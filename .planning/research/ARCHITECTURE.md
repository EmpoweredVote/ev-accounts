# Architecture Research

**Domain:** Civic tech — politician data enrichment pipeline (headshots, building photos, contact/term data, bios, education, experience) for ~389 LA County officials (v1.7)
**Researched:** 2026-02-24
**Confidence:** HIGH — based on direct source inspection of all relevant backend files, Python scripts, frontend components, and existing pipeline conventions

---

## System Overview

The v1.7 enrichment milestone adds data to existing politician records — it does not change the request path or the geofence lookup chain. The pipeline reads from authoritative sources (government websites, Wikimedia Commons, public records), writes enriched data into existing database tables, and the existing API and frontend consume it automatically via fields already in the schema.

The architecture has three distinct layers: the enrichment pipeline (offline Python scripts), the database (existing tables with existing columns), and the read path (unchanged Go API + React frontend).

```
┌─────────────────────────────────────────────────────────────────────┐
│            ENRICHMENT PIPELINE (offline, runs locally)               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐   │
│  │ City/County       │  │ Wikimedia Commons │  │ Public Records   │   │
│  │ Government Sites  │  │ (building photos) │  │ (term/bio data)  │   │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘   │
│           │                     │                      │              │
│           ▼                     ▼                      ▼              │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │               scrape_headshots.py  (NEW)                     │   │
│  │  - Reads politician_sources.json for per-city config         │   │
│  │  - Fetches headshot URL from each source's roster page       │   │
│  │  - Matches politician by full_name (seat-first dedup)        │   │
│  │  - UPDATEs photo_origin_url on politicians table             │   │
│  │  - Inserts into politician_images (type="default")           │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │               scrape_building_photos.py  (NEW)               │   │
│  │  - Reads city list from city_sources.json                    │   │
│  │  - Fetches Wikimedia Commons image URLs (CC-licensed)        │   │
│  │  - Writes to essentials.building_photos table  (NEW TABLE)   │   │
│  │  - Keyed on place_geoid (joins to geofence_boundaries)       │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │               enrich_contacts.py  (NEW)                      │   │
│  │  - Reads per-city config from politician_sources.json        │   │
│  │  - Scrapes office address, phone, email from roster pages    │   │
│  │  - UPSERTs into essentials.politician_contacts               │   │
│  │    (existing table, source='scraped')                        │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │               enrich_term_data.py  (NEW)                     │   │
│  │  - Reads term/election data from government sites or         │   │
│  │    public records (first elected, term end dates)            │   │
│  │  - UPDATEs politicians.valid_from, valid_to                  │   │
│  │  - May UPDATE politicians.total_years_in_office              │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │               enrich_bio_edu_exp.py  (NEW, optional)         │   │
│  │  - Scrapes bio text, education, work experience where avail  │   │
│  │  - UPDATEs politicians.bio_text                              │   │
│  │  - INSERTs into essentials.degrees, essentials.experiences   │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│              DATABASE (Supabase / PostgreSQL + PostGIS)               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  EXISTING TABLES (populated by enrichment pipeline):                │
│                                                                      │
│  essentials.politicians                                              │
│  ┌─────────────────┬──────────────────┬────────────────────────┐   │
│  │ photo_origin_url│ valid_from        │ valid_to               │   │
│  │ (scraped URL)   │ (term start date) │ (term end date)        │   │
│  │ bio_text        │ total_years_in_office                      │   │
│  └─────────────────┴──────────────────┴────────────────────────┘   │
│                                                                      │
│  essentials.politician_images  (existing — add headshot rows)        │
│  ┌──────────────┬──────────┬───────────────────────────────────┐   │
│  │ politician_id│ url      │ type ("default" or "thumb")       │   │
│  └──────────────┴──────────┴───────────────────────────────────┘   │
│                                                                      │
│  essentials.politician_contacts  (existing — add contact rows)       │
│  ┌──────────────┬────────┬────────┬────────┬──────────────────┐    │
│  │ politician_id│ email  │ phone  │ source │ contact_type     │    │
│  │              │        │        │"scraped"│"office"/"district"│   │
│  └──────────────┴────────┴────────┴────────┴──────────────────┘    │
│                                                                      │
│  essentials.degrees  (existing — add education rows)                 │
│  essentials.experiences  (existing — add work history rows)          │
│                                                                      │
│  NEW TABLE: essentials.building_photos                               │
│  ┌──────────────┬──────────────┬──────────────┬───────────────┐    │
│  │ id (uuid pk) │ place_geoid  │ photo_url    │ attribution   │    │
│  │              │ (e.g."0644000")│ (Wikimedia) │ (CC license) │    │
│  │ city_name    │ state        │ created_at   │               │    │
│  └──────────────┴──────────────┴──────────────┴───────────────┘    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (largely unchanged request path)
┌─────────────────────────────────────────────────────────────────────┐
│              EV-BACKEND (Go / Chi / GORM)                            │
│  internal/essentials/                                                │
│  ├── handlers.go      — GetPoliticianByID (minor: add contacts fetch)│
│  │   (minor edit: add PoliticianContact fetch step 8.5)             │
│  ├── handlers.go      — GetPoliticiansByAddress (UNCHANGED)          │
│  ├── routes.go        — add GET /cities/{geo_id}/building-photo (NEW)│
│  └── models.go        — add BuildingPhoto GORM model (NEW)           │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│              FRONTEND (essentials React app + ev-ui library)         │
│                                                                      │
│  essentials/src/pages/Profile.jsx                                    │
│  ├── Already renders: images[], degrees[], experiences[]             │
│  ├── Already renders: term_start/term_end via PoliticianProfile      │
│  ├── NEW: render contacts[] (office phone, email, address)           │
│                                                                      │
│  essentials/src/pages/Dashboard.jsx                                  │
│  ├── Already renders: building photos per tier (federal/state/local) │
│  ├── NEW: fetch building photo for city via /cities/{geo_id}/building │
│                                                                      │
│  ev-ui/src/PoliticianProfile.jsx                                     │
│  ├── Already has: getImageURL() with images[]/photo_origin_url logic │
│  ├── Already has: getTermLine() for valid_from/valid_to              │
│  ├── NEW: ContactSection component (phone, email, office address)    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Component Responsibilities

### Existing Components (unchanged or minor edit in v1.7)

| Component | Responsibility | v1.7 Change |
|-----------|---------------|-------------|
| `scrape_la_officials.py` | Config-driven scraper for LA County supervisors + LA City council/mayor; seat-first dedup; upserts politician records | Extend to also write photo_origin_url and politician_images when roster page includes headshots |
| `scrape_city_councils.py` | Batch scraper for 87 LA County cities; SOS PDF primary source; city website fallback | Extend to write photo_origin_url and politician_images when city site includes headshots |
| `politician_sources.json` | Per-source scraper config (URL, parser, ocd_id_template, district_type, title) | Add `photo_selector` field for per-source CSS selector or URL pattern for headshot extraction |
| `city_sources.json` | City list with SOS PDF roster, place_geoid, and city website URL | Add `building_photo_url` field for Wikimedia Commons URL of city hall image |
| `utils.py` | Shared load_env(), get_engine(), next_ext_id() utilities | No change |
| `essentials.politician_images` | Stores headshot URLs with type field ("default", "thumb") | New rows inserted by enrichment scripts |
| `essentials.politician_contacts` | Stores contact info; already has source, email, phone, contact_type fields | New rows inserted by enrich_contacts.py; source='scraped' |
| `essentials.politicians` | Core politician records with photo_origin_url, valid_from, valid_to, bio_text, total_years_in_office | Fields updated by enrichment scripts |
| `GetPoliticianByID` (handlers.go) | Returns full profile including images[], degrees[], experiences[]; currently steps 1-7 fetch associated data | Add step 8.5: fetch politician_contacts for this politician_id; add to profile response |
| `PoliticianProfile.jsx` (ev-ui) | Renders profile card, term dates (getTermLine), images (getImageURL with images[]/photo_origin_url fallback) | Add ContactSection render block; publish new ev-ui version |

### New Components (v1.7)

| Component | File | Responsibility |
|-----------|------|---------------|
| Headshot scraper | `EV-Backend/scripts/scrape_headshots.py` | Targeted scraper focused only on headshot URL extraction; reads politician_sources.json + city_sources.json; updates existing politician records |
| Building photo scraper | `EV-Backend/scripts/scrape_building_photos.py` | Fetches Wikimedia Commons URLs for 89 LA County city halls; inserts/updates building_photos table |
| Contact enrichment script | `EV-Backend/scripts/enrich_contacts.py` | Scrapes contact info (office phone, email, office address) from government websites; upserts into politician_contacts |
| Term data enrichment script | `EV-Backend/scripts/enrich_term_data.py` | Reads elected dates and term end dates from public records; updates politicians.valid_from, valid_to |
| Bio/edu/exp enrichment script | `EV-Backend/scripts/enrich_bio_edu_exp.py` | Scrapes bio text, education history, work experience where available; writes to bio_text, degrees, experiences |
| BuildingPhoto GORM model | `EV-Backend/internal/essentials/models.go` | New struct with TableName() = "essentials.building_photos" |
| Building photo endpoint | `EV-Backend/internal/essentials/handlers.go` | GET /cities/{geo_id}/building-photo — returns photo_url + attribution for a city |
| Building photo route | `EV-Backend/internal/essentials/routes.go` | Register GET /cities/{geo_id}/building-photo |
| Building photo migration | `EV-Backend/internal/essentials/setup.go` | AutoMigrate(&BuildingPhoto{}) — creates table |
| ContactSection (frontend) | `ev-ui/src/PoliticianProfile.jsx` | Renders contact info (phone, email, office address) on profile page |

---

## Recommended Project Structure

```
EV-Backend/
├── scripts/
│   ├── politician_sources.json     # MODIFIED — add photo_selector field
│   ├── city_sources.json           # MODIFIED — add building_photo_url field per city
│   ├── utils.py                    # UNCHANGED
│   ├── scrape_la_officials.py      # UNCHANGED (or minor headshot extension)
│   ├── scrape_city_councils.py     # UNCHANGED (or minor headshot extension)
│   ├── scrape_headshots.py         # NEW — headshot URL extraction for ~389 officials
│   ├── scrape_building_photos.py   # NEW — building photo URL collection for 89 cities
│   ├── enrich_contacts.py          # NEW — phone/email/address per official
│   ├── enrich_term_data.py         # NEW — valid_from/valid_to per official
│   └── enrich_bio_edu_exp.py       # NEW — bio_text/degrees/experiences (optional)
└── internal/
    └── essentials/
        ├── models.go               # MINOR ADD — BuildingPhoto struct
        ├── setup.go                # MINOR ADD — AutoMigrate(&BuildingPhoto{})
        ├── handlers.go             # MINOR EDIT — contacts fetch in GetPoliticianByID
        │                          #            — GetBuildingPhoto handler (NEW)
        ├── routes.go               # MINOR ADD — GET /cities/{geo_id}/building-photo
        └── [all other files]       # UNCHANGED

