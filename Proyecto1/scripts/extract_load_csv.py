"""SG-Food · Extracción y carga CSV -> raw (Fase 2).

Lee los 5 CSV de datos con `encoding="utf-8-sig"` (todos traen BOM) y los carga
en el schema `raw` con limpieza técnica mínima (strip, '' -> NULL).
Estrategia TRUNCATE + LOAD: idempotente y adecuada porque los archivos son
pequeños (máx. ~3.8k filas) y la recarga completa es determinista.

Archivos que NO se cargan (decisión documentada):
- `casos_calidad_opcionales.csv`: no son datos, son la lista de incidencias
  que los tests dbt deben cubrir (Fase 3).
- `catalogo_insumos_sgfood.xlsx`: catálogo descriptivo de las fuentes, no datos.

Configuración: solo variables de entorno (ver extract_load_db.py).
Uso:
  python3 scripts/extract_load_csv.py [--files inventario_bodega] [--dry-run]
  (--data-dir default: ./raw-data; en Airflow: /opt/airflow/raw-data)
"""

import argparse
import csv
import logging
import os
import sys

# NOTA: psycopg2 se importa dentro de conectar()/cargar_csv() para que --help
# y --dry-run funcionen sin la librería instalada.

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger("extract_load_csv")

ENCODING = "utf-8-sig"  # todos los CSV traen BOM
TARGET_SCHEMA = os.getenv("RAW_SCHEMA", "raw")

# archivo -> (tabla raw, columnas esperadas en orden)
ARCHIVOS = {
    "inventario_bodega": (
        "inventario_bodega",
        [
            "fecha_corte",
            "id_sucursal",
            "id_producto",
            "stock_disponible",
            "stock_minimo",
            "stock_maximo",
            "lote",
            "fecha_vencimiento",
        ],
    ),
    "devoluciones": (
        "devoluciones",
        ["id_devolucion", "fecha", "id_venta", "id_producto", "cantidad", "motivo"],
    ),
    "metas_ventas": (
        "metas_ventas",
        ["periodo", "id_sucursal", "meta_ventas", "meta_unidades"],
    ),
    "promociones": (
        "promociones",
        [
            "id_promocion",
            "nombre",
            "fecha_inicio",
            "fecha_fin",
            "id_categoria",
            "porcentaje_descuento",
        ],
    ),
    "proveedores_precios": (
        "proveedores_precios",
        [
            "id_proveedor",
            "proveedor",
            "id_producto",
            "costo_proveedor",
            "plazo_dias",
            "fecha_vigencia",
        ],
    ),
}


def conectar():
    try:
        import psycopg2
    except ImportError:
        raise RuntimeError("falta psycopg2 (pip install psycopg2-binary)")
    if not os.getenv("POSTGRES_PASSWORD"):
        raise RuntimeError("POSTGRES_PASSWORD no definida en el entorno")
    return psycopg2.connect(
        host=os.getenv("PGHOST", os.getenv("DBT_HOST", "postgres")),
        port=int(os.getenv("PGPORT", os.getenv("DBT_PORT", "5432"))),
        dbname=os.getenv("PGDATABASE", os.getenv("POSTGRES_WAREHOUSE_DB", "sgfood")),
        user=os.getenv("PGUSER", os.getenv("POSTGRES_USER", "airflow")),
        password=os.getenv("POSTGRES_PASSWORD"),
    )


def leer_csv(path, columnas_esperadas):
    """Lee el CSV, valida columnas exactas y aplica limpieza mínima.

    Lanza ValueError/FileNotFoundError con mensaje claro si algo no cuadra.
    """
    with open(path, encoding=ENCODING, newline="") as fh:
        lector = csv.DictReader(fh)
        reales = list(lector.fieldnames or [])
        faltan = [c for c in columnas_esperadas if c not in reales]
        sobran = [c for c in reales if c not in columnas_esperadas]
        if faltan or sobran:
            raise ValueError(
                f"{path}: columnas inválidas " f"(faltan={faltan}, sobran={sobran})"
            )
        filas = []
        for i, reg in enumerate(lector, start=2):
            filas.append(
                [
                    None if (reg[c] is None or reg[c].strip() == "") else reg[c].strip()
                    for c in columnas_esperadas
                ]
            )
    if not filas:
        raise ValueError(f"{path}: sin filas de datos")
    return filas


