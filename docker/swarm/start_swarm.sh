#!/usr/bin/env bash

BASE_DIR=$(cd "$(dirname "$0")";pwd)
cd $BASE_DIR

helpdoc(){
    cat <<EOF
Description:

    This shellscript is used to run a docker service in docker swarm
    - Domain replace exmple domain, if enabled, please command to 'curl -v https://Domain:443'
    - Service is to display to docker swarm, if not docker stack is install to faild

Usage:

    $0 -a <domain name> -b <service name> 

Option:
    -a    domain name
    -b    service name
EOF
}

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
      helpdoc
      exit 0
      ;;
    ?)
      echo "missing options,pls check!"
      helpdoc
      exit 1
      ;;
  esac
done

#可选参数赋值

# 安装filebrowers
Install_filebrower {
  sed -i 's/local.cluster/${DOMAIN}/g' docker-compose-${SERVICE_NAME}.yml
  docker stack deploy -c docker-compose-${SERVICE_NAME}.yml ${SERVICE_NAME}
}

main {
  Install_filebrower
}

# 若无指定任何参数输出帮助文档
if [ $# = 0 ]
then
  helpdoc
  exit 1
fi

main
