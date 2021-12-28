#!/usr/bin/env bash
#Description: 统计使用内存和CPU前十进程
#Author: mikelLam
#Created Time: 2021/12/28 10:49

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

memory() {
    local TEMFILE=`mktemp memory.XXX`
    top -b -n 1 > $TEMFILE

    tail -n +8 $TEMFILE | awk '{arrary[$NF]+=$6}END{for (i in arrary) print arrary[i],i}' |sort -k 1 -n -r | head -10
    rm -rf $TEMFILE
}

cpu() {
    local TEMFILE=`mktemp cpu.XXX`
    top -b -n 1 > $TEMFILE
    tail -n +8 $TEMFILE | awk '{arrary[$NF]+=$9}END{for (i in array) print arrary[i],i}'|sort -k 1 -n -r |head -10
    rm -rf $TEMFILE
}

main() {
    echo -e "${YELLOW}==========================memory===================================${RESET}"
    memory
    echo -e "${YELLOW}==========================cpu===================================${RESET}" 
    cpu
}

main "$@"