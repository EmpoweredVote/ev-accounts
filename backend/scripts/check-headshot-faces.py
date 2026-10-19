#!/usr/bin/env python
"""check-headshot-faces.py - does every published headshot actually contain a face?

No other gate asks this. Dimensions, aspect ratio, colour, licence, corner-agreement and the
photo_custom_url/politician_images pairing were all GREEN on an office seal, an election-results
map, a blank white frame, a headless torso and a portrait stored on its side.

  python backend/scripts/check-headshot-faces.py                # sweep our CDN, active rows
  python backend/scripts/check-headshot-faces.py --limit 200    # quick pass
  python backend/scripts/check-headshot-faces.py --json out.json

Exit 0 = nothing flagged. Exit 1 = flagged rows (printed). Exit 2 = the check could not run.

READ THE FLAGGED LIST WITH YOUR EYES. This is a triage net, not a verdict: on the first full
sweep 42 of 7,779 were flagged and only 9 were real. Profiles, hats, heavy shadow and faces
filling the whole frame all miss. A lone ROTATED_180 is the weakest call of all - the upright
score sits just under the bar - so confirm it by looking before acting on it.

It cannot see the WRONG PERSON's face, which is the dominant failure mode in headshot work.
"""
from __future__ import annotations

import argparse
import concurrent.futures as cf
import io
import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), 'lib'))
from headshot_image import open_portrait, face_report, PortraitRejected  # noqa: E402

FACE_BAR = 0.80

SQL = """
SELECT p.id, p.full_name,
       NULLIF(COALESCE(p.photo_custom_url, p.photo_origin_url), '') AS url
FROM essentials.politicians p
WHERE p.is_active = true
  AND NULLIF(COALESCE(p.photo_custom_url, p.photo_origin_url), '') LIKE %s
ORDER BY p.id
"""

# 🔴 OUR OWN STORAGE ANSWERS TO TWO HOSTNAMES: <ref>.storage.supabase.co AND <ref>.supabase.co.
# Matching only the first called 1,279 of OUR OWN files "hotlinked to an outside host" and left
# them out of the first corpus sweep entirely. Match the storage PATH, which both hostnames share.
OURS = '%supabase.co/storage/v1/object/public/%'


def load_env():
    """DATABASE_URL from the process, else backend/.env, else the MAIN checkout's .env.

    Linked worktrees carry no .env, and most work here happens in one, so fall back the same
    way scripts/lib/main-checkout-fallback.mjs does for node.
    """
    if os.environ.get('DATABASE_URL'):
        return {'DATABASE_URL': os.environ['DATABASE_URL']}
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
        if env.get('DATABASE_URL'):
            return env
    raise SystemExit('no DATABASE_URL: set it in the environment or in backend/.env')


def classify(rep):
    confs, best = rep['confs'], rep['best']
    if confs[best] < FACE_BAR:
        return 'NO_FACE'
    if confs[0] >= FACE_BAR or best == 0:
        return 'OK'
    return f'ROTATED_{best}'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--limit', type=int, default=0, help='check only the first N rows')
    ap.add_argument('--all-hosts', action='store_true',
                    help='include images on outside hosts too (slower, and a fetch failure is not a defect)')
    ap.add_argument('--external-only', action='store_true',
                    help='ONLY images not on our own storage - the genuinely hotlinked ones')
    ap.add_argument('--json', dest='json_out', help='write the full per-row result here')
    ap.add_argument('--workers', type=int, default=8)
    ap.add_argument('--only', nargs='+', metavar='UUID',
                    help='check just these politician ids - re-checking a repaired row, or proving '
                         'the detector can still fail by pointing it at a known-bad one')
    args = ap.parse_args()

    try:
        import requests
        import psycopg2
    except ImportError as e:
        print(f'cannot run: {e}. pip install -r backend/scripts/requirements.txt', file=sys.stderr)
        return 2

    env = load_env()
    with psycopg2.connect(env['DATABASE_URL']) as conn, conn.cursor() as cur:
        if args.only:
            cur.execute(SQL.replace('ORDER BY p.id', 'AND p.id = ANY(%s::uuid[]) ORDER BY p.id'),
                        ('%', args.only))
        elif args.external_only:
            cur.execute(SQL.replace('LIKE %s', 'NOT LIKE %s'), (OURS,))
        else:
            cur.execute(SQL, ('%' if args.all_hosts else OURS,))
        rows = cur.fetchall()
    if args.limit:
        rows = rows[:args.limit]
    print(f'checking {len(rows)} headshots...', flush=True)

    session = requests.Session()
    session.headers['User-Agent'] = 'EmpoweredVote-civic-data/1.0 (contact chris@empowered.vote)'

    def check(row):
        pid, name, url = row
        rec = {'id': str(pid), 'name': name, 'url': url}
        try:
            r = session.get(url, timeout=45)
            r.raise_for_status()
            img = open_portrait(r.content)
            rep = face_report(img)
            rec.update(verdict=classify(rep), confs=rep['confs'], eye_angle=rep['eye_angle'],
                       dims=list(img.size))
        except PortraitRejected as e:
            rec.update(verdict='CHECK_FAILED', error=str(e)[:120])
        except Exception as e:
            rec.update(verdict='UNREACHABLE', error=f'{type(e).__name__}: {str(e)[:100]}')
        return rec

    with cf.ThreadPoolExecutor(max_workers=args.workers) as ex:
        results = list(ex.map(check, rows))

    if args.json_out:
        with open(args.json_out, 'w', encoding='utf-8') as f:
            json.dump(results, f, ensure_ascii=False, indent=1)

    flagged = [r for r in results if r['verdict'] not in ('OK', 'UNREACHABLE')]
    unreachable = [r for r in results if r['verdict'] == 'UNREACHABLE']

    # A sweep that flags nothing is the shape a BROKEN detector also has, so say which it was.
    if not results:
        print('no rows matched - nothing was checked', file=sys.stderr)
        return 2
    ok = sum(1 for r in results if r['verdict'] == 'OK')
    print(f'\nchecked {len(results)}  ok {ok}  flagged {len(flagged)}  unreachable {len(unreachable)}')
    if unreachable:
        print(f'  ({len(unreachable)} could not be fetched; that is a broken link, not a face defect)')
    # Sort by best score, weakest first. Measured over 9,058 rows: a frame that is genuinely not
    # a photograph of a person (a seal, an election map, a campaign yard sign, a blank) tends to
    # score 0.00 at EVERY rotation, while a real face the detector merely missed scores 0.68-0.78.
    # So the top of this list is where the real defects cluster. It is a sort order, NOT a verdict
    # -- one office seal did reach 0.62 -- so read the whole list either way.
    def best_conf(r):
        return max((r.get('confs') or {'_': 0}).values())

    for r in sorted(flagged, key=lambda r: (best_conf(r), r['name'])):
        print(f"  {r['verdict']:14s} best={best_conf(r):.2f}  {r['name'][:38]:38s} "
              f"{r.get('dims', '')} {r['url'][:66]}")
    if flagged:
        print('\nLOOK AT THESE BEFORE ACTING. Most flags are real portraits the detector missed;')
        print('the ones scoring 0.00 everywhere are where the genuine non-portraits sit.')
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
