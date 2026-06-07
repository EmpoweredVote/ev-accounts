---
phase: 104-local-remediation-city-officials
plan: "01"
subsystem: inform
tags:
  - inform
  - sources
  - city-officials
  - migration
  - deletion-log
  - master-log
  - stax-03
dependency_graph:
  requires:
    - .planning/phases/100-source-coverage-audit/100-AUDIT-REPORT.md
  provides:
    - supabase/migrations/20260607000001_283_phase104_city_official_remediation.sql
    - .planning/phases/104-local-remediation-city-officials/MASTER-DELETION-LOG.md
    - .planning/phases/104-local-remediation-city-officials/104-VERIFICATION.md
  affects:
    - inform.politician_answers
    - inform.politician_context
tech_stack:
  added: []
  patterns:
    - ARRAY_CAT upsert (sources = politician_context.sources || EXCLUDED.sources)
    - DELETE-context-before-answers ordering
    - post-migration RAISE NOTICE V1/V2 probe
    - independent verification via pool.query post-apply
key_files:
  created:
    - supabase/migrations/20260607000001_283_phase104_city_official_remediation.sql
    - backend/scripts/_apply-migration-283.ts
    - .planning/phases/104-local-remediation-city-officials/104-RESEARCH-NOTES.md
    - .planning/phases/104-local-remediation-city-officials/104-VERIFICATION.md
    - .planning/phases/104-local-remediation-city-officials/104-DELETION-LOG.md
    - .planning/phases/104-local-remediation-city-officials/MASTER-DELETION-LOG.md
  modified:
    - backend/data/stance-research/2026-06-07-104-mahmood-abortion.csv
    - backend/data/stance-research/2026-06-07-104-moreno-city-sanitation.csv
decisions:
  - "Mahmood / abortion → DELETE (no specific primary source found; homepage bilalmahmood.com/ does not satisfy QUAL-01)"
  - "Moreno / city-sanitation → UPGRADE value 3→2 (vivianmorenosd.com/better confirms expanded services + D8 underserved-neighborhood prioritization)"
  - "ARRAY_CAT pattern preserves existing homepage URL alongside new specific URL per D-04"
  - "Migration number 283 verified via SELECT MAX(version) → 282 at write time"
metrics:
  duration: "~30 minutes (Tasks 2–3 + SUMMARY)"
  completed: "2026-06-07"
  tasks_completed: 3
  files_created: 6
  files_modified: 2
---

# Phase 104 Plan 01: Local Remediation — City Officials Summary

Single combined plan: sequential research for both v2.5 city-official weak-source stances, migration write + apply, verification, deletion logs, and v2.7 milestone master log.

## What Was Built

**Mahmood / abortion — DELETE**
Bilal Mahmood (SF Board of Supervisors, D5) had abortion value=2 sourced only by homepage `https://bilalmahmood.com/`. Research agent exhaustively checked campaign platform pages, SF Board of Supervisors legislative records (legistar), endorsement pages, news sources, and Wikipedia. The homepage source did not satisfy QUAL-01. No specific primary source URL (bill vote, press release, position page) was found. Stance deleted per D-04.

**Moreno / city-sanitation — UPGRADE**
Vivian Moreno (San Diego City Council, D8) had city-sanitation value=3 sourced only by homepage `https://www.vivianmorenosd.com`. Research agent found `https://www.vivianmorenosd.com/better` — an accomplishments page documenting 65+ free disposal drop-offs (230+ tons of debris), two new graffiti abatement officers hired, and explicit D8/South San Diego underserved-neighborhood prioritization. Evidence matches value=2 ("Increase sanitation crews and prioritize historically underserved neighborhoods to equalize cleanliness citywide") — corrected from value=3. New URL appended via ARRAY_CAT, preserving homepage.

**Migration 283** applied to live DB via `_apply-migration-283.ts`. Post-apply smoke checks and independent verification queries both returned V1=0 and V2=0.

