#!/usr/bin/env python3
"""Download + process Bend, OR headshots to 600x750 (4:5) for essentials.politician_images.

Sources are official .gov / district sites except where noted; see 00-ROSTER-RESEARCH.md.
Bend city portraits are pre-fetched into headshots/raw/<external_id>.jpg because bendoregon.gov
returns 403 to non-browser image requests (they were captured through a browser context).

Crop rule (feedback_headshot_crop_composition): leave roughly one ear-length between the top of
the hair and the frame top — NEVER vertically center the head. Implemented as a top-biased
vertical crop (TOP_BIAS), with per-subject `box` overrides for full-torso shots.

Run: py data/stance-research/bend-or/_headshots.py
"""
import os, json, base64
import requests
from PIL import Image
from io import BytesIO

DIR = 'data/stance-research/bend-or/headshots'
RAW = f'{DIR}/raw'
os.makedirs(DIR, exist_ok=True)

UA = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126.0 Safari/537.36'}

TOP_BIAS = 0.12   # when trimming height, keep the crop high: drop 12% of the excess off the top
TARGET = (600, 750)

CITY_PAGE = 'https://bendoregon.gov/city-council/'
SCHOOL_PAGE = 'https://www.blschools.org/board-and-policy/school-board'
PARK_PAGE = 'https://www.bendparksandrec.org/about/board-of-directors/'
CR = 'https://www.deschutescounty.gov/ImageRepository/Document?documentId='

# (external_id, name, url_or_None(=use raw file), source_page, license, box|None)
SUBJECTS = [
    # --- City of Bend council: official city portraits (pre-fetched to raw/) ---
    (-4105801, 'Melanie Kebler',        None, CITY_PAGE + 'melanie-kebler/',  'press_use', None),
    (-4105802, 'Megan Norris',          None, CITY_PAGE + 'megan-norris/',    'press_use', None),
    (-4105803, 'Gina Franzosa',         None, CITY_PAGE + 'gina-franzosa/',   'press_use', None),
    (-4105804, 'Megan Perkins',         None, CITY_PAGE + 'megan-perkins/',   'press_use', None),
    (-4105805, 'Steve Platt',           None, CITY_PAGE + 'steve-platt/',     'press_use', None),
    (-4105806, 'Ariel Méndez',          None, CITY_PAGE + 'ariel-mendez/',    'press_use', None),
    (-4105807, 'Mike Riley',            None, CITY_PAGE + 'mike-riley/',      'press_use', None),

    # --- Deschutes County: official CivicPlus ImageRepository portraits ---
    (-4101701, 'Anthony (Tony) DeBone', CR + '686',  'https://www.deschutescounty.gov/439/Commissioner-Tony-DeBone',  'press_use', None),
    (-4101702, 'Phil Chang',            CR + '681',  'https://www.deschutescounty.gov/440/Commissioner-Phil-Chang',   'press_use', None),
    (-4101703, 'Patti Adair',           CR + '671',  'https://www.deschutescounty.gov/441/Commissioner-Patti-Adair',  'press_use', None),
    (-4101711, 'Steve Dennison',        CR + '1444', 'https://www.deschutescounty.gov/474/About-the-County-Clerk',    'press_use', None),
    (-4101712, 'Scot Langton',          CR + '2629', 'https://www.deschutescounty.gov/395/About-Scot-Langton',        'press_use', None),

    # --- Bend-La Pine Schools board: official district portraits (already 1000x1250 = 4:5) ---
    (-4101981, 'Jenn Lynch',      'https://resources.finalsite.net/images/v1760114031/bendk12orus/bpm6mg99rqayo3huwdyc/Jenn_1000x1250.jpg',    SCHOOL_PAGE, 'press_use', None),
    (-4101982, 'Marcus LeGrand',  'https://resources.finalsite.net/images/v1760114031/bendk12orus/rzmemxghylsynqa2fvh9/Marcus_1000x1250.jpg',  SCHOOL_PAGE, 'press_use', None),
    (-4101983, 'Cameron Fischer', 'https://resources.finalsite.net/images/v1760114030/bendk12orus/biqiuwcjiqppgtx1q7qi/Cameron_1000x1250.jpg', SCHOOL_PAGE, 'press_use', None),
    (-4101984, 'Shirley Olson',   'https://resources.finalsite.net/images/v1760114034/bendk12orus/s3ucvmtlydkl9rp3uxye/Shirley_1000x1250.jpg', SCHOOL_PAGE, 'press_use', None),
    (-4101985, 'Amy Tatom',       'https://resources.finalsite.net/images/v1760114029/bendk12orus/c9hy5vcxd4qqta33fess/Amy_1000x1250.jpg',     SCHOOL_PAGE, 'press_use', None),
    (-4101986, 'Ross Tomlin',     'https://resources.finalsite.net/images/v1760114033/bendk12orus/flpqxouy6c45gbkbztyh/Ross_1000x1250.jpg',    SCHOOL_PAGE, 'press_use', None),
    (-4101987, 'Kina Chadwick',   'https://resources.finalsite.net/images/v1760114030/bendk12orus/fpuk422ibw9hhk5vh2na/Kina_1000x1250.jpg',    SCHOOL_PAGE, 'press_use', None),

    # --- Bend Metro Park & Recreation District board: official district portraits ---
    (-4105821, 'Cary Schneider',   'https://www.bendparksandrec.org/wp-content/uploads/2024/10/cary.jpg',   PARK_PAGE, 'press_use', None),
    (-4105822, 'Deb Schoen',       'https://www.bendparksandrec.org/wp-content/uploads/2024/10/deb.jpg',    PARK_PAGE, 'press_use', None),
    (-4105823, 'Nathan Hovekamp',  'https://www.bendparksandrec.org/wp-content/uploads/2024/10/nathan.jpg', PARK_PAGE, 'press_use', None),
    (-4105824, 'Jodie Schiffman',  'https://www.bendparksandrec.org/wp-content/uploads/2024/10/jodie.jpg',  PARK_PAGE, 'press_use', None),
    (-4105825, 'Donna Owens',      'https://www.bendparksandrec.org/wp-content/uploads/2024/10/donna.jpg',  PARK_PAGE, 'press_use', None),

    # --- Candidates: own campaign sites (headshot policy 2026-07-08 allows campaign photos) ---
    # Imhoff's is a full-torso cutout on transparent white -> crop to head+shoulders.
    (-4101723, 'Rob Imhoff', 'https://robimhoff.com/wp-content/uploads/2025/10/Rob-imhoff-2025-2-842x1024.png',
     'https://robimhoff.com/', 'campaign_use', (0.08, 0.0, 0.95, 0.52)),
]


