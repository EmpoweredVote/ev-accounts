# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-09 after v1.3 milestone start)

**Core value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.
**Current focus:** Phase 21 — next phase TBD

## Current Position

Phase: 20 of 23 (Location Endpoints) — COMPLETE
Plan: 4 of 4 complete
Status: Phase complete — all 4 plans done
Last activity: 2026-03-13 — Completed 20-04-PLAN.md (coordinate leakage architecture test)

Progress: [████░░░░░░] ~55% (12 of ~22 v1.3 plans complete)

## Performance Metrics

**v1.0 shipped:**
- Total plans: 18 plans, 8 phases, 4 days

**v1.1 shipped:**
- Plans: 5 (09-01, 09-02, 10-01, 10-02, 11-01)
- Phases: 3 (Phase 9–11)
- Timeline: 1 day (2026-03-04)

**v1.2 shipped:**
- Plans: 15 (12-01 through 16-01)
- Phases: 5 (Phase 12–16)
- Timeline: 2 days (2026-03-06 → 2026-03-07)

## Accumulated Context

### Key Decisions

Full key decisions log in PROJECT.md. v1.3 architecture decisions:

- **Location: encrypted lat/lng, not formatted address string** — Store only coordinates (pgcrypto via Supabase Vault). Address string discarded after geocoding. Coordinates never returned in any API response.
- **PostGIS internal, Indiana-scoped for Alpha** — TIGER/Line Indiana boundaries loaded into Supabase PostGIS. No third-party geographic API. Expand by loading more boundary data when scaling.
- **Multi-currency gems: extend existing ledger** — Add gem_type ENUM to connect.gem_transactions + 3 balance columns on connected_profiles. Single advisory lock pattern.
- **empowered_profiles politician columns as VQ output target** — Full field set matches Essentials consumed fields and maps to VQ consensus record structure.
- **Direct DB connection for migrations** — DATABASE_URL must use db.<ref>.supabase.co:5432 (direct), never the pooler (pooler.supabase.com:6543). Multi-statement SQL fails on pooler. (17-01)
- **Idempotent migration script** — Pre-verify before apply (skip if already applied), post-verify after apply (exit 1 if failed). Safe to re-run. (17-01)
- **PostGIS + pgcrypto enabled at Alpha deploy** — Both extensions documented in DEPLOY.md Step 1 even though Phase 19 needs them. Avoids second deploy window. (17-01)
- **Smoke test auth check: 401 is the only pass** — 500 = Supabase auth unreachable, 200 = catastrophic. Each status has distinct diagnostic meaning. (17-02)
- **Admin UI check hardcoded as [SKIP]** — Programmatic JS error detection not feasible in a fetch-based script; kept visible in output for operator checklist. (17-02)
- **Essentials politicians check validates migration 026** — Endpoint queries is_candidate column; 500 response during Alpha deploy = migration not applied. (17-02)
- **NUMERIC(3,1) for compass values; bounds 0.5–5.5** — INT stances (1–5) coexist with write-in half-integer positions. Outer bounds allow placement just outside defined stance range. (18-01)
- **migrate_guest_compass_state uses ON CONFLICT DO NOTHING** — never overwrites post-signup activity; per-row FK exception handler skips stale topic IDs rather than aborting. (18-01)
- **upsert_compass_answer gains SET search_path = ''** — was absent from migration 025 version; brought in line with project SECURITY DEFINER conventions. (18-01)
- **Anonymous compass mode: optionalAuth + short-circuit guard** — five answer routes return empty data ([], null, { topic_ids: [] }) for unauthenticated callers; guard placed before Zod parse so unauthenticated requests never hit validation. (18-02)
- **PUT/GET /selected-topics unauthenticated: { topic_ids: [] } not NOT_CONNECTED** — NOT_CONNECTED is reserved for authenticated users without a connected_profiles row; unauthenticated users simply have no topics. (18-02)
- **completed_onboarding at root AND in connected_profile** — additive promotion; both locations populated so no existing callers break. Inform-tier gets false at root. (18-03)
- **guest_state migration non-fatal: try/catch swallows errors** — signup always returns 201 on success regardless of migration outcome; errors logged for ops visibility. (18-03)
- **signUpBodySchema separate from authBodySchema** — login keeps minimal schema; signup schema extension is isolated and does not affect login validation. (18-03)
- **p_selected_topics null (not []) when absent** — RPC null guard skips UPDATE to selected_topics when no topics provided, avoiding overwrite of existing data. (18-03)
- **COMPASS_CONTRACT.md in /docs/ directory** — external-facing API contract for CompassV2 developer; login response user.tier is always "inform" (stub), GET /account/me required for real tier; selected_topics migration is Connected-only, localStorage fallback documented. (18-04)
- **Vault secret created in runbook, not migration** — embedding the location_encryption_key in a migration would permanently store it in migration history; created separately in RUNBOOK-TIGER-LOAD.md. (19-01)
- **location_set_at column in migration 031** — written by upsert_user_location RPC; included proactively to avoid a follow-up migration even though not explicitly listed in LOC-01 requirements. (19-01)
- **County ogr2ogr uses WHERE inside -sql, not standalone -where** — ogr2ogr treats -where and -sql as mutually exclusive; WHERE STATEFP='18' goes inside the -sql clause. Standalone -where with -sql silently loads all US counties or fails. (19-02)
- **Runbook structure: Vault creation is Step 1, before data load** — RPCs raise exception at call time if secret missing; runbook ordering enforces the prerequisite explicitly. (19-02)
- **convert_from(bytea, 'UTF8') not bytea::text for pgp_sym_decrypt_bytea output** — `bytea::text` produces hex repr (`\x33392e...`), not the original string. `convert_from()` decodes raw bytes to UTF-8 text correctly. Critical for resolve_user_jurisdiction float8 decode. (19-03)
- **PostGIS types in public schema, functions in extensions schema** — `geometry` type must be `public.geometry` in DECLARE blocks with `SET search_path = ''`. ST_* functions use `extensions.` prefix as documented. (19-03)
- **CREATE POLICY IF NOT EXISTS not supported in Supabase Postgres 17.4** — Use a DO block checking pg_policies instead. Affects any migration adding RLS policies with idempotency requirement. (19-03)
- **Session-mode pooler (pooler.supabase.com:5432) supports multi-statement SQL** — The port 6543 transaction-mode pooler is the problematic one. Port 5432 session-mode is safe for these migrations. (19-03)
- **geocodeAddress() privacy contract: coordinates never logged** — lat/lng returned as raw floats consumed by caller immediately; must only pass to upsert_user_location RPC, never log or return in API responses. (20-01)
- **GOOGLE_MAPS_API_KEY required at startup** — Missing key causes process.exit(1); geocoding call with missing key would produce confusing GEOCODING_API_ERROR at runtime. (20-01)
- **LA County: county boundary only for Alpha** — resolve_user_jurisdiction returns null for congressional/state_senate/state_house/school_district for CA addresses; county presence used to confirm in-coverage status. (20-01)
- **Jurisdiction consent gate: supabaseAdmin for consent check** — GET /me/jurisdiction uses supabaseAdmin (not user client) for the location_consent check; consistent with tierGuards.ts trusted server-side pattern. (20-03)
- **GET /me returns only location_consent boolean** — resolve_user_jurisdiction is never called from GET /me; jurisdiction data is only available via GET /me/jurisdiction. (20-03)
- **database.types.ts requires manual update when migrations add columns** — location_consent was missing from generated types after Phase 19 migration 031; manually added to Row/Insert/Update shapes. (20-03)
- **isInCoverage() bounding box in connect.ts, not geocodingService** — keeps the geocoding service generic; coverage policy belongs in the route layer. (20-02)
- **OUT_OF_COVERAGE returns 422 not 403** — address is syntactically valid but outside service area; 422 aligns with the other location validation error codes on this endpoint. (20-02)
- **Architecture tests in tests/architecture/, not backend/tests/** — vitest.config.ts include pattern is `../tests/**` relative to `backend/`; resolves to project root tests/. Static analysis tests use fs.readdirSync + readFileSync; negative lookahead excludes TS type annotations from object-key patterns. (20-04)

### Open Blockers

- **PostgREST schema config requires DB-level override** — Supabase dashboard UI change was not picked up by PostgREST. Fixed via `ALTER ROLE authenticator SET pgrst.db_schemas TO '...'`. Document this in DEPLOY.md for future deploys.
- **CompassV2 frontend CV2-01 through CV2-05** — Accounts side complete (Phase 18). CompassV2 repo must implement its side separately using COMPASS_CONTRACT.md as the integration spec.

### Pending Todos

None.

## Session Continuity

Last session: 2026-03-13
Stopped at: Completed 20-04-PLAN.md — coordinate leakage architecture test. Phase 20 complete.
Resume: Phase 21 — run /gsd:new-phase or continue v1.3 roadmap.
