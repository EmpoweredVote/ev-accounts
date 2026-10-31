#!/usr/bin/env python3 -I
"""Load Senate roll-call votes for the 108th-114th Congress from Voteview (UCLA's roll-call
archive, https://voteview.com/data) into essentials.legislative_votes. senate.gov blocks
automated fetches and LegiScan starts at the 115th, so Voteview fills that gap.

  federal_votes_voteview_senate.py <out_dir>             download + parse, write files only
  federal_votes_voteview_senate.py <out_dir> --rehearse  also run the load, then ROLL BACK
  federal_votes_voteview_senate.py <out_dir> --commit    run the load and COMMIT

Needs DATABASE_URL. Downloads are cached in <out_dir>/csv/. Loads votes ONLY for senators
who have no Voteview votes yet, so a rerun after more politicians get a bioguide id adds just
the new members. Never deletes. Members are matched by bioguide id (Voteview's member file);
no people are created. The bill link comes from Voteview's bill_number matched to
legislative_bills.external_id (<congress>-<TYPE>-<n>); other roll calls (nominations,
procedure) keep a null bill_id. Party is never stored.
"""
import collections, csv, datetime, os, re, subprocess, sys

CONGRESSES = range(108, 115)
BASE = 'https://voteview.com/static/data/out'
# Voteview cast_code: 1-3 yea (incl. paired/announced), 4-6 nay, 7-8 present, 9 not voting
POS = {1: 'yea', 2: 'yea', 3: 'yea', 4: 'nay', 5: 'nay', 6: 'nay', 7: 'present', 8: 'present', 9: 'not_voting'}
BILL_RE = re.compile(r'^(HR|S|HRES|SRES|HJRES|SJRES|HCONRES|SCONRES)(\d+)$')
FAIL_RE = re.compile(r'reject|fail|defeat|not (agreed|sustained|passed)|not invoked|not confirmed', re.I)


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


def download(out):
    d = os.path.join(out, 'csv')
    os.makedirs(d, exist_ok=True)
    for c in CONGRESSES:
        for kind in ('votes', 'members', 'rollcalls'):
            path = os.path.join(d, f'S{c}_{kind}.csv')
            if os.path.exists(path):
                continue
            r = subprocess.run(['curl', '-s', '--compressed', '-m', '120', '-w', '\n%{http_code}',
                                f'{BASE}/{kind}/S{c}_{kind}.csv'], capture_output=True, text=True)
            body, _, code = r.stdout.rpartition('\n')
            if code != '200' or not body.startswith('congress'):
                sys.exit(f'download failed: S{c}_{kind}.csv (HTTP {code})')
            open(path, 'w').write(body)
    return d


