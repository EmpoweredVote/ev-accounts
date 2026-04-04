# Phase 56: Essentials Data Editor Endpoint - Context

**Gathered:** 2026-04-03
**Status:** Ready for planning

<domain>
## Phase Boundary

A single `PATCH /api/essentials/politicians/:id` endpoint that allows role-holding `essentials_data_editor` users to update bio fields (bio, office_title, photo_origin_url, preferred_name) for politicians in their assigned jurisdiction. Structural fields (district assignments, active status) cannot be modified through this endpoint. Read operations and UI belong to Phase 58.

</domain>

<decisions>
## Implementation Decisions

### Mixed-field request handling
- If a request body contains ANY restricted field (`district_type`, `district_id`, `is_active`, `is_candidate`, `is_vacant`), return 422 — even if the body also contains valid allowed fields
- Silently stripping restricted fields is not acceptable; the whitelist is a security boundary, not a convenience filter
- The 422 response must list which specific fields triggered the rejection (so clients know what to remove)

### Jurisdiction matching
- Exact string equality on `jurisdiction_geoid` — no hierarchy (state geoid does not grant access to county politicians)
- NULL `jurisdiction_geoid` on the grant = global access (can edit politicians in any jurisdiction)
- If a user holds multiple `essentials_data_editor` grants, access is granted if ANY matching grant's jurisdiction covers the target politician

### Response shape
- Successful PATCH returns the updated politician object (scoped to essentials-relevant fields — not the full schema including district assignments)
- No follow-up GET required from the UI; the response is sufficient to update client state in place

### Audit log contents
- Each successful write appends to `role_audit_log` with: changed field keys, old values, new values, and `role_grant_id` (which grant authorized the change)
- No-op writes (request body matches current DB values, nothing changes) return 200 with the current record but do NOT write an audit log entry
- All four writable fields are loggable — none are sensitive; old/new values preserved for rollback/accountability

### Claude's Discretion
- Exact structure of the 422 error body (beyond listing offending fields)
- How to determine "nothing changed" — compare before write or inspect affected rows
- Which essentials-relevant fields to include in the success response object

</decisions>

<specifics>
## Specific Ideas

- Phase 57 uses the same NULL-scope = unrestricted pattern for `volunteer` grants; this endpoint should follow the same convention for consistency
- Phase 54's audit log already records `role_grant_id`; this endpoint should match that pattern

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 56-essentials-data-editor-endpoint*
*Context gathered: 2026-04-03*
