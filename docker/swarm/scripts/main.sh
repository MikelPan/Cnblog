#!/bin/bash

# 安装filebrowers
Install {
  sed -i "s/local.cluster/${DOMAIN}/g" ../docker-compose-${SERVICE_NAME}.yml
  sed -i "s/`second.local.cluster`/`${SECOND_DOMAIN}`/g" ../docker-compose-${SERVICE_NAME}.yml
  docker stack deploy -c ../docker-compose-${SERVICE_NAME}.yml ${SERVICE_NAME}
}

main {
  Install
}

main "$@"
