# Phase 11: Admin Tool XP View - Research

**Researched:** 2026-03-04
**Domain:** React admin UI extension — read-only XP visibility on the existing AccountDetailPage
**Confidence:** HIGH

## Summary

Phase 11 is a pure frontend phase with a narrow backend extension. The existing `admin_get_account_detail` RPC already returns `total_xp` and `current_level` inside the `connected_profile` nested object (because Phase 9 added those columns to `connect.connected_profiles` and the RPC uses `SELECT * FROM connect.connected_profiles`). No new backend migration or new admin RPC is needed for the XP summary display.

The XP History section requires a new backend endpoint — either a new admin-scoped route (`GET /api/admin/accounts/:userId/xp-history`) or reuse of `GET /api/xp/:userId/history` with admin auth. The existing `getXpHistory` function in `xpService.ts` already does paginated `xp_transactions` reads. The cleanest approach matches the codebase pattern: add a thin wrapper in `adminService.ts` that calls `getXpHistory`, add a route handler in `admin.ts`, and call it from the React component via `apiFetch`.

The admin UI (React + Vite + Tailwind v4) has well-established component patterns: card sections stacked vertically, `animate-pulse` skeleton rows inside `tbody`, `divide-y divide-gray-100` table bodies, `px-4 py-3` cell padding, and a Previous/Next pagination bar. All four existing patterns (card sections, table, skeleton, pagination) are copy-paste consistent across `AccountsPage.tsx`, `CronLogPage.tsx`, and `AccountDetailPage.tsx`. Phase 11 must follow these exactly.

**Primary recommendation:** Add XP summary to the existing header card using `account.connected_profile?.total_xp` and `account.connected_profile?.current_level`; add an XP History card section using a new `GET /api/admin/accounts/:userId/xp-history` endpoint backed by `getXpHistory` from `xpService.ts`; and add a metadata expand/collapse toggle row using inline `useState`.

---

## Standard Stack

No new dependencies are required. All tools are already installed.

### Core (already installed)
| Library | Version | Purpose | Role in Phase 11 |
|---------|---------|---------|-----------------|
| react | ^18.3.1 | UI framework | AccountDetailPage component extension |
| react-router-dom | ^6.21.1 | Routing | Already wires `AccountDetailPage` to `/admin/accounts/:userId` |
| tailwindcss | ^4.0.0 | Utility CSS | All styling — match existing class names exactly |
| zustand | ^5.0.11 | Auth state | `useAuthStore` for token via `apiFetch` |
| express | ^4.21.0 | Backend routing | New admin XP history route |
| zod | ^3.23.0 | Validation | Query param schema on new route |

### No new installations needed
Phase 11 adds no new packages to `admin/package.json` or `backend/package.json`.

---

## Architecture Patterns

### Established Project Structure (relevant to Phase 11)

```
admin/src/
├── pages/admin/
│   └── AccountDetailPage.tsx   # MODIFY — XP summary + XP History section
└── lib/
    └── api.ts                  # UNCHANGED — apiFetch used as-is

backend/src/
├── routes/
│   └── admin.ts                # MODIFY — new GET /accounts/:userId/xp-history handler
└── lib/
    ├── adminService.ts         # MODIFY — new getAdminXpHistory function
    └── xpService.ts            # UNCHANGED — getXpHistory already works; just call it
```

### Pattern 1: Conditional Section Rendering (existence check, not tier string)

**What:** Optional card sections only render when the relevant data object is non-null. Never check `account.tier === 'connected'` — check `account.connected_profile` existence.
**When to use:** For every XP-related section (summary and history).
**Example (from AccountDetailPage.tsx line 243):**
```typescript
// Source: admin/src/pages/admin/AccountDetailPage.tsx line 243
{account.calibration_status && (
  <div className="bg-white rounded-lg shadow p-6 mb-4">
    <h2 className="text-lg font-semibold text-gray-900 mb-3">Calibration Status</h2>
    ...
  </div>
)}
```

**For XP summary:** Check `account.connected_profile` — render the "Level X · Y XP" block only when this is non-null. `total_xp` and `current_level` come from inside `connected_profile` (they are `connected_profiles` columns returned via `SELECT *` in the RPC).

