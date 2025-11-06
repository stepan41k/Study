-- 1.	Изменение структуры данных и обновление записей в базе данных
-- 1.1.	Создайте запрос на добавление в таблицу project поля about типа данных text, для хранения данных краткого содержания проекта. Напишите запрос update для добавления данных в поле.
    ALTER TABLE project
ADD COLUMN about TEXT;

UPDATE project
SET about = 'Краткое описание для проекта ' || projectname
WHERE id IN (101, 102, 105);
-- 1.2.	В таблицу student добавьте поле категория, типа данных varchar(15) по умолчанию – студент.
    ALTER TABLE student
ADD COLUMN категория VARCHAR(15) DEFAULT 'студент';
-- 1.3.	Создайте запрос для добавления поля result в таблицу project типа real, а также поле project_deadline целого типа данных со значением по умолчанию, равным 30 дней.
    ALTER TABLE project
ADD COLUMN result REAL,
ADD COLUMN project_deadline INT DEFAULT 30;

-- 2.	Создание представлений для выборки данных
-- 2.1.	Создайте следующее представление:
    CREATE VIEW view_project AS
SELECT
    projectname,
    price
FROM
    project;
-- create view view_project AS select projectname, price from project;
-- Создайте запрос на выборку всех записей вашего представления.
    SELECT * FROM view_project;
-- 2.2.	Создайте представление project_type, содержащее поля: тип проекта, название проекта, год создания проекта. Создайте запрос на выборку всех записей созданного представления.
    CREATE OR REPLACE VIEW project_type_view AS -- добавил _view, т.к. project_type уже есть как колонка
SELECT
    project_type,
    projectname,
    EXTRACT(YEAR FROM startdate) AS creation_year
FROM
    project;
-- 2.3.	Создайте представление about на основании запроса, который бы в зависимости от шифра проекта в таблице выдавал бы для тип проекта, логику сделать свою.
    CREATE VIEW project_about_view AS
SELECT
    projectname,
    CASE
        WHEN id BETWEEN 101 AND 105 THEN 'Стандартный'
        WHEN id BETWEEN 106 AND 110 THEN 'Крупный'
        ELSE 'Сверхкрупный'
    END AS project_cipher_type
FROM
    project;

    SELECT * FROM project_about_view;
-- 2.4.	Создайте представление project_dl, которое в зависимости от наличия задолженности выполнения проекта (количество дней между датой начала и датой окончания не больше допустимого количества), выдавал бы текста «Премии не будет», иначе «Премия будет».
    CREATE VIEW project_dl AS
SELECT
    projectname,
    (enddate - startdate) AS duration,
    project_deadline,
    CASE
        WHEN (enddate - startdate) > project_deadline THEN 'Премии не будет'
        ELSE 'Премия будет'
    END AS bonus_status
FROM
    project;

    SELECT * FROM project_dl;
-- 2.5.	Создайте представление max_z, которое содержит список студентов, которые выполняли проекты, имеющую наибольшее количество не вовремя сданных.

    CREATE VIEW max_prosr AS
WITH late_projects_count AS (
    -- Шаг 1: Считаем количество просроченных проектов для каждой команды
    SELECT
        s.id AS student_id,
        s.lastname,
        s.firstname,
        COUNT(p.id) FILTER (WHERE (p.enddate - p.startdate) > p.project_deadline) AS late_count
    FROM
        student s
    JOIN
        project p ON s.idcommand = p.idcommand
    GROUP BY
        s.id, s.lastname, s.firstname
),
ranked_students AS (
    -- Шаг 2: Ранжируем студентов по количеству просроченных проектов
    SELECT
        student_id,
        lastname,
        firstname,
        late_count,
        DENSE_RANK() OVER (ORDER BY late_count DESC) as rnk
    FROM
        late_projects_count
)
-- Шаг 3: Выбираем только тех, у кого ранг равен 1 (максимальное количество)
SELECT
    lastname,
    firstname,
    late_count
FROM
    ranked_students
WHERE
    rnk = 1;

    SELECT * FROM max_prosr;

