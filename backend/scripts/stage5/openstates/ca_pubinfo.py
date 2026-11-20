"""California: keep a local copy of the Legislature's PUBINFO vote tables, and index them by bill.

PUBINFO (downloads.leginfo.legislature.ca.gov) is the Legislature's own bulk download: open, no key, no robots.txt, no
terms text (survey 2026-11-20). Each two-year session is one zip (pubinfo_2025.zip, 1.29 GB), almost all of it bill
text (205,269 .lob files). The vote and member tables are about 9 MB of it. The runner's rule (2026-11-20): read each
session's zip ONCE, keep the copy, keep it current with the small daily change files (pubinfo_<Day>.zip, under 1 MB),
never read the session zip again on every run.

So `sync` reads only the zip's directory and the members in TABLES, with HTTP range requests, and writes them under
<cache>/<year>/ with MANIFEST.json (the zip's size, ETag and Last-Modified, and each table's sha256). A year that has a
manifest is never read again unless --refresh is given. `daily` fetches each pubinfo_<Day>.zip newer than the last one
applied and merges its rows into the session's tables by each table's own key (capublic.sql's check_dup indexes); a
gap of more than seven days since the last one applied is reported, because the weekday files are overwritten weekly.
`index` writes one JSON file per bill (<cache>/<year>/bills/<bill_id>.json: its floor and committee vote summaries,
each member's vote, the motion texts) and <cache>/<year>/legislators.json. Those are the documents the reader reads
(src/lib/stateRollCallEvidence.ts, California); set CA_PUBINFO_DIR=<cache> for the verifier and every step 7 tool.

  python3 -I ca_pubinfo.py sync <cache> 2017 2019 2021 2023 2025 [--refresh]
  python3 -I ca_pubinfo.py daily <cache>
  python3 -I ca_pubinfo.py index <cache> [2025 ...]
  python3 -I ca_pubinfo.py votes <cache> <bill_id> [--floor]      # print a bill's votes, for a person to read

The cache lives outside the repo (legiscan-cache/pubinfo). Nothing here writes to the database.
"""
import datetime, hashlib, io, json, os, re, sys, urllib.request, zipfile

HOST = 'https://downloads.leginfo.legislature.ca.gov'
UA = 'EmpoweredVoteBot/1.0 (+https://empowered.vote)'
TABLES = ['BILL_DETAIL_VOTE_TBL', 'BILL_SUMMARY_VOTE_TBL', 'BILL_MOTION_TBL', 'LEGISLATOR_TBL', 'LOCATION_CODE_TBL',
          'BILL_TBL', 'BILL_HISTORY_TBL', 'BILL_VERSION_AUTHORS_TBL']
