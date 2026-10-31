#!/usr/bin/env python3 -I
"""Apply a federal-bills reload (108th-119th from govinfo BILLSTATUS) to essentials.

Takes the bills.ndjson written by federal_bills_dryrun.py and builds a psql script.
By DEFAULT it only writes files (nothing touches the database).

  federal_bills_apply.py <out_dir>                 write apply.sql + TSV files, stop
  federal_bills_apply.py <out_dir> --rehearse      also run it against $DATABASE_URL
                                                   inside a transaction that ROLLS BACK
  federal_bills_apply.py <out_dir> --commit        run it and COMMIT (production write)

Steps (one transaction): add sessions 102nd-118th; relabel the pre-108th rows to
their real Congress; delete the 108th-119th federal rows and their cosponsors; load
bills + linked cosponsors from the bulk data; add bioguide id-map rows.
Backups of the federal rows are written to <out_dir>/backup before the transaction.
Party is never stored. Members with no politician row stay unlinked.
"""
import os, subprocess, sys, json

SEP = '\x1f'  # joins topic tags inside one TSV field


def esc(v):
    """COPY text-format escaping; None -> \\N."""
    if v is None or v == '':
        return '\\N'
    return str(v).replace('\\', '\\\\').replace('\t', '\\t').replace('\n', '\\n').replace('\r', '\\r')


def write_tsv(out):
    nb = nc = 0
    with open(os.path.join(out, 'bills.ndjson')) as f, \
            open(os.path.join(out, 'stg_bills.tsv'), 'w') as fb, \
            open(os.path.join(out, 'stg_cos.tsv'), 'w') as fc:
        for line in f:
            r = json.loads(line)
            fb.write('\t'.join(esc(x) for x in [
                r['external_id'], r['congress'], r['number'], r['title'], r['summary'],
                r['raw_status'], r['status_label'], r['introduced_at'],
                r['passed_at'] if r['status_label'] in ('Passed', 'Signed') else '',
                r['signed_at'], SEP.join(r['topic_tags']), r['url'], r['sponsor_bioguide'],
            ]) + '\n')
            nb += 1
            for g in r['cosponsor_bioguides']:
                fc.write(f"{esc(r['external_id'])}\t{esc(g)}\n")
                nc += 1
    return nb, nc


