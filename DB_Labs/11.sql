-- При выполнении задания не забудьте проверять работу процедур и функций. Сделайте отладку 1 процедуры и 2-х функций по Вашему выбору. 
--         4.1. Процедуры и функции без привязки к базе данных
--             4.1.1. Напишите процедуру сurrent_time, которая выводит текущее время n раз, где n - параметр, задаваемый пользователем.
CREATE
OR REPLACE PROCEDURE current_time_n (n INT) LANGUAGE plpgsql AS $$
                DECLARE 
                    i INT;
                BEGIN
                    FOR i IN 1..n LOOP
                        RAISE NOTICE 'Time iteration %: %', i, NOW()::TIME;
                    END LOOP;
                END;
                $$;

--             4.1.2. Создайте хранимую процедуру cost, которая по введённой цене товара и его количеству вычислит сумму к выдаче. 
CREATE
OR REPLACE PROCEDURE calculate_cost (
    IN p_price NUMERIC,
    IN p_quantity INT,
    OUT p_total NUMERIC
) LANGUAGE plpgsql AS $$
                BEGIN
                    p_total := p_price * p_quantity;
                END;
                $$;

--             4.1.3. Напишите функцию, которая в зависимости от введенного значения переменной cur вычислит стоимость товара в долларах, если переменная cur=0 и в рублях, если переменная cur=1.
CREATE
OR REPLACE FUNCTION convert_currency (val NUMERIC, cur INT) RETURNS NUMERIC LANGUAGE plpgsql AS $$
                DECLARE
                    rate_usd_to_rub NUMERIC := 90.0;
                BEGIN
                    IF cur = 0 THEN
                        RETURN val / rate_usd_to_rub; -- В долларах
                    ELSIF cur = 1 THEN
                        RETURN val; -- В рублях
                    ELSE
                        RETURN NULL;
                    END IF;
                END;
                $$;

--         4.2. Хранимые процедуры выборки данных
--             4.2.1. Создание процедуры сnt_project, которая подсчитывает количество записей в таблице project.
CREATE
OR REPLACE PROCEDURE cnt_project () LANGUAGE plpgsql AS $$
                DECLARE
                    cnt INT;
                BEGIN
                    SELECT count(*) INTO cnt FROM z5_project;
                    RAISE NOTICE 'Количество проектов: %', cnt;
                END;
                $$;

--             4.2.2. (Использовать входные и выходные параметры) Создайте хранимую процедуру project_name, которая по первичному ключу проекта выдаёт название проекта. Для решения задачи требуется определить параметр shifr с атрибутом IN, а параметр project_name с атрибутом OUT.
CREATE
OR REPLACE PROCEDURE get_project_name_by_shifr (IN p_shifr VARCHAR, OUT p_project_name VARCHAR) LANGUAGE plpgsql AS $$
                BEGIN
                    SELECT projectname INTO p_project_name 
                    FROM z5_project 
                    WHERE shifr = p_shifr;
                    
                    IF NOT FOUND THEN
                        p_project_name := 'Project not found';
                    END IF;
                END;
                $$;

--             4.2.3. Создание хранимой процедуры mentor_team, которая по имени ментора выводит название команд.
CREATE
OR REPLACE PROCEDURE mentor_team (p_mentor_name VARCHAR) LANGUAGE plpgsql AS $$
                DECLARE
                    rec RECORD;
                BEGIN
                    FOR rec IN 
                        SELECT c.command 
                        FROM z5_command c
                        JOIN z5_mentor m ON m.idcommand = c.id
                        WHERE m.lastname = p_mentor_name
                    LOOP
                        RAISE NOTICE 'Команда ментора %: %', p_mentor_name, rec.command;
                    END LOOP;
                END;
                $$;

