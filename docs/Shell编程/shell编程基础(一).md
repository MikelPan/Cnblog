## 前言
### 为什么学Shell
Shell脚本语言是实现Linux/UNIX系统管理及自动化运维所必备的重要工具， Linux/UNIX系统的底层及基础应用软件的核心大都涉及Shell脚本的内容。每一个合格 的Linux系统管理员或运维工程师，都需要能够熟练地编写Shell脚本语言，并能够阅 读系统及各类软件附带的Shell脚本内容。只有这样才能提升运维人员的工作效率，适 应曰益复杂的工作环境，减少不必要的重复工作，从而为个人的职场发展奠定较好的基础
### 什么是shell
Shell是一个命令解释器，它在操作系统的最外层，负责直接与用户对话，把用户的输入解释给操作系统，并处理各种各样的操作系统的输出结果，输出屏幕返回给用户。

这种对话方式可以是：

交互的方式：从键盘输入命令，通过/bin/bash的解析，可以立即得到Shell的回应.
###  什么是shell脚本
命令、变量和流程控制语句等有机的结合起来，shell脚本擅长处理纯文本类型的数据，而linux中，几乎所有的配置文件，日志，都是纯文本类型文件。

### 脚本语言的分类
一、编译型语言

定义：指用专用的编译器，针对特定的操作平台（操作系统）将某种高级语言源代码一次性翻译成可被硬件平台直接运行的二进制机器码（具有操作数，指令、及相应的格式），这个过程叫做编译（./configure  make makeinstall ）；编译好的可执行性文件（.exe），可在相对应的平台上运行（移植性差，但运行效率高）。。

典型的编译型语言有， C语言、C++等。

另外，Java语言是一门很特殊的语言，Java程序需要进行编译步骤，但并不会生成特定平台的二进制机器码，它编译后生成的是一种与平台无关的字节码文件（*.class）（移植性好的原因），这种字节码自然不能被平台直接执行，运行时需要由解释器解释成相应平台的二进制机器码文件；大多数人认为Java是一种编译型语言，但我们说Java即是编译型语言，也是解释型语言也并没有错。

二、解释型语言

定义：指用专门解释器对源程序逐行解释成特定平台的机器码并立即执行的语言；相当于把编译型语言的编译链接过程混到一起同时完成的。

解释型语言执行效率较低，且不能脱离解释器运行，但它的跨平台型比较容易，只需提供特定解释器即可。

常见的解释型语言有， Python（同时是脚本语言）与Ruby等。

三、脚本语言

定义：为了缩短传统的编写-编译-链接-运行（edit-compile-link-run）过程而创建的计算机编程语言。

特点：程序代码即是最终的执行文件，只是这个过程需要解释器的参与，所以说脚本语言与解释型语言有很大的联系。脚本语言通常是被解释执行的，而且程序是文本文件。

典型的脚本语言有，JavaScript，Python，shell等。

其他常用的脚本语句种类

PHP是网页程序，也是脚本语言。是一款更专注于web页面开发（前端展示）的脚本语言，例如：Dedecms,discuz。PHP程序也可以处理系统日志，配置文件等，php也可以调用系统命令。

Perl脚本语言。比shell脚本强大很多，语法灵活、复杂，实现方式很多，不易读，团队协作困难，但仍不失为很好的脚本语言，存世大量的程序软件。MHA高可用Perl写的

Python，不但可以做脚本程序开发，也可以实现web程序以及软件的开发。近两年越来越多的公司都会要求会Python。

Shell脚本与php/perl/python语言的区别和优势？

shell脚本的优势在于处理操作系统底层的业务 （linux系统内部的应用都是shell脚本完成）因为有大量的linux系统命令为它做支撑。2000多个命令都是shell脚本编程的有力支撑，特别是grep、awk、sed等。例如：一键软件安装、优化、监控报警脚本，常规的业务应用，shell开发更简单快速，符合运维的简单、易用、高效原则.

PHP、Python优势在于开发运维工具以及web界面的管理工具，web业务的开发等。处理一键软件安装、优化，报警脚本。常规业务的应用等php/python也是能够做到的。但是开发效率和复杂比用shell就差很多了。

### 系统中的shell
```bash
cat /etc/shells 
/bin/sh
/bin/bash
/usr/bin/sh
/usr/bin/bash
```

