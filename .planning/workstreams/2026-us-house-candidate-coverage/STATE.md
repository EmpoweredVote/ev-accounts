---
gsd_state_version: 1.0
milestone: v2.22
milestone_name: 2026 US House Candidate Coverage
current_phase: 173
current_phase_name: discovery-sweep-anthropic-cost-reliability-hardening
status: executing
stopped_at: Completed 173-02-PLAN.md
last_updated: "2026-07-23T07:33:22.226Z"
last_activity: 2026-07-23
last_activity_desc: Phase 173 execution started
progress:
  total_phases: 10
  completed_phases: 7
  total_plans: 81
  completed_plans: 80
  percent: 70
---

<!-- RESOLVED 2026-07-01 (mig 1149): VA-5/6/9 incumbent office->district rotation FIXED via guarded
     3-cycle swap of offices.politician_id + politicians.office_id back-refs. Both elections + reps
     feeds now consistent: CD-5 McGuire, CD-6 Cline, CD-9 Griffith. Idempotent (re-run = UPDATE 0). -->

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-02 after v2.22 milestone started)

**Core value:** Every user who wants to understand their civic world can do so freely; those who want to participate can do so with trust, identity, and shared purpose — at their own pace, never dragged.
**Current focus:** Phase 173 — discovery-sweep-anthropic-cost-reliability-hardening
**Last shipped:** v2.20 2026 US House Candidate Coverage (Wave 1) — Phases 148–152, shipped 2026-06-30. CA 52 / TX 38 / FL 28 / NY 26 = 144 districts, 415 active race_candidates, federal-24 stances (0 unsourced), consolidated gate 8/8 + coordinate smoke 4/4; USHC-01..06 closed. USHC-07/Phase 153 carried forward (time-gated ≥ 2026-08-18).

## Current Position

Phase: 173 (discovery-sweep-anthropic-cost-reliability-hardening) — EXECUTING
Plan: 4 of 4
Status: Ready to execute
Last activity: 2026-07-23 — Phase 173 execution started

## v2.22 Phase Dependencies

```
Phase 160 (Field Resolution + Stance-Gap Diagnostic)         — no deps; MUST run first (gates all seeding)
  ├── Phase 161 (WA+AZ+TN+MA Seeding — create races + candidates)                    — needs 160; anchors USHC3-02/03/04/05
  ├── Phase 162 (IN+MD+MN+MO Seeding — create races + candidates)                    — needs 160; sequenced after 161
  ├── Phase 163 (WI+CO+AL+SC+LA Seeding — create races + candidates)                 — needs 160; sequenced after 162
  ├── Phase 164 (KY+OR+CT+OK+AR+IA+KS+MS Seeding — create races + candidates)        — needs 160; sequenced after 163
  └── Phase 165 (17 small-delegation states Seeding — create races + candidates)     — needs 160; sequenced after 164
Phase 166 (Consolidated Verification Gate)                   — needs 161, 162, 163, 164, 165 complete
Phase 167 (Post-Primary Reconciliation, date-gated Aug–Sep 2026) — needs 160 (provisional fields seeded) + each cluster's actual primary date; may extend past Phase 166 close (Sep clusters carry forward, FL-153/159-05 precedent)
```

Phases 161–165 each cover disjoint states so are data-independent once Phase 160 resolves the field; the sequential order 161→162→163→164→165 is for pipeline inheritance, not data dependency (identical to v2.20's 149→150→151 and v2.21's 155→156→157 pattern). All 38 Wave-3 states follow the create-races-first pattern — none have pre-seeded 2026 House races.

## v2.22 Requirement Coverage

