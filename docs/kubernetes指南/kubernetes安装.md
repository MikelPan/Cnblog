### minikube 创建集群
#### 安装kubelet
```bash
# 添加rpm 源
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
# 安装kubectl
yum install -y kubectl
# 添加自动补全
yum install -y bash-completion
echo 'source <(kubectl completion bash)' >>~/.bashrc
kubectl completion bash >/etc/bash_completion.d/kubectl
```
#### 安装minikube
```bash
# 安装
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-arm64 /usr/local/bin/minikube
# 启动集群
yum install -y conntrack socat
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
minikube start --driver=none
minikube start --driver=none --network-plugin=cni --extra-config=kubeadm.ignore-preflight-errors=NumCPU --force --cpus 1
# 初始化
mv /root/.kube /root/.minikube $HOME
chown -R $USER $HOME/.kube $HOME/.minikube
cat >> ~/.bashrc <<- 'EOF'
alias kcp='kubectl get po -o wide  -n kube-system'
alias kcdp='kubectl delete po -n kube-system'
alias kcl='kubectl logs -f  -n kube-system'
alias kcs='kubectl get svc -n kube-system'
alias kcn='kubectl get nodes -o wide -n kube-system'
alias kce='kuebctl get endpoints -n kube-system'
alias kci='kuebctl get ing -n kube-system'
alias kcir='kubectl get ingressroute -n kube-system'
alias kca='kubectl apply -n kube-system'
alias kct='kubectl create -n kube-system'
alias kcd='kubectl describe po  -n kube-system'
alias kexec='kubectl exec -ti  -n kube-system'
alias kall='kubectl get svc,pods,nodes --all-namespaces -o wide -n kube-system'
alias kdel='kubectl delete  -n kube-system'
EOF
source ~/.bashrc
# 启动dashboard
minikube dashboard
# 安装网络插件
minikube start --network-plugin=cni
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
# 安装awx
kca https://raw.githubusercontent.com/ansible/awx-operator/devel/deploy/awx-operator.yaml
cat <<EOF | kca -f -
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
spec:
  tower_ingress_type: Ingress
  tower_hostname: awx.01member.com
  tower_image_pull_policy: Always
  tower_admin_user: admin
  tower_admin_email: test@qq.com
  tower_admin_password_secret: 
  # postgress
  tower_postgres_resource_requirements:
    requests:
      memory: 2Gi
      storage: 8Gi
    limits:
      memory: 4Gi
      storage: 50Gi
  tower_postgres_storage_class: fast-ssd
  # node selector
  tower_node_selector: |
    disktype: ssd
    kubernetes.io/arch: amd64
    kubernetes.io/os: linux
  tower_tolerations: |
    - key: "dedicated"
      operator: "Equal"
      value: "AWX"
      effect: "NoSchedule"
  tower_web_resource_requirements:
    requests:
      cpu: 200m
      memory: 1Gi
    limits:
      cpu: 800m
      memory: 2Gi
  tower_task_resource_requirements:
    requests:
      cpu: 200m
      memory: 1Gi
    limits:
      cpu: 800m
      memory: 1Gi
EOF
# 创建管理员秘钥
---
cat <<- 'EOF' | kca -f -
apiVersion: v1
kind: Secret
metadata:
  name: <resourcename>-admin-password
  namespace: <target namespace>
stringData:
  password: mysuperlongpassword
EOF
# 创建psotgress秘钥
cat <<- 'EOF' |kca -f -
apiVersion: v1
kind: Secret
metadata:
  name: awx-postgres-configuration
  namespace: <target namespace>
stringData:
  host: <external ip or url resolvable by the cluster>
  port: <external port, this usually defaults to 5432>
  database: <desired database name>
  username: <username to connect as>
  password: <password to connect with>
type: Opaque
EOF
# 查看密码
kubectl get secret awx-admin-password -o jsonpath="{.data.password}" | base64 --decode
```
### kubeadm 创建集群
#### 服务器初始化
```bash
# 创建密码
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 24 | tee ~/.init/sshkey
# 初始化
cat <<- 'EOF' | sh -
#!/usr/bin/env bash

init_os(){
    setenforce 0 \
        && sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config \
        && getenforce

    systemctl stop firewalld \
        && systemctl daemon-reload \
        && systemctl disable firewalld \
        && systemctl daemon-reload \
        && systemctl status firewalld

    yum install -y iptables-services \
        && systemctl stop iptables \
        && systemctl disable iptables \
        && systemctl status iptables

    yum install wget -y
    cp -r /etc/yum.repos.d /etc/yum.repos.d.bak
    rm -f /etc/yum.repos.d/*.repo
    wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo \
        && wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
    yum clean all && yum makecache

    cat >> /etc/security/limits.conf <<EOF
# End of file
* soft nproc 10240000
* hard nproc 10240000
* soft nofile 10240000
* hard nofile 10240000
EOF

    # [ ! -e "/etc/sysctl.conf_bk" ] && /bin/mv /etc/sysctl.conf{,_bk} \
#     && cat > /etc/sysctl.conf << EOF
# fs.file-max=1000000
# fs.nr_open=20480000
# net.ipv4.tcp_max_tw_buckets = 180000
# net.ipv4.tcp_sack = 1
# net.ipv4.tcp_window_scaling = 1
# net.ipv4.tcp_rmem = 4096 87380 4194304
# net.ipv4.tcp_wmem = 4096 16384 4194304
# net.ipv4.tcp_max_syn_backlog = 16384
# net.core.netdev_max_backlog = 32768
# net.core.somaxconn = 32768
# net.core.wmem_default = 8388608
# net.core.rmem_default = 8388608
# net.core.rmem_max = 16777216
# net.core.wmem_max = 16777216
# net.ipv4.tcp_timestamps = 0
# net.ipv4.tcp_fin_timeout = 20
# net.ipv4.tcp_synack_retries = 2
# net.ipv4.tcp_syn_retries = 2
# net.ipv4.tcp_syncookies = 1
# #net.ipv4.tcp_tw_len = 1
# net.ipv4.tcp_tw_reuse = 1
# net.ipv4.tcp_mem = 94500000 915000000 927000000
# net.ipv4.tcp_max_orphans = 3276800
# net.ipv4.ip_local_port_range = 1024 65000
# #net.nf_conntrack_max = 6553500
# #net.netfilter.nf_conntrack_max = 6553500
# #net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60
# #net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 120
# #net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120
# #net.netfilter.nf_conntrack_tcp_timeout_established = 3600
# EOF

    swapoff -a yes | cp /etc/fstab /etc/fstab_bak
    cat /etc/fstab_bak | grep -v swap > /etc/fstab

    yum install -y chrony
    cp -rf /etc/chrony.conf{,.bak}
    sed -i 's/^server/#&/' /etc/chrony.conf
    cat >> /etc/chrony.conf << EOF
server 0.asia.pool.ntp.org iburst
server 1.asia.pool.ntp.org iburst
server 2.asia.pool.ntp.org iburst
server 3.asia.pool.ntp.org iburst
EOF
    timedatectl set-timezone Asia/Shanghai
    systemctl enable chronyd && systemctl restart chronyd
    timedatectl && chronyc sources
    cat > /etc/sysconfig/modules/ipvs.modules <<EOF
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
    chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4
    yum install ipset ipvsadm -y
    sysctl --system
}
init_os
EOF

```
#### 安装docker
```bash
cat  <<EOF |sh -
#!/usr/bin/env bash

deploy_docker(){
    yum remove docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-selinux \
        docker-engine-selinux \
        docker-engine

    rm -rf /etc/systemd/system/docker.service.d
    rm -rf /var/lib/docker
    rm -rf /var/run/docker

    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager \
          --add-repo \
            http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    yum install -y docker-ce-19.03.9-3.el7
    rm -rf /etc/docker
    mkdir /etc/docker
    echo -e '{
  "exec-opts": ["native.cgroupdriver=cgroupfs"],
  "log-driver": "json-file",
  "data-root":"/var/lib/docker",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
   },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "insecure-registries": [],
  "registry-mirrors": ["https://uyah70su.mirror.aliyuncs.com"]
}' > /etc/docker/daemon.json 

    mkdir -p /etc/systemd/system/docker.service.d

    echo -e '[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
BindsTo=containerd.service
After=network-online.target firewalld.service containerd.service
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify
ExecStart=/usr/bin/dockerd
ExecStartPost=/sbin/iptables -I FORWARD -s 0.0.0.0/0 -j ACCEPT
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process

[Install]
WantedBy=multi-user.target' > /usr/lib/systemd/system/docker.service

    systemctl enable docker
    systemctl daemon-reload
    systemctl start docker

    export DOCKER_COMPOSE_VERSION=1.25.0-rc2
    curl -L https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
}
deploy_docker
EOF
```
#### 配置环境
```bash
# 配置转发
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
# 添加源
# cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
# [kubernetes]
# name=Kubernetes
# baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
# enabled=1
# gpgcheck=1
# repo_gpgcheck=1
# gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
# exclude=kubelet kubeadm kubectl
# EOF

cat << EOF |tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

sudo systemctl enable --now kubelet
sudo systemctl start kubelet
# 集群初始化
kubeadm init \
--apiserver-advertise-address=192.168.68.129 \
--image-repository registry.aliyuncs.com/google_containers \
--pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 安装网络插件
## 配置bashrc
cp /etc/kubernetes/admin.conf /root/.kube/admin.conf
alias kocp='kubectl get po -o wide --kubeconfig=/root/.kube/admin.conf -n kube-system'
alias kocdp='kubectl delete po --kubeconfig=/root/.kube/admin.conf -n kube-system'
alias kocl='kubectl logs -f --tail 200 --kubeconfig=/root/.kube/admin.conf -n kube-system'
alias kocs='kubectl get svc  --kubeconfig=/root/.kube/admin.conf kube-system'
alias kocn='kubectl get nodes -o wide --kubeconfig=/root/.kube/admin.conf -n kube-system'
alias koce='kuebctl get endpoints --kubeconfig=/root/.kube/admin.conf -n kube-system'
alias koci='kuebctl get ing  --kubeconfig=/root/.kube/admin.conf -n kube-system'
alias kocir='kubectl get ingressroute --kubeconfig=/root/.kube/admin.conf -n kube-system'
alias koca='kubectl apply --kubeconfig=/root/.kube/admin.conf -n kube-system'
alias koct='kubectl create --kubeconfig=/root/.kube/admin.conf -n kube-system'
alias kocd='kubectl describe po  --kubeconfig=/root/.kube/admin.conf -n kube-system'
alias koexec='kubectl exec -ti  --kubeconfig=/root/.kube/admin.conf -n kube-system'
alias koall='kubectl get svc,pods,nodes --all-namespaces -o wide -n kube-system'
alias kodel='kubectl delete --kubeconfig=/root/.kube/admin.conf -n kube-system'
source ~/.bashrc
## flanel
koct -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml --kubeconfig=/root/.kube/admin.conf
## calicos
curl https://docs.projectcalico.org/manifests/calico-etcd.yaml -O
## 修改configmap
etcd_ca: "/calico-secrets/etcd-ca"
etcd_cert: "/calico-secrets/etcd-cert"
etcd_key: "/calico-secrets/etcd-key"
## 修改calico-etcd-secret
cat /etc/kubernetes/pki/etcd/ca.crt |base64 -w 0 > etcd_ca
cat /etc/kubernetes/pki/etcd/service.crt |base64 -w 0 > etcd_cert
cat /etc/kubernetes/pki/etcd/service.key |base64 -w 0 > etcd_key
## 修改网卡
cat > /etc/NetworkManager/conf.d/calico.conf <<- 'EOF'
[keyfile]
unmanaged-devices=interface-name:cali*;interface-name:tunl*
EOF

# Master 允许调度
kubectl taint node localhost.localdomain node-role.kubernetes.io/master-
# Master 禁止调度
kubectl taint node localhost.localdomain node-role.kubernetes.io/master="":NoSchedule
# 添加bashrc
yum install bash-completion -y
cat >> ~/.bashrc <<EOF
source <(kubectl completion bash)
source /usr/share/bash-completion/bash_completion
source <(helm completion bash)
#export KUBECONFIG=/etc/kubernetes/admin.conf
# kubernetes alias
alias kcp='kubectl get po -o wide'
alias kcdp='kubectl delete po'
alias kcl='kubectl logs -f --tail 200'
alias kcs='kubectl get svc'
alias kcn='kubectl get nodes -o wide'
alias kce='kuebctl get endpoints'
alias kci='kuebctl get ing'
alias kcir='kubectl get ingressroute'
alias kca='kubectl apply -f'
alias kcd='kubectl describe po'
alias kexec='kubectl exec -ti'
alias kall='kubectl get svc,pods,nodes --all-namespaces -o wide'
alias kdel='kubectl delete -f '
alias k='kubectl '
EOF
source ~/.bashrc
```
### kubectl 安装使用
```bash
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
# 安装指定版本
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl
curl -LO https://dl.k8s.io/release/v1.18.6/bin/linux/amd64/kubectl
```
### Helm 安装使用
#### 安装
```bash
wget https://get.helm.sh/helm-v3.3.3-linux-amd64.tar.gz -P /usr/local/src
tar zxvf helm-v3.3.3-linux-amd64.tar.gz -C /usr/local/src
mv /usr/local/src/linux-adm64/helm /usr/bin
```
#### 使用
```bash
# 添加repo
helm repo add  elastic    https://helm.elastic.co
helm repo add  gitlab     https://charts.gitlab.io
helm repo add  harbor     https://helm.goharbor.io
helm repo add  bitnami    https://charts.bitnami.com/bitnami
helm repo add  incubator  https://kubernetes-charts-incubator.storage.googleapis.com
helm repo add  stable     https://charts.helm.sh/stable
helm repo add  aliyuncs   https://apphub.aliyuncs.com
helm repo add  traefik    https://containous.github.io/traefik-helm-chart
helm repo add  loki       https://grafana.github.io/loki/charts
helm repo add  stakater   https://stakater.github.io/stakater-charts
helm repo add  kubernetes-dashboard	 https://kubernetes.github.io/dashboard/
helm repo add  jaegertractracing     https://jaegertracing.github.io/helm-charts
helm repo update
```
#### awx 安装在k8s中
##### 下载源码
```bash
git clone -b devel https://github.com/ansible/awx.git
```
##### 创建本地卷
```yaml
# 创建目录
mkdir /data/awx/ps
# 创建sc
cat <<EOF |kubectl apply -f - 
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: awx-sc
  namespace: awx
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
# 创建静态pv
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: awx-pv
  namespace: awx
spec:
  capacity:
    storage: 5Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: awx-sc
  local:
    path: /data/awx/ps
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - localhost.localdomain
EOF
# 创建pvc
cat <<EOF |kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: awx-postgres-pvc
  namespace: awx
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: awx-sc
EOF
# 删除资源
kubectl patch pvc awx-postgres-pvc  -p '{"metadata":{"finalizers":null}}' -n awx
```

