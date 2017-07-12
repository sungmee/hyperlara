FROM phusion/baseimage:0.9.22
MAINTAINER M.Chan <mo@lxooo.com>

# 设置环境变量
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

#
#--------------------------------------------------------------------------
# SSH: 默认是禁用的
#--------------------------------------------------------------------------
#

# # 生成 SSH KEYS，baseimage 不包含任何的 key，所以需要自己生成。
# # 也可以注释掉这句命令，系统在启动过程中，会生成一个。
# RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# 禁用SSH
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
        # make \
        # zip unzip \
        # pkg-config \
        # gcc make autoconf libc-dev \
        # libxml2-dev \
        # zlib1g-dev libicu-dev g++ \
        # libcurl4-openssl-dev \
        # libedit-dev \
        # libssl-dev \
        # libxml2-dev \
        # xz-utils \
    && locale-gen en_US.UTF-8

#
#--------------------------------------------------------------------------
# 安装配置 PHP、PHP 扩展和其它软体
#--------------------------------------------------------------------------
#
RUN add-apt-repository ppa:ondrej/php \
    && apt-get update \
    && apt-get -yq install --no-install-recommends \
        php7.1-cli \
        php7.1-fpm \
        php7.1-common \
        php7.1-curl \
        php7.1-json \
        php7.1-xml \
        php7.1-bcmath \
        php7.1-mbstring \
        php7.1-mcrypt \
        php7.1-dev \
        php7.1-zip \
        php7.1-intl \
        php7.1-soap \
        php7.1-gd \
        php7.1-exif \
        php7.1-tokenizer \
        # php-pear \
        # php-tideways \
        # php7.1-odbc \
        # php7.1-ldap \
        # php7.1-apcu \
        # php7.1-gmp \
        # php7.1-imap \
        # php7.1-phpdbg \
        # php7.1-pspell \
        # php7.1-readline \
        # php7.1-recode \
        # php7.1-tidy \
        # php7.1-xmlrpc \
        # php7.1-xsl \
        # php7.1-xdebug \
        # php7.1-opcache \
        # php7.1-memcached \
        php7.1-mysql \
        # php-mongodb \
        # php7.1-pgsql \
        # php7.1-sqlite \
        # php7.1-sqlite3 \
        # sqlite3 \
        # libsqlite3-dev \
        # postgresql-client \
    && apt-get clean

COPY ./php/laravel.ini /usr/local/etc/php/conf.d/
COPY ./php/laravel.pool.conf /usr/local/etc/php-fpm.d/
COPY ./php/run.sh /etc/service/php-fpm/run
RUN mkdir -p /run/php \
    && chmod +x /etc/service/php-fpm/run \
    && usermod -u 1000 www-data

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
COPY ./nginx/app.dev.conf /etc/nginx/sites-available/default
COPY ./nginx/run.sh /etc/service/nginx/run
RUN  chmod +x /etc/service/nginx/run
VOLUME ["/var/www"]
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
COPY ./crontab /etc/cron.d
RUN  chmod -R 644 /etc/cron.d

#
#--------------------------------------------------------------------------
# 配置命令别名
#--------------------------------------------------------------------------
#
COPY ./aliases.sh /root/aliases.sh
RUN echo '' >> ~/.bashrc \
    && echo '# Load Custom Aliases' >> ~/.bashrc \
    && echo 'source /root/aliases.sh' >> ~/.bashrc \
	&& echo '' >> ~/.bashrc \
	&& sed -i 's/\r//' ~/aliases.sh \
	&& sed -i 's/^#! \/bin\/sh/#! \/bin\/bash/' ~/aliases.sh \
    && echo '' >> ~/.bashrc \
    && echo 'alias art="php artisan"' >> ~/.bashrc

#
#--------------------------------------------------------------------------
# 安装 PHP REDIS
#--------------------------------------------------------------------------
#
COPY ./redis/run.sh /etc/service/redis/run
RUN apt-get install -y redis-server \
    && chmod +x /etc/service/redis/run
VOLUME ["/data"]

#
#--------------------------------------------------------------------------
# 安装 Beanstalkd 高性能分布式内存队列系统
#--------------------------------------------------------------------------
#
COPY ./beanstalkd/run.sh /etc/service/beanstalkd/run
RUN apt-get install -y beanstalkd \
    && chmod +x /etc/service/beanstalkd/run
VOLUME ["/var/lib/beanstalkd/data"]

#
#--------------------------------------------------------------------------
# 安装 Supervisor 守护进程
#--------------------------------------------------------------------------
#
COPY ./supervisor/run.sh /etc/service/supervisor/run
RUN apt-get install -y supervisor \
    && chmod +x /etc/service/supervisor/run \
    && mkdir -p /var/log/supervisor
COPY ./supervisor/supervisor.conf /etc/supervisor/conf.d/
VOLUME ["/var/log/supervisor"]

#
#--------------------------------------------------------------------------
# 收尾
#--------------------------------------------------------------------------
#

# 清除APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 设置默认工作目录
WORKDIR /var/www

# 暴露端口
EXPOSE 80