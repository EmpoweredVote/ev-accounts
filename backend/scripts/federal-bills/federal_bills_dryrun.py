#!/usr/bin/env python3 -I
"""Dry run: parse govinfo BILLSTATUS bulk XML (108th-119th) and report what a
federal-bills load into essentials.legislative_bills would do. WRITES NOTHING.
The database is only read, through psql (SELECTs).

Usage: federal_bills_dryrun.py <bulk_dir> <out_dir>
  bulk_dir  folder holding <congress>-<type>/BILLSTATUS-*.xml
  out_dir   receives bills.ndjson (parsed records) and report.txt
Needs DATABASE_URL in the environment.

Party is never stored: sponsor names are not kept at all, only bioguide ids.
"""
import collections, json, os, re, subprocess, sys
import xml.etree.ElementTree as ET
from multiprocessing import Pool

def run_psql(cmd, **kw):
    """subprocess.run for psql that never prints the command (it holds the DB password)."""
    try:
        return subprocess.run(cmd, check=True, **kw)
    except subprocess.CalledProcessError as e:
        sys.exit(f'psql failed (exit {e.returncode}); see output above')


TYPES = ('hr', 's', 'hjres', 'sjres', 'hres', 'sres', 'hconres', 'sconres')
TYPE_SLUG = {'hr': 'house-bill', 's': 'senate-bill', 'hjres': 'house-joint-resolution',
             'sjres': 'senate-joint-resolution',
             'hres': 'house-resolution', 'sres': 'senate-resolution',
             'hconres': 'house-concurrent-resolution', 'sconres': 'senate-concurrent-resolution'}
def ordinal(n):
    return f"{n}{'th' if 10 <= n % 100 <= 20 else {1: 'st', 2: 'nd', 3: 'rd'}.get(n % 10, 'th')}"


def txt(el, path):
    x = el.find(path)
    return (x.text or '').strip() if x is not None and x.text else ''


def strip_html(s):
    s = re.sub(r'<[^>]+>', ' ', s)
    s = s.replace('&nbsp;', ' ').replace('&amp;', '&').replace('&quot;', '"').replace('&#39;', "'")
    return re.sub(r'\s+', ' ', s).strip()


# One chamber's floor passage: "Passed House ...", "Passed Senate ...", "Passed/agreed to in House: ..."
CHAMBER_PASS_RE = re.compile(r'^(Passed|Agreed to)[^:]*?\b(House|Senate)\b', re.I)
SIMPLE_RES = ('HRES', 'SRES')  # one chamber's vote is final


def status_of(btype, latest, has_law, chambers_passed):
    """Passed = it actually passed: both chambers for bills, joint and concurrent
    resolutions; the one chamber for simple resolutions. A bill that passed only
    one chamber keeps its stage label (it has not passed yet)."""
    if has_law:
        return 'Signed'
    final = len(chambers_passed) >= (1 if btype in SIMPLE_RES else 2)
    if final:
        return 'Passed'
    if re.search(r'reported', latest, re.I):
        return 'Reported'
    if re.search(r'referred to|committee', latest, re.I):
        return 'In Committee'
    return 'Introduced'


def parse_file(path):
    b = ET.parse(path).getroot().find('bill')
    if b is None:
        return None
    folder = os.path.basename(os.path.dirname(path))  # <congress>-<type>
    fname = re.match(r'BILLSTATUS-(\d+)([a-z]+?)(\d+)\.xml$', os.path.basename(path))
    congress = int(txt(b, 'congress') or fname.group(1))
    btype = (txt(b, 'type') or txt(b, 'billType') or folder.split('-')[1]).upper()
    num = txt(b, 'number') or txt(b, 'billNumber') or fname.group(3)  # a few files use the older tags
    latest = txt(b, 'latestAction/text')
    laws = [txt(i, 'number') for i in b.findall('laws/item')]
    law_date = passed_at = ''
    chambers = set()
    for a in b.findall('actions/item'):
        d, t, ty = txt(a, 'actionDate'), txt(a, 'text'), txt(a, 'type')
        if ty == 'BecameLaw' and 'Signed' in t:
            law_date = d
        m = CHAMBER_PASS_RE.match(t)
        if m:
            chambers.add(m.group(2).lower())
            passed_at = max(passed_at, d)
    sums = sorted(b.findall('summaries/summary'), key=lambda s: txt(s, 'updateDate'))
    summary = strip_html(txt(sums[-1], 'text')) if sums else ''
    tags = []
    for n in [txt(b, 'policyArea/name')] + [txt(i, 'name') for i in b.findall('subjects/legislativeSubjects/item')]:
        if n and n not in tags:
            tags.append(n)
    sp = b.find('sponsors/item')
    cos = [txt(i, 'bioguideId') for i in b.findall('cosponsors/item') if not txt(i, 'sponsorshipWithdrawnDate')]
    low = btype.lower()
    return {
        'external_id': f'{congress}-{btype}-{num}', 'congress': congress, 'type': btype,
        'number': f'{btype} {num}', 'title': txt(b, 'title'), 'summary': summary[:4000],
        'raw_status': latest, 'status_label': status_of(btype, latest, bool(laws), chambers),
        'introduced_at': txt(b, 'introducedDate'), 'passed_at': passed_at,
        'signed_at': law_date or None if laws else None,
        'topic_tags': tags[:10],
        'url': f'https://www.congress.gov/bill/{ordinal(congress)}-congress/{TYPE_SLUG[low]}/{num}',
        'sponsor_bioguide': txt(sp, 'bioguideId') if sp is not None else '',
        'cosponsor_bioguides': sorted(set(c for c in cos if c)),
    }


