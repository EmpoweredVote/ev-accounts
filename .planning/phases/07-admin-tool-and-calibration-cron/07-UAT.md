---
status: testing
phase: 07-admin-tool-and-calibration-cron
source: 07-01-SUMMARY.md, 07-02-SUMMARY.md
started: 2026-02-28T00:00:00Z
updated: 2026-02-28T00:00:00Z
---

## Current Test

number: 10
name: Cron Idempotency (Code Check)
expected: |
  Open backend/src/lib/cronService.ts. The job starts with an INSERT ON
  CONFLICT (run_date) DO NOTHING check that returns early if a run already
  exists for today. This is a code review test, not a live test.
result: pass

## Tests

### 1. Admin Login
expected: Login page loads, submit credentials, redirected to dashboard with sidebar visible.
result: pass

### 2. Dashboard Stats
expected: Dashboard shows three sections — Users by Tier (Inform/Connected/Empowered counts), Users by Standing (Active/Suspended), and Invite Activity (Total/Claimed/Pending codes). Numbers reflect real data, not zeros across the board.
result: pass

### 3. Accounts List
expected: Click Accounts in sidebar. A table loads showing accounts with Name, Email, Tier badge, Standing badge, and Created date. The search bar and filter dropdowns are visible.
result: pass

### 4. Account Detail
expected: Click any row in the accounts table. A detail page loads showing the user's profile, a section labeled "Admin-only" containing legal_name and tolerance_rating fields, and action buttons (Suspend/Unsuspend, Demote).
result: pass

### 5. Invite Codes List
expected: Click Invites in sidebar. A table loads showing invite codes with Code, Created By, Claimed By, Status, and Created date columns. A "Create Invite" button is visible at the top.
result: pass

### 6. Create Invite Code
expected: Click "Create Invite". A new unclaimed invite code appears in the table.
result: pass

### 7. Invite Tree
expected: Click "Invite Tree" in sidebar (or "View Full Tree" button). An interactive diagram loads showing nodes for each user color-coded by tier. The diagram is zoomable and pannable.
result: pass
note: No nodes visible yet — expected, no invite chains exist. Diagram loads and is interactive.

### 8. Cron Log
expected: Click Cron Log in sidebar. The page loads (table may be empty if no cron runs have occurred yet — that's fine, "No cron runs recorded yet" is the correct empty state).
result: pass

### 9. Non-Admin Access Blocked
expected: The /api/admin/* routes require admin status. A regular authenticated user (non-admin) hitting any admin endpoint receives a 403. (Skip this test if you only have one account — mark as n/a)
result: n/a

### 10. Cron Idempotency (Code Check)
expected: Open backend/src/lib/cronService.ts. The job starts with an INSERT ON CONFLICT (run_date) DO NOTHING check that returns early if a run already exists for today. This is a code review test, not a live test.
result: pass
note: cron_upsert_lapse_run uses ON CONFLICT DO NOTHING; returns immediately if row already exists for today.

## Summary

total: 10
passed: 9
issues: 0
pending: 0
skipped: 1

## Gaps

[none yet]
