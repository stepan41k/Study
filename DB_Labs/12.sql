--         4.1. Управление данными
--             4.1.1. Наследование
--                 • Создайте таблицу user_new, с полями id, firstname, lastname, email
CREATE TABLE
    user_new (
        id SERIAL PRIMARY KEY,
        firstname VARCHAR(100),
        lastname VARCHAR(100),
        email VARCHAR(100)
    );

--                 • Создайте таблицы student_new, mentor_new, которые наследуются от таблицы user_new и каждая из таблиц имеет хотя бы одно своё собственное поле
CREATE TABLE
    student_new (groupname VARCHAR(50), yearb INTEGER) INHERITS (user_new);

CREATE TABLE
    mentor_new (salary NUMERIC(10, 2)) INHERITS (user_new);

--                 • Заполните таблицы student_new, mentor_new данными из соответствующих таблиц базы данных
INSERT INTO
    student_new (firstname, lastname, email, groupname, yearb)
SELECT
    firstname,
    lastname,
    email,
    groupname,
    yearb
FROM
    z5_student;

INSERT INTO
    mentor_new (firstname, lastname, email, salary)
SELECT
    firstname,
    lastname,
    email,
    50000
FROM
    z5_mentor;

--                 • Создайте операции вставки, обновления, удаления данных из таблиц (дочерних, родительской)
INSERT INTO
    student_new (firstname, lastname, email, groupname, yearb)
VALUES
    ('Иван', 'Новый', 'ivan@test.com', '6901', 2003);

UPDATE mentor_new
SET
    salary = 60000
WHERE
    lastname = 'Петров';

DELETE FROM user_new
WHERE
    email = 'ivan@test.com';

--                 • Напишите операции выборки данных с применением оператора only и без;
SELECT
    *
FROM
    user_new;

SELECT
    *
FROM
    ONLY user_new;

--             4.1.2. Домен и тип данных
--                 • Создайте домен chN, в котором добавьте проверку, что имя и фамилия пользователя не содержит пробелов и пустых значений
CREATE DOMAIN chN AS VARCHAR(100) CHECK (
    VALUE !~ '\s'
    AND VALUE <> ''
);

--                 • Измените тип данных фамилии и имени пользователя на указанных домен. Проверьте работу домена
ALTER TABLE user_new
ALTER COLUMN firstname
TYPE chN;

ALTER TABLE user_new
ALTER COLUMN lastname
TYPE chN;

ALTER TABLE student_new
ALTER COLUMN firstname
TYPE chN;

ALTER TABLE student_new
ALTER COLUMN lastname
TYPE chN;

ALTER TABLE mentor_new
ALTER COLUMN firstname
TYPE chN;

ALTER TABLE mentor_new
ALTER COLUMN lastname
TYPE chN;

-- Проверка (должна вызвать ошибку)
-- INSERT INTO user_new (firstname) VALUES ('Ivan Ivanov'); 
--                 • Создайте тип данных, включающий два текстовых поля для хранения названия компании и название должности работника. Примените тип данных для таблицы user_new, добавив поле – работа.
CREATE TYPE job_info AS (company_name TEXT, position_name TEXT);

-- Добавление поля в user_new (автоматически добавится наследникам)
ALTER TABLE user_new
ADD COLUMN work_data job_info;

--                 • Создайте пользовательскую функцию, которая принимает id пользователя и возвращает данные о его работе.
CREATE
OR REPLACE FUNCTION get_user_work (uid INTEGER) RETURNS job_info AS $$
                    DECLARE
                        res job_info;
                    BEGIN
                        SELECT work_data INTO res FROM user_new WHERE id = uid;
                        RETURN res;
                    END;
                    $$ LANGUAGE plpgsql;

--             4.1.3. Массивы
--                 • Добавьте в таблицу user_new поле contact_number имеющим тип данных ARRAY
ALTER TABLE user_new
ADD COLUMN contact_number TEXT[];

