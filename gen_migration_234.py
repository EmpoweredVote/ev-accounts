import csv

name_to_uuid = {
    'Aisha Wahab': 'bec15428-f2c6-45a2-9bf0-ae91e6fabe70',
    'Akilah Weber Pierson': 'e5470008-3c0d-4970-a485-053621d8f0a6',
    'Angelique Ashby': '060aa5ab-1d4a-4fd1-89cb-afc96cbc09cb',
    'Anna Caballero': '8b15f324-ed8b-4cc9-92b4-fdaf07896b20',
    'Benjamin Allen': '4486f856-118b-475c-83f0-078581a7b268',
    'Bob Archuleta': '29e15a5d-d98f-4536-ad62-05b2612f30ca',
    'Brian W. Jones': 'ee130fd3-649d-49e1-bda4-13d9bbed2f6c',
    'Caroline Menjivar': '4baa73c2-d38b-4d07-894f-1577d5ba43a3',
    'Catherine S. Blakespear': 'fad61dc3-a3ad-4056-b2f2-1f5d32fb886d',
    'Christopher Cabaldon': '5c4d4194-a7a1-4efa-80cb-af848e338b8d',
    'Dave Cortese': 'e0dc83f8-f72d-4869-8d79-532002408028',
    'Eloise Gómez Reyes': '1571da4a-b832-4792-917c-184c155b1700',
    'Henry Stern': 'f3671de4-514f-441c-8ad4-4a9ab7c65ae6',
    'Jerry McNerney': '0267f457-cd3f-4790-b0c8-76ec616de3f0',
    'Jesse Arreguín': 'eeeaf1be-3372-4cf9-b3b6-d5d1dff42615',
    'John Laird': '178a41d4-42b5-4ffd-be06-d1059d54eacb',
    'Josh Becker': '64eda290-d172-48de-8827-6ebca668cf5a',
    'Kelly Seyarto': '4fccbf85-d794-4cdc-a8b8-674ff1b48784',
    'Laura Richardson': '9edc0c37-f213-4aae-9212-c9cb4780d854',
    'Lena Gonzalez': '1cede4d2-3075-4860-b133-1ab34cdacff5',
    'Lola Smallwood-Cuevas': 'cb9b6b95-ace4-4ae3-a7e6-ae2349abd741',
    'Maria Elena Durazo': 'c7dc9c50-84c6-4bde-af06-e7f9d5167e93',
    'Marie Alvarado-Gil': '6e2d2c6d-b96e-4916-a7c8-51a8f46629ba',
    'Megan Dahle': 'c1215ce9-430e-411d-869c-353c93fe1cac',
    'Melissa Hurtado': 'd3b4ee4d-4cf5-4a3d-8e86-2320fc4a7c26',
    'Mike McGuire': '974bfe8b-afb8-424c-bfd2-7805f033b1a0',
    'Monique Limón': 'c7a56941-597a-456b-8fd8-e4bd840014c1',
}

topic_map = {
    'abortion': 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
    'ai-regulation': '666bf03d-81fc-4138-ab15-69ae734c9023',
    'campaign-finance': '92730f69-ae57-401c-8ad1-2d07834a895d',
    'childcare': 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
    'city-sanitation': '7687de4f-4d0b-462a-b803-bdfb23b16b42',
    'civil-rights': '0bc588c6-39e1-4084-b5de-cac909b8b762',
    'climate-change': 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
    'data-centers': '4559b513-0fd8-4ed1-babd-f3b554162f40',
    'deportation': '44905f3b-e105-4f6c-afc7-5d223813dbac',
    'economic-development': 'eb3d1247-0de1-4b7f-baec-7259861efd53',
    'fossil-fuels': 'a22215c3-6693-4bc2-b248-01aebba14570',
    'growth-and-development': 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
    'healthcare': 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
    'homelessness': '4938766b-b45a-46e3-93bd-b8b30651271a',
    'homelessness-response': '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
    'housing': '669cac97-66a6-4087-b036-936fbe62efb3',
    'immigration': '4e2c69ce-591e-4197-9cd5-7aceff79d390',
    'jail-capacity': 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
    'judicial-access-to-justice': '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
    'judicial-bail-pretrial': '1fab5edf-6151-4da0-9704-a7f2113ba54c',
    'judicial-criminal-justice': '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
    'judicial-government-deference': 'e5e48f0e-8f3a-40e1-8080-889fea389603',
    'judicial-interpretation': '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
    'judicial-police-accountability': '7bad33eb-e93e-4d94-8822-97212d49bde5',
    'judicial-prosecution-priorities': 'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
    'judicial-transparency': '6674d87e-999d-433a-aab7-3f626f59fd5f',
    'local-environment': '1935979c-b290-42e4-baa5-8cb0138b4ffa',
    'local-immigration': 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
    'medicare/aid': 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
    'misinformation': 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
    'public-safety-approach': 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
    'redistricting': '48cc9585-ec22-4f53-8d42-6839828dd36f',
    'religious-freedom': '6b9ba6d9-1001-43f5-b073-4d37130696fd',
    'rent-regulation': 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
    'residential-zoning': 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
    'same-sex-marriage': 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
    'school-vouchers': '00b95a6a-75db-4521-b523-3326bba938de',
    'social-security': '87d20824-a6e9-407b-983c-65440084a0ab',
    'tariffs': '683c8084-2281-4920-a07c-18439b2dd413',
    'taxes': 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
    'trans-athletes': 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
    'transportation-priorities': 'ba59337e-30e2-4aba-a39a-426b3366eb27',
    'ukraine-support': '24e9212c-b011-422a-865c-093e35050901',
    'voting-rights': 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
}

