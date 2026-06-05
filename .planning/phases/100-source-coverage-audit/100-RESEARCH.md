# Phase 100: Source Coverage Audit - Research

**Researched:** 2026-06-05
**Domain:** PostgreSQL audit queries, inform/essentials schema, politician tier classification
**Confidence:** HIGH

---

## Summary

Phase 100 is a pure data-audit phase: run SQL against the live DB, produce a report showing what fraction of stances have real source URLs, and generate a ranked target list for remediation phases 101–104. No new schema, no API changes, no migrations — only read queries and a markdown deliverable committed to the repo.

The `inform.politician_answers` table stores stance values; `inform.politician_context` stores reasoning and a `sources TEXT[]` array. The two tables share a composite key `(politician_id, topic_id)`. A stance is "sourced" when its context row exists, `sources` is non-null, and `sources` contains at least one element that is not an empty string and is not an `ARRAY[]`. The critical discovery from reviewing migration 233 is that some CA Assembly stances were inserted with `ARRAY[]::text[]` (explicit empty array) where no evidence was found — these are the primary unsourced rows to surface. A small secondary category exists: homepage-only URLs (`https://sd07.senate.ca.gov`) with no path, which may be considered weak sourcing but technically pass the "non-empty source" test.

Tier is determined by joining `essentials.offices → essentials.districts` and classifying `district_type`:
- **Federal**: `NATIONAL_UPPER`, `NATIONAL_LOWER`, `NATIONAL_EXEC`, `NATIONAL_JUDICIAL`
- **State**: `STATE_UPPER`, `STATE_LOWER`, `STATE_EXEC`, `STATE_BOARD`, `JUDICIAL`
- **Local**: `LOCAL`, `LOCAL_EXEC`, `COUNTY`, `SCHOOL`
- **City**: `LOCAL`, `LOCAL_EXEC` (distinguished from county-level LOCAL by government name containing "City of")

All queries must use `pool.query()` (direct postgres via `pg` driver). The `inform` schema is not in the PostgREST exposed schema list — PostgREST calls will silently fail. The deliverable is a TypeScript audit script plus a markdown report committed to the phase directory.

**Primary recommendation:** Deliver a standalone TypeScript audit script (`backend/scripts/run-source-coverage-audit.ts`) that queries the DB and writes two outputs: a markdown summary report and a CSV target list. Both get committed to the phase directory alongside the PLAN files.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SRCA-01 | DB audit report — total stances, % sourced, breakdown by tier (Federal/State/Local/City) | SQL queries defined below using `inform.politician_answers` LEFT JOIN `inform.politician_context`, tier derived from `essentials.districts.district_type` |
| SRCA-02 | Prioritized target list — all politicians with unsourced stances ranked federal→state→local→city, majority-unsourced flag | SQL query groups by politician, calculates unsourced count and %, adds majority flag, ordered by tier rank then prominence |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| DB audit queries | Database / Storage | API / Backend (Node.js pool.query) | Read-only SQL against inform + essentials schemas |
| Report generation | API / Backend (Node.js script) | — | TypeScript script using pool.query(), writes markdown + CSV |
| Tier classification | Database / Storage | — | Derived from essentials.districts.district_type via SQL CASE |
| Deliverable storage | Static / Repo file | — | Markdown and CSV files committed to .planning/phases/100 |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `pg` | Already in backend/package.json | Direct Postgres queries | Required for all inform/essentials schema reads — PostgREST cannot access these schemas |
| TypeScript | Already configured | Audit script language | Matches existing script pattern (see audit-112-stances.ts, run-fec-finance-summary.ts) |
| `dotenv` | Already in backend/package.json | Load DATABASE_URL from .env | Same pattern as all existing scripts |

### No New Packages Required

This phase installs zero new packages. All tooling is already present in `backend/package.json`. The audit script follows the identical pattern of `backend/scripts/audit-112-stances.ts` and `backend/scripts/run-fec-finance-summary.ts`.

**Installation:** None required.

---

## Package Legitimacy Audit

No packages are being installed for this phase.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| (none) | — | — | — | — | — | N/A |

---

## Architecture Patterns

### System Architecture Diagram

