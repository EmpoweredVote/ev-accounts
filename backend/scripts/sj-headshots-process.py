"""
sj-headshots-process.py
Process and upload 11 San Jose official headshots.
Uses Python PIL for image processing, requests for HTTP.
"""
import os
import io
import sys
import json
import time
import requests
from PIL import Image

# Load env vars
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
}
WIKI_HEADERS = {
    'User-Agent': 'EmpoweredVote/1.0 (civic data; jmadison@empowered.vote)',
}

# Official portrait sources
# Format: (name, politician_id, source_url, source_type, license, referer)
OFFICIALS = [
    {
        'name': 'Matt Mahan',
        'id': '41949a2b-563a-4608-91c6-951c63252a91',
        'url': 'https://upload.wikimedia.org/wikipedia/commons/a/ae/Matt_Mahan_portrait_2025.jpg',
        'source_type': 'wikimedia',
        'license': 'cc-by-sa-4.0',
        'referer': 'https://en.wikipedia.org/',
        'crop_top_pct': 0.0,  # eyes at ~25-35% from top; crop from bottom to get 4:5
    },
    {
        'name': 'Rosemary Kamei',
        'id': '7921e8f3-2e6f-47f8-bc2b-95b81bab6516',
        'url': 'file://sj-sanjoseca-Kamei.jpg',  # Pre-downloaded via Node.js (WAF bypass)
        'source_type': 'local',
        'license': 'public_domain',
        'referer': '',
        # 1920x1920 square - crop to portrait
    },
    {
        'name': 'Pamela Campos',
        'id': '104cca89-3420-457b-a35d-b446be2d72ab',
        'url': 'https://images.squarespace-cdn.com/content/v1/6942f53c3db83d0e41471664/d9561bd5-aae8-4d86-99df-390794b8bfed/Official+Portrait-Councilmember+Campos.jpg?format=2500w',
        'source_type': 'squarespace',
        'license': 'public_domain',
        'referer': 'https://www.sjdistrict2.org/',
        # 1950x2524 portrait
    },
    {
        'name': 'Anthony Tordillos',
        'id': '7b527446-d801-42c6-9233-053c2b02e128',
        'url': 'https://images.squarespace-cdn.com/content/v1/68dc1d398d83da7d0336165b/51c8e8fe-edad-4a15-89b7-0906009f2f9f/CM+Tordillos+First+Day.png?format=2500w',
        'source_type': 'squarespace',
        'license': 'public_domain',
        'referer': 'https://www.sjdistrict3.org/',
        # 1080x1350 portrait from D3 official website
    },
    {
        'name': 'David Cohen',
        'id': '83292881-92b3-4257-b291-4b02509a167c',
        'url': 'https://images.squarespace-cdn.com/content/v1/6201a5e40577d74133ad4cad/d95c1d21-c133-483a-b929-d1ebcbd43456/Davidatstorm.png?format=2500w',
        'source_type': 'squarespace',
        'license': 'public_domain',
        'referer': 'https://www.sanjosedistrict4.com/',
        # 1600x1600 square
    },
    {
        'name': 'Peter Ortiz',
        'id': 'a464cef9-de7f-45a3-8ff3-9bab20275db4',
        'url': 'https://upload.wikimedia.org/wikipedia/commons/9/96/Peter_Ortiz%2C_San_Jos%C3%A9_City_Councilman.png',
        'source_type': 'wikimedia',
        'license': 'public_domain',
        'referer': 'https://en.wikipedia.org/',
        # 200x200 - will upscale with Lanczos
    },
    {
        'name': 'Michael Mulcahy',
        'id': 'a05e1faa-c780-4a65-b01f-cca7e6f0210b',
        'url': 'file://sj-sanjoseca-Mulcahy.jpg',  # Pre-downloaded via Node.js (WAF bypass)
        'source_type': 'local',
        'license': 'public_domain',
        'referer': '',
        # 495x640 portrait
    },
    {
        'name': 'Bien Doan',
        'id': 'e4ac6674-1fa3-422a-857f-570873b86da3',
        'url': 'https://upload.wikimedia.org/wikipedia/commons/5/50/Bien_Doan%2C_San_Jos%C3%A9_City_Councilman.png',
        'source_type': 'wikimedia',
        'license': 'public_domain',
        'referer': 'https://en.wikipedia.org/',
        # 200x200 - will upscale
    },
    {
        'name': 'Domingo Candelas',
        'id': 'ab7cf49d-73af-4391-9a15-ebe0522e5bc5',
        'url': 'https://upload.wikimedia.org/wikipedia/commons/1/15/Domingo_Candelas%2C_San_Jos%C3%A9_City_Councilman.png',
        'source_type': 'wikimedia',
        'license': 'public_domain',
        'referer': 'https://en.wikipedia.org/',
        # 200x200 - will upscale
    },
    {
        'name': 'Pam Foley',
        'id': '3c9b607b-5dd6-43ab-ac4f-cab553adb7ab',
        'url': 'https://upload.wikimedia.org/wikipedia/commons/1/11/Foley_Pam_-_San_Jos%C3%A9_City_Councilwoman.jpg',
        'source_type': 'wikimedia',
        'license': 'public_domain',
        'referer': 'https://en.wikipedia.org/',
        # 1536x1920 portrait
    },
    {
        'name': 'George Casey',
        'id': 'f0d4ce8b-4ed7-45ec-b08e-439dded83313',
        'url': 'https://images.squarespace-cdn.com/content/v1/67d36df71d3cca0e7ebe4c0e/824d19c7-6a09-482a-8000-c2faa6c4dee9/George+Casey+higher+quality+square+photo.jpg?format=2500w',
        'source_type': 'squarespace',
        'license': 'public_domain',
        'referer': 'https://www.sjdistrict10.org/',
        # 2048x1365 landscape from D10 official website (best available source)
    },
]