SQL = r"""\set ON_ERROR_STOP on
\timing off
\echo '== backups'
\copy (select * from essentials.legislative_bills where jurisdiction='federal' and source='congress') to '{bk}/bills.copy'
\copy (select c.* from essentials.legislative_bill_cosponsors c join essentials.legislative_bills b on b.id=c.bill_id where b.jurisdiction='federal' and b.source='congress') to '{bk}/cosponsors.copy'
\copy (select * from essentials.legislative_politician_id_map where id_type='bioguide') to '{bk}/id_map_bioguide.copy'
\copy (select * from essentials.legislative_sessions where jurisdiction='federal') to '{bk}/sessions.copy'

BEGIN;

create temp table stg_bills (
  external_id text, congress int, number text, title text, summary text, raw_status text,
  status_label text, introduced_at date, passed_at date, signed_at date, tags text,
  url text, sponsor_bioguide text) on commit drop;
create temp table stg_cos (external_id text, bioguide text) on commit drop;
\copy stg_bills from '{out}/stg_bills.tsv'
\copy stg_cos from '{out}/stg_cos.tsv'

-- sessions 102nd..118th (the 119th row already exists)
insert into essentials.legislative_sessions (jurisdiction, name, start_date, end_date, is_current, external_id, source)
select 'federal',
  c || case when c % 100 between 11 and 13 then 'th' else case c % 10 when 1 then 'st' when 2 then 'nd' when 3 then 'rd' else 'th' end end || ' Congress',
  make_timestamptz(1789 + 2*(c-1), 1, 3, 0, 0, 0, 'UTC'),
  make_timestamptz(1789 + 2*c, 1, 3, 0, 0, 0, 'UTC'),
  false, c::text, 'congress'
from generate_series(102, 118) c
where not exists (select 1 from essentials.legislative_sessions s where s.jurisdiction='federal' and s.external_id=c::text);

-- the mislabeled rows: real congress/type/number come from the url
create temp table old_rows on commit drop as
select b.id, m[1]::int as congress, upper(m[2]) as btype, m[3] as num
from essentials.legislative_bills b,
     lateral regexp_match(b.url, '/bill/(\d+)/([a-z]+)/(\d+)') m
where b.jurisdiction='federal' and b.source='congress' and m is not null;

\echo '== rows with a non-bill url (deleted below; expect 1)'
select count(*) from essentials.legislative_bills b
where b.jurisdiction='federal' and b.source='congress' and b.id not in (select id from old_rows);

-- rows whose url is not a bill (an amendment stub saved as a bill, blank number): remove them
delete from essentials.legislative_bill_cosponsors where bill_id in (
  select b.id from essentials.legislative_bills b where b.jurisdiction='federal' and b.source='congress' and b.id not in (select id from old_rows));
delete from essentials.legislative_bills where jurisdiction='federal' and source='congress' and id not in (select id from old_rows);

-- keep + relabel pre-108th
update essentials.legislative_bills b
set external_id = o.congress || '-' || o.btype || '-' || o.num,
    session_id = (select s.id from essentials.legislative_sessions s where s.jurisdiction='federal' and s.external_id=o.congress::text),
    url = 'https://www.congress.gov/bill/' || o.congress ||
      case when o.congress % 100 between 11 and 13 then 'th' else case o.congress % 10 when 1 then 'st' when 2 then 'nd' when 3 then 'rd' else 'th' end end ||
      '-congress/' || case lower(o.btype) when 'hr' then 'house-bill' when 's' then 'senate-bill' when 'hjres' then 'house-joint-resolution'
        when 'sjres' then 'senate-joint-resolution' when 'hres' then 'house-resolution' when 'sres' then 'senate-resolution'
        when 'hconres' then 'house-concurrent-resolution' else 'senate-concurrent-resolution' end || '/' || o.num
from old_rows o where o.id = b.id and o.congress < 108;

-- delete 108th-119th rows and their cosponsors
delete from essentials.legislative_bill_cosponsors where bill_id in (select id from old_rows where congress >= 108);
delete from essentials.legislative_bills where id in (select id from old_rows where congress >= 108);

-- bioguide -> politician, only when unambiguous
create temp table bg on commit drop as
select bioguide, min(pid::text)::uuid as pid from (
  select bioguide_id as bioguide, id as pid from essentials.politicians where bioguide_id is not null and bioguide_id <> ''
  union
  select id_value, politician_id from essentials.legislative_politician_id_map where id_type='bioguide') x
group by bioguide having count(distinct pid) = 1;

insert into essentials.legislative_bills
  (session_id, external_id, jurisdiction, number, title, summary, raw_status, status_label, sponsor_id,
   introduced_at, passed_at, signed_at, topic_tags, url, source)
select s.id, b.external_id, 'federal', b.number, b.title, b.summary, b.raw_status, b.status_label, bg.pid,
  b.introduced_at, b.passed_at, b.signed_at,
  case when b.tags is null then null else string_to_array(b.tags, E'\x1f') end, b.url, 'congress'
from stg_bills b
join essentials.legislative_sessions s on s.jurisdiction='federal' and s.external_id=b.congress::text
left join bg on bg.bioguide = b.sponsor_bioguide;

insert into essentials.legislative_bill_cosponsors (bill_id, politician_id)
select distinct lb.id, bg.pid
from stg_cos c
join essentials.legislative_bills lb on lb.external_id=c.external_id and lb.jurisdiction='federal'
join bg on bg.bioguide=c.bioguide
on conflict do nothing;

-- id map: bioguide ids we hold on politicians but not yet in the map
insert into essentials.legislative_politician_id_map (politician_id, id_type, id_value, verified_at, source)
select bg.pid, 'bioguide', bg.bioguide, now(), 'congress-bulk'
from bg
where exists (select 1 from essentials.politicians p where p.id=bg.pid and p.bioguide_id=bg.bioguide)
on conflict do nothing;

\echo '== results (inside the transaction)'
select 'federal bills' as what, count(*) from essentials.legislative_bills where jurisdiction='federal'
union all select 'federal bills with sponsor', count(*) from essentials.legislative_bills where jurisdiction='federal' and sponsor_id is not null
union all select 'federal bills with empty title', count(*) from essentials.legislative_bills where jurisdiction='federal' and (title is null or title='')
union all select 'federal cosponsor rows', count(*) from essentials.legislative_bill_cosponsors c join essentials.legislative_bills b on b.id=c.bill_id where b.jurisdiction='federal'
union all select 'bioguide id-map rows', count(*) from essentials.legislative_politician_id_map where id_type='bioguide'
union all select 'federal sessions', count(*) from essentials.legislative_sessions where jurisdiction='federal'
union all select 'bills whose number looks wrong', count(*) from essentials.legislative_bills where jurisdiction='federal' and external_id !~ '^\d+-[A-Z]+-\d+$';
select s.external_id as congress, count(*) from essentials.legislative_bills b join essentials.legislative_sessions s on s.id=b.session_id
where b.jurisdiction='federal' group by 1 order by 1::int;

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
    commit = '--commit' in sys.argv
    rehearse = '--rehearse' in sys.argv
    bk = os.path.join(out, 'backup')
    os.makedirs(bk, exist_ok=True)
    nb, nc = write_tsv(out)
    with open(os.path.join(out, 'apply.sql'), 'w') as f:
        f.write(SQL.format(bk=bk, out=out, commit='true' if commit else 'false'))
    print(f'wrote {out}/apply.sql, {nb} bills, {nc} cosponsor links (before matching)')
    if commit or rehearse:
        subprocess.run(['psql', os.environ['DATABASE_URL'], '-X', '-f', os.path.join(out, 'apply.sql')], check=True)
    else:
        print('files only; database not touched')


if __name__ == '__main__':
    main()
