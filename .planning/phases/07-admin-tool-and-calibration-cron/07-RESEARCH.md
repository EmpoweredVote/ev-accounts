# Phase 7: Admin Tool and Calibration Cron - Research

**Researched:** 2026-02-27
**Domain:** Admin API (Express/TypeScript), Admin UI (Vite/React/Tailwind), Cron scheduling (node-cron), Tree visualization (@xyflow/react + dagre)
**Confidence:** HIGH

---

## Summary

Phase 7 has three distinct delivery areas: an Express admin API layer (`/api/admin/*`), a React admin UI (Vite + Tailwind), and a calibration lapse cron job. The existing codebase establishes all patterns needed — `requireAdmin` middleware follows the same shape as `requireConnected`/`requireEmpowered`, and the cron job integrates via the same `node-cron` module already used in the Civic Trivia Championships sibling project.

The Civic Trivia Championships admin panel (reviewed at master branch) is the canonical reference for admin UI patterns in this organization. It uses React Router v6 nested routes under an `AdminGuard` component, a `zustand` auth store, Tailwind CSS for styling, and `@headlessui/react` for accessible UI primitives. The admin layout uses a fixed sidebar with `<Outlet />` for page content. This project will use the same patterns and the same library stack, giving the "unified admin for all Empowered Vote features" goal a concrete, proven shape to extend.

The invite chain tree visualization is a new requirement not present in Civic Trivia. The standard solution is `@xyflow/react` (React Flow v12) with `@dagrejs/dagre` for automatic tree layout — this is the official React Flow recommendation for tree graphs and has first-class TypeScript support.

**Primary recommendation:** Use the Civic Trivia admin as the structural template: `AdminGuard` → `AdminLayout` → nested pages. Extend rather than invent. Tree diagram: React Flow + dagre. Cron: node-cron v4 with `noOverlap: true`. Idempotency: `calibration_lapse_runs` table keyed on `run_date DATE`.

---

## Standard Stack

### Backend Admin API

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Express 4.x | ^4.21.0 | Already in use | Locked decision — do not change |
| pg (pool) | ^8.13.0 | Raw SQL for admin queries | Existing pattern; service layer reads |
| supabaseAdmin | via @supabase/supabase-js | Trusted server-side reads | Existing pattern for internal checks |
| zod | ^3.23.0 | Request body validation | Existing pattern throughout |
| node-cron | 4.2.1 | Cron scheduling | Used in Civic Trivia; standard for Express |

### Admin UI (Vite App in `/admin` folder)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| react | ^18.x | UI framework | Existing use in project; Civic Trivia pattern |
| react-dom | ^18.x | DOM rendering | Same as above |
| react-router-dom | ^6.21.1 | Routing (nested routes, AdminGuard) | Same version as Civic Trivia |
| zustand | ^5.0.11 | Auth store | Locked pattern from Civic Trivia |
| @headlessui/react | ^2.2.9 | Accessible dropdowns, dialogs | Already used in Civic Trivia |
| tailwindcss | ^4.2.1 | Styling | Already used across EV projects |
| @xyflow/react | ^12.10.1 | Invite chain tree visualization | Official recommendation for node trees |
| @dagrejs/dagre | ^1.1.4 | Auto tree layout algorithm | Official React Flow recommendation |
| vite | ^5.x | Build tool | Locked decision; existing pattern |

**Note on @xyflow/react version:** The package changed name from `reactflow` to `@xyflow/react` in v12. Use `@xyflow/react` — the old `reactflow` package (v11) is still published but no longer receives updates.

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| @vitejs/plugin-react | ^4.x | Vite React plugin | Required for admin Vite config |
| postcss + autoprefixer | ^8.x / ^10.x | Tailwind build pipeline | Required for Tailwind v4 |
| @types/react + @types/react-dom | ^18.x | TypeScript types | Required for strict TS |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| @xyflow/react + dagre | D3.js force layout | D3 requires more custom code; React Flow handles pan/zoom/click natively |
| @xyflow/react + dagre | vis-network | vis-network is heavier, less React-idiomatic |
| node-cron | BullMQ / Agenda | Overkill for Alpha; project explicitly chose in-process node-cron |
| Tailwind | shadcn/ui | Civic Trivia uses raw Tailwind + Headless UI — stay consistent |
| zustand v5 | React Context | Civic Trivia uses zustand; must stay consistent for future unified admin |

**Backend admin installation:**
```bash
cd backend && npm install node-cron
npm install --save-dev @types/node-cron
```

**Admin UI installation (new `/admin` Vite app):**
```bash
# From repo root, create admin Vite app
npm create vite@latest admin -- --template react-ts
cd admin
npm install react-router-dom zustand @headlessui/react @xyflow/react @dagrejs/dagre
npm install -D tailwindcss postcss autoprefixer @vitejs/plugin-react
npx tailwindcss init -p
```

