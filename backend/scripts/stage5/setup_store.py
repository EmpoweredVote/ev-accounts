"""Set-up: put a state's merged bills into the store, the gate table and the subjects list (card A, step A4). Any topic.

  python3 -I scripts/stage5/setup_store.py --stage5 <stage5 dir> --state xx [--store <instruments dir>] [--date YYYY-MM-DD]
      [--tag <backup tag>] [--print]

Reads what bill_merge.py staged under `<stage5>/legiscan`: `store-staging-<xx>/instruments/state-<xx>/*.json`,
`gates-add-<xx>.tsv`, `subjects-add-<xx>.json`. Then, in this order, and only when every check below passes:
  1. copies each staged instrument into the store (`backend/data/source-store/instruments/state-<xx>/`, or --store);
  2. appends the gate rows to `<research>/stage0/gates.tsv` (the folder above <stage5>);
  3. adds the subjects to `<stage5>/subjects.json` (indent 2, as it is kept).
Before it writes anything it checks all three, and writes nothing when one fails (exit 2):
  - no staged instrument is already in the store with other content (the same bytes are skipped and counted);
  - no gate row (bill, vote date, body) is already in gates.tsv with other values; the file ends with a newline;
  - no subject key is already in subjects.json with another value.
gates.tsv and subjects.json are copied first to `<name>.bak-<date>-<tag>` (tag default: the state). Run twice, the
second run adds nothing and says so. Then validate the store: `npm run source-store --prefix backend -- validate`.

Why (2026-11-21): this was six to nine hand commands in every state, written afresh each time from the last state's
log: a loop for clashes, `cp -n`, `cat >>`, an inline script for the subjects. Oregon's and Hawaii's took 6 and 5 steps.
"""
import filecmp, glob, json, os, shutil, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt
import datetime

USAGE = 'setup_store.py --stage5 <dir> --state xx [--store <instruments dir>] [--date YYYY-MM-DD] [--tag <tag>] [--print]'
HERE = os.path.dirname(os.path.abspath(__file__))


def main():
    S = os.path.abspath(opt('--stage5', required=True, usage=USAGE)); xx = opt('--state', required=True, usage=USAGE).lower()
    L = f'{S}/legiscan'; staged = f'{L}/store-staging-{xx}/instruments/state-{xx}'
    store = os.path.abspath(opt('--store') or os.path.join(HERE, '..', '..', 'data', 'source-store', 'instruments')); dest = f'{store}/state-{xx}'
    gates, subjects = f'{os.path.dirname(S)}/stage0/gates.tsv', f'{S}/subjects.json'
    tag = f".bak-{opt('--date') or datetime.date.today().isoformat()}-{opt('--tag') or xx}"; dry = '--print' in sys.argv
    files = sorted(glob.glob(f'{staged}/*.json'))
    if not files: print(f'setup store: NO VERDICT. No staged instrument in {staged}: run bill_merge.py first.'); return 2
    for f in (f'{L}/gates-add-{xx}.tsv', f'{L}/subjects-add-{xx}.json', gates, subjects):
        if not os.path.exists(f): print(f'setup store: NO VERDICT. {f} is missing.'); return 2
    bad = []
    new = [f for f in files if not os.path.exists(f'{dest}/{os.path.basename(f)}')]
    clash = [os.path.basename(f) for f in files if f not in new and not filecmp.cmp(f, f'{dest}/{os.path.basename(f)}', shallow=False)]
    if clash: bad.append(f'{len(clash)} staged instrument(s) are in the store with other content, e.g. {clash[0]}: merge those by hand (bill_merge.py --ids for the rest)')
    add = [l for l in open(f'{L}/gates-add-{xx}.tsv').read().split('\n') if l.strip()]
    # a bill has one gate row per chamber: the key is the bill, the vote's date and the body
    key = lambda l: tuple(l.split('\t')[:3])
    have_text = open(gates).read(); have = {key(l): l for l in have_text.split('\n') if l.strip()}
    if have_text and not have_text.endswith('\n'): bad.append(f'{gates} does not end with a newline: an appended row would join its last line')
    g_new = [l for l in add if key(l) not in have]
    g_diff = [' '.join(key(l)) for l in add if key(l) in have and have[key(l)] != l]
    if g_diff: bad.append(f'{len(g_diff)} gate row(s) are in gates.tsv with other values, e.g. {g_diff[0]} (a ruling may have changed it since the merge: leave it)')
    subs, s_add = json.load(open(subjects)), json.load(open(f'{L}/subjects-add-{xx}.json'))
    if not isinstance(subs, dict) or not isinstance(s_add, dict): bad.append('subjects.json and the staged subjects must both be objects')
    else:
        s_diff = [k for k in s_add if k in subs and subs[k] != s_add[k]]
        if s_diff: bad.append(f'{len(s_diff)} subject key(s) are in subjects.json with another value, e.g. {s_diff[0]}')
    if bad:
        print('setup store: nothing written.'); [print(f'- {b}') for b in bad]; return 2
    s_new = {k: v for k, v in s_add.items() if k not in subs}
    print(f"setup store {xx}: {len(new)} instrument(s) to copy ({len(files) - len(new)} already there, same bytes), "
          f"{len(g_new)} gate row(s) to append ({len(add) - len(g_new)} already there), {len(s_new)} subject(s) to add ({len(s_add) - len(s_new)} already there)")
    if dry or not (new or g_new or s_new): print('nothing to do' if not dry else '(--print: nothing written)'); return 0
    before = (len(glob.glob(f'{dest}/*.json')), len(have), len(subs))
    os.makedirs(dest, exist_ok=True)
    for f in new: shutil.copyfile(f, f'{dest}/{os.path.basename(f)}')
    if g_new:
        shutil.copyfile(gates, gates + tag)
        with open(gates, 'a') as fh: fh.write('\n'.join(g_new) + '\n')
    if s_new:
        shutil.copyfile(subjects, subjects + tag); subs.update(s_new)
        with open(subjects, 'w') as fh: json.dump(subs, fh, indent=2, ensure_ascii=False); fh.write('\n')
    print(f"store state-{xx} {before[0]}->{len(glob.glob(f'{dest}/*.json'))}; gates.tsv {before[1]}->{before[1] + len(g_new)} rows; subjects.json {before[2]}->{len(subs)}; "
          f"backups {tag}. Next: npm run source-store --prefix backend -- validate")
    return 0


if __name__ == '__main__':
    sys.exit(main())
