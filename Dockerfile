FROM phusion/baseimage:master

LABEL maintainer="M.Chan <mo@lxooo.com>"

# 设置环境变量
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
ENV TIMEZONE UTC
ENV PHP_VERSION 8.1
# 兼容 Redis docker
ENV REDIS_PORT 6379

#
#--------------------------------------------------------------------------
# SSH: 默认禁用
#--------------------------------------------------------------------------
#
# 如何使用 SSH，请参考 https://github.com/phusion/baseimage-docker/blob/master/README_ZH_cn_.md#login_ssh
# 生成 SSH KEYS，baseimage 不包含任何的 key，所以需要自己生成。
# 也可以注释掉这句命令，系统在启动过程中，会生成一个。
# RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# 禁用 SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

#
#--------------------------------------------------------------------------
# 初始化 baseimage-docker 系统
#--------------------------------------------------------------------------
#
CMD ["/sbin/my_init"]

#
#--------------------------------------------------------------------------
# 安装配置 PHP、PHP 扩展和其它软体
#--------------------------------------------------------------------------
#
# RUN locale-gen en_US.UTF-8
RUN apt-get clean && apt-get update \
    && apt-get -yq install software-properties-common \
    && add-apt-repository ppa:ondrej/php \
    && apt-get -yq install --no-install-recommends \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-mcrypt \
        php${PHP_VERSION}-dev \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-bz2 \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-soap \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-exif \
        php${PHP_VERSION}-tokenizer \
        php${PHP_VERSION}-gmp \
        php${PHP_VERSION}-imap \
        php${PHP_VERSION}-readline \
        php${PHP_VERSION}-ctype \
        php${PHP_VERSION}-xdebug \
        php${PHP_VERSION}-opcache \
        php${PHP_VERSION}-memcached \
        php${PHP_VERSION}-redis \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-pdo-mysql \
        php${PHP_VERSION}-mongodb \
        php${PHP_VERSION}-pgsql \
        php${PHP_VERSION}-pdo-pgsql \
        php${PHP_VERSION}-sqlite \
        php${PHP_VERSION}-sqlite3 \
        # php${PHP_VERSION}-odbc \
        # php${PHP_VERSION}-ldap \
        # php${PHP_VERSION}-apcu \
        # php${PHP_VERSION}-phpdbg \
        # php${PHP_VERSION}-pspell \
        # php${PHP_VERSION}-recode \
        # php${PHP_VERSION}-tidy \
        # php${PHP_VERSION}-xmlrpc \
        # php${PHP_VERSION}-xsl \
        php7.4-json \
        php-pear \
        # php-tideways \
    && apt-get clean

#
#--------------------------------------------------------------------------
# 安装 Composer:
#--------------------------------------------------------------------------
#
RUN curl -s http://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    echo 'export PATH=${PATH}:/app/vendor/bin' >> ~/.bashrc

#
#--------------------------------------------------------------------------
# 安装配置 Nginx
#--------------------------------------------------------------------------
#
RUN add-apt-repository ppa:nginx/stable -y \
    && apt-get -yq install --no-install-recommends nginx \
    && echo 'daemon off;' >> /etc/nginx/nginx.conf \
    && apt-get clean
COPY ./build/app.dev.conf /etc/nginx/sites-available/default
COPY ./build/nginx.sh /etc/service/nginx/run
RUN  chmod +x /etc/service/nginx/run

#
#--------------------------------------------------------------------------
# 清理 APT 临时数据
#--------------------------------------------------------------------------
#
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#
#--------------------------------------------------------------------------
# 配置 Crontab
#--------------------------------------------------------------------------
#
COPY ./build/crontab /etc/cron.d/www-data
RUN chmod -R 644 /etc/cron.d

#
#--------------------------------------------------------------------------
# 配置 Baseimage 的 Runit 服务监控和管理 Laravel 的队列
#--------------------------------------------------------------------------
#
COPY ./build/worker.sh /etc/service/worker/run
RUN chmod +x /etc/service/worker/run

