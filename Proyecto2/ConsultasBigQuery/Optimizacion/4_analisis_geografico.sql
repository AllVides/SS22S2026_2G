
-- PROYECTO 2 - FASE 2
-- Consulta 4: Analisis geografico
-- Top 10 ubicaciones de origen

SELECT
    pickup_location_id AS ubicacion_origen,

    COUNT(*) AS total_viajes,

    ROUND(AVG(trip_distance), 2)
        AS distancia_promedio,

    ROUND(AVG(total_amount), 2)
        AS costo_promedio,

    COUNT(DISTINCT dropoff_location_id)
        AS destinos_diferentes

FROM
    `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`

WHERE
    pickup_datetime >= '2022-01-01'
    AND pickup_datetime < '2023-01-01'
    AND trip_distance > 0
    AND trip_distance <= 100
    AND total_amount >= 0
    AND pickup_location_id IS NOT NULL

GROUP BY
    pickup_location_id

ORDER BY
    total_viajes DESC,
    ubicacion_origen

LIMIT 10;
