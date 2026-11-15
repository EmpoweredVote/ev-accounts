"""Legislature profiles: what a state's legislature is like, written once and read by every topic (three-state review
2026-11-13, change 6). Each Stage 5 state learned its legislature's hosts, vote layout and text marks by hand and left
them as prose in a hand-over; the next topic to visit that state would have learned them again.

usage: python3 -I scripts/stage5/legislature.py show xx [--worktree <dir>]
       python3 -I scripts/stage5/legislature.py check [xx]            (no xx: every profile on file)
       python3 -I scripts/stage5/legislature.py new xx --name <Name>  (writes a skeleton to fill at hand-over time)

A profile is backend/data/legislatures/<xx>.json. It holds facts about the LEGISLATURE only: never a topic, a rung, a
bill ruling or a person. It names its source and the day it was verified, because sites change.

  state, name, verified (YYYY-MM-DD), source
  chambers            {"lower": "House", "upper": "Senate"}
  sessions            plain words: how sessions are numbered, special sessions
  bill_data           where bulk bill data comes from, and any limit on fetching it
  votes               mode (run_recipe's `votes`), official_hosts, legiscan_args (or null), floor_rule, gaps
  texts               hosts, marks (how a text shows new and struck words), note
  reader_access       host -> "open", "not checked" or "blocked: why", for every votes and texts host. A blocked host is
                      known BEFORE a session meets it; "not checked" tells session A to probe it.
  search_note         added to every search brief for this state (what the bulk data already covers)
  bill_table_note     added to every bill-table prompt for this state
  fill_quotes         {"label_strips": [regex, …]}: section labels the fill quote checker removes before comparing
  quirks              anything else the next session needs, one line each

Readers: session_card.py (the write recipe and the quirks on both cards), stage5_prompts.py (the two notes),
check_fill_quotes.py (the label strips). `check` fails a profile that is missing a part, names a topic-looking word in a
note ("gun", "voter", a rung), or has a regex that does not compile.
"""
import datetime, glob, json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt, positional

USAGE = 'legislature.py show xx | check [xx] | new xx --name <Name>   [--worktree <dir>]'
HERE = os.path.dirname(os.path.abspath(__file__))
MODES = ('legiscan', 'legiscan-plan', 'iga', 'ma', 'federal', 'none')
TOPIC_WORDS = re.compile(r'\b(gun|firearm|voter|abortion|rung \d|rungs? \d)\b', re.I)


def folder(wt=None): return os.path.join(os.path.abspath(wt or os.path.join(HERE, '..', '..', '..')), 'backend', 'data', 'legislatures')


def problems(p, xx):
    out = []
    def need(cond, msg):
        if not cond: out.append(msg)
    need(p.get('state') == xx, f'"state" must be "{xx}"')
    for k in ('name', 'source', 'sessions', 'search_note', 'bill_table_note'): need(isinstance(p.get(k), str) and p[k].strip(), f'"{k}" is missing')
    need(re.fullmatch(r'\d{4}-\d{2}-\d{2}', str(p.get('verified') or '')), '"verified" must be a date, YYYY-MM-DD')
    ch = p.get('chambers') or {}
    need(isinstance(ch.get('lower'), str) and isinstance(ch.get('upper'), str), '"chambers" needs "lower" and "upper" names')
    v = p.get('votes') or {}
    need(v.get('mode') in MODES, f'"votes.mode" must be one of {", ".join(MODES)}')
    need(isinstance(v.get('official_hosts'), list) and v.get('official_hosts'), '"votes.official_hosts" must list at least one host')
    need(v.get('legiscan_args') is None or isinstance(v.get('legiscan_args'), str), '"votes.legiscan_args" is a string or null')
    need(isinstance(v.get('floor_rule'), str) and v['floor_rule'].strip(), '"votes.floor_rule" is missing')
    t = p.get('texts') or {}
    need(isinstance(t.get('hosts'), list) and t.get('hosts') and isinstance(t.get('marks'), str) and t['marks'].strip(), '"texts" needs "hosts" and "marks"')
    ra = p.get('reader_access') or {}
    need(isinstance(ra, dict) and ra, '"reader_access" must name at least one host')
    for h, s in (ra.items() if isinstance(ra, dict) else []):
        need(isinstance(s, str) and (s in ('open', 'not checked') or s.startswith('blocked: ')), f'"reader_access.{h}" must be "open", "not checked" or "blocked: <why>"')
    for h in (v.get('official_hosts') or []) + (t.get('hosts') or []):
        need(h in ra or any(h.endswith(k) or k.endswith(h) for k in ra), f'"reader_access" says nothing about {h}')
    for i, rx in enumerate(((p.get('fill_quotes') or {}).get('label_strips')) or []):
        try: re.compile(rx)
        except re.error as e: out.append(f'"fill_quotes.label_strips[{i}]" does not compile: {e}')
    need(isinstance((p.get('fill_quotes') or {}).get('label_strips'), list), '"fill_quotes.label_strips" must be a list (it may be empty)')
    need(isinstance(p.get('quirks'), list) and isinstance(p.get('bill_data'), list), '"quirks" and "bill_data" must be lists')
    words = json.dumps({k: p.get(k) for k in ('search_note', 'bill_table_note', 'quirks', 'sessions', 'votes', 'texts')})
    m = TOPIC_WORDS.search(words)
    need(not m, f'a note names a topic or a rung ("{m.group(0) if m else ""}"): a legislature profile is read by every topic')
    return out


