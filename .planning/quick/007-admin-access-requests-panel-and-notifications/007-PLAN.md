---
phase: quick-007
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - backend/src/lib/emailService.ts
  - backend/src/lib/adminService.ts
  - backend/src/routes/admin.ts
  - backend/src/routes/auth.ts
  - backend/.env
  - backend/.env.example
  - admin/src/pages/admin/AccessRequestsPage.tsx
  - admin/src/pages/admin/AdminLayout.tsx
  - admin/src/App.tsx
autonomous: true

must_haves:
  truths:
    - "Admin can see all access requests listed newest-first in the admin panel"
    - "Admin receives an email when someone submits an access request"
    - "Access Requests page appears in the admin sidebar navigation"
  artifacts:
    - path: "backend/src/lib/emailService.ts"
      provides: "Resend email sending utility"
      exports: ["sendEmail"]
    - path: "backend/src/routes/admin.ts"
      provides: "GET /api/admin/access-requests endpoint"
    - path: "admin/src/pages/admin/AccessRequestsPage.tsx"
      provides: "Access Requests admin page"
      min_lines: 40
  key_links:
    - from: "admin/src/pages/admin/AccessRequestsPage.tsx"
      to: "/api/admin/access-requests"
      via: "apiFetch in useEffect"
      pattern: "apiFetch.*admin/access-requests"
    - from: "backend/src/routes/auth.ts"
      to: "backend/src/lib/emailService.ts"
      via: "sendEmail call after insertAccessRequest"
      pattern: "sendEmail"
---

<objective>
Add an admin Access Requests panel and email notifications for new access requests.

Purpose: Let the admin see who has requested access (waitlist) directly in the admin UI, and get notified by email in real-time when a new request comes in, so they can act quickly on invite decisions.

Output: GET /api/admin/access-requests endpoint, Resend email utility, email notification on POST /api/auth/request-access, and AccessRequestsPage in the admin UI.
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@backend/src/routes/admin.ts
@backend/src/routes/auth.ts
@backend/src/lib/adminService.ts
@admin/src/pages/admin/AdminLayout.tsx
@admin/src/App.tsx
@admin/src/pages/admin/InvitesPage.tsx
@admin/src/lib/api.ts
</context>

<tasks>

<task type="auto">
  <name>Task 1: Email service + admin GET endpoint + notification hook</name>
  <files>
    backend/src/lib/emailService.ts
    backend/src/lib/adminService.ts
    backend/src/routes/admin.ts
    backend/src/routes/auth.ts
    backend/.env.example
  </files>
  <action>
**1. Install Resend SDK:**

```bash
cd backend && npm install resend
```

**2. Create `backend/src/lib/emailService.ts`:**

A thin wrapper around the Resend SDK. This is the project's first transactional email utility.

```typescript
import { Resend } from 'resend';

const resend = process.env.RESEND_API_KEY
  ? new Resend(process.env.RESEND_API_KEY)
  : null;

export async function sendEmail(opts: {
  to: string;
  subject: string;
  html: string;
}): Promise<void> {
  if (!resend) {
    console.warn('[emailService] RESEND_API_KEY not set — skipping email:', opts.subject);
    return;
  }

  const { error } = await resend.emails.send({
    from: 'Empowered Vote <noreply@empowered.vote>',
    to: opts.to,
    subject: opts.subject,
    html: opts.html,
  });

  if (error) {
    console.error('[emailService] send failed:', error);
    // Do NOT throw — email failure should not break the request flow
  }
}
```

Key design decisions:
- Gracefully no-op when RESEND_API_KEY is not set (dev environments).
- Never throws — email is fire-and-forget; the access request itself must succeed even if email fails.
- `from` uses `noreply@empowered.vote` (Resend domain already verified per MEMORY.md).

**3. Add `listAccessRequests` to `backend/src/lib/adminService.ts`:**

Add near the existing `insertAccessRequest` function (around line 847):

```typescript
export async function listAccessRequests(): Promise<
  { id: string; email: string; requested_at: string }[]
> {
  const { data, error } = await supabaseAdmin
    .from('access_requests')
    .select('id, email, requested_at')
    .order('requested_at', { ascending: false });

  if (error) throw new Error(error.message);
  return data ?? [];
}
```

