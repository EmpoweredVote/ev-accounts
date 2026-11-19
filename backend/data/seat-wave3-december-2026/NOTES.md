# Wave 3 seating — the 72 December 2026 California handovers (`CC_0456`)

Read this before any further December work. The migration header carries the per-seat detail and
the authorities; this file carries the method, what it found, and what is still owed.

## What was written

72 `office_terms` rows, dated in advance at day precision, so `office_current_holder` flips by
itself on each handover day. The Reno pattern (`CC_0385`-`CC_0387`), and the same shape as
`CC_0453`'s 427 federal seats.

| date | seats | authority |
|---|---|---|
| 2026-12-04 | 11 | water / irrigation / CSD — WC 71253, WC 21101, EC 10554, GC 61042 |
| 2026-12-11 | 59 | school and community-college boards — Educ. Code 5017 |
| 2026-12-14 | 2 | City of Los Angeles — Charter § 205(c) |

Of the 72: **40 are re-elections** (the person already holds the seat, so `p_allow_reelection`
is true for those rows and those rows only) and **32 change hands**. 66 close a predecessor's
term at `date - 1`; **6 close nothing, and all 6 are flagged `is_vacant`** — they are genuinely
empty today.

## 🔴 The tracker says 60 and the real number is 72

`office_swearing_in` holds one row per OFFICE, and a race hangs off ONE office. For a
by-trustee-area seat those coincide. For an **at-large board** they do not: the body has N
offices, one race with `seats = N`, and only the race-carrying office ever received a
swearing-in row. So any office-keyed count of this wave undercounts an at-large body by N-1.

Five bodies are in that shape, accounting for all 12 of the gap:

| body | seats | swearing-in rows |
|---|---|---|
| Crescenta Valley Water District | 3 | 1 |
| Culver City Unified | 3 | 1 |
| Mountain View Elementary | 3 | 1 |
| Santa Monica Community College District | 4 | 1 |
| Santa Monica-Malibu Unified | 4 | 1 |

⚠ **Not new, and not something this file introduced.** `CC_0437` already seated **11** offices at
2026-12-11 that carry no swearing-in row, for exactly this reason. The count is wrong, not the
data. ▶ Anything that reports wave 3 by joining through `office_swearing_in` is reporting seats
that have a date row, not seats that are being filled.

## 🔴 At-large seat assignment: 14 map themselves, 3 needed a source

An at-large board has no numbered seats, so our `offices` rows are an internal fiction that has
to be mapped onto real people. 14 of the 17 map themselves — the winner already sits on the
body and keeps their own seat (`CC_0437`'s rule).

Three winners hold nothing. **"Seat the oldest `term_start`" is the wrong rule** — `CC_0437` paid
for that at El Monte City, where an unexpired term carried the same date as two members who were
not up. **The date does not discriminate; the source does.**

| newcomer | takes the seat of | authority |
|---|---|---|
| Carla D. Dillon | Kerry D. Erickson | LA County RR/CC *List of Offices to be Filled, Nov 3 2026* names the three officeholders up: Bodnar, Erickson, Johnson. Bodnar and Johnson were re-elected. |
| Robbie Staenberg | Richard Tahvildaran-Jesswein | `smmusd.org/board-of-education/board-of-education`, read 2026-11-18: exactly four terms end December 2026 — Lieberman, Mignano, Rouse, Tahvildaran-Jesswein. Three won. |
| Kera Blades-Snell | Nancy Greenstein | ⚠ **weakest of the three** — see below. |

🟢 **The SMMUSD roster also settled three seats our own data could never answer.** Kean,
Leon-Vazquez and Lieberman all carry `term_start = NULL` from the phase-2 backfill. The roster
puts Kean and Leon-Vazquez at December **2028**, so no date arithmetic on our side was used or
could have worked.

⚠ **Santa Monica CCD rests on our own cohorts, not on a published list.** `smc.edu/BOT` names all
seven trustees — and our seven holders match it one for one — but publishes no term dates, and
the City of Santa Monica's notice of offices would not load (HTTP failure, plain and in a
browser; the city, not the county, runs both Santa Monica elections, which is why neither body
appears in the RR/CC booklet). The cohorts here are unambiguous: four seats are up; Roy, Peters
and Greenstein hold the only `2022-12-01` terms and Barrera Castañón holds a distinct
`2025-02-04` unexpired term. Rader, Foster and Quiñones-Perez are all `2024-12-01` and continue.
**There is no tie, which is the condition El Monte failed on.** ▶ Confirm against the City's
notice if anyone can reach it.

