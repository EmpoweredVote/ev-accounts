# Summary: 11-01 — Admin Tool XP View

## Status: Complete

## What Was Built

Added read-only XP visibility to the admin account detail page — satisfying XPADM-01 and XPADM-02.

### Backend

- **`backend/src/lib/adminService.ts`**: Added `getAdminXpHistory(userId, page)` function. Delegates to `getXpHistory` from `xpService.ts` with a 25-per-page limit. Returns `{ transactions, total, page, pages }`.
- **`backend/src/routes/admin.ts`**: Added `GET /api/admin/accounts/:userId/xp-history` route. Accepts optional `?page=N` query param (validated via Zod). Delegated to `getAdminXpHistory`. Protected by existing `requireAuth + requireAdmin` middleware on the router.

### Admin UI

- **`admin/src/pages/admin/AccountDetailPage.tsx`**:
  - Added `ConnectedProfile`, `XpTransaction`, `XpHistoryResponse` interfaces
  - Added `connected_profile: ConnectedProfile | null` to `AccountDetail` interface
  - Added XP history state: `xpData`, `xpError`, `xpLoading`, `xpPage`, `expandedId`
  - Added `useEffect` gated on `account?.connected_profile` to fetch XP history on load and page change
  - Added "Level X · Y XP" summary line in the account header card (Connected/Empowered only)
  - Added full XP History card section with: source, amount, timestamp, metadata columns; loading skeleton; empty state; pagination (Previous/Next, page X of Y); metadata expand/collapse toggle (View/Hide for non-empty, em-dash for null/empty)

## Commits

- `ec1a7e1` — feat(11-01): add admin XP history backend endpoint
- `c16001c` — feat(11-01): add XP summary header and XP History section to AccountDetailPage

## Deviations

None. Implementation matched plan exactly.

## Verification Results

- `npx tsc --noEmit` — clean (backend + admin)
- `npm run build` (admin) — succeeded, 305 modules transformed
- `npm test` (backend) — 87 passed, 100 skipped (no regressions)
