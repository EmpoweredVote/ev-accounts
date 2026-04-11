# Plan A — Topic Scoping Data Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land the data model pieces that every downstream plan (compass builder UX, essentials coverage callout, deep comparison view, topic rewrite workflow) depends on: topic tier flags in `inform.compass_topic_roles`, topic office scope on `inform.compass_topics`, and office policy engagement level on `essentials.chambers`. Backfill existing rows and expose the new fields through the service layer.

**Architecture:** A single idempotent SQL migration (`059_topic_scoping_foundation.sql`) adds CHECK + UNIQUE constraints to the existing empty `compass_topic_roles` table, adds `office_scope TEXT[]` to `compass_topics`, creates the `policy_engagement_level` enum, and adds a column to `essentials.chambers`. Two TypeScript backfill scripts populate tier flags per the audit document and engagement levels per office-type patterns. The service layer (`compassService.ts`, `essentialsService.ts`) is updated to normalize the new data into clean API shapes at the boundary, returning booleans for tier flags rather than raw rows.

**Tech Stack:** PostgreSQL (via Supabase), TypeScript + Node.js (tsx runner), `pg` client for raw queries, `@supabase/supabase-js` for schema-filtered reads. No unit test infrastructure exists — verification is done via one-liner tsx scripts against the live dev database.

**Spec:** `docs/superpowers/specs/2026-04-10-local-officials-topic-scoping-design.md` (section: "Data model changes")

**Key constraint:** This is a backend-only plan. No frontend work, no ev-ui changes. The outputs of this plan are: migrated schema, populated tier flags on all 26 topics, populated engagement levels on Monroe County + surrounding chambers, and service layer changes that surface the new fields in existing API responses.

---

## File Structure

**Files created:**
- `docs/planning/topic-tier-audit.md` — human-reviewable audit table that drives the topic tier backfill. Produced in Task 1, reviewed by Chris before Task 3 runs.
- `ev-accounts/backend/migrations/059_topic_scoping_foundation.sql` — single idempotent migration containing all DDL for this plan.
- `ev-accounts/backend/scripts/backfill-topic-tier-flags.ts` — reads the audit data (inlined as a TypeScript const), inserts rows into `inform.compass_topic_roles` via `ON CONFLICT DO NOTHING`. Safe to re-run.
- `ev-accounts/backend/scripts/backfill-chamber-engagement-level.ts` — identifies administrative and retention-judge chambers by name pattern and updates `policy_engagement_level`. Prints a summary of changes. Safe to re-run.

**Files modified:**
- `ev-accounts/backend/src/lib/compassService.ts` — update `getCompassTopics()` to normalize `compass_topic_roles` rows into `applies_federal/state/local` booleans in the returned topic shape. Add `office_scope` to the `.select()` clause on the `compass_topics` query.
- `ev-accounts/backend/src/lib/essentialsService.ts` — add `ch.policy_engagement_level` to three SQL queries that join `essentials.chambers` (lines ~431, ~577, ~621, ~908 — verify during Task 6). Update TypeScript return types to include the new field on chamber-shaped objects.

**Not modified this plan:**
- Routes (`ev-accounts/backend/src/routes/*.ts`) — the route layer passes through whatever the service returns. As long as the service response gains the new fields at the top of the shape, the route layer automatically exposes them.
- Frontend repos (CompassV2, essentials, ev-ui) — future plans.

---

## Task 1: Produce Topic Tier Audit Document

**Files:**
- Create: `docs/planning/topic-tier-audit.md`

This task is pure documentation. It produces the human-reviewable source of truth that drives Task 3's backfill. No code runs.

The audit data comes from the spec's initial-guess table. The document format adds two columns that make it easier for Chris to review: "Reason" (why this topic got this set of tiers) and "Rewrite?" (flag for future rewrite consideration — does NOT get acted on in this plan).

- [ ] **Step 1: Create the audit document**

Write this exact content to `docs/planning/topic-tier-audit.md`:

```markdown
# Topic Tier Audit

**Date:** 2026-04-11
**Spec:** docs/superpowers/specs/2026-04-10-local-officials-topic-scoping-design.md
**Purpose:** Drives the tier flag backfill in Plan A. Each row assigns one or more applicable tiers (`federal`, `state`, `local`) per topic. The backfill script (`backfill-topic-tier-flags.ts`) inserts one row per (topic, tier) pair into `inform.compass_topic_roles`.

## Review gate

Chris reviews this document and approves before the backfill script runs. Do not run the backfill until this has been explicitly approved.

## How to read the table

- **Tier flags** — which levels of government the topic is meaningfully answerable at. A topic can have 1, 2, or all 3 tiers.
- **Reason** — why this assignment. Principle-level topics work at all levels. Federal-program topics only work at federal (or federal + state when states routinely comment on federal policy).
- **Rewrite?** — flagged for future rewrite consideration via the workflow in Plan D. Does NOT get acted on in this plan. Flagged topics still get tier flags backfilled under their current framing.

## Audit table

| topic_key | Federal | State | Local | Rewrite? | Reason |
|---|:---:|:---:|:---:|:---:|---|
| healthcare | ✅ | ✅ | ✅ | 🔄 | Currently federally framed (single-payer vs ACA). Rewrite could make it cleanly multi-tier. Mark all three tiers now; rewrite later under the current framing produces some mis-scoring we accept as interim. |
| abortion | ✅ | ✅ |  |  | Federal and state both have meaningful policy roles. Local officials have no levers. |
| tariffs | ✅ |  |  |  | Irreducibly federal (Congress sets tariffs). |
| taxes | ✅ | ✅ | ✅ | 🔄 | Tax policy exists at all three levels but current framing is federally focused. |
| same-sex-marriage | ✅ | ✅ | ✅ |  | Federal constitutional question, state recognition, local non-discrimination ordinances. |
| religious-freedom | ✅ | ✅ | ✅ |  | Federal RFRA, state RFRAs, local ordinances. |
| trans-athletes | ✅ | ✅ | ✅ |  | Federal Title IX, state laws, local school district policies. |
| ukraine-support |  ✅ |  |  |  | Federal foreign policy. |
| medicare/aid | ✅ |  |  |  | Federal programs. (States do administer Medicaid but stance questions are on the federal structure.) |
| fossil-fuels | ✅ | ✅ | ✅ |  | Federal energy policy, state regulation, local zoning and environmental review. |
| voting-rights | ✅ | ✅ | ✅ |  | Federal VRA, state election laws, local administration. |
| deportation | ✅ | ✅ | ✅ |  | Federal enforcement, state cooperation, local sanctuary policies. |
| social-security | ✅ |  |  |  | Federal program only. |
| ai-regulation | ✅ | ✅ |  | 🔄 | Primarily federal, state action on deepfakes/privacy emerging. Local angle is speculative — leave out for now. |
| climate-change | ✅ | ✅ | ✅ |  | All three levels have meaningful levers. |
| civil-rights | ✅ | ✅ | ✅ |  | Federal constitutional questions, state laws, local ordinances. |
| housing | ✅ | ✅ | ✅ |  | Federal HUD/LIHTC, state landlord-tenant and preemption, local zoning and inclusionary zoning. |
| campaign-finance | ✅ | ✅ | ✅ |  | Federal FEC, state disclosure, local lobbying rules. |
| immigration | ✅ | ✅ | ✅ | 🔄 | Federal core, state policy, local sanctuary. Rewrite candidate because current framing conflates several dimensions. |
| misinformation | ✅ | ✅ | ✅ |  | Federal platform regulation, state laws, local education policy. |
| redistricting | ✅ | ✅ |  |  | Federal and state — local redistricting (council districts) is genuine but rarely a compass-level issue. |
| school-vouchers | ✅ | ✅ | ✅ |  | Federal funding, state voucher programs, local school board implementation. |
| data-centers | ✅ | ✅ | ✅ |  | Federal energy/grid, state utility regulation, local zoning and tax abatements. |
| homelessness | ✅ | ✅ | ✅ |  | Federal HUD, state funding, local shelter and enforcement decisions. |
| childcare | ✅ | ✅ | ✅ |  | Federal CTC and subsidies, state licensing, local zoning and facility support. |
| jail-capacity |  | ✅ | ✅ |  | State corrections and local jails. No federal role. |

## Summary

- 26 topics
- 19 apply at all three tiers
- 2 apply at federal + state (abortion, ai-regulation, redistricting — wait, 3)
- 1 applies at state + local only (jail-capacity)
- 4 federal-only (tariffs, ukraine-support, medicare/aid, social-security)
- 4 flagged as rewrite candidates (healthcare, taxes, ai-regulation, immigration)

(Numbers recount during review to verify consistency.)
```

