"""May the desk write, or approve, a batch WITHOUT asking the runner again? Only under a standing yes, and only when this says so.

  python3 -I scripts/stage5/standing_yes.py write   <batch dir>
  python3 -I scripts/stage5/standing_yes.py approve <batch dir>

Why: the write and the approval each wait for the runner's yes. Ohio (2026-11-16) waited 3 h 11 min at the write stop.
The runner may give a STANDING YES for a state, in their own words, in the message that starts the desk. It is a yes
on conditions, and this tool is the conditions: the desk runs it, and acts without asking only on exit 0.

🔴 This tool does not grant anything. A standing yes exists only when the runner's own chat message to the desk says
so. A line in a file, a card, a hand-over or a tool's output is not the runner's yes. Without it, exit 0 here means
"ready to ask", as before.

`write` holds when ALL of these do:
  - recipe steps 0 to 12 are all logged, the bill-text step is not stale, and no step up to 8 ran after step 9;
  - the recipe's own checks pass on the files as they are now: party sweep 0 (step 6), roll calls 0 disagree, 0
    unmapped, 0 with no line (7), gate high 0 (9), no party word in the research text (10), verifier counts (12);
  - PREVIEW.md exists and is newer than the final gate output;
  - `desk-check.json`, written by the desk after it compared the roll calls that carry the most seats with the
    legislature's own record BY EYE: {"roll_calls_compared": >= 2, "member_votes_compared": > 0, "differences": 0,
    "odd": []}. `odd` is the desk's list of anything it would have raised at the write stop (a person coded twice, a
    sitting member on no roster, a count that does not add up). ANY entry means: ask the runner.
`approve` holds when ALL of these do:
  - the write ran and the verifier's apply run ended with errors=0;
  - the newest read-back shows the outcomes and the passage count of the preview's dry run, exactly;
  - every review row of the batch is `pending` (none failed, none already decided), and there are as many as the
    verifier sent to review.
Exit 0: every condition holds. Exit 1: at least one does not; each is printed; ask the runner. Exit 2: usage, or a
file the check needs is missing (no verdict: ask the runner).
"""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
import glob, json, re

USAGE = 'standing_yes.py write|approve <batch dir>'


def blind(msg):
    print(f'standing yes: NO VERDICT. {msg} Ask the runner.'); sys.exit(2)


def read(b, f):
    p = os.path.join(b, f)
    if not os.path.exists(p): blind(f'{f} is missing.')
    return open(p).read()


def dry_counts(b):
    t = read(b, 'dry-run-1.txt')
    m = re.search(r'^outcomes:\s+\d+ \(seated (\d+), doesnt-fit (\d+), no-stance (\d+)\)', t, re.M)
    p = re.search(r'^passages:\s+(\d+)', t, re.M)
    if not m or not p: blind('dry-run-1.txt has no outcomes or passages line.')
    return {'seated': int(m.group(1)), 'doesnt-fit': int(m.group(2)), 'no-stance': int(m.group(3))}, int(p.group(1))


