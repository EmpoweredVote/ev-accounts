# Phase 54: Admin UI — Grant/Revoke + Audit Dashboard - Research

**Researched:** 2026-04-03
**Domain:** React admin UI (Vite + React + Tailwind v4 + @headlessui/react), Express backend endpoint additions
**Confidence:** HIGH

## Summary

Phase 54 is primarily a frontend phase building two surfaces: a Roles tab inside `AccountDetailPage` and a new `/admin/role-audit` global dashboard. However, codebase analysis reveals **three backend gaps** that must be closed before the frontend can work. The existing grant/revoke endpoints do not accept scope fields (`feature_scope`, `jurisdiction_geoid`, `resource_id`). The `admin_get_account_detail` RPC does not return scope columns in its roles array. No `role_audit_log` read endpoint exists. All three gaps require backend work first.

The standard admin UI patterns are well-established in this codebase. `@headlessui/react` v2 is already installed and used in `PoliticiansPage.tsx` for dialogs. Tables with skeleton loading, pagination (Previous/Next with `{ page, pages, total }`), and confirmation dialogs all have existing reference implementations. Modals use `fixed inset-0 bg-black/50 z-50 flex items-center justify-center` overlay pattern. The `apiFetch` wrapper handles auth headers automatically.

**Primary recommendation:** Structure the work as two plans — Plan 01 closes the backend gaps (3 endpoint/RPC changes), Plan 02 builds the frontend. The frontend plan cannot proceed until Plan 01 is complete.

## Standard Stack

No new libraries. All tools are already in the project.

### Core (already in place)
| Tool | Version | Purpose | Notes |
|------|---------|---------|-------|
| React + Vite | (existing) | Admin SPA | Tailwind v4, TypeScript strict |
| `@headlessui/react` | ^2.2.9 | Modal dialogs | Already used in PoliticiansPage |
| `apiFetch` | project lib | API calls with auth | `admin/src/lib/api.ts` |
| `react-router-dom` | (existing) | Routing | `Link` for account detail links |
| Tailwind v4 | (existing) | Styling | `ev-red`, `ev-teal`, `ev-yellow` tokens |

**No new npm installs required.**

## Architecture Patterns

### Backend Gaps to Close First

#### Gap 1: Grant/revoke endpoints do not accept scope fields

Current `RoleActionSchema` in `admin.ts`:
```typescript
const RoleActionSchema = z.object({
  user_id: z.string().uuid(),
  role_slug: z.string().min(1),
  // MISSING: feature_scope, jurisdiction_geoid, resource_id
});
```

The `grant_role` RPC signature (from migration 047):
```sql
public.grant_role(p_user_id uuid, p_role_slug text,
  p_feature_scope text DEFAULT 'platform',
  p_jurisdiction_geoid text DEFAULT NULL,
  p_resource_id text DEFAULT NULL)
```

`adminGrantRole` and `adminRevokeRole` in `adminService.ts` also only pass `userId` and `roleSlug` — they do not forward scope params. Both the service functions and the route schema need updating.

#### Gap 2: `admin_get_account_detail` RPC returns roles without scope fields

Current roles query inside the RPC (migration 025):
```sql
SELECT ur.role_id, r.slug, r.name, ur.granted_at
FROM public.user_roles ur
JOIN public.roles r ON r.id = ur.role_id
WHERE ur.user_id = p_user_id AND ur.revoked_at IS NULL
```

Missing: `ur.feature_scope`, `ur.jurisdiction_geoid`, `ur.resource_id`. The Roles tab needs these to show the Scope column and to pass the right params to the revoke call. Options:
- Add a dedicated `GET /api/admin/accounts/:userId/roles` endpoint using `getUserRoles()` from `roleService.ts` (already returns scope fields)
- Update the RPC to include scope columns

The simpler path is a new endpoint — `getUserRoles(userId)` already returns the full shape with scope fields, and avoiding RPC modification reduces migration risk.

#### Gap 3: No `role_audit_log` read endpoint exists

The `public.role_audit_log` table exists (migration 047) with columns:
`id, actor_id, target_user_id, feature_scope, jurisdiction_geoid, resource_id, action, target_type, target_id, fields_changed, snapshot_after, created_at`

Indexes exist on `actor_id`, `target_user_id`, `feature_scope`, `created_at DESC`.

