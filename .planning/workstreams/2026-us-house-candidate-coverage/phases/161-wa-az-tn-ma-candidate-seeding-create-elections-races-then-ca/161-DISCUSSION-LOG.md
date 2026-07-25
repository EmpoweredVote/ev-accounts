# Phase 161: WA + AZ + TN + MA Candidate Seeding - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-03
**Phase:** 161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca
**Areas discussed:** TN redistricted map handling, State ordering & AZ urgency, Scaling the ~183-record pipeline, Fringe-candidate search depth

---

## TN redistricted map handling

### Q1: How should Phase 161 handle TN's races given the DB polygons still reflect the old (pre-May-2026) map?

| Option | Description | Selected |
|--------|-------------|----------|
| Seed on existing rows, defer boundary work | Wire TN races to existing CD rows; border-shifted addresses may see a neighboring CD's race until polygons refresh; boundary refresh is a coherent cross-state effort (TN/MO/AL/LA/UT) that must not break the reps feed | ✓ |
| In-phase TN polygon refresh | Import new TN shapefile inside 161; elections correct immediately but reps feed goes wrong for shifted addresses | |
| Dual-map design first | Pause TN until a dual-map model exists; correct both feeds but its own design phase, leaves TN dark | |

### Q2: Should Phase 161 include a TN old-vs-new district correspondence audit before wiring races?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — audit + severity artifact | One research task compares old/new TN maps per district, scores shift severity, ships as a 161 artifact | ✓ |
| Yes, and gate severe districts | Same audit + severe districts seeded without surfacing | (folded in via Q3) |
| No audit — wire all 9, note the caveat | Blanket approximation, caveat in docs only | |

### Q3 (after operator pushback): Where should the TN boundary problem sit in the sequence?

**Operator pushback (verbatim):** "wait. if we defer it, aren't you just getting bad data? Shouldn't this come first?"

Claude's clarification: seeded candidate/race/stance data is keyed to the NEW map and stays correct (self-corrects on polygon refresh, zero rework); only the address→race lookup is stale; new-polygons-first would falsify the reps feed instead (shared polygon; incumbents represent OLD districts until Jan 2027); dual-map needs backend code (violates the pure-data milestone) and is forced anyway by UT in Phase 165.

| Option | Description | Selected |
|--------|-------------|----------|
| Audit first, gate severe, dual-map before 165 | 161 opens with the TN audit; severe districts seeded but NOT surfaced; dual-map/polygon-refresh committed as its own phase before Phase 165 and well before Nov-3 | ✓ (confirmed on resume after AFK timeout) |
| Dual-map phase before 161 | Insert the boundary phase ahead; blocks the anchor phase incl. AZ's Jul-21 window | |
| Polygons-first for TN only | Import new TN shapes now; knowingly falsifies "who represents me today" for shifted users | |

**User's choice:** Audit first, gate severe, dual-map before 165
**Notes:** Question timed out (user AFK); provisionally adopted, then explicitly confirmed by the user on resume ("continue - confirm 1,2").

---

## State ordering & AZ urgency

### Q1: What order should the four states run, and does AZ get a hard pre-Jul-21 target?

| Option | Description | Selected |
|--------|-------------|----------|
| AZ first w/ Jul-21 target, then WA→TN→MA | AZ end-to-end first with an explicit goal of full AZ coverage before its Jul-21 primary; TN audit runs up front in parallel | ✓ (confirmed on resume after AFK timeout) |
| Primary-date order, no hard target | Same order, Jul-21 best-effort only | |
| Largest-first (WA anchor convention) | WA→AZ→TN→MA; AZ likely misses its primary window | |

**User's choice:** AZ first with hard Jul-21 target, then WA→TN→MA
**Notes:** Question timed out (user AFK); provisionally adopted, then explicitly confirmed by the user on resume ("continue - confirm 1,2").

---

## Scaling the ~183-record pipeline

### Q1: How should the ~183-record pipeline be structured across plans?

| Option | Description | Selected |
|--------|-------------|----------|
| Per-state vertical slices | One seed plan + one stance plan per state (AZ→WA→TN→MA), per-state pushes, majors-first within each state; TN audit its own up-front plan; closing 37-district mini-gate | ✓ |
| Seed-all first, then stance-all | All fields visible sooner (stance-less), but AZ pre-Jul-21 completeness riskier | |
| Split into two sub-waves | AZ+WA wave 1, TN+MA wave 2 with checkpoint between | |

**User's choice:** Per-state vertical slices
**Notes:** User moved to next area without further pipeline questions — gate shape / plan splitting / push-cadence details left to planner discretion.

---

## Fringe-candidate search depth

### Q1: What search-effort calibration applies to fringe/perennial candidates in this phase?

| Option | Description | Selected |
|--------|-------------|----------|
| Standard uniform effort | Same evidence bar and search effort for all ~183; honest-skip with written search trails absorbs the thin tail | ✓ |
| Elevate WA top-two | Treat WA's Aug-4 top-two as RCV-adjacent; extra passes before any WA skip | |
| Fast-path the fringe | Reduced tier for no-FEC-ID/no-news candidates; raises false-skip risk vs the 159 lesson | |

**User's choice:** Standard uniform effort

---

## Claude's Discretion

- Exact plan count/splitting (incl. whether TN's 73-record stance slice splits into two plans)
- Gate assertion set (clone prior seeding-phase verify SQL style)
- The severe-district surfacing-withhold mechanism (D-01b)
- Per-state elections/races migration authoring details
- The TN audit's severity rubric

## Deferred Ideas

- Cross-state district polygon refresh / dual-map design (TN/MO/AL/LA/UT) — own phase, committed before Phase 165 and well before Nov-3
- Partial-incumbent stance top-up (154 D-02 carry-forward)
- Challenger `finance_summary`
- MA late-filing independents (Aug-25 window) → Phase 167 MA cluster
- v2.21 calendar-gated tail (159-05/06, PA independents, FL 153)