---

## Civic Trivia Admin Patterns (Canonical Reference)

The Civic Trivia Championships repo establishes these specific patterns that Phase 7 MUST follow for compatibility:

### AdminGuard Pattern (React Router)
```typescript
// Source: https://raw.githubusercontent.com/EmpoweredVote/Civic-Trivia-Championships/master/frontend/src/App.tsx
function AdminGuard() {
  const { isAuthenticated, user, isLoading } = useAuthStore();
  if (isLoading) return null;
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  if (!user?.isAdmin) return <Forbidden />;
  return <Outlet />;
}

// Route structure:
<Route element={<AdminGuard />}>
  <Route path="/admin" element={<AdminLayout />}>
    <Route index element={<AdminDashboard />} />
    <Route path="accounts" element={<AccountsPage />} />
    <Route path="accounts/:userId" element={<AccountDetailPage />} />
    <Route path="invites" element={<InvitesPage />} />
    <Route path="cron-log" element={<CronLogPage />} />
    <Route path="roles" element={<RolesPage />} />
  </Route>
</Route>
```

### AdminLayout Pattern (Sidebar + Outlet)
```typescript
// Source: Civic Trivia AdminLayout.tsx
// Fixed sidebar (w-64) + sticky header + main content area
// Sidebar: navigation array → Link components with active state via useLocation()
// Mobile: toggle sidebarOpen state, backdrop overlay
// Outlet: renders current admin page in main content area
export function AdminLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const location = useLocation();
  // navigation = [{ name, href, icon }]
  // isActive() checks location.pathname
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Mobile backdrop, fixed sidebar, sticky header, <Outlet /> */}
    </div>
  );
}
```

### Auth Store Pattern (Zustand)
```typescript
// Source: Civic Trivia authStore.ts
// user.isAdmin field determines admin access — same pattern to use here
// In EV-Accounts: check admin_users table instead of JWT claim
export const useAuthStore = create<AuthStore>((set) => ({
  accessToken: null,
  user: null,         // { id, email, isAdmin: boolean, ... }
  isAuthenticated: false,
  isLoading: true,
  setAuth: (token, user) => set({ accessToken: token, user, isAuthenticated: true, isLoading: false }),
  clearAuth: () => set({ accessToken: null, user: null, isAuthenticated: false, isLoading: false }),
  setLoading: (loading) => set({ isLoading: loading }),
}));
```

### Admin Route Middleware Pattern (Backend)
```typescript
// Source: Civic Trivia backend/src/routes/admin.ts
// Apply authentication + admin middleware to ALL admin routes at once:
router.use(authenticateToken, requireAdmin);

// In EV-Accounts, the equivalent is:
router.use(requireAuth, requireAdmin);
// All admin routes get both middlewares automatically — no per-route repetition
```

---

## Architecture Patterns

### Recommended Project Structure

```
/                              # Repo root
├── backend/                   # Existing Express API
│   └── src/
│       ├── lib/
│       │   ├── adminService.ts    # NEW: admin queries (accounts, invites, etc.)
│       │   └── cronService.ts     # NEW: calibration lapse logic
│       ├── middleware/
│       │   └── requireAdmin.ts    # NEW: admin_users table check
│       ├── routes/
│       │   └── admin.ts           # NEW: /api/admin/* routes
│       └── cron/
│           └── calibrationLapse.ts # NEW: node-cron daily job
├── admin/                     # NEW: Vite React admin app
│   ├── src/
│   │   ├── store/
│   │   │   └── authStore.ts       # Auth state (zustand)
│   │   ├── pages/
│   │   │   ├── Login.tsx          # Admin login page
│   │   │   └── admin/
│   │   │       ├── AdminLayout.tsx
│   │   │       ├── AdminDashboard.tsx
│   │   │       ├── AccountsPage.tsx
│   │   │       ├── AccountDetailPage.tsx
│   │   │       ├── InvitesPage.tsx
│   │   │       ├── InviteTreePage.tsx    # React Flow tree
│   │   │       ├── CronLogPage.tsx
│   │   │       └── RolesPage.tsx
│   │   ├── components/
│   │   │   ├── InviteTree.tsx     # @xyflow/react tree visualization
│   │   │   └── ProtectedRoute.tsx
│   │   └── App.tsx
│   ├── package.json
│   ├── vite.config.ts
│   └── tailwind.config.js
└── supabase/
    └── migrations/
        └── 20260227000021_phase7_admin_schema.sql  # NEW
```

### Pattern 1: requireAdmin Middleware

