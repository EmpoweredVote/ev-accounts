# The three House results AP called after `CC_0351` — `CC_0356`

Applied to production 2026-11-05. Seven candidacies written: 3 won, 4 lost.
Federal 2026 goes **411 → 414 won** and **604 → 608 lost**.

| seat | winner | party | pct | loser(s) | called (UTC) | EEVP |
| --- | --- | --- | --- | --- | --- | --- |
| CA-47 | Dave Min | Dem | 56.90 | Jenny Rae Le Roux (GOP) 43.10 | 01:15:59.925 | 62.30 |
| CA-48 | Marni von Wilpert | Dem | 59.50 | Jim Desmond (GOP) 40.50 | 01:32:45.566 | 53.72 |
| NV-2 | Teresa F. Benitez-Thompson | Dem | 50.26 | David Flippo (GOP) 44.39; Lynn Chapman (IAP) 5.35 | 02:29:25.426 | 92.67 |

AP flags CA-48 and NV-2 as **flipped seats**. Neither had its incumbent on the ballot:
AP's incumbent of record is Darrell Issa (GOP) in CA-48 and Mark Amodei (GOP) in NV-2.
CA-47 is the opposite — Dave Min is the incumbent and held the seat.

`ap-2026-11-05.json` is the joined `metadata.json` + `progress.json` response for these
three races, verbatim, because a live feed is overwritten in place.

## 🔴 The winner is in `progress.json`, not `metadata.json`

`metadata.json` lists candidates in **ballot order** and carries no winner. The winner is
the `winner: "X"` flag on the candidate inside `progress.json`.

**This was got wrong once, off a correct feed.** CA-48's ballot order is Desmond, then
von Wilpert, and reading the first-listed candidate as the winner gets that race exactly
backwards. It was caught by reading the flag before anything was written, and reported to
the operator as a correction.

▶ **The fix is a gate, not a resolution to be careful.** The pre-gate now asserts that the
candidate marked `won` is also AP's **top vote-getter** in that race. `vote_pct` and
`winner` are two independent fields in the feed, so a transposition breaks their agreement
and the migration refuses to run. Without it nothing in the file could catch a swapped
winner: the write reads the file's own table and the post-verify reads the same table, so
a transposed pair agrees with itself.

⚠ **Do not copy that gate unexamined.** It holds here because all three races have a
single round and a majority winner. A plurality or ranked-choice race can be called for
someone who is not top on first preferences.

## It overwrites nothing

All seven rows carried `result IS NULL`. There is no prior value to record, and no
companion column left dating a result that has been replaced — the defect `CC_0354` had
to repair on 155 rows. The `UPDATE` is still guarded on `result IS NULL`, so a re-run
cannot overwrite a later, better value.

`result_recorded_at` is `now()`, **measured** at the write:
`2026-11-05 06:52:52.748835+00` on all seven. It is not derived, unlike the 1,009 rows
`CC_0354` had to date from git commit timestamps.

## A call is not a canvass

`result_certainty` is `called` on all seven. AP reports `isCertified: false` for these
three and for **every** federal race today, and counting is live — CA-48 is at 53.72% of
the expected vote. The `certified` upgrade is a separate pass, per state, once each state
canvasses.

## Controls

Four tampers, each asserted present in the file before running, each one change.
🔴 **Two of them first fired at the WRONG gate and were re-aimed** — a tamper that trips
an earlier check has not tested the check you meant to test.

| | fault planted | gate aimed at | observed |
| --- | --- | --- | --- |
| A | CA-48's winner and loser transposed | top-vote-getter | `the winner is not the top vote-getter: CA-48: Jim Desmond won on 40.50% but Marni von Wilpert polled 59.50%` |
| B | a pinned candidacy filed under CA-47's race | pin exists in its stated race | `only 6 of the 7 pinned rows exist in their stated race` |
| C | five extra rows stamped outside the seven | over-reach, vs the pre-write snapshot | `12 federal row(s) changed, expected exactly 7` |
| D | AP's spelling of a name written in | pin still names the expected person | `a pinned id no longer names the expected candidate: NV-2 Teresa F. Benitez-Thompson <> Teresa Benitez-Thompson` |

- **B was shadowed first.** Pointing a pin at an rc_id already in the file failed on the
  temp table's `PRIMARY KEY` — a real refusal, but a test of the key, not of the race
  join. Changing the `race_id` instead leaves the key unique and reaches the gate.
- **D was shadowed first.** Marking a second winner in NV-2 tripped the top-vote-getter
  check, which runs earlier. A second winner who is *also* the top vote-getter cannot
  exist in one race, so the winner-count pre-gate is **unreachable by tamper** from here;
  it is held by reading, not by a control. Said plainly rather than left looking covered.

## 🔴 A gate of this file's own fired on the first dry run, and the gate was wrong

Post-verify check 6 first read *no race **anywhere** holds a loser and no winner* and
failed with `24 race(s) hold a loser and no winner`. Prod was unchanged; the write was
not the cause. Measured, none of the 24 is in this election:

| election | races | of which hold an `advanced` row |
| --- | --- | --- |
| 2026-05-02 (TX municipal) | 3 | 0 |
| 2026-06-02 (CA primary) | 20 | 10 |
| 2026-08-18 (AK US Senate primary) | 1 | 1 |
| **2026-11-03 (this tier)** | **0** | — |

**The broad version asked a question that is wrong for a primary**: there the winner's row
reads `advanced`, not `won`, so "losers and no winner" is the normal shape, and 11 of the
24 are exactly that. Check 6 is scoped to the 2026-11-03 federal tier, where `won` is the
right marker.

⚠ **The remaining 13 are a real, separate question and this file does not close it**:
losers recorded in an earlier primary with neither a winner nor an advancer beside them,
and 12 of the June 20 cannot be joined to an office at all. They predate this programme.
Someone should look. Widening the gate until it passed would have buried them.

## Verified against production after applying

| check | result |
| --- | --- |
| Federal winners | **414** (was 411) |
| Federal losers | **608** (was 604) |
| Rows changed by this file | exactly 7, every one pinned |
| Federal result rows with no `result_recorded_at` | 0 |
| Federal rows claiming `certified` | 0 |
| Federal races with no winner | **56** — AP's 55 "Too Early to Call" plus LA-05's runoff, with no residue either way |

## Still open

- **55 federal races AP has not called**, plus LA-05, which is a runoff and needs its
  December survivors rather than a winner.
- `certified` upgrades, per state, as each canvasses. Nothing is certified today.
- 104 AP candidates we hold no row for; 215 result-less rows AP cannot classify.
- The 13 pre-existing loser-with-no-winner races above.
