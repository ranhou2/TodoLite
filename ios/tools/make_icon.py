"""生成 iOS 图标：蓝色渐变底 + 白色剪贴板与蓝色对勾徽章（与 Android 图标一致）。"""
from PIL import Image, ImageDraw
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'build', 'icons')
os.makedirs(OUT, exist_ok=True)

S = 1024
K = 2  # 超采样，缩放后边缘更干净
W = S * K
top = (90, 171, 255)     # #5AABFF
bottom = (10, 132, 255)  # #0A84FF

img = Image.new('RGB', (W, W))
draw = ImageDraw.Draw(img)
for y in range(W):
    t = y / (W - 1)
    draw.line([(0, y), (W, y)], fill=tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))


def r(value):
    return int(value * W)


white = (255, 255, 255)
line_blue = (191, 217, 250)
badge_blue = (10, 132, 255)

draw.rounded_rectangle([r(0.270), r(0.300), r(0.755), r(0.860)], radius=r(0.052), fill=white)
draw.rounded_rectangle([r(0.410), r(0.248), r(0.590), r(0.330)], radius=r(0.020), fill=white)
for cy in (0.408, 0.474, 0.540):
    draw.rounded_rectangle([r(0.335), r(cy), r(0.665), r(cy + 0.022)], radius=r(0.011), fill=line_blue)

cx, cy, rad = 0.722, 0.795, 0.100
draw.ellipse([r(cx - rad), r(cy - rad), r(cx + rad), r(cy + rad)], fill=badge_blue)


def stroke(p1, p2, width):
    draw.line([(r(p1[0]), r(p1[1])), (r(p2[0]), r(p2[1]))], fill=white, width=r(width))


stroke((0.690, 0.795), (0.715, 0.820), 0.014)
stroke((0.715, 0.820), (0.762, 0.770), 0.014)

icon = img.resize((S, S), Image.LANCZOS)
icon.save(os.path.join(OUT, 'AppIcon1024.png'))
icon.resize((60, 60), Image.LANCZOS).save(os.path.join(OUT, 'AppIcon60x60.png'))
icon.resize((120, 120), Image.LANCZOS).save(os.path.join(OUT, 'AppIcon60x60@2x.png'))
icon.resize((180, 180), Image.LANCZOS).save(os.path.join(OUT, 'AppIcon60x60@3x.png'))
print('icons generated')
