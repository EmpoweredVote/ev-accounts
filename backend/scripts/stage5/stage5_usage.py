"""Token log for one Stage 5 state run: the numbers the pilot measures (process-efficiency review 2026-11-12, section 7).

usage: python3 -I scripts/stage5/stage5_usage.py --session <main session .jsonl> [--wave-dir <dir>]... [--people N]
                                                  [--projects <dir>]... [--since <ISO>] [--until <ISO>] [--json <out>]

--session    the main session's transcript (~/.claude/projects/<project>/<session id>.jsonl). Its subagents are read
             from <session id>/subagents/*.jsonl beside it.
--wave-dir   a wave.py output folder; each <name>.result.json names a session id, whose transcript is looked for
             under every --projects root (default ~/.claude/projects and ~/.claude-ev/projects).
--since/--until  keep only turns in this window (one state's run inside a longer session).

Weighted units (as the review): one unit = one new Opus input token; a cache read counts 0.1, a cache write 1.25,
an output token 5; a Sonnet token counts half an Opus token (Haiku 0.2). Raw counts mislead: 95% of Georgia's raw
tokens were re-reads.

Prints: weighted units in all and per person; main-session units, share and steps (assistant turns); agents by kind
and model, with their average starting size (the first turn's input, cache write and cache read). Kinds are guessed
from each agent's first prompt (coder, quote-check, bill-table, triage, search, other).
"""
import collections as C, glob, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt, opts

USAGE = 'stage5_usage.py --session <jsonl> [--wave-dir <dir>]... [--people N] [--since ISO] [--until ISO] [--json <out>]'
W = {'in': 1.0, 'cw': 1.25, 'cr': 0.1, 'out': 5.0}


def model_factor(m):
    m = (m or '').lower()
    return 0.5 if 'sonnet' in m else 0.2 if 'haiku' in m else 1.0


def read(path, since=None, until=None):
    """(totals by model, first prompt, steps, first-turn size) for one transcript."""
    seen, tot, first, steps, start = set(), C.defaultdict(C.Counter), None, 0, None
    for l in open(path):
        try: o = json.loads(l)
        except ValueError: continue
        ts, m = o.get('timestamp') or '', o.get('message') or {}
        if (since and ts and ts < since) or (until and ts and ts > until): continue
        if first is None and o.get('type') == 'user':
            c = m.get('content')
            first = (c if isinstance(c, str) else ' '.join(x.get('text', '') for x in c or [] if isinstance(x, dict)))[:4000]
        if o.get('type') == 'assistant' and m.get('usage') and m.get('id') not in seen:
            seen.add(m.get('id')); steps += 1; u = m['usage']
            t = tot[m.get('model') or '?']
            t['in'] += u.get('input_tokens', 0); t['cw'] += u.get('cache_creation_input_tokens', 0)
            t['cr'] += u.get('cache_read_input_tokens', 0); t['out'] += u.get('output_tokens', 0)
            if start is None: start = u.get('input_tokens', 0) + u.get('cache_creation_input_tokens', 0) + u.get('cache_read_input_tokens', 0)
    return tot, first or '', steps, start or 0


def units(tot): return sum(model_factor(m) * sum(W[k] * c[k] for k in W) for m, c in tot.items())


def kind(first):
    f = first.lower()
    if 'stage 5 coder' in f or 'code-briefs' in f: return 'coder'
    if 'quote check' in f or 'quote-check' in f: return 'quote-check'
    if 'bill table' in f: return 'bill-table'
    if 'triage' in f[:600]: return 'triage'
    if 'search' in f[:1500] or 'source' in f[:300] or 'briefs/' in f: return 'search'
    return 'other'


def find_session(sid, roots):
    for r in roots:
        hits = glob.glob(os.path.join(os.path.expanduser(r), '*', f'{sid}.jsonl'))
        if hits: return hits[0]
    return None


def main():
    main_path = opt('--session', required=True, usage=USAGE)
    since, until = opt('--since'), opt('--until')
    roots = opts('--projects') or ['~/.claude/projects', '~/.claude-ev/projects']
    mt, _, msteps, _ = read(main_path, since, until)
    agents = [p for p in glob.glob(os.path.join(main_path[:-6], 'subagents', '*.jsonl'))]
    missing = []
    for d in opts('--wave-dir'):
        for f in sorted(glob.glob(os.path.join(d, '*.result.json'))):
            try: sid = json.load(open(f)).get('session_id')
            except ValueError: sid = None
            p = find_session(sid, roots) if sid else None
            (agents.append(p) if p else missing.append(os.path.basename(f)))
    by = C.defaultdict(lambda: {'n': 0, 'units': 0.0, 'steps': 0, 'start': 0})
    for p in agents:
        t, first, s, start = read(p, since, until)
        if not s: continue
        model = max(t, key=lambda m: sum(t[m].values())) if t else '?'
        b = by[(kind(first), model)]; b['n'] += 1; b['units'] += units(t); b['steps'] += s; b['start'] += start
    main_u = units(mt); agent_u = sum(b['units'] for b in by.values()); total = main_u + agent_u
    people = int(opt('--people', '0'))
    starts = [b['start'] / b['n'] for b in by.values() if b['n']]
    out = {'total_units': round(total), 'per_person': round(total / people) if people else None,
           'main_units': round(main_u), 'main_share': round(main_u / total, 3) if total else None, 'main_steps': msteps,
           'agent_start_avg': round(sum(b['start'] for b in by.values()) / max(1, sum(b['n'] for b in by.values()))),
           'agents': {f'{k}|{m}': {'n': b['n'], 'units': round(b['units']), 'steps': b['steps'], 'start_avg': round(b['start'] / b['n'])}
                      for (k, m), b in sorted(by.items())},
           'wave_results_without_transcript': missing}
    print(f"weighted units {total / 1e6:.2f}M" + (f", per person {total / people / 1e3:.0f}k ({people} people)" if people else ''))
    print(f"main session {main_u / 1e6:.2f}M ({100 * main_u / total if total else 0:.0f}%), {msteps} steps")
    print(f"agent starting size, average {out['agent_start_avg'] / 1e3:.0f}k" + (f" (by kind {min(starts) / 1e3:.0f}k-{max(starts) / 1e3:.0f}k)" if starts else ''))
    for k, v in out['agents'].items():
        print(f"  {k:45s} n={v['n']:3d} units={v['units'] / 1e6:6.2f}M steps={v['steps']:5d} start={v['start_avg'] / 1e3:4.0f}k")
    if missing: print(f'{len(missing)} wave result(s) with no transcript found under {roots}: {missing[:3]}')
    if opt('--json'): json.dump(out, open(opt('--json'), 'w'), indent=1)
    return 0


if __name__ == '__main__':
    sys.exit(main())
