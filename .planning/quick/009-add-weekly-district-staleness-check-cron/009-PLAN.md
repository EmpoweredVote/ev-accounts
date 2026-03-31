---
phase: quick
plan: 009
type: execute
wave: 1
depends_on: []
files_modified:
  - supabase/migrations/20260329000054_add_districts_last_verified_at.sql
  - backend/src/cron/districtStaleness.ts
  - backend/src/lib/districtStalenessService.ts
  - backend/src/index.ts
autonomous: true

must_haves:
  truths:
    - "A weekly cron fires every Sunday 3am UTC to re-verify district geo_ids"
    - "Users with stored coordinates have their jurisdiction re-resolved"
    - "Geo_ids are only updated when they actually changed (no churn)"
    - "districts_last_verified_at is always updated on each processed row"
    - "Per-user failures are non-fatal and logged"
  artifacts:
    - path: "supabase/migrations/20260329000054_add_districts_last_verified_at.sql"
      provides: "districts_last_verified_at column on connect.connected_profiles"
      contains: "districts_last_verified_at"
    - path: "backend/src/lib/districtStalenessService.ts"
      provides: "Core job logic"
      exports: ["runDistrictStalenessCheck"]
    - path: "backend/src/cron/districtStaleness.ts"
      provides: "node-cron registration"
      exports: ["startDistrictStalenessCron"]
  key_links:
    - from: "backend/src/index.ts"
      to: "backend/src/cron/districtStaleness.ts"
      via: "import + call startDistrictStalenessCron()"
      pattern: "startDistrictStalenessCron"
    - from: "backend/src/lib/districtStalenessService.ts"
      to: "connect.resolve_user_jurisdiction"
      via: "adminRpc"
      pattern: "adminRpc.*resolve_user_jurisdiction"
    - from: "backend/src/lib/districtStalenessService.ts"
      to: "connect.connected_profiles"
      via: "pool.query UPDATE"
      pattern: "pool\\.query.*UPDATE connect\\.connected_profiles"
---

<objective>
Add a weekly cron job that re-verifies district assignments for all Connected users who have stored coordinates, updating geo_ids only when boundaries have changed.

Purpose: District boundaries change over time (redistricting, annexations). This ensures users' district assignments stay current without manual intervention.
Output: Migration adding timestamp column + cron job service + registration wired into index.ts.
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@backend/src/cron/calibrationLapse.ts (pattern to follow for cron registration)
@backend/src/lib/cronService.ts (pattern to follow for service logic)
@backend/src/routes/connect.ts (lines 550-610 — existing set-location jurisdiction write pattern)
@backend/src/lib/supabase.ts (adminRpc helper)
@backend/src/lib/db.ts (pool export)
@backend/src/index.ts (cron registration site)
</context>

<tasks>

<task type="auto">
  <name>Task 1: Migration + district staleness service</name>
  <files>
    supabase/migrations/20260329000054_add_districts_last_verified_at.sql
    backend/src/lib/districtStalenessService.ts
  </files>
  <action>
**Migration** (`20260329000054_add_districts_last_verified_at.sql`):
```sql
ALTER TABLE connect.connected_profiles
  ADD COLUMN IF NOT EXISTS districts_last_verified_at TIMESTAMPTZ;
```
Apply via Supabase MCP `apply_migration`.

**Service** (`backend/src/lib/districtStalenessService.ts`):

Create `runDistrictStalenessCheck()` async function. Follow the same structure as `cronService.ts` (structured JSON logging, try/catch per user).

1. Import `adminRpc` from `../lib/supabase.js` and `pool` from `../lib/db.js`.

2. Query all connected_profiles with stored location:
```ts
const { rows: users } = await pool.query(
  `SELECT user_id, congressional_geo_id, state_senate_geo_id, state_house_geo_id,
          county_geo_id, school_district_geo_id
   FROM connect.connected_profiles
   WHERE encrypted_lat IS NOT NULL`
);
```