### Pattern 2: XP Fields Location in API Response

**What:** The `admin_get_account_detail` RPC returns `connected_profile` as a nested JSONB object. Because it does `SELECT * FROM connect.connected_profiles`, and Phase 9 added `total_xp BIGINT` and `current_level INT` to that table, those fields are already present in the response under `account.connected_profile.total_xp` and `account.connected_profile.current_level`.

**Critical implication for the TypeScript interface:** The `AccountDetail` interface must be updated to include a `connected_profile` sub-type with `total_xp` and `current_level`. The existing interface has `legal_name` and `tolerance_rating` at the root — this is a type annotation mismatch; the actual runtime data has them inside `connected_profile`. Phase 11 should access XP via `account.connected_profile?.total_xp` and must NOT add `total_xp` to the root-level `AccountDetail` interface.

```typescript
// Correct type extension for AccountDetailPage.tsx
interface ConnectedProfile {
  legal_name: string | null;
  tolerance_rating: number | null;
  total_xp: number;
  current_level: number;
  account_standing: string;
  verification_status: string;
  // ... other connected_profiles columns
}

interface AccountDetail {
  id: string;
  display_name: string;
  email: string;
  tier: string;
  account_standing: string;
  created_at: string;
  connected_profile: ConnectedProfile | null;  // was missing; add this
  roles: Role[];
  invited_by: { id: string; display_name: string } | null;
  invited_users: Array<{ id: string; display_name: string }>;
  calibration_status: CalibrationStatus | null;
}
```

### Pattern 3: Card Section (stacked, no tabs)

**What:** All account detail sections are `bg-white rounded-lg shadow p-6 mb-4` divs stacked vertically.
**When to use:** XP History card section follows this exact pattern.

```typescript
// Source: admin/src/pages/admin/AccountDetailPage.tsx — every section
<div className="bg-white rounded-lg shadow p-6 mb-4">
  <h2 className="text-lg font-semibold text-gray-900 mb-3">XP History</h2>
  {/* ... */}
</div>
```

### Pattern 4: Table with Skeleton Loading

**What:** The established table/skeleton pattern used in `AccountsPage.tsx` and `CronLogPage.tsx`.
- Wrapper: `bg-white rounded-lg shadow overflow-hidden`
- Table: `w-full text-sm`
- Header: `bg-gray-50 border-b border-gray-200` / `text-left px-4 py-3 font-medium text-gray-500`
- Body: `divide-y divide-gray-100`
- Skeleton: `animate-pulse` row with `colSpan={N}`, `px-4 py-3`, single `h-4 bg-gray-200 rounded w-full` div

```typescript
// Source: admin/src/pages/admin/CronLogPage.tsx — exact pattern
<div className="bg-white rounded-lg shadow overflow-hidden">
  <table className="w-full text-sm">
    <thead className="bg-gray-50 border-b border-gray-200">
      <tr>
        <th className="text-left px-4 py-3 font-medium text-gray-500">Source</th>
        <th className="text-left px-4 py-3 font-medium text-gray-500">Amount</th>
        <th className="text-left px-4 py-3 font-medium text-gray-500">Timestamp</th>
        <th className="text-left px-4 py-3 font-medium text-gray-500">Metadata</th>
      </tr>
    </thead>
    <tbody className="divide-y divide-gray-100">
      {xpLoading ? (
        Array.from({ length: 5 }).map((_, i) => (
          <tr key={i} className="animate-pulse">
            <td colSpan={4} className="px-4 py-3">
              <div className="h-4 bg-gray-200 rounded w-full"></div>
            </td>
          </tr>
        ))
      ) : xpData?.transactions.length === 0 ? (
        <tr>
          <td colSpan={4} className="px-4 py-8 text-center text-gray-400">
            No XP transactions found.
          </td>
        </tr>
      ) : (
        xpData?.transactions.map((tx) => (
          <tr key={tx.id}>
            <td className="px-4 py-3 text-gray-700">{tx.source}</td>
            <td className="px-4 py-3 text-gray-900 font-medium">+{tx.amount}</td>
            <td className="px-4 py-3 text-gray-500">
              {new Date(tx.created_at).toLocaleString()}
            </td>
            <td className="px-4 py-3">
              {/* metadata expand toggle */}
            </td>
          </tr>
        ))
      )}
    </tbody>
  </table>
</div>
```

