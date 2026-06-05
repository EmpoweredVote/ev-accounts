import csv, re
from collections import defaultdict

# Topic UUIDs (from DB, is_live=true)
topic_uuids = {
    'abortion':                  'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
    'ai-regulation':             '666bf03d-81fc-4138-ab15-69ae734c9023',
    'campaign-finance':          '92730f69-ae57-401c-8ad1-2d07834a895d',
    'civil-rights':              '0bc588c6-39e1-4084-b5de-cac909b8b762',
    'climate-change':            'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
    'economic-development':      'eb3d1247-0de1-4b7f-baec-7259861efd53',
    'fossil-fuels':              'a22215c3-6693-4bc2-b248-01aebba14570',
    'healthcare':                'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
    'housing':                   '669cac97-66a6-4087-b036-936fbe62efb3',
    'immigration':               '4e2c69ce-591e-4197-9cd5-7aceff79d390',
    'judicial-criminal-justice': '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
    'misinformation':            'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
    'redistricting':             '48cc9585-ec22-4f53-8d42-6839828dd36f',
    'religious-freedom':         '6b9ba6d9-1001-43f5-b073-4d37130696fd',
    'same-sex-marriage':         'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
    'school-vouchers':           '00b95a6a-75db-4521-b523-3326bba938de',
    'social-security':           '87d20824-a6e9-407b-983c-65440084a0ab',
    'tariffs':                   '683c8084-2281-4920-a07c-18439b2dd413',
    'taxes':                     'f7e5678d-dadd-4556-a2fc-446e24642ceb',
    'trans-athletes':            'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
    'ukraine-support':           '24e9212c-b011-422a-865c-093e35050901',
    'voting-rights':             'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
}

# Candidate UUIDs (from DB)
candidate_info = {
    '-400101': ('a9e04e1e-92d4-44e4-a411-b6fe4814290a', 'Steve Marshall', 'AL', 'R'),
    '-400102': ('3428e87f-dc47-4033-9f6a-6fe63ffc9fc9', 'Barry Moore', 'AL', 'R'),
    '-400103': ('98480c0b-2b26-4098-a830-a2efd88fed29', 'Dakarai Larriett', 'AL', 'D'),
    '-400104': ('6a2e7d16-5073-40c3-a41c-1eab2d7ae8ba', 'Mary Peltola', 'AK', 'D'),
    '-400105': ('a7307f34-90ca-4d29-8698-4898ed3de05c', 'Hallie Shoffner', 'AR', 'D'),
    '-400106': ('07a45a9b-7726-41bd-8f67-722b865345ec', 'Janak Joshi', 'CO', 'R'),
    '-400107': ('a2fee754-f90c-47ff-a3b7-377d55992273', 'Alex Vindman', 'FL', 'D'),
    '-400108': ('0ac89151-2b8d-4430-b9bd-3a80bef3413b', 'Angie Nixon', 'FL', 'D'),
    '-400109': ('ce8d48a3-5137-4521-81cd-8a86c0999b37', 'Mike Collins', 'GA', 'R'),
    '-400110': ('b841a475-41b4-4f19-9ad1-13769b1f4eef', 'Derek Dooley', 'GA', 'R'),
    '-400111': ('bc9ec968-d664-4987-8f9c-108f9ae51535', 'David Roth', 'ID', 'D'),
    '-400112': ('965ffd53-89a8-46cc-adb1-16bf588ed1c3', 'Juliana Stratton', 'IL', 'D'),
    '-400113': ('a6f10769-ec53-456f-afbd-2a89d3ac84b2', 'Don Tracy', 'IL', 'R'),
    '-400114': ('bd20ceb6-2c9c-4ad2-b259-793b98a5a4c1', 'Ashley Hinson', 'IA', 'R'),
    '-400115': ('db66036a-2a1f-4bcf-980e-2f29a336dc5f', 'Zach Wahls', 'IA', 'D'),
}

# Read CSV
rows = []
with open('C:/EV-Accounts/backend/data/stance-research/2026-05-22-us-senate-candidates-batch1.csv') as f:
    reader = csv.DictReader(f)
    for row in reader:
        if row['full_name']:
            rows.append(row)

by_candidate = defaultdict(list)
for row in rows:
    by_candidate[row['external_id']].append(row)


def dollar_quote(text):
    if '$$' in text:
        return '$REASON$' + text + '$REASON$'
    return '$$' + text + '$$'


def build_sources(row):
    srcs = []
    for k in ['source_url_1', 'source_url_2', 'source_url_3']:
        v = row.get(k, '').strip()
        if v:
            srcs.append("'" + v + "'")
    if not srcs:
        return "ARRAY[]::text[]"
    return "ARRAY[" + ",\n              ".join(srcs) + "]::text[]"


