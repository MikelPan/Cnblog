#!/usr/bin/env python3
#coding:utf-8

import requests
import json
import time
import datetime


def loki():
    app = ".*uat-container.*"
    #app = "user-control-service-master-container-provider"
    label="app_kubernetes_io_instance"
    url="http://localhost:3100/loki/api/v1/query_range"
    st=(datetime.datetime.now()).strftime("%Y-%m-%d")
    times=''
    time=(datetime.datetime.now()-datetime.timedelta(minutes=5)).strftime("%H:%M")
    print(url)
    level="INFO"
    pkg="com.dadi01.scrm"
    query = '{' + label + '=' + '~' +'"' + app + '"' + '}' + '|' + '~' + '"' + st + ' ' + times + '"' + '|' + '~' + '"' + level + '"' + '|' + '~' + '"' + pkg + '"'
    payload = {
        'query': query,
        'limit': 1000
    }
    head = {"Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"}
    r = requests.get(url,params=payload,headers=head)
    msg=json.loads(r.text)
    if msg['data']['result']:
        for i in msg['data']['result']:
            msg = json.dumps(i['stream'], sort_keys=True, indent=4)
            print(msg)
            #msg = json.dumps(i['values'], sort_keys=True, indent=4)
            for j in i['values'][:][:]:
                loki_url = "https://localhost/explore?orgId=1&left=%5B%22now-1h%22,%22now%22,%22Loki%22,%7B%22expr%22:%22%7Bapp_kubernetes_io_instance%3D~%5C%22" + i['stream']['app_kubernetes_io_instance'] + "%5C%22%7D%7C~%5C%22" + st + "%5C%22%7C~%5C%22ERROR%5C%22%7C~%5C%22.*com.dadi01.scrm.*%5C%22%22,%22maxLines%22:5000%7D%5D"
                data = {
                    "project": i['stream']['app_kubernetes_io_name'],
                    "instance": i['stream']['app_kubernetes_io_instance'],
                    "ns": i['stream']['namespace'],
                    "pod": i['stream']['pod'],
                    "msg": j,
                    "url": loki_url
                }
                print(data)
                weixin_url="https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=cd3ec070-386c-45c0-be6f-f3f628dsss42"

                msg = "### 错误日志详情如下 \n\n" \
                      "**项目名称:**&emsp; %s \n\n" \
                      "**实例名称:**&emsp; %s \n\n" \
                      "**命名空间:**&emsp; %s \n\n" \
                      "**pod名称:**&emsp; %s \n\n" \
                      "**错误详情:**&emsp; %s \n\n" %(data['project'],data['instance'],data['ns'],data['pod'],data['msg'])
                  
                data_json = {
                    "msgtype": "markdown",
                    "markdown": {
                        "content": "{}\n#### [错误详情]({})".format(msg,data['url'])
                    }
                }

                heads = {'Content-Type': 'application/json','Charset': 'utf-8'}
                print(data_json)
                requests.post(weixin_url,data=json.dumps(data_json),headers=heads)

if __name__ == "__main__":
    loki()






