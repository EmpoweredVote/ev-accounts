# Requirements: Empowered Accounts

**Defined:** 2026-04-25
**Milestone:** v2.0 Civic Account Experience + v2.1 Inform Account Tier
**Core Value:** Every user who wants to understand their civic world can do so freely; those who want to participate can do so with trust, identity, and shared purpose — at their own pace, never dragged.

## v2.0 Requirements (Phases 60–65)

### Design Foundation

- [x] **DSGN-01**: `ev-blue` (#3B82F6) and `ev-navy` (#020618) color tokens defined in `app/src/index.css` (and `ev-blue` in `admin/src/index.css`)
- [x] **DSGN-02**: Reusable `AuthCard` component — dark rounded card with border, consistent padding, used across all auth and onboarding screens
- [x] **DSGN-03**: Reusable `AuthInput` component — dark field with label, placeholder, error state, and blue focus ring
- [x] **DSGN-04**: `PrimaryButton` and `SecondaryButton` shared components — blue primary (full width), dark secondary (full width)
- [x] **DSGN-05**: `StepProgress` component — "Step X of Y" label + percentage + blue filled progress track
- [x] **DSGN-06**: `AppNav` component — logo mark + "Civic Platform" wordmark on left; right slot for auth controls

### Authentication

- [x] **AUTH-01**: `WelcomeScreen` page at `/welcome` — centered "Join to participate" card with Create account, Log in, and "Continue exploring" options; copy is invitational, never pressured
- [x] **AUTH-02**: `SignupPage` restyled — `AppNav`, `StepProgress` (Step 1 of 4), `AuthCard` with dark fields, blue CTA; heading "Create your Connected Account"
- [x] **AUTH-03**: Legal name field on `SignupPage` with inline explanation ("During Alpha, your identity is verified through our invite network — one person, one voice"); "never shown publicly" note removed — legal name may surface on Empowered accounts
- [x] **AUTH-04**: Invite code field has shield icon and inline alpha-trust explanation
- [x] **AUTH-05**: "Check your email" screen restyled — shows email address, magic-link explanation, sign-in link
- [x] **AUTH-06**: `LoginPage` restyled — `AppNav`, `AuthCard`, dark fields, blue CTA

### Onboarding

- [x] **ONBD-01**: All onboarding steps share `AppNav` and `StepProgress` bar (Step N of 3) as consistent wrapper
- [x] **ONBD-02**: `PseudonymStep` removed — display_name captured at signup (Phase 61); onboarding starts at location step
- [x] **ONBD-03**: `LocationStep` restyled as "Find your civic community" — pin icon, four `AuthInput` fields, no reveal gate, no Learn More link
- [x] **ONBD-04**: `LocationCelebrationStep` restyled as "You're connected" — green checkmark icon, three milestone items, Go to dashboard CTA
- [x] **ONBD-05**: Existing `WelcomeStep` removed from onboarding flow — `WelcomeScreen` (`/welcome`) handles the pre-entry value pitch

### Profile Page

- [ ] **PROF-01**: `ProfilePage` (admin app, `/profile`) restyled — user's display name as large heading, Level badge + XP progress bar (e.g. "Level 1 — 100 / 1000 XP")
- [ ] **PROF-02**: Gems section displays large colored gem icons (yellow, blue, red) with numeric count beneath each
- [ ] **PROF-03**: Recent Activity section shows last 4 XP transactions (activity name, date, +XP amount in teal)
- [ ] **PROF-04**: Invite section — locked state shows "Reach level 2 to unlock your first referral code"; active state shows invite code with copy button
- [ ] **PROF-05**: Verification Rating displayed as "0 / 150" with explanatory text ("Keep validating to increase your credibility score")
- [ ] **PROF-06**: "Ready to go public?" Empowered upgrade CTA section at page bottom for Connected users

### Dashboard

- [ ] **DASH-01**: `DashboardPage` (app, `/`) redesigned — top "Continue where you left off" card showing last-used feature with Continue button
- [ ] **DASH-02**: Inline stats bar below nav — display name, level badge, XP progress, gem counts, VR score, "View full profile →" link
- [ ] **DASH-03**: Explore features grid — Inform features section (available to all tiers) + Connect features section (Connected+ only; locked/dimmed for Inform tier users)
- [ ] **DASH-04**: "Ready to go public?" Empowered upgrade CTA at page bottom for Connected users

### InformLanding — SKIPPED (2026-05-10)

- [~] **LAND-01** through **LAND-05**: Superseded by `login.empowered.vote/profile`, which already serves as the platform explainer for unauthenticated visitors. No separate `InformLandingPage` will be built. Unauthenticated visits to `app.empowered.vote/` continue to redirect to `login.empowered.vote/login`.

### Activity Feed API

- [x] **API-01**: `GET /api/account/me/activity` endpoint — returns last 20 XP transactions for authenticated user: `{ source, amount, description, created_at }` per entry; requires Connected tier ✓ Phase 63-01

### Bug Fix

- [x] **FIX-01**: Fix invite code generation in DashboardPage — `optional_name` field value properly included in `POST /api/invites/generate` request body ✓ Phase 63-01 (confirmed closed by code inspection)

---

## v2.1 Requirements (Phases 66–68)

**Milestone: Inform Account Tier** — Make the Inform tier a first-class experience with yellow profile, low-friction signup, and an invitational path toward Connected.

**Inform tier rules:**
- Can fully use Inform features (Compass, Essentials)
- Can observe Connected/Empowered features (read-only)
- Cannot participate in Connected features (voting in Symposiums, speaking)
- Can only earn yellow gems (anonymity constraint — no blue/red)
- Compass stances and Essentials last location are remembered

### Backend Schema (IBAK)

- [x] **IBAK-01**: `inform.inform_profiles` table — `user_id UUID PK → public.users`, `yellow_gem_balance INT DEFAULT 0`, `last_essentials_location JSONB`, `created_at TIMESTAMPTZ DEFAULT now()`
- [x] **IBAK-02**: DB trigger auto-creates `inform_profiles` row on every `public.users` INSERT (all signups — Inform and Connected paths)
- [x] **IBAK-03**: `GET /api/account/me` returns `inform_profile: { yellow_gem_balance, last_essentials_location }` for all tiers
- [x] **IBAK-04**: `POST /api/gems/award` routes yellow gem awards to `inform_profiles.yellow_gem_balance` for Inform-tier users (no `connected_profiles`); blue/red gem awards return 422 for Inform-tier users
- [x] **IBAK-05**: `PATCH /api/account/location-hint` — Essentials-callable endpoint that stores last searched location in `inform_profiles.last_essentials_location`; authenticated, Inform-tier only
- [x] **IBAK-06**: Connecting an account (creating `connected_profiles` via `signup_with_invite` RPC) transfers `inform_profiles.yellow_gem_balance` to `connected_profiles.gem_balance_yellow` atomically

### Login Hub (LHUB)

- [ ] **LHUB-01**: `login.empowered.vote` landing shows the existing login form + a "Create an Account" CTA visible to unauthenticated visitors
- [ ] **LHUB-02**: "Create an Account" opens a modal explaining Inform Account constraints — can fully use Inform features, can observe Connected/Empowered features but not participate, can only earn yellow gems

### Inform Signup (ISUP)

- [ ] **ISUP-01**: Signup form (following modal) collects display name ("What should we call you?"), email, password — no invite code field
- [ ] **ISUP-02**: No invite code required or displayed on the Inform signup path
- [ ] **ISUP-03**: Post-signup "Check your email" screen has yellow Inform Account theming
- [ ] **ISUP-04**: After email confirmation, user is redirected to yellow Inform profile at `login.empowered.vote/profile`

### Yellow Inform Profile Page (IPRO)

- [ ] **IPRO-01**: Profile page at `login.empowered.vote/profile` is tier-aware — yellow for Inform, existing teal for Connected, existing for Empowered
- [ ] **IPRO-02**: Inform profile header: display name, "Inform Account" yellow badge/pill, yellow gem balance
- [ ] **IPRO-03**: Compass tile (yellow theme) shows calibration count/status
- [ ] **IPRO-04**: Essentials tile shows last searched location (if any) or prompt to explore Essentials
- [ ] **IPRO-05**: Connected/Empowered feature tiles visible in observable state — lock indicator shown, not hidden, not interactive
- [ ] **IPRO-06**: Subtle "Connect your account" section at page bottom — minimal prominence, framed as "when you're ready"

### Connected Account Explainer (CEXP)

- [ ] **CEXP-01**: Inform Account badge/pill on profile is clickable and opens an informational dialog
- [ ] **CEXP-02**: Explainer dialog covers: what Connected Accounts are, how identity verification works, invite codes in Alpha
- [ ] **CEXP-03**: Dialog includes "I have an invite code" CTA leading to existing Connected signup flow

---

## v3 Requirements (Deferred)

### Authentication
- **AUTH-V3-01**: OTP email verification flow (6-digit code, 30s resend timer, error state) — deferred; keeping magic-link for v2.0
- **AUTH-V3-02**: ZIP code only option in location step — deferred; full address required for now

### Profile
- **PROF-V3-01**: VR admin dashboard (distribution, holds, outliers) — deferred from v1.9
- **PROF-V3-02**: User-to-user compass compare — deferred from v1.x

### Inform Account
- **IBAK-V3-01**: Essentials app integration for `location-hint` endpoint — Essentials calls `PATCH /api/account/location-hint` on Inform user location search; v2.1 ships the endpoint, Essentials wires it up post-v2.1
- **IBAK-V3-02**: Yellow gem earning mechanics — Compass calibration as yellow gem source for Inform users; v2.1 ships gem routing, earning rules defined per feature

## Out of Scope

| Feature | Reason |
|---------|--------|
| OTP email verification | Keeping magic-link flow; OTP adds complexity without clear Alpha benefit |
| ZIP code only in location | Full address required for accurate district resolution |
| profile.empowered.vote domain | Profile stays on login.empowered.vote/profile for Alpha |
| contributor portal reskin | Separate surface; out of scope |
| admin tool (login.empowered.vote/admin) restyle | Admin-only UI; not user-facing |
| Empowered account upgrade flow | Admin-gated for Alpha; no self-service flow yet |
| DNS routing empowered.vote/login → login.empowered.vote | Infrastructure work; deferred |
| Inform account in app.empowered.vote dashboard | Phase 65 (DASH-03) handles tier-aware dashboard; separate from Inform profile at login.empowered.vote |
| Third-party identity verification | Deferred post-Alpha; invite chain is v2 trust mechanism |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DSGN-01 | Phase 60 | Complete |
| DSGN-02 | Phase 60 | Complete |
| DSGN-03 | Phase 60 | Complete |
| DSGN-04 | Phase 60 | Complete |
| DSGN-05 | Phase 60 | Complete |
| DSGN-06 | Phase 60 | Complete |
| AUTH-01 | Phase 61 | Complete |
| AUTH-02 | Phase 61 | Complete |
| AUTH-03 | Phase 61 | Complete |
| AUTH-04 | Phase 61 | Complete |
| AUTH-05 | Phase 61 | Complete |
| AUTH-06 | Phase 61 | Complete |
| ONBD-01 | Phase 62 | Complete |
| ONBD-02 | Phase 62 | Complete |
| ONBD-03 | Phase 62 | Complete |
| ONBD-04 | Phase 62 | Complete |
| ONBD-05 | Phase 62 | Complete |
| PROF-01 | Phase 63 | Pending |
| PROF-02 | Phase 63 | Pending |
| PROF-03 | Phase 63 | Pending |
| PROF-04 | Phase 63 | Pending |
| PROF-05 | Phase 63 | Pending |
| PROF-06 | Phase 63 | Pending |
| API-01 | Phase 63 | Complete |
| FIX-01 | Phase 63 | Complete |
| LAND-01 | Phase 64 | Skipped |
| LAND-02 | Phase 64 | Skipped |
| LAND-03 | Phase 64 | Skipped |
| LAND-04 | Phase 64 | Skipped |
| LAND-05 | Phase 64 | Skipped |
| DASH-01 | Phase 65 | Pending |
| DASH-02 | Phase 65 | Pending |
| DASH-03 | Phase 65 | Pending |
| DASH-04 | Phase 65 | Pending |
| IBAK-01 | Phase 66 | Complete |
| IBAK-02 | Phase 66 | Complete |
| IBAK-03 | Phase 66 | Complete |
| IBAK-04 | Phase 66 | Complete |
| IBAK-05 | Phase 66 | Complete |
| IBAK-06 | Phase 66 | Complete |
| LHUB-01 | Phase 67 | Pending |
| LHUB-02 | Phase 67 | Pending |
| ISUP-01 | Phase 67 | Pending |
| ISUP-02 | Phase 67 | Pending |
| ISUP-03 | Phase 67 | Pending |
| ISUP-04 | Phase 67 | Pending |
| IPRO-01 | Phase 68 | Pending |
| IPRO-02 | Phase 68 | Pending |
| IPRO-03 | Phase 68 | Pending |
| IPRO-04 | Phase 68 | Pending |
| IPRO-05 | Phase 68 | Pending |
| IPRO-06 | Phase 68 | Pending |
| CEXP-01 | Phase 68 | Pending |
| CEXP-02 | Phase 68 | Pending |
| CEXP-03 | Phase 68 | Pending |

**Coverage:**
- v2.0 requirements: 34 total (20 complete, 14 pending)
- v2.1 requirements: 21 total (0 complete, 21 pending)
- Mapped to phases: 55 / 55
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-25 (v2.0), 2026-04-27 (v2.1)*
*Last updated: 2026-04-27 — v2.1 Inform Account Tier requirements added*
