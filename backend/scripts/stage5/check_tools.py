"""Checks for the Stage 5 Python batch tools, on small made-up batches in a temporary folder. Each check pins one rule;
a tool is run as a subprocess, the way a batch runs it.
python3 -I scripts/stage5/check_tools.py [--tools <dir>]   (default: this folder; point it at a tampered copy to watch
a check fail). Exit 1 when any check fails. Needs no database, network or node_modules."""
import csv, glob, json, os, shutil, subprocess, sys, tempfile, traceback

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = sys.argv[sys.argv.index('--tools') + 1] if '--tools' in sys.argv else HERE
RU = 'source_url_'


def run(tool, *args, ok=True, env=None):
    p = subprocess.run([sys.executable, '-I', os.path.join(TOOLS, tool), *args], capture_output=True, text=True,
                       env={**{k: v for k, v in os.environ.items() if not k.startswith('LEGISCAN_')}, **(env or {})})
    if ok and p.returncode != 0: raise AssertionError(f'{tool} exit {p.returncode}: {p.stderr[-600:]}')
    return p


def write_csv(path, rows, cols=None):
    cols = cols or list(rows[0].keys())
    with open(path, 'w', newline='') as fh:
        w = csv.DictWriter(fh, fieldnames=cols); w.writeheader(); w.writerows(rows)


def read_csv(path): return list(csv.DictReader(open(path)))
def urls(r): return [r[c] for c in sorted((c for c in r if c.startswith(RU)), key=lambda c: int(c[len(RU):])) if r[c]]


def batch(tmp, people, research, evidence=None, ncols=2):
    """A batch folder: politicians.json, research.csv with ncols source_url_ columns, evidence.csv."""
    os.makedirs(tmp, exist_ok=True)
    json.dump([{'full_name': n, 'politician_id': p} for n, p in people], open(f'{tmp}/politicians.json', 'w'))
    cols = ['full_name', 'topic_key', 'evidence_type', 'reasoning'] + [f'{RU}{i}' for i in range(1, ncols + 1)]
    rows = []
    for r in research:
        row = {c: '' for c in cols}; row.update({k: v for k, v in r.items() if k != 'urls'})
        for i, u in enumerate(r.get('urls', [])): row[f'{RU}{i + 1}'] = u
        rows.append(row)
    write_csv(f'{tmp}/research.csv', rows, cols)
    write_csv(f'{tmp}/evidence.csv', evidence or [{'full_name': research[0]['full_name'], 'topic_key': 't', 'source_url': 'https://x/0', 'snippet': 's', 'snippet_index': '1'}],
              ['full_name', 'topic_key', 'source_url', 'snippet', 'snippet_index'])
    return tmp


CHECKS = []
def check(f): CHECKS.append(f); return f


@check
def legiscan_merge_grows_columns_for_any_row(t):
    """A row needing more source_url_ columns than the header has must not break the rows after it (it once KeyErrored)."""
    B = batch(t, [('Ann A', 'a'), ('Bob B', 'b')], [
        {'full_name': 'Ann A', 'topic_key': 't', 'evidence_type': 'record', 'urls': ['https://off/1', 'https://off/2']},
        {'full_name': 'Bob B', 'topic_key': 't', 'evidence_type': 'record', 'urls': ['https://off/3']}])
    os.makedirs(f'{B}/legiscan')
    needs = {'Ann A': [{'url': f'https://legiscan.com/XX/rollcall/HB1/id/{i}', 'official': 'https://off/9', 'act': 'yea'} for i in (1, 2)],
             'Bob B': [{'url': 'https://legiscan.com/XX/rollcall/HB1/id/1', 'official': 'https://off/3', 'act': 'nay'}]}
    json.dump(needs, open(f'{B}/legiscan/needs.json', 'w'))
    lines = [{'full_name': n, 'topic_key': 't', 'source_url': v['url'], 'snippet': f'roll call: {n.split()[1]} voted {"Yea" if v["act"] == "yea" else "Nay"}.', 'snippet_index': '1'} for n, vs in needs.items() for v in vs]
    write_csv(f'{B}/legiscan/legiscan-evidence.csv', lines)
    run('legiscan_merge.py', B, '--host', 'off')
    rows = {r['full_name']: r for r in read_csv(f'{B}/research.csv')}
    assert len(urls(rows['Ann A'])) == 4, urls(rows['Ann A'])
    assert urls(rows['Bob B']) == ['https://legiscan.com/XX/rollcall/HB1/id/1'], urls(rows['Bob B'])


@check
def legiscan_merge_lists_every_act_that_got_no_line(t):
    """A vote with no LegiScan line keeps its official page, and is listed in legiscan/no-line.json with its act."""
    B = batch(t, [('Ann A', 'a')], [{'full_name': 'Ann A', 'topic_key': 't', 'evidence_type': 'record', 'urls': ['https://off/1', 'https://off/2']}])
    os.makedirs(f'{B}/legiscan')
    rc = lambda i: f'https://legiscan.com/XX/rollcall/HB1/id/{i}'
    json.dump({'Ann A': [{'url': rc(1), 'official': 'https://off/1', 'act': 'yea', 'instrument': 'XX-HB-1-2025'},
                         {'url': rc(2), 'official': 'https://off/2', 'act': 'nay', 'instrument': 'XX-HB-1-2025'}]}, open(f'{B}/legiscan/needs.json', 'w'))
    write_csv(f'{B}/legiscan/legiscan-evidence.csv', [{'full_name': 'Ann A', 'topic_key': 't', 'source_url': rc(1), 'snippet': 'roll call: A voted Yea.', 'snippet_index': '1'}])
    out = run('legiscan_merge.py', B, '--host', 'off').stdout
    assert json.load(open(f'{B}/legiscan/no-line.json')) == [['Ann A', rc(2), 'nay', 'XX-HB-1-2025']], open(f'{B}/legiscan/no-line.json').read()
    assert 'no LegiScan line 1' in out, out
    assert urls(read_csv(f'{B}/research.csv')[0]) == ['https://off/2', rc(1)], read_csv(f'{B}/research.csv')


@check
def bill_text_reads_whole_operative_text_and_gate_option(t):
    """A quote that sits in section text outside every (quote) block is placed, from the gate file named by --gate."""
    B = batch(f'{t}/b', [('Ann A', 'a')], [{'full_name': 'Ann A', 'topic_key': 'tp', 'evidence_type': 'record', 'urls': ['https://off/1']}])
    os.makedirs(f'{t}/store/findings'); os.makedirs(f'{t}/store/instruments')
    json.dump({'findings': [{'instrument_id': 'XX-HB-1-2025'}]}, open(f'{t}/store/findings/a.json', 'w'))
    sec = ('Section 1. A person may not sell a widget without a permit issued by the department under this chapter. '
           'The department shall issue the permit within thirty days after it receives a complete application and the fee.')
    json.dump({'operative_text': f'(a) (section) {{+{sec}+}}\n\n(quote) Unrelated words of the act that hold nothing.',
               'urls': ['https://leg/hb1.pdf']}, open(f'{t}/store/instruments/XX-HB-1-2025.json', 'w'))
    open(f'{B}/gate-r7.txt', 'w').write('  high  quote-not-in-snippet  Ann A / tp: quote not in any snippet: "may not sell a widget without a permit"\n')
    run('bill_text_auto.py', B, f'{t}/store/findings', '--topic', 'tp', '--gate', f'{B}/gate-r7.txt')
    log = json.load(open(f'{B}/bill-text.json'))
    assert [p['source'] for p in log['Ann A']['placed']] == ['operative_text_full'], log
    assert 'https://leg/hb1.pdf' in urls(read_csv(f'{B}/research.csv')[0])


@check
def apply_overrides_skip_changed(t):
    """--skip-changed skips and reports a trim whose words an earlier trim changed; the default still stops on it."""
    B = batch(t, [('Ann A', 'a')], [{'full_name': 'Ann A', 'topic_key': 't', 'evidence_type': 'record', 'reasoning': 'Voted for HB 1 "to ban widgets".'}])
    json.dump({'trims': [{'name': 'Ann A', 'removed': '"to ban widgets"', 'now': 'to ban widgets'},
                         {'name': 'Ann A', 'removed': '"to ban widgets"', 'now': 'X'}]}, open(f'{B}/overrides.json', 'w'))
    p = run('apply_overrides.py', B, ok=False)
    assert p.returncode != 0, 'the default mode must stop on a trim whose words are gone'
    run('apply_overrides.py', B, '--skip-changed')
    assert read_csv(f'{B}/research.csv')[0]['reasoning'] == 'Voted for HB 1 to ban widgets.'
    log = json.load(open(f'{B}/overrides-applied.json'))
    assert len(log['applied']) == 1 and len(log['skipped']) == 1, log


@check
def state_legiscan_pairs_only_one_roll_call(t):
    """Date + tally pick one roll call; a same-day tie is broken on the motion; a committee vote and a vote with no
    single match go to unmapped.json, never a guess. A floor vote on a conference committee's recommendation is a floor
    vote (wa-01: "House Final Passage as recommended by the Conference Committee")."""
    B = batch(f'{t}/b', [('Ann Able', 'a')], [{'full_name': 'Ann Able', 'topic_key': 'tp', 'evidence_type': 'record', 'urls': ['https://off.gov/hb1', 'https://off.gov/hb2', 'https://off.gov/hb3', 'https://off.gov/hb4']}], ncols=4)
    os.makedirs(f'{t}/f')
    v = lambda u, ins, d, tal, mo: {'kind': 'record', 'url': u, 'act': 'yea', 'instrument_id': ins, 'chamber': 'H', 'date': d, 'note': f'tally {tal}', 'motion': mo}
    json.dump({'findings': [v('https://off.gov/hb1', 'XX-HB-1-2025', '2025-03-01', '60-40', 'Third reading'),
                            v('https://off.gov/hb2', 'XX-HB-2-2025', '2025-03-02', '70-30', 'Second reading'),
                            v('https://off.gov/hb3', 'XX-HB-3-2025', '2025-03-03', '50-50', 'Committee vote'),
                            v('https://off.gov/hb1', 'XX-HB-1-2025', '2025-03-09', '51-49', 'Final passage'),
                            v('https://off.gov/hb4', 'XX-HB-4-2025', '2025-03-10', '69-28', 'House Final Passage as recommended by the Conference Committee (#22)')]}, open(f'{t}/f/a.json', 'w'))
    run('state_legiscan.py', 'plan', B, f'{t}/f', '--state', 'XX', '--host', 'off.gov')
    pages = {p['url'] for p in json.load(open(f'{B}/legiscan/vote-pages.json'))}
    assert len(pages) == 5, pages
    h = lambda rc, d, desc, bill: {'roll_call_id': rc, 'date': d, 'desc': desc, 'bill_url': f'https://legiscan.com/XX/bill/{bill}/2025'}
    json.dump([{'url': 'XX-HB-1-2025|H|2025-03-01|60-40', 'hits': [h(11, '2025-03-01', 'Third reading passed', 'HB1')]},
               {'url': 'XX-HB-2-2025|H|2025-03-02|70-30', 'hits': [h(21, '2025-03-02', 'Amendment 3 adopted', 'HB2'), h(22, '2025-03-02', 'Second reading passed', 'HB2')]},
               {'url': 'XX-HB-3-2025|H|2025-03-03|50-50', 'hits': [h(41, '2025-03-03', 'Committee vote', 'HB3')]},  # one match, still a committee vote
               {'url': 'XX-HB-1-2025|H|2025-03-09|51-49', 'hits': [h(31, '2025-03-09', 'Motion to table', 'HB1'), h(32, '2025-03-09', 'Motion to reconsider', 'HB1')]},
               {'url': 'XX-HB-4-2025|H|2025-03-10|69-28', 'hits': [h(51, '2025-03-10', 'House Final Passage as recommended by the Conference Committee (#22)', 'HB4')]}],
              open(f'{B}/legiscan/rollcall-hits.json', 'w'))
    run('state_legiscan.py', 'pairs', B, f'{t}/f', '--state', 'XX', '--host', 'off.gov', '--topic', 'tp')
    got = sorted(r['source_url'] for r in read_csv(f'{B}/legiscan/pairs.csv'))
    assert got == ['https://legiscan.com/XX/rollcall/HB1/id/11', 'https://legiscan.com/XX/rollcall/HB2/id/22', 'https://legiscan.com/XX/rollcall/HB4/id/51'], got
    un = json.load(open(f'{B}/legiscan/unmapped.json'))
    assert sorted(u[2] for u in un) == ['XX-HB-1-2025', 'XX-HB-3-2025'], un


@check
def state_legiscan_places_a_conference_report_and_names_bills_as_the_datasets_do(t):
    """A vote on a conference report is a floor vote however the motion words it; a real committee vote is still left
    out, and says so. With the datasets on disk, a sponsorship's LegiScan page takes LegiScan's own bill number and
    the session's first year (South Carolina: S 109 of 2024 is /S0109/2023); without them, the flags decide."""
    B = batch(f'{t}/b', [('Ann Able', 'a')], [{'full_name': 'Ann Able', 'topic_key': 'tp', 'evidence_type': 'record',
              'urls': ['https://off.gov/h1', 'https://off.gov/h2', 'https://off.gov/s109', 'https://off.gov/s7', 'https://off.gov/h1c']}], ncols=5)
    os.makedirs(f'{t}/f')
    v = lambda u, ins, d, tal, mo: {'kind': 'record', 'url': u, 'act': 'yea', 'instrument_id': ins, 'chamber': 'S', 'date': d, 'note': f'tally {tal}', 'motion': mo}
    json.dump({'findings': [v('https://off.gov/h1', 'XX-H-1-2024', '2024-03-06', '28-18', 'Adopt Committee of Conference report'),
                            v('https://off.gov/h2', 'XX-H-2-2024', '2024-03-07', '9-3', 'Judiciary Committee: favorable'),
                            v('https://off.gov/h1c', 'XX-H-1-2024', '2024-03-08', '20-5', 'Senate Conference Committee - Final Passage'),  # Utah's wording
                            {'kind': 'record', 'url': 'https://off.gov/s109', 'act': 'cosponsor', 'instrument_id': 'XX-S-109-2024'},
                            {'kind': 'record', 'url': 'https://off.gov/s7', 'act': 'sponsor', 'instrument_id': 'XX-S-7-2024'}]}, open(f'{t}/f/a.json', 'w'))
    ds = f'{t}/ds'
    def session(folder, y0, y1, special, bills):
        d = f'{ds}/XX-{folder}/XX/s{folder}/bill'; os.makedirs(d)
        for n in bills: json.dump({'bill': {'bill_number': n, 'session': {'year_start': y0, 'year_end': y1, 'special': special}}}, open(f'{d}/{n}.json', 'w'))
    session(1, 2021, 2022, 0, ['S0109', 'H0001']); session(2, 2023, 2024, 0, ['S0109', 'H0001', 'S0007']); session(3, 2024, 2024, 1, ['S0109'])
    session(4, 2024, 2024, 0, ['S0007'])  # S 7 sits in two regular sessions that cover 2024: the datasets do not decide, the flags do
    env = {'LEGISCAN_DATASETS': ds}
    run('state_legiscan.py', 'plan', B, f'{t}/f', '--state', 'XX', '--host', 'off.gov', env=env)
    pages = json.load(open(f'{B}/legiscan/vote-pages.json'))
    assert sorted((p['bill'], p['year']) for p in pages) == [('H0001', 2024), ('H0001', 2024), ('H2', 2024)], pages  # H 1 as the datasets print it
    json.dump([{'url': 'XX-H-1-2024|S|2024-03-06|28-18', 'hits': [{'roll_call_id': 5, 'date': '2024-03-06', 'desc': 'Senate: To Adopt The Conference Report', 'bill_url': 'https://legiscan.com/XX/bill/H0001/2023'}]},
               {'url': 'XX-H-1-2024|S|2024-03-08|20-5', 'hits': [{'roll_call_id': 6, 'date': '2024-03-08', 'desc': 'Senate Conference Committee - Final Passage', 'bill_url': 'https://legiscan.com/XX/bill/H0001/2023'}]}],
              open(f'{B}/legiscan/rollcall-hits.json', 'w'))
    run('state_legiscan.py', 'pairs', B, f'{t}/f', '--state', 'XX', '--host', 'off.gov', '--topic', 'tp', env=env)
    got = sorted(r['source_url'] for r in read_csv(f'{B}/legiscan/pairs.csv'))
    assert got == ['https://legiscan.com/XX/bill/S0109/2023', 'https://legiscan.com/XX/bill/S7/2024', 'https://legiscan.com/XX/rollcall/H0001/id/5', 'https://legiscan.com/XX/rollcall/H0001/id/6'], got
    un = json.load(open(f'{B}/legiscan/unmapped.json'))
    assert [(u[2], 'a committee vote' in u[3]) for u in un] == [('XX-H-2-2024', True)], un
    run('state_legiscan.py', 'pairs', B, f'{t}/f', '--state', 'XX', '--host', 'off.gov', '--topic', 'tp', '--bill-pad', '4', '--session-start', 'odd')  # no datasets
    got = sorted(r['source_url'] for r in read_csv(f'{B}/legiscan/pairs.csv') if '/bill/' in r['source_url'])
    assert got == ['https://legiscan.com/XX/bill/S0007/2023', 'https://legiscan.com/XX/bill/S0109/2023'], got


@check
def legiscan_is_read_from_the_datasets_on_disk_by_default(t):
    """The recipe and the write script set LEGISCAN_DATASETS themselves when the state has datasets on disk; the live
    API only on LEGISCAN_LIVE=1 / "legiscan_live". Step 7 says which was read and the newest roll call on disk, stops
    on an act with no LegiScan line, and a vote later than the datasets says so. The desk's commands are printed whole."""
    S = f'{t}/stage5'; ds = f'{S}/legiscan/ds'; d = f'{ds}/XX-1/XX/s1'
    os.makedirs(f'{d}/bill'); os.makedirs(f'{d}/vote'); os.makedirs(f'{S}/codes')
    json.dump({'bill': {'bill_number': 'H0001', 'session': {'year_start': 2023, 'year_end': 2024, 'special': 0}}}, open(f'{d}/bill/H0001.json', 'w'))
    for i, day in ((1, '2024-03-06'), (2, '2024-05-01')): json.dump({'roll_call': {'roll_call_id': i, 'date': day}}, open(f'{d}/vote/{i}.json', 'w'))
    sys.path.insert(0, TOOLS)
    import importlib; of = importlib.import_module('_onfile'); importlib.reload(of); rr = importlib.import_module('run_recipe'); importlib.reload(rr)
    sys.path.remove(TOOLS)
    want = {'LEGISCAN_DATASETS': ds, 'LEGISCAN_DATASET_STATES': 'XX'}
    assert of.onfile_env(S, 'xx', env={}) == want
    assert of.onfile_env(S, 'xx', env={'LEGISCAN_LIVE': '1'}) == {}, 'the runner allowed the live API'
    assert of.onfile_env(S, 'xx', env={'LEGISCAN_DATASETS': '/else'}) == {}, 'the caller already chose'
    assert of.onfile_env(S, 'yy', env={}) == {}, 'no datasets for that state'
    assert of.newest_roll_call(ds, 'xx') == ('2024-05-01', 1)
    # a session just opened, with bills and no roll call yet, gives way to the newest session that holds one (fl-01)
    n = f'{ds}/XX-2/XX/s2'; os.makedirs(f'{n}/bill'); os.makedirs(f'{n}/vote')
    json.dump({'bill': {'bill_number': 'H0002', 'session': {'year_start': 2025, 'year_end': 2025, 'special': 0}}}, open(f'{n}/bill/H0002.json', 'w'))
    assert of.newest_roll_call(ds, 'xx') == ('2024-05-01', 2)
    # the recipe: step 7's check
    B = f'{t}/b'; os.makedirs(f'{B}/legiscan')
    rec = {'stage5': S, 'topic': 'tp', 'unit': 'state:xx', 'level': 'state', 'state': 'XX', 'roster': f'{t}/r.tsv', 'codes': f'{S}/codes', 'saved_root': t, 'votes': 'legiscan-plan'}
    put = lambda f, x: json.dump(x, open(f'{B}/{f}', 'w'))
    put('recipe.json', rec); put('legiscan/crosscheck.json', []); put('legiscan/unmapped.json', []); put('legiscan/no-line.json', [])
    out = run('run_recipe.py', B, '--check-only', '7').stdout
    assert 'datasets on disk, 0 API calls' in out and '2 session(s), newest roll call 2024-05-01' in out, out
    assert 'LIVE API' in run('run_recipe.py', B, '--check-only', '7', env={'LEGISCAN_LIVE': '1'}).stdout
    put('recipe.json', {**rec, 'legiscan_live': True}); assert 'LIVE API' in run('run_recipe.py', B, '--check-only', '7').stdout
    put('recipe.json', rec); put('legiscan/no-line.json', [['Ann Able', 'https://legiscan.com/XX/bill/H1/2024', 'sponsor', 'XX-H-1-2024']])
    p = run('run_recipe.py', B, '--check-only', '7', ok=False)
    assert p.returncode == 10 and 'NO LegiScan line' in p.stdout, (p.returncode, p.stdout)
    old = {k: os.environ.pop(k, None) for k in want}
    try:
        os.environ.update(want); cmds = rr.desk_commands(rec, B)
    finally:
        for k, v in old.items(): os.environ.pop(k, None) if v is None else os.environ.__setitem__(k, v)
    assert all(f'LEGISCAN_DATASETS={ds} LEGISCAN_DATASET_STATES=XX ' in c for c in cmds[:2]), cmds
    assert 'write-batch.sh' in cmds[0] and cmds[0].endswith(' apply') and '--apply --editor-id <editor id>' in cmds[1], cmds
    assert '--env-file=.env' in cmds[2] and f'{B}/pids-write.txt --batch-id b' in cmds[2] and 'approve-batch.ts <editor id> b' in cmds[3], cmds
    # a vote later than the datasets says so; an earlier one that finds no roll call does not
    batch(B, [('Ann Able', 'a')], [{'full_name': 'Ann Able', 'topic_key': 'tp', 'evidence_type': 'record', 'urls': ['https://off.gov/1', 'https://off.gov/2']}])
    os.makedirs(f'{t}/f')
    v = lambda u, day: {'kind': 'record', 'url': u, 'act': 'yea', 'instrument_id': 'XX-H-1-2024', 'chamber': 'H', 'date': day, 'note': 'tally 60-40', 'motion': 'Passage'}
    json.dump({'findings': [v('https://off.gov/1', '2024-06-01'), v('https://off.gov/2', '2024-04-01')]}, open(f'{t}/f/a.json', 'w'))
    put('legiscan/rollcall-hits.json', [])
    run('state_legiscan.py', 'pairs', B, f'{t}/f', '--state', 'XX', '--host', 'off.gov', '--topic', 'tp', env=want)
    un = {u[1]: u[3] for u in json.load(open(f'{B}/legiscan/unmapped.json'))}
    assert 'NEWER' in un['https://off.gov/1'] and '2024-05-01' in un['https://off.gov/1'] and 'NEWER' not in un['https://off.gov/2'], un
    # the write script
    if not shutil.which('zsh'): print('     (write-batch.sh part skipped: no zsh)'); return
    os.makedirs(f'{t}/bin'); open(f'{B}/pids.txt', 'w').write('a\n')
    open(f'{t}/bin/npx', 'w').write(f'#!/bin/sh\necho "$LEGISCAN_DATASETS|$LEGISCAN_DATASET_STATES" > {t}/env.txt\n'); os.chmod(f'{t}/bin/npx', 0o755)
    base = {k: x for k, x in os.environ.items() if not k.startswith('LEGISCAN_')}; base['PATH'] = f'{t}/bin:' + base['PATH']
    wb = lambda unit, **e: subprocess.run(['zsh', os.path.join(TOOLS, 'write-batch.sh'), S, B, 'tp', unit, '0'], capture_output=True, text=True, env={**base, **e})
    assert wb('state:xx').returncode == 0 and open(f'{t}/env.txt').read().strip() == f'{os.path.realpath(ds)}|XX', open(f'{t}/env.txt').read()
    wb('state:xx', LEGISCAN_LIVE='1'); assert open(f'{t}/env.txt').read().strip() == '|', 'the live API on the runner\'s yes'
    wb('state:yy'); assert open(f'{t}/env.txt').read().strip() == '|', 'no datasets for that state'


@check
def drop_held_keeps_first_full_copy(t):
    """Held and moved people leave both files; the -with-held copy is the FIRST full set and is never overwritten."""
    B = batch(t, [('Ann A', 'a'), ('Bob B', 'b'), ('Cy C', 'c')], [{'full_name': n, 'topic_key': 't', 'evidence_type': 'record'} for n in ('Ann A', 'Bob B', 'Cy C')],
              [{'full_name': n, 'topic_key': 't', 'source_url': 'https://x', 'snippet': 's', 'snippet_index': '1'} for n in ('Ann A', 'Bob B', 'Cy C')])
    open(f'{B}/held.txt', 'w').write('b\n'); open(f'{B}/moved.txt', 'w').write('c\n')
    run('drop_held.py', B)
    assert [r['full_name'] for r in read_csv(f'{B}/research.csv')] == ['Ann A']
    assert [r['full_name'] for r in read_csv(f'{B}/evidence.csv')] == ['Ann A']
    run('drop_held.py', B)
    assert len(read_csv(f'{B}/research-with-held.csv')) == 3


@check
def uncite_packs_left_and_drops_snippets(t):
    B = batch(t, [('Ann A', 'a')], [{'full_name': 'Ann A', 'topic_key': 't', 'evidence_type': 'record', 'urls': ['https://x/1', 'https://x/2']}],
              [{'full_name': 'Ann A', 'topic_key': 't', 'source_url': u, 'snippet': 's', 'snippet_index': '1'} for u in ('https://x/1', 'https://x/2')])
    json.dump([{'name': 'Ann A', 'url': 'https://x/1', 'why': 'test'}], open(f'{B}/uncite.json', 'w'))
    run('uncite.py', B)
    r = read_csv(f'{B}/research.csv')[0]
    assert r[f'{RU}1'] == 'https://x/2' and r[f'{RU}2'] == '', r
    assert [e['source_url'] for e in read_csv(f'{B}/evidence.csv')] == ['https://x/2']


@check
def quote_snippets_cuts_from_cached_page_and_skips_gone(t):
    import hashlib
    B = batch(t, [('Ann A', 'a')], [{'full_name': 'Ann A', 'topic_key': 'tp', 'evidence_type': 'record', 'urls': ['https://x/1']}])
    os.makedirs(f'{B}/pages')
    open(f'{B}/pages/{hashlib.sha1(b"https://x/1").hexdigest()}.txt', 'w').write('Before words here. Ann A said “we will act now” at the hearing.')
    open(f'{B}/gate.txt', 'w').write('  high  quote-not-in-snippet  Ann A / tp: quote not in any snippet: "we will act now"\n'
                                     '  high  quote-not-in-snippet  Gone G / tp: quote not in any snippet: "words"\n')
    run('quote_snippets.py', B, f'{B}/gate.txt', '--topic', 'tp')
    ev = read_csv(f'{B}/evidence.csv')
    assert ev[-1]['source_url'] == 'https://x/1' and 'we will act now' in ev[-1]['snippet'] and ev[-1]['topic_key'] == 'tp', ev[-1]
    assert json.load(open(f'{B}/quote-snippets.json'))['not_in_research'] == [['Gone G', 'words']]


@check
def respell_ids_bill_numbers(t):
    B = batch(t, [('Ann A', 'a')], [{'full_name': 'Ann A', 'topic_key': 't', 'evidence_type': 'record',
                                     'reasoning': 'Voted for XX-HB-12-2025, XX-HB-5-SP1-2020 and XX-SB-3-AMDT-H1-2024; not YY-HB-1-2025.'}])
    run('respell_ids.py', B, '--state', 'XX')
    got = {t['removed']: t['now'] for t in json.load(open(f'{B}/overrides.json'))['trims']}
    assert got == {'XX-HB-12-2025': 'HB 12 (2025)', 'XX-HB-5-SP1-2020': 'HB 5 (2020 Special Session I)', 'XX-SB-3-AMDT-H1-2024': 'SB 3 (2024)'}, got


