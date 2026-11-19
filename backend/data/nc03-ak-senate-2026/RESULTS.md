# NC-03 and the Alaska Senate — the last two called federal races (CC_0454)

Recorded 2026-11-18. Two seats, seven candidacies, two flips.

A sweep of all 470 federal races against AP's live wire on 2026-11-18 found our 461 recorded
winners agreeing with AP on every one, zero disagreements, and exactly two races AP had called
that we held nothing for. Both had been called *after* the previous results pass. This is those
two. Seven more races remain genuinely uncalled by AP and are waits, not gaps: AK-00, LA-05,
LA-06, MN-01, NC-05, NC-10, TN-04.

| Seat | Winner | Loser(s) | Margin | AP called |
|---|---|---|---|---|
| NC-03 | Raymond Smith Jr. (D) 118,434 | **Gregory F. Murphy (R, incumbent)** 118,176 · Daniel Cavender (L) 3,004 | **258 votes** | 2026-11-17 20:45Z |
| AK Senate | Mary Peltola (D) 144,302 | **Dan S. Sullivan (R, incumbent)** 131,844 · Gerald L. Heikes (R) 6,105 · Daniel J. Sullivan Jr. 4,760 | 12,458 | 2026-11-18 03:19Z |

Both incumbents lost. Nothing here is certified and **nothing here seats anybody.**

## Files

- `ap-calls-2026-11-18.json` — both races from AP's national feed, with `metadata` and
  `progress` already joined, so the winner flag sits beside the name it belongs to.
- `ak-division-of-elections-2026-11-18.json` — Alaska's own return, plus the majority test on
  both denominators.
- `source-extracts-2026-11-18.txt` — the concession, the recount statute and Alaska's
  tabulation notice, quoted at length.
- `tamper-controls.mjs` — the six controls, each watched failing before the file was applied.

## The three things that could have gone wrong

### 1. Alaska is ranked-choice, and the answer hid inside a percentage

A ranked-choice contest ends in round one only if the leader clears 50% of first-choice votes.
Otherwise transfers begin and the first-preference leader can lose. So "Peltola is top" is not
by itself a result, and the usual *the winner is the top vote-getter* gate is not enough.

**This race is the worked example of getting that wrong.** On 2026-11-17 Peltola had 141,637 of
283,377 counting the aggregate write-in line — 49.98%, **52 votes short**. Drop the 874
write-ins and the same ballots read 50.14%, **385 over**. The press reported "50.1%". AP printed
49.98 and held the race at Too Early to Call. One set of ballots, two correct-looking
percentages, two different outcomes.

With the fuller count the ambiguity is gone, which is why the race could be called:

```
144,302 of 287,011  (Alaska's contest total, write-ins excluded)  = 50.2775%   +796
144,302 of 287,896  (AP's total, 885 write-ins included)          = 50.1230%   +353
```

A majority either way, so no transfer can reach it. Alaska's own page says ranked-choice
tabulation starts 2026-11-18 "for required races"; this is not one of them.

▶ **Assertion P9 re-derives both from the vote counts in the file.** It does not read a
percentage, because a percentage is where this race already hid an answer once. Control P9
rewinds the numbers to 2026-11-17 and watches the gate refuse the file.

### 2. Alaska's ballot holds two Sullivans, and `result` cannot tell them apart

```
AP  64262  "Dan Sullivan"     (GOP) 131,844   the sitting senator, and AP's own incumbents[]
AP 177716  "Daniel Sullivan"  (UDC)   4,760   a different man
```

Our rows are `Dan S. Sullivan` (`is_incumbent` true) and `Daniel J. Sullivan Jr.` (false).
Alaska's own return names them exactly as we do — "Sullivan, Dan S. (REP)" and "Sullivan,
Daniel J. Jr." with no party — with matching totals. Three independent sources agree these are
two people.

🔴 **Both lost.** So a swap between them changes neither row's `result`, and no ordinary gate
sees it. It would simply move 131,844 votes and the words *the seat's incumbent* onto a man who
polled 4,760. Assertion P8 exists for that one failure: the row pinned as AP 64262 must be the
row the database flags as incumbent.

⚠ **The first version of control P8 proved nothing.** It swapped the two `race_candidates.id`
values, and P3 — *a pinned id must still name the expected candidate* — caught it first. An
earlier gate shadowing the one under test. Rebuilt to swap only the AP columns, it reaches P8.

### 3. NC-03 is 258 votes, inside North Carolina's recount threshold

N.C.G.S. 163-182.7(c)(1): for a nonstatewide ballot item a candidate may demand a recount where
the margin is not more than 1% of the total cast. 1% of 239,614 is **2,396**. The margin is
**258** — 0.1077%. Murphy was entitled to demand one.

Recorded anyway, and here is exactly what is and is not claimed:

- **Claimed:** AP called it; the NC State Board of Elections return agrees with AP to the vote
  on all three candidates at 190/190 precincts; Murphy **conceded on 2026-11-11**, a week before
  the call; the margin and the threshold.
- **Not claimed:** that no recount was demanded. No primary source was read that says so, and a
  search summary is not one. `result_certainty` is `called`, never `certified`.

▶ If a recount later changes this, the correction is a new migration — not a reason to have
withheld the result. A session once left 35 Senate seats blank for a day reasoning that a media
call is not a state return. **A call and a canvass are two facts; record both, label each.**

⚠ A search summary reported the margin as **293**. Both primary returns say 258. The 293 is a
mid-count number from a different moment, not a disagreement about the outcome.

## Why this file does not seat them

`CC_0340` and `CC_0453` scheduled 461 federal winners into `office_terms` at 2027-01-03. These
two were left out of both because no result existed to seat from. Recording the result is what
unblocks seating; it is not seating.

Seating is kept separate on purpose. Writing a result costs nothing if it moves — the column
says `called` and carries its sources. Writing an `office_terms` row is a claim to voters that a
named person will hold a seat, and `seat_officeholder` closes the predecessor's term as a side
effect. With NC-03 at 258 votes, that is a larger claim than the evidence has settled.

▶ **Seat these two in their own migration, by preference after NC certifies.** Assertion V9
asserts this file seated nobody, and control V9 watches it fire.

⚠ Control V9 also had to be rebuilt. A bare INSERT never reached the gate: both seats carry an
open-ended current term, an open-ended range covers every future date, and
`office_terms_no_overlap` rejected the row first. Closing the sitting term the day before is
what makes the insert legal — and is what a real seating migration does — so the control now
reproduces the mistake it guards against.

## Controls

Each was watched failing before the file was applied. Six gates, six different claims.

| Control | Aimed at | Fired |
|---|---|---|
| P3 | a pinned id that names somebody else | ✅ P3 |
| P7 | winner and loser transposed (the CA-48 mistake) | ✅ P7 |
| P8 | the two Sullivans' AP identities swapped | ✅ P8 *(after rebuild)* |
| P9 | Alaska as it stood on 2026-11-17 — short on one denominator | ✅ P9 |
| V1 | an over-reaching UPDATE outside the seven pins | ✅ V1 |
| V9 | the file accidentally seats the NC-03 winner | ✅ V9 *(after rebuild)* |

## Dated follow-ups

- **2026-11-25** — Alaska's target certification date. Move the four Alaska rows to
  `certified` against the Division of Elections' certified return.
- **North Carolina certification** — then move the three NC-03 rows to `certified`, and
  **re-read the margin**: this is the row most likely to have moved.
- **Seating** — one migration for both seats, at 2027-01-03, once the above is settled.
