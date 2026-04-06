# Feature Landscape — v1.9 Delegated Authority Roles

**Domain:** Civic platform contributor roles — delegated authority with geo-scoping and audit trail
**Researched:** 2026-04-02
**Scope:** Role system redesign (from flat slug grants to scoped grants), contributor portal, admin
tooling for grant/revoke, per-user audit in account detail, global audit dashboard, Civic Spaces
Volunteer role, ESSENTIALS-PROV env var change

---

## Current State (Baseline)

Understanding what already exists prevents re-implementing what is already built.

**`public.roles` (lookup table, Phase 6):** rows for `contributor`, `candidate`, `maven`, plus
inactive legacy rows. No feature scoping, no geo scoping.

**`public.user_roles` (Phase 6):** columns `user_id`, `role_id` (FK to roles), `granted_by`,
`granted_at`, `revoked_at`. Partial unique index on `(user_id, role_id) WHERE revoked_at IS NULL`.
No `feature_scope` column. No `jurisdiction_geoid` column.

**`POST /api/admin/roles/grant` and `POST /api/admin/roles/revoke`** exist but accept only
`{ user_id, role_slug }` — no scoping parameters.

**`public.admin_audit_log`** exists. `logAdminAction(actorId, action, targetUserId, details)` is
the established pattern. Every admin mutation calls it before returning 200.

**`requireAdmin` middleware:** flat boolean check against `public.admin_users`. No role-based
middleware exists.

**Civic Spaces `civic_spaces.moderators` table:** separate system. Moderators are granted via a
direct INSERT — it is unrelated to the `public.user_roles` system. `useIsModerator` hook in the
Civic Spaces frontend queries this table directly.

**Trivia schema:** CTC connects directly to Postgres with the `trivia_service` role. Accounts has
no API surface for trivia CRUD. The `trivia.questions`, `trivia.collections`, `trivia.topics`, and
`trivia.collection_questions` tables are owned and managed by the CTC application.

---

## Table Stakes

Features that must exist for v1.9 to have any value. Missing any one of these means the role
system does not function.

| Feature | Why Required | Complexity |
|---------|-------------|------------|
| `feature_scope` column on `user_roles` | Distinguishes compass editor from essentials editor | Low (ADD COLUMN) |
| `jurisdiction_geoid` column on `user_roles` | The geo-scoped authority premise. NULL = national. | Low (ADD COLUMN) |
| `resource_id` column on `user_roles` | Campaign Manager is scoped to a single `politician_id` | Low (ADD COLUMN) |
| Partial unique index update | Current index is `(user_id, role_id)`. New index must be `(user_id, role_id, feature_scope, jurisdiction_geoid, resource_id)` | Low |
| `checkPermission(userId, feature, geoid?, resourceId?)` server function | Route middleware needs a single function to enforce scoped authorization. Returns boolean. | Medium |
| Five new role slugs in `public.roles` | `compass_stance_editor`, `campaign_manager`, `ctc_content_editor`, `essentials_data_editor`, `volunteer` | Low (seed rows) |
| Admin grant form: add feature_scope + geoid + resource_id fields | Grant UI must carry the new schema fields | Medium |
| Admin revoke: must target correct scoped row | A user may hold compass editor for county A and county B simultaneously; revoke must specify which | Medium |
| Contributor portal: new React app (or new route in `/app`) | Distinct UX from end-user app. Role-holders land here after login. | High |
| `GET /api/contributor/me` endpoint | Returns caller's active scoped role grants. Portal home uses this to render role tiles. | Low |
| Role-specific API routes at `/api/contributor/*` | Each role type gets endpoints enforced by `checkPermission`. See per-role breakdown below. | High |
| Per-user audit log tab in admin account detail | Existing account detail page needs a Roles tab showing all grants (active + revoked) and the admin who made each change | Medium |
| Global audit dashboard: filter by role type + jurisdiction | New admin page. Reads from `admin_audit_log` filtered by `details->>'feature_scope'` and `details->>'jurisdiction_geoid'` | Medium |
| ESSENTIALS-PROV: add `ESSENTIALS_SERVICE_KEY` to Render + `.env.example` | Zero code changes. Env var only. | Low |

