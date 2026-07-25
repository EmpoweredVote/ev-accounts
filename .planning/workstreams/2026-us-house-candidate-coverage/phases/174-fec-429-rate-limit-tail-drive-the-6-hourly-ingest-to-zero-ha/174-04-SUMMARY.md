---
phase: 174-fec-429-rate-limit-tail-drive-the-6-hourly-ingest-to-zero-ha
plan: 04
subsystem: backend
tags: [fec, amendments, correctness, backend-reliability]

requires:
  - phase: 174-fec-429-rate-limit-tail-drive-the-6-hourly-ingest-to-zero-ha
    provides: "incremental min_load_date refresh (174-02) makes amended Schedule A rows arrive routinely on every run, not just during a rare whole-cycle backfill"
provides:
  - "Amended FEC Schedule A rows retire the row they supersede (data_source='fec' AND source_transaction_id = original_sub_id) so itemized totals never double-count"
  - "The dead is_amended==true skip branch removed from shouldSkipRecord (field absent from the live ScheduleA schema)"
  - "original_sub_id retained in raw_record via FEC_KEPT_FIELDS for audit/traceability"
affects: [fec-ingestion, campaign-finance]

tech-stack:
  added: []
  patterns:
    - "NormalizeResult.supersededSubIds is an additive optional field on the shared adapter interface — only the FEC adapter populates it; other adapters (Cal-Access, Indiana, LA Socrata) are unaffected and never need to"
    - "Retirement DELETEs (or soft-delete SETs) triggered by upstream supersession metadata should key ONLY on the OLD identifier the new row explicitly names, never touch the new row's own identifier, and stay parameterized ($1 = ANY(...)) — the same shape reused for any future adapter that needs amendment/supersession handling"

key-files:
  created: []
  modified:
    - backend/src/lib/adapters/adapterInterface.ts
    - backend/src/lib/adapters/fecAdapter.ts
    - backend/src/lib/adapters/fecAdapter.test.ts
    - .planning/workstreams/2026-us-house-candidate-coverage/phases/174-fec-429-rate-limit-tail-drive-the-6-hourly-ingest-to-zero-ha/174-FEC04-LIVE-CONFIRM.md

key-decisions:
  - "Task 1's checkpoint (blocking human-verify, gating the retirement DELETE) was resolved by explicit operator decision: 'proceed' on schema-level evidence (option 2 in 174-FEC04-LIVE-CONFIRM.md) rather than continuing to burn the shared production FEC key. Two independent live-sampling sessions (~1,500 + ~140 rows, including a session specifically targeting the deepest re-amendment chains found via /v1/filings/) never caught a Schedule A row with a populated original_sub_id, and the second session's scan itself hit FEC's own 429 on the shared production key. original_sub_id is confirmed present and typed as a sub_id-linking field on the live ScheduleA OpenAPI schema and documented as orig_sub_id in FEC's own sa warehouse wiki, so the field's existence/purpose is not in doubt — only a live-populated example was never caught."
  - "The retirement DELETE's authorization rests on its bounded blast radius, not just the schema evidence: it can only ever match a row whose source_transaction_id literally equals a value an amended row carries as its own original_sub_id, scoped to data_source='fec', and is guarded by 'only fires when original_sub_id is non-null' — so with the field observed null in every live-sampled row so far, the code ships as a verified no-op today that activates automatically, with no further code change needed, the first time FEC populates the field on a real row."
  - "Hard DELETE, not soft-delete: grepped backend/migrations for a deleted_at column scoped to contributions (none found) and additionally confirmed live via information_schema.columns against the production contributions table (id, donor_id, committee_id, politician_source_id, amount, contribution_date, election_cycle, confidence_level, data_source, source_transaction_id, raw_record, created_at, updated_at, donor_name_normalized — no deleted_at) before choosing the fallback hard-DELETE path the plan specified."
  - "original_sub_id is collected into supersededSubIds for EVERY record in the batch, including ones shouldSkipRecord would otherwise skip (memo_code='X') — not just the records that get inserted — so a superseded row is retired even in the (unlikely, unobserved) case where the amended row replacing it is itself a memo item. The retirement DELETE's own guard (data_source='fec' + exact source_transaction_id match) makes this safe to collect unconditionally."
  - "Removed 'is_amended' from FEC_KEPT_FIELDS (it never appears on live records — the field doesn't exist on the schema — so it was already a silent no-op in slimFecRecord); added 'original_sub_id' in its place."

