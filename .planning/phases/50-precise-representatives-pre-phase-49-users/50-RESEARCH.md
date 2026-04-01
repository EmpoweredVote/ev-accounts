# Phase 50: Precise Representatives for Pre-Phase-49 Users - Research

**Researched:** 2026-03-30
**Domain:** Express route modification, PostgreSQL RPC, pool.query, one-time backfill script
**Confidence:** HIGH — all findings from direct codebase inspection

## Summary

Phase 50 is a targeted fix to `GET /api/essentials/representatives/me`. The symptom: Connected users who set their location before Phase 49 shipped have `encrypted_lat`/`encrypted_lng` stored but null `congressional_geo_id` (and other geo_id columns). Phase 49-01's backfill attempted to populate these via the `resolve_user_jurisdiction` RPC but returned nulls for most users — the Phase 49-01 SUMMARY confirms only 2 of 8 users got geo IDs populated; 6 returned null due to a CA geofence gap at backfill time. Those 6 users fall to Path 2 (geocode `home_address`) which no longer works because Phase 49-02 removed the `home_address` write from `set-location`.

The fix is mechanically simple: add Path 1.5 in essentials.ts between the current Path 1 (stored geo_id check) and Path 2 (home_address geocode). Path 1.5 detects `encrypted_lat IS NOT NULL` but `congressional_geo_id IS NULL`, calls `resolve_user_jurisdiction` RPC to decrypt and resolve, writes the 12 jurisdiction columns back (so the next request hits Path 1), then serves the full politician set. A separate one-time backfill script covers existing affected users.

**Primary recommendation:** Add Path 1.5 inline in essentials.ts using the existing `adminRpc` call pattern from connect.ts set-location. Run a standalone backfill script that calls `resolve_user_jurisdiction` for all users with `encrypted_lat IS NOT NULL AND congressional_geo_id IS NULL`. No new migrations needed.

---

## Key Findings

### Finding 1: Column names confirmed from shipped migration

Migration `20260326000053_phase49_jurisdiction_columns.sql` uses:
- `congressional_district_name` (not `congressional_name`)
- `state_senate_district_name` (not `state_senate_name`)
- `state_house_district_name` (not `state_house_name`)
- `county_name`
- `school_district_name`

The connect.ts set-location write (lines 576–604) uses exactly these column names. Path 1.5 must use the same names.

### Finding 2: Path 1 trigger condition

Current Path 1 fires when `j.congressional_geo_id || j.state_senate_geo_id` is truthy. Path 1.5 must guard on the inverse: geo_ids are null but encrypted_lat is present.

The current two-query structure in `/representatives/me` (separate `home_address` query, then geo_id query) can be collapsed into a single query for Path 1.5 by SELECTing `encrypted_lat IS NOT NULL AS has_coords` alongside the geo_id columns.

### Finding 3: resolve_user_jurisdiction raises EXCEPTION if no location

From `20260310000032_location_rpcs.sql` line 122–124:
```sql
IF v_encrypted_lat IS NULL THEN
  RAISE EXCEPTION 'no location on file for user %', p_user_id;
END IF;
```

Calling the RPC for a user without `encrypted_lat` throws. Path 1.5 MUST guard on `encrypted_lat IS NOT NULL` before calling the RPC. The RPC also raises if `location_encryption_key` is not in Vault — that's a server configuration error, not a user state error.

### Finding 4: resolve_user_jurisdiction is called via adminRpc in connect.ts

The current pattern in connect.ts set-location (line 562):
```typescript
const { data: jurisdictionData, error: jurisdictionError } = await adminRpc('resolve_user_jurisdiction', {
  p_user_id: userId,
}, 'connect');
```

This uses `adminRpc` (supabase-js service role) not `pool.query`. The RPC is `SECURITY DEFINER` and requires Vault access — it works fine via adminRpc. Path 1.5 should use the same pattern.

However: essentials.ts currently has no `adminRpc` import (it was removed in Phase 49-02 when `resolve_user_jurisdiction` was eliminated from that file). The `adminRpc` import must be restored for Path 1.5.

### Finding 5: adminRpc import was removed from essentials.ts in Phase 49-02

Phase 49-02 SUMMARY explicitly states: "adminRpc import removed from essentials.ts — no longer used after Path 1 conversion to pool.query." The import must be re-added for Path 1.5.

### Finding 6: The jurisdiction column write uses pool.query, not adminRpc

After calling the RPC, the write-back uses `pool.query` (connect.ts line 574). This is correct — `connect.*` schema writes must use `pool.query`, not PostgREST. Path 1.5 write-back follows the same pattern.

