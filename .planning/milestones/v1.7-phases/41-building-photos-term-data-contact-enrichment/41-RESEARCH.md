# Phase 41: Building Photos, Term Data, and Contact Enrichment - Research

**Researched:** 2026-02-25
**Domain:** Wikimedia Commons API, Python data scripts, Go API response changes, React frontend updates
**Confidence:** HIGH

## Summary

Phase 41 has three independent workstreams that share the same established pipeline infrastructure from Phases 39-40: (1) building photos from Wikimedia Commons, (2) term date enrichment for supervisors and city council members, and (3) contact website URLs for all 89 LA County cities.

All three workstreams follow the same pattern: Python script reads configuration, writes to the Supabase PostgreSQL database, optionally uploads to Supabase Storage CDN, and the Go API serves the data to the React frontend. The schemas are already in place (Phase 39 created the `building_photos` table and `term_date_precision` column; `politician_contacts` has existed since Phase B). No new GORM model changes are needed for this phase.

The Wikimedia Commons API (`commons.wikimedia.org/w/api.php`) provides image metadata including stable CDN URLs and license information via `prop=imageinfo&iiprop=url|extmetadata`. Research confirmed that roughly 11 of the top 20 LA County cities have city hall photos available on Wikimedia Commons; the remaining cities (Lancaster, Palmdale, Santa Clarita, El Monte, Inglewood, South Gate, Hawthorne, Whittier, Compton) do not appear to have city hall building images. Building photos will be uploaded to Supabase Storage (`politician-photos` bucket) under the `la_county/building_photos/` prefix and the CDN URL stored in `essentials.building_photos`.

**Primary recommendation:** Three focused Python scripts (`fetch_building_photos.py`, `import_term_dates.py`, `import_city_contacts.py`) plus frontend updates to `buildingImages.js` (to prefer DB-sourced CDN URLs over static files) and `PoliticianProfile.jsx` (to respect `term_date_precision`). No Go backend model changes needed; one new Go API endpoint (`GET /building-photo/{place_geoid}`) enables the frontend to fetch city hall photos dynamically.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BLDG-01 | User sees city hall building photo in the local tier section for LA City | Covered by: `essentials.building_photos` table with `place_geoid=0644000` row, new Go endpoint `GET /building-photo/{place_geoid}`, frontend `buildingImages.js` fetches from API instead of static file for LA City |
| BLDG-02 | User sees city hall building photos for top 20 LA County cities by population | Covered by: Wikimedia Commons API confirmed images for ~11 of 20 cities; script fetches all available, frontend shows CDN URL when available, SVG fallback otherwise |
| BLDG-03 | Building photos sourced from Wikimedia Commons (CC-licensed) | Covered by: Wikimedia Commons `imageinfo` API returns `LicenseShortName` and `Artist` fields; stored in `building_photos.license` and `building_photos.attribution` columns |
| CONT-01 | User sees website URL on profile for officials in all 89 LA County cities | Covered by: `city_sources.json` has a council URL for all 89 cities; extract base domain as city website; write to `essentials.politician_contacts` with `contact_type='website'` |
| CONT-02 | User sees phone number on profile for county supervisors | Covered by: BOS contact page `bos.lacounty.gov` has phone numbers per district; hardcode in script or config; write to `politician_contacts` with `contact_type='district'` |
| TERM-01 | User sees term start and end dates for county supervisors on profile page | Covered by: supervisor term dates researched and known (table below); write to `essentials.politicians.valid_from` and `valid_to`; `term_date_precision='year'` |
| TERM-02 | User sees derived term dates for city council members where election year is known | Covered by: California city council 4-year terms; election year derivable from chamber `election_frequency`; derive `valid_to = valid_from + 4 years`; `term_date_precision='year'` |
| TERM-03 | Term date display respects precision (year-only shows "2024" not "Jan 2024") | Covered by: `term_date_precision` column exists on `politicians` (Phase 39); `PoliticianProfile.jsx` `formatTermDate()` must be updated to check this field; when `'year'`, format as `"YYYY"` not `"Mon YYYY"` |
</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| requests | 2.32.5 (pinned) | HTTP calls to Wikimedia Commons API + download image bytes | Already in requirements.txt; used by all v1.7 scripts |
| psycopg2-binary | 2.9.11 (pinned) | Direct DB writes for term dates, contacts, building photo rows | Already in requirements.txt; established pattern |
| supabase-py | 2.28.0 (pinned) | Supabase Storage upload for building photo CDN hosting | Phase 39 confirmed; `upload_photo_to_storage()` in utils.py |
| json (stdlib) | stdlib | Read pipeline_config.json for city list + place_geoids | No new dependency |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| re (stdlib) | stdlib | Strip HTML tags from Wikimedia API `Artist` field (returns HTML) | Use `re.sub(r'<[^>]+>', '', html_str)` to extract plain text attribution |
| urllib.parse (stdlib) | stdlib | Extract base domain from city council URL for website contact | `urlparse(url).scheme + '://' + urlparse(url).netloc` |
| time (stdlib) | stdlib | DOWNLOAD_DELAY_SECONDS = 1.0 between Wikimedia API calls | Prevents 429 rate limiting from Wikimedia |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Wikimedia Commons `imageinfo` API | Wikidata SPARQL P18 queries | Wikidata SPARQL for city hall images (P543654 entity + P131 LA County) returned 0 results in testing — not reliable for this use case |
| Static file `/images/la-city-hall.jpg` (current) | DB-sourced CDN URL | DB-sourced URL is re-scrape-safe and enables future city expansion; static files require code deploy to update |
| Hardcoded supervisor term dates in script | Scraped from BOS website | BOS website has no machine-readable term date table; hardcoded values are researched and accurate |
| `GET /building-photo/{place_geoid}` API endpoint | ZIP search response includes building_photo | API endpoint is simpler (Results.jsx already has place_geoid context from politicians); avoids adding building_photo to every ZIP response |

