"""
Compose a 1700x540 banner from a source photograph, and report what each breakpoint actually shows.

🔴 CROPPING DEPENDS ONLY ON THE BOX ASPECT, NEVER ON ITS SIZE. SectionBanner renders 13/4 on mobile
and 6/1 from `md` up, so ONE asset is seen two ways: the phone keeps 96.9% of the height, the desktop
keeps the middle 52.5%. Bend, Oregon shipped broken because it was certified on the full frame with
its subject in the upper third — rows outside the desktop slice — and reviewed fine on a phone.

So this prints the DESKTOP BAND in source pixels, and the previews it writes are the two real boxes.
"""
import sys
from PIL import Image

W, H = 1700, 540
DESKTOP_KEEP = 0.525          # 6/1 box over a 3.148:1 asset
MOBILE_KEEP = 0.969           # 13/4 box

def compose(src_path, out_path, anchor_y=0.5, anchor_x=0.5, zoom=1.0):
    im = Image.open(src_path)
    im.load()
    im = im.convert("RGB")
    if zoom > 1.0:
        w, h = im.size
        nw, nh = int(w / zoom), int(h / zoom)
        im = im.crop((int((w - nw) * anchor_x), int((h - nh) * anchor_y),
                      int((w - nw) * anchor_x) + nw, int((h - nh) * anchor_y) + nh))
    w, h = im.size
    target = W / H
    if w / h > target:                      # too wide: keep full height, choose columns
        nw = int(round(h * target))
        left = int(round((w - nw) * anchor_x))
        im = im.crop((left, 0, left + nw, h))
    else:                                   # too tall: keep full width, choose rows
        nh = int(round(w / target))
        top = int(round((h - nh) * anchor_y))
        im = im.crop((0, top, w, top + nh))
    im = im.resize((W, H), Image.LANCZOS)
    im.save(out_path, "JPEG", quality=90, progressive=True, optimize=True)
    d0 = int(H * (1 - DESKTOP_KEEP) / 2)
    m0 = int(H * (1 - MOBILE_KEEP) / 2)
    return {"out": out_path, "desktop_band": (d0, H - d0), "mobile_band": (m0, H - m0)}

if __name__ == "__main__":
    src, out = sys.argv[1], sys.argv[2]
    kw = {k: float(v) for k, v in (a.split("=") for a in sys.argv[3:])}
    r = compose(src, out, **kw)
    print(f"{r['out']}  desktop shows rows {r['desktop_band'][0]}-{r['desktop_band'][1]} of 540, "
          f"mobile {r['mobile_band'][0]}-{r['mobile_band'][1]}")
