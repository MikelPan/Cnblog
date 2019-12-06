## API网关Kong
### OpenResty安装
*Centos安装方式*
```bash
sudo yum install yum-utils
sudo yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
sudo yum install openresty
sudo yum install openresty-resty
```
*源代码编译安装*
```bash
#https://openresty.org/download/openresty-1.15.8.1.tar.gz
wget https://openresty.org/download/openresty-1.13.6.2.tar.gz
tar -xvf openresty-1.13.6.2.tar.gz
cd openresty-1.13.6.2/
./configure --with-pcre-jit --with-http_ssl_module --with-http_realip_module --with-http_stub_status_module --with-http_v2_module --prefix=/usr/local/bin/openresty
make -j2 && make install     //默认安装在--prefix指定的目录，这里是：/usr/local/bin/openresty
export PATH=/usr/local/openresty/bin:$PATH
```
### 安装kong
Kong是一个基于OpenResty的应用，是一个API网关
准备OpenResty和Luarocks
yum安装Luarocks
```bash
yum install -y epel-release
yum install -y luarocks
```
源码编译安装Luarocks:
```bash
git clone git://github.com/luarocks/luarocks.git
./configure --lua-suffix=jit --with-lua=/usr/local/openresty/luajit --with-lua-include=/usr/local/openresty/luajit/include/luajit-2.1
make install
```
下载Kong源码，编译安装
```bash
cd /usr/local/ && git clone https://github.com/Kong/kong.git
cd kong
// git checkout 切换到你要安装的版本
make install
```
