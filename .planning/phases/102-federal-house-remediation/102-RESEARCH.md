# Phase 102: Federal House Remediation - Research

**Researched:** 2026-06-06
**Domain:** Data quality / source remediation — US House representative stances in `inform.politician_answers`
**Confidence:** HIGH

---

## Summary

Phase 102 follows the Phase 101 pattern exactly, but the target population is US House representatives (`district_type = 'NATIONAL_LOWER'`) instead of senators. Live DB queries run during this research session establish the full ground truth before any planning decision is made.

**Critical finding:** The 36 House representatives who currently have stances in `inform.politician_answers` are ALL fully sourced and have no weak-sourced stances. The NATIONAL_LOWER population returns `unsourced_count = 0, weak_stances = 0` when the Phase 100/101 sourced definition is applied. The primary remediation target for Phase 102 is not NATIONAL_LOWER incumbents — it is the three 2026 Senate candidates (Dooley, Shoffner, Alme) deferred from Phase 101 whose 19 homepage-only-sourced stances were logged in `101-VERIFICATION.md` and `deferred-items.md`.

**Secondary finding:** There are 86 NATIONAL_LOWER incumbents in the DB who have zero stances at all. This is explicitly out of scope per REQUIREMENTS.md ("Adding stances for politicians not currently in DB" is Out of Scope — the 86 no-stance reps are analogous to the 64 senator topics that were never seeded, not to remediation targets). The triage script will confirm this zero-flagged state.

**Primary recommendation:** Phase 102 is structured as: (1) triage script confirming zero NATIONAL_LOWER unsourced/weak stances, (2) remediation of the 3 deferred Senate candidates (Dooley, Shoffner, Alme) whose 19 homepage-only stances are NATIONAL_UPPER-classified and block the V2 verification from returning 0. The phase is a 2-plan phase: Plan 01 = triage script + confirmation, Plan 02 = research + migration for the 3 candidates.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| NATIONAL_LOWER triage query | Database | Script layer | Same pattern as Phase 101 — pool.query() direct postgres; inform schema not in PostgREST |
| Candidate homepage-source remediation | Database | Research skill | Re-research via research-stances skill → migration UPSERT/DELETE |
| Deletion log (QUAL-02) | Repo file | Migration comment | Committed .md file mirrors the migration's `-- DELETED:` comments |
| FEDX-02 verification | Database | Phase docs | Success-criteria SQL queries run post-migration to confirm 0 count |

---

## Standard Stack

No new packages. Phase 102 is a data + script phase using the same tooling as Phase 101:

| Tool | Purpose | Source |
|------|---------|--------|
| `pg.Pool` (already installed) | All inform.* queries — direct postgres, never PostgREST | [ASSUMED: established pattern] |
| `npx tsx` | Run triage script | [ASSUMED: established pattern] |
| `psql` | Apply migration via session pooler | [ASSUMED: established pattern] |
| research-stances skill | Re-research Dooley/Shoffner/Alme stances | [ASSUMED: project skill] |

**Installation:** None required — all tooling already present from Phase 101.

---

## Package Legitimacy Audit

No new packages are installed in this phase. Section not applicable.

---

## Live DB State (Verified 2026-06-06)

These numbers are VERIFIED against the live production DB and drive all planning decisions.

### NATIONAL_LOWER Population

| Metric | Value | Source |
|--------|-------|--------|
| NATIONAL_LOWER incumbent politicians (is_active=true, is_incumbent=true) | 122 | [VERIFIED: live DB query] |
| NATIONAL_LOWER incumbents WITH stances | 36 | [VERIFIED: live DB query] |
| NATIONAL_LOWER incumbents WITHOUT any stances | 86 | [VERIFIED: live DB query] |
| Unsourced stances for NATIONAL_LOWER incumbents | **0** | [VERIFIED: live DB query] |
| Weak-sourced stances for NATIONAL_LOWER incumbents | **0** | [VERIFIED: live DB query] |

