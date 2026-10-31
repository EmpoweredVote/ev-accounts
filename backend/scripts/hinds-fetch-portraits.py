import os, sys, time, urllib.request
from PIL import Image
UA = {'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Safari/537.36'}
D = os.path.dirname(os.path.abspath(__file__))
os.makedirs(os.path.join(D,'src'), exist_ok=True)
jobs = []
for line in open(os.path.join(D,'imglist.txt')):
    p = line.split()
    if len(p) == 3: jobs.append(tuple(p))

for attempt in range(12):
    left = []
    for name, ts, url in jobs:
        dest = os.path.join(D,'src',name)
        if os.path.exists(dest) and os.path.getsize(dest) > 3000: continue
        try:
            req = urllib.request.Request(f'https://web.archive.org/web/{ts}im_/{url}', headers=UA)
            with urllib.request.urlopen(req, timeout=60) as r:
                d = r.read()
            if len(d) > 3000:
                open(dest,'wb').write(d)
                im = Image.open(dest)
                print(f'IMG {name:22} {im.size[0]}x{im.size[1]} {im.mode} {len(d)}b')
            else:
                left.append(name); print(f'   pass{attempt+1} {name} short {len(d)}b')
        except Exception as e:
            left.append(name); print(f'   pass{attempt+1} {name} {type(e).__name__}')
        sys.stdout.flush()
        time.sleep(45)
    print(f'--- pass {attempt+1}: {len(left)} missing ---'); sys.stdout.flush()
    if not left: break
    time.sleep(120)
print('IMAGES DONE')
