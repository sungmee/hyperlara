FROM phusion/baseimage:latest
MAINTAINER M.Chan <mo@lxooo.com>

# 设置环境变量
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
ENV TIMEZONE UTC

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
# 安装基础软体
#--------------------------------------------------------------------------
#
RUN apt-get clean && apt-get update \
    && apt-get -yq install software-properties-common \
        curl git vim \
        # wget \
        # make \
        # zip unzip \
        # bzip2 \
        # g++ \
        # gcc \
        # autoconf \
        # pkg-config \
        # xz-utils \
        # zlib1g-dev \
        # libicu-dev \
        # libc-dev \
        # libxml2-dev \
        # libcurl4-openssl-dev \
        # libfreetype6-dev \
        # libedit-dev \
        # libssl-dev \
        # libxml2-dev \
        # libjpeg-dev \
        # libldap2-dev \
        # libmcrypt-dev \
        # libmemcached-dev \
        # libpng12-dev \
        # libpq-dev \
    && locale-gen en_US.UTF-8

#
#--------------------------------------------------------------------------
# 安装配置 PHP、PHP 扩展和其它软体
#--------------------------------------------------------------------------
#
RUN add-apt-repository ppa:ondrej/php \
    && apt-get update \
    && apt-get -yq install --no-install-recommends \
        # 暂无 7.2: mcrypt
        php7.2-cli \
        php7.2-fpm \
        php7.2-common \
        php7.2-curl \
        php7.2-json \
        php7.2-xml \
        php7.2-bcmath \
        php7.2-mbstring \
        php-mcrypt \
        php7.2-dev \
        php7.2-zip \
        php7.2-intl \
        php7.2-soap \
        php7.2-gd \
        php7.2-exif \
        php7.2-tokenizer \
        php7.2-gmp \
        php7.2-imap \
        php7.2-readline \
        php7.2-ctype \
        php-pear \
        # php-tideways \
        # php7.2-odbc \
        # php7.2-ldap \
        # php7.2-apcu \
        # php7.2-phpdbg \
        # php7.2-pspell \
        # php7.2-recode \
        # php7.2-tidy \
        # php7.2-xmlrpc \
        # php7.2-xsl \
        php7.2-xdebug \
        php7.2-opcache \
        php7.2-memcached \
        php7.2-mysql \
        php7.2-pdo-mysql \
        php7.2-mongodb \
        php7.2-pgsql \
        php7.2-pdo-pgsql \
        # php7.2-sqlite \
        # php7.2-sqlite3 \
    && apt-get clean

# 配置 PHP 以及 扩展
COPY ./build/php.sh /etc/service/php-fpm/run
RUN mkdir -p /run/php \
    && chmod +x /etc/service/php-fpm/run \
    && usermod -u 1000 www-data \
    # php-fpm.conf
    && sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.2/fpm/php-fpm.conf \
    # php.ini fpm
    && sed -i -e "s/;date.timezone.*/date.timezone = $TIMEZONE/" /etc/php/7.2/fpm/php.ini \
    && sed -i -e "s/upload_max_filesize = .*/upload_max_filesize = 20M/" /etc/php/7.2/fpm/php.ini \
    && sed -i -e "s/post_max_size = .*/post_max_size = 20M/" /etc/php/7.2/fpm/php.ini \
    && sed -i -e "s/max_execution_time = .*/max_execution_time = 300/" /etc/php/7.2/fpm/php.ini \
    # php.ini cli
    && sed -i -e "s/;date.timezone.*/date.timezone = $TIMEZONE/" /etc/php/7.2/cli/php.ini \
    && sed -i -e "s/upload_max_filesize = .*/upload_max_filesize = 20M/" /etc/php/7.2/cli/php.ini \
    && sed -i -e "s/post_max_size = .*/post_max_size = 20M/" /etc/php/7.2/cli/php.ini \
    && sed -i -e "s/max_execution_time = .*/max_execution_time = 300/" /etc/php/7.2/cli/php.ini \
    # www.conf
    # 如果监听 9000 端口，需要修改相应的 Nginx 配置文件
    # && sed -i -e "s/listen = .*/listen = 0.0.0.0:9000/" /etc/php/7.2/fpm/pool.d/www.conf \
    && sed -i -e "s/pm.max_children = 5/pm.max_children = 20/" /etc/php/7.2/fpm/pool.d/www.conf \
    && sed -i -e "s/;catch_workers_output = yes/catch_workers_output = yes/" /etc/php/7.2/fpm/pool.d/www.conf \
    # opcache.ini fpm
    && sed -i -e "s/;opcache.enable=1/opcache.enable=1/" /etc/php/7.2/fpm/php.ini \
    && sed -i -e "s/;opcache.memory_consumption=128/opcache.memory_consumption=256/" /etc/php/7.2/fpm/php.ini \
    && sed -i -e "s/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=64/" /etc/php/7.2/fpm/php.ini \
    && sed -i -e "s/;opcache.use_cwd=1/opcache.use_cwd=0/" /etc/php/7.2/fpm/php.ini \
    && sed -i -e "s/;opcache.max_file_size=0/opcache.max_file_size=0/" /etc/php/7.2/fpm/php.ini \
    && sed -i -e "s/;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=30000/" /etc/php/7.2/fpm/php.ini \
    && sed -i -e "s/;opcache.validate_timestamps=1/opcache.validate_timestamps=1/" /etc/php/7.2/fpm/php.ini \
    && sed -i -e "s/;opcache.revalidate_freq=2/opcache.revalidate_freq=2/" /etc/php/7.2/fpm/php.ini \
    && sed -i -e "s/;opcache.save_comments=1/opcache.save_comments=1/" /etc/php/7.2/fpm/php.ini \
    # opcache.ini cli
    && sed -i -e "s/;opcache.enable=1/opcache.enable=1/" /etc/php/7.2/cli/php.ini \
    && sed -i -e "s/;opcache.memory_consumption=128/opcache.memory_consumption=256/" /etc/php/7.2/cli/php.ini \
    && sed -i -e "s/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=64/" /etc/php/7.2/cli/php.ini \
    && sed -i -e "s/;opcache.use_cwd=1/opcache.use_cwd=0/" /etc/php/7.2/cli/php.ini \
    && sed -i -e "s/;opcache.max_file_size=0/opcache.max_file_size=0/" /etc/php/7.2/cli/php.ini \
    && sed -i -e "s/;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=30000/" /etc/php/7.2/cli/php.ini \
    && sed -i -e "s/;opcache.validate_timestamps=1/opcache.validate_timestamps=1/" /etc/php/7.2/cli/php.ini \
    && sed -i -e "s/;opcache.revalidate_freq=2/opcache.revalidate_freq=2/" /etc/php/7.2/cli/php.ini \
    && sed -i -e "s/;opcache.save_comments=1/opcache.save_comments=1/" /etc/php/7.2/cli/php.ini

