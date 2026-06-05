"""
portland-headshots-process.py
Process and upload 14 Portland official headshots to Supabase Storage.
Uses Python PIL for image processing, requests for HTTP.
Phase 77 Plan 03.

Processing pipeline (per feedback_headshot_resize_no_distort.md):
1. Download full-size from portland.gov (drop styles/1_1_160w/ prefix)
2. CROP to 4:5 ratio FIRST - never stretch
3. RESIZE to 600x750 Lanczos q90
4. Upload to politician_photos/{politician_id}-headshot.jpg
"""
import os
import io
import sys
import json
import time
import requests
from PIL import Image

# Load env vars from backend .env
env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
env = {}
with open(env_path) as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith('#') and '=' in line:
            k, v = line.split('=', 1)
            env[k.strip()] = v.strip()

SUPABASE_URL = env['SUPABASE_URL']
SERVICE_KEY = env['SUPABASE_SERVICE_ROLE_KEY']
CDN_BASE = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos'
TMP_DIR = os.environ.get('TEMP', 'C:/Windows/Temp')

BROWSER_HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'image/webp,image/jpeg,image/*,*/*;q=0.8',
    'Referer': 'https://www.portland.gov/',
}

# Full-size /public/ files are WAF-blocked. Use Drupal 1_1_320w style URLs (320x320 square).
# These are the highest-res available from portland.gov without WAF bypass.
# Source URL for audit trail = canonical full-size path (dropping itok/style prefix).
STYLE_BASE = 'https://www.portland.gov/sites/default/files/styles/1_1_320w/public/'
FULLSIZE_BASE = 'https://www.portland.gov/sites/default/files/public/'

# 14 elected officials
# 'style_url': the 320w Drupal image style URL (works, returns 200)
# 'source_filename': original file path (used for photo_origin_url in audit migration)
OFFICIALS = [
    {
        'external_id': -690001,
        'name': 'Keith Wilson',
        'id': 'bd39d61e-3040-4ec1-815e-df16b1f9a8a0',
        'style_url': STYLE_BASE + '2024/Wilson-Blue-Background_0.png?h=99257d56&itok=WVFdB7ty',
        'source_filename': '2024/Wilson-Blue-Background_0.png',
        'license': 'public_domain',
    },
    {
        'external_id': -690002,
        'name': 'Simone Rede',
        'id': 'f797e87b-65dd-44c0-8d9d-967893d8ed3d',
        'style_url': STYLE_BASE + '2022/auditor-simone-rede_1.jpg?h=0bd0fa4f&itok=R2ePT3xu',
        'source_filename': '2022/auditor-simone-rede_1.jpg',
        'license': 'public_domain',
    },
    {
        'external_id': -690010,
        'name': 'Candace Avalos',
        'id': 'c5db367e-9403-4a88-a95f-bf864279e13b',
        'style_url': STYLE_BASE + '2025/Pink-Official-Background_0.png?h=8212257a&itok=h9HjFVsw',
        'source_filename': '2025/Pink-Official-Background_0.png',
        'license': 'public_domain',
    },
    {
        'external_id': -690011,
        'name': 'Jamie Dunphy',
        'id': '14ebbd1c-597e-483a-a846-73a7aca54ed2',
        'style_url': STYLE_BASE + '2025/Dunphy---IMG_8672---square---web.jpg?h=85b25253&itok=WgazjlT-',
        'source_filename': '2025/Dunphy---IMG_8672---square---web.jpg',
        'license': 'public_domain',
    },
    {
        'external_id': -690012,
        'name': 'Loretta Smith',
        'id': 'e6682850-601f-4017-b4e7-d9cd4be47aea',
        'style_url': STYLE_BASE + '2025/CouncilorSmithheadshot.jpg?h=a925b36f&itok=pdNPROQB',
        'source_filename': '2025/CouncilorSmithheadshot.jpg',
        'license': 'public_domain',
    },
    {
        'external_id': -690013,
        'name': 'Dan Ryan',
        'id': '60fa9870-d984-46a7-a6ed-5f6fbebe72ce',
        'style_url': STYLE_BASE + '2025/Ryan---IMG_8965---square---web.jpg?h=1db93414&itok=sIyh7tIY',
        'source_filename': '2025/Ryan---IMG_8965---square---web.jpg',
        'license': 'public_domain',
    },
    {
        'external_id': -690014,
        'name': 'Elana Pirtle-Guiney',
        'id': '987e0304-acd0-4b00-bf65-9e4fdbe4af3a',
        'style_url': STYLE_BASE + '2025/Pirtle-Guiney---IMG_8935---square---web.jpg?h=aee6e809&itok=he3Eo7Pb',
        'source_filename': '2025/Pirtle-Guiney---IMG_8935---square---web.jpg',
        'license': 'public_domain',
    },
    {
        'external_id': -690015,
        'name': 'Sameer Kanal',
        'id': 'dc00f7c1-54d1-46d8-8b35-545abdd38d8d',
        'style_url': STYLE_BASE + '2025/Kanal---IMG_9048---square---web_0.jpg?h=b74eb11d&itok=GJcT32kP',
        'source_filename': '2025/Kanal---IMG_9048---square---web_0.jpg',
        'license': 'public_domain',
    },
    {
        'external_id': -690016,
        'name': 'Angelita Morillo',
        'id': 'c6799d98-362a-4e27-b7c5-be45a82a150f',
        'style_url': STYLE_BASE + '2025/Morillo---IMG_9092---square---web.jpg?h=89151e41&itok=GaBbXykN',
        'source_filename': '2025/Morillo---IMG_9092---square---web.jpg',
        'license': 'public_domain',
    },
    {
        'external_id': -690017,
        'name': 'Steve Novick',
        'id': 'c9e19031-259e-4133-b5d9-96cf1a5f31ff',
        'style_url': STYLE_BASE + '2025/Novick---IMG_9553---square---web.jpg?h=9e2f3413&itok=WwT0tIMn',
        'source_filename': '2025/Novick---IMG_9553---square---web.jpg',
        'license': 'public_domain',
    },
    {
        'external_id': -690018,
        'name': 'Tiffany Koyama Lane',
        'id': '2947c92f-fee2-46e4-b472-9fd89a8f0f65',
        'style_url': STYLE_BASE + '2025/Koyama-Lane---IMG_9037---square---web.jpg?h=6303d4ef&itok=Pf84Fr7i',
        'source_filename': '2025/Koyama-Lane---IMG_9037---square---web.jpg',
        'license': 'public_domain',
    },
    {
        'external_id': -690019,
        'name': 'Eric Zimmerman',
        'id': '1518349b-3d63-49d0-9411-be19f86a7ea7',
        'style_url': STYLE_BASE + '2025/Profile-Photo.png?h=297da09b&itok=_0CgV5qV',
        'source_filename': '2025/Profile-Photo.png',
        'license': 'public_domain',
    },
    {
        'external_id': -690020,
        'name': 'Mitch Green',
        'id': 'acc73d7e-6522-40a9-bbe0-17cf56a96466',
        'style_url': STYLE_BASE + '2025/Green---IMG_8827---square---web.jpg?h=f28e14bd&itok=Isy4TawQ',
        'source_filename': '2025/Green---IMG_8827---square---web.jpg',
        'license': 'public_domain',
    },
    {
        'external_id': -690021,
        'name': 'Olivia Clark',
        'id': 'c06d9bab-e31e-41e7-82d6-955c9309a3d4',
        'style_url': STYLE_BASE + '2025/Clark---IMG_9110---square---web_0.jpg?h=441c11e4&itok=5ISWp2LL',
        'source_filename': '2025/Clark---IMG_9110---square---web_0.jpg',
        'license': 'public_domain',
    },
]

