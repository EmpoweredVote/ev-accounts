# Phase 48: Compliance + End-to-End Verification - Research

**Researched:** 2026-03-24
**Domain:** React routing (accounts admin app), GDPR/ePrivacy cookie classification, SSO smoke testing
**Confidence:** HIGH

## Summary

Phase 48 has two independent deliverables: (1) a `/privacy` page in the accounts admin React
app (`admin/src/`) disclosing the `ev_session` cookie, and (2) a committed smoke test document
at `docs/SSO-SMOKE-TEST.md` that captures manual E2E verification of cross-app SSO.

The `/privacy` page is a new public React route — no auth required, no backend changes, no new
dependencies. The accounts admin app (`accounts.empowered.vote`) is a Vite + React + Tailwind
v4 SPA. Adding the route follows the same pattern as existing public routes (`/login`, `/signup`).
A footer link must appear on all pages. The existing pages (`Login.tsx`, `Signup.tsx`) are
standalone full-screen components with no shared layout wrapper, so the footer link must be added
to each public page individually OR a lightweight shared wrapper must be introduced.

The smoke test document mirrors the existing `docs/SMOKE-TEST-INTEG.md` structure (checklist
format, run metadata, troubleshooting table) but covers browser-based SSO flows rather than
curl-based API calls. All five app production URLs are confirmed from codebase inspection.
The Phase 48 ROADMAP success criteria provide the exact checklist items.

**Primary recommendation:** Build the `/privacy` page as a standalone full-screen component
matching the Login/Signup visual style (no shared layout wrapper needed — just add footer link
inline to each existing public page). Write `docs/SSO-SMOKE-TEST.md` using the INTEG runbook
as a structural template, with Phase 48 success criteria as the checklist.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React Router DOM | already installed | Add `/privacy` route to App.tsx | Already used for all routes |
| Tailwind v4 | already installed | Style the privacy page | Already in use; brand tokens defined |
| React (JSX/TSX) | already installed | Privacy page component | Already used throughout admin app |

### Supporting
None — zero new dependencies required. This phase is pure content + routing work.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Inline footer link per page | Shared layout wrapper | Wrapper is heavier — only 2 public pages need the footer link; inline is simpler |
| Single `/privacy` page (full policy + cookie table) | Separate `/cookies` route | Context.md locked: one page with cookie disclosure as a section |

**Installation:**
```bash
# No new packages required
```

## Architecture Patterns

### Recommended Project Structure
```
admin/src/
├── App.tsx                    # Add Route path="/privacy" (public, no AuthGuard)
├── pages/
│   ├── Login.tsx              # Add footer link to /privacy
│   ├── Signup.tsx             # Add footer link to /privacy
│   └── PrivacyPage.tsx        # New — full privacy policy + cookie table
docs/
└── SSO-SMOKE-TEST.md          # New — reusable E2E SSO smoke test script
```

### Pattern 1: Adding a Public Route in App.tsx

**What:** A route outside all guard wrappers renders without authentication.
**When to use:** Any page that must be accessible without login.

**Example:**
```typescript
// Source: admin/src/App.tsx — existing public routes pattern
// /login and /signup routes are currently outside AuthGuard and AdminGuard blocks.
// /privacy follows the same placement.

import PrivacyPage from './pages/PrivacyPage';

// Inside <Routes> (before the AdminGuard block, alongside /login and /signup):
<Route path="/privacy" element={<PrivacyPage />} />
```

**Current App.tsx structure for reference:**
- `/login` → public
- `/signup` → public
- `*` → redirects to `/login` (catch-all)
- `/privacy` must come BEFORE the `*` catch-all or it will redirect to login

### Pattern 2: Privacy Page Visual Style

**What:** The accounts admin app uses a consistent full-screen centered card layout for
public pages. Login and Signup both use `min-h-screen flex flex-col items-center justify-center bg-gray-50 dark:bg-ev-black`.