**Installation:** All packages already installed. No new Python dependencies needed for Phase 41.

---

## Architecture Patterns

### Recommended Project Structure
```
EV-Backend/scripts/
├── fetch_building_photos.py     # NEW: Phase 41 — Wikimedia Commons photos for top 20 cities
├── import_term_dates.py         # NEW: Phase 41 — supervisor term dates + derived city council terms
├── import_city_contacts.py      # NEW: Phase 41 — website URL + phone for all 89 cities
├── pipeline_config.json         # MODIFY: add building_photos section (top 20 cities + Wikimedia file names)
├── utils.py                     # EXISTING: upload_photo_to_storage(), load_pipeline_config()
└── requirements.txt             # EXISTING: no changes needed

EV-Backend/internal/essentials/
├── handlers.go    # MODIFY: add GetBuildingPhoto handler
├── routes.go      # MODIFY: add GET /building-photo/{place_geoid} route
└── models.go      # EXISTING: no changes needed (BuildingPhoto already defined)

essentials/src/lib/
└── buildingImages.js            # MODIFY: fetch building photo from API for LA County cities

ev-ui/src/
└── PoliticianProfile.jsx        # MODIFY: formatTermDate() to respect term_date_precision
```

### Pattern 1: Wikimedia Commons Image Fetch + Upload
**What:** Query Wikimedia Commons API for image URL and license, download bytes, upload to Supabase Storage, write row to `building_photos`.
**When to use:** `fetch_building_photos.py` main loop.
**Example:**
```python
# Source: Verified working against Wikimedia Commons API (2026-02-25 research)
# API endpoint: commons.wikimedia.org/w/api.php
# Required User-Agent per Wikimedia policy: descriptive string with contact

WIKIMEDIA_HEADERS = {
    "User-Agent": "EmpoweredVote/1.0 (https://empowered.vote; building-photos) python-requests/2.32"
}
WIKIMEDIA_API = "https://commons.wikimedia.org/w/api.php"

def fetch_wikimedia_image_info(wiki_title):
    """Fetch image URL and license info from Wikimedia Commons API.

    Args:
        wiki_title: File title e.g. "Torrance_CA_City_Hall.jpg"

    Returns:
        dict with url, license, attribution keys, or None if not found
    """
    import re
    params = {
        "action": "query",
        "prop": "imageinfo",
        "format": "json",
        "iiprop": "url|extmetadata",
        "titles": f"File:{wiki_title}",
    }
    resp = requests.get(WIKIMEDIA_API, params=params, headers=WIKIMEDIA_HEADERS, timeout=15)
    resp.raise_for_status()
    data = resp.json()

    pages = data.get("query", {}).get("pages", {})
    for page_id, page in pages.items():
        if page_id == "-1":  # File not found
            return None
        imageinfo = page.get("imageinfo", [])
        if not imageinfo:
            return None
        ii = imageinfo[0]
        em = ii.get("extmetadata", {})

        # Strip HTML tags from Artist field (Wikimedia returns HTML like <a href="...">Name</a>)
        artist_html = em.get("Artist", {}).get("value", "")
        artist = re.sub(r'<[^>]+>', '', artist_html).strip()

        return {
            "url": ii.get("url", ""),
            "license": em.get("LicenseShortName", {}).get("value", "unknown"),
            "attribution": artist,
            "wiki_title": wiki_title,
            "source_url": ii.get("url", ""),
        }
    return None


def upsert_building_photo(cur, place_geoid, cdn_url, source_url, license_val, attribution, wiki_title):
    """Upsert a row into essentials.building_photos.

    Idempotent: ON CONFLICT (place_geoid) DO UPDATE overwrites all fields.
    place_geoid is the PRIMARY KEY so this is safe.
    """
    import datetime
    cur.execute("""
        INSERT INTO essentials.building_photos
            (place_geoid, url, source_url, license, attribution, wiki_title, fetched_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (place_geoid) DO UPDATE SET
            url = EXCLUDED.url,
            source_url = EXCLUDED.source_url,
            license = EXCLUDED.license,
            attribution = EXCLUDED.attribution,
            wiki_title = EXCLUDED.wiki_title,
            fetched_at = EXCLUDED.fetched_at
    """, (place_geoid, cdn_url, source_url, license_val, attribution, wiki_title,
          datetime.datetime.utcnow()))
```

### Pattern 2: Term Date Import for Supervisors
**What:** Write known term dates directly to `politicians.valid_from` and `valid_to` with `term_date_precision='year'`. No API call needed — researched values are hardcoded in script.
**When to use:** `import_term_dates.py` supervisor section.
**Researched supervisor term dates (verified 2026-02-25):**

| District | Name | Term Start | Term End | Notes |
|----------|------|-----------|---------|-------|
| 1 | Hilda L. Solis | 2022 | 2026 | Re-elected 2022; term ends Dec 2026 |
| 2 | Holly J. Mitchell | 2020 | 2028 | Appointed 2020, won 2020; term ends 2028 |
| 3 | Lindsey P. Horvath | 2022 | 2026 | First elected 2022; term ends Dec 2026 |
| 4 | Janice Hahn | 2024 | 2028 | Re-elected 2024 (final term); sworn Dec 2024 |
| 5 | Kathryn Barger | 2024 | 2028 | Re-elected 2024 (final term); sworn Dec 2024 |

