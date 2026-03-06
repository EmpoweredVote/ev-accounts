# Requirements: Empowered Accounts — v1.2

**Defined:** 2026-03-05
**Core Value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.

---

## v1.2 Requirements

### CompassV2 Backend Compatibility

Gaps discovered via CompassV2 bundle analysis (2026-03-05). All three are new
endpoints or extensions; the compass core routes are already correct.

- [ ] **COMP2-01**: User can clear all their compass answers and selected topics
  via `DELETE /api/compass/answers/me` ("Reset compass" action in CompassV2)
- [ ] **COMP2-02**: Active politicians list is publicly accessible without
  authentication via `GET /api/essentials/politicians` (for the compare widget)
- [ ] **COMP2-03**: `POST /api/connect/compass-import` accepts an optional
  `selected_topics` array alongside calibrations, storing pre-auth topic
  selections for import when the Connect flow completes

### Alpha Hardening

Tech debt carried since v1.1 close. Must be resolved before real users hit the
system.

- [ ] **HARD-01**: `database.types.ts` is regenerated via `supabase gen types
  typescript` and committed — no stale generated type mismatches remain
- [ ] **HARD-02**: TypeScript compiler reports zero errors in strict mode across
  the entire backend source tree
- [ ] **HARD-03**: JWT token revocation via Redis blocklist is reviewed and
  verified — a logged-out token is rejected on the next request, not just
  after expiry
- [ ] **HARD-04**: Architecture test suite runs cleanly with no skipped tests or
  TODO workarounds

### Compass Admin Backend

New admin API routes that the compass admin UI requires. The existing routes
(create/update topic, update stance, politician answers/context) remain; these
are the missing pieces.

- [ ] **CADM-01**: Admin can list all compass topics including non-live drafts
  via `GET /api/admin/compass/topics`
- [ ] **CADM-02**: Topic creation via `POST /api/admin/compass/topics` accepts
  an optional `stances` array and creates all stances atomically with the topic
- [ ] **CADM-03**: Admin can create a new politician record via
  `POST /api/admin/compass/politicians`
- [ ] **CADM-04**: Admin can edit a politician's profile (name, office title,
  photo URL, active status) via `PATCH /api/admin/compass/politicians/:id`
- [ ] **CADM-05**: Admin can list all compass categories via
  `GET /api/admin/compass/categories`
- [ ] **CADM-06**: Admin can create a compass category via
  `POST /api/admin/compass/categories`
- [ ] **CADM-07**: Admin can assign categories to a topic via
  `PUT /api/admin/compass/topics/:id/categories`

### Compass Admin React UI

New pages in the admin React app. All backend routes they call already exist or
will exist after the backend phase above.

- [ ] **CADM-08**: Admin can view all compass topics (including drafts), create
  new topics with stances, and toggle `is_live` status — Topics page in admin UI
- [ ] **CADM-09**: Admin can edit stance text for each of a topic's 5 values
  inline on the topic detail view
- [ ] **CADM-10**: Admin can view all politicians (including inactive), create
  new politicians, and edit politician profiles — Politicians page in admin UI
- [ ] **CADM-11**: Admin can set or update a politician's answers (value 1–5)
  for each compass topic on the politician detail view
- [ ] **CADM-12**: Admin can write or edit a politician's context (reasoning +
  sources) for a specific topic on the politician detail view
- [ ] **CADM-13**: Admin can view and create compass categories, and assign
  categories to topics — Categories page in admin UI

---

## Future Requirements

### CompassV2 Frontend Integration (separate repo)

These are changes needed in the CompassV2 private repo, not here.

- **CV2-01**: CompassV2 switches from `credentials: "include"` (cookies) to
  `Authorization: Bearer <token>` header injection
- **CV2-02**: CompassV2 calls `/api/account/me` instead of `/api/auth/me`
- **CV2-03**: CompassV2 calls `/api/auth/signup` with `email` field instead of
  `/api/auth/register` with `username`
- **CV2-04**: CompassV2 handles the `/api/account/me` response shape correctly
  (extract `connected_profile.completed_onboarding`)
- **CV2-05**: CompassV2 calls `/api/admin/me` instead of
  `/api/auth/admin-check`

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| Cookie-based auth on backend | CompassV2 will be updated to use bearer tokens — adding a second auth paradigm creates permanent technical debt |
| `/api/auth/me` alias route | Same reason — CompassV2 is the consumer to update, not the backend |
| User-to-user compass compare | Deferred from v1.0; infrastructure is in place (COMP-05) |
| Compass topic role assignments via admin UI | Role scope assignment (`compass_topic_roles`) is seeded via migration; editable through admin deferred to v1.3 |
| Gem reserve cap | Deferred for Alpha (CIVIC-02) |
| Third-party identity verification | Post-Alpha, invite chain is the v1 trust mechanism |

---

## Traceability

*Populated by roadmapper — see ROADMAP.md*

| Requirement | Phase | Status |
|-------------|-------|--------|
| COMP2-01 | — | Pending |
| COMP2-02 | — | Pending |
| COMP2-03 | — | Pending |
| HARD-01 | — | Pending |
| HARD-02 | — | Pending |
| HARD-03 | — | Pending |
| HARD-04 | — | Pending |
| CADM-01 | — | Pending |
| CADM-02 | — | Pending |
| CADM-03 | — | Pending |
| CADM-04 | — | Pending |
| CADM-05 | — | Pending |
| CADM-06 | — | Pending |
| CADM-07 | — | Pending |
| CADM-08 | — | Pending |
| CADM-09 | — | Pending |
| CADM-10 | — | Pending |
| CADM-11 | — | Pending |
| CADM-12 | — | Pending |
| CADM-13 | — | Pending |

**Coverage:**
- v1.2 requirements: 20 total
- Mapped to phases: 0 (pending roadmap)
- Unmapped: 20 ⚠️

---

*Requirements defined: 2026-03-05*
*Last updated: 2026-03-05 after initial definition*
