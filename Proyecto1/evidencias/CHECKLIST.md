# Evidencias — qué capturar y dónde guardar (Fase 4)

`sgfood_elt` debe correrse con trigger manual desde la UI (está pausado por
defecto). Disparar con *Trigger DAG* y esperar las 10 tareas en verde.

## Capturas (guardar en esta carpeta como PNG)

1. `dag_graph_verde.png` — Graph view del run completo en verde.
2. `dag_grid_tiempos.png` — Grid view con duraciones por tarea.
3. `dbt_test.png` — log de la tarea `dbt_test` (todos los tests en verde).
4. `validaciones_sql.png` — log de `validaciones_sql` (controles duros OK + A1–A6).
5. `consultas_resultados.png` — salida de `sql/validaciones.sql` (A1–A6) en
   psql/pgAdmin.

## Comandos de respaldo (si la UI no basta)

```bash
# Estado del DAG por CLI
docker compose exec airflow-scheduler airflow dags state sgfood_elt <run_id>
# Re-correr solo validaciones
docker compose exec -T postgres psql -U airflow -d sgfood -f sql/validaciones.sql
# Servir dbt docs (requiere exponer el target/ del contenedor dbt)
docker compose exec dbt dbt docs serve --project-dir /usr/app --port 8081
```
