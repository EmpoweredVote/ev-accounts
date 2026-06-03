---
phase: 88
plan: "04"
subsystem: inform
tags: [stance-corrections, ukraine-support, republican-audit, migration]
dependency_graph:
  requires: [88-03]
  provides: [ukraine-support-republican-corrections]
  affects: [inform.politician_answers, inform.politician_context]
tech_stack:
  added: []
  patterns: [upsert-with-subquery-topic-id, begin-commit-transaction]
key_files:
  created:
    - supabase/migrations/20260603000010_125_ukraine_support_republican_corrections.sql
    - .planning/phases/88-stance-corrections-party-normalization/88-04-SUMMARY.md
  modified: []
decisions:
  - "Value-change criterion: actual roll call vote record (2024 supplemental) trumps prior rhetorical posture"
  - "Brian W. Jones excluded from migration: CA state legislator has no federal vote record; original value=2 was party inference, flagged as unverified but not correctable without evidence"
  - "Barrasso and Blackburn shift is notable: both had strong prior anti-Russia rhetoric but both voted NAY on the $95B supplemental, aligning with the 2024 MAGA-aligned Republican shift on Ukraine"
metrics:
  duration: "~10 minutes"
  completed: "2026-06-03"
  task_count: 1
  file_count: 1
---

# Phase 88 Plan 04: Ukraine-Support Republican Corrections Summary

**One-liner:** Ukraine-support corrections for 4 Republicans (all 2→4) based on 2024 roll call votes, migration 125 applied.

---

## Disposition Counts

| Disposition | Count | Politicians |
|-------------|-------|-------------|
| verified-correct | 20 | Sullivan, Fischer, Risch, Moran, Cornyn, Curtis, Hoeven, Ernst, Murkowski, Rounds, McConnell, Ricketts, Wicker, Capito, Daines, S.M. Collins, Tillis, Scott, Young, Cotton |
| value-changed | 4 | Barrasso, Blackburn, Obernolte, Mike Collins |
| insufficient-evidence | 1 | Brian W. Jones |
| **Total** | **25** | |

---

## Value Distribution After Corrections

All 4 value-changed politicians shifted from value=2 (continue current aid levels) to value=4 (reduce aid, focus on domestic priorities):

| Politician | UUID | Old Value | New Value | Basis |
|------------|------|-----------|-----------|-------|
| John Barrasso | e4b27d5e | 2 | 4 | NAY on Senate vote 118-2 #154 (Apr 23 2024, 79-18) |
| Marsha Blackburn | 808ab926 | 2 | 4 | NAY on Senate vote 118-2 #154 (Apr 23 2024, one of 18 NAY) |
| Jay Obernolte | 18db5d61 | 2 | 4 | NAY on House roll call 164 H.R. 8035 (Apr 2024, 311-112) |
| Mike Collins | ce8d48a3 | 2 | 4 | NAY on House roll call 164; AP News confirms anti-Ukraine-aid posture; original source was wrong politician page |

No politicians were corrected to value=5 (end all aid). All four are "reduce/redirect" rather than "oppose entirely."

---

## Notable Findings

**Hawkish-rhetoric vs. actual vote discrepancy:** Both Barrasso and Blackburn had pre-existing context that cited anti-Russia rhetoric (Barrasso visited Kyiv in May 2022, Blackburn's national security page described hawkish posture against Russia). However, the April 2024 Senate roll call shows both voted NAY on the largest Ukraine aid package of the 118th Congress. This 2022→2024 shift reflects the broader MAGA-aligned Republican turn on Ukraine support.

**Obernolte intra-cycle flip:** Obernolte voted YEA on the 2022 Ukraine Lend-Lease Act (House roll 103) but NAY on the April 2024 $60B Ukraine supplemental (House roll 164). This is a documented position shift, not a data error.

**Mike Collins source error caught:** The original CSV had `ontheissues.org/Senate/Ashley_Hinson.htm` as the source for Mike Collins — a completely different politician's page. The correction migration includes the accurate sources (House roll call 164, Wikipedia, AP News) and documents the error.

**Brian W. Jones — SACC-02 violation in original data:** The original context for Jones explicitly states "he likely supports continued aid" — a prohibited party-inference formulation under SACC-02. The value was not changed because no direct evidence was found to assign a corrected value. This entry remains flagged as unverified inference in the DB.

**High verified-correct rate:** 80% of politicians in this batch (20/25) were already correctly scored at value=2. The 2024 roll call vote was the primary verification instrument for Senate Republicans; the April 2024 Senate vote 118-2 #154 (79-18) was definitive for nearly all senators in the batch.

---

## Recommendation for Future Audits

1. **Use roll call votes as primary source, not rhetorical statements.** For any federal legislator topic, start with clerk.house.gov or senate.gov roll call records before reading press releases or ontheissues pages. Roll calls are unambiguous; rhetoric can diverge from votes (as Barrasso/Blackburn demonstrate).

2. **The 2024 Ukraine supplemental votes are the tier-1 source for ukraine-support.** Senate vote 118-2 #154 (April 23 2024, 79-18) and House roll call 164 H.R. 8035 (April 20 2024, 311-112) distinguish supporters from reducers cleanly.

3. **Flag entries where original reasoning contains "likely", "suggests", "generally"** — these indicate party-inference violations (SACC-02). Brian W. Jones is the one remaining flagged entry in this batch.

4. **State legislators need state-level evidence.** CA Assembly and Senate members (like Jones) have no federal vote records; ukraine-support requires explicit public statements. Consider skipping this topic for purely state-level officials unless a direct public statement exists.

---

## Deviations from Plan

None. Plan executed exactly as specified. The CSV was located in the worktree path (`.claude/worktrees/agent-aa434810ddde8237d/data/stance-research/`) rather than the root `data/stance-research/` path referenced in the task — read from worktree location without issue.

---

## Self-Check: PASSED

- Migration file created: `supabase/migrations/20260603000010_125_ukraine_support_republican_corrections.sql` — FOUND
- Migration applied: DB verification confirmed all 4 politicians have value=4 and has-sources — PASSED
- Commit 603a844 exists: verified via git log — FOUND
- Brian W. Jones absent from migration: confirmed (only 4 UUIDs in SQL) — PASSED
- All 4 context rows have sources (1-3 URLs each): confirmed by verification query — PASSED
