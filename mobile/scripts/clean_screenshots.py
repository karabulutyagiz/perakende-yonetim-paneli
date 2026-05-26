"""Apple App Store reddi 2.3.10 için: Android status bar + nav butonlarını
mevcut iPhone screenshot'larından temizle.

01-products + 02-cart Android emülatörden alınmış; üstte Android status bar
(saat/sinyal/wifi/pil) + altta nav butonları (üçgen/daire/kare) var. Apple
"non-iOS status bar / menu bar" diyerek reddetti.

Bu script üst N pixel + alt M pixel'i kırpar, sonra canvas'ı orijinal boyuta
beyaz/uyumlu renkle extend eder. App içeriği bozulmaz.
03-04 zaten Apple iPhone frame içinde tasarlanmış — onlara dokunulmaz.
"""
from pathlib import Path
from PIL import Image

SRC = Path("mobile/ios/fastlane/screenshots/tr")
OUT = Path("mobile/ios/fastlane/screenshots/tr")  # in-place overwrite

# Android default: status bar ~96px, nav bar ~144px on a 1290x2796 canvas.
# Biraz cömert kes ki ucu kaçmasın.
TOP_CROP = 110
BOTTOM_CROP = 150
TARGET_W, TARGET_H = 1290, 2796


def clean(name: str) -> None:
    src = SRC / name
    if not src.exists():
        print(f"skip {name} (yok)")
        return
    img = Image.open(src).convert("RGB")
    w, h = img.size
    # Üst + alt kırp
    cropped = img.crop((0, TOP_CROP, w, h - BOTTOM_CROP))
    ch, cw = cropped.size[1], cropped.size[0]

    # Yeni temiz canvas: üstteki en üst pixel satırı rengiyle (app header rengi),
    # altta alt satır rengiyle doldur. Apple beyaz da kabul eder ama header
    # rengiyle doldurmak daha doğal görünür.
    top_color = cropped.getpixel((cw // 2, 0))
    bottom_color = cropped.getpixel((cw // 2, ch - 1))

    canvas = Image.new("RGB", (TARGET_W, TARGET_H), top_color)
    # Resize cropped'ı genişlikte 1290 olacak şekilde ölçekle
    new_w = TARGET_W
    new_h = int(ch * (new_w / cw))
    resized = cropped.resize((new_w, new_h), Image.LANCZOS)

    # Top color üstte, bottom color altta — ekran ortasına yapıştır
    y_offset = (TARGET_H - new_h) // 2
    # Üst banner için: üst kısmı top_color, alt kısmı bottom_color
    # Basit: tek renk canvas ile başla, alta bottom_color şerit ekle
    if bottom_color != top_color:
        # Alt yarıyı bottom_color ile doldur
        for y in range(y_offset + new_h, TARGET_H):
            for x in range(0, TARGET_W, 1290):  # tek satır
                pass
        # Daha verimli: PIL.ImageDraw ile rectangle
        from PIL import ImageDraw
        draw = ImageDraw.Draw(canvas)
        draw.rectangle((0, y_offset + new_h, TARGET_W, TARGET_H), fill=bottom_color)

    canvas.paste(resized, (0, y_offset))

    canvas.save(src, optimize=True)
    print(f"✅ {name}: {w}x{h} → temiz {TARGET_W}x{TARGET_H} (üstten {TOP_CROP}, alttan {BOTTOM_CROP} kırpıldı)")


if __name__ == "__main__":
    clean("01-products.png")
    clean("02-cart.png")
    # 03 ve 04 zaten Apple iPhone frame içinde marketing tasarımı — dokunulmaz.
    print("\n03-invoice ve 04-reports zaten Apple iPhone frame içinde — değiştirilmedi.")
