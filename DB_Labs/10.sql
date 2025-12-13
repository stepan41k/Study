-- При выполнении задания необходимо обрабатывать исключения, для 2 задач провести отладку (debug1,2).
--         4.1. PL/pgSQL код без привязки к базе данных
--             4.1.1. Создайте анонимный блок, в котором объявите переменные. Используя эти переменные выведите:  Наушники JBL T110 899*5=4495
--                 • v_pr number(8,2) := 899
--                 • v_qu number(3,0) :=5
--                 • v_title varchar(20) := ' Наушники JBL T110'
DO $$
                    DECLARE
                        v_pr NUMERIC(8, 0) := 899;
                        v_qu NUMERIC(3, 0) := 5;
                        v_title VARCHAR(20) := ' Наушники JBL T110';
                        v_total NUMERIC(10, 2);
                    BEGIN
                        v_total := v_pr * v_qu;
                        RAISE NOTICE '% %*%=%', TRIM(v_title), v_pr, v_qu, v_total;
                    END $$;

--             4.1.2. Напишите анонимный блок, в котором выведите текущее время n раз, где n – переменная, значение которой задаётся.
DO $$
                    DECLARE
                        n INT := 3;
                        i INT := 1;
                    BEGIN
                        RAISE NOTICE 'Вывод текущего времени % раз:', n;
                        WHILE i <= n LOOP
                            RAISE NOTICE '  Повтор %: %', i, NOW()::TIME;
                            i := i + 1;
                        END LOOP;
                    END $$;

--             4.1.3. Напишите код, который в зависимости от значения переменной cur вычислит стоимость товара в долларах, если переменная cur=0 и в рублях, если переменная cur=1.
DO $$
                    DECLARE
                        v_price NUMERIC := 10000;
                        v_cur INT := 1; -- 0: USD, 1: RUB (задаем значение)
                        v_exchange_rate NUMERIC := 91.5;
                        v_result NUMERIC;
                    BEGIN
                        IF v_cur = 0 THEN
                            v_result := v_price;
                            RAISE NOTICE 'Стоимость товара в долларах: $%', v_result;
                        ELSIF v_cur = 1 THEN
                            v_result := v_price * v_exchange_rate;
                            RAISE NOTICE 'Стоимость товара в рублях: % руб.', v_result;
                        ELSE
                            RAISE NOTICE 'Некорректное значение переменной cur (должно быть 0 или 1).';
                        END IF;
                    END $$;

--         4.2. Использование блоков <<>>
--             4.2.1. Создайте анонимный блок, содержащий два блока – внешний и внутренний. Во внешнем блоке объявите и инициализируйте переменные:
--                 • v_date – текущая дата
--                 • v_name – имя и фамилия отца
--                 • v_dt_bt – дата рождения отца
-- Во внутреннем блоке объявите и инициализируйте переменные
--                 • v_name – имя и фамилия ребёнка
--                 • v_dt_bt – дата рождения ребёнка
-- Объявите переменные, вычислите их значения и выведите на экран
--                 • v_age_f – возраст отца
--                 • v_age_c – возраст ребёнка
--                 • v_age_v – возраст отца на момент рождения ребёнка
DO $$
                    DECLARE
                        v_date DATE := CURRENT_DATE;
                        v_name_father VARCHAR(50) := 'Иван Петров';
                        v_dt_bt_father DATE := '1970-05-15';
                        v_age_f INT;
                    BEGIN
                        v_age_f := DATE_PART('year', AGE(v_date, v_dt_bt_father));

                        RAISE NOTICE '--- Внешний блок (Отец) ---';
                        RAISE NOTICE 'Текущая дата (v_date): %', v_date;

                        <<child_block>>
                        DECLARE
                            v_name_child VARCHAR(50) := 'Петр Иванов';
                            v_dt_bt_child DATE := '2000-10-20';
                            v_age_c INT;
                            v_age_v INT;
                        BEGIN
                            v_age_c := DATE_PART('year', AGE(v_date, v_dt_bt_child));

                            v_age_v := DATE_PART('year', AGE(v_dt_bt_child, v_dt_bt_father));

                            RAISE NOTICE '--- Внутренний блок (Ребенок) ---';
                            RAISE NOTICE 'Имя ребенка (child_block.v_name): %', v_name_child;
                            RAISE NOTICE 'Возраст отца (v_age_f): % лет', v_age_f;
                            RAISE NOTICE 'Возраст ребенка (v_age_c): % лет', v_age_c;
                            RAISE NOTICE 'Возраст отца на момент рождения ребенка (v_age_v): % лет', v_age_v;
                        END child_block;
                    END $$;

