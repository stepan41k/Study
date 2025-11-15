--     1. Привилегии доступа к данным
--         1.1. Проверьте роли пользователям stud1 07&3886V&g, stud2 07&3886V&f
                SELECT rolname FROM pg_roles WHERE rolname IN ('stud1', 'stud2');
--         1.2. Задайте привилегии доступа
--             1.2.1. Задайте привилегии доступа (учтите, что разрешение доступа к схеме должно быть дано пользователю, также учтите необходимость выдачу разрешений на необходимые сопутствующие объекты)
-- Пользователю stud1 дайте разрешение: 
                -- GRANT USAGE ON SCHEMA public TO stud1;
                -- REVOKE USAGE ON SCHEMA public FROM stud1;
--             ▪ на чтение представления project_student, добавление и удаление данных в представлении project_student;
                GRANT SELECT, INSERT, DELETE ON TABLE project_student TO stud1;
--             ▪ изменение данных в таблице student;
                -- GRANT UPDATE ON TABLE z5_student TO stud1;

                GRANT INSERT, UPDATE ON TABLE z5_student TO stud1;

                GRANT USAGE, UPDATE ON SEQUENCE student_id_seq TO stud1;
--             ▪ чтение данных представления tek_project с возможностью передачи привилегии;
                GRANT SELECT ON TABLE tek_project TO stud1 WITH GRANT OPTION;
--             ▪ запрет на просмотр данных в столбцах result, project_deadline таблицы project, разрешение на просмотр данных остальных столбцов таблицы project.
                GRANT SELECT (id, projectname, about, startdate, enddate, status, price, idcommand, project_type, shifr, category)
                ON TABLE z5_project TO stud1;
                REVOKE SELECT (result, project_deadline) ON TABLE z5_project FROM stud1;
--         1.3. Проверка привилегий
--             1.3.1. Создайте новое подключение для пользователя stud1.
--                 • Проверьте привилегии данного пользователя.
                    SELECT has_schema_privilege('stud1', 'public', 'USAGE');
--                 • Вернитесь к своему пользователю.
--     • Проверьте привилегии пользователя к схеме с помощью команд: has_table_privilege([user, ] table, privilege), has_schema_privilege([user, ] schema, privilege), has_database_privilege([user, ] database, privilege)
-- SELECT has_schema_privilege('stud1', 'схема', 'USAGE');
--     • Выполните проверку привилегий к бд – параметры имя базы данных и привилегии connect и create с помощью функции has_database_privilege()
        SELECT has_database_privilege('stud1', 'dbstud', 'CONNECT, CREATE');
