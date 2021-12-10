#!/bin/sh

# 此脚本可以用来更新docker镜像
# 建议在服务端停止后再运行

# 拉取最新镜像
docker-compose pull
# 清理旧的镜像
docker image prune -f