```typescript
// Source: Based on existing requireConnected/requireEmpowered patterns + ADMN-06 requirement
// File: backend/src/middleware/requireAdmin.ts
// Note: middleware/ is exempt from the supabaseAdmin ban (architecture test scans src/routes/ only)
import { Response, NextFunction } from 'express';
import type { AuthenticatedRequest } from './auth.js';
import { supabaseAdmin } from '../lib/supabase.js';

export async function requireAdmin(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const { data, error } = await supabaseAdmin
    .from('admin_users')
    .select('user_id')
    .eq('user_id', req.userId)
    .maybeSingle();

  if (error || !data) {
    res.status(403).json({ error: 'Admin access required' });
    return;
  }
  next();
}
```

### Pattern 2: Admin Audit Log on Every Action

Every admin write action must append to `admin_audit_log` BEFORE returning the response. This is the mechanism for ADMN-05.

```typescript
// Source: ADMN-05 requirement
// The audit log write and the action write should be in the same pg transaction
// when the action uses the pg pool. When action uses supabaseAdmin, write audit
// log separately — two sequential awaits is acceptable (non-atomic but acceptable for Alpha).

async function logAdminAction(
  actorId: string,
  action: string,
  targetUserId: string | null,
  details: Record<string, unknown> = {}
): Promise<void> {
  await pool.query(
    `INSERT INTO public.admin_audit_log (actor_id, action, target_user_id, details)
     VALUES ($1, $2, $3, $4)`,
    [actorId, action, targetUserId, JSON.stringify(details)]
  );
}
```

### Pattern 3: Calibration Lapse Cron (node-cron v4)

```typescript
// Source: node-cron v4 API (https://github.com/node-cron/node-cron/blob/master/src/node-cron.ts)
// Key options: timezone, noOverlap (prevents concurrent runs if job takes > 24h)
import cron from 'node-cron';

export function startCalibrationLapseCron(): void {
  cron.schedule('0 2 * * *', async () => {
    await runCalibrationLapseJob();
  }, {
    timezone: 'UTC',
    noOverlap: true,    // Skip if previous run still executing (prevents double-run on restart overlap)
    name: 'calibration-lapse'
  });
  console.log('[cron] Calibration lapse job registered (daily 2am UTC)');
}
```

### Pattern 4: Idempotency via calibration_lapse_runs Table

```sql
-- calibration_lapse_runs table
CREATE TABLE IF NOT EXISTS public.calibration_lapse_runs (
  run_date    DATE        PRIMARY KEY,  -- Only one row per calendar date
  started_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at TIMESTAMPTZ,
  users_warned_25  INTEGER NOT NULL DEFAULT 0,
  users_warned_30  INTEGER NOT NULL DEFAULT 0,
  users_demoted    INTEGER NOT NULL DEFAULT 0,
  error_message    TEXT
);
```

The job opens by attempting an INSERT for today's date. If it gets a unique violation (already ran today), it aborts. This is the idempotency key required by CRON-04.

```typescript
// Idempotency check pattern
const today = new Date().toISOString().slice(0, 10); // 'YYYY-MM-DD'
const { rowCount } = await pool.query(
  'INSERT INTO public.calibration_lapse_runs (run_date) VALUES ($1) ON CONFLICT (run_date) DO NOTHING',
  [today]
);
if (rowCount === 0) {
  console.log(`[cron] Calibration lapse already ran for ${today} — skipping`);
  return;
}
// Proceed with job...
// On completion: UPDATE calibration_lapse_runs SET finished_at = now(), users_demoted = X ...
```

### Pattern 5: React Flow Tree (Invite Chain Visualization)

```typescript
// Source: https://reactflow.dev/examples/layout/dagre
// @xyflow/react v12 + @dagrejs/dagre
import ReactFlow, { Background, Controls, MiniMap, useNodesState, useEdgesState } from '@xyflow/react';
import dagre from '@dagrejs/dagre';
import '@xyflow/react/dist/style.css';

const dagreGraph = new dagre.graphlib.Graph();
dagreGraph.setDefaultEdgeLabel(() => ({}));

const nodeWidth = 200;
const nodeHeight = 60;

function getLayoutedElements(nodes: Node[], edges: Edge[]) {
  dagreGraph.setGraph({ rankdir: 'TB' }); // Top-to-bottom tree
  nodes.forEach((node) => dagreGraph.setNode(node.id, { width: nodeWidth, height: nodeHeight }));
  edges.forEach((edge) => dagreGraph.setEdge(edge.source, edge.target));
  dagre.layout(dagreGraph);

  return {
    nodes: nodes.map((node) => {
      const { x, y } = dagreGraph.node(node.id);
      return { ...node, position: { x: x - nodeWidth / 2, y: y - nodeHeight / 2 } };
    }),
    edges,
  };
}

// Nodes are clickable — use onNodeClick to navigate to account detail
// Color-code by tier: inform=gray, connected=blue, empowered=green
// Suspended: add red border/indicator
```

