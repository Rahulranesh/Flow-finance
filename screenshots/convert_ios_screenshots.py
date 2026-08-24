import os
import glob
from PIL import Image

# Target 6.5" Display dimension required by Apple App Store Connect
TARGET_WIDTH = 1284
TARGET_HEIGHT = 2778

input_dir = "/Users/ranesh/Cashew/budget/screenshots"
output_dir = "/Users/ranesh/Cashew/budget/screenshots/ios_6.5_app_store"

os.makedirs(output_dir, exist_ok=True)

# Find PNG files
png_files = sorted(glob.glob(os.path.join(input_dir, "*.png")))

print(f"Found {len(png_files)} screenshots to process...")

for idx, filepath in enumerate(png_files, 1):
    filename = os.path.basename(filepath)
    try:
        with Image.open(filepath) as img:
            img = img.convert("RGBA")
            
            # Create a crisp canvas of 1284x2778
            canvas = Image.new("RGBA", (TARGET_WIDTH, TARGET_HEIGHT), (255, 255, 255, 255))
            
            # Resize image keeping aspect ratio
            img_ratio = img.width / img.height
            target_ratio = TARGET_WIDTH / TARGET_HEIGHT
            
            if img_ratio > target_ratio:
                # Fit by height
                new_h = TARGET_HEIGHT
                new_w = int(new_h * img_ratio)
            else:
                # Fit by width
                new_w = TARGET_WIDTH
                new_h = int(new_w / img_ratio)
                
            resized_img = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
            
            # Center on canvas
            offset_x = (TARGET_WIDTH - new_w) // 2
            offset_y = (TARGET_HEIGHT - new_h) // 2
            
            canvas.paste(resized_img, (offset_x, offset_y), resized_img)
            
            # Save final 1284x2778 PNG
            out_filename = f"app_store_6.5in_{idx:02d}_{os.path.splitext(filename)[0]}.png"
            out_filepath = os.path.join(output_dir, out_filename)
            
            canvas.convert("RGB").save(out_filepath, "PNG", quality=100)
            print(f"✅ Generated {out_filename} ({TARGET_WIDTH}x{TARGET_HEIGHT} px)")
            
    except Exception as e:
        print(f"❌ Error processing {filename}: {e}")

print("All screenshots converted successfully!")
