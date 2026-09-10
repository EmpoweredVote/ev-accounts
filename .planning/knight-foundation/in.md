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

## ✅ THE VINTAGE IS PROVED, NOT ARGUED — 150 / 150 AT GA-1 GRADE

`scripts/verify-in-legislative-vintage.mjs`. The General Assembly draws its own district overlay
on Find Your Legislator from two KMZ files it publishes itself:

```
/publications/maps/senate-districts/senate_2021.kmz    50 placemarks, KML dated 2022-04-29
/publications/maps/house-districts/house_2021.kmz     100 placemarks, KML dated 2022-04-29
```

Every one of the 150 TIGER polygons was tested at its own `ST_PointOnSurface`, against those
placemarks, with holes honoured:

```
House  100 / 100 agree
Senate  50 /  50 agree
total  150 / 150 agree, 0 disagree
```

Four planted controls passed first, including the one that matters most here:

| Control | Planted | Reported |
| --- | --- | --- |
| 1 | nothing | 0 |
| 2 | HD-45 geometry removed | 1 |
| 3 | **SD-17 and SD-18 swapped** — the layer-inversion failure | 2 |
| 4 | HD-99 given HD-100's geometry as well — ambiguity, not absence | 1 |

Control 3 is the Knight rule "TWO GIS LAYERS CAN INVERT" planted deliberately, so a detector that
merely counts coverage cannot pass this suite.

### 🔴🔴 THE SAME HOST SERVES JSON TO curl AND A REACT SHELL TO curl, AND BOTH ARE HTTP 200

`getLegislators` answers curl with real JSON. `getLegislatorDetails` and **both KMZ URLs** answer
curl with **HTTP 200 and 691 bytes of `<!doctype html>`** — with a browser user agent, with a
`Referer`, and with `X-Requested-With`. The same KMZ URLs answer an in-page `fetch()` with
**1,694,603** and **2,430,264** bytes beginning `PK\x03\x04`.

A script that trusted `%{http_code}` would have written a 691-byte file called `senate_2021.kmz`
and moved on. **Only a full decode catches it** — check the magic bytes and the length, never
`r.ok`, and never the status line. This is the WAF lesson, but it is not a WAF: it is the SPA's own
catch-all route answering for a path it does not recognise.

## ✅ THE ROSTER IS LOCKED — `data/in-legislature-roster.json`

`scripts/build-in-legislature-roster.mjs --self-test`. 150 seats, 100 House + 50 Senate, every
`geo_id` of the form `18` + three digits, every one resolving to a TIGER polygon in production:

| | Count |
| --- | --- |
| Roster seats | **150** |
| With a TIGER polygon | **150** |
| With a `districts` row already | **18** |
| District rows still to create | **132** |

Party is dropped at the roster boundary — it lives on `races.primary_party`, never on a person or
an office. `openstates_image` is carried for stage 5 only, and is **unmeasured**: the IGA API
publishes no portrait at all, so that column is the wave's only lead and has to be profiled before
it is trusted.

## ✅ ROSTERS.md AND BOTH MIGRATIONS ARE WRITTEN AND DRY-RUN CLEAN — NOT APPLIED

`CC_0088_in_legislature_structure.sql` and `CC_0089_in_legislature_incumbents.sql`. **Both slots
were reserved from the allocator**, not counted. Generated by
`scripts/gen-in-legislature-migrations.mjs`; `ROSTERS.md` by `scripts/gen-in-rosters-md.mjs`, so
the 150-row table is machine-generated and carries no transcription risk.

### What the two migrations do

| | `CC_0088` structure | `CC_0089` occupancy |
| --- | --- | --- |
| Chambers | **+2** (House 100, Senate 50) | — |
| Districts | **+132** (88 House, 44 Senate) | — |
| Offices | **+132**, and **18 repointed and retitled** | — |
| Pseudo-chambers | **−18**, guarded on emptiness | — |
| People | — | **+48 created**, **84 reused** |
| Terms | — | **+132**, all open-ended at `unknown` |

### The seat resolution, and why 92 became 84

| Disposition | Seats |
| --- | --- |
| **repair** — office already exists, holder kept | **18** |
| **reuse** — seats an existing `indiana_discovery` person | **84** |
| **new** — person created in `CC_0089` | **48** |

🔴 **EIGHT PEOPLE HAVE TWO PERSON ROWS EACH, AND THAT IS THE WHOLE OF THE 92 → 84 GAP.** HD-46,
HD-63, HD-96, HD-99, HD-100, SD-37, SD-39 and SD-44 each hold **both** a `ballotready` row (which
has the office) and a duplicate `indiana_discovery` row. The `ballotready` row keeps the seat;
neither is merged. Merging is a decision about *identity*, not about seating, and is not made
inside a seeding wave.

