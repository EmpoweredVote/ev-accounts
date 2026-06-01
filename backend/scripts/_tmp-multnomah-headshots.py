"""
_tmp-multnomah-headshots.py
Phase 83 Plan 02: Multnomah County commissioner headshot upload.

One-shot script: downloads, crops (4:5), resizes (600x750 Lanczos q90), uploads to
Supabase Storage, and inserts essentials.politician_images rows for all 5 commissioners.

Usage (from C:/EV-Accounts/backend):
    python scripts/_tmp-multnomah-headshots.py

Requirements:
    pip install Pillow requests psycopg2-binary   (all already installed)
    .env must contain: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, DATABASE_URL

Security note (T-83-07): SUPABASE_SERVICE_ROLE_KEY is loaded from .env only, never
logged. This script is deleted after audit migration 245 is written (Task 2).
"""

import os
import io
import sys
import time
import uuid
import requests
import psycopg2
from PIL import Image

# ---------------------------------------------------------------------------
# Load env vars from .env
# ---------------------------------------------------------------------------
env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
env = {}
if os.path.exists(env_path):
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                k, v = line.split('=', 1)
                env[k.strip()] = v.strip().strip('"').strip("'")

SUPABASE_URL = env.get('SUPABASE_URL') or os.environ.get('SUPABASE_URL')
SERVICE_KEY = env.get('SUPABASE_SERVICE_ROLE_KEY') or os.environ.get('SUPABASE_SERVICE_ROLE_KEY')
DATABASE_URL = env.get('DATABASE_URL') or os.environ.get('DATABASE_URL')

if not SUPABASE_URL:
    sys.stderr.write('ERROR: SUPABASE_URL not set in .env\n')
    sys.exit(1)
if not SERVICE_KEY:
    sys.stderr.write('ERROR: SUPABASE_SERVICE_ROLE_KEY not set in .env\n')
    sys.exit(1)
if not DATABASE_URL:
    sys.stderr.write('ERROR: DATABASE_URL not set in .env\n')
    sys.exit(1)

CDN_BASE = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos'
TMP_DIR = os.environ.get('TEMP', 'C:/Windows/Temp')

BROWSER_HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'image/webp,image/jpeg,image/*,*/*;q=0.8',
    'Referer': 'https://multco.us/elected/board-county-commissioners',
}

# ---------------------------------------------------------------------------
# Officials definitions (external_id, name, politician_id, primary_url, fallback_url)
#
# primary_url  = the WebP /styles/1_1_large/ URL (square crop from multco.us)
# fallback_url = underlying JPEG (strip /styles/1_1_large/ from path), may be portrait
# ---------------------------------------------------------------------------
OFFICIALS = [
    {
        'external_id': -410001,
        'full_name': 'Jessica Vega Pederson',
        'politician_id': '27f6b552-0e36-429a-a6fd-bb7108b80b35',
        'primary_url': 'https://multco.us/sites/default/files/styles/1_1_large/public/2026-01/54a2249-edit-chair-8x10-1.jpg.webp',
        'fallback_url': 'https://multco.us/sites/default/files/public/2026-01/54a2249-edit-chair-8x10-1.jpg',
    },
    {
        'external_id': -410010,
        'full_name': 'Meghan Moyer',
        'politician_id': 'bfaf8f7d-59f9-4747-925b-c546d84b58ad',
        'primary_url': 'https://multco.us/sites/default/files/styles/1_1_large/public/2026-01/moyer-2026-portrait-a2_0.jpg.webp',
        'fallback_url': 'https://multco.us/sites/default/files/public/2026-01/moyer-2026-portrait-a2_0.jpg',
    },
    {
        'external_id': -410011,
        'full_name': 'Shannon Singleton',
        'politician_id': '9c2b5568-9201-4d99-95e3-f2ecc1eaf2d3',
        'primary_url': 'https://multco.us/sites/default/files/styles/1_1_large/public/2024-12/20241202-commissioner-shannon-singleton-mn-04-4x3.jpg.webp',
        'fallback_url': 'https://multco.us/sites/default/files/public/2024-12/20241202-commissioner-shannon-singleton-mn-04-4x3.jpg',
    },
    {
        'external_id': -410012,
        'full_name': 'Julia Brim-Edwards',
        'politician_id': '0e37f57f-ccdb-4a6c-90b9-8f5fd7410080',
        'primary_url': 'https://multco.us/sites/default/files/styles/1_1_large/public/2023-06/20230526-D3-Commissioner-Jullia-Brim-Edwards-MN-%252816x9%2529.jpg.webp',
        'fallback_url': 'https://multco.us/sites/default/files/public/2023-06/20230526-D3-Commissioner-Jullia-Brim-Edwards-MN-%252816x9%2529.jpg',
    },
    {
        'external_id': -410013,
        'full_name': 'Vince Jones-Dixon',
        'politician_id': '28a723ed-300a-4ed6-8454-fca5bdb4ae4a',
        'primary_url': 'https://multco.us/sites/default/files/styles/1_1_large/public/2024-12/20241217-commissioner-vince-jones-dixon-mn-4x6.jpg.webp',
        'fallback_url': 'https://multco.us/sites/default/files/public/2024-12/20241217-commissioner-vince-jones-dixon-mn-4x6.jpg',
    },
]

