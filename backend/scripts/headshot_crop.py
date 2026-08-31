"""
The 4:5 headshot crop, in ONE place, used by BOTH the proof sheet and the importer.

🔴 WHY THIS MODULE EXISTS. The renderer and the importer each had their own crop, and they
DRIFTED: the importer flattened alpha onto white, the renderer did not, so a PNG with
transparency shipped white but was shown to the operator as a BLACK FRAME WITH NO FACE.
A proof sheet that differs from the import is worse than no proof sheet, because it buys
false confidence. Both now import from here, so they cannot diverge again.

Returns the crop AT ITS NATIVE SIZE together with the pixels kept, so the caller decides
whether to scale it to TARGET. Do not resize here: a caller that stores native size would
then resample twice and lose detail it never needed to lose.

The default is a CENTRE 4:5 crop, which is right for a standard portrait. Per-person
overrides live on the candidate row as a "crop" object and are needed whenever the subject
is not centred: standing to one side of a banner, inside a white photo mat, a cutout on a
wide graphic, or a head near the top edge.

  {"crop": {"zoom": 2.6, "anchor_x": 0.30, "anchor_y": 0.62}}

⚠ `bbox` is opt-in per person and is NOT hair/skin detection. The standing rule is that
pixel-based auto-cropping must not silently alter an image — it misreads grey and white
studio backgrounds and over-crops. This finds ink on an obvious white field, and every
result is looked at on the proof sheet before it ships.
"""
import io
import json
import os
import sys

import requests
from PIL import Image, ImageChops, ImageDraw

TARGET = (600, 750)
RATIO = TARGET[0] / TARGET[1]          # 0.8
UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}


def flatten(im):
    """Alpha onto WHITE. convert('RGB') alone turns transparent pixels BLACK."""
    if im.mode in ("RGBA", "LA", "P"):
        im = im.convert("RGBA")
        bg = Image.new("RGBA", im.size, (255, 255, 255, 255))
        im = Image.alpha_composite(bg, im)
    return im.convert("RGB")


def subject_bbox(im, tol=18):
    """Bounding box of everything that is not near-white. None if the whole frame is ink."""
    bg = Image.new("RGB", im.size, (255, 255, 255))
    diff = ImageChops.difference(im, bg).convert("L").point(lambda p: 255 if p > tol else 0)
    return diff.getbbox()


def crop_4x5(im, anchor_x=0.5, anchor_y=0.5, zoom=1.0, bbox=False, pad=0.22):
    im = flatten(im)

    if bbox:
        b = subject_bbox(im)
        if b:
            x0, y0, x1, y1 = b
            w, h = x1 - x0, y1 - y0
            px, py = int(w * pad), int(h * pad)
            x0, y0 = max(0, x0 - px), max(0, y0 - py)
            x1, y1 = min(im.size[0], x1 + px), min(im.size[1], y1 + py)
            im = im.crop((x0, y0, x1, y1))

    if zoom > 1.0:
        w, h = im.size
        nw, nh = int(w / zoom), int(h / zoom)
        left = int((w - nw) * anchor_x)
        top = int((h - nh) * anchor_y)
        im = im.crop((left, top, left + nw, top + nh))
        anchor_x = anchor_y = 0.5          # zoom already applied the anchor

    w, h = im.size
    if w / h > RATIO:                      # too wide: full height, choose columns
        nw = int(round(h * RATIO))
        left = int(round((w - nw) * anchor_x))
        box = (left, 0, left + nw, h)
    else:                                  # too tall: full width, choose the band
        nh = int(round(w / RATIO))
        top = int(round((h - nh) * anchor_y))
        box = (0, top, w, top + nh)
    kept = (box[2] - box[0], box[3] - box[1])
    # 🔴 RETURN THE CROP AT ITS OWN SIZE. This used to end `.resize(TARGET)`, which made
    # every caller that stores the NATIVE cropped size resample twice: a 185x246 Senate
    # portrait was enlarged to 600x750 and then shrunk back to 185x246, and the stored
    # bytes came out measurably softer than the source. Resizing is the caller's decision
    # because only the caller knows whether it is willing to enlarge.
    return im.crop(box), kept


