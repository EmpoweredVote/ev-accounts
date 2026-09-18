"""
MN-6: switch the 133 House candidates from the page's 525x675 palette GIF to the 1050x1350 JPEG
the House publishes at the SAME base name, and PROVE the two are the same photograph first.

🔴 A FILE AT THE SAME BASE NAME IS NOT NECESSARILY THE SAME PHOTOGRAPH. The member's profile page
links only the GIF, so the JPEG is unlinked and unlabelled -- nothing on the page asserts they
depict the same person. The check: downscale the JPEG to the GIF's exact size and measure the mean
absolute pixel difference. Same photo through palette quantisation and JPEG encoding lands low; a
different sitting, a different crop or a different person lands high. The verdict comes from the
MEASURED distribution, never from a threshold guessed in advance.
"""
import json, io, statistics
import requests
import numpy as np
from PIL import Image

UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
P = 'data/seed-mn-headshots-2026/candidates-house.json'
cands = json.load(open(P, encoding='utf-8'))

def get(u):
    r = requests.get(u, headers=UA, timeout=40)
    assert r.status_code == 200, f'{u} -> {r.status_code}'
    im = Image.open(io.BytesIO(r.content)); im.load()
    return im

rows, fails = [], []
for c in cands:
    base = c['url'].split('?')[0].rsplit('.', 1)[0]
    try:
        g = get(base + '.gif').convert('RGB')
        j = get(base + '.jpg').convert('RGB')
        jr = j.resize(g.size, Image.LANCZOS)
        mad = float(np.abs(np.asarray(g, dtype=np.int16) - np.asarray(jr, dtype=np.int16)).mean())
        rows.append((mad, c['name'], g.size, j.size))
    except Exception as e:
        fails.append((c['name'], str(e)))

rows.sort(reverse=True)
mads = [r[0] for r in rows]
print(f'compared {len(rows)} pairs, {len(fails)} failures')
for f in fails: print('  FAIL', f)
print(f'mean-abs-difference  min {min(mads):.2f}  median {statistics.median(mads):.2f}  max {max(mads):.2f}')
print('the five largest differences (these are the ones that would hide a swap):')
for mad, name, gs, js in rows[:5]:
    print(f'  {mad:6.2f}  {name:32s} gif {gs}  jpg {js}')
print('the three smallest:')
for mad, name, gs, js in rows[-3:]:
    print(f'  {mad:6.2f}  {name:32s} gif {gs}  jpg {js}')
