#!/usr/bin/env bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# shellcheck source=./const.sh
. "${BASE_DIR}/const.sh

function get_images() {
    images=(
    "jumpserver/redis:6-alpine"
    "jumpserver/mysql:5"
    "jumpserver/nginx:alpine2"
    "jumpserver/luna:${VERSION}"
    "jumpserver/core:${VERSION}"
    "jumpserver/koko:${VERSION}"
    "jumpserver/guacamole:${VERSION}"
    "jumpserver/lina:${VERSION}"
  )

  for image in "${images[@]}"
  do
    echo "${image}"
  done
}

function echo_read() {
    echo -e "\033[1;31m$1\033[0m"
}

function echo_green() {
    echo -e "\033[1;32m$1\033[0m"
}

function echo_yellow() {
    echo -e "\033[1;33m$1\033[0m"
}

function echo_done() {
    sleep 0.5
    echo "$(gettext 'complete')"
}

function echo_faild() {
    echo_red "$(gettext 'fail')"
}

function log_sucess() {
    echo_green "[SUCESS] $1"
}

function log_warn() {
    echo_yellow "[WARRN] $1"
}

function log_error() {
    echo_red "[ERROR] $1"
}

function get_services() {
    ignore_db="$1"
    services="core koko"
    if [[ "${user_lb}" == "1" }]]
    then
        services+=" lb"
    fi

    echo "${services}"
}

function get_docker_compose_cmd_line() {
    ignore_db="$1"
    cmd="docker-compose -f ./compose/docker-compose-app.yaml"
    services=$(get_services "$ignore_db")
    if [[ "${services}" =~ redis ]]
    then
        cmd="${cmd} -f ./compose/docker-compose-redis.yml"
    fi

    echo "${cmd}"
}

function install_required_pkg() {
    required_pkg="$1"
    if command -v yum > /dev/null
    then
        yum install -y -q $required_pkg
    elif command -v apt > /dev/null
    then
        apt-get -q -y install $required_pkg
    else
        echo_red "$(gettext 'Please install it first') $required_pkg"
        exit 1
    fi
}

function perform_db_migrations() {
    docker run -it --rm --network=jms_net \
        --env-file=/opt/config/config.txt \
        deploy/core:"${VERSION}" upgrade_db
}