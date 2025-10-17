--     3. Практические указания:

--         3.1. Внесение изменений
--             3.1.1. Перед выполнением заданий убедитесь, что структура таблиц вашей базы данных соответствует структуре ниже
-- project (id, projectname, about, startDate, enddate, status, price, idcommand)
-- student (id, lastname, firstname, role, email, yearb, groupname, idcommand)
-- command (id, command)
-- task (id, task, idproject)
-- resource (id, resource, idproject)
-- grouplist (groupname, sp)
-- mentor (id, lastname, firstname, email, idcommand)
        -- Создание таблицы 'command'
        CREATE TABLE IF NOT EXISTS command (
            id INT PRIMARY KEY,
            command VARCHAR(255) NOT NULL
        );

        -- Создание таблицы 'project'
        CREATE TABLE IF NOT EXISTS project (
            id INT PRIMARY KEY,
            projectname VARCHAR(255) NOT NULL,
            about TEXT,
            startDate DATE,
            endDate DATE,
            status VARCHAR(50),
            price DECIMAL(10, 2),
            idcommand INT,
            FOREIGN KEY (idcommand) REFERENCES command(id)
        );

        -- Создание таблицы 'student'
        CREATE TABLE IF NOT EXISTS student (
            id INT PRIMARY KEY,
            lastname VARCHAR(255) NOT NULL,
            firstname VARCHAR(255) NOT NULL,
            role VARCHAR(100),
            email VARCHAR(255) UNIQUE,
            yearb INT,
            groupname VARCHAR(50),
            idcommand INT,
            FOREIGN KEY (idcommand) REFERENCES command(id)
        );

        -- Создание таблицы 'task'
        CREATE TABLE IF NOT EXISTS task (
            id INT PRIMARY KEY,
            task TEXT,
            idproject INT,
            FOREIGN KEY (idproject) REFERENCES project(id)
        );

        -- Создание таблицы 'resource'
        CREATE TABLE IF NOT EXISTS resource (
            id INT PRIMARY KEY,
            resource TEXT,
            idproject INT,
            FOREIGN KEY (idproject) REFERENCES project(id)
        );

        -- Создание таблицы 'grouplist'
        CREATE TABLE IF NOT EXISTS grouplist (
            groupname VARCHAR(50) PRIMARY KEY,
            sp VARCHAR(255)
        );

        -- Создание таблицы 'mentor'
        CREATE TABLE IF NOT EXISTS mentor (
            id INT PRIMARY KEY,
            lastname VARCHAR(255) NOT NULL,
            firstname VARCHAR(255) NOT NULL,
            email VARCHAR(255) UNIQUE,
            idcommand INT,
            FOREIGN KEY (idcommand) REFERENCES command(id)
        );  
-- 3.1.2. В таблицу student добавьте поле yearb
        ALTER TABLE student ADD COLUMN yearb DATE;
-- 3.1.3. Заполните записями, для этого примените команду Update Таблица set поле=значение where id=Номер
        INSERT INTO command (id, command) VALUES
        (1, 'Команда Альфа'),
        (2, 'Команда Бета'),
        (3, 'Команда Гамма');
        INSERT INTO mentor (id, lastname, firstname, email, idcommand) VALUES
        (201, 'Смирнов', 'Алексей', 'smirnov_a@mentor.com', 1),
        (202, 'Кузнецова', 'Ольга', 'kuznetsova_o@mentor.com', 2),
        (203, 'Васильев', 'Дмитрий', 'vasilyev_d@mentor.com', 3);

        INSERT INTO project (id, projectname, about, startDate, endDate, status, price, idcommand, project_type)
        VALUES (104, 'Аналитическая платформа для маркетинга', 'Разработка платформы для сбора и анализа маркетинговых данных', '2026-01-10', '2026-07-10', 'Планируется', 250000.00, 3, 'информационный');
        UPDATE mentor SET email = 'dmitriy_vas@mentor.com' WHERE firstname = 'Дмитрий' AND lastname = 'Васильев';     
