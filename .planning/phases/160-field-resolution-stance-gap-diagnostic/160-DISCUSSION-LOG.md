# Phase 160: Field Resolution + Stance-Gap Diagnostic - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-03
**Phase:** 160-field-resolution-stance-gap-diagnostic
**Areas discussed:** Research fan-out strategy, Filing-not-closed states, Nonstandard primary systems (RCV), Artifact packaging

---

## Research fan-out strategy

### Q1 — How should the 38-state field-resolution research be dispatched?

| Option | Description | Selected |
|--------|-------------|----------|
| 3-wave agents, phase order (Recommended) | Per-state agents, max 3 concurrent, ordered by seeding-phase grouping (161 first → 165 last); validate first wave before continuing | ✓ |
| 3-concurrent, flat order | Same cap, no phase-order grouping | |
| Orchestrator-inline only | Serial, orchestrator resolves each state itself | |

**User's choice:** 3-wave agents, phase order.

### Q2 — How should walled sources be handled during agent research?

| Option | Description | Selected |
|--------|-------------|----------|
| Agents + Playwright residue (Recommended) | Agents use unwalled routes only, flag unresolvable districts; orchestrator Playwright-sweeps the residue per wave; no field row without a fetched source URL | ✓ |
| Orchestrator pre-fetches walled sources | Playwright-fetch walled pages first, agents work from saved copies | |
| You decide | Leave mechanics to researcher/planner | |

**User's choice:** Agents + Playwright residue.

---

## Filing-not-closed states

| Option | Description | Selected |
|--------|-------------|----------|
| Declared-so-far + deadline tag (Recommended) | Capture declared field tagged `filing-open (deadline)`; owning seeding phase re-pulls final list if deadline passed at execution, else seeds PROVISIONAL; Phase 167 reconciles late filers | ✓ |
| Defer field to seeding phase | Diagnostic records only deadline + incumbent map for filing-open states | |
| Date-gate those states' seeding | Hold seeding until deadline passes | |

**User's choice:** Recommended (answered as "1. recommended" after AFK resume).

---

## Nonstandard primary systems (RCV)

Presented as: keep two-bucket decided/late-primary classification + per-state `ballot_system` note; top-two/top-four "general field" = whoever advances, party-blind.

**User's choice (free text):** "For RCV options, let's go pretty far down the line, if we can. My feeling is that Empowered Vote MOST helps communities that Rank their politician, as it allows them to see many candidates quickly with context. So if there is an area to over-indulge in our search, it's making sure we are very thorough to support RCV races."

**Captured as:** D-04 (ballot_system taxonomy) + D-04a (RCV over-indulgence principle — exhaustive field capture for AK/ME, `rcv` flag in field table, seeding phases prioritize max coverage depth for RCV candidates; honest-skip evidence bar unchanged but search effort goes further before pinning a skip).

---

## Artifact packaging

| Option | Description | Selected |
|--------|-------------|----------|
| Master CSVs + seeding_phase column (Recommended) | One canonical 160-field-table.csv + 160-incumbent-map.csv mirroring 154, with a seeding_phase column (161–165) so each downstream phase filters its slice | ✓ |
| Per-seeding-phase splits | Five separate artifact sets | (not formally presented — user endorsed the recommendation) |

**User's choice:** "That sounds good; I trust your recommendation."

---

## Claude's Discretion

- Field-resolution source choice per state (official results preferred over aggregators).
- Research-agent prompt template + per-wave artifact merge mechanics.
- Exact `160-verify.sql` assertion set (clone 154/148 style).
- Phase-167 primary-date-cluster output format.

## Deferred Ideas

- Partial-incumbent stance top-up (reported, not actioned — future data-quality pass).
- Challenger FEC `finance_summary` (out of scope for v2.22).
- RCV-aware product/UI surfaces (D-04a is data-depth only this milestone).

## Session notes

- User went AFK twice mid-discussion; Area-1 continue-check and the final "ready for context" gate were resolved by best judgment per checkpoint/resume protocol. Areas 2–4 were answered by the user in a single message on return. All four substantive areas received explicit user decisions.