TARGET_W, TARGET_H = 600, 750
TARGET_RATIO = TARGET_H / TARGET_W  # 1.25 (4:5)


def download_image(official: dict) -> bytes:
    """Download 320w Drupal image style from portland.gov.
    Full-size /public/ files are WAF-blocked; 1_1_320w style URLs (320x320 square) work.
    """
    url = official['style_url']
    print(f"  Downloading: {url}")
    resp = requests.get(url, headers=BROWSER_HEADERS, timeout=30)
    if resp.status_code != 200:
        raise Exception(f"HTTP {resp.status_code} for {url}")
    print(f"  Downloaded: {len(resp.content)} bytes, type: {resp.headers.get('content-type', 'unknown')}")
    return resp.content


def process_image(raw_data: bytes, name: str) -> bytes:
    """
    Process image to 600x750 (4:5) JPEG q90.
    Rule: CROP to 4:5 FIRST, then resize to 600x750.
    Never stretch or change aspect ratio.
    Eyes should land at ~1/3 from top; full head + shoulders visible.
    """
    img = Image.open(io.BytesIO(raw_data))
    # Convert to RGB (handles PNG with alpha, P-mode palette, etc.)
    if img.mode != 'RGB':
        img = img.convert('RGB')

    w, h = img.size
    print(f"  Original: {w}x{h} ({img.mode})")

    current_ratio = h / w  # >1 = portrait, ==1 = square, <1 = landscape

    if current_ratio >= TARGET_RATIO:
        # Image is already portrait or taller than 4:5
        # Keep full width, crop height from bottom to get 4:5
        new_h = int(w * TARGET_RATIO)
        # Position from top (face is in upper portion)
        # For very tall images: take a small offset from top
        if current_ratio > 2.0:
            top = int(h * 0.05)
        elif current_ratio > 1.5:
            top = int(h * 0.02)
        else:
            top = 0
        if top + new_h > h:
            top = h - new_h
        img = img.crop((0, top, w, top + new_h))
        print(f"  Cropped portrait to: {img.size[0]}x{img.size[1]}")
    else:
        # Image is wider than 4:5 (square 1:1 or landscape)
        # Crop width to get 4:5 from the available height
        new_w = int(h / TARGET_RATIO)
        if new_w <= w:
            # Center crop horizontally (person is usually centered)
            left = (w - new_w) // 2
            img = img.crop((left, 0, left + new_w, h))
            print(f"  Cropped landscape/square to portrait: {img.size[0]}x{img.size[1]}")
        else:
            # Can't get 4:5 from height alone - use full image and pad/crop from bottom
            new_h = int(w * TARGET_RATIO)
            if new_h <= h:
                img = img.crop((0, 0, w, new_h))
                print(f"  Cropped from top: {img.size[0]}x{img.size[1]}")
            else:
                print(f"  WARNING: Cannot get 4:5 cleanly from {w}x{h}, using as-is")

    # Resize to exactly 600x750 with Lanczos
    img = img.resize((TARGET_W, TARGET_H), Image.LANCZOS)
    print(f"  Resized to: {img.size[0]}x{img.size[1]}")

    # Save as JPEG q90
    output = io.BytesIO()
    img.save(output, format='JPEG', quality=90, optimize=True)
    return output.getvalue()