#
#--------------------------------------------------------------------------
# 配置 PHP 以及 扩展
#--------------------------------------------------------------------------
#
COPY ./build/php.sh /etc/service/php-fpm/run
RUN mkdir -p /run/php \
    && chmod +x /etc/service/php-fpm/run \
    && usermod -u 1000 www-data \

    # php-fpm.conf
    && sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/${PHP_VERSION}/fpm/php-fpm.conf \

    # php.ini fpm
    && sed -i -e "s/;date.timezone.*/date.timezone = ${TIMEZONE}/" /etc/php/${PHP_VERSION}/fpm/php.ini \
    && sed -i -e "s/upload_max_filesize = .*/upload_max_filesize = 20M/" /etc/php/${PHP_VERSION}/fpm/php.ini \
    && sed -i -e "s/post_max_size = .*/post_max_size = 20M/" /etc/php/${PHP_VERSION}/fpm/php.ini \
    && sed -i -e "s/max_execution_time = .*/max_execution_time = 300/" /etc/php/${PHP_VERSION}/fpm/php.ini \

    # php.ini cli
    && sed -i -e "s/;date.timezone.*/date.timezone = ${TIMEZONE}/" /etc/php/${PHP_VERSION}/cli/php.ini \
    && sed -i -e "s/upload_max_filesize = .*/upload_max_filesize = 20M/" /etc/php/${PHP_VERSION}/cli/php.ini \
    && sed -i -e "s/post_max_size = .*/post_max_size = 20M/" /etc/php/${PHP_VERSION}/cli/php.ini \
    && sed -i -e "s/max_execution_time = .*/max_execution_time = 300/" /etc/php/${PHP_VERSION}/cli/php.ini \

    # www.conf
    && sed -i -e "s/listen = .*/listen = 0.0.0.0:9000/" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf \
    && sed -i -e "s/pm.max_children = 5/pm.max_children = 20/" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf \
    && sed -i -e "s/;catch_workers_output = yes/catch_workers_output = yes/" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf \


    # opcache.ini fpm
    && sed -i -e "s/;opcache.enable=1/opcache.enable=1/" /etc/php/${PHP_VERSION}/fpm/php.ini \
    && sed -i -e "s/;opcache.memory_consumption=128/opcache.memory_consumption=256/" /etc/php/${PHP_VERSION}/fpm/php.ini \
    && sed -i -e "s/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=64/" /etc/php/${PHP_VERSION}/fpm/php.ini \
    && sed -i -e "s/;opcache.use_cwd=1/opcache.use_cwd=0/" /etc/php/${PHP_VERSION}/fpm/php.ini \
    && sed -i -e "s/;opcache.max_file_size=0/opcache.max_file_size=0/" /etc/php/${PHP_VERSION}/fpm/php.ini \
    && sed -i -e "s/;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=30000/" /etc/php/${PHP_VERSION}/fpm/php.ini \
    && sed -i -e "s/;opcache.validate_timestamps=1/opcache.validate_timestamps=1/" /etc/php/${PHP_VERSION}/fpm/php.ini \
    && sed -i -e "s/;opcache.revalidate_freq=2/opcache.revalidate_freq=2/" /etc/php/${PHP_VERSION}/fpm/php.ini \
    && sed -i -e "s/;opcache.save_comments=1/opcache.save_comments=1/" /etc/php/${PHP_VERSION}/fpm/php.ini \

    # opcache.ini cli
    && sed -i -e "s/;opcache.enable=1/opcache.enable=1/" /etc/php/${PHP_VERSION}/cli/php.ini \
    && sed -i -e "s/;opcache.memory_consumption=128/opcache.memory_consumption=256/" /etc/php/${PHP_VERSION}/cli/php.ini \
    && sed -i -e "s/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=64/" /etc/php/${PHP_VERSION}/cli/php.ini \
    && sed -i -e "s/;opcache.use_cwd=1/opcache.use_cwd=0/" /etc/php/${PHP_VERSION}/cli/php.ini \
    && sed -i -e "s/;opcache.max_file_size=0/opcache.max_file_size=0/" /etc/php/${PHP_VERSION}/cli/php.ini \
    && sed -i -e "s/;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=30000/" /etc/php/${PHP_VERSION}/cli/php.ini \
    && sed -i -e "s/;opcache.validate_timestamps=1/opcache.validate_timestamps=1/" /etc/php/${PHP_VERSION}/cli/php.ini \
    && sed -i -e "s/;opcache.revalidate_freq=2/opcache.revalidate_freq=2/" /etc/php/${PHP_VERSION}/cli/php.ini \
    && sed -i -e "s/;opcache.save_comments=1/opcache.save_comments=1/" /etc/php/${PHP_VERSION}/cli/php.ini

#
#--------------------------------------------------------------------------
# 收尾
#--------------------------------------------------------------------------
#
# 设置默认工作目录
WORKDIR /app
# Larave 项目目录
VOLUME /app

# 以本镜像为母本构建您的自定义镜像时，下面命令将拷贝您的 Laravel 项目并执行依赖~安装。
ONBUILD COPY . /app
ONBUILD RUN cd /app && composer install --no-scripts
ONBUILD RUN chown -R 1000:33 storage bootstrap/cache
ONBUILD RUN chmod -R 751 storage bootstrap/cache
ONBUILD RUN chmod -R o+r storage bootstrap/cache

# 暴露端口
EXPOSE 9000
EXPOSE 80

ENTRYPOINT ["/bin/bash", "-c"]