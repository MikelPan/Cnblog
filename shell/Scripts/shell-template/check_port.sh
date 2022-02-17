#!/usr/bin/env bash
#Description: 监控一个服务端口
#Author: mikelLam
#Created Time: 2021/12/28 09:51

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
#   $1 - string
#   $2 - int
# Returns:
#   None
#########################

main() {
    local IP=${1:?missing hostIP}
    local PORT=${2:?missing port}
    [[ ! -x /usr/bin/telnet ]] && echo -e "${YELLOW} [WARNING] telnet: not found command${RESET}" && exit 1
    local TEMFILE=`mktemp port_status.XXX`
    echo -e "quit" |telnet $IP $PORT  &> $TEMFILE
    if egrep "\^]" $TEMFILE &> /dev/null;then
        echo -e "${GREEN} [INFO] $IP $PORT is opening!${RESET}"
    else
        echo -e "${RED} [ERROR] $IP $PORT is closening!${RESET}"
    fi
    rm -rf $TEMFILE
}

main "$@"
