---
phase: 148-field-resolution-stance-gap-diagnostic
plan: 02
subsystem: civic-data-diagnostics
tags: [diagnostic, read-only, field-resolution, us-house, wave-1, race-wiring, nominee-status]
requires:
  - "148-incumbent-map.csv (Plan 148-01 — DB incumbent map keyed on geo_id)"
  - "essentials.races / offices / districts (live prod, read-only — CA race UUIDs)"
  - "essentials.politicians (live prod, read-only — existing-record match for new_records_needed)"
  - "Wikipedia action=parse API + FEC /v1/candidates (external field source)"
provides:
  - "148-field-table.csv — 144-row 13-column per-district field table (general candidates, nominee_status, new_records_needed, live CA existing_race_id) consumed by Phases 149-151"
  - "148-FIELD-TABLE.md — reviewable narrative: per-state summary + full table + non-incumbent-nominee flag list + CA same-party generals + stance-gap summary"
  - "148-verify.sql — read-only prod gate (142 incumbents / 2 vacancies / 52 CA races 0-candidate / 52 CA race-id-by-geo_id match)"
  - "backend/scripts/diag-148-validate-field-table.py — CSV-shape validator (PASS)"
affects:
  - "Phase 149 (CA) — reads existing_race_id + general_candidates to insert race_candidates"
  - "Phase 150 (TX+NY) / 151 (FL) — read target_election to create races first; read incumbent_pid + new_records_needed"
  - "Phase 153 (FL re-check) — FL provisional field pruned post-Aug-18 primary"
tech-stack:
  added: []
  patterns:
    - "Wikipedia action=parse infobox candidateN/nomineeN + partyN extraction (TOC-wall bypass)"
    - "FL pre-primary qualified field from per-party Declared/Nominee subsections (provisional)"
    - "CA existing_race_id live via races.office_id->offices.district_id->districts.geo_id within 728d0074-... election"
    - "new_records_needed = candidates with no existing politicians row; renominated incumbent excluded by surname-match (DB name may differ from Wikipedia display)"
key-files:
  created:
    - .planning/phases/148-field-resolution-stance-gap-diagnostic/148-field-table.csv
    - .planning/phases/148-field-resolution-stance-gap-diagnostic/148-FIELD-TABLE.md
    - .planning/phases/148-field-resolution-stance-gap-diagnostic/148-verify.sql
    - backend/scripts/diag-148-validate-field-table.py
  modified: []
decisions:
  - "nominee_status taxonomy extended beyond the plan's 5 to 7 precise values: added incumbent-redistricted (CA Prop 50 / TX mid-decade) and incumbent-deceased (CA-1 LaMalfa) — more accurate than collapsing them into retired/vacancy"
  - "verify.sql placed in the phase dir per the plan's files_modified (not backend/scripts), keeping project psql DO-block gate convention"
  - "FL general_candidates = full per-party qualified field (provisional), since FL primary is Aug-18; Phase 151 seeds provisional, Phase 153 prunes"
metrics:
  duration: "~26 min"
  completed: "2026-06-28"
  tasks: 2
  files: 4
---

# Phase 148 Plan 02: Field Resolution + Stance-Gap Diagnostic (Field Half) Summary

Resolved and locked the verified Nov-3, 2026 general-ballot field for all 144 Wave-1 US House districts (CA 52 / TX 38 / FL 28 / NY 26) from Wikipedia's `action=parse` API (cross-checked against the registered-key FEC `/v1/candidates` per-state pull), overlaid it on the Plan 148-01 DB incumbent map by `geo_id`, re-queried all 52 CA `existing_race_id` values live from the "CA 2026 Statewide General" election, classified the genuinely-new candidate set per district, and assembled the three git-tracked reference artifacts (CSV + narrative .md + read-only verify gate) that Phases 149–151 consume without guessing. **USHC-01 fully satisfied.**

## Final per-state candidate counts

