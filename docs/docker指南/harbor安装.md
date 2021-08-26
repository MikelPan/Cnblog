### 安装harbor
#### 下载
```bash
wget https://github.com/goharbor/harbor/releases/download/v2.0.2/harbor-offline-installer-v2.0.2.tgz -P /usr/local/src
tar harbor-offline-installer-v2.0.2.tgz -C /usr/local
```
#### 安装docker-compose
```bash
curl -L https://github.com/docker/compose/releases/download/1.26.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/docker-compose
```
#### 安装harbor
```bash
cp harbor.yml.tmpl harbor.yml
# 修改配置
vim harbor.yml
hostname: domain.com 
# http related config
http:
  # port for http, default is 80. If https enabled, this port will redirect to https port
  port: 5000
harbor_admin_password: pwd
```

### harbor 配置自签证书
#### 生成CA证书私钥
```bash
openssl genrsa -out ca.key 4096
```
#### 生成CA证书
```bash
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=CN/ST=Beijing/L=Beijing/O=IT/OU=Docker/CN=domain.com" \
 -key ca.key \
 -out ca.crt
```
#### 生成私钥
```bash
openssl genrsa -out domain.com.key 4096
```
#### 生成证书签名请求
```bash
openssl req -sha512 -new \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=IT/OU=Docker/CN=domain.com" \
    -key domain.com.key \
    -out domain.com.csr
```
#### 生成一个x509 v3扩展文件
```bash
cat > v3.ext <<- 'EOF'
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
```
#### 使用该v3.ext文件为Harbor主机生成证书
```bash
openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in domain.com.csr \
    -out domain.com.crt
```
#### 将服务器证书和密钥复制到Harbor主机上的certficates文件夹中
```bash
mkdir -p /data/cert/
cp domain.com.crt /data/cert/
cp domain.com.key /data/cert/
```
#### Docker守护程序将.crt文件解释为CA证书，并将.cert文件解释为客户端证书
```bash
openssl x509 -inform PEM -in domain.com.crt -out domain.com.cert
```
#### 将服务器证书，密钥和CA文件复制到Harbor主机上的Docker certificate文件夹中
```bash
mkdir -p /etc/docker/certs.d/domain.com/
cp domain.com.cert /etc/docker/certs.d/domain.com/
cp domain.com.key /etc/docker/certs.d/domain.com/
cp ca.crt /etc/docker/certs.d/domain.com/
```
#### 证书加入到系统证书中
```bash
cat ca.crt >> /etc/pki/tls/certs/ca-bundle.crt
```
#### 修改harbor.yml文件

```yaml
https:
  port: 443
  certificate: /data/cert/domain.com.crt
  private_key: /data/cert/domain.com.key
```

#### 运行prepare脚本以启用HTTPS
```bash
./prepare
```
#### 运行install.sh脚本来启动harbor
```bash
./install.sh
```
#### 如果Harbor正在运行，请停止并删除现有实例
```bash
# 停止
docker-compose down -v
# 重启
docker-compose up -d
```
#### 从Docker客户端登录Harbor
```bash
docker login domain.com:xxxx
```
### harbor使用
#### 推送镜像
```bash
docker tag registry-vpc.cn-beijing.aliyuncs.com/acs/pause:3.2 domain.com:5000/member/pause:3.2
docker login
docker push domain.com:5000/member/pause:3.2
```
#### k8s使用harbor
```bash
# 创建harbor secret
cat ~/.docker/config.json
apiVersion: v1
kind: Secret
metadata:
  name: harbor-registry-secret
  namespace: kube-system
data:
  .dockerconfigjson: cat ~/.docker/config.json |base64 -w 0
type: kubernetes.io/dockerconfigjson
# 创建sa
apiVersion: v1
kind: ServiceAccount
metadata:
  name: test
  namespace: kube-system
imagePullSecrets:
- name: harbor-registry-secret
```