### NATIONAL_LOWER Incumbents With Stances — State Breakdown

| State | Reps With Stances | Total NATIONAL_LOWER Incumbents |
|-------|-------------------|----------------------------------|
| CA | 16 | 52 |
| MA | 9 | 9 (all MA reps have stances) |
| OR | 6 | 6 (all OR reps have stances) |
| UT | 4 | 4 (all UT reps have stances) |
| IN | 1 | 4 |
| TX | 0 | 37 |
| MD | 0 | 8 |
| ME | 0 | 2 |

### 86 NATIONAL_LOWER Incumbents Without Stances — Out of Scope

These 86 politicians have no rows in `inform.politician_answers`. Per REQUIREMENTS.md Out of Scope clause: "Adding stances for politicians not currently in DB" — the 86 have DB records (essentials.politicians rows) but zero stance rows. They are not remediation targets because there is nothing to remediate; they are future data-addition work outside v2.7.

The triage script (Plan 01) will confirm these 86 produce no rows in its output (correct: the triage query joins `inform.politician_answers`, so politicians with zero stances produce zero rows in the triage output).

### Deferred Candidates (from Phase 101 — INCLUDED in Phase 102 scope)

| Politician | NATIONAL_UPPER is_incumbent | Stance Count | Weak Stances | Homepage URL |
|------------|---------------------------|-------------|-------------|-------------|
| Derek Dooley | false (2026 GA Senate candidate) | 12 total, 6 weak | abortion, civil-rights, climate-change, healthcare, immigration, voting-rights | https://dooleyforgeorgia.com/ |
| Hallie Shoffner | false (2026 AR Senate candidate) | 11 total, 5 weak | campaign-finance, climate-change, economic-development, housing, taxes | https://www.hallieshoffner.com |
| Kurt Alme | false (2026 MT Senate candidate) | 13 total, 8 weak | abortion, fossil-fuels, religious-freedom, same-sex-marriage, social-security, tariffs, trans-athletes, voting-rights | https://almeforsenate.com/ |

These three are is_incumbent=false, NATIONAL_UPPER-classified. They were NOT captured by the Phase 101 triage (which filtered is_incumbent=true). The Phase 101 V2 query returned 19 (not 0) because of these 3 candidates. Phase 102 owns their remediation per the deferred-items.md commitment.

Note: Kurt Alme has some stances with both a homepage URL AND a real source URL — 5 topics have homepage-only, 8 stances total are weak. The DB query confirmed all 19 weak stances belong to these three candidates exclusively.

### Next Migration Number

`SELECT MAX(version) FROM supabase_migrations.schema_migrations` returns `268`. [VERIFIED: live DB query]

Next available migration number: **269**.

---

## Architecture Patterns

### System Architecture Diagram

```
DB Query (NATIONAL_LOWER triage)
  → pool.query() [inform schema — not PostgREST]
    → DISTINCT ON (p.id) CTE: essentials.politicians
      × essentials.offices (is_vacant=false)
      × essentials.districts (district_type='NATIONAL_LOWER')
    → LEFT JOIN inform.politician_answers
    → LEFT JOIN inform.politician_context
  → Apply SOURCED_CASE / UNSOURCED_CASE / HOMEPAGE_ONLY_REGEX
  → Output: 102-TRIAGE-REPORT.md + 102-HOUSE-TARGETS.csv

Deferred Candidate Research
  → research-stances skill [one at a time]
    → WebFetch: Ballotpedia, official pages, ontheissues.org
    → CSV output: YYYY-MM-DD-candidate-remediation.csv
  → Human spot-check (QUAL-01 verification)
  → Migration SQL: UPSERT inform.politician_answers + inform.politician_context
                    DELETE stances with no real source found
  → psql session pooler apply
  → FEDX-02 verification queries (V1=0 required; V2=0 required)

Deletion log
  → .planning/phases/102-federal-house-remediation/102-DELETION-LOG.md
```

