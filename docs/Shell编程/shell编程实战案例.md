### 批量生成随机字符文件名
```bash
# 问题说明
生成10个txt文件, 每个文件名包含10个随机小写字母
# 问题分析
采用openssl 生成随机数，操作结果如下：
1、生成40位随机数
openssl rand -base64 40
2、替换掉非小写字母的字符
openssl rand -base64 40 | sed 's#[^a-z]##g'
3、利用cut截取10位
openssl rand -base64 40 | sed 's#[^a-z]##g' | cut -c 2-10
# 实现的脚本如下：
cat > touch_file.sh <<EOF
#!/bin/bash
Path=/root/files
[ -d "$Path" ] || mkdir -p $Path
for n in `seq 10`
do
    file_name=$(openssl rand -base64 40 | sed 's#[^a-z]##g' | cut -c 2-10)
    touch $Path/${file_name}.txt
done
EOF
# 执行结果如下
[root@kube-master files]# tree
.
├── dikwbgyqx.txt
├── dolkcrzay.txt
├── dvagxwmqi.txt
├── evuwnkwqo.txt
├── fhnoibqxh.txt
├── marihckbw.txt
├── pkxopjfdo.txt
├── pwxfipbxz.txt
├── rhmydyvev.txt
└── wleprxofl.txt
```

### 多进程
```bash
# 脚本实现如下
#!/usr/bin/env bash

THREAD_NUM=10        #定义进程数量
if [[ -a tmp ]]
then        #防止计数文件存在引起冲突
    rm tmp                    #若存在先删除
fi
mkfifo tmp                    #创建fifo型文件用于计数
exec 9<>tmp

for (( i=0;i<$THREAD_NUM;i++ )) #向fd9文件中写回车，有多少个进程就写多少个
do
    echo -ne "\n" 1>&9
done

fn_num ()                    #用于测试的函数，传进来一个整数与10取余，并按照结果sleep
{                            #目的是让每个进程执行的时间有较大差异，方便看出子进程情况
   a=$1
   b=$(( $a % 10 ))
   echo "--->$a"                #标记子进程开始执行
   sleep $b
   echo "<------------------$a"    #标记子进程执行结束
}

for (( i=0;i < 100;i++ ))
do
{
    read -u 9    #read一次，就减去fd9中一个回车
    {   #当fd9中没有回车符时，脚本就会停住，达到控制进程数量的目的
        fn_num $i
        echo -ne "\n" 1>&9    #某个子进程执行结束，向fd9追加一个回车符，补充循环开始减去的那个
    }&

}
done

wait   #等待所有后台子进程结束

echo "over"
rm tmp
```