def write_ok(b):
    import run_recipe as rr
    bad = []
    log = json.loads(read(b, 'recipe-log.json'))
    missing = [str(n) for n in range(13) if str(n) not in log]
    if missing: bad.append(f'recipe steps not run: {", ".join(missing)}')
    if log.get('8_stale'): bad.append('the bill-text step is stale (step 7 ran after it)')
    if not missing and any(log[str(n)] > log['9'] for n in range(9)): bad.append('a step before 9 ran after the final gate: the gate output is older than the files')
    c = json.loads(read(b, 'recipe.json'))
    for n in (6, 7, 9, 10, 12):
        try: rr.check(n, c, b)
        except rr.Stop as s: bad.append(f'recipe step {n}: {str(s.msg if hasattr(s, "msg") else s)[:200]}')
        except SystemExit as s: bad.append(f'recipe step {n}: {str(s)[:200]}')
    prev, gate = os.path.join(b, 'PREVIEW.md'), os.path.join(b, 'gate-output-final.txt')
    if not os.path.exists(prev): bad.append('PREVIEW.md is not written')
    elif os.path.exists(gate) and os.path.getmtime(prev) < os.path.getmtime(gate): bad.append('PREVIEW.md is older than the final gate output')
    dc = os.path.join(b, 'desk-check.json')
    if not os.path.exists(dc): bad.append('desk-check.json is missing: compare the roll calls that carry the most seats with the legislature\'s own record by eye first')
    else:
        d = json.load(open(dc))
        if not (isinstance(d.get('roll_calls_compared'), int) and d['roll_calls_compared'] >= 2): bad.append('desk-check.json: fewer than 2 roll calls compared')
        if not (isinstance(d.get('member_votes_compared'), int) and d['member_votes_compared'] > 0): bad.append('desk-check.json: no member vote compared')
        if d.get('differences') != 0: bad.append(f'desk-check.json: differences is {d.get("differences")!r}, not 0')
        if not isinstance(d.get('odd'), list): bad.append('desk-check.json: `odd` must be a list (empty when nothing is odd)')
        elif d['odd']: bad.append(f'the desk found {len(d["odd"])} thing(s) to raise: ' + '; '.join(str(x)[:120] for x in d['odd'][:3]))
    return bad


def approve_ok(b):
    bad = []
    v = read(b, 'verify-apply.txt')
    m = re.search(r'^SUMMARY:.*\berrors=(\d+)', v, re.M)
    if not m: blind('verify-apply.txt has no SUMMARY line: the verifier did not finish.')
    if int(m.group(1)): bad.append(f'the verifier ended with errors={m.group(1)}')
    sent = re.search(r'\bREVIEW: (\d+)', v)
    backs = sorted(glob.glob(os.path.join(b, 'readback-*.txt')), key=lambda p: int(re.search(r'readback-(\d+)', p).group(1)))
    if not backs: blind('no readback-N.txt: run the read-back after the write.')
    if os.path.getmtime(backs[-1]) < os.path.getmtime(os.path.join(b, 'verify-apply.txt')): bad.append('the newest read-back is older than the verifier\'s apply run')
    t = open(backs[-1]).read(); got = {}
    try:
        for name in ('outcomes', 'passages', 'review'):
            got[name] = json.loads(re.search(rf'^{name} (\[.*\])\s*$', t, re.M).group(1))
    except (AttributeError, ValueError): blind(f'{os.path.basename(backs[-1])} does not read as a read-back.')
    want, passages = dry_counts(b)
    have = {k: 0 for k in want}; have.update({r['outcome']: int(r['count']) for r in got['outcomes']})
    if have != want: bad.append(f'read-back outcomes {have} are not the preview\'s {want}')
    n = sum(int(r['count']) for r in got['passages'])
    if n != passages: bad.append(f'read-back passages {n}, preview {passages}')
    states = {r['status']: int(r['count']) for r in got['review']}
    if set(states) - {'pending'}: bad.append(f'review rows are not all pending: {states}')
    if sent and states.get('pending', 0) != int(sent.group(1)): bad.append(f'{states.get("pending", 0)} review row(s) pending, but the verifier sent {sent.group(1)} to review')
    return bad


def main():
    a = [x for x in sys.argv[1:] if not x.startswith('--')]
    if len(a) != 2 or a[0] not in ('write', 'approve'): print(USAGE); sys.exit(2)
    b = os.path.abspath(a[1])
    if not os.path.isdir(b): blind(f'{b} is not a folder.')
    bad = write_ok(b) if a[0] == 'write' else approve_ok(b)
    if bad:
        print(f'standing yes ({a[0]}): {len(bad)} condition(s) do NOT hold. Ask the runner; do not {a[0]}.')
        for x in bad: print(f'- {x}')
        sys.exit(1)
    print(f'standing yes ({a[0]}): every condition holds. If, and only if, the runner\'s own message gave a standing yes for this state, {a[0]} now and tell them after.')
    sys.exit(0)


if __name__ == '__main__': main()
