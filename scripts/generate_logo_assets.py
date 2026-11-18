#!/usr/bin/env python3
"""
BoardBuddy Brand Asset Generator
Generates pixel-perfect SVG and PNG logo assets for backend static serving
and multi-platform Flutter client deployment (web, iOS, Android, macOS).
"""

import os
import math
import struct
import zlib


def write_png(filename: str, width: int, height: int, rgba: bytearray):
    """Writes raw RGBA bytes into a valid, optimized PNG file."""
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    raw_lines = bytearray()
    stride = width * 4
    for y in range(height):
        raw_lines.append(0)  # Filter type 0
        raw_lines.extend(rgba[y * stride : (y + 1) * stride])
    idat = zlib.compress(bytes(raw_lines), 9)

    def chunk(tag: bytes, data: bytes) -> bytes:
        crc = zlib.crc32(tag + data) & 0xFFFFFFFF
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)

    with open(filename, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", idat))
        f.write(chunk(b"IEND", b""))


def render_boardbuddy_icon(size: int, maskable: bool = False) -> bytearray:
    """Renders the BoardBuddy squircle + 2x2 Kanban card grid icon at any resolution."""
    buf = bytearray(size * size * 4)

    # Scale outer squircle if maskable (safe area is 80%)
    scale = 0.78 if maskable else 1.0

    bx = 0.85 * scale
    by = 0.85 * scale
    br = 0.44 * scale

    ring_cx = 0.30 * scale
    ring_cy = 0.30 * scale
    ring_half = 0.16 * scale
    ring_r = 0.08 * scale
    ring_stroke = 0.052 * scale

    c_grad1 = (226, 177, 138)  # #E2B18A (warm peach)
    c_grad2 = (236, 204, 168)  # #ECCCA8 (soft amber)
    c_icon = (25, 23, 24)      # #191718 (deep espresso)

    inv_size = 2.0 / size

    def sd_rounded_box(px: float, py: float, w: float, h: float, r: float) -> float:
        dx = abs(px) - (w - r)
        dy = abs(py) - (h - r)
        ox = max(dx, 0.0)
        oy = max(dy, 0.0)
        outside_dist = math.sqrt(ox * ox + oy * oy)
        inside_dist = min(max(dx, dy), 0.0)
        return outside_dist + inside_dist - r

    for y in range(size):
        ny = (y + 0.5) * inv_size - 1.0
        row_offset = y * size * 4
        for x in range(size):
            nx = (x + 0.5) * inv_size - 1.0

            d_outer = sd_rounded_box(nx, ny, bx, by, br)
            alpha_outer = max(0.0, min(1.0, 0.5 - d_outer / inv_size))
            if alpha_outer <= 0.0:
                continue

            t = max(0.0, min(1.0, (nx + ny + 1.6) / 3.2))
            gr = c_grad1[0] + (c_grad2[0] - c_grad1[0]) * t
            gg = c_grad1[1] + (c_grad2[1] - c_grad1[1]) * t
            gb = c_grad1[2] + (c_grad2[2] - c_grad1[2]) * t

            rx = abs(nx) - ring_cx
            ry = abs(ny) - ring_cy
            d_ring_box = sd_rounded_box(rx, ry, ring_half, ring_half, ring_r)
            d_ring = abs(d_ring_box) - ring_stroke
            alpha_ring = max(0.0, min(1.0, 0.5 - d_ring / inv_size))

            fr = gr * (1.0 - alpha_ring) + c_icon[0] * alpha_ring
            fg = gg * (1.0 - alpha_ring) + c_icon[1] * alpha_ring
            fb = gb * (1.0 - alpha_ring) + c_icon[2] * alpha_ring

            idx = row_offset + x * 4
            buf[idx] = int(fr)
            buf[idx + 1] = int(fg)
            buf[idx + 2] = int(fb)
            buf[idx + 3] = int(alpha_outer * 255)

    return buf


SVG_ICON = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="100%" height="100%">
  <defs>
    <linearGradient id="bbPeachGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#E2B18A" />
      <stop offset="50%" stop-color="#E8C19C" />
      <stop offset="100%" stop-color="#ECCCA8" />
    </linearGradient>
    <filter id="subtleGlow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="16" stdDeviation="24" flood-color="#FF6433" flood-opacity="0.22" />
    </filter>
  </defs>

  <!-- Outer Squircle -->
  <rect x="36" y="36" width="440" height="440" rx="116" ry="116" fill="url(#bbPeachGrad)" filter="url(#subtleGlow)" />

  <!-- 4 Rounded Hollow Cards (Kanban 2x2 Grid) -->
  <rect x="126" y="126" width="104" height="104" rx="26" ry="26" fill="none" stroke="#191718" stroke-width="26" />
  <rect x="282" y="126" width="104" height="104" rx="26" ry="26" fill="none" stroke="#191718" stroke-width="26" />
  <rect x="126" y="282" width="104" height="104" rx="26" ry="26" fill="none" stroke="#191718" stroke-width="26" />
  <rect x="282" y="282" width="104" height="104" rx="26" ry="26" fill="none" stroke="#191718" stroke-width="26" />
</svg>"""

SVG_FULL_HORIZONTAL = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 680 180" width="100%" height="100%">
  <defs>
    <linearGradient id="bbPeachGradH" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#E2B18A" />
      <stop offset="50%" stop-color="#E8C19C" />
      <stop offset="100%" stop-color="#ECCCA8" />
    </linearGradient>
    <filter id="subtleGlowH" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="8" stdDeviation="14" flood-color="#FF6433" flood-opacity="0.25" />
    </filter>
  </defs>

  <!-- Icon (left side: 132x132) -->
  <g transform="translate(24, 24)">
    <rect width="132" height="132" rx="36" ry="36" fill="url(#bbPeachGradH)" filter="url(#subtleGlowH)" />
    <rect x="30" y="30" width="30" height="30" rx="8" ry="8" fill="none" stroke="#191718" stroke-width="7.5" />
    <rect x="72" y="30" width="30" height="30" rx="8" ry="8" fill="none" stroke="#191718" stroke-width="7.5" />
    <rect x="30" y="72" width="30" height="30" rx="8" ry="8" fill="none" stroke="#191718" stroke-width="7.5" />
    <rect x="72" y="72" width="30" height="30" rx="8" ry="8" fill="none" stroke="#191718" stroke-width="7.5" />
  </g>

  <!-- Typography -->
  <text x="180" y="104" fill="#FFFFFF" font-family="-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Segoe UI', Roboto, sans-serif" font-weight="800" font-size="54" letter-spacing="-1.2">BoardBuddy</text>
  <text x="182" y="138" fill="#8F8B88" font-family="-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'Segoe UI', Roboto, sans-serif" font-weight="500" font-size="16" letter-spacing="0.2">AI-Powered Kanban</text>
</svg>"""


def main():
    print("🎨 Generating BoardBuddy Logo Assets...")

    # 1. SVGs
    svg_targets = [
        ("app/static/logo_icon.svg", SVG_ICON),
        ("app/static/logo.svg", SVG_FULL_HORIZONTAL),
        ("client/assets/images/logo_icon.svg", SVG_ICON),
        ("client/assets/images/logo.svg", SVG_FULL_HORIZONTAL),
    ]
    for path, content in svg_targets:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"  ✓ Written: {path}")

    # 2. Master PNGs
    print("  Rendering raster PNGs...")
    sizes = [1024, 512, 256, 192, 128, 64, 32, 16]
    for s in sizes:
        buf = render_boardbuddy_icon(s)
        # Backend static
        if s in [1024, 512, 256, 32]:
            write_png(f"app/static/logo_{s}.png", s, s, buf)
        if s == 512:
            write_png("app/static/logo.png", s, s, buf)
            write_png("app/static/logo_icon.png", s, s, buf)
        if s == 32:
            write_png("app/static/favicon.png", s, s, buf)
            # Write favicon.ico (PNG header works as modern favicon.ico)
            write_png("app/static/favicon.ico", s, s, buf)

        # Flutter client assets
        if s in [512, 256, 128, 32]:
            write_png(f"client/assets/images/logo_{s}.png", s, s, buf)
        if s == 512:
            write_png("client/assets/images/logo.png", s, s, buf)
            write_png("client/assets/images/logo_icon.png", s, s, buf)

        # Web launcher / PWA icons
        if s == 192:
            write_png("client/web/icons/Icon-192.png", 192, 192, buf)
            buf_mask = render_boardbuddy_icon(192, maskable=True)
            write_png("client/web/icons/Icon-maskable-192.png", 192, 192, buf_mask)
        if s == 512:
            write_png("client/web/icons/Icon-512.png", 512, 512, buf)
            buf_mask = render_boardbuddy_icon(512, maskable=True)
            write_png("client/web/icons/Icon-maskable-512.png", 512, 512, buf_mask)
        if s == 32:
            write_png("client/web/favicon.png", 32, 32, buf)

        # macOS AppIcon
        macos_path = "client/macos/Runner/Assets.xcassets/AppIcon.appiconset"
        if os.path.isdir(macos_path):
            if s in [16, 32, 64, 128, 256, 512, 1024]:
                write_png(f"{macos_path}/app_icon_{s}.png", s, s, buf)

        # iOS AppIcon
        ios_path = "client/ios/Runner/Assets.xcassets/AppIcon.appiconset"
        if os.path.isdir(ios_path):
            if s == 1024:
                write_png(f"{ios_path}/Icon-App-1024x1024@1x.png", 1024, 1024, buf)

    print("✅ All logo assets generated successfully!")


if __name__ == "__main__":
    main()