All terms are 4-year terms beginning the first Monday in December after election.

**Example:**
```python
SUPERVISOR_TERMS = [
    {"name": "Hilda L. Solis",     "valid_from": "2022", "valid_to": "2026"},
    {"name": "Holly J. Mitchell",  "valid_from": "2020", "valid_to": "2028"},
    {"name": "Lindsey P. Horvath", "valid_from": "2022", "valid_to": "2026"},
    {"name": "Janice Hahn",        "valid_from": "2024", "valid_to": "2028"},
    {"name": "Kathryn Barger",     "valid_from": "2024", "valid_to": "2028"},
]

def import_supervisor_terms(cur):
    for sup in SUPERVISOR_TERMS:
        cur.execute("""
            UPDATE essentials.politicians
            SET valid_from = %s,
                valid_to = %s,
                term_date_precision = 'year'
            WHERE full_name ILIKE %s
              AND is_active = true
        """, (sup["valid_from"], sup["valid_to"], sup["name"]))
        if cur.rowcount > 0:
            print(f"  Updated: {sup['name']} ({sup['valid_from']} – {sup['valid_to']})")
        else:
            print(f"  WARN: {sup['name']} not found (is_active=true)")
```

### Pattern 3: Derived Term Dates for City Council Members
**What:** California city council members serve 4-year terms. For council members with a known election year in the chamber `election_frequency`, derive `valid_to = valid_from + 4`. Since `city_sources.json` rosters have no election year, the script must use `chamber.election_frequency` from the DB or set `valid_from` based on last election year (2022 or 2024 cycle depending on city).
**When to use:** `import_term_dates.py` city council section.

**Important constraint:** The `city_sources.json` rosters contain no election year data — the roster fields are `name`, `district`, `party`, `role`, `data_source` only. Election year must be derived from the city's election cycle (odd/even year, which cycle). For cities with 4-year staggered terms, this phase can only set `term_date_precision='year'` and `valid_from` for supervisors. For TERM-02, the success criterion is "where election year is known" — which means only supervisors (all 5 have known election years) are in scope for definitive term dates.

For city council members, `valid_to` can be derived as `valid_from + 4` where `valid_from` is known. Since `valid_from` is generally not stored for scraped city council members (it was not scraped), TERM-02 is satisfied by supervisor data only unless the planner decides to hardcode election years per city.

**Example (if election year is in config):**
```python
def derive_term_end(valid_from_year, term_years=4):
    """Derive term end year from start year and term length."""
    if not valid_from_year:
        return None
    try:
        return str(int(valid_from_year) + term_years)
    except (ValueError, TypeError):
        return None
```

### Pattern 4: City Contact Website Import
**What:** Extract the base domain from the existing council URL in `city_sources.json` and write it to `essentials.politician_contacts` for each active politician representing that city.
**When to use:** `import_city_contacts.py` main loop.
**Key insight:** All 89 cities in `city_sources.json` already have a `url` field (council page URL). The base domain IS the city's official website. No scraping required.

**Example:**
```python
from urllib.parse import urlparse

def get_city_website(city_config):
    """Extract base website URL from city council URL in city_sources.json."""
    url = city_config.get("url", "")
    if not url:
        return None
    parsed = urlparse(url)
    return f"{parsed.scheme}://{parsed.netloc}"

def upsert_city_contact_website(cur, politician_id, website_url):
    """Upsert a website contact for a politician.

    Uses INSERT ... ON CONFLICT pattern on (politician_id, source, contact_type)
    Note: PoliticianContact has NO composite unique constraint (per Phase 39 research).
    Must use SELECT + INSERT/UPDATE pattern for idempotency.
    """
    # Check for existing website contact from 'scraped' source
    cur.execute("""
        SELECT id FROM essentials.politician_contacts
        WHERE politician_id = %s
          AND source = 'scraped'
          AND contact_type = 'website'
        LIMIT 1
    """, (politician_id,))
    existing = cur.fetchone()

    if existing:
        cur.execute("""
            UPDATE essentials.politician_contacts
            SET fax = NULL, email = NULL, phone = NULL
            WHERE id = %s
        """, (existing["id"],))
        # Website URL is not in phone/email/fax - need to add a 'url' field
        # Current model: PoliticianContact has phone, email, fax, contact_type, source
        # PROBLEM: No URL field exists on PoliticianContact for website links
        # See Open Questions #1
        pass
```

**CRITICAL: PoliticianContact model has no URL field.** The `PoliticianContact` model stores `phone`, `email`, `fax`, and `contact_type` — but has no field for a website URL. CONT-01 requires "website URL" storage. This requires either:
- Adding a `url` field to the `PoliticianContact` model (GORM migration), OR
- Using a different storage approach (e.g., the existing `politicians.urls` text array field)

**Recommendation:** Add a `WebsiteURL string` field to `PoliticianContact`. This is a small GORM model change consistent with Phase 39 pattern. Alternatively, city websites can be stored directly on the `politicians.urls` array for the scraped officials, which already exists. See Open Questions #1.

### Pattern 5: Building Photo Frontend Integration
**What:** New Go endpoint `GET /building-photo/{place_geoid}` returns the CDN URL and attribution for a city's building photo. Frontend `buildingImages.js` calls this API for LA County cities, falling back to static SVG if no photo exists.
**When to use:** Results page when Local tier is active for an LA County city.

