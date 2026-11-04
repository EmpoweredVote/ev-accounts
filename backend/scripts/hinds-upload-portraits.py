#!/usr/bin/env python3
"""
Upload the approved Hinds County portraits to Supabase Storage, then PROVE each one landed.

SUPABASE STORAGE NEEDS BOTH `apikey` AND `Authorization`. A lone Bearer is refused as HTTP 400
with a body claiming 403 "Invalid Compact JWS", which reads like a missing object rather than a
missing header.

VERIFICATION IS A BYTE COMPARISON, NOT AN HTTP 200. The public URL is re-fetched and its sha256
compared with the local file. A missing object in this bucket answers 400, not 404, so status
alone cannot be trusted in either direction.

CONTROL: a key that was NEVER uploaded is fetched in the same pass. If it comes back as an image,
the verification is not reading what it thinks it is and no result from this run can be believed.

  py -3 scripts/hinds-upload-portraits.py --dir <portraits dir> --dry-run
  py -3 scripts/hinds-upload-portraits.py --dir <portraits dir>
"""
import argparse, hashlib, json, os, re, sys, uuid
import requests

BUCKET = 'politician_photos'
BASE = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1'
PUBLIC = BASE + '/object/public/' + BUCKET + '/'

ap = argparse.ArgumentParser()
ap.add_argument('--dir', default='.')
ap.add_argument('--dry-run', action='store_true')
args = ap.parse_args()
os.chdir(args.dir)

key = os.environ.get('SUPABASE_SERVICE_ROLE_KEY')
if not key:
    for cand in ('../../../.env', 'C:/EV-Accounts/backend/.env'):
        if os.path.exists(cand):
            m = re.search(r'^SUPABASE_SERVICE_ROLE_KEY\s*=\s*(\S+)',
                          open(cand, encoding='utf-8', errors='replace').read(), re.M)
            if m:
                key = m.group(1).strip('"\'')
                break
if not key:
    sys.exit('SUPABASE_SERVICE_ROLE_KEY is not set and no .env carried it')
H = {'apikey': key, 'Authorization': 'Bearer ' + key}

ship = json.load(open('hc-ship.json'))
proc = {r['key']: r for r in json.load(open('processed.json'))}

jobs = []
for p in ship:
    r = proc[p['key']]
    body = open(r['processed'], 'rb').read()
    if body[:2] != b'\xff\xd8':
        sys.exit('%s is not a JPEG' % r['processed'])
    jobs.append({'key': p['key'], 'pid': p['pid'], 'name': p['name'], 'seat': p['title'],
                 'object': p['pid'] + '-headshot.jpg', 'bytes': body,
                 'sha': hashlib.sha256(body).hexdigest(), 'source': p['img']})

print('%d file(s) ready' % len(jobs))
for j in jobs:
    print('   %-26s %-22s -> %s  %7db  %s'
          % (j['seat'], j['name'], j['object'], len(j['bytes']), j['sha'][:12]))
if args.dry_run:
    print('\n[dry run] nothing uploaded')
    sys.exit(0)

for j in jobs:
    r = requests.post(BASE + '/object/' + BUCKET + '/' + j['object'],
                      headers={**H, 'Content-Type': 'image/jpeg', 'x-upsert': 'true'},
                      data=j['bytes'], timeout=120)
    j['put'] = r.status_code
    print('  upload %-26s HTTP %s' % (j['seat'], r.status_code))

# ---- verification: re-fetch the PUBLIC url and compare bytes -------------------------------
print('\nverifying by byte comparison, not by status code')
bad = 0
for j in jobs:
    r = requests.get(PUBLIC + j['object'], timeout=120)
    got = hashlib.sha256(r.content).hexdigest() if r.status_code == 200 else None
    j['verified'] = (got == j['sha'])
    print('  %-26s HTTP %-3s  %s' % (j['seat'], r.status_code,
          'BYTES MATCH' if j['verified'] else 'MISMATCH  local %s got %s'
          % (j['sha'][:12], (got or 'n/a')[:12])))
    if not j['verified']:
        bad += 1

# ---- CONTROL: an object that was never uploaded must NOT come back as an image --------------
ctrl = str(uuid.uuid4()) + '-headshot.jpg'
rc = requests.get(PUBLIC + ctrl, timeout=60)
is_img = rc.status_code == 200 and rc.content[:2] == b'\xff\xd8'
print('\nCONTROL  never-uploaded key -> HTTP %s, %d bytes  %s'
      % (rc.status_code, len(rc.content),
         'FAILED: it returned an image, so the check above proves nothing' if is_img
         else 'OK: it is not an image, so a match above means something'))
if is_img:
    sys.exit('CONTROL FAILED')
if bad:
    sys.exit('%d object(s) did not verify' % bad)

json.dump([{k: v for k, v in j.items() if k != 'bytes'} for j in jobs],
          open('hc-uploaded.json', 'w'), indent=1)
print('\nall %d verified. urls:' % len(jobs))
for j in jobs:
    print('  %s' % (PUBLIC + j['object']))
