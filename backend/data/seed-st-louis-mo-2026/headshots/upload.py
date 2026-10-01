"""Upload the 32 St. Louis renders to Supabase Storage and emit the SQL that makes them render.

Reads SUPABASE_SERVICE_ROLE_KEY from backend/.env. The key is never printed.

Storage sends BOTH apikey and Authorization: a lone Bearer token is refused as
HTTP 400 with body 403 "Invalid Compact JWS", which reads like a missing object.
"""
import csv, json, os, sys, urllib.request, urllib.error, io

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = 'kxsdzaojfaibhuzmclfq'
BUCKET = 'politician_photos'
CDN = f'https://{PROJ}.storage.supabase.co/storage/v1/object/public/{BUCKET}/'
API = f'https://{PROJ}.supabase.co/storage/v1/object/{BUCKET}/'

# key from backend/.env, never echoed
key = None
for line in open(os.path.join(HERE, '..', '..', '..', '.env'), encoding='utf-8', errors='replace'):
    line = line.strip()
    if line.startswith('SUPABASE_SERVICE_ROLE_KEY'):
        key = line.split('=', 1)[1].strip().strip('"').strip("'")
        break
if not key:
    sys.exit('SUPABASE_SERVICE_ROLE_KEY not found in backend/.env')
print('service key loaded, length', len(key))

IDS = json.load(open(os.path.join(HERE, 'politician-ids.json'), encoding='utf-8'))
manifest = {r['eid']: r for r in json.load(open(os.path.join(HERE, 'sheet-manifest.json'), encoding='utf-8'))}

ok, fail, sql = 0, 0, []
for eid, pid in IDS.items():
    r = manifest[eid]
    path = os.path.join(HERE, 'render', eid + '.jpg')
    data = open(path, 'rb').read()
    fname = f'{pid}-headshot.jpg'
    req = urllib.request.Request(API + fname, data=data, method='POST', headers={
        'apikey': key,
        'Authorization': 'Bearer ' + key,
        'Content-Type': 'image/jpeg',
        'x-upsert': 'true',
    })
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            code = resp.status
    except urllib.error.HTTPError as e:
        code = e.code
        print(f'  FAIL {r["name"]:24s} HTTP {code} {e.read()[:120]!r}')
        fail += 1
        continue
    except Exception as e:
        print(f'  FAIL {r["name"]:24s} {e}')
        fail += 1
        continue
    if code not in (200, 201):
        print(f'  FAIL {r["name"]:24s} HTTP {code}')
        fail += 1
        continue
    ok += 1
    url = CDN + fname
    src = r['page'].replace("'", "''")
    sql.append(
        "UPDATE essentials.politicians SET photo_custom_url='%s', photo_origin_url='%s' WHERE id='%s';"
        % (url, src, pid))
    sql.append(
        "INSERT INTO essentials.politician_images (politician_id, url, type, photo_license) "
        "SELECT '%s','%s','default','press_use' WHERE NOT EXISTS "
        "(SELECT 1 FROM essentials.politician_images WHERE politician_id='%s' AND type='default');"
        % (pid, url, pid))
    print(f'  ok   {r["name"]:24s} {len(data)//1024:3d}KB  {fname}')

print(f'\nuploaded {ok}, failed {fail}')
open(os.path.join(HERE, 'apply-photos.sql'), 'w', encoding='utf-8').write(
    'BEGIN;\n' + '\n'.join(sql) + '\n\nDO $$\nDECLARE v int;\nBEGIN\n'
    "  SELECT count(*) INTO v FROM essentials.politicians\n"
    "   WHERE external_id BETWEEN -2790432 AND -2790401\n"
    "     AND photo_custom_url LIKE 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/%';\n"
    "  IF v <> 32 THEN RAISE EXCEPTION 'photo gate: % of 32 carry a CDN photo_custom_url', v; END IF;\n"
    "  SELECT count(*) INTO v FROM essentials.politician_images pi\n"
    "   JOIN essentials.politicians p ON p.id = pi.politician_id\n"
    "   WHERE p.external_id BETWEEN -2790432 AND -2790401;\n"
    "  IF v <> 32 THEN RAISE EXCEPTION 'photo gate: % of 32 politician_images rows', v; END IF;\n"
    "  RAISE NOTICE 'photo gate PASSED: 32 photo_custom_url + 32 politician_images rows';\n"
    'END $$;\nCOMMIT;\n')
print('wrote apply-photos.sql')
