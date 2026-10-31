#!/usr/bin/env python3 -I
"""Fill in title, summary, topic tags and sponsor for the federal bills from the
102nd-107th Congress (no govinfo bulk files exist for them) using api.congress.gov.

  federal_bills_enrich_old.py <out_dir>             fetch from the API, write files only
  federal_bills_enrich_old.py <out_dir> --rehearse  also run the UPDATE, then ROLL BACK
  federal_bills_enrich_old.py <out_dir> --commit    run the UPDATE and COMMIT

Needs DATABASE_URL and CONGRESS_GOV_API_KEY. Reads the DB with SELECTs only until
--rehearse/--commit. Only fills empty fields; party and names are never stored.
Fetch results are cached in <out_dir>/old_enriched.ndjson, so a rerun resumes.
"""
import json, os, re, subprocess, sys, time

def run_psql(cmd, **kw):
    """subprocess.run for psql that never prints the command (it holds the DB password)."""
    try:
        return subprocess.run(cmd, check=True, **kw)
    except subprocess.CalledProcessError as e:
        sys.exit(f'psql failed (exit {e.returncode}); see output above')


API = 'https://api.congress.gov/v3'
SEP = '\x1f'


def psql(sql, **kw):
    return run_psql(['psql', os.environ['DATABASE_URL'], '-X', '-A', '-t', '-F', '\t', '-c', sql],
                          capture_output=True, text=True, **kw).stdout


def get(path, key):
    """GET via curl: the API 403s Python's default client headers but serves curl."""
    url = f'{API}{path}{"&" if "?" in path else "?"}format=json&api_key={key}'
    last = None
    for attempt in range(4):
        r = subprocess.run(['curl', '-s', '--compressed', '-m', '30', '-w', '\n%{http_code}', url],
                           capture_output=True, text=True)
        body, _, code = r.stdout.rpartition('\n')
        if code == '200':
            return json.loads(body)
        if code == '404':
            return None
        last = f'HTTP {code}'
        time.sleep(2 ** attempt)
    raise RuntimeError(f'API failed: {path}: {last}')


def strip_html(s):
    s = re.sub(r'<[^>]+>', ' ', s or '')
    s = s.replace('&nbsp;', ' ').replace('&amp;', '&').replace('&quot;', '"').replace('&#39;', "'")
    return re.sub(r'\s+', ' ', s).strip()


def esc(v):
    if v is None or v == '':
        return '\\N'
    return str(v).replace('\\', '\\\\').replace('\t', '\\t').replace('\n', '\\n').replace('\r', '\\r')


def fetch(out):
    key = os.environ['CONGRESS_GOV_API_KEY']
    rows = [l.split('\t')[0] for l in psql(
        "select external_id from essentials.legislative_bills where jurisdiction='federal' and source='congress' "
        "and (title is null or title='') and substring(external_id from '^\\d+')::int < 108 order by 1").splitlines() if l]
    path = os.path.join(out, 'old_enriched.ndjson')
    done = set()
    if os.path.exists(path):
        done = {json.loads(l)['external_id'] for l in open(path)}
    todo = [e for e in rows if e not in done]
    print(f'{len(rows)} rows to fill, {len(done)} already fetched, {len(todo)} to fetch', flush=True)
    with open(path, 'a') as f:
        for i, e in enumerate(todo, 1):
            c, t, n = e.split('-')
            base = f'/bill/{c}/{t.lower()}/{n}'
            d = get(base, key)
            b = (d or {}).get('bill')
            rec = {'external_id': e, 'found': bool(b)}
            if b:
                sums = (get(base + '/summaries', key) or {}).get('summaries', [])
                sums.sort(key=lambda s: s.get('updateDate', ''))
                subj = (get(base + '/subjects', key) or {}).get('subjects', {})
                tags = []
                for nme in [(b.get('policyArea') or {}).get('name')] + \
                           [x.get('name') for x in subj.get('legislativeSubjects', [])]:
                    if nme and nme not in tags:
                        tags.append(nme)
                sp = (b.get('sponsors') or [{}])[0]
                rec.update(title=b.get('title') or '', summary=strip_html(sums[-1].get('text'))[:4000] if sums else '',
                           tags=tags[:10], sponsor_bioguide=sp.get('bioguideId') or '')
            f.write(json.dumps(rec) + '\n')
            f.flush()
            if i % 50 == 0:
                print(f'  {i}/{len(todo)}', flush=True)
            time.sleep(0.15)
    return path


SQL = r"""\set ON_ERROR_STOP on
BEGIN;
create temp table stg_old (external_id text, title text, summary text, tags text, sponsor_bioguide text) on commit drop;
\copy stg_old from '{out}/stg_old.tsv'
create temp table bg on commit drop as
select bioguide, min(pid::text)::uuid as pid from (
  select bioguide_id as bioguide, id as pid from essentials.politicians where bioguide_id is not null and bioguide_id <> ''
  union
  select id_value, politician_id from essentials.legislative_politician_id_map where id_type='bioguide') x
group by bioguide having count(distinct pid) = 1;
update essentials.legislative_bills b
set title = coalesce(nullif(b.title, ''), s.title),
    summary = coalesce(nullif(b.summary, ''), s.summary),
    topic_tags = case when b.topic_tags is null or cardinality(b.topic_tags) = 0
                      then string_to_array(s.tags, E'\x1f') else b.topic_tags end,
    sponsor_id = coalesce(b.sponsor_id, bg.pid)
from stg_old s left join bg on bg.bioguide = s.sponsor_bioguide
where b.external_id = s.external_id and b.jurisdiction = 'federal';
\echo '== results (inside the transaction)'
select count(*) filter (where title is null or title='') as still_empty_title,
       count(*) filter (where sponsor_id is not null) as with_sponsor,
       count(*) filter (where summary is not null and summary<>'') as with_summary, count(*) as pre108_rows
from essentials.legislative_bills where jurisdiction='federal' and substring(external_id from '^\d+')::int < 108;
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
    path = fetch(out)
    recs = [json.loads(l) for l in open(path)]
    ok = [r for r in recs if r['found']]
    print(f'fetched {len(recs)}; found {len(ok)}; not found {len(recs) - len(ok)}')
    with open(os.path.join(out, 'stg_old.tsv'), 'w') as f:
        for r in ok:
            f.write('\t'.join(esc(x) for x in [r['external_id'], r['title'], r['summary'],
                                                SEP.join(r['tags']), r['sponsor_bioguide']]) + '\n')
    commit = '--commit' in sys.argv
    with open(os.path.join(out, 'enrich_old.sql'), 'w') as f:
        f.write(SQL.format(out=out, commit='true' if commit else 'false'))
    if commit or '--rehearse' in sys.argv:
        run_psql(['psql', os.environ['DATABASE_URL'], '-X', '-f', os.path.join(out, 'enrich_old.sql')])
    else:
        print('files only; database not touched')


if __name__ == '__main__':
    main()
