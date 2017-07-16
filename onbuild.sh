#!/bin/sh
cd /var/www
if [ -f "composer.json" ]
then
    composer install --no-scripts
    chmod -R 777 storage bootstrap/cache
else
    cd ..
    mv www www-backup
    composer create-project --prefer-dist laravel/laravel www
    mv www-backup www/www-backup
    cd www
    chmod -R 777 storage bootstrap/cache
fi