**Example (matching Login.tsx style):**
```tsx
// Outer wrapper — matches Login.tsx
<div className="min-h-screen flex flex-col items-center justify-center bg-gray-50 dark:bg-ev-black px-4 py-12">
  {/* Wordmark — matches Login.tsx */}
  <div className="mb-8 text-center space-y-1">
    <h1 className="text-3xl font-bold text-ev-teal dark:text-ev-teal-light tracking-tight">
      empowered.vote
    </h1>
  </div>
  {/* Content card — wider than login for policy text */}
  <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 shadow-sm p-8 w-full max-w-2xl space-y-8">
    {/* ... policy sections ... */}
  </div>
</div>
```

**Brand colors available:** `ev-teal`, `ev-teal-light`, `ev-yellow`, `ev-red`, `ev-black`.
Use `text-ev-teal` for headings, `text-gray-700 dark:text-gray-300` for body.

### Pattern 3: Footer Link on Existing Public Pages

**What:** Login.tsx and Signup.tsx need a Privacy Policy footer link. Both pages already
have small `<p>` link sections at the bottom of their card content.

**Example:**
```tsx
// Add to the bottom of both Login.tsx and Signup.tsx card content
// Login.tsx already has: "Don't have an account? Create one"
// Signup.tsx already has: "Don't have a code? Request access" + "Already have an account? Sign in"
// Pattern: add a small text line after existing link section

<p className="text-center text-sm text-gray-400 dark:text-gray-500 pt-2 border-t border-gray-100 dark:border-gray-800">
  <Link to="/privacy" className="hover:underline">Privacy Policy</Link>
</p>
```

### Pattern 4: Cookie Disclosure Table

**What:** The `ev_session` cookie details as decided in CONTEXT.md.
**Format:** HTML table with six columns.

```tsx
// Cookie table — use Tailwind table classes for styling
<table className="w-full text-sm border-collapse">
  <thead>
    <tr className="border-b border-gray-200 dark:border-gray-700">
      <th>Name</th>
      <th>Purpose</th>
      <th>Domain</th>
      <th>Duration</th>
      <th>Type</th>
      <th>Classification</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td className="font-mono">ev_session</td>
      <td>Session continuity across Empowered Vote apps</td>
      <td className="font-mono">.empowered.vote</td>
      <td>Session (until logout or browser close)</td>
      <td>First-party, HttpOnly, Secure, SameSite=Lax</td>
      <td>Strictly necessary</td>
    </tr>
  </tbody>
</table>
```

**Important note on Duration:** The `ev_session` cookie is actually set with `maxAge: 30 days`
(30 * 24 * 60 * 60 * 1000 ms) per the Phase 44 implementation. However, it functions as a
session cookie in practice because logout actively clears it. The "Session (until logout or
browser close)" description is accurate from a user-visible behavior standpoint — the user
is never aware of the 30-day maxAge because logout always removes it. The CONTEXT.md
decision uses this description. Use it as-is.

### Pattern 5: Smoke Test Document Structure

**What:** `docs/SSO-SMOKE-TEST.md` modeled after `docs/SMOKE-TEST-INTEG.md`.
**Structure:** Overview → Prerequisites → Steps (numbered, with expected results) →
Verification Checklist → Results section → Troubleshooting table.

**Results section format:**
```markdown
## Results

| Field | Value |
|-------|-------|
| Run date | |
| Browser + version | |
| Environment | Production |
| Overall | PASS / FAIL |

### Step-by-step pass/fail
- [ ] Step 1 — Login at accounts.empowered.vote
- [ ] Step 2 — Profile Hub (app.empowered.vote) authenticated
...
```

### Anti-Patterns to Avoid

- **Wrapping `/privacy` in AuthGuard:** The page must be publicly accessible without login.
  Check App.tsx placement — it must be outside all guard wrappers.
- **Forgetting the catch-all redirect:** App.tsx has `<Route path="*" element={<Navigate to="/login" replace />} />`.
  The `/privacy` route MUST appear before this catch-all or it will redirect to login.
- **Adding footer link only to the card, not the page wrapper:** The link should be inside the
  card so it's scrolled into view naturally.
