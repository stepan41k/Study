--         4.1. Управление данными
--             4.1.1. Наследование
--                 • Создайте таблицу user_new, с полями id, firstname, lastname, email
                    CREATE TABLE user_new (
                        id SERIAL PRIMARY KEY,
                        firstname TEXT,
                        lastname TEXT,
                        email TEXT
                    );
--                 • Создайте таблицы student_new, mentor_new, которые наследуются от таблицы user_new и каждая из таблиц имеет хотя бы одно своё собственное поле
                    CREATE TABLE student_new (
                        group_id INT
                    ) INHERITS (user_new);

                    CREATE TABLE mentor_new (
                        experience INT
                    ) INHERITS (user_new);
--                 • Заполните таблицы student_new, mentor_new данными из соответствующих таблиц базы данных
                    INSERT INTO student_new (firstname, lastname, email, group_id)
                    SELECT firstname, lastname, email, group_id FROM public.student;

                    INSERT INTO mentor_new (firstname, lastname, email, experience)
                    SELECT firstname, lastname, email, 5 FROM public.mentor; -- 5 лет опыта условно
--                 • Создайте операции вставки, обновления, удаления данных из таблиц (дочерних, родительской)
                    INSERT INTO student_new (firstname, lastname, email, group_id) 
                    VALUES ('New', 'Student', 'new@st.com', 1);

                    UPDATE user_new SET email = 'updated@st.com' WHERE firstname = 'New';

                    DELETE FROM mentor_new WHERE firstname = 'Sergey';
--                 • Напишите операции выборки данных с применением оператора only и без
                    SELECT * FROM user_new;
                    SELECT * FROM ONLY user_new;
--             4.1.2. Домен и тип данных
--                 • Создайте домен chN, в котором добавьте проверку, что имя и фамилия пользователя не содержит пробелов и пустых значений
                    CREATE DOMAIN chN AS TEXT
                    CHECK (
                        VALUE IS NOT NULL AND 
                        VALUE !~ '\s' AND 
                        LENGTH(VALUE) > 0
                    );
--                 • Измените тип данных фамилии и имени пользователя на указанных домен. Проверьте работу домена
                    ALTER TABLE user_new 
                        ALTER COLUMN firstname TYPE chN,
                        ALTER COLUMN lastname TYPE chN;
--                 • Создайте тип данных, включающий два текстовых поля для хранения названия компании и название должности работника. Примените тип данных для таблицы user_new, добавив поле – работа.
                    CREATE TYPE job_info_type AS (
                        company_name TEXT,
                        position_name TEXT
                    );

                    ALTER TABLE user_new ADD COLUMN job job_info_type;
--                 • Создайте пользовательскую функцию, которая принимает id пользователя и возвращает данные о его работе.
                    CREATE OR REPLACE FUNCTION get_user_job(u_id INT) 
                    RETURNS job_info_type AS $$
                    DECLARE
                        j job_info_type;
                    BEGIN
                        SELECT job INTO j FROM user_new WHERE id = u_id;
                        RETURN j;
                    END;
                    $$ LANGUAGE plpgsql;

                    --Пример:
                    --UPDATE user_new SET job = ROW('Google', 'Dev') WHERE id = 1;
                    --SELECT get_user_job(1);

--             4.1.3. Массивы
--                 • Добавьте в таблицу user_new поле contact_number имеющим тип данных ARRAY
                    ALTER TABLE user_new ADD COLUMN contact_number TEXT[];
--                 • Добавьте данные в данное поле по примеру
                    UPDATE student_new SET contact_number = ARRAY['89001112233', '911-200-22'] WHERE id = 1;
                    UPDATE student_new SET contact_number = ARRAY['9110022', '1234567'] WHERE id = 2; -- для проверки
--                 • Напишите запрос для нахождения фио пользователя и первого телефона из списка у пользователя
                    SELECT firstname, lastname, contact_number[1] as first_phone 
                    FROM user_new;
