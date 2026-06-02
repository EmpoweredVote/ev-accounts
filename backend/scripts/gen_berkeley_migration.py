import csv, sys
from collections import defaultdict

POLITICIAN_UUIDS = {
    'Adena Ishii':        '965de422-660e-4e24-9fe6-717cc0313403',
    'Jenny Wong':         '3342ae40-cc86-43e5-8581-3237b6aa8f08',
    'Rashi Kesarwani':    'd2013613-769f-4374-809e-a018dbc1e683',
    'Terry Taplin':       'bcdb549a-48bf-400f-9d23-c93e2e71007c',
    'Ben Bartlett':       'eaab41f8-71c8-47db-bd0b-62da46b5607b',
    'Igor Tregub':        '9f9a35a9-0226-45f0-9fd8-ef46163f7245',
    "Shoshana O'Keefe":   '8cc1c412-fe14-4bc6-b1e2-02d95997fd47',
    'Brent Blackaby':     '424eb63b-9976-4059-8049-365c09719cc6',
    'Cecilia Lunaparra':  '116aace8-9440-498b-bf1d-ebb196727c85',
    'Mark Humbert':       '7833be90-c693-40b8-a309-61ee77b4ba03',
}

TOPIC_UUIDS = {
    'abortion':                      'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
    'ai-regulation':                 '666bf03d-81fc-4138-ab15-69ae734c9023',
    'campaign-finance':              '92730f69-ae57-401c-8ad1-2d07834a895d',
    'childcare':                     'c1ac1330-47f7-44ec-baf3-c913d926b97c',
    'city-sanitation':               '7687de4f-4d0b-462a-b803-bdfb23b16b42',
    'civil-rights':                  '0bc588c6-39e1-4084-b5de-cac909b8b762',
    'climate-change':                'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
    'deportation':                   '44905f3b-e105-4f6c-afc7-5d223813dbac',
    'economic-development':          'eb3d1247-0de1-4b7f-baec-7259861efd53',
    'fossil-fuels':                  'a22215c3-6693-4bc2-b248-01aebba14570',
    'growth-and-development':        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
    'healthcare':                    'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
    'homelessness':                  '4938766b-b45a-46e3-93bd-b8b30651271a',
    'homelessness-response':         '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
    'housing':                       '669cac97-66a6-4087-b036-936fbe62efb3',
    'immigration':                   '4e2c69ce-591e-4197-9cd5-7aceff79d390',
    'jail-capacity':                 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
    'judicial-access-to-justice':    '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
    'judicial-bail-pretrial':        '1fab5edf-6151-4da0-9704-a7f2113ba54c',
    'judicial-criminal-justice':     '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
    'judicial-government-deference': 'e5e48f0e-8f3a-40e1-8080-889fea389603',
    'judicial-interpretation':       '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
    'judicial-police-accountability':'7bad33eb-e93e-4d94-8822-97212d49bde5',
    'judicial-prosecution-priorities':'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
    'judicial-transparency':         '6674d87e-999d-433a-aab7-3f626f59fd5f',
    'local-environment':             '1935979c-b290-42e4-baa5-8cb0138b4ffa',
    'local-immigration':             'b9ccee94-ad96-4f10-b655-889d8e5abe92',
    'medicare/aid':                  'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
    'misinformation':                'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
    'public-safety-approach':        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
    'redistricting':                 '48cc9585-ec22-4f53-8d42-6839828dd36f',
    'religious-freedom':             '6b9ba6d9-1001-43f5-b073-4d37130696fd',
    'rent-regulation':               'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
    'residential-zoning':            'd4f18138-a2e0-4110-b925-7387d9d0d16d',
    'same-sex-marriage':             'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
    'school-vouchers':               '00b95a6a-75db-4521-b523-3326bba938de',
    'social-security':               '87d20824-a6e9-407b-983c-65440084a0ab',
    'tariffs':                       '683c8084-2281-4920-a07c-18439b2dd413',
    'taxes':                         'f7e5678d-dadd-4556-a2fc-446e24642ceb',
    'trans-athletes':                'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
    'transportation-priorities':     'ba59337e-30e2-4aba-a39a-426b3366eb27',
    'ukraine-support':               '24e9212c-b011-422a-865c-093e35050901',
    'voting-rights':                 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
}