#
#--------------------------------------------------------------------------
# 安装 Composer:
#--------------------------------------------------------------------------
#
RUN curl -s http://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    echo 'export PATH=${PATH}:/var/www/vendor/bin' >> ~/.bashrc

#
#--------------------------------------------------------------------------
# 配置 Crontab
#--------------------------------------------------------------------------
#
COPY ./build/crontab /etc/cron.d/www-data
RUN  chmod -R 644 /etc/cron.d

#
#--------------------------------------------------------------------------
# 配置命令别名
#--------------------------------------------------------------------------
#
COPY ./build/aliases.sh /root/aliases.sh
RUN echo '' >> ~/.bashrc \
    && echo '# Load Custom Aliases' >> ~/.bashrc \
    && echo 'source /root/aliases.sh' >> ~/.bashrc \
	&& echo '' >> ~/.bashrc \
	&& sed -i 's/\r//' ~/aliases.sh \
	&& sed -i 's/^#! \/bin\/sh/#! \/bin\/bash/' ~/aliases.sh

#
#--------------------------------------------------------------------------
# 配置 Baseimage 的 Runit 服务监控和管理 Laravel 的队列
#--------------------------------------------------------------------------
#
COPY ./build/worker.sh /etc/service/worker/run
RUN chmod +x /etc/service/worker/run

#
#--------------------------------------------------------------------------
# 安装配置 Nginx
#--------------------------------------------------------------------------
#
RUN apt-add-repository ppa:nginx/stable -y \
    && apt-get update \
    && apt-get -yq install --no-install-recommends nginx \
    && echo 'daemon off;' >> /etc/nginx/nginx.conf \
    && apt-get clean
COPY ./build/app.dev.conf /etc/nginx/sites-available/default
COPY ./build/nginx.sh /etc/service/nginx/run
RUN  chmod +x /etc/service/nginx/run

# Larave 项目目录
VOLUME /var/www

#
#--------------------------------------------------------------------------
# 收尾
#--------------------------------------------------------------------------
#

# 清理 APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 设置默认工作目录
WORKDIR /var/www

# Laravel 依赖安装或项目新建脚本，在 shell 中执行 lara-setup，
# 脚本将自动配置 Laravel 项目到 /var/www 目录中
COPY ./build/lara-setup.sh /usr/local/bin/lara-setup
RUN chmod +x /usr/local/bin/lara-setup

# 以本镜像为母本构建您的自定义镜像时，下面命令将拷贝您的 Laravel 项目并执行依赖安装。
ONBUILD COPY . /var/www
ONBUILD RUN cd /var/www && composer install --no-scripts
ONBUILD RUN chmod -R 777 storage bootstrap/cache

# 暴露端口
EXPOSE 80

ENTRYPOINT ["/bin/bash", "-c"]