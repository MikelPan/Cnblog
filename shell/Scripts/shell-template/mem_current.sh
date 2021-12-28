#!/usr/bin/env bash
#Description: 内存使用率统计脚本
#Author: mikelLam
#Created Time: 2021/12/28 14:42

# Constants
RESET='\033[0m'
RED='\033[38;5;1m'
GREEN='\033[38;5;2m'
YELLOW='\033[38;5;3m'
MAGENTA='\033[38;5;5m'
CYAN='\033[38;5;6m'

# Function

########################
# Print to STDERR
# Arguments:
#   Missing to print
# Returns:
#   None
#########################

main() {
    memory_used=`head -2 /proc/meminfo |awk 'NR==1{t=$2}NR==2{f=$2;print(t-f)*100/t"%"}'`
    memory_cache=`head -5 /proc/meminfo |awk 'NR==1{t=$2}NR==5{c=$2;print c*100/t"%"}'`
    memory_buffer=`head -4 /proc/meminfo |awk 'NR==1{t=$2}NR==4{b=$2;print b*100/t"%"}'`
    echo -e "${CYAN} =========================内存使用率==========================${REST}"
    echo -e "${YELLOW}memory_used:${RESET} $memory_used\t"
    echo -e "${YELLOW}buffer:${RESET} $memory_buffer\t"
    echo -e "${YELLOW}cached:${RESET} $memory_cache"
}

main "$@"