**P5 turns all three readings into a checked claim**: it names the departing holder and refuses
unless production still shows that person in that seat. **P5b** additionally refuses if any of
the three won anything in 2026 — which would mean the file was moving a re-elected member out of
their own chair.

## 🔴 This file clears no `is_vacant` flag, and that is deliberate

Six of the 72 seats are flagged vacant and hold no term. `seat_officeholder` never touches
`essentials.offices`, so the flag survives, and **V5 asserts repo-wide that not one flag moved in
either direction**.

`CC_0434` cleared `is_vacant` across "every office this migration touched" — a predicate on the
migration's scope, not on what the column means — and `check:reachability` fired a new
`DEAD_GEOGRAPHY ca|SCHOOL 6` bucket within minutes; `CC_0436` put it back. Re-measured for these
six: **every one is the only office in its district, with 0 active holders and 1 vacant office**,
so clearing the flag gives `offices > 0 AND active_holders = 0 AND vacant_offices = 0` — verbatim
the classifier at `backend/scripts/check-address-reachability.mjs:287-289`. That gate is
master-only: it would fail the next person's PR and name an innocent author.

▶ **OWED, AND DATED — clear these six on 2026-12-11**, the day the terms begin. Same act as
`CC_0455` performs for TX-23 and FL-20 on 2027-01-03, same reason: `is_vacant` is a cached
boolean and cannot flip itself.

> Keppel Union TA 1 · Keppel Union TA 2 · Little Lake City TA 5 (vacant since 2026-05-11) ·
> Palmdale TA 3 · Paramount Unified TA 4 · Torrance Unified TA D

⚠ Six **more** flagged offices in the December window have no winner yet and are not in this file:
Altadena Library TA 3, Keppel Union TA 3, Montebello Unified TA 2, Palmdale TA 1, Palmdale TA 5,
Three Valleys MWD Division 3. They are in the same single-office-district shape.

## Controls — five, each at its own gate, each watched failing first

| variant | fault planted | fired |
|---|---|---|
| A | P5's expected departing holder renamed to a sitting member | ✅ **P5** — named the mismatch |
| B | one selected office dropped from the derivation | ✅ **P1** — 71 rows, expected 72 |
| C | `p_allow_reelection` forced true for every row | ✅ **P6** — 32 rows disagree |
| D | `is_vacant` cleared on the seats this file touches | ✅ **V3b** — named all six |
| E | `is_vacant` cleared on one office this file does **not** touch | ✅ **V5** — 66 → 65 repo-wide |

🔴 **B's first draft proved nothing and printed `DRY RUN OK`.** It excluded Altadena Library
TA 3 — an office that carries no winner and so was never in the selection. The edit applied
cleanly and created no fault, which is indistinguishable from a working gate. The exclusion now
names an office checked against production to be in the set.

🔴 **D and E exist because D alone leaves V5 untested.** D's flag clear lands inside the
selection, where the narrower V3b catches it first — a correct refusal at the wrong gate. E
clears a flag on an office this file never touches, so V3b is blind to it by construction and
only V5's repo-wide comparison is left to notice. **An earlier gate hiding the one you meant to
test is how a control proves nothing while printing red.**

C's output is also a free independent measurement: 32 rows disagreeing with "everything is a
re-election" is the number of seats that change hands, derived a different way from the 40.

## Results basis, and the checkpoint before anything begins

All 72 are `result_certainty = 'called'`; **none is `certified`**. The calls were made by the
bound (`CC_0377`'s rule — record only what the trailing candidate could not overtake if every
uncounted ballot broke their way), which a later count cannot reverse.

▶ **LA County certifies 2026-12-01, before all three handover dates.** That is a real checkpoint
between this file and the first term beginning: re-run the fetcher and analyser then, upgrade the
stages, and the 69 seats still without a winner become workable.

## Still open in wave 3 after this

- **69 offices with no winner** — 10 at 12-04, 57 at 12-11, 2 at 12-14. Held on the bound,
  waiting on the 2026-12-01 certification.
- **106 city offices** whose swearing-in date is `estimated` and therefore **not seatable**
  (floor 2026-12-01). They appear as each council posts its December agenda; promote each to
  `published` then.
- **4 cross-county school districts** need Kern, Ventura and Orange County results; **1 seat**
  needs the City of Pasadena.
- **The 96 cancelled elections** — `CC_0379`'s scout established 95 seat their nominee under
  Educ. Code 5328 with nobody appointed. Still one seating migration, not 96 research tasks.
- **The six `is_vacant` flags above**, on 2026-12-11.
