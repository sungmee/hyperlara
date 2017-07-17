#! /bin/sh
cd /var/www
if [ -f "composer.json" ]
then
    composer install --no-scripts
    chmod -R 777 storage bootstrap/cache
else
    cp -a /var/www /var/www-backup
    rm -rf * .[^.]*
    cd ..
    composer create-project --prefer-dist laravel/laravel www
    chmod -R 777 /var/www/storage /var/www/bootstrap/cache
    mv /var/www-backup /var/www/www-backup
fi