-- 3.	Создание правил select для представлений
-- 3.1.	Создайте таблицу student_command, которое бы показывало фамилию +имя_студента (как поле студент) и название команды, как поле команда и поле выплата как стоимость реализации проекта / количество студентов в команде, реализующих проект. Напишите правило select для представления.
    CREATE OR REPLACE VIEW student_command AS
WITH command_student_count AS (
    -- Подсчитываем количество студентов в каждой команде
    SELECT idcommand, COUNT(id) as student_count
    FROM student
    GROUP BY idcommand
)
SELECT
    s.firstname || ' ' || s.lastname AS student_name,
    c.command AS command_name,
    p.projectname,
    p.price / csc.student_count AS payout,
    s.id AS student_id,
    c.id AS command_id
FROM
    student s
JOIN
    command c ON s.idcommand = c.id
JOIN
    project p ON c.id = p.idcommand
JOIN
    command_student_count csc ON s.idcommand = csc.idcommand;
    *Примечание: Правила `ON SELECT` — устаревшая концепция. Представления сами по себе являются реализацией этого механизма.*

-- 3.2.	Создайте представление student_com, на основании представления student_command, для нахождения общего количества студентов в каждой команде.
    CREATE VIEW student_com AS
SELECT
    command_name,
    COUNT(DISTINCT student_name) AS total_students
FROM
    student_command
GROUP BY
    command_name;
-- 3.3.	Создайте представление task_project, на основании представления student_command, для нахождения итоговой и средней выплаты по каждой команде.
    CREATE VIEW payout_by_command AS
SELECT
    command_name,
    SUM(payout) AS total_payout,
    AVG(payout) AS average_payout
FROM
    student_command
GROUP BY
    command_name;

-- 4.	Создание правил insert для представлений 
-- 4.1.	Напишите правила insert/delete для представления student_command.

Примечание: Эта задача сложна для реализации через RULE, так как требует условной логики. Современный подход — использовать триггер INSTEAD OF. Но для выполнения задания приведем пример с правилом, который будет работать с ограничениями.
    CREATE OR REPLACE RULE student_command_delete AS
ON DELETE TO student_command
DO INSTEAD
    DELETE FROM student
    WHERE id = OLD.student_id;
-- 4.1.1.	Для правила insert предусмотрите проверку существования команды в случае, если команды нет, требуется добавить команду и соответственно студента в команду, в случае существования команды – добавить только студента в команду с найденным номером.
    (сложно и не рекомендуется в продакшене):
Это правило не может проверить наличие команды и вставить ее. Правила не поддерживают такую логику. Ниже приведена реализация через триггерную функцию, что является правильным подходом.
    CREATE OR REPLACE FUNCTION student_command_insert_trigger()
RETURNS TRIGGER AS $$
DECLARE
    new_command_id INT;
    student_firstname TEXT;
    student_lastname TEXT;
