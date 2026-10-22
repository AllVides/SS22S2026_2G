
-- PROYECTO 2 - FASE 2
-- Creacion de tabla base SIN particiones ni clustering
-- Subconjunto: enero de 2022

CREATE TABLE IF NOT EXISTS
  `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.viajes_base`
AS
SELECT
    DATE(pickup_datetime) AS fecha_viaje,
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
    `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
WHERE
    pickup_datetime >= '2022-01-01'
    AND pickup_datetime < '2022-02-01'
    AND trip_distance > 0
    AND trip_distance <= 100
    AND total_amount >= 0
    AND dropoff_datetime > pickup_datetime;
