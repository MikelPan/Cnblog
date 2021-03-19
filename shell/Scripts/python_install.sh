#!/bin/bash
#1、安装get
yum install -y wget
#2、下载tar包
wget -c https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tgz -P /usr/local/src
#3、解压文件
#tar zxvf /root/software/Python-3.7.3.tgz -C /usr/local/src
mkdir /usr/local/python
#4、添加环境变量
echo "export PATH=$PATH:/usr/local/python/bin" >> /etc/profile
source /etc/profile
#5、编译安装
yum install -y zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc-c++ make libffi-devel
cd /usr/local/src/Python-3.7.3 && ./configure --prefix=/usr/local/python
make -j 3 && make install
#6、更换系统python版本
mv /usr/bin/python /usr/bin/python2.7.5
ln -s /usr/local/python/bin/python3.7 /usr/bin/python
#7、配置yum
sed -i 's@#!/usr/bin/python@#!/usr/bin/python2.7@g' /usr/bin/yum
sed -i 's@#!/usr/bin/python@#!/usr/bin/python2.7@g' /usr/libexec/urlgrabber-ext-down
#8、安装虚拟环境
pip3 install virtualenv
#9、创建虚拟环境
mkdir -p /home/PyProject/venv
virtualenv -p /usr/local/python/bin/python3 python3-base
#10、安装ipython
pip3 install ipython