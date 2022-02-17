###
### 安装
```bash
# Dockerfile
tee > /usr/local/src/groovy/Dockerfile-gradle <<- 'EOF'
FROM openjdk:8-jdk-alpine
ENV PATH=/usr/local/gradle-6.6/bin:$PATH \
    TZ=Asia/Shanghai 
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && apk --update add --no-cache \
    && apk add curl --no-cache \
        unzip \
    && apk add -U tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo 'Asia/Shanghai' >/etc/timezone \
    && wget https://repo.spring.io/release/org/springframework/boot/spring-boot-cli/2.3.3.RELEASE/spring-boot-cli-2.3.3.RELEASE-bin.tar.gz -P /usr/local/share/ \
    && tar zxvf /usr/local/share/spring-boot-cli-2.3.3.RELEASE-bin.tar.gz -C /usr/local/ \
    && wget https://downloads.gradle-dn.com/distributions/gradle-6.6-bin.zip -P /usr/local/share \
    && unzip /usr/local/share/gradle-6.6-bin.zip -d /usr/local/ \
    && rm -rf /usr/local/share/gradle-6.6-bin.zip  \
    && rm -rf /usr/local/share/spring-boot-cli-2.3.3.RELEASE-bin.tar.gz \
    && rm -rf /var/cache/apk/* 
EOF
```