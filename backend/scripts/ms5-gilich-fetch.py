import io, urllib.request
from PIL import Image
UA={'User-Agent':'EmpoweredVote-asset-probe/1.0 (chris@empowered.vote)'}
cands=[('a2017','https://biloxi.ms.us/wp-content/uploads/2017/08/MayorAndrewFoFoGilich1.png'),
       ('b2015','https://biloxi.ms.us/wp-content/uploads/2015/05/MayorFoFoGilich.jpg')]
ims=[]
for slug,u in cands:
    d=urllib.request.urlopen(urllib.request.Request(u,headers=UA)).read()
    im=Image.open(io.BytesIO(d)).convert('RGB')
    print(slug, im.size, len(d),'bytes')
    open(f'data/seed-ms-2026/_assets/biloxi/gilich-{slug}.jpg','wb').write(d) if u.endswith('.jpg') else im.save(f'data/seed-ms-2026/_assets/biloxi/gilich-{slug}.png')
    ims.append((slug,im))
W,H=360,600
sheet=Image.new('RGB',(W*len(ims)+30,H+30),(245,245,245))
for i,(slug,im) in enumerate(ims):
    c=im.copy(); c.thumbnail((W,H), Image.LANCZOS); sheet.paste(c,(15+i*W,15))
sheet.save('data/seed-ms-2026/_assets/gilich-compare.png'); print('sheet', sheet.size)