--         4.3. PL/pgSQL код с привязкой к базе данных
--             4.3.1. Объявите переменные для присвоения значения следующим столбцам:
--                 • Фамилия ментора
--                 • Имя ментора
--                 • Отчество ментора
--                 • Шифр проекта
--                 • Название проекта
--                 • Год реализации проекта
--                 • Месяц реализации проекта
--                 • Стоимость реализации проекта
DO $$
                    DECLARE
                        v_m_last z5_mentor.lastname%TYPE;
                        v_m_first z5_mentor.firstname%TYPE;
                        v_m_middle text := 'Иванович'; -- Нет поля отчество в БД
                        v_p_id z5_project.id%TYPE;
                        v_p_name z5_project.projectname%TYPE;
                        v_p_year int;
                        v_p_month int;
                        v_p_price z5_project.price%TYPE;
                    BEGIN
                        SELECT 
                            m.lastname, m.firstname, 
                            p.id, p.projectname, 
                            EXTRACT(YEAR FROM p.startdate), 
                            EXTRACT(MONTH FROM p.startdate), 
                            p.price
                        INTO 
                            v_m_last, v_m_first, 
                            v_p_id, v_p_name, 
                            v_p_year, v_p_month, 
                            v_p_price
                        FROM z5_project p
                        JOIN z5_command c ON p.idcommand = c.id
                        JOIN z5_mentor m ON m.idcommand = c.id
                        LIMIT 1;

                        RAISE NOTICE 'Ментор % % %, Проект %, %, год реализации %, месяц реализации %, стоимость реализации %',
                            v_m_last, v_m_first, v_m_middle, v_p_id, v_p_name, v_p_year, v_p_month, v_p_price;
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            RAISE NOTICE 'Данные не найдены';
                    END $$;

-- Используя оператор SELECT присвоить заданным переменным значения и вывести на экран с именами полей на русском языке, например в таком формате: Ментов Фамилия Имя Отчество, Проект шифр, название, год реализации, месяц реализации, стоимость реализации
--             4.3.2. Объявить и инициализировать переменные с привязкой к полям
--                 • тематика проекта
--                 • стоимость проекта
--                 • суточная стоимость – (выводить с 2 знаками после запятой), вычисление стоимости реализации проекта за сутки 
-- Используя эти переменные, создать запрос, который получит стоимость заданной тематики. Вывести суммарную стоимость, а также количество проектов.
DO $$
                    DECLARE
                        v_topic z5_project.project_type%TYPE := 'IT';
                        v_total_price z5_project.price%TYPE;
                        v_day_cost numeric(10,2);
                        v_count int;
                        
                        v_one_price z5_project.price%TYPE;
                        v_start date;
                        v_end date;
                    BEGIN
                        SELECT sum(price), count(*)
                        INTO v_total_price, v_count
                        FROM z5_project
                        WHERE project_type = v_topic;
                        
                        RAISE NOTICE 'Тематика: %, Всего проектов: %, Общая стоимость: %', v_topic, v_count, v_total_price;

                        SELECT price, startdate, enddate INTO v_one_price, v_start, v_end
                        FROM z5_project WHERE project_type = v_topic LIMIT 1;
                        
                        IF v_one_price IS NOT NULL AND v_end > v_start THEN
                            v_day_cost := v_one_price / (v_end - v_start);
                            RAISE NOTICE 'Суточная стоимость (одного из проектов): %', v_day_cost;
                        ELSE
                            RAISE NOTICE 'Невозможно вычислить суточную стоимость (нет данных или даты равны)';
                        END IF;
                    END $$;

--         4.4. Управляющие операторы. Предусмотрите обработку исключений
--             4.4.1. (IF) Написать программу для изменения для нахождения корней квадратного уравнения, при этом значения переменных a, b, c. Предусмотрите проверку ввода только числовых значений. 
DO $$
                    DECLARE
                        a numeric := 1;
                        b numeric := -3;
                        c numeric := 2;
                        D numeric;
                        x1 numeric;
                        x2 numeric;
                    BEGIN
                        IF a = 0 THEN
                            RAISE EXCEPTION 'Коэффициент "a" не может быть равен 0';
                        END IF;

                        D := b*b - 4*a*c;
                        
                        RAISE NOTICE 'DEBUG: a=%, b=%, c=%, Дискриминант D=%', a, b, c, D;

                        IF D > 0 THEN
                            x1 := (-b + sqrt(D)) / (2*a);
                            x2 := (-b - sqrt(D)) / (2*a);
                            RAISE NOTICE 'Два корня: x1=%, x2=%', x1, x2;
                        ELSIF D = 0 THEN
                            x1 := -b / (2*a);
                            RAISE NOTICE 'Один корень: x1=%', x1;
                        ELSE
                            RAISE NOTICE 'Корней нет';
                        END IF;
                    EXCEPTION
                        WHEN OTHERS THEN
                            RAISE NOTICE 'Ошибка вычисления: %', SQLERRM;
                    END $$;

