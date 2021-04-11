#!/usr/bin/env bash

docker stop rabbitmq-server
docker rm rabbitmq-server
docker run --name rabbitmq-server --restart=alwsys \
  -p 5672:5672 \
  -p 15672:15672 \
  -v /var/lib/rabbitmq:/var/lib/rabbitmq \
  -v /etc/rabbitmq/rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf \
  --hostname hostname \
  -e RABBITMQ_DEFAULT_VHOST=rabbitmq-server \
  -e RABBITMQ_DEFAULT_USER=admin \
  -e RABBITMQ_DEFAULT_PASS=admin \
  -d rabbitmq:3.8.14-management