def upload_to_supabase(politician_id: str, jpeg_data: bytes) -> str:
    """Upload JPEG to Supabase Storage at politician_photos/{politician_id}-headshot.jpg."""
    filename = f"{politician_id}-headshot.jpg"
    url = f"{SUPABASE_URL}/storage/v1/object/politician_photos/{filename}"
    headers = {
        'Authorization': f'Bearer {SERVICE_KEY}',
        'Content-Type': 'image/jpeg',
        'x-upsert': 'true',
    }
    resp = requests.put(url, data=jpeg_data, headers=headers, timeout=30)
    if resp.status_code not in (200, 201):
        raise Exception(f"Upload failed: {resp.status_code} {resp.text}")
    cdn_url = f"{CDN_BASE}/{filename}"
    print(f"  Uploaded: {cdn_url}")
    return cdn_url


def main():
    results = []

    for official in OFFICIALS:
        print(f"\n{'='*60}")
        print(f"Processing: {official['name']} (external_id={official['external_id']})")
        print(f"  UUID: {official['id']}")

        try:
            # 1. Download
            raw = download_image(official)

            # 2. Save original locally for audit
            orig_file = os.path.join(TMP_DIR, f"portland-orig-{official['external_id']}.jpg")
            with open(orig_file, 'wb') as f:
                f.write(raw)

            # 3. Process (crop 4:5 first, then resize 600x750 Lanczos q90)
            processed = process_image(raw, official['name'])
            print(f"  Processed JPEG: {len(processed)} bytes")

            # 4. Save processed locally for inspection
            proc_file = os.path.join(TMP_DIR, f"portland-processed-{official['id']}.jpg")
            with open(proc_file, 'wb') as f:
                f.write(processed)
            print(f"  Saved locally: {proc_file}")

            # 5. Upload to Supabase Storage
            cdn_url = upload_to_supabase(official['id'], processed)

            source_url = FULLSIZE_BASE + official['source_filename']
            results.append({
                'name': official['name'],
                'external_id': official['external_id'],
                'id': official['id'],
                'license': official['license'],
                'source_url': source_url,
                'cdn_url': cdn_url,
                'success': True,
            })

            time.sleep(0.5)  # Polite delay

        except Exception as e:
            print(f"  ERROR: {e}")
            results.append({
                'name': official['name'],
                'external_id': official['external_id'],
                'id': official['id'],
                'license': official['license'],
                'source_url': FULLSIZE_BASE + official['source_filename'],
                'cdn_url': '',
                'success': False,
                'error': str(e),
            })

    # Summary
    print(f"\n{'='*60}")
    print("SUMMARY:")
    for r in results:
        status = 'OK' if r['success'] else f"FAILED: {r.get('error', '?')}"
        print(f"  {r['name']} ({r['external_id']}): {status}")

    # Write JSON for SQL generation / audit
    output_file = os.path.join(TMP_DIR, 'portland-headshots-results.json')
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)
    print(f"\nResults saved: {output_file}")

    success_count = sum(1 for r in results if r['success'])
    print(f"\n{success_count}/{len(results)} headshots uploaded successfully")

    if success_count < len(results):
        print("\nFAILED:")
        for r in results:
            if not r['success']:
                print(f"  {r['name']}: {r.get('error', '?')}")
        sys.exit(1)


if __name__ == '__main__':
    main()
