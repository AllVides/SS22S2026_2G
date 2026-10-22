
-- PROYECTO 2 - FASE 2
-- Consulta 1: Analisis temporal de viajes
-- Dataset: NYC Yellow Taxi Trips 2022

SELECT
    EXTRACT(MONTH FROM pickup_datetime) AS mes,

    COUNT(*) AS total_viajes,

    ROUND(AVG(trip_distance), 2)
        AS distancia_promedio,

    ROUND(AVG(total_amount), 2)
        AS costo_promedio,

    ROUND(
        AVG(
            TIMESTAMP_DIFF(
                dropoff_datetime,
                pickup_datetime,
                MINUTE
            )
        ), 2
    ) AS duracion_promedio_minutos

FROM
    `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`

WHERE
    pickup_datetime >= '2022-01-01'
    AND pickup_datetime < '2023-01-01'
    AND trip_distance > 0
    AND trip_distance <= 100
    AND total_amount >= 0
    AND dropoff_datetime > pickup_datetime

GROUP BY
    mes

ORDER BY
    mes;
  