-- 3.1.4. В таблицу project добавьте поле Тип проекта project_type
        ALTER TABLE project ADD COLUMN project_type VARCHAR(50);
-- 3.1.5. Заполните записями данное поле значениями социальный, информационный, исследовательский, применяя конструкцию:
-- update Таблица
-- set поле=case
-- when целое число от случайного * 3 = 0 then 'социальный' 
-- …
-- end;
        UPDATE project
            SET project_type = CASE FLOOR(RANDOM() * 3)::int
                WHEN 0 THEN 'социальный'
                WHEN 1 THEN 'информационный'
                WHEN 2 THEN 'исследовательский'
            END;





-- 3.2. Создание простых запросов на языке SQL.
-- 3.2.1. Выберите все типы проектов из таблицы project без повторений;
        SELECT DISTINCT project_type FROM project;
-- 3.2.2. Выбор из таблицы project записей, название которых начинается или заканчиваются на А;
        SELECT *
        FROM project
        WHERE
            LOWER(projectname) LIKE 'а%'
            OR LOWER(projectname) LIKE '%а';
-- 3.2.3. Выбор из списка значений – выбор проектов, типы которых 'исследовательский' или 'информационный';
        SELECT *
        FROM project
        WHERE project_type IN ('исследовательский', 'информационный');
-- 3.2.4. Найдите все проекты, которые были начаты между 2022 и 2024 годами;
        SELECT *
        FROM project
        WHERE EXTRACT(YEAR FROM startdate) BETWEEN 2021 AND 2024; 
-- 3.2.5. Найдите проекты, в описании которых присутствует буквосочетание ‘об’.
        SELECT *
        FROM project
        WHERE LOWER(about) LIKE '%об%';
-- 3.2.6. Найдите все задачи проектов, id которых содержит цифру 2 в повторении минимум 2 раза или содержит цифру 3 (используйте поиск по регулярному выражению).
        SELECT *
        FROM project
        WHERE id::text ~ '2.*2|3';





-- 3.3. Сортировка результатов запроса.
-- 3.3.1. Выводите проекты, отсортированных по дате старта проекта;
        SELECT *
        FROM project
        ORDER BY startdate ASC;
-- 3.3.2. Произведите сортировку записей таблицы Наставник по убыванию фамилий.
        SELECT *
        FROM mentor
        ORDER BY lastname DESC;
-- 3.3.3. Произведите сортировку записей любого запроса из предыдущего задания (3.2) по возрастанию (по убыванию) с ограничением на количество записей (limit) – пропуская первые 2 значения вывести 3 значения.
        SELECT *
        FROM project
        WHERE project_type IN ('исследовательский', 'информационный')
        ORDER BY projectname ASC
        LIMIT 3 OFFSET 2;





-- 3.4. Работа с функциями, при необходимости используем псевдонимы полей.
-- 3.4.1. Напишите запросы с применением строковых функций (SUBSTRING, INITCAP, REPLACE).
        SELECT lastname, firstname, email,
        REPLACE(email, '@mentor.com', '@corp.pro') AS new_email
        FROM mentor;
-- 3.4.2. Придумайте и продемонстрируйте применение всех типов округления.
        SELECT projectname, price / 12.7 AS "Исходное значение",
        ROUND(price / 12.7) AS "ROUND (до ближайшего)",
        CEILING(price / 12.7) AS "CEILING (вверх)",
        FLOOR(price / 12.7) AS "FLOOR (вниз)"
        FROM project;
-- 3.4.3. Выведите на экран значение полей: Фамилия + Имя студента (с помощью функции CONCAT).
        SELECT CONCAT(lastname, ' ', firstname) AS full_name
        FROM student;