- **Hardcoding contact email without checking codebase:** From codebase inspection, the
  established contact email pattern uses `chris@empowered.vote` for admin (ADMIN_EMAIL env var)
  and `noreply@empowered.vote` for outbound mail. For a data rights/privacy contact, use
  `privacy@empowered.vote` — consistent with the domain pattern. No `privacy@` address was
  found in the codebase; this is Claude's discretion per CONTEXT.md.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Routing | Custom location check | React Router DOM `<Route>` | Already installed, consistent with all other routes |
| Styling | Custom CSS | Tailwind v4 classes already in use | Brand tokens and utility classes already defined |

**Key insight:** This phase is pure content creation — one React component, two route additions,
two footer link additions, and one Markdown document. Zero new infrastructure.

## Common Pitfalls

### Pitfall 1: Route Ordering — Catch-All Overrides Privacy Route

**What goes wrong:** `/privacy` returns 302 redirect to `/login` instead of rendering the page.
**Why it happens:** App.tsx has `<Route path="*" element={<Navigate to="/login" replace />} />`.
React Router v6 matches routes in document order. If `/privacy` is placed AFTER the catch-all,
the catch-all matches first.
**How to avoid:** Place the `/privacy` route alongside `/login` and `/signup` (before any
Guard wrappers and before the catch-all).
**Warning signs:** Navigating to `/privacy` in browser redirects to `/login`.

### Pitfall 2: Smoke Test Duration Description Mismatch

**What goes wrong:** Cookie table says "Session (until logout or browser close)" but a
developer tests and sees a 30-day cookie in DevTools.
**Why it happens:** Phase 44 sets `maxAge: 30 * 24 * 60 * 60 * 1000` (30 days). The cookie
persists beyond browser close in the browser storage until logout clears it.
**How to avoid:** Add a note in the privacy page that the cookie is cleared on logout and is
intended to be treated as a session cookie from a user perspective.
**Warning signs:** Privacy review questions about the 30-day maxAge vs. "session" claim.

### Pitfall 3: Smoke Test Covers Logout from Wrong App

**What goes wrong:** Smoke test logs out from `accounts.empowered.vote` and tries to verify
cookie cleared at all apps. But the success criteria (criterion 3) requires testing single-logout
"from any one app" propagating to all others.
**Why it happens:** Tester assumes logout must originate from accounts.
**How to avoid:** Smoke test step for logout should be initiated from one of the five child apps
(e.g., Profile Hub), then verify `GET /api/auth/session` returns 401 and the cookie is absent.
This proves the logout coordination chain works in both directions.

### Pitfall 4: Inform-Baseline Graceful Degradation Test

**What goes wrong:** Tester skips the graceful degradation check (success criterion 4) because
it requires clearing cookies first.
**Why it happens:** The happy path works, tester considers the test done.
**How to avoid:** Smoke test script must explicitly include a step: "Clear all cookies, visit
each app, verify no broken pages, no redirect loops, Inform-baseline UI renders."
This is a distinct test sequence from the SSO happy path.

### Pitfall 5: SSO-SMOKE-TEST.md Not Written as Reusable Script

**What goes wrong:** Smoke test is written as "things I checked" diary entry, not a reproducible
checklist a different person could run.
**Why it happens:** Document written during live testing rather than scripted in advance.
**How to avoid:** Write the blank script FIRST (Plan 48-02, Task 1), then fill in results as a
separate commit (Task 2 after running the test). Checklist items use `[ ]` not `[x]` in the
blank script.

## Code Examples

### PrivacyPage.tsx — Minimal Structure

```tsx
// New file: admin/src/pages/PrivacyPage.tsx
// Public route — no auth required
import { Link } from 'react-router-dom';

export default function PrivacyPage() {
  return (
    <div className="min-h-screen flex flex-col items-center bg-gray-50 dark:bg-ev-black px-4 py-12">
      <div className="mb-8 text-center">
        <h1 className="text-3xl font-bold text-ev-teal dark:text-ev-teal-light tracking-tight">
          empowered.vote
        </h1>
      </div>
      <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 shadow-sm p-8 w-full max-w-2xl space-y-8">
        <h2 className="text-2xl font-bold text-gray-900 dark:text-white">Privacy Policy</h2>
        {/* ... sections ... */}
        {/* Cookie Disclosure section with table */}
        <p className="text-center text-sm text-gray-500 dark:text-gray-400">
          <Link to="/login" className="text-ev-teal dark:text-ev-teal-light hover:underline">
            Back to sign in
          </Link>
        </p>
      </div>
    </div>
  );
}
```

