import csv, io, sys, collections
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

FILES = ['csv-220802.csv','csv-221108.csv','csv-240806.csv','csv-241105.csv','csv-260804.csv']

def load(f):
    """contest -> {choice: (votes, party)}"""
    agg = collections.defaultdict(lambda: collections.defaultdict(int))
    party = {}
    with open(f, newline='', encoding='utf-8-sig', errors='replace') as fh:
        for row in csv.DictReader(fh):
            c = (row.get('Contest Title') or '').strip()
            ch = (row.get('Choice Name') or '').strip()
            if not c or not ch: continue
            try: v = int(row.get('Total Votes') or 0)
            except ValueError: v = 0
            agg[c][ch] += v
            party[(c,ch)] = (row.get('Choice Party') or '').strip()
    return agg, party

COUNTY_RE = ('COUNTY EXECUTIVE','PROSECUTING ATTORNEY','COUNTY ASSESSOR','COUNTY COUNCIL',
             'COUNTY AUDITOR','COUNTY CLERK','COLLECTOR OF REVENUE','RECORDER OF DEEDS',
             'SHERIFF','CORONER','TREASURER','PUBLIC ADMINISTRATOR','CIRCUIT CLERK',
             'CLERK OF THE CIRCUIT','SURVEYOR','COUNTY COUNSELOR')

for f in FILES:
    agg, party = load(f)
    print('='*70); print(f)
    hits = [c for c in agg if any(k in c.upper() for k in COUNTY_RE)]
    for c in sorted(hits):
        rows = sorted(agg[c].items(), key=lambda kv: -kv[1])
        tot = sum(v for _, v in rows) or 1
        print(f'\n  {c}')
        for ch, v in rows[:6]:
            print(f'      {v:>8,}  {100*v/tot:5.2f}%  {ch}  [{party.get((c,ch),"")}]')
