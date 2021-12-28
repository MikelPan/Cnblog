#!/usr/bin/env bash
#Description: 磁盘使用情况统计脚本
#Author: mikelLam
#Created Time: 2021/12/28 15:20

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
    device_num=`iostat -x|grep "^vd[a-z]"|wc -l`
    echo -e "${CYAN} =========================磁盘使用情况==========================${RESET}"
    awk 'BEGIN {print "device\tavgqu-sz"}'  
    iostat -x 1 3|egrep "^vd[a-z]"|tail -n +$((device_num+1))|awk '{io_long[$1]+=$9}END{for (i in io_long) print i"\t",io_long[i]}'
}

main "$@"