# FEC amendment double-count — verify Phase 174 FEC-04 actually fires (efficacy follow-up)

**Created:** 2026-07-23 (out of Phase 174, workstream 2026-us-house-candidate-coverage)
**Priority:** medium — correctness of itemized FEC totals, not a reliability/outage issue
**Blocks:** nothing; Phase 174 shipped as-is

## Context

Phase 174 FEC-04 added `retireSupersededRows` in `backend/src/lib/adapters/fecAdapter.ts`:
a parameterized `DELETE FROM transparent_motivations.contributions WHERE data_source='fec'
AND source_transaction_id = ANY($1::text[])`, fed only by **non-null** `original_sub_id`
values collected from each incoming Schedule A batch. It is safe and inert.

**The catch:** across TWO independent live-sampling sessions (~1,500 rows in the RESEARCH
phase + ~140 rows during 174-04, targeting the deepest re-amended F3X committees), **every**
`amendment_indicator:"A"` row came back with `original_sub_id: null`. The field exists in
FEC's live OpenAPI ScheduleA schema and is documented as `orig_sub_id` in FEC's internal `sa`
warehouse wiki, but is not observed populated on the public API. The free bulk `indiv{YY}.zip`
(21 cols) does not carry it either. Operator authorized proceeding on schema-level evidence
(option 2, recorded in `174-FEC04-LIVE-CONFIRM.md`).

## The open question

If `original_sub_id` is reliably null on the public API, then `retireSupersededRows` never
fires — so FEC-04 does NOT actually resolve the amendment **double-count** it was written to
fix: an amended filing reloads its Schedule A lines with a NEW `sub_id` + fresh `load_date`,
the `ON CONFLICT (source_transaction_id)` dedup misses it (new key), and the superseded row
persists → itemized totals double-count.

## What to check

1. After Phase 174 deploys and a few daily cycles run, query prod (`kxsdzaojfaibhuzmclfq`) for
   evidence of double-counted amended rows — e.g. multiple `contributions` rows for the same
   FEC filing/transaction identity (`image_number` + line) under `data_source='fec'` that
   should represent a single amended transaction.
2. If double-counting is present, design a dedup key that does NOT depend on `original_sub_id`
   — candidate: dedup/supersede by (`image_number`, transaction line identity) or by the
   amendment chain (`prior_sub_id`/`amendment_indicator` + committee/report linkage), so the
   old version is retired when a newer `load_date` version of the same logical line arrives.
3. Separately, re-check whether FEC ever populates `original_sub_id` (schema drift) — if it
   starts appearing, the existing `retireSupersededRows` will begin working as designed and
   this may become moot.

## Pointers

- `backend/src/lib/adapters/fecAdapter.ts` — `retireSupersededRows`, `normalizeRecords`, `FEC_KEPT_FIELDS`
- `.planning/workstreams/2026-us-house-candidate-coverage/phases/174-*/174-FEC04-LIVE-CONFIRM.md` — full sampling evidence
- `.planning/workstreams/2026-us-house-candidate-coverage/phases/174-*/174-RESEARCH-amendments.md` — original amendment research