ev-ui/
└── src/
    └── PoliticianProfile.jsx       # MINOR ADD — ContactSection render block
                                    # (publish new ev-ui version after change)

essentials/
└── src/
    └── pages/
        └── Dashboard.jsx           # MINOR EDIT — fetch + display building photo per city
```

### Structure Rationale

- **Separate scripts per concern:** Each enrichment script (headshots, building photos, contacts, term data, bio/edu/exp) is independent. They can be run in any order and re-run safely without side effects. This matches the existing pattern from v1.6 (separate `scrape_la_officials.py`, `scrape_city_councils.py`, `scrape_school_boards.py`).
- **Config extension rather than new config files:** Adding `photo_selector` to `politician_sources.json` and `building_photo_url` to `city_sources.json` keeps configs co-located with the scraper that reads them. Avoids proliferating config files.
- **One new DB table only (`building_photos`):** All other enrichment data goes into existing columns (photo_origin_url, valid_from, valid_to, bio_text) or existing tables (politician_images, politician_contacts, degrees, experiences). The building_photos table is genuinely new because no existing table captures city-level building image metadata.
- **Minor Go backend changes:** The enrichment pipeline writes directly to the DB via Python. The Go API only needs: (1) contacts added to the GetPoliticianByID response, (2) one new endpoint for building photos. No structural changes to the handler architecture.
- **ev-ui publish required:** ContactSection is new UI that goes in the shared component library. Any ev-ui change requires a version bump and publish to GitHub npm registry, then version update in essentials and CompassV2.

---

## Architectural Patterns

### Pattern 1: Politician-ID-Keyed Upsert for Enrichment Data

**What:** All enrichment scripts find the target `politician.id` first (by matching full_name + district/seat, using the same seat-first dedup logic from `scrape_la_officials.py`), then write enrichment data using that UUID as the foreign key. For `politician_contacts` and `politician_images`, the pattern is DELETE-where-source='scraped' + INSERT for the current scrape, making re-runs safe.

**When to use:** Every write to `politician_contacts`, `politician_images`, `degrees`, `experiences`. Never insert blindly without first resolving the politician_id.

**Trade-offs:** Requires the same seat-first dedup logic that already exists in `scrape_la_officials.py`. Rather than duplicating this logic, enrichment scripts should import the `find_existing_politician_for_seat()` function from `scrape_la_officials.py` (or extract it to `utils.py` as a shared helper).

**Example:**
```python
# Shared pattern: resolve politician_id before writing enrichment data
pol_id, match_type = find_existing_politician_for_seat(
    cur, ocd_id, title, scraped_name
)
if pol_id and match_type in ("exact", "fuzzy"):
    # Safe to write enrichment data for this politician_id
    cur.execute("""
        DELETE FROM essentials.politician_contacts
        WHERE politician_id = %s AND source = 'scraped'
    """, (pol_id,))
    cur.execute("""
        INSERT INTO essentials.politician_contacts
            (id, politician_id, source, email, phone, contact_type)
        VALUES (%s, %s, 'scraped', %s, %s, 'office')
    """, (str(uuid.uuid4()), pol_id, scraped_email, scraped_phone))
