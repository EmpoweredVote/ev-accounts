---
gsd_state_version: 1.0
milestone: v2.20
milestone_name: 2026 US House Candidate Coverage
status: ready_to_plan
last_updated: 2026-06-30T04:24:01.119Z
last_activity: 2026-06-30
progress:
  total_phases: 6
  completed_phases: 5
  total_plans: 32
  completed_plans: 32
  percent: 83
stopped_at: Phase 152 complete (1/1) — ready to discuss Phase 153
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-20 after v2.18 milestone started)

**Core value:** Every user who wants to understand their civic world can do so freely; those who want to participate can do so with trust, identity, and shared purpose — at their own pace, never dragged.
**Current focus:** Phase 153 — fl post primary re check (time gated — executes after aug 18, 2026)
**Last shipped:** v2.19 Local Civic Coverage — Phases 145–147 (inline-executed), formalized 2026-06-23. Falls Church VA (17) + Greene County MO (13) + Springfield MO (16): 46 records, 4 geofence boundaries, 118 evidence-only stances (0 unsourced), 46 headshots, 3 essentials coverage entries; LCC-01..05 closed. Migrations 1047–1049; git range a488232a → ef1a364f.

## Current Position

Phase: 153
Plan: Not started
Status: Ready to plan
Last activity: 2026-06-30

### Phase 150 done this session (commits on master, data live in prod):

- **150-01** mig 1109: 2 elections + 64 races (TX 38 geo 4801–4838 / NY 26 geo 3601–3626). TX election `783b7506-dd52-47a1-a85a-9ffc363f8a04`, NY `80a2b03d-f583-4156-a272-d51abbda0b0a`.
- **150-02** `backend/scripts/150-verify.sql`: per-state write-free gate. USHC-04 honest-skip pins (70: 43 TX + 27 NY) + USHC-02c reuse pins live.
- **150-03** mig 1110: TX 48 new politicians + 76 race_candidates. D-03 dedup: Casar TX-35→TX-37 reuse -100335; Toth TX-2 reuse -100515; **Dan Barrios TX-32 reuse e8c863a7** (Richardson councilmember = same person, web-confirmed); Allred NEW. New band -4810101..-4813802.
- **150-04** mig 1111: NY 33 new + 54 race_candidates. Goldman/Espaillat absent→Lander/Avila Chevalier active; minor lines Cohen(WF)/Smullen(Cons) seeded. New band -3610101..-3612601.
- **150-05/06** headshots: 11 auto-imaged (5 TX: Allred/Haynes/Herrera/Teixeira/Pulido; 6 NY: Oberacker/Lasher/Lander/Valdez/LiPetri/Gallant), 70 gate-pinned honest-skips. Shared `seed-tx-ny-house-headshots.py --state TX|NY`. USHC-04 PASSES.

### ⚠ STANCE BLOCKER (150-07..11) — operator decision needed:

Validation batch (TX-1..10, 20 in-scope candidates) surfaced: (a) **session limit hit** on first 3-concurrent wave (0 output); (b) single incumbent = **81k tokens / 49 tool calls**, 10/24 topics; (c) **primary sources 403/blank-walled** (GovTrack/congress.gov/house.gov/Ballotpedia) → values lean on OnTheIssues aggregator + pre-incumbency 2022 campaign positions; (d) **the mandatory D-05 primary-source verification pass is itself blocked** by the same walls (needs Playwright-per-URL at ~107-candidate scale); (e) Moran abortion=4 is a visible over-read. Moran CSV produced but NOT pushed (unverified; scratch in `tx-2026-house-b1/`). `_FED24_SCALE.txt` extract built.
Stance in-scope: TX = all 76 active (D-01 all-zero-incumbent); NY = 33 new only (D-01 partials untouched). ~107 needing federal-24.
Next: operator chooses stance pacing/approach. Then 150-12 final gate + coordinate smoke.

### v2.20 Phase Dependencies

