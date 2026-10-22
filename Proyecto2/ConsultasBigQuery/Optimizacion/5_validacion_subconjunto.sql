
-- PROYECTO 2 - FASE 2
-- Consulta 5: Validacion del subconjunto
-- Viajes de enero de 2022

SELECT
    COUNT(*) AS total_registros,
    COUNT(DISTINCT pickup_location_id)
        AS ubicaciones_origen,
    COUNT(DISTINCT dropoff_location_id)
        AS ubicaciones_destino,

    ROUND(AVG(trip_distance), 2)
        AS distancia_promedio,

    ROUND(AVG(total_amount), 2)
        AS costo_promedio

FROM
    `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`

WHERE
    pickup_datetime >= '2022-01-01'
    AND pickup_datetime < '2022-02-01'
    AND trip_distance > 0
    AND trip_distance <= 100
    AND total_amount >= 0
    AND dropoff_datetime > pickup_datetime;
