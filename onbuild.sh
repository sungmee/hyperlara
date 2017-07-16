#! /bin/sh
cd /var/www
if [ -f "composer.json" ]
then
    exec /sbin/setuser www-data composer install --no-scripts
    exec /sbin/setuser root chmod -R 777 storage bootstrap/cache
else
    cp -a /var/www /var/www-data
    rm -rf *
    rm -rf .[^.]*
    cd /var
    exec /sbin/setuser www-data composer create-project --prefer-dist laravel/laravel www
    mv -r /var/www-backup /var/www/www-backup
    cd /var/www
    exec /sbin/setuser root chmod -R 777 storage bootstrap/cache
fi