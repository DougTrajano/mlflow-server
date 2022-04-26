#!/bin/bash -x
if [[ "${PORT}" == 5001 ]]; then
    echo "PORT can not be set to the value of 5001. Please, select other port."
    exit 1
fi

if [[ -z "${MLFLOW_ARTIFACT_URI}" ]]; then
    echo "MLFLOW_ARTIFACT_URI can not be set. Define default value as ./mlruns"
    export MLFLOW_ARTIFACT_URI="./mlruns"
fi

if [[ -z "${MLFLOW_DB_DIALECT}" ]]; then
    export MLFLOW_DB_DIALECT="mysql+pymysql"
fi

if [[ -z "${MLFLOW_DB_USERNAME}" ]]; then
    export MLFLOW_DB_USERNAME="mlflow"
fi

if [[ -z "${MLFLOW_DB_PASSWORD}" ]]; then
    export MLFLOW_DB_PASSWORD="mlflow"
fi

if [[ -z "${MLFLOW_DB_DATABASE}" ]]; then
    export MLFLOW_DB_DATABASE="mlflow"
fi

if [[ -z "${MLFLOW_DB_PORT}" ]]; then
    export MLFLOW_DB_PORT=3306
fi

if [[ -z "${MLFLOW_BACKEND_URI}" ]]; then
    echo "MLFLOW_BACKEND_URI not set. Define default value based on other variables."
    export MLFLOW_BACKEND_URI=${MLFLOW_DB_DIALECT}://${MLFLOW_DB_USERNAME}:${MLFLOW_DB_PASSWORD}@${MLFLOW_DB_HOST}:${MLFLOW_DB_PORT}/${MLFLOW_DB_DATABASE}
fi

echo "Starting mlflow server"

exec mlflow server --host 0.0.0.0 --port 5001 \
    --default-artifact-root "${MLFLOW_ARTIFACT_URI}" \
    --backend-store-uri "${MLFLOW_BACKEND_URI}"
