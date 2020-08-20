#### 一、harbor安装
```shell
# 安装docker-compose
curl -L https://github.com/docker/compose/releases/download/1.24.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
# 下载harbor
wget -c https://storage.googleapis.com/harbor-releases/release-1.8.0/harbor-offline-installer-v1.8.0-rc2.tgz
tar zxvf harbor-offline-installer-v1.8.0-rc2.tgz -C /usr/local
# 修改配置文件
vim harbor.yml
hostname: harbor.plyx.site
# 启动harbor
./install.sh
# 配置docker
vim /etc/docker/daemon.json
{   "data-root": "/data/docker",
    "registry-mirrors": ["http://9b2cd203.m.daocloud.io"],
    "insecure-registries": ["192.168.174.200:8100","harbor.plyx.site:8100"],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "5"
    }
}
# 推动镜像
docker tag demo harbor.plyx.site:8100/spring_boot/demo
docker login harbor.plyx.site:8100
docker push harbor.plyx.site:8100/spring_boot/demo
```
#### 二、docker-registry安装
```shell
# 创建searcts
mkdir auth
docker run \
  --entrypoint htpasswd \
  registry:2 -Bbn mikel Password > auth/htpasswd
# 创建自签证书
mkdir certs
openssl req \
  -newkey rsa:4096 -nodes -sha256 -keyout certs/plyx.site.key \
  -x509 -days 365 -out certs/plyx.site.crt
# docker 私有仓库启动
docker run -d \
  -p 5000:5000 \
  --restart=always \
  --name registry \
  -v "$(pwd)"/auth:/auth \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  -v "$(pwd)"/certs:/certs \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/plyx.site.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/plyx.site.key \
  registry:2
# 在需要推送镜像的主机中
拷贝证书到dockcer配置文件中 /etc/docker/certs.d/plyx.site/plyx.site.crt
systemctl restart docker

### 通过config.yml 配置
## http访问
# 创建config.yml 文件
version: 0.1
log:
  fields:
    service: registry
storage:
  delete:
    enabled: true
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
    maxthreads: 100
  maintenance:
    uploadpurging:
      enabled: true
      age: 168h
      interval: 24h
      dryrun: false
    readonly:
      enabled: false
auth:
  htpasswd:
    realm: basic-realm
    path: /auth/htpasswd
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
    storagedriver:
        enabled: true
        interval: 10s
        threshold: 3
# 启动docker
docker run -d \
  --privileged \
  --restart=always \
  -p 5000:5000 \
  --name registry \
  -v $basepath/config.yml:/etc/docker/registry/config.yml \
  -v `pwd`/htpasswd:/auth/htpasswd \
  -v /home/registry/:/var/lib/registry/ \
  registry:2

## https 访问
###  自行签发证书配置
# 签发证书
1、创建ca密钥
openssl genrsa -out "ca.key" 4096
2、签发ca根证书
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=CN/ST=Beijing/L=Beijing/O=IT/OU=Docker/CN=domain.com" \
 -key ca.key \
 -out ca.crt
3、生成服务端私钥
openssl genrsa -out domain.com.key 4096
4、生成证书签名请求
openssl req -sha512 -new \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=IT/OU=Docker/CN=domain.com" \
    -key domain.com.key \
    -out domain.com.csr
4、创建x509 v3扩展文件
cat > v3.ext  <<EOF
[root_ca]
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=127.0.0.1
DNS.2=domain.com
DNS.3=localhost
EOF
5、签发证书
openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in domain.com.csr \
    -out domain.com.crt
6、Docker守护程序将.crt文件解释为CA证书，并将.cert文件解释为客户端证书
openssl x509 -inform PEM -in domain.com.crt -out domain.com.cert
9、存储证书
mkdir /ssl
cp docker.kptest.cn.crt docker.kptest.cn.key ca.crt
# 配置docker
## 拷贝证书
mkdir -p /etc/docker/certs.d/domain.com
cp ssl/ca.crt /etc/docker/certs.d/domain.com/ca.crt
cp ssl/domain.com.cert /etc/docker/certs.d/domain.com/domain.com.cert
cp ssl/domain.com.key /etc/docker/certs.d/domain.com/domain.com.key
systemctl restart docker
tee > ssl.sh <<- 'EOF'
#!/bin/bash
[[ -d "/usr/local/registry/.ssl" ]] || mkdir -pv /usr/local/registry/.ssl
basepath="/usr/local/registry/.ssl"
cd $basepath
echo -e "\033[40;4m 1、创建ca密钥 \033[0m"
openssl genrsa -out ca.key 4096
echo -e "\033[40;4m 2、签发ca根证书 \033[0m"
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=CN/ST=Beijing/L=Beijing/O=IT/OU=Docker/CN=$1" \
 -key ca.key \
 -out ca.crt
echo -e "\033[40;4m 3、生成服务端私钥 \033[0m"
openssl genrsa -out $1.key 4096
echo -e "\033[40;4m 4、生成证书签名请求 \033[0m"
openssl req -sha512 -new \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=IT/OU=Docker/CN=$1" \
    -key $1.key \
    -out $1.csr
echo -e "\033[40;4m 5、创建x509 v3扩展文件 \033[0m"
tee > v3.ext <<- 'EOF'
[root_ca]
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=ip
DNS.2=domain
DNS.3=localhost

sed -i "s/ip/$2/" v3.ext
sed -i "s/domain/$1/" v3.ext
sed -i "s/localhost/$3/" v3.ext
echo -e "\033[40;4m 6、签发证书 \033[0m"
openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in $1.csr \
    -out $1.crt
echo -e "\033[40;4m 7、Docker守护程序将.crt文件解释为CA证书，并将.cert文件解释为客户端证书 \033[0m"
openssl x509 -inform PEM -in $1.crt -out $1.cert
echo -e "\033[40;4m 7、配置docker \033[0m"
## 拷贝证书
mkdir -p /etc/docker/certs.d/$1:5000
cp ca.crt /etc/docker/certs.d/$1:5000/ca.crt
cp $1.cert /etc/docker/certs.d/$1:5000/$1.cert
cp $1.key /etc/docker/certs.d/$1:5000/$1.key
systemctl restart docker
EOF
### 安装registry
#创建config.yml配置文件
tee > config.yml <<- 'EOF'
version: 0.1
log:
  accesslog:
    disabled: true
  level: debug
  formatter: text
  fields:
    service: registry
    environment: staging
storage:
  delete:
    enabled: true
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
auth:
  htpasswd:
    realm: basic-realm
    path: /auth/htpasswd
http:
  addr: :5000
  host: https://domain
  headers:
    X-Content-Type-Options: [nosniff]
  http2:
    disabled: false
  tls:
    certificate: /etc/docker/registry/.ssl/domain.crt
    key: /etc/docker/registry/.ssl/domain.key
health:
  storagedriver:
    enabled: true
    interval: 10s
threshold: 3
EOF
tee > config.sh <<- 'EOF'
#!/bin/bash
sed -i "s/domain/$1/" config.yml
EOF
# 创建http passwd
mkdir -pv /usr/local/registry/auth
cd /usr/local/registry/auth
tee > htpaswd.sh <<- 'EOF'
pwd=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 24`
echo -e "# registry account info\nregistry: $1\nusername: admin\npassword: $pwd" > passwd
docker run --rm \
    --entrypoint htpasswd \
    registry:2.5 \
    -Bbn admin $pwd > htpasswd
