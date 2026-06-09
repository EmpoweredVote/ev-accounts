"""
_tmp-va-execs-headshots.py
Process and upload headshots for 3 VA state executives to Supabase Storage.
Phase 104 Plan 01 — VA-GOV-06.

Processing pipeline (per feedback_headshot_resize_no_distort.md):
1. Download from official website
2. CROP to 4:5 ratio FIRST - never stretch
3. RESIZE to 600x750 Lanczos q90
4. Upload to politician_photos/{politician_id}-headshot.jpg

VA State Executives (3 officials):
  Spanberger (-510001) — governor.virginia.gov
  Hashmi    (-510002) — ltgov.virginia.gov
  Jones     (-510003) — ag.virginia.gov (WARNING: landscape 425x283 source)

Bucket: politician_photos (NOT 'politician-headshots')
Path: {politician_id}-headshot.jpg

NOTE: politician UUIDs are resolved at runtime via DB lookup
(SELECT id FROM essentials.politicians WHERE external_id = N)
because migrations 306-311 used gen_random_uuid() and UUIDs are
not known until after the migrations run.
"""

import os
import io
import sys
import time
import requests
import psycopg2
from PIL import Image

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

_env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
_env = {}
with open(_env_path) as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith('#') and '=' in line:
            k, v = line.split('=', 1)
            _env[k.strip()] = v.strip()

SUPABASE_URL = _env.get('SUPABASE_URL', '')
SERVICE_KEY = _env.get('SUPABASE_SERVICE_ROLE_KEY', '')
DATABASE_URL = _env.get('DATABASE_URL', '')
BUCKET = 'politician_photos'
CDN_BASE = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos'

TARGET_SIZE = (600, 750)
JPEG_QUALITY = 90
RESAMPLE = Image.Resampling.LANCZOS

BROWSER_HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'image/webp,image/jpeg,image/png,image/*,*/*;q=0.8',
}

DOWNLOAD_TIMEOUT = 20

# ---------------------------------------------------------------------------
# ROSTER — VA State Executives (3 officials)
# politician_id is populated at runtime via DB lookup (not hardcoded).
# Source URLs verified live 2026-06-08 per 104-RESEARCH.md.
# ---------------------------------------------------------------------------

ROSTER = [
    # ============================================================
    # VA STATE EXECUTIVES (3 officials)
    # Source URLs verified HTTP 200 on 2026-06-08 (104-RESEARCH.md)
    # ============================================================
    {
        'external_id': -510001,
        'full_name': 'Abigail Spanberger',
        'section_label': 'VA State Executives',
        'title': 'Governor',
        'politician_id': None,  # resolved at runtime via DB
        'source_url': 'https://www.governor.virginia.gov/media/governorvirginiagov/governor-of-virginia/images/Governor-Spanberger-Official-Portrait.jpg',
        'source_domain': 'governor.virginia.gov',
        'is_required': True,
    },
    {
        'external_id': -510002,
        'full_name': 'Ghazala Hashmi',
        'section_label': 'VA State Executives',
        'title': 'Lieutenant Governor',
        'politician_id': None,  # resolved at runtime via DB
        'source_url': 'https://www.ltgov.virginia.gov/media/governorvirginiagov/lieutenant-governor/Portrait-LT-Governor-Ghazala-Hashmi.jpg',
        'source_domain': 'ltgov.virginia.gov',
        'is_required': True,
    },
    {
        'external_id': -510003,
        'full_name': 'Jay Jones',
        'section_label': 'VA State Executives',
        'title': 'Attorney General',
        'politician_id': None,  # resolved at runtime via DB
        # WARNING: source is landscape 425x283 — verify quality visually after upload
        # (104-RESEARCH.md Pitfall 8: crop yields ~226x283, close to 200px minimum)
        'source_url': 'https://www.ag.virginia.gov/images/Jones-headshot-20260320.jpg',
        'source_domain': 'ag.virginia.gov',
        'is_required': True,
    },
]


# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

def download_image(url: str) -> bytes:
    """Download image from URL with browser-like User-Agent. Returns raw bytes."""
    print(f'  Downloading: {url}')
    resp = requests.get(
        url,
        headers=BROWSER_HEADERS,
        timeout=DOWNLOAD_TIMEOUT,
        allow_redirects=True,
        verify=True,
    )
    if resp.status_code != 200:
        raise Exception(f'HTTP {resp.status_code} for {url}')
    print(f'  Downloaded: {len(resp.content)} bytes, type: {resp.headers.get("content-type", "unknown")}')
    return resp.content


