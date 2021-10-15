#!/usr/bin/env bash

for proc in $(find /proc -maxdepth 1 -regex '/proc/[0-9]+')
do
    echo $proc
    printf "%2d %5d %s\n" \
        "$(cat $proc/oom_score)" \
        "$(basename $proc)" \
        "$(cat $proc/cmdline |tr '\0' ' '|head -c 100)"
done 2>/dev/null| sort -rn | head -n 10