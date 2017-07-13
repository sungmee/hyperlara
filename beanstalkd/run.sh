#!/bin/sh
# 如果开启持久化，持久化文件保存在 /var/lib/beanstalkd/data，默认10兆一个文件
# /usr/bin/beanstalkd -b /var/lib/beanstalkd/data -s 10485760
/usr/bin/beanstalkd
