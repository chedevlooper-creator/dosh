"""Windows app_icon.ico üret (256×256 PNG + 32×32 PNG içinde)."""
from PIL import Image
import os

SRC = os.path.join(os.path.dirname(__file__), "icon_raw.png")
ICO = os.path.join(os.path.dirname(__file__), "..", "..", "windows", "runner", "resources", "app_icon.ico")

img = Image.open(SRC)
img_256 = img.resize((256, 256), Image.LANCZOS)
img_32 = img.resize((32, 32), Image.LANCZOS)

img_256.save(ICO, format="ICO", sizes=[(256, 256), (32, 32)])
print(f"ICO saved: {ICO}")