### Pattern 5: Pagination Bar (Previous/Next, page X of Y)

**What:** Shown only when `pages > 1`. Exact structure from `AccountsPage.tsx` and `CronLogPage.tsx`.

```typescript
// Source: admin/src/pages/admin/CronLogPage.tsx lines 118-140
{xpData && xpData.pages > 1 && (
  <div className="mt-4 flex items-center justify-between text-sm text-gray-600">
    <span>
      Page {xpData.page} of {xpData.pages} ({xpData.total} total)
    </span>
    <div className="flex gap-2">
      <button
        onClick={() => setXpPage((p) => Math.max(1, p - 1))}
        disabled={xpPage <= 1}
        className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 hover:bg-gray-50"
      >
        Previous
      </button>
      <button
        onClick={() => setXpPage((p) => Math.min(xpData.pages, p + 1))}
        disabled={xpPage >= xpData.pages}
        className="px-3 py-1 border border-gray-300 rounded disabled:opacity-50 hover:bg-gray-50"
      >
        Next
      </button>
    </div>
  </div>
)}
```

### Pattern 6: apiFetch for Data Fetching

**What:** All admin UI data fetching uses `apiFetch` from `../../lib/api`. It attaches the admin JWT automatically. The admin XP history endpoint is behind `requireAuth + requireAdmin` (inherited via `router.use` in `admin.ts`).

```typescript
// Source: admin/src/lib/api.ts — used in every page component
apiFetch<XpHistoryResponse>(`/admin/accounts/${userId}/xp-history?page=${xpPage}`)
  .then(setXpData)
  .catch((err) => setXpError(err.message))
  .finally(() => setXpLoading(false));
```

### Pattern 7: New Admin Backend Endpoint

**What:** `GET /api/admin/accounts/:userId/xp-history` — new route in `admin.ts`, new function in `adminService.ts`.

The function in `adminService.ts` delegates to `getXpHistory` from `xpService.ts`. This mirrors how `adminDemote` delegates to `executeDemotion` from `empowerService.ts`.

```typescript
// adminService.ts — new function
import { getXpHistory } from './xpService.js';

export async function getAdminXpHistory(
  userId: string,
  page: number = 1
): Promise<{ transactions: unknown[]; total: number; page: number; pages: number }> {
  const limit = 25;
  const offset = (page - 1) * limit;
  const { transactions, total } = await getXpHistory(userId, { limit, offset });
  return {
    transactions,
    total,
    page,
    pages: Math.max(1, Math.ceil(total / limit)),
  };
}
```

```typescript
// admin.ts — new route handler (add before end of file, after cron-log routes)
// Note: router.use(requireAuth, requireAdmin) at line 46 covers ALL routes
// No per-route auth needed.

const XpHistoryQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
});

router.get('/accounts/:userId/xp-history', async (req, res) => {
  try {
    const { userId } = req.params;
    const parsed = XpHistoryQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid query parameters' });
      return;
    }
    const result = await getAdminXpHistory(userId, parsed.data.page);
    res.json(result);
  } catch (err) {
    console.error('[admin/xp-history] error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});
```

**Pagination:** Use page-based pagination (1-indexed) with 25 per page — matching the `admin_list_invites` and `admin_list_accounts` pattern in `adminService.ts`. The existing `getXpHistory` uses offset-based internally; the admin wrapper converts page → offset.

### Pattern 8: Metadata Expand/Collapse

**What:** Metadata JSONB is shown collapsed by default with a toggle button to reveal raw JSON or key-value pairs. Use `useState<string | null>(null)` to track which row is expanded (store the transaction id). Claude's Discretion: use a toggle row (extra `<tr>` below the transaction row) which collapses to nothing when the transaction id is not in the expanded set.

