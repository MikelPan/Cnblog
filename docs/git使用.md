## git 介绍
### git 安装
```bash
yum install -y git
```
### git 参数配置
```bash
# 配置全局参数
## 配置用户名
git config --global http.postBuffer 1048576000
git config --global user.name ""
git config --global user.email ""
# 配置仓库参数
## 配置用户名
git config --local user.name ""
git config --lobal user.email ""

```
### git用法
#### 创建版本库
```shell
# 创建版本库
mkdir $HOME/git && cd $HOME/git
git init 
# 添加文件
touch README.md
echo "README" >> README.md
git add README.md
git commit -m "add  README"
```
#### 版本回退
```shell
# 查看版本日志
git log --pretty=oneline
# 回退到上一个版本
git reset --hard HEAD^
# 查看commit id
git reflog
# 回退到指定的版本
git reset --hard commitID
```
#### 创建分支
```shell
# 创建分支
git checkout -b dev
git add readme.txt
git commit -m "add merge"
# 切换到master 分支
git checkout master
# 合并dev分支
git merge --no-ff -m "merge with no-ff" dev
```
#### 临时切换分支
```shell
# 将当前分支存储
git stash
# 在dev分支上创建分支
git checkout dev
git checkout -b issue-01
# 合并分支
git checkout dev
git merge --no-ff -m "merged bug fix 101" issue-101
# 删除分支
git branch -d issue-01
# 切换到dev分支
git checkout dev
git status
# 恢复到指定的地方
git stash list
git stash apply stash@{0}
```
#### 关联远程仓库
```shell
# 关联仓库
git remote add origin git@github.com:michaelliao/learngit.git
git push -u orgin master
# 远程创建分支关联
git push --set-upstream origin dev
# 本地创建分支关联远程
git checkout --track origin/dev
# 推动分支
git push origin master
git push origin dev
```
#### git 输出信息
```bash
# 获取commit
git rev-parse --short HEAD
# 输出信息
git log --pretty=format:“%an” b29b8b608b4d00f85b5d08663120b286ea657b4a -1
git log --pretty=format:"%b" 
# 获取commit 多个
git log --reverse --oneline


其中--pretty=format:“%xx”可以指定需要的信息，其常用的选项有：
%H 提交对象（commit）的完整哈希字串 
%h 提交对象的简短哈希字串 
%T 树对象（tree）的完整哈希字串 
%t 树对象的简短哈希字串 
%P 父对象（parent）的完整哈希字串 
%p 父对象的简短哈希字串 
%an 作者（author）的名字 
%ae 作者的电子邮件地址 
%ad 作者修订日期（可以用 -date= 选项定制格式） 
%ar 作者修订日期，按多久以前的方式显示 
%cn 提交者(committer)的名字 
%ce 提交者的电子邮件地址 
%cd 提交日期 
%cr 提交日期，按多久以前的方式显示 
%s 提交说明

附更多选项
%H: commit hash
%h: 缩短的commit hash
%T: tree hash
%t: 缩短的 tree hash
%P: parent hashes
%p: 缩短的 parent hashes
%an: 作者名字
%aN: mailmap的作者名字 (.mailmap对应，详情参照git-shortlog(1)或者git-blame(1))
%ae: 作者邮箱
%aE: 作者邮箱 (.mailmap对应，详情参照git-shortlog(1)或者git-blame(1))
%ad: 日期 (--date= 制定的格式)
%aD: 日期, RFC2822格式
%ar: 日期, 相对格式(1 day ago)
%at: 日期, UNIX timestamp
%ai: 日期, ISO 8601 格式
%cn: 提交者名字
%cN: 提交者名字 (.mailmap对应，详情参照git-shortlog(1)或者git-blame(1))
%ce: 提交者 email
%cE: 提交者 email (.mailmap对应，详情参照git-shortlog(1)或者git-blame(1))
%cd: 提交日期 (--date= 制定的格式)
%cD: 提交日期, RFC2822格式
%cr: 提交日期, 相对格式(1 day ago)
%ct: 提交日期, UNIX timestamp
%ci: 提交日期, ISO 8601 格式
%d: ref名称
%e: encoding
%s: commit信息标题
%f: sanitized subject line, suitable for a filename
%b: commit信息内容
%N: commit notes
%gD: reflog selector, e.g., refs/stash@{1}
%gd: shortened reflog selector, e.g., stash@{1}
%gs: reflog subject
%Cred: 切换到红色
%Cgreen: 切换到绿色
%Cblue: 切换到蓝色
%Creset: 重设颜色
%C(...): 制定颜色, as described in color.branch.* config option
%m: left, right or boundary mark
%n: 换行
%%: a raw %
%x00: print a byte from a hex code
%w([[,[,]]]): switch line wrapping, like the -w option of git-shortlog(1).
```

