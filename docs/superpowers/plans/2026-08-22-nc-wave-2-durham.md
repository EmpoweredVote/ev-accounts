# NC Wave 2 — Durham City + Durham County Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Seat Durham's 15 elected officials — 7 city, 8 county — on address-reachable geometry, so a Durham address returns its full local government.

**Architecture:** Load NC's TIGER `place` layer for the city polygon, then two migrations: structure (one `LOCAL` district + 15 offices) and occupancy (15 politicians + 15 terms). The roster is a hand-verified, per-person-sourced `ROSTERS.md` rather than a programmatic builder — 15 seats across two bodies with no machine-readable roster API is the Austin/Travis shape, not the 170-seat NC General Assembly shape.

**Tech Stack:** TypeScript/Node 24, `tsx`, vitest, `psql` against the Supabase session pooler, PostGIS, TIGER shapefiles.

**Spec:** [`.planning/todos/2026-08-21-nc-durham-asheville-deep-seed.md`](../../../.planning/todos/2026-08-21-nc-durham-asheville-deep-seed.md) (wave 2)

**Scope decided 2026-08-22:** 5 at-large commissioners **plus** Sheriff, Register of Deeds, and Clerk of Superior Court. Excludes judges (`JUDICIAL` type, own scale) and the District Attorney (elected by *prosecutorial district*, not county — needs its own geography check before it can be seated honestly).

## Global Constraints

- **`cwd` resets between Bash calls.** Prefix every command `cd /c/EV-Accounts/backend &&` in the *same* compound command.
- **Migration slots: `CA_0006` (structure) and `CA_0007` (incumbents).** `CA_0001`–`CA_0005` exist. Cite slots in full.
- 🔴 **Dry-running a migration here — the naive recipe SILENTLY APPLIES.** 1497 of 1764 migrations self-wrap in `BEGIN;`/`COMMIT;`, so `BEGIN; \i file; ROLLBACK;` lets the file's own `COMMIT` close the outer transaction. **This cost a real un-rehearsed apply on `CA_0004` on 2026-08-22.** Instead:

  ```bash
  grep -vE '^(BEGIN|COMMIT);$' migrations/CA_000N_x.sql > body.sql
  # BEGIN; \i C:/abs/windows/path/body.sql ; <count queries>; ROLLBACK;
  # psql's \i needs a WINDOWS path — a /c/... path fails "No such file or directory".
  ```

  Then **prove reversion with a separate query afterwards.** The tell for a failed rehearsal is `WARNING: there is no transaction in progress`.
- **Every migration is idempotent** and ends with a `DO $$ ... $$` post-verify gate that `RAISE EXCEPTION`s on a wrong count.
- **Never cache "current".** Occupancy is `essentials.office_terms`, read via `essentials.office_current_holder`.
- **Don't invent dates.** Year-only → `start_precision => 'year'`; genuinely unknown → `'unknown'` with a NULL `term_start`.
- **No party affiliation on any officeholder.** Party lives on `races.primary_party`.
- **Commit with a pathspec** — `git commit -F msg -- <path>`. Parallel sessions sweep each other's staged files.
- 🔴 **Branch: `feat/nc-wave2-durham`, cut from `feat/nc-deep-seed` — NOT from `origin/master`.**
  Verified 2026-08-22: `origin/master` contains **neither** the `NC:` entry in `STATE_LAYER_ALLOWLIST`
  **nor** `EXPECTED_NC_MTFCC` (both `grep -c` → 0). Both landed in wave 1, which is still open as
  PR #136. Branching from master would silently lose the NC allowlist and the `--dry-run` gate fix,
  and Task 1 Step 2's red test would fail for the wrong reason.
  **Consequence:** wave 2's PR stacks on #136 and must be merged after it. If #136 merges first,
  rebase onto the new `origin/master` before opening wave 2's PR.

### 🔴 The identity rule for this wave — read before writing any politician insert

**Do NOT guard politician inserts on `full_name` alone.** The Austin migration (`1828_austin_travis_seating.sql:181-205`) does exactly that, and copying it here seats the wrong person **silently**.

Measured in prod on 2026-08-22:

| Name in prod | Who | `external_id` |
|---|---|---|
| `Mike Lee` | **US Senator, Utah** | `-400077` |
| `Michael V. Lee` | NC Senate District 7 (seated by wave 1) | `-3710007` |