rows = []
with open('backend/data/stance-research/2026-05-22-ca-state-senate.csv', newline='', encoding='utf-8-sig') as f:
    for row in csv.DictReader(f):
        if not row.get('full_name', '').strip():
            continue
        name = row['full_name'].strip()
        pid = name_to_uuid.get(name)
        if not pid:
            # Try raw
            pid = name_to_uuid.get(row['full_name'].strip())
        topic_key = row['topic_key'].strip()
        tid = topic_map.get(topic_key)
        if not pid or not tid:
            print(f"SKIP: name='{name}' topic='{topic_key}' pid={pid} tid={tid}")
            continue
        urls = [row.get(f'source_url_{i}', '').strip() for i in [1,2,3]]
        urls = [u for u in urls if u]
        rows.append({
            'pid': pid, 'tid': tid, 'key': topic_key, 'name': name,
            'val': float(row['value']),
            'reasoning': row.get('reasoning', ''),
            'urls': urls,
        })

lines = []
lines.append("-- ============================================================================")
lines.append("-- Migration 234: CA State Senate Stances -- 27 Senators")
lines.append("-- ============================================================================")
lines.append("-- Purpose: Insert/upsert stance data for 27 CA State Senators (researched 2026-05-22).")
lines.append("--")
lines.append(f"-- Scope: 27 senators, {len(rows)} stance rows")
lines.append("--")
lines.append("-- Missing senators (need research): Susan Rubio (SD-22), Suzette Martinez Valladares (SD-23),")
lines.append("--   Sasha Rene Perez (SD-25), Thomas Umberg (SD-34), Tony Strickland (SD-36),")
lines.append("--   Steve Padilla (SD-18), Rosilicie Ochoa Bogh (SD-19), Sabrina Cervantes (SD-31),")
lines.append("--   Steven Choi (SD-37), Scott Wiener (SD-11), Shannon Grove (SD-12),")
lines.append("--   Tim Grayson (SD-9), Roger Niello (SD-6)")
lines.append("--")
lines.append("-- Idempotency: ON CONFLICT DO UPDATE on both tables.")
lines.append("-- Apply to remote Supabase via psql.")
lines.append("-- ============================================================================")
lines.append("")
lines.append("BEGIN;")
lines.append("")

for row in rows:
    src_array = ('ARRAY[' + ', '.join("'" + u + "'" for u in row['urls']) + ']::text[]') if row['urls'] else 'ARRAY[]::text[]'
    lines.append(f"-- {row['name']} / {row['key']}")
    lines.append(f"INSERT INTO inform.politician_answers (politician_id, topic_id, value)")
    lines.append(f"VALUES ('{row['pid']}', '{row['tid']}', {row['val']})")
    lines.append(f"ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;")
    lines.append(f"")
    lines.append(f"INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)")
    lines.append(f"VALUES ('{row['pid']}', '{row['tid']}',")
    lines.append(f"        $${row['reasoning']}$$,")
    lines.append(f"        {src_array})")
    lines.append(f"ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;")
    lines.append(f"")

lines.append("COMMIT;")

with open('backend/migrations/234_ca_state_senate_stances.sql', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print(f"Written: 234_ca_state_senate_stances.sql ({len(rows)} stance rows)")
