# Requirements: Empowered Accounts v1.9

**Defined:** 2026-04-02
**Core Value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.

## v1.9 Requirements — Delegated Authority Roles

Admins assign geo-scoped and resource-scoped roles to Connected/Empowered accounts, granting limited contributor capabilities with full audit trails. A contributor portal serves as the role-holder workspace.

### Infrastructure

- [ ] **ROLE-01**: Schema migration — add `feature_scope` (TEXT NOT NULL), `jurisdiction_geoid` (TEXT nullable), `resource_id` (TEXT nullable) to `public.user_roles`; drop and replace `idx_user_roles_active_unique` with all-columns-inclusive index; create `grant_role`, `revoke_role`, `get_user_roles` SECURITY DEFINER RPCs (missing from all 54 current migrations); seed five role types: `compass_stance_editor`, `campaign_manager`, `ctc_content_editor`, `essentials_data_editor`, `volunteer`
- [ ] **ROLE-02**: `public.role_audit_log` table — columns: `id` (UUID), `actor_id` (UUID FK users), `feature_scope` (TEXT), `jurisdiction_geoid` (TEXT nullable), `resource_id` (TEXT nullable), `action` (TEXT), `target_type` (TEXT), `target_id` (TEXT), `fields_changed` (TEXT[]), `snapshot_after` (JSONB), `created_at` (TIMESTAMPTZ); indexes on `actor_id`, `feature_scope`, `created_at`
- [ ] **ROLE-03**: `requireRole(featureScope, opts?)` Express middleware — `pool.query()` EXISTS check for role presence with NULL-safe jurisdiction check (`IS NULL OR IS NOT DISTINCT FROM`); second-layer `resource_id` boundary check for `campaign_manager` role; 403 on any check failure
- [ ] **ROLE-04**: `GET /api/contributor/me` — returns authenticated user's active role grants (array of `{ feature_scope, jurisdiction_geoid, resource_id }`); used by contributor portal on load and by CTC/Civic Spaces for self-provisioning
- [ ] **ROLE-05**: `POST /api/roles/check` — body `{ feature_scope, jurisdiction_geoid?, resource_id? }`; returns `{ permitted: boolean }`; CORS-enabled for `*.empowered.vote` and Civic Spaces origin; used by Civic Spaces to verify volunteer gate
- [ ] **ROLE-06**: Admin grant/revoke UI — role assignment form in existing admin tool: feature scope dropdown, jurisdiction text field, resource_id politician picker (required for `campaign_manager`); per-user Roles tab showing all active grants with individual revoke buttons and grant timestamps
- [ ] **ROLE-07**: Global audit dashboard — admin page listing all role-holder audit log entries; filterable by `feature_scope`, `jurisdiction_geoid`, date range; each entry links to actor's account detail page

### Role-Gated Endpoints

- [ ] **ROLE-08**: `PUT /api/compass/stances/:politicianId` — requires `compass_stance_editor` role with `jurisdiction_geoid` matching politician's jurisdiction; accepts `{ topic_id, value, reasoning? }`; appends write to `role_audit_log` with `fields_changed` key list
- [ ] **ROLE-09**: Campaign Manager stance writes — same route surface as ROLE-08 but gated by `campaign_manager` role + `resource_id === politicianId`; `GET /api/compass/politicians` for Campaign Manager returns only their assigned politician (single-element array); no route permits reading opponent politician data
- [ ] **ROLE-10**: `PATCH /api/essentials/politicians/:id` — requires `essentials_data_editor` role with matching `jurisdiction_geoid`; restricted field whitelist: `bio`, `office_title`, `photo_origin_url`, `preferred_name`; all writes appended to `role_audit_log`
- [ ] **ROLE-11**: CTC Content Editor integration — `GET /api/contributor/me` exposes `ctc_content_editor` grant with `jurisdiction_geoid`; CTC reads this and enforces content-edit gate in its own system; accounts provides no additional CTC-specific API endpoints
- [ ] **ROLE-12**: Volunteer / Civic Spaces integration — `POST /api/roles/check` serves as the gate endpoint Civic Spaces calls to verify volunteer access; accounts does not write directly to `civic_spaces.moderators` (Civic Spaces provisions itself from the check response)

### Contributor Portal

- [ ] **ROLE-13**: Contributor portal app — new `contributor/` Vite + React app in this repo; calls `GET /api/auth/session` on load to exchange `ev_session` cookie for tokens; routes to role-type-specific views based on grants from `GET /api/contributor/me`; deployed to `contributors.empowered.vote`; `contributors.empowered.vote` added to `CORS_ORIGIN` on Render
- [ ] **ROLE-14**: Compass Stance Editor view — list of politicians in assigned jurisdiction with current stances; inline stance editor per topic; submits via ROLE-08; success appended to in-page activity log
- [ ] **ROLE-15**: Campaign Manager view — single assigned politician displayed (no list); stance editor for all topics; structurally no path to opponent politician data; reads from `GET /api/contributor/me` to determine `resource_id`
- [ ] **ROLE-16**: Essentials Data Editor view — politician cards in assigned jurisdiction; bio/office field editor with field-level dirty state; submits via ROLE-10; confirmation toast on save

### Essentials Provisioning

- [x] **ESSENTIALS-01**: `ESSENTIALS_SERVICE_KEY` env var set in Render for ev-accounts; `.env.example` updated with the key name; `ESSENTIALS-INTEGRATION.md` corrected on env var name (no code changes)

## Future Requirements (v2.0)

### Verification & Analytics
- **VR-F01**: VR admin dashboard — visualize Verification Rating distribution, holds, outliers
- **COMP-05**: User-to-user compass compare API

### Role Extensions
- Bulk audit log export (CSV) from global audit dashboard
- Audit log value-level diffs (before/after field values, not just key list)
- Wildcard geo-scope ("all counties in state")
- Role permission caching in Redis
- UI for creating new feature scope types without code changes

## Out of Scope

| Feature | Reason |
|---------|--------|
| Campaign Manager conflict blocking | Consultant model permitted — one person can hold multiple Campaign Manager grants |
| Roles baked into JWT claims | Revocations must propagate within cache TTL, not JWT expiry — fetched from API |
| Accounts writing to `civic_spaces.moderators` | Civic Spaces provisions itself via `POST /api/roles/check` |
| New CTC API endpoints in accounts | CTC enforces content-edit gate in its own system using `GET /api/contributor/me` |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ESSENTIALS-01 | Phase 51 | Complete |
| ROLE-01 | Phase 52 | Pending |
| ROLE-02 | Phase 52 | Pending |
| ROLE-03 | Phase 53 | Pending |
| ROLE-04 | Phase 53 | Pending |
| ROLE-05 | Phase 53 | Pending |
| ROLE-06 | Phase 54 | Pending |
| ROLE-07 | Phase 54 | Pending |
| ROLE-08 | Phase 55 | Pending |
| ROLE-09 | Phase 55 | Pending |
| ROLE-10 | Phase 56 | Pending |
| ROLE-11 | Phase 57 | Pending |
| ROLE-12 | Phase 57 | Pending |
| ROLE-13 | Phase 58 | Pending |
| ROLE-14 | Phase 58 | Pending |
| ROLE-15 | Phase 58 | Pending |
| ROLE-16 | Phase 58 | Pending |

**Coverage:**
- v1.9 requirements: 17 total
- Mapped to phases: 17
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-02*
*Last updated: 2026-04-02 after initial definition*
