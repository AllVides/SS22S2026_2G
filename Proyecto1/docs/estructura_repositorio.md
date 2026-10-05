# Estructura del repositorio — qué hay en cada carpeta

> Convención: nombres en español + prefijos dbt (`stg_/int_/dim_/fact_`).
> `raw-data/` equivale a `data/` del enunciado; no renombrar `dags/` ni `dbt/`.

```
.
├── README.md / AGENTS.md / .gitattributes
├── docker-compose.yml      # 5 servicios: postgres, airflow-init/webserver/scheduler, dbt
├── Dockerfile.airflow      # Airflow + dbt-postgres + psycopg2 (imagen portable)
├── requirements.txt        # dbt-core==1.9.0, dbt-postgres==1.9.1, psycopg2-binary
├── .env / .env.example     # TODA la configuración (ver docs/variables_entorno.md)
├── sql/                    # DDL del DW + validaciones end-to-end
├── scripts/                # EL Python (extracción/carga) + entrypoint Airflow
├── dags/                   # DAG principal + DAG auxiliar de desarrollo
├── dbt/                    # Proyecto dbt (staging → intermediate → marts)
├── docs/                   # Diseño y documentación (este archivo y demás)
├── raw-data/               # Fuentes (solo lectura desde contenedores)
├── init-db/                # Seed inicial de postgres (solo volumen nuevo)
├── evidencias/             # Capturas de la corrida en verde
└── logs/ plugins/          # Montajes de Airflow (logs generados / vacío)
```

## `sql/` — DDL y validaciones (se ejecutan contra `sgfood`)

| Archivo | Contenido |
|---|---|
| `ddl_dw.sql` | **Parte A (real):** `CREATE SCHEMA raw/staging/marts` + 12 tablas `raw` espejo 1:1 de cada fuente, **sin PK/FK/CHECK** (raw acepta datos sucios) y con `_loaded_at TIMESTAMPTZ DEFAULT now()` + `_source TEXT` en todas. **Parte B (referencia, `IF NOT EXISTS`):** 4 dims + 4 facts con PK/FK/índices como contrato del modelo (el dueño real es dbt). Todo re-ejecutable. Aplicar con `docker compose exec -T postgres psql -U airflow -d sgfood < sql/ddl_dw.sql` |
| `validaciones.sql` | 17 `SELECT` + 1 bloque `DO`: V1 (4 conteos raw↔marts), V2 (3 huérfanos), V3 (4 duplicados/nulos), bloque duro con `RAISE EXCEPTION`, A1–A6 analíticas. Detalle consulta por consulta en `docs/flujo_elt.md` |

## `scripts/` — EL Python + arranque Airflow

| Archivo | Contenido |
|---|---|
| `extract_load_db.py` | 7 tablas `oltp_sgfood` → `raw` con `TRUNCATE + INSERT-SELECT` (una transacción por tabla, rollback parcial). Limpieza: `NULLIF(TRIM(col::TEXT),'')` en textos, `CAST` directo en el resto. `--tables`, `--source-schema/--target-schema`, `--dry-run`. Exit 1 ante fallos |
| `extract_load_csv.py` | 5 CSV → `raw` con `utf-8-sig` (BOM). Valida columnas exactas **antes** de tocar la DB (*fail-fast*), luego `TRUNCATE + execute_values` por lotes. `--files`, `--data-dir`, `--dry-run`. No carga `casos_calidad_opcionales.csv` (casos de test) ni el `.xlsx` (catálogo) |
| `verify_counts.py` | Compara `oltp_sgfood.*` vs `raw.*` y filas de CSV vs `raw.*`; exit 1 si difieren |
| `entrypoint-airflow.sh` | Wrapper de arranque: renombra `airflow` a `$AIRFLOW_UID` con `usermod` y baja privilegios con `setpriv` antes del entrypoint oficial (ver `docs/variables_entorno.md`) |

## `dags/` — orquestación

| Archivo | Contenido |
|---|---|
| `sgfood_elt_dag.py` | DAG `sgfood_elt`: 10 tareas lineales (`check_conexiones → extract_load_db → extract_load_csv → validar_conteos_raw → dbt_run_staging → dbt_run_intermediate → dbt_run_marts → dbt_test → validaciones_sql → dbt_docs_generate`). `retries=2`, `retry_delay=5min`, `on_failure_callback`, `schedule` desde `SGFOOD_SCHEDULE`, `catchup=False`, `max_active_runs=1`. dbt por selector FQN (`run --select staging`, con `--profiles-dir` **después** del subcomando); `validaciones_sql` vía `psql -v ON_ERROR_STOP=1` (el `RAISE EXCEPTION` deja la tarea en rojo) |
| `dbt_build.py` | DAG auxiliar de desarrollo (`dbt debug` → `dbt build`). No forma parte del flujo oficial |

## `dbt/` — transformación y pruebas (perfil `sgfood`, target `dev`)