TARGET_W, TARGET_H = 600, 750
TARGET_RATIO = TARGET_H / TARGET_W  # 1.25


# ---------------------------------------------------------------------------
# Image download
# ---------------------------------------------------------------------------
def download_image(url: str) -> tuple[bytes, str]:
    """
    Download image from URL. Returns (bytes, url_used).
    Raises on non-200 or HTML content-type.
    """
    resp = requests.get(url, headers=BROWSER_HEADERS, timeout=30)
    ct = resp.headers.get('content-type', '')
    if resp.status_code != 200 or 'text/html' in ct:
        raise Exception(f"HTTP {resp.status_code} content-type={ct}")
    return resp.content, url


def download_with_fallback(official: dict) -> tuple[bytes, str]:
    """
    Try fallback_url (source JPEG) first. If that fails, try primary_url (WebP).
    Returns (image_bytes, url_used).
    """
    try:
        data, url = download_image(official['fallback_url'])
        print(f"  Source: fallback JPEG — {url}")
        return data, url
    except Exception as e:
        print(f"  Fallback failed ({e}), trying primary WebP...")
        data, url = download_image(official['primary_url'])
        print(f"  Source: primary WebP — {url}")
        return data, url


# ---------------------------------------------------------------------------
# Image processing (crop to 4:5 first, then resize to 600x750)
# ---------------------------------------------------------------------------
def process_image(raw_data: bytes, name: str) -> tuple[bytes, tuple[int, int], str]:
    """
    Process image: crop to 4:5 ratio, resize to 600x750, JPEG q90.
    Returns (jpeg_bytes, (src_w, src_h), crop_method).
    """
    img = Image.open(io.BytesIO(raw_data))
    # Normalise mode (WebP/PNG may have alpha channel)
    if img.mode != 'RGB':
        img = img.convert('RGB')

    w, h = img.size
    print(f"  Source: {w}x{h} ({img.format or 'unknown'})")
    current_ratio = h / w  # >1 portrait, ==1 square, <1 landscape

    tolerance = 0.05
    crop_method = ''

    if abs(current_ratio - TARGET_RATIO) / TARGET_RATIO <= tolerance:
        # Already approximately 4:5 — no crop, just resize
        crop_method = 'no-crop (already 4:5)'

    elif current_ratio > TARGET_RATIO:
        # Portrait taller than 4:5 — top-crop: take width × 1.25 from top
        new_h = int(w * TARGET_RATIO)
        img = img.crop((0, 0, w, new_h))
        crop_method = f'top-crop {w}x{new_h} (portrait {w}x{h})'

    elif abs(current_ratio - 1.0) / 1.0 <= tolerance:
        # Square — center-crop to 4:5: take height × 0.8 centered horizontally
        new_w = int(h * 0.8)
        left = (w - new_w) // 2
        img = img.crop((left, 0, left + new_w, h))
        crop_method = f'center-crop {new_w}x{h} from square {w}x{h}'

    else:
        # Landscape (or wide portrait where h < w) — center-crop to 4:5
        # Crop width to h / 1.25, centered horizontally
        new_w = int(h / TARGET_RATIO)
        if new_w <= w:
            left = (w - new_w) // 2
            img = img.crop((left, 0, left + new_w, h))
            crop_method = f'center-crop {new_w}x{h} from landscape {w}x{h}'
        else:
            # Image shorter than needed — top-crop by taking w × 1.25 from top
            new_h = int(w * TARGET_RATIO)
            if new_h <= h:
                img = img.crop((0, 0, w, new_h))
                crop_method = f'top-crop {w}x{new_h} (wide-portrait {w}x{h})'
            else:
                # Fallback: resize directly (very short source)
                crop_method = f'no-crop fallback {w}x{h}'

    img = img.resize((TARGET_W, TARGET_H), Image.LANCZOS)
    final_w, final_h = img.size
    assert final_w == TARGET_W and final_h == TARGET_H, \
        f"Resize failed: got {final_w}x{final_h}, expected {TARGET_W}x{TARGET_H}"
    print(f"  Final: {final_w}x{final_h} — {crop_method}")

    output = io.BytesIO()
    img.save(output, format='JPEG', quality=90, optimize=True)
    return output.getvalue(), (w, h), crop_method


