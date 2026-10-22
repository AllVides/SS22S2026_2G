
-- FASE 2 - Validacion de cobertura temporal
-- Conteo por mes, sin filtros de limpieza

SELECT
    EXTRACT(MONTH FROM pickup_datetime) AS mes,
    COUNT(*) AS total_registros
FROM
    `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
WHERE
    pickup_datetime >= '2022-01-01'
    AND pickup_datetime < '2023-01-01'
GROUP BY mes
ORDER BY mes;
