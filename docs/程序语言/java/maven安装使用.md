### maven 介绍
Maven 是基于项目对象模型（POM），可以通过一小段描述信息来管理项目的构建、报告和文档的软件项目管理工具。简单来说Maven 可以帮助我们更有效的管理项目。
同时也是一套强大的自动化构建工具。覆盖了编译、测试、运行、清理，打包和部署整个项目构建周期。

Maven 提供了仓库的概念，统一管理项目依赖的第三方jar包。最大限度的避免因环境配置不同导致编译出错的问题，比如在我的电脑上能运行，在其他电脑不能运行的尴尬问题。
目前大部分互联网公司都在适用Maven 管理项目。

maven官网：http://maven.apache.org/

下载二进制文件：
https://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.zip
https://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz

### 安装
#### linux
```bash
# 添加jdk环境变量
cat > /etc/profile.d/jdk.sh <<EOF
export JAVA_HOME=/usr/local/jdk1.8.0_221
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:$PATH
EOF
# 添加mvn环境变量
cat > /etc/profile.d/mvn.sh <<EOF
export MAVEN_HOME=/usr/local/apache-maven-3.6.3
export PATH=${MAVEN_HOME}/bin:$PATH
EOF
```

#### windows
```bash
# 配置环境变量
创建M2_HOME : E:\Program Files\apache-maven-3.6.1
修改PATH，在PATH的最后加上：%M2_HOME%\bin
```
### maven 创建项目
```bash
mvn archetype:generate -DgroupId=site.plyx.yunfeigj -DartifactId=yunfeigj-devops -DarchetypeArtifactId=maven-archetype-quickstart  -DinteractiveMode=false
-- groupId 组织名
-- artifactId 项目名
-- version 版本号
```

### maven 常用命令
|命令|功能|备注|
|----|----|----|
|mvn compile|编译源代码|这个过程会下载工程所有依赖的jar包|
|mvn clean|清理环境|清理target目录|
|mvn test|执行单元测试用例||
|mvn install|安装jar包到本地仓库|
|mvn dependency:tree|树型显示maven依赖关系|用于排查依赖冲突的问题|
|mvn dependency:list|显示maven依赖列表||
|mvn package|打包，将java工程打成jar包或war包||

### 跟换阿里云源
```xml
<mirror>
    <id>nexus-aliyun</id>
    <mirrorOf>*</mirrorOf>
    <name>Nexus aliyun</name>
    <url>http://maven.aliyun.com/nexus/content/groups/public</url>
</mirror>

<mirrors>
	<mirror>
        <id>aliyun-public</id>
        <mirrorOf>*</mirrorOf>
        <name>aliyun public</name>
        <url>https://maven.aliyun.com/repository/public</url>
    </mirror>
    <mirror>
        <id>aliyun-central</id>
        <mirrorOf>*</mirrorOf>
        <name>aliyun central</name>
        <url>https://maven.aliyun.com/repository/central</url>
    </mirror>
    <mirror>
        <id>aliyun-spring</id>
        <mirrorOf>*</mirrorOf>
        <name>aliyun spring</name>
        <url>https://maven.aliyun.com/repository/spring</url>
    </mirror>
    <mirror>
        <id>aliyun-spring-plugin</id>
        <mirrorOf>*</mirrorOf>
        <name>aliyun spring-plugin</name>
        <url>https://maven.aliyun.com/repository/spring-plugin</url>
    </mirror>
    <mirror>
        <id>aliyun-apache-snapshots</id>
        <mirrorOf>*</mirrorOf>
        <name>aliyun apache-snapshots</name>
        <url>https://maven.aliyun.com/repository/apache-snapshots</url>
    </mirror>
    <mirror>
        <id>aliyun-google</id>
        <mirrorOf>*</mirrorOf>
        <name>aliyun google</name>
        <url>https://maven.aliyun.com/repository/google</url>
    </mirror>
    <mirror>
        <id>aliyun-gradle-plugin</id>
        <mirrorOf>*</mirrorOf>
        <name>aliyun gradle-plugin</name>
        <url>https://maven.aliyun.com/repository/gradle-plugin</url>
    </mirror>
    <mirror>
        <id>aliyun-jcenter</id>
        <mirrorOf>*</mirrorOf>
        <name>aliyun jcenter</name>
        <url>https://maven.aliyun.com/repository/jcenter</url>
    </mirror>
    <mirror>
        <id>aliyun-releases</id>
        <mirrorOf>*</mirrorOf>
        <name>aliyun releases</name>
        <url>https://maven.aliyun.com/repository/releases</url>
    </mirror>

    <mirror>
        <id>aliyun-snapshots</id>
        <mirrorOf>*</mirrorOf>
        <name>aliyun snapshots</name>
        <url>https://maven.aliyun.com/repository/snapshots</url>
    </mirror>
    <mirror>
        <id>aliyun-grails-core</id>
        <mirrorOf>*</mirrorOf>
        <name>aliyun grails-core</name>
        <url>https://maven.aliyun.com/repository/grails-core</url>
    </mirror>
    <mirror>
        <id>aliyun-mapr-public</id>
        <mirrorOf>*</mirrorOf>
        <name>aliyun mapr-public</name>
        <url>https://maven.aliyun.com/repository/mapr-public</url>
    </mirror>
  </mirrors>
```
### maven 初始化spring boot 项目

