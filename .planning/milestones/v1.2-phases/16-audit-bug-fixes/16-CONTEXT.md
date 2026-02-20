# Phase 16: Audit Bug Fixes - Context

**Gathered:** 2026-02-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix integration bugs and code cleanup identified by v1.2 milestone audit. Core items: compass reset route permission fix, help_seen sync with DB, unused import removal. Additionally: relocate reset compass from gear icon to profile dropdown, and add a ? help icon for re-accessing /help.

</domain>

<decisions>
## Implementation Decisions

### Reset compass route
- Move `DELETE /compass/answers/me` from admin middleware group to session-only group in `routes.go`
- Any logged-in user (not just admins) can reset their compass server-side
- No special handling for existing desync state — once the route is accessible, the next reset will work correctly

### Help sync policy
- One-way sync: DB wins always
- If `completed_onboarding` is true in the DB, seed `localStorage.help_seen = "true"` on the client
- Prevents returning users on new devices from re-seeing /help automatically

### Help re-access icon
- Add a `?` icon that navigates to `/help` (the full walkthrough page)
- Always visible (not gated on help_seen or onboarding state)
- Included in this phase alongside the help_seen sync work

### Settings gear / Reset Compass relocation
- Remove the settings gear icon from the compass page entirely
- Move "Reset Compass" to the profile dropdown menu (where admin-only reset lived previously)
- Now available to all logged-in users, not just admins
- Keeps the compass page clean — reset is a rare action

### Unused import cleanup
- Remove unused `Router` import from `App.jsx` line 2

### Claude's Discretion
- Sync timing: Claude decides whether to seed help_seen on every auth check or only on login, based on existing auth flow patterns
- Help icon placement: Claude decides where the ? icon goes based on existing layout (compass page, library page, or nav area)
- Help icon styling: Claude picks icon style consistent with existing design system

</decisions>

<specifics>
## Specific Ideas

- Settings gear is too far from the compass on wide screens — user didn't notice it. Moving to profile dropdown solves discoverability for the rare "reset" action.
- Profile dropdown already had the admin reset — this just makes it available to everyone, which aligns with the route fix.
- The ? icon should be unobtrusive but findable when a user wants to revisit the walkthrough.

</specifics>

<deferred>
## Deferred Ideas

- Spoke inversion persistence across views (Phase 14 deferred cosmetic) — not included
- Help page screenshot sizing improvements (Phase 15 cosmetic) — not included
- SUMMARY.md `requirements_completed` frontmatter (documentation gap) — not included

</deferred>

---

*Phase: 16-audit-bug-fixes*
*Context gathered: 2026-02-19*
