"""Build build_batch.py specs for the education-library-books Season 3 (draft) Opus-alone run, 2026-10-15.

One batch per seated person (33, roster from Stage 3). Sources = the instrument text(s) in the person's roster row
plus the record that shows their own vote or sponsorship. Run from backend/:

    python3 data/stance-research/library-s3-2026-10-15/make_spec.py <out.json> [name ...]

With names, only those batches are written (e.g. the dry run). Human-saved files are copied into each batch dir
by build_batch.py's caller (see README.md here); a source with "human_saved" names a file in ./human-saved/.
"""
import json, os, sys

ROSTER = os.path.expanduser('~/Library/Application Support/Claude-EV/side-session-notes/'
                            'local_691d33e8-01b1-4e66-9a1b-24b288dc6864/library-33-seated-roster.tsv')
OFFICES = os.path.join(os.path.dirname(__file__), 'offices.tsv')  # politician_id, name, office_id, title, district_type

# Instrument -> (instrument label, text sources). A source is a URL or (URL, human-saved file name).
INSTR = {
  'BRAIN-631': ('Brainerd Public Schools (ISD 181) Policy 631 Library Materials (adopted 2024-02-12)',
    ['https://files.smartsites.parentsquare.com/5927/631_-_library_materials_02122024docx.pdf']),
  'CHINO-6163': ('Chino Valley USD BP 6163.1 Library Media Centers and AR 1312.2 Complaints Concerning Instructional Materials (revised 2023-11-16)',
    [('https://files.smartsites.parentsquare.com/7144/bp_61631.pdf', 'chino-bp-61631.txt'),
     ('https://files.smartsites.parentsquare.com/7144/ar_13122_.pdf', 'chino-ar-13122.txt')]),
  'CLAY-2023': ('Clay County District Schools amendment to the Library Media Services and Instructional Resources procedures manuals (Challenged Materials Procedure, 2023-04-06)',
    ['https://agenda.oneclay.net/content/files/library-meda-services-manual-change-to-page-18-23-1-4-all-markup-removed-2.pdf',
     'https://agenda.oneclay.net/content/files/challenged-materials-procedureinstructionaldocx-final-with-all-markup-removed-1.pdf']),
  'CLAY-POL-2024': ('Clay County District Schools Challenged Materials Policy - Reconsideration or Review of Library Materials (2024-05-02)',
    ['https://agenda.oneclay.net/content/files/042024-proposed-challenged-materials-policy-reconsideration-or-review-of-library-materials.pdf']),
  'ESC-2522-2024': ('Escambia County School Board Policy 2522 Challenges to Adoption or Use of Instructional, Library, or Reading List Materials (2024-10-15 / 2024-11-19)',
    [('https://go.boarddocs.com/fl/escambia/Board.nsf/files/DAXSTX744B5F/$file/2522%20CHALLENGES%20TO%20ADOPTION%20OR%20USE%20OF%20INSTRUCTIONAL%2C%20LIBRARY%2C%20OR%20READING%20LIST%20MATERIALS%20REVISED%20(1).pdf', 'esc-2522-2024.txt')]),
  'ESC-2522-2025B': ('Escambia County School Board Rule 2522 Challenges to Instructional, Library, Reading Lists (adopted 2025-10-21)',
    [('https://go.boarddocs.com/fl/escambia/Board.nsf/files/DM9Q6F67C539/$file/091825-2%20-%20Rule%202522%20-%20Challenges%20to%20Instructional%2C%20Library%2C%20Reading%20Lists%20(Adoption)%20Stamped%202.pdf', 'esc-2522-2025b.txt')]),
  'TN-SB2407-2022': ('Tennessee SB 2407 / HB 2154 (2022), Public Chapter 744, Age-Appropriate Materials Act',
    ['https://publications.tnsosfiles.com/acts/112/pub/pc0744.pdf']),
  'TX-SB13-2025': ('Texas S.B. 13 (89th Leg., 2025), school library advisory councils and library materials',
    ['https://capitol.texas.gov/tlodocs/89R/billtext/html/SB00013F.htm']),
  'UT-HB29-2024': ('Utah H.B. 29 (2024 General Session), Sensitive Material Review Amendments',
    [('https://le.utah.gov/~2024/bills/hbillenr/HB0029.pdf', 'ut-hb29-enrolled-ocr.txt')]),
}

