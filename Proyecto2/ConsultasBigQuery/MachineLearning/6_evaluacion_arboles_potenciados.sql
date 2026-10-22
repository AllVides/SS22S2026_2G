
-- PROYECTO 2 - FASE 3
-- Consulta 6: Evaluacion del modelo XGBoost
-- Utiliza el conjunto de validacion interno

SELECT
    ROUND(mean_absolute_error, 4) AS mae,
    ROUND(mean_squared_error, 4) AS mse,
    ROUND(SQRT(mean_squared_error), 4) AS rmse,
    ROUND(mean_squared_log_error, 4) AS msle,
    ROUND(median_absolute_error, 4) AS error_mediano,
    ROUND(r2_score, 4) AS r2,
    ROUND(explained_variance, 4) AS varianza_explicada
FROM ML.EVALUATE(
    MODEL `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.modelo_arboles_potenciados`
);
