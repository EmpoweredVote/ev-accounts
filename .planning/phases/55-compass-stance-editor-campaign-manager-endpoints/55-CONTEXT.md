# Phase 55: Compass Stance Editor + Campaign Manager Endpoints - Context

**Gathered:** 2026-04-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Role-holding contributors can write politician stances through the API with jurisdiction and resource boundaries enforced at every layer. A `compass_stance_editor` cannot modify politicians outside their assigned jurisdiction; a `campaign_manager` cannot read or write any politician other than their assigned one. This phase is API-only — no UI, no Contributor Portal (that is Phase 58).

</domain>

<decisions>
## Implementation Decisions

### Stance write shape
- Two separate routes, not one polymorphic endpoint:
  - `PUT /api/compass/stances/:politicianId/:topicId` — single topic write
  - `PUT /api/compass/stances/:politicianId/bulk` — write all topics at once
- Bulk write body: `{ stances: [{ topic_id, value, write_in_text? }] }`
- Single write body: `{ value, write_in_text? }` (topic_id in URL)
- Bulk writes are all-or-nothing — a single invalid stance rolls back the entire transaction
- Bulk writes produce one `role_audit_log` row **per topic changed** (not one row for the whole batch) — consistent with single-topic writes and queryable per-topic

### Jurisdiction resolution
- Add `home_jurisdiction_geoid` column to `inform.politicians` as part of this phase
- Enforcement: exact string equality between contributor's `jurisdiction_geoid` (from role grant) and politician's `home_jurisdiction_geoid`
- **NULL jurisdiction behavior (Phase 55 Alpha):** fail-open — write proceeds, a `console.warn` is logged. Add a TODO comment marking the migration point to fail-closed once Alpha cities are seeded
- Hierarchical (FIPS prefix) matching noted as a future enhancement — deferred until geo_id consistency across FEC/CAL Access data sources is confirmed

### Audit log content
- `fields_changed` for stance write entries: `{ topic_id, old_value, new_value, write_in_text_changed: boolean }`
- No full text content stored in the audit log
- Actor identified by `user_id` (UUID only — display name resolved at render time by admin UI; `legal_name` never stored)
- Include `role_grant_id` — links the write to the specific grant that authorized it (useful for tracing after revocation)
- Add/use an `action` column in `role_audit_log` with value `'stance_write'` to distinguish from `'grant'` and `'revoke'` entries in the Phase 54 audit dashboard

### Politicians list filtering (contributor-scoped endpoint)
- New endpoint: `GET /api/compass/contributors/politicians` — does NOT modify the existing `GET /compass/politicians` (Compass compare stays untouched)
- `compass_stance_editor`: returns politicians where `home_jurisdiction_geoid` exactly matches the contributor's grant jurisdiction
- `campaign_manager`: returns exactly one politician matching their `resource_id` grant
- If assigned politician doesn't exist or is deactivated: return `200` with `[]` (empty array) — avoids leaking whether resource_id is valid
- Endpoint returns politician records only — current stances fetched separately via existing `GET /compass/politicians/:id/answers`

### Claude's Discretion
- Exact schema for `role_audit_log` `action` column (add or reuse existing)
- Middleware composition order for `requireRole` + jurisdiction enforcement
- Error messages for cross-jurisdiction 403 responses
- Transaction implementation for bulk writes (RPC vs. pg pool transaction)

</decisions>

<specifics>
## Specific Ideas

- Politician data consolidation (one canonical shared politicians table across Compass, Essentials, Validation Quests) is a future initiative — not folded into this phase. `inform.politicians` is the working table for now.
- The fail-open NULL jurisdiction behavior is explicitly temporary. The code should include a comment noting the intended migration to fail-closed once Alpha seeding is complete.

</specifics>

<deferred>
## Deferred Ideas

- **Politician database consolidation** — a single canonical `politicians` table shared across Compass, Essentials, and Validation Quests. Currently each feature uses its own table (`inform.politicians`, `essentials.*`). This is a dedicated future phase.
- **Hierarchical jurisdiction matching** — FIPS prefix-based enforcement (county grant covers city politicians). Deferred until geo_id consistency across FEC/CAL Access data sources is confirmed.
- **Fail-closed NULL jurisdiction enforcement** — currently fail-open for Alpha. Migrate to fail-closed (422) once Alpha cities have `home_jurisdiction_geoid` populated.
- **Geo_id data quality tooling** — tools to inspect/flag politicians with missing or inconsistent `home_jurisdiction_geoid` values; would accelerate future location expansion.

</deferred>

---

*Phase: 55-compass-stance-editor-campaign-manager-endpoints*
*Context gathered: 2026-04-03*
