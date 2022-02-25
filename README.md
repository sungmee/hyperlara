# HyperLara

基于 `phusion/baseimage` 构建的 Laravel Docker 镜像。内置 PHP8.1、Nginx、Composer。

## 镜像说明

默认开启 Laravel 列队：`high,low,default,emails`，列队日志可直接在 HyperApp 查看，或查看容器运行日志。列队监控与管理采用 Baseimage-docker 的 Runit 模块，系统级别，纯净无添加，并且服务崩溃之后，支持后台进程自动重启。

默认加入 Laravel Crontab 定时任务。

## 应用目录

Laravel 项目目录：`/app`
Laravel Worker 列队的日志记录在 Laravel app 目录下的 `/storage/logs/worker.log` 中。

## 运行容器

    docker run -d --name myapp --link mysql:db --link redis:redis --link beanstalkd:beanstalkd -p 80:80 -v /path/to/your/laravel:/var/www sungmee/hyperlara:latest

## 初始化项目

将项目拷贝到宿主机目录 `/path/to/your/laravel`。如果您需要通过 `composer.json` 文件初始化项目（须先将其拷贝入您宿主机的项目目录）。也可以在空的 `/path/to/your/laravel` 中新建 Laravel 项目，请在宿主机中运行以下命令：

    docker exec myapp lara-setup

稍做等候，脚本将自动帮您安装好项目依赖，或者初始化一个新的 Laravel 项目。

## 以 HyperLara 作为母本构建镜像

在您的 Laravel 项目根目录中编写 Dockerfile 文件，并将您的 Laravel 项目文件拷贝到该目录下，请确保根目录中存在 composer.json 文件，然后，就 Build 吧，脚本会自动帮您安装并配置相关依赖。如果您还没有 Laravel 项目，脚本会自动帮您初始化一个新的 Laravel 项目。

PS: 如果新建项目没有成功，请进入容器以后，运行：`lara-setup`。

Dockerfile 示例：

```sh
FROM sungmee/hyperlara
MAINTAINER M.Chan <mo@lxooo.com>

# 设置时区为中华人民共和国
ENV TIMEZONE PRC
RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime \
    && echo $TIMEZONE > /etc/timezone

# 您的构建代码 ...
```

`docker build --platform linux/amd64 -t tag .`