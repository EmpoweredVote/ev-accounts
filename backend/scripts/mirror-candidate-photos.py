#!/usr/bin/env python
"""mirror-candidate-photos.py - copy hotlinked ballot photographs into our own bucket.

essentials.race_candidates.photo_url is the image election and ballot pages render
(electionService selects COALESCE(rc.photo_url, pi.url), so it OUTRANKS the profile column).
An importer that writes the URL it scraped straight into that column leaves us serving
somebody else's file from somebody else's host.

🔴 A HOTLINK IS NOT A PHOTOGRAPH WE HAVE. IT IS A PROMISE SOMEONE ELSE CAN WITHDRAW.
CC_0260 blanked three published photographs that had gone 404, 401 and 403. Every one was a
live, correct image when it was imported; no migration broke them, the web did. All three were
off-site. That is the whole argument for this script.

  python backend/scripts/mirror-candidate-photos.py                 # dry run, every off-site row
  python backend/scripts/mirror-candidate-photos.py --state CA      # one state
  python backend/scripts/mirror-candidate-photos.py --state CA --apply

Dry run by default. --apply uploads and then RE-FETCHES AND HASHES what the CDN serves, because
an upload returning 200 is not evidence the public URL changed (CC_0253).

It prints the SQL values for a migration and does NOT write the database itself: a photo that
appears on a ballot page is reviewed prose in this repo, and the migration is where the
reviewer sees which file was chosen and why.

🔴 IT REFUSES A FRAME WITH NO FACE IN IT. upload-ut-candidate-photos.ts, the script this
generalises, uploaded raw bytes with no such check - which is exactly how three campaign YARD
SIGNS reached ut/candidates/ and had to be replaced by CC_0255. A mirror of a graphic is a
tidier graphic.
⚠ AND IT STILL CANNOT SEE THE WRONG PERSON, or a group photo with one face cropped out of it.
LOOK AT WHAT YOU MIRROR.

⚠ NATIVE RESOLUTION, NOT THE 600x750 HOUSE CROP, AND THAT IS DELIBERATE. The 123 files already
in this column are raw source bytes at their own size (456x336 to 6016x4016, and one AVIF
served as .jpg). Cropping here would introduce an UPSCALE on a small source - three of the six
CA rows are 200x300 Ballotpedia thumbnails that would become 3.00x enlargements - to fix a
problem that is about WHO HOSTS THE FILE, not about how it is framed. Mirroring copies the
bytes, so it can never make an image worse. A small source is reported so it can be re-sourced.
⚠ EXIF IS CHECKED ANYWAY: mirroring raw bytes would preserve a sideways frame, and a browser
honours the orientation tag while a crop pipeline would have fixed it. A rotating frame is
re-encoded upright and said so in the output.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'lib'))
from headshot_image import open_portrait, face_report, PortraitRejected  # noqa: E402

FACE_BAR = 0.80
BUCKET = 'politician_photos'

# Every row the ballot list can render whose photo is NOT in our bucket. The liveness filter
# mirrors BALLOT_CANDIDATE_JOIN in backend/src/lib/electionService.ts -- a primary loser is not
# on this race's ballot, so its photograph does not render and is not worth a storage object.
SQL = """
SELECT rc.id, rc.full_name, rc.photo_url, lower(COALESCE(e.state, 'xx')) AS state
FROM essentials.race_candidates rc
LEFT JOIN essentials.races r ON r.id = rc.race_id
LEFT JOIN essentials.elections e ON e.id = r.election_id
WHERE NULLIF(rc.photo_url, '') IS NOT NULL
  AND rc.result IS DISTINCT FROM 'not_nominated'
  AND rc.photo_url NOT LIKE '%supabase.co/storage/v1/object/public/%'
