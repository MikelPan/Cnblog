#!/usr/bin/env python3
#coding:utf-8

import json
import jenkins
import time
from config import Config

class JenkinsApi(object):
    def __init__(self,env):
        self.env = env
        conf = Config().GetConfig()
        self.secret = conf[self.env]['jenkins']['secret']
        self.jenkins_url = conf[self.env]['jenkins']['jenkins_url']
        self.user_id = conf[self.env]['jenkins']['user_id']
        self.api_token = conf[self.env]['jenkins']['api_token']
        self.server = jenkins.Jenkins(self.jenkins_url, username=self.user_id, password=self.api_token)
        self.dev_view_name = conf[self.env]['jenkins']['dev']['view_name']
        self.test_view_name = conf[self.env]['jenkins']['test']['view_name']

    def _get_jobs(self):
        jobs = self.server.get_all_jobs()
        job_name_list = []
        for i,j in enumerate(jobs):
            job_name_list.append(j['name'])
        return job_name_list

    def _build_jobs(self):
        jobs = self.server.build_job()
        return jobs