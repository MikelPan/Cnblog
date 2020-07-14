## 包管理
管理包和依赖的工具。

- pip：Python 包和依赖关系管理工具。
- pip-tools：保证 Python 包依赖关系更新的一组工具。
- pipenv：Python 官方推荐的新一代包管理工具。
- poetry: 可完全取代 setup.py 的包管理工具。
- conda：跨平台，Python 二进制包管理工具。
- Curdling：管理 Python 包的命令行工具。
- wheel：Python 分发的新标准，意在取代 eggs。

## 分发
打包为可执行文件以便分发。

- PyInstaller：将 Python 程序转换成独立的执行文件（跨平台）。
- cx_Freeze：将python程序转换为带有一个动态链接库的可执行文件。
- dh-virtualenv：构建并将 virtualenv 虚拟环境作为一个 Debian 包来发布。
- Nuitka：将脚本、模块、包编译成可执行文件或扩展模块。
- py2app：将 Python 脚本变为独立软件包（Mac OS X）。
- py2exe：将 Python 脚本变为独立软件包（Windows）。
- pynsist：一个用来创建 Windows 安装程序的工具，可以在安装程序中打包 Python 本身。

## 配置
用来保存和解析配置的库。

- config：logging 模块作者写的分级配置模块。
- ConfigObj：INI 文件解析器，带验证功能。
- ConfigParser：(Python 标准库) INI 文件解析器。
- profig：通过多种格式进行配置，具有数值转换功能。
- python-decouple：将设置和代码完全隔离。


## 文件

- aiofiles：基于 asyncio，提供文件异步操作
- imghdr：（Python 标准库）检测图片类型
- mimetypes：（Python 标准库）将文件名映射为 MIME 类型
- path.py：对 os.path 进行封装的模块
- pathlib：（Python3.4+ 标准库）跨平台的、面向对象的路径操作库
- python-magic：文件类型检测的第三方库 libmagic 的 Python 接口
- Unipath：用面向对象的方式操作文件和目录
- watchdog：管理文件系统事件的 API 和 shell 工具

## 日期和时间
操作日期和时间的类库。

- arrow：更好的 Python 日期时间操作类库。
- Chronyk：Python 3 的类库，用于解析手写格式的时间和日期。
- dateutil：Python datetime 模块的扩展。
- delorean：解决 Python 中有关日期处理的棘手问题的库。
- maya：人性化的时间处理库。
- moment：一个用来处理时间和日期的 Python 库。灵感来自于 Moment.js。
- pendulum：一个比 arrow 更具有明确的，可预测的行为的时间操作库。
- PyTime：一个简单易用的 Python 模块，用于通过字符串来操作日期/时间。
- pytz：现代以及历史版本的世界时区定义。将时区数据库引入 Python。
- when.py：提供用户友好的函数来帮助用户进行常用的日期和时间操作。

## 文本处理

用于解析和操作文本的库。

通用

chardet：字符编码检测器，兼容 Python2 和 Python3。

difflib：(Python 标准库)帮助我们进行差异化比较。

ftfy：让 Unicode 文本更完整更连贯。

fuzzywuzzy：模糊字符串匹配。

Levenshtein：快速计算编辑距离以及字符串的相似度。

pangu.py：在中日韩语字符和数字字母之间添加空格。

pypinyin：汉字拼音转换工具 Python 版。

shortuuid：一个生成器库，用以生成简洁的，明白的，URL 安全的 UUID。

simplejson：Python 的 JSON 编码、解码器。

unidecode：Unicode 文本的 ASCII 转换形式 。

uniout：打印可读的字符，而不是转义的字符串。

xpinyin：一个用于把汉字转换为拼音的库。

yfiglet-figlet：pyfiglet -figlet 的 Python 实现。

flashtext: 一个高效的文本查找替换库。

Slug 化

awesome-slugify：一个 Python slug 化库，可以保持 Unicode。

python-slugify：Python slug 化库，可以把 unicode 转化为 ASCII。

unicode-slugify：一个 slug 工具，可以生成 unicode slugs ,需要依赖 Django 。

解析器

phonenumbers：解析，格式化，储存，验证电话号码。

PLY：lex 和 yacc 解析工具的 Python 实现。

Pygments：通用语法高亮工具。

pyparsing：生成通用解析器的框架。

python-nameparser：把一个人名分解为几个独立的部分。

python-user-agents：浏览器 user agent 解析器。

sqlparse：一个无验证的 SQL 解析器。

办公文本格式处理