@check
def setup_batch_sets_aside_the_rest_of_the_unit(t):
    S = f'{t}/stage5'; os.makedirs(f'{S}/codes')
    for p in ('a', 'b', 'c', 'f'): open(f'{S}/codes/{p}.json', 'w').write('{}')
    open(f'{S}/roster.tsv', 'w').write('politician_id\tlevel\tstate\n' + ''.join(f'{p}\t{l}\tXX\n'.replace('XX', st) for p, l, st in
                                       (('a', 'state', 'XX'), ('b', 'state', 'XX'), ('c', 'state', 'YY'), ('d', 'state', 'XX'), ('f', 'federal', 'XX'))))
    run('setup_batch.py', S, f'{t}/b1', '--level', 'state', '--state', 'XX', 'a')
    assert open(f'{t}/b1/pids.txt').read() == 'a\n' and open(f'{t}/b1/moved.txt').read() == 'b\n'
    p = run('setup_batch.py', S, f'{t}/b2', '--level', 'state', '--state', 'XX', 'd', ok=False)
    assert p.returncode != 0 and not os.path.exists(f'{t}/b2'), 'an uncoded id must stop the run before anything is written'


@check
def cite_named_adds_own_record_only(t):
    B = batch(f'{t}/b', [('Ann A', 'a')], [{'full_name': 'Ann A', 'topic_key': 'tp', 'evidence_type': 'record', 'urls': ['https://x/1', 'https://x/2']}])
    os.makedirs(f'{t}/f')
    json.dump({'findings': [{'kind': 'record', 'instrument_id': 'XX-HB-7-2025', 'url': 'https://off/hb7'},
                            {'kind': 'statement', 'instrument_id': 'XX-HB-8-2025', 'url': 'https://news/hb8'}]}, open(f'{t}/f/a.json', 'w'))
    open(f'{B}/gate.txt', 'w').write('  high  instrument-not-cited  Ann A / tp: names a bill not cited, canonical "hb7"\n'
                                     '  high  instrument-not-cited  Ann A / tp: names a bill not cited, canonical "hb8"\n')
    run('cite_named.py', B, f'{B}/gate.txt', f'{t}/f', '--state', 'XX')
    assert urls(read_csv(f'{B}/research.csv')[0]) == ['https://x/1', 'https://x/2', 'https://off/hb7']
    assert json.load(open(f'{B}/cite-named-none.json')) == [['Ann A', 'hb8']]


@check
def unquote_never_touches_own_words(t):
    B = batch(t, [('Ann A', 'a'), ('Bob B', 'b')], [
        {'full_name': 'Ann A', 'topic_key': 'tp', 'evidence_type': 'record', 'reasoning': 'Backed HB 1 "to license dealers" and said "I will fight".'},
        {'full_name': 'Bob B', 'topic_key': 'tp', 'evidence_type': 'statement', 'reasoning': 'Said "a fair rule".'}])
    open(f'{B}/gate.txt', 'w').write('\n'.join(f'  high  quote-not-in-snippet  {n} / tp: not in any snippet: "{q}"' for n, q in
                                               (('Ann A', 'to license dealers'), ('Ann A', 'I will fight'), ('Bob B', 'a fair rule'))) + '\n')
    run('unquote.py', B, f'{B}/gate.txt')
    assert [(x['name'], x['now']) for x in json.load(open(f'{B}/overrides.json'))['trims']] == [('Ann A', 'to license dealers')]


@check
def quote_fix_splits_an_edited_quote(t):
    B = batch(f'{t}/b', [('Ann A', 'a')], [{'full_name': 'Ann A', 'topic_key': 'tp', 'evidence_type': 'record',
                                            'reasoning': 'Sponsored HB 1 "requires a permit ... issued by the department".'}])
    os.makedirs(f'{t}/store/findings'); os.makedirs(f'{t}/store/instruments')
    json.dump({'findings': [{'instrument_id': 'XX-HB-1-2025'}]}, open(f'{t}/store/findings/a.json', 'w'))
    json.dump({'operative_text': 'The act requires a permit for each sale, which is issued by the department.'}, open(f'{t}/store/instruments/XX-HB-1-2025.json', 'w'))
    open(f'{B}/gate.txt', 'w').write('  high  quote-not-in-snippet  Ann A / tp: not in any snippet: "requires a permit ... issued by the department"\n')
    run('quote_fix.py', B, f'{B}/gate.txt', f'{t}/store/findings', '--saved-root', t)
    assert [x['now'] for x in json.load(open(f'{B}/overrides.json'))['trims']] == ['"requires a permit" … "issued by the department"']


@check
def archive_fallback_when_live_page_is_refused(t):
    """build_evidence.py reads archive.org when the live page fails the verifier's own test (_archive.live_failed).
    wi-01 cut from a 403 page and held a person whose pages the verifier read from the archive (2026-11-10)."""
    import importlib.util
    spec = importlib.util.spec_from_file_location('_archive', os.path.join(TOOLS, '_archive.py'))
    m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
    real = 'Statement on school safety. ' * 40
    assert m.live_failed(b'403', real), 'a 403 must fall back, even with a long body'
    assert m.live_failed(b'000', ''), 'a timeout must fall back'
    assert m.live_failed(b'200', 'Just a moment... checking your browser'), 'a short challenge page must fall back'
    assert m.live_failed(b'200', 'too short'), 'a body under 500 characters must fall back'
    assert not m.live_failed(b'200', real), 'a real 200 page must be kept'
    assert not m.live_failed(b'200', real + ' access denied ' + real), 'a marker in a long page is not a challenge'


@check
def evidence_rebuild_choice_reaches_step_4_and_from_research_after_step_7_is_refused(t):
    """Utah ut-01 (2026-11-15): `run_recipe.py --from 4` could not pass --from-pre/--from-research, so step 4 was run by
    hand; and --from-research on rows already through step 7 lost two roll-call pairings at the next step 7."""
    os.makedirs(t); B = f'{t}/b'; os.makedirs(B)
    rec = {'stage5': t, 'topic': 'tp', 'unit': 'state:xx', 'level': 'state', 'state': 'XX', 'roster': f'{t}/r.tsv', 'codes': f'{t}/c',
           'saved_root': t, 'votes': 'none'}
    json.dump(rec, open(f'{B}/recipe.json', 'w'))
    four = lambda *a: [l for l in run('run_recipe.py', B, '--from', '4', '--to', '4', '--print', *a, ok=False).stdout.splitlines() if 'build_evidence.py' in l]
    assert four() and all('--from-pre' not in l and '--from-research' not in l for l in four()), four()
    assert any(l.rstrip().endswith('--from-pre') or ' --from-pre ' in l for l in four('--evidence-from', 'pre')), four('--evidence-from', 'pre')
    assert any('--from-research' in l for l in four('--evidence-from', 'research'))
    p = run('run_recipe.py', B, '--from', '4', '--print', '--evidence-from', 'both', ok=False); assert p.returncode != 0, 'only pre or research'
    write_csv(f'{B}/research.csv', [{'full_name': 'A', 'value': '1'}]); write_csv(f'{B}/research-pre-evidence.csv', [{'full_name': 'A', 'value': '1'}])
    write_csv(f'{B}/research-pre-step7.csv', [{'full_name': 'A', 'value': '1'}])
    json.dump([], open(f'{B}/politicians.json', 'w'))
    open(f'{t}/r.tsv', 'w').write('politician_id\tfull_name\n'); os.makedirs(f'{t}/f')
    p = run('build_evidence.py', B, f'{t}/r.tsv', f'{t}/f', '--from-research', ok=False)
    assert p.returncode != 0 and 'step 7' in (p.stderr + p.stdout) and os.path.exists(f'{B}/research.csv'), (p.returncode, p.stderr[-300:])


def store(t, people, bills):
    """A source store: findings/<pid>.json from {pid: [(bill, act, gate)]}, instruments/state-xx/<bill>.json from {bill: text}."""
    os.makedirs(f'{t}/store/findings'); os.makedirs(f'{t}/store/instruments/state-xx')
    for pid, rows in people.items():
        json.dump({'politician_id': pid, 'findings': [{'id': f'{pid}{i}', 'kind': 'record', 'instrument_id': b, 'act': a, 'topic_keys': ['tp'],
                                                       'gate_by_topic': {'tp': g}} for i, (b, a, g) in enumerate(rows)], 'searches': []},
                  open(f'{t}/store/findings/{pid}.json', 'w'))
    for b, text in bills.items(): json.dump({'title': b, 'operative_text': text}, open(f'{t}/store/instruments/state-xx/{b}.json', 'w'))
    return f'{t}/store'


@check
def bill_table_check_needs_deciding_words_in_the_bill(t):
    S = store(t, {'a': [('XX-HB-1-2025', 'yea', 'none'), ('XX-HB-9-2025', 'yea', 'none')]},
              {'XX-HB-1-2025': 'A permit is no longer required to carry a handgun.', 'XX-HB-2-2025': 'Fees are waived.'})
    good = {'topic_key': 'tp', 'bills': {'XX-HB-1-2025': {'rung': 5, 'deciding_words': 'a permit is no longer   required', 'why': '', 'flag': ''},
                                         'XX-HB-2-2025': {'rung': None, 'deciding_words': '', 'why': 'direction only', 'flag': ''}}}
    json.dump(good, open(f'{t}/t.json', 'w'))
    assert run('bill_table.py', 'check', f'{t}/t.json', '--store', S).returncode == 0
    bad = json.loads(json.dumps(good)); bad['bills']['XX-HB-1-2025']['deciding_words'] = 'a permit is abolished'
    bad['bills']['XX-HB-2-2025']['why'] = ''; bad['bills']['XX-HB-7-2025'] = {'rung': 6, 'deciding_words': 'x'}
    json.dump(bad, open(f'{t}/b.json', 'w')); open(f'{t}/ids', 'w').write('a\n')
    p = run('bill_table.py', 'check', f'{t}/b.json', '--store', S, '--ids', f'{t}/ids', ok=False)
    assert p.returncode == 2, p.stdout
    for want in ('not in the operative text', 'needs a why', 'XX-HB-7-2025: no instrument file', 'XX-HB-9-2025: 1 person'):
        assert want in p.stdout, (want, p.stdout)


@check
def bill_table_settle_closes_a_flag_and_check_refuses_an_answer_left_in_it(t):
    S = store(t, {'a': [('XX-HB-1-2025', 'yea', 'none')]}, {'XX-HB-1-2025': 'x', 'XX-HB-2-2025': 'y', 'XX-HB-3-2025': 'z'})
    row = lambda flag: {'rung': None, 'deciding_words': '', 'why': 'w', 'flag': flag}
    T = f'{t}/t.json'
    def write(flags): json.dump({'topic_key': 'tp', 'bills': {f'XX-HB-{i + 1}-2025': row(f) for i, f in enumerate(flags)}}, open(T, 'w'))
    # Florida, 2026-11-14: the answer was appended to the flag of every row, flagged or not.
    write(['Is a fee cut rung 4? Best answer: yes. [Settled 2026-11-14, stop 1: as recommended.]', ' [Settled 2026-11-14, stop 1: as recommended.]', ''])
    p = run('bill_table.py', 'check', T, '--store', S, ok=False)
    assert p.returncode == 2 and p.stdout.count('reads as answered') == 2 and '2 flagged' in p.stdout, p.stdout
    write(['Is a fee cut rung 4?', 'A ruling of 2026 settled permits. Does it reach renewals?', ''])
    p = run('bill_table.py', 'check', T, '--store', S)
    assert p.returncode == 0 and '2 flagged (open questions): the record script codes nobody' in p.stdout, p.stdout
    before = open(T).read()
    for bad in (['XX-HB-3-2025', '--answer', 'yes'], ['XX-HB-9-2025', '--answer', 'yes'], ['XX-HB-1-2025'], ['--all', 'XX-HB-1-2025', '--answer', 'yes'], ['--answer', 'yes']):
        assert run('bill_table.py', 'settle', T, *bad, ok=False).returncode != 0, bad
    assert open(T).read() == before, 'a refused settle writes nothing'
    p = run('bill_table.py', 'settle', T, 'XX-HB-1-2025', '--answer', 'Runner, stop 1: yes.')
    r = json.load(open(T))['bills']['XX-HB-1-2025']
    assert (r['flag'], r['question'], r['answered']) == ('', 'Is a fee cut rung 4?', 'Runner, stop 1: yes.') and '1 still flagged' in p.stdout, (r, p.stdout)
    p = run('bill_table.py', 'settle', T, '--all', '--answer', 'Earlier ruling R7.')
    assert 'settled 1 bill(s); 0 still flagged' in p.stdout and json.load(open(T))['bills']['XX-HB-2-2025']['answered'] == 'Earlier ruling R7.', p.stdout
    p = run('bill_table.py', 'check', T, '--store', S)
    assert p.returncode == 0 and '0 flagged' in p.stdout and 'codes nobody' not in p.stdout, p.stdout


@check
def bill_table_questions_find_both_sides_and_skip_gated(t):
    S = store(t, {'a': [('XX-HB-1-2025', 'yea', 'none'), ('XX-HB-2-2025', 'sponsor', 'none')],
                  'b': [('XX-HB-1-2025', 'yea', 'none'), ('XX-HB-2-2025', 'yea', 'multi-subject')],
                  'c': [('XX-HB-1-2025', 'yea', 'none'), ('XX-HB-2-2025', 'nay', 'none')]},
              {'XX-HB-1-2025': 'x', 'XX-HB-2-2025': 'y'})
    json.dump({'topic_key': 'tp', 'bills': {'XX-HB-1-2025': {'rung': 4}, 'XX-HB-2-2025': {'rung': 2, 'flag': 'Is a fee cut rung 4?'}}}, open(f'{t}/t.json', 'w'))
    open(f'{t}/ids', 'w').write('a b c\n')
    p = run('bill_table.py', 'questions', f'{t}/t.json', '--store', S, '--ids', f'{t}/ids', '--out', f'{t}/q.md')
    md = open(f'{t}/q.md').read()
    assert 'Is a fee cut rung 4?' in md and '- a:' in md and '- b:' not in md and '- c:' not in md, md
    assert '1 flagged bill(s), 1 both-sides person(s)' in p.stdout, p.stdout


def code(d, pid, outcome, value=None, basis='record'):
    os.makedirs(d, exist_ok=True)
    json.dump({'politician_id': pid, 'outcome': outcome, 'value': value, 'evidence_basis': basis}, open(f'{d}/{pid}.json', 'w'))


@check
def search_list_skips_only_record_seats_at_skip_rungs_and_controls(t):
    """Only a RECORD seat at a skip rung is skipped; the control is seeded, searched, and checked before adopting."""
    pids = [f'p{i:02d}' for i in range(30)]
    os.makedirs(t)
    open(f'{t}/roster.tsv', 'w').write('politician_id\tfull_name\n' + ''.join(f'{p}\t{p.upper()}\n' for p in pids))
    R = f'{t}/rec'
    for p in pids[:24]: code(R, p, 'seated', 5)
    code(R, 'p24', 'seated', 2, 'own-words'); code(R, 'p25', 'seated', 4); code(R, 'p26', 'doesnt-fit')  # p27-29: no record-only code
    O = f'{t}/plan'
    args = ['--record-codes', R, '--roster', f'{t}/roster.tsv', '--skip-rungs', '5,2', '--control', '5', '--out', O]
    run('search_list.py', 'plan', *args)
    ctrl = [r['politician_id'] for r in csv.DictReader(open(f'{O}/control.tsv'), delimiter='\t')]
    first = open(f'{O}/control.tsv').read(); run('search_list.py', 'plan', *args)
    assert open(f'{O}/control.tsv').read() == first, 'the control must be the same on a re-run'
    search = {r['politician_id'] for r in csv.DictReader(open(f'{O}/search.tsv'), delimiter='\t')}
    assert len(ctrl) == 5 and set(ctrl) <= search
    assert {'p24', 'p25', 'p26', 'p27', 'p28', 'p29'} <= search, 'own-words, rung 4, no seat and no code are all searched'
    assert len(search) == 6 + 5
    C = f'{t}/codes'
    assert run('search_list.py', 'adopt', '--record-codes', R, '--codes', C, '--out', O, ok=False).returncode == 3, 'no full codes yet'
    for p in ctrl: code(C, p, 'seated', 5, 'joint')
    code(C, ctrl[0], 'seated', 4, 'joint')
    assert run('search_list.py', 'adopt', '--record-codes', R, '--codes', C, '--out', O, ok=False).returncode == 4, '1 in 5 changed'
    code(C, ctrl[0], 'seated', 5, 'joint')
    run('search_list.py', 'adopt', '--record-codes', R, '--codes', C, '--out', O)
    assert len(os.listdir(C)) == 24, 'every skipped person adopted, the control keeps its full code'
    assert json.load(open(f'{C}/{ctrl[0]}.json'))['evidence_basis'] == 'joint'


@check
def search_list_control_groups_draw_and_judge_each_group_apart(t):
    """--control-group: one control per group of rungs; a change in one group re-opens only that group (ruling 2026-11-13)."""
    pids = [f'p{i:02d}' for i in range(40)]
    os.makedirs(t)
    open(f'{t}/roster.tsv', 'w').write('politician_id\tfull_name\n' + ''.join(f'{p}\t{p.upper()}\n' for p in pids))
    R = f'{t}/rec'
    for p in pids[:15]: code(R, p, 'seated', 5)
    for p in pids[15:20]: code(R, p, 'seated', 2)
    for p in pids[20:32]: code(R, p, 'seated', 3)
    for p in pids[32:36]: code(R, p, 'seated', 4)  # p36-39: no record-only code
    O = f'{t}/plan'
    args = ['--record-codes', R, '--roster', f'{t}/roster.tsv', '--control-group', '5,2:4', '--control-group', '3:3', '--out', O]
    run('search_list.py', 'plan', *args)
    ctrl = list(csv.DictReader(open(f'{O}/control.tsv'), delimiter='\t'))
    by = {g: [r['politician_id'] for r in ctrl if r['group'] == g] for g in ('5,2', '3')}
    assert (len(by['5,2']), len(by['3'])) == (4, 3), by
    assert set(by['5,2']) <= set(pids[:20]) and set(by['3']) <= set(pids[20:32]), 'each control is drawn from its own group'
    search = {r['politician_id'] for r in csv.DictReader(open(f'{O}/search.tsv'), delimiter='\t')}
    assert len(search) == 8 + 7 and set(pids[32:]) <= search, 'rung 4 and no code are searched, plus both controls'
    skipped = list(csv.DictReader(open(f'{O}/skipped.tsv'), delimiter='\t'))
    assert sum(r['group'] == '3' for r in skipped) == 9 and sum(r['group'] == '5,2' for r in skipped) == 16, skipped
    bad = run('search_list.py', 'plan', *args, '--skip-rungs', '5,2', ok=False)
    assert bad.returncode != 0 and 'control-group' in bad.stderr + bad.stdout, 'the two ways of naming skip rungs must not mix'
    C = f'{t}/codes'
    adopt = ['adopt', '--record-codes', R, '--codes', C, '--out', O]
    assert run('search_list.py', *adopt, ok=False).returncode == 3, 'no full codes yet'
    for g, v in (('5,2', None), ('3', 3)):
        for p in by[g]: code(C, p, 'seated', v or json.load(open(f'{R}/{p}.json'))['value'], 'joint')
    code(C, by['3'][0], 'seated', 2, 'joint')  # one rung 3 control person changed
    r = run('search_list.py', *adopt, ok=False)
    assert r.returncode == 4, 'any change in a group of the control fails that group'
    re_open = [x['politician_id'] for x in csv.DictReader(open(f'{O}/reopened.tsv'), delimiter='\t')]
    assert len(re_open) == 9 and set(re_open) <= set(pids[20:32]), 'only the rung 3 seats are re-opened'
    assert len(os.listdir(C)) == 7 + 16, 'the group that held is adopted; the re-opened group is not'
    assert not any(os.path.exists(f'{C}/{p}.json') for p in re_open)
    code(C, by['3'][0], 'seated', 3, 'joint')
    run('search_list.py', *adopt)
    assert len(os.listdir(C)) == 7 + 16 + 9 and not os.path.exists(f'{O}/reopened.tsv'), 'both groups hold: everyone skipped is adopted'


@check
def search_list_side_group_reports_a_move_within_the_side_and_fails_on_a_change_of_side(t):
    """`<rungs>:<n>:side` (ruling 2026-11-14, rung 4): 4 -> 5 is reported; 4 -> 3, or a lost seat, re-opens the group."""
    pids = [f'p{i:02d}' for i in range(20)]
    os.makedirs(t)
    open(f'{t}/roster.tsv', 'w').write('politician_id\tfull_name\n' + ''.join(f'{p}\t{p.upper()}\n' for p in pids))
    R, C, O = f'{t}/rec', f'{t}/codes', f'{t}/plan'
    for p in pids[:12]: code(R, p, 'seated', 4)
    for p in pids[12:20]: code(R, p, 'seated', 3)
    args = ['--record-codes', R, '--roster', f'{t}/roster.tsv', '--control-group', '4:3:side', '--control-group', '3:3', '--out', O]
    bad = run('search_list.py', 'plan', *args, ok=False)
    assert bad.returncode != 0 and '--sides' in bad.stderr + bad.stdout, 'a :side group needs --sides'
    assert run('search_list.py', 'plan', *args, '--sides', '1,2,3/5', ok=False).returncode != 0, 'the sides must place the skipped rung'
    p = run('search_list.py', 'plan', *args, '--sides', '1,2,3/4,5')
    assert 'a move within the same side is reported' in p.stdout, p.stdout
    ctrl = list(csv.DictReader(open(f'{O}/control.tsv'), delimiter='\t'))
    by = {g: [r['politician_id'] for r in ctrl if r['group'] == g] for g in ('4', '3')}
    adopt = ['adopt', '--record-codes', R, '--codes', C, '--out', O]
    def full(moves):
        shutil.rmtree(C, ignore_errors=True)
        for g in by:
            for q in by[g]: code(C, q, 'seated', int(g), 'joint')
        for q, (o, v) in moves.items(): code(C, q, o, v, 'joint')
        return run('search_list.py', *adopt, ok=False)
    r = full({by['4'][0]: ('seated', 5)})
    assert r.returncode == 0 and '1 moved within the same side' in r.stdout and 'REPORT' in r.stdout, r.stdout
    assert len(os.listdir(C)) == 20 and not os.path.exists(f'{O}/reopened.tsv'), 'a move within the side adopts the group'
    for move in (('seated', 3), ('doesnt-fit', None), ('doesnt-fit', 5)):
        r = full({by['4'][0]: move})
        assert r.returncode == 4, (move, r.stdout)
        assert len(list(csv.DictReader(open(f'{O}/reopened.tsv'), delimiter='\t'))) == 9, 'the rung 4 group is re-opened'
    r = full({by['3'][0]: ('seated', 2)})
    assert r.returncode == 4 and 'rung 3: 1 of 3 changed; search' in r.stdout, 'a plain group still fails on any change, same side or not'


@check
def search_list_recode_only_new_findings_and_cut_short_searches(t):
    """Second pass only for a NEW on-topic finding (or no record-only code); a search that read none of the person's
    own pages is searched again once, not taken as 'found nothing'; everyone else keeps the record-only code."""
    os.makedirs(f'{t}/store/findings'); os.makedirs(f'{t}/briefs'); os.makedirs(f'{t}/plan')
    U = lambda i: f'00000000-0000-4000-8000-{i:012d}'
    a, b, c, d, e, f = (U(i) for i in range(1, 7))
    ok_places = ['campaign site https://x.example: nothing on the subject', 'blocked: https://ballotpedia.org/X (403)']
    bad_places = ['campaign site: not reached (blocked: https://y.example)', 'official member page: not reviewed', 'news search: nothing']
    srch = lambda places, n=1: [{'topic_key': 'tp', 'season': 3, 'places': places, 'found': 0, 'at': f'2026-11-1{i}T00:00:00Z'} for i in range(n)]
    fnd = lambda i, kind='record', topic='tp': {'id': i, 'kind': kind, 'topic_keys': [topic]}
    people = {a: ([fnd('a1'), fnd('a2', 'own-words')], srch(ok_places)),   # new own words -> second pass
              b: ([fnd('b1'), fnd('b9', 'own-words', 'other')], srch(ok_places)),  # nothing new on THIS topic -> keep
              c: ([fnd('c1')], srch(bad_places)),                           # nothing new, own pages unread -> search again
              d: ([fnd('d1')], srch(bad_places, 2)),                        # already searched twice -> keep
              e: ([fnd('e1')], []),                                         # no search on file -> search again
              f: ([fnd('f1', 'own-words')], srch(ok_places))}               # no record-only code -> second pass
    for p, (fs, ss) in people.items(): json.dump({'politician_id': p, 'findings': fs, 'searches': ss}, open(f'{t}/store/findings/{p}.json', 'w'))
    # b and d were shown their record in the collapsed layout (coder-inputs.ts --bill-table, record-script.ts): ids under "record"
    shown = lambda p, fs: ({'politician_id': p, 'record': [{'bill': 'B', 'act': 'yea', 'on': [[fs[0]['id'], '2025-01-01', 'H', '9–1', 'none']]}], 'findings': []}
                           if p in (b, d) else {'politician_id': p, 'findings': [{'id': fs[0]['id']}]})
    json.dump({'people': [shown(p, fs) for p, (fs, _) in people.items() if p != f]}, open(f'{t}/briefs/x-01.findings.json', 'w'))
    R = f'{t}/rec'
    for p in (a, b, c, d, e):
        os.makedirs(R, exist_ok=True)
        json.dump({'politician_id': p, 'outcome': 'seated', 'value': 4, 'topic_key': 'tp', 'season': 3, 'reasoning': 'Voted Yes on HB 1 (2025).'}, open(f'{R}/{p}.json', 'w'))
    open(f'{t}/plan/search.tsv', 'w').write('politician_id\tfull_name\n' + ''.join(f'{p}\tN{p[-1]}\n' for p in people))
    C = f'{t}/codes'
    args = ['--record-codes', R, '--record-briefs', f'{t}/briefs', '--store', f'{t}/store', '--out', f'{t}/plan']
    run('search_list.py', 'recode', *args, '--codes', C, '--apply')
    ids = lambda name: [r['politician_id'] for r in csv.DictReader(open(f'{t}/plan/{name}'), delimiter='\t')]
    assert sorted(ids('recode.tsv')) == sorted([a, f]), ids('recode.tsv')
    assert sorted(ids('research-again.tsv')) == sorted([c, e]), ids('research-again.tsv')
    assert sorted(ids('keep.tsv')) == sorted([b, d]), ids('keep.tsv')
    assert sorted(os.listdir(C)) == sorted([f'{b}.json', f'{d}.json']), 'only KEEP codes are copied'
    json.dump({'politician_id': b, 'outcome': 'seated', 'value': 4, 'topic_key': 'tp', 'season': 3, 'reasoning': 'Not yet searched for own words.'}, open(f'{R}/{b}.json', 'w'))
    run('search_list.py', 'recode', *args)
    assert b in ids('recode.tsv'), 'a record-only code that mentions the search is never kept'


@check
def sponsor_cover_writes_only_triaged_fill_bills(t):
    os.makedirs(f'{t}/ds/XX-1/2025/bill/people')
    json.dump({'person': {'people_id': 7, 'first_name': 'Ann', 'last_name': 'Able', 'name': 'Ann Able'}}, open(f'{t}/ds/XX-1/2025/bill/people/7.json', 'w'))
    open(f'{t}/roster.tsv', 'w').write('politician_id\tfull_name\npa\tAnn Able\n')
    bills = [{'bill_id': i, 'st': 'XX', 'y': 2025, 'num': f'HB{i}', 'title': tt, 'res': False, 'sponsors': [{'pid': 7}]}
             for i, tt in ((1, 'Carry permits'), (2, 'Game and fish'), (3, 'Core already'))] + [{'bill_id': 4, 'st': 'XX', 'y': 2025, 'num': 'HR4', 'title': 'x', 'res': True, 'sponsors': [{'pid': 7}]}]
    json.dump(bills, open(f'{t}/bills.json', 'w')); json.dump([3], open(f'{t}/core.json', 'w'))
    base = [f'{t}/bills.json', '--state', 'XX', '--roster', f'{t}/roster.tsv', '--core', f'{t}/core.json', '--ds', f'{t}/ds']
    run('sponsor_cover.py', *base, '--candidates', f'{t}/cand.json')
    assert [c['bill_id'] for c in json.load(open(f'{t}/cand.json'))] == [1, 2], 'resolutions and core bills are not candidates'
    json.dump({'1': 'fill'}, open(f'{t}/tri.json', 'w'))
    p = run('sponsor_cover.py', *base, '--triage', f'{t}/tri.json', '--write', f'{t}/new.json', ok=False)
    assert p.returncode != 0 and 'not triaged' in p.stderr and not os.path.exists(f'{t}/new.json'), 'an untriaged candidate must stop the write'
    json.dump({'1': 'fill', '2': 'skip'}, open(f'{t}/tri.json', 'w'))
    run('sponsor_cover.py', *base, '--triage', f'{t}/tri.json', '--write', f'{t}/new.json')
    assert json.load(open(f'{t}/new.json')) == [1, 3]


