"""
_tmp-va-federal-headshots.py
Process and upload headshots for 13 VA federal officials (2 US Senators + 11 US House Reps)
to Supabase Storage.
Phase 104 Plan 04 — VA-GOV-06.

Processing pipeline (per feedback_headshot_resize_no_distort.md):
1. Download from official source
2. CROP to 4:5 ratio FIRST - never stretch
3. RESIZE to 600x750 Lanczos q90
4. Upload to politician_photos/{politician_id}-headshot.jpg

Federal officials (external_ids -400079, -400080, -5102001 through -5102011):
  Mark Warner (US Senator)    (-400080) — unitedstates.github.io W000805
  Tim Kaine (US Senator)      (-400079) — unitedstates.github.io K000384
  Rob Wittman VA-1            (-5102001) — unitedstates.github.io W000804
  Jen Kiggans VA-2            (-5102002) — unitedstates.github.io K000399
  Bobby Scott VA-3            (-5102003) — unitedstates.github.io S000185
  Jennifer McClellan VA-4     (-5102004) — unitedstates.github.io M001227
  Ben Cline VA-5              (-5102005) — unitedstates.github.io C001118
  Morgan Griffith VA-6        (-5102006) — unitedstates.github.io G000568
  Eugene Vindman VA-7         (-5102007) — unitedstates.github.io V000138
  Don Beyer VA-8              (-5102008) — unitedstates.github.io B001292
  John McGuire VA-9           (-5102009) — unitedstates.github.io M001239
  Suhas Subramanyam VA-10     (-5102010) — unitedstates.github.io S001230
  James Walkinshaw VA-11      (-5102011) — walkinshaw.house.gov (NOT in unitedstates/images;
                                           took office Sept 2025)

Source URL notes:
  Standard (12/13): https://unitedstates.github.io/images/congress/original/{bioguide}.jpg
  Walkinshaw only:  https://walkinshaw.house.gov/uploadedphotos/highresolution/122f9b36-...
  The unitedstates.github.io mirror is the working CC0 mirror of official congressional portraits.
  Direct programmatic access to the official portrait server is blocked (returns 403).

Bucket: politician_photos (NOT 'politician-headshots')
Path: {politician_id}-headshot.jpg
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

# Standard congressional portrait mirror (CC0, not blocked unlike congress.gov)
UNITEDSTATES_BASE = 'https://unitedstates.github.io/images/congress/original/'

TARGET_SIZE = (600, 750)
JPEG_QUALITY = 90
RESAMPLE = Image.Resampling.LANCZOS

BROWSER_HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'image/webp,image/jpeg,image/png,image/*,*/*;q=0.8',
}

DOWNLOAD_TIMEOUT = 30

# ---------------------------------------------------------------------------
# FEDERAL ROSTER — 13 VA federal officials
# Bioguide IDs verified via Congress API + live unitedstates.github.io probing
# 2026-06-08. See 104-RESEARCH.md for verification provenance.
#
# CRITICAL: Direct access to the official congressional portrait server is BLOCKED. Use UNITEDSTATES_BASE.
# CRITICAL: Walkinshaw (W000831) NOT in unitedstates/images yet (Sept 2025 start).
#           Use walkinshaw.house.gov direct URL.
# CRITICAL: UUIDs resolved at runtime via DB external_id lookup (not hardcoded).
# ---------------------------------------------------------------------------

FEDERAL_ROSTER = [
    # ---- US Senators ----
    {
        'external_id': -400080,
        'full_name': 'Mark Warner',
        'title': 'US Senator',
        'section_label': 'VA Federal Officials',
        'bioguide': 'W000805',
        'source_url': UNITEDSTATES_BASE + 'W000805.jpg',
        'source_domain': 'unitedstates.github.io',
        'is_required': True,
    },
    {
        'external_id': -400079,
        'full_name': 'Tim Kaine',
        'title': 'US Senator',
        'section_label': 'VA Federal Officials',
        'bioguide': 'K000384',
        'source_url': UNITEDSTATES_BASE + 'K000384.jpg',
        'source_domain': 'unitedstates.github.io',
        'is_required': True,
    },
    # ---- US House Representatives ----
    {
        'external_id': -5102001,
        'full_name': 'Rob Wittman',
        'title': 'US Rep VA-1',
        'section_label': 'VA Federal Officials',
        'bioguide': 'W000804',
        'source_url': UNITEDSTATES_BASE + 'W000804.jpg',
        'source_domain': 'unitedstates.github.io',
        'is_required': True,
    },
    {
        'external_id': -5102002,
        'full_name': 'Jen Kiggans',
        'title': 'US Rep VA-2',
        'section_label': 'VA Federal Officials',
        'bioguide': 'K000399',
        'source_url': UNITEDSTATES_BASE + 'K000399.jpg',
        'source_domain': 'unitedstates.github.io',
        'is_required': True,
    },
    {
        'external_id': -5102003,
        'full_name': 'Bobby Scott',
        'title': 'US Rep VA-3',
        'section_label': 'VA Federal Officials',
        'bioguide': 'S000185',
        'source_url': UNITEDSTATES_BASE + 'S000185.jpg',
        'source_domain': 'unitedstates.github.io',
        'is_required': True,
    },
    {
        'external_id': -5102004,
        'full_name': 'Jennifer McClellan',
        'title': 'US Rep VA-4',
        'section_label': 'VA Federal Officials',
        'bioguide': 'M001227',
        'source_url': UNITEDSTATES_BASE + 'M001227.jpg',
        'source_domain': 'unitedstates.github.io',
        'is_required': True,
    },
    {
        'external_id': -5102005,
        'full_name': 'Ben Cline',
        'title': 'US Rep VA-5',
        'section_label': 'VA Federal Officials',
        'bioguide': 'C001118',
        'source_url': UNITEDSTATES_BASE + 'C001118.jpg',
        'source_domain': 'unitedstates.github.io',
        'is_required': True,
    },
    {
        'external_id': -5102006,
        'full_name': 'Morgan Griffith',
        'title': 'US Rep VA-6',
        'section_label': 'VA Federal Officials',
        'bioguide': 'G000568',
        'source_url': UNITEDSTATES_BASE + 'G000568.jpg',
        'source_domain': 'unitedstates.github.io',
        'is_required': True,
    },
    {
        'external_id': -5102007,
        'full_name': 'Eugene Vindman',
        'title': 'US Rep VA-7',
        'section_label': 'VA Federal Officials',
        'bioguide': 'V000138',
        'source_url': UNITEDSTATES_BASE + 'V000138.jpg',
        'source_domain': 'unitedstates.github.io',
        'is_required': True,
    },
    {
        'external_id': -5102008,
        'full_name': 'Don Beyer',
        'title': 'US Rep VA-8',
        'section_label': 'VA Federal Officials',
        'bioguide': 'B001292',
        'source_url': UNITEDSTATES_BASE + 'B001292.jpg',
        'source_domain': 'unitedstates.github.io',
        'is_required': True,
    },
    {
        'external_id': -5102009,
        'full_name': 'John McGuire',
        'title': 'US Rep VA-9',
        'section_label': 'VA Federal Officials',
        'bioguide': 'M001239',
        'source_url': UNITEDSTATES_BASE + 'M001239.jpg',
        'source_domain': 'unitedstates.github.io',
        'is_required': True,
    },
    {
        'external_id': -5102010,
        'full_name': 'Suhas Subramanyam',
        'title': 'US Rep VA-10',
        'section_label': 'VA Federal Officials',
        'bioguide': 'S001230',
        'source_url': UNITEDSTATES_BASE + 'S001230.jpg',
        'source_domain': 'unitedstates.github.io',
        'is_required': True,
    },
    # Walkinshaw: NOT in unitedstates/images yet (took office Sept 2025).
    # Use official portrait directly from walkinshaw.house.gov.
    {
        'external_id': -5102011,
        'full_name': 'James Walkinshaw',
        'title': 'US Rep VA-11',
        'section_label': 'VA Federal Officials',
        'bioguide': 'W000831',
        'source_url': 'https://walkinshaw.house.gov/uploadedphotos/highresolution/122f9b36-4502-4307-a1dd-a6c925cda981.jpg',
        'source_domain': 'walkinshaw.house.gov',
        'is_required': True,
    },
]


# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

def resolve_politician_id(cursor, external_id: int) -> str:
    """Look up politician UUID from external_id. Raises if not found."""
    cursor.execute(
        'SELECT id FROM essentials.politicians WHERE external_id = %s',
        (external_id,)
    )
    row = cursor.fetchone()
    if not row:
        raise Exception(f'No politician found for external_id={external_id}')
    return str(row[0])


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
    Full pipeline for one federal official:
    resolve UUID -> download -> open PIL -> convert RGB -> crop 4:5 -> resize 600x750
    -> upload -> return result.
    Does NOT insert politician_images DB rows (handled by migration 315).
    """
    external_id = member['external_id']
    full_name = member['full_name']
    source_url = member['source_url']
    bioguide = member['bioguide']

    print(f"\n{'='*60}")
    print(f"Processing: {full_name} (external_id={external_id})")
    print(f"  Title: {member['title']}")
    print(f"  Bioguide: {bioguide}")
    print(f"  Source domain: {member['source_domain']}")
    print(f"  Source: {source_url}")

    try:
        # 0. Resolve politician UUID from DB
        politician_uuid = resolve_politician_id(cursor, external_id)
        print(f'  UUID: {politician_uuid}')

        # 1. Download
        raw_bytes = download_image(source_url)

        # 2. Open with PIL
        img = Image.open(io.BytesIO(raw_bytes))

        # Convert to RGB (handles PNG with alpha, P-mode palette, RGBA, etc.)
        if img.mode != 'RGB':
            img = img.convert('RGB')
        print(f'  Original size: {img.width}x{img.height} mode={img.mode}')
        original_size = f'{img.width}x{img.height}'

        # 3. Validate minimum dimensions (skip if too small for quality crop)
        min_dim = 200
        if img.width < min_dim or img.height < min_dim:
            raise Exception(f'Image too small: {img.width}x{img.height} (minimum {min_dim}px)')

        # 4. Crop to 4:5 FIRST (NEVER stretch directly per feedback_headshot_resize_no_distort)
        img_before_crop_size = f'{img.width}x{img.height}'
        img = crop_to_4_5(img)
        crop_size = f'{img.width}x{img.height}'

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
            'title': member['title'],
            'bioguide': bioguide,
            'section_label': member['section_label'],
            'politician_id': politician_uuid,
            'source_url': source_url,
            'source_domain': member['source_domain'],
            'cdn_url': cdn_url,
            'original_size': original_size,
            'crop_size': crop_size,
            'success': True,
            'skip_reason': None,
            'is_required': member['is_required'],
        }

    except Exception as e:
        print(f'  ERROR: {e}')
        return {
            'external_id': external_id,
            'full_name': full_name,
            'title': member['title'],
            'bioguide': bioguide,
            'section_label': member['section_label'],
            'politician_id': None,
            'source_url': source_url,
            'source_domain': member['source_domain'],
            'cdn_url': None,
            'original_size': None,
            'crop_size': None,
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

    print(f'[_tmp-va-federal-headshots] Phase 104 Plan 04 headshot upload')
    print(f'  Roster: {len(FEDERAL_ROSTER)} federal officials (2 US Senators + 11 US House Reps)')
    print(f'  Target: {TARGET_SIZE[0]}x{TARGET_SIZE[1]} JPEG q{JPEG_QUALITY} via Lanczos')
    print(f'  Bucket: {BUCKET}')
    print(f'  Primary source (12/13): unitedstates.github.io/images/congress/original/')
    print(f'  Walkinshaw source (1/13): walkinshaw.house.gov (not yet in unitedstates/images)')

    # Open DB connection
    db_url = DATABASE_URL
    if 'sslmode' not in db_url:
        sep = '&' if '?' in db_url else '?'
        db_url = db_url + sep + 'sslmode=require'
    conn = psycopg2.connect(db_url)
    conn.autocommit = True
    cursor = conn.cursor()

    results = []
    try:
        for member in FEDERAL_ROSTER:
            result = process_member(cursor, member)
            results.append(result)
            time.sleep(0.5)  # polite delay between downloads
    finally:
        cursor.close()
        conn.close()

    successes = [r for r in results if r['success']]
    failures = [r for r in results if not r['success']]

    # Print manifest (deterministic block for Plan 05 parsing)
    print(f"\n{'='*60}")
    print('=== VA FEDERAL HEADSHOT MANIFEST ===')
    print()
    print('--- VA Federal Officials (13 officials: 2 senators + 11 reps) ---')
    for r in results:
        if r['success']:
            print(f'SUCCESS: {r["external_id"]} {r["full_name"]} {r["politician_id"]} -> {r["cdn_url"]}')
        else:
            print(f'FAILED: {r["external_id"]} {r["full_name"]} -- {r["skip_reason"]}')
    print()
    print(f'TOTALS: VA Federal {len(successes)}/13 succeeded')
    print()
    print('--- Dimension Log (original -> crop -> 600x750) ---')
    for r in results:
        if r['success']:
            print(f'  {r["external_id"]} {r["full_name"]}: original={r["original_size"]} crop={r["crop_size"]} final=600x750 source={r["source_domain"]}')
    print('=== END MANIFEST ===')

    # Hard gate: ALL 13 federal officials are required (no best-effort exceptions)
    if failures:
        print(f'\nFATAL: {len(failures)} federal official(s) failed — VA-GOV-06 not satisfied:')
        for r in failures:
            print(f'  {r["external_id"]} {r["full_name"]} [{r["bioguide"]}]: {r["skip_reason"]}')
            if r['external_id'] == -5102011:
                print(f'    NOTE: Walkinshaw (W000831) uses walkinshaw.house.gov portrait.')
                print(f'    If URL is 404, check walkinshaw.house.gov/about for current portrait URL.')
            elif r['source_domain'] == 'unitedstates.github.io':
                print(f'    NOTE: unitedstates.github.io/{r["bioguide"]}.jpg failed.')
                print(f'    Do NOT fall back to the official congressional portrait server (blocked, returns 403).')
                print(f'    Recommendation: retry; if persistent, check https://unitedstates.github.io/images/congress/original/{r["bioguide"]}.jpg in browser.')
        print('STOPPING: Do NOT proceed to migration 315 until all 13 federal headshots succeed.')
        sys.exit(1)

    print(f'\nAll 13 VA federal headshots uploaded successfully. VA-GOV-06 federal portion complete.')


if __name__ == '__main__':
    main()
