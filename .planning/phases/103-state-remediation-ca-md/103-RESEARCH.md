# Phase 103: State Remediation — CA + MD - Research

**Researched:** 2026-06-06
**Domain:** Data remediation — CA state legislator stance sources + MD executive branch fresh research
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01: CA Triage Scope**
Full triage of all CA politicians in DB — Plan 01 runs a fresh query for every politician whose office maps to a CA district (Assembly: district type STATE_LOWER for CA; Senate: STATE_UPPER for CA; statewide: governor etc.). Dual detection: unsourced + weak-source. Both: (1) politicians with unsourced stances and (2) politicians with ALL sources matching homepage-only pattern `^https?://[^/]+/?$`. Scope is dynamic — Plan 02 sizing comes from triage output.

**D-02: CA Politician Scope**
All CA state politicians in the DB — not just CA Assembly + CA Senate strictly. Statewide executives (e.g., Gavin Newsom as governor) are included. The triage query captures any politician with an office record tied to a CA district.

**D-03: Plan Structure**
3 plans:
- Plan 01: CA triage query only (like Phase 101/102 Plan 01)
- Plan 02: CA research + migration + deletion log (planner sizes batching from triage output)
- Plan 03: MD research (5 officials, all live topics, 1 at a time) + migration + deletion log appendix

Planner may split Plan 02 if CA triage reveals >25 target politicians.

**D-04: MD Research Approach**
All live compass topics — run research-stances for each MD official covering every topic in `inform.compass_topics WHERE is_live = true`. Sequential only — one MD official at a time. No deletion log needed for MD (no existing stances to delete).

**D-05: Source Update Policy**
Append new URLs to existing sources, never replace: `UPDATE inform.politician_context SET sources = sources || ARRAY['url'] WHERE ...`. Exception: if existing sources is empty or NULL, use plain INSERT/UPSERT.

**D-06: Deletion and Research Rules (carried from Phases 101/102)**
- Delete if no real URL found — regardless of value
- Single research pass — no retry loops
- No party inference
- QUAL-02 deletion log format: `politician full_name, topic_key, former value, reason`
- Plan 03 does NOT need MD deletion log entries (no existing stances)

### Claude's Discretion

None specified — all key decisions are locked.

### Deferred Ideas (OUT OF SCOPE)

None from discussion.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STAX-01 | Every CA state legislator (CA Assembly + CA Senate) stance: sourced or deleted | CA triage query (Plan 01) + CA remediation migration (Plan 02) |
| STAX-02 | MD officials in DB (migrations 269–271): research and add stances with sources from scratch | research-stances skill dispatched for 5 MD officials, all live topics (Plan 03) |
| QUAL-01 | Every stance updated/added: value verified against specific Chair text | Chair methodology embedded in every research-stances agent prompt |
| QUAL-02 | Deletion log produced (politician full_name, topic_key, former value, reason) | Plan 02 produces CA deletion log; Plan 03 has no entries (no prior stances for MD) |
</phase_requirements>

---

## Summary

Phase 103 has two independent tracks that must both complete before the phase closes. Track A (CA remediation, STAX-01) follows the exact triage-first pattern established in Phases 101 and 102: a TypeScript triage script queries all CA state politicians in the DB for unsourced stances and weak-source (homepage-only) stances, produces a CSV target list, and Plan 02 remediates everything on that list via research-stances followed by a single migration. Track B (MD fresh research, STAX-02) is structurally different — five Maryland executive branch officials were added in migrations 269–271 and have zero stances. They need full Chair methodology research from scratch across all live compass topics (confirmed 44 as of SKILL.md update 2026-06-02).

Key scope facts established at research time:

- The **known CA unsourced floor is 9 politicians** (Phase 100 target list, State tier rows) — but Plan 01 triage will reveal the full picture including weak-sourced politicians not visible in that list.
- **107 weak-source rows exist DB-wide** (Phase 100 audit). CA state legislators are the primary tier with weak sources — the Phase 100 tier breakdown shows State tier at 6,891 total stances / 16 unsourced, but weak-source is under-counted there since those 107 rows are counted as "sourced." Plan 01 will enumerate which CA politicians own those weak rows.
- The **next available migration number is 270** (last applied was 269, per supabase/migrations/20260606000002_269_house_source_remediation.sql). Planner must verify `SELECT MAX(version) FROM supabase_migrations.schema_migrations` before writing Plan 02 or Plan 03 migration filenames.
- **Live topic count is 44** (confirmed in SKILL.md, updated 2026-06-02: "As of 2026-06-02 there are 44 live topics"). MD officials need research across all 44 topics. The original 21-topic count is stale.

