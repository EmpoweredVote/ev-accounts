---
phase: quick
plan: "019"
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/quick/019-rename-accounts-to-login-empowered-vote/INFRA-CHECKLIST.md
  - app/src/components/AuthGuard.tsx
  - app/src/pages/DashboardPage.tsx
  - backend/src/routes/auth.ts
  - admin/src/pages/PrivacyPage.tsx
autonomous: true

must_haves:
  truths:
    - "Unauthenticated profile/app users are redirected to login.empowered.vote, not accounts.empowered.vote"
    - "Admin panel link in DashboardPage points to login.empowered.vote/admin"
    - "Access request notification email links to login.empowered.vote/admin/access-requests"
    - "Privacy page display text says login.empowered.vote, not accounts.empowered.vote"
    - "Infrastructure checklist documents all manual steps needed before deploy"
  artifacts:
    - path: ".planning/quick/019-rename-accounts-to-login-empowered-vote/INFRA-CHECKLIST.md"
      provides: "Manual infrastructure steps for user to complete before code deploys"
    - path: "app/src/components/AuthGuard.tsx"
      contains: "login.empowered.vote"
    - path: "app/src/pages/DashboardPage.tsx"
      contains: "login.empowered.vote"
    - path: "backend/src/routes/auth.ts"
      contains: "login.empowered.vote"
    - path: "admin/src/pages/PrivacyPage.tsx"
      contains: "login.empowered.vote"
  key_links:
    - from: "app/src/components/AuthGuard.tsx"
      to: "login.empowered.vote"
      via: "window.location.href redirect"
      pattern: "login\\.empowered\\.vote/login"
---

<objective>
Rename accounts.empowered.vote to login.empowered.vote across all runtime code references. Produce an infrastructure checklist the user must complete BEFORE deploying the code changes (DNS, Render, Supabase Auth, CORS).

Purpose: The admin/auth frontend is moving from accounts.empowered.vote to login.empowered.vote. accounts.empowered.vote stays alive as an alias during transition, but all code references should point to the new canonical domain.

Output: INFRA-CHECKLIST.md + 4 updated source files, committed atomically.

IMPORTANT: Infrastructure changes (Task 1 checklist) MUST be completed by the user BEFORE the code from Task 2 is deployed. The code changes are safe to commit and push, but the Render deploy must not go live until DNS + Render custom domain + Supabase Auth + CORS are configured.
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@app/src/components/AuthGuard.tsx
@app/src/pages/DashboardPage.tsx
@backend/src/routes/auth.ts
@admin/src/pages/PrivacyPage.tsx
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create INFRA-CHECKLIST.md documenting manual pre-deploy steps</name>
  <files>.planning/quick/019-rename-accounts-to-login-empowered-vote/INFRA-CHECKLIST.md</files>
  <action>
Create INFRA-CHECKLIST.md with the following content. This is a manual checklist the user must complete BEFORE deploying the code changes. Use markdown checkbox format.

The checklist must cover these 4 infrastructure steps in order:

1. **DNS: Add login.empowered.vote CNAME**
   - Go to DNS provider (likely Cloudflare or registrar)
   - Add a CNAME record for `login.empowered.vote` pointing to the same target as `accounts.empowered.vote` (the Render static site hostname)
   - Keep `accounts.empowered.vote` CNAME in place (alias during transition)
   - Wait for DNS propagation (check with `dig login.empowered.vote` or `nslookup login.empowered.vote`)

2. **Render: Add login.empowered.vote as custom domain**
   - Go to Render Dashboard -> the admin static site service
   - Settings -> Custom Domains -> Add `login.empowered.vote`
   - Render will auto-provision TLS certificate
   - Verify: visit `https://login.empowered.vote` in browser -- should serve the same admin/login app
   - Keep `accounts.empowered.vote` as a custom domain (alias)

3. **Supabase Auth: Update redirect allow-list and Site URL**
   - Go to Supabase Dashboard -> Authentication -> URL Configuration
   - Add `https://login.empowered.vote` and `https://login.empowered.vote/**` to Redirect URLs (keep existing `accounts.empowered.vote` entries)
   - Update Site URL from `https://accounts.empowered.vote` to `https://login.empowered.vote`

4. **Render API: Add login.empowered.vote to CORS_ORIGIN**
   - Go to Render Dashboard -> the ev-accounts-api service
   - Environment -> edit `CORS_ORIGIN` env var
   - Add `https://login.empowered.vote` to the comma-separated list (keep all existing entries including `https://accounts.empowered.vote`)
   - Trigger a manual deploy or wait for next deploy to pick up the env var change

Include a "Verification" section at the bottom:
- Visit `https://login.empowered.vote/login` -- should load the login page with valid TLS
- Visit `https://accounts.empowered.vote/login` -- should still work (alias)
- Open browser dev tools Network tab, confirm no CORS errors when the page makes API calls

