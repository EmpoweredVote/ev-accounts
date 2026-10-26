"""Build build_batch.py specs for the voting-rights Season 3 (draft) Opus-alone run, 2026-10-22.

One batch per person: the 65 people in the Stage 3 test set who hold an affirmative record (a Yea or a sponsorship),
plus Terry Wilson from the Stage 4 carry list (ruled 2026-10-21, Chris Andrews). Sources = each in-set record's
instrument text plus the page that shows the person's own vote or sponsorship. A person's Nay records in the set are
included too, so the coder sees everything the test set holds for them. Run from backend/:

    python3 data/stance-research/voting-rights-s3-2026-10-22/make_spec.py <out.json> [name ...]

With names, only those batches are written (e.g. the dry run).
"""
import csv, glob, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
PREP = os.path.expanduser('~/Documents/GitHub/.planning/research/s3-prep-voting-rights')
TEST_SET = os.path.join(PREP, 'stage1/test-set-final.tsv')
CARRY = os.path.join(PREP, 'stage4/reaudit/carry.json')
OFFICES = os.path.join(HERE, 'offices.tsv')  # politician_id, name, office_id, title, district_type, state, is_incumbent
STORE = os.path.join(HERE, '..', '..', 'source-store', 'instruments')

# Instrument -> (label, text sources: the version the final votes were cast on).
INSTR = {
  'KY-SB-2-2020': ('Kentucky SB 2 (2020 RS), voter identification, as enacted over veto',
    ['https://apps.legislature.ky.gov/recorddocuments/bill/20RS/sb2/bill.pdf']),
  'KY-SB-2-2020|HFA42': ('Kentucky House Floor Amendment 42 to SB 2/HCS 1 (2020 RS)',
    ['https://apps.legislature.ky.gov/recorddocuments/bill/20RS/SB2/HFA42.pdf']),
  'MA-H-4359-AMDT-7-2022': ('Massachusetts House amendment #7 to H.4359 (2022), voter identification',
    ['https://malegislature.gov/Bills/GetAmendmentContent/192/H4359/7/House/Content']),
  'MI-SB-303-2021': ('Michigan SB 303 (2021), voter identification, as passed',
    ['https://www.legislature.mi.gov/documents/2021-2022/billenrolled/Senate/htm/2021-SNB-0303.htm']),
  'NC-S-824-2018': ('North Carolina S 824 (2017 Session, 2018), Implementation of Voter ID Const. Amendment, ratified',
    ['https://www.ncleg.gov/Sessions/2017/Bills/Senate/PDF/S824v7.pdf']),
  'SC-H-3003-2011': ('South Carolina H 3003 (2011), photo identification for voting, ratified',
    ['https://www.scstatehouse.gov/sess119_2011-2012/bills/3003.htm']),
  'TX-SB-1-2021': ('Texas S.B. 1 (87th Leg., 2nd C.S., 2021), Election Integrity Protection Act of 2021, enrolled',
    ['https://capitol.texas.gov/tlodocs/872/billtext/html/SB00001F.htm']),
  'TX-SB-14-2011': ('Texas S.B. 14 (82nd Leg., 2011), photo identification for voting, enrolled',
    ['https://capitol.texas.gov/tlodocs/82R/billtext/html/SB00014F.htm']),
  'TX-SB-16-2025': ('Texas S.B. 16 (89th Leg., 2025), proof of citizenship for voter registration, as passed by the Senate',
    ['https://capitol.texas.gov/tlodocs/89R/billtext/html/SB00016E.htm']),
  'TX-SB-5-2017': ('Texas S.B. 5 (85th Leg., 2017), voter identification, enrolled',
    ['https://capitol.texas.gov/tlodocs/85R/billtext/html/SB00005F.htm']),
  'US-HR-22-2025': ('H.R. 22 (119th Congress), SAVE Act, as passed by the House',
    ['https://www.govinfo.gov/content/pkg/BILLS-119hr22eh/html/BILLS-119hr22eh.htm']),
  'US-S-1383-2026': ('S. 1383 (119th Congress) with House amendment, as passed by the House 2026-02-11',
    ['https://www.govinfo.gov/content/pkg/BILLS-119s1383eah/html/BILLS-119s1383eah.htm']),
  'VA-HB-1444-2023': ('Virginia HB 1444 (2023), voter identification, House substitute as passed by the House',
    ['https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+ful+HB1444H1']),
  'VA-HB-19-2020': ('Virginia HB 19 (2020), voter identification requirements, Chapter 1064',
    ['https://legacylis.virginia.gov/cgi-bin/legp604.exe?201+ful+CHAP1064']),
  'VA-SB-1256-2013': ('Virginia SB 1256 (2013), photo identification for voting, Chapter 725',
    ['https://legacylis.virginia.gov/cgi-bin/legp604.exe?131+ful+CHAP0725']),
  'VA-HB-46-2022': ('Virginia HB 46 (2022), voter identification, House substitute HB46H1 as passed by the House',
    ['https://legacylis.virginia.gov/cgi-bin/legp604.exe?221+ful+HB46H1']),
}

