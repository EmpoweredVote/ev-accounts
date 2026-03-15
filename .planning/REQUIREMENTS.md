# Requirements: Empowered Accounts v1.3

**Defined:** 2026-03-09
**Core Value:** Every platform feature can answer "does this user have permission to do X?" with a single join to the appropriate tier table — no flag chains, no application guesses, no partial states.

## v1.3 Requirements

### DEPLOY — Live Alpha Deployment

- [ ] **DEPLOY-01**: Migrations 026–029 applied to production Supabase instance with pre/post verification queries
- [x] **DEPLOY-02**: Deployment runbook documented — migration order, rollback steps, environment checklist, PostGIS + pgcrypto enablement steps
- [ ] **DEPLOY-03**: Production smoke test suite passes — health check, auth flow, compass endpoints, admin UI, essentials politicians endpoint

### CV2 — CompassV2 API Contract (accounts side)

- [x] **CV2-01**: Accounts API accepts `Authorization: Bearer <token>` in addition to session cookie for all authenticated routes
- [x] **CV2-02**: `GET /api/account/me` returns full structured shape including `completed_onboarding: boolean` and structured `xp: { total, level, xp_in_level, xp_to_next_level }` object
- [x] **CV2-03**: `POST /api/auth/signup` accepts and stores `email` field
- [x] **CV2-04**: Compass answer response shape aligned with CompassV2 expectations (verify with CompassV2 repo contract)
- [x] **CV2-05**: `GET /api/admin/me` endpoint returns admin identity `{ id, email }` (replaces `/auth/admin-check` pattern)

### LOC — Location Infrastructure

- [ ] **LOC-01**: `connect.connected_profiles` gains `encrypted_lat bytea`, `encrypted_lng bytea`, `location_consent boolean NOT NULL DEFAULT false`, `location_set_at timestamptz`; `public.users` view updated to exclude encrypted columns
- [ ] **LOC-02**: Supabase Vault secret `location_encryption_key` created; pgcrypto extension enabled; all coordinate reads/writes exclusively via SECURITY DEFINER RPCs using `extensions.pgp_sym_encrypt_bytea` / `extensions.pgp_sym_decrypt_bytea`
- [ ] **LOC-03**: `connect.upsert_user_location(user_id uuid, lat float8, lng float8)` RPC — encrypts via Vault key, writes to connected_profiles, sets `location_consent = true`, `location_set_at = now()`
- [ ] **LOC-04**: `inform.district_boundaries` PostGIS table created with GIST index; six Indiana TIGER/Line 2024 shapefiles loaded as runbook step (congressional, state upper/lower, county, place, unified school district), reprojected 4269→4326
- [ ] **LOC-05**: `connect.resolve_user_jurisdiction(user_id uuid)` RPC — decrypts coordinates, runs `extensions.ST_Covers` queries (not ST_Contains), uses `extensions.ST_MakePoint(lng, lat)` (longitude first), returns `{ city, state, county, congressional_district, state_upper, state_lower, school_district, geo_precision }` — never raw coordinates; `place` returns null for unincorporated addresses (not an error)
- [ ] **LOC-06**: `GET /api/account/me/jurisdiction` — authenticated, returns 403 if `location_consent = false`, calls `resolve_user_jurisdiction`, returns jurisdiction JSON
- [ ] **LOC-07**: `POST /api/connect/set-location` — new endpoint (separate from connect/complete), accepts `{ address: string }`, validates PO Box rejection (Zod), calls Census Geocoder API, calls `upsert_user_location` RPC; geocoding I/O is not inside any DB transaction
- [ ] **LOC-08**: Architecture test asserts `encrypted_lat`, `encrypted_lng`, and any plaintext coordinate representation never appear in route SELECT lists or API responses
- [ ] **LOC-09**: Input validation rejects PO Box addresses (`PO Box`, `P.O. Box`, `POB` case-insensitive) with user-facing error before geocoding

### PROF — empowered_profiles Politician Schema

- [x] **PROF-01**: Migration adds politician fields to `empower.empowered_profiles`: `representing_city`, `representing_state`, `district_type`, `district_label`, `district_id`, `chamber_name`, `chamber_name_formal`, `government_name`, `office_title`, `is_vacant boolean`, `is_candidate boolean` — schema designed as VQ consensus output target and Essentials consumption target
- [x] **PROF-02**: `GET /api/essentials/politicians` and `GET /api/essentials/candidates` updated to return all new fields; field names match Essentials `usePoliticianData.js` consumption exactly
- [x] **PROF-03**: Supabase types regenerated (`database.types.ts`); TypeScript strict compilation passes with 0 errors across backend + admin

### GEM — Multi-Currency Gem System

