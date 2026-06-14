"""
_tmp-lynn-headshots.py
Upload best-effort headshots for 18 Lynn officials:
  - 12 city officials (Mayor + 11 City Councilors), external_id -2537490001..-2537490012
  - 6 School Committee elected members, external_id -2507110001..-2507110006

Phase 119 Plan 03 (LYNN-02). Migration 586.

Processing pipeline (per feedback_headshot_resize_no_distort.md):
1. Download from official sources with browser User-Agent
2. CROP to 4:5 ratio FIRST — never stretch
3. RESIZE to 600x750 Lanczos q90
4. Upload to politician_photos/{politician_uuid}-headshot.jpg

lynnma.gov uses CivicLive CMS (NOT CivicEngage) — 11/11 council headshots confirmed 200 on CDN.
Mayor Nicholson has no photo on lynnma.gov; fallback is Wikipedia Commons (confirmed 200).
All 6 SC members are gaps — lynnschools.org is SchoolMessenger CMS (text-only page, no headshots).
CivicLive CDN base: https://cdnsm5-hosted2.civiclive.com/UserFiles/Servers/Server_109726/Image/Council%20Photos/

CRITICAL: Natasha Megie-Maddrey CDN filename is MegieMaddrey.png (no hyphen) — Pitfall 2 from RESEARCH.md.
         DB last_name='Megie-Maddrey' (with hyphen); CDN filename removes the hyphen.
"""

import os
import io
import sys
import time
import requests
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
    'Referer': 'https://www.lynnma.gov/',
}

BROWSER_HEADERS_DEFAULT = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'image/webp,image/jpeg,image/png,image/*,*/*;q=0.8',
}

# Wikipedia requires a descriptive User-Agent (not a browser UA) to avoid 429 rate limits
# See: https://meta.wikimedia.org/wiki/User-Agent_policy
WIKIMEDIA_HEADERS = {
    'User-Agent': 'Mozilla/5.0 (compatible; EmpoweredVoteBot/1.0; +https://empowered.vote)',
    'Accept': 'image/jpeg,image/png,image/*,*/*;q=0.8',
}

# CivicLive CDN base for Lynn City Council Photos
CIVICLIVE_CDN = 'https://cdnsm5-hosted2.civiclive.com/UserFiles/Servers/Server_109726/Image/Council%20Photos/'

# ---------------------------------------------------------------------------
# ROSTER — 18 Lynn officials
#
# City officials: Mayor + 11 City Councilors (-2537490001..-2537490012)
#   Mayor: Wikipedia Commons fallback (no lynnma.gov photo)
#   11 Councilors: CivicLive CDN (all confirmed 200)
#   CRITICAL: Megie-Maddrey CDN filename = MegieMaddrey.png (no hyphen — Pitfall 2)
#
# SC members: 6 at-large elected (-2507110001..-2507110006)
#   All 6 are gaps — lynnschools.org SchoolMessenger CMS text-only page; no headshots
# ---------------------------------------------------------------------------

