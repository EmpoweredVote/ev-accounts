---
phase: 88-stance-corrections-party-normalization
plan: "03"
subsystem: stance-data
tags: [tier2, corrections, ma-cluster, audit]
dependency_graph:
  requires: [88-01, 88-02]
  provides: [tier2-complete]
  affects: [inform.politician_answers, inform.politician_context]
tech_stack:
  added: []
  patterns: [act-on-mass-methodology, roll-call-vote-sourcing]
key_files:
  created:
    - supabase/migrations/20260603000009_124_tier2_borderline_corrections.sql
    - .planning/phases/88-stance-corrections-party-normalization/88-03-SUMMARY.md
  modified:
    - .planning/phases/88-stance-corrections-party-normalization/88-03-TIER2-DETERMINATIONS.md
decisions:
  - "MA value=3 cluster: Act on Mass methodology creates legitimate centrist patterns — not batch artifacts"
  - "OR progressive Democrats at value=1 dominance: confirmed via clerk.house.gov roll-call votes"
  - "MA Republicans at value=4 dominance: correct conservative direction, not inversion"
  - "Migration 124 is a no-op stub by design — zero Tier 2 corrections required"
metrics:
  duration: "Tasks 1-3 completed in prior sessions; Task 4 < 5 min"
  completed_date: "2026-06-03"
  tasks_completed: 4
  files_created: 2
requirements:
  - SACC-02
---

# Phase 88 Plan 03: Tier 2 Borderline Corrections Summary

**One-liner:** All 21 Tier 2 borderline politicians assessed and confirmed correct-as-is — MA cluster root cause is Act on Mass co-sponsorship methodology, not batch templating.

## Result

| Disposition | Count | Groups |
|-------------|-------|--------|
| correct-as-is | 21 | All 21 Tier 2 politicians |
| needs-correction | 0 | None |
| partial-correction | 0 | None |

**Zero DB corrections applied. Migration 124 is a documented no-op stub.**

## MA Cluster Finding

The 12-member MA value=3 cluster (Montigny, Robertson, Velis, Friedman, Cronin, Gregoire, Lovely, Saunders, Michlewitz, Mariano, Worrell, Shand) was investigated by pulling `inform.politician_context` reasoning text and sources for abortion, healthcare, and voting-rights at value=3.

**Root cause: CONFIRMED_CENTRIST — Act on Mass methodology.**

The Act on Mass co-sponsorship tracker (actonmass.org) assigns value=3 to MA Democrats who decline to co-sponsor progressive bills without taking actively restrictive stances. Every cluster row had:
- Populated sources arrays (no NULLs) — all pointing to actonmass.org plus some malegislature.gov bill links
- Specific per-politician reasoning (not verbatim duplicates)
- Individual legislative context (e.g., Friedman's S.761 sponsorship, Mariano's 2006 MA healthcare reform role, Saunders's H.4148 noncitizen voting bill)

This is not a batch artifact. It is a deliberate and documented research methodology. Kate Hogan (flagged independently, not in original cluster list) follows the identical methodology for the same reason.

## OR Progressives Finding

Val Hoyle (OR-04), Andrea Salinas (OR-06), and Suzanne Bonamici (OR-01) were sampled across 4 topics each. All confirmed via clerk.house.gov roll-call vote records (Women's Health Protection Act, Inflation Reduction Act, AHCA repeal, Ukraine Aid). Their value=1 dominance (94-96%) is accurate for US House Democrats with documented progressive voting records. The homelessness=2 variance on both Hoyle and Salinas adds credibility.

## MA Republicans Finding

Sullivan-Almeida, Durant, and Dooner (all MA Republicans with 90-93% value=4 dominance) were flagged by the Phase 87 audit's general 90%+ dominance filter — not by the cross-party direction filter (which correctly excluded R politicians with dominant value >= 4). Their value=4 dominance is expected for conservative MA Republicans representing Plymouth, Bristol, and Worcester districts. SSM exceptions (value=2 or value=3) for each add credibility consistent with MA Republicans who accept same-sex marriage given the state's history.

## Original Audit Hypothesis vs. Research Outcome

The Phase 87 audit flagged these politicians as "borderline" based on high dominance ratios. For every Tier 2 politician, the audit's concern was validated as non-actionable:
- MA cluster: the audit suspected batch artifact → research showed specific per-politician sourcing
- OR progressives: the audit suspected over-uniformity → research confirmed via congressional vote records
- MA Republicans: the audit flagged general 90%+ dominance → cross-party direction filter confirms these are expected alignments

No politician where the audit hypothesis turned out to generate a genuine correction.

## Migration 124

**File:** `supabase/migrations/20260603000009_124_tier2_borderline_corrections.sql`
**Content:** No-op stub with SQL comment block explaining the outcome.
**Applied:** SELECT 1 executed successfully — no data changes.

This is by design. The plan explicitly documented: "may be empty if all 21 turn out to be confirmed correct, in which case the migration step is skipped" — the stub satisfies the file-existence requirement and provides a numbered slot in the migration sequence.

## Notes for Future Audits

1. **Act on Mass methodology creates legitimate value=3 dominance for MA Democrats.** High value=3 dominance for MA House/Senate Democrats citing actonmass.org with specific bill non-co-sponsorships is a methodology fingerprint, not a batch artifact signal.

2. **OR/WA progressive US House Democrats legitimately cluster at value=1.** US House Democrats from OR/WA with consistent ACA/IRA/Ukraine voting records will naturally score value=1 on most topics. Consider a carveout in the 94-95% dominance threshold for this cohort.

3. **MA Republican legislators at value=4 are expected pattern.** The cross-party direction filter correctly excludes these; the general 90%+ dominance flag should have a similar carveout for expected partisan alignment when no cross-party mismatch is present.

4. **Emily Buss (Forward Party, UT) at value=2 is confirmed correct.** Forward Party politicians may appear in future research with centrist patterns — these are not artifacts.

## Key Artifact

`88-03-TIER2-DETERMINATIONS.md` — full per-politician evidence and rationale for all 21 Tier 2 cases, including the MA Cluster Investigation section with per-member labels, evidence basis by group, and notes for future audits.

## Deviations from Plan

None. The plan explicitly provided for the stub migration path ("corrections CSV may be empty if all 21 turn out to be confirmed correct"). Task 4 executed the documented stub path exactly as specified.

## Self-Check: PASSED

- `supabase/migrations/20260603000009_124_tier2_borderline_corrections.sql` — created, committed (0ef124a)
- `88-03-TIER2-DETERMINATIONS.md` — 21 named sections, 21 correct-as-is dispositions
- `data/stance-research/2026-06-03-tier2-corrections.csv` — header-only (no corrections)
- Migration 124 stub applied successfully
