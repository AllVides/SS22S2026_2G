"""DAG ejemplo: orquesta dbt (instalado en la imagen de Airflow).

El proyecto dbt está montado en /opt/airflow/dbt y la conexión usa las
variables del .env (DBT_HOST, POSTGRES_USER, POSTGRES_WAREHOUSE_DB, ...).
"""
import os
from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator

DBT_PROJECT_DIR = os.getenv("DBT_PROJECT_DIR", "/opt/airflow/dbt")
DBT_PROFILES_DIR = os.getenv("DBT_PROFILES_DIR", "/opt/airflow/dbt")

with DAG(
    dag_id="dbt_build",
    start_date=datetime(2026, 1, 1),
    schedule=None,
    catchup=False,
    tags=["dbt", "ejemplo"],
) as dag:
    dbt_debug = BashOperator(
        task_id="dbt_debug",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt debug --profiles-dir {DBT_PROFILES_DIR}",
    )

    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command=f"cd {DBT_PROJECT_DIR} && dbt build --profiles-dir {DBT_PROFILES_DIR}",
    )

    dbt_debug >> dbt_build
