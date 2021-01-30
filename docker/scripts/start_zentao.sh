#!/usr/bin/env bash

docker stop zentao-server
docker rm zentop-server
docker run --name zentao-server \
    -p 9000:80 \
    -p 9001:3306 \
    -e ADMINER_USER="root" \
    -e ADMINER_PASSWD="password" \
    -e BIND_ADDRESS="false" \
    -v /data/zbox/:/opt/zbox/ \
    --add-host smtp.exmail.qq.com:163.177.90.125 \
    --name zentao-server \
    -d idoop/zentao:latest