### Recommended Project Structure

```
backend/scripts/
└── run-house-source-triage.ts      # New — adapts run-senator-source-triage.ts for NATIONAL_LOWER + candidate scope

backend/data/stance-research/
└── YYYY-MM-DD-candidate-remediation.csv  # research-stances output for 3 deferred candidates

supabase/migrations/
└── YYYYMMDDNNNNNN_269_house_source_remediation.sql  # UPSERT + DELETE for candidates

.planning/phases/102-federal-house-remediation/
├── 102-TRIAGE-REPORT.md             # Plan 01 output
├── 102-HOUSE-TARGETS.csv            # Plan 01 output
├── 102-DELETION-LOG.md              # QUAL-02 (written during Plan 02)
├── 102-RESEARCH-NOTES.md            # Research batch log (Plan 02)
└── 102-VERIFICATION.md              # Post-migration verification (Plan 02)
```

### Pattern 1: House Triage CTE (adapts senate_politicians CTE)

The Phase 101 `SENATE_POLITICIANS_CTE` is adapted by changing `district_type = 'NATIONAL_UPPER'` to `district_type = 'NATIONAL_LOWER'` and removing the `is_incumbent = true` filter (since NATIONAL_LOWER already returns no non-incumbent rows per the live DB query — all 122 NATIONAL_LOWER active politicians are is_incumbent=true).

The deferred candidates (Dooley, Shoffner, Alme) are NATIONAL_UPPER, not NATIONAL_LOWER. The triage script should include a SECOND sub-query for non-incumbent NATIONAL_UPPER politicians to capture these candidates. Alternatively, the script can query them separately by politician_id and include them in the combined target list.

**Recommended approach for run-house-source-triage.ts:**
- Query 1: NATIONAL_LOWER politicians (same pattern as senator triage, district_type='NATIONAL_LOWER') — expected result: 0 flagged
- Query 2: Non-incumbent NATIONAL_UPPER politicians with homepage-only sources (the 3 deferred candidates) — expected result: 3 flagged (19 weak stances total)
- Combine results in the triage report

```typescript
// Source: adapted from backend/scripts/run-senator-source-triage.ts [ASSUMED]
const HOUSE_POLITICIANS_CTE = `
  house_politicians AS (
    SELECT DISTINCT ON (p.id)
      p.id,
      p.full_name,
      p.party,
      d.state
    FROM essentials.politicians p
    JOIN essentials.offices o
      ON o.politician_id = p.id
      AND o.is_vacant = false
    JOIN essentials.districts d
      ON d.id = o.district_id
      AND d.district_type = 'NATIONAL_LOWER'
    WHERE p.is_active = true
    ORDER BY p.id
  )`;

const CANDIDATE_DEFERRED_CTE = `
  deferred_candidates AS (
    SELECT DISTINCT ON (p.id)
      p.id,
      p.full_name,
      p.party,
      d.state
    FROM essentials.politicians p
    JOIN essentials.offices o
      ON o.politician_id = p.id
      AND o.is_vacant = false
    JOIN essentials.districts d
      ON d.id = o.district_id
      AND d.district_type = 'NATIONAL_UPPER'
    WHERE p.is_active = true
      AND p.is_incumbent = false
    ORDER BY p.id
  )`;
```

### Pattern 2: Migration UPSERT + DELETE Structure

Same as migration 268 (senator remediation). For each CSV row from research-stances:

```sql
-- Source: adapted from supabase/migrations/20260606000001_268_senator_source_remediation.sql [ASSUMED]
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('uuid', (SELECT id FROM inform.compass_topics WHERE topic_key = 'key'), value)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('uuid', (SELECT id FROM inform.compass_topics WHERE topic_key = 'key'), 
        'reasoning text', 
        ARRAY(SELECT u FROM unnest(ARRAY['url1','url2']) AS u WHERE u IS NOT NULL AND trim(u) != ''))
ON CONFLICT (politician_id, topic_id) DO UPDATE 
  SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
```

