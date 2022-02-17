#!/usr/bin/env python3

from MyQR import myqr
import zxing


reader=zxing.BarCodeReader()
code=reader.decode('/Users/admin/Downloads/WechatIMG10.jpeg')
print(code.parsed)

# 普通二维码
# qr.add_data(open('pic.img', 'r').read())
myqr.run(
    words=str(code.parsed),
    version=5,
    level='H',
    contrast=2.5,     # 调整底图的亮度越大越亮
    brightness=2.0,
#     words='D:/Pictures/2.gif',
    picture='/Users/admin/Downloads/my.png',    # 风格图片
    colorized=True,
    save_name='myr.png',
    save_dir='/Users/admin/Downloads'
)