"""pytest for local_pilot_sample.py: seeded, stratified, state-spread draw of the local-official pilot.
Fixture rosters only; the real roster is never read here."""
import csv, math, os, subprocess, sys
import pytest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import local_pilot_sample as lps

COLS = ['politician_id', 'full_name', 'office_id', 'level', 'state', 'scope', 'leaving', 'race_ids', 'office']
SHARE = {'CA': 120, 'UT': 60, 'IN': 50, 'TX': 40, 'WI': 30}  # per-stratum people spread over states


def roster_rows():
    rows, n = [], 0
    titles = {'council-and-mayor': ['Council Member, District 3', 'Mayor', 'Alder', 'Selectman'],
              'county': ['County Commissioner', 'Board of Supervisors', 'Judge/Executive'],
              'sheriff': ['Sheriff'], 'other': ['Coroner', 'Tax Collector', 'Constable']}
    pools = {'council-and-mayor': 140, 'county': 90, 'sheriff': 25, 'other': 120}
    states = list(SHARE)
    for st, total in pools.items():
        for i in range(total):
            n += 1; ti = titles[st]
            rows.append({'politician_id': f'p{n:04d}', 'full_name': f'Person {n}', 'office_id': f'o{n}', 'level': 'local',
                         'state': states[i % 5] if i % 3 else 'CA', 'scope': 'sitting', 'leaving': '', 'race_ids': '', 'office': ti[i % len(ti)]})
    rows.append({'politician_id': 'fed1', 'full_name': 'Fed', 'office_id': 'o', 'level': 'federal', 'state': 'CA', 'scope': 'sitting', 'leaving': '', 'race_ids': '', 'office': 'Senator'})
    return rows


def write_roster(path, rows):
    with open(path, 'w', newline='') as f:
        w = csv.DictWriter(f, COLS, delimiter='\t'); w.writeheader(); w.writerows(rows)


def run(roster, out, extra=()):
    return subprocess.run([sys.executable, '-I', os.path.join(HERE, 'local_pilot_sample.py'), '--roster', str(roster), '--out', str(out), *extra],
                          capture_output=True, text=True)


@pytest.fixture
def setup(tmp_path):
    r = tmp_path / 'roster.tsv'; write_roster(r, roster_rows())
    out = tmp_path / 'out'; out.mkdir(); (out / 'seed.txt').write_text('seed-one\n')
    return r, out


def sample(out): return list(csv.DictReader(open(out / 'sample.tsv'), delimiter='\t'))


def test_missing_seed_exits_2_and_writes_nothing(tmp_path):
    r = tmp_path / 'roster.tsv'; write_roster(r, roster_rows()); out = tmp_path / 'out'
    p = run(r, out)
    assert p.returncode == 2 and 'seed.txt' in p.stderr
    assert not (out / 'sample.tsv').exists()


def test_same_seed_same_sample_and_other_seed_differs(setup, tmp_path):
    r, out = setup
    assert run(r, out).returncode == 0
    a = open(out / 'sample.tsv').read()
    assert run(r, out).returncode == 0 and open(out / 'sample.tsv').read() == a
    out2 = tmp_path / 'out2'; out2.mkdir(); (out2 / 'seed.txt').write_text('seed-two')
    assert run(r, out2).returncode == 0 and open(out2 / 'sample.tsv').read() != a


def test_sample_is_100_unique_local_with_columns(setup):
    r, out = setup; assert run(r, out).returncode == 0
    s = sample(out)
    assert list(s[0]) == ['politician_id', 'full_name', 'state', 'office', 'stratum']
    assert len(s) == 100 and len({x['politician_id'] for x in s}) == 100 and 'fed1' not in {x['politician_id'] for x in s}


def test_each_stratum_at_least_10(setup):
    r, out = setup; run(r, out); s = sample(out)
    for st in lps.STRATA: assert sum(x['stratum'] == st for x in s) >= 10, st


