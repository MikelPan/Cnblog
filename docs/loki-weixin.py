#!/usr/bin/python3
# -*- coding: utf8 -*-

import requests
import json
import yaml
import urllib
import subprocess
import time
import shlex

#command=curl -vvv -G -s  "http://lcoalhost:port/loki/api/v1/query_range" --data-urlencode 'query={job="domain-test1"}|="ERROR"|="error"' | jq


# data = {
#     "query": "{job=domian-test2}"
# }
# data = urllib.parse.urlencode(data)
# data = urllib.parse.quote(data)
# print(urllib.parse.unquote(data))
# headers = {
#     'Content-Type': 'text/plain'
# }

def cmd(command):
    cmd = shlex.split(command)
    p = subprocess.Popen(cmd,shell=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE,encoding="utf-8")
    while p.poll() is None:
        line = p.stdout.readline()
        line = line.strip()
        if line:
            print('Subprogram output: [{}]'.format(line))
    if p.returncode == 0:
        print('Subprogram success')
    else:
        print('Subprogram failed')

if __name__ == "__main__":
    print(cmd('sh /media/mikel_pan/_dde_data1/data/github/Cnblog/docs/loki_api.sh'))




