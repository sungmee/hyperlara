#!/bin/sh
exec /sbin/setuser www-data php /app/artisan horizon

# COPY horizon.sh /etc/service/horizon/run
# RUN chmod +x /etc/service/horizon/run