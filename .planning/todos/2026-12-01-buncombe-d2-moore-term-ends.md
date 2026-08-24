# Buncombe County District 2 — Martin Moore's commission term ends (Dec 2026)

**Created** 2026-08-23 · **Status** checked; no correction needed now, dated follow-up only.
**Fires** early December 2026, when Buncombe commissioners are sworn in.

## What was flagged, and why it is not a defect

The wave-2b headshot pass noticed that Martin Moore won the **March 2026 Buncombe DA primary**
(BPR, 2026-03-06: "Martin Moore to be Buncombe County's first Black district attorney") while our
data still seats him as Vice Chair and District 2 Commissioner. That looked like a stale-occupancy
risk. It is not.

He **did not resign**. He ran for District Attorney *instead of seeking re-election* to the
commission, so his commission service runs to the natural end of his term. The county's own
elected-officials PDF — the source the wave-2 seed used — states the expiry years directly:

| Seat | Holder | Published expiry |
|---|---|---|
| District 2 | Martin Moore (D) | **(2026)** |
| District 2 | Terri Wells (D) | (2028) |

That is consistent with the recorded NC lesson: **a published term year is EXPIRY**, not an election
year. Wells' 2028 matches her November 2024 re-election; Moore's 2026 matches a term that began
2022-12-01.

So the District 2 seat Moore holds is simply **on the November 2026 ballot**, and occupancy changes
at the December 2026 swearing-in, not before.

## 🔴 Why `term_end` was NOT written from the PDF

`essentials.office_terms` has **`start_precision` but no `end_precision`**. Writing
`term_end = '2026-12-01'` from a published expiry of "(2026)" would assert a day-level fact we do
not have, with no column able to record that it is year-precision. That is exactly the invented date
the honesty rules forbid, and the asymmetry means there is no honest way to record a
year-precision end at all today.

Consequence: every NC officeholder seeded from this PDF carries an **open-ended** term even though
the county publishes an expiry year. Current occupancy is still correct — `office_current_holder`
resolves by date containment — so nothing reads wrong. The published expiry years are simply not
captured.

Two ways to fix that, if it is ever worth fixing:

1. Add `end_precision` to `office_terms`, mirroring `start_precision`, then backfill the expiry
   years from the PDF. This is the honest version and it is a schema change.
2. Leave terms open-ended and rely on a dated todo per body, as here. Cheaper, and it does not
   pretend to precision, but it does not scale past a handful of bodies.

## When this fires

- Confirm the November 2026 winner of Buncombe District 2 (Moore's seat). Also confirm Greg Cheatham
  (District 2, expiry 2028) is unaffected — he sits on a different schedule.
- Close Moore's District 2 term with `essentials.vacate_office` or seat the successor with
  `essentials.seat_officeholder`, which closes the predecessor the day before. Do **not** hand-roll
  the two-step.
- Moore's portrait is already imported and stays valid — he remains a real person in a new office.
  If we track District Attorneys, he needs a DA seat and a term from January 2027.
- Re-check Terri Wells' term row while you are here. It is a single open-ended span from 2020-12-01
  that covers both her 2020 and 2024 terms. Current occupancy is right; the history understates one
  re-election.
