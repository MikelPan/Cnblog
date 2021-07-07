#!/usr/bin/env bash

docker stop redis
docker rm redis
[ -d "/data/redis" ] || mkdir -pv /data/redis
docker run --name redis \
    -e ALLOW_EMPTY_PASSWORD=yes \
    -v /data/redis:/bitnami/redis/data \
    -d bitnami/redis:latest