# MN — slice 5 (Duluth · Saint Paul)

Per-state notes for the Knight Foundation cities program. Siblings: [`fl.md`](./fl.md) ·
[`ga.md`](./ga.md) · [`ca.md`](./ca.md) · [`in.md`](./in.md). Tracker: [`PROGRAM.md`](./PROGRAM.md).

**Opened 2026-09-12.** Lease `state:mn` held by chris@empowered.vote on DESKTOP-G6KDNN2.

MN needs **stage 1 and stage 2 both** — it is the first slice since Georgia to owe full geography
*and* a full legislature. CA/CO/NC skip both; Indiana skipped stage 1 only.

---

## Baseline, measured against production 2026-09-12

Re-measure rather than trust this once any wave has applied.

### What exists

| Layer | Count | Note |
| --- | --- | --- |
| `districts` COUNTY | 87 | all 87 carry a `geo_id`; **St. Louis `27137`, Ramsey `27123`** — both parent counties are present |
| `districts` NATIONAL_LOWER | 8 | congressional |
| `districts` NATIONAL_UPPER | 1 | |
| `districts` STATE_EXEC | 4 | Governor, Lt. Governor, Attorney General, Secretary of State — all four seated |
| `geofence_boundaries` G4020 | 87 | counties |
| `geofence_boundaries` G5200 | 8 | congressional |
| `geofence_boundaries` G6350 | 880 | **ZCTAs, not counties.** See the trap below |
| `governments` "State of Minnesota" | **1** | ✅ not Indiana's 18 |

### What does not exist

- **No `STATE_UPPER` and no `STATE_LOWER` districts. No `G5210` or `G5220` geofence rows.**
- **No place polygons** for Duluth or Saint Paul, and no `G4110` rows for MN at all.
- **No state legislative offices or chambers.** Not one. The only MN offices in production are the
  four statewide executives plus the federal delegation.

So stage 1 is a clean load with nothing to repair, and stage 2 is a clean seed. Indiana's shape —
18 legacy seats on 18 pseudo-chambers needing a repair as much as a seed — **does not recur here**,
and that was verified, not assumed.

---

## 🔴 Traps found while opening the wave

### 1. `G6350` geo_ids look like another state's FIPS and are not

MN's 880 `G6350` rows carry geo_ids beginning `55…`, which reads as Wisconsin's FIPS. **They are ZIP
codes.** The pattern holds nationally: Alabama (FIPS `01`) files `35…`/`36…`, California (`06`) files
`90…`–`97…`, Florida (`12`) files `32…`–`34…`. `G6350` is a ZCTA layer and its ids are ZIPs.

⚠ **Do not "fix" these.** The first read of this table during the MN opening called it cross-state
contamination; grouping `left(geo_id,2)` against `state` across every state is what disproved it.

### 2. 🔴🔴 A "Saint Paul" already exists in production, and it is in TEXAS

`essentials.governments` holds **`City of Saint Paul, Texas, US`**. Any wave that attaches Minnesota's
capital to a government row found by `name ILIKE '%Saint Paul%'` seats the entire Saint Paul council
under a Texas city. **Match the government by its TIGER place `geo_id` `2758000`, never by name.**

This is the same class as GA-2's roster collisions, where `John Carson` was a Colorado senator and
`Kim Jackson` a Utah treasurer — but here it is a *place*, not a person.

### 3. 🔴 TIGER calls it `St. Paul`, and four other Minnesota cities contain that string

Searching TIGERweb for `Saint Paul` in Minnesota returns **zero rows**. The city's TIGER `BASENAME`
is **`St. Paul`**. Searching for `%St. Paul%` instead returns **five** cities:

| TIGER name | GEOID |
| --- | --- |
| **St. Paul city** | **2758000** ← the capital, the one this slice wants |
| North St. Paul city | 2747221 |
| South St. Paul city | 2761492 |
| West St. Paul city | 2769700 |
| St. Paul Park city | 2758018 |

⚠ **`St. Paul Park` is `2758018` — it shares the capital's first five characters `27580`.** A prefix
match is not a match. Both name searches fail, in opposite directions: the spelled-out form finds
nothing, the abbreviated form finds five. **Pin the GEOID.**

Duluth has no such problem: `Duluth city` → **`2717000`**, confirmed identical on two independent
TIGERweb vintages (BAS 2026 layer 4 and Census 2020 layer 18).

### 4. 🔴 The TIGERweb layer number is not the one you would guess

`Places_CouSub_ConCity_SubMCD/MapServer/**0**` is **`Estates`** — a US Virgin Islands geography.
Querying it for Minnesota returns `{"count":0}`: a true answer to the wrong question, and
indistinguishable from "TIGERweb has no Minnesota places".

**Incorporated Places is layer 4** (BAS 2026), or 11 (ACS 2025), 18 (Census 2020), 25. The positive
control that exposed this was a bare count — `STATE='27'` on layer 4 returns **856** places.

▶ **Run a count control on any TIGERweb layer before trusting a zero from it.**

### 5. The Census ACS API now answers `200` with an HTML "Missing Key" page

`api.census.gov/data/2023/acs/acs5?...` without an API key returns **HTTP 200**, 8,531 bytes, and an
HTML error document — not JSON, and not an error status. `r.ok` is worthless here; only decoding the
body catches it. Use TIGERweb, which needs no key.

---

## The enacted plan — what stage 1 must prove it has