```
.env (DATABASE_URL)
        │
        ▼
backend/scripts/run-source-coverage-audit.ts
        │
        ├── pool.query()  ──►  inform.politician_answers   (total stances)
        │                      inform.politician_context   (sources[] per stance)
        │                      essentials.politicians      (full_name)
        │                      essentials.offices          (politician → district join)
        │                      essentials.districts        (district_type → tier)
        │
        ├── Aggregate: total, sourced count, % by tier
        │
        ├── Rank: politicians by (tier priority, prominence/stance_count)
        │
        ├─── OUTPUT 1: 100-AUDIT-REPORT.md  (human-readable summary)
        └─── OUTPUT 2: 100-TARGET-LIST.csv  (machine-readable ranked list)
                          │
                          └── Consumed by planner for phases 101–104
```

### Recommended Project Structure

```
backend/
└── scripts/
    └── run-source-coverage-audit.ts    # New audit script

.planning/phases/100-source-coverage-audit/
├── 100-RESEARCH.md                     # This file
├── 100-PLAN.md                         # Planner output
├── 100-AUDIT-REPORT.md                 # Generated by running the script
└── 100-TARGET-LIST.csv                 # Generated by running the script
```

### Pattern 1: Stance Source Audit SQL

**What:** The core LEFT JOIN pattern that identifies unsourced stances.
**When to use:** SRCA-01 aggregate query and SRCA-02 per-politician query.

```sql
-- Source: codebase analysis of inform schema (migration 026, 253, 233, 234)
-- Identifies "unsourced" stance: no context row OR empty sources array OR sources is NULL
SELECT
  pa.politician_id,
  pa.topic_id,
  pc.sources,
  CASE
    WHEN pc.politician_id IS NULL THEN 'no_context_row'
    WHEN pc.sources IS NULL THEN 'null_sources'
    WHEN array_length(pc.sources, 1) IS NULL THEN 'empty_array'
    WHEN NOT EXISTS (
      SELECT 1 FROM unnest(pc.sources) AS s(url)
      WHERE url IS NOT NULL AND trim(url) <> ''
    ) THEN 'all_blank_elements'
    ELSE 'sourced'
  END AS source_status
FROM inform.politician_answers pa
LEFT JOIN inform.politician_context pc
  ON pc.politician_id = pa.politician_id
  AND pc.topic_id = pa.topic_id
```

Note: `array_length(arr, 1) IS NULL` is the correct Postgres idiom for an empty array — `array_length(ARRAY[]::text[], 1)` returns NULL, not 0.

### Pattern 2: Tier Classification via District Join

**What:** Derive the Federal/State/Local/City tier for a politician by joining through offices → districts.
**When to use:** Tier breakdown in SRCA-01; tier ranking in SRCA-02.

```sql
-- Source: codebase analysis of campaignFinanceSearchService.ts (jurisdiction_tier CASE) 
-- and essentialsService.ts (district_type handling)
-- Tier priority for ranking: 1=Federal (highest priority), 2=State, 3=Local, 4=City
-- Note: in campaign finance service the numeric scale is inverted (NATIONAL=3, LOCAL=1)
-- For v2.7 we use Federal=1 (highest) to match requirements ordering.
SELECT
  p.id,
  p.full_name,
  CASE
    WHEN d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER','NATIONAL_EXEC','NATIONAL_JUDICIAL')
      THEN 'Federal'
    WHEN d.district_type IN ('STATE_UPPER','STATE_LOWER','STATE_EXEC','STATE_BOARD','JUDICIAL')
      THEN 'State'
    WHEN d.district_type IN ('LOCAL','LOCAL_EXEC','COUNTY','SCHOOL')
      THEN 'Local'
    ELSE 'Unknown'
  END AS tier,
  CASE
    WHEN d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER','NATIONAL_EXEC','NATIONAL_JUDICIAL')
      THEN 1
    WHEN d.district_type IN ('STATE_UPPER','STATE_LOWER','STATE_EXEC','STATE_BOARD','JUDICIAL')
      THEN 2
    WHEN d.district_type IN ('LOCAL','LOCAL_EXEC','COUNTY','SCHOOL')
      THEN 3
    ELSE 4
  END AS tier_rank
FROM essentials.politicians p
LEFT JOIN essentials.offices o ON o.politician_id = p.id AND o.is_vacant = false
LEFT JOIN essentials.districts d ON d.id = o.district_id
WHERE p.is_active = true
```