@check
def sponsor_cover_trims_refiled_copies(t):
    """Newest copy per (title, prime sponsor) kept; an older copy only for a new ROSTER sponsor or a text of another size."""
    os.makedirs(f'{t}/ds/XX-1/XX/2025/people'); os.makedirs(f'{t}/ds/XX-1/XX/2025/bill')
    for pid, first, last in ((7, 'Ann', 'Able'), (8, 'Bob', 'Best'), (9, 'Cy', 'Nobody')):
        json.dump({'person': {'people_id': pid, 'first_name': first, 'last_name': last, 'name': f'{first} {last}'}}, open(f'{t}/ds/XX-1/XX/2025/people/{pid}.json', 'w'))
    open(f'{t}/roster.tsv', 'w').write('politician_id\tfull_name\npa\tAnn Able\npb\tBob Best\n')
    prime = {'pid': 7, 't': 1}
    rows = [(1, 2026, [prime], 1000), (2, 2025, [prime], 1005),           # 2: same text, no new sponsor -> dropped
            (3, 2024, [prime, {'pid': 8, 't': 2}], 1000),                  # 3: adds roster sponsor Bob -> kept
            (4, 2023, [prime, {'pid': 9, 't': 2}], 1003),                  # 4: adds a sponsor NOT on the roster -> dropped
            (5, 2022, [prime], 1500)]                                      # 5: text size differs by 50% -> kept
    bills = [{'bill_id': i, 'st': 'XX', 'y': y, 'num': f'HB{i}', 'title': 'Carry permits.', 'res': False, 'sponsors': sp} for i, y, sp, _ in rows]
    for i, y, _, size in rows:
        json.dump({'bill': {'bill_id': i, 'texts': [{'type': 'Introduced', 'text_size': size}]}}, open(f'{t}/ds/XX-1/XX/2025/bill/HB{i}.json', 'w'))
    json.dump(bills, open(f'{t}/bills.json', 'w')); json.dump([], open(f'{t}/core.json', 'w'))
    json.dump({str(i): 'fill' for i, *_ in rows}, open(f'{t}/tri.json', 'w'))
    base = [f'{t}/bills.json', '--state', 'XX', '--roster', f'{t}/roster.tsv', '--core', f'{t}/core.json', '--ds', f'{t}/ds', '--triage', f'{t}/tri.json']
    run('sponsor_cover.py', *base, '--write', f'{t}/new.json')
    assert json.load(open(f'{t}/new.json')) == [1, 3, 5], json.load(open(f'{t}/new.json'))
    assert sorted(json.load(open(f'{t}/new.refiled.json'))) == ['2', '4']
    run('sponsor_cover.py', *base, '--keep-refiled', '--write', f'{t}/all.json')
    assert json.load(open(f'{t}/all.json')) == [1, 2, 3, 4, 5]


@check
def sponsor_cover_stubs_only_bills_no_roster_member_voted_on(t):
    """A "stub" is listed for the runner and left out of the core set, unless a roster member voted on the bill on the
    floor: then it is filled whatever the triage said. A committee roll call (a handful of members) is not a floor vote."""
    d = f'{t}/ds/XX-1/XX/2025'
    for sub in ('people', 'bill', 'vote'): os.makedirs(f'{d}/{sub}')
    for pid in range(1, 11):
        json.dump({'person': {'people_id': pid, 'first_name': f'F{pid}x', 'last_name': f'Last{"abcdefghij"[pid - 1]}', 'name': f'F{pid}x L'}}, open(f'{d}/people/{pid}.json', 'w'))
    open(f'{t}/roster.tsv', 'w').write('politician_id\tfull_name\npa\tF1x Lasta\n')
    floor = [{'people_id': i, 'vote_text': 'Yea'} for i in range(1, 11)]
    json.dump({'roll_call': {'roll_call_id': 1, 'bill_id': 1, 'chamber': 'H', 'votes': floor}}, open(f'{d}/vote/1.json', 'w'))       # floor: pa voted
    json.dump({'roll_call': {'roll_call_id': 2, 'bill_id': 2, 'chamber': 'H', 'votes': floor[:3]}}, open(f'{d}/vote/2.json', 'w'))   # committee: 3 of 10
    json.dump({'roll_call': {'roll_call_id': 3, 'bill_id': 3, 'chamber': 'H', 'votes': [dict(v, vote_text='Absent') if v['people_id'] == 1 else v for v in floor]}}, open(f'{d}/vote/3.json', 'w'))  # floor, pa absent
    bills = [{'bill_id': i, 'st': 'XX', 'y': 2025, 'num': f'HB{i}', 'title': tt, 'desc': 'd', 'res': False, 'sponsors': [{'pid': 1}]}
             for i, tt in ((1, 'Dealers: signs'), (2, 'Dealers: storage'), (3, 'Gun tax'), (4, 'Carry permits'))]
    json.dump(bills, open(f'{t}/bills.json', 'w')); json.dump([], open(f'{t}/core.json', 'w'))
    base = [f'{t}/bills.json', '--state', 'XX', '--roster', f'{t}/roster.tsv', '--core', f'{t}/core.json', '--ds', f'{t}/ds', '--keep-refiled']
    run('sponsor_cover.py', *base, '--candidates', f'{t}/cand.json')
    cand = {c['bill_id']: c for c in json.load(open(f'{t}/cand.json'))}
    assert [cand[i]['floor_voters'] for i in (1, 2, 3, 4)] == [1, 0, 0, 0], [cand[i]['floor_voters'] for i in (1, 2, 3, 4)]
    assert cand[1]['desc'] == 'd', 'the triage reads the summary line too'
    json.dump({'1': 'stub', '2': 'stub', '3': 'stub', '4': 'fill'}, open(f'{t}/tri.json', 'w'))
    p = run('sponsor_cover.py', *base, '--triage', f'{t}/tri.json', '--write', f'{t}/new.json')
    assert json.load(open(f'{t}/new.json')) == [1, 4], 'a stub a roster member voted on is filled; the other stubs stay out of core'
    assert 'stub -> fill: 2025 HB1' in p.stdout, p.stdout
    assert [x['bill_id'] for x in json.load(open(f'{t}/new.stubs.json'))] == [2, 3], 'stubs are listed for the runner'
    json.dump({'1': 'maybe', '2': 'stub', '3': 'stub', '4': 'fill'}, open(f'{t}/tri.json', 'w'))
    assert run('sponsor_cover.py', *base, '--triage', f'{t}/tri.json', '--write', f'{t}/x.json', ok=False).returncode != 0


@check
def run_recipe_replay_puts_back_the_first_pre_step_7_files(t):
    """--replay restores the pre-step-7 copies (keeping the current files), refuses when they are missing or out of date,
    and a later step-7 run never overwrites them while they are current."""
    sys.path.insert(0, TOOLS)
    import importlib; rr = importlib.import_module('run_recipe'); importlib.reload(rr)
    os.makedirs(t)
    w = lambda f, x: open(f'{t}/{f}', 'w').write(x)
    r = lambda f: open(f'{t}/{f}').read()
    w('research.csv', 'after-9'); w('evidence.csv', 'ev-after-9')
    try: rr.replay_restore(t); raise AssertionError('no pre-step-7 copies: must refuse')
    except rr.Stop as e: assert e.code == 2 and 'research-pre-step7.csv' in str(e)
    w('research-pre-step7.csv', 'clean'); w('evidence-pre-step7.csv', 'ev-clean')
    json.dump({'7': 'x', '8': 'x', '9': 'x', '8_stale': False}, open(f'{t}/recipe-log.json', 'w'))
    assert rr.replay_restore(t, dry=True) == 0 and r('research.csv') == 'after-9', '--print changes nothing'
    assert rr.replay_restore(t) == 1
    assert (r('research.csv'), r('evidence.csv')) == ('clean', 'ev-clean')
    assert (r('research-before-replay-1.csv'), r('evidence-before-replay-1.csv')) == ('after-9', 'ev-after-9'), 'the current files are kept'
    assert json.load(open(f'{t}/recipe-log.json'))['8_stale'] is True, 'step 9 must wait for step 8 again'
    w('research.csv', 'after-7-again'); rr.save_copies(t, 7)
    assert r('research-pre-step7.csv') == 'clean', 'a step-7 re-run must not overwrite the clean copy'
    assert rr.replay_restore(t) == 2 and r('research-before-replay-2.csv') == 'after-7-again'
    log = json.load(open(f'{t}/recipe-log.json')); log['pre7_stale'] = True; json.dump(log, open(f'{t}/recipe-log.json', 'w'))
    try: rr.replay_restore(t); raise AssertionError('an earlier step ran since: must refuse')
    except rr.Stop as e: assert 'out of date' in str(e)
    w('research.csv', 'new-evidence-run'); rr.save_copies(t, 7)
    assert r('research-pre-step7.csv') == 'new-evidence-run' and json.load(open(f'{t}/recipe-log.json'))['pre7_stale'] is False
    sys.path.remove(TOOLS)
    json.dump({'stage5': t, 'topic': 'tp', 'unit': 'state:xx', 'level': 'state', 'state': 'XX', 'roster': f'{t}/r.tsv', 'codes': t,
               'saved_root': t, 'votes': 'none'}, open(f'{t}/recipe.json', 'w'))
    w('held.txt', 'p1\n'); w('overrides.json', '{"trims": []}'); w('uncite.json', '[]')
    out = run('run_recipe.py', t, '--replay', '--print').stdout
    order = [out.index(x) for x in ('== step 7', 'drop_held.py', '== step 8', 'uncite.py', 'apply_overrides.py', '== step 9')]
    assert order == sorted(order), out
    assert 'apply_overrides.py' not in run('run_recipe.py', t, '--replay', '--print', '--no-reapply').stdout
    assert run('run_recipe.py', t, '--replay', '--from', '8', '--print', ok=False).returncode != 0


@check
def run_recipe_stops_on_a_high_and_on_stale_bill_text(t):
    """A gate high stops the run for hand work (exit 10); step 9 refuses while step 7 ran after step 8 (exit 2)."""
    os.makedirs(t)
    json.dump({'stage5': t, 'topic': 'tp', 'unit': 'state:xx', 'level': 'state', 'state': 'XX', 'roster': f'{t}/r.tsv',
               'codes': t, 'saved_root': t}, open(f'{t}/recipe.json', 'w'))
    open(f'{t}/gate-output-final.txt', 'w').write('stance-gate: 3 rows · high=2 medium=0 · evidence rows=9\n')
    assert run('run_recipe.py', t, '--check-only', '9', ok=False).returncode == 10
    open(f'{t}/gate-output-final.txt', 'w').write('stance-gate: 3 rows · high=0 medium=0 · evidence rows=9\n')
    assert run('run_recipe.py', t, '--check-only', '9').returncode == 0
    json.dump({'8_stale': True}, open(f'{t}/recipe-log.json', 'w'))
    p = run('run_recipe.py', t, '--from', '9', '--to', '9', ok=False)
    assert p.returncode == 2 and 'stale' in p.stdout, p.stdout
    open(f'{t}/dry-run-0.txt', 'w').write('outcomes: 1 (seated 1)\nrefused (2):\n  a  finding x…: kept off\n  b  CODE: a seat needs a value\n')
    assert run('run_recipe.py', t, '--check-only', '0', ok=False).returncode == 2, 'a refused code must stop the run'


@check
def run_recipe_writes_empty_fallback_list_only_when_nothing_is_needed(t):
    """No blank over a shown answer: an empty fallback/urls.txt (fallback-fetch crashed on a missing one, mo-01).
    Blanks over a shown answer: no list is made up; the fetch waits for the hand-written one."""
    sys.path.insert(0, TOOLS)
    import importlib; rr = importlib.import_module('run_recipe'); importlib.reload(rr)
    os.makedirs(f'{t}/a/fallback'); json.dump([], open(f'{t}/a/fallback/fallback-required.json', 'w'))
    assert rr.fallback_cmd(f'{t}/a', False) and open(f'{t}/a/fallback/urls.txt').read() == ''
    os.makedirs(f'{t}/b/fallback'); json.dump([{'name': 'X'}], open(f'{t}/b/fallback/fallback-required.json', 'w'))
    assert rr.fallback_cmd(f'{t}/b', False) is None and not os.path.exists(f'{t}/b/fallback/urls.txt')
    sys.path.remove(TOOLS)


@check
def write_batch_leaves_out_held_ids_without_moving_codes(t):
    """write-batch.sh passes held and moved ids to the writer as --skip-ids and never touches <stage5>/codes."""
    if not shutil.which('zsh'): print('     (skipped: no zsh)'); return
    os.makedirs(f'{t}/stage5/codes'); os.makedirs(f'{t}/batch'); os.makedirs(f'{t}/bin')
    for p in ('a', 'h', 'm'): open(f'{t}/stage5/codes/{p}.json', 'w').write('{}')
    open(f'{t}/batch/held.txt', 'w').write('h\n'); open(f'{t}/batch/moved.txt', 'w').write('m\n\n')
    open(f'{t}/batch/pids.txt', 'w').write('a\nh\nm\n')
    open(f'{t}/bin/npx', 'w').write(f'#!/bin/sh\nls {t}/stage5/codes > {t}/codes-during.txt\necho "$@" > {t}/args.txt\n'); os.chmod(f'{t}/bin/npx', 0o755)
    env = dict(os.environ, PATH=f'{t}/bin:' + os.environ['PATH'])
    p = subprocess.run(['zsh', os.path.join(TOOLS, 'write-batch.sh'), f'{t}/stage5', f'{t}/batch', 'tp', 'state:xx', '0'], capture_output=True, text=True, env=env)
    assert p.returncode == 0, p.stdout + p.stderr
    assert open(f'{t}/codes-during.txt').read().split() == ['a.json', 'h.json', 'm.json'], 'codes must stay in place during the run'
    args = open(f'{t}/args.txt').read()
    assert f'--skip-ids {os.path.realpath(t)}/batch/skip-ids.txt' in args and '--csv-out' in args, args
    assert open(f'{t}/batch/skip-ids.txt').read().split() == ['h', 'm'] and open(f'{t}/batch/pids-write.txt').read().split() == ['a']


@check
def search_effect_counts_changes_by_record_rung_and_codings(t):
    os.makedirs(f'{t}/plan')
    open(f'{t}/roster.tsv', 'w').write('politician_id\tfull_name\tlevel\tstate\n' + ''.join(f'{p}\t{p}\tstate\tXX\n' for p in 'abcdef') + 'z\tz\tstate\tYY\n')
    open(f'{t}/plan/search.tsv', 'w').write('politician_id\tfull_name\n' + ''.join(f'{p}\t{p}\n' for p in 'abcdz'))
    open(f'{t}/plan/control.tsv', 'w').write('politician_id\tfull_name\na\ta\n')
    R, F = f'{t}/rec', f'{t}/fin'
    for p, o, v in (('a', 'seated', 5), ('b', 'seated', 3), ('c', 'doesnt-fit', None), ('e', 'seated', 5)): code(R, p, o, v)
    for p, o, v in (('a', 'seated', 5), ('b', 'seated', 4), ('c', 'seated', 3), ('d', 'no-stance', None)): code(F, p, o, v)
    shutil.copyfile(f'{R}/e.json', f'{F}/e.json')  # e: skipped, record-only code adopted
    x = json.load(open(f'{F}/a.json')); x['coded_at'] = '2026-11-12T22:00:00Z'; json.dump(x, open(f'{F}/a.json', 'w'))  # a: re-coded, same seat
    run('search_effect.py', '--roster', f'{t}/roster.tsv', '--unit', 'state:xx', '--record-codes', R, '--codes', F, '--plan', f'{t}/plan', '--json', f'{t}/o.json')
    o = json.load(open(f'{t}/o.json'))
    assert o['searched'] == 4 and o['control_changed'] == 0, o
    b = o['by_record_result']
    assert (b['seated 3']['changed'], b['seated 3']['rung_only']) == (1, 1) and (b['doesnt-fit']['outcome_changed']) == 1 and b['seated 5']['changed'] == 0, b
    assert o['codings'] == {'record_only': 4, 'second_pass': 4, 'total': 8, 'per_person': 1.33}, o['codings']
    # With a grouped control and an id list: the controls are reported apart, and only listed people are counted.
    open(f'{t}/plan/control.tsv', 'w').write('politician_id\tfull_name\trecord_only\tgroup\na\ta\tseated 5\t5,2\nb\tb\tseated 3\t3\n')
    open(f'{t}/ids.txt', 'w').write('a\nb\nc\nd\n')
    run('search_effect.py', '--roster', f'{t}/roster.tsv', '--unit', 'state:xx', '--ids', f'{t}/ids.txt', '--record-codes', R, '--codes', F, '--plan', f'{t}/plan', '--json', f'{t}/o2.json')
    o = json.load(open(f'{t}/o2.json'))
    assert o['roster'] == 4 and o['controls'] == {'5,2': {'searched': 1, 'changed': 0}, '3': {'searched': 1, 'changed': 1}}, o
    assert o['codings'] == {'record_only': 3, 'second_pass': 4, 'total': 7, 'per_person': 1.75}, 'e is not on the id list, so it is not counted'


def profile(t, **over):
    p = {'topic_key': 'made-up-topic', 'label': 'made-up-topic S9 Stage 5', 'research': f'{t}/research', 'stage5': f'{t}/research/stage5',
         'sides': None, 'record_script': False, 'control_groups': [], 'settled': ['Trim rule: keep (runner, 2026-01-01).']}
    p.update(over); os.makedirs(p['stage5'], exist_ok=True)
    json.dump(p, open(f'{t}/profile.json', 'w')); return f'{t}/profile.json'


@check
def session_card_takes_every_topic_value_from_the_profile(t):
    """A card names no topic, side or rung of its own; an unfilled slot or a half-filled profile writes nothing."""
    os.makedirs(t)
    T = os.path.normpath(os.path.join(HERE, '..', '..', '..', '.claude', 'skills', 'season-topic-prep', 'templates'))
    for leg in 'AB':
        text = open(f'{T}/stage5-card-{leg}.md').read()
        for word in ('gun', 'firearm', '1,2,3/4,5', '5,2', 'rung 3', 'rung 5'): assert word not in text, f'card {leg} template names {word!r}'
    card = lambda leg, *a, ok=True: run('session_card.py', leg, '--state', 'zz', '--state-name', 'Zedland', '--out', f'{t}/card-{leg}.md', *a, ok=ok)
    P = profile(t)  # no skip rule, no script
    card('A', '--profile', P); card('B', '--profile', P)
    a, b = open(f'{t}/card-A.md').read(), open(f'{t}/card-B.md').read()
    assert '{{' not in a + b and 'made-up-topic' in a and 'Zedland' in b and f'{t}/research/stage5/zz/HANDOVER-A.md' in b
    assert 'Trim rule: keep' in a and 'Trim rule: keep' in b, 'settled rulings are on both cards'
    assert f'"saved_root": "{t}"' in b and '"topic": "made-up-topic"' in b, 'the recipe on the card is filled from the profile'
    assert 'search_list.py plan --' not in b and 'record-script.ts' not in b and 'Search everyone' in b, 'no skip rule: no plan command'
    assert len(a) < 14000 and len(b) < 16000, f'a card is a short page: A {len(a)}, B {len(b)}'
    P = profile(t, sides='1,2/3', record_script=True, control_groups=['1:7', '3,2:4'])
    card('B', '--profile', P); b = open(f'{t}/card-B.md').read()
    assert '--control-group 1:7 --control-group 3,2:4' in b and '--sides 1,2/3 --skip-rungs 1,3,2' in b and '{{' not in b, b[:300]
    assert 'rung 1 (control of 7); rungs 3 and 2 (control of 4)' in b
    P = profile(t, sides='1,2/3', record_script=True, control_groups=['1:7', '3:4:side'])
    card('B', '--profile', P); b = open(f'{t}/card-B.md').read()
    assert 'plan --control-group 1:7 --control-group 3:4:side --sides 1,2/3' in b and 'fails only on a change of side or outcome' in b and '--skip-rungs 1,3`' in b, b[:300]
    P = profile(t, control_groups=['1:7'])  # skip rule without the script
    card('B', '--profile', P); b = open(f'{t}/card-B.md').read()
    assert 'search_list.py plan --' in b and 'record-script.ts' not in b and 'not approved for this topic' in b
    os.remove(f'{t}/card-B.md')
    for bad in ({'record_script': True}, {'control_groups': ['5,2']}, {'stage5': 'relative/stage5'}, {'record_script': True, 'sides': '1/2', 'control_groups': []}):
        json.dump({**json.load(open(P)), **bad}, open(f'{t}/bad.json', 'w'))
        assert card('B', '--profile', f'{t}/bad.json', ok=False).returncode != 0 and not os.path.exists(f'{t}/card-B.md'), bad
    W = f'{t}/wt/.claude/skills/season-topic-prep/templates'; os.makedirs(W)
    open(f'{W}/stage5-card-B.md', 'w').write('{{TOPIC}} {{NOT_A_SLOT}}\n')
    r = card('B', '--profile', P, '--worktree', f'{t}/wt', ok=False)
    assert r.returncode != 0 and 'NOT_A_SLOT' in r.stderr + r.stdout and not os.path.exists(f'{t}/card-B.md'), 'an unfilled slot must write nothing'


def transcript(path, turns):
    """A main-session transcript: turns are (kind, timestamp, payload)."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as fh:
        for i, (kind, at, x) in enumerate(turns):
            if kind == 'say': o = {'type': 'user', 'timestamp': at, 'message': {'content': x}}
            elif kind == 'answer': o = {'type': 'user', 'timestamp': at, 'message': {'content': [{'type': 'tool_result', 'tool_use_id': x, 'content': 'ok'}]}}
            elif kind == 'note': o = {'type': 'file-history-snapshot', 'timestamp': at}
            else:
                content = [{'type': 'tool_use', 'id': x, 'name': 'AskUserQuestion', 'input': {'questions': [{'question': 'Carry on?'}]}}] if kind == 'ask' else [{'type': 'text', 'text': 'x'}]
                o = {'type': 'assistant', 'timestamp': at, 'message': {'id': f'm{i}', 'model': 'claude-opus-5-5', 'content': content,
                     'usage': {'input_tokens': 100, 'cache_creation_input_tokens': 0, 'cache_read_input_tokens': 1000, 'output_tokens': 10}}}
            fh.write(json.dumps(o) + '\n')


@check
def close_state_measures_whole_sessions_waits_and_refuses_to_replace_hand_work(t):
    """One command: units of every session and wave folder, waits a runner message ended, and no hand-written file replaced."""
    P = profile(t); S = f'{t}/research/stage5'
    os.makedirs(f'{S}/batches'); os.makedirs(f'{S}/waves/zz-search/out'); os.makedirs(f'{S}/waves/yy-search/out')
    open(f'{S}/batches/zz-ids.txt', 'w').write('a\nb\nc\nd\n')
    T = lambda h, m: f'2026-01-01T{h:02d}:{m:02d}:00.000Z'
    A, B = f'{t}/proj/main/aaaa.jsonl', f'{t}/proj/main/bbbb.jsonl'
    transcript(A, [('say', T(1, 0), 'go'), ('step', T(1, 1), 0), ('ask', T(1, 2), 'q1'), ('answer', T(1, 32), 'q1'), ('step', T(1, 33), 0)])
    transcript(B, [('say', T(2, 0), 'go'), ('step', T(2, 1), 0), ('note', T(2, 20), 0), ('say', T(2, 21), 'Yes, write it'), ('step', T(2, 22), 0),
                   ('step', T(2, 40), 0), ('answer', T(2, 50), 'not-a-question')])  # an ordinary tool result after a slow tool: not a wait on the runner
    transcript(f'{t}/proj/agents/cccc.jsonl', [('say', T(1, 5), 'search this person'), ('step', T(1, 6), 0)])
    transcript(f'{t}/proj/agents/dddd.jsonl', [('say', T(1, 5), 'search another state'), ('step', T(1, 6), 0)])
    json.dump({'session_id': 'cccc'}, open(f'{S}/waves/zz-search/out/find-a.result.json', 'w'))
    json.dump({'session_id': 'dddd'}, open(f'{S}/waves/yy-search/out/find-z.result.json', 'w'))
    step = 100 + 0.1 * 1000 + 5 * 10  # one made-up step, in weighted units
    args = ['--profile', P, '--state', 'zz', '--projects', f'{t}/proj']
    run('close_state.py', *args, '--session', A, '--leg', 'A')
    assert json.load(open(f'{S}/zz/usage-A.json'))['main_units'] == 3 * step and not os.path.exists(f'{S}/search-effect-zz.json')
    run('close_state.py', *args, '--session', A, '--session', B)
    u = json.load(open(f'{S}/zz/usage-zz.json'))
    assert u['main_units'] == 6 * step and u['total_units'] == 7 * step and u['people'] == 4, 'both sessions, this state\'s wave only'
    assert list(u['waves']) == ['zz-search'] and u['waves']['zz-search']['agents'] == 1, u['waves']
    waits = [(w['minutes'], w['ended_by']) for s in u['sessions'] for w in s['waits']]
    assert waits == [(30, 'an answer to a question'), (20, 'Yes, write it')], f'a snapshot line or a tool result is not the runner: {waits}'
    md = open(f'{S}/zz/MEASURES.md').read()
    assert f'{7 * step / 4:,.0f}' in md and 'Carry on?' in md and 'made-up-topic' in md and '| Gate runs | __' in md, md[:400]
    assert os.path.exists(f'{S}/zz/HANDOVER-B-skeleton.md')
    run('close_state.py', *args, '--session', A, '--session', B)  # its own page may be written again
    # Ohio 2026-11-16: the desk's second run wiped the rows the leg had filled in. A filled row survives a re-run.
    page = open(f'{S}/zz/MEASURES.md').read(); gate_row = next(l for l in page.split('\n') if l.startswith('| Gate runs |'))
    assert '__' in gate_row, gate_row
    open(f'{S}/zz/MEASURES.md', 'w').write(page.replace(gate_row, '| Gate runs | 3 (30, 18, 0) |'))
    run('close_state.py', *args, '--session', A, '--session', B)
    again = open(f'{S}/zz/MEASURES.md').read()
    assert '| Gate runs | 3 (30, 18, 0) |' in again and '| Runner stops | __' in again, 'a filled row is kept; an unfilled one is still asked for'
    open(f'{S}/zz/MEASURES.md', 'w').write('# written by hand\n')
    r = run('close_state.py', *args, '--session', A, '--session', B, ok=False)
    assert r.returncode != 0 and open(f'{S}/zz/MEASURES.md').read() == '# written by hand\n', 'a hand-written page is never replaced'
    assert run('close_state.py', *args, '--session', f'{t}/proj/main/none.jsonl', ok=False).returncode != 0


def topic_folder(t, **over):
    """A made-up topic's stage5 folder with a config, rulings, a roster of four and one stored bill. Returns (profile path, stage5)."""
    P = profile(t, topic_name='made-up topic', search={'subjects': ['widget limits;', 'widget permits.'], 'words': ['widget', 'gadget'],
                                                     'subject_examples': ['limit widgets', 'permit gadgets']}, **over)
    S = f'{t}/research/stage5'; os.makedirs(f'{S}/batches', exist_ok=True)
    json.dump({'topic_key': 'made-up-topic', 'codebook': '9.9', 'ladder_text': '   Question: "How many widgets?"\n   1. None.\n   2. Some.\n   3. All.'}, open(f'{S}/coder-config.json', 'w'))
    open(f'{S}/coder-rulings.md', 'w').write('# r\n\n## General {all}\n\n- g\n\n## Zedland notes {state:zz}\n\n- z\n\n## Other notes {state:yy}\n\n- y\n')
    rows = ''.join(f'{p}\tPerson {p.upper()}\tstate\tZZ\t{sc}\n' for p, sc in (('a', 'sitting'), ('b', 'both'), ('c', 'candidate'), ('d', 'sitting')))
    for f in (f'{S}/roster.tsv', f'{S}/batches/zz-roster.tsv'): open(f, 'w').write('politician_id\tfull_name\tlevel\tstate\tscope\n' + rows)
    open(f'{S}/batches/zz-ids.txt', 'w').write('a\nb\nc\nd\n')
    return P, S