```
Phase 148 (Field Resolution + Stance-Gap Diagnostic)   — no deps; MUST run first (gates all seeding)
  ├── Phase 149 (CA Seeding — race_candidates only)     — needs 148; turnkey (53 races pre-seeded); validates pattern
  ├── Phase 150 (TX + NY Seeding — create races first)  — needs 148; independent of 149/151; sequenced after 149
  └── Phase 151 (FL Seeding — provisional qualified)    — needs 148; independent of 149/150; sequenced after 150
Phase 152 (Coordinate Verification Gate)               — needs 149, 150, 151 complete
Phase 153 (FL Post-Primary Re-Check)                   — needs 151 AND date ≥ 2026-08-18 (DATE-GATED; executes after FL primary)
```

CA/TX/NY are independent of each other once Phase 148 resolves the field; the 149→150→151 order is for pipeline inheritance, not data dependency. Phase 153 is planned now but **executes/closes after the FL primary (Aug 18, 2026)** — Phases 148–152 ship the live Wave-1 experience (116 final + 28 provisional districts) before this re-check.

### v2.20 Requirement Coverage (target)

| Requirement | Phase 148 | Phase 149 (CA) | Phase 150 (TX+NY) | Phase 151 (FL) | Phase 152 | Phase 153 |
|-------------|:---------:|:--------------:|:-----------------:|:--------------:|:---------:|:---------:|
| USHC-01 Field Resolution | ◻ | | | | | |
| USHC-02 Records | | ◻ anchor | ◻ | ◻ | | |
| USHC-03 Race Wiring | | ◻ anchor | ◻ | ◻ | | |
| USHC-04 Headshots | | ◻ anchor | ◻ | ◻ | | |
| USHC-05 Stances | | ◻ anchor | ◻ | ◻ | | |
| USHC-06 Verification Gate | | | | | ◻ | |
| USHC-07 FL Re-Check | | | | | | ◻ (date-gated) |

100% coverage: all 7 USHC requirements mapped, no orphans. USHC-02/03/04/05 are state-partitioned (anchored at 149, continued 150/151; gate at 152).

### v2.20 Execution Methodology (carry-forward for plan-phase)

- **Production project ref:** `kxsdzaojfaibhuzmclfq`.
- **PURE DATA — no backend code.** Surfacing = Path B: elections feed reading `essentials.races` + `essentials.race_candidates`; geography inherited via `office_id → districts.geo_id` + `ST_Covers`. Path A (candidacy offices) is invisible to /elections; reps feed filters `is_incumbent=true` (excludes challengers). Empty-state UI is in the separate Essentials frontend repo, not this milestone.
- **Per-state work split:** CA = insert `race_candidates` only (53 races pre-seeded; template `scripts/ingest-ca-sos-2026-challengers.ts`). TX/NY = author `elections`+`races` first, then candidates. FL = provisional from FL DoE tab-delimited download, seed-now.
- **`race_candidates` shape:** non-null `politician_id` (NULL = no stances/photo), `candidate_status=active`, incumbent `is_incumbent=true`; NEVER `office_id IS NULL` on a House race (statewide convention); NEVER party on candidate card (lives on `races.primary_party`).
- **Two costliest traps, prevented by Phase 148:** (1) duplicate incumbent records (v2.4 two-Andy-Barrs / mig-1074) — reuse existing `politician_id`; (2) lost-incumbent-primary (NY-10 Goldman, NY-13 Espaillat both lost 6/23) — verify nominee per district from results, never from incumbency.
- **Stance pipeline:** federal 24-topic set (`_TOPIC_SCALE_FULL.txt`), `politician-stance-researcher` at 3-concurrency, per-candidate CSV → field-count-validate → `_merge.ts` → `_push_uuid.ts` (new NULL-external_id) / `_push.ts` (existing). **Mandatory primary-source verification pass before every push** (re-fetch raw quotes via Playwright; prior pass deleted 16 inference rows). 0-unsourced gate; honest-skip thin topics; whole-record skip allowed + gate-pinned. Wipe `essentials.quotes` per pid before re-push on any quote correction.
- **Fetch-walls:** Ballotpedia blank + Wikipedia TOC-only → Playwright/raw-wikitext. Register free FEC key (api.data.gov/signup, 1000/hr; DEMO_KEY 10/hr stalls); one paginated per-state call. FL: tab-delimited bulk download bypasses the ASP SPA.
- **Two-path prune (Phase 153, FL):** `politicians.is_active=false` AND `race_candidates.candidate_status=withdrawn` — NEVER hard-DELETE. Re-research advancing thin winners against primary sources.
- **Finance out of scope:** challenger `finance_summary` → v2.21+; record no-FEC-ID rather than retry.