### Pattern 6: Notifications Table

The `public.notifications` table is new and must be created in the Phase 7 schema migration.

```sql
CREATE TABLE IF NOT EXISTS public.notifications (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type        TEXT        NOT NULL,            -- 'calibration_warning_25', 'calibration_warning_30', 'demotion_confirmed'
  payload     JSONB       NOT NULL DEFAULT '{}',
  read_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notifications_user_unread
  ON public.notifications(user_id, created_at DESC)
  WHERE read_at IS NULL;
```

### Pattern 7: Admin Login Flow

Admin users use the SAME Supabase auth path as regular users (same `/api/auth/login` endpoint). The distinction is enforced by `requireAdmin` middleware which checks `admin_users` table. No separate login page is needed — the admin UI login page POSTs to `/api/auth/login` and, on success, checks `user.isAdmin` (returned from a `/api/admin/me` or similar endpoint).

The `admin_users` table is simple:
```sql
CREATE TABLE IF NOT EXISTS public.admin_users (
  user_id     UUID  PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Rows are inserted manually by a database migration for Alpha (no self-serve admin registration).

### Pattern 8: get_calibration_lapsed_users — Phase 7 Replacement

Phase 4 implemented a simplified version that returns any Empowered user missing any live topic. Phase 7 MUST replace this with a timestamp-aware version using `went_live_at`:

```sql
-- Phase 7 replacement: 30-day window based on went_live_at
CREATE OR REPLACE FUNCTION public.get_calibration_lapsed_users(
  p_days_threshold INTEGER DEFAULT 30
)
RETURNS TABLE (
  user_id UUID,
  overdue_topic_ids UUID[],
  days_overdue INTEGER
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT
    ep.user_id,
    array_agg(ct.id) AS overdue_topic_ids,
    (CURRENT_DATE - MIN(ct.went_live_at)::date)::integer AS days_overdue
  FROM empower.empowered_profiles ep
  JOIN inform.compass_topics ct ON ct.is_live = true
    AND ct.went_live_at IS NOT NULL
    AND ct.went_live_at <= now() - (p_days_threshold || ' days')::interval
  WHERE ep.is_active = true
  AND NOT EXISTS (
    SELECT 1 FROM inform.compass_responses cr
    WHERE cr.user_id = ep.user_id AND cr.topic_id = ct.id
  )
  GROUP BY ep.user_id;
$$;
```

The cron job calls this RPC three times with thresholds 25, 30, and 31 to identify which users need warnings vs. demotion.

### Anti-Patterns to Avoid

- **Exposing supabaseAdmin in admin routes directly:** Admin routes live in `src/routes/admin.ts` — the architecture test bans `supabaseAdmin` in `src/routes/`. Use `adminService.ts` in `src/lib/` for all data access.
- **Missing audit log on any admin action:** Every admin mutation (suspend, grant role, revoke, create invite, trigger demotion) must call `logAdminAction()` before returning 200. An unlogged admin action violates ADMN-05.
- **Cron without idempotency:** Do not rely on `noOverlap` alone for idempotency. `noOverlap` prevents concurrent process-level execution but does NOT prevent re-execution after a server restart. The `calibration_lapse_runs` table INSERT is the actual idempotency mechanism.
- **Treating tolerance_rating / legal_name as normal fields:** Admin access to these fields must be logged to `admin_audit_log` with action `'view_sensitive_profile'`. They are not omitted from admin API responses, but every access generates an audit event.
- **Re-using the Phase 4 get_calibration_lapsed_users RPC without replacing it:** The Phase 4 version has no `went_live_at` awareness — it returns all users missing any live topic, regardless of when the topic went live. Phase 7 must CREATE OR REPLACE with the timestamp-aware version.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tree visualization layout | Custom recursive position calculation | @xyflow/react + dagre | Dagre handles cycles, repositioning, zoom; hand-rolling is months of work |
| Cron scheduling | setInterval / setTimeout with manual drift correction | node-cron v4 | node-cron handles daylight saving, missed runs, timezone conversion |
| Admin UI auth state | React Context + useReducer | zustand (Civic Trivia pattern) | Established pattern; must match for future unified admin |
| Admin route guard | Per-route middleware application | `router.use(requireAuth, requireAdmin)` at top of admin.ts | Prevents forgetting middleware on any single route |
| Cron idempotency | In-memory flag | `calibration_lapse_runs` table (DATE PRIMARY KEY) | In-memory flag resets on server restart; DB key survives deploys |
| Notification creation | Direct INSERT in route | Service function wrapping INSERT | Keeps routes thin; consistent with existing service layer pattern |

**Key insight:** Admin UIs look simple but have many edge cases — accessible modals, keyboard navigation, error states, loading skeletons. Use Headless UI for interactive components (exactly as Civic Trivia does) rather than hand-rolling dropdown/dialog components.

---

## Common Pitfalls

### Pitfall 1: Architecture Test Will Flag supabaseAdmin in admin.ts

**What goes wrong:** Placing a `supabaseAdmin` import in `src/routes/admin.ts` causes the existing architecture test to fail.
**Why it happens:** The test scans `src/routes/` for any `supabaseAdmin` reference and throws. This is intentional enforcement.
**How to avoid:** Put ALL data access (including admin-specific queries) in `src/lib/adminService.ts`. Routes import named functions from adminService. The middleware (`src/middleware/requireAdmin.ts`) is exempt because the test only scans `src/routes/`.
**Warning signs:** TypeScript compilation succeeds but `npm test` fails on architecture test with "supabaseAdmin found in src/routes/".

### Pitfall 2: Cron Runs at Server Startup

**What goes wrong:** The cron job fires immediately when the server starts (if `runOnInit` is accidentally set, or if timezone/DST causes the expression to match at startup time).
**Why it happens:** node-cron v4's `schedule()` starts the task immediately by default. If the job runs at 2am UTC and a server restarts at exactly 2am UTC, it fires immediately.
**How to avoid:** Use `noOverlap: true` in options. The idempotency table check (INSERT on run_date, abort on conflict) is the primary guard — even if the cron fires twice, the second execution is a no-op.
**Warning signs:** Calibration logs showing two entries for the same `run_date`.

### Pitfall 3: React Flow Missing CSS Import

**What goes wrong:** React Flow renders nodes but they have no styles — handles are invisible, edges don't render correctly, zoom/pan doesn't work.
**Why it happens:** `@xyflow/react` requires `import '@xyflow/react/dist/style.css'` in main.tsx or the component file. This is easy to forget.
**How to avoid:** Add the CSS import at the top of `admin/src/main.tsx` (or the InviteTree component file).
**Warning signs:** Nodes render as plain unstyled divs; no minimap; no controls visible.

### Pitfall 4: Dagre Unmaintained Warning

**What goes wrong:** `@dagrejs/dagre` is marked "currently unmaintained" in React Flow documentation but is still recommended.
**Why it happens:** The original dagre maintainer archived the repo; @dagrejs is a maintained fork.
**How to avoid:** Use `@dagrejs/dagre` (the fork), not the original `dagre` package. The fork at v1.1.4 is stable and works with React Flow v12.
**Warning signs:** Using `npm install dagre` instead of `npm install @dagrejs/dagre` gets the unmaintained original.

### Pitfall 5: went_live_at is NULL for Seeded Topics

**What goes wrong:** The Phase 7 calibration RPC filters `WHERE ct.went_live_at IS NOT NULL`, which correctly excludes seeded topics. But if an admin manually sets `is_live = true` without setting `went_live_at`, those topics are also excluded.
**Why it happens:** The migration comment explicitly notes "went_live_at is NULL for seeded topics; set when is_live flips true via admin action." But the admin action to set `is_live = true` (the compass admin routes deferred from Phase 4) must also set `went_live_at = now()`.
**How to avoid:** In the Phase 7 admin compass topic update endpoint (`PUT /api/admin/compass/topics/:id`), when `is_live` transitions from `false` to `true`, also set `went_live_at = now()`. Consider a Postgres trigger as a safety net.
**Warning signs:** Topics are live but users are never flagged as lapsed because `went_live_at IS NULL` excludes them from the RPC.

### Pitfall 6: Admin Login Confusion

**What goes wrong:** Admin users try to log in at `/admin` and expect a separate auth system, but the admin UI uses the same `/api/auth/login` endpoint as regular users.
**Why it happens:** `ADMN-06` says "separate admin_users table keyed by user_id; being an authenticated user is not sufficient." This means the auth token is the same Supabase JWT — only the authorization check differs.
**How to avoid:** Admin UI login page POSTs to `/api/auth/login` exactly like regular auth. After login, the admin UI fetches `/api/admin/me` (or checks the user object) to verify admin status. If not admin, show "Access denied" without revealing admin exists.
**Warning signs:** Building a separate auth system or separate JWT issuer for admins — unnecessary and incompatible with the existing JWKS middleware.

### Pitfall 7: Cron Day-25/30/31 Logic Error

**What goes wrong:** Conflating the day threshold with calendar day counting. A topic that went live on day 0, at the cron on day 25, has been live for 25 days — but "25 days overdue" means the user has 5 more days before demotion (day 31 = demotion).
**Why it happens:** Off-by-one errors in `CURRENT_DATE - went_live_at::date`. The comparison is `>= 25 days` for warning, `>= 30 days` for final warning, `>= 31 days` for demotion.
**How to avoid:** Use `(CURRENT_DATE - ct.went_live_at::date) >= p_days_threshold` in the SQL. Test with synthetic topics that have `went_live_at` set to known past dates.
**Warning signs:** Users receiving demotion warning at day 24 or not until day 26.

---

## Code Examples

### Admin Routes File (Router-level Middleware Application)

```typescript
// Source: Pattern from Civic Trivia backend/src/routes/admin.ts + EV-Accounts middleware patterns
// File: backend/src/routes/admin.ts
import { Router, Request, Response } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import * as adminService from '../lib/adminService.js';

const router = Router();

// Apply both middlewares to ALL admin routes — no per-route repetition
router.use(requireAuth, requireAdmin);

router.get('/accounts', async (req, res) => {
  const { search, tier, standing, page = '1' } = req.query;
  const accounts = await adminService.listAccounts({ search, tier, standing, page: Number(page) });
  res.json(accounts);
});

router.post('/accounts/:userId/suspend', async (req, res) => {
  const { userId } = req.params;
  const actorId = (req as any).userId;
  await adminService.setAccountStanding(userId, 'suspended');
  await adminService.logAdminAction(actorId, 'suspend_account', userId);
  res.json({ ok: true });
});

export default router;
```

### node-cron v4 Daily Job Registration

```typescript
// Source: node-cron v4 source (github.com/node-cron/node-cron)
// TaskOptions: { timezone?, name?, noOverlap?, maxExecutions?, maxRandomDelay? }
import cron from 'node-cron';
import { runCalibrationLapseJob } from '../lib/cronService.js';

export function startCrons(): void {
  cron.schedule('0 2 * * *', async () => {
    await runCalibrationLapseJob();
  }, {
    timezone: 'UTC',
    noOverlap: true,
    name: 'calibration-lapse'
  });
  console.log('[cron] Calibration lapse registered: daily 02:00 UTC');
}
```

### Calibration Lapse Job (Three-Threshold Approach)

```typescript
// Source: CRON-01 through CRON-04 requirements + existing supabaseAdmin.rpc() pattern
// File: backend/src/lib/cronService.ts
import { pool } from './db.js';
import { supabaseAdmin } from './supabase.js';
import { executeDemotion } from './empowerService.js';

export async function runCalibrationLapseJob(): Promise<void> {
  const today = new Date().toISOString().slice(0, 10);
  const jobStart = Date.now();

  // CRON-04: Idempotency — abort if already ran today
  const { rowCount } = await pool.query(
    'INSERT INTO public.calibration_lapse_runs (run_date) VALUES ($1) ON CONFLICT (run_date) DO NOTHING',
    [today]
  );
  if (rowCount === 0) {
    console.log(`[cron] Already ran for ${today} — skipping`);
    return;
  }

  let warned25 = 0, warned30 = 0, demoted = 0;

  try {
    // Day 25: Warning
    const { data: day25 } = await supabaseAdmin.rpc('get_calibration_lapsed_users', { p_days_threshold: 25 });
    // ... write notifications for day25 users (excluding those at 30+)

    // Day 30: Final warning
    const { data: day30 } = await supabaseAdmin.rpc('get_calibration_lapsed_users', { p_days_threshold: 30 });
    // ... write final warning notifications for day30 users (excluding those at 31+)

    // Day 31: Demotion
    const { data: day31 } = await supabaseAdmin.rpc('get_calibration_lapsed_users', { p_days_threshold: 31 });
    for (const user of day31) {
      await executeDemotion(user.user_id, {
        reason: 'calibration_lapse',
        overdue_topics: user.overdue_topic_ids,
        days_overdue: user.days_overdue
      });
      // Write demotion confirmation notification
      demoted++;
    }

    await pool.query(
      `UPDATE public.calibration_lapse_runs
       SET finished_at = now(), users_warned_25 = $2, users_warned_30 = $3, users_demoted = $4
       WHERE run_date = $1`,
      [today, warned25, warned30, demoted]
    );
  } catch (err) {
    await pool.query(
      'UPDATE public.calibration_lapse_runs SET error_message = $2 WHERE run_date = $1',
      [today, String(err)]
    );
    throw err;
  }

  console.log(JSON.stringify({
    level: 'info', job: 'calibration-lapse',
    run_date: today, warned25, warned30, demoted,
    duration_ms: Date.now() - jobStart
  }));
}
```

### React Flow Tree (InviteTree Component Shell)

```typescript
// Source: https://reactflow.dev/examples/layout/dagre + @xyflow/react v12 API
import ReactFlow, { Background, Controls, MiniMap, useNodesState, useEdgesState } from '@xyflow/react';
import dagre from '@dagrejs/dagre';
import '@xyflow/react/dist/style.css';
import { useNavigate } from 'react-router-dom';

// Tier colors (designer discretion area — use Tailwind palette)
const TIER_COLORS = {
  inform:    '#94a3b8',   // slate-400
  connected: '#3b82f6',   // blue-500
  empowered: '#22c55e',   // green-500
};

export function InviteTree({ rootUserId }: { rootUserId?: string }) {
  const navigate = useNavigate();
  const [nodes, setNodes, onNodesChange] = useNodesState([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState([]);

  // Fetch tree data from GET /api/admin/invites/tree (or /api/admin/invites/tree/:userId)
  // Layout via getLayoutedElements(nodes, edges) using dagre
  // onNodeClick: navigate to /admin/accounts/:userId

  return (
    <div style={{ height: '600px' }}>
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onNodeClick={(_, node) => navigate(`/admin/accounts/${node.id}`)}
        fitView
      >
        <Background />
        <Controls />
        <MiniMap />
      </ReactFlow>
    </div>
  );
}
```

---

## Phase 7 API Routes Reference

### Admin API Routes (07-01)

All routes prefixed with `/api/admin/` and protected by `router.use(requireAuth, requireAdmin)`.

**Accounts:**
- `GET /api/admin/accounts` — list with search + filter (tier, standing)
- `GET /api/admin/accounts/:userId` — full account detail (legal_name, tolerance_rating, tier, roles, invite chain position, calibration lapse status) — ADMN-02, logged
- `POST /api/admin/accounts/:userId/suspend` — set account_standing = 'suspended' — ADMN-03
- `POST /api/admin/accounts/:userId/unsuspend` — set account_standing = 'active' — ADMN-03
- `POST /api/admin/accounts/:userId/demote` — call execute_demotion — ADMN-03

**Invites:**
- `GET /api/admin/invites` — list all invite codes
- `POST /api/admin/invites` — create invite code(s) — ADMN-01
- `DELETE /api/admin/invites/:codeId` — revoke active code — ADMN-01
- `GET /api/admin/invites/tree` — full cohort tree (all invite chains) — ADMN-01
- `GET /api/admin/invites/tree/:userId` — subtree rooted at userId — ADMN-01

**Roles (deferred from Phase 6):**
- `POST /api/admin/roles/grant` — call grantRole() from roleService — CIVIC-02
- `POST /api/admin/roles/revoke` — call revokeRole() from roleService — CIVIC-02

**Compass admin (deferred from Phase 4):**
- `POST /api/admin/compass/topics` — create topic
- `PUT /api/admin/compass/topics/:id` — update topic (including is_live + set went_live_at)
- `PUT /api/admin/compass/stances/:id` — update stance
- `PUT /api/admin/compass/politicians/:id/answers` — update politician answers
- `POST /api/admin/compass/politicians/:id/context` — set politician context
- `GET /api/admin/essentials/politicians` — list politicians (admin view)

**Cron log:**
- `GET /api/admin/cron-log` — list calibration_lapse_runs entries

**Dashboard:**
- `GET /api/admin/dashboard` — cohort stats (user counts by tier, pending verifications, recent invite activity)

---

## Schema Requirements (New Migration)

The Phase 7 migration creates:

1. `public.admin_users` — (user_id PK FK to users, created_at)
2. `public.admin_audit_log` — (id, actor_id FK, action TEXT, target_user_id FK nullable, details JSONB, created_at)
3. `public.notifications` — (id, user_id FK, type TEXT, payload JSONB, read_at TIMESTAMPTZ nullable, created_at)
4. `public.calibration_lapse_runs` — (run_date DATE PK, started_at, finished_at nullable, users_warned_25, users_warned_30, users_demoted, error_message nullable)
5. `public.get_calibration_lapsed_users` RPC — CREATE OR REPLACE with timestamp-aware version (p_days_threshold parameter)

RLS considerations:
- `admin_audit_log`: no user-facing SELECT policy — admin-only via service role
- `notifications`: SELECT policy for authenticated users to read own notifications (WHERE user_id = auth.uid())
- `calibration_lapse_runs`: no user-facing policy — admin-only
- `admin_users`: no user-facing policy

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `reactflow` npm package | `@xyflow/react` | v12 (2024) | Must use new package name; old package frozen at v11 |
| dagre (original) | @dagrejs/dagre | 2023 | Original unmaintained; use the maintained fork |
| node-cron v2/v3 (CommonJS) | node-cron v4 (ESM + TypeScript native) | May 2025 | `import cron from 'node-cron'` works with ESM; `noOverlap` replaces `waitForCompletion` |
| Hardcoded admin role in JWT | admin_users table check | ADMN-06 decision | Never store admin flag in JWT; check DB on every request |

**Deprecated/outdated:**
- `reactflow` v11 package: frozen, use `@xyflow/react` instead
- `dagre` (npm): unmaintained, use `@dagrejs/dagre`
- node-cron `waitForCompletion` option: replaced by `noOverlap` in v4

---

## Open Questions

1. **Admin UI: separate Vite app vs. served from Express**
   - What we know: MEMORY.md says "Vite + React (internal admin tool only)"; existing project has no frontend directory; Civic Trivia has a separate frontend directory
   - What's unclear: Should the admin Vite app be in `/admin/` (separate) or embedded in `/backend/src/admin-ui/`?
   - Recommendation: Create `/admin/` as a sibling to `/backend/` — matching Civic Trivia structure (`/frontend/`). During development, admin runs on a different port (e.g., 5174). For production, build output is served by Express as static files or deployed separately.

2. **Cron job: start it in index.ts or separate process**
   - What we know: MEMORY.md says "in-process node-cron for Alpha"; Civic Trivia starts crons in `server.ts` via `startExpirationCron()` and `startElectionDetectionCron()`
   - What's unclear: Should cron start in the existing `backend/src/index.ts` or in a separate entry point?
   - Recommendation: Add `startCalibrationLapseCron()` call in `backend/src/index.ts` inside the `if (env.NODE_ENV !== 'test')` guard — matching the conditional listen pattern already used.

3. **invite tree API: recursive SQL vs. application-level tree building**
   - What we know: `connect.invite_chains` table has inviter_id/invitee_id pairs. Fetching the full tree requires traversal.
   - What's unclear: Use Postgres recursive CTE (`WITH RECURSIVE`) or fetch all chains and build tree in JavaScript?
   - Recommendation: Use a Postgres recursive CTE for the full tree — it produces all nodes and edges in one query. JavaScript tree building is fine for small cohorts but recursive CTE is more robust. React Flow expects flat arrays of nodes/edges anyway.

4. **Architecture test: will admin.ts placement be flagged?**
   - What we know: The architecture test bans `supabaseAdmin` in `src/routes/`. Admin routes live at `src/routes/admin.ts`.
   - What's unclear: Does `adminService.ts` in `src/lib/` correctly exempt admin-tier queries from the ban?
   - Recommendation: Confirm by reading the architecture test before implementing. All supabaseAdmin calls in adminService.ts (lib/) are safe; routes file imports named functions only.

---

## Sources

### Primary (HIGH confidence)

- Civic Trivia Championships GitHub (master branch) — Admin patterns: AdminLayout, AdminDashboard, AdminGuard, authStore, backend admin routes, cron startCron.ts: https://github.com/EmpoweredVote/Civic-Trivia-Championships
- node-cron v4 TypeScript source (github.com/node-cron/node-cron/master) — TaskOptions interface confirms: `timezone`, `noOverlap`, `name`, `maxExecutions` options. Version 4.2.1 confirmed via npm registry.
- @xyflow/react npm registry — latest version 12.10.1 confirmed
- @dagrejs/dagre npm registry — latest version 1.1.4 confirmed
- reactflow.dev/examples/layout/dagre — dagre tree layout pattern, dagre.graphlib.Graph() API
- EV-Accounts existing codebase — middleware patterns (requireConnected, requireEmpowered), service layer pattern (adminService shape), architecture test constraint (supabaseAdmin banned in src/routes/)
- Supabase migrations 001-020 — existing schema, existing RPC functions, went_live_at column, invite_chains table structure

### Secondary (MEDIUM confidence)

- node-cron README (github.com/node-cron/node-cron) — confirms ESM import syntax, basic schedule() API, version 4.x is current
- React Flow documentation (reactflow.dev) — confirms dagre is recommended for trees, @xyflow/react is the current package name, dagre layout uses TB (top-to-bottom) direction

### Tertiary (LOW confidence)

- WebSearch results on admin dashboard patterns — confirm Tailwind + React Router sidebar pattern is standard; not directly verified against specific library versions

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — npm registry confirms versions; Civic Trivia confirms library choices
- Architecture: HIGH — patterns directly extracted from existing codebase + Civic Trivia source code
- Pitfalls: HIGH (architecture test pitfall) / MEDIUM (dagre/went_live_at pitfalls) — architecture test is verified by reading existing tests; others based on documentation + code review
- Cron implementation: HIGH — node-cron v4 source read directly from GitHub; TaskOptions interface confirmed

**Research date:** 2026-02-27
**Valid until:** 2026-03-27 (stable libraries; 30-day validity)
