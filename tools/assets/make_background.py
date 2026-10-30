#!/usr/bin/env python3
"""Genera assets/sprites/background.svg: un editor di codice scuro, con righe di "codice" sfocate.

Uso: python3 tools/assets/make_background.py
Il seme è fisso, quindi il risultato è sempre lo stesso.
"""
import random
from pathlib import Path

W, H = 800, 480
LINE_H = 20
GUTTER = 34
COLORS = ["#c792ea", "#82aaff", "#c3e88d", "#ffcb6b", "#89ddff", "#f78c6c", "#a6accd"]

BG = "#12141c"
ALPHA = 0.09  # intensità dei "token": i colori sono già mescolati con lo sfondo


def blend(color, alpha=ALPHA, base=BG):
    c = [int(color[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(base[i:i + 2], 16) for i in (1, 3, 5)]
    return "#" + "".join(f"{round(b[i] + (c[i] - b[i]) * alpha):02x}" for i in range(3))


rng = random.Random(1742)
parts = [
    f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">',
    "  <!-- Sfondo: editor di codice scuro (generato da tools/assets/make_background.py) -->",
    f'  <rect width="{W}" height="{H}" fill="{BG}"/>',
    f'  <rect width="{GUTTER}" height="{H}" fill="#171a24"/>',
    f'  <rect x="{GUTTER}" width="1" height="{H}" fill="#232838"/>',
]
indent = 0
for row in range(H // LINE_H):
    y = row * LINE_H + 6
    # "numero di riga" nel margine sinistro
    digits = 1 + (row + 1 >= 10)
    for d in range(digits):
        parts.append(f'  <rect x="{GUTTER - 10 - d * 6}" y="{y + 1}" width="4" height="6" rx="1" fill="#2c3245"/>')
    if rng.random() < 0.15:
        continue  # riga vuota
    indent = max(0, min(5, indent + rng.choice([-1, 0, 0, 1])))
    x = GUTTER + 12 + indent * 24
    for _ in range(rng.randint(2, 8)):
        w = rng.randint(14, 70)
        if x + w > W - 20:
            break
        color = rng.choice(COLORS)
        parts.append(f'  <rect x="{x}" y="{y}" width="{w}" height="8" rx="3" fill="{blend(color)}"/>')
        x += w + rng.randint(6, 12)
parts.append("</svg>")

out = Path(__file__).resolve().parents[2] / "assets" / "sprites" / "background.svg"
out.write_text("\n".join(parts) + "\n")
print(f"Scritto {out}")
