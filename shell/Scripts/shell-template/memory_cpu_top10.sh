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
    local MEMTEMFILE=`mktemp memory.XXX`
    top -b -n 1 > $MEMTEMFILE
    
    awk 'BEGIN {print "PID\tRES\tCOMMAND"}' 
    tail -n +8 $MEMTEMFILE | awk '
    {
        a[$1"-"$6"-"$NF]++
    }
    END{
        for (i in a) {
            split(i,b,"-")
            print b[1]"\t",b[2]"\t",b[3]
        }
    }' |sort -k 1 -n -r|head -n 10
    rm -rf $MEMTEMFILE
}

cpu() {
    local CPUTEMFILE=`mktemp cpu.XXX`
    top -b -n 1 > $CPUTEMFILE
    awk 'BEGIN {print "PID\t%CPU\tCOMMAND"}' 
    tail -n +8 $CPUTEMFILE | awk '
    {   
        a[$1"-"$9"-"$NF]++
    }
    END{
        for (i in a) {
            split(i,b,"-")
            print b[1]"\t",b[2]"\t",b[3]
        }
    }' |sort -k 2 -n -r|head -n 10
    rm -rf $CPUTEMFILE
}

main() {
    echo -e "${YELLOW}==========================memory===================================${RESET}"
    memory
    echo -e "${YELLOW}==========================cpu======================================${RESET}" 
    cpu
}

main "$@"