BEGIN
    -- Разбираем полное имя на имя и фамилию
    student_firstname := SPLIT_PART(NEW.student_name, ' ', 1);
    student_lastname := SPLIT_PART(NEW.student_name, ' ', 2);

    -- Проверяем, существует ли команда
    SELECT id INTO new_command_id FROM command WHERE command = NEW.command_name;

    -- Если команды нет, создаем ее
    IF NOT FOUND THEN
        INSERT INTO command (command) VALUES (NEW.command_name) RETURNING id INTO new_command_id;
    END IF;

    -- Вставляем студента с ID команды
    INSERT INTO student (firstname, lastname, idcommand) VALUES (student_firstname, student_lastname, new_command_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER student_command_insert
INSTEAD OF INSERT ON student_command
FOR EACH ROW EXECUTE FUNCTION student_command_insert_trigger();
-- 4.1.2.	Для правила delete предусмотрите проверку существования команды, в случае существования выполните удаление студентов данной команды.
-- 4.2.	Создайте представление tek_project для выборки записей из таблицы project, в которых поле Дата_окончания работы над проектом больше текущей даты с указанием названия команды, реализующий проект. Напишите правило update для редактирования полей представления команда, дата окончания работы.
    CREATE VIEW tek_project AS
SELECT
    p.projectname,
    p.enddate,
    c.command AS command_name,
    p.id AS project_id,
    c.id AS command_id
FROM
    project p
JOIN
    command c ON p.idcommand = c.id
WHERE
    p.enddate > CURRENT_DATE;

-- Сообщение: CREATE VIEW

-- Правило для обновления
CREATE OR REPLACE RULE tek_project_update AS
ON UPDATE TO tek_project
DO INSTEAD (
    -- Обновляем название команды
    UPDATE command SET command = NEW.command_name WHERE id = OLD.command_id;
    -- Обновляем дату окончания проекта
    UPDATE project SET enddate = NEW.enddate WHERE id = OLD.project_id;
);
-- 4.3.	Создание логов
-- 4.3.1.	Создайте таблицу log_student, включающую поля код записи, пользователь, текущая дата, операция
    CREATE TABLE log_student (
    log_id SERIAL PRIMARY KEY,
    username TEXT DEFAULT current_user,
    log_date TIMESTAMP DEFAULT now(),
    operation VARCHAR(10) NOT NULL,
    student_info TEXT
);
-- 4.3.2.	Напишите правило, которое при вставке/изменении/удалении данных в таблице student будет добавлять запись в таблицу логов.
    CREATE OR REPLACE RULE student_log_insert AS
ON INSERT TO student
DO ALSO
    INSERT INTO log_student (operation, student_info)
    VALUES ('INSERT', 'Добавлен: ' || NEW.firstname || ' ' || NEW.lastname);

-- Правило на обновление
CREATE OR REPLACE RULE student_log_update AS
ON UPDATE TO student
DO ALSO
    INSERT INTO log_student (operation, student_info)
    VALUES ('UPDATE', 'Изменен: ID=' || OLD.id || ', Новые данные: ' || NEW.firstname || ' ' || NEW.lastname);

-- Правило на удаление
CREATE OR REPLACE RULE student_log_delete AS
ON DELETE TO student
DO ALSO
    INSERT INTO log_student (operation, student_info)
    VALUES ('DELETE', 'Удален: ' || OLD.firstname || ' ' || OLD.lastname);
-- 4.3.3.	Выполните операции вставки/изменения/удаления записей в таблицу student.
    INSERT INTO student (firstname, lastname, groupname, idcommand) VALUES ('Тест', 'Тестов', 'ПИ-31', 1);
UPDATE student SET lastname = 'Тестович' WHERE firstname = 'Тест';
DELETE FROM student WHERE firstname = 'Тест';
-- 4.3.4.	Проверьте записи в таблице log_student.
    SELECT * FROM log_student;
-- 5.	Создание материализованных представлений
-- 5.1.	Создайте представление project_student для получения данных о проектах студентов (ФИО студента, Проект, Дата начала работы, Дата окончания, задача (задачи))
    CREATE MATERIALIZED VIEW project_student AS
SELECT
    s.firstname || ' ' || s.lastname AS student_fio,
    p.projectname,
    p.startdate,
    p.enddate,
    -- Агрегируем все задачи по проекту в одну строку
    STRING_AGG(t.task, '; ') AS tasks
FROM
    student s
JOIN
    project p ON s.idcommand = p.idcommand
LEFT JOIN
    task t ON p.id = t.idproject
GROUP BY
    student_fio, p.projectname, p.startdate, p.enddate;
-- 5.2.	Добавьте по одной записи в таблицы project, student, и две записи в таблицу task. Просмотрите результат выборки данных из материализованного представления.
    INSERT INTO command (id, command) VALUES (11, 'Explorers');
INSERT INTO student (id, firstname, lastname, groupname, idcommand) VALUES (20, 'Новый', 'Студент', 'ИC-41', 11);

-- Добавляем новый проект для этой команды
INSERT INTO project (id, projectname, idcommand, startdate, enddate) VALUES (200, 'Проект для MV', 11, '2025-10-01', '2025-11-01');

-- Добавляем две задачи к новому проекту
INSERT INTO task (task, idproject) VALUES ('Первая задача MV', 200), ('Вторая задача MV', 200);

SELECT * FROM project_student WHERE projectname = 'Проект для MV';
-- 5.3.	Обновите созданное представление.
    REFRESH MATERIALIZED VIEW project_student;

    SELECT * FROM project_student WHERE projectname = 'Проект для MV';
-- 5.4.	Найдите записи из созданного материализованного представления – постройте план запроса – проанализируйте время выполнения.
    EXPLAIN ANALYZE SELECT * FROM project_student WHERE projectname LIKE 'Разработка%';
-- 5.5.	Выполните запрос, на котором основано созданное представление – постройте план запроса – проанализируйте время выполнения запроса, сделайте выводы.
    EXPLAIN ANALYZE
SELECT
    s.firstname || ' ' || s.lastname AS student_fio,
    p.projectname,
    p.startdate,
    p.enddate,
    STRING_AGG(t.task, '; ') AS tasks
FROM
    student s
JOIN
    project p ON s.idcommand = p.idcommand
LEFT JOIN
    task t ON p.id = t.idproject
WHERE p.projectname LIKE 'Разработка%'
GROUP BY
    student_fio, p.projectname, p.startdate, p.enddate;
-- 5.6.	Создайте индекс по полю – название проекта, постройте план запроса – результаты сравните.
    CREATE INDEX idx_project_student_projectname ON project_student (projectname);

    EXPLAIN ANALYZE SELECT * FROM project_student WHERE projectname = 'Проект для MV';
-- 6.	Наследование и правила*
-- 6.1.	Создайте таблицы-наследники по группам student3091, student3092, student3093.
    CREATE TABLE student_is41 (
    CHECK (groupname = 'ИC-41')
) INHERITS (student);

-- Создаем таблицу для группы ПИ-31
CREATE TABLE student_pi31 (
    CHECK (groupname = 'ПИ-31')
) INHERITS (student);

-- Создаем таблицу для группы КБ-21
CREATE TABLE student_kb21 (
    CHECK (groupname = 'КБ-21')
) INHERITS (student);
-- 6.2.	Напишите правила для автоматического распределения студентов при вставке записей в таблицу student.
    CREATE OR REPLACE FUNCTION route_student_by_group()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.groupname = 'ИC-41') THEN
        INSERT INTO student_is41 VALUES (NEW.*);
    ELSIF (NEW.groupname = 'ПИ-31') THEN
        INSERT INTO student_pi31 VALUES (NEW.*);
    ELSIF (NEW.groupname = 'КБ-21') THEN
        INSERT INTO student_kb21 VALUES (NEW.*);
    ELSE
        -- Если группа не соответствует, можно либо вызвать ошибку, либо вставить в родительскую
        RAISE EXCEPTION 'Неизвестная группа: %', NEW.groupname;
    END IF;
    -- Возвращаем NULL, чтобы отменить вставку в родительскую таблицу student
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER route_student_trigger
BEFORE INSERT ON student
FOR EACH ROW EXECUTE FUNCTION route_student_by_group();
-- 6.3.	Протестируйте работу правил вставкой записей, проверьте полученный результат.
    INSERT INTO student (firstname, lastname, groupname) VALUES ('Анна', 'Иванова', 'ИC-41');
