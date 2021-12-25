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
        y_axis=[0, 253.45, 459.40, 1134.22, 1925.14, 4004.38, 5258.48],
        areastyle_opts=opts.AreaStyleOpts(opacity=0.5),
        label_opts=opts.LabelOpts(is_show=True),
    )
    .add_yaxis(
        series_name="请求总量",
        # stack="总量",
        y_axis=[0, 152077, 275657, 680722, 1155177, 2403039, 3157178],
        areastyle_opts=opts.AreaStyleOpts(opacity=0.5),
        label_opts=opts.LabelOpts(is_show=True),
    )
    .add_yaxis(
        series_name="TPS",
        # stack="总量",
        y_axis=[0, 253.45, 459.40, 1134.22, 1925.14, 4004.38, 5258.48],
        areastyle_opts=opts.AreaStyleOpts(opacity=0.5),
        label_opts=opts.LabelOpts(is_show=True),
    )
    .add_yaxis(
        series_name="事物总量",
        # stack="总量",
        y_axis=[0, 152077, 275657, 680722, 1155177, 2403039, 3157178],
        areastyle_opts=opts.AreaStyleOpts(opacity=0.5),
        label_opts=opts.LabelOpts(is_show=True),
    )
    .set_global_opts(
        title_opts=opts.TitleOpts(title="oltp_update_index-主键更新"),
        tooltip_opts=opts.TooltipOpts(trigger="axis", axis_pointer_type="cross"),
        yaxis_opts=opts.AxisOpts(
            type_="value",
            axistick_opts=opts.AxisTickOpts(is_show=False),
            splitline_opts=opts.SplitLineOpts(is_show=False),
        ),
        xaxis_opts=opts.AxisOpts(type_="category", boundary_gap=False),
    )
    .render("oltp_update_index.html")
)