# Column order of each kept table (pubinfo_load.zip, capublic.sql and <table>.sql).
COLS = {
    'BILL_DETAIL_VOTE_TBL': ['bill_id', 'location_code', 'legislator_name', 'vote_date_time', 'vote_date_seq', 'vote_code',
                             'motion_id', 'trans_uid', 'trans_update', 'member_order', 'session_date', 'speaker'],
    'BILL_SUMMARY_VOTE_TBL': ['bill_id', 'location_code', 'vote_date_time', 'vote_date_seq', 'motion_id', 'ayes', 'noes',
                              'abstain', 'vote_result', 'trans_uid', 'trans_update', 'file_item_num', 'file_location',
                              'display_lines', 'session_date'],
    'BILL_MOTION_TBL': ['motion_id', 'motion_text', 'trans_uid', 'trans_update'],
    'LEGISLATOR_TBL': ['district', 'session_year', 'legislator_name', 'house_type', 'author_name', 'first_name', 'last_name',
                       'middle_initial', 'name_suffix', 'name_title', 'web_name_title', 'party', 'active_flg', 'trans_uid',
                       'trans_update', 'active_legislator'],
    'LOCATION_CODE_TBL': ['session_year', 'location_code', 'location_type', 'consent_calendar_code', 'description',
                          'long_description', 'active_flg', 'trans_uid', 'trans_update', 'inactive_file_flg'],
    'BILL_TBL': ['bill_id', 'session_year', 'session_num', 'measure_type', 'measure_num', 'measure_state', 'chapter_year',
                 'chapter_type', 'chapter_session_num', 'chapter_num', 'latest_bill_version_id', 'active_flg', 'trans_uid',
                 'trans_update', 'current_location', 'current_secondary_loc', 'current_house', 'current_status',
                 'days_31st_in_print'],
    'BILL_HISTORY_TBL': ['bill_id', 'bill_history_id', 'action_date', 'action', 'trans_uid', 'trans_update_dt',
                         'action_sequence', 'action_code', 'action_status', 'primary_location', 'secondary_location',
                         'ternary_location', 'end_status'],
    'BILL_VERSION_AUTHORS_TBL': ['bill_version_id', 'type', 'house', 'name', 'contribution', 'committee_members',
                                 'active_flg', 'trans_uid', 'trans_update', 'primary_author_flg'],
}
# The key a daily row replaces an older row by (capublic.sql: the primary keys and check_dup indexes).
KEYS = {
    'BILL_DETAIL_VOTE_TBL': ['bill_id', 'vote_date_time', 'location_code', 'motion_id', 'legislator_name', 'vote_date_seq'],
    'BILL_SUMMARY_VOTE_TBL': ['bill_id', 'motion_id', 'vote_date_time', 'vote_date_seq', 'location_code'],
    'BILL_MOTION_TBL': ['motion_id'],
    'LEGISLATOR_TBL': ['session_year', 'house_type', 'district', 'legislator_name'],
    'LOCATION_CODE_TBL': ['session_year', 'location_code'],
    'BILL_TBL': ['bill_id'],
    'BILL_HISTORY_TBL': ['bill_id', 'bill_history_id'],
    'BILL_VERSION_AUTHORS_TBL': ['bill_version_id', 'type', 'house', 'name', 'contribution'],
}
# The fields the reader reads; the rest (trans_uid, trans_update, display_lines ...) stay in the .dat files.
SUMMARY_KEEP = ['location_code', 'vote_date_time', 'vote_date_seq', 'motion_id', 'ayes', 'noes', 'abstain', 'vote_result', 'session_date']
DETAIL_KEEP = ['location_code', 'legislator_name', 'vote_date_time', 'vote_date_seq', 'vote_code', 'motion_id', 'speaker']
DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']


def parse_dat(text, table):
    """A PUBINFO .dat file -> list of dicts. Fields are tab-separated; a text field is enclosed in backquotes and may
    hold a tab or a newline; NULL is the bare word. Refuses a row whose field count is not the table's."""
    cols, rows, i, n, row = COLS[table], [], 0, len(text), []
    while i < n:
        if text[i] == '`':
            j = text.find('`', i + 1)
            if j < 0: raise ValueError(f'{table}: a quoted field is never closed')
            row.append(text[i + 1:j]); i = j + 1
            if i < n and text[i] not in '\t\n\r': raise ValueError(f'{table}: text after a quoted field: {text[i:i + 20]!r}')
        else:
            j = i
            while j < n and text[j] not in '\t\n': j += 1
            v = text[i:j].rstrip('\r')
            row.append(None if v == 'NULL' else v); i = j
        if i < n and text[i] == '\r': i += 1
        if i >= n or text[i] == '\n':
            if len(row) != len(cols):
                raise ValueError(f'{table}: a row has {len(row)} fields, the table {len(cols)}: {row[:3]}')
            rows.append(dict(zip(cols, row))); row = []
        i += 1
    return rows


def write_dat(rows, table):
    out = []
    for r in rows:
        out.append('\t'.join('NULL' if r[c] is None else (f'`{r[c]}`' if not re.fullmatch(r'-?\d+(\.\d+)?|\d{4}-\d\d-\d\d \d\d:\d\d:\d\d', r[c]) else r[c])
                             for c in COLS[table]))
    return '\n'.join(out) + ('\n' if out else '')


class RangeFile(io.RawIOBase):
    """A remote file read by HTTP range requests, so zipfile reads only the directory and the members asked for."""
    def __init__(self, url, opener=urllib.request.urlopen):
        self.url, self.pos, self.open = url, 0, opener
        h = self.open(urllib.request.Request(url, method='HEAD', headers={'User-Agent': UA})).headers
        self.size, self.etag, self.modified = int(h['Content-Length']), h.get('ETag'), h.get('Last-Modified')
        self.fetched, self.refused = 0, None
    def readable(self): return True
    def seekable(self): return True
    def tell(self): return self.pos
    def seek(self, off, whence=0):
        self.pos = off if whence == 0 else self.pos + off if whence == 1 else self.size + off
        return self.pos
    def readinto(self, b):
        if self.pos >= self.size: return 0
        end = min(self.size, self.pos + len(b)) - 1
        r = self.open(urllib.request.Request(self.url, headers={'Range': f'bytes={self.pos}-{end}', 'User-Agent': UA}))
        if r.status != 206:
            self.refused = f'{self.url}: asked for a range, got HTTP {r.status}; refusing to read the whole zip'
            raise IOError(self.refused)
        d = r.read(); b[:len(d)] = d; self.pos += len(d); self.fetched += len(d)
        return len(d)