requirements-completed: [FEC-04]

coverage:
  - id: D1
    description: "shouldSkipRecord still skips memo_code='X' but no longer references the absent is_amended field; a plain amended row (amendment_indicator='A', no is_amended field) is no longer skipped"
    requirement: "FEC-04"
    verification:
      - kind: unit
        ref: "backend/src/lib/adapters/fecAdapter.test.ts#fecAdapter FEC-04 > shouldSkipRecord (via normalize) still skips memo_code=\"X\" but no longer skips a plain amended row lacking the absent is_amended flag"
        status: pass
    human_judgment: false
  - id: D2
    description: "normalizeRecords collects every non-null original_sub_id into NormalizeResult.supersededSubIds while still normalizing and inserting the amended row itself (its own, different, sub_id); omits the field entirely when nothing was superseded"
    requirement: "FEC-04"
    verification:
      - kind: unit
        ref: "backend/src/lib/adapters/fecAdapter.test.ts#fecAdapter FEC-04 > normalizeRecords collects non-null original_sub_id into NormalizeResult.supersededSubIds and still inserts the amended row itself"
        status: pass
      - kind: unit
        ref: "backend/src/lib/adapters/fecAdapter.test.ts#fecAdapter FEC-04 > normalizeRecords omits supersededSubIds entirely when no record carries a non-null original_sub_id"
        status: pass
    human_judgment: false
  - id: D3
    description: "upsertContributions retires superseded rows with a single parameterized DELETE (data_source='fec' AND source_transaction_id = ANY($1)) after inserting the batch, keyed on the OLD sub_id only — never the new amended row's own sub_id; issues no DELETE when nothing was superseded"
    requirement: "FEC-04"
    verification:
      - kind: unit
        ref: "backend/src/lib/adapters/fecAdapter.test.ts#fecAdapter FEC-04 > upsertContributions issues a retirement DELETE parameterized with data_source='fec' and the original_sub_id values, after inserting the batch, and never targets the new amended row"
        status: pass
      - kind: unit
        ref: "backend/src/lib/adapters/fecAdapter.test.ts#fecAdapter FEC-04 > upsertContributions issues no DELETE when supersededSubIds is absent (the common case — most transactions are never amended)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Task 1's live original_sub_id confirmation checkpoint is resolved and recorded — operator explicitly authorized proceeding on schema-level evidence after two live-sampling sessions failed to catch a populated row and one hit FEC's own 429 on the shared production key"
    verification: []
    human_judgment: true
    rationale: "This deliverable is the operator's own authorization decision, not something a test can verify — 174-FEC04-LIVE-CONFIRM.md is committed as the durable record of that decision for future audit, per the plan's own checkpoint gate."

duration: 20min
completed: 2026-07-23
status: complete
---

# Phase 174 Plan 04: FEC-04 — Amendment Supersession Retirement + Dead Skip Removal Summary

**Amended FEC Schedule A rows now retire the exact row they replace (`data_source='fec' AND source_transaction_id = original_sub_id`) via a bounded, parameterized DELETE gated on the operator's schema-level-evidence authorization; the dead `is_amended` skip branch (a field absent from the live ScheduleA schema) is removed.**

## Performance

