---
phase: quick
plan: 001
type: execute
wave: 1
depends_on: []
files_modified: [".planning/quick/001-invite-flow-and-civic-trivia-integration/FINDINGS.md"]
autonomous: true

must_haves:
  truths:
    - "User understands the full invite flow from code generation to Connected tier"
    - "User has a complete catalog of the current API surface"
    - "User has concrete guidance on integrating Civic Trivia Championships"
  artifacts:
    - path: ".planning/quick/001-invite-flow-and-civic-trivia-integration/FINDINGS.md"
      provides: "Comprehensive answers to all 3 user questions"
---

<objective>
Investigate the empowered-accounts codebase to answer three questions, then produce a clear findings document:

1. How does the invite flow work end-to-end? How do users enter an invite code when creating an account?
2. What features/routes are currently integrated with the empowered-accounts system?
3. Can Civic Trivia Championships (a separate app) integrate with this account/admin system, and what would that take?

Purpose: Give the user a complete understanding of their own system's invite mechanics, current API surface, and a concrete integration path for Civic Trivia.
Output: A single FINDINGS.md document with all three answers.
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/STATE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Investigate codebase and produce FINDINGS.md</name>
  <files>.planning/quick/001-invite-flow-and-civic-trivia-integration/FINDINGS.md</files>
  <action>
Read the following files to build a complete picture, then write FINDINGS.md:

**For invite flow understanding:**
- `backend/src/routes/auth.ts` — signup/login (how accounts are created)
- `backend/src/routes/invites.ts` — invite code generation (POST /send), claiming (POST /claim), listing (GET /mine)
- `backend/src/lib/inviteService.ts` — code generation logic, claim RPC, code format (XXXX-XXXX)
- `backend/src/routes/connect.ts` — the Connect verification flow (POST /start claims code + creates session, PATCH /step fills profile, POST /complete finalizes)
- `supabase/migrations/20260225000014_phase3_invite_connect_schema.sql` — schema for invite_codes, invite_chains, verification_sessions, connected_profiles

**For current API surface:**
- `backend/src/index.ts` — all mounted route prefixes
- All route files: auth, account, invites, connect, compass, empower, gems, roles, social, admin, candidates, essentialsCandidates
- `backend/src/middleware/auth.ts` — requireAuth, optionalAuth
- `backend/src/middleware/tierGuards.ts` — requireConnected, requireEmpowered

**For Civic Trivia integration assessment:**
- `backend/src/lib/supabase.ts` — dual client pattern (admin vs user-scoped)
- `backend/src/middleware/auth.ts` — JWT verification using Supabase JWTs
- `backend/src/lib/env.ts` — required environment variables
- `backend/src/routes/admin.ts` — admin API surface

**FINDINGS.md must contain these three sections:**

### Section 1: Invite Flow (End-to-End)
Document the complete user journey:
- Account creation (POST /api/auth/signup — email+password, no invite code required at signup)
- Invite code lifecycle: generation by Connected users (POST /api/invites/send), code format (XXXX-XXXX), max 5 unclaimed codes per user
- Two paths to claim: standalone POST /api/invites/claim OR as part of Connect flow POST /api/connect/start (which claims + creates verification session)
- Connect flow steps: start (claim code) -> profile (fill display_name, legal_name, location, home_address) -> review -> complete (atomic RPC creates connected_profiles row)
- Key design: invite code is NOT required at signup — it is required to START the Connect flow (tier upgrade from Inform to Connected)
- Invite chain tracking: invite_chains table records inviter-invitee relationships, inviter's tolerance_rating affected by invitee behavior

### Section 2: Current API Surface
Catalog every route with method, path, auth requirement, and tier requirement. Group by domain:
- Health: GET /api/health
- Auth: signup, login, logout, complete-onboarding
- Account: GET/PATCH /api/account/me
- Invites: send, claim, mine
- Connect: start, step, complete, status, compass-import
- Compass: topics, categories, answers, answers/batch, selected-topics, progress, politicians, politician answers, politician context
- Empower: (3 POST routes — empower, demote, check eligibility)
- Gems: balance, ledger
- Roles: list, user roles
- Social: connections, follows, blocks, peers
- Admin: dashboard, accounts, invites, roles, compass management, cron log
- Candidates: public slug lookup, answers
- Essentials: candidates by zip

### Section 3: Civic Trivia Integration Assessment
Provide concrete guidance:
- **Option A: Shared Supabase project** — Civic Trivia uses the SAME Supabase instance. Users authenticate once, JWT works across both apps. Civic Trivia adds its own schema (e.g., `trivia.*`). Empowered-accounts middleware can be extracted as a shared npm package or Civic Trivia can verify JWTs directly using the same SUPABASE_JWT_SECRET. This is the simplest path.
- **Option B: Separate Supabase project with SSO** — Each app has its own Supabase project. Would require a shared auth layer (e.g., a central auth service, or Supabase's upcoming multi-project auth). More complex, more isolated.
- **Recommendation:** Option A for Alpha. The existing JWT middleware (`backend/src/middleware/auth.ts`) already verifies Supabase JWTs with issuer/audience checks. Civic Trivia can either: (a) import the same middleware pattern, or (b) call empowered-accounts API directly for user data (GET /api/account/me with the user's JWT).
- **What Civic Trivia gets for free:** User accounts, tier system (Inform/Connected/Empowered), invite system, gem ledger, role system, admin UI for user management.
- **What needs to be built:** Trivia-specific schema (questions, rounds, scores, championships), trivia game API routes, trivia frontend, potentially gem rewards integration (award gems for trivia performance via the existing gem ledger API).
- **Admin integration:** The existing admin UI (Vite+React at /admin) could be extended with a trivia management section, OR Civic Trivia could have its own admin that shares the same requireAdmin middleware pattern.
  </action>
  <verify>
    - FINDINGS.md exists at `.planning/quick/001-invite-flow-and-civic-trivia-integration/FINDINGS.md`
    - Section 1 explains the full invite flow with specific route paths and code format
    - Section 2 lists all API routes (should be 40+ routes across all domains)
    - Section 3 provides two integration options with a clear recommendation
  </verify>
  <done>User has a single document answering all three questions with specific file references, route paths, and actionable integration guidance.</done>
</task>

</tasks>

<verification>
- FINDINGS.md is comprehensive and accurate (cross-referenced against actual route files)
- All route endpoints are cataloged
- Integration guidance is concrete and actionable, not vague
</verification>

<success_criteria>
- User can read FINDINGS.md and fully understand the invite flow without reading source code
- User has a complete API surface catalog they can share with Civic Trivia developers
- User has a clear next step for Civic Trivia integration (Option A recommended)
</success_criteria>

<output>
After completion, the findings document is the deliverable itself. No SUMMARY.md needed for quick tasks.
</output>
