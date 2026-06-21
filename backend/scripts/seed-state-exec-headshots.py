"""
seed-state-exec-headshots.py — Phase 141 (v2.18 State Leaders) Wave 2, plans 141-08..12.

Sources + processes + uploads a headshot for every newly-seeded elected Big-5 exec that lacks one,
then records it in essentials.politician_images (column `url`). Self-targeting + idempotent: it selects
exactly the SEXR-04 set (41-state seeds + IN Morales/Elliott) that has NO politician_images row, so a
re-run only fills remaining gaps.

Pipeline (per migration 271 / _tmp-va-execs-headshots.py + feedback_headshot_resize_no_distort):
  Wikipedia pageimages API (lead portrait) -> license via imageinfo extmetadata (FREE licenses only) ->
  download -> RGB -> CROP 4:5 first (never stretch) -> RESIZE 600x750 LANCZOS q90 ->
  upload to politician_photos/{uuid}-headshot.jpg (x-upsert) -> INSERT politician_images WHERE NOT EXISTS.

Wrong-person guard (T-141-11): the resolved Wikipedia page's wikidata description MUST contain a political
keyword (or the officeholder's state), else honest-skip. Non-free/fair-use images: honest-skip (T-141-12).

Usage:
  python backend/scripts/seed-state-exec-headshots.py [--batch A|B|C|D|E|ALL] [--dry-run]
Writes backend/scripts/_state-exec-headshot-results.json (consumed by the audit-migration generator).
"""
import os, io, sys, json, time, urllib.parse
import requests
import psycopg2
from PIL import Image

ENV = {}
with open(os.path.join(os.path.dirname(__file__), '..', '.env')) as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith('#') and '=' in line:
            k, v = line.split('=', 1); ENV[k.strip()] = v.strip()

SUPABASE_URL = ENV['SUPABASE_URL']
SERVICE_KEY = ENV['SUPABASE_SERVICE_ROLE_KEY']
DATABASE_URL = ENV['DATABASE_URL']
BUCKET = 'politician_photos'
CDN_BASE = f'{SUPABASE_URL.replace(".supabase.co", ".storage.supabase.co")}/storage/v1/object/public/{BUCKET}'
TARGET_SIZE = (600, 750)
JPEG_QUALITY = 90
UA = 'EmpoweredVote-civic-data/1.0 (https://empowered.vote; contact chris@empowered.vote)'
WIKI_API = 'https://en.wikipedia.org/w/api.php'

POLITICAL_KW = ['politic', 'governor', 'attorney general', 'secretary of state', 'treasurer',
                'comptroller', 'lieutenant', 'senator', 'representative', 'mayor', 'official',
                'commissioner', 'auditor', 'state of', 'american', 'chief financial']

# batch -> state list (FIPS-derived), used only to filter by --batch
BATCH_STATES = {
    'A': {'AK','AL','FL','IL','MS','NC','NY','SD'},
    'B': {'AR','GA','HI','IA','MO','ND','OK','VT'},
    'C': {'CO','KS','MI','NE','NJ','OH','PA','WA'},
    'D': {'CT','KY','MN','NH','NV','RI','TN','WI','WV'},
    'E': {'AZ','DE','ID','LA','MT','NM','SC','WY'},
}

def wiki_get(params):
    p = {'format': 'json', 'redirects': '1', **params}
    r = requests.get(WIKI_API, params=p, headers={'User-Agent': UA}, timeout=30)
    r.raise_for_status()
    return r.json()

ROLE_WORD = {'governor':'governor','lt_governor':'lieutenant governor','attorney_general':'attorney general',
             'secretary_of_state':'secretary of state','treasurer':'treasurer'}

def _try_title(title):
    """pageimages|description for one title; return (page_dict, desc) or (None,None)."""
    data = wiki_get({'action': 'query', 'prop': 'pageimages|description|pageprops',
                     'piprop': 'original|thumbnail', 'pithumbsize': '800', 'titles': title})
    page = next(iter(data.get('query', {}).get('pages', {}).values()), {})
    if 'missing' in page or page.get('pageid', 0) < 0:
        return None, None
    if 'disambiguation' in page.get('pageprops', {}):
        return None, 'disambig'
    return page, (page.get('description') or '').lower()

