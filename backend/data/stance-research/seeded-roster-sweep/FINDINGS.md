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