--             4.2.4. (4.1.3 применить процедуру использовать входные и выходные параметры). Создание хранимой процедуры, которая по введённому коду студента выведет список проектов и стоимость разработки проектов в долларах (если переменная cur=0) и в рублях (если переменная cur=1).
CREATE
OR REPLACE PROCEDURE student_projects_cost (p_student_id INT, cur INT) LANGUAGE plpgsql AS $$
                DECLARE
                    rec RECORD;
                    converted_price NUMERIC;
                BEGIN
                    FOR rec IN 
                        SELECT p.projectname, p.price 
                        FROM z5_project p
                        JOIN z5_command c ON c.id = p.idcommand
                        JOIN z5_student s ON s.idcommand = c.id
                        WHERE s.id = p_student_id
                    LOOP
                        -- Вызов функции из 4.1.3
                        converted_price := convert_currency(rec.price, cur);
                        
                        RAISE NOTICE 'Проект: %, Стоимость (%): %', 
                            rec.projectname, 
                            CASE WHEN cur=0 THEN 'USD' ELSE 'RUB' END, 
                            ROUND(converted_price, 2);
                    END LOOP;
                END;
                $$;

--             4.2.5. (домен) Создайте домен, который включает описание поля типа переменной текстовой длины не пустого с проверкой на значение поля шифра проекта (см.работу ранее). Внесите изменение в таблицу, отредактируйте определение поля. Напишите пользовательскую процедуру, которая найдёт все проекты с шифром в указанном диапазоне.
CREATE DOMAIN dom_shifr AS VARCHAR(6) CHECK (
    VALUE IS NOT NULL
    AND VALUE ~ '^[A-Za-z0-9\-]+$'
);

ALTER TABLE z5_project
ALTER COLUMN shifr
TYPE dom_shifr;

CREATE
OR REPLACE PROCEDURE find_projects_in_shifr_range (start_s VARCHAR, end_s VARCHAR) LANGUAGE plpgsql AS $$
                DECLARE
                    r RECORD;
                BEGIN
                    FOR r IN SELECT * FROM z5_project WHERE shifr BETWEEN start_s AND end_s LOOP
                        RAISE NOTICE 'Found Project: % (Shifr: %)', r.projectname, r.shifr;
                    END LOOP;
                END;
                $$;

--         4.3. Создание хранимых процедур для выполнения операций с записями:
--             4.3.1. Создайте хранимую процедуру ввода данных в таблицу project, предусмотрите обработку исключений.
CREATE
OR REPLACE PROCEDURE insert_project_safe (
    p_name VARCHAR,
    p_price NUMERIC,
    p_shifr VARCHAR,
    p_cmd_id INT
) LANGUAGE plpgsql AS $$
                BEGIN
                    INSERT INTO z5_project (projectname, price, shifr, idcommand, startdate)
                    VALUES (p_name, p_price, p_shifr, p_cmd_id, CURRENT_DATE);
                EXCEPTION WHEN OTHERS THEN
                    RAISE NOTICE 'Ошибка вставки проекта: %', SQLERRM;
                END;
                $$;

--             4.3.2. Создайте хранимую процедуру изменения записей таблицы team
CREATE
OR REPLACE PROCEDURE update_team_name (p_id INT, p_new_name VARCHAR) LANGUAGE plpgsql AS $$
                BEGIN
                    UPDATE z5_command SET command = p_new_name WHERE id = p_id;
                    IF NOT FOUND THEN
                        RAISE NOTICE 'Команда с ID % не найдена', p_id;
                    END IF;
                END;
                $$;

--             4.3.3. Добавьте поле рейтинг в таблицу student. Присвойте студентам рейтинг 50. Создайте хранимую процедуру для изменения рейтинга на 10% с каждым участием в проекте. 
ALTER TABLE z5_student
ADD COLUMN rating NUMERIC DEFAULT 50;

UPDATE z5_student
SET
    rating = 50;

