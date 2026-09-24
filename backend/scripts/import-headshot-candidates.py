"""
Import approved headshot candidates: render the production crop, upload to Supabase
Storage, create the politician_images row, and record provenance.

Run ONLY after the operator has approved a contact sheet
(scripts/render-headshot-contact-sheet.py). Reads the same candidates JSON.

  --exclude "Name" "Name"   skip the ones the operator rejected
  --only    "Name"          import just these
  --dry-run                 render and report, write nothing

WHAT IT GETS RIGHT THAT A NAIVE IMPORTER DOES NOT
  * Alpha is flattened onto WHITE before RGB conversion. convert("RGB") alone turns
    transparent pixels BLACK, which is how a circular-masked PNG portrait becomes a
    circle on a black square. Three El Paso County officials shipped as exactly that
    before this was fixed.
  * The image check is the MAGIC NUMBER, never the file extension and never r.ok -- a
    WAF rejection can arrive as HTTP 200.
  * photo_origin_url records the SOURCE PAGE (provenance). politician_images.url is
    the thing that renders. Putting a raw image URL in photo_origin_url works by
    accident because HAS_RENDERABLE_PHOTO_SQL accepts anything LIKE 'http%', and it
    means a dead link counts as coverage -- see scripts/verify-photo-origin-urls.mjs.
  * Anyone who already has an image row is skipped, so a re-run is a no-op.

USAGE (from C:/EV-Accounts/backend):
  py scripts/import-headshot-candidates.py --dry-run
  py scripts/import-headshot-candidates.py --exclude "Some Person"
  py scripts/import-headshot-candidates.py --replace   # repair missing/placeholder objects
"""
import argparse
import hashlib
import json
import os
import sys
from io import BytesIO

import psycopg2
import requests
from dotenv import load_dotenv
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from headshot_crop import crop_4x5, monochrome  # noqa: E402

load_dotenv()

BUCKET = "politician_photos"
CDN = f"https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/{BUCKET}/"
UPLOAD = f"https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/{BUCKET}/"
TARGET_W, TARGET_H = 600, 750
CACHE = ".tmp-headshot-cache"
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}

ap = argparse.ArgumentParser()
ap.add_argument("--json", default=".tmp-all-candidates.json",
                help="the approved candidates file, matching render-headshot-contact-sheet.py's "
                     "--json. Pass the SAME path that was rendered: writing a wave's list over "
                     "the shared default would clobber another wave's in-flight approval")
ap.add_argument("--exclude", nargs="*", default=[], help="names to skip")
ap.add_argument("--only", nargs="*", default=[], help="import only these names")
ap.add_argument("--dry-run", action="store_true")
ap.add_argument("--replace", action="store_true",
                help="repair a row that already has an image: re-upload and REPOINT it. Use only "
                     "when the existing object is missing or a placeholder -- verify with "
                     "scripts/verify-rendered-photo-urls.mjs first")
ap.add_argument("--max-upscale", type=float, default=1.0,
                help="enlarge up to this factor to reach 600x750; beyond it, store at native "
                     "cropped size instead (default 1.0 = never enlarge)")
args = ap.parse_args()

key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]

# 🔴 SEND BOTH `apikey` AND `Authorization`, NEVER `Authorization` ALONE.
# Supabase now issues secret keys in the `sb_secret_…` format instead of the legacy
# service_role JWT. Storage parses a lone Bearer token as a compact JWS, so an
# `sb_secret_` key arrives as HTTP 400 carrying {"statusCode":"403", …,
# "message":"Invalid Compact JWS"} -- an auth failure wearing two different status
# codes at once, which reads like a broken object rather than a rejected credential.
# It failed all 161 uploads of the OH-5 wave. The `apikey` header is accepted for
# BOTH key formats, so sending both works whichever key the .env carries and needs
# no migration.
STORAGE_AUTH = {"apikey": key, "Authorization": f"Bearer {key}"}
conn = psycopg2.connect(os.environ["DATABASE_URL"], sslmode="require")
cur = conn.cursor()

cands = [c for c in json.load(open(args.json, encoding="utf-8")) if c.get("url")]
if args.only:
    cands = [c for c in cands if c["name"] in args.only]
cands = [c for c in cands if c["name"] not in args.exclude]

print(f"{len(cands)} to import{' (DRY RUN)' if args.dry_run else ''}\n")
done = skipped = failed = 0
problems = []

