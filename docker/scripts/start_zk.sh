#!/usr/bin/env bash

docker stop zk
docker rm zk
docker run --name zk \
  -p 2181:2181 \
  --restart always \
  -d zookeeper