#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "screenshots"
LOGO_PATH = ROOT / "assets" / "logo.png"


PALETTE = {
    "bg_top": "#f4f7fb",
    "bg_bottom": "#e8eef8",
    "window": "#fbfcfe",
    "panel": "#1d2430",
    "card": "#ffffff",
    "card_alt": "#f4f8ff",
    "stroke": "#d7dfec",
    "text": "#1d2a3b",
    "muted": "#65758b",
    "accent": "#4f7cff",
    "accent_soft": "#e9f0ff",
    "green": "#22a06b",
    "amber": "#d98e04",
    "red": "#d24a43",
    "loofi": "#ff6b35",
    "openai": "#10a37f",
    "anthropic": "#c58b57",
    "codex": "#2e7cff",
}


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/liberation-sans/LiberationSans-Bold.ttf" if bold else "/usr/share/fonts/liberation-sans/LiberationSans-Regular.ttf",
    ]
    for candidate in candidates:
        path = Path(candidate)
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


FONT_H1 = font(28, bold=True)
FONT_H2 = font(22, bold=True)
FONT_H3 = font(18, bold=True)
FONT_BODY = font(15)
FONT_SMALL = font(13)
FONT_TINY = font(11)
FONT_BOLD = font(15, bold=True)
FONT_SMALL_BOLD = font(13, bold=True)


def make_background(size: tuple[int, int]) -> Image.Image:
    width, height = size
    bg = Image.new("RGB", size, PALETTE["bg_top"])
    draw = ImageDraw.Draw(bg)
    for y in range(height):
        ratio = y / max(height - 1, 1)
        draw.line(
            [(0, y), (width, y)],
            fill=blend(PALETTE["bg_top"], PALETTE["bg_bottom"], ratio),
        )
    return bg


def blend(c1: str, c2: str, ratio: float) -> tuple[int, int, int]:
    def hex_to_rgb(value: str) -> tuple[int, int, int]:
        value = value.lstrip("#")
        return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))

    a = hex_to_rgb(c1)
    b = hex_to_rgb(c2)
    return tuple(int(a[i] + (b[i] - a[i]) * ratio) for i in range(3))


def rounded_box(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], fill: str, outline: str | None = None, radius: int = 20, width: int = 1) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def shadowed_panel(base: Image.Image, box: tuple[int, int, int, int], radius: int = 24, shadow_offset: tuple[int, int] = (0, 18)) -> None:
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    shadow_box = (
        box[0] + shadow_offset[0],
        box[1] + shadow_offset[1],
        box[2] + shadow_offset[0],
        box[3] + shadow_offset[1],
    )
    sd.rounded_rectangle(shadow_box, radius=radius, fill=(24, 41, 67, 42))
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    base.alpha_composite(shadow)
    draw = ImageDraw.Draw(base)
    draw.rounded_rectangle(box, radius=radius, fill=PALETTE["window"], outline=PALETTE["stroke"], width=1)


def text(draw: ImageDraw.ImageDraw, xy: tuple[int, int], value: str, fnt: ImageFont.ImageFont, fill: str = PALETTE["text"]) -> None:
    draw.text(xy, value, font=fnt, fill=fill)


