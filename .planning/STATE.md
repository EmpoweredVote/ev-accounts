# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-17)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** Phase 4 (Compass UX Enhancements) — COMPLETE (8 of 8 plans done)

## Current Position

Phase: 4 of 5 (Compass UX Enhancements) — COMPLETE
Plan: 8 of 8 in current phase — complete (phase done)
Status: Phase 4 complete; Phase 5 (candidate discovery) is next
Last activity: 2026-02-18 — Phase 4 Plan 08 executed (LibraryDrawer write-in support with drag-to-position and server persistence)

Progress: [████████░░] 80%

## Performance Metrics

**Velocity:**
- Total plans completed: 6
- Average duration: 2 min
- Total execution time: 15 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-auth-safety-audit | 1 | 5 min | 5 min |
| 02-guest-first-auth | 3 (of 3) | 6 min | 2 min |
| 03-compass-visual-fixes | 2 (of 2) | 4 min | 2 min |
| 04-compass-ux-enhancements | 8 (of 8) | 10 min | 1 min |

**Recent Trend:**
- Last 5 plans: 5 min, 2 min, 2 min, 2 min, 2 min
- Trend: fast execution on focused frontend tasks

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Roadmap]: Monorepo migration deferred to v2 — no infrastructure phases in this milestone
- [Roadmap]: Phase 3 (visual fixes) depends only on Phase 1, can run parallel to Phase 2 if two devs available
- [Roadmap]: Stance randomization is direction-flip only (not full shuffle) — simpler, spectrum-preserving
- [01-01]: Integration tests use real Supabase DB (not SQLite) — Postgres schema namespacing requires real DB for accurate behavioral confirmation
- [01-01]: Route manifest embedded in auth-audit.md section 4 (not standalone file) — per user constraint from CONTEXT.md
- [01-01]: AdminMiddleware DB-dependent path not unit tested — requires admin user seeding; missing-userID path covered without DB
- [02-01]: Circular import (auth->compass->auth) resolved by using GORM Table() with anonymous structs — no behavioral change, same Postgres tables written
- [02-01]: Session creation on register uses Create (not upsert) since user is brand new and cannot have existing session
- [02-02]: CompassContext owns auth state (isLoggedIn/username) via /auth/me on mount; Layout.jsx no longer maintains its own auth fetch
- [02-02]: Logout clears both server session and localStorage answers/writeIns for clean state reset
- [02-03]: Inline modal registration uses custom form (not ev-ui AuthForm) — AuthForm is full-page and unsuitable for modal embedding
- [02-03]: Login toast uses bg-[#00657c] literal hex — Tailwind JIT may not resolve custom color aliases; literal is always safe
- [02-03]: Banner links to /register page rather than re-embedding inline form — persistent nudge is intentionally lower friction
- [03-01]: Label fallback uses 3 steps (16->13->11px) matching 10->14->18 char/line thresholds; hard-cap at 2 lines if still overflowing at 11px
- [03-01]: dynamicLabelOffset adds +8px only for multi-line labels; single-word labels use independent font-size path
- [03-01]: Desktop chrome offset=180px (header ~75 + back ~32 + buttons ~48 + margins ~25); mobile=240px for tab bar
- [03-02]: strokeDasharray omitted entirely (not "none") — inversion is internal state only, not visually indicated on spoke lines
- [03-02]: invertedSpokes prop preserved in polygon point calculations — click-to-invert behavior unchanged
- [Phase 04]: QUIZ-08: initRandomInversions accepts topic objects (id + short_title) — hash seed requires numeric topic.id
- [Phase 04]: guestId not cleared on logout — stance order persists across login/logout on same browser
- [04-01]: New PATCH fields (question_text, level) use snake_case JSON; existing fields (Title, ShortTitle) keep PascalCase for backward compatibility
- [04-01]: QuestionText and Level use empty string zero-value in Topic struct (not nullable pointer) — GORM stores empty string, omitempty suppresses from JSON when blank
- [04-03]: getQuestion helper defined at module scope — pure function with no closure over state, avoids re-creation on each render
- [04-03]: Category sub-label removed from Library cards — category heading above grid already provides context; level badge takes footer slot
- [04-03]: LEVEL_CONFIG uses inline SVG paths — consistent color control and sizing via Tailwind, no external assets

- [04-04]: AnimatePresence wraps conditional children — no early return guard on LibraryDrawer to allow exit animation
- [04-04]: Card click opens drawer (setDrawerTopic) instead of toggling compass topic selection
- [04-04]: Drawer panel stays open after stance selection — no auto-close on answer

- [04-05]: Frontend-only fix for drawer crash — backend CategoryHandler not modified (adding Preload(Topics.Stances) would be wasteful since full topics already available in context)
- [04-05]: Two-layer defense: Library.jsx context lookup (primary) + LibraryDrawer null guard (secondary)
- [Phase 04]: Level stored as pq.StringArray (text[]) — GORM AutoMigrate alters column; getLevels helper normalizes at display time for backward compat
- [Phase 04]: Optimistic setTopics now syncs all editable fields (title, short_title, question_text, level) — fixes silent stale state bug after save
- [Phase 04]: topicRes.ok check added to TopicUpdateHandler fetch — failed PATCH now throws and shows alert instead of silently continuing
- [04-08]: SortableStanceLabel and SortableWriteInCard copied exactly from Quiz.jsx — pure presentation components, no need to abstract to a shared module
- [04-08]: LibraryDrawer useEffect depends on topic?.id only — resets write-in state on topic change without re-firing on currentAnswer updates within same topic
- [04-08]: handleDrawerSelect clears writeIns context when predefined stance chosen — selecting a predefined stance replaces any existing write-in for that topic
- [04-verify]: answeredTopicIDs useEffect uses answersRef (not answers) to prevent infinite fetch loop — effect calls setAnswers, so answers in deps creates infinite cycle

### Pending Todos

None.

### Blockers/Concerns

- AUTH-01 RESOLVED: Session auth verified with 10 automated tests; cookie config documented; 62-route manifest complete
- Phase 5 candidate query: district-to-ZIP mapping for candidates differs from officeholder path — validate against election_records schema before 05-01 begins
- Building images (ESST-04): confirm demo target localities before asset curation (assumed: U.S. Capitol, state capitols, Bloomington City Hall, LA City Hall)

## Session Continuity

Last session: 2026-02-18
Stopped at: Completed 04-08-PLAN.md (LibraryDrawer write-in support with drag-to-position and server persistence — Phase 4 fully complete)
Resume file: .planning/phases/05-candidate-discovery/05-01-PLAN.md (when Phase 5 begins)