Needed: `GET /api/admin/role-audit?feature_scope=&jurisdiction_geoid=&from=&to=&page=` returning paginated results with actor display name (need a join to `public.users` for `display_name`).

**Note:** There is a separate `public.admin_audit_log` (used by `logAdminAction`) vs `public.role_audit_log` (Phase 52 schema). Phase 54's audit dashboard reads `role_audit_log`, not `admin_audit_log`.

### Recommended File Structure

```
backend/src/
├── routes/
│   └── admin.ts               # MODIFIED: grant/revoke scope fields + GET /role-audit endpoint
├── lib/
│   └── adminService.ts        # MODIFIED: adminGrantRole/adminRevokeRole scope params + listRoleAuditLog fn
admin/src/pages/admin/
├── AccountDetailPage.tsx      # MODIFIED: Roles tab — table with scope, Grant Role modal, Revoke confirm dialog
└── RoleAuditPage.tsx          # NEW: global audit dashboard at /admin/role-audit
admin/src/
└── App.tsx                    # MODIFIED: add /admin/role-audit route + nav item in AdminLayout
```

### Pattern 1: Modal with @headlessui/react v2 (Dialog)

Reference implementation from `PoliticiansPage.tsx`:
```typescript
// Source: admin/src/pages/admin/PoliticiansPage.tsx
import { Dialog, DialogPanel, DialogTitle } from '@headlessui/react';

{isCreateOpen && (
  <Dialog open={isCreateOpen} onClose={() => setIsCreateOpen(false)} className="relative z-50">
    <div className="fixed inset-0 bg-black/50" aria-hidden="true" />
    <div className="fixed inset-0 flex items-center justify-center p-4">
      <DialogPanel className="bg-white dark:bg-gray-900 rounded-lg shadow-xl p-6 max-w-md w-full">
        <DialogTitle>...</DialogTitle>
        {/* form contents */}
      </DialogPanel>
    </div>
  </Dialog>
)}
```

The promote modal in `AccountDetailPage.tsx` uses a simpler inline pattern (no `Dialog` component):
```typescript
// Source: admin/src/pages/admin/AccountDetailPage.tsx (line 1007)
{showPromoteModal && (
  <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center">
    <div className="bg-white dark:bg-gray-900 rounded-lg shadow-xl p-6 max-w-md w-full mx-4">
```

Either approach works. The `@headlessui/react` Dialog is cleaner and handles focus trapping/escape-key closing automatically — use it for the Grant Role modal. The inline pattern works fine for the Revoke confirmation since it can be an inline conditional in the table row.

### Pattern 2: Skeleton loading (existing pattern)

```typescript
// Source: admin/src/pages/admin/AccountDetailPage.tsx (line 841)
{promotionHistoryLoading ? (
  Array.from({ length: 3 }).map((_, i) => (
    <tr key={i} className="animate-pulse">
      <td colSpan={5} className="px-4 py-3">
        <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-full"></div>
      </td>
    </tr>
  ))
) : ...
```

Use 3 skeleton rows for the Roles tab (typically few roles), 5 for the audit dashboard.

### Pattern 3: Pagination (existing pattern)

```typescript
// Source: admin/src/pages/admin/AccountDetailPage.tsx (line 881)
{data && data.pages > 1 && (
  <div className="mt-4 flex items-center justify-between text-sm text-gray-600 dark:text-gray-400">
    <span>Page {data.page} of {data.pages} ({data.total} total)</span>
    <div className="flex gap-2">
      <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page <= 1}
        className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800">
        Previous
      </button>
      <button onClick={() => setPage(p => Math.min(data.pages, p + 1))} disabled={page >= data.pages}
        className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 hover:bg-gray-50 dark:border-gray-600 dark:text-gray-300 dark:hover:bg-gray-800">
        Next
      </button>
    </div>
  </div>
)}
```

### Pattern 4: Inline revoke confirmation (consistent with existing demote confirm)

The existing demote confirm pattern (line 955) renders an inline confirm block rather than a modal. For per-row revoke confirmation in the Roles tab, use a modal (per CONTEXT.md decision) triggered by clicking Revoke. The `AccountDetailPage` already has `showDemoteConfirm` state — follow the same inline confirm approach or use a modal. CONTEXT.md decided on a confirmation dialog modal.

### Pattern 5: Toast/success messages