for c in cands:
    pid = c.get("politician_id")
    if not pid:
        failed += 1
        problems.append(f"{c['name']}: no politician_id")
        continue
    cur.execute("SELECT 1 FROM essentials.politician_images WHERE politician_id = %s", (pid,))
    has_row = cur.fetchone() is not None
    # An existing image row normally means DONE, so a re-run is a no-op. But "has a row" is not
    # the same as "has a picture": the row can point at an object that is not in the bucket, or
    # at a placeholder. Seven Massachusetts legislators held a row AND a photo_custom_url for a
    # file that returns NoSuchKey. --replace is for repairing exactly those; it is never the
    # default, because overwriting a good portrait by accident is worse than skipping.
    if has_row and not args.replace:
        skipped += 1
        print(f"  skip     {c['name']:<26} already has an image row")
        continue
    try:
        # 🔴 CACHE-FIRST, SHARING THE PROOF SHEET'S CACHE. This is a correctness rule, not
        # a speed one: the operator approved specific BYTES on the contact sheet, and a
        # live refetch can return something else -- a WAF page, a 503, or a silently
        # updated image. Reusing the cached bytes means what shipped is what was approved.
        # It also stops the import re-hammering hosts the sheet already rate-limited:
        # miami.gov 403s every non-browser client, so those came from the Wayback Machine,
        # which then 503s under repeated fetches.
        ck = os.path.join(CACHE, hashlib.sha1(c["url"].encode()).hexdigest() + ".bin")
        if os.path.exists(ck) and os.path.getsize(ck) > 0:
            raw = open(ck, "rb").read()
        else:
            raw = requests.get(c["url"], headers=UA, timeout=60).content
        # 🔴 DECODABILITY, not a format whitelist. The rule that matters is "never trust the
        # extension and never trust HTTP status -- a WAF page arrives as HTTP 200" -- and
        # actually decoding the bytes enforces that MORE strictly than a magic-number
        # allowlist did. The old allowlist was JPEG+PNG only, so it silently refused every
        # WEBP: nine officials rendered on the proof sheet and would have vanished at import,
        # including seven Leon County kiosk portraits.
        try:
            Image.open(BytesIO(raw)).verify()
            decodable = True
        except Exception:  # noqa: BLE001
            decodable = False
        if not decodable or len(raw) < 2000:
            failed += 1
            problems.append(f"{c['name']}: source did not return a usable image")
            continue
        # ONE crop implementation, shared with the proof sheet (scripts/headshot_crop.py),
        # so the operator approves exactly what ships. Alpha flattening onto white lives
        # there too. A per-row "crop" override handles subjects the centre crop gets wrong
        # -- someone standing beside a banner, inside a photo mat, or with their head at
        # the top edge. Without it the default centre crop silently decapitates them.
        src = Image.open(BytesIO(raw))
        w, h = src.size                    # SOURCE size, reported in the log line
        img, (kw, kh) = crop_4x5(src, **c.get("crop", {}))

        # 🔴 NEVER SHIP A MONOCHROME PORTRAIT -- a house rule, enforced here so it holds
        # even when a greyscale row reaches the importer. It was previously enforced only
        # by the operator's eye on the proof sheet, and SC-5a is what that cost: the South
        # Carolina Legislative Manual is printed in DeviceGray, so 156 greyscale
        # candidates were built, rendered and published for approval before anyone saw it.
        # `allow_monochrome: true` on the row is the deliberate override, per person, and
        # it has to be written down rather than passed as a global flag.
        if not c.get("allow_monochrome"):
            is_mono, chroma, neutral = monochrome(img)
            if is_mono:
                failed += 1
                problems.append(
                    f"{c['name']}: MONOCHROME (chroma {chroma:.1f}, neutral {neutral:.2f}) "
                    "-- black-and-white portraits are never shipped. Find a colour source, "
                    "or set allow_monochrome on this row if it is genuinely wanted.")
                continue

        # NEVER ENLARGE, AND NEVER SKIP FOR BEING SMALL.
        # A source below 600x750 gets stored at its own cropped size instead of being
        # blown up to fit. Both alternatives are worse: enlarging bakes in interpolation
        # and produces a file that LOOKS like a full-resolution asset while carrying no
        # more detail, and skipping leaves the person hotlinked to somebody else's host,
        # which is how 7 Colorado portraits silently became 404s. Storing the real pixels
        # keeps the bytes ours AND keeps the recorded resolution honest -- the browser
        # scales it at render time, and anyone inspecting the file sees what it actually is.
        # --max-upscale raises the ceiling deliberately; it is not the default.
        upscale = max(TARGET_W / kw, TARGET_H / kh)
        if upscale <= args.max_upscale:
            out_w, out_h = TARGET_W, TARGET_H
        else:
            out_w, out_h = kw, kh          # native cropped size, no enlargement
        # Resample only when the size actually changes. crop_4x5 hands back the crop at its
        # own size, so the native branch is now a straight save of the cropped pixels rather
        # than an enlarge-to-600x750-then-shrink-back round trip.
        if (out_w, out_h) != img.size:
            img = img.resize((out_w, out_h), Image.LANCZOS)
        buf = BytesIO()
        img.save(buf, "JPEG", quality=90)
        data = buf.getvalue()
        filename = f"{pid}-headshot.jpg"
        final = CDN + filename

        if args.dry_run:
            print(f"  would   {c['name']:<26} {w}x{h} -> {out_w}x{out_h}"
                  f"{'  [native, not enlarged]' if (out_w, out_h) != (TARGET_W, TARGET_H) else ''}")
            done += 1
            continue

        up = requests.post(UPLOAD + filename,
                           headers={**STORAGE_AUTH,
                                    "Content-Type": "image/jpeg", "x-upsert": "true"},
                           data=data, timeout=90)
        if up.status_code not in (200, 201):
            failed += 1
            problems.append(f"{c['name']}: upload HTTP {up.status_code} {up.text[:100]}")
            continue
        if has_row and args.replace:
            # REPOINT the existing row rather than inserting beside it. A second row of the
            # SAME type would leave the read paths picking whichever sorts first -- possibly
            # the dead one.
            # 🔴 AND REPOINT ONLY THE 'default' ROW. politician_images.type is load-bearing:
            # stanceService.ts reads WHERE type = 'default', and a second row is not always a
            # mistake -- 191 people legitimately carry a 'thumb' beside their portrait.
            # Without this predicate one --replace run pointed BOTH at the headshot and
            # destroyed the thumbnail's URL.
            cur.execute(
                """UPDATE essentials.politician_images
                      SET url = %s, photo_license = %s
                    WHERE politician_id = %s AND type = 'default'""",
                (final, c["license"], pid))
        else:
            cur.execute(
                """INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
                   SELECT %s, %s, 'default', %s
                    WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = %s)""",
                (pid, final, c["license"], pid))
        # 🔴 CREATING THE IMAGE ROW DOES NOT CHANGE WHAT A VOTER SEES.
        # The address-search path (districtQueries.ts, DISTRICT_SELECT_FIELDS) builds its
        # photo from COALESCE(photo_custom_url, photo_origin_url, '') and NEVER READS
        # politician_images; essentialsBodiesService.ts reads it only third. So the mirrored
        # copy has to be written to photo_custom_url or the person keeps rendering from
        # whatever host they were hotlinked to. Florida's 155 legislators were imported
        # without this and stayed on the chamber hotlink -- the exact thing the wave removed.
        if args.replace:
            # The stale value is the thing being repaired, so it must be overwritten, not
            # preserved by an "only if empty" guard.
            cur.execute("UPDATE essentials.politicians SET photo_custom_url = %s WHERE id = %s",
                        (final, pid))
        else:
            cur.execute(
                "UPDATE essentials.politicians SET photo_custom_url = %s "
                " WHERE id = %s AND btrim(coalesce(photo_custom_url, '')) = ''",
                (final, pid))
        # photo_origin_url records the SOURCE PAGE (provenance), not the image URL.
        # It is also rewritten when it currently holds a RAW IMAGE URL: that value is the
        # defect this pipeline exists to clear, and an IS NULL guard alone silently skipped
        # all 155 Florida rows while still reporting them imported. A page URL somebody
        # already recorded is left alone.
        cur.execute(
            "UPDATE essentials.politicians SET photo_origin_url = %s "
            " WHERE id = %s AND (photo_origin_url IS NULL "
            "                    OR photo_origin_url ~* '\\.(jpg|jpeg|png|webp|gif)(\\?|$)')",
            (c["page"], pid))
        conn.commit()
        done += 1
        print(f"  imported {c['name']:<26} {w}x{h} -> {out_w}x{out_h}"
              f"{'  [native, not enlarged]' if (out_w, out_h) != (TARGET_W, TARGET_H) else ''}")
    except Exception as e:  # noqa: BLE001
        conn.rollback()
        failed += 1
        problems.append(f"{c['name']}: {type(e).__name__}: {e}")

cur.close()
conn.close()
print(f"\nimported {done} · skipped {skipped} · failed {failed}")
for p in problems:
    print(f"  {p}")
sys.exit(1 if failed else 0)