CREATE
OR REPLACE PROCEDURE update_student_rating_proc (p_student_id INT) LANGUAGE plpgsql AS $$
                DECLARE
                    prj_count INT;
                    current_rating NUMERIC;
                    i INT;
                BEGIN
                    SELECT rating INTO current_rating FROM z5_student WHERE id = p_student_id;
                    
                    SELECT count(p.id) INTO prj_count
                    FROM z5_project p
                    JOIN z5_student s ON s.idcommand = p.idcommand
                    WHERE s.id = p_student_id;

                    FOR i IN 1..prj_count LOOP
                        current_rating := current_rating * 1.10;
                    END LOOP;

                    UPDATE z5_student SET rating = current_rating WHERE id = p_student_id;
                    RAISE NOTICE 'Новый рейтинг студента %: %', p_student_id, current_rating;
                END;
                $$;

--         4.4. Создание хранимых функций:
--             4.4.1. (int) Создадим хранимую функцию, которая по названию команды получит общее количество проектов, которые выполнялись за конкретный месяц.
CREATE
OR REPLACE FUNCTION count_projects_by_team_month (p_team_name VARCHAR, p_month INT) RETURNS INT LANGUAGE plpgsql AS $$
                DECLARE
                    cnt INT;
                BEGIN
                    SELECT COUNT(*) INTO cnt
                    FROM z5_project p
                    JOIN z5_command c ON p.idcommand = c.id
                    WHERE c.command = p_team_name 
                    AND EXTRACT(MONTH FROM p.startdate) = p_month;
                    RETURN cnt;
                END;
                $$;

--             4.4.2. (text) Создадим хранимую функцию, которая по имени команды выводит название проекта, имеющую максимальную стоимость для данной команды.
CREATE
OR REPLACE FUNCTION get_max_price_project_name (p_team_name VARCHAR) RETURNS TEXT LANGUAGE plpgsql AS $$
                DECLARE
                    p_name TEXT;
                BEGIN
                    SELECT p.projectname INTO p_name
                    FROM z5_project p
                    JOIN z5_command c ON p.idcommand = c.id
                    WHERE c.command = p_team_name
                    ORDER BY p.price DESC
                    LIMIT 1;
                    
                    RETURN COALESCE(p_name, 'Нет проектов');
                END;
                $$;

--             4.4.3. (применение функции count_day) Найдите количество дней, которые прошли от даты начала работы над проектом до текущей даты. При выполнении задания используйте функцию count_day, созданную ранее.
-- Вспомогательная функция count_day (как сказано в задании, "созданная ранее")
CREATE
OR REPLACE FUNCTION count_day (start_d DATE) RETURNS INT AS $$
                BEGIN
                    RETURN (CURRENT_DATE - start_d);
                END;
                $$ LANGUAGE plpgsql;

-- Основное задание
CREATE
OR REPLACE FUNCTION days_since_project_start (p_project_id INT) RETURNS INT LANGUAGE plpgsql AS $$
                DECLARE
                    s_date DATE;
                BEGIN
                    SELECT startdate INTO s_date FROM z5_project WHERE id = p_project_id;
                    IF s_date IS NULL THEN RETURN 0; END IF;
                    RETURN count_day(s_date);
                END;
                $$;

--             4.4.4. (set) Создайте функцию, которая возвращает всех студентов указанной команды.
CREATE
OR REPLACE FUNCTION get_students_in_team (p_team_name VARCHAR) RETURNS SETOF z5_student LANGUAGE plpgsql AS $$
                BEGIN
                    RETURN QUERY 
                    SELECT s.* 
                    FROM z5_student s
                    JOIN z5_command c ON s.idcommand = c.id
                    WHERE c.command = p_team_name;
                END;
                $$;

--             4.4.5. *(массив) Добавьте поле телефоны в таблицу student, типа данных – массив строк, заполните значениями. Напишите функцию, которая находит контактные телефоны указанного студента.
ALTER TABLE z5_student
ADD COLUMN phones TEXT[];

