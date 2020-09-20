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
cat <<EOF | sh -
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
    yum install -y docker-ce
    rm -rf /etc/docker
    mkdir /etc/docker
    cat > /etc/docker/daemon.json <<EOF
{
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
}
EOF

    mkdir -p /etc/systemd/system/docker.service.d
    cat > /usr/lib/systemd/system/docker.service <<EOF
[Unit]
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
WantedBy=multi-user.target
EOF
    systemctl enable docker
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
--apiserver-advertise-address=192.168.174.138 \
--image-repository registry.aliyuncs.com/google_containers \
--pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 安装网络插件
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
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
helm repo add  stable     https://kubernetes-charts.storage.googleapis.com
helm repo add  aliyuncs   https://apphub.aliyuncs.com
helm repo add  stable     https://kubernetes-charts.storage.googleapis.com
helm repo add  traefik    https://containous.github.io/traefik-helm-chart
helm repo add  loki       https://grafana.github.io/loki/charts
helm repo add  stakater   https://stakater.github.io/stakater-charts
helm repo add  kubernetes-dashboard	 https://kubernetes.github.io/dashboard/
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