```typescript
// Claude's Discretion recommendation: toggle button in the metadata cell,
// with a collapsible detail row beneath
const [expandedId, setExpandedId] = useState<string | null>(null);

// In tbody mapping:
<>
  <tr key={tx.id}>
    ...
    <td className="px-4 py-3">
      {tx.metadata ? (
        <button
          onClick={() => setExpandedId(expandedId === tx.id ? null : tx.id)}
          className="text-xs text-blue-600 hover:text-blue-800"
        >
          {expandedId === tx.id ? 'Hide' : 'View'}
        </button>
      ) : (
        <span className="text-gray-300 text-xs">—</span>
      )}
    </td>
  </tr>
  {expandedId === tx.id && tx.metadata && (
    <tr key={`${tx.id}-meta`} className="bg-gray-50">
      <td colSpan={4} className="px-4 py-2">
        <pre className="text-xs text-gray-600 overflow-auto max-h-32">
          {JSON.stringify(tx.metadata, null, 2)}
        </pre>
      </td>
    </tr>
  )}
</>
```

This requires `React.Fragment` with key on each pair — use `<React.Fragment key={tx.id}>` wrapping both `<tr>` elements.

### Pattern 9: XP Summary in Account Header

**What:** Inline text display within the existing header card's badge area. The current header has tier badge and standing badge in a `flex gap-2` div. Add the level/XP string after the badges.

```typescript
// admin/src/pages/admin/AccountDetailPage.tsx — existing header card (lines 134-148)
// Claude's Discretion: add as a text span after the badges, styled as a
// secondary detail, only when connected_profile exists

{account.connected_profile && (
  <span className="text-sm text-gray-500 font-medium">
    Level {account.connected_profile.current_level} &middot; {account.connected_profile.total_xp.toLocaleString()} XP
  </span>
)}
```

Place this directly below the badges div (`<div className="flex gap-2">...</div>`) in the header, inside the right-side column. Alternatively, add it to the left column under the account ID line. Claude's Discretion: add to the left column as a third `<p>` below the email and ID lines, so it reads as a profile summary line.

### Anti-Patterns to Avoid

- **Checking `account.tier === 'connected'` for XP visibility:** Use `account.connected_profile !== null` — matching the Calibration Status pattern which checks `account.calibration_status` (null-check on the object, not a string comparison).
- **Adding `total_xp` / `current_level` to the root `AccountDetail` interface:** These fields come from `connected_profile` nested object. Accessing them at root level would require changing the API or doing flattening that doesn't exist.
- **Calling `GET /api/xp/:userId` from admin:** That endpoint is public and returns only summary data, not the full history. The admin needs `GET /api/admin/accounts/:userId/xp-history` which returns paginated ledger entries.
- **Creating a separate React state slice for each XP data piece:** Use a single `xpData` state object with `{ transactions, total, page, pages }` — matching how `data` works in `CronLogPage.tsx`.
- **Resetting `xpPage` on initial load:** The page state for XP history is independent of the account's main load state. Initialize `xpPage` at 1 and fetch XP history in a separate `useEffect` that depends on `[userId, xpPage]`.
- **Using `<React.Fragment>` without a key when mapping expand rows:** Metadata expansion uses two sibling `<tr>` elements per transaction row. Wrap both in `<React.Fragment key={tx.id}>` to satisfy React's list key requirement.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Paginated XP transaction read | Custom SQL in adminService | `getXpHistory` from `xpService.ts` | Already implemented with exact pagination pattern needed |
| JSON pretty-printing for metadata | Custom formatter | `JSON.stringify(tx.metadata, null, 2)` in `<pre>` | Sufficient for admin tool; no extra library needed |
| Level calculation | TypeScript tier arithmetic | Use `current_level` already stored on `connected_profiles` | Phase 9 persists `current_level` denormalized; no RPC call needed for display |

**Key insight:** `total_xp` and `current_level` are already returned by the existing `admin_get_account_detail` RPC inside `connected_profile`. No additional DB call is needed for the XP summary header. Only the history table needs a new endpoint.

---

## Common Pitfalls