No toast library is installed. Existing pattern: time-scoped state + auto-clear with `setTimeout`:
```typescript
// Source: admin/src/pages/admin/AccountDetailPage.tsx (line 258)
setPromotionSuccess('Account successfully promoted to Connected tier.');
fetchAccount();
setTimeout(() => setPromotionSuccess(null), 5000);
```

For the 1.5s in-modal "Role granted" message then auto-close, use the same pattern:
```typescript
setGrantSuccess(true);
setTimeout(() => {
  setGrantSuccess(false);
  setShowGrantModal(false);
  fetchRoles(); // refresh Roles tab
}, 1500);
```

For post-revoke success toast outside the modal, use a component-level success state auto-cleared after 3s.

### Conditional field logic for grant form

The `campaign_manager` role requires `resource_id` (politician UUID) instead of `jurisdiction_geoid`. All other roles use `jurisdiction_geoid`. Detection:

```typescript
const RESOURCE_SCOPED_ROLES = ['campaign_manager'];
const needsResourceId = RESOURCE_SCOPED_ROLES.includes(selectedRoleSlug);
```

The politician picker for `campaign_manager` calls `GET /api/admin/compass/politicians` (already used by `PoliticiansPage`) and renders a `<select>` with `{full_name || first_name + ' ' + last_name} — {office_title}`.

### Role tab: Revoke passes scope fields

The Roles tab shows `feature_scope`, `jurisdiction_geoid`, `resource_id`. When revoking, the revoke call must pass the same scope to match the right row (the revised `revoke_role` RPC uses `IS NOT DISTINCT FROM` for NULL-safe matching). The row data from `GET /admin/accounts/:userId/roles` must include these fields so the Revoke button can send them.

### Audit dashboard: `role_audit_log` vs `admin_audit_log`

Phase 54's dashboard reads `public.role_audit_log` — the table created in migration 047. This is distinct from `public.admin_audit_log` (written by `logAdminAction`). The `role_audit_log` table has `actor_id` (UUID) — the dashboard must join to `public.users` for the actor's `display_name`.

The audit dashboard filter resets page to 1 on "Search" press. Filters are query params: `feature_scope`, `jurisdiction_geoid`, `from` (ISO date), `to` (ISO date), `page`.

### Nav item for role-audit

`AdminLayout.tsx` has a `navItems` array. Add `{ label: 'Role Audit', to: '/admin/role-audit' }`. Add the route in `App.tsx` inside the admin guard block.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Modal focus trap + escape key | Custom event handlers | `@headlessui/react` Dialog | Already installed, handles a11y correctly |
| Toast notifications | Custom toast component | Component-level `useState` + `setTimeout` | Existing project pattern, sufficient for this tool |
| Politician data fetching | New endpoint | `GET /api/admin/compass/politicians` | Already exists, already returns `id`, `full_name`, `first_name`, `last_name`, `office_title` |
| Role list for grant form | Hardcoded slugs | `GET /api/roles` | Already exists, returns all active roles |

## Common Pitfalls

### Pitfall 1: Passing stale scope fields to revoke

**What goes wrong:** Revoke endpoint called with only `role_slug` — the scoped RPC matches `feature_scope = 'platform'` by default, which won't match a jurisdiction-scoped grant, silently returning success with no row updated.

**Why it happens:** Pre-Phase-52 endpoints only sent `role_slug`. The RPC defaults `p_feature_scope = 'platform'`.

**How to avoid:** The revoke call must send `feature_scope`, `jurisdiction_geoid`, and `resource_id` from the row data, not just `role_slug`. The Roles tab row data must include these fields.

**Warning signs:** Revoke returns `{ ok: true }` but the role reappears on reload.

### Pitfall 2: `admin_get_account_detail` RPC does not return scope columns

**What goes wrong:** Frontend reads `account.roles` from the existing account detail endpoint and scope columns are `undefined` — the Scope column in the Roles tab shows nothing, and revoke passes `undefined` as scope.

**Why it happens:** The `admin_get_account_detail` RPC (migration 025) selects `role_id, slug, name, granted_at` — no scope fields. Migration 047 added the columns but did not update this RPC.

**How to avoid:** Add a dedicated `GET /api/admin/accounts/:userId/roles` endpoint that calls `getUserRoles(userId)` from `roleService.ts`. This already returns the full scope shape. The frontend's Roles tab fetches from this endpoint, not from `account.roles`.