| State | Districts | General candidates | New records needed | Field status |
|-------|:---------:|:------------------:|:------------------:|:------------:|
| CA | 52 | 104 | 38 | decided |
| TX | 38 | 76 | 48 | decided |
| FL | 28 | 181 | 155 | **provisional** (pre-Aug-18 primary; full per-party qualified field) |
| NY | 26 | 54 | 33 | decided |
| **Total** | **144** | **415** | **274** | — |

`nominee_status` distribution across 144 rows: **109 incumbent-renominated, 17 incumbent-retired, 12 incumbent-redistricted, 3 incumbent-lost-primary, 2 open-seat-vacancy, 1 incumbent-deceased.** No uncalled races.

## Flagged non-incumbent-nominee districts (35 total) with nominee_status + citation

**incumbent-lost-primary (3):**
- **NY-10 (3610) Daniel S. Goldman** → lost to Brad Lander 6/24/2026 — https://www.axios.com/2026/06/24/dan-goldman-brad-lander-mamdani-new-york-primary . Nominees: Brad Lander (D), Jennifer Moore (R). *(inherited claim A1 re-confirmed)*
- **NY-13 (3613) Adriano Espaillat** → defeated by Darializa Avila Chevalier in 2026 Dem primary — Wikipedia NY#District_13. Nominees: Avila Chevalier (D), Jomo M. Williams (R), Bob Cohen (WF). *(A1 re-confirmed)*
- **TX-2 (4802) Dan Crenshaw** → defeated in primary by Steve Toth — Wikipedia TX#District_2. Nominees: Steve Toth (R), Shaun Finnie (D).

**incumbent-retired (17):** CA-11 Pelosi, CA-14 Swalwell, CA-26 Brownley, CA-48 Issa, TX-8 Luttrell, TX-10 McCaul, TX-19 Arrington, TX-21 Roy (ran for TX AG), TX-37 Doggett, TX-38 Hunt (ran for US Senate), FL-2 Dunn, FL-16 Buchanan, FL-19 Donalds (ran for Governor), FL-24 Wilson, **NY-7 (3607) Velázquez** *(A2 re-confirmed)*, **NY-12 (3612) Nadler** *(A2 re-confirmed)*, NY-21 Stefanik. Each cited to its Wikipedia per-district section.

**incumbent-redistricted (12):** CA-3 Kiley, CA-6 Bera, CA-38 L. Sánchez, CA-41 Calvert (CA Prop 50 shuffle); TX-9 Green, TX-30 Crockett, TX-32 Johnson, TX-33 Veasey, TX-35 Casar (TX mid-decade); FL-22 Frankel, FL-23 Moskowitz, FL-25 Wasserman Schultz. Incumbent keeps their record but gets no active race_candidates row in this geo_id; all general candidates here are new records.

**incumbent-deceased (1):** CA-1 (0601) Doug LaMalfa died Jan 2026; James Gallagher holds via special election and is the R nominee vs Mike McGuire (D).

**open-seat-vacancy (2):** **FL-20 (1220)** and **TX-23 (4823)** — DB-confirmed 0-holder. TX-23 cited to https://www.cbsnews.com/news/tony-gonzales-drops-out-of-house-runoff-race-after-admitting-affair-with-aide/ (Gonzales dropped out 3/5); FL-20 to Wikipedia FL#District_20.

## Uncalled districts

**None.** Every CA/TX/NY district resolved to a decided general with ≥2 candidates. FL is provisional (pre-Aug-18) by design — not "uncalled."

## CA same-party (top-two) generals — recorded party-agnostically

8 D-vs-D (CA-4, 7, 11, 12, 14, 29, 34, 37) + 1 R-vs-R (**CA-40** Ken Calvert vs Young Kim, two redistricted Republican incumbents). Both advancers' parties recorded on the race; never inferred one-D-one-R.

## CA existing_race_id resolution

**All 52 CA `existing_race_id` values resolved live** from the "CA 2026 Statewide General" election (`728d0074-8a8d-49e3-a68c-78ccdd15434f`). The query returned exactly 52 rows — no STOP, no placeholders, no research-copied UUIDs.