lines = []
lines.append("-- ============================================================================")
lines.append("-- Migration 197: U.S. Senate Candidate Stances -- Batch 1 of 3 (AL to IA)")
lines.append("-- ============================================================================")
lines.append("-- Purpose: Insert/upsert federal stance data for 15 non-incumbent 2026")
lines.append("--   Senate candidates created in Phase 75 (external_ids -400101 to -400115).")
lines.append("--")
lines.append("-- Source CSV: backend/data/stance-research/2026-05-22-us-senate-candidates-batch1.csv")
lines.append("-- Topic scope: 22 of 30 federal topics with evidence for these candidates")
lines.append("-- (excludes city-level keys; data-centers excluded per Phase 76 SRES-01)")
lines.append("--")
lines.append("-- Pre-state:  COUNT(*) from inform.politician_answers where politician_id")
lines.append("--             IN (15 candidate UUIDs) = 0 (confirmed Phase 76 research)")
lines.append("-- Post-state: 165 rows (15 candidates, 10-12 topics each)")
lines.append("--")
lines.append("-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.")
lines.append("-- Applied to remote Supabase via Supabase MCP apply_migration.")
lines.append("-- ============================================================================")
lines.append("")
lines.append("-- Topic UUID reference (inform.compass_topics where is_live = true):")
for tk, tid in sorted(topic_uuids.items()):
    lines.append("-- %-28s %s" % (tk, tid))
lines.append("")
lines.append("BEGIN;")
lines.append("")

for ext_id in sorted(by_candidate.keys(), key=lambda x: int(x)):
    uuid, name, state, party = candidate_info[ext_id]
    stances = by_candidate[ext_id]

    lines.append("-- ============================================================")
    lines.append("-- %s (%s, %s, %s)" % (name, state, party, ext_id))
    lines.append("-- ============================================================")
    lines.append("")

    for stance in stances:
        topic_key = stance['topic_key']
        topic_id = topic_uuids[topic_key]
        value = stance['value']
        reasoning = stance['reasoning']
        sources_arr = build_sources(stance)

        lines.append("-- ----- %s / %s -----" % (name, topic_key))
        lines.append("INSERT INTO inform.politician_answers (politician_id, topic_id, value)")
        lines.append("VALUES ('%s'," % uuid)
        lines.append("        '%s'," % topic_id)
        lines.append("        %s)" % value)
        lines.append("ON CONFLICT (politician_id, topic_id)")
        lines.append("DO UPDATE SET value = EXCLUDED.value;")
        lines.append("")
        lines.append("INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)")
        lines.append("VALUES ('%s'," % uuid)
        lines.append("        '%s'," % topic_id)
        lines.append("        %s," % dollar_quote(reasoning))
        lines.append("        %s)" % sources_arr)
        lines.append("ON CONFLICT (politician_id, topic_id)")
        lines.append("DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;")
        lines.append("")

lines.append("COMMIT;")
lines.append("")
lines.append("-- ============================================================================")
lines.append("-- Verification queries (run after migration to confirm correctness)")
lines.append("-- ============================================================================")
lines.append("")

uuids_list = [candidate_info[k][0] for k in sorted(candidate_info.keys())]
uuids_sql = ",\n     ".join("'%s'" % u for u in uuids_list)

lines.append("-- 1. Per-candidate row count (every candidate must have topic_count >= 10):")
lines.append("-- SELECT p.full_name, p.external_id, COUNT(pa.topic_id) AS topic_count")
lines.append("-- FROM essentials.politicians p")
lines.append("-- LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id")
lines.append("-- WHERE p.id IN (")
lines.append("--      %s" % uuids_sql)
lines.append("-- )")
lines.append("-- GROUP BY p.id, p.full_name, p.external_id")
lines.append("-- ORDER BY topic_count, p.full_name;")
lines.append("")
lines.append("-- 2. Context pairing (must return 0):")
lines.append("-- SELECT COUNT(*) FROM inform.politician_answers pa")
lines.append("-- LEFT JOIN inform.politician_context pc")
lines.append("--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id")
lines.append("-- WHERE pa.politician_id IN (")
lines.append("--      %s" % uuids_sql)
lines.append("-- )")
lines.append("--   AND pc.id IS NULL;")
lines.append("")
lines.append("-- 3. Sources non-empty (must return 0):")
lines.append("-- SELECT COUNT(*) FROM inform.politician_context")
lines.append("-- WHERE politician_id IN (")
lines.append("--      %s" % uuids_sql)
lines.append("-- )")
lines.append("--   AND (sources IS NULL OR array_length(sources, 1) = 0);")
lines.append("")
lines.append("-- 4. Topic scope sanity (must return 0 rows):")
lines.append("-- SELECT t.topic_key, COUNT(*)")
lines.append("-- FROM inform.politician_answers pa")
lines.append("-- JOIN inform.compass_topics t ON t.id = pa.topic_id")
lines.append("-- WHERE pa.politician_id IN (")
lines.append("--      %s" % uuids_sql)
lines.append("-- )")
lines.append("--   AND t.topic_key IN ('data-centers', 'transportation-priorities',")
lines.append("--                       'local-immigration', 'residential-zoning')")
lines.append("-- GROUP BY t.topic_key;")

sql = "\n".join(lines)
with open('C:/EV-Accounts/backend/migrations/197_us_senate_candidate_stances_batch1.sql', 'w', encoding='utf-8') as f:
    f.write(sql)

line_count = len(sql.split('\n'))
answer_inserts = len(re.findall(r'INSERT INTO inform\.politician_answers', sql))
context_inserts = len(re.findall(r'INSERT INTO inform\.politician_context', sql))
on_conflict = len(re.findall(r'ON CONFLICT', sql))
print("Migration written: %d lines" % line_count)
print("politician_answers INSERTs: %d" % answer_inserts)
print("politician_context INSERTs: %d" % context_inserts)
print("ON CONFLICT clauses: %d" % on_conflict)
print("Expected: %d pairs = %d total INSERTs" % (len(rows), len(rows)*2))
