#！/bin/bash
########################################################################################################################
# File Name: 1.bash
# Version:Version1.0
# Author:Mikel
# Create Time:Date
#########################################################################################################################
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
source /etc/profile
[ $(id-u) -gt 0 ] && echo "请用root用户执行此脚本!" && exit 1
centosVersion=$(awk '{print $(NF-1)}' /etc/redhat-release)
VERSION=`date +%F`
#日志相关
PROGPATH=`echo $0 | sed -e 's,[\\\\/][^\\\\/][^\\\\/]*$,,'`
[ -f $PROGPATH ] && PROGPATH="."
LOGPATH="$PROGPATH/log"
[ -e $LOGPATH ] || mkdir $LOGPATH
RESULTFILE="$LOGPATH/HostDailyCheck-`hostname`-`date +%Y%m%d`.txt"
#定义报表的全局变量
report_DateTime=" "
report_Hostname=" "
report_OSRelease=" "
report_Kernel=" "
report_Language=" "
report_LastReboot=" "
report_Uptime=" "
report_CPUs=" "
report_CPUType=" "
report_Arch=" "
report_MemTotal=" "
report_MenFree=" "
report_MemUsedPercent=" "
report_DiskTotal=" "
report_DiskFree=" "
report_DiskUserPercent=" "
report_IP=" "
report_MAC=" "
report_Gateway=" "
report_DNS=" "
report_Listen=" "
report_Selinux=" "
report_FireWall=" "
report_USERs=" "
report_USEREmptyPassword=" "
report_USERTheSameUID=" "
report_PasswordExpiry=" "
report_RootUser=" "
report_Sudoers=" "
report_SSHAuthorized=" "
report_SSHDProtocolVersion=" "
report_SSHDPermitRootLogin=" "
report_DefunctProcess=" "
report_SelfInitiatedService=" "
report_SelfInitiatedProgram=" "
report_RunningService=" "
report_Crontab=" "
report_Syslog=" "
report_SNMP=" "
report_NTP=" "
report_JDK=" "
function version(){
    echo ""
    echo ""
    echo "系统巡检脚本：Version $VERSION"
}
function getCpuStatus(){
    echo ""
    echo -e "\033[33m************************************CPU检查***********************************\033[0m"
    Physical_CPUs=$(grep "physical id" /proc/cpuinfo|sort|uniq|wc -l)
    Virt_CPUs=$(grep "processor" /proc/CPUinfo|wc-l)
    CPU_Kernel=$(grep "cores" /proc/cpuinfo|uniq|awk -F ':' '{print $2}')
    CPU_TYpe=$(grep "model name" /proc/cpuinfo|awk -F ':' '{print $2}'|sort|uniq)
    CPU_Arch=$(uname -m)
    echo "物理cpu个数:$Physical_CPUs"
    echo "逻辑cpu个数:$Virt_CPUs"
    echo "每CPU核心数:$CPU_Kernel"
    echo "    CPU型号:$CPU_Type"
    echo "    CPU架构:$CPU_Arch"
    # 报表信息
    report_CPUs=$Virt_CPUs
    report_CPUType=$CPU_Type
    report_Arch=$CPU_Arch
}
function getMemStatus(){
    echo ""
    echo -e "\033[33m*************************************************内存检查****************************\033[0m"
    if [[ $centosVersion<7 ]]
    then
        free -mo
    else
        free -h
    fi 
    # 报表信息
    MemTotal=$(grep MemTotal /proc/meminfo |awk '{print $2}')
    MemFree=$(grep MemFree /proc/meminfo | awk '{print $2}')
    let MemUsed=MemTotal-MemFree
    MemPercent="$(awk "BEGIN {if($MemTotal==0){printf 100}else{printf \"%.2f\",$MemUsed*100/$MemTotal}}")""%"
}    

function getDiskStatus(){
    echo ""
    echo -e "\033[33m****************************************磁盘检查***************************************\033[0m"
    df -hiP | sed 's/Mounted on/Mounted/'>/tmp/inode
    df -hTP | sed 's/Mounted on/Mounted/'>/tmp/disk 
    join /tmp/disk /tmp/inode | awk '{print $1,$2,"|",$3,$4,$5,$6,"|",$8,$9,$10,$11,"|",$12}'|column -t
    # 报表信息
    diskdata=$(df -TP | sed '1d' | awk '$2!="tmfs"{print}')
    disktotal=$(echo "$diskdata" |awk '{total+=$3}END{print total}')
    diskkused=$(echo "diskdata" |awk '{total+=$4}END{print total}')
    diskfree=$((disktotal-diskused))
    diskusedpercent=$(echo $disktotal $diskused |awk '{if($1==0){printf 100}else{printf "%.2f",$2*100/$1}}')
    inodedata=$(df -iTP|sed '1d'|awk '$2!="tmps"{print}')
    inodetotal=$(echo "$inodedata" |awk '{total+=$3}END{print total}')
    inodeused=$(echo "$inodedata" |awk '{total+=$4}END{print total}')
    inodefree=$((inodetotal-inodeused))
    inodeusedercent=$(echo $inodetotal $inodeused | awk '{if($1==0){printf 100}else{printf "%.2f",$2*100/$1}}')
    report_DiskTotal=$((disktotal/1024/1024))"GB" #硬盘总容量(GB)
    report_DiskFree=$((diskfree/1024/1024))"GB" #硬盘剩余(GB)
    report_DiskUsedPercent="$diskusedpercent""%" #硬盘使用率%
    report_InodeTotal=$((inodetotal/1000))"K" #Inode总量
    report_InodeFree=$((inodefree/1000))"K" #Inode剩余
    report_InodeUsedPercent="$inodeusedpercent""%" #Inode使用率%
}

function getSystemStatus(){
    echo ""
    echo -e "\033[33m############################ 系统检查 ############################\033[0m"
    if [ -e /etc/sysconfig/i18n ]
    then
        default_LANG="$(grep "LANG=" /etc/sysconfig/i18n | grep -v "^#" | awk -F '"' '{print $2}')"
    else
        default_LANG=$LANG
    fi
    export LANG="en_US.UTF-8"
    Release=$(cat /etc/redhat-release 2>/dev/null)
    Kernel=$(uname -r)
    OS=$(uname -o)
    Hostname=$(uname -n)
    SELinux=$(/usr/sbin/sestatus | grep "SELinux status: " | awk '{print $3}')
    LastReboot=$(who -b | awk '{print $3,$4}')
    uptime=$(uptime | sed 's/.*up \([^,]*\), .*/\1/')
    echo " 系统：$OS"
    echo " 发行版本：$Release"
    echo " 内核：$Kernel"
    echo " 主机名：$Hostname"
    echo " SELinux：$SELinux"
    echo " 语言/编码：$default_LANG"
    echo " 当前时间：$(date +'%F %T')"
    echo " 最后启动：$LastReboot"
    echo " 运行时间：$uptime"
    #报表信息
    report_DateTime=$(date +"%F %T") #日期
    report_Hostname="$Hostname" #主机名
    report_OSRelease="$Release" #发行版本
    report_Kernel="$Kernel" #内核
    report_Language="$default_LANG" #语言/编码
    report_LastReboot="$LastReboot" #最近启动时间
    report_Uptime="$uptime" #运行时间（天）
    report_Selinux="$SELinux"
    export LANG="$default_LANG"
}

function getServiceStatus(){
    echo ""
    echo -e "\033[33m############################ 服务检查 ############################\033[0m"
    echo ""
    if [[ $centosVersion > 7 ]]
    then
        conf=$(systemctl list-unit-files --type=service --state=enabled --no-pager | grep "enabled")
        process=$(systemctl list-units --type=service --state=running --no-pager | grep ".service")
        #报表信息
        report_SelfInitiatedService="$(echo "$conf" | wc -l)" #自启动服务数量
        report_RuningService="$(echo "$process" | wc -l)" #运行中服务数量
    else
        conf=$(/sbin/chkconfig | grep -E ":on|:启用")
        process=$(/sbin/service --status-all 2>/dev/null | grep -E "is running|正在运行")
        #报表信息
        report_SelfInitiatedService="$(echo "$conf" | wc -l)" #自启动服务数量
        report_RuningService="$(echo "$process" | wc -l)" #运行中服务数量
    fi
    echo "systemctl:服务配置"
    echo "--------"
    echo "$conf" | column -t
    echo ""
    echo "正在运行的服务"
    echo "--------------"
    echo "$process"
}

function getAutoStartStatus(){
    echo ""
    echo -e "\033[33m############################ 自启动检查 ##########################\033[0m"
    conf=$(grep -v "^#" /etc/rc.d/rc.local| sed '/^$/d')
    echo "$conf"
    #报表信息
    report_SelfInitiatedProgram="$(echo $conf | wc -l)" #自启动程序数量
}

function getNetworkStatus(){
    echo ""
    echo -e "\033[33m############################ 网络检查 ################################\033[0m"
    if [[ $centosVersion < 7 ]]
    then
        /sbin/ifconfig -a | grep -v packets | grep -v collisions | grep -v inet6
    else
    #ip a
        for i in $(ip link | grep BROADCAST | awk -F: '{print $2}')
            do ip add show $i | grep -E "BROADCAST|global"| awk '{print $2}' | tr '\n' ''
                echo ""
            done
    fi
    GATEWAY=$(ip route | grep default | awk '{print $3}')
    DNS=$(grep nameserver /etc/resolv.conf| grep -v "#" | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')
    echo ""
    echo " 网关：$GATEWAY "
    echo " DNS：$DNS"
    #报表信息
    IP=$(ip -f inet addr | grep -v 127.0.0.1 | grep inet | awk '{print $NF,$2}' | tr '\n' ',' | sed 's/,$//')
    MAC=$(ip link | grep -v "LOOPBACK\|loopback" | awk '{print $2}' | sed 'N;s/\n//' | tr '\n' ',' | sed 's/,$//')
    report_IP="$IP" #IP地址
    report_MAC=$MAC #MAC地址
    report_Gateway="$GATEWAY" #默认网关
    report_DNS="$DNS" #DNS
}

function getListenStatus(){
    echo ""
    echo -e "\033[33m############################ 监听检查 ##############################################\033[0m"
    TCPListen=$(ss -ntul | column -t)
    echo "$TCPListen"
    #报表信息
    report_Listen="$(echo "$TCPListen"| sed '1d' | awk '/tcp/ {print $5}' | awk -F: '{print $NF}' | sort | uniq | wc -l)"
}


function check(){
    version
    getSystemStatus
    getCpuStatus
    getMemStatus
    getDiskStatus
    getServiceStatus
    getAutoStartStatus
    getNetworkStatus
    getListenStatus 
}


#执行检查并保存检查结果
check > $RESULTFILE

echo "检查结果：$RESULTFILE"