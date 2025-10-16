-- Перед выполнением заданий убедитесь, что структура таблиц вашей базы данных соответствует структуре ниже
-- project (id, projectname, about, startdate, enddate, status, price, idcommand, project_type)
-- student (id, lastname, firstname, role, email, yearb, groupname, idcommand)
-- command (id, command)
-- task (id,task, idproject)
-- resource (id, resource, idproject)
-- grouplist (groupname, sp)
-- mentor (id, lastname, firstname, email, idcommand)


-- При выполнении задания создавайте отчет, включающий само задание, sql-код.

        -- 4.1. Формирование многотабличных запросов
            -- 4.1.1. Выведите фамилию и имена студента, и название команды, в которой он состоит.
                SELECT s.lastname, s.firstname, c.command
                FROM student s
                JOIN command c ON s.idcommand = c.id;
            -- 4.1.2. Выведите фамилии студентов, которые выполняют проект по указанной теме (тема ваша, например, исследовательский).
                SELECT s.lastname, s.firstname
                FROM student s
                JOIN project p ON s.idcommand = p.idcommand
                WHERE p.project_type = 'исследовательский';
            -- 4.1.3. Выберите все проекты команды A&B.
                SELECT p.projectname, p.about, p.startdate, p.enddate, p.status
                FROM project p
                JOIN command c ON p.idcommand = c.id
                WHERE c.command = 'A&B';
            -- 4.1.4. Найдите фамилии и имена тех студентов, которые работают над проектами, название которых начинается на указанную букву (например, буква «К») в период от начала года до текущей даты.
                SELECT s.lastname, s.firstname
                FROM student  s
                JOIN project p ON s.idcommand = p.idcommand
                WHERE p.projectname LIKE 'К%' AND p.startdate >= DATE_TRUNC('year', CURRENT_DATE) AND p.startdate <= CURRENT_DATE;
            -- 4.1.5. Перечислите студентов, котораые в команде под руководством Телиной Ирины Сергеевны.
                SELECT s.lastname, s.firstname
                FROM student s
                JOIN mentor m ON s.idcommand = m.idcommand
                WHERE m.lastname = 'Телина' AND m.firstname = 'Ирина Сергеевна';

        -- 4.2. Агрегатные функции в многотабличных запросах
            -- 4.2.1. Подсчитайте среднюю стоимость и количество выполняемых ей проектов каждой команды.
                SELECT c.command, COUNT(p.id) AS number_of_projects, AVG(p.price) AS average_price
                FROM command c
                JOIN project p ON c.id = p.idcommand
                GROUP BY c.command;
            -- 4.2.2. * (having) Найдите количество работ над проектами, у которых название команды которых начинается на «Р»
                SELECT c.command, COUNT(p.id) AS project_count
                FROM command c
                JOIN project p ON c.id = p.idcommand
                GROUP BY c.command      
                HAVING c.command LIKE 'Р%';
            -- 4.2.3. Решите задачу с применением filter
                SELECT c.command, COUNT(p.id) FILTER (WHERE p.project_type = 'коммерческий') AS commercial_project_count
                FROM command c
                LEFT JOIN project p ON c.id = p.idcommand
                GROUP BY c.command;
        -- 4.3. Внешние соединения 
            -- 4.3.1. Выполните операцию внешнего соединения таблиц Руководитель и Команда, для получения списка руководителей и название команд.
                SELECT m.lastname, m.firstname, c.command
                FROM mentor m
                LEFT JOIN command c ON m.idcommand = c.id;
            -- 4.3.2. Получите команды, которые не взяли ни одного проекта.
                SELECT g.groupname
                FROM grouplist g
                LEFT JOIN student s ON g.groupname = s.groupname
                WHERE s.id IS NULL;
            -- 4.3.3. Получите список групп, в которых нет ни одного студента.

        -- 4.4. Множественные операции 
            -- 4.4.1. Выведите название команд, которые выполняют проекты, стоимость которых >10000 и <20000 (оператор UNION ALL и UNION). Результаты сравните.
                SELECT c.command FROM command c JOIN project p ON c.id = p.idcommand WHERE p.price > 10000
                UNION
                SELECT c.command FROM command c JOIN project p ON c.id = p.idcommand WHERE p.price < 20000;

                SELECT c.command FROM command c JOIN project p ON c.id = p.idcommand WHERE p.price > 10000
                UNION ALL
                SELECT c.command FROM command c JOIN project p ON c.id = p.idcommand WHERE p.price < 20000;
            -- 4.4.2. Выбрать все записи о проектах, стоимость которых больше 1000р. и руководитель Цымбалюк Л.Н. (оператор пересечения).
                SELECT id, projectname, about, startdate, enddate, status, price, idcommand, project_type
                FROM project
                WHERE price > 1000
                INTERSECT
                SELECT p.id, p.projectname, p.about, p.startdate, p.enddate, p.status, p.price, p.idcommand, p.project_type
                FROM project p
                JOIN mentor m ON p.idcommand = m.idcommand
                WHERE m.lastname = 'Цымбалюк' AND m.firstname = 'Л.Н.';
            -- 4.4.3. Придумайте и реализуйте пример разности.
                -- Команды, у которых есть хоть какой-то проект
                SELECT c.command FROM command c JOIN project p ON c.id = p.idcommand
                EXCEPT
                -- Команды, у которых есть проект типа 'внутренний'
                SELECT c.command FROM command c JOIN project p ON c.id = p.idcommand WHERE p.project_type = 'внутренний';

        -- 4.5. Использование подзапросов
            -- 4.5.1. Агрегатные функции в подзапросах: Выведите на экран все проекты, которые имеют стоимость, большую средней стоимости проектов.
                SELECT projectname, price
                FROM project
                WHERE price > (SELECT AVG(price) FROM project);
            -- 4.5.2. Найдите фамилии и имена тех студентов, которые работают в команде A&B.
                SELECT lastname, firstname
                FROM student
                WHERE idcommand = (SELECT id FROM command WHERE command = 'A&B');
            -- 4.5.3. Найдите все проекты, которые имеет стоимость такую же, как стоимость указанного проекта.
                SELECT projectname, price
                FROM project
                WHERE price = (SELECT price FROM project WHERE projectname = 'Название конкретного проекта');
            -- 4.5.4. (HAVING): Выведите количество проектов каждой команды, у которых фамилия руководителя содержит букву а.
                SELECT c.command, COUNT(p.id) AS project_count
                FROM command c
                JOIN project p ON c.id = p.idcommand
                WHERE c.id IN (SELECT idcommand FROM mentor WHERE lastname LIKE '%а%')
                GROUP BY c.command;
            -- 4.5.5. (Запрос с подзапросом после Select) – найдите название проектов и разницу с стоимости проекта и средней стоимостью всех проектов
                SELECT projectname, price, price - (SELECT AVG(price) FROM project) AS price_difference
                FROM project;
            -- 4.5.6. Перечислите команды, которые не работали ни с одним проектом типа ‘исследовательский;
                SELECT command
                FROM command
                WHERE id NOT IN (SELECT idcommand FROM project WHERE project_type = 'исследовательский');

        -- 4.6. Подзапросы с ANY, SOME, ALL
            -- 4.6.1. ANY: Найдите команды, которые реализуют хотя бы один проект.
                SELECT command
                FROM command
                WHERE id = ANY (SELECT idcommand FROM project);
            -- 4.6.2. *SOME: Напишите запрос для вывода списка студентов, год рождения которых больше года рождения студентов из команды A&B
                SELECT lastname, firstname, yearb
                FROM student
                WHERE yearb > SOME (SELECT yearb FROM student WHERE idcommand = (SELECT id FROM command WHERE command = 'A&B'));
            -- 4.6.3. ALL. Найти проекты, стоимость которых больше, чем самый дорогой проект указанного типа.
                SELECT projectname, price 
                FROM project
                WHERE price > ALL (SELECT price FROM project WHERE project_type = 'коммерческий');

        -- 4.7. Подзапросы с EXISTS, NOT EXISTS
            -- 4.7.1. Напишите подзапрос для вывода фамилий студентов из команд, которые реализуют проекты более одного типа.
                SELECT s.lastname, s.firstname
                FROM student s
                WHERE EXISTS (
                    SELECT 1
                    FROM project p
                    WHERE s.idcommand = p.idcommand
                    GROUP BY p.idcommand
                    HAVING COUNT(DISTINCT p.project_type) > 1
                );
            -- 4.7.2. * Напишите запрос для вывода название команд, которые реализуют проекты каждого типа.
                SELECT c.command
                FROM command c
                WHERE NOT EXISTS (
                    SELECT DISTINCT p_types.project_type
                    FROM project p_types
                    EXCEPT
                    SELECT p.project_type
                    FROM project p
                    WHERE p.idcommand = c.id
                );
            -- 4.7.3. Перечислите команды, которые не имеют ни одного проекта с указанным статусом.
                SELECT c.command
                FROM command c
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM project p
                    WHERE p.idcommand = c.id AND p.status = 'завершен'
                );

        -- 4.8. Написание рекурсивных запросов
            -- 4.8.1. Почитайте про функцию generate_series(start, stop)
