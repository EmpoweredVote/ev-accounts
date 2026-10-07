#!/usr/bin/env python3
"""Why Season 2 seats fewer chairs than Season 1 — read-only measurement (2026-10-07).

Input: JSON exports made with a READ-ONLY psql session (PGOPTIONS='-c default_transaction_read_only=on'):
  labels.json   inform.stance_coder_labels + raw_output, joined to politician name and topic_key
  gold.json     inform.stance_gold_labels + topic_key + full_name
  answers.json  inform.politician_answers (politician_id, topic_key, season, value, created_at, editor_id)
  levels.json   {politician_id: federal|state|local|school|judicial|none} from the newest office term
  rungs.json    inform.compass_stance_revisions (rev_id, topic_key, value, text)

Usage: s2_seating_analysis.py <dir-with-exports>   → prints tables and writes <dir>/analysis.json

Writes nothing to the database. Unit of analysis: one (politician, topic, base batch) row, slot-1 coder
(Opus), codebook 0.4, valid labels, NEWEST run (rr2 > rr1 > base; Monroe -r3 > base). This is the same
"--latest" rule reliability-report uses.
"""
import json, re, sys, collections as C
from pathlib import Path

D = Path(sys.argv[1])
labels = json.load(open(D / 'labels.json'))
gold = json.load(open(D / 'gold.json'))
answers = json.load(open(D / 'answers.json'))
levels = json.load(open(D / 'levels.json'))
rungs = json.load(open(D / 'rungs.json'))

RUNG = C.defaultdict(dict)
for r in rungs:
    RUNG[r['rev_id']][r['value']] = r['text']

S1 = {(a['politician_id'], a['topic_key']): a['value'] for a in answers if a['season'] == 'Season 1'}

MONROE = re.compile(r'(monroe|shadow-(houchin|pierce|thomson)-)')


def base(b):
    return re.sub(r'-(rr\d|r\d)$', '', b)


def run_rank(b):
    m = re.search(r'-(rr|r)(\d)$', b)
    return int(m.group(2)) if m else 0


def latest_rows(slot=1):
    best = {}
    for x in labels:
        if x['coder_slot'] != slot or not x['valid'] or x['codebook_version'] != '0.4':
            continue
        b = base(x['batch_id'])
        # Monroe: a person-topic may move between the topic batch and the -nosource batch, so key on
        # the person-topic alone; gold: one row per bill batch.
        key = (x['politician_id'], x['topic_key']) if MONROE.search(b) else (b, x['politician_id'], x['topic_key'])
        r = (run_rank(x['batch_id']), x['created_at'])
        if key not in best or r > best[key][0]:
            best[key] = (r, x)
    return [v[1] for v in best.values()]


# ── cause classification ───────────────────────────────────────────────────────────────────────
DEGREE = re.compile(r'\b(high|as far as possible|significantly|substantially|only|all imports|broadly|'
                    r'current levels?|full|every|any kind|at every stage|without exception|strict|moderately?|'
                    r'aggressive(ly)?|maximum|minimal|some|small)\b', re.I)
NOCLAUSE = re.compile(r'\b(no new conditions|no penalties|no time limit|without (any|moving|new)|no [a-z]+ of any kind|'
                      r'silen(t|ce)|never (says|states|stated)|does not (say|state|name|address)|names no|says nothing|'
                      r'not stated|unstated|is not said)\b', re.I)
NOVOTE = re.compile(r'\b(a no vote|voted no|no vote|nay|voting against|opposed the bill|rules? out)\b', re.I)
MECH = re.compile(r'\b(mechanism|names no (rung|mechanism)|no rung (names|fits|reaches|orders)|fits no rung|'
                  r'not (a|the) (mandate|subsid)|demand-side|cost control|dimension|the ladder (orders|asks)|'
                  r'rungs? order)\b', re.I)
LEVER = re.compile(r'\b(lever|no-lever|own words? (only|can))\b', re.I)
CYCLE = re.compile(r'\b(election[- ]cycle|out[- ]of[- ]cycle|older campaign|previous campaign)\b', re.I)
OMNIBUS = re.compile(r'\b(omnibus|reconciliation|budget bill|appropriations|multi-subject|One Big Beautiful)\b', re.I)


