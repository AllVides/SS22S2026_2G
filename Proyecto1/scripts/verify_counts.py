"""SG-Food · Verificación de conteos fuente vs. raw (Fase 2).

Compara, en la misma base `sgfood`:
- cada tabla `oltp_sgfood.*` contra `raw.*`;
- cada CSV de datos (filas en archivo) contra su tabla `raw.*`.

Uso:
  python3 scripts/verify_counts.py [--data-dir raw-data]
Salida: tabla comparativa; exit 0 si todo coincide, exit 1 si hay diferencias
o si falta alguna variable/conexión (apto para Airflow).
"""

import argparse
import csv
import logging
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from extract_load_csv import ARCHIVOS, ENCODING  # noqa: E402
from extract_load_db import TABLAS, conectar  # noqa: E402

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger("verify_counts")


def contar_archivo(path):
    with open(path, encoding=ENCODING, newline="") as fh:
        return sum(1 for _ in csv.DictReader(fh))


def main():
    ap = argparse.ArgumentParser(description="Verifica conteos fuente vs. raw.")
    ap.add_argument("--data-dir", default=os.getenv("CSV_DIR", "raw-data"))
    args = ap.parse_args()

    try:
        conn = conectar()
    except Exception as e:
        log.error("Sin conexión al warehouse: %s", e)
        return 1

    errores = 0
    try:
        with conn.cursor() as cur:
            for tabla in TABLAS:
                cur.execute(f"SELECT count(*) FROM oltp_sgfood.{tabla};")
                n_src = cur.fetchone()[0]
                cur.execute(f"SELECT count(*) FROM raw.{tabla};")
                n_raw = cur.fetchone()[0]
                ok = "OK " if n_src == n_raw else "DIFIERE"
                if n_src != n_raw:
                    errores += 1
                log.info("[%s] oltp %-14s %6d | raw %-14s %6d",
                         ok, tabla, n_src, tabla, n_raw)
            for nombre, (tabla, _) in ARCHIVOS.items():
                try:
                    n_src = contar_archivo(os.path.join(args.data_dir, nombre + ".csv"))
                except FileNotFoundError:
                    log.error("[FALTA] archivo %s.csv no encontrado", nombre)
                    errores += 1
                    continue
                cur.execute(f"SELECT count(*) FROM raw.{tabla};")
                n_raw = cur.fetchone()[0]
                ok = "OK " if n_src == n_raw else "DIFIERE"
                if n_src != n_raw:
                    errores += 1
                log.info("[%s] csv  %-14s %6d | raw %-14s %6d",
                         ok, nombre + ".csv", n_src, tabla, n_raw)
    finally:
        conn.close()

    if errores:
        log.error("Verificación FALLIDA: %d diferencia(s)", errores)
        return 1
    log.info("Verificación OK: todos los conteos coinciden")
    return 0


if __name__ == "__main__":
    sys.exit(main())
