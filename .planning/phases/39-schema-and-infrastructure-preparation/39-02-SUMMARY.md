---
phase: 39-schema-and-infrastructure-preparation
plan: 02
subsystem: infra
tags: [python, supabase, storage, upload, pipeline, config, la-county]

# Dependency graph
requires:
  - phase: 39-schema-and-infrastructure-preparation
    provides: Plan 01 BuildingPhoto model and schema migrations for v1.7 enrichment pipeline
provides:
  - Reusable Supabase Storage upload function (upload_photo_to_storage) with correct content-type and upsert behavior
  - load_supabase_env() and get_supabase_client() credential helpers
  - load_pipeline_config() reading region data from pipeline_config.json
  - pipeline_config.json with LA County definition (90 cities, supervisors/council sources)
  - supabase==2.28.0 dependency in requirements.txt
  - Ext ID counter bumped to -300001 for v1.7 range
affects:
  - 40-headshot-enrichment
  - 41-contact-and-building-enrichment
  - 42-biography-enrichment
  - 43-term-dates-enrichment
  - 44-data-quality-and-validation

# Tech tracking
tech-stack:
  added: [supabase==2.28.0 (supabase-py)]
  patterns:
    - Lazy supabase import inside get_supabase_client() — scripts that don't use Storage are unaffected
    - Config-driven pipeline regions — adding a new county requires only a new JSON key, no Python code changes
    - Raw bytes + explicit content-type upload to Supabase Storage — avoids base64 corruption and text/plain MIME type pitfall
    - Upsert behavior (upsert=true) for re-scrape idempotency — same CDN URL reused on overwrite

key-files:
  created:
    - EV-Backend/scripts/pipeline_config.json
  modified:
    - EV-Backend/scripts/utils.py
    - EV-Backend/scripts/requirements.txt

key-decisions:
  - "Supabase import is lazy (inside get_supabase_client) to avoid requiring the package for DB-only scripts"
  - "upload_photo_to_storage() always uses explicit content-type — SDK defaults to text/plain which corrupts image serving"
  - "upsert=true on upload so re-running scripts overwrites old photos at the same CDN URL — no URL drift"
  - "pipeline_config.json is the v1.7 enrichment master config (separate from city_sources.json which is the v1.6 scraper config)"
  - "Ext ID counter advanced to -300001 for v1.7 to avoid collisions with v1.6 IDs (-200001 range)"

patterns-established:
  - "Config-driven regions: all enrichment scripts accept --region arg defaulting to default_region in pipeline_config.json"
  - "Supabase credentials loaded from same .env.local as DATABASE_URL — single credential file for all scripts"

requirements-completed: [PIPE-01, PIPE-04]

# Metrics
duration: 2min
completed: 2026-02-25
---

# Phase 39 Plan 02: Supabase Upload Utilities and Pipeline Config Summary

**Supabase Storage upload helper with explicit content-type/upsert plus config-driven pipeline_config.json covering 90 LA County cities for Phases 40-44 enrichment scripts**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-02-25T01:02:10Z
- **Completed:** 2026-02-25T01:04:50Z
- **Tasks:** 3 of 3 completed
- **Files modified:** 3

## Accomplishments
- Added 5 new functions to utils.py: load_supabase_env, get_supabase_client, upload_photo_to_storage, load_pipeline_config, and PHOTO_BUCKET constant
- Created pipeline_config.json with LA County region definition (90 cities including la_city, plus supervisors and city council sources)
- Bumped ext ID counter to -300001 for v1.7 to prevent collisions with v1.6 IDs
- Added supabase==2.28.0 to requirements.txt for all enrichment scripts

## Task Commits

Each task was committed atomically in EV-Backend repo:

1. **Task 1: Add Supabase upload utilities to utils.py and update requirements.txt** - `570cc9c` (feat)
2. **Task 2: Create pipeline_config.json with LA County region definition** - `1944124` (feat)
3. **Task 3: Verify Supabase bucket and credentials** - VERIFIED (bucket exists, public access, upload returns CDN URL with correct content-type)

## Files Created/Modified
- `EV-Backend/scripts/utils.py` - Added load_supabase_env, get_supabase_client, upload_photo_to_storage, load_pipeline_config; bumped ext ID to -300001
- `EV-Backend/scripts/requirements.txt` - Added supabase==2.28.0
- `EV-Backend/scripts/pipeline_config.json` - New file: la_county region with 90 cities (id/name/place_geoid only), supervisors and la_city_council sources

## Decisions Made
- Lazy supabase import inside get_supabase_client() so DB-only scripts don't need the package installed
- Explicit content-type on every upload (SDK defaults to text/plain which breaks `<img>` tags)
- Upsert behavior (upsert=true) so re-running scripts is idempotent — same CDN URL on overwrite
- pipeline_config.json is separate from city_sources.json — the latter is v1.6 scraper-specific, the former is v1.7 enrichment pipeline master config
- Kept only id/name/place_geoid in pipeline cities — scraper-specific fields (election_type, roster, etc.) don't belong in enrichment config

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - all functions imported cleanly, all 5 automated verifications passed.

## User Setup Required

**External services require manual configuration.** Task 3 (checkpoint:human-verify) requires the following:

1. **Create Supabase Storage bucket:**
   - Go to Supabase Dashboard -> Storage -> New Bucket
   - Name: `politician-photos`
   - Toggle "Public bucket" ON
   - Click "Create bucket"

2. **Add credentials to EV-Backend/.env.local:**
   ```
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_SERVICE_KEY=eyJhbGci...your-service-role-key...
   ```
   Use the **service_role** key (NOT the anon key) from Supabase Dashboard -> Project Settings -> API

3. **Install dependencies and test upload:**
   ```bash
   cd EV-Backend/scripts
   pip install -r requirements.txt
   python3 -c "
   from utils import load_supabase_env, upload_photo_to_storage
   load_supabase_env()
   import struct
   test_bytes = bytes.fromhex('ffd8ffe000104a46494600010100000100010000ffdb004300080606070605080707070909080a0c140d0c0b0b0c1912130f141d1a1f1e1d1a1c1c20242e2720222c231c1c2837292c30313434341f27393d38323c2e333432ffc0000b08000100010101100000ffc4001f0000010501010101010100000000000000000102030405060708090a0bffc40000ffd9')
   url = upload_photo_to_storage(test_bytes, 'test/pixel.jpg', 'image/jpeg')
   print(f'Upload OK! CDN URL: {url}')
   "
   ```

4. **Verify CDN URL** is accessible in browser without authentication

## Next Phase Readiness
- Once Supabase bucket is created and credentials verified, Phase 40 (Headshot Enrichment) can use upload_photo_to_storage() directly
- All Phase 40-44 enrichment scripts can use load_pipeline_config() for city/region iteration
- pipeline_config.json is the single source of truth for region expansion — adding Orange County requires only a new JSON key

## Self-Check: PASSED

- FOUND: EV-Backend/scripts/utils.py
- FOUND: EV-Backend/scripts/requirements.txt
- FOUND: EV-Backend/scripts/pipeline_config.json
- FOUND: .planning/phases/39-schema-and-infrastructure-preparation/39-02-SUMMARY.md
- FOUND: commit 570cc9c (Task 1 - Supabase utilities and requirements)
- FOUND: commit 1944124 (Task 2 - pipeline_config.json)

---
*Phase: 39-schema-and-infrastructure-preparation*
*Completed: 2026-02-25*
