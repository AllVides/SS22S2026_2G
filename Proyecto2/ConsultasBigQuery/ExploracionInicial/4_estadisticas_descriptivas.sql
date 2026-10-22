-- PROYECTO 2 - FASE 1
-- Consulta 3: Estadísticas descriptivas
-- Dataset NYC Yellow Taxi Trips 2022

SELECT
    COUNT(*) AS total_viajes,

    ROUND(AVG(trip_distance), 2)
        AS distancia_promedio,

    ROUND(AVG(fare_amount), 2)
        AS tarifa_promedio,

    ROUND(AVG(total_amount), 2)
        AS costo_total_promedio,

    ROUND(AVG(passenger_count), 2)
        AS pasajeros_promedio,

    ROUND(AVG(
        TIMESTAMP_DIFF(
            dropoff_datetime,
            pickup_datetime,
            MINUTE
        )
    ), 2) AS duracion_promedio_minutos,

    ROUND(MIN(trip_distance), 2)
        AS distancia_minima,

    ROUND(MAX(trip_distance), 2)
        AS distancia_maxima

FROM
    `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
TABLESAMPLE SYSTEM (1 PERCENT)
WHERE
    pickup_datetime >= '2022-01-01'
    AND pickup_datetime < '2023-01-01'
    AND trip_distance > 0
    AND fare_amount >= 0
    AND total_amount >= 0
    AND dropoff_datetime > pickup_datetime;
