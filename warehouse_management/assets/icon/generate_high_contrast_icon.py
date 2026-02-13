#!/usr/bin/env python3
"""
Generate high-contrast Halkhata app icon
- Solid yellow/amber background (no white)
- Dark navy blue book for strong contrast
- Maintains existing Halkhata ledger book identity
"""

from PIL import Image, ImageDraw
import math
import os

def create_high_contrast_icon(size=1024):
    """Create app icon with strong yellow background and dark book"""

    # High contrast colors matching app theme
    # Yellow background from app's gradient (ColorPalette.offerYellowEnd)
    yellow_bg = (245, 158, 11)  # #F59E0B - Amber-500 (app's yellow gradient end)

    # Dark navy book for maximum contrast on yellow
    dark_navy = (15, 23, 42)  # #0F172A - Slate-900 (very dark, high contrast)

    # Lighter navy for spine
    navy_accent = (30, 58, 138)  # #1E3A8A - Blue-900

    # White for ledger lines (shows well on dark navy)
    white = (255, 255, 255)

    # Gold accent for dots
    gold = (251, 191, 36)  # #FBBF24 - Amber-400

    # Create image with solid yellow background (NO WHITE)
    img = Image.new('RGB', (size, size), yellow_bg)
    draw = ImageDraw.Draw(img)

    # Padding - book fills most of icon for boldness
    padding = size * 0.12
    book_width = size - (2 * padding)
    book_height = book_width * 0.72  # Slightly shorter for better proportion

    # Book position (centered)
    book_x = padding
    book_y = (size - book_height) / 2

    # Draw subtle shadow for depth (darker yellow)
    shadow_offset = size * 0.015
    shadow_color = (217, 119, 6)  # Darker amber
    draw.rounded_rectangle(
        [book_x + shadow_offset, book_y + shadow_offset,
         book_x + book_width + shadow_offset, book_y + book_height + shadow_offset],
        radius=size * 0.04,
        fill=shadow_color
    )

    # Draw main book (DARK NAVY for strong contrast)
    draw.rounded_rectangle(
        [book_x, book_y, book_x + book_width, book_y + book_height],
        radius=size * 0.04,
        fill=dark_navy
    )

    # Draw book spine (navy accent)
    spine_width = book_width * 0.1
    draw.rounded_rectangle(
        [book_x, book_y, book_x + spine_width, book_y + book_height],
        radius=size * 0.04,
        fill=navy_accent
    )

    # Draw pages effect (right side) - very light gray
    page_thickness = size * 0.012
    page_color = (226, 232, 240)  # Light gray
    for i in range(3):
        offset = (i + 1) * (page_thickness * 0.7)
        draw.line(
            [book_x + book_width - offset, book_y + book_height * 0.2,
             book_x + book_width - offset, book_y + book_height * 0.8],
            fill=page_color,
            width=int(page_thickness * 0.4)
        )

    # Draw decorative wave line (gold on dark background)
    wave_y = book_y + book_height * 0.62
    wave_points = []
    steps = 25
    for i in range(steps + 1):
        x = book_x + spine_width * 1.3 + (i / steps) * (book_width - spine_width * 1.5)
        y_offset = math.sin(i * math.pi / 6) * (size * 0.012)
        y = wave_y + y_offset
        wave_points.append((x, y))

    if len(wave_points) > 1:
        draw.line(wave_points, fill=gold, width=int(size * 0.012))

    # Add ledger lines (white on dark book) - BOLD for visibility
    center_x = book_x + book_width / 2
    center_y = book_y + book_height * 0.35

    line_width = book_width * 0.55
    line_gap = size * 0.055
    line_thickness = int(size * 0.018)  # Thicker for better visibility

    for i in range(3):
        y_pos = center_y + (i - 1) * line_gap
        draw.rectangle(
            [center_x - line_width/2, y_pos - line_thickness/2,
             center_x + line_width/2, y_pos + line_thickness/2],
            fill=white
        )

    # Add accent dots (gold, larger for visibility)
    dot_radius = size * 0.015
    for i in range(3):
        y_pos = center_y + (i - 1) * line_gap
        x_pos = center_x - line_width/2 - dot_radius * 2.5
        draw.ellipse(
            [x_pos - dot_radius, y_pos - dot_radius,
             x_pos + dot_radius, y_pos + dot_radius],
            fill=gold
        )

    return img


