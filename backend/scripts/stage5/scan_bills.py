"""Scan a state's LegiScan dataset folders for a topic's bills: the input to sponsor_cover.py and the core-bill pick.

usage: python3 -I scripts/stage5/scan_bills.py <ds_root> <XX,YY> <out.json> --topic gun-policy

<ds_root> holds the LegiScan datasets as unzipped (<ST>-<session id>/<...>/bill/*.json). A bill is kept when its
title, description or subjects match the topic's keywords and none of its exclusions (unless it also names a keep
word). One dict per bill: bill_id, st, sid, sess, y, special, num, title, desc, subjects, link, lsurl, status,
sponsors[{pid, name, t, role, district}], res (a resolution), votes[{id, date, desc, yea, nay, chamber, passed}].
Moved from the gun-policy research folder (scan_gun.py, 2026-11); add a topic by adding its three patterns.
"""
import json, re, sys, glob, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt, positional
TOPICS = {}
TOPICS["gun-policy"] = (re.compile(r"\b(fire ?arms?|hand ?guns?|guns?|rifles?|shotguns?|pistols?|revolvers?|ammunition|weapons?|"
                 r"concealed carry|license to carry|carry permit|red flag|extreme risk|silencers?|suppressors?|"
                 r"bump stocks?|machine ?guns?|second amendment|2nd amendment|gun show|gunsmith|"
                 r"assault weapon|large.capacity|magazines?|shooting ranges?|castle doctrine|self.defense|gun violence)\b", re.I),
    re.compile(r"chemical weapons?|weapons? of mass destruction|offensive weapons?|nuclear weapons?|"
                 r"awareness (day|week|month)|gun violence survivors week", re.I),
    r"fire ?arm|hand ?gun|ammunition")
RES = re.compile(r"^(H|S|A)?(R|JR|CR|J|C|M|JM|CM|SR|HR)\d|R\d", re.I)
def resolution(b):
    return b.get('bill_type') not in ('B',)
USAGE = 'scan_bills.py <ds_root> <XX,YY> <out.json> --topic gun-policy'
root, states, out = positional(3, USAGE)[:3]; states = states.split(',')
topic = opt('--topic', required=True, usage=USAGE)
if topic not in TOPICS: raise SystemExit(f'no keyword list for {topic}: add one to TOPICS ({sorted(TOPICS)})')
POS, NEG, KEEP = TOPICS[topic]
hits = []
for st in states:
    for d in sorted(glob.glob(os.path.join(root, f"{st}-*"))):
        sid = int(d.rsplit('-', 1)[1])
        for f in glob.glob(os.path.join(d, '*', '*', 'bill', '*.json')):
            b = json.load(open(f))['bill']
            subj = ' '.join(s['subject_name'] for s in b.get('subjects', []))
            text = f"{b['title']} {b['description']} {subj}"
            if not POS.search(text): continue
            res = resolution(b)
            if NEG.search(text) and not re.search(KEEP, text, re.I): continue
            s = b['session']
            hits.append(dict(st=st, sid=sid, sess=s['session_name'], y=s['year_start'], special=s['special'],
                num=b['bill_number'], title=b['title'], desc=b['description'], subjects=subj,
                link=b['state_link'], lsurl=b['url'], bill_id=b['bill_id'], status=b['status'],
                sponsors=[dict(pid=p['people_id'], name=p['name'], t=p['sponsor_type_id'], role=p['role'],
                               district=p['district']) for p in b['sponsors']], res=res,
                votes=[dict(id=v['roll_call_id'], date=v['date'], desc=v['desc'], yea=v['yea'], nay=v['nay'],
                            chamber=v['chamber'], passed=v['passed']) for v in b['votes']]))
json.dump(hits, open(out, 'w'))
print(len(hits))
