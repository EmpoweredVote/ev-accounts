# Architecture Research

**Domain:** 2026 US House candidate surfacing — "type address → see House race in /elections"
**Researched:** 2026-06-27
**Confidence:** HIGH (traced live code file:line + inspected production schema and data)

---

## TL;DR — the definitive answer

**v2.20 is PURE DATA. No code change is required to surface a House race on /elections.** The `races → offices → districts → geofence` join in `getElectionsByCoordinate` already matches US House races to a resident's address by coordinate, and the CA scaffolding (all 53 district `races` rows linked to incumbent offices) is **already seeded**. What is missing is only `essentials.race_candidates` rows.

- **PATH B (`/elections`) is the canonical path for House races.** It is the only path that surfaces on the Elections page.
- **PATH A (candidacy offices) does NOT appear on /elections — proven, not assumed.** All 27 `Candidate for U.S. Senate — <State>` offices have **0** matching `race_candidates` rows and **0** `races` referencing them (live query below). They surface only in the representatives feed.
- **CA Wave-1 work = insert `race_candidates` only** (races + offices + geofences already exist).
- **TX / FL / NY Wave-1 work = create the `races` rows first, then insert `race_candidates`** (their US House races are not yet seeded).

---

## The two paths, resolved with evidence

### PATH A — Representatives feed (`getRepresentativesByAddress`, `essentialsService.ts`)

A candidate surfaces as an `essentials.offices` row (e.g. `Candidate for U.S. Senate — Louisiana`) linked to the state's US-Senate district, filtered by `p.is_active = true`. The query joins `geofence_boundaries → districts → offices → politicians` and never touches `races`/`race_candidates`:

- `essentialsService.ts:651` `JOIN essentials.offices o ON o.district_id = d.id`
- `essentialsService.ts:664` `AND (p.is_active = true OR o.is_vacant = true)`

Migration 042 explicitly forbids `race_candidates` from this path:
> `042_election_schema.sql:160` — "WARNING: race_candidates must NEVER be joined into the geofence search path (getRepresentativesByAddress)."

### PATH B — Elections page `/elections` (`getElectionsByCoordinate`, `electionService.ts`)

`GET /api/essentials/elections?lat=&lng=` (`essentials.ts:109`) and `/elections-by-address` (`essentials.ts:140`) both call `getElectionsByCoordinate`, which builds elections→races→candidates strictly from the three migration-042 tables. The district-matched query (`electionService.ts:284-303`):

```
FROM essentials.elections e
JOIN essentials.races r ON r.election_id = e.id
LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id     -- candidates
JOIN essentials.offices o ON o.id = r.office_id                  -- race→office
JOIN essentials.districts d ON d.id = o.district_id              -- office→district
JOIN essentials.geofence_boundaries gb                          -- district→polygon
  ON gb.geo_id = d.geo_id AND (d.mtfcc IS NULL OR d.mtfcc='' OR gb.mtfcc = d.mtfcc)
WHERE gb.geometry IS NOT NULL
  AND public.ST_Covers(gb.geometry, ST_MakePoint($lng,$lat))     -- coordinate match
  AND <ELECTION_VISIBILITY_WINDOW>
```

**This is how a House race matches a resident's district:** by `office.district_id → districts.geo_id` + PostGIS `ST_Covers` of the geofence polygon. No `geo_id` on the race itself; the race inherits geography through its `office_id`.

#### Proof that Path A is invisible to /elections (live production query)

```
=== Candidacy offices (Path A) titled 'Candidate for U.S. ...' ===
"Candidate for U.S. Senate — Louisiana"   offices: 4   matching_race_candidate_rows: 0
"Candidate for U.S. Senate — Michigan"    offices: 4   matching_race_candidate_rows: 0
... (all 27 rows) ... matching_race_candidate_rows: 0

=== Path A offices: races referencing their office_id ===
"Candidate for U.S. Senate — Alabama"  NATIONAL_UPPER  geo_id 01  races_on_this_office: 0
... (every row) ... races_on_this_office: 0
```

The LA Senate Path-A candidates had **zero** `race_candidates` rows and **zero** `races` on their offices → they appeared **only in the representatives feed, never on /elections.** Item 2 is settled.

---

## Required rows to make a 2026 US House race appear on /elections

Joining backward from `getElectionsByCoordinate`, a race surfaces when this full chain exists AND the election passes the visibility window:

