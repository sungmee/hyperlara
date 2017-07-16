#!/bin/sh
cd /var/www
if [ -f "composer.json" ]
then
    composer install --no-scripts
    chmod -R 777 storage bootstrap/cache
else
    cp -a /var/www /var/www-data
    rm -rf *
    rm -rf .[^.]*
    cd /var
    composer create-project --prefer-dist laravel/laravel www
    mv -r /var/www-backup /var/www/www-backup
    cd /var/www
    chmod -R 777 storage bootstrap/cache
fi