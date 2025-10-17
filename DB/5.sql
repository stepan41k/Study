-- Перед выполнением заданий убедитесь, что структура таблиц вашей базы данных соответствует структуре ниже
-- project (id, projectname, about, startdate, enddate, status, price, idcommand, project_type)
-- student (id, lastname, firstname, role, email, yearb, groupname, idcommand)
-- command (id, command)
-- task (id,task, idproject)
-- resource (id, resource, idproject)
-- grouplist (groupname, sp)
-- mentor (id, lastname, firstname, email, idcommand)
-- Добавим в таблицу Задача поле score (оценка). Заполним записями.
ALTER TABLE task ADD COLUMN score INTEGER;
UPDATE task SET score = floor(random() * 5 + 1)::int;
--         3.1. Работа с агрегатными функциями
--             3.1.1. Для каждого месяца 2024 года выведите количество проектов
--                 • Получим список месяцев
--                 • Добавим в sql-запрос выборку полей month_nm и количества выдач книг, соединим данные из построенной таблицы months с данными таблицы project по                    номеру месяца (из таблицы месяцев это поле month_nus), а для получения значения номера месяца из таблицы project – воспользуйтесь функцией extract.
--                 • Добавьте фильтр к агрегатной функции с условием выборки – дата 2024 (тоже функция extract для получения года из даты).
--                 • Добавьте группировку по полю месяц и номер месяца.
--                 • Добавьте сортировку по полю номер месяца.
                    WITH months AS (
                      SELECT generate_series(1, 12) AS month_num,
                             to_char(to_date(generate_series(1, 12)::text, 'MM'), 'Month') AS month_nm
                    )
                    SELECT m.month_nm, COUNT(p.id) AS project_count
                    FROM months m
                    LEFT JOIN z5_project p ON m.month_num = EXTRACT(MONTH FROM p.startdate)
                        AND EXTRACT(YEAR FROM p.startdate) = 2024
                    GROUP BY m.month_nm, m.month_num
                    ORDER BY m.month_num;
--         3.2. Задания для выполнения
--             3.2.1. Расставьте порядковый номер проекта для каждого дня
--                 • Воспользуйтесь функцией row_number() с окном по месяцу проекта с сортировкой по дню 
                    SELECT projectname, startdate,
                        ROW_NUMBER() OVER(PARTITION BY EXTRACT(MONTH FROM startdate) ORDER BY startdate) AS project_num_in_month
                    FROM z5_project
                    ORDER BY startdate;
--             3.2.2. Измените данный запрос с применением функций RANK() и DENSE_RANK(), NTILE(). Ответьте, в чём разница между применениями этих функций
                    SELECT projectname AS "Название проекта", startdate AS "Дата старта",
                        ROW_NUMBER() OVER(PARTITION BY EXTRACT(MONTH FROM startdate) ORDER BY startdate) as "ROW_NUMBER",
                        RANK() OVER(PARTITION BY EXTRACT(MONTH FROM startdate) ORDER BY startdate) as "RANK",
                        DENSE_RANK() OVER(PARTITION BY EXTRACT(MONTH FROM startdate) ORDER BY startdate) as "DENSE_RANK",
                        NTILE(4) OVER(PARTITION BY EXTRACT(MONTH FROM startdate) ORDER BY startdate) as "NTILE(4)"
                    FROM z5_project
                    ORDER BY startdate DESC;
--             3.2.3. Напишите аналогичный запросу из п.3.1 с применением оконной функции
                    WITH months AS (
                      SELECT generate_series(1, 12) AS month_num,
                             to_char(to_date(generate_series(1, 12)::text, 'MM'), 'Month') AS month_nm
                    )
                    SELECT month_nm, COUNT(id) AS "Количество проектов"
                    FROM months m
                    LEFT JOIN z5_project p ON m.month_num = EXTRACT(MONTH FROM p.startdate)
                        AND EXTRACT(YEAR FROM p.startdate) = 2024
                    GROUP BY m.month_nm, m.month_num
                    ORDER BY m.month_num;

                     WITH months AS (
                      SELECT generate_series(1, 12) AS month_num,
                             to_char(to_date(generate_series(1, 12)::text, 'MM'), 'Month') AS month_nm
                    )
                    SELECT DISTINCT month_nm, COUNT(id) OVER(PARTITION BY DATE_TRUNC('month', p.startdate) ORDER BY EXTRACT(MONTH FROM p.startdate)) AS "Количество проектов"
                    FROM months m
                    LEFT JOIN z5_project p ON m.month_num = EXTRACT(MONTH FROM p.startdate)
                        AND EXTRACT(YEAR FROM p.startdate) = 2024;

                    WITH months AS (
                      SELECT generate_series(1, 12) AS month_num,
                             to_char(to_date(generate_series(1, 12)::text, 'MM'), 'Month') AS month_nm
                    )
                    SELECT DISTINCT m.month_num, month_nm, COUNT(id) OVER(PARTITION BY DATE_TRUNC('month', p.startdate)) AS "Количество проектов"
                    FROM months m
                    LEFT JOIN z5_project p ON m.month_num = EXTRACT(MONTH FROM p.startdate)
                        AND EXTRACT(YEAR FROM p.startdate) = 2024
                    ORDER BY m.month_num;

