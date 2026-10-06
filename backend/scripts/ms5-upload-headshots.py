#!/usr/bin/env python3
"""
Upload the 18 approved MS-5 headshots to Supabase Storage, then PROVE each one landed.

Supabase Storage needs BOTH `apikey` and `Authorization` since the legacy keys were disabled;
a lone Bearer token is refused as HTTP 400 with a body claiming 403 "Invalid Compact JWS", which
reads like a missing object rather than a missing header.

Verification is a byte comparison, not an HTTP 200: the public URL is re-fetched and its sha256
compared to the local file. A missing object in this bucket answers 400, not 404, so status alone
cannot be trusted either way.

CONTROL: a key that was never uploaded is fetched in the same pass. If it comes back as an image,
the verification is not reading what it thinks it is.
"""
import os, sys, json, glob, hashlib, time
import requests

BUCKET = 'politician_photos'
BASE = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1'
PUBLIC = f'{BASE}/object/public/{BUCKET}/'

key = os.environ.get('SUPABASE_SERVICE_ROLE_KEY')
if not key:
    sys.exit('SUPABASE_SERVICE_ROLE_KEY is not set')
H = {'apikey': key, 'Authorization': f'Bearer {key}'}

files = []
for d in ('biloxi-processed', 'harrison-processed'):
    files += sorted(glob.glob(f'data/seed-ms-2026/_assets/{d}/*.jpg'))
print(f'{len(files)} files to upload\n')

results = []
for p in files:
    name = os.path.basename(p)
    data = open(p, 'rb').read()
    local = hashlib.sha256(data).hexdigest()
    r = requests.post(f'{BASE}/object/{BUCKET}/{name}', headers={**H, 'Content-Type': 'image/jpeg',
                                                                'x-upsert': 'true'}, data=data, timeout=60)
    ok = r.status_code in (200, 201)
    print(f'  {"OK " if ok else "ERR"} {r.status_code}  {name}  {len(data):>7,}B')
    if not ok:
        print('      ' + r.text[:200])
    results.append({'file': name, 'path': p, 'sha256': local, 'upload_status': r.status_code})

print('\nverifying by byte comparison (a 200 is not proof):')
bad = 0
for row in results:
    time.sleep(0.05)
    u = PUBLIC + row['file'] + '?v=ms5verify'
    rr = requests.get(u, timeout=60)
    remote = hashlib.sha256(rr.content).hexdigest()
    match = remote == row['sha256']
    row['verified'] = match
    if not match:
        bad += 1
        print(f'  MISMATCH {row["file"]}  http={rr.status_code} bytes={len(rr.content)}')

# CONTROL -- never uploaded. Must NOT be an image.
cu = PUBLIC + 'ms5-control-never-uploaded.jpg?v=ms5verify'
cr = requests.get(cu, timeout=30)
is_img = cr.content[:2] == b'\xff\xd8'
print(f'\nCONTROL never-uploaded key: HTTP {cr.status_code}, {len(cr.content)}B, '
      + ('RETURNED AN IMAGE -- verification above is meaningless' if is_img else 'not an image (correct)'))

print(f'\n{len(results) - bad} of {len(results)} verified byte-identical')
json.dump(results, open('data/seed-ms-2026/_assets/upload-results.json', 'w'), indent=2)
sys.exit(1 if bad or is_img else 0)
