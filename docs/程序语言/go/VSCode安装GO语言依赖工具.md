### 安装go 环境
```bash
# 查看系统版本
uname -a
Linux deppen 4.15.0-30deepin-generic #31 SMP Fri Nov 30 04:29:02 UTC 2018 x86_64 GNU/Linux
# 下载64位系统
wget https://dl.google.com/go/go1.14.3.linux-amd64.tar.gz -P /usr/local/src
wget https://studygolang.com/dl/golang/go1.13.4.linux-amd64.tar.gz -P /usr/local/src
cd /usr/local/src && tar zxvf go1.13.4.linux-amd64.tar.gz
mv go /usr/local/go
# 配置环境变量
cat > /etc/profile.d/go.sh <<EOF
export PATH=$PATH:/usr/local/go/bin
export GOPATH=~/workspaces/servers/go
export GOROOT=/usr/local/go
export GO111MODULE=on
export GOPROXY=https://goproxy.cn
EOF
source /etc/profile
```

由于vscode的各种lint、补全、nav、调试都依赖go语言的其他扩展工具，如果安装不全，会给出类似提示：
```bash
The "gocode" command is not available. Use "go get -v github.com/mdempsky/gocode" to install.
```

但如果按照vscode的提示点击“安装”后，经过漫长等待，会迎来进一步提示：
```bash
gocode:
Error: Command failed: /usr/local/go/bin/go get -u -v github.com/mdempsky/gocode
github.com/mdempsky/gocode (download)
Fetching https://golang.org/x/tools/go/gcexportdata?go-get=1
https fetch failed: Get https://golang.org/x/tools/go/gcexportdata?go-get=1: dial tcp 216.239.37.1:443: i/o timeout
package golang.org/x/tools/go/gcexportdata: unrecognized import path "golang.org/x/tools/go/gcexportdata" (https fetch: Get https://golang.org/x/tools/go/gcexportdata?go-get=1: dial tcp 216.239.37.1:443: i/o timeout)
```
### 解决办法
从官方文档中可以明确，VSCode依赖的几款工具完成不同功能：

|名称 | 描述 | 链接 |
|:------ |:------|:------ |
| gocode | 代码自动补全 | https://github.com/mdempsky/gocode |
| go-outline | 在当前文件中查找 | https://github.com/ramya-rao-a/go-outline |
| go-symbols | 在项目路径下查找 | https://github.com/acroca/go-symbols |
| gopkgs | 自动补全未导入包 | https://github.com/uudashr/gopkgs |
| guru | 查询所有引用 | https://golang.org/x/tools/cmd/guru |
| gorename | 重命名符号 | https://golang.org/x/tools/cmd/gorename |
| goreturns | 格式化代码 | https://github.com/sqs/goreturns |
| godef | 跳转到声明 | https://github.com/rogpeppe/godef |
| godoc | 鼠标悬浮时文档提示 | https://golang.org/x/tools/cmd/godoc |
| golint | 就是lint | https://golang.org/x/lint/golint |
| dlv | 调试功能 | https://github.com/derekparker/delve/tree/master/cmd/dlv |
| gomodifytags | 修改结构体标签 | https://github.com/fatih/gomodifytags |
| goplay | 运行当前go文件 | https://github.com/haya14busa/goplay/ |
| impl | 新建接口 |	https://github.com/josharian/impl |
| gotype-live |	类型诊断 | https://github.com/tylerb/gotype-live |
| gotests |	单元测试 |	https://github.com/cweill/gotests/ |
| go-langserver | 语言服务 | https://github.com/sourcegraph/go-langserver |
| filstruct | 结构体成员默认值 | https://github.com/davidrjenni/reftools/tree/master/cmd/fillstruct |

以上的工具可以有选择地安装，但为了开发过程中不要出什么岔子，我一般选择全部安装，很不幸的是安装过程中80%的工具会出现timeout的提示。

### 安装步骤

为了统一每个人的开发环境，下文中GOPATH表示自己电脑go的安装路径,如果没有的话建议先执行命令go env 查看到对应的GOPATH目录

