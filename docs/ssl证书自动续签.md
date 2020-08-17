## 自签证书
### 生成CA证书私钥
```bash
openssl genrsa -out ca.key 4096
```
### 生成CA证书
```bash
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=CN/ST=Beijing/L=Beijing/O=IT/OU=Docker/CN=domain.com" \
 -key ca.key \
 -out ca.crt
```
### 生成私钥
```bash
openssl genrsa -out domain.com.key 4096
```
### 生成证书签名请求
```bash
openssl req -sha512 -new \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=IT/OU=Docker/CN=domain.com" \
    -key domain.com.key \
    -out domain.com.csr
```
### 生成一个x509 v3扩展文件
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
### 使用该v3.ext文件为服务器主机生成证书
```bash
openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in domain.com.csr \
    -out domain.com.crt
```
## 自动续期
### 安装证书安装脚本
```shell
curl https://get.acme.sh | sh
alias acme.sh=~/.acme.sh/acme.sh
```
### 证书签发
```shell
# 使用http方式
acme.sh --issue -d plyx.site -d *.plyx.site -w /var/www/html/plyx.site
# 使用dns 方式
acme.sh --issue -d *.plyx.site -d plyx.site --dns --yes-I-know-dns-manual-mode-enough-go-ahead-please # 添加A记录
dig -t txt  _acme-challenge.clsn.io @8.8.8.8 # 验证证书
acme.sh --renew  -d *.plyx.site -d plyx.site --dns --yes-I-know-dns-manual-mode-enough-go-ahead-please # 生成证书

# 使用dns api方式
api 参考文档 https://github.com/Neilpang/acme.sh/tree/master/dnsapi
export Ali_Key=""
export Ali_Secret=""
acme.sh --issue --dns dns_ali -d plyx.site -d *.plyx.site
acme.sh --issue --dns dns_ali -d plyx.site -d *.plyx.site --keylength ec-256
```

#### 说明参数的含义：

- --issue是 acme.sh 脚本用来颁发证书的指令；
- -d是--domain的简称，其后面须填写已备案的域名；
- -w 是--webroot的简称，其后面须填写网站的根目录

```shell
# 查看证书
acme.sh --list
# 删除证书
acme.sh --remove -d plyx.site [--ecc]
```
### 安装证书
生成的证书放在了/root/.acme.sh/plyx.site目录，因为这是 acme.sh 脚本的内部使用目录，而且目录结构可能会变化，所以我们不能让 Nginx 的配置文件直接读取该目录下的证书文件。
```shell
acme.sh  --install-cert -d plyx.site \
         --key-file /usr/local/nginx/conf.d/ssl/key.pem \
         --fullchain-file /etc/nginx/conf.d/ssl/cert.pem \
         --reloadcmd "service nginx force-reload"
```
### 合并证书
```shell
cat fullchain.cer plyx.site.key > haproxy.crt
```
### 更新证书
```shell
acme.sh --renew -d plyx.site --force
acme.sh --renew -d plyx.site --force --ecc
```

### 检查域名过期时间
```shell
echo |openssl s_client -servername plyx.site  -connect plyx.site:443 2>/dev/null | openssl x509 -noout -dates|awk -F '=' '/notAfter/{print $2}'
```
### 检查证书过期时间
```bash
openssl x509 -in cert.pem -noout -dates
```
### 更新脚本
升级到最新版
```shell
acme.sh --upgrade
```
自动更新
```shell
# 开启自动更新
acme.sh  --upgrade  --auto-upgrade
# 关闭自动更新
acme.sh  --upgrade  --auto-upgrade 0
```
### 定时任务更新证书
```shell
55 0 * * * "/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" > /dev/null
```