@check
def stage5_prompts_fill_every_slot_from_the_profile_for_any_topic(t):
    """Search briefs, bill-table prompts, quote-check prompts and coder jobs: no topic word of the tool's own, no unfilled slot."""
    os.makedirs(t); P, S = topic_folder(t)
    T = os.path.normpath(os.path.join(HERE, '..', '..', '..', '.claude', 'skills', 'season-topic-prep', 'templates'))
    brief = open(f'{T}/BRIEF-stage5-find.md').read()
    for word in ('voter', 'SAVE Act', 'gun', 'firearm', 'citizenship'): assert word not in brief, f'the search brief template names {word!r}'
    src = open(os.path.join(TOOLS, 'stage5_prompts.py')).read() + open(os.path.join(TOOLS, 'run_state.py')).read()
    for word in ('gun', 'firearm', 'voter'): assert word not in src, f'a shared tool names {word!r}'
    os.makedirs(f'{S}/zz/find'); open(f'{S}/zz/find/d.json', 'w').write('{}')  # d is already searched
    open(f'{t}/note.md', 'w').write('Skip the Zedland sponsor lists.')
    sb = ['search-briefs', '--profile', P, '--state', 'zz', '--roster', f'{S}/batches/zz-roster.tsv']
    run('stage5_prompts.py', *sb, '--ids', f'{S}/batches/zz-ids.txt', '--note-file', f'{t}/note.md')
    b = open(f'{S}/zz/briefs/b.md').read()
    assert '{{' not in b and 'How many widgets?' in b and '"widget", "gadget"' in b and 'widget permits.' in b and '"limit widgets", "permit gadgets"' in b
    assert 'Skip the Zedland sponsor lists.' in b and f'{S}/zz/find/b.json' in b and 'and a candidate' in b and 'Before you finish' in b
    jobs = open(f'{S}/waves/zz-search/jobs.tsv').read().splitlines()
    assert [j.split('\t')[0] for j in jobs[1:]] == ['find-a', 'find-b', 'find-c'] and all(j.split('\t')[2] == 'sonnet' for j in jobs[1:]), 'the searched person is left out'
    open(f'{t}/again.txt', 'w').write('a\n')
    run('stage5_prompts.py', *sb, '--ids', f'{t}/again.txt', '--round', '2')
    assert f'{S}/zz/find-2/a.json' in open(f'{S}/zz/briefs-2/a.md').read() and open(f'{S}/waves/zz-search-2/jobs.tsv').read().splitlines()[1].startswith('find2-a\t')
    open(f'{t}/bad.txt', 'w').write('nobody\n')
    assert run('stage5_prompts.py', *sb, '--ids', f'{t}/bad.txt', ok=False).returncode != 0, 'an id that is not in the roster'
    json.dump({k: v for k, v in json.load(open(P)).items() if k != 'search'}, open(f'{t}/nosearch.json', 'w'))
    assert run('stage5_prompts.py', 'search-briefs', '--profile', f'{t}/nosearch.json', '--state', 'zz', '--roster', f'{S}/batches/zz-roster.tsv', '--ids', f'{t}/again.txt', ok=False).returncode != 0
    # bill table: the bills must be in the store of the worktree given; the rulings are {all} and this state's
    W = f'{t}/wt'; shutil.copytree(T, f'{W}/.claude/skills/season-topic-prep/templates'); store = f'{W}/backend/data/source-store/instruments/state-zz'; os.makedirs(store)
    for i in ('ZZ-HB-1-2025', 'ZZ-HB-2-2025', 'ZZ-SB-3-2025'): open(f'{store}/{i}.json', 'w').write('{}')
    json.dump({'kept': ['ZZ-HB-1-2025', 'ZZ-HB-2-2025', 'ZZ-SB-3-2025']}, open(f'{t}/bills.json', 'w'))
    bt = ['bill-table', '--profile', P, '--state', 'zz', '--state-name', 'Zedland', '--worktree', W]
    run('stage5_prompts.py', *bt, '--bills', f'{t}/bills.json', '--parts', '2')
    p0 = open(f'{S}/waves/zz-billtable/part0.md').read()
    assert '{{' not in p0 and '## General {all}' in p0 and '## Zedland notes' in p0 and '## Other notes' not in p0 and '1 to 3' in p0, 'three rungs, two rulings sections'
    assert 'ZZ-HB-1-2025' in p0 and 'ZZ-HB-2-2025' not in p0 and f'{S}/bill-table-zz.part0.json' in p0 and len(open(f'{S}/waves/zz-billtable/jobs.tsv').read().splitlines()) == 3
    json.dump(['ZZ-HB-9-2025'], open(f'{t}/gone.json', 'w'))
    assert run('stage5_prompts.py', *bt, '--bills', f'{t}/gone.json', ok=False).returncode != 0, 'a bill that is not in the store'
    with open(f'{W}/.claude/skills/season-topic-prep/templates/stage5-bill-table-prompt.md', 'a') as fh: fh.write('\n{{NOT_A_SLOT}}\n')
    shutil.rmtree(f'{S}/waves/zz-billtable')
    r = run('stage5_prompts.py', *bt, '--bills', f'{t}/bills.json', ok=False)
    assert r.returncode != 0 and 'NOT_A_SLOT' in r.stderr and not os.path.exists(f'{S}/waves/zz-billtable/part0.md'), 'an unfilled slot writes no prompt'
    # quote check: one line per finding the dry run names, once
    B = f'{S}/write/zz-01'; os.makedirs(B); os.makedirs(f'{S}/codes')
    f1, f2 = 'a' * 64, 'b' * 12 + 'c' * 52
    uid = '0e935fed-534e-42b0-a5ad-74f4199ff6df'
    json.dump({'finding_ids': [f1, f2]}, open(f'{S}/codes/{uid}.json', 'w'))
    open(f'{B}/dry.txt', 'w').write(f'refused (3):\n  {uid}  finding {f1[:12]}…: no quote check\n  {uid}  finding {f2[:12]}…: no quote check\n  {uid}  finding {f1[:12]}…: again\n')
    run('stage5_prompts.py', 'quote-check', '--profile', P, '--batch', B, '--dry-run', f'{B}/dry.txt', '--per', '1')
    assert json.load(open(f'{B}/qc/to-check.json')) == [[f1, uid], [f2, uid]], 'a finding listed twice is checked once'
    q = open(f'{B}/qc/qc-prompt-2.md').read()
    assert '{{' not in q and f2 in q and f1 not in q and 'made-up topic' in q and 'version 9.9' in q and f'{B}/qc/qc-2.jsonl' in q and 'Write all 1 lines' in q
    assert len(open(f'{B}/qc/jobs.tsv').read().splitlines()) == 3
    os.makedirs(f'{t}/cb'); [open(f'{t}/cb/{n}', 'w').write('x') for n in ('zz-01.md', 'zz-02.md', 'zz-01-r1.md', 'zz-rec-01.md')]
    run('stage5_prompts.py', 'coder-jobs', '--briefs', f'{t}/cb', '--name', 'zz', '--wave', f'{t}/cw')
    j = open(f'{t}/cw/jobs.tsv').read().splitlines()
    assert [x.split('\t')[0] for x in j[1:]] == ['zz-01', 'zz-02'] and all(x.endswith('\topus\tRead,Write') for x in j[1:]), 'coders are Opus, with Read and Write only'


STUB = """import os, sys
a = sys.argv[1:]; key = os.path.basename(sys.argv[0]) + (' ' + a[0] if a and not a[0].startswith(('-', '/')) else '')
C = os.environ['STUB_DIR']; open(C + '/calls.txt', 'a').write(key + ' :: ' + ' '.join(a) + chr(10))
f = C + '/exit ' + key
if os.path.exists(f + ' once'): code = int(open(f + ' once').read()); os.remove(f + ' once'); sys.exit(code)
if os.path.exists(C + '/say ' + key): print(open(C + '/say ' + key).read())
if os.path.exists(C + '/do ' + key): exec(open(C + '/do ' + key).read())
sys.exit(int(open(f).read()) if os.path.exists(f) else 0)
"""


@check
def run_state_chains_the_steps_and_stops_only_where_a_person_is_needed(t):
    """Record pass to early check in order; each stop that needs a ruling or a coder ends the run before the next step."""
    os.makedirs(t); P, S = topic_folder(t, sides='1/2,3', record_script=True, control_groups=['3:2', '1:2'])
    tools, bin_, C = f'{t}/tools', f'{t}/bin', f'{t}/stub'
    for d in (tools, bin_, C, f'{S}/record-briefs-zz', f'{S}/code-briefs', f'{S}/search-plan-zz'): os.makedirs(d)
    for n in ('run_state.py', 'session_card.py', 'legislature.py', '_args.py'): shutil.copy(os.path.join(TOOLS, n), tools)
    for n in ('wave.py', 'stage5_prompts.py', 'search_list.py', 'search_effect.py', 'roster_sync.py', 'bill_table.py'): open(f'{tools}/{n}', 'w').write(STUB)
    for n in ('npx', 'npm'):  # npx tsx scripts/stage5/<tool>.ts <args> ; npm run <script> --prefix <dir> -- <args>
        open(f'{bin_}/{n}', 'w').write(f'#!/bin/sh\nif [ "$1" = tsx ]; then shift; else shift; fi\nexec {sys.executable} -I {C}/stub.py "$@"\n'); os.chmod(f'{bin_}/{n}', 0o755)
    open(f'{C}/stub.py', 'w').write(STUB.replace("os.path.basename(sys.argv[0]) + (' ' + a[0] if a and not a[0].startswith(('-', '/')) else '')",
                                                 "os.path.basename(a[0]) + ((' ' + a[1]) if len(a) > 1 and a[1] in ('plan', 'adopt') else '')"))
    for n in ('zz-rec-01', 'zz-rec-02'): open(f'{S}/record-briefs-zz/{n}.ids.txt', 'w').write('a\n')
    open(f'{S}/code-briefs/zz-01.ids.txt', 'w').write('a\n'); open(f'{S}/search-plan-zz/recode-ids.txt', 'w').write('a\n')
    open(f'{S}/search-plan-zz/research-again-ids.txt', 'w').write('b\n')
    env = dict(os.environ, STUB_DIR=C, PATH=bin_ + os.pathsep + os.environ['PATH'])
    def go(*a):
        if os.path.exists(f'{C}/calls.txt'): os.remove(f'{C}/calls.txt')
        p = subprocess.run([sys.executable, '-I', f'{tools}/run_state.py', '--profile', P, '--state', 'zz', '--worktree', f'{t}/wt', '--tools', tools, *a], capture_output=True, text=True, env=env)
        calls = [l.split(' :: ')[0] for l in open(f'{C}/calls.txt')] if os.path.exists(f'{C}/calls.txt') else []
        return p, calls
    os.makedirs(f'{t}/wt/backend')
    def stub(key, code, once=False): open(f'{C}/exit {key}' + (' once' if once else ''), 'w').write(str(code))
    def clear():
        for f in os.listdir(C):
            if f.startswith(('exit ', 'say ')): os.remove(f'{C}/{f}')
    p, calls = go()
    want = ['roster_sync.py', 'bill_table.py check', 'record-script.ts plan', 'coder-inputs.ts', 'stage5_prompts.py coder-jobs', 'wave.py', 'split-codes.ts', 'split-codes.ts', 'record-script.ts adopt',
            'search_list.py plan', 'stage5_prompts.py search-briefs', 'wave.py', 'topic:stage5-find', 'search_list.py recode',
            'stage5_prompts.py search-briefs', 'wave.py', 'topic:stage5-find', 'search_list.py recode',
            'coder-inputs.ts', 'stage5_prompts.py coder-jobs', 'wave.py', 'split-codes.ts', 'search_list.py adopt', 'search_effect.py',
            'topic:stage5-report', 'topic:stage5-theme-prompt', 'wave.py', 'topic:stage5-report']
    assert p.returncode == 0 and calls == want, (p.returncode, p.stdout[-400:], calls)
    full = open(f'{C}/calls.txt').read()
    assert '--control-group 3:2 --control-group 1:2' in full and '--sides 1/2,3 --skip-rungs 3,1' in full and f'--dir {S}/zz/find-2 ' in full and '--round 2' in full
    assert f'--ids {S}/batches/zz-ids.txt --record-codes' in full and '--topic made-up-topic' in full and sorted(json.load(open(f'{S}/zz/run/log.json'))) == list('1234567')
    stub('record-script.ts adopt', 4); p, calls = go()
    assert p.returncode == 4 and calls[-1] == 'record-script.ts adopt' and 'standing check' in p.stdout, 'a failed standing check ends the run before the search plan'
    clear(); stub('split-codes.ts', 1); p, calls = go()
    assert p.returncode == 10 and 'search_list.py plan' not in calls and 'never by hand' in p.stdout, 'a sent-back code goes to a coder'
    assert '--round sb1' in p.stdout and 'record-script.ts adopt --out' in p.stdout and '--from 2' in p.stdout, 'the resume after a step-1 send-back names the standing check it would skip'
    clear(); open(f'{C}/say topic:stage5-find', 'w').write('refused 0e935fed-534e-42b0-a5ad-74f4199ff6df.json: a party name in places')
    p, calls = go('--from', '3'); assert p.returncode == 10 and calls[-1] == 'topic:stage5-find' and 'refused 1 search file' in p.stdout, p.stdout
    clear(); stub('search_list.py adopt', 4); p, calls = go('--from', '6')
    assert p.returncode == 4 and calls == ['search_list.py adopt', 'search_effect.py'] and 'reopened.tsv' in p.stdout, 'the effect is still measured; the early check waits'
    clear(); stub('topic:stage5-report', 4); p, calls = go('--from', '7')
    assert p.returncode == 4 and 'runner stop 2' in p.stdout and len(calls) == 4, 'the themes are made before the runner is asked'
    clear(); stub('topic:stage5-report', 3); p, calls = go('--from', '7'); assert p.returncode == 10 and len(calls) == 1
    clear(); stub('wave.py', 1); p, calls = go('--from', '5'); assert p.returncode == 2 and calls[-1] == 'wave.py', 'a failed command ends the run'
    clear(); p, calls = go('--from', '6', '--to', '6'); assert p.returncode == 0 and calls == ['search_list.py adopt', 'search_effect.py']
    p, calls = go('--print'); assert p.returncode == 0 and not calls and '# step 7: check' in p.stdout, '--print runs nothing'
    # --- a round: some people coded again, from a brief that holds only them
    clear(); ids = [f'{n}0000000-0000-4000-8000-000000000000' for n in '12345']; P1, P2, P3, P4, P5 = ids
    val = lambda flag: "a[a.index('" + flag + "') + 1]"
    open(f'{C}/do coder-inputs.ts', 'w').write(f"os.makedirs({val('--out')}, exist_ok=True); b = {val('--out')} + '/' + {val('--name')} + '-01'\n"
                                               f"open(b + '.ids.txt', 'w').write(open({val('--ids')}).read()); open(b + '.md', 'w').write('BRIEF ' + ' '.join(a))\n")
    open(f'{C}/do split-codes.ts', 'w').write(f"os.makedirs({val('--codes')}, exist_ok=True)\nfor p in open({val('--ids')}).read().split(): open({val('--codes')} + '/' + p + '.json', 'w').write('new ' + a[1])\n")
    for d in ('record-coded', 'coded', 'record-codes', 'codes'): os.makedirs(f'{S}/{d}', exist_ok=True)
    put = lambda f, text: open(f'{S}/{f}', 'w').write(text)
    put('record-coded/zz-rec-01.sendback.md', f'# Sent back: zz-rec-01\n\nFix each code below.\n\n### {P1}\n- names a bill not in the findings: XX-HB-9-2025\n\n### {P4}\n- no rung given\n')
    put('coded/zz-01.sendback.md', f'# Sent back: zz-01\n\n### {P2}\n- quotes a finding it does not cite\n- quotes a finding it does not cite\n\n### missing from the file\n- {P3}: no code given; code this person\n\n### not in this batch\n- {P5}: not in the batch list\n')
    put('record-codes/' + P1 + '.json', 'old record'); put('codes/' + P1 + '.json', 'old adopted'); put('codes/' + P2 + '.json', 'old second')
    put('search-plan-zz/recode-ids.txt', f'{P2}\n{P3}\n')
    p, calls = go('--round', 'sb1'); R = f'{S}/zz/rounds/sb1'; full = open(f'{C}/calls.txt').read().splitlines()
    assert p.returncode == 0 and calls == ['coder-inputs.ts', 'stage5_prompts.py coder-jobs', 'wave.py', 'split-codes.ts'] * 2, (p.returncode, p.stdout[-500:], calls)
    assert '2 record-only, 2 second-pass; 4 coded again, 0 sent back' in p.stdout, p.stdout
    assert '--record-only' in full[0] and f'--out {R}/briefs-rec' in full[0] and f'--coded-dir {R}/coded-rec ' in full[0] and '--name zz-rec-sb1' in full[0] and '--bill-table' in full[0]
    assert '--record-only' not in full[4] and '--name zz-code-sb1' in full[4] and f'--coded-dir {R}/coded ' in full[4]
    assert f'--codes {S}/record-codes ' in full[3] and full[3].endswith('--replace') and f'--codes {S}/codes ' in full[7] and full[7].endswith('--replace')
    assert open(f'{R}/rec-ids.txt').read().split() == [P1, P4] and open(f'{R}/code-ids.txt').read().split() == [P2, P3], 'each person is coded where their code lives, and nobody else is in the brief'
    rb, cb = open(f'{R}/briefs-rec/zz-rec-sb1-01.md').read(), open(f'{R}/briefs-code/zz-code-sb1-01.md').read()
    assert rb.startswith('BRIEF ') and 'second coding round (sb1)' in rb and f'`{P1}`: names a bill not in the findings: XX-HB-9-2025' in rb and f'`{P4}`: no rung given' in rb and P2 not in rb.split('second coding round')[1]
    assert cb.count('quotes a finding it does not cite') == 1 and f'`{P3}`: no code was given for this person' in cb and P5 not in cb.split('second coding round')[1], 'reasons are given once; a person outside the batch is not coded'
    got = lambda f: open(f'{S}/{f}').read()
    assert got(f'record-codes/{P1}.json').startswith('new ') and got(f'codes/{P1}.json') == got(f'record-codes/{P1}.json'), 'an adopted record code follows its new record code'
    assert not os.path.exists(f'{S}/codes/{P4}.json'), 'a record code that was never adopted is not put in codes/ by the round'
    assert got(f'zz/codes-before-sb1/record-codes/{P1}.json') == 'old record' and got(f'zz/codes-before-sb1/codes/{P1}.json') == 'old adopted' and got(f'zz/codes-before-sb1/codes/{P2}.json') == 'old second'
    assert not glob.glob(f'{S}/*coded/*.sendback.md') and len(glob.glob(f'{S}/*coded/*.sendback.answered.md')) == 2, 'an answered send-back is not answered twice'
    p, calls = go('--round', 'sb1'); assert p.returncode == 2 and not calls and 'new name' in p.stdout
    p, calls = go('--round', 'sb2'); assert p.returncode == 2 and not calls and 'nobody to code again' in p.stdout and not os.path.isdir(f'{S}/zz/rounds/sb2')
    open(f'{t}/again.txt', 'w').write(f'{P2}\n{P5}\n{P2}\n'); open(f'{t}/why.md', 'w').write('A ruling was added for this state since the first coding. It is in the rulings above.')
    stub('split-codes.ts', 3); p, calls = go('--round', 'r2', '--ids', f'{t}/again.txt', '--why', f'{t}/why.md'); R = f'{S}/zz/rounds/r2'
    assert p.returncode == 10 and len(calls) == 8 and 'another round under a new name' in p.stdout and f'{R}/coded/zz-code-r2-01.sendback.md' in p.stdout, (p.returncode, p.stdout)
    assert open(f'{R}/rec-ids.txt').read().split() == [P5] and open(f'{R}/code-ids.txt').read().split() == [P2], 'with --ids, a person with a second-pass code is coded from everything, anyone else from the record'
    for f in (f'{R}/briefs-rec/zz-rec-r2-01.md', f'{R}/briefs-code/zz-code-r2-01.md'):
        assert 'A ruling was added for this state' in open(f).read() and 'refused an earlier code' not in open(f).read()
    clear(); put('rounds-probe.sendback.md', 'x'); os.makedirs(f'{S}/zz/rounds/r2/coded'); put('zz/rounds/r2/coded/zz-code-r2-01.sendback.md', f'### {P2}\n- cites a bill with no file\n'); p, calls = go('--round', 'sb3')
    assert p.returncode == 0 and open(f'{S}/zz/rounds/sb3/code-ids.txt').read().split() == [P2] and not os.path.exists(f'{S}/zz/rounds/sb3/rec-ids.txt'), 'a round\'s own send-back is picked up by the next round'
    p, calls = go('--round', 'Bad Name'); assert p.returncode == 2 and not calls
    p, calls = go('--round', 'sb9', '--print'); assert not calls and not os.path.isdir(f'{S}/zz/rounds/sb9'), '--print runs nothing'
    json.dump({**json.load(open(P)), 'control_groups': [], 'record_script': False}, open(f'{t}/noskip.json', 'w'))
    r = subprocess.run([sys.executable, '-I', f'{tools}/run_state.py', '--profile', f'{t}/noskip.json', '--state', 'zz'], capture_output=True, text=True, env=env)
    assert r.returncode != 0 and 'no skip rule' in r.stderr, 'a topic with no skip rule is refused, not run with another topic\'s rule'


def leg_profile(wt, xx='zz', **over):
    """A made-up legislature profile in a made-up worktree."""
    p = {'state': xx, 'name': 'Zedland', 'verified': '2026-01-02', 'source': 'a made-up hand-over', 'chambers': {'lower': 'House', 'upper': 'Senate'},
         'sessions': 'Two-year sessions.', 'bill_data': ['Bulk files.'],
         'votes': {'mode': 'legiscan-plan', 'official_hosts': ['votes.zz.example'], 'legiscan_args': '--session-start odd', 'floor_rule': 'Passage motions only.', 'gaps': []},
         'texts': {'hosts': ['texts.zz.example'], 'marks': 'Added words underlined.', 'note': ''},
         'reader_access': {'votes.zz.example': 'blocked: robots.txt', 'texts.zz.example': 'open'},
         'search_note': 'Skip the Zedland vote pages.', 'bill_table_note': '- Zedland marks new law in capitals.',
         'fill_quotes': {'label_strips': ['^\\s*NEW PART\\.?\\s*']}, 'quirks': ['Members are listed by surname only.']}
    p.update(over); d = f'{wt}/backend/data/legislatures'; os.makedirs(d, exist_ok=True)
    json.dump(p, open(f'{d}/{xx}.json', 'w')); return p


@check
def legislature_profiles_hold_legislature_facts_only_and_reach_the_cards_and_prompts(t):
    """A profile is checked before anything reads it; the cards and prompts take the recipe and notes from it."""
    os.makedirs(t); W = f'{t}/wt'
    assert run('legislature.py', 'check').stdout.count(': ok') >= 3 and ': ok' in run('legislature.py', 'check', 'wa').stdout, 'the profiles on file pass'
    leg_profile(W)
    assert 'zz: ok' in run('legislature.py', 'check', '--worktree', W).stdout
    show = run('legislature.py', 'show', 'zz', '--worktree', W).stdout
    assert 'votes.zz.example`: blocked: robots.txt' in show and 'Verified 2026-01-02' in show and 'surname only' in show
    for bad, why in (({'search_note': 'Skip the gun bill lists.'}, 'names a topic'), ({'quirks': ['Rung 3 bills are common.']}, 'names a topic'),
                     ({'reader_access': {'texts.zz.example': 'open'}}, 'says nothing about votes.zz.example'), ({'verified': 'last week'}, 'must be a date'),
                     ({'fill_quotes': {'label_strips': ['(']}}, 'does not compile'), ({'reader_access': {'votes.zz.example': 'fine', 'texts.zz.example': 'open'}}, 'must be "open"'),
                     ({'state': 'yy'}, '"state" must be')):
        leg_profile(W, **bad); r = run('legislature.py', 'check', 'zz', '--worktree', W, ok=False)
        assert r.returncode == 1 and why in r.stdout, (bad, r.stdout)
    T = os.path.normpath(os.path.join(HERE, '..', '..', '..', '.claude', 'skills', 'season-topic-prep', 'templates'))
    shutil.copytree(T, f'{W}/.claude/skills/season-topic-prep/templates')
    r = run('session_card.py', 'B', '--profile', profile(t), '--state', 'zz', '--state-name', 'Zedland', '--worktree', W, '--out', f'{t}/x.md', ok=False)
    assert r.returncode != 0 and '"state" must be' in r.stderr and not os.path.exists(f'{t}/x.md'), 'a profile that fails its check stops the card'
    leg_profile(W)
    P, S = topic_folder(t, control_groups=['1:7'])
    card = lambda leg, st: (run('session_card.py', leg, '--profile', P, '--state', st, '--state-name', 'Zedland', '--worktree', W, '--out', f'{t}/c.md'), open(f'{t}/c.md').read())[1]
    b = card('B', 'zz')
    assert '"votes": "legiscan-plan", "official_host": "votes.zz.example", "max_urls": 20,\n "legiscan_args": "--session-start odd"}' in b and '<votes mode>' not in b
    assert 'blocked: robots.txt' in b and '{{' not in b and 'surname only' in card('A', 'zz')
    b = card('B', 'qq'); assert '<votes mode>' in b and 'No legislature profile is on file for `qq`' in b, 'no profile: the recipe is filled by hand, and the card says so'
    leg_profile(W, votes={'mode': 'legiscan-plan', 'official_hosts': ['votes.zz.example'], 'legiscan_args': None, 'floor_rule': 'x', 'gaps': []})
    assert 'legiscan_args' not in card('B', 'zz').split('**B9.')[1].split('```')[1], 'no extra flags: no legiscan_args line'
    leg_profile(W)
    store = f'{W}/backend/data/source-store/instruments/state-zz'; os.makedirs(store); open(f'{store}/ZZ-HB-1-2025.json', 'w').write('{}')
    json.dump(['ZZ-HB-1-2025'], open(f'{t}/bills.json', 'w'))
    bt = ['bill-table', '--profile', P, '--state', 'zz', '--state-name', 'Zedland', '--worktree', W, '--bills', f'{t}/bills.json', '--parts', '1']
    run('stage5_prompts.py', *bt); assert 'Zedland marks new law in capitals.' in open(f'{S}/waves/zz-billtable/part0.md').read()
    open(f'{t}/note.md', 'w').write('- A note for this run only.'); run('stage5_prompts.py', *bt, '--note-file', f'{t}/note.md')
    p0 = open(f'{S}/waves/zz-billtable/part0.md').read(); assert 'A note for this run only.' in p0 and 'capitals' not in p0, 'a note given for the run replaces the profile\'s'
    open(f'{t}/one.txt', 'w').write('a\n')
    run('stage5_prompts.py', 'search-briefs', '--profile', P, '--state', 'zz', '--roster', f'{S}/batches/zz-roster.tsv', '--ids', f'{t}/one.txt', '--worktree', W)
    assert 'Skip the Zedland vote pages.' in open(f'{S}/zz/briefs/a.md').read()


@check
def check_fill_quotes_reads_the_text_with_and_without_struck_words(t):
    """A quote must be in the saved text, as printed or as the law reads after the strikes; a wrong quote fails."""
    os.makedirs(f'{t}/fill'); os.makedirs(f'{t}/texts'); W = f'{t}/wt'; leg_profile(W)
    open(f'{t}/texts/ZZ-HB-1-2025.enrolled.txt', 'w').write('A person may not sell a [-large-] widget {+of any size+} to a buyer who has no permit at all. Other words follow here.')
    def fill(lines, **k): json.dump({'id': 'ZZ-HB-1-2025', 'on_topic': True, 'operative_text': '\n'.join(lines), **k}, open(f'{t}/fill/ZZ-HB-1-2025.json', 'w'))
    go = lambda *a, ok=True: run('check_fill_quotes.py', '--fills', f'{t}/fill', '--texts', f'{t}/texts', '--state', 'zz', '--worktree', W, *a, ok=ok)
    fill(['Sec. 3 (new): A person may not sell a widget of any size to a buyer who has no permit',     # as the law reads after the strike
          'NEW PART. Sec. 4: A person may not sell a large widget of any size to a buyer who',           # as printed; the label is the legislature's own
          '(a) may not sell a widget ... to a buyer who has no permit at all'])
    assert 'checked 3 quote parts; misses 0' in go().stdout
    fill(['Sec. 3: A person may always sell a widget of any size to any buyer who asks'])
    r = go(ok=False); assert r.returncode == 1 and 'MISS ZZ-HB-1-2025' in r.stdout, 'a planted wrong quote must fail'
    assert go('--skip', 'ZZ-HB-1-2025').returncode == 0 and '0 bill(s)' in go('--flag', 'not_set').stdout
    json.dump({'id': 'ZZ-SB-2-2025', 'operative_text': 'A person may not sell a widget of any size'}, open(f'{t}/fill/ZZ-SB-2-2025.json', 'w'))
    r = go('--skip', 'ZZ-HB-1-2025', ok=False); assert r.returncode == 1 and 'NO TEXT ZZ-SB-2-2025' in r.stdout, 'a fill with no saved text is not a pass'
    os.remove(f'{t}/fill/ZZ-SB-2-2025.json'); fill(['NEW PART. Sec. 4: A person may not sell a large widget of any size to a buyer who'])
    leg_profile(W, fill_quotes={'label_strips': []})
    assert go(ok=False).returncode == 1, 'the legislature\'s own label is removed only because its profile names it'


