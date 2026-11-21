"""Reader session: build a DRY batch from a state's converted datasets, shaped like a real Stage 5 batch at step 7,
so the step 7 tools, the merge and the gate can be run on it before any real run. Writes nothing to the store or the
database. Shared by every state and every topic.

  python3 -I scripts/stage5/openstates/pilot_batch.py --pilot <pilot dir> --ds <datasets root> --state XX --topic <key>
      [--topics <topics.json of any finished batch of this topic>]

Reads, in <pilot dir>: `roster-<xx>-leg.tsv` (the scoped roster), `idmap.tsv`, `bills-<xx>.json` (scan_bills.py).
Writes `<pilot dir>/findings/<pid>.json` and `<pilot dir>/batch/{research.csv, evidence.csv, politicians.json}`, and
copies --topics to `batch/topics.json` (the gate reads it).

A finding is made for every roster legislator's Yes or No on a floor roll call of a scanned bill, and for every
sponsorship, with the fields the pre-fill writes. 🔴 Nothing here is a code. The value in research.csv is a
placeholder (3) and each row's reasoning starts "PILOT PLACEHOLDER": this folder is never a write batch.

The reasoning names every bill the person VOTED on, the way a coder names it ("HB 1219"). That is what lets the gate
be tested here: it must find each named bill in the lines the state's reader wrote. Then run, in order:
  state_legiscan.py pairs, legiscan-evidence-lines.ts, legiscan_merge.py <batch> --host <host>, stance-gate.ts --dir <batch>
  python3 -I scripts/stage5/openstates/pilot_batch.py --pilot <pilot dir> --verdict
--verdict reads what those wrote and exits 0 only when: no vote is unmapped, every cross-checked vote agrees, no pair
lacks a line, the gate finds every named bill in a cited line (`instrument-not-cited` 0), and no vote page is cited
without a line (`source-without-snippet` on a vote page 0). Exit 1 names each fault with its count and one example.
Exit 2, no verdict: a file is missing, or nothing was cross-checked. Other gate findings are about the placeholder.
Sponsorships (2026-11-21): a sponsorship left on the legislature's own bill page (legiscan/sponsor-own-page.json) is not
fetched in a dry batch, so run `npx tsx scripts/stage5/sponsor-page-check.ts <pilot dir>/batch` after `pairs`: it reads a
sample of those pages as the verifier will and writes legiscan/sponsor-page-check.json. --verdict gives NO VERDICT
without it (or when it is older than the list), and fails on a page that does not print the sponsor or the bill.
Nevada, Oregon and Hawaii each met that page at step 9 of a live run; their dry batches had listed 81, 428 and 1,266
such pages, and the verdict counted them and passed.

Why (2026-11-19): this was `make_pilot_batch.py`, copied by hand into seven states' pilot folders, and it stopped
after the lines. Colorado's first real run then met five format faults in the merge and the gate (the record says
Yes/No, not Yea/Nay; a sponsor page whose snippet prints no bill number; and others), each found by a replay of a
117-person batch. Run on Colorado's own dry batch, the merge as it was before the fix disagrees on 6,256 of 6,256 votes.
"""
import os, sys; sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))  # -I drops the script dir
from _args import opt
from _against import against_the_bill
import csv, glob, json, re, shutil
from _legiscan_people import Matcher, read_idmap, read_people, read_roster

USAGE = 'pilot_batch.py --pilot <dir> --ds <datasets root> --state XX --topic <key> [--topics <topics.json>] | --pilot <dir> --verdict'
P = opt('--pilot', required=True, usage=USAGE); VERDICT = '--verdict' in sys.argv
DS, ST, TOPIC = ((opt(f, required=not VERDICT, usage=USAGE) or '') for f in ('--ds', '--state', '--topic'))
ST = ST.upper(); xx = ST.lower(); TOPICS = opt('--topics')
PLACEHOLDER = 'PILOT PLACEHOLDER: not a code.'
CH = {'H': 'House', 'S': 'Senate'}


def bill_parts(num):
    """'HB1097' -> ('HB', '1097'); a number printed with its session year, 'SB17-006' or 'HB20B-1013' (Colorado), loses it."""
    m = re.match(r'([A-Z]+?)(?:\d{2}B?-)?0*(\d+)$', num)
    return (m.group(1), m.group(2)) if m else None


