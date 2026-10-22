
-- PROYECTO 2 - FASE 3
-- Modelo 1: Regresion lineal
-- Prediccion de fare_amount

CREATE MODEL
  `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.modelo_regresion_lineal`

OPTIONS (
    model_type = 'LINEAR_REG',
    input_label_cols = ['tarifa_objetivo'],
    data_split_method = 'CUSTOM',
    data_split_col = 'es_validacion',
    l2_reg = 0.1,
    max_iterations = 20
)

AS

SELECT
    CAST(fare_amount AS FLOAT64) AS tarifa_objetivo,
    CAST(trip_distance AS FLOAT64) AS distancia,
    CAST(COALESCE(passenger_count, -1) AS STRING)
        AS pasajeros,
    pickup_location_id AS origen,
    dropoff_location_id AS destino,
    EXTRACT(HOUR FROM pickup_datetime) AS hora_inicio,
    EXTRACT(DAYOFWEEK FROM pickup_datetime) AS dia_semana,
    fecha_viaje >= DATE '2022-01-21'
        AS es_validacion

FROM
    `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.viajes_base`

WHERE
    fecha_viaje < DATE '2022-01-26'
    AND fare_amount BETWEEN 0 AND 300
    AND pickup_location_id IS NOT NULL
    AND dropoff_location_id IS NOT NULL;