### Finding 7: jurisdiction_state and jurisdiction_city cannot be recovered from the RPC

`resolve_user_jurisdiction` returns only 10 keys (5 geo IDs + 5 names). It does not return `state` or `city`. These come from the geocoder at set-location time.

For Path 1.5, `jurisdiction_state` and `jurisdiction_city` cannot be populated from the RPC alone. Options:
1. Leave them null in the write-back (they were null before, no regression)
2. The `X-Formatted-Address` header fallback already handles this: `homeAddress || [j.jurisdiction_city, j.jurisdiction_state].filter(Boolean).join(', ')` — if both are null, header will be empty string

For Phase 50, leaving `jurisdiction_state` and `jurisdiction_city` null is acceptable. Users will get correct politicians (the goal), and the next `set-location` call will populate all 12 columns. The `X-Formatted-Address` header will be empty string for these users, which is a minor UX gap but not a blocker.

### Finding 8: home_address is no longer written at set-location time

Phase 49-02 SUMMARY confirms: "Remove home_address fire-and-forget write from set-location (Phase 49 privacy constraint)." So for pre-Phase-49 users, `home_address` may or may not be populated depending on when they last enrolled. Path 2 geocodes `home_address` — if it's null for a pre-Phase-49 user who has `encrypted_lat`, they get 204 today, which is the wrong behavior. Path 1.5 fixes this.

### Finding 9: One-time backfill approach

The backfill needs to call `resolve_user_jurisdiction` for each affected user and write the 10 geo_id + name columns back. Since `resolve_user_jurisdiction` requires Vault access and is a PostgreSQL function, the backfill is most cleanly done as a TypeScript script (like `backfill-indiana-office-titles.ts`) that iterates affected users and calls the RPC per-user.

**Alternative:** A single SQL UPDATE with subquery (like Phase 49-01 migration). However, Phase 49-01 already attempted this and got nulls for 6 of 8 users. The CA geofence gap that caused those nulls may or may not be resolved now. If the gap is resolved, the same SQL approach works. If not, users still get nulls and the situation is unchanged.

The script approach gives better observability: log how many users were fixed vs. still returning null, so we know whether the geofence gap is resolved.

### Finding 10: No new migrations needed

Phase 50 is purely:
1. A route modification to essentials.ts (add Path 1.5)
2. A one-time backfill script

No schema changes. All 12 columns already exist from Phase 49-01.

---

## Standard Stack

No new libraries. All changes use existing patterns.

### Core (unchanged)
| Tool | Purpose |
|------|---------|
| `pool.query()` | Write 12 jurisdiction columns to `connect.connected_profiles` |
| `adminRpc()` | Call `connect.resolve_user_jurisdiction` RPC (Vault access required) |
| `Pool` (pg) | Backfill script DB connection |
| `tsx` | Run TypeScript backfill script via `npx tsx scripts/...` |

**Installation:** None. No new packages.

---

## Architecture Patterns

### Path 1.5 insertion point

The current route structure has two SELECTs: one for `home_address`, one for geo_ids. For efficiency, Path 1.5 should combine these into a single query that also fetches `encrypted_lat IS NOT NULL`:

```typescript
// Single query replacing the two existing queries
const { rows } = await pool.query<{
  home_address: string | null;
  congressional_geo_id: string | null;
  state_senate_geo_id: string | null;
  state_house_geo_id: string | null;
  county_geo_id: string | null;
  school_district_geo_id: string | null;
  jurisdiction_state: string | null;
  jurisdiction_city: string | null;
  has_coords: boolean;
}>(
  `SELECT home_address,
          congressional_geo_id, state_senate_geo_id, state_house_geo_id,
          county_geo_id, school_district_geo_id,
          jurisdiction_state, jurisdiction_city,
          (encrypted_lat IS NOT NULL) AS has_coords
   FROM connect.connected_profiles WHERE user_id = $1`,
  [userId]
);
const j = rows[0];
const homeAddress = j?.home_address ?? '';
```

This is a minor optimization but also simplifies the control flow.

### Path 1.5 logic

