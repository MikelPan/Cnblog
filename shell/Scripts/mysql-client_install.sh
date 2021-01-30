#!/usr/bin/env bash

rpm_url="https://mirrors.tuna.tsinghua.edu.cn/mysql/yum/mysql57-community-el7/"
for pkg in (mysql-community-common-5.7.33-1.el7.x86_64.rpm mysql-community-libs-5.7.33-1.el7.x86_64.rpm mysql-community-client-5.7.33-1.el7.x86_64.rpm)
do
    wget $rpm_url$pkg -P /usr/local/src
    rpm -ivh /usr/local/src/$pkg
done