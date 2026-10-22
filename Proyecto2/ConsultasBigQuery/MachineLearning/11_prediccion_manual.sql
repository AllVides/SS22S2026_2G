
-- PROYECTO 2 - FASE 3
-- Demostracion en vivo de Machine Learning
-- Modifica los valores para simular distintos viajes

WITH viaje_nuevo AS (
    SELECT
        5.0 AS distancia,
        '2' AS pasajeros,
        '132' AS origen,
        '161' AS destino,
        14 AS hora_inicio,
        3 AS dia_semana
)

SELECT
    'Regresion lineal' AS modelo,
    ROUND(predicted_tarifa_objetivo, 2)
        AS tarifa_estimada_usd
FROM ML.PREDICT(
    MODEL `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.modelo_regresion_lineal`,
    (SELECT * FROM viaje_nuevo)
)

UNION ALL

SELECT
    'XGBoost' AS modelo,
    ROUND(predicted_tarifa_objetivo, 2)
        AS tarifa_estimada_usd
FROM ML.PREDICT(
    MODEL `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.modelo_arboles_potenciados`,
    (SELECT * FROM viaje_nuevo)
);