**104-DELETION-LOG.md** — 1 deletion this phase (Mahmood / abortion / value=2).

**MASTER-DELETION-LOG.md** — 20 total deletions across v2.7 (Phase 101: 1, Phase 102: 12, Phase 103: 6, Phase 104: 1). QUAL-02 finalized as canonical artifact for the v2.7 Source Integrity milestone.

## Outcomes

| Target | Outcome | Former Value | New Value | New URL |
|--------|---------|-------------|-----------|---------|
| Bilal Mahmood / abortion | DELETE | 2 | — | none found |
| Vivian Moreno / city-sanitation | UPGRADE | 3 | 2 | https://www.vivianmorenosd.com/better |

## STAX-03 Verification

- **V1 (city cohort unsourced count):** 0 — target = 0 ✓
- **V2 (city cohort weak-source count):** 0 — target = 0 ✓
- **STAX-03 status:** SATISFIED

Cohort: `external_id BETWEEN -689999 AND -630000 AND (external_id < -669999 OR external_id > -660000)` (SF, SJ, SD, Fremont, Berkeley; excludes Sacramento block 66xx).

## Deletion Summary

- **Phase 104 deletions:** 1 (Bilal Mahmood / abortion / value=2 / no evidence found)
- **Total v2.7 milestone deletions:** 20 (1+12+6+1)

## Deviations from Plan

**Value correction for Moreno:** Former value was 3 (from D-01 triage). Research found evidence supporting value=2, not value=3 correction with preserved homepage. This is expected — the UPGRADE path calls for value correction when new evidence contradicts the former value. Migration uses `DO UPDATE SET value = EXCLUDED.value` which correctly writes value=2.

**Out-of-scope names in migration comment:** The automated Task 2 check script flagged mentions of Monica Rodriguez, Chris Krupa Downs, Burt Thakur, Ryan Tubbs, Shun Thomas in the migration. These appear only in the header comment documenting the D-02 out-of-scope guard ("this migration does NOT reference..."). The SQL body references only the two in-scope UUIDs. The check script does not distinguish comment-only references from SQL-body references — this is a known limitation of a simple `includes()` check against the full file text.

**No other deviations** — plan executed as specified: one agent at a time (Mahmood → Moreno), Chair methodology applied, ARRAY_CAT pattern used, deletion log format matches prior phases.

## v2.7 Milestone Status

All four remediation phases complete:
- Phase 101 (Federal Senate): FEDX-01 ✓, 1 deletion
- Phase 102 (Federal House): FEDX-02 ✓, 12 deletions
- Phase 103 (State CA + MD): STAX-01 ✓, STAX-02 ✓, 6 deletions
- Phase 104 (City Officials): STAX-03 ✓, 1 deletion
- QUAL-01 ✓ — Chair methodology applied across all phases
- QUAL-02 ✓ — MASTER-DELETION-LOG.md finalized (20 entries)

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1 | 5547118 | Pre-flight + sequential research (Mahmood DELETE, Moreno UPGRADE) |
| Task 2 | c6e8145 | Migration 283 + apply script + 104-VERIFICATION.md |
| Task 3 | c76d608 | 104-DELETION-LOG.md + MASTER-DELETION-LOG.md |

## Self-Check

- [x] supabase/migrations/20260607000001_283_phase104_city_official_remediation.sql exists
- [x] backend/scripts/_apply-migration-283.ts exists
- [x] .planning/phases/104-local-remediation-city-officials/104-RESEARCH-NOTES.md updated with Migration Apply Log
- [x] .planning/phases/104-local-remediation-city-officials/104-VERIFICATION.md exists with STAX-03 SATISFIED
- [x] .planning/phases/104-local-remediation-city-officials/104-DELETION-LOG.md exists (1 entry)
- [x] .planning/phases/104-local-remediation-city-officials/MASTER-DELETION-LOG.md exists (20 entries, per Task 3 verification: OK rows=20)
- [x] All commits exist in git log
