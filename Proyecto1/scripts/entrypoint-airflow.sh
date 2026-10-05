#!/usr/bin/env bash
# Wrapper de entrypoint para los contenedores Airflow (ver docker-compose.yml).
#
# Problema: Airflow 2.10+ exige correr con un usuario que tenga username
# (getpwuid). Arrancar con `user: "UID:0"` deja un UID numérico sin entrada en
# /etc/passwd y TODO comando `airflow` muere con:
#   AirflowConfigException: ... has no username
#
# Solución portable: el contenedor arranca como root, aquí se renombra el
# usuario `airflow` de la imagen al UID del host (AIRFLOW_UID del .env) y se
# delega al entrypoint oficial, que baja privilegios vía gosu. Así la IMAGEN
# no depende de la máquina: cambiar de UID es solo `recreate`, sin rebuild
# (AIRFLOW_UID ausente = 50000 = comportamiento upstream puro).
set -e

TARGET_UID="${AIRFLOW_UID:-50000}"
CURRENT_UID="$(id -u airflow)"

if [ "$TARGET_UID" != "$CURRENT_UID" ]; then
    echo "entrypoint-airflow: renombrando usuario airflow ${CURRENT_UID} -> ${TARGET_UID}"
    usermod -u "$TARGET_UID" airflow
    # Transfiere solo lo que quedó con el UID viejo (seguro ante re-ejecución).
    chown -R --from="$CURRENT_UID" airflow:root /home/airflow 2>/dev/null || true
fi

# El entrypoint oficial NO baja privilegios solo (verificado en 2.10.5):
# hay que hacerlo aquí, si no todo correría como root.
exec setpriv --reuid airflow --regid 0 --clear-groups /entrypoint "$@"
