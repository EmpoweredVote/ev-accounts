# Phase 117: Candidate Stub Resolution + Data Import - Research

**Researched:** 2026-04-14
**Domain:** Data import + schema migration (ev-accounts backend, Supabase Postgres, essentials schema)
**Confidence:** HIGH (all claims verified against codebase files — no external library research needed)

## Summary

Phase 117 is a two-track data-phase: (a) a **pre-code feasibility doc** (`117-FEASIBILITY.md`) cataloging public-record sourcing for ~30 Monroe County stub candidates, and (b) a **code wave** that adds an `is_candidate` column to `essentials.politicians`, backfills it for existing non-incumbent candidate leaks, inserts the sourced candidates as new `is_candidate=true` rows, and filters them out of the address-resolver.

The research surfaced four findings that meaningfully reshape planner decisions, listed here so they get top billing:

1. **The address-resolver already filters by `is_incumbent = true` today** (essentialsService.ts L593). The "candidate leakage" bug described in the memory note is narrower than it appears — it only affects rows where `is_incumbent` was wrongly set to `true`. The new `is_candidate` flag is still the right fix (explicit semantic over an overloaded `is_incumbent`), but the backfill logic must reconcile the two columns carefully.
2. **Compass picker filters by `JOIN inform.politician_answers`** (compassService.ts L279). New candidates with zero compass answers will **NOT** appear in the Compass picker automatically — CAND-05 is not satisfied by insert alone. This is a blocker the planner must address (either loosen the picker's filter or scope CAND-05 to "rows exist such that picker could render them when answers are added in a later phase").
3. **`stagingService.promoteToEssentials` hardcodes `is_incumbent = true`** (stagingService.ts L443, L475). Routing Phase 117 imports through staging would actively reintroduce the leak we're fixing. Staging is not a viable path without modifying the promote function first — which defeats the "reuse existing workflow" argument.
4. **No photo-upload code exists in `ev-accounts/backend`.** The Supabase Storage upload pattern lives in `EV-Backend/scripts/utils.py` and `EV-Backend/scripts/upload_monroe_council_photos.py` (Python, against the legacy Go backend repo). Bucket is `politician_photos`, path convention `{region_prefix}/{filename}`. A Phase 117 import script either (a) invokes the existing Python pattern, or (b) ports it to a new TS script — the planner must pick.

**Primary recommendation:** Write a bespoke TS import script (`scripts/import-monroe-stub-candidates.ts`) — not staging — that reads a feasibility-derived JSON/CSV, inserts `essentials.politicians` rows with `is_candidate=true, is_incumbent=false, is_active=true`, uploads photos via the existing Python upload helper (or a TS port), links `race_candidates.politician_id`, and records the bio source URL. The schema migration + backfill is a separate artifact (next number: **068**).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Feasibility sourcing (public records, clerk, press) | Claude (research) + human review | — | Not code — deliverable is a markdown doc |
| Schema change + backfill | Database (migration) | — | `is_candidate` column on `essentials.politicians` |
| Politician row inserts | Database (import script via `ev-accounts/backend/scripts/`) | — | Idempotent script pattern already used by `seedPolitician.ts` |
| Photo re-hosting | External CDN (Supabase Storage, bucket `politician_photos`) | Import script (TS/Py) | Never hotlink; follow existing `EV-Backend/scripts/utils.py` pattern |
| Address-lookup filter | API / backend (`essentialsService.getRepresentativesByAddress`) | — | Single SQL predicate, close the leak at the resolver |
| Compass picker visibility | API / backend (`compassService.getCompassPoliticians`) | — | Requires loosening the `JOIN inform.politician_answers` filter OR scope re-definition |
| Profile rendering (fallback photo) | Browser / ev-ui (`PoliticianProfile.jsx` placeholder div) | — | Already implemented — initials on `colors.evTeal` background, party-agnostic |
| Feasibility → planner go/no-go | Human decision | — | Not automated |

## Standard Stack

This is a codebase-internal data phase. No new libraries required. Existing stack:

| Library / Tool | Version | Purpose | Verified |
|---|---|---|---|
| `pg` (node-postgres) | existing | Direct SQL for essentials (not in PostgREST exposed list) | [VERIFIED: `ev-accounts/backend/src/lib/db.ts` imported throughout] |
| `tsx` | existing | TS execution for import scripts | [VERIFIED: `scripts/seedPolitician.ts` uses `npx tsx`] |
| `supabase-js` (Python) | existing | Storage upload via `client.storage.from_('politician_photos').upload(...)` | [VERIFIED: `EV-Backend/scripts/utils.py` L165] |
| `dotenv` | existing | `.env` loading in scripts | [VERIFIED: audit-112-candidates.ts L18] |

**Installation:** None. Phase 117 reuses everything already installed.

## User Constraints (from CONTEXT.md)

### Locked Decisions (D-01 through D-14)

- **D-01:** Feasibility is a tiered markdown doc (`117-FEASIBILITY.md`) with Confirmed-sourceable / Partial / Unsourceable tiers + prioritized scope-down 5-10 list.
- **D-02:** Claude performs **real sourcing** — actually hits clerk filings, candidate sites, press for each stub. Records source URLs + data-found Y/N per candidate.
- **D-03:** April 25 go/no-go is a **human discussion**, not a numeric threshold.
- **D-04:** Feasibility doc committed **BEFORE** any import script or migration.
- **D-05:** Source priority: **Monroe County Clerk filings first**, then candidate site/social, then local press.
- **D-06:** Candidates with no sourceable photo AND no sourceable bio still get imported with ev-ui missing-photo fallback + office-title-only bio (`Candidate for [office title]`).
- **D-07:** Bios are **extracted + lightly compressed from a single named source**. Never LLM-synthesized across sources. Source URL stored alongside bio text.
- **D-08:** Add `essentials.politicians.is_candidate BOOLEAN NOT NULL DEFAULT false` via migration. `true` = active candidate, not sitting official.
- **D-09:** Update `essentialsService` address-resolver path to exclude `is_candidate = true`. Compass picker and race listings still include candidates.
- **D-10:** **Backfill** `is_candidate = true` for any politician linked via `race_candidates` where `is_incumbent = false`. Runs in the same migration.
- **D-11:** Phase 117's 30 new imports all get `is_candidate = true`. Incumbents running again remain `is_candidate = false`.
- **D-12:** Photo placeholder = **reuse existing ev-ui PoliticianProfile missing-photo fallback**. Party-agnostic.
- **D-13:** Sourced photos → **Supabase Storage CDN** via existing scraped/re-hosted pattern. No hotlinking.
- **D-14:** Bio content bar = one sentence, ~120-180 chars. Source citation column is planner's discretion (`bio_source_url` on politicians, or a `politician_sources` join).

### Claude's Discretion

- Exact column name / placement of source-citation field.
- Staging workflow vs bespoke import script (**this research recommends bespoke — see Finding #3 above**).
- Migration filename numbering (**next available: 068** — verified by `ls migrations/ | sort -V`).
- SQL WHERE-clause vs application-code filter for `is_candidate` in address-resolver (**this research recommends SQL WHERE clause** — the existing query already has `AND COALESCE(p.is_incumbent, true) = true`, adding `AND COALESCE(p.is_candidate, false) = false` is a one-line change).

### Deferred Ideas (OUT OF SCOPE)

- Full candidate/politician table split (separate `candidacies` table joined to `people`) — post-primary phase.
- Candidate Q&A / response tracking (Vote411/VoteSmart parity) — v2026.5.x.
- Withdrawn candidate status tracking — v2026.5.x.
- Expanding `discover-indiana-candidates.ts` into a full automated pipeline — Phase 123+.
- Staging workflow vs bespoke script — flagged as planner discretion; research recommends bespoke.

## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| **CAND-01** | Feasibility evaluation doc exists before any code work | Deliverable template defined in D-01/D-02; raw stub list obtained via `npx tsx scripts/audit-112-candidates.ts` (queries `race_candidates WHERE politician_id IS NULL` for 2026-05-05 IN election). Research cannot perform the actual public-record sourcing in this step — that is the feasibility task itself. |
| **CAND-02** | Politician records exist for stub candidates with at minimum name + office | Insert pattern verified in `seedPolitician.ts::createFederalPolitician` (L220-236): INSERT `essentials.politicians (full_name, first_name, last_name, is_active, is_incumbent, source)` + INSERT `essentials.offices (politician_id, chamber_id, title, representing_state, is_vacant)`. Phase 117 adds `is_candidate=true` and omits the `source='federal_2026_bulk_seed'` literal in favor of a phase-specific marker. |
| **CAND-03** | Min viable data: photo, 1-line bio, office title | Photo pipeline verified in `EV-Backend/scripts/upload_monroe_council_photos.py` (bucket `politician_photos`, `upsert=true`, updates `essentials.politicians.photo_custom_url`). Bio cap of 120-180 chars is a content rule, not a schema constraint — `bio_text` is TEXT. Office title lives on `essentials.offices.title`, not on politicians. |
| **CAND-04** | Resolved candidates appear in Essentials profiles without errors | Profile route reads from `essentials.politicians` joined to offices/districts/contacts/images. The profile page fallback already handles missing photo (see `ev-ui/src/PoliticianProfile.jsx` L640-650: renders `<div style={styles.placeholder}>{initials || '?'}</div>`). |
| **CAND-05** | Resolved candidates appear in Compass politician picker | **RISK — requires planner decision.** `getCompassPoliticians()` in `compassService.ts` L265-304 does `JOIN inform.politician_answers pa ON pa.politician_id = p.id`. A newly-inserted candidate with zero compass answers will NOT appear. Options: (a) change JOIN to LEFT JOIN + include rows with zero answers, (b) seed a placeholder `politician_answers` row per candidate, (c) descope CAND-05 to "infrastructure ready; UI visibility follows in Phase 124 bio/stance work". |

## Runtime State Inventory

| Category | Items Found | Action Required |
|---|---|---|
| **Stored data** | `essentials.politicians` rows (adding ~30 new); `essentials.race_candidates` stub rows to update `politician_id`; `essentials.politician_images` for photo links; `essentials.offices` rows per candidate; `inform.politician_answers` (NOT written by this phase — but see CAND-05 risk). | Schema add + data migration + row inserts. |
| **Live service config** | None — no external service (n8n, Datadog, Cloudflare) stores candidate data. | None. |
| **OS-registered state** | None. | None. |
| **Secrets / env vars** | `DATABASE_URL`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` — all exist. | None. |
| **Build artifacts / installed packages** | None — no code rename, no package name change. | None. |
| **Cache keys (extra category for this phase)** | `candidateService.ts` and `essentialsService.ts` use an in-process cache (`cache.get(...)`) with TTL 900s on address and ZIP lookups. After import, cache will serve stale "no candidates here" results for up to 15 min. | Plan: document that verification should bypass cache or wait 15 min (or add a deliberate cache invalidation step). |

## Architecture Patterns

### System Architecture Diagram

```
┌────────────────────┐     ┌───────────────────────┐     ┌──────────────────────┐
│ Feasibility Input  │     │ Monroe County Clerk   │     │ Candidate sites /    │
│ (17-FEASIBILITY.md)│────►│ CAN-2 filings (auth.) │     │ local press          │
│ + structured CSV   │     └───────────────────────┘     └──────────────────────┘
└──────────┬─────────┘                 │                            │
           │                           ▼                            ▼
           │              ┌──────────────────────────┐
           │              │   Sourced facts per      │
           │              │   candidate: name,       │
           │              │   office, photo URL,     │
           │              │   bio, source URLs       │
           │              └──────────┬───────────────┘
           ▼                         ▼
┌──────────────────────────────────────────────────────┐
│ scripts/import-monroe-stub-candidates.ts             │
│                                                       │
│  for each candidate in feasibility list:             │
│    1. download photo → upload to Supabase Storage    │
│       (bucket: politician_photos, path:              │
│        monroe_2026/{slug}.jpg)                        │
│    2. INSERT essentials.politicians                   │
│       (is_candidate=true, is_incumbent=false,         │
│        is_active=true, bio_text, photo_custom_url)    │
│    3. INSERT essentials.offices (title, chamber_id)   │
│    4. INSERT essentials.politician_images             │
│    5. UPDATE essentials.race_candidates               │
│       SET politician_id = <new> WHERE id = <stub>     │
│    6. Record bio_source_url (column TBD)              │
└──────────────────────────┬───────────────────────────┘
                           │
                           ▼
            ┌──────────────────────────┐
            │ Supabase Postgres        │
            │ (essentials schema)       │
            └───────────┬──────────────┘
                        │
          ┌─────────────┼─────────────────────────┐
          ▼             ▼                         ▼
  ┌───────────────┐ ┌────────────────────┐  ┌─────────────────┐
  │ Essentials    │ │ Compass picker     │  │ Address resolver│
  │ profile route │ │ (RISK: filters by  │  │ FILTERS         │
  │ (works)       │ │ politician_answers)│  │ is_candidate    │
  │  → CAND-04    │ │  → CAND-05 risk    │  │  (leak closed)  │
  └───────────────┘ └────────────────────┘  └─────────────────┘
```

### Recommended Layout (new files)

```
.planning/phases/117-candidate-stub-resolution-data-import/
├── 117-FEASIBILITY.md               # deliverable for CAND-01
└── 117-FEASIBILITY-data.csv         # optional raw row source for import script

ev-accounts/backend/
├── migrations/
│   └── 068_add_is_candidate_with_backfill.sql    # D-08 + D-10 in one file
├── scripts/
│   ├── import-monroe-stub-candidates.ts          # new: reads feasibility CSV, does inserts
│   └── upload-monroe-stub-photos.py              # OR reuse Python pattern directly
```

### Pattern 1: Migration + backfill in one file (established)

**Source:** `ev-accounts/backend/migrations/064_backfill_city_council_geo_id.sql`, `067_backfill_municipality_geo_id.sql`, `047_add_city_council_district_columns.sql`

**Shape for 068:**

```sql
-- Migration 068: add is_candidate column + backfill from race_candidates
BEGIN;

ALTER TABLE essentials.politicians
  ADD COLUMN IF NOT EXISTS is_candidate BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN essentials.politicians.is_candidate IS
  'true = active candidate running for office; false = sitting official. Address resolver filters is_candidate=true out of tier-grouped results. See Phase 117 memory note project_candidates_vs_politicians.md.';

-- Backfill: any politician linked to a race as a non-incumbent is, by definition, a candidate
UPDATE essentials.politicians p
SET is_candidate = true
WHERE EXISTS (
  SELECT 1
  FROM essentials.race_candidates rc
  WHERE rc.politician_id = p.id
    AND rc.is_incumbent = false
);

-- Verification (logged, not returned)
DO $$
DECLARE v_count int;
BEGIN
  SELECT COUNT(*) INTO v_count FROM essentials.politicians WHERE is_candidate = true;
  RAISE NOTICE 'migration 068: is_candidate=true count after backfill: %', v_count;
END $$;

COMMIT;
```

### Pattern 2: Idempotent import script with INSERT + UPDATE race_candidates

**Source:** `ev-accounts/backend/scripts/seedPolitician.ts::createFederalPolitician` (L190-243) and `scripts/link-monroe-candidates-to-politicians.sql`

**Shape:** wrap inserts in a single transaction per candidate, skip if `race_candidates.politician_id IS NOT NULL` already (idempotent re-run).

```typescript
// Per-candidate transaction sketch — verify against seedPolitician.ts
await pool.query('BEGIN');
const { rows: [{ id: politicianId }] } = await pool.query(
  `INSERT INTO essentials.politicians
     (full_name, first_name, last_name, bio_text, photo_custom_url,
      is_active, is_incumbent, is_candidate, source)
   VALUES ($1,$2,$3,$4,$5, true, false, true, 'phase_117_monroe_stub_import')
   RETURNING id`,
  [fullName, firstName, lastName, bioText, photoCdnUrl]
);
await pool.query(
  `INSERT INTO essentials.offices
     (politician_id, chamber_id, title, representing_state, representing_city, is_vacant)
   VALUES ($1,$2,$3,'IN',$4, false)`,
  [politicianId, chamberId, officeTitle, city]
);
await pool.query(
  `UPDATE essentials.race_candidates
   SET politician_id = $1, updated_at = now()
   WHERE id = $2 AND politician_id IS NULL`,
  [politicianId, stubRaceCandidateId]
);
await pool.query('COMMIT');
```

### Pattern 3: Photo upload (Python, existing)

**Source:** `EV-Backend/scripts/upload_monroe_council_photos.py` L60-66, `EV-Backend/scripts/utils.py` L165-171.

```python
client.storage.from_(BUCKET).upload(
    storage_path,                       # "monroe_2026/{slug}.jpg"
    image_bytes,
    {"content-type": "image/jpeg", "upsert": "true"},
)
cdn_url = client.storage.from_(BUCKET).get_public_url(storage_path)
# then: UPDATE essentials.politicians SET photo_custom_url = cdn_url WHERE id = ...
```

**Bucket:** `politician_photos` (NOT `politician-headshots`). **Path convention:** `{region_prefix}/{filename}`. **Upsert:** `true` — re-run safe. Storage URL is stable across overwrites.

### Pattern 4: Filter addition in address-resolver

**Source:** `ev-accounts/backend/src/lib/essentialsService.ts::getRepresentativesByAddress` L538-595.

**Current filter (L593):** `${includeChallengers ? '' : 'AND COALESCE(p.is_incumbent, true) = true'}`

**Change:** add one line above the `ORDER BY`:

```sql
AND COALESCE(p.is_candidate, false) = false
```

This runs unconditionally (both when `includeChallengers` is true and false) — because even when showing challengers, sitting incumbents are still the "these are your reps" view. The same addition is needed on the statewide query (L597-641).

### Anti-Patterns to Avoid

- **Routing through staging** — `stagingService.promoteToEssentials` hardcodes `is_incumbent = true` (L443, L475). Would reintroduce the leak for every new candidate. Either modify that function as part of this phase (scope creep) or skip staging.
- **Hotlinking candidate-site photos** — D-13 forbids this. Photo breakage before May 5 would be visible and embarrassing.
- **Using `candidateService.ts`** — that file is for `empower.empowered_profiles` (user-owned Empowered tier accounts), NOT for `essentials.politicians` candidate rows. Despite the name, it is unrelated.
- **Writing bios by synthesizing from multiple sources** — D-07 forbids. One-source-only bios. This also simplifies the `bio_source_url` column to a single TEXT field.
- **Hand-rolling an admin UI for candidate entry** — 30 rows × May 1 deadline = zero ROI on UI work.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Supabase Storage upload | A new JS uploader | Reuse `EV-Backend/scripts/utils.py::upload_photo_to_supabase` pattern | Already handles upsert + CDN URL retrieval |
| Slug generation | A new slugifier | Whatever pattern `essentials.politicians.slug` already uses (see `link-monroe-candidates-to-politicians.sql` Step 0 which references slug update) | Consistency with existing rows |
| Stub inventory query | Fresh SQL | Re-run `npx tsx scripts/audit-112-candidates.ts` | Canonical "stub = politician_id IS NULL" definition; already validates election exists |
| Politician → candidate linking | Ad hoc UPDATE | `link-monroe-candidates-to-politicians.sql` pattern (last-name + first-3 prefix disambiguation) | Idempotent, safe re-run |
| Schema-change + backfill in separate migrations | Two files | One combined file (D-10 + D-08) | Matches 064, 067 precedent |
| Missing-photo placeholder UI | New asset | `PoliticianProfile.jsx` L640-650 already renders initials on `colors.evTeal` | Party-agnostic; already shipped |

## Common Pitfalls

### Pitfall 1: `is_incumbent` vs `is_candidate` semantic overlap
**What goes wrong:** After migration, a politician could theoretically have `is_incumbent=true AND is_candidate=true` (a sitting official running for re-election). The backfill (D-10) prevents one direction (`is_incumbent=false` → `is_candidate=true`) but doesn't constrain the other.
**Why it happens:** Two booleans encoding overlapping status.
**How to avoid:** Document in the column `COMMENT` that `is_candidate` means "not currently holding a seat" and that incumbents-running-again retain `is_candidate=false, is_incumbent=true`. This matches D-11.
**Warning signs:** Any row where both flags are true after migration. Add a verification SELECT to migration 068.

### Pitfall 2: Compass picker silently fails CAND-05
**What goes wrong:** Import script runs, rows exist, but `getCompassPoliticians` still returns the pre-import list because its INNER JOIN on `inform.politician_answers` drops zero-answer candidates.
**Why it happens:** L279: `JOIN inform.politician_answers pa ON pa.politician_id = p.id`
**How to avoid:** Planner MUST decide: (a) loosen JOIN to LEFT JOIN (may have performance/UX side effects — every row in the picker; check how the Compass frontend handles zero-answer rows); (b) insert sentinel `politician_answers` rows per candidate (ugly, pollutes answers table); (c) descope CAND-05 to "structural readiness, visibility delivered by Phase 120/124 stance authoring".
**Warning signs:** Post-import verification query `SELECT COUNT(*) FROM getCompassPoliticians()` returns the same count as before.

### Pitfall 3: Staging workflow reintroduces the leak
**What goes wrong:** Planner picks staging over bespoke script, doesn't notice `promoteToEssentials` hardcodes `is_incumbent=true` (L443), and all 30 new candidates land as fake incumbents.
**Why it happens:** Staging was built for sitting-official imports; never adapted for candidate semantics.
**How to avoid:** Do not use staging for this phase. If staging is preferred for volunteer-review reasons, the plan must include a task to modify `promoteToEssentials` to accept an `is_candidate` flag and set `is_incumbent = !is_candidate`.

### Pitfall 4: Cache TTL masks verification
**What goes wrong:** After running the import, an address-lookup smoke test returns stale results for up to 15 minutes (TTL 900s).
**Why it happens:** `essentialsService` and `candidateService` both wrap reads in `cache.get/set` with 900s TTL.
**How to avoid:** Verification script queries Postgres directly (`pool.query`) bypassing cache, OR waits 15 min, OR the planner adds a cache invalidation step.

### Pitfall 5: `race_candidates` stub not updated
**What goes wrong:** Import creates politician rows but forgets to `UPDATE essentials.race_candidates SET politician_id = <new>`. Stubs remain stubs. `audit-112-candidates.ts` still shows 30 stubs.
**Why it happens:** Two-step process (insert politician → update race_candidate) is easy to drop.
**How to avoid:** Wrap both in a single transaction per candidate. Planner includes an assertion in the import script: after insert, re-query `race_candidates WHERE id = <stub>` and assert `politician_id IS NOT NULL`.

### Pitfall 6: Office scaffolding not already present
**What goes wrong:** Import script tries to insert `essentials.offices` for a race whose `chamber_id`/`district_id` don't yet exist. Insert fails or inserts with nulls.
**Why it happens:** The research assumed scaffolding exists (see CONTEXT canonical_refs: "Planner verifies during research"). If a contested race has no pre-existing chamber/district rows, the phase must add them too.
**How to avoid:** Pre-flight check in import script: for each candidate's race, assert a matching `(chamber, district)` pair exists. Fail loudly and list missing ones.

## Code Examples

### Address-resolver SQL update (one-line filter addition)

**File:** `ev-accounts/backend/src/lib/essentialsService.ts`
**Location:** Inside `districtQueryText` (~L593) and `statewideQueryText` (~L635).

```typescript
// Source: ev-accounts/backend/src/lib/essentialsService.ts L593
AND (p.is_active = true OR o.is_vacant = true)
${includeChallengers ? '' : 'AND COALESCE(p.is_incumbent, true) = true'}
AND COALESCE(p.is_candidate, false) = false    // ← NEW: phase 117 leak fix
ORDER BY COALESCE(p.id, o.id)
```

### Migration 068 (verified pattern from 064/067)

```sql
-- migrations/068_add_is_candidate_with_backfill.sql
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

## State of the Art

This is an internal data phase; no external state-of-the-art applies. Noted for completeness:

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| `inform.politicians` with `is_candidate` column | `essentials.politicians` (unified; no `is_candidate`) | Phase 35 deduplication (pre-v2026) | The `is_candidate` column was dropped during Phase 35 consolidation and must now be re-added. See comment at `essentialsService.ts` L167. |
| Two-record stub `inform.politicians` | Real 2577+ row `essentials.politicians` | Migration 058 | `admin_list_politicians` rewritten to hit essentials. Established that essentials is source of truth for all politician UI. |
| Scraped photos stored at origin URL | Re-hosted on Supabase Storage CDN | Pre-v2026.3.x | Phase 117 must follow; no hotlinking. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | "~30 stub candidates" — CONTEXT says ~30; exact count requires running `audit-112-candidates.ts` which needs DB access. Not run in this research session. | Summary | Scope differs; scope-down list (D-01) may need tightening. |
| A2 | The `essentials.politicians` row definitely has a `source` column (referenced in `seedPolitician.ts` L223 `source='federal_2026_bulk_seed'`). Not verified by reading the schema directly. | Patterns | Low — if missing, the INSERT simply drops the column. |
| A3 | No existing `bio_source_url` column on `essentials.politicians`. Grep for `bio_source` returned no results. | Sourcing column decision | Low — worst case, the column already exists and the migration adds it redundantly (guarded by `ADD COLUMN IF NOT EXISTS`). |
| A4 | The `politician_photos` Supabase bucket exists and the service-role key has upload permissions. Verified by existence of `upload_monroe_council_photos.py` which uses it successfully. | Photo pipeline | Low — fail fast at upload time if wrong. |
| A5 | The Compass picker risk (CAND-05) is a real blocker and not compensated for somewhere else in the codebase. Verified by reading `compassService.ts::getCompassPoliticians`. | CAND-05 risk | HIGH — if planner assumes "insert = visibility" without the picker-query change, CAND-05 silently fails at verification time. |
| A6 | Feasibility sourcing is feasible for most contested-race candidates via Monroe County Clerk (`monroecounty.in.gov`) CAN-2 filings. NOT VERIFIED — Research did not attempt live sourcing; that is the feasibility task (D-02). | CAND-01 | Medium — if clerk filings are not publicly accessible in a useful format, April 25 scope-down triggers. |

**Planner + discuss-phase:** A5 is the one to flag before execution. A6 is self-resolving (the feasibility doc IS the verification).

## Open Questions

1. **Compass picker filter — is `LEFT JOIN politician_answers` an acceptable change?**
   - What we know: Current query uses `INNER JOIN`; comment says "matches Go backend behavior — prevents every card from showing compass icon" (compassService.ts L267).
   - What's unclear: Whether the Compass frontend has been updated since to handle zero-answer rows, or whether the UI will show a broken "compass icon but no data" state.
   - Recommendation: Planner checks `CompassV2` frontend for how zero-answer picker rows render. If they render cleanly as "no stance data" then `LEFT JOIN` is safe. If not, descope CAND-05 to "structural readiness."

2. **`bio_source_url` column vs `politician_sources` join table.**
   - What we know: A `transparent_motivations.politician_sources` table already exists (see `seedPolitician.ts::isDuplicate`). It stores FEC/Indiana discovery sources, not human-authored bio citations.
   - What's unclear: Whether reusing that table for bio citations is semantic overload.
   - Recommendation: Add `bio_source_url TEXT` directly on `essentials.politicians` as part of migration 068. Trivial to add, single-source-per-bio (D-07), and keeps `politician_sources` focused on discovery provenance.

3. **Does the feasibility doc need a structured CSV sidecar for the import script to consume?**
   - Recommendation: Yes. Planner should specify that `117-FEASIBILITY.md` is the human-readable artifact and `117-FEASIBILITY-data.csv` (or `.json`) is the machine-readable input for `import-monroe-stub-candidates.ts`. Keeps Claude's sourcing work double-duty: doc + data file.

4. **Contested-race scaffolding gap.**
   - What we know: The `race_candidates` table has stubs, meaning races exist. But chambers/districts/offices may or may not exist for each.
   - What's unclear: Whether `seed-monroe-county-2026-primary.sql` already created all the office scaffolding the import needs.
   - Recommendation: Pre-flight check in the import script. Planner adds a task for it.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| `node` / `npx` / `tsx` | Import script | ✓ (used by all existing scripts) | existing | — |
| `pg` (Postgres connection) | Migration + inserts | ✓ | existing `DATABASE_URL` | — |
| Supabase Storage bucket `politician_photos` | Photo uploads | ✓ (verified by `upload_monroe_council_photos.py`) | — | — |
| Python 3 + `supabase` + `psycopg2` (for existing photo upload script) | If reusing Python helper instead of porting | Unknown in the ev-accounts workspace | — | Port to TS using `@supabase/supabase-js` (already a dependency elsewhere in the project) |
| Monroe County Clerk public-record access | Feasibility sourcing | Unverified | — | Fall back to LegiScan / Ballotpedia / candidate sites; flag in feasibility doc |
| `FEC_API_KEY` | NOT needed for Phase 117 (county-level races) | — | — | — |

**Missing with no fallback:** None blocking the code path.
**Missing with fallback:** Public-record sourcing — feasibility doc itself handles this by tiering candidates.

## Validation Architecture

### Test Framework
| Property | Value |
|---|---|
| Framework | Vitest + integration test suite (see `ev-accounts/backend` — `npm test`) |
| Config file | `ev-accounts/backend/vitest.config.ts` (assumed — Wave 0 verify) |
| Quick run command | `cd ev-accounts/backend && npm run typecheck` |
| Full suite command | `cd ev-accounts/backend && npm test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| CAND-01 | Feasibility doc exists and is committed | manual-only | human review of `.planning/phases/117-*/117-FEASIBILITY.md` | N/A (doc) |
| CAND-02 | Politician records exist for each stub in the scope-down list | integration (SQL) | `psql $DATABASE_URL -c "SELECT COUNT(*) FROM essentials.politicians WHERE source = 'phase_117_monroe_stub_import'"` | ❌ Wave 0 (new script) |
| CAND-02 | `race_candidates.politician_id` no longer NULL for imported candidates | integration (SQL) | `npx tsx scripts/audit-112-candidates.ts --dry-run` (compare stub count pre/post) | ✓ script exists |
| CAND-03 | Each imported candidate has `photo_custom_url` OR falls back to placeholder; has `bio_text` non-empty; has matching `essentials.offices` row | integration (SQL) | `psql $DATABASE_URL -f scripts/verify-117-imports.sql` | ❌ Wave 0 |
| CAND-04 | Essentials profile page loads for each imported candidate without 500 error | e2e smoke | `curl -fsS https://essentials.empowered.vote/politician/<slug>` for each new slug | ❌ Wave 0 (shell script) |
| CAND-05 | Imported candidates appear in Compass picker | integration (SQL) | `psql $DATABASE_URL -c "SELECT full_name FROM essentials.politicians WHERE source='phase_117_monroe_stub_import' AND id IN (SELECT DISTINCT politician_id FROM inform.politician_answers)"` — **PLUS** planner-decided picker-query fix | ❌ Wave 0 + **CAND-05 risk gate** |
| `is_candidate` leak closed | Address lookup for a Monroe County address does NOT return any `is_candidate=true` row | integration (API) | `curl -fsS "$API/api/essentials/representatives?address=..." \| jq '.politicians[] \| .is_candidate' \| grep -v false` (should be empty) | ❌ Wave 0 |
| Backfill correctness | After migration 068, every politician linked via `race_candidates.is_incumbent=false` has `is_candidate=true` | integration (SQL) | `psql -c "SELECT COUNT(*) FROM essentials.politicians p WHERE is_candidate=false AND EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.politician_id=p.id AND rc.is_incumbent=false)"` (must be 0) | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `npm run typecheck` (fast)
- **Per wave merge:** `npm test` + `npx tsx scripts/audit-112-candidates.ts --dry-run` (compare stub counts)
- **Phase gate:** All SQL verifications green + at least one live address-lookup smoke test + Compass picker check

### Wave 0 Gaps
- [ ] `ev-accounts/backend/scripts/verify-117-imports.sql` — idempotent SQL verification of imports (row counts, source tag, photo+bio+office completeness, is_candidate flag)
- [ ] `ev-accounts/backend/scripts/verify-117-leak-closed.sh` — curl address resolver, assert no `is_candidate=true` rows returned
- [ ] CAND-05 decision: pick one of (a) LEFT JOIN picker fix, (b) sentinel politician_answers, (c) scope descope — must be resolved before implementation begins
- [ ] Manual QA script listing one URL per imported slug for human smoke test before May 1

*(No new Vitest files required if all verification is SQL + shell — feasible given the phase timeline.)*

## Project Constraints (from CLAUDE.md)

- **Schema namespace:** Essentials lives in `essentials.*` schema. NOT in PostgREST exposed list → all reads/writes use `pool.query()` directly (`supabaseAnon.schema('essentials')` will fail).
- **Essentials service module:** `ev-accounts/backend/src/lib/essentialsService.ts` is the canonical address-resolver surface. New SQL filters land here.
- **Migrations directory:** `ev-accounts/backend/migrations/NNN_description.sql`. Next number: 068.
- **Photo CDN pattern:** Supabase Storage, bucket `politician_photos`, `upsert=true`, store result in `essentials.politicians.photo_custom_url` (preferred over `photo_origin_url` per address-resolver query `COALESCE(p.photo_custom_url, p.photo_origin_url, '')`).
- **Antipartisan principle (memory note):** Placeholder photos, bios, any UI must NOT use partisan colors or party framing. `PoliticianProfile.jsx` placeholder uses `colors.evTeal` — compliant.
- **Security:** `SUPABASE_SERVICE_ROLE_KEY` is required for Storage upload but must NEVER be committed. Scripts read from `.env`.
- **Commit style:** Recent commits use `docs(NNN-MM): ...` and `feat(NNN-MM): ...` prefixes. Migration commits typically separate from script commits.

## Security Domain

| ASVS Category | Applies | Control |
|---|---|---|
| V2 Authentication | no | Import runs as operator with DB credentials — no end-user auth surface |
| V3 Session Management | no | — |
| V4 Access Control | yes | `SUPABASE_SERVICE_ROLE_KEY` required for Storage upload; must not leak into logs or commits |
| V5 Input Validation | yes | Feasibility-derived CSV/JSON is operator-authored but still must be validated: required fields (name, office, race_candidate_id), length caps (bio 180 chars), URL shape (bio_source_url) |
| V6 Cryptography | no | — |

### Threats

| Pattern | STRIDE | Mitigation |
|---|---|---|
| Service role key leak via committed `.env` or log dump | Information disclosure | `.gitignore` already excludes `.env`; script must not `console.log(process.env.SUPABASE_SERVICE_ROLE_KEY)`; the pattern in `upload_monroe_council_photos.py` already uses `get_supabase_client()` indirection |
| Malicious bio_source_url (XSS if rendered as unsanitized HTML) | Tampering | Frontend renders `bio_text` as text, not HTML — verified by reading `PoliticianProfile.jsx`. `bio_source_url` should be rendered via `<a href>` — planner verifies existing contact URL rendering path is used |
| SQL injection via candidate name | Tampering | All inserts parameterized (`$1`, `$2`) — verified by existing `seedPolitician.ts` pattern; no string concatenation |
| Reputational / factual harm from hallucinated bios | Integrity | D-07 hard rule: single-source, no synthesis. Planner enforces via code review of `117-FEASIBILITY.md` |

## Sources

### Primary (HIGH confidence — direct codebase reads)
- `.planning/phases/117-candidate-stub-resolution-data-import/117-CONTEXT.md` (locked decisions D-01..D-14)
- `.planning/REQUIREMENTS.md` (CAND-01..CAND-05)
- `.planning/ROADMAP.md` (phase goal, success criteria)
- `.planning/STATE.md` (May 1 deadline, April 25 scope-drop gate)
- `ev-accounts/backend/src/lib/essentialsService.ts` L538-715 — address resolver query shape + existing `is_incumbent` filter
- `ev-accounts/backend/src/lib/compassService.ts` L258-304 — Compass picker JOIN on `politician_answers` (CAND-05 risk source)
- `ev-accounts/backend/src/lib/stagingService.ts` L360-489 — staging promote path with hardcoded `is_incumbent=true`
- `ev-accounts/backend/src/lib/candidateService.ts` L1-297 — confirmed unrelated to Phase 117 (empower tier, not essentials)
- `ev-accounts/backend/scripts/audit-112-candidates.ts` — canonical stub definition + query
- `ev-accounts/backend/scripts/seedPolitician.ts` L190-243 — insert pattern (reference for Phase 117 import)
- `ev-accounts/backend/scripts/link-monroe-candidates-to-politicians.sql` — idempotent linking pattern
- `ev-accounts/backend/migrations/064_backfill_city_council_geo_id.sql` — migration-with-backfill pattern
- `ev-accounts/backend/migrations/026_inform_schema_repair_and_candidates.sql` L250 — historical `is_candidate` column on `inform.politicians` (dropped in Phase 35 dedup)
- `ev-accounts/backend/migrations/033_politician_schema.sql` — historical `is_candidate` in RPC return type
- `ev-accounts/backend/migrations/058_admin_list_politicians_fix_schema.sql` L53 comment — confirms `is_candidate` not present in current essentials schema
- `EV-Backend/scripts/upload_monroe_council_photos.py` L60-66 — canonical photo upload + DB update pattern
- `EV-Backend/scripts/utils.py` L150-171 — reusable `upload_photo_to_supabase` helper (Python)
- `ev-ui/src/PoliticianProfile.jsx` L280-295, L640-650 — missing-photo fallback (initials on evTeal), party-agnostic

### Secondary (MEDIUM confidence — inferred from grep)
- `ev-accounts/backend/migrations/` listing — next number is 068 (verified by `ls | sort -V`)

### Tertiary (LOW / unverified — flagged for feasibility doc)
- Monroe County Clerk CAN-2 filings URL and format — not visited
- LegiScan / Ballotpedia candidate coverage for Monroe County stub list — not visited
- Exact count of stubs (~30 per CONTEXT; authoritative count requires running `audit-112-candidates.ts --dry-run`)

## Metadata

**Confidence breakdown:**
- Codebase structure / patterns: **HIGH** — all claims verified by direct file reads.
- `is_candidate` leak mechanics: **HIGH** — the current `is_incumbent`-only filter is verified in `essentialsService.ts` L593.
- Compass picker CAND-05 risk: **HIGH** — verified via `compassService.ts` L279 INNER JOIN.
- Staging suitability: **HIGH** — verified by reading `stagingService.ts::promoteToEssentials` hardcoded literal.
- Feasibility sourcing feasibility: **UNVERIFIED** — by design; that's the Phase 117 gate task itself.
- Exact stub count: **MEDIUM** — CONTEXT says ~30; exact count requires DB query.

**Research date:** 2026-04-14
**Valid until:** 2026-04-25 (April 25 scope-drop gate) — any decisions beyond that need re-validation against the committed feasibility doc.
