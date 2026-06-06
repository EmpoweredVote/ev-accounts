# Phase 103 — MD Officials Verification Record

**Phase:** 103 — State Remediation CA + MD (Plan 03)
**Migration:** 279
**Verified:** 2026-06-06
**Requirements:** STAX-02, QUAL-01

---

## Migration Apply

**Command:** `psql "$DATABASE_URL" -f supabase/migrations/20260606000004_279_md_officials_stances.sql`
**Exit code:** 0
**Timestamp:** 2026-06-06

**psql NOTICE output:**
```
POST-MIGRATION MD officials with zero stances: 0
POST-MIGRATION MD stances without source URL: 0
```

**Row counts from migration output:** 46 INSERTs (23 politician_answers + 23 politician_context), 0 DELETEs, COMMIT ✓

**MAX(version) post-apply:** 279 ✓

---

## STAX-02 Verification — Query V3 (every MD official has > 0 stances)

**Query:**
```sql
SELECT p.full_name, COUNT(pa.topic_id) AS stance_count
FROM essentials.politicians p
LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
WHERE p.id = ANY(ARRAY[
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  'ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
  '60329719-1d5b-4bb4-8295-38ea18f6f378',
  'b26fb5d2-90eb-4108-8ce5-838df719473d',
  '75378a96-8886-46eb-b0c1-37cbe2579265'
]::uuid[])
GROUP BY p.full_name
ORDER BY stance_count ASC;
```

**Result:**

| full_name | stance_count |
|-----------|-------------|
| Dereck E. Davis | 2 |
| Anthony G. Brown | 3 |
| Aruna Miller | 5 |
| Brooke Lierman | 5 |
| Wes Moore | 8 |

**Status: PASS** — All 5 MD officials have stance_count > 0. STAX-02 V3 criterion satisfied.

---

## STAX-02 Verification — Sourced Check (every MD stance has real URL)

**Query:**
```sql
SELECT COUNT(*) AS md_unsourced_count
FROM inform.politician_answers pa
LEFT JOIN inform.politician_context pc
  ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
WHERE pa.politician_id = ANY(ARRAY[
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  'ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
  '60329719-1d5b-4bb4-8295-38ea18f6f378',
  'b26fb5d2-90eb-4108-8ce5-838df719473d',
  '75378a96-8886-46eb-b0c1-37cbe2579265'
]::uuid[])
AND (
  pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) IS NULL
  OR NOT EXISTS (SELECT 1 FROM unnest(pc.sources) s(u) WHERE u IS NOT NULL AND trim(u) != '')
);
```

**Result:** `md_unsourced_count = 0`

**Status: PASS** — Every MD stance has at least one non-blank source URL in politician_context.

---

## STAX-02 Verification — Homepage-Only Check (no weak sources)

**Query:**
```sql
SELECT COUNT(*) AS md_weak_source_count
FROM inform.politician_context pc
WHERE pc.politician_id = ANY(ARRAY[
  '21e534c8-c0c0-42f5-b52b-5eb2f246d632',
  'ea9fc2d6-3b26-469a-978c-e8c846d2d49a',
  '60329719-1d5b-4bb4-8295-38ea18f6f378',
  'b26fb5d2-90eb-4108-8ce5-838df719473d',
  '75378a96-8886-46eb-b0c1-37cbe2579265'
]::uuid[])
AND NOT EXISTS (
  SELECT 1 FROM unnest(pc.sources) AS u(url)
  WHERE url IS NOT NULL AND trim(url) <> ''
    AND url !~ '^https?://[^/]+/?$'
);
```

**Result:** `md_weak_source_count = 0`

**Status: PASS** — No MD stance has only homepage-pattern source URLs. All sources are specific pages.

---

## Per-Official Stance Count

| Full Name (DB-canonical) | stance_count (DB post-migration) | applicable_topics | topics_with_value | topics_skipped |
|--------------------------|----------------------------------|-------------------|-------------------|----------------|
| Wes Moore | 8 | 25 | 8 | 17 |
| Aruna Miller | 5 | 25 | 5 | 20 |
| Anthony G. Brown | 3 | 25 | 3 | 22 |
| Brooke Lierman | 5 | 25 | 5 | 20 |
| Dereck E. Davis | 2 | 25 | 2 | 23 |
| **TOTAL** | **23** | **125** | **23** | **102** |

Applicable topics: 25 (44 live total minus 19 excluded city/judicial tier topics per SKILL.md skip list).
Skipped topics per official: no evidence found meeting QUAL-01 standard — per CONTEXT.md D-06, single-pass rule applies; no retry loops; skipped topics simply have no stance row.

---

## Cross-Checks

| Check | Expected | Actual | Status |
|-------|----------|--------|--------|
| CSV data rows | 23 | 23 | ✓ |
| Migration INSERT INTO politician_answers count | 23 | 23 | ✓ |
| Migration INSERT INTO politician_context count | 23 | 23 | ✓ |
| Post-migration DB stance count (5 MD officials) | 23 | 23 | ✓ |
| DELETE FROM statements in migration | 0 | 0 | ✓ |
| ARRAY_CAT occurrences in migration | 0 | 0 | ✓ |
| MAX(version) post-migration | 279 | 279 | ✓ |
| V3: MD officials with zero stances | 0 | 0 | ✓ |
| Sourced check: MD stances without URL | 0 | 0 | ✓ |
| Homepage-only check: MD weak sources | 0 | 0 | ✓ |

All cross-checks pass. CSV row count = migration INSERT count = post-migration MD stance total = 23.

---

## QUAL-01 Compliance

Every value added in this plan was verified against the specific Chair text for that topic at the Task 2 human-verify checkpoint. The checkpoint required spot-checking 3 source URLs (one each for Moore, Brown, and one other official) — all passed. No stance value was inferred from party affiliation. All values match specific documented positions (legislation co-sponsored, lawsuits filed, campaign statements, signed bills). QUAL-01 satisfied.

---

## STAX-02 Closure

MD fresh research is complete. All 5 MD executive branch officials now have > 0 stances in inform.politician_answers:

- Wes Moore (Governor): **8 stances** (abortion, childcare, civil-rights, climate-change, fossil-fuels, immigration, tariffs, taxes)
- Aruna Miller (Lt. Governor): **5 stances** (civil-rights, climate-change, fossil-fuels, healthcare, same-sex-marriage)
- Anthony G. Brown (Attorney General): **3 stances** (abortion, civil-rights, immigration)
- Brooke Lierman (Comptroller): **5 stances** (abortion, civil-rights, climate-change, immigration, school-vouchers)
- Dereck E. Davis (Treasurer): **2 stances** (civil-rights, taxes)

Total MD stances added: **23**

STAX-02 success criteria satisfied:
1. Every MD official in DB has > 0 stances — V3 confirms 0 officials remain at zero.
2. Every MD stance has a paired context row with at least one non-blank non-homepage URL — sourced-check confirms md_unsourced_count = 0 and homepage-only check confirms md_weak_source_count = 0.

---

## Note on QUAL-02

QUAL-02 (deletion log requirement) does **NOT** apply to this plan. Per CONTEXT.md D-04: MD officials had zero existing stances before migration 279. There were no incorrect, homepage-only, or outdated stance rows to delete. The deletion log requirement applies only where prior stances existed and were removed — which is Plan 02's domain (CA officials with sourcing problems). QUAL-02 for Phase 103 overall is satisfied by Plan 02's CA deletion log.

No deletion log entries were produced by this plan. No DELETE statements appear in migration 279.
