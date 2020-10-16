# -*- coding: utf8 -*-
from flask import Flask
from flask import request
import time
import hmac
import hashlib
import base64
import urllib
import requests
import json
import sys



reload(sys) 
sys.setdefaultencoding('utf-8')

app = Flask(__name__)
url = 'https://oapi.dingtalk.com/robot/send?access_token=859fe7562a332ec1d0a1b7385da590baa726a0b59c9311a68d7bf32e5bxxxxx' 

def get_timestamp_sign():
    timestamp = long(round(time.time() * 1000))
    secret = 'SEC5d4464c3b48f46352d7d0ec92a1f7b674c11910acefc3d1c4bf2b33xxxxxx'
    secret_enc = bytes(secret).encode('utf-8')
    string_to_sign = '{}\n{}'.format(timestamp, secret)
    string_to_sign_enc = bytes(string_to_sign).encode('utf-8')
    hmac_code = hmac.new(secret_enc, string_to_sign_enc, digestmod=hashlib.sha256).digest()
    sign = urllib.quote_plus(base64.b64encode(hmac_code))
    return {"timestamp": timestamp, "sign": sign}



def send_dingtalk(msg,url):
   data = {
        'msgtype': 'text',
        'text': {
            'content': '{}'.format(msg)
        },
        'at': {
            'atMobiles': []
            }
   }
   headers = {
        'Content-Type': 'application/json',
        'Charset': 'utf-8'
    }
   response = requests.post(url, headers=headers, data=json.dumps(data))

def get_dingtalk_content(data):
    parameter = get_timestamp_sign()
    dingtalk_url = url + '&timestamp=' + str(parameter['timestamp']) + '&sign=' + str(parameter['sign'])

    for item in data:
        if item['status'] == 'firing':
            warning_level = '告警级别：' + item['labels']['severity'] + '\n'
            warning_name = '告警标题：' + item['labels']['alertname'] + '\n'
            warning_start = '告警时间：' + item['startsAt'].split('.')[0].replace('T',' ') + '\n'
            warning_message = '告警详情：' +item['annotations']['message'] + '\n'
            msg = warning_name + warning_level + warning_start + warning_message
            send_dingtalk(msg,dingtalk_url)



@app.route('/',methods=['POST'])
def send():
    if request.method == 'POST':
        post_data = json.loads(request.get_data())
        print(post_data['alerts'])
        get_dingtalk_content(post_data['alerts'])
        return 'Hello'

if __name__ == '__main__':
  app.run(host='0.0.0.0',port=80)