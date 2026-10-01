#!/usr/bin/env python3
"""
Process the 8 Biloxi portraits to the find-headshots convention: 4:5 crop, 600x750, JPEG q90.

The 7 council originals are 2048x2560, which is EXACTLY 4:5 -- so they are a pure resize with
no crop decision at all. Only the mayor needs a crop, and his source is a 1737x2889 portrait
whose subject sits high in the frame, so the centred auto-crop is rendered and LOOKED AT rather
than trusted.
"""
from PIL import Image
import os, json

SRC = 'data/seed-ms-2026/_assets/biloxi'
OUT = 'data/seed-ms-2026/_assets/biloxi-processed'
os.makedirs(OUT, exist_ok=True)

PEOPLE = [
 ('ward1','c4e9f036-a730-4e17-b19f-67bc4cf0685d','Wayne Gray','Council Member, Ward 1','ward1.jpg'),
 ('ward2','43800326-0f41-4ddb-987a-1a50e3cfb0c4','Anthony Marshall','Council Member, Ward 2','ward2.jpg'),
 ('ward3','9b44113d-0130-4f44-b0be-370e331bf6b0','Robert Nail','Council Member, Ward 3','ward3.jpg'),
 ('ward4','d17836ed-3c05-4868-8974-85b3cdc3bdef','Jamie Creel','Council Member, Ward 4','ward4.jpg'),
 ('ward5','7217df2d-57d6-4c8e-9578-e9dff718cdd3','Paul Tisdale','Council Member, Ward 5','ward5.jpg'),
 ('ward6','52930985-bb79-4c7b-b1fe-775fd85e983b','Kenny Glavan','Council Member, Ward 6','ward6.jpg'),
 ('ward7','c8e9d222-4ce0-49ec-9d9a-c4ab48f090da','David Shoemaker','Council Member, Ward 7','ward7.jpg'),
 ('mayor','5cb4aeb2-f692-41e7-8bee-4fbe687230ac','Andrew Gilich','Mayor','gilich-a2017.png'),
]

def to_spec(img):
    w, h = img.size
    tr = 4/5
    if w/h > tr:
        nw = int(h*tr); left = (w-nw)//2
        img = img.crop((left, 0, left+nw, h)); mode = f'crop W {w}->{nw}'
    else:
        nh = int(w/tr); top = (h-nh)//2
        img = img.crop((0, top, w, top+nh)); mode = f'crop H {h}->{nh} from y={top}'
    return img.resize((600,750), Image.LANCZOS), mode

rows = []
for slug, pid, name, title, fn in PEOPLE:
    src = Image.open(os.path.join(SRC, fn)).convert('RGB')
    w, h = src.size
    out, mode = to_spec(src)
    dest = os.path.join(OUT, f'{pid}-headshot.jpg')
    out.save(dest, 'JPEG', quality=90)
    up = 600/min(w, int(h*4/5)) if w else 0
    factor = 600/ (w if w/h > 4/5 else w)
    print(f'{slug:<7} {name:<18} src {w}x{h}  {mode:<28} -> 600x750  scale {600/w:.2f}x'
          + ('  [UPSCALED]' if w < 600 else ''))
    rows.append({'slug':slug,'politician_id':pid,'name':name,'title':title,
                 'src_file':fn,'src_w':w,'src_h':h,'mode':mode,
                 'out':f'{pid}-headshot.jpg','upscaled': w < 600})
json.dump(rows, open('data/seed-ms-2026/_assets/biloxi-processed.json','w'), indent=2)
print('\nnone upscaled' if not any(r['upscaled'] for r in rows) else 'SOME UPSCALED')
