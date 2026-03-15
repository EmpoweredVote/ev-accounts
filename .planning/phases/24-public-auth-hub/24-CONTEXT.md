# Phase 24: Public Auth Hub (Login Rebrand + Signup Flow) - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Transform `accounts.empowered.vote` into the universal Connected Account portal. Scope:
1. Rebrand the login page for all-tier users (not admin-first)
2. Add a `/signup` route with invite code, real name, and covenant messaging
3. Tier-based post-login routing with `?redirect=` support
4. Profile page gets an "Admin Panel" link for admin-flagged accounts

Creating the Connected dashboard or Empowered view are out of scope — profile page is the interim destination for both tiers.

</domain>

<decisions>
## Implementation Decisions

### Login page rebrand
- Audience framing: tier-neutral — "Sign in to Empowered Vote" (works for Inform, Connected, Empowered, and Admin)
- Branding: Empowered Vote logo + wordmark only. No tagline or feature callouts.
- "Don't have an account? Create one" link appears below the sign-in button
- Single login page for all users — no separate admin-specific login UI
- Admin access is unlocked from the profile page for accounts with the admin flag (not a separate login surface)

### Signup flow
- Invite/referral code is required to create an account
- "Don't have a code? Request access" fallback path for users without a code (captures email for admin review)
- Real legal name required at signup
- One-account covenant surfaced as an info callout on the form (not a checkbox) — explains: this is your only account, privacy-first, future identity + location verification will be required
- Form structure: Claude's discretion (single vs. multi-step based on field count)
- Fields collected: email, password, legal name, invite code (location/address deferred to profile page)
- Post-signup destination: profile page (so user can finish filling out location etc.) — unless `?redirect=` is present (see routing)

### Post-login routing
- Routing signal priority: `?redirect=` param first, then tier + onboarding state
- If valid `?redirect=` present: send user there immediately (both login and signup)
- If no redirect and `completed_onboarding = false`: send to profile page
- Connected (no redirect, onboarding complete): profile page (Connected dashboard is a future phase)
- Empowered (no redirect): profile page (Empowered view is a future phase)
- Admin flag: profile page — admin panel accessible via link on profile for flagged accounts
- First-time detection: `completed_onboarding = false` on `connected_profiles`

### Redirect param behavior
- Trusted domains: `*.empowered.vote` wildcard (scales as new apps are added; explicit allowlist is maintenance debt)
- Untrusted domains: silently ignored, falls back to default tier routing
- When redirect param is present and valid: show a brief callout on the login/signup page — e.g. "You'll be returned to [app name] after signing in" — builds trust, standard OAuth pattern
- Post-signup with redirect: fires immediately after account creation (no profile page stop)
- Post-signup without redirect and `completed_onboarding = false`: profile page

### Admin panel access (Phase 24 scope)
- React admin tool (`admin.empowered.vote`) stays as a separate app — no structural change
- Profile page adds an "Admin Panel" link/button visible only to admin-flagged accounts
- Admin tool's own internal `/login` page remains as-is (internal operators-only URL, not publicly linked)

### Claude's Discretion
- Single vs. multi-step signup form layout
- Exact copy for the one-account covenant callout
- "Request access" form design (email capture for admin review)
- Loading states and error handling on auth forms
- Exact redirect callout copy and placement on login/signup

</decisions>

<specifics>
## Specific Ideas

- Admin access model: "Admin is a flag beyond Connect/Empower" — not a separate tier, an unlocked capability visible from the profile page
- Redirect notice pattern should feel like standard OAuth flows (Google, GitHub style) — user recognizes "You're signing in to access [app]"
- Signup covenant messaging tone: privacy-first, civic identity, one account per real person, future verification coming — not legalistic, informational

</specifics>

<deferred>
## Deferred Ideas

- **Admin panel merge into accounts app** — Move the React admin tool into `accounts.empowered.vote` as a unified app. Explicitly planned for the next available phase after Phase 24.
- **Connected dashboard** — Post-login destination for Connected users. Profile page is the interim. Dashboard is its own phase.
- **Empowered view** — Post-login destination for Empowered users. Same situation.
- **Address/location in signup form** — User considered adding address collection at signup. Deferred — profile page handles this for now; revisit when identity verification ships.
- **Identity + location verification** — Full KYC/address verification for Connected accounts. Surfaced in signup UI as "coming soon" but not implemented in this phase.

</deferred>

---

*Phase: 24-public-auth-hub*
*Context gathered: 2026-03-14*
