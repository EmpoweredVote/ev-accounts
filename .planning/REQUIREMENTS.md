# Requirements — v2.21 2026 US House Candidate Coverage (Wave 2)

**Milestone goal:** Every resident of the next 8 largest-delegation states can enter their address into Elections and see their 2026 US House race — the actual Nov-3 general-ballot field — each candidate with a headshot and chairs-not-polarity, evidence-only federal-24 stances. Reuses the fully-proven v2.20 elections-feed pipeline.

**Scope:** The next 8 House delegations by size (all ≥ 11 seats) — **PA (17), IL (17), OH (15), GA (14), NC (14), MI (13), NJ (12), VA (11) = 113 districts**. Nov-3 general-ballot field (major-party nominees + ballot-qualified independents/third-party). New work = challengers + open-seat candidates; sitting incumbents already stanced (v2.16/v2.17) and reuse their existing records. Wave 2 of a multi-milestone program; remaining ~178 districts (38 smaller-delegation states) → Wave 3+.

**Method (settled, inherited from v2.20):** Surfacing via the elections feed (`essentials.races` + `race_candidates`) — PURE DATA, no backend code (Path B; surfacing path proven in v2.20). Per-state seed split: author `elections` + `races` rows first where none pre-exist, then `race_candidates` with non-null `politician_id`. Stances: federal 24-topic set, chairs-not-polarity, evidence-only, mandatory primary-source verification pass, 0 unsourced. Never infer from party. Two costliest traps — duplicate-incumbent records and lost-incumbent-primary — prevented up front by the Phase-154-style field-resolution diagnostic (verify nominee per district from results, never from incumbency).

---

## v2.21 Requirements

### Field Resolution

- [x] **USHC2-01**: The verified Nov-3 general-ballot field is identified for all 113 Wave-2 districts (PA/IL/OH/GA/NC/MI/NJ/VA) — major-party nominees + ballot-qualified independents/third-party — with each race where the incumbent is NOT the 2026 nominee (lost-primary / retirement / redistricting / vacancy / deceased) explicitly flagged via the nominee-status taxonomy, and the per-state challenger/open-seat stance gap diagnosed against existing incumbent records.

### Candidate Records

- [ ] **USHC2-02**: Every Wave-2 candidate has exactly one `essentials.politicians` record — incumbents and previously-seeded figures reuse their existing record (no duplicate politician rows), only genuinely new candidates get new records; party normalized (Democratic, not Democrat); collision-free negative `external_id` scheme verified against live IDs per state before any insert.

### Race Wiring (Elections surfacing)

- [ ] **USHC2-03**: Every Wave-2 US House race surfaces on `/elections` for an in-district address via `essentials.races` + `essentials.race_candidates` — `elections` + `races` rows authored first for any state lacking pre-seeded 2026 House races, then `race_candidates` — with `race_candidates.politician_id` linked for every candidate (non-null, `candidate_status=active`, never `office_id IS NULL` on a House race) so stances and headshots resolve.

### Headshots

- [ ] **USHC2-04**: Every newly-seeded Wave-2 candidate has a headshot (find-headshots conventions: Storage-mirrored 600×750 + `politician_images` row + `photo_origin_url`; free-license, wrong-person-guarded, documented honest-skips where none found).

### Stances

- [ ] **USHC2-05**: Every Wave-2 candidate lacking them has sourced compass stances across the federal 24-topic set — chairs-not-polarity, every answer paired to an `inform.politician_context` row with a real fetched source URL, **0 unsourced**, honest-skip (per-topic or whole-record) where no documentable evidence, and a mandatory primary-source verification pass before push (no party inference, no agent over-read). Already-stanced incumbents skipped via the stance-gap diagnostic.

### Verification

- [ ] **USHC2-06**: A consolidated read-only gate proves the milestone — for each of the 8 Wave-2 states a test address resolves to its district and the House race displays the expected candidate field on `/elections`; asserts 0 unsourced stance rows and 0 duplicate-incumbent politician records across the 113 districts.

---

## Future Requirements (deferred to Wave 3+)

- [ ] Remaining ~178 US House districts (the 38 smaller-delegation states beyond the top-12), in largest-delegation-first waves.
- [ ] Challenger FEC finance summaries (`finance_summary`) for newly-seeded candidates — reuse the existing FEC ingestion + name-match queue.
- [ ] Viewer-personalized compass alignment / multi-candidate compass overlay on the race display (rendering concern; no schema change).

## Out of Scope (v2.21)

- The remaining ~178 districts in the 38 smaller-delegation states — deferred to later waves.
- 2026 Senate races — own existing per-race track; not part of this milestone.
- Primary-only / withdrawn / also-ran candidates not on the Nov-3 general ballot.
- The 20 non-federal compass topics (state/local/judicial-only) — federal office scopes to 24 topics by design.
- Backend / frontend code changes — surfacing is pure-data (proven in v2.20); the `/elections` "race not covered" empty state lives in the separate Essentials frontend repo.
- FL post-primary re-check (Phase 153) — separate date-gated carry-forward (≥ 2026-08-18) from v2.20, not part of Wave 2.

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| USHC2-01 Field Resolution | Phase 154 | Pending |
| USHC2-02 Candidate Records | Phase 155 (anchor), 156, 157, 159 (MI) | Pending |
| USHC2-03 Race Wiring | Phase 155 (anchor), 156, 157, 159 (MI) | Pending |
| USHC2-04 Headshots | Phase 155 (anchor), 156, 157, 159 (MI) | Pending |
| USHC2-05 Stances | Phase 155 (anchor), 156, 157, 159 (MI) | Pending |
| USHC2-06 Verification Gate | Phase 158 (100 decided districts), 159 (MI) | Pending |

> **MI is date-gated (D-01):** MI's congressional primary is Aug 4, 2026. Phase 154 resolves MI only to declared-field + incumbent-map; MI nominee seeding + verification is the date-gated Phase 159 (≥ 2026-08-04). Phases 155/156/157 + the Phase 158 gate cover the 100 decided-state districts; Phase 159 completes the milestone to 113.
