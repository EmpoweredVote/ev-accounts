# Requirements: Empowered Accounts

**Defined:** 2026-04-25
**Milestone:** v2.0 Civic Account Experience
**Core Value:** Every user who wants to understand their civic world can do so freely; those who want to participate can do so with trust, identity, and shared purpose — at their own pace, never dragged.

## v2.0 Requirements

### Design Foundation

- [ ] **DSGN-01**: `ev-blue` (#3B82F6) and `ev-navy` (#020618) color tokens defined in `app/src/index.css` (and `ev-blue` in `admin/src/index.css`)
- [ ] **DSGN-02**: Reusable `AuthCard` component — dark rounded card with border, consistent padding, used across all auth and onboarding screens
- [ ] **DSGN-03**: Reusable `AuthInput` component — dark field with label, placeholder, error state, and blue focus ring
- [ ] **DSGN-04**: `PrimaryButton` and `SecondaryButton` shared components — blue primary (full width), dark secondary (full width)
- [ ] **DSGN-05**: `StepProgress` component — "Step X of Y" label + percentage + blue filled progress track
- [ ] **DSGN-06**: `AppNav` component — logo mark + "Civic Platform" wordmark on left; right slot for auth controls

### Authentication

- [ ] **AUTH-01**: `WelcomeScreen` page at `/welcome` — centered "Join to participate" card with Create account, Log in, and "Continue exploring" options; copy is invitational, never pressured
- [ ] **AUTH-02**: `SignupPage` restyled to match Figma — `AppNav`, `StepProgress` (Step 1 of 4), `AuthCard` with dark fields, blue CTA
- [ ] **AUTH-03**: Legal name field retained on `SignupPage` with inline explanation of why it's required ("During Alpha, your identity is verified through our invite network — one person, one voice") and "never shown publicly" note
- [ ] **AUTH-04**: Invite code field has shield icon and inline alpha-trust explanation ("Access is invite-only during Alpha to ensure trusted participation. This trust-based system builds accountability in our community.")
- [ ] **AUTH-05**: "Check your email" confirmation screen restyled — shows email address, magic-link explanation, link to sign in (magic-link flow retained, no OTP)
- [ ] **AUTH-06**: `LoginPage` restyled to match Figma design language — `AppNav`, `AuthCard`, dark fields, blue CTA, "Already have account? Sign In" link

### Onboarding

- [ ] **ONBD-01**: All onboarding steps share `AppNav` and `StepProgress` bar (Step N of 4) as consistent wrapper
- [ ] **ONBD-02**: `PseudonymStep` restyled as "Choose your civic name" — avatar icon, "This is how your voice appears in civic spaces and discussions" copy, `AuthInput` for civic name, Continue + Back
- [ ] **ONBD-03**: `LocationStep` restyled as "Find your civic community" — pin icon, "We use your location to connect you with your local civic space. Learn More." copy, street/city/state/zip fields, Continue + Back (no ZIP-only option)
- [ ] **ONBD-04**: `LocationCelebrationStep` restyled as "You're connected" — green checkmark icon, "We matched you to your civic district and community", three milestone items (Account created ✓, Location matched ✓, Ready to participate ✓), Go to dashboard CTA
- [ ] **ONBD-05**: Existing `WelcomeStep` removed from onboarding flow — `WelcomeScreen` (`/welcome`) handles the pre-entry value pitch; onboarding starts directly at civic name

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

### InformLanding

- [ ] **LAND-01**: `InformLandingPage` component — served at app.empowered.vote root (`/`) for unauthenticated users; authenticated users see `DashboardPage` instead
- [ ] **LAND-02**: Hero section — "Understand your world" headline, subtitle, "No account required" note, feature card grid (Empowered Essentials, Empowered Compass, Treasury Tracker, Fallacy Finders, Empowered Badges)
- [ ] **LAND-03**: "Participate with your community" section — civic spaces icons (Civic Spaces, Common Ground, Symposium), Connected account value prop explained without pressure
- [ ] **LAND-04**: "Join the conversation" bottom section — Create account + Sign in buttons; copy frames Connected as "for those seeking shared solutions", not a funnel
- [ ] **LAND-05**: `AppNav` on InformLanding with Sign In and Create account links in right slot

### Activity Feed API

- [ ] **API-01**: `GET /api/account/me/activity` endpoint — returns last 20 XP transactions for authenticated user: `{ source, amount, description, created_at }` per entry; requires Connected tier

### Bug Fix

- [ ] **FIX-01**: Fix invite code generation in DashboardPage — `optional_name` field value properly included in `POST /api/invites/generate` request body and saved in `invite_codes` record

## v3 Requirements (Deferred)

### Authentication
- **AUTH-V3-01**: OTP email verification flow (6-digit code, 30s resend timer, error state) — deferred; keeping magic-link for v2.0
- **AUTH-V3-02**: ZIP code only option in location step — deferred; full address required for now

### Profile
- **PROF-V3-01**: VR admin dashboard (distribution, holds, outliers) — deferred from v1.9
- **PROF-V3-02**: User-to-user compass compare — deferred from v1.x

## Out of Scope

| Feature | Reason |
|---------|--------|
| OTP email verification | Keeping magic-link flow; OTP requires backend changes and adds complexity without clear Alpha benefit |
| ZIP code only option in location | Full address required for accurate district resolution |
| profile.empowered.vote domain | Profile stays on login.empowered.vote/profile for Alpha; domain split deferred |
| contributor portal reskin | Contributor portal (/contributor) is a separate surface; out of scope for v2.0 |
| admin tool (login.empowered.vote/admin) restyle | Admin-only UI; not user-facing; out of scope |
| Empowered account upgrade flow | Empowerment tier is admin-gated for Alpha; no self-service flow yet |

## Traceability

*To be populated by gsd-roadmapper*

| Requirement | Phase | Status |
|-------------|-------|--------|
| DSGN-01 | Phase 60 | Pending |
| DSGN-02 | Phase 60 | Pending |
| DSGN-03 | Phase 60 | Pending |
| DSGN-04 | Phase 60 | Pending |
| DSGN-05 | Phase 60 | Pending |
| DSGN-06 | Phase 60 | Pending |
| AUTH-01 | Phase 61 | Pending |
| AUTH-02 | Phase 61 | Pending |
| AUTH-03 | Phase 61 | Pending |
| AUTH-04 | Phase 61 | Pending |
| AUTH-05 | Phase 61 | Pending |
| AUTH-06 | Phase 61 | Pending |
| ONBD-01 | Phase 62 | Pending |
| ONBD-02 | Phase 62 | Pending |
| ONBD-03 | Phase 62 | Pending |
| ONBD-04 | Phase 62 | Pending |
| ONBD-05 | Phase 62 | Pending |
| PROF-01 | Phase 63 | Pending |
| PROF-02 | Phase 63 | Pending |
| PROF-03 | Phase 63 | Pending |
| PROF-04 | Phase 63 | Pending |
| PROF-05 | Phase 63 | Pending |
| PROF-06 | Phase 63 | Pending |
| API-01 | Phase 63 | Pending |
| FIX-01 | Phase 63 | Pending |
| LAND-01 | Phase 64 | Pending |
| LAND-02 | Phase 64 | Pending |
| LAND-03 | Phase 64 | Pending |
| LAND-04 | Phase 64 | Pending |
| LAND-05 | Phase 64 | Pending |
| DASH-01 | Phase 65 | Pending |
| DASH-02 | Phase 65 | Pending |
| DASH-03 | Phase 65 | Pending |
| DASH-04 | Phase 65 | Pending |

**Coverage:**
- v2.0 requirements: 34 total
- Mapped to phases: 34
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-25*
*Last updated: 2026-04-25 — initial v2.0 definition*
