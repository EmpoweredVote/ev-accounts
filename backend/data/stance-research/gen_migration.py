#!/usr/bin/env python3
"""Generate stance migration SQL from batch CSV files."""

import csv
import sys
import re

# Canonical topic UUID mapping (from migration 197 + compass-topics-reference.md + DB query)
TOPIC_UUIDS = {
    # Federal / state topics
    'abortion':                'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
    'ai-regulation':           '666bf03d-81fc-4138-ab15-69ae734c9023',
    'campaign-finance':        '92730f69-ae57-401c-8ad1-2d07834a895d',
    'childcare':               'c1ac1330-47f7-44ec-baf3-c913d926b97c',
    'civil-rights':            '0bc588c6-39e1-4084-b5de-cac909b8b762',
    'climate-change':          'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
    'deportation':             '44905f3b-e105-4f6c-afc7-5d223813dbac',
    'economic-development':    'eb3d1247-0de1-4b7f-baec-7259861efd53',
    'fossil-fuels':            'a22215c3-6693-4bc2-b248-01aebba14570',
    'healthcare':              'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
    'homelessness':            '4938766b-b45a-46e3-93bd-b8b30651271a',
    'homelessness-response':   '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
    'housing':                 '669cac97-66a6-4087-b036-936fbe62efb3',
    'immigration':             '4e2c69ce-591e-4197-9cd5-7aceff79d390',
    'jail-capacity':           'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
    'judicial-criminal-justice':     '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
    'judicial-interpretation':       '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
    'medicare/aid':            'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
    'misinformation':          'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
    'public-safety-approach':  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
    'redistricting':           '48cc9585-ec22-4f53-8d42-6839828dd36f',
    'religious-freedom':       '6b9ba6d9-1001-43f5-b073-4d37130696fd',
    'same-sex-marriage':       'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
    'school-vouchers':         '00b95a6a-75db-4521-b523-3326bba938de',
    'social-security':         '87d20824-a6e9-407b-983c-65440084a0ab',
    'tariffs':                 '683c8084-2281-4920-a07c-18439b2dd413',
    'taxes':                   'f7e5678d-dadd-4556-a2fc-446e24642ceb',
    'trans-athletes':          'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
    'ukraine-support':         '24e9212c-b011-422a-865c-093e35050901',
    'voting-rights':           'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
    # City / local topics
    'city-sanitation':                 '7687de4f-4d0b-462a-b803-bdfb23b16b42',
    'growth-and-development':          'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
    'judicial-access-to-justice':      '9d45acaf-1ba4-4cb8-95e1-5ed985223b91',
    'judicial-bail-pretrial':          '1fab5edf-6151-4da0-9704-a7f2113ba54c',
    'judicial-government-deference':   'e5e48f0e-8f3a-40e1-8080-889fea389603',
    'judicial-police-accountability':  '7bad33eb-e93e-4d94-8822-97212d49bde5',
    'judicial-prosecution-priorities': 'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
    'judicial-transparency':           '6674d87e-999d-433a-aab7-3f626f59fd5f',
    'local-environment':               '1935979c-b290-42e4-baa5-8cb0138b4ffa',
    'local-immigration':               'b9ccee94-ad96-4f10-b655-889d8e5abe92',
    'rent-regulation':                 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
    'residential-zoning':              'd4f18138-a2e0-4110-b925-7387d9d0d16d',
    'transportation-priorities':       'ba59337e-30e2-4aba-a39a-426b3366eb27',
}

# Default excluded topics for federal/senate batches (city-level only, not applicable to federal officials)
EXCLUDED_TOPICS_FEDERAL = {'data-centers', 'local-immigration', 'transportation-priorities'}

# No exclusions for local officials (all topics are fair game)
EXCLUDED_TOPICS_LOCAL = {'data-centers'}


def dollar_quote(text):
    """Wrap text in dollar quotes, using tagged variant if text contains $$."""
    text = text.strip()
    if '$$' in text:
        return f'$REASON${text}$REASON$'
    return f'$${text}$$'


def build_sources_array(row):
    """Build ARRAY[...] from source_url_1/2/3, stripping empties."""
    sources = []
    for col in ['source_url_1', 'source_url_2', 'source_url_3']:
        url = (row.get(col) or '').strip()
        if url:
            # Escape single quotes
            url = url.replace("'", "''")
            sources.append(f"'{url}'")
    if not sources:
        return "ARRAY[]::text[]"
    return f"ARRAY[{', '.join(sources)}]::text[]"