--                 • Добавьте данные в данное поле по примеру
UPDATE user_new
SET
    contact_number = ARRAY['89001112233', '9112526']
WHERE
    id = (
        SELECT
            id
        FROM
            user_new
        LIMIT
            1
    );

--                 • Напишите запрос для нахождения фио пользователя и первого телефона из списка у пользователя
SELECT
    firstname,
    lastname,
    contact_number[1] as first_phone
FROM
    user_new;

--                 • Выведите записи о пользователях, которые имеют номер, начинающийся на 911, и содержит две цифры 2 – с применением регулярного выражения
-- Нужно развернуть массив или проверять элементы. Для выборки записей:
SELECT
    *
FROM
    user_new
WHERE
    EXISTS (
        SELECT
            1
        FROM
            unnest(contact_number) AS ph
        WHERE
            ph ~ '^911.*2.*2'
    );

--                 • Примените функцию ANY() для нахождения пользователей, которые имеют конкретный телефон
SELECT
    *
FROM
    user_new
WHERE
    '89001112233' = ANY (contact_number);

--                 • Напишите запросы с применением операторов @>,<@, &&, ||
-- Содержит ли массив конкретные номера
SELECT
    *
FROM
    user_new
WHERE
    contact_number @> ARRAY['+79009990022'];

SELECT
    *
FROM
    user_new
WHERE
    contact_number <@ ARRAY[
        '+79009990022',
        '+79003334466',
        '+79003334455',
        '+79001112233'
    ];

-- Пересечение массивов (есть ли общие элементы)
SELECT
    *
FROM
    user_new
WHERE
    contact_number && ARRAY['9112526', '000000'];

-- Конкатенация (добавление в запросе)
SELECT
    contact_number || ARRAY['555666']
FROM
    user_new;

--                 • Напишите запросы с применением функций array_append, array_cat, array_dims, unnest
SELECT
    array_append(contact_number, '777'), -- добавить в конец
    array_cat(contact_number, ARRAY['888', '999']), -- объединить массивы
    array_dims(contact_number) -- размерность
FROM
    user_new;

-- Unnest (разворачивание в строки)
SELECT
    firstname,
    unnest(contact_number)
FROM
    user_new;

--             4.1.4. Работа с данными в форматах json, xml
--                 • Добавим в таблицу student_new поле about формата json для хранения данных о пользователе, а именно – work место учёбы/работы, interests – интересы – набор нескольких данных, по примеру. Заполните записями. Выведите данные только о тех пользователях, в интересы которых входит только спорт, спорт или чтение, спорт и компьютер
-- {
--   "work": "Университет НовГУ",
--   "interests": "путешествия", "чтение", "спорт"
-- }
ALTER TABLE student_new
ADD COLUMN about JSONB;

-- Заполнение
UPDATE student_new
SET
    about = '{
                    "work": "Университет НовГУ",
                    "interests": ["путешествия", "чтение", "спорт"]
                    }'::jsonb
WHERE
    id = (
        SELECT
            id
        FROM
            student_new
        LIMIT
            1
    );

-- Вывод (интересы: только спорт, ИЛИ спорт и чтение, ИЛИ спорт и компьютер)
-- Логика оператора @> (содержит) и <@ (содержится в).
SELECT
    firstname,
    about
FROM
    student_new
WHERE
    (
        about -> 'interests' @> '["спорт"]'
        AND jsonb_array_length(about -> 'interests') = 1
    )
    OR (
        about -> 'interests' @> '["спорт", "чтение"]'
        AND jsonb_array_length(about -> 'interests') = 2
    )
    OR (
        about -> 'interests' @> '["спорт", "компьютер"]'
        AND jsonb_array_length(about -> 'interests') = 2
    );

--                 • Добавим в таблицу mentor_new поле schedule формата xml для хранения расписания педагога, по примеру. Заполните записями. Выведите данные только о расписании, о расписании определённой группы.
ALTER TABLE mentor_new
ADD COLUMN schedule XML;

