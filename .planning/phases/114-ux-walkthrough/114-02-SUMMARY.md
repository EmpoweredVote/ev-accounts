---
phase: 114-ux-walkthrough
plan: 02
subsystem: research
tags: [ux-walkthrough, essentials, playwright, monroe-county, voter-facing, gap-register]

requires:
  - phase: 114-ux-walkthrough
    provides: 114-01 methodology + empty GAPS register skeleton
  - phase: 112-data-completeness-audit
    provides: BALLOT-BASELINE-2026-05-05.md denominator + AUDIT-REPORT-112.md (stub rows, headshot gaps, profile completeness flags)
provides:
  - essentials.md voter-side walkthrough narrative (13 sections, 200 W Kirkwood address)
  - 8 production screenshots of Essentials under screenshots/essentials/
  - Gap entries G-114-001 through G-114-010 appended to GAPS.md
  - Voter-facing confirmation of multiple AUDIT-112 DB gaps (stub candidates, missing headshots, profile completeness)
  - First voter-facing blocker identified (wrong election date "May 4, 2026" app-wide on candidate profile template)
affects: [114-03, 114-04, 114-05, 114-06, 114-07, 115]

tech-stack:
  added: []
  patterns:
    - "Playwright MCP accessibility snapshot → grep → screenshot loop as a gap-capture workflow for a React SPA"
    - "Cross-reference UI observation against AUDIT-REPORT-112 stub/linked status to distinguish voter-facing vs already-audited DB gaps"

key-files:
  created:
    - .planning/research/ux-walkthrough/essentials.md
    - .planning/research/ux-walkthrough/screenshots/essentials/01-landing.png
    - .planning/research/ux-walkthrough/screenshots/essentials/02-address-typed.png
    - .planning/research/ux-walkthrough/screenshots/essentials/03-results-all.png
    - .planning/research/ux-walkthrough/screenshots/essentials/04-elections-tab.png
    - .planning/research/ux-walkthrough/screenshots/essentials/05-pierce-profile.png
    - .planning/research/ux-walkthrough/screenshots/essentials/06-young-profile.png
    - .planning/research/ux-walkthrough/screenshots/essentials/07-arrington-empty-profile.png
    - .planning/research/ux-walkthrough/screenshots/essentials/08-out-of-area-dc.png
  modified:
    - .planning/research/ux-walkthrough/GAPS.md

key-decisions:
  - "Clicked 3 candidate profiles rather than all 10+ (Pierce incumbent + Young linked-thin challenger + Arrington DB stub) — each demonstrates a distinct profile-completeness failure mode that generalizes to its peers, avoiding 20+ redundant clicks"
  - "Logged G-114-010 as one blocker covering all 4 stub candidates at this address rather than one entry per stub — Phase 115 tiering cares about the class of failure, not the per-row count"
  - "Did NOT log 'only Houchin visible in federal tier' as a data gap after discovering Elections tab renders all 5 candidates correctly — downgraded to navigational ux-friction (G-114-003, G-114-005)"
  - "Exercised the out-of-area empty state via a DC address (1600 Pennsylvania Ave) rather than a nonsense string — gives a valid-address-out-of-coverage path, which is more realistic than the unrecognized-address path"

patterns-established:
  - "Walker-first Playwright, audit-reference second: walk the UI cold, then cross-reference findings against AUDIT-REPORT-112.md to separate voter-facing gaps from already-known DB gaps"
  - "One gap entry per failure class, not per instance: G-114-010 covers Arrington + Nyquist + J. Davis + Branham + Hays as the 'DB stub on ballot' class"

requirements-completed: [UX-01]

duration: ~45min
completed: 2026-04-13
---

# Phase 114-02: Essentials Voter-Side Walkthrough (UX-01)

**Live Playwright walk of essentials.empowered.vote against 200 W Kirkwood Ave in April 2026 surfaces a May 5 ↔ May 4 date bug across every candidate profile, confirms the default Representatives tab hides all primary challengers, and catches 4 DB stub candidates whose profile pages are literally a single name card — yielding 10 G-114-NNN gap entries in the phase register.**

## Performance

- **Duration:** ~45 min
- **Completed:** 2026-04-13
- **Tasks:** 2 / 2
- **Files created:** 9 (essentials.md + 8 PNGs)
- **Files modified:** 1 (GAPS.md — 10 entries appended)

## Accomplishments

- **Full Playwright walkthrough against production** — landing → address entry → default Results → Elections tab → incumbent profile (Matt Pierce) → linked-but-thin challenger (Lilliana Young) → DB stub challenger (Benjamin T. Arrington) → out-of-area empty state (DC address) → back-navigation. No human-leg fallback was needed.
- **10 gap entries logged with full 8-field schema**, all passing automated acceptance criteria (monotonic IDs, required fields, evidence pointers, antipartisan rule respected).
- **3 data-type gaps linked back to `BALLOT-BASELINE-2026-05-05.md`** via `baseline_ref` — G-114-007 (Pierce missing bio, HD-61 row), G-114-009 (Young missing headshot, HD-61 row), G-114-010 (Arrington/Nyquist/Davis/Branham stubs, County-Wide rows).
- **4 gaps cross-referenced against AUDIT-REPORT-112.md** so Phase 115 can count them against the existing DB audit rather than double-count: G-114-007 ↔ §AUDIT-06, G-114-008 ↔ §AUDIT-04, G-114-009 ↔ §AUDIT-05, G-114-010 ↔ §AUDIT-03.
- **Top voter-facing blocker identified:** candidate profile page template renders `"Election: May 4, 2026"` — off by one day — confirmed across Pierce, Young, and Arrington profiles (→ app-wide template bug, not per-politician data). Severity=blocker because voters trust date labels on candidate pages.
- **Positive finding also documented:** The Elections tab's candidate list is 100% correct against the baseline denominator for Bloomington Township. The race-coverage problem is navigational (default tab), not a data problem.