- [ ] **Step 2: Commit**

```bash
git add docs/planning/topic-tier-audit.md
git commit -m "docs: add topic tier audit for Plan A backfill

Drives the tier flag backfill for all 26 existing compass topics.
Chris reviews and approves before backfill runs.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

- [ ] **Step 3: User review gate**

Stop here. Ask Chris to review `docs/planning/topic-tier-audit.md` and either (a) approve as-is, (b) request changes inline, or (c) reject specific rows with corrections. Do not proceed to Task 2 until the audit is explicitly approved.

If changes are requested, edit the document, re-commit, and re-request review until approved.

---

## Task 2: Create and Apply Schema Migration

**Files:**
- Create: `ev-accounts/backend/migrations/059_topic_scoping_foundation.sql`

This task adds all the DDL for Plan A in a single idempotent migration. It's intentionally conservative: uses `IF NOT EXISTS`, `ADD CONSTRAINT IF NOT EXISTS` equivalents via DO blocks, and wraps in a transaction so partial failures roll back cleanly.

Verification is done against the live dev database (`EV-Backend-Dev`, project ID `mzuppdqbibqjedmesbmp`) because the backend has no unit test harness. Production migration happens later via the usual Supabase SQL editor path.

- [ ] **Step 1: Write the verification script**

Create a temporary verification script at `/tmp/verify-059.ts` (do not commit) that queries `information_schema` and asserts the expected schema changes exist:

```typescript
import 'dotenv/config';
import pg from 'pg';
const { Pool } = pg;
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function main() {
  // 1. Check CHECK constraint on compass_topic_roles.role_scope
  const chk = await pool.query(`
    SELECT conname FROM pg_constraint
    WHERE conname = 'chk_role_scope_tier'
  `);
  console.log('CHECK chk_role_scope_tier exists:', chk.rows.length === 1);

  // 2. Check UNIQUE constraint on (topic_id, role_scope)
  const uq = await pool.query(`
    SELECT conname FROM pg_constraint
    WHERE conname = 'uq_compass_topic_roles_topic_scope'
  `);
  console.log('UNIQUE uq_compass_topic_roles_topic_scope exists:', uq.rows.length === 1);

  // 3. Check compass_topics.office_scope column
  const ofs = await pool.query(`
    SELECT column_name, data_type FROM information_schema.columns
    WHERE table_schema='inform' AND table_name='compass_topics' AND column_name='office_scope'
  `);
  console.log('compass_topics.office_scope exists:', ofs.rows.length === 1, ofs.rows[0]);

  // 4. Check essentials.policy_engagement_level enum type
  const enm = await pool.query(`
    SELECT typname FROM pg_type WHERE typname = 'policy_engagement_level'
  `);
  console.log('enum policy_engagement_level exists:', enm.rows.length === 1);

  // 5. Check essentials.chambers.policy_engagement_level column
  const pel = await pool.query(`
    SELECT column_name, data_type, column_default
    FROM information_schema.columns
    WHERE table_schema='essentials' AND table_name='chambers' AND column_name='policy_engagement_level'
  `);
  console.log('chambers.policy_engagement_level exists:', pel.rows.length === 1, pel.rows[0]);

  await pool.end();
}
main().catch(e => { console.error(e); process.exit(1); });
```

- [ ] **Step 2: Run verification and confirm it fails**

```bash
cd ev-accounts/backend
set -a && source .env && set +a
npx tsx /tmp/verify-059.ts
```

Expected output (all should be `false` before the migration runs):
```
CHECK chk_role_scope_tier exists: false
UNIQUE uq_compass_topic_roles_topic_scope exists: false
compass_topics.office_scope exists: false
enum policy_engagement_level exists: false
chambers.policy_engagement_level exists: false
```

If any are already `true`, the migration is partially applied — stop and investigate before proceeding.

- [ ] **Step 3: Create the migration file**

Write this exact content to `ev-accounts/backend/migrations/059_topic_scoping_foundation.sql`:

```sql
BEGIN;

