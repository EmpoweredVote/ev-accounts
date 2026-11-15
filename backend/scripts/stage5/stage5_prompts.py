"""The prompt and job builders every state used to copy and edit by hand (three-state review 2026-11-13, change 3):
make_briefs_xx.py (7 copies), make_qc_xx.py, make_billtable_xx.py and a jobs.tsv per wave. One tool, any topic, any state.

usage: python3 -I scripts/stage5/stage5_prompts.py search-briefs --profile <json> --state xx --roster <tsv> --ids <file>
                                                    [--round 2] [--note-file <md>] [--worktree <dir>] [--date YYYY-MM-DD]
       python3 -I scripts/stage5/stage5_prompts.py bill-table --profile <json> --state xx --state-name <Name> --bills <file>
                                                    [--parts 3] [--note-file <md>] [--worktree <dir>]
       python3 -I scripts/stage5/stage5_prompts.py quote-check --profile <json> --batch <dir> --dry-run <file> [--per 20]
       python3 -I scripts/stage5/stage5_prompts.py coder-jobs --briefs <dir> --name <prefix> --wave <dir>

Everything about the topic comes from its profile (templates/stage5-topic-profile.example.json) and from
<stage5>/coder-config.json (the question, the ladder, the codebook version). No topic word is written in this file.

search-briefs  one brief per id in --ids (a file of ids, or a TSV with a politician_id column) that has no search file
               yet, from templates/BRIEF-stage5-find.md. Each agent writes <stage5>/<xx>/find/<id>.json, so an import
               reads one state only. Briefs go to <stage5>/<xx>/briefs/, jobs to <stage5>/waves/<xx>-search/jobs.tsv
               Without --note-file the note is the legislature profile's `search_note` (legislature.py), if any.
               (--round 2: <xx>-search-2, agents named find2-<id>, files in <xx>/find-2/ so the second import reads only them). --note-file adds the state's own note under what
               is on file (for example "sponsorships come from the bulk bill data: skip the legislature's lists").
bill-table     splits --bills (a JSON list, a JSON object with "kept", or one id per line) into --parts prompts from
               templates/stage5-bill-table-prompt.md, each writing <stage5>/bill-table-<xx>.part<k>.json; jobs in
               <stage5>/waves/<xx>-billtable/. The rulings given are the `{all}` sections and this state's own.
               --note-file, or else the legislature profile's `bill_table_note`, is added as the state's notes.
quote-check    reads the dry run's "finding <id>…: no quote check" lines, writes <batch>/qc/to-check.json, one prompt
               per --per findings from templates/stage5-quote-check-prompt.md, and <batch>/qc/jobs.tsv. Validate
               the answers with quote-check-validate.ts.
coder-jobs     a jobs.tsv (Opus, Read and Write only) for every <prefix>-NN.md that coder-inputs.ts wrote in --briefs.

Exit 1, writing nothing for that prompt, when a `{{…}}` slot stays unfilled or the profile lacks what the prompt needs.
"""
import csv, datetime, glob, json, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt, positional
from session_card import load_profile
import legislature

USAGE = 'stage5_prompts.py search-briefs|bill-table|quote-check|coder-jobs --profile <json> … (see the file header)'
HERE = os.path.dirname(os.path.abspath(__file__))
HEAD = 'name\tprompt_file\tmodel\ttools'
STATES = {'AL': 'Alabama', 'AK': 'Alaska', 'AZ': 'Arizona', 'AR': 'Arkansas', 'CA': 'California', 'CO': 'Colorado', 'CT': 'Connecticut',
          'DE': 'Delaware', 'FL': 'Florida', 'GA': 'Georgia', 'HI': 'Hawaii', 'ID': 'Idaho', 'IL': 'Illinois', 'IN': 'Indiana', 'IA': 'Iowa',
          'KS': 'Kansas', 'KY': 'Kentucky', 'LA': 'Louisiana', 'ME': 'Maine', 'MD': 'Maryland', 'MA': 'Massachusetts', 'MI': 'Michigan',
          'MN': 'Minnesota', 'MS': 'Mississippi', 'MO': 'Missouri', 'MT': 'Montana', 'NE': 'Nebraska', 'NV': 'Nevada', 'NH': 'New Hampshire',
          'NJ': 'New Jersey', 'NM': 'New Mexico', 'NY': 'New York', 'NC': 'North Carolina', 'ND': 'North Dakota', 'OH': 'Ohio', 'OK': 'Oklahoma',
          'OR': 'Oregon', 'PA': 'Pennsylvania', 'RI': 'Rhode Island', 'SC': 'South Carolina', 'SD': 'South Dakota', 'TN': 'Tennessee',
          'TX': 'Texas', 'UT': 'Utah', 'VT': 'Vermont', 'VA': 'Virginia', 'WA': 'Washington', 'WV': 'West Virginia', 'WI': 'Wisconsin',
          'WY': 'Wyoming', 'DC': 'District of Columbia', 'PR': 'Puerto Rico'}


