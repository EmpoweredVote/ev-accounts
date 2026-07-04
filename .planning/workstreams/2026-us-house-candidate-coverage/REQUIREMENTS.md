# Requirements — v2.22 2026 US House Candidate Coverage (Wave 3 — National Completion)

**Milestone goal:** Every US resident — in all 435 districts — can enter their address into Elections and see their 2026 US House race: the actual Nov-3 general-ballot field, each candidate with a headshot and chairs-not-polarity, evidence-only federal-24 stances. Completes the multi-milestone House program by covering the final 38 states.

**Scope:** The 38 remaining states (all delegations ≤ 10) = **178 districts**: WA 10 · AZ 9 · TN 9 · MA 9 · IN 9 · MD 8 · MN 8 · MO 8 · WI 8 · CO 8 · AL 7 · SC 7 · LA 6 · KY 6 · OR 6 · CT 5 · OK 5 · AR 4 · IA 4 · KS 4 · MS 4 · NV 4 · UT 4 · NM 3 · NE 3 · WV 2 · ID 2 · HI 2 · ME 2 · NH 2 · RI 2 · MT 2 · AK 1 · DE 1 · ND 1 · SD 1 · VT 1 · WY 1. New work = challengers + open-seat candidates; sitting incumbents already stanced (v2.16/v2.17) and reuse their existing records. With Waves 1 (144) + 2 (113) this closes all 435 districts.

**Method (settled, inherited from v2.20/v2.21):** Surfacing via the elections feed (`essentials.races` + `race_candidates`) — PURE DATA, no backend code (Path B). All 38 states follow the create-races-first pattern (one `elections` row per state + one `races` row per district → existing `NATIONAL_LOWER` office; never `office_id IS NULL`). **Primary-status split (the v2.21 Phase-159 principle):** primary-decided states seed the final general-ballot field; late-primary states (Aug–Sep primaries) seed the full qualified pre-primary field marked `PROVISIONAL:`, then reconcile against official results after each primary (prune losers, confirm nominees) — the proven FL/MI/VA pattern. Stances: federal 24-topic set, chairs-not-polarity, evidence-only, mandatory primary-source verification pass, 0 unsourced, never inferred from party. Two costliest traps — duplicate-incumbent records and lost-incumbent-primary — prevented up front by the field-resolution diagnostic.

---

## v2.22 Requirements

### Field Resolution

- [ ] **USHC3-01**: The verified 2026 ballot field is resolved for all 178 districts across the 38 remaining states — every state classified by primary date (decided vs late-primary); decided states get the confirmed Nov-3 general-ballot field (major-party nominees + ballot-qualified independents/third-party) with every incumbent-not-nominee race explicitly flagged; late-primary states get the full qualified pre-primary field from official filing lists; incumbent map + stance-gap baseline built and collision-free negative `external_id` bands verified per state before any insert.

### Candidate Records

- [ ] **USHC3-02**: Every Wave-3 candidate has exactly one `essentials.politicians` record — incumbents and previously-seeded figures reuse their existing record (0 duplicate politician rows), only genuinely new candidates get new records; party normalized (Democratic, not Democrat); external_ids follow the verified collision-free per-state scheme.

### Race Wiring (Elections surfacing)

- [ ] **USHC3-03**: Every Wave-3 US House race surfaces on `/elections` for an in-district address via `essentials.races` + `essentials.race_candidates` — `elections` + `races` rows authored first per state (none of the 38 states have pre-seeded 2026 House races), then `race_candidates` with non-null `politician_id`, `candidate_status=active`, incumbents flagged `is_incumbent=true`, never `office_id IS NULL`, party never on the candidate card.

### Headshots

- [ ] **USHC3-04**: Every newly-seeded Wave-3 candidate has a headshot (find-headshots conventions: Storage-mirrored 600×750 + `politician_images` row + `photo_origin_url`; free-license, wrong-person-guarded, documented honest-skips where none found).

### Stances

- [ ] **USHC3-05**: Every newly-seeded Wave-3 candidate has sourced compass stances across the federal 24-topic set — chairs-not-polarity, every answer paired to an `inform.politician_context` row with a real fetched source URL, **0 unsourced**, honest-skip (per-topic or whole-record, gate-pinned with a written search trail) where no documentable evidence, and a mandatory primary-source verification pass before push. Already-stanced incumbents skipped via the stance-gap diagnostic.

### Verification

- [ ] **USHC3-06**: A consolidated read-only gate proves the milestone — coordinate smoke resolves a test address to its district and House race with the expected candidate field on `/elections` for a representative sample of the 38 states; asserts 0 unsourced stance rows, 0 duplicate-incumbent records, and 0 NULL `politician_id`/`office_id` across all 178 districts.

- [ ] **USHC3-07**: Every late-primary state is reconciled against official results after its primary — primary losers pruned (two-path: race_candidates deactivated + orphan check), advancing nominees confirmed, `PROVISIONAL:` flags cleared — date-gated per state primary date; Sep-primary states may carry forward past the main build (FL-153 pattern).

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
| USHC3-01 Field Resolution | Phase 160 | Pending |
| USHC3-02 Candidate Records | Phases 161 (anchor), 162, 163, 164, 165 | Pending |
| USHC3-03 Race Wiring | Phases 161 (anchor), 162, 163, 164, 165 | Pending |
| USHC3-04 Headshots | Phases 161 (anchor), 162, 163, 164, 165 | Pending |
| USHC3-05 Stances | Phases 161 (anchor), 162, 163, 164, 165 | Pending |
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