**Primary recommendation:** Build Plan 01 as a direct adaptation of `run-house-source-triage.ts` — adapt the CA district join (STATE_LOWER + STATE_UPPER + STATE_EXEC, state = 'CA'), keep the SOURCED_CASE/UNSOURCED_CASE constants verbatim, and output both a triage report and a CA-TARGETS.csv. Plan 02 and Plan 03 size themselves from Plan 01 output and the confirmed MD target list respectively.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CA triage query (unsourced + weak-source detection) | Database / Storage | — | Queries inform.* directly via pool.query(); inform schema not in PostgREST |
| CA remediation migration (UPSERT + DELETE) | Database / Storage | — | Direct psql apply; session pooler URL; same pattern as migrations 268/269 |
| MD fresh research (research-stances skill) | API / Backend | — | research-stances orchestrates agent dispatch + DB upsert via pool.query() |
| Deletion log (QUAL-02) | Repository artifact | — | Markdown file committed alongside migration; not a DB table |
| Source append vs overwrite logic | Database / Storage | — | ARRAY_CAT pattern: `sources = sources || ARRAY[...]` vs fresh INSERT when sources is NULL/empty |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| pg (Pool) | project version | All inform.* queries and migrations | inform schema not in PostgREST; pool.query() is the only working path [ASSUMED] |
| tsx | project version | Run TypeScript triage scripts directly | Established pattern: `npx tsx scripts/run-*.ts` [ASSUMED] |
| dotenv | project version | Load DATABASE_URL from backend/.env | Established pattern in all audit/triage scripts [ASSUMED] |
| psql | system | Apply migrations to live Supabase DB | `supabase db push` does not work; direct psql via session pooler URL is the locked pattern [VERIFIED: STATE.md v2.2 Geospatial Patterns] |

### No New Packages

This phase installs no new npm packages. All tooling is already installed. No package legitimacy audit needed.

---

## Package Legitimacy Audit

No external packages are added in this phase. The phase only uses tooling already present in the project (pg, tsx, dotenv, psql). Audit skipped.

---

## Architecture Patterns

### System Architecture Diagram

```
Plan 01 — CA Triage
  backend/scripts/run-ca-source-triage.ts
    └─ pool.query() → essentials.offices JOIN essentials.districts (STATE_LOWER/STATE_UPPER/STATE_EXEC, CA)
                    → DISTINCT ON (politician_id) subquery
                    → LEFT JOIN inform.politician_answers + inform.politician_context
                    → SOURCED_CASE / UNSOURCED_CASE / HOMEPAGE_ONLY_REGEX filters
    └─ writes → 103-CA-TRIAGE-REPORT.md (human-readable)
             → 103-CA-TARGETS.csv (machine-readable: full_name, politician_id, state, party, unsourced_count, weak_count, classification, affected_topic_keys)

Plan 02 — CA Remediation
  research-stances skill (sequential, 1 agent per politician batch)
    └─ politician-stance-researcher agent × N batches
    └─ writes → backend/data/stance-research/YYYY-MM-DD-ca-state-remediation.csv
  Migration file → BEGIN; UPSERTs + DELETEs + COMMIT
    └─ UPSERT: inform.politician_answers ON CONFLICT DO UPDATE
    └─ UPSERT: inform.politician_context (sources ARRAY_CAT pattern)
    └─ DELETE: inform.politician_context + inform.politician_answers (context first)
    └─ psql apply via session pooler
  103-DELETION-LOG.md (QUAL-02 format: full_name | topic_key | former value | reason)

Plan 03 — MD Fresh Research
  research-stances skill (sequential, 1 agent per official)
    └─ 5 MD officials × 44 topics = up to 220 stance assessments
    └─ writes → backend/data/stance-research/YYYY-MM-DD-md-officials.csv
  Migration file → BEGIN; INSERT INTO inform.politician_answers + inform.politician_context; COMMIT
    └─ No DELETEs (no existing MD stances)
    └─ psql apply via session pooler
```

### Recommended Project Structure

No new directories. All artifacts go into:
```
.planning/phases/103-state-remediation-ca-md/
  103-CA-TRIAGE-REPORT.md        (Plan 01 output)
  103-CA-TARGETS.csv             (Plan 01 output — machine-readable target list)
  103-RESEARCH-NOTES.md          (Plan 02 pre-flight: scope, live stance scale, dispatch plan)
  103-DELETION-LOG.md            (Plan 02 output — QUAL-02)
  103-VERIFICATION.md            (Plan 02 + 03 output — post-migration SQL checks)

backend/scripts/
  run-ca-source-triage.ts        (Plan 01 script)

backend/data/stance-research/
  YYYY-MM-DD-ca-state-remediation.csv
  YYYY-MM-DD-md-officials.csv

supabase/migrations/
  YYYYMMDD000001_270_ca_state_source_remediation.sql   (Plan 02 — next number after 269)
  YYYYMMDD000002_271_md_officials_stances.sql          (Plan 03 — next after Plan 02)
```

Note: Migration numbers above assume 270 and 271 as next available. Planner MUST verify `SELECT MAX(version) FROM supabase_migrations.schema_migrations` before writing both migration filenames.

### Pattern 1: CA Triage Script (DISTINCT ON, dual-scope, state filter)

The CA triage is a direct adaptation of `run-house-source-triage.ts`. The critical addition is a state filter on the district join:

```typescript
// Source: backend/scripts/run-house-source-triage.ts (Phase 102 — adapt verbatim)
// CA version adds: d.state = 'CA' AND d.district_type IN ('STATE_LOWER','STATE_UPPER','STATE_EXEC')
const CA_POLITICIANS_CTE = `
  WITH ca_politicians AS (
    SELECT DISTINCT ON (p.id)
      p.id,
      p.full_name,
      p.is_active,
      d.state,
      d.district_type,
      o.title as office_title
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE p.is_active = true
      AND d.state = 'CA'
      AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC', 'STATE_BOARD')
    ORDER BY p.id
  )
`;
```

