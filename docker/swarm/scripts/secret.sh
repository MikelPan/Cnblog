#!/usr/bin bash

cat /root/ssl/aliyun_region_id |docker secret create aliyun_region_id -
cat /root/ssl/aliyun_secret_key |docker secret create aliyun_secret_key -
cat /root/ssl/aliyun_access_key |docker secret create aliyun_access_key -