⚠ **HD-100 is the one to read twice.** Production says **Robert B Johnson**; the General Assembly
says **Blake Johnson**. Same man — Ballotpedia files him at `Robert_Blake_Johnson`. A surname-only
match would have passed this without ever noticing the first name differed.

### 🔴 R3 — THE HOST GOVERNMENT IS CHOSEN, NOT ASSUMED

There are **22** government rows named `State of Indiana`, every one `type` STATE, `state` IN,
`geo_id` NULL — indistinguishable by attribute. **Every other state in production has exactly
one.** The 18 pseudo-chambers are spread across **18 of them**, one each.

`e00dba00-b293-499c-ad67-6f52ab8f4d7c` hosts the legislature: the only row carrying correctly
modelled statewide chambers — Comptroller, Secretary of State, Treasurer, Utility Regulatory
Commission — with real `official_count` values. The other 21 are an import artefact and are **left
alone**; after `CC_0088`, 17 of them hold no chamber at all. Consolidating them is a larger repair,
and half-doing it is worse than scheduling it — the same argument as the orphan offices.

### 🔴 R4 — THE NEW DISTRICTS MATCH THE *CURRENT* LOADER, AND THE LEGACY 18 ARE LEFT UPPERCASE

`load-state-tiger-boundaries.ts` writes `state` as a **lowercase** abbreviation (line 719,
`FIPS_TO_STATE[fips]`) and labels sldl/sldu `State House District N` / `State Senate District N`.
That is why GA, FL, CO and NC are lowercase — **1,910 legislative district rows across 15 states**,
against **319 uppercase in only CA, IN and TX**. Indiana's legacy 18 came from an older loader.

The 132 new rows match the **current** loader, so a future loader run on Indiana is a **no-op**
rather than a duplicate-maker.

⚠ **The legacy 18 are deliberately NOT normalised, and I nearly did normalise them.** Live read
paths compare `d.state = $1` **case-sensitively** against an upper-cased argument
(`essentialsBrowseService.ts:100,996` → `districtQueries.ts:218`). Those queries filter to
statewide `district_type`s and so cannot see a `STATE_LOWER` row — but proving that for *every*
caller is a bigger claim than a seeding wave needs to make. **Indiana therefore carries both cases,
and every read must keep using `lower(d.state)`.**

### ✅ Dry run — both migrations as ONE transaction, and the rollback was verified

```
INSERT 0 1 · INSERT 0 1 · INSERT 0 132 · UPDATE 18 · INSERT 0 132 · DELETE 18
NOTICE:  IN-2 structure OK: 2 chambers, 100+50 districts, 100+50 offices, 0 pseudo-chambers
INSERT 0 48 · INSERT 0 132
NOTICE:  IN-2 occupancy OK: 150 offices, 150 seated, 0 dated, 0 ended
ROLLBACK
```

**Production was re-measured afterwards and is untouched:** 12 House / 6 Senate districts, 18
offices, 18 pseudo-chambers, **0** real chambers, **0** people in the reserved band. The rollback
reverted — confirmed, not assumed.

⚠ The first dry-run attempt aborted on a mis-escaped `\echo` **before** reaching the explicit
`ROLLBACK`, and `psql` rolled back on disconnect. That is the right outcome by luck, not by design.
The run above is the one that ends in an explicit `ROLLBACK` with exit 0.

### ✅ Gates green

| Gate | Result |
| --- | --- |
| `check:migrations` | OK — 2 added vs `origin/master`, 1872 slots across 126 refs, tree scan clean |
| `check:reservations` | OK — both slots reserved by their own author |
| `check:occupancy` | OK — 6 files scanned, no writes to the dropped `offices.politician_id` |

## ▶ WHAT REMAINS FOR IN-2

1. **Apply** `CC_0088` then `CC_0089` through `psql`, in that order — they are one unit.
2. Write and run `scripts/verify-in-legislature-probes.sql`: the four-answer probe at **Fort Wayne**
   and **Gary** city halls, plus a **per-district positive control** — all 150 districts resolving
   individually. 🔴 `check:reachability` green means "nothing regressed", **not** "your districts
   were swept"; it takes no probe list.
3. Re-measure `essentials.offices_missing_terms` — the unflagged count must not move.
4. Update `PROGRAM.md`: stage 2 ✅, and the legislature's portraits belong **inside** stage 5, not
   beside it (the GA-6 lesson). Indiana's 150 have **no portrait in the API at all**; the Open
   States `image` column is the only lead and is unmeasured.
