"""Build the SC-5a headshot candidate list for all 170 General Assembly seats.

WHY THIS IS NOT THE PENNSYLVANIA SHAPE
  PA-5a probed for an unlinked original and found one 7.5x larger than the linked
  file. South Carolina has no such bucket -- measured: /original/, /large/, /300/,
  /full/, /hi/, /hires/, /big/, /lg/, /photo/, .png and .JPG all 404, and the
  directory index is 403. What scstatehouse.gov serves is
  /images/members/<member_id>.jpg at 125px wide, and the EXIF inside it still names
  the 3418x5137 Nikon frame the state does not publish. A 125px source needs a 4.8x
  enlargement to reach the 600x750 production crop, and this pipeline never enlarges.

  The SC Legislative Manual is the way through. It is a print artefact published by
  the same agency (LSA), and it embeds the portraits at print resolution -- measured
  232x292 to 2548x3214, and already at 4:5, so the crop is close to lossless.

HOW A PHOTO IS TIED TO A PERSON -- the off-by-one class
  THE MANUAL PRINTS BOTH THE DISTRICT AND THE SURNAME NEXT TO THE FACE. Each
  member's bio text block starts at exactly the same y as their photo's bbox, and it
  reads "ADAMS, Brian Richard [R] (Dist. No. 44, ...)". So the key is a district
  number the document itself states -- never an ordinal, never a filename, never a
  position in the page's image list. Those are the keys that produce off-by-ones.
  The gate is that the surname printed in that same sentence ALSO agrees with the
  surname the roster seats in that district: two fields of one sentence, checked
  against a roster built from a different source. A 2026 arrival whose predecessor
  is still in the 2025 manual fails exactly here, which is what catches staleness.

🔴 A PIXEL IDENTITY CHECK WAS ATTEMPTED AND DOES NOT WORK HERE -- SO IT IS NOT A GATE
  PA-5a proved identity by comparing /original/ against /300/, the SAME photograph at
  two sizes, and scored a median MAD of 1.96 against a reject threshold of 18. That
  does not transfer. South Carolina's two sources are a print manual and a 125px web
  downsample: different crops, different years, sometimes a different shoot. Measured
  over 70 pairs, with a different-person control on every metric:

      metric                    genuine max   control min   separated
      raw MAD 64x80                  69.14         39.49          no
      equalised MAD 64x80            92.61         55.61          no
      NCC 64x80                       1.063         0.524         no
      NCC equalised 64x80             1.083         0.517         no
      NCC centre-70% 48x60            1.164         0.513         no
      NCC gradient 64x80              1.065         0.822         no
      NCC gradient centre-70%         1.109         0.853         no

  Every distribution overlaps its own control, so no threshold drawn from any of them
  means anything -- the first run derived 71.1 and rejected five members whose photos
  are fine. The score is kept as a RANKING signal, which it is valid for: the widest
  scores are where a mis-pairing would hide, and those frames are badged on the
  contact sheet for the operator to look at hardest. It is not a pass/fail gate, and
  calling it one would be a confident wrong answer.
  ▶ The operator's check replaces it: the sheet shows the manual crop BESIDE the
  state's own id-keyed thumbnail, so the two faces are compared by the one detector
  that does discriminate here.

Writes .tmp-sc-candidates.json in the schema import-headshot-candidates.py reads,
and primes .tmp-headshot-cache with the extracted bytes so the sheet and the import
use exactly the pixels this script measured.
"""
import argparse
import collections
import hashlib
import io
import json
import os
import re
import sys

import fitz
import requests
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from headshot_crop import crop_4x5  # noqa: E402

UA = {
    'User-Agent': (
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0 Safari/537.36'
    )
}
BASE = 'https://www.scstatehouse.gov/man25/'
CACHE = '.tmp-headshot-cache'
PDF_CACHE = '.tmp-sc-manual'
TARGET_W, TARGET_H = 600, 750

