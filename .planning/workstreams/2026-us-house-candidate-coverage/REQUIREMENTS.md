# Requirements — v2.22 2026 US House Candidate Coverage (Wave 3 — National Completion)

**Milestone goal:** Every US resident — in all 435 districts — can enter their address into Elections and see their 2026 US House race: the actual Nov-3 general-ballot field, each candidate with a headshot and chairs-not-polarity, evidence-only federal-24 stances. Completes the multi-milestone House program by covering the final 38 states.

**Scope:** The 38 remaining states (all delegations ≤ 10) = **178 districts**: WA 10 · AZ 9 · TN 9 · MA 9 · IN 9 · MD 8 · MN 8 · MO 8 · WI 8 · CO 8 · AL 7 · SC 7 · LA 6 · KY 6 · OR 6 · CT 5 · OK 5 · AR 4 · IA 4 · KS 4 · MS 4 · NV 4 · UT 4 · NM 3 · NE 3 · WV 2 · ID 2 · HI 2 · ME 2 · NH 2 · RI 2 · MT 2 · AK 1 · DE 1 · ND 1 · SD 1 · VT 1 · WY 1. New work = challengers + open-seat candidates; sitting incumbents already stanced (v2.16/v2.17) and reuse their existing records. With Waves 1 (144) + 2 (113) this closes all 435 districts.

**Method (settled, inherited from v2.20/v2.21):** Surfacing via the elections feed (`essentials.races` + `race_candidates`) — PURE DATA, no backend code (Path B). All 38 states follow the create-races-first pattern (one `elections` row per state + one `races` row per district → existing `NATIONAL_LOWER` office; never `office_id IS NULL`). **Primary-status split (the v2.21 Phase-159 principle):** primary-decided states seed the final general-ballot field; late-primary states (Aug–Sep primaries) seed the full qualified pre-primary field marked `PROVISIONAL:`, then reconcile against official results after each primary (prune losers, confirm nominees) — the proven FL/MI/VA pattern. Stances: federal 24-topic set, chairs-not-polarity, evidence-only, mandatory primary-source verification pass, 0 unsourced, never inferred from party. Two costliest traps — duplicate-incumbent records and lost-incumbent-primary — prevented up front by the field-resolution diagnostic.

---

## v2.22 Requirements

### Field Resolution

- [x] **USHC3-01**: The verified 2026 ballot field is resolved for all 178 districts across the 38 remaining states — every state classified by primary date (decided vs late-primary); decided states get the confirmed Nov-3 general-ballot field (major-party nominees + ballot-qualified independents/third-party) with every incumbent-not-nominee race explicitly flagged; late-primary states get the full qualified pre-primary field from official filing lists; incumbent map + stance-gap baseline built and collision-free negative `external_id` bands verified per state before any insert.

### Candidate Records

- [x] **USHC3-02**: Every Wave-3 candidate has exactly one `essentials.politicians` record — incumbents and previously-seeded figures reuse their existing record (0 duplicate politician rows), only genuinely new candidates get new records; party normalized (Democratic, not Democrat); external_ids follow the verified collision-free per-state scheme.

### Race Wiring (Elections surfacing)

- [x] **USHC3-03**: Every Wave-3 US House race surfaces on `/elections` for an in-district address via `essentials.races` + `essentials.race_candidates` — `elections` + `races` rows authored first per state (none of the 38 states have pre-seeded 2026 House races), then `race_candidates` with non-null `politician_id`, `candidate_status=active`, incumbents flagged `is_incumbent=true`, never `office_id IS NULL`, party never on the candidate card.

### Headshots

- [x] **USHC3-04**: Every newly-seeded Wave-3 candidate has a headshot (find-headshots conventions: Storage-mirrored 600×750 + `politician_images` row + `photo_origin_url`; free-license, wrong-person-guarded, documented honest-skips where none found).

### Stances

- [x] **USHC3-05**: Every newly-seeded Wave-3 candidate has sourced compass stances across the federal 24-topic set — chairs-not-polarity, every answer paired to an `inform.politician_context` row with a real fetched source URL, **0 unsourced**, honest-skip (per-topic or whole-record, gate-pinned with a written search trail) where no documentable evidence, and a mandatory primary-source verification pass before push. Already-stanced incumbents skipped via the stance-gap diagnostic.

### Verification

- [ ] **USHC3-06**: A consolidated read-only gate proves the milestone — coordinate smoke resolves a test address to its district and House race with the expected candidate field on `/elections` for a representative sample of the 38 states; asserts 0 unsourced stance rows, 0 duplicate-incumbent records, and 0 NULL `politician_id`/`office_id` across all 178 districts.