### Pitfall 3: Confusing `role_audit_log` with `admin_audit_log`

**What goes wrong:** Dashboard queries `admin_audit_log` (or vice versa) — wrong table, wrong columns.

**Why it happens:** Both tables exist. `logAdminAction` writes to `admin_audit_log`. The Phase 52 schema created `role_audit_log` as the dedicated role-action audit store.

**How to avoid:** The `GET /api/admin/role-audit` endpoint queries `public.role_audit_log` directly via `pool.query()`. The `admin_audit_log` is a separate concern.

### Pitfall 4: `role_audit_log` is not currently written to by grant/revoke

**What goes wrong:** Audit dashboard shows 0 entries even after granting roles.

**Why it happens:** Current `adminGrantRole` calls `grantRole()` which calls the `grant_role` RPC — neither writes to `role_audit_log`. The `logAdminAction` call in `admin.ts` writes to `admin_audit_log` instead.

**How to avoid:** Phase 54 must wire `role_audit_log` writes into the grant/revoke flow. Either:
- Extend the `grant_role`/`revoke_role` RPCs to write to `role_audit_log` atomically, OR
- Write to `role_audit_log` explicitly in `adminService.ts` after the RPC succeeds (via `pool.query()`)

Direct `pool.query()` writes in `adminService.ts` is the simpler path — no migration needed, consistent with the "use pool for non-public schema" pattern (though `role_audit_log` is in `public` schema so `supabaseAdmin.from('role_audit_log')` would also work).

### Pitfall 5: Grant modal role selector shows all roles including non-scoped ones

**What goes wrong:** Admin selects `volunteer` (platform scope) and sees the jurisdiction field — confusing since `volunteer` is platform-scoped only.

**How to avoid:** Derive `feature_scope` type from the selected role slug. For Alpha, scope type is implicit by role slug:
- `campaign_manager` → resource scope → show politician picker
- All others → jurisdiction scope → show jurisdiction text field (optional)
- `volunteer`, `ctc_content_editor`, `essentials_data_editor` may be platform-only (no scope needed)

Per CONTEXT.md decision: "conditional field (jurisdiction text input OR politician picker depending on role)". Research cannot resolve which non-`campaign_manager` roles need jurisdiction vs platform scope — this is a product decision. **Recommendation:** Show jurisdiction field for all roles except `campaign_manager`. If left blank, `feature_scope` defaults to `platform`. This matches how the DB defaults work.

### Pitfall 6: AccountDetailPage is already very large (1046 lines)

**What goes wrong:** Adding the Roles tab modal and state to `AccountDetailPage.tsx` makes the file unwieldy.

**How to avoid:** Extract the Roles tab content into a `RolesTab.tsx` component that accepts `userId` as a prop and manages its own state (role list, grant modal, revoke confirm). This keeps `AccountDetailPage.tsx` as a layout orchestrator.

## Code Examples

### New roles endpoint shape

```typescript
// Source: backend/src/lib/roleService.ts (getUserRoles return type)
// GET /api/admin/accounts/:userId/roles response shape:
{
  roles: Array<{
    role_id: string;
    slug: string;
    name: string;
    granted_at: string;       // ISO timestamp
    feature_scope: string;    // 'platform' | 'jurisdiction' | 'resource'
    jurisdiction_geoid: string | null;
    resource_id: string | null;
  }>
}
```

### Scoped grant request body

```typescript
// POST /api/admin/roles/grant — expanded schema
{
  user_id: string;           // UUID
  role_slug: string;         // e.g. 'compass_stance_editor'
  feature_scope?: string;    // 'platform' | 'jurisdiction' | 'resource', default 'platform'
  jurisdiction_geoid?: string | null;
  resource_id?: string | null;
}
```

### Audit log endpoint

```typescript
// GET /api/admin/role-audit?feature_scope=&jurisdiction_geoid=&from=&to=&page=
// Response shape:
{
  entries: Array<{
    id: string;
    actor_id: string;
    actor_display_name: string;   // joined from public.users
    target_user_id: string;
    target_display_name: string;  // joined from public.users
    feature_scope: string | null;
    jurisdiction_geoid: string | null;
    resource_id: string | null;
    action: string;               // 'granted' | 'revoked'
    created_at: string;
  }>;
  total: number;
  page: number;
  pages: number;
}
```

