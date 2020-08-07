#!/usr/bin/python3
# -*- coding: utf8 -*-

import asyncio
import sys
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

async def loki_log(cmd):
    # Create the subprocess; redirect the standard output
    # into a pipe.
    proc = await asyncio.create_subprocess_shell(
        cmd, stdout=asyncio.subprocess.PIPE)

    # Read one line of output.
    data = await proc.stdout.readline()
    line = data.decode('ascii').rstrip()

    # Wait for the subprocess exit.
    # await proc.wait()
    return line

if __name__ == "__main__":
    loki_log('./media/mikel_pan/_dde_data1/data/github/Cnblog/docs/loki_api.sh')