SQL = r"""\set ON_ERROR_STOP on
BEGIN;
set local statement_timeout = '15min';
create temp table stg_votes (external_vote_id text, politician_id uuid, bill_key text, congress int,
  vote_question text, position text, vote_date date, result text, yea_count int, nay_count int) on commit drop;
\copy stg_votes from '{out}/stg_votes.tsv'
-- safety: refuse if any staged member already has Voteview votes (no double loading)
create temp table stg_pol on commit drop as select distinct politician_id from stg_votes;
analyze stg_pol;
do $$ begin
  if exists (select 1 from stg_pol p join essentials.legislative_votes v on v.politician_id = p.politician_id
             where v.source = 'voteview') then
    raise exception 'a staged member already has Voteview votes; refusing to insert again';
  end if;
end $$;
insert into essentials.legislative_votes
  (politician_id, bill_id, session_id, external_vote_id, vote_question, position, vote_date, result, yea_count, nay_count, source)
select s.politician_id, b.id, se.id, s.external_vote_id, s.vote_question, s.position, s.vote_date, s.result,
       s.yea_count, s.nay_count, 'voteview'
from stg_votes s
join essentials.legislative_sessions se on se.jurisdiction='federal' and se.external_id=s.congress::text
left join essentials.legislative_bills b on b.jurisdiction='federal' and b.external_id=s.bill_key;
\echo '== results (inside the transaction)'
select se.external_id as congress, count(*) as votes, count(distinct v.politician_id) as members,
       count(distinct v.external_vote_id) as roll_calls, count(*) filter (where v.bill_id is null) as no_bill
from essentials.legislative_votes v join essentials.legislative_sessions se on se.id = v.session_id
where v.source = 'voteview' group by 1 order by 1::int;
select position, count(*) from essentials.legislative_votes where source = 'voteview' group by 1 order by 2 desc;
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
    d = download(out)
    bg = collections.defaultdict(set)
    for pid, g in psql("select id, bioguide_id from essentials.politicians where bioguide_id is not null and bioguide_id <> ''"):
        bg[g].add(pid)
    for pid, g in psql("select politician_id, id_value from essentials.legislative_politician_id_map where id_type='bioguide'"):
        bg[g].add(pid)
    have = {r[0] for r in psql("select distinct politician_id from essentials.legislative_votes where source='voteview'")}
    n = rc = nobill = 0
    skipped_members, unknown_bill = set(), collections.Counter()
    with open(os.path.join(out, 'stg_votes.tsv'), 'w') as fo:
        for c in CONGRESSES:
            icpsr = {}  # Voteview member id -> politician id (Senate only, matched by bioguide)
            for m in csv.DictReader(open(os.path.join(d, f'S{c}_members.csv'))):
                if m['chamber'] != 'Senate' or not m['bioguide_id']:
                    continue
                s = bg.get(m['bioguide_id'])
                if s and len(s) == 1:
                    pid = next(iter(s))
                    if pid in have:
                        skipped_members.add(pid)
                    else:
                        icpsr[m['icpsr']] = pid
            rolls = {r['rollnumber']: r for r in csv.DictReader(open(os.path.join(d, f'S{c}_rollcalls.csv')))
                     if r['chamber'] == 'Senate'}
            seen = set()
            for v in csv.DictReader(open(os.path.join(d, f'S{c}_votes.csv'))):
                pid = icpsr.get(str(int(float(v['icpsr']))))
                pos = POS.get(int(float(v['cast_code'])))
                r = rolls.get(v['rollnumber'])
                if not pid or not pos or not r:
                    continue
                bm = BILL_RE.match((r['bill_number'] or '').strip())
                if r['bill_number'] and not bm:
                    unknown_bill[re.sub(r'\d+', '#', r['bill_number'])] += 1
                key = f'{c}-{bm.group(1)}-{bm.group(2)}' if bm else None
                if v['rollnumber'] not in seen:
                    seen.add(v['rollnumber'])
                    rc += 1
                    nobill += key is None
                q = ': '.join(x for x in [r['vote_question'], r['vote_desc']] if x)
                fo.write('\t'.join(esc(x) for x in [
                    f"voteview-{c}-S-{int(v['rollnumber'])}", pid, key, c, q, pos,
                    datetime.date.fromisoformat(r['date']).isoformat(),
                    'failed' if FAIL_RE.search(r['vote_result'] or '') else 'passed',
                    r['yea_count'], r['nay_count']]) + '\n')
                n += 1
    print(f'members already loaded (skipped): {len(skipped_members)}; roll calls with a linkable senator: {rc} '
          f'({nobill} with no bill link); vote rows: {n}; unrecognised bill labels: {dict(unknown_bill.most_common(8))}')
    commit = '--commit' in sys.argv
    with open(os.path.join(out, 'senate_votes.sql'), 'w') as f:
        f.write(SQL.format(out=out, commit='true' if commit else 'false'))
    if commit or '--rehearse' in sys.argv:
        run_psql(['psql', os.environ['DATABASE_URL'], '-X', '-f', os.path.join(out, 'senate_votes.sql')])
    else:
        print('files only; database not touched')


if __name__ == '__main__':
    main()
