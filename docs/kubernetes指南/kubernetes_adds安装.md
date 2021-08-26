### 安装Jenkins
```bash
# 安装jenkins helm
helm upgrade --install helm-jenkins stable/jenkins --set master.serviceType=NodePort,master.nodePort=30010 -n default --debug
# 查看密码
printf $(kubectl get secret --namespace default helm-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
# 修改插件源
sed -i 's/http:\/\/updates.jenkins-ci.org\/download/https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins/g' default.json && sed -i 's/http:\/\/www.google.com/https:\/\/www.baidu.com/g' default.json
# 安装插件
kubernetes

```

### 安装harbor