def _search_title(full_name, state_name, role_word):
    """Use search to find the correct politician page when the bare title is ambiguous."""
    q = f'{full_name} {state_name} {role_word}'
    data = wiki_get({'action': 'query', 'list': 'search', 'srsearch': q, 'srlimit': '1'})
    hits = data.get('query', {}).get('search', [])
    return hits[0]['title'] if hits else None

def resolve_portrait(full_name, state_name, role=''):
    """Return (image_url, license_str, page_title) or (None, reason, None)."""
    role_word = ROLE_WORD.get(role, '')
    page, desc = _try_title(full_name)
    political = page is not None and desc != 'disambig' and (
        not desc or any(k in desc for k in POLITICAL_KW) or state_name.lower() in desc)
    if not political:
        # disambiguation / wrong-person / missing -> search by name+state+office
        st = _search_title(full_name, state_name, role_word)
        if st and st.lower() != full_name.lower():
            page, desc = _try_title(st)
            political = page is not None and desc != 'disambig' and (
                not desc or any(k in desc for k in POLITICAL_KW) or state_name.lower() in desc)
    if page is None:
        return None, 'no-wikipedia-page', None
    if desc == 'disambig':
        return None, 'disambiguation-unresolved', full_name
    if not political:
        return None, f'desc-not-political:"{(desc or "")[:50]}"', page.get('title')
    title = page.get('title', full_name)
    img_url = page.get('original', {}).get('source')
    thumb = page.get('thumbnail', {}).get('source')
    if not img_url and not thumb:
        return None, 'no-lead-image', title
    # license via imageinfo extmetadata on the File: page (use original filename when available)
    ref = img_url or thumb
    fname = 'File:' + urllib.parse.unquote(ref.split('/')[-1])
    try:
        ii = wiki_get({'action': 'query', 'prop': 'imageinfo', 'iiprop': 'extmetadata', 'titles': fname})
        ipage = next(iter(ii.get('query', {}).get('pages', {}).values()), {})
        ext = (ipage.get('imageinfo') or [{}])[0].get('extmetadata', {})
        lic = (ext.get('LicenseShortName', {}).get('value', '') or '').strip()
    except Exception:
        lic = ''
    low = lic.lower()
    nonfree = ('fair use' in low or 'non-free' in low or 'nonfree' in low or 'all rights reserved' in low)
    free = (not nonfree) and ('public domain' in low or low.startswith('cc') or low.startswith('pd')
            or 'no restrictions' in low or 'cc0' in low or 'copyrighted free use' in low
            or 'free use' in low or 'wtfpl' in low or 'attribution' in low or 'gfdl' in low
            or 'free art' in low or 'flickr' in low)
    if lic and not free:
        return None, f'non-free-license:{lic}', title
    photo_license = 'public_domain' if ('public domain' in low or 'pd' in low or not lic) else lic.replace(' ', '_').lower()
    # candidate URLs: prefer original, fall back to 800px thumbnail (handles odd formats / transient errors)
    cands = [u for u in (img_url, thumb) if u]
    return cands, photo_license, title

def crop_to_4_5(img):
    w, h = img.size
    target = 4/5
    if w/h > target:  # too wide -> center-crop width
        nw = int(h*target); left = (w-nw)//2
        return img.crop((left, 0, left+nw, h))
    else:             # too tall -> top-crop (keep head)
        nh = int(w/target)
        return img.crop((0, 0, w, nh))

def download(url):
    r = requests.get(url, headers={'User-Agent': UA, 'Accept': 'image/*,*/*;q=0.8'}, timeout=60)
    r.raise_for_status()
    return r.content

def upload(uuid, jpeg):
    url = f'{SUPABASE_URL}/storage/v1/object/{BUCKET}/{uuid}-headshot.jpg'
    r = requests.put(url, data=jpeg,
                     headers={'Authorization': f'Bearer {SERVICE_KEY}', 'Content-Type': 'image/jpeg', 'x-upsert': 'true'},
                     timeout=60)
    if r.status_code not in (200, 201):
        raise Exception(f'upload {r.status_code}: {r.text[:200]}')
    return f'{CDN_BASE}/{uuid}-headshot.jpg'

