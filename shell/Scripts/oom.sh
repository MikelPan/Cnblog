#!/usr/bin/env bash

for proc in $(find /proc -maxdepth 1 -regex '/proc/[0-9]+')
do
    echo $proc
    printf "%2d %5d %s\n" \
        "$(cat $proc/oom_sorce)" \
        "$(basename $proc)" \
        "$(cat $proc/cmdline |head -c 50)"
done 2>/dev/null | sort -rn | head -n 10