**Caveat:** "City" vs "Local" distinction within the LOCAL/LOCAL_EXEC bucket requires a join to `essentials.governments` and checking whether `g.name` starts with "City of". The SRCA-01 requirement groups them as Federal/State/Local/City. In practice, the distinction between city council officials and county officials within the LOCAL tier can be made by filtering on `g.type = 'CITY'` vs. other government types. [ASSUMED — need to verify essentials.governments.type enum values from live DB]

### Pattern 3: Majority-Unsourced Flag

**What:** Flag politicians where unsourced stances exceed 50% of their total stances.
**When to use:** SRCA-02 target list — flags "full re-research" candidates vs. "spot fix" candidates.

```sql
-- Per-politician unsourced summary with majority flag
SELECT
  p.full_name,
  tier_subq.tier,
  tier_subq.tier_rank,
  COUNT(pa.topic_id) AS total_stances,
  SUM(CASE WHEN (pc.politician_id IS NULL
                 OR pc.sources IS NULL
                 OR array_length(pc.sources, 1) IS NULL)
           THEN 1 ELSE 0 END) AS unsourced_count,
  ROUND(
    SUM(CASE WHEN (pc.politician_id IS NULL
                   OR pc.sources IS NULL
                   OR array_length(pc.sources, 1) IS NULL)
             THEN 1.0 ELSE 0.0 END)
    / NULLIF(COUNT(pa.topic_id), 0) * 100, 1
  ) AS unsourced_pct,
  CASE
    WHEN SUM(CASE WHEN (pc.politician_id IS NULL
                        OR pc.sources IS NULL
                        OR array_length(pc.sources, 1) IS NULL)
                  THEN 1 ELSE 0 END)
         > COUNT(pa.topic_id) / 2.0
    THEN true ELSE false
  END AS majority_unsourced
FROM inform.politician_answers pa
JOIN essentials.politicians p ON p.id = pa.politician_id
LEFT JOIN inform.politician_context pc
  ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
LEFT JOIN (
  -- tier subquery — one row per politician
  SELECT DISTINCT ON (p2.id) p2.id AS pid,
    CASE
      WHEN d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER','NATIONAL_EXEC','NATIONAL_JUDICIAL')
        THEN 'Federal'
      WHEN d.district_type IN ('STATE_UPPER','STATE_LOWER','STATE_EXEC','STATE_BOARD','JUDICIAL')
        THEN 'State'
      WHEN d.district_type IN ('LOCAL','LOCAL_EXEC','COUNTY','SCHOOL')
        THEN 'Local'
      ELSE 'Unknown'
    END AS tier,
    CASE
      WHEN d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER','NATIONAL_EXEC','NATIONAL_JUDICIAL')
        THEN 1
      WHEN d.district_type IN ('STATE_UPPER','STATE_LOWER','STATE_EXEC','STATE_BOARD','JUDICIAL')
        THEN 2
      WHEN d.district_type IN ('LOCAL','LOCAL_EXEC','COUNTY','SCHOOL')
        THEN 3
      ELSE 4
    END AS tier_rank
  FROM essentials.politicians p2
  LEFT JOIN essentials.offices o ON o.politician_id = p2.id AND o.is_vacant = false
  LEFT JOIN essentials.districts d ON d.id = o.district_id
) tier_subq ON tier_subq.pid = p.id
WHERE p.is_active = true
GROUP BY p.full_name, p.id, tier_subq.tier, tier_subq.tier_rank
HAVING SUM(CASE WHEN (pc.politician_id IS NULL
                      OR pc.sources IS NULL
                      OR array_length(pc.sources, 1) IS NULL)
                THEN 1 ELSE 0 END) > 0
ORDER BY tier_subq.tier_rank NULLS LAST, p.full_name
```

### Pattern 4: Milestone-Specific Breakdown

