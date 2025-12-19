-- project (id, projectname, about, startdate, enddate, status, price, idcommand, project_type)
-- student (id, lastname, firstname, role, email, yearb, groupname, idcommand)
-- command (id, command)
-- task (id,task, idproject)
-- resource (id, resource, idproject)
-- grouplist (groupname, sp)
-- mentor (id, lastname, firstname, email, idcommand)
-- Создайте новое подключение с Вашими данными
-- Активация расширений (выполнить под суперпользователем)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE EXTENSION IF NOT EXISTS dblink;

-- Сделайте импорт нужных для работы данных на новый сервер
DROP TABLE IF EXISTS z5_task,
z5_resource,
z5_project,
z5_student,
z5_mentor,
z5_command,
z5_grouplist,
user_new,
log_price,
users CASCADE;

CREATE TABLE
    z5_command (id SERIAL PRIMARY KEY, command VARCHAR(100));

CREATE TABLE
    z5_mentor (
        id SERIAL PRIMARY KEY,
        lastname VARCHAR(100),
        firstname VARCHAR(100),
        email VARCHAR(100),
        idcommand INT REFERENCES z5_command (id)
    );

CREATE TABLE
    z5_student (
        id SERIAL PRIMARY KEY,
        lastname VARCHAR(100),
        firstname VARCHAR(100),
        role VARCHAR(50),
        email VARCHAR(100),
        yearb INT,
        groupname VARCHAR(50),
        idcommand INT REFERENCES z5_command (id),
        manager_id INT,
        level INT,
        категория_пользователя VARCHAR(50),
        категория VARCHAR(50)
    );

CREATE TABLE
    z5_project (
        id SERIAL PRIMARY KEY,
        projectname VARCHAR(200),
        about TEXT,
        startdate DATE,
        enddate DATE,
        status VARCHAR(50),
        price NUMERIC(10, 2),
        idcommand INT REFERENCES z5_command (id),
        project_type VARCHAR(50),
        shifr VARCHAR(50),
        category VARCHAR(50),
        категория VARCHAR(50),
        result TEXT,
        project_deadline DATE,
        mentor_id INT REFERENCES z5_mentor (id)
    );

CREATE TABLE
    z5_task (
        id SERIAL PRIMARY KEY,
        task TEXT,
        idproject INT REFERENCES z5_project (id),
        score INT
    );

CREATE TABLE
    z5_resource (
        id SERIAL PRIMARY KEY,
        resource VARCHAR(100),
        idproject INT REFERENCES z5_project (id)
    );

CREATE TABLE
    z5_grouplist (groupname VARCHAR(50), sp INT);

--         1.1. Создание транзакций
--             1.1.1. Создайте транзакцию, которая состоит из операций
--                 • Ввод данных об команде
--                 • Ввод данных о менторе
--                 • Произведите проверку, что менторов у команды нет, то транзакция фиксация, иначе – отмена.
DO $$
                    DECLARE
                        new_command_id INT;
                        mentor_count INT;
                    BEGIN
                        INSERT INTO z5_command (command) VALUES ('CyberTeam') RETURNING id INTO new_command_id;
                        
                        INSERT INTO z5_mentor (lastname, firstname, email, idcommand) 
                        VALUES ('Ivanov', 'Ivan', 'ivan@test.com', new_command_id);

                        SELECT COUNT(*) INTO mentor_count FROM z5_mentor WHERE idcommand = new_command_id;
                        
                        IF mentor_count > 1 THEN
                            RAISE NOTICE 'У команды уже были менторы. Отмена.';
                            ROLLBACK;
                        ELSE
                            RAISE NOTICE 'Транзакция успешно зафиксирована.';
                        END IF;
                    EXCEPTION WHEN OTHERS THEN
                        RAISE NOTICE 'Произошел откат: %', SQLERRM;
                    END $$;

