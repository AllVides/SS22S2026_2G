
-- PROYECTO 2 - FASE 3
-- Consulta 1: Validacion del dataset para ML
-- Objetivo: verificar registros aptos y split temporal

WITH datos AS (
    SELECT
        fecha_viaje,
        fare_amount,
        trip_distance,
        passenger_count,
        pickup_location_id,
        dropoff_location_id
    FROM
        `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.viajes_base`
),

clasificacion AS (
    SELECT
        *,
        CASE
            WHEN fecha_viaje < DATE '2022-01-21'
                THEN 'Entrenamiento'
            WHEN fecha_viaje < DATE '2022-01-26'
                THEN 'Validacion'
            ELSE 'Prueba'
        END AS conjunto
    FROM datos
)

SELECT
    conjunto,
    COUNT(*) AS total_registros,
    COUNTIF(fare_amount IS NULL)
        AS tarifas_nulas,
    COUNTIF(fare_amount < 0 OR fare_amount > 300)
        AS tarifas_fuera_rango,
    COUNTIF(passenger_count IS NULL)
        AS pasajeros_nulos,
    COUNTIF(pickup_location_id IS NULL
        OR dropoff_location_id IS NULL)
        AS ubicaciones_nulas,
    COUNTIF(
        fare_amount BETWEEN 0 AND 300
        AND pickup_location_id IS NOT NULL
        AND dropoff_location_id IS NOT NULL
    ) AS registros_aptos
FROM clasificacion
GROUP BY conjunto
ORDER BY
    CASE conjunto
        WHEN 'Entrenamiento' THEN 1
        WHEN 'Validacion' THEN 2
        ELSE 3
    END;
