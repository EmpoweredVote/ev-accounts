"""
Verify a headshot wave FROM OUTSIDE: re-fetch what the read path composes and DECODE it.

WHY THIS EXISTS BESIDE verify-rendered-photo-urls.mjs. That script sweeps a whole state
and is filtered by flags. MN-6 shipped a verifier that printed "108 rows, 0 broken,
control failed as required" while testing NONE of the 133 rows just written, because an
exclusion added for a since-fixed reason survived the fix. A control proves a verifier CAN
fail; it never proves the verifier read the right rows. THE COUNT IS THE TELL.

So this one is scoped to a wave's own candidate JSON, and it:
  * resolves each candidate's politician_id against the DB read path
    (COALESCE(photo_custom_url, photo_origin_url)) rather than trusting the JSON,
  * fetches the bytes and DECODES them -- a clean HTTP 200 can carry a truncated body,
    and only a full decode catches that,
  * ASSERTS the number of rows actually tested against --expect, and exits non-zero if it
    differs,
  * runs a negative control (a CDN key for a random UUID) that MUST fail. If the control
    passes, every other answer in the run is meaningless.

Usage (from the wave's backend/):
  py scripts/verify-imported-headshots.py --json .tmp-pa-candidates.json --expect 252
"""
import argparse
import json
import os
import sys
import uuid
from concurrent.futures import ThreadPoolExecutor
from io import BytesIO

import psycopg2
import requests
from dotenv import load_dotenv
from PIL import Image

load_dotenv()

ap = argparse.ArgumentParser()
ap.add_argument("--json", required=True)
ap.add_argument("--expect", type=int, required=True,
                help="how many rows this run MUST test. A smaller number is the MN-6 failure.")
ap.add_argument("--concurrency", type=int, default=8)
args = ap.parse_args()

cands = json.load(open(args.json, encoding="utf-8"))
ids = [c["politician_id"] for c in cands if c.get("politician_id")]
names = {c["politician_id"]: c["name"] for c in cands if c.get("politician_id")}

conn = psycopg2.connect(os.environ["DATABASE_URL"], sslmode="require")
cur = conn.cursor()
cur.execute("""SELECT p.id::text, COALESCE(p.photo_custom_url, p.photo_origin_url, '')
                 FROM essentials.politicians p
                WHERE p.id = ANY(%s::uuid[])""", (ids,))
rows = [(pid, url) for pid, url in cur.fetchall() if url]
cur.execute("""SELECT p.id::text FROM essentials.politicians p
                WHERE p.id = ANY(%s::uuid[])
                  AND COALESCE(p.photo_custom_url, p.photo_origin_url, '') = ''""", (ids,))
blank = [names.get(r[0], r[0]) for r in cur.fetchall()]

UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}


def probe(url):
    """Return (ok, detail). ok only when the bytes DECODE as an image."""
    try:
        r = requests.get(url, headers=UA, timeout=60)
    except Exception as e:  # noqa: BLE001
        return False, f"fetch failed: {type(e).__name__}"
    if r.status_code != 200:
        return False, f"HTTP {r.status_code}"
    try:
        im = Image.open(BytesIO(r.content))
        im.load()                      # full decode: a truncated body dies HERE, not on open()
    except Exception as e:  # noqa: BLE001
        return False, f"undecodable ({type(e).__name__}), {len(r.content)} bytes"
    return True, f"{im.width}x{im.height} {im.format} {len(r.content)}B"


# NEGATIVE CONTROL FIRST, and watched failing. A CDN key for a UUID nobody holds must not
# decode. If this passes, stop -- the probe is answering yes to everything.
ctl_url = rows[0][1].rsplit("/", 1)[0] + f"/{uuid.uuid4()}-headshot.jpg"
ctl_ok, ctl_detail = probe(ctl_url)
print(f"control (bogus CDN key): {'PASSED - PROBE IS BROKEN' if ctl_ok else 'failed as required'} "
      f"-- {ctl_detail}")
if ctl_ok:
    sys.exit(2)

results = []
with ThreadPoolExecutor(max_workers=args.concurrency) as ex:
    for (pid, url), (ok, detail) in zip(rows, ex.map(lambda r: probe(r[1]), rows)):
        results.append((pid, url, ok, detail))

broken = [(names.get(p, p), u, d) for p, u, ok, d in results if not ok]
sizes = {}
for _, _, ok, d in results:
    if ok:
        sizes[d.split()[0]] = sizes.get(d.split()[0], 0) + 1

print(f"\ntested {len(results)} rows -- decoded {len(results) - len(broken)}, broken {len(broken)}")
print("sizes: " + ", ".join(f"{k} x{v}" for k, v in sorted(sizes.items(), key=lambda kv: -kv[1])))
if blank:
    print(f"no photo at all ({len(blank)}): {', '.join(blank)}")
for n, u, d in broken:
    print(f"  BROKEN {n}: {d} -- {u}")

if len(results) != args.expect:
    print(f"\n!! COUNT MISMATCH: tested {len(results)}, expected {args.expect}. "
          f"A verifier that reads the wrong rows reports a clean bill of health.")
    sys.exit(3)
print(f"\ncount check: tested {len(results)} == expected {args.expect}")
sys.exit(1 if broken else 0)