| Requirement | Phase 160 | 161 (WA+AZ+TN+MA) | 162 (IN+MD+MN+MO) | 163 (WI+CO+AL+SC+LA) | 164 (KY+OR+CT+OK+AR+IA+KS+MS) | 165 (17 small states) | Phase 166 | Phase 167 |
|-------------|:---------:|:------------------:|:------------------:|:----------------------:|:--------------------------------:|:------------------------:|:---------:|:---------:|
| USHC3-01 Field Resolution | ✅ | | | | | | | |
| USHC3-02 Records | | ✅ anchor | ✅ | ✅ | ✅ | ✅ | | |
| USHC3-03 Race Wiring | | ✅ anchor | ✅ | ✅ | ✅ | ✅ | | |
| USHC3-04 Headshots | | ✅ anchor | ✅ | ✅ | ✅ | ✅ | | |
| USHC3-05 Stances | | ✅ anchor | ✅ | ✅ | ✅ | ✅ | | |
| USHC3-06 Verification Gate | | | | | | | ✅ | |
| USHC3-07 Post-Primary Reconciliation | | | | | | | | ◻ date-gated |

100% coverage: all 7 USHC3 requirements mapped to Phases 160–167, no orphans. District load per seeding phase: 161=37, 162=33, 163=36, 164=38, 165=34 (sum 178).

## v2.22 Execution Methodology (carry-forward for plan-phase)

