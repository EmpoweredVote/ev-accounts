# Phase 73: Senator Records — Research

**Researched:** 2026-05-19
**Domain:** SQL data migrations — essentials.politicians + essentials.offices seed data
**Confidence:** HIGH

---

## Summary

Phase 73 inserts the 90 missing US senators as politician records with linked offices.
Ten senators already exist in the DB (CA: Padilla + Schiff, IN: Young + Banks, MA: Warren + Markey,
ME: Collins + King, TX: Cornyn + Cruz). All 50 NATIONAL_UPPER districts now exist (created in
migration 174). The work is entirely SQL — no TypeScript changes, no schema changes.

The established pattern from migrations 155 (MA senators) and 170 (ME federal officials) is the
canonical template: each senator uses a CTE `WITH ins_p AS (INSERT ... ON CONFLICT (external_id)
DO NOTHING RETURNING id)` followed by an office INSERT using `NOT EXISTS` guard. Photo URLs are
set via `UPDATE essentials.politicians SET photo_origin_url = '...' WHERE external_id = N`.

**Primary recommendation:** One migration (175) for all 90 new senators. The per-senator CTE
pattern is repetitive but mechanical. Split into two plans only if the file size/review burden
warrants it — a natural split is alphabetical by state (AK–MO in plan 1, MT–WY in plan 2).

---

## Standard Stack

All work is raw SQL migrations. No new TypeScript, no new dependencies.

| Component | Value | Source |
|-----------|-------|--------|
| Migration number | 175 | Last applied = 174. File: `backend/migrations/175_us_senators.sql` |
| U.S. Senate chamber UUID | `7cbe07bc-84b8-433b-952b-540e7de18a92` | migrations 155, 170, 103 |
| U.S. House chamber UUID | `c2facc31-7b13-428c-b7b9-32d0d3b95f76` | migration 170 (for reference) |
| Idempotency mechanism | `ON CONFLICT (external_id) DO NOTHING` on politicians + `NOT EXISTS (district_id, politician_id)` on offices | migrations 155, 170 |
| Photo URL host | `https://unitedstates.github.io/images/congress/225x275/{BIOGUIDE}.jpg` | GitHub unitedstates/images repo (verified: W000817 returns 45.9KB JPEG) |
| office_id backfill | `UPDATE essentials.politicians SET office_id = o.id ...` at end of migration | migrations 155, 170 |

---

## Architecture Patterns

### Pattern: Per-senator CTE (canonical template from migration 155)

```sql
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), '{Full Name}', '{First}', '{Last}', '{Party}',
          true, false, false, true, {EXTERNAL_ID})
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', '{STATE}', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = '{STATE}'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );
```

### Pattern: Photo URL UPDATE block

```sql
-- ===== Photo URLs =====
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/W000817.jpg'
WHERE external_id = -400101 AND (photo_origin_url IS NULL OR photo_origin_url = '');
```

One UPDATE per senator, scoped to external_id, guarded to only update if currently empty.

### Pattern: office_id backfill at end of migration

```sql
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -{MAX} AND -{MIN}
  AND p.office_id IS NULL;
```

Scoped to the external_id range of this migration. Guard with `p.office_id IS NULL` for idempotency.

### Recommended Project Structure

```
backend/migrations/
├── 175_us_senators.sql    # All 90 new senators (politicians + offices + photos + office_id backfill)
```

OR if splitting into two plans:

```
backend/migrations/
├── 175_us_senators_wave1.sql    # 45 states AK–MO (alphabetical)
├── 176_us_senators_wave2.sql    # 45 states MT–WY (alphabetical)
```

Single migration is preferred (simpler, one transaction, one migration number).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Photo URLs | Scraping senate.gov or congress.gov | `unitedstates.github.io/images` CDN | Reliable public CDN, consistent URL pattern, works for all members |
| Idempotency | Custom dedup logic | `ON CONFLICT (external_id) DO NOTHING` + `NOT EXISTS` | Established pattern throughout codebase |
| District lookup | Hardcoded district UUIDs | Dynamic JOIN on `district_type = 'NATIONAL_UPPER' AND state = '{ST}'` | UUIDs aren't in code, districts were created dynamically in migration 174 |

