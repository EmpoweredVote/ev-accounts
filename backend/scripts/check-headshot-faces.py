#!/usr/bin/env python
"""check-headshot-faces.py - does every published headshot actually contain a face?

No other gate asks this. Dimensions, aspect ratio, colour, licence, corner-agreement and the
photo_custom_url/politician_images pairing were all GREEN on an office seal, an election-results
map, a blank white frame, a headless torso and a portrait stored on its side.

  python backend/scripts/check-headshot-faces.py                # sweep our CDN, active rows
  python backend/scripts/check-headshot-faces.py --limit 200    # quick pass
  python backend/scripts/check-headshot-faces.py --json out.json
  python backend/scripts/check-headshot-faces.py --no-ballot    # profile column only (the pre-CC_0259 net)

  npm run check:headshot-faces           --prefix backend   # what CI runs weekly (full corpus)
  npm run check:headshot-faces:external  --prefix backend   # what CI runs nightly (off-site links)
  npm run check:headshot-faces:accept    --prefix backend   # record the flags you have just LOOKED at

Exit 0 = nothing NEW flagged. Exit 1 = a flag that is not in the accepted-flags baseline, or
(with --fail-on-unreachable) a URL that will not fetch. Exit 2 = the check could not run.

🔴 A FLAG IS ONLY "ACCEPTED" WHILE THE BYTES ARE THE ONES SOMEBODY LOOKED AT. The baseline is
keyed on (url, sha256), so an x-upsert overwrite at the same path lapses the acceptance and
the new picture is judged from scratch. Do not run --write-accepted to turn a red run green;
run it after reading every flag.

🔴 THERE ARE TWO PLACES A HEADSHOT IS PUBLISHED FROM, AND THIS SWEEPS BOTH (since CC_0259).

  profile  COALESCE(politicians.photo_custom_url, photo_origin_url)  - profile page + browse grid
  ballot   race_candidates.photo_url                                 - election and ballot pages

They are DIFFERENT COLUMNS and the ballot one WINS where it is set: electionService.ts selects
COALESCE(rc.photo_url, pi.url), so it outranks BOTH the scalar and the politician_images row.
Until CC_0259 this script read only the profile column, and the gap was not theoretical - five
people whose headshots had already been "fixed" were still serving the original defect on every
ballot page: two campaign yard signs, and a five-person family photograph that PASSES this very
check, because a group photo has faces in it. Measured 2026-10-19, the ballot column brought in
images the gate had NEVER seen: +31 in the default scope (9,159 -> 9,190 distinct) and +39 with
--all-hosts (9,160 -> 9,199). Eleven of those ballot rows carry NO politician_id at all, so no
politician-rooted query could ever have reached them.
▶ So a flagged row now names its SITE. Fix the column it names - fixing the other one leaves
  the defect rendering.

READ THE FLAGGED LIST WITH YOUR EYES. This is a triage net, not a verdict: on the first full
sweep 42 of 7,779 were flagged and only 9 were real. Profiles, hats, heavy shadow and faces
filling the whole frame all miss. A lone ROTATED_180 is the weakest call of all - the upright
score sits just under the bar - so confirm it by looking before acting on it.

It cannot see the WRONG PERSON's face, nor a GROUP PHOTO, which are the dominant failure modes
in headshot work. Counting faces catches the crowd; nothing automated catches the impostor.
"""
from __future__ import annotations

import argparse
import concurrent.futures as cf
import hashlib
import io
import json
import os
import sys
import time

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

# The ballot column. Keyed on the POLITICIAN where there is one, so --only and the flagged
# output line up with the profile sweep; a candidate row with no politician_id falls back to
# its own id, because it still publishes an image.
#
# `result IS DISTINCT FROM 'not_nominated'` mirrors BALLOT_CANDIDATE_JOIN in
# backend/src/lib/electionService.ts: a primary loser is not on this race's ballot, so its
# photograph does not render and is not this gate's business. That is the BROADER of the two
# render paths - getCandidateById also drops 'withdrawn' - so sweeping to this rule covers
# both. ⚠ If that join condition changes, change this with it, or the gate silently stops
# matching what is published.
SQL_BALLOT = """
SELECT COALESCE(rc.politician_id, rc.id) AS id, rc.full_name,
       NULLIF(rc.photo_url, '') AS url
FROM essentials.race_candidates rc
WHERE NULLIF(rc.photo_url, '') IS NOT NULL
  AND rc.result IS DISTINCT FROM 'not_nominated'
  AND NULLIF(rc.photo_url, '') LIKE %s
ORDER BY 1
"""