### Pitfall 1: Wrong Field Path for XP Summary Data
**What goes wrong:** XP data is accessed at `account.total_xp` (undefined) instead of `account.connected_profile?.total_xp`.
**Why it happens:** The `AccountDetail` TypeScript interface has `legal_name` declared at root level, suggesting the API returns a flat object. In reality the RPC returns `connected_profile` as a nested object.
**How to avoid:** Read XP from `account.connected_profile?.total_xp` and `account.connected_profile?.current_level`. Update the TypeScript interface to add a `connected_profile` sub-object type.
**Warning signs:** "Level 0 · 0 XP" displayed for users with real XP balance, or TypeScript errors accessing `total_xp`.

### Pitfall 2: AccountDetail Interface Missing connected_profile
**What goes wrong:** TypeScript compilation error or `undefined` access when reading `account.connected_profile.total_xp`.
**Why it happens:** The existing `AccountDetail` interface doesn't declare `connected_profile` as a typed field — it has `legal_name` and `tolerance_rating` at root (which is inaccurate). The runtime data has these fields inside `connected_profile`.
**How to avoid:** Add `connected_profile: ConnectedProfile | null` to the `AccountDetail` interface. The `ConnectedProfile` interface should include `total_xp: number`, `current_level: number`, plus the fields already used (`legal_name`, `tolerance_rating`).
**Warning signs:** TypeScript error "Property 'connected_profile' does not exist on type 'AccountDetail'".

### Pitfall 3: XP History Fetch Fires Before Account Loads
**What goes wrong:** XP history `apiFetch` fires with `userId` defined but the account hasn't loaded yet, causing a race condition or incorrect state.
**Why it happens:** Two `useEffect` hooks (main account fetch + XP history fetch) can run concurrently.
**How to avoid:** Add `account` to the XP history `useEffect` dependency array: `useEffect(() => { if (userId && account?.connected_profile) { fetchXpHistory(); } }, [userId, xpPage, account?.connected_profile])`. Only fetch XP history when the account is loaded AND has a connected_profile.
**Warning signs:** XP history section shows an error for non-Connected users who just happen to have a userId.

### Pitfall 4: Route Conflict with Existing Admin Routes
**What goes wrong:** New `GET /accounts/:userId/xp-history` conflicts with existing `GET /accounts/:userId` param match.
**Why it happens:** Express matches routes top-to-bottom. If `/accounts/:userId/xp-history` is registered AFTER `/accounts/:userId`, the latter won't match because the full path `/:userId/xp-history` doesn't match the `:userId` sub-path pattern.
**How to avoid:** In `admin.ts`, Express correctly distinguishes `/accounts/:userId` (no trailing segment) from `/accounts/:userId/xp-history` (trailing literal). This is safe regardless of order — Express only matches the full path. No special ordering needed here.
**Warning signs:** 404 on `/admin/accounts/:userId/xp-history`.

### Pitfall 5: Metadata Toggle Breaking React List Keys
**What goes wrong:** Console error "Each child in a list should have a unique 'key' prop" when rendering the expanded metadata row.
**Why it happens:** Two sibling `<tr>` elements (transaction row + metadata row) can't both be top-level children of a `map()` without wrapping.
**How to avoid:** Wrap both `<tr>` elements in `<React.Fragment key={tx.id}>`. The fragment's key satisfies React's list requirement without adding DOM nodes.
**Warning signs:** React key warning in browser console when metadata rows are present.

### Pitfall 6: `toLocaleString()` on Undefined
**What goes wrong:** `account.connected_profile.total_xp.toLocaleString()` throws if `total_xp` is `undefined` (can happen if the `connected_profiles` row was created before Phase 9 migration and has NULL value).
**Why it happens:** Phase 9 added `total_xp BIGINT NOT NULL DEFAULT 0` — any pre-existing rows would have been updated with DEFAULT 0 by the migration. But the TypeScript type should reflect this.
**How to avoid:** Use `(account.connected_profile?.total_xp ?? 0).toLocaleString()` and `account.connected_profile?.current_level ?? 0` for display.
**Warning signs:** "Cannot read properties of undefined (reading 'toLocaleString')" in browser console.

