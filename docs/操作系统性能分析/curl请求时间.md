### curl 请求时间
```bash
time_namelookup ：DNS 域名解析的时候，就是把 https://zhihu.com 转换成 ip 地址的过程
time_connect ：TCP 连接建立的时间，就是三次握手的时间
time_appconnect ：SSL/SSH 等上层协议建立连接的时间，比如 connect/handshake 的时间
time_redirect ：从开始到最后一个请求事务的时间
time_pretransfer ：从请求开始到响应开始传输的时间
time_starttransfer ：从请求开始到第一个字节将要传输的时间
time_total ：这次请求花费的全部时间
```
### curl 请求测试
```bash
curl -v -w "time_namelookup: %{time_namelookup}\n 
time_connect: %{time_connect}\n  
time_appconnect: %{time_appconnect}\n  
time_redirect: %{time_redirect}\n  
time_pretransfer: %{time_pretransfer}\n  
time_starttransfer: %{time_starttransfer}\n  
----------\n
time_total: %{time_total}\n" -s https://www.baidu.com
```