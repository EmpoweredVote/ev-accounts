"""Checks for the Stage 5 Python batch tools, on small made-up batches in a temporary folder. Each check pins one rule;
a tool is run as a subprocess, the way a batch runs it.
python3 -I scripts/stage5/check_tools.py [--tools <dir>]   (default: this folder; point it at a tampered copy to watch
a check fail). Exit 1 when any check fails. Needs no database, network or node_modules."""
import csv, json, os, subprocess, sys, tempfile, traceback

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