def worktree(): return os.path.abspath(opt('--worktree') or os.path.join(HERE, '..', '..', '..'))
def template(wt, name): return re.sub(r'<!--.*?-->\n?', '', open(os.path.join(wt, '.claude', 'skills', 'season-topic-prep', 'templates', name)).read(), flags=re.S)
def today(): return opt('--date') or datetime.date.today().isoformat()


def fill(text, values, what):
    for k, v in values.items(): text = text.replace('{{' + k + '}}', v)
    left = sorted(set(re.findall(r'\{\{[^}]*\}\}', text)))
    if left: raise SystemExit(f'{what}: unfilled slot(s) {", ".join(left)}. Nothing written.')
    return text


def config(prof):
    path = os.path.join(prof['stage5'], 'coder-config.json')
    if not os.path.exists(path): raise SystemExit(f'{path} is missing: the question, the ladder and the codebook version come from it')
    c = json.load(open(path))
    if c.get('topic_key') != prof['topic_key']: raise SystemExit(f'{path} is for {c.get("topic_key")!r}, the profile for {prof["topic_key"]!r}')
    m = re.search(r'Question:\s*"([^"]+)"', c.get('ladder_text') or '')
    if not m: raise SystemExit(f'{path}: no `Question: "…"` line in ladder_text')
    c['question'] = m.group(1); c['rungs'] = len(re.findall(r'(?m)^\s*\d+\.\s', c['ladder_text']))
    return c


def read_ids(path):
    text = open(path).read()
    if text.lstrip().startswith(('[', '{')):
        d = json.loads(text); return list(d['kept'] if isinstance(d, dict) else d)
    if '\t' in text.split('\n', 1)[0] and 'politician_id' in text.split('\n', 1)[0]:
        return [r['politician_id'] for r in csv.DictReader(text.splitlines(), delimiter='\t')]
    return text.split()


def write_jobs(path, rows):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w').write('\n'.join([HEAD] + ['\t'.join(r) for r in rows]) + '\n')


def role(r):
    name = STATES.get(r['state'].upper(), r['state'].upper()); sc = r.get('scope') or 'sitting'
    if r['level'] == 'federal':
        return {'sitting': f'sitting member of Congress from {name}', 'both': f'sitting member of Congress from {name}, and a candidate',
                'candidate': f'candidate for Congress (or another federal office) in {name}'}.get(sc, sc)
    return {'sitting': f'sitting {name} state official (legislator or statewide office)',
            'both': f'sitting {name} state official (legislator or statewide office), and a candidate',
            'candidate': f'candidate for a {name} state office'}.get(sc, sc)