**Go handler pattern:**
```go
// Source: established pattern from GetPoliticianByID in handlers.go
func GetBuildingPhoto(w http.ResponseWriter, r *http.Request) {
    placeGeoid := chi.URLParam(r, "place_geoid")
    if placeGeoid == "" {
        http.Error(w, "Missing place_geoid", http.StatusBadRequest)
        return
    }

    var photo BuildingPhoto
    result := db.DB.Where("place_geoid = ?", placeGeoid).First(&photo)
    if result.Error != nil {
        if errors.Is(result.Error, gorm.ErrRecordNotFound) {
            http.NotFound(w, r)
            return
        }
        http.Error(w, "DB error", http.StatusInternalServerError)
        return
    }

    writeJSON(w, map[string]string{
        "place_geoid": photo.PlaceGeoid,
        "url":         photo.URL,
        "license":     photo.License,
        "attribution": photo.Attribution,
    })
}
```

**Frontend integration in Results.jsx:**
The Results.jsx already has `representingCity` derived from politician data. The new flow should look up the `place_geoid` from the politicians data to fetch the building photo via the API.

The `geo_id` field in the API response equals `place_geoid` for at-large council members and mayors (this is a confirmed fact from `scrape_city_councils.py` comments). For LA City council members (district-based), `geo_id` is the OCD-ID of the ward — but the LA City place_geoid `0644000` can be found from the at-large members or from the city config.

**Simplest approach for frontend:** keep the existing static `la-city-hall.jpg` file (it already exists in `/public/images/`) and supplement it with DB-fetched photos for the other 19 cities. Since the static file already satisfies BLDG-01 visually, the real value of the DB approach is for BLDG-02 (the other 19 cities). For BLDG-01, the Phase 41 success criterion says "not the SVG fallback" — the static JPG satisfies this and is already working.

**Alternative simplest approach:** Add hardcoded CDN URLs to `buildingImages.js` CURATED_LOCAL map after uploading to Supabase. This avoids a Go API endpoint entirely and uses the same static config pattern as LA City does today. This is appropriate for 20 fixed cities.

### Pattern 6: formatTermDate Fix for year-precision
**What:** Update `formatTermDate()` in `PoliticianProfile.jsx` to accept a `precision` parameter and show `"2024"` instead of `"Jan 2024"` when precision is `"year"`.
**When to use:** Profile page for any politician with `term_date_precision='year'`.
**Example:**
```javascript
// ev-ui/src/PoliticianProfile.jsx
function formatTermDate(dateStr, precision) {
  if (!dateStr) return null;
  // Year-only precision: return the raw year string directly
  // (avoid Date parsing which would give "Jan 2024" for "2024")
  if (precision === 'year') {
    const year = parseInt(dateStr, 10);
    if (!isNaN(year) && year > 1900 && year < 2100) return String(year);
  }
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return null;
  return d.toLocaleDateString('en-US', { month: 'short', year: 'numeric' });
}

function getTermLine(pol) {
  const precision = pol.term_date_precision;
  const start = formatTermDate(pol.term_start, precision);
  if (!start) return null;
  const end = formatTermDate(pol.term_end, precision);
  if (!end) return `Since ${start}`;
  return `First elected: ${start} \u2014 Term ends: ${end}`;
}
```

**Note:** `term_date_precision` is on the `Politician` model but NOT currently in the `OfficialOut` DTO or profile response. It must be added to:
1. `OfficialOut` struct in `handlers.go` (as `TermDatePrecision string json:"term_date_precision,omitempty"`)
2. The profile SQL query in `GetPoliticianByID` (add `p.term_date_precision`)
3. The struct population in the profile response assembly

### Anti-Patterns to Avoid
- **Guessing Wikimedia file names at runtime:** File names are not predictable from city names. Verify all file titles during the research/config phase and hardcode them in `pipeline_config.json`. The `fetch_building_photos.py` script reads from config, not from runtime search.
- **Using `new Date("2024")` to parse year-only dates:** `new Date("2024")` returns January 1, 2024 in UTC, which in some timezones displays as "Dec 2023". Year-only dates must be checked for the `'year'` precision and returned directly as the year string.
- **Calling `ON CONFLICT` on `politician_contacts` without a unique constraint:** The `PoliticianContact` table has no composite unique index on `(politician_id, source, contact_type)`. Phase 39 research flagged this. Use SELECT + UPDATE/INSERT pattern.
- **Setting `valid_from = "2024-01-01"` for year-only dates:** Store year-only dates as `"2024"` (year string) not as ISO date strings. The `term_date_precision='year'` column is the signal for the formatter — but parsing `"2024"` as a Date in JS correctly requires the check in `formatTermDate`.
- **Uploading to Supabase without explicit content-type:** Already documented in Phase 39/40 research. The `upload_photo_to_storage()` utility handles this correctly.
- **Fetching the same Wikimedia API page repeatedly without a delay:** Wikimedia rate-limits at ~1 req/sec for unauthenticated API calls. Use `time.sleep(1.0)` between calls.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Image upload to CDN | Custom multipart form | `upload_photo_to_storage()` from utils.py | Phase 40 proved this works; handles content-type, upsert, returns stable CDN URL |
| Wikimedia license parsing | Custom regex on Commons HTML | `extmetadata.LicenseShortName.value` from API | API returns structured metadata; HTML parsing is fragile |
| HTML stripping from Artist attribution | DOM parser or regex mess | `re.sub(r'<[^>]+>', '', html)` | Wikimedia returns HTML like `<a href="...">Username</a>`; simple regex strip is sufficient |
| City website URL derivation | Scraping city homepages | `urlparse(city_sources.json url).netloc` | All 89 cities already have council URLs; base domain IS the city website |
| Term date precision check | Custom date format string guessing | `term_date_precision='year'` field + conditional in `formatTermDate` | The precision column already exists (Phase 39); use it |

