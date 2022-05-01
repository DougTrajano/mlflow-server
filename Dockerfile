FROM python:3.10.4-slim

WORKDIR /app

COPY . /app/

RUN set -x && \
    apt-get update && \
    apt-get install --no-install-recommends --no-install-suggests -y \
    supervisor gettext-base nginx apache2-utils

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
#COPY nginx.conf /etc/nginx/conf.d/default.conf

# install pip then packages
RUN pip install --upgrade pip && \
    pip install -r requirements.txt --upgrade

# Make scripts executable and run env-vars.sh
RUN chmod +x /app/scripts/mlflow.sh && \
    chmod +x /app/scripts/nginx.sh

# Monkey patching mlflow.store.db.utils.py to add NullPool to sqlalchemy engine
RUN cp /app/src/utils.py /usr/local/lib/python3.10/site-packages/mlflow/store/db/utils.py

EXPOSE ${PORT}

# WWW (nginx)
RUN addgroup -gid 1000 www && \
    adduser -uid 1000 -H -D -s /bin/sh -G www www

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
