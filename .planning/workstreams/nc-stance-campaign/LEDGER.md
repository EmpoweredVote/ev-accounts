# NC Stance Campaign — Batch Ledger

`inform.politician_answers` has no timestamps. This file is the only record of what each batch
wrote. Append one row per batch, in the same task that pushes it. Never backfill from memory.

| Batch | Date | Cohort | People | Rows pushed | Quotes drafted | CSV | written-*.json |
|---|---|---|---|---|---|---|---|

## Pre-campaign baselines (measured 2026-08-24, before any batch was pushed)

Task 6 compares the end state against these. Measure them again at close-out, not the delta.

| Measure | Baseline |
|---|---|
| `inform.politician_answers` rows, all corpora | 32,887 |
| `inform.politician_context` rows, all corpora | 33,541 |
| Context rows with no matching answer (orphan context) | **654** |
| Answer rows for anyone holding an NC seat | 326 |
| Answer rows for the 202 people in this campaign | 0 |

The orphan-context number is the one that must not grow. A context row without an answer is an
unpublished claim: it renders the moment someone writes an answer for that pair.