-- https://postgrespro.ru/docs/postgresql/9.5/functions-srf
            -- 4.8.2. Напишите запрос, который получит набор чисел от 1 до 10 с шагом 0,5
                SELECT generate_series(1, 10, 0.5);
            -- 4.8.3. Напишите рекурсивный запрос для получения суммы 10 чисел
            WITH RECURSIVE sum_recursive(n, total) AS (
                SELECT 1, 1
                UNION ALL
                SELECT n + 1, total + n + 1
                FROM sum_recursive
                WHERE n < 10
            )
            SELECT total FROM sum_recursive WHERE n=10;
            -- 4.8.4. Напишите запрос, который сгенерирует даты в диапазоне от сегодняшнего числа + 30 дней.
                SELECT generate_series(CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days', '1 day')::date;
            -- 4.8.5. Построение рекурсивного запроса к набору данных
                -- • Создайте таблицу events, содержащую поля id, predid, postid, descr.
                    CREATE TABLE events (
                        id SERIAL PRIMARY KEY,
                        predid INT,
                        postid INT,
                        descr TEXT
                    );
                -- • Напишите запрос на выборку к generate_series(1,10) AS id с полями id*10, (id-1)*10, (id+1)*10, 'Event ' || id*10
                -- • Напишите запрос на вставку 10 записей в таблицу events, как результат предыдущего запроса
                    INSERT INTO events (id, predid, postid, descr)
                    SELECT
                        id,
                        (id-1)*10,
                        (id+1)*10,
                        'Event ' || id*10
                    FROM generate_series(1,10) AS id;
                -- • В результате вы должны получить 
                -- • Напишите рекурсивный запрос, который найдёт id события от события с id=10
                    WITH RECURSIVE event_chain AS (
                        SELECT id, predid, descr
                        FROM events
                        WHERE id = 10

                        UNION ALL

                        SELECT e.id, e.predid, e.descr
                        FROM events e
                        JOIN event_chain ec ON e.id = ec.predid / 10
                    )
                    SELECT id, descr FROM event_chain;
            -- 4.8.6. *В таблицу student добавьте поле уровень, заполните его значениями (так 0 до 2), найдите список по подчинённым указанного пользователя.
                ALTER TABLE student ADD COLUMN level INT;
                -- Примерное заполнение
                UPDATE student SET level = (id % 3);


                WITH RECURSIVE subordinates AS (
                    SELECT id, lastname, firstname, idcommand, level
                    FROM student
                    WHERE lastname = 'фамилия_руководителя' -- Задаем начального пользователя

                    UNION ALL

                    SELECT s.id, s.lastname, s.firstname, s.idcommand, s.level
                    FROM student s
                    INNER JOIN subordinates sub ON s.idcommand = sub.id
                )
                SELECT * FROM subordinates;

        -- 4.9. Сводные таблицы
            -- 4.9.1. По каждой группе найдите количество проектов, подвести итоги
                SELECT s.groupname, COUNT(DISTINCT p.id) AS project_count
                FROM student s
                JOIN project p ON s.idcommand = p.idcommand
                GROUP BY ROLLUP(s.groupname)
                ORDER BY s.groupname;
            -- 4.9.2. Распределите всех студентов по группам в зависимости от возраста
                -- 4.9.2.1. От 7 до 17 – начинающий
                -- 4.9.2.2. От 18 до 24 – продвинутый
                -- 4.9.2.3. От 25 до 35 – профессионал
                -- 4.9.2.4. От 36 – эксперт
                    SELECT lastname, firstname,
                        CASE
                            WHEN (2024 - yearb) BETWEEN 7 AND 17 THEN 'начинающий'
                            WHEN (2024 - yearb) BETWEEN 18 AND 24 THEN 'продвинутый'
                            WHEN (2024 - yearb) BETWEEN 25 AND 35 THEN 'профессионал'
                            WHEN (2024 - yearb) >= 36 THEN 'эксперт'
                            ELSE 'не определено'
                        END AS age_group
                    FROM student;

                    CREATE TABLE student_task (
                        id SERIAL PRIMARY KEY,
                        idstudent INT REFERENCES student(id),
                        idtask INT REFERENCES task(id),
                        completed BOOLEAN DEFAULT FALSE
                    );
-- По каждой группе найдите количество выполненных задач (соответственно, предусмотрите, дополнение в базе данных – закрепление задачи на студентом)
    WITH student_age_groups AS (
    SELECT
        id,
        CASE
            WHEN (2024 - yearb) BETWEEN 7 AND 17 THEN 'начинающий'
            WHEN (2024 - yearb) BETWEEN 18 AND 24 THEN 'продвинутый'
            WHEN (2024 - yearb) BETWEEN 25 AND 35 THEN 'профессионал'
            WHEN (2024 - yearb) >= 36 THEN 'эксперт'
            ELSE 'не определено'
        END AS age_group
    FROM
        student
)
SELECT sag.age_group, COUNT(st.id) AS completed_tasks_count
FROM student_age_groups sag
JOIN student_task st ON sag.id = st.idstudent
WHERE st.completed = TRUE
GROUP BY sag.age_group
ORDER BY sag.age_group;