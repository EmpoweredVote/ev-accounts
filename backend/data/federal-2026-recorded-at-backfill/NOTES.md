# Backfilling `result_recorded_at` on the 1,009 federal 2026 result rows — `CC_0354`

Worked record for `backend/migrations/CC_0354_federal_2026_backfill_result_recorded_at.sql`,
applied to production 2026-11-05.

`CC_0350`, `CC_0351`, `CC_0352` and `CC_0353` each reported the same debt. This pays it.

## It was two defects, and the smaller one was worse

| | rows | what was wrong |
|---|---|---|
| Missing | **854** | `result_recorded_at` was NULL. The outcome is recorded; when we recorded it is not. |
| **Stale** | **155** | `result_recorded_at` was set **and wrong** — it dated the ballot-qualification record that the AP call overwrote (2026-08-20 to 2026-09-24), against a result that did not exist until 2026-11-04. |

854 + 155 = 1,009, the figure the four earlier passes reported.

🔴 **A NULL says "unknown". A stale value makes a false statement.** The column's own comment
reads *"When the outcome was written"*; for those 155 it named the write of an outcome that is
no longer in the row. Both are fixed; the 155 old values are in
`overwritten-2026-11-05.json` and in the migration header, because there is no history table.

## The true write instant is unrecoverable, so the value is derived and says so

Three places could have held the real moment. All three were checked and all three are empty:

1. **`race_candidates.updated_at` exists, and cannot date a result.** No trigger maintains it —
   the table's only trigger is `race_candidate_mirror_data` — so it moves only when a writer
   sets it by hand, and the three result migrations never did. **Proven, not assumed:** Chuck
   Edwards' row was updated by `CC_0352` on 2026-11-04 and its `updated_at` still reads
   `2026-07-01T04:12:58.150Z`, its insert default.
   ⚠ **It is not uniformly stale, which makes it worse than useless:** 1,060 of the table's
   5,175 rows *do* carry an `updated_at` later than `created_at`, written by other code paths.
   The column looks maintained, answers plausibly for a fifth of the table, and is silent about
   every result this programme wrote.
2. **Postgres commit timestamps** — `track_commit_timestamp` is `off`, so
   `pg_xact_commit_timestamp(xmin)` holds nothing. Worth turning on for next time; it is a
   server setting plus a restart and only helps from that point forward.
