# Phase 21: empowered_profiles Politician Schema - Context

**Gathered:** 2026-03-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Add the full politician field set to `inform.politicians` so that `GET /api/essentials/politicians` can return district and jurisdiction data to Essentials and Validation Quests. Includes a seed script to populate known Bloomington (IN) and Los Angeles (CA) politician records using PostGIS boundary data already loaded in Phase 19.

**Roadmap correction:** The Phase 21 goal was originally written as targeting `empower.empowered_profiles`. Discussion revealed politicians are data records without auth accounts — they live in `inform.politicians`, not the tier model. `empower.empowered_profiles` already has most of these columns from Phase 8. Phase 21 adds the missing columns to `inform.politicians` and updates the endpoints.

</domain>

<decisions>
## Implementation Decisions

### Column nullability
- All new string columns (`representing_city`, `representing_state`, `district_type`, `district_label`, `district_id`, `chamber_name`, `chamber_name_formal`, `government_name`) are **nullable** — NULL means "not yet populated," not empty string
- Boolean columns (`is_vacant`, `is_candidate`) already exist on `inform.politicians`; `is_vacant` is new and should be **NOT NULL DEFAULT false** — existing rows are assumed to be active filled seats

### New columns needed on inform.politicians
The following are missing from `inform.politicians` (most already exist on `empower.empowered_profiles` from Phase 8):
- `representing_city` TEXT nullable
- `representing_state` TEXT nullable
- `district_type` TEXT nullable
- `district_label` TEXT nullable — new everywhere (e.g., "9th Congressional District")
- `district_id` TEXT nullable
- `chamber_name` TEXT nullable
- `chamber_name_formal` TEXT nullable
- `government_name` TEXT nullable
- `is_vacant` BOOLEAN NOT NULL DEFAULT false — new everywhere

(`office_title` and `is_candidate` already exist on `inform.politicians`)

### Politicians vs candidates filter logic
- `/politicians` endpoint reads from `inform.politicians` where `is_vacant = false` (active filled seats)
- `/candidates` endpoint reads from `empower.empowered_profiles` where `is_candidate = true`
- These are separate data sources — politicians are data records, candidates are tier-model accounts
- The same real person can appear in BOTH endpoints if they are an incumbent running for re-election (politician in `inform.politicians` + empowered_profiles with `is_candidate = true`)

### NULL handling in API response
- All new fields are always included in API responses, even when `null`
- Consistent shape from day one — callers (Essentials, VQ) can always destructure the same fields without checking for key presence

### Backfill strategy
- Phase 21 includes a **separate seed script** (not embedded in the migration) to populate known Bloomington, IN and Los Angeles, CA politician records
- Data source: derive district assignments using PostGIS TIGER/Line boundary data already loaded in Phase 19 (resolve_user_jurisdiction for known district addresses)
- Seed script is idempotent (ON CONFLICT DO UPDATE or DO NOTHING) — safe to re-run as data grows
- Pattern: same as Phase 19 RUNBOOK-TIGER-LOAD.md — a documented runbook step, not an automatic migration

### Claude's Discretion
- Exact `district_label` display format (e.g., "Indiana 9th Congressional District" vs "9th District" vs "CD-9")
- Whether seed script is TypeScript or raw SQL
- How to handle the LA County data given the Phase 20 note that resolve_user_jurisdiction returns null for congressional/state_senate/state_house/school_district for CA addresses (county boundary only for Alpha)

</decisions>

<specifics>
## Specific Ideas

- Phase 19 already loaded Indiana TIGER/Line data AND LA County boundary — use `resolve_user_jurisdiction` against known district center-point addresses to derive the correct district identifiers for each politician
- Phase 20 STATE.md note: LA County Alpha coverage is county boundary only — congressional/state_senate/state_house/school_district return null for CA. LA politicians in the seed script may only get `district_type: 'county'` reliably
- `district_label` should be a human-readable label suitable for display (e.g., "Monroe County" or "Indiana 9th Congressional District") — the researcher should look at what Essentials / usePoliticianData.js renders with this field

</specifics>

<deferred>
## Deferred Ideas

- Cross-app account infrastructure integration (Compass, Essentials, VQ, CTC consuming the Accounts API) — this is a multi-phase effort, likely after Phase 24; not part of Phase 21 scope
- Politicians gaining real auth accounts (`empower.empowered_profiles` rows) — deferred until politicians actively join the platform; Phase 21 only manages their data records
- Admin tool UI for editing politician district fields — not in Phase 21 scope

</deferred>

---

*Phase: 21-empowered-profiles-politician-schema*
*Context gathered: 2026-03-13*