Uses `supabaseAdmin` (service role) — same pattern as `insertAccessRequest`. No RLS policy needed because admin reads always go through service role.

**4. Add GET /api/admin/access-requests to `backend/src/routes/admin.ts`:**

Import `listAccessRequests` from adminService (add to the existing import block at line 19-54).

Add the route handler (place it near the dashboard routes, after GET /api/admin/dashboard):

```typescript
/**
 * GET /api/admin/access-requests
 * Returns all access requests sorted newest-first.
 */
router.get('/access-requests', async (_req, res) => {
  try {
    const requests = await listAccessRequests();
    res.json({ requests });
  } catch (err) {
    console.error('[admin/access-requests] error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});
```

No audit logging needed — this is a read-only list view, not a sensitive detail view.

**5. Add email notification to POST /api/auth/request-access in `backend/src/routes/auth.ts`:**

Import `sendEmail` from emailService at the top of auth.ts:
```typescript
import { sendEmail } from '../lib/emailService.js';
```

After the successful `insertAccessRequest` call (line 421), add a fire-and-forget email before the response:

```typescript
await insertAccessRequest(parsed.data.email);

// Fire-and-forget admin notification — sendEmail never throws
const adminEmail = process.env.ADMIN_EMAIL;
if (adminEmail) {
  sendEmail({
    to: adminEmail,
    subject: 'New Access Request — Empowered Vote',
    html: `<p>Someone just requested access to Empowered Vote.</p>
           <p><strong>Email:</strong> ${parsed.data.email}</p>
           <p><strong>Time:</strong> ${new Date().toISOString()}</p>
           <p>Review in the <a href="https://accounts.empowered.vote/admin/access-requests">admin panel</a>.</p>`,
  });
}

res.status(201).json({ message: 'Access request submitted' });
```

Do NOT await `sendEmail` — it is intentionally fire-and-forget. The response should not be delayed by email delivery. `sendEmail` already handles errors internally.

**6. Update `backend/.env.example`:**

Add these two lines:
```
RESEND_API_KEY=re_your-resend-api-key
ADMIN_EMAIL=admin@empowered.vote
```

Note: `ADMIN_EMAIL=chris@empowered.vote` already exists in the actual `.env` — do NOT modify `.env`, only update `.env.example` for documentation.
  </action>
  <verify>
Run `cd backend && npx tsc --noEmit` — no type errors. Confirm `listAccessRequests` is exported from adminService. Confirm `sendEmail` is exported from emailService. Confirm the new GET route is registered in admin.ts. Confirm auth.ts imports sendEmail and calls it after insertAccessRequest.
  </verify>
  <done>
GET /api/admin/access-requests returns `{ requests: [{ id, email, requested_at }] }` sorted newest-first. POST /api/auth/request-access sends a notification email to ADMIN_EMAIL. Email gracefully no-ops when RESEND_API_KEY is unset. Backend typechecks cleanly.
  </done>
</task>

<task type="auto">
  <name>Task 2: Admin UI — Access Requests page + routing</name>
  <files>
    admin/src/pages/admin/AccessRequestsPage.tsx
    admin/src/pages/admin/AdminLayout.tsx
    admin/src/App.tsx
  </files>
  <action>
**1. Create `admin/src/pages/admin/AccessRequestsPage.tsx`:**

Follow the exact same pattern as InvitesPage.tsx — `apiFetch` in a `useCallback` + `useEffect`, loading/error states, table display.