Include a note: "Once all 4 steps are verified, the code changes in Task 2 are safe to deploy."

Also include a "Post-Migration Cleanup (Later)" section noting:
- Documentation files (docs/*.md) reference `accounts.empowered.vote` extensively -- update in a follow-up pass
- Planning files (.planning/**) contain historical references -- leave as-is (they are historical records)
- Comment in `app/src/App.tsx:82` mentions `accounts.empowered.vote` -- cosmetic, update if desired
- Eventually remove `accounts.empowered.vote` DNS/Render/Supabase/CORS entries once all external consumers have updated
  </action>
  <verify>Read the file. Confirm it has all 4 infrastructure steps with checkboxes, a verification section, and a post-migration cleanup section.</verify>
  <done>INFRA-CHECKLIST.md exists with complete, actionable manual steps the user can follow before deploying.</done>
</task>

<task type="auto">
  <name>Task 2: Update all 4 runtime code references from accounts.empowered.vote to login.empowered.vote</name>
  <files>
    app/src/components/AuthGuard.tsx
    app/src/pages/DashboardPage.tsx
    backend/src/routes/auth.ts
    admin/src/pages/PrivacyPage.tsx
  </files>
  <action>
Make exactly 4 targeted string replacements. Each is a single-line change:

1. **app/src/components/AuthGuard.tsx line 18** -- Change:
   `window.location.href = \`https://accounts.empowered.vote/login?redirect=${returnUrl}\``
   to:
   `window.location.href = \`https://login.empowered.vote/login?redirect=${returnUrl}\``

2. **app/src/pages/DashboardPage.tsx line 285** -- Change:
   `href="https://accounts.empowered.vote/admin"`
   to:
   `href="https://login.empowered.vote/admin"`

3. **backend/src/routes/auth.ts line 502** -- Change:
   `https://accounts.empowered.vote/admin/access-requests`
   to:
   `https://login.empowered.vote/admin/access-requests`

4. **admin/src/pages/PrivacyPage.tsx line 24** -- Change:
   `(accounts.empowered.vote)`
   to:
   `(login.empowered.vote)`

After making changes, run these verification commands:
- `cd C:/EV-Accounts && npx tsc --noEmit --project app/tsconfig.json 2>&1 | head -20` (app type check)
- `cd C:/EV-Accounts && npx tsc --noEmit --project admin/tsconfig.json 2>&1 | head -20` (admin type check)
- `cd C:/EV-Accounts && npx tsc --noEmit --project backend/tsconfig.json 2>&1 | head -20` (backend type check)

These are pure string literal changes so type checks should pass cleanly.

Do NOT change any other files. The many references in docs/, .planning/, and script comments are intentionally left for a follow-up pass (documented in INFRA-CHECKLIST.md).
  </action>
  <verify>
Run: `grep -rn "accounts\.empowered\.vote" app/src/components/AuthGuard.tsx app/src/pages/DashboardPage.tsx backend/src/routes/auth.ts admin/src/pages/PrivacyPage.tsx`
This should return ZERO results. If any match is found, the replacement was missed.

Then run: `grep -rn "login\.empowered\.vote" app/src/components/AuthGuard.tsx app/src/pages/DashboardPage.tsx backend/src/routes/auth.ts admin/src/pages/PrivacyPage.tsx`
This should return exactly 4 results (one per file).

TypeScript compilation must pass for all 3 projects (app, admin, backend).
  </verify>
  <done>All 4 runtime references updated from accounts.empowered.vote to login.empowered.vote. Zero references to the old domain remain in these 4 files. TypeScript compiles cleanly.</done>
</task>

</tasks>

<verification>
1. `grep -rn "accounts\.empowered\.vote" app/src/components/AuthGuard.tsx app/src/pages/DashboardPage.tsx backend/src/routes/auth.ts admin/src/pages/PrivacyPage.tsx` returns nothing
2. `grep -rn "login\.empowered\.vote" app/src/components/AuthGuard.tsx app/src/pages/DashboardPage.tsx backend/src/routes/auth.ts admin/src/pages/PrivacyPage.tsx` returns 4 matches
3. TypeScript compiles for app, admin, and backend
4. INFRA-CHECKLIST.md exists and is complete
</verification>

<success_criteria>
- INFRA-CHECKLIST.md documents all 4 manual infrastructure steps with clear instructions
- All 4 runtime code references changed from accounts.empowered.vote to login.empowered.vote
- Zero remaining accounts.empowered.vote references in the 4 modified source files
- TypeScript compilation passes for all 3 projects
- Both tasks committed atomically in a single commit
</success_criteria>

<output>
After completion, create `.planning/quick/019-rename-accounts-to-login-empowered-vote/019-SUMMARY.md`
</output>
