
-- PROYECTO 2 - SEMINARIO DE SISTEMAS 2
-- FASE 1: EXPLORACIÓN DEL DATASET
-- Objetivo: identificar las columnas y tipos de datos.

SELECT
    column_name,
    data_type,
    is_nullable
FROM
    `bigquery-public-data.new_york_taxi_trips.INFORMATION_SCHEMA.COLUMNS`
WHERE
    table_name = 'tlc_yellow_trips_2022'
ORDER BY
    ordinal_position;
