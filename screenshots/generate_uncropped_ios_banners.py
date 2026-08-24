import os
import glob
from PIL import Image, ImageDraw, ImageFilter

TARGET_W = 1284
TARGET_H = 2778
IN_DIR = "/Users/ranesh/Cashew/budget/screenshots"
OUT_DIR = "/Users/ranesh/Cashew/budget/screenshots/ios_6.5_app_store"

os.makedirs(OUT_DIR, exist_ok=True)

# Select key slide graphics
slides = [
    ("playstore_slide_1_welcome_enhanced.png", (248, 250, 252)),
    ("playstore_slide_2_cashflow_enhanced.png", (248, 250, 252)),
    ("playstore_slide_3_budget_enhanced.png", (248, 250, 252)),
    ("playstore_slide_4_family_enhanced.png", (248, 250, 252)),
    ("playstore_slide_5_ai_assistant_enhanced.png", (248, 250, 252)),
    ("playstore_light_banner_add_transaction.png", (241, 245, 249)),
    ("playstore_light_banner_analytics_categories.png", (241, 245, 249)),
    ("playstore_light_banner_analytics_metrics.png", (241, 245, 249)),
]

def add_rounded_corners(im, radius):
    circle = Image.new('L', (radius * 2, radius * 2), 0)
    draw = ImageDraw.Draw(circle)
    draw.ellipse((0, 0, radius * 2 - 1, radius * 2 - 1), fill=255)
    alpha = Image.new('L', im.size, 255)
    w, h = im.size
    alpha.paste(circle.crop((0, 0, radius, radius)), (0, 0))
    alpha.paste(circle.crop((0, radius, radius, radius * 2)), (0, h - radius))
    alpha.paste(circle.crop((radius, 0, radius * 2, radius)), (w - radius, 0))
    alpha.paste(circle.crop((radius, radius, radius * 2, radius * 2)), (w - radius, h - radius))
    im.putalpha(alpha)
    return im

print("Generating 1284x2778 uncropped App Store banners...")

for idx, (filename, bg_color) in enumerate(slides, 1):
    src_path = os.path.join(IN_DIR, filename)
    if not os.path.exists(src_path):
        continue
        
    with Image.open(src_path) as img:
        img = img.convert("RGBA")
        
        # Create 1284x2778 background canvas
        canvas = Image.new("RGBA", (TARGET_W, TARGET_H), bg_color + (255,))
        
        # Calculate scaling to fit within canvas with comfortable padding (width ~ 1160px)
        max_card_w = 1180
        max_card_h = 2450
        
        ratio = min(max_card_w / img.width, max_card_h / img.height)
        new_w = int(img.width * ratio)
        new_h = int(img.height * ratio)
        
        resized_img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        # Add subtle rounded corners to card
        card = add_rounded_corners(resized_img, 32)
        
        # Center horizontally and vertically
        pos_x = (TARGET_W - new_w) // 2
        pos_y = (TARGET_H - new_h) // 2
        
        # Draw soft shadow behind card
        shadow = Image.new("RGBA", (new_w + 40, new_h + 40), (0, 0, 0, 0))
        shadow_draw = ImageDraw.Draw(shadow)
        shadow_draw.rounded_rectangle([20, 20, new_w + 20, new_h + 20], radius=32, fill=(0, 0, 0, 30))
        shadow = shadow.filter(ImageFilter.GaussianBlur(16))
        
        # Paste shadow & card onto canvas
        canvas.paste(shadow, (pos_x - 20, pos_y - 15), shadow)
        canvas.paste(card, (pos_x, pos_y), card)
        
        # Save output
        out_name = f"uncropped_6.5in_slide_{idx:02d}.png"
        out_path = os.path.join(OUT_DIR, out_name)
        canvas.convert("RGB").save(out_path, "PNG", quality=100)
        print(f"✅ Generated {out_name} (1284x2778 px - 100% Uncropped)")

print("All 1284x2778 uncropped App Store banners created!")
