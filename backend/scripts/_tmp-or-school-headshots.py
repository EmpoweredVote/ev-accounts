"""
_tmp-or-school-headshots.py
Process and upload headshots for 38 Multnomah County school board members to Supabase Storage.
Phase 86 Plan 02.

Processing pipeline (per feedback_headshot_resize_no_distort.md):
1. Download from official district website
2. CROP to 4:5 ratio FIRST - never stretch
3. RESIZE to 600x750 Lanczos q90
4. Upload to politician_photos/{politician_id}-headshot.jpg

Covers 6 districts (38 politicians, external_ids -860001..-860055):
  PPS:           -860001 to -860007  (7 members)  — Finalsite CDN
  Parkrose:      -860011 to -860015  (5 members)  — Direct paths on parkrose.com
  Reynolds:      -860021 to -860027  (7 members)  — Drupal itok tokens
  Centennial:    -860031 to -860037  (7 members)  — ParentSquare/SmartSites CDN
  David Douglas: -860041 to -860047  (7 members)  — WordPress uploads
  Riverdale:     -860051 to -860055  (5 members)  — Finalsite CDN (resources.finalsite.net)
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

# Load env from backend .env
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

# ---------------------------------------------------------------------------
# ROSTER — 38 board members with discovered source URLs
# External IDs and UUIDs verified against production DB 2026-06-01.
# Source URLs discovered via live scraping of each district's official website.
# ---------------------------------------------------------------------------

ROSTER = [
    # ============================================================
    # PORTLAND PUBLIC SCHOOLS (PPS) — 7 members
    # Source: https://www.pps.net/board/board-of-education/board-members
    # URL pattern: https://ppsnet.finalsite.com/fs/resource-manager/view/{UUID}
    # ============================================================
    {
        'external_id': -860001,
        'full_name': 'Edward Wang',
        'district_label': 'PPS',
        'title': 'Board Member (Zone 7)',
        'politician_id': '10b4ad6b-7db3-4805-b103-1c830f91637c',
        'source_url': 'https://ppsnet.finalsite.com/fs/resource-manager/view/5d026714-5d57-4225-b3a0-e7d067cbbbe9',
        'source_domain': 'pps.net',
    },
    {
        'external_id': -860002,
        'full_name': 'Michelle DePass',
        'district_label': 'PPS',
        'title': 'Board Member (Zone 2)',
        'politician_id': 'f40f4d14-4400-41d5-83d6-2a5c74b55fa7',
        'source_url': 'https://ppsnet.finalsite.com/fs/resource-manager/view/b829e8be-7795-430e-8db8-847b17768da3',
        'source_domain': 'pps.net',
    },
    {
        'external_id': -860003,
        'full_name': 'Christy Splitt',
        'district_label': 'PPS',
        'title': 'Board Member (Zone 1)',
        'politician_id': '344e17f8-0a2e-4e21-9575-094a97bf9902',
        'source_url': 'https://ppsnet.finalsite.com/fs/resource-manager/view/234d98ce-926d-4f30-a3e9-34c0af846c5a',
        'source_domain': 'pps.net',
    },
    {
        'external_id': -860004,
        'full_name': 'Patte Sullivan',
        'district_label': 'PPS',
        'title': 'Board Member (Zone 3)',
        'politician_id': '42c86392-30f2-494a-b31e-080cf082f84b',
        'source_url': 'https://ppsnet.finalsite.com/fs/resource-manager/view/8c104d6e-dcaf-4bb2-8c30-45b23c95506a',
        'source_domain': 'pps.net',
    },
    {
        'external_id': -860005,
        'full_name': 'Rashelle Chase-Miller',
        'district_label': 'PPS',
        'title': 'Board Member (Zone 4)',
        'politician_id': '2c93690e-0efe-409c-9bf3-455c5975dffd',
        'source_url': 'https://ppsnet.finalsite.com/fs/resource-manager/view/ec5c3590-e78c-42d7-b439-9a7db96fbb5e',
        'source_domain': 'pps.net',
    },
    {
        'external_id': -860006,
        'full_name': 'Virginia La Forte',
        'district_label': 'PPS',
        'title': 'Board Member (Zone 5)',
        'politician_id': '9fd4af48-7ca2-408c-abf0-1bbc94346c79',
        'source_url': 'https://ppsnet.finalsite.com/fs/resource-manager/view/d9272c7d-e554-4902-bd43-08da1a04fdf9',
        'source_domain': 'pps.net',
    },
    {
        'external_id': -860007,
        'full_name': 'Stephanie Engelsman',
        'district_label': 'PPS',
        'title': 'Board Member (Zone 6)',
        'politician_id': '7442d79b-052c-4012-9f12-a6742b57f9fe',
        'source_url': 'https://ppsnet.finalsite.com/fs/resource-manager/view/95fba4d1-6618-47f1-b3a4-2580dfea8221',
        'source_domain': 'pps.net',
    },
    # ============================================================
    # PARKROSE — 5 members
    # Source: https://www.parkrose.com/school-board
    # URL pattern: https://www.parkrose.com/images/about/school_board/{filename}.jpg
    # ============================================================
    {
        'external_id': -860011,
        'full_name': 'Paul Tabron Jr.',
        'district_label': 'Parkrose',
        'title': 'Board Member (Position 1)',
        'politician_id': 'eeba6ea2-93fa-4aa2-86ae-74431cf2278d',
        'source_url': 'https://www.parkrose.com/images/about/school_board/paul-web.jpg',
        'source_domain': 'parkrose.com',
    },
    {
        'external_id': -860012,
        'full_name': 'Brenda Rivas',
        'district_label': 'Parkrose',
        'title': 'Board Member (Position 2)',
        'politician_id': 'ef606b2d-a9b6-419e-88a2-bf2f82c1d3eb',
        'source_url': 'https://www.parkrose.com/images/about/school_board/brenda.jpg',
        'source_domain': 'parkrose.com',
    },
    {
        'external_id': -860013,
        'full_name': 'Joash Bullock',
        'district_label': 'Parkrose',
        'title': 'Board Member (Position 3)',
        'politician_id': '7fccdafd-fa44-49b7-883d-2a4d5d79441a',
        'source_url': 'https://www.parkrose.com/images/about/school_board/joash-bullock.jpg',
        'source_domain': 'parkrose.com',
    },
    {
        'external_id': -860014,
        'full_name': 'Adolfo Jimenez',
        'district_label': 'Parkrose',
        'title': 'Board Member (Position 4)',
        'politician_id': 'e0a87048-111e-449d-817f-8ec339f0d467',
        'source_url': 'https://www.parkrose.com/images/about/school_board/adolfo-jimenez.jpg',
        'source_domain': 'parkrose.com',
    },
    {
        'external_id': -860015,
        'full_name': 'Mariah Galaviz',
        'district_label': 'Parkrose',
        'title': 'Board Member (Position 5)',
        'politician_id': '11db09c5-8550-44d9-85ba-8d8a7a4cf6db',
        'source_url': 'https://www.parkrose.com/images/about/school_board/mariah.jpg',
        'source_domain': 'parkrose.com',
    },
    # ============================================================
    # REYNOLDS — 7 members
    # Source: https://www.reynolds.k12.or.us/schoolboard/{slug}
    # URL pattern: Drupal gallery500 style with itok tokens (fetched per-member)
    # ============================================================
    {
        'external_id': -860021,
        'full_name': 'Aaron Muñoz',
        'district_label': 'Reynolds',
        'title': 'Board Member (Position 1)',
        'politician_id': 'ec1345e0-90b7-4250-9213-4943aefe29aa',
        'source_url': 'https://www.reynolds.k12.or.us/sites/default/files/styles/gallery500/public/imageattachments/schoolboard/page/53775/aaron.png?itok=gc8gKxir',
        'source_domain': 'reynolds.k12.or.us',
    },
    {
        'external_id': -860022,
        'full_name': 'Joyce Rosenau',
        'district_label': 'Reynolds',
        'title': 'Board Member (Position 2)',
        'politician_id': '3e6ac0ed-a27e-4869-becb-d40fcf36db8f',
        'source_url': 'https://www.reynolds.k12.or.us/sites/default/files/styles/gallery500/public/imageattachments/schoolboard/page/69022/joyce.png?itok=-AC0wI1w',
        'source_domain': 'reynolds.k12.or.us',
    },
    {
        'external_id': -860023,
        'full_name': 'Michael Reyes',
        'district_label': 'Reynolds',
        'title': 'Board Member (Position 3)',
        'politician_id': 'e40d9fcd-972e-46ad-8ca6-b495d9646901',
        'source_url': 'https://www.reynolds.k12.or.us/sites/default/files/styles/gallery500/public/imageattachments/schoolboard/page/53783/michael.png?itok=ZrKNrFMD',
        'source_domain': 'reynolds.k12.or.us',
    },
    {
        'external_id': -860024,
        'full_name': 'Cayle Tern',
        'district_label': 'Reynolds',
        'title': 'Board Member (Position 4)',
        'politician_id': 'feb5bbc8-9583-4e60-94a7-da6d08b7caf6',
        'source_url': 'https://www.reynolds.k12.or.us/sites/default/files/styles/gallery500/public/imageattachments/schoolboard/page/53779/cayle.png?itok=umD8fUNi',
        'source_domain': 'reynolds.k12.or.us',
    },
    {
        'external_id': -860025,
        'full_name': 'Patty Carrera',
        'district_label': 'Reynolds',
        'title': 'Board Member (Position 5)',
        'politician_id': '497d41d3-5065-4cd5-80a3-7c7fae737324',
        'source_url': 'https://www.reynolds.k12.or.us/sites/default/files/styles/gallery500/public/imageattachments/schoolboard/page/1844/patty.png?itok=iZHI5YhF',
        'source_domain': 'reynolds.k12.or.us',
    },
    {
        'external_id': -860026,
        'full_name': 'Ana Gonzalez Muñoz',
        'district_label': 'Reynolds',
        'title': 'Board Member (Position 6)',
        'politician_id': '6e54cb4c-454c-4a5e-baee-589d4cee32d4',
        'source_url': 'https://www.reynolds.k12.or.us/sites/default/files/styles/gallery500/public/imageattachments/schoolboard/page/32631/ana.png?itok=T4LCbGIE',
        'source_domain': 'reynolds.k12.or.us',
    },
    {
        'external_id': -860027,
        'full_name': 'Francisco Ibarra',
        'district_label': 'Reynolds',
        'title': 'Board Member (Position 7)',
        'politician_id': '337a335e-f10e-4c9d-9369-18c36f7de5c6',
        'source_url': 'https://www.reynolds.k12.or.us/sites/default/files/styles/gallery500/public/imageattachments/schoolboard/page/66219/francisco.png?itok=Af7aHLtS',
        'source_domain': 'reynolds.k12.or.us',
    },
    # ============================================================
    # CENTENNIAL — 7 members
    # Source: https://csd28j.org/boardmembers (ParentSquare/SmartSites CMS)
    # URL pattern: https://files.smartsites.parentsquare.com/3490/{filename}
    # ============================================================
    {
        'external_id': -860031,
        'full_name': 'David Linn',
        'district_label': 'Centennial',
        'title': 'Board Member (Position 1)',
        'politician_id': 'c13cb001-d27b-42f6-93dc-3fb00db21120',
        'source_url': 'https://files.smartsites.parentsquare.com/3490/img_pd_123745_ogjxu5.png',
        'source_domain': 'csd28j.org',
    },
    {
        'external_id': -860032,
        'full_name': 'Ronald Hardin',
        'district_label': 'Centennial',
        'title': 'Board Member (Position 2)',
        'politician_id': '9839f19d-f280-4499-84ac-b1c8348400e7',
        'source_url': 'https://files.smartsites.parentsquare.com/3490/img_pd_123745_ovdfak.png',
        'source_domain': 'csd28j.org',
    },
    {
        'external_id': -860033,
        'full_name': 'Will Mohring',
        'district_label': 'Centennial',
        'title': 'Board Member (Position 3)',
        'politician_id': 'cfb6ee39-6536-4f82-acd5-4e3551eab7f4',
        'source_url': 'https://files.smartsites.parentsquare.com/3490/Will Mohring P6 At-Large (1)_1752530741.png',
        'source_domain': 'csd28j.org',
    },
    {
        'external_id': -860034,
        'full_name': 'Melissa Standley',
        'district_label': 'Centennial',
        'title': 'Board Member (Position 4)',
        'politician_id': 'fb8ab828-149e-4abb-aeef-61536b68ece3',
        'source_url': 'https://files.smartsites.parentsquare.com/3490/img_pd_123745_kaakwr.png',
        'source_domain': 'csd28j.org',
    },
    {
        'external_id': -860035,
        'full_name': 'Rose Solowski',
        'district_label': 'Centennial',
        'title': 'Board Member (Position 5)',
        'politician_id': '9747fe9d-1d43-49df-b1fe-c1b9be89b10c',
        'source_url': 'https://files.smartsites.parentsquare.com/3490/img_pd_123745_ybmchp.png',
        'source_domain': 'csd28j.org',
    },
    {
        'external_id': -860036,
        'full_name': 'Michael Newman',
        'district_label': 'Centennial',
        'title': 'Board Member (Position 6)',
        'politician_id': 'c2b9cc5d-9e08-453b-aa38-c71dfde280b1',
        'source_url': 'https://files.smartsites.parentsquare.com/3490/Michael Newman P6 At-Large (1)_1752531598.png',
        'source_domain': 'csd28j.org',
    },
    {
        'external_id': -860037,
        'full_name': 'Pam Shields',
        'district_label': 'Centennial',
        'title': 'Board Member (Position 7)',
        'politician_id': '7cdce2fa-eafa-42bb-bf33-66b1d32ae8fb',
        'source_url': 'https://files.smartsites.parentsquare.com/3490/img_pd_123745_zdv1ht.png',
        'source_domain': 'csd28j.org',
    },
    # ============================================================
    # DAVID DOUGLAS — 7 members
    # Source: https://www.ddouglas.k12.or.us/school-board/board-members/
    # URL pattern: WordPress /wp-content/uploads/{YEAR}/{MONTH}/{FILE}
    # Note: Some URLs are http:// — requests follows redirects to https
    # ============================================================
    {
        'external_id': -860041,
        'full_name': 'Althea Ender',
        'district_label': 'David Douglas',
        'title': 'Board Member (Position 1)',
        'politician_id': 'f1907eef-b4b7-46bd-aeb3-c41edb51fa06',
        'source_url': 'http://www.ddouglas.k12.or.us/wp-content/uploads/2026/02/Althea-Ender-scaled.jpg',
        'source_domain': 'ddouglas.k12.or.us',
    },
    {
        'external_id': -860042,
        'full_name': 'Stephanie Stephens',
        'district_label': 'David Douglas',
        'title': 'Board Member (Position 2)',
        'politician_id': '5cf1f2d8-0604-452a-a994-1d88a8cb0de6',
        'source_url': 'http://www.ddouglas.k12.or.us/wp-content/uploads/2014/06/Stephanie-Stephens-2017-683x1024.jpg',
        'source_domain': 'ddouglas.k12.or.us',
    },
    {
        'external_id': -860043,
        'full_name': 'Sara Epstein',
        'district_label': 'David Douglas',
        'title': 'Board Member (Position 3)',
        'politician_id': '56f84b9a-f73f-4c2f-8974-43f572ade8f3',
        'source_url': 'https://www.ddouglas.k12.or.us/wp-content/uploads/2025/07/Sara-Ruth-Epstein-Picture-edited.jpg',
        'source_domain': 'ddouglas.k12.or.us',
    },
    {
        'external_id': -860044,
        'full_name': 'Muriel Jordan',
        'district_label': 'David Douglas',
        'title': 'Board Member (Position 4)',
        'politician_id': '0bdbc359-e0af-45de-b99f-79f181e068ff',
        'source_url': 'https://www.ddouglas.k12.or.us/wp-content/uploads/2025/09/Muriel-Jordan-edited-2-scaled.jpg',
        'source_domain': 'ddouglas.k12.or.us',
    },
    {
        'external_id': -860045,
        'full_name': 'Thomas Stephenson',
        'district_label': 'David Douglas',
        'title': 'Board Member (Position 5)',
        'politician_id': '2f2614a8-6590-4bb9-af19-be8d41faa5fb',
        'source_url': 'https://www.ddouglas.k12.or.us/wp-content/uploads/2025/07/Thomas-Stephenson-edited-683x1024.png',
        'source_domain': 'ddouglas.k12.or.us',
    },
    {
        'external_id': -860046,
        'full_name': 'Heather Franklin',
        'district_label': 'David Douglas',
        'title': 'Board Member (Position 6)',
        'politician_id': '76779c80-2ccd-4497-88b2-00b859e8d1bb',
        'source_url': 'http://www.ddouglas.k12.or.us/wp-content/uploads/2022/08/Heather-Franklin_683x1024-crop-2-683x1024.png',
        'source_domain': 'ddouglas.k12.or.us',
    },
    {
        'external_id': -860047,
        'full_name': 'José Gamero-Georgeson',
        'district_label': 'David Douglas',
        'title': 'Board Member (Position 7)',
        'politician_id': 'acd677e0-6277-4866-aeb3-96b3ffbac222',
        'source_url': 'https://www.ddouglas.k12.or.us/wp-content/uploads/2024/12/Jose-Gamero-Georgeson_headshot-2.png',
        'source_domain': 'ddouglas.k12.or.us',
    },
    # ============================================================
    # RIVERDALE — 5 members
    # Source: https://www.riverdaleschool.com/about-us/school-board-policy
    # URL pattern: resources.finalsite.net (CDN direct image URLs extracted from img tags)
    # ============================================================
    {
        'external_id': -860051,
        'full_name': 'Shaina Weinstein',
        'district_label': 'Riverdale',
        'title': 'Board Member (Seat 1)',
        'politician_id': 'aa483fc0-9410-41d0-9e68-1c62ad740d2c',
        'source_url': 'https://resources.finalsite.net/images/f_auto,q_auto,t_image_size_1/v1734406260/riverdalek12orus/rp9b3bblxbqtq5hklire/ShainaWeinsteinHeadshot.jpg',
        'source_domain': 'riverdaleschool.com',
    },
    {
        'external_id': -860052,
        'full_name': 'Mina Stricklin',
        'district_label': 'Riverdale',
        'title': 'Board Member (Seat 2)',
        'politician_id': '0af24917-0c71-4275-b234-d7f1cfb8ff79',
        'source_url': 'https://resources.finalsite.net/images/f_auto,q_auto,t_image_size_1/v1686937338/riverdalek12orus/f6qecratmahpa7xtdgtk/MinaStricklin.jpg',
        'source_domain': 'riverdaleschool.com',
    },
    {
        'external_id': -860053,
        'full_name': 'Michele Rosenbaum',
        'district_label': 'Riverdale',
        'title': 'Board Member (Seat 3)',
        'politician_id': '04260ecf-5636-4daa-850e-d4ec924a16eb',
        'source_url': 'https://resources.finalsite.net/images/f_auto,q_auto,t_image_size_1/v1670002047/riverdalek12orus/fqhcryczbw8iibp7h9j4/MicheleRosenbaum.png',
        'source_domain': 'riverdaleschool.com',
    },
    {
        'external_id': -860054,
        'full_name': 'Ali Lanenga',
        'district_label': 'Riverdale',
        'title': 'Board Member (Seat 4)',
        'politician_id': 'a8e94f7c-2cfe-4296-8604-903273d6b385',
        'source_url': 'https://resources.finalsite.net/images/f_auto,q_auto,t_image_size_1/v1752528365/riverdalek12orus/rtj34pqwy2v45xtuj3ff/AliLanengaPortrait.jpg',
        'source_domain': 'riverdaleschool.com',
    },
    {
        'external_id': -860055,
        'full_name': 'Milessa Lowrie',
        'district_label': 'Riverdale',
        'title': 'Board Member (Seat 5)',
        'politician_id': 'c59855c0-4a3b-439f-b0bf-6f219c5cf028',
        'source_url': 'https://resources.finalsite.net/images/f_auto,q_auto,t_image_size_1/v1752528078/riverdalek12orus/fovh1trcg6hv8m8jmr6s/MilessaLowrieHeadshot_1.jpg',
        'source_domain': 'riverdaleschool.com',
    },
]


# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

def fetch_politician_id(cursor, external_id: int) -> str:
    """SELECT id FROM essentials.politicians WHERE external_id = %s; returns UUID string."""
    cursor.execute(
        'SELECT id FROM essentials.politicians WHERE external_id = %s',
        (external_id,)
    )
    row = cursor.fetchone()
    if not row:
        raise ValueError(f'No politician found with external_id={external_id}')
    return str(row[0])


def download_image(url: str) -> bytes:
    """Download image from URL with browser-like User-Agent. Returns raw bytes."""
    print(f'  Downloading: {url}')
    resp = requests.get(
        url,
        headers=BROWSER_HEADERS,
        timeout=30,
        allow_redirects=True,
        verify=False,  # ddouglas.k12.or.us has SSL cert issues
    )
    if resp.status_code != 200:
        raise Exception(f'HTTP {resp.status_code} for {url}')
    print(f'  Downloaded: {len(resp.content)} bytes, type: {resp.headers.get("content-type", "unknown")}')
    return resp.content


def crop_to_4_5(img: Image.Image) -> Image.Image:
    """
    Crop image to 4:5 aspect ratio.
    - Square or landscape: center-crop horizontally (preserve full height, crop sides)
    - Portrait taller than 4:5: top-crop (preserve top; eyes at ~1/3 from top)
    NEVER stretch or change aspect ratio.
    """
    w, h = img.size
    target_ratio = 4.0 / 5.0  # 0.8

    current_ratio = w / h  # > target_ratio = wider than 4:5; < target_ratio = taller

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


def insert_politician_images_row(cursor, politician_uuid: str, url: str) -> bool:
    """
    INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
    with NOT EXISTS guard.
    type MUST be 'default' (NOT 'headshot') — UI filters with .find(img => img.type === 'default').
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
    Full pipeline for one board member:
    download -> verify bytes -> crop 4:5 -> resize 600x750 -> upload -> insert DB row.
    Returns result dict with success/failure info.
    """
    external_id = member['external_id']
    full_name = member['full_name']
    source_url = member['source_url']
    politician_uuid = member['politician_id']

    print(f"\n{'='*60}")
    print(f"Processing: {full_name} (external_id={external_id})")
    print(f"  District: {member['district_label']} / {member['title']}")
    print(f"  UUID: {politician_uuid}")
    print(f"  Source: {source_url}")

    try:
        # 1. Download
        raw_bytes = download_image(source_url)

        # 2. Open with PIL
        img = Image.open(io.BytesIO(raw_bytes))

        # Convert to RGB (handles PNG with alpha, P-mode palette, RGBA, etc.)
        if img.mode != 'RGB':
            img = img.convert('RGB')
        print(f'  Original size: {img.width}x{img.height} mode={img.mode}')

        # 3. Crop to 4:5 first (NEVER stretch directly)
        img = crop_to_4_5(img)

        # 4. Resize to 600x750 Lanczos
        img = resize_600x750(img)

        # 5. Verify final dimensions
        assert img.size == TARGET_SIZE, f'Expected {TARGET_SIZE}, got {img.size}'

        # 6. Save as JPEG q90 to bytes buffer
        buf = io.BytesIO()
        img.save(buf, format='JPEG', quality=JPEG_QUALITY, optimize=True)
        jpeg_bytes = buf.getvalue()
        print(f'  JPEG size: {len(jpeg_bytes)} bytes')

        # 7. Upload to Supabase Storage
        cdn_url = upload_to_storage(politician_uuid, jpeg_bytes)

        # 8. Insert politician_images row
        inserted = insert_politician_images_row(cursor, politician_uuid, cdn_url)
        if inserted:
            print(f'  DB: Inserted politician_images row (type=default)')
        else:
            print(f'  DB: Row already existed (skipped insert)')

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
        print(f'  ERROR: {e}')
        return {
            'external_id': external_id,
            'full_name': full_name,
            'district_label': member['district_label'],
            'politician_id': politician_uuid,
            'source_url': source_url,
            'cdn_url': None,
            'success': False,
            'skip_reason': str(e),
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

    print(f'[_tmp-or-school-headshots] Starting Phase 86 Plan 02 headshot upload')
    print(f'  Roster: {len(ROSTER)} members across 6 districts')
    print(f'  Target: {TARGET_SIZE[0]}x{TARGET_SIZE[1]} JPEG q{JPEG_QUALITY} via Lanczos')
    print(f'  Bucket: {BUCKET}')

    # Open DB connection (add sslmode=require for Supabase pooler)
    db_url = DATABASE_URL
    if 'sslmode' not in db_url:
        sep = '&' if '?' in db_url else '?'
        db_url = db_url + sep + 'sslmode=require'
    conn = psycopg2.connect(db_url)
    conn.autocommit = False
    cursor = conn.cursor()

    results = []
    try:
        for member in ROSTER:
            result = process_member(cursor, member)
            results.append(result)
            if result['success']:
                conn.commit()  # Commit after each successful insert
            time.sleep(0.5)  # Polite delay between downloads
    finally:
        cursor.close()
        conn.close()

    # Summary
    print(f"\n{'='*60}")
    print('SUMMARY:')
    succeeded = [r for r in results if r['success']]
    failed = [r for r in results if not r['success']]

    district_counts = {}
    for r in results:
        d = r['district_label']
        if d not in district_counts:
            district_counts[d] = {'success': 0, 'fail': 0}
        if r['success']:
            district_counts[d]['success'] += 1
        else:
            district_counts[d]['fail'] += 1

    print(f'  Attempted: {len(results)}')
    print(f'  Succeeded: {len(succeeded)}')
    print(f'  Failed:    {len(failed)}')
    print()
    print('Per-district breakdown:')
    for dist, counts in district_counts.items():
        print(f'  {dist}: {counts["success"]} succeeded, {counts["fail"]} failed')
    print()
    print('Per-member results:')
    for r in results:
        if r['success']:
            print(f'  OK  {r["external_id"]:8d}  {r["full_name"]}')
            print(f'         cdn: {r["cdn_url"]}')
        else:
            print(f'  FAIL {r["external_id"]:8d}  {r["full_name"]}: {r["skip_reason"]}')

    if failed:
        print(f'\nFAILED members ({len(failed)}):')
        for r in failed:
            print(f'  {r["external_id"]} {r["full_name"]} — {r["skip_reason"]}')
        sys.exit(1)
    else:
        print(f'\nAll {len(results)} headshots uploaded successfully.')


if __name__ == '__main__':
    import urllib3
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    main()
