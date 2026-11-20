"""Every sitting legislator on the roster must be linked to a LegiScan person before the votes are read.

  python3 -I scripts/stage5/link_check.py --state XX --roster <scoped roster.tsv> --ds <legiscan ds root> --idmap <idmap.tsv>
      [--add] [--no-record <tsv>] [--offices <regex>]

Why: a vote reaches a person only through `idmap.tsv` (or a state script's own name rule). A legislator with no line
there has NO votes on file, and nothing errors: the person is coded from a thin record or as "no record". Kentucky,
2026-11-14: six sitting members had no line (a former surname, "Casey" for "Cassie", middle names). Two were written
as blanks when a vote and a sponsorship on file would have seated them, and one was held.

What it does. A legislator is a roster row whose `office` matches --offices and whose `scope` is not `candidate`.
Each must have an idmap line that points at a LegiScan person of this state's datasets.
  - A unique name match (the shared rule: first three letters of the first name or nickname + the whole last name)
    is printed with the LegiScan role and district. `--add` appends those lines to idmap.tsv; check each one on name
    and chamber. Without `--add` they still count as unlinked: a state's skeleton script may not use the same rule.
  - Anyone left is printed with the unlinked LegiScan people who share a name word, and the newest session's
    unlinked LegiScan people are listed, so the pair can be made by hand.
  - A member who truly has no LegiScan record (seated after the newest dataset) goes in --no-record:
    `<politician_id>\t<reason>` per line. The reason is required.
  - `--from-db` reads the member ids we hold (essentials.legislative_politician_id_map, via
    scripts/member-ids/export-member-ids.ts, saved as member-ids.tsv beside idmap.tsv; `--member-ids <tsv>` reads a
    saved export instead). A dataset person converted from Open States is paired by its Open States id, which
    sync-member-ids.ts matched to the seat: no name involved. A LegiScan id from the database is paired too, marked
    with how it was matched. `--add` writes these lines first. An idmap line that disagrees with the database is a
    CONFLICT: printed, never changed, and the exit is 1.
Exit 0: every legislator is linked or excused. Exit 1: someone is not, or a CONFLICT. Exit 2: usage, or the check was blind (no
legislators matched --offices, or no LegiScan people were read): it gives no verdict then.
"""
import os, sys; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))  # -I drops the script dir
from _args import opt
from _legiscan_people import Matcher, norm, read_idmap, read_roster, SUFFIX
import csv, glob, json, re, subprocess

USAGE = ('link_check.py --state XX --roster <tsv> --ds <ds root> --idmap <idmap.tsv> [--add] [--from-db | --member-ids <tsv>] '
         '[--no-record <tsv>] [--offices <regex>]')
ST = opt('--state', required=True, usage=USAGE).upper()
IDMAP = opt('--idmap', required=True, usage=USAGE)
ROSTER = opt('--roster', required=True, usage=USAGE)
OFFICES = re.compile(opt('--offices', r'senat|represent|assembl|delegate|legislat'), re.I)
ADD = '--add' in sys.argv
FROM_DB = '--from-db' in sys.argv
TRUSTED = {'seat', 'id_crosswalk', 'manual'}


def blind(msg):
    print(f'link check: NO VERDICT. {msg}'); sys.exit(2)


roster = read_roster([ROSTER])
legs = {pid: r for pid, r in roster.items() if OFFICES.search(r.get('office') or '') and (r.get('scope') or 'sitting') != 'candidate'}
if not legs: blind(f'no roster row has an office matching /{OFFICES.pattern}/ (is the office column filled? pass --offices)')

# LegiScan people, and the newest session each was seen in (a dataset folder holds one session).
people, seen, newest = {}, {}, 0
for d in glob.glob(os.path.join(opt('--ds', required=True, usage=USAGE), f'{ST}-*')):
    bills = glob.glob(os.path.join(d, '*', '*', 'bill', '*.json'))
    year = json.load(open(bills[0]))['bill']['session'].get('year_end', 0) if bills else 0
    newest = max(newest, year)
    for f in glob.glob(os.path.join(d, '*', '*', 'people', '*.json')):
        p = json.load(open(f))['person']
        people[p['people_id']] = p; seen[p['people_id']] = max(seen.get(p['people_id'], 0), year)
if not people: blind(f'no LegiScan people found for {ST} under --ds')

idmap = read_idmap(IDMAP)

