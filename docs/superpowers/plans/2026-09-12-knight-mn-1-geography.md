# Knight MN-1 — Minnesota legislative and place geography

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Load Minnesota's 67 Senate districts, 134 House districts and two Knight place polygons
(Duluth, Saint Paul) into `essentials.geofence_boundaries` and `essentials.districts`, proved to be
the **L2022** enacted plan rather than merely proved to be 67 and 134 rows.

**Architecture:** No new loader. `scripts/load-state-tiger-boundaries.ts` is a state-parameterised
TIGER loader whose `STATE_LAYER_ALLOWLIST` deliberately omits Minnesota — adding a state is a code
change *on purpose*, so that someone reviews which layers are safe for it. Task 2 is that review.
Verification follows the FL-1 shape: identity anchors resolved against the **enacted plan**,
independent of TIGER, because a correct record count proves nothing about which map arrived.

**Tech Stack:** TypeScript + `tsx`, `pg`, `shapefile`, `adm-zip`; PostGIS; `psql "$DATABASE_URL"`
for read-only verification; TIGERweb ArcGIS REST for anchor resolution.

**Spec:** [`docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`](../specs/2026-08-28-knight-cities-program-design.md)
(stage 1 of §3; gates in §5). State notes and the measured baseline:
[`.planning/knight-foundation/mn.md`](../../../.planning/knight-foundation/mn.md).

## Global Constraints

Copied from spec §4.1 and CLAUDE.md. Every task's requirements implicitly include this section.

- **`outSR=4326` is load-bearing on every ArcGIS fetch.**
- **Always pair `geo_id` with `district_type` in a join. Never match a district on `label`.**
- **Always `lower(d.state)`** — `essentials.districts.state` is mixed case.
- **`essentials.geofence_boundaries.state` holds 2-digit FIPS.** Minnesota is **`27`**, never `MN`.
- **`cwd` resets between Bash calls.** Prefix every command with `cd /c/EV-Accounts/backend &&`.
- **`ev_api` cannot create objects in `essentials`.** This wave is DML only, so `psql` works. Do not
  use the Supabase MCP for a write — it wraps each call in its own transaction, which destroys the
  `BEGIN … ROLLBACK` dry-run.
- **Migration numbers are ALLOCATED, never counted:**
  `npm run steward --prefix backend -- slot CC --purpose "..."`, then name the file that number at
  once. ⚠ This **supersedes spec §4.1's "take the migration number last"**, which predates the
  allocator. CI fails a migration whose slot nobody reserved.
- **`office_current_holder` LEFT JOINs from `offices`**, so a vacancy is a NULL `politician_id`.
  Seated counts use `count(och.politician_id)`, never `count(*)`.
- **Run a positive control on any detector that reports "nothing found."** MN-1 has already paid for
  this rule twice — see `mn.md` traps 4 and 5.

---

### Task 1: Resolve the L2022 identity anchors, independent of TIGER

Nothing else in this plan can be trusted without this. FL-1's verify file states the reason plainly:
*"a correct record count proves nothing about WHICH map you have."* Minnesota last redistricted under
*Wattson v. Simon*, ordered **2022-02-15**, and TIGER vintages before that carry the 2012 plan with
the same 67/134 shape and the same `1A`/`1B` labels. **The two maps are indistinguishable by count.**

**Files:**
- Create: `backend/data/seed-mn-2026/anchors-L2022.json`
- Create: `backend/data/seed-mn-2026/SOURCES.md`

**Interfaces:**
- Produces: `anchors-L2022.json`, an array of
  `{ name: string, lon: number, lat: number, sldu: string, sldl: string, source: string }`.
  Task 6 reads it to write the anchor assertions. `sldl` values carry the letter — `"7B"`, not `7`.

- [ ] **Step 1: Find what the state's own lookup tool queries**

`gis.lcc.mn.gov/iMaps/districts/` is the Legislative Coordinating Commission's "Who Represents Me"
app. It publishes no documented REST endpoint. Use GA-5's route — read the page's iframe/JS and find
the service it actually calls:

```bash
cd /c/EV-Accounts/backend && \
curl -sL --max-time 60 "https://gis.lcc.mn.gov/iMaps/districts/" \
  -o data/seed-mn-2026/_lcc-districts.html -w "http=%{http_code} bytes=%{size_download}\n"
grep -oE 'https?://[^"'"'"' ]*(arcgis|MapServer|FeatureServer|rest/services)[^"'"'"' ]*' \
  data/seed-mn-2026/_lcc-districts.html | sort -u
```

Expected: one or more ArcGIS REST URLs. If the grep is empty, that is a **negative result about the
HTML only** — the app may load its config from a separate JS bundle. Follow every `<script src>` on
the page before concluding the endpoint is not published.

⚠ If the host 403s a plain `curl`, fetch it in Playwright. A WAF rejection here can arrive as HTTP
200 or 202, so judge by the body, never by the status.

- [ ] **Step 2: Confirm the service is L2022 and not the 2012 plan**

Read the layer's own metadata (`?f=json`) and record `name`, `description` and any vintage field.
The plan's own publisher page is the arbiter:
`https://gis.lcc.mn.gov/redist2020/plans.php?plname=L2022&pltype=court`.

**A layer named for 2022 is not proof.** GA-5 found `County_Commissioners_2020` was current and
`CountyDistrict` was stale — *the names were backwards*. Record the evidence you actually used.

- [ ] **Step 3: Resolve three anchors, two of them Knight city halls**

Query the confirmed service at three points. Record the returned Senate and House district for each:

| Anchor | Why |
| --- | --- |
| **Duluth City Hall**, 411 W 1st St, Duluth MN 55802 | stage 3 jurisdiction; the stage-2 probe reuses it |
| **Saint Paul City Hall**, 15 W Kellogg Blvd, Saint Paul MN 55102 | stage 3 jurisdiction |
| **Minnesota State Capitol**, 75 Rev Dr MLK Jr Blvd, Saint Paul MN 55155 | a third point in a different Saint Paul district, so the two Saint Paul anchors cannot both be satisfied by one wrong polygon |

Geocode each to lon/lat first and record the geocoder used. `outSR=4326`.

- [ ] **Step 4: Get a second, independent confirmation for at least two anchors**

FL-1 obtained a government-domain second source for two of three anchors and **recorded plainly that
Bradenton had only one**. Do the same here. Candidates: St. Louis County and Ramsey County election
services; the Secretary of State's pollfinder.

Write `SOURCES.md` naming every source, its URL, its retrieval date, and — explicitly — **any anchor
that has only one source**.

- [ ] **Step 5: Write the anchors file**

```json
[
  {
    "name": "Duluth City Hall",
    "lon": -92.1046,
    "lat": 46.7825,
    "sldu": "<from step 3>",
    "sldl": "<from step 3, WITH its A/B letter>",
    "source": "<service URL + second source, or 'SINGLE SOURCE'>"
  }
]
```

⚠ The lon/lat above are approximate and **must be replaced** with the geocoded values from Step 3.
The `sldu`/`sldl` values are deliberately unfilled — this task exists to determine them, and guessing
them would defeat the whole task.

- [ ] **Step 6: Commit**

```bash
cd /c/EV-Accounts && git add backend/data/seed-mn-2026/anchors-L2022.json backend/data/seed-mn-2026/SOURCES.md
git commit -F msg.txt -- backend/data/seed-mn-2026/anchors-L2022.json backend/data/seed-mn-2026/SOURCES.md
```

---

### Task 2: Add Minnesota to the loader allowlist

**Files:**
- Modify: `backend/scripts/load-state-tiger-boundaries.ts` — `STATE_LAYER_ALLOWLIST`

**Interfaces:**
- Consumes: nothing.
- Produces: `MN` accepted by `--state MN --fips 27 --layers sldu,sldl,place`.

- [ ] **Step 1: Read the neighbouring entries and their comments**

The Wisconsin entry carries a multi-line comment recording *how its vintage was proved* — identity
anchors against TIGERweb, named, with the districts they returned. That comment is the house style
for this table. Read it before writing MN's.

- [ ] **Step 2: Add the entry, with the vintage evidence from Task 1**

