#!/usr/bin/env python3
"""Download + process Falls Church official portraits to 600x750, emit review JSON (base64 data URIs).
Does NOT upload — review first. Run: python data/stance-research/falls-church-va/_headshots.py
"""
import requests, os, json, base64
from PIL import Image
from io import BytesIO

REVIEW_DIR = 'data/stance-research/falls-church-va/headshots'
os.makedirs(REVIEW_DIR, exist_ok=True)

GOV = 'https://www.fallschurchva.gov/ImageRepository/Document?documentID='
APP = ''  # apptegy full urls inline

SUBJECTS = [
    # (external_id, full_name, title, source_page, image_url, license)
    (-5127200001, 'Letty Hardi', 'Mayor', 'https://www.fallschurchva.gov/directory.aspx?EID=235', GOV+'13850', 'press_use'),
    (-5127200002, 'Laura Downs', 'Vice Mayor', 'https://www.fallschurchva.gov/directory.aspx?EID=286', GOV+'21869', 'press_use'),
    (-5127200003, 'Justine Underhill', 'Council Member', 'https://www.fallschurchva.gov/directory.aspx?EID=280', GOV+'19615', 'press_use'),
    (-5127200004, 'Marybeth Connelly', 'Council Member', 'https://www.fallschurchva.gov/directory.aspx?EID=40', GOV+'13854', 'press_use'),
    (-5127200005, 'David Snyder', 'Council Member', 'https://www.fallschurchva.gov/directory.aspx?EID=26', GOV+'13852', 'press_use'),
    (-5127200006, 'Erin Flynn', 'Council Member', 'https://www.fallschurchva.gov/directory.aspx?EID=279', GOV+'19616', 'press_use'),
    (-5127200007, 'Arthur Agin', 'Council Member', 'https://www.fallschurchva.gov/directory.aspx?EID=291', GOV+'28324', 'press_use'),
    (-5127200008, 'Metin A. Cay', 'Sheriff', 'https://www.fallschurchva.gov/416/Sheriff', GOV+'18824', 'press_use'),
    (-5127200009, 'Jody Acosta', 'Treasurer', 'https://www.fallschurchva.gov/147/Treasurer', GOV+'2347', 'press_use'),
    (-5127200010, 'Thomas D. Clinton', 'Commissioner of the Revenue', 'https://www.fallschurchva.gov/directory.aspx?EID=48', GOV+'31788', 'press_use'),
    (-5101290001, 'Kathleen Tysse', 'School Board Chair', 'https://www.fccps.org/page/school-board', 'https://cmsv2-assets.apptegy.net/uploads/3850/file/5569752/a8166e85-ec5e-4d0b-8b80-5735b1f1fc88.jpeg', 'press_use'),
    (-5101290002, 'Anne Sherwood', 'School Board Vice Chair', 'https://www.fccps.org/page/school-board', 'https://cmsv2-assets.apptegy.net/uploads/3850/file/3938384/9d561314-41cf-41a3-901b-e760178e72d0.png', 'press_use'),
    (-5101290003, 'Jerrod Anderson', 'School Board Member', 'https://www.fccps.org/page/school-board', 'https://cmsv2-assets.apptegy.net/uploads/3850/file/1693902/14fc8015-a911-4537-8c3c-3bffd1689bc8.jpeg', 'press_use'),
    (-5101290004, 'Bethany Henderson', 'School Board Member', 'https://www.fccps.org/page/school-board', 'https://cmsv2-assets.apptegy.net/uploads/3850/file/2710679/4f0d5f45-0a29-44f6-9051-8dd7ba059987.jpeg', 'press_use'),
    (-5101290005, 'MaryKate Hughes', 'School Board Member', 'https://www.fccps.org/page/school-board', 'https://cmsv2-assets.apptegy.net/uploads/3850/file/5566626/7d0ba16d-a65f-44a6-ad9a-ee72404a59c8.jpeg', 'press_use'),
    (-5101290006, 'Amie Murphy', 'School Board Member', 'https://www.fccps.org/page/school-board', 'https://cmsv2-assets.apptegy.net/uploads/3850/file/2710680/6c19bc79-a52c-451c-81db-4b1e0f55a133.jpeg', 'press_use'),
    (-5101290007, 'Lori Silverman', 'School Board Member', 'https://www.fccps.org/page/school-board', 'https://cmsv2-assets.apptegy.net/uploads/3850/file/771626/959ca0d4-15e0-44bd-973d-47ee0340ccd9.png', 'press_use'),
]

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
    img = img.resize((600,750), Image.LANCZOS)
    return img, (w, h)

out = []
for ext, name, title, page, url, lic in SUBJECTS:
    try:
        img, orig = process(url)
        fn = f'{ext}.jpg'
        path = os.path.join(REVIEW_DIR, fn)
        img.save(path, 'JPEG', quality=90)
        buf = BytesIO(); img.save(buf, 'JPEG', quality=70)
        b64 = base64.b64encode(buf.getvalue()).decode()
        out.append({'external_id': ext, 'full_name': name, 'title': title, 'source_page': page,
                    'image_url': url, 'license': lic, 'orig_size': orig, 'file': fn,
                    'data_uri': 'data:image/jpeg;base64,'+b64, 'ok': True})
        print(f'OK   {name:22} orig {orig[0]}x{orig[1]} -> 600x750')
    except Exception as e:
        out.append({'external_id': ext, 'full_name': name, 'title': title, 'image_url': url, 'ok': False, 'error': str(e)})
        print(f'FAIL {name:22} {e}')

with open(os.path.join(REVIEW_DIR, '_review.json'), 'w') as f:
    json.dump(out, f, indent=2)
print(f'\n{sum(1 for o in out if o["ok"])}/{len(out)} processed. Review JSON written.')
