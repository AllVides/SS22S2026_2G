"""SG-Food · Extracción y carga OLTP -> raw (Fase 2).

Lee las 7 tablas de `oltp_sgfood` y las carga en el schema `raw` con limpieza
técnica mínima (TRIM, '' -> NULL, CAST seguro). Estrategia TRUNCATE + LOAD:
idempotente por construcción (re-ejecutar deja el mismo estado) y adecuada
porque las fuentes son pequeñas y la recarga completa es determinista.

Configuración: solo variables de entorno (sin credenciales hardcodeadas).
  Dentro de contenedores: basta `DBT_HOST/DBT_PORT/POSTGRES_*` del `.env`.
  Desde el host: exportar `PGHOST=localhost PGPORT=<POSTGRES_PORT> ...`
  (p. ej. `set -a; source .env; set +a` y luego `PGHOST=localhost`).

Uso:
  python3 scripts/extract_load_db.py [--tables venta,cliente] [--dry-run]

Salida: exit 0 si todo cargó (con conteos en el log), exit 1 ante cualquier
fallo — Airflow detecta el fallo por el código de salida.
"""

import argparse
import logging
import os
import sys

# psycopg2 se importa dentro de conectar() para que --help y --dry-run
# funcionen sin la librería instalada (solo la carga real la requiere).

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger("extract_load_db")

SOURCE_SCHEMA = os.getenv("OLTP_SCHEMA", "oltp_sgfood")
TARGET_SCHEMA = os.getenv("RAW_SCHEMA", "raw")

# tabla -> columnas espejo (mismo orden en origen y destino)
TABLAS = {
    "sucursal": ["id_sucursal", "nombre", "ciudad", "departamento"],
    "categoria": ["id_categoria", "nombre"],
    "marca": ["id_marca", "nombre"],
    "producto": [
        "id_producto",
        "sku",
        "nombre",
        "id_categoria",
        "id_marca",
        "unidad_medida",
        "costo_base",
        "precio_lista",
        "activo",
    ],
    "cliente": [
        "id_cliente",
        "nit",
        "nombre",
        "tipo_cliente",
        "municipio",
        "departamento",
        "fecha_alta",
    ],
    "venta": [
        "id_venta",
        "fecha",
        "id_cliente",
        "id_sucursal",
        "canal",
        "metodo_pago",
        "estado",
    ],
    "venta_detalle": [
        "id_detalle",
        "id_venta",
        "id_producto",
        "cantidad",
        "precio_unitario",
        "descuento",
        "subtotal",
    ],
}

# columnas de texto donde aplica TRIM + '' -> NULL (el resto se castea directo;
# un valor no casteable falla la tabla con error claro en el log)
TEXTO = {
    "nombre",
    "ciudad",
    "departamento",
    "sku",
    "unidad_medida",
    "nit",
    "tipo_cliente",
    "municipio",
    "canal",
    "metodo_pago",
    "estado",
}


def conectar():
    """Abre la conexión al warehouse. Requiere POSTGRES_USER/PASSWORD en entorno."""
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


def expr_limpia(col):
    if col in TEXTO:
        return f"NULLIF(TRIM({col}::TEXT), '') AS {col}"
    return col


def cargar_tabla(conn, tabla, columnas, src_schema, tgt_schema):
    """TRUNCATE + INSERT-SELECT con limpieza mínima. Una transacción por tabla."""
    origen = f"{src_schema}.{tabla}"
    destino = f"{tgt_schema}.{tabla}"
    select_cols = ", ".join(expr_limpia(c) for c in columnas)
    with conn.cursor() as cur:
        cur.execute(f"TRUNCATE TABLE {destino};")
        cur.execute(
            f"INSERT INTO {destino} ({', '.join(columnas)}, _source) "
            f"SELECT {select_cols}, '{origen}' FROM {origen};"
        )
        n = cur.rowcount
    conn.commit()
    return n


def main():
    ap = argparse.ArgumentParser(description="Carga OLTP -> raw (TRUNCATE + LOAD).")
    ap.add_argument(
        "--tables",
        default=",".join(TABLAS),
        help="Subconjunto separado por comas (default: todas).",
    )
    ap.add_argument(
        "--dry-run", action="store_true", help="Muestra el plan sin conectar ni cargar."
    )
    ap.add_argument("--source-schema", default=SOURCE_SCHEMA)
    ap.add_argument("--target-schema", default=TARGET_SCHEMA)
    args = ap.parse_args()

    pedidas = [t.strip() for t in args.tables.split(",") if t.strip()]
    desconocidas = [t for t in pedidas if t not in TABLAS]
    if desconocidas:
        log.error("Tablas desconocidas: %s (válidas: %s)", desconocidas, sorted(TABLAS))
        return 1

    if args.dry_run:
        for t in pedidas:
            log.info(
                "[dry-run] TRUNCATE+LOAD %s.%s <- %s.%s (%d cols)",
                args.target_schema,
                t,
                args.source_schema,
                t,
                len(TABLAS[t]),
            )
        return 0

    total = 0
    try:
        conn = conectar()
    except Exception as e:
        log.exception("No se pudo conectar al warehouse: %s", e)
        return 1

    fallos = 0
    try:
        for tabla in pedidas:
            try:
                n = cargar_tabla(
                    conn, tabla, TABLAS[tabla], args.source_schema, args.target_schema
                )
                total += n
                log.info(
                    "OK %-14s %d filas (%s -> %s)",
                    tabla,
                    n,
                    args.source_schema,
                    args.target_schema,
                )
            except Exception:
                conn.rollback()
                fallos += 1
                log.exception("FALLO tabla %s (rollback, continúa con el resto)", tabla)
    finally:
        conn.close()

    if fallos:
        log.error("%d tabla(s) fallaron, %d filas cargadas", fallos, total)
        return 1
    log.info("Carga OLTP->raw completa: %d filas en %d tablas", total, len(pedidas))
    return 0


if __name__ == "__main__":
    sys.exit(main())
