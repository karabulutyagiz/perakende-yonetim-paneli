"""Play Store feature graphic üretici — 1024x500 PNG.

ParaSende brand palette:
- Background: #F8F2E5 (krem)
- Primary teal: #0F766E
- Dark text: #1F2937
- Accent gold: #B8860B
"""

from PIL import Image, ImageDraw, ImageFilter, ImageFont
from pathlib import Path

W, H = 1024, 500
BG = (248, 242, 229)          # #F8F2E5
TEAL = (15, 118, 110)         # #0F766E
TEAL_DARK = (8, 73, 68)
DARK = (31, 41, 55)           # #1F2937
GOLD = (184, 134, 11)         # #B8860B
WHITE = (255, 255, 255)

OUT = Path(__file__).parent / "feature-graphic-1024x500.png"
ICON = Path(__file__).parent.parent.parent / "mobile" / "assets" / "icon" / "parasende.png"


def load_font(size: int, bold: bool = False) -> ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial.ttf",
    ]
    if bold:
        candidates = [
            "/System/Library/Fonts/Helvetica.ttc",  # has Bold inside
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size=size, index=1 if bold and path.endswith(".ttc") else 0)
        except Exception:
            continue
    return ImageFont.load_default()


def main() -> None:
    img = Image.new("RGB", (W, H), BG)

    # Soft radial-ish gradient via overlay (yumuşatılmış teal blob sağ tarafta)
    overlay = Image.new("RGB", (W, H), BG)
    draw_o = ImageDraw.Draw(overlay)
    # büyük teal yarı-saydam daire
    cx, cy, r = 880, 250, 380
    for i in range(r, 0, -8):
        alpha = int(60 * (1 - i / r) ** 1.8)
        tint = (
            min(255, BG[0] + (TEAL[0] - BG[0]) * alpha // 255),
            min(255, BG[1] + (TEAL[1] - BG[1]) * alpha // 255),
            min(255, BG[2] + (TEAL[2] - BG[2]) * alpha // 255),
        )
        draw_o.ellipse((cx - i, cy - i, cx + i, cy + i), fill=tint)
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=18))
    img = Image.blend(img, overlay, alpha=0.55)

    draw = ImageDraw.Draw(img)

    # Sol tarafa app icon (yuvarlatılmış kare içinde)
    icon_size = 220
    icon = Image.open(ICON).convert("RGBA").resize((icon_size, icon_size), Image.LANCZOS)
    icon_x, icon_y = 70, (H - icon_size) // 2
    # Yuvarlatılmış kare arka plan (beyaz)
    pad = 14
    bg_box = Image.new("RGBA", (icon_size + pad * 2, icon_size + pad * 2), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg_box)
    bg_draw.rounded_rectangle(
        (0, 0, icon_size + pad * 2 - 1, icon_size + pad * 2 - 1),
        radius=46,
        fill=WHITE,
    )
    img.paste(bg_box, (icon_x - pad, icon_y - pad), bg_box)
    img.paste(icon, (icon_x, icon_y), icon)

    # Sağ tarafa metin
    text_x = icon_x + icon_size + 70
    title_font = load_font(78, bold=True)
    sub_font = load_font(34)
    tag_font = load_font(26, bold=True)

    draw.text((text_x, 130), "ParaSende", fill=DARK, font=title_font)
    draw.text((text_x, 230), "İşletmeni cebinden yönet", fill=TEAL_DARK, font=sub_font)

    # Etiket çipleri (pill'ler) — alta sıralı
    chips = ["Stok", "Sipariş", "Fatura", "Borç", "Rapor"]
    cx_chip = text_x
    cy_chip = 320
    chip_h = 50
    for label in chips:
        bbox = draw.textbbox((0, 0), label, font=tag_font)
        tw = bbox[2] - bbox[0]
        chip_w = tw + 40
        draw.rounded_rectangle(
            (cx_chip, cy_chip, cx_chip + chip_w, cy_chip + chip_h),
            radius=chip_h // 2,
            fill=TEAL,
        )
        draw.text(
            (cx_chip + 20, cy_chip + (chip_h - (bbox[3] - bbox[1])) // 2 - bbox[1]),
            label,
            fill=WHITE,
            font=tag_font,
        )
        cx_chip += chip_w + 14

    # Alt sağ köşeye küçük altın aksan
    draw.rounded_rectangle((W - 180, H - 30, W - 30, H - 18), radius=6, fill=GOLD)

    img.save(OUT, "PNG", optimize=True)
    print(f"Yazıldı: {OUT} ({OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
