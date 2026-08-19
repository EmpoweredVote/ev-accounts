# Austin TX / Travis County deep seed — wave 1 landed, wave 2 open

Created 2026-08-18. Wave 1 applied to prod as migrations **1827** (seats) + **1828** (people/occupancy)
+ **1829** (20 portraits). Roster and sourcing: `backend/data/seed-austin-2026/ROSTERS.md`.
Contact sheet reviewed before import: https://claude.ai/code/artifact/f98aaa45-7aa6-415d-aa30-d3cb6a5f39e2

## Wave 1 — DONE and verified

23 offices, all seated, all address-reachable.

* City of Austin — new `LOCAL` district, `geo_id 4805000`, Mayor + 10 council members.
* Travis County — 12 elected executives onto the pre-existing `48453` district.
* End-to-end probe from an Austin City Hall point (`-97.7472, 30.2653`) returns **26 officials**:
  11 city + 12 county + CD-37 (Doggett) + TX HD-49 (Hinojosa) + TX SD-14 (Eckhardt).
* Negative control passed: `Austin County` (`48015`) does **not** surface. It shares no geo_id with
  the city, but it does share `48015` with TX SD15 and TX HD15.
* `check:migrations` and `check:occupancy` both green.

### Headshots — 20 of 23 imported (migration 1829)

`11/11` city renderable, `9/12` county. The gate is the **upscale factor** `600/crop_width`, not a
pixel floor.

* **13 clean** (0.37x–0.71x): all 11 city portraits from Austin's Widen DAM at ~2000px, plus
  George Morales III (880x1099) and Brigid Shea (1033x1059).
* **7 soft** (1.5x–3.0x), each flagged `REPLACE` in `photo_license` with its source dimensions:
  Delia Garza 1.5x, Ann Howard 1.88x, José Garza 2.5x, Travillion 2.64x, and Andy Brown /
  Velva Price / Dyana Limon-Mercado all at 3.0x. Shipped on the standing call that an upscale beats
  a blank spot. **At 3.0x the pixels are largely invented — these are placeholders that happen to be
  the right person.** Worth re-hunting whenever a better source appears.
* **3 absent** — see the press-sweep item below.

What the contact sheet caught (it has now caught something on every wave):
* A 1080px file on Ann Howard's own precinct page is **not a portrait** — it is a departmental
  graphic reading "When you need help, who should you contact?". It was a candidate purely because
  of its size and location. She fell back to the 400px file, which is why her row is soft.
* 🔴 **The county publishes DEPARTMENT STAFF portraits beside the electeds** — `kate-garza.jpg` sits
  on the County Judge's page, `Grace_Inman_headshot.JPG` elsewhere. Matching a filename containing
  "headshot" would have filed a staffer's face under an officeholder's name.
* 🔴 **A bare `.convert('RGB')` turns transparent PNG corners BLACK.** It put hard black corners on
  the DA's circular-vignette portrait and Brigid Shea's PNG. Flatten alpha onto white first.
* 🔴 **The DA's asset is named `...1727-×-2506-px...` and serves at 300×300**; its `srcset` confirms
  300w is the largest that exists. Filename dimensions are decoration, not a hint.

Still outstanding for wave 1 scope: the **banner** (candidate asset identified —
`Austin City Council - Web_austin-city-hall-council.jpg` on the same Widen DAM) and **stances**
(city seats only, now unblocked since seating is done).

## 🔴 Open: portraits for the 3 remaining officials — press sweep chosen

Sheriff **Sally Hernandez**, Tax Assessor-Collector **Celia Israel**, County Treasurer
**Dolores Ortega Carter**. Each sits on a domain separate from the main county site and none
publishes a portrait of the officeholder — a genuine absence, not a failed fetch. Already checked and
dry: `tcsheriff.org` (home + `/about/office-of-the-sheriff`), `tax-office.traviscountytx.gov`,
`/treasurer` on the main domain. `/sheriff`, `/tax-assessor-collector`, `/county-clerk` and
`/county-treasurer` all **404** on `traviscountytx.gov`.

Next lead, per Chris: **local press** — KUT, Austin Monitor, Community Impact, Austin
American-Statesman. Rationale: the Newton cohort was wrongly written off as dead until `patch.com`
per-person candidate profiles turned up portraits. 🔴 **The credit line is the licence test** —
"Courtesy of <name>" is OK, a photographer credit or "Credit:" is a REFUSE, no credit is UNKNOWN.
Grep the raw HTML near the image FILENAME; a figcaption regex has missed a photographer credit twice.

## ✅ RESOLVED by another session — the `check:reachability` break

While this wave was in flight, `npm run check:reachability` failed with `syntax error at or near "$"`
and verified nothing. Cause: `1dc0562b` interpolated `FALLBACK_EXCLUDED_MTFCC_SQL_LIST` into
`MTFCC_DISTRICT_TYPE_GUARD`, but `scripts/check-address-reachability.mjs` extracts that guard as
**raw source text** (`loadGuard()`) so there is one definition of the mapping — a nested `${...}` is
never expanded and reached Postgres literally.

Fixed by the parallel session in `087eb779`, cherry-picked to master as `bad34f33`
("revert the global G4000 exclusion"). The gate runs again. Keeping the note because the shape
recurs: **a raw-text consumer of a template literal cannot see nested interpolation**, and the
failure mode is a guard that exits non-zero for a reason unrelated to data — indistinguishable from
a real regression.

## 🔴 Open, NOT OURS — reachability gate is RED on master (Indiana judicial geometry)

With the gate working, it now fails on a different regression:

```
BAD_GEOMETRY     observed 7 (baseline 5)
  in JUDICIAL  Indiana Appeals Court Judge - District 1 (Retain Bailey?)  [1800001]
  in JUDICIAL  Indiana Appeals Court Judge - District 2 (Retain Bradford?)  [1800002]
BAD_GEOMETRY  in|JUDICIAL  observed 2 (NEW bucket — this jurisdiction was clean before)
```

**Austin/Travis introduced no regression**: `UNREACHABLE` held exactly at its baseline of 38 and
`DEAD_GEOGRAPHY` improved 20 → 19. This wave created no `JUDICIAL` districts at all. The baseline was
deliberately **not** updated here — doing so would mask someone else's regression behind an unrelated
commit. Whoever seeded those two Indiana retention districts owns it; see also
`.planning/todos/2026-07-30-indiana-address-reachability.md`.

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
