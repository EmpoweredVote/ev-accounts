---
gsd_state_version: 1.0
milestone: v2.19
milestone_name: Local Civic Coverage
status: Awaiting next milestone
last_updated: "2026-06-23T00:00:00.000Z"
last_activity: 2026-06-23 — Milestone v2.19 formalized (retroactive) and archived
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 0
  completed_plans: 0
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-20 after v2.18 milestone started)

**Core value:** Every user who wants to understand their civic world can do so freely; those who want to participate can do so with trust, identity, and shared purpose — at their own pace, never dragged.
**Current focus:** v2.19 Local Civic Coverage COMPLETE + archived (formalized retroactively). Awaiting next milestone.
**Last shipped:** v2.19 Local Civic Coverage — Phases 145–147 (inline-executed), formalized 2026-06-23. Falls Church VA (17) + Greene County MO (13) + Springfield MO (16): 46 records, 4 geofence boundaries, 118 evidence-only stances (0 unsourced), 46 headshots, 3 essentials coverage entries; LCC-01..05 closed. Migrations 1047–1049; git range a488232a → ef1a364f.

## Current Position

Phase: Milestone v2.19 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-06-23 — Milestone v2.19 formalized (retroactive) and archived

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
| 023 | Deep candidate coverage — CA Gov (Hilton/Becerra) +11 sourced stances + 2 headshots; LA Mayor (Bass/Raman) reasoning enriched (38 stances, avg 819/1084 chars, 2 Raman value changes) | 2026-06-23 | — | [023-deep-candidate-coverage-gov-la-mayor](./quick/023-deep-candidate-coverage-gov-la-mayor/) |

## Session Continuity

Last session: 2026-06-23
Stopped at: v2.19 Local Civic Coverage formalized retroactively (Falls Church VA / Greene County MO / Springfield MO) and archived; tag v2.19 created
Resume file: — (awaiting next milestone)

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

## Operator Next Steps

- v2.19 Local Civic Coverage formalized + archived (retroactive). Start the next milestone with /gsd-new-milestone, or continue local coverage informally (more cities/counties; CA-city builds Burbank/Norwalk/Bellflower available to fold into a future local-coverage milestone).
