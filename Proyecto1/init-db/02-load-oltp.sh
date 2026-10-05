#!/usr/bin/env bash
# Carga la fuente OLTP sintética en la DB warehouse. Solo con volumen NUEVO.
# Si el volumen ya existía, cargarla a mano:
#   docker compose exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_WAREHOUSE_DB" -f /seed-data/sgfood_oltp.sql
set -e

: "${POSTGRES_USER:?POSTGRES_USER no definida}"
: "${POSTGRES_WAREHOUSE_DB:?POSTGRES_WAREHOUSE_DB no definida}"

if [ -f /seed-data/sgfood_oltp.sql ]; then
  echo "Cargando /seed-data/sgfood_oltp.sql en $POSTGRES_WAREHOUSE_DB ..."
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_WAREHOUSE_DB" -f /seed-data/sgfood_oltp.sql
else
  echo "AVISO: /seed-data/sgfood_oltp.sql no encontrado, se omite carga OLTP."
fi
