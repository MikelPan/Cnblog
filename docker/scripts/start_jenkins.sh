#!/usr/bin/env bash

mkdir -pv /tmp/Dockerfile
tee > /tmp/Dockerfile/Dockerfile-jenkins <<- 'EOF'
FROM jenkins/jenkins
ARG dockerGid=999
ENV JENKINS_HOME=/data/jenkins
USER root
#清除了基础镜像设置的源，切换成腾讯云的阿里云源
RUN echo '' > /etc/apt/sources.list.d/stretch-backports.list \
  && echo "deb http://mirrors.ustc.edu.cn/debian stretch main contrib non-free" > /etc/apt/sources.list \
  && echo "deb http://mirrors.ustc.edu.cn/debian stretch-updates main contrib non-free" >> /etc/apt/sources.list \
  && echo "deb http://mirrors.ustc.edu.cn/debian-security stretch/updates main contrib non-free" >> /etc/apt/sources.list \
  && apt-get update && apt-get install -y libltdl7 && apt-get update \
  && echo "docker:x:${dockerGid}:jenkins" >> /etc/group \
  && curl -L https://github.com/docker/compose/releases/download/1.26.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose \
  && chmod +x /usr/local/bin/docker-compose
EOF
cd /tmp/Dockerfile
docker build -t auto-jenkins -f Dockerfile-jenkins --no-cache . 

mkdir -pv /var/lib/jenkins
chown -R 1000 /var/lib/jenkins

tee > /tmp/Dockerfile/start_jenkins.sh <<- 'EOF'
#!/usr/bin/env bash

docker stop jenkins
docker rm jenkins
docker run --name jenkins \
    -p 8080:8080 \
    -p 50000:50000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $(which docker):/bin/docker \
    -v /var/lib/jenkins:/data/jenkins \
    -v /etc/localtime:/etc/localtime \
    -d auto-jenkins
EOF
sh -x start_jenkins.sh

status=`docker ps -a |grep jenkins |awk '{print $7}'`
if [[ $status == 'Up' ]]
then
    echo 'jenkins is deploy sucessful!'
    rm -rf /tmp/Dockerfile/*
    rm -rf /tmp/Dockerfile
else
    echo 'jenkins is deploy faild!'

