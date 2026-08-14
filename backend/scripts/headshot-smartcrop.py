"""
Subject-aware 4:5 headshot crop — reusable across city/county deep seeds.

    from headshot_smartcrop import process
    final, how = process(Image.open(src))   # -> 600x750, plus a crop note
    final.save(dst, 'JPEG', quality=90)

Use this instead of a centred crop whenever source portraits are letterboxed into
a wide frame — county and city sites very often publish a studio headshot padded
out to a 1600x700 "banner", and the subject is rarely centred in it.

Why this exists: during the Seattle/King County seed a centred crop was validated
on ONE image (Dembowski, who happens to be centred) and then applied to all 14.
Most of the county's 1600x700 studio shots place the subject well off-centre, so a
centred 560-wide window sliced faces off at the edge. Corrected offsets ranged
x@299..x@863.

TWO RULES this encodes, both learned the hard way:
  * Crop THEN resize. Never resize first — it distorts faces.
  * Never select or crop a headshot without LOOKING at the result. Aspect ratio
    being correct does not mean the framing is. Render every output and inspect it
    before import; a source that is not actually a portrait (a wide shot of someone
    at a dais, a distant standing photo) passes every numeric check and still looks
    wrong.

Approach: the studio backgrounds are smooth and the subject carries the detail, so
column-wise variance locates the subject reliably without a face detector. We take
the variance profile across columns, find its centre of mass, and centre the crop
window there — clamped to the image bounds.

Vertically we bias upward (a third of the excess off the top) so hair stays in and
the eyes sit nearer the upper third.

NOTHING here is trusted blind: every output is rendered to a review sheet and
eyeballed before import.
"""
from PIL import Image, ImageFilter
import numpy as np

TARGET = 4 / 5


def subject_center_x(img):
    """Return the x centre of the subject, as a fraction 0..1 of width."""
    g = img.convert('L').filter(ImageFilter.GaussianBlur(2))
    a = np.asarray(g, dtype=np.float32)
    # Column detail = vertical gradient energy; smooth backdrops score near zero.
    grad = np.abs(np.diff(a, axis=0)).sum(axis=0)
    if grad.sum() <= 0:
        return 0.5
    # Suppress the weakest 40% so a gradient backdrop cannot drag the centroid.
    thresh = np.percentile(grad, 40)
    w = np.clip(grad - thresh, 0, None)
    if w.sum() <= 0:
        return 0.5
    xs = np.arange(len(w), dtype=np.float32)
    return float((xs * w).sum() / w.sum() / len(w))


def crop_45(img, upward_bias=3):
    """Crop to 4:5 around the subject, then the caller resizes. Never distorts."""
    w, h = img.size
    if w / h > TARGET:
        nw = int(round(h * TARGET))
        cx = subject_center_x(img) * w
        left = int(round(cx - nw / 2))
        left = max(0, min(left, w - nw))          # clamp inside the image
        return img.crop((left, 0, left + nw, h)), f'x@{left}'
    nh = int(round(w / TARGET))
    if nh > h:                                     # already narrower than 4:5
        nw = int(round(h * TARGET))
        cx = subject_center_x(img) * w
        left = max(0, min(int(round(cx - nw / 2)), w - nw))
        return img.crop((left, 0, left + nw, h)), f'x@{left}'
    top = (h - nh) // upward_bias
    return img.crop((0, top, w, top + nh)), f'y@{top}'


def process(img):
    cropped, how = crop_45(img)
    return cropped.resize((600, 750), Image.LANCZOS), how