DO $$
                    DECLARE
                        summa_pr NUMERIC := 5500; -- Стоимость проекта
                        bonus NUMERIC(10, 2);
                    BEGIN
                        CASE
                            WHEN summa_pr > 10000 THEN
                                bonus := summa_pr * 0.70;
                            WHEN summa_pr >= 1000 AND summa_pr <= 10000 THEN
                                bonus := summa_pr * 0.30;
                            ELSE
                                bonus := 0;
                        END CASE;

                        RAISE NOTICE 'Сумма: %, Бонус: %', summa_pr, bonus;

                    EXCEPTION
                        WHEN OTHERS THEN
                            RAISE EXCEPTION 'Ошибка в 4.4.2: %', SQLERRM;
                    END $$;

--             4.4.3. (LOOP) Вычислите значение суммы ряда P = 1 + x + x2/2! + x3/3!+… Вычисление завершить, если ai < 0.0001
DO $$
                    DECLARE
                        x NUMERIC := 0.5;
                        p NUMERIC := 1.0;
                        i INT := 1;
                        a_i NUMERIC;
                        v_precision CONSTANT NUMERIC := 0.0001;
                    BEGIN
                        LOOP
                            a_i := POWER(x, i) / factorial(i);

                            IF ABS(a_i) < v_precision THEN
                                EXIT;
                            END IF;

                            p := p + a_i;
                            i := i + 1;
                        END LOOP;

                        RAISE NOTICE 'Сумма ряда P (x=%) с помощью LOOP до точности %: %', x, v_precision, p;

                    EXCEPTION
                        WHEN OTHERS THEN
                            RAISE EXCEPTION 'Ошибка в 4.4.3: %', SQLERRM;
                    END $$;

--             4.4.4. (WHILE) Вычислите значение суммы ряда с применением оператора while
DO $$
                    DECLARE
                        x NUMERIC := 0.5; 
                        p DECIMAL(10,5) := 1.0;
                        i INT := 1;
                        a_i NUMERIC := 1.0;
                        v_precision CONSTANT NUMERIC := 0.0001;
                    BEGIN
                        WHILE ABS(a_i) >= v_precision OR i = 1 LOOP
                            a_i := POWER(x, i) / factorial(i);

                            IF ABS(a_i) < v_precision THEN
                                EXIT;
                            END IF;

                            p := p + a_i;
                            i := i + 1;
                        END LOOP;

                        RAISE NOTICE 'Сумма ряда P (x=%) с помощью WHILE: %', x, p;

                    EXCEPTION
                        WHEN OTHERS THEN
                            RAISE EXCEPTION 'Ошибка в 4.4.4: %', SQLERRM;
                    END $$;

--             4.4.5. (FOR) Определите последовательность из трёх дат с максимальным проектов в течение 20 дней, начиная с даты 01.10.2025
DO $$
                    DECLARE
                        v_start_range DATE := '2025-10-01';
                        v_end_range DATE := '2025-10-20';
                        v_max_count INT := -1;
                        v_best_date DATE;
                        r RECORD;
                    BEGIN
                        RAISE NOTICE 'Поиск лучшей последовательности из 3-х дат в диапазоне с % по %', v_start_range, v_end_range;

                        FOR r IN
                            SELECT
                                d.dt AS date1,
                                (d.dt + INTERVAL '1 day')::DATE AS date2,
                                (d.dt + INTERVAL '2 days')::DATE AS date3,
                                (
                                    SELECT COUNT(*) FROM z5_project WHERE startdate = d.dt
                                ) + (
                                    SELECT COUNT(*) FROM z5_project WHERE startdate = (d.dt + INTERVAL '1 day')::DATE
                                ) + (
                                    SELECT COUNT(*) FROM z5_project WHERE startdate = (d.dt + INTERVAL '2 days')::DATE
                                ) AS total_count
                            FROM generate_series(v_start_range, v_end_range, '1 day'::interval) d(dt)
                            WHERE (d.dt + INTERVAL '2 days')::DATE <= v_end_range -- Убеждаемся, что последовательность не выходит за диапазон
                            ORDER BY total_count DESC, date1 ASC
                            LIMIT 1
                        LOOP
                            v_max_count := r.total_count;
                            v_best_date := r.date1;
                        END LOOP;

                        IF v_max_count > 0 THEN
                            RAISE NOTICE 'Лучшая последовательность: %, %, %. Количество проектов: %',
                                v_best_date, (v_best_date + INTERVAL '1 day')::DATE, (v_best_date + INTERVAL '2 days')::DATE, v_max_count;
                        ELSE
                            RAISE NOTICE 'Проекты в заданный период не найдены.';
                        END IF;

                    EXCEPTION
                        WHEN OTHERS THEN
                            RAISE EXCEPTION 'Ошибка в 4.4.5: %', SQLERRM;
                    END $$;

