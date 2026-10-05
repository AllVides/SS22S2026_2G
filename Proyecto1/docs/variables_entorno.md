# Variables de entorno — qué configura cada una

Toda la autenticación y conexión vive en `.env` (commiteado a propósito:
proyecto de curso con valores locales). `.env.example` es la plantilla con
secretos como `cambiar_*`. Regla de oro: **ningún secreto hardcodeado en
código** — `docker-compose.yml`, `dbt/profiles.yml` y `scripts/*.py` solo
leen entorno.

Cómo fluyen (quién consume qué):

```
.env ─┬─ docker-compose.yml ─┬─ postgres (POSTGRES_*)
      │                      ├─ AIRFLOW__DATABASE__SQL_ALCHEMY_CONN (construida)
      │                      ├─ contenedores Airflow (env_file + environment)
      │                      └─ contenedor dbt (env_file + environment)
      ├─ dbt/profiles.yml (env_var: POSTGRES_*, DBT_*)
      └─ scripts/*.py (POSTGRES_* + DBT_HOST/DBT_PORT, override PGHOST/...)
```

## PostgreSQL

| Variable | Ejemplo | Consume | Detalle |
|---|---|---|---|
| `POSTGRES_USER` | `airflow` | postgres, compose (conn Airflow), dbt (`user`), scripts (`PGUSER`) | Rol dueño de todo. Cambiarlo exige recrear el volumen (`down -v`) porque el rol se crea al inicializar |
| `POSTGRES_PASSWORD` | `airflow123` | todos los anteriores (`pass`) | Requerida por `scripts/*.py` (aborta sin ella). Rotarla = recrear volumen + actualizar `.env` |
| `POSTGRES_DB` | `airflow` | postgres (`POSTGRES_DB`), compose (conn metadata) | **Solo metadata de Airflow.** Nunca apuntar dbt ni fuentes aquí |
| `POSTGRES_PORT` | `5432` | compose (`ports`) | Puerto publicado al host. En conflicto: cambiarlo (dbt/scripts dentro de contenedores usan `DBT_PORT`, no este) |
| `POSTGRES_WAREHOUSE_DB` | `sgfood` | `init-db/01` (la crea), `init-db/02` (la siembra), dbt (`dbname` vía `env_var`), scripts (`PGDATABASE`) | Datos de negocio: OLTP (`oltp_sgfood`) + DW (`raw/staging/marts`). Crearla a mano si el volumen ya existía (ver `AGENTS.md`) |

## Airflow: imagen y usuario

| Variable | Ejemplo | Detalle |
|---|---|---|
| `AIRFLOW_IMAGE_NAME` | `apache/airflow:2.10.5-python3.11` | Base + tag de la imagen custom (`Dockerfile.airflow`). Cambiar versión = `build` + `airflow-init` + recrear |
| `AIRFLOW_UID` | `1000` | **`id -u` del host.** `entrypoint-airflow.sh` renombra `airflow` a este UID en runtime y baja con `setpriv`: los archivos en volúmenes quedan con tu usuario y todo `airflow` CLI tiene username (exigido en 2.10+). **Única variable dependiente de la máquina**; cambiarla = solo `up -d --force-recreate`, sin rebuild. Default `1000`; ausente = `50000` (upstream puro) |
| `AIRFLOW_GID` | `0` | Requerido por la imagen oficial. No tocar |

## Airflow: ejecutor y webserver

| Variable | Ejemplo | Detalle |
|---|---|---|
| `AIRFLOW_EXECUTOR` | `LocalExecutor` | Sin Redis/Celery. No agregar workers |
| `AIRFLOW_WEBSERVER_PORT` | `8080` | UI en `http://localhost:8080`. En conflicto: cambiarlo (mapeo `${...}:8080`) |

## Airflow: seguridad (`AIRFLOW_FERNET_KEY`, `AIRFLOW_WEBSERVER_SECRET_KEY`)

Claves generadas una vez y estables: la primera cifra conexiones/variables en la
metadata; la segunda firma sesiones de la UI. **Si cambian con volumen existente**,
las conexiones cifradas dejan de leerse (re-generar o `down -v`). Generar con:

```bash
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
python3 -c "import secrets; print(secrets.token_hex(16))"
```

## Airflow: admin (`AIRFLOW_ADMIN_*`)

`AIRFLOW_ADMIN_USER/PASSWORD/FIRSTNAME/LASTNAME/EMAIL` → el compose los mapea a
`_AIRFLOW_WWW_USER_*` y `airflow-init` crea el rol Admin (idempotente: si existe,
lo omite). Solo se usan en `airflow-init`; cambiar la password después requiere
hacerlo por UI/CLI, no basta editar el `.env`.

## Airflow: comportamiento (`AIRFLOW__CORE__*`)

`LOAD_EXAMPLES=False` (sin DAGs de ejemplo), `DAGS_ARE_PAUSED_AT_CREATION=True`
(el DAG nace pausado y se dispara manual — así lo pide la entrega de evidencias),
`LOAD_DEFAULT_CONNECTIONS=False` (el warehouse se resuelve por entorno, no por
Connections de UI).

## SG-Food: `SGFOOD_SCHEDULE=@daily`

Schedule del DAG `sgfood_elt` (lee `os.getenv` en el DAG). `catchup=False`:
al despausar no reprocesa el pasado. Para desarrollo usar `@once` o disparo manual.

## dbt (`DBT_*`)

| Variable | Ejemplo | Detalle |
|---|---|---|
| `DBT_IMAGE_NAME` | `ghcr.io/dbt-labs/dbt-postgres:1.9.latest` | Contenedor CLI (`sleep infinity`). A la par del adapter (`1.9.1`) |
| `DBT_HOST` / `DBT_PORT` | `postgres` / `5432` | Host **intra-contenedores**. Fuera de Docker (dbt local): `DBT_HOST=localhost DBT_PORT=<POSTGRES_PORT>` |
| `DBT_SCHEMA` | `analytics` | Schema *fallback* del target `dev`. Los modelos usan `+schema` por capa vía `generate_schema_name` (`staging/intermediate/marts`), así que este valor casi no se usa |
| `DBT_THREADS` | `4` | Paralelismo de `dbt build`. Subirlo con fuentes pequeñas no ayuda; 4 está bien |

La autenticación dbt **reutiliza** `POSTGRES_USER/PASSWORD/WAREHOUSE_DB`
(no hay `DBT_USER/DBT_PASSWORD`: no duplicar credenciales).

## `TZ=America/Guatemala`

UTC-6 sin horario de verano. Afecta logs y `start_date`/schedule del DAG.

## Overrides de los scripts (no están en `.env`, son por invocación)

`PGHOST/PGPORT/PGUSER/PGPASSWORD/PGDATABASE` tienen **precedencia** sobre
`DBT_HOST/DBT_PORT/POSTGRES_*` en `scripts/*.py`. Sirven para correr desde el
host: `set -a; source .env; set +a` y luego `PGHOST=localhost PGPORT=5432`.
También: `OLTP_SCHEMA`/`RAW_SCHEMA` (default `oltp_sgfood`/`raw`) y `CSV_DIR`.