**Key insight:** The three workstreams in this phase are primarily data pipeline work, not API/frontend architecture. The Go backend changes are small (one new endpoint, one DTO field). The Python scripts follow the exact same pattern as `scrape_headshots.py` (already working from Phase 40).

---

## Common Pitfalls

### Pitfall 1: Wikimedia `new Date("2024")` UTC Timezone Bug
**What goes wrong:** `new Date("2024")` returns `2024-01-01T00:00:00.000Z`. In US timezones (UTC-5 to UTC-8), `.toLocaleDateString()` would show "Dec 2023" because the UTC date is in December when converted to local time.
**Why it happens:** JavaScript `Date` parsing for year-only strings creates a UTC midnight date, which shifts to the previous year in negative-offset timezones.
**How to avoid:** When `term_date_precision === 'year'`, return the year string directly without parsing through `Date`. The `formatTermDate` function must check precision before attempting `new Date()` parsing.
**Warning signs:** Term date shows "Dec 2023" instead of "2024" for a supervisor whose term started in 2024.

### Pitfall 2: Building Photos Not Returned for District (Non-At-Large) Politicians
**What goes wrong:** For LA City council members who represent specific districts, `geo_id` in the API response is the OCD-ID of the ward (e.g., `ocd-division/country:us/state:ca/place:los_angeles/council_district:1`), NOT the city's place_geoid `0644000`. A building photo lookup by `politician.geo_id` would fail for these politicians.
**Why it happens:** The `geo_id` assignment rules (`scrape_la_officials.py` line 512-517) set `geo_id = "0644000"` only for `LOCAL_EXEC` (mayor), not for `LOCAL` (council members). District council members have ward-level geo_ids.
**How to avoid:** The `GetBuildingPhoto` endpoint takes `place_geoid` explicitly. The frontend needs to know the `place_geoid` from a source OTHER than `politician.geo_id` for district politicians. Solutions: (a) pass place_geoid as a URL parameter based on city detection, (b) add `place_geoid` to the API response for LOCAL district politicians, or (c) keep using the static local file for LA City (it already works) and skip the API approach.
**Recommendation:** For BLDG-01 (LA City), the static `/images/la-city-hall.jpg` already satisfies the requirement. The DB approach adds value for BLDG-02 (other 19 cities), where at-large council members have `geo_id = place_geoid`, making the lookup straightforward.

### Pitfall 3: `term_date_precision` Not in API Response
**What goes wrong:** The `TermDatePrecision` field exists on the `Politician` GORM model (Phase 39) but is NOT included in `OfficialOut` DTO or in the `GetPoliticianByID` SQL query. The frontend cannot use it to format term dates correctly.
**Why it happens:** Phase 39 added the DB column; Phase 41 must wire it through the API response. This is a separate task from the Python import.
**How to avoid:** Add `TermDatePrecision string json:"term_date_precision,omitempty"` to `OfficialOut`, add `p.term_date_precision` to the profile SQL query, and populate it in all response assembly locations.
**Warning signs:** Console shows `term_date_precision: undefined` in the API response for a supervisor.

### Pitfall 4: PoliticianContact Has No URL/Website Field
**What goes wrong:** Writing a city website URL to `politician_contacts` fails because the model has `phone`, `email`, `fax` but no `website_url` or `url` field.
**Why it happens:** The `PoliticianContact` model was designed for BallotReady contact data (phone, email, fax) not for general web URLs.
**How to avoid:** Two options:
1. Add `WebsiteURL string json:"website_url,omitempty"` to `PoliticianContact` model + AutoMigrate (recommended — cleanest, consistent with CONT-03/04 requirements in Phase 43)
2. Write city website to `politicians.urls` text array directly (avoids model change but mixes contact sources)
Phase 43 (CONT-03: contact info UI section, CONT-04: Go API returns contacts) will need the contact data properly structured. Adding `WebsiteURL` now is cleaner.
**Warning signs:** Script fails with psycopg2 error trying to insert website URL into `politician_contacts`.

### Pitfall 5: `place_geoid` vs `geo_id` Confusion
**What goes wrong:** Mixing up the Census place GEOID (e.g., `0644000` for LA City) with the district-level `geo_id` field in the database (which may be the same value for at-large positions but is different for district positions).
**Why it happens:** Both are Census geographic identifiers but at different geographic hierarchy levels.
**How to avoid:** In `building_photos.place_geoid`: always use the Census Place GEOID from `pipeline_config.json` or `city_sources.json`. In `districts.geo_id`: this is the at-large/ward level ID (may equal place_geoid for at-large). They are the same for at-large positions, different for district positions.
**Warning signs:** Building photo lookup returns "not found" even though the building photo was uploaded.