> v2.19 / v2.18 requirement coverage + methodology below are HISTORICAL (shipped milestones).

### v2.19 Requirement Coverage

| Requirement | Phase 145 (Falls Church VA) | Phase 146 (Greene County MO) | Phase 147 (Springfield MO) |
|-------------|:---------------------------:|:----------------------------:|:--------------------------:|
| LCC-01 Records   | ✅ 17 | ✅ 13 | ✅ 16 |
| LCC-02 Boundaries | ✅ school G5420 | ✅ county G4020 | ✅ place G4110 + school G5420 |
| LCC-03 Stances   | ✅ 55 | ✅ 26 | ✅ 37 |
| LCC-04 Headshots | ✅ 17 | ✅ 13 | ✅ 16 |
| LCC-05 Coverage  | ✅ COVERAGE_STATES | ✅ COVERAGE_COUNTIES | ✅ COVERAGE_STATES |

All 5 requirements (LCC-01..05) delivered across phases 145–147 — 46 records · 4 boundaries · 118 stances (0 unsourced) · 46 headshots · 3 coverage entries. Executed inline (no plan dirs); per-jurisdiction deep-dive memory files are the build record.

> v2.18 State Leaders requirement coverage + execution detail archived in `.planning/milestones/v2.18-*` and `MILESTONES.md`.

### v2.18 Phase Dependencies

```
Phase 141 (Roster Lock + Seed)                    — no dependencies; must run first (roster gates everything)
  └── Phase 142 (Stance Wave 1: Gov + AG)          — needs Phase 141 UUIDs; SEXS-01 prompt update is plan 142-01
  └── Phase 143 (Stance Wave 2: SoS+Treasurer+LtGov) — needs Phase 141 UUIDs; recommended after 142 (proxy-row calibration)
Phase 144 (Phase Gate)                            — needs Phases 141, 142, 143 complete
```

Phases 142 and 143 are independent of each other (disjoint office types) but both require Phase 141. Phase 144 requires all three preceding phases complete.

### v2.18 Execution Methodology (carry-forward for plan-phase)

- **In-scope filter:** `WHERE d.district_type = 'STATE_EXEC' AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a WHERE a.politician_id = p.id)` — scope to politician UUIDs, not external_id range (exec external_ids are heterogeneous across states).
- **Production project ref:** `kxsdzaojfaibhuzmclfq`.
- **Seed dedup key:** `(district_type='STATE_EXEC', state=XX, role_canonical)` on districts — never title string. Dry-run gap query must return 0 new rows for the 9 already-seeded states before any INSERT executes.
- **external_id scheme:** `-(state_fips * 10000 + office_seq)` per new state — verify 0 collisions against live negative IDs before authoring; document chosen scheme in migration header comment.
- **State code:** always uppercase 2-char postal abbreviation; include post-insert assertion in every migration (`state = upper(state)` check).
- **geo_id:** `'{state_fips}'` (string, e.g. `'48'` for TX) — never NULL or empty; gate asserts `COUNT(*) WHERE geo_id IS NULL OR geo_id = '' = 0`.
- **Office-type evidence guidance (mandatory before stance dispatch):** Gov = bill signings/vetoes/EOs; AG = filed lawsuits/amicus briefs/multistate coalitions (coalition counts ONLY when coalition has a published position directly on topic); Treasurer = investment/divestment decisions (documented fund actions); SoS = specific election administration actions (not role description); LtGov = honest-partial if no independent record.
- **Stance pipeline reuse:** `_TOPIC_SCALE.txt` (25 topics, unchanged from v2.16/v2.17), `politician-stance-researcher` at **3-concurrency**, per-exec CSV → `_merge.ts` → external_id-keyed `_push.ts`; proxy-row review gate standard before every push.
- **Existing records:** CA execs fully stanced — never re-research. IN Governor already stanced. Run stance gap diagnostic (COUNT(pa.id) per STATE_EXEC politician UUID) before authoring any research plans.
- **True denominator:** 208 (not 250). AZ Lt Gov deferred (Prop 131, eff. Jan 2027); documented in Phase 144 gate as known exclusion.

