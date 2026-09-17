"""
MN-5: fetch back what a browser is actually served, and decode it.

A database row is a claim about the database. HAS_RENDERABLE_PHOTO_SQL accepts anything URL-shaped,
so a 404 counts as coverage -- this is the claim about the OBJECT. It reads the value the read path
composes, COALESCE(photo_custom_url, photo_origin_url, ''), decodes it, and asserts the shape the
importer promises: 4:5, and no larger than 600x750.

⚠ A POSITIVE CONTROL RUNS ALONGSIDE: a bucket key that cannot exist must fail. A verifier that
passes everything is indistinguishable from one that tests nothing.
"""
import os
import sys
from io import BytesIO

import psycopg2
import requests
from dotenv import load_dotenv
from PIL import Image

load_dotenv()
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
GOVS = ('State of Minnesota', 'City of Duluth, Minnesota, US', 'City of Saint Paul, Minnesota, US',
        'St. Louis County, Minnesota, US', 'Ramsey County, Minnesota, US')

conn = psycopg2.connect(os.environ["DATABASE_URL"], sslmode="require")
cur = conn.cursor()
cur.execute("""
  SELECT DISTINCT p.full_name, c.name_formal,
         COALESCE(NULLIF(btrim(p.photo_custom_url), ''), NULLIF(btrim(p.photo_origin_url), ''), '')
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE g.name IN %s AND c.name_formal <> 'Minnesota House of Representatives'
   ORDER BY 2, 1""", (GOVS,))
rows = cur.fetchall()
cur.close(); conn.close()

CONTROL = ("CONTROL bogus object", "control",
           "https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/"
           "politician_photos/00000000-0000-0000-0000-000000000000-headshot.jpg")
ok = blank = bad = 0
problems = []
shapes = {}
for name, body, url in list(rows) + [CONTROL]:
    is_control = name.startswith("CONTROL")
    if not url:
        blank += 1
        problems.append(f"BLANK  {body:<42} {name}")
        continue
    try:
        r = requests.get(url, headers=UA, timeout=60)
        im = Image.open(BytesIO(r.content))
        im.load()
        w, h = im.size
        good = r.status_code == 200 and abs(w / h - 0.8) < 0.02 and w <= 600 and h <= 750
    except Exception as e:  # noqa: BLE001
        good, w, h = False, 0, 0
        if is_control:
            problems.append(f"control failed as required: {type(e).__name__}")
    if is_control:
        print(f"\npositive control: {'FAILED AS REQUIRED' if not good else 'PASSED -- THE VERIFIER IS BLIND'}")
        if good:
            sys.exit(2)
        continue
    if good:
        ok += 1
        shapes[f"{w}x{h}"] = shapes.get(f"{w}x{h}", 0) + 1
    else:
        bad += 1
        problems.append(f"BAD    {body:<42} {name}  HTTP {r.status_code} {w}x{h}")

print(f"{len(rows)} rows · {ok} decode and are 4:5 within 600x750 · {bad} broken · {blank} blank")
print("shapes: " + ", ".join(f"{k}x{v}" for k, v in sorted(shapes.items(), key=lambda x: -x[1])))
for p in problems:
    print(f"  {p}")
