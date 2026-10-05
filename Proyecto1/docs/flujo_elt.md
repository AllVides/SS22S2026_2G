# Flujo ELT y validaciones sobre la BD

Pipeline `sgfood_elt` (10 tareas lineales): **E**xtract-**L**oad con Python a
`raw` → **T**ransform con dbt (`staging → intermediate → marts`) → validación
(`dbt test` + `validaciones.sql`). Todo corre en la base `sgfood`; la base
`airflow` es solo metadata y no se toca aquí.

```mermaid
flowchart LR
    OLTP[(oltp_sgfood<br/>7 tablas)] --> EL[extract_load_db<br/>TRUNCATE + INSERT-SELECT]
    CSV[(5 CSV)] --> EC[extract_load_csv<br/>TRUNCATE + INSERT lotes]
    EL --> RAW[(raw<br/>12 tablas)]
    EC --> RAW
    RAW --> VC[validar_conteos_raw<br/>source = raw?]
    VC --> S[dbt staging<br/>12 views]
    S --> I[dbt intermediate<br/>3 views]
    I --> M[dbt marts<br/>4 dim + 4 fact]
    M --> T[dbt_test<br/>84 + 2 singulares]
    T --> V[validaciones_sql<br/>V1-V3 duros, A1-A6]
    V --> D[dbt docs generate]
```

## Etapa 1 — Extracción y carga a `raw` (idempotente por `TRUNCATE+LOAD`)

**`extract_load_db.py`** (una transacción por tabla, rollback parcial): por cada
tabla genera y ejecuta:

```sql
TRUNCATE TABLE raw.venta;
INSERT INTO raw.venta (id_venta, fecha, ..., _source)
SELECT id_venta,
       CAST(fecha AS DATE)            AS fecha,          -- CAST directo
       NULLIF(TRIM(canal::TEXT), '') AS canal,          -- textos: TRIM + ''→NULL
       ...,
       'oltp_sgfood.venta'                              -- trazabilidad
FROM oltp_sgfood.venta;
```

Un valor no casteable aborta **esa** tabla (rollback + log) y sigue con el resto;
exit 1 global si hubo fallos. Volúmenes reales: 6/8/10/80/250/1200/3209 filas.

**`extract_load_csv.py`**: lee con `utf-8-sig`, valida columnas exactas contra el
contrato (`ARCHIVOS`) **antes** de conectarse, normaliza (`strip`, `''→None`) e
inserta por lotes con `execute_values` + `_source='<archivo>.csv'`.
Volúmenes: 3840/80/48/30/103 filas.

**`verify_counts.py`**: 12 comparaciones `oltp_sgfood.* = raw.*` y
`lineas_csv = raw.*`; cualquier diferencia → exit 1 (tarea en rojo).

## Etapa 2 — Transformación dbt (23 modelos)

- **staging** (views, `source('raw', ...)`): espejo tipado. Ej. `stg_venta` castea
  `id_venta::bigint`, `fecha::date` y aplica `nullif(trim(...))` a
  `canal/metodo_pago/estado`; `stg_metas_ventas` conserva `periodo` como texto
  `YYYY-MM` (normaliza marts).
- **intermediate** (views, `ref()`): `int_ventas_detalle` une
  detalle+venta+producto+categoría+marca y calcula
  `round(cantidad*precio_unitario*(1-descuento),2) AS subtotal_calculado`;
  `int_inventario_estado` agrega `flag_stock_bajo` (`disponible < minimo`),
  `flag_vencido` (`vencimiento < corte`) y `dias_para_vencer`;
  `int_devoluciones` hereda `id_sucursal` de su venta (el CSV no la trae).
- **marts** (tables): `dim_fecha` por `generate_series(min,max)` de los hechos;
  dims de entidad con surrogate `row_number() OVER (ORDER BY id_natural)` (SCD1);
  `fact_ventas.subtotal` = **calculado** (no el fuente); `fact_metas.periodo` =
  `date_trunc('month', to_date(periodo,'YYYY-MM'))`.
