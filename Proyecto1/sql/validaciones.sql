-- ============================================================================
-- SG-Food · Validaciones end-to-end (Fase 4). Tarea `validaciones_sql` del DAG.
-- Se ejecuta con: psql -v ON_ERROR_STOP=1 -f sql/validaciones.sql
--
-- V1-V3 son controles duros: los bloques DO lanzan EXCEPTION si fallan y
-- psql sale != 0 -> la tarea Airflow queda en rojo.
-- A1-A6 son analíticas de negocio (informativas, siempre exit 0).
-- ============================================================================
SET search_path TO marts, staging, raw, public;

-- ============================ V1: conteos raw vs. marts =====================
SELECT 'V1a_venta' AS control, (SELECT count(*) FROM raw.venta) AS en_raw,
       (SELECT count(DISTINCT id_venta) FROM fact_ventas) AS en_marts;
SELECT 'V1b_detalle' AS control, (SELECT count(*) FROM raw.venta_detalle) AS en_raw,
       (SELECT count(*) FROM fact_ventas) AS en_marts;
SELECT 'V1c_inventario' AS control, (SELECT count(*) FROM raw.inventario_bodega) AS en_raw,
       (SELECT count(*) FROM fact_inventario) AS en_marts;
SELECT 'V1d_devoluciones' AS control, (SELECT count(*) FROM raw.devoluciones) AS en_raw,
       (SELECT count(*) FROM fact_devoluciones) AS en_marts;

-- ================== V2: integridad referencial (hechos sin dimensión) =======
SELECT 'V2a_ventas_huerfanas' AS control, count(*) AS filas
FROM fact_ventas f
WHERE NOT EXISTS (SELECT 1 FROM dim_producto p WHERE p.producto_sk = f.producto_sk)
   OR NOT EXISTS (SELECT 1 FROM dim_cliente c WHERE c.cliente_sk = f.cliente_sk)
   OR NOT EXISTS (SELECT 1 FROM dim_sucursal s WHERE s.sucursal_sk = f.sucursal_sk)
   OR NOT EXISTS (SELECT 1 FROM dim_fecha d WHERE d.fecha = f.fecha_fk);
SELECT 'V2b_inventario_huerfano' AS control, count(*) AS filas
FROM fact_inventario f
WHERE NOT EXISTS (SELECT 1 FROM dim_producto p WHERE p.producto_sk = f.producto_sk)
   OR NOT EXISTS (SELECT 1 FROM dim_sucursal s WHERE s.sucursal_sk = f.sucursal_sk)
   OR NOT EXISTS (SELECT 1 FROM dim_fecha d WHERE d.fecha = f.fecha_corte);
SELECT 'V2c_devoluciones_huerfanas' AS control, count(*) AS filas
FROM fact_devoluciones f
WHERE NOT EXISTS (SELECT 1 FROM dim_producto p WHERE p.producto_sk = f.producto_sk)
   OR NOT EXISTS (SELECT 1 FROM dim_fecha d WHERE d.fecha = f.fecha_fk);

-- ==================== V3: duplicados y nulos en claves ======================
SELECT 'V3a_dup_fact_ventas' AS control, count(*) AS filas
FROM (SELECT id_detalle FROM fact_ventas GROUP BY id_detalle HAVING count(*) > 1) t;
SELECT 'V3b_nulos_claves_ventas' AS control, count(*) AS filas
FROM fact_ventas
WHERE id_detalle IS NULL OR fecha_fk IS NULL OR producto_sk IS NULL
   OR cliente_sk IS NULL OR sucursal_sk IS NULL;
SELECT 'V3c_dup_dims' AS control, count(*) AS filas
FROM (
    SELECT producto_sk FROM dim_producto GROUP BY producto_sk HAVING count(*) > 1
    UNION ALL
    SELECT cliente_sk FROM dim_cliente GROUP BY cliente_sk HAVING count(*) > 1
    UNION ALL
    SELECT sucursal_sk FROM dim_sucursal GROUP BY sucursal_sk HAVING count(*) > 1
) t;
SELECT 'V3d_dup_inventario' AS control, count(*) AS filas
FROM (SELECT fecha_corte, sucursal_sk, producto_sk FROM fact_inventario
      GROUP BY 1, 2, 3 HAVING count(*) > 1) t;

-- ============ Controles duros: EXCEPTION si V2 o V3 devuelven filas =========
DO $$
DECLARE
    n integer;
