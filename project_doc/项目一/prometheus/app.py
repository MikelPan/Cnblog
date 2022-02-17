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
import logging
import time
from logging.handlers import RotatingFileHandler
from flask_script import Manager,Server
from email.mime.text import MIMEText
from email.header import Header
import smtplib
from datetime import datetime, timedelta
import pytz

imp.reload(sys) 

app = Flask(__name__)

class Notificaty_APi(object):

    def __init__(self,env):
        self.env = env
        filepath = os.path.split(os.path.realpath(__file__))[0]
        yamlpath = os.path.join(filepath, 'config.yaml')
        f = open(yamlpath,'r',encoding='utf-8')
        rows = f.read()
        self.parms = yaml.load(rows,Loader=yaml.FullLoader)
        self.parms = yaml.safe_load(rows)
        self.url = self.parms[self.env]['weixin']['url']

    def send_weixin(self,msg):

        data = {
            #markdown类型
            "msgtype": "markdown",
            "markdown": {
                "content": "{}".format(msg)
            }
        }

        headers = {
            'Content-Type': 'application/json',
            'Charset': 'utf-8'
        }

        response = requests.post(self.url, headers=headers, data=json.dumps(data))

    def send_smtp(self,msg):

        # 第三方 SMTP 服务
        mail_host=self.parms[self.env]['smtp']['host'] #设置服务器
        mail_user=self.parms[self.env]['smtp']['user']  #用户名
        mail_pass=self.parms[self.env]['smtp']['passwd']   #口令 
        
        sender = self.parms[self.env]['smtp']['send_email']
        receivers = [self.parms[self.env]['smtp']
                     ['receivers_email']]  # 接收邮件，可设置为你的QQ邮箱或者其他邮箱
        message = MIMEText(msg, 'plain', 'utf-8')
        message['From'] = "{}".format(sender)
        message['To'] = ",".join(receivers)
         
        subject = 'Prometheus 邮件告警通知'
        message['Subject'] = Header(subject, 'utf-8')
         
        try:
            smtpObj = smtplib.SMTP_SSL(mail_host)
            #smtpObj.connect(mail_host, 25)    # 25 为 SMTP 端口号
            smtpObj.set_debuglevel(1)
            smtpObj.ehlo(mail_host)
            smtpObj.login(mail_user,mail_pass)
            smtpObj.sendmail(sender, receivers, message.as_string())
            smtpObj.quit()
            print("邮件发送成功")
        except smtplib.SMTPException:
            print("Error: 无法发送邮件")

    def timestamp_to_date(self,_time):
        t = float(_time/1000)
        d = time.localtime(t)
        _t = time.strftime("%Y-%m-%d %H:%M:%S",d)
        return _t

    def utc_to_cst(self,utc_time_str, utc_format='%Y-%m-%dT%H:%M:%S.%fZ'):
        local_tz = pytz.timezone('Asia/Shanghai')
        local_format = "%Y-%m-%d %H:%M:%S"
        utc_time_str_h = utc_time_str.split('.')[0]
        utc_time_str = utc_time_str.split('.')[1]
        if len(utc_time_str) > 7:
            utc_time_str[:-4]
            utc_time_str = utc_time_str_h + '.' + utc_time_str[:-4] + 'Z'
        utc_dt = datetime.strptime(utc_time_str, utc_format)
        local_dt = utc_dt.replace(tzinfo=pytz.utc).astimezone(local_tz)
        time_str = local_dt.strftime(local_format)
        return datetime.fromtimestamp(int(time.mktime(time.strptime(time_str, local_format))))

    def get_content(self,data):

        for item in data:
            warning_time = str(self.utc_to_cst(item['startsAt']))
            warning_level = '告警级别：' + item['labels']['severity'] + '\n'
            warning_name = '告警标题：' + item['labels']['alertname'] + '\n'
            if item['labels']['alertname'] == 'Status_Not_200':
                warning_host = '告警接口：' + item['labels']['path'] + '\n'
            elif ('instance' in item['labels'].keys()):
                warning_host = '告警主机：' + item['labels']['instance'] + '\n'
            elif ('node' in item['labels'].keys()):
                warning_host = '告警主机：' + item['labels']['node'] + '\n'
            else:
                warning_host = '告警主机：' + '' + '\n'
            warning_start = '告警时间：' + warning_time + '\n'
            if ('description' in item['annotations'].keys()):
                warning_message = '告警详情：' +item['annotations']['description'] + '\n'
            else:
                warning_message = '告警详情：' +item['annotations']['message'] + '\n'
            msg = warning_name  + warning_host + warning_level + warning_start + warning_message
            if item['status'] == 'firing' and item['labels']['severity'] == 'critical':
                self.send_weixin(msg)
                self.send_smtp(msg)
            elif item['status'] == 'firing' and item['labels']['severity'] == 'warning':
                self.send_smtp(msg)
            else:
                self.send_smtp('触发异常,请关注,监控地址如下:\nhttps://prometheus.01member.com')


notify = Notificaty_APi('prod')

def make_dir(make_dir_path):
    path = make_dir_path.strip()
    if not os.path.exists(path):
        os.makedirs(path)

log_dir_name = "Logs"
log_file_name = 'logs-' + time.strftime('%Y-%m-%d', time.localtime(time.time())) + '.log'
log_file_folder = os.path.abspath(
    os.path.join(os.path.dirname(__file__), os.pardir)) + os.sep + log_dir_name
make_dir(log_file_folder)
log_file_str = log_file_folder + os.sep + log_file_name

# 默认日志等级的设置
#logging.basicConfig(level=logging.WARNING)
# 创建日志记录器，指明日志保存路径,每个日志的大小，保存日志的上限
file_log_handler = RotatingFileHandler(log_file_str, maxBytes=1024 * 1024, backupCount=10)
# 设置日志的格式                   发生时间    日志等级     日志信息文件名      函数名          行数        日志信息
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(filename)s - %(funcName)s - %(lineno)s - %(message)s')
# 将日志记录器指定日志的格式
file_log_handler.setFormatter(formatter)
# 日志等级的设置
file_log_handler.setLevel(logging.DEBUG)
# 为全局的日志工具对象添加日志记录器
logging.getLogger().addHandler(file_log_handler)

@app.route('/')
def index():
    return 'Ok！'

@app.route('/prometheus',methods=['POST'])
def send_prod():
    if request.method == 'POST':
        post_data = json.loads(request.get_data())
        app.logger.info(post_data)
        app.logger.info(notify.get_content(post_data['alerts']))
        return 'Hello'


if __name__ == '__main__':
  app.debug = True
  manager = Manager(app)
  server = Server(host="0.0.0.0", port=5000)
  manager.add_command("runserver", server)
  manager.run()