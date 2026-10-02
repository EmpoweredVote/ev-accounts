#!/usr/bin/env python
"""measure-ks-portraits.py — Knight program, wave KS-5.

Decodes every portrait that build-ks-portrait-manifest.mjs saved and writes the real dimensions,
upscale factor and a monochrome test back into the manifest. Reads and writes files only.

Why this is a separate pass: a hand-rolled JPEG SOF walker in the collector returned null on some
of these files, and a null dimension reported as "no upscale" is worse than no number. PIL decodes.

Checks it adds, each of which has cost a published frame before:
  * upscale   — 600/width. SC-5 and MN-5 both turned on the display size not being the file size.
  * monochrome — `headshot_crop.monochrome` is enforced in code now, because documented-but-
    unenforced cost 156 published frames. Measured as mean per-pixel channel spread.
  * aspect    — a portrait far from 4:5 will lose face to the crop; reported, not judged.
"""
import json
import os
import pathlib
import sys

from PIL import Image, ImageStat

ROOT = pathlib.Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "data/seed-ks-2026/ks-portrait-manifest.json"

rows = json.loads(MANIFEST.read_text(encoding="utf-8"))

measured = 0
for r in rows:
    f = r.get("file")
    if not f:
        continue
    p = ROOT / f
    if not p.exists():
        r.setdefault("notes", []).append("FILE MISSING ON DISK")
        continue
    try:
        im = Image.open(p)
        im.load()
    except Exception as e:  # a file that will not decode must never reach the importer
        r.setdefault("notes", []).append("WILL NOT DECODE: %s" % e)
        continue

    w, h = im.size
    r["width"], r["height"] = w, h
    r["upscale"] = round(600.0 / w, 2)
    r["aspect"] = round(w / h, 3)

    rgb = im.convert("RGB")
    # Mean absolute spread between channels. A true greyscale image scores ~0.
    small = rgb.resize((64, 64))
    px = list(small.getdata())
    spread = sum(max(p) - min(p) for p in px) / float(len(px))
    r["colour_spread"] = round(spread, 2)
    r["monochrome"] = spread < 6.0

    notes = [n for n in r.get("notes", []) if not n.startswith("upscale ")]
    if r["upscale"] > 1:
        notes.append("upscale %.2fx" % r["upscale"])
    if r["monochrome"]:
        notes.append("MONOCHROME — skip, enforced in code")
    r["notes"] = notes
    measured += 1

MANIFEST.write_text(json.dumps(rows, indent=1), encoding="utf-8")

usable = [r for r in rows if r.get("status") == 200 and not r.get("is_placeholder") and r.get("width")]
sizes = sorted({"%dx%d" % (r["width"], r["height"]) for r in usable})
ups = [r["upscale"] for r in usable]
mono = [r for r in usable if r.get("monochrome")]
undecodable = [r for r in rows if any(n.startswith("WILL NOT DECODE") for n in r.get("notes", []))]

print("measured          %d" % measured)
print("usable            %d" % len(usable))
print("will not decode   %d" % len(undecodable))
print("monochrome        %d" % len(mono))
print("distinct sizes    %s" % " · ".join(sizes))
if ups:
    print("upscale to 600w   min %.2fx · max %.2fx · all-same=%s"
          % (min(ups), max(ups), len(set(ups)) == 1))
for r in undecodable:
    print("  🔴 %s — %s" % (r.get("name"), r["notes"][-1]))
for r in mono:
    print("  ⚠ monochrome: %s (spread %.2f)" % (r.get("name"), r["colour_spread"]))