Durham County's board chair is **Dr. Michael 'Mike' Lee** — a *third* person. Under a bare
`WHERE NOT EXISTS (SELECT 1 FROM politicians p WHERE p.full_name = pp.full_name)` guard, storing him
as "Mike Lee" means: no row is inserted (the name exists), Austin's 1:1 assertion **passes** (exactly
one match), and seating resolves to the **Utah senator** — putting a sitting US Senator on the Durham
County Board of Commissioners with nothing erroring. Wave 1 escaped this only because ncleg
publishes the NC senator's middle initial.

Therefore:

1. **Every Durham politician gets an explicit `external_id`** in the free band `-(3730000 + n)`,
   verified free 2026-08-22 (0 rows in `-3739999..-3730000`). Guard inserts on `external_id`
   (`ON CONFLICT (external_id) DO NOTHING` against the real unique index from migration 191),
   never on name.
2. **Add a cross-state homonym assertion** to the gate: no politician seated on a Durham office may
   simultaneously hold an office whose district `state` is not `nc`. Fail loudly if one does.
3. Record the disambiguation in `ROSTERS.md` explicitly — this trap will recur in Asheville (wave 3).

---

### Task 1: Load the NC `place` layer

Delivers Durham's city polygon. **`place` has `writeDistrictRow: false`** — the loader writes only
`geofence_boundaries`, so the `districts` row is created by `CA_0006`, not here.