### Conditional field rendering in grant form

```typescript
const POLITICIAN_ROLES = ['campaign_manager'];

function GrantRoleModal({ userId, onClose, onSuccess }) {
  const [roleSlug, setRoleSlug] = useState('');
  const [jurisdictionGeoid, setJurisdictionGeoid] = useState('');
  const [resourceId, setResourceId] = useState('');

  const needsPolitician = POLITICIAN_ROLES.includes(roleSlug);
  const featureScope = needsPolitician ? 'resource'
    : jurisdictionGeoid ? 'jurisdiction'
    : 'platform';

  // ...
}
```

### Scope column display

```typescript
function ScopeCell({ feature_scope, jurisdiction_geoid, resource_id }: UserRoleGrant) {
  if (feature_scope === 'resource' && resource_id) {
    return <span><span className="text-xs text-gray-400 mr-1">Politician</span>{resource_id.slice(0, 8)}&hellip;</span>;
  }
  if (feature_scope === 'jurisdiction' && jurisdiction_geoid) {
    return <span><span className="text-xs text-gray-400 mr-1">Jurisdiction</span>{jurisdiction_geoid}</span>;
  }
  return <span className="text-gray-400 text-xs">Platform</span>;
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Roles on `admin_get_account_detail` RPC | Dedicated `/admin/accounts/:id/roles` endpoint | Phase 54 | Avoids RPC modification; scope fields available |
| Grant/revoke without scope | Scoped grant/revoke | Phase 54 | `jurisdiction` and `resource` grants now possible from UI |
| No audit trail for role actions | `role_audit_log` table | Phase 52 | Dashboard is now buildable |

## Open Questions

1. **Which roles are platform-only vs jurisdiction-scoped?**
   - What we know: `campaign_manager` uses `resource_id`. All others show jurisdiction field per CONTEXT.md.
   - What's unclear: Should `volunteer`, `ctc_content_editor`, `essentials_data_editor` also accept jurisdiction or always be `platform`?
   - Recommendation: For Alpha, treat all non-`campaign_manager` roles as optionally jurisdiction-scoped — jurisdiction field shown, if left blank `feature_scope = 'platform'`. No blocking issue.

2. **How to display `resource_id` (politician UUID) in the Roles tab Scope column?**
   - What we know: `resource_id` is a UUID. The Roles tab fetches from `/admin/accounts/:userId/roles` which returns raw UUID.
   - What's unclear: Should it show the politician's name? That requires an additional lookup.
   - Recommendation: Show truncated UUID with "Politician" label for Alpha. Full name lookup is a nice-to-have, not required.

3. **Does `role_audit_log.action` already contain the string 'granted'/'revoked', or is it something else?**
   - What we know: The table's `action` column exists. No existing rows written to it yet (grant/revoke currently writes only to `admin_audit_log`).
   - Recommendation: Standardize on `'granted'` and `'revoked'` when writing to `role_audit_log` in Phase 54.

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection:
  - `backend/migrations/047_role_scope_migration.sql` — role_audit_log schema, grant_role/revoke_role RPC signatures
  - `backend/migrations/025_rpc_pool_migration.sql` — admin_get_account_detail RPC roles query (missing scope columns confirmed)
  - `backend/src/routes/admin.ts` — grant/revoke endpoint current schema (no scope params confirmed)
  - `backend/src/lib/roleService.ts` — getUserRoles return type, invalidateRoleCache
  - `backend/src/lib/adminService.ts` — adminGrantRole/adminRevokeRole delegates
  - `admin/src/pages/admin/AccountDetailPage.tsx` — modal patterns, pagination, skeleton loading
  - `admin/src/pages/admin/PoliticiansPage.tsx` — @headlessui/react Dialog usage
  - `admin/src/pages/admin/AdminLayout.tsx` — nav items pattern
  - `admin/src/App.tsx` — route registration pattern
  - `admin/package.json` — @headlessui/react ^2.2.9 confirmed installed

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries confirmed via package.json and existing code
- Architecture: HIGH — gaps confirmed by direct codebase inspection
- Pitfalls: HIGH — all pitfalls identified from actual code state

**Research date:** 2026-04-03
**Valid until:** 2026-05-03 (stable codebase, no fast-moving dependencies)