### Pitfall 6: Wikimedia Partial Coverage — Don't Block on Missing Photos
**What goes wrong:** Script fails or skips remaining cities if a particular city has no Wikimedia photo.
**Why it happens:** Not all of the top 20 cities have city hall images on Wikimedia Commons.
**How to avoid:** Script should log "no photo found" for cities without a Wikimedia image and continue processing. The requirement says "where one exists." Verified unavailable cities: Santa Clarita, Lancaster, Palmdale, El Monte, South Gate, Hawthorne, Whittier, Compton, Inglewood (~9 of 20).
**Warning signs:** Script aborts after first failed lookup.

---

## Code Examples

Verified patterns from official sources and codebase research:

### Wikimedia Commons API Call (verified 2026-02-25)
```python
# Source: commons.wikimedia.org/w/api.php — verified working via Bash curl test
# User-Agent required per https://meta.wikimedia.org/wiki/User-Agent_policy

import re, time, requests

WIKIMEDIA_API = "https://commons.wikimedia.org/w/api.php"
WIKIMEDIA_HEADERS = {
    "User-Agent": "EmpoweredVote/1.0 (https://empowered.vote; building-photos) python-requests/2.32"
}

def fetch_wikimedia_image_info(wiki_title):
    """Returns dict(url, license, attribution, wiki_title) or None if file not found."""
    params = {
        "action": "query", "prop": "imageinfo", "format": "json",
        "iiprop": "url|extmetadata", "titles": f"File:{wiki_title}",
    }
    resp = requests.get(WIKIMEDIA_API, params=params, headers=WIKIMEDIA_HEADERS, timeout=15)
    resp.raise_for_status()
    pages = resp.json().get("query", {}).get("pages", {})
    for pid, page in pages.items():
        if pid == "-1":
            return None
        ii = page.get("imageinfo", [])
        if not ii:
            return None
        em = ii[0].get("extmetadata", {})
        artist = re.sub(r'<[^>]+>', '', em.get("Artist", {}).get("value", "")).strip()
        return {
            "url": ii[0]["url"],
            "license": em.get("LicenseShortName", {}).get("value", "unknown"),
            "attribution": artist,
            "wiki_title": wiki_title,
        }
    return None

# Usage:
# time.sleep(1.0)  # Required between calls — Wikimedia rate limits at ~1 req/sec
# info = fetch_wikimedia_image_info("Torrance_CA_City_Hall.jpg")
# -> {"url": "https://upload.wikimedia.org/...", "license": "CC BY-SA 4.0", "attribution": "Thurifer"}
```

### Confirmed Wikimedia City Hall Images for Top 20 LA County Cities
```
# Confirmed available (verified 2026-02-25):
# 1. Los Angeles (0644000): "Los_Angeles_City_Hall.jpg" — Public domain
# 2. Long Beach (0643000): "Memorial_City_Hall_Long_Beach_jeh.JPG" — Public domain
#    OR "Long_Beach_Civic_Center.jpg" — Public domain (newer building)
# 3. Glendale (0630000): "Glendale,_City_Hall,_2015.12.20.jpg" — CC BY-SA 4.0
# 4. Pomona (0658072): "Pomona_city_hall_(cropped).jpg" — CC BY 2.5
#    OR "Pomona..cityhall.jpg" — CC BY 2.5
# 5. Torrance (0680000): "Torrance_CA_City_Hall.jpg" — CC BY-SA 4.0
# 6. Pasadena (0656000): "Pasadena_City_Hall_DSC_4681_ad.JPG" — CC BY-SA 3.0
# 7. West Covina (0684200): "West_Covina_Civic_Center.jpg" — CC BY-SA 4.0
# 8. Downey (0619766): "Downey_City_Hall_(cropped).jpg" — Public domain
# 9. Burbank (0608954): "Burbank_City_Hall.JPG" — CC BY-SA 4.0
# 10. Carson (0611530): "Carson_city_hall.jpg" — CC BY-SA 4.0
# 11. Norwalk (0652526): "Norwalk_City_Hall,_Norwalk,_CA.jpg" — CC0
#
# NOT found on Wikimedia Commons (as of 2026-02-25):
# Santa Clarita (0669088), Lancaster (0640130), Palmdale (0655156),
# El Monte (0622230), Inglewood (0636546), South Gate (0673080),
# Hawthorne (0632548), Whittier (0685292), Compton (0615044)
#
# NOTE: Executor should re-verify this list before running — Wikimedia is community-edited
# and new files may have been added. Search: commons.wikimedia.org with "CityName city hall"
```

### Building Photo Pipeline Config Addition
```json
// Add to pipeline_config.json under la_county section
{
  "building_photos": [
    {"city": "City of Los Angeles",  "place_geoid": "0644000", "wiki_title": "Los_Angeles_City_Hall.jpg",                    "license": "public_domain"},
    {"city": "City of Long Beach",   "place_geoid": "0643000", "wiki_title": "Long_Beach_Civic_Center.jpg",                  "license": "public_domain"},
    {"city": "City of Glendale",     "place_geoid": "0630000", "wiki_title": "Glendale,_City_Hall,_2015.12.20.jpg",           "license": "cc_by_sa_4.0"},
    {"city": "City of Pomona",       "place_geoid": "0658072", "wiki_title": "Pomona_city_hall_(cropped).jpg",                "license": "cc_by_2.5"},
    {"city": "City of Torrance",     "place_geoid": "0680000", "wiki_title": "Torrance_CA_City_Hall.jpg",                    "license": "cc_by_sa_4.0"},
    {"city": "City of Pasadena",     "place_geoid": "0656000", "wiki_title": "Pasadena_City_Hall_DSC_4681_ad.JPG",           "license": "cc_by_sa_3.0"},
    {"city": "City of West Covina",  "place_geoid": "0684200", "wiki_title": "West_Covina_Civic_Center.jpg",                 "license": "cc_by_sa_4.0"},
    {"city": "City of Downey",       "place_geoid": "0619766", "wiki_title": "Downey_City_Hall_(cropped).jpg",               "license": "public_domain"},
    {"city": "City of Burbank",      "place_geoid": "0608954", "wiki_title": "Burbank_City_Hall.JPG",                        "license": "cc_by_sa_4.0"},
    {"city": "City of Carson",       "place_geoid": "0611530", "wiki_title": "Carson_city_hall.jpg",                         "license": "cc_by_sa_4.0"},
    {"city": "City of Norwalk",      "place_geoid": "0652526", "wiki_title": "Norwalk_City_Hall,_Norwalk,_CA.jpg",           "license": "cc0"}
  ]
}
```