| | |
| --- | --- |
| Plan | **L2022** |
| Ordered by | Minnesota Supreme Court **Special Redistricting Panel**, *Wattson v. Simon* |
| Order date | **2022-02-15** |
| First effective election | **2022** |
| Senate districts | **67** → `G5210` → `STATE_UPPER` |
| House districts | **134** → `G5220` → `STATE_LOWER` |
| Publisher | `gis.lcc.mn.gov/redist2020/plans.php?plname=L2022&pltype=court` |

🔴 **MINNESOTA HOUSE DISTRICTS ARE NOT NUMBERED 1–134.** Each of the 67 Senate districts contains
exactly two House districts, labelled with the Senate district's number plus `A` or `B`: Senate
District 1 holds House Districts **`1A`** and **`1B`**, through to `67A`/`67B`.

The consequences are load-bearing and they run through every stage of this slice:

- A House district label is **not an integer**. Anything that casts, sorts or joins on a numeric
  district will break or silently mis-seat. Sorting `1A, 10A, 2A` lexically is wrong.
- The nesting is exact and therefore **gateable**: every House district must fall inside exactly one
  Senate district, and each Senate district must contain exactly two. That is a stronger structural
  check than any other state in the program has offered, and stage 1 should assert it.
- The A/B suffix is how a roster row is identified. Two legislators share the number `1`.

## The `is_vacant` / turnover note

Stage 2 seats **who holds the seat today**, not who won in November. The program's standing rule
applies with unusual force here: MN's general election is **2026-11-03**, seven weeks after this wave
opened, and all 134 House seats are on that ballot. A certified result is not a fact about who holds
the seat; only a **special**-election winner starts early.

▶ **Expect to re-run the change-check immediately before applying stage 2**, and expect the roster to
need a refresh if stage 2 slips past early November.

---

## Jurisdictions

| | Duluth | Saint Paul |
| --- | --- | --- |
| TIGER place | **`2717000`** | **`2758000`** |
| Parent county | St. Louis — `27137` ✅ present | Ramsey — `27123` ✅ present |
| Consolidated? | no | no |
| Council structure | not yet measured — stage 3 | not yet measured — stage 3 |
| County board | not yet measured — stage 4 | not yet measured — stage 4 |

Neither is a consolidated city-county, so §3.2 does not apply and stage 4 keeps both the county board
and the separately elected county officers.

---

## ✅ RESOLVED — the loader collapsed A/B districts in `ocd_id` (found and fixed 2026-09-12)

**Fixed before any Minnesota row was written** — `src/lib/ocdDistrictSuffix.ts`, 13 tests, wired
into the loader. ✅ **Maryland's existing rows were repaired 2026-09-16 by `CC_0113`** — and the
scope was **42 rows in `districts` PLUS 42 in `geofence_boundaries`**, not the 24 recorded here. 24
is `rows − distinct` in one table, a count of the collapse rather than of the rows carrying it, and
`geofence_boundaries` was never named at all.

Found during the Task 3 dry run. **The dry run itself passed** — 67 and 134 records, both
pre-flight assertions green, no DB writes — and the defect is invisible in its output.

`load-state-tiger-boundaries.ts` derives `ocd_id` for both SLD layers with:

```ts
case 'sldu':
case 'sldl': {
  const dn = parseInt(districtNum ?? '0', 10);
  ocd_id = buildOcdId(abbrevUpper, layerDef.ocdKey, String(dn));
```

`parseInt('08A', 10)` is **8**. The letter is dropped, so `08A` and `08B` both become
`ocd-division/country:us/state:mn/sldl:8`.

**Measured against the real TIGER file: 134 House districts collapse to 67 distinct `ocd_id`s. All
67 pairs collide.** `geo_id` is unaffected — 134 of 134 stay distinct, because `geoIdSource` is the
raw `GEOID` (`2708A`), which keeps the letter.

### Why nothing would have caught it

- **`ocd_id` carries no unique constraint.** `essentials.districts` has unique indexes on `id` and
  `external_id` only. The duplicates would be written **silently**.
- **The wave's own acceptance test would pass.** Address search uses `geo_id`, never `ocd_id`
  (`ocd_id` ROLLS UP, `geo_id` LOOKS UP), so `check:reachability` and every anchor would be green.
- The pre-flight assertions count records. They cannot see a field derived per row.

### It is already in production, for Maryland

| State | `sldl` rows | distinct `ocd_id` | rows sharing one | `geo_id` ending in a letter |
| --- | --- | --- | --- | --- |
| **MD** | 71 | 47 | **24** | 42 |

Maryland's delegate districts are `1A`, `1B`, `1C`, `2A`… — the same shape, already loaded, already
collapsed. MD is currently the **only** affected state. Minnesota would add **67** more, tripling it.

▶ **North Dakota (slice 12) and South Dakota (slice 15) both hit this too** — PROGRAM.md already
records SD's `26A`/`26B`/`28A`/`28B` subdistricts. This is not a Minnesota problem.

### What it actually breaks

`ocd_id` keys the coverage map's aggregation in `src/lib/coverageMapService.ts`
(`stats.get(ocd_id)`, `map.set(loc.ocd_id, …)`). Two districts sharing one `ocd_id` have their
coverage stats merged into a single bucket — Minnesota would render as **67** House districts rather
than 134, each conflating a pair. Address search is unaffected.

### The fix, and why it is safe

Strip leading zeros exactly as now, but keep any alpha suffix:

