import os, csv
base = r'C:/EV-Accounts/backend/data/stance-research'
expected = [
    ('2026-06-07-md-delegate-d41-rosenberg.csv', 'Samuel I. Rosenberg'),
    ('2026-06-07-md-delegate-d41-ruff.csv', 'Malcolm P. Ruff'),
    ('2026-06-07-md-delegate-d41-stinnett.csv', 'Sean A. Stinnett'),
    ('2026-06-07-md-delegate-d42b-guyton.csv', 'Michele Guyton'),
    ('2026-06-07-md-delegate-d42c-stonko.csv', 'Joshua J. Stonko'),
    ('2026-06-07-md-delegate-d43a-boyce.csv', 'Regina T. Boyce'),
    ('2026-06-07-md-delegate-d43a-embry.csv', 'Elizabeth Embry'),
    ('2026-06-07-md-delegate-d43b-forbes.csv', 'Catherine M. Forbes'),
    ('2026-06-07-md-delegate-d44a-ebersole.csv', 'Eric Ebersole'),
    ('2026-06-07-md-delegate-d44b-mccaskill.csv', 'Aletheia McCaskill'),
    ('2026-06-07-md-delegate-d44b-ruth.csv', 'Sheila Ruth'),
    ('2026-06-07-md-delegate-d45-addison.csv', 'Jackie Addison'),
    ('2026-06-07-md-delegate-d45-smith.csv', 'Stephanie Smith'),
    ('2026-06-07-md-delegate-d45-young.csv', 'Caylin Young'),
    ('2026-06-07-md-delegate-d46-clippinger.csv', 'Luke Clippinger'),
    ('2026-06-07-md-delegate-d46-edelson.csv', 'Mark Edelson'),
    ('2026-06-07-md-delegate-d46-lewis.csv', 'Robbyn Lewis'),
    ('2026-06-07-md-delegate-d47a-fennell.csv', 'Diana M. Fennell'),
    ('2026-06-07-md-delegate-d47a-ivey.csv', 'Julian Ivey'),
    ('2026-06-07-md-delegate-d47b-taveras.csv', 'Deni Taveras'),
]
forbidden = {'data-centers', 'local-immigration', 'transportation-priorities'}
total = 0
nf = 0
per_delegate = {}
for fname, name in expected:
    p = os.path.join(base, fname)
    assert os.path.exists(p), f'missing {p}'
    with open(p, encoding='utf-8', newline='') as f:
        rdr = csv.DictReader(f)
        rows = list(rdr)
        if not rows:
            nf += 1
            per_delegate[name] = 0
            continue
        for r in rows:
            assert r['full_name'] == name, f'{fname}: {r["full_name"]!r}!={name!r}'
            assert r['topic_key'] not in forbidden, f'{fname}: forbidden topic {r["topic_key"]}'
            v = int(r['value'])
            assert 1 <= v <= 5, f'{fname}: value {v} out of range'
            assert r['source_url_1'].strip(), f'{fname}: empty source_url_1'
        per_delegate[name] = len(rows)
        total += len(rows)
# ensure no d42a vacant CSV
vacant_path = os.path.join(base, '2026-06-07-md-delegate-d42a-vacant.csv')
assert not os.path.exists(vacant_path), 'NO CSV must exist for vacant HD-42A'
print(f'OK 20 files; {total} rows; {nf} not-found; vacant CSV absent: PASS')
print(f'Total rows: {total}')
for name, count in sorted(per_delegate.items(), key=lambda x: x[1], reverse=True):
    print(f'  {name}: {count} stances')
# Check min 120 rows
assert total >= 120, f'FAIL: total {total} < 120 minimum'
# Check Rosenberg >= 10
assert per_delegate['Samuel I. Rosenberg'] >= 10, f'Rosenberg has {per_delegate["Samuel I. Rosenberg"]} < 10'
# Check Clippinger >= 10
assert per_delegate['Luke Clippinger'] >= 10, f'Clippinger has {per_delegate["Luke Clippinger"]} < 10'
print('All sanity gates: PASS')