def main():
    roster = read_roster([f'{P}/roster-{xx}-leg.tsv'])
    roster = {k: r for k, r in roster.items() if re.search(r'senat|represent|delegate|assembl', r.get('office') or '', re.I)}
    if not roster: raise SystemExit(f'NO VERDICT: no legislator on {P}/roster-{xx}-leg.tsv (is the office column filled?)')
    M = Matcher(roster, read_idmap(f'{P}/idmap.tsv'), read_people(DS, ST))
    bills = json.load(open(f'{P}/bills-{xx}.json'))
    find, named, stats = {}, {}, {'floor roll calls': 0, 'vote findings': 0, 'sponsor findings': 0, 'voters not on roster': 0, 'bills not read': 0}
    for b in bills:
        parts = bill_parts(b['num'])
        if not parts or b['special'] or b['res']: stats['bills not read'] += 1; continue
        ins, name = f"{ST}-{parts[0]}-{parts[1]}-{b['y']}", f'{parts[0]} {parts[1]}'
        def add(pid, f):
            find.setdefault(pid, []).append(f)
            if f['act'] in ('yea', 'nay'): named.setdefault(pid, {})[name] = 1
        for sp in b['sponsors']:
            pid = M.match(sp['pid'])
            if pid:
                add(pid, {'kind': 'record', 'url': b['link'], 'date': '', 'instrument_id': ins, 'act': 'sponsor' if sp['t'] == 1 else 'cosponsor',
                          'note': f'{ST} sponsor list.', 'topic_keys': [TOPIC]}); stats['sponsor findings'] += 1
        for v in b['votes']:
            if re.match(r'\w+ Committee\b', v['desc']): continue  # a committee's vote; a conference report's final passage is a floor vote
            rc = json.load(open(glob.glob(os.path.join(DS, f"{ST}-{b['sid']}", '*', '*', 'vote', f"{v['id']}.json"))[0]))['roll_call']
            stats['floor roll calls'] += 1
            for x in rc['votes']:
                pid = M.match(x['people_id'])
                if not pid: stats['voters not on roster'] += 1; continue
                act = {1: 'yea', 2: 'nay'}.get(x['vote_id'])
                if not act: continue
                kill = against_the_bill(rc['desc'])  # a Yea to accept a Majority Ought Not to Pass report (_against.py)
                add(pid, {'kind': 'record', 'url': b['link'], 'date': rc['date'], 'date_precision': 'day', 'instrument_id': ins, 'act': act, 'motion': rc['desc'],
                          **({'against_bill': True} if kill else {}),
                          'note': f"{ST} {CH[rc['chamber']]}, {rc['desc']}, {rc['date']}: {act} (tally {rc['yea']}–{rc['nay']})." + (' A Yea on this motion is a vote against the bill.' if kill else ''), 'topic_keys': [TOPIC],
                          '_pilot': {'roll_call_id': rc['roll_call_id'], 'state_link': rc['state_link']}}); stats['vote findings'] += 1
    if not find: raise SystemExit('NO VERDICT: no roster legislator has a vote or a sponsorship on a scanned bill (check idmap.tsv and the bill scan)')
    os.makedirs(f'{P}/findings', exist_ok=True); os.makedirs(f'{P}/batch', exist_ok=True)
    rows, pol = [], []
    for pid, fs in sorted(find.items()):
        json.dump(fs, open(f'{P}/findings/{pid}.json', 'w'), indent=1)
        urls = list(dict.fromkeys(f['url'] for f in fs))
        name = roster[pid]['full_name']; pol.append({'full_name': name, 'politician_id': pid, 'level': 'state', 'race_id': None})
        rows.append({'full_name': name, 'topic_key': TOPIC, 'value': '3', 'reasoning': f"{PLACEHOLDER} Voted on: {'; '.join(named.get(pid) or ['no bill'])}.", 'evidence_type': 'record',
                     'blank_reason': '', **{f'source_url_{i + 1}': u for i, u in enumerate(urls)}})
    n = max(len([k for k in r if k.startswith('source_url_')]) for r in rows)
    cols = ['full_name', 'topic_key', 'value', 'reasoning', 'evidence_type', 'blank_reason'] + [f'source_url_{i + 1}' for i in range(n)]
    w = csv.DictWriter(open(f'{P}/batch/research.csv', 'w', newline=''), fieldnames=cols, restval=''); w.writeheader(); w.writerows(rows)
    csv.writer(open(f'{P}/batch/evidence.csv', 'w', newline='')).writerow(['full_name', 'topic_key', 'source_url', 'snippet', 'snippet_index'])
    json.dump(pol, open(f'{P}/batch/politicians.json', 'w'), indent=1)
    if TOPICS: shutil.copyfile(TOPICS, f'{P}/batch/topics.json')
    print('people with a finding', len(find), 'of', len(roster), 'roster legislators;', stats)


