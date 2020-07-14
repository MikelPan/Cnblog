## for循环语句
在计算机科学中，for循环（英语：for loop）是一种编程语言的迭代陈述，能够让程式码反复的执行。它跟其他的循环，如while循环，最大的不同，是它拥有一个循环计数器，或是循环变数。这使得for循环能够知道在迭代过程中的执行顺序。

### shell中的for循环
shell中的for 循环与在c中不同，它包含三种形式：
第一种结构是列表for 循环;
第二种结构就是不带列表的for循环；
第三种就类似于C语言。

1、列表for循环(常用)
```bash
#！/bin/bash
for i in 取值列表
do
    循环主体/命令
done
```
2、不带列表for循环(示例)
```bash
#!/bin/absh
echo "今天是什么日子："  
for i 
     do   
     echo "$i" 
done 
```
脚本执行结果：
```bash
[root@kube-master ~]# sh test.sh 好日子
今天是什么日子：
好日子
```
3、类似C语言的风格（这种用法常在C语语言中使用）
```bash
for((i=0;i<=3;i++))
    do
      echo $i
done 
```
## while循环语句
在编程语言中，while循环（英语：while loop）是一种控制流程的陈述。利用一个返回结果为布林值（Boolean）的表达式作为循环条件，当这个表达式的返回值为“真”（true）时，则反复执行循环体内的程式码；若表达式的返回值为“假”（false），则不再执行循环体内的代码，继续执行循环体下面的代码。

因为while循环在区块内代码被执行之前，先检查陈述是否成立，因此这种控制流程通常被称为是一种前测试循环（pre-test loop）。相对而言do while循环，是在循环区块执行结束之后，再去检查陈述是否成立，被称为是后测试循环。

### shell中while语法
```bash
while 条件
  do
    命令
done
```
sleep 单位 秒  sleep 1 休息1秒
usleep 单位 微秒 usleep 1000000 休息1s
1微秒等于百万分之一秒（10的负6次方秒）

## break continue exit return
条件与循环控制及程序返回值命令表

| 命令 | 说明　|
| :------ | :------ |
| break n | 如果省略n，则表示跳出整个循环，n表示跳出循环的层数 |
| continue n | 如果省略n，则表示跳过本次循环，忽略本次循环的剩余代码，进人循环的下一次循环。 n表示退到第n层继续循环 |
| exit n | 退出当前Shell程序，n为上一次程序执行的状态返回值。n也可以省略，在下一个Shell里可通过"$?"接收exit n的n值 |
| return n | 用于在函数里作为函数的返回值，以判断函数执行是否正确。在下一个Shell里可通过"$?"接收exit n的n值 |

```bash
简单来说即：
break    跳出循环
continue 跳出本次循环
exit     退出脚本
return   与 exit 相同，在函数中使用
```
### break命令说明
```bash
[root@k8s-master] # help break 
break: break [n]
    退出 for、while、或 until 循环
    
    退出一个 FOR、WHILE 或 UNTIL 循环。如果指定了N，则打破N重
    循环
    
    退出状态：
    退出状态为0除非 N 不大于或等于 1。
```

### continue命令说明
```bash
[root@k8s-master]# help continue 
continue: continue [n]
    继续 for、while、或 until 循环。
    
    继续当前 FOR、WHILE 或 UNTIL 循环的下一步。
    如果指定了 N， 则继续当前的第 N 重循环。
    
    退出状态：
    退出状态为 0 除非 N 不大于或等于1。
```
### exit命令说明
```bash
[root@k8s-master]# help exit
exit: exit [n]
    退出shell。
    
    以状态 N 退出 shell。  如果 N 被省略，则退出状态
    为最后一个执行的命令的退出状态。
```
### return命令说明
```bash
[root@k8s-master]# help return 
return: return [n]
    从一个 shell 函数返回。
    
    使一个函数或者被引用的脚本以指定的返回值 N 退出。
    如果 N 被省略，则返回状态就是
    函数或脚本中的最后一个执行的命令的状态。
    
    退出状态：
    返回 N，或者如果 shell 不在执行一个函数或引用脚本时，失败。
```
## shell中的数组
### 为什么会产生Shell数组

通常在开发Shell脚本时，定义变量采用的形式为“a=l;b=2;C=3”，可如果有多个 变量呢？这时再逐个地定义就会很费劲，并且要是有多个不确定的变量内容，也会难以 进行变量定义，此外，快速读取不同变量的值也是一件很痛苦的事情，于是数组就诞生 了，它就是为了解决上述问题而出现的。

### 什么是Shell数组
Shell的数组就是一个元素集合，它把有限个元素（变量或字符内容）用一个名字来 命名，然后用编号对它们进行区分。这个名字就称为数组名，用于区分不同内容的编 号就称为数组下标。组成数组的各个元素（变量）称为数组的元素，有时也称为下标变量.

### 数组中的增删改查
Shell的数组就是一个元素集合，它把有限个元素（变量或字符内容）用一个名字来 命名，然后用编号对它们进行区分。这个名字就称为数组名，用于区分不同内容的编 号就称为数组下标。组成数组的各个元素（变量）称为数组的元素，有时也称为下标变量.

*shell数组的定义*
```bash
# 使用小括号将变量括起来赋值
array=(1 2 3)
echo ${array[*]}
1 2 3
# 使用小括号将变量括起来赋值,同时采用键值对的方式赋值
array=([1]=one [2]=two [3]=three)
echo ${array[*]}
one two three
```
*数组增加与修改*
```bash
# 通过添加下标的方式增加数组
array[4]=four
array[3]=five
echo ${array[*]}
one two five four
```

*数组的删除*
```bash
# 通过unset[]下标删除
unset array[1]
ehco ${array[*]}
two three
```
## shell 函数
### shell 函数语法
```bash
# 第一种写法
function main() {
    函数体
    return n
}
# 第二种写法
main () {
    函数体
    return n
}
```