```

### Pattern 2: photo_origin_url for Headshots (Existing Field, No New Table)

**What:** The `politicians.photo_origin_url` field already exists and is served by the API via the `photo_origin_url` field in `OfficialOut`. The `PoliticianProfile` component already has `getImageURL()` logic that prefers `images[]` (from BallotReady) and falls back to `photo_origin_url`. For scraped officials (data_source='scraped'), `images[]` will be empty — so writing to `photo_origin_url` is sufficient for the card and profile to show the headshot.

Optionally, also insert into `politician_images` with type="default" to be consistent with BallotReady records and enable the `images[]` array pathway. This is the cleaner approach.

**When to use:** For all ~389 LA County officials. Prefer the dual write (photo_origin_url + politician_images) so the frontend getImageURL() logic works identically regardless of data source.

**Trade-offs:** `photo_origin_url` stores the scraped government site URL directly (no re-hosting). The v1.6 source comment in `scrape_la_officials.py` acknowledges this: "Photo re-hosting to Supabase Storage is planned but deferred." This remains out of scope for v1.7 per PROJECT.md.

**Example:**
```python
# Dual write: photo_origin_url + politician_images
cur.execute("""
    UPDATE essentials.politicians
    SET photo_origin_url = %s, last_synced = NOW()
    WHERE id = %s AND (photo_origin_url IS NULL OR photo_origin_url = '')
""", (scraped_photo_url, pol_id))

