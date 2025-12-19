--         3.1. Изучение материалов курса 
--             3.1.1. Откройте материал базового курса по администрированию https://postgrespro.ru/education/ и подготовьте электронные ответы на вопросы с приведением примеров (при возможности с демонстрацией работы)
--                 • Базовый курс
--                     TODO: ◦ Конфигурирование сервера
-- Основные файлы:
-- postgresql.conf: Главный файл конфигурации (память, воркеры, логирование).
-- pg_hba.conf: Host Based Authentication — правила доступа (кто, откуда, к какой БД).
-- pg_ident.conf: Маппинг системных пользователей в пользователей БД.
-- Уровни применения настроек:
-- System-wide (файл).
-- Per Database (ALTER DATABASE).
-- Per User (ALTER ROLE).
-- Per Session (SET).
-- Применение изменений: Некоторые параметры требуют рестарта сервера (shared_buffers), другие — только перечитывания конфигурации (SIGHUP / pg_reload_conf()).
--                     TODO: ◦ Архитектура
-- Процессная модель: Postgres использует процессы, а не потоки.
-- Postmaster: Главный процесс, запускает остальные, слушает порт.
-- Backend processes: На каждое соединение клиента создается отдельный процесс postgres.
-- Background workers: Фоновые процессы (Checkpointer, BgWriter, WalWriter, Autovacuum Launcher).
-- Память:
-- Shared Buffers: Общая память для всех процессов (кэш страниц данных).
-- WAL Buffers: Буфер журнала предзаписи.
-- Local Memory: Память каждого процесса (work_mem для сортировок/хешей, temp_buffers).
--                     TODO: ◦ Организация данных
-- Иерархия: Instance (Кластер) → Database → Schema → Table/Index/View.
-- Физический уровень:
-- $PGDATA: Директория, где лежит всё.
-- Tablespaces: Возможность хранить объекты БД на разных дисках/путях.
-- Pages (Blocks): Данные хранятся страницами (по умолчанию 8kb).
-- TOAST: Механизм хранения больших полей (длиннее страницы) в отдельных файлах ("нарезка").
-- Heap: Куча — стандартный способ хранения строк таблицы (неупорядоченно).
--                     TODO: ◦ Мониторинг
-- Системные представления (System Views):
-- pg_stat_activity: Кто подключен, какие запросы выполняются прямо сейчас.
-- pg_stat_database: Статистика по базам (кол-во транзакций, hit ratio кэша).
-- pg_stat_bgwriter: Работа фоновых процессов записи.
-- Расширения: pg_stat_statements — стандарт де-факто для анализа самых "тяжелых" запросов (по времени, CPU, IO).
-- Уровень ОС: Мониторинг CPU, Disk I/O, RAM, Load Average. Postgres сильно зависит от файлового кэша ОС.
--                     TODO: ◦ Управление доступом
-- Аутентификация (Authentication): Проверка личности. Настраивается в pg_hba.conf. Методы: md5/scram-sha-256 (пароль), peer (локальный пользователь ОС), trust, cert.
-- Авторизация (Authorization): Проверка прав.
-- Roles: В Postgres понятия "пользователь" и "группа" объединены в "Роль".
-- Атрибуты: LOGIN, SUPERUSER, CREATEDB, REPLICATION.
-- Привилегии: Команды GRANT / REVOKE. Уровни: БД, схема, таблица, колонка.
-- RLS (Row-Level Security): Политики доступа к конкретным строкам таблицы на основе условий.
--                     TODO: ◦ Резервное копирование
-- Логическое (Logical):
-- pg_dump / pg_dumpall. Создает SQL-скрипт для воссоздания данных.
-- Плюсы: переносимость между версиями/ОС, выборочность. Минусы: медленное восстановление больших баз.
-- Физическое (Physical):
-- pg_basebackup. Побитовая копия файлов базы данных.
-- PITR (Point-In-Time Recovery): Восстановление на любой момент времени. Требует наличия базового бэкапа и архива WAL-файлов (Write-Ahead Log).
--                     TODO: ◦ Репликация
-- Физическая (Streaming Replication):
-- Передача WAL-записей с Primary на Standby.
-- Standby является точной копией Primary (read-only).
-- Может быть синхронной (гарантия записи на реплику) и асинхронной.
-- Логическая (Logical Replication):
-- Модель Publisher/Subscriber.
-- Позволяет реплицировать отдельные таблицы.
-- Работает между разными мажорными версиями и даже ОС.
-- Replication Slots: Механизм на мастере, гарантирующий, что нужные WAL-файлы не удалятся, пока их не заберет реплика.
--                     TODO:◦ Настройка и мониторинг сервера баз данных
-- Ключевые параметры памяти:
-- shared_buffers: ~25-40% RAM.
-- work_mem: Память на операцию (сортировка, хеш). Осторожно, умножается на кол-во соединений!
-- maintenance_work_mem: Память для служебных задач (VACUUM, CREATE INDEX).
-- effective_cache_size: Подсказка планировщику о том, сколько памяти доступно в кэше ОС.
-- Чекпоинты (Checkpoints): Процесс сброса грязных страниц из памяти на диск. Настройка max_wal_size и checkpoint_completion_target критична для плавности I/O.
-- Планировщик (Query Planner): Использует статистику (ANALYZE) для построения плана выполнения. EXPLAIN (ANALYZE) — главный инструмент отладки запросов.
--                     TODO: ◦ Журналирование
-- Куда писать: log_destination (stderr, csvlog, syslog). csvlog удобен для парсинга.
-- Что писать:
-- log_min_duration_statement: Логирование запросов, выполняющихся дольше N мс (поиск медленных запросов).
-- log_checkpoints: Обязательно для диагностики проблем с записью.
-- log_lock_waits: Отслеживание ожиданий блокировок.
-- log_temp_files: Отслеживание сброса временных данных на диск (нехватка work_mem)
--                     TODO: ◦ Блокировки
-- MVCC (Multi-Version Concurrency Control):
-- Главный тезис: "Писатели не блокируют читателей, читатели не блокируют писателей".
-- Каждая транзакция видит согласованный снимок данных на момент начала.
-- Виды блокировок:
-- Table-level (например, при ALTER TABLE или VACUUM FULL).
-- Row-level (при UPDATE, DELETE, SELECT FOR UPDATE).
-- Advisory locks (прикладные блокировки, управляемые пользователем).
-- Deadlocks: Взаимные блокировки. Postgres автоматически обнаруживает их и разрывает одну из транзакций.
--                    TODO: ◦ Задачи администрирования
-- VACUUM (Очистка):
-- Удаление "мертвых" кортежей (старых версий строк после update/delete), чтобы освободить место для новых данных.
-- Autovacuum: Должен быть включен всегда. Требует тонкой настройки на нагруженных системах.
-- Transaction ID Wraparound: Критическая проблема. Если VACUUM FREEZE не выполняется вовремя, база может остановиться для защиты данных (счетчик транзакций 32-битный).
-- Индексы:
-- Периодический REINDEX (если индекс распух) или пересоздание через CREATE INDEX CONCURRENTLY (без блокировки таблицы).
-- Обновление версий:
-- Minor (14.1 -> 14.2): Просто замена бинарников.
-- Major (13 -> 14): Требует pg_dump/restore или pg_upgrade.
set
    search_path = 'bookings';