BEGIN
    SELECT (SELECT count(*) FROM (
        SELECT 1 FROM fact_ventas f
        WHERE NOT EXISTS (SELECT 1 FROM dim_producto p WHERE p.producto_sk = f.producto_sk)
           OR NOT EXISTS (SELECT 1 FROM dim_cliente c WHERE c.cliente_sk = f.cliente_sk)
           OR NOT EXISTS (SELECT 1 FROM dim_sucursal s WHERE s.sucursal_sk = f.sucursal_sk)
           OR NOT EXISTS (SELECT 1 FROM dim_fecha d WHERE d.fecha = f.fecha_fk)) t)
        + (SELECT count(*) FROM (
        SELECT 1 FROM fact_inventario f
        WHERE NOT EXISTS (SELECT 1 FROM dim_producto p WHERE p.producto_sk = f.producto_sk)
           OR NOT EXISTS (SELECT 1 FROM dim_sucursal s WHERE s.sucursal_sk = f.sucursal_sk)
           OR NOT EXISTS (SELECT 1 FROM dim_fecha d WHERE d.fecha = f.fecha_corte)) t)
        + (SELECT count(*) FROM (
        SELECT id_detalle FROM fact_ventas GROUP BY id_detalle HAVING count(*) > 1) t)
        + (SELECT count(*) FROM fact_ventas
           WHERE id_detalle IS NULL OR fecha_fk IS NULL OR producto_sk IS NULL
              OR cliente_sk IS NULL OR sucursal_sk IS NULL) t
        INTO n;
    IF n > 0 THEN
        RAISE EXCEPTION 'VALIDACION FALLIDA: % filas huérfanas/duplicadas/nulas en claves', n;
    END IF;
    RAISE NOTICE 'Controles duros OK: sin huérfanos, duplicados ni nulos en claves';
END $$;

-- ==================== A1: ventas por marca y mes =============================
SELECT 'A1_ventas_marca_mes' AS consulta, f.nombre_mes, f.anio,
       p.marca, sum(v.subtotal) AS venta_total, sum(v.cantidad) AS unidades
FROM fact_ventas v
JOIN dim_fecha f ON f.fecha = v.fecha_fk
JOIN dim_producto p ON p.producto_sk = v.producto_sk
WHERE v.estado = 'COMPLETADA'
GROUP BY 1, 2, 3, 4
ORDER BY 2, 3, 5 DESC;

-- ================== A2: ventas por categoría y mes ============================
SELECT 'A2_ventas_categoria_mes' AS consulta, f.nombre_mes, f.anio,
       p.categoria, sum(v.subtotal) AS venta_total
FROM fact_ventas v
JOIN dim_fecha f ON f.fecha = v.fecha_fk
JOIN dim_producto p ON p.producto_sk = v.producto_sk
WHERE v.estado = 'COMPLETADA'
GROUP BY 1, 2, 3, 4
ORDER BY 2, 3, 5 DESC;

-- ==================== A3: top 10 productos ===================================
SELECT 'A3_top_productos' AS consulta, p.nombre AS producto, p.marca,
       sum(v.cantidad) AS unidades, sum(v.subtotal) AS venta_total
FROM fact_ventas v
JOIN dim_producto p ON p.producto_sk = v.producto_sk
WHERE v.estado = 'COMPLETADA'
GROUP BY 1, 2, 3
ORDER BY 5 DESC
LIMIT 10;

-- ================== A4: stock bajo y próximo a vencer =========================
SELECT 'A4_stock_bajo' AS consulta, s.nombre AS sucursal, p.nombre AS producto,
       i.stock_disponible, i.stock_minimo, i.fecha_vencimiento
FROM fact_inventario i
JOIN dim_sucursal s ON s.sucursal_sk = i.sucursal_sk
JOIN dim_producto p ON p.producto_sk = i.producto_sk
WHERE i.fecha_corte = (SELECT max(fecha_corte) FROM fact_inventario)
  AND (i.flag_stock_bajo OR i.flag_vencido)
ORDER BY 1, 2;

-- ============ A5: cumplimiento de metas vs. ventas reales =====================
SELECT 'A5_metas_vs_real' AS consulta,
       to_char(m.periodo, 'YYYY-MM') AS periodo, s.nombre AS sucursal,
       m.meta_ventas, coalesce(r.venta_real, 0) AS venta_real,
       round(100.0 * coalesce(r.venta_real, 0) / nullif(m.meta_ventas, 0), 1) AS pct_cumplimiento
FROM fact_metas m
JOIN dim_sucursal s ON s.sucursal_sk = m.sucursal_sk
LEFT JOIN (
    SELECT date_trunc('month', v.fecha_fk)::date AS periodo, v.sucursal_sk,
           sum(v.subtotal) AS venta_real
    FROM fact_ventas v
    WHERE v.estado = 'COMPLETADA'
    GROUP BY 1, 2
) r ON r.periodo = m.periodo AND r.sucursal_sk = m.sucursal_sk
ORDER BY 2, 3;

-- ================= A6: devoluciones por motivo ================================
SELECT 'A6_devoluciones_motivo' AS consulta, d.motivo,
       count(*) AS n_devoluciones, sum(d.cantidad) AS unidades_devueltas
FROM fact_devoluciones d
GROUP BY 1, 2
ORDER BY 4 DESC;
