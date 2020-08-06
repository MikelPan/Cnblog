### jenkins简介
Jenkins是一个自包含的开源自动化服务器，可用于自动化与构建，测试以及交付或部署软件有关的各种任务。
Jenkins可以通过本机系统软件包Docker安装，甚至可以由安装了Java Runtime Environment（JRE）的任何计算机独立运行。

### jenkins安装
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

node()
{
    job_name="${env.JOB_NAME}".replace('%2F','/').split('/')
    job_name=job_name[0]

    workspace="data/jenkins/workspace/CICD"

    ws("$workspace")
    {
        dir("pipeline")
        {
            git url: 'https://'
            def check_groovy_file="${job_name}/${env.BRANCH_NAME}/Jenkinsfile"
            load "${check_groovy_file"}
        }
    }
}
```