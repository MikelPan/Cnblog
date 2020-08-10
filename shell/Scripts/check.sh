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
centosVersion=$(awk '{print $(NF-1)}' /etc/redht-release)
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
    if [[ $centosVersion<7 ]];then
        free -mo
    else
        free -h
    fi 
    # 报表信息
    MemTotal=$(grep MemTotal /proc/meminfo |awk '{print $2}')
    MemFree=$(grep MemFree /proc/meminfo | awk '{print $2}')
    let MemUsed=MemTotal-MemFree
    MemPercent="$(awk "begin {if($MemTotal==0){printf 100}else{printf \"%.2f\",$MemUsed*100/$MemTotal}}")""%"
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
    inodeusedercent=$
}