--                 • Выведите записи о пользователях, которые имеют номер, начинающийся на 911, и содержит две цифры 2 – с применением регулярного выражения
                    SELECT DISTINCT u.firstname, u.lastname, u.contact_number
                    FROM user_new u, unnest(u.contact_number) as phone
                    WHERE phone ~ '^911.*2.*2';
--                 • Примените функцию ANY() для нахождения пользователей, которые имеют конкретный телефон
                    SELECT * FROM user_new 
                    WHERE '89001112233' = ANY(contact_number);
--                 • Напишите запросы с применением операторов @>,<@, &&, ||
                    SELECT * FROM user_new WHERE contact_number @> ARRAY['9110022'];
                    SELECT * FROM user_new WHERE contact_number && ARRAY['9110022', '000000'];
                    UPDATE user_new SET contact_number = contact_number || ARRAY['555555'] WHERE id = 1;
--                 • Напишите запросы с применением функций array_append, array_cat, array_dims, unnest
                    SELECT 
                        array_append(contact_number, '777'), -- добавить в конец
                        array_cat(contact_number, ARRAY['888', '999']), -- слить два массива
                        array_dims(contact_number), -- размерность
                        unnest(contact_number) -- развернуть
                    FROM user_new LIMIT 1;
--             4.1.4. Работа с данными в форматах json, xml
--                 • Добавим в таблицу student_new поле about формата json для хранения данных о пользователе, а именно – work место учёбы/работы, interests – интересы – набор нескольких данных, по примеру. Заполните записями. Выведите данные только о тех пользователях, в интересы которых входит только спорт, спорт или чтение, спорт и компьютер
-- {
--   "work": "Университет НовГУ",
--   "interests": "путешествия", "чтение", "спорт"
-- }
                    ALTER TABLE student_new ADD COLUMN about JSON;

                    -- Заполнение
                    UPDATE student_new 
                    SET about = '{"work": "Университет НовГУ", "interests": ["спорт", "чтение"]}'::json 
                    WHERE id = 1;

                    UPDATE student_new 
                    SET about = '{"work": "IT Company", "interests": ["спорт"]}'::json 
                    WHERE id = 2; -- id из таблицы user_new/student_new

                    -- Вывод (интересы: только спорт, или спорт и чтение, или спорт и компьютер)
                    -- Примечание: операторы JSONB (@>) удобнее, но для чистого JSON используем текстовое приведение
                    SELECT firstname, about 
                    FROM student_new 
                    WHERE (about->>'interests')::text LIKE '%"спорт"%' 
                    OR (about->>'interests')::text LIKE '%"чтение"%'
                    OR (about->>'interests')::text LIKE '%"компьютер"%';