def run_manual(manual_path):
    """Process explicit external_id|direct_image_url|license rows (2nd-source .gov/Ballotpedia portraits)."""
    conn = psycopg2.connect(DATABASE_URL); conn.autocommit = False
    cur = conn.cursor()
    results = []
    for line in open(manual_path):
        line = line.strip()
        if not line or line.startswith('#'): continue
        ext, url, lic = (line.split('|') + ['', ''])[:3]
        ext = int(ext)
        cur.execute("SELECT id, full_name FROM essentials.politicians WHERE external_id=%s", (ext,))
        row = cur.fetchone()
        if not row:
            print(f'  ERR ext {ext}: not in DB'); continue
        uuid, name = str(row[0]), row[1]
        res = {'external_id': ext, 'full_name': name, 'state': '?', 'uuid': uuid}
        try:
            raw = open(url, 'rb').read() if not url.startswith('http') else download(url)
            img = Image.open(io.BytesIO(raw))
            if img.mode != 'RGB': img = img.convert('RGB')
            if img.width < 120 or img.height < 120:
                raise Exception(f'too-small:{img.width}x{img.height}')
            img = crop_to_4_5(img).resize(TARGET_SIZE, Image.Resampling.LANCZOS)
            buf = io.BytesIO(); img.save(buf, format='JPEG', quality=JPEG_QUALITY, optimize=True)
            cdn = upload(uuid, buf.getvalue())
            cur.execute("""INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
                           SELECT gen_random_uuid(), %s::uuid, %s, 'default', %s
                           WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id=%s::uuid)""",
                        (uuid, cdn, lic or 'public_domain', uuid))
            conn.commit()
            res.update(success=True, license=lic or 'public_domain', source=url, cdn=cdn); print(f'  OK {name} (ext {ext}) lic={lic}')
        except Exception as e:
            conn.rollback(); res.update(success=False, skip_reason=f'manual-error:{str(e)[:60]}'); print(f'  ERR {name}: {e}')
        results.append(res); time.sleep(0.2)
    # merge into results JSON
    out = os.path.join(os.path.dirname(__file__), '_state-exec-headshot-results.json')
    prior = json.load(open(out)) if os.path.exists(out) else []
    by_ext = {r['external_id']: r for r in prior}
    for r in results:
        # preserve the real state from prior record
        if r['external_id'] in by_ext: r['state'] = by_ext[r['external_id']].get('state', r['state'])
        by_ext[r['external_id']] = r
    json.dump(list(by_ext.values()), open(out, 'w'), indent=1)
    ok = sum(1 for r in results if r.get('success'))
    print(f'\n=== MANUAL DONE: {ok}/{len(results)} uploaded ===')
    cur.close(); conn.close()