---

## Per-Role Type: Concrete Behaviors and Boundaries

### Role 1: Compass Stance Editor

**Slug:** `compass_stance_editor`
**Required tier:** Connected or Empowered
**Scope dimensions:** `feature_scope = 'compass'`, `jurisdiction_geoid` = a GEOID (county, state,
or congressional) or NULL for national. No `resource_id`.

**Can do:**
- `GET /api/contributor/compass/politicians` — list politicians whose `district_id` matches their
  authorized jurisdiction(s). Does NOT return all politicians nationally.
- `GET /api/contributor/compass/politicians/:id/answers` — read current stances for an authorized
  politician.
- `PUT /api/contributor/compass/politicians/:id/answers` — replace all stances for an authorized
  politician. Calls the existing `admin_update_politician_answers` RPC. Logged to `admin_audit_log`
  with `action: 'contributor:compass:politician:answers:replace'`, `details` including
  `politician_id`, `answer_count`, and the contributor's `jurisdiction_geoid`.
- `GET /api/contributor/compass/politicians/:id/:topicId/context` — read context for any topic.
- `POST /api/contributor/compass/politicians/:id/context` — write context (reasoning + sources) for
  an authorized politician.

**Cannot do:**
- Cannot update stances for any politician outside their authorized jurisdiction.
- Cannot create or delete topics (topic lifecycle is admin-only).
- Cannot create or delete stances on topics (that changes the structural meaning of the scale).
- Cannot update stance text (that changes the scale options all users see).
- Cannot see other contributors' identity, authorization scope, or assignments.
- Cannot access any other feature scope (essentials, trivia, civic spaces).
- Cannot view any user data, XP, gems, or account details.

**Contributor portal home screen:** Shows a list of politicians they are authorized to update,
with the current answer count per politician and a "Last updated" timestamp from the
`admin_audit_log`. Click-through opens a stance editor UI (reuses the compass admin UI pattern
from CompassV2).

---

### Role 2: Campaign Manager

**Slug:** `campaign_manager`
**Required tier:** Connected or Empowered
**Scope dimensions:** `feature_scope = 'compass'`, `resource_id = politician_id` (single UUID).
`jurisdiction_geoid` is irrelevant — the `resource_id` is the sole authorization boundary.

This is the most tightly scoped role. The threat model: a campaign manager for Candidate A must
have zero ability to read Candidate B's stances before Candidate B has published them publicly.
The authorization check is not "does this politician's district match?" but "does this politician's
UUID match this user's `resource_id`?"

**Can do:**
- `GET /api/contributor/compass/politicians/:id/answers` — only for their exact `resource_id`
  politician UUID. 403 for any other ID.
- `PUT /api/contributor/compass/politicians/:id/answers` — only for their exact `resource_id`.
  Logged same as Compass Stance Editor.
- `POST /api/contributor/compass/politicians/:id/context` — only for their exact `resource_id`.
- `GET /api/contributor/compass/topics` — read topics and stances (needed to compose an answer
  update). Public data — no restriction needed here beyond authentication.

**Cannot do:**
- Cannot call `GET /api/contributor/compass/politicians` (the list endpoint). Must use their
  pre-assigned `resource_id` directly. This prevents enumerating other politicians in the system.
- Cannot read stances for any politician other than their assigned `resource_id`.
- Cannot read context for any politician other than their assigned `resource_id`.
- Cannot list or discover politicians in their geographic area.
- Cannot access any other feature scope.
- Cannot be granted this role with `jurisdiction_geoid` — only `resource_id` is meaningful for
  this role type. The grant form must enforce this: if role slug is `campaign_manager`,
  `jurisdiction_geoid` field is hidden and `resource_id` (politician picker) is required.

