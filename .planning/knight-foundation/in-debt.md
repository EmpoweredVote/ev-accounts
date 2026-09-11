# Indiana — the four debts, and how to pick them up cold

**▶ STATUS 2026-09-11 — three of four are closed.**
**Debt 2 CLOSED** (`CC_0098`): the 17 unreferenced `State of Indiana` rows are gone, 5 remain.
**Debt 4 half closed**: the six Gary portraits are imported, stage 5 is **192/204**, and the
remaining 12 blanks are all settled by ruling or by absence of any source.
**Debt 3 CLOSED 2026-09-11** (`CC_0099` + `CC_0100`): the geometry was found, vintage-proved and the
seven members seated. **Lake County is 19 of 19.** **Debt 1 is untouched** and needs a disposition
ruling before any SQL. A fifth item was found while closing Debt 2;
it is at the bottom of this file.

**Status 2026-09-11: all five Knight stages are CLOSED for Indiana.** Nothing here is stage work.
These are four things the slice measured, recorded and deliberately did not do. Ruling
(Cantrell, 2026-09-11): **clear this debt before opening slice 5 (MN).**

Read [`in.md`](./in.md) for the slice's full record and [`PROGRAM.md`](./PROGRAM.md) for the board.
Every number below was **re-measured against production on 2026-09-11**, not restated — three of
them had drifted from what earlier notes said, and one debt is bigger than the note claimed
because IN-8 created more of it.

🔴 **Re-measure before starting any of these.** The whole reason this file exists is that the
earlier one-line versions of these numbers were wrong in four places.

---

## Debt 1 — the `indiana_discovery` orphan cohort

**671 people hold 755 offices; 671 of those offices have no district, no chamber and no
government.** They are unreachable by any address, and nothing errors.

```sql
SELECT count(DISTINCT p.id) AS people, count(DISTINCT o.id) AS offices,
       count(*) FILTER (WHERE o.district_id IS NULL) AS orphaned
FROM essentials.politicians p
JOIN essentials.office_current_holder och ON och.politician_id = p.id
JOIN essentials.offices o ON o.id = och.office_id
WHERE p.source = 'indiana_discovery';
```

| orphan office title | count |
| --- | --- |
| `Indiana Elected Official` | 305 |
| `State Representative` | 231 |
| `State Senator` | 102 |
| `Governor` | 10 |
| `Secretary of State` | 10 |
| `Lieutenant Governor` | 6 |

⚠ **Earlier notes said "671 unreachable offices". The count of 671 is PEOPLE and orphan offices;
the cohort spans 755 offices in total.** The extra 84 are real seats — see below.

### 🔴🔴 84 of these people ALSO hold a real seat, and deleting them would unseat a sitting legislator

IN-2 reused 84 existing `indiana_discovery` person rows rather than creating duplicates, so those
84 people now hold **two** offices: the real one IN-2 gave them, and their old orphan. That is
expected and was ruled correct (Cantrell, ruling R2, 2026-09-10).

```sql
-- the 84: people holding BOTH an orphan and a real office
SELECT count(*) FROM (
  SELECT p.id FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  WHERE p.source = 'indiana_discovery'
  GROUP BY p.id HAVING bool_or(o.district_id IS NOT NULL) AND bool_or(o.district_id IS NULL)) s;
```

⚠ Earlier notes say **92**; it is **84**. in.md records why the number moved during IN-2's seat
resolution. Re-measure before acting.

### What the work actually is

**Retiring the 671 orphan OFFICES, not the people.** 🔴 **Never delete these people** — the
standing rule is that `office_current_holder` is mostly candidates and non-officeholders, and
deleting them destroys real records. The question to answer first, with a `GROUP BY` and a read of
actual rows:

- Which orphans are historical officeholders, which are candidates, which are duplicates of a
  person now seated properly?
- 🔴 **`districts` has NO inbound FKs**, so deleting a district orphans its offices. Repoint,
  never delete.
- The 305 `Indiana Elected Official` rows are the least specific and probably need their own
  treatment.

▶ **This is its own wave with its own ruling.** Do not fold it into anything else.

---

## Debt 2 — ✅ CLOSED 2026-09-11 (`CC_0098`)

**17 unreferenced rows deleted, 5 remain.** What follows is the record of what it actually took.

```sql
SELECT count(*) AS govs,
       count(*) FILTER (WHERE NOT EXISTS (
         SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id)) AS empty
FROM essentials.governments g WHERE g.name = 'State of Indiana';
```

IN-2 repointed Indiana's 18 legislative offices off 18 pseudo-chambers and deleted the emptied
chambers, which left their government rows behind holding nothing. ⚠ Earlier notes say **21**; it
is **22**, with **17** empty.