def verdict():
    """Read what the step 7 tools, the merge and the gate left in <pilot>/batch. See the header."""
    B = f'{P}/batch'; L = f'{B}/legiscan'
    need = [f'{L}/pairs.csv', f'{L}/unmapped.json', f'{L}/crosscheck.json', f'{L}/no-line.json', f'{B}/gate-findings.json']
    gone = [os.path.relpath(f, P) for f in need if not os.path.exists(f)]
    if gone: print('NO VERDICT: not run yet, missing', ', '.join(gone)); return 2
    votes = {r['source_url'] for r in csv.DictReader(open(need[0]))}
    unmapped, cross, noline = (json.load(open(f)) for f in need[1:4])
    g = json.load(open(need[4])); g = g if isinstance(g, list) else g.get('findings', [])
    if not cross: print('NO VERDICT: 0 votes were cross-checked, so the merge read nothing'); return 2
    if not any(PLACEHOLDER in (r.get('reasoning') or '') and 'Voted on:' in r['reasoning'] for r in csv.DictReader(open(f'{B}/research.csv'))):
        print('NO VERDICT: research.csv names no bill, so the gate had nothing to look for (build the batch with this script)'); return 2
    bad = [x for x in cross if x.get('agree') is not True]
    inc = [x for x in g if x['check_id'] == 'instrument-not-cited']
    sws = [x for x in g if x['check_id'] == 'source-without-snippet']
    on_vote = [x for x in sws if any(u in x['what'] for u in votes)]
    # sponsorships left on the legislature's own page: a sample of those pages must have been read (sponsor-page-check.ts)
    own_f, chk_f = f'{L}/sponsor-own-page.json', f'{L}/sponsor-page-check.json'
    own = json.load(open(own_f)) if os.path.exists(own_f) else []
    sp_faults, sp_note = [], 'no sponsorship is left on an official page'
    if own:
        if not os.path.exists(chk_f):
            print(f'NO VERDICT: {len(own)} sponsorship(s) are cited on the legislature\'s own page and none was read: run '
                  f'`npx tsx scripts/stage5/sponsor-page-check.ts {B}`'); return 2
        chk = json.load(open(chk_f))
        if chk.get('on_file') != len(own) or not chk.get('sampled'):
            print(f'NO VERDICT: sponsor-page-check.json was made for {chk.get("on_file")} sponsorship(s) and read {chk.get("sampled")} page(s); the list now holds {len(own)}. Run it again'); return 2
        sp_faults = chk.get('faults') or []
        sp_note = f"{len(own)} sponsorship(s) on an official page, {chk['sampled']} page(s) read, {chk.get('ok')} prove the sponsorship"
    faults = [('unmapped vote(s)', unmapped), ('cross-checked vote(s) that disagree with the finding', bad), ('pair(s) with no line', noline),
              ('named bill(s) the gate cannot find in a cited line (instrument-not-cited)', inc), ('vote page(s) cited with no line', on_vote),
              ('sampled sponsorship page(s) that do not print the sponsor or the bill, or cannot be read', sp_faults)]
    print(f'{len(votes)} vote page(s), {len(cross)} vote(s) cross-checked, {len(cross) - len(bad)} agree')
    for what, xs in faults:
        print(f"  {'ok ' if not xs else 'FAULT'} {len(xs)} {what}" + (f': e.g. {json.dumps(xs[0], ensure_ascii=False)[:260]}' if xs else ''))
    print(f'  sponsorships: {sp_note}.' + (' A fault is the runner\'s question HERE: which page proves a sponsorship in this state, or hold them.' if sp_faults else ''))
    return 1 if any(xs for _, xs in faults) else 0


if __name__ == '__main__':
    sys.exit(verdict()) if VERDICT else main()