def load(xx, wt=None, must=False):
    """The profile for a state, or None when there is none (must=True: exit instead). Exits on a profile that fails `check`."""
    path = os.path.join(folder(wt), f'{xx.lower()}.json')
    if not os.path.exists(path):
        if must: raise SystemExit(f'{path}: no legislature profile for {xx}. Write one with `legislature.py new {xx} --name <Name>`.')
        return None
    p = json.load(open(path)); bad = problems(p, xx.lower())
    if bad: raise SystemExit(f'{path}: ' + '; '.join(bad))
    return p


def summary(p):
    """The profile as the lines a session card shows."""
    v, t = p['votes'], p['texts']
    L = [f'- Verified {p["verified"]} ({p["source"]}). Check anything a site could have changed since.',
         f'- Chambers: {p["chambers"]["lower"]} and {p["chambers"]["upper"]}. {p["sessions"]}',
         f'- Bill data: {" ".join(p["bill_data"])}' if p['bill_data'] else None,
         f'- Votes: mode `{v["mode"]}`; hosts {", ".join(v["official_hosts"])}' + (f'; extra flags `{v["legiscan_args"]}`' if v.get('legiscan_args') else '') + f'. {v["floor_rule"]}',
         *[f'- Vote gap: {g}' for g in v.get('gaps') or []],
         f'- Texts: {", ".join(t["hosts"])}. {t["marks"]}' + (f' {t["note"]}' if t.get('note') else ''),
         *[f'- Our reader and `{h}`: {s}' for h, s in p['reader_access'].items()],
         *[f'- {q}' for q in p['quirks']]]
    return '\n'.join(x for x in L if x)


def main():
    cmd, *rest = positional(1, USAGE); wt = opt('--worktree'); D = folder(wt)
    if cmd == 'check':
        files = [os.path.join(D, f'{rest[0].lower()}.json')] if rest else sorted(glob.glob(os.path.join(D, '*.json')))
        if not files or not all(os.path.exists(f) for f in files): raise SystemExit(f'no profile to check in {D}')
        bad = 0
        for f in files:
            xx = os.path.basename(f)[:-5]; ps = problems(json.load(open(f)), xx); bad += bool(ps)
            print(f'{xx}: ' + ('ok' if not ps else '; '.join(ps)))
        return 1 if bad else 0
    if not rest: raise SystemExit(USAGE)
    xx = rest[0].lower()
    if cmd == 'show': print(summary(load(xx, wt, must=True))); return 0
    if cmd == 'new':
        path = os.path.join(D, f'{xx}.json')
        if os.path.exists(path): raise SystemExit(f'{path} exists: edit it, and set "verified" to today')
        os.makedirs(D, exist_ok=True)
        json.dump({'state': xx, 'name': opt('--name', required=True, usage=USAGE), 'verified': datetime.date.today().isoformat(), 'source': '',
                   'chambers': {'lower': '', 'upper': ''}, 'sessions': '', 'bill_data': [],
                   'votes': {'mode': '', 'official_hosts': [], 'legiscan_args': None, 'floor_rule': '', 'gaps': []},
                   'texts': {'hosts': [], 'marks': '', 'note': ''}, 'reader_access': {}, 'search_note': '', 'bill_table_note': '',
                   'fill_quotes': {'label_strips': []}, 'quirks': []}, open(path, 'w'), indent=2)
        print(f'{path}: fill every part, then `legislature.py check {xx}`'); return 0
    raise SystemExit(USAGE)


if __name__ == '__main__':
    sys.exit(main())
