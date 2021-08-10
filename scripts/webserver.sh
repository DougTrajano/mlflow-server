#!/bin/bash -x
if [[ -z "${MLFLOW_TRACKING_USERNAME}" ]]; then
    export MLFLOW_TRACKING_USERNAME="mlflow"
fi

if [[ -z "${MLFLOW_TRACKING_PASSWORD}" ]]; then
    export MLFLOW_TRACKING_PASSWORD="mlflow"
fi

if [[ -z "${PORT}" ]]; then
    export PORT=80
fi

envsubst '${PORT}' < /app/nginx.conf > /etc/nginx/nginx.conf

htpasswd -b -c /etc/nginx/.htpasswd ${MLFLOW_TRACKING_USERNAME} ${MLFLOW_TRACKING_PASSWORD}

exec nginx -g "daemon off;"