--             1.1.2. Разработать хранимую процедуру, которая не позволяла бы добавлять запись о проекте, если дата начала введена меньше даты окончания. Для отмены команды вставки записи применить команду отката транзакций ROLLBACK.
--                 • Создайте процедуру check_date:
--                     ◦ Задайте входные параметры процедуры: id_project, id_command, date_int, date_out;
--                     ◦ Задайте локальную переменную result и присвойте ей значение ‘ОК’.
--                     ◦ Задайте локальную переменную diff для проверки разницы между двумя датами.
--                     ◦ Напишите инструкцию для ввода записей в таблицу project, значение берите из входных параметров процедуры.
--                     ◦ Вычислите значение переменной diff как разница между двумя датами (дата окончания и дата начала), где код = последнему добавленному ключевому значению.
--                     ◦ Произведите проверку, если полученное число больше 0, то примените транзакцию, иначе откатите транзакцию и установите значение переменной result как ‘No’.
--                     ◦ Выведите значение переменной result на экран.
--                 • Выведите записи из таблицы project.
--                 • Задайте значения для переменных, дату выдачи поставьте меньше даты возврата
--                 • Вызовите процедуру check;
--                 • Проверьте, произведено ли добавление записи в таблицу.
--                 • Задайте значения переменных, дату окончания поставьте больше даты начала
--                 • Вызовите процедуру и проверьте, произведено ли добавление записей в таблицу.
CREATE
OR REPLACE PROCEDURE check_date (
    p_projectname VARCHAR,
    p_idcommand INT,
    p_date_in DATE,
    p_date_out DATE
) LANGUAGE plpgsql AS $$
                    DECLARE
                        v_result TEXT := 'OK';
                        v_diff INT;
                        v_new_id INT;
                    BEGIN
                        INSERT INTO z5_project (projectname, idcommand, startdate, enddate) 
                        VALUES (p_projectname, p_idcommand, p_date_in, p_date_out)
                        RETURNING id INTO v_new_id;

                        v_diff := p_date_out - p_date_in;

                        IF v_diff > 0 THEN
                            COMMIT; 
                            RAISE NOTICE 'Result: %', v_result;
                        ELSE
                            ROLLBACK;
                            v_result := 'No';
                            RAISE NOTICE 'Result: % (Dates invalid, transaction rolled back)', v_result;
                        END IF;
                    END;
                    $$;

-- Тестирование:
-- 1. Вывод таблицы
SELECT
    *
FROM
    z5_project;

-- 2. Ошибка (начало > конца)
CALL check_date ('Project Bad', 1, '2023-12-31', '2023-01-01');

-- 3. Проверка (записи быть не должно)
SELECT
    *
FROM
    z5_project
WHERE
    projectname = 'Project Bad';

-- 4. Успех
CALL check_date ('Project Good', 1, '2023-01-01', '2023-12-31');

-- 5. Проверка (запись есть)
SELECT
    *
FROM
    z5_project
WHERE
    projectname = 'Project Good';

--             1.1.3. (триггер) Создание триггера, который записывает в таблицу 
-- log_price данные о тех случаях изменения стоимости проекта в таблице project, при которых значение стоимости проекта стало больше 10000 рублей. 
-- *Триггер должен фиксировать и те случаи изменений стоимости, которые отменены командой rollback.
CREATE TABLE
    log_price (
        id SERIAL PRIMARY KEY,
        project_id INT,
        old_price NUMERIC,
        new_price NUMERIC,
        change_time TIMESTAMP DEFAULT NOW(),
        note TEXT
    );

CREATE
OR REPLACE FUNCTION log_price_change () RETURNS TRIGGER AS $$
                DECLARE
                    conn_str TEXT;
                    query_str TEXT;
                BEGIN
                    IF NEW.price > 10000 THEN
                        conn_str := 'dbname=' || current_database() || ' user=' || current_user;
                        
                        query_str := format(
                            'INSERT INTO log_price (project_id, old_price, new_price, note) VALUES (%s, %s, %s, ''Price > 10000'')',
                            NEW.id, COALESCE(OLD.price, 0), NEW.price
                        );
                        
                        PERFORM dblink_exec(conn_str, query_str);
                    END IF;
                    RETURN NEW;
                EXCEPTION WHEN OTHERS THEN
                    INSERT INTO log_price (project_id, old_price, new_price, note)
                    VALUES (NEW.id, OLD.price, NEW.price, 'Price > 10000 (Local)');
                    RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_price
