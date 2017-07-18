#!/bin/sh
exec /sbin/setuser www-data php /var/www/artisan queue:work --queue=high,low,default,emails --sleep=3 --tries=3 --daemon