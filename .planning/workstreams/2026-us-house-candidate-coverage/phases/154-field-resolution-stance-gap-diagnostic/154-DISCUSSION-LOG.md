# Phase 154: Field Resolution + Stance-Gap Diagnostic - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-30
**Phase:** 154-field-resolution-stance-gap-diagnostic
**Areas discussed:** MI provisional handling, Partial-incumbent top-up, Third-party inclusion bar, Vacancy/special races

---

## MI Primary Timing / Provisional Handling

Trigger: web-confirmed MI 2026 congressional primary is **Aug 4, 2026** — after the build window. Roadmap's "all 8 states decided" is wrong for MI.

| Option | Description | Selected |
|--------|-------------|----------|
| MI as date-gated final phase | Build 7 decided states now (100 districts); date-gated MI phase (≥ Aug 4) seeds real nominees. No provisional records, no prune. | ✓ |
| Provisional-seed MI now + re-check | Seed MI's full qualified field provisionally, add a post-primary prune (FL/Wave-1 two-path pattern). | |
| Defer MI to Wave 3 | Drop MI from v2.21 → 100 districts. | |

**User's choice:** MI as date-gated final phase
**Notes:** MI is a single state with a near-term primary, so waiting for real Aug-4 results is cheaper than provisional-seed + prune. Keeps committed 113-district scope. Restructures roadmap back-half (split 157→NJ+VA; 158 gate scopes to 100; add date-gated MI phase).

---

## Partial-Incumbent Stance Top-Up

| Option | Description | Selected |
|--------|-------------|----------|
| Report only, no top-up | Diagnostic surfaces partials; Wave 2 researches only new candidates + zero-stance incumbents. Inherits Wave-1 policy. | ✓ |
| Top up all partials | Research every partial incumbent to full federal-24. | |

**User's choice:** Report only, no top-up
**Notes:** USHC2-05 covers candidates *lacking* stances; topping up prior-milestone partials would inflate load. NY partials were untouched in Wave 1.

---

## Third-Party / Independent Inclusion Bar

| Option | Description | Selected |
|--------|-------------|----------|
| All ballot-qualified for Nov-3 | Every candidate on the Nov-3 general ballot (major + ballot-qualified independents/third-party + certified write-ins). No-record minors → honest-skip. | ✓ |
| Major-party + relevance bar | Major-party always; minors only if they clear a viability bar. | |

**User's choice:** All ballot-qualified for Nov-3
**Notes:** Matches what the voter actually sees + the stated scope. Bar = ballot-qualified for the general; excludes primary-only also-rans and uncertified write-ins.

---

## Vacancy / Special Races (NJ-11, VA-11, GA-13)

| Option | Description | Selected |
|--------|-------------|----------|
| Resolve current officeholder + flag DB gaps | Verify current member + 2026 nominee from official sources (never 2024 incumbency); special-seated members missing from DB → new-record needs; taxonomy-tagged; no ghost incumbents. | ✓ |
| Resolve nominee only, defer officeholder check | Identify 2026 nominee per seat only; skip reconciling current officeholder. | |

**User's choice:** Resolve current officeholder + flag DB gaps
**Notes:** VA-11 (Connolly died/retired 2025, 2025 special), NJ-11 (Sherrill → NJ governor), GA-13 (open/vacancy) all need current-officeholder verification to avoid duplicate/ghost incumbent records downstream.

## Claude's Discretion

- Field-resolution source per state (official state results vs aggregators — primary-source rigor preferred), diagnostic artifact format/location, and the exact `154-verify.sql` assertion set (clone `148-verify.sql`).

## Deferred Ideas

- MI nominee seeding → date-gated MI phase (≥ Aug 4).
- Roadmap edit: split 157→NJ+VA; 158 gate scopes to 100 districts; add date-gated MI phase.
- Partial-incumbent top-up → future data-quality pass.
- Challenger FEC finance_summary → Wave 3+.
