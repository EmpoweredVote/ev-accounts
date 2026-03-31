---
phase: 43-integration-documentation
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - docs/INTEGRATION-GUIDE-v2.md
autonomous: true

must_haves:
  truths:
    - "Chris Andrews' team can find every API endpoint with method, path, auth requirement, and shape"
    - "Team knows SSO redirect flow and JWT ES256 verification approach"
    - "Team knows politician IDs are essentials UUIDs, not inform integers"
    - "Team knows compass value range is 0.5-5.5"
    - "Team knows which schemas exist and which are API-accessible"
    - "Team knows production URLs and anti-patterns to avoid"
  artifacts:
    - path: "docs/INTEGRATION-GUIDE-v2.md"
      provides: "Complete integration reference for partner teams"
      min_lines: 300
  key_links: []
---

<objective>
Produce the v2 integration guide that replaces the v1 guide (empowered-accounts-integration-guide.md) and reflects the post-consolidation state of ev-accounts: new auth model (ES256 JWT, SSO redirect), unified politician IDs (essentials UUIDs), full endpoint inventory, schema map, and anti-patterns.

Purpose: Chris Andrews' team needs a single document to update all partner integrations (CompassV2, Essentials, Treasury Tracker, Read & Rank, etc.) from the old Go-server assumptions to the current ev-accounts API.

Output: `docs/INTEGRATION-GUIDE-v2.md`
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@empowered-accounts-integration-guide.md

Source files to read for endpoint accuracy:
@backend/src/routes/auth.ts
@backend/src/routes/account.ts
@backend/src/routes/connect.ts
@backend/src/routes/essentials.ts
@backend/src/routes/essentialsBrowse.ts
@backend/src/routes/essentialsCandidates.ts
@backend/src/routes/essentialsPoliticians.ts
@backend/src/routes/compass.ts
@backend/src/routes/compassAdmin.ts
@backend/src/routes/admin.ts
@backend/src/routes/gems.ts
@backend/src/routes/xp.ts
@backend/src/routes/social.ts
@backend/src/routes/invites.ts
@backend/src/routes/referral.ts
@backend/src/routes/profile.ts
@backend/src/routes/roles.ts
@backend/src/routes/health.ts
@backend/src/routes/treasury.ts
@backend/src/routes/trivia.ts
@backend/src/routes/vq.ts
@backend/src/routes/empower.ts
@backend/src/routes/meetings.ts
@backend/src/routes/campaignFinance.ts
@backend/src/routes/candidates.ts
@backend/src/routes/staging.ts

Existing docs for reference:
@docs/COMPASSV2-INTEGRATION.md
@docs/ESSENTIALS-INTEGRATION.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Read all route files and produce docs/INTEGRATION-GUIDE-v2.md</name>
  <files>docs/INTEGRATION-GUIDE-v2.md</files>
  <action>
Read every file in `backend/src/routes/` to extract the actual registered endpoints (method, path, middleware like requireAuth/requireAdmin/requireConnected, request body shape, response shape). Also read:
- `backend/src/middleware/` for auth middleware details (JWT verification approach)
- `backend/src/index.ts` or `backend/src/app.ts` for route mounting prefixes
- `empowered-accounts-integration-guide.md` as the v1 baseline to evolve from
- `docs/COMPASSV2-INTEGRATION.md` and `docs/ESSENTIALS-INTEGRATION.md` for existing integration context

Then write `docs/INTEGRATION-GUIDE-v2.md` with these sections:

**1. Overview** — What ev-accounts is, what changed from the Go server era, who this doc is for.

**2. Production URLs** — API (`https://api.empowered.vote`, alias `https://accounts-api.empowered.vote`), Accounts app (`https://accounts.empowered.vote`), Profile app (`https://profile.empowered.vote`). Anti-pattern: do NOT use `ev-backend-h3n8.onrender.com` (Go server is down permanently).

**3. Authentication** — ES256 asymmetric JWT signing. SSO redirect flow: user logs in at `accounts.empowered.vote`, redirected back with `#access_token=` hash fragment. All API calls use `Authorization: Bearer <token>`. JWKS endpoint for verification. No session cookies for API auth. Include the JWKS URL from the Supabase project.

**4. Tier System** — Inform/Connected/Empowered, tier = child record presence. Which endpoints require which tier.

**5. Schema Inventory** — Table: schema name, purpose, API-accessible or internal-only. Schemas: `public`, `connect`, `empower`, `inform`, `essentials`, `validation_quests`, `transparent_motivations`, `treasury`. Anti-pattern: do NOT use `supabaseAdmin.schema('essentials')` via PostgREST — essentials is not in the exposed schema list, use `pool.query()`.

**6. Unified Politician IDs** — All politician references use `essentials.politicians` UUIDs. The old `inform.politicians` integer IDs are deprecated. Bridge table `essentials.politician_inform_bridge` exists for legacy mapping. Anti-pattern: do NOT use inform integer IDs.

**7. Compass Value Range** — Values are 0.5 to 5.5 (half-step scale), NOT 0-5 or 1-5 as in the old system.

**8. Endpoint Inventory** — Group by route file / domain area. For each endpoint: `METHOD /api/path` — auth requirement (none, requireAuth, requireConnected, requireAdmin), brief description, request body shape (if POST/PUT/PATCH), response shape. Cover ALL route files. Use tables or definition lists for readability.

**9. Anti-Patterns** — Consolidated list of things NOT to do, with the "why" for each:
  - Do not use the Go server URL
  - Do not use inform.politicians integer IDs
  - Do not chain JS awaits for multi-table writes — use RPCs
  - Do not call supabaseAdmin.schema('essentials') via PostgREST
  - Do not assume compass values are integers or 0-5 range

**10. Migration Checklist** — Bullet list: steps for a partner app to migrate from Go-server integration to ev-accounts integration.

Write in a direct, scannable style. Use tables for endpoint inventories. Keep anti-patterns inline at relevant sections AND collected in the dedicated section.
  </action>
  <verify>
1. File exists: `ls docs/INTEGRATION-GUIDE-v2.md`
2. Contains all 7 required coverage areas: auth model, unified politician IDs, compass value range, schema inventory, endpoint inventory, anti-patterns, URLs
3. Grep for at least 20 distinct endpoint paths: `grep -c "GET\|POST\|PUT\|PATCH\|DELETE" docs/INTEGRATION-GUIDE-v2.md` should be >= 20
4. Anti-patterns present: grep for "Do not" or "do NOT" — should have at least 5 matches
5. No references to the Go server URL as a valid endpoint
  </verify>
  <done>
docs/INTEGRATION-GUIDE-v2.md exists with 300+ lines, covers all 7 required areas from the phase 43 success criteria, includes accurate endpoint paths read from actual route files, and is self-contained (readable without source code).
  </done>
</task>

</tasks>

<verification>
- `docs/INTEGRATION-GUIDE-v2.md` exists and is 300+ lines
- All 7 coverage areas from phase 43 success criteria are present
- Endpoint paths match actual registered routes in backend/src/routes/
- Anti-patterns are clearly called out
- Document is self-contained — a developer can use it without reading source code
</verification>

<success_criteria>
Chris Andrews' team can read INTEGRATION-GUIDE-v2.md and update any partner integration from Go-server state to ev-accounts state without reading source code or asking clarifying questions.
</success_criteria>

<output>
After completion, create `.planning/quick/013-phase-43-integration-documentation-for-chri/013-SUMMARY.md`
</output>
