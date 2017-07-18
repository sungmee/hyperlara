# HyperLara

基于 phusion/baseimage 构建的 Laravel Docker 镜像。内置 PHP7.1、Nginx、Composer。

## 分支说明

- master：最精简高效配置，使用 Runit 处理队列。
- master-spv：使用 Supervisor 代替 master 分支的 Runit 处理队列。
- allinone：该分支在 master 分支的基础上，内置 Redis、Beanstalkd。
- allinone-spv：该分支在 master-spv 分支的基础上，内置 Redis、Beanstalkd。

默认开启 Laravel 列队：`high,low,default,emails`，列队日志可直接在 HyperApp 查看，或查看容器运行日志。列队监控与管理采用 Baseimage-docker 的 Runit 模块，系统级别，纯净无添加，并且服务崩溃之后，支持后台进程自动重启。如果您偏爱 Supervisor，请参考 Dockerfile 中相关注释，重新 Build 镜像即可。

默认加入 Laravel Crontab 定时任务。

项目目录：

- Laravel 项目目录：`/var/www`

可选安装 Supervisor（日志在 Laravel app 目录下的：`/storage/logs/worker.log`）、Redis、Beanstalkd。如果要安装它们，请参考 Dockerfile 中的注释，并去掉相应被注释的代码，然后重新 Build 镜像。可选安装时可能需要暴露的目录：

- Supervisor 日志目录：`/var/log/supervisor`
- Supervisor 配置目录：`/etc/supervisor/conf.d`
- Redis 数据目录 `/var/lib/redis`
- Redis 日志目录 `/var/log/redis`
- Redis PID 目录 `/var/run/redis`
- Beanstalkd 数据目录：`/var/lib/beanstalkd/data`

## 运行容器

    docker run -d --name myapp --link mysql:db --link redis:redis -p 80:80 -v /path/to/your/laravel:/var/www sungmee/hyperlara

如果你用独立容器运行 Beanstalkd，还要加上 `--link beanstalkd:beanstalkd` 到上面命令里。

请自行将项目拷贝到宿主机目录 `/path/to/your/laravel`。或者进入容器后用 `composer` 新建项目。如下操作：

    docker exec -it myapp /bin/bash

然后

    composer create-project --prefer-dist laravel/laravel myapp

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