--             4.4.6. (Вложенные циклы) Выведите количество реализованных проектов за каждый месяц 2024-2025 годов.
DO $$
                    DECLARE
                        v_year INT;
                        v_month INT;
                        v_count BIGINT;
                    BEGIN
                        RAISE NOTICE 'Количество реализованных проектов за каждый месяц 2024-2025 годов:';

                        FOR v_year IN 2024..2025 LOOP
                            FOR v_month IN 1..12 LOOP
                                SELECT COUNT(*)
                                INTO v_count
                                FROM z5_project
                                WHERE EXTRACT(YEAR FROM enddate) = v_year
                                AND EXTRACT(MONTH FROM enddate)= v_month;

                                IF v_count > 0 THEN
                                    RAISE NOTICE '  Год: %, Месяц: %, Количество: %', v_year, v_month, v_count;
                                END IF;
                            END LOOP;
                        END LOOP;

                    EXCEPTION
                        WHEN OTHERS THEN
                            RAISE EXCEPTION 'Ошибка в 4.4.6: %', SQLERRM;
                    END $$;

--         4.5. Обработка ошибок
--             4.5.1. Напишите программу, в которой произведите удаление ментора, при этом предусмотрите, если есть ссылка на него выведите текстовое сообщение – Удаление невозможно, удалите сначала подчинённые записи.
DO $$
                    DECLARE
                        v_mentor_id_linked INT := 1; -- ID ментора, связанного с проектами
                    BEGIN
                        RAISE NOTICE 'Попытка удаления ментора с ID: %', v_mentor_id_linked;

                        DELETE FROM z5_mentor WHERE id = v_mentor_id_linked;
                        RAISE NOTICE 'Ментор успешно удален.';

                    EXCEPTION
                        WHEN foreign_key_violation THEN
                            RAISE NOTICE 'Удаление невозможно, удалите сначала подчинённые записи (проекты).';
                        WHEN NO_DATA_FOUND THEN
                            RAISE NOTICE 'Ментор с ID % не найден.', v_mentor_id_linked;
                        WHEN OTHERS THEN
                            RAISE EXCEPTION 'Непредвиденная ошибка при удалении: %', SQLERRM;
                    END $$;

--             4.5.2. Напишите программу, в которой введите данные о проекте, предусмотрите проверку, что ввода данных не нарушит ссылочную целостность.
DO $$
                    DECLARE
                        v_mentor_id_check INT := 999;
                        v_title_new TEXT := 'Новый тестовый проект';
                    BEGIN
                        RAISE NOTICE 'Попытка вставки проекта с mentor_id: %', v_mentor_id_check;
                        
                        PERFORM 1 FROM z5_mentor WHERE id = v_mentor_id_check;
                        IF NOT FOUND THEN
                            RAISE EXCEPTION 'Нарушение ссылочной целостности: Ментор с ID % не существует.', v_mentor_id_check;
                        END IF;

                        INSERT INTO z5_project (id, title, cost)
                        VALUES (v_mentor_id_check, v_title_new, 1000);

                        RAISE NOTICE 'Проект успешно добавлен.';

                    EXCEPTION
                        WHEN SQLSTATE '23503' THEN
                            RAISE NOTICE 'Ошибка: Нарушение ссылочной целостности при вставке.';
                        WHEN OTHERS THEN
                            RAISE NOTICE 'Обработка ошибки: %', SQLERRM;
                    END $$;