def crop_to_4_5(img: Image.Image) -> Image.Image:
    """
    Crop image to 4:5 aspect ratio.
    - Wider than 4:5 (landscape/square): center-crop width, keep full height
    - Taller than 4:5 (portrait): top-crop to 4:5 (eyes at ~1/3 from top)
    NEVER stretch or change aspect ratio by distortion.
    """
    w, h = img.size
    target_ratio = 4.0 / 5.0  # 0.8

    current_ratio = w / h

    if abs(current_ratio - target_ratio) < 0.001:
        return img

    if current_ratio > target_ratio:
        # Wider than 4:5: center-crop width, keep full height
        new_w = int(h * target_ratio)
        left = (w - new_w) // 2
        cropped = img.crop((left, 0, left + new_w, h))
        print(f'  Crop (center-horizontal): {w}x{h} -> {cropped.width}x{cropped.height}')
        return cropped
    else:
        # Taller than 4:5: top-crop (keep head at top, crop bottom)
        new_h = int(w / target_ratio)
        cropped = img.crop((0, 0, w, new_h))
        print(f'  Crop (top): {w}x{h} -> {cropped.width}x{cropped.height}')
        return cropped


def resize_600x750(img: Image.Image) -> Image.Image:
    """Resize image to exactly 600x750 using Lanczos resampling."""
    resized = img.resize(TARGET_SIZE, RESAMPLE)
    print(f'  Resized to: {resized.width}x{resized.height}')
    return resized


def upload_to_storage(politician_uuid: str, jpeg_bytes: bytes) -> str:
    """
    Upload JPEG to Supabase Storage at politician_photos/{politician_uuid}-headshot.jpg.
    Uses upsert=True (x-upsert header) to overwrite if file already exists.
    Bucket MUST be 'politician_photos' (NOT 'politician-headshots').
    Returns the public CDN URL.
    """
    filename = f'{politician_uuid}-headshot.jpg'
    url = f'{SUPABASE_URL}/storage/v1/object/{BUCKET}/{filename}'
    headers = {
        'Authorization': f'Bearer {SERVICE_KEY}',
        'Content-Type': 'image/jpeg',
        'x-upsert': 'true',  # overwrite if exists
    }
    resp = requests.put(url, data=jpeg_bytes, headers=headers, timeout=60)
    if resp.status_code not in (200, 201):
        raise Exception(f'Storage upload failed: {resp.status_code} {resp.text}')
    cdn_url = f'{CDN_BASE}/{filename}'
    print(f'  Uploaded to Storage: {cdn_url}')
    return cdn_url


def process_member(cursor, member: dict) -> dict:
    """
    Full pipeline for one official:
    download -> open PIL -> convert RGB -> crop 4:5 -> resize 600x750 -> upload -> return result.
    Does NOT insert politician_images DB rows (handled by migration 315).
    """
    external_id = member['external_id']
    full_name = member['full_name']
    source_url = member['source_url']
    politician_uuid = member['politician_id']

    print(f"\n{'='*60}")
    print(f"Processing: {full_name} (external_id={external_id})")
    print(f"  Section: {member['section_label']} / {member['title']}")
    print(f"  UUID: {politician_uuid}")
    print(f"  Source: {source_url}")
    print(f"  Required: {member['is_required']}")

    try:
        # 1. Download
        raw_bytes = download_image(source_url)

        # 2. Open with PIL
        img = Image.open(io.BytesIO(raw_bytes))

        # Convert to RGB (handles PNG with alpha, P-mode palette, RGBA, etc.)
        if img.mode != 'RGB':
            img = img.convert('RGB')
        print(f'  Original size: {img.width}x{img.height} mode={img.mode}')

        # 3. Validate minimum dimensions (skip if too small for quality crop)
        min_dim = 200
        if img.width < min_dim or img.height < min_dim:
            raise Exception(f'Image too small: {img.width}x{img.height} (minimum {min_dim}px)')

        # 4. Crop to 4:5 FIRST (NEVER stretch directly per feedback_headshot_resize_no_distort)
        img = crop_to_4_5(img)

        # 5. Resize to 600x750 Lanczos
        img = resize_600x750(img)

        # 6. Verify final dimensions
        assert img.size == TARGET_SIZE, f'Expected {TARGET_SIZE}, got {img.size}'

        # 7. Save as JPEG q90 to bytes buffer (re-encode strips EXIF/stego)
        buf = io.BytesIO()
        img.save(buf, format='JPEG', quality=JPEG_QUALITY, optimize=True)
        jpeg_bytes = buf.getvalue()
        print(f'  JPEG size: {len(jpeg_bytes)} bytes')

        # 8. Upload to Supabase Storage
        cdn_url = upload_to_storage(politician_uuid, jpeg_bytes)

        return {
            'external_id': external_id,
            'full_name': full_name,
            'section_label': member['section_label'],
            'politician_id': politician_uuid,
            'source_url': source_url,
            'cdn_url': cdn_url,
            'success': True,
            'skip_reason': None,
            'is_required': member['is_required'],
        }

    except Exception as e:
        print(f'  ERROR: {e}')
        return {
            'external_id': external_id,
            'full_name': full_name,
            'section_label': member['section_label'],
            'politician_id': politician_uuid,
            'source_url': source_url,
            'cdn_url': None,
            'success': False,
            'skip_reason': str(e),
            'is_required': member['is_required'],
        }