### App.tsx — Route Addition

```typescript
// Source: admin/src/App.tsx — add alongside existing public routes
import PrivacyPage from './pages/PrivacyPage';

// Inside <Routes>, BEFORE the AdminGuard block and the catch-all *:
<Route path="/login" element={<Login />} />
<Route path="/signup" element={<Signup />} />
<Route path="/privacy" element={<PrivacyPage />} />   // NEW — public, no guard

// Authenticated (any tier) — follows after
<Route element={<AuthGuard />}>
  ...
</Route>
// catch-all stays last
<Route path="*" element={<Navigate to="/login" replace />} />
```

## Five App Production URLs (confirmed from codebase)

| App | URL | SSO Requirements |
|-----|-----|-----------------|
| Profile Hub | `https://app.empowered.vote` | SSO-04 |
| CTC | `https://ctc.empowered.vote` | SSO-05, SSO-06 |
| Essentials | `https://essentials.empowered.vote` | SSO-07, SSO-08 |
| CompassV2 | `https://compass.empowered.vote` | SSO-11, SSO-12 |
| Validation Quests | `https://quests.empowered.vote` | SSO-09, SSO-10 |

Source: `app/src/pages/DashboardPage.tsx` (hub links) and Phase 44-47 SUMMARY files.

## SSO Architecture Summary (for smoke test design)

All five apps implement the same SSO pattern. Understanding this informs which smoke test
steps are meaningful:

**Session inheritance flow:**
1. User logs in at `accounts.empowered.vote`
2. `POST /api/auth/login` response includes `Set-Cookie: ev_session=<refresh_token>; Domain=.empowered.vote; HttpOnly; SameSite=Lax; MaxAge=2592000`
3. Any `*.empowered.vote` app loads → on mount, calls `GET https://accounts.empowered.vote/api/auth/session` with `credentials: 'include'`
4. Server reads `ev_session` cookie, calls `supabaseAdmin.auth.refreshSession()`, rotates cookie, returns `{ access_token, refresh_token }`
5. App stores `access_token`, uses it for subsequent API calls — user appears authenticated

**Logout propagation flow:**
1. User clicks logout in any app
2. App calls `POST https://accounts.empowered.vote/api/auth/logout` with `credentials: 'include'`
3. Server clears `ev_session` cookie (via pre-requireAuth middleware)
4. Server also revokes Supabase session if Bearer token present
5. Other apps: on next page load, `/api/auth/session` returns 401 (no cookie) → unauthenticated state

**Graceful degradation (no session):**
- Profile Hub: redirects to accounts.empowered.vote/login
- CTC: shows public/guest state
- Essentials: renders Inform-baseline (public compass content)
- CompassV2: renders Inform-baseline (public compass content)
- VQ: PrivateRoute returns null while checking, then unauthenticated state; no redirect loops

**What to verify in smoke test:**
- Happy path: login once → all five apps show authenticated state
- Logout propagation: logout from one app → all five show unauthenticated on next visit
- Graceful degradation: clear cookies → all five apps render without errors

## Privacy Policy Content Decisions (Claude's Discretion)

From CONTEXT.md:
- **Contact email for data rights requests:** No `privacy@empowered.vote` address found in
  codebase. Established pattern uses `chris@empowered.vote` (ADMIN_EMAIL) and
  `noreply@empowered.vote` (outbound). Recommend `privacy@empowered.vote` as the dedicated
  data rights contact — consistent with domain pattern, separate from admin notifications.
  Planner should confirm this with user.
- **User rights self-service:** Link to `https://accounts.empowered.vote/profile` for profile
  edits (ProfilePage at `/profile` route) and account settings. The settings page at
  `app/src/pages/settings/` covers notification preferences and account deletion.
- **Visual layout:** Full-width prose sections with `<h3>` subheadings, separated by `<hr>`
  or spacing. Cookie table spans full width of the card (max-w-2xl). Back-to-login link at bottom.

