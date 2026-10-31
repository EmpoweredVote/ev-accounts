#!/usr/bin/env python3 -I
"""Load House roll-call votes for the 108th-114th Congress (2003-2016) from the House
Clerk's XML (https://clerk.house.gov/evs/<year>/roll<NNN>.xml) into
essentials.legislative_votes.

  federal_votes_house_clerk.py <out_dir>             download + parse, write files only
  federal_votes_house_clerk.py <out_dir> --rehearse  also run the load, then ROLL BACK
  federal_votes_house_clerk.py <out_dir> --commit    run the load and COMMIT

Needs DATABASE_URL. Downloads are cached in <out_dir>/xml/<year>/, so a rerun resumes.
Only members who match a politician row (by bioguide id) are loaded; no people are
created. The bill link comes from <legis-num> matched to legislative_bills.external_id
(<congress>-<TYPE>-<n>); procedural votes keep a null bill_id. Party is never stored.
Loads votes ONLY for members who have no House Clerk votes yet, so a rerun after more
politicians get a bioguide id adds just the new members. Never deletes.
"""
import collections, datetime, glob, os, re, subprocess, sys, time
import xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor

YEARS = range(2003, 2017)
LEGIS = {'H R': 'HR', 'H RES': 'HRES', 'H J RES': 'HJRES', 'H CON RES': 'HCONRES',
         'S': 'S', 'S RES': 'SRES', 'S J RES': 'SJRES', 'S CON RES': 'SCONRES'}
POS = {'yea': 'yea', 'aye': 'yea', 'nay': 'nay', 'no': 'nay', 'not voting': 'not_voting',
       'present': 'present'}
FAIL_RE = re.compile(r'fail|reject|defeat|not (agreed|sustained|passed)', re.I)


def run_psql(cmd, **kw):
    """subprocess.run for psql that never prints the command (it holds the DB password)."""
    try:
        return subprocess.run(cmd, check=True, **kw)
    except subprocess.CalledProcessError as e:
        sys.exit(f'psql failed (exit {e.returncode}); see output above')


def psql(sql):
    out = run_psql(['psql', os.environ['DATABASE_URL'], '-X', '-A', '-t', '-F', '\t', '-c', sql],
                   capture_output=True, text=True).stdout
    return [l.split('\t') for l in out.splitlines() if l]


def esc(v):
    if v is None or v == '':
        return '\\N'
    return str(v).replace('\\', '\\\\').replace('\t', '\\t').replace('\n', '\\n').replace('\r', '\\r')


def fetch_year(args):
    out, year = args
    d = os.path.join(out, 'xml', str(year))
    os.makedirs(d, exist_ok=True)
    misses, n, got = 0, 0, 0
    while misses < 3:  # the end of a session year: three missing rolls in a row
        n += 1
        path = os.path.join(d, f'roll{n:03d}.xml')
        if not os.path.exists(path):
            r = subprocess.run(['curl', '-s', '--compressed', '-m', '30', '-w', '\n%{http_code}',
                                f'https://clerk.house.gov/evs/{year}/roll{n:03d}.xml'],
                               capture_output=True, text=True)
            body, _, code = r.stdout.rpartition('\n')
            if code == '200' and '<rollcall-vote>' in body[:400] + body:
                open(path, 'w').write(body)
            else:
                misses += 1
                continue
            time.sleep(0.1)
        misses = 0
        got += 1
    return year, got


SQL = r"""\set ON_ERROR_STOP on
BEGIN;
set local statement_timeout = '15min';
create temp table stg_votes (external_vote_id text, politician_id uuid, bill_key text, congress int,
  vote_question text, position text, vote_date date, result text, yea_count int, nay_count int) on commit drop;
\copy stg_votes from '{out}/stg_votes.tsv'
-- safety: refuse if any staged member already has House Clerk votes (no double loading)
create temp table stg_pol on commit drop as select distinct politician_id from stg_votes;
analyze stg_pol;
do $$ begin
  if exists (select 1 from stg_pol p join essentials.legislative_votes v on v.politician_id = p.politician_id
             where v.source = 'house-clerk') then
    raise exception 'a staged member already has House Clerk votes; refusing to insert again';
  end if;
end $$;
insert into essentials.legislative_votes
  (politician_id, bill_id, session_id, external_vote_id, vote_question, position, vote_date, result, yea_count, nay_count, source)
select s.politician_id, b.id, se.id, s.external_vote_id, s.vote_question, s.position, s.vote_date, s.result,
       s.yea_count, s.nay_count, 'house-clerk'
from stg_votes s
join essentials.legislative_sessions se on se.jurisdiction='federal' and se.external_id=s.congress::text
left join essentials.legislative_bills b on b.jurisdiction='federal' and b.external_id=s.bill_key;
\echo '== results (inside the transaction)'
select s.external_id as congress, count(*) as votes, count(distinct v.politician_id) as members,
       count(distinct v.external_vote_id) as roll_calls, count(*) filter (where v.bill_id is null) as no_bill
from essentials.legislative_votes v join essentials.legislative_sessions s on s.id=v.session_id
where v.source='house-clerk' group by 1 order by 1::int;
select position, count(*) from essentials.legislative_votes where source='house-clerk' group by 1 order by 2 desc;
\if {commit}
COMMIT;
\echo '== COMMITTED'
\else
ROLLBACK;
\echo '== ROLLED BACK (rehearsal; nothing persisted)'
\endif
"""