def sha(path):
    return hashlib.sha256(open(path, 'rb').read()).hexdigest()


def sync(cache, years, refresh=False, opener=urllib.request.urlopen):
    for y in years:
        d = os.path.join(cache, str(y)); man = os.path.join(d, 'MANIFEST.json')
        if os.path.exists(man) and not refresh:
            print(f'{y}: on disk since {json.load(open(man))["fetched_at"]}; not read again (--refresh to read it)')
            continue
        os.makedirs(d, exist_ok=True)
        rf = RangeFile(f'{HOST}/pubinfo_{y}.zip', opener)
        try:
            z = zipfile.ZipFile(io.BufferedReader(rf, buffer_size=1 << 16))
        except (zipfile.BadZipFile, OSError):
            if rf.refused: raise SystemExit(rf.refused)  # zipfile reports a failed read as "not a zip file"
            raise
        names = {i.filename.upper(): i.filename for i in z.infolist()}
        tables = {}
        for t in TABLES:
            name = names.get(f'{t}.DAT')
            if not name: raise SystemExit(f'{y}: pubinfo_{y}.zip has no {t}.dat')
            p = os.path.join(d, f'{t}.dat')
            with open(p, 'wb') as f: f.write(z.read(name))
            tables[t] = {'bytes': os.path.getsize(p), 'sha256': sha(p)}
        json.dump({'zip': f'pubinfo_{y}.zip', 'zip_bytes': rf.size, 'etag': rf.etag, 'last_modified': rf.modified,
                   'bytes_read': rf.fetched, 'fetched_at': datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds'),
                   'tables': tables, 'daily_applied': []}, open(man, 'w'), indent=1)
        print(f'{y}: read {rf.fetched / 1e6:.1f} MB of the {rf.size / 1e9:.2f} GB zip; {len(tables)} tables')


def session_of(bill_id):
    m = re.match(r'(\d{4})\d{4}', bill_id or '')
    return m.group(1) if m else None


def merge_rows(old, new, table):
    """Replace rows of `old` by `new` on the table's key; append the rest. Returns (rows, replaced, added)."""
    key = KEYS[table]; at = {tuple(r[k] for k in key): i for i, r in enumerate(old)}
    rows, rep, add = list(old), 0, 0
    for r in new:
        k = tuple(r[c] for c in key)
        if k in at: rows[at[k]] = r; rep += 1
        else: at[k] = len(rows); rows.append(r); add += 1
    return rows, rep, add


def daily(cache, opener=urllib.request.urlopen, today=None):
    years = sorted(y for y in os.listdir(cache) if re.fullmatch(r'\d{4}', y) and os.path.exists(os.path.join(cache, y, 'MANIFEST.json')))
    if not years: raise SystemExit('no session on disk: run sync first')
    y = years[-1]; man_p = os.path.join(cache, y, 'MANIFEST.json'); man = json.load(open(man_p))
    since = max([a['last_modified_iso'] for a in man['daily_applied']] or [_iso(man['last_modified'])])
    files = []
    for day in DAYS:
        url = f'{HOST}/pubinfo_{day}.zip'
        h = opener(urllib.request.Request(url, method='HEAD', headers={'User-Agent': UA})).headers
        files.append((_iso(h['Last-Modified']), day, url, int(h['Content-Length'])))
    files.sort()
    newer = [f for f in files if f[0] > since]
    if not newer: print(f'{y}: nothing newer than {since}'); return 0
    gap = (datetime.datetime.fromisoformat(newer[0][0]) - datetime.datetime.fromisoformat(since)).days
    if gap > 7 and len(newer) == len(files):
        print(f'⚠ {y}: the oldest daily file ({newer[0][0]}) is {gap} days after the last applied ({since}); a change '
              f'in between may be lost. Read the session zip again: sync <cache> {y} --refresh (about 30 MB).')
        return 1
    for mod, day, url, size in newer:
        if size > 50_000_000: raise SystemExit(f'{url} is {size} bytes; a daily change file is under 1 MB. Not read.')
        z = zipfile.ZipFile(io.BytesIO(opener(urllib.request.Request(url, headers={'User-Agent': UA})).read()))
        done = {}
        for info in z.infolist():
            t = info.filename.upper().removesuffix('.DAT')
            if t not in TABLES: continue
            new = parse_dat(z.read(info.filename).decode('utf-8', 'replace'), t)
            new = [r for r in new if t in ('BILL_MOTION_TBL',) or (session_of(r.get('bill_id') or r.get('bill_version_id') or '') or r.get('session_year', '')[:4]) == y]
            p = os.path.join(cache, y, f'{t}.dat')
            rows, rep, add = merge_rows(parse_dat(open(p, encoding='utf-8', errors='replace').read(), t), new, t)
            open(p, 'w', encoding='utf-8').write(write_dat(rows, t))
            done[t] = {'replaced': rep, 'added': add}
        man['daily_applied'].append({'file': f'pubinfo_{day}.zip', 'last_modified_iso': mod, 'tables': done})
        print(f'{y}: applied pubinfo_{day}.zip ({mod}): ' + ', '.join(f'{t} {v["replaced"]}~{v["added"]}+' for t, v in done.items()))
    json.dump(man, open(man_p, 'w'), indent=1)
    return 0