# The page that shows each member's vote, by (instrument, chamber). Dates as in the test set.
REC = {
  ('KY-SB-2-2020', 'House'): ['https://apps.legislature.ky.gov/record/20rs/sb2/vote_history.pdf'],
  ('KY-SB-2-2020', 'Senate'): ['https://apps.legislature.ky.gov/record/20rs/sb2/vote_history.pdf'],
  ('KY-SB-2-2020|HFA42', 'House'): ['https://apps.legislature.ky.gov/record/20rs/sb2/vote_history.pdf'],
  ('MA-H-4359-AMDT-7-2022', 'House'): ['https://malegislature.gov/RollCall/192/HouseRollCall139.pdf'],
  ('MI-SB-303-2021', 'Senate'): ['https://www.legislature.mi.gov/documents/2021-2022/Journal/Senate/htm/2021-SJ-10-06-077.htm'],
  ('MI-SB-303-2021', 'House'): ['https://www.legislature.mi.gov/documents/2021-2022/Journal/House/htm/2021-HJ-10-14-084.htm'],
  ('NC-S-824-2018', 'House'): ['https://www.ncleg.gov/Legislation/Votes/RollCallVoteTranscript/2017/H/1354'],
  ('NC-S-824-2018', 'Senate'): ['https://www.ncleg.gov/Legislation/Votes/RollCallVoteTranscript/2017/S/824'],
  ('SC-H-3003-2011', 'House'): ['https://www.scstatehouse.gov/sess119_2011-2012/hj11/20110426.htm'],
  ('SC-H-3003-2011', 'Senate'): ['https://www.scstatehouse.gov/sess119_2011-2012/sj11/20110511.htm'],
  ('TX-SB-1-2021', 'House'): ['http://journals.house.texas.gov/hjrnl/872/pdf/87C2DAY06FINAL.PDF'],
  ('TX-SB-1-2021', 'Senate'): ['http://journals.senate.texas.gov/sjrnl/872/pdf/87S208-31-F.PDF'],
  ('TX-SB-14-2011', 'House'): ['http://journals.house.texas.gov/hjrnl/82r/pdf/82RDAY77FINAL.PDF'],
  ('TX-SB-14-2011', 'Senate'): ['http://journals.senate.texas.gov/sjrnl/82r/pdf/82RSJ05-09-F.PDF'],
  ('TX-SB-16-2025', 'Senate'): ['http://journals.senate.texas.gov/sjrnl/89r/pdf/89RSJ04-01-F.PDF'],
  ('TX-SB-5-2017', 'House'): ['http://journals.house.texas.gov/hjrnl/85r/pdf/85RDAY84FINAL.PDF'],
  ('TX-SB-5-2017', 'Senate'): ['http://journals.senate.texas.gov/sjrnl/85r/pdf/85RSJ05-27-F.PDF'],
  ('US-HR-22-2025', 'House'): ['https://clerk.house.gov/evs/2025/roll102.xml'],
  ('US-S-1383-2026', 'House'): ['https://clerk.house.gov/evs/2026/roll069.xml'],
  ('VA-HB-1444-2023', 'House'): ['https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+vot+HV1322+HB1444'],
  ('VA-HB-19-2020', 'House'): ['https://legacylis.virginia.gov/cgi-bin/legp604.exe?201+vot+HV1986+HB0019'],
  ('VA-HB-19-2020', 'Senate'): ['https://legacylis.virginia.gov/cgi-bin/legp604.exe?201+vot+SV1810HB0019+HB0019'],
  ('VA-SB-1256-2013', 'House'): ['https://legacylis.virginia.gov/cgi-bin/legp604.exe?131+vot+HV1165+SB1256'],
  ('VA-SB-1256-2013', 'Senate'): ['https://legacylis.virginia.gov/cgi-bin/legp604.exe?131+vot+SV0362SB1256+SB1256'],
  ('VA-HB-46-2022', 'House'): ['https://legacylis.virginia.gov/cgi-bin/legp604.exe?221+vot+HV0967+HB0046'],
}

