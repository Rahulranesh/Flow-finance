import os
import subprocess
from PIL import Image

TARGET_W = 1284
TARGET_H = 2778
DEVICE_ID = "7F0DE7E6-3619-4F9B-8D90-B072FA5E8E4C"
OUT_DIR = "/Users/ranesh/Cashew/budget/screenshots/ios_6.5_app_store"

os.makedirs(OUT_DIR, exist_ok=True)

tmp_raw = "/tmp/sim_screenshot_raw.png"

# Take screenshot
cmd = f"xcrun simctl io {DEVICE_ID} screenshot {tmp_raw}"
res = subprocess.run(cmd, shell=True, capture_output=True, text=True)

if res.returncode == 0 and os.path.exists(tmp_raw):
    with Image.open(tmp_raw) as img:
        img = img.convert("RGB")
        resized = img.resize((TARGET_W, TARGET_H), Image.Resampling.LANCZOS)
        out_path = os.path.join(OUT_DIR, "01_ios_live_home_1284x2778.png")
        resized.save(out_path, "PNG", quality=100)
        print(f"✅ Successfully captured & generated {out_path} ({TARGET_W}x{TARGET_H} px)")
else:
    print(f"Could not capture live screenshot: {res.stderr}")