```ts
  // MN. sldu/sldl: TIGER must carry L2022 — the plan ordered by the Minnesota Supreme Court
  // Special Redistricting Panel in Wattson v. Simon on 2022-02-15, first effective in 2022.
  // The 2012 plan has the SAME shape: 67 Senate districts, 134 House districts, same 1A/1B
  // labelling. A count of 67/134 therefore distinguishes nothing. Vintage proved by anchors —
  // see backend/data/seed-mn-2026/anchors-L2022.json and SOURCES.md.
  //   <anchor 1> -> SD <n> / HD <nX>
  //   <anchor 2> -> SD <n> / HD <nX>
  //   <anchor 3> -> SD <n> / HD <nX>
  MN: new Set(['sldu', 'sldl', 'place']),
```

⚠ `cd`/`cd119` and `county` are **deliberately excluded**: production already holds 8 MN congressional
districts and all 87 counties (measured 2026-09-12). Loading them again is not idempotent progress,
it is a second chance to introduce a conflicting `geo_id`. `cousub` and `unsd` are out of scope for
this slice.

- [ ] **Step 2b: Add the MN pre-flight assertion block**

The allowlist is only half the entry. Every state also has a `fipsArg === '<fips>'` pre-flight block
in the loader body that asserts its expected record counts and **aborts before any DB write** on a
mismatch. Copy the TN block's shape, and add `MN` to the "every per-state pre-flight assertion above"
list in the comment below it.

⚠ **Measure the counts from the raw `.dbf`, do not take them from statute.** The TN block says so
explicitly. For MN this was done on 2026-09-12 by reading the DBF header record count inside each
TIGER 2024 FIPS 27 zip: **sldu 67, sldl 134, place 915 (855 `G4110` + 60 `G4210` CDPs)**.

- [ ] **Step 3: Verify the entry — NOT with `tsc`**

🔴 **`npm run typecheck` DOES NOT CHECK THIS FILE, AND WILL PASS NO MATTER WHAT YOU WRITE.**
`backend/tsconfig.json` sets `include: ['src*']`, so everything under `scripts/` is outside the
TypeScript project; `lint` is `eslint src`, so nothing lints it either. This was found on 2026-09-12
by planting `ZZ_CONTROL_PLANT: 12345` into `STATE_LAYER_ALLOWLIST` — a `Record<string, Set<string>>`
— and watching `tsc --noEmit` report **0 errors**. An earlier draft of this plan asked for that
typecheck as the verification step. It was a vacuous check.

Verify through the CLI instead, which actually exercises the entry. All three must pass:

```bash
cd /c/EV-Accounts/backend
# 1. MN is registered and the entry parses — expect the --layers demand, not "unknown state"
npx tsx scripts/load-state-tiger-boundaries.ts --state MN --fips 27
#    -> --layers required: specify a comma-separated subset of MN's allowlist

# 2. NEGATIVE CONTROL — an unknown state is refused, and MN appears in the known list
npx tsx scripts/load-state-tiger-boundaries.ts --state ZZ --fips 99
#    -> unknown state: ZZ. Known: CA, TX, UT, IN, MA, ME, OR, MD, VA, NV, AZ, WI, WA, CO, DC, NC, FL, GA, TN, MN

# 3. The deliberate EXCLUSIONS actually bite — not merely documented in a comment
npx tsx scripts/load-state-tiger-boundaries.ts --state MN --fips 27 --layers cousub
#    -> layer 'cousub' not in allowlist for MN. Allowed: sldu, sldl, place
```

▶ **This gap is wider than MN-1.** No script under `backend/scripts/` is typechecked or linted by
CI, and that is most of this program's tooling. Worth raising separately; it is not MN-1's to fix.

- [ ] **Step 4: Commit**

```bash
cd /c/EV-Accounts && git commit -F msg.txt -- backend/scripts/load-state-tiger-boundaries.ts
```

---

### Task 3: Dry-run the `sldu` + `sldl` load

**Files:**
- Create: `backend/data/seed-mn-2026/_dryrun-sldu-sldl.log`

- [ ] **Step 1: Record the pre-load counts**

