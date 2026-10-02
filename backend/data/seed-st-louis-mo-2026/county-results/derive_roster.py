import csv, io, sys, json, collections, os, hashlib
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

# Every file must be byte-complete. A truncated CSV returns a plausible WRONG winner
# under a clean HTTP 200 -- that happened on 2026-09-29 and handed back the runner-up
# in County Council District 6 at a believable 53/47 margin.
EXPECT = {
    'csv-201103.csv': 7998603, 'csv-220802.csv': 6929384, 'csv-221108.csv': 6316962,
    'csv-240806.csv': 14766495, 'csv-241105.csv': 9364370, 'csv-260804.csv': 6438599,
}
for f, n in EXPECT.items():
    got = os.path.getsize(f)
    assert got == n, f'{f}: {got} bytes, expected {n} -- TRUNCATED, re-download before trusting this'
print('integrity: all %d files byte-complete' % len(EXPECT))

def winners(path, titles):
    agg = collections.defaultdict(lambda: collections.defaultdict(int)); party = {}
    ncol = None
    with open(path, newline='', encoding='utf-8-sig', errors='replace') as fh:
        r = csv.DictReader(fh)
        for row in r:
            c = (row.get('Contest Title') or '').strip().upper()
            ch = (row.get('Choice Name') or '').strip()
            if c not in titles or not ch: continue
            agg[c][ch] += int(row.get('Total Votes') or 0)
            party[(c, ch)] = (row.get('Choice Party') or '').strip()
    out = {}
    for c, choices in agg.items():
        rows = sorted(choices.items(), key=lambda kv: -kv[1])
        tot = sum(v for _, v in rows)
        out[c] = {'winner': rows[0][0], 'votes': rows[0][1],
                  'pct': round(100*rows[0][1]/tot, 2), 'party': party[(c, rows[0][0])],
                  'total_votes': tot, 'field': [{'name': n, 'votes': v} for n, v in rows]}
    return out

N22 = winners('csv-221108.csv', {'COUNTY EXECUTIVE', 'PROSECUTING ATTORNEY', 'COUNTY ASSESSOR',
              'COUNTY COUNCIL - DISTRICT 1', 'COUNTY COUNCIL - DISTRICT 3',
              'COUNTY COUNCIL - DISTRICT 5', 'COUNTY COUNCIL - DISTRICT 7'})
N24 = winners('csv-241105.csv', {'COUNTY COUNCIL - DISTRICT 2', 'COUNTY COUNCIL - DISTRICT 4',
              'COUNTY COUNCIL - DISTRICT 6'})

# Who the county itself says holds the seat TODAY (read 2026-09-29).
# A certified result is NOT a fact about who holds the seat: Wesley Bell won
# Prosecuting Attorney in 2022 and then won a US House seat.
HELD_NOW = {
    'COUNTY EXECUTIVE':            ('Sam Page', 'stlouiscountymo.gov/st-louis-county-government/county-executive/'),
    'PROSECUTING ATTORNEY':        ('Melissa Price Smith', 'stlcopa.stlouiscountymo.gov/'),
    'COUNTY ASSESSOR':             ('Jake Zimmerman', 'stlouiscountymo.gov/st-louis-county-government/county-assessor/'),
    'COUNTY COUNCIL - DISTRICT 1': ('Rita Heard Days', 'stlouiscountymo.gov/st-louis-county-government/county-council/'),
    'COUNTY COUNCIL - DISTRICT 2': ('Gretchen Bangert', 'stlouiscountymo.gov/st-louis-county-government/county-council/'),
    'COUNTY COUNCIL - DISTRICT 3': ('Dennis Hancock', 'stlouiscountymo.gov/st-louis-county-government/county-council/'),
    'COUNTY COUNCIL - DISTRICT 4': ('Shalonda D. Webb', 'stlouiscountymo.gov/st-louis-county-government/county-council/'),
    'COUNTY COUNCIL - DISTRICT 5': ('Lisa D. Clancy', 'stlouiscountymo.gov/st-louis-county-government/county-council/'),
    'COUNTY COUNCIL - DISTRICT 6': ('Michael Archer', 'stlouiscountymo.gov/st-louis-county-government/county-council/'),
    'COUNTY COUNCIL - DISTRICT 7': ('Mark Harder', 'stlouiscountymo.gov/st-louis-county-government/county-council/'),
}

seats = []
for contest, (held, src) in HELD_NOW.items():
    cert = N22.get(contest) or N24.get(contest)
    cohort = 'nov-2022' if contest in N22 else 'nov-2024'
    last = held.split()[-1].lower()
    seats.append({
        'contest': contest, 'cohort': cohort,
        'certified_winner': cert['winner'], 'certified_votes': cert['votes'],
        'certified_pct': cert['pct'], 'certified_party': cert['party'],
        'held_now': held, 'held_now_source': src,
        'same_person': last in cert['winner'].lower(),
    })

print('\n%-30s %-9s %-24s %-22s %s' % ('CONTEST', 'COHORT', 'CERTIFIED WINNER', 'HELD NOW', 'MATCH'))
for s in seats:
    print('%-30s %-9s %-24s %-22s %s' % (s['contest'], s['cohort'], s['certified_winner'],
          s['held_now'], 'yes' if s['same_person'] else '*** NO ***'))

json.dump({'measured': '2026-09-29', 'seats': seats,
           'charter_6_010': 'There shall be no elective county officers other than county executive, '
                            'council members, prosecuting attorney and assessor.',
           'source_csvs': {k: v for k, v in EXPECT.items()}},
          open('county-roster-2026-09-29.json', 'w', encoding='utf-8'), indent=2)
print('\nwrote county-roster-2026-09-29.json')
