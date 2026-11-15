"""LegiScan datasets already on disk are the default source for the vote tools; the live API is the exception.

Why: Tennessee, Kentucky and South Carolina (2026-11-14) each ran step 7 against the live API, hit the monthly cap,
stopped, and asked the runner the same question. The datasets were on disk each time. src/lib/legiscan/client.ts reads
them when LEGISCAN_DATASETS is set, and nothing set it.

onfile_env(stage5 dir, state): {} when the caller already chose (LEGISCAN_DATASETS is set), when the runner allowed
the live API for this run (LEGISCAN_LIVE=1), or when <stage5>/legiscan/ds holds no folder for the state; else the two
variables to set. A dataset is a snapshot: newest_roll_call() gives the date of its last roll call, and a vote after
that date is not in it."""
import glob, json, os


def onfile_env(stage5, state, env=os.environ):
    if env.get('LEGISCAN_DATASETS') or env.get('LEGISCAN_LIVE') == '1' or not state: return {}
    root = os.path.join(stage5, 'legiscan', 'ds')
    if not glob.glob(os.path.join(root, f'{state.upper()}-*')): return {}
    return {'LEGISCAN_DATASETS': root, 'LEGISCAN_DATASET_STATES': state.upper()}


def newest_roll_call(root, state):
    """(date of the newest roll call on disk, number of sessions on disk); (None, n) when no session holds a roll call.
    Read from the newest year whose sessions hold any roll call: a session just opened has bills and no votes yet
    (Florida, 2026-11-15: the 2027 session's first bills made step 7 print "newest roll call none")."""
    sess = []
    for d in glob.glob(os.path.join(root, f'{state.upper()}-*', '*', '*')):
        bills = sorted(glob.glob(os.path.join(d, 'bill', '*.json')))
        if bills:
            s = json.load(open(bills[0]))['bill']['session']
            sess.append((int(s.get('year_end') or s.get('year_start') or 0), d))
    if not sess: return None, 0
    for top in sorted({y for y, _ in sess}, reverse=True):
        newest = ''
        for _, d in (x for x in sess if x[0] == top):
            for f in glob.glob(os.path.join(d, 'vote', '*.json')):
                newest = max(newest, json.load(open(f))['roll_call'].get('date') or '')
        if newest: return newest, len(sess)
    return None, len(sess)