# The accepted-flags file, same convention as cal-access-attribution-baseline.json.
#
# 🔴 KEYED ON (URL, SHA256 OF THE BYTES), AND THE HASH IS THE LOAD-BEARING HALF. Keying on the
# URL alone was the first attempt and it was WRONG: the claim "replacing an image changes its
# ?v= cache key, so the acceptance expires by itself" is false for every row it has to cover -
# NONE of the 16 accepted URLs carries a ?v= key, they are plain <uuid>-headshot.jpg paths that
# an x-upsert overwrites IN PLACE. A URL-keyed acceptance would have gone on muting that path
# after someone uploaded a completely different picture to it.
# With the hash, ANY change to the bytes lapses the acceptance and the frame is judged again.
# ⚠ It records "a human looked at this and it is a real face the detector missed". It is not a
# mute button, and `--write-accepted` must not be run to make a red build green.
ACCEPTED_PATH = os.path.normpath(
    os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data',
                 'headshot-accepted-flags.json'))

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


def load_accepted(path):
    """(url, sha256) -> entry, for flags a human has already looked at.

    Missing file = accept nothing, which is the safe direction: a lost baseline makes the
    check LOUD, never silently permissive.
    """
    if not path or not os.path.exists(path):
        return set()
    with open(path, encoding='utf-8') as f:
        doc = json.load(f)
    return {(e['url'], e.get('sha256')) for e in doc.get('accepted', [])}


def write_accepted(path, flagged, best_conf):
    """Record the current flags as looked-at, with the hash of the exact bytes judged.

    Stores the verdict, score and dimensions too, so a later reader can see WHAT was accepted
    rather than only that something was.
    """
    doc = {
        '_comment': 'Flags a human has looked at and judged real faces the detector missed. '
                    'Keyed on (url, sha256): the hash is what makes an acceptance expire by '
                    'itself, because these paths are overwritten IN PLACE by x-upsert and the '
                    'URL alone would go on muting a path after the picture behind it changed. '
                    'Written by check-headshot-faces.py --write-accepted, and only after '
                    'looking at every flag. It is not a mute button.',
        'accepted': [
            {'url': r['url'], 'sha256': r.get('sha256'), 'name': r['name'],
             'verdict': r['verdict'], 'best': round(best_conf(r), 3), 'dims': r.get('dims')}
            for r in sorted(flagged, key=lambda r: (best_conf(r), r['name']))
        ],
    }
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(doc, f, ensure_ascii=False, indent=1)
        f.write('\n')