ROSTER = [
    # ============================================================
    # CITY OFFICIALS — Mayor + 11 City Councilors (-2537490001..-2537490012)
    # Mayor: Wikipedia Commons (lynnma.gov has no photo)
    # Councilors: CivicLive CDN (all confirmed 200)
    # ============================================================

    # BLOCK 1: Mayor Jared Nicholson (-2537490001)
    # No photo on lynnma.gov or CivicLive CDN; fallback: Wikipedia Commons (confirmed 200)
    # Using WIKIMEDIA_HEADERS — Wikipedia requires a descriptive UA (Chrome UA returns 429)
    {
        'external_id': -2537490001,
        'full_name': 'Jared Nicholson',
        'section': 'City Council',
        'source_url': 'https://upload.wikimedia.org/wikipedia/commons/7/7f/Jared_Nicholson_1.jpg',
        'fallback_url': None,
        'headers': WIKIMEDIA_HEADERS,
    },

    # BLOCK 2: Brian M. Field (-2537490002) — At-Large
    # Confirmed 200: CivicLive CDN
    {
        'external_id': -2537490002,
        'full_name': 'Brian M. Field',
        'section': 'City Council',
        'source_url': CIVICLIVE_CDN + 'Field.png',
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
    },

    # BLOCK 3: Brian P. LaPierre (-2537490003) — At-Large
    # Confirmed 200: CivicLive CDN
    {
        'external_id': -2537490003,
        'full_name': 'Brian P. LaPierre',
        'section': 'City Council',
        'source_url': CIVICLIVE_CDN + 'LaPierre.png',
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
    },

    # BLOCK 4: Nicole D. McClain (-2537490004) — At-Large
    # Confirmed 200: CivicLive CDN
    {
        'external_id': -2537490004,
        'full_name': 'Nicole D. McClain',
        'section': 'City Council',
        'source_url': CIVICLIVE_CDN + 'McClain.png',
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
    },

    # BLOCK 5: Hong L. Net (-2537490005) — At-Large
    # Confirmed 200: CivicLive CDN
    {
        'external_id': -2537490005,
        'full_name': 'Hong L. Net',
        'section': 'City Council',
        'source_url': CIVICLIVE_CDN + 'Net.png',
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
    },

    # BLOCK 6: Peter Meaney (-2537490006) — Ward 1
    # Confirmed 200: CivicLive CDN
    {
        'external_id': -2537490006,
        'full_name': 'Peter Meaney',
        'section': 'City Council',
        'source_url': CIVICLIVE_CDN + 'Meaney.png',
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
    },

    # BLOCK 7: Obed A. Matul (-2537490007) — Ward 2
    # Confirmed 200: CivicLive CDN
    {
        'external_id': -2537490007,
        'full_name': 'Obed A. Matul',
        'section': 'City Council',
        'source_url': CIVICLIVE_CDN + 'Matul.png',
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
    },

    # BLOCK 8: Constantino Alinsug (-2537490008) — Ward 3, Council President
    # Confirmed 200: CivicLive CDN
    {
        'external_id': -2537490008,
        'full_name': 'Constantino Alinsug',
        'section': 'City Council',
        'source_url': CIVICLIVE_CDN + 'Alinsug.png',
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
    },

    # BLOCK 9: Natasha S. Megie-Maddrey (-2537490009) — Ward 4
    # CRITICAL PITFALL: CDN filename is 'MegieMaddrey.png' (no hyphen) — Pitfall 2 from RESEARCH.md
    # DB last_name='Megie-Maddrey' (with hyphen); CDN filename removes hyphen
    # Confirmed 200 with MegieMaddrey.png (NOT Megie-Maddrey.png which returns 404)
    {
        'external_id': -2537490009,
        'full_name': 'Natasha S. Megie-Maddrey',
        'section': 'City Council',
        'source_url': CIVICLIVE_CDN + 'MegieMaddrey.png',
        # NOTE: 'MegieMaddrey.png' NOT 'Megie-Maddrey.png' — confirmed 200, hyphen removed in CDN
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
    },

    # BLOCK 10: Cardeliz Paez (-2537490010) — Ward 5
    # Confirmed 200: CivicLive CDN
    {
        'external_id': -2537490010,
        'full_name': 'Cardeliz Paez',
        'section': 'City Council',
        'source_url': CIVICLIVE_CDN + 'Paez.png',
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
    },

    # BLOCK 11: Frederick W. Hogan (-2537490011) — Ward 6, Vice President
    # Confirmed 200: CivicLive CDN
    {
        'external_id': -2537490011,
        'full_name': 'Frederick W. Hogan',
        'section': 'City Council',
        'source_url': CIVICLIVE_CDN + 'Hogan.png',
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
    },

    # BLOCK 12: Jordan T. Avery (-2537490012) — Ward 7
    # Confirmed 200: CivicLive CDN
    {
        'external_id': -2537490012,
        'full_name': 'Jordan T. Avery',
        'section': 'City Council',
        'source_url': CIVICLIVE_CDN + 'Avery.png',
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
    },

    # ============================================================
    # SCHOOL COMMITTEE — 6 at-large elected (-2507110001..-2507110006)
    # All 6 are gaps — lynnschools.org uses SchoolMessenger CMS (text-only page)
    # No headshot images found on official site; no fallback per D-01
    # ============================================================

    # SC BLOCK 1: Brian K. Castellanos (-2507110001)
    {
        'external_id': -2507110001,
        'full_name': 'Brian K. Castellanos',
        'section': 'School Committee',
        'source_url': None,
        'fallback_url': None,
        'headers': BROWSER_HEADERS_DEFAULT,
        'gap_reason': 'No headshot on lynnschools.org (SchoolMessenger text-only page); no fallback per D-01',
    },

    # SC BLOCK 2: Lorraine Gately (-2507110002) — Vice Chair
    {
        'external_id': -2507110002,
        'full_name': 'Lorraine Gately',
        'section': 'School Committee',
        'source_url': None,
        'fallback_url': None,
        'headers': BROWSER_HEADERS_DEFAULT,
        'gap_reason': 'No headshot on lynnschools.org (SchoolMessenger text-only page); no fallback per D-01',
    },

    # SC BLOCK 3: Brenda Ortiz McGrath (-2507110003)
    {
        'external_id': -2507110003,
        'full_name': 'Brenda Ortiz McGrath',
        'section': 'School Committee',
        'source_url': None,
        'fallback_url': None,
        'headers': BROWSER_HEADERS_DEFAULT,
        'gap_reason': 'No headshot on lynnschools.org (SchoolMessenger text-only page); no fallback per D-01',
    },

    # SC BLOCK 4: Lennin Peña (-2507110004)
    {
        'external_id': -2507110004,
        'full_name': 'Lennin Peña',
        'section': 'School Committee',
        'source_url': None,
        'fallback_url': None,
        'headers': BROWSER_HEADERS_DEFAULT,
        'gap_reason': 'No headshot on lynnschools.org (SchoolMessenger text-only page); no fallback per D-01',
    },

    # SC BLOCK 5: Andrea L. Satterwhite (-2507110005)
    {
        'external_id': -2507110005,
        'full_name': 'Andrea L. Satterwhite',
        'section': 'School Committee',
        'source_url': None,
        'fallback_url': None,
        'headers': BROWSER_HEADERS_DEFAULT,
        'gap_reason': 'No headshot on lynnschools.org (SchoolMessenger text-only page); no fallback per D-01',
    },

    # SC BLOCK 6: Tristan J. Smith (-2507110006)
    {
        'external_id': -2507110006,
        'full_name': 'Tristan J. Smith',
        'section': 'School Committee',
        'source_url': None,
        'fallback_url': None,
        'headers': BROWSER_HEADERS_DEFAULT,
        'gap_reason': 'No headshot on lynnschools.org (SchoolMessenger text-only page); no fallback per D-01',
    },
]


# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

def download_image(url: str, headers: dict) -> bytes:
    """Download image from URL with browser User-Agent. Returns raw bytes."""
    print(f'  Downloading: {url}')
    resp = requests.get(
        url,
        headers=headers,
        timeout=30,
        allow_redirects=True,
        verify=True,
    )
    if resp.status_code != 200:
        raise Exception(f'HTTP {resp.status_code} for {url}')
    content_type = resp.headers.get('content-type', 'unknown')
    print(f'  Downloaded: {len(resp.content)} bytes, type: {content_type}')
    if 'text/html' in content_type or len(resp.content) < 1000:
        raise Exception(f'Suspicious response (content-type={content_type}, size={len(resp.content)}) — likely not an image')
    return resp.content


def crop_to_4_5(img: Image.Image) -> Image.Image:
    """
    Crop image to 4:5 aspect ratio — NEVER stretch.
    Per feedback_headshot_resize_no_distort.md:
    - Square or landscape: center-crop horizontally (preserve full height, crop sides)
    - Portrait taller than 4:5: top-crop (preserve top 4/5-height)
    """
    w, h = img.size
    target_ratio = 4.0 / 5.0  # 0.8

    current_ratio = w / h

    if abs(current_ratio - target_ratio) < 0.001:
        return img

    if current_ratio > target_ratio:
        # Wider than 4:5 (landscape or square): center-crop width, keep full height
        new_w = int(h * target_ratio)
        left = (w - new_w) // 2
        cropped = img.crop((left, 0, left + new_w, h))
        print(f'  Crop (center-width): {w}x{h} -> {cropped.width}x{cropped.height}')
        return cropped
    else:
        # Taller than 4:5 (portrait): top-crop height, keep full width
        new_h = int(w / target_ratio)
        cropped = img.crop((0, 0, w, new_h))
        print(f'  Crop (top-height): {w}x{h} -> {cropped.width}x{cropped.height}')
        return cropped