- **Duration:** ~20 min (continuation of a plan that reached a blocking checkpoint in a prior session; this session covers Task 2 only — the checkpoint's live-sampling work was already done)
- **Completed:** 2026-07-23
- **Tasks:** 2 (Task 1: checkpoint, resolved via operator decision in a prior session; Task 2: implementation, this session)
- **Files modified:** 4 (2 source, 1 test, 1 checkpoint artifact)

## Accomplishments
- `adapterInterface.ts`: `NormalizeResult` gains an optional `supersededSubIds?: string[]` — additive, does not affect Cal-Access/Indiana/LA Socrata adapters.
- `fecAdapter.ts` `shouldSkipRecord`: removed the dead `record['is_amended'] === true` branch (confirmed by `174-RESEARCH-amendments.md` to reference a field absent from the live `ScheduleA` response schema — it never fired); `memo_code === 'X'` skip retained unchanged.
- `fecAdapter.ts` `normalizeRecords`: collects every record's non-null `original_sub_id` (regardless of whether that record itself is skipped) into `supersededSubIds`, returned on `NormalizeResult` only when non-empty. The amended row itself is still normalized and inserted normally under its own (different) `sub_id`.
- `fecAdapter.ts` `upsertContributions`: after the existing batched-insert loop, when `supersededSubIds.length > 0`, issues one parameterized `DELETE FROM transparent_motivations.contributions WHERE data_source = 'fec' AND source_transaction_id = ANY($1::text[])` via a new `retireSupersededRows` helper. Hard DELETE (no `deleted_at` column exists on `contributions` — confirmed both via a `backend/migrations` grep and a live `information_schema.columns` query against the production table). A retirement failure is caught, logged, and counted into `UpsertResult.errors` rather than throwing (matches the existing per-batch error-tolerance pattern in the same function).
- `original_sub_id` added to `FEC_KEPT_FIELDS` (replacing the never-populated `is_amended`) so the amended row's slim `raw_record` retains the linkage for audit/traceability.
- `fecAdapter.test.ts`: 5 new tests in a new `fecAdapter FEC-04` describe block, exercising the skip-check change, `supersededSubIds` collection (populated and omitted-when-empty cases), the retirement DELETE's exact SQL shape/parameterization/post-insert ordering, and the no-DELETE common case.
- `174-FEC04-LIVE-CONFIRM.md` committed: status header updated from "INTERIM/INCONCLUSIVE" to "RESOLVED (option 2 / proceed)", recording the operator's authorization to proceed on schema-level evidence.

## Task Commits

Each task was committed atomically:

1. **Task 1: Live confirmation of original_sub_id supersession linkage** — checkpoint, resolved via operator decision (no code commit; the operator's "proceed" instruction is the resolution, recorded in the artifact committed alongside Task 2 below).
2. **Task 2: FEC-04 — retire superseded rows on original_sub_id + remove dead skip check** - `4eccfcea` (feat)

**Plan metadata:** (this commit, docs: complete plan)

## Files Created/Modified
- `backend/src/lib/adapters/adapterInterface.ts` - `NormalizeResult.supersededSubIds?: string[]` (additive)
- `backend/src/lib/adapters/fecAdapter.ts` - dead `is_amended` skip branch removed; `normalizeRecords` collects `supersededSubIds`; new `retireSupersededRows` helper + call site in `upsertContributions`; `original_sub_id` added to `FEC_KEPT_FIELDS`
- `backend/src/lib/adapters/fecAdapter.test.ts` - new `fecAdapter FEC-04` describe block, 5 tests
- `.planning/workstreams/2026-us-house-candidate-coverage/phases/174-fec-429-rate-limit-tail-drive-the-6-hourly-ingest-to-zero-ha/174-FEC04-LIVE-CONFIRM.md` - status header updated to RESOLVED, committed as the recorded evidence for the operator's decision

## Decisions Made
- Accepted the operator's authorization to proceed on schema-level evidence (option 2) rather than re-attempting the live sampling — re-scanning would burn the shared production FEC key for a field that two independent, ~1,640-row-total sampling sessions never caught populated, and the retirement DELETE's blast radius is independently bounded regardless of whether a populated example is ever caught in a sampling window (it can only ever match `data_source='fec' AND source_transaction_id = original_sub_id`, and only fires when that field is non-null).
- Collected `original_sub_id` for every record in the batch (not just non-skipped ones) — the plan's `<behavior>` spec said "collects every non-null original_sub_id from the batch," which reads as the whole batch, not the insert-eligible subset; this also makes the retirement correct in the theoretical case where an amended row is itself a memo item.
- Kept `upsertContributions`'s existing per-batch error-tolerance pattern for the new retirement step: a DELETE failure is caught/logged/counted into `errors` rather than throwing and aborting the whole upsert, consistent with how transient insert-batch failures are already handled in the same function.
- Removed `is_amended` from `FEC_KEPT_FIELDS` rather than leaving it alongside the new `original_sub_id` entry — it was already inert (the field doesn't exist on live records, so `slimFecRecord`'s `record[k] !== undefined` guard always skipped it) and keeping a known-dead field name in the "fields we read or need" list would be misleading to a future reader.

## Deviations from Plan
None - Task 2 executed exactly as specified in the plan's `<action>`/`<behavior>` blocks. The one substantive judgment call (operator's Task 1 checkpoint resolution) was made explicitly by the operator, not auto-applied by the executor, and is documented above and in `174-FEC04-LIVE-CONFIRM.md` rather than treated as a Rule 1-4 deviation.

## Issues Encountered
None. `npx tsc --noEmit` clean; `npx vitest run src/lib/adapters/fecAdapter.test.ts` 14/14 pass (5 new FEC-04 tests + 9 pre-existing FEC-01/02/03 tests unaffected); the plan's own targeted verification command (`npx vitest run src/lib/adapters/fecAdapter.test.ts -t "supersed|original_sub_id|skip"`) matches and passes the 5 new tests.

## User Setup Required

None - no external service configuration required. The retirement DELETE ships as a verified no-op today (no live row with a populated `original_sub_id` has been observed) and activates automatically, with no further deploy or config step, the first time FEC populates the field on a real amended row.

## Next Phase Readiness
- FEC-04 is now fully implemented: the pre-existing amendment double-count latent bug (an amended row inserted under a new sub_id while the row it superseded stayed live forever) is closed at the code level, gated behind the operator's explicit authorization on schema-level evidence.
- Combined with 174-01 (shared limiter), 174-02 (bulk-first committee resolution + incremental `min_load_date`, FEC-01/FEC-02), and 174-03 (limiter wiring across every real call site + Retry-After backoff + daily cron, FEC-03), Phase 174's full FEC 429-rate-limit-tail redesign (FEC-01 through FEC-04) is now implemented end-to-end.
- Residual monitoring item (not blocking, not part of this plan): if/when a live Schedule A row with a populated `original_sub_id` is ever observed (e.g., during routine future debugging or a future research pass with fresh rate-limit budget), it would be worth a quick spot-check that the retirement DELETE actually fired and removed exactly one row — the current test suite proves the SQL shape/parameterization/ordering with mocks, but has not (and by design of the checkpoint resolution, could not) observe a real populated row end-to-end against production data.
- No blockers for the rest of Phase 174 or for closing out the phase.

---
*Phase: 174-fec-429-rate-limit-tail-drive-the-6-hourly-ingest-to-zero-ha*
*Plan: 04*
*Completed: 2026-07-23*

## Self-Check: PASSED

All 4 modified/created files (`adapterInterface.ts`, `fecAdapter.ts`, `fecAdapter.test.ts`,
`174-FEC04-LIVE-CONFIRM.md`) and this SUMMARY.md confirmed present on disk; Task 2 commit hash
`4eccfcea` confirmed present in `git log`.