--                 3.2. Работа с базой данных Авиаперевозок
--             3.2.1. Сравнение двух схем (Postgres Pro Standard : Документация: 18: Приложение M. Демонстрационная база данных «Авиаперевозки» : Компания Postgres Professional) – почитайте документацию. Изучите две схемы бд demo и demo2, опишите найденные вами различия.
-- demo1
--                   Schema  |         Name          |   Type   | Owner 
-- ----------+-----------------------+----------+-------
--  bookings | aircrafts             | view     | demo
--  bookings | aircrafts_data        | table    | demo
--  bookings | airports              | view     | demo
--  bookings | airports_data         | table    | demo
--  bookings | boarding_passes       | table    | demo
--  bookings | bookings              | table    | demo
--  bookings | flights               | table    | demo
--  bookings | flights_flight_id_seq | sequence | demo
--  bookings | flights_v             | view     | demo
--  bookings | routes                | view     | demo
--  bookings | seats                 | table    | demo
--  bookings | ticket_flights        | table    | demo
--  bookings | tickets               | table    | demo
-- demo2
--   Schema  |         Name          |   Type   | Owner 
-- ----------+-----------------------+----------+-------
--  bookings | airplanes             | view     | demo
--  bookings | airplanes_data        | table    | demo
--  bookings | airports              | view     | demo
--  bookings | airports_data         | table    | demo
--  bookings | boarding_passes       | table    | demo
--  bookings | bookings              | table    | demo
--  bookings | flights               | table    | demo
--  bookings | flights_flight_id_seq | sequence | demo
--  bookings | routes                | table    | demo
--  bookings | seats                 | table    | demo
--  bookings | segments              | table    | demo
--  bookings | tickets               | table    | demo
--  bookings | timetable             | view     | demo
-- 1. Переименование сущностей (Самолеты)
-- В первой схеме Aircrafts, во второй — Airplanes
-- demo: aircrafts (view), aircrafts_data (table)
-- demo2: airplanes (view), airplanes_data (table)
-- 2. Изменение структуры связей билетов и рейсов
-- demo: ticket_flights (table)
-- demo2: segments (table)
-- 3. Изменение типа объекта routes
-- demo: routes — view
-- demo2: routes — table
-- 4. Изменение представлений для рейсов
-- demo: Присутствует flights_v
-- demo2: flights_v отсутствует, но есть timetable
--           3.2.2. Выполнение запросов к данным базы данных demo (по вариантам – ваш вариант номер в списке рейтинга -12, если номер больше 12):
--             3.2.2.1 Рейсы с наибольшим количеством пассажиров в определенный день
SELECT
    f.flight_no,
    f.scheduled_departure,
    a.model,
    COUNT(tf.ticket_no) AS passenger_count
FROM
    bookings.flights f
    JOIN bookings.ticket_flights tf ON f.flight_id = tf.flight_id
    JOIN bookings.aircrafts a ON f.aircraft_code = a.aircraft_code
WHERE
    f.scheduled_departure::date = '2017-09-10'
GROUP BY
    f.flight_id,
    f.flight_no,
    f.scheduled_departure,
    a.model
ORDER BY
    passenger_count DESC
LIMIT
    10;

-- Planning Time: 0.419 ms
-- Execution Time: 2937.667 ms
-- (24 rows)
CREATE INDEX IF NOT EXISTS idx_flights_scheduled_departure ON bookings.flights ();

WITH
    target_flights AS (
        SELECT
            flight_id,
            flight_no,
            scheduled_departure,
            aircraft_code
        FROM
            bookings.flights
        WHERE
            scheduled_departure >= '2017-09-10'
            AND scheduled_departure < '2017-09-11'
    )
SELECT
    f.flight_no,
    f.scheduled_departure,
    a.model,
    COUNT(tf.ticket_no) AS passenger_count
FROM
    target_flights f
    JOIN bookings.ticket_flights tf ON f.flight_id = tf.flight_id
    JOIN bookings.aircrafts a ON f.aircraft_code = a.aircraft_code
GROUP BY
    f.flight_id,
    f.flight_no,
    f.scheduled_departure,
    a.model