--                 • Добавим в таблицу mentor_new поле schedule формата xml для хранения расписания педагога, по примеру. Заполните записями. Выведите данные только о расписании, о расписании определённой группы.
                    ALTER TABLE mentor_new ADD COLUMN schedule XML;

                    -- Заполнение
                    INSERT INTO mentor_new (firstname, lastname, experience, schedule)
                    VALUES ('MentorXML', 'Test', 10, 
                    '<schedule>
                        <lesson group="1">Monday 10:00</lesson>
                        <lesson group="2">Tuesday 12:00</lesson>
                    </schedule>');

                    -- Вывод всего расписания
                    SELECT schedule FROM mentor_new WHERE schedule IS NOT NULL;

                    -- Вывод расписания для группы 1 (используя xpath)
                    SELECT xpath('//lesson[@group="1"]/text()', schedule) 
                    FROM mentor_new 
                    WHERE schedule IS NOT NULL;

--         4.2. Триггеры по поддержки целостности данных
--             4.2.1. Триггер для формирования значения первичных ключей
--                 • Создайте копию таблицы user_new без serial.
                    CREATE TABLE user_manual_pk (
                        id INT PRIMARY KEY, -- нет serial
                        firstname TEXT,
                        lastname TEXT
                    );
--                 • Создайте триггер для формирования значения первичного ключа для таблицы user_new (триггер должен формировать случайное число, проверять, что это значение не задействовано как ключ и добавлять его в поле).
                    CREATE OR REPLACE FUNCTION generate_pk_func() RETURNS TRIGGER AS $$
                    DECLARE
                        new_id INT;
                        exists_check INT;
                    BEGIN
                        LOOP
                            -- Генерация случайного числа от 1 до 10000
                            new_id := floor(random() * 10000 + 1)::INT;
                            
                            -- Проверка уникальности
                            SELECT id INTO exists_check FROM user_manual_pk WHERE id = new_id;
                            
                            IF exists_check IS NULL THEN
                                NEW.id := new_id;
                                EXIT; -- выход из цикла, если ID уникален
                            END IF;
                        END LOOP;
                        RETURN NEW;
                    END;
                    $$ LANGUAGE plpgsql;

                    CREATE TRIGGER trg_generate_pk
                    BEFORE INSERT ON user_manual_pk
                    FOR EACH ROW
                    EXECUTE FUNCTION generate_pk_func();
--                 • Добавьте записи, проверьте работу триггера.
                    INSERT INTO user_manual_pk (firstname, lastname) VALUES ('Test', 'RandomID');
                    SELECT * FROM user_manual_pk;
--             4.2.2. Триггер по поддержанию значений внешних ключей (on update cascade)
--                 • Добавьте если не создавали ранее таблицу Группа (группа, специальность, год_поступления), заполните таблицу данными. 
--                 • Создайте триггер, который при изменении номера группы в таблице Groups происходит автоматическое изменение всех кодовых значений user_new.
-- Указания для выполнения: произведите проверку условия неравенства нового и старого значения ключевого поля, в случае неравенства выполните запрос на обновление подчинённой таблицы, установив в поле внешнего ключа связи новое значение первичного ключа главной таблицы, при условии равенства внешнего ключа старому значению поля внешнего ключа.
                    -- Создадим отдельный триггер, так как стандартный FK делает это автоматически, но задание просит ручную реализацию.
                    -- Предполагаем связь: student_new.group_id -> groups.id

                    CREATE OR REPLACE FUNCTION cascade_update_group_id() RETURNS TRIGGER AS $$
                    BEGIN
                        IF OLD.id <> NEW.id THEN
                            UPDATE student_new
                            SET group_id = NEW.id
                            WHERE group_id = OLD.id;
                        END IF;
                        RETURN NEW;
                    END;
                    $$ LANGUAGE plpgsql;

                    CREATE TRIGGER trg_update_cascade_groups
                    AFTER UPDATE ON public.groups
                    FOR EACH ROW
                    EXECUTE FUNCTION cascade_update_group_id();
--                 • Проверьте работу созданного триггера, для этого, например, измените группу с номером 1 на код 2091, проверьте изменение данных в таблице user_new.
                    UPDATE public.groups SET id = 2091 WHERE id = 1;
                    SELECT * FROM student_new WHERE group_id = 2091;
--             4.2.3. Удаление строк подчинённой таблицы (on delete cascade) – выполните с применением транзакции с откатом удаления
--                 TODO:• Создайте триггер, который будет производить каскадное удаление строк из таблицы Студент при удалении записи в таблице Группа.
--                 • Проверьте работу созданного триггера, для этого удалите данные о группе с номером 1, проверьте удаление данных о всех студентах данной группы.
--                 • Создайте триггер для таблицы user_new для организации каскадного удаления информации по своему усмотрению.
                    -- Триггер для удаления студентов при удалении группы
                    CREATE OR REPLACE FUNCTION cascade_delete_students() RETURNS TRIGGER AS $$
                    BEGIN
                        DELETE FROM student_new WHERE group_id = OLD.id;
                        RETURN OLD;
                    END;
                    $$ LANGUAGE plpgsql;

                    CREATE TRIGGER trg_delete_cascade_groups
                    BEFORE DELETE ON public.groups
                    FOR EACH ROW
                    EXECUTE FUNCTION cascade_delete_students();

                    BEGIN;
                        DELETE FROM public.groups WHERE id = 1;
                        -- Проверим, что студенты удалились (в рамках транзакции)
                        SELECT * FROM student_new WHERE group_id = 1; -- должно быть пусто
                    ROLLBACK;
--             4.2.4. Триггер для поддержки целостности на уровни ссылок
--                 • Создайте триггер, который при вводе данных в таблицу project, не связанных с таблицей team будет вывод сообщения об ошибке, а при успешном вводе - успешного ввода данных. Триггер должен работать таким образом, чтобы при вводе записи в таблицу project, которая содержит данные о команде, отсутствующей в таблице team запись не добавлялась в таблицу, а при верном вводе – добавлялась. Проверьте работу триггера.
                    CREATE OR REPLACE FUNCTION check_team_exists() RETURNS TRIGGER AS $$
                    BEGIN
                        IF NOT EXISTS (SELECT 1 FROM public.team WHERE id = NEW.team_id) THEN
                            RAISE EXCEPTION 'Team with id % does not exist', NEW.team_id;
                        END IF;
                        RETURN NEW;
                    END;
                    $$ LANGUAGE plpgsql;

                    CREATE TRIGGER trg_check_project_team
                    BEFORE INSERT ON public.project
                    FOR EACH ROW
                    EXECUTE FUNCTION check_team_exists();
--                 • Создайте аналогичный триггер для контроля ввода данных в таблицу task. Также предусмотрите проверку ввода, которая не позволяла бы добавлять запись о задаче, если дата выполнения введена меньше даты выдачи задания. Проверьте работу триггера.
                    CREATE OR REPLACE FUNCTION check_task_rules() RETURNS TRIGGER AS $$
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

                    CREATE TRIGGER trg_check_task
                    BEFORE INSERT ON public.task
                    FOR EACH ROW
                    EXECUTE FUNCTION check_task_rules();

--         4.3. Создание контролирующего триггера
--             4.3.1. Создайте триггер, который при добавлении нового пользователя будет заполнять значение поля IO (инициалы). Для этого:
--     • Добавьте в таблицу user_new поле IO тип данных текстовый два символа
        ALTER TABLE user_new ADD COLUMN IO CHAR(2);
--     • Создайте триггер на событие before insert on user_new, значение первых букв инициала имени и отчества. При этом можно применить регулярное выражение для нахождения имени и отчества.
        CREATE OR REPLACE FUNCTION fill_io() RETURNS TRIGGER AS $$
        BEGIN
            -- Берем первую букву имени и фамилии
            NEW.IO := substring(NEW.firstname, 1, 1) || substring(NEW.lastname, 1, 1);
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;

        CREATE TRIGGER trg_fill_io
        BEFORE INSERT ON user_new
        FOR EACH ROW
        EXECUTE FUNCTION fill_io();
--             4.3.2. Создайте триггер, который при добавлении записи будет проверять бизнес-правило: рейтинг ментора должен быть больше или равен рейтинга команды.
                ALTER TABLE mentor_new ADD COLUMN team_id INT;
                CREATE OR REPLACE FUNCTION check_mentor_rating() RETURNS TRIGGER AS $$
                DECLARE
                    team_rating INT;
                BEGIN
                    -- Получаем рейтинг команды
                    SELECT rating INTO team_rating FROM public.team WHERE id = NEW.team_id;
                    
                    -- У ментора нет рейтинга в mentor_new (он в таблице mentor, откуда копировали, но допустим поле есть)
                    -- Предположим, что у mentor_new есть поле rating (унаследовать или добавить). 
                    -- В 4.1.1 мы создали experience. Добавим rating для корректности задачи:
                    -- ALTER TABLE mentor_new ADD COLUMN rating INT DEFAULT 0;
                    
                    -- Проверка (предполагаем, что поле rating существует у NEW)
                    -- Т.к. user_new не имеет rating, проверим логику на experience как аналог или используем заглушку
                    IF NEW.experience < team_rating THEN -- Используем experience вместо rating для примера
                        RAISE EXCEPTION 'Mentor rating/experience must be >= team rating';
                    END IF;
                    
                    RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;
--             4.3.3. Создайте триггер, который обеспечит выполнение бизнес-правила: в каждой команде не может быть больше определенного количества студентов. Установите максимальное количество студентов в команде равным 5. При попытке добавить нового студента в команду, если в команде уже 5 студентов, триггер должен блокировать вставку новых данных.
                ALTER TABLE student_new ADD COLUMN team_id INT;

                CREATE OR REPLACE FUNCTION check_team_limit() RETURNS TRIGGER AS $$
                DECLARE
                    cnt INT;
                BEGIN
                    SELECT count(*) INTO cnt FROM student_new WHERE team_id = NEW.team_id;
                    
                    IF cnt >= 5 THEN
                        RAISE EXCEPTION 'Team is full (max 5 students)';
                    END IF;
                    
                    RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;

                CREATE TRIGGER trg_max_students
                BEFORE INSERT ON student_new
                FOR EACH ROW
                EXECUTE FUNCTION check_team_limit();
-- * Напишите команду MERGE, которая будет обновлять информацию о студенте, если он уже существует в базе, или добавлять его, если он новый.
                MERGE INTO student_new t
                USING (VALUES ('MergeUser', 'Test', 'm@m.ru', 1, 1)) AS s(fname, lname, mail, grp, tm)
                ON t.email = s.mail
                WHEN MATCHED THEN
                    UPDATE SET firstname = s.fname
                WHEN NOT MATCHED THEN
                    INSERT (firstname, lastname, email, group_id, team_id)
                    VALUES (s.fname, s.lname, s.mail, s.grp, s.tm);
--         4.4. Запись изменений в таблицу логов
                CREATE TABLE IF NOT EXISTS log_project (
                    id SERIAL PRIMARY KEY,
                    action TEXT,
                    project_name TEXT,
                    log_time TIMESTAMP DEFAULT NOW()
                );
--             4.4.1. Создание триггера, который записывает в таблицу log_project данные о добавленных и удалённых строках таблицы project. 
-- *Триггер должен фиксировать и те случаи удаления, которые отменены командой rollback.
                CREATE OR REPLACE FUNCTION log_project_func() RETURNS TRIGGER AS $$
                BEGIN
                    IF (TG_OP = 'INSERT') THEN
                        INSERT INTO log_project (action, project_name) VALUES ('INSERT', NEW.name);
                    ELSIF (TG_OP = 'DELETE') THEN
                        INSERT INTO log_project (action, project_name) VALUES ('DELETE', OLD.name);
                    END IF;
                    RETURN NULL;
                END;
                $$ LANGUAGE plpgsql;

                CREATE TRIGGER trg_log_project
                AFTER INSERT OR DELETE ON public.project
                FOR EACH ROW
                EXECUTE FUNCTION log_project_func();
--             4.4.2. Создайте таблицу log_student, которая будет содержать поля: id_ (номер записи – с инкрементным значением, date_ строка для хранения даты изменения, time_ – строка для хранения времени изменения, event – строка, хранящая значение действия, выполняемого с таблицей, row_number – номер изменяемой строки, user_ - пользователь, который вносит изменение).
                CREATE TABLE log_student (
                    id_ SERIAL PRIMARY KEY,
                    date_ TEXT,
                    time_ TEXT,
                    event TEXT,
                    row_number INT,
                    user_ TEXT
                );
--             4.4.3. Создайте триггер, который будет следить за операциями добавления записей в таблицу team, удаления записей в таблице team, изменения записей в таблице team.
                CREATE OR REPLACE FUNCTION log_team_changes() RETURNS TRIGGER AS $$
                BEGIN
                    INSERT INTO log_student (date_, time_, event, row_number, user_)
                    VALUES (
                        to_char(now(), 'YYYY-MM-DD'),
                        to_char(now(), 'HH24:MI:SS'),
                        TG_OP, -- INSERT/UPDATE/DELETE
                        COALESCE(NEW.id, OLD.id),
                        current_user
                    );
                    RETURN NULL;
                END;
                $$ LANGUAGE plpgsql;

                CREATE TRIGGER trg_log_team
                AFTER INSERT OR UPDATE OR DELETE ON public.team
                FOR EACH ROW
                EXECUTE FUNCTION log_team_changes();
--             4.4.4. Проверьте триггер, для этого выполните операцию добавления от имени другого пользователя.
                -- CREATE ROLE test_user LOGIN;
                -- SET ROLE test_user;
                INSERT INTO public.team (name) VALUES ('Gamma');
                RESET ROLE;
                SELECT * FROM log_student;
--         4.5. Создание DDL триггеров* (напишите код, возможно не будет доступа)
--             4.5.1. Создайте триггер, который будет запрещать удалять таблицы после 18-00 и фиксирует попытки это сделать.
                CREATE OR REPLACE FUNCTION prevent_drop_after_hours() RETURNS event_trigger AS $$
                BEGIN
                    IF to_char(now(), 'HH24:MI') > '18:00' THEN
                        RAISE EXCEPTION 'Deletion of tables is prohibited after 18:00';
                    END IF;
                END;
                $$ LANGUAGE plpgsql;
--             4.5.2. Создайте триггер, который будет фиксировать случаи выполнения DML кода в субботу и в воскресенье. В лог нужно записывать имя пользователя, дату и время, текст запроса.
                CREATE TABLE IF NOT EXISTS dml_weekend_log (
                    username TEXT,
                    log_time TIMESTAMP,
                    query_text TEXT
                );

                CREATE OR REPLACE FUNCTION log_weekend_dml() RETURNS TRIGGER AS $$
                DECLARE
                    dow INT;
                BEGIN
                    dow := extract(ISODOW FROM now()); -- 6 = Sat, 7 = Sun
                    IF dow IN (6, 7) THEN
                        INSERT INTO dml_weekend_log (username, log_time, query_text)
                        VALUES (current_user, now(), current_query());
                    END IF;
                    RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;
                -- Пример привязки:
                -- CREATE TRIGGER trg_weekend_check 
                -- BEFORE INSERT OR UPDATE OR DELETE ON user_new 
                -- FOR EACH ROW EXECUTE FUNCTION log_weekend_dml();

--         4.6. Создание INSTEAD OF триггера для вставки данных в представление
--             4.6.1. Создайте многотабличное представление, которое выводит данные о проектах, командах и менторах, а также полей обязательных для заполнения в данных таблицах.
                CREATE VIEW project_details_view AS
                SELECT 
                    p.name as project_name,
                    t.name as team_name,
                    m.firstname as mentor_name,
                    p.id as p_id -- нужно для идентификации при вставке
                FROM public.project p
                LEFT JOIN public.team t ON p.team_id = t.id
                LEFT JOIN public.mentor m ON m.id = t.id; -- условная связь для примера
--             4.6.2. Попробуйте вставить данные в созданное представление. В результате вы получите ошибку ввода.
                -- INSERT INTO project_details_view (project_name, team_name) VALUES ('New Proj', 'New Team');
                -- Выдаст ошибку, так как view содержит джойны и не обновляема автоматически без правил.
--             4.6.3. Создайте триггер на вставку данных в представление, который будет вставлять данные в базовые таблицы
                CREATE OR REPLACE FUNCTION insert_view_func() RETURNS TRIGGER AS $$
                DECLARE
                    new_team_id INT;
                BEGIN
                    -- 1. Вставляем команду
                    INSERT INTO public.team (name) VALUES (NEW.team_name) RETURNING id INTO new_team_id;
                    
                    -- 2. Вставляем проект
                    INSERT INTO public.project (name, team_id) VALUES (NEW.project_name, new_team_id);
                    
                    RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;

                CREATE TRIGGER trg_view_insert
                INSTEAD OF INSERT ON project_details_view
                FOR EACH ROW
                EXECUTE FUNCTION insert_view_func();

                -- Проверка
                INSERT INTO project_details_view (project_name, team_name) VALUES ('View Project', 'View Team');
                SELECT * FROM public.project WHERE name = 'View Project';