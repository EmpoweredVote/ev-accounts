# Politician District Seed — Runbook

## Overview

This runbook seeds `inform.politicians` with district metadata for known Alpha coverage areas. Migration 033 adds 9 new columns to `inform.politicians` (representing_city, representing_state, district_type, district_label, district_id, chamber_name, chamber_name_formal, government_name, is_vacant) — this seed script populates those columns for Bloomington, Indiana and Los Angeles, California. Must be run once per environment after migration 033 is applied.

---

## Purpose

The `GET /api/essentials/politicians` endpoint returns politician records including all 9 new district fields. Downstream consumers (Essentials app, Validation Quests) need these fields populated to render politician district context. The seed script inserts placeholder records that can be updated with real officeholder data when known.

---

## Prerequisites

Before starting, confirm all of the following:

- **Migration 033 applied** — `inform.politicians` has the 9 new columns (run `\d inform.politicians` in psql to confirm `district_type`, `is_vacant`, etc. exist)
- **SUPABASE_URL set** — the project URL (e.g., `https://<ref>.supabase.co`)
- **SUPABASE_SERVICE_ROLE_KEY set** — service role key from Supabase Dashboard → Settings → API
- **Node.js 18+ and tsx available** — run `npx tsx --version` to confirm

---

## Command

Run from the repository root:

```bash
npx tsx scripts/seedPoliticians.ts
```

### With environment variables inline (if not in .env):

```bash
SUPABASE_URL=https://<ref>.supabase.co \
SUPABASE_SERVICE_ROLE_KEY=<service-role-key> \
npx tsx scripts/seedPoliticians.ts
```

---

## What It Does

The script upserts 4 politician records using `ON CONFLICT (first_name, last_name) DO UPDATE`:

| Coverage Area     | District Type  | district_id | Chamber             |
|-------------------|----------------|-------------|---------------------|
| Bloomington, IN   | congressional  | 18-09       | U.S. House          |
| Bloomington, IN   | state_senate   | 18-040      | Indiana Senate      |
| Bloomington, IN   | state_house    | 18-060      | Indiana House       |
| Los Angeles, CA   | county         | 06-037      | (county level)      |

All records are set to `is_active = true`, `is_vacant = false`.

**Note on LA County:** Only the county-level record is seeded for Los Angeles. Congressional, state senate, state house, and school district fields are not populated — this is expected Alpha behavior. The `GET /api/essentials/politicians` endpoint filters `is_vacant = false`, so LA County always appears.

---

## Idempotency

Safe to re-run. The script uses Supabase upsert with `onConflict: 'first_name,last_name'`. Running the script multiple times against the same environment will update existing records rather than creating duplicates.

---

## Verification

After running the script, verify the endpoint returns records with populated district fields:

### Option A — cURL (requires server running)

```bash
curl -s http://localhost:3000/api/essentials/politicians | \
  jq '.[] | .incumbent | {office_title, district_type, district_id, government_name}'
```

Expected: each non-null incumbent has `district_type`, `district_id`, and `government_name` populated.

### Option B — Direct DB query (psql)

```sql
SELECT office_title, district_type, district_id, government_name, is_vacant
FROM inform.politicians
WHERE is_active = true
ORDER BY representing_state, district_type;
```

Expected: 4 rows matching the seed data above, all with `is_vacant = false`.

### Option C — TypeScript compilation check

The `essentialsService.ts` PoliticianRecord interface was updated in phase 21-02 to include all 9 new fields. Confirm TypeScript compiles cleanly:

```bash
cd backend && npx tsc --noEmit
```

---

## Extending Coverage

To add more coverage areas:

1. Open `scripts/seedPoliticians.ts`
2. Add entries to the `seedRecords` array following the existing pattern
3. Use the `district_id` format `'{state_fips}-{district_number}'` (e.g., `'17-10'` for Illinois 10th Congressional)
4. Re-run: `npx tsx scripts/seedPoliticians.ts`
5. The script is idempotent — existing records will be updated, new ones inserted

### District ID format reference

| District Type  | Format           | Example         |
|----------------|------------------|-----------------|
| congressional  | `{state_fips}-{seat_number (2 digits)}` | `18-09` |
| state_senate   | `{state_fips}-{district (3 digits)}` | `18-040` |
| state_house    | `{state_fips}-{district (3 digits)}` | `18-060` |
| county         | `{state_fips}-{county_fips (3 digits)}` | `06-037` |
| school_district | `{state_fips}-{district_geoid}` | varies |

---

## Related

- **Migration 033** — `supabase/migrations/033_inform_politicians_district_columns.sql` — adds the 9 new columns
- **RUNBOOK-TIGER-LOAD.md** — loads PostGIS boundary data for jurisdiction resolution
- **essentialsService.ts** — `backend/src/lib/essentialsService.ts` — endpoint that returns these records