def main():
    batch = 'ALL'; dry = False; manual = None
    args = sys.argv[1:]
    for i, a in enumerate(args):
        if a == '--dry-run': dry = True
        elif a == '--manual': manual = args[i+1] if i+1 < len(args) else None
        elif a.startswith('--manual='): manual = a.split('=', 1)[1]
        elif a.startswith('--batch'): batch = a.split('=')[-1] if '=' in a else 'ALL'
        elif a in BATCH_STATES or a == 'ALL': batch = a
    if manual:
        return run_manual(manual)
    states = None if batch == 'ALL' else BATCH_STATES[batch]

    conn = psycopg2.connect(DATABASE_URL); conn.autocommit = False
    cur = conn.cursor()
    cur.execute("""
        SELECT p.id, p.external_id, p.full_name, d.state, o.role_canonical
        FROM essentials.politicians p
        JOIN essentials.offices o ON o.politician_id = p.id
        JOIN essentials.districts d ON d.id = o.district_id
        WHERE d.district_type='STATE_EXEC'
          AND o.role_canonical IN ('governor','lt_governor','attorney_general','secretary_of_state','treasurer')
          AND ((p.external_id <= -100001 AND p.external_id NOT BETWEEN -4900009 AND -4900001)
               OR p.external_id IN (642977, 688298))
          AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id)
        ORDER BY d.state, p.external_id;
    """)
    rows = cur.fetchall()
    STATE_NAME = {'AK':'Alaska','AL':'Alabama','AZ':'Arizona','AR':'Arkansas','CO':'Colorado','CT':'Connecticut','DE':'Delaware','FL':'Florida','GA':'Georgia','HI':'Hawaii','IA':'Iowa','ID':'Idaho','IL':'Illinois','KS':'Kansas','KY':'Kentucky','LA':'Louisiana','MI':'Michigan','MN':'Minnesota','MO':'Missouri','MS':'Mississippi','MT':'Montana','NC':'North Carolina','ND':'North Dakota','NE':'Nebraska','NH':'New Hampshire','NJ':'New Jersey','NM':'New Mexico','NV':'Nevada','NY':'New York','OH':'Ohio','OK':'Oklahoma','PA':'Pennsylvania','RI':'Rhode Island','SC':'South Carolina','SD':'South Dakota','TN':'Tennessee','VT':'Vermont','WA':'Washington','WI':'Wisconsin','WV':'West Virginia','WY':'Wyoming','IN':'Indiana'}
    targets = [r for r in rows if states is None or r[3] in states]
    print(f'Targets needing headshot: {len(targets)} (batch={batch})')
    results = []
    for uuid, ext, name, st, role in targets:
        sname = STATE_NAME.get(st, st)
        res = {'external_id': ext, 'full_name': name, 'state': st, 'uuid': str(uuid)}
        try:
            cands, lic_or_reason, title = resolve_portrait(name, sname, role)
            if not cands:
                res.update(success=False, skip_reason=lic_or_reason); print(f'  SKIP {name} ({st}): {lic_or_reason}')
                results.append(res); time.sleep(0.3); continue
            img = None; used = None; last_err = None
            for u in cands:
                try:
                    cand = Image.open(io.BytesIO(download(u)))
                    if cand.mode != 'RGB': cand = cand.convert('RGB')
                    if cand.width < 200 or cand.height < 200:
                        last_err = f'too-small:{cand.width}x{cand.height}'; continue
                    img = cand; used = u; break
                except Exception as ie:
                    last_err = f'open:{str(ie)[:40]}'; continue
            if img is None:
                res.update(success=False, skip_reason=last_err or 'no-usable-image'); print(f'  SKIP {name} ({st}): {last_err}')
                results.append(res); time.sleep(0.3); continue
            img_url = used
            img = crop_to_4_5(img).resize(TARGET_SIZE, Image.Resampling.LANCZOS)
            buf = io.BytesIO(); img.save(buf, format='JPEG', quality=JPEG_QUALITY, optimize=True)
            if dry:
                res.update(success=True, license=lic_or_reason, source=img_url, cdn=None, dry=True); print(f'  OK(dry) {name} ({st}) lic={lic_or_reason}')
                results.append(res); time.sleep(0.3); continue
            cdn = upload(str(uuid), buf.getvalue())
            cur.execute("""INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
                           SELECT gen_random_uuid(), %s::uuid, %s, 'default', %s
                           WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id=%s::uuid)""",
                        (str(uuid), cdn, lic_or_reason, str(uuid)))
            conn.commit()
            res.update(success=True, license=lic_or_reason, source=img_url, cdn=cdn); print(f'  OK {name} ({st}) lic={lic_or_reason}')
        except Exception as e:
            conn.rollback()
            res.update(success=False, skip_reason=f'error:{str(e)[:80]}'); print(f'  ERR {name} ({st}): {e}')
        results.append(res); time.sleep(0.3)

    ok = sum(1 for r in results if r.get('success'))
    sk = len(results) - ok
    print(f'\n=== DONE batch={batch}: {ok} uploaded, {sk} honest-skip of {len(results)} ===')
    for r in results:
        if not r.get('success'): print(f'  skip: {r["external_id"]} {r["full_name"]} ({r["state"]}) -> {r["skip_reason"]}')
    out = os.path.join(os.path.dirname(__file__), '_state-exec-headshot-results.json')
    # merge with any prior results so multi-batch runs accumulate
    prior = []
    if os.path.exists(out):
        try: prior = json.load(open(out))
        except Exception: prior = []
    by_ext = {r['external_id']: r for r in prior}
    for r in results: by_ext[r['external_id']] = r
    json.dump(list(by_ext.values()), open(out, 'w'), indent=1)
    cur.close(); conn.close()

if __name__ == '__main__':
    main()