# ---------------------------------------------------------------------------
# Supabase Storage upload
# ---------------------------------------------------------------------------
def upload_to_storage(politician_id: str, jpeg_data: bytes) -> str:
    """Upload JPEG to Supabase Storage. Returns CDN URL."""
    filename = f"{politician_id}-headshot.jpg"
    url = f"{SUPABASE_URL}/storage/v1/object/politician_photos/{filename}"
    headers = {
        'Authorization': f'Bearer {SERVICE_KEY}',
        'Content-Type': 'image/jpeg',
        'x-upsert': 'true',
    }
    resp = requests.put(url, data=jpeg_data, headers=headers, timeout=30)
    if resp.status_code not in (200, 201):
        raise Exception(f"Storage upload failed: {resp.status_code} {resp.text}")
    cdn_url = f"{CDN_BASE}/{filename}"
    print(f"  Uploaded: {cdn_url}")
    return cdn_url


# ---------------------------------------------------------------------------
# politician_images DB insert (idempotent — skip if row already exists)
# ---------------------------------------------------------------------------
def insert_politician_image(conn, politician_id: str, url: str) -> str:
    """
    Insert politician_images row with type='default', photo_license='public_domain'.
    Skips if a row already exists for politician_id. Returns row id.
    """
    with conn.cursor() as cur:
        # Check for existing row
        cur.execute(
            "SELECT id FROM essentials.politician_images WHERE politician_id = %s",
            (politician_id,)
        )
        row = cur.fetchone()
        if row:
            existing_id = str(row[0])
            print(f"  politician_images row already exists: {existing_id} — skipping insert")
            return existing_id

        new_id = str(uuid.uuid4())
        cur.execute(
            """
            INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
            VALUES (%s, %s, %s, 'default', 'public_domain')
            """,
            (new_id, politician_id, url)
        )
        conn.commit()
        print(f"  Inserted politician_images row: {new_id}")
        return new_id


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    print("=== Multnomah County Commissioner Headshot Upload ===")
    print(f"Target: {len(OFFICIALS)} officials\n")

    conn = psycopg2.connect(DATABASE_URL, sslmode='require')

    results = []
    failed = []

    for official in OFFICIALS:
        print(f"\n--- {official['full_name']} (external_id={official['external_id']}) ---")
        print(f"  politician_id: {official['politician_id']}")

        try:
            # 1. Download (fallback JPEG first, then primary WebP)
            raw, src_url = download_with_fallback(official)
            print(f"  Downloaded: {len(raw)} bytes")

            # 2. Process: crop 4:5, resize 600x750, JPEG q90
            jpeg_data, (src_w, src_h), crop_method = process_image(raw, official['full_name'])
            print(f"  JPEG size: {len(jpeg_data)} bytes")

            # 3. Save to temp for audit
            tmp_file = os.path.join(TMP_DIR, f"multco-{official['external_id']}-processed.jpg")
            with open(tmp_file, 'wb') as f:
                f.write(jpeg_data)

            # 4. Upload to Supabase Storage (upsert)
            cdn_url = upload_to_storage(official['politician_id'], jpeg_data)

            # 5. Insert politician_images row (idempotent)
            img_id = insert_politician_image(conn, official['politician_id'], cdn_url)

            results.append({
                'external_id': official['external_id'],
                'full_name': official['full_name'],
                'politician_id': official['politician_id'],
                'src_url': src_url,
                'src_dimensions': f"{src_w}x{src_h}",
                'crop_method': crop_method,
                'cdn_url': cdn_url,
                'image_id': img_id,
                'success': True,
            })

            time.sleep(0.5)

        except Exception as e:
            print(f"  ERROR: {e}")
            failed.append(official['full_name'])
            results.append({
                'external_id': official['external_id'],
                'full_name': official['full_name'],
                'politician_id': official['politician_id'],
                'success': False,
                'error': str(e),
            })

    conn.close()

    # ---------------------------------------------------------------------------
    # Summary
    # ---------------------------------------------------------------------------
    print(f"\n{'='*60}")
    success_count = sum(1 for r in results if r['success'])
    print(f"\n{success_count}/{len(OFFICIALS)} headshots uploaded\n")

    for r in results:
        if r['success']:
            print(f"  OK  {r['full_name']} ({r['external_id']})")
            print(f"        src: {r['src_dimensions']} — {r['crop_method']}")
            print(f"        url: {r['cdn_url']}")
        else:
            print(f"  FAIL {r['full_name']} ({r['external_id']}): {r.get('error', '?')}")

    # Storage URLs for audit migration 245
    if success_count == len(OFFICIALS):
        print(f"\n{success_count}/{len(OFFICIALS)} headshots uploaded")
        print("\nStorage URLs (for audit migration 245):")
        for r in results:
            if r['success']:
                print(f"  {r['external_id']}: {r['cdn_url']}")
        sys.exit(0)
    else:
        print(f"\n{success_count}/{len(OFFICIALS)} headshots uploaded")
        print(f"\nFailed: {', '.join(failed)}")
        sys.exit(1)


if __name__ == '__main__':
    main()