# Also insert into politician_images (delete-recreate if already exists)
cur.execute("""
    DELETE FROM essentials.politician_images
    WHERE politician_id = %s AND type = 'default'
""", (pol_id,))
cur.execute("""
    INSERT INTO essentials.politician_images (id, politician_id, url, type)
    VALUES (%s, %s, %s, 'default')
""", (str(uuid.uuid4()), pol_id, scraped_photo_url))
```

### Pattern 3: Config-Driven Source Declaration for Photo/Contact Data

**What:** Rather than hardcoding per-city scraping logic in Python, store per-source metadata in `politician_sources.json` (for supervisors/LA city) and `city_sources.json` (for 87 other cities). The v1.6 scraping scripts already read these configs. For v1.7, add new fields to the existing configs:

For `politician_sources.json`:
```json
{
  "id": "la_county_supervisors",
  "photo_selector": "img.supervisor-photo",
  "contact_fields": {"phone": ".phone-number", "email": "a[href^='mailto:']"}
}
```

For `city_sources.json`:
```json
{
  "place_geoid": "0644000",
  "city": "Los Angeles",
  "building_photo_url": "https://commons.wikimedia.org/wiki/Special:FilePath/Los_Angeles_City_Hall_2013.jpg",
  "building_photo_attribution": "Photo: Carol Highsmith, Public Domain"
}
```

**When to use:** Every new data type that requires per-source configuration. Avoids hardcoding selectors or URLs in Python.

**Trade-offs:** Some sources will not have machine-parseable headshots (Cloudflare-protected sites, no consistent DOM structure) — these fall back to hardcoded URLs or remain empty. The config should include a `photo_url_override` for this case, matching the existing `hardcoded fallback` pattern.

### Pattern 4: Building Photo as City-Level Record (New Table)

**What:** Building photos are city-level, not politician-level. They belong to a city (keyed by `place_geoid`) rather than to any individual politician. The `building_photos` table is new because no existing table captures this.

The Dashboard already displays building photos by tier (federal = Capitol building, state = Capitol, local = city hall). Currently these are hardcoded in the frontend for the cities that have been manually configured. The new table enables dynamic lookup.

**Schema:**
```go
type BuildingPhoto struct {
    ID          uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    PlaceGeoID  string    `gorm:"uniqueIndex"` // Census GEOID e.g. "0644000" for LA City
    CityName    string
    State       string
    PhotoURL    string
    Attribution string    // CC license attribution text
    CreatedAt   time.Time
}

func (BuildingPhoto) TableName() string {
    return "essentials.building_photos"
}
```

**API endpoint:**
```
GET /essentials/cities/{geo_id}/building-photo
→ { photo_url: "...", attribution: "...", city_name: "..." }
```

**Frontend usage:** Dashboard fetches building photo for the user's city after address lookup resolves, replaces the static hardcoded building image with the dynamic response.

**When to use:** This approach works for all 89 LA County cities in v1.7. For future regional expansion, the same table and endpoint cover any city where a building photo has been curated.

**Trade-offs:** Requires a Wikimedia Commons research pass (one URL per city hall). ~89 lookups, manual or semi-automated via Wikimedia API. Not every city hall will have a high-quality Wikimedia Commons image — these get no image or a generic fallback.

---

## Data Flow

### Enrichment Pipeline Data Flow (offline, developer runs locally)

```
Developer runs: python3 scrape_headshots.py
    ↓
Read politician_sources.json + city_sources.json
    ↓
For each source:
    Fetch roster HTML (requests + BeautifulSoup)
    Parse official names + headshot URLs
    For each official:
        find_existing_politician_for_seat(cur, ocd_id, title, name)
            → politician_id (UUID)
        UPDATE politicians SET photo_origin_url = ... WHERE id = politician_id
        DELETE FROM politician_images WHERE politician_id = ... AND type = 'default'
        INSERT INTO politician_images (politician_id, url, type='default')
    Commit per-source (not global transaction — follows scrape_city_councils.py convention)
    ↓
