
-- PROYECTO 2 - FASE 2
-- Creacion de tabla optimizada
-- Particionamiento por fecha
-- Clustering por ubicaciones

CREATE TABLE IF NOT EXISTS
  `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.viajes_optimizados`

PARTITION BY fecha_viaje

CLUSTER BY
    pickup_location_id,
    dropoff_location_id

AS
SELECT *
FROM
  `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.viajes_base`;