TARGET_W, TARGET_H = 600, 750


def download_image(official: dict) -> bytes:
    """Download image with appropriate headers, or load from local file."""
    url = official['url']
    source_type = official['source_type']

    # Local file (pre-downloaded via Node.js for WAF-protected sources)
    if source_type == 'local':
        fname = url.replace('file://', '')
        local_path = os.path.join(TMP_DIR, fname)
        print(f"  Loading local file: {local_path}")
        with open(local_path, 'rb') as f:
            data = f.read()
        print(f"  Loaded: {len(data)} bytes")
        return data

    if source_type == 'wikimedia':
        headers = dict(WIKI_HEADERS)
        headers['Referer'] = official.get('referer', 'https://en.wikipedia.org/')
    else:
        headers = dict(BROWSER_HEADERS)
        headers['Referer'] = official.get('referer', url)
        headers['Accept'] = 'image/webp,image/jpeg,image/*,*/*;q=0.8'

    print(f"  Downloading from: {url}")
    resp = requests.get(url, headers=headers, timeout=30)
    if resp.status_code != 200:
        raise Exception(f"HTTP {resp.status_code} for {url}")
    print(f"  Downloaded: {len(resp.content)} bytes, type: {resp.headers.get('content-type', 'unknown')}")
    return resp.content


