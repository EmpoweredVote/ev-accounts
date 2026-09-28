#!/usr/bin/env python3
"""
Repair the Harrison County Sheriff's published portrait.

HCSO publishes Matt Haley only as a cut-out standing inside a gold ring on a transparent
background. Flattening that gives a portrait with a gold annulus behind the shoulders.

The ring is removed by COLOUR PLUS CONNECTEDNESS, not colour alone: his badge, collar stars and
buttons are the same gold, so a global hue replacement would eat them. The ring is one large
connected region; the insignia are small and separate. Keep the largest component only.

CONTROLS
  1. The insignia must SURVIVE. Gold pixels inside the torso are counted before and after; if
     that count collapses, the mask has eaten the badge and the result is rejected.
  2. The ring must actually GO. Gold pixels outside the torso are counted before and after.
  A repair that changes neither number is a no-op dressed as a fix.
"""
import numpy as np
from PIL import Image
from scipy import ndimage

SRC = 'data/seed-ms-2026/_assets/harrison/sheriff-circle-orig.png'
OUTDIR = 'data/seed-ms-2026/_assets/recrop'

im = Image.open(SRC).convert('RGBA')
a = np.array(im)
rgb = a[..., :3].astype(np.int16)
alpha = a[..., 3]
H, W = alpha.shape
print(f'source {W}x{H}, opaque pixels {int((alpha > 0).sum()):,}')

R, G, B = rgb[..., 0], rgb[..., 1], rgb[..., 2]
gold = (R > 150) & (G > 110) & (B < 130) & ((R - B) > 70) & ((G - B) > 45) & (alpha > 0)
print(f'gold-coloured pixels: {int(gold.sum()):,}')

lbl, n = ndimage.label(gold)
sizes = ndimage.sum(gold, lbl, range(1, n + 1))
biggest = int(np.argmax(sizes)) + 1
ring = lbl == biggest
print(f'{n} gold components; largest = {int(sizes.max()):,} px '
      f'({100 * sizes.max() / max(1, gold.sum()):.1f}% of all gold) -> taken as the ring')

# The torso region: the central column band, where the badge and buttons are.
cx0, cx1 = int(W * 0.30), int(W * 0.70)
torso = np.zeros_like(gold)
torso[:, cx0:cx1] = True
gold_in_torso_before = int((gold & torso).sum())
gold_out_torso_before = int((gold & ~torso).sum())

# Grow the ring mask slightly to catch its antialiased edge.
ring_d = ndimage.binary_dilation(ring, iterations=2)

out = a.copy()
out[..., :3][ring_d] = 255
out[..., 3][ring_d] = 255           # opaque white where the ring was
flat = np.dstack([
    (out[..., :3] * (out[..., 3:4] / 255.0) + 255 * (1 - out[..., 3:4] / 255.0)).astype(np.uint8)
])
res = Image.fromarray(flat, 'RGB')

arr2 = np.array(res).astype(np.int16)
R2, G2, B2 = arr2[..., 0], arr2[..., 1], arr2[..., 2]
gold2 = (R2 > 150) & (G2 > 110) & (B2 < 130) & ((R2 - B2) > 70) & ((G2 - B2) > 45)
gold_in_torso_after = int((gold2 & torso).sum())
gold_out_torso_after = int((gold2 & ~torso).sum())

print(f'\nCONTROL 1  insignia (gold inside torso): {gold_in_torso_before:,} -> {gold_in_torso_after:,}'
      f'   {"KEPT" if gold_in_torso_after > gold_in_torso_before * 0.5 else "DESTROYED -- reject"}')
print(f'CONTROL 2  ring (gold outside torso):    {gold_out_torso_before:,} -> {gold_out_torso_after:,}'
      f'   {"REMOVED" if gold_out_torso_after < gold_out_torso_before * 0.15 else "STILL THERE -- no-op"}')

# Crop in on Matt: the opaque silhouette minus the ring is the subject.
subject = (alpha > 0) & ~ring_d
ys, xs = np.where(subject)
y0, y1, x0, x1 = ys.min(), ys.max(), xs.min(), xs.max()
print(f'\nsubject bounding box: x {x0}-{x1}, y {y0}-{y1}  ({x1-x0}x{y1-y0})')

sh = y1 - y0
head = 0.06
ch = min(H, sh * (1 + head))
cw = ch * 0.8
cx = (x0 + x1) / 2
left = max(0, min(W - cw, cx - cw / 2))
top = max(0, min(H - ch, y0 - sh * head))
box = (int(left), int(top), int(left + cw), int(top + ch))
final = res.crop(box).resize((600, 750), Image.LANCZOS)
final.save(f'{OUTDIR}/sheriff-repaired.jpg', 'JPEG', quality=90)
print(f'crop {box} -> 600x750, effective width {box[2]-box[0]}px, '
      f'{"downscale" if box[2]-box[0] >= 600 else "UPSCALE"} {600/(box[2]-box[0]):.2f}x')

# before/after
before = res.copy()
b2 = im.convert('RGB')
sheet = Image.new('RGB', (600 * 2 + 30, 750 + 20), (245, 243, 238))
tmp = b2.copy(); tmp.thumbnail((600, 750), Image.LANCZOS)
sheet.paste(tmp, (10 + (600 - tmp.width) // 2, 10))
sheet.paste(final, (620, 10))
sheet.save(f'{OUTDIR}/sheriff-compare.png')
print('wrote', f'{OUTDIR}/sheriff-compare.png', '(left = as published, right = repaired crop)')