| # | Table | Required row | Notes |
|---|-------|--------------|-------|
| 1 | `essentials.elections` | 1 per state per election event | e.g. "CA 2026 Statewide General", `election_type='general'`, `state='CA'`, `election_date='2026-11-03'`. **Already exists for CA.** |
| 2 | `essentials.offices` | the district's `U.S. Representative` office | **Already exists for all 435 districts** (v2.15, holds the sitting incumbent). Reuse it — do NOT create a new office. |
| 3 | `essentials.districts` | `NATIONAL_LOWER` row, `geo_id`=`SSCC` (e.g. `0612`), `mtfcc='G5200'` | **Already exists (all 435, TIGER-geofenced).** |
| 4 | `essentials.geofence_boundaries` | polygon for `(geo_id, 'G5200')` | **Already exists.** Confirmed CA-12 (`0612`,`G5200`) `has_geom=true`. |
| 5 | `essentials.races` | 1 per district, `office_id`→the district's House office, `election_id`→#1, `position_name` e.g. `'U.S. Representative District 12'` | **Exists for all 53 CA.** **MISSING for TX/FL/NY** — must be created. |
| 6 | `essentials.race_candidates` | 1 per candidate, `race_id`→#5, `politician_id`→record (incumbent or seeded challenger), `full_name`, `is_incumbent`, `candidate_status='active'` | **THE CORE MISSING DATA — 0 candidates in 52/53 CA House races, 0 for TX/FL/NY.** |

### Visibility window (must pass — `electionService.ts:24-27`)
```
(election_type != 'general' AND election_date >= CURRENT_DATE - 30 days)
OR (election_type = 'general' AND election_date >= DATE_TRUNC('year', CURRENT_DATE))
```
The Nov-3-2026 general elections satisfy this for all of 2026. ✓

### `race_candidates` exact insert shape (live schema — note 2 cols beyond migration 042)
`id (default), race_id, politician_id (nullable), full_name (NOT NULL), first_name, last_name, photo_url, is_incumbent (default false), candidate_status (default 'active' CHECK active|withdrawn|filed), last_verified_at, source, external_id, occupational_designation, website_url`

