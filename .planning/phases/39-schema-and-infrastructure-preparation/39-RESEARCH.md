# Phase 39: Schema and Infrastructure Preparation - Research

**Researched:** 2026-02-24
**Domain:** PostgreSQL schema migrations (GORM), Supabase Storage (Python client), Python pipeline config architecture
**Confidence:** HIGH

## Summary

Phase 39 sets up three interdependent prerequisites that all enrichment phases (40-44) depend on: (1) new database columns/tables via GORM AutoMigrate, (2) a Supabase Storage bucket for photo CDN hosting, and (3) reusable Python utilities for photo upload plus a config-driven pipeline architecture.

The schema work follows the established GORM AutoMigrate pattern used throughout `internal/essentials/setup.go`. Adding a new column (`photo_license`, `term_date_precision`) requires only adding the field to the Go struct — GORM will ADD the column on next server start without dropping existing data. Adding a new table (`building_photos`) requires adding the struct and registering it in `AutoMigrate(...)`. This is the lowest-risk part of the phase.

The Supabase Storage work requires adding the `supabase` Python package (not currently in `scripts/requirements.txt`) and adding two new env vars (`SUPABASE_URL`, `SUPABASE_SERVICE_KEY`) to `.env.local`. The critical upload pattern is to pass `{"content-type": "image/jpeg", "upsert": "true"}` explicitly — the SDK defaults to `text/plain` without a content-type, silently corrupting image files. Service-role key bypasses all RLS, so scripts using the service key do not need any INSERT policy. Public read access requires creating the bucket with `public=True` (not an RLS policy — it sets `public: true` on the bucket record itself, enabling unauthenticated CDN downloads). The `get_public_url()` method returns a stable, permanent CDN URL that remains valid on re-upload/overwrite.

**Primary recommendation:** Add `supabase==2.28.0` to `requirements.txt`, add `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` to `.env.local`, implement `upload_photo_to_storage()` in `utils.py` following the verified upload pattern, and scaffold `pipeline_config.json` (or `.yaml`) with per-region city lists. All GORM model changes go in `models.go` + `setup.go` per the established pattern.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Adding a new region must require **config-only changes** — no Python code modifications needed
- Photos should be **overwritten on re-scrape** — same CDN URL is reused, no versioning
- **Track but don't block** — record license type for every photo, but don't prevent storing photos without a clear license
- License attribution is **internal only for now** — tracked in database, not displayed on frontend in v1.7
- Scripts connect **directly to Supabase** using the Python client for both database writes and storage uploads — no Go API admin endpoints needed

### Claude's Discretion
- Supabase bucket folder structure and file naming conventions
- Config file format (YAML vs JSON) and geographic granularity
- Whether scraping sources are defined in config per-city or discovered at runtime
- Python script organization (flat files vs package)
- Credential management approach (.env location)
- Logging strategy (console only vs file logging)
- Photo size handling (original only vs multiple sizes)
- License category enum values beyond the three examples
- Wikimedia license variant restrictions

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PIPE-01 | Enrichment scripts are idempotent and config-driven (re-runnable without duplicates) | Covered by: upsert=true upload option (Storage), ON CONFLICT upsert pattern (DB), config file as single source of truth for regions |
| PIPE-04 | Pipeline designed for future regional expansion (config-driven, not LA-specific) | Covered by: pipeline_config.json with region key at top level; scripts accept region as arg or default; no hard-coded city lists in Python |
</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| supabase-py | 2.28.0 (latest as of 2026-02) | Python client for Supabase Storage upload and public URL generation | Official Supabase client; same project already uses Supabase as DB host |
| GORM AutoMigrate | already in go.mod | Add new columns/tables to PostgreSQL without manual DDL | Already used for all existing schema migrations in setup.go |
| psycopg2-binary | 2.9.11 (pinned) | Direct DB writes from Python scripts | Already in requirements.txt; used by all existing import scripts |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| python-dotenv or manual parse | N/A | Load SUPABASE_URL and SUPABASE_SERVICE_KEY from .env.local | Follow existing `load_env()` pattern in utils.py — manual parse, no extra dependency |
| mimetypes (stdlib) | stdlib | Detect content-type from file extension | Use `mimetypes.guess_type()` as fallback; always prefer explicit MIME type when known |
| json (stdlib) | stdlib | Read pipeline config | Already used in scrape_city_councils.py for city_sources.json |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| supabase-py | boto3 + S3 API | Supabase Storage supports S3 API, but supabase-py is simpler and already aligned with the project's Supabase-first approach |
| JSON config | YAML config | YAML requires PyYAML dependency (not in requirements.txt); JSON is zero-dependency and already used by city_sources.json |
| GORM AutoMigrate | Raw SQL migration scripts | AutoMigrate is already the project pattern and handles ADD COLUMN safely; raw SQL adds maintenance overhead |

