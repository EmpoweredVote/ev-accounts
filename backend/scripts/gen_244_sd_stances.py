#!/usr/bin/env python3
"""Generate backend/migrations/244_sd_stances.sql from the SD officials CSV."""

import csv
from pathlib import Path

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

EXCLUDED_TOPICS = {'data-centers'}

POLITICIAN_UUIDS = {
    'Todd Gloria':          'a975b943-f3e0-492a-bd26-9f5993a5c094',
    'Heather Ferbert':      '0d81c306-514e-455c-988e-b0d04f7e0897',
    'Joe LaCava':           '1e93b635-3706-4268-91e2-97abae0c54a0',
    'Jennifer Campbell':    'c6d7ea83-d6ee-4d08-a183-effd36f6a2cc',
    'Stephen Whitburn':     'f86591f9-4341-4e3a-a9cb-f284887ccf74',
    'Henry L. Foster III':  '296b5d71-954a-46db-8055-17299abb86fa',
    'Marni von Wilpert':    'c3f1fad4-46cd-4f2f-8723-d7a3f99dca65',
    'Kent Lee':             '3fb56c85-f8b7-4732-88e1-f79b56750428',
    'Raul Campillo':        '84ba4a09-a90f-4ad4-9fa3-995961bd839c',
    'Vivian Moreno':        '0b16443e-fec4-4f33-abbc-eb1331e3b42d',
    'Sean Elo-Rivera':      'dc3d8a98-07ce-4797-bc84-957a72fd854f',
}

POLITICIAN_ROLES = {
    'Todd Gloria':          'Mayor',
    'Heather Ferbert':      'City Attorney',
    'Joe LaCava':           'District 1',
    'Jennifer Campbell':    'District 2',
    'Stephen Whitburn':     'District 3',
    'Henry L. Foster III':  'District 4',
    'Marni von Wilpert':    'District 5',
    'Kent Lee':             'District 6',
    'Raul Campillo':        'District 7',
    'Vivian Moreno':        'District 8',
    'Sean Elo-Rivera':      'District 9',
}

ORDER = list(POLITICIAN_ROLES.keys())


def dquote(text):
    if '$$' not in text:
        return f'$${text}$$'
    return f'$BODY${text}$BODY$'


def main():
    csv_path = Path('backend/data/stance-research/2026-05-28-san-diego-officials.csv')
    out_path = Path('backend/migrations/244_sd_stances.sql')

    rows_by_pol = {n: [] for n in ORDER}
    unknown_topics = set()

    with open(csv_path, newline='', encoding='utf-8') as f:
        for row in csv.DictReader(f):
            name = row['full_name']
            topic = row['topic_key']
            if topic in EXCLUDED_TOPICS:
                continue
            if topic not in TOPIC_UUIDS:
                unknown_topics.add(topic)
                continue
            if name in rows_by_pol:
                rows_by_pol[name].append(row)
            else:
                print(f'WARNING: unknown politician: {name!r}')

    total = sum(len(v) for v in rows_by_pol.values())

    L = []

    L += [
        '-- ============================================================================',
        '-- Migration 244: San Diego Officials Stances — 11 Politicians',
        '-- ============================================================================',
        '-- Purpose: Insert/upsert stance data for 11 San Diego city officials.',
        '--',
        '-- Politicians: Todd Gloria (Mayor), Heather Ferbert (City Attorney),',
        '--              Joe LaCava (D1), Jennifer Campbell (D2), Stephen Whitburn (D3),',
        '--              Henry L. Foster III (D4), Marni von Wilpert (D5), Kent Lee (D6),',
        '--              Raul Campillo (D7), Vivian Moreno (D8), Sean Elo-Rivera (D9)',
        '--',
        f'-- Stance count: {total} rows (politician_answers + politician_context pairs)',
        '--',
        '-- Topic scope: 42 topics (all 43 live topics except data-centers)',
        '-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.',
        '-- Apply to remote Supabase via psql.',
        '-- ============================================================================',
        '',
        '-- Topic UUID reference (inform.compass_topics):',
    ]
    for k in sorted(TOPIC_UUIDS):
        L.append(f'-- {k:<38} {TOPIC_UUIDS[k]}')
    L += ['', '-- Politician UUID reference (essentials.politicians):']
    for n in ORDER:
        L.append(f'-- {n:<30} {POLITICIAN_UUIDS[n]}')
    L += ['', 'BEGIN;']

    for name in ORDER:
        stances = rows_by_pol[name]
        if not stances:
            continue
        p = POLITICIAN_UUIDS[name]
        role = POLITICIAN_ROLES[name]
        L += [
            '',
            '-- ============================================================',
            f'-- {name} ({role})',
            '-- ============================================================',
        ]
        for row in stances:
            tk = row['topic_key']
            tid = TOPIC_UUIDS[tk]
            val = float(row['value'])
            reasoning = row['reasoning']
            sources = [row.get(f'source_url_{i}', '').strip() for i in range(1, 4)]
            sources = [s for s in sources if s]
            src_sql = 'ARRAY[' + ', '.join(f"'{s}'" for s in sources) + ']::text[]'
            L += [
                '',
                f'-- ----- {name} / {tk} -----',
                'INSERT INTO inform.politician_answers (politician_id, topic_id, value)',
                f"VALUES ('{p}', '{tid}', {val})",
                'ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;',
                '',
                'INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)',
                f"VALUES ('{p}', '{tid}',",
                dquote(reasoning) + ',',
                src_sql + ')',
                'ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;',
            ]

    L += ['', 'COMMIT;', '']

    out_path.write_text('\n'.join(L), encoding='utf-8')
    print(f'Written: {out_path}  ({total} stances)')
    for n in ORDER:
        print(f'  {n}: {len(rows_by_pol[n])}')
    if unknown_topics:
        print(f'UNKNOWN TOPICS (skipped): {unknown_topics}')


if __name__ == '__main__':
    main()
