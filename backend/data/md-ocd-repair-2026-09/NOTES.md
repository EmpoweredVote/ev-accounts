# Maryland OCD-ID suffix repair — applied 2026-09-16

Migration [`CC_0113_md_ocd_suffix_repair.sql`](../../migrations/CC_0113_md_ocd_suffix_repair.sql).
Lease `state:md` held by chris@empowered.vote on DESKTOP-G6KDNN2.

Closes the item MN-1 opened on 2026-09-12 and carried through MN-2, MN-3 and MN-4.

---

## The defect

`scripts/load-state-tiger-boundaries.ts` derived the OCD-ID suffix with
`parseInt(districtNum, 10)`. **`parseInt('01A', 10)` is `1`**, so the letter was dropped. Maryland's
delegate districts are subdivided `1A`/`1B`/`1C`, and all three became
`ocd-division/country:us/state:md/sldl:1`.

The loader itself was fixed on 2026-09-12 by [`src/lib/ocdDistrictSuffix.ts`](../../src/lib/ocdDistrictSuffix.ts)
(13 tests), **before any Minnesota row was written** — MN's 134 House districts are correct in
production. This migration is the separate repair that doc named: writing Minnesota correctly does
not fix Maryland.

## 🔴🔴 THE SCOPE WAS 84 ROWS IN TWO TABLES, NOT THE 24 ON RECORD

Every note carried the figure **24**. That is `rows − distinct` in **one** table — a count of the
*collapse*, not of the rows carrying it. Measured before applying:

| | rows | distinct `ocd_id` | rows carrying a letter |
| --- | --- | --- | --- |
| `essentials.districts` STATE_LOWER | 71 | 47 | **42** |
| `essentials.geofence_boundaries` G5220 | 71 | 47 | **42** |

🔴 **`geofence_boundaries` was never mentioned in the defect write-up and had exactly the same
damage.** Repairing only `districts` would have left the two tables disagreeing about the same
district, and nothing would have errored. Both are repaired in one transaction, and the post-verify
asserts they agree row for row.

⚠ `staging.politicians.district_ocd_id` holds **0** rows matching `state:md/sldl:`. Checked, not
assumed — it is the only other `ocd_id` column in the database.

## 🔴 What it actually broke, measured

`federalCoverage.ts` → `districtTotalsByState()` computes the state-legislative seat denominator as
`COUNT(DISTINCT ocd_id) FILTER (WHERE ocd_id ~ '/sld[ul]:')`.

**Maryland has 118 legislative district rows and reported 94.** The denominator was 24 short, so
Maryland's state-legislative coverage was displayed against the wrong total. It now reports 118.

⚠ `coverageMapService.ts` → `statsByJurisdiction()` is **not** affected, which is worth stating
because the original defect note named it. Its regexp extracts only `county|place|school_district`
prefixes, so an `sldl` row yields NULL and is skipped. The harm was the denominator.

🟢 `backend/data/coverage/md.yaml` already declared `expected_seats: 71` for the State House and
needed no change. **The YAML was right and the data was wrong.**

## 🟢 `geo_id` was never affected, which is why it is the repair's source

`geo_id` comes from the raw TIGER `GEOID` (`2401A`) and keeps the letter. That is why address
search was always correct — **`ocd_id` ROLLS UP, `geo_id` LOOKS UP** — and why `check:reachability`
could never have caught this. So the new suffix is derived **from `geo_id`**, never from the
damaged `ocd_id`: nothing is reconstructed from a value known to be lossy.

⚠ **Maryland's TIGER district codes are THREE characters**, so a whole delegate district is
`24`+`003` = `24003` and a subdistrict is `24`+`01A` = `2401A`. A control that assumed `2403`
planted on **Maryland's 3rd congressional district** instead (see below).

## ⚠ Massachusetts is deliberately untouched

MA has **200** `sld` rows collapsing to **161**: its Senate districts are *named* ("First Essex"),
not numbered, so 40 rows carry the literal suffix `NaN`. `ocdDistrictSuffix.ts` preserves `NaN` on
purpose rather than re-key 40 live rows as a side effect of someone else's fix.

That is a different defect with its own decision and its own migration. **The post-verify asserts MA
is still 200/161**, so this migration cannot quietly widen.

## Verification