def main():
    # Validate environment
    if not SUPABASE_URL:
        print('ERROR: SUPABASE_URL not set in .env')
        sys.exit(1)
    if not SERVICE_KEY:
        print('ERROR: SUPABASE_SERVICE_ROLE_KEY not set in .env')
        sys.exit(1)
    if not DATABASE_URL:
        print('ERROR: DATABASE_URL not set in .env')
        sys.exit(1)

    print(f'[_tmp-va-execs-headshots] Phase 104 Plan 01 headshot upload')
    print(f'  Roster: {len(ROSTER)} officials (3 VA state executives)')
    print(f'  Target: {TARGET_SIZE[0]}x{TARGET_SIZE[1]} JPEG q{JPEG_QUALITY} via Lanczos')
    print(f'  Bucket: {BUCKET}')

    # Open DB connection
    db_url = DATABASE_URL
    if 'sslmode' not in db_url:
        sep = '&' if '?' in db_url else '?'
        db_url = db_url + sep + 'sslmode=require'
    conn = psycopg2.connect(db_url)
    conn.autocommit = True
    cursor = conn.cursor()

    # Resolve politician UUIDs at runtime via DB lookup
    # (migrations 306-311 used gen_random_uuid() — UUIDs not known at script-write time)
    print('\nResolving politician UUIDs from DB...')
    for member in ROSTER:
        cursor.execute(
            'SELECT id FROM essentials.politicians WHERE external_id = %s',
            (member['external_id'],)
        )
        row = cursor.fetchone()
        if not row:
            print(f'FATAL: politician not found for external_id={member["external_id"]} ({member["full_name"]})')
            cursor.close()
            conn.close()
            sys.exit(1)
        member['politician_id'] = str(row[0])
        print(f'  external_id={member["external_id"]} -> UUID={member["politician_id"]}')

    results = []
    try:
        for member in ROSTER:
            result = process_member(cursor, member)
            results.append(result)
            # Special warning for Jay Jones landscape source (104-RESEARCH.md Pitfall 8)
            if member['external_id'] == -510003 and result['success']:
                print('WARNING: source is landscape 425x283 — verify quality visually')
            time.sleep(0.5)  # polite delay between downloads
    finally:
        cursor.close()
        conn.close()

    exec_results = [r for r in results if r['section_label'] == 'VA State Executives']
    exec_success = [r for r in exec_results if r['success']]
    exec_failed = [r for r in exec_results if not r['success']]

    # Print manifest (deterministic block for Plan 05 migration 315 comments)
    print(f"\n{'='*60}")
    print('=== VA EXECS HEADSHOT MANIFEST ===')
    print()
    print('--- VA State Executives (3 officials) ---')
    for r in exec_results:
        if r['success']:
            print(f'SUCCESS: {r["external_id"]} {r["full_name"]} {r["politician_id"]} -> {r["cdn_url"]}')
        else:
            print(f'FAILED: {r["external_id"]} {r["full_name"]} -- {r["skip_reason"]}')
    print()
    print(f'TOTALS: VA Execs {len(exec_success)}/3 succeeded')
    print('=== END MANIFEST ===')

    # Hard gate: all 3 VA exec officials must succeed (is_required=True)
    required_failures = [r for r in exec_failed if r['is_required']]
    if required_failures:
        print(f'\nFATAL: {len(required_failures)} required VA exec official(s) failed — VA-GOV-06 not satisfied:')
        for r in required_failures:
            print(f'  {r["external_id"]} {r["full_name"]}: {r["skip_reason"]}')
        print('STOPPING: Do NOT proceed until all 3 VA exec headshots succeed.')
        sys.exit(1)

    print(f'\nAll 3 VA exec headshots uploaded successfully. VA-GOV-06 (exec portion) met.')


if __name__ == '__main__':
    main()
