# AZ-02 — resolve Curtis Goodwin after the Arizona primary canvass

**Created:** 2026-07-26 (out of migration 1476)
**Date-gated:** do this on or after **2026-08-06**. Nothing useful can be done before then — see below.
**Priority:** medium. One row, but it is voter-facing and currently carries a disclosure note.

## The one thing to do

Decide whether **Curtis Goodwin (Libertarian)** belongs in the AZ-02 general-election field, then
close out the row: `essentials.race_candidates` id `a48d4bf8-b07d-4ce8-bda5-6bd6b8b5c359`
(politician `7370c0f1-5362-4c7a-b665-452a98f9af84`), race `U.S. Representative District 2`,
election `AZ 2026 Statewide General` (2026-11-03).

- **Confirmed on the ballot** → `provisional_until = NULL`, stamp `last_verified_at`, append the
  verification trail to `source`. (This is exactly what migration 1457 did for its KEEP set of 9,
  including Monica Alponte in AZ-01, who *did* win her Libertarian primary — copy that pattern.)
- **Not on the ballot** → `candidate_status = 'withdrawn'`, stamp `last_verified_at`. Do NOT delete:
  `electionService` already filters `candidate_status != 'withdrawn'`, so this clears him from every
  voter-facing surface while preserving the record that he filed. Again, 1457's CULL set is the
  precedent.
- **Still genuinely uncalled** → re-date again (`2026-08-12`, after the challenge window) rather
  than clearing. Never clear the flag without positive evidence.

**A verdict needs POSITIVE evidence in one direction.** 1457 is emphatic about this and explains
why: Ballotpedia started returning HTTP 202 with an empty body partway through its sweep, and an
absent name is indistinguishable from a throttled fetch. *Do not treat "not found" as a cull.*

## Why 2026-08-06 and not sooner

From the Arizona SoS election calendar (`azsos.gov/elections/calendar-dates`):

| Date | Event |
|------|-------|
| 2026-07-21 | Primary election (AZ-02 Libertarian: Goodwin vs Alex Flores, write-in) |
| 2026-08-03 | County canvass deadline |
| **2026-08-06** | **Official Statewide Canvass of the July 21 2026 Primary Election** |
| 2026-08-11 | Deadline to challenge a primary result in court |

Every Arizona result is **unofficial until the canvass is adopted**, so before 2026-08-06 the
nomination cannot be confirmed no matter how many times the page is checked. That is the whole
reason this is date-gated rather than open work.

## State as of 2026-07-26 (verified, not assumed)

- Ballotpedia AZ-02: *"Curtis Goodwin and Alex Flores ran in the Libertarian primary for U.S. House
  Arizona District 2 on July 21, 2026"* and **"The outcome of this election has not been called
  yet."** The general-election section lists only **Eli Crane** (incumbent, won the R primary
  88,612 / 100.0%) and **Jonathan Nez**, with *"Additional general election candidates will be
  added here following the primary."*
- Wikipedia's AZ-02 section carries Goodwin only under *Independents and third-party candidates →
  Declared*, with no Libertarian primary results box. A July poll had him at 7%.
- Row state after 1476: `provisional_until = 2026-08-06`, `last_verified_at = 2026-07-26`,
  `candidate_status = 'active'`.

## How the flag behaves in the meantime — do not "fix" this

`last_verified_at` (2026-07-26) is **earlier** than `provisional_until` (2026-08-06), so
`last_verified_at < provisional_until` still holds and the row **keeps** its disclosure. Concretely:

- It is **out** of `essentials.stale_provisional_candidates` until 2026-08-06, then returns by
  itself. No cron, no reminder — it is a fact about the row (1456's design).
- The site keeps showing the note on AZ-02, now reading *"Filing or withdrawal deadlines are still
  open. We re-verify this ballot against the official source on or after August 6, 2026"* instead of
  the previous *"past its … re-verification date"*.

Stamping `last_verified_at` only hides a row when the date is in the **past** (that is how 1457's
culled rows left the view). It does not hide this one.

## Related

- Migration 1456 — defined `provisional_until` + the stale view. Read its header first.
- Migration 1457 — re-verified the original 17; documents Goodwin as the deliberate exception.
- Migration 1476 — this re-dating.
- The reader-facing note shipped in ev-accounts `e0e2b936` (`electionService.PROVISIONAL_UNTIL`) and
  essentials `0d7f7649` (`ElectionsView.jsx`).
