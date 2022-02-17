### perf数据采集
```bash
yum install -y perf
```
### 用 perf 生成火焰图
#### 安装
```bash
git clone https://github.com/brendangregg/FlameGraph
```
#### perf采集数据
```bash
# 采集数据
perf record -F 99 -p 4480 -g -- sleep 30
perf record -e cpu-clock -p 4480 -g -- sleep 30
# -g 额外记录函数调用关系
# -e cpu-clock 监控的指标为cpu周期
# -p 需要记录的进程ID
# -F 99表示每秒99次采样
# -- sleep 30 持续30秒
# 查看报告
perf report -i perf.data
# 折叠
perf script -i perf.data &> perf.unfold
# 生产火焰图
stackcollapse-perf.pl perf.unfold &> perf.folded
# 生成svg图
./flamegraph.pl perf.folded > perf.svg
```
#### 生成java
```bash
# 安装jmap
git clone https://github.com/jvm-profiling-tools/perf-map-agent.git
cd perf-map-agent
cmake .
make
```