def psql(sql):
    out = run_psql(['psql', os.environ['DATABASE_URL'], '-X', '-A', '-t', '-F', '\t', '-c', sql],
                         capture_output=True, text=True).stdout
    return [l.split('\t') for l in out.splitlines() if l]


def main(bulk, out):
    os.makedirs(out, exist_ok=True)
    files = []
    for c in range(108, 120):
        for t in TYPES:
            d = os.path.join(bulk, f'{c}-{t}')
            if os.path.isdir(d):
                files += [os.path.join(d, f) for f in sorted(os.listdir(d)) if f.endswith('.xml')]
    with Pool() as p:
        recs = [r for r in p.imap(parse_file, files, chunksize=500) if r]
    with open(os.path.join(out, 'bills.ndjson'), 'w') as f:
        for r in recs:
            f.write(json.dumps(r) + '\n')

    # --- read-only DB lookups ---
    bg = {}
    for pid, g in psql("select id, bioguide_id from essentials.politicians where bioguide_id is not null and bioguide_id <> ''"):
        bg.setdefault(g, set()).add(pid)
    for pid, g in psql("select politician_id, id_value from essentials.legislative_politician_id_map where id_type='bioguide'"):
        bg.setdefault(g, set()).add(pid)
    existing = psql("select external_id, substring(url from '/bill/(\\d+)/'), url from essentials.legislative_bills "
                    "where jurisdiction='federal' and source='congress'")
    new_keys = {r['external_id'] for r in recs}

    L = []
    L.append(f'duplicate new keys (must be 0): {len(recs) - len(new_keys)}')
    L.append(f'bills parsed: {len(recs)} from {len(files)} files')
    by = collections.Counter((r['congress']) for r in recs)
    L.append('per congress: ' + ', '.join(f'{c}:{by[c]}' for c in sorted(by)))
    L.append('status: ' + str(dict(collections.Counter(r['status_label'] for r in recs))))
    L.append(f"empty title: {sum(not r['title'] for r in recs)}, empty summary: {sum(not r['summary'] for r in recs)}, "
             f"no tags: {sum(not r['topic_tags'] for r in recs)}, no introduced date: {sum(not r['introduced_at'] for r in recs)}")
    amb = {g for g, s in bg.items() if len(s) > 1}
    L.append(f'bioguide ids known to us: {len(bg)}; ambiguous (map to >1 politician): {len(amb)}')
    spons = [r['sponsor_bioguide'] for r in recs]
    L.append(f"bills with a sponsor: {sum(bool(s) for s in spons)}; sponsor linked to a politician: "
             f"{sum(s in bg and s not in amb for s in spons)}")
    cos_all = [g for r in recs for g in r['cosponsor_bioguides']]
    L.append(f'cosponsor rows: {len(cos_all)}; linked: {sum(g in bg and g not in amb for g in cos_all)}')
    unl = {g for g in set(spons) | set(cos_all) if g and g not in bg}
    L.append(f'distinct member ids with no politician (stay unlinked): {len(unl)}')
    # existing rows
    by_real = collections.Counter(c for _, c, _ in existing)
    old = [e for e in existing if e[1] and int(e[1]) < 108]
    L.append(f'existing federal rows: {len(existing)}; real congress <108 (keep+relabel): {len(old)}; '
             f'108-119 (delete+reload): {sum(1 for e in existing if e[1] and int(e[1]) >= 108)}')
    def real_key(url):
        m = re.search(r'/bill/(\d+)/([a-z]+)/(\d+)', url or '')
        return f'{m.group(1)}-{m.group(2).upper()}-{m.group(3)}' if m else None
    lost = [e for e in existing if e[1] and int(e[1]) >= 108 and real_key(e[2]) not in new_keys]
    L.append(f'existing 108-119 rows with no bulk record (types outside hr/s/hjres/sjres): {len(lost)} '
             f"{dict(collections.Counter((real_key(e[2]) or 'unparseable-url').split('-')[1] for e in lost))}")
    dups = len(existing) - len({real_key(e[2]) for e in existing})
    L.append(f'existing rows sharing a real key (duplicates): {dups}')
    open(os.path.join(out, 'report.txt'), 'w').write('\n'.join(L) + '\n')
    print('\n'.join(L))


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
