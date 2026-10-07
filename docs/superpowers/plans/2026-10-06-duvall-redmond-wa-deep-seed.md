# Duvall + Redmond, WA Deep Seed — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Seat all 16 elected city officials of Duvall and Redmond, Washington, so that an address in either city returns its mayor and council alongside the King County and Washington officials already seeded.

**Architecture:** Four waves. A research wave compiles an evidenced `ROSTERS.md` from King County certified results; two migration waves write structure then occupancy; then headshots and banners. No geography wave — both city polygons are already loaded and were probed with PostGIS.

**Tech Stack:** PostgreSQL / PostGIS on Supabase, hand-applied SQL migrations in `backend/migrations/`, the `steward` slot allocator, and the separate `essentials` React repo for banners and coverage chips.

**Spec:** [`.planning/todos/2026-10-06-duvall-redmond-wa-deep-seed.md`](../../../.planning/todos/2026-10-06-duvall-redmond-wa-deep-seed.md)

## Global Constraints

- **Migration numbers are allocated, never counted:** `npm run steward --prefix backend -- slot CC --purpose "..."`. Name the file that number immediately.
- **Author namespace is `CC_`** (Chris Cantrell). Never `CA_`.
- **Every migration is idempotent** (`IF NOT EXISTS`, `NOT EXISTS` guards, guarded `UPDATE`s) and ends with a `DO $$ ... $$` post-verify gate that `RAISE EXCEPTION`s on a wrong count.
- **Dry-run against production** by wrapping the body `BEGIN; ... ROLLBACK;` and **confirm the rollback reverted** before the real apply.
- **`politicians.is_incumbent` is set explicitly on every insert** — `true` for all 16. It defaults to `false`, and a seated person inserted without it is hidden from address search.
- **`governments.geo_id` AND `governments.mtfcc` must both be set**, or the city is invisible on the landing page even when fully seeded.
- **Commit with an explicit pathspec:** `git commit -F msg -- <path>`.
- **Work in an own worktree:** `git worktree add -b seed/wa-duvall-redmond /c/ev-accounts-wa origin/master`.
- **No stances.** This seed writes no `inform.politician_answers` row, and the coverage chips omit `hasContext`.
- **Party affiliation is never recorded on an officeholder.** These are non-partisan offices; drop party entirely.

## Review Focus

Five things the spec implies that no single task's gate would otherwise catch:

1. **An appointee's term start is the appointment date, not the predecessor's election date.** Four of the 16 seats are appointments. Writing the election date would answer `office_holders_as_of()` with the wrong person for the whole gap. Pinned in Task 2's gate.
2. **A person can hold a seat and have lost a different seat in the same election.** Sara Taylor lost Duvall Position 1 and sits in Position 3; Jennifer Hernandez lost Position 6 and sits in Position 7. A name-matched join against certified results seats them in the losing seat. Pinned in Task 1's gate.
3. **The citywide polygon is shared by eight offices in each city.** A district-rooted join is safe; a politician-rooted join fans out. Any verification query must use `DISTINCT ON (p.id)`. Pinned in Task 3's probe.
4. **`is_vacant` filtering after the match emits a spurious all-NULL office row.** Neither city should carry a vacant office at the end, but the probe must use a derived join so a future vacancy does not silently produce one. Pinned in Task 3's probe.
5. **Duvall Position 5 appears in both the 2023 and 2025 certified results.** It was an unexpired short term followed by a full term. Treating these as two terms breaks continuous occupancy; treating 2023 as the start is correct. Pinned in Task 1.

---

## File Structure

| File | Responsibility |
|---|---|
| `backend/data/seed-duvall-redmond-2026/ROSTERS.md` | The evidenced roster: every seat, holder, term start, and the document that states it. Compiled by hand, consumed by review. |
| `backend/data/seed-duvall-redmond-2026/sources/` | Retrieved certified-result CSVs and roster HTML, kept so a reviewer can re-read what was read. |
| `backend/migrations/CC_NNNN_duvall_redmond_structure.sql` | Wave 1: governments, chambers, districts, offices. |
| `backend/migrations/CC_NNNN_duvall_redmond_occupancy.sql` | Wave 2: politicians and office_terms. |
| `essentials/src/lib/coverage.js` | Wave 4: two coverage chips. Separate repo. |
| `essentials/src/lib/buildingImages.js` | Wave 4: two banners. Separate repo. |

