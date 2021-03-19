#!/usr/bin/env bash

# jenkins 打包镜像
tee > /tmp/Dockerfile <<- 'EOF'
FROM jenkins/jenkins
ARG dockerGid=999
ENV JENKINS_HOME=/data/jenkins
USER root
#清除了基础镜像设置的源，切换成腾讯云的阿里云源
RUN echo '' > /etc/apt/sources.list.d/jessie-backports.list \
  && echo "deb http://mirrors.aliyun.com/debian jessie main contrib non-free" > /etc/apt/sources.list \
  && echo "deb http://mirrors.aliyun.com/debian jessie-updates main contrib non-free" >> /etc/apt/sources.list \
  && echo "deb http://mirrors.aliyun.com/debian-security jessie/updates main contrib non-free" >> /etc/apt/sources.list \
  && apt-get update && apt-get install -y libltdl7 && apt-get update \
  && echo "docker:x:${dockerGid}:jenkins" >> /etc/group \
  && curl -L https://github.com/docker/compose/releases/download/1.26.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose \
  && chmod +x /usr/local/bin/docker-compose
EOF
docker build -t auto-jenkins -f /tmp/Dockerfile --no-cache .
## 启动jenkins
chown -R 1000 /data/jenkins
docker run --name jenkins \
    -p 8080:8080 \
    -p 50000:50000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $(which docker):/bin/docker \
    -v /data/jenkins:/data/jenkins \
    -v /etc/localtime:/etc/localtime \
    -d auto-jenkins
rm -rf /tmp/Dockerfile