**What:** Confirm sourcing state for each milestone cohort mentioned in SRCA-01 (v2.3 senators, v2.4 candidates, v2.5 city officials, migrations 269–271 MD officials).
**When to use:** SRCA-01 requires these cohorts be explicitly represented.

```sql
-- v2.3 senators: district_type = 'NATIONAL_UPPER'
-- v2.4 candidates: external_id range -400101 to -400143 (from memory log)
-- v2.5 city officials: represents politicians in San Jose/San Diego/Berkeley/Fremont governments
-- MD officials: external_id -240001 to -240005

-- Example: v2.3 senators
SELECT
  COUNT(pa.topic_id) AS total_senator_stances,
  SUM(CASE WHEN pc.sources IS NULL OR array_length(pc.sources,1) IS NULL THEN 1 ELSE 0 END) AS unsourced,
  ROUND(SUM(CASE WHEN pc.sources IS NULL OR array_length(pc.sources,1) IS NULL
                 THEN 1.0 ELSE 0.0 END) / COUNT(pa.topic_id) * 100, 1) AS unsourced_pct
FROM inform.politician_answers pa
LEFT JOIN inform.politician_context pc ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
JOIN essentials.offices o ON o.politician_id = pa.politician_id AND o.is_vacant = false
JOIN essentials.districts d ON d.id = o.district_id AND d.district_type = 'NATIONAL_UPPER'
```

### Pattern 5: Existing Script Structure (follow this)

**What:** The TypeScript audit script pattern already established in this codebase.
**When to use:** Building `run-source-coverage-audit.ts`.

```typescript
// Source: backend/scripts/audit-112-stances.ts — exact pattern
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';
import { writeFileSync } from 'node:fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

async function main() {
  // ... queries ...
  // Write to stdout OR to a file:
  writeFileSync(path.resolve(__dirname, '../../.planning/phases/100-source-coverage-audit/100-AUDIT-REPORT.md'), markdown);
  writeFileSync(path.resolve(__dirname, '../../.planning/phases/100-source-coverage-audit/100-TARGET-LIST.csv'), csv);
  await pool.end();
}

main().catch((err) => {
  console.error('Fatal error:', err);
  pool.end();
  process.exit(1);
});
```

**Run command:** `cd backend && npx tsx scripts/run-source-coverage-audit.ts`

### Anti-Patterns to Avoid

- **Using PostgREST for inform schema:** `supabaseAdmin.schema('inform').from(...)` will fail silently. Always use `pool.query()` for any inform.* read.
- **Treating `array_length(arr, 1) = 0` as empty:** Postgres returns NULL for empty arrays, not 0. Use `array_length(arr, 1) IS NULL` to detect empty arrays.
- **Counting context row existence as "sourced":** A context row with an empty sources array is NOT sourced. The check must verify non-null AND non-empty array AND at least one non-blank URL.
- **Forgetting orphan answers (no context row):** A stance in `politician_answers` with no matching row in `politician_context` is also unsourced. The LEFT JOIN with NULL check catches these.
- **Deriving tier only from office_title:** Use `essentials.districts.district_type`, not `essentials.offices.title` (e.g., title="Senator" applies to both US Senators and State Senators).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Empty array detection | Custom parsing | `array_length(arr, 1) IS NULL` | Postgres idiom — empty array returns NULL from array_length |
| Tier classification | String matching on office_title | `CASE` on `district_type` | office_title is inconsistent; district_type is the canonical discriminator |
| Script execution | New CLI tooling | `npx tsx scripts/*.ts` | Already used for all audit/ingest scripts in this repo |
| Report formatting | Template engine | String concatenation / template literals | Prior scripts (run-fec-finance-summary.ts) use this pattern; no templating dependency needed |

**Key insight:** Postgres array functions are the right tool for sources[] inspection. Hand-rolling array empty-detection in TypeScript by round-tripping the array through Node would add latency and complexity for no benefit.

---

## Known Data Facts (Verified from Migration Analysis)

### "Sourced" Definition (Operationalized)

A stance in `inform.politician_answers` counts as **sourced** when ALL of the following are true:
1. A row exists in `inform.politician_context` with the same `(politician_id, topic_id)`.
2. `sources` is NOT NULL.
3. `array_length(sources, 1)` is NOT NULL (i.e., the array is not empty).
4. At least one element of `sources` is a non-blank string (trim(element) != '').

