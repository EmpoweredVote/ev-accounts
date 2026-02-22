# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-22)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v1.4 Compass Polish & Tech Debt — Phase 25: Onboarding-to-Calibration Redirect & Topic Display Fix

## Current Position

Phase: 25 — Onboarding-to-Calibration Redirect & Topic Display Fix
Plan: 01 (complete)
Status: Phase 25 Plan 01 execution complete
Last activity: 2026-02-22 — Onboarding redirect to calibration fixed; topic card display regression diagnosed and resolved

Progress: [##..................] 50% (2/4 v1.4 phases complete)

## Performance Metrics

**Velocity (v1.0):**
- Total plans completed: 21
- v1.0 phases: 7 phases, 21 plans

**Velocity (v1.1):**
- Total plans completed: 3
- v1.1 phases: 3 phases, 3 plans

**Velocity (v1.2):**
- Total plans completed: 12
- v1.2 phases: 6 phases, 12 plans, 27 tasks

**Velocity (v1.3):**
- Total plans completed: 7
- v1.3 phases: 4 phases, 7 plans

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
All v1.0 decisions resolved — see `.planning/milestones/v1.0-ROADMAP.md` for full history.
All v1.1 decisions resolved — see `.planning/milestones/v1.1-ROADMAP.md` for full history.
All v1.2 decisions resolved — see `.planning/milestones/v1.2-ROADMAP.md` for full history.
All v1.3 decisions resolved — see `.planning/milestones/v1.3-ROADMAP.md` for full history.
- [Phase 23-ux-cleanup]: Remove Edit Topics button entirely — AddTopicModal is dead UI redundant with Library page topic management
- [Phase 23-ux-cleanup]: Remove Clear button — clearSelections restored to compassTopicsRef snapshot with unclear semantics
- [Phase 23-ux-cleanup]: Phase 23-02: Question-text-first hierarchy across LibraryDrawer, Quiz, Library, and CalibrationOverlay — tension poles removed entirely

### Key Decisions (v1.4)

- **Phase 21**: answersRef pattern in BuildCompass — use useRef to read context answers inside effect without adding to dep array, matching Library.jsx convention exactly
- **Phase 22-01**: Estimate label widths using charCount * fontSize * 0.6 ratio (no DOM measurement); classify label sides via sin(angle) > 0.1 threshold; padding prop retained as vertical-only
- **Phase 22-02**: Uniform font sizing instead of adaptive (varying sizes looked inconsistent); default labelFontSize 18px; max-w-2xl on desktop chart container; dynamic padding capped at 2x base
- **Phase 23-01**: Remove Edit Topics button entirely — AddTopicModal is dead UI redundant with Library page; Remove Clear button — clearSelections unclear semantics; Add w-full to stat card containers and parents for mobile width
- **Phase 23-02**: Question-text-first hierarchy across all four compass views; tension poles removed; fallback to topic name when no question_text exists; suppress subtitle when fallback used to avoid duplicate display
- **Phase 24-01**: start_phrase column already dropped from DB in Phase 17 — only CLI tooling still referenced the dead field; removed from compassimport package and cmd/seed seeder
- **Phase 24-02**: short_name field removed from admin components — no architectural decisions needed, straightforward dead code cleanup of 4 removal sites
- **Phase 25-01**: Use ?calibrate=1 URL param (not localStorage) to signal calibration intent from Onboarding to Compass — cleared with replace:true to preserve back-button behavior; topic card "regression" was a routing dead-end, not a rendering bug

### Pending Todos

None.

### Roadmap Evolution

- Phase 25 added: Onboarding-to-Calibration Redirect & Topic Display Fix

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-02-22
Stopped at: Completed 25-01-PLAN.md
Resume file: None