---

### Task 1: Compile the evidenced roster

**Files:**
- Create: `backend/data/seed-duvall-redmond-2026/ROSTERS.md`
- Create: `backend/data/seed-duvall-redmond-2026/sources/` (retrieved CSVs and HTML)

**Interfaces:**
- Consumes: nothing.
- Produces: a table of 16 rows, each with `city`, `office_title`, `position_no`, `full_name`, `term_start` (ISO date), `start_precision`, and `source_id`. Waves 2 reads only this file.

**What is already established** (retrieved 2026-10-06, keep the files):

King County Elections certified results, November 2025 — `webresults-11252025-final.csv`:

| City | Contest | Winner |
|---|---|---|
| Duvall | Mayor | Amy McHenry (64.54%) |
| Duvall | Council Position No. 1 | Adam Olen (64.92%, over Sara Taylor) |
| Duvall | Council Position No. 3 | **Loren Kosloske** (89.52%) |
| Duvall | Council Position No. 5 | Mike Supple (98.48%) |
| Duvall | Council Position No. 6 | Paul Wiggins (65.29%, over Jenn Hernandez) |
| Redmond | Council Position No. 2 | Vivek Prakriya (64.14%) |
| Redmond | Council Position No. 4 | Melissa Stuart (74.49%) |
| Redmond | Council Position No. 6 | Menka Soni (56.90%) |

King County Elections certified results, November 2023 — `webresults-20231127-final.csv`:

| City | Contest | Winner |
|---|---|---|
| Redmond | Mayor | Angela Birney (69.92%) |
| Redmond | Council Position No. 1 | **Osman Salahuddin** (70.37%) |
| Redmond | Council Position No. 3 | Jessica Forsythe (98.43%) |
| Redmond | Council Position No. 5 | Vanessa Kritzer (98.56%) |
| Redmond | Council Position No. 7 | Angie Nuevacamina (53.68%) |
| Duvall | Council Position No. 2 | **Rick Shaffer** (98.86%) |
| Duvall | Council Position No. 4 | Ronn Mercer (98.93%) |
| Duvall | Council Position No. 5 | Mike Supple (98.95%) — unexpired short term |
| Duvall | Council Position No. 7 | **Carol Kufeldt** (80.63%) |

🔴 **Four seats are held by someone the certified results did not elect.** Each is an appointment and each needs its own document:

| Seat | Certified winner | Sitting today | What to find |
|---|---|---|---|
| Redmond Pos 1 | Osman Salahuddin | **Sayna Parsi** | Salahuddin's resignation date and Parsi's appointment date |
| Duvall Pos 2 | Rick Shaffer | **Linda Conway** | Shaffer's departure and Conway's appointment date |
| Duvall Pos 3 | Loren Kosloske | **Sara Taylor** | Kosloske's departure and Taylor's appointment date |
| Duvall Pos 7 | Carol Kufeldt | **Jennifer Hernandez** | Kufeldt's departure and Hernandez's appointment date |

- [ ] **Step 1: Save the two certified CSVs into `sources/`**

```bash
mkdir -p backend/data/seed-duvall-redmond-2026/sources
# 2025 final: https://kingcounty.gov/en/dept/elections/results/2025/november-general -> "Download the results as a .csv file"
# 2023 final: https://kingcounty.gov/en/dept/elections/results/2023/november-general -> "Download the results as a .csv file"
```

⚠ Both CSVs are **cp1252**, not UTF-8 — a UTF-8 read raises `UnicodeDecodeError` on a name with an accent. Read them with `encoding='cp1252'`.

- [ ] **Step 2: Pull the 2021 and 2019 certified results the same way**

Needed only for continuous occupancy — how far back each sitting member has held *that* position. URL pattern: `https://kingcounty.gov/en/dept/elections/results/<year>/november-general`, then the link captioned "Download the results as a .csv file".

Walk each seat back year by year until the sitting member is **absent** from that position. That year's successor election is the term start. Stop there; do not keep walking.

