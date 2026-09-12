# Indiana — the four debts, and how to pick them up cold

**▶ STATUS 2026-09-12 — ALL FOUR ARE CLOSED.** (Debt 5, the orphaned `Mayor` chamber, is still open
and is not Indiana's.)
**Debt 2 CLOSED** (`CC_0098`): the 17 unreferenced `State of Indiana` rows are gone, 5 remain.
**Debt 4 half closed**: the six Gary portraits are imported, stage 5 is **192/204**, and the
remaining 12 blanks are all settled by ruling or by absence of any source.
**Debt 3 CLOSED 2026-09-11** (`CC_0099` + `CC_0100`): the geometry was found, vintage-proved and the
seven members seated. **Lake County is 19 of 19.** **Debt 1 CLOSED** across `CC_0101`-`CC_0104`: flags, identity merge, then both halves of the retirement. A fifth item was found while closing Debt 2;
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

## Debt 1 — the `indiana_discovery` orphan cohort · **STEP 1 APPLIED 2026-09-12 (`CC_0101`)**

**671 people hold 755 offices; 671 of those offices have no district, no chamber and no
government.** Ruling (Cantrell, 2026-09-12): **flags first, retirement second.** Step 1 is applied.

### 🔴🔴 WHAT THE COHORT ACTUALLY IS: A CAMPAIGN-FINANCE SWEEP, NOT A ROSTER

Every one of the 671 came from a candidate-committee filing
(`transparent_motivations.politician_sources`, `source_type = 'candidate_committee'`). Every orphan
term is the same thing — the ADR 0002 phase-2 backfill, `start_precision = 'unknown'`, no start, no
end. **The office title records the seat the person SOUGHT OR HELD, and nothing distinguishes the
two.**

▶ **The diagnostic title is `Governor`, which holds TEN people.** Pence, Holcomb and Braun — three
different real governors — plus McCormick, Melton, Myers, Owens and three more who only ran. Read
that table and the cohort explains itself; read the count alone and it does not.

⚠ **NO FIELD IN THE ROW SEPARATES A FORMER GOVERNOR FROM A FAILED CANDIDATE.**
`total_years_in_office` null on all 671, `bio_text` null on 668, `valid_from` null on all 671,
`is_incumbent` **true on all 671**. The database holds no signal. Do not go looking for one.

### 🔴🔴 THE READ PATHS ARE NOT BROKEN. THE FLAGS WERE.

Production holds **77,001** placeholder occupancies, and they split by the script that made them:

| source | placeholder rows | `is_active` | `is_incumbent` |
| --- | --- | --- | --- |
| `cal_access_discovery` | 76,330 | **0** | **0** |
| `indiana_discovery` | **671** | **671** | **671** |

Every politician-rooted read path guards on `is_active` and/or `is_incumbent`, so California's
76,330 pass through harmlessly. Indiana's leaked, because
`scripts/discover-indiana-candidates.ts:407-408` inserts both true where the CalAccess script
inserts both false.

🔴 **THE FIRST ANSWER WAS THE WRONG ONE, AND IT WAS THE EXPENSIVE KIND OF WRONG.** A sweep of
`backend/src` found `is_placeholder_occupancy` referenced **zero times** and concluded that all
77,001 were exposed and five join sites needed a filter. **Comparing the two cohorts' flags
overturned that**: the guards already work for 99.1% of the population. ▶ **When a defect looks
systemic, find the population that DOESN'T have it and ask what is different about them.**

### What leaked, measured rather than inferred

- Indiana's browse-page officeholder count read **1,252**. Real figure **581**. 54% inflated, and
  **Indiana was the only state affected** — `essentialsBrowseService.getStatesWithData` is the one
  rollup rooted at `offices` instead of `districts`.
- `GET /api/essentials/politicians?q=` returns **two rows** for a person holding two offices.
  ⚠ **The code comment above that join (`essentialsService.ts:517-519`) says "One row per office,
  so this cannot fan out."** True joining FROM offices; false joining FROM politicians, which is
  what that query does. A guarantee written for one direction, relied on in the other.
- `getPoliticianById` reads `o.title` off `rows[0]` of an unordered join, so a profile can render
  **"Governor" for someone who is not the governor**.

### The three classes

| class | count | what it is | disposition |
| --- | --- | --- | --- |
| **A** | **84** | the SAME person row holds a real seat *and* an orphan duplicate of it (Aaron Freeman: real Senator + orphan "State Senator") | retire the orphan office only — **never the flags**, they are sitting legislators |
| **B** | ~66 | a SEPARATE row for someone already seated in Indiana (Michael Braun / Mike Braun) | identity merge, deferred — see below |
| **C** | ~521 | no Indiana seat under any name: former officeholders, losing candidates, never-helds | flags, then retire |

### ✅ Step 1 — `CC_0101`, applied 2026-09-12

Sets `is_active = false, is_incumbent = false` on the **587 orphan-ONLY** people (B + C). Deletes
nothing. 🔴 **The `NOT EXISTS` clause is the whole safety property** — a control was watched firing
on prod in a rolled-back transaction: without it the predicate selects **671** and the first person
it deactivates is **Aaron Freeman, a sitting Indiana state senator.**

🟢 **THE POST-VERIFY GATE CAUGHT ITS OWN AUTHOR.** It asserted the browse count would fall to 581;
the dry run returned **665**. The 84 dual-holders stay active by design, so their orphan offices
stay in that count. 1252 − 587 = 665, and 665 − 84 = 581 after step 2. **The residual 84 is the
measure of what step 2 is for.**

| after step 1 | |
| --- | --- |
| Indiana browse count | 1,252 → **665** |
| `Governor` orphans reachable by name search | 10 → **0** |
| rows deleted | **0** (672 people still present) |
| dual-holders still active | **84**, untouched |
| ❌ "Aaron Freeman" search rows | **still 2** — he is one of the 84 |

⚠ **WHAT IT COST, RULED ACCEPTABLE:** `campaignFinanceSearchService` filters `p.is_active`, so
those 587 left campaign-finance search. That makes Indiana consistent with CalAccess's 76,330,
which were already excluded the same way.

### ✅ Step 2a — class A retired 2026-09-12 (`CC_0103`)

**84 duplicate offices deleted, with their 84 placeholder terms.** No person deleted, no flag
touched, and the other 587 orphan offices untouched.

The bar for a DELETE was met by showing the row asserts nothing: no district, no chamber, no
government, no city; a term from the phase-2 backfill with no dates and `precision 'unknown'`;
**0 races** referencing it and **0** legacy `politicians.office_id` snapshots pointing at it. And
the title is the same seat, measured across all 84 rather than assumed:

| orphan title | real seat | n |
| --- | --- | --- |
| `State Representative` | Representative | 33 |
| `Indiana Elected Official` | Representative | 23 |
| `State Senator` | Senator | 18 |
| `Indiana Elected Official` | Senator | 10 |

**Not one contradicts.** Nobody holds a House seat plus an orphan "Governor".

🟢 **A control was watched firing, and then kept in the migration.** The broad predicate (any
orphan office held by an `indiana_discovery` person) selects **671**; adding "holder also holds a
real seat" selects **84**. The pre-flight asserts both, so the day the restriction stops
discriminating the migration refuses to run.

| | before | after |
| --- | --- | --- |
| "Aaron Freeman" rows from the search query shape | **2** | **1** |
| Indiana browse count | 665 | **581** — the figure `CC_0101` predicted |
| orphan offices | 671 | **587** |
| `indiana_discovery` people | 672 | **672** |
| `offices_missing_terms` | 822 / 655 | **822 / 655**, unchanged |

▶ The end-to-end assertion is **in the gate**: it runs the search endpoint's own query shape for
Aaron Freeman and requires exactly 1 row.

### ✅ Step 2b — the remaining 587 retired 2026-09-12 (`CC_0104`)

**587 orphan offices deleted with their 587 placeholder terms. The cohort is closed: Indiana holds
ZERO placeholder occupancies.** System-wide the count falls 77,001 → **76,330**, all CalAccess.

This was the harder half and the reason is worth keeping. Class A was a duplicate of a better row.
**These 587 people hold no other office at all**, so the delete leaves them with none. It is still
right, because the row is FALSE for every one of them: for a former officeholder — Pence, Holcomb,
Connie Lawson, Rebecca Skillman, Jon Ford — it asserts the office in the **present tense**, and it
carries no dates, so it does not record that they once held it; for a losing candidate it is simply
wrong. ▶ **The title records the office SOUGHT, not one held.**

⚠ **Nothing in the row tells the two apart** — no `total_years_in_office`, no `bio_text` on all but
three, no `valid_from`, every term the undated phase-2 backfill. Which is exactly why one
disposition fits both: unreachable, undated and untrue either way.

🟢 **WHAT SURVIVED IS THE PART WORTH KEEPING.** The FK on `politician_sources` is to the PERSON:

| | kept |
| --- | --- |
| people | **672**, all of them, deactivated |
| candidate-committee sources | **537** on the 588 who now hold nothing, **84** on the class A people = 621 |
| researched stance answers | **79**, across 7 people, including Jon Ford's 11 |

**Deleting an office loses no research.** If a later roster wave seats any of them properly, their
stances and finance record come with them.

🟢 **The control changed shape between the two steps, on purpose.** `CC_0103`'s clause was "the
holder ALSO holds a real seat" (84 of 671). Afterwards every remaining orphan is held by an
INACTIVE person — measured 587 inactive, **0 active** — so `CC_0104` asserts both halves. An active
holder appearing in that set means a class A row has come back, and it refuses to run.

⚠ **The gate that actually proved nothing was lost was the TABLE-WIDE one**: `politician_sources`
and `politician_answers` totals captured before the delete and compared after. A cohort-scoped
count would not have caught collateral damage elsewhere — and an ad-hoc check written afterwards
read 621 against an expected 536 purely because it was measuring a superset.

### Debt 1 — ✅ CLOSED 2026-09-12

| step | migration | result |
| --- | --- | --- |
| 1 — flags | `CC_0101` | 587 orphan-only people deactivated |
| identity merge | `CC_0102` | 55 committee sources repointed to the seated officeholder |
| 2a — class A | `CC_0103` | 84 duplicate offices retired; Aaron Freeman returns 1 row, not 2 |
| 2b — class B/C | `CC_0104` | 587 orphan offices retired; the cohort is closed |

**Indiana browse count: 1,252 → 665 → 581 → 581.** `offices_missing_terms` unchanged throughout at
822 / 655 — these offices always carried a term, so the view never listed them.

▶ **Two things remain, and neither is the cohort.**
1. ✅ **Ronald Turpin — RESOLVED 2026-09-12 (`CC_0105`).** Ruling (Cantrell): *"Ronald Turpin is
   Allen County Commissioner — not state senator."* Same man; his committee source is repointed to
   the seated row, as `CC_0102` did for the other 55.
   ▶ **The doubt was the office mismatch, and that signal was worthless here** — the placeholder
   title records an office SOUGHT for *every* row in the cohort, so it is the population's defining
   property, not a discriminator. **A signal shared by every row cannot separate rows.**
2. ✅ **The `DISTINCT` — FIXED 2026-09-12.** `CC_0103` only removed the 84 Indiana rows that were
   exercising the fan-out; **26 people system-wide hold more than one office**, so it was never
   Indiana's alone. `getPoliticiansFlatList` now dedupes with `DISTINCT ON (p.id)` inside a wrapper
   (its own ORDER BY would otherwise fight the caller's `ORDER BY full_name` and the pagination —
   which also means `LIMIT 50` was counting duplicates and could return fewer than 50 people), and
   `getPoliticianById` now has a deterministic `ORDER BY … LIMIT 1` instead of an arbitrary `rows[0]`.

   🔴🔴 **THE FIRST DRAFT OF THAT ORDERING WAS WORSE THAN THE BUG.** Preferring "a real seat — has a
   district, then a chamber" picked the **migration-196 `Candidate for …` placeholders**, which carry
   a district AND a chamber, so the detail view reported **Harriet Hageman and Angie Craig — both
   sitting U.S. Representatives — as Senate candidates.** The missing rule is the one the list query
   already encodes in its `incumbentFilter`: **a seat HELD beats a seat SOUGHT.** With it, all 26
   resolve to a held office. ▶ **A tiebreak that falls through to a UUID is not deterministic in any
   sense that matters — it is just silent.**

### 🔴🔴 A GUARANTEE IN CLAUDE.md IS HALF TRUE, AND IT LICENSED THE BUG

`CLAUDE.md` line 28 says the view is *"exactly one row per office … so it cannot fan a result set
out"* and then shows **both** join directions under that one guarantee. The claim holds joining
FROM offices. It does **not** hold joining FROM politicians: a person with two offices yields two
rows, which is what made `GET /api/essentials/politicians?q=` return two Aaron Freemans.
`office_terms`' exclusion constraint forbids two people on one office; **it cannot see one person
on two.** The same sentence is repeated in `check-office-occupancy.mjs` (twice) and
`essentialsService.ts` (twice, above the two queries that actually fan out).

### ✅ Class B — REVIEWED AND MERGED 2026-09-12 (`CC_0102`)

All 69 candidate pairs were read by hand (Cantrell) on the review page and the answers read back
from its store: **55 same · 13 different · 1 unsure**. Consistency held — 55 distinct people, no
orphan merged into two targets, and each of the three double-matched orphans resolved to exactly
one target.

▶ **The review page, with every verdict still on it:**
https://claude.ai/code/artifact/12a02219-0d48-413c-a6d4-97a6c5708bb6

🔴🔴 **THE CANDIDATE LIST WAS DIRTY AND INCOMPLETE, AND BOTH FAILURES SHOWED UP IN THE ANSWERS.**
Matching exact full name gives 2, surname+initial 110, surname alone 297, Indiana-restricted 66 —
**the predicate's shape decided the answer**, so none of those was ever "the number of duplicates".
The hand review excluded **Frank Mrvan**, whom the matcher paired with his own son, and included
**Elizabeth Brown / Liz Brown**, whom it could not see because E and L differ on the first initial.

⚠ **THE FORD ROWS ARE WHY THE REVIEW BEATS THE ANNOTATION.** A note on the page argued Jonathan
Ford was the likelier match for J.D. Ford, reasoning from initials. Wrong: **J.D. Ford is JAMES
Ford**, senator for District 29; **JON Ford** is a former senator for District 38 who now heads the
Office of Energy Development. Two independent facts agree with the ruling — this list separately
pairs Gregory Goode with Greg Goode, who holds District 38 now, and James Ford's committee is named
*"Friends to Elect JD Ford"*. ▶ **Reason from the SEAT, not from the initials.**

### 🔴🔴 CC_0101 STRANDED 54 OFFICEHOLDERS' FINANCE DATA, AND THE COST STATEMENT HID IT

The merges turned out to carry no photo, no stances and no race rows — the seated targets already
had photos. They carried exactly one thing: a candidate-committee link, on all 55. And only **1 of
the 55** seated rows had one of its own. So after `CC_0101` deactivated the orphans, **54 sitting
Indiana legislators' campaign finance was reachable only through a deactivated row.**

The cost *was* stated before the ruling — "these leave campaign-finance search" — and accepted on
that framing. ▶ **A COST STATED AT THE LEVEL OF A COHORT CAN HIDE A DIFFERENT COST INSIDE IT.**
"587 candidate rows leave finance search" and "54 sitting legislators lose their finance link" are
the same sentence at two resolutions, and only the second is decidable. **State the sharper one.**

✅ **`CC_0102` repoints all 55** from the duplicate row to the seated officeholder, appending
provenance to `notes` rather than overwriting it. Applied 2026-09-12. Nothing created, nothing
deleted, no person row merged, no flag touched. **181 seated Indiana officeholders now carry a
committee source** — for 54 of them, on their real record for the first time.

🟢 **AN INDEPENDENT CONTROL, FROM A FIELD THE MATCHER NEVER TOUCHED.** Each source row's `notes`
carries the committee's own name. Across the 55: **28** name the seated form and not the orphan's
("MIKE BRAUN FOR INDIANA, INC." on the row called Michael Braun), **10** are surname-only and carry
no signal ("Barrett Election Committee"), **2** carry the legal name against the roster's informal
one (Michael/Mike Aylesworth, Stephen/Steve Bartels). **Not one points at a different person.**

⚠ **`politician_sources.essentials_politician_id` is FK'd `ON DELETE RESTRICT`.** That protection
moved with the row: it now sits on the officeholder, and the emptied orphan rows are free.

⚠ Still open from the review: **Ronald Turpin** (ruled *unsure* — the orphan says State Senator,
the seat is an Allen County commissioner) and the **13 ruled different**, which stay deactivated
and are retired with the rest in step 2.

⚠ **591 committee sources still sit on deactivated `indiana_discovery` rows** — the ~532
orphan-only people with no seated counterpart. That is the accepted cost, not a defect: they are
candidates and former officeholders, and there is no better record to attach them to.

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

## Debt 5 — ✅ CLOSED 2026-09-12 (`CC_0106`)

The one `essentials.chambers` row whose `government_id` pointed at a government that does not
exist — named `Mayor`, `official_count` 1, **0 offices** — is deleted. Chambers: 1176 → 1175, and
zero orphans remain.

🔴🔴 **`essentials.chambers.government_id` HAS NO FOREIGN KEY, WHICH IS HOW IT EXISTED.** Found
while closing debt 2, whose guard had been written as "governments holding no chamber". Reading
`pg_constraint` showed `essentials.governments` has exactly ONE inbound FK and it is not from
chambers — it is `districts.government_id`. ▶ **A COUNT OF CHILDREN IS NOT A COUNT OF REFERENCES
UNTIL YOU HAVE READ `pg_constraint`.** Debt 2's guard was corrected to "no chambers AND no
districts" before it ran, and the count was the same either way — luck, not confirmation.

Safe because it was reachable from nothing. Three tables reference `chambers`, and **two of the
three would not even have blocked the delete**, so their silence had to be asserted rather than
assumed: `meetings.meetings` (NO ACTION — 0 rows, and a row here would have been *evidence the
chamber is real* and wants repointing), `discovered_sources` and `source_outlets` (both ON DELETE
SET NULL — 0 rows each, and either would have been silently blanked).

⚠ **Seven other chambers hold no offices and are untouched.** Their governments exist: they are
empty, not orphaned. The gate asserts that count stays at 7.

⚠ Not Indiana's, and it predated the slice. `CC_0098`'s gate deliberately asserted the orphan count
was *unchanged* rather than zero, so this row would still be here to deal with on purpose.