# Member ids from the database (CA_0401/CA_0402): an Open States person id matched to the seat, or a LegiScan id.
# A dataset person converted from Open States carries `_openstates.person_id`, so the pair is made by id, not by
# name. LegiScan ids in the database were mostly matched by name (match_method 'name'): check those like a name match.
db_lines, db_conflicts = [], []
MEMBER_IDS = opt('--member-ids')
if FROM_DB or MEMBER_IDS:
    if FROM_DB:
        MEMBER_IDS = MEMBER_IDS or os.path.join(os.path.dirname(os.path.abspath(IDMAP)), 'member-ids.tsv')
        backend = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        run = subprocess.run(['npx', 'tsx', 'scripts/member-ids/export-member-ids.ts', '--roster', os.path.abspath(ROSTER),
                              '--out', os.path.abspath(MEMBER_IDS)], cwd=backend, capture_output=True, text=True)
        if run.returncode: blind(f'--from-db: export-member-ids failed: {(run.stderr or run.stdout).strip()[-300:]}')
        print(run.stdout.strip())
    by_os, by_ls = {}, {}
    for row in csv.DictReader(open(MEMBER_IDS), delimiter='\t'):
        if row['id_type'] == 'openstates' and row['match_method'] in TRUSTED: by_os[row['id_value']] = row['politician_id']
        elif row['id_type'] == 'legiscan': by_ls[row['id_value']] = (row['politician_id'], row['match_method'])
    for ls, p in sorted(people.items()):
        osid = (p.get('_openstates') or {}).get('person_id')
        if osid in by_os: pid, how = by_os[osid], 'by Open States id'
        elif str(ls) in by_ls: pid, how = by_ls[str(ls)][0], f"by LegiScan id ({by_ls[str(ls)][1]} match: check it)"
        else: continue
        if pid not in legs: continue
        if ls in idmap:
            if idmap[ls] != pid: db_conflicts.append((ls, pid, how))
            continue
        db_lines.append((ls, pid, how))

linked = {pid for ls, pid in idmap.items() if ls in people}
excused = {}
if opt('--no-record'):
    for line in open(opt('--no-record')):
        parts = line.rstrip('\n').split('\t')
        if not parts[0].strip() or parts[0].startswith('#'): continue
        if len(parts) < 2 or not parts[1].strip(): blind(f'--no-record line for {parts[0]} gives no reason')
        excused[parts[0].strip()] = parts[1].strip()

if db_lines:
    if ADD:
        with open(IDMAP, 'a') as fh:
            for ls, pid, how in db_lines: fh.write(f"{ls}\t{pid}\t# {people[ls].get('name')} (link_check database id, {how})\n")
        for ls, pid, how in db_lines: idmap[ls] = pid; linked.add(pid)
        print(f'added {len(db_lines)} line(s) from database ids to {IDMAP}:')
    else:
        print(f'{len(db_lines)} database id(s) not yet in idmap (run with --add to write them):')
    for ls, pid, how in db_lines: print(f"  {legs[pid]['full_name']}  <-  {ls}\t{people[ls].get('name')}\t{how}")
for ls, pid, how in db_conflicts:
    print(f"CONFLICT: idmap has {ls} ({people[ls].get('name')}) -> {idmap[ls]}, but the database says -> {pid} "
          f"({legs[pid]['full_name']}, {how}). Fix the wrong one; nothing was changed.")

m = Matcher(legs, idmap, people)
# The shared rule keys on LegiScan's last_name field, which holds "Mays Bledsoe" for Amanda Mays Bledsoe: a whole
# name that is letter-for-letter the roster's, and the only one, is a name match too.
whole = {}
for pid, r in legs.items(): whole.setdefault(norm(r['full_name']), []).append(pid)
whole = {k: v[0] for k, v in whole.items() if len(v) == 1}
by_name = {}
for ls in sorted(people):
    if ls in idmap: continue
    pid = m.match(ls) or whole.get(norm(people[ls].get('name')))
    if pid and pid not in linked: by_name.setdefault(pid, []).append(ls)

# A record the converter made for a voter it could not tie to a dump person (Oregon 2026-11-20: the record prints "Emerson
# Levy", the dump "Em Levy") holds that member's votes under a new id each session. It has no Open States id, and the
# member is already linked by another record, so the name rule above skips it and nothing is reported. Link a name-only
# record whose whole name is one roster member's, and say so.
made = [(ls, whole[norm(people[ls].get('name'))]) for ls in sorted(people)
        if ls not in idmap and (people[ls].get('_openstates') or {}).get('name_only') and whole.get(norm(people[ls].get('name'))) in linked]
if made:
    if ADD:
        with open(IDMAP, 'a') as fh:
            for ls, pid in made: fh.write(f"{ls}\t{pid}\t# {people[ls].get('name')} (link_check name-only record of a linked member)\n")
        for ls, pid in made: idmap[ls] = pid
    print(f"{'added' if ADD else 'not yet in idmap (run with --add):'} {len(made)} name-only record(s) the converter made for a linked member's votes:")
    for ls, pid in made: print(f"  {legs[pid]['full_name']}  <-  {ls}\t{people[ls].get('name')}")

# Maine 2026-11-20: the House record prints a member as "Bridgeo, W.R." or "Ray, D.M." (family name, then initials), and
# the converter keeps that label as a name-only record when the dump gives another given name ("Bill Bridgeo"). The
# whole-name rule above cannot see it. A name-only label of that shape links to the one roster member of that chamber
# whose family name is the label's and whose first given name starts with the label's first initial; one that fits
# two members, or none, is left for the report below.
LABEL = re.compile(r"^([^,]+), ((?:[A-Za-z]\. ?)*[A-Za-z]\.?)$")
def family_of(full):
    w = [x for x in re.sub(r'[",]', ' ', full).split() if norm(x) not in SUFFIX]
    return w