-- Заполним для теста
UPDATE z5_student
SET
    phones = ARRAY['+79001112233', '+79998887766']
WHERE
    id = 1;

CREATE
OR REPLACE FUNCTION get_student_phones (p_student_id INT) RETURNS TEXT[] LANGUAGE plpgsql AS $$
                DECLARE
                    res TEXT[];
                BEGIN
                    SELECT phones INTO res FROM z5_student WHERE id = p_student_id;
                    RETURN res;
                END;
                $$;

--             4.4.6. *(сложный тип данных) Создайте тип данных t_us для хранения списка студентов. Создайте таблицу student_project с полями шифр проекта, название, поле sp типа данных t_us. Заполните данными из существующих таблиц. Напишите программу для получения списка студентов, которые выполняли проекты с номером 1234, и с номером 1235.
-- Создаем тип для студента
CREATE TYPE t_us AS (lastname VARCHAR, firstname VARCHAR);

-- Таблица student_project со сложным типом
CREATE TABLE
    z5_student_project_complex (
        shifr VARCHAR(20),
        projectname VARCHAR(100),
        sp t_us
    );

-- Заполнение (в реальности это делается сложнее, здесь пример одной вставки)
INSERT INTO
    z5_student_project_complex (shifr, projectname, sp)
VALUES
    ('1234', 'Proj A', ROW ('Ivanov', 'Ivan')::t_us),
    ('1235', 'Proj B', ROW ('Petrov', 'Petr')::t_us);

-- Функция получения списка (возвращает текст для наглядности)
CREATE
OR REPLACE FUNCTION get_students_for_projects_1234_1235 () RETURNS TABLE (lname VARCHAR, fname VARCHAR, shifr_out VARCHAR) LANGUAGE plpgsql AS $$
                BEGIN
                    RETURN QUERY
                    SELECT (sp).lastname, (sp).firstname, shifr
                    FROM z5_student_project_complex
                    WHERE shifr IN ('1234', '1235');
                END;
                $$;

-- TODO: Curosr
--             4.4.7. (refcursor) Объявите тип запись, включающую поля Фамилия студента, Название проекта, Дата начала работы над проектом. Создайте хранимую функцию, которая по номеру выдачи проекта получит запись – фамилия студента, название проекта и дата начала работы над проектом. Выведите результат работы функции в окно вывода.
CREATE TYPE student_project_info AS (
    s_lastname VARCHAR,
    p_projectname VARCHAR,
    p_startdate DATE
);

CREATE
OR REPLACE FUNCTION get_project_cursor (p_project_id INTEGER) RETURNS refcursor LANGUAGE plpgsql AS $$
            DECLARE
                my_ref_cursor refcursor := 'result_cursor';
            BEGIN
                OPEN my_ref_cursor FOR
                SELECT 
                    s.lastname, 
                    p.projectname, 
                    p.startdate
                FROM z5_project p
                JOIN z5_student s ON p.idcommand = s.idcommand
                WHERE p.id = p_project_id;

                RETURN my_ref_cursor;
            END;
            $$;

DO $$
            DECLARE
                v_cursor refcursor;
                v_record student_project_info;
            BEGIN
                v_cursor := get_project_cursor(1);

                LOOP
                    FETCH v_cursor INTO v_record;
                    EXIT WHEN NOT FOUND;

                    RAISE NOTICE 'Фамилия: %, Проект: %, Дата начала: %', 
                                v_record.s_lastname, 
                                v_record.p_projectname, 
                                v_record.p_startdate;
                END LOOP;
                
                CLOSE v_cursor;
            END;
            $$;

SELECT
    get_project_info_cursor (2);

