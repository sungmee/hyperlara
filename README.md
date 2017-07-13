# HyperLara

基于 phusion/baseimage 构建的 Laravel Docker 镜像。内置 PHP7.1、Nginx、Composer、Redis、Beanstalkd、Supervisor。

默认开启 Laravel 列队：`high,low,emails`，列队日志在 Laravel app 目录下的：`/storage/logs/worker.log`。

默认开启 Laravel 定时任务。

- Laravel 项目目录：`/var/www`
- Redis 数据目录 `/var/lib/redis`
- Redis 日志目录 `/var/log/redis`
- Redis PID 目录 `/var/run/redis`
- Beanstalkd 数据目录：`/var/lib/beanstalkd/data`
- Supervisor 日志目录：`/var/log/supervisor`
- Supervisor 配置目录：`/etc/supervisor/conf.d`