通用

tablib：一个用来处理中表格数据的模块。

Office

Marmir：把输入的 Python 数据结构转换为电子表单。

openpyxl：一个用来读写 Excel 2010 xlsx/xlsm/xltx/xltm 文件的库。

pyexcel：一个提供统一 API，用来读写，操作 Excel 文件的库。

python-docx：读取，查询以及修改 Microsoft Word 2007/2008 docx 文件。

relatorio：模板化 OpenDocument 文件。

unoconv：在 LibreOffice/OpenOffice 支持的任意文件格式之间进行转换。

XlsxWriter：一个用于创建 Excel .xlsx 文件的 Python 模块。

xlwings：一个使得在 Excel 中方便调用 Python 的库（反之亦然），基于 BSD 协议。

xlwt：读写 Excel 文件的数据和格式信息。

PDF

PDFMiner：一个用于从 PDF 文档中抽取信息的工具。

PyPDF2：一个可以分割，合并和转换 PDF 页面的库。

ReportLab：快速创建富文本 PDF 文档。

Markdown

Mistune：快速并且功能齐全的纯 Python 实现的 Markdown 解析器。

Python-Markdown：John Gruber’s Markdown 的 Python 版实现。

Python-Markdown2：纯 Python 实现的 Markdown 解析器，比 Python-Markdown 更快，更准确

YAML

PyYAML：Python 版本的 YAML 解析器。

CSV

csvkit：用于转换和操作 CSV 的工具。

配置
用来保存和解析配置的库。

config：logging 模块作者写的分级配置模块。

ConfigObj：INI 文件解析器，带验证功能。

ConfigParser：(Python 标准库) INI 文件解析器。

profig：通过多种格式进行配置，具有数值转换功能。

python-decouple：将设置和代码完全隔离。

命令行工具
用于创建命令行程序的库。

命令行程序开发

asciimatics：跨平台，全屏终端包（即鼠标/键盘输入和彩色，定位文本输出），完整的复杂动画和特殊效果的高级 API。

cement：Python 的命令行程序框架。

click：一个通过组合的方式来创建精美命令行界面的包。

cliff：一个用于创建命令行程序的框架，可以创建具有多层命令的命令行程序。

clint：Python 命令行程序工具。

colorama：跨平台彩色终端文本。

docopt：Python 风格的命令行参数解析器。

Gooey：一条命令，将命令行程序变成一个 GUI 程序。

python-prompt-toolkit：一个用于构建强大的交互式命令行程序的库。

python-fire：Google 出品的一个基于 Python 类的构建命令行界面的库。

Pythonpy：在命令行中直接执行任何 Python 指令。

生产力工具

aws-cli：Amazon Web Services 的通用命令行界面。

bashplotlib：在终端中进行基本绘图。

caniusepython3：判断是哪个项目妨碍你你移植到 Python3。

cookiecutter：从 cookiecutters（项目模板）创建项目的一个命令行工具。

doitlive：一个用来在终端中进行现场演示的工具。

pyftpdlib：一个速度极快和可扩展的 Python FTP 服务库。

howdoi：通过命令行获取即时的编程问题解答。

httpie：一个命令行 HTTP 客户端，cURL 的替代品，易用性更好。

PathPicker：从 bash 输出中选出文件。

percol：向 UNIX shell 传统管道概念中加入交互式选择功能。

SAWS：一个加强版的 AWS 命令行。

thefuck：修正你之前的命令行指令。

mycli：一个 MySQL 命令行客户端，具有自动补全和语法高亮功能。

pgcli：Postgres 命令行工具，具有自动补全和语法高亮功能。

try：一个从来没有更简单的命令行工具，用来试用 python 库。


数据库
Python 实现的数据库。

pickleDB：一个简单，轻量级键值储存数据库。

PipelineDB：流式 SQL 数据库。

TinyDB：一个微型的，面向文档型数据库。

ZODB：一个 Python 原生对象数据库。一个键值和对象图数据库。

数据库驱动
用来连接和操作数据库的库。

MySQL：awesome-mysql 系列

aiomysql：基于 asyncio 的异步 MySQL 数据库操作库。

mysql-python：Python 的 MySQL 数据库连接器。

ysqlclient：mysql-python 分支，支持 Python 3。

oursql：一个更好的 MySQL 连接器，支持原生预编译指令和 BLOBs。

PyMySQL：纯 Python MySQL 驱动，兼容 mysql-python。

PostgreSQL

psycopg2：Python 中最流行的 PostgreSQL 适配器。