FAKE_CLAUDE = """#!/usr/bin/env python3
import json, os, sys
C = os.environ['STUB_DIR']; a = sys.argv[1:]
call = {'argv': a, 'no_write': os.environ.get('STAGE5_NO_DB_WRITE'), 'cwd': os.getcwd(), 'leg_env': {k: v for k, v in os.environ.items() if k.startswith('STAGE5_LEG_')}}
json.dump(call, open(C + '/call.json', 'w')); open(C + '/calls.jsonl', 'a').write(json.dumps(call) + '\\n')
n = int(open(C + '/n.txt').read()) if os.path.exists(C + '/n.txt') else 0; open(C + '/n.txt', 'w').write(str(n + 1))
replies = open(C + '/reply.txt').read().split('\\n===NEXT===\\n'); reply = replies[min(n, len(replies) - 1)]
if reply == 'CRASH': sys.exit(3)
sid = a[a.index('--session-id') + 1] if '--session-id' in a else a[a.index('--resume') + 1]
turns = int(open(C + '/turns.txt').read()) if os.path.exists(C + '/turns.txt') else 20
print(json.dumps({'session_id': sid, 'result': reply, 'num_turns': turns}))
"""


@check
def leg_starts_a_slim_session_that_cannot_write_and_turns_its_last_line_into_a_stop(t):
    """A leg is the card plus the slim rules, started slim with the no-write flag; only a listed last line counts."""
    os.makedirs(t); P, S = topic_folder(t, control_groups=['1:7']); C, bin_ = f'{t}/stub', f'{t}/bin'; os.makedirs(C); os.makedirs(bin_)
    open(f'{bin_}/claude', 'w').write(FAKE_CLAUDE); os.chmod(f'{bin_}/claude', 0o755)
    env = dict(os.environ, STUB_DIR=C, PATH=bin_ + os.pathsep + os.environ['PATH']); env.pop('STAGE5_NO_DB_WRITE', None)
    T = os.path.normpath(os.path.join(HERE, '..', '..', '..', '.claude', 'skills', 'season-topic-prep', 'templates'))
    rules = open(f'{T}/stage5-slim-rules.md').read(); deskT = open(f'{T}/stage5-card-desk.md').read()
    for word in ('gun', 'firearm', 'voter', 'rung 5', '1,2,3'): assert word not in rules and word not in deskT, f'a slim-session template names {word!r}'
    assert 'never write the database' in rules and 'only on the runner\'s yes' in deskT
    def leg(reply, *a, which='A'):
        open(f'{C}/reply.txt', 'w').write(reply)
        for f in ('call.json', 'calls.jsonl', 'n.txt'):
            if os.path.exists(f'{C}/{f}'): os.remove(f'{C}/{f}')
        p = subprocess.run([sys.executable, '-I', os.path.join(TOOLS, 'leg.py'), which, '--profile', P, '--state', 'zz', '--state-name', 'Zedland', *a], capture_output=True, text=True, env=env)
        return p, (json.load(open(f'{C}/call.json')) if os.path.exists(f'{C}/call.json') else None)
    D = f'{S}/zz/desk'
    p, c = leg(f'Bill table done.\n\nSTOP question {D}/QUESTION-A-1.md')
    assert p.returncode == 10 and p.stdout.strip() == f'STOP question {D}/QUESTION-A-1.md', (p.returncode, p.stdout, p.stderr[-300:])
    a = c['argv']
    assert c['no_write'] == '1' and c['cwd'].endswith('/backend'), 'every slim session is started with the no-write flag'
    assert a[0] == '-p' and '--safe-mode' in a and '--disable-slash-commands' in a and a[a.index('--model') + 1] == 'opus' and '--resume' not in a
    assert a[a.index('--tools') + 1] == a[a.index('--allowedTools') + 1] and 'Bash' in a[a.index('--tools') + 1]
    assert '# Session A card' in a[1] and 'You are running this card as a slim session' in a[1] and f'{D}/QUESTION-A-<n>.md' in a[1] and '{{' not in a[1]
    sidA = a[a.index('--session-id') + 1]; assert c['leg_env'] == {'STAGE5_LEG_SESSION': sidA, 'STAGE5_LEG_CAP': '100000', 'STAGE5_LEG_LOG': f'{D}/LOG-A.md'}, c['leg_env']
    st = json.load(open(f'{D}/leg-A.json')); assert st['session_id'] == sidA and st['sessions'] == [sidA] and st['last'].startswith('STOP question') and len(st['runs']) == 1
    p, c = leg('DONE A'); assert p.returncode != 0 and c is None and '--answer' in p.stderr, 'a started leg is resumed, never started twice'
    open(f'{t}/ans.md', 'w').write('Rung question: "Direction only (Recommended)"')
    p, c = leg('All steps finished.\nDONE A', '--answer', f'{t}/ans.md')
    a = c['argv']; assert p.returncode == 0 and a[a.index('--resume') + 1] == sidA and c['leg_env']['STAGE5_LEG_SESSION'] == sidA and 'Direction only (Recommended)' in a[1] and '# Session A card' not in a[1] and c['no_write'] == '1'
    assert len(json.load(open(f'{D}/leg-A.json'))['runs']) == 2
    p, c = leg('DONE A'); assert p.returncode != 0 and c is None and 'already DONE' in p.stderr
    p, c = leg('x', '--answer', f'{t}/ans.md', which='B'); assert p.returncode != 0 and c is None, 'no answer for a leg that never started'
    for reply, code in ((f'Preview ready.\nSTOP write {S}/write/zz-01/PREVIEW.md', 11), ('STOP blocked the import refused 3 files: see run/step-3.log', 12),
                        ('DONE B\nActually one more thing is left.', 2), ('I will stop here and wait.', 2), ('', 2), ('CRASH', 2), ('STOP approve now', 11)):
        if os.path.exists(f'{D}/leg-B.json'): os.remove(f'{D}/leg-B.json')
        p, c = leg(reply, which='B'); assert p.returncode == code, (reply, p.returncode, p.stdout)
    open(f'{t}/empty.md', 'w').write('  \n'); p, c = leg('DONE B', '--answer', f'{t}/empty.md', which='B'); assert p.returncode != 0 and c is None, 'an empty answer is not sent'
    run('session_card.py', 'desk', '--profile', P, '--state', 'zz', '--state-name', 'Zedland', '--out', f'{t}/desk.md')
    d = open(f'{t}/desk.md').read(); assert '{{' not in d and f'{D}' in d and 'write-batch.sh' in d and 'leg.py A --profile' in d and 'standing_yes.py write' in d and "own chat message" in d and len(d) < 6500
    # the write script itself refuses in a slim session, before it runs the writer
    open(f'{bin_}/npx', 'w').write('#!/bin/sh\necho ran >> "$STUB_DIR/npx.txt"\n'); os.chmod(f'{bin_}/npx', 0o755); os.makedirs(f'{t}/b')
    go = lambda mode, e: subprocess.run(['zsh', os.path.join(TOOLS, 'write-batch.sh'), S, f'{t}/b', 'made-up-topic', 'state:zz', mode], capture_output=True, text=True, env=e, cwd=t)
    r = go('apply', dict(env, STAGE5_NO_DB_WRITE='1'))
    assert r.returncode == 5 and 'REFUSED' in r.stderr and not os.path.exists(f'{C}/npx.txt'), (r.returncode, r.stderr[-200:])
    go('apply', env); assert os.path.exists(f'{C}/npx.txt'), 'outside a slim session the write script still runs the writer'


@check
def leg_hands_over_to_a_fresh_session_past_the_size_cap(t):
    """A leg is a chain of sessions: `leg.py log` reports the session's size from its transcript, and a hand-over starts a fresh session."""
    os.makedirs(t); P, S = topic_folder(t, control_groups=['1:7']); C, bin_, home = f'{t}/stub', f'{t}/bin', f'{t}/home'; os.makedirs(C); os.makedirs(bin_)
    open(f'{bin_}/claude', 'w').write(FAKE_CLAUDE); os.chmod(f'{bin_}/claude', 0o755); os.makedirs(f'{home}/.claude/projects/p')
    env = dict(os.environ, STUB_DIR=C, HOME=home, PATH=bin_ + os.pathsep + os.environ['PATH'])
    for k in [k for k in env if k.startswith('STAGE5_')]: env.pop(k)
    D = f'{S}/zz/desk'; LEG = os.path.join(TOOLS, 'leg.py')
    def transcript(sid, *sizes):   # one assistant step per size: new input, cache read and cache write all count
        with open(f'{home}/.claude/projects/p/{sid}.jsonl', 'w') as fh:
            fh.write(json.dumps({'type': 'user', 'message': {'content': 'go'}}) + '\n')
            for i, n in enumerate(sizes):
                fh.write(json.dumps({'type': 'assistant', 'message': {'id': f'm{i}', 'usage': {'input_tokens': 10, 'cache_read_input_tokens': n - 110, 'cache_creation_input_tokens': 100, 'output_tokens': 999999}}}) + '\n')
    def leg(reply, *a, which='A', turns=20):
        open(f'{C}/reply.txt', 'w').write(reply); open(f'{C}/turns.txt', 'w').write(str(turns))
        for f in ('call.json', 'calls.jsonl', 'n.txt'):
            if os.path.exists(f'{C}/{f}'): os.remove(f'{C}/{f}')
        p = subprocess.run([sys.executable, '-I', LEG, which, '--profile', P, '--state', 'zz', '--state-name', 'Zedland', *a], capture_output=True, text=True, env=env)
        return p, ([json.loads(l) for l in open(f'{C}/calls.jsonl')] if os.path.exists(f'{C}/calls.jsonl') else [])
    # --- the size line: the latest step's whole input, against the cap; output tokens are not size
    log = lambda line, sid, cap='100000', **kw: subprocess.run([sys.executable, '-I', LEG, 'log', *([line] if line else [])], capture_output=True, text=True,
                                                              env=dict(env, STAGE5_LEG_LOG=f'{t}/LOG.md', STAGE5_LEG_SESSION=sid, STAGE5_LEG_CAP=cap), **kw)
    transcript('s-small', 150000, 99999); transcript('s-big', 5000, 100000)
    r = log('A1 bill list: 40 bills', 's-small'); assert r.returncode == 0 and '99,999 of 100,000' in r.stdout and 'carry on' in r.stdout and 'HAND OVER' not in r.stdout, r.stdout + r.stderr
    r = log('- A2 texts: 38 of 40', 's-big'); assert 'HAND OVER NOW' in r.stdout and '100,000 of 100,000' in r.stdout, r.stdout
    r = log('', 's-big', cap='0', input='A3 "quoted" line\n'); assert 'carry on' in r.stdout and 'HAND OVER' not in r.stdout, 'a cap of 0 turns the cap off'
    r = log('A4', 's-none'); assert r.returncode == 0 and 'unknown' in r.stdout and 'carry on' in r.stdout, 'a session with no transcript is never told to hand over'
    assert open(f'{t}/LOG.md').read() == '- A1 bill list: 40 bills\n- A2 texts: 38 of 40\n- A3 "quoted" line\n- A4\n', open(f'{t}/LOG.md').read()
    r = subprocess.run([sys.executable, '-I', LEG, 'log', 'x'], capture_output=True, text=True, env=env); assert r.returncode != 0 and 'not inside a slim leg' in r.stderr
    # --- a hand-over starts a fresh session with the card, the rules and the note; the desk only sees the end
    os.makedirs(D); note = f'{D}/CONTINUE-A-1.md'; open(note, 'w').write('On step A3. Next: bill_table.py check.\n')
    p, calls = leg(f'Texts done.\nSTOP handover {note}\n===NEXT===\nDONE A')
    assert p.returncode == 0 and p.stdout.strip() == 'DONE A' and len(calls) == 2, (p.returncode, p.stdout, p.stderr[-300:], len(calls))
    a0, a1 = calls[0]['argv'], calls[1]['argv']; s0, s1 = a0[a0.index('--session-id') + 1], a1[a1.index('--session-id') + 1]
    assert s0 != s1 and '--resume' not in a1 and calls[1]['no_write'] == '1' and calls[1]['leg_env']['STAGE5_LEG_SESSION'] == s1
    assert '# Session A card' in a1[1] and 'When the session is large' in a1[1] and 'You are continuing this leg' in a1[1] and note in a1[1] and 'You are continuing' not in a0[1]
    assert f'{D}/CONTINUE-A-<n>.md' in a0[1] and 'The cap for this\nleg is 100,000 tokens' in a0[1] and '{{' not in a0[1]
    st = json.load(open(f'{D}/leg-A.json')); assert st['sessions'] == [s0, s1] and st['session_id'] == s1 and [r['session'] for r in st['runs']] == [s0, s1] and st['last'] == 'DONE A'
    transcript(s0, 5000); transcript(s1, 5000)
    r = subprocess.run([sys.executable, '-I', LEG, 'sessions', '--profile', P, '--state', 'zz'], capture_output=True, text=True, env=env)
    assert r.stdout.split() == ['--session', f'{home}/.claude/projects/p/{s0}.jsonl', '--session', f'{home}/.claude/projects/p/{s1}.jsonl'], r.stdout + r.stderr
    # --- a hand-over naming no file is not followed; one inside MIN_TURNS steps stops the leg as blocked (a cap too low would loop)
    os.remove(f'{D}/leg-A.json'); p, calls = leg(f'STOP handover {D}/CONTINUE-A-9.md\n===NEXT===\nDONE A')
    assert p.returncode == 2 and len(calls) == 1 and 'missing or empty' in p.stdout, (p.returncode, p.stdout)
    os.remove(f'{D}/leg-A.json'); p, calls = leg(f'STOP handover {note}', turns=3)
    assert p.returncode == 12 and len(calls) == 1 and p.stdout.startswith('STOP blocked the leg handed over again after 3 steps'), (p.returncode, p.stdout)
    os.remove(f'{D}/leg-A.json'); p, calls = leg(f'STOP handover {note}')
    assert p.returncode == 12 and len(calls) == 13 and '13 hand-overs' in p.stdout, (p.returncode, len(calls), p.stdout)
    # --- an answer goes to a fresh session only when the stopped one is past the cap AND left a note in its last run
    def answered(size, with_note, *a):
        for f in glob.glob(f'{D}/*'): os.remove(f)
        p, calls = leg(f'STOP question {D}/QUESTION-B-1.md', which='B'); sid = json.load(open(f'{D}/leg-B.json'))['session_id']; transcript(sid, size)
        if with_note: open(f'{D}/CONTINUE-B-1.md', 'w').write('On step B8. The question is open.\n')
        open(f'{t}/ans.md', 'w').write('Option A, as recommended')
        p, calls = leg('DONE B', '--answer', f'{t}/ans.md', *a, which='B'); assert p.returncode == 0 and len(calls) == 1, (p.returncode, p.stdout, p.stderr[-300:])
        return sid, calls[0]['argv'], json.load(open(f'{D}/leg-B.json'))
    sid, a, st = answered(140000, True)
    assert '--resume' not in a and a[a.index('--session-id') + 1] != sid and st['sessions'] == [sid, st['session_id']]
    assert '# Session B card' in a[1] and f'{D}/CONTINUE-B-1.md' in a[1] and 'Option A, as recommended' in a[1] and a[1].index('You are continuing') < a[1].index('Option A, as recommended')
    sid, a, st = answered(60000, True); assert a[a.index('--resume') + 1] == sid and st['sessions'] == [sid] and '# Session B card' not in a[1], 'a small session is resumed: it keeps what it knows'
    sid, a, st = answered(140000, False); assert a[a.index('--resume') + 1] == sid, 'a large session that left no note is resumed: a fresh one would know nothing'
    sid, a, st = answered(140000, True, '--cap', '0'); assert a[a.index('--resume') + 1] == sid, 'with the cap off nothing is handed over'
    # --- Utah 2026-11-15: a RESUMED session counts only this run's steps, so a hand-over a few steps after an answer is
    # not "the cap is too low"; and an answer after a blocked hand-over goes to a fresh session, never back to the full one
    for f in glob.glob(f'{D}/*'): os.remove(f)
    p, calls = leg(f'STOP question {D}/QUESTION-B-1.md', which='B'); sid = json.load(open(f'{D}/leg-B.json'))['session_id']; transcript(sid, 90000)
    open(f'{D}/CONTINUE-B-1.md', 'w').write('On step B9.\n'); open(f'{t}/ans.md', 'w').write('Leave them unread')
    p, calls = leg(f'STOP handover {D}/CONTINUE-B-1.md\n===NEXT===\nDONE B', '--answer', f'{t}/ans.md', which='B', turns=4)
    assert p.returncode == 0 and len(calls) == 2 and calls[0]['argv'][calls[0]['argv'].index('--resume') + 1] == sid, (p.returncode, p.stdout, len(calls))
    assert '--resume' not in calls[1]['argv'] and 'You are continuing this leg' in calls[1]['argv'][1], 'the resumed session hands over to a fresh one'
    for f in glob.glob(f'{D}/*'): os.remove(f)
    open(f'{D}/CONTINUE-B-1.md', 'w').write('On B9.\n'); p, calls = leg(f'STOP handover {D}/CONTINUE-B-1.md', which='B', turns=3)
    assert p.returncode == 12, 'a FRESH session that hands over inside MIN_TURNS steps is still blocked'
    sid = json.load(open(f'{D}/leg-B.json'))['session_id']; transcript(sid, 90000); open(f'{t}/ans.md', 'w').write('carry on')
    p, calls = leg('DONE B', '--answer', f'{t}/ans.md', which='B')
    assert p.returncode == 0 and '--resume' not in calls[0]['argv'] and 'You are continuing this leg' in calls[0]['argv'][1], 'after a blocked hand-over the answer goes to a fresh session'
    # --- Ohio 2026-11-16: a session that worked for 28 minutes reported 1 step (its last reply was a wake-up after a
    # background task). Few steps AND a short run say "the cap is too low"; few steps after a long run do not.
    for f in glob.glob(f'{D}/*'): os.remove(f)
    open(f'{D}/CONTINUE-B-1.md', 'w').write('On B9.\n'); env['STAGE5_LEG_QUICK'] = '0'
    p, calls = leg(f'STOP handover {D}/CONTINUE-B-1.md\n===NEXT===\nDONE B', which='B', turns=1)
    del env['STAGE5_LEG_QUICK']
    assert p.returncode == 0 and len(calls) == 2 and 'You are continuing this leg' in calls[1]['argv'][1], (p.returncode, p.stdout, len(calls))


@check
def wave_starts_agents_slim_and_only_with_named_tools(t):
    os.makedirs(t); open(f'{t}/p.md', 'w').write('x')
    open(f'{t}/jobs.tsv', 'w').write(f'name\tprompt_file\tmodel\ttools\na\t{t}/p.md\topus\tRead,Write\n')
    out = run('wave.py', f'{t}/jobs.tsv', '--out', f'{t}/o', '--print').stdout
    assert '--safe-mode' in out and '--tools Read,Write' in out and 'claude-opus-5-5' in out, out
    assert '--safe-mode' not in run('wave.py', f'{t}/jobs.tsv', '--out', f'{t}/o', '--print', '--full').stdout


@check
def link_check_stops_on_a_legislator_with_no_vote_link(t):
    """Kentucky 2026-11-14: six sitting members had no idmap line, so their votes were never read, and nothing said so."""
    os.makedirs(f'{t}/ds/XX-1/2025/s/bill'); os.makedirs(f'{t}/ds/XX-1/2025/s/people')
    json.dump({'bill': {'session': {'year_end': 2026}}}, open(f'{t}/ds/XX-1/2025/s/bill/1.json', 'w'))
    for i, first, last, name in ((7, 'Ann', 'Able', 'Ann Able'), (8, 'Deanna', 'Frazier', 'Deanna Frazier'), (9, 'Amy', 'Mays Bell', 'Amy Mays Bell')):
        json.dump({'person': {'people_id': i, 'first_name': first, 'last_name': last, 'name': name, 'role': 'Rep', 'district': f'HD-{i}'}}, open(f'{t}/ds/XX-1/2025/s/people/{i}.json', 'w'))
    rows = [('pa', 'Ann Able', 'sitting', 'Representative'), ('pg', 'Deanna Gordon', 'both', 'Senator'), ('pb', 'Amy Mays Bell', 'sitting', 'Representative'),
            ('pc', 'Cal Runner', 'candidate', 'Representative'), ('pv', 'Gia Gov', 'sitting', 'Governor')]
    def roster(rs): open(f'{t}/roster.tsv', 'w').write('politician_id\tfull_name\tscope\toffice\n' + ''.join('\t'.join(r) + '\n' for r in rs))
    def idmap(lines): open(f'{t}/idmap.tsv', 'w').write(''.join(f'{a}\t{b}\n' for a, b in lines))
    def go(*extra): return run('link_check.py', '--state', 'xx', '--roster', f'{t}/roster.tsv', '--ds', f'{t}/ds', '--idmap', f'{t}/idmap.tsv', *extra, ok=False)
    roster(rows); idmap([(7, 'pa'), (8, 'pg'), (9, 'pb')])
    p = go(); assert p.returncode == 0 and '3 legislator(s)' in p.stdout and '0 NOT linked' in p.stdout, p.stdout + p.stderr   # the candidate and the governor are not asked for
    idmap([(7, 'pa'), (9, 'pb')])
    p = go(); assert p.returncode == 1 and '- Deanna Gordon (Senator)' in p.stdout and 'Deanna Frazier' in p.stdout, 'a changed surname is named beside the unlinked LegiScan person'
    idmap([(7, 'pa'), (9, 'pb'), (8, 'someone-else')])
    assert go().returncode == 1, 'a line that points at another id links nobody here'
    idmap([(7, 'pa'), (9, 'pb'), (77, 'pg')])
    assert go().returncode == 1, 'a line whose LegiScan person is not in the datasets links nobody'
    open(f'{t}/none.tsv', 'w').write('pg\tseated 2026-10-01, after the newest dataset\n')
    p = go('--no-record', f'{t}/none.tsv'); assert p.returncode == 0 and 'excused: Deanna Gordon' in p.stdout
    open(f'{t}/none.tsv', 'w').write('pg\n'); assert go('--no-record', f'{t}/none.tsv').returncode == 2, 'an excuse needs a reason'
    idmap([(8, 'pg')])
    p = go(); assert p.returncode == 1 and p.stdout.count('name match, not yet in idmap') == 2, 'a name match alone is not a link'
    p = go('--add'); assert p.returncode == 0 and 'added 2 line(s)' in p.stdout, p.stdout
    assert open(f'{t}/idmap.tsv').read().count('link_check name match') == 2 and go().returncode == 0   # 9: LegiScan's last_name is "Mays Bell"
    roster([r[:3] + ('',) for r in rows]); assert go().returncode == 2, 'no office column filled: no verdict, never a pass'
    roster(rows); os.rename(f'{t}/ds/XX-1', f'{t}/ds/YY-1'); assert go().returncode == 2, 'no LegiScan people read: no verdict'


@check
def state_legiscan_cites_the_legislatures_own_page_for_an_open_states_roll_call(t):
    """A roll call converted from Open States data has no legiscan.com page: its pair names the legislature's own
    roll-call page, taken from the hit. One with no page is unmapped, with that reason. A sponsorship on such a bill
    makes no pair and is listed apart. A LegiScan bill beside it still gets its LegiScan addresses. A special-session
    hit is not taken for a regular-session vote."""
    B = batch(f'{t}/b', [('Ann Able', 'a')], [{'full_name': 'Ann Able', 'topic_key': 'tp', 'evidence_type': 'record',
              'urls': ['https://leg.gov/hb1', 'https://leg.gov/hb2', 'https://leg.gov/hb3', 'https://leg.gov/hb4']}], ncols=4)
    os.makedirs(f'{t}/f')
    v = lambda n, d, tal: {'kind': 'record', 'url': f'https://leg.gov/hb{n}', 'act': 'yea', 'instrument_id': f'XX-HB-{n}-2025', 'chamber': 'H', 'date': d, 'note': f'tally {tal}', 'motion': 'Third reading'}
    json.dump({'findings': [v(1, '2025-03-01', '60-40'), v(2, '2025-03-02', '70-30'), v(3, '2025-03-03', '55-45'), v(4, '2025-03-04', '50-49'),
                            {'kind': 'record', 'url': 'https://leg.gov/hb1', 'act': 'sponsor', 'instrument_id': 'XX-HB-1-2025'},
                            {'kind': 'record', 'url': 'https://leg.gov/hb3', 'act': 'cosponsor', 'instrument_id': 'XX-HB-3-2025'}]}, open(f'{t}/f/a.json', 'w'))
    ds = f'{t}/ds'
    def session(folder, special, bills, openstates):
        d = f'{ds}/XX-{folder}/XX/s{folder}/bill'; os.makedirs(d)
        if openstates: json.dump({'source': 'Open States'}, open(f'{ds}/XX-{folder}/.openstates.json', 'w'))
        for n in bills: json.dump({'bill': {'bill_number': n, 'state_link': f'https://leg.gov/{n.lower()}', 'session': {'year_start': 2025, 'year_end': 2025, 'special': special}}}, open(f'{d}/{n}.json', 'w'))
    session(900001, 0, ['HB1', 'HB2', 'HB4'], True); session(900002, 1, ['HB4'], True); session(77, 0, ['HB3'], False)
    env = {'LEGISCAN_DATASETS': ds}
    run('state_legiscan.py', 'plan', B, f'{t}/f', '--state', 'XX', '--host', 'leg.gov', env=env)
    os_hit = lambda rc, d, link, special=0: {'roll_call_id': rc, 'date': d, 'desc': 'House Third reading', 'bill_url': 'https://open.pluralpolicy.com/xx/bills/2025/HB1/', 'openstates': True, 'special': special, 'state_link': link}
    json.dump([{'url': 'XX-HB-1-2025|H|2025-03-01|60-40', 'hits': [os_hit(90000001, '2025-03-01', 'https://leg.gov/votes?id=7')]},
               {'url': 'XX-HB-2-2025|H|2025-03-02|70-30', 'hits': [os_hit(90000002, '2025-03-02', '')]},
               {'url': 'XX-HB-3-2025|H|2025-03-03|55-45', 'hits': [{'roll_call_id': 31, 'date': '2025-03-03', 'desc': 'House: Third reading', 'bill_url': 'https://legiscan.com/XX/bill/HB3/2025'}]},
               {'url': 'XX-HB-4-2025|H|2025-03-04|50-49', 'hits': [os_hit(90000004, '2025-03-04', 'https://leg.gov/votes?id=9', special=1)]}],
              open(f'{B}/legiscan/rollcall-hits.json', 'w'))
    out = run('state_legiscan.py', 'pairs', B, f'{t}/f', '--state', 'XX', '--host', 'leg.gov', '--topic', 'tp', env=env).stdout
    got = sorted(r['source_url'] for r in read_csv(f'{B}/legiscan/pairs.csv'))
    assert got == ['https://leg.gov/votes?id=7', 'https://legiscan.com/XX/bill/HB3/2025', 'https://legiscan.com/XX/rollcall/HB3/id/31'], got
    un = {u[2]: u[3] for u in json.load(open(f'{B}/legiscan/unmapped.json'))}
    assert sorted(un) == ['XX-HB-2-2025', 'XX-HB-4-2025'] and 'names no page of the legislature' in un['XX-HB-2-2025'] and '0 LegiScan roll calls' in un['XX-HB-4-2025'], un
    assert json.load(open(f'{B}/legiscan/sponsor-own-page.json')) == [['Ann Able', 'https://leg.gov/hb1', 'XX-HB-1-2025', 'sponsor']], open(f'{B}/legiscan/sponsor-own-page.json').read()
    assert 'unmapped 1: yea: the roll call is from Open States data' in out and 'sponsorships left on the official page' in out, out
    needs = json.load(open(f'{B}/legiscan/needs.json'))['Ann Able']
    assert {'url': 'https://leg.gov/votes?id=7', 'official': 'https://leg.gov/hb1', 'act': 'yea', 'instrument': 'XX-HB-1-2025'} in needs, needs