ORDER BY
    passenger_count DESC
LIMIT
    10;

-- Planning Time: 0.378 ms
-- Execution Time: 3155.251 ms
-- (24 rows)
--             3.2.2.2 Количество пассажиров, перевезенных каждым из самолетов
SELECT
    a.model,
    COUNT(tf.ticket_no) AS total_passengers_transported
FROM
    bookings.aircrafts a
    JOIN bookings.flights f ON a.aircraft_code = f.aircraft_code
    JOIN bookings.ticket_flights tf ON f.flight_id = tf.flight_id
WHERE
    f.status = 'Arrived'
GROUP BY
    a.aircraft_code,
    a.model
ORDER BY
    total_passengers_transported DESC;

-- Planning Time: 0.382 ms
-- Execution Time: 20654.471 ms
CREATE MATERIALIZED VIEW
    bookings.aircraft_stats_mv AS
SELECT
    a.model,
    COUNT(tf.ticket_no) AS total_passengers_transported
FROM
    bookings.aircrafts a
    JOIN bookings.flights f ON a.aircraft_code = f.aircraft_code
    JOIN bookings.ticket_flights tf ON f.flight_id = tf.flight_id
WHERE
    f.status = 'Arrived'
GROUP BY
    a.aircraft_code,
    a.model;

CREATE INDEX ON bookings.aircraft_stats_mv (model);

REFRESH MATERIALIZED VIEW bookings.aircraft_stats_mv;

-- Разрешить использовать больше памяти для хеш-таблиц при джойнах
SET
    work_mem = '64MB';

-- Разрешить параллельное выполнение запроса (задействовать несколько ядер)
SET
    max_parallel_workers_per_gather = 4;

--                     3.2.3. Для запросов написать план запроса, найти статистику выполнения: время выполнения, количество обработанных строк для каждого шага. Привести значения статистики данных для таблиц и индексов участвующих в запросе.
-- Если индексы, которые созданы для столбцов таблиц, участвующих в запросе, не используются, объяснить, почему они не используются.
EXPLAIN (
    ANALYZE,
    BUFFERS,
    TIMING
)
SELECT
    f.flight_no,
    f.scheduled_departure,
    a.model,
    COUNT(tf.ticket_no) AS passenger_count
FROM
    bookings.flights f
    JOIN bookings.ticket_flights tf ON f.flight_id = tf.flight_id
    JOIN bookings.aircrafts a ON f.aircraft_code = a.aircraft_code
WHERE
    f.scheduled_departure >= '2017-09-10 00:00:00'
    AND f.scheduled_departure < '2017-09-11 00:00:00'
GROUP BY
    f.flight_id,
    f.flight_no,
    f.scheduled_departure,
    a.model
ORDER BY
    passenger_count DESC
LIMIT
    10;

-- Planning Time: 1.339 ms
-- Execution Time: 2958.641 ms
-- Основная проблема: Чтение таблицы ticket_flights (Seq Scan)
-- Шаг 1: Фильтрация рейсов (Seq Scan on flights f)
-- Время: 17.4 ms
-- Обработано: 214 867 строк, из них отброшено фильтром 214 310, оставлено 557
-- Буферы: shared hit=2688 (все данные были в оперативной памяти, диск не трогал)
-- Шаг 2: Чтение билетов (Seq Scan on ticket_flights tf) — BOTTLENECK
-- Время: 1970.6 ms
-- Строки: Прочитано 8 391 852 строк
-- Буферы: read=70087 (Чтение с диска). База вычитывала ~560 МБ данных с жесткого диска, так как их не было в кэше
-- Шаг 3: Соединение (Hash Join) соединяет 557 рейсов с 8.4 млн строк билетов
-- Время: Накапливает время до 2926 ms.
-- Строки: На выходе получено 5 433 записи (билеты на 557 рейсов)
-- Шаг 4: Подтягивание самолетов (Index Scan ... aircrafts_data) для каждой строки узнает модель самолета
-- Метод: Memoize (Кэширование)
-- Эффективность: Hits: 5425 (взято из памяти), Misses: 8
-- Count:
-- ticket_flights: ~8 391 852
-- flights: ~214 867
-- ticket_flights:
-- Отсутствие подходящего индекса: Соединение таблицы по полю flight_id, а в базе индекс:
-- Indexes: "ticket_flights_pkey" PRIMARY KEY, btree (ticket_no, flight_id)
-- Решение:
-- CREATE INDEX ON bookings.ticket_flights(flight_id);
-- Правило B-Tree: Индексы работают слева направо. Если flight_id стоит на втором месте в индексе, база не может эффективно использовать его для поиска только по flight_id.
-- flights:
-- Селективность: База нашла 557 строк из 214 000. ~0.25% данных - очень хорошая селективность для использования индекса. Отсутсвие индекса.
-- Indexes: "flights_pkey" PRIMARY KEY, btree (flight_id) "flights_flight_no_scheduled_departure_key" UNIQUE CONSTRAINT, btree (flight_no, scheduled_departure)
-- CREATE INDEX ON bookings.flights(scheduled_departure);
EXPLAIN (
    ANALYZE,
    BUFFERS,
    TIMING
)
SELECT
    a.model,
    COUNT(tf.ticket_no) AS total_passengers_transported
FROM
    bookings.aircrafts a
    JOIN bookings.flights f ON a.aircraft_code = f.aircraft_code
    JOIN bookings.ticket_flights tf ON f.flight_id = tf.flight_id
WHERE
    f.status = 'Arrived'
GROUP BY
    a.aircraft_code,
    a.model
ORDER BY
    total_passengers_transported DESC;

