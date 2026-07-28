"""
seed-wi-legislature-headshots.py

Download, crop, resize and (optionally) upload headshots for sitting Wisconsin state legislators.

  py scripts/seed-wi-legislature-headshots.py            # process locally + build contact sheets
  py scripts/seed-wi-legislature-headshots.py --upload   # also upload to Supabase Storage

Pipeline mirrors _tmp-nv-legislature-headshots.py (D-01 crop-first):
  1. Resolve politician UUID at RUNTIME from the guard's manifest (never hardcode a UUID).
  2. Download the high-res portrait from the member's own legis.wisconsin.gov site
     (Umbraco media, ?width=1600). The docs.legis roster image is only 150x200 and is used
     ONLY as an explicit fallback.
  3. CROP to 4:5 FIRST — never stretch.
  4. RESIZE to 600x750 Lanczos q90 (re-encode strips EXIF).
  5. Upload to politician_photos/{uuid}-headshot.jpg via PUT with x-upsert: true.

Crop placement: Umbraco publishes an official focal point as rxy=x,y on the portrait URL. Where
present it is used to place the subject; otherwise the crop is anchored to the TOP of the frame.
Neither path vertically centres the head — centring buries the subject low in the frame.
"""

import csv
import io
import os
import sys
import time

import requests
from PIL import Image

DIR = os.path.join('data', 'stance-research', 'wi-2026-state-leg')
OUT = os.path.join(DIR, 'processed')
SHEETS = os.path.join(DIR, 'contact_sheets')

TARGET = (600, 750)
JPEG_QUALITY = 90
MIN_SRC_DIM = 100
UPLOAD = '--upload' in sys.argv

UA = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                    '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'image/webp,image/jpeg,image/png,image/*,*/*;q=0.8'}

_env = {}
with open(os.path.join(os.path.dirname(__file__), '..', '.env')) as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith('#') and '=' in line:
            k, v = line.split('=', 1)
            _env[k.strip()] = v.strip()

SUPABASE_URL = _env.get('SUPABASE_URL', '')
SERVICE_KEY = _env.get('SUPABASE_SERVICE_ROLE_KEY', '')
BUCKET = 'politician_photos'
CDN_BASE = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos'


def read_csv(path):
    with open(path, encoding='utf-8') as f:
        return list(csv.DictReader(f))


def crop_4_5(img, rxy):
    """Crop to 4:5. Uses the official focal point when available, else anchors to the top."""
    w, h = img.size
    target = 4.0 / 5.0
    ratio = w / h
    if abs(ratio - target) < 0.001:
        return img, 'none'
    if ratio > target:
        # Wider than 4:5 — crop width. Centre horizontally unless a focal x is given.
        new_w = int(round(h * target))
        fx = 0.5
        if rxy:
            try:
                fx = float(rxy.split(',')[0])
            except ValueError:
                pass
        left = int(round(fx * w - new_w / 2))
        left = max(0, min(left, w - new_w))
        return img.crop((left, 0, left + new_w, h)), f'horizontal@{fx:.3f}'
    # Taller than 4:5 — crop height.
    new_h = int(round(w / target))
    if rxy:
        try:
            fy = float(rxy.split(',')[1])
        except ValueError:
            fy = None
        if fy is not None:
            # Put the focal point ~38% down the final frame: keeps headroom above the hairline
            # instead of centring the face.
            top = int(round(fy * h - new_h * 0.38))
            top = max(0, min(top, h - new_h))
            return img.crop((0, top, w, top + new_h)), f'vertical@{fy:.3f}'
    return img.crop((0, 0, w, new_h)), 'top'


def process(raw):
    img = Image.open(io.BytesIO(raw))
    if img.mode != 'RGB':
        img = img.convert('RGB')
    src = img.size
    if img.width < MIN_SRC_DIM or img.height < MIN_SRC_DIM:
        raise Exception(f'source too small: {img.width}x{img.height}')
    return img, src