- [ ] **USHC3-07**: Every late-primary state is reconciled against official results after its primary — primary losers pruned (two-path: race_candidates deactivated + orphan check), advancing nominees confirmed, `PROVISIONAL:` flags cleared — date-gated per state primary date; Sep-primary states may carry forward past the main build (FL-153 pattern).

---

## v2.24 Requirements — Backend Reliability (Discovery-Sweep Cost Hardening, Phase 173)

Cron-audit follow-up 2026-07-23 (`.planning/todos/2026-07-23-cron-audit-followups.md` item 1). Pure-backend; no schema, no data.

### Anthropic Preflight

- [x] **OPS-01**: Before the weekly discovery sweep spends any paid Anthropic call, it verifies the `ANTHROPIC_API_KEY` is configured AND the account has usable credit; if either is unavailable it aborts the sweep (does not iterate jurisdictions) and emits exactly one operator alert — eliminating the per-jurisdiction "Anthropic credit balance too low" (144×) and key-not-configured (45×) failure floods.

### Retry-Spend Reduction

- [x] **OPS-02**: The discovery cron's `withRetry` no longer retries non-retryable Anthropic errors (credit-exhausted, insufficient-quota, auth/401/403); retries remain only for genuinely transient network faults — so one failing jurisdiction can no longer multiply the paid-call count 3×.

### Graceful No-Report

- [x] **OPS-03**: A model turn that ends without invoking `report_candidates` is treated as a clean zero-candidate result for that jurisdiction (logged/counted as zero-found, not thrown as a hard failure, not retried) — eliminating the 21× "Claude did not invoke report_candidates" hard-error path for this benign case.

### Cadence Confirmation

- [x] **OPS-04**: The weekly Sunday-02:00 UTC cadence and `SWEEP_HORIZON_DAYS=180` are confirmed intended (or adjusted per operator decision) and documented in code so cost-scaling-with-jurisdiction-count is a deliberate, visible choice.

## v2.24 Requirements — Backend Reliability (FEC 429 Rate-Limit Tail, Phase 174)

> Successor to the `d505c9ad` per-request backoff (verified working: daily FEC failures 3,410→101). Root-cause approach (per `174-RESEARCH.md` + `174-RESEARCH-amendments.md`, live-API verified): the free bulk path (`fecBulkLoader.ts`, `scripts/030-bulk-load-fec.ts`) already carries the 40M+ itemized-contribution volume with no rate limit; the 429s come only from the *separate* 6-hourly API refresh cron re-pulling every source's whole cycle. Cut the request volume at the root — resolve committees from bulk, fetch Schedule A **incrementally** via the live-confirmed `min_load_date` filter, and run **daily** — rather than pacing a wasteful whole-cycle re-pull. Limiter + server-signaled backoff remain as backstops. FEC request sites: `resolveCommitteeIds` (`fecAdapter.ts:87`), `fetchWithRetry` (`fecAdapter.ts:475`), `runFecAutoMatch` (`fecResearch.ts`). Cron `campaignFinanceCron.ts:27`.

### FEC-01 — Committee resolution from free bulk data (no per-source API lookup)

- [x] **FEC-01**: Candidate→committee resolution no longer depends on a per-source FEC **API** call. It is sourced from FEC's free bulk `ccl{YY}.zip` candidate→committee linkage — the same file `fecBulkLoader.ts` already parses into its `cmteToSource` map, no key/rate limit — with the API `resolveCommitteeIds` lookup retained only as a fallback when the bulk linkage is stale or missing a candidate. Eliminates the dominant 429 source (`resolveCommitteeIds`) at the root.

### FEC-02 — Incremental amendment-aware Schedule A fetch (the core volume cut)

- [x] **FEC-02**: The Schedule A refresh fetches only transactions loaded since the last successful run via the live-confirmed `min_load_date` filter on `/schedules/schedule_a/` (persisted per-run cursor that advances each run), replacing the whole-cycle-per-source re-pull. This is amendment-inclusive — an amended filing re-loads with a new `load_date`, and the API serves amendment-resolved (current-version) rows — cutting per-run API volume from tens of thousands to an estimated ~1,000–1,500/day.

### FEC-03 — Daily cadence + shared limiter/backoff backstop

- [x] **FEC-03**: The `fec-ingest` cron cadence changes 6h→**daily** (`load_date` is date-granularity, so 6-hourly yields zero extra freshness). As a safety cap, every outbound FEC API request (all THREE sites: `resolveCommitteeIds` fallback, `fetchWithRetry`, `runFecAutoMatch`) acquires from a single shared rate limiter (Redis token-bucket, degrading to in-process — mirroring the existing FEC lock pattern) budgeted under the ~1,000 req/hr ceiling; on 429 the code honors `Retry-After`/`X-RateLimit-Remaining` when present, keeping exponential backoff as the final fallback.

