---
phase: 114-ux-walkthrough
plan: 03
subsystem: research
tags: [ux-walkthrough, compass, playwright, monroe-county, voter-facing, gap-register]

requires:
  - phase: 114-ux-walkthrough
    provides: 114-01 methodology + GAPS skeleton; 114-02 Essentials walk + G-114-001..010
  - phase: 112-data-completeness-audit
    provides: AUDIT-REPORT-112.md stance coverage + headshot status per politician
provides:
  - compass.md voter-side walkthrough narrative (11 sections)
  - 9 production screenshots of Compass under screenshots/compass/
  - Gap entries G-114-011 through G-114-015 appended to GAPS.md
  - Per-race Compass stance availability table for all May 5 ballot races
  - Answer to framing question: Compass useful for 1 of 8 ballot races (HD-61 only)
affects: [114-04, 114-05, 114-06, 114-07, 115]

tech-stack:
  added: []
  patterns:
    - "React @dnd-kit requires real Playwright PointerEvents — browser_evaluate JS .click() loops register only 1 of N for tile selections"
    - "Compass compare picker State dropdown filter is the workaround for geo-unaware default list"

key-files:
  created:
    - .planning/research/ux-walkthrough/compass.md
    - .planning/research/ux-walkthrough/screenshots/compass/01-landing.png
    - .planning/research/ux-walkthrough/screenshots/compass/02-quiz-q1.png
    - .planning/research/ux-walkthrough/screenshots/compass/03-build-pick-topics.png
    - .planning/research/ux-walkthrough/screenshots/compass/04-build-6-selected.png
    - .planning/research/ux-walkthrough/screenshots/compass/05-compass-results.png
    - .planning/research/ux-walkthrough/screenshots/compass/06-compare-picker.png
    - .planning/research/ux-walkthrough/screenshots/compass/07-indiana-picker-filtered.png
    - .planning/research/ux-walkthrough/screenshots/compass/08-compare-pierce-overlay.png
    - .planning/research/ux-walkthrough/screenshots/compass/09-compare-clean.png
  modified:
    - .planning/research/ux-walkthrough/GAPS.md

key-decisions:
  - "Logged G-114-012 as a single blocker covering all absent May 5 primary challengers rather than per-candidate entries — the failure class ('no stance data for any contested primary') is what Phase 115 needs to tier"
  - "Included Indiana sitting officials NOT on the May 5 primary ballot (Banks, Young senators, Braun governor, Beckwith LG) in the §7 roster because their presence in the picker is accurate; absence of primary challengers is the gap, not the presence of these officials"
  - "G-114-015 logged as minor (not confusing) because the Religious Freedom duplicate was observed during JS auto-advance and requires human re-verification before escalation"
  - "Took 9 screenshots instead of the ≥6 minimum to capture the full compare flow including onboarding tooltip (08) and clean dual-radar (09)"

patterns-established:
  - "Indiana-filter workflow: 'State' dropdown → Indiana → Federal/State/Local tier buttons → confirms which politicians have stance data for a given state"
  - "Framing-question answer format: direct Y/N per ballot race with root-cause attribution (stub vs no-data-entered)"

requirements-completed: [UX-02]

duration: ~60min
completed: 2026-04-13
---

# Phase 114-03: Compass Voter-Side Walkthrough (UX-02)

**Full Playwright walk of compass.empowered.vote reveals the compare feature works correctly for 1 of 8 May 5 ballot races (HD-61 Pierce vs Young); every other contested primary is dark because challengers have no stance data. 5 gap entries logged (G-114-011 through G-114-015); next monotonic ID is G-114-016.**

## Performance

- **Duration:** ~60 min
- **Completed:** 2026-04-13
- **Tasks:** 2 / 2
- **Files created:** 10 (compass.md + 9 PNGs)
- **Files modified:** 1 (GAPS.md — 5 entries appended)

## Accomplishments

