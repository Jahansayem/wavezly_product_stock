#!/usr/bin/env python3
"""
Generate Halkhata app icon with Royal Blue color scheme
Based on the provided হালখাতা ledger book design
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_halkhata_icon(size=1024):
    """Create app icon with book and Bengali text"""

    # Colors matching the new Royal Blue theme
    royal_blue = (42, 95, 209)  # #2A5FD1
    white = (255, 255, 255)
    gold = (251, 191, 36)  # Amber accent

    # Create image with white background
    img = Image.new('RGB', (size, size), white)
    draw = ImageDraw.Draw(img)

    # Padding
    padding = size * 0.1
    book_width = size - (2 * padding)
    book_height = book_width * 0.75

    # Book position (centered)
    book_x = padding
    book_y = (size - book_height) / 2

    # Draw book shadow (subtle)
    shadow_offset = size * 0.02
    shadow_color = (200, 200, 200)
    draw.rounded_rectangle(
        [book_x + shadow_offset, book_y + shadow_offset,
         book_x + book_width + shadow_offset, book_y + book_height + shadow_offset],
        radius=size * 0.03,
        fill=shadow_color
    )

    # Draw main book (Royal Blue)
    draw.rounded_rectangle(
        [book_x, book_y, book_x + book_width, book_y + book_height],
        radius=size * 0.03,
        fill=royal_blue
    )

    # Draw book spine highlight (lighter blue)
    spine_width = book_width * 0.08
    spine_color = (82, 135, 229)  # Lighter blue
    draw.rounded_rectangle(
        [book_x, book_y, book_x + spine_width, book_y + book_height],
        radius=size * 0.03,
        fill=spine_color
    )

    # Draw pages effect (right side)
    page_thickness = size * 0.015
    page_color = (245, 245, 245)
    for i in range(3):
        offset = (i + 1) * (page_thickness * 0.6)
        draw.line(
            [book_x + book_width - offset, book_y + book_height * 0.15,
             book_x + book_width - offset, book_y + book_height * 0.85],
            fill=page_color,
            width=int(page_thickness * 0.3)
        )

    # Draw decorative wave line (inspired by original design)
    wave_y = book_y + book_height * 0.65
    wave_points = []
    steps = 30
    for i in range(steps + 1):
        x = book_x + spine_width + (i / steps) * (book_width - spine_width)
        # Simple sine wave
        import math
        y_offset = math.sin(i * math.pi / 8) * (size * 0.015)
        y = wave_y + y_offset
        wave_points.append((x, y))

    # Draw wave
    if len(wave_points) > 1:
        draw.line(wave_points, fill=gold, width=int(size * 0.01))

    # Add Bengali text "হালখাতা" placeholder
    # For icon, we'll use a stylized "H" or book symbol instead
    # Draw a simple ledger lines icon in the center
    center_x = book_x + book_width / 2
    center_y = book_y + book_height * 0.4

    # Draw ledger lines (3 horizontal lines representing entries)
    line_width = book_width * 0.5
    line_gap = size * 0.05
    line_thickness = int(size * 0.015)

    for i in range(3):
        y_pos = center_y + (i - 1) * line_gap
        draw.rectangle(
            [center_x - line_width/2, y_pos - line_thickness/2,
             center_x + line_width/2, y_pos + line_thickness/2],
            fill=white
        )

    # Add small accent dots on the left of each line (bullet points)
    dot_radius = size * 0.012
    for i in range(3):
        y_pos = center_y + (i - 1) * line_gap
        x_pos = center_x - line_width/2 - dot_radius * 3
        draw.ellipse(
            [x_pos - dot_radius, y_pos - dot_radius,
             x_pos + dot_radius, y_pos + dot_radius],
            fill=gold
        )

    return img

# Generate icons
print("Generating Halkhata app icon...")

# Create 1024x1024 icon
icon_1024 = create_halkhata_icon(1024)
icon_1024.save('wavezly_icon_1024.png', 'PNG', quality=100)
print("Generated wavezly_icon_1024.png")

# Create foreground (transparent background version for adaptive icon)
icon_fg = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
draw_fg = ImageDraw.Draw(icon_fg)

# Draw just the book and elements on transparent background
royal_blue = (42, 95, 209, 255)
white = (255, 255, 255, 255)
gold = (251, 191, 36, 255)

size = 1024
padding = size * 0.15  # More padding for adaptive icon
book_width = size - (2 * padding)
book_height = book_width * 0.75
book_x = padding
book_y = (size - book_height) / 2

# Draw main book
draw_fg.rounded_rectangle(
    [book_x, book_y, book_x + book_width, book_y + book_height],
    radius=size * 0.03,
    fill=royal_blue
)

# Spine
spine_width = book_width * 0.08
spine_color = (82, 135, 229, 255)
draw_fg.rounded_rectangle(
    [book_x, book_y, book_x + spine_width, book_y + book_height],
    radius=size * 0.03,
    fill=spine_color
)

# Pages
page_thickness = size * 0.015
page_color = (245, 245, 245, 255)
for i in range(3):
    offset = (i + 1) * (page_thickness * 0.6)
    draw_fg.line(
        [book_x + book_width - offset, book_y + book_height * 0.15,
         book_x + book_width - offset, book_y + book_height * 0.85],
        fill=page_color,
        width=int(page_thickness * 0.3)
    )

# Wave and ledger lines
import math
wave_y = book_y + book_height * 0.65
wave_points = []
steps = 30
for i in range(steps + 1):
    x = book_x + spine_width + (i / steps) * (book_width - spine_width)
    y_offset = math.sin(i * math.pi / 8) * (size * 0.015)
    y = wave_y + y_offset
    wave_points.append((x, y))

if len(wave_points) > 1:
    draw_fg.line(wave_points, fill=gold, width=int(size * 0.01))

# Ledger lines
center_x = book_x + book_width / 2
center_y = book_y + book_height * 0.4
line_width = book_width * 0.5
line_gap = size * 0.05
line_thickness = int(size * 0.015)

for i in range(3):
    y_pos = center_y + (i - 1) * line_gap
    draw_fg.rectangle(
        [center_x - line_width/2, y_pos - line_thickness/2,
         center_x + line_width/2, y_pos + line_thickness/2],
        fill=white
    )

# Dots
dot_radius = size * 0.012
for i in range(3):
    y_pos = center_y + (i - 1) * line_gap
    x_pos = center_x - line_width/2 - dot_radius * 3
    draw_fg.ellipse(
        [x_pos - dot_radius, y_pos - dot_radius,
         x_pos + dot_radius, y_pos + dot_radius],
        fill=gold
    )

icon_fg.save('wavezly_icon_foreground.png', 'PNG')
print("Generated wavezly_icon_foreground.png")

print("\nIcon generation complete!")
print("   - wavezly_icon_1024.png (standard icon)")
print("   - wavezly_icon_foreground.png (adaptive icon foreground)")