```ts
const m = /^0*(\d+)([A-Za-z]*)$/.exec(districtNum ?? '0');
const suffix = m ? m[1] + m[2].toUpperCase() : String(parseInt(districtNum ?? '0', 10));
ocd_id = buildOcdId(abbrevUpper, layerDef.ocdKey, suffix);
```

Byte-equivalent for every purely numeric code — `'043'` → `43`, `'008'` → `8` — so the 19 states
already loaded through this path are unchanged. Only codes carrying a letter change.

✅ **Repaired 2026-09-16 by `CC_0113` — 84 rows, not 24.** It was a separate migration, not part of MN-1. Writing MN
correctly does not fix MD, and MD's wrong `ocd_id`s are already embedded in whatever has read them.

## Open questions, carried into MN-1

1. **Does TIGER's `sldu`/`sldl` for MN carry L2022?** A record count of 67/134 proves nothing about
   *which* map it is — the FL-1 lesson. Anchors must come from the enacted plan, independently.
2. **Which service does the state's own "Who Represents Me" tool query?** `gis.lcc.mn.gov/iMaps/districts/`
   exposes no documented REST endpoint. GA-5's route — read the iframe on the jurisdiction's own page
   and find what it actually calls — is the precedent.
3. **Do Duluth and Saint Paul publish council-district layers?** Unmeasured; stage 3's problem.

---

# MN-2 — the legislature (APPLIED 2026-09-14)

Branch `knight/mn-2-legislature`, worktree `/c/ev-accounts-mn`, lease `state:mn`.
Migrations **`CC_0107`** (structure) and **`CC_0108`** (occupancy) — both slots **reserved from the
allocator**, not counted. Roster:
[`backend/data/seed-mn-legislature-2026/ROSTERS.md`](../../backend/data/seed-mn-legislature-2026/ROSTERS.md).

**201 offices — 134 House + 67 Senate. 200 seated, 1 vacant. 198 people created, 2 reused.**

Baseline re-measured against production 2026-09-14, and it matched what stage 1 left: **67 + 134
districts present, ZERO legislative offices, ZERO legislative chambers**, and exactly **one**
`State of Minnesota` government row (`b610e3f3-…`). Indiana's 22 indistinguishable governments do
not recur here, and that was measured rather than hoped.

## 🔴🔴 A ROSTER LIST PAGE IS NOT A CHANGE-CHECK — AND THIS IS THE FINDING OF THE WAVE

`house.mn.gov/members/` listed **Joe Schomacker for 21A on 2026-09-14**, three months after he
resigned. Neither chamber publishes a vacancy marker: a case-insensitive search for `vacan` over
the House list page and over the Senate API returns **nothing at all**. The only in-band signal is
a banner on the member's own profile page — *"Resigning effective 11:59 p.m. Sunday, June 21st
2026"*.

So the change-check is **all 201 individual member pages**, not the two roster pages. It found
exactly one status note in 201, and its own positive controls — a resignation banner, a vacancy
wording, a death wording and a successor wording, each planted into a copy of SD-35 — all fired.

The House's own Session Daily settles the disposition: *"No special election will be called to fill
the remainder of his term."* **HD-21A is vacant**, first vacant day **2026-06-22**, filled at the
2026-11-03 general.

▶ **Disposition follows Georgia's SD-12, with one difference.** The office is created and flagged
through `essentials.vacate_office()`, which with no open term writes **no span** and sets
`is_vacant` + `vacant_since`. Georgia left `vacant_since` NULL because only the *announcement* was
documented; **Minnesota's date is documented, so it is written.** No person row is created for
Schomacker — this wave seats who holds a seat today.

## 🔴 THE HOUSE'S OWN LEADERSHIP TAB IS STALE, AND THE OTHER FOUR TABS ARE NOT

One document, five tabs, and they do not all agree. Leadership lists **Amanda Hemmingsen-Jaeger
(47A)** and **Kaohly Vang Her (64A)**; Alphabetical, District Order, Republican and DFL all list
the successors **Shelley Buck** and **Meg Luger-Nikolai**, and Open States agrees with those four.
Hemmingsen-Jaeger is now the **senator for district 47** — she moved chamber, and one tab did not
notice.

⚠ The two caucus tabs carry **67 each**, not 134. An absence from the Republican tab is a fact
about party, not a disagreement; the builder asserts that GOP and DFL *partition* the House
instead. A first draft treated the absences as 128 disagreements.

## 🔴 EIGHT MEMBER NAMES ARE HTML-ENCODED

`Mar&#237;a Isa P&#233;rez-Vega` is one of them. A raw regex capture writes mojibake into a
voter-facing field. `extract-house-tabs.mjs` decodes, and **refuses to run if it finds no encoded
name to decode** — a decoder that is never exercised has proved nothing.

## 🔴 FIVE NAME COLLISIONS, SPLITTING TWO WAYS — AND THE FIFTH WAS INVISIBLE

Production holds an **active** politician row with the same `(first_name, last_name)` for five of
the 200 members, which `essentials.politician_name_duplicate_guard` refuses. Each was read before
it was classified.

| Seat | Roster | Existing row | Verdict |
| --- | --- | --- | --- |
| 55B | Kaela Berg | Kaela Berg, candidate MN-02 | ♻ same person — reuse |
| 54 | Eric R. Pratt | Eric Pratt, candidate MN-02 | ♻ same person — reuse |
| 20B | Steven Jacob | Steven Jacob, candidate **KS**-01, a Libertarian from Lawrence | ✂ different |
| 9B | Tom Murphy | Tom Murphy, **Mayor of Sahuarita, AZ** | ✂ different |
| 64 | Erin P. Murphy | Erin **J.** Murphy, **Boston City Councillor** | ✂ different |