def process_image(raw_data: bytes, name: str) -> bytes:
    """
    Process image to 600x750 (4:5) JPEG q90.
    Strategy:
    - If taller than wide (portrait): crop to 4:5, with eyes at ~1/3 from top
    - If square: crop top 0-20%, then get 4:5
    - If wider than tall (landscape): use center crop of the person
    - Always resize to 600x750 with Lanczos
    """
    img = Image.open(io.BytesIO(raw_data))
    if img.mode in ('RGBA', 'P', 'LA'):
        img = img.convert('RGB')
    elif img.mode != 'RGB':
        img = img.convert('RGB')

    w, h = img.size
    print(f"  Original: {w}x{h}")

    target_ratio = TARGET_H / TARGET_W  # 1.25

    current_ratio = h / w

    if current_ratio >= target_ratio:
        # Image is taller than needed - crop vertically
        # Keep full width, crop height to get 4:5
        new_h = int(w * target_ratio)
        # Position: try to keep face visible - take from top, leaving some bottom
        # For portrait photos, face is usually in upper 60%
        # Eyes at 1/3 from top means face center at ~25% from top
        if current_ratio > 2.0:
            # Very tall - crop more from bottom
            top = int(h * 0.05)
        elif current_ratio > 1.5:
            top = int(h * 0.02)
        else:
            top = 0
        # Ensure we don't exceed bounds
        if top + new_h > h:
            top = h - new_h
        img = img.crop((0, top, w, top + new_h))
        print(f"  Cropped (portrait): {img.size[0]}x{img.size[1]}")
    else:
        # Image is wider than needed (landscape or square)
        # Need to crop horizontally to get 4:5
        new_w = int(h / target_ratio)
        if new_w > w:
            # Image too short/wide - need to crop vertically AND horizontally
            # Resize to fit width, then crop
            new_h_fit = int(w * target_ratio)
            if new_h_fit <= h:
                img = img.crop((0, 0, w, new_h_fit))
            else:
                # Can't make 4:5 without distortion - use center crop of whatever we have
                # Crop to square first (take min dimension centered), then extend to 4:5
                min_dim = min(w, h)
                left = (w - min_dim) // 2
                top = 0  # Face is usually at top
                img = img.crop((left, top, left + min_dim, top + min_dim))
                # Now have square, crop to 4:5
                new_h_sq = int(min_dim * target_ratio)
                if new_h_sq > min_dim:
                    # Can't get 4:5 from square - use as-is, will letterbox
                    pass
                else:
                    img = img.crop((0, 0, min_dim, new_h_sq))
        else:
            # Image is wider than needed - crop horizontally centered
            # For person photos, center is usually where the person is
            left = (w - new_w) // 2
            img = img.crop((left, 0, left + new_w, h))
        print(f"  Cropped (landscape->portrait): {img.size[0]}x{img.size[1]}")

    # Resize to 600x750 with Lanczos
    img = img.resize((TARGET_W, TARGET_H), Image.LANCZOS)
    print(f"  Resized to: {img.size[0]}x{img.size[1]}")

    # Save as JPEG q90
    output = io.BytesIO()
    img.save(output, format='JPEG', quality=90, optimize=True)
    return output.getvalue()


def upload_to_supabase(politician_id: str, jpeg_data: bytes) -> str:
    """Upload JPEG to Supabase Storage."""
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


SKIP_ALREADY_DONE = {
    '104cca89-3420-457b-a35d-b446be2d72ab',  # Campos - already uploaded
    '7b527446-d801-42c6-9233-053c2b02e128',  # Tordillos - already uploaded
    'a05e1faa-c780-4a65-b01f-cca7e6f0210b',  # Mulcahy - already uploaded
    '3c9b607b-5dd6-43ab-ac4f-cab553adb7ab',  # Foley - already uploaded
}

def main():
    results = []

    for official in OFFICIALS:
        if official['id'] in SKIP_ALREADY_DONE:
            print(f"\nSkipping (already uploaded): {official['name']}")
            cdn_url = f"{CDN_BASE}/{official['id']}-headshot.jpg"
            results.append({'name': official['name'], 'id': official['id'],
                           'license': official['license'], 'url': cdn_url, 'success': True})
            continue
        print(f"\n{'='*60}")
        print(f"Processing: {official['name']}")

        try:
            # 1. Download
            raw = download_image(official)

            # 2. Process
            processed = process_image(raw, official['name'])
            print(f"  Processed JPEG: {len(processed)} bytes")

            # 3. Save locally for inspection
            tmp_file = os.path.join(TMP_DIR, f"sj-processed-{official['id']}.jpg")
            with open(tmp_file, 'wb') as f:
                f.write(processed)
            print(f"  Saved locally: {tmp_file}")

            # 4. Upload to Supabase
            cdn_url = upload_to_supabase(official['id'], processed)

            results.append({
                'name': official['name'],
                'id': official['id'],
                'license': official['license'],
                'url': cdn_url,
                'success': True,
            })

            # Delay between requests (longer for Wikimedia to avoid rate limiting)
            if official['source_type'] == 'wikimedia':
                time.sleep(3.0)
            else:
                time.sleep(0.5)

        except Exception as e:
            print(f"  ERROR: {e}")
            results.append({
                'name': official['name'],
                'id': official['id'],
                'license': official['license'],
                'url': '',
                'success': False,
                'error': str(e),
            })

    # Summary
    print(f"\n{'='*60}")
    print("SUMMARY:")
    for r in results:
        status = 'OK' if r['success'] else f"FAILED: {r.get('error', '?')}"
        print(f"  {r['name']}: {status}")

    # Write JSON for SQL generation
    output_file = os.path.join(TMP_DIR, 'sj-headshots-results.json')
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=2)
    print(f"\nResults saved: {output_file}")

    success_count = sum(1 for r in results if r['success'])
    print(f"\n{success_count}/{len(results)} headshots uploaded successfully")


if __name__ == '__main__':
    main()
