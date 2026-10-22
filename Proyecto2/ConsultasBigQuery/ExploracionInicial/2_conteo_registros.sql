
-- PROYECTO 2 - FASE 1
-- Conteo de registros mediante metadatos
-- Dataset: NYC Yellow Taxi Trips 2022
-- Tiro error toco verlo drectamente desde la consola

SELECT
    table_name,
    total_rows AS total_registros,
    ROUND(total_logical_bytes / POW(1024, 3), 2)
        AS tamano_gib
FROM
    `bigquery-public-data.region-us.INFORMATION_SCHEMA.TABLE_STORAGE`
WHERE
    table_schema = 'new_york_taxi_trips'
    AND table_name = 'tlc_yellow_trips_2022'
    AND deleted = FALSE;