--TODO: overload
--             4.4.8. (перегружаемая функция) Проверьте, есть ли проект указанной команды, если да, то найти их количество, если команда не указана, то вернуть 0. (перегрузка функции – разное количество параметров). 
-- 1. С параметром (название команды)
CREATE
OR REPLACE FUNCTION check_project_overload (p_team_name VARCHAR) RETURNS INT LANGUAGE plpgsql AS $$
                DECLARE
                    cnt INT;
                BEGIN
                    SELECT COUNT(*) INTO cnt 
                    FROM z5_project p JOIN z5_command c ON p.idcommand = c.id
                    WHERE c.command = p_team_name;
                    
                    RETURN cnt;
                END;
                $$;

-- 2. Без параметров (возвращает 0)
CREATE
OR REPLACE FUNCTION check_project_overload () RETURNS INT LANGUAGE plpgsql AS $$
                BEGIN
                    RETURN 0;
                END;
                $$;

SELECT
    check_project_overload ();

SELECT
    check_project_overload ('Omega');

--             4.4.9. (табличная функция) Создайте функцию, выводящую названия проектов как шифр и их название. Выведите данные на экран в виде шифр– название. При выводе пользуйтесь функциями LPAD, RPAD. 
CREATE
OR REPLACE FUNCTION list_projects_formatted () RETURNS TABLE (formatted_str TEXT) LANGUAGE plpgsql AS $$
                BEGIN
                    RETURN QUERY 
                    SELECT RPAD(shifr, 10, '.') || LPAD(projectname, 20, ' ') 
                    FROM z5_project;
                END;
                $$;

--             4.4.10. (возврат строки) Создайте функцию, возвращающую строку таблицы student, напишите запрос для добавления полученной с помощью функции строки в таблицу student.
CREATE
OR REPLACE FUNCTION get_student_row (p_id INT) RETURNS z5_student LANGUAGE plpgsql AS $$
                DECLARE
                    r z5_student;
                BEGIN
                    SELECT * INTO r FROM z5_student WHERE id = p_id;
                    -- Для примера модифицируем ID, чтобы можно было вставить как нового
                    r.id := NULL; 
                    r.lastname := r.lastname || '_copy';
                    RETURN r;
                END;
                $$;

-- TODO: Курсор
-- Пример использования в SQL запросе:
-- INSERT INTO z5_student SELECT * FROM get_student_row(1);
--             4.4.11. (курсоры) Создайте тип данных t_bk для хранения списка проектов. Создайте таблицу accounting с полями номер месяца, год, поле sp_us типа данных t_us, поле sp_bk типа данных t_bk. Заполните таблицу записями, используя курсоры. Выведите данные.
CREATE TYPE t_bk AS (projectname VARCHAR, price NUMERIC);

CREATE TABLE
    z5_accounting (month INT, year INT, sp_us t_us, sp_bk t_bk);

CREATE
OR REPLACE PROCEDURE fill_accounting_cursor () LANGUAGE plpgsql AS $$
                DECLARE
                    cur_data CURSOR FOR 
                        SELECT s.lastname, s.firstname, p.projectname, p.price, p.startdate
                        FROM z5_project p
                        JOIN z5_student s ON s.idcommand = p.idcommand; -- Студенты команды проекта
                    rec RECORD;
                BEGIN
                    OPEN cur_data;
                    LOOP
                        FETCH cur_data INTO rec;
                        EXIT WHEN NOT FOUND;
                        
                        INSERT INTO z5_accounting (month, year, sp_us, sp_bk)
                        VALUES (
                            EXTRACT(MONTH FROM rec.startdate),
                            EXTRACT(YEAR FROM rec.startdate),
                            ROW(rec.lastname, rec.firstname)::t_us,
                            ROW(rec.projectname, rec.price)::t_bk
                        );
                    END LOOP;
                    CLOSE cur_data;
                END;
                $$;

CALL fill_accounting_cursor ();

SELECT
    *
from
    z5_accounting;

