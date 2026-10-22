
-- PROYECTO 2 - FASE 2
-- Comparacion A: Tabla sin optimizacion

SELECT
    COUNT(*) AS total_viajes,
    ROUND(AVG(trip_distance), 2) AS distancia_promedio,
    ROUND(AVG(total_amount), 2) AS costo_promedio
FROM
    `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.viajes_base`
WHERE
    fecha_viaje BETWEEN '2022-01-21' AND '2022-01-25'
    AND pickup_location_id = '132';
