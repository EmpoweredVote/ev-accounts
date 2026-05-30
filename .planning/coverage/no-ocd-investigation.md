# Investigation: active politicians with no usable `ocd_id`

**Date:** 2026-05-30
**Context:** While building the multi-state coverage tracker, the coverage join
(`essentials.politicians → offices.district_id → districts.ocd_id`) silently skips any politician
whose district has no `ocd_id`. A spot-check flagged "444" such records; this is the full diagnosis.

## Headline

Of **4,776 active politicians, only 2,398 (50.2%) have a usable `ocd_id`.** The other **2,378 are
invisible to the coverage tracker.** They fall into three distinct buckets, which pull coverage
numbers in *opposite* directions — candidates inflate "active" totals while real officials are
undercounted.

| Bucket | Count | What it is | Direction |
|--------|------:|------------|-----------|
| 1. No office at all | **1,042** | Mostly **candidates / manually-entered people** | Over-counts "active" |
| 2. Office but `district_id` is NULL | **892** | Real officials never linked to a district | Under-counts coverage |
| 3. District exists but `ocd_id` is NULL/'' | **444** | Real officials, **backfillable** (all have `geo_id`) | Under-counts coverage |

(1,042 + 892 + 444 = 2,378 ✓)

---

## Bucket 1 — No office at all (1,042): the candidate-pollution problem

These have **no `offices` row**. Breakdown:
- **222** linked to `essentials.race_candidates` → declared candidates.
- **510** flagged `is_incumbent`, in no race, no office — of which **499 are `data_source = 'manual'`**
  (only 2 campaign URLs). Ambiguous: either real incumbents entered without an office row, or
  candidates mis-flagged. **Needs human triage.**
- **310** neither incumbent nor candidate.

Source signal is decisive for most: campaign sites (`kimforla.com`, `lamayor2026.org`,
`mckinney4la.com`…), `LACBA 2026 JEEC Ratings`, `IN_MONROE_COUNTY_CFA4_2026`, plus a bulk `manual`
batch created 2026-05-22 (LA-area 2026 candidates like Maria Lou Calanche).

