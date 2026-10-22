
-- PROYECTO 2 - FASE 1
-- Consulta 4: Analisis de valores atipicos
-- Distribucion de distancias

WITH muestra AS (
    SELECT
        trip_distance
    FROM
        `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
    TABLESAMPLE SYSTEM (1 PERCENT)
    WHERE
        pickup_datetime >= '2022-01-01'
        AND pickup_datetime < '2023-01-01'
        AND trip_distance > 0
)
SELECT
    COUNT(*) AS total_viajes,
    COUNTIF(trip_distance > 50) AS viajes_mayores_50,
    COUNTIF(trip_distance > 100) AS viajes_mayores_100,
    COUNTIF(trip_distance > 500) AS viajes_mayores_500,
    ROUND(AVG(trip_distance), 2) AS promedio_original,
    ROUND(
        AVG(IF(trip_distance <= 100, trip_distance, NULL)),
        2
    ) AS promedio_sin_extremos,
    APPROX_QUANTILES(trip_distance, 100)[OFFSET(50)] AS mediana,
    APPROX_QUANTILES(trip_distance, 100)[OFFSET(95)] AS percentil_95,
    APPROX_QUANTILES(trip_distance, 100)[OFFSET(99)] AS percentil_99
FROM muestra;