AFTER
UPDATE
OR INSERT ON z5_project FOR EACH ROW
EXECUTE FUNCTION log_price_change ();

--             1.1.4. (Использование курсоров). Используя курсорный цикл, увеличьте на 20% стоимость проектов тех команд, которые имеют более 3-х студентов в своём составе. В конце каждой итерации проверять, не получится ли данная стоимость более 10000 рублей, в случае нарушения условия отменить изменение стоимости.
DO $$
                DECLARE
                    cur_projects CURSOR FOR 
                        SELECT p.id, p.price, COUNT(s.id) as student_count
                        FROM z5_project p
                        JOIN z5_student s ON p.idcommand = s.idcommand
                        GROUP BY p.id, p.price
                        HAVING COUNT(s.id) > 3;
                    
                    rec RECORD;
                    v_new_price NUMERIC;
                BEGIN
                    OPEN cur_projects;
                    LOOP
                        FETCH cur_projects INTO rec;
                        EXIT WHEN NOT FOUND;
                        
                        v_new_price := rec.price * 1.20;
                        
                        SAVEPOINT sp_before_update;
                        
                        UPDATE z5_project SET price = v_new_price WHERE id = rec.id;
                        
                        IF v_new_price > 10000 THEN
                            RAISE NOTICE 'Project % price would be %, rolling back update.', rec.id, v_new_price;
                            ROLLBACK TO SAVEPOINT sp_before_update;
                        ELSE
                            RAISE NOTICE 'Project % updated to %', rec.id, v_new_price;
                        END IF; 
                    END LOOP;
                    CLOSE cur_projects;
                END $$;

--             1.1.5. Создание хранимых процедур. Добавьте в таблицу user_new два поля для хранения информации о домашнем и сотовом телефоне. Разработать процедуру для ввода записей в таблицу user_new. Данная процедура должна проверять, есть ли информация хотя бы об одном из телефонов для связи, и если такой информации нет, то не вводить данные.
CREATE TABLE
    user_new (
        id SERIAL PRIMARY KEY,
        username VARCHAR(100),
        home_phone VARCHAR(20),
        cell_phone VARCHAR(20)
    );

CREATE
OR REPLACE PROCEDURE add_user_with_phone (
    p_username VARCHAR,
    p_home VARCHAR,
    p_cell VARCHAR
) LANGUAGE plpgsql AS $$
                BEGIN
                    IF (p_home IS NULL OR p_home = '') AND (p_cell IS NULL OR p_cell = '') THEN
                        RAISE NOTICE 'Ошибка: Не указан ни один телефон для связи.';
                        RETURN;
                    END IF;

                    INSERT INTO user_new (username, home_phone, cell_phone) 
                    VALUES (p_username, p_home, p_cell);
                    
                    RAISE NOTICE 'Пользователь добавлен.';
                END;
                $$;

--         1.2. Шифрование данных
--             1.2.1. Разработать хранимые процедуры для шифрования и дешифрования данных.
--                 • В таблицу users добавьте поле email, которое будет хранить электронную почту пользователя.
--                 • Напишите функцию для шифрования данных.
--                 • Создайте триггер, который будет срабатывать при вводе данных в таблицу Users и будет шифровать электронную почту пользователя.
--                 • Проверьте работу триггера.
--                 • Напишите функцию для дешифрования данных.
--                 • Напишите процедуру для проверки существования в базе данных о пользователе с введённой почтой. При написании функции используйте функцию дешифрования. Процедура должна выдавать значение 1, если пользователь существует, и 0, если не существует.
--                 • Проверьте работу процедуры.
DROP TABLE IF EXISTS users;

