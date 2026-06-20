# Architecture Research

**Domain:** Statewide executive integration into existing politician/district/feed schema
**Researched:** 2026-06-20
**Confidence:** HIGH — all findings from direct code reading of production source

---

## Surfacing Code Path: How STATE_EXEC Reaches `GET /representatives/me`

### The Two-Query Architecture

`GET /representatives/me` (`backend/src/routes/essentials.ts:509`) runs one of three paths (Path 0 / Path 1 / Path 1.5), all of which ultimately call `getRepresentativesByJurisdiction()` in `backend/src/lib/essentialsService.ts`. That function executes **two queries in sequence**:

**Query 1 — district-based (geo_id lookup):**
Matches `NATIONAL_LOWER`, `STATE_UPPER`, `STATE_LOWER`, `COUNTY`, `SCHOOL` districts via stored geo_ids.

**Query 2 — statewide (state-code lookup, lines 1585–1598):**
```sql
WHERE d.district_type IN ('NATIONAL_UPPER', 'NATIONAL_EXEC', 'STATE_EXEC', 'NATIONAL_JUDICIAL', 'JUDICIAL')
AND (d.state = $1 OR d.district_type IN ('NATIONAL_EXEC', 'NATIONAL_JUDICIAL'))
AND (p.is_active = true OR o.is_vacant = true)
AND COALESCE(p.is_incumbent, true) = true
AND (d.district_type != 'JUDICIAL' OR LENGTH(d.geo_id) != 5)
```

The `$1` state parameter is derived from the user's congressional geo_id:
```sql
SELECT state FROM essentials.districts
WHERE geo_id = $1 AND district_type = 'NATIONAL_LOWER' LIMIT 1
```

`STATE_EXEC` is already enumerated in this `IN` clause. The same clause appears identically in `getRepresentativesByAddress()` (the anonymous address-search path) at line 706.

### State Code Derivation — Critical Dependency

Both the Path 0 and Path 1 routes derive `d.state` from the congressional (NATIONAL_LOWER) geo_id. The statewide query only fires **if `congressional` is non-null** (line 1578: `if (congressional)`). This means:

- A user who has set their location and has a valid `congressional_geo_id` (or a `user_districts` row with `us_house` layer) will automatically get all STATE_EXEC records for their state.
- The state code comes from `essentials.districts.state` on the NATIONAL_LOWER district row, which uses 2-char uppercase postal abbreviation (e.g. `'CA'`, `'IN'`).
- STATE_EXEC districts must use **uppercase postal abbreviation** in `essentials.districts.state` — lowercase was a confirmed bug in OR migration 223 (fixed in 223a).

### Verdict: STATE_EXEC Already Surfaces for the 9 Covered States

For any user in CA, IN, MA, MD, ME, OR, TX, UT, or VA who has set their location, existing STATE_EXEC records already surface today — no feed-surfacing code change is required. The 9 existing states are working by the existing state-code path. The v2.18 work is **data-only** for those states (gap-fill stances). For the 41 uncovered states, surfacing will begin automatically as soon as their STATE_EXEC records are seeded — no code change needed.

**Feed-surfacing work required: NONE.** This is a data-seed milestone, not a code milestone.

---

## Component Boundaries

### Existing Components — No Modification Needed

| Component | File | Role in v2.18 |
|-----------|------|---------------|
| `getRepresentativesByAddress()` | `essentialsService.ts:576` | Already includes STATE_EXEC in statewide query — no change |
| `getRepresentativesByJurisdiction()` | `essentialsService.ts:1495` | Already includes STATE_EXEC in statewide query — no change |
| `GET /representatives/me` route | `essentials.ts:509` | No change — all paths call the above functions |
| `inform.politician_answers` | DB table | No schema change — same write path as all other politicians |
| `inform.politician_context` | DB table | No schema change — same write path |
| Stance research pipeline | `backend/data/stance-research/*/` | Reused verbatim (same `_TOPIC_SCALE.txt`, `_push.ts` pattern) |