For topics where no real source is found (deletion path):

```sql
-- DELETED: Derek Dooley / abortion / former value=4.0 / reason=no evidence found
DELETE FROM inform.politician_context WHERE politician_id = 'uuid' AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion');
DELETE FROM inform.politician_answers WHERE politician_id = 'uuid' AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'abortion');
```

### Anti-Patterns to Avoid

- **Querying `inform.*` via PostgREST:** The `inform` schema is not in the PostgREST exposed schema list. All queries must use `pg.Pool`. Silent failures result.
- **Parallel research-stances agents:** Rate limit rule (one at a time). Never dispatch multiple agents in parallel. Memory.md feedback rule is explicit.
- **Inferring values from party affiliation:** Chair methodology requires exact stance text match. Dooley/Shoffner/Alme are 2026 candidates with limited public records — skip topics with insufficient evidence rather than inferring from party.
- **Treating 86 no-stance reps as a remediation gap:** They have no stance rows to remediate. Out of scope per REQUIREMENTS.md.
- **is_incumbent scope confusion:** Phase 101 triage filtered `is_incumbent = true`. That filter excluded the 3 deferred candidates. Phase 102 triage must explicitly scope the candidate query separately.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SOURCED_CASE / UNSOURCED_CASE SQL | New definitions | Copy verbatim from `run-senator-source-triage.ts` | Phase 100 locked the definition; divergence breaks cross-phase comparison |
| Homepage-only detection regex | New pattern | `'^https?://[^/]+/?$'` from existing script | Locked per D-01 in Phase 101 CONTEXT.md |
| Migration UPSERT pattern | Custom merge | ON CONFLICT (politician_id, topic_id) DO UPDATE | Established in Phase 101 migration 268 |
| Stance research | Manual URL fetching | research-stances skill with WebFetch only | Rate limit protection; consistent Chair methodology |

---

## Common Pitfalls

### Pitfall 1: Scope Confusion — NATIONAL_LOWER vs. Deferred Candidates

**What goes wrong:** Planner scopes Phase 102 as a pure NATIONAL_LOWER remediation and misses the 3 deferred candidates (Dooley, Shoffner, Alme) which are NATIONAL_UPPER-classified.

**Why it happens:** The deferred candidates are logged in Phase 101 docs but not in the REQUIREMENTS.md text. FEDX-02 says "House representative stances" — the 3 candidates are Senate candidates, not House reps. A strict reading of FEDX-02 would exclude them.

**How to avoid:** Phase 101 VERIFICATION.md explicitly says Phase 102 owns them (deferred-items.md). The deferred-items.md entry says "Coordinate with Phase 102 planning." The Phase 102 success criteria from ROADMAP.md success criterion 1 says `district_type = 'NATIONAL_UPPER'` is NOT in the Phase 102 query scope — Phase 102 success criteria only checks NATIONAL_LOWER. However, the V2=0 milestone goal (homepage-only count = 0) cannot be reached while these 3 candidates remain unremediated. Phase 102 is the natural owner.

**Resolution:** Phase 102 Plan 01 should include BOTH a NATIONAL_LOWER triage AND a deferred-candidate triage. Plan 02 remediates the deferred candidates regardless of FEDX-02 strictness, since they were explicitly deferred here and no later phase owns them.

**Warning signs:** If the triage report only covers NATIONAL_LOWER and makes no mention of Dooley/Shoffner/Alme, the deferred work will fall through the cracks.

### Pitfall 2: Treating `is_incumbent=false` Politicians as Out of Scope for Sourcing

**What goes wrong:** Researcher correctly filters `is_incumbent=true` for House rep triage (matching Phase 101 senator scope), then concludes that all NATIONAL_UPPER non-incumbent stances are someone else's problem.

