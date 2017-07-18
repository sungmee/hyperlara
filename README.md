# HyperLara

基于 `phusion/baseimage` 构建的 Laravel Docker 镜像。内置 PHP7.1、Nginx、Composer。

其它分支支持 Redis、Beanstalkd 和 Supervisor 服务。

## 分支列表

- [Tag: `latest`] [master](https://github.com/sungmee/hyperlara/blob/master/Dockerfile) -- 最精简高效配置，使用系统自带的 Runit 处理队列。
- [Tag: `spv`] [master-spv](https://github.com/sungmee/hyperlara/blob/master-spv/Dockerfile) -- 使用 Supervisor 代替 master 分支的 Runit 处理队列。
- [Tag: `allinone`] [allinone](https://github.com/sungmee/hyperlara/blob/allinone/Dockerfile) -- 该分支在 master 分支的基础上，内置 Redis、Beanstalkd。
- [Tag: `aspv`] [allinone-spv](https://github.com/sungmee/hyperlara/blob/allinone-spv/Dockerfile) -- 该分支在 master-spv 分支的基础上，内置 Redis、Beanstalkd。

## 镜像说明

默认开启 Laravel 列队：`high,low,default,emails`，列队日志可直接在 HyperApp 查看，或查看容器运行日志。列队监控与管理采用 Baseimage-docker 的 Runit 模块，系统级别，纯净无添加，并且服务崩溃之后，支持后台进程自动重启。如果您偏好 Supervisor 来管理并守护列队进程，请选用 spv 分支。

默认加入 Laravel Crontab 定时任务。

## 应用目录

Laravel 项目目录：`/var/www`

其它分支可能会用到的目录：

- Supervisor 日志目录：`/var/log/supervisor`
- Supervisor 配置目录：`/etc/supervisor/conf.d`
- Redis 数据目录 `/var/lib/redis`
- Redis 日志目录 `/var/log/redis`
- Redis PID 目录 `/var/run/redis`
- Beanstalkd 数据目录：`/var/lib/beanstalkd/data`

PS：Laravel Worker 列队的日志记录在 Laravel app 目录下的 `/storage/logs/worker.log` 中。

## 运行容器

### master 和 master-spv 分支

    docker run -d --name myapp --link mysql:db --link redis:redis --link beanstalkd:beanstalkd -p 80:80 -v /path/to/your/laravel:/var/www sungmee/hyperlara

### allinone 和 allinone-spv 分支

    docker run -d --name myapp --link mysql:db -p 80:80 -v /path/to/your/laravel:/var/www sungmee/hyperlara

## 初始化项目

将项目拷贝到宿主机目录 `/path/to/your/laravel`。如果您需要通过 `composer.json` 文件初始化项目（须先将其拷贝入您宿主机的项目目录）。也可以在空的 `/path/to/your/laravel` 中新建 Laravel 项目，请在宿主机中运行以下命令：

    docker exec myapp lara-setup

稍做等候，脚本将自动帮您安装好项目依赖，或者初始化一个新的 Laravel 项目。

## 快捷命令

清理缓存：`docker exec myapp php artisan cache:clear` 或者进入容器（`docker exec -it myapp /bin/bash`）后在 /var/www 目录中运行命令别名 `art cache:clear`

数据表迁移：`docker exec myapp php artisan migrate` 或者进入容器 `docker exec -it myapp /bin/bash` 后在 /var/www 目录中运行命令别名 `art migrate`

其它快捷命令：

- `..` 切换到上一级目录
- `...` 切换到上两级目录
- `....` 切换到上三级目录
- `c` 清屏
- `ff` 搜索文件
- `fd` 搜索文件夹
- ...

更多快捷命令，请查阅文件 [aliases.sh](https://github.com/sungmee/hyperlara/blob/master/build/aliases.sh)

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