## 脚本书写规范
### 脚本统一存放目录
```bash
mkdir -p /services/scripts;cd /services/scripts
```
### 编辑脚本使用vim
```bash
# cat  ~/.vimrc 
autocmd BufNewFile *.py,*.go,*.sh,*.java exec ":call SetTitle()"

func SetTitle()
    if expand("%:e") == 'sh'
        call setline(1,"#!/bin/bash")
        call setline(2, "##############################################################")
        call setline(3, "# File Name: ".expand("%"))
        call setline(4, "# Version: V1.0")
        call setline(5, "# Author: Mikel_Pan")
        call setline(6, "# Organization: https://github.com/plyxgit/Cnblog.git")
        call setline(7, "# Created Time : ".strftime("%F %T"))
        call setline(8, "# Description:")
        call setline(9, "##############################################################")
        call setline(10, "")
    endif
endfunc
```

### 文件名规范
名字要有意义，并且结尾以 .sh 结束

### 开发的规范和习惯小结
1) 放在统一的目录

2) 脚本以.sh为扩展名

3) 开头指定脚本解释器。

4) 开头加版本版权等信息，可配置~/.vimrc文件自动添加。

5) 脚本不要用中文注释，尽量用英文注释。

6) 代码书写优秀习惯

  a、成对的内容一次性写出来，防止遗漏，如[  ]、' '、" "等

  b、[  ]两端要有空格，先输入[  ],退格，输入2个空格，再退格写。

  c、流程控制语句一次书写完，再添加内容。(if 条件 ; then  内容;fi)ddd

  d、通过缩进让代码易读。

  f、脚本中的引号都是英文状态下的引号，其他字符也是英文状态。

## shell脚本的执行
```bash
sh/bash   scripts.sh 
chown +x   ./scripts.sh  && ./scripts.sh  
source scripts.sh
. (空格) scripts.sh
cat oldboyedu.sh |bash  # 效率较低
```
*source 与 .（点） 的作用*
```bash
# help source  |head -2
source: source 文件名 [参数]
    在当前 shell 中执行一个文件中的命令。
```
.(点)
```bash
help . |head -2
.: . 文件名 [参数]
    在当前 shell 中执行一个文件中的命令。
```
## shell 的变量

### 什么是变量
变量可以分为两类：环境变量（全局变量）和普通变量（局部变量）

环境变量也可称为全局变量，可以在创建他们的Shell及其派生出来的任意子进程shell中使用，环境变量又可分为自定义环境变量和Bash内置的环境变量

普通变量也可称为局部变量，只能在创建他们的Shell函数或Shell脚本中使用。普通变量一般是由开发者用户开发脚本程序时创建的。

特殊变量

### 环境变量
使用 env/declare/set/export -p 命令查看系统中的环境变量，这三个命令的的输出方式稍有不同。
```bash
# env
XDG_SESSION_ID=6249
HOSTNAME=kube-master
TERM=xterm
SHELL=/bin/bash
HISTSIZE=1000
SSH_CLIENT=14.103.36.188 56875 22
SSH_TTY=/dev/pts/0
USER=root
```

输出一个系统中的 环境变量
```bash
[root@kube-master ~]# echo $HOSTNAME
kube-master
```
### 普通变量
本地变量在用户当前的Shell生存期的脚本中使用。例如，本地变量OLDBOY取值为bingbing，这个值在用户当前Shell生存期中有意义。如果在Shell中启动另一个进程或退出，本地变量值将无效.
```bash
a=1;echo $a
```
### export命令
```bash
# help export 
export: export [-fn] [名称[=值] ...] 或 export -p
为 shell 变量设定导出属性。

标记每个 NAME 名称为自动导出到后续命令执行的环境。如果提供了 VALUE
则导出前将 VALUE 作为赋值。
```
export 命令说明：
当前shell窗口及子shell窗口生效
在新开的shell窗口不会生效，生效需要写入配置文件

### 环境变量相关配置文件
```bash
/etc/proflie
/etc/bashrc
~/.bashrc
~/.bash_profile
/etc/proflie.d/  # 目录
```
文件读取顺序：
```bash
① /etc/profile
② ~/.bash_profile
③ ~/.bashrc
④ /etc/bashrc
```
### 环境变量的知识小结
- 变量名通常要大写。
- 变量可以在自身的Shell及子Shell中使用。
- 常用export来定义环境变量。
- 执行env默认可以显示所有的环境变量名称及对应的值。
- 输出时用“$变量名”，取消时用“unset变量名”。
- 书写crond定时任务时要注意，脚本要用到的环境变量最好先在所执行的Shell脚本中重新定义。
- 如果希望环境变量永久生效，则可以将其放在用户环境变量文件或全局环境变量文件里。

