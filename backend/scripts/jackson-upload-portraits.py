#!/usr/bin/env python3
"""
Upload the 8 approved Jackson portraits to Supabase Storage, then PROVE each one landed.

🔴 SUPABASE STORAGE NEEDS BOTH `apikey` AND `Authorization`. A lone Bearer is refused as HTTP 400
with a body claiming 403 "Invalid Compact JWS", which reads like a missing object rather than a
missing header.

🔴 VERIFICATION IS A BYTE COMPARISON, NOT AN HTTP 200. The public URL is re-fetched and its sha256
compared with the local file. A missing object in this bucket answers 400, not 404, so status
alone cannot be trusted in either direction.

🔴 CONTROL: a key that was NEVER uploaded is fetched in the same pass. If it comes back as an
image, the verification is not reading what it thinks it is.

  py -3 scripts/jackson-upload-portraits.py --src <dir of <key>.jpg> --dry-run
  py -3 scripts/jackson-upload-portraits.py --src <dir>
"""
import argparse, hashlib, json, os, sys
import requests

BUCKET = 'politician_photos'
BASE = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1'
PUBLIC = f'{BASE}/object/public/{BUCKET}/'

# key in the processed set -> (politician uuid, name, seat)
PEOPLE = [
    ('mayor', 'f6784ca0-54d6-4286-97ee-5ea7f7735d7c', 'John Horhn', 'Mayor'),
    ('ward1', '82f30af3-7ad4-4fcc-9117-cb45bbe58343', 'Ashby M. Foote III', 'Council Member, Ward 1'),
    ('ward2', '82c06258-02e0-4921-a1b8-bb8376a63226', 'Montyne Clay', 'Council Member, Ward 2'),
    ('ward3', '5c6283a1-ce05-4c48-9020-3523c76a0867', 'Kenneth Stokes', 'Council Member, Ward 3'),
    ('ward4', 'a8eba8fc-9bc1-4820-95a9-6e7969c20c14', 'Brian C. Grizzell', 'Council Member, Ward 4'),
    ('ward5', '41c02c13-2e1f-403d-9125-96d4b60b372c', 'Vernon Hartley', 'Council Member, Ward 5'),
    ('ward6', '6b0c7f1a-c4ba-4be5-96f3-d58565974f65', 'Lashia Brown-Thomas', 'Council Member, Ward 6'),
    ('ward7', '686f9d17-591d-4a5d-b2a9-f1d3026566a8', 'Kevin Parkinson', 'Council Member, Ward 7'),
]

ap = argparse.ArgumentParser()
ap.add_argument('--src', required=True)
ap.add_argument('--dry-run', action='store_true')
args = ap.parse_args()

key = os.environ.get('SUPABASE_SERVICE_ROLE_KEY')
if not key:
    sys.exit('SUPABASE_SERVICE_ROLE_KEY is not set')
H = {'apikey': key, 'Authorization': f'Bearer {key}'}

jobs = []
for slug, pid, name, seat in PEOPLE:
    src = os.path.join(args.src, f'{slug}.jpg')
    if not os.path.exists(src):
        sys.exit(f'missing {src}')
    body = open(src, 'rb').read()
    if body[:2] != b'\xff\xd8':
        sys.exit(f'{src} is not a JPEG')
    jobs.append({'slug': slug, 'pid': pid, 'name': name, 'seat': seat,
                 'object': f'{pid}-headshot.jpg', 'bytes': body,
                 'sha': hashlib.sha256(body).hexdigest()})

print(f'{len(jobs)} file(s) ready')
if args.dry_run:
    for j in jobs:
        print(f"  [dry-run] {j['seat']:24} {j['name']:22} -> {j['object']}  {len(j['bytes']):>7}b  {j['sha'][:12]}")
    sys.exit(0)

for j in jobs:
    r = requests.post(f"{BASE}/object/{BUCKET}/{j['object']}", headers={**H, 'Content-Type': 'image/jpeg',
                      'x-upsert': 'true'}, data=j['bytes'], timeout=120)
    j['put'] = r.status_code
    print(f"  upload {j['seat']:24} HTTP {r.status_code}")

# ── verification: bytes, not status ──────────────────────────────────────────
print('\nverifying by sha256 of the re-fetched public object')
bad = 0
for j in jobs:
    g = requests.get(PUBLIC + j['object'] + '?cb=verify', timeout=120)
    got = hashlib.sha256(g.content).hexdigest() if g.ok else None
    same = got == j['sha']
    if not same:
        bad += 1
    print(f"  {j['seat']:24} HTTP {g.status_code} {len(g.content):>7}b  {'MATCH' if same else 'MISMATCH'}")

# ── CONTROL: an object that was never uploaded ───────────────────────────────
c = requests.get(PUBLIC + '00000000-0000-0000-0000-00000000dead-headshot.jpg?cb=control', timeout=60)
is_img = c.ok and c.content[:2] == b'\xff\xd8'
print(f"\nCONTROL never-uploaded key -> HTTP {c.status_code}, {len(c.content)}b, "
      f"{'IMAGE (verification is blind)' if is_img else 'not an image (verification reads real objects)'}")
if is_img:
    sys.exit('CONTROL FAILED')
if bad:
    sys.exit(f'{bad} object(s) did not match their local bytes')

json.dump([{k: v for k, v in j.items() if k != 'bytes'} for j in jobs],
          open(os.path.join(args.src, 'uploaded.json'), 'w'), indent=1)
print(f'\nOK — {len(jobs)} object(s) uploaded and byte-verified; control fired.')