```bash
cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -c "
SELECT 'geofence G5210' k, count(*) n FROM essentials.geofence_boundaries WHERE state='27' AND mtfcc='G5210'
UNION ALL SELECT 'geofence G5220', count(*) FROM essentials.geofence_boundaries WHERE state='27' AND mtfcc='G5220'
UNION ALL SELECT 'districts STATE_UPPER', count(*) FROM essentials.districts WHERE lower(state)='mn' AND district_type='STATE_UPPER'
UNION ALL SELECT 'districts STATE_LOWER', count(*) FROM essentials.districts WHERE lower(state)='mn' AND district_type='STATE_LOWER';"
```
Expected, per the 2026-09-12 baseline: **0, 0, 0, 0.** If any is non-zero, **stop** — the baseline
has moved and this plan's assumptions need re-measuring.

- [ ] **Step 2: Run the loader with `--dry-run`**

```bash
cd /c/EV-Accounts/backend && \
npx tsx scripts/load-state-tiger-boundaries.ts --state MN --fips 27 --layers sldu,sldl --dry-run \
  2>&1 | tee data/seed-mn-2026/_dryrun-sldu-sldl.log
```
Expected: **67** `sldu` and **134** `sldl` records recognised, 0 inserted.

- [ ] **Step 3: Assert the A/B labels survived the read**

```bash
grep -cE '"?[0-9]{1,2}[AB]"?' data/seed-mn-2026/_dryrun-sldu-sldl.log
```
Expected: non-zero. A House label that arrives as `7` rather than `7B` means the loader dropped the
suffix, and **every House district in the state would then be ambiguous between its A and B halves**.
Stop and fix the loader before proceeding.

- [ ] **Step 4: Confirm the counts are exactly 67 and 134, not merely plausible**

If `sldl` reports 268, the loader has read both the A and B geometries of each district as separate
records **or** loaded two vintages. If it reports 67, it has collapsed them.

- [ ] **Step 5: Commit the log**

```bash
cd /c/EV-Accounts && git commit -F msg.txt -- backend/data/seed-mn-2026/_dryrun-sldu-sldl.log
```

---

### Task 4: Apply `sldu` + `sldl`, and verify against the anchors

**Files:**
- Create: `backend/scripts/verify-mn-tiger-import.sql`

- [ ] **Step 1: Apply**

```bash
cd /c/EV-Accounts/backend && \
npx tsx scripts/load-state-tiger-boundaries.ts --state MN --fips 27 --layers sldu,sldl \
  2>&1 | tee data/seed-mn-2026/_apply-sldu-sldl.log
```

- [ ] **Step 2: Assert the counts and the nesting**

Minnesota offers a structural gate no other state in this program has: **every House district nests
inside exactly one Senate district, and every Senate district contains exactly two.**

```sql
-- 67 and 134, and nothing else
SELECT district_type, count(*) FROM essentials.districts
WHERE lower(state)='mn' AND district_type IN ('STATE_UPPER','STATE_LOWER')
GROUP BY 1;   -- expect STATE_UPPER 67, STATE_LOWER 134

-- every House label is <senate number><A|B>, and each Senate number appears exactly twice
SELECT regexp_replace(label, '[AB]$', '') AS sd, count(*) AS halves
FROM essentials.districts
WHERE lower(state)='mn' AND district_type='STATE_LOWER'
GROUP BY 1 HAVING count(*) <> 2;   -- expect ZERO rows
```

- [ ] **Step 3: Assert the geometry nesting, not just the labels**

Labels agreeing proves naming, not geography. Assert containment with PostGIS: each House polygon's
interior point must fall inside its own Senate polygon. Expect **134 of 134**.

- [ ] **Step 4: Run the anchors from Task 1**

Each anchor's lon/lat must return the Senate and House district recorded in `anchors-L2022.json`.
**This is the step that proves the vintage.** If an anchor disagrees, TIGER has given you the 2012
plan and the load must be rolled back, not patched.

- [ ] **Step 5: Write `verify-mn-tiger-import.sql`**

Model it on `backend/scripts/verify-fl-tiger-import.sql` — a header naming the enacted plan and its
order date, the anchor table with sources, an explicit note on any single-sourced anchor, then the
assertions from Steps 2–4.

- [ ] **Step 6: Commit**

---

### Task 5: Apply the two place polygons

**Files:**
- Modify: `backend/scripts/verify-mn-tiger-import.sql`

- [ ] **Step 1: Apply the `place` layer**

```bash
cd /c/EV-Accounts/backend && \
npx tsx scripts/load-state-tiger-boundaries.ts --state MN --fips 27 --layers place \
  2>&1 | tee data/seed-mn-2026/_apply-place.log
```