⚠ **The guard is lifted for three rows, not for the migration.** `CC_0108` inserts the 195
collision-free rows with the trigger **armed**, so a collision nobody anticipated still stops it;
only then is `essentials.allow_duplicate_name` set to `'on'` for the three, and back to `'off'`
immediately afterwards.

🟢 **THE FIFTH COLLISION WAS INVISIBLE UNTIL A DIFFERENT BUG WAS FIXED.** An early draft of the
roster builder took `full_name` from the chamber and `first_name` from Open States, writing
**"Steven Jacob"** with `first_name` **"Steve"**. The guard keys on `(first_name, last_name)`, so
the mismatch hid the Kansas Steven Jacob from the reuse search entirely — the exact-match query
returned **four** collisions, not five.
▶ **A FIELD PAIR THAT A CONSTRAINT READS MUST COME FROM ONE SOURCE.**

## 🔴 THERE IS NO `term_start` TO BE HAD, AND NONE IS INVENTED

The richest per-member pages either chamber publishes give an election **year** and an ordinal —
"Elected: 2010 / Term: 8th" (House), "re-elected 2020, 2022 / Term: 4th" (Senate). The Legislative
Reference Library's legislator database gives **biennia** ("House 1971-72"). Neither is a date.

At least six sitting members took their seats at a **2025 special election** rather than at the
start of the biennium, so the constitutional first-Monday-in-January date would be positively
wrong for them and is not a fact about anyone else either. Every term is written **open-ended at
`start_precision = 'unknown'`** — the GA-2 and IN-2 pattern. `seat_officeholder()` is not used; it
refuses a NULL `term_start` by design.

## 🔴 ALL 201 SEATS ARE ON THE 2026-11-03 BALLOT

Every Minnesota House seat is elected every two years, and the Senate class elected in 2022 serves
through 2026. ▶ **Re-run the change-check immediately before applying** if this slips past early
November. A certified result is not a fact about who holds the seat; only a *special*-election
winner starts early.

## ✅ Dry run — both migrations as ONE transaction, and the rollback was verified

```
INSERT 0 1 · INSERT 0 1 · INSERT 0 201 · vacate_office -> f
NOTICE:  MN-2 structure OK: 2 chambers, 134 House + 67 Senate offices, 1 vacant (21A since 2026-06-22)
INSERT 0 195 · SET · INSERT 0 3 · SET · INSERT 0 200
NOTICE:  MN-2 occupancy OK: 198 people in band, 201 offices, 200 seated, 200 terms, 0 dated, 0 ended, 21A vacant
ROLLBACK
```

`vacate_office` returning **`f`** is correct: there was no open term to close, and the flag is
still set. Production was re-measured afterwards and is **untouched** — 0 legislative offices, 4
chambers (the pre-existing executives), 0 people in the reserved band, no 21A office. The rollback
reverted, confirmed rather than assumed.

### 🔴 EVERY GATE WAS WATCHED FAILING FIRST

A gate that passes can pass for the wrong reason. Five defects were planted into copies of the dry
run (`backend/data/seed-mn-legislature-2026/gate-controls.sh`), and each aborted with a
**distinguishable** exception:

| Control | Reported |
| --- | --- |
| one office short | `expected 134 House / 67 Senate offices, got 134 / 66` |
| vacancy never flagged | `expected 1 vacant Minnesota legislative office(s), got 0` |
| one term short | `expected 200 seated Minnesota legislative offices, got 199` |
| a term carries a date | `200 dated and 0 ended terms; every Minnesota term is open-ended and unknown` |
| the vacant seat seated | `expected 200 seated Minnesota legislative offices, got 201` |

⚠ The last one aborts at the **seated-count** gate, which fires before the dedicated 21A gate. The
21A gate is still there and still needed — it catches the case where a seat is *swapped* rather
than added, leaving the count right.

## ✅ Gates green

| Gate | Result |
| --- | --- |
| `check:migrations` | OK — 2 added vs `origin/master`, 1905 slots across 148 refs, tree scan clean |
| `check:reservations` | OK — both slots reserved by their own author |
| `check:occupancy` | OK — 4 files scanned, no writes to the dropped `offices.politician_id` |

## ▶ Owed, carried forward

1. Stage 3 (Duluth and Saint Paul councils) and stage 4 (St. Louis and Ramsey county boards) are
   still unmeasured. Ramsey's `OpenData/OpenData` MapServer layer 2 is `Commissioner Districts` —
   found during MN-1 and noted then for stage 4.
2. ✅ Maryland's collided `ocd_id` rows repaired 2026-09-16 (`CC_0113`, 84 rows). Still owed: a second geographic source for the
   Duluth anchor, since St. Louis County GIS was never actually searched; `backend/scripts/` is
   unlinted and untypechecked.

## ✅ MN-2 APPLIED 2026-09-14 — THE MINNESOTA LEGISLATURE IS SEATED

`CC_0107` then `CC_0108`, both exit 0, both gates green on the way in.

```
CC_0107: INSERT 0 1 · INSERT 0 1 · INSERT 0 201 · vacate_office -> f
NOTICE:  MN-2 structure OK: 2 chambers, 134 House + 67 Senate offices, 1 vacant (21A since 2026-06-22)
CC_0108: INSERT 0 195 · SET · INSERT 0 3 · SET · INSERT 0 200
NOTICE:  MN-2 occupancy OK: 198 people in band, 201 offices, 200 seated, 200 terms, 0 dated, 0 ended, 21A vacant
```