--             4.5.3. Напишите код, вызывающий любую ошибку по вашему усмотрению. Выведите информацию об ошибке с помощью GET STACKED DIAGNOSTICS.
DO $$
                    DECLARE
                        v_denominator INT := 0;
                        v_result INT;
                        v_error_msg TEXT;
                        v_detail TEXT;
                        v_hint TEXT;
                        v_context TEXT;
                    BEGIN
                        v_result := 10 / v_denominator;

                    EXCEPTION
                        WHEN division_by_zero THEN
                            GET STACKED DIAGNOSTICS
                                v_error_msg = MESSAGE_TEXT,
                                v_detail = PG_EXCEPTION_DETAIL,
                                v_hint = PG_EXCEPTION_HINT,
                                v_context = PG_EXCEPTION_CONTEXT;

                            RAISE NOTICE '--- Вызвана ошибка: Деление на ноль ---';
                            RAISE NOTICE 'Сообщение: %', v_error_msg;
                            RAISE NOTICE 'Подробности: %', COALESCE(v_detail, 'Нет подробностей');
                            RAISE NOTICE 'Подсказка: %', COALESCE(v_hint, 'Нет подсказки');
                            RAISE NOTICE 'Контекст: %', v_context;
                    END $$;

--             4.5.4. Реализуйте создание и обработку собственного исключения.
DO $$
                    DECLARE
                        v_project_cost NUMERIC := 500;
                        v_min_cost CONSTANT NUMERIC := 1000;
                        PROJECT_COST_TOO_LOW CONSTANT TEXT := 'U4504'; 
                    BEGIN
                        RAISE NOTICE 'Проверка стоимости проекта: %', v_project_cost;

                        IF v_project_cost < v_min_cost THEN
                            RAISE EXCEPTION 'Стоимость проекта (% руб.) слишком низка. Минимально: % руб.', v_project_cost, v_min_cost
                            USING HINT = 'Увеличьте стоимость проекта до ' || v_min_cost || ' руб. или выше.',
                                ERRCODE = PROJECT_COST_TOO_LOW;
                        END IF;

                        RAISE NOTICE 'Проект принят (стоимость достаточна).';

                    EXCEPTION
                        WHEN SQLSTATE 'U4504' THEN
                            RAISE NOTICE '--- ОБРАБОТКА СОБСТВЕННОГО ИСКЛЮЧЕНИЯ ---';
                            RAISE NOTICE 'Ошибка: %', SQLERRM;
                            RAISE NOTICE 'Действие: %', PG_EXCEPTION_HINT;
                        WHEN OTHERS THEN
                            RAISE EXCEPTION 'Непредвиденная ошибка: %', SQLERRM;
                    END $$;

--         4.6. PL/pgSQL с применением курсоров
--             4.6.1. (неявные курсоры) Создайте переменную – запись, которая включает информацию об менторе и его количестве команд. В данную переменную получите ментора, который работает с наибольшим количеством команд, если таких менторов несколько, то предусмотрите вывод нескольких строк. Выведите на экран его фамилию и данное количество.
DO $$
                    DECLARE
                        v_max_teams INT;
                        r_mentor RECORD;
                    BEGIN
                        SELECT COALESCE(MAX(team_count), 0)
                        INTO v_max_teams
                        FROM (
                            SELECT m.id, COUNT(DISTINCT c.id) AS team_count
                            FROM z5_mentor m
                            LEFT JOIN z5_project p ON m.id = p.mentor_id
                            LEFT JOIN z5_command c ON p.idcommand = c.id
                            GROUP BY m.id
                        ) AS sub;

                        RAISE NOTICE 'Максимальное количество команд: %', v_max_teams;

                        FOR r_mentor IN
                            SELECT m.lastname, COUNT(DISTINCT c.id) AS team_count
                            FROM z5_mentor m
                            LEFT JOIN z5_project p ON m.id = p.mentor_id
                            LEFT JOIN z5_command c ON p.idcommand = c.id
                            GROUP BY m.id, m.lastname
                            HAVING COUNT(DISTINCT c.id) = v_max_teams
                        LOOP
                            RAISE NOTICE '  - Фамилия ментора: %, Количество команд: %', r_mentor.lastname, r_mentor.team_count;
                        END LOOP;

                    EXCEPTION
                        WHEN OTHERS THEN
                            RAISE NOTICE 'Ошибка: %', SQLERRM;
                    END $$;