def test_small_stratum_takes_what_the_pool_has(tmp_path):
    rows = [x for x in roster_rows() if x['office'] != 'Sheriff']
    sheriffs = [dict(x, politician_id=f's{i}', office='Sheriff') for i, x in enumerate(roster_rows()[:6])]
    r = tmp_path / 'r.tsv'; write_roster(r, rows + sheriffs); out = tmp_path / 'o'; out.mkdir(); (out / 'seed.txt').write_text('x')
    assert run(r, out).returncode == 0
    assert sum(x['stratum'] == 'sheriff' for x in sample(out)) == 6


def test_california_capped_at_pool_share_rounded_up(setup):
    r, out = setup; run(r, out)
    rows = [x for x in roster_rows() if x['level'] == 'local']
    cap = math.ceil(sum(x['state'] == 'CA' for x in rows) / len(rows) * 100)
    assert sum(x['state'] == 'CA' for x in sample(out)) <= cap


def test_no_state_over_share_plus_one(setup):
    r, out = setup; run(r, out)
    rows = [x for x in roster_rows() if x['level'] == 'local']; s = sample(out)
    for st in {x['state'] for x in rows}:
        share = sum(x['state'] == st for x in rows) / len(rows) * 100
        assert sum(x['state'] == st for x in s) <= math.ceil(share) + 1, st


def test_duplicate_politician_keeps_first_and_is_reported(setup):
    r, out = setup
    rows = roster_rows(); dup = dict(rows[0], office_id='other', office='Sheriff'); rows.insert(5, dup); write_roster(r, rows)
    assert run(r, out).returncode == 0
    md = open(out / 'strata.md').read()
    assert 'duplicate' in md.lower() and '1' in md
    first = [x for x in sample(out) if x['politician_id'] == rows[0]['politician_id']]
    assert all(x['office'] == rows[0]['office'] for x in first)


def test_blank_and_unknown_title_go_to_other():
    for t in ('', '   ', 'Zzyzx Warden'): assert lps.stratum(t) == 'other'


@pytest.mark.parametrize('title,want', [
    ('Council Member, At Large', 'council-and-mayor'), ('MAYOR', 'council-and-mayor'), ('Board of Aldermen', 'council-and-mayor'),
    ('Selectman', 'council-and-mayor'), ('Town Board Member', 'council-and-mayor'), ('City Commissioner, Ward 2', 'council-and-mayor'),
    ('County Commissioner', 'county'), ('Commissioner, District 5', 'county'), ('Board of Supervisors', 'county'),
    ('County Judge/Executive', 'county'), ('Fiscal Court Commissioner', 'county'), ('County Council Member', 'county'),
    ('Sheriff', 'sheriff'), ('County Sheriff', 'sheriff'),
    ('Supervisor of Elections', 'other'), ('Soil and Water Conservation District Commissioner', 'other'),
    ('School Board Member', 'other'), ('Coroner', 'other')])
def test_stratum_keywords(title, want): assert lps.stratum(title) == want


def test_strata_md_has_pool_and_sample_counts(setup):
    r, out = setup; run(r, out); md = open(out / 'strata.md').read()
    for st in lps.STRATA: assert st in md
    assert 'CA' in md and 'pool' in md.lower() and 'sample' in md.lower()


def run_flags(roster, out, *extra): return run(roster, out, extra)


def blank_roster(tmp_path, blank_n, total_other=120):
    rows = roster_rows(); k = 0
    for x in rows:
        if x['stratum_hint' if False else 'level'] == 'local' and x['office'] in ('Coroner', 'Tax Collector', 'Constable') and k < blank_n:
            x['office'] = ''; k += 1
    r = tmp_path / 'blank.tsv'; write_roster(r, rows); return r, rows


def mkout(tmp_path, name='o'):
    out = tmp_path / name; out.mkdir(); (out / 'seed.txt').write_text('s'); return out


def test_blank_titles_over_10_percent_exit_3(tmp_path):
    r, _ = blank_roster(tmp_path, 60); out = mkout(tmp_path)
    p = run(r, out)
    assert p.returncode == 3 and 'blank' in p.stderr.lower() and '--offices' in p.stderr
    assert not (out / 'sample.tsv').exists()


