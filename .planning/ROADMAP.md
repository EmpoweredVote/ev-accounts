# Roadmap: Empowered Accounts

## Milestones

- ✅ **v1.0 MVP** — Phases 1–8 (shipped 2026-02-28)
- ✅ **v1.1 XP & Progression** — Phases 9–11 (shipped 2026-03-04)
- 🔄 **v1.2 CompassV2 Integration & Alpha Hardening** — Phases 12–15 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1–8) — SHIPPED 2026-02-28</summary>

- [x] Phase 1: Foundation (2/2 plans) — completed 2026-02-24
- [x] Phase 2: Auth Routes and Account Core (2/2 plans) — completed 2026-02-25
- [x] Phase 3: Alpha Enrollment (3/3 plans) — completed 2026-02-25
- [x] Phase 4: Compass Routes (3/3 plans) — completed 2026-02-26
- [x] Phase 5: Empower Flow (2/2 plans) — completed 2026-02-27
- [x] Phase 6: Gems, Roles, and Social Graph (3/3 plans) — completed 2026-02-27
- [x] Phase 7: Admin Tool and Calibration Cron (3/3 plans) — completed 2026-02-27
- [x] Phase 8: Public Candidate Pages (2/2 plans) — completed 2026-02-28

Full details: `.planning/milestones/v1.0-ROADMAP.md`

</details>

<details>
<summary>✅ v1.1 XP & Progression (Phases 9–11) — SHIPPED 2026-03-04</summary>

- [x] Phase 9: XP Schema & Core (2/2 plans) — completed 2026-03-04
- [x] Phase 10: XP API (2/2 plans) — completed 2026-03-04
- [x] Phase 11: Admin Tool XP View (1/1 plan) — completed 2026-03-04

Full details: `.planning/milestones/v1.1-ROADMAP.md`

</details>

### v1.2 CompassV2 Integration & Alpha Hardening (Phases 12–15)

- [x] Phase 12: Alpha Hardening (2/2 plans) — completed 2026-03-06
  - [x] 12-01-PLAN.md — Regenerate Supabase types and verify TypeScript compiles clean (HARD-01, HARD-02)
  - [x] 12-02-PLAN.md — JWT revocation test and test suite cleanup (HARD-03, HARD-04)
- [x] Phase 13: CompassV2 Backend Compatibility (4/4 plans) — completed 2026-03-06
  - [x] 13-01-PLAN.md — Migrations: inform schema repair, deleted_at, is_candidate, reset and import RPCs
  - [x] 13-02-PLAN.md — DELETE /compass/answers/me endpoint (COMP2-01)
  - [x] 13-03-PLAN.md — GET /essentials/politicians unauthenticated endpoint (COMP2-02)
  - [x] 13-04-PLAN.md — Expand POST /connect/compass-import with selected_topics (COMP2-03)
- [ ] Phase 14: Compass Admin Backend (0/? plans)
- [ ] Phase 15: Compass Admin React UI (0/? plans)

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | 2/2 | Complete | 2026-02-24 |
| 2. Auth Routes and Account Core | v1.0 | 2/2 | Complete | 2026-02-25 |
| 3. Alpha Enrollment | v1.0 | 3/3 | Complete | 2026-02-25 |
| 4. Compass Routes | v1.0 | 3/3 | Complete | 2026-02-26 |
| 5. Empower Flow | v1.0 | 2/2 | Complete | 2026-02-27 |
| 6. Gems, Roles, and Social Graph | v1.0 | 3/3 | Complete | 2026-02-27 |
| 7. Admin Tool and Calibration Cron | v1.0 | 3/3 | Complete | 2026-02-27 |
| 8. Public Candidate Pages | v1.0 | 2/2 | Complete | 2026-02-28 |
| 9. XP Schema & Core | v1.1 | 2/2 | Complete | 2026-03-04 |
| 10. XP API | v1.1 | 2/2 | Complete | 2026-03-05 |
| 11. Admin Tool XP View | v1.1 | 1/1 | Complete | 2026-03-06 |
| 12. Alpha Hardening | v1.2 | 2/2 | Complete | 2026-03-06 |
| 13. CompassV2 Backend Compatibility | v1.2 | 4/4 | Complete | 2026-03-06 |
| 14. Compass Admin Backend | v1.2 | 0/? | Pending | — |
| 15. Compass Admin React UI | v1.2 | 0/? | Pending | — |

---

## Phase Details: v1.2

### Phase 12: Alpha Hardening

**Goal:** The codebase compiles clean, types are current, and security guarantees are verifiable — so that real Alpha users can be onboarded without hitting type gaps, stale schema assumptions, or auth bypasses.