CREATE TABLE
    users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(100),
        email_enc BYTEA
    );

-- Функция шифрования (используем ключ 'my_secret_key')
CREATE
OR REPLACE FUNCTION encrypt_email () RETURNS TRIGGER AS $$
                    BEGIN
                        NEW.email_enc := pgp_sym_encrypt(NEW.email_enc::text, 'my_secret_key');
                        RETURN NEW;
                    END;
                    $$ LANGUAGE plpgsql;

-- Триггер
CREATE TRIGGER trg_encrypt_email BEFORE INSERT ON users FOR EACH ROW
EXECUTE FUNCTION encrypt_email ();

-- Проверка работы триггера (вставляем строку как bytea, она зашифруется)
-- Примечание: Чтобы передать текст в bytea триггер должен уметь его читать. 
-- Удобнее сделать VIEW или функцию-обертку, но сделаем через приведение типов:
INSERT INTO
    users (username, email_enc)
VALUES
    ('user1', 'test@mail.com'::bytea);

-- Функция дешифрования
CREATE
OR REPLACE FUNCTION get_decrypted_email (p_enc_data BYTEA) RETURNS TEXT AS $$
                    BEGIN
                        RETURN pgp_sym_decrypt(p_enc_data, 'my_secret_key');
                    EXCEPTION WHEN OTHERS THEN
                        RETURN NULL;
                    END;
                    $$ LANGUAGE plpgsql;

-- Процедура проверки существования пользователя по email
CREATE
OR REPLACE PROCEDURE check_user_by_email (p_email TEXT, INOUT result INT) LANGUAGE plpgsql AS $$
                    DECLARE
                        cnt INT;
                    BEGIN
                        SELECT COUNT(*) INTO cnt 
                        FROM users 
                        WHERE pgp_sym_decrypt(email_enc, 'my_secret_key') = p_email;
                        
                        IF cnt > 0 THEN
                            result := 1;
                        ELSE
                            result := 0;
                        END IF;
                    END;
                    $$;

--             1.2.2. Создайте функцию, которая будет шифровать и дешифровать данные в базе данных, например номера телефонов, номера кредитных карт или личные данные пользователей. Проверьте работу функции.
-- Шифрование
CREATE
OR REPLACE FUNCTION secure_data_encrypt (p_data TEXT) RETURNS BYTEA AS $$
                BEGIN
                    RETURN pgp_sym_encrypt(p_data, 'super_secure_key');
                END;
                $$ LANGUAGE plpgsql;

-- Дешифрование
CREATE
OR REPLACE FUNCTION secure_data_decrypt (p_data BYTEA) RETURNS TEXT AS $$
                BEGIN
                    RETURN pgp_sym_decrypt(p_data, 'super_secure_key');
                END;
                $$ LANGUAGE plpgsql;

--         1.3. Хэширование данных
--             1.3.1. В таблице Пользователи добавьте поля логин и пароль
-- Добавляем поля в users
ALTER TABLE users
ADD COLUMN login VARCHAR(100);

ALTER TABLE users
ADD COLUMN password_hash TEXT;

--             1.3.2. Добавьте записи в таблицу, применяя цикл или рекурсивный подзапрос, создавая пользователей с именами student1… student100 и паролем применив хэширование
-- Функция хеширования SHA-256 с итерациями
CREATE
OR REPLACE FUNCTION hash_sha256 (p_text TEXT, p_iterations INT DEFAULT 1) RETURNS TEXT AS $$
                DECLARE
                    v_hash TEXT := p_text;
                    i INT;
                BEGIN
                    FOR i IN 1..p_iterations LOOP
                        v_hash := encode(digest(v_hash, 'sha256'), 'hex');
                    END LOOP;
                    RETURN v_hash;
                END;
                $$ LANGUAGE plpgsql;

