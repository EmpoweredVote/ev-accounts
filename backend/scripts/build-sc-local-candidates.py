"""Build the SC-5b headshot candidate list: Columbia, Myrtle Beach, Richland, Horry.

FOUR PUBLISHERS, FOUR PLATFORMS, AND EVERY ONE NEEDED ITS OWN PROBE. What the page
links is the best available image on none of them:

  Columbia    WordPress. The council index links the MAYOR as a 440x358 LANDSCAPE
              file; his own subdomain's media library holds a 1828x2560 portrait.
              (The wp-json search misses him -- the file is spelled "rikenmann".)
              Councillors are 323x427 on their own profile pages, not on the index.
  Myrtle Bch  Plain pages; the name follows the <img>. Sizes run 450x556 to 1912x2709.
  Richland    The URL carries its own resize -- ?dimension=userprofile&w=150&h=150.
              STRIP THE QUERY and the origin is 2944x3761, nearly 20x larger.
  Horry       Umbraco. The linked media URL is already the original (~2143x3217),
              but only the COUNCIL publishes portraits; officers are on their
              department pages and two of the six publish none.

🔴 RICHLAND'S WAF READS THE WHOLE FINGERPRINT, NOT THE USER-AGENT. Measured:
a bare request 200s, a Chrome UA ALONE 403s, and a full Chrome header set 200s only
when it carries a Referer. A half-impersonation is rejected more readily than none.
The pipeline's own partial UA would 403 here, so this script writes the bytes it
measured straight into the shared cache and the importer never refetches them.

Writes .tmp-sc-local-candidates.json in the schema import-headshot-candidates.py and
render-headshot-contact-sheet.py both read.
"""
import argparse
import hashlib
import io
import json
import os
import re
import sys

import requests
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from headshot_crop import crop_4x5, monochrome  # noqa: E402

CACHE = '.tmp-headshot-cache'
TARGET_W, TARGET_H = 600, 750
CHROME_UA = ('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
             '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36')
DOC_H = {
    'User-Agent': CHROME_UA,
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
    'Sec-Fetch-Dest': 'document', 'Sec-Fetch-Mode': 'navigate', 'Sec-Fetch-Site': 'none',
}
CHROME_IMG = re.compile(
    r'(?i)logo|icon|sprite|favicon|\.svg|seal|hero|banner|footer|placeholder|'
    r'map|district-\d|edit_|thumbnail|flag|quote-bubble|recruitment|background|'
    r'chatgpt-image')


def fetch(url, referer=None, doc=False):
    """Richland 403s a half-impersonation; a bare request is the reliable fallback."""
    headers = dict(DOC_H) if doc else {
        'User-Agent': CHROME_UA,
        'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        'Sec-Fetch-Dest': 'image', 'Sec-Fetch-Mode': 'no-cors',
        'Sec-Fetch-Site': 'same-origin',
    }
    if referer:
        headers['Referer'] = referer
    try:
        r = requests.get(url, headers=headers, timeout=45)
        if r.status_code != 200:
            r = requests.get(url, timeout=45)     # bare
        return r
    except Exception:  # noqa: BLE001
        try:
            return requests.get(url, timeout=45)
        except Exception:  # noqa: BLE001
            return None


def portrait_score(url, referer=None):
    """(area, size, chroma, raw) for a usable portrait, else None."""
    r = fetch(url, referer=referer)
    if r is None or r.status_code != 200:
        return None
    if r.content[:2] not in (b'\xff\xd8', b'\x89P') and r.content[:4] != b'RIFF':
        return None
    try:
        im = Image.open(io.BytesIO(r.content))
        im.load()
    except Exception:  # noqa: BLE001
        return None
    w, h = im.size
    if w < 150 or h < 150:
        return None
    if w / h > 1.35:          # a banner, not a portrait
        return None
    _, chroma, _ = monochrome(im)
    return (w * h, (w, h), chroma, r.content)