def test_allow_blank_titles_overrides_and_strata_md_says_so(tmp_path):
    r, _ = blank_roster(tmp_path, 60); out = mkout(tmp_path)
    assert run(r, out, ['--allow-blank-titles']).returncode == 0
    md = open(out / 'strata.md').read()
    assert 'Blank titles' in md and '60' in md and '--allow-blank-titles' in md


def test_blank_count_and_share_printed_when_under_threshold(setup):
    r, out = setup; run(r, out); md = open(out / 'strata.md').read()
    assert 'Blank titles after merge: 0 of' in md and '0.0%' in md


def test_offices_file_fills_blank_and_wins_over_roster(tmp_path):
    r, rows = blank_roster(tmp_path, 60)
    blanks = [x['politician_id'] for x in rows if x['office'] == '']
    off = tmp_path / 'offices.tsv'
    with open(off, 'w') as f:
        f.write('politician_id\toffice\n')
        for p in blanks: f.write(f'{p}\tCity Council Member\n')
        f.write(f"{rows[0]['politician_id']}\tSheriff\n")  # overrides a titled roster row
    out = mkout(tmp_path)
    assert run(r, out, ['--offices', str(off)]).returncode == 0
    md = open(out / 'strata.md').read()
    assert 'Blank titles after merge: 0 of' in md
    pool, _ = lps.read_pool(str(r), str(off))
    got = {p['politician_id']: p for p in pool}
    assert all(got[b]['stratum'] == 'council-and-mayor' for b in blanks)
    assert got[rows[0]['politician_id']]['office'] == 'Sheriff' and got[rows[0]['politician_id']]['stratum'] == 'sheriff'


def test_blank_offices_row_does_not_erase_roster_title(tmp_path):
    rows = roster_rows(); off = tmp_path / 'o.tsv'
    off.write_text(f"politician_id\toffice\n{rows[0]['politician_id']}\t\n")
    r = tmp_path / 'r.tsv'; write_roster(r, rows)
    pool, _ = lps.read_pool(str(r), str(off))
    assert pool[0]['office'] == rows[0]['office']


def test_duplicate_prefers_first_non_blank_office(tmp_path):
    rows = roster_rows(); first = rows[0]
    blank = dict(first, office_id='b', office=''); titled = dict(first, office_id='t', office='Sheriff')
    r = tmp_path / 'r.tsv'; write_roster(r, [blank, titled, dict(first, office_id='z', office='Mayor')] + rows[1:])
    pool, dups = lps.read_pool(str(r))
    me = [p for p in pool if p['politician_id'] == first['politician_id']]
    assert len(me) == 1 and me[0]['office'] == 'Sheriff' and dups == 2


@pytest.mark.parametrize('title,want', [
    ('Fiscal Court Magistrate', 'county'), ('County Judge', 'county'), ('County Judge/Executive', 'county'), ('Commissioners Court', 'county'),
    ('Freeholder', 'county'), ('Police Jury', 'county'), ('Village President', 'council-and-mayor'),
    ('Parkville City Council', 'council-and-mayor'), ('Park District Commissioner', 'other'), ('Clerk of Court', 'other'),
    ('Magistrate, District 1', 'other')])
def test_keyword_gaps(title, want): assert lps.stratum(title) == want


def test_california_cap_binds(tmp_path):
    rows, n = [], 0
    def add(count, office, ca):
        nonlocal n
        for i in range(count):
            n += 1; rows.append({'politician_id': f'c{n:04d}', 'full_name': f'P{n}', 'office_id': 'o', 'level': 'local',
                                 'state': 'CA' if i < ca else 'UT', 'scope': 'sitting', 'leaving': '', 'race_ids': '', 'office': office})
    add(30, 'Sheriff', 30); add(30, 'County Commissioner', 30); add(130, 'Mayor', 30); add(130, 'Coroner', 30)
    cap = math.ceil(120 / 320 * 100)
    pool, _ = lps.read_pool(str(_write(tmp_path, rows)))
    for seed in ('a', 'b', 'c', 'd'):
        chosen, *_ = lps.draw(pool, 100, seed)
        assert sum(p['state'] == 'CA' for p in chosen) == cap  # binds: CA fills exactly to the cap


def _write(tmp_path, rows):
    r = tmp_path / 'ca.tsv'; write_roster(r, rows); return r