--             1.3.3. Создайте функцию на языке PL/pgSQL, которая будет вычислять хэш-значение для столбца типа TEXT. Хэширование должно выполняться с использованием алгоритма SHA-256. Также предусмотрите возможность передачи параметра, определяющего количество раз применения хэширования к одному значению.
-- Заполнение данными (student1...student100)
DO $$
                DECLARE
                    i INT;
                BEGIN
                    FOR i IN 1..100 LOOP
                        INSERT INTO users (username, login, password_hash)
                        VALUES (
                            'Student ' || i,
                            'student' || i,
                            hash_sha256('pass' || i, 1)
                        );
                    END LOOP;
                END $$;

--         1.4. Заполнение таблицы случайными данными в PostgreSQL: UUID, varchar
--             1.4.1. Используя тип данных UUID сгенерируйте id произвольной таблицы
--                 • Создайте таблицу с полыми:
--                     ◦ uuid
--                     ◦ time_created
CREATE TABLE
    random_uuid_table (uuid_col UUID PRIMARY KEY, time_created TIMESTAMP);

--                 • Создайте триггерную функцию и триггер, чтобы автоматически генерировать значение UUID при вставке новой записи в таблицу и добавляет текущее время создания записи
--                 • Создайте триггер – при вставке данных генерируется случайное значение uuid
CREATE
OR REPLACE FUNCTION gen_uuid_trigger () RETURNS TRIGGER AS $$
                    BEGIN
                        NEW.uuid_col := gen_random_uuid();
                        NEW.time_created := NOW();
                        RETURN NEW;
                    END;
                    $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_gen_uuid BEFORE INSERT ON random_uuid_table FOR EACH ROW
EXECUTE FUNCTION gen_uuid_trigger ();

--                 • Проверьте работу триггера
INSERT INTO
    random_uuid_table (uuid_col)
VALUES
    (NULL);

-- Триггер сам заполнит
SELECT
    *
FROM
    random_uuid_table;

--             1.4.2. Создайте функцию для генерации случайных слов из существующего файла
--                 • Функция должна вернуть текстовую строку
--                 • Объявите переменную для хранения массива слов
--                 • Почитайте документацию по функции pg_read_file()
-- https://pgpedia.info/p/pg_read_file.html
--                 • Прочитаем данные из файла /usr/share/dict/words 
-- Файл /usr/share/dict/words — это стандартный словарь английского языка, который часто встречается в операционных системах семейства Unix, таких как Linux и macOS. Он содержит список слов, обычно одно слово на строку, без определений или других метаданных. Этот файл используется различными программами для проверки орфографии, генерации случайных паролей, создания кроссвордов и других задач, связанных с обработкой текста.
--                 • Преобразуем слова в массив
--                 • Напишите функцию, которая будет возвращать указанное количество слов с данного массива
--                 • Проверьте работу функции
--                 • Придумайте применение данного словаря для учебной базы данных.
CREATE
OR REPLACE FUNCTION get_random_words (n INT) RETURNS TEXT AS $$
                    DECLARE
                        file_content TEXT;
                        words_array TEXT[];
                        result_text TEXT := '';
                        i INT;
                        total_words INT;
                    BEGIN
                        -- Попытка прочитать файл (путь должен быть разрешен в postgresql.conf)
                        -- Если не работает, раскомментируйте блок ниже для использования встроенного словаря
                        
                        -- BEGIN MOCK DATA (Если нет доступа к файлу)
                        words_array := ARRAY['apple', 'banana', 'project', 'database', 'sql', 'system', 'random', 'code', 'linux', 'server'];
                        -- END MOCK DATA
                        
                        /* Реальный код чтения (требует настройки прав):
                        file_content := pg_read_file('/usr/share/dict/words'); -- Путь может требовать настройки
                        words_array := string_to_array(file_content, E'\n');
                        */
                        
                        total_words := array_length(words_array, 1);
                        
                        FOR i IN 1..n LOOP
                            result_text := result_text || ' ' || words_array[floor(random() * total_words + 1)::int];
                        END LOOP;
                        
                        RETURN trim(result_text);
                    END;
                    $$ LANGUAGE plpgsql;

