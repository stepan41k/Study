-- ВАРИАНТ №45. Университет (кафедры) Распопов 
-- Даны таблицы:
CREATE TABLE
    university (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        rector VARCHAR(255)
    );

CREATE TABLE
    faculty (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        dean VARCHAR(255),
        university_id INT REFERENCES university (id) ON DELETE CASCADE
    );

CREATE TABLE
    department (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        head VARCHAR(255),
        faculty_id INT REFERENCES faculty (id) ON DELETE CASCADE
    );

-- Наполнение тестовыми данными
INSERT INTO
    university (name, rector)
VALUES
    ('МГУ', 'Садовничий');

INSERT INTO
    faculty (name, dean, university_id)
VALUES
    ('ВМК', 'Соколов', 1),
    ('Мехмат', 'Шафаревич', 1);

INSERT INTO
    department (name, head, faculty_id)
VALUES
    ('Кафедра АСВК', 'Смелянский', 1),
    ('Кафедра Математики', 'Иванов', 2);

-- УНИВЕРСИТЕТ (Код_университета, Название, Ректор)
-- ФАКУЛЬТЕТ (Код_факультета, Название, Декан, Код_университета)
-- КАФЕДРА (Код_кафедры, Название, Заведующий, Код_факультета)
--     • Создайте представление с разделенными данными университета и напишите INSTEAD OF триггер для управления данными через представление
CREATE OR REPLACE VIEW
    v_university_structure AS
SELECT
    u.id AS u_id,
    u.name AS u_name,
    u.rector,
    f.id AS f_id,
    f.name AS f_name,
    f.dean
FROM
    university u
    JOIN faculty f ON u.id = f.university_id;

CREATE
OR REPLACE FUNCTION trg_v_university_structure_insert () RETURNS TRIGGER AS $$
        DECLARE
            new_uni_id INT;
        BEGIN
            SELECT id INTO new_uni_id FROM university WHERE name = NEW.u_name;

            IF new_uni_id IS NULL THEN
                INSERT INTO university (name, rector) 
                VALUES (NEW.u_name, NEW.rector) 
                RETURNING id INTO new_uni_id;
            END IF;

            INSERT INTO faculty (name, dean, university_id)
            VALUES (NEW.f_name, NEW.dean, new_uni_id);

            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_instead_of_insert INSTEAD OF INSERT ON v_university_structure FOR EACH ROW
EXECUTE FUNCTION trg_v_university_structure_insert ();

INSERT INTO
    v_university_structure (u_name, rector, f_name, dean)
VALUES
    ('МГТУ', 'Александров', 'ИУ', 'Пролетарский');

--     • Реализуйте составной триггер для таблицы КАФЕДРА: автоматическая проверка соответствия факультету
CREATE
OR REPLACE FUNCTION check_dept_compliance () RETURNS TRIGGER AS $$
        DECLARE
            faculty_dean VARCHAR;
        BEGIN
            SELECT dean INTO faculty_dean FROM faculty WHERE id = NEW.faculty_id;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'Факультет с ID % не найден', NEW.faculty_id;
            END IF;

            IF NEW.head = faculty_dean THEN
                RAISE EXCEPTION 'Конфликт интересов: Заведующий кафедрой (%) не может быть Деканом того же факультета', NEW.head;
            END IF;

            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_dept_compound_check BEFORE INSERT
OR
UPDATE ON department FOR EACH ROW
EXECUTE FUNCTION check_dept_compliance ();

INSERT INTO
    department (name, head, faculty_id)
VALUES
    ('Кафедра Физики', 'Попов', 20);

--      Хранимые процедуры и функции:
--     • Создайте процедуру с курсором и параметром: получите структуру указанного университета
CREATE
OR REPLACE PROCEDURE show_uni_structure (p_uni_id INT) LANGUAGE plpgsql AS $$
        DECLARE
            cur_structure CURSOR FOR 
                SELECT f.name as f_name, d.name as d_name
                FROM faculty f
                LEFT JOIN department d ON f.id = d.faculty_id
                WHERE f.university_id = p_uni_id
                ORDER BY f.name;
                
            rec RECORD;
            v_uni_name VARCHAR;
        BEGIN
            SELECT name INTO v_uni_name FROM university WHERE id = p_uni_id;
            
            IF v_uni_name IS NULL THEN
                RAISE NOTICE 'Университет с ID % не найден.', p_uni_id;
                RETURN;
            END IF;

            RAISE NOTICE 'Структура университета: %', v_uni_name;
            RAISE NOTICE '--------------------------------';

            OPEN cur_structure;
            LOOP
                FETCH cur_structure INTO rec;
                EXIT WHEN NOT FOUND;
                
                IF rec.d_name IS NOT NULL THEN
                    RAISE NOTICE 'Факультет: % | Кафедра: %', rec.f_name, rec.d_name;
                ELSE
                    RAISE NOTICE 'Факультет: % | (Кафедр нет)', rec.f_name;
                END IF;
            END LOOP;
            CLOSE cur_structure;
        END;
        $$;

CALL show_uni_structure (1);

--     • Создайте функцию с оконными функциями: определите рейтинг факультетов по количеству кафедр
CREATE
OR REPLACE FUNCTION get_faculty_ratings () RETURNS TABLE (
    uni_name VARCHAR,
    faculty_name VARCHAR,
    dept_count BIGINT,
    rating BIGINT
) AS $$
        BEGIN
            RETURN QUERY
            SELECT 
                u.name,
                f.name,
                COUNT(d.id) as count_depts,
                DENSE_RANK() OVER (ORDER BY COUNT(d.id) DESC) as rank_val
            FROM faculty f
            JOIN university u ON f.university_id = u.id
            LEFT JOIN department d ON f.id = d.faculty_id
            GROUP BY u.name, f.name;
        END;
        $$ LANGUAGE plpgsql;

SELECT
    *
FROM
    get_faculty_ratings ();