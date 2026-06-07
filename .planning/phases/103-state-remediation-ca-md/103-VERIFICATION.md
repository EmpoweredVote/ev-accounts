# Phase 103 — CA State Source Remediation: Verification Record

**Plan:** 103-02
**Migration applied:** 282
**Migration file:** supabase/migrations/20260606000005_282_ca_state_source_remediation.sql
**Verification date:** 2026-06-06

---

## Migration Apply

**Command:**
```bash
cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
  psql "$DATABASE_URL" -f /c/EV-Accounts/supabase/migrations/20260606000005_282_ca_state_source_remediation.sql
```

**Exit code:** 0 (success)

**Timestamp:** 2026-06-06

**psql output summary:**
- 24 × `INSERT 0 1` (12 politician_answers + 12 politician_context upserts)
- 12 × `DELETE 1` (6 context deletes + 6 answers deletes)
- `DO` (RAISE NOTICE block executed)
- `INSERT 0 1` (migration registration)
- `COMMIT`

**RAISE NOTICE output (from POST-STATE block):**
```
NOTICE:  POST-MIGRATION CA STATE unsourced stances: 0
NOTICE:  POST-MIGRATION CA STATE weak-source stances: 0
```

**Post-apply MAX(version) check:**
```sql
SELECT MAX(version) FROM supabase_migrations.schema_migrations WHERE length(version) <= 5 AND version ~ '^[0-9]+$';
-- Result: 282 ✓
```

---

## STAX-01 Verification

### Query V1 — CA State Unsourced Stance Count

**Target:** 0

**SQL:**
```sql
SELECT COUNT(*) AS ca_unsourced_count
FROM inform.politician_answers pa
JOIN essentials.politicians p ON p.id = pa.politician_id
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON d.id = o.district_id
  AND d.district_type IN ('STATE_LOWER','STATE_UPPER','STATE_EXEC')
  AND d.state = 'CA'
  AND p.is_active = true
  AND COALESCE(o.is_vacant, false) = false
LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
WHERE (
  pc.politician_id IS NULL
  OR pc.sources IS NULL
  OR array_length(pc.sources, 1) IS NULL
  OR NOT EXISTS (SELECT 1 FROM unnest(pc.sources) s(u) WHERE u IS NOT NULL AND trim(u) != '')
);
```

**Result:** `ca_unsourced_count = 0` — **PASS**

---

### Query V2 — CA State Weak-Source Stance Count

**Target:** 0

**SQL:**
```sql
SELECT COUNT(*) AS ca_weak_source_count
FROM inform.politician_answers pa
JOIN essentials.politicians p ON p.id = pa.politician_id
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON d.id = o.district_id
  AND d.district_type IN ('STATE_LOWER','STATE_UPPER','STATE_EXEC')
  AND d.state = 'CA'
  AND p.is_active = true
  AND COALESCE(o.is_vacant, false) = false
JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
WHERE NOT EXISTS (
  SELECT 1 FROM unnest(pc.sources) AS s(url)
  WHERE url IS NOT NULL AND trim(url) <> ''
    AND url !~ '^https?://[^/]+/?$'
);
```

**Result:** `ca_weak_source_count = 0` — **PASS**

---

### Query V3 — Informational: Flagged-Politician Stance Totals

**SQL:**
```sql
SELECT COUNT(*) AS flagged_politician_stance_total
FROM inform.politician_answers
WHERE politician_id IN (
  'e5470008-3c0d-4970-a485-053621d8f0a6',  -- Akilah Weber Pierson
  '4baa73c2-d38b-4d07-894f-1577d5ba43a3',  -- Caroline Menjivar
  '0649630c-bd6d-40fe-8f66-e026e6f6c83e',  -- Catherine Stefani
  '1571da4a-b832-4792-917c-184c155b1700',  -- Eloise Gómez Reyes
  'f26309c8-2525-49b2-bdaf-62980cbb1853',  -- Gavin Newsom
  '21940b7c-2424-47e9-a649-077b0f827c2c',  -- Gregg Hart
  'f3671de4-514f-441c-8ad4-4a9ab7c65ae6',  -- Henry Stern
  'b959d608-5674-467e-a1c8-3572c76a729b',  -- Juan Carrillo
  '0afa998d-94e9-4af4-ba00-256c38869398',  -- Lisa Calderon
  '3f200d93-74aa-4191-a275-77b64ff5b219',  -- Natasha Johnson
  '8b183a30-3afb-4d9e-aa40-aa2ad2c674aa'   -- Rob Bonta
);
```