**Installation:**
```bash
# Add to EV-Backend/scripts/requirements.txt
supabase==2.28.0

# Install in venv
cd EV-Backend/scripts
python3.13 -m pip install supabase==2.28.0
```

---

## Architecture Patterns

### Recommended Project Structure
```
EV-Backend/scripts/
├── utils.py                    # ADD: upload_photo_to_storage(), load_supabase_env()
├── pipeline_config.json        # NEW: top-level { "regions": { "la_county": { cities: [...] } } }
├── scrape_la_supervisors.py    # Phase 40: uses upload_photo_to_storage()
├── scrape_la_city_council.py   # Phase 40: uses upload_photo_to_storage()
├── fetch_wikimedia_photos.py   # Phase 41: building photos
├── scrape_city_contacts.py     # Phase 41/43: contact info
├── requirements.txt            # ADD: supabase==2.28.0
└── .venv/                      # Python virtual environment
```

```
EV-Backend/internal/essentials/
├── models.go    # ADD: BuildingPhoto struct, photo_license field on PoliticianImage, term_date_precision on Politician
└── setup.go     # ADD: &BuildingPhoto{} to AutoMigrate list
```

### Pattern 1: GORM Column Addition (photo_license, term_date_precision)
**What:** Add a string field to an existing struct — AutoMigrate will ADD the column on next server start; no data loss.
**When to use:** Adding new columns to existing tables.
**Example:**
```go
// In models.go — add field to existing PoliticianImage struct
type PoliticianImage struct {
    ID           uuid.UUID `json:"id" gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    PoliticianID uuid.UUID `json:"politician_id" gorm:"type:uuid;index"`
    URL          string    `json:"url"`
    Type         string    `json:"type"` // "default", "thumb"
    PhotoLicense string    `json:"photo_license,omitempty"` // "cc_by_sa", "press_use", "scraped_no_license", etc.
}

// In Politician struct — add term_date_precision
type Politician struct {
    // ... existing fields ...
    TermDatePrecision string `json:"term_date_precision,omitempty"` // "year", "month", "day"
}

// setup.go — no change needed; existing AutoMigrate list covers modified structs
```

### Pattern 2: GORM New Table (building_photos)
**What:** Add new struct + register in AutoMigrate.
**When to use:** Adding a brand new table.
**Example:**
```go
// In models.go
type BuildingPhoto struct {
    PlaceGeoid   string    `json:"place_geoid" gorm:"primaryKey;size:20"`    // G4110 Census GEOID
    URL          string    `json:"url"`                                        // Supabase CDN URL
    SourceURL    string    `json:"source_url"`                                 // Original Wikimedia URL
    License      string    `json:"license"`                                    // e.g., "cc_by_sa"
    Attribution  string    `json:"attribution"`                                // Author/uploader credit
    WikiTitle    string    `json:"wiki_title"`                                 // Wikimedia file title
    FetchedAt    time.Time `json:"fetched_at"`
}

func (BuildingPhoto) TableName() string {
    return "essentials.building_photos"
}

