#!/usr/bin/env bash

docker stop mysql-server
docker rm mysql-server
docker run --name mysql-server \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=123456 \
  -v /var/lib/mysql:/var/lib/mysql \
  --restart always \
  -d mysql:5.7.33 --character-set-server=utf8mb4 --collation-server=utf8mb4_general_ci
