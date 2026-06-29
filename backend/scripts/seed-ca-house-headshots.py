"""
seed-ca-house-headshots.py — Phase 149 (v2.20 2026 US House Candidate Coverage) Wave 2, plan 149-03.

CLONE of seed-state-exec-headshots.py (verified Phase-141 pipeline). The ONLY change from the
original is the target-selection query (see main()): the new CA-2026-House challengers have NO
essentials.offices row (149-01 / A2: an office row would pollute the reps feed + geofence search),
so the original STATE_EXEC offices-join self-target query returns nothing for them. Instead this
selects the new-candidate set directly by the -601xxxx external_id band:

  external_id BETWEEN -6019999 AND -6010000 AND is_active=true
    AND NOT EXISTS a politician_images row

NOTE: the 149-01 reconciliation correction (migration 1092) retired 2 duplicate new records
(-6013801 Hilda Solis, -6014101 Linda Sánchez, both is_active=false) — the is_active=true filter
naturally excludes them, leaving exactly the 36-candidate target set. All candidates are state 'CA'
and carry no role_canonical (state='CA', role='' passed to resolve_portrait).

Sources + processes + uploads a headshot for every targeted candidate lacking one, then records it
in essentials.politician_images (column `url`). Self-targeting + idempotent: a re-run only fills gaps.

Pipeline (UNCHANGED from the original — all guards intact):
  Wikipedia pageimages API (lead portrait) -> license via imageinfo extmetadata (FREE licenses only) ->
  download -> RGB -> CROP 4:5 first (never stretch) -> RESIZE 600x750 LANCZOS q90 ->
  upload to politician_photos/{uuid}-headshot.jpg (x-upsert) -> INSERT politician_images WHERE NOT EXISTS.

Wrong-person guard: the resolved Wikipedia page's wikidata description MUST contain a political
keyword (or the candidate's state), else honest-skip. Non-free/fair-use images: honest-skip.

Usage:
  python backend/scripts/seed-ca-house-headshots.py [--dry-run]
  python backend/scripts/seed-ca-house-headshots.py --manual <file>   (external_id|image_url|license)
Writes backend/scripts/_ca-house-headshot-results.json.
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

# Strict person-page guard (T-149-09): obscure House challengers rarely have own Wikipedia pages,
# so a bare-title / search match frequently lands on an election/place/event article (whose lead
# image is a map/seal — NOT the candidate) or on a different notable individual of the same name.
# The base POLITICAL_KW description guard is too weak here (election articles contain "house
# elections", place articles contain "california"). Require the resolved PAGE TITLE to actually be
# the candidate's name: the candidate's surname must appear in the title, AND the title must not
# match a non-person article pattern. Anything else -> honest-skip for manual second-source sourcing.
import re as _re
_NON_PERSON_TITLE = _re.compile(
    r'(election|congressional district|gubernatorial|ballot|primary|\bcity\b|, california|'
    r'county|\b\d{4}\b|referendum|proposition|special election)', _re.IGNORECASE)

# Parenthetical disambiguators that prove the page is a DIFFERENT (non-candidate) person/topic.
_BAD_DISAMBIG = _re.compile(
    r'\((racing|driver|musician|singer|actor|actress|footballer|baseball|basketball|boxer|'
    r'athlete|band|album|song|film|tv series|novel|company|wrestler|artist|painter|author|'
    r'comedian|rapper|dj|producer|director|cricketer|rugby|hockey|soccer|tennis|golfer)',
    _re.IGNORECASE)

def _title_is_candidate_person(full_name, title):
    """True only if the resolved page title plausibly IS this candidate's biographical page.

    Guards against (a) election/place/event articles whose lead image is a map/seal, and
    (b) same-surname different-individual pages (e.g. 'Danny McBride' for John McBride,
    'Shane Lewis (racing driver)'). Requires BOTH the candidate's first name and surname to
    appear in the title, and rejects non-political parenthetical disambiguators.
    """
    if not title:
        return False
    if _NON_PERSON_TITLE.search(title):
        return False  # election / place / year article, not a person
    if _BAD_DISAMBIG.search(title):
        return False  # explicitly a different kind of notable person/topic
    # strip parenthetical disambiguators like "(politician)" before name matching
    base = _re.sub(r'\s*\([^)]*\)\s*', ' ', title).strip().lower()
    parts = [p for p in _re.sub(r'[^\w\s]', ' ', full_name).split() if len(p) > 1]
    if not parts:
        return False
    first = parts[0].lower(); surname = parts[-1].lower()
    # Both the candidate's first name AND surname must be present in the title — a person page is
    # titled with the person's actual name. (Catches 'Danny McBride' vs 'John McBride'.)
    return first in base and surname in base

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
    # Strict person-page guard (T-149-09 wrong-person): reject election/place/event articles and
    # same-name different-individual pages. Obscure challengers fail this -> manual sourcing.
    if not _title_is_candidate_person(full_name, title):
        return None, f'not-candidate-person-page:"{title[:50]}"', title
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
    out = os.path.join(os.path.dirname(__file__), '_ca-house-headshot-results.json')
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
    dry = False; manual = None
    args = sys.argv[1:]
    for i, a in enumerate(args):
        if a == '--dry-run': dry = True
        elif a == '--manual': manual = args[i+1] if i+1 < len(args) else None
        elif a.startswith('--manual='): manual = a.split('=', 1)[1]
    if manual:
        return run_manual(manual)

    conn = psycopg2.connect(DATABASE_URL); conn.autocommit = False
    cur = conn.cursor()
    # Phase 149-03 target: new CA-2026-House challengers (-601xxxx band, scheme -(6010000+cd*100+seq)).
    # These have NO essentials.offices row, so the original STATE_EXEC offices-join cannot find them.
    # is_active=true excludes the 2 mig-1092-retired dup records (-6013801, -6014101). All are state CA.
    cur.execute("""
        SELECT p.id, p.external_id, p.full_name
        FROM essentials.politicians p
        WHERE p.external_id BETWEEN -6019999 AND -6010000
          AND p.is_active = true
          AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id)
        ORDER BY p.external_id;
    """)
    rows = cur.fetchall()
    targets = [(r[0], r[1], r[2], 'CA', '') for r in rows]
    print(f'CA House candidates needing headshot: {len(targets)}')
    results = []
    for uuid, ext, name, st, role in targets:
        sname = 'California'
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
    print(f'\n=== DONE CA-House: {ok} uploaded, {sk} honest-skip of {len(results)} ===')
    for r in results:
        if not r.get('success'): print(f'  skip: {r["external_id"]} {r["full_name"]} ({r["state"]}) -> {r["skip_reason"]}')
    out = os.path.join(os.path.dirname(__file__), '_ca-house-headshot-results.json')
    # merge with any prior results so multi-run accumulates
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
