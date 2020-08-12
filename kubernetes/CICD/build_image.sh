#!/bin/bash
PROJECT=$1
MODULE=$2
DOCKERFILE=$3
JAR_DIR=$4
JAR_NAME=$5
PORT=$6
TAG=$7
REGISTRY="harbor.plyx.site:8100/${PROJECT}/${MODULE}"
TIME=`data +"%Y%%m%d%H%M%S"`
IMAGE_NAME=${REGISTRY}:${TIME}_${TAGE}
docker build -t ${IMAGE_NAME} --build-arg jar_dir=${JAR_DIR} jar_name=${JAR_NAME} port=${PORT} ${DOCKERFILE}
docker push ${IMAGE_NMAE}