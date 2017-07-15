# HyperLara

基于 phusion/baseimage 构建的 Laravel Docker 镜像。内置 PHP7.1、Nginx、Composer、Supervisor。

可选安装 Redis、Beanstalkd。如果要安装它们，请去掉 Dockerfile 中相应被注释的代码。

默认开启 Laravel 列队：`high,low,emails`，列队日志在 Laravel app 目录下的：`/storage/logs/worker.log`。

默认开启 Laravel 定时任务。

可以暴露的目录：

- Laravel 项目目录：`/var/www`
- Supervisor 日志目录：`/var/log/supervisor`
- Supervisor 配置目录：`/etc/supervisor/conf.d`

可选安装时可能需要暴露的目录：

- Redis 数据目录 `/var/lib/redis`
- Redis 日志目录 `/var/log/redis`
- Redis PID 目录 `/var/run/redis`
- Beanstalkd 数据目录：`/var/lib/beanstalkd/data`

## 运行容器

    docker run -d --name myapp --link mysql:db --link redis:redis -p 80:80 -v /path/to/your/laravel:/var/www sungmee/hyperlara

如果你用独立容器运行 Beanstalkd，还要加上 `--link beanstalkd` 到上面命令里。

请自行将项目拷贝到宿主机目录 `/path/to/your/laravel`。或者进入容器后用 `composer` 新建项目。如下操作：

    docker exec -it myapp /bin/bash

然后

    composer create-project --prefer-dist laravel/laravel myapp