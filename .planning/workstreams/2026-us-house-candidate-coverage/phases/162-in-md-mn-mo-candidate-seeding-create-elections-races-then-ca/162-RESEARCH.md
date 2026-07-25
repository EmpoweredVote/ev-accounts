# Phase 162: IN + MD + MN + MO Candidate Seeding - Research

**Researched:** 2026-07-04
**Domain:** Pure-data election seeding (Postgres/Supabase) — second Wave-3 seeding phase, cloning the proven Phase-161 pipeline
**Confidence:** HIGH (every mechanic is a direct, already-executed-once precedent from Phase 161; MO severity classification is MEDIUM until the phase's own D-01a audit runs — same posture Phase 161 had for TN)

## Summary

Phase 162 is a **parameterization exercise, not new engineering**. Every mechanic needed — per-state elections+races migration, MA-style existing-race reuse (here: MD), external_id assignment, headshot pipeline, stance push pipeline, redistricted-state severity-routed withholding, incumbent-flag bug fix — was already built and proven exactly once in Phase 161 (WA/AZ/TN/MA), completed 2026-07-04. This research's job is narrow: confirm the phase-specific facts (which MO districts are the audit's likely severe candidates, the exact IN-9 bug rows, the exact MD reuse state, per-state record counts) and hand the planner direct clone-templates (file paths, SQL, decision mechanisms) from 161, rather than re-deriving methodology already locked in `162-CONTEXT.md`.

**Total scope:** 33 districts (IN 9 decided / MD 8 decided-with-open-window / MN 8 late-primary / MO 8 late-primary-plus-redistricted). **118 new candidate records** required (IN 12, MD 13, MN 35, MO 58) plus the **11 zero-tier incumbents** (MD's all 8 + IN's Baird/Carson/Messmer) requiring full stance research — **129 total stance-research targets**, comparable in scale to Phase 161's ~183-record load but concentrated more heavily in MO/MN's multi-filer late-primary fields than in incumbent top-up.

**Primary recommendation:** Clone `161-tn-generate.mts` → `162-mo-generate.mts` for MO (redistricted, severity-routed withholding), clone `161-az-generate.mts`/`161-wa-generate.mts` → `162-mn-generate.mts` and `162-in-generate.mts` for the vanilla new-election states, and clone `161-ma-generate.mts` → `162-md-generate.mts` for MD's races-only reuse. Fix the IN-9 incumbent-flag bug (D-02) as Task 1 of the IN seed plan (a 5-row UPDATE + re-query, not a standalone research plan — unlike TN's audit, this fix requires no research, only a live DB query). Clone `161-verify.sql`/`161-coordinate-smoke.ts` structurally for the phase-closing 33-district mini-gate, adding a new MO-severe assertion block analogous to 161's TN-SEVERE block.

## User Constraints (from CONTEXT.md)

<user_constraints>

### Locked Decisions

**D-01 (MO redistricting handling — mirrors TN D-01 from Phase 161):** MO is redistricted for 2026 (2025 GOP-drawn map upheld by MO Supreme Court 4-3, 2026-03-24; pending referendum does not affect 2026). Same stale-polygon situation as TN: DB holds old (pre-2025) MO district polygons; seeded data is keyed to the NEW map and stays correct; only the address→race polygon join is stale, self-correcting on Phase-164.1's polygon refresh. MO races wire to the **existing CD-numbered district rows** (old polygons) — importing new polygons now would falsify the reps feed.

**D-01a (audit FIRST):** Phase opens with an MO old-vs-new district correspondence audit — one research task, scoring boundary-shift severity per district, shipped as a phase artifact (clone the TN audit rubric from 161-01). Runs up front, parallel with early non-MO seeding.

**D-01b (gate severe):** MO districts scored severe (expected: **MO-5** Cleaver, primary remap target; check MO-4/MO-6 adjacency) are seeded but NOT surfaced (races+candidates+stances land; race withheld from `/elections`). Planner picks the mechanism — **match 161's D-01b choice exactly** (see Must-Answer #1 below: election_id-substitution).

**D-01c (un-gate in 164.1):** Already-committed Phase 164.1 (TN+MO+AL+LA+UT polygon refresh) un-gates any MO districts withheld here. No new roadmap insertion needed.

**D-02 (IN-9 incumbent-flag bug — fix BEFORE any IN seeding):** Pre-existing IN-9 primary race (`7d3f0042-eb15-462b-bf14-df15244c5d16`) carries 5 mis-flagged `race_candidates` rows: Houchin (true incumbent) flagged `is_incumbent=false`; her 4 primary opponents flagged `is_incumbent=true`. A dedicated first plan step corrects these 5 rows, verified by re-query, BEFORE any IN general race/race_candidates are authored. Houchin's `politician_id` (`68568faf-1e0f-4ca2-89d9-bda625665712`) is reused for the general race — never insert a new Houchin record.

**D-02a:** Scope is flag-correction ONLY on the existing primary rows — do not delete the primary race or its rows (valid historical data).

**D-03 (state ordering & urgency):** **MO runs first, end-to-end** (audit → races → records → headshots → stances → push) — earliest civic moment (Aug-4 primary; Jul-27 independent petition deadline), largest/most-urgent provisional field, and the audit must front-load anyway. Then **MN** (Aug-11 primary). Then **decided IN + MD last** (small fields, lowest urgency). Push stances per state as each completes (never one mega-push).

**D-03a:** Within each state, stance research runs incumbents + evidenced majors first, fringe filers last.