-- Planning Time: 0.329 ms
-- Execution Time: 20469.818 ms
-- Шаг 1: Фильтрация рейсов (Seq Scan on flights f)
-- Время: 42.3 ms
-- Количество строк: из 198 802 строк отобрано 198 430
-- Вывод: Практически все рейсы имеют статус 'Arrived' (отброшено  16 тысяч)
-- Шаг 2: Чтение билетов (Seq Scan on ticket_flights tf) - Полное чтение самой большой таблицы
-- Время: 1703.9 ms
-- Количество строк: Обработано 8 391 852
-- Шаг 3: Первое соединение (Hash Join) — Bottleneck №1
-- Действие: Соединяет рейсы flights с ticket_flights
-- Время: Скачок с 1703 ms до 5 702 ms
-- Количество строк: Получено 7 920 956 строк
-- Проблема: Temp written=20750. Хэш-таблица для соединения оказалась слишком большой для выделенной памяти (Memory). Postgres был вынужден писать данные на диск (Swapping)
-- Шаг 4: Второе соединение (Hash Join) — Bottleneck №2
-- Действие: К 8 миллионам строк присоединяет название самолета из aircrafts_data
-- Время: Скачок с 5702 ms до 17 734 ms (заняло 12 секунд!)
-- Проблема: Опять Temp read/written. База данных прогоняет 8 млн строк через диск, чтобы просто добавить название модели самолета к каждой строке
-- Шаг 5: Группировка (HashAggregate)
-- Действие: Схлопывает 8 млн строк в 8 итоговых строк
-- Время: Заняло еще ~3 секунды
-- Count:
-- ticket_flights: ~8 391 852
-- flights: ~198 430
-- Промежуточный результат: ~7 920 956 строк
-- flights(status)
-- Причина: Фильтрация по status = 'Arrived', а этому условию удовлетворяют 198 430 из 214 000 строк
-- Seq Scan: Читать индекс имеет смысл, если нужно найти 1-5% строк. Если нужно прочитать 92%, быстрее сделать Seq Scan, чем бегать по индексу
-- ticket_flights(flight_id)
-- Причина: Так как мы отобрали 92% рейсов, нам нужно найти билеты для этих же 92% рейсов.
-- Seq Scan: Это означает, что нам все равно придется прочитать почти всю таблицу ticket_flights (та же история)
-- Истинная причина тормозов не в отсутствии индексов, а в архитектуре запроса и настройках памяти
-- SET work_mem = '128MB', запрос выполнился бы в 2-3 раза быстрее, но все равно остался бы тяжелым
-- Скорее всего поможет только Materialized View
--         3.3. Предварительный анализ данных (база данных demo2)
--             3.3.1. Работа со системными представлениями. 
--                 • Выведите список 10 самых крупных таблиц схемы bookings с указанием их приблизительного размера (в строках).
SELECT
    c.relname AS table_name,
    c.reltuples::bigint AS approximate_row_count
FROM
    pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE
    n.nspname = 'bookings'
    AND c.relkind = 'r'
ORDER BY
    c.reltuples DESC
LIMIT
    10;

--   table_name    | approximate_row_count 
-- -----------------+-----------------------
-- segments        |              27580256
-- boarding_passes |              26298992
-- tickets         |              21095264
-- bookings        |               9706657
-- flights         |                135571
-- routes          |                  7242
-- airports_data   |                  5501
-- seats           |                  1741
-- airplanes_data  |                    10
-- (9 rows)
--             3.3.2. Профилирование данных 
--                 • Постройте распределение количества рейсов (flights) по их статусам (status). Сделайте вывод о доле отмененных и задержанных рейсов.
SELECT
    status,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM
    bookings.flights
GROUP BY
    status
ORDER BY
    count DESC;

--  status   | count  | percentage 
-- -----------+--------+------------
-- Arrived   | 124095 |      91.54
-- Scheduled |  10565 |       7.79
-- Cancelled |    702 |       0.52
-- On Time   |    173 |       0.13
-- Departed  |     21 |       0.02
-- Delayed   |     10 |       0.01
-- Boarding  |      5 |       0.00
-- (7 rows)
--                 • Найдите дубликаты в данных пассажиров (tickets), где совпадает passenger_id, но различается passenger_name. Является ли это ошибкой данных?
SELECT
    passenger_id,
    ARRAY_AGG(DISTINCT passenger_name) AS names_found,
    COUNT(DISTINCT passenger_name) AS distinct_name_count
FROM
    bookings.tickets
GROUP BY
    passenger_id
HAVING
    COUNT(DISTINCT passenger_name) > 1;

-- passenger_id | names_found | distinct_name_count 
-- --------------+-------------+---------------------
-- (0 rows)
-- Думаю это не ошибка данных. Поле passenger_id в этой базе представляет собой номер паспорта. Папорт уникален и принадлежит одному человеку.
-- Коллизий быть не должно, только есл не человеческий фактор, но можно предусмотреть exception
--         3.4. Анализ временных рядов и визуализация полученных данных
--             3.4.1. Построить столбчатую диаграмму количества бронирований по дням недели за последнюю неделю
--                 • Напишем sql запрос для нахождения дня недели и количество бронирований за последнюю неделю с сортировкой по дате.
--                 • Построим график, отражающий полученные данные
SELECT
    b.book_date::date AS date,
    TO_CHAR(b.book_date, 'Day') AS day_of_week,
    COUNT(*) AS bookings_count
FROM
    bookings.bookings b
WHERE
    b.book_date >= bookings.now () - INTERVAL '7 days'
    AND b.book_date <= bookings.now ()
GROUP BY
    1,
    2
ORDER BY
    1;

--                         3.4.2. Динамика продаж
--                 • Постройте временной ряд общего объема выручки (total_amount) по дням за любые 3 месяца (относительно bookings.now()). Визуализируйте полученные данные.
SELECT
    b.book_date::date AS sale_date,
    SUM(b.total_amount) AS total_revenue