def main():
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(SHEETS, exist_ok=True)

    manifest = {(r['chamber'], int(r['district'])): r
                for r in read_csv(os.path.join(DIR, 'wi_headshot_import_manifest.csv'))}
    sources = read_csv(os.path.join(DIR, 'wi_portrait_sources.csv'))

    results = []
    for s in sources:
        keyed = manifest.get((s['chamber'], int(s['district'])))
        if not keyed:
            print(f"  SKIP {s['chamber']}{s['district']} — not in guard manifest")
            continue
        pid = keyed['politician_id']
        name = keyed['prod_name'].strip('"')
        used_fallback = not s['portrait_url']
        url = s['portrait_url'] or s['fallback']
        try:
            r = requests.get(url, headers=UA, timeout=30)
            if r.status_code != 200:
                raise Exception(f'HTTP {r.status_code}')
            img, src = process(r.content)
            cropped, how = crop_4_5(img, s.get('rxy', ''))
            final = cropped.resize(TARGET, Image.Resampling.LANCZOS)
            path = os.path.join(OUT, f'{pid}-headshot.jpg')
            final.save(path, 'JPEG', quality=JPEG_QUALITY, optimize=True)
            # Upscale factor tells us honestly how soft the result will look.
            upscale = round(TARGET[0] / cropped.width, 2)
            results.append({'politician_id': pid, 'name': name, 'chamber': s['chamber'],
                            'district': s['district'], 'src_w': src[0], 'src_h': src[1],
                            'upscale': upscale, 'crop': how, 'fallback': used_fallback,
                            'url': url, 'path': path, 'ok': True, 'error': ''})
            print(f"  OK   {s['chamber']}{s['district']:>3} {name[:26]:<26} src={src[0]}x{src[1]:<5} "
                  f"upscale={upscale}x crop={how}{'  [FALLBACK 150px]' if used_fallback else ''}")
        except Exception as e:
            results.append({'politician_id': pid, 'name': name, 'chamber': s['chamber'],
                            'district': s['district'], 'src_w': 0, 'src_h': 0, 'upscale': 0,
                            'crop': '', 'fallback': used_fallback, 'url': url, 'path': '',
                            'ok': False, 'error': str(e)})
            print(f"  FAIL {s['chamber']}{s['district']} {name} — {e}")
        time.sleep(0.15)

    with open(os.path.join(DIR, 'wi_headshot_processed.csv'), 'w', newline='', encoding='utf-8') as f:
        wr = csv.DictWriter(f, fieldnames=list(results[0].keys()))
        wr.writeheader()
        wr.writerows(results)

    good = [r for r in results if r['ok']]
    hires = [r for r in good if not r['fallback']]
    fb = [r for r in good if r['fallback']]
    print(f"\nprocessed {len(good)}/{len(results)}")
    print(f"  high-res member-site portrait: {len(hires)}  (median upscale "
          f"{sorted(r['upscale'] for r in hires)[len(hires)//2] if hires else 0}x)")
    print(f"  150x200 roster fallback:       {len(fb)}  (upscale ~4x — visibly soft)")

    # Contact sheets, 20 per sheet, so the batch can actually be eyeballed for wrong-person /
    # not-a-headshot errors rather than trusted on filename heuristics.
    for group, label in ((hires, 'hires'), (fb, 'fallback')):
        for i in range(0, len(group), 20):
            batch = group[i:i + 20]
            cols, tw, th = 5, 180, 225
            rows = (len(batch) + cols - 1) // cols
            sheet = Image.new('RGB', (cols * tw, rows * (th + 16)), 'white')
            for n, r in enumerate(batch):
                im = Image.open(r['path']).resize((tw, th), Image.Resampling.LANCZOS)
                sheet.paste(im, ((n % cols) * tw, (n // cols) * (th + 16)))
            p = os.path.join(SHEETS, f'{label}_{i//20 + 1}.jpg')
            sheet.save(p, 'JPEG', quality=88)
            print(f'  contact sheet: {p}  ({len(batch)} images)')

    if not UPLOAD:
        print('\n(no --upload flag: nothing sent to Supabase Storage)')
        return

    if not SERVICE_KEY or not SUPABASE_URL:
        print('ERROR: SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY missing from .env')
        sys.exit(1)
    uploaded = 0
    for r in good:
        fn = f"{r['politician_id']}-headshot.jpg"
        with open(r['path'], 'rb') as fh:
            data = fh.read()
        resp = requests.put(f'{SUPABASE_URL}/storage/v1/object/{BUCKET}/{fn}', data=data,
                            headers={'Authorization': f'Bearer {SERVICE_KEY}',
                                     'Content-Type': 'image/jpeg', 'x-upsert': 'true'},
                            timeout=60)
        if resp.status_code not in (200, 201):
            print(f"  UPLOAD FAIL {r['name']}: {resp.status_code} {resp.text[:120]}")
            continue
        uploaded += 1
        print(f"  uploaded {r['name']} -> {CDN_BASE}/{fn}")
    print(f'\nuploaded {uploaded}/{len(good)}')


if __name__ == '__main__':
    main()
