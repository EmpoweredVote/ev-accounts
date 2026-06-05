from PIL import Image
import sys

# Load the downloaded Run on Climate portrait
img = Image.open('C:/EV-Accounts/backend/scripts/tordillos-runonclimate.jpg')
print(f"Original: {img.width}x{img.height} ({img.format} {img.mode})")

w, h = img.size  # 1500x1125

# Target 4:5 crop from a 1500x1125 landscape image.
# Face is centered horizontally. We want eyes at ~1/3 from top.
# Target crop width: since image is wider than tall, use full height → crop_width = int(h * 4/5)
# 1125 * 4/5 = 900 → crop is 900x1125
# But 900x1125 would be 4:5, let's verify: 900/1125 = 0.8 = 4/5 ✓

target_ratio = 4 / 5  # width/height

# Strategy: the face is in the upper-center of the landscape image.
# Crop to 4:5 by taking full height and center-cropping width.
crop_w = int(h * target_ratio)  # 1125 * 0.8 = 900
crop_h = h  # 1125

# Center horizontally (face is centered)
x_offset = (w - crop_w) // 2  # (1500 - 900) // 2 = 300

# Crop: (left, upper, right, lower)
cropped = img.crop((x_offset, 0, x_offset + crop_w, crop_h))
print(f"After crop: {cropped.width}x{cropped.height} (ratio {cropped.width/cropped.height:.3f})")

# Resize to 600x750 with Lanczos
resized = cropped.resize((600, 750), Image.LANCZOS)
print(f"After resize: {resized.width}x{resized.height}")

# Save as JPEG q90
out_path = 'C:/EV-Accounts/backend/scripts/tordillos-headshot.jpg'
resized.save(out_path, 'JPEG', quality=90)
print(f"Saved to: {out_path}")

# Verify saved file
verify = Image.open(out_path)
print(f"Verified: {verify.width}x{verify.height} {verify.format}")
