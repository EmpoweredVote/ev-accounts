"""Set-up: the Sonnet wave that reads each core bill's text (the "fill"). Shared by every state.

  python3 -I scripts/stage5/bill_fill_wave.py --stage5 <stage5 dir> --state xx [--wave <name>] [--size 10]

Batches of --size ids that have a saved text (`legiscan/texts/<id>.*.txt`) and no fill yet (`legiscan/fill/<id>.json`),
one job per batch, from the brief `legiscan/FILL-BRIEF-<xx>.md`. The brief's @LARGE@ slot gets the ids whose text is
over 30,000 characters. Writes `<stage5>/waves/<wave>/` (default wave `<xx>-fill`): batch-NN.txt, w-NN.md, jobs.tsv.
Run it again after a wave to build the next one from what is still unfilled (give it a new --wave name).
Exit 2 when the brief is missing or the wave folder already holds a jobs.tsv.
"""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt
import glob

USAGE = 'bill_fill_wave.py --stage5 <dir> --state xx [--wave <name>] [--size 10]'
S, xx = opt('--stage5', required=True, usage=USAGE), opt('--state', required=True, usage=USAGE).lower()
L = os.path.join(S, 'legiscan'); W = os.path.join(S, 'waves', opt('--wave', f'{xx}-fill')); N = int(opt('--size', '10'))
bf = f'{L}/FILL-BRIEF-{xx}.md'
if not os.path.exists(bf): print(f'fill wave: {bf} is missing'); sys.exit(2)
if os.path.exists(f'{W}/jobs.tsv'): print(f'fill wave: {W}/jobs.tsv exists. Name a new wave with --wave.'); sys.exit(2)
os.makedirs(W, exist_ok=True)
ids, large = [], []
for f in sorted(glob.glob(f'{L}/inst-{xx}/*.json')):
    i = os.path.basename(f)[:-5]; t = glob.glob(f'{L}/texts/{i}.*.txt')
    if not t or os.path.exists(f'{L}/fill/{i}.json'): continue
    ids.append(i)
    if len(open(t[0]).read()) > 30000: large.append(i)
brief = open(bf).read().replace('@LARGE@', ', '.join(large) or 'none')
rows = ['name\tprompt_file\tmodel\ttools']
for k in range(0, len(ids), N):
    n = k // N; b = f'{W}/batch-{n:02d}.txt'; open(b, 'w').write('\n'.join(ids[k:k + N]) + '\n')
    p = f'{W}/w-{n:02d}.md'; open(p, 'w').write(brief + f'\nYour batch file: `{b}` ({len(ids[k:k + N])} ids).\n')
    rows.append(f'fill-{xx}-{n:02d}\t{p}\tsonnet\tRead,Write,Bash')
open(W + '/jobs.tsv', 'w').write('\n'.join(rows) + '\n')
print('ids', len(ids), 'large', len(large), 'jobs', len(rows) - 1)