EOF
# 启动容器
cd /usr/local/registry/auth
tee > docker_registry.sh <<- 'EOF'
basepath="/usr/local/registry"
docker container stop registry
docker container rm registry
docker run -d \
  --privileged \
  --restart=always \
  -p 5000:5000\
  --name registry \
  -v $basepath/auth/config.yml:/etc/docker/registry/config.yml \
  -v $basepath/.ssl/:/etc/docker/registry/.ssl/ \
  -v $basepath/auth/htpasswd:/auth/htpasswd \
  -v $basepath/.registry/:/var/lib/registry/ \
  registry:2
EOF
chmod +x docker_registry.sh
sh -x docker_registry.sh
# 登陆docker
docker login domain:5000
docker tag maven:
```
### nexus 仓库使用
```shell
## 启动镜像
docker create volume nexus-data
docker run -d --name nexus3 --restart=always \
    -p 8081:8081 \
    --mount src=nexus-data,target=/nexus-data \
    sonatype/nexus3
## nginx代理
upstream register
{
    server 127.0.0.1:8081; #端口为上面添加的私有镜像仓库是设置的 HTTP 选项的端口号
    check interval=3000 rise=2 fall=10 timeout=1000 type=http;
    check_http_send "HEAD / HTTP/1.0\r\n\r\n";
    check_http_expect_alive http_4xx;
}
server {
    server_name nexus.kptest.cn;#如果没有 DNS 服务器做解析，请删除此选项使用本机 IP 地址访问
    listen       443 ssl;
    ssl_certificate key/example.crt;
    ssl_certificate_key key/example.key;
    ssl_session_timeout  5m;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers  HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers   on;
    large_client_header_buffers 4 32k;
    client_max_body_size 300m;
    client_body_buffer_size 512k;
    proxy_connect_timeout 600;
    proxy_read_timeout   600;
    proxy_send_timeout   600;
    proxy_buffer_size    128k;
    proxy_buffers       4 64k;
    proxy_busy_buffers_size 128k;
    proxy_temp_file_write_size 512k;
    location / {
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_redirect off;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_pass http://register;
        proxy_read_timeout 900s;
    }
    error_page   500 502 503 504  /50x.html;
}
# 配置ssl加密
openssl s_client -showcerts -connect nexous.kptest.cn:443 </dev/null 2>/dev/null|openssl x509 -outform PEM >ca.crt
cat ca.crt | sudo tee -a /etc/ssl/certs/ca-certificates.crt
systemctl restart docker
````