"""
seed-ks-house-headshots.py — Phase 164-01 (v2.22 Wave 3). CLONE of seed-mo-house-headshots.py, all
guards intact incl. Phase-156 hardening (dropped 'american' kw + pre-1940 historical-year reject).
Only changes: KS band, KS state name, RESULTS_JSON, and the localized ", kansas" place-token in
_NON_PERSON_TITLE (the one token every state clone localizes; the hardened _BAD_DISAMBIG /
_HISTORICAL_YEAR / POLITICAL_KW guards are byte-for-byte unchanged).

CLONE of seed-ca-house-headshots.py (the validated Phase-149 pipeline) — ALL guards intact. The ONLY
target-selection change is MO's new-candidate external_id band -290899..-290101 from 162-02.
New challengers have NO essentials.offices row, so the band query is used (not an offices-join).

NOTE (162-02 D-01b): MO's 5 severe (redistricting-withheld) districts' candidates are seeded on the
"MO 2026 Congressional Redistricting - Polygon Pending" election, NOT the general — but they still
get headshots here. The target query is scoped by external_id BAND ONLY (no election-name join),
because seeding is complete regardless of whether the district's race currently surfaces on
/elections. Incumbents (-29001..-29008) are excluded by construction (they fall outside the band).

Pipeline (UNCHANGED): Wikipedia pageimages -> license via imageinfo extmetadata (FREE only) ->
download -> RGB -> CROP 4:5 -> RESIZE 600x750 LANCZOS q90 -> upload politician_photos/{uuid}-headshot.jpg
(x-upsert) -> INSERT politician_images WHERE NOT EXISTS. Hardened wrong-person guard (title must
contain candidate first+surname; reject election/place/event + non-political disambiguators).

Usage:
  python backend/scripts/seed-mo-house-headshots.py --state MO [--dry-run]
  python backend/scripts/seed-mo-house-headshots.py --manual <file>   (external_id|image_url|license)
Writes backend/scripts/_mo-house-headshot-results.json.
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
                'commissioner', 'auditor', 'state of', 'chief financial',
                'congress', 'candidate', 'assembly', 'councilmember', 'council member']
# NOTE: 'american' removed (Phase 156): it wrongly passed founding-father 'John Hancock' for the OH-1 Libertarian.

# new-candidate external_id band + Wikipedia search state name, per state.
# MO band: -290899..-290101 (162-02 generator output, actual range -290805..-290101; excludes
# incumbents -29001..-29008 which fall far outside this band). Election name is NOT used for scoping
# (see module docstring, D-01b).
BANDS = {
    # KS new-candidate band (164-01 generator: actual range -200410..-200103). Upper bound is
    # -200103 (KS-1 seq 3), which excludes the two legacy MA senators at -200101/-200102 (D-04
    # collision). The 9 legacy MA House rows -200201..-200209 fall inside the range but are all
    # already imaged in prior phases, so the NOT EXISTS politician_images filter auto-excludes them.
    # KS incumbents (-20001..-20004) fall far outside this band (already imaged). Same hardened guards.
    'KS': (-200499, -200103, 'Kansas'),
}

def wiki_get(params):
    p = {'format': 'json', 'redirects': '1', **params}
    r = requests.get(WIKI_API, params=p, headers={'User-Agent': UA}, timeout=30)
    r.raise_for_status()
    return r.json()

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

def _search_title(full_name, state_name):
    """Use search to find the correct politician page when the bare title is ambiguous."""
    q = f'{full_name} {state_name} Congress candidate'
    data = wiki_get({'action': 'query', 'list': 'search', 'srsearch': q, 'srlimit': '1'})
    hits = data.get('query', {}).get('search', [])
    return hits[0]['title'] if hits else None

import re as _re
_NON_PERSON_TITLE = _re.compile(
    r'(election|congressional district|gubernatorial|ballot|primary|\bcity\b|, kansas|'
    r'county|\b\d{4}\b|referendum|proposition|special election)', _re.IGNORECASE)

_BAD_DISAMBIG = _re.compile(
    r'\((racing|driver|musician|singer|actor|actress|footballer|baseball|basketball|boxer|'
    r'athlete|band|album|song|film|tv series|novel|company|wrestler|artist|painter|author|'
    r'comedian|rapper|dj|producer|director|cricketer|rugby|hockey|soccer|tennis|golfer)',
    _re.IGNORECASE)

_HISTORICAL_YEAR = _re.compile(r'(1[0-9]\d{2})')
def _desc_is_historical(desc):
    """True if the short description names a pre-1940 year (dead historical homonym, e.g. John Hancock 1737-1793)."""
    if not desc:
        return False
    for y in _HISTORICAL_YEAR.findall(desc):
        if int(y) < 1940:
            return True
    return False

def _title_is_candidate_person(full_name, title):
    """True only if the resolved page title plausibly IS this candidate's biographical page."""
    if not title:
        return False
    if _NON_PERSON_TITLE.search(title):
        return False
    if _BAD_DISAMBIG.search(title):
        return False
    base = _re.sub(r'\s*\([^)]*\)\s*', ' ', title).strip().lower()
    parts = [p for p in _re.sub(r'[^\w\s]', ' ', full_name).split() if len(p) > 1]
    if not parts:
        return False
    first = parts[0].lower(); surname = parts[-1].lower()
    return first in base and surname in base