def label_fits(lab, full):
    m = LABEL.match(lab or '')
    if not m: return False
    w = family_of(full); fam = norm(m.group(1)); first = norm(m.group(2))[:1]
    for k in range(1, len(w)):
        if norm(''.join(w[k:])) == fam: return bool(first) and norm(w[0])[:1] == first
    return False
CHAMBER = {'Rep': 'representative', 'Sen': 'senator'}
labelled = []
for ls in sorted(people):
    pr = people[ls]
    if ls in idmap or not (pr.get('_openstates') or {}).get('name_only') or not LABEL.match(pr.get('name') or ''): continue
    office = CHAMBER.get(pr.get('role'))
    fits = [pid for pid, r in legs.items() if (not office or office in norm(r.get('office')))
            and label_fits(pr.get('name'), r['full_name'])]
    if len(fits) == 1: labelled.append((ls, fits[0]))
if labelled:
    if ADD:
        with open(IDMAP, 'a') as fh:
            for ls, pid in labelled: fh.write(f"{ls}\t{pid}\t# {people[ls].get('name')} (link_check record label: family name and initial)\n")
        for ls, pid in labelled: idmap[ls] = pid; linked.add(pid)
    print(f"{'added' if ADD else 'not yet in idmap (run with --add):'} {len(labelled)} record label(s) of the form \"Family, I.\" fitting one member:")
    for ls, pid in labelled: print(f"  {legs[pid]['full_name']}  <-  {ls}\t{people[ls].get('name')}")


def who(ls):
    p = people[ls]
    return f"{ls}\t{p.get('name')}\t{p.get('role') or '?'} {p.get('district') or '?'}\tlast seen {seen.get(ls) or '?'}"


added = []
for pid, lss in sorted(by_name.items(), key=lambda kv: legs[kv[0]]['full_name']):
    if len(lss) == 1 and ADD: added.append((lss[0], pid)); linked.add(pid)
if added:
    with open(IDMAP, 'a') as fh:
        for ls, pid in added: fh.write(f"{ls}\t{pid}\t# {people[ls].get('name')} (link_check name match)\n")
    print(f'added {len(added)} line(s) to {IDMAP}; check each on name and chamber:')
    for ls, pid in added: print(f"  {legs[pid]['full_name']} ({legs[pid].get('office')})  <-  {who(ls)}")

free = [ls for ls in people if ls not in idmap and ls not in {a for a, _ in added}]
missing = [pid for pid in legs if pid not in linked and pid not in excused]
print(f'link check {ST}: {len(legs)} legislator(s) on the roster, {len(legs) - len(missing) - len([p for p in excused if p in legs and p not in linked])} linked, '
      f'{len([p for p in excused if p in legs and p not in linked])} excused, {len(missing)} NOT linked; {len(people)} LegiScan people read')
for pid, why in excused.items():
    if pid in legs and pid not in linked: print(f"  excused: {legs[pid]['full_name']}: {why}")
if not missing: sys.exit(1 if db_conflicts else 0)

print('NOT linked: these people have no votes or sponsorships on file until idmap.tsv has their line.')
for pid in sorted(missing, key=lambda p: legs[p]['full_name']):
    r = legs[pid]; print(f"- {r['full_name']} ({r.get('office')})  {pid}")
    if pid in by_name:
        for ls in by_name[pid]: print(f'    name match, not yet in idmap (run with --add, then check it): {who(ls)}')
        continue
    words = {norm(w) for w in re.sub(r'[",.]', ' ', r['full_name']).split() if len(norm(w)) >= 3 and norm(w) not in SUFFIX}
    near = [ls for ls in free if words & {norm(w) for w in (people[ls].get('name') or '').split()}]
    for ls in sorted(near, key=lambda x: -seen.get(x, 0))[:6]: print(f'    shares a name word: {who(ls)}')
    for ls in sorted(ls for ls in people if ls in idmap and idmap[ls] != pid and words >= {norm(w) for w in (people[ls].get('name') or '').split() if len(norm(w)) >= 3}):
        print(f'    already linked to ANOTHER id {idmap[ls]} (a duplicate person row, or a wrong line?): {who(ls)}')
    if not near: print('    no unlinked LegiScan person shares a name word (a changed surname? see the list below)')
left = sorted((ls for ls in free if seen.get(ls) == newest), key=lambda x: people[x].get('name') or '')
print(f'Unlinked LegiScan people of the newest session ({newest}), {len(left)}: one of them may be a person above under another name.')
for ls in left[:60]: print(f'    {who(ls)}')
print(f'Fix: add `<legiscan people_id>\\t<politician_id>` to {IDMAP} (check name and chamber), or list a member with no LegiScan record in --no-record with a reason.')
sys.exit(1)