--     • Проверка привилегий на конкретную таблицу/представление (запросить привилегии для конкретного объекта (таблицы project, представления project_student). Напишите запрос к таблице information_schema.table_privileges. Добавьте условие выборки – нужная таблица или представление.
        SELECT grantee, table_schema, table_name, privilege_type
        FROM information_schema.table_privileges
        WHERE grantee = 'stud1' AND table_name IN ('z5_project', 'project_student');

        SELECT grantee, table_schema, table_name, column_name, privilege_type
        FROM information_schema.column_privileges
        WHERE grantee = 'stud1' AND table_name IN ('z5_project', 'project_student');
--     • Напишите запрос с применением функции STRING_AGG(поле, разделитель) для агрегации по полям пользователь имя таблицы с указанием привилегий.
        SELECT grantee, table_name, STRING_AGG(privilege_type, ', ') AS privileges
        FROM information_schema.table_privileges
        WHERE grantee = 'stud1'
        GROUP BY grantee, table_name;
--     2. Создание политик доступа
--         2.1. В таблице student выберите поле для идентификации пользователя (можно использовать поле lastname или name).
--         2.2. Обновите существующие записи, добавьте записи или обновите любую запись с изменением его значения на пользователей (stud1, stud2).
            UPDATE z5_student SET lastname = 'stud1' WHERE student_id = 1;
            UPDATE z5_student SET lastname = 'stud2' WHERE student_id = 2;
--         2.3. Включите защиту на уровне строк для таблицы student: 
            ALTER TABLE z5_student ENABLE ROW LEVEL SECURITY;
--         2.4. Создайте политику для отношения student, позволяющую только членам роли stud1 обращаться к строкам отношения и при этом только к своим (в таблице student должна быть запись о пользователе stud1).
            CREATE POLICY student_stud1_policy
            ON z5_student
            FOR ALL
            TO stud1
            USING (lastname = current_user);
--         2.5. Создайте политику, чтобы stud2 мог видеть и добавлять любые строки.
            CREATE POLICY student_stud2_policy
            ON z5_student
            FOR ALL
            TO stud2
            USING (true);
--         2.6. Напишите запрос на создание политики, которая позволит всем пользователям видеть все строки в таблице users, но менять только свою собственную.
            CREATE POLICY users_policy
            ON z5_users
            FOR ALL
            USING (true)
            WITH CHECK (username = current_user);
--         2.7. Проверьте созданные политики доступа (напишем запрос по примеру п.1.3 для агрегации политик по tablename с обращением к nаблице pg_policies).
            SELECT schemaname, tablename, policyname, permissive, cmd, qual, with_check
            FROM pg_policies
            WHERE tablename = 'z5_student';
--         2.8. Создайте политику менторы видят все проекты своей команды. Проверьте работу политики.
            CREATE POLICY mentor_team_projects_policy
            ON z5_project
            FOR SELECT
            USING (project_id IN (SELECT project_id FROM teams WHERE mentor_username = current_user));
--         2.9. Создайте политику для ограничения доступа к полю result в зависимости от категории – просматривать может пользователь stud2.
            CREATE POLICY result_access_policy
            ON z5_project
            FOR SELECT
            TO stud2
            USING (category = 'some_category');
--     3. Аудит доступа
--         3.1. Создайте таблицу аудита audit (id, username, action, table_name, timestamp)
            CREATE TABLE audit (
                id SERIAL PRIMARY KEY,
                username TEXT,
                action TEXT,
                table_name TEXT,
                timestamp TIMESTAMPTZ
            );
--         3.2. Напишите правило добавления записей в таблицу при выполнении операций
            CREATE OR REPLACE RULE audit_student_insert AS
            ON INSERT TO z5_student
            DO ALSO
            INSERT INTO audit (username, action, table_name, timestamp)
            VALUES (current_user, 'INSERT', 'student', now());
--         3.3. Проверьте работу правила.
            SELECT * FROM audit;
--     4. Работа с транзакциями
--         4.1. Базовые транзакции
--                 • Стартуйте транзакцию
--                 • Обновите статус проекта с номером N
--                 • Добавьте запись в таблицу Задачи
--                 • Проверьте изменения (выведите данные из таблиц)
--                 • Примените транзакцию
                    BEGIN;
                    UPDATE z5_project SET status = 'in_progress' WHERE project_id = 1;
                    INSERT INTO z5_task (project_id, task_name) VALUES (1, 'Новая задача');
                    SELECT * FROM z5_project WHERE project_id = 1;
                    SELECT * FROM z5_task WHERE project_id = 1;
                    COMMIT;
--         4.2. Уровни изоляций транзакций
--                 • Проверка работы уровня: создайте 2 подключения 
--                     ◦ В первом установите уровень изоляции READ COMMITTED и измените данные о студенте
--                     ◦ Во втором подключении аналогично установите указанный уровень изоляции и проверьте результат изменения.
--                 • Симуляция блокировки: создайте 2 подключения 
--                     ◦ В первом установите уровень изоляции READ COMMITTED и измените данные о студенте
--                     ◦ Во втором подключении сделайте аналогичный запрос на изменение
                    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
                    BEGIN;
                    UPDATE z5_student SET name = 'НовоеИмя' WHERE student_id = 1;

                                            
                    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
                    BEGIN;
                    SELECT name FROM z5_student WHERE student_id = 1;


                    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
                    BEGIN;
                    UPDATE z5_student SET name = 'ЕщеОдноИмя' WHERE student_id = 1;

                    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
                    BEGIN;
                    UPDATE z5_student SET name = 'ДругоеИмя' WHERE student_id = 1;
  
--         4.3. Откройте 4 подключения к базе данных, в каждом из подключений откройте по транзакции с уровнем изоляции read committed
--                 • В начальный момент времени всем транзакциям доступна изначальная версия данных (v1). Например, данные о имени студента:

--                 • В первой транзакции напишем запрос на изменение имени для второго студента (v1)

--                     ◦ В 4-й транзакции проверим, что имя пользователя ещё не зафиксировано в базе данных
--                     ◦ Зафиксируем изменения в 1-й транзакции
--                 • Во второй транзакции изменим имя студента на новое значение (v2)

--                     ◦ Увидим, что имя студента во второй транзакции изменилось (пока без её фиксации)
--                     ◦ Проверим, что в 4-й транзакции имя пока такое, какое было после изменения 1-й транзакции
--                     ◦ Пока не фиксируем данные изменения
--                 • В 3-й транзакции напишем запрос на удаление данной строки  (v3)
--                     ◦ Так как в 3-й транзакции не зафиксировано изменение, то запрос на select в открытых транзакциях возвращает версию v2 (изоляция read committed – отличие уровня изоляции от Serializable)
--                     ◦ Из-за блокировки, наложенной во 2-й транзакции, 3-я транзакция переходит в режим ожидания с запросом на удаление данных, ожидание будет происходить до завершения 2-й транзакции
--                     ◦ Проверьте, что 4-я транзакция продолжает свою работу, как и 2-я, возвращая разные версии, вторая v3, 4-я v2. 
--                     ◦ Завершите 2-ю транзакцию, это разблокирует 3-ю транзакцию
--                     ◦ Проверьте состояние данных в 4-й транзакции
--                     ◦ Закройте 3-ю транзакцию
--                     ◦ Проверьте состояние данных в 4-й транзакции
--                 • Просмотрите активные транзакции 
-- SELECT pid, state, datname, usename, query FROM pg_stat_activity where добавьте условие;

                    -- Подключение 1: 
                    BEGIN;
                    UPDATE z5_student SET name = 'v1' WHERE student_id = 2;

                    -- Подключение 4: 
                    BEGIN;
                    SELECT name FROM z5_student WHERE student_id = 2;


                    --Подключение 1
                    COMMIT;

                    -- Подключение 2: 
                    BEGIN;
                    UPDATE z5_student SET name = 'v2' WHERE student_id = 2;

                    -- Подключение 4: 
                    SELECT name FROM z5_student WHERE student_id = 2;

                    -- Подключение 3: 
                    BEGIN; 
                    DELETE FROM z5_student WHERE student_id = 2;

                    -- Подключение 2: 
                    COMMIT;

                    -- Подключение 4: 
                    SELECT name FROM z5_student WHERE student_id = 2;

                    -- Подключение 3: 
                    COMMIT;

                    SELECT pid, state, datname, usename, query
                    FROM pg_stat_activity
                    WHERE state = 'active';
--         4.4. Выполнение транзакций с уровнем изоляции Serializable
--             4.4.1. Смоделируйте работу транзакций по примеру диаграммы 2 из теоретических рекомендаций, также обратитесь к полезной ссылке по уровням изоляций транзакций.
                                        -- T1:
                    BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

                    -- T2:
                    BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

                    -- T3:
                    BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

                    -- T4:
                    BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;


                    -- t == 2

                    -- T1
                    UPDATE variables SET value = 'v2' WHERE id = 1;

                    -- T2
                    SELECT value FROM variables WHERE id = 1;

                    -- T3
                    SELECT value FROM variables WHERE id = 1;


                    -- t == 3

                    -- T1
                    SELECT value FROM variables WHERE id = 1;

                    -- T4
                    SELECT value FROM variables WHERE id = 1;


                    -- t==4

                    -- T2
                    SELECT value FROM variables WHERE id = 1;


                    -- t==5

                    -- T2
                    UPDATE variables SET value = 'v3' WHERE id = 1; --LOCK

                    -- T3
                    SELECT value FROM variables WHERE id = 1;

                    -- T4
                    SELECT value FROM variables WHERE id = 1;


                    -- === t==6

                    -- T1
                    COMMIT; -- SUCCESS

                    -- T2: UNLOCK
                    -- ERROR:  could not serialize access due to concurrent update


                    -- t == 7

                    -- T2
                    SELECT * FROM variables; -- : current transaction is aborted, commands ignored...

                    -- T3
                    SELECT value FROM variables WHERE id = 1;

                    -- T4
                    SELECT value FROM variables WHERE id = 1;

                    -- T5
                    BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;


                    -- t == 8

                    -- T2
                    COMMIT; -- -> ROLLBACK


                    -- t == 9

                    -- T3
                    SELECT value FROM variables WHERE id = 1;

                    -- T4
                    SELECT value FROM variables WHERE id = 1;

                    -- T5
                    SELECT value FROM variables WHERE id = 1;


                    -- t==10

                    -- T3
                    UPDATE variables SET value = 'v4' WHERE id = 1;
                    -- ERROR:  could not serialize access due to concurrent update

                    -- T5
                    UPDATE variables SET value = 'v5' WHERE id = 1; -- SUCCESS


                    -- t==11

                    -- T3
                    COMMIT; -- -> ROLLBACK


                    -- t == 12

                    -- T4
                    SELECT value FROM variables WHERE id = 1;

                    -- T5
                    SELECT value FROM variables WHERE id = 1;
-- Дополнительное задание*
--         4.5. Работа с транзакциями и расширенными политиками доступа
--             4.5.1. Создание транзакции для расчета успеваемости студентов
--                 • Добавьте поле student_rating типа real в таблицу student для хранения рейтинга студента.
                    ALTER TABLE z5_student ADD COLUMN student_rating REAL;
--                 • Создайте политику доступа, чтобы только менторы и администраторы могли видеть рейтинг студентов.
                    ALTER TABLE z5_student ENABLE ROW LEVEL SECURITY;

                    CREATE POLICY rating_access_policy
                    ON z5_student
                    FOR SELECT
                    TO mentors, administrators
                    USING (true);
--                 • Запустите транзакцию, которая рассчитает и сохранит рейтинг студента с id=1 на основе среднего результата его завершенных проектов.
                    BEGIN;

                    -- Рассчитываем и обновляем рейтинг для студента с id=1
                    UPDATE z5_student
                    SET student_rating = (
                        SELECT AVG(result) -- Предполагается, что в таблице project есть столбец 'result' с оценкой
                        FROM z5_project
                        WHERE student_id = 1 AND status = 'completed' -- Фильтруем по завершенным проектам
                    )
                    WHERE student_id = 1;

                    -- Проверяем изменения внутри транзакции (опционально)
                    SELECT student_id, student_rating FROM z5_student WHERE student_id = 1;

                    COMMIT;
--                 • Зафиксируйте транзакцию и получите ID выполненной транзакции.
                    BEGIN;
                    SELECT txid_current();
                    COMMIT;
--             4.5.2. Создание таблиц на основе типов проектов и настройка политик доступа
--                 • Создание таблиц для разных типов проектов.
                    CREATE TABLE research_projects (
                        project_id SERIAL PRIMARY KEY,
                        project_name TEXT NOT NULL,
                        status TEXT DEFAULT 'active',
                        student_id INT,
                        price NUMERIC,
                        result INT
                    );

                    -- Таблица для коммерческих проектов
                    CREATE TABLE commercial_projects (
                        project_id SERIAL PRIMARY KEY,
                        project_name TEXT NOT NULL,
                        status TEXT DEFAULT 'active',
                        student_id INT,
                        price NUMERIC,
                        result INT
                    );
--                 • Включите защиту на уровне строк (RLS) для всех созданных таблиц.
                    ALTER TABLE research_projects ENABLE ROW LEVEL SECURITY;
                    ALTER TABLE commercial_projects ENABLE ROW LEVEL SECURITY;      
--                 • Настройте права доступа: stud1 может только просматривать активные исследовательские проекты, stud2 имеет полный доступ ко всем типам проектов.
                    -- Политика для stud1: только чтение активных исследовательских проектов
                    CREATE POLICY "stud1_can_view_active_research_projects"
                    ON research_projects
                    FOR SELECT
                    TO stud1
                    USING (status = 'active');

                    -- Политика для stud2: полный доступ к исследовательским проектам
                    CREATE POLICY "stud2_full_access_to_research"
                    ON research_projects
                    FOR ALL
                    TO stud2
                    USING (true);

                    -- Политика для stud2: полный доступ к коммерческим проектам
                    CREATE POLICY "stud2_full_access_to_commercial"
                    ON commercial_projects
                    FOR ALL
                    TO stud2
                    USING (true);
--                 • Создайте объединенную таблицу project_unified, которая содержит данные всех типов проектов с указанием категории.
                    CREATE OR REPLACE VIEW project_unified AS
                    SELECT project_id, project_name, status, student_id, price, result, 'research' AS category
                    FROM research_projects
                    UNION ALL
                    SELECT project_id, project_name, status, student_id, price, result, 'commercial' AS category
                    FROM commercial_projects;
--                 • Ограничьте доступ к определенным столбцам - создайте представление project_limited, которое скрывает поля price и result от студентов.
                    CREATE OR REPLACE VIEW project_limited AS
                    SELECT project_id, project_name, status, student_id, category
                    FROM project_unified;


                    GRANT SELECT ON project_limited TO stud1;
                    -- stud2 уже имеет доступ через политики к базовым таблицам,
                    -- но можно также предоставить доступ к этому представлению для унификации.
                    GRANT SELECT ON project_limited TO stud2;