-- Заполнение
UPDATE mentor_new
SET
    schedule = '<schedule>
                        <lesson group="6901" day="Monday">Math</lesson>
                        <lesson group="6902" day="Tuesday">Physics</lesson>
                    </schedule>'
WHERE
    id = (
        SELECT
            id
        FROM
            mentor_new
        LIMIT
            1
    );

-- Вывод всего расписания
SELECT
    schedule
FROM
    mentor_new;

-- Вывод расписания для группы 6901 (XPath)
SELECT
    xpath('//lesson[@group="6901"]', schedule)
FROM
    mentor_new;

--         4.2. Триггеры по поддержки целостности данных
--             4.2.1. Триггер для формирования значения первичных ключей
--                 • Создайте копию таблицы user_new без serial.
CREATE TABLE
    user_manual_pk (id INTEGER PRIMARY KEY, firstname VARCHAR(50));

--                 • Создайте триггер для формирования значения первичного ключа для таблицы user_new (триггер должен формировать случайное число, проверять, что это значение не задействовано как ключ и добавлять его в поле).
CREATE
OR REPLACE FUNCTION generate_random_id () RETURNS TRIGGER AS $$
                    DECLARE
                        new_id INTEGER;
                        done BOOLEAN := FALSE;
                    BEGIN
                        WHILE NOT done LOOP
                            new_id := floor(random() * 100000)::INTEGER;
                            IF NOT EXISTS (SELECT 1 FROM user_manual_pk WHERE id = new_id) THEN
                                done := TRUE;
                            END IF;
                        END LOOP;
                        NEW.id := new_id;
                        RETURN NEW;
                    END;
                    $$ LANGUAGE plpgsql;

-- Триггер
CREATE TRIGGER trg_manual_pk BEFORE INSERT ON user_manual_pk FOR EACH ROW
EXECUTE FUNCTION generate_random_id ();

--                 • Добавьте записи, проверьте работу триггера.
INSERT INTO
    user_manual_pk (firstname)
VALUES
    ('TestUser');

SELECT
    *
FROM
    user_manual_pk;

--             4.2.2. Триггер по поддержанию значений внешних ключей (on update cascade)
--                 • Добавьте если не создавали ранее таблицу Группа (группа, специальность, год_поступления), заполните таблицу данными.
CREATE TABLE
    groups (
        group_id INTEGER PRIMARY KEY,
        spec VARCHAR(50),
        year_start INTEGER
    );

INSERT INTO
    groups
VALUES
    (1, 'IT', 2020),
    (2, 'Design', 2021);

ALTER TABLE user_new
ADD COLUMN INTEGER REFERENCES groups (group_id);

UPDATE user_new
SET
    group_id_fk = 1
WHERE
    id IN (
        SELECT
            id
        FROM
            user_new
        LIMIT
            1
    );

--                 • Создайте триггер, который при изменении номера группы в таблице Groups происходит автоматическое изменение всех кодовых значений user_new.
-- Указания для выполнения: произведите проверку условия неравенства нового и старого значения ключевого поля, в случае неравенства выполните запрос на обновление подчинённой таблицы, установив в поле внешнего ключа связи новое значение первичного ключа главной таблицы, при условии равенства внешнего ключа старому значению поля внешнего ключа.
-- Создадим отдельный триггер, так как стандартный FK делает это автоматически, но задание просит ручную реализацию.
-- Предполагаем связь: student_new.group_id -> groups.id
CREATE
OR REPLACE FUNCTION cascade_update_group () RETURNS TRIGGER AS $$
                    BEGIN
                        IF OLD.group_id <> NEW.group_id THEN
                            UPDATE user_new 
                            SET group_id_fk = NEW.group_id 
                            WHERE group_id_fk = OLD.group_id;
                        END IF;
                        RETURN NEW;
                    END;
                    $$ LANGUAGE plpgsql;

-- Триггер
CREATE TRIGGER trg_group_update
AFTER
UPDATE ON groups FOR EACH ROW
EXECUTE FUNCTION cascade_update_group ();

