# RE-CHECK SEPTEMBER 2026 — Maine tribal seat term ends are open-ended

Created 2026-08-12 alongside migration 1718 (ADR 0003), which seated Maine's two filled tribal House
seats. **Both terms were written open-ended (`term_end IS NULL`) and reporting says they expire within
weeks of each other this autumn.** That is the exact shape that let TX SD-22 render Brian Birdwell as
a sitting senator for 77 days after he resigned — so this is a scheduled re-check, not a nice-to-have.

| Seat | Holder | `term_start` | precision | Reported term end |
|---|---|---|---|---|
| Passamaquoddy Tribe | Aaron M. Dana (`-232901`) | 2022-01-01 | `year` | **September 2026** |
| Houlton Band of Maliseet Indians | Brian Reynolds (`-232902`) | 2025-05-01 | `month` | **October 2026** |

## Why the dates are as loose as they are

Neither official profile
(`legislature.maine.gov/house/house/MemberProfiles/Details/1507` and `/3140`) carries a term start or
end — they render title, tribe, contact and committees only. So:

- **Dana's sources conflict on the month** he took the seat: Wikipedia says he assumed office
  2022-12-07 (which matches the 131st Legislature convening), the Maine Monitor says October 2022.
  A conflict at month level means month precision is not earned, hence `'year'` with 2022-01-01.
- **Reynolds' sources agree on May 2025** (the Houlton Band reclaimed the seat after seven years
  vacant; contemporaneous coverage is dated 2025-05-14), hence `'month'` with 2025-05-01.
- **`how_started` is `'unknown'` for both.** The tribes' own selection processes differ and we have
  not verified either. Do not fill this in from an assumption that one was "elected" and the other
  "appointed" — some coverage says Reynolds was appointed, but that is secondary.
- **The term ends were NOT written.** They come from a Maine Monitor summary read through WebFetch,
  which returns a paraphrase, and no primary source we found states them. Writing a `term_end` we
  cannot cite would be inventing a date — ADR 0002 forbids it.

## What to do in September 2026

1. **Re-read both official profiles** and the Maine Legislature's tribal-representation history page
   (`legislature.maine.gov/lawlibrary/history-of-tribal-representation-in-maine/9261`) for authoritative
   term dates. If found, close the terms with `essentials.vacate_office` (first VACANT day, not the
   last served day) or `seat_officeholder` for a successor, which closes the predecessor itself.
2. **Run `node scripts/roster-diff.mjs me`.** It should read `lower 153 v 153, flagged 0`. If a tribal
   holder departs and we miss it, this is the detector — but note Open States lagged our corrected TX
   data by weeks, so a disagreement there is a reading queue, not a verdict.
3. **Watch for the Penobscot seat being reclaimed.** It is currently `is_vacant = true` with no term
   rows and no `vacant_since` (the withdrawal was 2015 and we cannot date it precisely). If the Nation
   sends a representative, `seat_officeholder` on office for
   `Non-Voting Tribal Member - Penobscot Nation`, then clear `is_vacant`/`vacant_since` — remember
   **`seat_officeholder` does not clear those flags**, which was the defect in migration 1715.
4. A returning Penobscot representative needs a politician row: the ME tribal band continues at
   **`-232903`** (`-232901` Dana, `-232902` Reynolds; Maine's district-keyed band is `-232001..-232151`).
   Leave `party` NULL — these seats are not filled through a partisan ballot.

## Do not "fix" these by tidying

- `geo_id` **must stay NULL** on all three districts. `check:reachability` fails if one gains
  geometry, deliberately — see ADR 0003 and the `membershipGeometryInvariant()` check.
- `representation_note` must stay populated; the read path is required to refuse to render these seats
  without it.