def on_q(p):
    return (p.get('v2_relevance') == 'on-question' and p.get('v1_attribution') in ('own-act', 'own-words')
            and p.get('v3_class') in ('record', 'statement-answer', 'statement-other'))


def classify(x):
    """Primary cause = the first gate in V1→V6 order where every passage stopped."""
    ro = x['raw_output'] or {}
    ps = ro.get('passages', [])
    why = (ro.get('reasoning') or '') + ' ' + ' '.join(p.get('note') or '' for p in ps)
    if 'nosource' in x['batch_id'] or not ps:
        prim = '1 no source found'
    elif not any(p.get('v1_attribution') in ('own-act', 'own-words') and p.get('v3_class') != 'not-evidence' for p in ps):
        prim = '2 only third-party / not-evidence'
    elif not any(on_q(p) for p in ps):
        prim = '3 adjacent / off-question only'
    else:
        oq = [p for p in ps if on_q(p)]
        live = [p for p in oq if p.get('v5_time') == 'in-term']
        if not live:
            prim = '4 time (pre-seating/undated/superseded)'
        else:
            shapes = {p.get('v4_shape') for p in live}
            if 'chair-shaped' in shapes:
                prim = '9 chair-shaped passage, row still blank (' + (x['blank_reason'] or '?') + ')'
            elif 'direction-only' in shapes:
                prim = '5 direction-only'
            elif shapes & {'multi-subject'}:
                prim = '6 multi-subject vote only'
            elif shapes & {'off-axis'}:
                prim = '7 off-axis (mechanism the ladder does not order)'
            else:
                prim = '8 rhetorical / near-unanimous / study only'
    tags = set()
    if DEGREE.search(ro.get('reasoning') or ''): tags.add('degree word')
    if NOCLAUSE.search(why): tags.add('silence / "no X" clause')
    if NOVOTE.search(why): tags.add('No vote / ruling-out')
    if MECH.search(why) or any(p.get('v4_shape') == 'off-axis' and on_q(p) for p in ps): tags.add('mechanism no rung names')
    if LEVER.search(why): tags.add('no-lever level')
    if CYCLE.search(why): tags.add('election cycle')
    if any(p.get('v5_time') == 'pre-seating' for p in ps): tags.add('record before term')
    if OMNIBUS.search(why) or any(p.get('v4_shape') == 'multi-subject' for p in ps): tags.add('multi-subject')
    return prim, tags


def evidence_basis(x):
    """own-words when no surviving in-term on-question passage is a record."""
    ps = (x['raw_output'] or {}).get('passages', [])
    live = [p for p in ps if on_q(p)]
    if not live:
        return 'none'
    return 'record' if any(p.get('v3_class') == 'record' for p in live) else 'own-words'


def quoted_rungs(x):
    """Rung numbers whose text the reasoning quotes (≥ 25 chars of a rung, or a 6-word run)."""
    txt = (x['raw_output'] or {}).get('reasoning') or ''
    out = set()
    for v, t in RUNG.get(x['served_revision_id'], {}).items():
        words = re.findall(r"[A-Za-z']+", t.lower())
        low = re.sub(r'\s+', ' ', txt.lower())
        for i in range(0, max(1, len(words) - 4)):
            if ' '.join(words[i:i + 5]) in low:
                out.add(v)
                break
    return sorted(out)


