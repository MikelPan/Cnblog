

### tcpdump
#### 抓取http request post
tcpdump -s 0 -nn -vv -AA 'tcp dst port 9001 and (tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x504f5354)'
#### 抓取http request get
tcpdump -s 0 -nn -vv -AA 'tcp dst port 9001 and (tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x47455420)'
#### 抓取http request & request response
tcpdump -s 0 -nn -vv -AA 'tcp dst port 9001 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'
#### 抓取http数据包
tcpdump -s 0 -nn -vv -AA 'tcp dst port 9001 and (tcp[20:2]=0x4745 or tcp[20:2]=0x4854)'
#### 获取网络数据包
tcpdump net 192.168.1.0/24
#### 获取主机数据包
tcpdump host 192.168.1.100