def main():
    out = os.path.abspath(sys.argv[1])
    os.makedirs(out, exist_ok=True)
    with ThreadPoolExecutor(4) as ex:
        for year, got in ex.map(fetch_year, [(out, y) for y in YEARS]):
            print(f'{year}: {got} roll calls', flush=True)
    bg = collections.defaultdict(set)
    for pid, g in psql("select id, bioguide_id from essentials.politicians where bioguide_id is not null and bioguide_id <> ''"):
        bg[g].add(pid)
    for pid, g in psql("select politician_id, id_value from essentials.legislative_politician_id_map where id_type='bioguide'"):
        bg[g].add(pid)
    have = {r[0] for r in psql("select distinct politician_id from essentials.legislative_votes where source='house-clerk'")}
    bg = {g: p for g, p in bg.items() if not (len(p) == 1 and next(iter(p)) in have)}
    print(f'members already loaded (skipped): {len(have)}')
    n = rc = nobill = 0
    unknown = collections.Counter()
    seen = set()
    with open(os.path.join(out, 'stg_votes.tsv'), 'w') as fo:
        for f in sorted(glob.glob(os.path.join(out, 'xml', '*', 'roll*.xml'))):
            root = ET.parse(f).getroot()
            m = root.find('vote-metadata')
            t = lambda p: (m.findtext(p) or '').strip()
            congress, year = int(t('congress')), int(f.split(os.sep)[-2])
            xid = f"house-clerk-{congress}-{year}-{int(t('rollcall-num'))}"
            if xid in seen:
                continue
            seen.add(xid)
            lm = re.match(r'^(H R|H RES|H J RES|H CON RES|S|S J RES|S CON RES|S RES) (\d+)$', t('legis-num'))
            key = f'{congress}-{LEGIS[lm.group(1)]}-{lm.group(2)}' if lm else None
            date = datetime.datetime.strptime(t('action-date'), '%d-%b-%Y').date().isoformat()
            result = 'failed' if FAIL_RE.search(t('vote-result')) else 'passed'
            yea = m.findtext('.//totals-by-vote/yea-total')
            nay = m.findtext('.//totals-by-vote/nay-total')
            rows = []
            for rv in root.findall('vote-data/recorded-vote'):
                lg = rv.find('legislator')
                pids = bg.get(lg.get('name-id') or '') if lg is not None else None
                if not pids or len(pids) != 1:
                    continue
                v = (rv.findtext('vote') or '').strip().lower()
                if v not in POS:
                    unknown[v] += 1
                    continue
                rows.append((next(iter(pids)), POS[v]))
            if not rows:
                continue
            rc += 1
            nobill += key is None
            for pid, pos in rows:
                fo.write('\t'.join(esc(x) for x in [
                    xid, pid, key, congress, f"{t('vote-question')}: {t('vote-desc')}".strip(': '), pos,
                    date, result, yea, nay]) + '\n')
                n += 1
    print(f'roll calls with a linkable member: {rc} ({nobill} with no bill link); vote rows: {n}; '
          f'unknown vote words: {dict(unknown)}')
    commit = '--commit' in sys.argv
    with open(os.path.join(out, 'house_votes.sql'), 'w') as f:
        f.write(SQL.format(out=out, commit='true' if commit else 'false'))
    if commit or '--rehearse' in sys.argv:
        run_psql(['psql', os.environ['DATABASE_URL'], '-X', '-f', os.path.join(out, 'house_votes.sql')])
    else:
        print('files only; database not touched')


if __name__ == '__main__':
    main()