--                 • Проверьте работу созданного триггера, для этого, например, измените группу с номером 1 на код 2091, проверьте изменение данных в таблице user_new.
UPDATE groups
SET
    group_id = 2091
WHERE
    group_id = 1;

-- Проверка: SELECT * FROM user_new WHERE group_id_fk = 2091;
--             4.2.3. Удаление строк подчинённой таблицы (on delete cascade) – выполните с применением транзакции с откатом удаления
--                 TODO:• Создайте триггер, который будет производить каскадное удаление строк из таблицы Студент при удалении записи в таблице Группа.
--                 • Проверьте работу созданного триггера, для этого удалите данные о группе с номером 1, проверьте удаление данных о всех студентах данной группы.
--                 • Создайте триггер для таблицы user_new для организации каскадного удаления информации по своему усмотрению.
CREATE
OR REPLACE FUNCTION cascade_delete_group () RETURNS TRIGGER AS $$
                    BEGIN
                        DELETE FROM user_new WHERE group_id_fk = OLD.group_id;
                        RETURN OLD;
                    END;
                    $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_group_delete BEFORE DELETE ON groups FOR EACH ROW
EXECUTE FUNCTION cascade_delete_group ();

-- Тест с транзакцией и откатом
BEGIN;

DELETE FROM groups
WHERE
    group_id = 2091;

-- Проверяем: SELECT count(*) FROM user_new WHERE group_id_fk = 2091; (должно быть 0)
ROLLBACK;

--             4.2.4. Триггер для поддержки целостности на уровни ссылок
--                 • Создайте триггер, который при вводе данных в таблицу project, не связанных с таблицей team будет вывод сообщения об ошибке, а при успешном вводе - успешного ввода данных. Триггер должен работать таким образом, чтобы при вводе записи в таблицу project, которая содержит данные о команде, отсутствующей в таблице team запись не добавлялась в таблицу, а при верном вводе – добавлялась. Проверьте работу триггера.
-- Для project и team (z5_command)
CREATE
OR REPLACE FUNCTION check_team_exists () RETURNS TRIGGER AS $$
                    BEGIN
                        IF NOT EXISTS (SELECT 1 FROM z5_command WHERE id = NEW.idcommand) THEN
                            RAISE EXCEPTION 'Ошибка: Команды с ID % не существует', NEW.idcommand;
                        END IF;
                        RAISE NOTICE 'Успешный ввод данных проекта';
                        RETURN NEW;
                    END;
                    $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_project_team BEFORE INSERT ON z5_project FOR EACH ROW
EXECUTE FUNCTION check_team_exists ();

INSERT INTO
    z5_project (
        id,
        projectname,
        about,
        startdate,
        enddate,
        status,
        price,
        idcommand,
        project_type,
        shifr,
        project_deadline,
        mentor_id
    )
VALUES
    (
        5,
        '12 лаба',
        '12 лаба по базам данных',
        '2025-09-28',
        '2025-10-20',
        'в работе',
        0.0,
        3,
        'научный',
        'PR0117',
        30,
        2
    );

-- ALTER TABLE z5_task
-- ADD COLUMN date_issued DATE;
-- ALTER TABLE z5_task
-- ADD COLUMN date_due DATE;
-- CREATE
-- OR REPLACE FUNCTION check_task_dates () RETURNS TRIGGER AS $$
--                     BEGIN
--                         IF NEW.date_due < NEW.date_issued THEN
--                             RAISE EXCEPTION 'Ошибка: Дата выполнения меньше даты выдачи';
--                         END IF;
--                         RETURN NEW;
--                     END;
--                     $$ LANGUAGE plpgsql;
-- CREATE TRIGGER trg_check_task_dates BEFORE INSERT ON z5_task FOR EACH ROW
-- EXECUTE FUNCTION check_task_dates ();
--                 • Создайте аналогичный триггер для контроля ввода данных в таблицу task. Также предусмотрите проверку ввода, которая не позволяла бы добавлять запись о задаче, если дата выполнения введена меньше даты выдачи задания. Проверьте работу триггера.
CREATE
OR REPLACE FUNCTION check_task_rules () RETURNS TRIGGER AS $$
                    BEGIN
                        -- Проверка дат
                        IF NEW.due_date < NEW.issue_date THEN
                            RAISE EXCEPTION 'Due date cannot be earlier than issue date';
                            RETURN NULL; -- блокировка вставки
                        END IF;
                        
                        -- Проверка проекта (аналогично foreign key)
                        IF NOT EXISTS (SELECT 1 FROM public.project WHERE id = NEW.project_id) THEN
                            RAISE EXCEPTION 'Project not found';
                        END IF;

                        RETURN NEW;
                    END;
                    $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_task BEFORE INSERT ON public.task FOR EACH ROW
