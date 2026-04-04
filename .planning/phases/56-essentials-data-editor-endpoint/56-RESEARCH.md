# Phase 56: Essentials Data Editor Endpoint - Research

**Researched:** 2026-04-03
**Domain:** Express 4.x role-gated PATCH endpoint, pg pool writes to essentials schema, audit log
**Confidence:** HIGH

## Summary

Phase 56 adds one new endpoint: `PATCH /api/essentials/politicians/:id` for `essentials_data_editor`
role holders. All required infrastructure is already in place from Phases 52–55: `requireRole`
middleware, `getCachedUserRoles`, `writeStanceAuditLog` (extended for this action), `pool.query()`
for non-public schema writes. The endpoint is simpler than Phase 55's stance editor — single
role, no `resource_id` scoping, no bulk path.

Three field-name discrepancies between CONTEXT.md and the live DB schema require attention from the
planner. The CONTEXT.md lists writable field `bio` but the column is `bio_text`. The CONTEXT.md
lists `office_title` as writable, but that value comes from `essentials.offices.title`, not
`essentials.politicians`. And `photo_origin_url` on reads is a `COALESCE(photo_custom_url,
photo_origin_url, '')` — writes should target `photo_custom_url` to set an override, or
`photo_origin_url` for the canonical value.

The jurisdiction matching pattern for `essentials_data_editor` does not exist yet in `stanceService.ts`
— that file only handles `compass_stance_editor` and `campaign_manager`. A new matching function
(or inline logic) is needed for this role's grant-to-politician jurisdiction check.

**Primary recommendation:** One plan — route + service function + audit log + tests. No migration
required (all schema from Phase 55 is already in place). Clarify field name discrepancies before
writing code.

## Standard Stack

No new libraries. All tools are already in the project.

### Core (already in place)
| Tool | Version | Purpose | Notes |
|------|---------|---------|-------|
| `express` | 4.x | HTTP routing | New route in new file or added to essentialsPoliticians.ts |
| `pg` (pool) | existing | Non-public schema writes | `pool.query()` — essentials schema not PostgREST-exposed |
| `zod` | existing | Request body validation and restricted field detection | All schemas use zod |
| `requireRole` | Phase 53 | Role-gated middleware | `requireRole('essentials_data_editor')` |
| `getCachedUserRoles` | Phase 52/53 | Fetch user's grants + jurisdiction | Returns `jurisdiction_geoid`, `id` |
| `writeStanceAuditLog` | Phase 55 | Audit log write helper | In `stanceService.ts`, takes `PoolClient` |
| `pool` | Phase 35+ | Direct postgres | `lib/db.ts` |

**No new npm installs required.**

## Architecture Patterns

### Recommended File Structure

```
backend/src/
├── routes/
│   └── essentialsEditor.ts    # NEW — PATCH /politicians/:id for essentials_data_editor
├── lib/
│   └── stanceService.ts       # MODIFIED — add getEditorMatchingGrant() for essentials_data_editor
backend/
└── (no migration needed)      # All schema from Phase 55 is already in place
```

Mount in `index.ts` BEFORE `essentialsPoliticiansRouter`:
```typescript
import essentialsEditorRouter from './routes/essentialsEditor.js';
// ...
app.use('/api/essentials/politicians', essentialsEditorRouter);   // BEFORE
app.use('/api/essentials/politicians', essentialsPoliticiansRouter);
```

This follows the dual-router pattern already established for `compassContributorRouter` /
`compassRouter` — same URL prefix, no method collision (PATCH vs GET).

### Pattern 1: Restricted field detection (hard reject before writes)

The CONTEXT.md decision is a security boundary: if ANY restricted field is present in the
request body, 422 immediately — do not process allowed fields.

```typescript
// Source: CONTEXT.md decision — restricted field whitelist enforcement
const ALLOWED_FIELDS = ['bio', 'office_title', 'photo_origin_url', 'preferred_name'] as const;
const RESTRICTED_FIELDS = ['district_type', 'district_id', 'is_active', 'is_candidate', 'is_vacant'];

// Check for restricted fields FIRST, before zod validation of allowed fields
const bodyKeys = Object.keys(req.body);
const offendingFields = bodyKeys.filter(k => RESTRICTED_FIELDS.includes(k));
if (offendingFields.length > 0) {
  res.status(422).json({
    code: 'RESTRICTED_FIELDS',
    message: 'Request contains fields that cannot be modified through this endpoint',
    fields: offendingFields,
  });
  return;
}
```