- [ ] **Step 3: Find each of the four appointments**

Primary source is the city council's own minutes, which record the appointment as a motion:

- Duvall: `https://www.duvallwa.gov/` → Government → City Council → Agendas & Minutes
- Redmond: `https://www.redmond.gov/189/City-Council` → Agendas & Minutes

🔴 **An appointment date is the date the appointee takes office, not the date the seat fell vacant, and not the predecessor's election date.** Record both: the predecessor's `term_end` (last day held) and the appointee's `term_start` (first day held). They should be adjacent.

🔴 **Do not use `WebFetch` to source any name or date here.** Use it only to locate a page; read the page itself.

- [ ] **Step 4: Settle whether either city elects a municipal court judge**

Grep both certified CSVs for the city name and read **every** contest, not just the council ones:

```bash
python -c "
import csv
rows=list(csv.DictReader(open('backend/data/seed-duvall-redmond-2026/sources/kc2025nov-final.csv',encoding='cp1252')))
for r in rows:
    if r['District Name'] in ('City of Redmond','City of Duvall'):
        print(r['District Name'],'|',r['Ballot Title'],'|',r['Ballot Response'])
" | sort -u
```

Neither 2025 nor 2023 shows a judicial contest for either city in the data retrieved so far. If 2021 and 2019 also show none, record that as the finding and seat no judge. **A seat that does not exist must not be created**, and an office with no term row is invisible with no error.

🔴 **If a judicial contest IS found, the seat count stops being 16.** Record the new total in `ROSTERS.md` and update the hard-coded `16` in **both** gates — Task 2 Step 5 (`n_off`) and Task 3 Step 6 (`n_seated`). A gate asserting 16 against a 17-seat city fails the apply, which is the safe direction, but the number must be corrected rather than the gate loosened.

- [ ] **Step 5: Settle the Redmond Mayor's vote**

The city page sentence is truncated mid-clause: *"attends and presides over Council meetings but does not vote, except in the"*. Read the Redmond Municipal Code, Title 2.

⚠ `codepublishing.com` returns **HTTP 403 to `curl` even with a browser User-Agent**. Fetch it in Playwright.

Decide and record:
- Mayor votes normally → `voting_powers = 'full'`, `representation_note` may be NULL.
- Mayor presides without a vote except to break a tie → `voting_powers = 'non_voting'` and `representation_note` is **required** by the CHECK, carrying the tie-break power. This is the Nashville Vice Mayor shape.

**Do not default to `full`.**

- [ ] **Step 6: Write `ROSTERS.md` and check it against the two traps**

The file lists 16 rows with a source id per row, and a Sources table giving each document's URL and retrieval date.

Two assertions the file must state explicitly, because both are counter-intuitive and both are real:

1. **Sara Taylor lost Position 1 and sits in Position 3. Jennifer Hernandez lost Position 6 and sits in Position 7.** A name match against certified results seats each in the seat they lost.
2. **Mike Supple's Position 5 appears in both 2023 and 2025.** 2023 was an unexpired short term; 2025 a full term. His continuous occupancy starts at the **2023** term, and that is one term row, not two.

- [ ] **Step 7: Commit**

```bash
git add backend/data/seed-duvall-redmond-2026/
git commit -F msg -- backend/data/seed-duvall-redmond-2026/
```

---

### Task 2: Wave 1 — structure

**Files:**
- Create: `backend/migrations/CC_NNNN_duvall_redmond_structure.sql`

**Interfaces:**
- Consumes: `ROSTERS.md` (seat list only; no people yet).
- Produces: 2 `governments` rows, their `chambers`, 2 `districts` rows, and 16 `offices` rows. Task 3 reads `offices.id` by `(government, title)`.

- [ ] **Step 1: Reserve the slot and name the file immediately**

```bash
npm run steward --prefix backend -- slot CC --purpose "Duvall and Redmond WA city governments, chambers, districts and offices"
```

- [ ] **Step 2: Confirm the polygons are still there before writing anything that depends on them**

