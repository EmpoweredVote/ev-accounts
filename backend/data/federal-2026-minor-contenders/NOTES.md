# The last two seeding gaps in LA-01 and VA-11 — `CC_0353`

Worked record for `backend/migrations/CC_0353_federal_2026_seed_minor_contenders.sql`,
applied to production 2026-11-04.

`CC_0352` closed the four seeding gaps that changed an outcome or took more than 20% of a
district, and named the two it deliberately left: the minor candidates in the two races it had
already opened. This closes those two.

| Seat | Person | Party | AP share | AP votes | AP candidateID | Result written |
|---|---|---|---|---|---|---|
| LA-01 | E. Liddy Glass | NPA | 1.62% | 4,279 | 178730 | `lost` / `called` |
| VA-11 | Dianne Blais | Grn | 1.22% | 4,078 | 179330 | `lost` / `called` |

Two politician rows created, two candidacy rows created. **Nothing was updated and nothing was
deleted**, so this file overwrote no citation and destroyed no value.

## Files

| File | What it is |
|---|---|
| `ap-2026-11-04.json` | AP's own metadata + progress for the two races, joined, read 2026-11-04. Byte-identical in substance to the snapshot `CC_0351` recorded, so no count moved between the losers pass and this one. |
| `source-extracts-2026-11-04.txt` | The passage actually read off each source page, tags stripped and whitespace collapsed, nothing else changed. |

## What the sources established

**Identity came from the page, never from a search summary.** The Louisiana Illuminator's
2026-11-03 ballot guide lists the LA-01 field as `(R) Randall Arrington · (No Party) E. "Liddy"
Glass · (D) Lauren Jewett · (R) Steve Scalise` — AP's four names, independently. The Virginia
Mercury's voter guide carries Blais's own entry under "Green Party".

🔴 **A search summary attached the wrong occupation to the wrong candidate, and reading the page
caught it.** A summary of the Wikipedia Louisiana article reported Glass as "an Independent,
special education teacher". The article reads `E. Glass (Independent)` with no occupation, and
`Lauren Jewett (Democratic), special education teacher` on the following line. Jewett's
occupation had already been written into `CC_0352` from her own Ballotpedia biography. Nothing
about Glass's occupation is recorded, because nothing establishes it.

**Both losses are independently established, not inferred from "not the winner".** Ballotpedia
states each outcome in its own words, and each lists the loser by name:

- LA-01 — "Incumbent Steve Scalise (R) won election outright against Lauren Jewett (D), Randall
  Arrington (R), and Liddy Glass (Unaffiliated) in the primary for U.S. House Louisiana
  District 1 on November 3, 2026."
- VA-11 — "Incumbent James Walkinshaw (D) defeated Arthur Purves (R) and Dianne Blais (G) in the
  general election for U.S. House Virginia District 11 on November 3, 2026."

## Why `lost` and not `runoff` in Louisiana

Louisiana's November contest is a **nonpartisan primary**, and `lost` is only the right result
because Scalise cleared 50%. Had he not, the top two would have gone to the 2026-12-12 general
and the right result for the survivors would be `runoff` — which is exactly what LA-05 still is.
Scalise took 60.71%, and Ballotpedia records that "the general election scheduled for
December 12, 2026, was canceled".

## Why `called` and not `certified`

The two sources disagree on the count, which is the point:

| | AP | Ballotpedia |
|---|---|---|
| LA-01 Glass | 1.62%, 4,279 | 1.6%, 4,184 |
| VA-11 Blais | 1.22%, 4,078 | 1.5%, 2,921 |

Neither is final. Ballotpedia's VA-11 total (193,618) is well behind AP's, so it is counting a
smaller return, not a different election. AP's figures are recorded because every other row this
programme wrote carries AP's. A call and a canvass are two facts; the canvass is a later pass,
per state.

## Name variants

| Source | LA-01 | VA-11 |
|---|---|---|
| AP | `E. Liddy Glass` | `Dianne Blais` |
| Louisiana Illuminator | `E. "Liddy" Glass` | — |
| Ballotpedia | `Liddy Glass` | `Dianne Blais` |
| Wikipedia | `E. Glass` | — |
| Virginia Mercury | — | `Dianne Blais` in her entry, **`Diane Blais` in the page's own summary line** |

