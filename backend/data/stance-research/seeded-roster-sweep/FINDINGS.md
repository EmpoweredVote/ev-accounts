# Seeded-roster sweep — is there another fabricated officeholder?

**Date:** 2026-08-06 · **Trigger:** migration 1566, which found that Waltham's Mayor seat held
**Arthur Donahue, a person who does not exist**. Every sweep this workstream had built evaluates
CITATIONS against pages and never SUBJECTS against rosters, so a fabricated person was structurally
invisible. This is the sweep for his peers.

## Result

**No second fabricated officeholder was found in the high-risk set.** One unrelated but real
voter-facing defect was found and fixed: **migration 1571**, below.

## Scale, and why the sweep was targeted rather than exhaustive

There are **4,527 seeded politicians (`external_id < 0`) across 404 governments in 53 states**.
Fetching and diffing 404 official rosters is not proportionate, and two cheap funnels were tested and
rejected before settling on a targeted approach:

* ⚠ **"Profile is empty" fires on 13.5%** — 611 of 4,540 seeded people have no party, photo, bio, urls,
  slug, source or external id, exactly like Donahue. Far too broad to order a queue by. (Same failure
  as the host-row-count proxy that fired on 63% of rows during signal calibration.)
* ⚠ **`chambers.website_url` is NULL for every municipal chamber checked**, so roster URLs cannot be
  resolved from our own data — each one needs a search.

Instead the sweep targeted **the defect's observed shape**. Donahue was a *lone invented name in a
single-occupant seat inside an otherwise-correct roster*: Waltham's 15 councillors were all correct and
only the mayor was wrong. So:

### 1. Every seeded single-occupant seat of the kind that hid him — mayors — DONE, and clean
All **55** negatively-seeded `Mayor` office_terms nationally were enumerated and checked by name.
Donahue is the only unrecognisable one. ⚠ The one other that looked wrong — Brockton's
**Moises M. Rodrigues** — is CORRECT (elected Nov 2025, sworn in 2026-01-05).

### 2. Seat-count anomaly scan across all 661 seeded chambers — DONE
Compared each seeded chamber's occupant count against `chambers.official_count`.

🔑 **The direction of the delta is the whole signal.** Of 20 mismatches, **19 were NEGATIVE** —
partially seeded rosters, which is a *coverage* gap and not a fabrication. **A fabricated extra person
shows a POSITIVE delta**, and there were only two, one of which (`official_count = 0`) is an unset
field. That left exactly one to read, and it was worth reading — see migration 1571.

⚠ **537 of 661 chambers have `official_count` NULL**, so this scan is a partial filter, not a complete
one. It cannot clear the chambers it could not measure.

### 3. Full name-by-name roster verification of the cities where the generator demonstrably operated

957 politicians were touched by stance retirements across all 32 rollback records; resolving those to
governments gives **68 governments containing seeded politicians the generator wrote stances for**.
Most of the large ones are **state legislatures and Congress**, whose rosters come from authoritative
feeds and where a typed-in invented person is not the failure mode. The municipal deep-seeds are.

| City | Seeded | Result |
|---|---|---|
| Waltham MA | 13 | 🔴 **Arthur Donahue fabricated** — fixed by migration 1566 |
| Alhambra CA · Carson CA · Lynn MA · Somerville MA | 5 / 5 / 12 / 12 | ✅ verified name-by-name (re-research clusters) |
| Newton MA | 25 | ✅ previously verified ward by ward (migration 1548 work) |
| Beverly Hills CA | 5 | ✅ roster corrected by migration 1546 (Mirisch out, Pynoos in) |
| Portland OR | 12 | ✅ previously verified (migration 1558 work) |
| **Lowell MA** | 12 | ✅ **all 11 councillors + Mayor Gitschier present** on `lowellma.gov/533/Meet-the-City-Council` |
| **Fall River MA** | 10 | ✅ **all 9 councillors present** on `fallriverma.gov/government/city_council/current_council.php` |
| **Medford MA** | 8 | ✅ **all 7 councillors present** on `medfordma.org/citycouncil` |
| **New Bedford MA** | 12 | ⚠ **corroborated, not directly fetched** — see below |

⚠ **New Bedford is held to a weaker standard and should be said so.** `newbedford-ma.gov` returns
**403 to both `curl -A` and WebFetch** — a bot block, which the checker correctly refused to read as
absence. All 11 councillors were corroborated from two independent routes (the city site as indexed,
and The New Bedford Light's report of Ryan Pereira's election as council president), and every name
matches our roster including ward assignments. That is corroboration, not verification.

## 🔴 What the sweep DID find — migration 1571, applied

**Wisconsin Supreme Court: `official_count` 7, seated 8.** All eight are real justices. The eighth is a
handoff that has already happened and whose flags never moved:

* **Rebecca Grassl Bradley** — term_end **2026-07-31**, `is_incumbent` **true**
* **Chris Taylor** — term_start **2026-08-01**, `is_incumbent` **false**

Taylor won on 2026-04-07 and was sworn in 2026-08-01, succeeding Bradley, who did not seek re-election.
Today is 2026-08-06: the flags are five days stale and contradict the term dates.