def collect(cur, args):
    """Every published image, from both columns, DE-DUPLICATED BY URL.

    The same file is usually in both columns, and fetching it twice would double the sweep
    for no new information. So a URL is checked once and carries the list of SITES that
    publish it - which is what tells you where to apply a fix.
    """
    # Branch exactly as the single-query version did, rather than combining the flags: with
    # --external-only AND --all-hosts, a combined form resolves to NOT LIKE '%' and silently
    # matches nothing. Precedence is --only, then --external-only, then --all-hosts.
    if args.only:
        host, op = '%', 'LIKE %s'
    elif args.external_only:
        host, op = OURS, 'NOT LIKE %s'
    else:
        host, op = ('%' if args.all_hosts else OURS), 'LIKE %s'

    plans = []
    profile_sql = SQL.replace('LIKE %s', op)
    if args.only:
        profile_sql = profile_sql.replace('ORDER BY p.id', 'AND p.id = ANY(%s::uuid[]) ORDER BY p.id')
        plans.append(('profile', profile_sql, (host, args.only)))
    else:
        plans.append(('profile', profile_sql, (host,)))

    if not args.no_ballot:
        ballot_sql = SQL_BALLOT.replace('LIKE %s', op)
        if args.only:
            ballot_sql = ballot_sql.replace('ORDER BY 1', 'AND rc.politician_id = ANY(%s::uuid[]) ORDER BY 1')
            plans.append(('ballot', ballot_sql, (host, args.only)))
        else:
            plans.append(('ballot', ballot_sql, (host,)))

    merged: dict[str, dict] = {}
    counts = {}
    for site, sql, params in plans:
        cur.execute(sql, params)
        rows = cur.fetchall()
        counts[site] = len(rows)
        for pid, name, url in rows:
            rec = merged.get(url)
            if rec is None:
                merged[url] = {'id': str(pid), 'name': name, 'url': url, 'sites': [site]}
            elif site not in rec['sites']:
                rec['sites'].append(site)
    return list(merged.values()), counts


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
    ap.add_argument('--no-ballot', action='store_true',
                    help='skip race_candidates.photo_url - the profile-only net this script used '
                         'before CC_0259. For comparing the two scopes, not for routine use.')
    ap.add_argument('--accepted', default=str(ACCEPTED_PATH), metavar='FILE',
                    help='accepted-flags file: flags listed there do not fail the run (CI mode). '
                         'Pass an empty string to ignore it and see every flag.')
    ap.add_argument('--write-accepted', action='store_true',
                    help='rewrite the accepted-flags file from THIS run. Only after looking at '
                         'every flag: it is an "I have seen these" record, not a mute button.')
    ap.add_argument('--fail-on-unreachable', action='store_true',
                    help='treat a URL that will not fetch as a failure. A dead link is a broken '
                         'image on a page even though it is not a face defect (CC_0260).')
    args = ap.parse_args()

    try:
        import requests
        import psycopg2
    except ImportError as e:
        print(f'cannot run: {e}. pip install -r backend/scripts/requirements.txt', file=sys.stderr)
        return 2

    env = load_env()
    with psycopg2.connect(env['DATABASE_URL']) as conn, conn.cursor() as cur:
        rows, counts = collect(cur, args)
    if args.limit:
        rows = rows[:args.limit]
    scope = '  '.join(f'{k} {v}' for k, v in counts.items())
    print(f'checking {len(rows)} distinct images  ({scope} rows before de-duplication)', flush=True)
    if args.no_ballot:
        # ASCII only: this prints to a cp1252 console on Windows and a non-ASCII glyph here
        # raised UnicodeEncodeError and killed the run.
        print('  WARNING --no-ballot: race_candidates.photo_url is NOT being checked, and it '
              'OUTRANKS the profile column on every ballot page.')

    session = requests.Session()
    session.headers['User-Agent'] = 'EmpoweredVote-civic-data/1.0 (contact chris@empowered.vote)'

    def check(row):
        rec = dict(row)
        url = rec['url']
        # ONE retry on a fetch failure, because UNREACHABLE can fail a scheduled run and a
        # single blip across ~9,200 requests would redden a nightly that is otherwise green.
        # Only the FETCH is retried: a decode failure is deterministic and retrying it just
        # doubles the work.
        last = None
        for attempt in (1, 2):
            try:
                r = session.get(url, timeout=45)
                r.raise_for_status()
                break
            except Exception as e:                       # noqa: BLE001 - reported, not swallowed
                last = e
                r = None
                if attempt == 1:
                    time.sleep(1.5)
        if r is None:
            rec.update(verdict='UNREACHABLE', error=f'{type(last).__name__}: {str(last)[:100]}')
            return rec
        rec['sha256'] = hashlib.sha256(r.content).hexdigest()
        try:
            img = open_portrait(r.content)
            rep = face_report(img, short_circuit_at=FACE_BAR)
            rec.update(verdict=classify(rep), confs=rep['confs'], eye_angle=rep['eye_angle'],
                       dims=list(img.size))
        except PortraitRejected as e:
            rec.update(verdict='CHECK_FAILED', error=str(e)[:120])
        except Exception as e:
            rec.update(verdict='UNDECODABLE', error=f'{type(e).__name__}: {str(e)[:100]}')
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

    accepted = load_accepted(args.accepted)
    fresh = [r for r in flagged if (r['url'], r.get('sha256')) not in accepted]
    known = len(flagged) - len(fresh)

    for r in sorted(flagged, key=lambda r: (best_conf(r), r['name'])):
        sites = '+'.join(r.get('sites') or ['?'])
        mark = '      ' if (r['url'], r.get('sha256')) in accepted else ' NEW  '
        print(f" {mark}{r['verdict']:13s} best={best_conf(r):.2f}  {r['name'][:34]:34s} "
              f"[{sites:14s}] {r.get('dims', '')} {r['url'][:58]}")
    if known:
        try:
            where = os.path.relpath(args.accepted)
        except ValueError:              # different drive on Windows - the full path still reads
            where = args.accepted
        print(f'\n  {known} of those are in {where} - already looked at '
              'and judged real faces the detector missed.')

    if args.write_accepted:
        write_accepted(args.accepted, flagged, best_conf)
        print(f'wrote {len(flagged)} accepted flags to {args.accepted}')
        return 0

    # Report BOTH failure kinds before returning. Returning on the first one hid the dead-link
    # list behind any new face flag, which is the one run where you most want to see both.
    failed = False
    if fresh:
        print(f'\n{len(fresh)} NEW flag(s). LOOK AT THESE BEFORE ACTING. Most flags are real')
        print('portraits the detector missed; the ones scoring 0.00 everywhere are where the')
        print('genuine non-portraits sit. The [site] column says WHICH COLUMN PUBLISHES IT -')
        print('"ballot" means race_candidates.photo_url, which outranks the profile column on')
        print('election pages. Once judged, record them with --write-accepted.')
        failed = True
    if unreachable and args.fail_on_unreachable:
        print(f'\n{len(unreachable)} image(s) would not fetch after a retry. A dead link is a')
        print('broken image on a page, not a face defect - but it is still broken (CC_0260).')
        for r in unreachable[:20]:
            print(f"  UNREACHABLE  {r['name'][:34]:34s} {r.get('error', '')[:46]}  {r['url'][:54]}")
        failed = True
    return 1 if failed else 0


if __name__ == '__main__':
    raise SystemExit(main())
