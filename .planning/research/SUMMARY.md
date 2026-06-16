# v2.15 Research Summary — National House Rep Seeding (Tier 1)

**Scope:** Seed the ~298 missing US House politician + office records, FK-linked to the
existing `NATIONAL_LOWER` congressional districts (all already have `tiger_geoid`). Geofencing
infra is complete (Phase 116/v2.11); this milestone fills the rep layer only. Stances = Tier 2 (v2.16+).

## Current DB State (production `kxsdzaojfaibhuzmclfq`, 2026-06-16)

- `essentials.geo_districts` `layer='us_house'`: 436 polygons ✓
- `essentials.districts` `NATIONAL_LOWER`: 440 rows, **all 440 have `tiger_geoid`** ✓
- House reps linked: **137 / 435** (only 10 states seeded)
- Senate: fully covered (50 `NATIONAL_UPPER`, 143 politicians) — out of scope
- **States with 0 House reps (~40):** AL, AK, AZ, AR, CO, CT, DE, FL(28), GA(14), HI, ID, IL(17),
  IA, KS, KY, LA, MI(13), MN, MS, MO, MT, NE, NV, NH, NJ(12), NM, NY(26), NC(14), ND, OH(15),
  OK, PA(17), RI, SC, SD, TN, WA(10), WV, WI, plus partials IN(4/9) and TX(37/38).

## Data Source: unitedstates/congress-legislators

- File: `legislators-current.yaml` (raw: `https://raw.githubusercontent.com/unitedstates/congress-legislators/main/legislators-current.yaml`)
- **NOT yet fetched anywhere in the codebase** — FEC scripts only reference it in comments. The ingestion script downloads it fresh.
- Schema (verified from repo README):
  - `id.bioguide` — stable primary key (alphanumeric, e.g. `W000804`)
  - `name.first`, `name.last`, `name.official_full` (full name per House/Senate; present for all current members)
  - `terms[]` — **last entry is the current term**. Fields: `type` (`'rep'` = House incl. delegates, `'sen'` = Senate), `state` (2-letter USPS), `district` (number; **`0` = at-large**, `-1` = unknown), `party` (`'Democrat'`/`'Republican'`/`'Independent'`)

## tiger_geoid Mapping (verified)

`tiger_geoid = STATE_FIPS(2) + CD(2, zero-padded)`:
- Multi-district: NY-1=`3601`, TX-1=`4801`
- **At-large (`district: 0`): suffix `00`** — AK=`0200`, DE=`1000`, ND=`3800`, SD=`4600`, VT=`5000`, WY=`5600`
- `geo_id` == `tiger_geoid` for `NATIONAL_LOWER`; join the ingest on `tiger_geoid` (Path 0 canonical pattern, dual-key `(tiger_geoid, district_type)`).

## Insert Pattern (from migration 311 — VA federal officials, reuse verbatim)

- **Shared US House chamber UUID** (reuse, never create): `c2facc31-7b13-428c-b7b9-32d0d3b95f76`
- `essentials.politicians`: `full_name, first_name, last_name, party, is_active=true, is_appointed=false, is_vacant=false, is_incumbent=true, external_id`
- `essentials.offices`: `district_id, chamber_id=<US House>, politician_id, title='U.S. Representative', representing_state=<2-letter>, is_appointed_position=false, is_vacant=false, role_canonical=NULL`
- Backfill `politicians.office_id` after office insert.
- Idempotency: `ON CONFLICT (external_id) DO NOTHING` + `NOT EXISTS (district_id, chamber_id)` guard.

## Key Decisions / Gotchas (carry into PLAN)

1. **party normalization**: YAML `'Democrat'` → DB `'Democratic'` (v2.6 SACC-03 normalized 775 rows; do NOT reintroduce `'Democrat'`). `'Republican'`/`'Independent'` pass through.
2. **Delegates share `type='rep'`**: filter to the 50 states + DC delegate only; skip PR/GU/VI/AS/MP (no `NATIONAL_LOWER` district rows). DC has 3 district rows (delegate + 2 shadow reps) — seed the delegate, leave shadow rows unseeded.
3. **Process only unseeded districts**: `LEFT JOIN offices ... WHERE politician_id IS NULL` so the 137 already-linked reps (CA/TX partial/VA/MA/MD/OR/UT/ME/IN partial/DC) are never touched and no orphan politicians are created.
4. **external_id scheme**: `-(state_fips*1000 + cd)` (at-large cd=0). Range -1000..-56999, **0 collisions** confirmed against existing 3,354 negative external_ids.
5. **Vacancy-robust verify gate**: assert every YAML-listed current House rep (50 states + DC) is linked; expect linked count = 435 − live vacancies + DC delegate. Do NOT hard-assert 435.
6. **Headshots**: `find-headshots` skill after seeding (politicians.photo_origin_url starts NULL).
7. **Name**: `full_name` = `official_full` (fallback to `first + last`); `first_name`/`last_name` from `name.first`/`name.last`.

## Recommended phase split (continues from Phase 124)

- **Phase 125** — National House Rep Ingestion: build fetch+seed script (or generated migration), FK-link all ~298 unseeded districts. Idempotent. Pre-flight + post-count assertions.
- **Phase 126** — Headshots + Phase Gate Verification: `find-headshots` for new reps; consolidated verify SQL (per-state coverage, Path 0 spot checks across ≥5 states, party-normalization assertion, no-orphan-politician assertion).
