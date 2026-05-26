"""Apple App Store screenshot'larını gerçek iPhone screenshot'larından
ParaSende brand'li iPhone mockup PNG'lere dönüştürür.

Input:  ~/Desktop/perakende ss/{6,5,2,3}.jpeg (gerçek iOS native screenshot)
Output: mobile/ios/fastlane/screenshots/tr/0{1..4}-*.png (1290x2796, iPhone 6.7")

Apple guideline 2.3.10 reddi sonrası — non-iOS status bar / nav bar yok artık,
sadece gerçek iOS UI + minimal mockup frame.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HOME = Path.home()
SRC = HOME / "Desktop" / "perakende ss"
OUT = Path(__file__).resolve().parent.parent / "ios" / "fastlane" / "screenshots" / "tr"
OUT.mkdir(parents=True, exist_ok=True)

# Apple iPhone 6.7" canvas
W, H = 1290, 2796
# Brand renkleri
BG_TOP = (236, 246, 240)      # çok açık yeşil
BG_BOT = (208, 233, 220)      # biraz daha doygun
TEXT_COLOR = (14, 110, 78)    # ParaSende green
BEZEL_COLOR = (20, 20, 25)    # iPhone siyah bezel
CARD_BG = (255, 255, 255)

# Mockup düzeni
TOP_TITLE_AREA_H = 380         # üstte başlık için yer
SHOT_PAD = 60                  # screenshot ile canvas kenarları
BEZEL_THICKNESS = 14           # iPhone bezel kalınlığı
CORNER_RADIUS = 70             # screenshot ve bezel köşe yuvarlama

# (src filename, başlık, alt başlık)
SHOTS = [
    ("6.jpeg",  "Tüm ürünleriniz",   "tek ekranda yönetilebilir"),
    ("5.jpeg",  "Gelen siparişler",  "anında bildirim, hızlı işlem"),
    ("2.png.jpeg", "Net satış raporu", "günlük • haftalık • aylık görünüm"),
    ("3.jpeg",  "Renk kodlu borç",   "vade gününe göre takip"),
]


def gradient_bg() -> Image.Image:
    img = Image.new("RGB", (W, H), BG_TOP)
    draw = ImageDraw.Draw(img)
    for y in range(H):
        t = y / H
        r = int(BG_TOP[0] * (1 - t) + BG_BOT[0] * t)
        g = int(BG_TOP[1] * (1 - t) + BG_BOT[1] * t)
        b = int(BG_TOP[2] * (1 - t) + BG_BOT[2] * t)
        draw.line([(0, y), (W, y)], fill=(r, g, b))
    return img


def load_font(size: int) -> ImageFont.FreeTypeFont:
    candidates = [
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except Exception:
            continue
    return ImageFont.load_default()


def round_corners(img: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, img.size[0], img.size[1]), radius=radius, fill=255
    )
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def add_bezel(img: Image.Image, thickness: int, color: tuple, radius: int) -> Image.Image:
    """Görseli iPhone tarzı bezel ile sarar."""
    w, h = img.size
    new_w = w + 2 * thickness
    new_h = h + 2 * thickness
    frame = Image.new("RGBA", (new_w, new_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(frame)
    draw.rounded_rectangle(
        (0, 0, new_w, new_h), radius=radius + thickness, fill=color + (255,)
    )
    frame.paste(img, (thickness, thickness), img if img.mode == "RGBA" else None)
    return frame


def drop_shadow(img: Image.Image, blur: int = 30, offset: int = 14) -> Image.Image:
    w, h = img.size
    shadow = Image.new("RGBA", (w + offset * 2, h + offset * 2), (0, 0, 0, 0))
    sd_mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(sd_mask).rounded_rectangle(
        (0, 0, w, h), radius=CORNER_RADIUS + BEZEL_THICKNESS, fill=110
    )
    shadow.paste((0, 0, 0, 110), (offset, offset + 6), sd_mask)
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    shadow.paste(img, (offset, offset), img)
    return shadow


def build(src_name: str, title: str, subtitle: str, out_name: str) -> None:
    src_path = SRC / src_name
    if not src_path.exists():
        raise FileNotFoundError(src_path)
    shot = Image.open(src_path).convert("RGB")

    # Görsel boyutu: kullanılabilir alan
    avail_w = W - SHOT_PAD * 2 - BEZEL_THICKNESS * 2
    avail_h = H - TOP_TITLE_AREA_H - SHOT_PAD - BEZEL_THICKNESS * 2

    # Şekil oranını koru — fit
    sw, sh = shot.size
    scale = min(avail_w / sw, avail_h / sh)
    new_sw = int(sw * scale)
    new_sh = int(sh * scale)
    shot = shot.resize((new_sw, new_sh), Image.LANCZOS)
    shot = round_corners(shot, CORNER_RADIUS)
    framed = add_bezel(shot, BEZEL_THICKNESS, BEZEL_COLOR, CORNER_RADIUS)
    shadowed = drop_shadow(framed, blur=36, offset=10)

    # Canvas
    canvas = gradient_bg().convert("RGBA")
    draw = ImageDraw.Draw(canvas)

    # Başlık
    title_font = load_font(96)
    sub_font = load_font(50)
    title_bbox = draw.textbbox((0, 0), title, font=title_font)
    title_w = title_bbox[2] - title_bbox[0]
    title_h = title_bbox[3] - title_bbox[1]
    title_x = (W - title_w) // 2
    title_y = 130
    draw.text((title_x, title_y), title, font=title_font, fill=TEXT_COLOR)

    sub_bbox = draw.textbbox((0, 0), subtitle, font=sub_font)
    sub_w = sub_bbox[2] - sub_bbox[0]
    sub_x = (W - sub_w) // 2
    sub_y = title_y + title_h + 36
    draw.text((sub_x, sub_y), subtitle, font=sub_font, fill=(60, 90, 80))

    # Mockup'ı yerleştir
    fw, fh = shadowed.size
    fx = (W - fw) // 2
    fy = TOP_TITLE_AREA_H
    canvas.paste(shadowed, (fx, fy), shadowed)

    final = canvas.convert("RGB")
    out_path = OUT / out_name
    final.save(out_path, optimize=True)
    print(f"✅ {out_path.name}  ({src_name})")


if __name__ == "__main__":
    # Mevcut PNG'leri sil — eski Android UI screenshot'lar kalmasın
    for f in OUT.glob("*.png"):
        f.unlink()
    for i, (src, title, sub) in enumerate(SHOTS, start=1):
        build(src, title, sub, f"0{i}-iphone.png")
    print(f"\nKaydedildi: {OUT}")
