# Phase 58: Contributor Portal - Context

**Gathered:** 2026-04-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Build a Contributor Portal for role-holders inside the existing `/app` (profiles.empowered.vote) React app — a dedicated "Contributor" tab in the Profile Hub that shows active role grants on a dashboard and routes to scoped editing UIs for each role type (Compass, Essentials, Campaign Manager equivalent). Auth enforcement, API endpoints, and backend role logic are already built in prior phases; this phase is purely the frontend workspace.

</domain>

<decisions>
## Implementation Decisions

### App Scaffolding
- **Location**: Inside `/app` (profiles.empowered.vote) — NOT a new subdomain or Vite app
- **No `contributors.empowered.vote`**: Deferred/abandoned in favor of integrating into the Profile Hub
- **Entry point**: A dedicated "Contributor" tab in the Profile Hub tab bar
- **Tab visibility**: Always visible to all logged-in users — but disabled/locked for users with no active grants
- **Locked state**: Shows an "encourage + contact link" state — brief explanation of contributor roles and how to get access (not just a cold empty state)

### Dashboard Design
- **Layout**: Card-based — one card per role grant
- **Card content** (all four shown):
  - Role type display name
  - Jurisdiction scope (e.g., "Los Angeles County" or "Unrestricted")
  - Grant date and who granted it
  - CTA button to open that editor (primary action)
- **Design approach**: Use `ui-ux-pro-max` skill during implementation for card layout and visual design
- **Multiple grants**: Each grant gets its own card — users with multiple grants see multiple cards

### Role Editor Navigation
- **Opening an editor**: Clicking the CTA navigates to a dedicated route (e.g., `/contributor/compass-editor`, `/contributor/campaign-manager`, `/contributor/essentials-editor`)
- **Back navigation**: Standard back button returns to the Contributor tab dashboard
- **Multi-grant switching**: User goes back to the dashboard to switch between editors — no in-editor switcher
- **Scope**: All three editor types are implemented in this phase (Compass, Campaign Manager, Essentials) — not stubs

### Scope Enforcement UX
- **Jurisdiction badge**: A visible scope badge in the editor header at all times (e.g., "Showing: Los Angeles County") — set expectations upfront, never ambiguous
- **Campaign Manager view**: Shows a single-item politician list (consistent layout with other editors), user clicks through to the stance editor — does NOT land directly on the editor
- **Save feedback**: Toast notification on successful save

### Role Display Names (RESOLVED)
- `compass_stance_editor` → **"Compass Editor"**
- `campaign_manager` → **"Candidate Coordinator"**
- `essentials_data_editor` → **"Essentials Editor"**
- Do NOT use "Campaign Manager" anywhere in the UI — always "Candidate Coordinator"

### Claude's Discretion
- Toast design (duration, position, style) — follow existing patterns in `/app`
- Route structure within `/contributor/*` — Claude organizes these sensibly
- Locked tab state visual design — Claude implements appropriate disabled styling
- Loading/skeleton states for dashboard cards

</decisions>

<specifics>
## Specific Ideas

- Use `ui-ux-pro-max` skill during the card design portion — user explicitly requested this for the dashboard cards
- "Encourage + contact link" empty state — not a cold "you have no roles" message; should feel welcoming and explain contributor roles
- Scope badge pattern inspired by the success criteria spec: editor views must never show data outside the user's assigned jurisdiction, and this should be visually obvious
- Campaign Manager's single-item list is intentional consistency (not a skip-to-editor shortcut) — keeps the UI pattern uniform across role types

</specifics>

<deferred>
## Deferred Ideas

- **Admin action tracking / audit log** — tracking contributor edits for admin review is a new capability; belongs in its own phase. Every save action by a role-holder should eventually be logged for admin oversight. Capture for backlog.
- **`contributors.empowered.vote` subdomain** — decided against; contributor workspace lives inside profiles.empowered.vote instead.
- **Role terminology overhaul** — user flagged that "Campaign Manager" is a real-world job title that may create confusion. Renaming the underlying role keys (backend) is out of scope here, but the question of Empowered-specific terminology for ALL role types (display names) should be resolved as a separate design decision before Phase 58 implementation begins. Could be a quick `/gsd:quick` task.

</deferred>

---

*Phase: 58-contributor-portal*
*Context gathered: 2026-04-03*