**Contributor portal home screen:** Shows exactly one politician card — their assigned politician's
name, photo, office title, current stance count, and "Last updated" from the audit log. No list,
no navigation to other politicians.

---

### Role 3: CTC Content Editor

**Slug:** `ctc_content_editor`
**Required tier:** Connected or Empowered
**Scope dimensions:** `feature_scope = 'ctc'`, `jurisdiction_geoid` = a GEOID (determines which
election races, and therefore which questions, they may edit). NULL = all jurisdictions.

**Architecture constraint (HIGH confidence, from Phase 41 code):** CTC owns the `trivia` schema
via the `trivia_service` Postgres role. Accounts does not have API routes for trivia CRUD. CTC
connects directly to the database.

**Implication:** The accounts API cannot delegate CTC content editing directly — it would require
either (a) exposing new accounts API routes that proxy trivia writes, or (b) CTC querying the
accounts API to check whether the calling user has a `ctc_content_editor` grant and then enforcing
authorization in CTC itself.

**Recommended approach for v1.9:** Option (b). Accounts provides a `GET /api/contributor/me`
endpoint that returns the caller's active scoped role grants including `ctc_content_editor` grants
with their jurisdiction. CTC calls this endpoint when a user tries to edit a question, checks
whether the grant covers the question's jurisdiction, and enforces the restriction natively. This
avoids creating a new API proxy surface in accounts for a schema accounts doesn't own.

**What accounts provides:**
- `GET /api/contributor/me` — returns active role grants including `{ role_slug: 'ctc_content_editor', jurisdiction_geoid: '...', resource_id: null }`.
- No content write endpoints in accounts for trivia.

**What CTC must build:** A contributor mode that reads the accounts role grants and scopes its
question editor accordingly.

**Cannot do (enforced by CTC, informed by accounts grant):**
- Cannot edit questions for races outside their authorized jurisdiction.
- Cannot delete questions (destructive — admin-only in CTC).
- Cannot create new election races.