**Exact races↔geo_id join column used:** `essentials.races.office_id = essentials.offices.id`, then `essentials.offices.district_id = essentials.districts.id`, reading `districts.geo_id` (scoped `district_type='NATIONAL_LOWER'`, `substr(geo_id,1,2)='06'`). The `races` table has **no** direct `geo_id`/`district_id` column — the join is via `office_id` (confirmed against the live schema before relying on it). All 52 CA general races confirmed at 0 `race_candidates` (pre-seed baseline). TX/FL/NY `existing_race_id` left blank (their races are created in Phases 150/151).

## 148-verify.sql — read-only, all assertions passed

Ran `psql "$DATABASE_URL" -f .planning/phases/.../148-verify.sql` against production (`kxsdzaojfaibhuzmclfq`), **exit 0**, SELECT-only (no INSERT/UPDATE/DELETE, no `--commit`):

- **PASS 1:** 142 Wave-1 NATIONAL_LOWER non-vacant districts each map to exactly one incumbent politician_id.
- **PASS 2:** FL-20 (1220) and TX-23 (4823) still 0-holder.
- **PASS 3:** all 52 CA general races still have 0 race_candidates.
- **PASS 4:** all 52 CA `existing_race_id` values resolve to a live CA-general race whose geo_id matches the CSV row (encoded 52 (geo_id, race_id) pairs diffed both directions against the live JOIN).

`diag-148-validate-field-table.py` prints **PASS** (144 rows; CA 52 / TX 38 / FL 28 / NY 26; every row has source_url + nominee_status; every non-vacancy row has incumbent_pid; every CA row UUID-shaped existing_race_id; TX/FL/NY existing_race_id blank).

## Stance-gap top-up threshold

Per-incumbent `incumbent_stance_count` + `incumbent_top_up_tier` emitted per district (CSV-wide: 73 zero / 59 partial / 10 done / 2 vacant; ~134/142 below federal-24). **The full-24-vs-only-zeros top-up threshold is explicitly deferred to Phase 149** (operator decision at plan time), per 148-FIELD-TABLE.md.

## Deviations from Plan

**1. [Rule 2 — correctness] Extended nominee_status taxonomy from 5 to 7 values.**
- Plan enumeration: `incumbent-renominated | incumbent-lost-primary | incumbent-retired | open-seat-vacancy | uncalled`.
- Added two precise values the field genuinely required: **`incumbent-redistricted`** (12 districts where CA Prop 50 / TX mid-decade redistricting moved the seated incumbent to a different seat — collapsing these into "retired" would be inaccurate and would mislead the seeding phases about why the incumbent isn't reused here) and **`incumbent-deceased`** (CA-1, LaMalfa died in office; seat held via special). All non-renominated districts are still flagged with a citation, satisfying the must-have; the extra precision improves the trap-prevention the artifact exists for.

**2. [Rule 3 — convention] verify.sql located in the phase dir.**
- The plan's `files_modified` + Task 2 verify command reference `.planning/phases/148-.../148-verify.sql`; authored there (project psql DO-block gate convention preserved). An initial draft under `backend/scripts/` was moved to the phase dir to match the plan.

No production writes, no migrations, no application code — read-only diagnostic throughout.

## Known Stubs

None. Every cell is populated from a verified source or the live DB. FL `field_status=provisional` rows are intentional (pre-Aug-18 primary; full qualified field), to be pruned to general nominees in Phase 153 — documented, not a stub.

## Self-Check: PASSED

- FOUND: .planning/phases/148-field-resolution-stance-gap-diagnostic/148-field-table.csv (144 data rows)
- FOUND: .planning/phases/148-field-resolution-stance-gap-diagnostic/148-FIELD-TABLE.md
- FOUND: .planning/phases/148-field-resolution-stance-gap-diagnostic/148-verify.sql
- FOUND: backend/scripts/diag-148-validate-field-table.py
- FOUND commit: 7ed66407 (Task 1)
- FOUND commit: 1448b4b7 (Task 2)