| Ruta | Contenido |
|---|---|
| `dbt_project.yml` | `staging`/`intermediate` = views, `marts` = tables (+schema por capa), seeds → `raw` |
| `profiles.yml` | Conexión 100% por `env_var` del `.env` (sin secretos). También montado en `/root/.dbt/profiles.yml` del contenedor dbt |
| `macros/generate_schema_name.sql` | Cada capa va a su schema (`staging/intermediate/marts`); `intermediate` lo autocrea dbt (no está en el DDL) |
| `models/staging/` | `sources.yml` (fuente `raw`, 12 tablas, `freshness` sobre `_loaded_at`: warn 48h / error 720h) + 12 `stg_*` (`source()`, casteo/limpieza; `stg_metas_ventas` conserva `periodo` texto) + `schema.yml` (`unique/not_null/accepted_values` con valores reales) |
| `models/intermediate/` | `int_ventas_detalle` (joins + `subtotal_calculado`, todos los estados), `int_inventario_estado` (flags + `dias_para_vencer`), `int_devoluciones` (sucursal heredada de la venta) + `schema.yml` |
| `models/marts/` | `dim_fecha` (`generate_series` + mes en español sin locale), `dim_producto/cliente/sucursal` (surrogate `row_number()`, SCD1), `fact_ventas/inventario/devoluciones/metas` + `schema.yml` (`relationships` hecho→dimensión) |
| `tests/` | 2 singulares ligados a `casos_calidad_opcionales.csv`: `assert_subtotal_consistente` (fuente vs recalculado ±1ctv) y `assert_devolucion_no_excede_venta` (devuelto ≤ vendido por venta+producto). Pasan con 0 filas |
| `seeds/ snapshots/ macros/ plugins/` | Reservados/vacíos (seeds → schema `raw` si se usan) |

## `docs/` — documentación

| Archivo | Contenido |
|---|---|
| `diseno_dw.md` | Diagrama Mermaid del estrella, granos/claves/relaciones y 7 decisiones justificadas |
| `estructura_repositorio.md` | Este archivo: contenido de cada carpeta |
| `variables_entorno.md` | El `.env` variable por variable: quién la consume y cuándo cambiarla |
| `flujo_elt.md` | El flujo ELT etapa por etapa con el SQL que se ejecuta + validaciones explicadas |

## `raw-data/` — fuentes (montaje solo-lectura en los 3 servicios)

| Archivo | Contenido | Destino `raw` |
|---|---|---|
| `sgfood_oltp.sql` | DDL + INSERTs OLTP (schema `oltp_sgfood`): 6 sucursales, 8 categorías, 10 marcas, 80 productos, 250 clientes, 1200 ventas, 3209 líneas (2026-01-01 → 2026-08-31) | 7 tablas |
| `inventario_bodega.csv` | 3840 filas: corte×sucursal×producto (stock, lote, vencimiento) | `raw.inventario_bodega` |
| `devoluciones.csv` | 80 filas (sin sucursal: se hereda de la venta) | `raw.devoluciones` |
| `metas_ventas.csv` | 48 filas: periodo `YYYY-MM` × sucursal | `raw.metas_ventas` |
| `promociones.csv` | 30 campañas por categoría | `raw.promociones` (reserva) |
| `proveedores_precios.csv` | 103 costos por producto | `raw.proveedores_precios` (reserva) |
| `casos_calidad_opcionales.csv` | 10 incidencias documentadas → **casos de test**, no se cargan | — (Fase 3) |
| `catalogo_insumos_sgfood.xlsx` | Catálogo descriptivo de fuentes, no datos → no se carga | — |

Todos los CSV traen **BOM** (leer con `utf-8-sig`) y están limpios de nulos;
los casos sucios viven solo como documentación para los tests.

## `init-db/` · `evidencias/` · resto

| Ruta | Contenido |
|---|---|
| `init-db/01-create-warehouse-db.sh` | Crea `sgfood` si no existe (heredoc + `\gexec`; `\gexec` **no** funciona con `psql -c`) |
| `init-db/02-load-oltp.sh` | Carga `sgfood_oltp.sql` en `sgfood`. Ambos corren **solo con volumen nuevo**; si no, crear/cargar a mano (ver `AGENTS.md`) |
| `evidencias/CHECKLIST.md` | 5 capturas exigidas (graph verde, tiempos, `dbt test`, `validaciones_sql`, analíticas) + comandos CLI de respaldo |
| `Dockerfile.airflow` | `apache/airflow:2.10.5-python3.11` + `requirements.txt`; termina en `USER root` para que el wrapper pueda hacer `usermod` (imagen portable, UID en runtime) |
| `requirements.txt` | `dbt-core==1.9.0` + `dbt-postgres==1.9.1` fijos (1.9.4 no existe; el pin laxo del adapter resolvía core 1.12 incompatible) + `psycopg2-binary` |
| `.env` / `.env.example` | Configuración total / plantilla sin secretos (`.env` commiteado a propósito) |
| `logs/` | Logs de Airflow (generados, ignorados por git). Archivos con dueño del host gracias a `AIRFLOW_UID` |