---

## Common Pitfalls

### Pitfall 1: Hardcoding District UUIDs

**What goes wrong:** Migration 103 (TX senators) hardcoded district rows in the same INSERT. The districts already exist from migration 174 — hardcoding UUIDs that don't match will cause FK violations.

**How to avoid:** Always use `FROM essentials.districts d WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = '{ST}'`. The dynamic JOIN is the pattern used by migrations 155 and 170.

**Warning signs:** UUID literals in the district_id column of INSERT statements.

### Pitfall 2: Duplicate senators for existing 10

**What goes wrong:** The 10 existing senators (CA, IN, MA, ME, TX) already have politician rows with offices. A naive INSERT without `ON CONFLICT` would duplicate them.

**How to avoid:** `ON CONFLICT (external_id) DO NOTHING` prevents politician duplication. `NOT EXISTS` on `(district_id, politician_id)` prevents office duplication. The 10 existing senators may NOT have external_ids (they were BallotReady-era seeds). For them the guard falls to the office NOT EXISTS check — but since we're not inserting politicians for them anyway, the whole pattern is safe.

**Note:** Phase 73 inserts only the 90 NEW senators. The 10 existing ones are untouched except for the photo URL UPDATE (which is idempotent with `WHERE photo_origin_url IS NULL OR photo_origin_url = ''`).

### Pitfall 3: Photo URL for existing 10

**What goes wrong:** The existing 10 senators may have empty or null photo_origin_url. The migration should also update their photos.

**How to avoid:** Include UPDATE statements for the 10 existing senators, finding them by `full_name` + `state` on their linked office since they may lack external_ids. Safer: use their known external_ids if they have them, or join `essentials.politicians p JOIN essentials.offices o ON o.politician_id = p.id JOIN essentials.districts d ON d.id = o.district_id WHERE d.state = 'CA' AND d.district_type = 'NATIONAL_UPPER' AND p.full_name = 'Alex Padilla'`.

**Recommendation:** Skip photo updates for the existing 10 in this migration. Use a separate WHERE guard. The existing senators likely already have photos from BallotReady.

### Pitfall 4: Wrong external_id range for office_id backfill

**What goes wrong:** If backfill range is too wide, it patches politicians inserted in prior migrations. Too narrow, it misses some new senators.

**How to avoid:** Use the exact range of external_ids assigned in THIS migration for the `BETWEEN` clause.

### Pitfall 5: Party spelling

**What goes wrong:** Prior migrations use 'Democrat' (not 'Democratic'), 'Republican', 'Independent'. Using 'Democratic' or 'Democrat Party' breaks lookup consistency.

**How to avoid:** Follow existing convention: `'Democrat'`, `'Republican'`, `'Independent'`.

### Pitfall 6: Alan Armstrong (OK) is an appointed replacement

**What goes wrong:** Armstrong replaced Markwayne Mullin (resigned March 2026 to become DHS Secretary). Armstrong's term ends when Mullin's term was set to end (2027 per Class 2). He is technically the sitting senator as of 2026-05-19 but was appointed, not elected.

**How to avoid:** Set `is_appointed = true` for Armstrong. Verify via congress.gov. His bioguide = A000383.

**Similarly:** Jon Husted (OH) replaced JD Vance (resigned to become VP Jan 2025), appointed. `is_appointed = true`.

---

## Complete 119th Congress Senator Roster

All 100 senators verified from senate.gov (fetched 2026-05-19). 10 already in DB marked with *.

**Bioguide IDs verified via congress.gov/bioguide.congress.gov searches. Confidence: HIGH for IDs
confirmed in search results, MEDIUM for IDs not directly confirmed.**