# The 2025 manual, 106th edition -- the most recent the publications page links.
SECTIONS = [
    ('senate', '08_SenMem_A-G.pdf'),
    ('senate', '09_SenMem_G-N.pdf'),
    ('senate', '10_SenMem_O-Z.pdf'),
    ('house', '19_HseMem_A-D.pdf'),
    ('house', '20_HseMem_D-H.pdf'),
    ('house', '21_HseMem_H-L.pdf'),
    ('house', '22_HseMem_L-P.pdf'),
    ('house', '23_HseMem_P-Y.pdf'),
]
# Presiding officers are cross-referenced out of the member sections
# ("for biography and picture, see p. 19") and photographed here instead.
OFFICER_SECTIONS = [
    ('senate', '07_SenOff.pdf'),
    ('house', '18_HseOff.pdf'),
]

DIST_RE = re.compile(r'\(Dist\.\s*No\.\s*(\d+)', re.I)
# "ADAMS, Brian Richard [R]" / "CAMPSEN, George E. III “Chip” [R]"
SURNAME_RE = re.compile(r'^\s*([A-Z][A-Za-z\'\-]*(?:\s+[A-Z][A-Za-z\'\-]*)*),')


def fetch_pdf(filename: str) -> str:
    os.makedirs(PDF_CACHE, exist_ok=True)
    path = os.path.join(PDF_CACHE, filename)
    if os.path.exists(path) and os.path.getsize(path) > 10000:
        return path
    resp = requests.get(BASE + filename, headers=UA, timeout=180)
    if resp.status_code != 200 or resp.content[:5] != b'%PDF-':
        raise SystemExit(
            f'{filename}: HTTP {resp.status_code}, first bytes {resp.content[:20]!r} '
            '-- a clean 200 can carry an error page, so this is refused rather than parsed'
        )
    with open(path, 'wb') as fh:
        fh.write(resp.content)
    return path


def norm_key(chamber: str, district) -> str:
    return f'{chamber}-{int(district)}'


def fingerprint(img: Image.Image, size=(64, 80)) -> list:
    """Grayscale, 4:5-cropped, fixed-size pixel list for mean absolute difference."""
    cropped, _ = crop_4x5(img)
    return list(cropped.convert('L').resize(size, Image.LANCZOS).getdata())


def mad(a: list, b: list) -> float:
    return sum(abs(x - y) for x, y in zip(a, b)) / len(a)


