
-- PROYECTO 2 - FASE 3
-- Consulta 7: Evaluacion final con TEST
-- Modelo: Regresion lineal
-- Periodo: 26 al 31 de enero de 2022

SELECT
    ROUND(mean_absolute_error, 4) AS mae,
    ROUND(mean_squared_error, 4) AS mse,
    ROUND(SQRT(mean_squared_error), 4) AS rmse,
    ROUND(median_absolute_error, 4) AS error_mediano,
    ROUND(r2_score, 4) AS r2,
    ROUND(explained_variance, 4) AS varianza_explicada

FROM ML.EVALUATE(
    MODEL `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.modelo_regresion_lineal`,
    (
        SELECT
            CAST(fare_amount AS FLOAT64)
                AS tarifa_objetivo,

            CAST(trip_distance AS FLOAT64)
                AS distancia,

            CAST(COALESCE(passenger_count, -1) AS STRING)
                AS pasajeros,

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
    )
);
