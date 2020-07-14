from fastapi import APIRouter

import json
import jenkins
import time
from config import Config

router = APIRouter()

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


@router.get("/jobs/{Job_Name}/build")
async def build_jobs(Job_Name: str):
    
    return [{"username": "Foo"}, {"username": "Bar"}]

@router.get("/jobs/{Job_Name}/update")
async def update_jobs():
    return {"username": "fakecurrentuser"}


@router.get("/jobs/{Job_Name}/list")
async def list_jobs(username: str):
    JenkinsApi = JenkinsApi('dev')
    jobs = JenkinsApi._get_jobs()
    return [{"jobs": job}]

@router.get("/jobs/list")
async def list_jobs():
    jenkinsapi = JenkinsApi('dev')
    jobs = jenkinsapi._get_jobs()
    for i in jobs:
        job = i
    return {"jobs": job}