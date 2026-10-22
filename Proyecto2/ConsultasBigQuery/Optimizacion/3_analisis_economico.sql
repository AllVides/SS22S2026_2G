
-- PROYECTO 2 - FASE 2
-- Consulta 3: Analisis economico
-- Tarifas y propinas segun la distancia recorrida

WITH viajes AS (
    SELECT
        trip_distance,
        fare_amount,
        tip_amount,
        total_amount,

        CASE
            WHEN trip_distance <= 2 THEN '01. 0-2 millas'
            WHEN trip_distance <= 5 THEN '02. 2-5 millas'
            WHEN trip_distance <= 10 THEN '03. 5-10 millas'
            WHEN trip_distance <= 20 THEN '04. 10-20 millas'
            ELSE '05. Mas de 20 millas'
        END AS rango_distancia

    FROM
        `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`

    WHERE
        pickup_datetime >= '2022-01-01'
        AND pickup_datetime < '2023-01-01'
        AND trip_distance > 0
        AND trip_distance <= 100
        AND fare_amount >= 0
        AND total_amount >= 0
        AND tip_amount >= 0
)

SELECT
    rango_distancia,
    COUNT(*) AS total_viajes,

    ROUND(AVG(trip_distance), 2)
        AS distancia_promedio,

    ROUND(AVG(fare_amount), 2)
        AS tarifa_promedio,

    ROUND(AVG(tip_amount), 2)
        AS propina_promedio,

    ROUND(AVG(total_amount), 2)
        AS costo_total_promedio

FROM viajes

GROUP BY rango_distancia
ORDER BY rango_distancia;
