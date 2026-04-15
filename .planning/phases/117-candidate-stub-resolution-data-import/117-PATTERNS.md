# Phase 117: Candidate Stub Resolution + Data Import — Pattern Map

**Mapped:** 2026-04-14
**Files analyzed:** 9 (6 new, 2 modified, 1 non-code artifact)
**Analogs found:** 8 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `ev-accounts/backend/migrations/068_add_is_candidate_and_backfill.sql` | migration | batch (schema + UPDATE) | `migrations/064_backfill_city_council_geo_id.sql` | role + flow match |
| `ev-accounts/backend/scripts/import-monroe-stub-candidates.ts` | script (import) | batch (INSERT loop) | `scripts/seedPolitician.ts::createFederalPolitician` (L190-243) | exact |
| `ev-accounts/backend/scripts/verify-117-imports.sql` | script (SQL verification) | batch (SELECT only) | `scripts/link-monroe-candidates-to-politicians.sql` Step 1 | role match |
| `ev-accounts/backend/scripts/verify-117-leak-closed.sh` | script (shell smoke test) | request-response | none in ev-accounts/backend; closest is ad-hoc curl patterns in research | **no analog** |
| `ev-accounts/backend/scripts/verify-117-profile-loads.sh` | script (shell smoke test) | request-response | same as above | **no analog** |
| `ev-accounts/backend/src/lib/essentialsService.ts` (L593, L635) | service (modify) | request-response (SQL filter) | self — one-line WHERE clause addition | exact |
| `ev-accounts/backend/src/lib/compassService.ts` (L279) | service (modify) | request-response (JOIN change) | self — INNER → LEFT JOIN | exact |
| `.planning/phases/117-.../117-FEASIBILITY.md` | artifact (markdown doc) | n/a | none — new artifact type | **no analog** |
| Photo upload (reuse OR port) | script (upload) | file-I/O + HTTP | `EV-Backend/scripts/upload_monroe_council_photos.py` L38-92 | exact (Python) |

## Pattern Assignments

### `migrations/068_add_is_candidate_and_backfill.sql` (migration, batch schema+backfill)

**Analog:** `ev-accounts/backend/migrations/064_backfill_city_council_geo_id.sql`

**Pattern: wrap whole migration in BEGIN/COMMIT, use `DO $$ ... $$` for logged verification.** Unlike 064 which uses a `FOR rec IN ... LOOP` per-row update, Phase 117 uses a single set-based `UPDATE ... WHERE EXISTS`, which is simpler.

**Header comment pattern** (064 L1-12):
```sql
-- Migration 064: backfill city_council_geo_id for all Connected users with stored location
--
-- The ordering bug fixed in 063 caused city_council_geo_id to be stored incorrectly
-- [... problem context ...]
--
-- Failures are logged as warnings (not errors) so one bad row doesn't abort the rest.
```

**Verification/logging block pattern** (064 L14-46) — copy the `DO $$ ... RAISE NOTICE` shape:
```sql
DO $$
DECLARE
  v_count int := 0;
BEGIN
  [... logic ...]
  RAISE NOTICE 'backfill 064 complete: % updated, % errors', v_count, v_errors;
END;
$$;
```

**Concrete Phase 117 migration body** (from RESEARCH.md L336-362, verified against 064 pattern):
```sql
-- migrations/068_add_is_candidate_and_backfill.sql
BEGIN;

ALTER TABLE essentials.politicians
  ADD COLUMN IF NOT EXISTS is_candidate BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN essentials.politicians.is_candidate IS
  'Phase 117: true = active candidate; false = sitting official. Address resolver filters is_candidate=true out of tier-grouped results (essentialsService.ts). Compass picker and race listings are NOT filtered.';

-- D-10 backfill: any politician linked to a race as non-incumbent is a candidate
UPDATE essentials.politicians p
SET is_candidate = true
WHERE EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.politician_id = p.id AND rc.is_incumbent = false
);

DO $$
DECLARE v_count int;
BEGIN
  SELECT COUNT(*) INTO v_count FROM essentials.politicians WHERE is_candidate = true;
  RAISE NOTICE 'migration 068: is_candidate=true after backfill: %', v_count;
END $$;

COMMIT;
```

