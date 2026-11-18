"""Maryland: every vote address the Open States dump holds for the listed bills of one session, in the form the reader
reads (https://mgaleg.maryland.gov/<year>RS/votes/<house|senate>/<NNNN>.pdf#<BILL>; 2017: .htm; a veto overridden in
the next session: #<bill's year>-<BILL>), as JSON for fetch-legislature-rollcalls.ts --also.

Why: the bill's own page leaves some floor votes out (2022 SB 861: the Senate's third reading after the House amended
it, vote 1377, is in the dump and not on the page). The fetch reads each address the page does not link with the same
reader, which keeps it only if the vote file itself says it is a vote on this bill; a motion is counted, not read.
The dump's own labels and counts are not used: only the address.

  python3 -I scripts/stage5/openstates/md_dump_votes.py <extract dir> <session> --bills-file <bills.txt> > also.json
"""
import collections, csv, json, os, re, sys
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))  # -I drops the script dir
from _args import opt, positional

USAGE = 'md_dump_votes.py <extract dir> <session> --bills-file <bills.txt>'
X, SESSION = positional(2, USAGE)
want = {re.sub(r'[\s.]+', '', b).upper() for b in open(opt('--bills-file', required=True, usage=USAGE)) if b.strip()}
csv.field_size_limit(10 ** 9)
rows = lambda t: csv.DictReader(open(os.path.join(X, f'{t}.tsv')), delimiter='\t', quoting=csv.QUOTE_NONE)
sess = {r['id']: r['identifier'] for r in rows('legislativesession')}
if SESSION not in sess.values() or not re.fullmatch(r'20\d{2}', SESSION):
    raise SystemExit(f'{SESSION} is not a regular session of this extract')
bills = {r['id']: re.sub(r'[\s.]+', '', r['identifier']).upper() for r in rows('bill') if sess[r['legislative_session_id']] == SESSION}
# the same two forms convert.py rewrites (md_vote_page)
VOTE = re.compile(r'^https?://mgaleg\.maryland\.gov/(20\d{2})RS/votes/(house|senate)/(\d{4})\.pdf$', re.I)
OLD = re.compile(r'^https?://mgaleg\.maryland\.gov/webmga/frmMain\.aspx\?pid=flrvotepage&tab=subject\d+&id=([hs][bj])0*(\d+),([hs])-(\d{4})&stab=\d+&ys=(20\d{2})RS$', re.I)
src = collections.defaultdict(list)
for r in rows('votesource'):
    src[r['vote_event_id']].append(r['url'])
out = collections.defaultdict(set)
skipped = 0
for r in rows('voteevent'):
    code = bills.get(r['bill_id'])
    if code not in want:
        continue
    for u in src[r['id']]:
        m, o = VOTE.match(u), OLD.match(u)
        if o and f'{o.group(1).upper()}{int(o.group(2))}' != code:
            o = None  # an old page names its bill: it must be this one
        year, ch, no = (m.group(1), m.group(2).lower(), m.group(3)) if m else (o.group(5), 'house' if o.group(3).lower() == 'h' else 'senate', o.group(4)) if o else (None,) * 3
        if year not in (SESSION, str(int(SESSION) + 1)):
            skipped += 1
            continue
        tag = f'{SESSION}-{code}' if year != SESSION else code
        out[code].add(f"https://mgaleg.maryland.gov/{year}RS/votes/{ch}/{no}.{'htm' if year == '2017' else 'pdf'}#{tag}")
json.dump({b: sorted(us) for b, us in sorted(out.items())}, sys.stdout, indent=1)
print(f'{sum(map(len, out.values()))} addresses on {len(out)} bills; {skipped} addresses of another form or session left out', file=sys.stderr)
