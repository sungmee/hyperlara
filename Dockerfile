# 使用phusion/baseimage作为基础镜像,去构建你自己的镜像,需要下载一个明确的版本,千万不要使用`latest`.
# 查看https://github.com/phusion/baseimage-docker/blob/master/Changelog.md,可用看到版本的列表.
FROM phusion/baseimage:0.9.22

MAINTAINER M.Chan <mo@lxooo.com>

# 设置环境变量
RUN DEBIAN_FRONTEND=noninteractive
RUN locale-gen en_US.UTF-8

ENV DEBIAN_FRONTEND noninteractive
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LC_CTYPE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV TERM xterm

ENV APP_NAME app
ENV APP_EMAIL app@hailu.org
ENV APP_DOMAIN app.dev

RUN ln -snf /usr/share/zoneinfo/UTC /etc/localtime && echo UTC > /etc/timezone

# 安装基础库和软件
# RUN apt-get install -y software-properties-common curl build-essential \
#     dos2unix gcc git libmcrypt4 libpcre3-dev memcached make python2.7-dev \
#     python-pip re2c unattended-upgrades whois vim libnotify-bin nano wget \
#     debconf-utils apt-utils language-pack-en-base
RUN apt-get update && \
    apt-get install -y --allow-downgrades --allow-remove-essential \
        --allow-change-held-packages \
        pkg-config \
        libcurl4-openssl-dev \
        libedit-dev \
        libssl-dev \
        libxml2-dev \
        xz-utils \
        git \
        curl \
        vim \
    && apt-get clean

# 添加第三方源
RUN apt-add-repository ppa:nginx/development -y && \
    apt-add-repository ppa:chris-lea/redis-server -y && \
    add-apt-repository -y ppa:ondrej/php
    # # 添加 gpg 密钥 packagecloud 包验证
    # curl -s https://packagecloud.io/gpg.key | apt-key add - && \
    # echo "deb http://packages.blackfire.io/debian any main" | tee /etc/apt/sources.list.d/blackfire.list && \
    # curl --silent --location https://deb.nodesource.com/setup_6.x | bash - && \

# 安装并配置 Nginx
RUN apt-get update && \
    apt-get install -y --allow-downgrades --allow-remove-essential \
        --allow-change-held-packages \
        nginx \
    && apt-get clean
COPY app.dev /etc/nginx/sites-available/
COPY fastcgi_params /etc/nginx/
RUN rm -rf /etc/nginx/sites-available/default && \
    rm -rf /etc/nginx/sites-enabled/default && \
    ln -fs "/etc/nginx/sites-available/app.dev" "/etc/nginx/sites-enabled/app.dev" && \
    sed -i -e "s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf && \
    sed -i -e "s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf && \
    echo "daemon off;" >> /etc/nginx/nginx.conf && \
    usermod -u 1000 www-data && \
    chown -Rf www-data.www-data /var/www/html/ && \
    sed -i -e "s/worker_processes  1/worker_processes 5/" /etc/nginx/nginx.conf
VOLUME ["/var/www/html/app"]
VOLUME ["/var/cache/nginx"]
VOLUME ["/var/log/nginx"]

# 安装并配置 PHP
# 安装 php7.0-memcached 等部分兼容扩展前，可能需要先安装 php5.6-common 这个 php5.6 扩展。
RUN apt-get install -y --allow-downgrades --allow-remove-essential \
        --allow-change-held-packages \
        php7.0-cli php7.0-common php7.0-dev php7.0-curl \
        php7.0-json php7.0-xml php7.0-mbstring php7.0-mcrypt \
        php7.0-mysql php7.0-memcached \
        php7.0-zip php7.0-bcmath php7.0-gd \
        php7.0-apcu  php7.0-imap \
        php7.0-readline php7.0-xdebug \
        php7.0-intl php7.0-soap php7.0-fpm \
    && apt-get clean
RUN sed -i -e "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/cli/php.ini && \
    sed -i -e "s/display_errors = .*/display_errors = On/" /etc/php/7.0/cli/php.ini && \
    sed -i -e "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.0/cli/php.ini
