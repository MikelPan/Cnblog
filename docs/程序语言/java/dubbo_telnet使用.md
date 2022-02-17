### telnet 调式dubbo
#### 进入dubbo
```bash
telnet 127.0.0.1 dubbo_port
```
#### dubbo查看服务
- ls
1、ls 显示服务列表
2、ls -l 显示服务详细列表
3、ls xxxxService 显示服务方法列表
4、ls -l xxxxService 显示服务方法详细列表
```bash
# 查看dubbo所有服务
dubbo>ls
# 查看dubbo所有服务详细信息
# 查看具体服务方法
dubbo> ls -l com
```
- ps
1、ps 显示服务端口列表
2、ps -l 显示服务地址列表
3、ps port 显示端口上的连接信息
4、ps -l port 显示端口上的连接信息
```bash
# 查看服务
dubbo> ps
# 查看服务详细列表
dubbo> ps -l
# 查看端口上连接信息
dubbo> ps 

```
- trace
1、trace xxxxService 跟踪1次服务任意方法调用情况
2、trace xxxxService 10 跟踪10次服务任意方法调用情况
3、trace xxxxService xxxxMethod 跟踪1次服务方法调用情况
4、trace xxxxService xxxxMethod 10 跟踪10次服务方法调用情况
```bash
```
- invoke
1、invoke xxxxService 调用方法
```bash

```
