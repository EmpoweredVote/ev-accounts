#!/usr/bin/env python3 -I
"""Gap report: are the sitting members of Congress connected to our politician rows?
READ ONLY. Run it after each election, after a Congress is sworn in (January), and
before re-running the federal bill and vote loaders.

  federal_link_gaps.py <out_dir> [--congress 119]

Needs DATABASE_URL and CONGRESS_GOV_API_KEY. Compares congress.gov's current-member list
(api.congress.gov /v3/member/congress/<n>?currentMember=true) with the politicians who
hold a current U.S. House / U.S. Senate term in essentials. Writes <out_dir>/gaps.md and
gaps.json, and prints the summary. No party is read or written.

Sections:
  A  official current members with NO politician row carrying their bioguide id
  B  our sitting House/Senate holders with NO bioguide id (fix with federal-bioguide-backfill.ts)
  C  our holders whose bioguide id is NOT on the official current list (stale term or wrong id)
Fix order after A/B: run federal-bioguide-backfill.ts, then the three vote loaders (each adds
only new members) and federal_votes_legiscan.py --congress N --refresh for new roll calls.
"""
import json, os, subprocess, sys


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


def official(congress, key):
    members, offset = [], 0
    while True:
        url = (f'https://api.congress.gov/v3/member/congress/{congress}?currentMember=true'
               f'&limit=250&offset={offset}&format=json&api_key={key}')
        r = subprocess.run(['curl', '-s', '--compressed', '-m', '60', '-w', '\n%{http_code}', url],
                           capture_output=True, text=True)
        body, _, code = r.stdout.rpartition('\n')
        if code != '200':
            sys.exit(f'congress.gov returned HTTP {code} at offset {offset}')
        page = json.loads(body).get('members', [])
        members += page
        if len(page) < 250:
            return members
        offset += 250


def main():
    out = os.path.abspath(sys.argv[1])
    congress = sys.argv[sys.argv.index('--congress') + 1] if '--congress' in sys.argv else '119'
    os.makedirs(out, exist_ok=True)
    off = {}
    for m in official(congress, os.environ['CONGRESS_GOV_API_KEY']):
        terms = (m.get('terms') or {}).get('item') or []
        now = next((t for t in terms if not t.get('endYear')), None)
        if not now:
            continue  # no open term: not serving now
        off[m['bioguideId']] = {'bioguide': m['bioguideId'], 'name': m.get('name'), 'state': m.get('state'),
                                'district': m.get('district'),
                                'chamber': 'Senate' if 'senate' in (now.get('chamber') or '').lower() else 'House'}
    have = {}
    for pid, bio in psql("select id, bioguide_id from essentials.politicians where bioguide_id is not null and bioguide_id <> ''"):
        have.setdefault(bio, []).append(pid)
    holders = psql(
        "select p.id, p.full_name, c.name, coalesce(p.bioguide_id,'') from essentials.office_terms t "
        "join essentials.offices o on o.id=t.office_id join essentials.chambers c on c.id=o.chamber_id "
        "join essentials.governments g on g.id=c.government_id join essentials.politicians p on p.id=t.politician_id "
        "where g.type='NATIONAL' and c.name in ('U.S. House of Representatives','U.S. Senate') "
        "and (t.term_end is null or t.term_end > now()) order by c.name, p.full_name")
    a = [m for b, m in sorted(off.items()) if b not in have]
    b_ = [{'id': i, 'name': n, 'chamber': c} for i, n, c, bio in holders if not bio]
    c_ = [{'id': i, 'name': n, 'chamber': c, 'bioguide': bio} for i, n, c, bio in holders if bio and bio not in off]
    res = {'congress': congress, 'official_current_members': len(off), 'our_sitting_holders': len(holders),
           'A_official_without_politician_id': a, 'B_our_holders_without_id': b_, 'C_our_ids_not_on_official_list': c_}
    json.dump(res, open(os.path.join(out, 'gaps.json'), 'w'), indent=1)
    L = [f'# Federal member link gaps ({congress}th Congress)', '',
         f'- Official current members: {len(off)}',
         f'- Our sitting House/Senate holders: {len(holders)}',
         f'- A. Official members with no politician carrying their id: **{len(a)}**',
         f'- B. Our sitting holders with no bioguide id: **{len(b_)}**',
         f'- C. Our ids not on the official current list: **{len(c_)}**', '']
    for title, rows, fmt in [
            ('A. Official members missing from our politicians (add the person, or fix the id)', a,
             lambda r: f"{r['name']} ({r['chamber']}, {r['state']}{'-' + str(r['district']) if r['district'] else ''}) {r['bioguide']}"),
            ('B. Our sitting holders with no bioguide id (run federal-bioguide-backfill.ts)', b_,
             lambda r: f"{r['name']} ({r['chamber']}) {r['id']}"),
            ('C. Our bioguide ids not on the official current list (stale term or wrong id)', c_,
             lambda r: f"{r['name']} ({r['chamber']}) {r['bioguide']} {r['id']}")]:
        L += [f'## {title}', ''] + ([f'- {fmt(r)}' for r in rows] or ['- none']) + ['']
    open(os.path.join(out, 'gaps.md'), 'w').write('\n'.join(L))
    print('\n'.join(L[:8]))
    print(f'full report: {out}/gaps.md')


if __name__ == '__main__':
    main()