RUN sed -i -e "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/fpm/php.ini && \
    sed -i -e "s/display_errors = .*/display_errors = On/" /etc/php/7.0/fpm/php.ini && \
    sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.0/fpm/php.ini && \
    sed -i -e "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/7.0/fpm/php.ini && \
    sed -i -e "s/post_max_size = .*/post_max_size = 100M/" /etc/php/7.0/fpm/php.ini && \
    sed -i -e "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.0/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_children = 5/pm.max_children = 9/g" /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i -e "s/;listen.mode = 0660/listen.mode = 0750/g" /etc/php/7.0/fpm/pool.d/www.conf
RUN find /etc/php/7.0/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;
RUN phpdismod -s cli xdebug
RUN phpenmod mcrypt && \
    mkdir -p /run/php/ && \
    chown -Rf www-data.www-data /run/php

## ln: failed to create symbolic link '/etc/php/7.0/cli/conf.d/20-mcrypt.ini': File exists

# 安装并配置 Composer
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    printf "\nPATH=\"~/.composer/vendor/bin:\$PATH\"\n" | tee -a ~/.bashrc

# # 安装 Laravel Envoy 远程服务器任务处理器
# RUN composer global require "laravel/envoy"

# # 安装 Laravel 安装器
# RUN composer global require "laravel/installer"

# # 安装 Lumen 安装器
# RUN composer global require "laravel/lumen-installer"

# # 安装 Node.js
# RUN apt-get install -y nodejs && \
#     /usr/bin/npm install -g gulp && \
#     /usr/bin/npm install -g bower

# # 安装 Sqlite
# RUN apt-get install -y sqlite3 libsqlite3-dev

# # 安装 MySQL —— 注意需要去除上面添加 MySQL 源的注释
# RUN echo mysql-server mysql-server/root_password password $DB_PASS | debconf-set-selections;\
#     echo mysql-server mysql-server/root_password_again password $DB_PASS | debconf-set-selections;\
#     apt-get install -y mysql-server
# RUN /usr/sbin/mysqld && \
#     sleep 10s && \
#     echo "GRANT ALL ON *.* TO root@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION; CREATE USER 'homestead'@'0.0.0.0' IDENTIFIED BY 'secret'; GRANT ALL ON *.* TO 'homestead'@'0.0.0.0' IDENTIFIED BY 'secret' WITH GRANT OPTION; GRANT ALL ON *.* TO 'homestead'@'%' IDENTIFIED BY 'secret' WITH GRANT OPTION; FLUSH PRIVILEGES; CREATE DATABASE homestead;" | mysql
# VOLUME ["/var/lib/mysql"]

# # 安装 Postgres
# RUN apt-get install -y postgresql postgresql-client

# 安装 redis —— 以后考虑换成安装配置 phpredis
RUN apt-get install -y redis-server

# # 安装 Blackfire 及 PHP 扩展 —— Web分析器，用于测试应用的性能
# RUN apt-get install -y blackfire-agent blackfire-php

# 安装 Beanstalkd 高性能分布式内存队列系统
# /etc/init.d/beanstalkd {start|stop|force-stop|restart|force-reload|status}
# RUN apt-get install -y --allow-downgrades --allow-remove-essential \
#         --allow-change-held-packages \
#         beanstalkd && \
#         sed -i -e "s/BEANSTALKD_LISTEN_ADDR.*/BEANSTALKD_LISTEN_ADDR=0.0.0.0/" /etc/default/beanstalkd && \
#         sed -i -e "/BEANSTALKD_LISTEN_PORT=11300/a START=yes" /etc/default/beanstalkd \
#     && apt-get clean

# 安装 Supervisor —— 进程监控软件
RUN apt-get install -y supervisor && \
    mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
VOLUME ["/var/log/supervisor"]

# 镜像瘦身 —— 清除安装文件缓存等乱七八糟的东西
RUN apt-get remove --purge -y software-properties-common && \
    apt-get autoremove -y && \
    apt-get clean && \
    apt-get autoclean && \
    echo -n > /var/lib/apt/extended_states && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm -rf /usr/share/man/?? && \
    rm -rf /usr/share/man/??_*

COPY crontab /etc/cron.d
RUN chmod -R 644 /etc/cron.d

WORKDIR /var/www/html/app

# 暴露端口
# EXPOSE 80 443 3306 6379
EXPOSE 80

# set container entrypoints
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]