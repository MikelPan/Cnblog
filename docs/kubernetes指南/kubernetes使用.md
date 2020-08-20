### helm 使用
#### helｍ安装
```bash
wget https://get.helm.sh/helm-v3.2.4-linux-amd64.tar.gz -P /usr/local/src
tar zxvf helm-v3.2.4-linux-amd64 -C /usr/local/src
mv linux-adm64/helm /usr/local/bin
```
#### helm使用
```bash
# 添加repo
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com	
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add aliyuncs https://apphub.aliyuncs.com
# 跟换阿里云char
helm repo add stable https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
# 查看char
helm search repo
# 添加自动补全
yum install bash-completion -y
source /usr/share/bash-completion/bash_completion
source <(helm completion bash)
```
##### 创建char
helm create test 
