#!/usr/bin/env python3
"""Process the Harrison County portraits to 4:5 / 600x750 / q90, flattening alpha on white."""
from PIL import Image
import os, json
SRC='data/seed-ms-2026/_assets/harrison'
OUT='data/seed-ms-2026/_assets/harrison-processed'
os.makedirs(OUT, exist_ok=True)

PEOPLE=[
 ('d1','9900867f-9721-4da3-87eb-0e06886b82ba','Dan Cuevas','Supervisor, District 1','d1.jpg'),
 ('d2','699afdf5-18f8-4ad7-92d6-04b466fcd8fa','Rebecca Powers','Supervisor, District 2','d2.jpg'),
 ('d3','e304bc6f-805e-405c-8af8-f98df3bd79ee','Marlin Ladner','Supervisor, District 3','d3.jpg'),
 ('d4','01cc7a9d-f427-49c2-ba90-928163a4eaad','Kent Jones','Supervisor, District 4','d4.jpg'),
 ('d5','81877664-281c-44c5-b9b2-4f7d6f2f00f7','Nathan Barrett','Supervisor, District 5','d5.jpg'),
 ('circuit','5dc02160-d488-455b-8c2b-7084c7cca2ff','Justin Wetzel','Circuit Clerk','circuit.jpg'),
 ('assessor','234c3d33-38f4-4a0d-a682-1fd0b7cb7b52','Paula Ladner','Tax Assessor','assessor.jpg'),
 ('collector','fe783b4b-b409-4223-8a7e-0a72ef0c3b6c','Sharon Barnett','Tax Collector','collector.jpg'),
 ('sheriff','82189594-b059-458a-b56d-b044ee7bd8d4','Matt Haley','Sheriff','sheriff-circle-orig.png'),
 ('chancery','23f20063-8eeb-49b6-b950-70b4b879965c','Angela Thrash','Chancery Clerk','chancery-thrash.jpg'),
]

def load(p):
    im=Image.open(p)
    if im.mode in ('RGBA','LA','P'):
        im=im.convert('RGBA')
        bg=Image.new('RGB',im.size,(255,255,255)); bg.paste(im,mask=im.split()[-1]); return bg
    return im.convert('RGB')

def to_spec(img):
    w,h=img.size; tr=4/5
    if w/h>tr:
        nw=int(h*tr); left=(w-nw)//2; img=img.crop((left,0,left+nw,h)); m=f'crop W {w}->{nw}'
    else:
        nh=int(w/tr); top=(h-nh)//2; img=img.crop((0,top,w,top+nh)); m=f'crop H {h}->{nh} @y{top}'
    return img.resize((600,750), Image.LANCZOS), m

rows=[]
for slug,pid,name,title,fn in PEOPLE:
    src=load(os.path.join(SRC,fn)); w,h=src.size
    out,mode=to_spec(src)
    out.save(os.path.join(OUT,f'{pid}-headshot.jpg'),'JPEG',quality=90)
    up = 600/w
    flag = f'UPSCALED {up:.2f}x' if w<600 else ''
    print(f'{slug:<10}{name:<17} src {w}x{h:<6} {mode:<22} -> 600x750  {flag}')
    rows.append({'slug':slug,'politician_id':pid,'name':name,'title':title,'src':fn,
                 'src_w':w,'src_h':h,'mode':mode,'upscale':round(up,2) if w<600 else None})
json.dump(rows,open('data/seed-ms-2026/_assets/harrison-processed.json','w'),indent=2)
n=sum(1 for r in rows if r['upscale'])
print(f'\n{len(rows)} processed, {n} upscaled')
