
### 主要参数
-i 设置抓包的网络接口，不设置则默认为第一个非自环接口
-D 列出当前存在的网络接口
-f 设定抓包过滤表达式
-s 设置每个抓包的大小，默认为65535。（相当于tcpdump的-s，tcpdump默认抓包的大小仅为68）
-p 设置网络接口以非混合模式工作，即只关心和本机有关的流量。
-B 设置内核缓冲区大小，仅对windows有效。
-y 设置抓包的数据链路层协议，不设置则默认为-L找到的第一个协议，局域网一般是EN10MB等。
-L 列出本机支持的数据链路层协议，供-y参数使用。 

```bash

tshark -s 512 -i eth0 -n -f 'tcp dst port 80' -R 'http.host and http.request.uri' -T fields -e http.host -e http.request.uri -l | tr -d '\t'


tshark  -f 'tcp dst port 443' -R 'http.host and http.request.uri' -T fields -e http.host -e http.request.uri -l | tr -d '\t'


tshark  -r test.cap -R "http.request.line || http.file_data || http.response.line" -T fields -e http.request.line -e http.file_data -e http.response.line -E header=y
```



