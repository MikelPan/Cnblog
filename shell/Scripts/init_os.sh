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

    [ ! -e "/etc/sysctl.conf_bk" ] && /bin/mv /etc/sysctl.conf{,_bk} \
    && cat > /etc/sysctl.conf << EOF
fs.file-max=1000000
fs.nr_open=20480000
net.ipv4.tcp_max_tw_buckets = 180000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.ipv4.tcp_max_syn_backlog = 16384
net.core.netdev_max_backlog = 32768
net.core.somaxconn = 32768
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_fin_timeout = 20
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_syncookies = 1
#net.ipv4.tcp_tw_len = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.ip_local_port_range = 1024 65000
#net.nf_conntrack_max = 6553500
#net.netfilter.nf_conntrack_max = 6553500
#net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60
#net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 120
#net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120
#net.netfilter.nf_conntrack_tcp_timeout_established = 3600
EOF

    swapoff -a yes | cp /etc/fstab /etc/fstab_bak
    cat /etc/fstab_bak | grep -v swap > /etc/fstab

    yum install -y chrony
    cp /etc/chrony.conf{,.bak}
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
    cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.ip_forward = 1
vm.swappiness=0
EOF
    sysctl --system

    cat << EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

    yum -y install wget vim iftop iotop net-tools nmon telnet lsof iptraf nmap httpd-tools lrzsz mlocate ntp ntpdate strace libpcap nethogs iptraf iftop nmon bridge-utils bind-utils telnet nc nfs-utils rpcbind nfs-utils dnsmasq python python-devel tcpdump mlocate tree

    yum install -y kubelet kubeadm kubectl ipvsadm ipset
    systemctl start kubelet && systemctl enable kubelet

    cat >> ~/.bashrc <<EOF
KUBECONFIG=/etc/kubernetes/admin.conf
# alias kubernetes
alias kcp='kubectl get po -o wide'
alias kcdp='kubectl delete po'
alias kcs='kubectl get svc'
alias kce='kubectl get enpoints'
alias kcl='kubectl logs -f'
alias kca='kubectl apply -f'
alias kcdf='kubectl delete -f'
alias kcds='kubectl delete svc'
alias kcn='kubectl get nodes -o wide'
alias kcdn='kubectl describe nodes'
EOF
    source ~/.bashrc
}
init_os