**Also add** (derived from Pitfall #1 — pre-flight integrity check):
```sql
-- Post-backfill sanity: warn if any row ended up with both flags true
DO $$
DECLARE v_conflict int;
BEGIN
  SELECT COUNT(*) INTO v_conflict
  FROM essentials.politicians
  WHERE is_candidate = true AND is_incumbent = true;
  IF v_conflict > 0 THEN
    RAISE WARNING 'migration 068: % rows have both is_candidate=true AND is_incumbent=true', v_conflict;
  END IF;
END $$;
```

---

### `scripts/import-monroe-stub-candidates.ts` (script, batch insert)

**Analog:** `ev-accounts/backend/scripts/seedPolitician.ts` — specifically `createFederalPolitician` (L190-243)

**Imports + dotenv pattern** (seedPolitician.ts L25-35) — copy this block verbatim, adjust imports:
```typescript
import 'dotenv/config';
import readline from 'readline';
import fs from 'fs';
import { parse } from 'csv-parse/sync';
import { pool } from '../src/lib/db.js';
```

Note: `audit-112-candidates.ts` uses an alternate dotenv pattern with explicit path resolution (L18-27) — use this if the script is run from a directory other than `backend/`:
```typescript
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });

const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
```

**Core INSERT pattern** (seedPolitician.ts L219-235) — adapt to phase 117:
```typescript
// Insert politician
const polResult = await pool.query<{ id: string }>(
  `INSERT INTO essentials.politicians
     (full_name, first_name, last_name, is_active, is_incumbent, source)
   VALUES ($1, $2, $3, true, false, 'federal_2026_bulk_seed')
   RETURNING id`,
  [fullName, toTitleCase(firstName), toTitleCase(lastName)]
);
const politicianId = polResult.rows[0]!.id;

// Insert office
await pool.query(
  `INSERT INTO essentials.offices
     (politician_id, chamber_id, title, representing_state, is_vacant)
   VALUES ($1, $2, $3, $4, false)`,
  [politicianId, chamberIdForOffice, officeTitle, state]
);
```

**Phase 117 adaptation** (adds `is_candidate`, `bio_text`, `photo_custom_url`, and the race_candidates UPDATE step):
```typescript
await pool.query('BEGIN');
try {
  const { rows: [{ id: politicianId }] } = await pool.query<{ id: string }>(
    `INSERT INTO essentials.politicians
       (full_name, first_name, last_name, bio_text, bio_source_url,
        photo_custom_url, is_active, is_incumbent, is_candidate, source)
     VALUES ($1,$2,$3,$4,$5,$6, true, false, true, 'phase_117_monroe_stub_import')
     RETURNING id`,
    [fullName, firstName, lastName, bioText, bioSourceUrl, photoCdnUrl]
  );

  await pool.query(
    `INSERT INTO essentials.offices
       (politician_id, chamber_id, district_id, title, representing_state, representing_city, is_vacant)
     VALUES ($1,$2,$3,$4,'IN',$5, false)`,
    [politicianId, chamberId, districtId, officeTitle, city]
  );

  // CRITICAL (Pitfall #5): update stub, otherwise audit still shows stub
  const upd = await pool.query(
    `UPDATE essentials.race_candidates
     SET politician_id = $1, updated_at = now()
     WHERE id = $2 AND politician_id IS NULL
     RETURNING id`,
    [politicianId, stubRaceCandidateId]
  );
  if (upd.rowCount !== 1) {
    throw new Error(`race_candidates ${stubRaceCandidateId} already linked or not found`);
  }

  await pool.query('COMMIT');
} catch (err) {
  await pool.query('ROLLBACK');
  throw err;
}
```

**Dry-run flag pattern** (seedPolitician.ts L209-217) — copy the "print-and-return-fake-record" shape:
```typescript
if (dryRun) {
  console.log(`[dry-run] Would CREATE politician: ${fullName} (${state}, ${officeTitle})`);
  return {
    id: '00000000-0000-0000-0000-000000000000',
    full_name: fullName,
    representing_state: state,
  };
}
```

**Idempotency pattern** (RESEARCH.md L208, link-monroe script comment L8): "skip if `race_candidates.politician_id IS NOT NULL`". The `WHERE id = $2 AND politician_id IS NULL` clause in the UPDATE already enforces this — a re-run inserts a duplicate politician but fails the UPDATE (rowCount=0) and rolls back. Plan should add a pre-check at the top of each iteration:
```typescript
const { rows: [stub] } = await pool.query(
  `SELECT id, politician_id FROM essentials.race_candidates WHERE id = $1`,
  [stubRaceCandidateId]
);
if (stub?.politician_id) {
  console.log(`[skip] race_candidate ${stubRaceCandidateId} already linked to ${stub.politician_id}`);
  continue;
}
```

**Pre-flight office scaffolding check** (Pitfall #6):
```typescript
// Fail loud if chamber/district missing for this candidate's race
const { rows: [scaffold] } = await pool.query(
  `SELECT r.id AS race_id, r.chamber_id, r.district_id
   FROM essentials.races r
   JOIN essentials.race_candidates rc ON rc.race_id = r.id
   WHERE rc.id = $1`,
  [stubRaceCandidateId]
);
if (!scaffold?.chamber_id || !scaffold?.district_id) {
  throw new Error(`race_candidate ${stubRaceCandidateId}: missing chamber/district scaffolding`);
}
```

---

### `scripts/verify-117-imports.sql` (SQL verification)

**Analog:** `scripts/link-monroe-candidates-to-politicians.sql` — specifically the Step 1 "SELECT only — no changes" preview pattern (L27-46).

**Header pattern**:
```sql
-- =============================================================================
-- Verify Phase 117 Monroe County candidate stub imports
--
-- Checks: row counts, source tag presence, photo+bio+office completeness,
--         is_candidate flag set, race_candidates stubs resolved.
--
-- SELECT-only — safe to re-run. No writes.
--
-- Usage: psql $DATABASE_URL -f scripts/verify-117-imports.sql
-- =============================================================================
```

**Preview-style SELECT pattern** (link-monroe L30-46) — copy the shape, change the joins:
```sql
-- Check 1: all imported rows have required fields
SELECT
  p.full_name,
  p.slug,
  (p.bio_text IS NOT NULL AND length(p.bio_text) > 0) AS has_bio,
  (p.photo_custom_url IS NOT NULL) AS has_photo,
  EXISTS(SELECT 1 FROM essentials.offices o WHERE o.politician_id = p.id) AS has_office,
  p.is_candidate,
  p.is_incumbent
FROM essentials.politicians p
WHERE p.source = 'phase_117_monroe_stub_import'
ORDER BY p.last_name;

-- Check 2: no imported row is missing office scaffolding (should be empty)
SELECT p.id, p.full_name
FROM essentials.politicians p
LEFT JOIN essentials.offices o ON o.politician_id = p.id
WHERE p.source = 'phase_117_monroe_stub_import'
  AND o.id IS NULL;

-- Check 3: stubs are resolved (should return 0 for Monroe contested races)
SELECT COUNT(*) AS unresolved_stubs
FROM essentials.race_candidates rc
JOIN essentials.races r ON r.id = rc.race_id
JOIN essentials.elections e ON e.id = r.election_id
WHERE e.name = '2026 Indiana Primary'
  AND e.state = 'IN'
  AND rc.politician_id IS NULL;

-- Check 4: backfill correctness — no non-incumbent linked candidate missed
SELECT COUNT(*) AS backfill_gap
FROM essentials.politicians p
WHERE p.is_candidate = false
  AND EXISTS (
    SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.politician_id = p.id AND rc.is_incumbent = false
  );

-- Check 5: conflict detector — both flags should not be true
SELECT COUNT(*) AS flag_conflict
FROM essentials.politicians
WHERE is_candidate = true AND is_incumbent = true;
```

---

### `scripts/verify-117-leak-closed.sh` (shell smoke test)

**Analog:** none in ev-accounts/backend. Research section "Phase Requirements → Test Map" row `is_candidate leak closed` provides the exact curl command to base this on.

**Concrete content** (from RESEARCH.md L441):
```bash
#!/usr/bin/env bash
# Phase 117: verify address-lookup leak is closed.
# Queries the production address resolver for a known Monroe County address
# and asserts NO returned politician has is_candidate=true.
set -euo pipefail

API="${API_URL:-https://api.empowered.vote}"
ADDRESS="${1:-401 N Morton St, Bloomington, IN 47404}"

echo "Checking leak closure at $API for: $ADDRESS"

response=$(curl -fsS --get "$API/api/essentials/representatives" --data-urlencode "address=$ADDRESS")

leaked=$(echo "$response" | jq -r '.politicians[]? | select(.is_candidate == true) | .full_name')

if [[ -n "$leaked" ]]; then
  echo "FAIL: leaked candidates in address lookup:"
  echo "$leaked"
  exit 1
fi

echo "PASS: no is_candidate=true rows in address lookup"
```

**Note:** the `is_candidate` field is not currently exposed in the API response. The plan must either (a) expose `p.is_candidate` in `essentialsService` SELECT, or (b) cross-check returned IDs against a direct DB query. Planner picks.

---

### `scripts/verify-117-profile-loads.sh` (shell smoke test)

**Analog:** none. Based on RESEARCH.md Phase Requirements CAND-04 row: `curl -fsS https://essentials.empowered.vote/politician/<slug>`.

```bash
#!/usr/bin/env bash
# Phase 117: verify every imported candidate's profile page loads (200 OK).
set -euo pipefail

BASE="${FRONTEND_URL:-https://essentials.empowered.vote}"
DATABASE_URL="${DATABASE_URL:?DATABASE_URL required}"

slugs=$(psql "$DATABASE_URL" -Atc "
  SELECT slug FROM essentials.politicians
  WHERE source = 'phase_117_monroe_stub_import' AND slug IS NOT NULL
")

fail=0
while IFS= read -r slug; do
  [[ -z "$slug" ]] && continue
  url="$BASE/politician/$slug"
  if curl -fsS -o /dev/null -w "%{http_code}" "$url" | grep -q '^200$'; then
    echo "PASS: $url"
  else
    echo "FAIL: $url"
    fail=1
  fi
done <<<"$slugs"

exit $fail
```

---

### `src/lib/essentialsService.ts` L593 / L635 (modify, one-line filter)

**Analog:** self — current L593 `AND COALESCE(p.is_incumbent, true) = true`. This IS the pattern.

**Current filter** (L592-594):
```typescript
    AND (p.is_active = true OR o.is_vacant = true)
    ${includeChallengers ? '' : 'AND COALESCE(p.is_incumbent, true) = true'}
    ORDER BY COALESCE(p.id, o.id)
```

**Required change** (both `districtQueryText` ~L593 and `statewideQueryText` ~L635 — D-09):
```typescript
    AND (p.is_active = true OR o.is_vacant = true)
    ${includeChallengers ? '' : 'AND COALESCE(p.is_incumbent, true) = true'}
    AND COALESCE(p.is_candidate, false) = false
    ORDER BY COALESCE(p.id, o.id)
```

**Rationale** (RESEARCH.md L260-264): runs unconditionally — even when `includeChallengers=true`, sitting incumbents are still the "these are your reps" view. The `COALESCE(..., false)` keeps the filter forward-compatible: rows with NULL `is_candidate` (shouldn't happen due to `NOT NULL DEFAULT false` but safe) are treated as non-candidates.

**Also update the SELECT** to expose `p.is_candidate` if `verify-117-leak-closed.sh` needs to introspect it — otherwise the smoke test has to cross-check DB directly. Planner decides.

---

### `src/lib/compassService.ts` L279 (modify — CAND-05 risk gate)

**Analog:** self. This is a **decision, not a pattern copy**.

**Current code** (L265-288):
```typescript
export async function getCompassPoliticians() {
  // Only return politicians that have at least one compass answer
  // (matches Go backend behavior — prevents every card from showing compass icon)
  const { rows } = await pool.query(
    `SELECT DISTINCT ON (p.id)
            p.id, p.first_name, p.last_name, p.preferred_name, p.full_name,
            COALESCE(p.photo_custom_url, p.photo_origin_url, pi.url, '') AS photo_origin_url,
            p.is_active,
            [...]
     FROM essentials.politicians p
     JOIN inform.politician_answers pa ON pa.politician_id = p.id      -- ← L279 INNER JOIN (the blocker)
     LEFT JOIN essentials.offices o ON o.politician_id = p.id
     [...]
     WHERE p.is_active = true
     ORDER BY p.id, o.id DESC`
  );
```

**Three options** (RESEARCH.md Pitfall #2 — planner picks one before implementation):

**Option A — LEFT JOIN** (minimum code change):
```typescript
     FROM essentials.politicians p
     LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
     [...]
     WHERE p.is_active = true
     -- no WHERE on pa.id — both answered and zero-answer rows included
```
Risk: every politician appears in the picker; Compass UI must handle zero-answer rows. Research open question #1 flags this.

**Option B — sentinel row**: insert a single placeholder `inform.politician_answers` row per candidate during import. Rejected as "ugly, pollutes answers table" in RESEARCH.md.

**Option C — descope CAND-05**: pivot requirement to "structural readiness; picker visibility delivered in Phase 120/124". No code change to compassService.ts this phase.

Planner MUST resolve this before wave execution. RESEARCH.md calls A5 "the one to flag before execution".

---

### `117-FEASIBILITY.md` (markdown artifact)

**Analog:** none — this is a new artifact type for the phase.

**Required structure** (from D-01, D-02):
- Three tiers: **Confirmed-sourceable / Partial / Unsourceable**
- Per-candidate row: name, office, clerk-filing URL, candidate-site URL, press URL, fields-found Y/N (name, office, photo, bio)
- Prioritized "scope-down 5-10" list identifying which candidates survive if April 25 forces a scope cut
- Contested-race coverage summary (D-61 IN House, IN-9 US House, contested Monroe County offices)

**Structured sidecar** (RESEARCH.md open question #3 recommendation): also produce `117-FEASIBILITY-data.csv` or `.json` with columns: `race_candidate_id, full_name, first_name, last_name, office_title, chamber_id, district_id, photo_source_url, bio_text, bio_source_url, tier`. The import script consumes this file directly.

---

### Photo upload — reuse Python vs port to TS

**Analog (Python):** `EV-Backend/scripts/upload_monroe_council_photos.py` L38-92 — canonical pattern, verified working against `politician_photos` bucket.

**Core upload + DB update block** (L52-82):
```python
storage_path = f"{STORAGE_PREFIX}/{filename}"

with open(photo_path, "rb") as f:
    image_bytes = f.read()

# upsert=true: safe to re-run
client.storage.from_(BUCKET).upload(
    storage_path,
    image_bytes,
    {"content-type": "image/png", "upsert": "true"},
)
cdn_url = client.storage.from_(BUCKET).get_public_url(storage_path)

cur.execute("""
    UPDATE essentials.politicians
    SET photo_custom_url = %s
    WHERE slug = %s
    RETURNING id, full_name, photo_custom_url
""", (cdn_url, slug))
```

**Constants** (L22-24):
```python
BUCKET = "politician_photos"
STORAGE_PREFIX = "monroe_council"   # Phase 117 should use "monroe_2026" per RESEARCH.md L128
```

**TS port option** (`@supabase/supabase-js` is already a dependency):
```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

const BUCKET = 'politician_photos';
const STORAGE_PREFIX = 'monroe_2026';

async function uploadPhoto(localPath: string, filename: string): Promise<string> {
  const bytes = await fs.promises.readFile(localPath);
  const storagePath = `${STORAGE_PREFIX}/${filename}`;

  const { error } = await supabase.storage.from(BUCKET).upload(
    storagePath, bytes,
    { contentType: 'image/jpeg', upsert: true }
  );
  if (error) throw error;

  const { data } = supabase.storage.from(BUCKET).getPublicUrl(storagePath);
  return data.publicUrl;
}
```

**Planner decision:** port to TS (keeps Phase 117 code inside `ev-accounts/backend`, avoids cross-repo Python dep); OR invoke Python as a pre-step. Recommendation from RESEARCH: bespoke TS script (Finding #4).

## Shared Patterns

### Parameterized SQL / no string concatenation
**Source:** `seedPolitician.ts` L219-234 (all `$1, $2, $3` placeholders)
**Apply to:** all queries in `import-monroe-stub-candidates.ts`
**Security rationale:** RESEARCH.md Security Domain — "SQL injection via candidate name — Mitigation: All inserts parameterized"

### Transaction-per-candidate with explicit BEGIN/COMMIT/ROLLBACK
**Source:** RESEARCH.md L212-233 (sketch) + implied by Pitfall #5
**Apply to:** `import-monroe-stub-candidates.ts` main loop — wrap each candidate's INSERT + INSERT + UPDATE in a transaction, rollback on any failure.
```typescript
await pool.query('BEGIN');
try {
  /* inserts */
  await pool.query('COMMIT');
} catch (err) {
  await pool.query('ROLLBACK');
  throw err;
}
```

### Service-role key handling (never log)
**Source:** `upload_monroe_council_photos.py` uses `get_supabase_client()` indirection; never prints env
**Apply to:** any script touching `SUPABASE_SERVICE_ROLE_KEY`
**Rule:** no `console.log(process.env.SUPABASE_SERVICE_ROLE_KEY)`, no echoing auth headers; rely on `dotenv` + `.env` (already gitignored).

### Idempotent script re-runs
**Source:** `link-monroe-candidates-to-politicians.sql` header comment L8 — "This script is IDEMPOTENT — only updates candidates where politician_id IS NULL. Safe to re-run without side effects."
**Apply to:** `import-monroe-stub-candidates.ts` (pre-check stub linked state), `verify-117-imports.sql` (SELECT-only), `verify-117-leak-closed.sh` (read-only curl).

### Migration filename numbering
**Source:** `ls ev-accounts/backend/migrations/ | sort -V` — next = **068**
**Apply to:** new migration file must be named `068_add_is_candidate_and_backfill.sql` (matches D-08).

### `COALESCE(bool_col, default) = expected` filter idiom
**Source:** `essentialsService.ts` L593 `COALESCE(p.is_incumbent, true) = true`
**Apply to:** new `COALESCE(p.is_candidate, false) = false` clause — preserves the existing style so the two filters read as a pair.

### `source` column tagging for bulk imports
**Source:** `seedPolitician.ts` L223 `'federal_2026_bulk_seed'`
**Apply to:** Phase 117 uses `'phase_117_monroe_stub_import'` as the literal. Enables verification queries (`WHERE source = 'phase_117_monroe_stub_import'`) and easy rollback if needed.

### Antipartisan placeholder rendering (reuse, don't replace)
**Source:** `ev-ui/src/PoliticianProfile.jsx` L640-650 — renders initials on `colors.evTeal` background when photo missing
**Apply to:** D-06 candidates (no photo, no bio) — do NOT introduce a new placeholder asset; rely on the existing initials-on-teal render. Bio falls back to literal `Candidate for [office title]`.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `verify-117-leak-closed.sh` | shell smoke test | request-response | No existing shell-based verification scripts in `ev-accounts/backend/scripts/`. Derived from RESEARCH.md test map row. |
| `verify-117-profile-loads.sh` | shell smoke test | request-response | Same as above. |
| `117-FEASIBILITY.md` | markdown research artifact | n/a | New artifact type. Structure derived from D-01/D-02/D-03 and RESEARCH.md open question #3. |

## Metadata

**Analog search scope:**
- `ev-accounts/backend/migrations/` — migration-with-backfill precedent
- `ev-accounts/backend/scripts/` — TS import + SQL verification scripts
- `ev-accounts/backend/src/lib/` — essentialsService, compassService, stagingService
- `EV-Backend/scripts/` — existing Python photo upload helpers
- `ev-ui/src/` — placeholder render pattern

**Files read (concrete excerpts extracted):**
- `ev-accounts/backend/migrations/064_backfill_city_council_geo_id.sql` (L1-46)
- `ev-accounts/backend/scripts/seedPolitician.ts` (L1-50, L180-260)
- `ev-accounts/backend/scripts/link-monroe-candidates-to-politicians.sql` (L1-60)
- `ev-accounts/backend/scripts/audit-112-candidates.ts` (L1-60)
- `ev-accounts/backend/src/lib/essentialsService.ts` (L538-650)
- `ev-accounts/backend/src/lib/compassService.ts` (L258-304)
- `EV-Backend/scripts/upload_monroe_council_photos.py` (L1-100)

**Pattern extraction date:** 2026-04-14

**Critical planner decision points (flagged by RESEARCH.md, surfaced here):**
1. **CAND-05 / compassService.ts L279** — pick Option A (LEFT JOIN), B (sentinel rows), or C (descope) before wave execution. Assumption A5 in RESEARCH.md.
2. **Photo upload language** — reuse Python or port to TS. Recommendation: TS port.
3. **`bio_source_url` column placement** — direct on `essentials.politicians` (recommended) vs. `politician_sources` join table. Recommendation: direct column, added in migration 068.
4. **`is_candidate` API exposure** — expose in `essentialsService` SELECT so `verify-117-leak-closed.sh` can introspect? Yes if shell script should be self-contained; no if cross-checking against DB is acceptable.