### FEC-04 — Amendment supersession correctness (no double-count)

- [x] **FEC-04**: When an incremental pull returns a Schedule A transaction with a populated `original_sub_id` (an amendment superseding a prior row), the superseded row is retired so itemized totals do not double-count — the current `ON CONFLICT (source_transaction_id)` dedup does NOT catch this (new `sub_id`), a pre-existing latent gap. The dead `is_amended === true` skip check (references a field absent from the live schema) is removed. A single targeted live query against a high-amendment committee confirms the `original_sub_id` linkage before the retirement logic is finalized.

### FEC-05 — Verified outcome + documented decision

- [ ] **FEC-05**: After deploy, a full **daily** `fec-ingest` cycle completes with **zero** `status='failed'` 429 rows in `ingestion_runs` (verified by read-only query: `status='failed' AND (notes ILIKE '%429%' OR notes ILIKE '%rate limit%')`); and a decision doc records the daily-cadence choice and states that a higher/dedicated api.data.gov FEC key is **NOT required** (the code reaches zero-429 under the current 1,000/hr registered key), so the option isn't silently reconsidered.

---

## Future Requirements (deferred)

- [ ] Challenger FEC finance summaries (`finance_summary`) for newly-seeded candidates — reuse the existing FEC ingestion + name-match queue (→ v2.23+).
- [ ] Viewer-personalized compass alignment / multi-candidate compass overlay on the race display (rendering concern; no schema change).
- [ ] Post-special-election re-seeds for any House vacancies filled after Wave-3 close.

## Out of Scope (v2.22)

- 2026 Senate races — own existing per-race track; not part of this milestone.
- Primary-only / withdrawn / also-ran candidates not qualified for the ballot being seeded.
- The 20 non-federal compass topics (state/local/judicial-only) — federal office scopes to 24 topics by design.
- Backend / frontend code changes — surfacing is pure-data (proven in v2.20/v2.21).
- The v2.21 MI+VA post-primary cull + gate (159-05/06, date-gated ≥ 2026-08-05) and PA independents re-check (≥ 2026-08-10) — v2.21 carry-forwards, executed from the preserved Phase 159 plans.
- FL post-primary re-check (Phase 153, ≥ 2026-08-18) — v2.20 carry-forward.

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| USHC3-01 Field Resolution | Phase 160 | Complete (2026-07-03) |
| USHC3-02 Candidate Records | Phases 161 (anchor), 162, 163, 164, 165 | In progress — 161 anchor complete (2026-07-04): AZ/WA/TN/MA, 183 new records |
| USHC3-03 Race Wiring | Phases 161 (anchor), 162, 163, 164, 165 | In progress — 161 anchor complete (2026-07-04): 37 districts surface (5 severe-TN withheld by design) |
| USHC3-04 Headshots | Phases 161 (anchor), 162, 163, 164, 165 | In progress — 161 anchor complete (2026-07-04): 167 documented honest-skips |
| USHC3-05 Stances | Phases 161 (anchor), 162, 163, 164, 165 | In progress — 161 anchor complete (2026-07-04): 0 unsourced, 59 pinned whole-record skips |
| USHC3-06 Verification Gate | Phase 166 | Pending |
| USHC3-07 Post-Primary Reconciliation | Phase 167 (date-gated, Aug–Sep 2026) | Pending |

100% coverage: all 7 USHC3 requirements mapped to phases 160–167, no orphans.

> **Phase numbering:** v2.22 phases run **160–167** (159 dirs preserved for the v2.21 date-gated tail). **Phases 177/178 are reserved** by a parallel session (Hillsboro/Tigard OR) and must not be assigned.

**Phase grouping (largest-delegation-first, load-balanced):**

| Phase | States | Districts |
|-------|--------|-----------|
| 160 | Field Resolution + Stance-Gap Diagnostic (all 38 states) | 178 (diagnostic only) |
| 161 | WA, AZ, TN, MA | 37 |
| 162 | IN, MD, MN, MO | 33 |
| 163 | WI, CO, AL, SC, LA | 36 |
| 164 | KY, OR, CT, OK, AR, IA, KS, MS | 38 |
| 165 | NV, UT, NM, NE, WV, ID, HI, ME, NH, RI, MT, AK, DE, ND, SD, VT, WY | 34 |
| 166 | Consolidated Verification Gate (all 38 states) | 178 (gate only) |
| 167 | Post-Primary Reconciliation (late-primary states, date-gated) | subset of 178 |