// In setup.go — add to AutoMigrate list
if err := db.DB.AutoMigrate(
    // ... existing models ...
    &BuildingPhoto{},
); err != nil {
    log.Fatal("Failed to auto-migrate tables", err)
}
```

### Pattern 3: Supabase Storage Upload (Python)
**What:** Initialize supabase client with service key, upload image bytes with explicit content-type and upsert=true.
**When to use:** Storing scraped photos to CDN, overwriting on re-scrape.

**Critical warning from STATE.md:** Base64 encoding corrupts image files. Content-type MUST be explicit. Passing file as raw bytes (not base64-encoded string) is correct.

```python
# Source: https://supabase.com/docs/reference/python/storage-from-upload
# Source: https://github.com/supabase/storage-py/blob/main/README.md

import mimetypes
from supabase import create_client, Client

BUCKET_NAME = "politician-photos"

def load_supabase_env():
    """Load SUPABASE_URL and SUPABASE_SERVICE_KEY from .env.local.

    Must be called before get_supabase_client().
    Uses same .env.local as load_env() (DATABASE_URL, etc.).
    """
    import os
    from pathlib import Path
    if os.getenv("SUPABASE_URL") and os.getenv("SUPABASE_SERVICE_KEY"):
        return
    env_path = Path(__file__).parent.parent / ".env.local"
    if env_path.exists():
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line.startswith("SUPABASE_URL="):
                    os.environ["SUPABASE_URL"] = line.split("=", 1)[1]
                elif line.startswith("SUPABASE_SERVICE_KEY="):
                    os.environ["SUPABASE_SERVICE_KEY"] = line.split("=", 1)[1]


def get_supabase_client() -> Client:
    """Create Supabase client with service role key (bypasses RLS)."""
    import os
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_SERVICE_KEY")
    if not url or not key:
        raise RuntimeError("SUPABASE_URL and SUPABASE_SERVICE_KEY must be set")
    return create_client(url, key)


def upload_photo_to_storage(
    image_bytes: bytes,
    storage_path: str,
    content_type: str = "image/jpeg",
) -> str:
    """Upload image bytes to Supabase Storage and return the public CDN URL.

    Args:
        image_bytes: Raw image bytes (NOT base64-encoded — base64 corrupts binary files)
        storage_path: Path within bucket, e.g., "la_county/supervisors/{politician_id}.jpg"
        content_type: MIME type — MUST be explicit, SDK defaults to text/plain otherwise

    Returns:
        Public CDN URL (stable; survives re-upload/overwrite)

    Raises:
        Exception if upload fails
    """
    client = get_supabase_client()
    # upsert=true: overwrite on re-scrape (same URL reused — decision locked)
    client.storage.from_(BUCKET_NAME).upload(
        storage_path,
        image_bytes,
        {"content-type": content_type, "upsert": "true"},
    )
    # get_public_url() returns the stable public URL (no expiry, no auth required)
    public_url = client.storage.from_(BUCKET_NAME).get_public_url(storage_path)
    return public_url
```

### Pattern 4: Config-Driven Pipeline (PIPE-04)
**What:** JSON config file with region-keyed structure so adding Orange County is a config change, not code change.
**When to use:** All enrichment scripts.
**Example:**
```json
// scripts/pipeline_config.json
{
  "regions": {
    "la_county": {
      "state": "CA",
      "county": "Los Angeles",
      "supervisor_url": "...",
      "cities": [
        {
          "id": "la_city",
          "name": "City of Los Angeles",
          "place_geoid": "0644000",
          "ocd_id_base": "ocd-division/country:us/state:ca/place:los_angeles"
        }
      ]
    }
  },
  "default_region": "la_county"
}
```

Scripts accept `--region la_county` arg (defaulting to `default_region`) and load `config["regions"][region]` to get city list, URLs, and geographic identifiers.

### Pattern 5: Supabase Bucket Creation (one-time setup, via Dashboard or SQL)
**What:** Create public bucket with service-role-only upload restriction.
**When to use:** One-time bucket provisioning.

Option A — Supabase Dashboard: Storage > New Bucket > name `politician-photos` > toggle Public ON. No SQL needed; service key bypasses RLS for uploads.

Option B — SQL (via Supabase SQL editor):
```sql
-- Create public bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('politician-photos', 'politician-photos', true);