**Contributor portal home screen in accounts portal:** A tile labeled "CTC Content Editor" with
their authorized jurisdiction. A link to the CTC contributor interface (CTC's URL). Accounts
portal is informational here — it does not host the editor UI.

---

### Role 4: Essentials Data Editor

**Slug:** `essentials_data_editor`
**Required tier:** Connected or Empowered
**Scope dimensions:** `feature_scope = 'essentials'`, `jurisdiction_geoid` = GEOID of the
jurisdiction they may edit. NULL = national.

The essentials schema is large (~30 tables) but an Essentials Data Editor has a narrow mandate:
updating biographical and office data for politicians in their jurisdiction. This is not the full
admin politician CRUD — it is a limited subset.

**Can do:**
- `GET /api/contributor/essentials/politicians` — list politicians whose `district_id` maps to
  their authorized jurisdiction. Same geo-filter logic as Compass Stance Editor.
- `PATCH /api/contributor/essentials/politicians/:id` — update a restricted subset of fields:
  `office_title`, `photo_origin_url`, `representing_city`, `representing_state`, `district_label`.
  Cannot change `district_type`, `district_id`, `is_active`, `is_candidate`, `is_vacant` — those
  require admin review because they affect data integrity and platform routing.
- `PUT /api/contributor/essentials/politicians/:id/contacts` — upsert contact records (phone, fax,
  email, website) for their authorized politicians. Contacts are factual, frequently stale, and
  worth crowdsourcing.
- `POST /api/contributor/essentials/politicians/:id/context` — write context/reasoning if
  Essentials gets a context model (deferred; not in v1.9 scope, just flag the extensibility).

**Cannot do:**
- Cannot add or remove politicians from Essentials (create/delete are admin-only).
- Cannot change `district_type`, `district_id`, `is_active`, `is_candidate`, `is_vacant`.
- Cannot edit bills, votes, committees, endorsements, judicial records — those are ingested
  from external data sources, not manually curated.
- Cannot access compass stances.
- Cannot see other users' data.

**Contributor portal home screen:** List of politicians in their authorized jurisdiction with a
"Data completeness" indicator (% of editable fields populated). Click-through opens a bio editor.

---

### Role 5: Volunteer

**Slug:** `volunteer`
**Required tier:** Connected or Empowered
**Scope dimensions:** `feature_scope = 'civic_spaces'`, `jurisdiction_geoid` optionally set
(limits which slices they moderate). NULL means their grants apply across all slices.

**What a Volunteer does in Civic Spaces:** The Civic Spaces `civic_spaces.moderators` table is the
existing gate for moderation access in that app. The Volunteer role in accounts is how an admin
grants that access — it is the external authorization signal that the Civic Spaces app consumes.

**Integration pattern:** Same as CTC — Civic Spaces checks `GET /api/contributor/me` (or a new
dedicated endpoint `GET /api/roles/me/volunteer-grants`) at login, and if a `volunteer` grant
exists, the app inserts a row in `civic_spaces.moderators` (or reuses an existing row). Accounts
does not write to `civic_spaces.moderators` directly — the Civic Spaces app does, using its own
service-role connection.

**Can do (in Civic Spaces, once provisioned):**
- Access the moderation queue (`ModeratorQueue` component is already built).
- Perform mod actions: remove, dismiss, warn, suspend — all via existing `civic_spaces.mod_action`
  RPC (already built in Phase 5).
- If `jurisdiction_geoid` is set on their grant: only see flags for posts in slices that match
  their geoid. This requires the Civic Spaces `get_mod_queue` RPC to gain a `p_slice_geoid` filter
  parameter — that is a Civic Spaces implementation detail, not an accounts API change.

**Cannot do:**
- Cannot grant volunteer/moderator status to other users.
- Cannot suspend platform-level accounts (suspend in Civic Spaces is space-level only; permanent
  account suspension remains admin-only in accounts API).
- Cannot read non-public user data from accounts (display_name is public; that is all they get).

**Accounts contributor portal home screen:** A tile labeled "Civic Volunteer" with their assigned
jurisdiction (or "All spaces"). A link to the Civic Spaces app. Accounts portal is informational
here — the actual moderation UI is in Civic Spaces.

---

## Table Stakes: Admin Tooling

These belong in the existing admin tool at `accounts.empowered.vote/admin`.

| Feature | Why Required | Where it Lives |
|---------|-------------|----------------|
| Grant form: role picker shows only new v1.9 roles | Old "contributor", "candidate", "maven" slugs are separate from the scoped roles. The form must distinguish them clearly. | Admin RolesPage.tsx |
| Grant form: conditional fields based on role slug | Campaign Manager shows only politician picker (resource_id). Other roles show jurisdiction picker. CTC/Volunteer show jurisdiction picker or "all". | Admin RolesPage.tsx |
| Revoke must accept scoped row target | Because a user may hold `compass_stance_editor` for two different jurisdictions, revoke must specify which grant by its row ID or by the combination (user_id + role_id + feature_scope + jurisdiction_geoid). | Admin RolesPage.tsx + `/api/admin/roles/revoke` |
| Per-user Roles tab in account detail | Lists all grants (active and revoked) with grantor, granted_at, revoked_at, jurisdiction, resource label. | Admin AccountDetail.tsx |
| Global audit dashboard | New admin page. Filterable by: `feature_scope`, `jurisdiction_geoid`, date range. Reads `admin_audit_log` WHERE action starts with `'contributor:'`. | New admin page |
| Audit log entries for contributor actions | Every write action in the contributor portal routes calls `logAdminAction()` with action string starting with `'contributor:'` and details including `feature_scope`, `jurisdiction_geoid`, `resource_id`, affected resource ID. | contributor route handlers |

---

## Audit Log: Granularity Decision

**Recommendation: action-level with old/new snapshot in details. Not field-level diff.**

Rationale: field-level diff (e.g., `{ office_title: { old: "...", new: "..." } }`) is more
informative but significantly more complex to implement. For v1.9 Alpha, the right level is:

```json
{
  "action": "contributor:compass:politician:answers:replace",
  "actor_id": "<contributor user UUID>",
  "target_user_id": null,
  "details": {
    "feature_scope": "compass",
    "jurisdiction_geoid": "18105",
    "politician_id": "<uuid>",
    "answer_count": 12,
    "role_slug": "compass_stance_editor",
    "grant_id": "<user_roles row UUID>"
  }
}
```

For Essentials updates, include the fields changed as a key list (not values):

```json
{
  "action": "contributor:essentials:politician:patch",
  "details": {
    "feature_scope": "essentials",
    "jurisdiction_geoid": "18105",
    "politician_id": "<uuid>",
    "fields_changed": ["office_title", "photo_origin_url"],
    "role_slug": "essentials_data_editor"
  }
}
```

Storing old values is valuable but introduces storage bloat for politician answers (12 values per
update). **Do not store old answer values in the audit log for v1.9.** Flag this as a Phase X
enhancement if auditors need reversibility.

---

## Contributor Portal: Home Screen Pattern

The portal is a separate React app (not inside `/admin`, not inside `/app`). It lives at a new
subdomain, e.g. `contribute.empowered.vote`. Or it can be a route inside `/app` — decision deferred
to roadmap, but the UI/UX must be distinct from the end-user app.

**Auth flow:** Same Auth Hub redirect pattern. Contributor logs in at Auth Hub, redirected back
with token. Portal calls `GET /api/contributor/me` on load.

**`GET /api/contributor/me` response:**

```json
{
  "grants": [
    {
      "id": "<user_roles UUID>",
      "role_slug": "compass_stance_editor",
      "feature_scope": "compass",
      "jurisdiction_geoid": "18105",
      "jurisdiction_label": "Monroe County, IN",
      "resource_id": null,
      "resource_label": null,
      "granted_at": "2026-04-01T..."
    }
  ]
}
```

**Home screen layout:** One card per active grant. Each card shows:
- Role name in plain English ("Compass Stance Editor")
- Jurisdiction or resource label ("Monroe County, IN" or "Rep. Jane Smith")
- Primary action button ("Edit Stances" / "Open CTC Editor" / "Go to Civic Spaces")

If no grants: "You have no active contributor roles. Contact an admin if this is unexpected."

---

## Differentiators

Features that are not strictly required for v1.9 to work but provide meaningful value.

| Feature | Value | Complexity | Recommendation |
|---------|-------|-----------|----------------|
| Revision history on politician answers | Lets admins see drift over time from a Campaign Manager's edits | Medium | Defer to v2 |
| Multi-jurisdiction grant in single row | A state-level editor covering all counties in a state without N separate grants | Low schema, Medium UI | Defer to v2 — start with one grant per jurisdiction |
| Notification to contributor when role is granted/revoked | Common courtesy UX | Low | Include in v1.9 — use existing Supabase email |
| Contributor-facing audit trail ("Your recent edits") | Transparency to contributors about their own history | Low | Include in v1.9 — filter admin_audit_log by actor_id |
| Expiry date on grants | "This grant is valid through the 2026 election" | Low schema | Defer to v2 |
| Read-only comparison mode for Campaign Manager | Let them see the "landscape" without rival data — only topics, not opponent answers | Medium | Defer — not safe enough to design quickly |

---

## Anti-Features

Things to deliberately NOT build in v1.9.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Campaign Manager "landscape view" showing all politicians' stances | Direct violation of the tighter leash. Even read-only is too risky — they see where gaps are. | They get topics only, not any other politician's answers. |
| Contributor self-service grant requests via the portal | Admins must retain full control over who gets what in Alpha. Self-service is a v3 feature. | Admin-only grant in the admin tool. |
| Trivia CRUD API routes in accounts | Accounts doesn't own the trivia schema. Adding a proxy layer creates an ownership boundary violation. | CTC enforces its own role check using accounts' role grant data. |
| Volunteer "suspend account" that affects accounts tier | Space-level actions must not bleed into account standing. `civic_spaces.connected_profiles.account_standing` is a local copy — the canonical record is in `connect.connected_profiles`. | Volunteer moderation actions stay within the `civic_spaces.*` context. |
| Single mega-endpoint `GET /api/contributor/resources` that returns everything | Mixing scopes creates accidental data exposure. A compass editor call should not even receive a 403 for essentials data — the endpoint shouldn't exist for them. | Separate route prefixes per feature scope. |
| `feature_scope` as a freeform text field | No validation = typos that silently grant access or silently deny it. | Use a defined enum or constrained CHECK in the migration. |
| Global contributor audit dashboard that shows account standing, XP, or gems | Scope creep — contributors are not admins. | Audit dashboard shows only contributor actions (action LIKE 'contributor:%'). |

---

## Feature Dependencies

```
Schema migration (feature_scope + jurisdiction_geoid + resource_id on user_roles)
  → checkPermission() function
    → all contributor API routes
      → contributor portal frontend

Admin grant form updates (new fields)
  → role grant endpoint accepts new fields
    → revoke endpoint can target scoped rows

GET /api/contributor/me
  → contributor portal home screen
  → CTC role check integration
  → Civic Spaces volunteer provisioning
```

---

## MVP Recommendation for v1.9

Build in this order:

1. **Schema migration** — add three columns, update unique index, seed five role slugs.
2. **`checkPermission()` function** — the authorization primitive everything else uses.
3. **`GET /api/contributor/me`** — portal home and CTC/Civic Spaces integrations depend on this.
4. **Compass Stance Editor** — clearest scope, existing admin routes provide the template.
5. **Campaign Manager** — same routes as Compass Stance Editor but with resource_id enforcement.
6. **Essentials Data Editor** — needs new restricted PATCH endpoint (not the full admin PATCH).
7. **Admin grant/revoke updates** — accept scoped fields, revoke by row ID.
8. **Admin UI: grant form + per-user roles tab** — frontend work on existing admin tool.
9. **Contributor portal** — new React app or new route, home screen + role UIs.
10. **Global audit dashboard** — reads existing log data; low risk, high value.
11. **CTC Content Editor** — integration pattern, not a new API surface. Documentation + role grant support.
12. **Volunteer** — same pattern as CTC. Civic Spaces integration docs + role grant support.
13. **ESSENTIALS-PROV** — can be done any time, independent of all the above.

Defer to post-v1.9: multi-jurisdiction grants, revision history, grant expiry, Campaign Manager
landscape view, self-service grant requests.

---

## Sources

- `supabase/migrations/20260227000020_phase6_roles_schema.sql` — current roles schema (verified)
- `backend/src/routes/admin.ts` — existing grant/revoke endpoints at `POST /api/admin/roles/grant|revoke` (verified)
- `backend/src/lib/adminService.ts` — `logAdminAction` pattern (verified)
- `backend/src/middleware/requireAdmin.ts` — current flat admin check (verified)
- `backend/src/routes/compassAdmin.ts` — existing admin compass writes as template for contributor routes (verified)
- `backend/src/routes/essentialsPoliticians.ts` — essentials read surface (verified)
- `supabase/migrations/20260323000051_phase41_trivia_service_role.sql` — confirms CTC owns trivia schema via its own Postgres role (verified)
- `supabase/migrations/20260328200000_phase5_moderation.sql` (Civic Spaces) — confirms moderators table and mod_action RPC are already built (verified)
- `C:/Civic Spaces/CIVIC-SPACES-ONBOARDING.md` — confirmed integration pattern and Auth Hub flow (verified)
- `C:/Civic Spaces/src/components/ModeratorQueue.tsx` — confirmed mod queue UI is already built (verified)