# Records of each person's own act, by instrument and (where it differs) by chamber/date.
REC = {
  'BRAIN-631': ['https://docs.google.com/document/d/1d8AVK7pdfRMM2zk4A1D3r0uYDYFG7JyzZFHaMzXymJ4/export?format=txt'],
  'CHINO-6163': [('https://www.chino.k12.ca.us/cms/lib/CA01902308/Centricity/domain/677/2023/minutes/11-16-23%20Minutes.pdf', 'chino-minutes-2023-11-16.txt')],
  'CLAY-2023': [('https://agenda.oneclay.net/content/files/2023-apr-6-regular-mtg.pdf', 'clay-minutes-2023-04-06.txt')],
  'CLAY-POL-2024': ['https://agenda.oneclay.net/content/files/2024-may-2-regular-mtg.pdf'],
  'ESC-2522-2024': [
    ('https://go.boarddocs.com/fl/escambia/Board.nsf/PRINT-AgendaDetailed?open&id=D8RNLQ604D27&current_committee_id=A4EP6J588C05', 'esc-agenda-2024-10-15.txt'),
    ('https://go.boarddocs.com/fl/escambia/Board.nsf/PRINT-AgendaDetailed?open&id=D9HM2R59282E&current_committee_id=A4EP6J588C05', 'esc-agenda-2024-11-19.txt')],
  'ESC-2522-2025B': [
    ('https://go.boarddocs.com/fl/escambia/Board.nsf/PRINT-AgendaDetailed?open&id=DLCPAD63A9AC&current_committee_id=A4EP6J588C05', 'esc-agenda-2025-10-21.txt')],
  'TN-SB2407-2022': ['https://wapp.capitol.tn.gov/apps/BillInfo/Default.aspx?BillNumber=SB2407&GA=112'],
  'TX-SB13-2025:STATE_UPPER': ['https://journals.senate.texas.gov/sjrnl/89r/pdf/89RSJ05-31-F.PDF'],
  'TX-SB13-2025:STATE_LOWER': ['https://journals.house.texas.gov/hjrnl/89r/pdf/89RDAY79FINAL.PDF'],
  'TX-SB13-2025:sponsor': ['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=89R&Bill=SB13'],
  'UT-HB29-2024:STATE_LOWER': ['https://le.utah.gov/DynaBill/svotes.jsp?sessionid=2024GS&voteid=756&house=H'],
  'UT-HB29-2024:STATE_UPPER': ['https://le.utah.gov/DynaBill/svotes.jsp?sessionid=2024GS&voteid=1168&house=S'],
}
SPONSORS = {'Brad Buckley'}
# Round 2 (2026-10-15): sources the coder asked for (needs_source) on its first pass. Batches get a -r2 suffix.
CLAY_MANUAL_2024 = ('https://agenda.oneclay.net/content/files/library-media-services-manual-may-2024-draft-1.pdf',
  'Clay County District Schools Library Media Services Manual (May 2024 draft), adopted 2024-05-02 (item C11)')
CLAY_INSTR_P19 = ('https://agenda.oneclay.net/content/files/instructional-manual-page-19paragraph-21-final-1.pdf', INSTR['CLAY-2023'][0])
TN_HB2154 = ('https://www.capitol.tn.gov/Bills/112/Bill/HB2154.pdf', 'Tennessee HB 2154 (2022), House companion of SB 2407, as filed')
TX_SB13_HOUSE = ('https://capitol.texas.gov/tlodocs/89R/billtext/html/SB00013H.htm', INSTR['TX-SB13-2025'][0] + ', House committee report version')
TX_HJ79 = ('https://journals.house.texas.gov/hjrnl/89r/pdf/89RDAY79FINAL.PDF', INSTR['TX-SB13-2025'][0])
EXTRA = {p: [CLAY_MANUAL_2024, CLAY_INSTR_P19] for p in ('Ashley Gilhousen', 'Beth Clark', 'Erin Skipper', 'Michele Hanson')}
EXTRA.update({'Mark Cochran': [TN_HB2154], 'William Lamberth': [TN_HB2154], 'Brad Buckley': [TX_SB13_HOUSE, TX_HJ79]})  # TX House sponsor of SB 13 — bill history names him; he has no separate roll-call need


def src(x, label):
  url, saved = (x, None) if isinstance(x, str) else x
  return {'url': url, 'human_saved_path': f'human-saved/{saved}' if saved else None, 'instruments': [label]}


def main():
  out, only = sys.argv[1], set(sys.argv[2:])
  r2 = '--r2' in only; only.discard('--r2')
  offices = {l.split('\t')[0]: l.rstrip('\n').split('\t') for l in open(OFFICES)}
  rows = [l.rstrip('\n').split('\t') for l in open(ROSTER)][1:]
  batches = []
  for row_id, person, level, chair, instr, pid, _office in rows:
    o = offices[pid]
    name = 'lib-' + person.split()[-1].lower().replace('.', '')
    if only and name not in only: continue
    sources = []
    for code in instr.split(','):
      label, texts = INSTR[code]
      sources += [src(t, label) for t in texts]
      if code in REC: recs = REC[code]
      elif code == 'TX-SB13-2025':
        recs = REC['TX-SB13-2025:sponsor'] if person in SPONSORS else REC[f'TX-SB13-2025:{o[4]}']
      else: recs = REC[f'{code}:{o[4]}']
      sources += [src(r, label) for r in recs]
    if r2: sources += [{'url': u, 'human_saved_path': None, 'instruments': [l]} for u, l in EXTRA.get(person, [])]
    seen, uniq = set(), []
    for s in sources:
      if s['url'] not in seen: seen.add(s['url']); uniq.append(s)
    batches.append({'name': name + ('-r2' if r2 else ''), 'row_id': row_id, 'person': person, 'expected_chair': int(chair),
                    'politician_id': pid, 'office_id': o[2], 'level': 'school' if level == 'school' else 'state',
                    'topic_key': 'education-library-books', 'sources': uniq})
  json.dump({'season': 'draft', 'batches': batches}, open(out, 'w'), indent=2)
  print(f'{len(batches)} batch(es) -> {out}')


main()
