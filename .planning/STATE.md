# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-18)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v1.2 Compass Onboarding & UX — Phase 13: Topic Selection Enforcement

## Current Position

Phase: 13 of 15 (Topic Selection Enforcement)
Plan: 1 of 2 in current phase — plan 01 complete
Status: Phase 13 in progress — plan 01 executed
Last activity: 2026-02-19 — completed 13-01 (Library page counter badge, on-compass card indicators, add/remove toggle with confirmation popover)

Progress: [██░░░░░░░░░░░░░░░░░░] 11% (v1.2)

## Performance Metrics

**Velocity (v1.0):**
- Total plans completed: 21
- v1.0 phases: 7 phases, 21 plans

**Velocity (v1.1):**
- Total plans completed: 3
- v1.1 phases: 3 phases, 3 plans

**v1.2 (in progress):**
- Total plans completed: 4

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
All v1.0 decisions resolved — see `.planning/milestones/v1.0-ROADMAP.md` for full history.
All v1.1 decisions resolved — see `.planning/milestones/v1.1-ROADMAP.md` for full history.

**v1.2 decisions:**
- (11-01) Keep `getQuestion` alias in Library.jsx delegating to `getQuestionText` rather than renaming all call sites — avoids churn in a large file
- (11-01) TopicEditor.jsx placeholder text left unchanged — it is a UI hint string, not the runtime fallback
- [Phase 12-quick-ux-fixes]: short_name has no uniqueIndex constraint — multiple topics could share a radar label, acceptable per plan spec
- [Phase 12-quick-ux-fixes]: Library defaults to showAll=true (All view) — inverted from previous hideAnswered=true default, users see all topics by default
- (12-02) question_text updated directly via SQL — title column left unchanged; question_text is the display override layer per getQuestionText() priority
- (12-02) short_name column added via ALTER TABLE (GORM AutoMigrate hadn't run against Supabase) — DDL applied manually before data updates
- (13-01) Tasks 1 and 2 committed together — single Library.jsx file, cohesive implementation, no natural commit seam between them
- (13-01) Card click while popover open dismisses popover (not drawer) — prevents misclick-to-drawer on confirmation
- (13-01) wouldDropBelow3 uses selectedTopics.length <= 3 (current count) — removing 1 from 3 drops to 2, below minimum

### Pending Todos

None.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-02-19
Stopped at: Completed 13-01-PLAN.md (Library indicators, counter badge, add/remove toggle)
Resume file: .planning/phases/13-topic-selection-enforcement/13-02-PLAN.md
