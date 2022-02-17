## VsCode搭建Java开发环境（Spring Boot项目创建、运行、调试）
### 安装扩展

安装如下两个主要扩展即可，这两个扩展已关联java项目开发主要使用的maven、springboot等所需要的扩展

![](https://img2018.cnblogs.com/blog/949088/201810/949088-20181018140701454-853945200.png)

开始步骤：

- 在 Visual Studio Code 中打开扩展视图(Ctrl+Shift+X)。
输入“java”搜索商店扩展插件。
- 找到并安装 Java Extension Pack (Java 扩展包)，如果你已经安装了 Language Support for Java(TM) by Red Hat，也可以单独找到并安装 Java Debugger for Visual Studio Code 扩展。
- 输入“Spring Boot Extension”搜索商店扩展插件。
- 找到并安装 “Spring Boot Extension Pack”。安装过程中可能会比较慢，耐心等待即可。

配置Maven：

点左下角的设置图标->设置，打开设置内容筛选框，输入maven，然后点击右侧的打开json格式setting：
![](https://img2018.cnblogs.com/blog/949088/201810/949088-20181018142037876-936312706.png)

然后把maven的可执行文件路径配置、maven的setting路径配置、java.home的路径配置，拷贝到右侧的用户设置区域并且设置为自己电脑的实际路径

![](https://img2018.cnblogs.com/blog/949088/201810/949088-20181018142807301-1282887727.png)

设置内容如下：
```json
{
    "workbench.iconTheme": "vscode-icons",
    "workbench.startupEditor": "newUntitledFile",
    "java.errors.incompleteClasspath.severity": "ignore",
    "workbench.colorTheme": "Atom One Dark",
    "java.home":"D:\\software\\Java\\jdk1.8.0_60",
    "java.configuration.maven.userSettings": "D:\\software\\apache-maven-3.3.3-bin\\apache-maven-3.3.3\\conf\\settings.xml",
    "maven.executable.path": "D:\\software\\apache-maven-3.3.3-bin\\apache-maven-3.3.3\\bin\\mvn.cmd",
    "maven.terminal.useJavaHome": true,
    "maven.terminal.customEnv": [
        {
            "environmentVariable": "JAVA_HOME",
            "value": "D:\\software\\Java\\jdk1.8.0_60"
        }
    ],
}
```
如果你的mvn更新包速度很慢，建议使用阿里云的镜像速度会快点（修改maven的setting配置如下）：
```xml
 <!-- 阿里云仓库 -->
        <mirror>
            <id>alimaven</id>
            <mirrorOf>central</mirrorOf>
            <name>aliyun maven</name>
            <url>http://maven.aliyun.com/nexus/content/repositories/central/</url>
        </mirror>
        <mirror>
            <id>nexus-aliyun</id>
            <mirrorOf>*</mirrorOf>
            <name>Nexus aliyun</name>
            <url>http://maven.aliyun.com/nexus/content/groups/public</url>
        </mirror>
        <!-- 中央仓库1 -->
        <mirror>
            <id>repo1</id>
            <mirrorOf>central</mirrorOf>
            <name>Human Readable Name for this Mirror.</name>
            <url>http://repo1.maven.org/maven2/</url>
        </mirror>
    
        <!-- 中央仓库2 -->
        <mirror>
            <id>repo2</id>
            <mirrorOf>central</mirrorOf>
            <name>Human Readable Name for this Mirror.</name>
            <url>http://repo2.maven.org/maven2/</url>
        </mirror>
```
配置完成重启 VSCode。
### 创建Spring Boot项目
使用快捷键(Ctrl+Shift+P)命令窗口，输入 Spring 选择创建 Maven 项目。 效果如下：
![](https://img2018.cnblogs.com/blog/949088/201810/949088-20181019110527579-986789609.png)

选择需要使用的语言、Group Id、项目名称等，这里选择Java：
![](https://img2018.cnblogs.com/blog/949088/201810/949088-20181019110754155-40455743.png)

![](https://img2018.cnblogs.com/blog/949088/201810/949088-20181019110856222-1209305730.png)

![](https://img2018.cnblogs.com/blog/949088/201810/949088-20181019111002777-1987557021.png)

选择Spring Boot版本：
![](https://img2018.cnblogs.com/blog/949088/201810/949088-20181019111039119-440533955.png)

选择需要引入的包，引入如下几个包即可满足web开发：

DevTools（代码修改热更新，无需重启）、Web（集成tomcat、SpringMVC）、Lombok（智能生成setter、getter、toString等接口，无需手动生成，代码更简介）、Thymeleaf （模板引擎）。

选择好要引入的包后直接回车，在新弹出的窗口中选择项目路径，至此Spring Boot项目创建完成。

![](https://img2018.cnblogs.com/blog/949088/201810/949088-20181019111826340-254130709.png)

创建好后vscode右下角会有如下提示，点击Open it 即可打开刚才创建的Spring Boot项目。
![](https://img2018.cnblogs.com/blog/949088/201810/949088-20181019112116653-410014195.png)

### 项目运行跟调试
项目创建后会自动创建DemoApplication.java文件，在DemoApplication 文件目录下新建文件夹 Controller，新建文件HomeController.java。效果如下：
![](https://img2018.cnblogs.com/blog/949088/201810/949088-20181019133810848-1910514658.png)

Ps:SpringBoot项目的Bean装配默认规则是根据DemoApplication类所在的包位置从上往下扫描。所以必须放在同一目录下否则会无法访问报如下所示错误：
![](https://img2018.cnblogs.com/blog/949088/201810/949088-20181018171327250-1855055392.png)

启动工程之前还需要配置下运行环境，如下图，点左边的小虫子图标，然后点上面的下拉箭头，选择添加配置，第一次设置时VS Code会提示选择需要运行的语言环境，选择对应环境后自动创建 launch.json 文件。
![](https://img2018.cnblogs.com/blog/949088/201810/949088-20181018170430790-1469607250.png)

launch.json 调试配置文件如下，默认不修改配置也可使用：
![](https://img2018.cnblogs.com/blog/949088/201810/949088-20181018170816359-2101824580.png)

选择对应的配置环境调式项目如下，默认端口为8080。
![](https://img2018.cnblogs.com/blog/949088/201810/949088-20181018170940292-676370504.png)

启动后可在控制台输出面板查看启动信息，显示如下后，访问：http://localhost:8080即可。
![](https://img2018.cnblogs.com/blog/949088/201810/949088-20181018171203180-856160012.png)

最终效果如下：
![](https://img2018.cnblogs.com/blog/949088/201810/949088-20181019135017904-1365099465.png)

### 访问HTML页面
在spring boot 中访问html需要引入Thymeleaf （模板引擎）包，在创建项目时已引用该包这里不需在重复引用。在resources-->templates目录下创建Index.html文件，效果如下：
![](https://img2018.cnblogs.com/blog/949088/201810/949088-20181019135536794-1609170362.png)

html内容：
```html
<!DOCTYPE html>
<html lang="en" xmlns:th="http://www.w3.org/1999/xhtml">
<head>
    <meta charset="UTF-8"/>
    <title>第一个HTML页面</title>
</head>
<body>
<h1>Hello Spring Boot!!!</h1>
<p th:text="${hello}"></p>
</body>
</html>
```
在controller目录下新建TestController.java文件，代码如下：
```bash
@Controller
public class TestController {

    /**
     * 本地访问内容地址 ：http://localhost:8080/hello
     * @param map
     * @return
     */
    @RequestMapping("/hello")
    public String helloHtml(HashMap<String, Object> map) {
        map.put("hello", "欢迎进入HTML页面");
        return "/index";
    }
}
```

Ps:如果要访问html页面注解必须为Controller不能为RestController。否则无法访问。

RestController和Controller的区别：

@RestController is a stereotype annotation that combines @ResponseBody and @Controller.
意思是：
@RestController注解相当于@ResponseBody ＋ @Controller合在一起的作用。
1)如果只是使用@RestController注解Controller，则Controller中的方法无法返回jsp页面，配置的视图解析器InternalResourceViewResolver不起作用，返回的内容就是Return 里的内容。

例如：本来应该到success.html页面的，则其显示success.

2)如果需要返回到指定页面，则需要用 @Controller配合视图解析器InternalResourceViewResolver才行。

3)如果需要返回json或者xml或者自定义mediaType内容到页面，则需要在对应的方法上加上@ResponseBody注解

效果展示如下：
![](https://img2018.cnblogs.com/blog/949088/201810/949088-20181019140657585-1350811104.png)