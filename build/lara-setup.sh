#! /bin/sh
cd /app
if [ -f "/app/composer.json" ]
    then
        composer install --no-scripts
    else
        cp -a /app /backup
        rm -rf * .[^.]*
        cd ..
        composer create-project --prefer-dist laravel/laravel www
        mv /backup /app/backup
    fi

chmod -R 1000:33 /app/storage /app/bootstrap/cache
chmod -R 751 /app/storage /app/bootstrap/cache
chmod -R o+r /app/storage /app/bootstrap/cache