１、创建目录$GOPATH/src/golang.org/x，并切换到该目录
```bash
mkdir -p $GOPATH/src/golang.org/x/
cd $GOPATH/src/golang.org/x/
```
2、克隆golang.org工具源码
```bash
git clone https://github.com/golang/tools.git
git clone https://github.com/golang/lint.git
git clone https://github.com/golang/sys.git
git clone https://github.com/golang/net.git
```
3、下载github源码
按照go get -u -v命令，从GitHub上下载代码后还会fetch，我们很可能会在fetch https://golang.org/xxx的时候挂掉，原因你懂的。所以去掉-u选项，禁止从网络更新现有代码。
```bash
# 先从github下载依赖工具的源码，fetch提示timeout不要管
go get -v github.com/ramya-rao-a/go-outline
go get -v github.com/acroca/go-symbols
go get -v github.com/mdempsky/gocode
go get -v github.com/rogpeppe/godef
go get -v github.com/zmb3/gogetdoc
go get -v github.com/fatih/gomodifytags
go get -v sourcegraph.com/sqs/goreturns
go get -v github.com/cweill/gotests/...
go get -v github.com/josharian/impl
go get -v github.com/haya14busa/goplay/cmd/goplay
go get -v github.com/uudashr/gopkgs/cmd/gopkgs
go get -v github.com/davidrjenni/reftools/cmd/fillstruct
go get -v github.com/alecthomas/gometalinter

go get -u -v github.com/rogpeppe/godef
go get -u -v golang.org/x/lint/golint
go get -u -v github.com/lukehoban/go-find-references
go get -u -v github.com/lukehoban/go-outline
go get -u -v github.com/tpng/gopkgs
go get -u -v github.com/newhook/go-symbols
```
4、安装工具｀
```bash
go install github.com/ramya-rao-a/go-outline
go install github.com/acroca/go-symbols
go install github.com/mdempsky/gocode
go install github.com/rogpeppe/godef
go install github.com/zmb3/gogetdoc
go install github.com/fatih/gomodifytags
go install sourcegraph.com/sqs/goreturns
go install github.com/cweill/gotests/...
go install github.com/josharian/impl
go install github.com/haya14busa/goplay/cmd/goplay
go install github.com/uudashr/gopkgs/cmd/gopkgs
go install github.com/davidrjenni/reftools/cmd/fillstruct
go install github.com/alecthomas/gometalinter
$GOPATH/bin/gometalinter --install
go install golang.org/x/tools/cmd/godoc
go install golang.org/x/lint/golint
go install golang.org/x/tools/cmd/gorename
go install golang.org/x/tools/cmd/goimports
go install golang.org/x/tools/cmd/guru
```
### vscode 配置插件
`在 Preferences -> Setting 然后输入 go，然后选择 setting.json，填入你想要修改的配置`
- 自动完成未导入的包
```bash
  "go.autocompleteUnimportedPackages": true,
```
- 如果你遇到使用标准包可以出现代码提示，但是使用自己的包或者第三方库无法出现代码提示，你可以查看一下你的配置项
```bash
 "go.inferGopath": true,
```
- 如果引用的包使用了 ( . “aa.com/text”) 那这个text包下的函数也无法跳转进去，这是为什么？

修改 "go.docsTool" 为 gogetdoc，默认是 godoc
```bash
  "go.docsTool": "gogetdoc",
```
参考 settings.json
```bash
{
  "go.goroot": "",
  "go.gopath": "",
  "go.inferGopath": true,
  "go.autocompleteUnimportedPackages": true,
  "go.gocodePackageLookupMode": "go",
  "go.gotoSymbol.includeImports": true,
  "go.useCodeSnippetsOnFunctionSuggest": true,
  "go.useCodeSnippetsOnFunctionSuggestWithoutType": true,
  "go.docsTool": "gogetdoc",
  "files.autoSave": "onFocusChange",
}
```

### 示例

进入到$GOPATH/src下,创建mian.go
```go
package main

import "fmt"

func main() {
    fmt.Println("Hello,world")
}
```

运行go run main.go, 输出如下：
```bash
Hello,world
```