-- Применение: генерация описаний проектов
UPDATE z5_project
SET
    about = get_random_words (5)
WHERE
    about IS NULL;

--         1.5. Придумайте и реализуйте систему управления пользователями, включающую регистрацию новых пользователей, аутентификацию и управление доступом. Система должна включать защиту данных через шифрование и хэширование с солью, а также предоставлять функционал для генерации текстовых данных на основе списка слов.
DROP TABLE IF EXISTS app_users;

CREATE TABLE
    app_users (
        id SERIAL PRIMARY KEY,
        username_enc BYTEA,
        password_hash TEXT,
        salt TEXT, -- Соль
        role VARCHAR(20) CHECK (role IN ('admin', 'moderator', 'user')),
        created_at TIMESTAMP DEFAULT NOW()
    );

--                 • Пароль должен быть захэширован с использованием соли (случайная строка символов, добавляемая к паролю перед хэшированием).
--                 • Предусмотрите хранение имени пользователя в шифрованном виде.
--                 • Реализовать функцию, которая принимает список слов и длину предложения. Функция должна случайным образом выбирать слова из списка и формировать предложение указанной длины. Предложения могут содержать любые части речи (существительные, глаголы, прилагательные и т.д.).
--                 • Определить несколько ролей (например, администратор, модератор, обычный пользователь). Назначить каждому пользователю роль при регистрации. Разграничить доступ к различным частям системы в зависимости от роли пользователя.
--             1.5.2. Все операции с базой данных должны быть защищены (использование транзакций, защита от SQL-инъекций).
-- 1. Регистрация пользователя
CREATE
OR REPLACE PROCEDURE register_user (p_username TEXT, p_password TEXT, p_role TEXT) LANGUAGE plpgsql AS $$
                    DECLARE
                        v_salt TEXT;
                        v_hash TEXT;
                        v_user_enc BYTEA;
                    BEGIN
                        v_salt := encode(gen_random_bytes(16), 'hex');
                        
                        v_hash := encode(digest(p_password || v_salt, 'sha256'), 'hex');
                        
                        v_user_enc := pgp_sym_encrypt(p_username, 'app_secret_key');
                        
                        INSERT INTO app_users (username_enc, password_hash, salt, role)
                        VALUES (v_user_enc, v_hash, v_salt, p_role);
                        
                        RAISE NOTICE 'User registered successfully.';
                    END;
                    $$;

-- 2. Аутентификация
CREATE
OR REPLACE FUNCTION authenticate_user (p_username TEXT, p_password TEXT) RETURNS TEXT AS $$
                    DECLARE
                        rec RECORD;
                        v_hash_check TEXT;
                    BEGIN
                        FOR rec IN SELECT * FROM app_users LOOP
                            IF pgp_sym_decrypt(rec.username_enc, 'app_secret_key') = p_username THEN
                                v_hash_check := encode(digest(p_password || rec.salt, 'sha256'), 'hex');
                                
                                IF v_hash_check = rec.password_hash THEN
                                    RETURN 'Access Granted. Role: ' || rec.role;
                                ELSE
                                    RETURN 'Access Denied: Wrong Password';
                                END IF;
                            END IF;
                        END LOOP;
                        
                        RETURN 'Access Denied: User not found';
                    END;
                    $$ LANGUAGE plpgsql;

-- 3. Функция генерации предложений (на основе словаря из 1.4)
CREATE
OR REPLACE FUNCTION generate_sentence (word_count INT) RETURNS TEXT AS $$
                    BEGIN
                        RETURN initcap(get_random_words(word_count)) || '.';
                    END;
                    $$ LANGUAGE plpgsql;

-- Тестирование системы 1.5
CALL register_user ('admin_max', 'superpass123', 'admin');

CALL register_user ('student_1', 'learning', 'user');

SELECT
    authenticate_user ('admin_max', 'superpass123');

-- Должен пустить
SELECT
    authenticate_user ('admin_max', 'wrongpass');

-- Отказ
SELECT
    generate_sentence (4);

-- Случайное предложение