#!/usr/bin/env python3
"""
Convert the Halkhata design image to app icon format
Resizes and optimizes for Android app icons
"""

from PIL import Image
import os

# Input image path
input_image = r"C:\Users\Jahan\Downloads\ChatGPT Image Feb 7, 2026, 03_51_22 PM.png"

print("Converting Halkhata image to app icon...")

# Open the original image
img = Image.open(input_image)
print(f"Original image size: {img.size}")
print(f"Original image mode: {img.mode}")

# === 1. Create 1024x1024 standard icon (with background) ===
print("\n1. Creating standard 1024x1024 icon...")

# Resize to 1024x1024 with high-quality resampling
icon_1024 = img.resize((1024, 1024), Image.Resampling.LANCZOS)

# Convert to RGB if it has transparency (for compatibility)
if icon_1024.mode == 'RGBA':
    # Create white background
    background = Image.new('RGB', (1024, 1024), (255, 255, 255))
    # Paste the icon on white background
    background.paste(icon_1024, (0, 0), icon_1024)
    icon_1024 = background
elif icon_1024.mode != 'RGB':
    icon_1024 = icon_1024.convert('RGB')

# Save the standard icon
icon_1024.save('wavezly_icon_1024.png', 'PNG', quality=100, optimize=True)
print("   Saved: wavezly_icon_1024.png")

# === 2. Create adaptive icon foreground (transparent background) ===
print("\n2. Creating adaptive icon foreground...")

# Reload original to preserve transparency
img_original = Image.open(input_image)

# For adaptive icons, we need to make the icon smaller (safe area)
# Android guidelines recommend keeping important content in the center 66% (108dp out of 108dp)
# We'll use 80% of the size and center it with transparency

# Calculate dimensions for 80% content area
safe_size = int(1024 * 0.75)  # 75% to ensure safety zone
padding = (1024 - safe_size) // 2

# Create transparent canvas
foreground = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))

# Resize original to safe size
resized = img_original.resize((safe_size, safe_size), Image.Resampling.LANCZOS)

# Ensure it's RGBA
if resized.mode != 'RGBA':
    resized = resized.convert('RGBA')

# Paste in center with transparency
foreground.paste(resized, (padding, padding), resized if resized.mode == 'RGBA' else None)

# Save foreground
foreground.save('wavezly_icon_foreground.png', 'PNG', optimize=True)
print("   Saved: wavezly_icon_foreground.png")

# === 3. Extract dominant background color for adaptive icon ===
print("\n3. Analyzing dominant background color...")

# Get the corner pixels to determine background color
# (assuming the gradient background)
corner_pixels = [
    img_original.getpixel((10, 10)),
    img_original.getpixel((img_original.width - 10, 10)),
    img_original.getpixel((10, img_original.height - 10)),
    img_original.getpixel((img_original.width - 10, img_original.height - 10)),
]

# Average the RGB values (ignoring alpha if present)
avg_r = sum(p[0] for p in corner_pixels) // len(corner_pixels)
avg_g = sum(p[1] for p in corner_pixels) // len(corner_pixels)
avg_b = sum(p[2] for p in corner_pixels) // len(corner_pixels)

bg_color_hex = f"#{avg_r:02X}{avg_g:02X}{avg_b:02X}"
print(f"   Detected background color: {bg_color_hex}")

# For this yellow-orange gradient icon, we'll use a warm yellow
# Based on the image, it appears to be a yellow-orange gradient
# Let's use the lighter yellow from the top: approximately #FFD93D to #FFA726
suggested_bg = "#FFD93D"  # Warm yellow that matches the icon

print(f"   Recommended adaptive_icon_background: {suggested_bg}")

print("\nIcon conversion complete!")
print("\nGenerated files:")
print("  - wavezly_icon_1024.png (1024x1024 standard icon)")
print("  - wavezly_icon_foreground.png (1024x1024 adaptive foreground with transparency)")
print(f"\nRecommended pubspec.yaml config:")
print(f'  adaptive_icon_background: "{suggested_bg}"')
print(f'  adaptive_icon_foreground: "assets/icon/wavezly_icon_foreground.png"')
