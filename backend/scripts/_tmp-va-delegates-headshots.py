"""
_tmp-va-delegates-headshots.py
Download, crop, resize, and upload headshots for 99 active VA House delegates
to Supabase Storage bucket 'politician_photos'.

Phase 104 Plan 03 — VA-GOV-06 (delegate portion).

Processing pipeline (per feedback_headshot_resize_no_distort.md):
1. Download from house.vga.virginia.gov/delegate_photos/{H####}.jpg
2. CROP to 4:5 ratio FIRST - never stretch
3. RESIZE to 600x750 Lanczos q90
4. Upload to politician_photos/{politician_id}-headshot.jpg

Active delegates: HD-1 through HD-100 EXCLUDING HD-20 (vacant, is_vacant=true).
external_ids: -5120001 through -5120100, EXCLUDING -5120020.

CRITICAL: Source URL is https://house.vga.virginia.gov/delegate_photos/{H####}.jpg
  - Domain is house.vga.virginia.gov (NOT bare vga.virginia.gov which returns 404)
  - {H####} is the VGA internal member ID (NOT the district number)
  - HD-1 = H0219 (NOT H0001); see DELEGATE_HID_MAP below
  - Full-res path yields 2500x2500 px images (not the thumbnail subfolder)

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
# Assertions — verified at module load time
# ---------------------------------------------------------------------------

# Complete HD-number -> H-ID mapping (scraped from house.vga.virginia.gov/members,
# verified 2026-06-08). Exactly 99 entries: keys 1..19, 21..100. Key 20 is absent.
DELEGATE_HID_MAP = {
    1: 'H0219', 2: 'H0375', 3: 'H0239', 4: 'H0208', 5: 'H0406',
    6: 'H0269', 7: 'H0370', 8: 'H0344', 9: 'H0294', 10: 'H0317',
    11: 'H0403', 12: 'H0351', 13: 'H0264', 14: 'H0108', 15: 'H0355',
    16: 'H0281', 17: 'H0405', 18: 'H0305', 19: 'H0365',
    # HD-20: VACANT (Michelle Maldonado resigned 2026-05-31) — excluded entirely per D-04, D-17
    21: 'H0382', 22: 'H0297', 23: 'H0404', 24: 'H0227', 25: 'H0343',
    26: 'H0385', 27: 'H0380', 28: 'H0301', 29: 'H0374', 30: 'H0395',
    31: 'H0377', 32: 'H0329', 33: 'H0398', 34: 'H0231', 35: 'H0321',
    36: 'H0350', 37: 'H0253', 38: 'H0266', 39: 'H0357', 40: 'H0308',
    41: 'H0393', 42: 'H0333', 43: 'H0224', 44: 'H0242', 45: 'H0056',
    46: 'H0390', 47: 'H0348', 48: 'H0384', 49: 'H0401', 50: 'H0136',
    51: 'H0383', 52: 'H0325', 53: 'H0364', 54: 'H0354', 55: 'H0371',
    56: 'H0362', 57: 'H0397', 58: 'H0327', 59: 'H0259', 60: 'H0328',
    61: 'H0247', 62: 'H0394', 63: 'H0342', 64: 'H0388', 65: 'H0314',
    66: 'H0389', 67: 'H0369', 68: 'H0238', 69: 'H0392', 70: 'H0323',
    71: 'H0386', 72: 'H0124', 73: 'H0396', 74: 'H0335', 75: 'H0391',
    76: 'H0361', 77: 'H0402', 78: 'H0212', 79: 'H0356', 80: 'H0372',
    81: 'H0207', 82: 'H0399', 83: 'H0347', 84: 'H0336', 85: 'H0284',
    86: 'H0400', 87: 'H0173', 88: 'H0322', 89: 'H0387', 90: 'H0262',
    91: 'H0285', 92: 'H0353', 93: 'H0349', 94: 'H0366', 95: 'H0311',
    96: 'H0295', 97: 'H0360', 98: 'H0407', 99: 'H0345', 100: 'H0267',
}

# Guard assertions — fail immediately if map is malformed
assert 20 not in DELEGATE_HID_MAP, 'HD-20 must be absent from DELEGATE_HID_MAP per D-04'
assert len(DELEGATE_HID_MAP) == 99, f'Expected 99 delegate entries, got {len(DELEGATE_HID_MAP)}'
assert DELEGATE_HID_MAP[1] == 'H0219', f'HD-1 expected H0219, got {DELEGATE_HID_MAP[1]}'
assert DELEGATE_HID_MAP[100] == 'H0267', f'HD-100 expected H0267, got {DELEGATE_HID_MAP[100]}'

# Canonical names from migration 308_va_delegates.sql.
# HD-20 is absent — do NOT add a Maldonado entry.
DELEGATE_NAMES = {
    1: 'Patrick A. Hope',
    2: 'Adele Y. McClure',
    3: 'Alfonso H. Lopez',
    4: 'Charniele L. Herring',
    5: 'R. Kirk McPike',
    6: 'Richard C. Sullivan, Jr.',
    7: 'Karen Keys-Gamarra',
    8: 'Irene Shin',
    9: 'Karrie K. Delaney',
    10: 'Dan Helmer',
    11: 'Gretchen M. Bulova',
    12: 'Holly M. Seibold',
    13: 'Marcus B. Simon',
    14: 'Vivian E. Watts',
    15: 'Laura Jane Cohen',
    16: 'Paul E. Krizek',
    17: 'Garrett McGuire',
    18: 'Kathy KL Tran',
    19: 'Rozia A. Henson, Jr.',
    # 20: VACANT — absent
    21: 'Josh Thomas',
    22: 'Elizabeth R. Guzman',
    23: 'Margaret Angela Franklin',
    24: 'Luke E. Torian',
    25: 'Briana D. Sewell',
    26: 'JJ Singh',
    27: 'Atoosa R. Reaser',
    28: 'David A. Reid',
    29: 'Fernando J. Martinez',
    30: 'John C McAuliff',
    31: 'Delores Oates',
    32: 'William D. Wiley',
    33: 'Justin L. Pence',
    34: 'Tony O. Wilt',
    35: 'Chris Runion',
    36: 'Ellen H. McLaughlin',
    37: 'Terry L. Austin',
    38: 'Sam Rasoul',
    39: 'Will P. Davis',
    40: 'Joseph P. McNamara',
    41: 'Lily V. Franklin',
    42: 'Jason S. Ballard',
    43: 'James W. Morefield',
    44: "Israel D. O'Quinn",
    45: 'Terry G. Kilgore',
    46: 'Mitchell Cornett',
    47: 'Wren M. Williams',
    48: 'Eric J. Phillips',
    49: 'Madison Whittle',
    50: 'Thomas C. Wright, Jr.',
    51: 'Eric Zehr',
    52: 'Wendell S. Walker',
    53: 'Timothy P. Griffin',
    54: 'Katrina E. Callsen',
    55: 'Amy J. Laufer',
    56: 'Thomas A. Garrett, Jr.',
    57: 'May Nivar',
    58: 'Rodney T. Willett',
    59: 'Hyland F. Fowler, Jr.',
    60: 'Scott A. Wyatt',
    61: 'Michael J. Webert',
    62: 'Karen Fleming Hamilton',
    63: 'Phillip A. Scott',
    64: 'Stacey A. Carroll',
    65: 'Joshua G. Cole',
    66: 'Nicole Cole',
    67: 'Hillary Pugh Kent',
    68: 'M. Keith Hodges',
    69: 'Mark C. Downey',
    70: 'Shelly A. Simonds',
    71: 'Jessica L. Anderson',
    72: 'R. Lee Ware',
    73: 'Leslie Chambers Mehta',
    74: 'Mike A. Cherry',
    75: 'Lindsey Dougherty',
    76: 'Debra D. Gardner',
    77: 'Charles H. Schmidt, Jr.',
    78: 'Betsy B. Carr',
    79: 'Rae C. Cousins',
    80: 'Destiny L. LeVere Bolling',
    81: 'Delores L. McQuinn',
    82: 'Kimberly Pope Adams',
    83: 'Howard Otto Wachsmann, Jr.',
    84: 'Nadarius E. Clark',
    85: 'Marcia S. Price',
    86: 'Virgil Gene Thornton, Sr.',
    87: 'Jeion A. Ward',
    88: 'Don Scott',
    89: 'Karen Robins Carnegie',
    90: 'James A. Leftwich, Jr.',
    91: 'C. E. Hayes, Jr.',
    92: 'Bonita G. Anthony',
    93: 'Jackie Hope Glass',
    94: 'Phil M. Hernandez',
    95: 'Alex Q. Askew',
    96: 'Kelly K. Convirs-Fowler',
    97: 'Michael Feggans',
    98: 'Andrew Rice',
    99: 'Anne Ferrell H. Tata',
    100: 'Robert S. Bloxom, Jr.',
}

assert 20 not in DELEGATE_NAMES, 'HD-20 must be absent from DELEGATE_NAMES per D-04'
assert len(DELEGATE_NAMES) == 99, f'Expected 99 name entries, got {len(DELEGATE_NAMES)}'

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

DELEGATE_PHOTO_BASE = 'https://house.vga.virginia.gov/delegate_photos/'

TARGET_SIZE = (600, 750)
JPEG_QUALITY = 90
RESAMPLE = Image.Resampling.LANCZOS

BROWSER_HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'image/webp,image/jpeg,image/png,image/*,*/*;q=0.8',
}

DOWNLOAD_TIMEOUT = 30


# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

def resolve_politician_id(cursor, external_id: int) -> str:
    """Look up politician UUID from essentials.politicians by external_id."""
    cursor.execute(
        'SELECT id FROM essentials.politicians WHERE external_id = %s',
        (external_id,)
    )
    row = cursor.fetchone()
    if not row:
        raise Exception(f'No politician found with external_id={external_id}')
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


def process_delegate(cursor, district: int) -> dict:
    """
    Full pipeline for one delegate:
    resolve UUID -> download -> open PIL -> convert RGB -> crop 4:5 -> resize 600x750 -> upload -> return result.
    Does NOT insert politician_images DB rows (handled by migration 315).
    """
    h_id = DELEGATE_HID_MAP[district]
    full_name = DELEGATE_NAMES[district]
    external_id = -5120000 - district
    source_url = DELEGATE_PHOTO_BASE + h_id + '.jpg'

    print(f"\n{'='*60}")
    print(f"Processing: HD-{district} {full_name} (external_id={external_id})")
    print(f"  H-ID: {h_id}")
    print(f"  Source: {source_url}")

    try:
        # Resolve politician UUID from DB
        politician_uuid = resolve_politician_id(cursor, external_id)
        print(f'  UUID: {politician_uuid}')

        # 1. Download
        raw_bytes = download_image(source_url)

        # 2. Open with PIL
        img = Image.open(io.BytesIO(raw_bytes))

        # Convert to RGB (handles PNG with alpha, P-mode palette, RGBA, etc.)
        if img.mode != 'RGB':
            img = img.convert('RGB')
        original_dims = f'{img.width}x{img.height}'
        print(f'  Original size: {img.width}x{img.height} mode={img.mode}')

        # 3. Validate minimum dimensions (skip if too small for quality crop)
        min_dim = 200
        if img.width < min_dim or img.height < min_dim:
            raise Exception(f'Image too small: {img.width}x{img.height} (minimum {min_dim}px)')

        # 4. Crop to 4:5 FIRST (NEVER stretch directly per feedback_headshot_resize_no_distort)
        img = crop_to_4_5(img)
        crop_dims = f'{img.width}x{img.height}'

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
            'district': district,
            'h_id': h_id,
            'external_id': external_id,
            'full_name': full_name,
            'politician_id': politician_uuid,
            'source_url': source_url,
            'cdn_url': cdn_url,
            'original_dims': original_dims,
            'crop_dims': crop_dims,
            'success': True,
            'error': None,
        }

    except Exception as e:
        print(f'  ERROR: {e}')
        return {
            'district': district,
            'h_id': h_id,
            'external_id': external_id,
            'full_name': full_name,
            'politician_id': None,
            'source_url': source_url,
            'cdn_url': None,
            'original_dims': None,
            'crop_dims': None,
            'success': False,
            'error': str(e),
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

    print(f'[_tmp-va-delegates-headshots] Phase 104 Plan 03 headshot upload')
    print(f'  Roster: 99 VA House delegates (HD-1..HD-100 excluding HD-20 vacant)')
    print(f'  Source: {DELEGATE_PHOTO_BASE}{{H####}}.jpg')
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

    # Sanity check: confirm HD-20 is still vacant in DB
    cursor.execute(
        'SELECT COUNT(*) FROM essentials.politicians WHERE external_id = %s AND is_vacant = true',
        (-5120020,)
    )
    hd20_vacant_count = cursor.fetchone()[0]
    if hd20_vacant_count != 1:
        print(f'  NOTE: HD-20 vacancy check: expected 1, got {hd20_vacant_count}')
        print(f'  (HD-20 is still excluded regardless — per D-04/D-17)')
    else:
        print(f'  HD-20 confirmed still vacant in DB (is_vacant=true)')

    results = []
    districts_in_order = sorted(DELEGATE_HID_MAP.keys())  # 99 districts: 1-19, 21-100

    try:
        for district in districts_in_order:
            result = process_delegate(cursor, district)
            results.append(result)
            time.sleep(0.5)  # polite delay between downloads (~50s total overhead for 99)
    finally:
        cursor.close()
        conn.close()

    # Tally results
    successes = [r for r in results if r['success']]
    failures = [r for r in results if not r['success']]

    # Print manifest block (deterministic, parseable by Plan 05)
    print(f"\n{'='*60}")
    print('=== VA DELEGATES HEADSHOT MANIFEST ===')
    print()
    print(f'--- VA House of Delegates ({len(districts_in_order)} active delegates, HD-20 excluded) ---')
    for r in results:
        if r['success']:
            print(f'SUCCESS: {r["external_id"]} HD-{r["district"]} {r["full_name"]} {r["politician_id"]} -> {r["cdn_url"]}')
        else:
            print(f'FAILED: {r["external_id"]} HD-{r["district"]} {r["full_name"]} -- {r["error"]}')
    print()
    print(f'TOTALS: VA Delegates {len(successes)}/99 succeeded')
    if failures:
        print(f'FAILURES ({len(failures)}):')
        for r in failures:
            print(f'  HD-{r["district"]} (ext={r["external_id"]}) {r["full_name"]}: {r["error"]}')
    print('=== END MANIFEST ===')

    # Hard gate: all 99 delegates must succeed (VA-GOV-06)
    if len(successes) < 99:
        failing_districts = [r['district'] for r in failures]
        print(f'\nFATAL: Only {len(successes)}/99 delegate headshots succeeded.')
        print(f'Failing districts: {failing_districts}')
        print('VA-GOV-06 requirement not satisfied. Fix failures before proceeding.')
        sys.exit(1)

    print(f'\nAll 99 VA delegate headshots uploaded successfully.')
    print('VA-GOV-06 delegate portion complete.')


if __name__ == '__main__':
    main()
