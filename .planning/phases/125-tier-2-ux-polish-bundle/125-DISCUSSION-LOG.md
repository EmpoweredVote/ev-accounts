# Phase 125: Tier 2 UX Polish Bundle - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 125-tier-2-ux-polish-bundle
**Areas discussed:** Status audit, Complex gaps, Product decisions (G-114-011), Wave structure

---

## Status Audit

| Option | Description | Selected |
|--------|-------------|----------|
| Verify-first in research | Researcher spot-checks each gap in production before planning | ✓ |
| Assume all 17 still need work | Plan fixes regardless; executor marks done if already fixed | |
| Only flag obvious overlaps | Flag G-114-008 and G-114-019 as verify-first, treat others as broken | |

**User's choice:** Verify-first in research — researcher confirms current production state before writing fix tasks.

---

## Scope Reduction

User reviewed all 15 remaining gaps (after initially cutting G-114-017 and G-114-022) and further cut:

| Gap | Reason cut |
|-----|------------|
| G-114-005 | No longer needed |
| G-114-008 | Resolved by Phase 118 |
| G-114-013 | No longer needed |
| G-114-015 | No longer needed |
| G-114-019 | No longer needed |
| G-114-017 | Cut entirely (candidate-level nav is too large a product change) |
| G-114-022 | Cut entirely (budget-vs-actual requires data not yet available) |

**Remaining in scope:** 10 gaps — G-114-001, 002, 004, 011, 014, 020, 021, 023, 024, 025.

---

## G-114-011: Compass Picker Geo-Default

| Option | Description | Selected |
|--------|-------------|----------|
| Essentials address context | Read stored Essentials localStorage; pre-select state | ✓ (primary) |
| Browser geolocation | navigator.geolocation → reverse-geocode → state | ✓ (fallback) |
| Unfiltered | Current behavior | ✓ (final fallback) |
| Indiana hardcoded | Always default to Indiana | |

**User's choice:** Three-tier chain — Essentials localStorage → browser geolocation → unfiltered.
**Fallback when no context:** Unfiltered (current behavior). Do NOT hardcode Indiana.

---

## Wave / Delivery Structure

| Option | Description | Selected |
|--------|-------------|----------|
| App-by-app waves | Wave 1: Essentials, Wave 2: Compass, Wave 3: R&R + Treasury | ✓ |
| One wave, one plan | All 10 gaps in a single plan | |
| Complexity-based waves | Group by trivial / medium / data-heavy | |

**User's choice:** App-by-app waves. Each wave is its own plan + deploy, verified in production before the next begins.

---

## Claude's Discretion

- Exact cross-reference annotation style for G-114-004
- Visual treatment of Treasury "Featured municipalities" section
- Whether to silently skip browser geolocation if denied vs prompt
- Diagnostic approach for G-114-014 headshot source

## Deferred Ideas

- G-114-017 (candidate-level nav) — cut, not added to roadmap backlog
- G-114-022 (budget-vs-actual) — cut, not added to roadmap backlog