FROM
    bookings.bookings b
WHERE
    b.book_date >= bookings.now () - INTERVAL '3 months'
    AND b.book_date <= bookings.now ()
GROUP BY
    1
ORDER BY
    1;

--                 • Рассчитайте скользящее среднее выручки за 7 дней. Визуализируйте оба ряда на одном графике (запрос должен выдать данные для построения). Визуализируйте полученные данные.
WITH
    daily_sales AS (
        SELECT
            book_date::date AS sale_date,
            SUM(total_amount) AS daily_revenue
        FROM
            bookings.bookings
        WHERE
            book_date >= bookings.now () - INTERVAL '3 months'
            AND book_date <= bookings.now ()
        GROUP BY
            1
    )
SELECT
    sale_date,
    daily_revenue,
    ROUND(
        AVG(daily_revenue) OVER (
            ORDER BY
                sale_date ROWS BETWEEN 6 PRECEDING
                AND CURRENT ROW
        ),
        2
    ) AS moving_average_7d
FROM
    daily_sales
ORDER BY
    1;

--             3.4.3. Сезонность рейсов
--                 • Преобразуйте даты вылета из bookings.flights.scheduled_departure в день недели и час. Постройте гистограмму количества вылетов по часам суток. Какие часы самые загруженные?
SELECT
    EXTRACT(
        HOUR
        FROM
            scheduled_departure
    ) AS hour_of_day,
    COUNT(*) AS flights_count
FROM
    bookings.flights
GROUP BY
    1
ORDER BY
    1;

--                 • Сравните общее количество вылетов в текущем месяце (декабрь 2025) с аналогичным месяцем в прошлом (ноябрь 2025). Используйте функцию LAG. Визуализируйте полученные данные.
WITH
    monthly_flights AS (
        SELECT
            DATE_TRUNC('month', scheduled_departure)::date AS flight_month,
            TO_CHAR(scheduled_departure, 'Month YYYY') AS month_name,
            COUNT(*) AS flights_total
        FROM
            bookings.flights
        WHERE
            scheduled_departure >= '2025-11-01'
            AND scheduled_departure < '2026-01-01'
        GROUP BY
            1,
            2
    )
SELECT
    month_name,
    flights_total AS current_month_flights,
    LAG(flights_total) OVER (
        ORDER BY
            flight_month
    ) AS previous_month_flights,
    flights_total - LAG(flights_total) OVER (
        ORDER BY
            flight_month
    ) AS difference,
    ROUND(
        (
            flights_total - LAG(flights_total) OVER (
                ORDER BY
                    flight_month
            )
        )::numeric / NULLIF(
            LAG(flights_total) OVER (
                ORDER BY
                    flight_month
            ),
            0
        ) * 100,
        2
    ) AS growth_percent
FROM
    monthly_flights
ORDER BY
    flight_month;

--   month_name   | current_month_flights | previous_month_flights | difference | growth_percent 
-- ----------------+-----------------------+------------------------+------------+----------------
-- November  2025 |                  5467 |                        |            |               
-- December  2025 |                  5539 |                   5467 |         72 |           1.32
--                                 • Рассчитайте процентное изменение (MoM - Month over Month) количества бронирований за последние доступные месяца, используя LAG() и ROUND() для точности.
WITH
    monthly_stats AS (
        SELECT
            DATE_TRUNC('month', book_date)::date AS month_start,
            TO_CHAR(book_date, 'Month YYYY') AS month_name,
            COUNT(*) AS bookings_count
        FROM
            bookings.bookings
        WHERE
            book_date <= bookings.now ()
        GROUP BY
            1,
            2
    )
SELECT
    month_name,
    bookings_count,
    LAG(bookings_count) OVER (
        ORDER BY
            month_start
    ) AS prev_month_count,
    ROUND(
        (
            bookings_count - LAG(bookings_count) OVER (
                ORDER BY
                    month_start
            )
        )::numeric / NULLIF(
            LAG(bookings_count) OVER (
                ORDER BY
                    month_start
            ),
            0
        ) * 100,
        2
    ) AS mom_percentage
FROM
    monthly_stats
ORDER BY
    month_start DESC
LIMIT
    6;

--   month_name   | bookings_count | prev_month_count | mom_percentage 
-- ----------------+----------------+------------------+----------------
-- August    2027 |         402180 |           396675 |           1.39
-- July      2027 |         396675 |           397993 |          -0.33
-- June      2027 |         397993 |           412620 |          -3.54
-- May       2027 |         412620 |           395857 |           4.23
-- April     2027 |         395857 |           411179 |          -3.73
-- March     2027 |         411179 |           371624 |          10.64
--         3.5. Выявление аномалий
--             3.5.1. Используя представление flight_performance, рассчитайте среднюю задержку вылета и стандартное отклонение по всем рейсам.
SELECT
    ROUND(
        AVG(
            EXTRACT(
                EPOCH
                FROM
                    (actual_departure - scheduled_departure)
            ) / 60
        ),
        2
    ) AS mean_delay_minutes,
    ROUND(
        STDDEV(
            EXTRACT(
                EPOCH
                FROM
                    (actual_departure - scheduled_departure)
            ) / 60
        ),
        2
    ) AS stddev_delay_minutes
FROM
    bookings.flights_v
WHERE
    actual_departure IS NOT NULL;

