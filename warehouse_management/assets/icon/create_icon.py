from PIL import Image, ImageDraw, ImageFont
import math

# Create 1024x1024 image
size = 1024
img = Image.new('RGB', (size, size))
draw = ImageDraw.Draw(img)

# Create gradient background (teal)
for y in range(size):
    # Gradient from #2DD4BF to #0D9488
    r = int(45 + (13 - 45) * y / size)
    g = int(212 + (148 - 212) * y / size)
    b = int(191 + (136 - 191) * y / size)
    draw.rectangle([(0, y), (size, y+1)], fill=(r, g, b))

# Draw wave patterns
for i in range(4):
    y_offset = 200 + i * 150
    points = []
    for x in range(0, size + 1, 10):
        y = y_offset + math.sin((x + i * 100) * 0.01) * 50
        points.append((x, y))
    
    if len(points) > 1:
        draw.line(points, fill=(255, 255, 255, 50), width=3)

# Draw white circle
center = (size // 2, size // 2)
radius = 380
draw.ellipse([center[0] - radius, center[1] - radius,
              center[0] + radius, center[1] + radius],
             fill=(255, 255, 255))

# Try to draw "W" text
try:
    # Try to use a font, fallback to default if not available
    try:
        font = ImageFont.truetype("arial.ttf", 400)
    except:
        font = ImageFont.load_default()
    
    # Draw "W" in teal color
    text = "W"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    text_x = (size - text_width) // 2
    text_y = (size - text_height) // 2 - 50
    
    draw.text((text_x, text_y), text, fill=(45, 212, 191), font=font)
except Exception as e:
    # Fallback: draw simple "W" shape with lines
    draw.line([(312, 350), (412, 650)], fill=(45, 212, 191), width=40)
    draw.line([(412, 650), (512, 450)], fill=(45, 212, 191), width=40)
    draw.line([(512, 450), (612, 650)], fill=(45, 212, 191), width=40)
    draw.line([(612, 650), (712, 350)], fill=(45, 212, 191), width=40)

# Draw wave accent
points = []
for x in range(312, 713, 10):
    if x < 512:
        y = 680 + math.sin((x - 312) / 200 * math.pi) * -30
    else:
        y = 680 + math.sin((x - 312) / 200 * math.pi) * -30
    points.append((x, int(y)))

if len(points) > 1:
    draw.line(points, fill=(13, 148, 136), width=8)

# Save the image
img.save('wavezly_icon_1024.png', 'PNG')
print("Icon generated successfully: wavezly_icon_1024.png")
