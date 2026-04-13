---
phase: 114-ux-walkthrough
plan: 04
subsystem: research
tags: [ux-walkthrough, read-rank, playwright, monroe-county, voter-facing, gap-register]

requires:
  - phase: 114-ux-walkthrough
    provides: 114-01 methodology; 114-02 Essentials gaps G-114-001..010; 114-03 Compass gaps G-114-011..015
provides:
  - read-rank.md voter-side walkthrough narrative (8 sections, 159 lines)
  - 7 production screenshots under screenshots/read-rank/
  - Gap entries G-114-016 through G-114-020 appended to GAPS.md
  - Per-candidate quote coverage table for all Monroe May 5 primary candidates
  - Answer to D-07 framing question: location filter broken; IN-9/county challengers have 0 quotes
affects: [114-05, 114-06, 114-07, 115]

key-files:
  created:
    - .planning/research/ux-walkthrough/read-rank.md
    - .planning/research/ux-walkthrough/screenshots/read-rank/01-landing.png through 07-redistricting-ca-quote.png
  modified:
    - .planning/research/ux-walkthrough/GAPS.md

key-decisions:
  - "Completed Voting Rights topic fully (all 3 quotes + reveal) rather than sampling — needed politician identities for coverage table"
  - "Did not click through all 26 topics — used AUDIT-112 quote counts for Pierce/Young, stub status for county candidates, and Voting Rights reveal as representative sample"
  - "Logged both location filter mechanisms as one blocker entry (G-114-016) rather than two entries — same root cause, same voter impact"

requirements-completed: [UX-03]

duration: ~45min
completed: 2026-04-13
---

# Phase 114-04: Read & Rank Voter-Side Walkthrough (UX-03)

**Both Read & Rank location filters are non-functional. The app is topic-centric with no candidate navigation. Pierce(10)/Young(6) quotes exist but are undiscoverable without working filters. All IN-9 D challengers and county race candidates have zero quotes. One confirmed Monroe candidate (David Henry) found in Voting Rights reveal. Next gap ID: G-114-021.**

## Performance

- **Duration:** ~45 min
- **Completed:** 2026-04-13
- **Tasks:** 2 / 2
- **Files created:** 8 (read-rank.md + 7 PNGs)
- **Files modified:** 1 (GAPS.md — 5 entries appended)

## Accomplishments

- Full walk from landing → skip practice → topic list → address filter test → Voting Rights topic (3 quotes + champion selection + reveal) → back to topic list for Redistricting preview
- Both location filter mechanisms confirmed non-functional (address text → no effect; Browse Location → empty dropdown)
- **David G Henry** confirmed with ≥1 sourced quote in Read & Rank (Voting Rights, B Square Bulletin source)
- Cross-app "View on Essentials" links with `#compass=` session passthrough confirmed working in reveal screen
- D-07 framing question directly answered with per-candidate coverage table (§6) and 2-paragraph conclusion (§7)

## Gap Entries Logged

| ID | Severity | Type | One-line |
|----|----------|------|----------|
| G-114-016 | blocker | feature | Both location filters non-functional (address text + Browse Location dropdown) |
| G-114-017 | confusing | ux-friction | Topic-centric structure — no candidate-level nav to surface Monroe quotes efficiently |
| G-114-018 | blocker | data | IN-9 D challengers + all county-race candidates have zero Read & Rank quotes |
| G-114-019 | confusing | ux-friction | "Your verdicts appear on Essentials" copy has no hyperlink or CTA |
| G-114-020 | minor | content | App page title is "readrank-prototype" — prototype label in production browser tab |

## Task Commits

1. **Task 1: 7 screenshots** — `4cefb35` (docs)
2. **Task 2: read-rank.md + GAPS.md append** — `196719e` (docs)

## Next Phase Readiness

- **Next monotonic gap ID: G-114-021**
- **Plans 114-05 (Treasury) and 114-06 (cross-app) start at G-114-021**
- **Phase 115 note:** G-114-016 (filters broken) is a Tier 1 candidate alongside G-114-006, G-114-010, G-114-012 — all are pre-May-5 blockers. G-114-018 (0 quotes for challengers) is the same root cause as G-114-012 and G-114-010 — a cross-app pattern that Phase 115 should group as "stub candidate data intake" Tier 1 priority.

---
*Phase: 114-ux-walkthrough*
*Plan: 04*
*Completed: 2026-04-13*