```typescript
// --- Path 1.5: encrypted coords present but geo_ids not yet stored ---
if (j && j.has_coords && !j.congressional_geo_id && !j.state_senate_geo_id) {
  // Decrypt + resolve via RPC
  const { data: jData, error: jError } = await adminRpc('resolve_user_jurisdiction', {
    p_user_id: userId,
  }, 'connect');

  if (!jError && jData) {
    const jd = jData as Record<string, string | null>;

    // Write back the 10 resolvable columns (geo IDs + names)
    // jurisdiction_state and jurisdiction_city cannot be recovered from RPC — leave null
    pool.query(
      `UPDATE connect.connected_profiles
       SET congressional_geo_id        = $2,
           congressional_district_name = $3,
           state_senate_geo_id         = $4,
           state_senate_district_name  = $5,
           state_house_geo_id          = $6,
           state_house_district_name   = $7,
           county_geo_id               = $8,
           county_name                 = $9,
           school_district_geo_id      = $10,
           school_district_name        = $11,
           updated_at                  = now()
       WHERE user_id = $1`,
      [userId, jd.congressional, jd.congressional_name, jd.state_senate, jd.state_senate_name,
       jd.state_house, jd.state_house_name, jd.county, jd.county_name,
       jd.school_district, jd.school_district_name]
    ).catch((e: Error) => console.error('[representatives/me] Path 1.5 write-back error:', e.message));

    // Serve result same as Path 1
    const [politicians, localOfficials] = await Promise.all([
      getRepresentativesByJurisdiction({
        congressional: jd.congressional,
        state_senate: jd.state_senate,
        state_house: jd.state_house,
        county: jd.county,
        school_district: jd.school_district,
      }),
      getLocalOfficialsByUserId(userId),
    ]);
    // ... merge, set headers, return 200
  }
  // If RPC error (e.g., no boundaries loaded for user's coords) — fall through to Path 2
}
```

The write-back is fire-and-forget (`.catch()`) — same pattern as set-location. A write failure logs but does not fail the request.

### Backfill script pattern

Modeled after `backend/scripts/backfill-indiana-office-titles.ts`:

```typescript
// Usage:
//   npx tsx scripts/backfill-pre-phase49-geo-ids.ts --dry-run
//   npx tsx scripts/backfill-pre-phase49-geo-ids.ts

// 1. SELECT user_id FROM connect.connected_profiles
//    WHERE encrypted_lat IS NOT NULL
//      AND congressional_geo_id IS NULL
//
// 2. For each user_id:
//    - Call SELECT connect.resolve_user_jurisdiction($1) AS j
//    - If j returns non-null geo IDs: UPDATE connected_profiles with the 10 columns
//    - Log: fixed / still-null (geofence gap)
//
// 3. Print summary: N affected users, N fixed, N still-null (geofence gap)
```

The script calls the RPC per-user via `pool.query('SELECT connect.resolve_user_jurisdiction($1) AS j', [userId])`. This is equivalent to calling it from SQL and returns the same `jsonb` object.

### Anti-Patterns to Avoid

- **Calling resolve_user_jurisdiction for users without encrypted_lat**: The RPC raises EXCEPTION. Always guard with `has_coords` check.
- **Using pool.query to call resolve_user_jurisdiction**: The RPC requires Vault access, which is available via SECURITY DEFINER. `pool.query` can call it — it runs server-side and accesses Vault internally. This is fine and is used in the backfill script approach.
- **Forgetting to restore adminRpc import in essentials.ts**: It was explicitly removed in Phase 49-02. Must be re-added.
- **Writing jurisdiction_state / jurisdiction_city in Path 1.5**: Cannot — only geocoder knows city/state. Leave as null; populated on next set-location.
- **Failing the request if Path 1.5 RPC returns null**: If `resolve_user_jurisdiction` returns all-null (no boundaries loaded), fall through to Path 2. Never hard-fail the route.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Coordinate decryption | Node.js Vault + pgcrypto | `connect.resolve_user_jurisdiction` RPC | Already exists, SECURITY DEFINER, never exposes raw coords |
| District boundary lookup | New PostGIS query in Node | `connect.resolve_user_jurisdiction` RPC | Already does ST_Covers against inform.district_boundaries |
| Backfill iteration | SQL migration UPDATE subquery | TypeScript script with per-user logging | Better observability for diagnosing CA geofence gap |

---

## Common Pitfalls

### Pitfall 1: adminRpc import missing from essentials.ts

**What goes wrong:** Phase 49-02 removed `adminRpc` from essentials.ts. Path 1.5 needs it to call `resolve_user_jurisdiction`. TypeScript will fail to compile.