queries：psycopg2 库的封装，用来和 PostgreSQL 进行交互。

txpostgres：基于 Twisted 的异步 PostgreSQL 驱动。

其他关系型数据库

apsw：另一个 Python SQLite 封装。

dataset：在数据库中存储 Python 字典

pymssql：一个简单的 Microsoft SQL Server 数据库接口。

NoSQL 数据库

asyncio-redis：基于 asyncio 的 redis 客户端 (PEP 3156)。

cassandra-python-driver：Cassandra 的 Python 驱动。

HappyBase：一个为 Apache HBase 设计的，对开发者友好的库。

Plyvel：一个快速且功能丰富的 LevelDB 的 Python 接口。

py2neo：Neo4j restful 接口的 Python 封装客户端。

pycassa：Cassandra 的 Python Thrift 驱动。

PyMongo：MongoDB 的官方 Python 客户端。

redis-py：Redis 的 Python 客户端。

telephus：基于 Twisted 的 Cassandra 客户端。

txRedis：基于 Twisted 的 Redis 客户端。



网络
用于网络编程的库。

asyncio：(Python 标准库) 异步 I/O, 事件循环, 协程以及任务。

Twisted：一个事件驱动的网络引擎。

pulsar：事件驱动的并发框架。

diesel：基于 Greenlet 的事件 I/O 框架。

pyzmq：一个 ZeroMQ 消息库的 Python 封装。

Toapi：一个轻巧，简单，快速的 Flask 库，致力于为所有网站提供 API 服务。

txZMQ：基于 Twisted 的 ZeroMQ 消息库的 Python 封装。

HTTP
使用 HTTP 的库。

aiohttp：基于 asyncio 的异步 HTTP 网络库。

requests：人性化的 HTTP 请求库。

grequests：requests 库 + gevent ，用于异步 HTTP 请求.

httplib2：全面的 HTTP 客户端库。

treq：类似 requests 的 Python API 构建于 Twisted HTTP 客户端之上。

urllib3：一个具有线程安全连接池，支持文件 post，清晰友好的 HTTP 库。

WebSocket
帮助使用 WebSocket 的库。

AutobahnPython：给 Python 、使用的 WebSocket & WAMP 基于 Twisted 和 asyncio。

Crossbar：开源统一应用路由(Websocket & WAMP for Python on Autobahn)。

django-socketio：给 Django 用的 WebSockets。

WebSocket-for-Python：为 Python2/3 以及 PyPy 编写的 WebSocket 客户端和服务器库。

## WSGI 服务器

兼容 WSGI 的 web 服务器

- gunicorn：Pre-forked, 部分是由 C 语言编写的。
- uwsgi：uwsgi 项目的目的是开发一组全栈工具，用来建立托管服务， 由 C 语言编写。
- bjoern：异步，非常快速，由 C 语言编写。
- fapws3：异步 (仅对于网络端)，由 C 语言编写。
- meinheld：异步，部分是由 C 语言编写的。
- netius：异步，非常快速。
- paste：多线程，稳定，久经考验。
- rocket：多线程。
- waitress：多线程, 是它驱动着 Pyramid 框架。
- Werkzeug：一个 WSGI 工具库，驱动着 Flask ，而且可以很方便大嵌入到你的项目中去。

## Web 框架
全栈 Web 框架。

- Django：Python 界最流行的 web 框架。
- Flask：一个 Python 微型框架。
- pyramid：一个小巧，快速，接地气的开源 Python web 框架。
- Bottle：一个快速小巧，轻量级的 WSGI 微型 web 框架。
- CherryPy：一个极简的 Python web 框架，服从 HTTP/1.1 协议且具有 WSGI 线程池。
- TurboGears：一个可以扩展为全栈解决方案的微型框架。
- Tornado：一个 web 框架和异步网络库。
- sanic：基于 Python3.5+ 的异步网络框架。
- starlette: 一款轻量级，高性能的 ASGI 框架

## 电子商务
用于电子商务以及支付的框架和库。

- django-oscar：一个用于 Django 的开源的电子商务框架。
- django-shop：一个基于 Django 的店铺系统。
- Cartridge：一个基于 Mezzanine 构建的购物车应用。
- shoop：一个基于 Django 的开源电子商务平台。
- alipay：非官方的 Python 支付宝 API。
- merchant：一个可以接收来自多种支付平台支付的 Django 应用。
- money：一个货币类库。带有可选的 CLDR 后端本地化格式，提供可扩展的货币兑换解决方案。
- python-currencies：显示货币格式以及它的数值。