### v2.18 Key Data Points (from research)

**208-office breakdown:**

- 50 Governor (all states)
- 43 Lt. Governor (excl. ME/NH/OR/WY=none; TN/WV=Senate Speaker by statute; AZ=deferred eff.2027)
- 43 Attorney General (excl. AK/HI/NH/NJ/WY=Gov appoints; ME=legislature; TN=Supreme Court)
- 35 Secretary of State (excl. AK/HI/UT=no office; DE/FL/NJ/NY/OK/PA/TX/VA=Gov appoints; ME/NH/TN=legislature)
- 37 Treasurer (excl. TX/MN/MT/NY=abolished/absorbed; AK/GA/HI/MI/NJ/VA=Gov appoints; ME/MD/NH/TN=legislature; FL=CFO, NY/TX=Comptroller are in-scope equiv)

**9 already-seeded states (68 records):**

- CA: all 5 Big 5 + extras — fully stanced, no action needed for records
- IN: Gov stanced; AG/SoS/Treasurer missing stances (need research); check if AG/SoS/Treasurer records exist
- MA: all 5 Big 5 seeded (Auditor also there but not Big 5)
- MD: Gov+LtGov+AG in scope (3); Comptroller seeded but NOT Big 5 for MD; Treasurer leg-elected
- ME: Gov is only in-scope Big 5 (1); 0 stances on all existing records
- OR: Gov+AG+SoS+Treasurer in scope (4; no LtGov); check stance coverage
- TX: Gov+LtGov+AG in scope (3); Comptroller = Treasurer equiv already seeded; SoS is appointed (OUT)
- UT: Gov+LtGov+AG+Treasurer in scope (4; no SoS); check if AG+Treasurer records exist
- VA: Gov+LtGov+AG in scope (3); SoS+Treasurer appointed — VA already has all 3 records

**41 states with zero STATE_EXEC records** — all in-scope Big 5 must be seeded from scratch.

### v2.18 Critical Pitfall Reminders

1. **Phantom offices:** Use 208-office matrix from FEATURES.md — never a 50x5 flat grid. ME=1, TN=1, NJ=2, AK=2, HI=2, WY=3, MD=3, TX=3, VA=3.
2. **Dedup on (STATE_EXEC, state, role_canonical)** — never title string. Title strings are inconsistent ("Indiana Governor" vs "Governor" vs "California Governor").
3. **Uppercase state code always** — lowercase `or` silently breaks feed routing (migration 223 production defect). Post-insert assertion mandatory.
4. **geo_id = '{fips}'** (string, non-empty) — never NULL; gate asserts this.
5. **Verify all officeholders from live source** — 37 gubernatorial races ran in 2024; January 2026 inaugurations may not be in training data.
6. **Stance gap diagnostic before dispatch** — filter by `NOT EXISTS` on `inform.politician_answers` keyed on politician UUID; never re-research stanced execs (CA execs, IN Governor).
7. **external_id collision check** — query `SELECT external_id FROM essentials.politicians WHERE external_id < 0 ORDER BY external_id` before authoring any new state migration.
8. **Office-type evidence before first dispatch** (SEXS-01) — exec actions are not floor votes; AG multistate coalitions count only with published topical platform.

