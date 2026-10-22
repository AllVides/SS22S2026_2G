
-- PROYECTO 2 - FASE 3
-- Consulta 10: Predicciones con XGBoost
-- Muestra reproducible de registros TEST
-- Periodo: 26 al 31 de enero de 2022

WITH datos_test AS (
    SELECT
        CAST(fare_amount AS FLOAT64) AS tarifa_objetivo,
        CAST(trip_distance AS FLOAT64) AS distancia,

        CAST(
            COALESCE(passenger_count, -1) AS STRING
        ) AS pasajeros,

        pickup_location_id AS origen,
        dropoff_location_id AS destino,

        EXTRACT(HOUR FROM pickup_datetime)
            AS hora_inicio,

        EXTRACT(DAYOFWEEK FROM pickup_datetime)
            AS dia_semana

    FROM
        `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.viajes_base`

    WHERE
        fecha_viaje BETWEEN DATE '2022-01-26'
                         AND DATE '2022-01-31'

        AND fare_amount BETWEEN 0 AND 300
        AND pickup_location_id IS NOT NULL
        AND dropoff_location_id IS NOT NULL

        AND MOD(
            FARM_FINGERPRINT(
                CONCAT(
                    CAST(pickup_datetime AS STRING),
                    '|',
                    CAST(dropoff_datetime AS STRING),
                    '|',
                    CAST(trip_distance AS STRING)
                )
            ),
            1000
        ) = 0
)

SELECT
    ROUND(tarifa_objetivo, 2) AS tarifa_real,

    ROUND(predicted_tarifa_objetivo, 2)
        AS tarifa_predicha,

    ROUND(
        ABS(tarifa_objetivo - predicted_tarifa_objetivo),
        2
    ) AS error_absoluto,

    ROUND(distancia, 2) AS distancia

FROM ML.PREDICT(
    MODEL `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.modelo_arboles_potenciados`,
    (SELECT * FROM datos_test)
)

ORDER BY distancia, tarifa_real
LIMIT 20;