Measured from OUTSIDE the migrations, before and after:

| | Before | After | Expected |
| --- | --- | --- | --- |
| MN legislative offices | 0 | **201** | 201 |
| MN chambers on the government row | 4 | **6** | 4 executives + 2 |
| People in band `-2732201..-2732001` | 0 | **198** | 198 |
| MN legislative terms | 0 | **200** | 200 |
| MN legislative **seated** (`count(och.politician_id)`) | 0 | **200** | 200 |
| `politicians` total | 86,926 | **87,124** | +198 exactly |
| `offices_missing_terms` total | 822 | **823** | +1, the vacant 21A |
| `offices_missing_terms` **unflagged** | 655 | **655** | unmoved — 21A is flagged |

### ✅ The three dispositions landed as written

- **21A**: `is_vacant` true, `vacant_since` **2026-06-22**, **0** terms, **0** holders. No span written.
- **The two reused rows** keep their MN-02 race edge *and* gain one term each — Kaela Berg on
  House 55B, Eric Pratt on Senate 54. No duplicate person was created.
- **The three namesake pairs are six distinct rows**, and only the Minnesota one of each holds a
  Minnesota seat: Steven Jacob (MN 20B) beside Steven Jacob (KS candidate, no office); Tom Murphy
  (MN 9B) beside Tom Murphy (Mayor, Sahuarita AZ); Erin P. Murphy (MN Senate 64) beside
  Erin J. Murphy (City Councillor, Boston).

### ✅ END-TO-END PROBE — and it matches a THIRD, INDEPENDENT authority

The only reliable detector is whether an address returns a legislator. All four MN-1 anchors were
run point → `geofence_boundaries` → `districts` → `offices` → `office_terms` → `politicians`:

| Point | Senate | House |
| --- | --- | --- |
| Duluth City Hall | SD-8 **Jennifer A. McEwen** | HD-8A **Pete Johnson** |
| Saint Paul City Hall | SD-65 **Sandra L. Pappas** | HD-65B **María Isa Pérez-Vega** |
| 235 Marshall Ave | SD-64 **Erin P. Murphy** | HD-64A **Meg Luger-Nikolai** |
| 1200 Montreal Ave | SD-64 **Erin P. Murphy** | HD-64B **Dave Pinto** |

🟢 **THE NAMES ARE THE POINT, NOT THE DISTRICT NUMBERS.** MN-1 recorded what the *state's own*
"Who Represents Me" tool returned at Duluth and Saint Paul City Hall — McEwen, Johnson, Pappas,
Perez-Vega. Those names came from `gis.lcc.mn.gov`, not from either chamber's roster and not from
Open States. The seeded chain reproduces all four. That is a third authority agreeing, not a
restatement of the sources the roster was built from.

🟢 Two further things fall out of the same table. **`María Isa Pérez-Vega` renders with its
accents**, so the HTML-decoder fix reached production. And **64A and 64B resolve to different
people inside one Senate district** — the only test that catches a collapsed or swapped A/B half.
64A returns **Meg Luger-Nikolai**, the successor the House's own Leadership tab still gets wrong.

⚠ **The probe was controlled.** Eight OK out of eight is a uniform answer. Re-running it with
Duluth's expectation set to the **2012 plan's** `7`/`7A` reported `*** WRONG DISTRICT ***` on
exactly those two rows and left the other six OK.

### ✅ PER-DISTRICT CONTROL — green is not a claim about districts unless you count them

| Layer | Districts | With exactly 1 office | With exactly 1 holder | Unseated | Anomalies |
| --- | --- | --- | --- | --- | --- |
| `STATE_LOWER` | 134 | **134** | 133 | 1 — `2721A` | none |
| `STATE_UPPER` | 67 | **67** | **67** | 0 | none |

The single unseated district is **named**, not merely counted, and it is the expected one. No
Minnesota legislator holds two Minnesota legislative seats.

### ✅ Idempotent, proved by re-running both

Both migrations were applied a second time. Every write into `essentials.*` reported `INSERT 0 0`,
both post-verify gates passed unchanged, and the four counts afterwards were identical —
201 offices, 198 people, 200 terms, 87,124 politicians.

### ✅ Gates after the apply

| Gate | Result |
| --- | --- |
| `check:reachability` | **OK — nothing regressed**, and TWO buckets fell: `BAD_GEOMETRY` 4 (baseline 5), `UNREACHABLE` 37 (baseline 38). `DEAD_GEOGRAPHY` unmoved at 17. |
| `check:migrations` | OK |
| `check:reservations` | OK |
| `check:occupancy` | OK |

▶ **Next: stage 3** — Duluth and Saint Paul city councils. Neither council's district layer has
been measured yet.

---

# MN-3 — Duluth and Saint Paul councils (APPLIED 2026-09-15)

`X0052`/`X0053` boundaries, then `CC_0109` structure, then `CC_0110` occupancy.
**18 offices, 18 people, 0 vacancies** — Duluth 10, Saint Paul 8.
Full record, sources and gate output: [`backend/data/seed-mn-cities-2026/SOURCES.md`](../../backend/data/seed-mn-cities-2026/SOURCES.md).
Roster: [`backend/data/mn-cities-roster.json`](../../backend/data/mn-cities-roster.json).