INSERT INTO student (firstname, lastname, groupname) VALUES ('Петр', 'Петров', 'ПИ-31');

    SELECT * FROM student_is41;

    SELECT * FROM student_pi31;

    SELECT * FROM student_kb21;

    SELECT * FROM ONLY student;
-- 7.	Привилегии доступа к данным
-- 7.1.	Проверьте роли пользователям stud1 07&3886V&g, stud2 07&3886V&f
    CREATE ROLE stud1 WITH LOGIN PASSWORD '07&3886V&g';
CREATE ROLE stud2 WITH LOGIN PASSWORD '07&3886V&f';
-- 7.2.	Задайте привилегии доступа (учтите, что разрешение чтение данных должно быть дано при всех других вариантах разрешений)
-- 7.2.1.	Задайте привилегии доступа (учтите, что разрешение чтение данных должно быть дано при всех других вариантах разрешений)
    GRANT SELECT ON project_student TO stud1;
-- 7.2.2.	Пользователю stud1 дайте разрешение: 
-- -	на чтение представления project_student.
-- -	изменение данных в таблице student.
-- -	разрешение на добавление и удаление данных в представлении project_student.
-- -	чтение данных представления tek_project с возможностью передачи привилегии
-- -	разрешение на добавление записей в таблицу project.
    GRANT UPDATE ON student TO stud1;
    GRANT INSERT, DELETE ON project_student TO stud1;
    GRANT SELECT ON tek_project TO stud1 WITH GRANT OPTION;
    GRANT INSERT ON project TO stud1;
