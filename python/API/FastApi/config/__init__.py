#!/usr/bin/env python3
#coding:utf-8

import os
import yaml
from aliyunsdkcore.client import AcsClient

class Config(object):
    def __init__(self):
        filepath = os.path.split(os.path.realpath(__file__))[0]
        yamlpath = os.path.join(filepath, 'config.yml')
        f = open(yamlpath,'r',encoding='utf-8')
        rows = f.read()
        self.parms = yaml.load(rows,Loader=yaml.FullLoader)
        self.parms = yaml.safe_load(rows)
        f.close()
    
    def GetConfig(self):
        return self.parms

    def aliyun_client(self):
        conf = self.GetConfig()
        if self.env in conf.keys():
            self.access_key_id = conf[self.env]['aliyun']['access-key-id']
            self.access_key_secret = conf[self.env]['aliyun']['access-key-secret']
            self.region_id = conf[self.env]['aliyun']['region-id']
        self.client = AcsClient(
            self.access_key_id,
            self.access_key_secret,
            self.region_id
            )
        return self.c