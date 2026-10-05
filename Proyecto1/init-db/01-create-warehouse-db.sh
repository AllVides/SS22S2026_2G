#!/usr/bin/env bash
# Crea la DB warehouse si no existe. Se ejecuta solo con volumen de postgres NUEVO.
set -e

: "${POSTGRES_USER:?POSTGRES_USER no definida}"
: "${POSTGRES_WAREHOUSE_DB:?POSTGRES_WAREHOUSE_DB no definida}"

# NOTA: \gexec solo funciona en script/heredoc, NO con psql -c (el backslash
# llegaría al servidor como error de sintaxis). Por eso se usa heredoc.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<EOSQL
SELECT 'CREATE DATABASE "$POSTGRES_WAREHOUSE_DB"'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$POSTGRES_WAREHOUSE_DB')\gexec
EOSQL
