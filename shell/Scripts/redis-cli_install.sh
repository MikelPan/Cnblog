#!/usr/bin/env bash

wget https://download.redis.io/releases/redis-5.0.10.tar.gz -P /usr/local/src 
tar zxvf /usr/local/src/redis-5.0.10.tar.gz
cd /usr/local/src/redis-5.0.10
make
cp /usr/local/src/redis-5.0.10/src/redis-cli