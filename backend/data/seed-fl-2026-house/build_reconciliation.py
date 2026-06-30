#!/usr/bin/env python3
"""151-03 reconciliation builder. Reads 148 FL field + incumbent map + live race_ids,
decides REUSE vs NEW per candidate, assigns external_ids. Writes 151-03-fl-reconciliation.csv."""
import csv, re, unicodedata, sys

FIELD = '../../../.planning/phases/148-field-resolution-stance-gap-diagnostic/148-field-table.csv'
RACEIDS = 'fl_race_ids.txt'
OUT = '151-03-fl-reconciliation.csv'

def norm(s):
    s = unicodedata.normalize('NFKD', s).encode('ascii','ignore').decode('ascii')
    return re.sub(r'[^a-z0-9 ]','', s.lower()).strip()

def lastname(s):
    toks = norm(s).split()
    return toks[-1] if toks else ''

# cross-district reuse: name -> (pid, external_id, new_geo)
CROSS = {
    'lois frankel':       ('b4040115-b3ea-4500-89cf-1ddaecafc94e', -12022, '1223'),
    'jared moskowitz':    ('1cb8827c-6ae0-4fcf-884c-94ad2246f15d', -12023, '1225'),
    'debbie wasserman schultz': ('097623b0-3063-4943-a13c-89d213ca5829', -12025, '1220'),
}

race_id = {}
for line in open(RACEIDS, encoding='utf-8'):
    line=line.strip()
    if '|' in line:
        g,rid = line.split('|'); race_id[g]=rid

rows = [r for r in csv.DictReader(open(FIELD, encoding='utf-8')) if r['state']=='FL']

def parse_field(s):
    out=[]
    for c in s.split(';'):
        c=c.strip()
        m=re.match(r'^(.*?)\s*\(([^)]+)\)\s*$', c)
        if m: out.append((m.group(1).strip(), m.group(2).strip()))
        elif c: out.append((c,'?'))
    return out

out_rows=[]
new_names=[]   # (full_name, geo) for live dedup check
for r in rows:
    cd=int(r['cd']); geo=r['geo_id']; rid=race_id[geo]
    status=r['nominee_status']; inc_pid=r['incumbent_pid']; inc_name=r['incumbent_name']
    inc_last = lastname(inc_name) if inc_pid else None
    renominated = (status=='incumbent-renominated')
    field = parse_field(r['general_candidates'])
    seq=0
    inc_matched=False
    for name,party in field:
        nn=norm(name)
        # cross-district reuse?
        if nn in CROSS and CROSS[nn][2]==geo:
            pid,ext,_=CROSS[nn]
            out_rows.append([cd,geo,rid,name,party,'REUSE',pid,ext,'false',r['source_url']])
            continue
        # home renominated incumbent? (last-name match, only once)
        if renominated and not inc_matched and inc_last and lastname(name)==inc_last:
            out_rows.append([cd,geo,rid,name,party,'REUSE',inc_pid,r['incumbent_external_id'],'true',r['source_url']])
            inc_matched=True
            continue
        # NEW
        seq+=1
        ext = -(1210000 + cd*100 + seq)
        out_rows.append([cd,geo,rid,name,party,'NEW','',ext,'false',r['source_url']])
        new_names.append((name,geo))
    if renominated and not inc_matched:
        print(f"WARN FL-{cd}: renominated incumbent '{inc_name}' NOT found in field by last-name match", file=sys.stderr)

with open(OUT,'w',newline='',encoding='utf-8') as f:
    w=csv.writer(f)
    w.writerow(['cd','geo_id','race_id','full_name','party_from_field','decision','target_politician_id','assign_external_id','is_incumbent','source_url'])
    w.writerows(out_rows)

# emit NEW names for live dedup batch check
with open('fl_new_names.txt','w',encoding='utf-8') as f:
    for n,g in new_names:
        f.write(f"{n}\t{g}\n")

reuse=[r for r in out_rows if r[5]=='REUSE']
new=[r for r in out_rows if r[5]=='NEW']
cross=[r for r in reuse if r[6] in (c[0] for c in CROSS.values())]
inc_reuse=[r for r in reuse if r[8]=='true']
print(f"total rows: {len(out_rows)}  REUSE: {len(reuse)} (home-incumbent {len(inc_reuse)}, cross-district {len(cross)})  NEW: {len(new)}")
print(f"distinct NEW external_ids: {len(set(r[7] for r in new))} (should equal {len(new)})")
# Cherfilus check
cherf=[r for r in out_rows if 'cherfilus' in norm(r[3])]
print("Cherfilus rows:", [(r[3],r[5]) for r in cherf])