- **Production project ref:** `kxsdzaojfaibhuzmclfq`.
- **PURE DATA — no backend code.** Surfacing = Path B: elections feed reading `essentials.races` + `essentials.race_candidates`; geography inherited via `office_id → districts.geo_id` + `ST_Covers`. Path A invisible to /elections; reps feed filters `is_incumbent=true` (excludes challengers).
- **All 38 states: create elections + races first.** None of the 38 Wave-3 states have pre-seeded 2026 House races. All follow the TX+NY Phase-150 pattern: one `essentials.elections` row per state (`election_date='2026-11-03'`) + one `essentials.races` row per district with `office_id` → the existing `NATIONAL_LOWER` US House office for that district. **NEVER** `office_id IS NULL` on a House race.
- **`race_candidates` shape:** non-null `politician_id`, `candidate_status=active`, incumbent `is_incumbent=true`; NEVER party on candidate card (lives on `races.primary_party`).
- **Two costliest traps, prevented by Phase 160:** (1) duplicate incumbent records — reuse existing `politician_id` (already seeded v2.15–v2.17); (2) lost-incumbent-primary — verify nominee per district from results in decided states, never from incumbency.
- **Primary-status split (generalized from v2.21 Phase-159):** decided states seed the confirmed general field; late-primary states seed the FULL qualified pre-primary field marked `PROVISIONAL:` in the SAME seeding phase (never deferred to a separate date-gated seeding phase) — only the post-primary cull (Phase 167) is date-gated.
- **external_id scheme for new challengers:** `-(state_fips * 10000 + cd * 100 + seq)` — same scheme as Waves 1/2; verify 0 collisions per state before authoring. State FIPS: WA=53, AZ=04, TN=47, MA=25, IN=18, MD=24, MN=27, MO=29, WI=55, CO=08, AL=01, SC=45, LA=22, KY=21, OR=41, CT=09, OK=40, AR=05, IA=19, KS=20, MS=28, NV=32, UT=49, NM=35, NE=31, WV=54, ID=16, HI=15, ME=23, NH=33, RI=44, MT=30, AK=02, DE=10, ND=38, SD=46, VT=50, WY=56.
- **Stance pipeline:** federal 24-topic set (`_TOPIC_SCALE_FULL.txt`), `politician-stance-researcher` at **3-concurrency (never more)**, per-candidate CSV → field-count-validate → `_merge.ts` → `_push_uuid.ts` (new NULL-external_id) / `_push.ts` (existing). **Mandatory primary-source verification pass before every push.** 0-unsourced gate; honest-skip thin topics — a header-only CSV without a documented search trail is NOT a valid skip (21/25 false skips caught in v2.21's 159 Wave-2 spot-audit); whole-record skip allowed + gate-pinned with a written search trail. Wipe `essentials.quotes` per pid before re-push on any quote correction.
- **Fetch-walls:** Ballotpedia blank + Wikipedia TOC-only → Playwright/raw-wikitext. Bluesky public JSON bypasses JS walls; r.jina.ai works on many news sites. Register/reuse the free FEC key (api.data.gov/signup, 1000/hr); one paginated per-state call.
- **Headshot trap:** trust the find-headshots auto-guard's first-name-mismatch rejection (Bouchard father/son wrong-person trap from v2.21 159-Wave-1) — do not override it.
- **Finance out of scope:** challenger `finance_summary` → future milestone; record no-FEC-ID rather than retry.
- **Scope groupings (largest-delegation-first, load-balanced ~33-38 districts/phase):**
  - Phase 161: WA (10) + AZ (9) + TN (9) + MA (9) = 37 districts (largest four; anchor the pipeline)
  - Phase 162: IN (9) + MD (8) + MN (8) + MO (8) = 33 districts
  - Phase 163: WI (8) + CO (8) + AL (7) + SC (7) + LA (6) = 36 districts
  - Phase 164: KY (6) + OR (6) + CT (5) + OK (5) + AR (4) + IA (4) + KS (4) + MS (4) = 38 districts
  - Phase 165: NV (4) + UT (4) + NM (3) + NE (3) + WV (2) + ID (2) + HI (2) + ME (2) + NH (2) + RI (2) + MT (2) + AK (1) + DE (1) + ND (1) + SD (1) + VT (1) + WY (1) = 34 districts (17 states)
  - Phase 166: gate across all 178 districts
  - Phase 167: date-gated post-primary reconciliation, per-state-cluster plans (exact clusters resolved by Phase 160's primary-date research)

> v2.20 and v2.21 requirement coverage + methodology are HISTORICAL (v2.20 fully shipped; v2.21 Waves 1-2 complete, 159-05/06 tail date-gated ≥ 2026-08-05). See `.planning/milestones/v2.20-ROADMAP.md` and `.planning/milestones/v2.21-ROADMAP.md` for full phase details, and `.planning/ROADMAP.md`'s collapsed v2.21/v2.20 sections for the carried-forward execution methodology text below.

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
| carry_forward | v2.21 159-05/06 — MI+VA post-primary cull + gate | date-gated: executes ≥ 2026-08-05 (day after Aug-4 MI+VA primaries) |
| carry_forward | v2.22+ remaining ~178 US House districts (beyond top-12 delegations) | **NOW IN PROGRESS as v2.22 Phases 160–167** (roadmap created 2026-07-03) |
| carry_forward | **MO revert branch (164.1-07)** — if the referendum qualifies by 2026-08-04, MO does ZERO polygon work, stays withheld, and the revert diverts to **Phase 167's MO cluster** | date-gated: decision ≥ 2026-08-04 (SOS Hoskins certification) |
| carry_forward | **Jan-2027 boundary promotion** — promote G5200V26→canonical + offices re-key + user_districts/connected_profiles re-resolve + retire D-11 fallback | date-gated ≥ 2027-01-03; spec: `164.1-jan2027-boundary-promotion-spec.md` |

## Performance Metrics

**v2.20 Scope — 2026 US House Candidate Coverage (Wave 1) — COMPLETE ✅**

- Phases: 5 (148–152), 32 plans
- Requirements: 6/7 closed (USHC-01..06); USHC-07/Phase-153 carried forward (time-gated ≥ 2026-08-18)
- Output: 144 districts (CA 52 / TX 38 / FL 28 / NY 26), 415 active race_candidates, federal-24 stances (0 unsourced), headshots, consolidated gate 8/8 + coordinate smoke 4/4
- Shipped: 2026-06-30 (tag v2.20)

**v2.21 Scope — 2026 US House Candidate Coverage (Wave 2) — Waves 1-2 COMPLETE, tail date-gated**

- Phases: 6 (154–159), plans mostly complete
- Requirements: 5/6 closed (USHC2-01..05); USHC2-06 partial (89-district decided-state gate ✅; MI+VA gate pending 159-06, date-gated ≥ 2026-08-05)
- Output so far: 113 districts total (89 decided + 24 MI+VA provisional-seeded/stanced)

**v2.22 Scope — 2026 US House Candidate Coverage (Wave 3 — National Completion) — PLANNING**

- Phases: 8 (160–167), plans TBD
- Requirements: 0/7 closed (USHC3-01..07)
- Target: 178 districts across the final 38 states (WA 10 down to AK/DE/ND/SD/VT/WY 1 each)

**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 173 P01 | 20min | 3 tasks | 2 files |
| Phase 173 P03 | 2min | 2 tasks | 2 files |
| Phase 173 P02 | 2min | 3 tasks | 2 files |

## Accumulated Context

### Roadmap Evolution

- Phase 157 edited: MI+NJ+VA -> NJ+VA (23 districts); MI split to date-gated Phase 159
- Phase 158 edited: gate scoped to 100 decided-state districts; MI verified in 159
- Phase 159 added: MI Candidate Seeding + Verification, date-gated >= 2026-08-04 (MI primary Aug 4)
- Phase 159 REFRAMED (2026-07-01): "wait until Aug 4, seed decided nominees" -> "seed full pre-primary qualified field NOW (all parties, records+headshots+full federal-24 stances) + post-primary cull >= Aug 5". Applies FL's provisional-field pattern (Phase 151 seed -> 153 cull) to MI+VA. Rationale: serve primary voters at the Aug-4 civic moment; FL already does this (181-cand provisional field live) — MI/VA were the un-principled dark exception. DB-confirmed: FL 181 active cands, VA 0 (races scaffolded), MI 0 (fully dark). VA primary date verified Aug-4 (moved from June). Operator chose FULL coverage (accepts loser stance work discarded at cull).
- Phase 159 Waves 1-2 COMPLETE (2026-07-01/02): 159-01 MI seed (migs 1146/1147: 1 election + 13 races, 56 new pols + 67 active rc) + 159-03 VA seed (mig 1148: 46 new pols + 58 active rc onto 11 existing races) + mig 1149 VA-5/6/9 office-rotation fix; 159-02 MI stances (46/56, 344 rows, 0 unsourced, 10 pinned skips; headshots 4) + 159-04 VA stances (37 stanced, 288 rows, 0 unsourced, 9 genuine skips after spot-audit found 13/22 pins FALSE; headshots 6). Exact skip pins in 159-02/159-04 SUMMARY.md. Key lessons in memory (project_phase159_wave1): header-only CSV without a search trail ≠ honest-skip (21/25 false); Bouchard father/son wrong-person revert — trust the auto-guard's first-name-mismatch rejection.
- **v2.22 roadmap created (2026-07-03):** Phases 160–167 derived from USHC3-01..07. Generalizes the v2.21 Phase-159 "seed full provisional field now, cull later" principle to ALL late-primary states in Wave 3 (not a special case) — every seeding phase (161–165) may contain a mix of decided and late-primary states, resolved per-district by Phase 160. Grouping: largest-delegation-first, load-balanced 33-38 districts/phase (37/33/36/38/34), same methodology as v2.20/v2.21 (5 phases total kept the granularity comparable despite 178 vs 113/144 districts, per "standard" granularity guidance).
- Phase 164.1 inserted after Phase 164: Cross-State District Polygon Refresh + Dual-Map Design (TN/MO/AL/LA/UT) — D-01c from Phase 161 discussion: redistricted-state polygons must refresh before Phase 165 (UT full re-key) and well before Nov-3; un-gates TN districts withheld under 161 D-01b; likely needs backend query changes (dual-map: reps feed on current-representation boundaries until Jan 2027, elections on 2026 boundaries) (URGENT)

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

None at roadmap time. Run diagnostic queries at Phase 160 plan authoring:

1. `SELECT d.geo_id, p.full_name, p.external_id, COUNT(pa.id) as stance_count FROM essentials.politicians p JOIN essentials.offices o ON o.politician_id = p.id JOIN essentials.districts d ON d.id = o.district_id LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id WHERE d.district_type = 'NATIONAL_LOWER' AND d.state IN ('WA','AZ','TN','MA','IN','MD','MN','MO','WI','CO','AL','SC','LA','KY','OR','CT','OK','AR','IA','KS','MS','NV','UT','NM','NE','WV','ID','HI','ME','NH','RI','MT','AK','DE','ND','SD','VT','WY') GROUP BY d.geo_id, p.full_name, p.external_id ORDER BY d.state, d.geo_id` — incumbent map + stance-gap baseline for all 38 states.
2. `SELECT external_id FROM essentials.politicians WHERE external_id < 0 ORDER BY external_id` — existing negative IDs for collision-free external_id scheme design per state.
3. Per-state: `SELECT COUNT(*) FROM essentials.races r JOIN essentials.elections el ON el.id = r.election_id WHERE el.election_date = '2026-11-03' AND r.office_id IN (SELECT o.id FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id WHERE d.district_type = 'NATIONAL_LOWER' AND d.state = '{ST}')` — confirm no pre-seeded 2026 races exist before authoring.
4. Per-state 2026 congressional primary date lookup (official SoS sources) — the classification input for the decided/late-primary split and for clustering Phase 167's date-gated plans.

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
| Phase 160 P01 | 10min | 3 tasks | 6 files |
| Phase 160 P07 | 25min | 3 tasks | 4 files |
| Phase 161 P03 | 210min | 3 tasks | 18 files |
| Phase 161 P05 | 165min | 0 tasks | 9 files |
| Phase 161 P11 | 90m | 2 tasks | 3 files |
| Phase 163 P01 | 55min | 2 tasks | 3 files |
| Phase 163 P02 | 35min | 3 tasks | 5 files |
| Phase 163 P03 | 20 | 3 tasks | 5 files |

## Session Continuity

Last session: 2026-07-23T07:33:16.200Z
Stopped at: Completed 173-02-PLAN.md
Resume file: None

## Operator Next Steps

- **Anytime:** `/gsd-plan-phase 165` (UT dependency satisfied — 164.1 Wave 2 delivered UT G5200V26 polygons + `164.1-ut-wiring-contract.md`).
- **≥ 2026-08-04:** `/gsd-execute-phase 164.1 --wave 4` — Plan 164.1-07, MO date-gated (SOS Hoskins certification decision): map-holds branch = MO G5200V26 import + un-withhold 2902-2906 + flip the 162 gate; referendum-qualifies branch = zero polygon work, MO stays withheld, divert to Phase 167's MO cluster.
- **≥ 2027-01-03:** plan the Jan-2027 boundary-promotion phase per `164.1-jan2027-boundary-promotion-spec.md` — promote G5200V26→canonical, re-key `essentials.offices` (UT wiring contract + state correspondences), re-resolve `connect.user_districts`, refresh `connected_profiles.congressional_geo_id`, and RETIRE the D-11 `resolve_congressional_2026` read-path fallback.
- **D-11 SHIPPED in 164.1 (2026-07-07) — delivered, NOT an accepted limitation:** differential-zone Connected-tier users' `/elections` is corrected in-phase by a read-only live fallback (`connect.resolve_congressional_2026`, migration 1246 — decrypts server-side, ST_Covers vs G5200V26, FIPS 47/29/01/22/49 only, NO cache mutation) substituted in Paths 1/1.5 of `/api/elections/me`. Live-proven by the 1641 smoke's direct-RPC sentinel probe for TN/AL/LA/UT. The Jan-2027 promotion phase retires it once the cache is authoritative.
- **Phase 166 inheritance:** the consolidated gate inherits the FLIPPED (now positive) TN/AL/LA severe assertions — 161-verify asserts all 9 TN surfacing, 163-verify asserts all 7 AL + 6 LA surfacing — and the 13 un-withheld districts (TN 4704/4705/4706/4708/4709 + AL 0102 + LA 2202/2206 + their non-severe peers already surfacing) join the 178-district assertion set; MO's 5 severe (2902-2906) stay asserted-withheld until Plan 164.1-07 clears.
- **≥ 2026-08-05:** `/gsd-execute-phase 159` Waves 3-4 (159-05 post-primary cull vs official MI SoS / VA results, then 159-06 24-district gate) — closes USHC2-06 and v2.21
- **≥ 2026-08-10:** PA independents re-check (Aug-3 filing deadline; FL-153 pattern)
- **≥ 2026-08-18:** Phase 153 — FL post-primary re-check (USHC-07 carry-forward from v2.20)
- ~~`/gsd-cleanup`~~ DONE 2026-07-02 (v2.20 dirs 148-152 → milestones/v2.20-phases/, b5084500)
- ~~Phase 156 carry-forwards #1/#2~~ DONE 2026-07-02 (mig 1168, 37701cf7): NC field reconciled vs official NCSBE general list — all 9 NC Libertarians certified (feared mass-prune was false); pruned Rogers NC-11 + Aguilar NC-13 (not certified, 0 stances/imgs); added Bo Whitehead (Green, NC-8, honest-skip pinned). OH-1: Hancock confirmed certified Libertarian nominee (won May-5 primary 91.2% over Stoops write-in; LPO site listing = stale endorsement) — no data change. 156 gate re-run 11/11 PASS.
- Note: a parallel session is working Phases 177/178 (Hillsboro/Tigard OR) in this repo — avoid collisions on those phase dirs and Oregon data. **v2.22 phase numbers (160-167) do not conflict with 177/178.**

## Decisions

- [v2.22 roadmap]: Phases start at 160 (159 dirs preserved for the v2.21 date-gated tail); 177/178 remain reserved and are not approached (v2.22 runs 160-167, well clear).
- [v2.22 roadmap]: Phase 160 (diagnostic) generalizes the v2.21 Phase-159 principle to all 38 states — every seeding phase may mix decided and late-primary states, resolved per-district; late-primary states seed the full provisional field in the SAME seeding phase, never a separate date-gated seeding phase.
- [v2.22 roadmap]: 5 seeding phases (161-165), largest-delegation-first, load-balanced by district count (37/33/36/38/34 = 178), not by state count — mirrors v2.20's 149-150-151 and v2.21's 155-156-157 grouping logic.
- [v2.22 roadmap]: Phase 161 (WA+AZ+TN+MA, 37 districts) is the anchor seeding phase for USHC3-02/03/04/05; Phases 162-165 are continuations.
- [v2.22 roadmap]: Phase 166 (gate) depends on all 5 seeding phases; Phase 167 (post-primary reconciliation) is structured as per-state-primary-date-cluster plans, authored once Phase 160 resolves exact clusters; Sep-primary clusters may carry forward past milestone close (FL-153/159-05 precedent).
- [v2.22 roadmap]: external_id scheme continues unchanged: -(state_fips * 10000 + cd * 100 + seq); verify 0 collisions per state before authoring.
- [v2.21 roadmap]: All 8 Wave-2 states follow the TX+NY (create-races-first) pattern — none have pre-seeded 2026 House races; CA-style turnkey does not apply.
- [v2.21 roadmap]: Phase 155 (PA+IL, 34 districts) is the anchor seeding phase for USHC2-02/03/04/05; phases 156+157 are continuations. This mirrors v2.20's Phase 149 (CA) as anchor.
- [v2.21 roadmap]: Grouping by size with load balance: 154 (diag) → 155 (PA+IL=34) → 156 (OH+GA+NC=43) → 157 (MI+NJ+VA=36) → 158 (gate). 5 phases total, "standard" granularity.
- [v2.21 roadmap]: external_id scheme for new challengers = -(state_fips * 10000 + cd * 100 + seq); verify 0 collisions per state before authoring. State FIPS: PA=42, IL=17, OH=39, GA=13, NC=37, MI=26, NJ=34, VA=51.
- [v2.18 roadmap]: SEXS-02 assigned to Phase 143 (completing phase) — spans both Wave 1 (Gov+AG) and Wave 2 (SoS+Treasurer+LtGov); Phase 142 carries it partially; 143 closes it
- [v2.18 roadmap]: Feed surfacing (SEXR-05) is a smoke test in Phase 144, not a build phase — STATE_EXEC already enumerated in essentialsService.ts lines 669-716 and 1585-1598
- [v2.18 roadmap]: external_id scheme for new states = `-(state_fips * 10000 + office_seq)` — safest non-overlapping range; must verify 0 collisions against live DB before authoring
- [Phase 160-01]: diag-160-external-id-collision.ts hardcodes KY-CD1 and OK-CD1 to safe_start_seq=200 per Critical Finding 6, not just a saturation-threshold heuristic
- [Phase 160-01]: diag-160-race-preexistence-audit.ts uses LEFT JOIN race_candidates so 0-candidate pre-scaffolded races (MD/OR) still emit a full-column audit row with existing_race_id populated
- [Phase 160-07]: 160-verify.sql A2 rewritten (not copied) from the 154 template to assert the DISCOVERED 29-race baseline (ME2/MD8/MA9/NV4/OR6) + race_candidates counts (NV=9/MA=2/ME=2/MD=0/OR=0), never a blanket 0-races/0-candidates claim.
- [161-03]: No Task/Agent tool available this session; researched all 24 AZ candidates directly via Playwright-driven fetches of Ballotpedia/campaign sites instead of dispatching politician-stance-researcher sub-agents, applying identical chairs-not-polarity/honest-skip standards
- [161-03]: Discovered 5 of the 24 target AZ candidates (Ajluni, Descheenie, Davison, Bracht, Bah) withdrew or were disqualified from the 2026 ballot after the 161-02 snapshot; pinned as ballot-ineligibility whole-record skips for the 161-11 gate rather than researching stances for non-ballot candidates
- [Phase ?]: 161-05: No Task/Agent tool available (matches 161-03) — researched all 23 remaining WA challengers directly via curl/wayback/Wikipedia; 9 sourced (46/60 total), 14 pinned whole-record honest-skips incl. a John Roco cross-state-homonym identity-risk flag for the 161-11 gate.
- [Phase ?]: [161-11]: AZ roster reconciliation applied via migration 1204 (candidate_status='withdrawn' for 5 ballot-ineligible candidates), excluding them from the gate's active-scoped in-scope set
- [Phase ?]: [161-11]: 161-verify.sql + 161-coordinate-smoke.ts both green against prod -- all 37 WA/AZ/TN/MA districts satisfy USHC3-02/03/04/05, TN severe-district withholding proven end-to-end
- [Phase 163]: 163-01: AL severe geo_id set = {0102} only (1/7); AL-1/6/7 needed special primaries procedurally but score below the severity rubric on evidence
- [Phase 163]: 163-01: LA severe geo_id set = {2202, 2206} (2/6), sourced from an enrolled-statute (SB8-2024 vs SB121-2026) parish-by-parish diff; LA-4 flagged borderline for downstream spot-check
- [Phase 163-02]: WI-7 Tiffany (retired to run for Governor) is REUSE-NO-ROW open seat, no active House row; WI-2 legitimately 2-candidate all-D race (Pocan+Alexander), no Republican filed, verified not an error
- [Phase 163-02]: seed-wi-house-headshots.py hardened with a _FOREIGN_NATIONALITY guard after Douglas Alexander (WI-2) resolved to a British Labour MP homonym; bad upload deleted from prod before commit
- [Phase 163]: 163-03: DeGette CO-1 lost-primary treated as REUSE-NO-ROW (new incumbent-transition pattern, third variant); her existing record/office/19 stances untouched, not wired into CO-1 race_candidates
- [Phase 163]: 163-03: CO decided-field race description follows the IN 'Confirmed nominees' convention, not PROVISIONAL
- [Phase ?]: 173-01: checkAnthropicAvailability canary uses claude-haiku-4-5 (cheapest); only APIError status 401/402/403 classify as unusable, everything else re-thrown as inconclusive so 173-02's sweep can proceed
- [Phase ?]: 173-01: runDiscoveryAgent's no-report exit paths return zero-candidate results (not throw); no changes needed to discoveryService.ts's existing zero-candidate completed path
- [Phase ?]: OPS-03 zero-candidate caller contract regression-locked in discoveryService.test.ts; no source change needed (RESEARCH Pattern 3)
- [Phase ?]: OPS-04 weekly cron cadence documented as deliberate bounded-cost choice; cadence/timezone unchanged
- [Phase ?]: [Phase 173-02]: isRetryable classifies other 4xx (400/404/422) as non-retryable too, not just 401/402/403 — a retry on any 4xx fails identically
- [Phase ?]: [Phase 173-02]: runDiscoverySweep preflight aborts only on a RETURNED {available:false} from checkAnthropicAvailability, never on a thrown (inconclusive) error — thrown errors are logged and the sweep proceeds