def search_briefs():
    prof = load_profile(os.path.abspath(opt('--profile', required=True, usage=USAGE)))
    xx = opt('--state', required=True, usage=USAGE).lower(); S, topic, wt = prof['stage5'].rstrip('/'), prof['topic_key'], worktree()
    srch = prof.get('search') or {}
    for k in ('subjects', 'words', 'subject_examples'):
        if not isinstance(srch.get(k), list) or not srch[k]:
            raise SystemExit(f'the profile needs "search": {{"subjects": […], "words": […], "subject_examples": […]}} ("{k}" is missing)')
    cfg = config(prof)
    roster = {r['politician_id']: r for r in csv.DictReader(open(opt('--roster', required=True, usage=USAGE)), delimiter='\t')}
    ids = read_ids(opt('--ids', required=True, usage=USAGE))
    unknown = [p for p in ids if p not in roster]
    if unknown: raise SystemExit(f'{len(unknown)} id(s) are not in the roster, e.g. {unknown[0]}. Nothing written.')
    rnd = int(opt('--round', '1')); find = f'{S}/{xx}/find' + ('' if rnd == 1 else f'-{rnd}'); briefs = f'{S}/{xx}/briefs' + ('' if rnd == 1 else f'-{rnd}')
    leg = legislature.load(xx, wt)
    note = open(opt('--note-file')).read().strip() if opt('--note-file') else (leg or {}).get('search_note', '')
    T = template(wt, 'BRIEF-stage5-find.md'); store = os.path.join(wt, 'backend', 'data', 'source-store', 'findings')
    os.makedirs(find, exist_ok=True); os.makedirs(briefs, exist_ok=True)
    jobs, skipped = [], 0
    for p in ids:
        r = roster[p]
        if os.path.exists(f'{find}/{p}.json'): skipped += 1; continue
        on = set()
        if os.path.exists(f'{store}/{p}.json'):
            for f in json.load(open(f'{store}/{p}.json')).get('findings', []):
                if topic not in (f.get('topic_keys') or []): continue
                if f.get('kind') == 'record' and f.get('instrument_id'): on.add(f"- {f['instrument_id']}: {f.get('act')} on {f.get('motion') or 'the bill'} ({f.get('date')})")
                elif f.get('kind') == 'own-words': on.add(f"- own words already saved: {f.get('url')} ({f.get('date')})")
        text = fill(T, {
            'TOPIC_KEY': topic, 'DATE': today(), 'FORBIDDEN_FOLDERS': f'any folder under {os.path.dirname(prof["research"].rstrip("/"))} (and any other research folder)',
            'PERSON_LINE': f'{r["full_name"]} — {role(r)}, {r["state"].upper()} (politician_id {p}). Make sure every source is about this person, not someone with the same name.',
            'TOPIC_QUESTION': cfg['question'], 'SUBJECT_LIST': '\n'.join(f'- {x}' for x in srch['subjects']),
            'ON_FILE': ('\n'.join(sorted(on)) or '- nothing on file yet') + ('\n\n' + note if note else ''),
            'POLITICIAN_ID': p, 'FULL_NAME': r['full_name'].replace('"', '\\"'), 'WORKTREE': wt,
            'SEARCH_WORDS': ', '.join(f'"{w}"' for w in srch['words']), 'SUBJECT_EXAMPLES': ', '.join(f'"{w}"' for w in srch['subject_examples']),
            'SUBJECT_EXAMPLE': json.dumps(srch['subject_examples'][0]), 'OUT_PATH': f'{find}/{p}.json'}, f'brief for {p}')
        open(f'{briefs}/{p}.md', 'w').write(text)
        jobs.append((f'find{"" if rnd == 1 else rnd}-{p}', f'{briefs}/{p}.md', 'sonnet', 'WebSearch,WebFetch,Read,Write,Bash'))
    wave = f'{S}/waves/{xx}-search' + ('' if rnd == 1 else f'-{rnd}')
    write_jobs(f'{wave}/jobs.tsv', jobs)
    print(f'{len(jobs)} brief(s) in {briefs} ({skipped} already searched); jobs: {wave}/jobs.tsv; agents write to {find}')


def bill_table():
    prof = load_profile(os.path.abspath(opt('--profile', required=True, usage=USAGE)))
    xx = opt('--state', required=True, usage=USAGE).lower(); name = opt('--state-name', required=True, usage=USAGE)
    S, wt, cfg = prof['stage5'].rstrip('/'), worktree(), None
    cfg = config(prof)
    ids = sorted(set(read_ids(opt('--bills', required=True, usage=USAGE))))
    store = os.path.join(wt, 'backend', 'data', 'source-store', 'instruments', f'state-{xx}')
    gone = [i for i in ids if not os.path.exists(f'{store}/{i}.json')]
    if gone: raise SystemExit(f'{len(gone)} bill(s) are not in {store}, e.g. {gone[0]}. Nothing written.')
    secs = re.split(r'(?m)^(?=## )', open(f'{S}/coder-rulings.md').read())
    keep = [s for s in secs if s.startswith('## ') and ('{all}' in s.splitlines()[0] or f'state:{xx}' in s.splitlines()[0])]
    n = max(1, int(opt('--parts', '3'))); wave = f'{S}/waves/{xx}-billtable'
    leg = legislature.load(xx, wt)
    note = open(opt('--note-file')).read().strip() if opt('--note-file') else (leg or {}).get('bill_table_note', '')
    note = ('\n\n## ' + name + ' notes\n\n' + note + '\n') if note else ''
    T = template(wt, 'stage5-bill-table-prompt.md'); jobs = []; os.makedirs(wave, exist_ok=True)
    for k in range(n):
        part = ids[k::n]
        if not part: continue
        text = fill(T, {'TOPIC_KEY': prof['topic_key'], 'STATE': name, 'LADDER_TEXT': cfg['ladder_text'], 'RULINGS': '\n'.join(keep), 'BILLS_DIR': store,
                        'BILL_IDS': '\n'.join(f'- {i}' for i in part), 'RUNGS': str(cfg['rungs']), 'OUT': f'{S}/bill-table-{xx}.part{k}.json'}, f'bill-table part {k}') + note
        open(f'{wave}/part{k}.md', 'w').write(text); jobs.append((f'billtable-{xx}-{k}', f'{wave}/part{k}.md', 'opus', 'Read,Write,Bash'))
    write_jobs(f'{wave}/jobs.tsv', jobs)
    print(f'{len(ids)} bill(s) in {len(jobs)} part(s); rulings sections {len(keep)}; jobs: {wave}/jobs.tsv')