```sql
SELECT geo_id, mtfcc, ST_GeometryType(geometry),
       round((ST_Area(geometry::geography)/1e6)::numeric,2) AS sq_km
FROM essentials.geofence_boundaries
WHERE geo_id IN ('5319035','5357535') AND mtfcc = 'G4110';
-- Expect: 5319035 ST_Polygon 6.40 ; 5357535 ST_MultiPolygon 44.65
```

- [ ] **Step 3: Write the migration body**

Two governments, with **both** `geo_id` and `mtfcc`:

```sql
INSERT INTO essentials.governments (name, type, state, city, geo_id, mtfcc)
SELECT 'City of Duvall, Washington, US', 'City', 'WA', 'Duvall', '5319035', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE geo_id = '5319035' AND mtfcc = 'G4110');

INSERT INTO essentials.governments (name, type, state, city, geo_id, mtfcc)
SELECT 'City of Redmond, Washington, US', 'City', 'WA', 'Redmond', '5357535', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE geo_id = '5357535' AND mtfcc = 'G4110');
```

Then, per city: a `City Council` chamber (`official_count` 7, `term_length` 4, `staggered_term` true) and a `Mayor` chamber; one `LOCAL` district per city carrying the citywide `(mtfcc, geo_id)` pair; and the offices — `Mayor`, plus `Councilmember, Position N` for N in 1..7.

Set `offices.voting_powers` and `offices.representation_note` from Task 1 Step 5. **Council President, Council Vice President and Mayor Pro Tempore get no `offices` row** — they are elected from among the members. Record them in the office `description` only.

- [ ] **Step 4: Dry-run against production and confirm the rollback reverted**

```sql
BEGIN;
  -- full migration body here
ROLLBACK;
-- then re-run the Step 5 gate OUTSIDE the transaction and confirm it FAILS,
-- which proves the rollback actually reverted.
```

- [ ] **Step 5: Post-verify gate**

```sql
DO $$
DECLARE n_off int; n_gov int; n_outside int; n_nogeo int;
BEGIN
  SELECT count(*) INTO n_gov FROM essentials.governments
   WHERE geo_id IN ('5319035','5357535') AND mtfcc = 'G4110';
  IF n_gov <> 2 THEN RAISE EXCEPTION 'expected 2 governments, got %', n_gov; END IF;

  SELECT count(*) INTO n_off
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('5319035','5357535') AND g.mtfcc = 'G4110';
  IF n_off <> 16 THEN RAISE EXCEPTION 'expected 16 offices, got %', n_off; END IF;

  SELECT count(*) INTO n_outside
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id IN ('5319035','5357535') AND lower(g.state) <> 'wa';
  IF n_outside <> 0 THEN RAISE EXCEPTION '% offices outside WA', n_outside; END IF;

  -- every district this migration created resolves to exactly one existing boundary
  SELECT count(*) INTO n_nogeo
    FROM essentials.districts d
   WHERE d.geo_id IN ('5319035','5357535') AND d.mtfcc = 'G4110'
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  IF n_nogeo <> 0 THEN RAISE EXCEPTION '% districts with no boundary', n_nogeo; END IF;
END $$;
```

- [ ] **Step 6: Apply, then commit with a pathspec**

```bash
git commit -F msg -- backend/migrations/CC_NNNN_duvall_redmond_structure.sql
```

---

### Task 3: Wave 2 — occupancy

**Files:**
- Create: `backend/migrations/CC_NNNN_duvall_redmond_occupancy.sql`

**Interfaces:**
- Consumes: `offices.id` from Task 2; term starts from `ROSTERS.md`.
- Produces: 16 `politicians` rows and 16 `office_terms` rows.

- [ ] **Step 1: Reserve the slot**

```bash
npm run steward --prefix backend -- slot CC --purpose "Duvall and Redmond WA officeholders and terms"
```

- [ ] **Step 2: Record the baseline before writing**

```sql
SELECT count(*) FILTER (WHERE NOT is_vacant) AS unflagged
FROM essentials.offices_missing_terms;
-- Expect 239. If it is not 239, STOP and find out why before continuing.
```

- [ ] **Step 3: Check every name against the duplicate-name guard first**