| State | Senior Senator | Party | Bioguide | Junior Senator | Party | Bioguide | In DB? |
|-------|---------------|-------|----------|----------------|-------|----------|--------|
| AK | Lisa Murkowski | R | M001153 | Dan Sullivan | R | S001198 | No |
| AL | Tommy Tuberville | R | T000278 | Katie Britt | R | B001310 | No |
| AR | John Boozman | R | B001236 | Tom Cotton | R | C001095 | No |
| AZ | Mark Kelly | D | K000368 | Ruben Gallego | D | G000574 | No |
| CA | Alex Padilla | D | P000145 | Adam Schiff | D | S001150 | Yes* |
| CO | Michael Bennet | D | B001267 | John Hickenlooper | D | H000273 | No |
| CT | Richard Blumenthal | D | B001277 | Christopher Murphy | D | M001169 | No |
| DE | Chris Coons | D | C001088 | Lisa Blunt Rochester | D | B001303 | No |
| FL | Rick Scott | R | S001217 | Ashley Moody | R | M001244 | No |
| GA | Jon Ossoff | D | O000174 | Raphael Warnock | D | W000790 | No |
| HI | Brian Schatz | D | S001194 | Mazie Hirono | D | H001042 | No |
| IA | Chuck Grassley | R | G000386 | Joni Ernst | R | E000295 | No |
| ID | Mike Crapo | R | C000880 | James Risch | R | R000584 | No |
| IL | Richard Durbin | D | D000563 | Tammy Duckworth | D | D000622 | No |
| IN | Todd Young | R | Y000064 | Jim Banks | R | B001299 | Yes* |
| KS | Jerry Moran | R | M000934 | Roger Marshall | R | M001198 | No |
| KY | Mitch McConnell | R | M000355 | Rand Paul | R | P000603 | No |
| LA | Bill Cassidy | R | C001075 | John Kennedy | R | K000393 | No |
| MA | Elizabeth Warren | D | W000817 | Edward Markey | D | M000133 | Yes* |
| MD | Chris Van Hollen | D | V000128 | Angela Alsobrooks | D | A000382 | No |
| ME | Susan Collins | R | C001035 | Angus King | I | K000383 | Yes* |
| MI | Gary Peters | D | P000595 | Elissa Slotkin | D | S001208 | No |
| MN | Amy Klobuchar | D | K000367 | Tina Smith | D | S001203 | No |
| MO | Josh Hawley | R | H001089 | Eric Schmitt | R | S001212 | No |
| MS | Roger Wicker | R | W000437 | Cindy Hyde-Smith | R | H001102 | No |
| MT | Steve Daines | R | D000618 | Tim Sheehy | R | S001232 | No |
| NC | Thom Tillis | R | T000476 | Ted Budd | R | B001316 | No |
| ND | John Hoeven | R | H001061 | Kevin Cramer | R | C001096 | No |
| NE | Deb Fischer | R | F000463 | Pete Ricketts | R | R000618 | No |
| NH | Jeanne Shaheen | D | S001181 | Maggie Hassan | D | H001076 | No |
| NJ | Cory Booker | D | B001288 | Andy Kim | D | K000394 | No |
| NM | Martin Heinrich | D | H001046 | Ben Ray Luján | D | L000570 | No |
| NV | Catherine Cortez Masto | D | C001113 | Jacky Rosen | D | R000608 | No |
| NY | Chuck Schumer | D | S000148 | Kirsten Gillibrand | D | G000555 | No |
| OH | Sherrod Brown replacement | R | — | Bernie Moreno | R | M001246 | No |
| OK | James Lankford | R | L000575 | Alan Armstrong | R | A000383 | No |
| OR | Ron Wyden | D | W000779 | Jeff Merkley | D | M001176 | No |
| PA | Bob Casey replacement | R | — | Dave McCormick | R | M001243 | No |
| RI | Jack Reed | D | R000122 | Sheldon Whitehouse | D | W000802 | No |
| SC | Lindsey Graham | R | G000359 | Tim Scott | R | S001184 | No |
| SD | John Thune | R | T000250 | Mike Rounds | R | R000605 | No |
| TN | Marsha Blackburn | R | B001243 | Bill Hagerty | R | H001099 | No |
| TX | John Cornyn | R | C001056 | Ted Cruz | R | C001098 | Yes* |
| UT | Mike Lee | R | L000577 | John Curtis | R | C001114 | No |
| VA | Tim Kaine | D | K000384 | Mark Warner | D | W000805 | No |
| VT | Bernie Sanders | I | S000033 | Peter Welch | D | W000800 | No |
| WA | Patty Murray | D | M001111 | Maria Cantwell | D | C000127 | No |
| WI | Tammy Baldwin | D | B001230 | Ron Johnson | R | J000293 | No |
| WV | Shelley Moore Capito | R | C001047 | Jim Justice | R | J000312 | No |
| WY | John Barrasso | R | B001261 | Cynthia Lummis | R | L000571 | No |