# The bill's history page, given with every vote record: it shows which motion each vote was on (the dry run's coder
# asked for this on VA HB 19).
HISTORY = {
  'KY-SB-2-2020': 'https://apps.legislature.ky.gov/record/20rs/sb2.html',
  'KY-SB-2-2020|HFA42': 'https://apps.legislature.ky.gov/record/20rs/sb2.html',
  'NC-S-824-2018': 'https://www.ncleg.gov/BillLookUp/2017/S824',
  'TX-SB-1-2021': 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=872&Bill=SB1',
  'TX-SB-14-2011': 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=82R&Bill=SB14',
  'TX-SB-16-2025': 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB16',
  'TX-SB-5-2017': 'https://capitol.texas.gov/BillLookup/History.aspx?LegSess=85R&Bill=SB5',
  'VA-HB-1444-2023': 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+sum+HB1444',
  'VA-HB-19-2020': 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?201+sum+HB19',
  'VA-SB-1256-2013': 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?131+sum+SB1256',
  'VA-HB-46-2022': 'https://legacylis.virginia.gov/cgi-bin/legp604.exe?221+sum+HB46',
}

# A sponsorship evidences the bill as filed (C37): the filed text plus the page that names the sponsor.
SPONSOR = {
  'KY-SB-2-2020': ['https://apps.legislature.ky.gov/record/20rs/sb2.html',
                   'https://apps.legislature.ky.gov/recorddocuments/bill/20RS/sb2/orig_bill.pdf'],
  'MA-H-4359-AMDT-7-2022': ['https://malegislature.gov/Bills/192/H4359/Amendments/House'],
  'TX-SB-1-2021': ['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=872&Bill=SB1',
                   'https://capitol.texas.gov/tlodocs/872/billtext/html/SB00001I.htm'],
  'TX-SB-16-2025': ['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB16',
                    'https://capitol.texas.gov/tlodocs/89R/billtext/html/SB00016I.htm'],
  'TX-SB-5-2017': ['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=85R&Bill=SB5',
                   'https://capitol.texas.gov/tlodocs/85R/billtext/html/SB00005I.htm'],
  'US-HR-22-2025': ['https://www.govinfo.gov/content/pkg/BILLS-119hr22ih/html/BILLS-119hr22ih.htm'],
  'US-S-1383-2026': ['https://www.govinfo.gov/content/pkg/BILLS-119hr7296ih/html/BILLS-119hr7296ih.htm'],
  'VA-HB-1444-2023': ['https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+sum+HB1444',
                      'https://legacylis.virginia.gov/cgi-bin/legp604.exe?231+ful+HB1444'],
  'VA-SB-1256-2013': ['https://legacylis.virginia.gov/cgi-bin/legp604.exe?131+sum+SB1256',
                      'https://legacylis.virginia.gov/cgi-bin/legp604.exe?131+ful+SB1256'],
}

# The store's final vote per (instrument, chamber), used to place a Season 2 row whose chamber the test set left blank.
FINAL_DATE = {
  ('TX-SB-1-2021', 'House'): '2021-08-31', ('TX-SB-1-2021', 'Senate'): '2021-08-31',
  ('TX-SB-5-2017', 'House'): '2017-05-28', ('TX-SB-5-2017', 'Senate'): '2017-05-27',
  ('TX-SB-14-2011', 'House'): '2011-05-16', ('TX-SB-14-2011', 'Senate'): '2011-05-09',
  ('VA-HB-19-2020', 'House'): '2020-03-05', ('VA-HB-19-2020', 'Senate'): '2020-03-07',
  ('VA-SB-1256-2013', 'House'): '2013-02-20', ('VA-SB-1256-2013', 'Senate'): '2013-02-05',
  ('VA-HB-1444-2023', 'House'): '2023-02-02',
  ('US-HR-22-2025', 'House'): '2025-04-10', ('US-S-1383-2026', 'House'): '2026-02-11',
}
SUFFIX = {'jr', 'jr.', 'sr', 'sr.', 'ii', 'iii', 'iv'}


def surname(full):
  toks = [t for t in re.split(r'[\s,]+', full) if t and t.lower() not in SUFFIX]
  return toks[-1].lower()


def store_votes():
  out = {}
  for f in glob.glob(os.path.join(STORE, '*', '*.json')):
    d = json.load(open(f))
    out[d['id']] = d.get('votes', [])
  return out