Conditions that make a stance **unsourced**:
- Missing context row (orphan answer) [VERIFIED: migration 253 fixed exactly this case for CA legislature]
- Context row exists but `sources = ARRAY[]::text[]` (empty array) [VERIFIED: migration 233 contains 2 such entries for CA Assembly politicians where no evidence was found]
- Context row exists but `sources IS NULL` (defensive case; schema default is `'{}'` but early data cannot be assumed)

### Weak-Source Pattern (NOT counted as unsourced, but noted)

Some stances have homepage-only URLs with no specific path, e.g., `ARRAY['https://sd07.senate.ca.gov']::text[]`. These have a non-empty sources array and technically pass the "sourced" test. [VERIFIED: found in migrations 234 and 253 for Tim Grayson deportation/homelessness stances]

The v2.7 requirement says "at least one non-placeholder URL." Whether a root homepage URL counts as a placeholder is an open question (see Open Questions section). For the Phase 100 audit, these should be counted as **sourced** (to avoid false positives) but NOTED separately as "homepage-only sources." The QUAL-01 standard ("URL links to a primary source") would apply to these during remediation phases 101–104.

### v2.3 Senator Stances (Expected: Fully Sourced)

US Senate stances were ingested via CSV files from `backend/data/stance-research/2026-05-20-us-senate-batch*.csv`. Review of these CSVs shows real URLs (ontheissues.org, official Senate pages, Wikipedia articles with specific paths). These are expected to be sourced. [VERIFIED: sampled batches 10, 13 from data directory]

### v2.4 Candidate Stances (Expected: Fully Sourced)

2026 Senate candidate stances were ingested via migrations 197, 198, 207. Review of migration 197 shows real campaign site and news URLs. [VERIFIED: migration 197 sampled]

### v2.5 City Official Stances (Expected: Mix — SJ/Sacramento minimal)

- SF officials: migration 216 (stances) — expected sourced (pattern established in v2.5)
- SD officials: migrations 244, 250 — expected sourced
- Berkeley officials: migration 256 — expected sourced  
- Fremont officials: migration 219 — expected sourced
- San Jose officials: migration 221 — Matt Mahan only per v2.6 roadmap note. Other SJ officials may have NO stances at all.
- Sacramento officials: migration 221 or later — coverage may be incomplete. [ASSUMED — need to verify against live DB]

### Migration 269–271 MD Officials (Expected: Zero Stances)

The MD officials (Wes Moore, Aruna Miller, Anthony Brown, Brooke Lierman, Dereck Davis) were added in migrations 269 (chambers), 270 (politicians + offices), 271 (headshots). No stance migration exists for them. Their `politician_answers` count is expected to be zero. [VERIFIED: no MD stance migration found in backend/migrations/]

### CA Assembly and Senate Stances (Expected: Mostly Sourced, Some Empty Array)

- CA Assembly: migration 233 — 2 stances with `ARRAY[]::text[]` confirmed. Total ~1,500+ rows. [VERIFIED]
- CA State Senate: migration 234 — 0 instances of `ARRAY[]::text[]`. Some homepage-only URLs. [VERIFIED]
- Note from migration 234 header: 13 senators were explicitly missing (Susan Rubio, Suzette Valladares, Sasha Perez, Thomas Umberg, Tony Strickland, Steve Padilla, Rosilicie Ochoa Bogh, Sabrina Cervantes, Steven Choi, Scott Wiener, Shannon Grove, Tim Grayson, Roger Niello). Of these, Tim Grayson and Roger Niello got context rows via migration 253. The remaining 11 may still have unsourced or missing stances. [VERIFIED: from migration 234 header comment]

---

## Common Pitfalls

### Pitfall 1: DISTINCT ON Required for Multi-Office Politicians
**What goes wrong:** A politician with multiple office rows (e.g., appointed then elected to a new seat) produces duplicate rows in the tier join, inflating counts.
**Why it happens:** essentials.offices can have multiple rows per politician_id; LEFT JOIN without DISTINCT produces a Cartesian product.
**How to avoid:** Use `DISTINCT ON (p.id)` in the tier subquery, or use `MIN(CASE WHEN ...) OVER (PARTITION BY p.id)` window function.
**Warning signs:** Total stances count in TypeScript exceeds expected count from a simple `SELECT COUNT(*) FROM inform.politician_answers`.

