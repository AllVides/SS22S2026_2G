
-- PROYECTO 2 - FASE 2
-- Tabla optimizada compatible con fechas historicas
-- Conserva fecha_viaje original de 2022
-- Utiliza una fecha auxiliar para particionamiento

CREATE TABLE IF NOT EXISTS
  `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.viajes_optimizados_v2`

PARTITION BY fecha_particion

CLUSTER BY
    pickup_location_id,
    dropoff_location_id

AS
SELECT
    fecha_viaje,

    DATE_ADD(
        CURRENT_DATE(),
        INTERVAL EXTRACT(DAY FROM fecha_viaje) - 1 DAY
    ) AS fecha_particion,

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
