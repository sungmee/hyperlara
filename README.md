# HyperLara

基于 phusion/baseimage 构建的 Laravel Docker 镜像。内置 php7.1、nginx、composer、redis、beanstalkd、supervisor。

默认开启 Laravel 列队：`high,low,emails`，列队日志在 Laravel app 目录下的：`/storage/logs/worker.log`。

默认开启 Laravel 定时任务。

- Laravel app 目录：`/var/www`
- Redis 数据目录：`/data`
- Beanstalkd 数据目录：`/var/lib/beanstalkd/data`
- Supervisor 日志目录：`/var/log/supervisor`