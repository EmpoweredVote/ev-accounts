"""KY-5 portrait route sweep.

Reads all 138 Legislator-Profile pages on legislature.ky.gov and records, per SEAT:
  * the heading name and the portrait <img alt="<Name> photo"> the publisher itself asserts
  * the thumbnail src and the "Download Full Resolution Image" href, both AS PUBLISHED
  * a HEAD against the full-res object for status and byte length

Nothing is constructed. The Senate's DistrictNumber is 101-138, not 1-38, and the portrait
filenames follow it -- senate137.jpg is district 37 -- so any URL built from a district number
is wrong for half the chamber. The filenames are POSITIONAL (houseN.jpg), which is the
off-by-one class; the alt text is what ties a file to a person, so it is captured verbatim.

The <img> carries onerror -> /Legislators Full Res Images/Placeholder.png. A placeholder is
not a portrait, so it is detected rather than imported.

requests is refused 403 by this host; urllib with a short UA is accepted. One pass, 0.35s apart.
"""
import json
import re
import time
import urllib.request as ur

UA = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
BASE = 'https://legislature.ky.gov'
PROFILE = BASE + '/Legislators/Pages/Legislator-Profile.aspx?DistrictNumber={}'

IMG_RE = re.compile(r'<img class="leg-img"[^>]*>')
SRC_RE = re.compile(r'src="([^"]+)"')
ALT_RE = re.compile(r'alt="([^"]*)"')
# Attribute order varies between profiles -- some carry id="downloadFullRes" before class,
# some after. An order-sensitive pattern silently missed the link on 2 of 3 control seats,
# which would have under-reported full-res coverage rather than erroring. Match the anchor,
# then pull href out of it.
DL_RE = re.compile(r'<a\b[^>]*\bclass="download"[^>]*>')
H2_RE = re.compile(r'<h2>(.*?)</h2>', re.S)


def get(url, method='GET'):
    req = ur.Request(url, headers=UA, method=method)
    r = ur.urlopen(req, timeout=60)
    return r.status, r.headers, (r.read() if method == 'GET' else b'')


def main():
    rows = []
    for n in list(range(1, 101)) + list(range(101, 139)):
        rec = {'districtNumber': n,
               'chamber': 'House' if n <= 100 else 'Senate',
               'district': n if n <= 100 else n - 100}
        try:
            _, _, body = get(PROFILE.format(n))
            h = body.decode('utf-8', 'replace')
            rec['profileBytes'] = len(body)
            h2 = H2_RE.search(h)
            rec['heading'] = re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', '', h2.group(1))).strip() if h2 else None
            img = IMG_RE.search(h)
            if img:
                src = SRC_RE.search(img.group(0))
                alt = ALT_RE.search(img.group(0))
                rec['thumbSrc'] = src.group(1) if src else None
                rec['alt'] = alt.group(1) if alt else None
            dl = DL_RE.search(h)
            rec['fullResHref'] = (re.search(r'href="([^"]+)"', dl.group(0)).group(1)
                                  if dl else None)
        except Exception as e:
            rec['profileError'] = f'{type(e).__name__}: {e}'
        time.sleep(0.35)

        if rec.get('fullResHref'):
            url = BASE + rec['fullResHref']
            try:
                status, hdrs, _ = get(url, method='HEAD')
                rec['fullResStatus'] = status
                rec['fullResBytes'] = int(hdrs.get('Content-Length') or 0)
                rec['fullResType'] = hdrs.get('Content-Type')
            except Exception as e:
                rec['fullResStatus'] = getattr(e, 'code', 'ERR')
                rec['fullResError'] = f'{type(e).__name__}: {e}'
            time.sleep(0.35)
        rows.append(rec)
        if n % 20 == 0:
            print(f'  ... {n}', flush=True)

    out = {'measured': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()), 'rows': rows}
    with open('ky-portrait-route.json', 'w', encoding='utf-8') as f:
        json.dump(out, f, indent=2)
    print('wrote ky-portrait-route.json', len(rows))


if __name__ == '__main__':
    main()
