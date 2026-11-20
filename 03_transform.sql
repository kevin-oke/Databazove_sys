
\set ON_ERROR_STOP on 
\encoding UTF8

-- CREATE SCHEMA IF NOT EXISTS gold;
--DROP SCHEMA IF EXISTS gold CASCADE;
--CREATE SCHEMA gold;

-- DIM_USER
CREATE TABLE gold.dim_user(
    user_id INT NOT NULL UNIQUE,
    gender CHAR(1) NOT NULL CHECK(gender IN ('M','F')),
    zip_code VARCHAR(10),
    age_group VARCHAR(20) NOT NULL,
    occupation VARCHAR(50) NOT NULL
);

CREATE TABLE gold.dim_movie(
    movie_id INT NOT NULL UNIQUE,
    title VARCHAR(200) NOT NULL,
    release_year INT,
    genre_name VARCHAR(200) NOT NULL
);

CREATE TABLE gold.dim_date (
    date_id INT PRIMARY KEY,
    rated_at DATE NOT NULL UNIQUE,
    day INT NOT NULL,
    month INT NOT NULL,
    year INT NOT NULL,
    day_of_week INT NOT NULL,
    day_name VARCHAR(10),
    week INT NOT NULL,
    month_name VARCHAR(10) NOT NULL,
    quarter INT NOT NULL
);

CREATE TABLE gold.dim_time(
    time_id INT PRIMARY KEY,
    rated_time TIME NOT NULL UNIQUE,
    hour INT NOT NULL,
    minute INT NOT NULL,
    second INT NOT NULL,
    time_of_day VARCHAR(10) NOT NULL
);

CREATE TABLE gold.fact_rating (
    rating_id INT PRIMARY KEY,
    user_id INT NOT NULL REFERENCES gold.dim_user (user_id),
    movie_id INT NOT NULL REFERENCES gold.dim_movie (movie_id),
    date_id INT NOT NULL REFERENCES gold.dim_date (date_id),
    time_id INT NOT NULL REFERENCES gold.dim_time (time_id),
    rating NUMERIC(2,1) NOT NULL CHECK (rating BETWEEN 1 AND 5),
    rating_count INT NOT NULL,
    rating_percentage INT NOT NULL
);

CREATE INDEX ON gold.fact_rating (user_id);
CREATE INDEX ON gold.fact_rating (movie_id);
CREATE INDEX ON gold.fact_rating (date_id);
CREATE INDEX ON gold.fact_rating (time_id);

BEGIN;

TRUNCATE gold.fact_rating,
gold.dim_user,
gold.dim_movie,
gold.dim_date,
gold.dim_time;
-- gold.dim_time RESTART IDENTITY; v prípade ak mám tam autoinkrement

INSERT INTO gold.dim_user (user_id, gender, zip_code, age_group, occupation)
    SELECT u.user_id, u.gender, u.zip_code,
        COALESCE(a.age_group_name, 'unknown'), COALESCE(o.occupation_name, 'unknown')
    FROM silver.stg_users u
    LEFT JOIN silver.stg_age_groups a ON a.age_group_id = u.age
    LEFT JOIN silver.stg_occupations o ON o.occupation_id = u.occupation_id
    ORDER BY u.user_id;

INSERT INTO gold.dim_movie (movie_id, title, release_year, genre_name)
SELECT
    m.movie_id,
    m.title,
    m.release_year,
    COALESCE(g.genre_name, 'Unknown')
FROM silver.stg_movies AS m
LEFT JOIN (
    SELECT
        gm.movie_id,
        STRING_AGG(DISTINCT g.genre_name, ', ' ORDER BY g.genre_name) AS genre_name
    FROM silver.stg_genres_movies AS gm
    JOIN silver.stg_genres AS g
        ON g.genre_id = gm.genre_id
    GROUP BY gm.movie_id
) AS g
    ON g.movie_id = m.movie_id
ORDER BY m.movie_id;

INSERT INTO gold.dim_date
    SELECT
        TO_CHAR(d, 'YYYYMMDD')::INT AS date_id,
        d AS rated_at,
        EXTRACT(day FROM d)::INT AS day,
        EXTRACT(month FROM d)::INT AS month,
        EXTRACT(year FROM d)::INT AS year,
        EXTRACT(isodow FROM d)::INT as day_of_week,
        TRIM(TO_CHAR(d, 'Day')) AS day_name,
        EXTRACT(week FROM d)::INT AS week,
        TRIM(TO_CHAR(d, 'Month')) AS month_name,
        EXTRACT(quarter FROM d)::INT AS quarter
    FROM GENERATE_SERIES(
        (SELECT min(rated_at)::DATE FROM silver.stg_ratings),
        (SELECT MAX(rated_at)::DATE FROM silver.stg_ratings),
        INTERVAL '1 day'
    ) AS gs(d);

INSERT INTO gold.dim_time (
    time_id, rated_time, hour, minute, second, time_of_day
)
SELECT
    sec / 3600 * 10000
        + (sec / 60) % 60 * 100
        + sec % 60 AS time_id,

    MAKE_TIME(
        sec / 3600,
        (sec / 60) % 60,
        sec % 60
    ) AS rated_time,

    sec / 3600 AS hour,
    (sec / 60) % 60 AS minute,
    sec % 60 AS second,

    CASE
        WHEN sec / 3600 BETWEEN 5 AND 11 THEN 'morning'
        WHEN sec / 3600 BETWEEN 12 AND 17 THEN 'afternoon'
        WHEN sec / 3600 BETWEEN 18 AND 21 THEN 'evening'
        ELSE 'night'
    END AS time_of_day

FROM GENERATE_SERIES(0, 86399) AS gs(sec);

INSERT INTO gold.fact_rating (
    rating_id, user_id, movie_id, date_id, time_id,
    rating, rating_count, rating_percentage
)
WITH rating_totals AS (
    SELECT
        r.*,
        COUNT(*) OVER (
            PARTITION BY r.movie_id, r.rating
        ) AS rating_count,
        COUNT(*) OVER (
            PARTITION BY r.movie_id
        ) AS movie_rating_count
    FROM silver.stg_ratings AS r
)
SELECT
    rt.rating_id,
    rt.user_id,
    rt.movie_id,
    (TO_CHAR(rt.rated_at::DATE, 'YYYYMMDD'))::INT,
    (EXTRACT(HOUR FROM rt.rated_at) * 10000
     + EXTRACT(MINUTE FROM rt.rated_at) * 100
     + EXTRACT(SECOND FROM rt.rated_at)::INT),
    rt.rating,
    rt.rating_count,
    ROUND(100.0 * rt.rating_count / rt.movie_rating_count)::INT
FROM rating_totals AS rt;

COMMIT;