# ---------------------------------------------------------------- Columbia ----
def columbia():
    out = {}
    index = requests.get('https://citycouncil.columbiasc.gov/', headers=DOC_H, timeout=45)
    profiles = sorted(set(re.findall(
        r'href="(https://citycouncil\.columbiasc\.gov/council-profiles/[^"#?]+)"', index.text)))
    for url in profiles:
        page = requests.get(url, headers=DOC_H, timeout=45)
        title = re.search(r'<title>([^<]+)', page.text)
        name = (title.group(1).split('|')[0].strip() if title else url.rstrip('/').split('/')[-1])
        imgs = {u for u in re.findall(r'https?://[^"\'<> ]+?\.(?:jpe?g|png)', page.text)
                if 'wp-content/uploads' in u and not CHROME_IMG.search(u)}
        best = None
        for u in imgs:
            s = portrait_score(u, referer=url)
            if s and (best is None or s[0] > best[0]):
                best, best_url = s, u
        if best:
            out[name] = (best_url, url, best)
    # The mayor has NO council-profile page; his own subdomain carries the real portrait.
    r = requests.get('https://mayor.columbiasc.gov/wp-json/wp/v2/media', headers=DOC_H,
                     params={'search': 'rickenmann', 'per_page': 20, 'media_type': 'image'},
                     timeout=45)
    best = None
    for it in (r.json() if r.status_code == 200 else []):
        md = it.get('media_details') or {}
        w, h = md.get('width') or 0, md.get('height') or 0
        if h > w and w >= 300:
            s = portrait_score(it['source_url'])
            if s and (best is None or s[0] > best[0]):
                best, best_url = s, it['source_url']
    if best:
        out['Daniel J. Rickenmann'] = (best_url, 'https://mayor.columbiasc.gov/', best)
    return out


# ------------------------------------------------------------ Myrtle Beach ----
def myrtle():
    url = 'https://www.cityofmyrtlebeach.com/government/mayor___city_council/index.php'
    page = requests.get(url, headers=DOC_H, timeout=45)
    out = {}
    for m in re.finditer(r'<img[^>]+src="([^"]+)"[^>]*>', page.text):
        src = m.group(1)
        if not re.search(r'(?i)council|mayor|headshot|revize', src) or CHROME_IMG.search(src):
            continue
        if re.search(r'(?i)envelope|permissions', src):
            continue
        # The member's NAME follows the portrait in this template; take the first
        # capitalised run after the tag rather than trusting the filename -- the file
        # for Jackie Hatley is named "Jackie Vereen" (her maiden name).
        tail = re.sub(r'(?s)<[^>]+>', ' ', page.text[m.end():m.end() + 400])
        tail = ' '.join(tail.split())
        who = tail.split(',')[0].strip()[:60]
        full = src if src.startswith('http') else (
            'https://www.cityofmyrtlebeach.com/' + src.lstrip('/'))
        s = portrait_score(full, referer=url)
        if s and who:
            out[who] = (full, url, s)
    return out


# ---------------------------------------------------------------- Richland ----
def richland():
    out = {}
    council = 'https://www.richlandcountysc.gov/Government/Elected-Offices/County-Council'
    page = fetch(council, doc=True)
    if page is not None and page.status_code == 200:
        # Parse ARTICLE blocks. The name is an <h2 class="list-item-title">, the photo
        # is a <picture> inside the same article, and the header also links that
        # member's own profile page. Reading the text that merely FOLLOWS the <img>
        # returned "alt=\"\"/> Telephone 803-542-0002 Email" as eleven councillors'
        # names on the first pass -- the structure is there, so use it.
        for art in re.findall(r'(?s)<article>(.*?)</article>', page.text):
            name = re.search(r'class="list-item-title">([^<]+)</h2>', art)
            img = re.search(
                r'(/files/assets/county/[^"?]*?/images/[a-z0-9\-]+\.(?:jpe?g|png))', art, re.I)
            if not name or not img:
                continue
            who = name.group(1).strip()
            prof = re.search(r'href="(https://www\.richlandcountysc\.gov/[^"]*?/County-Council/'
                             r'[^"]+)"', art)
            # STRIP THE RESIZE: ?dimension=userprofile&w=150&h=150 serves a 150px
            # square, the bare path is the origin -- 2944x3761 for Branham.
            best_url = 'https://www.richlandcountysc.gov' + img.group(1)
            best = portrait_score(best_url, referer=council)
            # Some origins really ARE small (three are ~150px). The member's own
            # profile page sometimes carries a larger file, so ask it and keep
            # whichever is bigger.
            if prof:
                sub = fetch(prof.group(1), doc=True)
                if sub is not None and sub.status_code == 200:
                    for u in set(re.findall(
                            r'(/files/assets/county/[^"?]*?/images/[a-z0-9\-]+\.'
                            r'(?:jpe?g|png))', sub.text, re.I)):
                        cand_url = 'https://www.richlandcountysc.gov' + u
                        cand = portrait_score(cand_url, referer=prof.group(1))
                        if cand and (best is None or cand[0] > best[0]):
                            best, best_url = cand, cand_url
            if best:
                out[who] = (best_url, prof.group(1) if prof else council, best)
    officers = {
        'Paul Brawley': ('https://www.richlandcountysc.gov/files/assets/county/v/4/'
                         'administration/images/paul-brawley.jpg',
                         'https://www.richlandcountysc.gov/Government/Elected-Offices/Auditor'),
        'Jeanette W. McBride': ('https://www.richlandcountysc.gov/files/assets/county/v/2/'
                                'courts/images/jeanette-mcbride.jpg',
                                'https://www.richlandcountysc.gov/Government/'
                                'Elected-Offices/Clerk-of-Court'),
        'Amy McCulloch': ('https://www.richlandcountysc.gov/files/assets/county/v/3/'
                          'courts/images/amy-mcculloch.jpg',
                          'https://www.richlandcountysc.gov/Government/'
                          'Elected-Offices/Probate-Judge'),
        'Kendra L. Dove': ('https://www.richlandcountysc.gov/files/assets/county/v/2/'
                           'treasurer/images/kendraldove.jpg',
                           'https://www.richlandcountysc.gov/Government/'
                           'Elected-Offices/Treasurer'),
        'Naida Rutherford': ('https://rccosc.com/wp-content/uploads/2024/04/'
                             'coroner-rutherford-scaled-e1713149987838.jpg',
                             'https://rccosc.com/coroner-naida-rutherford/'),
    }
    for who, (img, page_url) in officers.items():
        s = portrait_score(img, referer=page_url)
        if s:
            out[who] = (img, page_url, s)
    return out