### v2.17 Execution Notes (archive reference for pipeline reuse)

- **Concurrency = 3** confirmed safe on premium tier.
- **Per-rep output files → merged + RFC-4180-validated** into the batch CSV.
- **Embed scale via a shared `_TOPIC_SCALE.txt`** (fetched live) that each agent Reads — token-efficient.
- **Resolve politician_id by external_id→UUID map**, not name.
- **Proxy-row drop rule (standing):** "overall record alignment", coalition membership without published topical platform, office role description — all dropped before push. Caucus membership counts ONLY when caucus has a published platform directly on that topic.
- **One-try-per-URL efficiency rule** — agents that hang on a URL re-fetch loop blow the session; one fetch attempt per URL, then move on.
- **MCP Supabase tokens expire ~1 hour** — fall back to `node --import tsx` + `pool` from `backend/src/lib/db.js` for verification queries; load `dotenv/config`.
- **`_push.ts` does NOT load dotenv** — run with `set -a && source .env && set +a && node --import tsx .../​_push.ts <csv>`.

## Deferred Items

Re-acknowledged at v2.18 close (2026-06-22). All pre-existing, none from v2.18.

| Category | Item | Status |
|----------|------|--------|
| quick_task | 22 historical quick-task dirs (001–022) | missing status markers (mostly completed long ago) |
| verification_gap | Phase 109 (v2.9 LA County) — 109-VERIFICATION.md | human_needed (stale, pre-v2.15) |
| carry_forward | AZ Lt Governor (Prop 131 eff. Jan 2027) | deferred to v2.19+ per requirements |
| carry_forward | McDowell NC-6 (−37006) honest-skip | await future documentable record; auto-fill later |
| carry_forward | 3 House vacancies (FL-20/GA-13/TX-23) | re-run seed script once special elections seat members |

## Performance Metrics

**v2.17 Scope — National House Rep Stances (Tier 2 continuation) — COMPLETE ✅**

- Phases: 9 (132–140)
- Requirements: 9/9 closed (USHS-06..14)
- Plans complete: ~45
- Shipped: 2026-06-20

**v2.18 Scope — State Leaders — COMPLETE ✅**

- Phases: 4 (141–144)
- Requirements: 8/8 closed (SEXR-01..05, SEXS-01..03)
- Plans complete: 34
- Shipped: 2026-06-22

**v2.19 Scope — Local Civic Coverage — COMPLETE ✅**

- Phases: 3 (145–147), executed inline (no plan dirs)
- Requirements: 5/5 closed (LCC-01..05)
- Output: 46 records, 4 boundaries, 118 stances (0 unsourced), 46 headshots, 3 coverage entries
- Shipped: 2026-06-23 (formalized retroactively)

## Accumulated Context

### Key Decisions

Full key decisions log in PROJECT.md. All prior milestone decisions archived in milestones/.

### v2.18 Scope Notes (established 2026-06-20)