- [ ] **GEM-01**: `connect.gem_transactions` gains `gem_type gem_type_enum NOT NULL` where `gem_type_enum = ('yellow', 'blue', 'red')`; existing rows backfilled to `'yellow'`
- [ ] **GEM-02**: `connect.connected_profiles` gains `yellow_gem_balance integer NOT NULL DEFAULT 0`, `blue_gem_balance integer NOT NULL DEFAULT 0`, `red_gem_balance integer NOT NULL DEFAULT 0`; legacy `gem_balance` column removed after backfill
- [ ] **GEM-03**: `credit_gems` RPC updated to accept `gem_type gem_type_enum` parameter; advisory lock covers all three balances atomically; existing CTC integration updated to pass `gem_type = 'yellow'`
- [ ] **GEM-04**: `POST /api/gems/award` endpoint — service-key authenticated, per-key `permittedTypes` enforcement (keys declare which gem types they can award), idempotent with `idempotency_key`, returns `{ gem_type, amount, new_balance, is_duplicate }`
- [ ] **GEM-05**: `GET /api/account/me` returns structured gem object `{ yellow: number, blue: number, red: number }` replacing legacy `gem_balance` integer
- [ ] **GEM-06**: Gem balance-always-0 bug confirmed fixed — integration test awards yellow gems and asserts `yellow_gem_balance` increments correctly on `/api/account/me`
- [ ] **GEM-07**: Admin tool account detail page displays three gem balances (yellow / blue / red) replacing single balance display

### PROFILE — Central Profile Page

- [x] **PROFILE-01**: `GET /api/account/profile/:userId` — public endpoint returning `{ username, tier, level, total_xp, selected_topic_ids, empowered_profile? }` (no gems, no tolerance_rating, no location)
- [x] **PROFILE-02**: `GET /api/account/profile/me` — authenticated owner view adds `{ gem_balances: { yellow, blue, red }, location_consent, email }` to the public shape
- [x] **PROFILE-03**: Profile page UI in admin React app — displays aggregated profile data using the new endpoint; replaces any per-feature profile views in the admin tool

## Future Requirements

### Post-Alpha Location Expansion

- **LOC-F01**: Full US TIGER/Line boundary loading (expand beyond Indiana)
- **LOC-F02**: City council ward boundaries (not in TIGER/Line — requires city GIS portal data per city)
- **LOC-F03**: Location key rotation procedure (decrypt all rows, re-encrypt with new key)
- **LOC-F04**: `is_stale` flag on stored coordinates + re-resolution trigger after redistricting

### Post-Alpha Gem Economy

- **GEM-F01**: `debit_gems` RPC updated for multi-currency (debit specific gem type)
- **GEM-F02**: Gem reserve cap per currency (deferred per CIVIC-02)
- **GEM-F03**: Blue gem voting integration (Symposiums)
- **GEM-F04**: Red gem Awareness Exchange spend (future feature repo)

### Post-Alpha Profile

- **PROFILE-F01**: Verification history tab on profile (Validation Quests)
- **PROFILE-F02**: Framer-embeddable profile widget

## Out of Scope

| Feature | Reason |
|---------|--------|
| Validation Quests implementation | Separate feature repo; accounts provides the schema target and jurisdiction endpoint |
| CompassV2 frontend CV2 changes | CompassV2 repo owns its side; accounts ships the API contract |
| Full US district boundary loading | Alpha is Bloomington, IN only; expansion is a data load task, not an architecture change |
| City council ward boundaries | Not in TIGER/Line; requires per-city GIS data; not Alpha-critical |
| Location key rotation automation | One-time Alpha concern; runbook procedure sufficient |
| Gem debit for multi-currency | Credit path first; debit follows same pattern but is not needed for Alpha |
| User-to-user compass compare | Infrastructure in place; deferred (COMP-05) |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DEPLOY-01 | Phase 17 | Pending |
| DEPLOY-02 | Phase 17 | Pending |
| DEPLOY-03 | Phase 17 | Pending |
| CV2-01 | Phase 18 | Complete |
| CV2-02 | Phase 18 | Complete |
| CV2-03 | Phase 18 | Complete |
| CV2-04 | Phase 18 | Complete |
| CV2-05 | Phase 18 | Complete |
| LOC-01 | Phase 19 | Pending |
| LOC-02 | Phase 19 | Pending |
| LOC-03 | Phase 19 | Pending |
| LOC-04 | Phase 19 | Pending |
| LOC-05 | Phase 19 | Pending |
| LOC-06 | Phase 20 | Pending |
| LOC-07 | Phase 20 | Pending |
| LOC-08 | Phase 20 | Pending |
| LOC-09 | Phase 20 | Pending |
| PROF-01 | Phase 21 | Complete |
| PROF-02 | Phase 21 | Complete |
| PROF-03 | Phase 21 | Complete |
| GEM-01 | Phase 22 | Pending |
| GEM-02 | Phase 22 | Pending |
| GEM-03 | Phase 22 | Pending |
| GEM-04 | Phase 22 | Complete |
| GEM-05 | Phase 22 | Complete |
| GEM-06 | Phase 22 | Complete |
| GEM-07 | Phase 22 | Complete |
| PROFILE-01 | Phase 23 | Complete |
| PROFILE-02 | Phase 23 | Complete |
| PROFILE-03 | Phase 23 | Complete |

**Coverage:**
- v1.3 requirements: 29 total
- Mapped to phases: 29
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-09*
*Last updated: 2026-03-09 after initial definition*
