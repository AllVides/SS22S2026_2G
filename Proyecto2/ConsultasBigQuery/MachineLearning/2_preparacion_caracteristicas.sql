
-- PROYECTO 2 - FASE 3
-- Consulta 2: Preparacion de caracteristicas
-- Objetivo: preparar variables para regresion

WITH datos_preparados AS (
    SELECT
        fecha_viaje,

        CAST(fare_amount AS FLOAT64)
            AS tarifa_objetivo,

        CAST(trip_distance AS FLOAT64)
            AS distancia,

        CAST(
            COALESCE(passenger_count, -1)
            AS STRING
        ) AS pasajeros,

        pickup_location_id AS origen,
        dropoff_location_id AS destino,

        EXTRACT(HOUR FROM pickup_datetime)
            AS hora_inicio,

        EXTRACT(DAYOFWEEK FROM pickup_datetime)
            AS dia_semana,

        CASE
            WHEN fecha_viaje < DATE '2022-01-21'
                THEN 'TRAIN'
            WHEN fecha_viaje < DATE '2022-01-26'
                THEN 'EVAL'
            ELSE 'TEST'
        END AS conjunto

    FROM
        `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.viajes_base`

    WHERE
        fare_amount BETWEEN 0 AND 300
        AND pickup_location_id IS NOT NULL
        AND dropoff_location_id IS NOT NULL
)

SELECT
    conjunto,
    COUNT(*) AS total_registros,
    ROUND(AVG(tarifa_objetivo), 2)
        AS tarifa_promedio,
    ROUND(AVG(distancia), 2)
        AS distancia_promedio,
    COUNTIF(pasajeros = '-1')
        AS pasajeros_desconocidos
FROM datos_preparados
GROUP BY conjunto
ORDER BY conjunto;