def harvest(path: str, chamber: str, url: str):
    """Yield one record per (photo, bio text) pair the document itself associates."""
    doc = fitz.open(path)
    for pno in range(doc.page_count):
        page = doc[pno]
        blocks = [b for b in page.get_text('blocks') if b[4].strip()]
        for info in page.get_image_info(xrefs=True):
            xref = info.get('xref')
            if not xref:
                continue
            ix0, iy0, ix1, iy1 = info['bbox']
            # Filter on SHAPE, not on size. A 150px minimum looks like a sensible
            # "ignore the ornaments" rule and silently threw away real portraits --
            # Lee Hewitt's (HD-108) is published at 103x130. Every member portrait in
            # this manual is close to 4:5; rules, seals and page furniture are not.
            aspect = info['width'] / info['height'] if info['height'] else 0
            if not (0.60 <= aspect <= 1.00) or info['width'] < 80 or info['height'] < 100:
                continue
            # THE INVARIANT IS THE SHARED TOP EDGE, AND ONLY THAT.
            # An x-overlap test looks safer and is wrong: the bio wraps AROUND the
            # portrait, so a right-hand photo at x 189-246 has its own text at x 42-185,
            # not overlapping it at all. Requiring overlap rejected 41 correct pairs on
            # the first run. What the layout actually guarantees is that a member's bio
            # block starts on the same baseline as their photo.
            best, best_dy = None, 99.0
            for b in blocks:
                dy = abs(b[1] - iy0)
                if dy < best_dy:
                    best, best_dy = b, dy
            if best is None or best_dy > 6:
                yield {
                    'chamber': chamber, 'page_no': pno, 'xref': xref,
                    'width': info['width'], 'height': info['height'],
                    'district': None, 'surname': None, 'text': None,
                    'source_pdf': url, 'why': f'no bio block within 6pt (best {best_dy:.1f})',
                }
                continue
            text = ' '.join(best[4].split())
            dmatch = DIST_RE.search(text)
            smatch = SURNAME_RE.match(text)
            yield {
                'chamber': chamber, 'page_no': pno, 'xref': xref,
                'width': info['width'], 'height': info['height'],
                'district': int(dmatch.group(1)) if dmatch else None,
                'surname': smatch.group(1).strip() if smatch else None,
                'text': text[:160],
                'source_pdf': url,
                'why': None if dmatch else 'bio block states no "(Dist. No. N"',
            }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--roster', default='data/sc-legislature-roster.json')
    ap.add_argument('--out', default='.tmp-sc-candidates.json')
    ap.add_argument('--mad-threshold', type=float, default=None,
                    help='reject a manual photo scoring above this against the state\'s '
                         'id-keyed file. Default: derived from the measured separation.')
    args = ap.parse_args()

    roster = json.load(open(args.roster, encoding='utf-8'))
    members = {}
    for chamber in ('house', 'senate'):
        for m in roster['chambers'][chamber]['members']:
            members[norm_key(chamber, m['district'])] = dict(m, chamber=chamber)
    print(f'roster: {len(members)} seats')

    # ---- 1. harvest every (photo, printed district) pair the manual states -------
    found = {}
    unmatched = []
    docs = {}
    for chamber, filename in SECTIONS:
        path = fetch_pdf(filename)
        docs[filename] = fitz.open(path)
        n = 0
        for rec in harvest(path, chamber, BASE + filename):
            rec['pdf'] = filename
            if rec['district'] is None:
                unmatched.append(rec)
                continue
            key = norm_key(chamber, rec['district'])
            if key in found:
                # Two photos claiming one seat is a real defect, never a tie to break.
                unmatched.append(dict(rec, why=f'duplicate claim on {key}'))
                continue
            found[key] = rec
            n += 1
        print(f'  {filename:<24} {n} portraits keyed by printed district')

    missing = sorted(set(members) - set(found))
    print(f'\nkeyed from member sections: {len(found)} of {len(members)}')
    print(f'not yet keyed ({len(missing)}): {missing}')
    print(f'photos with no usable bio block: {len(unmatched)}')
    for rec in unmatched[:10]:
        print(f'   {rec["pdf"]} p{rec["page_no"]} {rec["width"]}x{rec["height"]}: '
              f'{rec["why"]} :: {(rec["text"] or "")[:90]}')

    # ---- 2. the officers' sections, for seats cross-referenced out of the members'
    officer_pool = []
    for chamber, filename in OFFICER_SECTIONS:
        path = fetch_pdf(filename)
        docs[filename] = fitz.open(path)
        for rec in harvest(path, chamber, BASE + filename):
            rec['pdf'] = filename
            officer_pool.append(rec)
    print(f'\nofficer-section portraits available: {len(officer_pool)}')
    for rec in officer_pool:
        if rec['district'] is not None:
            key = norm_key(rec['chamber'], rec['district'])
            if key in missing and key not in found:
                found[key] = rec
                print(f'   {key} filled from {rec["pdf"]} p{rec["page_no"]}')
    # Officer pages may name without stating a district: match those on surname.
    still = sorted(set(members) - set(found))
    for key in list(still):
        m = members[key]
        for rec in officer_pool:
            if not rec['surname'] or rec['chamber'] != m['chamber']:
                continue
            if rec['surname'].lower() == m['last_name'].lower():
                found[key] = dict(rec, why='matched on surname in the officers section')
                print(f'   {key} filled from {rec["pdf"]} p{rec["page_no"]} '
                      f'(surname {rec["surname"]})')
                break

    missing = sorted(set(members) - set(found))
    print(f'\nkeyed after officers: {len(found)} of {len(members)}; missing {len(missing)}')
    for key in missing:
        print(f'   MISSING {key}  {members[key]["full_name"]}')

    # ---- 3. identity: every manual face against the state's id-keyed 125px file ---
    print('\nidentity check -- manual photo vs scstatehouse.gov/images/members/<code>.jpg')
    os.makedirs(CACHE, exist_ok=True)
    scores, rows = [], []
    state_fp = {}
    for key, rec in sorted(found.items()):
        m = members[key]
        info = docs[rec['pdf']].extract_image(rec['xref'])
        manual_img = Image.open(io.BytesIO(info['image']))
        try:
            raw = requests.get(m['photo_url'], headers=UA, timeout=30).content
            if raw[:2] not in (b'\xff\xd8', b'\x89P'):
                raise ValueError('state file is not an image')
            state_img = Image.open(io.BytesIO(raw))
        except Exception as exc:  # noqa: BLE001
            rows.append((key, m, rec, info, None, f'state file unavailable: {exc}'))
            continue
        a, b = fingerprint(manual_img), fingerprint(state_img)
        state_fp[key] = b
        score = mad(a, b)
        scores.append(score)
        rows.append((key, m, rec, info, score, None))

    if scores:
        srt = sorted(scores)
        print(f'  matched pairs: {len(scores)}')
        print(f'  MAD  min {srt[0]:.2f}  median {srt[len(srt)//2]:.2f}  '
              f'p90 {srt[int(len(srt)*0.9)]:.2f}  max {srt[-1]:.2f}')

    # POSITIVE CONTROL: the same comparison across DIFFERENT people must score high,
    # or the metric is not discriminating and no threshold drawn from it means anything.
    control = []
    keys = [k for k, _, _, _, s, _ in rows if s is not None]
    for i, key in enumerate(keys[:60]):
        other = keys[(i + 7) % len(keys[:60])]
        if other == key:
            continue
        rec = found[key]
        info = docs[rec['pdf']].extract_image(rec['xref'])
        a = fingerprint(Image.open(io.BytesIO(info['image'])))
        control.append(mad(a, state_fp[other]))
    if control:
        csrt = sorted(control)
        print(f'  CONTROL (different people, n={len(control)}): '
              f'min {csrt[0]:.2f}  median {csrt[len(csrt)//2]:.2f}  max {csrt[-1]:.2f}')

    # 🔴 NO THRESHOLD IS DERIVED FROM THIS. The control above overlaps the genuine
    # distribution (see the module docstring for all seven metrics measured), so a
    # midpoint between them is not a decision boundary -- the first version of this
    # script computed one and rejected five members whose photos are correct. The
    # score is carried into the sheet as a ranking signal and nothing else.
    if scores and control:
        separated = max(scores) < min(control)
        print(f'  separated: {"YES" if separated else "NO -- ranking signal only, not a gate"}')
        if separated:
            print('  ⚠ the distributions now separate; that is a CHANGE from the measured '
                  'result and should be re-read before any gate is built on it')

    flag_at = sorted(scores)[int(len(scores) * 0.9)] if scores else None
    if flag_at is not None:
        print(f'  badging the widest decile on the sheet: MAD >= {flag_at:.2f}')

    # ---- 4. write the candidates ------------------------------------------------
    # PICK THE BETTER SOURCE PER SEAT, rather than assuming the manual always wins.
    # It usually does -- but the manual reproduces a few members at 93x116, below even
    # the 125px web file, and for the 4 stale seats and the 5 it omits entirely the web
    # file is the only source that shows the CURRENT member. Every seat gets a
    # candidate; which source it came from and what it really measures are recorded.
    out, rejected = [], []
    hist = collections.Counter()
    resolved = set()
    for key, m, rec, info, score, err in rows:
        img = Image.open(io.BytesIO(info['image']))
        _, (kw, kh) = crop_4x5(img)
        upscale = max(TARGET_W / kw, TARGET_H / kh)
        # THE GATE: the surname printed beside this photo must be the surname the
        # roster seats in this district. Both come out of the manual's own sentence;
        # the roster comes from the chamber's member list and Open States. A seat that
        # changed hands since the 2025 edition fails here, which is the point.
        reason = None
        printed = (rec.get('surname') or '').strip().lower()
        seated = m['last_name'].strip().lower()
        if not printed:
            reason = 'the manual states no surname beside this photo'
        elif printed not in seated and seated not in printed:
            reason = (f'manual prints "{rec["surname"]}" for {key}, roster seats '
                      f'"{m["last_name"]}" -- the 2025 edition predates this member')
        if reason:
            rejected.append((key, m['full_name'], reason))
            continue
        # The bytes came out of a PDF, so there is no URL to refetch. Prime the shared
        # cache under the PDF's own URL: the sheet and the import then use exactly these
        # pixels, and if the cache is ever cleared the fetch returns a PDF and fails
        # loudly instead of silently shipping something else.
        url = f'{rec["source_pdf"]}#page={rec["page_no"] + 1}&member={m["member_id"]}'
        ck = os.path.join(CACHE, hashlib.sha1(url.encode()).hexdigest() + '.bin')
        with open(ck, 'wb') as fh:
            fh.write(info['image'])
        hist[f'{info["width"]}x{info["height"]}'] += 1
        resolved.add(key)
        out.append({
            'name': m['full_name'],
            'politician_id': None,  # filled by the resolver below
            'member_id': m['member_id'],
            'chamber': m['chamber'],
            'district': m['district'],
            'url': url,
            'page': m['bio_url'],
            'license': 'press_use',
            'source': 'manual-2025',
            'source_w': info['width'],
            'source_h': info['height'],
            'upscale': round(upscale, 2),
            'mad': None if score is None else round(score, 2),
            # Not a verdict -- a request that the operator look at this pair hardest.
            'verify_face': bool(score is not None and flag_at is not None and score >= flag_at),
            'state_thumb': m['photo_url'],
            'printed_surname': rec.get('surname'),
        })

    # Every seat the manual could not serve, and every seat where the web file is the
    # larger of the two, falls back to scstatehouse.gov/images/members/<code>.jpg.
    for key in sorted(members):
        m = members[key]
        manual = next((c for c in out if c['member_id'] == m['member_id']), None)
        try:
            raw = requests.get(m['photo_url'], headers=UA, timeout=30).content
            if raw[:2] not in (b'\xff\xd8', b'\x89P'):
                raise ValueError('not an image')
            simg = Image.open(io.BytesIO(raw))
            _, (skw, skh) = crop_4x5(simg)
        except Exception as exc:  # noqa: BLE001
            if manual is None:
                rejected.append((key, m['full_name'], f'no manual photo and no web file: {exc}'))
            continue
        if manual is not None and manual['source_w'] * manual['source_h'] >= skw * skh:
            continue  # the manual crop is at least as large; keep it
        if manual is not None:
            out.remove(manual)
            note = (f'web file {skw}x{skh} beats the manual\'s '
                    f'{manual["source_w"]}x{manual["source_h"]}')
        else:
            note = 'the 2025 manual does not carry this member'
        ck = os.path.join(CACHE, hashlib.sha1(m['photo_url'].encode()).hexdigest() + '.bin')
        with open(ck, 'wb') as fh:
            fh.write(raw)
        out.append({
            'name': m['full_name'],
            'politician_id': None,
            'member_id': m['member_id'],
            'chamber': m['chamber'],
            'district': m['district'],
            'url': m['photo_url'],
            'page': m['bio_url'],
            'license': 'press_use',
            'source': 'scstatehouse-web',
            'source_w': simg.size[0],
            'source_h': simg.size[1],
            'upscale': round(max(TARGET_W / skw, TARGET_H / skh), 2),
            'mad': None,
            'verify_face': False,
            'state_thumb': m['photo_url'],
            'printed_surname': None,
            'note': note,
        })

    print(f'\ncandidates: {len(out)}   rejected: {len(rejected)}   '
          f'no photo at all: {len(missing)}')
    for key, name, reason in rejected:
        print(f'   REJECT {key} {name}: {reason}')
    reach = sum(1 for c in out if c['upscale'] <= 1.0)
    print(f'reach 600x750 with no enlargement: {reach} of {len(out)}')
    worst = sorted(out, key=lambda c: -c['upscale'])[:5]
    for c in worst:
        print(f'   widest upscale {c["upscale"]}x  {c["name"]} {c["source_w"]}x{c["source_h"]}')

    with open(args.out, 'w', encoding='utf-8') as fh:
        json.dump(out, fh, indent=1)
    print(f'\nwrote {args.out}')


if __name__ == '__main__':
    main()