-- 3.4.4. Выведите текущую дату (с подписями день, месяц, год) с применением функций LPAD, RPAD.
        SELECT
        RPAD(CONCAT('День: ', EXTRACT(DAY FROM CURRENT_DATE)), 20, '.') AS "День (форматирование справа)",

        LPAD(CONCAT('Месяц: ', EXTRACT(MONTH FROM CURRENT_DATE)), 20, '-') AS "Месяц (форматирование слева)",

        CONCAT('День (с ведущим нулем): ', LPAD(CAST(EXTRACT(DAY FROM CURRENT_DATE) AS CHAR(2)), 2, '0')) AS "Пример с нулем",

        RPAD(CONCAT(EXTRACT(YEAR FROM CURRENT_DATE), ' :Год'), 20, '=') AS "Год (форматирование справа)";
-- 3.4.5. Преобразуйте строку в число, строку в дату (по своему усмотрению).
        SELECT '12345.67' AS original_string,
        CAST('12345.67' AS DECIMAL(10, 2)) AS converted_number;

        SELECT '25/12/2025' AS original_string,
        TO_DATE('25/12/2025', 'DD/MM/YYYY') AS converted_date;
-- 3.4.6. Преобразуйте число, дату в строку 1в строку в определённому формате (по своему усмотрению).
        SELECT projectname, price,
        TO_CHAR(price, '9999G999D99 L') AS formatted_price
        FROM project
        WHERE id = 101;

        SELECT projectname, startDate,
        TO_CHAR(startDate, 'Day, DD TMMonth YYYY') AS formatted_date
        FROM project
        WHERE id = 101;
-- 3.4.7. Выведите названия проектов, которые состоят из более, чем одно слово.
        SELECT projectname
        FROM project
        WHERE projectname LIKE '% %';
-- 3.4.8. Найдите количество месяцев между текущей датой и январём 2025 года.
        SELECT (EXTRACT(MONTH FROM CURRENT_DATE) - EXTRACT(MONTH FROM DATE '2025-01-01')) AS months_difference;
-- 3.4.9. Найдите количество дней, прошедших от начала года до текущей даты.
        SELECT EXTRACT(DOY FROM CURRENT_DATE) AS days_defference;
-- 3.4.10. Вывод списка студентов, возраст которых между 20 и 22.
        SELECT lastname, firstname, yearb,
        (EXTRACT(YEAR FROM CURRENT_DATE) - yearb) AS age
        FROM student
        WHERE (EXTRACT(YEAR FROM CURRENT_DATE) - yearb) BETWEEN 20 AND 22;
-- 3.4.11. Найдите количество дней между датой начала работы над проектом и датой окончания работы над проектом.
        SELECT projectname, startDate, endDate,
        (endDate - startDate) AS duration_in_days
        FROM project;
-- 3.4.12. Вычислите возраст (в днях) каждого проекта.
        SELECT projectname, startDate,
        (CURRENT_DATE - startDate) AS project_age_in_days
        FROM project;
-- 3.4.13. Найдите по каждой команде количество выполненных работ в период от начала года до текущей даты
        SELECT c.command AS command_name,
        COUNT(p.id) AS completed_projects_this_year
        FROM command c
        JOIN project p ON c.id = p.idcommand
        WHERE p.status = 'Завершен' AND p.endDate BETWEEN DATE_TRUNC('year', CURRENT_DATE) AND CURRENT_DATE
        GROUP BY c.id, c.command;


-- 3.5. Использование агрегатных функций
-- 3.5.1. Найти средний год рождения всех студентов; 
        SELECT AVG(yearb) AS average_birth_year
        FROM student;
-- 3.5.2. Найдите минимальную стоимость проектов каждого типа.
        SELECT project_type, MIN(price) AS min_price
        FROM project
        GROUP BY project_type;
-- 3.5.3. Напишите запрос, который по каждому проекту находит выполненных задач, если данное количество будет от 3 до 5;
        SELECT p.projectname, COUNT(t.id) AS task_count
        FROM project p
        JOIN task t ON p.id = t.idproject
        GROUP BY p.id, p.projectname
        HAVING COUNT(t.id) BETWEEN 3 AND 5;