### Pitfall 2: is_active Filter on Politicians
**What goes wrong:** Including inactive politicians inflates the "unsourced" count with records that are intentionally hidden (historical candidates, vacant seats filled by replacements, etc.).
**Why it happens:** essentials.politicians has `is_active` column; old/inactive records are not deleted but are excluded from frontend display.
**How to avoid:** Always filter `WHERE p.is_active = true` in the main audit queries.
**Warning signs:** Politician count much higher than expected (~1,049 was the v2.6 baseline per STATE.md).

### Pitfall 3: Orphan Context Rows Not Counted as Unsourced
**What goes wrong:** Counting only rows where `pc.politician_id IS NULL` misses the case where a context row exists but has an empty sources array.
**Why it happens:** Two failure modes exist — missing context row AND empty-sources context row. Migration 253 specifically fixed orphan ANSWER rows (answers without context), confirming this distinction matters.
**How to avoid:** The source status check must examine BOTH the join result (IS NULL → no context row) AND the sources array content (even when context row exists).
**Warning signs:** Audit shows 0 unsourced but you know migration 233 inserted 2 empty-array rows.

### Pitfall 4: Wrong Path for Output Files
**What goes wrong:** Script writes report to current working directory instead of the phase directory.
**Why it happens:** `process.cwd()` in the script resolves to `backend/` when run as `cd backend && npx tsx scripts/...`, but the report should go to `.planning/phases/100-source-coverage-audit/`.
**How to avoid:** Use `__dirname` + `path.resolve` with `../../` to navigate to the repo root, as shown in Pattern 5 above.
**Warning signs:** Report appears in `backend/` directory rather than `.planning/phases/100-source-coverage-audit/`.

### Pitfall 5: MD Officials Appear as "Politicians with Zero Stances" vs. "Politicians with Unsourced Stances"
**What goes wrong:** The SRCA-02 requirement asks for "politicians with any unsourced stances" — the MD officials have ZERO stances, so they won't appear in a query joining `inform.politician_answers`. They need to be shown explicitly in the audit even though they have no stance rows.
**Why it happens:** The source audit query starts from `inform.politician_answers` — it can only find politicians who have at least one answer. MD officials need a separate query from `essentials.politicians` filtered to their external_id range.
**How to avoid:** Include a separate section in the audit report that explicitly lists MD officials with zero stances, confirming their state before Phase 103 research.
**Warning signs:** MD officials don't appear anywhere in the SRCA-02 target list.

---

## Deliverable Format

The Phase 100 deliverable consists of two files generated by running the audit script:

### 100-AUDIT-REPORT.md

A markdown document committed to `.planning/phases/100-source-coverage-audit/` containing:

1. **Executive Summary** — total stances, total sourced, total unsourced, % sourced overall
2. **Tier Breakdown Table** — one row per tier (Federal/State/Local/City) with total stances, sourced count, unsourced count, % sourced
3. **Milestone Cohort Table** — explicit rows for v2.3 senators, v2.4 candidates, v2.5 city officials, migrations 269–271 MD officials
4. **"Sourced" Definition** — the operationalized definition locked for the rest of v2.7
5. **Weak Sources Note** — count of stances with homepage-only URLs (technically sourced but weak)

### 100-TARGET-LIST.csv

A CSV committed alongside the report containing:

```
full_name,politician_id,tier,tier_rank,total_stances,unsourced_count,unsourced_pct,majority_unsourced
"Wes Moore",<uuid>,State,2,0,0,0.0,false
...
```

Sorted by: tier_rank ASC, majority_unsourced DESC (full-re-research cases first within tier), unsourced_count DESC.

Phases 101–104 consume this CSV to scope their work.

---

## Runtime State Inventory