**Why it happens:** Phase 101 triage filtered `is_incumbent=true` for senators. The 43 non-incumbent NATIONAL_UPPER politicians (2026 Senate candidates) were out of Phase 101's triage scope because the Phase 101 success criteria explicitly targeted incumbents. But the Phase 101 V2 query (homepage-only check) ran WITHOUT the is_incumbent filter and returned 19.

**How to avoid:** The deferred-items.md is explicit that Phase 102 owns Dooley/Shoffner/Alme. The triage script should include a second sub-query targeting `is_incumbent=false AND district_type='NATIONAL_UPPER'` as a distinct section.

### Pitfall 3: Migration Number Collision

**What goes wrong:** Migration written as 269 but another migration was applied between research and execution.

**Why it happens:** Migration numbers are assigned at planning time but may conflict with hotfixes or parallel work.

**How to avoid:** Verify `SELECT MAX(version) FROM supabase_migrations.schema_migrations` at the START of Task 3 (migration write), not at research time. Current max = 268; next available = 269.

**Warning signs:** psql error "duplicate key value violates unique constraint" on migration insert.

### Pitfall 4: is_incumbent Filter Gap in V1/V2 Verification Queries

**What goes wrong:** Phase 102 FEDX-02 success criteria SQL (V1) uses `district_type = 'NATIONAL_LOWER'` and returns 0 (because there are no unsourced NATIONAL_LOWER stances). But V2 (homepage-only count) also needs to return 0 for the deferred candidates. If Phase 102 only runs V1, V2 will still return 19.

**How to avoid:** Phase 102 verification must run BOTH queries: V1 (NATIONAL_LOWER unsourced = 0) AND a V2 covering ALL politician_context rows for NATIONAL_UPPER active politicians (including candidates) to confirm homepage-only count drops to 0 after deferred candidate remediation.

---

## Code Examples

### Triage Script Output Files (naming convention)

```
// Source: adapted from run-senator-source-triage.ts [ASSUMED]
const phaseDir = path.resolve(__dirname, '..', '..', '.planning', 'phases', '102-federal-house-remediation');
const reportPath = path.resolve(phaseDir, '102-TRIAGE-REPORT.md');
const csvPath = path.resolve(phaseDir, '102-HOUSE-TARGETS.csv');
```

### FEDX-02 Verification SQL

