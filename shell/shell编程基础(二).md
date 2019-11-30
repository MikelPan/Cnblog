## 条件表达式
### 文件判断
常用文件测试操作符:

| 常用文件测试操作符 | 说明 | 
| :------| :------ |
| -d文件，d的全拼为directory | 文件存在且为目录则为真，即测试表达式成立 |
| -f文件，f的全拼为file | 文件存在且为普通文件则为真，即测试表达式成立 |
| -e文件，e的全拼为exist | 文件存在则为真，即测试表达式成立。注意区别于“-f”，-e不辨别是目录还是文件 |
| -r文件，r的全拼为read | 文件存在且可读则为真，即测试表达式成立 |
| -s文件，s的全拼为size | 文件存在且文件大小不为0则为真，即测试表达式成立 |
| -w文件，w的全拼为write | 文件存在且可写则为真，即测试表达式成立 |
| -x文件，x的全拼为executable | 文件存在且可执行则为真，即测试表达式成立 |
| -L文件，L的全拼为link | 文件存在且为链接文件则为真，即测试表达式成立 |
| fl -nt f2，nt 的全拼为 newer than | 文件fl比文件f2新则为真，即测试表达式成立。根据文件的修改时间来计算 |
| fl -ot f2，ot 的全拼为 older than | 文件fl比文件f2旧则为真，即测试表达式成立。根据文件的修改时间来计算 |

*判断文件是否存在*
```bash
[root@kube-master ~]# [ -f /etc/hosts ]
[root@kube-master ~]# echo $?
0
[root@kube-master ~]# [ -f /etc/hosts1 ]
[root@kube-master ~]# echo $?
1
```
*判断文件是否存在,返回方式*
```bash
[root@kube-master ~]# [ -f /etc/hosts ] && echo "文件存在" || echo "文件不存在" 
文件存在
[root@kube-master ~]# [ -f /etc/hosts1 ] && echo "文件存在" || echo "文件不存在" 
文件不存在
```
*判断目录是否存在*
```bash
[root@kube-master ~]# [ -d /tmp ] && echo "目录存在" || echo "目录不存在" 
目录存在
[root@kube-master ~]# [ -d /tmp1 ] && echo "目录存在" || echo "目录不存在" 
目录不存在
```
*使用变量的方法进行判断*
```bash
dir=/etc1/;[ -d $dir ] && tar zcf etc.tar.gz $dir || echo "$dir目录不存在"
```
### 字符串判断
*字符串测试操作符*
| 常用字符串测试操作符 | 说明 | 
| :------| :------ |
| -n "字符串" | 若字符串的长度不为0,则为真，即测试表达式成立，n可以理解为no zero |
| -Z "字符串" | 若字符串的长度为0,则为真，即测试表达式成立，z可以理解为zero的缩写 |
| "串 1"== "串 2" | 若字符串1等于字符串2,则为真，即测试表达式成立，可使用"=="代替"=" |
| "串 1" ！= "串 2" | 若字符串1不等于字符串2,则为真，即测试表达式成立，但不能用"!=="代替"!=" |
1.对于字符串的测试，一定要将字符串加双引号之后再进行比较。

2.空格非空 
*-z 判断字符串长度*
```bash
[root@kube-master ~]# x=  ; [ -z "$x" ] && echo "输入为空" || echo '输入有内容'
输入为空
[root@kube-master ~]# x=12 ; [ -z "$x" ] && echo "输入为空" || echo '输入有内容'
输入有内容
```
*-n 判断字符串长度*
```bash
[root@kube-master ~]# x=12 ; [ -n "$x" ] && echo "输入有内容" || echo '输入为空'
输入有内容
[root@kube-master ~]# x= ; [ -n "$x" ] && echo "输入有内容" || echo '输入为空'
输入为空
```
*"串 1" == " 串 2 "*       使用定义变量的方式进行判断
```bash
cmd=$1
[ "$cmd" == "start" ] && echo start
# 测试
[root@kube-master ~]# cmd=start;[ "$cmd" == "start" ] && echo start
start
```
### 整数判断
*整数二元比较操作符参考*
| 在[]以及test中使用的比较符号 | 在(())和[[]]中使用的比较符号 | 说明 |
| :------| :------ | :------ |
| -eq | ==或= | 相等，全拼为equal |
| -ne | ！= | 不相等，全拼为not equal |
| -gt | > | 大于，全拼为greater than |
| -ge | >= | 大于等于，全拼为greater equal |
| -lt | < | 小于，全拼为less than |
| -le | <= | 小于等于，全拼为less equal |
*判断两数是否相等*
```bash
[root@kube-master ~]# [ 1 -eq 1 ]
[root@kube-master ~]# echo $?
0
[root@kube-master ~]# [ 1 -eq 2 ]
[root@kube-master ~]# echo $?
1
```
*大于等于*
```bash
[root@kube-master ~]# [ 11 -ge 1 ] && echo "成立" || echo "不成立"
成立
```
*小于*
```bash
[root@kube-master ~]# [ 11 -lt 1 ] && echo "成立" || echo "不成立"
不成立
```
*大于*
```bash
[root@kube-master ~]# [ 11 -gt 1 ] && echo "成立" || echo "不成立"
成立
```
*不等于*
```bash
[root@kube-master ~]# [ 11 -ne 1 ] && echo "成立" || echo "不成立"
成立
```
### 逻辑符号
*常用逻辑操作符*

