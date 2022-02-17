#!/usr/bin/env python3


import pyecharts.options as opts
from pyecharts.charts import Line

"""
Gallery 使用 pyecharts 1.1.0
参考地址: https://echarts.baidu.com/examples/editor.html?c=area-stack

目前无法实现的功能:

暂无
"""


x_data = ["0","8", "16", "32", "64", "128", "256"]


(
    Line()
    .add_xaxis(xaxis_data=x_data)
    .add_yaxis(
        series_name="QPS",
        # stack="总量",
        y_axis=[0, 3426.83, 5536.80, 8141.05, 10249.68, 11608.66, 12654.61],
        areastyle_opts=opts.AreaStyleOpts(opacity=0.5),
        label_opts=opts.LabelOpts(is_show=True),
    )
    .add_yaxis(
        series_name="请求总量",
        # stack="总量",
        y_axis=[0, 2056180, 3322460, 4885500, 6151820, 6966980, 7597100],
        areastyle_opts=opts.AreaStyleOpts(opacity=0.5),
        label_opts=opts.LabelOpts(is_show=True),
    )
    .add_yaxis(
        series_name="TPS",
        # stack="总量",
        y_axis=[0, 171.34, 276.84, 407.05, 512.48, 580.43, 632.73],
        areastyle_opts=opts.AreaStyleOpts(opacity=0.5),
        label_opts=opts.LabelOpts(is_show=True),
    )
    .add_yaxis(
        series_name="事物总量",
        # stack="总量",
        y_axis=[0, 102809, 166123, 244275, 307591, 348349, 379855],
        areastyle_opts=opts.AreaStyleOpts(opacity=0.5),
        label_opts=opts.LabelOpts(is_show=True),
    )
    .add_yaxis(
        series_name="读",
        # stack="总量",
        y_axis=[0, 1439326, 2325722, 3419850, 4306274, 4876886, 5317970],
        areastyle_opts=opts.AreaStyleOpts(opacity=0.5),
        label_opts=opts.LabelOpts(is_show=True),
    )
    .add_yaxis(
        series_name="写",
        # stack="总量",
        y_axis=[0, 408522, 660088, 970844, 1222527, 1384663, 1510266],
        areastyle_opts=opts.AreaStyleOpts(opacity=0.5),
        label_opts=opts.LabelOpts(is_show=True),
    )
    .set_global_opts(
        title_opts=opts.TitleOpts(title="oltp_read_write-读写混合"),
        tooltip_opts=opts.TooltipOpts(trigger="axis", axis_pointer_type="cross"),
        yaxis_opts=opts.AxisOpts(
            type_="value",
            axistick_opts=opts.AxisTickOpts(is_show=False),
            splitline_opts=opts.SplitLineOpts(is_show=False),
        ),
        xaxis_opts=opts.AxisOpts(type_="category", boundary_gap=False),
    )
    .render("oltp_read_write.html")
)