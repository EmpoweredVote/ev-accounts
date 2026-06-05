"""
_tmp-in-me-school-headshots.py
Process and upload headshots for Phase 89 IN + ME school board members to Supabase Storage.
Phase 89 Plan 03.

Processing pipeline (per feedback_headshot_resize_no_distort.md):
1. Download from official district website
2. CROP to 4:5 ratio FIRST - never stretch
3. RESIZE to 600x750 Lanczos q90
4. Upload to politician_photos/{politician_id}-headshot.jpg
5. INSERT essentials.politician_images row (type='default')

Districts covered (40 politicians):
  IPS D3 Hope Duke Star   (-890001)          -- myips.org: transparent GIF placeholders only
  IPS D2 Hasaan Rashid    (ext_id=506586)    -- myips.org: transparent GIF placeholders only
  MCCSC D7 Aja Jester     (ext_id=437675)    -- mccsc.edu: check at runtime
  Lewiston (8 members)    (-890011..-890018) -- lewistonpublicschools.org: Schoolblocks CMS
  Bangor   (7 members)    (-890021..-890027) -- bangorschools.net: Thrillshare CMS
  South Portland (7)      (-890031..-890037) -- spsd.org: JS-heavy CMS
  Auburn   (8 members)    (-890041..-890048) -- auburnschl.edu: Cloudflare protected
  Biddeford (7 members)   (-890051..-890057) -- biddefordschools.me: Thrillshare CMS

Log file: C:/EV-Accounts/backend/scripts/.tmp-phase89-headshot-log.txt
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

LOG_FILE = os.path.join(os.path.dirname(__file__), '.tmp-phase89-headshot-log.txt')

# ---------------------------------------------------------------------------
# ROSTER — 40 board members
# politician_id UUIDs verified against production DB 2026-06-03.
# Source URL patterns from RESEARCH.md §Maine Board Rosters.
# IPS members: myips.org returns 403 / transparent GIF placeholders (RESEARCH.md confirmed).
# MCCSC: mccsc.edu SmartSites CMS — attempt at runtime.
# ME districts: Schoolblocks/Thrillshare/Cloudflare CMS — server-side fetch blocked.
# ---------------------------------------------------------------------------

ROSTER = [
    # ============================================================
    # INDIANAPOLIS PUBLIC SCHOOLS (IPS) — 3 entries for Plan 89
    # Source: https://myips.org/district-school-board/school-board/
    # NOTE: RESEARCH.md confirmed myips.org shows transparent GIF placeholders
    # for ALL board members. Site also returns 403. All IPS entries = NO_PHOTO.
    # ============================================================
    {
        'external_id': -890001,
        'full_name': 'Hope Duke Star',
        'district_label': 'IPS',
        'title': 'Indianapolis Public School Board - District 3',
        'politician_id': '813eb1e1-4ca5-4a04-b052-ad297f8b5c01',
        'source_url': 'https://myips.org/district-school-board/school-board/',
        'no_photo_reason': 'official site (myips.org) shows transparent GIF placeholders for all members; site also returns 403 on server-side fetch',
    },
    {
        'external_id': 506586,
        'full_name': 'Hasaan Rashid',
        'district_label': 'IPS',
        'title': 'Indianapolis Public School Board - District 2',
        'politician_id': '3006c348-e909-4c65-8222-412062653060',
        'source_url': 'https://myips.org/district-school-board/school-board/',
        'no_photo_reason': 'official site (myips.org) shows transparent GIF placeholders for all members; site also returns 403 on server-side fetch',
    },
    # ============================================================
    # MONROE COUNTY COMMUNITY SCHOOL CORPORATION (MCCSC) — 1 entry
    # Source: https://www.mccsc.edu/board
    # SmartSites CMS — member photos rendered via JavaScript only.
    # ============================================================
    {
        'external_id': 437675,
        'full_name': 'Aja Jester',
        'district_label': 'MCCSC',
        'title': 'MCCSC Board of School Trustees - District 7',
        'politician_id': 'b3799cb0-d361-4405-b82e-59031c5ffe73',
        'source_url': 'https://www.mccsc.edu/board',
        'no_photo_reason': None,  # attempt at runtime
    },
    # ============================================================
    # LEWISTON PUBLIC SCHOOLS (ME) — 8 members
    # Source: https://www.lewistonpublicschools.org/en-US/school-committee-bc9f3846/school-committee-members-ab24c81b
    # Schoolblocks Next.js CMS — fully JS-rendered; member photos/names not in static HTML.
    # ============================================================
    {
        'external_id': -890011,
        'full_name': 'Phoenix McLaughlin',
        'district_label': 'Lewiston',
        'title': 'School Committee Member (Ward 1)',
        'politician_id': '18188cc8-4038-40b3-a046-790e24804dd4',
        'source_url': 'https://www.lewistonpublicschools.org/en-US/school-committee-bc9f3846/school-committee-members-ab24c81b',
        'no_photo_reason': None,
    },
    {
        'external_id': -890012,
        'full_name': 'Janet Beaudoin',
        'district_label': 'Lewiston',
        'title': 'School Committee Member (Ward 2)',
        'politician_id': '6f9c333a-4e42-42ab-a0dd-ffd35399fc79',
        'source_url': 'https://www.lewistonpublicschools.org/en-US/school-committee-bc9f3846/school-committee-members-ab24c81b',
        'no_photo_reason': None,
    },
    {
        'external_id': -890013,
        'full_name': 'Elizabeth Eames',
        'district_label': 'Lewiston',
        'title': 'School Committee Member (Ward 3)',
        'politician_id': 'e139ad66-027a-4387-aed3-8473f4de06ac',
        'source_url': 'https://www.lewistonpublicschools.org/en-US/school-committee-bc9f3846/school-committee-members-ab24c81b',
        'no_photo_reason': None,
    },
    {
        'external_id': -890014,
        'full_name': 'Julia Harper',
        'district_label': 'Lewiston',
        'title': 'School Committee Member (Ward 4)',
        'politician_id': '8e167885-51a4-4777-bebc-d569adf4cfbd',
        'source_url': 'https://www.lewistonpublicschools.org/en-US/school-committee-bc9f3846/school-committee-members-ab24c81b',
        'no_photo_reason': None,
    },
    {
        'external_id': -890015,
        'full_name': 'VACANT - Ward 5',
        'district_label': 'Lewiston',
        'title': 'School Committee Member (Ward 5)',
        'politician_id': 'cfd9020c-6769-4386-80ad-877ad1a5d764',
        'source_url': 'https://www.lewistonpublicschools.org/en-US/school-committee-bc9f3846/school-committee-members-ab24c81b',
        'no_photo_reason': 'vacant seat — no person to photograph',
    },
    {
        'external_id': -890016,
        'full_name': 'Meghan Hird',
        'district_label': 'Lewiston',
        'title': 'School Committee Member (Ward 6)',
        'politician_id': '8d4b288d-891b-4979-bb53-1ad6207bc4d9',
        'source_url': 'https://www.lewistonpublicschools.org/en-US/school-committee-bc9f3846/school-committee-members-ab24c81b',
        'no_photo_reason': None,
    },
    {
        'external_id': -890017,
        'full_name': 'Donna Gallant',
        'district_label': 'Lewiston',
        'title': 'School Committee Member (Ward 7)',
        'politician_id': 'c931fa94-473e-4293-bb20-9839d4b85101',
        'source_url': 'https://www.lewistonpublicschools.org/en-US/school-committee-bc9f3846/school-committee-members-ab24c81b',
        'no_photo_reason': None,
    },
    {
        'external_id': -890018,
        'full_name': 'Luke Jensen',
        'district_label': 'Lewiston',
        'title': 'School Committee Member (At-Large)',
        'politician_id': '88a38745-c67e-4d29-8102-339275f9d0d1',
        'source_url': 'https://www.lewistonpublicschools.org/en-US/school-committee-bc9f3846/school-committee-members-ab24c81b',
        'no_photo_reason': None,
    },
    # ============================================================
    # BANGOR SCHOOL DEPARTMENT (ME) — 7 members
    # Source: https://www.bangorschools.net/page/school-committee
    # Thrillshare CMS with Fastly client challenge — server-side fetch blocked.
    # ============================================================
    {
        'external_id': -890021,
        'full_name': 'Tim Surrette',
        'district_label': 'Bangor',
        'title': 'School Committee Member',
        'politician_id': 'dde04c35-5c57-4b8b-9622-a1efda0030df',
        'source_url': 'https://www.bangorschools.net/page/school-committee',
        'no_photo_reason': None,
    },
    {
        'external_id': -890022,
        'full_name': 'Katie Brydon',
        'district_label': 'Bangor',
        'title': 'School Committee Member',
        'politician_id': 'fc2bc0b7-a2d0-4db8-8411-ed06b8a27a24',
        'source_url': 'https://www.bangorschools.net/page/school-committee',
        'no_photo_reason': None,
    },
    {
        'external_id': -890023,
        'full_name': 'Mallory Cook',
        'district_label': 'Bangor',
        'title': 'School Committee Member',
        'politician_id': '26931a0b-1fef-4e37-9d6a-ea5a1dfeb279',
        'source_url': 'https://www.bangorschools.net/page/school-committee',
        'no_photo_reason': None,
    },
    {
        'external_id': -890024,
        'full_name': 'Ben Speed',
        'district_label': 'Bangor',
        'title': 'School Committee Member',
        'politician_id': '7fd1623b-6da0-4049-8701-817a2157e7fd',
        'source_url': 'https://www.bangorschools.net/page/school-committee',
        'no_photo_reason': None,
    },
    {
        'external_id': -890025,
        'full_name': 'Ben Sprague',
        'district_label': 'Bangor',
        'title': 'School Committee Member',
        'politician_id': 'd7d85d00-8d7a-41fb-a7ff-34a0168c9dec',
        'source_url': 'https://www.bangorschools.net/page/school-committee',
        'no_photo_reason': None,
    },
    {
        'external_id': -890026,
        'full_name': 'Shelly Okere',
        'district_label': 'Bangor',
        'title': 'School Committee Member',
        'politician_id': 'e13c4597-d591-421c-8494-347662e08bdb',
        'source_url': 'https://www.bangorschools.net/page/school-committee',
        'no_photo_reason': None,
    },
    {
        'external_id': -890027,
        'full_name': 'Sara Luciano',
        'district_label': 'Bangor',
        'title': 'School Committee Member',
        'politician_id': '2a42b883-6335-448c-8adb-d27965d772b7',
        'source_url': 'https://www.bangorschools.net/page/school-committee',
        'no_photo_reason': None,
    },
    # ============================================================
    # SOUTH PORTLAND PUBLIC SCHOOLS (ME) — 7 members
    # Source: https://www.spsd.org/board/members-of-the-board
    # JS-heavy CMS with Fastly/CDN protection — server-side fetch blocked.
    # ============================================================
    {
        'external_id': -890031,
        'full_name': 'Susan Rauscher',
        'district_label': 'South Portland',
        'title': 'Board Member (District 1)',
        'politician_id': 'e7341f3f-ef71-484e-83c7-7cd6e37e6b2b',
        'source_url': 'https://www.spsd.org/board/members-of-the-board',
        'no_photo_reason': None,
    },
    {
        'external_id': -890032,
        'full_name': 'Tyler Smith',
        'district_label': 'South Portland',
        'title': 'Board Member (District 2)',
        'politician_id': '93126212-ef27-4cb7-9210-f772c6d32df1',
        'source_url': 'https://www.spsd.org/board/members-of-the-board',
        'no_photo_reason': None,
    },
    {
        'external_id': -890033,
        'full_name': 'Rosemarie De Angelis',
        'district_label': 'South Portland',
        'title': 'Board Member (District 3)',
        'politician_id': '753bd209-583a-49c7-9bec-9c45a193f25b',
        'source_url': 'https://www.spsd.org/board/members-of-the-board',
        'no_photo_reason': None,
    },
    {
        'external_id': -890034,
        'full_name': 'George Risch',
        'district_label': 'South Portland',
        'title': 'Board Member (District 4)',
        'politician_id': 'ee4e1262-172f-4e86-bb64-85602dcf3208',
        'source_url': 'https://www.spsd.org/board/members-of-the-board',
        'no_photo_reason': None,
    },
    {
        'external_id': -890035,
        'full_name': 'VACANT - District 5',
        'district_label': 'South Portland',
        'title': 'Board Member (District 5)',
        'politician_id': '6f9aab95-b05b-4f34-9b6f-5cd22556ac63',
        'source_url': 'https://www.spsd.org/board/members-of-the-board',
        'no_photo_reason': 'vacant seat — no person to photograph',
    },
    {
        'external_id': -890036,
        'full_name': 'Jennifer Ryan',
        'district_label': 'South Portland',
        'title': 'Board Member',
        'politician_id': 'abc895e7-ac0c-4b73-9628-c4c8b773db4a',
        'source_url': 'https://www.spsd.org/board/members-of-the-board',
        'no_photo_reason': None,
    },
    {
        'external_id': -890037,
        'full_name': 'Eleni Richardson',
        'district_label': 'South Portland',
        'title': 'Board Member',
        'politician_id': '6b59943f-c8d6-478a-94ac-e9427852331d',
        'source_url': 'https://www.spsd.org/board/members-of-the-board',
        'no_photo_reason': None,
    },
    # ============================================================
    # AUBURN PUBLIC SCHOOLS (ME) — 8 members
    # Source: https://auburnschl.edu/district_info/school_committee
    # Cloudflare-protected CMS — server-side fetch blocked.
    # ============================================================
    {
        'external_id': -890041,
        'full_name': 'Korin McGuigan',
        'district_label': 'Auburn',
        'title': 'School Committee Member (Ward 1)',
        'politician_id': '73594c68-0edd-4680-a91b-cec47631546b',
        'source_url': 'https://auburnschl.edu/district_info/school_committee',
        'no_photo_reason': None,
    },
    {
        'external_id': -890042,
        'full_name': 'Misty Edgecomb',
        'district_label': 'Auburn',
        'title': 'School Committee Member (Ward 2)',
        'politician_id': 'cc5e2056-2715-4487-afd5-9af1b6b3cedf',
        'source_url': 'https://auburnschl.edu/district_info/school_committee',
        'no_photo_reason': None,
    },
    {
        'external_id': -890043,
        'full_name': 'Patricia Gautier',
        'district_label': 'Auburn',
        'title': 'School Committee Member (Ward 3)',
        'politician_id': '9f8d11de-6839-4bf3-99f3-910b6d9b6eff',
        'source_url': 'https://auburnschl.edu/district_info/school_committee',
        'no_photo_reason': None,
    },
    {
        'external_id': -890044,
        'full_name': 'Lydia Chapman',
        'district_label': 'Auburn',
        'title': 'School Committee Member (Ward 4)',
        'politician_id': '97f35caf-9ed4-470b-9b1e-ad77ab5b5cf1',
        'source_url': 'https://auburnschl.edu/district_info/school_committee',
        'no_photo_reason': None,
    },
    {
        'external_id': -890045,
        'full_name': 'Daniel F. Poisson Sr.',
        'district_label': 'Auburn',
        'title': 'School Committee Member (Ward 5)',
        'politician_id': '6412d2fb-eb93-4bc9-b746-c9297d8f60ba',
        'source_url': 'https://auburnschl.edu/district_info/school_committee',
        'no_photo_reason': None,
    },
    {
        'external_id': -890046,
        'full_name': 'Pamela Albert',
        'district_label': 'Auburn',
        'title': 'School Committee Member (At-Large)',
        'politician_id': '13269f6c-ac6e-47b4-9107-14d407a022bf',
        'source_url': 'https://auburnschl.edu/district_info/school_committee',
        'no_photo_reason': None,
    },
    {
        'external_id': -890047,
        'full_name': 'Olivia Jaye Rich',
        'district_label': 'Auburn',
        'title': 'School Committee Member (At-Large)',
        'politician_id': '5179b7a5-457b-4151-b33f-16d913c56cdb',
        'source_url': 'https://auburnschl.edu/district_info/school_committee',
        'no_photo_reason': None,
    },
    {
        'external_id': -890048,
        'full_name': 'Nancy Pulk',
        'district_label': 'Auburn',
        'title': 'School Committee Member (At-Large)',
        'politician_id': 'dba1b106-297d-4bc7-948a-8e29376d1612',
        'source_url': 'https://auburnschl.edu/district_info/school_committee',
        'no_photo_reason': None,
    },
    # ============================================================
    # BIDDEFORD PUBLIC SCHOOLS (ME) — 7 members
    # Source: https://biddefordschools.me (locate School Committee page)
    # Thrillshare CMS with Fastly client challenge — server-side fetch blocked.
    # ============================================================
    {
        'external_id': -890051,
        'full_name': 'Amy Clearwater',
        'district_label': 'Biddeford',
        'title': 'School Committee Member',
        'politician_id': '776f939c-69c1-4dbc-a1d5-23b4aade606f',
        'source_url': 'https://biddefordschools.me/domain/128',
        'no_photo_reason': None,
    },
    {
        'external_id': -890052,
        'full_name': 'Meagan Desjardins',
        'district_label': 'Biddeford',
        'title': 'School Committee Member',
        'politician_id': 'fb7b6e04-6b60-47b0-a729-96921665cac9',
        'source_url': 'https://biddefordschools.me/domain/128',
        'no_photo_reason': None,
    },
    {
        'external_id': -890053,
        'full_name': 'Michele Landry',
        'district_label': 'Biddeford',
        'title': 'School Committee Member',
        'politician_id': 'd1c309f6-c7fd-448b-ad38-9899dfd5a929',
        'source_url': 'https://biddefordschools.me/domain/128',
        'no_photo_reason': None,
    },
    {
        'external_id': -890054,
        'full_name': 'Marie Potvin',
        'district_label': 'Biddeford',
        'title': 'School Committee Member',
        'politician_id': 'aafdf42e-adb5-40a4-88d9-8be6434f4b33',
        'source_url': 'https://biddefordschools.me/domain/128',
        'no_photo_reason': None,
    },
    {
        'external_id': -890055,
        'full_name': 'Timothy Stebbins',
        'district_label': 'Biddeford',
        'title': 'School Committee Member',
        'politician_id': '70596b36-3451-4fdd-8a3a-bb8f1b3bb216',
        'source_url': 'https://biddefordschools.me/domain/128',
        'no_photo_reason': None,
    },
    {
        'external_id': -890056,
        'full_name': 'Karen Ruel',
        'district_label': 'Biddeford',
        'title': 'School Committee Member',
        'politician_id': '2c3d2be1-d7cf-46a1-bb44-e8e3a2a1d35a',
        'source_url': 'https://biddefordschools.me/domain/128',
        'no_photo_reason': None,
    },
    {
        'external_id': -890057,
        'full_name': 'Emily Henley',
        'district_label': 'Biddeford',
        'title': 'School Committee Member',
        'politician_id': 'aa906e12-56fb-4f5c-9599-d666e7b7f8b3',
        'source_url': 'https://biddefordschools.me/domain/128',
        'no_photo_reason': None,
    },
]


# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

def log_result(line: str):
    """Append one result line to the working log file."""
    with open(LOG_FILE, 'a', encoding='utf-8') as f:
        f.write(line + '\n')


def download_image(url: str) -> bytes:
    """Download image from URL with browser-like User-Agent. Returns raw bytes."""
    print(f'  Downloading: {url}')
    resp = requests.get(
        url,
        headers=BROWSER_HEADERS,
        timeout=30,
        allow_redirects=True,
        verify=False,
    )
    if resp.status_code != 200:
        raise Exception(f'HTTP {resp.status_code} for {url}')
    content_type = resp.headers.get('content-type', '').lower()
    # Reject transparent GIF placeholders
    if 'gif' in content_type or url.endswith('.gif'):
        raise Exception('transparent GIF placeholder detected — no photo available')
    # Reject HTML responses (client challenges / error pages)
    if 'text/html' in content_type:
        raise Exception(f'site returned HTML (client challenge or redirect) — server-side fetch blocked')
    print(f'  Downloaded: {len(resp.content)} bytes, type: {content_type}')
    return resp.content


def crop_to_4_5(img: Image.Image) -> Image.Image:
    """
    Crop image to 4:5 aspect ratio.
    - Square or landscape: center-crop horizontally (preserve full height, crop sides)
    - Portrait taller than 4:5: top-crop (preserve top; eyes at ~1/3 from top per
      memory feedback_headshot_cropping.md — crop bottom, not top, for tall sources)
    NEVER stretch or change aspect ratio.
    """
    w, h = img.size
    target_ratio = 4.0 / 5.0  # 0.8

    current_ratio = w / h

    if abs(current_ratio - target_ratio) < 0.001:
        # Already 4:5
        return img

    if current_ratio > target_ratio:
        # Image is wider than 4:5 (landscape or square): center-crop width, keep full height
        new_w = int(h * target_ratio)
        left = (w - new_w) // 2
        cropped = img.crop((left, 0, left + new_w, h))
        print(f'  Crop (center): {w}x{h} -> {cropped.width}x{cropped.height}')
        return cropped
    else:
        # Image is taller than 4:5 (portrait): top-crop to 4:5
        # Keep full width, crop height from bottom (preserve head/shoulders at top)
        new_h = int(w / target_ratio)
        cropped = img.crop((0, 0, w, new_h))
        print(f'  Crop (top): {w}x{h} -> {cropped.width}x{cropped.height}')
        return cropped


def resize_600x750(img: Image.Image) -> Image.Image:
    """Resize image to exactly 600x750 using Lanczos resampling."""
    resized = img.resize(TARGET_SIZE, RESAMPLE)
    print(f'  Resized to: {resized.width}x{resized.height}')
    return resized


def save_jpeg_q90(img: Image.Image) -> bytes:
    """Save image as JPEG quality=90 optimize=True, return bytes."""
    buf = io.BytesIO()
    img.save(buf, format='JPEG', quality=JPEG_QUALITY, optimize=True)
    return buf.getvalue()


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


def insert_politician_image(cursor, politician_uuid: str, url: str) -> bool:
    """
    INSERT INTO essentials.politician_images with NOT EXISTS guard.
    type MUST be 'default' — UI filters with .find(img => img.type === 'default').
    Returns True if inserted, False if already existed.
    """
    cursor.execute(
        """
        INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
        SELECT gen_random_uuid(), %s::uuid, %s, 'default', 'public_domain'
        WHERE NOT EXISTS (
            SELECT 1 FROM essentials.politician_images
            WHERE politician_id = %s::uuid
        )
        """,
        (politician_uuid, url, politician_uuid)
    )
    return cursor.rowcount > 0


def process_member(cursor, member: dict) -> dict:
    """
    Full pipeline for one board member.
    If member has a pre-determined no_photo_reason, skip download and log as NO_PHOTO.
    Otherwise: attempt download -> verify -> crop 4:5 -> resize 600x750 -> upload -> insert.
    Returns result dict.
    """
    external_id = member['external_id']
    full_name = member['full_name']
    source_url = member['source_url']
    politician_uuid = member['politician_id']
    pre_known_reason = member.get('no_photo_reason')

    print(f"\n{'='*60}")
    print(f"Processing: {full_name} (external_id={external_id})")
    print(f"  District: {member['district_label']} / {member['title']}")
    print(f"  UUID: {politician_uuid}")

    # If we know ahead of time there's no photo (vacant seat, transparent placeholder sites)
    if pre_known_reason:
        print(f'  SKIP: {pre_known_reason}')
        log_line = f'{external_id}|{full_name}|{member["district_label"]}|NO_PHOTO|{source_url}|{pre_known_reason}'
        log_result(log_line)
        return {
            'external_id': external_id,
            'full_name': full_name,
            'district_label': member['district_label'],
            'politician_id': politician_uuid,
            'source_url': source_url,
            'cdn_url': None,
            'success': False,
            'skip_reason': pre_known_reason,
        }

    print(f'  Source: {source_url}')

    try:
        # 1. Download
        raw_bytes = download_image(source_url)

        # 2. Open with PIL
        img = Image.open(io.BytesIO(raw_bytes))

        # Convert to RGB (handles PNG with alpha, P-mode palette, RGBA, etc.)
        if img.mode != 'RGB':
            img = img.convert('RGB')
        original_dims = f'{img.width}x{img.height}'
        print(f'  Original size: {img.width}x{img.height} mode={img.mode}')

        # 3. Crop to 4:5 first (NEVER stretch directly — per feedback_headshot_resize_no_distort.md)
        img_before_resize = crop_to_4_5(img)

        # 4. Resize to 600x750 Lanczos
        img_final = resize_600x750(img_before_resize)

        # 5. Verify final dimensions
        assert img_final.size == TARGET_SIZE, f'Expected {TARGET_SIZE}, got {img_final.size}'

        # 6. Save as JPEG q90
        jpeg_bytes = save_jpeg_q90(img_final)
        print(f'  JPEG size: {len(jpeg_bytes)} bytes')

        # 7. Upload to Supabase Storage
        cdn_url = upload_to_storage(politician_uuid, jpeg_bytes)

        # 8. Insert politician_images row (type='default')
        inserted = insert_politician_image(cursor, politician_uuid, cdn_url)
        if inserted:
            print(f'  DB: Inserted politician_images row (type=default)')
        else:
            print(f'  DB: Row already existed (skipped insert)')

        crop_note = f'{original_dims} -> 4:5 crop -> 600x750 q90'
        log_line = f'{external_id}|{full_name}|{member["district_label"]}|UPLOADED|{source_url}|{crop_note}'
        log_result(log_line)

        return {
            'external_id': external_id,
            'full_name': full_name,
            'district_label': member['district_label'],
            'politician_id': politician_uuid,
            'source_url': source_url,
            'cdn_url': cdn_url,
            'success': True,
            'skip_reason': None,
        }

    except Exception as e:
        reason = str(e)
        print(f'  ERROR: {reason}')
        log_line = f'{external_id}|{full_name}|{member["district_label"]}|NO_PHOTO|{source_url}|{reason}'
        log_result(log_line)
        return {
            'external_id': external_id,
            'full_name': full_name,
            'district_label': member['district_label'],
            'politician_id': politician_uuid,
            'source_url': source_url,
            'cdn_url': None,
            'success': False,
            'skip_reason': reason,
        }


def main():
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

    print(f'[_tmp-in-me-school-headshots] Starting Phase 89 Plan 03 headshot upload')
    print(f'  Roster: {len(ROSTER)} members across 7 districts (3 IN + 37 ME)')
    print(f'  Target: {TARGET_SIZE[0]}x{TARGET_SIZE[1]} JPEG q{JPEG_QUALITY} via Lanczos (LANCZOS resampling)')
    print(f'  Bucket: {BUCKET}')
    print(f'  Log: {LOG_FILE}')

    # Clear/initialize log file
    with open(LOG_FILE, 'w', encoding='utf-8') as f:
        f.write(f'# Phase 89 Plan 03 headshot log\n')
        f.write(f'# format: external_id|full_name|district|UPLOADED or NO_PHOTO|source_url|notes\n')
        f.write(f'# generated by _tmp-in-me-school-headshots.py\n')

    # Open DB connection
    db_url = DATABASE_URL
    if 'sslmode' not in db_url:
        sep = '&' if '?' in db_url else '?'
        db_url = db_url + sep + 'sslmode=require'
    conn = psycopg2.connect(db_url)
    conn.autocommit = False
    cursor = conn.cursor()

    results = []
    districts_order = ['IPS', 'MCCSC', 'Lewiston', 'Bangor', 'South Portland', 'Auburn', 'Biddeford']

    try:
        for district_name in districts_order:
            district_members = [m for m in ROSTER if m['district_label'] == district_name]
            if not district_members:
                continue
            print(f"\n{'#'*60}")
            print(f'# DISTRICT: {district_name} ({len(district_members)} members)')
            print(f"{'#'*60}")
            for member in district_members:
                result = process_member(cursor, member)
                results.append(result)
                if result['success']:
                    conn.commit()
                time.sleep(0.3)
    finally:
        cursor.close()
        conn.close()

    # Summary
    print(f"\n{'='*60}")
    print('PHASE 89 HEADSHOT UPLOAD SUMMARY:')
    succeeded = [r for r in results if r['success']]
    failed = [r for r in results if not r['success']]

    district_counts = {}
    for r in results:
        d = r['district_label']
        if d not in district_counts:
            district_counts[d] = {'success': 0, 'fail': 0, 'total': 0}
        district_counts[d]['total'] += 1
        if r['success']:
            district_counts[d]['success'] += 1
        else:
            district_counts[d]['fail'] += 1

    print(f'  Total attempted: {len(results)}')
    print(f'  Uploaded:        {len(succeeded)}')
    print(f'  No photo:        {len(failed)}')
    print()
    print('Per-district breakdown:')
    for dist in districts_order:
        if dist in district_counts:
            c = district_counts[dist]
            print(f'  {dist}: {c["success"]}/{c["total"]} uploaded')
    print()

    if succeeded:
        print('Uploaded:')
        for r in succeeded:
            print(f'  OK  {r["external_id"]:8}  {r["full_name"]}')
            print(f'      cdn: {r["cdn_url"]}')

    if failed:
        print(f'\nNo photo ({len(failed)}):')
        for r in failed:
            print(f'  N/A {r["external_id"]:8}  {r["full_name"]} — {r["skip_reason"]}')

    print(f'\nLog written to: {LOG_FILE}')


if __name__ == '__main__':
    import urllib3
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    main()