def report():
    rows = latest_rows(1)
    out = {}
    for name, sel in [('monroe', lambda x: bool(MONROE.search(x['batch_id']))),
                      ('gold-shadow', lambda x: not MONROE.search(x['batch_id']))]:
        R = [x for x in rows if sel(x)]
        seat = [x for x in R if x['value'] is not None]
        print(f'\n=== {name}: {len(R)} rows, {len(seat)} chairs ({100*len(seat)/max(1,len(R)):.0f}%) ===')
        bl = C.Counter(x['blank_reason'] for x in R if x['value'] is None)
        print('blank_reason', dict(bl))
        by = C.defaultdict(C.Counter)
        for x in R:
            st = 'chair' if x['value'] is not None else 'blank'
            by['level:' + (x['level'] or levels.get(x['politician_id'], '?'))][st] += 1
            by['basis:' + evidence_basis(x)][st] += 1
            s1 = S1.get((x['politician_id'], x['topic_key']))
            tr = ('S1 none' if s1 is None else 'S1 chair') + ' → ' + (
                'S2 blank' if x['value'] is None else ('same' if s1 == x['value'] else ('new chair' if s1 is None else 'replaced')))
            by['s1→s2'][tr] += 1
        for k in sorted(by):
            print(' ', k, dict(by[k]))
        prim = C.Counter(); tags = C.Counter(); ex = C.defaultdict(list); tagex = C.defaultdict(list)
        topic = C.defaultdict(C.Counter)
        bound = C.Counter()
        for x in R:
            topic[x['topic_key']]['chair' if x['value'] is not None else (x['blank_reason'] or '?')] += 1
            if x['value'] is not None:
                continue
            p, t = classify(x)
            prim[p] += 1; ex[p].append(x)
            for tg in t:
                tags[tg] += 1; tagex[tg].append(x)
            if x['blank_reason'] in ('direction-only', 'compound-partial'):
                q = quoted_rungs(x)
                bound[(x['topic_key'], tuple(q))] += 1
        print('  primary cause:')
        for k in sorted(prim):
            e = ', '.join(f"{y['full_name'].split()[-1]}/{y['topic_key']} [{y['id'][:8]}]" for y in ex[k][:4])
            print(f'    {k}: {prim[k]}   e.g. {e}')
        print('  tags (a blank can carry several):')
        for k, v in tags.most_common():
            e = ', '.join(f"{y['full_name'].split()[-1]}/{y['topic_key']} [{y['id'][:8]}]" for y in tagex[k][:4])
            print(f'    {k}: {v}   e.g. {e}')
        print('  by topic:')
        for k in sorted(topic, key=lambda k: -sum(topic[k].values())):
            print('   ', k, dict(topic[k]))
        print('  direction-only/compound-partial: rungs quoted in reasoning:')
        for (tk, q), v in sorted(bound.items()):
            print('   ', tk, list(q), v)
        out[name] = {'rows': len(R), 'chairs': len(seat), 'blank_reason': bl, 'primary': prim, 'tags': tags,
                     'examples': {k: [y['id'] for y in v[:8]] for k, v in ex.items()}}
    return out


def gold_report():
    # Newest non-superseded gold row per item; blind gold only; keep excluded rows but mark them.
    sup = {g['supersedes_id'] for g in gold if g['supersedes_id']}
    G = [g for g in gold if g['id'] not in sup and g['mode'] == 'blind']
    print(f'\n=== gold: {len(G)} current blind rows ===')
    c = C.Counter(); lv = C.defaultdict(C.Counter); s1c = C.Counter(); bvf = C.Counter()
    for g in G:
        fin = 'chair' if g['final_value'] is not None else 'blank:' + (g['final_blank_reason'] or '?')
        bl = 'chair' if g['blind_value'] is not None else ('blank' if g['blind_blank_reason'] else 'none')
        c['final ' + fin.split(':')[0]] += 1
        c[fin] += 1
        bvf[f'blind {bl} → final {fin.split(":")[0]}'] += 1
        if g['blind_value'] is not None and g['final_value'] is not None and g['blind_value'] != g['final_value']:
            bvf['blind chair ≠ final chair'] += 1
        lv[levels.get(g['politician_id'], '?')][fin.split(':')[0]] += 1
        s1 = S1.get((g['politician_id'], g['topic_key']))
        if s1 is not None:
            s1c['S1 chair, gold ' + ('same' if g['final_value'] == s1 else ('blank' if g['final_value'] is None else 'other chair'))] += 1
        else:
            s1c['no S1 row'] += 1
    for k, v in sorted(c.items()): print(' ', k, v)
    for k, v in sorted(bvf.items()): print(' ', k, v)
    for k in lv: print('  level', k, dict(lv[k]))
    for k, v in sorted(s1c.items()): print(' ', k, v)
    return {'n': len(G), 'counts': c, 'blind_vs_final': bvf, 's1': s1c}


if __name__ == '__main__':
    res = report()
    res['gold'] = gold_report()
    json.dump(res, open(D / 'analysis.json', 'w'), default=lambda o: dict(o) if isinstance(o, C.Counter) else str(o), indent=1)