**D-04 (MD reuse):** MD reuses its 8 `existing_race_id` general races (see `160-race-preexistence-audit.csv`) — do NOT author new MD `races`; the MA Phase-161 reuse pattern applies. Confirm at plan time whether any MD `race_candidates` rows already exist (like MA-5/MA-7 did) and do not duplicate them. **(Research finding: confirmed 0 pre-existing MD `race_candidates` rows — see Must-Answer #4 below; unlike MA, MD needs no dedup guard for pre-wired incumbents, though a `NOT EXISTS` guard is still good idempotency practice.)**

**D-04a:** MD is `field_status=decided` (Jun-23 nominees final) but carries `filing_open_deadline=2026-08-03` (unaffiliated/minor-party window still open statewide). Seed confirmed nominees + declared-so-far minor-party candidates NOW; Phase 167 catches late-filed independents after Aug-3. MO carries the same open-window nuance (Jul-27 petition deadline) — its full field is already seeded provisionally, so the re-pull is a Phase-167 concern.

### Carried Forward (locked — do not re-litigate; from Phase 161 / milestone standing standards)
- Full provisional field seeded NOW marked `PROVISIONAL:` for late-primary states (MN/MO); only the cull (Phase 167) is date-gated.
- Full federal-24 sourced stances per candidate; 0-unsourced gate floor; chairs-not-polarity; never party-inferred; honest-skip (per-topic or whole-record) only with a written search trail, whole-record skips gate-pinned; mandatory primary-source verification pass before every push.
- The 11 zero-tier incumbents (MD all 8 + IN Baird `499386`/Carson `499408`/Messmer `499413`) are IN-SCOPE for full stance research — unlike higher-tier incumbents, skipped via the diagnostic.
- `race_candidates`: non-null `politician_id`, `candidate_status='active'`, incumbents `is_incumbent=true`; NEVER party on the candidate card (`races.primary_party` only); NEVER `office_id IS NULL` on a House race.
- external_id band `-(state_fips*10000 + cd*100 + seq)`; FIPS: IN=18, MD=24, MN=27, MO=29. Re-verify 0 collisions per state before authoring (the current `160-negative-id-audit.csv` does NOT cover these 4 states — see Must-Answer #3). Existing incumbents use mixed legacy schemes (IN `-18001`, MD `-2440001`, MN `-27001`, MO `-29001`, plus positive SoS ids like `499386`) — never recompute or touch an incumbent's external_id.
- Incumbents reuse existing records (identity by `(district_type='NATIONAL_LOWER', geo_id)` join, never computed external_id); zero duplicate `full_name` per state. Verified departures: MD-5 Hoyer retired, MN-2 Craig (US Senate run), MO-6 Graves retired.
- Stance agents at 3-concurrency max, first-wave output validation, exact 1–5 scale texts embedded per topic (`_TOPIC_SCALE_FULL.txt`); headshots via find-headshots conventions — trust the auto-guard's first-name-mismatch rejection.
- Migrations idempotent (NOT EXISTS guards); pure-data changes need no deploy. Push each stance batch to PROD as it completes (stance CSVs are gitignored → PROD is the durable store).

### Claude's Discretion
- Exact plan count/splitting (e.g., whether MO's 58-record stance slice splits into two plans for checkpoint safety), gate assertion set, the severe-district withholding mechanism (D-01b — **research recommends: clone 161's exactly**), the MO correspondence audit's severity rubric (**research recommends: clone TN's rubric verbatim**), per-state elections/races migration authoring details, and where the IN-9 flag fix (D-02) lives in the plan graph (**research recommends: Task 1 of the IN seed plan, not a standalone plan**).

### Deferred Ideas (OUT OF SCOPE)
- Cross-state district polygon refresh / dual-map design (TN, MO, AL, LA, UT) — Phase 164.1 (committed, before Phase 165).
- Partial-incumbent stance top-up (higher-tier incumbents with some stances) — out of v2.22 scope.
- Challenger `finance_summary` — out of scope; record no-FEC-ID rather than retry.
- MD late-filing independents (window to Aug-3) and MO late independents (petition deadline Jul-27) — Phase 167's MO (Aug-4)/MN (Aug-11) clusters reconcile.
- v2.21 tail items (159-05/06, PA independents, FL Phase 153) — calendar-gated, separate.

</user_constraints>

## Phase Requirements

<phase_requirements>

| ID | Description | Research Support |
|----|-------------|------------------|
| USHC3-02 | Every candidate has exactly one `essentials.politicians` record; incumbents reuse; party normalized; collision-free external_ids | Must-Answer #2 (IN-9 fix), #3 (fresh collision query), #4 (MD reuse check), #5 (per-state counts) below |
| USHC3-03 | Every race surfaces on `/elections` via `races`+`race_candidates`; elections/races authored first; `race_candidates` non-null `politician_id`, `candidate_status=active`, incumbents flagged, never `office_id IS NULL` | Must-Answer #1 (MO audit + withholding mechanism clone), #8 (plan graph) below |
| USHC3-04 | Every newly-seeded candidate has a headshot (or documented honest-skip) | Pipeline templates section — clone `seed-{az,wa,tn,ma}-house-headshots.py` verbatim with new `BANDS` entries |
| USHC3-05 | Every newly-seeded candidate has sourced federal-24 stances, 0-unsourced, honest-skip with search trail | Must-Answer #6 (stance scope: 129 targets), #7 (fetch-wall intel) below |

</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Election/race authoring (elections, races rows) | Database / Storage | — | Pure data via migration SQL; no service-layer writes |
| Race surfacing on `/elections` | API / Backend (read path) | Database | `electionService.ts` reads races+race_candidates+districts+geofence_boundaries; zero code changes this phase |
| Candidate record creation (politicians, race_candidates) | Database / Storage | — | Pure data via migration SQL |
| Headshot ingestion (Wikipedia fetch → Storage → politician_images) | Backend script (offline) | Database / Storage | `backend/scripts/seed-*-house-headshots.py`, outside request path |
| Stance research + push | Backend script (offline) | Database | `_merge.ts`/`_push.ts`/`_push_uuid.ts`; writes via `pool.query()`, never PostgREST |
| MO old/new district correspondence audit (D-01a) | Research/analysis (no tier) | — | Pure research artifact; no runtime component |
| IN-9 incumbent-flag fix (D-02) | Database (single UPDATE) | — | 5-row idempotent flag correction on existing rows, no new records |
| Consolidated read-only mini-gate (33-district) | Database (read-only) | — | `psql -v ON_ERROR_STOP=1 -f 162-verify.sql` against prod |

No frontend/browser tier work exists in this phase.

## Standard Stack

This phase installs **zero new packages** — identical to Phase 161. All tooling is reused verbatim.

### Core (already installed, reused verbatim)
| Tool | Purpose | Why Standard |
|------|---------|---------------|
| `pg` / `backend/src/lib/db.js` `pool` | All non-public-schema reads/writes | PostgREST cannot see `essentials`/`inform` schemas |
| `psql -v ON_ERROR_STOP=1 -f` | Migrations + read-only verify gate | Matches every prior seeding phase |
| `psycopg2` + `requests` + `Pillow` (Python, invoke via `py` not `python3`) | Headshot pipeline | Proven pipeline; only a new `BANDS` entry needed per state |
| `node --import tsx` + `csv-parse/sync` | `_merge.ts`/`_push.ts`/`_push_uuid.ts` stance pipeline | Same pipeline used by every prior stance batch |
| `.mts` one-off generator scripts | Deterministic field→SQL migration generation | Avoids hand-writing 33 districts' worth of INSERTs |

### Alternatives Considered
None — this is a pure parameterization of Phase 161's proven pipeline; no new tool decisions to make.

**Installation:** None required.

## Package Legitimacy Audit

**N/A — this phase installs zero external packages.** All tooling (`pg`, `psycopg2`, `csv-parse`, `tsx`) is already installed and was vetted in prior phases (148–161). No new `npm install`/`pip install` occurs.

## Architecture Patterns

### System Architecture Diagram

```
160-field-table-p162.csv (33 rows, IN/MD/MN/MO)
        │
        ▼
┌───────────────────────┐     ┌──────────────────────────┐
│ D-01a: MO correspond-  │     │ D-02: IN-9 flag fix       │
│ ence audit (research   │     │ (UPDATE 5 existing rows,  │
│ artifact, no DB write) │     │ verify re-query)          │
└──────────┬─────────────┘     └──────────┬────────────────┘
           │ severe geo_id list             │ Houchin pid reused
           ▼                                ▼
┌─────────────────────────────────────────────────────────┐
│  Per-state .mts generator (clone 161-{tn,az,ma}-generate) │
│  → typed FIELD array → migration SQL (idempotent)         │
└───────────┬─────────────────────┬─────────────┬───────────┘
            │                     │             │
            ▼                     ▼             ▼
    MO: 2 elections        MN/IN: 1 election  MD: 0 new elections
    (general + withheld    each + races        (candidates-only onto
    "Polygon Pending"),    (new-election         8 existing_race_id)
    severity-routed races  pattern)
            │                     │             │
            └──────────┬──────────┴─────────────┘
                        ▼
            essentials.politicians (118 new)
            essentials.race_candidates (118 new + incumbent reuse rows)
                        │
                        ▼
            headshot pipeline (per-state BANDS entry)
                        │
                        ▼
            federal-24 stance research (129 targets: 118 new + 11 zero-tier)
            → _merge.ts → _push_uuid.ts (new) / _push.ts (existing) → PROD
                        │
                        ▼
            162-verify.sql + 162-coordinate-smoke.ts
            (33-district mini-gate incl. MO-severe non-surfacing assertion)
```

### Recommended Project Structure
```
backend/
├── scripts/
│   ├── 162-mo-generate.mts       # clone 161-tn-generate.mts (severity-routed)
│   ├── 162-mn-generate.mts       # clone 161-az-generate.mts (new-election, vanilla)
│   ├── 162-in-generate.mts       # clone 161-az-generate.mts + IN-9 flag-fix UPDATE prepended
│   ├── 162-md-generate.mts       # clone 161-ma-generate.mts (races-only reuse)
│   ├── seed-mo-house-headshots.py  # clone seed-tn-house-headshots.py (band-scoped, 2 elections)
│   ├── seed-mn-house-headshots.py  # clone seed-mi-house-headshots.py (election-scoped)
│   ├── seed-in-house-headshots.py  # clone seed-mi-house-headshots.py
│   ├── seed-md-house-headshots.py  # clone seed-ma-house-headshots.py (band-scoped over new range only)
│   ├── 162-verify.sql            # clone 161-verify.sql structurally + MO-SEVERE block
│   └── 162-coordinate-smoke.ts   # clone 161-coordinate-smoke.ts (4-state + MO-severe negative sample)
├── migrations/
│   ├── {N}_seed_mo_2026_house_elections_races.sql
│   ├── {N+1}_seed_mo_2026_house_candidates.sql
│   ├── {N+2}_seed_mn_2026_house_elections_races.sql
│   ├── {N+3}_seed_mn_2026_house_candidates.sql
│   ├── {N+4}_fix_in9_incumbent_flags.sql          # D-02, standalone idempotent UPDATE
│   ├── {N+5}_seed_in_2026_house_elections_races.sql
│   ├── {N+6}_seed_in_2026_house_candidates.sql
│   └── {N+7}_seed_md_2026_house_candidates.sql    # candidates-only, no elections/races INSERT
└── data/
    ├── seed-mo-2026-house/162-{plan}-mo-reconciliation.csv
    ├── seed-mn-2026-house/162-{plan}-mn-reconciliation.csv
    ├── seed-in-2026-house/162-{plan}-in-reconciliation.csv
    ├── seed-md-2026-house/162-{plan}-md-reconciliation.csv
    └── stance-research/{mo,mn,in,md}-2026-house/_TOPIC_SCALE_FULL.txt (federal-24 subset)
```

### Pattern 1: MO redistricted severity-routed seed (clone 161-tn-generate.mts / migrations 1196/1197 exactly)
**What:** Two elections (`MO 2026 Statewide General` + a dedicated, non-general, >30-day-past-dated `MO 2026 Congressional Redistricting - Polygon Pending` election); 8 races, each wired to the district's existing old-CD `NATIONAL_LOWER` office; severe races' `election_id` points at the withheld election, non-severe at the general.
**When to use:** MO only, this phase.
**Example:** See `backend/migrations/1196_seed_tn_2026_house_elections_races.sql` and `1197_seed_tn_2026_house_candidates.sql` verbatim — substitute FIPS 29, 8 districts, and the D-01a-derived severe geo_id list for TN's `4704,4705,4706,4708,4709`.

### Pattern 2: MD races-only candidate insert (clone 161-ma-generate.mts / migration 1202 exactly)
**What:** No `elections`/`races` INSERT — write only `race_candidates` onto the 8 `existing_race_id` values from `160-race-preexistence-audit.csv` (rows for MD, cd 1-8).
**When to use:** MD only, this phase.
**Example:** See `backend/migrations/1202_seed_ma_2026_house_candidates.sql` verbatim — substitute the 8 MD `existing_race_id` UUIDs (below) and the 13 new MD candidates. **Unlike MA, MD has ZERO pre-existing `race_candidates` rows** (confirmed — see Must-Answer #4), so the `NOT EXISTS` dedup guard exists purely for idempotent re-run safety, not to protect a live pre-wired incumbent row.

### Pattern 3: IN / MN vanilla new-election seed (clone 161-az-generate.mts exactly)
**What:** One `elections` row + N `races` rows wired to existing `NATIONAL_LOWER` offices — standard pattern, no reuse, no withholding.
**When to use:** IN and MN, this phase.
**Example:** See `backend/migrations/1187_seed_az_2026_house_elections_races.sql` / `1188_seed_az_2026_house_candidates.sql` verbatim — substitute FIPS 18 (IN, 9 districts) or FIPS 27 (MN, 8 districts).

### Pattern 4: IN-9 incumbent-flag fix (D-02, new pattern this phase — no direct 161 precedent, TN/WA/AZ/MA had no equivalent bug)
**What:** A standalone idempotent UPDATE on the 5 pre-existing IN-9 primary `race_candidates` rows, run BEFORE any IN general-race authoring.
**Example:**
```sql
-- Migration: fix_in9_incumbent_flags.sql
BEGIN;
UPDATE essentials.race_candidates
SET is_incumbent = true
WHERE id = '9d2de2ae-2fef-48b6-b3d4-2787166b78df'  -- Erin Houchin
  AND is_incumbent = false;

UPDATE essentials.race_candidates
SET is_incumbent = false
WHERE id IN (
  '037ad94f-d379-4f9c-baf1-a75742a46eac',  -- James H. (Jim) Graham
  '283b1fdd-3d89-4f82-a065-098324f2f967',  -- Keil L. Roark
  'a9233775-b8af-423e-aea6-734c2855e5ac',  -- Tim Peck
  '926943ad-ee64-4ddb-b9e7-6475a6a2d087'   -- Brad A. Meyer
) AND is_incumbent = true;
COMMIT;

-- Verification (must return exactly 1 row, is_incumbent=true, Houchin only):
SELECT rc.id, rc.full_name, rc.is_incumbent
FROM essentials.race_candidates rc
WHERE rc.race_id = '7d3f0042-eb15-462b-bf14-df15244c5d16'
ORDER BY rc.full_name;
-- Expected: Houchin true; Graham/Roark/Peck/Meyer all false.
```
**Do not delete the primary race or rows (D-02a)** — this is flag-correction only. Idempotent: re-running finds `is_incumbent` already correct and the `WHERE is_incumbent = {true|false}` guards make it a 0-row UPDATE on re-apply.

### Anti-Patterns to Avoid
- **Setting `office_id IS NULL` for MO's severe districts:** violates the locked, milestone-wide invariant. Use election_id-substitution (Pattern 1) instead.
- **Re-deriving MD's field from scratch or duplicating pre-wired rows:** MD has 0 pre-existing `race_candidates` (confirmed), so this risk is lower than MA's was, but still guard with `NOT EXISTS (race_id, politician_id)`.
- **Recomputing an incumbent's external_id under the new formula:** IN/MD/MN/MO incumbents keep their historical ids (`-18001` etc., or positive SoS ids for the 3 IN zero-tier incumbents); only new challengers get `-(fips*10000+cd*100+seq)`.
- **Skipping the live collision re-check because 160 already audited some states:** `160-negative-id-audit.csv` does NOT cover IN/MD/MN/MO (verified — see Must-Answer #3). Run a fresh check regardless.
- **Authoring IN's general race/candidates before fixing the IN-9 flag bug:** D-02 is an explicit ordering requirement — the fix must land first in the same plan (or an earlier plan) as any IN race authoring.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|--------------|-----|
| Headshot licensing/wrong-person detection | A new image-fetch script | Clone `seed-{az,wa,tn,ma}-house-headshots.py`, add a `BANDS` entry per state | The wrong-person guard took multiple phases of hardening (Bouchard incident) — do not re-derive |
| Stance topic scale texts | Hand-typing 1-5 text per topic | Fetch live from `inform.compass_topics`/`compass_stances`, filter to federal-24 | Topic set changes over time; hardcoded copies risk staleness |
| CSV→DB stance push | A new push script | `_merge.ts` + `_push.ts` (existing pid) / `_push_uuid.ts` (new NULL-external_id pid) | Handles RFC-4180 parsing, surname-leak guard, transactional push |
| Gate assertions for a multi-state seeding batch | A bespoke ad hoc verify script | Clone `161-verify.sql` structurally | Encodes the per-state-scoping discipline + honest-skip-pin-ordering lesson |
| MO district polygon comparison | A custom GIS diff pipeline | Qualitative county-level breakdown from named sources (per the TN precedent) | No shapefile parsing needed for a severity classification |
| Election-visibility withholding for a stale-polygon district | A new `is_visible` column or backend code change | The election_id-substitution mechanism (Pattern 1) | Reuses `electionService.ts`'s existing `ELECTION_VISIBILITY_WINDOW` semantics with zero code changes; proven end-to-end in 161 |

**Key insight:** Every mechanical piece of Phase 162 is a parameterization of an already-proven Phase-161 script — change the FIPS code, district count, and FIELD array. The only genuinely new artifact is the MO correspondence audit itself and the IN-9 flag-fix migration (which has no direct 161 precedent but is a trivial, well-specified UPDATE).

## Must-Answer Findings

### 1. MO correspondence audit (D-01a/b) — rubric, predicted severe districts, withholding mechanism

**Exact TN severity rubric to clone verbatim** (from `161-tn-correspondence-audit.md`):
> A district is scored **SEVERE** if either condition holds: (1) **>25% of the district's population moved to a different congressional district** between the old (currently-live-in-`essentials.districts`) map and the new map, OR (2) **the district's core anchor city/county changed** — the metro area/county that defined the district's political and geographic identity under the old map is no longer the anchor under the new map (lost entirely to another district, or a new anchor added that wasn't previously present). Otherwise **NOT-SEVERE**.
>
> Evidence basis: no shapefile/GIS diff (per the Don't-Hand-Roll guidance) — a qualitative county-level breakdown from named reporting, cross-checked against a quantitative proxy (shift in the district's notional 2024 presidential-election result recalculated under new vs. old boundaries, sourced to Dave's Redistricting App via Wikipedia's state-redistricting article), plus explicit "anchor changed" statements from named reporting.

**MO districts the evidence predicts will score severe:** `162-CONTEXT.md`'s Specific Ideas section names **MO-5** (Cleaver, Kansas City) as the primary remap target — "redrawn more Republican by adding rural counties" — and explicitly flags **MO-4/MO-6 adjacency** for audit attention. This research did not independently re-verify MO's redistricting details beyond what CONTEXT.md/160-03-SUMMARY already established (MO Supreme Court upheld the 2025 GOP-drawn map 4-3 on 2026-03-24); the actual severity scoring is D-01a's job, to be run fresh by the planner/executor using current news sources — do not treat MO-5/4/6 as pre-decided, only as the audit's starting hypothesis (mirrors how TN-4/5/6/8 were "open questions" in 161-RESEARCH.md that the audit itself resolved to a *larger* severe set than expected). **Recommendation: budget for the possibility that more than 3 of MO's 8 districts score severe**, as TN's audit found 5/9 severe against a working assumption of "maybe just 1-2."

**Withholding mechanism 161 actually used (clone exactly):** Point each severe race's `election_id` at a **dedicated, non-general, >30-day-past-dated "MO 2026 Congressional Redistricting - Polygon Pending" election row** (`election_type='special'`, a date more than 30 days before execution time — TN used its actual redistricting signing date, 2026-05-07). `office_id` stays on the district's normal old-CD `NATIONAL_LOWER` office for ALL races (satisfies the never-null invariant). `electionService.ts`'s `ELECTION_VISIBILITY_WINDOW` is:
```sql
(e.election_type != 'general' AND e.election_date >= CURRENT_DATE - INTERVAL '30 days')
OR (e.election_type = 'general' AND e.election_date >= DATE_TRUNC('year', CURRENT_DATE::date))
```
A `general`-type election dated anywhere in 2026 is ALWAYS visible (year-level check) — so the ONLY way to suppress a subset of races sharing a state's general election is to move them onto a different, non-general, stale-dated election row. race_candidates inserts should join by district `geo_id` directly (not by election name) — this lets one insert-generation code path correctly wire both severe and non-severe rows without branching (161's TN lesson). Verify with a direct SQL replica of `ELECTION_VISIBILITY_WINDOW` plus a coordinate-smoke negative sample against a severe MO district (161's exact verification pattern — see `161-11-SUMMARY.md`'s TN-SEVERE assertion and the `TN 4709` negative coordinate-smoke sample).

**MO headshot script departure to replicate:** Because MO (like TN) will have 2 elections for one state's House field, scope the headshot script's `BANDS` entry by **external_id band only, no election-name join** (161-06's exact departure from the single-election precedent) — severe-district candidates still need headshot attempts even though their race is currently withheld.

### 2. IN-9 flag fix (D-02) — exact rows, ids, and idempotent fix shape

Confirmed directly from `160-race-preexistence-audit.csv` (rows for `IN,9,1809,2026-05-05,2026 Indiana Primary,7d3f0042-eb15-462b-bf14-df15244c5d16,...`):

| candidate_pid | full_name | current is_incumbent | correct is_incumbent | race_candidates.id |
|---|---|---|---|---|
| `68568faf-1e0f-4ca2-89d9-bda625665712` | Erin Houchin | `false` | **`true`** | `9d2de2ae-2fef-48b6-b3d4-2787166b78df` |
| `037ad94f-d379-4f9c-baf1-a75742a46eac` | James H. (Jim) Graham | `true` | **`false`** | (same `race_candidates.id` as pid, `037ad94f-...`) |
| `283b1fdd-3d89-4f82-a065-098324f2f967` | Keil L. Roark | `true` | **`false`** | `283b1fdd-...` |
| `a9233775-b8af-423e-aea6-734c2855e5ac` | Tim Peck | `true` | **`false`** | `a9233775-...` |
| `926943ad-ee64-4ddb-b9e7-6475a6a2d087` | Brad A. Meyer | `true` | **`false`** | `926943ad-...` |

(Note: in this audit CSV, `candidate_pid` and `race_candidates.id` coincide for the 4 non-Houchin rows per the CSV's column layout; Houchin's `race_candidates.id` is `9d2de2ae-2fef-48b6-b3d4-2787166b78df`, distinct from her `politician_id` `68568faf-...`. Re-verify both id values with a live SELECT before writing the UPDATE, since the audit CSV's exact column semantics should be double-checked against the live schema rather than assumed from CSV positional inference alone.)

Primary race id: `7d3f0042-eb15-462b-bf14-df15244c5d16` ("2026 Indiana Primary", `election_date=2026-05-05`, `source=sos_excel`). Houchin's `politician_id` (`68568faf-1e0f-4ca2-89d9-bda625665712`) is confirmed identical across `160-field-table-p162.csv`, `160-incumbent-map.csv`, and this audit — reuse it for the IN-9 general race; **never INSERT a new Houchin record.**

**Idempotent UPDATE + verification shape:** See "Pattern 4" above (Architecture Patterns section) for the exact SQL. Run as its own small migration (or as Task 1 of the IN seed plan) with a `WHERE is_incumbent = {opposite value}` guard so re-runs are 0-row no-ops, then a re-query confirming exactly 1 `true` row (Houchin) and 4 `false` rows on race `7d3f0042-...`.

### 3. Fresh collision check for external_id band -(fips*10000+cd*100+seq), IN/MD/MN/MO

**Confirmed:** `160-negative-id-audit.csv` (16 colliding districts total) covers only `KY, OR, OK, KS, NV(x3), NM(x3), NE, ME(x2), NH, MT` — **zero rows for IN/MD/MN/MO.** This is consistent with (not necessarily proof of) 0 collisions for this phase's 4 states, since the underlying diagnostic script (`backend/scripts/diag-160-external-id-collision.ts`, from 160-01) iterates **all 38 Wave-3 states** and only emits rows where a collision is found — but CONTEXT.md is explicit that this must be re-verified fresh at plan time rather than inferred from CSV absence alone (the DB may have changed since 160-01 ran, e.g. via 161's own new-challenger inserts, though those used FIPS 53/04/47/25, not 18/24/27/29, so no overlap risk from that source specifically).

**Recommended fresh-check options (either is sufficient):**

**Option A — re-run the existing, already-committed diagnostic script** (safest, reuses hardened logic):
```bash
cd /c/EV-Accounts/backend && set -a && source .env && set +a && npx tsx scripts/diag-160-external-id-collision.ts
```
Confirm the regenerated `160-negative-id-audit.csv` still has 0 rows for `state IN ('IN','MD','MN','MO')`.

**Option B — direct scoped SQL, checking the exact bands this phase will write into:**
```sql
-- IN: fips=18, cd 1-9 | MD: fips=24, cd 1-8 | MN: fips=27, cd 1-8 | MO: fips=29, cd 1-8
SELECT external_id, full_name, external_id / -10000 AS approx_fips_cd
FROM essentials.politicians
WHERE external_id < 0
  AND (
    (external_id BETWEEN -180999 AND -180101)  -- IN CD1-9 seq 1-99 space, generous bound
    OR (external_id BETWEEN -240899 AND -240101)  -- MD CD1-8
    OR (external_id BETWEEN -270899 AND -270101)  -- MN CD1-8
    OR (external_id BETWEEN -290899 AND -290101)  -- MO CD1-8
  );
-- Expected: 0 rows (or only the known legacy incumbent ids -18001..-18009 / -2440001..-2440008 /
-- -27001..-27008 / -29001..-29008, which use a DIFFERENT legacy formula and must be excluded from
-- the "collision" definition -- they are not colliding with the NEW-challenger band's seq 1-99 space
-- unless seq happens to land on a legacy value; cross-check any hits against 160-incumbent-map.csv
-- before treating them as a real collision).
```
**Note the mixed legacy schemes to avoid recomputing:** IN incumbents use `-18001`..`-18009` (i.e., `-(fips*1000+cd)`, NOT the new-challenger `-(fips*10000+cd*100+seq)` formula); MD uses `-2440001`..`-2440008`; MN uses `-27001`..`-27008`; MO uses `-29001`..`-29008`; 3 IN incumbents (Baird/Carson/Messmer) use **positive** SoS-sourced ids (`499386`/`499408`/`499413`) and Houchin uses `499417`. None of these legacy/positive ids fall inside the new-challenger band's seq-1-99 range for any of these states' CDs (verified by inspection: e.g., IN CD9 new-challenger range is `-180901`..`-180999`, nowhere near `-18009` or `499417`), so a genuine 0-collision result is the expected outcome — but run the live check anyway per the "never trust a computed band" lesson from 160-01/161.

### 4. MD reuse (D-04) — the 8 existing_race_id values + pre-existing race_candidates check

From `160-field-table-p162.csv` / `160-race-preexistence-audit.csv`:

| cd | geo_id | existing_race_id |
|----|--------|-------------------|
| 1 | 2401 | `cb9a70c8-626b-43ed-9267-9531d2403535` |
| 2 | 2402 | `01c39962-63fe-4f5d-ac56-a546e09374a6` |
| 3 | 2403 | `34ae857f-a68e-40c6-a1bd-1bc9266dce5b` |
| 4 | 2404 | `1df5607b-36f4-45f6-a94f-adabba5811da` |
| 5 | 2405 | `b927bbd3-be7b-4ca1-a5f0-0fcd743a9997` |
| 6 | 2406 | `d5d7f27a-e421-46d8-af73-da225ea625a0` |
| 7 | 2407 | `a6b83f0d-bc99-4f29-9d39-a87025d55a01` |
| 8 | 2408 | `52874d42-9b2b-47c9-a87b-c11801627eb2` |

**Confirmed: 0 pre-existing MD `race_candidates` rows.** In `160-race-preexistence-audit.csv`, all 8 MD rows have every `race_candidates`-sourced column (`candidate_pid`, `full_name`, `is_incumbent`, `rc_id`, etc.) blank — unlike MA, which had 2 pre-wired rows (Clark MA-5, Pressley MA-7) that Phase 161 had to protect from duplication. This means MD needs no Clark/Pressley-style "already-wired-skip" handling; all 8 incumbents (Harris/Olszewski/Elfreth/Ivey/Hoyer-retired/McClain Delaney/Mfume/Raskin) AND all 13 new challengers get fresh `race_candidates` INSERTs onto the 8 existing races. Still apply a `NOT EXISTS (race_id, politician_id)` guard for migration idempotency (the 161-08 MA pattern), even though no live duplicate risk currently exists — a mid-phase re-run should never double-insert.

### 5. Per-state field counts (from 160-field-table-p162.csv)

**New records needed per district** (counted from `new_records_needed` column):

| State | District | New records | Notes |
|-------|----------|--------------|-------|
| IN | 1 | 1 (Regnitz) | |
| IN | 2 | 2 (Decio, Henry-L) | |
| IN | 3 | 1 (Thompson) | |
| IN | 4 | 1 (Cox) | Baird = zero-tier incumbent |
| IN | 5 | 1 (Ford) | |
| IN | 6 | 1 (Wirth) | |
| IN | 7 | 2 (McAuley, Sceniak-L) | Carson = zero-tier incumbent |
| IN | 8 | 1 (Allen) | Messmer = zero-tier incumbent |
| IN | 9 | 2 (Meyer, Hudson-L) | **D-02 fix required first**; Houchin done-tier (25 stances) |
| **IN total** | | **12** | |
| MD | 1 | 1 (Schwartz-D) | Harris = zero-tier |
| MD | 2 | 1 (Wallace-R) | Olszewski = zero-tier |
| MD | 3 | 1 (Flowers-R) | Elfreth = zero-tier |
| MD | 4 | 1 (McDermott-R) | Ivey = zero-tier |
| MD | 5 | **4** (Boafo-D, Chaffee-R, Burruss-Ind, Jordan-Ind) | **Open seat — Hoyer retired**; Hoyer = zero-tier (no active row needed, retired) |
| MD | 6 | 2 (Ficker-R, Landman-Green) | McClain Delaney = zero-tier |
| MD | 7 | 1 (Collier-R) | Mfume = zero-tier |
| MD | 8 | 2 (Riley-R, Wallace-Green) | Raskin = zero-tier |
| **MD total** | | **13** | all 8 incumbents zero-tier — full stance research on ALL MD incumbents required |
| MN | 1 | 4 (Goetzman, Morlan, Eaton, Johnson) | |
| MN | 2 | **7** (Pratt, Abdulle, Berg, Klein, Little, McTavish, Mosel) | **Open seat — Craig filed for Senate** |
| MN | 3 | 2 (Bass, Wittrock) | |
| MN | 4 | 4 (Rechtzigel, Wikstrom, Xiong, Rahman) | |
| MN | 5 | **9** (Jackson, Al-Aqidi, Nagel, Windhauser, Zieska, Le, McKenzie, Reeves, Schluter) | Omar's district — largest MN field |
| MN | 6 | 3 (Corey, Foley, Chapin) | |
| MN | 7 | 2 (Carlson, Osberg) | |
| MN | 8 | 4 (Hamilton, Gulbranson, Munter, Swanson) | |
| **MN total** | | **35** | |
| MO | 1 | **7** (Bush-D, Harris-D, Henderson-D, Murphy-D, Berry-R, Jones-R, Schmitz-L) | **MO-1 primary note: Cori Bush (D) challenging incumbent Wesley Bell (D) — 2024 rematch, both need candidate records (Bell reuses existing pid, Bush is new); prioritize Bush under D-03a (evidenced major)** |
| MO | 2 | 10 (Sparks-Holmes, Pfeifer, Sheridan, Wilkinson, Bilash, Summers, Vivio, VonDras, Wellman, Coulter Daugherty) | |
| MO | 3 | 6 (Fraser, Conner, Holstein, Mann, Wilson, Higgins) | |
| MO | 4 | 10 (Shelton, Vera, Cass, Gray, Herrera, Miller, Rick, Rogers, Russell, Holbrook) | Flagged for D-01a adjacency check |
| MO | 5 | 7 (Beebe, Brattin, Burks, Hueffmeier, Knox, Patty, Langkraehr) | **Cleaver's district — D-01a expected-severe candidate** |
| MO | 6 | **9** (Ingram, Oshel, Schultz, Stigall, Willett, Levine, Pondelick, Smead, Maidment) | **Open seat — Graves retired**; flagged for D-01a adjacency check |
| MO | 7 | 4 (Casey, Hunt, Hesketh, Craig) | |
| MO | 8 | 5 (Heslop, Barnitz, Harbison, Reichard, Sharpe Lombard) | |
| **MO total** | | **58** | Largest single-state new-record load in this phase; comparable to WA's 60 in Phase 161 |

**Grand total new records: 12 + 13 + 35 + 58 = 118.** Plus 11 zero-tier incumbents requiring full stance research (MD's 8 + IN's Baird/Carson/Messmer) = **129 total stance-research targets** for this phase.

### 6. Stance scope confirmation

**11 zero-tier incumbents in-scope for full federal-24 stance research** (0 existing stances each, per `160-incumbent-map.csv`):
- MD (all 8): Harris `-2440001`, Olszewski `-2440002`, Elfreth `-2440003`, Ivey `-2440004`, Hoyer `-2440005` (retired — no active race_candidates row needed, but verify whether any historical stance backfill applies; likely N/A since he's not on the 2026 ballot), McClain Delaney `-2440006`, Mfume `-2440007`, Raskin `-2440008`
- IN (3): Baird `499386`, Carson `499408`, Messmer `499413`

**Higher-tier incumbents correctly OUT of scope** (skipped via the diagnostic — "partial"/"done" tier, already have some-to-full stance coverage): IN's Mrvan/Yakym/Stutzman/Spartz/Shreve/Houchin (Houchin is "done" tier, 25 stances); MN's all 8 (all "partial" tier, 4-19 existing stances); MO's all 8 (all "partial" tier, 5-18 existing stances). Per the milestone-standing "partial-incumbent stance top-up out of scope" rule (carried forward from 154 D-02), do NOT attempt to top up any partial-tier incumbent this phase.

**Federal-24 topic count confirmed:** REQUIREMENTS.md explicitly states "federal 24-topic set" and Phase-161's precedent computed it as `44 total live topics − 11 city-only − 8 judicial-only − 1 data-centers = 24`. **Re-verify this arithmetic live at execution time** (161-RESEARCH.md's own Pitfall 5 warns the live topic count was 44 as of 2026-06-02 and "will be different by execution time" — do not assume 44 is still current for Phase 162). Scale texts live at `backend/data/stance-research/{state}-2026-house/_TOPIC_SCALE_FULL.txt` per state (existing examples: `az-2026-house/`, `ma-2026-house/`, `fl-2026-house-indep/` — clone the directory-per-state convention, e.g. `mo-2026-house/`, `mn-2026-house/`, `in-2026-house/`, `md-2026-house/`), but per Phase-161's Don't-Hand-Roll finding, build each state's file by filtering a LIVE query against `inform.compass_topics`/`compass_stances`, not by copying an old file verbatim (topic set drifts).

### 7. Fetch-wall / data-source intel

Confirmed working source URLs per state (from `160-field-table-p162.csv` and `staging/p162-{MN,MO}.csv`):

- **IN:** Two sources used across districts — `https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Indiana#District_{N}` (per-district anchor) and `https://www.thegreenpapers.com/G26/IN` (statewide). No fetch-wall issue reported for IN.
- **MD:** `https://elections.maryland.gov/elections/2026/Primary_Results/gen_results_2026_4.html` (official state results page) — used uniformly for all 8 districts. No fetch-wall issue reported.
- **MN:** `https://candidates.sos.mn.gov/CandidateFilingResults.aspx?county=0&municipality=&schooldistrict=0&hospitaldistrict=&level=1&party=0&federal=True&judicial=False&executive=False&senate=False&representative=False&title=&office=0&candidateid=0` (the exact GET-param query used uniformly for all 8 MN districts) — **this ASP.NET page DID render successfully via r.jina.ai with these exact params** (per `160-03-SUMMARY.md`); this is the canonical source URL to record even though the actual fetch route was `r.jina.ai/<this URL>`, not a direct curl.
- **MO:** `https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Missouri` (single statewide article covering all 8 districts) — **MO SoS's own ASPX candidate-filing pages are unfetchable** (render only nav boilerplate via both curl and r.jina.ai); Wikipedia's raw wikitext (which itself cites the official SoS filing list) is the working substitute. If deeper per-candidate detail is needed during stance research (beyond the field-resolution level already captured), expect the same MO SoS fetch-wall to recur — fall back to Wikipedia/Ballotpedia/news coverage per candidate, same as every other state's stance-research pattern.

### 8. Plan graph shape recommendation

Mirroring 161's 11-plan, 6-wave structure with the locked MO→MN→IN+MD ordering (D-03):

| Wave | Plan(s) | Content |
|------|---------|---------|
| 1 | 162-01 | MO correspondence audit (D-01a) — pure research artifact, no DB writes, parallel-safe with nothing else in this phase since it's the very first task |
| 2 | 162-02 | MO seed end-to-end: 2 elections (general + Polygon-Pending withheld), 8 severity-routed races, 58 new politicians, headshots. Fresh external_id collision check (FIPS 29) run here. |
| 3 | 162-03, 162-04 | MO stances, split into 2 plans for checkpoint safety (58 new + MO's partial-tier incumbents are OUT of scope, so ~58 stance targets — comparable to TN's 73-into-2-plans precedent; MO-1's Bush prioritized first per D-03a "evidenced majors first") |
| 4 | 162-05 | MN seed end-to-end: 1 election, 8 races, 35 new politicians, headshots. Fresh external_id collision check (FIPS 27). |
| 5 | 162-06 | MN stances (35 targets, single plan — comparable to AZ's 32-in-one-plan precedent, no split needed) |
| 6 | 162-07 | IN-9 flag fix (D-02, Task 1) + IN seed end-to-end: 1 election, 9 races, 12 new politicians, headshots. Fresh external_id collision check (FIPS 18). |
| 6 (parallel) | 162-08 | MD candidates-only seed onto 8 existing races: 13 new politicians + 8 incumbent race_candidates rows (all 8 zero-tier), headshots. Fresh external_id collision check (FIPS 24). |
| 7 | 162-09 | IN stances (12 new + 3 zero-tier incumbents = 15 targets) |
| 7 (parallel) | 162-10 | MD stances (13 new + 8 zero-tier incumbents = 21 targets — MD has the highest incumbent-stance ratio in this phase since all 8 are zero-tier) |
| 8 | 162-11 | 33-district mini-gate: `162-verify.sql` (clone `161-verify.sql` structurally, add MO-SEVERE assertion block analogous to TN-SEVERE) + `162-coordinate-smoke.ts` (clone `161-coordinate-smoke.ts`, 4-state positive + MO-severe negative sample) |

**Rationale for IN+MD parallel waves (6/7):** both are small, decided, low-urgency states (D-03 explicitly ranks them last and together) with no interdependency — IN's flag fix and MD's races-only reuse touch entirely disjoint tables/rows, so running them as parallel plans within the same wave is safe and matches 161's Wave 4 pattern (161-07 TN stances-part-1 + 161-08 MA seed ran in the same wave).

**This is a recommendation, not a mandate** — CONTEXT.md's Claude's Discretion section explicitly leaves exact plan count/splitting to the planner. The one hard constraint is D-03's ordering: MO end-to-end before MN end-to-end before IN/MD.

## Common Pitfalls

### Pitfall 1: MO severity classification may exceed the CONTEXT.md working assumption (MO-5, maybe MO-4/6)
**What goes wrong:** Treating MO-5 as the only (or the only-plus-2-adjacent) severe district without running the actual audit risks either under-withholding (serving wrong data) or over-withholding (needlessly hiding correct data).
**Why it happens:** TN's own audit found 5/9 severe against a working assumption of "maybe just TN-9" — redistricting severity is frequently undercounted by pre-audit intuition because "anchor changed" (rubric prong 2) catches cases a simple population-percentage estimate misses.
**How to avoid:** Run the full D-01a audit exactly like TN's — gather named-source county-reassignment reporting for all 8 MO districts, not just MO-4/5/6, before concluding the severe set. Budget audit time accordingly (161-01 took real research effort, not a rubber-stamp).
**Warning signs:** An audit that concludes "just MO-5" after checking only MO-4/5/6 and skipping MO-1/2/3/7/8 is under-scoped — TN-6 and TN-7 (rural, no a priori reason to suspect) turned out respectively severe and not-severe only after full-district review.

### Pitfall 2: IN-9 fix ordering — a race authored before the flag fix silently reuses the wrong incumbent
**What goes wrong:** If the IN general race/race_candidates migration runs before the flag-fix migration, downstream logic that derives "who is IN-9's incumbent" from `is_incumbent=true` on the existing primary race would (if such logic exists anywhere) pick one of Houchin's opponents instead of her.
**Why it happens:** D-02 exists precisely because this bug is already live in prod; any process trusting the existing flag before it's fixed inherits the error.
**How to avoid:** Sequence the fix as Task 1 of the IN seed plan (or an earlier plan), verified by re-query, BEFORE the IN general election/races/candidates migration is authored or applied. The general race's incumbent wiring should use Houchin's `politician_id` (`68568faf-...`) directly from `160-incumbent-map.csv`, not derive it from the (formerly buggy) primary race flags.
**Warning signs:** Any IN-9 general race_candidates row showing Graham/Roark/Peck/Meyer as `is_incumbent=true`, or Houchin missing/flagged false, on the NEW general race.

### Pitfall 3: MO's dual-election headshot scoping (same trap TN hit)
**What goes wrong:** A headshot script scoped by election name (the single-election-per-state assumption baked into `seed-mi-house-headshots.py`) will silently skip MO's severe-district candidates, since their `race_candidates` rows join through the withheld "Polygon Pending" election, not the general one.
**Why it happens:** Every non-redistricted state in Phase 161 (AZ/WA/MA) had exactly one election row; TN was the first exception, and MO is this phase's equivalent exception.
**How to avoid:** Clone `seed-tn-house-headshots.py`'s band-scoped-only `BANDS` entry (no election-name filter) for MO specifically; IN/MN/MD can use the simpler election-scoped pattern since they each have exactly one relevant election.
**Warning signs:** A headshot pass reporting 0% coverage attempted for MO's severe-district candidates specifically (while non-severe MO districts get normal coverage) is a sign the script is still election-scoped.

### Pitfall 4: MO-1's Bush/Bell primary rematch — do not conflate incumbent-reuse with the new-challenger record
**What goes wrong:** Wesley Bell (incumbent, D, `-29001`) and Cori Bush (new candidate, D, former incumbent Bush lost the 2024 primary to Bell and is challenging again) could be confused if a generator script naively pattern-matches "candidate previously held this seat" logic — Bush needs a genuinely NEW `essentials.politicians` record (she does not currently hold MO-1; Bell does), even though she is a nationally recognizable former member of Congress.
**Why it happens:** Bush's public profile (she IS a former U.S. Representative, just not for the current MO-1 seat under Bell) could trigger an incorrect "she must already have a politician_id, go find it" assumption.
**How to avoid:** Check whether Bush already has an `essentials.politicians` record from a PRIOR seeding phase (she represented old MO-1 2021-2025) — if a record exists from her prior tenure, REUSE it (do not create a duplicate); if not, this is a genuinely new record under this phase's external_id band. Either way, do NOT treat her as "Bell's opponent, therefore not real" — she is D-03a's top-priority "evidenced major" for MO-1 stance research.
**Warning signs:** A duplicate `full_name='Cori Bush'` row in `essentials.politicians`, or Bush completely missing from the MO-1 race_candidates wiring.

### Pitfall 5: Federal-24 topic filtering — same trap as Phase 161's Pitfall 5
**What goes wrong:** `_TOPIC_SCALE_FULL.txt` master dumps observed elsewhere in this repo contain ALL live topics (city + judicial + data-centers), not just the federal-24 subset.
**Why it happens:** The master topic-scale dump is a convenience artifact for all research tiers; nothing prevents copy-pasting the wrong subset into a House-candidate agent prompt.
**How to avoid:** Build each of the 4 new per-state `_TOPIC_SCALE_FULL.txt` files (`in-2026-house/`, `md-2026-house/`, `mn-2026-house/`, `mo-2026-house/`) by filtering a LIVE query against `inform.compass_topics`, re-deriving the federal-24 exclusion list (11 city-only + 8 judicial-only + 1 data-centers) at execution time rather than copying an old file.
**Warning signs:** An agent scoring a House candidate on `residential-zoning` or any `judicial-*` topic.

## Code Examples

### Live topic-set query, then filter to federal-24 (clone from 161-RESEARCH.md verbatim)
```sql
SELECT id, key, category FROM inform.compass_topics WHERE is_active = true ORDER BY category, key;
-- Then exclude: 11 city-only + 8 judicial-only + 1 data-centers = should leave exactly 24 for federal offices.
-- Re-verify the total count is still 44 (or note the new total) before subtracting -- do not assume 44.
```

### Live external_id collision re-check (mandatory before authoring any migration)
```sql
-- Run once per state, immediately before authoring that state's migration SQL.
-- Example for MO (fips=29):
SELECT external_id FROM essentials.politicians
WHERE external_id BETWEEN -290899 AND -290101
ORDER BY external_id;
-- Expected: 0 rows.
```

### MO correspondence audit skeleton (clone 161-tn-correspondence-audit.md's structure)
```markdown
# MO Old-vs-New Congressional Map Correspondence Audit (D-01a)
## Severity Rubric
[identical rubric text -- see Must-Answer #1 above]
## Per-District Severity Table
| geo_id | old_cd | incumbent | anchor_county_old | anchor_county_new | pct_population_moved (proxy) | severity | rationale |
[one row per MO CD 1-8]
## Severe geo_id list: [enumerated]
## Source URLs
[all fetched directly during this audit]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Single-election-per-state headshot BANDS scoping | Band-scoped-only (no election-name join) for any state with 2+ elections | Phase 161 (TN) | MO must adopt this pattern from the start, not discover it mid-phase |
| Assuming a pre-audit severity guess is close to final | Full per-district audit required regardless of intuition | Phase 161 (TN's 5/9 vs. expected ~2/9) | MO's audit should not shortcut to "just MO-5" |

**Deprecated/outdated:** None — this phase's entire methodology is < 24 hours old (Phase 161 completed 2026-07-04, same day as this research).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | MO-5 (and possibly MO-4/MO-6) will score severe under D-01a | Must-Answer #1 | LOW — this is explicitly framed as a hypothesis for the audit to test, not a locked fact; the audit itself resolves it. If wrong, the audit's own output (not this research) governs downstream withholding decisions. |
| A2 | The `160-race-preexistence-audit.csv`'s IN-9 rows' `candidate_pid` values equal the corresponding `race_candidates.id` for the 4 non-Houchin rows (per apparent CSV column layout) | Must-Answer #2 | MEDIUM — if the CSV's column semantics differ from this inference, the UPDATE's `WHERE id IN (...)` clause could target the wrong rows. **Mitigation already specified: re-verify both id sets with a live SELECT before writing the UPDATE**, do not trust the CSV positional read alone. |
| A3 | 0 collisions will be found for IN/MD/MN/MO's external_id bands (based on the legacy-scheme non-overlap analysis in Must-Answer #3) | Must-Answer #3 | LOW — this is a testable prediction, not an assumption relied upon without a fresh live check; the research explicitly mandates re-running the check regardless of this prediction. |
| A4 | Cori Bush (MO-1) may already have an `essentials.politicians` record from her 2021-2025 tenure as the prior MO-1 incumbent | Common Pitfalls #4 | MEDIUM — if a prior record exists and isn't found/reused, a duplicate `full_name` row would violate the "0 duplicate politician rows" gate assertion (USHC3-02). **Mitigation specified: check for a prior record by full_name before treating her as a new insert.** |
| A5 | The federal-24 topic count is still 24 (44 total − 11 city − 8 judicial − 1 data-centers) as of Phase-162 execution time | Must-Answer #6 | LOW — 161-RESEARCH.md itself flagged this as needing re-verification at execution time; this research inherits that caveat rather than asserting a fixed number. |

## Open Questions

1. **Will MO's audit find a severe set larger than MO-4/5/6, mirroring TN's expansion beyond its pre-audit hypothesis?**
   - What we know: TN's audit expanded from "maybe TN-9 only" to 5/9 severe once anchor-change evidence was gathered for every district.
   - What's unclear: Whether MO's redistricting was as sweeping as TN's 9-0-flip attempt, or more surgical (targeting mainly MO-5).
   - Recommendation: Budget the D-01a audit plan for full 8-district review, not a 3-district shortcut.

2. **Does Cori Bush already have a politician_id from her 2021-2025 MO-1 tenure?**
   - What we know: She was MO-1's incumbent before losing the 2024 D primary to Bell; the project has been seeding House incumbents/former-incumbents since v2.15.
   - What's unclear: Whether her prior record (if any) was created in an earlier phase and is still queryable, or whether she was never seeded because she wasn't an incumbent at any prior seeding-phase snapshot.
   - Recommendation: `SELECT id, external_id FROM essentials.politicians WHERE lower(full_name) LIKE '%bush%' AND lower(full_name) LIKE '%cori%'` before authoring the MO-1 candidates migration.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|--------------|-----------|---------|----------|
| `psql` CLI | Migration execution + verify gate | ✓ (used throughout 148-161) | system | — |
| `node --import tsx` | `.mts` generators, `_merge.ts`/`_push.ts` stance scripts | ✓ | project-pinned | — |
| Python 3 (`py`, NOT `python3`) | Headshot pipeline | ✓ (`python3` is a dead MS-Store alias; use `py`) | Python 3.14.3 | Use `py` explicitly |
| Supabase prod DB (`kxsdzaojfaibhuzmclfq`) via `backend/.env` `DATABASE_URL` (Session pooler) | All writes/reads | ✓ | — | — |
| WebFetch/Playwright for stance research | Sourcing citations | ✓ (3-concurrency cap) | — | Playwright orchestrator-run for walled sources |

**Missing dependencies with no fallback:** None identified.
**Missing dependencies with fallback:** None beyond the known `python3`→`py` substitution.

**Migration number high-water mark at research time:** `1205` (`1205_or_westmetro_school_boards_wave1_headshots.sql`, from the parallel OR/westmetro session). **Re-check live via `ls backend/migrations | sort | tail -5` immediately before authoring each migration** — a parallel session is actively climbing this number (per 161's own repeated experience of the plan's assumed number being stale).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None (no unit-test framework) — this project verifies data-seeding phases via read-only SQL assertion scripts (`psql -v ON_ERROR_STOP=1 -f <phase>-verify.sql`) and standalone TS coordinate-smoke scripts, per the 149→161 precedent. No Jest/pytest/vitest applicable. |
| Config file | none — see Wave 0 Gaps below |
| Quick run command | `cd /c/EV-Accounts/backend && set -a && source .env && set +a && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/162-verify.sql` |
| Full suite command | Same command — the gate script IS the full suite for this phase (single consolidated set of assertion blocks, per 156/158/161 precedent) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|---------------------|-------------|
| USHC3-02 | 0 duplicate politician rows per state; new/reuse split correct; IN-9 flags corrected | SQL assertion | `psql -f scripts/162-verify.sql` (dup-full_name + reuse-pid + IN9-FLAG checks, cloned from 156/161-verify.sql pattern) | ❌ Wave 0 — write `162-verify.sql` |
| USHC3-03 | 33 races exist, 0 NULL office_id, 0 NULL politician_id (active) | SQL assertion | same file, scope-count + NULLPID checks | ❌ Wave 0 |
| USHC3-03 (MO severe) | Severe MO races exist but do NOT surface via `/elections` | SQL assertion + coordinate smoke | `162-verify.sql` (MO-SEVERE block, clone TN-SEVERE) + `162-coordinate-smoke.ts` (0 races for severe-district test point) | ❌ Wave 0 — both new |
| USHC3-04 | Every new candidate has a `politician_images` row or a pinned honest-skip | SQL assertion | `162-verify.sql` (`_img_skip` pattern) | ❌ Wave 0 |
| USHC3-05 | 0 unsourced stance rows; every in-scope candidate has ≥1 sourced federal stance or a pinned whole-record skip | SQL assertion | `162-verify.sql` (`_stance_skip`/`_in_scope`/`_fed24` pattern) | ❌ Wave 0 |
| MD reuse invariant | All 8 MD incumbents + 13 new challengers wired without duplication | SQL assertion | `162-verify.sql` (exactly-1-row-per-pid-per-race check) | ❌ Wave 0 |
| IN-9 flag invariant | Race `7d3f0042-...` shows Houchin `true`, 4 opponents `false` | SQL assertion | `162-verify.sql` (IN9-FLAG block, new — no 161 precedent) | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** targeted `psql` SELECT for the specific state/district just written (idempotency + row-count spot check)
- **Per state-slice merge:** run the state-scoped subset of `162-verify.sql` assertions (or the whole file — cheap)
- **Phase gate:** Full `162-verify.sql` green + `162-coordinate-smoke.ts` (4-state positive + MO-severe negative sample) before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `backend/scripts/162-verify.sql` — clone `161-verify.sql` structurally; needs a NEW MO-SEVERE assertion block (no 161 precedent to copy line-for-line, but the TN-SEVERE block is a direct structural template) and a NEW IN9-FLAG assertion block (genuinely novel — no prior-phase equivalent)
- [ ] `backend/scripts/162-coordinate-smoke.ts` — clone `161-coordinate-smoke.ts`, extended to IN/MD/MN/MO, with a negative-result sample for at least one severe MO district
- [ ] MO correspondence audit artifact (`162-mo-correspondence-audit.md`) — D-01a deliverable, no code, produces the severity table (clone `161-tn-correspondence-audit.md`'s structure)
- [ ] Per-state `.mts` generators (`162-{mo,mn,in,md}-generate.mts`) — clone `161-{tn,az,az,ma}-generate.mts` respectively
- [ ] Per-state headshot scripts (or a single parameterized script with a `BANDS` entry per state) — clone `seed-{tn,mi,mi,ma}-house-headshots.py` respectively (MO needs the band-scoped-only variant per Pitfall 3)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|--------------------|
| V2 Authentication | No | No auth surface changed — pure data phase |
| V3 Session Management | No | Not applicable |
| V4 Access Control | No | Writes happen via `pool.query()` with the service-role `DATABASE_URL`, never via a public-facing route; RLS unaffected |
| V5 Input Validation | Partial | Migration SQL generators must escape free-text fields (candidate names, source URLs) via the `sqlStr()`-style helper established in `159-mi-generate.mts` — carry forward for all 4 new generators |
| V6 Cryptography | No | Not applicable |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|-----------------------|
| SQL injection via unescaped candidate names in generated migration SQL | Tampering | Use the `sqlStr()` quote-escaping helper for every free-text field — never raw string interpolation |
| A "seeded but withheld" MO race accidentally surfacing due to a future unrelated migration touching `election_type` | Tampering / Repudiation | Re-run the `162-verify.sql` MO-non-surfacing assertion as part of every subsequent phase's gate that touches MO data (166's consolidated gate, and Phase 164.1's polygon-refresh phase) — document this dependency in the phase's SUMMARY |
| IN-9 flag-fix silently reverted by a future unrelated migration re-seeding the primary race | Tampering | The IN9-FLAG assertion in `162-verify.sql` should be re-run by Phase 166's consolidated gate as a standing invariant, same as 161's TN-SEVERE inheritance requirement |

This phase has an unusually small security surface (no new code, no new auth/access paths) — the primary concern is data-integrity (the MO withholding mechanism and the IN-9 flag fix must not silently regress), covered under Validation Architecture above.

## Sources

### Primary (HIGH confidence)
- `.planning/phases/162-in-md-mn-mo-candidate-seeding-create-elections-races-then-ca/162-CONTEXT.md` — locked decisions, all facts directly authoritative
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-field-table-p162.csv` — the 33-row field table (all per-state/per-district facts quoted verbatim above)
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-race-preexistence-audit.csv` — MD's 8 existing_race_id values + IN-9 bug rows
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-incumbent-map.csv` — incumbent pid/external_id/tier map
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-negative-id-audit.csv` — confirmed 0 rows for IN/MD/MN/MO
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-03-SUMMARY.md` — IN/MD/MN/MO field-resolution provenance, MO/MN fetch-wall intel
- `.planning/phases/161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca/161-tn-correspondence-audit.md` — the exact severity rubric cloned above
- `.planning/phases/161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca/161-06-SUMMARY.md` — the exact D-01b withholding mechanism implementation
- `.planning/phases/161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca/161-08-SUMMARY.md` — the MA reuse pattern (MD template)
- `.planning/phases/161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca/161-11-SUMMARY.md` — the mini-gate assertion set and coordinate-smoke pattern
- `.planning/phases/161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca/161-RESEARCH.md` — Code Examples/Pitfalls/Validation Architecture templates cloned structurally above
- `backend/migrations/1196_seed_tn_2026_house_elections_races.sql`, `1197_...`, `1202_seed_ma_2026_house_candidates.sql`, `1187/1188_seed_az_2026_house_*.sql` — direct migration templates (read by file listing; exact SQL bodies referenced by the 161-RESEARCH.md Code Examples section, not independently re-read line-by-line in this session)
- `.planning/STATE.md` §"v2.22 Execution Methodology" — FIPS table, standing pipeline rules
- `.planning/ROADMAP.md` §Phase 162/161/164.1 — goal + success criteria

### Secondary (MEDIUM confidence)
- MO redistricting severity predictions (MO-5 primary target, MO-4/6 adjacency) — sourced from CONTEXT.md's Specific Ideas, itself derived from Phase-160's field-resolution research; not independently re-verified against fresh news sources in this research session (that verification is D-01a's job, to run at execution time with then-current sources)

### Tertiary (LOW confidence)
- None — this research relied entirely on already-authoritative, already-executed-once project artifacts (Phase 160/161 outputs) rather than external web research, since the phase's methodology is fully locked and precedented.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new tools, 100% reuse of Phase-161's proven pipeline
- Architecture: HIGH — every pattern (elections+races authoring, races-only reuse, severity-routed withholding, external_id assignment) has a working, gate-verified precedent completed 2026-07-04
- MO severity classification: MEDIUM — the rubric and mechanism are HIGH-confidence (proven verbatim on TN), but the actual severe-district SET for MO is unresolved until the phase's own D-01a audit runs (same posture 161-RESEARCH.md had for TN before 161-01 executed)
- IN-9 fix: MEDIUM-HIGH — the bug and the target rows are confirmed from a committed audit CSV; the exact `race_candidates.id` vs `candidate_pid` column correspondence should get one live-SELECT re-verification before the UPDATE is authored (flagged in Assumptions Log A2)
- Pitfalls: HIGH — every pitfall listed either directly recurs from Phase 161's own documented incidents (dual-election headshot scoping, severity-audit under-scoping) or is a straightforward, well-specified new risk (IN-9 ordering, Bush/Bell record confusion)

**Research date:** 2026-07-04
**Valid until:** 14 days (this is an active, fast-moving multi-phase milestone with a parallel session also modifying `backend/migrations/`; the migration high-water mark and any DB state facts should be re-verified at plan/execution time regardless of this window)
