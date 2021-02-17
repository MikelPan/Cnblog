#!/usr/bin/env bash
docker stop minio
docker rm minio
docker run --name minio \
  -p 9090:9000 \
  -v /data/minio/data:/data \
  -v /data/minio/config:/root/.minio \
  -d minio/minio server /data