**11 verdicts, every gate watched failing first** — [`control-cc0113-gates.mjs`](./control-cc0113-gates.mjs),
which splits the migration at its post-verify banner and plants between the repair and the gate, so
the gate text being judged is the real one, letter for letter.

Two pre-flight gates (the damage is not 42/42; a corrected id is already held by another row) and
seven post-verify gates (a collapsed row survives; a row goes missing; the two tables disagree; a
malformed suffix; the seat denominator is short; Massachusetts moved; another state drops a letter),
plus the positive half: the unmutated migration passes, and passes again when run twice.

Dry-run against production inside `BEGIN … ROLLBACK`, **and the rollback confirmed reverted** —
71/71 inside the transaction, back to 47 after, `2401A` back to `sldl:1`. Then applied, then re-run:
the pre-flight takes its `already repaired` path and both `UPDATE`s touch 0 rows.

### 🔴 THREE OF THE NINE CONTROLS PLANTED THE WRONG THING, AND THE ROWCOUNT ASSERTION CAUGHT THEM

Each case declares in advance how many rows its mutation must touch. Three disagreed:

- **two planted on rows that do not exist** — `geo_id='2403'` and `'2447'`, because Maryland's codes
  are three characters. `2403` *does* exist: it is the 3rd **congressional** district.
- **one planted a change the gate could not see** — it took the lowest-id Massachusetts row, which
  already held a *unique* `ocd_id`, so swapping one unique value for another left `distinct` at 161
  and the gate passed, correctly. MA's only shared value is `sldu:NaN`; the plant has to come from
  that group.

▶ This is MN-4's lesson holding a third time: **assert the consequence you planted, not the action
you took.**

## National state after the repair

The defect scan — a lettered `geo_id` whose `ocd_id` suffix drops the letter — returns **zero rows
nationally**. Inverted, the same scan finds **mn 134** and **md 42**, so the zero is a real zero and
not a broken query.

## ✅ THE GUARD — added 2026-09-16, in two halves

ND (slice 12) and SD (slice 15) have the same subdistrict shape and are not loaded yet. The loader
is fixed; these assert it **stays** fixed. The workflow's own rule decided the placement: a check
that talks to the database gets its own job, and `static guards` accepts only dependency-free ones.

| | `check:ocd-loader` | `check:ocd-suffixes` |
| --- | --- | --- |
| Reads | the LOADER source | the DATA in production |
| Runs | step in `static guards`, **push + PR** | own job, **schedule only** |
| Catches | the pull request that would cause a bad load | a bad load that already happened |
| Price | free — the job pays its minute anyway | ~30 billed min/month |

Neither replaces the other. The data half gates the **end state**, which is the rule; but it can
only fail *after* a hand-run loader has written to production, so the static half fails on the PR
instead.

🔴 **THE DATA GUARD CARRIES ITS OWN POSITIVE CONTROL.** A read-only check cannot plant a row, so it
measures the **inverse** too — the rows that correctly *keep* a letter (MN 134 + MD 42 = 176 today).
If that count is zero the query has stopped matching and the check **fails saying so**, rather than
reporting a clean sweep. A detector that reports "nothing found" is worthless until it has been
shown finding something.

### 🔴 THE FIRST DRAFT OF THE STATIC GUARD FIRED ON CORRECT CODE

It scanned the whole loader for `parseInt` on a district code and flagged
`const dn = parseInt(districtNum ?? '0', 10);` — which is in the **`cd` branch**, where it is
**right**, because congressional district codes are plain numbers (`01`, `00` = at-large). Only the
`sldu`/`sldl` branch is subject to the letter rule, so the guard is scoped to that branch.
▶ **A guard that fires on correct code is a guard that gets deleted.** There is now a control
asserting it stays quiet on the `cd` branch, alongside the ones that make it fire.

It also reported the wrong line number — 1832 for a call on 1912 — because it *deleted* comments
before matching. Comments are now blanked in place.

### Controls: [`control-ocd-guards.sh`](./control-ocd-guards.sh)

Six, all passing: the real loader passes · the reintroduced `parseInt` is refused · **the `cd`
branch does NOT fire** · a renamed `case 'sldu':` anchor is refused rather than silently finding
nothing · production passes · a planted collapsed row is caught inside a rolled-back transaction.