-- TODO: polymorph
--             4.4.12. *(полиморфная функция RETURNS anyelement) Создайте функцию (id int, nm text), которая будет возвращать разную информацию в зависимости от типа от типа переданной сущности и типа операции для таблиц Ментор, Студент, Проект – для ментора и студента – количество проектов, для таблицы Проект – список ресурсов.
CREATE
OR REPLACE FUNCTION z5_get_entity_info (search_id INT, entity_sample anyelement) RETURNS TEXT AS $$
            DECLARE
                v_result TEXT;
                v_type TEXT := pg_typeof(entity_sample)::TEXT;
            BEGIN
                IF v_type LIKE '%z5_student' THEN
                    SELECT COUNT(p.id)::TEXT INTO v_result
                    FROM z5_student s
                    JOIN z5_project p ON s.idcommand = p.idcommand
                    WHERE s.id = search_id;
                    
                    RETURN 'Количество проектов студента: ' || COALESCE(v_result, '0');

                ELSIF v_type LIKE '%z5_mentor' THEN
                    SELECT COUNT(id)::TEXT INTO v_result
                    FROM z5_project
                    WHERE mentor_id = search_id;
                    
                    RETURN 'Количество проектов ментора: ' || COALESCE(v_result, '0');

                ELSIF v_type LIKE '%z5_project' THEN
                    SELECT string_agg(resource, ', ') INTO v_result
                    FROM z5_resource
                    WHERE idproject = search_id;
                    
                    RETURN 'Ресурсы проекта: ' || COALESCE(v_result, 'Нет ресурсов');

                ELSE
                    RETURN 'Неизвестный тип сущности';
                END IF;
            END;
            $$ LANGUAGE plpgsql;

SELECT
    z5_get_entity_info (3, NULL::z5_student);

SELECT
    z5_get_entity_info (3, NULL::z5_mentor);

SELECT
    z5_get_entity_info (1, NULL::z5_project);

-- TODO: lateral
--             4.4.13. *(QUERY LATERAL join с функциями) Создайте функцию с использованием LATERAL, которая для команд показывает проекты за указанный период.
CREATE
OR REPLACE FUNCTION get_projects_by_cmd_period (_cmd_id INT, _start_date DATE, _end_date DATE) RETURNS TABLE (
    p_name VARCHAR,
    p_start DATE,
    p_status VARCHAR,
    p_price INT
) LANGUAGE plpgsql AS $$
                BEGIN
                    RETURN QUERY 
                    SELECT 
                        p.projectname::VARCHAR,
                        p.startdate,
                        p.status::VARCHAR,
                        p.price::INT
                    FROM z5_project p
                    WHERE p.idcommand = _cmd_id
                    AND p.startdate >= _start_date 
                    AND p.startdate <= _end_date;
                END;
                $$;

CREATE
OR REPLACE FUNCTION show_commands_projects_report (_date_from DATE, _date_to DATE) RETURNS TABLE (
    command_name VARCHAR,
    project_name VARCHAR,
    start_date DATE,
    status VARCHAR,
    price INT
) LANGUAGE plpgsql AS $$
                BEGIN
                    RETURN QUERY 
                    SELECT 
                        c.command::VARCHAR,
                        res.p_name,
                        res.p_start,
                        res.p_status,
                        res.p_price
                    FROM z5_command c
                    CROSS JOIN LATERAL get_projects_by_cmd_period(c.id, _date_from, _date_to) res;
                END;
                $$;

SELECT
    *
FROM
    show_commands_projects_report ('2022-01-01', '2025-12-31');

--         4.5. Доп.задания*
--             4.5.1. Добавить в таблицу ментор поле рейтинг. Задайте значение рейтинга 100 для каждого метора. Изменить значение рейтинга для ментора, применяя правила:
--                 • если ментор не брал команды в текущий месяц -50 к рейтингу
--                 • если ментор не брал команды в текущую неделю -10 к рейтингу
--                 • если ментор в текущий месяц взял 1 команду +10 к рейтингу
--                 • если ментор взял больше 5 команд+100 к рейтингу
ALTER TABLE z5_mentor
ADD COLUMN rating INT DEFAULT 100;

