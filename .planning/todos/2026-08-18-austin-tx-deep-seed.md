# Austin TX / Travis County deep seed — wave 1 landed, wave 2 open

Created 2026-08-18. Wave 1 applied to prod as migrations **1827** (seats) + **1828** (people/occupancy).
Roster and sourcing: `backend/data/seed-austin-2026/ROSTERS.md`.

## Wave 1 — DONE and verified

23 offices, all seated, all address-reachable.

* City of Austin — new `LOCAL` district, `geo_id 4805000`, Mayor + 10 council members.
* Travis County — 12 elected executives onto the pre-existing `48453` district.
* End-to-end probe from an Austin City Hall point (`-97.7472, 30.2653`) returns **26 officials**:
  11 city + 12 county + CD-37 (Doggett) + TX HD-49 (Hinojosa) + TX SD-14 (Eckhardt).
* Negative control passed: `Austin County` (`48015`) does **not** surface. It shares no geo_id with
  the city, but it does share `48015` with TX SD15 and TX HD15.
* `check:migrations` and `check:occupancy` both green.

Still outstanding for wave 1 scope: **headshots** (11 city portraits located on the Widen DAM, county
portraits mostly not yet located) and the **banner** (candidate asset identified). Stances were
scoped to city seats only, after seating — seating is now done, so that work is unblocked.

## 🔴 BLOCKER FOUND, NOT MINE, NOT FIXED — `check:reachability` is broken on `feat/zip-code-search`

`npm run check:reachability` fails with `syntax error at or near "$"` and **verifies nothing**.

Cause: commit `1dc0562b` ("fix(geo): exclude G6350 from the district-join catch-all") added
`FALLBACK_EXCLUDED_MTFCC_SQL_LIST` and interpolated it into the `MTFCC_DISTRICT_TYPE_GUARD`
template literal in `src/lib/geoIdGuard.ts:84`. But `scripts/check-address-reachability.mjs`
extracts that guard as **raw source text** with a regex (`loadGuard()`), deliberately, so there is
one definition of the mapping. A nested `${...}` is never expanded by that path, so the literal
string `${FALLBACK_EXCLUDED_MTFCC_SQL_LIST}` reaches Postgres.

Scope:
* `origin/master` does **not** contain the constant — the gate still works there, including the
  daily cron.
* `1dc0562b` exists only on `feat/zip-code-search` (and its pushed remote), so the break lands on
  master the moment that branch merges.

This is the "a broken positive guard is worse than none" failure mode: the gate exits non-zero for a
reason unrelated to data, so a real unreachable district would be indistinguishable from this.

Two candidate fixes, for whoever owns that branch:
1. Make `loadGuard()` resolve the nested constant (extract `FALLBACK_EXCLUDED_MTFCCS` too and
   substitute), or
2. Stop interpolating: inline the list in the guard and have `geoIdGuard.test.ts` assert the inline
   list equals `FALLBACK_EXCLUDED_MTFCCS`, keeping the single-source-of-truth property without a
   template placeholder that raw-text consumers cannot see.

Austin/Travis reachability was verified by running the classify query with the constant expanded by
hand — G4110→LOCAL and G4020→COUNTY are both admitted by the guard. That is a manual substitute for
the gate, not a replacement for fixing it.

## Wave 2 — deferred, with reasons

| Item | Size | Note |
|---|---|---|
| Travis County judiciary | ~30 seats | Civil district courts (12), criminal district courts (9), county courts at law (9 per votetravis / "criminal court-at-law #3-#9" per the org chart — **the two sources name these differently, reconcile before seeding**), 2 probate courts, 2 civil courts-at-law |
| Justices of the Peace | 5 | Judicial. Pct 1 Yvonne M. Williams, 2 Randall Slagle, 3 Sylvia Holmes, 4 Raúl Arturo González, 5 Tanisa Jeffers |
| **Constables** | 5 | ⚠ **Arguably belonged in wave 1** — elected, non-judicial law enforcement. Left out only because the approved scope said "elected executives" and enumerated 12 seats. Pct 1 Tonya Nixon, 2 Adan Ballesteros, 3 Stacy Suits, 4 Gabriel Padilla, 5 Carlos Lopez. Cheapest remaining win. |
| Austin ISD | 9 trustees | 7 single-member + 2 at-large. **Needs a TIGER unified-school-district polygon loaded** — only 5 `G5420` geofences exist in all of Texas, all Collin County ISDs. AISD has none. |

## 🔴 Recheck January 2027 — hard date

* **George Morales III (Commissioner Pct 4)** holds the seat by **appointment** (2026-06-11), running
  only to the end of Margaret Gómez's term. He is unopposed in the 2026-11-03 general. A fresh
  **elected** term begins 2027-01-01, which needs a new `office_terms` row via `seat_officeholder`
  (the helper closes the appointed term the day before).
* **Five city seats' terms end January 2027** — D1 Harper-Madison, D3 Velásquez, D5 Alter,
  D8 Ellis, D9 Qadri. All five are on the November 2026 ballot.
* Term ends were **deliberately not written** to `office_terms`; all 23 rows are open-ended, which is
  the documented lifecycle. So nothing self-corrects — these seats will show stale holders after
  January 2027 unless this recheck happens. That tradeoff was chosen over writing future `term_end`
  values, which would make 23 seats silently self-vacate instead.
* Brigid Shea (Pct 2) already won the 2026 primary and faces no Republican, so her next term is
  effectively secured — but it is still a new term starting 2027-01-01.

## Data-quality debt observed elsewhere (separate cleanup, not this wave)

* **30+ `Tarrant County` `office_terms` rows carry `start_precision='day'` with `term_start IS NULL`.**
  Incoherent: `'day'` asserts a known day. The Fort Worth rows in the same seed correctly pair a NULL
  start with `start_precision='unknown'`. Austin/Travis writes real dates for all 23 and does not
  reproduce this.
* **Tarrant County has no Sheriff, County Attorney, Tax Assessor-Collector, Treasurer or Constable
  offices** despite 30 seeded judicial seats — its elected-executive tier is materially less complete
  than Travis's now is. Worth a Tarrant follow-up wave.

## Source cautions worth carrying forward

* 🔴 **Ballotpedia was stale on Travis Precinct 4** — still lists Margaret Gómez (assumed 1995) after
  her 2026-06-11 retirement. Detector, not oracle. The county's own org chart and the County Clerk's
  office-holder list both had Morales.
* 🔴 **austintexas.gov council-page `alt` text is unusable** — no `alt` at all for D4 and D10, and
  diacritics stripped elsewhere ("Jose Velasquez"). Read the `member-name` anchor text, which is keyed
  to each district's `href`. Same class as the Kitsap alt-off-by-one.
* ⚠ **`votetravis.gov` is JS-rendered** — `curl` returns HTTP 200 with **0 bytes**. Render it. Not a WAF.
* ⚠ `chambers.slug` is a **generated** column derived from `name_formal`, not `name`, and cannot be
  inserted. Getting `name_formal` wrong silently produces a different slug.