---

## Code Examples

### XP Summary in Header Card
```typescript
// Source: admin/src/pages/admin/AccountDetailPage.tsx — header card (modify existing)
// Add below the flex gap-2 badges div, inside the left column
{account.connected_profile && (
  <p className="text-sm text-gray-500 mt-1">
    Level {account.connected_profile.current_level ?? 0}
    {' · '}
    {(account.connected_profile.total_xp ?? 0).toLocaleString()} XP
  </p>
)}
```

### XP History Section (full structure)
```typescript
// Source: pattern from admin/src/pages/admin/CronLogPage.tsx
// Separate state for XP history (do not reuse account loading state)
const [xpData, setXpData] = useState<XpHistoryResponse | null>(null);
const [xpError, setXpError] = useState<string | null>(null);
const [xpLoading, setXpLoading] = useState(false);
const [xpPage, setXpPage] = useState(1);
const [expandedId, setExpandedId] = useState<string | null>(null);

// Fetch XP history only when account is loaded and is Connected tier
useEffect(() => {
  if (!userId || !account?.connected_profile) return;
  setXpLoading(true);
  setXpError(null);
  apiFetch<XpHistoryResponse>(`/admin/accounts/${userId}/xp-history?page=${xpPage}`)
    .then(setXpData)
    .catch((err) => setXpError(err.message))
    .finally(() => setXpLoading(false));
}, [userId, xpPage, account?.connected_profile]);
```

### ConnectedProfile Type Extension
```typescript
// Source: admin/src/pages/admin/AccountDetailPage.tsx — extend AccountDetail
interface ConnectedProfile {
  user_id: string;
  display_name: string;
  account_standing: string;
  verification_status: string;
  legal_name: string | null;
  tolerance_rating: number | null;
  total_xp: number;
  current_level: number;
  gem_balance: number;
  completed_onboarding: boolean;
  created_at: string;
}

interface XpTransaction {
  id: string;
  source: string;
  amount: number;
  metadata: Record<string, unknown> | null;
  created_at: string;
}

interface XpHistoryResponse {
  transactions: XpTransaction[];
  total: number;
  page: number;
  pages: number;
}
```

### New adminService Function
```typescript
// Source: pattern from admin/src/lib/adminService.ts — adminDemote delegates to empowerService
// In backend/src/lib/adminService.ts — add at end of file
import { getXpHistory } from './xpService.js';

export async function getAdminXpHistory(
  userId: string,
  page: number = 1
): Promise<{ transactions: unknown[]; total: number; page: number; pages: number }> {
  const limit = 25;
  const offset = (page - 1) * limit;
  const { transactions, total } = await getXpHistory(userId, { limit, offset });
  return {
    transactions,
    total,
    page,
    pages: Math.max(1, Math.ceil(total / limit)),
  };
}
```