def resize_600x750(img: Image.Image) -> Image.Image:
    """Resize image to exactly 600x750 using Lanczos resampling."""
    resized = img.resize(TARGET_SIZE, RESAMPLE)
    print(f'  Resized to: {resized.width}x{resized.height}')
    return resized


def upload_to_storage(politician_uuid: str, jpeg_bytes: bytes) -> str:
    """
    Upload JPEG to Supabase Storage at politician_photos/{politician_uuid}-headshot.jpg.
    Returns the public CDN URL.
    """
    filename = f'{politician_uuid}-headshot.jpg'
    url = f'{SUPABASE_URL}/storage/v1/object/{BUCKET}/{filename}'
    headers = {
        'Authorization': f'Bearer {SERVICE_KEY}',
        'Content-Type': 'image/jpeg',
        'x-upsert': 'true',
    }
    resp = requests.put(url, data=jpeg_bytes, headers=headers, timeout=60)
    if resp.status_code not in (200, 201):
        raise Exception(f'Storage upload failed: {resp.status_code} {resp.text}')
    cdn_url = f'{CDN_BASE}/{filename}'
    print(f'  Uploaded: {cdn_url}')
    return cdn_url


def resolve_politician_id(cursor, external_id: int) -> str:
    """Resolve politician UUID from external_id via parameterized query."""
    cursor.execute(
        'SELECT id FROM essentials.politicians WHERE external_id = %s',
        (external_id,)
    )
    row = cursor.fetchone()
    if not row:
        raise Exception(f'No politician found for external_id={external_id}')
    return str(row[0])


def process_member(cursor, member: dict) -> dict:
    """
    Full pipeline for one official:
    resolve UUID -> gap-check -> download (with fallback) -> crop 4:5 -> resize 600x750
    -> re-encode JPEG q90 -> upload -> return result.

    Note: DB INSERT is handled separately in main() after all uploads complete,
    to avoid partial DB state. This script outputs UPLOADED/GAP lines for migration 586.
    """
    external_id = member['external_id']
    full_name = member['full_name']
    source_url = member.get('source_url')
    fallback_url = member.get('fallback_url')
    section = member.get('section', '')
    headers = member.get('headers', BROWSER_HEADERS_DEFAULT)
    gap_reason = member.get('gap_reason', 'No source URL')

    print(f"\n{'='*60}")
    print(f"Processing: {full_name} (external_id={external_id}, section={section})")

    try:
        # Resolve politician UUID at runtime
        politician_uuid = resolve_politician_id(cursor, external_id)
        print(f"  UUID: {politician_uuid}")

        # GAP: no source URL
        if not source_url:
            print(f"  GAP: {gap_reason}")
            return {
                'external_id': external_id,
                'full_name': full_name,
                'section': section,
                'politician_id': politician_uuid,
                'cdn_url': None,
                'success': False,
                'skip_reason': gap_reason,
            }

        # Try primary URL, fall back if needed
        raw_bytes = None
        used_url = source_url
        try:
            raw_bytes = download_image(source_url, headers)
        except Exception as primary_err:
            if fallback_url:
                print(f"  Primary failed ({primary_err}), trying fallback: {fallback_url}")
                try:
                    raw_bytes = download_image(fallback_url, BROWSER_HEADERS_DEFAULT)
                    used_url = fallback_url
                except Exception as fallback_err:
                    raise Exception(f'Primary: {primary_err}; Fallback: {fallback_err}')
            else:
                raise

        # Decode with Pillow
        img = Image.open(io.BytesIO(raw_bytes))

        # Convert to RGB (handles PNG with alpha, P-mode palette, RGBA, CMYK)
        if img.mode != 'RGB':
            img = img.convert('RGB')
        print(f'  Original size: {img.width}x{img.height} mode={img.mode}')

        # Crop to 4:5 FIRST — never stretch
        img = crop_to_4_5(img)

        # Resize to 600x750 with Lanczos
        img = resize_600x750(img)

        # Verify final dimensions
        assert img.size == TARGET_SIZE, f'Expected {TARGET_SIZE}, got {img.size}'

        # Re-encode as JPEG q90
        buf = io.BytesIO()
        img.save(buf, format='JPEG', quality=JPEG_QUALITY, optimize=True)
        jpeg_bytes = buf.getvalue()
        print(f'  JPEG size: {len(jpeg_bytes)} bytes')

        # Upload to Supabase Storage
        cdn_url = upload_to_storage(politician_uuid, jpeg_bytes)
        print(f'  SOURCE: {used_url}')

        return {
            'external_id': external_id,
            'full_name': full_name,
            'section': section,
            'politician_id': politician_uuid,
            'cdn_url': cdn_url,
            'success': True,
            'skip_reason': None,
            'source_used': used_url,
        }

    except Exception as e:
        print(f'  FAILED: {e}')
        return {
            'external_id': external_id,
            'full_name': full_name,
            'section': section,
            'politician_id': member.get('politician_id'),
            'cdn_url': None,
            'success': False,
            'skip_reason': str(e),
        }