def pill(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], label: str, fill: str, fg: str) -> None:
    rounded_box(draw, box, fill=fill, radius=(box[3] - box[1]) // 2)
    bbox = draw.textbbox((0, 0), label, font=FONT_SMALL_BOLD)
    tx = box[0] + ((box[2] - box[0]) - (bbox[2] - bbox[0])) // 2
    ty = box[1] + ((box[3] - box[1]) - (bbox[3] - bbox[1])) // 2 - 1
    text(draw, (tx, ty), label, FONT_SMALL_BOLD, fg)


def progress(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], ratio: float, fill: str) -> None:
    rounded_box(draw, box, fill="#e9edf4", radius=(box[3] - box[1]) // 2)
    inner = (box[0], box[1], int(box[0] + max(4, (box[2] - box[0]) * max(0.0, min(ratio, 1.0)))), box[3])
    rounded_box(draw, inner, fill=fill, radius=(box[3] - box[1]) // 2)


def place_logo(base: Image.Image, xy: tuple[int, int], size: int) -> None:
    logo = Image.open(LOGO_PATH).convert("RGBA")
    logo.thumbnail((size, size))
    base.alpha_composite(logo, xy)


def draw_window_chrome(draw: ImageDraw.ImageDraw, base: Image.Image, x: int, y: int, w: int, h: int, title: str) -> None:
    shadowed_panel(base, (x, y, x + w, y + h))
    rounded_box(draw, (x, y, x + w, y + 62), fill="#f7f9fd", outline=PALETTE["stroke"], radius=24)
    place_logo(base, (x + 18, y + 14), 34)
    text(draw, (x + 62, y + 20), title, FONT_H3)
    for i, color in enumerate(("#ff5f57", "#ffbd2f", "#28c840")):
        cx = x + w - 72 + i * 18
        draw.ellipse((cx, y + 22, cx + 10, y + 32), fill=color)


def stat_card(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, h: int, title_value: str, main_value: str, tint: str) -> None:
    rounded_box(draw, (x, y, x + w, y + h), fill=PALETTE["card"], outline=PALETTE["stroke"], radius=16)
    text(draw, (x + 18, y + 14), title_value, FONT_SMALL, PALETTE["muted"])
    text(draw, (x + 18, y + 38), main_value, FONT_H3, tint)


def metric_chip(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, title_value: str, value: str, detail: str, tint: str) -> None:
    rounded_box(draw, (x, y, x + w, y + 78), fill=PALETTE["card_alt"], outline=PALETTE["stroke"], radius=16)
    text(draw, (x + 14, y + 12), title_value, FONT_TINY, PALETTE["muted"])
    text(draw, (x + 14, y + 30), value, FONT_BOLD, tint)
    text(draw, (x + 14, y + 52), detail, FONT_TINY, PALETTE["muted"])


def provider_card(draw: ImageDraw.ImageDraw, x: int, y: int, w: int, title_value: str, subtitle: str, accent: str, health: str, chips: Iterable[tuple[str, str, str]], bars: Iterable[tuple[str, float, str]]) -> None:
    rounded_box(draw, (x, y, x + w, y + 222), fill=PALETTE["card"], outline=PALETTE["stroke"], radius=20)
    rounded_box(draw, (x, y, x + 6, y + 222), fill=accent, radius=20)
    text(draw, (x + 20, y + 18), title_value, FONT_H3)
    text(draw, (x + 20, y + 44), subtitle, FONT_SMALL, PALETTE["muted"])
    pill(draw, (x + w - 130, y + 18, x + w - 18, y + 48), health, blend(accent, "#ffffff", 0.82), accent)
    for idx, chip in enumerate(chips):
        metric_chip(draw, x + 20 + idx * 168, y + 74, 154, chip[0], chip[1], chip[2], accent)
    bar_y = y + 168
    for idx, (label, ratio, tint) in enumerate(bars):
        top = bar_y + idx * 28
        text(draw, (x + 20, top), label, FONT_TINY, PALETTE["muted"])
        progress(draw, (x + 128, top + 3, x + w - 20, top + 11), ratio, tint)


def render_main() -> None:
    img = make_background((1360, 900)).convert("RGBA")
    draw = ImageDraw.Draw(img)

    draw.ellipse((1010, -70, 1360, 280), fill=(109, 151, 255, 54))
    draw.ellipse((950, 40, 1230, 320), fill=(255, 132, 91, 38))

    wx, wy, ww, wh = 94, 54, 1172, 786
    draw_window_chrome(draw, img, wx, wy, ww, wh, "AI Usage Monitor")

    content_x = wx + 24
    content_y = wy + 82

    rounded_box(draw, (content_x, content_y, wx + ww - 24, content_y + 108), fill=PALETTE["card_alt"], outline=PALETTE["stroke"], radius=20)
    text(draw, (content_x + 22, content_y + 16), "Realtime Overview", FONT_H2)
    text(draw, (content_x + 22, content_y + 50), "4 providers are live, browser sync is healthy, and current spend is tracking below plan.", FONT_BODY, PALETTE["muted"])
    pill(draw, (wx + ww - 186, content_y + 24, wx + ww - 40, content_y + 56), "Healthy", "#eaf8f1", PALETTE["green"])

    for idx, item in enumerate([
        ("Providers", "6 enabled", PALETTE["text"]),
        ("Connected", "4 active", PALETTE["green"]),
        ("Total Cost", "$72.38", PALETTE["text"]),
        ("Tool Monitors", "3 enabled", PALETTE["codex"]),
    ]):
        stat_card(draw, content_x + idx * 272, content_y + 126, 250, 86, item[0], item[1], item[2])

    text(draw, (content_x, content_y + 236), "Providers", FONT_H3)
    pill(draw, (content_x + 144, content_y + 236, content_x + 262, content_y + 266), "4/6 connected", "#eef3ff", PALETTE["accent"])

    provider_card(
        draw,
        content_x,
        content_y + 280,
        564,
        "Loofi Server",
        "Flux Trainer XL • stable sync • updated 2m ago",
        PALETTE["loofi"],
        "Connected",
        [
            ("Active model", "Flux Trainer XL", "training"),
            ("GPU memory", "71%", "live load"),
            ("Requests (24h)", "1,284", "server volume"),
        ],
        [
            ("GPU headroom", 0.71, PALETTE["loofi"]),
            ("Job queue", 0.42, PALETTE["amber"]),
        ],
    )
    provider_card(
        draw,
        content_x + 584,
        content_y + 280,
        564,
        "OpenAI",
        "gpt-5 • org admin key • updated 1m ago",
        PALETTE["openai"],
        "Connected",
        [
            ("Requests", "482", "since last reset"),
            ("Tokens", "1.82M", "1.12M in • 704K out"),
            ("Estimated cost", "$18.42", "Today $6.10"),
        ],
        [
            ("Request headroom", 0.58, PALETTE["green"]),
            ("Monthly budget", 0.44, PALETTE["openai"]),
        ],
    )
    provider_card(
        draw,
        content_x,
        content_y + 528,
        564,
        "Anthropic",
        "claude-sonnet-4.5 • monthly budget in view",
        PALETTE["anthropic"],
        "Connected",
        [
            ("Requests", "214", "since last reset"),
            ("Tokens", "924K", "601K in • 323K out"),
            ("Estimated cost", "$9.74", "Today $2.68"),
        ],
        [
            ("Request headroom", 0.32, PALETTE["amber"]),
            ("Monthly budget", 0.67, PALETTE["amber"]),
        ],
    )
    provider_card(
        draw,
        content_x + 584,
        content_y + 528,
        564,
        "Codex CLI",
        "browser sync on • 2 sessions active • reset in 3h",
        PALETTE["codex"],
        "Tracked",
        [
            ("Current period", "78 / 100", "78% used"),
            ("Weekly limit", "332 / 500", "66% used"),
            ("Plan cost", "$20/mo", "Pro"),
        ],
        [
            ("Primary quota", 0.78, PALETTE["amber"]),
            ("Weekly quota", 0.66, PALETTE["codex"]),
        ],
    )

    img.save(OUT_DIR / "main-window.png")


def render_settings() -> None:
    img = make_background((1360, 900)).convert("RGBA")
    draw = ImageDraw.Draw(img)
    draw.ellipse((920, -90, 1320, 300), fill=(79, 124, 255, 44))

    wx, wy, ww, wh = 94, 54, 1172, 786
    draw_window_chrome(draw, img, wx, wy, ww, wh, "AI Usage Monitor Settings")

    sidebar = (wx + 24, wy + 88, wx + 256, wy + wh - 24)
    rounded_box(draw, sidebar, fill="#f8fafc", outline=PALETTE["stroke"], radius=20)
    text(draw, (sidebar[0] + 22, sidebar[1] + 20), "Configure", FONT_H3)
    for idx, (name, active) in enumerate([
        ("General", False),
        ("Providers", True),
        ("Alerts", False),
        ("Budget", False),
        ("Subscriptions", False),
        ("History", False),
    ]):
        top = sidebar[1] + 68 + idx * 56
        fill = PALETTE["accent_soft"] if active else "#f8fafc"
        rounded_box(draw, (sidebar[0] + 14, top, sidebar[2] - 14, top + 42), fill=fill, outline=None, radius=14)
        text(draw, (sidebar[0] + 30, top + 11), name, FONT_BODY, PALETTE["accent"] if active else PALETTE["text"])

    cx0 = sidebar[2] + 20
    cx1 = wx + ww - 24
    rounded_box(draw, (cx0, wy + 88, cx1, wy + 188), fill=PALETTE["card_alt"], outline=PALETTE["stroke"], radius=20)
    text(draw, (cx0 + 22, wy + 108), "Providers", FONT_H2)
    text(draw, (cx0 + 22, wy + 144), "Enable the providers you actively use, keep admin credentials in KWallet, and point custom endpoints at compatible services when needed.", FONT_BODY, PALETTE["muted"])

    provider_rows = [
        ("Loofi Server", "On", PALETTE["loofi"], "https://loofi.local", "Environment token, no API key stored"),
        ("OpenAI", "On", PALETTE["openai"], "gpt-5", "Admin key stored in KWallet"),
        ("Anthropic", "On", PALETTE["anthropic"], "claude-sonnet-4.5", "Billing API key stored in KWallet"),
        ("Google Gemini", "Off", "#6a7b91", "gemini-2.5-pro", "Enable when you need provider comparisons"),
    ]
    top = wy + 212
    for idx, row in enumerate(provider_rows):
        ry = top + idx * 128
        rounded_box(draw, (cx0, ry, cx1, ry + 108), fill=PALETTE["card"], outline=PALETTE["stroke"], radius=18)
        draw.rounded_rectangle((cx0 + 18, ry + 18, cx0 + 26, ry + 90), radius=4, fill=row[2])
        text(draw, (cx0 + 42, ry + 20), row[0], FONT_H3)
        pill(draw, (cx1 - 136, ry + 18, cx1 - 22, ry + 48), row[1], "#eaf8f1" if row[1] == "On" else "#eef2f7", PALETTE["green"] if row[1] == "On" else PALETTE["muted"])
        metric_chip(draw, cx0 + 42, ry + 54, 220, "Primary field", row[3], "configured", row[2])
        metric_chip(draw, cx0 + 280, ry + 54, 290, "Secrets", row[4], "secure storage", row[2])
        metric_chip(draw, cx0 + 588, ry + 54, 210, "Refresh", "60 sec", "inherits global interval", row[2])

    img.save(OUT_DIR / "settings-view.png")


def render_panel() -> None:
    img = Image.new("RGBA", (540, 200), "#8cb0c7")
    draw = ImageDraw.Draw(img)
    for y in range(200):
        draw.line([(0, y), (540, y)], fill=blend("#90b7ca", "#7aa0b6", y / 199))
    draw.ellipse((20, 30, 170, 180), fill=(255, 255, 255, 26))
    draw.ellipse((380, -20, 560, 150), fill=(255, 214, 182, 34))

    rounded_box(draw, (18, 132, 522, 188), fill=PALETTE["panel"], outline="#283244", radius=18)

    for idx in range(4):
        ix = 34 + idx * 34
        draw.ellipse((ix, 148, ix + 18, ix + 132), fill="#93a3bd")

    widget_x = 206
    rounded_box(draw, (widget_x, 140, widget_x + 128, 180), fill="#232d3c", outline="#3a475b", radius=14)
    place_logo(img, (widget_x + 10, 147), 24)
    text(draw, (widget_x + 42, 146), "Flux XL", FONT_SMALL_BOLD, "#f5f7fb")
    text(draw, (widget_x + 42, 162), "GPU 71%  Req 1.2K", FONT_TINY, "#b8c3d6")

    rounded_box(draw, (widget_x + 136, 144, widget_x + 230, 176), fill="#26303f", outline="#3a475b", radius=14)
    text(draw, (widget_x + 154, 151), "$72.38", FONT_SMALL_BOLD, "#f5f7fb")
    text(draw, (widget_x + 154, 165), "month", FONT_TINY, "#b8c3d6")

    rounded_box(draw, (widget_x - 18, 26, widget_x + 230, 104), fill="#ffffff", outline=PALETTE["stroke"], radius=18)
    text(draw, (widget_x, 42), "Compact panel mode", FONT_SMALL_BOLD)
    text(draw, (widget_x, 62), "The widget can surface the active model, GPU load,", FONT_TINY, PALETTE["muted"])
    text(draw, (widget_x, 78), "request volume, or compact cost directly in the panel.", FONT_TINY, PALETTE["muted"])

    img.save(OUT_DIR / "panel-view.png")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    render_main()
    render_settings()
    render_panel()


if __name__ == "__main__":
    main()
