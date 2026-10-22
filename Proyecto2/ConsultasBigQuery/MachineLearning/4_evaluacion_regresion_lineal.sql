
-- PROYECTO 2 - FASE 3
-- Evaluacion interna del modelo de regresion lineal
-- Utiliza el conjunto de validacion definido al entrenar

SELECT *
FROM ML.EVALUATE(
    MODEL `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.modelo_regresion_lineal`
);