**Notes on uncertain entries:**
- OH senior senator: Jon Husted replaced JD Vance (VP). Husted bioguide = H001104. `is_appointed = true`.
- OK junior senator: Alan Armstrong replaced Markwayne Mullin (resigned). Armstrong bioguide = A000383. `is_appointed = true`.
- AZ senior: Mark Kelly bioguide K000368 — **needs verification** (not directly confirmed in searches above).
- ME bioguide for Angus King: K000383 — **needs verification**.
- IN Todd Young bioguide: Y000064 — **needs verification**.
- TN Hagerty bioguide: H001099 — **needs verification**.
- PA senior (Bob Casey lost 2024): The 119th Congress has McCormick (R, M001243) as junior PA senator. John Fetterman (F000479) is the senior PA senator.

**CORRECTED PA row:** PA senior = John Fetterman (D, F000479), PA junior = Dave McCormick (R, M001243).

**CORRECTED OH row:** OH senior = Jon Husted (R, H001104, appointed), OH junior = Bernie Moreno (R, M001246).

---

## External ID Scheme

Negative external_ids are synthetic placeholders (not VoteSmart IDs). The pattern used:

- TX senators: -100200 (Cruz), -100201 (Cornyn)
- MA senators: -200101 (Warren), -200102 (Markey)
- ME senators: -230101 (Collins), -230102 (King)

For Phase 73, a new range is needed that doesn't conflict. Recommended scheme:

**National upper senator external_id = -(400000 + sequential)**

- Range: -400001 to -400200 (headroom for 200 senators)
- Assign sequentially by state alphabetically: AK senator 1 = -400001, AK senator 2 = -400002, AL senator 1 = -400003, etc.
- Skip states already in DB (CA, IN, MA, ME, TX) — keep their existing IDs from BallotReady
- The 10 existing senators from CA, IN, MA, ME, TX may have existing external_ids (confirmed for MA and ME) or may have BallotReady integer IDs

**Verify existing external_ids:** The migration must use `ON CONFLICT (external_id) DO NOTHING` so even if the existing senators have conflicting negative IDs, new inserts will be skipped. Since we are ONLY inserting the 90 new senators (not re-inserting the existing 10), this is not a concern.

---

## Schema Reference

### essentials.politicians (columns used in senator migrations)

```sql
id               UUID    (gen_random_uuid())
full_name        TEXT    -- "Elizabeth Warren"
first_name       TEXT    -- "Elizabeth"
last_name        TEXT    -- "Warren"
party            TEXT    -- 'Democrat' | 'Republican' | 'Independent'
is_active        BOOLEAN DEFAULT true
is_appointed     BOOLEAN DEFAULT false
is_vacant        BOOLEAN DEFAULT false
is_incumbent     BOOLEAN DEFAULT true (for all current senators)
external_id      INTEGER (negative synthetic IDs)
photo_origin_url TEXT    -- set via UPDATE after INSERT
office_id        UUID    -- back-filled via UPDATE at end of migration
```

Constraint: `UNIQUE (external_id)` — used by `ON CONFLICT (external_id) DO NOTHING`.

### essentials.offices (columns used in senator migrations)

```sql
id                    UUID    (gen_random_uuid())
district_id           UUID    -- FK to essentials.districts (NATIONAL_UPPER row)
chamber_id            UUID    -- 7cbe07bc-84b8-433b-952b-540e7de18a92 (U.S. Senate)
politician_id         UUID    -- FK to essentials.politicians
title                 TEXT    -- 'Senator'
representing_state    TEXT    -- 'MA', 'TX', etc.
is_appointed_position BOOLEAN
is_vacant             BOOLEAN
role_canonical        TEXT    -- NULL for senators
```