-- 7.3.	Проверка привилегий
-- -	Проверка привилегий на конкретную таблицу/представление (запросить привилегии для конкретного объекта (таблицы project , представления project_student). Напишите запрос к таблице information_schema.table_privileges. Добавьте условие выборки – нужная таблица или представление.
-- -	Напишите запрос с применением функции STRING_AGG(поле, разделитель) для агрегации по полям пользователь имя таблицы с указанием привилегий.
    SELECT
    grantee,
    table_schema,
    table_name,
    privilege_type
FROM
    information_schema.table_privileges
WHERE
    table_name IN ('project', 'project_student', 'tek_project')
    AND grantee = 'stud1';



    SELECT
    grantee,
    table_name,
    STRING_AGG(privilege_type, ', ') AS privileges
FROM
    information_schema.table_privileges
WHERE
    grantee IN ('stud1', 'stud2')
GROUP BY
    grantee, table_name
ORDER BY
    grantee, table_name;
 
-- 7.4.	Использование функций has_*_privilege – используйте функции ниже
-- -	has_table_privilege([user, ] table, privilege)
    SELECT has_table_privilege('stud1', 'student', 'UPDATE');
-- -	has_schema_privilege([user, ] schema, privilege)
    SELECT has_schema_privilege('stud2', 'public', 'USAGE');
-- -	has_database_privilege([user, ] database, privilege)
    SELECT has_database_privilege('stud1', current_database(), 'CONNECT');

-- 8.	Создание политик доступа
-- 8.1.	В таблице student выберите поле для идентификации пользователя (можно использовать поле lastname или name).
-- 8.2.	Обновите существующие записи, добавьте записи или обновите любую запись с изменением его значения на пользователей (stud1, stud2).
    UPDATE student SET email = 'stud1' WHERE id = 2;
UPDATE student SET email = 'stud2' WHERE id = 5;
-- 8.3.	Включите защиту на уровне строк для таблицы student: 
-- ALTER TABLE student ENABLE ROW LEVEL SECURITY
    ALTER TABLE student ENABLE ROW LEVEL SECURITY;
-- 8.4.	Создайте политику для отношения student, позволяющую только членам роли stud1 обращаться к строкам отношения и при этом только к своим (в таблице student должна быть запись о пользователе stud1.
    CREATE POLICY stud1_policy ON student
FOR ALL
TO stud1
USING (email = current_user)
WITH CHECK (email = current_user);
-- 8.5.	Создайте политику, чтобы stud2 мог видеть и добавлять любые строки.
    CREATE POLICY stud2_policy ON student
FOR ALL
TO stud2
USING (true)
WITH CHECK (true);
-- 8.6.	Напишите запрос на создание политики, которая позволит всем пользователям видеть все строки в таблице users, но менять только свою собственную.
    CREATE POLICY public_select_all ON student
FOR SELECT
USING (true);

    CREATE POLICY user_modify_own ON student
FOR UPDATE
USING (email = current_user)
WITH CHECK (email = current_user);
-- 8.7.	Проверьте созданные политики доступа (напишем запрос по примеру п.7.3 для агрегации политик по tablename с обращением к nаблице pg_policies).
    SELECT
    p.polname AS policy_name,
    n.nspname || '.' || c.relname AS table_name,
    -- Агрегируем роли, к которым применяется политика
    (SELECT STRING_AGG(r.rolname, ',') FROM pg_roles r WHERE r.oid = ANY(p.polroles)) AS roles,
    p.polcmd AS command,
    pg_get_expr(p.polqual, p.polrelid) AS using_expression,
    pg_get_expr(p.polwithcheck, p.polrelid) AS check_expression
FROM
    pg_policy p
JOIN
    pg_class c ON c.oid = p.polrelid
JOIN
    pg_namespace n ON n.oid = c.relnamespace
WHERE
    c.relname = 'student';