**Dependencies:** None (prerequisite for all other v1.2 phases)

**Requirements:** HARD-01, HARD-02, HARD-03, HARD-04

**Plans:** 2 plans

Plans:
- [ ] 12-01-PLAN.md — Regenerate Supabase types and verify TypeScript compiles clean
- [ ] 12-02-PLAN.md — JWT revocation integration test and test suite cleanup

**Success Criteria:**

1. `tsc --noEmit` exits 0 with no errors or warnings across the entire backend source tree (including `src/` and `admin/src/`).
2. `supabase gen types typescript` output matches the committed `database.types.ts` byte-for-byte — running the command produces no diff.
3. A Redis-blocklisted JWT is rejected with 401 on the very next request after logout — verified by an integration test that logs out, then immediately calls `GET /api/account/me` with the same token.
4. The architecture test suite (`npm test`) exits 0 with no skipped tests (`xit`, `xdescribe`, `.skip`) and no TODO/FIXME workaround comments in test files.

---

### Phase 13: CompassV2 Backend Compatibility

**Goal:** The three API gaps discovered during CompassV2 bundle analysis are closed, so CompassV2 can fully function against this backend without workarounds.

**Dependencies:** Phase 12 (clean compile baseline)

**Requirements:** COMP2-01, COMP2-02, COMP2-03

**Plans:** 4 plans

Plans:
- [ ] 13-01-PLAN.md — Migrations: inform schema repair, deleted_at, is_candidate, reset and import RPCs
- [ ] 13-02-PLAN.md — DELETE /compass/answers/me endpoint (COMP2-01)
- [ ] 13-03-PLAN.md — GET /essentials/politicians unauthenticated endpoint (COMP2-02)
- [ ] 13-04-PLAN.md — Expand POST /connect/compass-import with selected_topics (COMP2-03)

**Success Criteria:**

1. `DELETE /api/compass/answers/me` returns 200 and subsequently `GET /api/compass/answers` returns an empty array, and `GET /api/compass/selected-topics` returns an empty array — all in a single authenticated user session.
2. `GET /api/essentials/politicians` returns 200 with a non-empty array of active politicians when called with no `Authorization` header (unauthenticated request).
3. `POST /api/connect/compass-import` with a body containing both `calibrations` and `selected_topics` succeeds, and the imported user's selected topics match the submitted array when retrieved via `GET /api/compass/selected-topics`.

---

### Phase 14: Compass Admin Backend

**Goal:** All admin API routes required by the compass admin UI exist and are correctly guarded, so the React UI phase has a complete and tested backend to call.

**Dependencies:** Phase 12 (clean compile baseline)

**Requirements:** CADM-01, CADM-02, CADM-03, CADM-04, CADM-05, CADM-06, CADM-07

**Success Criteria:**

1. `GET /api/admin/compass/topics` returns all topics including those with `is_live = false` — a topic created without setting `is_live` appears in the response.
2. `POST /api/admin/compass/topics` with a `stances` array atomically creates the topic and all stances: if the topic insert succeeds but a stance is malformed, neither record is committed (verified by inspecting DB state after a deliberately bad stance payload).
3. `POST /api/admin/compass/politicians` creates a politician and `PATCH /api/admin/compass/politicians/:id` updates name, office title, photo URL, and active status — each returning the updated record.
4. `GET /api/admin/compass/categories`, `POST /api/admin/compass/categories`, and `PUT /api/admin/compass/topics/:id/categories` all return correct data and each mutation is recorded in the admin action log (verifiable via `GET /api/admin/logs`).

---

### Phase 15: Compass Admin React UI

**Goal:** An admin can seed and manage all compass data (topics, stances, politicians, answers, context, categories) entirely through the admin React app without touching the database directly.

**Dependencies:** Phase 14 (all backend routes exist)

**Requirements:** CADM-08, CADM-09, CADM-10, CADM-11, CADM-12, CADM-13

**Success Criteria:**

1. From the Topics page, an admin can create a new topic with stances and immediately toggle it live — the topic appears in the live topics list visible to users via `GET /api/compass/topics`.
2. On the Topic detail view, an admin can update stance text for any of the 5 values inline and save — the updated text is returned by `GET /api/compass/topics` on next load.
3. From the Politicians page, an admin can create a politician, then navigate to that politician's detail view and set compass answer values for multiple topics and write context (reasoning + sources) for at least one topic — all without a page reload or manual API call.
4. From the Categories page, an admin can create a category and assign it to an existing topic — the topic subsequently appears under that category in `GET /api/compass/categories`.