def create_high_contrast_foreground(size=1024):
    """Create foreground with transparent background for adaptive icon"""

    # Dark navy book
    dark_navy = (15, 23, 42, 255)
    navy_accent = (30, 58, 138, 255)
    white = (255, 255, 255, 255)
    gold = (251, 191, 36, 255)
    page_color = (226, 232, 240, 255)

    # Transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # More padding for adaptive icon safe zone
    padding = size * 0.18
    book_width = size - (2 * padding)
    book_height = book_width * 0.72
    book_x = padding
    book_y = (size - book_height) / 2

    # Draw main book
    draw.rounded_rectangle(
        [book_x, book_y, book_x + book_width, book_y + book_height],
        radius=size * 0.04,
        fill=dark_navy
    )

    # Spine
    spine_width = book_width * 0.1
    draw.rounded_rectangle(
        [book_x, book_y, book_x + spine_width, book_y + book_height],
        radius=size * 0.04,
        fill=navy_accent
    )

    # Pages
    page_thickness = size * 0.012
    for i in range(3):
        offset = (i + 1) * (page_thickness * 0.7)
        draw.line(
            [book_x + book_width - offset, book_y + book_height * 0.2,
             book_x + book_width - offset, book_y + book_height * 0.8],
            fill=page_color,
            width=int(page_thickness * 0.4)
        )

    # Wave
    wave_y = book_y + book_height * 0.62
    wave_points = []
    steps = 25
    for i in range(steps + 1):
        x = book_x + spine_width * 1.3 + (i / steps) * (book_width - spine_width * 1.5)
        y_offset = math.sin(i * math.pi / 6) * (size * 0.012)
        y = wave_y + y_offset
        wave_points.append((x, y))

    if len(wave_points) > 1:
        draw.line(wave_points, fill=gold, width=int(size * 0.012))

    # Ledger lines
    center_x = book_x + book_width / 2
    center_y = book_y + book_height * 0.35
    line_width = book_width * 0.55
    line_gap = size * 0.055
    line_thickness = int(size * 0.018)

    for i in range(3):
        y_pos = center_y + (i - 1) * line_gap
        draw.rectangle(
            [center_x - line_width/2, y_pos - line_thickness/2,
             center_x + line_width/2, y_pos + line_thickness/2],
            fill=white
        )

    # Dots
    dot_radius = size * 0.015
    for i in range(3):
        y_pos = center_y + (i - 1) * line_gap
        x_pos = center_x - line_width/2 - dot_radius * 2.5
        draw.ellipse(
            [x_pos - dot_radius, y_pos - dot_radius,
             x_pos + dot_radius, y_pos + dot_radius],
            fill=gold
        )

    return img


# Generate high-contrast icons
print("=" * 60)
print("Generating HIGH-CONTRAST Halkhata App Icon")
print("=" * 60)
print("\nColors used:")
print("  Background:     #F59E0B (Amber-500, yellow)")
print("  Book:           #0F172A (Slate-900, dark navy)")
print("  Spine:          #1E3A8A (Blue-900, navy accent)")
print("  Ledger Lines:   #FFFFFF (White, high contrast)")
print("  Accent Dots:    #FBBF24 (Amber-400, gold)")
print("  Shadow:         #D97706 (Amber-600, dark yellow)")
print("\n" + "-" * 60)

# Create 1024x1024 icon with solid yellow background
icon_1024 = create_high_contrast_icon(1024)
icon_1024.save('wavezly_icon_1024_contrast.png', 'PNG', quality=100)
print("[OK] Generated: wavezly_icon_1024_contrast.png")
print("  - NO white background")
print("  - Strong contrast for launcher visibility")

# Create foreground for adaptive icon
icon_fg = create_high_contrast_foreground(1024)
icon_fg.save('wavezly_icon_foreground_contrast.png', 'PNG')
print("[OK] Generated: wavezly_icon_foreground_contrast.png")
print("  - Transparent background")
print("  - Safe for Android adaptive icon masks")

print("\n" + "=" * 60)
print("Icon generation complete!")
print("=" * 60)
print("\nBefore -> After:")
print("  White BG -> Solid yellow (#F59E0B)")
print("  Light blue book -> Dark navy (#0F172A)")
print("  Low contrast -> HIGH CONTRAST")
print("  Washed out -> BOLD launcher presence")
print("\nConfirmation: NO VISIBLE WHITE BACKGROUND in final icons")
print("=" * 60)
