#!/usr/bin/env bash

docker stop redis-server
docker rm redis-server
docker run --name redis-server \
  -p 6379:6379 \
  -v /data/redis/conf/redis.conf:/etc/redis/conf \
  -v /data/redis/data:/data \
  --restart always \
  -d redis:5.0.12 redis-server /etc/redis/redis.conf