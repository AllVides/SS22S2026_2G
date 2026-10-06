# Evidencias de ejecución del flujo (Fase 4)

Estas capturas muestran que el pipeline `sgfood_elt` corrió completo y que los datos pasaron todas las validaciones.

**Cómo se ejecutó:** el DAG `sgfood_elt` está pausado por defecto, así que se disparó a mano desde la interfaz de Airflow con **Trigger DAG**. Después se esperó a que las 10 tareas terminaran en verde.

## Resumen

| #   | Evidencia                      | Tarea o etapa                                              | Qué demuestra                                              |
| --- | ------------------------------ | ---------------------------------------------------------- | ---------------------------------------------------------- |
| 1   | Extracción y carga a `raw`     | `extract_load_db`, `extract_load_csv`                      | Los datos de origen llegaron a `raw`.                      |
| 2   | Verificación de cargas a `raw` | `validar_conteos_raw`                                      | Las filas de origen coinciden con las de `raw`.            |
| 3   | Staging hasta marts            | `dbt_run_staging`, `dbt_run_intermediate`, `dbt_run_marts` | dbt construyó todas las capas del modelo.                  |
| 4   | Validaciones                   | `dbt_test`, `validaciones_sql`                             | Las pruebas de calidad pasaron.                            |
| 5   | Logs de validaciones SQL       | `validaciones_sql`                                         | Los controles V1, V2 y V3 dieron los resultados esperados. |
| 6   | Documentación de dbt           | `dbt_docs_generate`                                        | Se generó el catálogo y el mapa de dependencias.           |

---

## 1. Extracción y carga a `raw`

![Extracción y carga a raw](images/1%20extraccion%20y%20carga%20a%20raw.png)

**Tareas:** `extract_load_db` y `extract_load_csv`.

**Qué se ve:** las tareas terminaron en verde. `extract_load_db` copió las 7 tablas de `oltp_sgfood` y `extract_load_csv` cargó los 5 archivos CSV, ambos hacia el esquema `raw`.

## 2. Verificación de cargas a `raw`

![Verificación de cargas a raw](images/2%20verificacion%20cargas%20a%20raw.png)

**Tarea:** `validar_conteos_raw`.

**Qué se ve:** la comparación entre el origen y `raw`. Son 12 comparaciones y todas coinciden. Si hubiera alguna diferencia, la tarea saldría en rojo y el flujo se detendría.

## 3. Staging hasta marts

![Staging hasta marts](images/3%20stagin%20hasta%20mart.png)

**Tareas:** `dbt_run_staging`, `dbt_run_intermediate` y `dbt_run_marts`.

**Qué se ve:** dbt ejecutó las tres capas en orden:

- `staging`: 12 vistas.
- `intermediate`: 3 vistas.
- `marts`: 4 dimensiones y 4 tablas de hechos.

## 4. Validaciones

![Validaciones](images/4%20validaciones.png)

**Tareas:** `dbt_test` y `validaciones_sql`.

**Qué se ve:** las dos tareas de validación en verde. `dbt_test` corrió las 84 pruebas más 2 pruebas singulares (`unique`, `not_null`, `accepted_values`, `relationships`).

## 5. Logs de validaciones SQL

![Logs de validaciones SQL](images/5%20logs%20de%20validaciones%20sql.png)

**Tarea:** `validaciones_sql` (archivo `sql/validaciones.sql`).

**Qué se ve:** el resultado de los controles:

| Control                          | Resultado esperado               |
| -------------------------------- | -------------------------------- |
| **V1** Conteos `raw` y `marts`   | Iguales: 1200 / 3209 / 3840 / 80 |
| **V2** Registros huérfanos       | `0`                              |
| **V3** Duplicados y nulos        | `0`                              |
| **Bloque `DO`**                  | `NOTICE: Controles duros OK`     |
| **A1 a A6** Consultas analíticas | Devuelven filas con sentido      |

## 6. Documentación de dbt generada

![Documentación de dbt generada](images/6%20docu%20de%20dbt%20generada.png)

**Tarea:** `dbt_docs_generate`.

**Qué se ve:** la documentación web de dbt abierta en el navegador, con el diccionario de datos y el mapa de dependencias (lineage) de `raw` a `marts`. Se generó con 23 modelos, 84 pruebas y 12 fuentes.

Para volver a generarla, ver el punto 10 del manual de implementación (archivo `static_index.html`).

---

## Conclusión

El pipeline completo se ejecutó sin errores: las 10 tareas terminaron en verde, no se perdió ni se duplicó información entre `raw` y `marts`, y las validaciones no encontraron registros huérfanos, duplicados ni nulos en las claves.