### New Admin Route
```typescript
// Source: pattern from backend/src/routes/admin.ts — getCronLog route
// router.use(requireAuth, requireAdmin) already covers all routes in this file
// Add after the existing /accounts/:userId routes

const XpHistoryQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
});

/**
 * GET /api/admin/accounts/:userId/xp-history
 * Paginated XP transaction history for a Connected user. Admin only.
 * Returns 25 transactions per page in reverse chronological order.
 */
router.get('/accounts/:userId/xp-history', async (req, res) => {
  try {
    const { userId } = req.params;
    const parsed = XpHistoryQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({ error: 'Invalid query parameters' });
      return;
    }
    const result = await getAdminXpHistory(userId as string, parsed.data.page);
    res.json(result);
  } catch (err) {
    console.error('[admin/xp-history] error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| No XP data in admin tool | `total_xp` and `current_level` already in `connected_profile` via `admin_get_account_detail` | Phase 9 (2026-03-04) | Summary header requires no new backend; just read fields already present |
| No XP history API | `GET /api/xp/me/history` (user-scoped) exists | Phase 10 (2026-03-04) | Admin endpoint must be separate (admin auth, any userId) but can reuse `getXpHistory` service function |

**Current state of the admin UI:**
- No XP-related code anywhere in `AccountDetailPage.tsx` — Phase 11 adds it entirely.
- The `AccountDetail` interface has `legal_name` and `tolerance_rating` at root level (inaccurate TypeScript — they're inside `connected_profile` at runtime). Phase 11 should fix this by adding a proper `connected_profile` sub-interface.

---

## Open Questions

1. **Type annotation mismatch in AccountDetailPage.tsx**
   - What we know: The `AccountDetail` interface declares `legal_name: string | null` at root, but the `admin_get_account_detail` RPC returns it inside `connected_profile`. The UI renders `account.legal_name` which would be `undefined` at runtime for this path — it may show "Not set" always (since `undefined ?? 'Not set'` = `'Not set'`).
   - What's unclear: Whether this is a known acceptable inaccuracy in the type (the RPC might also merge these to root via `||` operator — but reading the SQL, it does NOT, `connected_profile` stays nested).
   - Recommendation: When adding the `connected_profile` sub-type, also update the existing references to `account.legal_name` and `account.tolerance_rating` to `account.connected_profile?.legal_name` and `account.connected_profile?.tolerance_rating`. This fixes an existing bug alongside the Phase 11 work. Mark this as a bonus fix in the plan.

2. **Metadata column — null vs empty object**
   - What we know: `xp_transactions.metadata` is `JSONB` (nullable). Some transactions may have `null` metadata (e.g., automated awards without context). The `getXpHistory` function selects `metadata` — it will be `null` for these rows.
   - What's unclear: Whether `{}` (empty object) or `null` is the value for transactions without metadata.
   - Recommendation: The metadata column should render a "—" placeholder when `tx.metadata === null` (no View button). When `tx.metadata` is an empty object `{}`, show "View" but expand to `{}`. Handle both cases.

---

## Sources

### Primary (HIGH confidence)
- `admin/src/pages/admin/AccountDetailPage.tsx` — full page read; existing card sections, header structure, conditional rendering pattern, calibration status pattern
- `admin/src/pages/admin/AccountsPage.tsx` — table, skeleton, pagination bar patterns
- `admin/src/pages/admin/CronLogPage.tsx` — table, skeleton, pagination bar (closest match to XP history needs)
- `admin/src/lib/api.ts` — `apiFetch` function used by all admin pages
- `backend/migrations/025_rpc_pool_migration.sql` lines 157-258 — exact `admin_get_account_detail` RPC; confirms `connected_profile` is nested, confirms `SELECT *` returns Phase 9 XP columns
- `backend/src/lib/xpService.ts` — `getXpHistory` function signature and implementation; confirms reuse path
- `backend/src/routes/admin.ts` — `router.use(requireAuth, requireAdmin)` covers all routes; import patterns; error response shape
- `backend/src/lib/adminService.ts` — existing service function patterns; `adminDemote` delegates to `empowerService` (delegation pattern to reuse)
- `.planning/phases/10-xp-api/10-VERIFICATION.md` — confirms Phase 10 status PASSED; `getXpHistory` is fully implemented and returns `{ transactions, total }`

### Secondary (MEDIUM confidence)
- `.planning/phases/10-xp-api/10-RESEARCH.md` — pagination parameter shape, `getXpHistory` return type documentation
- `.planning/phases/11-admin-tool-xp-view/11-CONTEXT.md` — locked decisions confirming stacked sections (not tabs), table format, columns

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; verified against `admin/package.json` and `backend/package.json`
- Architecture (frontend patterns): HIGH — directly read from actual component files; copy-paste patterns confirmed
- Architecture (backend route/service): HIGH — directly read from `admin.ts`, `adminService.ts`, `xpService.ts`
- API response shape: HIGH — read the exact RPC SQL to confirm `connected_profile` nesting and Phase 9 XP columns
- Pitfalls: HIGH — identified by cross-referencing type interface vs actual RPC output and known React list key requirements

**Research date:** 2026-03-04
**Valid until:** 2026-04-03 (stable codebase; Tailwind v4 and React 18 are stable; no fast-moving dependencies)
