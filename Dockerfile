FROM python:3.8-slim

LABEL maintainer="Douglas Trajano <douglas.trajano@outlook.com>"

USER root

# making directory of app
RUN mkdir /app
WORKDIR /app

# copying all files over
COPY . /app/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN set -x \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y \
    supervisor gettext-base nginx apache2-utils

# install pip then packages
RUN pip install --upgrade pip \
    && pip install -r requirements.txt --upgrade

# Make scripts executable and run env-vars.sh
RUN chmod +x /app/scripts/entry-point.sh \
    && chmod +x /app/scripts/mlflow.sh \
    && chmod +x /app/scripts/webserver.sh

EXPOSE ${MLFLOW_PORT}

# WWW (nginx)
RUN addgroup -gid 1000 www \
    && adduser -uid 1000 -H -D -s /bin/sh -G www www

COPY nginx.conf /etc/nginx/conf.d/default.conf

ENTRYPOINT ["/bin/bash", "/app/scripts/entry-point.sh"]
