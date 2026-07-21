# Phase 162: IN + MD + MN + MO Candidate Seeding - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-04
**Phase:** 162-in-md-mn-mo-candidate-seeding-create-elections-races-then-ca
**Areas discussed:** MO redistricting handling, IN-9 flag bug fix, State ordering / urgency, MD reuse + open window

> **Resolution note:** All four gray areas were framed with a concrete "My read" recommendation and presented for selection. The operator was away at decision time (no response within the question window), so each area was locked to its recommended default. Every default is grounded in the Phase-161 precedent (same milestone, same pipeline) and the Phase-160 field-resolution findings, so no default is speculative. Any area can be re-opened at plan time.

---

## MO redistricting handling

| Option | Description | Selected |
|--------|-------------|----------|
| Mirror TN D-01 exactly | Audit old-vs-new map up front, seed new-map-correct data, withhold severe MO districts (likely MO-5 + adjacent), un-gate in 164.1 | ✓ (default) |
| Treat MO as ordinary | Ignore the redistricting and surface all MO districts on old polygons | |

**User's choice:** Locked to default (mirror TN D-01) — operator away.
**Notes:** Phase 160 confirmed the 2025 MO map is in effect for 2026 (Supreme Court upheld 4-3, Mar-24). MO is already in the committed 164.1 dual-map set, so the withhold→un-gate path already has a home. "Treat MO as ordinary" would serve actively-wrong address lookups for the redrawn KC-area districts — rejected on the same reasoning that produced TN D-01 in Phase 161.

---

## IN-9 flag bug fix

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated first step, flag-only fix | Correct is_incumbent on the 5 existing IN-9 primary rows (Houchin→true, 4 losers→false), verified by re-query, before any IN general seeding | ✓ (default) |
| Delete/re-seed the stale primary race | Remove the primary rows and re-create | |

**User's choice:** Locked to default (dedicated flag-only fix) — operator away.
**Notes:** The primary race is valid historical data; only the flags are wrong. Flag correction is the minimal, safe fix and satisfies the zero-duplicate-incumbent invariant. Delete/re-seed would discard valid primary data unnecessarily.

---

## State ordering / urgency

| Option | Description | Selected |
|--------|-------------|----------|
| MO → MN → IN/MD | MO first (earliest primary Aug-4 + redistricting audit front-loaded), MN second (Aug-11), decided IN+MD last | ✓ (default) |
| Decided-first (IN/MD → MN → MO) | Clear the small decided fields first | |

**User's choice:** Locked to default (MO first) — operator away.
**Notes:** Matches Phase-161 D-02's "earliest civic moment first" logic (AZ ran first there for its Jul-21 primary). MO's Aug-4 primary + Jul-27 petition deadline is the tightest window in this slice, and the MO correspondence audit must front-load regardless. Push per state as each completes (159/161 pattern).

---

## MD reuse + open window

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse existing races, seed now, Phase 167 catches late filers | Reuse the 8 existing_race_id races (MA pattern); seed nominees + declared minor-party now; re-pull after Aug-3; 167 reconciles late independents | ✓ (default) |
| Defer MD entirely until Aug-3 window closes | Wait for the filing window to close before seeding | |

**User's choice:** Locked to default (reuse + seed now) — operator away.
**Notes:** MD primary is decided (Jun-23); nominees are final. The open unaffiliated/minor window (Aug-3) is handled exactly as MA's Aug-25 window in Phase 161 — seed declared-so-far, let Phase 167 catch late filers. Deferring MD would leave voters without their known field at the civic moment for no benefit.

---

## Claude's Discretion

- Exact plan count/splitting (incl. whether MO/MN provisional stance slices split for checkpoint safety).
- Gate assertion set (clone prior seeding-phase verify SQL).
- The severe-district withholding mechanism (match 161's D-01b choice).
- The MO correspondence audit's severity rubric (clone TN's from 161).
- Per-state elections/races migration authoring details.
- Placement of the IN-9 flag fix in the plan graph.

## Deferred Ideas

- Cross-state polygon refresh / dual-map design → Phase 164.1 (un-gates withheld MO districts).
- Partial-incumbent stance top-up → out of v2.22 scope (zero-tier incumbents remain in-scope).
- Challenger finance_summary → out of scope per REQUIREMENTS.md.
- MD late-filing independents (Aug-3) / MO late independents (Jul-27) → Phase 167 reconciliation.
- v2.21 tail (159-05/06, PA independents, FL Phase 153) → calendar-gated, separate.
