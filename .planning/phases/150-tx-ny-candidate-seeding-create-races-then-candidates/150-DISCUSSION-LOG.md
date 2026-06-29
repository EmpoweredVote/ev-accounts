# Phase 150: TX + NY Candidate Seeding (create races, then candidates) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-29
**Phase:** 150-tx-ny-candidate-seeding-create-races-then-candidates
**Areas discussed:** NY incumbent top-up, Minor-party candidates, TX redistricted reuse, Wave structure / split

---

## NY incumbent stance top-up

| Option | Description | Selected |
|--------|-------------|----------|
| Zero-only | Consistent w/ 149 D-01. TX 37 zero → full-24; NY 25 partial left as-is (already surface w/ 4–21 sourced stances); all 81 new challengers → full-24. | ✓ |
| Top NY partials to full-24 | Bring all 25 NY partial incumbents to full-24 now; large added workstream, breaks CA-pattern consistency. | |
| Threshold top-up | Top up only NY incumbents below a floor (e.g. <12 topics); middle ground. | |

**User's choice:** Zero-only (Recommended)
**Notes:** Stance gap is asymmetric — TX all-zero (gets full-24), NY all-partial (left untouched, already has real content). Partial top-up deferred to a later sweep, matching CA's 7 partials.

---

## Minor-party candidates

| Option | Description | Selected |
|--------|-------------|----------|
| Seed all, honest-skip stances | Seed every listed candidate (party-agnostic card); thin minor candidates → documented whole-record honest-skip pinned in verify gate. | ✓ |
| Major-party only | Seed only D + R nominees, drop minor/third-line; misrepresents the actual ballot. | |

**User's choice:** Seed all, honest-skip stances (Recommended)
**Notes:** NY-13 (Working Families / Bob Cohen), NY-21 (Conservative / Robert Smullen) are genuine third candidates, not cross-endorsements. Reflect the true ballot field; honest-skip where sources are thin.

---

## TX redistricted reuse

| Option | Description | Selected |
|--------|-------------|----------|
| Mandatory pre-insert live-DB check | Query live DB by name+identity before any insert; reuse existing pid. Flag Casar (TX-35→TX-37), Allred (TX-33) explicitly; zero duplicate full_name per state in gate. | ✓ |
| Standard dedup only | Rely on D-02 rule without naming specific TX cross-district targets; riskier. | |

**User's choice:** Mandatory pre-insert live-DB check (Recommended)
**Notes:** Cross-district redistricting intensifies the CA Solis/Sánchez/Ruiz failure vector — Casar is the active TX-37 D while being the sitting TX-35 incumbent; Allred likely has a 2024 Senate record. 148 new_records_needed used naive matching, so each reuse target must be confirmed live.

---

## Wave structure / split

| Option | Description | Selected |
|--------|-------------|----------|
| One phase, planner waves | Single phase; planner splits into waves (authoring → records+wiring → headshots+stances), TX/NY parallel. Planner may still recommend a split. | ✓ |
| Pre-split TX vs NY now | Two explicit sub-phases up front; more planning overhead. | |

**User's choice:** One phase, planner waves (Recommended)
**Notes:** Matches 149 precedent. TX/NY are independent within one phase; planner retains discretion to recommend a TX-vs-NY split if context budget is exceeded.

---

## Claude's Discretion

- Wave/batch structure; TX/NY parallel tracks; headshots/stances interleave vs separate waves.
- Recommend a TX-vs-NY split if context budget exceeded.
- Push-script mechanics (`_push_uuid.ts`); reuse of the 149 malformed-CSV repair pipeline.
- Election/race authoring SQL mechanics (migration vs script); mirror "CA 2026 Statewide General" shape.

## Deferred Ideas

- Top-up of the 25 NY partial incumbents to full federal-24 — deferred to a later sweep.
- FL seeding (Phase 151), 144-completion coordinate gate (Phase 152), FL provisional prune (Phase 153).