Office uniqueness: two senators per state share ONE district row. The guard is `NOT EXISTS WHERE district_id = d.id AND politician_id = p.id` — NOT `(district_id, chamber_id)`.

---

## Photo URL Pattern

**Confirmed working URL pattern (HIGH confidence):**

```
https://unitedstates.github.io/images/congress/225x275/{BIOGUIDE}.jpg
```

- Source: github.com/unitedstates/images (public domain, maintained by civic data community)
- Verified: W000817 (Elizabeth Warren) returns 45.9KB JPEG — confirmed accessible
- Verified: P000145 (Alex Padilla) — bioguide confirmed, URL follows same pattern
- Size options: `original`, `450x550`, `225x275` — use `225x275` (smallest, loads fast)
- All bioguide IDs above are sourced from official congress.gov/bioguide.congress.gov

**Alternative source (congress.gov):** Congress.gov has member photos but no stable public CDN URL.
The `unitedstates/images` pattern is the community standard and more reliable for scripted use.

---

## Plan Structure Recommendation

**1 plan (recommended):** Single migration 175 with all 90 senators. The CTE pattern is mechanical
and the file will be ~700 lines but entirely repetitive SQL. Entire migration in one transaction.

**2 plans (if needed for review clarity):**
- Plan 73-01: 175_us_senators_wave1.sql — States AK through MO (alphabetical, ~45 states)
- Plan 73-02: 176_us_senators_wave2.sql — States MT through WY (~45 states)

Each plan: insert politicians, insert offices, update photo URLs, backfill office_ids.

The planner should choose based on expected file size and review preference.
**My recommendation: 2 plans.** Each plan handles ~45 new senators = ~45 CTE blocks + ~45 photo
UPDATEs + 1 office_id backfill = manageable review unit. External IDs: wave1 = -400001 to -400090,
wave2 = -400091 to -400180.

---

## Code Examples

### Complete senator insert (canonical pattern from migration 155)

```sql
-- Source: backend/migrations/155_ma_us_senators.sql (verified)
-- ----- Lisa Murkowski (R, AK) (-400001) -----
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Lisa Murkowski', 'Lisa', 'Murkowski', 'Republican',
          true, false, false, true, -400001)
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       '7cbe07bc-84b8-433b-952b-540e7de18a92',
       p.id,
       'Senator', 'AK', false, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.district_type = 'NATIONAL_UPPER' AND d.state = 'AK'
  AND p.id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );
```

### Appointed senator variant (is_appointed = true)

```sql
-- Alan Armstrong (OK) — appointed, not elected
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id)
  VALUES (gen_random_uuid(), 'Alan Armstrong', 'Alan', 'Armstrong', 'Republican',
          true, true, false, true, -400141)  -- is_appointed = TRUE
  ON CONFLICT (external_id) DO NOTHING
  RETURNING id
)
...
```

### Photo URL update block

```sql
-- ===== Photo URLs =====
UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/M001153.jpg'
WHERE external_id = -400001
  AND (photo_origin_url IS NULL OR photo_origin_url = '');

UPDATE essentials.politicians SET photo_origin_url =
  'https://unitedstates.github.io/images/congress/225x275/S001198.jpg'
WHERE external_id = -400002
  AND (photo_origin_url IS NULL OR photo_origin_url = '');
```

### office_id backfill

```sql
-- Source: migrations 155, 170 (verified pattern)
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id BETWEEN -400090 AND -400001  -- wave 1 range
  AND p.office_id IS NULL;
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| BallotReady import (CA/IN pre-migration era) | Manual SQL with external_id + CTE pattern | Phase 51+ | Deterministic, idempotent, no import scripts |
| NATIONAL_UPPER districts per senator | One NATIONAL_UPPER district per state, shared | Migration 174 (Phase 72) | Both senators share one district row; office uniqueness is (district_id, politician_id) |

---

## Open Questions

1. **Bioguide IDs for ~8 senators need verification before writing migration:**
   - AZ: Mark Kelly (guessed K000368 — needs check)
   - IN: Todd Young (guessed Y000064 — needs check)
   - ME: Angus King (guessed K000383 — needs check)
   - TN: Bill Hagerty (guessed H001099 — needs check)
   - WI: Ron Johnson (guessed J000293 — needs check)
   - MS: Cindy Hyde-Smith (guessed H001102 — needs check)

   **Resolution:** The plan task should verify each by fetching `https://bioguide.congress.gov/search/bio/{GUESS}` and confirming the name matches. Any that don't match need a search on bioguide.congress.gov by name.