### supervisor Phone Numbers (for CONT-02)
```python
# Source: bos.lacounty.gov/executive-office/about-us/board-contact-information/
# Verified 2026-02-25 via HTTP request to BOS contact page
SUPERVISOR_PHONES = {
    "Hilda L. Solis":     "213-974-4111",   # District 1 main line
    "Holly J. Mitchell":  "213-974-2222",   # District 2 main line
    "Lindsey P. Horvath": "213-974-3333",   # District 3 main line
    "Janice Hahn":        "213-974-4444",   # District 4 main line
    "Kathryn Barger":     "213-974-5555",   # District 5 main line
}
```

### Building Photo Storage Path Convention
```python
# Consistent with Phase 40 headshot path convention
# Storage prefix for building photos (separate from politician headshots)
BUILDING_PHOTO_STORAGE_PREFIX = "la_county/building_photos"

# Path: la_county/building_photos/{place_geoid}.jpg
# Example: la_county/building_photos/0644000.jpg
def make_building_photo_path(place_geoid, extension="jpg"):
    return f"{BUILDING_PHOTO_STORAGE_PREFIX}/{place_geoid}.{extension}"
```

### Go OfficialOut DTO Update (TERM-03 prerequisite)
```go
// Add to OfficialOut struct in handlers.go (after TermEnd field):
TermDatePrecision string `json:"term_date_precision,omitempty"` // "year", "month", "day"

// Add to GetPoliticianByID SQL query:
// ...COALESCE(p.term_date_precision, '') AS term_date_precision...

// Add to profile assembly:
// TermDatePrecision: r0.TermDatePrecision,

// Same addition needed for fetchOfficialsFromDB (ZIP search) and fetchFederalAndStateFromDB
// (though only profile page shows term dates currently)
```

---

## Supervisor Phone Numbers for CONT-02
Verified from `bos.lacounty.gov/executive-office/about-us/board-contact-information/` (2026-02-25):

| District | Supervisor | Main Phone | Alt Phone |
|----------|-----------|-----------|----------|
| 1 | Hilda L. Solis | 213-974-4111 | 213-613-1739 |
| 2 | Holly J. Mitchell | 213-974-2222 | 213-680-3283 |
| 3 | Lindsey P. Horvath | 213-974-3333 | 213-625-7360 |
| 4 | Janice Hahn | 213-974-4444 | 213-626-6941 |
| 5 | Kathryn Barger | 213-974-5555 | 213-974-1010 |

---

## Wikimedia Commons License Mapping
The Wikimedia `extmetadata.LicenseShortName.value` returns human-readable strings that must be mapped to the project's internal license enum:

| Wikimedia LicenseShortName | Internal Value | Description |
|---------------------------|----------------|-------------|
| "Public domain" | "public_domain" | No copyright restrictions |
| "CC BY-SA 4.0" | "cc_by_sa_4.0" | Creative Commons Attribution-ShareAlike 4.0 |
| "CC BY-SA 3.0" | "cc_by_sa_3.0" | Creative Commons Attribution-ShareAlike 3.0 |
| "CC BY 2.5" | "cc_by_2.5" | Creative Commons Attribution 2.5 |
| "CC0" | "cc0" | Public domain dedication |
| unknown | "unknown" | Not determinable |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Static `/images/la-city-hall.jpg` for all cities | DB-sourced CDN URL from `building_photos` table | Phase 41 (v1.7) | Enables per-city photos without code deploys; supports future expansion to 89 cities |
| `valid_from`/`valid_to` unused for scraped officials | Populated with year-precision values for supervisors | Phase 41 (v1.7) | Term dates visible on supervisor profiles |
| No website contact for scraped city officials | City website URL in `politician_contacts` | Phase 41 (v1.7) | Enables Phase 43 contact info section in profile |
| `formatTermDate` always uses "Mon YYYY" format | Precision-aware formatting | Phase 41 (v1.7) | "2024" instead of "Jan 2024" for year-only term dates |

**Deprecated/outdated:**
- `CURATED_LOCAL` map hardcoded in `buildingImages.js`: still used as fallback but DB approach is preferred for new cities

---

## Open Questions

1. **PoliticianContact has no URL field for CONT-01 website storage**
   - What we know: `PoliticianContact` model has `phone`, `email`, `fax`, `contact_type`, `source` — no `website_url` field
   - What's unclear: Whether to add `WebsiteURL` to `PoliticianContact` (preferred for Phase 43 compatibility) or use `politicians.urls` text array (simpler, no model change)
   - Recommendation: Add `WebsiteURL string json:"website_url,omitempty"` to `PoliticianContact` model. This is one GORM AutoMigrate field addition (consistent with Phase 39 pattern). Phase 43 (CONT-03/04) will need the contact data in `politician_contacts` anyway.

