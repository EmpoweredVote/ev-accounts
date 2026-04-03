---
phase: 54-admin-ui-grant-revoke-audit-dashboard
plan: 02
subsystem: ui
tags: [react, typescript, headlessui, tailwind, role-management, audit-log, admin]

# Dependency graph
requires:
  - phase: 54-01
    provides: Backend scope threading, writeRoleAuditLog, getRoleAuditLog endpoint, getAccountDetail enriched with getUserRoles
provides:
  - RolesTab component with scoped grant/revoke UI for account detail page
  - GrantRoleModal with role selector, conditional politician picker (campaign_manager), jurisdiction field
  - RoleAuditPage with filterable paginated audit dashboard at /admin/role-audit
  - Route and sidebar nav wired for role-audit
affects:
  - Any future plan that adds role management UI features
  - Phase 55+ if further role admin is planned

# Tech tracking
tech-stack:
  added: []
  patterns:
    - headlessui Dialog for confirmation dialogs and modals (consistent with PoliticiansPage pattern)
    - Conditional form fields based on role slug (campaign_manager = politician picker, others = jurisdiction text)
    - Derived feature_scope from form state (not shown to user, computed automatically)
    - Skeleton rows (animate-pulse) for table loading states
    - Inline auto-dismiss success messages (setTimeout 2000ms)

key-files:
  created:
    - admin/src/components/RolesTab.tsx
    - admin/src/components/GrantRoleModal.tsx
    - admin/src/pages/admin/RoleAuditPage.tsx
  modified:
    - admin/src/pages/admin/AccountDetailPage.tsx
    - admin/src/App.tsx
    - admin/src/pages/admin/AdminLayout.tsx

key-decisions:
  - "Audit filter uses feature_scope (platform/jurisdiction/resource) not role slug — backend getRoleAuditLog only accepts feature_scope as role filter"
  - "Role slug displayed in audit table from snapshot_after.role_slug JSONB field, falls back to feature_scope"
  - "RolesTab exported Role interface (with scope fields) replaces local Role interface in AccountDetailPage"
  - "Politicians endpoint: /admin/compass/politicians used for politician picker (existing endpoint, returns { politicians } array)"

patterns-established:
  - "Scope display pattern: jurisdiction_geoid non-null → 'Jurisdiction: {value}'; resource_id non-null → 'Resource: {value}'; else 'Platform-wide' in gray"
  - "Modal pattern: load data on open, reset state (slug/geoid/resourceId) on each open, error stays in modal, success auto-closes"

# Metrics
duration: 4min
completed: 2026-04-03
---

# Phase 54 Plan 02: Admin UI Grant/Revoke + Audit Dashboard Summary

**RolesTab with scoped grant modal and revoke confirmation, plus filterable audit dashboard at /admin/role-audit — ROLE-06 and ROLE-07 complete**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-03T16:54:55Z
- **Completed:** 2026-04-03T16:59:13Z
- **Tasks:** 2 (checkpoint pending human verify)
- **Files modified:** 6

## Accomplishments
- RolesTab shows scope per grant (Jurisdiction/Resource/Platform-wide) with Grant Role button and headlessui revoke confirmation dialog
- GrantRoleModal: role dropdown, conditional politician picker for campaign_manager, jurisdiction text field for all others, derived feature_scope
- RoleAuditPage: scope/jurisdiction/date-range filters, paginated table (25/page), color-coded granted/revoked badges, linked actor+target names, skeleton loading
- Route /admin/role-audit registered, "Role Audit" added to sidebar nav

## Task Commits

1. **Task 1: RolesTab + GrantRoleModal + revoke confirmation** - `65c2a61` (feat)
2. **Task 2: RoleAuditPage + route wiring** - `fbc3e18` (feat)

## Files Created/Modified
- `admin/src/components/RolesTab.tsx` - Roles table with scope columns, revoke dialog, grant button
- `admin/src/components/GrantRoleModal.tsx` - Role grant modal with conditional fields and politician picker
- `admin/src/pages/admin/RoleAuditPage.tsx` - Filterable paginated audit dashboard
- `admin/src/pages/admin/AccountDetailPage.tsx` - Replaced inline roles section with RolesTab; removed handleRoleRevoke
- `admin/src/App.tsx` - Added /admin/role-audit route and RoleAuditPage import
- `admin/src/pages/admin/AdminLayout.tsx` - Added "Role Audit" nav link

## Decisions Made
- Backend audit filter is `feature_scope` not `role_slug` — adapted plan's "role dropdown" to scope dropdown (platform/jurisdiction/resource). Role slug is shown per row from `snapshot_after.role_slug`.
- Politicians fetched from `/admin/compass/politicians` (existing endpoint) rather than a hypothetical `/admin/politicians` — same data, already present.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Audit filter dropdown uses feature_scope instead of role slug**
- **Found during:** Task 2 (RoleAuditPage)
- **Issue:** Plan specified role slug dropdown but backend `AuditLogQuerySchema` only accepts `feature_scope` as a filter param. There is no `role_slug` column on `role_audit_log` — only in the JSONB `snapshot_after`.
- **Fix:** Dropdown shows scope categories (All scopes / Platform-wide / Jurisdiction / Resource) instead of individual role slugs. The "Role" display column still reads `snapshot_after?.role_slug`.
- **Files modified:** admin/src/pages/admin/RoleAuditPage.tsx
- **Verification:** tsc + vite build both pass
- **Committed in:** fbc3e18 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 backend alignment)
**Impact on plan:** Necessary alignment with existing backend schema. Audit filter is still useful and correct.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- ROLE-06 and ROLE-07 complete: admin can grant/revoke scoped roles and view full audit trail
- Checkpoint pending: human verification of grant modal, revoke confirmation, and audit dashboard
- After checkpoint approval: Phase 54 plan 02 fully complete

---
*Phase: 54-admin-ui-grant-revoke-audit-dashboard*
*Completed: 2026-04-03*