🔴 **"EMPTY OF CHAMBERS" WAS NOT THE RIGHT PREDICATE, AND THIS FILE HAD IT WRONG.**
`essentials.governments` has exactly **one** inbound foreign key and it is **not** from chambers:
`districts.government_id`, `ON DELETE NO ACTION`. Of the three rows carrying a single chamber, one
is *also* referenced by a district. The delete therefore guards on **no chambers AND no districts**,
which is still 17 — but the count agreeing was luck, not confirmation.

⚠ **Five rows survive and two are large** — 16 chambers / 20 offices, and 11 chambers / 165 offices.
**Which is "the real Indiana" is not settled**, and consolidating them would move offices between
governments. That is a different decision with a different blast radius, deliberately not taken.

🟢 **A control was watched firing**: planting a chamber on one of the 17 made the guarded delete
remove **16, not 17**, and the planted row survived.

✅ Applied, re-runs as `DELETE 0`, `CC_0088`/`CC_0089` still pass, all four CI gates green with
`UNREACHABLE` and `BAD_GEOMETRY` still below baseline.

---

## Debt 3 — ✅ CLOSED 2026-09-11 (`CC_0099` + `CC_0100`). Seven seats live, Lake County 19 of 19

**The seven districts are `WAYEO_WebMap_WFL1` layer 8, "County Council Districts".**

```
https://services6.arcgis.com/3BIBAkkTYicFwv1e/arcgis/rest/services/WAYEO_WebMap_WFL1/FeatureServer/8
   398 polygons statewide, public, queryable.  Lake = 7 rows, councildistrictid '089-District N'.
   item 92242dc49492424f8378103b52bfa480, owner Prem_GIO_Broadband (Indiana GIO).
   dataLastEditDate 2025-02-03; the item says "Updates Feb 2025: County Council".
```

**WAYEO = "Who Are Your Elected Officials"**, the Secretary of State's own address lookup
(`in.wayeo.us`). 🟢🟢 **The county's own page told us where it was the whole time.**
`lakecountyin.gov/departments/council/find-my-council-district` says, in prose: *"please refer to
the 'Who Are Your Elected Officials' interactive map from IN.gov … filter to the County level …
Scroll down to determine your Council Member/District."* No layer to find — the county delegates
the lookup to the state, so the geometry was never going to be in the county's own ArcGIS org.

🔴🔴 **THE THREE PLACES THIS FILE TOLD YOU TO LOOK WERE ALL THE WRONG KIND OF PLACE**, and two of
them were swept to exhaustion before the prose was read:

- The Surveyor's org was enumerated in full — **149 services, 234 layers** — and holds no
  council-district layer. That negative is now real rather than keyword-shaped (`Election
  Precincts` was found by the same scan, which is what proves the scan was not blind).
- `COUNTY-DISTRICT-MAPS/CO-COUNCIL/` is a **PDF folder**, as IN-6 said.
- ArcGIS Online at large has no Lake County council layer: the only Indiana county-council
  feature services published by their own counties are **Vigo** and **Wayne**.

▶ **The lesson is not "enumerate harder".** IN-6 and this session both searched for a *layer*.
The answer was a *sentence*, on the county page that the debt file already named. **Read the
human-facing page before sweeping the machine-facing one.**

### The vintage gate — 339 of 339 precincts, against the county's own map

The county publishes `departments/council/CC_District_Map3X5.pdf`: seven districts, prepared by
the **Lake County Board of Elections & Registration**, **Esri ArcMap 10.8.1, created 2022-01-26** —
the post-2020-census redistricting map. Like Gary's it is `FOR REFERENCE ONLY` and carries no
extractable district geometry, **but its precinct labels are live text with coordinates** (2129
words), which turns it from a picture into a checkable source.

| gate | result |
| --- | --- |
| Lake is the **only** Indiana county with 7 rows in the layer; `089` is its FIPS | ✅ matches the known seat count |
| all **342** current precincts nest wholly inside exactly one district | ✅ 0 split, 0 outside |
| **339 of 339** precincts get the same district from the 2022 PDF as from WAYEO | ✅ **0 disagreements** |
| area closes: 625.76 sq mi over seven districts | ✅ vs the county's ~627 (499 land + 128 water) |
| districts overlap nowhere | ✅ every sampled point is in exactly one |

🔴 **THE FIRST TWO RUNS OF THAT COMPARISON WERE BOTH WRONG, IN OPPOSITE DIRECTIONS.**

1. A vertex-based nesting test reported **153 of 342 precincts straddling two districts**. It was
   measuring nothing: precinct vertices lie **exactly on** district edges, where point-in-polygon
   is undefined. Fixed by sampling **strictly interior** points.
2. Sampling the PDF's colour **around each precinct's label** gave 311/320 and nine disagreements
   — every one of them a label sitting on a border, two of them (`SJ 13`, `SJ 19`) simply swapped
   with each other. Fixed by fitting an affine georeference from the 320 matched labels and
   sampling **inside each precinct's own polygon**: 339/339, no disagreements.

