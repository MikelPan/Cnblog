```bash
strace -o output.txt -T -tt -e trace=all -p 28979
strace -T -tt -e trace=all -p 20114
strace -T -tt -e trace=process -v -p 22149
-e trace=file     跟踪和文件访问相关的调用(参数中有文件名)
-e trace=process  和进程管理相关的调用，比如fork/exec/exit_group
-e trace=network  和网络通信相关的调用，比如socket/sendto/connect
-e trace=signal    信号发送和处理相关，比如kill/sigaction
-e trace=desc  和文件描述符相关，比如write/read/select/epoll等
-e trace=ipc 进程见同学相关，比如shmget等
strace -T -tt -e trace=network -v -p 22149
```

