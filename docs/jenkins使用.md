### jenkins简介
Jenkins是一个自包含的开源自动化服务器，可用于自动化与构建，测试以及交付或部署软件有关的各种任务。
Jenkins可以通过本机系统软件包Docker安装，甚至可以由安装了Java Runtime Environment（JRE）的任何计算机独立运行。

### jenkins安装
```bash
# 物理机安装
## 安装java环境
wget https://download.oracle.com/otn/java/jdk/8u261-b12/a4634525489241b9a9e1aa73d9e118e6/jdk-8u261-linux-x64.tar.gz?AuthParam=1597552691_67429c142927b21fadba4cd7de9df6e5
mv jdk-8u261-linux-x64.tar.gz?AuthParam=1597552691_67429c142927b21fadba4cd7de9df6e5 jdk-8u261-linux-x64.tar.gz
tar zxvf jdk-8u261-linux-x64.tar.gz -C /usr/local
tee > /etc/profile.d/jdk.sh <<- 'EOF'
export JAVA_HOME=/usr/local/jdk1.8.0_261
export JRE_HOME=${JAVA_HOME}/jre
export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib
export PATH=${JAVA_HOME}/bin:$PATH
EOF
source /etc/profile
## 安装jenkins
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yum clean all
yum makecache
yum install jenkins -y
### 无法拉取官方源
yum install -y https://mirrors.tuna.tsinghua.edu.cn/jenkins/redhat-stable/jenkins-2.235.4-1.1.noarch.rpm
### 修改配置
sed -i 's/^JENKINS_USER/#JENKINS_USER/' /etc/sysconfig/jenkins
sed -i 's/^JENKINS_HOME/#JENKINS_HOME/' /etc/sysconfig/jenkins
sed -i 's/^JENKINS_PORT/#JENKINS_PORT/' /etc/sysconfig/jenkins
tee >> /etc/sysconfig/jenkins <<- 'EOF'
# jenkins configurage
JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true -Dorg.jenkinsci.plugins.gitclient.Git.timeOut=60"
JENKINS_USER="root"
JENKINS_HOME="/data/jenkins"
JENKINS_PORT="8080"
EOF
sed -i '/candidates/a\/usr/local/jdk1.8.0_221/bin/java' /etc/init.d/jenkins
systemctl enable jenkins
mkdir -pv /data/jenkins
systemctl start jenkins
### 修改默认镜像源
cp /data/jenkins/hudson.model.UpdateCenter.xml /data/jenkins/hudson.model.UpdateCenter.xml.bak
tee > /data/jenkins/hudson.model.UpdateCenter.xml <<- 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<sites>
  <site>
    <id>default</id>
    <url>https://mirrors.tuna.tsinghua.edu.cn/jenkins/updates/update-center.json</url>
  </site>
</sites>
EOF
## 访问
cat /data/jenkins/secrets/initialAdminPassword
curl -v http://localhost:8080
# docker 安装
## 制作镜像
tee > Dockerfile <<- 'EOF'
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
## 启动jenkins
chown -R 1000 /data/jenkins
docker run --name jenkins \
    -p 8080:8080 \
    -p 50000:50000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $(which docker):/bin/docker \
    -v /data/jenkins:/data/jenkins \
    -d auto-jenkins
```
### 常用插件安装
```bash
Build Monitor View
Workspace Cleanup
Disk Usage
Multijob plugin
Build Pipeline Plugin：灰度发布
Mask Passwords Plugin：密码加密
Configuration Slicing Plugin：批量修改JOB的配置
BlueOcean
Locale
```
### jenkins升级
```bash

```
### jenkinsfile脱离代码仓库
#### 安装插件
```bash
1、Config File Provider Plugin
2、Pipeline: Multibranch with defaults
```
#### 配置jenkins
```groovy
// 添加default jenkinsfile
#!/usr/bin/env groovy
import groovy.transform.Field

@Field def job_name=""

node() {

    environment {
       PATH = "/usr/local/git/bin:$PATH" 
    }

    job_name="${env.JOB_NAME}".replace('%2F','/').split('/')
    job_name=job_name[0]

    workspace="/data/jenkins/workspace/CICD"

    ws("$workspace")
    {
      dir('Cnblog')
      {
        git url: 'https://github.com/MikelPan/Cnblog.git'
        def check_groovy_file="kubernetes/CICD/Jenkinsfile/${job_name}/${env.BRANCH_NAME}/Jenkinsfile.groovy"
        load "${check_groovy_file}"
      }
    }
}
//  在项目根目录中实现如下结构
---Cnblog
  ---master
    ---Jenkinsfile
```
### jenkins 忘记管理员密码
```bash
# 删除jenkins目录中的config.xml中的下面部分
<useSecurity>true</useSecurity>  
<authorizationStrategy class="hudson.security.FullControlOnceLoggedInAuthorizationStrategy">  
  <denyAnonymousReadAccess>true</denyAnonymousReadAccess>  
</authorizationStrategy>  
<securityRealm class="hudson.security.HudsonPrivateSecurityRealm">  
  <disableSignup>true</disableSignup>  
  <enableCaptcha>false</enableCaptcha>  
</securityRealm>
# 重启Jenkins服务；
# 进入首页>“系统管理”>“Configure Global Security”；
# 勾选“启用安全”；
# 点选“Jenkins专有用户数据库”，并点击“保存”；
# 重新点击首页>“系统管理”,发现此时出现“管理用户”；
# 点击进入展示“用户列表”；
# 点击右侧进入修改密码页面，修改后即可重新登录
```