- **Full Playwright walkthrough** — landing → full calibration (33 Qs) → Build topic selection (6 of 8 topics) → radar results → Compare picker (all-states) → Indiana filter → Matt Pierce dual-radar comparison. No human-leg fallback needed.
- **5 gap entries logged** with full 8-field schema, all passing automated acceptance criteria (monotonic IDs, required fields, evidence pointers, antipartisan rule respected).
- **Per-race stance availability table (§8)** answers the voter framing question concretely: 1 of 8 races addressable via Compass (IN HD-61).
- **Indiana filter enumeration (§7):** 9–10 Indiana politicians confirmed in picker across Federal/State/Local tiers; complete list of absent May 5 primary candidates documented with AUDIT-112 cross-reference.
- **Cross-app integration confirmed positive:** "View full profile on Essentials ↗" link in compare panel passes session state as `#compass=<base64>` fragment.
- **Onboarding tooltip (4-step, fixed overlay) identified as ux-friction** on first compare use.

## Task Commits

1. **Task 1: 9 screenshots** — `1451126` (docs)
2. **Task 2: compass.md + GAPS.md append** — `3e4aa8d` (docs)

## Gap Entries Logged

| ID | Severity | Type | One-line |
|----|----------|------|----------|
| G-114-011 | confusing | ux-friction | Compare picker defaults to all states; no geo-aware prioritization |
| G-114-012 | blocker | data | All May 5 primary challengers absent from picker — contested races undecidable |
| G-114-013 | confusing | ux-friction | 4-step fixed-overlay onboarding tooltip blocks dual-radar on first compare |
| G-114-014 | confusing | feature | Pierce headshot missing in Compass compare panel despite existing in Essentials |
| G-114-015 | minor | content | Religious Freedom question may repeat in 33-question calibration (unverified) |

## Files Created/Modified

- `.planning/research/ux-walkthrough/compass.md` — 11-section narrative, ~250 lines
- `.planning/research/ux-walkthrough/screenshots/compass/01–09.png` — 9 production screenshots
- `.planning/research/ux-walkthrough/GAPS.md` — appended plan 114-03 block (5 entries, G-114-011..015)

## Decisions Made

- **Framing-question answer format:** Direct Y/N per ballot race with root-cause attribution distinguishes "stub candidate (no politician record)" from "linked candidate (no stance data entered)" — this distinction matters for Phase 115 triage, since stubs require different remediation (create politician record first) than linked politicians (just need stance data entry).
- **Single blocker for all absent primary challengers:** G-114-012 covers IN-9 Graham/Meyer/Peck/Roark + county-wide race candidates as the class "primary challenger with no stance data" rather than one entry per candidate. Same logic as G-114-010 aggregation in plan 114-02.

## Deviations from Plan

- Took 9 screenshots vs the ≥6 floor — added 08 (dual-radar with onboarding tooltip, documents G-114-013) and 09 (clean dual-radar) because the onboarding tooltip warranted its own evidence capture.
- Observed G-114-015 (potential duplicate Religious Freedom question) as an incidental finding during auto-advance; not in the original plan scope. Logged as minor.

## Issues Encountered

- **React @dnd-kit synthetic click failure:** First attempt to select all 8 Build topic tiles via `browser_evaluate` JS `.click()` loop registered only 1 of 8 — React @dnd-kit requires real PointerEvents. Fixed by switching to real `browser_click` calls per tile. This pattern is now documented in the tech-stack section.
- **Fixed-overlay tooltip blocked clicks:** When attempting to dismiss the onboarding tooltip by clicking outside it, the `fixed inset-0` overlay intercepted all pointer events. Required fresh snapshot to find the "Skip All" button ref and click it directly.

## User Setup Required

None — pure voter-side research pass against production.

## Next Phase Readiness

- **Next monotonic gap ID:** G-114-016 (Plans 114-04 and 114-05 start here)
- **Wave 3 (114-04 Read & Rank, 114-05 Treasury) can begin** — both append to GAPS.md starting at G-114-016
- **Phase 115 pre-tiering intuition from Compass:** G-114-012 (no primary challenger data) is a strong Tier 1 candidate alongside G-114-006 and G-114-010 from Essentials — together they mean the three most contested races on the Monroe County ballot (IN-9 D primary, County Prosecutor, County Clerk) are either dark or incomplete in every app.
- **Read & Rank (114-04) advance flag:** Per G-114-008 from the Essentials walk, Pierce has 10 quotes in DB but no visible Read & Rank section on his Essentials profile. Plan 114-04 should confirm whether Read & Rank renders Pierce quotes correctly on its own app before the Essentials integration question is escalated.

---
*Phase: 114-ux-walkthrough*
*Plan: 03*
*Completed: 2026-04-13*