-- Optional: explicit service-role upload restriction
-- (service key bypasses RLS automatically, so this is for defense-in-depth)
CREATE POLICY "service_role_upload_only"
ON storage.objects FOR INSERT
TO service_role
WITH CHECK (bucket_id = 'politician-photos');

CREATE POLICY "public_read"
ON storage.objects FOR SELECT
USING (bucket_id = 'politician-photos');
```

### Anti-Patterns to Avoid
- **Base64-encoding image bytes before upload:** The supabase-py SDK accepts raw bytes. Encoding to base64 first produces a corrupt binary file that Supabase Storage cannot serve as an image.
- **Omitting content-type:** SDK defaults to `text/plain` when content-type is not specified. All CDN-served photos will show as plain text, breaking `<img>` tags.
- **Using DATABASE_URL port 6543 (pooler) for Supabase Python client:** The existing `utils.py` note applies to psycopg2. The supabase-py client uses the REST/HTTP API, so this warning does not apply to it — use the project URL (not the database URL) for `SUPABASE_URL`.
- **Putting SUPABASE_SERVICE_KEY in git:** This key has full bypass of all RLS — treat like a root password. Add to `.env.local` only, never commit.
- **Hard-coding LA County city lists in Python:** Defeats the PIPE-04 requirement. All city/region data goes in `pipeline_config.json`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Image upload to CDN | Custom multipart/form-data upload | `supabase.storage.from_().upload()` | Handles auth headers, retry, MIME negotiation |
| Public URL construction | String concatenation of project URL + bucket + path | `supabase.storage.from_().get_public_url()` | URL format may change; SDK always returns correct stable URL |
| MIME type detection | Custom extension-to-MIME map | `mimetypes.guess_type()` (stdlib) as fallback | stdlib covers all common formats |
| Database schema migration | Manual `ALTER TABLE` SQL scripts | GORM AutoMigrate | Project already uses AutoMigrate; manual DDL creates drift risk |

**Key insight:** GORM AutoMigrate only ADDS columns — it never drops or modifies existing ones. This makes it safe for incremental column additions but means removed fields from structs leave orphaned columns in the database (not a problem here).

---

## Common Pitfalls

### Pitfall 1: Content-Type Defaulting to text/plain
**What goes wrong:** Image is uploaded as `text/plain`, CDN serves it with wrong MIME type, browser refuses to render it as an image.
**Why it happens:** The `supabase-py` storage client explicitly documents: "If no mimetype is specified, it defaults to `text/plain`." This is a silent failure — the upload succeeds (200 OK), but the served file is corrupt from the CDN's perspective.
**How to avoid:** Always pass `{"content-type": "image/jpeg"}` (or appropriate MIME) in the file_options dict. The `upload_photo_to_storage()` wrapper in utils.py enforces this.
**Warning signs:** Images upload without error but appear as broken `<img>` tags in the frontend.

### Pitfall 2: Service Key vs Anon Key Confusion
**What goes wrong:** Scripts use the anon key (public key), which is subject to RLS. If no INSERT policy exists for anon users, uploads fail with 403.
**Why it happens:** Supabase projects have two common client keys — anon key (public, subject to RLS) and service role key (bypasses all RLS). Scripts must use the service role key.
**How to avoid:** Env var is named `SUPABASE_SERVICE_KEY` (not `SUPABASE_ANON_KEY`) to make this explicit. Service keys bypass RLS — no INSERT policy needed for scripts.
**Warning signs:** Upload returns `{ "error": "new row violates row-level security policy" }`.

### Pitfall 3: GORM AutoMigrate Skips Existing Struct Fields Needing Type Changes
**What goes wrong:** If a column already exists with a different type, AutoMigrate will NOT alter the column type — it only adds missing columns.
**Why it happens:** GORM AutoMigrate is additive-only by design.
**How to avoid:** `photo_license` and `term_date_precision` are new columns on existing tables — there is no existing column to conflict with. `building_photos` is a new table. No type-change risk in this phase.
**Warning signs:** Not applicable for this phase (all additions, no modifications).

### Pitfall 4: Bucket Public Setting vs RLS Policies
**What goes wrong:** Creating an RLS SELECT policy for anonymous reads but not setting `public: true` on the bucket. Results in missing CDN acceleration (files served as authenticated, not cached by CDN edge nodes).
**Why it happens:** Supabase Storage has two separate layers: the `public` field on the bucket record, and RLS policies on `storage.objects`. Setting `public: true` on the bucket enables CDN caching and unauthenticated access without needing an RLS policy.
**How to avoid:** Create bucket with `public: true`. Service key bypasses RLS for uploads. The bucket's public setting handles read access.
**Warning signs:** Files are accessible but CDN hit rate is low; download URLs require auth tokens.

### Pitfall 5: PoliticianContact Lacks Composite Unique Constraint (Pre-Existing Risk)
**What goes wrong:** Phase 41 contact upserts cannot use ON CONFLICT because `politician_contacts` has no composite unique constraint. This is a pre-existing issue flagged in STATE.md.
**Why it happens:** The `PoliticianContact` model has only an index on `politician_id`, not a composite unique constraint on `(politician_id, source, contact_type)`.
**How to avoid:** Phase 39 is the right time to add this constraint to `models.go` before Phase 41 runs contact upserts. Add composite unique index:
```go
type PoliticianContact struct {
    // ... existing fields ...
    PoliticianID uuid.UUID `json:"politician_id" gorm:"type:uuid;index:idx_pol_contact_unique,unique"`
    Source       string    `json:"source"       gorm:"index:idx_pol_contact_unique,unique"` // "person" or "officeholder"
    ContactType  string    `json:"contact_type" gorm:"index:idx_pol_contact_unique,unique"` // "district", "capitol", etc.
}
```
AutoMigrate will create the index. **Note: decide whether this constraint fits the data model** — if a politician can have multiple contacts with the same source+type (e.g., two district phones), it should not be unique.
**Warning signs:** Phase 41 upsert scripts produce duplicate contact rows on re-run.

### Pitfall 6: External ID Counter Range for v1.7 Scripts
**What goes wrong:** New v1.7 import scripts use the same `next_ext_id()` from utils.py, which starts at -200001 on process launch. If v1.6 scripts already consumed IDs below -200001, the v1.7 range overlaps.
**Why it happens:** `init_ext_id_counter()` in `scrape_city_councils.py` queries the DB minimum and resets the counter, but this only runs if explicitly called. Other scripts that just call `from utils import next_ext_id` without `init_ext_id_counter()` will get values starting at -200001 again.
**How to avoid:** All v1.7 scripts MUST call `init_ext_id_counter()` at startup (as `scrape_city_councils.py` already does), OR the v1.7 range should be established as a documented range in utils.py (e.g., -300001 and below for v1.7).
**Warning signs:** Unique constraint violations on `external_id` during v1.7 imports.

---

## Code Examples

Verified patterns from official sources:

### Upload Image with Explicit Content-Type and Upsert
```python
# Source: https://supabase.com/docs/reference/python/storage-from-upload
# Source: https://github.com/supabase/storage-py/blob/main/README.md (content-type warning)

