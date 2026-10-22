
-- PROYECTO 2 - FASE 2
-- Reconstruccion de la tabla optimizada
-- Origen: viajes_base (2,421,619 registros)

CREATE OR REPLACE TABLE
  `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.viajes_optimizados`

PARTITION BY fecha_viaje

CLUSTER BY
    pickup_location_id,
    dropoff_location_id

AS
SELECT
    fecha_viaje,
    pickup_datetime,
    dropoff_datetime,
    pickup_location_id,
    dropoff_location_id,
    passenger_count,
    trip_distance,
    fare_amount,
    tip_amount,
    total_amount
FROM
    `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.viajes_base`;