- **True denominator = 208**, not 250. Count: 50+43+43+35+37 = 208. AZ LtGov deferred (eff. Jan 2027, not seated yet).
- **Stance phases split by office type** (not by state) because evidence types differ across offices. Governors+AGs (richer archives) in Wave 1, SoS+Treasurer+LtGov in Wave 2.
- **SEXS-01 (prompt update) is plan 142-01**, not a standalone phase. It must be the first plan of Phase 142.
- **SEXS-02 spans both waves 142+143.** Assigned to Phase 143 (completing phase). Phase 142 carries partial SEXS-02 for Gov+AG.
- **Feed surfacing (SEXR-05) is a smoke test in the gate**, not a build phase. `STATE_EXEC` is already enumerated in `essentialsService.ts` at both query sites — no code change needed.
- **MD Comptroller is NOT a Big 5 Treasurer equivalent for MD.** MD in-scope = Gov + LtGov + AG only (3). NY/TX Comptrollers ARE the Treasurer equivalent (absorbed duties). FL CFO is the Treasurer equivalent.
- **MA title aliases:** MA Secretary of the Commonwealth = `role_canonical = secretary_of_state`. MA Treasurer and Receiver-General = `role_canonical = treasurer`.
- **TN has only 1 in-scope office** (Governor). LtGov = Senate Speaker by statute, AG = Supreme Court appoints, SoS + Treasurer = legislature. Do not seed TN AG/SoS/Treasurer/LtGov.
- **NJ has 2 in-scope offices** (Governor + LtGov on ticket). All other NJ Big 5 are Governor-appointed.
- **WV and TN "LtGov" exclusion:** Both are Senate Presidents designated by statute — not popularly elected. Do NOT seed as LtGov.
- **AL FIPS = 01 (single digit):** `-(01 * 10000 + seq)` = -10001..-10005 range; verify no collision with AL House reps which used `-1001..-1007`.

### v2.13–v2.14 Scope Notes (carry-forward for reference)

- **Tiger_geoid backfill pattern**: For city council districts, `tiger_geoid` = city FIPS code padded to match `geo_districts.geoid` format. Always join on `(tiger_geoid, district_type)`.
- **Phase gate SQL pattern**: 8+ labeled assertions, one per requirement. `DO $$ BEGIN IF NOT (...) THEN RAISE EXCEPTION ... END IF; END $$;` style.
- **MAGE-05 filter**: Always add `mtfcc IN ('G5210','G5220')` when querying geofence_boundaries for MA state legislative layers.

### Open Blockers

None for v2.18 start. Run the live diagnostic queries at plan authoring time:

1. `SELECT state, COUNT(*) FROM essentials.districts WHERE district_type='STATE_EXEC' GROUP BY state ORDER BY state` — confirm 9-state baseline and exact record counts before authoring seeds.
2. `SELECT p.full_name, p.external_id, COUNT(pa.id) as stance_count FROM essentials.politicians p JOIN essentials.offices o ON o.politician_id = p.id JOIN essentials.districts d ON d.id = o.district_id LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id WHERE d.district_type = 'STATE_EXEC' GROUP BY p.id ORDER BY stance_count, p.full_name` — stance gap diagnostic for 9 existing states.
3. `SELECT external_id FROM essentials.politicians WHERE external_id < 0 ORDER BY external_id` — existing negative IDs for collision-free external_id scheme design.

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
| Phase 148 P01 | 5 min | 2 tasks | 2 files |
| Phase 149 P1 | 18min | 2 tasks | 2 files |
| Phase 149 P02 | 12min | 1 tasks | 1 files |
| Phase 149 P03 | 15min | 1 tasks | 2 files |

## Session Continuity

Last session: 2026-06-30T04:18:08.104Z
Stopped at: Phase 150 context gathered
Resume file: None

## Decisions

