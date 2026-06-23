#!/usr/bin/env python3
"""Download + process Greene County MO official portraits to 600x750, emit review JSON.
Sources: greenecountymo.gov/files/file.php?id=NNN (official, press_use). Does NOT upload.
Run: python data/stance-research/greene-county-mo/_headshots.py
"""
import requests, os, json, base64
from PIL import Image
from io import BytesIO

REVIEW_DIR = 'data/stance-research/greene-county-mo/headshots'
os.makedirs(REVIEW_DIR, exist_ok=True)
B = 'https://greenecountymo.gov/files/file.php?id='

SUBJECTS = [
    (-29077001, 'Bob Dixon',               'Presiding Commissioner',       B+'33391'),
    (-29077002, 'Rusty MacLachlan',        'Commissioner, 1st District',   B+'36415'),
    (-29077003, 'John C. Russell',         'Commissioner, 2nd District',   B+'33408'),
    (-29077004, 'Jim Arnott',              'Sheriff',                      B+'238'),
    (-29077005, 'Dan Patterson',           'Prosecuting Attorney',         B+'37'),
    (-29077006, 'Brent Johnson',           'Assessor',                     B+'228'),
    (-29077007, 'Allen Icet',              'Collector of Revenue',         B+'36673'),
    (-29077008, 'Shane Schoeller',         'County Clerk',                 B+'230'),
    (-29077009, 'Bryan Feemster',          'Circuit Clerk',                B+'240'),
    (-29077010, 'Cheryl Dawson-Spaulding', 'Recorder of Deeds',            B+'237'),
    (-29077011, 'Justin Hill',             'Treasurer',                    B+'239'),
    (-29077012, 'Cindy Stein',             'Auditor',                      B+'11612'),
    (-29077013, 'Sherri Martin',           'Public Administrator',         B+'36417'),
]
SRC_PAGE = 'https://greenecountymo.gov/about/elected_officials.php'

def process(url):
    r = requests.get(url, headers={'User-Agent': 'Mozilla/5.0'}, timeout=20)
    r.raise_for_status()
    img = Image.open(BytesIO(r.content)).convert('RGB')
    w, h = img.size
    tr = 4/5
    if w/h > tr:
        nw = int(h*tr); left = (w-nw)//2; img = img.crop((left,0,left+nw,h))
    else:
        nh = int(w/tr); top = (h-nh)//2; img = img.crop((0,top,w,top+nh))
    return img.resize((600,750), Image.LANCZOS), (w, h)

out = []
for ext, name, title, url in SUBJECTS:
    try:
        img, orig = process(url)
        fn = f'{ext}.jpg'
        img.save(os.path.join(REVIEW_DIR, fn), 'JPEG', quality=90)
        buf = BytesIO(); img.save(buf, 'JPEG', quality=70)
        b64 = base64.b64encode(buf.getvalue()).decode()
        out.append({'external_id': ext, 'full_name': name, 'title': title, 'source_page': SRC_PAGE,
                    'image_url': url, 'license': 'press_use', 'orig_size': orig, 'file': fn,
                    'data_uri': 'data:image/jpeg;base64,'+b64, 'ok': True})
        print(f'OK   {name:24} orig {orig[0]}x{orig[1]} -> 600x750')
    except Exception as e:
        out.append({'external_id': ext, 'full_name': name, 'title': title, 'image_url': url, 'ok': False, 'error': str(e)})
        print(f'FAIL {name:24} {e}')

with open(os.path.join(REVIEW_DIR, '_review.json'), 'w') as f:
    json.dump(out, f, indent=2)
print(f'\n{sum(1 for o in out if o["ok"])}/{len(out)} processed.')
