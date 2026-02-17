# Phase 2: Guest-First Auth - Context

**Gathered:** 2026-02-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can take the full compass quiz without creating an account. Guest answers persist in localStorage across browser sessions. After viewing results, a save prompt offers account creation with inline registration. When a guest creates an account, localStorage answers merge to the server (server-wins for existing accounts). "Clear compass" is admin-only, accessible from the profile dropdown.

</domain>

<decisions>
## Implementation Decisions

### Save Prompt
- Appears **after viewing results** — user sees their radar chart first, then gets prompted
- **Modal dialog** initially — if user dismisses, a **persistent bottom banner** replaces it
- Messaging focuses on **saving results** — "Create an account to save your compass results"
- If guest dismisses both modal and banner, show the banner **once more on next visit**, then stop permanently
- The modal includes **inline registration** (email/password fields) — user signs up without leaving the results page

### Guest Experience
- **Subtle nav hint** — a small "Sign in" or "Guest" label in the header area, nothing intrusive
- **Full access** for guests — quiz, results, library, compare all work identically to logged-in users
- **Keep current navigation flow** — same landing behavior, just remove the login gate
- No features are restricted for guests

### Account Merge
- **Silent merge** for new accounts — answers transfer seamlessly, no notification needed
- **Brief notice** when logging into an existing account with different local answers — "Your saved answers have been restored" so user knows local changes didn't persist
- Server-wins strategy is confirmed — server answers always take priority on login

### Admin Controls
- **Confirmation dialog** required before clearing compass — "Are you sure? This will clear all your compass answers."
- Clear wipes **both server and localStorage** — complete reset
- Only **"Clear compass"** is admin-only in this phase — nothing else changes
- Placement: **inline with other profile actions** (logout, etc.) — no special separator

### Claude's Discretion
- Exact nav treatment for guest indicator (sign in button style, placement)
- localStorage management strategy after server sync (clear vs keep as fallback)
- Loading states and error handling during merge/registration
- Toast/notification styling for the "saved answers restored" message

</decisions>

<specifics>
## Specific Ideas

- Save prompt is a two-step nudge: modal first, then banner — respects user choice but gives one more gentle reminder on next visit
- Inline registration in the modal keeps the user on the results page — no redirect to a separate sign-up page
- The overall philosophy is "zero friction to try, gentle nudge to stay" — never block the experience

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-guest-first-auth*
*Context gathered: 2026-02-17*
