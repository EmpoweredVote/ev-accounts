# California — slice 3 notes

**Program tracker:** [`PROGRAM.md`](./PROGRAM.md) · **Spec:**
[`docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

Jurisdictions: **Long Beach** (Los Angeles County) and **San José** (Santa Clara County).

California is the cheapest slice on paper — stages 1 and 2 are skipped, because all 80 `sldl`, 40
`sldu`, 482 `place` and 58 `county` polygons are loaded and both chambers are complete at 80/80 and
40/40. What it is not is empty.

---

## 🔴🔴 The starting position in the tracker was WRONG, and it was wrong in the dangerous direction

The spec's §2.3 and the tracker's jurisdiction table both said:

| Jurisdiction | Tracker said | Production actually held, measured 2026-09-02 |
| --- | --- | --- |
| Long Beach | "4 citywide execs already seated; **all 9 council districts absent**" | 13 offices, 13 seated, 13 with a headshot |
| San José | "**Mayor only**; all 10 council districts absent" | 11 offices, 11 seated, 11 with a headshot |
| Los Angeles County | "3 offices, 3 seated" | **8** offices, 8 seated, 8 with a headshot |
| Santa Clara County | "3 offices, 3 seated, 0 headshots" | 3 offices, 3 seated, 0 headshots — correct |

**Re-measure before trusting a baseline.** A stale tracker line reads exactly like a finding, and a
wave that had believed this one would have created nine duplicate Long Beach council districts on top
of nine that already existed — the 1495/1496/1498 duplicate-office family, in a new city.

⚠ The Los Angeles County line was wrong for a specific, repeatable reason. See the `lower(d.state)`
note below.

---

## 🔴 `lower(d.state)` is not stylistic, and Los Angeles County is where it bites

`essentials.districts.state` is mixed case in California. Los Angeles County's **five supervisorial**
district rows carry uppercase `CA`; the **one countywide** row that holds the Assessor, District
Attorney and Sheriff carries lowercase `ca` — a leftover from migration 1635, which consolidated
three duplicate county rows and took the canonical shape from the 57 non-duplicated peers.

A first pass filtering `d.state = 'CA'` therefore reported that Los Angeles County has **no Assessor,
no District Attorney and no Sheriff**. All three exist and are correctly seated. The rule in
CLAUDE.md is load-bearing:

```sql
WHERE lower(d.state) = 'ca'
```

---

## Jurisdiction status

### Long Beach — ✅ CA-1 APPLIED 2026-09-02 (`CC_0053`, `CC_0054`, `X0046`)

**13 offices, 13 people, 0 vacancies.** Nine single-member council districts plus a citywide Mayor,
City Attorney, City Auditor and City Prosecutor, all four-year terms.

Full record: [`backend/data/seed-long-beach-2026/ROSTERS.md`](../../backend/data/seed-long-beach-2026/ROSTERS.md).

Two defects fixed:

1. 🔴🔴 **All nine council district rows shared the city place polygon `0643000`**, so one Long Beach
   address returned **all nine councilmembers**. Repointed onto per-district `X0046` polygons.
2. **All thirteen occupancy rows were undated** — ADR 0002 phase-2 backfill from a `cicero` vendor
   snapshot, never change-checked. Now day-precision from the city's own Legistar.

### Los Angeles County — ✅ already complete, re-verified 2026-09-02, not rewritten

All 8 elected officials (5 supervisors + Assessor, DA, Sheriff) were seated with dated terms by
migration 1635, and the county's own *Salary and Tenure Data* sheet (REV. 08/07/26) agrees row for
row. Nothing was written. Districts 1 and 3, the Sheriff and the Assessor are on the 2026 ballot and
all take office in December 2026; Hilda Solis reaches her term limit.

### San José — ▶ CA-2

10 council districts + Mayor, **all already seated on real per-district polygons** (`X0010`,
geo_ids `sj-council-district-1..10`, source `sj_city_council_districts_2022`). The spatial probe
returns exactly one councilmember, so **San José needs no geometry work**. What it owes:

- All 11 seats carry the same **undated** backfill occupancy Long Beach did. They need the same
  change-check and dated terms.
- San José's 2026 cycle must be read the way Long Beach's was. A certified June result is not an
  occupancy.

### Santa Clara County — ▶ CA-2, and it is the real work in that wave

Three countywide officers exist and are seated with dated terms from migration 1631: **Robert Jonsen**
(Sheriff), **Jeffrey Rosen** (District Attorney), **Neysa Fligor** (Assessor). None has a headshot —
the only headshot debt in this slice.

🔴 **There is no Board of Supervisors at all.** Five seats and five district polygons still to seat,
plus a supervisor-district layer to find and arbitrate.

⚠ **Re-check the Assessor.** `Neysa Fligor` carries `term_start 2026-01-26` at `day` precision — an
unusual mid-term date that migration 1631 wrote and CA-1 did not re-verify. A mid-term start is
normally an appointment or a succession, and neither is recorded.

---

## 🔴 GA-4's two-layer arbitration is UNAVAILABLE in Los Angeles County, and that was measured

GA-4 established the strongest available vintage test: arbitrate two competing council-district
layers against the county's own **ballot-building** table. Neither half exists here.

- **One layer, not two.** Three ArcGIS catalogue searches return exactly one authoritative Long Beach
  service. The only other item carrying the same title is owned by `CRC.Admin` — the Citizens
  Redistricting Commission — and resolves to the **same FeatureServer URL**. The remainder are
  student copies in CSULB accounts. The GA-4 inversion (fresh roster on superseded geometry) cannot
  occur, because there is nothing to invert against.
- **The county publishes no district attributes.** `LACounty_Dynamic/Political_Boundaries/MapServer`:
  - layer **34** `Registrar Recorder Precincts` declares `DST_CITY` and `DIV_CITY` — precisely the
    ballot-building fields GA-4 arbitrated on — and **every row returns NULL for both**;
  - layer **37** `Registrar Recorder Election Precincts` carries real precinct IDs (2,853 of them)
    and **no district fields at all**;
  - the City Clerk's Statement of Votes, which maps precincts to contests, is a **scanned** PDF with
    no text layer.

**Expect the same in San José.** Check Santa Clara County's equivalent before planning CA-2's
geometry arbitration, and plan for a control set instead if it is also blank.

### What replaced it — and the difference is stated, not blurred

**2,700 active business-licence locations, 300 per district**, from the city's own daily-updated
register, each tested for containment by the loaded polygon: **2,700 of 2,700, all nine districts,
zero outside any district.**

⚠ That is a **control**, not an **arbitration**. The register's `COUNCIL_NUMBER` is plausibly derived
by the city from this same boundary layer. What it proves is that the layer is the map the city's own
operational systems route work by, across every district. It does not prove the boundaries against an
outside authority, because no outside authority publishes them. Say which one you have.

### 🔴 A district stamped on a record is a fact about WHEN THE RECORD WAS WRITTEN

The second control set — the city's development-projects layer, which carries a filing date per case
— disagreed on 8 of its 61 points. Split by era it stops being a disagreement:

| Cases filed | n | agree | disagree |
| --- | --- | --- | --- |
| after 2022-12-20 (the 2021 map took effect) | 25 | 24 | 1 |
| before | 36 | 29 | 7 |

Every one of the seven pre-map disagreements moves the way the 2021 redistricting moved — downtown
addresses stamped District 2 now sit in District 1. The single post-map outlier sits **2,083 m** from
the district it claims, and a boundary question cannot be two kilometres wide.

---

## 🔴 The uncovered ground is water, and the loader checks it rather than assuming it

| Measure | sq mi |
| --- | --- |
| TIGER place `0643000` total | 77.85 |
| ...of which **land** (TIGERweb) | **50.67** |
| ...of which water | 27.18 |
| Union of the nine council districts | **53.06** |
| Place area covered by no district | 24.83 |

A 24.83 sq mi hole would be alarming if it were land. It is a single contiguous piece whose
representative point sits in the outer harbour, and the districts cover 53.06 against 50.67 of land —
every acre, plus about 2.4 sq mi of harbour. The loader's gate is `union >= land area`, not a
judgement about the shape of the number.

⚠ Long Beach and San José are both coastal, and San José's ten districts union to 180.7 against a
181.06 sq mi place polygon. Do the same land/water split before reading any gap as a defect.

---

## 🔴🔴 California cities set their own election calendars, and the authoritative page can be STALE

Long Beach's own City Clerk still publishes an elections FAQ quoting the **pre-2020** Charter
Sec. 1901: April primary, June general, and *"candidates elected to office shall assume such office on
the third Tuesday in July."* That has not been true since 2018. The current rule — a June primary, a
November general and terms commencing on the **third Tuesday in DECEMBER** — is stated by the 2026
candidate packet, by the two 2026 Council resolutions appointing unopposed officers, and by Legistar's
own turnover dates.

> **A stale page on the authoritative site is more dangerous than a missing one.** Read for the
> calendar alone it would have dated every Long Beach term four to five months early, consistently
> enough to look right.

Take the calendar from **the current cycle's candidate packet**, never from a general FAQ.

---

## 🟢 Legistar is the best occupancy source found in this slice

`webapi.legistar.com/v1/longbeach/...` — no key, no WAF — publishes **day-precision** office records
with start and end dates per person per body:

```
/v1/longbeach/bodies                    list the bodies
/v1/longbeach/bodies/{id}/officeRecords  City Council = 1, City Attorney = 29, Auditor = 30, Prosecutor = 31
/v1/longbeach/persons/{id}/officeRecords the Mayor sits in his own body, reachable only this way
```

Its chains are gapless by one day, which is what makes it checkable: Burroughs ends 2006-06-30 and
Doud starts 2006-07-18; Parkin ends 2022-12-19 and McIntosh starts 2022-12-20.

**Check whether San José publishes Legistar too before hand-assembling its dates.**

Two failure modes found, both of which a single-source read would have swallowed:

- 🔴 **It dates one occupancy from the ELECTION, not the swearing-in.** Doug Haubert starts
  2010-04-13, the date of the primary he won, while his predecessor's record runs to 2010-07-19.
  Taken literally, both men held the office for three months.
- 🔴 **It stops.** No `officeRecords` row starts after **2024-12-17**, so the entire December 2024
  cohort is absent — Tunua Thrash-Ntuk has a person record and no office record.

Both were resolved from the predecessor's end date plus the charter rule plus the certified result,
and both are labelled `derived:` in the row's own `source` column.

---

## 🔴🔴 The change-check found a scheduled turnover, and refused to write it

Long Beach's Primary Nominating Election was held 2026-06-02 and is certified. It decided **seven of
the thirteen seats outright**. **None of those winners is in office**, because terms commence
2026-12-15.

> **DISTRICT 7 HANDS OVER TO VIVIAN MALAUULU ON 2026-12-15.** Roberto Uranga is term-limited — the
> candidate packet prints *"Not eligible to run for an additional term due to term limits"* against
> his name — and Malauulu won outright with 74.12%. She is **not** in the database. A certified result
> is not a fact about who holds the seat.

⚠ Also note **what a missing contest can mean**. City Attorney and City Prosecutor do not appear in
the 2026 results file at all. That is not a gap: LBMC 1.15.150 lets the Council **appoint** a sole
nominee and cancel the contest, and both resolutions are on file. A cancelled election looks exactly
like a missing result unless you go looking.

⚠ And **losing then winning is not continuous occupancy.** Tunua Thrash-Ntuk lost District 8 in 2020
(43.23% to Al Austin) and won it in 2024. Her occupancy starts 2024-12-17. A roster read without the
certified results would have got this wrong in the safe-looking direction.

---

## Allocations taken by this slice

| Sequence | Taken | For |
| --- | --- | --- |
| `CC_` | `CC_0053`, `CC_0054` | Long Beach geometry repair, Long Beach occupancy dates |
| `X` (private MTFCC) | `X0046` | Long Beach council districts |

🔴 The `CC_` ceiling was **`CC_0052`** measured across **138 refs** on 2026-09-02 — five slots above
what `MEMORY.md` and the GA-5 handoff recorded, and GA-5 itself had already had to renumber
`CC_0045`/`CC_0046` to `CC_0049`–`CC_0051` after a master collision. **Sweep every remote ref, and
re-count immediately before the rename.**

---

## Banners

`long beach` and `san jose` are both already live `CURATED_LOCAL` keys in the **essentials** repo
(`src/lib/buildingImages.js`), scoped `CA`:

- `long beach` — Long Beach from Queensway Bay | Christophe.Finot | CC BY-SA 2.5
- `san jose` — Downtown San Jose skyline panorama | XAtsukex | CC BY 3.0

Both **predate the program's certification standard** (compose 1700x540 first, then preview both
boxes). CA-3 re-certifies them rather than replacing them, and checks §8.1 adjacency against
`states/california.jpg`, which has not been examined.

⚠ Neither Los Angeles County nor Santa Clara County has its own county-tier key, and on the Florida
precedent it should not get one: Manatee, Leon and Miami-Dade never did. Palm Beach County got a key
because it has **no city half**. Both California counties have one.