```sql
SELECT id, full_name, first_name, last_name, is_incumbent, is_active
FROM essentials.politicians
WHERE (first_name, last_name) IN (
  ('Amy','McHenry'),('Adam','Olen'),('Linda','Conway'),('Sara','Taylor'),
  ('Ronn','Mercer'),('Mike','Supple'),('Paul','Wiggins'),('Jennifer','Hernandez'),
  ('Angela','Birney'),('Sayna','Parsi'),('Vivek','Prakriya'),('Jessica','Forsythe'),
  ('Melissa','Stuart'),('Vanessa','Kritzer'),('Menka','Soni'),('Angie','Nuevacamina'));
```

🔴 The guard keys on `(first_name, last_name)`, not `full_name`. A hit has two opposite right answers — **read what the row is**. `Sara Taylor`, `Melissa Stuart` and `Jennifer Hernandez` are common enough to expect a hit that is a different person in another state. Reuse a row only when it is the same person.

- [ ] **Step 4: Insert the people, with `is_incumbent` explicit**

```sql
INSERT INTO essentials.politicians (full_name, first_name, last_name, is_incumbent, is_active, data_source)
SELECT 'Amy McHenry','Amy','McHenry', true, true, 'CC_NNNN duvall redmond deep seed'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians
                   WHERE first_name='Amy' AND last_name='McHenry' AND data_source LIKE 'CC_NNNN%');
-- ... one block per person. is_incumbent = true on all 16.
```

Do **not** write `politicians.office_id`, `valid_from` or `valid_to` — all three are deprecated.

- [ ] **Step 5: Seat each person with the helper, never by hand**

```sql
SELECT essentials.seat_officeholder(
  (SELECT o.id FROM essentials.offices o
     JOIN essentials.chambers c ON c.id=o.chamber_id
     JOIN essentials.governments g ON g.id=c.government_id
    WHERE g.geo_id='5319035' AND g.mtfcc='G4110' AND o.title='Mayor'),
  (SELECT id FROM essentials.politicians WHERE first_name='Amy' AND last_name='McHenry'),
  DATE '2026-01-01',
  'King County Elections certified results, 2025-11-25; City of Duvall mayor page, retrieved 2026-10-06');
```

Use the term start from `ROSTERS.md`, not the election date. For a start known only to the year, pass January 1 with `start_precision => 'year'`. **Never invent a date.**

- [ ] **Step 6: Post-verify gate**

```sql
DO $$
DECLARE n_seated int; n_unflagged int; n_vac int;
BEGIN
  SELECT count(och.politician_id) INTO n_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id=o.chamber_id
    JOIN essentials.governments g ON g.id=c.government_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.geo_id IN ('5319035','5357535') AND g.mtfcc='G4110';
  IF n_seated <> 16 THEN RAISE EXCEPTION 'expected 16 seated, got %', n_seated; END IF;

  SELECT count(*) FILTER (WHERE NOT is_vacant) INTO n_unflagged
    FROM essentials.offices_missing_terms;
  IF n_unflagged <> 239 THEN
    RAISE EXCEPTION 'offices_missing_terms unflagged moved to % (baseline 239)', n_unflagged;
  END IF;

  SELECT count(*) INTO n_vac
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id=o.chamber_id
    JOIN essentials.governments g ON g.id=c.government_id
   WHERE g.geo_id IN ('5319035','5357535') AND o.is_vacant;
  IF n_vac <> 0 THEN RAISE EXCEPTION '% offices flagged vacant', n_vac; END IF;
END $$;
```

🔴 `office_current_holder` LEFT JOINs from `offices`, so `count(*)` would pass vacuously on an empty result. The gate counts `och.politician_id`.

- [ ] **Step 7: Assert each appointee's start is NOT the predecessor's election date**

```sql
-- Review Focus #1. Each of these four must be an appointment date in 2024-2026,
-- strictly LATER than the January after the election their predecessor won.
SELECT p.full_name, o.title, g.city, t.term_start, t.start_precision, t.source
  FROM essentials.office_terms t
  JOIN essentials.politicians p ON p.id = t.politician_id
  JOIN essentials.offices o ON o.id = t.office_id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
 WHERE (g.city, o.title) IN
       (('Redmond','Councilmember, Position 1'), ('Duvall','Councilmember, Position 2'),
        ('Duvall','Councilmember, Position 3'), ('Duvall','Councilmember, Position 7'))
   AND t.term_end IS NULL;
-- Each term_start must be the APPOINTMENT date from council minutes,
-- never 2024-01-01 or 2026-01-01.
```

