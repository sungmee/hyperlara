#!/bin/sh
exec /sbin/setuser www-data php /app/artisan queue:work --queue=high,low,default,emails,once --sleep=3 --tries=3 --timeout=30 --daemon