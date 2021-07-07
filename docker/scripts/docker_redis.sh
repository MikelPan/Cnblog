#!/usr/bin/env bash

docker stop redis
docker rm redis
[ -d "/data/redis" ] || mkdir -pv /data/redis
docker run --name redis \
    -e ALLOW_EMPTY_PASSWORD=yes \
    -v /data/redis:/bitnami/redis/data \
    -p 6379:6379 \
    -d bitnami/redis:latest