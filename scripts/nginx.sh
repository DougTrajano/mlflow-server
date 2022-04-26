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

echo "Replacing variables in nginx.conf"
envsubst '${PORT}' < /app/nginx.conf > /etc/nginx/nginx.conf

echo "Adding basic auth to nginx"
htpasswd -b -c /etc/nginx/.htpasswd ${MLFLOW_TRACKING_USERNAME} ${MLFLOW_TRACKING_PASSWORD}

echo "Starting nginx"
exec nginx -g "daemon off;"