3. **A server log** — `apply-migration-file.mjs` writes to stdout only, there is no apply table
   by design (`CC_0070`'s table comment explains why), and the management API log endpoint this
   repo's tooling uses has been withdrawn. Ordinary DML would not be logged in any case.

So each row gets **the git commit timestamp of the migration that wrote its result**:

| migration | rows | commit | committed (UTC) | wrote |
|---|---|---|---|---|
| `CC_0339` | 33 | `3d4088708` | 2026-11-05T00:02:22Z | the Senate winners |
| `CC_0350` | 377 | `f7702c4fc` | 2026-11-05T00:41:54Z | the House winners |
| `CC_0351` | 599 | `21c54a4e9` | 2026-11-05T01:12:43Z | the losers, both chambers |

⚠ **This is an upper bound and it is slightly late.** The workflow is apply-to-production, then
commit, so each write happened a few minutes *before* the timestamp it now carries. The error is
minutes, in a known direction. It is not a measurement. `CC_0339` uses the **earliest** commit of
its file, not the squash-merge (#1317, 16:11:50-08:00), because the earliest commit is nearest
the apply.

🟢 **The three derived values cross-check against two measured ones.** `CC_0352` and `CC_0353`
stamped their own rows with `now()` at apply. All five are strictly increasing in the order the
passes ran, and the derived three all fall before the first measured one — a gate asserts it:

```
00:02:22 (CC_0339) < 00:41:54 (CC_0350) < 01:12:43 (CC_0351)
         < 01:59:21.737696 (CC_0352, measured) < 05:07:55.375038 (CC_0353, measured)
```

🟢 **A derived value is visible as one:** its sub-second part is zero, where a measured `now()`
carries microseconds. A convenience for readers, not a contract.

## The attribution is measured, not assumed

Which migration wrote a row is derived from the row: AP-sourced (its `result_source` carries
`interactives.apelections.org`), then Senate+`won` → `CC_0339`, House+`won` → `CC_0350`,
`lost` → `CC_0351`, with the six rows `CC_0352`/`CC_0353` already stamped excluded by id.

That split lands on **33 / 377 / 599** — what the three migrations said they wrote — and the 155
stale rows split **51 `won` / 104 `lost`**, which is exactly the count of prior citations
`CC_0350` (51) and `CC_0351` (104) each reported overwriting, arrived at from the opposite
direction. Two independent descriptions of the same set agreeing is the evidence.

## Controls

Four tampers, each asserted present before it ran, each aimed at a different gate. All four
fired where aimed.

| Control | Fault planted | Gate aimed at | Observed |
|---|---|---|---|
| A | two derived timestamps transposed | migration-order | `the three derived timestamps are not in migration order` |
| B | the six-id exclusion dropped | attribution pre-gate | `1015 rows attributed, expected 1009` |
| C | a derived timestamp moved to October | nothing recorded before election day | `33 AP-called row(s) claim to have been recorded before election day` |
| D | five extra rows stamped with `now()` | over-reach, against the pre-write snapshot | `1014 federal row(s) changed, expected exactly 1009` |

🟢 **A fifth fault was caught by a gate before any tamper existed:** the first dry run failed
with `294 of the 293 pre-existing result rows are unchanged`. The header had said 293; the real
figure is 294, because Chuck Edwards' row was written by `CC_0352` but is not AP-sourced, so it
sits outside the predicate — correctly, since his timestamp is already measured.

⚠ **A timestamp read through the `pg` driver is truncated to milliseconds.** The two measured
values are stored to microseconds (`.737696`, `.375038`); the driver returns a JS `Date` and the
first draft of the gates pinned `.737`/`.375`. The dry run failed with `0 of the 4 CC_0352 rows
keep their measured timestamp` — a real equality failure that reads like a data problem. Read
such a value with `to_char(..., 'YYYY-MM-DD HH24:MI:SS.US')`.

## Verified against production after applying

```
2026-11-05 00:02:22.000000   33   (CC_0339, derived)
2026-11-05 00:41:54.000000  377   (CC_0350, derived)
2026-11-05 01:12:43.000000  599   (CC_0351, derived)
2026-11-05 01:59:21.737696    4   (CC_0352, measured)
2026-11-05 05:07:55.375038    2   (CC_0353, measured)
```

| Check | Result |
|---|---|
| Federal result rows with no `result_recorded_at` | **0** |
| Rows changed by this file | exactly 1,009, all in the attributed set |
| Non-AP-sourced federal result rows | 294, all unchanged |
| The six measured rows | unchanged, pinned by id to the microsecond |
| Federal winners | 411 — unchanged; no result, certainty or citation was touched |

## The column comment now carries the warning

`ev_api` cannot `COMMENT ON` a table it does not own (*"must be owner of relation
race_candidates"*), so the migration could not carry it. It was applied separately through the
privileged connection and read back:

> When the outcome was written. Distinct from last_verified_at, which tracks candidacy
> re-verification. WARNING: 1,009 federal 2026-11-03 rows carry a DERIVED value, not a measured
> one — CC_0354 backfilled them with the git commit timestamp of the migration that wrote each
> result (CC_0339/CC_0350/CC_0351), because the true instant is unrecoverable: updated_at is not
> maintained on this table and track_commit_timestamp is off. Those values are a few minutes
> LATE and have a zero sub-second part. See CC_0354 and
> backend/data/federal-2026-recorded-at-backfill/.

## Files

| File | What it is |
|---|---|
| `overwritten-2026-11-05.json` | the 155 rows whose `result_recorded_at` this file replaced, with the old value, the seat, the name and the result. The same list is in the migration header. |

## Owed next

- **Turn on `track_commit_timestamp`** so the next pass can measure instead of derive.
- 104 AP candidates we hold no row for; 215 result-less rows AP cannot classify; 59 uncalled
  races; `certified` upgrades per state; LA-05's runoff survivors.
