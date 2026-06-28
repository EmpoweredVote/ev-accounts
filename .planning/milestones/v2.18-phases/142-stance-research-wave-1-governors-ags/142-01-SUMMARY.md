---
phase: 142-stance-research-wave-1-governors-ags
plan: 01
wave: 1
requirements: [SEXS-01]
status: complete
completed: 2026-06-21
---

# 142-01 SUMMARY — SEXS-01 Office-Type Evidence Guidance

## What was done

Inserted a new `### Office-Type Evidence Guidance (statewide executives)` subsection into
`.claude/agents/politician-stance-researcher.md`, immediately after the **Evidence Hierarchy**
section (as a sibling subsection) and before `## CRITICAL RULES`. This is the durable agent
definition, so the guidance applies to **every** future `politician-stance-researcher` dispatch
automatically — not only this milestone.

The subsection covers all **five** statewide-executive office types:
- **Governor** — bills signed/vetoed, executive orders, budget/line-item vetoes, emergency declarations; actions over slogans.
- **Attorney General** — lawsuits filed/joined, amicus briefs, multistate coalition actions; **coalition membership counts ONLY when the coalition has a published position directly on that topic** (ROADMAP SC#4).
- **Treasurer** (Phase 143) — investment/divestment decisions; not a "manages state funds" overview page.
- **Secretary of State** (Phase 143) — specific election-administration actions; not the generic "administers elections" role text.
- **Lieutenant Governor** (Phase 143) — honest-partial when no independent record; never mirror the same-state Governor.

Closes with the distinction sentence: a bill signing (Gov) ≠ an amicus brief (AG) ≠ an investment decision (Treasurer) — cite the act that actually happened.

## Verification

Plan verify grep passed: `Office-Type Evidence Guidance` count = 1, all five office-type
names present, plus `amicus|lawsuit`, `veto|signed|executive order`, `invest|divest`, and the
on-topic-coalition restriction anchor — printed `CONTENT_ANCHORS_PRESENT`.

Pre-existing Evidence Hierarchy / Stance Assessment / inversion-trap content left intact.

## Decisions

- Per RESEARCH, did NOT put the guidance in the stale `SKILL.md` (says "ONE agent at a time" / "44 topics"). The durable home is the agent def. SKILL.md cleanup deferred as optional (not a gate).

## Gate status

SEXS-01 satisfied. Wave 2 (142-02..142-09) is now clear to dispatch researchers.