🟢 **Both fixes were checked by a control that had to fail first**, and both controls did:
   - the interior-sampling detector must still report a **genuinely** split municipality — it
     returns Gary 2/3, Hammond 5/1, Hobart 3/6, Crown Point 6/7/4, exactly as the map shows;
   - the PDF comparison must **collapse** when aimed wrongly — shifting the georeference takes
     339/339 to 81% at 60pt and **51.5% at 200pt**, and label-adjacent sampling scores 37.9%.
   - the legend swatches are read by locating the seven legend *words* and scanning left, then
     asserting **seven distinct non-white colours**. ⚠ The earlier Gary attempt sampled swatches
     at hardcoded coordinates, hit white, and reported four districts at *exactly 24.2%* each.

### Four detached fragments, all islands inside District 6 — two real, two empty

| fragment | addresses | the 2022 PDF says | verdict |
| --- | --- | --- | --- |
| D7, 0.0387 sq mi | **28** | D7 on **1494 of 1494** colour-bearing samples | ✅ **real** — an unincorporated pocket inside Crown Point |
| D7, 0.0077 sq mi | **1** | D7 on **1586 of 1586** | ✅ **real** — same pattern |
| D3, 0.00095 sq mi | 0 | **no district colour at all**, 0 of 5235 samples | ⚠ artefact, over a road corridor; coincides with `GR 19 NV`, a no-voter strip 25 m x 130 m |
| D4, 0.00120 sq mi | 0 | **no district colour at all**, 0 of 4129 samples | ⚠ artefact, same shape |

⚠ **Do not "clean" the two real ones.** A 28-address island of District 7 sitting inside District 6
is what the county map draws, and Crown Point's annexation history is why. The two empty artefacts
reach no address (checked against the county's 201,149 address points; the same query finds 194 in
a downtown Crown Point box, which is the control).

### What was done

| step | artefact |
| --- | --- |
| boundaries | `scripts/load-lake-county-council-boundaries.ts` → `X0051`, 7 rows. Seven gates; GATE 6 re-checks the frozen 2022 comparison on every run |
| structure | `CC_0099` — 7 `COUNTY` districts, 7 offices in the existing (and until now EMPTY) `Lake County Council` chamber |
| people | `CC_0100` — 7 people, 7 open terms, all `start_precision = 'unknown'` |
| acceptance | `scripts/verify-lake-council-probes.sql` — 7 anchors → 7 distinct districts → 7 correct holders; a Fort Wayne point returns 0 |

**Change-check before seating:** the council's own page and its **seven per-district pages**
(`council-1stdist` … `council-7thdist`) were read live 2026-09-11. All seven still serve, on the
same districts. 🟢 **The per-district pages are the stronger evidence**: IN-6 read the aggregate
"Our Team" block, and a block can be mis-ordered without looking wrong — seven separately
addressed pages cannot be. **Prefer the per-item page to the aggregate list when a MAPPING is
what you need.**

🔴 **Ronald G. Brewer Sr. holds exactly one office, asserted by the gate.** Measured first: no
Brewer row existed at all, so he was created rather than reused. ⚠ **Randy Niemeyer (Council D7)
and Rick Niemeyer (Indiana Senate) are different people**, as are Charlie Brown (D3) and
Michael A. Brown (Clerk).

⚠ **The name searches returned SEVEN IDENTICAL "NO MATCH" ANSWERS, which is the shape of a broken
detector, so three positive controls were added** — Michael A. Brown, Rick Niemeyer, Mary Brown.
All three were found, so the seven absences are real. An earlier pass of the same search was
useless for the opposite reason: `%Cid%` matched SALCIDO and PLACIDO, `%Hamm%` matched Hammond and
Hammer. **A substring is not a name.**

### Gates after

| gate | before | after |
| --- | --- | --- |
| `check:reachability` | BAD_GEOMETRY 4 · DEAD_GEOGRAPHY 17 · UNREACHABLE 37 | **4 · 17 · 37**, all at or below baseline |
| `essentials.offices_missing_terms` | 822 / 167 / 655 | **822 / 167 / 655** — unchanged, because the offices and their terms were written by the same pair |
| `check:occupancy` · `check:migrations` · `check:reservations` | — | green |

## Debt 4 — 18 portrait blanks, and **IN-8 made six of them**

```sql
SELECT g.name, count(*) FILTER (WHERE NOT (
   EXISTS (SELECT 1 FROM essentials.politician_images i WHERE i.politician_id = p.id)
   OR btrim(coalesce(p.photo_custom_url,'')) <> '')) AS blanks
FROM essentials.offices o
JOIN essentials.chambers c ON c.id = o.chamber_id
JOIN essentials.governments g ON g.id = c.government_id
JOIN essentials.office_current_holder och ON och.office_id = o.id
JOIN essentials.politicians p ON p.id = och.politician_id
WHERE g.name LIKE '%Indiana, US' GROUP BY 1 ORDER BY 2 DESC;
```