Print coverage report: N headshots found out of M officials
```

```
Developer runs: python3 scrape_building_photos.py
    ↓
Read city_sources.json
    ↓
For each city with building_photo_url field:
    INSERT INTO essentials.building_photos (place_geoid, city_name, photo_url, attribution)
    ON CONFLICT (place_geoid) DO UPDATE SET photo_url = EXCLUDED.photo_url
    ↓
Print: N city hall photos inserted/updated
```

```
Developer runs: python3 enrich_contacts.py
    ↓
For each source in politician_sources.json:
    Fetch roster HTML
    Parse contact fields (phone, email, office address)
    For each official:
        find_existing_politician_for_seat() → politician_id
        DELETE FROM politician_contacts WHERE politician_id = ... AND source = 'scraped'
        INSERT INTO politician_contacts (politician_id, source='scraped', phone, email, contact_type)
    Commit per-source
    ↓
Print: N contact records written
```

### Profile Page Read Flow (existing, unchanged except contacts addition)

```
User clicks politician card → navigate to /politician/{id}
    ↓
GET /essentials/politician/{id}
    ↓
GetPoliticianByID handler:
    Step 1: SELECT ... FROM politicians JOIN offices JOIN districts JOIN chambers JOIN governments
    Step 2: SELECT * FROM addresses WHERE politician_id = ?
    Step 3: SELECT * FROM identifiers WHERE politician_id = ?
    Step 4: SELECT name, position, urls FROM committees JOIN politician_committees
    Step 5: SELECT * FROM politician_images WHERE politician_id = ?     [headshots from pipeline]
    Step 6: SELECT * FROM degrees WHERE politician_id = ?               [from pipeline]
    Step 7: SELECT * FROM experiences WHERE politician_id = ?           [from pipeline]
    Step 8.5 (NEW): SELECT * FROM politician_contacts WHERE politician_id = ?
    ↓
Assemble PoliticianProfileOut (add contacts[] field)
    ↓
PoliticianProfile.jsx renders:
    - getImageURL(): images[0].url → photo_origin_url (headshot from pipeline)
    - getTermLine(): valid_from → valid_to (term dates from pipeline)
    - ContactSection (NEW): contacts[].phone, contacts[].email, contacts[].contact_type
    - degrees[]: education section (from pipeline)
    - experiences[]: work history section (from pipeline)
    - bio_text: biography (from pipeline)
```

### Building Photo Read Flow (new)

```
User address search → geofence results → Dashboard resolves city geo_id from G4110 match
    ↓
GET /essentials/cities/{place_geoid}/building-photo
    ↓
GetBuildingPhoto handler:
    SELECT photo_url, attribution, city_name FROM essentials.building_photos WHERE place_geoid = ?
    → { photo_url: "https://commons.wikimedia.org/...", attribution: "...", city_name: "..." }
    ↓
