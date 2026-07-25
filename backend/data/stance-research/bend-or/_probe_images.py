#!/usr/bin/env python3
"""Probe candidate campaign sites for portrait-shaped images.
Lists every image on a page with its real dimensions so a human can pick the headshot.
Run: python data/stance-research/bend-or/_probe_images.py <url> [<url> ...]
"""
import sys, re, requests
from io import BytesIO
from urllib.parse import urljoin
from PIL import Image

UA = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/126.0 Safari/537.36'}


def images_on(page):
    r = requests.get(page, headers=UA, timeout=25)
    r.raise_for_status()
    html = r.text
    urls = []
    urls += re.findall(r'<meta[^>]+og:image[^>]+content="([^"]+)"', html, re.I)
    urls += re.findall(r'<img[^>]+src="([^"]+)"', html, re.I)
    urls += re.findall(r'<img[^>]+data-src="([^"]+)"', html, re.I)
    urls += re.findall(r'srcset="([^"]+)"', html, re.I)
    flat = []
    for u in urls:
        for part in u.split(','):
            cand = part.strip().split(' ')[0]
            if cand and not cand.startswith('data:'):
                flat.append(urljoin(page, cand))
    seen, out = set(), []
    for u in flat:
        if u in seen:
            continue
        seen.add(u)
        out.append(u)
    return out


for page in sys.argv[1:]:
    print(f'\n=== {page}')
    try:
        cands = images_on(page)
    except Exception as e:
        print(f'  page fetch failed: {e}')
        continue
    shown = 0
    for u in cands:
        if shown >= 14:
            break
        try:
            ir = requests.get(u, headers=UA, timeout=20)
            if not ir.ok or 'image' not in ir.headers.get('content-type', ''):
                continue
            im = Image.open(BytesIO(ir.content))
            w, h = im.size
            if w < 200 or h < 200:
                continue  # icons/logos
            ratio = w / h
            tag = 'PORTRAIT' if 0.6 <= ratio <= 0.95 else ('square' if 0.95 < ratio < 1.15 else 'wide')
            print(f'  {tag:9} {w}x{h}  {u[:130]}')
            shown += 1
        except Exception:
            continue
