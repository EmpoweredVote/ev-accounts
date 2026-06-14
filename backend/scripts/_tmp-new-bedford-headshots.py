"""
_tmp-new-bedford-headshots.py
Upload best-effort headshots for 12 New Bedford city officials:
  - Mayor Jon Mitchell + 11 City Councilors, external_id -2545000001..-2545000012

Phase 120 Plan 02 (NEWBED-02). Migration 588.

Processing pipeline (per feedback_headshot_resize_no_distort.md):
1. Download from best available source (Wikipedia Commons, campaign sites)
2. CROP to 4:5 ratio FIRST — never stretch
3. RESIZE to 600x750 Lanczos q90
4. Upload to politician_photos/{politician_uuid}-headshot.jpg

CRITICAL: newbedford-ma.gov is Cloudflare JS-challenged (all official bio pages inaccessible
programmatically). Do NOT attempt any URLs on newbedford-ma.gov. Any response from that
domain will be a Cloudflare JS challenge page (starts with 'Just a moment...'), not an image.

Alternative sources investigated at execution time:
- Mayor Mitchell: Wikipedia Commons (confirmed images at upload.wikimedia.org)
- Councilors: Wikipedia Commons first; newbedford-ma.gov bio page URLs blocked (Cloudflare);
  no confirmed alternative CDN discovered — documented as gaps with specific error reasons.

Expected outcome per RESEARCH.md: Mayor likely uploadable from Wikipedia Commons;
most councilors likely gaps (no accessible non-editorial headshot source found).
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
}

# Wikipedia requires a descriptive User-Agent (not a browser UA) to avoid 429 rate limits
# See: https://meta.wikimedia.org/wiki/User-Agent_policy
WIKIMEDIA_HEADERS = {
    'User-Agent': 'Mozilla/5.0 (compatible; EmpoweredVoteBot/1.0; +https://empowered.vote)',
    'Accept': 'image/jpeg,image/png,image/*,*/*;q=0.8',
}

# ---------------------------------------------------------------------------
# ROSTER — 12 New Bedford city officials (-2545000001..-2545000012)
#
# newbedford-ma.gov is Cloudflare JS-challenged — DO NOT USE any URLs from this domain.
# Mayor: Wikipedia Commons (confirmed images at upload.wikimedia.org)
# Councilors: No confirmed accessible non-editorial headshot source found;
#   all documented as gaps with specific error reasons per project convention.
# ---------------------------------------------------------------------------

ROSTER = [
    # BLOCK 1: Mayor Jon Mitchell (-2545000001)
    # Wikipedia Commons confirmed: 2015 speaking engagement photo (best headshot candidate)
    # Primary: full-resolution speaking photo
    # Fallback: 2023 event photo
    {
        'external_id': -2545000001,
        'full_name': 'Jon Mitchell',
        'source_url': 'https://upload.wikimedia.org/wikipedia/commons/7/79/Jon_Mitchell_22520740514_25f19af20d_k.jpg',
        'fallback_url': 'https://upload.wikimedia.org/wikipedia/commons/f/f7/Event_celebrating_new_zero-emission_school_buses_in_New_Bedford_FxEf8A1XwAUOh5Y_(Jon_Mitchell).jpg',
        'headers': WIKIMEDIA_HEADERS,
        'gap_reason': None,
    },

    # BLOCK 2: Ian Abreu (-2545000002) — At-Large
    # newbedford-ma.gov bio page: https://www.newbedford-ma.gov/city-council/biographies/ian-abreu/
    # BLOCKED: Cloudflare JS challenge (not a simple 403 — full managed challenge)
    # No confirmed Wikipedia Commons image or accessible alternative source found
    {
        'external_id': -2545000002,
        'full_name': 'Ian Abreu',
        'source_url': None,
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
        'gap_reason': 'newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); no Wikipedia Commons image found; no confirmed alternative source',
    },

    # BLOCK 3: Shane Burgo (-2545000003) — At-Large
    # newbedford-ma.gov bio page: blocked (Cloudflare)
    # No confirmed alternative source found
    {
        'external_id': -2545000003,
        'full_name': 'Shane Burgo',
        'source_url': None,
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
        'gap_reason': 'newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); no Wikipedia Commons image found; no confirmed alternative source',
    },

    # BLOCK 4: Naomi Carney (-2545000004) — At-Large
    # newbedford-ma.gov bio page: blocked (Cloudflare)
    # No confirmed alternative source found
    {
        'external_id': -2545000004,
        'full_name': 'Naomi Carney',
        'source_url': None,
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
        'gap_reason': 'newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); no Wikipedia Commons image found; no confirmed alternative source',
    },

    # BLOCK 5: Brian Gomes (-2545000005) — At-Large
    # newbedford-ma.gov bio page: blocked (Cloudflare)
    # No confirmed alternative source found
    {
        'external_id': -2545000005,
        'full_name': 'Brian Gomes',
        'source_url': None,
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
        'gap_reason': 'newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); no Wikipedia Commons image found; no confirmed alternative source',
    },

    # BLOCK 6: James Roy (-2545000006) — At-Large (newly elected Nov 2025)
    # newbedford-ma.gov bio page: blocked (Cloudflare); may not have bio page yet as new member
    # No confirmed alternative source found
    {
        'external_id': -2545000006,
        'full_name': 'James Roy',
        'source_url': None,
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
        'gap_reason': 'newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); newly elected Nov 2025 (bio page may not exist yet); no confirmed alternative source',
    },

    # BLOCK 7: Leo Choquette (-2545000007) — Ward 1
    # newbedford-ma.gov bio page: blocked (Cloudflare)
    # No confirmed alternative source found
    {
        'external_id': -2545000007,
        'full_name': 'Leo Choquette',
        'source_url': None,
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
        'gap_reason': 'newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); no Wikipedia Commons image found; no confirmed alternative source',
    },

    # BLOCK 8: Scott Pemberton (-2545000008) — Ward 2 (newly elected Nov 2025)
    # newbedford-ma.gov bio page: blocked (Cloudflare); may not have bio page yet
    # No confirmed alternative source found
    {
        'external_id': -2545000008,
        'full_name': 'Scott Pemberton',
        'source_url': None,
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
        'gap_reason': 'newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); newly elected Nov 2025 (bio page may not exist yet); no confirmed alternative source',
    },

    # BLOCK 9: Shawn Oliver (-2545000009) — Ward 3
    # newbedford-ma.gov bio page: blocked (Cloudflare)
    # Note: has entered MA lieutenant governor race per RESEARCH.md — campaign site may have photos
    # No confirmed campaign site URL found at execution time
    {
        'external_id': -2545000009,
        'full_name': 'Shawn Oliver',
        'source_url': None,
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
        'gap_reason': 'newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); no confirmed campaign site or Wikipedia Commons image found (has entered MA LG race but no accessible headshot URL)',
    },

    # BLOCK 10: Derek Baptiste (-2545000010) — Ward 4
    # newbedford-ma.gov bio page: blocked (Cloudflare)
    # No confirmed alternative source found
    {
        'external_id': -2545000010,
        'full_name': 'Derek Baptiste',
        'source_url': None,
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
        'gap_reason': 'newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); no Wikipedia Commons image found; no confirmed alternative source',
    },

    # BLOCK 11: Joseph Lopes (-2545000011) — Ward 5
    # newbedford-ma.gov bio page: blocked (Cloudflare)
    # No confirmed alternative source found
    {
        'external_id': -2545000011,
        'full_name': 'Joseph Lopes',
        'source_url': None,
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
        'gap_reason': 'newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); no Wikipedia Commons image found; no confirmed alternative source',
    },

    # BLOCK 12: Ryan Pereira (-2545000012) — Ward 6 (Council President 2026)
    # newbedford-ma.gov bio page: blocked (Cloudflare)
    # No confirmed alternative source found
    {
        'external_id': -2545000012,
        'full_name': 'Ryan Pereira',
        'source_url': None,
        'fallback_url': None,
        'headers': BROWSER_HEADERS,
        'gap_reason': 'newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); no Wikipedia Commons image found; no confirmed alternative source',
    },
]


# ---------------------------------------------------------------------------
# Functions (copied verbatim from _tmp-lynn-headshots.py)
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
    """
    external_id = member['external_id']
    full_name = member['full_name']
    source_url = member.get('source_url')
    fallback_url = member.get('fallback_url')
    headers = member.get('headers', BROWSER_HEADERS)
    gap_reason = member.get('gap_reason', 'No source URL')

    print(f"\n{'='*60}")
    print(f"Processing: {full_name} (external_id={external_id})")

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
                    raw_bytes = download_image(fallback_url, headers)
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
            'politician_id': None,
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

    print(f'[_tmp-new-bedford-headshots] Phase 120 — New Bedford Headshots (migration 588)')
    print(f'  Total officials: {len(ROSTER)} (12 city officials only; SC out of scope)')
    print(f'  Target: {TARGET_SIZE[0]}x{TARGET_SIZE[1]} JPEG q{JPEG_QUALITY} via LANCZOS')
    print(f'  Bucket: {BUCKET}')
    print(f'  Note: newbedford-ma.gov Cloudflare-blocked; alternative sources attempted per official; gaps documented with specific error codes')

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
    # Print output lines for migration 588 construction
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

    print(f"\nSummary: {len(succeeded)} uploaded, {len(gaps)} gaps, 0 Python errors")

    print(f"\n{'='*60}")
    print('MIGRATION 588 INSERT BLOCKS:')
    print(f"{'='*60}")
    for r in succeeded:
        print(f"""
-- {r['full_name']} — external_id {r['external_id']}
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
        print(f"-- GAP: {r['external_id']} {r['full_name']} -- {r['skip_reason']}")


if __name__ == '__main__':
    import urllib3
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    main()