Verification needed: check what `district_type` values are actually used for CA statewide offices (governor, AG, etc.) in the DB. `STATE_EXEC` is the presumed type but could be `STATE_BOARD` or another. The triage script should use `IN (...)` with all plausible state-tier types rather than a hard `= 'STATE_LOWER'`. [ASSUMED — verify via `SELECT DISTINCT district_type FROM essentials.districts WHERE state = 'CA'` before writing the script]

### Pattern 2: Source Append (ARRAY_CAT)

From CONTEXT.md D-05 — when a context row already exists with sources (even homepage-only), use append not overwrite:

```sql
-- Source: CONTEXT.md D-05 (locked decision)
-- Case 1: context row exists — append
UPDATE inform.politician_context
  SET sources = sources || ARRAY['https://new-real-url.com/page']
  WHERE politician_id = 'uuid' AND topic_id = (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change');

-- Case 2: no context row yet — INSERT (or use ON CONFLICT DO UPDATE with EXCLUDED.sources)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  VALUES ('uuid', topic_id_subquery, 'reasoning text', ARRAY['https://real-url.com/page'])
  ON CONFLICT (politician_id, topic_id)
  DO UPDATE SET
    reasoning = EXCLUDED.reasoning,
    sources   = EXCLUDED.sources;
```

For the migration, the planner must check whether each politician already has a context row before choosing ARRAY_CAT vs fresh INSERT. The safest migration pattern is an explicit two-step per CONTEXT.md D-05: first try UPDATE with ARRAY_CAT; if 0 rows updated, then INSERT. Alternatively, use `DO UPDATE SET sources = politician_context.sources || EXCLUDED.sources` in the ON CONFLICT clause.

### Pattern 3: MD Official Identification (by UUID, not name)

CONTEXT.md and 100-AUDIT-REPORT.md both warn that middle-initial name variants caused lookup issues in Phase 100. Always use UUID literals:

```
Wes Moore       → 21e534c8-c0c0-42f5-b52b-5eb2f246d632
Aruna Miller    → ea9fc2d6-3b26-469a-978c-e8c846d2d49a
Anthony G. Brown→ 60329719-1d5b-4bb4-8295-38ea18f6f378
Brooke Lierman  → b26fb5d2-90eb-4108-8ce5-838df719473d
Dereck E. Davis → 75378a96-8886-46eb-b0c1-37cbe2579265
```

### Pattern 4: Migration Registration

```sql
-- Source: supabase/migrations/20260606000002_269_house_source_remediation.sql (template)
INSERT INTO supabase_migrations.schema_migrations (version, name)
  VALUES ('270', '270_ca_state_source_remediation')
  ON CONFLICT DO NOTHING;
```

### Pattern 5: Blank-URL Array Filter in Migration

From 102-RESEARCH.md Pattern 2 — when building source arrays in migration SQL, always strip blank elements:

```sql
-- Source: Phase 102 migration pattern
ARRAY(
  SELECT u FROM unnest(ARRAY['url1', 'url2', '']) AS u
  WHERE u IS NOT NULL AND trim(u) != ''
)
```

### Anti-Patterns to Avoid

- **`supabaseAdmin.schema('inform')`**: inform schema is not in PostgREST exposed list. Silently fails. All inform queries must use `pool.query()`.
- **Name-based politician lookup in migration SQL**: Use UUID literals. `WHERE p.full_name = 'Anthony Brown'` silently matches 0 rows (DB has `Anthony G. Brown`).
- **Overwriting sources instead of appending**: Per D-05, `DO UPDATE SET sources = EXCLUDED.sources` destroys prior source history. Use `sources = politician_context.sources || EXCLUDED.sources` in the conflict clause (or separate UPDATE + INSERT logic).
- **Running research-stances agents in parallel**: Rate limit burns immediately with empty output. One agent at a time, always.
- **Using hardcoded topic count (21)**: As of 2026-06-02 there are 44 live topics. research-stances Step 0 must fetch live count from DB before every run.
- **Inferring from party affiliation**: Locked rule — every stance needs a real fetched URL. Never infer from party.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Weak-source detection SQL | Custom regex logic | Copy HOMEPAGE_ONLY_REGEX + SOURCED_CASE/UNSOURCED_CASE constants verbatim from run-house-source-triage.ts | Locked locked definition from Phase 100 — any deviation invalidates cross-phase comparisons |
| Topic list for research | Hardcoded array | SKILL.md Step 0 query: `SELECT id, topic_key, ... FROM inform.compass_topics JOIN inform.compass_stances WHERE is_live = true` | Count has grown from 21 to 44; hardcoded list will miss new topics |
| politician_id resolution | Name-based WHERE clause | UUID literals from confirmed Phase 100 IDs or triage output | Middle-initial variants cause silent 0-row matches |
| Migration application | `supabase db push` | `psql "$DATABASE_URL" -f migration.sql` via session pooler | supabase db push does not work in this project |

**Key insight:** The entire methodology (sourced definition, weak-source regex, migration SQL shape, deletion log format, dispatch rules) is fully established from Phases 100–102. Phase 103 is execution of a known pattern, not design of a new one.

---

## Common Pitfalls

### Pitfall 1: CA District Type Coverage
**What goes wrong:** Triage script only joins `STATE_LOWER` and `STATE_UPPER`, missing the statewide exec tier (governor = Gavin Newsom). Newsom shows 4 unsourced stances in the Phase 100 target list but would be invisible to an Assembly+Senate-only filter.
**Why it happens:** The intuitive reading of "CA state legislators" is Assembly + Senate only.
**How to avoid:** Use `IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC', 'STATE_BOARD')` in the district_type filter. Verify against live DB: `SELECT DISTINCT district_type FROM essentials.districts WHERE state = 'CA'`.
**Warning signs:** Gavin Newsom does not appear in the triage output; politician count seems too low.

