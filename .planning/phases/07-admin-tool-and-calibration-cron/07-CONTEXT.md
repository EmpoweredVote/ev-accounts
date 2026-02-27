# Phase 7: Admin Tool and Calibration Cron - Context

**Gathered:** 2026-02-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Administrators can manage the Alpha cohort through a secure internal UI, and the platform automatically enforces calibration commitments via a daily scheduled job — with every action and every automated event logged.

Delivers three things:
1. Admin API — `/api/admin/*` routes with `requireAdmin` middleware and audit logging on every action
2. Admin React UI (Vite) — invite management, account review, cohort dashboard, invite chain visualization
3. Calibration cron — daily lapse enforcement, idempotency, day-25 warning, day-30 final warning, day-31 demotion

</domain>

<decisions>
## Implementation Decisions

### Admin UI structure
- Dashboard with cohort stats is the landing view (user counts by tier, pending verifications, recent invite activity)
- Sidebar navigation with sections: Dashboard, Accounts, Invites, Cron Log
- Admin infrastructure must be designed as a general-purpose framework compatible with the existing Civic Trivia Championships admin panel (https://github.com/EmpoweredVote/Civic-Trivia-Championships) — not a one-off tool. Researcher should review that repo for existing patterns before planning.
- Roles section should also be included for the deferred Phase 6 admin grant/revoke role routes

### Account review capability
- Individual account detail shows full profile + audit trail: legal_name, tolerance_rating, tier, standing, roles, invite chain position, calibration activity, consent records
- Admins can take write actions from the account detail view: suspend/unsuspend (toggle account_standing), manually trigger execute_demotion, grant/revoke roles
- Account list has search (by name/email) + filter by tier (Inform/Connected/Empowered) and account_standing (active/suspended)
- Empowered accounts show calibration lapse status: days since last calibration, which live topics are overdue, warning/demotion risk indicator

### Invite chain visualization
- Visual tree diagram (graphical, interactive, zoomable) — not an indented list
- Both global tree view (full cohort from seed accounts) and per-account drill-down (subtree rooted at any selected user)
- Nodes are clickable — clicking navigates to that user's account detail view
- Nodes are color-coded by tier (Inform/Connected/Empowered); suspended accounts visually flagged

### Calibration cron timing
- Day 25: write warning notification with specific topics that need calibration
- Day 30: write "final warning" notification — user is not demoted yet, has until day 31
- Day 31: if still uncalibrated, `execute_demotion` runs
- NOTE: ROADMAP.md says "day 30 demotion" but the user has revised this to day 31 (day 30 = final warning, day 31 = actual demotion). Plans should use day 31.

### Notification delivery
- In-app only — no email in Phase 7
- New `public.notifications` table: user_id, type, payload (JSONB), read_at, created_at
- Table designed to be reusable for future notification types beyond calibration
- Day-25 content: generic warning + specific list of topics needing calibration
- Day-30 content: final warning — demotion will execute if not calibrated before next cron run
- Day-31 content: demotion confirmation (written after execute_demotion completes)

### Deferred admin routes (from prior phases)
- **From Phase 4 (compass admin routes):** topics/create, topics/update, stances/update, compass/politicians/context, `PUT /compass/politicians/:id/answers`, `GET /essentials/politicians` — all belong in Phase 7 admin API
- **From Phase 6 (role admin routes):** `POST /api/admin/roles/grant`, `POST /api/admin/roles/revoke` — `grantRole` and `revokeRole` in `roleService.ts` are ready, just need HTTP endpoints with requireAdmin middleware
- These must be included in 07-01-PLAN.md task list

### Claude's Discretion
- Exact dashboard stat cards layout and styling
- D3 vs. React Flow vs. other library for tree diagram (researcher should evaluate)
- Specific color values for tier coding
- Admin login flow (whether admin users use the same auth path or a dedicated login)
- Cron idempotency table schema details

</decisions>

<specifics>
## Specific Ideas

- Admin infrastructure should feel extensible — Civic Trivia Championships already has an admin panel, and this admin should be designed to eventually serve as the unified admin for all Empowered Vote features. Researcher should read the existing admin panel repo before planning.
- Day 31 demotion timing: user explicitly revised the roadmap's "day 30" to day 30 = final warning, day 31 = demotion. This is a product decision, not a technical one.
- The privacy goal for Connected accounts: "I'd love to eventually live in a world where even we do not know the identities of Connected accounts until they empower." Captured as deferred idea.

</specifics>

<deferred>
## Deferred Ideas

- **Email notifications** — day-25/30 warning emails deferred; in-app only for Phase 7. Email infrastructure (Resend, SendGrid, or Supabase transactional email) is a future phase decision.
- **Third-party identity silo for Connected accounts** — future privacy architecture where even admins cannot view legal_name/personal info of Connected users until they empower. Would require an independent third party to partially silo identity data. Out of scope for Alpha.

</deferred>

---

*Phase: 07-admin-tool-and-calibration-cron*
*Context gathered: 2026-02-27*