def main():
    import psycopg2

    # Validate environment
    if not SUPABASE_URL:
        print('ERROR: SUPABASE_URL not set')
        sys.exit(1)
    if not SERVICE_KEY:
        print('ERROR: SUPABASE_SERVICE_ROLE_KEY not set')
        sys.exit(1)
    if not DATABASE_URL:
        print('ERROR: DATABASE_URL not set')
        sys.exit(1)

    print(f'[_tmp-lynn-headshots] Phase 119 — Lynn Headshots (migration 586)')
    print(f'  Total officials: {len(ROSTER)} (12 city + 6 SC)')
    print(f'  Target: {TARGET_SIZE[0]}x{TARGET_SIZE[1]} JPEG q{JPEG_QUALITY} via LANCZOS')
    print(f'  Bucket: {BUCKET}')
    print(f'  Note: CivicLive CDN accessible; 12 confirmed 200 for city (11 CDN + 1 Wikipedia Mayor); 6 SC gaps (SchoolMessenger text-only)')

    # Open DB connection with SSL
    db_url = DATABASE_URL
    if 'sslmode' not in db_url:
        sep = '&' if '?' in db_url else '?'
        db_url = db_url + sep + 'sslmode=require'
    conn = psycopg2.connect(db_url)
    conn.autocommit = True
    cursor = conn.cursor()

    results = []
    try:
        for member in ROSTER:
            result = process_member(cursor, member)
            results.append(result)
            time.sleep(0.3)
    finally:
        cursor.close()
        conn.close()

    # -----------------------------------------------------------------------
    # Print output lines for migration 586 construction
    # -----------------------------------------------------------------------
    succeeded = [r for r in results if r['success']]
    gaps = [r for r in results if not r['success']]

    print(f"\n{'='*60}")
    print('RESULTS:')
    print(f"{'='*60}")
    for r in results:
        if r['success']:
            print(f"UPLOADED: {r['external_id']} {r['full_name']} -> {r['cdn_url']}")
        else:
            print(f"GAP: {r['external_id']} {r['full_name']} -- {r['skip_reason']}")

    print(f"\nSummary: {len(succeeded)} uploaded, {len(gaps)} gaps")

    print(f"\n{'='*60}")
    print('MIGRATION 586 INSERT BLOCKS:')
    print(f"{'='*60}")
    for r in succeeded:
        print(f"""
-- {r['full_name']} ({r['section']}) — external_id {r['external_id']}
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = {r['external_id']}),
       '{r['cdn_url']}',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = {r['external_id']})
);""")

    print(f"\n{'='*60}")
    print('DOCUMENTED GAPS:')
    for r in gaps:
        print(f"-- GAP: {r['external_id']} {r['full_name']} ({r['section']}) -- {r['skip_reason']}")


if __name__ == '__main__':
    import urllib3
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    main()
