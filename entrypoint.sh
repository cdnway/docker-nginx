#!/bin/bash

# 定义 Nginx 启动命令
NGINX_CMD="/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf"

# 定义等待时间（单位：秒）
WAIT_TIME=60

# 自定义函数，用于启动 Nginx
start_nginx() {
    echo "Starting Nginx..."
    $NGINX_CMD
}

# 自定义函数，用于重启 Nginx
restart_nginx() {
    echo "Nginx is not running or has terminated unexpectedly. Restarting Nginx..."
    $NGINX_CMD
}

# 在容器启动时启动 Nginx
start_nginx

# 循环检查 Nginx 是否运行，如果没有运行则重启 Nginx
while true; do
    ps aux | grep -q '[n]ginx'
    if [ $? -ne 0 ]; then
        restart_nginx
    fi
    sleep $WAIT_TIME
done