### New Components Required per Milestone

| Component | Type | Purpose |
|-----------|------|---------|
| Authoritative elected-Big-5 roster | Data file / research | Source of truth for which offices are elected per state |
| `governments` + `chambers` stub records | SQL migrations | One government + N chambers per new state (40+ states need this) |
| `essentials.districts` (STATE_EXEC) | SQL migration | One district per office per state |
| `essentials.politicians` + `essentials.offices` | SQL migration | One politician + one office per exec |
| Headshot back-fill | Script / migration | Gubernatorial portraits from official state .gov or Wikipedia |
| Stance research CSV + push | Per-state scripts | Reused v2.16/v2.17 pipeline, per-exec rather than per-rep |
| Phase gate SQL | `backend/scripts/verify-phase-*.sql` | Read-only assertions: all Big-5 offices filled, 0 unsourced |

---

## Idempotent Seeding Model

### One STATE_EXEC District Per Office (Not Per State)

The established pattern (confirmed in CA migration 190, MA 154, MD 270, VA 317, OR 223, ME 169) is **one `essentials.districts` row per executive office**, not one per state. Each district has:

- `district_type = 'STATE_EXEC'`
- `state = '{STATE}'` — 2-char uppercase postal abbreviation
- `geo_id = '{FIPS}'` — numeric state FIPS code as text (e.g. `'06'` for CA, `'18'` for IN, `'51'` for VA)
- `label = '{State} {Role}'` — human-readable, e.g. `'Indiana Governor'`
- `district_id = ''` — always empty string (named strings were a bug in OR 223)
- `mtfcc = ''` — always empty string (no TIGER MTFCC for exec offices)

### Dedup Key: `(state, label)` on `essentials.districts`

The correct idempotent guard for a STATE_EXEC district is:
```sql
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE district_type = 'STATE_EXEC'
    AND state = '{STATE}'
    AND label = '{State} {Role}'
)
```

The `label` encodes both the state and the office kind (e.g. `'Indiana Governor'`, `'Indiana Attorney General'`). **Do not use title string from `essentials.offices`** — those titles are inconsistent across states (e.g. "Governor", "Indiana Governor", "Texas Governor"). The label on `essentials.districts` is the stable dedup key.

For the offices table, the guard is:
```sql
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.district_id = d.id
    AND o.chamber_id = (SELECT id FROM essentials.chambers
                        WHERE name = '{State} {Role}' AND government_id = ...)
)
```

### role_canonical Column

`essentials.offices.role_canonical` exists (added in migration 154) and is populated for MA Treasurer (`'treasurer'`) and MA Secretary (`'secretary_of_state'`) only. It is **never read by any service code** — it was added for future cross-state role queries that have not been implemented. For v2.18, set it for the Big 5 roles to enable future cross-state queries: `'governor'`, `'lt_governor'`, `'attorney_general'`, `'secretary_of_state'`, `'treasurer'`. Leave it NULL for non-Big-5 offices that are being left untouched.

---

## External ID Scheme

### Established Pattern: `-{FIPS_zero_padded}{OFFSET}`

| State | FIPS | Pattern | Example |
|-------|------|---------|---------|
| CA | 06 | `-{06}{OFFSET}` → 7-8 digits | `-6000101` through `-6000108` |
| MA | 25 | `-{200}{OFFSET}` → 6 digits | `-200001` through `-200007` (non-standard due to collision on `-200002`) |
| MD | 24 | `-{240}{OFFSET}` → 6 digits | `-240001` through `-240005` |
| OR | 41 | `-{410}{OFFSET}` → 7 digits | `-4100001` through `-4100005` |
| ME | 23 | `-{230}{OFFSET}` → 6 digits | `-230001` through (check) |
| VA | 51 | `-{510}{OFFSET}` → 7 digits | `-510001` through `-510003` |