@check
def legiscan_merge_cross_checks_a_vote_cited_on_a_legislature_page(t):
    """A vote line on a legislature's own roll-call page is cross-checked against the finding like a LegiScan one: a
    Yea finding with a Nay line stops the merge (exit 1). "was absent or not voting" agrees with an abstain finding."""
    def go(said, act='yea'):
        B = batch(f'{t}/{said.replace(" ", "-")}-{act}', [('Ann Able', 'a')], [{'full_name': 'Ann Able', 'topic_key': 't', 'evidence_type': 'record', 'urls': ['https://leg.gov/hb1']}])
        os.makedirs(f'{B}/legiscan')
        json.dump({'Ann Able': [{'url': 'https://leg.gov/votes?id=7', 'official': 'https://leg.gov/hb1', 'act': act, 'instrument': 'XX-HB-1-2025'}]}, open(f'{B}/legiscan/needs.json', 'w'))
        write_csv(f'{B}/legiscan/legiscan-evidence.csv', [{'full_name': 'Ann Able', 'topic_key': 't', 'source_url': 'https://leg.gov/votes?id=7',
                  'snippet': f'Xx House roll call 7 (2025GS), HB 1 - Third reading (2025-03-01): Able, A. {said}.', 'snippet_index': '1'}])
        p = run('legiscan_merge.py', B, '--host', 'leg.gov', ok=False)
        return p.returncode, json.load(open(f'{B}/legiscan/crosscheck.json')), urls(read_csv(f'{B}/research.csv')[0])
    code, cross, cited = go('voted Yea')
    assert code == 0 and [c['agree'] for c in cross] == [True] and cited == ['https://leg.gov/votes?id=7'], (code, cross, cited)
    code, cross, _ = go('voted Nay')
    assert code == 1 and [c['agree'] for c in cross] == [False], (code, cross)
    code, cross, _ = go('was absent or not voting', act='abstain')
    assert code == 0 and [c['agree'] for c in cross] == [True], (code, cross)
    code, cross, _ = go('was absent or not voting')
    assert code == 1 and [c['agree'] for c in cross] == [False], (code, cross)
    # South Dakota words a member who did not vote as the record lists them: each agrees with an abstain finding only
    for said in ('was excused', 'was absent', 'did not vote', 'voted present', 'was suspended'):
        code, cross, _ = go(said, act='abstain')
        assert code == 0 and [c['agree'] for c in cross] == [True], (said, code, cross)
        code, cross, _ = go(said)
        assert code == 1 and [c['agree'] for c in cross] == [False], (said, code, cross)


def openstates_extract(t, st='ut'):
    """A two-session Open States extract for one state, as extract.py writes it: one House member, one senator."""
    X = f'{t}/work/extracts/2026-11/{st}'; os.makedirs(X)
    def tsv(name, cols, rows):
        open(f'{X}/{name}.tsv', 'w').write('\t'.join(cols) + '\n' + ''.join('\t'.join(r.get(c, '\\N') for c in cols) + '\n' for r in rows))
    json.dump({'dump': '2026-11-public.pgdump', 'month': '2026-11', 'state': st, 'extracted_at': 'x'}, open(f'{X}/extract.json', 'w'))
    tsv('legislativesession', ['id', 'identifier', 'name', 'classification', 'start_date', 'end_date'],
        [{'id': 's20', 'identifier': '2020', 'name': '2020 General Session', 'classification': 'primary', 'start_date': '2020-01-27', 'end_date': '2020-03-12'},
         {'id': 's21', 'identifier': '2021', 'name': '2021 General Session', 'classification': 'primary', 'start_date': '2021-01-19', 'end_date': '2021-03-05'}])
    tsv('organization', ['id', 'name', 'classification', 'parent_id'], [{'id': 'leg', 'name': 'Legislature', 'classification': 'legislature'},
        {'id': 'up', 'name': 'Senate', 'classification': 'upper', 'parent_id': 'leg'}, {'id': 'lo', 'name': 'House', 'classification': 'lower', 'parent_id': 'leg'}])
    tsv('post', ['id', 'label'], [])
    tsv('person', ['id', 'name', 'given_name', 'family_name', 'image', 'primary_party', 'email'],
        [{'id': 'p-rep', 'name': 'Rae Able', 'given_name': 'Rae', 'family_name': 'Able', 'primary_party': 'Republican'},
         {'id': 'p-sen', 'name': 'Sam Baker', 'given_name': 'Sam', 'family_name': 'Baker', 'primary_party': 'Democratic'}])
    tsv('membership', ['person_id', 'organization_id', 'post_id', 'start_date', 'end_date'], [])
    tsv('bill', ['id', 'legislative_session_id', 'identifier', 'title', 'classification', 'subject', 'from_organization_id'],
        [{'id': 'b20', 'legislative_session_id': 's20', 'identifier': 'S.B. 5', 'title': 'A bill', 'classification': '{bill}', 'subject': '{}', 'from_organization_id': 'up'},
         {'id': 'b21', 'legislative_session_id': 's21', 'identifier': 'SB 6', 'title': 'A bill', 'classification': '{bill}', 'subject': '{}', 'from_organization_id': 'up'}])
    tsv('billsource', ['bill_id', 'url'], [{'bill_id': 'b20', 'url': 'http://le.utah.gov/~2020/bills/static/SB0005.html'}])
    tsv('billsponsorship', ['bill_id', 'name', 'entity_type', 'primary', 'person_id'], [])
    ev = lambda i, b, s, org: {'id': i, 'bill_id': b, 'legislative_session_id': s, 'organization_id': org, 'motion_text': 'passed 3rd reading', 'start_date': s.replace('s', '20') + '-02-01', 'result': 'pass', 'order': '0'}
    # Both sessions: a House floor vote and a Senate floor vote on a SENATE bill, each filed under the bill's chamber
    # ("up"), as Utah's rows are; and a committee vote, told apart only by its link.
    tsv('voteevent', ['id', 'bill_id', 'legislative_session_id', 'organization_id', 'motion_text', 'start_date', 'result', 'order'],
        [ev('h20', 'b20', 's20', 'up'), ev('s20v', 'b20', 's20', 'up'), ev('c20', 'b20', 's20', 'up'), ev('h21', 'b21', 's21', 'up'), ev('s21v', 'b21', 's21', 'up')])
    link = lambda sess, vid, house: f'http://le.utah.gov/DynaBill/svotes.jsp?sessionid={sess}GS&voteid={vid}&house={house}'
    tsv('votesource', ['vote_event_id', 'url'], [{'vote_event_id': 'h20', 'url': link(2020, 1, 'H')}, {'vote_event_id': 's20v', 'url': link(2020, 2, 'S')},
        {'vote_event_id': 'c20', 'url': 'http://le.utah.gov/mtgvotes.jsp?voteid=9'}, {'vote_event_id': 'h21', 'url': link(2021, 1, 'H')}, {'vote_event_id': 's21v', 'url': link(2021, 2, 'S')}])
    tsv('votecount', ['vote_event_id', 'option', 'value'], [{'vote_event_id': e, 'option': 'yes', 'value': '1'} for e in ('h20', 's20v', 'c20', 'h21', 's21v')])
    pv = lambda e, name, pid=None: {'vote_event_id': e, 'voter_name': name, 'option': 'yes', **({'voter_id': pid} if pid else {})}
    # 2021 links its voters; 2020 links none (Utah 2017-2020), under the same printed labels.
    tsv('personvote', ['vote_event_id', 'voter_id', 'voter_name', 'option'],
        [pv('h21', 'Able, R.', 'p-rep'), pv('s21v', 'Baker, S.', 'p-sen'), pv('h20', 'Able, R.'), pv('s20v', 'Baker, S.'), pv('c20', 'Able, R.'), pv('h20', 'Stranger, Q.')])
    return X


@check
def openstates_convert_takes_the_voting_chamber_and_committee_from_the_roll_call_link(t):
    """Open States files a Utah vote under the bill's chamber. The converted roll call must carry the chamber its
    own link names, a committee vote must say Committee, a label linked in another session must reach the same
    person, an old "S.B. 5" must be SB5, links must be https, and no party may be written. Without a registry the
    converter refuses, because a new one renumbers everything."""
    X = openstates_extract(t)
    p = run('openstates/convert.py', X, '--out', f'{t}/out', '--legiscan-root', f'{t}/none', ok=False)
    assert p.returncode != 0 and 'id_registry.json' in (p.stderr + p.stdout), 'no registry: refuse'
    run('openstates/convert.py', X, '--out', f'{t}/out', '--legiscan-root', f'{t}/none', env={'OPENSTATES_NEW_REGISTRY': '1'})
    reg = json.load(open(f'{t}/work/id_registry.json'))
    rcs = {}
    for f in glob.glob(f'{t}/out/UT-*/UT/*/vote/*.json'):
        r = json.load(open(f))['roll_call']; rcs[r['_openstates']['vote_event_id']] = r
    assert len(rcs) == 5, sorted(rcs)
    assert [rcs[e]['chamber'] for e in ('h20', 's20v', 'h21', 's21v')] == ['H', 'S', 'H', 'S'], {e: r['chamber'] for e, r in rcs.items()}
    assert rcs['h20']['desc'].startswith('House ') and 'Committee' not in rcs['h20']['desc'], rcs['h20']['desc']
    assert 'Committee' in rcs['c20']['desc'] and rcs['c20']['_openstates']['committee'] is True, rcs['c20']['desc']
    assert all(r['state_link'].startswith('https://le.utah.gov/') for r in rcs.values()), [r['state_link'] for r in rcs.values()]
    rep = reg['people']['person:p-rep']; sen = reg['people']['person:p-sen']
    assert [v['people_id'] for v in rcs['h21']['votes']] == [rep] and [v['people_id'] for v in rcs['s21v']['votes']] == [sen]
    assert rep in [v['people_id'] for v in rcs['h20']['votes']], 'the 2020 House label is the 2021 House member'
    assert [v['people_id'] for v in rcs['s20v']['votes']] == [sen], 'the 2020 Senate label is the 2021 senator'
    assert len({v['people_id'] for v in rcs['h20']['votes']}) == 2, 'a label never linked anywhere stays its own name-only person'
    assert sorted(os.path.basename(f) for f in glob.glob(f'{t}/out/UT-*/UT/*/bill/*.json')) == ['SB5.json', 'SB6.json']
    b = json.load(open(glob.glob(f'{t}/out/UT-*/UT/*/bill/SB5.json')[0]))['bill']
    assert b['bill_number'] == 'SB5' and b['state_link'] == 'https://le.utah.gov/~2020/bills/static/SB0005.html', (b['bill_number'], b['state_link'])
    people = [json.load(open(f))['person'] for f in glob.glob(f'{t}/out/UT-*/UT/*/people/*.json')]
    assert people and all(q['party'] == '' and q['party_id'] == '0' for q in people), [(q['name'], q['party']) for q in people]
    assert {q['role'] for q in people if q['people_id'] == rep} == {'Rep'} and {q['role'] for q in people if q['people_id'] == sen} == {'Sen'}
    assert all(os.path.exists(os.path.join(d, '.openstates.json')) for d in glob.glob(f'{t}/out/UT-*'))
    before = json.dumps(reg, sort_keys=True)
    run('openstates/convert.py', X, '--out', f'{t}/out', '--legiscan-root', f'{t}/none')
    assert json.dumps(json.load(open(f'{t}/work/id_registry.json')), sort_keys=True) == before, 'a second run hands out the same numbers'


@check
def openstates_convert_merges_roll_calls_read_from_the_legislature(t):
    """A dump can hold a session's bills and none of its roll calls (Utah 2025). A roll call read from the
    legislature's own site joins the session like any other: its chamber, its page as the citation, its voters
    linked by the same label rules, and a mark saying where it came from. A page the dump already holds is not added
    twice, and a supplement whose members are not its tally, or whose bill the extract does not hold, stops the run."""
    X = openstates_extract(t)
    S = f'{t}/work/supplements/UT'; os.makedirs(S)
    url = lambda vid, house: f'https://le.utah.gov/DynaBill/svotes.jsp?sessionid=2021GS&voteid={vid}&house={house}'
    rc = lambda vid, house, yea, nay, ab: {'url': url(vid, house), 'date': '2021-02-09', 'motion': 'House/ passed 3rd reading', 'question': '3rd Reading',
                                           'chamber': house, 'yea': len(yea), 'nay': len(nay), 'absent': len(ab), 'passed': 1,
                                           'groups': {'Yea': yea, 'Nay': nay, 'Absent or not voting': ab}}
    def supp(bills): json.dump({'state': 'UT', 'session': '2021', 'source': 'le.utah.gov', 'bills': bills}, open(f'{S}/2021.json', 'w'))
    conv = lambda ok=True: run('openstates/convert.py', X, '--out', f'{t}/out', '--legiscan-root', f'{t}/none', ok=ok, env={'OPENSTATES_NEW_REGISTRY': '1'})
    # voteid 1 on the House side is already in the dump (h21); voteid 7 is not
    supp({'SB 6': [rc(1, 'H', ['Able, R.'], [], []), rc(7, 'H', [], ['Able, R.'], ['Stranger, Q.'])]})
    p = conv()
    assert 'added 1' in p.stdout and 'already_in_dump 1' in p.stdout, p.stdout[-300:]
    rcs = [json.load(open(f))['roll_call'] for f in glob.glob(f'{t}/out/UT-*/UT/2021*/vote/*.json')]
    assert len(rcs) == 3, [r['state_link'] for r in rcs]
    new = [r for r in rcs if r['_openstates'].get('from_legislature')]
    assert len(new) == 1 and new[0]['state_link'] == url(7, 'H') and new[0]['chamber'] == 'H', new
    assert (new[0]['yea'], new[0]['nay'], new[0]['nv'], new[0]['absent'], new[0]['passed']) == (0, 1, 1, 0, 1), new[0]
    assert new[0]['desc'] == 'House House/ passed 3rd reading' and new[0]['date'] == '2021-02-09', new[0]['desc']
    reg = json.load(open(f'{t}/work/id_registry.json'))
    rep = reg['people']['person:p-rep']
    votes = {v['people_id']: v['vote_text'] for v in new[0]['votes']}
    assert votes.get(rep) == 'Nay' and len(votes) == 2 and sorted(votes.values()) == ['NV', 'Nay'], votes
    b = json.load(open(glob.glob(f'{t}/out/UT-*/UT/2021*/bill/SB6.json')[0]))['bill']
    assert url(7, 'H') in [v['state_link'] for v in b['votes']], 'the bill file lists the added roll call'
    mk = {json.load(open(f))['openstates_session']: json.load(open(f)) for f in glob.glob(f'{t}/out/UT-*/.openstates.json')}
    assert mk['2021']['rollcalls_from_legislature']['count'] == 1 and mk['2021']['rollcalls_from_legislature']['bills'] == ['SB 6'], mk['2021']
    assert mk['2020']['rollcalls_from_legislature'] is None and mk['2021']['counts']['rollcalls_from_legislature'] == 1
    before = json.dumps(reg, sort_keys=True)
    conv()
    assert json.dumps(json.load(open(f'{t}/work/id_registry.json')), sort_keys=True) == before, 'a second run hands out the same numbers'
    # the members listed must be the tally
    bad = rc(7, 'H', [], ['Able, R.'], ['Stranger, Q.']); bad['nay'] = 2
    supp({'SB 6': [bad]})
    p = conv(ok=False)
    assert p.returncode != 0 and 'are not the tally' in (p.stderr + p.stdout), (p.returncode, p.stderr[-200:])
    supp({'SB 99': [rc(7, 'H', ['Able, R.'], [], [])]})
    p = conv(ok=False)
    assert p.returncode != 0 and 'is not in session 2021' in (p.stderr + p.stdout), (p.returncode, p.stderr[-200:])
    # a state with no rule for reading the chamber from the address: the supplement's own chamber is the one that voted
    Z = openstates_extract(f'{t}/z', st='zz'); os.makedirs(f'{t}/z/work/supplements/ZZ')
    json.dump({'state': 'ZZ', 'session': '2021', 'source': 'x', 'bills': {'SB 6': [rc(7, 'H', ['Able, R.'], [], [])]}}, open(f'{t}/z/work/supplements/ZZ/2021.json', 'w'))
    run('openstates/convert.py', Z, '--out', f'{t}/z/out', '--legiscan-root', f'{t}/none', env={'OPENSTATES_NEW_REGISTRY': '1'})
    z = [r for r in (json.load(open(f))['roll_call'] for f in glob.glob(f'{t}/z/out/ZZ-*/ZZ/2021*/vote/*.json')) if r['_openstates'].get('from_legislature')]
    assert len(z) == 1 and z[0]['chamber'] == 'H' and z[0]['desc'].startswith('House '), [(r['chamber'], r['desc']) for r in z]


@check
def openstates_convert_cites_ohios_votes_page_and_keeps_each_vote_once(t):
    """Ohio 2026-11-16: the dump's vote addresses (search-prod.lis.state.oh.us/solarapi/v1/...) are dead, and most
    votes are in the dump two to four times. Each converted vote must cite the bill's Votes page with the vote named
    after a # (day, chamber, tally), a /cmtevotes row must be a committee vote, a vote stored three times must be one
    roll call (the copy updated last), the marker must count what was dropped, and an address of another form keeps
    its own address."""
    X = f'{t}/work/extracts/2026-11/oh'; os.makedirs(X)
    def tsv(name, cols, rows):
        open(f'{X}/{name}.tsv', 'w').write('\t'.join(cols) + '\n' + ''.join('\t'.join(r.get(c, '\\N') for c in cols) + '\n' for r in rows))
    json.dump({'dump': '2026-11-public.pgdump', 'month': '2026-11', 'state': 'oh', 'extracted_at': 'x'}, open(f'{X}/extract.json', 'w'))
    tsv('legislativesession', ['id', 'identifier', 'name', 'classification', 'start_date', 'end_date'],
        [{'id': 's135', 'identifier': '135', 'name': '135th Legislature (2023-2024)', 'classification': '', 'start_date': '2023-01-02', 'end_date': '2024-12-31'}])
    tsv('organization', ['id', 'name', 'classification', 'parent_id'], [{'id': 'leg', 'name': 'Ohio General Assembly', 'classification': 'legislature'},
        {'id': 'up', 'name': 'Senate', 'classification': 'upper', 'parent_id': 'leg'}, {'id': 'lo', 'name': 'House', 'classification': 'lower', 'parent_id': 'leg'}])
    tsv('post', ['id', 'label'], [])
    tsv('person', ['id', 'name', 'given_name', 'family_name', 'image', 'primary_party', 'email'],
        [{'id': 'p1', 'name': 'Cindy Abrams', 'given_name': 'Cindy', 'family_name': 'Abrams'}, {'id': 'p2', 'name': 'Tim Barhorst', 'given_name': 'Tim', 'family_name': 'Barhorst'}])
    tsv('membership', ['person_id', 'organization_id', 'post_id', 'start_date', 'end_date'], [])
    tsv('bill', ['id', 'legislative_session_id', 'identifier', 'title', 'classification', 'subject', 'from_organization_id'],
        [{'id': 'b1', 'legislative_session_id': 's135', 'identifier': 'HB 327', 'title': 'A bill', 'classification': '{bill}', 'subject': '{}', 'from_organization_id': 'lo'}])
    tsv('billsource', ['bill_id', 'url'], [])
    tsv('billsponsorship', ['bill_id', 'name', 'entity_type', 'primary', 'person_id'], [])
    # a text link of the dead form, and one of a form the rule does not know (kept as it is)
    tsv('billversion', ['id', 'bill_id', 'note', 'date'], [{'id': 'v1', 'bill_id': 'b1', 'note': 'As Reported by House Committee', 'date': '2024-05-22'},
                                                          {'id': 'v2', 'bill_id': 'b1', 'note': 'As Introduced', 'date': '2023-11-13'}])
    tsv('billversionlink', ['version_id', 'url', 'media_type'], [
        {'version_id': 'v1', 'url': 'https://search-prod.lis.state.oh.us/solarapi/v1/general_assembly_135/bills/hb327/RH/01?format=pdf', 'media_type': 'application/pdf'},
        {'version_id': 'v2', 'url': 'https://search-prod.lis.state.oh.us/solarapi/v1/general_assembly_135/bills/hb327/IN/00/hb327_00_IN.html', 'media_type': 'text/html'}])
    ev = lambda i, motion, cls, upd, d='2024-06-12': {'id': i, 'bill_id': 'b1', 'legislative_session_id': 's135', 'organization_id': 'lo', 'motion_text': motion,
                                                     'motion_classification': cls, 'start_date': d, 'result': 'pass', 'order': '0', 'updated_at': upd}
    tsv('voteevent', ['id', 'bill_id', 'legislative_session_id', 'organization_id', 'motion_text', 'motion_classification', 'start_date', 'result', 'order', 'updated_at'],
        [ev('f1', 'Pass', '{passage}', '2024-06-13'), ev('f2', 'Pass', '{passage}', '2024-11-21'), ev('f3', 'Pass', '{passage}', '2024-07-03'),
         ev('c1', 'Reported - Substitute', '{committee-passage}', '2024-05-23', '2024-05-22'), ev('x1', 'Pass', '{passage}', '2024-06-01', '2024-06-01')])
    old = 'http://search-prod.lis.state.oh.us/solarapi/v1/general_assembly_135/bills/hb327'
    tsv('votesource', ['vote_event_id', 'url'], [{'vote_event_id': 'f1', 'url': old + '/votes'}, {'vote_event_id': 'f2', 'url': old.replace('http:', 'https:') + '/votes'},
        {'vote_event_id': 'f3', 'url': old + '/votes'}, {'vote_event_id': 'c1', 'url': old + '/cmtevotes'},
        {'vote_event_id': 'x1', 'url': 'https://search-prod.lis.state.oh.us/solarapi/v1/general_assembly_135_special_1/bills/hb327/votes'}])
    tsv('votecount', ['vote_event_id', 'option', 'value'], [{'vote_event_id': e, 'option': 'yes', 'value': '1'} for e in ('f1', 'f2', 'f3', 'c1', 'x1')])
    pv = lambda e, name, pid, opt='yes': {'vote_event_id': e, 'voter_name': name, 'option': opt, 'voter_id': pid}
    tsv('personvote', ['vote_event_id', 'voter_id', 'voter_name', 'option'],
        [pv(e, 'Cindy Abrams', 'p1') for e in ('f1', 'f2', 'f3', 'c1', 'x1')] + [pv(e, 'Tim Barhorst', 'p2', 'no') for e in ('f1', 'f2', 'f3')])
    run('openstates/convert.py', X, '--out', f'{t}/out', '--legiscan-root', f'{t}/none', env={'OPENSTATES_NEW_REGISTRY': '1'})
    rcs = {r['_openstates']['vote_event_id']: r for r in (json.load(open(f))['roll_call'] for f in glob.glob(f'{t}/out/OH-*/OH/*/vote/*.json'))}
    assert sorted(rcs) == ['c1', 'f2', 'x1'], sorted(rcs)
    page = 'https://www.legislature.ohio.gov/legislation/135/hb327/votes#'
    assert rcs['f2']['state_link'] == rcs['f2']['url'] == page + '2024-06-12-House-1-1', rcs['f2']['state_link']
    assert rcs['f2']['_openstates']['committee'] is False and rcs['f2']['chamber'] == 'H'
    assert rcs['c1']['_openstates']['committee'] is True and 'Committee' in rcs['c1']['desc'] and rcs['c1']['state_link'] == page + '2024-05-22-House-1-0', rcs['c1']
    assert rcs['x1']['state_link'].endswith('/general_assembly_135_special_1/bills/hb327/votes'), 'an address of another form is kept'
    mk = json.load(open(glob.glob(f'{t}/out/OH-*/.openstates.json')[0]))
    assert mk['counts'].get('duplicate_rollcalls_dropped') == 2 and 'duplicate_rollcalls_dropped_members_differed' not in mk['counts'], mk['counts']
    b = json.load(open(glob.glob(f'{t}/out/OH-*/OH/*/bill/HB327.json')[0]))['bill']
    assert len(b['votes']) == 3, [v['state_link'] for v in b['votes']]
    links = sorted(x['state_link'] for x in b['texts'])
    assert links == ['https://search-prod.lis.state.oh.us/api/v2/general_assembly_135/legislation/hb327/01_RH/pdf/',
                     'https://search-prod.lis.state.oh.us/solarapi/v1/general_assembly_135/bills/hb327/IN/00/hb327_00_IN.html'], links
    # From the 136th the dump's address is the bill's action list, the same for every vote: a committee vote is
    # then told only by its motion ("Reported", classed committee-passage). A conference report the dump also
    # classes committee-passage is the chamber's floor vote.
    acts = 'https://search-prod.lis.state.oh.us/api/v2/general_assembly_135/legislation/hb327/actions'
    ev136 = [ev('r1', 'Reported', '{committee-passage}', '2024-05-23', '2024-05-21'), ev('r2', 'Conference report agreed to', '{committee-passage}', '2024-06-20', '2024-06-20')]
    for name, rows_ in (('voteevent', ev136), ('votesource', [{'vote_event_id': 'r1', 'url': acts}, {'vote_event_id': 'r2', 'url': acts}]),
                        ('votecount', [{'vote_event_id': e, 'option': 'yes', 'value': '1'} for e in ('r1', 'r2')]),
                        ('personvote', [pv(e, 'Cindy Abrams', 'p1') for e in ('r1', 'r2')])):
        head = open(f'{X}/{name}.tsv').read().split('\n', 1)[0].split('\t')
        open(f'{X}/{name}.tsv', 'a').write(''.join('\t'.join(r.get(c, '\\N') for c in head) + '\n' for r in rows_))
    run('openstates/convert.py', X, '--out', f'{t}/out', '--legiscan-root', f'{t}/none')
    rcs = {r['_openstates']['vote_event_id']: r for r in (json.load(open(f))['roll_call'] for f in glob.glob(f'{t}/out/OH-*/OH/*/vote/*.json'))}
    assert rcs['r1']['_openstates']['committee'] is True and rcs['r1']['state_link'] == page + '2024-05-21-House-1-0', rcs['r1']
    assert rcs['r2']['_openstates']['committee'] is False and rcs['r2']['state_link'] == page + '2024-06-20-House-1-0', rcs['r2']
    # Once the legislature's own record of a bill is read (supplements/OH/<GA>.json, 'checked'), it is the bill's floor
    # votes: the dump's 136th dates are clock times, a late vote lands on the next day (136 SB 273: 2026-06-10T01:10Z for
    # the House vote of 2026-06-09), and one dump tally is not the record's (135 SB 58, 62-29 against 63-27). A dump
    # floor vote of that bill not on the record is dropped and counted; one on it is kept once; committee votes stay.
    os.makedirs(f'{t}/work/supplements/OH')
    rec = lambda d, y, n: {'url': page + f'{d}-House-{y}-{n}', 'date': d, 'motion': 'Passed', 'question': 'Passed', 'chamber': 'H',
                           'yea': y, 'nay': n, 'absent': 0, 'passed': 1,
                           'groups': {'Yea': ['Cindy Abrams', 'Tim Barhorst'][:y], 'Nay': ['Tim Barhorst'][:n], 'Absent or not voting': []}}
    json.dump({'state': 'OH', 'session': '135', 'source': 'x', 'bills': {'HB327': [rec('2024-06-11', 1, 1), rec('2024-06-20', 1, 0)]},
               'checked': {'HB327': {'floor': 2, 'read': 2}}, 'refused': {}}, open(f'{t}/work/supplements/OH/135.json', 'w'))
    run('openstates/convert.py', X, '--out', f'{t}/out', '--legiscan-root', f'{t}/none')
    rcs = [json.load(open(f))['roll_call'] for f in glob.glob(f'{t}/out/OH-*/OH/*/vote/*.json')]
    floor = sorted(r['state_link'] for r in rcs if not r['_openstates']['committee'])
    assert floor == [page + '2024-06-11-House-1-1', page + '2024-06-20-House-1-0'], floor
    assert sorted(r['_openstates']['vote_event_id'] for r in rcs if r['_openstates']['committee']) == ['c1', 'r1']
    mk = json.load(open(glob.glob(f'{t}/out/OH-*/.openstates.json')[0]))
    assert mk['counts'].get('dump_floor_rollcalls_not_on_the_record_dropped') == 2, mk['counts']