AP's spelling is stored, as for every other row in this programme. The variants travel in
`politicians.source` so the next pass does not re-derive them.

## Neither person already existed — and the whole table was searched, not the race

This is the `CC_0352` lesson applied before the fact. Jennifer Balkcom read as "a person we do
not hold" only because the losers pass looked for her inside her race while she sat in
`politicians` as a sitting state representative. So both surnames were matched against the
entire table on `full_name` as well as `last_name`, archived rows included:

- `ILIKE '%glass%'` — 24 rows. One real person surnamed Glass: **Jackie Hope Glass** (Nevada),
  a different first name in a different state. The rest are Glassburn / Glasscock / Glasstein /
  Douglass / Jaglassian and CAL-ACCESS committee rows.
- `ILIKE '%blais%'` — 7 rows. **No person surnamed Blais at all.** The rest are CAL-ACCESS
  committee names, plus Blaise Ingoglia, where it is a first name.

⚠ Dianne Blais has run before — VA-10 in 2014 and Virginia House of Delegates 40 in 2011 — so a
historical row was the thing to look for. There is none.

## Controls

Four tampers, each asserted present in its file before it ran, each aimed at a different gate.
**All four fired on the gate they were aimed at**, which `CC_0352` could not manage for one of
its own.

| Control | Fault planted | Gate it was aimed at | Observed |
|---|---|---|---|
| A | Glass's `race_id` mistyped as VA-11's | the named per-person guard | `E. Liddy Glass reads (missing) in LA-01, expected lost` |
| B | an extra `UPDATE` resolving Jim Long, whom AP does not name | the "adds rows, reclassifies none" gate | `5 of the 6 result-less rows in these races are still untouched, expected 6` |
| C | `result_recorded_at` left NULL | the candidacy-shape gate | `0 of the 2 candidacies carry the expected result, expected 2` |
| D | a third seed row, `Dianne Blaise` | the "exactly two people created" gate | `3 politician row(s) created by this file, expected exactly 2` |

## Verified against production after applying

| Check | Result |
|---|---|
| Politicians created by this file | 2 |
| Rows surnamed Glass or Blais | 3 — Jackie Hope Glass plus the two new |
| Glass, LA-01 | `lost` / `called`, `result_recorded_at` stamped |
| Blais, VA-11 | `lost` / `called`, `result_recorded_at` stamped |
| Federal rows marked `won` | 411 — unchanged |
| Federal rows marked `lost` | 604 (was 602) |
| `result_certainty = 'certified'` | 0 |
| Federal races with a loser and no winner | 0 — the anomaly `CC_0351` pinned stays closed |
| The six result-less rows in these races | still NULL |

## What is still open in these two races

⚠ **Every candidate AP names in LA-01 and VA-11 now has a row, but neither race matches our
table**, because we hold six rows AP does not name, all with no result:

- **LA-01 Jim Long** — entered the jungle primary; Wikipedia lists him under "Withdrawn".
- **VA-11 Amy Roma, Bree Fram, Michael Van Meter, Nathan Headrick, Stella Pekarsky** — the
  Democratic primary field for a primary that never happened. Ballotpedia: "The Democratic
  primary scheduled for August 4, 2026, was canceled."

Each needs its own disposition and `CC_0352` has already shown that *withdrew* and *never filed*
look identical in this table and want opposite acts — one is a `candidate_status`, the other is
a deleted row. They belong to the 215 result-less rows `CC_0351` reported, not to this file.

## Still owed by the programme

- 104 of the 106 AP candidates we hold no row for. These two were the last in races already
  opened; the rest is a separate pass.
- `result_recorded_at` is still NULL on the 1,009 rows written by `CC_0339`, `CC_0350` and
  `CC_0351`. This file stamps its own two, as `CC_0352` did. The backfill is owed.
- 59 uncalled races, `certified` upgrades per state, and LA-05's runoff survivors.
