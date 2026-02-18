# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-17)

**Core value:** Users can explore political issues and discover their elected officials without friction — the experience must feel polished and trustworthy enough to demo confidently.
**Current focus:** Phase 6 (Audit Gap Closure) — COMPLETE (1 of 1 plans done)

## Current Position

Phase: 6 of 6 (Audit Gap Closure) — COMPLETE
Plan: 1 of 1 in current phase — complete (all plans done)
Status: Phase 6 complete — all 3 v1 audit gap items closed; QUIZ-01, AUTH-05, ChamberName resolved
Last activity: 2026-02-18 — Phase 6 Plan 01 executed (question_text quiz headings + guest_state register + ChamberName)

Progress: [██████████] 100%

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
| Phase 05 P01 | 3 | 1 tasks | 2 files |
| Phase 05 P03 | 3 | 2 tasks | 9 files |
| Phase 05 P05 | 2 | 2 tasks | 4 files |
| Phase 06 P01 | 2 | 3 tasks | 5 files |

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
- [05-02]: Badge rendered inside card container (not outside) — overflow:hidden on card would clip external absolute elements; internal absolute positioning is unaffected
- [05-02]: Badge zIndex:1 ensures render above imageWrapper in both horizontal and vertical variants
- [05-04]: RaceNode/CandidacyNode type names used instead of Race/Candidacy to avoid conflicts with Phase B candidacy history types
- [05-04]: levelToDistrictType uses keyword matching on position name for NATIONAL_UPPER/LOWER discrimination (BallotReady provides broad level only)
- [05-04]: Candidates endpoint is live-fetch from BallotReady races query (no caching) since election data changes frequently near election dates
- [Phase 05]: [05-01]: FEDERAL_ORDER puts legislative branch first (Senate > House > President/VP) — matches user requirement for discovery-first UX
- [Phase 05]: [05-01]: TermStart/TermEnd use omitempty — backward-compatible API extension surfacing existing valid_from/valid_to DB columns
- [Phase 05]: SVG placeholder files with .svg extension instead of .jpg — simpler MVP; real photos replace by updating buildingImages.js mapping
- [Phase 05]: Term date rendered below card in wrapper div (not inside PoliticianCard title prop) — avoids ev-ui modifications and clamping issues
- [Phase 05]: Scroll-spy only active when selectedFilter === All — specific tier filters use static image for that tier
- [05-05]: fetchCandidates returns empty array for non-ZIP queries — no candidate-by-address endpoint exists yet; graceful degradation
- [05-05]: showCandidates toggle defaults to false — officials-only is the default experience per ESST-01
- [05-05]: renderPoliticianCard extracted as module-scope function receiving handlePoliticianClick as parameter — avoids closure-over-state issues
- [05-05]: Candidate id prefixed with candidate- to prevent React key collisions with official IDs
- [05-05]: candidateData cleared when toggle turned off — no stale data persists between toggle cycles
- [Phase 06]: Register.jsx stays on page after registration — banner disappears because isLoggedIn becomes true
- [Phase 06]: raceChamberName uses normalizedPosition.name first, falls back to position.name — covers all cases without extra API calls

### Pending Todos

None.

### Blockers/Concerns

- AUTH-01 RESOLVED: Session auth verified with 10 automated tests; cookie config documented; 62-route manifest complete
- Phase 5 candidate query: district-to-ZIP mapping for candidates differs from officeholder path — validate against election_records schema before 05-01 begins
- Building images (ESST-04): confirm demo target localities before asset curation (assumed: U.S. Capitol, state capitols, Bloomington City Hall, LA City Hall)

## Session Continuity

Last session: 2026-02-18
Stopped at: Completed 06-01-PLAN.md (Phase 6 complete — all 3 gap closure tasks done)
Resume file: none (Phase 6 complete — all v1 audit gaps resolved)