@check
def openstates_convert_places_a_south_dakota_vote_only_from_the_record(t):
    """South Dakota 2026-11-17: the dump cannot tell a committee's vote from the chamber's (a House committee's "Do
    Pass" is filed under the House, as the floor vote is), so a vote is placed only when it was read from the
    legislature's record. The record's copy replaces the dump's; the dump's copy still teaches who a label is. Every
    address becomes the vote's own page, /Session/Vote/<id>. A consent calendar is one vote on several bills: each
    bill keeps its own copy. Every other dump row is kept, marked committee, with the reason it was not placed."""
    X = f'{t}/work/extracts/2026-11/sd'; os.makedirs(X)
    def tsv(name, cols, rows):
        open(f'{X}/{name}.tsv', 'w').write('\t'.join(cols) + '\n' + ''.join('\t'.join(r.get(c, '\\N') for c in cols) + '\n' for r in rows))
    json.dump({'dump': '2026-11-public.pgdump', 'month': '2026-11', 'state': 'sd', 'extracted_at': 'x'}, open(f'{X}/extract.json', 'w'))
    tsv('legislativesession', ['id', 'identifier', 'name', 'classification', 'start_date', 'end_date'],
        [{'id': 's18', 'identifier': '2018', 'name': '2018 Regular Session', 'classification': '', 'start_date': '2018-01-09', 'end_date': '2018-03-26'}])
    tsv('organization', ['id', 'name', 'classification', 'parent_id'], [{'id': 'leg', 'name': 'South Dakota Legislature', 'classification': 'legislature'},
        {'id': 'up', 'name': 'Senate', 'classification': 'upper', 'parent_id': 'leg'}, {'id': 'lo', 'name': 'House', 'classification': 'lower', 'parent_id': 'leg'}])
    tsv('post', ['id', 'label'], [])
    tsv('person', ['id', 'name', 'given_name', 'family_name', 'image', 'primary_party', 'email'],
        [{'id': 'p1', 'name': 'Ann Able', 'given_name': 'Ann', 'family_name': 'Able'}])
    tsv('membership', ['person_id', 'organization_id', 'post_id', 'start_date', 'end_date'], [])
    bill = lambda i, ident: {'id': i, 'legislative_session_id': 's18', 'identifier': ident, 'title': 'A bill', 'classification': '{bill}', 'subject': '{}', 'from_organization_id': 'lo'}
    tsv('bill', ['id', 'legislative_session_id', 'identifier', 'title', 'classification', 'subject', 'from_organization_id'],
        [bill('b1', 'HB 1209'), bill('b2', 'SB 55'), bill('b3', 'HB 1001')])
    for name, cols in (('billsource', ['bill_id', 'url']), ('billsponsorship', ['bill_id', 'name', 'entity_type', 'primary', 'person_id']),
                       ('billversion', ['id', 'bill_id', 'note', 'date']), ('billversionlink', ['version_id', 'url', 'media_type'])):
        tsv(name, cols, [])
    ev = lambda i, b, upd, org='lo', motion='Do Pass': {'id': i, 'bill_id': b, 'legislative_session_id': 's18', 'organization_id': org, 'motion_text': motion,
                                                        'motion_classification': '{passage}', 'start_date': '2018-02-05', 'result': 'pass', 'order': '0', 'updated_at': upd}
    # f1 and f1old: the consent vote 25955 twice under HB 1209 (the copy updated last is kept); f3: its copy under HB 1001,
    # whose record was not read (SB 55 has no copy of its own, and must still get the record's); c1: a House committee's
    # vote, filed under the House like a floor vote; u1: a vote of HB 1001
    tsv('voteevent', ['id', 'bill_id', 'legislative_session_id', 'organization_id', 'motion_text', 'motion_classification', 'start_date', 'result', 'order', 'updated_at'],
        [ev('f1', 'b1', '2018-03-01'), ev('f1old', 'b1', '2018-02-06'), ev('f3', 'b3', '2018-03-01', 'leg'), ev('c1', 'b1', '2018-03-01'), ev('u1', 'b3', '2018-03-01', 'leg')])
    old = 'http://sdlegislature.gov/Legislative_Session/Bills/RollCall.aspx?Vote={}&Session=2018'
    tsv('votesource', ['vote_event_id', 'url'], [{'vote_event_id': e, 'url': old.format(n)} for e, n in (('f1', 25955), ('f1old', 25955), ('f3', 25955), ('u1', 99))]
        + [{'vote_event_id': 'c1', 'url': 'https://sdlegislature.gov/api/Votes/83164'}])
    tsv('votecount', ['vote_event_id', 'option', 'value'], [{'vote_event_id': e, 'option': 'yes', 'value': '1'} for e in ('f1', 'f1old', 'f3', 'c1', 'u1')])
    # Open States links the voter on the dump's copy; the record names her only by her label
    tsv('personvote', ['vote_event_id', 'voter_id', 'voter_name', 'option'],
        [{'vote_event_id': e, 'voter_name': 'Able', 'option': 'yes', 'voter_id': 'p1'} for e in ('f1', 'f1old', 'f3', 'c1', 'u1')])
    os.makedirs(f'{t}/work/supplements/SD')
    page = 'https://sdlegislature.gov/Session/Vote/'
    rec = {'url': page + '25955', 'date': '2018-02-05', 'motion': 'Do Pass', 'question': 'Do Pass', 'chamber': 'H', 'yea': 1, 'nay': 0, 'absent': 1, 'passed': 1,
           'groups': {'Yea': ['Able'], 'Nay': [], 'Absent or not voting': ['Baker']}}
    json.dump({'state': 'SD', 'session': '2018', 'source': 'sdlegislature.gov', 'bills': {'HB1209': [rec], 'SB55': [rec]},
               'checked': {'HB1209': {'floor': 1, 'read': 1}, 'SB55': {'floor': 1, 'read': 1}}, 'refused': {}}, open(f'{t}/work/supplements/SD/2018.json', 'w'))
    run('openstates/convert.py', X, '--out', f'{t}/out', '--legiscan-root', f'{t}/none', env={'OPENSTATES_NEW_REGISTRY': '1'})
    bills_ = {json.load(open(f))['bill']['bill_id']: json.load(open(f))['bill']['bill_number'] for f in glob.glob(f'{t}/out/SD-*/SD/*/bill/*.json')}
    rcs = [json.load(open(f))['roll_call'] for f in glob.glob(f'{t}/out/SD-*/SD/*/vote/*.json')]
    placed = sorted((bills_[r['bill_id']], r['state_link'], r['chamber']) for r in rcs if not r['_openstates']['committee'])
    assert placed == [('HB1209', page + '25955', 'H'), ('SB55', page + '25955', 'H')], placed
    assert all(r['_openstates'].get('from_legislature') for r in rcs if not r['_openstates']['committee'])
    held = {r['_openstates']['vote_event_id']: r for r in rcs if r['_openstates']['committee']}
    assert sorted(held) == ['c1', 'f3', 'u1'], sorted(held)
    assert held['c1']['state_link'] == page + '83164' and 'not a floor vote' in held['c1']['_openstates']['sd_not_placed'], held['c1']
    assert held['u1']['state_link'] == page + '99' and held['u1']['_openstates']['sd_not_placed'] == "the bill's record was not read", held['u1']
    # the record's "Able" is the person the dump's copy linked, though that copy is not placed
    able = [v['people_id'] for r in rcs if not r['_openstates']['committee'] for v in r['votes'] if v['vote_id'] == 1]
    people = {json.load(open(f))['person']['people_id']: json.load(open(f))['person']['name'] for f in glob.glob(f'{t}/out/SD-*/SD/*/people/*.json')}
    assert [people.get(p) for p in able] == ['Ann Able', 'Ann Able'], (able, people)
    mk = json.load(open(glob.glob(f'{t}/out/SD-*/.openstates.json')[0]))
    assert mk['counts'].get('duplicate_rollcalls_dropped') == 1 and mk['counts'].get('dump_floor_rollcalls_replaced_by_the_record') == 1, mk['counts']


@check
def openstates_convert_places_a_mississippi_vote_only_from_the_record_and_links_its_full_names(t):
    """Mississippi 2026-11-17: the dump misreads the PDF's member list ("Absent or those Barnett"), so a vote is placed
    only when it was read from the record, and every address becomes the vote's own PDF with the bill named
    (/<session>/pdf/votes/<house|senate>/<NNNNNNN>.pdf#HB1793). The record prints full legal names from the member
    list, where Open States often keeps a nickname: a given name that starts the stored one links ("Chris" for
    "Christopher"); otherwise the family name links only when one member of it is seated in that chamber AND the record
    prints only one member of it there that session (Districts 15 and 30 were both Huddleston in 2018, the second
    unknown to Open States). Its counts carry no "sd_" prefix."""
    X = f'{t}/work/extracts/2026-11/ms'; os.makedirs(X)
    def tsv(name, cols, rows):
        open(f'{X}/{name}.tsv', 'w').write('\t'.join(cols) + '\n' + ''.join('\t'.join(r.get(c, '\\N') for c in cols) + '\n' for r in rows))
    json.dump({'dump': '2026-11-public.pgdump', 'month': '2026-11', 'state': 'ms', 'extracted_at': 'x'}, open(f'{X}/extract.json', 'w'))
    tsv('legislativesession', ['id', 'identifier', 'name', 'classification', 'start_date', 'end_date'],
        [{'id': 's26', 'identifier': '2026', 'name': '2026 Regular Session', 'classification': 'primary', 'start_date': '2026-01-06', 'end_date': '2026-04-05'}])
    tsv('organization', ['id', 'name', 'classification', 'parent_id'], [{'id': 'leg', 'name': 'Legislature', 'classification': 'legislature'},
        {'id': 'up', 'name': 'Senate', 'classification': 'upper', 'parent_id': 'leg'}, {'id': 'lo', 'name': 'House', 'classification': 'lower', 'parent_id': 'leg'}])
    tsv('post', ['id', 'label'], [])
    tsv('person', ['id', 'name', 'given_name', 'family_name', 'image', 'primary_party', 'email'],
        [{'id': 'p-car', 'name': 'Bubba Carpenter', 'given_name': 'Bubba', 'family_name': 'Carpenter'},
         {'id': 'p-abl', 'name': 'Christopher Able', 'given_name': 'Christopher', 'family_name': 'Able'},
         {'id': 'p-hud', 'name': 'Mac Huddleston', 'given_name': 'Mac', 'family_name': 'Huddleston'}])
    tsv('membership', ['person_id', 'organization_id', 'post_id', 'start_date', 'end_date'],
        [{'person_id': p, 'organization_id': 'lo', 'start_date': '2024-01-02', 'end_date': '2028-01-01'} for p in ('p-car', 'p-abl', 'p-hud')])
    bill = lambda i, ident: {'id': i, 'legislative_session_id': 's26', 'identifier': ident, 'title': 'A bill', 'classification': '{bill}', 'subject': '{}', 'from_organization_id': 'lo'}
    tsv('bill', ['id', 'legislative_session_id', 'identifier', 'title', 'classification', 'subject', 'from_organization_id'], [bill('b1', 'HB 1793')])
    for name, cols in (('billsource', ['bill_id', 'url']), ('billsponsorship', ['bill_id', 'name', 'entity_type', 'primary', 'person_id']),
                       ('billversion', ['id', 'bill_id', 'note', 'date']), ('billversionlink', ['version_id', 'url', 'media_type'])):
        tsv(name, cols, [])
    ev = lambda i: {'id': i, 'bill_id': 'b1', 'legislative_session_id': 's26', 'organization_id': 'lo', 'motion_text': 'Passed',
                    'motion_classification': '{passage}', 'start_date': '2026-02-25', 'result': 'pass', 'order': '0', 'updated_at': '2026-03-01'}
    # d1: the dump's copy of the vote the record was read for; d2: a vote the record step did not keep (a motion)
    tsv('voteevent', ['id', 'bill_id', 'legislative_session_id', 'organization_id', 'motion_text', 'motion_classification', 'start_date', 'result', 'order', 'updated_at'], [ev('d1'), ev('d2')])
    pdf = 'http://billstatus.ls.state.ms.us/2026/pdf/votes/house/{}.pdf'
    tsv('votesource', ['vote_event_id', 'url'], [{'vote_event_id': 'd1', 'url': pdf.format('0510008')}, {'vote_event_id': 'd2', 'url': pdf.format('0510009')}])
    tsv('votecount', ['vote_event_id', 'option', 'value'], [{'vote_event_id': e, 'option': 'yes', 'value': '1'} for e in ('d1', 'd2')])
    tsv('personvote', ['vote_event_id', 'voter_id', 'voter_name', 'option'], [{'vote_event_id': e, 'voter_name': 'Absent or those Barnett', 'option': 'yes'} for e in ('d1', 'd2')])
    os.makedirs(f'{t}/work/supplements/MS')
    page = 'https://billstatus.ls.state.ms.us/2026/pdf/votes/house/0510008.pdf#HB1793'
    names = ['Lester Carpenter', 'Chris Able', 'Mac Huddleston', 'Robert E. Huddleston']
    rec = {'url': page, 'date': '2026-02-25', 'motion': 'Passed', 'question': 'Passed', 'chamber': 'H', 'yea': 4, 'nay': 0, 'absent': 0, 'passed': 1,
           'groups': {'Yea': names, 'Nay': [], 'Absent or not voting': []}}
    json.dump({'state': 'MS', 'session': '2026', 'source': 'billstatus.ls.state.ms.us', 'bills': {'HB1793': [rec]},
               'checked': {'HB1793': {'floor': 1, 'read': 1}}, 'refused': {}}, open(f'{t}/work/supplements/MS/2026.json', 'w'))
    out = run('openstates/convert.py', X, '--out', f'{t}/out', '--legiscan-root', f'{t}/none', env={'OPENSTATES_NEW_REGISTRY': '1'}).stdout
    rcs = [json.load(open(f))['roll_call'] for f in glob.glob(f'{t}/out/MS-*/MS/*/vote/*.json')]
    placed = [r for r in rcs if not r['_openstates']['committee']]
    assert [(r['state_link'], r['chamber']) for r in placed] == [(page, 'H')], [(r['state_link'], r['chamber']) for r in rcs]
    held = {r['_openstates']['vote_event_id']: r for r in rcs if r['_openstates']['committee']}
    assert sorted(held) == ['d2'], sorted(held)
    assert held['d2']['state_link'] == pdf.format('0510009').replace('http:', 'https:') + '#HB1793', held['d2']['state_link']
    assert 'not a floor vote' in held['d2']['_openstates']['not_placed'] and 'sd_not_placed' not in held['d2']['_openstates'], held['d2']['_openstates']
    people = {j['people_id']: j for j in (json.load(open(f))['person'] for f in glob.glob(f'{t}/out/MS-*/MS/*/people/*.json'))}
    got = sorted((people[v['people_id']]['name'], people[v['people_id']]['_openstates']['person_id']) for v in placed[0]['votes'])
    # Robert E. Huddleston is linked to no one: two Huddlestons are printed, and only one is known to Open States
    assert got == [('Bubba Carpenter', 'p-car'), ('Christopher Able', 'p-abl'), ('Mac Huddleston', 'p-hud'), ('Robert E. Huddleston', None)], got
    assert "'Lester Carpenter' -> 'Bubba Carpenter'" in out and 'Robert E. Huddleston' not in out.split('seat rule')[-1], out
    mk = json.load(open(glob.glob(f'{t}/out/MS-*/.openstates.json')[0]))
    assert mk['counts'].get('dump_rollcalls_not_placed') == 1 and not any(k.startswith('sd_') for k in mk['counts']), mk['counts']


@check
def openstates_convert_places_a_maryland_vote_only_from_the_record_on_its_own_pdf(t):
    """Maryland 2026-11-18: the dump links about one member vote in twenty of 2017-2022 to no one ("Washington, A."), and
    holds no 2023 vote, so a vote is placed only when it was read from the record. Each address becomes the vote's own
    file with the bill named (/<year>RS/votes/<house|senate>/<NNNN>.pdf#SB1; 2017: .htm). 2017's rows carry a page that is
    gone (webmga/frmMain.aspx?pid=flrvotepage&...&id=hb0760,h-0501&...); it is rewritten only when it names the row's bill.
    The old bill page becomes /mgawebsite/Legislation/Details/hb0760?ys=2017RS. A full name from the committee pages
    links with its accents folded: the pages print "Joseline A. Peña-Melnyk", where Open States keeps "Pena-Melnyk"."""
    X = f'{t}/work/extracts/2026-11/md'; os.makedirs(X)
    def tsv(name, cols, rows):
        open(f'{X}/{name}.tsv', 'w').write('\t'.join(cols) + '\n' + ''.join('\t'.join(r.get(c, '\\N') for c in cols) + '\n' for r in rows))
    json.dump({'dump': '2026-11-public.pgdump', 'month': '2026-11', 'state': 'md', 'extracted_at': 'x'}, open(f'{X}/extract.json', 'w'))
    tsv('legislativesession', ['id', 'identifier', 'name', 'classification', 'start_date', 'end_date'],
        [{'id': 's16', 'identifier': '2016', 'name': '2016 Regular Session', 'classification': 'primary', 'start_date': '2016-01-13', 'end_date': '2016-04-11'},
         {'id': 's17', 'identifier': '2017', 'name': '2017 Regular Session', 'classification': 'primary', 'start_date': '2017-01-11', 'end_date': '2017-04-10'}])
    tsv('organization', ['id', 'name', 'classification', 'parent_id'], [{'id': 'leg', 'name': 'General Assembly', 'classification': 'legislature'},
        {'id': 'up', 'name': 'Senate', 'classification': 'upper', 'parent_id': 'leg'}, {'id': 'lo', 'name': 'House', 'classification': 'lower', 'parent_id': 'leg'}])
    tsv('post', ['id', 'label'], [])
    tsv('person', ['id', 'name', 'given_name', 'family_name', 'image', 'primary_party', 'email'],
        [{'id': 'p-pen', 'name': 'Joseline Pena-Melnyk', 'given_name': 'Joseline', 'family_name': 'Pena-Melnyk'},
         {'id': 'p-was', 'name': 'Alonzo Washington', 'given_name': 'Alonzo', 'family_name': 'Washington'}])
    tsv('membership', ['person_id', 'organization_id', 'post_id', 'start_date', 'end_date'],
        [{'person_id': p, 'organization_id': 'lo', 'start_date': '2015-01-14', 'end_date': '2019-01-09'} for p in ('p-pen', 'p-was')])
    bill = lambda i, ident: {'id': i, 'legislative_session_id': 's17', 'identifier': ident, 'title': 'A bill', 'classification': '{bill}', 'subject': '{}', 'from_organization_id': 'lo'}
    # b16: 2016's SB 907, whose veto 2017 overrode on a vote filed under 2017 (2017 has its own SB 907)
    tsv('bill', ['id', 'legislative_session_id', 'identifier', 'title', 'classification', 'subject', 'from_organization_id'],
        [bill('b1', 'HB 760'), {**bill('b16', 'SB 907'), 'legislative_session_id': 's16', 'from_organization_id': 'up'}])
    tsv('billsource', ['bill_id', 'url'], [{'bill_id': 'b1', 'url': 'http://mgaleg.maryland.gov/webmga/frmMain.aspx?id=HB0760&stab=01&pid=billpage&tab=subject3&ys=2017rs'}])
    for name, cols in (('billsponsorship', ['bill_id', 'name', 'entity_type', 'primary', 'person_id']),
                       ('billversion', ['id', 'bill_id', 'note', 'date']), ('billversionlink', ['version_id', 'url', 'media_type'])):
        tsv(name, cols, [])
    ev = lambda i: {'id': i, 'bill_id': 'b1', 'legislative_session_id': 's17', 'organization_id': 'leg', 'motion_text': 'Third Reading Passed',
                    'motion_classification': '{passage}', 'start_date': '2017-03-17', 'result': 'pass', 'order': '0', 'updated_at': '2017-04-01'}
    # d1: the dump's copy of the record vote; d2: a vote the record step did not keep; d3: an old page naming ANOTHER bill
    tsv('voteevent', ['id', 'bill_id', 'legislative_session_id', 'organization_id', 'motion_text', 'motion_classification', 'start_date', 'result', 'order', 'updated_at'],
        [ev('d1'), ev('d2'), ev('d3'), {**ev('d4'), 'bill_id': 'b16', 'legislative_session_id': 's16'}])
    old = 'http://mgaleg.maryland.gov/webmga/frmMain.aspx?pid=flrvotepage&tab=subject7&id={},h-{}&stab=02&ys=2017RS'
    tsv('votesource', ['vote_event_id', 'url'], [{'vote_event_id': 'd1', 'url': old.format('hb0760', '0501')}, {'vote_event_id': 'd2', 'url': old.format('hb0760', '0502')},
                                                 {'vote_event_id': 'd3', 'url': old.format('hb0761', '0503')},
                                                 {'vote_event_id': 'd4', 'url': old.format('sb0907', '1361').replace(',h-', ',s-')}])
    tsv('votecount', ['vote_event_id', 'option', 'value'], [{'vote_event_id': e, 'option': 'yes', 'value': '1'} for e in ('d1', 'd2', 'd3', 'd4')])
    tsv('personvote', ['vote_event_id', 'voter_id', 'voter_name', 'option'], [{'vote_event_id': e, 'voter_name': 'Washington, A.', 'option': 'yes'} for e in ('d1', 'd2', 'd3', 'd4')])
    os.makedirs(f'{t}/work/supplements/MD')
    page = 'https://mgaleg.maryland.gov/2017RS/votes/house/0501.htm#HB760'
    rec = {'url': page, 'date': '2017-03-17', 'motion': 'Third Reading Passed', 'question': 'On Third Reading', 'chamber': 'H', 'yea': 2, 'nay': 0, 'absent': 0, 'passed': 1,
           'groups': {'Yea': ['Joseline A. Peña-Melnyk', 'Alonzo T. Washington'], 'Nay': [], 'Absent or not voting': []}}
    json.dump({'state': 'MD', 'session': '2017', 'source': 'mgaleg.maryland.gov', 'bills': {'HB760': [rec]},
               'checked': {'HB760': {'floor': 1, 'read': 1}}, 'refused': {}}, open(f'{t}/work/supplements/MD/2017.json', 'w'))
    run('openstates/convert.py', X, '--out', f'{t}/out', '--legiscan-root', f'{t}/none', env={'OPENSTATES_NEW_REGISTRY': '1'})
    rcs = [json.load(open(f))['roll_call'] for f in glob.glob(f'{t}/out/MD-*/MD/*/vote/*.json')]
    placed = [r for r in rcs if not r['_openstates']['committee']]
    assert [(r['state_link'], r['chamber']) for r in placed] == [(page, 'H')], [(r['state_link'], r['chamber'], r['_openstates']['committee']) for r in rcs]
    held = {r['_openstates']['vote_event_id']: r for r in rcs if r['_openstates']['committee']}
    assert sorted(held) == ['d2', 'd3', 'd4'], sorted(held)
    assert held['d4']['state_link'] == 'https://mgaleg.maryland.gov/2017RS/votes/senate/1361.htm#2016-SB907', held['d4']['state_link']
    assert held['d2']['state_link'] == 'https://mgaleg.maryland.gov/2017RS/votes/house/0502.htm#HB760', held['d2']['state_link']
    assert held['d3']['state_link'] == old.format('hb0761', '0503').replace('http:', 'https:'), 'an old page naming another bill is left as it is'
    people = {j['people_id']: j for j in (json.load(open(f))['person'] for f in glob.glob(f'{t}/out/MD-*/MD/*/people/*.json'))}
    got = sorted(people[v['people_id']]['_openstates']['person_id'] for v in placed[0]['votes'])
    assert got == ['p-pen', 'p-was'], got
    b = json.load(open(glob.glob(f'{t}/out/MD-*/MD/*/bill/HB760.json')[0]))['bill']
    assert b['state_link'] == 'https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0760?ys=2017RS', b['state_link']
    mks = [json.load(open(f))['counts'] for f in glob.glob(f'{t}/out/MD-*/.openstates.json')]
    assert len(mks) == 2 and sum(c.get('md_vote_address_not_rewritten', 0) for c in mks) == 1, mks


@check
def openstates_convert_links_a_maryland_record_name_to_the_one_person_whose_name_fits(t):
    """Maryland 2026-11-18. The record prints full names; the first pass linked them only among the session's roster
    (memberships and dump-linked voters). Three faults, each measured on the 2017-2026 record:
      - the dump linked none of Theodore Sophocleus's 2017 votes, so the seat rule gave his name to Alice Sophocleus,
        seated in the House that session (and 2020 "Dana Jones" to the Speaker, Adrienne Jones);
      - Open States keeps Alonzo Washington only as a senator, so as a delegate (2017-2022) he was linked to no one;
      - "Heather Bagnall" is Open States' "Heather Bagnall Tudball", a two-word family name.
    Now the one person of the state whose name fits is linked, and printed; the seat rule is never reached for her."""
    X = f'{t}/work/extracts/2026-11/md'; os.makedirs(X)
    def tsv(name, cols, rows):
        open(f'{X}/{name}.tsv', 'w').write('\t'.join(cols) + '\n' + ''.join('\t'.join(r.get(c, '\\N') for c in cols) + '\n' for r in rows))
    json.dump({'dump': '2026-11-public.pgdump', 'month': '2026-11', 'state': 'md', 'extracted_at': 'x'}, open(f'{X}/extract.json', 'w'))
    tsv('legislativesession', ['id', 'identifier', 'name', 'classification', 'start_date', 'end_date'],
        [{'id': 's17', 'identifier': '2017', 'name': '2017 Regular Session', 'classification': 'primary', 'start_date': '2017-01-11', 'end_date': '2017-04-10'}])
    tsv('organization', ['id', 'name', 'classification', 'parent_id'], [{'id': 'leg', 'name': 'General Assembly', 'classification': 'legislature'},
        {'id': 'up', 'name': 'Senate', 'classification': 'upper', 'parent_id': 'leg'}, {'id': 'lo', 'name': 'House', 'classification': 'lower', 'parent_id': 'leg'}])
    tsv('post', ['id', 'label'], [])
    pr = lambda i, given, fam: {'id': i, 'name': f'{given} {fam}', 'given_name': given, 'family_name': fam}
    tsv('person', ['id', 'name', 'given_name', 'family_name', 'image', 'primary_party', 'email'],
        [pr('p-ali', 'Alice', 'Sophocleus'), pr('p-ted', 'Theodore', 'Sophocleus'), pr('p-bag', 'Heather', 'Bagnall Tudball'),
         pr('p-was', 'Alonzo', 'Washington'), pr('p-mwa', 'Mary', 'Washington')])
    tsv('membership', ['person_id', 'organization_id', 'post_id', 'start_date', 'end_date'],
        [{'person_id': 'p-ali', 'organization_id': 'lo', 'start_date': '2015-01-14', 'end_date': '2019-01-09'},
         {'person_id': 'p-bag', 'organization_id': 'lo', 'start_date': '2015-01-14', 'end_date': '2019-01-09'},
         {'person_id': 'p-was', 'organization_id': 'up'}, {'person_id': 'p-mwa', 'organization_id': 'up'}])
    tsv('bill', ['id', 'legislative_session_id', 'identifier', 'title', 'classification', 'subject', 'from_organization_id'],
        [{'id': 'b1', 'legislative_session_id': 's17', 'identifier': 'HB 760', 'title': 'A bill', 'classification': '{bill}', 'subject': '{}', 'from_organization_id': 'lo'}])
    for name, cols in (('billsource', ['bill_id', 'url']), ('billsponsorship', ['bill_id', 'name', 'entity_type', 'primary', 'person_id']),
                       ('billversion', ['id', 'bill_id', 'note', 'date']), ('billversionlink', ['version_id', 'url', 'media_type']),
                       ('voteevent', ['id', 'bill_id', 'legislative_session_id', 'organization_id', 'motion_text', 'motion_classification', 'start_date', 'result', 'order', 'updated_at']),
                       ('votesource', ['vote_event_id', 'url']), ('votecount', ['vote_event_id', 'option', 'value']), ('personvote', ['vote_event_id', 'voter_id', 'voter_name', 'option'])):
        tsv(name, cols, [])
    os.makedirs(f'{t}/work/supplements/MD')
    names = ['Theodore Sophocleus', 'Heather Bagnall', 'Alonzo T. Washington']
    rec = {'url': 'https://mgaleg.maryland.gov/2017RS/votes/house/0501.htm#HB760', 'date': '2017-03-17', 'motion': 'Third Reading Passed',
           'question': 'On Third Reading', 'chamber': 'H', 'yea': 3, 'nay': 0, 'absent': 0, 'passed': 1, 'groups': {'Yea': names, 'Nay': [], 'Absent or not voting': []}}
    json.dump({'state': 'MD', 'session': '2017', 'source': 'mgaleg.maryland.gov', 'bills': {'HB760': [rec]},
               'checked': {'HB760': {'floor': 1, 'read': 1}}, 'refused': {}}, open(f'{t}/work/supplements/MD/2017.json', 'w'))
    out = run('openstates/convert.py', X, '--out', f'{t}/out', '--legiscan-root', f'{t}/none', env={'OPENSTATES_NEW_REGISTRY': '1'}).stdout
    people = {j['people_id']: j for j in (json.load(open(f))['person'] for f in glob.glob(f'{t}/out/MD-*/MD/*/people/*.json'))}
    rc = [json.load(open(f))['roll_call'] for f in glob.glob(f'{t}/out/MD-*/MD/*/vote/*.json')][0]
    got = [people[v['people_id']]['_openstates']['person_id'] for v in rc['votes']]
    assert sorted(map(str, got)) == ['p-bag', 'p-ted', 'p-was'], [(people[v['people_id']]['name'], people[v['people_id']]['_openstates']) for v in rc['votes']]
    assert "'Alonzo T. Washington' -> 'Alonzo Washington'" in out and "'Theodore Sophocleus' -> 'Theodore Sophocleus'" in out, out[-800:]