```typescript
import { useEffect, useState, useCallback } from 'react';
import { apiFetch } from '../../lib/api';

interface AccessRequest {
  id: string;
  email: string;
  requested_at: string;
}

interface AccessRequestsResponse {
  requests: AccessRequest[];
}

export function AccessRequestsPage() {
  const [requests, setRequests] = useState<AccessRequest[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const fetchRequests = useCallback(() => {
    setLoading(true);
    setError(null);
    apiFetch<AccessRequestsResponse>('/admin/access-requests')
      .then((data) => setRequests(data.requests))
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    fetchRequests();
  }, [fetchRequests]);

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          Access Requests
        </h1>
        <span className="text-sm text-gray-500 dark:text-gray-400">
          {requests.length} request{requests.length !== 1 ? 's' : ''}
        </span>
      </div>

      {error && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 text-red-700 rounded-md text-sm dark:bg-red-900/20 dark:border-red-800 dark:text-red-400">
          {error}
        </div>
      )}

      {loading ? (
        <p className="text-gray-500 dark:text-gray-400">Loading...</p>
      ) : requests.length === 0 ? (
        <p className="text-gray-500 dark:text-gray-400">No access requests yet.</p>
      ) : (
        <div className="bg-white dark:bg-gray-900 shadow rounded-lg overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
            <thead className="bg-gray-50 dark:bg-gray-800">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Email
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wider">
                  Requested At
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
              {requests.map((req) => (
                <tr key={req.id} className="hover:bg-gray-50 dark:hover:bg-gray-800/50">
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white">
                    {req.email}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-400">
                    {new Date(req.requested_at).toLocaleString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
```

Matches existing admin page patterns: same heading style, same table structure (bg-white, shadow, rounded-lg), same loading/error/empty states, same dark mode classes.

**2. Add nav item to `admin/src/pages/admin/AdminLayout.tsx`:**

Add to the `navItems` array (line 4-15), after 'Invites' / 'Invite Tree' and before 'Cron Log':

```typescript
{ label: 'Access Requests', to: '/admin/access-requests' },
```

Place it logically near Invites since both relate to onboarding/access management.

**3. Add route to `admin/src/App.tsx`:**

Import AccessRequestsPage at the top (add after the InviteTreePage import):
```typescript
import { AccessRequestsPage } from './pages/admin/AccessRequestsPage';
```

Add the route inside the `<Route path="/admin" element={<AdminLayout />}>` block, after the invite tree routes (after line 81):
```tsx
<Route path="access-requests" element={<AccessRequestsPage />} />
```
  </action>
  <verify>
Run `cd admin && npx tsc --noEmit` — no type errors. Confirm AccessRequestsPage is imported in App.tsx and has a Route. Confirm AdminLayout navItems includes 'Access Requests'. Start the admin dev server (`cd admin && npm run dev`) and verify the page loads at /admin/access-requests without console errors.
  </verify>
  <done>
Access Requests page renders in admin UI at /admin/access-requests. Shows table of all requests (email + date) sorted newest-first. Nav sidebar includes "Access Requests" link. Page handles loading, error, and empty states. Matches existing admin UI patterns and brand styling.
  </done>
</task>

<task type="checkpoint:human-verify" gate="non-blocking">
  <what-built>
    Admin access requests panel with email notifications:
    1. GET /api/admin/access-requests endpoint returning all requests newest-first
    2. Email notification to ADMIN_EMAIL on new access request submission
    3. Access Requests page in admin UI with table display
  </what-built>
  <how-to-verify>
    1. Start backend and admin: `cd backend && npm run dev` and `cd admin && npm run dev`
    2. Navigate to admin panel -> confirm "Access Requests" appears in sidebar
    3. Click it -> confirm page loads and shows any existing requests (or empty state)
    4. Test the notification: POST to /api/auth/request-access with a test email and check that:
       - The request appears in the admin panel (refresh the page)
       - An email arrives at chris@empowered.vote (requires RESEND_API_KEY in .env — if not set, check backend logs for the "[emailService] RESEND_API_KEY not set" warning)
  </how-to-verify>
  <resume-signal>Type "approved" or describe issues</resume-signal>
</task>

</tasks>

<verification>
- `cd backend && npx tsc --noEmit` passes
- `cd admin && npx tsc --noEmit` passes
- GET /api/admin/access-requests returns `{ requests: [...] }` with correct shape
- POST /api/auth/request-access still returns 201 and now triggers email (or logs skip)
- Admin UI shows Access Requests in sidebar and renders the page
</verification>

<success_criteria>
- Admin can view all access requests in the admin panel, sorted newest-first
- New access requests trigger an email notification to ADMIN_EMAIL
- Email gracefully degrades when RESEND_API_KEY is not configured
- Access Requests page matches existing admin UI patterns (table, dark mode, loading/error states)
- Both backend and admin typecheck cleanly
</success_criteria>

<output>
After completion, create `.planning/quick/007-admin-access-requests-panel-and-notifications/007-SUMMARY.md`
</output>