# Download image bytes first
import requests
response = requests.get(photo_url, timeout=15)
response.raise_for_status()
image_bytes = response.content  # raw bytes, NOT base64

# Upload to Supabase Storage
storage_path = f"la_county/supervisors/{politician_id}.jpg"
supabase_client.storage.from_("politician-photos").upload(
    storage_path,
    image_bytes,
    {"content-type": "image/jpeg", "upsert": "true"}
)

# Get stable public CDN URL
# Source: https://supabase.com/docs/reference/python/storage-from-getpublicurl
cdn_url = supabase_client.storage.from_("politician-photos").get_public_url(storage_path)
# Returns: https://{project_id}.supabase.co/storage/v1/object/public/politician-photos/la_county/supervisors/{id}.jpg
```

### Creating Supabase Client with Service Key (Python)
```python
# Source: https://github.com/supabase/supabase-py/blob/main/src/supabase/README.md

from supabase import create_client, Client

# SUPABASE_URL: the project URL (e.g., https://xxxx.supabase.co)
# SUPABASE_SERVICE_KEY: service role key from Project Settings > API
# Note: NOT the DATABASE_URL used by psycopg2 — different credential entirely
supabase: Client = create_client(
    os.environ["SUPABASE_URL"],
    os.environ["SUPABASE_SERVICE_KEY"]
)
```

### GORM: Adding New Table with place_geoid Primary Key
```go
// Source: established GORM pattern in internal/essentials/models.go
// place_geoid is a string primary key (not UUID) because it's the Census GEOID
// e.g., "0644000" for City of Los Angeles
type BuildingPhoto struct {
    PlaceGeoid  string    `json:"place_geoid" gorm:"primaryKey;size:20"`
    URL         string    `json:"url"`
    SourceURL   string    `json:"source_url"`
    License     string    `json:"license"`
    Attribution string    `json:"attribution"`
    WikiTitle   string    `json:"wiki_title"`
    FetchedAt   time.Time `json:"fetched_at"`
}