--             4.6.2. (выбор в переменную %TYPE) Напишите программу, в которой опишете переменную temp и получите значение ещё не закрытых проектов на текущий день. 
DO $$
                    DECLARE
                        v_project_title z5_project.projectname%TYPE;
                        v_unclosed_projects INT;
                    BEGIN
                        SELECT COUNT(*)
                        INTO v_unclosed_projects
                        FROM z5_project
                        WHERE enddate IS NULL OR enddate > CURRENT_DATE;

                        RAISE NOTICE 'Количество еще не закрытых проектов на текущий день: %', v_unclosed_projects;

                        SELECT projectname INTO v_project_title
                        FROM z5_project
                        WHERE enddate IS NULL OR enddate > CURRENT_DATE
                        LIMIT 1;

                        IF FOUND THEN
                            RAISE NOTICE 'Пример названия одного из незакрытых проектов: %', v_project_title;
                        END IF;

                    EXCEPTION
                        WHEN OTHERS THEN
                            RAISE EXCEPTION 'Ошибка в 4.6.2: %', SQLERRM;
                    END $$;

--             4.6.3. (выбор в запись %ROWTYPE) Напишите программу для получения списка проектов, которые были реализованы в указанный период.
DO $$
                    DECLARE
                        v_start_period DATE := '2024-01-01';
                        v_end_period DATE := '2024-12-31';
                        r_project z5_project%ROWTYPE;
                    BEGIN
                        RAISE NOTICE 'Список проектов, реализованных в период с % по %:', v_start_period, v_end_period;

                        FOR r_project IN
                            SELECT *
                            FROM z5_project
                            WHERE startdate >= v_start_period AND enddate <= v_end_period
                            ORDER BY startdate
                        LOOP
                            RAISE NOTICE '  - Шифр: %, Название: %, Дата начала: %',
                                r_project.shifr, r_project.projectname, r_project.startdate;
                        END LOOP;

                        IF NOT FOUND THEN
                            RAISE NOTICE '  -- Проекты в указанный период не найдены.';
                        END IF;

                    EXCEPTION
                        WHEN OTHERS THEN
                            RAISE EXCEPTION 'Ошибка в 4.6.3: %', SQLERRM;
                    END $$;

--             4.6.4. (явные курсоры – используем for) Создайте переменную st, которая ссылается на запись из таблицы student. В данную переменную получите список студентов, участвовал / участвует в наибольшем количестве проектов. Выведите на экран данную информацию с применением цикла.
DO $$
                    DECLARE
                        r_student RECORD;
                        v_max_projects INT;
                    BEGIN
                        SELECT COALESCE(MAX(project_count), 0)
                        INTO v_max_projects
                        FROM (
                            SELECT s.id, COUNT(p.id) AS project_count
                            FROM z5_student s
                            JOIN z5_project p ON s.idcommand = p.idcommand
                            GROUP BY s.id
                        ) AS sub;

                        RAISE NOTICE 'Максимальное количество проектов у студента: %', v_max_projects;

                        FOR r_student IN
                            SELECT s.lastname, s.firstname, COUNT(p.id) AS project_count
                            FROM z5_student s
                            JOIN z5_project p ON s.idcommand = p.idcommand
                            GROUP BY s.id, s.lastname, s.firstname
                            HAVING COUNT(p.id) = v_max_projects
                        LOOP
                            RAISE NOTICE '  - Студент: % %, Количество проектов: %',
                                r_student.lastname, r_student.firstname, r_student.project_count;
                        END LOOP;

                    EXCEPTION
                        WHEN OTHERS THEN
                            RAISE NOTICE 'Ошибка: %', SQLERRM;
                    END $$;

--             4.6.5. (курсор с параметрами) Напишите программу, которая бы находила список проектов, стоимость которых находится в диапазоне от a до b.
DO $$
                    DECLARE
                        v_min_price NUMERIC := 5000;
                        v_max_price NUMERIC := 15000;
                        r_project z5_project%ROWTYPE;
                    BEGIN
                        RAISE NOTICE 'Проекты, стоимость которых находится в диапазоне от % до %:', v_min_price, v_max_price;

                        FOR r_project IN
                            SELECT *
                            FROM z5_project
                            WHERE price BETWEEN v_min_price AND v_max_price
                            ORDER BY price DESC
                        LOOP
                            RAISE NOTICE '  - Название: %, Стоимость: % руб.', r_project.projectname, r_project.price;
                        END LOOP;

                    EXCEPTION
                        WHEN OTHERS THEN
                            RAISE EXCEPTION 'Ошибка в 4.6.5: %', SQLERRM;
                    END $$;