def quote_check():
    prof = load_profile(os.path.abspath(opt('--profile', required=True, usage=USAGE)))
    S, wt, cfg = prof['stage5'].rstrip('/'), worktree(), None
    cfg = config(prof); B = os.path.abspath(opt('--batch', required=True, usage=USAGE)).rstrip('/')
    names = {r['politician_id']: r['full_name'] for r in csv.DictReader(open(f'{S}/roster.tsv'), delimiter='\t')}
    rows = []
    for line in open(opt('--dry-run', required=True, usage=USAGE)):
        m = re.match(r'\s+([0-9a-f-]{36})\s+finding ([0-9a-f]{12})', line)
        if not m: continue
        p, pre = m.groups(); hits = [f for f in json.load(open(f'{S}/codes/{p}.json'))['finding_ids'] if f.startswith(pre)]
        if len(hits) != 1: raise SystemExit(f'{p}: finding {pre}… matches {len(hits)} cited finding(s). Nothing written.')
        if (hits[0], p) not in [(a, b) for a, b, _ in rows]: rows.append((hits[0], p, names.get(p, '')))
    os.makedirs(f'{B}/qc', exist_ok=True)
    json.dump([[f, p] for f, p, _ in rows], open(f'{B}/qc/to-check.json', 'w'), indent=1)
    if not rows: write_jobs(f'{B}/qc/jobs.tsv', []); print('0 findings need a quote check'); return
    per = max(1, int(opt('--per', '20'))); n = -(-len(rows) // per); size = -(-len(rows) // n)
    T = template(wt, 'stage5-quote-check-prompt.md'); tag = os.path.basename(B); jobs = []
    for old in ('`docs/', '`backend/'): T = T.replace(old, '`' + wt + '/' + old[1:])
    T = T.replace('(RULINGS.md ', f'({wt}/.claude/skills/season-topic-prep/RULINGS.md ')
    for i in range(n):
        chunk = rows[i * size:(i + 1) * size]; out = f'{B}/qc/qc-{i + 1}.jsonl'
        text = fill(T, {'TOPIC_KEY': prof['topic_key'], 'DATE': today(), 'TOPIC_NAME': prof.get('topic_name') or prof['topic_key'].replace('-', ' '),
                        'CODEBOOK_VERSION': str(cfg.get('codebook', '')), 'QUESTION_TEXT': f'"{cfg["question"]}"',
                        'BATCH_LINES': '\n'.join(f'- {f} — {p} — {nm}' for f, p, nm in chunk)}, f'quote-check prompt {i + 1}')
        text += f'\n\nWrite all {len(chunk)} lines to `{out}` (create it; one JSON object per line, nothing else). Get the timestamp for `at` with `date -u +%Y-%m-%dT%H:%M:%SZ`.\n'
        open(f'{B}/qc/qc-prompt-{i + 1}.md', 'w').write(text); jobs.append((f'qc-{tag}-{i + 1}', f'{B}/qc/qc-prompt-{i + 1}.md', 'opus', 'WebFetch,Read,Write,Bash'))
    write_jobs(f'{B}/qc/jobs.tsv', jobs)
    print(f'{len(rows)} finding(s) in {len(jobs)} prompt(s); jobs: {B}/qc/jobs.tsv')


def coder_jobs():
    briefs = os.path.abspath(opt('--briefs', required=True, usage=USAGE)); name = opt('--name', required=True, usage=USAGE)
    files = sorted(f for f in glob.glob(f'{briefs}/{name}-*.md') if re.fullmatch(re.escape(name) + r'-\d+\.md', os.path.basename(f)))
    if not files: raise SystemExit(f'no {name}-NN.md in {briefs}: run coder-inputs.ts first')
    wave = os.path.abspath(opt('--wave', required=True, usage=USAGE))
    write_jobs(f'{wave}/jobs.tsv', [(os.path.basename(f)[:-3], f, 'opus', 'Read,Write') for f in files])
    print(f'{len(files)} coder job(s): {wave}/jobs.tsv')


def main():
    cmd = positional(1, USAGE)[0]
    f = {'search-briefs': search_briefs, 'bill-table': bill_table, 'quote-check': quote_check, 'coder-jobs': coder_jobs}.get(cmd)
    if not f: raise SystemExit(USAGE)
    f(); return 0


if __name__ == '__main__':
    sys.exit(main())