**Files:**
- Modify: `backend/scripts/load-state-tiger-boundaries.ts` (add `place` to NC's `EXPECTED_NC_MTFCC`)
- Create: `backend/scripts/verify-nc-place-import.sql`

**Interfaces:**
- Consumes: nothing. NC is already in `STATE_LAYER_ALLOWLIST` as `['sldu','sldl','place']` — the entry needs no change, only the expected-count table does.
- Produces: `essentials.geofence_boundaries` rows with `mtfcc='G4110'`, `state='37'`, including `geo_id='3719000'` (Durham city). `CA_0006` joins on that `geo_id`.

- [ ] **Step 1: Add the expected count, deliberately WRONG first**

Add `place` to the existing `EXPECTED_NC_MTFCC` table beside NC's assertion block. Set it to a
deliberately wrong value (e.g. `999`) for the red half of the test.

The correct value is **552** — measured from raw TIGER 2024 FIPS 37 on 2026-08-21: 776 total records
= **552 `G4110` incorporated places** + 224 `G4210` CDPs. The loader already filters to `G4110` only
(`load-state-tiger-boundaries.ts:755`, `:804`), so the assertion counts G4110.

🔴 **The 224 CDPs must never be loaded.** A CDP is a Census statistical area, not a government.
Loading them invents 224 fake municipalities with no elected officials — offices that would be
invisible and unfixable.

- [ ] **Step 2: Dry-run and watch it FAIL**

Run: `cd /c/EV-Accounts/backend && npx tsx scripts/load-state-tiger-boundaries.ts --state NC --fips 37 --layers place --dry-run`

Expected: **FAILS** with `expected 999 records, got 552`. Since wave 1's fix, `--dry-run` genuinely
downloads and asserts, so this failure is real evidence the gate is live.

- [ ] **Step 3: Correct to 552 and re-run**

Expected: `PASSED: 552 records`. No DB writes.

- [ ] **Step 4: Load for real** *(controller-only if prod writes are reserved)*

Run: `cd /c/EV-Accounts/backend && npx tsx scripts/load-state-tiger-boundaries.ts --state NC --fips 37 --layers place`

⚠️ **This load WILL require a matview refresh**, unlike wave 1. Places nest inside counties, so they
are child boundaries. The loader prints an `ACTION REQUIRED` notice; wave 1 correctly ignored it
because `sldu`/`sldl` cross county lines, but **for `place` it is real**:

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY essentials.geofence_child_county;
```

Requires matview ownership — run as `postgres`, not `ev_api`. Then confirm `npm run check:child-county`
reports `stale 0`, which CI enforces on every push.

- [ ] **Step 5: Write and run the verification SQL**

Create `backend/scripts/verify-nc-place-import.sql` asserting: `G4110` count = 552; `G4210` count = 0
(**proves the CDP filter held**); Durham city `3719000` present with `FUNCSTAT` A; and a point-in-polygon
check that Durham City Hall (`-78.8996816092, 35.996066837243`) falls inside `3719000`.

- [ ] **Step 6: Commit**

---

### Task 2: Verified roster — 15 seats, per-person sources

**Files:**
- Create: `backend/data/seed-durham-2026/ROSTERS.md`

Model on `backend/data/seed-austin-2026/ROSTERS.md`: numbered source table, an explicit
**"Source defects found"** section, then a row per seat. **No database writes to produce this file.**

**Interfaces:**
- Consumes: nothing.
- Produces: for each of 15 seats — `body`, `office_title`, `full_name`, name parts, `assumed_office`
  (ISO), `precision` (`day`/`year`/`unknown`), `how_started` (`elected`/`appointed`/`unknown`),
  `external_id`, and the source ID establishing each. Task 3 reads these.

**Known starting facts** (verified 2026-08-22 — re-verify, don't re-derive):

City of Durham — 7 seats, **all elected citywide**, sworn in **2025-12-01**:

| Seat | Member | Note |
|---|---|---|
| Mayor | Leonardo "Leo" Williams | elected 2023; began 2nd 2-yr term Dec 2025 |
| Ward 1 | Matt Kopac | new Dec 2025 |
| Ward 2 | Shanetta Burris | new Dec 2025 |
| Ward 3 | Chelsea Cook | **appointed 2024**, then elected 2025 |
| At-Large | Javiera Caballero | **appointed 2018**, elected 2019 |
| At-Large | Nate Baker | elected 2023 |
| At-Large | Carl Rist | elected 2023 |

Durham County — 8 seats, **all elected countywide**:

| Seat | Member | Note |
|---|---|---|
| Commissioner (Chair) | Dr. Michael "Mike" Lee | sworn **2024-12-02**; elected Chair 2025 |
| Commissioner (Vice-Chair) | Nida Allam | incumbent, retained 2024 |
| Commissioner | Michelle Burton | new 2024 |
| Commissioner | Stephen Valentine | new 2024 |
| Commissioner | Wendy Jacobs | incumbent, retained 2024 |
| Sheriff | Clarence F. Birkhead | **establish assumed-office date** |
| Register of Deeds | *to establish* | on the 2024 ballot |
| Clerk of Superior Court | *to establish* | on the 2026 ballot |

🔴 **`term_start` means the day this person began holding THIS seat — not the start of the current term.**
Continuous service through a re-election is ONE term row. So Chelsea Cook's `term_start` is her **2024
appointment** with `how_started='appointed'`, not her 2025 election; Javiera Caballero's is her **2018
appointment**. Getting this wrong understates tenure for two real people.

🔴 **Chair and Vice-Chair are board roles, not separate offices.** Durham County has five commissioner
seats; the chairmanship rotates by board vote. Do **not** create a "Chair" office — record it in the
title or a note if at all, and never as a sixth seat.

- [ ] **Step 1: Establish the two unknown county officials** (Register of Deeds, Clerk of Superior Court) from the county's own site and the NC State Board of Elections, not from a single secondary source.
- [ ] **Step 2: Establish an assumed-office date for all 15**, with precision. Prefer the swearing-in date. Where only a year is available use `'year'`; where genuinely unknown write NULL / `'unknown'` — **never a guess**.
- [ ] **Step 3: Record the Mike Lee disambiguation** explicitly, with the two colliding prod rows and their `external_id`s, so the next reader cannot miss it.
- [ ] **Step 4: Cross-check every name against prod** for cross-state homonyms:

```sql
SELECT p.full_name, d.state, d.label, p.external_id
FROM essentials.politicians p
LEFT JOIN essentials.office_current_holder och ON och.politician_id = p.id
LEFT JOIN essentials.offices o ON o.id = och.office_id
LEFT JOIN essentials.districts d ON d.id = o.district_id
WHERE lower(p.full_name) IN ( /* the 15 names, lowercased */ );
```

Any hit outside `nc` is a homonym to document, **never** a row to reuse.
- [ ] **Step 5: Commit** the roster file.

---

### Task 3: Generate `CA_0006` and `CA_0007`

**Files:**
- Create: `backend/scripts/gen-durham-migrations.mjs`
- Output: `migrations/_wip_durham_structure.sql`, `migrations/_wip_durham_incumbents.sql`

**Interfaces:**
- Consumes: `data/seed-durham-2026/ROSTERS.md` (or a JSON the same task emits from it).
- Produces: two `_wip_` SQL files. Tasks 4 and 5 rename them into `CA_0006` / `CA_0007`.

**Structure migration (`CA_0006`) must:**

- Insert **one** `LOCAL` district: `geo_id '3719000'`, `state 'nc'`, label **`Durham Citywide`**.
  🔴 Follow the **Bainbridge Island Citywide** precedent (`5303736`, **7 offices** — the same shape as Durham's council), **not** Austin's.
  Austin's council is genuinely district-elected, so it has 10 separate district rows; Durham's
  entire council is elected citywide, so all 7 seats hang off this single district.
- Insert 7 city offices on that district, and 8 county offices on the **existing** `37063` district
  (`NOT EXISTS`-guarded; do not create the county district).

  🔴 **`geo_id '37063'` is claimed by TWO districts — pairing with `district_type` is MANDATORY.**
  Measured in prod 2026-08-22:

  ```
  COUNTY      | Durham County           | 37063 | 0 offices
  STATE_LOWER | State House District 63 | 37063 | 1 office   <- seated by wave 1
  ```

  NC House District 63's geo_id is `'37'||lpad(63,3,'0')` = `37063`, byte-identical to Durham
  County's FIPS. A bare `geo_id = '37063'` lookup matches both, and would attach the Sheriff,
  Register of Deeds, Clerk and 5 commissioners to **a state house district** — or fan out to 16
  offices — while an "8 offices created" count still looks correct. Every county join must read:

  ```sql
  JOIN essentials.districts d
    ON d.geo_id = '37063' AND d.district_type = 'COUNTY' AND lower(d.state) = 'nc'
  ```
- 🔴 Set `representation_note` on the **3 ward seats**, in the Bainbridge house style but adjusted:
  Bainbridge wards *nominate* in the primary; **Durham's do not affect voting at all.** The city's own
  wording is *"The candidate is, however, elected by all city voters. Wards do not affect where a
  resident votes or which candidate(s) a resident can vote for."* So the note must say the ward is a
  **residency requirement only** — do not copy Bainbridge's "residency and nomination" phrasing, which
  would assert a primary restriction Durham does not have.
  `representation_note` on a `voting_powers='full'` seat is permitted (CHECK requires it only when
  powers are not full) and there are 10 existing precedents.
- End with a post-verify gate asserting: 1 new `LOCAL` district; 7 offices on `3719000`; 8 on the
  `COUNTY` row for `37063`; 3 ward offices carrying a non-null `representation_note`; **0** offices
  on a district lacking geometry; and **0** districts carrying an unexpected office count.

  🔴 **Plus the assertion that actually catches the collision:** after `CA_0006` runs,
  `STATE_LOWER` district `37063` must still carry **exactly 1** office — its Representative.

  ```sql
  SELECT count(*) INTO n_hd63 FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '37063' AND d.district_type = 'STATE_LOWER';
  IF n_hd63 <> 1 THEN RAISE EXCEPTION
    'CA_0006: NC House District 63 carries % offices, expected 1 — county offices cross-wired onto the house district', n_hd63; END IF;
  ```

  Counting offices on the county row alone would **not** notice offices landing on the house
  district; only this assertion does.

**Incumbents migration (`CA_0007`) must:** insert 15 politicians guarded on `external_id`, seat each
via `seat_officeholder` (passing `how_started` and `start_precision` explicitly — do **not** let
`p_how_started` fall through to its `'elected'` default for appointees), and gate on: 15 seated,
the appointed count matching the roster, and **the cross-state homonym assertion** from the identity
rule above.

- [ ] **Step 1: Write the generator**, modelled on `scripts/gen-nc-legislature-migrations.mjs`.
- [ ] **Step 2: Generate, then READ the emitted SQL** and check names with apostrophes (`O'…`), quoted nicknames (`Dr. Michael "Mike" Lee`) and any non-ASCII survive verbatim. Confirm the file is UTF-8 **without BOM** — a mojibaked name is voter-facing.
- [ ] **Step 3:** `npm run check:occupancy` — catches any write to the dropped `offices.politician_id`.
- [ ] **Step 4: Commit** the generator.

---

### Task 4: Apply `CA_0006` (structure)

- [ ] **Step 1:** `git fetch origin && npm run check:migrations`; confirm `CA_0006` is still free.
- [ ] **Step 2:** Rename `_wip_durham_structure.sql` → `CA_0006_durham_structure.sql`; update self-references and the forward-reference to `CA_0007`.
- [ ] **Step 3: Rehearse using the CORRECTED recipe** from Global Constraints — strip `BEGIN;`/`COMMIT;` into a body copy, wrap that, run count queries, `ROLLBACK`.
- [ ] **Step 4: Prove reversion** with a separate query (expect 0 Durham `LOCAL` districts, 0 offices on `3719000`). **A printed `ROLLBACK` is not proof.**
- [ ] **Step 5: Apply for real.**
- [ ] **Step 6: Re-run to prove idempotency** — second run must be a no-op.
- [ ] **Step 7: Commit.**

---

### Task 5: Apply `CA_0007` (incumbents)

- [ ] **Step 1:** Re-verify the `external_id` band `-3739999..-3730000` is still 0 rows.
- [ ] **Step 2:** Rename into `CA_0007_durham_incumbents.sql`; rehearse with the corrected recipe; prove reversion.
- [ ] **Step 3: Apply for real.**
- [ ] **Step 4: Verify the homonym guard actually held:**

```sql
SELECT p.full_name, p.external_id, d2.state AS other_state, d2.label AS other_office
FROM essentials.politicians p
JOIN essentials.office_current_holder och ON och.politician_id = p.id
JOIN essentials.offices o ON o.id = och.office_id
JOIN essentials.districts d ON d.id = o.district_id AND d.geo_id IN ('3719000','37063')
JOIN essentials.office_current_holder och2 ON och2.politician_id = p.id
JOIN essentials.offices o2 ON o2.id = och2.office_id
JOIN essentials.districts d2 ON d2.id = o2.district_id AND lower(d2.state) <> 'nc';
```

Expected: **0 rows.** Any row means a Durham seat resolved to an out-of-state politician — the Mike Lee failure. Stop and fix before proceeding.
- [ ] **Step 5:** `npm run check:occupancy`, and confirm `offices_missing_terms` unflagged is **still 655** — 15 new offices must all have terms.
- [ ] **Step 6: Commit.**

---

### Task 6: End-to-end acceptance

- [ ] **Step 1: Probe Durham City Hall** (`-78.8996816092, 35.996066837243`) and confirm it returns **all 15** new officials plus wave 1's HD-30 (Marcia Morey) and SD-22 (Sophia Chitlik).
- [ ] **Step 2: Negative control** — a point outside Durham city but inside Durham County (e.g. rural county) must return the **8 county** officials and **zero city** officials. Then run the control-of-the-control: the same query at Durham City Hall must return the 7 city seats, proving the query can fire.
- [ ] **Step 3: Confirm the ward seats are not treated as constituencies** — the probe must return all 3 ward members for ANY Durham city address, never one.
- [ ] **Step 4: Gate suite** — `check:migrations`, `check:occupancy`, `check:child-county` (**must be `stale 0`** after the place load), `check:reachability`, `typecheck`, `npm test`.
- [ ] **Step 5: Update the spec** — mark wave 2 done, record `CA_0006`/`CA_0007`, and note that wave 3 (Asheville + Buncombe) reuses the place layer loaded here, so it does **not** need to re-run `place`.
- [ ] **Step 6: Commit and open the PR.**

---

## Self-Review

**Spec coverage.** Wave 2's spec bullets map to tasks: `place` G4110-only → Task 1 (with the CDP count asserted at 0); Durham city `LOCAL` district on `3719000` with 7 citywide offices → Task 3/4; county offices on the existing `37063` → Task 3/4; banner/headshots/stances are **deliberately deferred** to wave 2b, because all three attach to politician rows this wave creates.

**Placeholder scan.** Two roster entries are marked *to establish* (Register of Deeds, Clerk of Superior Court) — that is Task 2's explicit job, not an unfilled blank, and Step 1 names where to look.

**Type consistency.** `external_id` band `-(3730000+n)` is asserted in Task 3, re-verified in Task 5 Step 1, and used as the insert guard. `geo_id '3719000'` and `'37063'` are used identically in Tasks 1, 3, 4 and 5.

**The known gap.** Two of 15 assumed-office dates are unestablished at plan time. If either proves genuinely unavailable, the honest record is NULL / `'unknown'` — not a guess, and not a dropped seat.