- [v2.18 roadmap]: SEXS-02 assigned to Phase 143 (completing phase) — spans both Wave 1 (Gov+AG) and Wave 2 (SoS+Treasurer+LtGov); Phase 142 carries it partially; 143 closes it
- [v2.18 roadmap]: Feed surfacing (SEXR-05) is a smoke test in Phase 144, not a build phase — STATE_EXEC already enumerated in essentialsService.ts lines 669-716 and 1585-1598
- [v2.18 roadmap]: external_id scheme for new states = `-(state_fips * 10000 + office_seq)` — safest non-overlapping range; must verify 0 collisions against live DB before authoring
- [Phase 118-01]: Migration number 619 (not 600) — disk files 600–618 already taken by Phase 117 stance files; DB MAX was 604 at execution time; disk wins
- [Phase 118-01]: PROJ_LIB path is C:\Program Files\GDAL\projlib (not C:\OSGeo4W\share\proj as documented in CONTEXT.md)
- [Phase 118-02]: Migration number 622 (not 601) — DB MAX was 619; disk highest was 621 (621_malakie_stances.sql); use 622 for Medford fix + city tiger_geoid backfill
- [Phase 118-02]: MAGE-05 requires mtfcc IN ('G5210','G5220') filter — geo_id '25017' exists as both Middlesex County (G4020) and 8th Bristol SLDL District (G5220); unfiltered subquery returns 3 rows; mtfcc filter returns correct 2 rows
- [Phase 118-03]: Medford Step 5 omitted — charter reform 2020 creates fully at-large council; migration 711 follows 709 (Fall River) at-large pattern with 2-gate post-verification only
- [Phase 123-04]: Fall River and Medford Path 0 spot checks require essentialsService join pattern (d.geo_id=gb.geo_id + G4110 discriminator) — citywide LOCAL rows have mtfcc=NULL; tiger_geoid join (gb.mtfcc=d.mtfcc) fails silently for NULL vs G4110
- [Phase ?]: [Phase 148-01]: Map incumbents by (NATIONAL_LOWER, geo_id) — never computed external_id (CA -6000301 verified live; -(fips*1000+cd) mis-keys CA/TX). Wave-1 stance gap: 73 zero / 59 partial / 10 done / 2 vacant (FL-20 1220, TX-23 4823).
- [Phase 148-02]: nominee_status taxonomy extended to 7 values — added incumbent-redistricted (CA Prop 50 + TX mid-decade, 12 districts) + incumbent-deceased (CA-1 LaMalfa). 144 rows: 109 renominated / 17 retired / 12 redistricted / 3 lost-primary / 2 vacancy / 1 deceased. 274 new candidate records needed (CA 38 / TX 48 / FL 155-provisional / NY 33). NY-10 Goldman + NY-13 Espaillat re-confirmed lost-primary (Axios/Wiki); NY-7 Velázquez + NY-12 Nadler retired; FL-20/TX-23 vacancy.
- [Phase 148-02]: CA existing_race_id join is races.office_id->offices.district_id->districts.geo_id (races has NO direct geo_id); all 52 resolved live from "CA 2026 Statewide General" (728d0074), 0 race_candidates baseline. FL field provisional (Aug-18 primary) = full per-party qualified field, pruned in Phase 153. 148-verify.sql passes read-only (4 assertions, psql exit 0).
- [Phase ?]: [Phase 149-01]: New CA House challenger external_id scheme = -(6010000 + cd*100 + seq); -(6000000+cd*100+seq) COLLIDED with -6000xxx incumbents; -6010000..-6015999 band verified empty.
- [Phase ?]: [Phase 149-01]: essentials.politicians has NO updated_at column — UPDATE must not set it (migration rollback caught it).
- [Phase ?]: [Phase 149-01]: CA seeded 38 NEW + 66 REUSE (38 matches 148, 0 live name-flips); redistricted runners (Bera CA-3/Kiley CA-6/Calvert CA-40) reuse pid is_incumbent=false; Ruiz dup 05349fa0 retired, CA-25 wired to 5238b298; mig 1091; 104 race_candidates, Gov race untouched (76).
- [Phase ?]: USHC-02c reuse pin excludes Linda Sánchez CA-41 (new record -6014101, not pid reuse); gate House-scoped NATIONAL_LOWER+728d0074; USHC-04/05 fail pre-Wave-2/3 by design
- [Phase ?]: [Phase 149-03]: CA House headshot wrong-person guard hardened (title must contain candidate first+surname, reject election/place/event + non-political disambiguators); base guard false-passed 21/25; auto-pass imaged 4/36; 32 to manual; USHC-04 PARTIAL

## Operator Next Steps

- v2.19 Local Civic Coverage formalized + archived (retroactive). Start the next milestone with /gsd-new-milestone, or continue local coverage informally (more cities/counties; CA-city builds Burbank/Norwalk/Bellflower available to fold into a future local-coverage milestone).
