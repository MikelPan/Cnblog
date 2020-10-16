#FROM registry.szcasic.com/python/flask:2.7.17-alpine3.10
FROM registry.cn-shenzhen.aliyuncs.com/k8s-kubeadm/python2-flask:2.7.17-alpine3.10

WORKDIR /apps
COPY ./app.py /apps

CMD ["python","app.py"]
