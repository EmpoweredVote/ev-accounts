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
"""
import argparse
import json
import os
import sys
from io import BytesIO

import psycopg2
import requests
from dotenv import load_dotenv
from PIL import Image

load_dotenv()

BUCKET = "politician_photos"
CDN = f"https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/{BUCKET}/"
UPLOAD = f"https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/{BUCKET}/"
TARGET_W, TARGET_H = 600, 750
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}

ap = argparse.ArgumentParser()
ap.add_argument("--exclude", nargs="*", default=[], help="names to skip")
ap.add_argument("--only", nargs="*", default=[], help="import only these names")
ap.add_argument("--dry-run", action="store_true")
args = ap.parse_args()

key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
conn = psycopg2.connect(os.environ["DATABASE_URL"], sslmode="require")
cur = conn.cursor()

cands = [c for c in json.load(open(".tmp-all-candidates.json", encoding="utf-8")) if c.get("url")]
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
    if cur.fetchone():
        skipped += 1
        print(f"  skip     {c['name']:<26} already has an image row")
        continue
    try:
        raw = requests.get(c["url"], headers=UA, timeout=60).content
        # Magic number, never the extension: a WAF page can arrive as HTTP 200.
        if not (raw[:3] == b"\xff\xd8\xff" or raw[:4] == b"\x89PNG") or len(raw) < 2000:
            failed += 1
            problems.append(f"{c['name']}: source did not return a usable image")
            continue
        img = Image.open(BytesIO(raw))
        # Flatten any alpha onto white FIRST -- convert('RGB') alone turns transparent
        # pixels black, which is how a masked PNG becomes a circle on a black square.
        if img.mode in ("RGBA", "LA", "P"):
            img = img.convert("RGBA")
            bg = Image.new("RGBA", img.size, (255, 255, 255, 255))
            img = Image.alpha_composite(bg, img)
        img = img.convert("RGB")
        w, h = img.size
        ratio = TARGET_W / TARGET_H
        if w / h > ratio:
            kw, kh = int(h * ratio), h
            img = img.crop(((w - kw) // 2, 0, (w - kw) // 2 + kw, h))
        else:
            kw, kh = w, int(w / ratio)
            img = img.crop((0, (h - kh) // 2, w, (h - kh) // 2 + kh))
        upscale = max(TARGET_W / kw, TARGET_H / kh)
        img = img.resize((TARGET_W, TARGET_H), Image.LANCZOS)
        buf = BytesIO()
        img.save(buf, "JPEG", quality=90)
        data = buf.getvalue()
        filename = f"{pid}-headshot.jpg"
        final = CDN + filename

        if args.dry_run:
            print(f"  would   {c['name']:<26} {w}x{h} ({upscale:.2f}x) -> {filename}")
            done += 1
            continue

        up = requests.post(UPLOAD + filename,
                           headers={"Authorization": f"Bearer {key}",
                                    "Content-Type": "image/jpeg", "x-upsert": "true"},
                           data=data, timeout=90)
        if up.status_code not in (200, 201):
            failed += 1
            problems.append(f"{c['name']}: upload HTTP {up.status_code} {up.text[:100]}")
            continue
        cur.execute(
            """INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
               SELECT %s, %s, 'default', %s
                WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id = %s)""",
            (pid, final, c["license"], pid))
        # photo_origin_url records the SOURCE PAGE (provenance), not the image URL.
        cur.execute(
            "UPDATE essentials.politicians SET photo_origin_url = %s WHERE id = %s AND photo_origin_url IS NULL",
            (c["page"], pid))
        conn.commit()
        done += 1
        print(f"  imported {c['name']:<26} {w}x{h} ({upscale:.2f}x)")
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
