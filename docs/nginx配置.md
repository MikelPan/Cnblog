### 配置反向代理
#### 创建加密认证
```bash
# 创建密码文件
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 24
yum install -y http-tools
htpasswd -bc /usr/local/nginx/conf.d/passwd admin `cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 24`
chmod 400 /usr/local/nginx/conf.d/passwd
chown nginx /usr/local/nginx/conf.d/passwd
# 添加加密配置
server {
    listen 80;
    server_name _;
    location / {
        root html;
        index index.html index.htm;
        auth_basic "admin";
        auth_basic_user_file /usr/local/nginx/conf.d/passwd;
    }
    access_log off;
}
# 重新加载nginx
service nginx reload
```
#### nginx 自动下载

#### upstream配置
upstream apigateway{
    server ip:port weight=1 max_fails=2 fail_timeout=10s;
}
#### proxy 配置
```bash
proxy_set _header Host $host;
proxy_set _header X-Forwarded-For $remode_addr;
proxy_connect_timeout 60;
proxy_sent_timeout 60;
proxy_read_timeout 60;
proxy_buffer_size 4k;
proxy_buffers 4 32k;
proxy_busy_buffers_size 64k;
proxy_temp_file_write_size 64k;
proxy_http_version 1.1;
proxy_set_header Connection "";
proxy_next_upstream invalid_header error timeout http_500 http_502 http_503 http_504;
```
[官方文档说明](http://nginx.org/en/docs/http/ngx_http_proxy_module.html)

#### location 配置
#### http nginx.conf 主配置文件
```bash
# 掩藏版本号
server_tokens off;
# 客户端请求文件大小
client_max_body_size  10m;
```










