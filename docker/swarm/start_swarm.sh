#!/usr/bin/env bash

BASE_DIR=$(cd "$(dirname "$0")";pwd)
cd $BASE_DIR
while getopts "a:b:h" opts
do
  case $opts in
    a)
      #DOMAIN:域名
      DOMAIN=$OPTARG
      ;;
    b)
      #SERVICE_NAME:服务名称
      SERVICE_NAME=$OPTARG
      ;;
    h)
      echo -e "OPTTIONS:\n-a:域名(必选) \n-b:服务名(必选)"
      exit 1
      ;;
    ?)
      echo "missing options,pls check!"
      exit 1
      ;;
  esac
done

#可选参数赋值

# 安装filebrowers
Install_filebrower {
  sed -i 's/local.cluster/${DOMAIN}/g' docker-compose-${SERVICE_NAME}.yml
  docker stack deploy -c docker-compose-${SERVICE_NAME}.yaml ${SERVICE_NAME}
}

main {
  Install_filebrower
}

main
