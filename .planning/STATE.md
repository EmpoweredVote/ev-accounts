# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-20)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v1.3 Compass Bug Fixes & Title Standardization — Phase 17: Title Standardization (Backend)

## Current Position

Phase: 17 of 20 (Title Standardization — Backend)
Plan: 2 of 2 complete
Status: Phase complete
Last activity: 2026-02-21 — 17-02 complete: all 21 topics updated in DB with tension titles/short titles/questions; ShortName and StartPhrase removed from model and handlers

Progress: [████████░░░░░░░░░░░░] 40% (16/20 phases complete across all milestones)

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

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
All v1.0 decisions resolved — see `.planning/milestones/v1.0-ROADMAP.md` for full history.
All v1.1 decisions resolved — see `.planning/milestones/v1.1-ROADMAP.md` for full history.
All v1.2 decisions resolved — see `.planning/milestones/v1.2-ROADMAP.md` for full history.

Recent v1.3 decisions:
- [Phase 17]: Title standardization is backend-first — server data must be canonical before frontend display phases run
- [Phase 19]: Calibration flow fixes depend on Phase 18 so that topic names are correct in the same pass users see calibration
- [17-01]: Tension title format uses em dash separator and policy outcome pairs (not partisan labels); pole order randomized per topic — 10 right-first, 11 left-first verified
- [17-01]: Two short titles renamed for clarity: Taxes -> Taxes & Spending, Tariffs -> Trade & Tariffs
- [17-02]: Database is now canonical source of truth for all topic naming — no hardcoded fallbacks needed in frontend
- [17-02]: ShortName and StartPhrase dropped at DB and model level simultaneously to keep code/schema in sync

### Pending Todos

None.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-02-21
Stopped at: Completed 17-02-PLAN.md — Phase 17 fully complete; DB updated with canonical topic names, model cleaned
Resume file: None
