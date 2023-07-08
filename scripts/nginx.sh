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
mkdir -p /etc/nginx
touch /etc/nginx/.htpasswd

# Replace commas with newlines
string1=$(echo ${MLFLOW_TRACKING_USERNAME} | tr ',' '\n')
string2=$(echo ${MLFLOW_TRACKING_PASSWORD} | tr ',' '\n')

# Loop over both strings in parallel
while read val1 && read val2 <&3; do
    htpasswd -b /etc/nginx/.htpasswd ${val1} ${val2}
done <<< "$string1" 3<<< "$string2"

# htpasswd -b -c /etc/nginx/.htpasswd ${MLFLOW_TRACKING_USERNAME} ${MLFLOW_TRACKING_PASSWORD}

echo "Starting nginx"
exec nginx -g "daemon off;"
