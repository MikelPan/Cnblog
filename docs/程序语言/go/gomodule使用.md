### go module 使用
#### 配置 go module
*windows下*
```bash
set GO111MODULE=on 或者 set GO111MODULE=auto
```
*mac或者linux下*
```bash
export GO111MODULE=on 或者 export GO111MODULE=auto
```
#### go proxy
*windows下*
```bash
go env -w GOPROXY=https://goproxy.cn,direct
```
*linux或者mac下*
```bash
export GOPROXY=https://goproxy.cn
```
#### 创建项目
```bash
mdkir -p /goprojects/workspace/go-learning
cd /goprojects/workspace/go-learning && go mod init github.com/user/go-learning
go mod vendor && mv go.mod vendor
git init 
git checkout -b dev
echo '#### go-learning' > README.md
git add README.md
git commit -m "添加README"
git remote add origin https://user:password@github.com/user/go-learngit.git
git config --local user.name "user"
git push -u origin dev
sed -i 's#https://github.com/user/go-learngit.git#https://user:password@github.com/user/go-learngit.git#g' .git/config
```
<!--stackedit_data:
eyJoaXN0b3J5IjpbLTEzMzUxMDI4NzNdfQ==
-->