Dashboard replaces placeholder building image with fetched URL
```

---

## Integration Points

### Existing Tables Used by Pipeline (no schema changes needed)

| Table | Fields Written | Notes |
|-------|----------------|-------|
| `essentials.politicians` | `photo_origin_url`, `valid_from`, `valid_to`, `bio_text`, `total_years_in_office` | All columns exist; enrichment scripts write via UPDATE WHERE id = ? |
| `essentials.politician_images` | `politician_id`, `url`, `type` | Existing table; DELETE + INSERT pattern (same as BallotReady upsert in handlers.go) |
| `essentials.politician_contacts` | `politician_id`, `source`, `email`, `phone`, `fax`, `contact_type` | Existing table; source='scraped'; DELETE WHERE source='scraped' + INSERT pattern |
| `essentials.degrees` | `politician_id`, `degree`, `major`, `school`, `grad_year` | Existing table; delete + recreate |
| `essentials.experiences` | `politician_id`, `title`, `organization`, `type`, `start`, `end` | Existing table; delete + recreate |

### New Table

| Table | Fields | Unique Key | Notes |
|-------|--------|------------|-------|
| `essentials.building_photos` | `id`, `place_geoid`, `city_name`, `state`, `photo_url`, `attribution`, `created_at` | `place_geoid` | Keyed on Census GEOID for incorporated places (G4110 MTFCC); matches geofence_boundaries.geo_id for city-level records |

### Go API Changes (internal boundaries)

| Boundary | Change | Scope |
|----------|--------|-------|
| `GetPoliticianByID` (handlers.go) | Add step 8.5: fetch politician_contacts; add `Contacts []ContactOut` to `PoliticianProfileOut` | ~15 lines; one new SELECT + mapping |
| `PoliticianProfileOut` (handlers.go) | Add `Contacts []ContactOut` field | 1 line; backward-compatible (omitempty) |
| New handler `GetBuildingPhoto` (handlers.go) | SELECT from building_photos WHERE place_geoid = ?; return JSON | ~20 lines |
| `routes.go` | `r.Get("/cities/{geo_id}/building-photo", GetBuildingPhoto)` | 1 line |
| `models.go` | Add `BuildingPhoto` struct with TableName() | ~10 lines |
| `setup.go` | Add `db.DB.AutoMigrate(&BuildingPhoto{})` | 1 line |

### Frontend Changes (ev-ui + essentials app)

| Component | Change | Scope |
|-----------|--------|-------|
| `PoliticianProfile.jsx` (ev-ui) | Add ContactSection render block that displays contacts[]; conditionally show if contacts non-empty | ~30 lines; requires ev-ui version bump + publish |
| `essentials/src/pages/Dashboard.jsx` | After address search resolves city geo_id, fetch building photo and pass to building image slot | ~15 lines; no ev-ui publish needed |

### External Services

| Service | How Used | Notes |
|---------|----------|-------|
| Government websites (bos.lacounty.gov, clerk.lacity.gov, city sites) | Headshot + contact scraping | Same sites already used by v1.6 scrapers; browser User-Agent required; hardcoded fallbacks for Cloudflare-blocked sites |
| Wikimedia Commons | City hall building photo URLs (cc-licensed) | Use Special:FilePath redirect for stable URLs; verify CC license before adding; ~89 manual lookups |
| Public records (county registrar, city clerks) | Term/election date data | Variable structure; may require manual research for some cities |

---

## New vs Modified Components

### New (create from scratch)

| Component | File | Notes |
|-----------|------|-------|
| Headshot scraper | `EV-Backend/scripts/scrape_headshots.py` | Focused on photo_origin_url + politician_images; re-uses find_existing_politician_for_seat() |
| Building photo scraper | `EV-Backend/scripts/scrape_building_photos.py` | Reads city_sources.json; writes to building_photos table |
| Contact enrichment script | `EV-Backend/scripts/enrich_contacts.py` | Reads politician_sources.json + city_sources.json; writes politician_contacts |
| Term data enrichment script | `EV-Backend/scripts/enrich_term_data.py` | Writes politicians.valid_from, valid_to |
| Bio/edu/exp enrichment script | `EV-Backend/scripts/enrich_bio_edu_exp.py` | Lowest priority; skip if no machine-readable sources found |
| BuildingPhoto model | `EV-Backend/internal/essentials/models.go` (addition) | Go struct + TableName() |
| GetBuildingPhoto handler | `EV-Backend/internal/essentials/handlers.go` (addition) | ~20 lines |
| Building photo route | `EV-Backend/internal/essentials/routes.go` (addition) | 1 line |

### Modified (targeted changes to existing files)

| Component | File | Change | Scope |
|-----------|------|--------|-------|
| politician_sources.json | `EV-Backend/scripts/politician_sources.json` | Add `photo_selector` and `contact_fields` fields per source | 3-4 lines per source |
| city_sources.json | `EV-Backend/scripts/city_sources.json` | Add `building_photo_url` and `building_photo_attribution` per city | 2 lines per city |
| PoliticianProfileOut | `EV-Backend/internal/essentials/handlers.go` | Add `Contacts []ContactOut` field | 1 line |
| GetPoliticianByID | `EV-Backend/internal/essentials/handlers.go` | Add contacts fetch (step 8.5) | ~15 lines |
| setup.go | `EV-Backend/internal/essentials/setup.go` | Add AutoMigrate(&BuildingPhoto{}) | 1 line |
| PoliticianProfile.jsx | `ev-ui/src/PoliticianProfile.jsx` | Add ContactSection render block | ~30 lines; new ev-ui version |
| Dashboard.jsx | `essentials/src/pages/Dashboard.jsx` | Fetch + display building photo | ~15 lines |

### Kept Unchanged

| Component | Why |
|-----------|-----|
| geofence_lookup.go | Lookup logic is correct as-is; enrichment data doesn't affect geofences |
| FindGeoIDsByPoint() | No change to spatial query |
| FindPoliticiansByGeoMatches() | No change to join logic |
| SearchPoliticians handler | No change to address search path |
| scrape_la_officials.py | Core upsert/dedup logic intact; headshot extraction is additive |
| scrape_city_councils.py | Same; dedup logic intact |
| promote_scraped_officials.py | v1.5 script; no v1.7 changes |
| All geofence import scripts | v1.6 scripts; no v1.7 changes |
| CompassV2 | No politician data display; unaffected |

---

## Build Order (dependency-aware)

Dependencies flow: schema → pipeline scripts → coverage verification → API changes → frontend changes.

### Step 1: Schema Migration (blocking for all pipeline scripts)

Add `building_photos` table:

```go
// models.go — add this struct
type BuildingPhoto struct {
    ID          uuid.UUID `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
    PlaceGeoID  string    `gorm:"uniqueIndex"`
    CityName    string
    State       string
    PhotoURL    string
    Attribution string
    CreatedAt   time.Time
}

func (BuildingPhoto) TableName() string {
    return "essentials.building_photos"
}
```

```go
// setup.go — add one line to AutoMigrate call
db.DB.AutoMigrate(&BuildingPhoto{})
```

Run `go run .` to apply migration. Verify table exists in Supabase.

All other enrichment data goes into existing tables — no additional schema changes needed.

### Step 2: Headshot Pipeline (parallel-capable, highest impact)

Build and run `scrape_headshots.py`. This is the highest-value step: headshots are the most visible enrichment on politician cards. Target: 80%+ of ~389 officials.

Sub-steps:
1. Audit `politician_sources.json` for each source: fetch the roster page, determine which HTML element contains the headshot (CSS selector or URL pattern)
2. Add `photo_selector` field to each source config
3. For city_sources.json: add `headshot_base_url` or `photo_selector` per city where photos are accessible
4. Run scrape_headshots.py
5. Query coverage: `SELECT COUNT(*) FROM essentials.politicians WHERE (photo_origin_url IS NOT NULL AND photo_origin_url != '') AND data_source IN ('scraped') AND state = 'CA'`

### Step 3: Building Photo Pipeline (independent, can run in parallel with Step 2)

Research Wikimedia Commons URLs for 89 LA County city halls. This is manual/semi-automated.

1. Add `building_photo_url` + `building_photo_attribution` to city_sources.json for each city
2. Run `scrape_building_photos.py` to populate `building_photos` table
3. Verify: `SELECT COUNT(*) FROM essentials.building_photos WHERE state = 'CA'`

### Step 4: Contact Enrichment (depends on Step 1 only, independent of Steps 2-3)

1. Run `enrich_contacts.py`
2. Verify: `SELECT COUNT(*) FROM essentials.politician_contacts WHERE source = 'scraped'`
3. Spot-check: confirm phone/email populated for known officials

### Step 5: Term Data Enrichment (independent)

1. Run `enrich_term_data.py`
2. Verify: `SELECT COUNT(*) FROM essentials.politicians WHERE valid_from IS NOT NULL AND valid_from != '' AND data_source = 'scraped'`

### Step 6: Bio/Education/Experience Enrichment (optional, lowest priority)

Run only for sources that have machine-readable bio/edu/exp data. Many city council websites will not have this. This step is explicitly lower priority than headshots and contacts.

### Step 7: Go API Changes (depends on Steps 1-6 being populated, can be done in parallel)

1. Add `ContactOut` DTO and `contacts []ContactOut` to `PoliticianProfileOut`
2. Add contacts fetch (step 8.5) to `GetPoliticianByID`
3. Add `GetBuildingPhoto` handler and register route
4. Test: `curl https://api.empowered.vote/essentials/politician/{id}` — verify contacts[] populated
5. Test: `curl https://api.empowered.vote/essentials/cities/0644000/building-photo` — verify response

### Step 8: Frontend Changes (depends on Step 7 Go API changes)

1. Add `ContactSection` to `ev-ui/src/PoliticianProfile.jsx`
2. Bump ev-ui version, publish to GitHub npm registry
3. Update ev-ui version in essentials/ and CompassV2/ package.json
4. Add building photo fetch to `essentials/src/pages/Dashboard.jsx`
5. Test profile page: contacts visible for LA County officials
6. Test dashboard: city hall photo appears for LA addresses

### Blocking Dependencies

```
Step 1 (schema migration)
  ↓
Steps 2, 3, 4, 5, 6  [all parallel — each is independent]
  ↓
Step 7 (Go API changes) — can start in parallel with Steps 2-6 using empty tables
  ↓
Step 8 (frontend changes) — requires Step 7 deployed
```

---

## Anti-Patterns

### Anti-Pattern 1: Separate Deduplication Logic in Each Enrichment Script

**What people do:** Copy-paste the seat-first dedup logic (ocd_id lookup → exact name match → fuzzy last-name match) into each new enrichment script.

**Why it's wrong:** The dedup logic already exists and was carefully validated in v1.6 (Levenshtein threshold=1, specific handling of "Jr." suffixes, supervisor district type=LOCAL not COUNTY). Duplicating it creates maintenance risk — one copy gets updated, others drift.

**Do this instead:** Extract `find_existing_politician_for_seat()` from `scrape_la_officials.py` into `utils.py`. All enrichment scripts import from utils. This is the v1.6 precedent (get_engine, next_ext_id already moved to utils.py when they were needed by multiple scripts).

### Anti-Pattern 2: Global Transaction for Multi-City Enrichment Run

**What people do:** Wrap the entire run (89 cities) in a single database transaction, so any one city failure rolls back all progress.

**Why it's wrong:** The v1.6 `scrape_city_councils.py` explicitly solved this with per-city commits: "Per-city COMMIT (not global transaction) — one failed city won't roll back all." A government website going down or returning unexpected HTML should not undo enrichment for the other 88 cities.

**Do this instead:** Follow the per-source commit pattern established in v1.6 — commit after each source/city, log failures, continue to the next source. This is directly documented in `scrape_city_councils.py`'s docstring.

### Anti-Pattern 3: Overwriting Existing High-Quality Data with Scraped Data

**What people do:** Unconditionally UPDATE `photo_origin_url` for all officials, replacing BallotReady-provided photos (which are professional headshots) with potentially lower-quality scraped government website photos.

**Why it's wrong:** ~389 LA County officials have `data_source = 'scraped'` and empty `photo_origin_url`. But some officials may already have photos from BallotReady (those imported via `promote_scraped_officials.py` with `match_confidence = 'exact'` or `'likely'`). Overwriting those with government site photos is a downgrade in photo quality.

**Do this instead:** Use a conditional UPDATE:
```sql
UPDATE essentials.politicians
SET photo_origin_url = %s
WHERE id = %s AND (photo_origin_url IS NULL OR photo_origin_url = '')
```
Only fill gaps; never overwrite existing photos. Same principle for `politician_images`: skip INSERT if a non-scraped image already exists for this politician.

### Anti-Pattern 4: Hardcoding Building Photo URLs in Frontend

**What people do:** Extend the existing hardcoded building photo configuration in `Dashboard.jsx` by adding 89 more `if/else` branches or a static map object.

**Why it's wrong:** The v1.1 building photo implementation was explicitly designed as temporary. The `building_photos` table solves this correctly: dynamic lookup, attributions stored with photos, reusable for future regional expansion.

**Do this instead:** Build the `building_photos` table + API endpoint (Step 1/3/7 above). The frontend makes one fetch per city. This is cleaner, attributions are tracked, and expansion to future regions requires only adding rows to the table — not frontend deploys.

### Anti-Pattern 5: Fetching External Images at Request Time

**What people do:** Add an API endpoint that proxies the government website image URL on each profile page load (to avoid cross-origin issues or CORS restrictions).

**Why it's wrong:** Government websites are unreliable, have aggressive rate limiting, and may block Render's IP ranges. Proxying images adds latency to every profile page load and creates a new failure mode on the hot path.

**Do this instead:** Store the URL in the database and have the browser fetch the image directly from the government site (or Wikimedia Commons). This is the current approach with `photo_origin_url` and it works. If cross-origin issues arise for specific sources, note them in the script and skip those sources rather than building a proxy.

---

## Scaling Considerations

| Scale | Architecture Notes |
|-------|-------------------|
| Current (v1.7, ~389 LA County officials) | All enrichment fits in existing schema; single-region scope; pipeline runs in minutes |
| Next region (e.g. Bloomington IN expansion) | Same scripts; add sources to politician_sources.json/city_sources.json; building_photos table already designed for multi-city; external_id counter already has dedicated ranges per milestone (v1.6 = -200001 range, v1.7 should use -300001 range) |
| All CA counties | Same pattern; city_sources.json grows to ~500 cities; enrichment scripts are idempotent so re-runs are safe; no Go API changes needed |

---

## Sources

- Direct source inspection: `EV-Backend/scripts/scrape_la_officials.py` — seat-first dedup, upsert logic, commit pattern, photo_origin_url precedent — HIGH confidence
- Direct source inspection: `EV-Backend/scripts/scrape_city_councils.py` — per-city commit pattern, city_sources.json structure, ext_id counter initialization — HIGH confidence
- Direct source inspection: `EV-Backend/scripts/utils.py` — v1.6 external ID range (-200001), get_engine(), load_env() — HIGH confidence
- Direct source inspection: `EV-Backend/scripts/politician_sources.json` — 3 existing sources, config structure — HIGH confidence
- Direct source inspection: `EV-Backend/internal/essentials/models.go` — Politician, PoliticianImage, PoliticianContact, Degree, Experience structs; all target fields confirmed present — HIGH confidence
- Direct source inspection: `EV-Backend/internal/essentials/handlers.go` — GetPoliticianByID steps 1-7, OfficialOut struct, PoliticianProfileOut structure, contacts not yet included in response — HIGH confidence
- Direct source inspection: `EV-Backend/internal/essentials/geofence_lookup.go` — mtfccToDistrictTypes, FindGeoIDsByPoint, FindPoliticiansByGeoMatches — HIGH confidence
- Direct source inspection: `ev-ui/src/PoliticianProfile.jsx` — getImageURL() (images[]/photo_origin_url), getTermLine() (valid_from/valid_to) — HIGH confidence
- Direct source inspection: `ev-ui/src/PoliticianCard.jsx` — imageSrc, name, title, subtitle props; no contacts rendering currently — HIGH confidence
- Direct source inspection: `.planning/PROJECT.md` — v1.7 milestone goal, out-of-scope items (photo re-hosting, infrastructure migration) — HIGH confidence

---

*Architecture research for: LA County Data Enrichment Pipeline Integration (v1.7)*
*Researched: 2026-02-24*
