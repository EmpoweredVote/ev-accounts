"""
render-banner-candidate-bands.py -- show each banner candidate AS THE 6:1 DESKTOP BAND.

🔴 CERTIFY AGAINST THE DESKTOP BAND, NOT THE FULL FRAME. SectionBanner is a responsive pair:
mobile 13/4 keeps 96.9% of a 1700x540 asset, desktop 6/1 keeps 52.5% -- rows 128-412. Two Austin
candidates looked fine at full frame and died in the band. banner_review.md said otherwise once
and was stale; following it reproduces the Bend defect.

Each candidate is composed the way it would actually ship -- centre 3.148:1 crop to 1700x540 --
and then the band is drawn beneath the full frame so the two can be compared directly.
"""
import json, os, sys
from io import BytesIO
import requests
from PIL import Image, ImageDraw

SRC, OUT, N = sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 12
CACHE = ".tmp-banner-cache"; os.makedirs(CACHE, exist_ok=True)
UA = {"User-Agent": "EmpoweredVote-banner-sourcing/1.0 (chris@empowered.vote)"}
ASSET = (1700, 540); RATIO = ASSET[0] / ASSET[1]
BAND_TOP, BAND_BOT = 128, 412

def compose(im, anchor_y=0.5):
    """Centre 3.148:1 crop scaled to 1700x540 -- the asset as it would ship."""
    w, h = im.size
    if w / h > RATIO:
        kh = h; kw = int(round(h * RATIO))
    else:
        kw = w; kh = int(round(w / RATIO))
    x = (w - kw) // 2
    y = int(round((h - kh) * anchor_y))
    return im.crop((x, y, x + kw, y + kh)).resize(ASSET, Image.LANCZOS)

cands = json.load(open(SRC, encoding="utf-8"))[:N]
W = 820
rows = []
for c in cands:
    ck = os.path.join(CACHE, str(abs(hash(c["url"]))) + ".bin")
    if os.path.exists(ck):
        raw = open(ck, "rb").read()
    else:
        raw = requests.get(c["url"], headers=UA, timeout=120).content
        open(ck, "wb").write(raw)
    im = Image.open(BytesIO(raw)); im.load(); im = im.convert("RGB")
    asset = compose(im)
    band = asset.crop((0, BAND_TOP, ASSET[0], BAND_BOT))
    rows.append((c, asset.resize((W, int(W * 540 / 1700))), band.resize((W, int(W * (BAND_BOT - BAND_TOP) / 1700)))))
    print(f"  {c['title'].replace('File:','')[:52]:<54}{im.size[0]}x{im.size[1]}")

hdr = 34
H = sum(a.height + b.height + hdr + 12 for _, a, b in rows)
sheet = Image.new("RGB", (W, H), "white"); d = ImageDraw.Draw(sheet); y = 0
for i, (c, a, b) in enumerate(rows):
    d.text((4, y + 4), f"{i+1}. {c['title'].replace('File:','')[:70]}", fill="black")
    d.text((4, y + 18), f"   {c['w']}x{c['h']}  {c['licence']}  |  FULL FRAME then 6:1 BAND", fill="#555")
    y += hdr
    sheet.paste(a, (0, y)); y += a.height + 2
    sheet.paste(b, (0, y)); y += b.height + 10
sheet.save(OUT)
print(f"\n{OUT}  {sheet.size[0]}x{sheet.size[1]}")