## 🔴🔴 Duluth publishes two council-district maps and a count cannot tell them apart

Both return exactly five features numbered 1–5. The city adopted a new map on 2022-03-28.

**The population attribute does not discriminate** — the old layer's totals sit close enough to
the 2020 census to pass a plausibility check. What gives it away is the **field names**,
`POP_2010` and `Numb_12`, whose precinct populations sum to **86,265, Duluth's 2010 census
population exactly**.

The decisive measurement is coverage: the superseded map leaves **8.68 sq mi of Duluth in no
district** (89.176%) against the current map's 99.984%. Roughly one address in nine would return
no councilor and nothing would error.

⚠ **Two layers inside one service can be different vintages.** The old service's precinct layer
holds 35 precincts while its own district layer was dissolved from 43.

## 🔴🔴 A city council's change-check signal is an expired date, not a banner

The word scanner built on MN-2's lesson — resigned, vacant, appointed, sworn in, stepping down,
interim — ran over all 18 member pages and returned **one benign hit**, with **all six of its
positive controls firing**. It was still the wrong instrument: Terese Tomanek's page says
*"Term Expires: January 5, 2026"*, read on 2026-09-14.

▶ **A CONTROL PROVES A DETECTOR IS NOT BROKEN. IT CANNOT PROVE THE DETECTOR IS LOOKING AT THE
RIGHT THING.**

**All four Duluth at-large pages state the same expired date.** The *distribution* gave it away —
Duluth staggers its council, so its expiries must not be uniform. The four names are right and all
four dates are stale; Jordon Johnson's page states an expiry that predates his own term.

## 🔴 Three seats had turned over mid-term, and a list page got one wrong

Duluth District 2 (Mayou resigned, DeLuca interim, Desotelle elected), Duluth District 4 (a
special election to an unexpired partial term, which is why the seat appears in both the 2023 and
2025 listings), and Saint Paul Ward 4 (Jalali resigned 2025-03-08, Coleman won the 2025-08-12
special and was sworn in 2025-08-27).

⚠ Saint Paul's own council index says flatly *"Councilmembers were elected to a 4-year term in
2023"*, which is **wrong for Ward 4** — the MN-2 lesson in a second dress.

## 🟢 Every term is dated, and the two cities are not made uniform

MN-2 wrote all 200 legislative terms open-ended at `unknown`. Both cities publish dates, so all 18
carry a real `term_start` at `day` precision and the gate asserts **0 undated and 0 ended**.

Saint Paul's seven wards **tile the city exactly** (100.000%); Duluth's five districts **overhang
it by 11.16 sq mi** of Lake Superior and unincorporated township. Duluth's four at-large seats run
in one citywide race and are **not numbered**; Saint Paul has **no at-large seat at all**, which
the structure gate asserts it never gains.

## ✅ Probe, and the two waves stacking

Duluth City Hall returns **9** answers, Saint Paul City Hall **5** — ward, mayor, and the
legislators MN-2 seated. 🟢 The mayor Saint Paul returns is **Kaohly Her**, the person whose
departure from HD-64A the Minnesota House's own Leadership tab still has not noticed. One person
closes both waves.

**Per-district control: 12 of 12**, each at its own interior point, each returning exactly one
holder and the right one, with offshore and Minneapolis negative controls.

## 🔴 Sixteen gates watched failing first — and two of my own controls were lying

Six loader gates and eight migration gates were each run against a deliberately wrong input.
GATE 3 refused Duluth's superseded map at 89.176% while passing the current one at 99.984%.

Two controls planted something **other than what they claimed, and both looked like passes**: a
greedy regex deleted three boundary inserts instead of one, so the gate correctly reported 2 — the
gate was right and the control was lying — and a "two seats, one person" control duplicated a
person row, tripping a unique index before the gate was ever reached.
▶ **A CONTROL THAT ABORTS FOR THE WRONG REASON PROVES NOTHING.** Every control now asserts what it
planted before the file is written.

🟢 No matview refresh was needed, and that was checked: `geofence_child_county` is defined over
`G4110` and mentions no `X00` code.

## ✅ MN-4 APPLIED 2026-09-15 — BOTH COUNTY BOARDS ARE SEATED

**19 offices, 19 seated, 0 vacancies.** St. Louis 10, Ramsey 9 — `CC_0111` (structure) and
`CC_0112` (occupancy), on `X0054` and `X0055`. Full record:
[`backend/data/seed-mn-counties-2026/SOURCES.md`](../../backend/data/seed-mn-counties-2026/SOURCES.md).

### 🔴🔴 THE TWO COUNTIES DO NOT ELECT THE SAME OFFICES, AND NEITHER MATCHES THE GENERAL RULE

§ 382.01 says auditor, treasurer, sheriff, recorder, attorney, coroner. **Ramsey elects a board,
a sheriff and an attorney** (§ 383A.20 — Minnesota's only home rule charter county makes the other
four appointive). **St. Louis elects those plus an Auditor/Treasurer** (§ 383C.136 abolished the
treasurer in 1969 and gave its duties to the auditor). Neither elects a coroner. The migration's
post-verify asserts 4+3 chambers and 10+9 offices, and refuses a Ramsey auditor by name.

### 🔴🔴 A SINGLE PERCENTAGE IS NOT A GATE, MEASURED IN BOTH DIRECTIONS