--             3.5.2. Найдите рейсы, задержка вылета которых превышает 3 стандартных отклонения от среднего. Выведите топ-10 таких рейсов с самой большой задержкой (маршрут, дата, задержка).
WITH
    stats AS (
        SELECT
            AVG(
                EXTRACT(
                    EPOCH
                    FROM
                        (actual_departure - scheduled_departure)
                ) / 60
            ) AS mean_val,
            STDDEV(
                EXTRACT(
                    EPOCH
                    FROM
                        (actual_departure - scheduled_departure)
                ) / 60
            ) AS stddev_val
        FROM
            bookings.flights_v
        WHERE
            actual_departure IS NOT NULL
    )
SELECT
    f.flight_no,
    f.departure_airport || ' -> ' || f.arrival_airport AS route,
    f.scheduled_departure,
    ROUND(
        EXTRACT(
            EPOCH
            FROM
                (f.actual_departure - f.scheduled_departure)
        ) / 60,
        2
    ) AS delay_minutes
FROM
    bookings.flights_v f,
    stats
WHERE
    f.actual_departure IS NOT NULL
    AND (
        EXTRACT(
            EPOCH
            FROM
                (f.actual_departure - f.scheduled_departure)
        ) / 60
    ) > (stats.mean_val + 3 * stats.stddev_val)
ORDER BY
    delay_minutes DESC
LIMIT
    10;

--             3.5.3. Рассчитайте медианную стоимость билета (total_amount) для каждого класса обслуживания (fare_conditions), используя таблицы segments и tickets.
SELECT
    tf.fare_conditions AS class_type,
    PERCENTILE_CONT(0.5) WITHIN GROUP (
        ORDER BY
            tf.amount
    ) AS median_cost
FROM
    bookings.ticket_flights tf
GROUP BY
    tf.fare_conditions
ORDER BY
    median_cost DESC;

--             3.5.4. Посчитайте среднее количество перелетов (segments) на одного уникального пассажира (passenger_id).
WITH
    passenger_stats AS (
        SELECT
            t.passenger_id,
            COUNT(tf.flight_id) AS flights_count
        FROM
            bookings.tickets t
            JOIN bookings.ticket_flights tf ON t.ticket_no = tf.ticket_no
        GROUP BY
            t.passenger_id
    )
SELECT
    ROUND(AVG(flights_count), 2) AS avg_flights_per_passenger
FROM
    passenger_stats;

--             3.5.5. Выявите пассажиров, количество перелетов которых превышает 95-й процентиль. Можно ли их считать "супер-путешественниками" или это ошибка данных?
WITH
    passenger_activity AS (
        SELECT
            t.passenger_id,
            t.passenger_name,
            COUNT(tf.flight_id) AS total_flights
        FROM
            bookings.tickets t
            JOIN bookings.ticket_flights tf ON t.ticket_no = tf.ticket_no
        GROUP BY
            t.passenger_id,
            t.passenger_name
    ),
    threshold AS (
        SELECT
            PERCENTILE_CONT(0.95) WITHIN GROUP (
                ORDER BY
                    total_flights
            ) AS p95_limit
        FROM
            passenger_activity
    )
SELECT
    pa.passenger_id,
    pa.passenger_name,
    pa.total_flights,
    t.p95_limit AS threshold_95
FROM
    passenger_activity pa,
    threshold t
WHERE
    pa.total_flights > t.p95_limit
ORDER BY
    pa.total_flights DESC
LIMIT
    10;

--  passenger_id |  passenger_name   | total_flights | threshold_95 
-- --------------+-------------------+---------------+--------------
-- 1469 568096  | TATYANA ZAYCEVA   |             6 |            4
-- 0736 965006  | EKATERINA PETROVA |             6 |            4
-- 2005 899431  | LYUDMILA SMIRNOVA |             6 |            4
-- 9549 842859  | TATYANA KUZNECOVA |             6 |            4
-- 6956 580016  | EVGENIY KOZLOV    |             6 |            4
-- 6480 107379  | PAVEL MAKAROV     |             6 |            4
-- 1122 553097  | RUSLAN BARANOV    |             6 |            4
-- 1961 005089  | ANATOLIY DAVYDOV  |             6 |            4
-- 8575 224000  | OLGA IVANOVA      |             6 |            4
-- 7876 981926  | ANTONINA ANDREEVA |             6 |            4
-- Если total_flights ~ 20-50 за год - нормальное поведение
-- Если total_flights > 500-1000 - подозрительно
--         3.6. Когортный анализ
--             3.6.1. Анализ удержания пассажиров. Используя таблицы bookings.bookings и bookings.tickets, сформируйте когорты пассажиров по месяцу их первой покупки (первого бронирования). Для каждой когорты рассчитайте кривую удержания — процент пассажиров, совершивших повторное бронирование в течение 1 месяца после первой покупки, 3 месяца после первой покупки.
WITH
    first_bookings AS (
        -- Находим дату первой покупки для каждого пассажира
        SELECT
            t.passenger_id,
            MIN(b.book_date) AS first_purchase_date,
            DATE_TRUNC('month', MIN(b.book_date))::date AS cohort_month
        FROM
            bookings.tickets t
            JOIN bookings.bookings b ON t.book_ref = b.book_ref
        GROUP BY
            t.passenger_id
    ),
    retention_flags AS (
        -- Проверяем наличие покупок в нужных интервалах
        SELECT
            fb.passenger_id,
            fb.cohort_month,
            -- Была ли покупка в течение 1 месяца ПОСЛЕ первой даты
            MAX(
                CASE
                    WHEN b.book_date > fb.first_purchase_date
                    AND b.book_date <= fb.first_purchase_date + INTERVAL '1 month' THEN 1
                    ELSE 0
                END
            ) AS retained_1m,
            -- Была ли покупка в течение 3 месяцев ПОСЛЕ первой даты
            MAX(
                CASE
                    WHEN b.book_date > fb.first_purchase_date
                    AND b.book_date <= fb.first_purchase_date + INTERVAL '3 months' THEN 1
                    ELSE 0
                END
            ) AS retained_3m
        FROM
            first_bookings fb
            -- Соединяем с историей покупок, чтобы найти повторные
            JOIN bookings.tickets t ON fb.passenger_id = t.passenger_id
            JOIN bookings.bookings b ON t.book_ref = b.book_ref
        GROUP BY
            fb.passenger_id,
            fb.cohort_month
    )
    -- Агрегируем по когортам
