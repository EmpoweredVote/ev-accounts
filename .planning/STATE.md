---
gsd_state_version: 1.0
milestone: v2.21
milestone_name: 2026 US House Candidate Coverage
status: executing
last_updated: "2026-07-02T00:00:00.000Z"
last_activity: 2026-07-02 -- Phase 159 Wave 2 complete (159-02 MI + 159-04 VA stances/headshots); Waves 3-4 date-gated
stopped_at: "Phase 159 Waves 1-2 COMPLETE (159-01/03 seed + 159-02/04 stances/headshots, all pushed). Waves 3-4 (159-05 cull + 159-06 gate) DATE-GATED >= 2026-08-05 (MI+VA primaries Aug-4). Nothing in v2.21 is runnable before then."
progress:
  total_phases: 6
  completed_phases: 5
  total_plans: 34
  completed_plans: 32
  percent: 94
---

<!-- RESOLVED 2026-07-01 (mig 1149): VA-5/6/9 incumbent office->district rotation FIXED via guarded
     3-cycle swap of offices.politician_id + politicians.office_id back-refs. Both elections + reps
     feeds now consistent: CD-5 McGuire, CD-6 Cline, CD-9 Griffith. Idempotent (re-run = UPDATE 0). -->


# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-30 after v2.21 milestone started)

**Core value:** Every user who wants to understand their civic world can do so freely; those who want to participate can do so with trust, identity, and shared purpose — at their own pace, never dragged.
**Current focus:** Phase 159 — MI + VA Primary-Field Coverage (seed now) + Post-Primary Cull
**Last shipped:** v2.20 2026 US House Candidate Coverage (Wave 1) — Phases 148–152, shipped 2026-06-30. CA 52 / TX 38 / FL 28 / NY 26 = 144 districts, 415 active race_candidates, federal-24 stances (0 unsourced), consolidated gate 8/8 + coordinate smoke 4/4; USHC-01..06 closed. USHC-07/Phase 153 carried forward (time-gated ≥ 2026-08-18).

## Current Position

Phase: 159 (MI + VA Primary-Field Coverage (seed now) + Post-Primary Cull) — WAVES 1-2 COMPLETE; WAVES 3-4 DATE-GATED ≥ 2026-08-05
Plan: 4 of 6 complete (159-01/02/03/04); 159-05 (post-primary cull) + 159-06 (gate) locked until ≥ 2026-08-05
Status: Paused on calendar gate — MI+VA primaries are Aug-4; 159-05 has an explicit run-early STOP
Last activity: 2026-07-02 -- Wave 2 complete: MI 46/56 stanced (344 rows, 0 unsourced, 10 pinned skips, cac368d2); VA 37 stanced (288 rows, 0 unsourced, 9 genuine skips after 13/22 false-skip spot-audit recovery, b606317b). All pushed.
Carry-forward opened: PA independents (Aug-3 filing deadline) → post-Aug-10 date-gated re-check (FL-153 pattern)
Ballot flags queued for 159-05 cull (verify vs official results ≥ Aug-5): MI — Prieto -261108 / Goci -261301 / King -261305 / Murphy -261104 / S.Baker -261101 disqualified, Rais -260704 off-ballot; VA — Roma, Van Meter, Cook, Hall withdrawn (VA-9 D field = Crockett/Murphy/Powers)

## v2.21 Phase Dependencies

```
Phase 154 (Field Resolution + Stance-Gap Diagnostic)   — no deps; MUST run first (gates all seeding)
  ├── Phase 155 (PA + IL Seeding — create races + candidates)   — needs 154; anchors USHC2-02/03/04/05
  ├── Phase 156 (OH + GA + NC Seeding — create races + candidates) — needs 154; sequenced after 155
  └── Phase 157 (MI + NJ + VA Seeding — create races + candidates) — needs 154; sequenced after 156
Phase 158 (Coordinate Verification Gate)               — needs 155, 156, 157 complete
```