Ramsey tiles its county at **100.000%**; St. Louis covers **98.220%** and is **correct** — the gap
is one 120.593 sq mi edge wedge of Lake Superior plus 912 slivers, holding no incorporated place.
MN-3's `minCoverPct: 99.9` would have refused it.

But the number chosen instead would have failed the other way: a control that removes Duluth's own
district still scores **97.682%**, above the 97% backstop. **What refused it was decomposing the
gap** — a 157.597 sq mi piece that contains Duluth — and GATE 3P, which asks the reachability
question directly: every incorporated place in the county must sit in exactly one district (27 in
St. Louis, 15 in Ramsey). ▶ Neither threshold, on its own, was the gate.

⚠ Area ratios mislead in both directions here and that is why they are not the main gate. Duluth's
place polygon is only **96.077%** covered (its own polygon overhangs the lake) and White Bear Lake
**99.118%** (it straddles the Washington County line). Both are correct.

### 🔴 GATE 4's TOLERANCE IS A PROPERTY OF THE COUNTY, NOT A CONSTANT

St. Louis's layer self-overlaps on **11 pairs totalling 0.022856 sq mi**; Ramsey's on **zero**.
MN-3's flat 0.001 refused a correct layer. Tolerances are now measured per county and each was
watched refusing a planted 8 sq mi overlap. ⚠ The loader also had to be made to **print the
measurement beside the verdict** — it first said *"no overlapping district pairs"* about a layer
with eleven of them.

### 🔴🔴 A CONTROL CAN PLANT A REAL CHANGE IN THE WRONG PLACE, AND IT LOOKS LIKE A PASS

MN-3 ended on *a control that aborts for the wrong reason proves nothing*. The next form of it:
the coverage control removed **St. Louis district 1** to orphan Duluth — **Duluth is in district
3** — and **Ramsey district 4** to orphan Saint Paul — **Saint Paul is in district 5**. Both gates
passed, correctly, on a control that had orphaned nobody. Both now assert the place sits in **0**
districts before judging. ▶ **Assert the consequence you planted, not the action you took.**

### 🔴 THE ROSTER CONTRADICTED ITS OWN PROSE, AND THE PROSE WAS RIGHT

