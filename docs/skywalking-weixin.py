#!/usr/bin/python3
# -*- coding: utf8 -*-
from flask import Flask
from flask import request
import requests
import json
import sys
import imp
import yaml
import os
from flask_script import Manager 



imp.reload(sys) 

app = Flask(__name__)

class Notificaty_APi(object):

    def __init__(self,env):
        self.env = env
        filepath = os.path.split(os.path.realpath(__file__))[0]
        yamlpath = os.path.join(filepath, 'config.yml')
        f = open(yamlpath,'r',encoding='utf-8')
        rows = f.read()
        self.parms = yaml.load(rows,Loader=yaml.FullLoader)
        self.parms = yaml.safe_load(rows)
        self.url = self.parms[self.env]['skywalking']['weixin_url']

    def send_weixin(self,msg):

        data = {
            #markdown类型
            "msgtype": "markdown",
            "markdown": {
                "content": "{}".format(self.msg)
            }
        }

        headers = {
            'Content-Type': 'application/json',
            'Charset': 'utf-8'
        }

        response = requests.post(self.url, headers=headers, data=json.dumps(data))

    def timestamp_to_date(self,_time):
        t = float(_time/1000)
        d = time.localtime(t)
        _t = time.strftime("%Y-%m-%d %H:%M:%S",d)
        return _t

    def get_weixin_content(self,data):

        for item in data:
            time = self.timestamp_to_date(item['startTime'])
            warning_name = '告警标题：' + item['name'] + '\n'
            warning_start = '告警时间：' + time + '\n'
            warning_message = '告警详情：' + item['alarmMessage'] + '\n'
            msg = warning_name  + warning_start + warning_message
            print(msg)
            # self.send_weixin(msg,self.url)

notify = Notificaty_APi('uat')

@app.route('/prod-skywalking',methods=['POST'])
def send_prod():
    if request.method == 'POST':
        post_data = json.loads(request.get_data())
        print(post_data)
        notify.get_weixin_content(post_data)
        return 'Hello'

@app.route('/uat-skywalking',methods=['POST'])
def send_uat():
    if request.method == 'POST':
        post_data = json.loads(request.get_data())
        print(post_data)
        notify.get_weixin_content(post_data)
        return 'Hello'

if __name__ == '__main__':
  manager = Manager(app)
  manager.run()


