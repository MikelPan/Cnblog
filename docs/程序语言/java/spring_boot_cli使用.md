## Spring Boot CLI：安装CLI和使用CLI
### Spring Boot CLI
Spring Boot CLI是一个命令行工具，如果想使用Spring进行快速开发可以使用它。它允许你运行Groovy脚本，这意味着你可以使用熟悉的类Java语法，并且没有那么多的模板代码。你可以通过Spring Boot CLI启动新项目，或为它编写命令。
### Spring Boot CLI 安装
```bash
# 下载
wget https://repo.spring.io/release/org/springframework/boot/spring-boot-cli/2.3.3.RELEASE/spring-boot-cli-2.3.3.RELEASE-bin.tar.gz -P /usr/local/src
tar zxvf /usr/local/src/spring-boot-cli-2.3.3.RELEASE-bin.tar.gz -C /usr/local/
```
```bash
# 添加环境变量
tee > /etc/profile.s/spring.sh <<- 'EOF'
export SPRING_HOME=/usr/local/spring-2.3.3.RELEASE
export CLASSPATH=.:${SPRING_HOME}/lib:$CLASSPATH
export PATH=${SPRING_HOME}/bin:$PATH
EOF
source /etc/profile
```
### 使用
#### 基础命令
```bash
usage: spring [--help] [--version] 
       <command> [<args>]

Available commands are:

  run [options] <files> [--] [args]
    Run a spring groovy script

  grab                
    Download a spring groovy script's dependencies to ./repository

  jar [options] <jar-name> <files>
    Create a self-contained executable jar file from a Spring Groovy script

  war [options] <war-name> <files>
    Create a self-contained executable war file from a Spring Groovy script

  install [options] <coordinates>
    Install dependencies to the lib/ext directory

  uninstall [options] <coordinates>
    Uninstall dependencies from the lib/ext directory

  init [options] [location]
    Initialize a new project using Spring Initializr (start.spring.io)

  encodepassword [options] <password to encode>
    Encode a password for use with Spring Security

  shell                
    Start a nested shell

Common options:

  --debug Verbose mode   
    Print additional status information for the command you are running


See 'spring help <command>' for more information on a specific command.
```
#### 运行脚本
- 启动groovy脚本
```groovy
[[ -d "/usr/local/src/groovy" ]] || mkdir -pv /usr/local/src/groovy
tee > /usr/local/src/groovy/helloworld.groovy <<- 'EOF'
@RestController
class Hello {
    @RequestMapping("/hello")
    def hello() {
        return "Hello World Groovy!";
    }
}
EOF
spring run /usr/local/src/groovy/helloworld.groovy -- --server.port=9000 &
```
- 启动java脚本
```java
[[ -d "/usr/local/src/java" ]] || mkdir -pv /usr/local/src/java
tee > /usr/local/src/java/helloworld.java <<- 'EOF'
@RestController
public class Hello {
    @RequestMapping("/hello")
    public String hello() {
        return "Hello World Java!";
    }
}
EOF
spring run /usr/local/src/java/helloworld.java -- --server.port=9001 &
```
- 制作Dockerfile
```bash
# Dockerfile
tee > /usr/local/src/groovy/Dockerfile-spring <<- 'EOF'
FROM openjdk:8-jdk-alpine
ARG PORT
ARG JAR_NAME
ENV JAR_NAME=$JAR_NAME \
    PORT=$PORT \
    SPRING_HOME=/usr/local/spring-2.3.3.RELEASE \
    CLASSPATH=.:/usr/local/spring-2.3.3.RELEASE/lib \
    PATH=/usr/local/spring-2.3.3.RELEASE/bin:$PATH \
    TZ=Asia/Shanghai \
    APPLICATION_ENV=dev \
    APPLICATION_DIR=/apps/
WORKDIR /apps
ADD ${JAR_NAME} /apps 
ADD application-dev.yml /apps
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && apk --update add --no-cache \
    && apk add curl --no-cache \
    && apk add -U tzdata \
    && apk add --no-cache bash \
        bash-doc \
        bash-completion \
    && /bin/bash \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo 'Asia/Shanghai' >/etc/timezone \
    && wget https://repo.spring.io/release/org/springframework/boot/spring-boot-cli/2.3.3.RELEASE/spring-boot-cli-2.3.3.RELEASE-bin.tar.gz -P /usr/local/share/ \
    && tar zxvf /usr/local/share/spring-boot-cli-2.3.3.RELEASE-bin.tar.gz -C /usr/local/ \
    && rm -rf /usr/local/share/spring-boot-cli-2.3.3.RELEASE-bin.tar.gz \
    && rm -rf /var/cache/apk/* \
EXPOSE ${PORT}
#CMD ["/bin/bash"]
ENTRYPOINT ["sh","-c","spring run  $JAR_NAME -- --spring.config.location=$APPLICATION_DIR --spring.profiles.active=$APPLICATION_ENV"]
EOF
# build image
docker build -t spring:v1.0 --build-arg  PORT=9000 --build-arg JAR_NAME=helloworld.groovy -f Dockerfile-spring .
# docker run
docker run --rm -itd spring:v1.0 sh
curl -v localhost:9000
```
- 初始化项目
```bash
# 运行命令
spring init -d=web --build=gradle --name devops --java-version 1.8 --groupId cn.jt7t.springboot --artifactId springboot-devops --language java --boot-version 2.3.2.RELEASE --type maven-project --extract
# 参数说明
1、-d 添加依赖
2、--build 编译类型
3、--java-version java版本
4、--groupId 组织名称，一般为域名+项目名
5、--artifactId 子模块，一般为部分或岗位名称
6、--language  语言类型
7、--boot-version springboot版本
8、--type 项目类型
9、--extract 在当前目录解压
# 生成的文件目录如下：
.
├── HELP.md
├── mvnw
├── mvnw.cmd
├── pom.xml
└── src
    ├── main
    │   ├── java
    │   │   └── cn
    │   │       └── jt7t
    │   │           └── springboot
    │   │               └── springbootdevops
    │   │                   └── DevopsApplication.java
    │   └── resources
    │       ├── application.properties
    │       ├── static
    │       └── templates
    └── test
        └── java
            └── cn
                └── jt7t
                    └── springboot
                        └── springbootdevops
                            └── DevopsApplicationTests.java

16 directories, 7 files
# 清除一下不需要的文件
rm -rf mvnw* HELP.md
```


