"""Checks for the Stage 5 Python batch tools, on small made-up batches in a temporary folder. Each check pins one rule;
a tool is run as a subprocess, the way a batch runs it.
python3 -I scripts/stage5/check_tools.py [--tools <dir>]   (default: this folder; point it at a tampered copy to watch
a check fail). Exit 1 when any check fails. Needs no database, network or node_modules."""
import csv, json, os, shutil, subprocess, sys, tempfile, traceback

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = sys.argv[sys.argv.index('--tools') + 1] if '--tools' in sys.argv else HERE
RU = 'source_url_'


def run(tool, *args, ok=True):
    p = subprocess.run([sys.executable, '-I', os.path.join(TOOLS, tool), *args], capture_output=True, text=True)
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
    single match go to unmapped.json, never a guess."""
    B = batch(f'{t}/b', [('Ann Able', 'a')], [{'full_name': 'Ann Able', 'topic_key': 'tp', 'evidence_type': 'record', 'urls': ['https://off.gov/hb1', 'https://off.gov/hb2', 'https://off.gov/hb3']}], ncols=3)
    os.makedirs(f'{t}/f')
    v = lambda u, ins, d, tal, mo: {'kind': 'record', 'url': u, 'act': 'yea', 'instrument_id': ins, 'chamber': 'H', 'date': d, 'note': f'tally {tal}', 'motion': mo}
    json.dump({'findings': [v('https://off.gov/hb1', 'XX-HB-1-2025', '2025-03-01', '60-40', 'Third reading'),
                            v('https://off.gov/hb2', 'XX-HB-2-2025', '2025-03-02', '70-30', 'Second reading'),
                            v('https://off.gov/hb3', 'XX-HB-3-2025', '2025-03-03', '50-50', 'Committee vote'),
                            v('https://off.gov/hb1', 'XX-HB-1-2025', '2025-03-09', '51-49', 'Final passage')]}, open(f'{t}/f/a.json', 'w'))
    run('state_legiscan.py', 'plan', B, f'{t}/f', '--state', 'XX', '--host', 'off.gov')
    pages = {p['url'] for p in json.load(open(f'{B}/legiscan/vote-pages.json'))}
    assert len(pages) == 4, pages
    h = lambda rc, d, desc, bill: {'roll_call_id': rc, 'date': d, 'desc': desc, 'bill_url': f'https://legiscan.com/XX/bill/{bill}/2025'}
    json.dump([{'url': 'XX-HB-1-2025|H|2025-03-01|60-40', 'hits': [h(11, '2025-03-01', 'Third reading passed', 'HB1')]},
               {'url': 'XX-HB-2-2025|H|2025-03-02|70-30', 'hits': [h(21, '2025-03-02', 'Amendment 3 adopted', 'HB2'), h(22, '2025-03-02', 'Second reading passed', 'HB2')]},
               {'url': 'XX-HB-3-2025|H|2025-03-03|50-50', 'hits': [h(41, '2025-03-03', 'Committee vote', 'HB3')]},  # one match, still a committee vote
               {'url': 'XX-HB-1-2025|H|2025-03-09|51-49', 'hits': [h(31, '2025-03-09', 'Motion to table', 'HB1'), h(32, '2025-03-09', 'Motion to reconsider', 'HB1')]}],
              open(f'{B}/legiscan/rollcall-hits.json', 'w'))
    run('state_legiscan.py', 'pairs', B, f'{t}/f', '--state', 'XX', '--host', 'off.gov', '--topic', 'tp')
    got = sorted(r['source_url'] for r in read_csv(f'{B}/legiscan/pairs.csv'))
    assert got == ['https://legiscan.com/XX/rollcall/HB1/id/11', 'https://legiscan.com/XX/rollcall/HB2/id/22'], got
    un = json.load(open(f'{B}/legiscan/unmapped.json'))
    assert sorted(u[2] for u in un) == ['XX-HB-1-2025', 'XX-HB-3-2025'], un


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
    assert len(a) < 14000 and len(b) < 16000, 'a card is a short page'
    P = profile(t, sides='1,2/3', record_script=True, control_groups=['1:7', '3,2:4'])
    card('B', '--profile', P); b = open(f'{t}/card-B.md').read()
    assert '--control-group 1:7 --control-group 3,2:4' in b and '--sides 1,2/3 --skip-rungs 1,3,2' in b and '{{' not in b, b[:300]
    assert 'rung 1 (control of 7); rungs 3 and 2 (control of 4)' in b
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
sys.exit(int(open(f).read()) if os.path.exists(f) else 0)
"""


@check
def run_state_chains_the_steps_and_stops_only_where_a_person_is_needed(t):
    """Record pass to early check in order; each stop that needs a ruling or a coder ends the run before the next step."""
    os.makedirs(t); P, S = topic_folder(t, sides='1/2,3', record_script=True, control_groups=['3:2', '1:2'])
    tools, bin_, C = f'{t}/tools', f'{t}/bin', f'{t}/stub'
    for d in (tools, bin_, C, f'{S}/record-briefs-zz', f'{S}/code-briefs', f'{S}/search-plan-zz'): os.makedirs(d)
    for n in ('run_state.py', 'session_card.py', '_args.py'): shutil.copy(os.path.join(TOOLS, n), tools)
    for n in ('wave.py', 'stage5_prompts.py', 'search_list.py', 'search_effect.py'): open(f'{tools}/{n}', 'w').write(STUB)
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
    want = ['record-script.ts plan', 'coder-inputs.ts', 'stage5_prompts.py coder-jobs', 'wave.py', 'split-codes.ts', 'split-codes.ts', 'record-script.ts adopt',
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
    json.dump({**json.load(open(P)), 'control_groups': [], 'record_script': False}, open(f'{t}/noskip.json', 'w'))
    r = subprocess.run([sys.executable, '-I', f'{tools}/run_state.py', '--profile', f'{t}/noskip.json', '--state', 'zz'], capture_output=True, text=True, env=env)
    assert r.returncode != 0 and 'no skip rule' in r.stderr, 'a topic with no skip rule is refused, not run with another topic\'s rule'


@check
def wave_starts_agents_slim_and_only_with_named_tools(t):
    os.makedirs(t); open(f'{t}/p.md', 'w').write('x')
    open(f'{t}/jobs.tsv', 'w').write(f'name\tprompt_file\tmodel\ttools\na\t{t}/p.md\topus\tRead,Write\n')
    out = run('wave.py', f'{t}/jobs.tsv', '--out', f'{t}/o', '--print').stdout
    assert '--safe-mode' in out and '--tools Read,Write' in out and 'claude-opus-5-5' in out, out
    assert '--safe-mode' not in run('wave.py', f'{t}/jobs.tsv', '--out', f'{t}/o', '--print', '--full').stdout


fails = 0
with tempfile.TemporaryDirectory() as root:
    for i, f in enumerate(CHECKS):
        try:
            f(os.path.join(root, str(i))); print('ok  ', f.__name__)
        except Exception:
            fails += 1; print('FAIL', f.__name__); traceback.print_exc(limit=1)
print(f'{len(CHECKS) - fails}/{len(CHECKS)} checks pass')
sys.exit(1 if fails else 0)
