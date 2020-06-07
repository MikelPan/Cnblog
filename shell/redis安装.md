#### 一、redis安装
```shell
# redis 二进制安装
yum install -y epel-release vim atop htop net-tools git wget gcc-c++
yum clean all
yum maakecache
wget -P /usr/local/src http://download.redis.io/releases/redis-5.0.3.tar.gz
cd /usr/local/src && tar zxvf redis-5.0.3.tar.gz
cd redis-5.0.3 && maake
mkdir-p/usr/local/redis/etc
cd src && make install PREFIX=/usr/local/redis
cd../ &&mvredis.conf /usr/local/redis/etc
sed -i 's@daemonize no@daemonize yes@g' /usr/local/redis/etc/redis.conf
echo 'export PATH=/usr/local/redis/bin:$PATH'>> /etc/profile
source/etc/profile
```
#### 二、redis配置开机启动
```shell
# 配置开机启动
vim/etc/systemd/system/redis-server.service
-------------------------------------start----------------------------------------
[Unit]
Description=The redis-server Process Manager
After=syslog.target network.target

[Service]
Type=simple
PIDFile=/var/run/redis_6379.pid
ExecStart=/usr/local/redis/bin/redis-server /usr/local/redis/etc/redis.conf
ExecReload=/bin/kill -USR2 $MAINPID
ExecStop=/bin/kill -SIGINT $MAINPID
[Install]
WantedBy=multi-user.target
 ---------------------------------------end-------------------------------------------
systemctl enable redis-server
systemctl start redis-server
```