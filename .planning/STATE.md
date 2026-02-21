# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-20)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v1.3 Compass Bug Fixes & Title Standardization — Phase 18: Title Display (Frontend) COMPLETE; next: Phase 19 Calibration Flow

## Current Position

Phase: 18 of 20 (Title Display — Frontend)
Plan: 2 of 2 complete
Status: Phase complete
Last activity: 2026-02-21 — 18-02 complete: tension titles + italic QuestionText added to LibraryDrawer, CalibrationOverlay answer step, Quiz (both modes), and ComparePanel; start_phrase removed from all views; build verified

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
- [18-01]: parseTensionTitle splits at first colon — name is before colon, poles is after; falls back to short_title when no colon
- [18-01]: getQuestionText "Where do you stand on" fallback removed — returns empty string; server data is now canonical
- [18-01]: Library and calibration pick cards use identical two-line layout: topic name primary (text-sm font-medium), poles muted (text-xs text-gray-500)
- [18-02]: Admin TopicEditor placeholder text "Where do you stand on...?" is admin form guidance, not a user-facing fallback — left unchanged (out of scope)
- [18-02]: ComparePanel dropdown value stays as short_title (data key) while display text uses tension title name — backward compatible
- [18-02]: stanceContent in Quiz is shared between full/curated modes; start_phrase removal cleaned both simultaneously

### Pending Todos

None.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-02-21
Stopped at: Completed 18-02-PLAN.md — tension titles applied to all remaining views (LibraryDrawer, CalibrationOverlay answer, Quiz both modes, ComparePanel); Phase 18 complete
Resume file: None