func (BuildingPhoto) TableName() string {
    return "essentials.building_photos"
}
```

### License Category Values (Discretion Applied)
```python
# Recommended license category values for photo_license column
# Track but don't block — all values accepted, no upload gating
LICENSE_CC_BY_SA = "cc_by_sa"           # Wikimedia Commons: Creative Commons Attribution-ShareAlike
LICENSE_CC_BY = "cc_by"                  # Creative Commons Attribution (no ShareAlike requirement)
LICENSE_CC0 = "cc0"                      # Public domain / no rights reserved
LICENSE_PRESS_USE = "press_use"          # Official press/government photo, usage rights implied
LICENSE_SCRAPED_NO_LICENSE = "scraped_no_license"  # No explicit license found; internal use only
LICENSE_PUBLIC_DOMAIN = "public_domain"  # Explicitly in public domain (US government works)
LICENSE_UNKNOWN = "unknown"              # License not determined
```

### Pipeline Config Structure (Discretion Applied: JSON over YAML)
```json
// scripts/pipeline_config.json
{
  "default_region": "la_county",
  "regions": {
    "la_county": {
      "state": "CA",
      "county_name": "Los Angeles County",
      "county_supervisor_url": "https://bos.lacounty.gov/board-of-supervisors/",
      "la_city_council_url": "https://clerk.lacity.gov/city-council/city-council-members",
      "cities": [
        {
          "id": "la_city",
          "name": "City of Los Angeles",
          "place_geoid": "0644000",
          "ocd_id_base": "ocd-division/country:us/state:ca/place:los_angeles"
        }
      ]
    }
  }
}
```
Scripts load: `config = json.load(open(config_path)); region = config["regions"][args.region]`

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Storing photo URLs from BallotReady (external hotlinks) | Re-hosting to Supabase Storage CDN | Phase 39 (v1.7) | Eliminates link rot risk from government website URLs breaking |
| No license tracking | `photo_license` column on `politician_images` | Phase 39 (v1.7) | Legal compliance tracking before any scraping at scale |
| No term date precision | `term_date_precision` on `politicians` | Phase 39 (v1.7) | Prevents "Jan 2024" display when only year is known |
| No building photos | `building_photos` table with `place_geoid` PK | Phase 39 (v1.7) | Supports Phase 41 Wikimedia city hall photo import |

**Deprecated/outdated:**
- Cicero API: replaced by BallotReady in v1.5; existing `CICERO_KEY` in `.env.local` is unused by current scripts
- Hotlinking photos from BallotReady URLs: superseded by Supabase Storage re-hosting

---

## Open Questions

1. **PoliticianContact composite unique constraint**
   - What we know: No composite unique index exists; STATE.md flags this as a pre-planning concern for Phase 41
   - What's unclear: Whether a politician can legitimately have multiple contacts with the same (source, contact_type) — e.g., two "district" phone numbers
   - Recommendation: Review data from BallotReady Phase B implementation before adding the constraint. If not needed in Phase 39, document the decision for Phase 41's planner.

2. **Supabase Service Key env var name**
   - What we know: Supabase dashboard calls this the "service_role" key; common env var names include `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_SERVICE_KEY`, `SUPABASE_KEY`
   - What's unclear: No existing convention in this project (supabase Python client not yet used)
   - Recommendation: Use `SUPABASE_SERVICE_KEY` (matches the pattern of other short env var names in `.env.local`)

3. **Supabase URL env var for scripts vs Go backend**
   - What we know: The Go backend uses `DATABASE_URL` (direct Postgres connection). Supabase-py uses the project REST URL (e.g., `https://xxxx.supabase.co`), which is a different value.
   - What's unclear: Whether `SUPABASE_URL` should be added to `.env.local` alongside `DATABASE_URL` or managed separately.
   - Recommendation: Add `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` to `.env.local` — scripts already read from the same file via `load_env()`.

