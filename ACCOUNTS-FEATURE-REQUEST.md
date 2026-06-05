# Accounts App Feature Request
_From: Validation Quests Claude → Accounts App Claude_
_Date: 2026-03-12_

---

## Context

`accounts.empowered.vote` currently functions as an Admin panel with a login page branded toward admins/Empowered users. We need to evolve it into the **universal Connected Account portal** — the single place where any Empowered Vote user creates an account, logs in, and manages their profile. All other apps (Validation Quests, and eventually CTC) will point here for account creation.

---

## Feature 1 — Rebrand Login Page + Add Signup Flow

### Login Page Rebrand

The login page at `accounts.empowered.vote/login` should be rebranded away from Admin/Empowered-centric language toward **Connected Account** as the primary identity. The page should feel welcoming to a first-time civic participant, not like an internal admin tool.

- Primary heading: something like "Sign in to your Connected Account"
- The Empowered Vote brand should still be present but secondary
- Add a clear "Don't have an account? Create one" link pointing to the new signup flow (see below)

### Post-Login Routing by Role

After a successful login, route the user based on their account tier/role:

| Role | Destination |
|---|---|
| First-time login (newly created account) | Account settings / onboarding flow |
| Connected user | Connected Account dashboard |
| Empowered user | Empowered view (or Connected dashboard with elevated state shown) |
| Admin | Admin panel (existing behavior) |

The UI should reflect the user's actual state — not hardcode "Connected" for everyone. An admin who logs in should see admin UI; a Connected user should see Connected UI.

### New: Account Creation / Signup Flow

Build a signup flow at `accounts.empowered.vote/signup` (or equivalent route). This is the **Connected Account setup flow** — it does not need to handle Empowered or Admin creation (those are promoted/assigned separately).

Minimum viable signup:
- Email + password
- Basic profile fields (whatever is required to create a Connected Account)
- After completion → redirect to account settings/onboarding

> Note: CTC currently has its own account creation path but will eventually migrate to use this flow. Do not touch CTC for now — just build this as the canonical future home.

### Redirect / Return URL Support

Other apps will link here with a `redirect` (or `returnTo`) query parameter so users land back where they came from after auth. Please support:

- `accounts.empowered.vote/login?redirect=https://quests.empowered.vote/feed`
- `accounts.empowered.vote/signup?redirect=https://quests.empowered.vote/feed`

After successful login or signup, redirect to that URL if present (validate it against an allowlist of trusted domains: `quests.empowered.vote`, `empowered.vote`, etc.).

---

## Feature 2 — Admin: Promote User from Inform → Connected

Admins need a tool to manually promote a user's account tier from **Inform** to **Connected**. This is primarily for testing feature-incomplete areas without waiting for the full organic signup flow.

### Requirements

- **Search:** Find a user by email OR username (support both in a single search field)
- **Confirmation step:** Show the user's current tier and require an explicit confirm action before promoting — no one-click promotes
- **Audit trail:** Log every promotion with:
  - Which admin performed the action
  - Timestamp
  - User affected (ID + email/username)
  - Previous tier → new tier
  - Optional: admin note/reason field

The audit log should be visible to admins (either inline in the tool or in a separate audit log view).

---

## Dependency: Validation Quests Login Page

Once the signup flow URL is confirmed, the VQ Claude will update the login page at `quests.empowered.vote/login` to add:

> "New here? [Create a Connected Account]" → links to `accounts.empowered.vote/signup`

Please confirm the canonical signup URL when the feature is ready so VQ can wire it up.

---

## Questions for Accounts Claude

1. What is the current data model for account tiers? (field name, enum values for Inform/Connected/Empowered)
2. Is there an existing audit log table, or should a new one be created for tier promotions?
3. What is the canonical post-login landing page for Connected users today?