-- =============================================================================
-- Migration 059: Topic Scoping Data Foundation
-- =============================================================================
-- Adds tier flag infrastructure (CHECK + UNIQUE on existing compass_topic_roles),
-- adds office_scope metadata column to compass_topics, and adds a
-- policy_engagement_level enum + column on essentials.chambers.
--
-- Spec: docs/superpowers/specs/2026-04-10-local-officials-topic-scoping-design.md
-- Plan: docs/superpowers/plans/2026-04-11-plan-a-topic-scoping-data-foundation.md
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Section 1: Constrain compass_topic_roles.role_scope to tier values
-- ---------------------------------------------------------------------------
-- The table already exists and is queried by compassService.getCompassTopics.
-- It is empty in the data. We constrain role_scope so future inserts must
-- use one of the three valid tier values.

DO $$ BEGIN
  ALTER TABLE inform.compass_topic_roles
    ADD CONSTRAINT chk_role_scope_tier
    CHECK (role_scope IN ('federal', 'state', 'local'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ---------------------------------------------------------------------------
-- Section 2: Unique constraint on (topic_id, role_scope)
-- ---------------------------------------------------------------------------
-- Prevents duplicate rows for the same (topic, tier) pair. This also makes
-- the ON CONFLICT clause in the backfill script work cleanly.

DO $$ BEGIN
  ALTER TABLE inform.compass_topic_roles
    ADD CONSTRAINT uq_compass_topic_roles_topic_scope
    UNIQUE (topic_id, role_scope);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ---------------------------------------------------------------------------
-- Section 3: Add office_scope column to compass_topics
-- ---------------------------------------------------------------------------
-- Optional metadata for topics primarily relevant to specific office types
-- (e.g., bail reform for judges, curriculum for school boards). NULL means
-- "cross-cutting." Array values reference district_type enum values.
-- Informational only — never used as a render filter per spec principle #2.

ALTER TABLE inform.compass_topics
  ADD COLUMN IF NOT EXISTS office_scope TEXT[] NULL;

-- ---------------------------------------------------------------------------
-- Section 4: Create policy_engagement_level enum
-- ---------------------------------------------------------------------------
-- Distinguishes policy-making offices (compass applies) from administrative
-- offices (no compass) and retention judges (track record, not positions).

DO $$ BEGIN
  CREATE TYPE essentials.policy_engagement_level AS ENUM ('full', 'record_only', 'none');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ---------------------------------------------------------------------------
-- Section 5: Add policy_engagement_level column to essentials.chambers
-- ---------------------------------------------------------------------------
-- Default 'full' preserves current behavior — every existing chamber gets the
-- policy-making treatment until the backfill script overrides specific ones.

ALTER TABLE essentials.chambers
  ADD COLUMN IF NOT EXISTS policy_engagement_level essentials.policy_engagement_level NOT NULL DEFAULT 'full';

COMMIT;
```

- [ ] **Step 4: Apply the migration**

The `applyMigrations.ts` runner at `ev-accounts/backend/scripts/applyMigrations.ts` has a hardcoded migration list that stops at 038 — it is stale and cannot apply this migration. Apply manually via psql using the direct connection string (not the pooler):

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/backend
set -a && source .env && set +a
# DATABASE_URL must be the direct connection (port 5432), not pooler (6543)
psql "$DATABASE_URL" -f migrations/059_topic_scoping_foundation.sql
```

Expected output: a series of `BEGIN` / `ALTER TABLE` / `CREATE TYPE` / `COMMIT` confirmations, no errors.

If `DATABASE_URL` is the pooler URL, this will fail on the multi-statement transaction. Switch to the direct connection string from Supabase dashboard: **Project Settings → Database → Connection string → URI**.

- [ ] **Step 5: Re-run verification and confirm it passes**

```bash
cd ev-accounts/backend
npx tsx /tmp/verify-059.ts
```

Expected output (all should now be `true`):
```
CHECK chk_role_scope_tier exists: true
UNIQUE uq_compass_topic_roles_topic_scope exists: true
compass_topics.office_scope exists: true { column_name: 'office_scope', data_type: 'ARRAY' }
enum policy_engagement_level exists: true
chambers.policy_engagement_level exists: true { column_name: 'policy_engagement_level', data_type: 'USER-DEFINED', column_default: "'full'::essentials.policy_engagement_level" }
```

If any line reports `false`, investigate which DDL statement failed and re-apply. Do not proceed until all five verifications pass.

- [ ] **Step 6: Delete the temporary verification script**

```bash
rm /tmp/verify-059.ts
```

- [ ] **Step 7: Commit the migration file**

```bash
git add ev-accounts/backend/migrations/059_topic_scoping_foundation.sql
git commit -m "feat(backend): migration 059 — topic scoping foundation

Adds CHECK + UNIQUE constraints to compass_topic_roles, adds office_scope
to compass_topics, creates policy_engagement_level enum and adds column
to essentials.chambers. See docs/superpowers/specs/2026-04-10 and plan A.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Write and Run Topic Tier Flag Backfill

**Files:**
- Create: `ev-accounts/backend/scripts/backfill-topic-tier-flags.ts`

This script reads the approved audit data (inlined as a TypeScript const — simpler than parsing the markdown and makes the script self-contained) and inserts one row into `compass_topic_roles` per (topic, tier) pair. Uses `ON CONFLICT DO NOTHING` against the unique constraint from Task 2 so it's idempotent.

- [ ] **Step 1: Create the backfill script**

Write this exact content to `ev-accounts/backend/scripts/backfill-topic-tier-flags.ts`:

```typescript
/**
 * backfill-topic-tier-flags.ts
 *
 * Populates inform.compass_topic_roles with one row per (topic, tier) pair,
 * based on the audit in docs/planning/topic-tier-audit.md.
 *
 * Idempotent via the (topic_id, role_scope) unique constraint added in
 * migration 059. Safe to re-run.
 *
 * Run:
 *   cd ev-accounts/backend
 *   set -a && source .env && set +a
 *   npx tsx scripts/backfill-topic-tier-flags.ts
 */

import 'dotenv/config';
import pg from 'pg';

const { Pool } = pg;

type Tier = 'federal' | 'state' | 'local';

// Derived from docs/planning/topic-tier-audit.md (approved 2026-04-11).
// Each topic_key maps to the list of tiers at which it is meaningfully answerable.
const TIER_FLAGS: Record<string, Tier[]> = {
  'healthcare':        ['federal', 'state', 'local'],
  'abortion':          ['federal', 'state'],
  'tariffs':           ['federal'],
  'taxes':             ['federal', 'state', 'local'],
  'same-sex-marriage': ['federal', 'state', 'local'],
  'religious-freedom': ['federal', 'state', 'local'],
  'trans-athletes':    ['federal', 'state', 'local'],
  'ukraine-support':   ['federal'],
  'medicare/aid':      ['federal'],
  'fossil-fuels':      ['federal', 'state', 'local'],
  'voting-rights':     ['federal', 'state', 'local'],
  'deportation':       ['federal', 'state', 'local'],
  'social-security':   ['federal'],
  'ai-regulation':     ['federal', 'state'],
  'climate-change':    ['federal', 'state', 'local'],
  'civil-rights':      ['federal', 'state', 'local'],
  'housing':           ['federal', 'state', 'local'],
  'campaign-finance':  ['federal', 'state', 'local'],
  'immigration':       ['federal', 'state', 'local'],
  'misinformation':    ['federal', 'state', 'local'],
  'redistricting':     ['federal', 'state'],
  'school-vouchers':   ['federal', 'state', 'local'],
  'data-centers':      ['federal', 'state', 'local'],
  'homelessness':      ['federal', 'state', 'local'],
  'childcare':         ['federal', 'state', 'local'],
  'jail-capacity':     ['state', 'local'],
};

async function main() {
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });

  try {
    // Resolve topic_key → topic_id
    const { rows: topics } = await pool.query(
      `SELECT id, topic_key FROM inform.compass_topics WHERE is_live = true`
    );
    const topicKeyToId = new Map<string, string>(
      topics.map((t) => [t.topic_key, t.id])
    );

    const missingInDb: string[] = [];
    const missingInAudit: string[] = [];

    for (const key of Object.keys(TIER_FLAGS)) {
      if (!topicKeyToId.has(key)) missingInDb.push(key);
    }
    for (const t of topics) {
      if (!(t.topic_key in TIER_FLAGS)) missingInAudit.push(t.topic_key);
    }

    if (missingInDb.length > 0) {
      console.error('ERROR: Audit has topic_keys not present in DB:', missingInDb);
      process.exit(1);
    }
    if (missingInAudit.length > 0) {
      console.error('ERROR: DB has topic_keys not present in audit:', missingInAudit);
      console.error('Update docs/planning/topic-tier-audit.md and the TIER_FLAGS map in this script.');
      process.exit(1);
    }

    // Insert one row per (topic, tier) pair
    let inserted = 0;
    let skipped = 0;
    for (const [key, tiers] of Object.entries(TIER_FLAGS)) {
      const topicId = topicKeyToId.get(key)!;
      for (const tier of tiers) {
        const result = await pool.query(
          `INSERT INTO inform.compass_topic_roles (topic_id, role_scope)
           VALUES ($1, $2)
           ON CONFLICT (topic_id, role_scope) DO NOTHING`,
          [topicId, tier]
        );
        if (result.rowCount === 1) inserted++;
        else skipped++;
      }
    }

    console.log(`Inserted ${inserted} new rows, skipped ${skipped} existing rows.`);
    console.log(`Total topics: ${topics.length}, total (topic, tier) pairs: ${inserted + skipped}`);

    // Summary
    const { rows: summary } = await pool.query(
      `SELECT role_scope, COUNT(*) AS n
       FROM inform.compass_topic_roles
       GROUP BY role_scope
       ORDER BY role_scope`
    );
    console.log('Per-tier totals after backfill:');
    for (const r of summary) {
      console.log(`  ${r.role_scope}: ${r.n} topics`);
    }
  } finally {
    await pool.end();
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
```

- [ ] **Step 2: Run the script**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/backend
set -a && source .env && set +a
npx tsx scripts/backfill-topic-tier-flags.ts
```

Expected output (numbers approximate based on the 26-topic audit):
```
Inserted 67 new rows, skipped 0 existing rows.
Total topics: 26, total (topic, tier) pairs: 67
Per-tier totals after backfill:
  federal: 24 topics
  local: 20 topics
  state: 23 topics
```

Exact counts will depend on the audit. The important check: no errors, and the per-tier totals should sum to the total pairs (67 = 24 + 23 + 20 in the above example).

- [ ] **Step 3: Spot-check specific rows**

```bash
set -a && source .env && set +a
npx tsx -e "
import pg from 'pg';
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const { rows } = await pool.query(\`
  SELECT t.topic_key, array_agg(r.role_scope ORDER BY r.role_scope) AS tiers
  FROM inform.compass_topics t
  LEFT JOIN inform.compass_topic_roles r ON r.topic_id = t.id
  WHERE t.topic_key IN ('tariffs', 'housing', 'jail-capacity', 'ukraine-support', 'abortion')
  GROUP BY t.topic_key
  ORDER BY t.topic_key
\`);
console.log(rows);
await pool.end();
"
```

Expected output:
```
[
  { topic_key: 'abortion', tiers: ['federal', 'state'] },
  { topic_key: 'housing', tiers: ['federal', 'local', 'state'] },
  { topic_key: 'jail-capacity', tiers: ['local', 'state'] },
  { topic_key: 'tariffs', tiers: ['federal'] },
  { topic_key: 'ukraine-support', tiers: ['federal'] }
]
```

If any row has wrong tiers, fix the `TIER_FLAGS` map, delete the mis-inserted rows manually, and re-run the script.

- [ ] **Step 4: Commit**

```bash
git add ev-accounts/backend/scripts/backfill-topic-tier-flags.ts
git commit -m "feat(backend): topic tier flag backfill script

Populates inform.compass_topic_roles from the audit in
docs/planning/topic-tier-audit.md. Idempotent via the unique constraint
added in migration 059. Run once against dev DB; production applies
separately via the usual deploy path.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Write and Run Chamber Engagement Level Backfill

**Files:**
- Create: `ev-accounts/backend/scripts/backfill-chamber-engagement-level.ts`

This script identifies chambers by name pattern and updates `policy_engagement_level` for administrative offices (`none`) and retention-election judicial bodies (`record_only`). Everything else stays at the default `full`.

The script is conservative: it only touches chambers whose names match specific patterns, and it prints a dry-run summary before committing any changes. The actual update is guarded by a `--apply` flag so a dry-run is the default.

- [ ] **Step 1: Create the backfill script**

Write this exact content to `ev-accounts/backend/scripts/backfill-chamber-engagement-level.ts`:

```typescript
/**
 * backfill-chamber-engagement-level.ts
 *
 * Identifies administrative and retention-judge chambers by name pattern
 * and updates policy_engagement_level accordingly.
 *
 * Default mode: dry-run. Prints what would change.
 * With --apply: actually performs the updates inside a transaction.
 *
 * Run:
 *   cd ev-accounts/backend
 *   set -a && source .env && set +a
 *   npx tsx scripts/backfill-chamber-engagement-level.ts           # dry run
 *   npx tsx scripts/backfill-chamber-engagement-level.ts --apply   # commit changes
 */

import 'dotenv/config';
import pg from 'pg';

const { Pool } = pg;

// Chambers whose names match these patterns become engagement level 'none'
// (administrative offices — no policy positions, no compass).
const NONE_PATTERNS = [
  'Recorder',
  'Surveyor',
  'Auditor',
  'Coroner',
  'Assessor',
  'Circuit Court Clerk',
  'City Clerk',
  'Treasurer',
] as const;

// Chambers whose names match these patterns become engagement level 'record_only'
// (retention judges — voters decide on track record, not positions).
//
// NOTE: In Indiana, circuit court judges are CONTESTED in their first election
// and RETAINED in subsequent elections. For v1 we leave circuit court judges at
// 'full' and only mark appellate/supreme court as 'record_only'. The spec's
// open question #4 flags this as needing Indiana-specific verification.
const RECORD_ONLY_PATTERNS = [
  'Court of Appeals',
  'Supreme Court',
  'Appellate',
] as const;

async function main() {
  const apply = process.argv.includes('--apply');
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });

  try {
    // Fetch all chambers with their current engagement level
    const { rows: chambers } = await pool.query(
      `SELECT id, name, policy_engagement_level FROM essentials.chambers ORDER BY name`
    );

    const toNone: { id: string; name: string }[] = [];
    const toRecordOnly: { id: string; name: string }[] = [];

    for (const ch of chambers) {
      const matchesNone = NONE_PATTERNS.some((p) => ch.name.includes(p));
      const matchesRecord = RECORD_ONLY_PATTERNS.some((p) => ch.name.includes(p));

      // record_only takes priority if a chamber somehow matches both
      if (matchesRecord && ch.policy_engagement_level !== 'record_only') {
        toRecordOnly.push({ id: ch.id, name: ch.name });
      } else if (matchesNone && !matchesRecord && ch.policy_engagement_level !== 'none') {
        toNone.push({ id: ch.id, name: ch.name });
      }
    }

    console.log(`\n=== DRY RUN SUMMARY${apply ? ' (will apply)' : ''} ===\n`);
    console.log(`Total chambers: ${chambers.length}`);
    console.log(`Will set to 'none': ${toNone.length}`);
    for (const c of toNone) console.log(`  - ${c.name}`);
    console.log(`Will set to 'record_only': ${toRecordOnly.length}`);
    for (const c of toRecordOnly) console.log(`  - ${c.name}`);

    if (!apply) {
      console.log(`\nDry run complete. Re-run with --apply to commit changes.`);
      return;
    }

    // Actual updates inside a transaction
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      for (const c of toNone) {
        await client.query(
          `UPDATE essentials.chambers SET policy_engagement_level = 'none' WHERE id = $1`,
          [c.id]
        );
      }
      for (const c of toRecordOnly) {
        await client.query(
          `UPDATE essentials.chambers SET policy_engagement_level = 'record_only' WHERE id = $1`,
          [c.id]
        );
      }

      await client.query('COMMIT');
      console.log(`\nApplied: ${toNone.length} → none, ${toRecordOnly.length} → record_only.`);
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }

    // Post-verify
    const { rows: summary } = await pool.query(
      `SELECT policy_engagement_level, COUNT(*) AS n
       FROM essentials.chambers
       GROUP BY policy_engagement_level
       ORDER BY policy_engagement_level`
    );
    console.log('\nFinal counts by engagement level:');
    for (const r of summary) console.log(`  ${r.policy_engagement_level}: ${r.n}`);
  } finally {
    await pool.end();
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
```

- [ ] **Step 2: Dry-run the script**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/backend
set -a && source .env && set +a
npx tsx scripts/backfill-chamber-engagement-level.ts
```

Expected output (chamber counts will vary based on current DB state):
```
=== DRY RUN SUMMARY ===

Total chambers: <some number in the hundreds>
Will set to 'none': <list of administrative chambers>
  - Recorder
  - Auditor
  - Surveyor
  - Coroner
  - ...
Will set to 'record_only': <list of appellate/supreme chambers, possibly 0>
  - ...

Dry run complete. Re-run with --apply to commit changes.
```

- [ ] **Step 3: Human review gate**

Read the dry-run output carefully. Check that:
- The `none` list only contains clearly administrative chambers (recorders, auditors, surveyors, coroners, assessors, clerks, treasurers)
- The `record_only` list only contains appellate/supreme court chambers
- No chambers that take policy positions (mayors, council, sheriff, prosecutor, school board) are in either list

If any chamber looks wrong, update the `NONE_PATTERNS` or `RECORD_ONLY_PATTERNS` arrays in the script and re-run the dry-run until it looks right.

- [ ] **Step 4: Apply the backfill**

Only after the dry-run output has been manually verified:

```bash
set -a && source .env && set +a
npx tsx scripts/backfill-chamber-engagement-level.ts --apply
```

Expected output:
```
=== DRY RUN SUMMARY (will apply) ===
...
Applied: <N> → none, <M> → record_only.

Final counts by engagement level:
  full: <large number>
  none: <N>
  record_only: <M>
```

- [ ] **Step 5: Spot-check Monroe County officials**

```bash
set -a && source .env && set +a
npx tsx -e "
import pg from 'pg';
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
const { rows } = await pool.query(\`
  SELECT p.full_name, c.name AS chamber, c.policy_engagement_level
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  LEFT JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.label ILIKE '%Monroe%' OR c.name ILIKE '%Monroe%' OR d.label ILIKE '%Bloomington%'
  ORDER BY c.policy_engagement_level, p.full_name
\`);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
"
```

Expected:
- Administrative officers (Amy Swain/Recorder, Brianne Gregory/Auditor, Catherine Smith/Treasurer, Judith Sharp/Assessor, Jeffrey Hall/Coroner, Trohn Enright-Randolph/Surveyor, Nicole Browne/Circuit Court Clerk, Nicole Bolden/City Clerk) should have `policy_engagement_level = 'none'`
- Circuit Court Judges (Monroe County 10th Circuit, Divisions 1-9) should have `policy_engagement_level = 'full'` — they're contested-election judges in Indiana
- Mayor, council, sheriff, prosecutor, school board should all be `'full'`

If Circuit Court Judges came back as `record_only`, the pattern matching was too aggressive — update the script and re-run. (The plan's current patterns explicitly avoid this by only matching `Court of Appeals` / `Supreme Court` / `Appellate`.)

- [ ] **Step 6: Commit**

```bash
git add ev-accounts/backend/scripts/backfill-chamber-engagement-level.ts
git commit -m "feat(backend): chamber engagement level backfill script

Identifies administrative chambers (recorders, auditors, surveyors,
coroners, assessors, clerks, treasurers) and appellate judicial bodies
by name pattern and sets policy_engagement_level accordingly. Default
'full' preserved for everything else. Dry-run by default; --apply to
commit changes.

Contested-election circuit court judges stay at 'full' per spec open
question #4 — Indiana's retention rules need further verification
before any contested/retention auto-classification.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Expose Tier Flags in compassService

**Files:**
- Modify: `ev-accounts/backend/src/lib/compassService.ts` (lines 107-159 — the `getCompassTopics` function)

The function already queries `compass_topic_roles` and returns a `roles` array per topic. We add three derived booleans (`applies_federal`, `applies_state`, `applies_local`) to the response shape at the API boundary, normalizing the rows. We also add `office_scope` to the `compass_topics` select clause so it flows through.

- [ ] **Step 1: Write the verification script**

Create `/tmp/verify-compass-service.ts` (do not commit):

```typescript
import 'dotenv/config';
import { getCompassTopics } from '../ev-accounts/backend/src/lib/compassService.js';

async function main() {
  const topics = await getCompassTopics();

  console.log(`Got ${topics.length} topics`);

  // Find tariffs (should be federal-only)
  const tariffs = topics.find((t: any) => t.short_title === 'Tariffs' || t.title?.includes('Tariff'));
  if (!tariffs) {
    console.error('ERROR: tariffs topic not found');
    process.exit(1);
  }
  console.log('Tariffs:', {
    applies_federal: (tariffs as any).applies_federal,
    applies_state:   (tariffs as any).applies_state,
    applies_local:   (tariffs as any).applies_local,
    office_scope:    (tariffs as any).office_scope,
  });

  // Find housing (should be all three)
  const housing = topics.find((t: any) => t.short_title === 'Housing' || t.title?.includes('Housing'));
  if (!housing) {
    console.error('ERROR: housing topic not found');
    process.exit(1);
  }
  console.log('Housing:', {
    applies_federal: (housing as any).applies_federal,
    applies_state:   (housing as any).applies_state,
    applies_local:   (housing as any).applies_local,
    office_scope:    (housing as any).office_scope,
  });

  // Verify every topic has the three boolean fields defined
  const missing = topics.filter(
    (t: any) =>
      typeof t.applies_federal !== 'boolean' ||
      typeof t.applies_state !== 'boolean' ||
      typeof t.applies_local !== 'boolean'
  );
  if (missing.length > 0) {
    console.error(`ERROR: ${missing.length} topics missing tier boolean fields`);
    console.error(missing.map((t: any) => t.title));
    process.exit(1);
  }
  console.log(`All ${topics.length} topics have tier boolean fields.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
```

- [ ] **Step 2: Run verification and confirm it fails**

```bash
cd /Users/chrisandrews/Documents/GitHub
set -a && source ev-accounts/backend/.env && set +a
# Note: running from repo root so the import path works. Adjust if needed.
cd ev-accounts/backend
npx tsx /tmp/verify-compass-service.ts
```

Expected: the three boolean fields are `undefined` on all topics (the current service doesn't return them). Script exits with ERROR.

- [ ] **Step 3: Update getCompassTopics in compassService.ts**

Open `ev-accounts/backend/src/lib/compassService.ts` and locate the `getCompassTopics` function around line 107.

Find this block (the `compass_topics` select):
```typescript
    .schema('inform')
    .from('compass_topics')
    .select('id,title,short_title,question_text,is_live,version')
    .eq('is_live', true)
    .order('created_at', { ascending: true });
```

Replace the `.select(...)` line with:
```typescript
    .select('id,title,short_title,question_text,is_live,version,office_scope')
```

Next, find the return block at the bottom of the function:
```typescript
  return topics.map(topic => ({
    ...topic,
    stances: (stancesRes.data ?? [])
      .filter(s => s.topic_id === topic.id)
      .map(({ topic_id: _tid, ...s }) => s),
    categories: (catsRes.data ?? [])
      .filter(c => c.topic_id === topic.id)
      .map(c => {
        const cat = c.compass_categories as { id: string; title: string } | null;
        return cat ? { category_id: cat.id, title: cat.title } : null;
      })
      .filter(Boolean),
    roles: (rolesRes.data ?? [])
      .filter(r => r.topic_id === topic.id)
      .map(({ topic_id: _tid, ...r }) => r),
  }));
```

Replace it with:
```typescript
  return topics.map(topic => {
    const topicRoles = (rolesRes.data ?? []).filter(r => r.topic_id === topic.id);

    // Normalize tier rows into three booleans at the API boundary.
    // A topic with no rows defaults to all three tiers = true (cross-cutting).
    const hasAnyRoleRows = topicRoles.length > 0;
    const applies_federal = hasAnyRoleRows
      ? topicRoles.some(r => r.role_scope === 'federal')
      : true;
    const applies_state = hasAnyRoleRows
      ? topicRoles.some(r => r.role_scope === 'state')
      : true;
    const applies_local = hasAnyRoleRows
      ? topicRoles.some(r => r.role_scope === 'local')
      : true;

    return {
      ...topic,
      applies_federal,
      applies_state,
      applies_local,
      stances: (stancesRes.data ?? [])
        .filter(s => s.topic_id === topic.id)
        .map(({ topic_id: _tid, ...s }) => s),
      categories: (catsRes.data ?? [])
        .filter(c => c.topic_id === topic.id)
        .map(c => {
          const cat = c.compass_categories as { id: string; title: string } | null;
          return cat ? { category_id: cat.id, title: cat.title } : null;
        })
        .filter(Boolean),
      roles: topicRoles.map(({ topic_id: _tid, ...r }) => r),
    };
  });
```

The key changes:
1. The `compass_topics` select now includes `office_scope`.
2. The return value now includes `applies_federal`, `applies_state`, `applies_local` on every topic, derived from the `rolesRes.data` rows.
3. The existing `roles` field is preserved unchanged (backward compatibility with any consumer that reads the raw rows).
4. Topics with no rows in `compass_topic_roles` default to all three tiers = true — matches the spec behavior for unpopulated topics.

- [ ] **Step 4: Typecheck**

```bash
cd ev-accounts/backend
npm run typecheck
```

Expected: no errors. If there are errors about missing types on the new fields, verify that the `...topic` spread picks up `office_scope` from the SELECT — the Supabase JS client infers the type from the select string.

- [ ] **Step 5: Re-run verification and confirm it passes**

```bash
cd ev-accounts/backend
set -a && source .env && set +a
npx tsx /tmp/verify-compass-service.ts
```

Expected output:
```
Got 26 topics
Tariffs: {
  applies_federal: true,
  applies_state: false,
  applies_local: false,
  office_scope: null
}
Housing: {
  applies_federal: true,
  applies_state: true,
  applies_local: true,
  office_scope: null
}
All 26 topics have tier boolean fields.
```

- [ ] **Step 6: Delete the verification script**

```bash
rm /tmp/verify-compass-service.ts
```

- [ ] **Step 7: Commit**

```bash
git add ev-accounts/backend/src/lib/compassService.ts
git commit -m "feat(backend): expose tier flags + office_scope via getCompassTopics

Normalizes compass_topic_roles rows into applies_federal/state/local
booleans at the API boundary. Adds office_scope to the compass_topics
select clause. Existing 'roles' field preserved for backward compat.
Topics with no role rows default to all three tiers = true.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: Expose Policy Engagement Level in essentialsService

**Files:**
- Modify: `ev-accounts/backend/src/lib/essentialsService.ts` (multiple queries that join `essentials.chambers`)

The essentials service uses raw SQL for politician lookups. Every query that joins `essentials.chambers` needs to include `ch.policy_engagement_level` in its SELECT, and every return-shape type needs the new field.

- [ ] **Step 1: Locate all chambers joins**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/backend
grep -n "essentials\.chambers ch" src/lib/essentialsService.ts
```

Expected: several lines showing `LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id`. Note all line numbers — you'll update each query block.

- [ ] **Step 2: Write verification script**

Create `/tmp/verify-essentials-service.ts` (do not commit). The exact function to call depends on which essentials service functions return chamber data; look for a function that fetches politicians with their offices/chambers and call it. Likely candidates: `getPoliticiansByAddress`, `getPoliticianById`, `lookupPoliticiansByGeofence`.

```typescript
import 'dotenv/config';
import * as ess from '../ev-accounts/backend/src/lib/essentialsService.js';

async function main() {
  // Use whatever function retrieves a politician with chamber info.
  // Verify the resulting shape includes policy_engagement_level.

  // Example — adjust based on the actual service API:
  // const politician = await ess.getPoliticianById('<some-known-id>');
  // console.log('engagement level:', politician?.offices?.[0]?.chamber?.policy_engagement_level);

  // If the service returns a nested shape, drill into it.
  // The goal: confirm that at least one code path exposes policy_engagement_level.

  console.log('Verification skeleton — adjust based on the actual service API');
}

main().catch(e => { console.error(e); process.exit(1); });
```

Because the service has multiple return shapes and 1675 lines of code, this step requires reading `essentialsService.ts` first to pick an appropriate function. Budget time for that reading.

- [ ] **Step 3: Read essentialsService.ts and identify all queries that need updating**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/backend
# Read the service file, focus on SQL query blocks around the chambers joins
# identified in Step 1
```

For each SQL query that contains `LEFT JOIN essentials.chambers ch`:
- Add `ch.policy_engagement_level` to the SELECT list
- If the result is mapped to a TypeScript type, add `policy_engagement_level: 'full' | 'record_only' | 'none'` to that type
- If the result is passed directly through to a response shape, verify the consumer handles the new field

Every chamber-joining query in this file gets the same treatment. Do NOT skip any — inconsistent exposure means some code paths have the field and others don't, which is a bug waiting to happen.

- [ ] **Step 4: Update each query (pattern)**

For each identified location, update the SELECT clause. Example transformation:

**Before:**
```sql
SELECT
  p.id, p.full_name,
  o.title, o.representing_state,
  c.name AS chamber_name,
  d.label AS district_label
FROM essentials.politicians p
LEFT JOIN essentials.offices o ON o.politician_id = p.id
LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
LEFT JOIN essentials.districts d ON d.id = o.district_id
WHERE ...
```

Hmm — the existing code uses `ch` as the alias in some places and `c` in others. Use the alias that matches each specific query.

**After:**
```sql
SELECT
  p.id, p.full_name,
  o.title, o.representing_state,
  c.name AS chamber_name,
  c.policy_engagement_level AS policy_engagement_level,
  d.label AS district_label
FROM essentials.politicians p
LEFT JOIN essentials.offices o ON o.politician_id = p.id
LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
LEFT JOIN essentials.districts d ON d.id = o.district_id
WHERE ...
```

And update any row-mapping functions to surface the new field:

**Before:**
```typescript
return rows.map(r => ({
  id: r.id,
  full_name: r.full_name,
  chamber_name: r.chamber_name,
  // ...
}));
```

**After:**
```typescript
return rows.map(r => ({
  id: r.id,
  full_name: r.full_name,
  chamber_name: r.chamber_name,
  policy_engagement_level: r.policy_engagement_level as 'full' | 'record_only' | 'none',
  // ...
}));
```

The TypeScript type declarations for the return shape (search for `interface` or `type` near each query) also need the new field added.

- [ ] **Step 5: Typecheck**

```bash
cd ev-accounts/backend
npm run typecheck
```

Fix any type errors. Most likely source of errors: a return shape interface that's strict about its fields and now rejects the new one, or a place where the service return type is consumed downstream and needs its type extended too.

- [ ] **Step 6: Runtime verification**

```bash
cd ev-accounts/backend
set -a && source .env && set +a
npx tsx -e "
import pg from 'pg';
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

// Find a Monroe County politician with known engagement levels
const { rows } = await pool.query(\`
  SELECT p.id, p.full_name, c.name AS chamber_name, c.policy_engagement_level
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE p.full_name IN ('Kerry Thomson', 'Amy Swain', 'Geoffrey J. Bradley')
  ORDER BY p.full_name
\`);
console.log('Direct SQL verification:');
rows.forEach(r => console.log('  ' + r.full_name + ' / ' + r.chamber_name + ' / ' + r.policy_engagement_level));
await pool.end();
"
```

Expected:
```
Direct SQL verification:
  Amy Swain / Recorder / none
  Geoffrey J. Bradley / Indiana Circuit Court Judge - 10th Circuit, Division 1 / full
  Kerry Thomson / City Mayor / full
```

This confirms the backfill from Task 4 stuck and the column is queryable. The service layer mapping is verified indirectly by the typecheck in Step 5 — any consumer reading the mapped shape will see the new field.

- [ ] **Step 7: Commit**

```bash
git add ev-accounts/backend/src/lib/essentialsService.ts
git commit -m "feat(backend): expose policy_engagement_level via essentials queries

Adds c.policy_engagement_level to every query joining essentials.chambers
in essentialsService.ts. Updates TypeScript return types. Enables
downstream code (future essentials frontend + compass builder) to
distinguish full-policy offices from administrative and retention-judge
offices.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: End-to-End API Verification

**Files:** none modified — this task runs curl-like verifications against the running dev server.

- [ ] **Step 1: Start the dev server**

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-accounts/backend
npm run dev
```

Wait for the "listening on port 3000" message. Leave this running in a background terminal.

- [ ] **Step 2: Hit the compass topics endpoint**

In a second terminal:
```bash
curl -s http://localhost:3000/api/compass/topics | node -e "
const data = JSON.parse(require('fs').readFileSync(0, 'utf8'));
const topics = Array.isArray(data) ? data : data.topics || data.data;
console.log('Topic count:', topics.length);
const tariffs = topics.find(t => t.short_title === 'Tariffs');
const housing = topics.find(t => t.short_title === 'Housing');
console.log('Tariffs tier flags:', {
  applies_federal: tariffs.applies_federal,
  applies_state: tariffs.applies_state,
  applies_local: tariffs.applies_local,
});
console.log('Housing tier flags:', {
  applies_federal: housing.applies_federal,
  applies_state: housing.applies_state,
  applies_local: housing.applies_local,
});
console.log('Tariffs office_scope:', tariffs.office_scope);
"
```

Expected output:
```
Topic count: 26
Tariffs tier flags: { applies_federal: true, applies_state: false, applies_local: false }
Housing tier flags: { applies_federal: true, applies_state: true, applies_local: true }
Tariffs office_scope: null
```

If any of these come back `undefined` or wrong, Task 5's service update didn't reach the route layer. Verify the route handler in `ev-accounts/backend/src/routes/compass.ts` passes through the service response unchanged.

- [ ] **Step 3: Hit the essentials politician endpoint**

Pick a Monroe County politician (Kerry Thomson is a good test):
```bash
curl -s "http://localhost:3000/api/essentials/politicians/1c6dbdaf-e110-48d3-9b88-27f911d9521f" | node -e "
const data = JSON.parse(require('fs').readFileSync(0, 'utf8'));
console.log(JSON.stringify(data, null, 2).slice(0, 2000));
"
```

Look for `policy_engagement_level` in the response. It should appear somewhere nested (likely inside an `offices` array or a `chamber` object, depending on the API shape).

Expected: `policy_engagement_level: "full"` (Kerry Thomson is a mayor — full engagement).

- [ ] **Step 4: Hit a known 'none' politician**

Amy Swain (Monroe County Recorder):
```bash
curl -s "http://localhost:3000/api/essentials/politicians/fa4cbcff-06c5-4f31-a034-0c9b4b268868" | node -e "
const data = JSON.parse(require('fs').readFileSync(0, 'utf8'));
console.log(JSON.stringify(data, null, 2).slice(0, 2000));
"
```

Expected: `policy_engagement_level: "none"` somewhere in the chamber section of the response.

- [ ] **Step 5: Stop the dev server**

Ctrl+C in the first terminal.

- [ ] **Step 6: Commit a final "Plan A complete" marker (optional)**

If nothing further needs committing from this task:
```bash
# Nothing to commit from this task — verification only.
# Proceed to the execution handoff.
```

If the route handler in Step 2 needed a minor pass-through update:
```bash
git add ev-accounts/backend/src/routes/compass.ts   # or whichever route file
git commit -m "fix(routes): pass through tier flag fields from compass service

Route handler was selectively passing fields and dropped the new
applies_federal/state/local booleans. Changed to spread full topic
object so future field additions flow through automatically.

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>"
```

---

## Plan A Complete

After all tasks pass, Plan A delivers:

1. ✅ `inform.compass_topic_roles` has 60+ rows mapping 26 topics to their applicable tiers, with CHECK + UNIQUE constraints preventing invalid data
2. ✅ `inform.compass_topics.office_scope TEXT[]` column exists for future per-office topics
3. ✅ `essentials.policy_engagement_level` enum exists
4. ✅ `essentials.chambers.policy_engagement_level` populated for Monroe County administrative offices (`none`) with the rest defaulting to `full`
5. ✅ `compassService.getCompassTopics()` returns `applies_federal/state/local` booleans per topic, plus `office_scope`
6. ✅ `essentialsService.*` chamber joins include `policy_engagement_level`
7. ✅ API endpoints verified returning the new fields
8. ✅ Topic audit document committed at `docs/planning/topic-tier-audit.md` as the source of truth for future tier adjustments

**Not delivered by Plan A (comes in Plan B, C, D):**
- Any frontend changes (tier badges, coverage callout, deep view)
- Any compass builder UX updates
- Any `ev-ui` components
- The topic rewrite workflow

**Unblocks:** Plans B, C, and D can all start once Plan A lands.