**Result:** `flagged_politician_stance_total = 209`

*Pre-migration: 209 + 6 (deletions) - 12 (net new upserts already present as updates) = effectively 203 net retained (6 deleted, 12 confirmed/corrected).*

---

## Cross-Checks

| Check | Expected | Actual | Pass/Fail |
|-------|----------|--------|-----------|
| 103-DELETION-LOG.md row count | 6 | 6 | PASS |
| Migration `-- DELETED:` comment count | 6 | 6 | PASS |
| Research CSV data row count | 12 | 12 | PASS |
| Migration UPSERT count (politician_answers INSERT lines) | 12 | 12 | PASS |
| UPSERT + DELETE = Plan 01 flagged stance count | 18 | 12 + 6 = 18 | PASS |
| Intersection of UPSERT and DELETE (politician_id, topic_id) pairs | empty | empty | PASS |
| MAX(version) post-apply | 282 | 282 | PASS |

*Intersection check: Gómez Reyes has UPSERT for campaign-finance and DELETE for religious-freedom + ukraine-support — no (politician_id, topic_id) pair appears in both blocks. Henry Stern has only DELETEs. Rob Bonta has only DELETE. All other politicians have only UPSERTs. Empty intersection confirmed.*

---

## ARRAY_CAT Pattern Audit

**Classification from 103-RESEARCH-NOTES.md:** 6 pairs classified as ARRAY_CAT (existing context rows with homepage-only sources that must be preserved per CONTEXT.md D-05).

**Spot-check: Akilah Weber Pierson / fossil-fuels**
- politician_id: `e5470008-3c0d-4970-a485-053621d8f0a6`
- Pre-migration array_length: **1** (sources: `{https://sd39.senate.ca.gov}`)
- Post-migration array_length: **2** (sources: `{https://sd39.senate.ca.gov, https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB1137}`)

```sql
SELECT politician_id, topic_id, array_length(sources, 1) AS post_migration_length, sources
FROM inform.politician_context
WHERE politician_id = 'e5470008-3c0d-4970-a485-053621d8f0a6'
  AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'fossil-fuels');
-- Result: post_migration_length = 2, sources = {https://sd39.senate.ca.gov, https://leginfo...SB1137}
```

**Verdict:** Post-migration array_length (2) > pre-migration array_length (1). ARRAY_CAT pattern confirmed — source history preserved. **PASS**

All 6 ARRAY_CAT pairs used `sources = politician_context.sources || EXCLUDED.sources` in the ON CONFLICT clause. The remaining 6 PLAIN_OVERWRITE pairs used `sources = EXCLUDED.sources` (no prior history to preserve — empty sources arrays confirmed at Task 1 Step E).

---

## QUAL-01 + QUAL-02 Compliance

**QUAL-01 (Chair-text value verification):** Every retained or updated stance value was verified against the exact Chair text for that topic value by the research-stances skill in Task 2 (human-verify checkpoint approved by operator 2026-06-06). No party-affiliation inference was used. Spot-check sources confirmed at checkpoint.

**QUAL-02 (Deletion log):** `.planning/phases/103-state-remediation-ca-md/103-DELETION-LOG.md` committed with 6 rows in the required format (`politician full_name | topic_key | former value | reason`). Deletion log row count (6) equals migration `-- DELETED:` comment count (6). ✓

---

## STAX-01 Closure

**CA state remediation is complete.**

- Query V1 (CA state unsourced stance count): **0** — PASS
- Query V2 (CA state weak-source stance count): **0** — PASS
- Migration 282 applied to live DB with exit code 0
- All 11 flagged CA politicians remediated: 12 upserts + 6 deletions = 18 flagged stances resolved
- ARRAY_CAT source history preserved for 6 pairs (Weber Pierson, Menjivar, Stefani, Gómez Reyes, Hart, Johnson)
- PLAIN_OVERWRITE applied for 6 pairs (Newsom×4, Carrillo, Calderon) — no prior history to preserve

STAX-01 is **SATISFIED** for the CA scope (STATE_LOWER, STATE_UPPER, STATE_EXEC, state = 'CA').