ORDER BY rc.full_name
"""

# Pillow's name for a format -> the extension and content type we store it under. Getting this
# wrong is already in the bucket: one existing object is AVIF served as .jpg.
EXT = {'JPEG': ('jpg', 'image/jpeg'), 'PNG': ('png', 'image/png'),
       'WEBP': ('webp', 'image/webp'), 'GIF': ('gif', 'image/gif'),
       'AVIF': ('avif', 'image/avif'), 'TIFF': ('tiff', 'image/tiff')}


def load_env():
    """Same fallback as check-headshot-faces.py: process, then backend/.env, then the MAIN
    checkout's .env, because a linked worktree carries none."""
    need = ('DATABASE_URL', 'SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY')
    if all(os.environ.get(k) for k in need):
        return {k: os.environ[k] for k in need}
    here = os.path.dirname(os.path.abspath(__file__))
    candidates = [os.path.join(here, '..', '.env')]
    try:
        import subprocess
        main = subprocess.run(['git', 'rev-parse', '--path-format=absolute', '--git-common-dir'],
                              cwd=here, capture_output=True, text=True, timeout=10).stdout.strip()
        if main:
            candidates.append(os.path.join(os.path.dirname(main), 'backend', '.env'))
    except Exception:
        pass
    for path in candidates:
        if not os.path.exists(path):
            continue
        env = {}
        with open(path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    k, v = line.split('=', 1)
                    env[k.strip()] = v.strip()
        if all(env.get(k) for k in need):
            return env
    raise SystemExit(f'missing one of {need}: set them in the environment or backend/.env')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--state', help='only this election state (USPS, e.g. CA)')
    ap.add_argument('--apply', action='store_true', help='actually upload (default: dry run)')
    ap.add_argument('--timeout', type=int, default=60)
    args = ap.parse_args()

    try:
        import requests
        import psycopg2
    except ImportError as e:
        print(f'cannot run: {e}. pip install -r backend/scripts/requirements.txt', file=sys.stderr)
        return 2

    env = load_env()
    with psycopg2.connect(env['DATABASE_URL']) as conn, conn.cursor() as cur:
        cur.execute(SQL)
        rows = cur.fetchall()
    if args.state:
        rows = [r for r in rows if r[3] == args.state.lower()]
    if not rows:
        print('nothing to mirror: no live ballot row points outside our bucket.')
        return 0

    print(f'{"MIRRORING" if args.apply else "DRY RUN -"} {len(rows)} off-site ballot photo(s)\n')
    session = requests.Session()
    session.headers['User-Agent'] = ('Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                                     'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36')
    base = env['SUPABASE_URL'].rstrip('/')
    cdn = f"{base.replace('.supabase.co', '.storage.supabase.co')}/storage/v1/object/public/{BUCKET}"
    key = env['SUPABASE_SERVICE_ROLE_KEY']

    done, failed, values = 0, 0, []
    for rc_id, name, src, state in rows:
        try:
            r = session.get(src, timeout=args.timeout)
            r.raise_for_status()
            blob = r.content
        except Exception as e:
            print(f'  SKIP  {name[:28]:28s} fetch failed: {type(e).__name__} {str(e)[:60]}')
            failed += 1
            continue

        try:
            img = open_portrait(blob)                      # applies EXIF, composites alpha
            rep = face_report(img, short_circuit_at=FACE_BAR)
        except PortraitRejected as e:
            print(f'  SKIP  {name[:28]:28s} will not decode: {str(e)[:60]}')
            failed += 1
            continue
        if rep['confs'][rep['best']] < FACE_BAR:
            print(f'  REFUSE {name[:27]:27s} NO FACE at any rotation (best '
                  f'{rep["confs"][rep["best"]]:.2f}) - mirroring a graphic just tidies it')
            failed += 1
            continue

        probe = Image_open_format(blob)
        rotates = _rotates(blob)
        if rotates:
            # Re-encode upright: raw bytes would keep the orientation tag and a browser honours it.
            buf = io.BytesIO()
            img.save(buf, format='JPEG', quality=92, optimize=True)
            blob, probe = buf.getvalue(), 'JPEG'
            note = '  (RE-ENCODED UPRIGHT from EXIF)'
        else:
            note = ''
        ext, ctype = EXT.get(probe, ('jpg', 'image/jpeg'))
        obj = f'{state}/candidates/{rc_id}.{ext}'
        url = f'{cdn}/{obj}'
        up = 600.0 / max(1, img.size[0])
        small = f'  <-- SMALL SOURCE {img.size[0]}x{img.size[1]}' if img.size[0] < 400 else ''

        print(f'  {"UPLOAD" if args.apply else "would"}  {name[:28]:28s} {str(img.size):12s} '
              f'face {rep["confs"][rep["best"]]:.2f}  -> {obj}{note}{small}')
        print(f'         src {src[:96]}')
        if not args.apply:
            values.append((rc_id, name, url, src))
            continue

        want = hashlib.sha256(blob).hexdigest()
        try:
            put = session.put(f'{base}/storage/v1/object/{BUCKET}/{obj}', data=blob, timeout=120,
                              headers={'Authorization': f'Bearer {key}', 'apikey': key,
                                       'Content-Type': ctype, 'x-upsert': 'true'})
            put.raise_for_status()
        except Exception as e:
            print(f'         FAIL upload: {type(e).__name__} {str(e)[:80]}')
            failed += 1
            continue
        try:
            got = session.get(url, headers={'Cache-Control': 'no-cache'}, timeout=args.timeout)
            got.raise_for_status()
            served = hashlib.sha256(got.content).hexdigest()
        except Exception as e:
            print(f'         FAIL verify: {type(e).__name__} {str(e)[:80]}')
            failed += 1
            continue
        if served != want:
            print(f'         FAIL served bytes differ ({served[:12]} != {want[:12]})')
            failed += 1
            continue
        print(f'         OK served {len(got.content)}B {got.headers.get("Content-Type")} '
              f'sha {served[:12]} MATCH')
        values.append((rc_id, name, url, src))
        done += 1

    print(f'\n{done} mirrored and byte-verified, {failed} skipped/failed')
    if values:
        print('\n-- for the migration (rc_id, name, new url, source it replaces):')
        for rc_id, name, url, src in values:
            print(f"  ('{rc_id}'::uuid, '{name.replace(chr(39), chr(39) * 2)}',\n"
                  f"   '{url}',\n   '{src}'),")
    return 1 if failed else 0


def Image_open_format(blob):
    from PIL import Image
    with Image.open(io.BytesIO(blob)) as im:
        return im.format


def _rotates(blob):
    """True when the file carries an EXIF orientation that actually turns the image."""
    from PIL import Image
    try:
        with Image.open(io.BytesIO(blob)) as im:
            return (im.getexif() or {}).get(274, 1) not in (None, 1)
    except Exception:
        return False


if __name__ == '__main__':
    raise SystemExit(main())
