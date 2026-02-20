# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-18)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** v1.2 Compass Onboarding & UX — Phase 16: Audit Bug Fixes (Complete)

## Current Position

Phase: 16 of 16 (Audit Bug Fixes)
Plan: 1 of 1 in current phase
Status: Phase 16 complete — all v1.2 audit gaps closed
Last activity: 2026-02-20 — 16-01 audit bug fixes executed

Progress: [████████████████████] 100% (16/16 phases complete)

## Performance Metrics

**Velocity (v1.0):**
- Total plans completed: 21
- v1.0 phases: 7 phases, 21 plans

**Velocity (v1.1):**
- Total plans completed: 3
- v1.1 phases: 3 phases, 3 plans

**v1.2 (in progress):**
- Total plans completed: 10

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
All v1.0 decisions resolved — see `.planning/milestones/v1.0-ROADMAP.md` for full history.
All v1.1 decisions resolved — see `.planning/milestones/v1.1-ROADMAP.md` for full history.

**v1.2 decisions:**
- (16-01) Reset compass not gated on admin — any logged-in user can reset their own compass via session-authenticated DELETE /compass/answers/me
- (16-01) Floating ? button at bottom-right (z-40) — unobtrusive, always visible, does not require ev-ui modification
- (16-01) help_seen seeded one-way from DB (completed_onboarding) — DB wins; localStorage-only flow preserved for guests
- (11-01) Keep `getQuestion` alias in Library.jsx delegating to `getQuestionText` rather than renaming all call sites — avoids churn in a large file
- (11-01) TopicEditor.jsx placeholder text left unchanged — it is a UI hint string, not the runtime fallback
- [Phase 12-quick-ux-fixes]: short_name has no uniqueIndex constraint — multiple topics could share a radar label, acceptable per plan spec
- [Phase 12-quick-ux-fixes]: Library defaults to showAll=true (All view) — inverted from previous hideAnswered=true default, users see all topics by default
- (12-02) question_text updated directly via SQL — title column left unchanged; question_text is the display override layer per getQuestionText() priority
- (12-02) short_name column added via ALTER TABLE (GORM AutoMigrate hadn't run against Supabase) — DDL applied manually before data updates
- (13-01) Tasks 1 and 2 committed together — single Library.jsx file, cohesive implementation, no natural commit seam between them
- (13-01) Card click while popover open dismisses popover (not drawer) — prevents misclick-to-drawer on confirmation
- (13-01) wouldDropBelow3 uses selectedTopics.length <= 3 (current count) — removing 1 from 3 drops to 2, below minimum
- (13-02) Compare button hidden (not disabled) when showChart is false — cleaner than a disabled state when chart itself isn't visible
- (13-02) compassTopicCount <= 3 shows below-3 warning — triggers at exactly 3 since removal will drop to 2, breaking the minimum
- (13-02) No CTA button to Library in MinimumProgress — bottom nav already provides that navigation path (later reversed in 14-04: added "Browse Topics in Library" button)
- (14-01) BuildCompass.jsx required no changes — heading "Build Your Compass" uses compass language, not quiz language
- (14-01) Route path /quiz and internal variable names preserved unchanged — only user-facing text rebranded
- (14-02) Tasks 1 and 2 committed together — single Compass.jsx file, cohesive implementation, no natural commit seam
- (14-02) onReplaceTopic receives shortTitle (string) from RadarChartCore — must look up full topic object via topics.find()
- (14-02) Reset clears onboarding_spokeFlip from localStorage so spoke hint reappears after fresh start
- (14-03) calibrationCompleted flag persisted to localStorage so post-onboarding topic removal shows MinimumProgress not overlay
- (14-03) No write-in support during onboarding — users can write in later from the Library drawer
- (14-03) handleResetCompass clears calibration_skipped + calibration_completed + calibration_progress so overlay re-appears on reset
- (14-04) CalibrationOverlay uses calibrationActive state instead of answeredCompassCount < 3 to prevent premature unmount mid-flow
- (14-04) SavePromptModal gated on hasAnswers — only shows when user has answered at least one stance
- (14-04) LibraryDrawer closes after removing topic from compass on compass page
- (14-04) Cosmetic issues deferred: settings gear placement, spoke inversion persistence across views
- (15-02) Responsive images via CSS display classes (md:hidden / hidden md:block) — simpler than JS media query hook
- (15-02) HelpGuard wraps each guarded route individually in App.jsx rather than a wrapping layout
- (15-02) help_seen set on both close (X) and CTA — any exit path marks walkthrough as seen
- (15-02) Login.jsx post-login redirect changed from /library to /results to match new primary destination

### Pending Todos

None.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-02-20
Stopped at: Completed 16-01-PLAN.md — Phase 16 complete, v1.2 milestone audit gaps fully closed