| 在[]和test中使用的操作符 | 说明 | 在[[]]和(())中使用的操作符 | 说明 |
| :------| :------ | :------ | :------ |
| -a | -a[ 条件A -a  条件B ]A与B都要成立，整个表达式才成立 |　&& | and，与，两端都为真，则结果为真　|
| -o | [ 条件A -o  条件B] A与B都不成立，整个表达式才不成立 | \|\| | or，或，两端有一个为真，则结果为真 |
| ！ | | ! | not，非，两端相反，则结果为真 |
*逻辑操作符与整数判断配合*
```bash
[root@kube-master ~]# [ 11 -ne 1 ] && echo "成立" || echo "不成立"
成立
```
*取反*
```bash
[root@kube-master ~]# [ ! 11 -ne 1 ] && echo "成立" || echo "不成立"
不成立
```
*两边都为真*
```bash
[root@kube-master ~]# [  11 -ne 1 -a 1 -eq 1 ] && echo "成立" || echo "不成立"
成立
```
*至少有一边为真*
```bash
[root@kube-master ~]# [  11 -ne 1 -o 1 -eq 1 ] && echo "成立" || echo "不成立"
成立
```
*感叹号的特殊用法*
使用历史命令,感叹号加上history中的序号,即可执行
```bash
[root@kube-master ~]# !516
 ls
anaconda-ks.cfg  bootime.avg  setup.sh  vim
```
##  if条件语句
### 三种语法
*单分支语句*
```bash
if [ -f /etc/hosts ]
then
    echo '文件存在'
fi
```
*双分支语句*
```bash
if [ -f /etc/hosts ]  
then
   echo "文件存在"
else
echo "文件不存在"
   echo "..." >>/tmp/test.log
fi
```
*多分支语句*
```bash
if [ -f /etc/hosts ]  
then
   echo " hosts文件存在"
elif [ -f /etc/host ]
then
   echo " host文件存在"
fi
```
### if条件语句小结
单分支：一个条件一个结果
双分支：一个条件两个结果
多分支：多个条件多个结果

## case条件结构语句
### case语法结构
```bash
case "字符串变量" in 
  值1)
     指令1
     ;;
  值2)
     指令2
     ;;
  值*)
     指令
esac
```
### case与if的对比
*case书写方式*
```bash
case $name in
  值1) 
      指令1
      ;;
  值2) 
      指令2
      ;;
   *) 
      指令
esac
```
*if书写方式*
```bash
if [ $name == "值1" ]
  then 
    指令1
elif [ $name == "值2" ]
  then 
    指令2
else
    指令    
fi
```
### case值的书写方式
```bash
apple)
    echo -e "$RED_COLOR apple $RES"
      ;;
```
也可以这样写，输入2种格式找同一个选项;
```bash
apple|APPLE)
    echo -e "$RED_COLOR apple $RES"
      ;;
```
### case语句小结
- case语句就相当于多分支的if语句。case语句的优势是更规范、易读。
- case语句适合变量的值少，且为固定的数字或字符串集合。(1,2,3)或(start,stop,restart)。
- 系统服务启动脚本传参的判断多用case语句，多参考rpcbind/nfs/crond脚本；菜单脚本也可以使用case