CREATE
OR REPLACE PROCEDURE update_mentor_rating () LANGUAGE plpgsql AS $$
                DECLARE
                    m RECORD;
                    cmd_count_month INT;
                    cmd_count_week INT;
                    rating_change INT;
                BEGIN
                    FOR m IN SELECT id, rating FROM z5_mentor LOOP
                        rating_change := 0;
                        
                        SELECT COUNT(*) INTO cmd_count_month 
                        FROM z5_project 
                        WHERE mentor_id = m.id AND EXTRACT(MONTH FROM startdate) = EXTRACT(MONTH FROM CURRENT_DATE);

                        SELECT COUNT(*) INTO cmd_count_week 
                        FROM z5_project 
                        WHERE mentor_id = m.id AND startdate >= CURRENT_DATE - 7;
                        
                        IF cmd_count_month = 0 THEN rating_change := rating_change - 50; END IF;
                        IF cmd_count_week = 0 THEN rating_change := rating_change - 10; END IF;
                        IF cmd_count_month = 1 THEN rating_change := rating_change + 10; END IF;
                        IF cmd_count_month > 5 THEN rating_change := rating_change + 100; END IF;

                        UPDATE z5_mentor SET rating = m.rating + rating_change WHERE id = m.id;
                    END LOOP;
                END;
                $$;

--             4.5.2. Создайте хранимую функцию, возвращающую таблицу данных о студентах и проектах, которые они взяли в указанный период.
CREATE
OR REPLACE FUNCTION report_students_projects (d_start DATE, d_end DATE) RETURNS TABLE (
    fist_name VARCHAR,
    student_name VARCHAR,
    project_name VARCHAR,
    start_date DATE
) LANGUAGE plpgsql AS $$
                BEGIN
                    RETURN QUERY
                    SELECT s.firstname, s.lastname, p.projectname, p.startdate
                    FROM z5_student s
                    JOIN z5_project p ON s.idcommand = p.idcommand
                    WHERE p.startdate BETWEEN d_start AND d_end;
                END;
                $$;

SELECT
    *
FROM
    report_students_projects ('2023-01-01', '2025-12-31');

--             4.5.3. Выведите информацию о студентах группы с определённым номером, упорядоченных в порядке убывания года рождения
-- SELECT * FROM z5_student WHERE groupname = 'Omega' ORDER BY yearb DESC;
-- Отладка:
DO $$
                DECLARE
                    v_total NUMERIC;
                    v_out_name VARCHAR;
                    v_cnt INT;
                    v_max_prj TEXT;
                BEGIN
                    RAISE NOTICE '--- START DEBUGGING ---';

                    -- 1. Тест процедуры 4.1.2
                    CALL calculate_cost(150.5, 4, v_total);
                    RAISE NOTICE '4.1.2 Cost Test (150.5 * 4): %', v_total;

                    -- 2. Тест процедуры 4.2.2
                    CALL get_project_name_by_shifr('PR0113', v_out_name);
                    RAISE NOTICE '4.2.2 Project Name for PR-0113: %', v_out_name;

                    -- 3. Тест функции 4.4.1
                    v_cnt := count_projects_by_team_month('Omega', 1); -- Январь
                    RAISE NOTICE '4.4.1 Omega projects in Jan: %', v_cnt;

                    -- 4. Тест функции 4.4.2
                    v_max_prj := get_max_price_project_name('A&B');
                    RAISE NOTICE '4.4.2 A&B max price project: %', v_max_prj;
                    
                    -- 5. Тест процедуры (4.1.1)
                    RAISE NOTICE '4.1.1';
                    CALL current_time_n(2); 

                    RAISE NOTICE '--- END DEBUGGING ---';
                END;
                $$;