### Pitfall 2: Weak-Source Count Underestimate
**What goes wrong:** Only checking `unsourced_count > 0` in the target filter. Politicians with ALL sources as homepage-only URLs pass the sourced 4-rule check and would be missed.
**Why it happens:** The 4-rule sourced definition (Phase 100) classifies homepage-only as technically sourced. The `QUAL-01` standard requires a primary source with specific evidence.
**How to avoid:** The triage HAVING clause must be `(unsourced_count > 0 OR weak_count > 0)`. The `HOMEPAGE_ONLY_REGEX` check fires on every non-blank URL element; a politician is "weak-sourced" when ALL their non-blank URLs for a stance match the regex.
**Warning signs:** The triage finds fewer than 9 targets (the known floor from Phase 100).

### Pitfall 3: Migration Number Collision
**What goes wrong:** Writing a migration file with number 270 when another migration was applied to the live DB between Phase 102 completion and Plan 01/02/03 execution.
**Why it happens:** Migrations can be applied directly via psql at any time; the file counter in the repository may not reflect the live DB state.
**How to avoid:** Run `SELECT MAX(version) FROM supabase_migrations.schema_migrations` against the live DB BEFORE writing the migration filename. This is noted as a required step in both CONTEXT.md and the Phase 102 Plan 03 template.
**Warning signs:** psql apply fails with a duplicate version error.

### Pitfall 4: MD Topic Count Assumption
**What goes wrong:** Building the MD research plan against 21 topics (the original topic count from v2.3). MD officials end up with incomplete coverage.
**Why it happens:** The SKILL.md update note (2026-06-02) expanded the count to 44, but the number 21 still appears in older references throughout the codebase.
**How to avoid:** Run `SELECT COUNT(*) FROM inform.compass_topics WHERE is_live = true` before writing Plan 03. The SKILL.md Step 0 topic-resolution query fetches the live set; embed the full output in the research-stances agent prompt — do not hardcode any topic list.
**Warning signs:** Plan 03 scope math shows fewer than 44 topics per official.

### Pitfall 5: ARRAY_CAT vs Overwrite in Migration
**What goes wrong:** Migration uses `DO UPDATE SET sources = EXCLUDED.sources` for CA remediation context rows that already have homepage-only sources. This destroys the prior source history.
**Why it happens:** Standard upsert pattern sets `column = EXCLUDED.column`. The CA-specific rule (D-05) requires appending, not replacing.
**How to avoid:** For CA context rows that already exist (weak-sourced politicians), the migration must use `DO UPDATE SET sources = politician_context.sources || EXCLUDED.sources`. For CA politicians with completely missing context rows (unsourced — null/empty), standard INSERT is fine.
**Warning signs:** Post-migration check shows source count decreased for a previously-weak-sourced politician.