## Task Commits

1. **Task 1: Playwright walk + 8 screenshots** — `7d69397` (docs)
2. **Task 2: essentials.md narrative + GAPS.md append** — `8f48bef` (docs)

## Gap Entries Logged

| ID | Severity | Type | One-line |
|----|----------|------|----------|
| G-114-001 | confusing | ux-friction | No autocomplete dropdown during address typing |
| G-114-002 | minor | content | Address echoed ALL CAPS in results header |
| G-114-003 | blocker | ux-friction | Default Representatives tab hides primary challengers |
| G-114-004 | confusing | content | Deckard/Henry shown under different offices on two tabs with no cross-linkage |
| G-114-005 | confusing | ux-friction | `Representatives` is wrong default in the month before a primary |
| G-114-006 | blocker | content | Profile page shows "Election: May 4, 2026" (app-wide template bug, should be May 5) |
| G-114-007 | confusing | data | Matt Pierce profile missing personal bio (confirms AUDIT-112 §06) |
| G-114-008 | confusing | feature | Pierce profile missing Read & Rank section despite 10 linked quotes |
| G-114-009 | confusing | data | Lilliana Young missing headshot (confirms AUDIT-112 §05) |
| G-114-010 | blocker | data | 4 May 5 candidates at this address are DB stubs → single-card profiles (confirms AUDIT-112 §03) |

## Files Created/Modified

- `.planning/research/ux-walkthrough/essentials.md` — 213-line screen-by-screen narrative with inline gap-ID references and screenshot pointers
- `.planning/research/ux-walkthrough/screenshots/essentials/01-landing.png` → `08-out-of-area-dc.png` — production screenshots
- `.planning/research/ux-walkthrough/GAPS.md` — appended plan 114-02 block (10 monotonic G-114-NNN entries)

## Decisions Made

- **Cross-reference policy:** Every gap that matched a `stub` or `Complete=N` row in `AUDIT-REPORT-112.md` was marked with that cross-reference in the `notes` field so Phase 115 can distinguish "new voter-facing gap" from "DB gap already audited, now with voter-facing consequence surfaced." This avoids double-counting.
- **G-114-010 aggregation:** Logged as a single blocker covering 5 stub candidates (Arrington, Nyquist, Joe Davis, Branham, Hays) rather than 5 separate gaps — the failure class ("DB stub on ballot") is what Phase 115 needs to tier, not the per-candidate instance count.
- **Rejected false alarm:** The first inspection of the Representatives tab suggested all primary challengers were missing from the DB. Clicking the Elections tab proved the challengers ARE in the DB and the issue is a navigational/default-tab problem. This reclassification (data → ux-friction) is the clearest validation the "drive the UI cold, don't assume from one tab" walkthrough policy is working.

## Deviations from Plan

None — plan executed exactly as written. All 2 tasks completed, 8 screenshots captured (meeting the ≥8 floor), 10 gap entries appended (exceeding the ≥6 floor), antipartisan rule respected, all data-type gaps have non-`n/a` baseline_ref.

## Issues Encountered

- **Initial overreaction:** On the Representatives tab I believed federal D primary candidates were missing from the DB and was about to log it as a critical data blocker. Switched to Elections tab first, confirmed all candidates are present, and reclassified as ux-friction. The lesson (captured in Decisions above) is now part of the walker's self-check: always exhaust in-app navigation before logging "missing" as data.
- **Intermediate accessibility snapshot files** (`_snap-*.md`) were written during the walk as working notes then removed before committing — they served as a grep-addressable bridge between the large snapshot YAMLs and the grep/write loop, but have no value as committed artifacts.

## User Setup Required

None — pure voter-side research pass against production.

## Next Phase Readiness

- **Wave 2 sequencing confirmed critical:** Plans 114-03 (Compass), 114-04 (Read & Rank), 114-05 (Treasury) all append to `GAPS.md` and must start their monotonic IDs at **G-114-011** (the next number after this plan's last entry at G-114-010). They cannot run in parallel worktrees against this shared file.
- **Phase 115 pre-tiering intuition:** G-114-006 (wrong date) and G-114-010 (stub candidates) are the two findings most likely to make Tier 1 "must ship before May 5" because both mislead a voter about actionable ballot information. G-114-003 and G-114-005 (default tab + hidden challengers) are strong Tier 1 candidates too but are lower-risk because the correct data exists one click away.
- **Read & Rank integration flag for Plan 114-06:** G-114-008 notes that Pierce has 10 quotes in DB (per AUDIT-112) but no visible Read & Rank section on his Essentials profile. Plan 114-06 should verify this during the cross-app pass — if the Essentials → Read & Rank surface truly isn't rendering, that's a cross-app integration blocker separate from the per-app walk.

---
*Phase: 114-ux-walkthrough*
*Plan: 02*
*Completed: 2026-04-13*