-- 3.5.4. Найдите среднюю цену тех проектов, месяц начала работы над которыми март, и год текущий.
        SELECT AVG(price) AS average_price_for_march_projects
        FROM project
        WHERE EXTRACT(MONTH FROM startDate) = 3 AND EXTRACT(YEAR FROM startDate) = EXTRACT(YEAR FROM CURRENT_DATE);
-- 3.5.5. (case) Найдём количество проектов, которые по цене в диапазонах от 100 до 500, от 500 до1000, от 1000 до 10000.
        SELECT
            CASE
                WHEN price >= 100000 AND price <= 400000 THEN 'от 100,000 до 400,000'
                WHEN price > 400000 AND price <= 1000000 THEN 'от 400,000 до 1,000,000'
                ELSE 'Другой диапазон (менее 100,000)'
            END AS price_range,
            COUNT(id) AS project_count
        FROM project
        GROUP BY price_range
        ORDER BY price_range;





-- 3.6. Работа с дополнительными функциями по группировке.
-- 3.6.1. (coalesce) Вывести количество проектов у каждой команды и итоговую стоимость всех проектов. Если у проекта нет цены, мы заменим ее на 'бесплатно' с помощью COALESCE.
        SELECT c.command AS command_name,
            COUNT(p.id) AS project_count,
            SUM(COALESCE(p.price, 0)) AS total_cost
        FROM command c
        LEFT JOIN project p ON c.id = p.idcommand
        GROUP BY c.id, c.command
        ORDER BY command_name;
-- 3.6.2. (grouping) Найти сколько проектов по типу проекта по каждой команде.
        SELECT c.command AS team_name,
            COALESCE(p.project_type, 'Тип не указан') AS project_type,
            COUNT(p.id) AS project_count
        FROM command c
        LEFT JOIN project p ON c.id = p.idcommand
        GROUP BY c.command, p.project_type
        ORDER BY team_name, project_type;
-- Группируем по команде и по типу проекта
-- 3.6.3. (group by cube) Найти сколько проектов в каждом статусе по каждой команд. Группируем по команде и по статусу
        SELECT COALESCE(c.command, 'Все команды (итог)') AS team_name, 
            COALESCE(p.status, 'Все статусы (итог)') AS project_status,
            COUNT(p.id) AS project_count
        FROM command c
        LEFT JOIN project p ON c.id = p.idcommand
        GROUP BY CUBE(c.command, p.status)
        ORDER BY team_name, project_status;
-- 3.6.4. (group by grouping sets) Найти агрегации как по команде и по типу проекта, только команда, только тип проекта и общее количество. Группируем по команде и по типу проекта, по команде, по типу проекта, () – общее значение
        SELECT COALESCE(c.command, 'Всего по командам') AS team_name,
            COALESCE(p.project_type, 'Всего по типам проектов') AS project_type,
            COUNT(p.id) AS project_count
        FROM command c
        LEFT JOIN project p ON c.id = p.idcommand
        GROUP BY GROUPING SETS (
            (c.command, p.project_type), 
            (p.project_type),            
            (c.command),                 
            ()                          
        )
        ORDER BY team_name, project_type;
-- 3.6.5. Найти сколько проектов выполняет каждая команда и сколько студентов задействовано в проектах.
        WITH project_counts AS (
            SELECT idcommand, COUNT(id) AS num_projects
            FROM project
            GROUP BY idcommand
        ),
        student_counts AS (
            SELECT idcommand, COUNT(id) AS num_students
            FROM student
            GROUP BY idcommand
        )

        SELECT c.command AS team_name,
            COALESCE(pc.num_projects, 0) AS project_count,
            COALESCE(sc.num_students, 0) AS student_count
        FROM command c
        LEFT JOIN project_counts pc ON c.id = pc.idcommand
        LEFT JOIN student_counts sc ON c.id = sc.idcommand
        ORDER BY team_name;