**Recommended scheme for v2.18:** Use `-(FIPS * 100 + offset)` where FIPS is zero-padded to 2 digits and offset is 01-09 for the Big 5. The formula `-(state_fips * 100 + offset)` maps cleanly:
- Indiana (FIPS 18): `-1801` through `-1805`
- Wyoming (FIPS 56): `-5601` through `-5605`

**Collision check:** Federal seeded reps use `-(state_fips * 1000 + cd)` — minimum is `-1001` (AL CD1). State exec IDs `-(fips * 100 + offset)` will be `-101` through `-5609`. These overlap with the federal range for states FIPS 10+. **Use `-(fips * 100000 + offset)` instead** to stay safely below the federal minimum of `-1001` and above the existing exec ranges.

The safest collision-free scheme that also aligns with the established FIPS-prefix pattern used by MD/OR/VA:

```
external_id = -(state_fips * 100000 + seq)
```

Where `seq` is 1-99 (one per office). This gives:
- Indiana (18): `-1800001` through `-1800005`
- All 50 states: range `-100001` through `-5600099`
- No collision with NATIONAL_LOWER range (`-(fips * 1000 + cd)` = `-1001` through `-56001`)
- No collision with existing execs (CA `-6000101`+ uses 7-digit with different multiplier; verify against existing records before finalizing any new state's range)

**Practical recommendation:** Before creating any new state's seed migration, run a live query to confirm the proposed external_id range is clear:
```sql
SELECT external_id FROM essentials.politicians
WHERE external_id BETWEEN -{fips}00001 AND -{fips}99999;
```

---

## Data Flow

### Seed Migration Pattern (4-step, established across all 9 existing states)

```
Step 1: assert government row exists (DO $$ RAISE EXCEPTION if count != 1)
Step 2: INSERT INTO essentials.districts (one per office, WHERE NOT EXISTS on state+label)
Step 3: INSERT INTO essentials.chambers (one per office, WHERE NOT EXISTS on name+government_id)
Step 4: CTE per exec:
          WITH ins_p AS (INSERT INTO essentials.politicians ON CONFLICT(external_id) DO NOTHING RETURNING id)
          INSERT INTO essentials.offices ... WHERE NOT EXISTS on (district_id, chamber_id)
Step 5: UPDATE essentials.politicians SET office_id = o.id WHERE office_id IS NULL (scoped to external_id range)
```

### Stance Write Path — No Changes

`inform.politician_answers` and `inform.politician_context` are keyed on `(politician_id, topic_id)`. State execs are full `essentials.politicians` records and receive stances via the identical external_id → UUID lookup used by the v2.16/v2.17 push scripts. No schema or code change needed.

### Feed Read Path — No Changes

```
GET /representatives/me
  → Path 0/1/1.5 all call getRepresentativesByJurisdiction(jurisdiction)
      → Query 1: district-based geo_id lookup (congressional / state_senate / state_house / county / school)
      → Query 2: statewide lookup
           WHERE d.district_type IN ('NATIONAL_UPPER', 'NATIONAL_EXEC', 'STATE_EXEC', ...)
           AND d.state = {state_from_congressional_district}
           (STATE_EXEC already enumerated)
```

---

## System Overview

```
                    essentials.districts
                    (district_type='STATE_EXEC',
                     state='XX', geo_id='{FIPS}',
                     label='{State} {Role}')
                              |
                              | district_id FK
                              v
                    essentials.offices
                    (title='{Role}',
                     representing_state='XX',
                     is_appointed_position=false,   ← elected only
                     role_canonical='{key}')
                              |
                              | politician_id FK
                              v
                    essentials.politicians
                    (external_id=-(fips*100000+seq),
                     is_active=true, is_incumbent=true)
                              |
              ________________|________________
             |                                 |
             v                                 v
inform.politician_answers           inform.politician_context
(politician_id, topic_id, value)    (politician_id, topic_id, sources[])
             |                                 |
             |__________________________________|
                              |
                              v
              getRepresentativesByJurisdiction()
              (statewide query: WHERE d.state = $1
               AND d.district_type IN (..., 'STATE_EXEC', ...))
                              |
                              v
              GET /api/essentials/representatives/me
              GET /api/essentials/address-search
```

---

## Suggested Build Order

### Why This Order

1. **Roster first** — the elected-Big-5 roster determines exactly what to seed; building it first prevents mid-migration scope corrections (e.g. discovering TX has no elected Treasurer after writing the migration).
2. **Governments + chambers before politicians** — politicians reference chambers, chambers reference governments; FK order matters.
3. **Seed before stances** — stance push needs the politician UUID, which comes from the seed.
4. **Gate last** — verifies the full chain (district → office → politician → stances → surfacing).

### Build Order

| Phase | Work | New or Modified |
|-------|------|-----------------|
| Phase A: Roster | Research + document elected Big-5 per state (NGA / Ballotpedia / state .gov). Per-state JSON or CSV: state, office kind, current officeholder, FIPS. Mark appointed vs. elected. | New data file |
| Phase B: Governments + Chambers | For the ~41 states without a government row or exec chambers, create stub government + chamber rows. Idempotent. Reuse existing pattern from v2.3 (50-state government stubs). | New migration(s) |
| Phase C: Districts + Politicians + Offices | Per-state seed migrations: STATE_EXEC districts, politicians, offices. One migration per state wave (group by roster size). Only elected offices. | New migrations |
| Phase D: Headshots | Official gubernatorial portraits and exec headshots from state .gov / Wikipedia. `photo_origin_url` or `photo_custom_url` on `essentials.politicians`. | Migrations or script |
| Phase E: Stance Research | Per-exec CSV research using v2.16/v2.17 pipeline. Batched at 3-concurrency. external_id-keyed push. Same honest-skip and no-inference rules. | New scripts + migrations |
| Phase F: Gate | Read-only SQL gate: all elected Big-5 offices filled per state, 0 unsourced rows, state-code surfacing verified for a sample address per state. | New SQL script |

---

## Architectural Patterns to Follow

### Pattern 1: Pre-flight Government Assertion

Every state exec migration since MD (270) begins with a `DO $$` block asserting the government row exists and has exactly 1 row. This catches ordering errors (e.g. seeding exec before the government stub) at migration time rather than silently inserting orphaned records.

### Pattern 2: Label-Keyed District Dedup

State is not enough — multiple offices per state share the same FIPS geo_id. The `(state, label)` compound key on `essentials.districts` is the correct idempotency guard. The label is `'{State} {Role}'` where Role is the official role name as it appears in the chamber.

### Pattern 3: Elected-Only Filter via `is_appointed_position`

The feed already filters by `AND COALESCE(p.is_incumbent, true) = true` but not by `is_appointed_position`. The `is_elected` field on `PoliticianFlatRecord` is derived as `!row.is_appointed_position`. For v2.18, only seed offices where the position is voter-elected — set `is_appointed_position=false` for elected offices and `is_appointed_position=true` for appointed ones (e.g. MD Treasurer, ME AG/SoS/Treasurer). The frontend uses `is_elected` to distinguish.

### Pattern 4: Uppercase State Abbreviation

`essentials.districts.state` must use uppercase postal abbreviation (`'CA'` not `'ca'`). Lowercase was a confirmed production bug in OR migration 223 that required a separate fix migration (223a). The statewide query in `getRepresentativesByJurisdiction()` uses `d.state = $1` where `$1` comes from `SELECT state FROM essentials.districts WHERE geo_id = $1 AND district_type = 'NATIONAL_LOWER'` — those NATIONAL_LOWER rows already use uppercase.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Seeding Non-Elected Officers

**What people do:** Seed all 5 Big-5 offices for every state without checking whether the office is elected or appointed.
**Why it's wrong:** MD Treasurer, ME AG/SoS/Treasurer, VA SoS, TX SoS, UT SoS — these are appointed, not elected. Setting `is_appointed_position=false` for them misrepresents the office. More importantly, v2.18's goal is "elected Big 5" and seeding appointed officials balloons scope without adding product value.
**Do this instead:** Use the authoritative roster (Phase A) to mark each office as elected or appointed. Seed both with correct flags; present only elected ones as "your representatives."

### Anti-Pattern 2: Deduping on office title string

**What people do:** Check for existing records with `WHERE o.title = 'Governor'` or `WHERE o.title = 'Indiana Governor'` to detect existing Big-5 records.
**Why it's wrong:** Title strings are inconsistent across states and across migrations. VA uses `'Governor'`, OR uses `'Governor'`, MA uses `'Governor'` — all are the same role but distinguishable only by their linked district.
**Do this instead:** Dedup on `(essentials.districts.state, essentials.districts.label)` for the district, and on `(district_id, chamber_id)` for the office. These are the established guards in every existing migration.

### Anti-Pattern 3: Skipping the government pre-flight assertion

**What people do:** Assume the government row exists because it was seeded in a prior migration.
**Why it's wrong:** If migrations are applied out of order or to a non-production DB, missing government rows cause silent orphan records (no FK violation because `chamber_id` could be NULL or reference a wrong government).
**Do this instead:** Begin every state exec migration with `DO $$ IF COUNT(*) != 1 THEN RAISE EXCEPTION ... END IF; $$` asserting the government row exists.

### Anti-Pattern 4: Using a shared STATE_EXEC district across all offices in a state

**What people do:** Create one `STATE_EXEC` district per state and link all exec offices to it (treating it like the NATIONAL_UPPER pattern where 2 senators share one district row).
**Why it's wrong:** A shared district means the feed query returns all exec offices when matching the single district, which is correct — but the idempotency guards for offices break down (the `WHERE NOT EXISTS on (district_id, chamber_id)` guard becomes the only distinguishing factor, which depends on chambers existing first). More critically: the `label` on the shared district loses specificity. CA, MA, MD, OR, VA all use **one district per office** — follow this pattern.
**Do this instead:** One `essentials.districts` row per executive office, with `label = '{State} {Role}'`.

---

## Integration Points

| Integration | How It Works | Notes |
|-------------|-------------|-------|
| `GET /representatives/me` | Statewide query already includes `STATE_EXEC` — zero code change | Conditioned on `congressional` geo_id being non-null |
| `GET /essentials/address-search` | Same statewide query at line 706 — already includes `STATE_EXEC` | Works for anonymous address lookup too |
| Stance pipeline (`_push.ts`) | external_id → UUID lookup in `essentials.politicians` | No change to push logic |
| Headshot backfill | `photo_origin_url` or `photo_custom_url` on `essentials.politicians` | Same column as all other politicians |
| Phase gate SQL | New `backend/scripts/verify-phase-{N}.sql` | Pattern: `verify-phase-132-140.sql`; assert per-state counts + 0 unsourced |

---

## Sources

All findings from direct code reading (HIGH confidence):

- Feed surfacing: `backend/src/lib/essentialsService.ts` lines 1574–1598 (Path 0/1 statewide query), lines 669–716 (address-search statewide query)
- Route handler: `backend/src/routes/essentials.ts` lines 509–741
- Seed pattern: `backend/migrations/190_ca_state_executives.sql` (CA, one-per-office model)
- Seed pattern: `backend/migrations/154_ma_state_executives.sql` (MA, role_canonical, label dedup)
- Seed pattern: `backend/migrations/270_md_state_executives.sql` (MD, appointed vs elected distinction)
- Seed pattern: `backend/migrations/317_va_state_executives.sql` (VA, uppercase state, empty district_id)
- Seed pattern: `backend/migrations/223_or_executive_officials.sql` (OR, FIPS-prefix external_id)
- Upstream bug fix: `backend/migrations/223a_or_executive_district_fix.sql` (lowercase state bug)

---

*Architecture research for: v2.18 State Leaders — statewide exec integration*
*Researched: 2026-06-20*