> Phase 100 is a read-only audit phase. No runtime state is changed.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | `inform.politician_answers` + `inform.politician_context` — read-only; no writes | None |
| Live service config | None affected | None |
| OS-registered state | None affected | None |
| Secrets/env vars | DATABASE_URL read from backend/.env | None — already configured |
| Build artifacts | None affected | None |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js + tsx | Running audit script | ✓ (used by all existing scripts) | See package.json | — |
| DATABASE_URL | pool.query() DB connection | ✓ (used by all backend scripts) | — | — |
| `pg` package | Direct Postgres queries | ✓ (in backend/package.json) | — | — |
| Supabase remote DB | Live data | ✓ (production Supabase, always available) | — | — |

**Missing dependencies with no fallback:** None.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | No automated tests for audit scripts (data-quality phase, same as Phases 87, 89) |
| Config file | N/A |
| Quick run command | `cd backend && npx tsx scripts/run-source-coverage-audit.ts --dry-run` |
| Full run command | `cd backend && npx tsx scripts/run-source-coverage-audit.ts` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SRCA-01 | Audit report with tier breakdown produced | manual-only | Run script, inspect output | ❌ Wave 0 |
| SRCA-02 | Target list CSV produced with rankings | manual-only | Run script, verify CSV structure | ❌ Wave 0 |

Manual verification: inspect 100-AUDIT-REPORT.md for expected sections; verify 100-TARGET-LIST.csv has correct columns and MD officials appear with 0 stances in a separate section.

**Justification for manual-only:** This is a pure data audit phase — the deliverable IS the output of the audit run. Automated tests would need to mock the live DB state, which defeats the purpose of an audit. Pattern is identical to Phases 87 and 89 (nyquist_compliant: false, same rationale).

### Wave 0 Gaps

- [ ] `backend/scripts/run-source-coverage-audit.ts` — the audit script itself
- [ ] `.planning/phases/100-source-coverage-audit/100-AUDIT-REPORT.md` — generated output
- [ ] `.planning/phases/100-source-coverage-audit/100-TARGET-LIST.csv` — generated output

---

## Security Domain

> `security_enforcement` not explicitly set to false in config.json — treating as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Audit script uses service-role DATABASE_URL (local only, not an API endpoint) |
| V3 Session Management | No | No session management — script-only |
| V4 Access Control | No | Not an API endpoint |
| V5 Input Validation | No | No user input; all data from DB |
| V6 Cryptography | No | No crypto operations |

### Known Threat Patterns

No runtime threat surface. The audit script:
- Runs locally only (not deployed to Render)
- Uses DATABASE_URL from local `.env` (never committed)
- Produces only read-only markdown/CSV output
- Has no web-facing interface

The only risk is accidental exposure of DB credentials if the report itself embedded raw connection strings — ensure the script outputs only statistics, not connection metadata.

---

## Open Questions (RESOLVED)

1. **Homepage-only URLs — are they "placeholder" for v2.7?**
   - What we know: Some stances (primarily Tim Grayson deportation/homelessness, SD-27 stances in migration 234) have `ARRAY['https://sd07.senate.ca.gov']` with no specific path. These have non-empty sources arrays.
   - What's unclear: The SRCA-01 definition says "non-placeholder URL" — does a root homepage URL count as a placeholder? Under strict QUAL-01 reading (Phase 101+), "every URL links to a primary source" would flag these. But for the Phase 100 audit count, treating them as unsourced would skew the baseline.
   - RESOLVED: Count them as "sourced" for SRCA-01 total counts (they do have a source array element), but emit a separate "weak sources" count in the audit report so remediation phases can decide whether to remediate them. This preserves a clean operational definition while flagging the cases.

2. **San Jose and Sacramento stance coverage**
   - What we know: Phase 78 completion note says "SJ: Matt Mahan only" — San Jose City Council members other than the mayor may have no stances. Sacramento officials were added informally extending CSTA-04.
   - What's unclear: Exact count of SJ/Sacramento officials with zero stances vs. some stances.
   - RESOLVED: The audit script will reveal this definitively. No pre-planning decision needed — the audit is the answer.