Three Ramsey commissioners carried `2023-01-02` at **`day`** — § 382.01's first Monday, which
governs the **constitutional officers** and not the board (§ 375.01 gives no day, which is why St.
Louis's two expiry cohorts land on a Monday and a Tuesday). No page states a day. Corrected to
`month`, making the mix **5 `day` · 7 `month` · 7 `year`** — the five being exactly the five
constitutional officers, as the notes had claimed all along. `CC_0112` asserts the mix *and* that
no commissioner carries a day.

### ✅ 52 gate verdicts, and the probe

24 loader verdicts (12 controls, each asserting what it planted) and **28 migration gates**, run by
splitting each migration at its post-verify banner so the real gate text judges a broken state.
Dry-run as one transaction with the rollback verified; both applied; both re-run idempotent.

**Duluth City Hall returns 13 answers, Saint Paul 8, Hibbing 7** — councilor, legislators and
county officers together, three waves stacking. Per-district control **14 of 14**.

⚠ **MN-3's offshore control point does not transfer** — 20 km out in Lake Superior returns a
commissioner, correctly, because it is inside St. Louis County. A negative control must be outside
the thing being tested, not outside the last thing that was tested.

## ▶ Next

**Stages 1-4 are applied. STAGE 5 IS OPEN AND WAS NEVER "NOTHING OWED"** — see MN-5 below. The line
that stood here said Minnesota owed nothing, which counted the *jurisdictions* and forgot that stage 5
is headshots plus a banner for the whole slice, legislature included. GA-6 paid for that lesson and
wrote it down; this file repeated the error anyway.

Carried forward beyond this slice:

1. ✅ **Maryland repaired 2026-09-16 by `CC_0113`** — and the real scope was **84 rows across TWO
   tables** (42 `districts` + 42 `geofence_boundaries`), not the 24 on record; the boundary table was
   never named. The live harm was `federalCoverage`'s seat denominator, which reported **94 for a
   state with 118**. ▶ ND (slice 12) and SD (slice 15) share the shape; the loader is fixed, and
   `check:ocd-suffixes` now watches both tables on a schedule.
2. ✅ `backend/scripts/` is linted (PR #515).

# MN-5 — stage 5 assets, PART ONE APPLIED 2026-09-16. 99 portraits imported, 0 failed.

**Measured before: 242 Minnesota offices, 241 seated, SIX renderable portraits.** The four statewide
executives had one each and two legislators did; every city, every county and 199 of 201 legislative
seats had none.

## 🔴🔴 THE MINNESOTA HOUSE FORBIDS THE USE THIS PIPELINE MAKES — 133 SEATS ARE A LICENCE DEBT, NOT A GAP

The House publishes a complete, consistent portrait per district at
`house.mn.gov/hinfo/memberimgls94/<district>.gif`, 525x675, with the member's name in the page's
`alt`. Its *Photo and Digital Image Use Policy* (updated 2024-10-23) retains copyright in perpetuity,
requires permission **in advance**, requires a per-photographer credit, forbids sale or use "on a
website" for for-profit purposes — and **forbids digital alteration "in any way, including
cropping"**, which is precisely what a 4:5 proof-sheet crop is.

**No workaround survives that clause.** Hotlinking dodges the hosting question and still crops.
Open States serves the same `house.mn.gov` files, re-pointed rather than re-licensed.

▶ Ruling (Cantrell, 2026-09-16): **record the debt, request permission, ship everything else.** The
request is drafted at [`backend/data/seed-mn-headshots-2026/HOUSE-PERMISSION-REQUEST.md`](../../backend/data/seed-mn-headshots-2026/HOUSE-PERMISSION-REQUEST.md).

⚠ **The Senate is a DIFFERENT question, and was asked separately.** It publishes no policy, and its
portraits are 1200x1500. The 67 shipped as `press_use`, the treatment GA-6's 233 had. **Georgia and
Florida raised no such question because those chambers publish no such policy — absence of a policy
is not a licence, but a published refusal is a refusal.** ▶ Every later slice inherits the question:
**read the chamber's photo policy BEFORE building a roster-portrait script.**

## 🔴 A CAPTURE IS EVIDENCE ABOUT THE QUESTION IT WAS TAKEN FOR

MN-3 captured all 18 city member pages, for TERM DATES, and its copies are already wrong about
portraits: all four Duluth at-large pages carried `/media/12005/headshot.jpg` in that capture, while
the live pages carry three different files and one of them carries none at all. Re-reading live is
not fussiness — the cached answer was wrong for three of four.

## 🔴 THREE DETECTOR FAULTS, EACH OF WHICH LOOKED LIKE AN HONEST ANSWER

- **A noise filter dropped the Mayor of Duluth.** His portrait is
  `reinert_roger_formal-headshot_-with-seal.jpg`, and the filter refused anything matching `seal` —
  the city seal is IN the photograph. **A filename that names the person now outranks the filter.**
  A substring list is a guess about files that carry no name; it must never overrule one that does.
- **Node's `fetch` reported "0 of 37 upgraded" and the number was false.** These hosts refuse its TLS
  fingerprint. On `requests` the same rules upgraded seven Saint Paul portraits, one of them from
  325x260 to 2880x3600. **The failure was shaped exactly like an honest negative** — the known
  `reference_waf_blocks_node_fetch_by_tls` rule, arriving as a measurement rather than an error.
- **A Drupal derivative carries THREE marks and all three must come off**: the `/styles/<style>/public/`
  segment, the `.webp` Drupal appends when it re-encodes, and the `itok` signature. Stripping only the
  style segment returns the same 325px file and looks like "no larger copy exists".

## ✅ Resolved by office, and the name checked TWICE

The Senate half used GA-6's rule: resolve on (chamber → MTFCC, district `geo_id`), never on a name.
The name is a redundancy check and it ran against **both** the production row and the portrait's own
`alt` text, because an alt naming someone else outvotes the page. **67 of 67 resolved, 0 name
disagreements.**

## ✅ The decode and distinctness checks were CONTROLLED BEFORE USE

A planted truncated body (header intact, image incomplete) failed the full decode; a planted
byte-identical twin was caught by hash. Both fired. Then, on the real set: **104 sources decode, 0
capped, 104 byte-distinct of 104** — so no shared placeholder is hiding in the set, which is the
failure a count alone cannot see.

## 🔴 senate.mn SERVES ONE SENATOR A 126x162 GIF UNDER A `.jpg` NAME

Eric Lucero (SD-30) and Robert Kupec (SD-4) are the only two senators below target on the state's own
site — 126x162 and 320x400 against everyone else's 1200x1500. Both caucus sites host the same
official portraits at full resolution, under the same `30Lucero` / `04Kupec` base names. **The
extension is not the format and the display size is not the file.**

## ✅ Applied — 99 imported, 0 failed, measured from outside

| Body | Offices | Seated | Renderable | `photo_custom_url` | `politician_images` |
| --- | --- | --- | --- | --- | --- |
| Minnesota Senate | 67 | 67 | **67** | 67 | 67 |
| St. Louis County Board | 7 | 7 | **7** | 7 | 7 |
| Ramsey County Board | 7 | 7 | **7** | 7 | 7 |
| Duluth City Council | 9 | 9 | 8 | 8 | 8 |
| Saint Paul City Council | 7 | 7 | 6 | 6 | 6 |
| County officers (4) and mayors (2) | 6 | 6 | 4 | 4 | 4 |
| Minnesota House | 134 | 133 | **1** | 1 | 1 | 

✅ **AND THE OBJECTS WERE FETCHED BACK.** Every stored URL was re-fetched from the CDN and **decoded**,
not header-sniffed: **104 of 108 decode and are 4:5 within the 600x750 ceiling, 0 broken**, and the
four blanks are exactly the four the operator held for re-sourcing. **A bogus bucket key ran alongside
and failed as required** — a verifier that passes everything is indistinguishable from one that tests
nothing.

**600x750 is a ceiling, not a contract**: 87 rows ship at 600x750 and 17 at their native cropped size,
the smallest being Ramsey's eight at 200x250. **Ramsey publishes nothing larger** — its own
per-commissioner pages serve the same 200x250 file, checked one by one, and St. Louis serves Keith
Nelson a 200x300 file dated 2017.

## ▶ Owed

1. **133 House portraits** — blocked on permission, above.
2. **Four re-sourced portraits** awaiting approval: Nephew (no city portrait exists; campaign
   landscape), Her (the city publishes only an event photograph; campaign portrait), Johnson (the
   council portrait exists under the ward-7 filename her own page does not use), Fletcher (the
   un-resized original is 503x651 PORTRAIT where the linked copy is 550x290 landscape).
3. **Two banners** — Duluth and Saint Paul, and the adjacency test against the Minnesota state banner.