POLITICIAN_ORDER = [
    'Adena Ishii', 'Jenny Wong', 'Rashi Kesarwani', 'Terry Taplin',
    'Ben Bartlett', 'Igor Tregub', "Shoshana O'Keefe",
    'Brent Blackaby', 'Cecilia Lunaparra', 'Mark Humbert',
]
POLITICIAN_TITLE = {
    'Adena Ishii':        'Mayor',
    'Jenny Wong':         'City Auditor',
    'Rashi Kesarwani':    'Council Member (District 1)',
    'Terry Taplin':       'Council Member (District 2)',
    'Ben Bartlett':       'Council Member (District 3)',
    'Igor Tregub':        'Council Member (District 4)',
    "Shoshana O'Keefe":   'Council Member (District 5)',
    'Brent Blackaby':     'Council Member (District 6)',
    'Cecilia Lunaparra':  'Council Member (District 7)',
    'Mark Humbert':       'Council Member (District 8)',
}

rows_by_pol = defaultdict(list)
with open('data/stance-research/2026-06-01-berkeley-officials.csv', newline='', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for r in reader:
        rows_by_pol[r['full_name']].append(r)

total = sum(len(v) for v in rows_by_pol.values())

lines = []
lines.append('-- ============================================================================')
lines.append('-- Migration 256: Berkeley Officials Stances -- 10 Politicians')
lines.append('-- ============================================================================')
lines.append('-- Purpose: Insert/upsert stance data for 10 Berkeley city officials.')
lines.append('--')
lines.append("-- Politicians: Adena Ishii (Mayor), Jenny Wong (City Auditor),")
lines.append("--              Rashi Kesarwani (D1), Terry Taplin (D2), Ben Bartlett (D3),")
lines.append("--              Igor Tregub (D4), Shoshana O'Keefe (D5), Brent Blackaby (D6),")
lines.append("--              Cecilia Lunaparra (D7), Mark Humbert (D8)")
lines.append('--')
lines.append(f'-- Stance count: {total} rows')
lines.append('-- Topic scope: 42 topics (all 43 live topics except data-centers)')
lines.append('--')
lines.append('-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.')
lines.append('-- ============================================================================')
lines.append('')
lines.append('-- Topic UUID reference (inform.compass_topics, data-centers excluded):')
for key in sorted(TOPIC_UUIDS.keys()):
    uid = TOPIC_UUIDS[key]
    lines.append(f'-- {key:<34} {uid}')
lines.append('')
lines.append('-- Politician UUID reference (essentials.politicians):')
for name in POLITICIAN_ORDER:
    lines.append(f'-- {name:<26} {POLITICIAN_UUIDS[name]}')
lines.append('')
lines.append('BEGIN;')

for name in POLITICIAN_ORDER:
    stances = rows_by_pol.get(name, [])
    if not stances:
        continue
    title = POLITICIAN_TITLE[name]
    pid = POLITICIAN_UUIDS[name]
    lines.append('')
    lines.append('-- ============================================================')
    lines.append(f'-- {name} ({title})')
    lines.append('-- ============================================================')
    for s in stances:
        topic_key = s['topic_key']
        tid = TOPIC_UUIDS.get(topic_key)
        if not tid:
            print(f'WARNING: unknown topic_key {topic_key}', file=sys.stderr)
            continue
        value = float(s['value'])
        reasoning = s['reasoning']
        urls = [s.get(f'source_url_{i}', '').strip() for i in range(1, 4)]
        urls = [u for u in urls if u]
        if urls:
            sources_sql = 'ARRAY[' + ', '.join(f"'{u}'" for u in urls) + ']::text[]'
        else:
            sources_sql = "ARRAY[]::text[]"

        lines.append('')
        lines.append(f'-- ----- {name} / {topic_key} -----')
        lines.append('INSERT INTO inform.politician_answers (politician_id, topic_id, value)')
        lines.append(f"VALUES ('{pid}', '{tid}', {value})")
        lines.append('ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;')
        lines.append('')
        lines.append('INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)')
        lines.append(f"VALUES ('{pid}', '{tid}',")
        lines.append(f'$${reasoning}$$,')
        lines.append(f'{sources_sql})')
        lines.append('ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;')

lines.append('')
lines.append('COMMIT;')

sql = '\n'.join(lines)
with open('migrations/256_berkeley_stances.sql', 'w', encoding='utf-8') as f:
    f.write(sql)
print(f'Written: migrations/256_berkeley_stances.sql ({total} stances, {len(lines)} lines)')