@check
def openstates_convert_takes_south_dakota_sponsors_named_on_the_introduced_text(t):
    """South Dakota 2026-11-17 (runner: cite the introduced text). The dump marks every sponsor primary and cites a bill
    page that is a script shell. For a bill whose sponsors the fetch read, the bill's page is its introduced text, its
    sponsors are the record's members that text names (prime or co-sponsor as the record says), and the rest are left
    out and counted. A committee sponsor row is kept. A bill not read keeps the dump's sponsors."""
    X = f'{t}/work/extracts/2026-11/sd'; os.makedirs(X)
    def tsv(name, cols, rows):
        open(f'{X}/{name}.tsv', 'w').write('\t'.join(cols) + '\n' + ''.join('\t'.join(r.get(c, '\\N') for c in cols) + '\n' for r in rows))
    json.dump({'dump': '2026-11-public.pgdump', 'month': '2026-11', 'state': 'sd', 'extracted_at': 'x'}, open(f'{X}/extract.json', 'w'))
    tsv('legislativesession', ['id', 'identifier', 'name', 'classification', 'start_date', 'end_date'],
        [{'id': 's26', 'identifier': '2026', 'name': '2026 Regular Session', 'classification': '', 'start_date': '2026-01-13', 'end_date': '2026-03-30'}])
    tsv('organization', ['id', 'name', 'classification', 'parent_id'], [{'id': 'leg', 'name': 'South Dakota Legislature', 'classification': 'legislature'},
        {'id': 'up', 'name': 'Senate', 'classification': 'upper', 'parent_id': 'leg'}, {'id': 'lo', 'name': 'House', 'classification': 'lower', 'parent_id': 'leg'}])
    tsv('post', ['id', 'label'], [])
    tsv('person', ['id', 'name', 'given_name', 'family_name', 'image', 'primary_party', 'email'],
        [{'id': 'p1', 'name': 'Ann Able', 'given_name': 'Ann', 'family_name': 'Able'}, {'id': 'p2', 'name': 'Bo Baker', 'given_name': 'Bo', 'family_name': 'Baker'}])
    tsv('membership', ['person_id', 'organization_id', 'post_id', 'start_date', 'end_date'], [])
    bill = lambda i, ident, org: {'id': i, 'legislative_session_id': 's26', 'identifier': ident, 'title': 'A bill', 'classification': '{bill}', 'subject': '{}', 'from_organization_id': org}
    tsv('bill', ['id', 'legislative_session_id', 'identifier', 'title', 'classification', 'subject', 'from_organization_id'], [bill('b1', 'SB 179', 'up'), bill('b2', 'SB 180', 'up'), bill('b3', 'SB 181', 'up')])
    tsv('billsource', ['bill_id', 'url'], [{'bill_id': b, 'url': f'https://sdlegislature.gov/Session/Bill/{n}'} for b, n in (('b1', 27015), ('b2', 27016), ('b3', 27017))])
    sp = lambda b, name, pid, kind='person': {'bill_id': b, 'name': name, 'entity_type': kind, 'primary': 't', 'person_id': pid}
    tsv('billsponsorship', ['bill_id', 'name', 'entity_type', 'primary', 'person_id'],
        [sp('b1', 'Able', 'p1'), sp('b1', 'Baker', 'p2'), sp('b1', 'Senate Judiciary', '\\N', 'organization'), sp('b2', 'Able', 'p1'), sp('b2', 'Baker', 'p2'), sp('b3', 'Able', 'p1'), sp('b3', 'House State Affairs', '\\N', 'organization')])
    for name, cols in (('billversion', ['id', 'bill_id', 'note', 'date']), ('billversionlink', ['version_id', 'url', 'media_type']),
                       ('voteevent', ['id', 'bill_id', 'legislative_session_id', 'organization_id', 'motion_text', 'motion_classification', 'start_date', 'result', 'order', 'updated_at']),
                       ('votesource', ['vote_event_id', 'url']), ('votecount', ['vote_event_id', 'option', 'value']), ('personvote', ['vote_event_id', 'voter_id', 'voter_name', 'option'])):
        tsv(name, cols, [])
    os.makedirs(f'{t}/work/supplements/SD')
    text = 'https://mylrc.sdlegislature.gov/api/Documents/299353.pdf'
    json.dump({'state': 'SD', 'session': '2026', 'source': 'sdlegislature.gov', 'bills': {}, 'checked': {}, 'refused': {},
               'sponsors': {'SB179': {'text': text, 'introduced_by': 'Senator Able', 'members': [
                   # the record prints her "Able (Ann)", the dump "Able": still the dump's person p1
                   {'name': 'Ann Able', 'label': 'Able (Ann)', 'chamber': 'S', 'type': 'P', 'on_text': True},
                   {'name': 'Bo Baker', 'label': 'Baker', 'chamber': 'S', 'type': 'C', 'on_text': False}]},
                   'SB181': {'refused': 'the introduced text of SB181 names Senator Sutton, who is 0 sponsors of the record'}}},
              open(f'{t}/work/supplements/SD/2026.json', 'w'))
    run('openstates/convert.py', X, '--out', f'{t}/out', '--legiscan-root', f'{t}/none', env={'OPENSTATES_NEW_REGISTRY': '1'})
    bs = {b['bill_number']: b for b in (json.load(open(f))['bill'] for f in glob.glob(f'{t}/out/SD-*/SD/*/bill/*.json'))}
    b1, b2 = bs['SB179'], bs['SB180']
    # sponsors refused: the dump's people are not cited on the script shell; the committee row stays
    assert [(s_['name'], s_['committee_sponsor']) for s_ in bs['SB181']['sponsors']] == [('House State Affairs', 1)], bs['SB181']['sponsors']
    assert b1['state_link'] == text, b1['state_link']
    assert [(s_['name'], s_['sponsor_type_id'], s_['committee_sponsor']) for s_ in b1['sponsors']] == [('Ann Able', 1, 0), ('Senate Judiciary', 1, 1)], b1['sponsors']
    assert b2['state_link'] == 'https://sdlegislature.gov/Session/Bill/27016' and len(b2['sponsors']) == 2, 'a bill not read keeps the dump\'s sponsors'
    able = [s_['people_id'] for s_ in b2['sponsors'] if s_['name'] == 'Ann Able']
    assert able and b1['sponsors'][0]['people_id'] == able[0], ('the record\'s "Able (Ann)" is the dump\'s "Able"', b1['sponsors'][0], b2['sponsors'])
    mk = json.load(open(glob.glob(f'{t}/out/SD-*/.openstates.json')[0]))
    c = mk['counts']
    assert c.get('sd_sponsors_named_on_the_text') == 1 and c.get('sd_sponsors_not_named_on_the_text') == 1 and c.get('dump_sponsor_rows_replaced_by_the_record') == 3 and c.get('sd_sponsor_rows_dropped_sponsors_refused') == 1, c


@check
def openstates_coverage_names_a_session_with_bills_and_no_roll_calls(t):
    """Utah 2026-11-15: the dump held the 2025 session's bills and none of its roll calls, and nothing said so. The
    check must pass a full extract, name a session whose roll calls are gone, name one whose roll calls list no voter,
    and give no verdict for an extract with no bills (Puerto Rico's was empty)."""
    X = openstates_extract(t)
    cov = lambda d, ok=True: run('openstates/coverage.py', d, '--min-bills', '1', ok=ok)
    p = cov(X); assert p.returncode == 0 and 'no gap' in p.stdout, p.stdout[-300:]
    assert 'le.utah.gov/DynaBill/svotes.jsp' in p.stdout, 'the roll-call address a reader must read is printed'
    def drop(name, keep):
        lines = open(f'{X}/{name}.tsv').read().split('\n'); head = lines[0].split('\t')
        open(f'{X}/{name}.tsv', 'w').write('\n'.join([lines[0]] + [l for l in lines[1:] if l and keep(dict(zip(head, l.split('\t'))))]) + '\n')
    saved = {n: open(f'{X}/{n}.tsv').read() for n in ('voteevent', 'personvote', 'bill')}
    # 1. the 2021 session keeps its bill and loses every roll call
    drop('voteevent', lambda r: r['legislative_session_id'] != 's21')
    assert 's21' not in open(f'{X}/voteevent.tsv').read().split('\n', 1)[1], 'the tamper applied'
    p = cov(X, ok=False); assert p.returncode == 1 and 'UT 2021' in p.stdout and 'no roll call' in p.stdout and 'UT 2020' not in p.stdout, p.stdout[-400:]
    # at the default of 50 bills a one-bill session is not a gap
    p = run('openstates/coverage.py', X); assert p.returncode == 0, p.stdout[-200:]
    open(f'{X}/voteevent.tsv', 'w').write(saved['voteevent'])
    # 2. the 2021 roll calls are there and list no voter
    drop('personvote', lambda r: r['vote_event_id'] not in ('h21', 's21v'))
    p = cov(X, ok=False); assert p.returncode == 1 and 'UT 2021' in p.stdout and 'list no voter' in p.stdout, p.stdout[-400:]
    open(f'{X}/personvote.tsv', 'w').write(saved['personvote'])
    # 3. no bill at all: no verdict, and a second state is still read
    Z = openstates_extract(f'{t}/z', st='zz'); drop('bill', lambda r: False)
    p = cov(X, ok=False); assert p.returncode == 2 and 'NO VERDICT' in p.stdout, (p.returncode, p.stdout[-300:])
    p = run('openstates/coverage.py', X, Z, '--min-bills', '1', ok=False)
    assert p.returncode == 2 and 'ZZ: 2 session' in p.stdout and 'NO VERDICT for UT' in p.stdout, p.stdout[-400:]


@check
def roster_sync_brings_the_shared_roster_into_step_and_touches_no_other_state(t):
    """Utah 2026-11-15: the shared roster lacked a new winner, had no office on any Utah row, and kept a level the
    runner had changed. Without --write it reports and changes nothing; with it the batch roster wins for the listed
    ids only, a backup is kept, and a second run finds nothing. A batch row with no office gives no verdict."""
    os.makedirs(t); cols = ['politician_id', 'full_name', 'office_id', 'level', 'state', 'scope', 'leaving', 'race_ids', 'office']
    row = lambda pid, name, level='state', st='UT', office='State Senator': dict(zip(cols, [pid, name, 'o-' + pid, level, st, 'sitting', 'no', '', office]))
    def tsv(path, rows): open(path, 'w').write('\t'.join(cols) + '\n' + ''.join('\t'.join(r[c] for c in cols) + '\n' for r in rows))
    shared, batch, ids = f'{t}/roster.tsv', f'{t}/ut-roster.tsv', f'{t}/ut-ids.txt'
    other = row('x1', 'Tex Other', st='TX', office='')
    tsv(shared, [other, row('a', 'Ann A', office=''), row('b', 'Bea B', level='local', office='')])
    tsv(batch, [row('a', 'Ann A'), row('b', 'Bea B'), row('c', 'Cy New')])
    open(ids, 'w').write('a\nb\nc\n')
    sync = lambda *a, ok=True: run('roster_sync.py', '--shared', shared, '--batch', batch, '--ids', ids, *a, ok=ok)
    before = open(shared).read()
    p = sync(ok=False)
    assert p.returncode == 1 and '1 not in the shared roster' in p.stdout and "level 'local' -> 'state'" in p.stdout and 'office 2' in p.stdout, p.stdout
    assert open(shared).read() == before, 'without --write nothing changes'
    p = sync('--write'); assert p.returncode == 0 and '1 row(s) added' in p.stdout, p.stdout
    got = {r['politician_id']: r for r in read_csv(shared, delimiter='\t')} if 'delimiter' in read_csv.__code__.co_varnames else None
    lines = [l.split('\t') for l in open(shared).read().strip().split('\n')]
    got = {l[0]: dict(zip(cols, l)) for l in lines[1:]}
    assert got['b']['level'] == 'state' and got['a']['office'] == 'State Senator' and got['c']['full_name'] == 'Cy New', got
    assert got['x1'] == other, 'a row of another state is not touched'
    assert open(f'{shared}.bak-sync-ut').read() == before, 'the backup is the file as it was'
    assert sync().returncode == 0
    # a second sync never replaces the first backup
    tsv(batch, [row('a', 'Ann A', office='State Representative'), row('b', 'Bea B'), row('c', 'Cy New')])
    sync('--write'); assert open(f'{shared}.bak-sync-ut').read() == before
    # blind: a batch row with no office, and an id the batch roster does not hold
    tsv(batch, [row('a', 'Ann A', office=''), row('b', 'Bea B'), row('c', 'Cy New')]); mid = open(shared).read()
    p = sync('--write', ok=False); assert p.returncode == 2 and 'blank office' in p.stdout and open(shared).read() == mid, p.stdout
    tsv(batch, [row('a', 'Ann A'), row('b', 'Bea B')])
    p = sync('--write', ok=False); assert p.returncode == 2 and 'not in' in p.stdout and open(shared).read() == mid, p.stdout


@check
def bill_table_affected_lists_only_people_a_new_bill_can_move(t):
    """Ohio 2026-11-16: three late bills, all no rung, 25 people coded again, 0 changed. Only a counted Yes act on a new
    bill WITH a rung can move a code. A flagged bill is refused, and so is a bill the table lacks."""
    S = f'{t}/store'; os.makedirs(f'{S}/instruments/state-xx'); os.makedirs(f'{S}/findings')
    for b in ('XX-HB-1-2025', 'XX-HB-2-2025', 'XX-HB-3-2025'): json.dump({'instrument_id': b, 'operative_text': 'a rule'}, open(f'{S}/instruments/state-xx/{b}.json', 'w'))
    def person(pid, *acts):
        json.dump({'politician_id': pid, 'findings': [{'id': f'{pid}{i}', 'kind': 'record', 'topic_keys': ['tp'], 'instrument_id': b, 'act': a,
                                                       **({'gate_by_topic': {'tp': 'near-unanimous'}} if g else {})} for i, (b, a, g) in enumerate(acts)], 'searches': []},
                  open(f'{S}/findings/{pid}.json', 'w'))
    person('yes', ('XX-HB-1-2025', 'yea', 0)); person('spon', ('XX-HB-1-2025', 'sponsor', 0)); person('no', ('XX-HB-1-2025', 'nay', 0))
    person('gated', ('XX-HB-1-2025', 'yea', 1)); person('norung', ('XX-HB-2-2025', 'yea', 0)); person('none', ('XX-HB-3-2025', 'yea', 0))
    open(f'{t}/ids.txt', 'w').write('yes\nspon\nno\ngated\nnorung\nnone\n')
    T = f'{t}/table.json'
    def table(flag=''): json.dump({'topic_key': 'tp', 'bills': {'XX-HB-1-2025': {'rung': 3, 'deciding_words': 'a rule', 'flag': flag},
                                                               'XX-HB-2-2025': {'rung': None, 'why': 'off the question', 'flag': ''}}}, open(T, 'w'))
    table()
    aff = lambda *bills, ok=True: run('bill_table.py', 'affected', T, *bills, '--ids', f'{t}/ids.txt', '--store', S, '--out', f'{t}/again.txt', ok=ok)
    p = aff('XX-HB-1-2025', 'XX-HB-2-2025')
    assert open(f'{t}/again.txt').read().split() == ['spon', 'yes'], open(f'{t}/again.txt').read()
    assert '5 of 6 people hold a finding' in p.stdout and '2 hold a counted Yes act' in p.stdout, p.stdout
    p = aff('XX-HB-2-2025'); assert open(f'{t}/again.txt').read() == '' and 'no round is needed' in p.stdout, p.stdout
    table(flag='rung 3 or 4?'); p = aff('XX-HB-1-2025', ok=False); assert p.returncode != 0 and 'still flagged' in (p.stderr + p.stdout)
    table(); p = aff('XX-HB-3-2025', ok=False); assert p.returncode != 0 and 'not in the table' in (p.stderr + p.stdout)


@check
def roster_sync_refuses_two_records_for_one_person(t):
    """Runner, 2026-11-16: one person, one record, one stance. Ohio coded "Allison Russo" and "C. Allison Russo" apart and
    the write was held. Two ids that read as one person stop the sync, with --write or without; a listed pair of real
    namesakes passes; a father and a son (a suffix apart) and two people who share only a surname are not a pair."""
    os.makedirs(t); cols = ['politician_id', 'full_name', 'office_id', 'level', 'state', 'scope', 'leaving', 'race_ids', 'office']
    row = lambda pid, name, office='State Representative': dict(zip(cols, [pid, name, 'o', 'state', 'OH', 'sitting', 'no', '', office]))
    def tsv(path, rows): open(path, 'w').write('\t'.join(cols) + '\n' + ''.join('\t'.join(r[c] for c in cols) + '\n' for r in rows))
    shared, batch, ids = f'{t}/roster.tsv', f'{t}/oh-roster.tsv', f'{t}/oh-ids.txt'
    people = [row('r1', 'C. Allison Russo'), row('r2', 'Allison Russo', 'Secretary of State'), row('t1', 'Cecil Thomas'), row('t2', 'Jim Thomas'),
              row('m1', 'Joseph A. Miller, III'), row('m2', 'Joseph A. Miller')]
    tsv(shared, people); tsv(batch, people); open(ids, 'w').write('\n'.join(r['politician_id'] for r in people) + '\n')
    sync = lambda *a, ok=True: run('roster_sync.py', '--shared', shared, '--batch', batch, '--ids', ids, *a, ok=ok)
    before = open(shared).read()
    for a in ((), ('--write',)):
        p = sync(*a, ok=False)
        assert p.returncode == 3 and 'C. Allison Russo' in p.stdout and '1 pair' in p.stdout and 'Thomas' not in p.stdout and 'Miller' not in p.stdout, p.stdout
    assert open(shared).read() == before
    open(f'{t}/distinct.tsv', 'w').write('r1\tr2\n'); assert sync('--distinct', f'{t}/distinct.tsv', ok=False).returncode == 2, 'a pair with no reason gives no verdict'
    open(f'{t}/distinct.tsv', 'w').write('r1\tr2\ttwo people, checked on the House roster\n'); assert sync('--distinct', f'{t}/distinct.tsv').returncode == 0
    open(ids, 'w').write('r1\nt1\nt2\nm1\nm2\n'); assert sync().returncode == 0


@check
def standing_yes_holds_only_when_every_condition_does(t):
    """The desk may write or approve without asking only under the runner's standing yes AND when this passes. Each
    condition is broken in turn; each must turn the answer to "ask the runner"."""
    os.makedirs(f'{t}/legiscan')
    J = lambda f, x: json.dump(x, open(f'{t}/{f}', 'w'))
    W = lambda f, x: open(f'{t}/{f}', 'w').write(x)
    def good():
        J('recipe.json', {'stage5': t, 'topic': 'tp', 'unit': 'state:xx', 'level': 'state', 'state': 'XX', 'roster': f'{t}/r.tsv', 'codes': t, 'saved_root': t, 'votes': 'legiscan-plan'})
        J('recipe-log.json', {**{str(n): f'2026-11-16T06:{n:02d}:00' for n in range(13)}, '8_stale': False})
        W('party-sweep.jsonl', ''); W('party-sweep-research.jsonl', ''); W('research.csv', 'full_name,reasoning\nAnn A,voted yes\n')
        J('legiscan/crosscheck.json', []); J('legiscan/unmapped.json', []); J('legiscan/no-line.json', [])
        W('gate-output-final.txt', 'stance-gate: 3 rows · high=0 medium=1 · evidence rows=9\n')
        W('verify-dry-run.txt', 'AUTO-PUSH: 0  UNCHANGED: 1  REVIEW: 2  RE-RESEARCH: 0  OUT-OF-SCOPE: 0\n')
        W('dry-run-1.txt', 'x\noutcomes:  3 (seated 2, doesnt-fit 1, no-stance 0)\npassages:  1 (own-words 1, local-record 0)\n')
        W('PREVIEW.md', '# preview\n'); os.utime(f'{t}/PREVIEW.md', (2e9, 2e9))
        J('desk-check.json', {'roll_calls_compared': 3, 'member_votes_compared': 121, 'differences': 0, 'odd': []})
        W('verify-apply.txt', 'AUTO-PUSH: 0  UNCHANGED: 1  REVIEW: 2  RE-RESEARCH: 0\nSUMMARY: pushed=0 reviewed=2 errors=0\n'); os.utime(f'{t}/verify-apply.txt', (1e9, 1e9))
        W('readback-1.txt', 'outcomes [{"outcome":"doesnt-fit","count":1},{"outcome":"seated","count":2}]\npassages [{"count":1}]\nreview [{"batch_id":"b","status":"pending","count":2}]\n')
        W('stage5-write-apply.txt', 'topic tp\noutcomes:  3 (seated 2, doesnt-fit 1, no-stance 0)\npassages:  1 (own-words 1, local-record 0)\n')
        J('politicians.json', [{'full_name': 'Ann A', 'politician_id': 'a'}, {'full_name': 'Hal Held', 'politician_id': 'h'}])
        for f in ('held.txt', 'moved.txt'):
            if os.path.exists(f'{t}/{f}'): os.remove(f'{t}/{f}')
    sy = lambda which, ok=True: run('standing_yes.py', which, t, ok=ok)
    good()
    p = sy('write'); assert p.returncode == 0 and 'every condition holds' in p.stdout and "runner's own message" in p.stdout, p.stdout + p.stderr
    p = sy('approve'); assert p.returncode == 0, p.stdout + p.stderr
    def broken(which, change, word, code=1):
        good(); change(); p = sy(which, ok=False)
        assert p.returncode == code and word in p.stdout, (which, word, p.returncode, p.stdout, p.stderr[-200:])
    broken('write', lambda: W('gate-output-final.txt', 'stance-gate: 3 rows · high=2 medium=0 · evidence rows=9\n'), 'step 9')
    broken('write', lambda: J('legiscan/crosscheck.json', [{'agree': False}]), 'step 7')
    broken('write', lambda: J('legiscan/unmapped.json', [{'x': 1}]), 'step 7')
    broken('write', lambda: W('party-sweep-research.jsonl', '{"x":1}\n'), 'step 10')
    broken('write', lambda: J('recipe-log.json', {**{str(n): 'x' for n in range(12)}, '8_stale': False}), 'steps not run: 12')
    broken('write', lambda: J('recipe-log.json', {**{str(n): f'2026-11-16T06:{n:02d}:00' for n in range(13)}, '8_stale': True}), 'stale')
    broken('write', lambda: J('recipe-log.json', {**{str(n): f'2026-11-16T06:{n:02d}:00' for n in range(13)}, '4': '2026-11-16T09:00:00', '8_stale': False}), 'ran after the final gate')
    broken('write', lambda: os.remove(f'{t}/desk-check.json'), 'desk-check.json is missing')
    broken('write', lambda: J('desk-check.json', {'roll_calls_compared': 3, 'member_votes_compared': 121, 'differences': 1, 'odd': []}), 'differences')
    broken('write', lambda: J('desk-check.json', {'roll_calls_compared': 3, 'member_votes_compared': 121, 'differences': 0, 'odd': ['Russo is coded twice']}), 'Russo is coded twice')
    broken('write', lambda: J('desk-check.json', {'roll_calls_compared': 1, 'member_votes_compared': 40, 'differences': 0, 'odd': []}), 'fewer than 2')
    broken('write', lambda: os.remove(f'{t}/PREVIEW.md'), 'PREVIEW.md is not written')
    broken('write', lambda: os.remove(f'{t}/recipe-log.json'), 'NO VERDICT', code=2)
    rb = lambda o, p, r: W('readback-1.txt', f'outcomes {o}\npassages [{{"count":{p}}}]\nreview {r}\n')
    O, R = '[{"outcome":"doesnt-fit","count":1},{"outcome":"seated","count":2}]', '[{"batch_id":"b","status":"pending","count":2}]'
    broken('approve', lambda: rb('[{"outcome":"seated","count":3}]', 1, R), 'read-back outcomes')
    broken('approve', lambda: rb(O, 0, R), 'read-back passages')
    broken('approve', lambda: rb(O, 1, '[{"batch_id":"b","status":"resolved","count":2}]'), 'not all pending')
    broken('approve', lambda: rb(O, 1, '[{"batch_id":"b","status":"pending","count":1}]'), 'sent 2 to review')
    broken('approve', lambda: W('verify-apply.txt', 'REVIEW: 2\nSUMMARY: pushed=0 reviewed=2 errors=1\n'), 'errors=1')
    broken('approve', lambda: os.remove(f'{t}/readback-1.txt'), 'NO VERDICT', code=2)
    broken('approve', lambda: os.utime(f'{t}/verify-apply.txt', (3e9, 3e9)), 'older than')
    broken('approve', lambda: os.remove(f'{t}/stage5-write-apply.txt'), 'NO VERDICT', code=2)
    # --- Mississippi 2026-11-18: people held out of the write. Their unreadable votes are not a reason to ask again, the
    # read-back equals what the WRITE wrote (the dry run less the held), and a row sent back for more research stays pending.
    def held_case(extra=lambda: None):
        good(); W('held.txt', 'h\n'); J('legiscan/no-line.json', [['Hal Held', 'https://x/v.pdf', 'yea', 'XX-HB-1-2025']]); extra()
    held_case(); p = sy('write'); assert p.returncode == 0 and 'belongs to a held person' in p.stdout, p.stdout + p.stderr
    held_case(lambda: J('legiscan/no-line.json', [['Hal Held', 'u', 'yea', 'b'], ['Ann A', 'u', 'yea', 'b']])); p = sy('write', ok=False); assert p.returncode == 1 and 'step 7' in p.stdout, p.stdout
    held_case(lambda: J('legiscan/unmapped.json', [{'no': 'name'}])); p = sy('write', ok=False); assert p.returncode == 1 and 'step 7' in p.stdout, 'an entry that names no one is never excused'
    held_case(lambda: J('legiscan/crosscheck.json', [{'agree': False}])); p = sy('write', ok=False); assert p.returncode == 1, 'a disagreement is never excused'
    def wrote_less(dry, wrote, back, verify='REVIEW: 2\nSUMMARY: pushed=0 reviewed=2 errors=0\n', pending=2):
        W('dry-run-1.txt', f'outcomes:  {dry} (seated {dry - 1}, doesnt-fit 1, no-stance 0)\npassages:  1 (own-words 1, local-record 0)\n')
        W('stage5-write-apply.txt', f'outcomes:  {wrote} (seated {wrote - 1}, doesnt-fit 1, no-stance 0)\n')
        rb(f'[{{"outcome":"doesnt-fit","count":1}},{{"outcome":"seated","count":{back - 1}}}]', 1, f'[{{"batch_id":"b","status":"pending","count":{pending}}}]')
        W('verify-apply.txt', verify); os.utime(f'{t}/verify-apply.txt', (1e9, 1e9))
    held_case(lambda: wrote_less(4, 3, 3)); p = sy('approve'); assert p.returncode == 0, p.stdout + p.stderr
    held_case(lambda: wrote_less(5, 3, 3)); p = sy('approve', ok=False); assert p.returncode == 1 and 'more than the people left out' in p.stdout, p.stdout
    held_case(lambda: wrote_less(4, 3, 4)); p = sy('approve', ok=False); assert p.returncode == 1 and 'not what the write wrote' in p.stdout, p.stdout
    more = 'REVIEW: 2  RE-RESEARCH: 1\nSUMMARY: pushed=0 reviewed=3 errors=0\n'
    held_case(lambda: wrote_less(4, 3, 3, more, 3)); p = sy('approve'); assert p.returncode == 0 and '1 row(s) need more research' in p.stdout, p.stdout + p.stderr
    held_case(lambda: wrote_less(4, 3, 3, more, 2)); p = sy('approve', ok=False); assert p.returncode == 1 and 'back for more research' in p.stdout, p.stdout


fails = 0
with tempfile.TemporaryDirectory() as root:
    for i, f in enumerate(CHECKS):
        try:
            f(os.path.join(root, str(i))); print('ok  ', f.__name__)
        except Exception:
            fails += 1; print('FAIL', f.__name__); traceback.print_exc(limit=3)
print(f'{len(CHECKS) - fails}/{len(CHECKS)} checks pass')
sys.exit(1 if fails else 0)
