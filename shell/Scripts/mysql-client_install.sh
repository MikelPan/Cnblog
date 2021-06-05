#!/usr/bin/env bash

rpm_url="https://mirrors.tuna.tsinghua.edu.cn/mysql/yum/mysql57-community-el7/"
yum -y remove mari*
for pkg in mysql-community-client-5.7.33-1.el7.x86_64.rpm mysql-community-libs-5.7.33-1.el7.x86_64.rpm mysql-community-common-5.7.33-1.el7.x86_64.rpm
do
    wget $rpm_url$pkg -P /usr/local/src
done
for pkg in mysql-community-client-5.7.33-1.el7.x86_64.rpm mysql-community-libs-5.7.33-1.el7.x86_64.rpm mysql-community-common-5.7.33-1.el7.x86_64.rpm
do
    rpm -ivh /usr/local/src/$pkg
done