- [ ] **Step 2: Assert the two GEOIDs this slice needs, BY ID**

```sql
SELECT geo_id, name FROM essentials.geofence_boundaries
WHERE state='27' AND mtfcc='G4110' AND geo_id IN ('2717000','2758000');
-- expect exactly 2 rows: 2717000 Duluth, 2758000 St. Paul
```

🔴 **Match on `geo_id`, never on name.** Confirmed 2026-09-12: TIGER names the capital **`St. Paul`**,
so a search for `Saint Paul` returns **nothing**, while `%St. Paul%` returns **five** Minnesota cities
— North St. Paul `2747221`, South St. Paul `2761492`, West St. Paul `2769700` and St. Paul Park
`2758018`. **`St. Paul Park` shares the capital's first five characters**, so a prefix match is not a
match either. Duluth is `2717000`, confirmed on two independent TIGERweb vintages.

- [ ] **Step 3: Check for `geo_id` collisions before trusting the load**

Production already carries 1,159 `geo_id` collisions across 13 states. `src/lib/geoIdGuard.ts` guards
the read path; ad-hoc SQL does not. Assert that `2717000` and `2758000` each resolve to exactly one
row per `district_type`.

- [ ] **Step 4: Extend the verify file and commit**

---

### Task 6: Gates, and the ledger

- [ ] **Step 1: Run the four wave gates**

```bash
cd /c/EV-Accounts && git fetch origin
npm run check:migrations  --prefix backend
npm run check:occupancy   --prefix backend
npm run check:reachability --prefix backend
cd backend && psql "$DATABASE_URL" -f scripts/verify-mn-tiger-import.sql
```

- [ ] **Step 2: Read `check:reachability` as "nothing regressed", NOT as "MN was swept"**

Per spec §5, corrected at GA-3: the gate takes **no per-jurisdiction probe list**. A green run means
no district regressed. It does **not** prove MN's new districts were examined. The per-district
control in Task 4 Step 3 is what distinguishes *swept and clean* from *not swept*.

⚠ `check:reachability` **does not run on PRs** — master-push and cron only. Run it locally.

- [ ] **Step 3: Record baseline movement honestly**

`essentials.offices_missing_terms` should **not move**: MN-1 creates districts, not offices. If it
moves, something created an office without a term and that is the one failure CI cannot catch.

- [ ] **Step 4: Update the tracker**

In [`PROGRAM.md`](../../../.planning/knight-foundation/PROGRAM.md): set slice 5's **1 geo** column to
`✅`, and add a ledger row stating the counts loaded, the anchors that proved the vintage, and which
anchors had only one source.

- [ ] **Step 5: Release or extend the lease**

```bash
npm run steward --prefix backend -- extend state:mn --hours 24   # if MN-2 follows immediately
npm run steward --prefix backend -- release state:mn             # if stopping here
```
⚠ `extend` **renews from now**; it does not add to the old expiry. A lapsed lease fails silently.

---

## Self-review

**Spec coverage.** Stage 1 is "TIGER `place` + `sldu` + `sldl` loaded and verified" (§3). Tasks 3–5
load all three; Tasks 1, 4 and 6 verify. §5's four gates are Task 6 Step 1. §4.1's constraints are in
Global Constraints, with the migration-numbering line explicitly marked as superseded by CLAUDE.md.

**Placeholders.** One deliberate gap remains: the `sldu`/`sldl` values in Task 1 Step 5, and the
anchor lines in Task 2 Step 2. These are the *output* of Task 1 — filling them here would be
inventing the evidence the wave exists to gather. Every other value is measured: FIPS `27`, GEOIDs
`2717000` and `2758000`, counts 67 and 134, plan L2022 ordered 2022-02-15.

**Type consistency.** `anchors-L2022.json` is produced in Task 1 Step 5 and consumed in Task 4 Step 4
and Task 2 Step 2, under that name throughout. `sldl` is a **string** with an A/B suffix everywhere it
appears.

**Not in this plan.** Stage 2 (the 201-seat legislature) is MN-2. Stages 3–5 are later waves. This
plan writes **no offices, no people and no migrations** — it loads geography only, so it needs no
`CC_` slot.
