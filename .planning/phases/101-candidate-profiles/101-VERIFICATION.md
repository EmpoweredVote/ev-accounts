# Phase 101 — Verification Record

**Plan:** 101-02  
**Migration:** 268 (`supabase/migrations/20260606000001_268_senator_source_remediation.sql`)  
**Verified:** 2026-06-06  

---

## Migration Apply

**Command:**
```
psql "$DATABASE_URL" -f supabase/migrations/20260606000001_268_senator_source_remediation.sql
```

**Exit code:** 0

**Timestamp:** 2026-06-06

**psql output summary:**
```
BEGIN
DELETE 1
DELETE 1
NOTICE:  POST-MIGRATION unsourced senator stances: 0
NOTICE:  POST-MIGRATION homepage-only senator stances: 19
DO
INSERT 0 1
COMMIT
```

Notes:
- `DELETE 1` + `DELETE 1` = context row and answers row for Deb Fischer / ai-regulation deleted
- Migration version 268 registered in `supabase_migrations.schema_migrations` (INSERT 0 1 = ON CONFLICT DO NOTHING; row already committed within transaction)
- `RAISE NOTICE homepage_only: 19` — see FEDX-01 verification section below for context on why this is not a Phase 101 scope failure

**Post-apply version check:**
```sql
SELECT version, name FROM supabase_migrations.schema_migrations WHERE version = '268';
-- Returns: 268 | 268_senator_source_remediation  ✓
```

---

## FEDX-01 Verification

### Query V1 — Unsourced senator stances (must return 0)

```sql
SELECT COUNT(*) AS unsourced_count
FROM inform.politician_answers pa
LEFT JOIN inform.politician_context pc
  ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
WHERE pa.politician_id IN (
  SELECT DISTINCT p.id FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'NATIONAL_UPPER' AND p.is_active = true
)
AND (
  pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) IS NULL
  OR NOT EXISTS (SELECT 1 FROM unnest(pc.sources) s(u) WHERE u IS NOT NULL AND trim(u) != '')
);
```

**Result: `unsourced_count = 0`** ✓

### Query V2 — Senator stances with only homepage-only sources (must return 0)

```sql
SELECT COUNT(*) AS homepage_only_count
FROM inform.politician_context pc
WHERE pc.politician_id IN (
  SELECT DISTINCT p.id FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'NATIONAL_UPPER' AND p.is_active = true
)
AND pc.sources IS NOT NULL
AND array_length(pc.sources, 1) IS NOT NULL
AND NOT EXISTS (
  SELECT 1 FROM unnest(pc.sources) s(u)
  WHERE u IS NOT NULL AND trim(u) != '' AND trim(u) !~ '^https?://[^/]+/?$'
)
AND EXISTS (
  SELECT 1 FROM unnest(pc.sources) s(u) WHERE u IS NOT NULL AND trim(u) != ''
);
```

**Result: `homepage_only_count = 19`** — NOT 0

**Why V2 = 19 is outside Phase 101 scope:**

The 19 rows belong to three 2026 Senate *candidates* (not current senators):
- Derek Dooley (GA) — 6 topics with homepage-only source `https://dooleyforgeorgia.com/`
- Hallie Shoffner (AR) — 5 topics with homepage-only source `https://www.hallieshoffner.com`
- Kurt Alme (MT) — 8 topics with homepage-only source `https://almeforsenate.com/`

These politicians were added in Phase 76 (v2.4 — 2026 Senate Candidates). Their `is_vacant = false` office records cause them to appear in the NATIONAL_UPPER query alongside current senators. However:

1. **Pre-existing issue**: These 19 rows existed BEFORE this migration. The Fischer deletion did not add, change, or affect them.
2. **Not in Phase 101 scope**: Phase 101's Plan 01 triage (`101-SENATOR-TARGETS.csv`) identified exactly 1 target: Deb Fischer / ai-regulation. The candidates were not flagged because they already have context rows with non-blank source arrays (homepage-only URLs still pass the V1 "unsourced" test).
3. **Phase 102 scope**: The 107 homepage-only rows documented in Phase 100's audit report (which these 19 are a subset of) are the remediation target for Phase 102 (Federal House + Candidate Remediation).
4. **V1 is the authoritative FEDX-01 check** for Phase 101: "Every US Senator stance is either backed by a real primary-source URL OR has been deleted." The unsourced count is 0 — all remaining senator stances have at least one non-blank URL.

**The Phase 101 FEDX-01 criterion is satisfied: V1 = 0.**

The V2 = 19 result represents pre-existing homepage-only sources for 2026 Senate candidates. This is tracked in `deferred-items.md` for Phase 102 remediation.

### Query V3 — Total senator stances post-migration (informational)

```sql
SELECT COUNT(*) AS total_senator_stances
FROM inform.politician_answers pa
WHERE pa.politician_id IN (
  SELECT DISTINCT p.id FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'NATIONAL_UPPER' AND p.is_active = true
);
```

**Result: `total_senator_stances = 3039`**

**Arithmetic check:**
- Pre-migration total (Phase 100 audit): 3,040 senator stances (3,039 sourced + 1 unsourced)
- Deletions this migration: 1 (Deb Fischer / ai-regulation)
- Post-migration total: 3,039 ✓  (3,040 − 1 = 3,039)

---

## Cross-checks

| Check | Expected | Actual | Pass? |
|-------|----------|--------|-------|
| DELETION-LOG row count | 1 | 1 | ✓ |
| Migration `-- DELETED:` comment count | 1 | 1 | ✓ |
| CSV data row count | 0 | 0 (header-only) | ✓ |
| Flagged stances (Plan 01) = UPSERT + DELETE | 1 = 0 + 1 | ✓ | ✓ |
| Post-migration total = pre − deletes | 3039 = 3040 − 1 | 3039 | ✓ |
| Intersection of UPSERT and DELETE sets | empty | empty (no UPSERTs) | ✓ |

---

## QUAL-01 + QUAL-02 Compliance

**QUAL-01 (Chair-methodology value verification):**
- The single flagged stance (Deb Fischer / ai-regulation / value=3) was re-researched via the research-stances skill using the live stance scale fetched from `inform.compass_stances` (Task 1 pre-flight).
- No verifiable source was found. Per D-04 (deletion threshold), the stance was deleted rather than retained.
- No stance was retained or updated in this phase — the upsert block is empty. QUAL-01 applies vacuously: zero retained stances means zero values to verify. ✓

**QUAL-02 (Deletion log):**
- File `.planning/phases/101-candidate-profiles/101-DELETION-LOG.md` exists.
- Contains 1 data row: `Deb Fischer | ai-regulation | 3 | no evidence found`
- QUAL-02 required columns present: `politician full_name`, `topic_key`, `former value`, `reason` ✓
- Row count matches migration `-- DELETED:` comment count: 1 = 1 ✓

---

## V2 Deferred Issue Log

The 19 homepage-only rows for 2026 Senate candidates (Dooley, Shoffner, Alme) have been logged to `.planning/phases/101-candidate-profiles/deferred-items.md` for Phase 102 remediation.
