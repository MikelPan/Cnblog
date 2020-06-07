
### tshark简介

### tsahrk 安装
```bash
# linux rehat & centos
yum install -y wireshark wireshark-qt
```

### 主要参数
```bash
捕获停止选项:
　　-c: -c <packet count> 捕获n个包之后结束，默认捕获无限个;
　　-a: -a <autostop cond.> ... duration:NUM，在num秒之后停止捕获;
　　　　　　　　　　　　　　　　　　 filesize:NUM，在numKB之后停止捕获;
　　　　　　　　　　　　　　　　　   files:NUM，在捕获num个文件之后停止捕获;

捕获输出选项:
　　-b <ringbuffer opt.> ... ring buffer的文件名由-w参数决定,-b参数采用test:value的形式书写;
　　　　　　　　　　　　　　　　 duration:NUM - 在NUM秒之后切换到下一个文件;
　　　　　　　　　　　　　　　　 filesize:NUM - 在NUM KB之后切换到下一个文件;
　　　　　　　　　　　　　　　　 files:NUM - 形成环形缓冲，在NUM文件达到之后;
RPCAP选项:
　　remote packet capture protocol，远程抓包协议进行抓包；
　　-A:  -A <user>:<password>,使用RPCAP密码进行认证;

输入文件:
　　-r: -r <infile> 设置读取本地文件

处理选项:
　　-2: 执行两次分析
　　-R: -R <read filter>,包的读取过滤器，可以在wireshark的filter语法上查看；在wireshark的视图->过滤器视图，在这一栏点击表达式，就会列出来对所有协议的支持。
　　-Y: -Y <display filter>,使用读取过滤器的语法，在单次分析中可以代替-R选项;
　　-n: 禁止所有地址名字解析（默认为允许所有）
　　-N: 启用某一层的地址名字解析。“m”代表MAC层，“n”代表网络层，“t”代表传输层，“C”代表当前异步DNS查找。如果-n和-N参数同时存在，-n将被忽略。如果-n和-N参数都不写，则默认打开所有地址名字解析。
　　-d: 将指定的数据按有关协议解包输出,如要将tcp 8888端口的流量按http解包，应该写为“-d tcp.port==8888,http”;tshark -d. 可以列出所有支持的有效选择器。
　　
输出选项:
　　-w: -w <outfile|-> 设置raw数据的输出文件。这个参数不设置，tshark将会把解码结果输出到stdout,“-w -”表示把raw输出到stdout。如果要把解码结果输出到文件，使用重定向“>”而不要-w参数。
　　-F: -F <output file type>,设置输出的文件格式，默认是.pcapng,使用tshark -F可列出所有支持的输出文件类型。
　　-V: 增加细节输出;
　　-O: -O <protocols>,只显示此选项指定的协议的详细信息。
　　-P: 即使将解码结果写入文件中，也打印包的概要信息；
　　-S: -S <separator> 行分割符
　　-x: 设置在解码输出结果中，每个packet后面以HEX dump的方式显示具体数据。
　　-T: -T pdml|ps|text|fields|psml,设置解码结果输出的格式，包括text,ps,psml和pdml，默认为text
　　-e: 如果-T fields选项指定，-e用来指定输出哪些字段;
　　-E: -E <fieldsoption>=<value>如果-T fields选项指定，使用-E来设置一些属性，比如
　　　　header=y|n
　　　　separator=/t|/s|<char>
　　　　occurrence=f|l|a
　　　　aggregator=,|/s|<char>
　　-t: -t a|ad|d|dd|e|r|u|ud 设置解码结果的时间格式。“ad”表示带日期的绝对时间，“a”表示不带日期的绝对时间，“r”表示从第一个包到现在的相对时间，“d”表示两个相邻包之间的增量时间（delta）。
　　-u: s|hms 格式化输出秒；
　　-l: 在输出每个包之后flush标准输出
　　-q: 结合-z选项进行使用，来进行统计分析；
　　-X: <key>:<value> 扩展项，lua_script、read_format，具体参见 man pages；
　　-z：统计选项，具体的参考文档;tshark -z help,可以列出，-z选项支持的统计方式。

其他选项:
　　-h: 显示命令行帮助；
　　-v: 显示tshark 的版本信息;
```

```bash

tshark -s 512 -i eth0 -n -f 'tcp dst port 80' -R 'http.host and http.request.uri' -T fields -e http.host -e http.request.uri -l | tr -d '\t'


tshark  -f 'tcp dst port 443' -R 'http.host and http.request.uri' -T fields -e http.host -e http.request.uri -l | tr -d '\t'


tshark  -r test.cap -R "http.request.line || http.file_data || http.response.line" -T fields -e http.request.line -e http.file_data -e http.response.line -E header=y
```

#### 案例说明
```bash
# 实时打印mysql查询
tshark -s 512 -i eth0 -n -f 'tcp dst port 3306' -R 'mysql.query' -T fields -e mysql.query
```
- [官方文档](https://links.jianshu.com/go?to=https%3A%2F%2Fwww.wireshark.org%2Fdocs%2Fmanpages%2Ftshark.html)

