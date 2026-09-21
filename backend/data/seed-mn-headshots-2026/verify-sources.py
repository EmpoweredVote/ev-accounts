"""
MN-5: fetch every candidate portrait and prove it is a real, whole image before anyone approves it.

THE ONLY HONEST TEST OF AN IMAGE IS A FULL DECODE (GA-6). Image.verify() reads the header and passes
a truncated file; Image.load() is what fails. legis.ga.gov served two portraits capped at exactly
1 MiB with a valid SOI, an agreeing Content-Length and no EOI, and every cheap test passed.

Byte-distinctness is not decoration either: if a chamber serves one placeholder for members without a
portrait, every copy is byte-identical, and a repeated hash is what exposes it.
"""
import hashlib
import json
import sys
from io import BytesIO

import requests
from PIL import Image

CACHE = ".tmp-headshot-cache"  # shared with the contact sheet: the operator approves these bytes
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
TARGET_W, TARGET_H = 600, 750

import os
os.makedirs(CACHE, exist_ok=True)
path = sys.argv[1]
cands = json.load(open(path, encoding="utf-8"))
rows, hashes, problems = [], {}, []

for c in cands:
    if not c.get("url"):
        continue
    ck = os.path.join(CACHE, hashlib.sha1(c["url"].encode()).hexdigest() + ".bin")
    if os.path.exists(ck) and os.path.getsize(ck) > 0:
        raw = open(ck, "rb").read()
        src = "cache"
    else:
        r = requests.get(c["url"], headers=UA, timeout=60)
        raw = r.content
        src = f"HTTP {r.status_code}"
        if r.status_code != 200:
            problems.append(f"{c['name']}: {src}")
            continue
        open(ck, "wb").write(raw)
    try:
        im = Image.open(BytesIO(raw))
        im.load()                      # FULL decode, not verify()
        w, h = im.size
        fmt = im.format
    except Exception as e:             # noqa: BLE001
        problems.append(f"{c['name']}: does not decode -- {type(e).__name__}: {e}")
        continue
    if len(raw) in (1048576, 2097152):
        problems.append(f"{c['name']}: body is exactly {len(raw)} bytes -- a capped response")
    digest = hashlib.sha256(raw).hexdigest()
    hashes.setdefault(digest, []).append(c["name"])
    # what the 4:5 crop will yield, and whether it reaches the 600x750 ceiling
    crop_w, crop_h = (w, int(round(w * TARGET_H / TARGET_W))) if w / h < TARGET_W / TARGET_H else (int(round(h * TARGET_W / TARGET_H)), h)
    crop_w, crop_h = min(crop_w, w), min(crop_h, h)
    rows.append({"name": c["name"], "bytes": len(raw), "format": fmt, "w": w, "h": h,
                 "crop": f"{crop_w}x{crop_h}", "upscale": round(max(TARGET_W / crop_w, TARGET_H / crop_h), 2),
                 "src": src})

dupes = {d: n for d, n in hashes.items() if len(n) > 1}
print(f"{len(rows)} decoded · {len(problems)} problem(s) · {len(hashes)} byte-distinct of {len(rows)}")
small = [r for r in rows if r["upscale"] > 1.0]
print(f"below the 600x750 ceiling: {len(small)}"
      + (f" (max upscale {max(r['upscale'] for r in small)}x)" if small else ""))
for d, names in dupes.items():
    print(f"  DUPLICATE BYTES {d[:12]}: {', '.join(names)}")
for p in problems:
    print(f"  {p}")
json.dump(rows, open(path.replace(".json", "-sources.json"), "w", encoding="utf-8"), indent=1)
sys.exit(1 if problems or dupes else 0)
