# Kitsap County Sheriff — interim appointment lands by 2026-08-29

**Opened** 2026-08-17 · **Re-check after** 2026-08-29 · **Migration that set current state:** 1822

## What we hold now

`essentials.office_terms` for Kitsap County / Sheriff
(`office_id = 2314ba12-903a-4492-addf-9d7f9e4a2b75`):

| holder | term_start | term_end | how_ended |
|---|---|---|---|
| John Gese | 2021-08-01 | **2026-06-25** | resigned |
| Penelope Sapp (`b9fe1fa9-9d4b-4301-8e43-763951034d64`) | **2026-06-26** | open | — |

Sapp is **ACTING**, not appointed. She was Chief of Corrections and took the office automatically on
Gese's departure.

## Why it will change

Gese and four KCSO leaders resigned effective 2026-06-26 ahead of a pension deadline
([Kitsap Daily News, 2026-06-09](https://www.kitsapdailynews.com/2026/06/09/sheriff-gese-4-kcso-leadership-members-resigning-june-26/)).
Because the seat is partisan and was held by a Democrat, the county Democratic central committee
forwarded three names; the Board of Commissioners must appoint an interim sheriff **no later than
2026-08-29**, after background checks. PCO-ranked order was:

1. **Brandon Myers** — *also the Democratic nominee for the seat on 2026-11-03*
2. Jeffrey Menge
3. Ken Dickinson

Interviews were held 2026-07-14, followed by executive session.

## What to do after 2026-08-29

1. Read `https://www.kitsap.gov/sheriff/Pages/Admin-Department.aspx` — it is the page that told us
   Sapp holds it now, and it is kept current.
2. If an interim was appointed, close Sapp's term the day before and `seat_officeholder` the
   appointee with `how_started => 'appointed'`.
3. 🔴 **If the appointee is Brandon Myers, he is simultaneously a `race_candidates` row on the
   2026 general** (`pid 01119ca2-d252-4c9d-8052-57164ace14b8`, already has a headshot from mig 1822).
   Seating him makes him an incumbent — check whether `race_candidates.is_incumbent` should flip
   for that row, and remember party never goes on a candidate (it lives on `races.primary_party`).
4. The general itself resolves the seat on 2026-11-03 (Myers vs. Rick Kuss), so this office needs a
   third pass in November regardless.

## Traps recorded while doing 1822

🔴 **`kitsap.gov/sheriff/Pages/Admin-Department.aspx` has `alt` text shifted by one slot.**
`Chief Penelope Sapp.png` carries `alt="Sheriff John Gese"`; `Chief Jeff Menge.png` carries
`alt="Chief Penelope Sapp"`. Filenames are correct, alt is stale. Matching on alt files the wrong
person's face. Verify by eye.

🔴 **`/sheriff/Pages/KCSO-Who-Am-I.aspx` is a SUSPECT GALLERY**, not a staff bio page — 66 images of
people wanted for shoplifting and burglary. Do not let a portrait harvester near it.

🔴 **A `term_end IS NULL` test for "has this person left office" passes vacuously here.** Kitsap's
county rows all carry real fixed `term_end` dates, so Gese read as having zero open terms *before*
the migration ran. The post-verify in 1822 asserts the positive fact instead (term_end =
2026-06-25 AND how_ended = 'resigned', plus absence from `office_current_holder`).