**Conclusion:** `essentials.politicians` is mixing **declared candidates** into the active-officeholder
set — the known [candidates-vs-politicians](../../memory/project_candidates_vs_politicians.md) issue,
now quantified. These inflate every coverage count (e.g. a chunk of UT's "414 active").

## Bucket 2 — Office, but no district (892): missing district linkage

`offices` rows exist with real titles but `district_id IS NULL`:

| Position | n | | Position | n |
|----------|--:|-|----------|--:|
| Indiana Elected Official (generic import) | 305 | | U.S. Representative | 82 |
| State Representative | 232 | | Mayor | 20 |
| Council Member | 112 | | Governor | 10 |
| State Senator | 102 | | Secretary of State | 10 |

These are **real officials** whose office was never geocoded to a district. The 305 "Indiana Elected
Official" rows are a generic bulk import; the State Rep/Senator/US Rep rows may overlap/duplicate the
properly-loaded legislators or come from states we haven't OCD-linked. **Needs dedup + linkage triage.**

## Bucket 3 — District exists, no `ocd_id` (444): the clean backfill target

All 444 have a `district_id`. By type: **LOCAL 198**, **U.S. Senate (NATIONAL_UPPER) 139**, SCHOOL 29,
**Governor/STATE_EXEC 26**, Mayor 21, COUNTY 19, federal judiciary 9, JUDICIAL 2, NATIONAL_LOWER 1.

**Backfill feasibility is high — every district has a `geo_id`, 432/444 have `office.representing_state`:**

| Type | Signal available | Synthesizable `ocd_id`? |
|------|------------------|--------------------------|
| U.S. Senate (139) | `geo_id`=state FIPS, `representing_state`=2-letter | ✅ `…/state:<xx>` (exact) — trivial |
| Governor/State exec (26) | same | ✅ `…/state:<xx>` (exact) |
| LOCAL (198) | `geo_id` → matches a `geofence_boundaries` row (198/198) | ✅ from geofence name → place slug |
| LOCAL_EXEC mayors (21) | `geo_id` resolves (21/21) | ✅ |
| SCHOOL (29) | `geo_id` resolves (25/29) | ✅ for 25; 4 need a source |
| COUNTY (19) | `geo_id` resolves only 4/19 | ⚠️ weak — needs county FIPS→OCD map |
| Federal judiciary (9) | n/a (courts aren't OCD-geographic) | ❌ special-case / skip |

The single highest-value fix: **U.S. Senate.** 143 senators exist, only 4 have a usable OCD — 48
states' senators are invisible purely for lack of an `ocd_id`.

---

## Plan A — Candidates belong in a separate "Elections Coverage" view (NOT officeholder coverage)

**Decided 2026-05-30:** officeholder coverage does **not** need candidate cleanup. Verified that the
coverage join already excludes pure candidates: of the 2,398 counted politicians, only 133 are also in
`race_candidates`, and **all 133 are incumbents** (sitting officials running again — correctly counted).
**Zero pure-candidate leakage.** So no `politician_status` model is required for coverage accuracy.

Instead, candidates — which exist *only for elections* — get their **own coverage section**, distinct
from the officeholder tracker:

- **Source:** `essentials.elections` → `races` → `race_candidates` (already populated by the
  `research-utah-elections` skill and discovery runs).
- **Metrics per race / jurisdiction:** races defined for the upcoming election, candidates loaded per
  race (vs expected field), candidate headshots, **candidate stances researched**, source-verified.
- **Surface:** a second tab/section on the admin coverage page (or a sibling `elections` YAML), so
  "election readiness" is tracked separately from "do we have the sitting officials."
- The ambiguous **499 `manual` `is_incumbent` no-office** records still need a one-time triage
  (real incumbents missing an `offices` row vs mis-entered candidates), but that's data hygiene, not a
  blocker for either coverage view.

**Deliverable (when prioritized):** a SPEC for the elections-coverage section. Independent of Plan B.

## ✅ Plan B — statewide tier APPLIED 2026-05-30

Ran `scripts/backfill-district-ocd.ts --type {national_upper,state_exec,local_exec} --write` —
**78 districts / 186 officials** updated (all previously NULL `ocd_id`):
- NATIONAL_UPPER: 48 districts → `…/state:xx` (US Senate now **143/143** with ocd, was 4)
- STATE_EXEC: 22 → `…/state:xx` (governors / constitutional officers)
- LOCAL_EXEC: 8 → `…/place:slug` (CA mayors)

Overall active-with-ocd: 2,398 → **2,584**. Regenerated ca/in/tx/ma/me/or YAMLs + re-synced;
"Statewide offices" rows now appear (TX 8, ME 7, OR 8, CA 20, IN 30) and UT's rollup picked up its execs
(414→421). Address search unaffected (geo_id unchanged; it never reads ocd_id). **Revert log:**
`.planning/coverage/backfill-log-2026-05-30.json` (78 district ids; revert = set ocd_id NULL).

**Also:** the "Statewide offices" row lumps Gov + US Senate + officers (expected_seats null); could split US
Senate into its own row (expected 2). And duplicate senator records (MI shows 6) inflate some counts —
dedup is separate.

## ✅ Plan B — deferred LOCAL/SCHOOL/COUNTY tiers APPLIED 2026-05-30

Refined the synthesis rules in `scripts/backfill-district-ocd.ts` and ran `--write` (all deferred types) —
**157 districts / 246 officials** updated (all previously NULL `ocd_id`):
- **LOCAL: 110** — 48 bare `…/place:slug` (G4110 at-large cities: Long Beach, Pasadena, Cambridge, ME
  cities…) + **62 ward-aware** `…/place:slug/ward:N`. Ward place comes from the geo_id slug prefix
  (`sf`→san_francisco, `sd`→san_diego, `sj`→san_jose, `portland-or`→portland; berkeley/fremont/sacramento
  literal) or the X-layer geofence name (Bloomington). Covers SF 1-11, SD 1-9, SJ 1-10, Sacramento 1-8,
  Berkeley 1-8, Fremont 1-6, Portland-OR 1-4, Bloomington 1-6.
- **SCHOOL: 28** — parent-LEA rollup. LAUSD `board_district_N` (generic "Board District N" geofence) →
  `school_district:los_angeles_unified` via alias; IN `MCCSC N` → `mccsc`; IPS sub-geos with no own
  geofence → 7-digit parent lookup → `indianapolis_public_schools`; Martinsville/RBBCSC/Eminence direct.
  Board-subdistricts roll up to the parent district (never a per-seat division).
- **COUNTY: 19** — 10-digit geo_id = state2+county3+seq5; FIPS-5 → county name (G4020 geofence first,
  then a 6-county IN `COUNTY_FIPS_NAME` table since `geofence_boundaries` has no IN G4020 rows). Seats
  roll up to `…/county:slug` (Greene, Jackson, Lawrence, Marion, Monroe, Morgan).
- **Skipped (correct):** 2 JUDICIAL, 1 NATIONAL_JUDICIAL, 1 NATIONAL_LOWER — no OCD geography.

Ward divisions roll up to their parent `place:` row under coverage's subtree matcher, so e.g. SF's 11
supervisors all count under the existing `place:san_francisco` location (now `populated: true`,
stances total 20). Regenerated ca/in/me/ma/or YAMLs (+restored hand-curated `treasury` values: ca 92,
in 5) and re-synced ca/in/me/ma/or/ut. `getCoverage('ca')` → 181 locations all populated (1057 rostered);
`getCoverage('in')` → 37 (423 rostered). Address search unaffected (geo_id untouched; spot-checked SF
supervisor / Monroe county / LAUSD board / Long Beach still join their geofence). **Revert log:**
`.planning/coverage/backfill-log-deferred-tiers-2026-05-30.json` (157 district ids; revert = set ocd_id NULL).

**Remaining out of scope:** Bucket-1 (1,042 no-office candidates) and Bucket-2 (892 office-without-district)
are separate triage tasks, untouched here.

## Plan B (original) — Backfill `ocd_id` on Bucket-3 districts (migration, review before run)

**Goal:** make the 444 real officials visible in coverage by synthesizing `ocd_id` from data already
present. Idempotent, reversible, staged.

**Synthesis rules (by `district_type`):**
- **NATIONAL_UPPER, STATE_EXEC** → `ocd-division/country:us/state:<xx>` where `<xx> =
  lower(representing_state)` (fallback: FIPS `d.geo_id` → abbr). Set `match: exact` semantics. ~165 rows.
- **LOCAL, LOCAL_EXEC** → join `d.geo_id = geofence_boundaries.geo_id`, take the place name → slug,
  build `…/state:<xx>/place:<slug>`. ~219 rows (geo_id resolves 100%).
- **SCHOOL** → same via geofence name → `…/school_district:<slug>` for the 25 that resolve; flag 4.
- **COUNTY (19)** → only 4 resolve via geofence; build a county-FIPS → OCD map for the rest (or defer).
- **NATIONAL_JUDICIAL / JUDICIAL (11)** → out of scope (no OCD geography); leave as-is.

**Approach:**
1. Write `scripts/backfill-district-ocd.ts --dry-run` that prints proposed `(district_id, old, new)`
   per type with a per-type count, **writing nothing**.
2. Review the dry-run diff (especially the place/school slug derivations and any collisions).
3. Run per-type with `--type national_upper` first (lowest risk, highest value), verify the coverage
   tracker now shows e.g. a "U.S. Senate" presence, then proceed to locals.
4. Re-run `coverage-sync` / regenerate affected state YAMLs; the new officials appear automatically.

**Risks / guards:**
- Don't overwrite an existing valid `ocd_id` (only touch NULL/'' ).
- `representing_state` case is inconsistent (`CA` vs `me` vs FIPS `06`) — normalize to lowercase
  2-letter via a FIPS↔abbr map; assert every row resolves before writing.
- Statewide-office rows use `match: exact` in coverage, so a bare `…/state:<xx>` won't double-count
  under the chamber/subtree matchers.
- All changes scoped to `essentials.districts.ocd_id`; fully reversible (capture old values in the
  dry-run output / a backup table).

---

## Reproduction (key SQL)

```sql
-- The three buckets
SELECT count(*) FROM essentials.politicians WHERE is_active;                       -- 4776
-- with usable ocd:
SELECT count(DISTINCT p.id) FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id=p.id
  JOIN essentials.districts d ON d.id=o.district_id
  WHERE p.is_active AND d.ocd_id LIKE 'ocd-division/%';                            -- 2398
-- bucket 3 (district, no ocd) by type:
SELECT d.district_type, count(DISTINCT p.id)
  FROM essentials.politicians p JOIN essentials.offices o ON o.politician_id=p.id
  JOIN essentials.districts d ON d.id=o.district_id
  WHERE p.is_active AND (d.ocd_id IS NULL OR d.ocd_id NOT LIKE 'ocd-division/%')
  GROUP BY 1 ORDER BY 2 DESC;
```

## Open questions for the team
1. Are the **499 `manual` `is_incumbent` no-office** records real incumbents (→ create offices) or
   candidates (→ reclassify)? Decides Bucket-1 handling.
2. Do the Bucket-2 **State Rep/Senator/US Rep without districts** duplicate the OCD-linked legislators,
   or are they separate (un-geocoded) imports? Decides whether to link or dedup.
3. County OCD backfill: build a county-FIPS→OCD map now, or defer the 15 unresolved counties?