## 其他补充说明
### inux中产生随机数的方法
```bash
[root@kube-master ~]#  echo $RANDOM 
29291
[root@kube-master ~]#  echo $RANDOM 
5560
[root@kube-master ~]#  echo $RANDOM 
2904
```
### echo 命令输出带颜色字符
```bash
# 彩色字体
echo -e "\033[30m 黑色字 clsn \033[0m"
echo -e "\033[31m 红色字 clsn \033[0m"
echo -e "\033[32m 绿色字 clsn \033[0m"
echo -e "\033[33m 黄色字 clsn \033[0m"
echo -e "\033[34m 蓝色字 clsn \033[0m"
echo -e "\033[35m 紫色字 clsn \033[0m"
echo -e "\033[36m 天蓝字 clsn \033[0m"
echo -e "\033[37m 白色字 clsn \033[0m"
# 彩色底纹
echo -e "\033[40;37m 黑底白字 clsn \033[0m"
echo -e "\033[41;37m 红底白字 clsn \033[0m"
echo -e "\033[42;37m 绿底白字 clsn \033[0m"
echo -e "\033[43;37m 黄底白字 clsn \033[0m"
echo -e "\033[44;37m 蓝底白字 clsn \033[0m"
echo -e "\033[45;37m 紫底白字 clsn \033[0m"
echo -e "\033[46;37m 天蓝白字 clsn \033[0m"
# 特效字体
echo -e　"\033[0m 关闭所有属性"
echo -e "\033[1m 设置高亮度"
echo -e "\033[4m 下划线"
echo -e "\033[5m 闪烁"
echo -e "\033[7m 反显"
echo -e "\033[8m 消隐"
echo -e "\033[30m — \033[37m 设置前景色"
echo -e "\033[40m — \033[47m 设置背景色"
echo -e "\033[nA 光标上移 n 行"
echo -e "\033[nB 光标下移 n 行"
echo -e "\033[nC 光标右移 n 行"
echo -e "\033[nD 光标左移 n 行"
echo -e "\033[y;xH 设置光标位置"
echo -e "\033[2J 清屏"
echo -e "\033[K 清除从光标到行尾的内容"
echo -e "\033[s 保存光标位置"
echo -e "\033[u 恢复光标位置"
echo -e "\033[?25l 隐藏光标"
echo -e "\033[?25h 显示光标"
```
### 显示文本中的隐藏字符
使用cat命令查看文本中的隐藏字符
```bash
[root@kube-master ~]# cat --help
Usage: cat [OPTION]... [FILE]...
Concatenate FILE(s), or standard input, to standard output.

  -A, --show-all           equivalent to -vET
  -b, --number-nonblank    number nonempty output lines, overrides -n
  -e                       equivalent to -vE
  -E, --show-ends          display $ at end of each line
  -n, --number             number all output lines
  -s, --squeeze-blank      suppress repeated empty output lines
  -t                       equivalent to -vT
  -T, --show-tabs          display TAB characters as ^I
  -u                       (ignored)
  -v, --show-nonprinting   use ^ and M- notation, except for LFD and TAB
      --help     display this help and exit
      --version  output version information and exit

With no FILE, or when FILE is -, read standard input.

Examples:
  cat f - g  Output f's contents, then standard input, then g's contents.
  cat        Copy standard input to standard output.

GNU coreutils online help: <http://www.gnu.org/software/coreutils/>
For complete documentation, run: info coreutils 'cat invocation
```
使用cat -A查看隐藏的字符:
```bash
[root@kube-master ~]# cat -A /etc/hosts
::1^Ilocalhost^Ilocalhost.localdomain^Ilocalhost6^Ilocalhost6.localdomain6$
127.0.0.1^Ilocalhost^Ilocalhost.localdomain^Ilocalhost4^Ilocalhost4.localdomain4$
$
172.18.77.102^IiZwz91ivbj51belpslwpogZ^IiZwz91ivbj51belpslwpogZ$
$
$
$
$
# hostname$
172.18.77.102 kube-master$
49.235.236.38 kube-node$
120.79.77.84 apiserver.cluster.local$
```
### shell 脚本段注释方法
方法一：
```bash
<<EOF
  内容
EOF
```
方法二:
```bash
一行注释方法 → : '内容'
段注释方法 ↓
:' 
 http://blog.znix.top
'
```