**How to avoid:** Import `adminRpc` from `../lib/supabaseAdmin.js` (or wherever it's imported in connect.ts). Check connect.ts import line for the exact import path.

**Warning signs:** `tsc --noEmit` fails with "cannot find name adminRpc."

### Pitfall 2: Column name mismatch

**What goes wrong:** Phase 49 research used `congressional_name` but the actual migration uses `congressional_district_name`. Using wrong column names silently fails (PostgreSQL UPDATE with unknown column raises error; TypeScript type would miss it if not explicit).

**How to avoid:** Use the exact column names from `20260326000053_phase49_jurisdiction_columns.sql`:
- `congressional_district_name`
- `state_senate_district_name`
- `state_house_district_name`
- `county_name`
- `school_district_name`

### Pitfall 3: resolve_user_jurisdiction EXCEPTION vs null return

**What goes wrong:** If the RPC is called for a user with `encrypted_lat IS NOT NULL` but whose coordinates fall outside all loaded boundary polygons, the RPC returns a jsonb with all-null values (it does NOT raise an exception in this case). But if `encrypted_lat IS NULL`, it raises an EXCEPTION.

**Critical distinction:** `RAISE EXCEPTION` only on null encrypted_lat. All-null geo IDs (outside boundaries) is a normal jsonb return, not an exception.

**How to avoid:** The `has_coords` guard prevents the null-lat exception. If the RPC returns all-null (no boundary match), the code should fall through to Path 2, not fail.

### Pitfall 4: Backfill script ignores users with location_consent = false

**What goes wrong:** A user may have `encrypted_lat IS NOT NULL` due to a past `upsert_user_location` call but `location_consent = false` due to a subsequent revocation. The `resolve_user_jurisdiction` RPC checks `location_consent = true` at line 120 of the migration — it won't find their coords and raises EXCEPTION.

**How to avoid:** The backfill query must include `AND location_consent = true` alongside `encrypted_lat IS NOT NULL`.

### Pitfall 5: Path 1.5 write-back is fire-and-forget — verify async pattern

**What goes wrong:** If `pool.query(...).catch(...)` write-back is awaited, a DB error would propagate. If it's not caught at all, unhandled rejection. If `.catch()` is used but the promise is not awaited, it's fire-and-forget — correct pattern for non-critical write.

**How to avoid:** Use `pool.query(...).catch((e: Error) => console.error(...))` without `await` — same as set-location pattern. TypeScript strict may require `void pool.query(...)` to silence unused-promise lint.

---

## Code Examples

### adminRpc import to restore in essentials.ts

Check connect.ts for the exact import:
```typescript
// Source: C:/EV-Accounts/backend/src/routes/connect.ts (existing import)
import { adminRpc } from '../lib/supabaseAdmin.js';
```

### resolve_user_jurisdiction return shape (from RPC source)
```typescript
// Source: supabase/migrations/20260310000032_location_rpcs.sql lines 144-158
// Returns jsonb with 10 keys:
{
  congressional:        string | null,   // TIGER/Line GEOID e.g. "0637"
  congressional_name:   string | null,
  state_senate:         string | null,   // e.g. "06028"
  state_senate_name:    string | null,
  state_house:          string | null,   // e.g. "06055"
  state_house_name:     string | null,
  county:               string | null,   // e.g. "06037"
  county_name:          string | null,
  school_district:      string | null,   // e.g. "0610260"
  school_district_name: string | null,
}
// Does NOT return: state, city, or raw coordinates
```

### Column names for connected_profiles write-back (from shipped migration)
```sql
-- Source: supabase/migrations/20260326000053_phase49_jurisdiction_columns.sql
congressional_geo_id        TEXT
congressional_district_name TEXT   -- note: _district_name, not _name
state_senate_geo_id         TEXT
state_senate_district_name  TEXT   -- note: _district_name, not _name
state_house_geo_id          TEXT
state_house_district_name   TEXT   -- note: _district_name, not _name
county_geo_id               TEXT
county_name                 TEXT   -- note: _name only (no _district_)
school_district_geo_id      TEXT
school_district_name        TEXT   -- note: _name only (no _district_)
jurisdiction_state          TEXT
jurisdiction_city           TEXT
```

### Backfill script query
```typescript
// Identify affected users
const { rows: affected } = await pool.query(
  `SELECT user_id FROM connect.connected_profiles
   WHERE encrypted_lat IS NOT NULL
     AND location_consent = true
     AND congressional_geo_id IS NULL`
);

// Per-user resolve + write
for (const { user_id } of affected) {
  const { rows } = await pool.query(
    `SELECT connect.resolve_user_jurisdiction($1) AS j`,
    [user_id]
  );
  const j = rows[0]?.j as Record<string, string | null> | null;
  if (!j || !j.congressional) {
    console.log(`[backfill] ${user_id}: no boundary match (geofence gap)`);
    continue;
  }
  if (!isDryRun) {
    await pool.query(
      `UPDATE connect.connected_profiles
       SET congressional_geo_id        = $2,
           congressional_district_name = $3,
           state_senate_geo_id         = $4,
           state_senate_district_name  = $5,
           state_house_geo_id          = $6,
           state_house_district_name   = $7,
           county_geo_id               = $8,
           county_name                 = $9,
           school_district_geo_id      = $10,
           school_district_name        = $11,
           updated_at                  = now()
       WHERE user_id = $1`,
      [user_id, j.congressional, j.congressional_name, j.state_senate, j.state_senate_name,
       j.state_house, j.state_house_name, j.county, j.county_name,
       j.school_district, j.school_district_name]
    );
  }
  console.log(`[backfill] ${user_id}: fixed`);
}
```

---

## State of the Art

| Situation | Before Phase 50 | After Phase 50 |
|-----------|----------------|----------------|
| Pre-Phase-49 user with encrypted coords, null geo_ids | Falls to Path 2 → geocodes null home_address → 204 No Content | Path 1.5 → decrypts + resolves → correct ~15-20 politicians |
| Post-Phase-49 user (set-location after 49-02) | Path 1 with stored geo_ids | Unchanged — still Path 1 |
| User with no location at all | Path 2 → 204 No Content | Unchanged |
| Pre-Phase-49 user after Phase 50 first request | Backfill might have fixed them | If not fixed by backfill: Path 1.5 writes geo_ids; subsequent requests use Path 1 |

---

## Open Questions

1. **CA geofence gap status**
   - What we know: Phase 49-01 backfill got nulls for 6 of 8 users, attributed to "CA geofence gap." The boundaries for those users' locations were not loaded at the time.
   - What's unclear: Is the CA geofence gap still present? If yes, Path 1.5 will return null from the RPC for CA users and still fall to Path 2.
   - Recommendation: Run `SELECT COUNT(*) FROM inform.district_boundaries WHERE district_type = 'congressional'` or `SELECT DISTINCT district_type FROM inform.district_boundaries` to check if CA boundaries are now loaded. The backfill script's dry-run output will reveal how many users are still null after the RPC.

2. **Should Path 1.5 write-back be awaited (blocking) or fire-and-forget?**
   - What we know: set-location uses fire-and-forget (non-fatal) for the write.
   - Recommendation: Fire-and-forget (same as set-location). The write's success/failure doesn't affect whether this request returns correct politicians. The next request will still trigger Path 1.5 if the write failed (extra RPC call, harmless).

3. **X-Formatted-Address header for Path 1.5 users**
   - What we know: `jurisdiction_state` and `jurisdiction_city` are null for pre-Phase-49 users. The header fallback `homeAddress || [j.jurisdiction_city, j.jurisdiction_state].filter(Boolean).join(', ')` will be empty string.
   - Recommendation: Accept empty string for now. It's a display-only header. After next set-location, it populates correctly.

---

## Sources

All findings from direct codebase inspection — no external sources needed.

### Primary (HIGH confidence)
- `C:/EV-Accounts/backend/src/routes/essentials.ts` — current Path 1 / Path 2 implementation (read in full)
- `C:/EV-Accounts/backend/src/routes/connect.ts` lines 562–634 — adminRpc pattern for resolve_user_jurisdiction, column write-back
- `C:/EV-Accounts/supabase/migrations/20260326000053_phase49_jurisdiction_columns.sql` — exact column names shipped in Phase 49-01
- `C:/EV-Accounts/supabase/migrations/20260310000032_location_rpcs.sql` lines 90–163 — resolve_user_jurisdiction RPC (exception on null lat, return shape)
- `C:/EV-Accounts/.planning/phases/49-stored-jurisdiction-cross-app-location-profile/49-01-SUMMARY.md` — backfill got 2/8 users; 6 returned null (CA geofence gap)
- `C:/EV-Accounts/.planning/phases/49-stored-jurisdiction-cross-app-location-profile/49-02-SUMMARY.md` — adminRpc removed from essentials.ts; home_address write removed from set-location
- `C:/EV-Accounts/backend/scripts/backfill-indiana-office-titles.ts` — one-time backfill script pattern (dry-run, pool, logging)
- `C:/EV-Accounts/backend/src/lib/essentialsService.ts` lines 1309–1316 — JurisdictionGeoIds interface, getLocalOfficialsByUserId signature

---

## Metadata

**Confidence breakdown:**
- Route modification (Path 1.5 logic): HIGH — current code read, RPC behavior confirmed from migration source
- Column names: HIGH — confirmed from shipped migration file
- adminRpc pattern: HIGH — identical call pattern already in connect.ts
- Backfill script approach: HIGH — modeled on existing backfill script in repo
- CA geofence gap resolution: LOW — unknown whether CA boundaries are now loaded; dry-run needed

**Research date:** 2026-03-30
**Valid until:** 2026-04-30 (stable codebase, no fast-moving dependencies)
