#!/usr/bin/env python3 -I
"""Load federal roll-call votes (115th-119th Congress, House and Senate) from the
LegiScan US bulk dataset into essentials.legislative_votes.

  federal_votes_legiscan.py <legiscan_ds_dir> <out_dir>             write files only
  federal_votes_legiscan.py <legiscan_ds_dir> <out_dir> --rehearse  run, then ROLL BACK
  federal_votes_legiscan.py <legiscan_ds_dir> <out_dir> --commit    run and COMMIT

Needs DATABASE_URL. Replaces the 804 older federal-session votes (mis-filed Senate rows) with the full
set; refuses to run twice. Only members who match a politician row are loaded (by bioguide id, else by
a LegiScan id in legislative_politician_id_map); other members are skipped, no people
are created. The bill link comes from the LegiScan bill number, matched to
legislative_bills.external_id (<congress>-<TYPE>-<n>); unmatched roll calls keep a
null bill_id. Party is never stored.
"""
import collections, glob, json, os, re, subprocess, sys

def run_psql(cmd, **kw):
    """subprocess.run for psql that never prints the command (it holds the DB password)."""
    try:
        return subprocess.run(cmd, check=True, **kw)
    except subprocess.CalledProcessError as e:
        sys.exit(f'psql failed (exit {e.returncode}); see output above')


# LegiScan bill-number prefix -> congress.gov type
TYPE_MAP = {'HB': 'HR', 'HR': 'HRES', 'HJR': 'HJRES', 'HCR': 'HCONRES',
            'SB': 'S', 'SR': 'SRES', 'SJR': 'SJRES', 'SCR': 'SCONRES'}
POS = {'Yea': 'yea', 'Nay': 'nay', 'NV': 'not_voting', 'Absent': 'absent'}


def psql(sql):
    out = run_psql(['psql', os.environ['DATABASE_URL'], '-X', '-A', '-t', '-F', '\t', '-c', sql],
                         capture_output=True, text=True).stdout
    return [l.split('\t') for l in out.splitlines() if l]


def esc(v):
    if v is None or v == '':
        return '\\N'
    return str(v).replace('\\', '\\\\').replace('\t', '\\t').replace('\n', '\\n').replace('\r', '\\r')


SQL = r"""\set ON_ERROR_STOP on
\echo '== backup of existing federal-session votes (replaced below; they are mis-filed under the 119th)'
\copy (select * from essentials.legislative_votes where session_id in (select id from essentials.legislative_sessions where jurisdiction='federal')) to '{out}/existing_federal_votes.copy'
BEGIN;
set local statement_timeout = '15min';
delete from essentials.legislative_votes where session_id in (select id from essentials.legislative_sessions where jurisdiction='federal');
-- refuse to run twice (a per-row duplicate check is too slow on the big votes table)
do $$ begin
  if exists (select 1 from essentials.legislative_votes v join essentials.legislative_bills b on b.id = v.bill_id where b.jurisdiction = 'federal') then
    raise exception 'federal votes already loaded; refusing to insert again';
  end if;
end $$;
create temp table stg_votes (external_vote_id text, politician_id uuid, bill_key text, congress int,
  vote_question text, position text, vote_date date, result text, yea_count int, nay_count int) on commit drop;
\copy stg_votes from '{out}/stg_votes.tsv'
insert into essentials.legislative_votes
  (politician_id, bill_id, session_id, external_vote_id, vote_question, position, vote_date, result, yea_count, nay_count, source)
select s.politician_id, b.id, se.id, s.external_vote_id, s.vote_question, s.position, s.vote_date, s.result,
       s.yea_count, s.nay_count, 'legiscan'
from stg_votes s
join essentials.legislative_sessions se on se.jurisdiction='federal' and se.external_id=s.congress::text
left join essentials.legislative_bills b on b.jurisdiction='federal' and b.external_id=s.bill_key;
\echo '== results (inside the transaction)'
select count(*) as federal_votes, count(distinct politician_id) as members, count(distinct external_vote_id) as roll_calls,
       count(*) filter (where bill_id is null) as no_bill
from essentials.legislative_votes v where session_id in (select id from essentials.legislative_sessions where jurisdiction='federal');
select position, count(*) from essentials.legislative_votes
where session_id in (select id from essentials.legislative_sessions where jurisdiction='federal') group by 1 order by 2 desc;
\if {commit}
COMMIT;
\echo '== COMMITTED'
\else
ROLLBACK;
\echo '== ROLLED BACK (rehearsal; nothing persisted)'
\endif
"""


def main():
    ds, out = sys.argv[1], os.path.abspath(sys.argv[2])
    os.makedirs(out, exist_ok=True)
    # member -> politician
    bg = collections.defaultdict(set)
    for pid, g in psql("select id, bioguide_id from essentials.politicians where bioguide_id is not null and bioguide_id <> ''"):
        bg[g].add(pid)
    for pid, g in psql("select politician_id, id_value from essentials.legislative_politician_id_map where id_type='bioguide'"):
        bg[g].add(pid)
    lg = collections.defaultdict(set)
    for pid, v in psql("select politician_id, id_value from essentials.legislative_politician_id_map where id_type='legiscan'"):
        lg[v].add(pid)
    member = {}
    for f in glob.glob(os.path.join(ds, 'US-*/US/*/people/*.json')):
        p = json.load(open(f))['person']
        s = bg.get(p.get('bioguide_id') or '') or lg.get(str(p['people_id']))
        if s and len(s) == 1:
            member[p['people_id']] = next(iter(s))
    # LegiScan bill id -> our external_id
    bill_key = {}
    for f in glob.glob(os.path.join(ds, 'US-*/US/*/bill/*.json')):
        b = json.load(open(f))['bill']
        m = re.match(r'([A-Z]+)(\d+)$', b['bill_number'])
        c = re.match(r'(\d+)', b['session']['session_name'])
        if m and c and m.group(1) in TYPE_MAP:
            bill_key[b['bill_id']] = f'{c.group(1)}-{TYPE_MAP[m.group(1)]}-{m.group(2)}'
    n = rc = nobill = 0
    with open(os.path.join(out, 'stg_votes.tsv'), 'w') as fo:
        for f in sorted(glob.glob(os.path.join(ds, 'US-*/US/*/vote/*.json'))):
            r = json.load(open(f))['roll_call']
            congress = int(re.search(r'_(\d+)\w+_Congress', f).group(1))
            key = bill_key.get(r.get('bill_id'))
            mine = [v for v in r['votes'] if v['people_id'] in member and v['vote_text'] in POS]
            if not mine:
                continue
            rc += 1
            nobill += key is None
            for v in mine:
                fo.write('\t'.join(esc(x) for x in [
                    f"legiscan-{r['roll_call_id']}", member[v['people_id']], key, congress,
                    r['desc'], POS[v['vote_text']], (None if r['date'].startswith('0000') else r['date']), 'passed' if r['passed'] else 'failed',
                    r['yea'], r['nay']]) + '\n')
                n += 1
    print(f'members linkable: {len(member)}; roll calls with a linkable member: {rc} '
          f'({nobill} with no matching bill); vote rows: {n}')
    commit = '--commit' in sys.argv
    with open(os.path.join(out, 'votes.sql'), 'w') as f:
        f.write(SQL.format(out=out, commit='true' if commit else 'false'))
    if commit or '--rehearse' in sys.argv:
        run_psql(['psql', os.environ['DATABASE_URL'], '-X', '-f', os.path.join(out, 'votes.sql')])
    else:
        print('files only; database not touched')


if __name__ == '__main__':
    main()