--             3.2.4. Напишите оконную функцию для присвоения номера каждому пользователю студенту в группе (с сортировкой по фамилии и имени).
                    SELECT groupname AS "Группа", lastname AS "Фамилия", firstname AS "Имя",
                        ROW_NUMBER() OVER(PARTITION BY groupname ORDER BY lastname, firstname) as "Номер в группе"
                    FROM z5_student
                    ORDER BY groupname, lastname, firstname;
--             3.2.5. Найдем в каждом месяце начало работы над проектами указанной команды.
                    WITH RankedProjects AS (
                        SELECT projectname, startdate, idcommand,
                            ROW_NUMBER() OVER(PARTITION BY DATE_TRUNC('month', startdate) ORDER BY startdate ASC) as rank_in_month
                        FROM z5_project
                        WHERE idcommand = 1
                    )
                    SELECT to_char(startdate, 'FMMonth') AS "Месяц начала", startdate AS "Дата старта первого проекта"
                    FROM RankedProjects
                    WHERE rank_in_month = 1
                    ORDER BY startdate;
--             3.2.6. Найдем разницу между стоимостью проекта и средней стоимостью всех проектов.
                    SELECT projectname AS "Название проекта", price AS "Стоимость",
                        ROUND(price - AVG(price) OVER(), 2) as "Отклонение от средней стоимости"
                    FROM z5_project;
--             3.2.7. Упорядочьте записи о проектах в порядке убывания/возрастания их стоимости (с применением функций ранжирования и предложения window).
                    SELECT projectname AS "Название проекта", price AS "Стоимость",
                        RANK() OVER w_price_desc AS "Ранг по убыванию стоимости",
                        RANK() OVER w_price_asc  AS "Ранг по возрастанию стоимости"
                    FROM z5_project
                    WINDOW
                        w_price_desc AS (ORDER BY price DESC),
                        w_price_asc  AS (ORDER BY price ASC);
--             3.2.8. Найдём накопительную сумму стоимости для каждого статуса проектов.
                    SELECT projectname AS "Название проекта", status AS "Статус", startdate AS "Дата старта", price AS "Стоимость",
                        SUM(price) OVER(PARTITION BY status ORDER BY startdate, id) as "Накопительная сумма по статусу"
                    FROM z5_project
                    ORDER BY status, startdate;
--             3.2.9. *Найдём количество проектов, над которыми работает наставник с применением функций накопления.
                    SELECT m.lastname || ' ' || m.firstname AS "Наставник", p.projectname AS "Проект", p.startdate AS "Дата старта",
                        ROW_NUMBER() OVER(PARTITION BY m.id ORDER BY p.startdate) as "Накопительное кол-во проектов"
                    FROM z5_mentor m
                    JOIN z5_project p ON m.idcommand = p.idcommand
                    ORDER BY m.id, p.startdate;
--             3.2.10. *Посчитаем количество ресурсов для каждого проекта за последние 6 месяцев.
                    SELECT p.id, p.projectname, p.startdate, COUNT(r.id) as resource_count
                    FROM z5_project p
                    LEFT JOIN z5_resource r ON p.id = r.idproject
                    WHERE p.startdate >= (NOW() - INTERVAL '6 months')
                    GROUP BY p.id, p.projectname, p.startdate
                    ORDER BY p.startdate DESC;
--             3.2.11. * Произведите ранжирование по средней	 оценке студента за последние 3 задачи.
                    WITH RankedTasks AS (
                        SELECT s.id AS student_id, s.lastname, s.firstname, t.score,
                            ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY t.id DESC) AS task_num
                        FROM z5_student s
                        JOIN z5_command cmd ON s.idcommand = cmd.id
                        JOIN z5_project p ON cmd.id = p.idcommand
                        JOIN z5_task t ON p.id = t.idproject
                        WHERE t.score IS NOT NULL
                    )  
                    SELECT lastname, firstname, AVG(score) AS average_score,
                        DENSE_RANK() OVER (ORDER BY AVG(score) DESC) AS student_rank
                    FROM RankedTasks
                    WHERE task_num <= 3
                    GROUP BY student_id, lastname, firstname
                    ORDER BY student_rank;
                    
--             3.2.12. *Найти накопительную сумму цен проектов за последние 3 месяца.
                    SELECT projectname, startdate, price,
                        SUM(price) OVER (ORDER BY startdate, id RANGE BETWEEN INTERVAL '3 months' PRECEDING AND CURRENT ROW) AS "Сумма за 3 мес."
                    FROM z5_project
                    ORDER BY startdate, id;