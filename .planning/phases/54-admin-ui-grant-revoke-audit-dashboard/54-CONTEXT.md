# Phase 54: Admin UI — Grant/Revoke + Audit Dashboard - Context

**Gathered:** 2026-04-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Admin tool UI for managing scoped role grants and reviewing all role-holder actions. Admins can assign and remove roles from the account detail page (Roles tab) and review all historical grant/revoke events through a filterable global audit dashboard at `/admin/role-audit`. This phase is pure admin frontend over the backend endpoints from Phases 52–53 — no new API endpoints.

</domain>

<decisions>
## Implementation Decisions

### Grant form UX
- Modal triggered from a "Grant Role" button on the Roles tab
- Self-contained modal: role type selector + conditional field (jurisdiction text input OR politician picker depending on role)
- No confirmation step on submit — the filled form is self-documenting
- On success: modal shows brief in-modal "Role granted" message (~1.5s) then auto-closes; Roles tab refreshes with new row visible
- On failure: modal stays open, inline error message below the form ("Failed to grant role. Please try again.")

### Roles tab display
- Slim table layout with columns: Role | Scope | Granted | Actions
- "Scope" column collapses jurisdiction and resource_id into one field with a small label ("Jurisdiction" or "Politician") to distinguish
- Revoke button right-aligned in Actions column
- Clicking Revoke opens a confirmation dialog: "Revoke [role name] for this user? This cannot be undone." with Cancel / Confirm Revoke
- After confirmed revoke: row disappears, brief success toast shown
- On revoke failure: row stays, error toast shown — no optimistic removal

### Audit dashboard filtering
- Filter bar at top of `/admin/role-audit` page with three controls:
  - Role: dropdown of known `feature_scope` enum values
  - Jurisdiction: free-text input (optional)
  - Date range: From / To date inputs
- Filters apply on "Search" button press — not live/auto-apply
- Results table columns: Timestamp | Actor (linked to account detail) | Target User (linked to account detail) | Action | Role | Scope
- Action column color-coded: green for "granted", red for "revoked"
- Default sort: newest first
- Paginated: 25–50 rows per page, Previous/Next controls

### Empty and error states
- Roles tab with no grants: plain "No roles assigned" message with Grant Role button still visible and prominent
- Audit dashboard with no results: plain "No entries match your filters" message
- Loading state for both surfaces: skeleton table rows (no layout shift when data arrives)
- No optimistic updates anywhere — UI only reflects server-confirmed state
  - Grant failure: modal stays open with inline error
  - Revoke failure: row stays, error toast

### Claude's Discretion
- Exact skeleton row count and styling
- Toast positioning and duration
- Politician picker implementation detail (search vs dropdown)
- Pagination page size (25 or 50 — either fine)

</decisions>

<specifics>
## Specific Ideas

- Revoke confirm dialog should include the role name in the dialog text so admins know exactly what they're revoking
- Audit log action column should be visually scannable — color-coded badges (green/red) preferred over plain text

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 54-admin-ui-grant-revoke-audit-dashboard*
*Context gathered: 2026-04-03*