- `dbt test` corre `unique/not_null` en claves, `relationships` hecho→dimensión,
  `accepted_values` (canal, pago, estado, tipo cliente, unidad, motivo),
  `freshness` de sources y los 2 singulares (0 filas = pasa).

## Etapa 3 — Validaciones SQL (`sql/validaciones.sql`, `search_path=marts,…`)

### Estructura del archivo

| Bloque | Consultas | Naturaleza |
|---|---|---|
| V1 conteos raw↔marts | 4 (`V1a` venta, `V1b` detalle, `V1c` inventario, `V1d` devoluciones) | informativas (par `en_raw`/`en_marts`, ej. `1200`/`1200`) |
| V2 huérfanos | 3 (ventas/inventario/devoluciones) | informativas (esperado `0`) |
| V3 duplicados/nulos | 4 (PK `fact_ventas`, nulos en claves, PKs de las 3 dims, PK compuesta inventario) | informativas (esperado `0`) |
| Bloque `DO` | 1 | **duro**: suma los 4 controles clave y `RAISE EXCEPTION` si `n > 0` → `psql -v ON_ERROR_STOP=1` sale ≠ 0 → tarea en rojo |
| A1–A6 analíticas | 6 | informativas (siempre exit 0) |

### Cómo está escrita cada consulta (patrones)

- **V1**: escalar contra escalar, con etiqueta para leer el log:
  `SELECT 'V1a_venta', (SELECT count(*) FROM raw.venta), (SELECT count(DISTINCT id_venta) FROM fact_ventas);`
  (`DISTINCT` porque el grano de marts es la *línea*, no la cabecera.)
- **V2**: anti-join con `NOT EXISTS` **por dimensión unidos con `OR`** (un hecho
  es huérfano si falla *cualquiera*): ej. `fact_ventas` valida sus 4 FK
  (`producto_sk/cliente_sk/sucursal_sk/fecha_fk`) en una sola pasada.
- **V3**: duplicados con `GROUP BY <clave> HAVING count(*) > 1` (en dims, las 3
  PK unidas con `UNION ALL` en una sola consulta); nulos con `IS NULL` en cadena
  `OR` sobre las 5 columnas clave de `fact_ventas`.
- **Bloque duro**: repite los 4 controles mínimos (huérfanos ventas+inventario,
  duplicados y nulos de `fact_ventas`), los suma en `n` y falla con el total.
  Es deliberadamente más estricto que informativo: es el portón de calidad.
- **A1/A2**: `JOIN fact_ventas→dim_fecha→dim_producto`, filtro
  `estado='COMPLETADA'` (las ANULADA/PENDIENTE se conservan en el DW por
  trazabilidad pero no suman venta), agregación mes×marca/categoría.
- **A3**: top 10 por `sum(subtotal)` con `LIMIT 10` (resultado real validado:
  Palomitas/SaborMax Q19,516).
- **A4**: foto del `max(fecha_corte)` + flags precalculados (`flag_stock_bajo
  OR flag_vencido`) — la consulta es trivial porque la regla vive en `int_*`.
- **A5**: `fact_metas LEFT JOIN` ventas reales agregadas a mes
  (`date_trunc('month', fecha_fk)`), `% = 100*real/meta` con
  `nullif(meta,0)` anti-división-por-cero y `coalesce(real,0)` para meses sin venta.
- **A6**: `GROUP BY motivo` sobre `fact_devoluciones` (conserva el motivo como
  dimensión degenerada a propósito).

### Resultados esperados (corrida validada)

V1 iguales (1200/3209/3840/80), V2 = V3 = 0, `NOTICE: Controles duros OK`,
A1–A6 con filas coherentes. Ante cualquier `EXCEPTION`, ver el mensaje
(`% filas huérfanas/duplicadas/nulas`) y rastrear hacia atrás por capas:
marts → intermediate → staging → raw → fuente (cada capa conserva las claves
naturales para el diagnóstico).