EXECUTE FUNCTION check_task_rules ();

--         4.3. Создание контролирующего триггера
--             4.3.1. Создайте триггер, который при добавлении нового пользователя будет заполнять значение поля IO (инициалы). Для этого:
--     • Добавьте в таблицу user_new поле IO тип данных текстовый два символа
ALTER TABLE user_new
ADD COLUMN IO CHAR(2);

--     • Создайте триггер на событие before insert on user_new, значение первых букв инициала имени и отчества. При этом можно применить регулярное выражение для нахождения имени и отчества.
CREATE
OR REPLACE FUNCTION fill_initials () RETURNS TRIGGER AS $$
                BEGIN
                    -- Берем первую букву имени и фамилии
                    NEW.IO := substring(NEW.firstname from 1 for 1) || substring(NEW.lastname from 1 for 1);
                    RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_fill_initials BEFORE INSERT ON user_new FOR EACH ROW
EXECUTE FUNCTION fill_initials ();

--             4.3.2. Создайте триггер, который при добавлении записи будет проверять бизнес-правило: рейтинг ментора должен быть больше или равен рейтинга команды.
-- Добавим поля рейтинга для демонстрации
ALTER TABLE mentor_new
ADD COLUMN rating INTEGER DEFAULT 10;

ALTER TABLE z5_command
ADD COLUMN rating INTEGER DEFAULT 5;

-- Добавим связь ментора с командой в mentor_new (или используем idcommand если есть)
ALTER TABLE mentor_new
ADD COLUMN idcommand INTEGER;

CREATE
OR REPLACE FUNCTION check_mentor_rating () RETURNS TRIGGER AS $$
                DECLARE
                    team_rating INTEGER;
                BEGIN
                    SELECT rating INTO team_rating FROM z5_command WHERE id = NEW.idcommand;
                    
                    IF NEW.rating < team_rating THEN
                        RAISE EXCEPTION 'Рейтинг ментора (%) ниже рейтинга команды (%)', NEW.rating, team_rating;
                    END IF;
                    RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_rating BEFORE INSERT
OR
UPDATE ON mentor_new FOR EACH ROW
EXECUTE FUNCTION check_mentor_rating ();

--             4.3.3. Создайте триггер, который обеспечит выполнение бизнес-правила: в каждой команде не может быть больше определенного количества студентов. Установите максимальное количество студентов в команде равным 5. При попытке добавить нового студента в команду, если в команде уже 5 студентов, триггер должен блокировать вставку новых данных.
ALTER TABLE student_new
ADD COLUMN team_id INT;

-- Предполагаем, что связь студента с командой через idcommand
CREATE
OR REPLACE FUNCTION check_team_limit () RETURNS TRIGGER AS $$
                DECLARE
                    cnt INTEGER;
                BEGIN
                    SELECT count(*) INTO cnt FROM z5_student WHERE idcommand = NEW.idcommand;
                    
                    IF cnt >= 5 THEN
                        RAISE EXCEPTION 'В команде % уже максимальное количество студентов (5)', NEW.idcommand;
                    END IF;
                    RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_team_limit BEFORE INSERT ON z5_student FOR EACH ROW
EXECUTE FUNCTION check_team_limit ();

