#!/usr/bin/env python
"""Mirror the approved WI winner headshots into Supabase Storage and emit the migration SQL.

Two rules this repo paid for, both load-bearing here:
  - Storage needs BOTH `apikey` and `Authorization`. A lone Bearer is refused as HTTP 400
    carrying a body that says 403 "Invalid Compact JWS", which reads like a missing object.
  - A person needs BOTH `politicians.photo_custom_url` (what the backend reads) and a
    `politician_images` row of type 'default' (what the grid reads out of images[]).
    Writing one without the other renders on one surface and blanks on the other, and no
    gate in this repo sees it.

It never writes to the database. It prints SQL for a migration to carry.
"""
import io, json, os, re, sys
import requests
from PIL import Image

PROJECT = "kxsdzaojfaibhuzmclfq"
BUCKET = "politician_photos"
CDN = f"https://{PROJECT}.storage.supabase.co/storage/v1/object/public/{BUCKET}/"
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Safari/537.36"

def production_render(img):
    """Centre 4:5, then 600x750 Lanczos. No vertical auto-crop: pixel-based head detection
    is unreliable on plain backgrounds and silently over-crops."""
    img = img.convert("RGB"); w, h = img.size; tr = 4 / 5
    if w / h > tr:
        nw = int(h * tr); img = img.crop(((w - nw) // 2, 0, (w - nw) // 2 + nw, h))
    else:
        nh = int(w / tr); img = img.crop((0, (h - nh) // 2, w, (h - nh) // 2 + nh))
    return img.resize((600, 750), Image.LANCZOS)

def main(manifest_path, out_sql, key):
    rows = json.load(open(manifest_path))["import"]
    done = []
    for r in rows:
        resp = requests.get(r["image_url"], headers={"User-Agent": UA}, timeout=40)
        if resp.status_code != 200 or not resp.content:
            raise SystemExit(f'{r["name"]}: source returned {resp.status_code}')
        src = Image.open(io.BytesIO(resp.content)); sw, sh = src.size
        if (sw, sh) != tuple(r["source_px"]):
            raise SystemExit(f'{r["name"]}: source is now {sw}x{sh}, manifest recorded '
                             f'{r["source_px"][0]}x{r["source_px"][1]} - re-approve before importing')
        buf = io.BytesIO(); production_render(src).save(buf, "JPEG", quality=92)
        data = buf.getvalue()
        filename = f'{r["politician_id"]}-headshot.jpg'
        up = requests.post(
            f"https://{PROJECT}.supabase.co/storage/v1/object/{BUCKET}/{filename}",
            headers={"apikey": key, "Authorization": f"Bearer {key}",
                     "Content-Type": "image/jpeg", "x-upsert": "true"},
            data=data, timeout=60)
        if up.status_code not in (200, 201):
            raise SystemExit(f'{r["name"]}: upload {up.status_code} {up.text[:200]}')
        final = CDN + filename
        # The CDN is a different host from the upload host. Read the object back before
        # claiming it landed: a correct API response is not evidence the file is servable.
        back = requests.get(final, timeout=40)
        if back.status_code != 200 or len(back.content) != len(data):
            raise SystemExit(f'{r["name"]}: read-back {back.status_code} '
                             f'{len(back.content)} bytes vs {len(data)} uploaded')
        done.append({**r, "cdn_url": final, "bytes": len(data), "source_px": [sw, sh]})
        print(f'  {r["name"]:24} {sw}x{sh} -> {len(data)//1024} KB  OK', flush=True)

    json.dump(done, open(out_sql + ".json", "w"), indent=1)
    with open(out_sql, "w", encoding="utf-8") as f:
        for r in done:
            pid, url = r["politician_id"], r["cdn_url"]
            lic, origin = r["licence"], r["origin_page"].replace("'", "''")
            f.write(
f"""  -- {r['name']} — {r['seat']}
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT '{pid}', '{url}', 'default', '{lic}'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = '{pid}' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = '{url}', photo_origin_url = '{origin}'
   WHERE id = '{pid}' AND photo_custom_url IS NULL;

""")
    print("wrote", out_sql)

if __name__ == "__main__":
    k = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not k: raise SystemExit("SUPABASE_SERVICE_ROLE_KEY is not set")
    main(sys.argv[1], sys.argv[2], k)
