---
phase: 43-integration-documentation
plan: "01"
quick-task: "013"
subsystem: documentation
tags: [integration, documentation, api-reference, partner-teams]
completed: "2026-03-29"
duration: "~25 minutes"

dependency-graph:
  requires: []
  provides: [docs/INTEGRATION-GUIDE-v2.md]
  affects: [CompassV2, Essentials, Treasury Tracker, Read & Rank, Fallacy Finders, Validation Quests, CTC]

tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - docs/INTEGRATION-GUIDE-v2.md
  modified: []

decisions:
  - "Guide supersedes empowered-accounts-integration-guide.md (v1). v1 left in place for reference."
  - "JWKS URL hard-coded with the production Supabase project ID (kxsdzaojfaibhuzmclfq) for copy-paste accuracy."
  - "All 25 route groups from backend/src/routes/ inventoried by reading actual source files."

metrics:
  lines: 828
  endpoint-entries: 186
  anti-patterns: 9
  migration-checklist-items: 13
---

# Quick Task 013: Phase 43 Integration Documentation Summary

**One-liner:** 828-line ev-accounts integration guide (v2) — ES256 JWT/SSO auth, unified politician UUIDs, compass 0.5–5.5 values, full 25-domain endpoint inventory, 9 anti-patterns, migration checklist.

## What Was Built

`docs/INTEGRATION-GUIDE-v2.md` — the complete integration reference for all partner teams (CompassV2, Essentials, Treasury Tracker, Read & Rank, etc.) to migrate from Go-server assumptions to ev-accounts.

## Coverage

All 10 sections from the plan spec:

1. **Overview** — what changed from v1 (Go server era): JWT algorithm, auth flow, politician IDs, compass values, SSO cookie
2. **Production URLs** — `api.empowered.vote` + alias, `accounts.empowered.vote`, `profile.empowered.vote`, CORS origins, exposed headers
3. **Authentication** — ES256/JWKS JWT verification code pattern, SSO redirect flow step-by-step, silent session renewal, service-to-service auth (ServiceKey vs GemKey)
4. **Tier System** — three tiers as child record presence, middleware guard table, suspended account behavior
5. **Schema Inventory** — 8 schemas, PostgREST exposure status per schema, anti-patterns inline
6. **Unified Politician IDs** — essentials UUIDs only, bridge table for migration, anti-pattern for integer IDs
7. **Compass Value Range** — 0.5–5.5 half-step float, valid value list, Zod schema
8. **Endpoint Inventory** — 25 sections (8.1–8.25), all routes read from actual source files, auth requirement per endpoint, request/response shapes for key endpoints
9. **Anti-Patterns** — 9 consolidated anti-patterns with "why" for each
10. **Migration Checklist** — 13 actionable steps for Go-server-to-ev-accounts migration

## Deviations from Plan

None. The file was produced as specified. All route files in `backend/src/routes/` were read before writing the doc. Endpoint accuracy was verified against actual registered paths and middleware chains in the source.

## Verification

```
wc -l docs/INTEGRATION-GUIDE-v2.md    → 828 (spec: ≥300)
grep -cE "GET|POST|PUT|PATCH|DELETE"   → 186 (spec: ≥20)
grep -c "do NOT\|Do NOT"               → 16 (spec: ≥5)
```

All 7 required coverage areas from phase 43 success criteria present.
Document is self-contained — a developer can use it without reading source code.
