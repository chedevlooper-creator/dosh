"""1024x1024 uygulama ikonu üret — altın daire + Д harfi."""
from PIL import Image, ImageDraw, ImageFont
import os, math

SIZE = 1024
OUT = os.path.join(os.path.dirname(__file__), "icon_raw.png")

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Yumuşak gölge için offset'li koyu daire
shadow_offset = 6
draw.ellipse(
    [24 + shadow_offset, 24 + shadow_offset, SIZE - 24 + shadow_offset, SIZE - 24 + shadow_offset],
    fill=(0, 0, 0, 35),
)

# Ana altın daire (gradient taklidi: 3 katman)
cx, cy, r = SIZE // 2, SIZE // 2, SIZE // 2 - 24
gold_colors = [(0xF9, 0xC7, 0x2C), (0xF5, 0xB6, 0x2B), (0xE8, 0xA0, 0x1E)]
for i, (ri, gi, bi) in enumerate(gold_colors):
    step = 3
    cr = r - i * step
    draw.ellipse(
        [cx - cr, cy - cr, cx + cr, cy + cr],
        fill=(ri, gi, bi, 255),
    )

# Dış çerçeve (ince altın halka)
frame_r = r - 2
draw.ellipse(
    [cx - frame_r, cy - frame_r, cx + frame_r, cy + frame_r],
    outline=(0xD9, 0x96, 0x1A, 180),
    width=4,
)

# İç ince halka
inner_r = r - 18
draw.ellipse(
    [cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r],
    outline=(0xFF, 0xE0, 0x7A, 100),
    width=2,
)

# Д harfi (Cyrillic De) — el ile çizim (font bağımsız)
letter_color = (0xFF, 0xFF, 0xFF, 245)

# Dikey çizgi (sol, yaklaşık sol omurga)
lx = cx - 130
draw.rectangle([lx, cy - 220, lx + 36, cy + 180], fill=letter_color)

# Üst yatay çizgi
draw.rectangle([lx - 10, cy - 240, cx + 200, cy - 204], fill=letter_color)

# Sağ üst eğri (yaklaşık üçgen sağ tarafı) — daha iyi görünüm için polygon
curve_points = [
    (cx + 190, cy - 210),
    (cx + 200, cy - 204),
    (cx + 200, cy - 220),
    (cx + 160, cy - 260),
]
draw.polygon(curve_points, fill=letter_color)

# Sol tarafa da bir miktar yatay alt çizgi (Д'nin alt tabanı)
draw.rectangle([lx - 8, cy + 155, cx + 60, cy + 191], fill=letter_color)

# Üçgen sağ taraf (Д'nin sağ ayağı)
triangle = [
    (cx + 140, cy - 204),
    (cx + 200, cy - 204),
    (cx + 200, cy - 180),
]
draw.polygon(triangle, fill=letter_color)

img.save(OUT, "PNG")
print(f"Icon saved: {OUT} ({os.path.getsize(OUT)} bytes)")
