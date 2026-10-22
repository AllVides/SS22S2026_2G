
-- PROYECTO 2 - FASE 1
-- Análisis inicial de calidad de datos
-- Muestra de viajes del año 2022

SELECT
    COUNT(*) AS total_muestra,
    COUNTIF(passenger_count IS NULL) AS pasajeros_nulos,
    COUNTIF(trip_distance IS NULL) AS distancia_nula,
    COUNTIF(fare_amount IS NULL) AS tarifa_nula,
    COUNTIF(total_amount IS NULL) AS total_nulo,
    COUNTIF(trip_distance <= 0) AS distancia_invalida,
    COUNTIF(total_amount < 0) AS total_negativo
FROM (
    SELECT
        passenger_count,
        trip_distance,
        fare_amount,
        total_amount
    FROM
        `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
    TABLESAMPLE SYSTEM (1 PERCENT)
);
