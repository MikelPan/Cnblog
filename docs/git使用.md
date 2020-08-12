### git 介绍
#### git 安装
```bash
yum install -y git
```
#### git　参数配置
```bash
git config --global http.postBuffer 1048576000
```
#### git 用法
##### 创建版本库
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
##### 版本回退
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
##### 创建分支
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
##### 临时切换分支
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
##### 关联远程仓库
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