### Pitfall 6: City-Level Topic Skip Rule Misapplied
**What goes wrong:** research-stances agent skips `economic-development`, `homelessness-response`, etc. for CA state legislators because SKILL.md lists them as city-level topics. But CA state legislators are state/federal officials who may have votes on housing, homelessness, etc. that are distinct from the city-tier framing.
**Why it happens:** SKILL.md says "City-level topics to SKIP for state/federal candidates." The precedent from Phase 102 (Shoffner's economic-development) shows that for EXISTING stances on these topics, the skip rule does not apply to remediation — existing stances must be upgraded or deleted.
**How to avoid:** For CA politicians, the skip rule applies to NEW stance creation on city-level topics. For topics already in `politician_answers`, the agent must either find a real source or flag for deletion — no "skip" for existing rows.
**Warning signs:** An existing CA politician stance on a topic like `economic-development` disappears from the CSV with no deletion log entry.

---

## Code Examples

Verified patterns from official sources:

### CA Politician Query (DISTINCT ON + state filter)

```typescript
// Adapted from backend/scripts/run-house-source-triage.ts (Phase 102)
const { rows } = await pool.query(`
  WITH ca_politicians AS (
    SELECT DISTINCT ON (p.id)
      p.id,
      p.full_name,
      p.party,
      d.state,
      d.district_type
    FROM essentials.politicians p
    JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE p.is_active = true
      AND d.state = 'CA'
      AND d.district_type IN ('STATE_LOWER', 'STATE_UPPER', 'STATE_EXEC', 'STATE_BOARD')
    ORDER BY p.id
  )
  SELECT
    cp.full_name,
    cp.politician_id,
    ...
  FROM ca_politicians cp
  JOIN inform.politician_answers pa ON pa.politician_id = cp.id
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id
    AND pc.topic_id = pa.topic_id
  GROUP BY cp.id, cp.full_name, cp.party, cp.state, cp.district_type
  HAVING SUM(unsourced_case) > 0 OR SUM(weak_case) > 0
`);
```

### Source Append Migration SQL

```sql
-- Source: CONTEXT.md D-05 + Phase 102 migration 269 pattern
-- For CA politicians with existing (homepage-only) context rows:
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  (SELECT id FROM inform.compass_topics WHERE topic_key = 'climate-change'),
  'Reasoning text here...',
  ARRAY(SELECT u FROM unnest(ARRAY['https://real-url.com/page']) AS u
        WHERE u IS NOT NULL AND trim(u) != '')
)
ON CONFLICT (politician_id, topic_id) DO UPDATE
  SET reasoning = EXCLUDED.reasoning,
      sources   = politician_context.sources || EXCLUDED.sources;
```

### Verify Next Migration Number

```bash
# Source: established pattern — STATE.md v2.2 Geospatial Patterns
psql "$DATABASE_URL" -c "SELECT MAX(version) FROM supabase_migrations.schema_migrations;"
# Expected at research time: 269 (last applied = 20260606000002_269_house_source_remediation.sql)
# Next available: 270 — VERIFY before writing migration filename
```

### Live Topic Count Check

```bash
cd backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query('SELECT COUNT(*) as cnt FROM inform.compass_topics WHERE is_live = true');
console.log('Live topic count:', rows[0].cnt);
await pool.end();
"
# Expected: 44 (confirmed in SKILL.md as of 2026-06-02)
```

### CA State District Type Verification

```bash
cd backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(
  'SELECT DISTINCT d.district_type FROM essentials.districts d WHERE d.state = \$1 ORDER BY 1',
  ['CA']
);
console.log(JSON.stringify(rows));
await pool.end();
"
# Needed to confirm which district_type values to include in the triage IN() clause
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| 21 live topics | 44 live topics | 2026-06-02 (SKILL.md update) | MD research plan must cover all 44 topics per official; estimates of ~44×5=220 max stance assessments |
| Triage-then-remediate (Phase 101 introduced) | Triage-then-remediate (Phase 103 follows same pattern) | Phase 101 (2026-06-05) | Plan 01 always precedes Plan 02; never assume count from prior audit |
| Direct supabase.schema('inform') calls | pool.query() only for inform.* | Established by Phase 35 | Planner must not use PostgREST paths for any inform schema operation |

**Deprecated/outdated:**
- `supabase db push` for migration apply: does not work in this project. Direct psql only.
- 21-topic scope assumption: topic count is now 44.

---

## Runtime State Inventory

Not a rename/refactor/migration phase in the structural-change sense — this is data remediation and fresh research. No renaming of stored strings, no key changes, no OS registration changes.

Relevant runtime state verified:
- **inform.politician_answers**: CA state politicians have existing rows (unsourced or weak-sourced) — will be UPSERTED or DELETED by Plan 02 migration.
- **inform.politician_context**: CA politicians have existing context rows (empty sources or homepage-only sources) — will have sources APPENDed by Plan 02 migration. MD officials have zero context rows — Plan 03 will INSERT fresh rows.
- **inform.compass_topics**: Live topic count is the input constraint for Plan 03 scope. Must be queried fresh; not hardcoded.
- **supabase_migrations.schema_migrations**: MAX(version) = 269 at research time. Next migration numbers: 270 (Plan 02) and 271 (Plan 03). Verify before writing.
- **Secrets/env vars**: No changes — same DATABASE_URL and backend/.env patterns throughout.
- **Build artifacts**: No package installs; no compiled output affected.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| psql | Migration apply (Plans 02, 03) | ✓ | Used in Phase 102 successfully | — |
| backend/.env DATABASE_URL | All pool.query() operations | ✓ | Session pooler URL confirmed working in Phase 102 | — |
| research-stances skill | Plans 02, 03 | ✓ | Used in Phases 101, 102 | — |
| politician-stance-researcher agent | research-stances agent dispatch | ✓ | Used in Phases 101, 102 | — |
| tsx | Run triage script | ✓ | Used in Phases 101, 102 | — |

**Missing dependencies with no fallback:** None.

---

## Live DB State (verified from Phase 100 + Phase 102 outputs)

| Metric | Value | Source |
|--------|-------|--------|
| CA state tier total stances | 6,891 | Phase 100 audit (State tier) |
| CA state tier unsourced stances | 16 | Phase 100 audit (State tier) |
| DB-wide weak-source rows | 107 | Phase 100 audit (counted as sourced but homepage-only) |
| Known CA unsourced politicians (floor) | 9 | Phase 100 TARGET-LIST.csv (State tier rows) |
| MD official stance count | 0 | Phase 100 AUDIT-REPORT.md MD Officials section |
| MD official confirmed IDs | 5 | Phase 100 AUDIT-REPORT.md — UUIDs confirmed |
| Last applied migration | 269 | supabase/migrations/20260606000002_269_house_source_remediation.sql |
| Next available migration number | 270 | Verify via MAX(version) before writing |
| Live compass topics | 44 | SKILL.md updated 2026-06-02 |

**CA floor politicians (from Phase 100 TARGET-LIST.csv — State tier rows):**
| Full Name | Politician ID | Unsourced Count |
|-----------|--------------|-----------------|
| Gavin Newsom | f26309c8-2525-49b2-bdaf-62980cbb1853 | 4 |
| Katy Hall | e1e4e88b-bfd0-4c16-8e95-72c51b59c1f4 | 3 |
| Tracy Miller | d2d9d65d-138a-4b40-a4de-88642f35ec15 | 3 |
| Candice B. Pierucci | 99198363-2ac9-4b56-9d80-7abfe7b2a01a | 1 |
| Cody Harris | c6dcdb47-9bbd-4c9b-9169-77e6082f17b1 | 1 |
| Juan Carrillo | b959d608-5674-467e-a1c8-3572c76a729b | 1 |
| Lisa Calderon | 0afa998d-94e9-4af4-ba00-256c38869398 | 1 |
| Mike Braun | a73e7a2a-48b0-4636-8fa4-5324ede65833 | 1 |
| Roland Gutierrez | 3aee54f8-89eb-425d-b850-19fff9f2c8ea | 1 |

Note: Mike Braun (Indiana Governor, external_id -based lookup) appears in the State tier with 1 unsourced stance — he is likely Indiana state, not CA. The triage script's state='CA' filter will naturally exclude him. Katy Hall, Tracy Miller, Candice B. Pierucci, Cody Harris, Juan Carrillo, Lisa Calderon, and Roland Gutierrez are all CA legislators. Plan 01 triage will confirm.

**MD official UUIDs (confirmed in Phase 100):**
| Full Name (DB) | Politician ID |
|----------------|--------------|
| Wes Moore | 21e534c8-c0c0-42f5-b52b-5eb2f246d632 |
| Aruna Miller | ea9fc2d6-3b26-469a-978c-e8c846d2d49a |
| Anthony G. Brown | 60329719-1d5b-4bb4-8295-38ea18f6f378 |
| Brooke Lierman | b26fb5d2-90eb-4108-8ce5-838df719473d |
| Dereck E. Davis | 75378a96-8886-46eb-b0c1-37cbe2579265 |

---

## Plan 01 Template — CA Triage Script

The CA triage script (`run-ca-source-triage.ts`) must:

1. Copy SOURCED_CASE, UNSOURCED_CASE, HOMEPAGE_ONLY_REGEX constants **verbatim** from `run-house-source-triage.ts`.
2. Copy the dotenv + pool setup verbatim.
3. Replace the HOUSE_POLITICIANS_CTE and DEFERRED_CANDIDATES_CTE with a single CA_POLITICIANS_CTE:
   - `WHERE p.is_active = true AND d.state = 'CA' AND d.district_type IN ('STATE_LOWER','STATE_UPPER','STATE_EXEC','STATE_BOARD')`
   - `DISTINCT ON (p.id) ORDER BY p.id`
4. Summary query: total CA politicians, total stances, unsourced count, weak count.
5. Per-target query: `HAVING (unsourced_count > 0 OR weak_count > 0)` — classification column: `unsourced_only`, `weak_only`, or `both`.
6. Per-topic detail rollup: for each flagged politician, which topic_keys have unsourced or weak-source issues.
7. Two output artifacts:
   - `103-CA-TRIAGE-REPORT.md`: executive summary + methodology + per-politician detail sections
   - `103-CA-TARGETS.csv`: columns `full_name,politician_id,state,party,total_stances,unsourced_count,weak_count,classification,affected_topic_keys`
8. `--dry-run` flag support (print to stderr, no file writes).
9. Output path: phaseDir = path.resolve(__dirname, '..', '..', '.planning', 'phases', '103-state-remediation-ca-md').

**Note on Mike Braun**: phase 100 listed him as State tier, but he is the Governor of Indiana. His office join may produce a result with state='CA' only if there is a CA district record misconfigured for him. The `d.state = 'CA'` filter should naturally exclude him. If he appears in the CA triage output, that is a data anomaly worth flagging.

---

## Plan 02 Sizing Guidelines (from triage output)

Per CONTEXT.md D-03 (mirrors Phase 101 D-03):
- ≤ 10 CA target politicians: 1 research plan (research + migration + deletion log)
- 11–25 CA target politicians: 2 plans (split alphabetically or by district type)
- 26+ CA target politicians: planner may split further; use 3 plans

The known floor (9 politicians with unsourced stances) is near the ≤10 threshold, but weak-source detection will likely add more. The 107 DB-wide weak-source rows are predominantly in the State tier. If more than 25 CA politicians are flagged, Plan 02 should be split.

**Research batch sizing per agent dispatch:**
- Phase 101/102 precedent: 1 senator/candidate per agent invocation (narrow, focused)
- For CA state legislators: same rule — 1 politician per agent, sequentially. Do not batch multiple legislators into a single agent.
- Affected topics only per flagged politician (not all 44 topics) — unless the politician has a mix of unsourced and weak-source issues that spans many topics.

**Exception for CA politicians with many unsourced stances (e.g., Katy Hall with 3 unsourced):** The agent should be given only the affected topic_keys as the `--topics` argument. Do not re-research topics that already have real (non-homepage) source URLs.

---

## Plan 03 Scope — MD Officials

**5 officials × 44 live topics = up to 220 stance assessments.**

Dispatch order (suggested): alphabetical or by seniority — Wes Moore (Governor, most prominent), Aruna Miller (Lt. Gov.), Anthony G. Brown (AG), Brooke Lierman (Comptroller), Dereck E. Davis (Treasurer). One agent per official. Wait for each agent's CSV to be written before dispatching the next.

**City-level topic handling for MD officials:** MD officials are state-level executives. The SKILL.md city-level topic skip list applies: `transportation-priorities, economic-development, homelessness-response, residential-zoning, city-sanitation, local-immigration, rent-regulation, growth-and-development, local-environment, public-safety-approach, jail-capacity, judicial-*` — these should be skipped for state officials. Only research topics that apply at the state/federal level. (Since MD officials have NO existing stances, the Phase 102 "existing-stance exception" for the city-level skip rule does NOT apply here.)

**No deletion log for MD:** MD officials have zero existing stances. Any topic with no evidence found simply gets no stance row written. This is expected and does not require a deletion log entry.

**Migration structure for Plan 03:** All INSERT (no UPSERT / ON CONFLICT needed unless agents produce duplicate rows — possible if multiple MD officials share a topic). Safe to use ON CONFLICT DO UPDATE to be defensive. No DELETE statements. Migration is purely additive.

---

## Verification SQL (STAX-01 + STAX-02)

The planner should embed these as post-migration verification queries in `103-VERIFICATION.md`:

```sql
-- V1: STAX-01 — CA state unsourced stance count (must be 0)
SELECT COUNT(*) AS ca_unsourced_count
FROM inform.politician_answers pa
LEFT JOIN inform.politician_context pc
  ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
JOIN essentials.politicians p ON p.id = pa.politician_id AND p.is_active = true
WHERE EXISTS (
  SELECT 1 FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE o.politician_id = pa.politician_id
    AND o.is_vacant = false
    AND d.state = 'CA'
    AND d.district_type IN ('STATE_LOWER','STATE_UPPER','STATE_EXEC','STATE_BOARD')
)
AND (
  pc.politician_id IS NULL
  OR pc.sources IS NULL
  OR array_length(pc.sources, 1) IS NULL
  OR NOT EXISTS (
    SELECT 1 FROM unnest(pc.sources) AS s(url)
    WHERE url IS NOT NULL AND trim(url) <> ''
  )
);
-- Expected post-migration: 0

-- V2: STAX-01 — CA weak-source count (must be 0 after remediation)
SELECT COUNT(*) AS ca_weak_source_count
FROM inform.politician_context pc
JOIN inform.politician_answers pa
  ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
JOIN essentials.politicians p ON p.id = pa.politician_id AND p.is_active = true
WHERE EXISTS (
  SELECT 1 FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE o.politician_id = pa.politician_id
    AND o.is_vacant = false
    AND d.state = 'CA'
    AND d.district_type IN ('STATE_LOWER','STATE_UPPER','STATE_EXEC','STATE_BOARD')
)
AND NOT EXISTS (
  SELECT 1 FROM unnest(pc.sources) AS u(url)
  WHERE url IS NOT NULL AND trim(url) <> ''
    AND url !~ '^https?://[^/]+/?$'
);
-- Expected post-migration: 0

-- V3: STAX-02 — MD officials with zero stances (must be 0 post-Plan-03)
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
-- Expected: every official has > 0 stances; none remain at 0
```

---

## Existing CA Stance Research CSVs (Prior Work)

Two CA state senate research CSVs already exist in `backend/data/stance-research/`:
- `2026-05-22-ca-state-senate.csv` — older research, format uses `full_name` column
- `2026-05-31-ca-state-senate.csv` — newer research, format uses `politician_name` column, includes `external_id`

These are prior research artifacts from gap-fill work (not from the v2.7 source integrity methodology). **They should NOT be used directly for Plan 02 remediation** unless the URLs in those CSVs pass spot-check verification as real primary sources. If a politician's topic appears in these CSVs with a real (non-homepage) source URL, the planner may consider that as a potential "already researched" case — but the triage output is the authoritative scope for Plan 02. These CSVs do not replace the triage step.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `d.state = 'CA'` is a valid column on `essentials.districts` that distinguishes CA state records | CA Triage Script Pattern | Triage query fails or returns wrong scope; need to verify the actual column name/format for state identification in the districts table |
| A2 | CA statewide executives (governor, AG) have `district_type = 'STATE_EXEC'` in the DB | CA District Type Coverage | Newsom and other statewide officials would be missed by the triage if a different district type is used |
| A3 | Mike Braun (listed in Phase 100 State tier as having 1 unsourced stance) is Indiana Governor, not a CA official, and will be excluded by `d.state = 'CA'` filter | Live DB State | If Braun's office is somehow linked to a CA district record, he would appear incorrectly in CA triage results |
| A4 | Next available migration numbers are 270 and 271 | Migration Numbers | Collision if any migration was applied to the live DB between Phase 102 close (2026-06-06) and Phase 103 execution |
| A5 | The two existing CA state senate CSVs (2026-05-22, 2026-05-31) used the homepage-only pattern for some source URLs | Existing CA Stance Research CSVs | If those CSVs have real source URLs, some CA politicians may not need re-research; triage output will reveal this |

---

## Open Questions (Plan 01 Task 1 resolves Q1+Q2 via live DB pre-flight; Q3+Q4 resolved as "triage output is authoritative")

1. **What is the exact `district_type` for CA statewide executives (Gavin Newsom as governor)?**
   - What we know: district_type IN ('STATE_LOWER','STATE_UPPER','STATE_EXEC','STATE_BOARD') is the presumed set; `STATE_EXEC` is the most likely type for governor
   - What's unclear: whether the DB uses STATE_EXEC, STATEWIDE, or another value
   - Recommendation: Plan 01's first task should run `SELECT DISTINCT district_type FROM essentials.districts WHERE state = 'CA'` and log the results before writing the triage CTE

2. **Is `d.state` the correct column name for state filtering on `essentials.districts`?**
   - What we know: Phase 100 audit uses district_type to classify tiers; the CA triage requires a state filter
   - What's unclear: whether the column is named `state`, `state_code`, or embedded in the district name/geoid
   - Recommendation: Check `\d essentials.districts` or `SELECT column_name FROM information_schema.columns WHERE table_name = 'districts' AND table_schema = 'essentials'` in Plan 01

3. **How many CA state politicians are in the DB total (for sizing context)?**
   - What we know: CA has 80 Assembly seats and 40 Senate seats (120 state legislators) plus statewide executives (~6–10)
   - What's unclear: how many are in the DB as active politicians (some districts may be vacant or not yet seeded)
   - Recommendation: Plan 01 triage executive summary will report the total count; no action needed until triage runs

4. **Do the prior CA state senate CSVs (2026-05-22 and 2026-05-31) contain real source URLs or homepage-only sources?**
   - What we know: Files exist; newer one (2026-05-31) has Supabase leginfo.legislature.ca.gov URLs which look like real sources
   - What's unclear: whether those CSVs were fully ingested into the DB or only partially
   - Recommendation: Treat triage output as authoritative. If a topic appears in the triage as weak-sourced but leginfo.ca.gov is already in `politician_context.sources`, the triage will classify it correctly. No special handling needed.

---

## Validation Architecture

Workflow validation is data-migration-only. No unit tests or automated test suite applies here — stance data changes are validated via SQL queries, not application-level tests. The verification SQL in the Verification SQL section above constitutes the validation plan.

Per-plan verification:
- **Plan 01**: Script exits 0 + both artifacts (TRIAGE-REPORT.md, CA-TARGETS.csv) exist + CSV header matches locked shape
- **Plan 02**: V1 (CA unsourced count = 0) + V2 (CA weak-source count = 0) + QUAL-02 deletion log row count matches migration DELETE count
- **Plan 03**: V3 (MD officials all have > 0 stances) + every context row for each MD official has at least one non-blank non-homepage source URL

---

## Security Domain

No auth, session management, access control, or cryptographic changes in this phase. The only security-relevant pattern is the same as all prior remediation phases: `pool.query()` for all inform.* access (never service role PostgREST paths), and UUID literal resolution in migrations (no name-based injection risk since names are not user-controlled at migration time).

ASVS V5 (Input Validation) applies minimally to the migration SQL — source URL arrays must filter blank/null elements using the established `ARRAY(SELECT u FROM unnest(...) WHERE ...)` pattern.

---

## Sources

### Primary (HIGH confidence)
- `.planning/phases/103-state-remediation-ca-md/103-CONTEXT.md` — locked decisions D-01 through D-06, MD official UUIDs, plan structure
- `.planning/phases/100-source-coverage-audit/100-AUDIT-REPORT.md` — sourced definition (4-rule), weak-source count (107), tier breakdown, MD officials section
- `.planning/phases/100-source-coverage-audit/100-TARGET-LIST.csv` — 9 CA state politicians with unsourced stances (floor)
- `.claude/skills/research-stances/SKILL.md` — invocation rules, topic count (44), rate-limit rule, agent prompt template, Step 0 query
- `backend/scripts/run-house-source-triage.ts` — direct template for CA triage script (SOURCED_CASE, UNSOURCED_CASE, HOMEPAGE_ONLY_REGEX verbatim)
- `backend/scripts/run-source-coverage-audit.ts` — Query E (weak-source filter) and SOURCED_CASE/UNSOURCED_CASE originals
- `.planning/phases/102-federal-house-remediation/102-TRIAGE-REPORT.md` — Plan 01 triage output format template
- `.planning/phases/102-federal-house-remediation/102-01-PLAN.md` — Plan 01 task structure template (script build + run)
- `.planning/phases/102-federal-house-remediation/102-02-PLAN.md` — Plan 02 task structure (pre-flight, research dispatch, migration write, apply + verify)
- `.planning/STATE.md` §"v2.7 Source Integrity Patterns" — methodology rules (Chair methodology, deletion log format, sourced definition lock)
- `supabase/migrations/20260606000002_269_house_source_remediation.sql` — migration structure template; confirms last applied migration = 269

### Secondary (MEDIUM confidence)
- `.planning/phases/101-candidate-profiles/101-CONTEXT.md` — plan sizing thresholds (≤10 / 11–25 / 26+), deletion rules
- `backend/data/stance-research/2026-05-31-ca-state-senate.csv` — confirms CA state senators already have some leginfo.ca.gov source URLs (real sources) from prior research work

### Tertiary (LOW confidence)
- [A1–A5 in Assumptions Log] — assumptions about DB column names and district_type values that require verification in Plan 01 Task 1 before the triage CTE is written

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all tooling (psql, pg, tsx, dotenv) verified in use by Phases 101/102
- Architecture: HIGH — patterns are established from Phases 100–102; no new design decisions
- Pitfalls: HIGH — Pitfalls 1–4 are confirmed from prior phases; Pitfall 5 (ARRAY_CAT) is derived from locked CONTEXT.md D-05; Pitfall 6 (city-level skip rule) is confirmed from Phase 102 Plan 02 notes
- CA scope: MEDIUM — floor is known (9 politicians) but full scope (including weak-source) unknown until Plan 01 runs
- MD scope: HIGH — 5 officials, 44 topics, 0 existing stances — fully confirmed

**Research date:** 2026-06-06
**Valid until:** 2026-07-06 (stable domain — source integrity methodology is locked for v2.7; only the triage output numbers will change when Plan 01 runs)