def resolve_portrait(full_name, state_name, role=''):
    """Return (image_url_candidates, license_str, page_title) or (None, reason, None)."""
    page, desc = _try_title(full_name)
    political = page is not None and desc != 'disambig' and (
        not desc or any(k in desc for k in POLITICAL_KW) or state_name.lower() in desc)
    if not political:
        st = _search_title(full_name, state_name)
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
    if _desc_is_historical(desc):
        return None, f'historical-homonym-desc:"{(desc or "")[:50]}"', title
    if not _title_is_candidate_person(full_name, title):
        return None, f'not-candidate-person-page:"{title[:50]}"', title
    img_url = page.get('original', {}).get('source')
    thumb = page.get('thumbnail', {}).get('source')
    if not img_url and not thumb:
        return None, 'no-lead-image', title
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
    cands = [u for u in (img_url, thumb) if u]
    return cands, photo_license, title

def crop_to_4_5(img):
    w, h = img.size
    target = 4/5
    if w/h > target:
        nw = int(h*target); left = (w-nw)//2
        return img.crop((left, 0, left+nw, h))
    else:
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

RESULTS_JSON = os.path.join(os.path.dirname(__file__), '_ks-house-headshot-results.json')

def _merge_results(results):
    prior = []
    if os.path.exists(RESULTS_JSON):
        try: prior = json.load(open(RESULTS_JSON))
        except Exception: prior = []
    by_ext = {r['external_id']: r for r in prior}
    for r in results: by_ext[r['external_id']] = r
    json.dump(list(by_ext.values()), open(RESULTS_JSON, 'w'), indent=1)

def run_manual(manual_path):
    conn = psycopg2.connect(DATABASE_URL); conn.autocommit = False
    cur = conn.cursor()
    results = []
    for line in open(manual_path, encoding='utf-8'):
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
    _merge_results(results)
    ok = sum(1 for r in results if r.get('success'))
    print(f'\n=== MANUAL DONE: {ok}/{len(results)} uploaded ===')
    cur.close(); conn.close()

def main():
    dry = False; manual = None; state = None
    args = sys.argv[1:]
    for i, a in enumerate(args):
        if a == '--dry-run': dry = True
        elif a == '--manual': manual = args[i+1] if i+1 < len(args) else None
        elif a.startswith('--manual='): manual = a.split('=', 1)[1]
        elif a == '--state': state = args[i+1] if i+1 < len(args) else None
        elif a.startswith('--state='): state = a.split('=', 1)[1]
    if manual:
        return run_manual(manual)
    if state not in BANDS:
        print('ERROR: --state MO required (or --manual <file>)'); sys.exit(1)
    lo, hi, sname = BANDS[state]

    conn = psycopg2.connect(DATABASE_URL); conn.autocommit = False
    cur = conn.cursor()
    # New MO 2026 House candidates: scoped by external_id BAND ONLY (no election-name join). Unlike
    # OH/GA/NC/MI (single election per state), MO has TWO elections (general + withheld "Polygon
    # Pending" for the 5 severe/redistricted districts per 162-02 D-01b) -- severe-district candidates
    # STILL need headshots even though their race doesn't currently surface on /elections. The band
    # filter still excludes reused incumbents (their external_ids like -29001 fall OUTSIDE -290101..-290899).
    cur.execute("""
        SELECT DISTINCT p.id, p.external_id, p.full_name
        FROM essentials.politicians p
        JOIN essentials.race_candidates rc ON rc.politician_id = p.id AND rc.candidate_status = 'active'
        WHERE p.external_id BETWEEN %s AND %s
          AND p.is_active = true
          AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id)
        ORDER BY p.external_id;
    """, (lo, hi))
    rows = cur.fetchall()
    targets = [(r[0], r[1], r[2]) for r in rows]
    print(f'{state} House candidates needing headshot: {len(targets)}')
    results = []
    for uuid, ext, name in targets:
        res = {'external_id': ext, 'full_name': name, 'state': state, 'uuid': str(uuid)}
        try:
            cands, lic_or_reason, title = resolve_portrait(name, sname)
            if not cands:
                res.update(success=False, skip_reason=lic_or_reason); print(f'  SKIP {name} ({state}): {lic_or_reason}')
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
                res.update(success=False, skip_reason=last_err or 'no-usable-image'); print(f'  SKIP {name} ({state}): {last_err}')
                results.append(res); time.sleep(0.3); continue
            img_url = used
            img = crop_to_4_5(img).resize(TARGET_SIZE, Image.Resampling.LANCZOS)
            buf = io.BytesIO(); img.save(buf, format='JPEG', quality=JPEG_QUALITY, optimize=True)
            if dry:
                res.update(success=True, license=lic_or_reason, source=img_url, cdn=None, dry=True); print(f'  OK(dry) {name} ({state}) lic={lic_or_reason} <- {title}')
                results.append(res); time.sleep(0.3); continue
            cdn = upload(str(uuid), buf.getvalue())
            cur.execute("""INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
                           SELECT gen_random_uuid(), %s::uuid, %s, 'default', %s
                           WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id=%s::uuid)""",
                        (str(uuid), cdn, lic_or_reason, str(uuid)))
            conn.commit()
            res.update(success=True, license=lic_or_reason, source=img_url, cdn=cdn); print(f'  OK {name} ({state}) lic={lic_or_reason} <- {title}')
        except Exception as e:
            conn.rollback()
            res.update(success=False, skip_reason=f'error:{str(e)[:80]}'); print(f'  ERR {name} ({state}): {e}')
        results.append(res); time.sleep(0.3)

    ok = sum(1 for r in results if r.get('success'))
    sk = len(results) - ok
    print(f'\n=== DONE {state}-House: {ok} uploaded, {sk} honest-skip of {len(results)} ===')
    for r in results:
        if not r.get('success'): print(f'  skip: {r["external_id"]} {r["full_name"]} -> {r["skip_reason"]}')
    _merge_results(results)
    cur.close(); conn.close()

if __name__ == '__main__':
    main()