## RESTful API
用来开发 RESTful APIs 的库

### Django

- django-rest-framework：一个强大灵活的工具，用来构建 web API。
- django-tastypie：为 Django 应用开发 API。
- django-formapi：为 Django 的表单验证，创建 JSON APIs 。

### Flask

- flask-api：为 flask 开发的，可浏览 Web APIs 。
- flask-restful：为 flask 快速创建 REST APIs 。
- flask-restless：为 SQLAlchemy 定义的数据库模型创建 RESTful APIs 。
- flask-api-utils：为 Flask 处理 API 表示和验证。
- eve：REST API 框架，由 Flask, MongoDB 等驱动。

### Pyramid

- cornice：一个 Pyramid 的 REST 框架 。

### 与框架无关的

- falcon：一个用来建立云 API 和 web app 后端的高性能框架。
- sandman：为现存的数据库驱动系统自动创建 REST APIs 。
- restless：框架无关的 REST 框架 ，基于从 Tastypie 学到的知识。
- ripozo：快速创建 REST/HATEOAS/Hypermedia APIs。

## 模板引擎
模板生成和词法解析的库和工具。

- Jinja2：一个现代的，对设计师友好的模板引擎。
- Chameleon：一个 HTML/XML 模板引擎。模仿了 ZPT（Zope Page Templates）, 进行了速度上的优化。
- Genshi：Python 模板工具，用以生成 web 感知的结果。
- Mako：Python 平台的超高速轻量级模板。

## 队列
处理事件以及任务队列的库。

- celery：一个异步任务队列/作业队列，基于分布式消息传递。
- huey：小型多线程任务队列。
- mrq：Mr. Queue -一个 Python 的分布式 worker 任务队列， 使用 Redis 和 gevent。
- rq：简单的 Python 作业队列。
- simpleq：一个简单的，可无限扩张的，基于亚马逊 SQS 的队列。

## 搜索

对数据进行索引和执行搜索查询的库和软件。

- django-haystack：Django 模块化搜索。
- elasticsearch-py：Elasticsearch 的官方底层 Python 客户端。
- elasticsearch-dsl-py：Elasticsearch 的官方高级 Python 客户端。
- solrpy：solr 的 Python 客户端。
- Whoosh：一个快速的纯 Python 搜索引擎库。

## 电子邮件
用来发送和解析电子邮件的库。

- django-celery-ses：带有 AWS SES 和 Celery 的 Django email 后端。
- envelopes：供人类使用的电子邮件库。
- flanker：一个 email 地址和 Mime 解析库。
- imbox：Python IMAP 库。
- inbox.py：Python SMTP 服务器。
- inbox：一个开源电子邮件工具箱。
- lamson：Python 风格的 SMTP 应用服务器。
- mailjet：Mailjet API 实现，用来提供批量发送邮件，统计等功能。
- marrow.mailer：高性能可扩展邮件分发框架。
- modoboa：一个邮件托管和管理平台，具有现代的、简约的 Web UI。
- pyzmail：创建，发送和解析电子邮件。
- Talon：Mailgun 库，用来抽取信息和签名。
- yagmail：yagmail是一个GMAIL / SMTP客户端，旨在使其尽可能简单地发送电子邮件。

## URL 处理
解析 URLs 的库

- furl：一个让处理 URL 更简单小型 Python 库。
- purl：一个简单的，不可变的 URL 类，具有简洁的 API 来进行询问和处理。
- pyshorteners：一个纯 Python URL 缩短库。
- shorturl：生成短小 URL 和类似 bit.ly 短链的 Python 实现。
- webargs：一个解析 HTTP 请求参数的库，内置对流行 web 框架的支持，包括 Flask, Django, Bottle, Tornado 和 Pyramid。


## 进程
操作系统进程启动及通信库。

- envoy：比 Python subprocess 模块更人性化。
- sarge：另一 种 subprocess 模块的封装。
- sh：一个完备的 subprocess 替代库。

## 并发和并行

用以进行并发和并行操作的库。

- multiprocessing：(Python 标准库) 基于进程的“线程”接口。
- threading：(Python 标准库)更高层的线程接口。
- eventlet：支持 WSGI 的异步框架。
- gevent：一个基于协程的 Python 网络库，使用 greenlet。
- Tomorrow：用于产生异步代码的神奇的装饰器语法实现。
- uvloop：在 libuv 之上超快速实现 asyncio 事件循环