---
phase: 148-field-resolution-stance-gap-diagnostic
verified: 2026-06-28T00:00:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
re_verification:
  none: "initial verification"
---

# Phase 148: Field Resolution + Stance-Gap Diagnostic — Verification Report

**Phase Goal:** The verified Nov-3 general-ballot field is locked for all 144 Wave-1 districts, every district where the incumbent is NOT the 2026 nominee is explicitly flagged, and every district incumbent is mapped to its existing `politician_id` — so no seeding phase can create a duplicate incumbent or surface a non-candidate.
**Requirement:** USHC-01
**Verified:** 2026-06-28
**Status:** PASSED — phase goal achieved
**Re-verification:** No — initial verification

## VERDICT

**PHASE GOAL ACHIEVED.** All four ROADMAP success criteria are verified against the live codebase and production DB, not merely against the SUMMARY claims. The three reference artifacts (`148-field-table.csv`, `148-FIELD-TABLE.md`, `148-verify.sql`) plus the two diagnostic scripts exist, are substantive, are internally consistent, and are corroborated by independent live DB queries. The phase is a read-only data/diagnostic phase; it correctly performs zero production writes. Ready for Phases 149–151 to consume.

## Goal Achievement — Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Per-district field table for all 144 districts (CA 52 / TX 38 / FL 28 / NY 26), each listing Nov-3 candidates, CA/TX/NY `decided` + FL `provisional` | ✓ VERIFIED | `148-field-table.csv` = 144 data rows (145 lines). Per-state via robust CSV parse: CA 52 / TX 38 / FL 28 / NY 26. `field_status` by state: CA/TX/NY all `decided` (116), FL all `provisional` (28). Every row has non-empty `general_candidates` + `source_url`. |
| 2 | Every non-incumbent-nominee district flagged (lost-primary/retirement/open), incl. NY-10 Goldman + NY-13 Espaillat from a primary-results source; CA top-two same-party recorded party-agnostically | ✓ VERIFIED | NY-10 (3610) + NY-13 (3613) = `incumbent-lost-primary` w/ citations (Axios 6/24, Wikipedia NY#District_13). NY-7 (3607) + NY-12 (3612) = `incumbent-retired`. FL-20 (1220) + TX-23 (4823) = `open-seat-vacancy`. nominee_status dist: 109 renominated / 17 retired / 12 redistricted / 3 lost-primary / 2 vacancy / 1 deceased; 35 non-renominated all flagged + cited. CA same-party: 8 D-vs-D + CA-40 R-vs-R (Calvert vs Kim) recorded with both parties. |
| 3 | Stance-gap diagnostic maps each incumbent to existing `politician_id` + reports stance count; incumbents below federal-24 surfaced | ✓ VERIFIED | `148-incumbent-map.csv` 145 lines. All 142 non-vacancy rows carry a UUID `incumbent_pid` (robust UUID-regex check: 0 failures) resolved by `(district_type='NATIONAL_LOWER', geo_id)` — 0 computed-external_id lookups. `incumbent_stance_count` + `incumbent_top_up_tier` per row; CSV-wide 73 zero / 59 partial / 10 done / 2 vacant. Live independent query confirms 142 mapped incumbents. |
| 4 | Genuinely-new candidate set enumerated per state, distinct from reused incumbents/previously-seeded figures | ✓ VERIFIED | `new_records_needed` populated per district (CA 38 / TX 48 / FL 155 / NY 33 = 274). The 17 empty rows independently confirmed correct: every candidate in them has an exact-name existing `essentials.politicians` record (e.g. CA-1 Gallagher+McGuire, CA-11 Chan+Wiener, CA-40 Calvert+Kim, plus renominated-row challengers Joe Males/Eric Ching/April Verlato/Houston Brignano). |

**Score: 4/4 truths verified.**

## Required Verification Checks (run by verifier, not trusting SUMMARY)

| # | Check | Result | Status |
|---|-------|--------|--------|
| 1 | `148-field-table.csv` row count = 144; CA 52 / TX 38 / FL 28 / NY 26 | 144 total; CA 52 / TX 38 / FL 28 / NY 26 | ✓ PASS |
| 2 | `diag-148-validate-field-table.py` prints PASS | `PASS: 144 rows ... all 52 CA existing_race_id UUID-shaped`, exit 0 | ✓ PASS |
| 3 | `148-verify.sql` all 4 assertions PASS, psql exit 0 | PASS 1 (142 incumbents) / PASS 2 (FL-20+TX-23 0-holder) / PASS 3 (52 CA races 0-candidate) / PASS 4 (52 CA race-id↔geo_id match); `DO` / exit 0 | ✓ PASS |
| 4 | NY-10+NY-13 lost-primary w/ citation; NY-7+NY-12 retired; FL-20+TX-23 open-seat-vacancy | All six confirmed with correct nominee_status + source_url | ✓ PASS |
| 5 | Every non-vacancy row has UUID incumbent_pid; every CA row has UUID existing_race_id | 0 missing pids; 0 missing/non-UUID CA race_ids; 0 non-CA rows with a stray race_id | ✓ PASS |
| 6 | `148-FIELD-TABLE.md` has per-state summary, full 144-row table, flag list, stance-gap summary w/ Phase 149 deferral | All sections present; full table = 144 rows; explicit "NOT decided here — Phase 149 scoping decision" note | ✓ PASS |

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `essentials.districts (NATIONAL_LOWER, geo_id)` | `politicians.id (incumbent_pid)` | district→office→politician join | ✓ WIRED | 142 incumbents mapped by geo_id; live query reconciles; UUIDs not computed external_ids |
| `148-incumbent-map.csv` | `148-field-table.csv` | geo_id left-join | ✓ WIRED | All 142 non-vacancy field-table rows carry incumbent_pid + stance_count from the map |
| `essentials.races (CA 728d0074… general)` | `148-field-table.csv existing_race_id` | live re-query via `races.office_id→offices.district_id→districts.geo_id` | ✓ WIRED | 52 CA UUIDs; verify.sql PASS 4 diffs the 52 (geo_id,race_id) pairs both directions against live JOIN |

## Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real Data | Status |
|----------|------|--------|-----------|--------|
| `148-field-table.csv` incumbent_pid/stance_count | per-district | live `essentials`/`inform` via diag-148 script + geo_id join | Yes — independently re-queried (142 incumbents) | ✓ FLOWING |
| `148-field-table.csv` existing_race_id (CA) | 52 UUIDs | live `essentials.races` within CA general election | Yes — verify.sql PASS 4 confirms each resolves live | ✓ FLOWING |
| `148-field-table.csv` general_candidates/nominee_status | per-district field | Wikipedia action=parse + FEC /v1/candidates (cited per row) | Yes — every row has source_url; key NY/FL/TX flags spot-checked | ✓ FLOWING |

## Behavioral / Probe Execution

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| CSV validator | `python backend/scripts/diag-148-validate-field-table.py` | PASS, exit 0 | ✓ PASS |
| Prod gate | `psql … -f 148-verify.sql` | 4/4 assertions PASS, exit 0 | ✓ PASS |
| Independent live count | direct SELECT (CA races + Wave-1 incumbents) | 52 CA races / 142 incumbents | ✓ PASS |

## Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `diag-148-incumbent-stance-gap.ts` | none (SELECT-only; writeFileSync only to git-tracked CSV) | — | clean |
| `148-verify.sql` | `INSERT INTO _csv_ca` is into `CREATE TEMP TABLE … ON COMMIT DROP` | ℹ Info | Not a production write — standard read-only assertion pattern (encodes 52 expected pairs for in-DB diff); SELECT-only confirmed |
| All phase files | no TBD/FIXME/XXX/placeholder | — | clean |

## Deviation Assessment — nominee_status 5 → 7 values

**Sound and well-documented. Not a defect.** The plan enumerated 5 values; the executor added `incumbent-redistricted` (12 CA Prop 50 / TX mid-decade districts) and `incumbent-deceased` (CA-1 LaMalfa). Success criterion 2 requires every non-2026-nominee district be *flagged*; all 35 such districts remain flagged with a citation. Collapsing redistricted/deceased into "retired"/"vacancy" would have *misinformed* the seeding phases about why the incumbent isn't reused there. The extra precision strengthens the trap-prevention purpose of the artifact. Documented in 148-02-SUMMARY (Deviations #1) and 148-FIELD-TABLE.md flag-list sections.

## Follow-Ups for Phases 149–151 (informational, not gaps)

1. **`new_records_needed` matching is naive surname/exact-name** — corroborated correct here, but Phase 149 (USHC-02) must still confirm each "reuse" target is the right record before inserting `race_candidates`. The DB contains FEC-committee junk rows and homonyms (many "GALLAGHER FOR …" committee records).
2. **Duplicate "Raul Ruiz" record (CA-25)** — two `Raul Ruiz` rows (both 0 stances) exist in `essentials.politicians`. Pre-existing condition, not introduced by Phase 148, but a USHC-02 dedup target for Phase 149.
3. **FL field is provisional by design** (pre-Aug-18 primary; full per-party qualified field, 155 new records) — Phase 151 seeds provisional, Phase 153 (USHC-07) prunes to final nominees post-primary.
4. **Top-up threshold (full-24 vs zeros-only)** correctly deferred to Phase 149 operator decision; ~134/142 incumbents are below federal-24 (73 at zero) — a substantial stance workstream.

## Human Verification

None blocking. The 148-VALIDATION.md flags one manual spot-check (per-district field correctness vs external ground truth) — partially exercised here (NY-10/NY-13/CA-40 confirmed from cited sources); full per-district external audit is a data-quality judgment outside automated scope and does not block phase closure.

## Gaps Summary

No gaps. All four success criteria verified, all six required checks PASS, all key links wired, data flows from live sources, no blocking anti-patterns, and the single deviation is a sound, documented scope-additive improvement.

---

_Verified: 2026-06-28_
_Verifier: Claude (gsd-verifier)_