def read_csv_stances(csv_files, excluded_topics=None):
    """Read stances from one or more CSV files. Returns list of row dicts."""
    if excluded_topics is None:
        excluded_topics = EXCLUDED_TOPICS_FEDERAL
    rows = []
    for path in csv_files:
        with open(path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                topic_key = row.get('topic_key', '').strip()
                if not topic_key or topic_key in excluded_topics:
                    continue
                if topic_key not in TOPIC_UUIDS:
                    print(f"  WARNING: Unknown topic_key '{topic_key}' in {path} — skipping", file=sys.stderr)
                    continue
                # Normalize value
                try:
                    val = float(row.get('value', '').strip())
                except ValueError:
                    print(f"  WARNING: Invalid value '{row.get('value')}' for {row.get('full_name')}/{topic_key} — skipping", file=sys.stderr)
                    continue
                rows.append(row)
    return rows


def generate_migration(migration_num, batch_label, candidate_inventory, csv_files, outpath,
                       excluded_topics=None, header_scope_note=None):
    """Generate a migration SQL file."""
    rows = read_csv_stances(csv_files, excluded_topics=excluded_topics)

    # Group by politician using full_name only (simplified CSV format has no politician_id column)
    from collections import defaultdict
    by_candidate = defaultdict(list)
    for row in rows:
        name = row.get('full_name', '').strip()
        by_candidate[name].append(row)

    total_stances = sum(len(v) for v in by_candidate.values())

    lines = []

    # Header
    lines.append(f"-- {'=' * 76}")
    lines.append(f"-- Migration {migration_num}: {batch_label}")
    lines.append(f"-- {'=' * 76}")
    lines.append(f"-- Purpose: Insert/upsert stance data for {len(candidate_inventory)} politicians.")
    lines.append(f"--")
    scope = header_scope_note or "All applicable topics."
    lines.append(f"-- Topic scope: {scope}")
    lines.append(f"--")
    lines.append(f"-- Post-state: ~{total_stances} rows expected")
    lines.append(f"--")
    lines.append(f"-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.")
    lines.append(f"-- Apply to remote Supabase via psql.")
    lines.append(f"-- {'=' * 76}")
    lines.append("")
    lines.append("-- Topic UUID reference (inform.compass_topics):")
    for key, uuid in sorted(TOPIC_UUIDS.items()):
        lines.append(f"-- {key:<32} {uuid}")
    lines.append("")
    lines.append("BEGIN;")
    lines.append("")

    # Per-candidate blocks
    for name, pid in sorted(candidate_inventory, key=lambda x: x[0].split()[-1]):
        stances = by_candidate.get(name, [])
        info = f"{name}"
        lines.append(f"-- {'=' * 60}")
        lines.append(f"-- {info}")
        lines.append(f"-- {'=' * 60}")
        lines.append("")

        if not stances:
            lines.append(f"-- NOTE: No stances found in CSV for {name} ({pid})")
            lines.append("")
            continue

        for row in stances:
            topic_key = row['topic_key'].strip()
            topic_uuid = TOPIC_UUIDS[topic_key]
            try:
                value = float(row['value'].strip())
            except ValueError:
                continue

            reasoning = row.get('reasoning', '').strip()
            sources_arr = build_sources_array(row)

            lines.append(f"-- ----- {name} / {topic_key} -----")
            lines.append(f"INSERT INTO inform.politician_answers (politician_id, topic_id, value)")
            lines.append(f"VALUES ('{pid}',")
            lines.append(f"        '{topic_uuid}',")
            lines.append(f"        {value})")
            lines.append(f"ON CONFLICT (politician_id, topic_id)")
            lines.append(f"DO UPDATE SET value = EXCLUDED.value;")
            lines.append("")
            lines.append(f"INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)")
            lines.append(f"VALUES ('{pid}',")
            lines.append(f"        '{topic_uuid}',")
            lines.append(f"        {dollar_quote(reasoning)},")
            lines.append(f"        {sources_arr}::text[])")
            lines.append(f"ON CONFLICT (politician_id, topic_id)")
            lines.append(f"DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;")
            lines.append("")

    lines.append("COMMIT;")
    lines.append("")
    lines.append("-- ============================================================================")
    lines.append("-- Verification queries (run after applying):")
    lines.append("-- ============================================================================")
    lines.append("--")
    lines.append("-- Per-candidate row count (every candidate must have >= 10 topics):")
    lines.append("-- SELECT p.full_name, COUNT(pa.topic_id) AS topic_count")
    lines.append("-- FROM essentials.politicians p")
    lines.append("-- LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id")
    lines.append(f"-- WHERE p.id IN ({', '.join(repr(pid) for _, pid in candidate_inventory)})")
    lines.append("-- GROUP BY p.id, p.full_name ORDER BY topic_count;")
    lines.append("--")
    lines.append("-- Context pairing (must return 0):")
    lines.append("-- SELECT COUNT(*) FROM inform.politician_answers pa")
    lines.append("-- LEFT JOIN inform.politician_context pc")
    lines.append("--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id")
    lines.append(f"-- WHERE pa.politician_id IN ({', '.join(repr(pid) for _, pid in candidate_inventory)})")
    lines.append("--   AND pc.politician_id IS NULL;")

    sql = '\n'.join(lines)
    with open(outpath, 'w', encoding='utf-8') as f:
        f.write(sql)

    print(f"Written: {outpath}")
    print(f"  {len(by_candidate)} candidates, {total_stances} total stances")
    for name, stances in sorted(by_candidate.items(), key=lambda x: x[0].split()[-1]):
        print(f"  {name}: {len(stances)} stances")


# ============================================================================
# BATCH 2: 13 candidates, KY through MN, migration 198
# ============================================================================

BATCH2_CANDIDATES = [
    ("Charles Booker",     "b5cc94df-2ba3-4057-8abd-5760383b286b"),
    ("Andy Barr",          "d6d297f5-5319-4be1-b938-6bcce63368e7"),
    ("Julia Letlow",       "c79994ff-9e88-4318-97d9-d06b0ede183f"),
    ("John Fleming",       "8be7e981-77a6-4ef7-b8d7-891fd9cc26d8"),
    ("Graham Platner",     "7f8e0d30-0b48-4c34-8cd7-34df2a9d8bf7"),
    ("Seth Moulton",       "5ccb1f15-f285-470c-b86a-97f9e6b22dff"),
    ("Abdul El-Sayed",     "ec0cfeae-a512-4ce2-a8f2-a25b00112b9b"),
    ("Mallory McMorrow",   "3bdf2b9e-7512-4cc6-93f5-252078fae92c"),
    ("Haley Stevens",      "3957855d-a78c-492d-b3b6-0f680c1f82c8"),
    ("Mike Rogers",        "ace0b96d-8ef8-4aca-8928-6848ae430da6"),
    ("Peggy Flanagan",     "15bd3382-0d8a-4c3e-8ab9-ab324517882d"),
    ("Angie Craig",        "0cf6bbcf-7c3a-44d3-a8e7-8888d8da24ff"),
    ("Royce White",        "b4b13cd9-ba8a-439b-9a4d-2d46bf7d6c23"),
]

BATCH2_CSVS = [
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch2-booker.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch2-barr.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch2-letlow.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch2-fleming.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch2-platner.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch2-moulton.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch2-elsayed-mcmorrow.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch2-stevens.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch2-rogers.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch2-flanagan.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch2-craig.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch2-white.csv",
]

# ============================================================================
# BATCH 3: 15 candidates, MS through WY, migration 207
# ============================================================================

BATCH3_CANDIDATES = [
    ("Scott Colom",           "4fd59af4-eca7-4cdc-9082-178278ce3dc8"),
    ("Kurt Alme",             "0f8bb5ea-8d89-4cfb-9291-04b54c128b82"),
    ("Seth Bodnar",           "b6c3620e-1ac1-460c-acb4-74854d59b334"),
    ("Dan Osborn",            "79e1e32f-9b0d-4f8f-86f3-679185424596"),
    ("Chris Pappas",          "a4f51d46-c361-4b17-bd63-7932a01ee2c3"),
    ("John Sununu",           "ffb0dcac-385a-4df3-a441-cdbd0e713c1d"),
    ("Roy Cooper",            "1f7429f7-1ecd-4f44-abce-03c72d5cf664"),
    ("Michael Whatley",       "867caca5-ab41-4e1b-b051-4a2cd95a335e"),
    ("Sherrod Brown",         "56603da5-e7ad-48a9-8c77-259513869ed4"),
    ("Kevin Hern",            "b1114b75-8ca1-494e-9251-e8faa84ff408"),
    ("David Brock Smith",     "ae7e8d67-e8a4-49a7-bb5c-715c99168374"),
    ("Annie Andrews",         "238222f5-e5e0-4331-8540-ee904bbacb8a"),
    ("Rachel Fetty Anderson", "6b44e402-7ea5-4dad-b3dd-6066fab6c6f6"),
    ("Harriet Hageman",       "e2f59e14-a81d-45fe-86c0-c992a63d86cd"),
    ("James Byrd",            "f8869b74-2a0c-40b7-93b4-40f32eec7108"),
]

BATCH3_CSVS = [
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch3-colom.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch3-alme.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch3-bodnar.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch3-osborn.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch3-pappas.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch3-sununu.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch3-cooper.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch3-whatley.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch3-brown.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch3-hern.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch3-smith.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch3-andrews.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch3-anderson.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch3-hageman.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-batch3-byrd.csv",
]

# ============================================================================
# GAP-FILL: 2 appointed incumbent senators, migration 210
# ============================================================================

GAPFILL_CANDIDATES = [
    ("Alan Armstrong", "abbe5ec0-94fb-4230-bc7c-4b890e4e6387"),
    ("Jon Husted",     "d5740b38-9b65-431a-9e33-645d432dec61"),
]

GAPFILL_CSVS = [
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-armstrong-gapfill.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-husted-gapfill.csv",
]

# ============================================================================
# SF OFFICIALS: 20 San Francisco elected/appointed officials, migration 216
# ============================================================================

SF_CANDIDATES = [
    ("Daniel Lurie",     "708db738-2bf1-4a6f-b8a5-7ac23d171b33"),
    ("Brooke Jenkins",   "969f1ca4-4766-44fd-8638-ef813b1835e7"),
    ("David Chiu",       "86c12b33-cb76-41da-bdf0-6b58a0cbbed6"),
    ("Paul Miyamoto",    "c1a5fe0a-5c9a-490d-9d2d-71bd8b3f22d1"),
    ("Rafael Mandelman", "d2596e4d-f491-449e-b112-40be13418112"),
    ("Myrna Melgar",     "72621ac9-bcdb-4ea3-aeec-1b1f50c9f996"),
    ("Matt Dorsey",      "68845df3-7103-45d9-8429-7ef51ee6ada3"),
    ("Bilal Mahmood",    "d3c5004c-9ca0-444e-96d9-107d4315abcb"),
    ("Alan Wong",        "6273727a-26e0-495d-9fda-f827b88029b3"),
    ("Danny Sauter",     "d1a320a9-39e9-4152-85a0-11cab602fdc9"),
    ("Stephen Sherrill", "54e564e7-4788-4913-b75e-95382896d509"),
    ("Connie Chan",      "f3f21e38-d8e6-41d2-9d74-0360a5f679b9"),
    ("Jackie Fielder",   "02f88a57-ccf5-4fe1-a693-7fc949321fb1"),
    ("Shamann Walton",   "eab7b830-c831-45f9-bca8-11b079f42680"),
    ("Chyanne Chen",     "8f59c9fd-03f9-4652-bc4a-418bd8764a1f"),
    ("José Cisneros",    "94035c6d-d6b2-4223-bdeb-e93e2ec26198"),
    ("Joaquín Torres",   "f0a54f0a-c1e5-457a-97af-8c2c9e1adf1a"),
    ("Manohar Raju",     "aa35ed62-a5a7-47fd-99d3-0ceb3336e405"),
    ("Greg Wagner",      "c3627dfd-6f20-40e8-b9af-55c4af048d92"),
    ("Carmen Chu",       "f82edba8-5f6b-4c00-af78-b782426f05a2"),
]

SF_CSVS = [
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-lurie.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-jenkins.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-chiu.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-miyamoto.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-mandelman.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-melgar.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-dorsey.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-mahmood.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-wong.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-sauter.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-sherrill.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-chan.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-fielder.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-walton.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-chyanne-chen.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-cisneros.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-torres.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-raju.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-wagner.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-05-22-sf-chu.csv",
]

# ============================================================================
# MD EXEC: 5 MD Constitutional Officers, migration 282
# ============================================================================

MD_EXEC_CANDIDATES = [
    ("Wes Moore",        "21e534c8-c0c0-42f5-b52b-5eb2f246d632"),
    ("Aruna Miller",     "ea9fc2d6-3b26-469a-978c-e8c846d2d49a"),
    ("Anthony G. Brown", "60329719-1d5b-4bb4-8295-38ea18f6f378"),
    ("Brooke Lierman",   "b26fb5d2-90eb-4108-8ce5-838df719473d"),
    ("Dereck E. Davis",  "75378a96-8886-46eb-b0c1-37cbe2579265"),
]

MD_EXEC_CSVS = [
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-exec-moore.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-exec-miller.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-exec-brown.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-exec-lierman.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-exec-davis.csv",
]

# ============================================================================
# MD SENATORS BATCH A: SD-01 through SD-15, migration 283
# ============================================================================

MD_SENATORS_A_CANDIDATES = [
    ("Mike McKay",           "f88cd73d-1970-4da1-9bea-2142a25999a7"),
    ("Paul D. Corderman",    "5127f8d8-ca40-40aa-8773-4c1abad66f41"),
    ("Karen Lewis Young",    "1f78b5e2-b192-4aae-8112-19338aaa891d"),
    ("William G. Folden",    "4a5241b7-8737-4a58-adf2-c5335111d3c4"),
    ("Justin Ready",         "493c5d0c-1986-40d4-9fff-3a3bc3fe62e8"),
    ("Johnny Ray Salling",   "9f8d0005-c5ff-42f8-b158-cdb6e4eee872"),
    ("J.B. Jennings",        "5927d5ab-2fd7-4454-bcc3-34e494821aac"),
    ("Carl Jackson",         "2fbad601-c2da-4f99-b04f-d28ae30b80f7"),
    ("Katie Fry Hester",     "6da20195-1b0c-43f2-b1b3-7a3954326fe6"),
    ("Benjamin Brooks",      "a16b94b0-dd22-40a9-af91-03295ea27986"),
    ("Shelly Hettleman",     "3089c813-f0a8-46af-9a7b-1699129037e9"),
    ("Clarence K. Lam",      "fc23b939-0dfd-4968-ab19-fc1e7745e997"),
    ("Guy Guzzone",          "f0fafa0e-3dd9-4d50-bc5e-c96315f766d7"),
    ("Craig J. Zucker",      "82145bc2-770a-421e-a2a1-0e79aae5b643"),
    ("Brian J. Feldman",     "d423151e-8477-470d-8f73-ba7d2092f714"),
]

MD_SENATORS_A_CSVS = [
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d01-mckay.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d02-corderman.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d03-young.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d04-folden.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d05-ready.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d06-salling.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d07-jennings.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d08-jackson.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d09-hester.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d10-brooks.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d11-hettleman.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d12-lam.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d13-guzzone.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d14-zucker.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d15-feldman.csv",
]

# ============================================================================
# MD SENATORS BATCH B: SD-16 through SD-31, migration 284
# ============================================================================

MD_SENATORS_B_CANDIDATES = [
    ("Sara Love",              "c5d2cd24-170a-4f87-8fde-84216fe62806"),  # SD-16
    ("Cheryl C. Kagan",        "e35d5990-55c7-42e2-94bc-27cb1c49b5f1"),  # SD-17
    ("Jeff Waldstreicher",     "da75c207-bb23-477e-b3c0-7c462394b570"),  # SD-18
    ("Benjamin F. Kramer",     "7a2d1548-3268-4767-97a8-bb8b142d5a33"),  # SD-19
    ("William C. Smith, Jr.",  "b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc"),  # SD-20
    ("Jim Rosapepe",           "9c400214-f007-4a8d-92fe-5f5d23b3838e"),  # SD-21
    ("Alonzo T. Washington",   "8c8b0896-dfd0-4d3c-8492-e594d93b78ca"),  # SD-22
    ("Ron Watson",             "9aef8bfb-8e0c-4f00-9898-c738abe4970c"),  # SD-23
    ("Joanne C. Benson",       "4a7dc8a6-2138-4472-8197-8b878034f029"),  # SD-24
    ("Nick Charles",           "cf190bac-9369-4175-bd4b-8ba776697d9c"),  # SD-25
    ("C. Anthony Muse",        "47823046-7dea-4a4f-a11b-0c5890539891"),  # SD-26
    ("Kevin M. Harris",        "8c6327bf-2eb4-4788-91f7-c5518ab5a3f1"),  # SD-27
    ("Arthur Ellis",           "4754dede-4a3b-4280-a8b1-7497530107f7"),  # SD-28
    ("Jack Bailey",            "0abc8345-1fbb-4994-b39c-c3c4f4eefc9f"),  # SD-29
    ("Shaneka Henson",         "05c9b5b9-cb2b-4387-ab6b-350b69553fac"),  # SD-30
    ("Bryan W. Simonaire",     "4aa50ee7-aeed-48ae-96e7-142bd9ac731b"),  # SD-31
]

MD_SENATORS_B_CSVS = [
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d16-love.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d17-kagan.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d18-waldstreicher.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d19-kramer.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d20-smith.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d21-rosapepe.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d22-washington.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d23-watson.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d24-benson.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d25-charles.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d26-muse.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d27-harris.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d28-ellis.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d29-bailey.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d30-henson.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d31-simonaire.csv",
]

# ============================================================================
# MD SENATORS BATCH C: SD-32 through SD-47, migration 285
# ============================================================================

MD_SENATORS_C_CANDIDATES = [
    ("Pamela Beidle",           "409ad653-a4fc-41d0-bb61-a933c5bc45c7"),  # SD-32
    ("Dawn Gile",               "ff266ecf-9ea5-4282-b729-9830cc8abfa3"),  # SD-33
    ("Mary-Dulany James",       "18313901-28d8-464c-9368-2873577e9d44"),  # SD-34
    ("Jason C. Gallion",        "e2ca1bfd-255d-417b-a9d7-424e6c10749d"),  # SD-35
    ("Stephen S. Hershey, Jr.", "72287137-7faf-4570-8d9e-c6f8d162f4e0"),  # SD-36
    ("Johnny Mautz",            "34c94aa4-11b7-4594-9c3e-c506f10309f6"),  # SD-37
    ("Mary Beth Carozza",       "9b2fe9e6-21bf-4aee-b351-a841f3f382b9"),  # SD-38
    ("Nancy J. King",           "81b8bae9-0b0f-43de-8079-c0b605e12cec"),  # SD-39
    ("Antonio Hayes",           "04e1a744-acf5-4453-9172-7135b6bfce96"),  # SD-40
    ("Dalya Attar",             "fb714c92-166f-4cc1-bb6b-19988a81cefe"),  # SD-41
    ("Chris West",              "fc06c2bb-db76-43fa-8e2e-91a4c34e57ae"),  # SD-42
    ("Mary Washington",         "38404814-7be0-40e3-b044-062f98b2a5b0"),  # SD-43
    ("Charles E. Sydnor, III",  "30f96c7e-7bf0-4270-bfbb-ee4c520a7344"),  # SD-44
    ("Cory V. McCray",          "54ea8c48-d8d0-43e2-83fe-2f91cac71fdd"),  # SD-45
    ("Bill Ferguson",           "6e3c30f5-52be-48b0-b5b4-383e5d745c57"),  # SD-46
    ("Malcolm Augustine",       "9d191d69-084f-4941-bc0a-c59d336f032e"),  # SD-47
]

MD_SENATORS_C_CSVS = [
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d32-beidle.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d33-gile.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d34-james.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d35-gallion.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d36-hershey.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d37-mautz.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d38-carozza.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d39-king.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d40-hayes.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d41-attar.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d42-west.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d43-washington.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d44-sydnor.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d45-mccray.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d46-ferguson.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-senator-d47-augustine.csv",
]

# ============================================================================
# MD DELEGATES BATCH A: HD-1 through HD-7, migration 286
# ============================================================================

MD_DELEGATES_A_CANDIDATES = [
    ("Jim Hinebaugh, Jr.",       "3817ad52-3f43-4bd3-8525-e7dcd0816153"),  # HD-1A
    ("Jason C. Buckel",          "5260bd6f-e70a-46f1-aa7d-49eaf22192cf"),  # HD-1B
    ("Terry L. Baker",           "d049cf3e-6577-4f8d-ba7e-768ac2b78d66"),  # HD-1C
    ("William Valentine",        "cdf746c1-8311-416b-9ad3-2684a83b6992"),  # HD-2A
    ("William J. Wivell",        "df6fe96f-7795-4934-9acc-2b9f8f0aa8f7"),  # HD-2A
    ("Matthew J. Schindler",     "18c6abb4-7b4b-4e21-a7fe-008e43d6f3e5"),  # HD-2B
    ("Kris Fair",                "dfb9ae21-4605-4c58-94e8-84b1eb1a30c1"),  # HD-3
    ("Kenneth Kerr",             "c0abb4fa-be8d-4fbe-9b6d-6319a8ecd255"),  # HD-3
    ("Karen Simpson",            "5946ad0c-ddf5-4674-840e-6968105042cd"),  # HD-3
    ("Barrie S. Ciliberti",      "00a1eaeb-157c-42f8-a6e5-9a9d02decbe9"),  # HD-4
    ("April Miller",             "b389687f-817b-4fda-8770-a888029f4629"),  # HD-4
    ("Jesse T. Pippy",           "ce2fc441-abd5-4d8f-9c56-114e31c4d43c"),  # HD-4
    ("Christopher Eric Bouchat", "c12bb600-318a-4541-bcdd-8260f1ba172e"),  # HD-5
    ("April Rose",               "5967c703-2583-466f-a438-c3ac182111d5"),  # HD-5
    ("Chris Tomlinson",          "6e5ac4b7-73fd-497d-a4e9-7d5124c3d904"),  # HD-5
    ("Robin L. Grammer, Jr.",    "0608cc7a-72ed-4d24-b966-3eee82075bf1"),  # HD-6
    ("Robert B. Long",           "eadb65c9-74b6-40c3-b9e7-159c5734c59f"),  # HD-6
    ("Ric Metzgar",              "ba85b633-32cf-4617-923c-3a325f39894e"),  # HD-6
    ("Ryan Nawrocki",            "f5224e0c-0761-4ca7-a889-ed44517e2b91"),  # HD-7A
    ("Kathy Szeliga",            "0945acd2-cb51-49ad-a22f-6043d2e61520"),  # HD-7A
    ("Lauren Arikan",            "6a04e5b9-d532-4e80-bbca-6677a35620e5"),  # HD-7B
]

MD_DELEGATES_A_CSVS = [
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d01a-hinebaugh.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d01b-buckel.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d01c-baker.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d02a-valentine.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d02a-wivell.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d02b-schindler.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d03-fair.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d03-kerr.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d03-simpson.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d04-ciliberti.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d04-miller.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d04-pippy.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d05-bouchat.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d05-rose.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d05-tomlinson.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d06-grammer.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d06-long.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d06-metzgar.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d07a-nawrocki.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d07a-szeliga.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d07b-arikan.csv",
]

# ============================================================================
# MD DELEGATES BATCH B: HD-8 through HD-13, migration 287
# ============================================================================

MD_DELEGATES_B_CANDIDATES = [
    ("Nick Allen",              "a1f58b34-76ee-43ce-b152-4843c42f4f79"),  # HD-8
    ("Harry Bhandari",          "6d95657c-6c46-4aab-886f-f9688adc7b33"),  # HD-8
    ("Kim Ross",                "5d17e3ea-9d63-4a96-8848-9e293ac05fdb"),  # HD-8
    ("Chao Wu",                 "7ced90a8-39dc-447e-ba33-e3af4cd47473"),  # HD-9A
    ("Natalie Ziegler",         "38b5030a-aa8b-4363-8b62-3ec384d22088"),  # HD-9A
    ("Courtney Watson",         "a4b61b58-9006-4e58-952d-abeb2521cda0"),  # HD-9B
    ("Adrienne A. Jones",       "760cd4a7-235c-472f-a0ba-fb07098dfd57"),  # HD-10 (Speaker)
    ("N. Scott Phillips",       "04eb4549-ad64-4ddc-ad53-8f90217f905f"),  # HD-10
    ("Jennifer White Holland",  "d80816fc-da1d-48f4-95c9-467f8831933c"),  # HD-10
    ("Cheryl E. Pasteur",       "b5aee428-9b2e-4c87-9a5c-63d44f58e1d8"),  # HD-11A
    ("Jon S. Cardin",           "631dac5c-fb86-41f5-a82d-5963164a9142"),  # HD-11B
    ("Dana Stein",              "e94337e1-4776-4058-87b4-32dfeb7732a0"),  # HD-11B
    ("Jessica Feldmark",        "fdb9f7d3-93db-4436-bd82-5d7fd853f05e"),  # HD-12A
    ("Terri L. Hill",           "f6a237a0-34ff-4a93-b05a-335ec38b6da3"),  # HD-12A
    ("Gary Simmons",            "69cbeb94-6978-4f3f-b8b7-735f789c6d3c"),  # HD-12B
    ("Pam Lanman Guzzone",      "589ed7af-602a-4ec9-8072-448b05446772"),  # HD-13
    ("Gabriel M. Moreno",       "c0ec0d09-db8f-49fe-b4b6-0221a59ab7ec"),  # HD-13
    ("Jen Terrasa",             "f45e2178-2a05-4974-8af8-379662412060"),  # HD-13
]

MD_DELEGATES_B_CSVS = [
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d08-allen.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d08-bhandari.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d08-ross.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d09a-wu.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d09a-ziegler.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d09b-watson.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d10-jones.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d10-phillips.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d10-holland.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d11a-pasteur.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d11b-cardin.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d11b-stein.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d12a-feldmark.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d12a-hill.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d12b-simmons.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d13-guzzone.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d13-moreno.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d13-terrasa.csv",
]

# ============================================================================
# MD DELEGATES BATCH C: HD-14 through HD-20, migration 288
# ============================================================================

MD_DELEGATES_C_CANDIDATES = [
    ("Anne R. Kaiser",        "bfd0f15f-abb1-4d28-b1f4-e06875adce16"),  # HD-14
    ("Bernice Mireku-North",  "8abee534-5db0-4950-a2b9-d0d1e8088cc7"),  # HD-14
    ("Pam Queen",             "a11c027a-ef25-4a09-8df7-e9b7c60bea90"),  # HD-14
    ("Linda Foley",           "b80a680a-9f79-4d56-994b-00ce24ec7ef3"),  # HD-15
    ("David Fraser-Hidalgo",  "ab8aa19a-42c3-445e-9632-a5c7f05458ee"),  # HD-15
    ("Lily Qi",               "e00e72f9-6b53-46a7-a1e4-74ab7b91d68d"),  # HD-15
    ("Marc Korman",           "e76d0654-b0c6-43dc-9159-e929e480d070"),  # HD-16
    ("Sarah Wolek",           "4db476f3-bc84-484c-9440-666028942469"),  # HD-16
    ("Teresa Woorman",        "36171e41-704b-4bf9-b300-755afe4ee06f"),  # HD-16
    ("Julie Palakovich Carr", "70d58d4b-4203-4fc2-b36f-32e6231c4339"),  # HD-17
    ("Ryan Spiegel",          "203a0228-7a63-4a6a-b26d-fa45ba139472"),  # HD-17
    ("Joe Vogel",             "458a60ba-a235-4b36-80bb-8b537375a4ff"),  # HD-17
    ("Aaron M. Kaufman",      "bc703231-6af8-48c6-8ae6-4a93fc60b18f"),  # HD-18
    ("Emily Shetty",          "d1a30768-52e8-4a0d-badc-3e5f2f5792c7"),  # HD-18
    ("Jared Solomon",         "c0bf0c64-6254-40a7-b810-8717977759dd"),  # HD-18
    ("Charlotte Crutchfield", "98d6a17e-59dc-4d11-a342-869603862f10"),  # HD-19
    ("Bonnie Cullison",       "17c22fec-63a4-4f5d-8607-0c364ddffd71"),  # HD-19
    ("Vaughn Stewart",        "ac558ee8-ecae-47b6-a25e-46307521b4af"),  # HD-19
    ("Lorig Charkoudian",     "9c5e1ac7-8a39-4c6e-8b20-0788a92f8607"),  # HD-20
    ("David Moon",            "96876928-53f8-4ed5-b2de-deab3a456d83"),  # HD-20
    ("Jheanelle K. Wilkins",  "cf68a5cd-f375-4296-8a87-1828d903baea"),  # HD-20
]

MD_DELEGATES_C_CSVS = [
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d14-kaiser.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d14-mireku-north.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d14-queen.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d15-foley.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d15-fraser-hidalgo.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d15-qi.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d16-korman.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d16-wolek.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d16-woorman.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d17-palakovich-carr.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d17-spiegel.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d17-vogel.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d18-kaufman.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d18-shetty.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d18-solomon.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d19-crutchfield.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d19-cullison.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d19-stewart.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d20-charkoudian.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d20-moon.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d20-wilkins.csv",
]

# ============================================================================
# MD DELEGATES BATCH D: HD-21 through HD-27, migration 289
# ============================================================================

MD_DELEGATES_D_CANDIDATES = [
    ("Ben Barnes",                "590b56b2-1473-4e86-ba96-0490e172f6ff"),  # HD-21 (Approps Chair)
    ("Mary A. Lehman",            "251a2047-372b-480e-aa09-231f9a5edeca"),  # HD-21
    ("Joseline Peña-Melnyk",      "00cd05cc-75de-4d9a-ab23-9f53441bc186"),  # HD-21 (Speaker Pro Tem)
    ("Anne Healey",               "4436b432-a63f-4946-919a-f30c41f899e4"),  # HD-22
    ("Ashanti Martinez",          "d8eee978-cec3-492d-9867-9d40b2a50a9d"),  # HD-22
    ("Nicole A. Williams",        "5c24446e-c9d6-4dda-9703-e3c049798315"),  # HD-22
    ("Adrian Boafo",              "1da26040-98b4-4eb0-aa1f-3ec05b297a29"),  # HD-23
    ("Marvin E. Holmes, Jr.",     "b8e331fa-d58e-479f-b076-8fda0b0604c5"),  # HD-23 (comma in name)
    ("Kym Taylor",                "9273ed81-2052-428a-b39d-849abeef270b"),  # HD-23
    ("Tiffany T. Alston",         "2e809682-2d95-480c-885e-d2174b811cfe"),  # HD-24
    ("Derrick Coley",             "8fab5ff7-603d-4ab0-a05c-a7070d187a48"),  # HD-24
    ("Andrea Fletcher Harrison",  "d61a670a-7626-4464-93dc-c1e21d7b26da"),  # HD-24
    ("Kent Roberson",             "338210ee-b9ab-4820-bfce-98f5354837af"),  # HD-25
    ("Denise Roberts",            "d5999df9-83b8-4870-a170-4d13f40473e2"),  # HD-25
    ("Karen Toles",               "cd422f8c-913b-4280-987b-9383ead34e85"),  # HD-25
    ("Veronica Turner",           "7a76712a-38cd-41de-b260-cd0127284f16"),  # HD-26
    ("Kriselda Valderrama",       "768ac1cf-a599-4ddb-943c-c985fafb2607"),  # HD-26
    ("Jamila J. Woods",           "916afe40-4061-476f-9a54-b271b32778d2"),  # HD-26
    ("Darrell Odom",              "0e238dbf-5b4e-4e95-8a94-e02d97a136f5"),  # HD-27A
    ("Jeffrie E. Long, Jr.",      "70f63959-f51d-4411-adc1-f1c429bbc397"),  # HD-27B (comma in name)
    ("Mark N. Fisher",            "71542618-59c8-4b06-a765-e3df60cca763"),  # HD-27C
]

MD_DELEGATES_D_CSVS = [
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d21-barnes.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d21-lehman.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d21-pena-melnyk.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d22-healey.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d22-martinez.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d22-williams.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d23-boafo.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d23-holmes.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d23-taylor.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d24-alston.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d24-coley.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d24-harrison.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d25-roberson.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d25-roberts.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d25-toles.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d26-turner.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d26-valderrama.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d26-woods.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d27a-odom.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d27b-long.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d27c-fisher.csv",
]

# ============================================================================
# MD DELEGATES BATCH E: HD-28 through HD-33, migration 290
# ============================================================================

MD_DELEGATES_E_CANDIDATES = [
    ("Debra Davis",                    "1cc5a555-4b8a-4573-8525-9ad2c7c0bf46"),  # HD-28
    ("Edith J. Patterson",             "b9c61fea-fcb1-45cc-8e2c-e5b3046b7266"),  # HD-28
    ("C. T. Wilson",                   "69870c10-cea2-43c2-8cf9-bfcaf0b82265"),  # HD-28
    ("Matthew Morgan",                 "c4e4d811-1e14-45fe-9335-7521f1603856"),  # HD-29A (distinct from Todd B. Morgan)
    ("Brian M. Crosby",                "898845f9-cb93-4162-b0ed-6842eacda5d6"),  # HD-29B
    ("Todd B. Morgan",                 "7d79931f-101c-415b-a6a0-b7a919f70905"),  # HD-29C (distinct from Matthew Morgan)
    ("Dylan Behler",                   "3f45bad5-b856-4d8e-b3d9-8c03623e030a"),  # HD-30A
    ("Dana Jones",                     "d8eabd9b-2aa8-40de-94ce-06ce6ef167cf"),  # HD-30A
    ("Seth A. Howard",                 "2fe3f655-c28e-40c3-a2f9-48ea9eb8b498"),  # HD-30B
    ("Brian Chisholm",                 "cfc704da-dd6c-40b0-97fa-0c5ece8d3976"),  # HD-31
    ("Nicholaus R. Kipke",             "0e0bdc53-b5a2-4292-aeb7-341a4c5bed08"),  # HD-31 (former Minority Leader)
    ("LaToya Nkongolo",                "13462ee2-0dd9-4f70-809f-a813c23951d4"),  # HD-31
    ("J. Sandy Bartlett",              "7d818044-a989-47e1-b6cf-d482ebad0600"),  # HD-32
    ("Mark S. Chang",                  "4a409af4-8568-42c3-bb72-7bb7500c96ce"),  # HD-32
    ("Mike Rogers",                    "24980735-6a39-4e48-94b0-7318cac8dfde"),  # HD-32
    ("Andrew C. Pruski",               "ddfd43d3-023d-417e-9b68-af5a693e601e"),  # HD-33A
    ("Stuart Michael Schmidt, Jr.",    "55d9d0b6-78a3-460b-97b9-87913ffc8e85"),  # HD-33B (comma in name)
    ("Heather Bagnall",                "41749b94-11b8-4047-8421-95db0900d4b2"),  # HD-33C
]

MD_DELEGATES_E_CSVS = [
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d28-davis.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d28-patterson.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d28-wilson.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d29a-morgan-m.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d29b-crosby.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d29c-morgan-t.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d30a-behler.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d30a-jones.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d30b-howard.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d31-chisholm.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d31-kipke.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d31-nkongolo.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d32-bartlett.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d32-chang.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d32-rogers.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d33a-pruski.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d33b-schmidt.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d33c-bagnall.csv",
]

# ============================================================================
# MD DELEGATES BATCH F: HD-34 through HD-40, migration 291
# ============================================================================

MD_DELEGATES_F_CANDIDATES = [
    ("Andre V. Johnson, Jr.",   "b592e432-6411-48b3-bca3-d5596d0d81e9"),  # HD-34A (comma in name — distinct from Steve Johnson)
    ("Steve Johnson",           "dbb1c600-c87b-449c-bd3b-1c236287c00f"),  # HD-34A (distinct from Andre V. Johnson, Jr.)
    ("Susan K. McComas",        "58d0ff82-631f-475f-889a-9a4ebb39fc07"),  # HD-34B
    ("Mike Griffith",           "0c789b27-d50c-4822-95ff-409ecb7db08a"),  # HD-35A
    ("Teresa E. Reilly",        "547841f2-3476-4e83-9344-0cac984d44e8"),  # HD-35A
    ("Kevin B. Hornberger",     "96a6d696-50fd-4393-a0f6-19e69dc15716"),  # HD-35B
    ("Steven J. Arentz",        "fee8a413-a3a8-4568-ad9b-db00f94f5ac2"),  # HD-36
    ("Jefferson L. Ghrist",     "eca530ff-628d-417d-a3dc-b858dc7c2376"),  # HD-36
    ("Jay A. Jacobs",           "8b43dd9c-26c3-48bb-ac60-d95f8a39349a"),  # HD-36
    ("Sheree Sample-Hughes",    "a1c2b55c-df7d-487c-ad90-7f7e2c2e6951"),  # HD-37A (Speaker Pro Tem; hyphenated last name)
    ("Christopher T. Adams",    "1eada938-f28c-46b9-bd21-df241656cd2b"),  # HD-37B
    ("Thomas S. Hutchinson",    "fb1fe811-b340-42d3-88ee-97b5364117cd"),  # HD-37B
    ("H. Kevin Anderson",       "d17104a7-8a35-4bcd-8879-76ceb997df6a"),  # HD-38A
    ("Barry Beauchamp",         "bc7ee014-a452-4eaf-81e9-2f4c55d3eaea"),  # HD-38B
    ("Wayne A. Hartman",        "1ff2bb96-0e55-4893-8a4c-b675dfbb79f6"),  # HD-38C
    ("Gabriel Acevero",         "e1b53b61-d4f7-4d10-bdb3-2a8dcfb12820"),  # HD-39 (progressive caucus)
    ("Lesley J. Lopez",         "2fa68ca4-00b5-4518-a692-d12447d7fec3"),  # HD-39
    ("Greg Wims",               "b7e2aa8f-a301-4004-81e9-d1f857c81075"),  # HD-39
    ("Marlon Amprey",           "62bed8b6-beb2-4c41-b234-dc6427bfc9c0"),  # HD-40
    ("Frank M. Conaway, Jr.",   "94855fb3-0e08-45ac-8c67-ba668ef67c4b"),  # HD-40 (comma in name)
    ("Melissa Wells",           "7217c1b4-6fae-447d-9566-f2513319fa94"),  # HD-40
]

MD_DELEGATES_F_CSVS = [
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d34a-johnson-a.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d34a-johnson-s.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d34b-mccomas.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d35a-griffith.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d35a-reilly.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d35b-hornberger.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d36-arentz.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d36-ghrist.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d36-jacobs.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d37a-sample-hughes.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d37b-adams.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d37b-hutchinson.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d38a-anderson.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d38b-beauchamp.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d38c-hartman.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d39-acevero.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d39-lopez.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d39-wims.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d40-amprey.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d40-conaway.csv",
    r"C:\EV-Accounts\backend\data\stance-research\2026-06-07-md-delegate-d40-wells.csv",
]

if __name__ == '__main__':
    import os
    base = r"C:\EV-Accounts\backend\migrations"

    print("Generating migration 198 (batch-2)...")
    generate_migration(
        migration_num=198,
        batch_label="Batch 2 of 3 (KY → MN)",
        candidate_inventory=BATCH2_CANDIDATES,
        csv_files=BATCH2_CSVS,
        outpath=os.path.join(base, "198_us_senate_candidate_stances_batch2.sql"),
    )

    print()
    print("Generating migration 207 (batch-3)...")
    generate_migration(
        migration_num=207,
        batch_label="Batch 3 of 3 (MS → WY)",
        candidate_inventory=BATCH3_CANDIDATES,
        csv_files=BATCH3_CSVS,
        outpath=os.path.join(base, "207_us_senate_candidate_stances_batch3.sql"),
    )

    print()
    print("Generating migration 210 (gap-fill: Armstrong OK + Husted OH)...")
    generate_migration(
        migration_num=210,
        batch_label="Appointed Senator Gap-Fill (Armstrong OK + Husted OH)",
        candidate_inventory=GAPFILL_CANDIDATES,
        csv_files=GAPFILL_CSVS,
        outpath=os.path.join(base, "210_appointed_senator_gapfill_stances.sql"),
    )

    print()
    print("Generating migration 216 (SF officials stances)...")
    generate_migration(
        migration_num=216,
        batch_label="SF Officials Stances — 20 San Francisco Politicians",
        candidate_inventory=SF_CANDIDATES,
        csv_files=SF_CSVS,
        excluded_topics=EXCLUDED_TOPICS_LOCAL,
        header_scope_note="All 43 compass topics (city + federal); only data-centers excluded.",
        outpath=os.path.join(base, "216_sf_officials_stances.sql"),
    )

    print()
    print("Generating migration 282 (MD exec stances)...")
    generate_migration(
        migration_num=282,
        batch_label="MD Executive Stances — 5 Constitutional Officers",
        candidate_inventory=MD_EXEC_CANDIDATES,
        csv_files=MD_EXEC_CSVS,
        excluded_topics=EXCLUDED_TOPICS_FEDERAL,
        header_scope_note="Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.",
        outpath=os.path.join(base, "282_md_exec_stances.sql"),
    )

    print()
    print("Generating migration 283 (MD senators batch A: SD-01 through SD-15)...")
    generate_migration(
        migration_num=283,
        batch_label="MD Senators Batch A — Districts 1-15",
        candidate_inventory=MD_SENATORS_A_CANDIDATES,
        csv_files=MD_SENATORS_A_CSVS,
        excluded_topics=EXCLUDED_TOPICS_FEDERAL,
        header_scope_note="Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.",
        outpath=os.path.join(base, "283_md_senators_batch_a.sql"),
    )

    print()
    print("Generating migration 284 (MD senators batch B: SD-16 through SD-31)...")
    generate_migration(
        migration_num=284,
        batch_label="MD Senators Batch B — Districts 16-31",
        candidate_inventory=MD_SENATORS_B_CANDIDATES,
        csv_files=MD_SENATORS_B_CSVS,
        excluded_topics=EXCLUDED_TOPICS_FEDERAL,
        header_scope_note="Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.",
        outpath=os.path.join(base, "284_md_senators_batch_b.sql"),
    )

    print()
    print("Generating migration 285 (MD senators batch C: SD-32 through SD-47)...")
    generate_migration(
        migration_num=285,
        batch_label="MD Senators Batch C — Districts 32-47",
        candidate_inventory=MD_SENATORS_C_CANDIDATES,
        csv_files=MD_SENATORS_C_CSVS,
        excluded_topics=EXCLUDED_TOPICS_FEDERAL,
        header_scope_note="Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.",
        outpath=os.path.join(base, "285_md_senators_batch_c.sql"),
    )

    print()
    print("Generating migration 286 (MD delegates batch A: HD-1 through HD-7)...")
    generate_migration(
        migration_num=286,
        batch_label="MD Delegates Batch A — Districts 1-7",
        candidate_inventory=MD_DELEGATES_A_CANDIDATES,
        csv_files=MD_DELEGATES_A_CSVS,
        excluded_topics=EXCLUDED_TOPICS_FEDERAL,
        header_scope_note="Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.",
        outpath=os.path.join(base, "286_md_delegates_batch_a.sql"),
    )

    print()
    print("Generating migration 287 (MD delegates batch B: HD-8 through HD-13)...")
    generate_migration(
        migration_num=287,
        batch_label="MD Delegates Batch B — Districts 8-13",
        candidate_inventory=MD_DELEGATES_B_CANDIDATES,
        csv_files=MD_DELEGATES_B_CSVS,
        excluded_topics=EXCLUDED_TOPICS_FEDERAL,
        header_scope_note="Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.",
        outpath=os.path.join(base, "287_md_delegates_batch_b.sql"),
    )

    print()
    print("Generating migration 288 (MD delegates batch C: HD-14 through HD-20)...")
    generate_migration(
        migration_num=288,
        batch_label="MD Delegates Batch C — Districts 14-20",
        candidate_inventory=MD_DELEGATES_C_CANDIDATES,
        csv_files=MD_DELEGATES_C_CSVS,
        excluded_topics=EXCLUDED_TOPICS_FEDERAL,
        header_scope_note="Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.",
        outpath=os.path.join(base, "288_md_delegates_batch_c.sql"),
    )

    print()
    print("Generating migration 289 (MD delegates batch D: HD-21 through HD-27)...")
    generate_migration(
        migration_num=289,
        batch_label="MD Delegates Batch D — Districts 21-27",
        candidate_inventory=MD_DELEGATES_D_CANDIDATES,
        csv_files=MD_DELEGATES_D_CSVS,
        excluded_topics=EXCLUDED_TOPICS_FEDERAL,
        header_scope_note="Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.",
        outpath=os.path.join(base, "289_md_delegates_batch_d.sql"),
    )

    print()
    print("Generating migration 290 (MD delegates batch E: HD-28 through HD-33)...")
    generate_migration(
        migration_num=290,
        batch_label="MD Delegates Batch E — Districts 28-33",
        candidate_inventory=MD_DELEGATES_E_CANDIDATES,
        csv_files=MD_DELEGATES_E_CSVS,
        excluded_topics=EXCLUDED_TOPICS_FEDERAL,
        header_scope_note="Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.",
        outpath=os.path.join(base, "290_md_delegates_batch_e.sql"),
    )

    print()
    print("Generating migration 291 (MD delegates batch F: HD-34 through HD-40)...")
    generate_migration(
        migration_num=291,
        batch_label="MD Delegates Batch F — Districts 34-40",
        candidate_inventory=MD_DELEGATES_F_CANDIDATES,
        csv_files=MD_DELEGATES_F_CSVS,
        excluded_topics=EXCLUDED_TOPICS_FEDERAL,
        header_scope_note="Federal/state topics only; data-centers, local-immigration, transportation-priorities excluded.",
        outpath=os.path.join(base, "291_md_delegates_batch_f.sql"),
    )