4. **Bucket folder structure for politician photos**
   - What we know: Decision deferred to Claude's discretion; re-scrape should overwrite same path
   - Recommendation: `{region}/{entity_type}/{politician_id}.jpg` — e.g., `la_county/supervisors/abc123.jpg`, `la_county/la_city_council/def456.jpg`. This supports multi-region expansion (PIPE-04) and groups by entity type for easy bucket browsing.

5. **v1.7 External ID Range**
   - What we know: v1.5 used -100001 and below; v1.6 used -200001 and below
   - Recommendation: Establish v1.7 range as -300001 and below; update `_EXT_ID_COUNTER` in `utils.py` to `-300001` and document in comments. All v1.7 scripts must call `init_ext_id_counter()` at startup.

---

## Sources

### Primary (HIGH confidence)
- `/supabase/storage-py` (Context7) — upload pattern, content-type requirement, FileOptions definition
- `/supabase/supabase-py` (Context7) — create_client, upload with upsert, get_public_url
- `https://supabase.com/docs/reference/python/storage-from-upload` — official Python upload reference with upsert example
- `https://supabase.com/docs/reference/python/storage-from-getpublicurl` — official Python get_public_url reference
- `https://supabase.com/docs/guides/storage/uploads/standard-uploads` — content-type behavior documented (defaults to text/plain)
- `https://supabase.com/docs/guides/storage/buckets/creating-buckets` — public:true behavior documented
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/models.go` — existing GORM model patterns
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/setup.go` — existing AutoMigrate pattern
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/utils.py` — existing env loading and ext_id counter patterns
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/requirements.txt` — current Python dependencies

### Secondary (MEDIUM confidence)
- `https://supabase.com/docs/guides/storage/security/access-control` — service key bypasses RLS; public bucket vs RLS policy distinction
- `https://pypi.org/project/supabase/` — current version 2.28.0 confirmed via WebSearch

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — supabase-py is official, well-documented, Context7 verified; GORM pattern is codebase-confirmed
- Architecture: HIGH — all patterns drawn from existing codebase conventions + official Supabase docs
- Pitfalls: HIGH — content-type pitfall explicitly documented in official storage-py README; PoliticianContact constraint gap confirmed by direct model inspection

**Research date:** 2026-02-24
**Valid until:** 2026-04-24 (supabase-py is stable; core upload API unlikely to change)
