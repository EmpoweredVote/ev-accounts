# Phase 101: Federal Senate Remediation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-05
**Phase:** 101-federal-senate-remediation
**Areas discussed:** Weak-source scope, Research approach, Plan structure, Deletion threshold

---

## Weak-Source Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Query first, scope dynamically | Planner runs a weak-source query filtered to NATIONAL_UPPER senators, produces senator-specific count, then scopes the work. | ✓ |
| Fix all senator weak sources regardless | Phase 101 = fix every homepage-only URL among senators, however many there are. | |
| Defer weak sources to a later pass | Phase 101 only fixes the 1 unsourced Deb Fischer stance. Weak-source senator rows stay as-is. | |

**User's choice:** Query first, scope dynamically.
**Notes:** None.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Upgrade to specific URL or delete | For each homepage-only URL: find the specific bill/vote/press release. If a real URL can't be found, delete. No partial credit. | ✓ |
| Upgrade to specific URL; keep even if can't upgrade | Try to find real URLs. If homepage URL is the best available, keep it (passes locked sourced definition). | |
| Re-research from scratch using research-stances skill | Treat weak-sourced stances like unsourced ones — re-run full research, producing new CSV with new values and URLs. | |

**User's choice:** Upgrade to specific URL or delete.

---

## Research Approach

| Option | Description | Selected |
|--------|-------------|----------|
| Targeted source-finding | Query unsourced/weak-sourced stances → pass each to researcher agent → agent finds specific URL for existing value → UPDATE or DELETE. | |
| Full re-research via research-stances skill | Re-run research-stances for each affected senator. May change stance values as well as sources. | ✓ |
| Manual (no agent) | Human looks up each senator stance manually and provides URLs. | |

**User's choice:** Full re-research via research-stances skill.
**Notes:** User chose full re-research over targeted source-finding, accepting that stance values may be corrected where new sourced evidence differs from existing values.

---

| Option | Description | Selected |
|--------|-------------|----------|
| New sourced value wins | If re-research finds a real source supporting a different value, update the value. | ✓ |
| Keep existing value, add/upgrade source only | Re-research finds URLs for existing value only; if only contradicting sources found, delete. Never change value. | |

**User's choice:** New sourced value wins.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Only senators with unsourced or weak-sourced stances | Re-run research-stances only for senators identified in the weak-source query + Deb Fischer. | ✓ |
| All 100 senators | Full re-verification pass. Every senator, every topic. | |

**User's choice:** Only senators with unsourced or weak-sourced stances.

---

## Plan Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Plan 01 = triage query, Plan 02+ = research + migration | Plan 01: senator weak-source query + target list. Plan 02+: research-stances batches + migration + deletion log. | ✓ |
| Single plan | One plan: triage + research + migration. Makes sense only if weak-source senator count is confirmed small. | |
| 3+ plans (full batch split) | Plan 01 = triage, Plan 02 = first batch, Plan 03 = second batch, Plan 04 = migration + log. | |

**User's choice:** Plan 01 = triage query, Plan 02+ = research + migration.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Planner decides based on count | ≤10 senators: 1 plan. 11–25: 2 plans (A-M, N-Z). 26+: 3 plans. Planner writes correct number of steps after seeing triage output. | ✓ |
| Always 2 research plans (A-M / N-Z) | Mirror the Phase 74 senator research pattern regardless of count. | |
| One plan per senator | Max granularity, max parallelism. Probably overkill given likely small count. | |

**User's choice:** Planner decides based on count (dynamic batching).

---

## Deletion Threshold

| Option | Description | Selected |
|--------|-------------|----------|
| Delete if no real URL found, regardless of value | Consistent with Chair methodology and no-party-inference rule. Even an 'obvious' stance must have a real source. | ✓ |
| Delete only if value seems directionally wrong | Keep stances consistent with senator's party/record even without a specific URL. Conflicts with no-party-inference rule. | |
| Keep with homepage URL as placeholder | Upgrade to official website as 'best available' source. Doesn't satisfy QUAL-01. | |

**User's choice:** Delete if no real URL found, regardless of value.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Single research pass per topic | Agent does one web research pass per topic per senator. If no specific bill/statement/vote/press release found, flag for deletion. | ✓ |
| Two-pass: agent + human review of flagged stances | Agent flags 'no evidence found'. Human manually verifies before final deletion decision. | |
| Researcher decides inline | Researcher agent makes the delete/keep/update call inline. No separate human review. | |

**User's choice:** Single research pass per topic.

---

## Claude's Discretion

None — all decision areas had clear user choices.

## Deferred Ideas

None — discussion stayed within phase scope.