The model: link `politician_id` to the politician record (incumbents + seeded challengers both have records here per the project's seed convention). Photos/stances flow automatically through `politician_id` — the feed's `PHOTO_LATERAL` (`electionService.ts:48`) does `COALESCE(rc.photo_url, pi.url)` against `politician_images`.

---

## Production state of the target data (live inventory, 2026-06-27)

```
Wave-1 US House race coverage by state FIPS:
  06 (CA): house_races 53   candidates 6     ← races seeded, candidates ~0
  48 (TX): (none)                            ← NO races seeded
  12 (FL): (none)                            ← NO races seeded
  36 (NY): (none)                            ← NO races seeded

CA-53 House races: office_has_holder=true for ALL 53  (race.office_id = the incumbent's office)
CA-12 example: race "U.S. Representative District 12" → office U.S. Representative
               → holder Lateefah Simon (is_incumbent, is_active) → district geo_id 0612 / G5200 (geofenced)
```

So the CA scaffolding is a turnkey target: every district race already points at the incumbent's office. Seeding the incumbent + challengers as `race_candidates` on the existing race rows is all CA needs.

Existing `race_candidates` model rows (Utah/Indiana US House) confirm the convention: each row carries `politician_id`, `full_name`, `is_incumbent`, `candidate_status='active'`, `source` (`sos_excel`/`sos_filing`).

---

## Empty state: "district resolves but race not seeded at all"

**This is NOT in this repo and is NOT a backend code change.** The backend contract is invariant: `getElectionsByCoordinate` returns an array; when no race chain matches, `groupElectionRows([])` returns `[]` (`electionGrouping.ts:144`), and the route responds `200 { elections: [] }` (`essentials.ts:120`; test contract `tests/integration/essentials-elections.test.ts`). There is no "no elections" branch in the backend — the empty-state message is rendered by the **Essentials frontend** (separate repo at `C:\Transparent Motivations\essentials`, consumes the API; see MEMORY `reference_essentials_frontend_deploy`). v2.20 therefore needs no empty-state work in this repo. If a "no race for your district yet" message is desired, that is a one-line Essentials-app change, out of this milestone's scope.

---

## Recommended build order (per Wave-1 state)

```
[Resident address]
   ↓ Census geocode (lat,lng)        — already live
[ST_Covers geofence polygon]         — already live, all 435 districts
   ↓ districts.geo_id (06NN, G5200)
[essentials.races]  ← office_id → incumbent's U.S. Representative office
   ↓
[essentials.race_candidates]  ← incumbent + challengers (politician_id)
   ↓ PHOTO_LATERAL + stances via politician_id
[/elections response]
```

1. **Candidate records first (the real work).** For each Nov-3 general-ballot candidate not already in `essentials.politicians`: seed politician + headshot + federal-24-topic chairs-not-polarity stances (existing pipeline). Sitting incumbents already exist + are stanced (v2.15–v2.17); a stance-gap diagnostic at plan time surfaces any incumbent below threshold.
2. **CA — insert `race_candidates` only.** Reuse `scripts/ingest-ca-sos-2026-challengers.ts` as the template (find race by `position_name` → insert candidates, idempotent on name collision). The 53 race rows + offices + geofences already exist. Seed the incumbent as `is_incumbent=true` + challengers as `is_incumbent=false` on each existing race.
3. **TX / FL / NY — create `races` first, then `race_candidates`.** One `races` row per district (`office_id` = that district's existing `U.S. Representative` office, `election_id` = the state's general election — create the `elections` row if absent, mirroring "CA 2026 Statewide General"), then insert candidates. `importElectionData.ts` / `seed-la-county-2026-primary-state-federal.sql` are the working precedents.
4. **Verify by coordinate.** For each Wave-1 state, run `getElectionsByCoordinate(lat,lng)` (or curl `/api/essentials/elections-by-address`) for a known address in a seeded district; assert the House race + candidates + headshots come back. This is the existing v2.6 ELEC-01 Playwright-style verification pattern.
5. **Re-check post-primary.** Most CA/TX/NY primaries are done; FL primary is Aug 18 — seed the known field now, re-confirm nominees after (the operator's "seed the upcoming-vote field now, don't guess the general winner" rule from the Senate track).

---

## Integration Points

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Census Geocoder → backend | HTTP, lng/lat | already live; `$1=lng, $2=lat` PostGIS order |
| geofence ↔ race | `office.district_id → districts.geo_id` + `ST_Covers` | race has NO geo_id of its own — geography is inherited via `office_id`. A race seeded with `office_id IS NULL` would be treated as **statewide** (`fetchStatewideRaceRows`, `electionService.ts:106-128`) and would NOT geo-match a district — so House races MUST carry `office_id`. |
| candidate → photo/stances | `race_candidates.politician_id` | `COALESCE(rc.photo_url, politician_images.url)`; stances served by separate compass endpoints keyed on `politician_id`. Always link the record, don't denormalize. |
| Essentials frontend ↔ API | `GET /api/essentials/elections[-by-address]` | empty-state UI lives there; backend always returns `{elections:[]}`. |

---

## Anti-Patterns (specific to this milestone)

### AP-1: Seeding House candidates via Path-A candidacy offices
**What people do:** Copy the Senate model — make a `Candidate for U.S. House — <State> <N>` office.
**Why it's wrong:** Proven invisible to /elections (0 races, 0 race_candidates on every Path-A office). It would only show in the representatives feed, which is not the v2.20 goal.
**Do this instead:** Seed `race_candidates` rows on the district race (Path B).

### AP-2: Seeding a House race with `office_id IS NULL`
**What people do:** Create a `races` row without linking the office.
**Why it's wrong:** `office_id IS NULL` is the *statewide* convention (`electionService.ts:118-121`); the race would match every resident of the state, not the specific district, and would be mis-classified as a statewide race.
**Do this instead:** Always set `races.office_id` to the district's existing `U.S. Representative` office.

### AP-3: Creating a duplicate office/politician for an incumbent running again
**What people do:** Make a new politician/office record for the sitting rep as a "candidate."
**Why it's wrong:** v2.4 made duplicate records (two "Andy Barr"); breaks the feed and stance attribution.
**Do this instead:** Reuse the existing politician record; add a `race_candidates` row with `is_incumbent=true` pointing at it.

---

## Sources

- `backend/src/lib/electionService.ts:24-330` (HIGH — `getElectionsByCoordinate` race→office→district→geofence join; visibility window; statewide vs district branch)
- `backend/src/lib/electionGrouping.ts:133-204` (HIGH — empty-array grouping, district_type inference)
- `backend/src/lib/essentialsService.ts:51-62, 576-735` (HIGH — representatives feed is_active filter; UPCOMING_ELECTIONS_LATERAL)
- `backend/src/lib/geoIdGuard.ts:15-28` (HIGH — MTFCC→district_type guard, `G5200`→`NATIONAL_LOWER`)
- `backend/src/routes/essentials.ts:109-160` (HIGH — `/elections` + `/elections-by-address` handlers; always `{elections:[]}`)
- `backend/migrations/042_election_schema.sql` (HIGH — elections/races/race_candidates schema + the "never join race_candidates into geofence path" warning)
- Live production DB inspection 2026-06-27 (HIGH — 53 CA House races seeded w/ 0 candidates; TX/FL/NY absent; 27 Path-A offices w/ 0 race_candidates & 0 races; CA-12 geofence present; race_candidates 16-col schema)
- `backend/scripts/ingest-ca-sos-2026-challengers.ts` (HIGH — canonical race_candidates seed pattern)
- MEMORY `project_2026_senate_coverage.md` (HIGH — Path-A model description, confirmed against live data)

---
*Architecture research for: 2026 US House candidate surfacing (v2.20)*
*Researched: 2026-06-27*
