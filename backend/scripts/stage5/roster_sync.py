"""The shared roster must say what the state's own roster says, before the run reads it.

  python3 -I scripts/stage5/roster_sync.py --shared <stage5>/roster.tsv --batch <stage5>/batches/xx-roster.tsv --ids <stage5>/batches/xx-ids.txt [--write]

Why: the set-up leg builds `batches/xx-roster.tsv` (this state's in-scope people, after the results check and the
runner's roster answers), but the record script, the coder inputs, the import and the write read the SHARED
`roster.tsv`, an older export of every state. Utah, 2026-11-15: the shared file lacked a new winner ("not on any
roster"), had a blank office on all 119 Utah rows (the record pass refused 86 of 86), and still had one person at the
level the runner had just changed (she was left out of the write). Two stops no card listed, and one person unwritten.

What it does. The batch roster wins, for the ids in --ids only. Per id it compares every column the two files share.
  - Without --write: prints each difference and exits 1 if there is any. Nothing is changed.
  - With --write: adds the missing rows and sets the differing fields, after copying the shared file to
    `<shared>.bak-sync-<xx>` (an existing backup is kept: the first one is the true original). Prints what it changed.
A row of another state is never touched, and a column only one file has is left alone.
One person, one record (runner, 2026-11-16: "All politicians should only have one record for their stance"). Two ids
of --ids whose names read as one person (same surname and suffix, and the same given name or one the other holds:
"Allison Russo" and "C. Allison Russo") stop the run, with --write or without: Ohio coded one such person twice, on
two records, and the write was held. Settle it in the batch roster and the id list (keep the record the votes are
linked to), or list a real pair of namesakes in --distinct <tsv> (`<id>\t<id>\t<reason>`).
Exit 0: in step (or made so). Exit 3: two records for one person. Exit 1: differences, not written. Exit 2: usage, or the check was blind: an id in --ids
is not in the batch roster, an id's batch row has a blank office, or --ids is empty. It writes nothing then.
"""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt
import csv, shutil

USAGE = 'roster_sync.py --shared <roster.tsv> --batch <xx-roster.tsv> --ids <xx-ids.txt> [--write] [--distinct <tsv>]'
SHARED, BATCH, IDS = (opt(f, required=True, usage=USAGE) for f in ('--shared', '--batch', '--ids'))
WRITE = '--write' in sys.argv


def blind(msg):
    print(f'roster sync: NO VERDICT. {msg}'); sys.exit(2)


def read(path):
    with open(path, newline='') as fh:
        r = csv.DictReader(fh, delimiter='\t', quoting=csv.QUOTE_NONE)
        return r.fieldnames, list(r)


ids = open(IDS).read().split()
if not ids: blind(f'{IDS} lists no one')
bcols, brows = read(BATCH); scols, srows = read(SHARED)
batch = {r['politician_id']: r for r in brows}
off = [p for p in ids if p not in batch]
if off: blind(f'{len(off)} id(s) of {IDS} are not in {BATCH}: {", ".join(off[:5])}')
if 'office' in bcols:
    no_office = [batch[p]['full_name'] for p in ids if not (batch[p].get('office') or '').strip()]
    if no_office: blind(f'{len(no_office)} batch roster row(s) have a blank office (rebuild the roster with topic:stage5-roster): {", ".join(no_office[:5])}')
SUFFIX = {'jr', 'sr', 'ii', 'iii', 'iv', 'v'}
def name_key(full):
    w = [x.strip('.,"').lower() for x in full.replace('"', ' ').split()]
    w = [x for x in w if x]
    suf = ''.join(x for x in w if x in SUFFIX); w = [x for x in w if x not in SUFFIX]
    return (w[-1] if w else '', suf), {x for x in w[:-1] if len(x) > 1}
distinct = set()
if opt('--distinct'):
    for line in open(opt('--distinct')):
        parts = line.rstrip('\n').split('\t')
        if len(parts) >= 2 and not parts[0].startswith('#'):
            if len(parts) < 3 or not parts[2].strip(): blind(f'--distinct line for {parts[0]} gives no reason')
            distinct.add(frozenset(parts[:2]))
by_last = {}
for p in ids: by_last.setdefault((name_key(batch[p]['full_name'])[0], batch[p].get('state', '')), []).append(p)
twice = [(a, b) for group in by_last.values() for i, a in enumerate(group) for b in group[i + 1:]
         if name_key(batch[a]['full_name'])[1] & name_key(batch[b]['full_name'])[1] and frozenset((a, b)) not in distinct]
if twice:
    print(f'roster sync: {len(twice)} pair(s) of records read as ONE person. One person gets one record and one stance. Nothing was written.')
    for a, b in twice: print(f"  {batch[a]['full_name']} ({batch[a].get('office') or '?'}) {a}\n  {batch[b]['full_name']} ({batch[b].get('office') or '?'}) {b}")
    print('Keep the record the votes are linked to; drop the other from the batch roster and the id list (its findings join the kept record). '
          'Two different people: list the pair in --distinct with a reason.')
    sys.exit(3)
cols = [c for c in scols if c in bcols and c != 'politician_id']
shared = {}
for r in srows: shared.setdefault(r['politician_id'], r)   # first row wins, as the readers do

missing = [p for p in ids if p not in shared]
diffs = [(p, c, shared[p].get(c) or '', batch[p].get(c) or '') for p in ids if p in shared for c in cols if (shared[p].get(c) or '') != (batch[p].get(c) or '')]
if not missing and not diffs:
    print(f'roster sync: {len(ids)} people, the shared roster agrees with {os.path.basename(BATCH)} on {", ".join(cols)}.'); sys.exit(0)

by_col = {}
for _, c, _, _ in diffs: by_col[c] = by_col.get(c, 0) + 1
print(f'roster sync: {len(ids)} people; {len(missing)} not in the shared roster; {len(diffs)} field(s) differ'
      + (' (' + ', '.join(f'{c} {n}' for c, n in sorted(by_col.items())) + ')' if by_col else ''))
for p in missing[:20]: print(f"  missing: {batch[p]['full_name']} ({batch[p].get('office') or '?'})  {p}")
shown = 0
for p, c, old, new in diffs:
    if c == 'office' and not old: continue   # a blank office filled: counted above, not listed one by one
    if shown < 40: print(f"  {batch[p]['full_name']}: {c} '{old}' -> '{new}'")
    shown += 1
if shown > 40: print(f'  … and {shown - 40} more')

if not WRITE:
    print('Not written. Run again with --write: the batch roster is the one the set-up leg and the runner settled.'); sys.exit(1)
bak = f'{SHARED}.bak-sync-{os.path.basename(BATCH).split("-")[0]}'
if not os.path.exists(bak): shutil.copy2(SHARED, bak)
for p, c, _, new in diffs: shared[p][c] = new
for p in missing: srows.append({c: batch[p].get(c, '') for c in scols})
tmp = SHARED + '.tmp'
with open(tmp, 'w', newline='') as fh:
    w = csv.DictWriter(fh, fieldnames=scols, delimiter='\t', quoting=csv.QUOTE_NONE, quotechar=None, escapechar=None, lineterminator='\n', extrasaction='ignore')
    w.writeheader(); w.writerows(srows)
os.replace(tmp, SHARED)
print(f'Written: {len(missing)} row(s) added, {len(diffs)} field(s) set in {SHARED} (backup {bak}).')
sys.exit(0)