def cargar_csv(conn, tabla, columnas, filas, fuente):
    """TRUNCATE + INSERT por lotes en una transacción. Devuelve n filas."""
    from psycopg2.extras import execute_values

    cols = ", ".join(columnas)
    with conn.cursor() as cur:
        cur.execute(f"TRUNCATE TABLE {TARGET_SCHEMA}.{tabla};")
        execute_values(
            cur,
            f"INSERT INTO {TARGET_SCHEMA}.{tabla} ({cols}, _source) " f"VALUES %s",
            [(tuple(f) + (fuente,)) for f in filas],
        )
    conn.commit()
    # no se uso cur.rowcount porque execute_values inserta por páginas
    # (page_size=100) y rowcount solo refleja la última. Si no hubo excepción,
    # todas las filas se insertaron: se reporta len(filas) y verify_counts.py
    # confirma contra la DB.
    return len(filas)


def main():
    ap = argparse.ArgumentParser(description="Carga CSV -> raw (TRUNCATE + LOAD).")
    ap.add_argument(
        "--files",
        default=",".join(ARCHIVOS),
        help="Subconjunto (nombres sin .csv, separados por comas).",
    )
    ap.add_argument(
        "--data-dir",
        default=os.getenv("CSV_DIR", "raw-data"),
        help="Directorio de CSV (default: raw-data).",
    )
    ap.add_argument(
        "--dry-run",
        action="store_true",
        help="Valida columnas y cuenta filas sin conectar ni cargar.",
    )
    args = ap.parse_args()

    pedidos = [f.strip() for f in args.files.split(",") if f.strip()]
    desconocidos = [f for f in pedidos if f not in ARCHIVOS]
    if desconocidos:
        log.error(
            "Archivos desconocidos: %s (válidos: %s)", desconocidos, sorted(ARCHIVOS)
        )
        return 1

    # Fase 1: leer y validar todo ANTES de tocar la DB (fail-fast)
    lotes = {}
    try:
        for nombre in pedidos:
            tabla, columnas = ARCHIVOS[nombre]
            path = os.path.join(args.data_dir, nombre + ".csv")
            filas = leer_csv(path, columnas)
            lotes[nombre] = (tabla, columnas, filas)
            log.info(
                "%-20s OK %d filas, columnas válidas%s",
                nombre + ".csv",
                len(filas),
                " [dry-run]" if args.dry_run else "",
            )
    except FileNotFoundError as e:
        log.error("Archivo no encontrado: %s", e.filename)
        return 1
    except ValueError as e:
        log.error("Validación fallida: %s", e)
        return 1
    if args.dry_run:
        return 0

    # Fase 2: cargar
    try:
        conn = conectar()
    except Exception as e:
        log.exception("No se pudo conectar al warehouse: %s", e)
        return 1

    total, fallos = 0, 0
    try:
        for nombre in pedidos:
            tabla, columnas, filas = lotes[nombre]
            try:
                n = cargar_csv(conn, tabla, columnas, filas, nombre + ".csv")
                total += n
                log.info(
                    "OK %-20s %d filas (-> %s.%s)",
                    nombre + ".csv",
                    n,
                    TARGET_SCHEMA,
                    tabla,
                )
            except Exception:
                conn.rollback()
                fallos += 1
                log.exception("FALLO %s (rollback, continúa con el resto)", nombre)
    finally:
        conn.close()

    if fallos:
        log.error("%d archivo(s) fallaron, %d filas cargadas", fallos, total)
        return 1
    log.info("Carga CSV->raw completa: %d filas en %d archivos", total, len(pedidos))
    return 0


if __name__ == "__main__":
    sys.exit(main())