SELECT
    TO_CHAR(cohort_month, 'YYYY-MM') AS cohort,
    COUNT(*) AS cohort_size,
    -- 1 Month
    ROUND(SUM(retained_1m)::numeric / COUNT(*) * 100, 2) AS retention_1m_pct,
    -- 3 Months
    ROUND(SUM(retained_3m)::numeric / COUNT(*) * 100, 2) AS retention_3m_pct
FROM
    retention_flags
GROUP BY
    cohort_month
ORDER BY
    cohort_month;

-- Проверка:
-- SELECT 
--     t.passenger_id,
--     COUNT(DISTINCT b.book_ref) AS bookings_count
-- FROM bookings.tickets t
-- JOIN bookings.bookings b ON t.book_ref = b.book_ref
-- GROUP BY t.passenger_id
-- HAVING COUNT(DISTINCT b.book_ref) > 1
-- LIMIT 10;
--  passenger_id | bookings_count 
-- --------------+----------------
-- (0 rows)
--             3.6.2. Анализ "выживаемости" маршрутов. 
-- Выживание означает, что маршрут не прекратил выполнение в течение указанного срока — т.е. имел рейсы в этот период. Когорта (квартал первого рейса)
--                 • Используя таблицу bookings.flights и bookings.routes, сформируйте когорты маршрутов (route_no) по кварталу их первого выполнения (первого рейса по scheduled_departure). 
--                 • Для каждой когорты рассчитайте долю маршрутов, которые "выжили" — то есть имели хотя бы один рейс в течение 2 месяцев после первого рейса, 4 месяцев после первого рейса. 
WITH
    route_starts AS (
        -- Определяем первый рейс
        SELECT
            flight_no,
            MIN(scheduled_departure) AS first_flight_date,
            -- Формируем название квартала
            TO_CHAR(MIN(scheduled_departure), 'YYYY-"Q"Q') AS cohort_quarter
        FROM
            bookings.flights
        GROUP BY
            flight_no
    ),
    survival_check AS (
        -- Проверяем активность маршрута в заданных окнах
        SELECT
            rs.flight_no,
            rs.cohort_quarter,
            -- Ищем хотя бы 1 рейс в интервале start, start + 2 мес
            EXISTS (
                SELECT
                    1
                FROM
                    bookings.flights f
                WHERE
                    f.flight_no = rs.flight_no
                    AND f.scheduled_departure > rs.first_flight_date
                    AND f.scheduled_departure <= rs.first_flight_date + INTERVAL '2 months'
            ) AS survived_2m,
            -- 4 месяца
            EXISTS (
                SELECT
                    1
                FROM
                    bookings.flights f
                WHERE
                    f.flight_no = rs.flight_no
                    AND f.scheduled_departure > rs.first_flight_date
                    AND f.scheduled_departure <= rs.first_flight_date + INTERVAL '4 months'
            ) AS survived_4m
        FROM
            route_starts rs
    )
    -- Агрегируем результаты
SELECT
    cohort_quarter,
    COUNT(*) AS routes_launched,
    -- Доля выживших через 2 месяца
    ROUND(
        COUNT(
            CASE
                WHEN survived_2m THEN 1
            END
        )::numeric / COUNT(*) * 100,
        2
    ) AS survival_2m_pct,
    -- Доля выживших через 4 месяца
    ROUND(
        COUNT(
            CASE
                WHEN survived_4m THEN 1
            END
        )::numeric / COUNT(*) * 100,
        2
    ) AS survival_4m_pct
FROM
    survival_check
GROUP BY
    cohort_quarter
ORDER BY
    cohort_quarter;

--         3.7. Текстовый анализ и эксперименты
--             3.7.1. Анализ географии: Используя LIKE и регулярные выражения, найдите все аэропорты, в названии города (airports.city) которых упоминаются направления света (Северный, Южно- и т.д.).
SELECT
    airport_code,
    airport_name,
    city
FROM
    bookings.airports
WHERE
    city ~* '(Север|Юж|Восток|Запад)';

--             3.7.2. Гипотетический A/B-тест. Предположим, авиакомпания ввела новую систему лояльности для пассажиров, летающих классом Comfort. 
--                 • Разделите пассажиров, летавших классом Comfort за последний год, на две гипотетические группы: те, кто летал до введения программы (контроль), и после (тест). Границу установите произвольно (например, MAX(book_date)- interval '3 months'). 
--                 • Сравните для этих двух групп среднее количество бронирований на пассажира и средний чек после границы – "момента внедрения". 
--                 • Сформулируйте гипотезу о влиянии программы и проверьте ее на данных, описав логику запроса. Какие статистические метрики вы бы рассчитали для реального теста?
WITH
    split_data AS (
        -- Выбираем данные и размечаем группы
        SELECT
            t.passenger_id,
            tf.amount,
            b.book_date,
            CASE
                WHEN b.book_date < bookings.now () - INTERVAL '3 months' THEN 'Control (Before)'
                ELSE 'Test (After)'
            END AS group_name
        FROM
            bookings.ticket_flights tf
            JOIN bookings.tickets t ON tf.ticket_no = t.ticket_no
            JOIN bookings.bookings b ON t.book_ref = b.book_ref
        WHERE
            tf.fare_conditions = 'Comfort'
            -- Берем только за последний год
            AND b.book_date >= bookings.now () - INTERVAL '1 year'
            AND b.book_date <= bookings.now ()
    ),
    passenger_metrics AS (
        -- Считаем метрики для каждого пассажира внутри его группы
        SELECT
            group_name,
            passenger_id,
            COUNT(*) AS flights_count,
            AVG(amount) AS avg_ticket_price
        FROM
            split_data
        GROUP BY
            group_name,
            passenger_id
    )
    -- Итоговое сравнение групп
