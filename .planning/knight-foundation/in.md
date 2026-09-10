# Indiana — slice 4 notes

Program tracker: [`PROGRAM.md`](./PROGRAM.md) · Spec:
[`2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

Jurisdictions: **Fort Wayne** (Allen County) and **Gary** (Lake County).

Stage 1 is closed — Indiana's TIGER polygons were loaded in February 2026, before the program
existed. Stage 2 is this wave.

## 🔴🔴 INDIANA'S LEGISLATURE IS PARTIALLY SEATED, AND ITS 18 SEATS HANG ON 18 FAKE CHAMBERS

Measured against production 2026-09-10, as `ev_api`.

Every earlier slice was one of two clean shapes: a legislature at 0 (FL, GA) or a legislature at
100% (CA, CO, NC). **Indiana is neither, and the difference is not only the count.** The 18 seats
that exist are modelled wrongly, so IN-2 is a **repair and a seed in one wave** — the Long Beach
shape, one tier up.

### What exists

| Measure | House | Senate |
| --- | --- | --- |
| TIGER polygons (`G5220` / `G5210`, `census_tiger_2024`) | **100** | **50** |
| `essentials.districts` rows | **12** | **6** |
| Offices | **12** | **6** |
| Seated (`count(och.politician_id)`) | **12** | **6** |
| Districts still to create | **88** | **44** |

150 polygons, 18 districts, 132 missing. The polygon half of stage 1 is genuinely complete: every
one of the 18 district rows pairs to a polygon on `(geo_id, mtfcc)`, and the 132 orphan boundaries
are orphaned only because no `districts` row points at them yet.

### 🔴 THE DEFECT: ONE CHAMBER PER DISTRICT, `official_count = 0`

`State of Indiana` carries **46 chambers**. It carries **no `Indiana House of Representatives`
chamber and no `Indiana State Senate` chamber.** Instead there are 18 chambers named for a single
district each:

```
Indiana House of Representatives - District 45     official_count 0    1 office
Indiana State Senate - District 33                 official_count 0    1 office
...
```

`count(DISTINCT o.chamber_id)` over `STATE_LOWER` is **12 across 12 offices**, and over
`STATE_UPPER` is **6 across 6**. FL and GA are 1 and 1.

🟢 **THE DEFECT IS INDIANA-ONLY.** Swept across every state: Indiana is the *only* one where a
legislative chamber count exceeds 2. Nothing else in production has to be repaired to fix this.

🟢 **AND NOTHING DEPENDS ON THE 18.** The three tables carrying a `chambers` FK —
`meetings.meetings`, `essentials.discovered_sources`, `essentials.source_outlets` — hold **zero**
rows against any of the 18 chamber ids. The only referents are their own 18 offices.

⚠ **The same shape exists on Indiana's courts and is NOT this wave's business**: five separate
`Supreme Court` chambers of one office each, and eleven `Indiana Appeals Court Judge - District N`
chambers. Recorded here so the next reader knows it was seen and left alone, not missed.
[`project_indiana_appellate_districts`] is the related note.

### 🔴 THE 18 OCCUPANCIES ARE UNDATED VENDOR BACKFILL

All 18 politicians carry `source = 'ballotready'`; all 18 terms carry
`start_precision = 'unknown'`, a NULL `term_start` and
`source = 'backfill from essentials.off…'`. Not one is dated.

This is exactly what CA-1 found in Long Beach, where all 13 rows were undated vendor backfill and
`CC_0054` re-dated them from the city's own Legistar. The Indiana equivalent is the General
Assembly's own member pages.

⚠ **`office.title` also disagrees with the house style.** These 18 carry the district name as the
title (`Indiana House of Representatives - District 45`); FL and GA carry `Representative` and
`Senator`, with the district on the *district*.

### The 18 already seated

House: 45 Borders · 46 Heaton · 60 Mayfield · 61 Pierce · 62 Hall · 63 Lindauer · 65 May ·
96 Porter · 97 Moed · 98 Shackleford · 99 Summers · 100 Johnson.
Senate: 33 Taylor · 37 Bray · 39 Bassler · 40 Yoder · 44 Koch · 46 Hunley.

🔴 **These 18 need the same change-check as the other 132, not less of one.** They were written by
a vendor at an unknown date, so "already seated" says nothing about whether the person still holds
the seat. The Knight rule stands: the check asks *has this person left?*, and the General
Assembly's own roster is what answers it.

### ⚠ `18046` IS TWO DISTRICTS, AND IT COST ME A WRONG BASELINE FIRST TIME

A `LEFT JOIN` from `districts` to `geofence_boundaries` on `geo_id` **alone** returned 25 House and
18 Senate district rows. The true counts are **12 and 6**. Indiana's `sldl` range runs 18001–18100
and its `sldu` range 18001–18050, so every Senate geo_id collides with a House one — `18046` is
House District 46 **and** Senate District 46 — and the fan-out inflated both numbers.

The spec already says to pair `geo_id` with `district_type` in every join. This is that rule
failing loudly enough to be worth restating: **the wrong number was plausible**, off by exactly the
kind of margin a partially-seeded state would produce.

## The roster — two sources, 150 seats, zero disagreements

| Source | What it is | Rows |
| --- | --- | --- |
| **A** `iga.in.gov/api/getLegislators?session_lpid=session_2026` | The General Assembly's own list, behind its React front end | **151** |
| **B** `data.openstates.org/people/current/in.csv` | Open States, a third party | **150** |

Reconciled: **150 seats, 100 House + 50 Senate, all distinct, 0 disagreements** on the holder.

🔴 **SOURCE A IS OVER-LONG BY ONE, AND THE MARKER IS A NULL DISTRICT.** Indiana keeps the departed
member in the list and blanks the district rather than removing the row. Senator **Andy Zay** is
the 151st: `"district": null`. He resigned effective **2026-01-08** on appointment to chair the
Indiana Utility Regulatory Commission, and **Nick McKinley** took SD-17 on **2026-02-09**. The rule
is therefore `district != null`, which is Georgia's `dateVacated == null` in a different dress. Do
**not** de-duplicate on name or district.

🟢 **THAT TURNOVER ALSO DATES THE SOURCES.** Both A and B independently show McKinley in SD-17, so
both are current to at least 2026-02-09 — and Open States carries 150 rows with no Zay, agreeing
with the rule rather than merely with the list.

### 🔴 THE 0-DISAGREEMENT RESULT WAS CONTROLLED BEFORE IT WAS BELIEVED

A uniform answer is a broken detector until a positive control passes. Three defects were planted
into source B and the diff was re-run:

| Control | Planted | Reported | Verdict |
| --- | --- | --- | --- |
| 1 | nothing | 0 disagreements | baseline |
| 2 | SD-17 surname corrupted | 1 — `upper-17 IGA:McKinley vs OS:Zzzcontrol` | ✅ |
| 3 | HD-1 row deleted | 1 — `lower-1 OPENSTATES MISSING` | ✅ |
| 4 | SD-17 moved to SD-99 | 2 — `upper-17 OPENSTATES MISSING` + `upper-99 IGA MISSING` | ✅ |

Three distinct defect shapes, three correct and *distinguishable* reports. The 150/150 agreement is
real, not a detector that returns "fine" to everything.

### 🔴 THERE IS NO `term_start` TO BE HAD, AND NONE IS INVENTED

`getLegislatorDetails` — the richest per-member endpoint the site has — returns exactly this:
`lpid, honorific, firstname, lastname, statephone, district_id, party, busemail, contact_form_url,
caucus_page_url, bills[], committees[]`. **No service-start of any kind. No portrait URL either.**

So every Indiana term is written open-ended at `start_precision = 'unknown'`, which is the GA-2
pattern (all 235 of Georgia's terms are `unknown`) and is what the 18 existing Indiana rows already
carry. ⚠ **Stage 5 will need the four caucus sites for portraits** — the API has none, though the
Open States CSV carries an `image` column worth measuring first.

### ⚠ A 200 THAT CARRIES THE SPA SHELL, ON THE SAME HOST THAT SERVED JSON A MINUTE EARLIER

`getLegislators` answers curl with JSON. `getLegislatorDetails` answers curl with **HTTP 200, 691
bytes of `<!doctype html>`** — the React shell — and it does so with a browser UA, with a `Referer`,
and with `X-Requested-With`. It answers an in-page `fetch()` with 7,548 bytes of JSON. Two endpoints
on one host disagree about who may read them, and **neither returns an error code to say so**. Only
a full decode catches it; `r.ok` and the status line both say success.

## 🔴🔴 THE REAL FINDING: 671 UNREACHABLE INDIANA OFFICES, AND 92 OF THEM ARE MY ROSTER

`essentials.politicians` holds **672 rows sourced `indiana_discovery`**, of which **671 hold an
office with no `district_id`, no `chamber_id` and no government**:

| Orphan office title | Count |
| --- | --- |
| Indiana Elected Official | 305 |
| State Representative | 231 |
| State Senator | 102 |
| Governor / SoS / Lt Gov / AG / other | 33 |

These are the "stranded officeholders" of
[`project_indiana_address_reachability`], measured at full size for the first time. **No address can
ever reach them**, and nothing errors.

**92 of the 150 sitting legislators are in this cohort.** The overlap, measured:

| Group | Seats |
| --- | --- |
| Already a `ballotready` row, seated on a real office | **18** |
| Already an `indiana_discovery` row, holding an orphan office | **92** |
| No matching person row at all — genuinely new | **47** |

(The three groups overlap slightly where a seat has both kinds of row; 18 + 92 + 47 is not 150.)

🟢 **THE MATCH IS UNAMBIGUOUS.** Not one of the 150 roster names matches more than one
`indiana_discovery` row. The GA lesson — that 2 of 4 name hits were a Colorado senator and a Utah
treasurer — was tested for here and does not arise.

🟢 **AND THE 92 CARRY NOTHING.** Zero stance answers, zero photographs, between them. Reuse
preserves no data; it only avoids manufacturing duplicates.

### Ruling R2 (Cantrell, 2026-09-10): reuse the 92, leave the orphan offices

Seat the existing 92 person rows on the new district-backed offices, create 47 new people, reuse
the 18 already seated. **No duplicate person rows are created.**

Their orphan offices are **left untouched and recorded as a debt**, not cleaned here. Two reasons,
and the second is the load-bearing one:

1. My 92 are a seventh of 671. Retiring only them leaves 579 and makes the cohort harder to reason
   about, not easier.
2. **Closing a term without flagging the office vacant pushes `essentials.offices_missing_terms`
   drift up**, and that unflagged count is the number CI watches. A cleanup wave has to flag as it
   closes, deliberately, across the whole cohort — that is its own wave, not a side effect of this
   one.

⚠ **The consequence, stated so it is not discovered later:** after IN-2, each of those 92 people
holds **two** offices — the real, reachable one this wave creates, and the orphan one. That is
visible in any per-person office count, and it is expected.

### Ruling R1 (Cantrell, 2026-09-10): full repair of the 18

Create the two real chambers, repoint all 18 existing offices onto them, normalise their titles to
`Representative` / `Senator`, then delete the 18 emptied pseudo-chambers.

## 🟢 STAGE 1 RE-CHECKED: THE POLYGON VINTAGE IS CORRECT, AND THE 2026 REDISTRICTING WAS A DIFFERENT MAP

Indiana's `sldl`/`sldu` polygons are `census_tiger_2024`, loaded 2026-02-11/12 — before this
program existed, which is why stage 1 reads ✅ without a Knight wave behind it.

The 2025–26 Indiana redistricting fight was **congressional only**, and it **failed**: the House
passed a new congressional map 57–41 on 2025-12-05 and **the Senate rejected it 31–19 on
2025-12-11**, 21 Republicans joining 10 Democrats. **No state legislative map was redrawn**, so the
2021 enacted plan still governs and TIGER 2024 is the right vintage.

⚠ **This is reasoning, not the GA-1 geometric proof.** GA-1's standard was to compare the state's
own published GeoJSON against every TIGER polygon at its own interior point — 180/180 and 56/56.
Indiana has **not** had that treatment. It is a task in this wave, before 132 offices are written
onto those polygons, not an assumption to carry.