Phases 155/156/157 each cover disjoint states so are data-independent once Phase 154 resolves the field; the sequential order 155→156→157 is for pipeline inheritance, not data dependency (identical to v2.20's 149→150→151 pattern). All 8 Wave-2 states follow the TX+NY (create-races-first) pattern — none have pre-seeded 2026 House races.

## v2.21 Requirement Coverage

| Requirement | Phase 154 | Phase 155 (PA+IL) | Phase 156 (OH+GA+NC) | Phase 157 (NJ) | Phase 159 (MI+VA) |
|-------------|:---------:|:-----------------:|:--------------------:|:--------------:|:-----------------:|
| USHC2-01 Field Resolution | ✅ | | | | |
| USHC2-02 Records | | ✅ anchor | ✅ | ✅ NJ | ✅ seeded (Wave 1) |
| USHC2-03 Race Wiring | | ✅ anchor | ✅ | ✅ NJ | ✅ seeded (Wave 1) |
| USHC2-04 Headshots | | ✅ anchor | ✅ | ✅ NJ | ✅ (Wave 2) |
| USHC2-05 Stances | | ✅ anchor | ✅ | ✅ NJ | ✅ (Wave 2) |
| USHC2-06 Verification Gate | | | | Phase 158 ✅ (89 decided) | ◻ 159-06 gate (≥ Aug-5, after 159-05 cull) |

100% coverage: all 6 USHC2 requirements mapped, no orphans. Remaining open work: 159-05 (MI+VA post-primary cull) + 159-06 (24-district gate), both date-gated ≥ 2026-08-05.

## v2.21 Execution Methodology (carry-forward for plan-phase)

- **Production project ref:** `kxsdzaojfaibhuzmclfq`.
- **PURE DATA — no backend code.** Surfacing = Path B: elections feed reading `essentials.races` + `essentials.race_candidates`; geography inherited via `office_id → districts.geo_id` + `ST_Covers`. Path A invisible to /elections; reps feed filters `is_incumbent=true` (excludes challengers).
- **All 8 states: create elections + races first.** None of the 8 Wave-2 states have pre-seeded 2026 House races. All follow the TX+NY Phase-150 pattern: one `essentials.elections` row per state (`election_date='2026-11-03'`, e.g. "PA 2026 Statewide General") + one `essentials.races` row per district with `office_id` → the existing `NATIONAL_LOWER` US House office for that district. **NEVER** `office_id IS NULL` on a House race.
- **`race_candidates` shape:** non-null `politician_id`, `candidate_status=active`, incumbent `is_incumbent=true`; NEVER party on candidate card (lives on `races.primary_party`).
- **Two costliest traps, prevented by Phase 154:** (1) duplicate incumbent records — reuse existing `politician_id` (already seeded v2.15–v2.17); (2) lost-incumbent-primary (PA/IL/OH/GA/NC all held primaries) — verify nominee per district from results, never from incumbency. GA-13 open seat and VA-11 Connolly retirement require special handling.
- **external_id scheme for new challengers:** `-(state_fips * 10000 + cd * 100 + seq)` — verify 0 collisions per state before authoring. State FIPS: PA=42, IL=17, OH=39, GA=13, NC=37, MI=26, NJ=34, VA=51.
- **Stance pipeline:** federal 24-topic set (`_TOPIC_SCALE_FULL.txt`), `politician-stance-researcher` at 3-concurrency, per-candidate CSV → field-count-validate → `_merge.ts` → `_push_uuid.ts` (new NULL-external_id) / `_push.ts` (existing). **Mandatory primary-source verification pass before every push.** 0-unsourced gate; honest-skip thin topics; whole-record skip allowed + gate-pinned. Wipe `essentials.quotes` per pid before re-push on any quote correction.
- **Fetch-walls:** Ballotpedia blank + Wikipedia TOC-only → Playwright/raw-wikitext. Register free FEC key (api.data.gov/signup, 1000/hr); one paginated per-state call.
- **Finance out of scope:** challenger `finance_summary` → v2.22+; record no-FEC-ID rather than retry.
- **VA note:** VA-11 vacancy — verify current officeholder status at plan time (Connolly retired March 2025; special election may have filled or be scheduled). VA NATIONAL_LOWER district offices and geofencing are present from v2.15/v2.10.
- **Scope groupings:**
  - Phase 155: PA (17) + IL (17) = 34 districts (largest two; anchor the pipeline)
  - Phase 156: OH (15) + GA (14) + NC (14) = 43 districts (mid-tier, largest batch by volume)
  - Phase 157: MI (13) + NJ (12) + VA (11) = 36 districts (final three)
  - Phase 158: gate across all 113 districts

> v2.20 requirement coverage + methodology below are HISTORICAL (shipped milestone). See .planning/milestones/v2.20-ROADMAP.md for full v2.20 phase details.

## Deferred Items

Re-acknowledged at v2.20 close (2026-06-30).

| Category | Item | Status |
|----------|------|--------|
| quick_task | 22 historical quick-task dirs (001–022) | missing status markers (mostly completed long ago) |
| verification_gap | Phase 109 (v2.9 LA County) — 109-VERIFICATION.md | human_needed (stale, pre-v2.15) |
| carry_forward | **USHC-07 / Phase 153 — FL post-primary re-check** | **time-gated: executes ≥ 2026-08-18** (FL provisional field shipped in v2.20; two-path prune of primary losers + confirm advancing nominees after the Aug-18 FL primary) |
| carry_forward | AZ Lt Governor (Prop 131 eff. Jan 2027) | deferred per requirements |
| carry_forward | McDowell NC-6 (−37006) honest-skip | await future documentable record; auto-fill later |
| carry_forward | 3 House vacancies (FL-20/GA-13/TX-23) | re-run seed script once special elections seat members |
| carry_forward | v2.22+ remaining ~178 US House districts (beyond top-12 delegations) | next Wave of the multi-milestone House program |

## Performance Metrics

**v2.20 Scope — 2026 US House Candidate Coverage (Wave 1) — COMPLETE ✅**

- Phases: 5 (148–152), 32 plans
- Requirements: 6/7 closed (USHC-01..06); USHC-07/Phase-153 carried forward (time-gated ≥ 2026-08-18)
- Output: 144 districts (CA 52 / TX 38 / FL 28 / NY 26), 415 active race_candidates, federal-24 stances (0 unsourced), headshots, consolidated gate 8/8 + coordinate smoke 4/4
- Shipped: 2026-06-30 (tag v2.20)

**v2.21 Scope — 2026 US House Candidate Coverage (Wave 2) — IN PROGRESS**

- Phases: 5 (154–158), plans TBD
- Requirements: 0/6 closed (USHC2-01..06)
- Target: 113 districts (PA 17 / IL 17 / OH 15 / GA 14 / NC 14 / MI 13 / NJ 12 / VA 11)

## Accumulated Context

### Roadmap Evolution

- Phase 157 edited: MI+NJ+VA -> NJ+VA (23 districts); MI split to date-gated Phase 159
- Phase 158 edited: gate scoped to 100 decided-state districts; MI verified in 159
- Phase 159 added: MI Candidate Seeding + Verification, date-gated >= 2026-08-04 (MI primary Aug 4)
- Phase 159 REFRAMED (2026-07-01): "wait until Aug 4, seed decided nominees" -> "seed full pre-primary qualified field NOW (all parties, records+headshots+full federal-24 stances) + post-primary cull >= Aug 5". Applies FL's provisional-field pattern (Phase 151 seed -> 153 cull) to MI+VA. Rationale: serve primary voters at the Aug-4 civic moment; FL already does this (181-cand provisional field live) — MI/VA were the un-principled dark exception. DB-confirmed: FL 181 active cands, VA 0 (races scaffolded), MI 0 (fully dark). VA primary date verified Aug-4 (moved from June). Operator chose FULL coverage (accepts loser stance work discarded at cull).
- Phase 159 Waves 1-2 COMPLETE (2026-07-01/02): 159-01 MI seed (migs 1146/1147: 1 election + 13 races, 56 new pols + 67 active rc) + 159-03 VA seed (mig 1148: 46 new pols + 58 active rc onto 11 existing races) + mig 1149 VA-5/6/9 office-rotation fix; 159-02 MI stances (46/56, 344 rows, 0 unsourced, 10 pinned skips; headshots 4) + 159-04 VA stances (37 stanced, 288 rows, 0 unsourced, 9 genuine skips after spot-audit found 13/22 pins FALSE; headshots 6). Exact skip pins in 159-02/159-04 SUMMARY.md. Key lessons in memory (project_phase159_wave1): header-only CSV without a search trail ≠ honest-skip (21/25 false); Bouchard father/son wrong-person revert — trust the auto-guard's first-name-mismatch rejection.

### Key Decisions

Full key decisions log in PROJECT.md. All prior milestone decisions archived in milestones/.

### v2.21 Scope Notes (established 2026-06-30)

- **All 8 states require elections+races authoring first.** Unlike CA in v2.20 (which had pre-seeded 2026 races making it a race_candidates-only turnkey state), all 8 Wave-2 states need the full TX+NY Phase-150 pattern.
- **Phase 155 (PA+IL) is the anchor phase** — the first seeding phase where the per-state pipeline pattern is established for Wave 2 (mirrors Phase 149 CA as the v2.20 anchor, even though PA/IL are not turnkey). USHC2-02/03/04/05 are formally anchored here.
- **Grouping rationale (largest-first, load-balanced):** 154 (diagnostic) → 155 (34 districts: PA+IL) → 156 (43 districts: OH+GA+NC) → 157 (36 districts: MI+NJ+VA) → 158 (gate). This gives three seeding phases with 34/43/36 district loads — balanced and comparable to v2.20's pattern.
- **GA-13 open-seat status:** GA-13 was a vacancy/open seat at v2.20 close (one of the 3 carried-forward House vacancies). Phase 154 diagnostic must confirm whether a special election has been held or is scheduled and what the current general-ballot field looks like.
- **VA-11 status:** Gerry Connolly (D-VA-11) retired March 2025 due to esophageal cancer. A special election was scheduled; Phase 154 diagnostic must confirm the current officeholder and 2026 general-ballot field.
- **Incumbents already stanced:** All OH/GA/NC reps covered in v2.17 (Phase 132/133); all PA/IL reps in v2.16 (Phases 127-130); all MI/NJ reps in v2.17 (Phase 134); all VA reps in v2.10/v2.17. The stance-gap diagnostic in Phase 154 verifies coverage and surfaces any top-up needs.
- **0-unsourced is the non-negotiable gate floor** — same as v2.20. Every answer row must have a paired `inform.politician_context` row with a real fetched source URL.

### Open Blockers

None at roadmap time. Run diagnostic queries at Phase 154 plan authoring:

1. `SELECT d.geo_id, p.full_name, p.external_id, COUNT(pa.id) as stance_count FROM essentials.politicians p JOIN essentials.offices o ON o.politician_id = p.id JOIN essentials.districts d ON d.id = o.district_id LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id WHERE d.district_type = 'NATIONAL_LOWER' AND d.state IN ('PA','IL','OH','GA','NC','MI','NJ','VA') GROUP BY d.geo_id, p.full_name, p.external_id ORDER BY d.state, d.geo_id` — incumbent map + stance-gap baseline.
2. `SELECT external_id FROM essentials.politicians WHERE external_id < 0 ORDER BY external_id` — existing negative IDs for collision-free external_id scheme design per state.
3. Per-state: `SELECT COUNT(*) FROM essentials.races r JOIN essentials.elections el ON el.id = r.election_id WHERE el.election_date = '2026-11-03' AND r.office_id IN (SELECT o.id FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id WHERE d.district_type = 'NATIONAL_LOWER' AND d.state = '{ST}')` — confirm no pre-seeded 2026 races exist before authoring.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 003 | Expose jurisdiction fields on GET /api/account/me for VQ | 2026-03-18 | 6932815 | [003-expose-jurisdiction-location-fields-on-g](./quick/003-expose-jurisdiction-location-fields-on-g/) |
| 004 | Implement POST /api/vq/adjust-vr endpoint for Yellow quest VR adjustment | 2026-03-18 | 6f78510 | [004-implement-post-api-vq-adjust-vr-endpoin](./quick/004-implement-post-api-vq-adjust-vr-endpoin/) |
| 005 | Fix double-login: hash-fragment SSO loop between accounts and profile apps | 2026-03-18 | 7b6be4a | [005-fix-double-login-accounts-to-profile](./quick/005-fix-double-login-accounts-to-profile/) |
| 006 | Configure /app for Render static site deploy (profile.empowered.vote) | 2026-03-18 | df0a9b7 | [006-configure-app-render-static-site-deploy](./quick/006-configure-app-render-static-site-deploy/) |
| 007 | Admin access requests panel + Resend email notification on new submissions | 2026-03-19 | 4a2bb7a | [007-admin-access-requests-panel-and-notifications](./quick/007-admin-access-requests-panel-and-notifications/) |
| 008 | Fix representatives/me to return precise results for Connected users | 2026-03-29 | 8dfa38e | [008-fix-representatives-me-to-return-precise](./quick/008-fix-representatives-me-to-return-precise/) |
| 009 | Add weekly district staleness check cron for Connected users | 2026-03-29 | 10e5447 | [009-add-weekly-district-staleness-check-cron](./quick/009-add-weekly-district-staleness-check-cron/) |
| 010 | Fix BUG-01: restore deleted district rows for 54 CA Cicero politicians + quarantine CAL Access committee records | 2026-03-30 | dd06d9f | [010-fix-bug-01-restore-cicero-districts-quarant](./quick/010-fix-bug-01-restore-cicero-districts-quarant/) |
| 011 | Fix BUG-03: city/local officials missing from GET /essentials/representatives/me | 2026-03-30 | 64ccc0a | [011-fix-bug-03-city-officials-in-representatives](./quick/011-fix-bug-03-city-officials-in-representatives/) |
| 012 | Fix CA NATIONAL_UPPER senators (Padilla + Schiff) missing from geofence search | 2026-03-30 | 1b95f0e | [012-fix-ca-national-upper-senators-padilla-geofence](./quick/012-fix-ca-national-upper-senators-padilla-geofence/) |
| 013 | Phase 43 — Integration Documentation for Chris Andrews' team | 2026-03-30 | 85267c1 | [013-phase-43-integration-documentation-for-chri](./quick/013-phase-43-integration-documentation-for-chri/) |
| 014 | Add City Council district to jurisdiction data (connected_profiles + DashboardPage) | 2026-04-09 | c88eee1 | [014-add-city-council-district-to-jurisdicti](./quick/014-add-city-council-district-to-jurisdicti/) |
| 015 | Session polling for cross-app logout sync | 2026-04-09 | 091fb16 | [015-session-polling-cross-app-logout-sync](./quick/015-session-polling-cross-app-logout-sync/) |
| 016 | CA SoS 2026 challenger ingestion — 49 challengers across 16 LA County Primary races | 2026-04-13 | cfc2f40 | [016-ca-sos-challenger-ingestion](./quick/016-ca-sos-challenger-ingestion/) |
| 017 | Import verified 2026 LA County primary candidates | 2026-04-13 | — | [017-import-verified-2026-la-county-primary-c](./quick/017-import-verified-2026-la-county-primary-c/) |
| 018 | Add municipality_geo_id support so LA City races display for LA residents | 2026-04-13 | — | [018-add-municipality-geo-id-support-so-la-ci](./quick/018-add-municipality-geo-id-support-so-la-ci/) |
| 019 | Rename accounts.empowered.vote to login.empowered.vote in runtime code | 2026-04-15 | ac151ef | [019-rename-accounts-to-login-empowered-vote](./quick/019-rename-accounts-to-login-empowered-vote/) |
| 020 | FC post history tab on DashboardPage — PostHistory component with cursor pagination | 2026-04-17 | 0da4072 | [020-build-fc-post-history-feature-on-account](./quick/020-build-fc-post-history-feature-on-account/) |
| 021 | Add candidate support to compass compare | 2026-05-14 | 5eb3852 | [021-add-candidate-support-to-compass-compar](./quick/021-add-candidate-support-to-compass-compar/) |
| 022 | Fix Malik inversion bug, run 24 stance ingest scripts (255 rows), extend compassService dual-path fallback | 2026-05-15 | 01b3bfe | [022-run-pending-stance-ingest-and-extend-ca](./quick/022-run-pending-stance-ingest-and-extend-ca/) |
| 023 | Deep candidate coverage — CA Gov (Hilton/Becerra) +11 sourced stances + 2 headshots; LA Mayor (Bass/Raman) reasoning enriched; ALL 4 candidates + pre-existing stances primary-source fact-checked (4 honest-skips deleted, value/quote/source corrections); both Govs at 22 symmetric state-tier | 2026-06-23 | c96d749f | [023-deep-candidate-coverage-gov-la-mayor](./quick/023-deep-candidate-coverage-gov-la-mayor/) |

## Session Continuity

Last session: 2026-07-02
Stopped at: Phase 159 Waves 1-2 complete; all v2.21 remaining work is calendar-gated
Resume file: .planning/phases/159-mi-candidate-seeding-verification-date-gated-primary-aug-4-2/ (159-05/06 plans + 159-02/159-04 SUMMARY.md skip pins)

## Operator Next Steps

- **≥ 2026-08-05:** `/gsd-execute-phase 159` Waves 3-4 (159-05 post-primary cull vs official MI SoS / VA results, then 159-06 24-district gate) — closes USHC2-06 and v2.21
- **≥ 2026-08-10:** PA independents re-check (Aug-3 filing deadline; FL-153 pattern)
- **≥ 2026-08-18:** Phase 153 — FL post-primary re-check (USHC-07 carry-forward from v2.20)
- **Anytime:** `/gsd-cleanup` (v2.20 phase dirs 148-152 still in .planning/phases/); Phase 156 carry-forwards (NCSBE NC-minor-line prune, OH-1 Stoops-vs-Hancock); or scope Wave 3 (~178 remaining districts) via `/gsd-new-milestone`
- Note: a parallel session is working Phases 177/178 (Hillsboro/Tigard OR) in this repo — avoid collisions on those phase dirs and Oregon data

## Decisions

- [v2.21 roadmap]: All 8 Wave-2 states follow the TX+NY (create-races-first) pattern — none have pre-seeded 2026 House races; CA-style turnkey does not apply.
- [v2.21 roadmap]: Phase 155 (PA+IL, 34 districts) is the anchor seeding phase for USHC2-02/03/04/05; phases 156+157 are continuations. This mirrors v2.20's Phase 149 (CA) as anchor.
- [v2.21 roadmap]: Grouping by size with load balance: 154 (diag) → 155 (PA+IL=34) → 156 (OH+GA+NC=43) → 157 (MI+NJ+VA=36) → 158 (gate). 5 phases total, "standard" granularity.
- [v2.21 roadmap]: external_id scheme for new challengers = -(state_fips * 10000 + cd * 100 + seq); verify 0 collisions per state before authoring. State FIPS: PA=42, IL=17, OH=39, GA=13, NC=37, MI=26, NJ=34, VA=51.
- [v2.18 roadmap]: SEXS-02 assigned to Phase 143 (completing phase) — spans both Wave 1 (Gov+AG) and Wave 2 (SoS+Treasurer+LtGov); Phase 142 carries it partially; 143 closes it
- [v2.18 roadmap]: Feed surfacing (SEXR-05) is a smoke test in Phase 144, not a build phase — STATE_EXEC already enumerated in essentialsService.ts lines 669-716 and 1585-1598
- [v2.18 roadmap]: external_id scheme for new states = `-(state_fips * 10000 + office_seq)` — safest non-overlapping range; must verify 0 collisions against live DB before authoring