-- * Напишите команду MERGE, которая будет обновлять информацию о студенте, если он уже существует в базе, или добавлять его, если он новый.
MERGE INTO z5_student t USING (
    VALUES
        (101, 'Сидоров', 'Петр', 'test@mail.ru')
) AS s (id, lastname, firstname, email) ON t.id = s.id WHEN MATCHED THEN
UPDATE
SET
    lastname = s.lastname,
    firstname = s.firstname,
    email = s.email WHEN NOT MATCHED THEN INSERT (id, lastname, firstname, email)
VALUES
    (s.id, s.lastname, s.firstname, s.email);

--         4.4. Запись изменений в таблицу логов
CREATE TABLE
    log_project (
        id SERIAL PRIMARY KEY,
        project_id INTEGER,
        operation VARCHAR(10),
        log_time TIMESTAMP DEFAULT NOW()
    );

--             4.4.1. Создание триггера, который записывает в таблицу log_project данные о добавленных и удалённых строках таблицы project. 
-- *Триггер должен фиксировать и те случаи удаления, которые отменены командой rollback.
CREATE
OR REPLACE FUNCTION log_project_changes () RETURNS TRIGGER AS $$
                BEGIN
                    IF (TG_OP = 'INSERT') THEN
                        INSERT INTO log_project (project_id, operation) VALUES (NEW.id, 'INSERT');
                        RETURN NEW;
                    ELSIF (TG_OP = 'DELETE') THEN
                        INSERT INTO log_project (project_id, operation) VALUES (OLD.id, 'DELETE');
                        RETURN OLD;
                    END IF;
                    RETURN NULL;
                END;
                $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_project
AFTER INSERT
OR DELETE ON z5_project FOR EACH ROW
EXECUTE FUNCTION log_project_changes ();

--             4.4.2. Создайте таблицу log_student, которая будет содержать поля: id_ (номер записи – с инкрементным значением, date_ строка для хранения даты изменения, time_ – строка для хранения времени изменения, event – строка, хранящая значение действия, выполняемого с таблицей, row_number – номер изменяемой строки, user_ - пользователь, который вносит изменение).
CREATE TABLE
    log_student (
        id_ SERIAL PRIMARY KEY,
        date_ TEXT,
        time_ TEXT,
        event TEXT,
        row_number INTEGER,
        user_ TEXT
    );

--             4.4.3. Создайте триггер, который будет следить за операциями добавления записей в таблицу team, удаления записей в таблице team, изменения записей в таблице team.
CREATE
OR REPLACE FUNCTION log_team_ops () RETURNS TRIGGER AS $$
                DECLARE
                    curr_date TEXT := to_char(now(), 'YYYY-MM-DD');
                    curr_time TEXT := to_char(now(), 'HH24:MI:SS');
                    curr_user TEXT := current_user;
                    row_id INTEGER;
                BEGIN
                    IF (TG_OP = 'DELETE') THEN row_id := OLD.id; ELSE row_id := NEW.id; END IF;
                    
                    -- Пишем в таблицу log_student (как просили создать в 4.4.2, хотя логично было бы log_team)
                    INSERT INTO log_student (date_, time_, event, row_number, user_)
                    VALUES (curr_date, curr_time, TG_OP, row_id, curr_user);
                    
                    IF (TG_OP = 'DELETE') THEN RETURN OLD; ELSE RETURN NEW; END IF;
                END;
                $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_team
AFTER INSERT
OR
UPDATE
OR DELETE ON z5_command FOR EACH ROW
EXECUTE FUNCTION log_team_ops ();

--             4.4.4. Проверьте триггер, для этого выполните операцию добавления от имени другого пользователя.
-- SET ROLE postgres; -- переключение пользователя, если есть права
INSERT INTO
    z5_command (command)
VALUES
    ('New Team Alpha');

SELECT
    *
FROM
    log_student;