3. For each user, wrap in try/catch (non-fatal per user):
   - Call `adminRpc('resolve_user_jurisdiction', { p_user_id: user.user_id }, 'connect')`
   - Cast result to `Record<string, string | null>` (same as connect.ts line 572)
   - Compare the 5 geo_id fields: `congressional`, `state_senate`, `state_house`, `county`, `school_district` from the RPC result against stored values
   - If ANY geo_id differs: run a single `pool.query()` UPDATE setting all geo_id + name columns (mirror the exact UPDATE from connect.ts lines 574-604, but WITHOUT `jurisdiction_state` and `jurisdiction_city` since those come from geocoding, not jurisdiction resolution) AND `districts_last_verified_at = now()`
   - If NO geo_ids changed: run a minimal UPDATE setting only `districts_last_verified_at = now()` (no churn on geo columns)
   - On per-user error: `console.error` and increment `failed` counter, continue loop

4. Log summary as structured JSON:
```ts
console.log(JSON.stringify({
  level: 'info',
  job: 'district-staleness',
  users_checked: total,
  users_updated: updated,
  users_unchanged: unchanged,
  users_failed: failed,
  duration_ms: Date.now() - jobStart,
}));
```

**Important**: The RPC returns keys like `congressional`, `state_senate`, etc. (without `_geo_id` suffix). Compare `jData.congressional` against `user.congressional_geo_id`, etc. Match the exact key mapping used in connect.ts lines 592-603.

Also note: the RPC also returns `_name` variants (e.g., `congressional_name`). When updating changed geo_ids, also update the corresponding `_name` columns to keep them in sync.
  </action>
  <verify>
- `npx tsc --noEmit` passes (no type errors)
- Migration applied successfully via Supabase MCP
- Manual review: service imports are correct, UPDATE queries match connect.ts pattern
  </verify>
  <done>
- `districts_last_verified_at` column exists on `connect.connected_profiles`
- `districtStalenessService.ts` exports `runDistrictStalenessCheck`
- Service queries users with coordinates, re-resolves jurisdictions, updates only changed geo_ids, always stamps `districts_last_verified_at`
  </done>
</task>

<task type="auto">
  <name>Task 2: Cron registration + wiring</name>
  <files>
    backend/src/cron/districtStaleness.ts
    backend/src/index.ts
  </files>
  <action>
**Cron file** (`backend/src/cron/districtStaleness.ts`):
Follow `calibrationLapse.ts` pattern exactly:
```ts
import cron from 'node-cron';
import { runDistrictStalenessCheck } from '../lib/districtStalenessService.js';

export function startDistrictStalenessCron(): void {
  cron.schedule(
    '0 3 * * 0',   // Sunday 3:00 AM UTC
    async () => {
      try {
        await runDistrictStalenessCheck();
      } catch (err) {
        console.error('[cron] Unhandled error in district staleness check:', err);
      }
    },
    {
      timezone: 'UTC',
      name: 'district-staleness',
    }
  );
  console.log('[cron] District staleness check registered (weekly Sunday 03:00 UTC)');
}
```

**index.ts** — Add import and call alongside existing cron registrations:
- Import: `import { startDistrictStalenessCron } from './cron/districtStaleness.js';`
- Call: `startDistrictStalenessCron();` right after `startCampaignFinanceCron();` (line ~136)
  </action>
  <verify>
- `npx tsc --noEmit` passes
- `grep -n 'startDistrictStalenessCron' backend/src/index.ts` shows import and call
- Server starts without errors: `cd backend && npx tsx src/index.ts` (verify cron registration log line appears, then Ctrl+C)
  </verify>
  <done>
- `districtStaleness.ts` registers weekly cron at Sunday 3am UTC
- `index.ts` imports and calls `startDistrictStalenessCron()`
- Server boots cleanly with `[cron] District staleness check registered` in logs
  </done>
</task>

</tasks>

<verification>
- `npx tsc --noEmit` — no type errors across backend
- Server starts and all three cron jobs register (calibration-lapse, campaign-finance, district-staleness)
- `districts_last_verified_at` column exists: `SELECT column_name FROM information_schema.columns WHERE table_schema = 'connect' AND table_name = 'connected_profiles' AND column_name = 'districts_last_verified_at'` returns 1 row
</verification>

<success_criteria>
- Weekly cron registered at Sunday 3am UTC
- Service re-resolves jurisdictions for all users with stored coordinates
- Only writes geo_id columns when values actually changed
- Always updates `districts_last_verified_at` timestamp
- Per-user errors are caught and logged, never crash the job
- TypeScript compiles cleanly, server boots cleanly
</success_criteria>

<output>
After completion, create `.planning/quick/009-add-weekly-district-staleness-check-cron/009-SUMMARY.md`
</output>