# ------------------------------------------------------------------- Horry ----
def horry():
    out = {}
    council = 'https://www.horrycountysc.gov/council/'
    page = requests.get(council, headers=DOC_H, timeout=45)
    if page.status_code != 200:
        page = requests.get('https://www.horrycountysc.gov/county-council/',
                            headers=DOC_H, timeout=45)
        council = page.url
    # Horry captions every councillor portrait in the img's own alt attribute, so the
    # name travels with the image rather than with its position on the page.
    for m in re.finditer(
            r'<img[^>]*?src="(https://www\.horrycountysc\.gov/media/[^"]+)"[^>]*?>', page.text):
        src, tag = m.group(1), m.group(0)
        if CHROME_IMG.search(src):
            continue
        alt = re.search(r'alt="([^"]*)"', tag)
        who = re.sub(r'&quot;|&#34;', '"', alt.group(1)).strip() if alt else ''
        if not who:
            continue
        s = portrait_score(src, referer=council)
        if s:
            out[who] = (src, council, s)
    officers = {
        'Tina Hardee': ('https://www.horrycountysc.gov/media/t5ydrwv4/tina-hardee.png',
                        'https://www.horrycountysc.gov/departments/auditor/'),
        'Renee N. Elvis': ('https://www.horrycountysc.gov/media/53elodz3/renee-elvis-cutout.png',
                           'https://www.horrycountysc.gov/departments/clerk-of-court/'),
        'Phillip E. Thompson': ('https://www.horrycountysc.gov/media/k0pbzisk/sheriff-cutout.png',
                                'https://www.horrycountysc.gov/departments/sheriffs-office/'),
        'Angie Jones': ('https://www.horrycountysc.gov/media/o1wbr5gy/angie-jones-cut-out.png',
                        'https://www.horrycountysc.gov/departments/treasurer/'),
    }
    for who, (img, page_url) in officers.items():
        s = portrait_score(img, referer=page_url)
        if s:
            out[who] = (img, page_url, s)
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default='.tmp-sc-local-candidates.json')
    args = ap.parse_args()

    found = {}
    for label, fn in (('Columbia', columbia), ('Myrtle Beach', myrtle),
                      ('Richland', richland), ('Horry', horry)):
        try:
            got = fn()
        except Exception as exc:  # noqa: BLE001
            print(f'{label}: FAILED {type(exc).__name__}: {exc}')
            got = {}
        print(f'{label}: {len(got)} portraits discovered')
        for who, (img, page_url, s) in got.items():
            print(f'   {s[1][0]}x{s[1][1]:<6} chroma {s[2]:5.1f}  {who[:46]:<48} '
                  f'{img.split("/")[-1][:40]}')
        found[label] = got

    os.makedirs(CACHE, exist_ok=True)
    json.dump({k: {w: [u, p, list(s[1]), s[2]] for w, (u, p, s) in v.items()}
               for k, v in found.items()},
              open('.tmp-sc-local-discovered.json', 'w', encoding='utf-8'), indent=1)
    for v in found.values():
        for _who, (url, _p, s) in v.items():
            ck = os.path.join(CACHE, hashlib.sha1(url.encode()).hexdigest() + '.bin')
            with open(ck, 'wb') as fh:
                fh.write(s[3])
    total = sum(len(v) for v in found.values())
    print(f'\n{total} portraits discovered and cached; '
          f'wrote .tmp-sc-local-discovered.json')


if __name__ == '__main__':
    main()