SELECT
    group_name,
    COUNT(DISTINCT passenger_id) AS total_passengers,
    ROUND(AVG(flights_count), 4) AS avg_flights_per_passenger,
    ROUND(AVG(avg_ticket_price), 2) AS avg_check
FROM
    passenger_metrics
GROUP BY
    group_name
ORDER BY
    group_name;

-- Гипотеза о влиянии программы:
-- Внедрение новой системы лояльности увеличит частоту полетов и средний чек в сегменте Comfort, так как пассажиры будут мотивированы накапливать бонусы
-- Проверка на демо-данных: Гипотеза не подтвердится из-за отсутствия повторных покупок в синтетических данных
-- Вывод: На текущих данных эффект от внедрения программы не наблюдается (метрики идентичны)
-- Статистические метрики для реального теста
-- 1.  t-test:
-- Чтобы проверить, есть ли статистически значимая разница между средним чеком в группе Control и Test.
-- 2. p-value:
-- Если p < 0.05, мы считаем, что изменения реальны, а не являются результатом случайности
-- 3. Доверительные интервалы:
-- Например: Средний чек вырос на 500 руб ± 50 руб с вероятностью 95%
-- Проверка на нормальность распределения
-- 4. Сезонное распределение (лето)
--                     3.8. *Создание сложных отчетов
--             3.8.1. Рассчитайте конверсию по шагам: Бронь -> Выпуск билета -> Регистрация на рейс (получение посадочного) -> Фактический вылет. 
-- Конверсия — это метрика, показывающая долю пользователей или сущностей, которые переходят от одного этапа процесса к следующему. В контексте авиабилетов и бизнес-процессов она измеряет, какая часть начальных действий (например, бронирований) успешно завершается на каждом последующем этапе. Конверсия (%) = (Количество сущностей на текущем этапе / Количество сущностей на предыдущем этапе) × 100%
-- -- Этап                            Что измеряется                                                                  Формула
-- -- 1. Бронь                        Уникальные бронирования (book_ref)                                              —
-- -- 2. Выпуск билета                Уникальные билеты (ticket_no), привязанные к брони                              Tickets / Bookings × 100%
-- -- 3. Регистрация (посадочный)     Уникальные посадочные талоны (ticket_no + flight_id)                            Boarding Passes / Tickets × 100%
-- -- 4. Фактический вылет            Рейсы, у которых есть реальное время вылета (actual_departure IS NOT NULL)      Actual Departures / Boarding Passes × 100%
WITH
    funnel_stats AS (
        SELECT
            -- Количество уникальных бронирований
            (
                SELECT
                    COUNT(book_ref)
                FROM
                    bookings.bookings
            ) AS step1_bookings,
            -- Количество уникальных билетов
            (
                SELECT
                    COUNT(ticket_no)
                FROM
                    bookings.tickets
            ) AS step2_tickets,
            -- Количество выданных посадочных талонов
            (
                SELECT
                    COUNT(*)
                FROM
                    bookings.boarding_passes
            ) AS step3_boarding_passes,
            -- Количество посадочных на рейсы, которые фактически вылетели
            (
                SELECT
                    COUNT(bp.ticket_no)
                FROM
                    bookings.boarding_passes bp
                    JOIN bookings.flights f ON bp.flight_id = f.flight_id
                WHERE
                    f.actual_departure IS NOT NULL
            ) AS step4_actual_flown
    )
SELECT
    -- Брони (База)
    step1_bookings,
    -- Выпуск билетов
    step2_tickets,
    ROUND(
        (step2_tickets::numeric / step1_bookings) * 100,
        2
    ) AS conv_booking_to_ticket_pct,
    -- Регистрация
    step3_boarding_passes,
    ROUND(
        (step3_boarding_passes::numeric / step2_tickets) * 100,
        2
    ) AS conv_ticket_to_bp_pct,
    -- Фактический вылет
    step4_actual_flown,
    ROUND(
        (
            step4_actual_flown::numeric / step3_boarding_passes
        ) * 100,
        2
    ) AS conv_bp_to_fly_pct
FROM
    funnel_stats;

--             3.8.2. Найдите топ-5 самых частых комбинаций городов в рамках одного бронирования (например, Москва->Париж и Париж->Москва в одном билете).
-- Примечание: используем LEAST() и GREATEST() — для нормализации пары городов (чтобы Москва→СПб и СПб→Москва считались одной комбинацией), извлечение только русских названий городов: city->>'ru' (JSON-поля), CONCAT(LEAST(...), '↔', GREATEST(...)) — для формирования уникального ключа пары и GROUP BY по сформированной паре. Формат вывода - строка в формате "Город1↔Город2".
SELECT
    CONCAT(
        LEAST(dep.city ->> 'ru', arr.city ->> 'ru'),
        ' ↔ ',
        GREATEST(dep.city ->> 'ru', arr.city ->> 'ru')
    ) AS city_pair,
    COUNT(*) AS frequency
FROM
    bookings.ticket_flights tf
    JOIN bookings.flights f ON tf.flight_id = f.flight_id
    JOIN bookings.airports_data dep ON f.departure_airport = dep.airport_code
    JOIN bookings.airports_data arr ON f.arrival_airport = arr.airport_code
GROUP BY
    city_pair
ORDER BY
    frequency DESC
LIMIT
    5;