--         4.5. Создание DDL триггеров* (напишите код, возможно не будет доступа)
--             4.5.1. Создайте триггер, который будет запрещать удалять таблицы после 18-00 и фиксирует попытки это сделать.
CREATE
OR REPLACE FUNCTION abort_drop_table_after_18 () RETURNS event_trigger AS $$
                BEGIN
                    IF (EXTRACT(HOUR FROM current_time) >= 18) THEN
                        RAISE EXCEPTION 'Удаление таблиц запрещено после 18:00';
                    END IF;
                END;
                $$ LANGUAGE plpgsql;

CREATE EVENT TRIGGER trg_no_drop_evening ON sql_drop
EXECUTE FUNCTION abort_drop_table_after_18 ();

--             4.5.2. Создайте триггер, который будет фиксировать случаи выполнения DML кода в субботу и в воскресенье. В лог нужно записывать имя пользователя, дату и время, текст запроса.
-- Таблица лога DML
CREATE TABLE
    log_dml_weekend (
        username TEXT,
        event_time TIMESTAMP,
        query_text TEXT
    );

CREATE
OR REPLACE FUNCTION check_weekend_dml () RETURNS TRIGGER AS $$
                BEGIN
                    -- 6 = Суббота, 0 = Воскресенье
                    IF (EXTRACT(DOW FROM NOW()) IN (0, 6)) THEN
                        INSERT INTO log_dml_weekend (username, event_time, query_text)
                        VALUES (current_user, now(), current_query());
                    END IF;
                    RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;

-- Назначаем на таблицу (например, z5_student)
CREATE TRIGGER trg_weekend_audit
AFTER INSERT
OR
UPDATE
OR DELETE ON z5_student FOR EACH ROW
EXECUTE FUNCTION check_weekend_dml ();

--         4.6. Создание INSTEAD OF триггера для вставки данных в представление
--             4.6.1. Создайте многотабличное представление, которое выводит данные о проектах, командах и менторах, а также полей обязательных для заполнения в данных таблицах.
CREATE VIEW
    project_details_view AS
SELECT
    p.projectname,
    p.price,
    c.command AS team_name,
    m.lastname AS mentor_lastname
FROM
    z5_project p
    JOIN z5_command c ON p.idcommand = c.id
    LEFT JOIN z5_mentor m ON p.mentor_id = m.id;

--             4.6.2. Попробуйте вставить данные в созданное представление. В результате вы получите ошибку ввода.
INSERT INTO
    project_details_view (projectname, price, team_name, mentor_lastname)
VALUES
    ('Супер Проект', 100000, 'Alpha', 'Sidorov');

--             4.6.3. Создайте триггер на вставку данных в представление, который будет вставлять данные в базовые таблицы
CREATE
OR REPLACE FUNCTION insert_project_view () RETURNS TRIGGER AS $$
                DECLARE
                    team_id INTEGER;
                    ment_id INTEGER;
                BEGIN
                    -- 1. Ищем или создаем команду
                    SELECT id INTO team_id FROM z5_command WHERE command = NEW.team_name;
                    IF team_id IS NULL THEN
                        INSERT INTO z5_command (command) VALUES (NEW.team_name) RETURNING id INTO team_id;
                    END IF;

                    -- 2. Ищем ментора (по фамилии для примера)
                    SELECT id INTO ment_id FROM z5_mentor WHERE lastname = NEW.mentor_lastname LIMIT 1;
                    -- Если ментора нет, можно либо создавать, либо оставлять NULL. Допустим, оставляем NULL, если не найден.

                    -- 3. Вставляем проект
                    INSERT INTO z5_project (projectname, price, idcommand, mentor_id)
                    VALUES (NEW.projectname, NEW.price, team_id, ment_id);

                    RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_insert_view INSTEAD OF INSERT ON project_details_view FOR EACH ROW
EXECUTE FUNCTION insert_project_view ();

-- Теперь вставка сработает
INSERT INTO
    project_details_view (projectname, price, team_name, mentor_lastname)
VALUES
    ('Супер Проект 2', 150000, 'Omega', 'Ivanov');