def load(url, ext):
    if url is None:
        return Image.open(f'{RAW}/{ext}.jpg')
    r = requests.get(url, headers=UA, timeout=30)
    r.raise_for_status()
    return Image.open(BytesIO(r.content))


def flatten(img):
    """Composite transparency onto white so cutout PNGs don't turn black in RGB."""
    if img.mode in ('RGBA', 'LA', 'P'):
        img = img.convert('RGBA')
        bg = Image.new('RGBA', img.size, (255, 255, 255, 255))
        img = Image.alpha_composite(bg, img)
    return img.convert('RGB')


def process(img, box):
    img = flatten(img)
    if box:
        w, h = img.size
        img = img.crop((int(box[0] * w), int(box[1] * h), int(box[2] * w), int(box[3] * h)))
    w, h = img.size
    tr = 4 / 5
    if w / h > tr:                       # too wide -> trim sides, centered
        nw = int(h * tr)
        left = (w - nw) // 2
        img = img.crop((left, 0, left + nw, h))
    else:                                # too tall -> trim height, biased to the TOP
        nh = int(w / tr)
        top = int((h - nh) * TOP_BIAS)
        img = img.crop((0, top, w, top + nh))
    return img.resize(TARGET, Image.LANCZOS)


out = []
for ext, name, url, page, lic, box in SUBJECTS:
    try:
        src = load(url, ext)
        orig = src.size
        img = process(src, box)
        img.save(f'{DIR}/{ext}.jpg', 'JPEG', quality=90)
        out.append({'external_id': ext, 'full_name': name, 'source_page': page,
                    'image_url': url or 'browser-context fetch from the official city bio page',
                    'license': lic, 'orig_size': list(orig), 'file': f'{ext}.jpg', 'ok': True})
        print(f'OK   {name:24} {orig[0]}x{orig[1]} -> 600x750')
    except Exception as e:
        out.append({'external_id': ext, 'full_name': name, 'image_url': url, 'ok': False, 'error': str(e)})
        print(f'FAIL {name:24} {e}')

with open(f'{DIR}/_review.json', 'w', encoding='utf-8') as f:
    json.dump(out, f, indent=2, ensure_ascii=False)

# contact sheet for a single-glance correct-person / composition review
ok = [o for o in out if o['ok']]
cols = 7
rows = (len(ok) + cols - 1) // cols
sheet = Image.new('RGB', (cols * 200, rows * 250), 'white')
for i, o in enumerate(ok):
    th = Image.open(f"{DIR}/{o['file']}").resize((200, 250), Image.LANCZOS)
    sheet.paste(th, ((i % cols) * 200, (i // cols) * 250))
sheet.save(f'{DIR}/_contact_sheet.jpg', 'JPEG', quality=85)
print(f"\n{len(ok)}/{len(out)} processed. Contact sheet: {DIR}/_contact_sheet.jpg")
print('order: ' + ', '.join(o['full_name'] for o in ok))
