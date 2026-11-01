#!/usr/bin/env python3
"""
Fetch the Hinds County portrait sources from the Internet Archive -- POLITELY.

The county's own site was replaced by its vendor and now 404s /sites/default/files/*, so the
archive is the only source. Run from backend/data/seed-hinds-county-2026/portraits/ (or pass
--dir). Anything already in src/ is skipped, so a blocked run costs nothing.

🔴 THIS SCRIPT CANNOT "TRY HARDER". wayback_fetch stops the run on three consecutive 429s, by
design -- see the module docstring for how this machine got block-listed on 2026-10-31.
"""
import argparse, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from wayback_fetch import WaybackClient, Blocked, UA

ap = argparse.ArgumentParser()
ap.add_argument('--dir', default='.')
ap.add_argument('--min-gap', type=float, default=12.0, help='seconds between requests')
args = ap.parse_args()

listing = os.path.join(args.dir, 'hc-imglist.txt')
if not os.path.exists(listing):
    sys.exit(f'no hc-imglist.txt in {os.path.abspath(args.dir)}')

jobs = [l.split() for l in open(listing) if len(l.split()) == 3]
src = os.path.join(args.dir, 'src')
os.makedirs(src, exist_ok=True)

have = [j for j in jobs if os.path.exists(os.path.join(src, j[0]))]
todo = [j for j in jobs if j not in have]
print(f'{len(jobs)} sources, {len(have)} already on disk, {len(todo)} to fetch')
print(f'identifying as: {UA}')
print(f'pacing: 1 request per {args.min_gap:.0f}s, aborting on 3 consecutive 429s\n')

client = WaybackClient(min_gap=args.min_gap)
ok = fail = 0
try:
    for name, ts, url in todo:
        dest = os.path.join(src, name)
        if client.save(f'https://web.archive.org/web/{ts}im_/{url}', dest):
            print(f'  got  {name}  {os.path.getsize(dest)}b'); ok += 1
        else:
            print(f'  miss {name}'); fail += 1
        sys.stdout.flush()
except Blocked as e:
    print(f'\n🔴 {e}')
    print(f'\n{ok} fetched this run, {len(todo)-ok-fail} never attempted. Re-run later; '
          f'nothing already on disk is re-fetched.')
    sys.exit(2)

print(f'\n{ok} fetched, {fail} missed, {len(have)} already had. '
      f'{len(have)+ok}/{len(jobs)} complete.')
