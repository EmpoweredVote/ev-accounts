# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-18)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v1.1 Essentials UX Polish — Phase 10: Term Dates

## Current Position

Phase: 10 of 10 (Term Dates)
Plan: 1 of 1 in current phase (complete)
Status: Phase complete — all plans done
Last activity: 2026-02-18 — Completed 10-01-PLAN.md with human-verify approval

Progress: [████████░░] 80% (v1.1)

## Performance Metrics

**Velocity (v1.0):**
- Total plans completed: 21
- v1.0 phases: 7 phases, 21 plans

**By Phase (v1.0):**

| Phase | Plans | Status |
|-------|-------|--------|
| 1. Auth Safety Audit | 1 | Complete |
| 2. Guest-First Auth | 3 | Complete |
| 3. Compass Visual Fixes | 2 | Complete |
| 4. Compass UX Enhancements | 8 | Complete |
| 5. Essentials Improvements | 5 | Complete |
| 6. Audit Gap Closure | 1 | Complete |
| 7. Integration Polish | 1 | Complete |

**By Phase (v1.1):**

| Phase | Plans | Status |
|-------|-------|--------|
| 8. Layout | 1 | Complete |
| 9. Building Imagery | 1 | Complete |
| 10. Term Dates | 1 | Complete |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
All v1.0 decisions resolved — see `.planning/milestones/v1.0-ROADMAP.md` for full history.

v1.1 decisions:
- [Phase 08-layout]: Sidebar width increased to 300px and building image aspect ratio changed to 1/2.25 (portrait) for Results page sticky layout
- [Phase 08-layout]: IntersectionObserver root set to scrolling main panel ref on desktop so scroll-spy tier-swap works correctly in two-panel layout
- [Phase 09-building-imagery]: Sourced all building photos from Wikimedia Commons (public domain/CC) to avoid licensing concerns in civic app
- [Phase 09-building-imagery]: FALLBACK.Federal stays as us-capitol.svg — CURATED map exclusively serves real photos; fallback always uses SVGs for unsupported cities
- [Phase 09-building-imagery]: Extract city name from chamber_name regex when representing_city is empty — BallotReady transform doesn't populate representing_city
- [Phase 10-term-dates]: Use en-dash (U+2013) for date ranges in term date display — typographically correct for date spans
- [Phase 10-term-dates]: Hide term date line entirely when both start and end are null — no placeholder text
- [Phase 10-term-dates]: Start-only dates display as "Since Jan 2023" — forward-looking phrasing for ongoing terms

### Pending Todos

None.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-02-18
Stopped at: Completed 10-01-PLAN.md — phase 10 done, human-verify approved
Resume file: None — phase 10 complete, v1.1 milestone all phases done
