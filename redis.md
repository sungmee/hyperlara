## Build phpredis extension

```bash
git clone https://github.com/phpredis/phpredis.git
cd phpredis
git checkout php7
phpize
./configure
make && make install
cd ..
rm -rf phpredis
```

## Activate phpredis extension in fpm and cli

```bash
echo "extension=redis.so" > /etc/php/7.0/mods-available/redis.ini
ln -sf /etc/php/7.0/mods-available/redis.ini /etc/php/7.0/fpm/conf.d/20-redis.ini
ln -sf /etc/php/7.0/mods-available/redis.ini /etc/php/7.0/cli/conf.d/20-redis.ini
service php7.0-fpm restart
```