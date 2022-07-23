#!/bin/bash -x
if [[ "${PORT}" == 5001 ]]; then
    echo "PORT can not be set to the value of 5001. Please, select other port."
    exit 1
fi

if [[ -z "${MLFLOW_ARTIFACT_URI}" ]]; then
    echo "MLFLOW_ARTIFACT_URI can not be set. Define default value as ./mlruns"
    export MLFLOW_ARTIFACT_URI="./mlruns"
fi

if [[ -n "${DATABASE_URL}" ]]; then
    export MLFLOW_BACKEND_URI="${DATABASE_URL}"
    # Heroku uses "postgres" dialect, but we want to use "postgresql"
    # so we will update MLFLOW_BACKEND_URI to use "postgresql" dialect.
    python -c "import os; os.environ['MLFLOW_BACKEND_URI'] = os.environ['MLFLOW_BACKEND_URI'].replace('postgres', 'postgresql')"
    unset DATABASE_URL
fi

if [[ -z "${MLFLOW_BACKEND_URI}" ]]; then
    echo "MLFLOW_BACKEND_URI not set. Define default value based on other variables."

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

    export MLFLOW_BACKEND_URI=${MLFLOW_DB_DIALECT}://${MLFLOW_DB_USERNAME}:${MLFLOW_DB_PASSWORD}@${MLFLOW_DB_HOST}:${MLFLOW_DB_PORT}/${MLFLOW_DB_DATABASE}
    unset MLFLOW_DB_DIALECT
    unset MLFLOW_DB_USERNAME
    unset MLFLOW_DB_PASSWORD
    unset MLFLOW_DB_DATABASE
    unset MLFLOW_DB_HOST
    unset MLFLOW_DB_PORT
fi

echo "Starting mlflow server"

exec mlflow server --host 0.0.0.0 --port 5001 \
    --default-artifact-root "${MLFLOW_ARTIFACT_URI}" \
    --backend-store-uri "${MLFLOW_BACKEND_URI}" \
    --serve-artifacts \
    --gunicorn-opts "--worker-class gevent --threads 2 --workers 2 --timeout 300 --keep-alive 300"