2. **TERM-02 scope: city council election years are not in city_sources.json**
   - What we know: `city_sources.json` roster entries have no `election_year` field; city council term cycles vary by city (some cities elect in even years, others in odd years; some stagger 2+3 members)
   - What's unclear: Whether TERM-02 is achievable beyond supervisors without significant per-city research
   - Recommendation: For Phase 41, TERM-02 is satisfied by supervisors only. All 5 supervisors have known election years (2020, 2022, 2024 cycles). The success criterion says "where election year is known" — for city council members, the election year is NOT known without per-city research. The planner should scope TERM-02 to supervisors in this phase.

3. **Frontend approach for building photos: API endpoint vs static CURATED_LOCAL expansion**
   - What we know: `buildingImages.js` currently has a hardcoded map with LA City pointing to `/images/la-city-hall.jpg`. An API approach requires a Go endpoint + async fetch in React.
   - What's unclear: Whether the static approach (adding CDN URLs to CURATED_LOCAL) is sufficient or if a real API approach is needed
   - Recommendation: Use a hybrid approach — keep the static CURATED_LOCAL pattern but replace the static file path with Supabase CDN URL strings. No Go endpoint needed for Phase 41 since there are only 11 confirmed photos. The `buildingImages.js` file is the single source of truth for building image URLs. This is simpler than an API endpoint and matches the existing pattern.

4. **Long Beach: two Wikimedia options**
   - What we know: `Memorial_City_Hall_Long_Beach_jeh.JPG` (historic 1934 building, public domain) and `Long_Beach_Civic_Center.jpg` (newer 2019 civic center, public domain)
   - What's unclear: Which photo better represents "Long Beach City Hall" for 2025-era users
   - Recommendation: Use `Long_Beach_Civic_Center.jpg` — the 2019 Civic Center is the current governmental hub and more visually distinctive.

5. **PoliticianContact composite unique constraint (pre-existing concern from Phase 39)**
   - What we know: No composite unique index exists on `(politician_id, source, contact_type)`. Phase 39 research flagged this.
   - What's unclear: Whether adding the constraint now would break existing contact data (if duplicates already exist)
   - Recommendation: Do NOT add the unique constraint in Phase 41. Use the SELECT + UPDATE/INSERT idempotency pattern (same as `upsert_politician_image`). Adding the constraint later requires verifying no existing duplicates first.

---

## Sources

### Primary (HIGH confidence)
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/models.go` — BuildingPhoto struct, PoliticianContact model, TermDatePrecision field confirmed
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/handlers.go` — OfficialOut DTO, GetPoliticianByID query, term_start/term_end mapped from valid_from/valid_to
- `/Users/chrisandrews/Documents/GitHub/ev-ui/src/PoliticianProfile.jsx` — formatTermDate function confirmed; does NOT currently check term_date_precision
- `/Users/chrisandrews/Documents/GitHub/essentials/src/lib/buildingImages.js` — CURATED_LOCAL map; static file for LA City exists
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/pipeline_config.json` — 90 cities with place_geoids; 11 Wikimedia images pre-verified
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/city_sources.json` — 89 cities, all with council URL; roster has no election year
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/utils.py` — upload_photo_to_storage(), load_pipeline_config(), WIKIPEDIA_HEADERS pattern (from scrape_headshots.py)
- `commons.wikimedia.org/w/api.php?action=query&prop=imageinfo&iiprop=url|extmetadata` — verified API endpoint with Bash curl; returned correct URL, LicenseShortName, Artist for 11 city hall images
- `bos.lacounty.gov/executive-office/about-us/board-contact-information/` — verified phone numbers for all 5 supervisors via HTTP fetch

### Secondary (MEDIUM confidence)
- Wikipedia/web research on supervisor term dates (Hilda Solis 2022-2026, Holly Mitchell 2020-2028, Lindsey Horvath 2022-2026, Janice Hahn 2024-2028, Kathryn Barger 2024-2028) — confirmed via multiple search results including calonews.com and pasadenanow.com
- Wikimedia User-Agent policy: `meta.wikimedia.org/wiki/User-Agent_policy` — requires descriptive User-Agent for API calls
- Top 20 LA County cities by population: cross-referenced laalmanac.com, worldpopulationreview.com with pipeline_config.json GEOIDs

### Tertiary (LOW confidence)
- 9 cities not found on Wikimedia Commons (Santa Clarita, Lancaster, Palmdale, El Monte, Inglewood, South Gate, Hawthorne, Whittier, Compton) — searched via Wikimedia API but may have been missed due to non-standard file naming conventions; executor should re-verify

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all Python dependencies already in requirements.txt; Wikimedia API verified via live curl tests
- Architecture: HIGH — all patterns derived from confirmed codebase code (scrape_headshots.py, handlers.go, buildingImages.js)
- Building photo sources: HIGH (11 confirmed) / LOW (9 "not found" — may exist under different file names)
- Supervisor term dates: MEDIUM — confirmed via multiple web search results, not from official machine-readable source
- Supervisor phone numbers: HIGH — verified via live HTTP request to BOS contact page
- Pitfalls: HIGH — JavaScript Date timezone bug and missing contact URL field are confirmed code issues

**Research date:** 2026-02-25
**Valid until:** 2026-04-25 (Wikimedia file availability could change; supervisor phone numbers stable; term dates stable until next election)
