
-- PROYECTO 2 - FASE 2
-- Verificacion de registros en ambas tablas

SELECT
    'Tabla base' AS tabla,
    COUNT(*) AS total_registros
FROM
    `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.viajes_base`

UNION ALL

SELECT
    'Tabla optimizada' AS tabla,
    COUNT(*) AS total_registros
FROM
    `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.viajes_optimizados`

UNION ALL

SELECT
    'Tabla optimizada V2' AS tabla,
    COUNT(*) AS total_registros
FROM
    `project-e2e09e75-7c61-4bba-9a1.optimizacion_taxis.viajes_optimizados_v2`;

