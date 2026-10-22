# Proyecto 2 — Análisis y predicción de viajes de taxi en Nueva York

**Universidad:** Universidad de San Carlos de Guatemala (USAC)  
**Curso:** Seminario de Sistemas 2  
**Proyecto:** Proyecto 2

## Introducción

Este proyecto utiliza el conjunto de datos **NYC Yellow Taxi Trips 2022** para aplicar técnicas de análisis de datos y aprendizaje automático con **Google BigQuery y BigQuery ML**. El trabajo comprende la exploración y evaluación de la calidad de los datos, el uso de consultas SQL y técnicas de optimización, el entrenamiento y comparación de modelos de **regresión lineal y árboles potenciados (XGBoost)**, y la presentación de resultados mediante un dashboard.

Para la visualización, los resultados obtenidos en BigQuery se organizaron en **Google Sheets** y luego se conectaron a **Data Studio (Looker Studio)**. La metodología, los resultados, las decisiones técnicas y las evidencias se encuentran desarrollados en los documentos de cada fase.

## Integrantes

| Nombre | Carné |
|---|---|
| Omar Alejandro Vides Esteban | 201709146 |
| Tobías Rafael Zamora Santos | 202010828 |

## Documentación por fases

| Fase | Descripción | Documentación |
|---|---|---|
| **1. Exploración inicial** | Estructura, volumen, valores nulos, estadísticas descriptivas y datos atípicos. | [README de la Fase 1](docs/README_Fase_1_Exploracion.md) |
| **2. Consultas y optimización** | Consultas analíticas, subconjuntos de datos, particionamiento, clustering y comparación de procesamiento. | [README de la Fase 2](docs/README_Fase_2_Optimizacion.md) |
| **3. Machine Learning** | Preparación de características, entrenamiento y evaluación de regresión lineal y XGBoost, y predicciones con datos de prueba. | [README de la Fase 3](docs/README_Fase_3_MachineLearning.md) |
| **4. Dashboard** | Visualizaciones exploratorias, comparación de modelos y predicciones, usando BigQuery → Google Sheets → Data Studio. | [README de la Fase 4](docs/README_Fase_4_Dashboard.md) |

## Dashboard interactivo

[**Ver el dashboard del Proyecto 2 en Data Studio**](https://datastudio.google.com/reporting/a35f0e0b-044f-4a87-9f8d-4cb9a5f1a2a4)

## Organización del repositorio

- [`ConsultasBigQuery/`](ConsultasBigQuery/) — scripts SQL organizados por fase.
- [`docs/`](docs/) — documentación detallada de las cuatro fases.
- [`images/`](images/) — capturas y evidencias de resultados.

> **Nota:** Las predicciones de tarifas se desarrollaron con datos de enero de 2022. El dashboard también incluye análisis exploratorios del dataset de 2022. Para detalles de alcance, limitaciones y resultados, consulta los README de cada fase.
