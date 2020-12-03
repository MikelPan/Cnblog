### 安装Vscode
#### 安装
```bash
# 安装
curl -fsSL https://code-server.dev/install.sh | sh
# 配置免密
sed -i.bak 's/auth: password/auth: none/' ~/.config/code-server/config.yaml
# 重启
systemctl restart code-server@$USER
```
#### 配置ssh 代理
```bash
ssh -N -L 8080:127.0.0.1:8080 root@ip
```
#### 配置http代理
```bash
# nginx 访问配置
server {
    listen 80;
    listen [::]:80;
    server_name mydomain.com;

    location / {
      proxy_pass http://localhost:8080/;
      proxy_set_header Host $host;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection upgrade;
      proxy_set_header Accept-Encoding gzip;
    }
}
```
##### 配置https代理
```bash
# acme.sh 配置证书
# nginx 加载ssl 证书配置

```