def _iso(http_date):
    return datetime.datetime.strptime(http_date, '%a, %d %b %Y %H:%M:%S %Z').isoformat()


def index(cache, years=None):
    years = years or sorted(y for y in os.listdir(cache) if re.fullmatch(r'\d{4}', y))
    for y in years:
        d = os.path.join(cache, str(y))
        load = lambda t: parse_dat(open(os.path.join(d, f'{t}.dat'), encoding='utf-8', errors='replace').read(), t)
        motions = {r['motion_id']: r['motion_text'] for r in load('BILL_MOTION_TBL')}
        locs = {r['location_code']: r['description'] for r in load('LOCATION_CODE_TBL')}
        bills = {}
        for r in load('BILL_SUMMARY_VOTE_TBL'):
            bills.setdefault(r['bill_id'], {'summary': [], 'detail': []})['summary'].append({k: r[k] for k in SUMMARY_KEEP})
        for r in load('BILL_DETAIL_VOTE_TBL'):
            bills.setdefault(r['bill_id'], {'summary': [], 'detail': []})['detail'].append({k: r[k] for k in DETAIL_KEEP})
        out = os.path.join(d, 'bills'); os.makedirs(out, exist_ok=True)
        for bid, b in bills.items():
            used = {r['motion_id'] for r in b['summary'] + b['detail']}
            b['motions'] = {m: motions.get(m) for m in sorted(used)}
            b['locations'] = {r['location_code']: locs.get(r['location_code']) for r in b['summary'] + b['detail']}
            b['bill_id'] = bid
            json.dump(b, open(os.path.join(out, f'{bid}.json'), 'w'), sort_keys=True, separators=(',', ':'))
        legs = [{k: r[k] for k in ('district', 'session_year', 'legislator_name', 'house_type', 'first_name', 'last_name',
                                   'middle_initial', 'name_suffix', 'author_name')} for r in load('LEGISLATOR_TBL')]
        json.dump(legs, open(os.path.join(d, 'legislators.json'), 'w'), sort_keys=True)
        print(f'{y}: {len(bills)} bills with votes, {len(legs)} legislator rows')


def main(argv):
    if len(argv) < 3: raise SystemExit(__doc__)
    cmd, cache = argv[1], os.path.abspath(argv[2])
    rest = [a for a in argv[3:] if not a.startswith('--')]
    if cmd == 'sync': sync(cache, rest, '--refresh' in argv)
    elif cmd == 'daily': return daily(cache)
    elif cmd == 'index': index(cache, rest or None)
    elif cmd == 'votes':
        b = json.load(open(os.path.join(cache, session_of(rest[0]), 'bills', f'{rest[0]}.json')))
        for s in sorted(b['summary'], key=lambda r: (r['vote_date_time'], int(r['vote_date_seq']))):
            if '--floor' in argv and not s['location_code'].endswith('FLOOR'): continue
            print(s['vote_date_time'][:10], s['location_code'], s['vote_date_seq'], s['motion_id'], f"{s['ayes']}-{s['noes']}-{s['abstain']}",
                  s['vote_result'], '|', b['motions'].get(s['motion_id']))
    else: raise SystemExit(__doc__)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