**Important:** This check runs before zod parsing. An empty body (no allowed fields AND no
restricted fields) passes the restriction check but zod can reject it as requiring at least
one field.

### Pattern 2: Jurisdiction enforcement for essentials_data_editor

The `getMatchingGrant()` function in `stanceService.ts` only handles `compass_stance_editor`
and `campaign_manager`. Phase 56 needs its own jurisdiction-matching logic for
`essentials_data_editor`.

```typescript
// New function in stanceService.ts (or inline in handler — service is cleaner)
// Source: adapted from getMatchingGrant() in stanceService.ts

export function getEditorMatchingGrant(
  grants: UserRoleGrant[],
  politicianGeoid: string | null
): UserRoleGrant | null {
  for (const grant of grants) {
    if (grant.slug !== 'essentials_data_editor') continue;

    // NULL jurisdiction on grant = global access (any politician)
    if (grant.jurisdiction_geoid === null) return grant;

    // Politician has no home jurisdiction assigned
    // Phase 56 CONTEXT.md does not specify fail-open for NULL politician geoid.
    // Treat as no match (fail-closed) — matches Phase 57 volunteer pattern.
    if (politicianGeoid === null) continue;

    // Exact string equality
    if (grant.jurisdiction_geoid === politicianGeoid) return grant;
  }
  return null;
}
```

**NOTE:** Phase 55's `getMatchingGrant()` fails open when the politician has no geoid
(`console.warn` + returns grant). CONTEXT.md for Phase 56 does NOT mention fail-open for
null politician geoid — it only mentions NULL on the grant = global. Planner should clarify
this before coding; the recommendation is fail-closed for null politician geoid.

### Pattern 3: No-op detection (compare before write)

CONTEXT.md says no-op writes return 200 with current record but NO audit log. Two approaches:
1. Fetch current values before UPDATE, compare in-app, skip write if nothing changed
2. Run the UPDATE, check `rowCount` or `xmax` for actual mutation

Recommendation: fetch-before-write (compare in-app). This avoids relying on Postgres
row versioning internals and makes the no-op detection explicit and testable.

```typescript
// Fetch current values
const { rows: current } = await pool.query(
  `SELECT bio_text, preferred_name, photo_origin_url FROM essentials.politicians WHERE id = $1`,
  [politicianId]
);
const cur = current[0];

// Compute what actually changed
const changed: Record<string, { old: unknown; new: unknown }> = {};
if (body.bio !== undefined && body.bio !== cur.bio_text) {
  changed['bio'] = { old: cur.bio_text, new: body.bio };
}
// ... etc for each field

if (Object.keys(changed).length === 0) {
  // No-op: return current record, no audit log
  return res.status(200).json(buildResponse(cur));
}
```

### Pattern 4: Single-statement PATCH write (pool.query, no explicit transaction)

Unlike Phase 55 bulk stances, this is a single UPDATE. A single Postgres statement is
implicitly atomic — no `BEGIN/COMMIT` needed.

However: the audit log is a second write. To ensure the UPDATE and audit log are atomic,
use a transaction.

```typescript
const client = await pool.connect();
try {
  await client.query('BEGIN');

  await client.query(
    `UPDATE essentials.politicians
     SET bio_text = $1, preferred_name = $2, photo_origin_url = $3
     WHERE id = $4`,
    [newBio, newPreferredName, newPhotoUrl, politicianId]
  );

  await writeStanceAuditLog(client, { ... });

  await client.query('COMMIT');
} catch (err) {
  await client.query('ROLLBACK');
  throw err;
} finally {
  client.release();
}
```

Pattern is identical to Phase 55's single-stance write in `compassContributor.ts`.

### Pattern 5: Success response shape

CONTEXT.md: return updated politician scoped to essentials-relevant fields (not full schema
including district assignments). This means returning only the writable fields plus
enough identity context for the UI to identify the record.

