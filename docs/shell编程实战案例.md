### 批量生成随机字符文件名
```bash
# 问题说明
生成10个txt文件, 每个文件名包含10个随机小写字母
# 问题分析
采用openssl 生成随机数，操作结果如下：
1、生成40位随机数
openssl rand -base64 40
2、替换掉飞小写字母的字符
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

### 

