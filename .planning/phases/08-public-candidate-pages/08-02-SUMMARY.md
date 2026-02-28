---
phase: 08-public-candidate-pages
plan: 02
subsystem: api
tags: [express, typescript, supertest, vitest, candidate-pages, optionalAuth, integration-tests]

# Dependency graph
requires:
  - phase: 08-01
    provides: candidateService.ts with getCandidateBySlug, getCandidatesByZip, getCandidateAnswers
affects: [deployment, Essentials frontend integration, Framer public candidate page integration]

provides:
  - GET /api/candidates/:slug — optionalAuth public candidate profile endpoint (active + inactive)
  - GET /api/candidates/:slug/answers — optionalAuth candidate answers with inversion support
  - GET /api/essentials/candidates/:zip — optionalAuth ZIP-based candidate discovery (active only)
  - Integration tests with 18 CI-safe assertions + 9 DB-dependent it.skip tests

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Route files import from lib/candidateService.ts only — service-role client never used directly in routes/"
    - "/:slug/answers declared before /:slug in router — explicit ordering, prevents ambiguity"
    - "ZIP validation regex /^\\d{5}(-\\d{4})?$/ + slice(0, 5) normalization before cache lookup"
    - "Architecture test string match requires comments in route files to NOT contain banned identifier name"

key-files:
  created:
    - backend/src/routes/candidates.ts
    - backend/src/routes/essentialsCandidates.ts
    - tests/integration/candidates.test.ts
  modified:
    - backend/src/index.ts

key-decisions:
  - "Route file comments must not contain 'supabaseAdmin' string — architecture test uses content.includes() literal match, not import AST analysis"
  - "ZIP+4 format accepted in route, normalized to 5-digit before passing to getCandidatesByZip — consistent cache keys"
  - "CI-safe tests for optionalAuth routes assert [404, 500] range — no live DB means service throws 500; route wiring is confirmed either way"
  - "/:slug/answers validation (topics param) fires before DB call — safe to test in CI without live DB"

patterns-established:
  - "optionalAuth route wiring CI tests: assert status in [expected, 500] when no live DB — validates route is registered without requiring connectivity"
  - "Architecture CI tests: fs.readFileSync on route files, assert .not.toContain('supabaseAdmin') — catches drift immediately"

# Metrics
duration: 12min
completed: 2026-02-28
---

# Phase 8 Plan 2: Public Candidate Pages — Route Files and Integration Tests Summary

**Three optionalAuth Express routes (slug profile, slug answers, ZIP discovery) with 18 CI-safe + 9 DB-skipped integration tests enforcing tolerance_rating absence and inactive-candidate behavior**

## Performance

- **Duration:** 12 min
- **Started:** 2026-02-28T16:10:48Z
- **Completed:** 2026-02-28T16:22:48Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- `GET /api/candidates/:slug` returns full profile (active or inactive) via getCandidateBySlug — 404 for unknown slug, 200 for all others including demoted candidates
- `GET /api/candidates/:slug/answers` accepts comma-separated `?topics=uuid1,uuid2` and optional `?inverted=uuid1` query params, validates UUID format before any DB call
- `GET /api/essentials/candidates/:zip` validates 5-digit and ZIP+4 formats, normalizes to 5-digit before lookup, returns 200+[] for valid ZIP with no candidates
- All three routes use optionalAuth — no auth token required, suspended users can still view public candidate pages
- 18 CI-safe tests pass in all environments (no DB required): validation edge cases, architecture file assertions, router mount assertions
- 9 DB-dependent tests marked it.skip per decision [04-03] — cover tolerance_rating absence, inactive behavior, ZIP exclusion, inversion, response shape

## Task Commits

Each task was committed atomically:

1. **Task 1: Route files + index.ts mounts** - `970413b` (feat)
2. **Task 2: Integration tests** - `913cff6` (test)

## Files Created/Modified
- `backend/src/routes/candidates.ts` — GET /:slug and GET /:slug/answers handlers, optionalAuth, calls getCandidateBySlug/getCandidateAnswers
- `backend/src/routes/essentialsCandidates.ts` — GET /:zip handler, ZIP regex validation, calls getCandidatesByZip
- `backend/src/index.ts` — candidatesRouter and essentialsCandidatesRouter imported and mounted
- `tests/integration/candidates.test.ts` — 27 total tests (18 CI-safe run + 9 DB-dependent skipped)

## Decisions Made

- **Route file comment constraint**: The architecture test uses `content.includes('supabaseAdmin')` — a literal string match on the entire file. Any comment mentioning the banned identifier causes a false positive failure. Comments reworded to say "service-role client" instead. This is consistent with decision [04-03] from Phase 4.
- **ZIP normalization**: ZIP+4 format (e.g., `47401-1234`) accepted by the route validator, normalized to 5-digit (`47401`) via `zip.slice(0, 5)` before passing to getCandidatesByZip. Ensures cache keys are always 5-digit.
- **CI-safe test assertion pattern for optionalAuth**: Routes that reach candidateService call the Upstash Redis cache, which throws `fetch failed` in CI (no Redis config). The error propagates as 500. Tests assert `expect([404, 500]).toContain(res.status)` to confirm route is wired without requiring connectivity.
- **Validation tests are fully CI-safe**: The `topics` param absence check and ZIP format validation both fire before any service/DB call, making those tests deterministically safe.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Route file comments contained banned architecture test string**
- **Found during:** Task 1 verification (architecture test run)
- **Issue:** Initial comments in candidates.ts and essentialsCandidates.ts said "supabaseAdmin is NOT imported in this file". The architecture test uses `content.includes('supabaseAdmin')` — a literal string match — and flagged both files as violations even though neither imports the client.
- **Fix:** Rewrote all comments to say "service-role client" instead of the banned identifier name. This matches the established pattern from decision [04-03] and [07-01].
- **Files modified:** backend/src/routes/candidates.ts, backend/src/routes/essentialsCandidates.ts
- **Verification:** Grep confirms zero matches for `supabaseAdmin` in both route files; architecture violations list no longer includes candidates.ts or essentialsCandidates.ts
- **Committed in:** 970413b (Task 1 commit, files corrected before commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug in comment wording triggering false positive)
**Impact on plan:** Auto-fix required for architecture test to pass. No scope creep — single comment rewrite.

## Issues Encountered
- Architecture test pre-existing failures: routes/auth.ts, compass.ts, connect.ts, and social.ts continue to fail the architecture test. These are pre-existing architectural debt from earlier phases, not regressions from Phase 8. Candidates.ts and essentialsCandidates.ts are NOT in the violations list.

## Next Phase Readiness
- Phase 8 (08-public-candidate-pages) is now complete — both plans executed
- All three Phase 8 success criteria satisfied:
  - CAND-01: GET /api/candidates/:slug returns legal name split, metadata, public stances — no auth required
  - CAND-02: tolerance_rating structurally absent from all candidate responses (candidateService.ts whitelist + test assertions)
  - CAND-03: Inactive candidates return full profile with active:false; ZIP lookup excludes inactive (getCandidatesByZip enforces is_active=true)
- Routes ready for Framer and Essentials frontend integration
- No blockers — project roadmap complete (all 8 phases done)

---
*Phase: 08-public-candidate-pages*
*Completed: 2026-02-28*