- [ ] **Step 8: Live probe — the only reliable detector is end to end**

Resolve a real address in each city through the running API, not through SQL:

- A Duvall address returns **Amy McHenry** and seven Duvall councilmembers.
- A Redmond address returns **Angela Birney** and seven Redmond councilmembers.
- The Duvall address returns **no** Redmond official, and the reverse.
- A Seattle address (the control) returns **neither** city's officials.

🔴 Use `DISTINCT ON (p.id)` in any politician-rooted verification query — eight offices in each city share one polygon, and a politician-rooted join fans out (Review Focus #3).

- [ ] **Step 9: Apply, then commit with a pathspec**

---

### Task 4: Wave 3 — headshots

**Files:**
- Modify: `essentials.politicians.photo_custom_url` for the 16, via a migration or the import tooling.

- [ ] **Step 1: Collect candidate portraits from official and press sources only**

City staff-directory pages first: Duvall `Directory.aspx?EID=<n>` (per-member pages are linked from `/166/City-Council`), Redmond `/directory/employee?eid=<n>` (ids 859, 886, 940, 985, 1014, 1015, 1016 observed 2026-10-06).

Second source: the **Washington voters' pamphlet API**, which carries filed candidate photographs:

- Index: `voter.votewa.gov/elections/voterguide.ashx?e=<el>&la=en&c=&p=XX`
- Per candidate: `.../candidate.ashx?e=<el>&r=<RaceID>&b=<BallotID>&la=en`

🔴 **`&la=en` is required.** Without it the same URL returns the SPA shell with HTTP 200.

- [ ] **Step 2: Build a contact sheet with a PER-IMAGE `alt` naming the person**

A sheet without a per-image `alt` is blind when the wrong person is also plausible. Skip monochrome — no-monochrome is enforced in code. Crop to roughly one ear above the hair.

- [ ] **Step 3: Get the sheet approved before publishing anything**

- [ ] **Step 4: Write `photo_custom_url`**

🔴 `photo_custom_url` is what renders. A `politician_images` row alone changes nothing a voter sees. **A blank beats a wrong or unverified face.**

- [ ] **Step 5: Commit with a pathspec**

---

### Task 5: Wave 4 — banners and coverage chips

**Files:**
- Modify: `essentials/src/lib/buildingImages.js` (separate repo)
- Modify: `essentials/src/lib/coverage.js` (separate repo)

- [ ] **Step 1: Read the Washington state banner in the 6:1 band first**

Adjacency is composition. The state banner sets what the two city banners must not duplicate.

- [ ] **Step 2: Certify each city banner in the 6:1 band, and look at the asset itself**

`banners.json` is generated and CI-enforced. Run the matcher in Vite.

- [ ] **Step 3: Add the two coverage chips under a Washington block, `hasContext` OMITTED**

```javascript
{ label: 'Duvall',  browseGovernmentList: ['5319035'], browseStateAbbrev: 'WA' },
{ label: 'Redmond', browseGovernmentList: ['5357535'], browseStateAbbrev: 'WA' },
```

`hasContext` is omitted because this seed writes no stances. Do not set it to `true`.

- [ ] **Step 4: Verify the chips resolve**

A landing chip is keyed on `governments.geo_id`, which address search never touches. A city can answer every address and still be invisible on the main page. Click both chips on the deployed site.

- [ ] **Step 5: Commit in the essentials repo with a pathspec**

---

## Closing measurements

```bash
git fetch origin
npm run check:migrations  --prefix backend
npm run check:occupancy   --prefix backend
npm run check:reservations --prefix backend
npm run steward --prefix backend -- sync
```

```sql
SELECT count(*) FILTER (WHERE NOT is_vacant) FROM essentials.offices_missing_terms;  -- must be 239
```

Release the leases when the work is done:

```bash
npm run steward --prefix backend -- release place:5319035
npm run steward --prefix backend -- release place:5357535
```