3. **City tier isolation from Local tier**
   - What we know: The v2.7 requirements ask for Federal/State/Local/City breakdown. Both city council officials and county officials use `district_type = 'LOCAL'` or `'LOCAL_EXEC'`.
   - What's unclear: The exact `essentials.governments.type` enum values that distinguish city-level governments from county or other local governments.
   - RESOLVED: Join through `essentials.governments g` and check `g.name ILIKE 'City of %'` to split LOCAL into City vs. non-City. If the join is fragile, report all LOCAL as "Local/City" combined with a note, then break out city officials by filtering known city government UUIDs (SF, SJ, SD, Berkeley, Fremont — known from migrations).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Sacramento city officials have at least some stances in `inform.politician_answers` | Known Data Facts (City Official section) | Sacramento section of audit report would show 0 stances; would affect Phase 104 scope |
| A2 | `essentials.governments.type` can be used to distinguish "City of X" governments from county/state governments | Architecture Patterns (Pattern 2) | City tier breakdown in SRCA-01 might need to use `g.name LIKE 'City of %'` instead; functionally equivalent but different SQL |
| A3 | All v2.3 US Senator stances have real source URLs (not empty arrays) | Known Data Facts (v2.3 section) | Phase 101 scope would be larger than expected; the audit will reveal this definitively |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| PostgREST for inform schema reads | `pool.query()` direct postgres | Phase 35 (v1.6) | inform/essentials schemas not in PostgREST exposed list; all reads must use pg driver |
| Inline script SQL (no TypeScript type annotations) | TypeScript-typed audit scripts with `tsx` | Phase 87+ | Matches existing script patterns; better maintainability |
| Audit report as a phase plan comment | Standalone markdown file committed to phase directory | Phase 87 introduced `87-AUDIT-REPORT.md` | Reports are now first-class artifacts, not embedded in plans |

**Deprecated/outdated:**
- `inform.politicians` table: was the canonical politicians table through Phase 35. After migration 058, `essentials.politicians` is canonical for all politician records. `inform.politician_answers` and `inform.politician_context` still use `essentials.politicians.id` as FK — confirmed by migration 058 which rewrote `admin_list_politicians()` to join against `essentials.politicians`.

---

## Sources

### Primary (HIGH confidence)
- `backend/migrations/026_inform_schema_repair_and_candidates.sql` — definitive schema for `inform.politician_answers` and `inform.politician_context`, including `sources TEXT[] NOT NULL DEFAULT '{}'`
- `backend/migrations/058_admin_list_politicians_fix_schema.sql` — confirms `essentials.politicians` is canonical FK target; `inform.politicians` is abandoned
- `backend/migrations/233_ca_assembly_stances.sql` — confirms `ARRAY[]::text[]` is the real empty-sources pattern used in the codebase (2 instances found)
- `backend/src/lib/campaignFinanceSearchService.ts` — provides the canonical `CASE district_type` tier classification SQL used in the codebase
- `backend/scripts/audit-112-stances.ts` — establishes the TypeScript audit script pattern to follow

### Secondary (MEDIUM confidence)
- `backend/migrations/234_ca_state_senate_stances.sql` — confirms 13 CA senators lacked stance coverage as of migration 234; Grayson/Niello fixed by migration 253; remaining 11 senators' status is unknown without querying live DB
- `backend/migrations/253_fix_ca_legislature_orphan_context_rows.sql` — confirms "orphan answer" (answer row with no context row) is a real data pattern that has occurred and been fixed before; the audit must check for this
- `.planning/milestones/v2.6-ROADMAP.md` — Phase 87 audit approach: SQL-based report, standalone markdown file, `87-AUDIT-REPORT.md` naming convention

### Tertiary (LOW confidence)
- Memory log note: "v2.5 Phase 78 completion note: SJ: Matt Mahan only" — San Jose coverage may be thin; unverified until live DB query

---

## Metadata

**Confidence breakdown:**
- Schema: HIGH — verified directly from migration SQL files
- SQL patterns: HIGH — derived from existing codebase patterns (campaignFinanceSearchService.ts, audit-112-stances.ts)
- Data state: MEDIUM — some facts (CA senator coverage, SJ/Sacramento) require live DB query to confirm; confirmed only from migration comments
- Deliverable format: HIGH — consistent with Phase 87 precedent

**Research date:** 2026-06-05
**Valid until:** 2026-07-05 (schema is stable; data state only changes with new migrations)
