#!/usr/bin/env bash

BASE_DIR=$(cd "$(dirname "$0")";pwd)
cd $BASE_DIR

helpdoc(){
    cat <<EOF
Description:

    This shellscript is used to run a docker service in docker swarm
    - Domain Domain replace exmple domain
    - Second Domain if enabled, please command to 'curl -v https://Second Domain:443'
    - Service is to display to docker swarm, if not docker stack is install to faild

Usage:

    $0 -a <domain name> -b <service name> -c<second domain name>

Option:
    -a    domain name
    -b    service name
    -c    second domain name
EOF
}

while getopts "a:b:c:h:" opts
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
    c)
      #SECOND_DOMAIN:二级域名
      SECOND_DOMAIN=$OPTARG
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



# 若无指定任何参数输出帮助文档
if [ $# = 0 ]
then
  helpdoc
  exit 1
fi

# 安装filebrowers
Install_filebrower {
  sed -i "s/local.cluster/${DOMAIN}/g" docker-compose-${SERVICE_NAME}.yml
  sed -i "s/`second.local.cluster`/`${SECOND_DOMAIN}`/g" docker-compose-${SERVICE_NAME}.yml
  docker stack deploy -c docker-compose-${SERVICE_NAME}.yml ${SERVICE_NAME}
}

main {
  Install_filebrower
}

main