🔴 **Voter-facing, not cosmetic.** Occupancy is a two-gate model (`term_end` AND `is_incumbent`). Under
it Bradley is excluded by her date gate — but **Taylor is also excluded, by his flag**. Wisconsin's
newest justice can be invisible while the seat reads empty or still hers, depending which gate a query
applies. Same shape as Beverly Hills / Mirisch.

🔑 **A seat-count check is a cheap detector for two defects it was not designed for** — fabricated extra
people and stale handoffs, both of which surface as a positive delta. Worth running on a schedule.

## What remains unswept, stated plainly

* **~25 municipal governments** in the 68 that the generator touched but which this pass did not reach
  (Sacramento, San Francisco, Berkeley, San Jose, Santa Monica, Whittier, Downey, El Monte, Gardena,
  Lancaster, the Oregon Washington-County cities, Salt Lake City and County, and a tail of 1-2 seeded
  officials each).
* **~336 seeded governments the generator never touched.** Lower prior — a fabricated person is a
  by-product of the stance-writing pass — but not zero, since the seeding pass and the stance pass are
  not the same thing and Donahue was created by the seeder on 2026-06-15.
* **537 chambers with a NULL `official_count`**, which the anomaly scan could not measure.

**Recommended cheap follow-up:** backfill `chambers.official_count` from charter data. It converts the
seat-count scan from a partial filter into a complete one, and it is the only test here that found
anything without a per-city web fetch.

---

# Follow-up 2026-08-06: the `official_count` backfill was the WRONG fix

The recommendation immediately above was to backfill `chambers.official_count`. **Investigating it
showed that would have been actively harmful — and the same investigation found two real defects.**

## Why the backfill was wrong

`essentials.chambers` has 1,073 rows: **538 NULL, 535 populated — but 320 of those are ZERO**, which is
"unset" rather than a real body size. Only **215 carry a real positive count.**

🔴 **Of those 215, 200 (93%) already equal `count(offices)` for the chamber.** `official_count` is
therefore largely a *copy of our own offices table*, not an independent charter fact. Backfilling the
remaining 538 from `offices` would have made the seat-count detector **circular** — delta zero by
construction, detecting nothing, while looking like a strengthened check.

🔑 **A detector is only worth as much as the independence of the two things it compares.** Filling the
gap in a redundant column would have destroyed the detector it was meant to strengthen.

## The better detector, which needs no backfill

What caught Wisconsin was structural — **7 offices, 8 office_terms** — and needs no `official_count` at
all. Filtered to *current* terms that is already clean corpus-wide (0 double-occupied offices), because
Bradley's term genuinely ended.

The signal that remains is the **disagreement between the two occupancy gates**, derivable entirely from
our own data across all **82,352** office_terms:

    -- flagged in, but the term has ended
    p.is_incumbent AND ot.term_end < CURRENT_DATE
    -- flagged out, but the term is current
    NOT p.is_incumbent AND ot.term_start <= CURRENT_DATE
      AND (ot.term_end IS NULL OR ot.term_end >= CURRENT_DATE)

**Result: 0 and 2.** Both of the two are sitting members of Congress. Fixed by **migration 1572**.

## 🔴 Gilbert Cisneros — a sitting U.S. Representative whose stances and seat were on different records

Two rows, inserted in the same batch at the *same microsecond*, by two sources:

| row | source | stances | office | flags |
|---|---|---|---|---|
| `65f08851` | `inform-migration` | **19 answers / 19 context** | none | `is_active` FALSE |
| `d26d3a2f` | `federal_2026_bulk_seed` | 0 | U.S. Representative, from 2025-01-03 | `is_incumbent` FALSE |

Nineteen researched, voter-facing stances hung off a deactivated record holding no office, while the
record holding his seat had none and read as non-incumbent. Verified currently serving against the very
source his office_term cites — `legislators-current.json`: **Gilbert Ray Cisneros, Jr., C001123,
rep CA-31, 2025-01-03 → 2027-01-03.**

⚠ **Scope measured, not assumed:** exactly **one** name in the corpus has this split with stances on one
side and an office on the other. (13,102 names recur across an 85k-person corpus — ordinary, not this.)

**Raul Ruiz** was the second hit and is benign: his real record (`-6000325`) is correct and holds 15
answers; an inactive duplicate held a redundant office_term for the same seat, now removed.

## 🔑 The lesson worth more than either fix

Reconciling our records against `legislators-current` **keyed on `bioguide_id` returns ZERO offenders** —
because **neither Cisneros row nor either Ruiz row has a `bioguide_id`**, while 523 politicians do. The
join silently skipped precisely the rows that were broken.

**A reconciliation keyed on a column that is NULL on the defective rows reports "all clean" and means
nothing. Check the join's coverage before trusting its emptiness.**

## Revised recommendation

Do **not** backfill `official_count` from `offices`. Either source it independently from charter data —
in which case it becomes a genuine cross-check — or drop it from the detector and run the two-gate
incumbency query above, which is complete today, needs no backfill, and found two sitting members of
Congress on its first run.
