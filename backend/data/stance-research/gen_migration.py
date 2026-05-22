#!/usr/bin/env python3
"""Generate stance migration SQL from batch CSV files."""

import csv
import sys
import re

# Canonical topic UUID mapping (from migration 197 + compass-topics-reference.md)
TOPIC_UUIDS = {
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
    'judicial-criminal-justice': '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
    'judicial-interpretation': '448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee',
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
}

# EXCLUDED topics (city-level only, not federal)
EXCLUDED_TOPICS = {'data-centers', 'local-immigration', 'transportation-priorities'}


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


def read_csv_stances(csv_files):
    """Read stances from one or more CSV files. Returns list of row dicts."""
    rows = []
    for path in csv_files:
        with open(path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                topic_key = row.get('topic_key', '').strip()
                if not topic_key or topic_key in EXCLUDED_TOPICS:
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


def generate_migration(migration_num, batch_label, candidate_inventory, csv_files, outpath):
    """Generate a migration SQL file."""
    rows = read_csv_stances(csv_files)

    # Group by politician (using full_name + politician_id)
    from collections import defaultdict
    by_candidate = defaultdict(list)
    for row in rows:
        pid = row.get('politician_id', '').strip()
        name = row.get('full_name', '').strip()
        key = (name, pid)
        by_candidate[key].append(row)

    total_stances = sum(len(v) for v in by_candidate.values())

    lines = []

    # Header
    lines.append(f"-- {'=' * 76}")
    lines.append(f"-- Migration {migration_num}: U.S. Senate Candidate Stances — {batch_label}")
    lines.append(f"-- {'=' * 76}")
    lines.append(f"-- Purpose: Insert/upsert federal stance data for {len(candidate_inventory)} non-incumbent 2026")
    lines.append(f"--   Senate candidates.")
    lines.append(f"--")
    lines.append(f"-- Topic scope: 30 federal-applicable topics (excludes city-level keys; data-centers excluded)")
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
        key = (name, pid)
        stances = by_candidate.get(key, [])
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
    for (name, pid), stances in sorted(by_candidate.items(), key=lambda x: x[0][0].split()[-1]):
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