| jurisdiction | blanks | who |
| --- | --- | --- |
| Gary | ~~8~~ **2** | Clerk Suzette Raggs, Judge Deidre L Monroe. ✅ **The six district members were imported 2026-09-11** from the council's own page |
| Allen County | 7 | Hammond, Armstrong, Fries, Kerley, Lagemann, Keesling; McAlexander (monochrome) |
| Lake County | 3 | Sheriff Oscar Martinez (placeholder); Petalas, Katona (monochrome) |
| Fort Wayne | 0 | — |

✅ **CLOSED 2026-09-11 — stage 5 is now 192 of 204.** IN-8 added six seats and no portraits, taking
coverage to 186/204; importing the six took it to **192/204**. All six render from
`photo_custom_url`, all six objects re-fetch as real JPEGs, and a bogus object in the same bucket
returns HTTP 400. **12 blanks remain**, all of them settled: see the list below.

### 🟢 The six new Gary blanks are the easy ones, and the source is already known

`garycommoncouncil.gov/council-members/` carries a portrait for **all nine** councilmembers —
this session already harvested them, matched by the name beside each image:

```
data/seed-in-local-headshots-2026/harvest.json   page == "Gary council"
```

Six of those nine were not imported only because the people did not exist yet. They are 563x450
landscape frames; the crop is `scripts/headshot_crop.py` as usual. **Re-harvest live rather than
trusting the cached file** — it is a month old by the time anyone reads this.

The other twelve are settled and should stay blank unless a ruling changes:

- **Six Allen officials** — blank **by ruling** (Cantrell, 2026-09-11): the county publishes no
  member portraits and the only source is the county party page, which fails press/official/PD.
- **Three monochrome** — blank under the standing skip-monochrome rule. These are real portraits;
  a ruling could take them.
- **Raggs, Monroe, Martinez** — no portrait exists. Martinez's county page serves
  `user-icon-placeholder.png`; 🔴 **a placeholder counts as coverage** under
  `HAS_RENDERABLE_PHOTO_SQL`, so it must never be imported.

---

## Suggested order

| # | debt | why here | size |
| --- | --- | --- | --- |
| 1 | ~~Six Gary portraits~~ ✅ **DONE 2026-09-11** | source was the council's own page | small |
| 2 | ~~17 empty government rows~~ ✅ **DONE 2026-09-11** | references nothing; verified per row, deleted | small |
| 3 | ~~Lake County Council~~ ✅ **DONE 2026-09-11** | the hunt ended in a state layer, not a data request | medium |
| 4 | **671 orphan offices** | needs its own ruling on disposition before any SQL | large |

Doing 1 first made the stage-5 number true again before anyone quoted it: **192 of 204**.

## Before touching any of it

- `npm run steward -- claim state:in --label "Indiana debt"` — the lease from the IN waves expires
  2026-09-12 06:53Z.
- Work in a worktree you created. `C:/ev-accounts-in` is this slice's, on `knight/in-2-legislature`.
- 🔴 Migration numbers are **allocated, never counted**: `npm run steward -- slot CC --purpose "..."`.
- Re-run `npm run check:reachability` before and after. Baselines as of 2026-09-11:
  `BAD_GEOMETRY` 4, `DEAD_GEOGRAPHY` 17, `UNREACHABLE` 37.
- `essentials.offices_missing_terms` sits at **822 / 167 / 655**. The unflagged 655 is the number
  that matters.

---

## Debt 5 (new, found 2026-09-11 while closing Debt 2) — a chamber pointing at nothing

🔴 **`essentials.chambers.government_id` HAS NO FOREIGN KEY.** The only inbound FK on
`essentials.governments` is `districts.government_id`. So a chamber can reference a government row
that does not exist, and one does:

```sql
SELECT c.id, c.name, c.official_count,
       (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = c.id) AS offices
FROM essentials.chambers c
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.id = c.government_id);
```

One row: a chamber named **`Mayor`**, `official_count` 1, **0 offices**, `government_id`
`d50caa4b-592f-42d8-8619-4ec82d9ac4ac`, which is not in `governments`. **It is not Indiana's** and
predates this work — `CC_0098` neither caused it nor fixed it, and its gate asserts the orphan count
is *unchanged* rather than zero for exactly that reason.

Small, but it means **no count of "governments and their chambers" is safe without an existence
check**, and it suggests the same shape may exist elsewhere. Worth one sweep: are there orphaned
offices, districts or terms by the same mechanism?
