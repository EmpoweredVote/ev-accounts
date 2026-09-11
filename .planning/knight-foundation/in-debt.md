# Indiana — the four debts, and how to pick them up cold

**▶ Debt 4 is HALF CLOSED (2026-09-11): the six Gary portraits are imported, stage 5 is 192/204.
The remaining 12 blanks are all settled by ruling or by absence of any source. Debts 1, 2 and 3 are
untouched. Next cheapest is Debt 2, the 17 empty government rows.**

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

## Debt 2 — 22 `State of Indiana` government rows, 17 of them empty

```sql
SELECT count(*) AS govs,
       count(*) FILTER (WHERE NOT EXISTS (
         SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id)) AS empty
FROM essentials.governments g WHERE g.name = 'State of Indiana';
```

IN-2 repointed Indiana's 18 legislative offices off 18 pseudo-chambers and deleted the emptied
chambers, which left their government rows behind holding nothing. ⚠ Earlier notes say **21**; it
is **22**, with **17** empty.

This is the cheapest debt: the 17 empty rows reference nothing. **Confirm emptiness per row before
deleting** — the five non-empty ones are load-bearing and one of them is the real Indiana.

---

## Debt 3 — Lake County Council's seven district seats

Still deferred, and **IN-8's solution does not transfer.**

Gary's six were unblocked because the Lake County Surveyor's precinct layer encodes the **city**
council district in the leading digit of `P26`. It does **not** encode the **county** council
district, so the seven county seats cannot be dissolved from it. The Surveyor's org carries no
council-district layer (searched 2026-09-11: `council district` returns 0 results).

The seven members were identified in IN-6 and are recorded in
[`backend/data/seed-lake-county-2026/ROSTERS.md`](../../backend/data/seed-lake-county-2026/ROSTERS.md).
🔴 **Ronald G. Brewer Sr sits on Lake County Council District 2** and left Gary's at-large seat —
whoever seats these must assert he holds exactly one office, as `CC_0097` does for Marian Ivey.

### Where to look next, in order

1. **`lakecountyin.gov/departments/voters/maps-gis/COUNTY-DISTRICT-MAPS/`** — the folder exists and
   is the county analogue of the folder that held Gary's map. Its file list is rendered
   client-side, so **fetch it with Playwright and a real UA**, not `requests`.
2. **The Surveyor's hub itself** — `https://services5.arcgis.com/8CXRnvSfSpwdf0R6/arcgis/rest/services?f=json`
   — enumerate every service rather than searching by keyword. `Selectable_Features` layer 3 is
   `Political Township`, which is NOT the council district.
3. **Ask the Board of Elections**, as IN-4 planned to.

🔴🔴 **The lesson that unblocked Gary applies here too: a negative result is only ever true of the
place you looked.** IN-6 concluded the geometry did not exist after sweeping one ArcGIS org; it was
public in another. Before concluding again, enumerate.

🔴🔴 **And two wrong maps were rejected for Gary before the right one was found.** Any Lake County
council layer must be **vintage-gated against a published county map**, the way
`load-gary-council-boundaries.ts` GATE 2 is gated on `G4 01` / `G5 22` / `G5 28`. A layer with the
right county, the right count and the right naming can still be the wrong year.

---

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
| 2 | **17 empty government rows** | references nothing; verify per row, delete | small |
| 3 | **Lake County Council** | needs a hunt and a vintage gate; may end in a data request | medium |
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