def chamber_of(votes, instr, full_name):
  """The chamber whose final vote lists this surname as yea, or None (ambiguous or absent)."""
  hits = []
  for (i, ch), date in FINAL_DATE.items():
    if i != instr: continue
    for v in votes.get(instr, []):
      if v.get('date') != date or not v.get('body', '').endswith(ch): continue
      names = [m['name'].lower() for m in v.get('members', []) if m.get('vote') == 'yea']
      if any(surname(full_name) in re.split(r'[\s,.]+', n) for n in names):
        hits.append(ch)
  return hits[0] if len(set(hits)) == 1 else None


# Pages the snapshot fetcher cannot read, saved by hand with Chris Andrews' OK for this run only (2026-10-22).
# Each file's first line records its source and method. build_batch.py needs each in the batch's human-saved/.
SAVED = {
  'http://journals.house.texas.gov/hjrnl/85r/pdf/85RDAY84FINAL.PDF': 'tx-hj-85-day84-sb5.txt',
  'http://journals.senate.texas.gov/sjrnl/85r/pdf/85RSJ05-27-F.PDF': 'tx-sj-85-0527-sb5.txt',
  'https://www.legislature.mi.gov/documents/2021-2022/Journal/Senate/htm/2021-SJ-10-06-077.htm': 'mi-sj-2021-10-06.txt',
}


def src(url, label):
  return {'url': url, 'human_saved_path': f'human-saved/{SAVED[url]}' if url in SAVED else None, 'instruments': [label]}


def main():
  out, only = sys.argv[1], set(sys.argv[2:])
  offices = {l.split('\t')[0]: l.rstrip('\n').split('\t') for l in open(OFFICES)}
  rows = [r for r in csv.DictReader(open(TEST_SET), delimiter='\t') if r['status'] == 'in']
  items = {(i['politician_id'], i['instrument_id'], i['chamber'], i['vote']): i['rec']
           for i in json.load(open(os.path.join(PREP, 'stage3/items.json')))}
  votes = store_votes()
  carry = json.load(open(CARRY))['carry']
  by = {}
  for r in rows:
    by.setdefault(r['politician_id'], []).append((r['instrument_id'], r['chamber'], r['vote'], r['stratum']))
  for c in carry:  # carry records not in the test set
    for rec in c['records']:
      t = (rec['instrument_id'], 'House', 'yea', 'carry')
      if not any(x[0] == t[0] for x in by.get(c['politician_id'], [])): by.setdefault(c['politician_id'], []).append(t)
  batches, unplaced = [], []
  for pid, recs in by.items():
    if not any(v in ('yea', 'sponsor') for _, _, v, _ in recs): continue  # Nay-only: a Nay cannot seat a chair
    o = offices[pid]
    name = 'vr-' + re.sub(r'[^a-z]', '', o[1].split()[0].lower())[:1] + re.sub(r'[^a-z]', '', surname(o[1]))
    if only and name not in only: continue
    sources = []
    for instr, ch, vote, stratum in recs:
      rec = items.get((pid, instr, ch, vote), instr)
      if not ch:
        ch = chamber_of(votes, instr, o[1])
        if not ch: unplaced.append((o[1], instr)); continue
      label, texts = INSTR[rec if rec in INSTR else instr]
      sources += [src(t, label) for t in texts]
      if vote == 'sponsor': sources += [src(u, label) for u in SPONSOR[instr]]
      else: sources += [src(u, label) for u in REC[(rec if rec in INSTR else instr, ch)]]
      key = rec if rec in INSTR else instr
      if vote != 'sponsor' and key in HISTORY: sources.append(src(HISTORY[key], label))
    seen, uniq = set(), []
    for s in sources:
      if s['url'] not in seen: seen.add(s['url']); uniq.append(s)
    batches.append({'name': name, 'person': o[1], 'politician_id': pid, 'office_id': o[2],
                    'level': 'federal' if o[4].startswith('NATIONAL') else 'state',
                    'topic_key': 'voting-rights', 'records': [list(r) for r in recs], 'sources': uniq})
  names = [b['name'] for b in batches]
  assert len(names) == len(set(names)), sorted(n for n in names if names.count(n) > 1)
  json.dump({'season': 'draft', 'batches': sorted(batches, key=lambda b: b['name'])}, open(out, 'w'), indent=2)
  print(f'{len(batches)} batch(es) -> {out}')
  for u in unplaced: print('UNPLACED (chamber unknown, record left out):', u)


main()