Suggested shape (Claude's discretion per CONTEXT.md):
```typescript
{
  id: string;
  full_name: string;
  preferred_name: string | null;
  bio_text: string | null;         // NOTE: column name, not "bio"
  photo_origin_url: string | null;
  // office_title NOT included — from essentials.offices, not this table
}
```

Do NOT include `district_type`, `district_id`, `is_active`, `is_candidate`, `is_vacant`.

### Pattern 6: Audit log write for bio_edit action

Reuse `writeStanceAuditLog()` from `stanceService.ts` — it writes to `role_audit_log` with
`fields_changed: text[]` and `snapshot_after: jsonb`. For this endpoint the `target_type`
should be `'politician'` (not `'politician_answer'`).

```typescript
// Source: stanceService.writeStanceAuditLog signature
await writeStanceAuditLog(client, {
  actorId: userId,
  targetUserId: userId,           // actor is the editor, no separate target user
  roleGrantId: matchingGrant.id,
  featureScope: matchingGrant.feature_scope,
  jurisdictionGeoid: matchingGrant.jurisdiction_geoid,
  resourceId: matchingGrant.resource_id,
  topicId: politicianId,          // repurposed: target entity identifier
  oldValue: ...,
  newValue: ...,
  writeInTextChanged: false,
});
```

**Alternatively:** create a new `writeBioAuditLog()` function that takes a `fieldsChanged`
map (since there are up to 4 fields changed, not just `value`/`write_in_text`). This is
cleaner but requires a new function. Recommendation: new `writeEssentialsAuditLog()` with
a `changes: Record<string, { old: unknown; new: unknown }>` parameter for structured diffs.
`writeStanceAuditLog` is designed for stance-specific fields and would require awkward
field mapping.

### Pattern 7: Route mounting order (avoids path capture)

`essentialsPoliticiansRouter` already handles `GET /api/essentials/politicians/:id` and
multiple sub-paths. The new `essentialsEditorRouter` handles `PATCH /api/essentials/politicians/:id`.

Mount order in `index.ts`:
```typescript
app.use('/api/essentials/politicians', essentialsEditorRouter);     // PATCH routes
app.use('/api/essentials/politicians', essentialsPoliticiansRouter); // GET routes
```

No collision — different HTTP methods on the same path. Express routes by method + path.

### Anti-Patterns to Avoid

- **Writing to essentials schema via supabaseAdmin/supabaseAnon:** `essentials` is NOT in
  the PostgREST exposed schema list. All reads AND writes must use `pool.query()`. Confirmed
  in MEMORY.md: "essentials schema is NOT in the PostgREST exposed schema list."
- **Silently stripping restricted fields:** CONTEXT.md explicitly forbids this — the whitelist
  is a security boundary. Any restricted field = 422 with the offending field list.
- **Using `getMatchingGrant()` from stanceService for essentials_data_editor:** That function
  only handles `compass_stance_editor` and `campaign_manager` slugs. It will return `null`
  for any `essentials_data_editor` grant — wrong behavior, not an error.
- **Writing `office_title` directly to essentials.politicians:** `office_title` comes from
  `essentials.offices.title` in all queries, not from a column on `essentials.politicians`.
  Writing it to `essentials.politicians` would have no effect on read responses.
- **Using the `bio` field name in SQL:** The DB column is `bio_text`, not `bio`. SQL with
  `bio` will fail with "column does not exist."

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Role presence check | Custom JWT inspection | `requireRole('essentials_data_editor')` | Already handles caching, 401/403 |
| Grant jurisdiction lookup | Re-query the DB | `getCachedUserRoles(userId)` returns grants with `jurisdiction_geoid` | Redis-cached with 90s TTL |
| Audit log write | Custom INSERT | New `writeEssentialsAuditLog()` modeled on `writeStanceAuditLog` | Consistent audit shape, pool client passed in |
| Politician existence check | Trust caller | `SELECT id FROM essentials.politicians WHERE id = $1` | Prevents 404 vs 403 confusion |

## Common Pitfalls

### Pitfall 1: `bio` vs `bio_text` field name mismatch

**What goes wrong:** SQL `UPDATE essentials.politicians SET bio = $1` fails with "column `bio`
does not exist".

**Why it happens:** The DB column is `bio_text`. CONTEXT.md discusses the API-level field as
`bio` (user-visible name) but the actual column differs. All existing queries in
`essentialsService.ts` use `bio_text`.

**How to avoid:** In the UPDATE query use `bio_text`. In the API body schema (zod) use `bio`
as the field name and map it to `bio_text` when building the SQL. Document the mapping
explicitly in the route comment.

**Warning signs:** Runtime DB error "column does not exist."

### Pitfall 2: `office_title` cannot be updated via essentials.politicians

**What goes wrong:** Writing `office_title` to `essentials.politicians` has no effect on
`GET /api/essentials/politicians/:id` responses, which source `office_title` from
`o.title` in `essentials.offices`.

**Why it happens:** `essentials.politicians` does not have an `office_title` column. The
column exists on `essentials.offices` as `title`. All read queries JOIN to that table:
`LEFT JOIN essentials.offices o ON o.politician_id = p.id` → `o.title AS office_title`.

**How to avoid:** If `office_title` is truly writable in Phase 56, the UPDATE must go to
`essentials.offices` table. However, a politician can have multiple office records (multiple
terms). This adds complexity. **Planner should confirm with user whether `office_title` is
meant to update `essentials.offices` or if Phase 56 should restrict writable fields to
`bio_text`, `preferred_name`, `photo_origin_url` only.**

**Warning signs:** UPDATE runs successfully but `office_title` in GET response is unchanged.

### Pitfall 3: photo_origin_url vs photo_custom_url

**What goes wrong:** Writing to `photo_origin_url` may be shadowed by `photo_custom_url` in
read responses. All read queries use `COALESCE(p.photo_custom_url, p.photo_origin_url, '')`
— if `photo_custom_url` is already set, changing `photo_origin_url` has no visible effect.

**Why it happens:** The codebase supports two photo columns: `photo_origin_url` (imported
from external sources) and `photo_custom_url` (manual override). COALESCE prefers
`photo_custom_url`.

**How to avoid:** When the API receives `photo_origin_url` to update, write to
`photo_custom_url` — this is the "user override" column and will take precedence in reads.
Alternatively, write to both columns (keep them in sync). Document the intent.

**Warning signs:** PATCH returns the new photo URL in the response, but subsequent GETs
return the old photo if `photo_custom_url` had a prior value.

### Pitfall 4: getMatchingGrant fails silently for essentials_data_editor

**What goes wrong:** Calling `getMatchingGrant(grants, politicianId, geoid)` from
`stanceService.ts` always returns `null` for an `essentials_data_editor` grant — the
function only iterates slugs `'compass_stance_editor'` and `'campaign_manager'`. The
handler returns 403 to all `essentials_data_editor` users.

**Why it happens:** `getMatchingGrant()` was written for Phase 55 roles only.

**How to avoid:** Use the new `getEditorMatchingGrant()` function (or equivalent inline
logic) that checks for `essentials_data_editor` slug and applies jurisdiction matching.

**Warning signs:** All PATCH requests return 403 even from users with valid grants.

### Pitfall 5: Route mounting order — PATCH path captured by GET /:id handler

**What goes wrong:** If `essentialsEditorRouter` is mounted AFTER
`essentialsPoliticiansRouter`, Express will try the GET /:id route first. Since Express
does match by method, this is actually safe — PATCH would not match GET. However, if the
two routers share a mount and the GET handler for /:id does not `next()` on method
mismatch, a 404 could result.

**How to avoid:** Mount `essentialsEditorRouter` before `essentialsPoliticiansRouter` to be
explicit about precedence. This follows the established pattern from Phase 55
(`compassContributorRouter` before `compassRouter`). Verified in `index.ts` lines 79–84.

**Warning signs:** PATCH requests to `/api/essentials/politicians/:id` return 404.

### Pitfall 6: No audit log written for no-op writes (per decision)

**What goes wrong:** Audit log is written even when nothing changed — the audit log contains
spurious entries with empty `fields_changed`.

**Why it happens:** The no-op check is skipped or the comparison logic is wrong.

**How to avoid:** After fetching current values, compute the diff before entering the
transaction. If `Object.keys(changed).length === 0`, return 200 immediately with the current
record — do not open a transaction, do not call the write functions.

**Warning signs:** `role_audit_log` contains entries with `fields_changed = '{}'` or
`snapshot_after = {}`.

## Code Examples

### Request body validation (zod schema with restricted field check)

```typescript
// Source: CONTEXT.md + codebase convention

const RESTRICTED_FIELDS = ['district_type', 'district_id', 'is_active', 'is_candidate', 'is_vacant'];

// Allowed field schema — at least one field required
const patchPoliticianSchema = z.object({
  bio: z.string().max(10000).optional(),
  office_title: z.string().max(500).optional(),
  photo_origin_url: z.string().url().max(2048).optional().or(z.literal('')),
  preferred_name: z.string().max(200).optional(),
}).refine(
  (data) => Object.values(data).some((v) => v !== undefined),
  { message: 'At least one field must be provided' }
);
```

### Route handler skeleton

```typescript
// Source: pattern from compassContributor.ts

router.patch(
  '/:id',
  requireAuth,
  requireRole('essentials_data_editor'),
  async (req: Request, res: Response): Promise<void> => {
    const politicianId = req.params['id'] as string;
    const actorId = (req as AuthenticatedRequest).userId;

    // 1. Validate UUID
    if (!UUID_RE.test(politicianId)) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'Invalid politician ID format' });
      return;
    }

    // 2. Check for restricted fields FIRST
    const bodyKeys = Object.keys(req.body ?? {});
    const offendingFields = bodyKeys.filter(k => RESTRICTED_FIELDS.includes(k));
    if (offendingFields.length > 0) {
      res.status(422).json({
        code: 'RESTRICTED_FIELDS',
        message: 'Request contains fields that cannot be modified through this endpoint',
        fields: offendingFields,
      });
      return;
    }

    // 3. Parse allowed fields
    const parsed = patchPoliticianSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: parsed.error.issues.map(i => i.message).join('; ') });
      return;
    }

    // 4. Get grants
    const grants = await getCachedUserRoles(actorId);

    // 5. Check politician exists + get jurisdiction
    const existsResult = await pool.query<{ id: string; home_jurisdiction_geoid: string | null }>(
      `SELECT id, home_jurisdiction_geoid FROM essentials.politicians WHERE id = $1 LIMIT 1`,
      [politicianId]
    );
    if (existsResult.rows.length === 0) {
      res.status(404).json({ code: 'NOT_FOUND', message: 'Politician not found' });
      return;
    }
    const politicianGeoid = existsResult.rows[0].home_jurisdiction_geoid;

    // 6. Find matching grant
    const matchingGrant = getEditorMatchingGrant(grants, politicianGeoid);
    if (!matchingGrant) {
      res.status(403).json({ code: 'FORBIDDEN', message: 'Your jurisdiction does not cover this politician' });
      return;
    }

    // 7. Fetch current values for no-op check and audit diff
    // ... fetch, compare, build changed map ...

    // 8. If no-op, return current record
    if (Object.keys(changed).length === 0) {
      return res.status(200).json(buildResponse(current));
    }

    // 9. Transaction: UPDATE + audit log
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      // UPDATE essentials.politicians SET bio_text = ..., preferred_name = ..., ...
      // writeEssentialsAuditLog(client, { ... })
      await client.query('COMMIT');
      res.status(200).json(buildResponse(updated));
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }
);
```

### getEditorMatchingGrant (new function in stanceService.ts)

```typescript
// Source: adapted from getMatchingGrant in stanceService.ts

export function getEditorMatchingGrant(
  grants: UserRoleGrant[],
  politicianGeoid: string | null
): UserRoleGrant | null {
  for (const grant of grants) {
    if (grant.slug !== 'essentials_data_editor') continue;

    // NULL jurisdiction on grant = global access
    if (grant.jurisdiction_geoid === null) return grant;

    // Politician has no assigned jurisdiction — no match (fail-closed)
    if (politicianGeoid === null) continue;

    // Exact string equality
    if (grant.jurisdiction_geoid === politicianGeoid) return grant;
  }
  return null;
}
```

### Essentials audit log write (new function)

```typescript
// New function in stanceService.ts or a new essentialsEditorService.ts

export async function writeEssentialsAuditLog(
  client: PoolClient,
  actorId: string,
  matchingGrant: UserRoleGrant,
  politicianId: string,
  changed: Record<string, { old: unknown; new: unknown }>
): Promise<void> {
  const fieldsChanged = Object.keys(changed);
  const snapshotAfter = { politician_id: politicianId, changes: changed };

  await client.query(
    `INSERT INTO public.role_audit_log
       (actor_id, target_user_id, feature_scope, jurisdiction_geoid, resource_id,
        action, target_type, target_id, fields_changed, snapshot_after, role_grant_id)
     VALUES ($1, $2, $3, $4, $5, 'bio_edit', 'politician', $6, $7, $8, $9)`,
    [
      actorId,
      actorId,
      matchingGrant.feature_scope,
      matchingGrant.jurisdiction_geoid,
      matchingGrant.resource_id,
      politicianId,
      fieldsChanged,
      JSON.stringify(snapshotAfter),
      matchingGrant.id,
    ]
  );
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| No write path for essentials.politicians | PATCH endpoint for bio fields | Phase 56 | essentials_data_editor role becomes functional |
| getMatchingGrant handles compass roles only | getEditorMatchingGrant for essentials_data_editor | Phase 56 | Clean role-specific matching |
| No `bio_edit` action type in role_audit_log | Extended with `bio_edit` | Phase 56 | Searchable audit trail for essentials edits |

**Current schema state after Phase 55:**
- `essentials.politicians.home_jurisdiction_geoid` — exists (added in migration 049)
- `inform.politician_answers.write_in_text` — exists (added in migration 049)
- `public.role_audit_log.role_grant_id` — exists (added in migration 049)
- `public.user_roles.id` — exists (pre-existing)
- `get_user_roles` RPC returns `id` — yes (updated in migration 049)

**No migration needed for Phase 56.** All required schema is already in place.

## Open Questions

1. **Is `office_title` truly writable, and if so, to which table?**
   - What we know: `office_title` in GET responses comes from `essentials.offices.title`,
     not from a column on `essentials.politicians`. There is no `office_title` column on
     `essentials.politicians`.
   - What's unclear: Phase boundary says `office_title` is a writable bio field, but the
     data architecture separates identity (politicians table) from office context (offices
     table). Writing to `offices.title` has different implications — a politician can have
     multiple active office records.
   - Recommendation: Either (a) write to `essentials.offices` for the most recent/active
     office record, or (b) remove `office_title` from the writable fields for Phase 56
     and defer it. Confirm with user before coding.

2. **Should NULL `home_jurisdiction_geoid` on the politician be fail-open or fail-closed?**
   - What we know: Phase 55's `getMatchingGrant` fails open (logs warning, allows write).
     CONTEXT.md for Phase 56 does not mention fail-open behavior.
   - What's unclear: Is fail-open intentional for Phase 56 as well?
   - Recommendation: Fail-closed (return `null` from `getEditorMatchingGrant` when
     `politicianGeoid === null`). This is the safer default for a bio edit endpoint.
     Confirm with user if fail-open is intended.

3. **Which fields to include in the success response?**
   - What we know: CONTEXT.md delegates this to Claude's discretion. Response must exclude
     district assignments and active status.
   - Recommendation: Include `id`, `full_name`, `preferred_name`, `bio_text`,
     `photo_origin_url` (post-COALESCE value). Exclude `office_title` if it's not writable
     to avoid confusion.

4. **Should `bio` in the API map to `bio_text` or is there a separate `bio` column?**
   - What we know: All existing queries in `essentialsService.ts` use `bio_text`. No
     `bio` column exists in any migration.
   - Recommendation: The API body field is named `bio` (user-facing), the DB column is
     `bio_text`. Map explicitly: `body.bio → bio_text column`. No migration needed.

## Sources

### Primary (HIGH confidence)
- Direct codebase inspection:
  - `backend/src/lib/stanceService.ts` — `getMatchingGrant`, `writeStanceAuditLog`, `StanceAuditParams` interface confirmed
  - `backend/src/lib/roleService.ts` — `UserRoleGrant` interface includes `id: string` confirmed
  - `backend/src/middleware/requireRole.ts` — single-slug usage confirmed
  - `backend/src/lib/essentialsService.ts` — `bio_text` column name, `office_title` from `o.title`, `photo_custom_url` COALESCE confirmed
  - `backend/src/routes/essentialsPoliticians.ts` — existing GET route structure, UUID_REGEX pattern
  - `backend/src/routes/compassContributor.ts` — full PATCH pattern to follow for transaction + audit log
  - `backend/src/index.ts` — router mounting order, dual-router pattern confirmed
  - `backend/migrations/049_compass_contributor_schema.sql` — schema additions confirmed, no migration needed for Phase 56
  - `backend/migrations/033_politician_schema.sql` — `district_type`, `district_id`, `is_active`, `is_candidate`, `is_vacant` column names confirmed on `essentials.politicians`
  - `backend/src/lib/adminService.ts` lines 304–327 — `writeRoleAuditLog` signature, audit log INSERT pattern

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries confirmed via direct code inspection, no new installs
- Architecture: HIGH — patterns verified against actual codebase; dual-router and transaction patterns confirmed
- Pitfalls: HIGH — field name discrepancies confirmed by direct inspection of `essentialsService.ts`
- Schema state: HIGH — migration 049 confirmed in place, no additional migration needed
- Open questions: MEDIUM — `office_title` table source requires product decision; fail-open for null geoid requires clarification

**Research date:** 2026-04-03
**Valid until:** 2026-05-03 (stable codebase, no fast-moving dependencies)