### kubernetes 维护管理
#### kubernetes 集群访问

##### 通过kubectl config访问

```bash
# 配置集群配置文件
cat > $HOME/.kube/config <<- 'EOF'
apiVersion: v1
clusters:
- cluster:
    #certificate-authority: /Users/admin/.minikube/ca.crt
    insecure-skip-tls-verify: true
    server: https://47.243.34.122:8443
  name: minikube
contexts:
- context:
    cluster: minikube
    namespace: default
    user: minikube
  name: minikube
current-context: minikube
kind: Config
preferences: {}
users:
- name: minikube
  user:
    client-certificate: /Users/admin/.minikube/client.crt
    client-key: /Users/admin/.minikube/client.key
EOF
```

##### 通过token访问
```bash
# 查看所有的集群，因为你的 .kubeconfig 文件中可能包含多个上下文
kubectl config view -o jsonpath='{"Cluster name\tServer\n"}{range .clusters[*]}{.name}{"\t"}{.cluster.server}{"\n"}{end}'

# 从上述命令输出中选择你要与之交互的集群的名称
export CLUSTER_NAME="kubernetes"

# 指向引用该集群名称的 API 服务器
APISERVER=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.server}")

# 获得令牌
TOKEN=$(kubectl get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='default')].data.token}"|base64 -d)

# 使用令牌玩转 API
curl -X GET $APISERVER/api --header "Authorization: Bearer $TOKEN" --insecure

# 使用jsonpath
APISERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
TOKEN=$(kubectl get secret $(kubectl get serviceaccount default -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 --decode )
curl $APISERVER/api --header "Authorization: Bearer $TOKEN" --insecure
```
##### 通过serviceaccount来访问
```bash
# 创建serviceaccount
kubectl create serviceaccount kubernetes-devops
# kubectl get sa kubernetes-devops  -o json
# 创建ClusterRole、RoleBinding
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: kubernetes-devops
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods", "services", "pods/log"]
  verbs: ["get", "watch", "list"]
# 绑定clusterroule
kubectl create rolebinding kubernetes-devops-read --clusterrole kubernetes-devops --serviceaccount kubernetes-devops -n default
# 获取token,ca crt,url
## 获取账号
export SERVICE_ACCOUNT=kubernetes-devops

## 获取Service Account token secret名字
SECRET=$(kubectl get serviceaccount ${SERVICE_ACCOUNT} -o json \
| jq -Mr '.secrets[].name | select(contains("token"))')

## 从secret中提取Token
TOKEN=$(kubectl get secret ${SECRET} -o json | jq -Mr '.data.token' | base64 -d)

## 从secret中提取证书文件
kubectl get secret ${SECRET} -o json | jq -Mr '.data["ca.crt"]' \
| base64 -d > /tmp/ca.crt

## 获取API Server URL，如果API Server部署在多台Master上，只需访问其中一台即可。
APISERVER=https://$(kubectl -n default get endpoints kubernetes --no-headers \
| awk '{ print $2 }' | cut -d "," -f 1)

# 访问api server
curl -s $APISERVER/api/v1/namespaces/{namespace}/pods/ \
--header "Authorization: Bearer $TOKEN" --cacert /tmp/ca.crt
```
##### 通过useraccount 访问api server
```bash
# 托管版本
使用云厂商创建子账号，赋予rbac权限
# 自建版本
## 创建私钥
openssl genrsa -out devops.key 2048
## 生成证书请求
openssl req -new -key devops.key -out devops-csr.pem -subj "/CN=devops/O=dev/O=test" # CN 用户名，O 用户组
## 生成crt
openssl x509 -req -in wolken.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out devops.crt -days 3650
## 创建kubeconfig
kubectl config set-credentials wolken --client-certificate-data=`cat devops.crt |base64 --wrap=0`  --client-key-data=`cat devops.key |base64 --wrap=0`
## 创建上下文
kubectl config set-context devops-context --cluster=kubernetes --namespace=test --user=devops
## 利用上下文连接pod
kubectl --context=devops-context get po
## 创建role
## 创建rolebinding
## 拷贝kubeconfig
cp kubeconfig /home/devops/.kube/config
```

##### 通过pod内部访问
```bash
# 指向内部 API 服务器的主机名
APISERVER=https://kubernetes.default.svc

# 服务账号令牌的路径
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount

# 读取 Pod 的名字空间
NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)

# 读取服务账号的持有者令牌
TOKEN=$(cat ${SERVICEACCOUNT}/token)

# 引用内部整数机构（CA）
CACERT=${SERVICEACCOUNT}/ca.crt

# 使用令牌访问 API
curl --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER}/api
```
#### 通过API 查询服务





