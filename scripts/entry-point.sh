#!/bin/bash -x
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
