---
phase: 117
slug: candidate-stub-resolution-data-import
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-14
---

# Phase 117 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `117-RESEARCH.md` §Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest (ev-accounts/backend) + SQL/shell verification scripts |
| **Config file** | `ev-accounts/backend/vitest.config.ts` (Wave 0 verify exists) |
| **Quick run command** | `cd ev-accounts/backend && npm run typecheck` |
| **Full suite command** | `cd ev-accounts/backend && npm test` |
| **Estimated runtime** | ~60 seconds (typecheck) / ~3 min (full test) |

---

## Sampling Rate

- **After every task commit:** Run `cd ev-accounts/backend && npm run typecheck`
- **After every plan wave:** Run `cd ev-accounts/backend && npm test` + `npx tsx scripts/audit-112-candidates.ts --dry-run` (compare stub counts pre/post)
- **Before `/gsd-verify-work`:** All SQL verifications green + live address-lookup smoke test + Compass picker check
- **Max feedback latency:** ~60 seconds (typecheck) between task commits

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists |
|--------|----------|-----------|-------------------|-------------|
| CAND-01 | Feasibility doc exists and is committed | manual-only | human review of `117-FEASIBILITY.md` | N/A (doc deliverable) |
| CAND-02 | Politician records exist for each stub in scope-down list | integration (SQL) | `psql $DATABASE_URL -c "SELECT COUNT(*) FROM essentials.politicians WHERE source='phase_117_monroe_stub_import'"` | ❌ W0 (import script) |
| CAND-02 | `race_candidates.politician_id` populated for imported candidates | integration (SQL) | `npx tsx scripts/audit-112-candidates.ts --dry-run` (compare stub count pre/post) | ✅ script exists |
| CAND-03 | Each import has photo_custom_url or fallback, bio_text non-empty, matching office row | integration (SQL) | `psql $DATABASE_URL -f scripts/verify-117-imports.sql` | ❌ W0 |
| CAND-04 | Essentials profile page loads for each slug without 500 | e2e smoke | `scripts/verify-117-profile-loads.sh` (curl each slug) | ❌ W0 |
| CAND-05 | Imported candidates appear in Compass picker | integration (SQL) | `psql -c "SELECT full_name FROM essentials.politicians WHERE source='phase_117_monroe_stub_import' AND id IN (SELECT DISTINCT politician_id FROM inform.politician_answers)"` | ❌ W0 + **CAND-05 fix required** |
| is_candidate leak closed | Address lookup for Monroe County does NOT return is_candidate=true rows | integration (API) | `scripts/verify-117-leak-closed.sh` (curl resolver, assert no is_candidate=true) | ❌ W0 |
| Backfill correctness | After migration 068, every politician linked via race_candidates.is_incumbent=false has is_candidate=true | integration (SQL) | `psql -c "SELECT COUNT(*) FROM essentials.politicians p WHERE is_candidate=false AND EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.politician_id=p.id AND rc.is_incumbent=false)"` (must be 0) | ❌ W0 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `ev-accounts/backend/scripts/verify-117-imports.sql` — idempotent SQL verification (row counts, source tag, photo+bio+office completeness, is_candidate flag)
- [ ] `ev-accounts/backend/scripts/verify-117-leak-closed.sh` — curl address resolver, assert no `is_candidate=true` rows returned
- [ ] `ev-accounts/backend/scripts/verify-117-profile-loads.sh` — curl essentials profile page for each imported slug, assert 200
- [ ] **CAND-05 fix decision:** Resolve planner's-call picker fix (a) LEFT JOIN (b) sentinel answers (c) descope — MUST be locked before implementation begins
- [ ] Verify `vitest.config.ts` present in `ev-accounts/backend` (assumption A-VITEST in research)
- [ ] Manual QA URL checklist (one URL per imported slug) for pre–May 1 human smoke test

*No new Vitest test files required — all verification is SQL + shell, feasible given phase timeline and data-import nature.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Feasibility doc go/no-go | CAND-01 | D-03: planner's-call, not a numeric threshold | Human reviews `117-FEASIBILITY.md` with product owner on April 25; decides scope-down or proceed-full |
| Bio accuracy (single-source, no hallucination) | CAND-03 / D-07 | Semantic correctness cannot be grep-checked | Human reviews each imported bio against its `bio_source_url` before commit |
| Photo visual sanity (right person, right office) | CAND-03 | Image identity requires human perception | Human spot-checks every imported photo against source before Supabase upload |
| Pre–May 1 live smoke test | CAND-04 / CAND-05 | Production readiness confirmation | Human loads each imported candidate's Essentials profile + Compass picker on essentials.empowered.vote |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (3 shell/SQL scripts + CAND-05 fix decision)
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s (typecheck)
- [ ] `nyquist_compliant: true` set in frontmatter (after Wave 0 + planner approval)

**Approval:** pending
