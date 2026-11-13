"""Write a Stage 5 session card: the one short page a session reads instead of the skill file, STAGE5.md, the runbook
and the tools README (three-state review 2026-11-13, change 2: those four cost about 31,000 tokens, carried on every
step of the session).

usage: python3 -I scripts/stage5/session_card.py A|B --profile <topic-profile.json> --state xx --state-name <Name>
                                                  [--worktree <dir>] [--out <file>] [--date YYYY-MM-DD]

--profile   the topic's profile (<stage5>/topic-profile.json; templates/stage5-topic-profile.example.json). Every
            topic-specific value on the card comes from it: the topic key, the research folders, the ladder's sides,
            whether the record pass by script is approved, the skip rule's control groups, the settled rulings. No
            topic, side or rung is written into this tool or its templates. What is known about the state's
            legislature (hosts, vote layout, text marks, what our reader can open) comes from its legislature
            profile, backend/data/legislatures/<xx>.json (legislature.py), when there is one.
--worktree  the worktree the session runs in (default: the one this tool is in). Commands are printed for its backend/.
--out       default <stage5>/<xx>/CARD-<A|B>.md.

The card is rendered from templates/stage5-card-<A|B>.md. A `{{#SKIP}}…{{/SKIP}}` block is kept only when the profile
names control groups, `{{^SKIP}}…{{/SKIP}}` only when it names none; `SCRIPT` the same for the record pass by script.
Exit 1, writing nothing, when the profile is incomplete or any `{{…}}` slot stays unfilled.
"""
import datetime, json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt, positional
import legislature

USAGE = 'session_card.py A|B --profile <topic-profile.json> --state xx --state-name <Name> [--worktree <dir>] [--out <file>]'
HERE = os.path.dirname(os.path.abspath(__file__))
GROUP = re.compile(r'\s*(\d+(?:\s*,\s*\d+)*)\s*:\s*(\d+)\s*')


def load_profile(path):
    """The profile, checked. Keys starting with `_` are notes."""
    p = json.load(open(path))
    for k in ('topic_key', 'label', 'research', 'stage5'):
        if not isinstance(p.get(k), str) or not p[k].strip(): raise SystemExit(f'{path}: "{k}" is missing')
    for k in ('research', 'stage5'):
        if not os.path.isabs(p[k]): raise SystemExit(f'{path}: "{k}" must be an absolute path, so a session never has to look for it')
    groups = p.get('control_groups') or []
    if not isinstance(groups, list) or any(not isinstance(g, str) or not GROUP.fullmatch(g) for g in groups):
        raise SystemExit(f'{path}: "control_groups" must be a list like ["5,2:10", "3:10"], or [] to search everyone')
    p['control_groups'] = groups
    p['record_script'] = bool(p.get('record_script'))
    if p['record_script'] and not p.get('sides'): raise SystemExit(f'{path}: "record_script" is true but "sides" is not set')
    if p['record_script'] and not groups:
        raise SystemExit(f'{path}: "record_script" is true but "control_groups" is empty: the script pass belongs to the record-first flow')
    return p


def skip_rungs(groups):
    out = []
    for g in groups: out += [x.strip() for x in GROUP.fullmatch(g).group(1).split(',')]
    return out


def search_rule(groups):
    parts = []
    for g in groups:
        m = GROUP.fullmatch(g); rungs = [x.strip() for x in m.group(1).split(',')]
        parts.append(f"rung{'s' if len(rungs) > 1 else ''} {' and '.join(rungs)} (control of {m.group(2)})")
    return ('Record seats at ' + '; '.join(parts) + ' are not searched, except each control. A group with no more seats than its '
            'control is all control. Everyone else is searched, with no cap.')


def render(text, flags, values):
    for name, on in flags.items():
        text = re.sub(r'\{\{#' + name + r'\}\}\n?(.*?)\{\{/' + name + r'\}\}\n?', (lambda m: m.group(1)) if on else '', text, flags=re.S)
        text = re.sub(r'\{\{\^' + name + r'\}\}\n?(.*?)\{\{/' + name + r'\}\}\n?', '' if on else (lambda m: m.group(1)), text, flags=re.S)
    for k, v in values.items(): text = text.replace('{{' + k + '}}', v)
    left = sorted(set(re.findall(r'\{\{[^}]*\}\}', text)))
    if left: raise SystemExit(f'unfilled slot(s) on the card: {", ".join(left)}. Nothing written.')
    return text


def main():
    leg = positional(1, USAGE)[0].upper()
    if leg not in ('A', 'B'): raise SystemExit(USAGE)
    path = os.path.abspath(opt('--profile', required=True, usage=USAGE))
    p = load_profile(path)
    xx = opt('--state', required=True, usage=USAGE).lower()
    if not re.fullmatch(r'[a-z]{2}', xx): raise SystemExit('--state is the two-letter code, e.g. wa')
    name = opt('--state-name', required=True, usage=USAGE)
    wt = os.path.abspath(opt('--worktree') or os.path.join(HERE, '..', '..', '..'))
    skill = os.path.join(wt, '.claude', 'skills', 'season-topic-prep')
    S, groups = p['stage5'].rstrip('/'), p['control_groups']
    settled = [s for s in p.get('settled') or [] if isinstance(s, str) and s.strip()]
    lg = legislature.load(xx, wt)
    values = {
        'TOPIC': p['topic_key'], 'LABEL': p['label'], 'STATE': name, 'xx': xx, 'XX': xx.upper(),
        'R': p['research'].rstrip('/'), 'SAVED_ROOT': os.path.dirname(p['research'].rstrip('/')), 'S': S, 'WT': wt, 'BACKEND': os.path.join(wt, 'backend'), 'SKILL': skill,
        'PROFILE': path, 'CARD_B': f'{S}/{xx}/CARD-B.md', 'SINCE': str(p.get('since') or 2017),
        'DATE': opt('--date') or datetime.date.today().isoformat(),
        'SIDES': str(p.get('sides') or ''), 'SKIP_RUNGS': ','.join(skip_rungs(groups)),
        'CONTROL_ARGS': ' '.join(f'--control-group {g.replace(" ", "")}' for g in groups),
        'SEARCH_RULE': search_rule(groups) if groups else '',
        'LEG_PATH': os.path.join(legislature.folder(wt), f'{xx}.json'), 'LEG_SUMMARY': legislature.summary(lg) if lg else '',
        'RECIPE_VOTES': lg['votes']['mode'] if lg else '', 'RECIPE_HOSTS': ','.join(lg['votes']['official_hosts']) if lg else '',
        'RECIPE_LEGISCAN': (',\n "legiscan_args": ' + json.dumps(lg['votes']['legiscan_args'])) if lg and lg['votes'].get('legiscan_args') else '',
        'SETTLED': '\n'.join(f'- {s.strip()}' for s in settled) or '- Nothing is recorded as settled for this topic. Check `coder-rulings.md` before asking a bill question.',
    }
    text = render(open(os.path.join(skill, 'templates', f'stage5-card-{leg}.md')).read(), {'SKIP': bool(groups), 'SCRIPT': p['record_script'], 'LEG': bool(lg)}, values)
    out = opt('--out') or f'{S}/{xx}/CARD-{leg}.md'
    os.makedirs(os.path.dirname(out), exist_ok=True)
    open(out, 'w').write(text)
    print(f'{out}: {len(text):,} characters (about {len(text) // 4:,} tokens)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
