---
phase: 125-national-house-rep-ingestion
plan: 01
status: complete
completed: 2026-06-16
requirements: [USHR-01, USHR-03]
---

# 125-01 Summary — Build ingestion script + generate migration

## What was built

- **`backend/scripts/seed-national-house-reps.ts`** — fetches `legislators-current.yaml`, builds the current House roster (last term, `type='rep'`), embeds a USPS→FIPS map (50 states + DC), maps `tiger_geoid = FIPS + zero-padded CD` (at-large `00`), `external_id = -(fips*1000 + cd)`, normalizes `Democrat→Democratic`. Queries unseeded `NATIONAL_LOWER` districts and matches each to its roster rep by `tiger_geoid`. `--dry-run` (default) prints a coverage report; `--generate` writes a reviewable migration. **Zero DB writes** (SELECT-only).
- **`backend/migrations/739_national_house_reps.sql`** — generated migration, 299 idempotent politician+office insert blocks (migration-311 pattern) + office_id backfill. 7523 lines, single BEGIN/COMMIT. **NOT applied** (that's 125-02).

## Coverage report (dry-run)

- Roster: 432 current House reps (50 states + DC); 5 territory delegates skipped (PR/GU/VI/AS/MP — no FIPS/districts)
- Unseeded `NATIONAL_LOWER` districts: 303
- **MATCHED (insert generated): 299**
- VACANCY (excluded): 4 — investigated and confirmed:
  - `1198` DC "Delegate District (at Large)" — duplicate TIGER row; DC delegate (Eleanor Holmes Norton) already seeded under `dc`-prefixed geoids (Phase 105). Correctly excluded.
  - `1220` FL-20, `1313` GA-13, `4823` TX-23 — **genuine current vacancies**. Confirmed: `legislators-current.yaml` has zero current members for these districts (GA-13/TX-23 absent from all current terms; FL-20's only history hit is Debbie Wasserman Schultz's pre-redistricting term — she is now FL-25). Seat unfilled pending special election.
- ALREADY-SEEDED (not in gap): 133 (the pre-existing CA/TX/VA/MA/MD/OR/UT/ME/IN/DC reps)

## Verification (acceptance criteria met)

- 299 `INSERT INTO essentials.politicians` + 299 `INSERT INTO essentials.offices`
- 0 literal `'Democrat'` party values; 127 `'Democratic'` (normalization holds)
- office_id backfill present, scoped `external_id BETWEEN -56999 AND -1000`
- Single `BEGIN;`/`COMMIT;`; every block has `ON CONFLICT (external_id) DO NOTHING` + `NOT EXISTS` office guard
- Spot checks: AK-AL Begich `0200`/`-2000`; WY-AL Hageman `5600`/`-56000`; NY-1 LaLota `3601`/`-36001`; AL-2 Figures `Democratic` — all correct
- external_id range `-1001..-56000` (within the 0-collision band)

## Deviations

- Migration number is **739**, not 734 — the pre-flight `MAX(version)` against `supabase_migrations.schema_migrations` returned 738 (higher than disk max 733), so the script used 739. This is the documented psql-migration safety check working as designed.
- `--dry-run` is the default mode (not a no-op flag); generation requires explicit `--generate`. Matches the plan's "no writes without intent" requirement.

## For 125-02

Apply `migrations/739_national_house_reps.sql` to production (`kxsdzaojfaibhuzmclfq`). Expected: linked House reps 137 → 436 (435 voting − 3 vacancies + ... actually 137 baseline + 299 = 436). The 3 genuine vacancies (FL-20, GA-13, TX-23) and the duplicate DC row (1198) remain unlinked by design.