```sql
-- V1: NATIONAL_LOWER unsourced count (must return 0)
SELECT COUNT(*) AS unsourced_count
FROM inform.politician_answers pa
LEFT JOIN inform.politician_context pc
  ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
WHERE pa.politician_id IN (
  SELECT DISTINCT p.id FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type = 'NATIONAL_LOWER' AND p.is_active = true
)
AND (
  pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) IS NULL
  OR NOT EXISTS (SELECT 1 FROM unnest(pc.sources) s(u) WHERE u IS NOT NULL AND trim(u) != '')
);

-- V2: ALL active NATIONAL_UPPER politicians homepage-only count (must return 0 after deferred candidate remediation)
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

### research-stances Agent Dispatch (one at a time)

```
// For each deferred candidate, dispatch ONE agent with topics limited to weak-sourced topics only
// Dooley: --topics abortion,civil-rights,climate-change,healthcare,immigration,voting-rights
// Shoffner: --topics campaign-finance,climate-change,economic-development,housing,taxes  
// Alme: --topics abortion,fossil-fuels,religious-freedom,same-sex-marriage,social-security,tariffs,trans-athletes,voting-rights
//
// All three are NATIONAL_UPPER Senate candidates, NOT House reps — use federal topic scope
// (skip local-only topics: transportation-priorities, economic-development [included for Shoffner who has this topic], etc.)
// EXCEPTION: economic-development is in Shoffner's weak list — include it since the stance already exists
```

---

## Phase Plan Structure (D-03 equivalent)

Based on verified DB state:

- **NATIONAL_LOWER triage result:** 0 senators flagged (confirmed before planning)
- **Deferred candidates:** 3 politicians, 19 weak-sourced stances total

**Batch count determination (D-03 thresholds adapted for candidates):**
- 3 candidates = ≤10 threshold → 1 research plan
- Total plans for Phase 102: **2 plans**

| Plan | Content |
|------|---------|
| 102-01 | Triage script (`run-house-source-triage.ts`) — covers NATIONAL_LOWER (confirms 0 flagged) AND deferred NATIONAL_UPPER candidates (confirms 3 flagged, 19 weak stances). Outputs `102-TRIAGE-REPORT.md` and `102-HOUSE-TARGETS.csv` |
| 102-02 | Research + migration + deletion log: research-stances for Dooley, Shoffner, Alme (one at a time); migration 269; `102-DELETION-LOG.md`; `102-VERIFICATION.md` |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| NATIONAL_UPPER only in Phase 100 audit | Phase 102 includes NATIONAL_UPPER non-incumbents (candidates) to close the V2=19 deferred issue | Phase 101 deferred-items.md | V2 homepage-only count can reach 0 after Phase 102 |
| is_incumbent=true filter (Phase 101) | Phase 102 explicitly includes is_incumbent=false for deferred candidates | Phase 102 scope expansion | Catches 3 previously-missed candidate rows |

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FEDX-02 | Every US House representative stance: re-researched with Chair methodology → has real source URL, or has been deleted | Live DB confirms 36 House reps with stances, all already sourced (0 unsourced, 0 weak). V1 query returns 0. Deferred candidates are NATIONAL_UPPER and technically outside FEDX-02 literal scope, but Phase 102 remediates them to bring V2 to 0. |
| QUAL-01 | Every stance updated/added: value verified against specific Chair text | research-stances skill enforces Chair methodology. Applies to 3 deferred candidates only (NATIONAL_LOWER reps require no research — already sourced). |
| QUAL-02 | Deletion log produced (politician full_name, topic_key, former value, reason) | 102-DELETION-LOG.md in same format as 101-DELETION-LOG.md. Expected entries: stances for Dooley/Shoffner/Alme topics where research finds no real specific URL. |
</phase_requirements>

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Next migration number is 269 | Live DB State | Verified `MAX(version) = 268` at 2026-06-06. Risk: another migration applies before Plan 02 executes. Mitigation: plan task re-verifies before writing. |
| A2 | The 3 deferred candidates (Dooley/Shoffner/Alme) are Phase 102's responsibility per deferred-items.md | Architecture Patterns | If a future discussion assigns them elsewhere, Phase 102 should skip them and the V2 query stays at 19 |
| A3 | NATIONAL_LOWER has 122 is_active=true is_incumbent=true politicians, all with 0 unsourced/weak stances | Live DB State | Verified directly — zero risk if DB hasn't changed |
| A4 | Kurt Alme has both weak AND real sources on some topics | Live DB State | Verified: 8 weak topics (homepage-only), 5 topics have both homepage AND a real URL. Triage will flag only the 8 weak-only topics. |

---

## Open Questions

1. **Should the FEDX-02 success criteria query (V1) also check NATIONAL_UPPER candidates?**
   - What we know: FEDX-02 success criterion says `district_type = 'NATIONAL_LOWER'` in the WHERE clause — it is unambiguously scoped to House reps.
   - What's unclear: Whether remediating the 3 candidates should be framed as satisfying FEDX-02 or as "cleanup from Phase 101 deferred work."
   - Recommendation: Frame it as the latter. FEDX-02 V1 query is NATIONAL_LOWER only (will trivially pass as 0). The deferred candidate remediation is tracked in 101-VERIFICATION.md and closes a separate V2=0 goal. Both are documented in 102-VERIFICATION.md.

2. **Kurt Alme: topic `taxes` in Shoffner's weak list vs economic-development**
   - What we know: Shoffner's 5 weak topics are: campaign-finance, climate-change, economic-development, housing, taxes. All 5 have only a homepage URL. These are all valid federal-tier topics per the compass topic list.
   - What's unclear: `economic-development` is listed as a city-level skip topic in SKILL.md ("economic-development" in the city-level SKIP list). But Shoffner already HAS a stance for it — remediation is upgrade-or-delete, not add-or-skip.
   - Recommendation: Include `economic-development` in Shoffner's research because the stance already exists and must be either upgraded to a real source or deleted. The skip rule in SKILL.md applies to new stance creation, not remediation of existing stances.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| DATABASE_URL (Supabase session pooler) | Triage script, psql migration apply | Verified | — | None — required |
| `npx tsx` | Run triage script | Verified (used in Phase 101) | — | — |
| `psql` | Apply migration | Verified (used in Phase 101) | — | — |
| research-stances skill | Candidate re-research | Present at `.claude/skills/research-stances/SKILL.md` | — | — |

---

## Validation Architecture

`workflow.nyquist_validation` key is absent from `.planning/config.json` — treating as enabled.

This phase has no application code changes — no TypeScript compilation targets, no API routes, no React components. The "tests" for this phase are the SQL verification queries (V1, V2) run post-migration. These replace automated test framework tests.

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FEDX-02 | V1 query returns 0 unsourced NATIONAL_LOWER stances | SQL verification | `psql $DATABASE_URL -c "SELECT COUNT(*) ..."` | N/A — SQL query, not file |
| QUAL-01 | Human spot-check 3 random source URLs from research CSV | Manual | Human verification at checkpoint:human-verify task | N/A |
| QUAL-02 | 102-DELETION-LOG.md exists with correct format | File check | `test -f .planning/phases/102-.../102-DELETION-LOG.md && grep -q "former value" ...` | Not yet — Wave 2 deliverable |

**Wave 0 Gaps:** No test framework gaps — this is a data phase. The SQL verification queries serve as the functional equivalent of automated tests and are embedded in Plan 02 Task 4.

---

## Security Domain

`security_enforcement` key absent from config — treating as enabled. However, this phase makes no code changes — no new API endpoints, no auth changes, no user-facing data paths. The security controls are:

- All DB writes go through `pool.query()` (direct postgres, not PostgREST)
- Migration uses `BEGIN/COMMIT` transactions (atomicity)
- No user-supplied input — all writes are from researched CSV output verified by human at checkpoint task

No ASVS categories apply (no application code modified).

---

## Sources

### Primary (HIGH confidence)
- Live DB queries run 2026-06-06 — NATIONAL_LOWER counts, sourcing state, migration version
- `.planning/phases/101-candidate-profiles/101-VERIFICATION.md` — deferred items, V2=19 root cause
- `.planning/phases/101-candidate-profiles/deferred-items.md` — explicit Phase 102 responsibility assignment
- `.planning/phases/100-source-coverage-audit/100-AUDIT-REPORT.md` — locked sourced definition
- `backend/scripts/run-senator-source-triage.ts` — complete template to adapt
- `.planning/phases/101-candidate-profiles/101-CONTEXT.md` — D-01 through D-04 methodology decisions

### Secondary (MEDIUM confidence)
- `.planning/REQUIREMENTS.md` — FEDX-02, QUAL-01, QUAL-02 definitions
- `.planning/ROADMAP.md` Phase 102 success criteria — query shapes for V1/V2

---

## Metadata

**Confidence breakdown:**
- DB state (NATIONAL_LOWER counts, sourcing): HIGH — verified against live production DB 2026-06-06
- Deferred candidate scope: HIGH — explicit in Phase 101 deferred-items.md
- Plan structure (2 plans): HIGH — based on verified 0 NATIONAL_LOWER targets + 3 deferred candidates ≤ 10 threshold
- Migration number 269: HIGH at time of research — must re-verify before writing migration
- research-stances approach for candidates: HIGH — same pattern as Phase 101 Plan 02

**Research date:** 2026-06-06
**Valid until:** 2026-06-13 (7 days — migration number could change with any hotfix)
