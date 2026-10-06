"""SG-Food · DAG principal ELT (Fase 4).

Secuencia:
check_conexiones -> extract_load_db -> extract_load_csv -> validar_conteos_raw
  -> dbt_run_staging -> dbt_run_intermediate -> dbt_run_marts -> dbt_test
  -> validaciones_sql -> dbt_docs_generate

Conexiones: el warehouse se resuelve solo con variables del `.env`
(DBT_HOST/DBT_PORT/POSTGRES_*), disponibles en el contenedor. No requiere
crear Airflow Connections en la UI. Schedule parametrizable con SGFOOD_SCHEDULE.
"""

import logging
import os
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.python import PythonOperator

log = logging.getLogger(__name__)

SCRIPTS_DIR = "/opt/airflow/scripts"
CSV_DIR = "/opt/airflow/raw-data"
DBT_PROJECT_DIR = os.getenv("DBT_PROJECT_DIR", "/opt/airflow/dbt")
DBT_PROFILES_DIR = os.getenv("DBT_PROFILES_DIR", "/opt/airflow/dbt")
# --profiles-dir es flag POR COMANDO (después del subcomando), no global.
# `dbt --profiles-dir X run` falla con "No such option".
DBT_BIN = f"cd {DBT_PROJECT_DIR} && dbt"
DBT_FLAGS = f"--profiles-dir {DBT_PROFILES_DIR}"
SCHEDULE = os.getenv("SGFOOD_SCHEDULE", "@daily")


def _fallo_visible(context):
    ti = context["task_instance"]
    log.error(
        "FALLO %s.%s (run %s, intento %s)",
        ti.dag_id,
        ti.task_id,
        context["run_id"],
        ti.try_number,
    )


def check_conexiones():
    """Verifica env mínima y conexión al warehouse (SELECT 1)."""
    import psycopg2

    faltan = [
        v for v in ("POSTGRES_PASSWORD", "POSTGRES_WAREHOUSE_DB") if not os.getenv(v)
    ]
    if faltan:
        raise RuntimeError(f"Variables faltantes en el entorno: {faltan}")
    conn = psycopg2.connect(
        host=os.getenv("DBT_HOST", "postgres"),
        port=int(os.getenv("DBT_PORT", "5432")),
        dbname=os.getenv("POSTGRES_WAREHOUSE_DB"),
        user=os.getenv("POSTGRES_USER", "airflow"),
        password=os.getenv("POSTGRES_PASSWORD"),
        connect_timeout=10,
    )
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT 1;")
    finally:
        conn.close()
    log.info("check_conexiones OK: warehouse existente y accesible")


with DAG(
    dag_id="sgfood_elt",
    description="ELT SG-Food: Python (raw) + dbt (staging/intermediate/marts) + validaciones",
    start_date=datetime(2026, 1, 1),
    schedule=SCHEDULE,
    catchup=False,
    max_active_runs=1,
    default_args={
        "owner": "sgfood",
        "retries": 2,
        "retry_delay": timedelta(minutes=5),
        "on_failure_callback": _fallo_visible,
    },
    tags=["sgfood", "elt"],
) as dag:

    check_conexiones = PythonOperator(
        task_id="check_conexiones",
        python_callable=check_conexiones,
    )

    extract_load_db = BashOperator(
        task_id="extract_load_db",
        bash_command=f"python3 {SCRIPTS_DIR}/extract_load_db.py",
    )

    extract_load_csv = BashOperator(
        task_id="extract_load_csv",
        bash_command=f"python3 {SCRIPTS_DIR}/extract_load_csv.py --data-dir {CSV_DIR}",
    )

    validar_conteos_raw = BashOperator(
        task_id="validar_conteos_raw",
        bash_command=f"python3 {SCRIPTS_DIR}/verify_counts.py --data-dir {CSV_DIR}",
    )

    dbt_run_staging = BashOperator(
        task_id="dbt_run_staging",
        bash_command=f"{DBT_BIN} run {DBT_FLAGS} --select staging",
    )

    dbt_run_intermediate = BashOperator(
        task_id="dbt_run_intermediate",
        bash_command=f"{DBT_BIN} run {DBT_FLAGS} --select intermediate",
    )

    dbt_run_marts = BashOperator(
        task_id="dbt_run_marts",
        bash_command=f"{DBT_BIN} run {DBT_FLAGS} --select marts",
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"{DBT_BIN} test {DBT_FLAGS}",
    )

    # validaciones.sql ya incluye bloques DO que lanzan EXCEPTION si hay
    # huérfanos/duplicados/nulos en claves -> psql sale != 0 -> tarea en rojo.
    validaciones_sql = BashOperator(
        task_id="validaciones_sql",
        bash_command=(
            "PGPASSWORD=$POSTGRES_PASSWORD psql -h $DBT_HOST -p $DBT_PORT "
            "-U $POSTGRES_USER -d $POSTGRES_WAREHOUSE_DB "
            "-v ON_ERROR_STOP=1 -f /opt/airflow/sql/validaciones.sql"
        ),
    )

    dbt_docs_generate = BashOperator(
        task_id="dbt_docs_generate",
        bash_command=f"{DBT_BIN} docs generate {DBT_FLAGS}",
    )

    (
        check_conexiones
        >> extract_load_db
        >> extract_load_csv
        >> validar_conteos_raw
        >> dbt_run_staging
        >> dbt_run_intermediate
        >> dbt_run_marts
        >> dbt_test
        >> validaciones_sql
        >> dbt_docs_generate
    )