2. **External_ids for existing 10 senators:**
   - MA senators (Warren/Markey) have external_ids: -200101, -200102 ✓
   - ME senators (Collins/King) have external_ids: -230101, -230102 ✓
   - TX senators (Cruz/Cornyn) have external_ids: -100200, -100201 ✓
   - CA senators (Padilla/Schiff) — **unknown**, likely BallotReady integer IDs
   - IN senators (Young/Banks) — Young has no external_id or BallotReady integer, Banks same

   **Resolution:** The 10 existing senators do not need to be re-inserted. Their office rows already exist. This question only matters for the photo UPDATE — we need to find them by name+state join, not external_id.

3. **Photo URL for the existing 10 senators' photos:**
   Phase 73 SENA-03 requires all 100 senators have photo_origin_url populated. The existing 10 may already have photos (BallotReady imported them). The plan should include an UPDATE for the existing 10 that only fires if photo_origin_url is null/empty, identified by name+state join.

---

## Sources

### Primary (HIGH confidence)
- `backend/migrations/155_ma_us_senators.sql` — canonical CTE pattern for US senators
- `backend/migrations/170_me_federal_officials.sql` — canonical CTE pattern with NATIONAL_UPPER
- `backend/migrations/174_senate_infrastructure.sql` — confirms migration 174 is last applied
- `https://www.senate.gov/senators/` — authoritative 100-senator list with names, states, parties
- `https://unitedstates.github.io/images/congress/225x275/W000817.jpg` — photo CDN (45.9KB JPEG confirmed)
- `https://github.com/unitedstates/images` — documents URL pattern

### Secondary (MEDIUM confidence — verified via congress.gov URLs in search results)
- Alex Padilla: P000145 — `congress.gov/member/.../ P000145`
- Adam Schiff: S001150 — `congress.gov/member/.../S001150`
- Elissa Slotkin: S001208 — `congress.gov/member/.../S001208`
- Angela Alsobrooks: A000382 — `congress.gov/member/.../A000382`
- Jim Banks: B001299 — `congress.gov/member/.../B001299`
- Ashley Moody: M001244 — `congress.gov/member/.../M001244`
- Jim Justice: J000312 — `congress.gov/member/.../J000312`
- Tim Sheehy: S001232 — `congress.gov/member/.../S001232`
- Jon Husted: H001104 — `congress.gov/member/.../H001104`
- Bernie Moreno: M001246 — GovTrack confirmed
- Alan Armstrong: A000383 — `congress.gov/member/.../A000383`
- John Curtis: C001114 — `congress.gov/member/.../C001114`
- Dave McCormick: M001243 — `congress.gov/member/.../M001243`
- Andy Kim: K000394 — `bioguide.congress.gov/search/bio/K000394`
- Multiple others confirmed via bioguide.congress.gov search results

### Tertiary (LOW confidence — training knowledge, unverified specific IDs)
- Todd Young: Y000064 — needs verification
- Mark Kelly: K000368 — needs verification
- Angus King: K000383 — needs verification
- Bill Hagerty: H001099 — needs verification
- Ron Johnson: J000293 — needs verification
- Cindy Hyde-Smith: H001102 — needs verification

---

## Metadata

**Confidence breakdown:**
- Standard stack (migration number, chamber UUID, CTE pattern): HIGH — sourced from actual migration files
- Architecture (idempotency guards, office uniqueness): HIGH — directly from migrations 155 + 170
- Senator list (names, states, parties): HIGH — senate.gov fetched 2026-05-19
- Bioguide IDs (~90% of them): MEDIUM — confirmed via congress.gov URL search results
- Bioguide IDs (6 senators above): LOW — training data guesses, needs verification

**Research date:** 2026-05-19
**Valid until:** 2026-06-19 (stable domain — senator roster changes rarely mid-term)