## Open Questions

1. **Contact email for privacy/data requests**
   - What we know: No `privacy@empowered.vote` address exists in codebase. `chris@empowered.vote`
     is the admin notification recipient. `noreply@empowered.vote` is the outbound sender.
   - What's unclear: Is there a specific email Chris wants to use for data access/deletion requests?
   - Recommendation: Planner should default to `privacy@empowered.vote` and note it as a
     fill-in placeholder for Chris to confirm. The domain is verified; the mailbox just needs
     to be set up in Resend or forwarded.

2. **Cookie duration accuracy: "Session" vs. "30 days"**
   - What we know: `ev_session` is set with `maxAge: 30 * 24 * 60 * 60 * 1000` (30 days) per
     Phase 44 implementation. The CONTEXT.md description says "Session (until logout or browser close)."
   - What's unclear: Whether "30 days" or "Session" is more accurate for the privacy policy.
   - Recommendation: Use "30 days" in the Duration column (technically accurate per implementation)
     with a note: "Cleared immediately on logout." This is more precise and avoids a discrepancy
     if regulators or researchers inspect the actual cookie. The CONTEXT.md description was likely
     written before the 30-day maxAge was confirmed.

3. **Settings page URL for user rights self-service link**
   - What we know: `app/src/pages/settings/` exists in the Profile Hub app. No standalone
     settings route was found in the accounts admin app (`admin/src/`).
   - What's unclear: Which URL to direct users to for self-service account settings — the
     Profile Hub settings or a future accounts settings page?
   - Recommendation: Link to `https://app.empowered.vote/settings` (Profile Hub) for self-service
     actions. If that page handles deletion, it's the right target.

## Sources

### Primary (HIGH confidence)
- Read `admin/src/App.tsx` — full routing structure; placement of public vs. guarded routes confirmed
- Read `admin/src/pages/Login.tsx` — exact Tailwind class patterns for public page styling
- Read `admin/src/pages/Signup.tsx` — footer link placement pattern
- Read `admin/src/index.css` — brand color tokens confirmed (ev-teal, ev-teal-light, etc.)
- Read `admin/src/lib/redirect.ts` — trusted domain list (*.empowered.vote)
- Read `app/src/pages/DashboardPage.tsx` (via grep) — five production app URLs confirmed
- Read `.planning/phases/44-01-SUMMARY.md` — cookie implementation details (maxAge 30 days, HttpOnly, SameSite=Lax)
- Read `.planning/phases/44-02-SUMMARY.md` — /api/auth/session endpoint confirmed
- Read `.planning/phases/45-01-SUMMARY.md`, `45-02-SUMMARY.md` — Profile Hub + CTC SSO confirmed
- Read `.planning/phases/46-01-SUMMARY.md`, `46-02-SUMMARY.md` — Essentials + CompassV2 SSO confirmed
- Read `.planning/phases/47-01-SUMMARY.md`, `47-02-SUMMARY.md` — VQ SSO confirmed
- Read `docs/SMOKE-TEST-INTEG.md` — existing smoke test document format and structure

### Secondary (MEDIUM confidence)
- GDPR/ePrivacy "strictly necessary" cookie classification — well-established regulatory framework;
  session authentication cookies universally classified as strictly necessary under both GDPR
  Article 6(1)(b) and ePrivacy Directive Article 5(3) "technical storage" exemption

### Tertiary (LOW confidence)
- `privacy@empowered.vote` as contact email — no existing address found; recommendation only

## Metadata

**Confidence breakdown:**
- React routing/component pattern: HIGH — read actual source files
- Tailwind styling approach: HIGH — read Login.tsx directly; classes are exact
- Five app URLs: HIGH — read from `app/src/pages/DashboardPage.tsx` via grep
- SSO architecture for smoke test design: HIGH — read all four phase summaries
- GDPR "strictly necessary" classification: MEDIUM — standard regulatory interpretation,
  not verified against a specific current official source
- Contact email recommendation: LOW — no codebase precedent found

**Research date:** 2026-03-24
**Valid until:** 2026-04-24 (stable domain — React Router, Tailwind patterns change infrequently)
