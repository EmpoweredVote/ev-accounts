# Stack Research — v1.7 LA County Data Enrichment

**Domain:** Civic engagement platform — politician photo scraping, building photo acquisition, contact/term data extraction
**Researched:** 2026-02-24
**Confidence:** HIGH

---

## Scope

This document covers only *new or changed* stack decisions for v1.7. The existing stack is retained as-is:

- **Go 1.24.3 + Chi + GORM + PostgreSQL/PostGIS** — backend unchanged
- **React 19 + Vite + Tailwind** — frontends unchanged
- **Python import scripts + shared `utils.py`** — scraper infrastructure reused, extended
- **`PoliticianImage`, `PoliticianContact`, `Degree`, `Experience` models** — already in DB schema, scripts write into them
- **`politician_sources.json` / `city_sources.json`** — config-driven scraper pattern reused

v1.7 adds four new capabilities to the existing Python scraper pipeline:
1. Headshot photo scraping from city/county government websites
2. City hall building photo acquisition via Wikimedia Commons API
3. Contact/term data extraction (email, phone, website, term dates)
4. Bio/education/experience enrichment where available

---

## Recommended Stack

### Core Technologies (Unchanged)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Python | 3.13 | Scraping pipeline runtime | Already in use; venv at `scripts/.venv/lib/python3.13` |
| psycopg2-binary | 2.9.11 | Direct PostgreSQL writes | Already in use across all scripts |
| requests | 2.32.5 | HTTP fetching | Already in use; handles government site scraping |
| beautifulsoup4 | 4.12.3 | HTML parsing | Already in use; 4.14.3 available but 4.12.3 is pinned and working |
| rapidfuzz | 3.12.1 | Name deduplication matching | Already in use; 3.14.3 available but current version is correct |

### New Libraries for v1.7

| Library | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| `playwright` | `1.58.0` | JS-rendered government sites | Already in `requirements.txt` at 1.44.0; upgrade to 1.58.0 for Chromium 133. Government council pages increasingly use React/Angular rendering that `requests` + BeautifulSoup cannot reach. The `fetch_html_with_fallback()` pattern in `scrape_city_councils.py` already uses Playwright as fallback — this is the established pattern to extend. |
| `Pillow` | `12.1.1` | Image validation before DB write | NEW. Validates downloaded headshots are actual images (not 404 HTML, placeholder GIFs, or broken files) before inserting into `essentials.politician_images`. Verifies minimum dimensions. Pure Python, no system dependencies. |

### No New Libraries for Wikimedia Commons

The Wikimedia Commons MediaWiki API is accessed via plain `requests` GET calls to `https://commons.wikimedia.org/w/api.php` — no additional library needed. Authentication is not required for read-only image searches. The API accepts `action=query&list=allimages&aisearch={term}&aiprop=url|title&ailimit=5&format=json` with a descriptive `User-Agent` header. This is the same `requests` + JSON parsing pattern used in all existing scripts.

Do NOT add `pyWikiCommons`, `wikipedia`, `SPARQLWrapper`, or any Wikimedia SDK. `SPARQLWrapper` 2.0.0 has not been updated since March 2022 and is effectively unmaintained on PyPI. The plain `requests` approach is simpler and already proven in the codebase.

### No Google Places API for Building Photos

The existing `buildingImages.js` frontend approach (curated static image map with Wikimedia Commons sources and SVG fallback) is the correct pattern for building photos. Do NOT use Google Places API for building photo acquisition:
- Places Photos API has per-request billing (even on free tier, 10K requests/month cap)
- Photos are not permanently linkable URLs — they expire or require API key in URL
- The project already has `/images/la-city-hall.jpg` and the Wikimedia Commons pattern from v1.1

For LA County city halls, acquire photos via Wikimedia Commons API (free, CC-licensed, permanent URLs) and store them as static assets in the `essentials` frontend, following the same pattern as existing building images.

---

## Integration Points

### Photo Storage: `essentials.politician_images` Table (Existing)

The `PoliticianImage` model already exists in Go (`models.go` line 159):

```go
type PoliticianImage struct {
    ID           uuid.UUID
    PoliticianID uuid.UUID
    URL          string
    Type         string  // "default" or "thumb"
}
```

Python scraper inserts rows via psycopg2:
```python
cur.execute("""
    INSERT INTO essentials.politician_images (id, politician_id, url, type)
    VALUES (%s, %s, %s, 'default')
    ON CONFLICT DO NOTHING
""", (str(uuid.uuid4()), politician_id, photo_url))
```

The Go API already reads `politician_images` and includes them in profile responses. No Go changes needed once rows are inserted.

### Contact Storage: `essentials.politician_contacts` Table (Existing)

The `PoliticianContact` model already exists in Go (`models.go` line 249):

```go
type PoliticianContact struct {
    ID           uuid.UUID
    PoliticianID uuid.UUID
    Source       string   // "person" or "officeholder"
    Email        string
    Phone        string
    Fax          string
    ContactType  string   // "district", "capitol", etc.
}
```

For scraped officials, use `Source = "officeholder"` and `ContactType = "district"`. Upsert pattern:
```python
cur.execute("""
    INSERT INTO essentials.politician_contacts
        (id, politician_id, source, email, phone, contact_type)
    VALUES (%s, %s, 'officeholder', %s, %s, 'district')
    ON CONFLICT (politician_id, source, contact_type) DO UPDATE SET
        email = EXCLUDED.email,
        phone = EXCLUDED.phone
""", (str(uuid.uuid4()), politician_id, email, phone))
```

Note: The `politician_contacts` table currently lacks a composite unique constraint in the Go model definition — verify one exists or add it before running enrichment scripts. If not present, use `DO NOTHING` and manage upserts by querying first.

### Term Data Storage: `essentials.offices` and `essentials.politicians` Tables

Term start/end dates are not yet a distinct field in the schema. The `Politician` model has `ValidFrom` / `ValidTo` fields (line 14-15 in `models.go`) and `Office` has no start/end date fields. For v1.7:

- Store `term_start` date in `politicians.valid_from` (string field, accepts ISO date)
- Store `term_end` date in `politicians.valid_to` (string field)
- Store `total_years_in_office` in `politicians.total_years_in_office` (int field)

No schema changes needed — these fields exist.

### Building Photo Storage: Static Assets in Frontend

City hall building photos go to `essentials/public/images/` and are registered in `essentials/src/lib/buildingImages.js` in the `CURATED_LOCAL` map. This is a code change in the `essentials` React app, not a database operation.

Pattern to follow (from `buildingImages.js` line 73-75):
```js
const CURATED_LOCAL = {
  bloomington: '/images/bloomington-city-hall.jpg',
  'los angeles': '/images/la-city-hall.jpg',
  // Add new cities here: 'burbank': '/images/burbank-city-hall.jpg'
};
```

Key matching is on `city.includes(key)` — the city name from politician data (lowercase). For LA County cities where the `representing_city` on council members may be the council chamber name rather than a clean city name, coordinate with the `buildSubtitle()` pattern to extract the city name.

---

## Supporting Libraries — Updated `requirements.txt`

Current pinned versions in `EV-Backend/scripts/requirements.txt`:
```
geopandas==1.1.2
SQLAlchemy==2.0.46
psycopg2-binary==2.9.11
shapely==2.0.7
requests==2.32.5
beautifulsoup4==4.12.3
rapidfuzz==3.12.1
pdfplumber==0.11.4
playwright==1.44.0
```

For v1.7, add one library and upgrade Playwright:

```
geopandas==1.1.2
SQLAlchemy==2.0.46
psycopg2-binary==2.9.11
shapely==2.0.7
requests==2.32.5
beautifulsoup4==4.12.3
rapidfuzz==3.12.1
pdfplumber==0.11.4
playwright==1.58.0        # Upgraded from 1.44.0 — Chromium 133, better JS site support
Pillow==12.1.1            # NEW — image validation before DB insert
```

After upgrading Playwright, run `playwright install chromium` to download the updated browser binary.

---

## Wikimedia Commons API — How to Use

No additional library needed. Query pattern using existing `requests`:

```python
import requests

WIKIMEDIA_USER_AGENT = "EmpoweredVote/1.7 (contact@empowered.vote)"

def search_wikimedia_image(search_term: str) -> str | None:
    """Search Wikimedia Commons for an image. Returns URL or None."""
    params = {
        "action": "query",
        "list": "allimages",
        "aisearch": search_term,
        "aiprop": "url|title|mime",
        "aisort": "name",
        "ailimit": "5",
        "format": "json",
    }
    resp = requests.get(
        "https://commons.wikimedia.org/w/api.php",
        params=params,
        headers={"User-Agent": WIKIMEDIA_USER_AGENT},
        timeout=10,
    )
    resp.raise_for_status()
    images = resp.json().get("query", {}).get("allimages", [])
    # Filter: JPEG/PNG only, skip icons/logos
    for img in images:
        mime = img.get("mime", "")
        url = img.get("url", "")
        if mime in ("image/jpeg", "image/png") and "city_hall" in url.lower():
            return url
    return images[0]["url"] if images else None
```

Search terms for city hall building photos: `"{City Name} City Hall"` as the `aisearch` parameter. For LA County Supervisors: `"Los Angeles County Hall of Administration"` or `"Kenneth Hahn Hall of Administration"`.

Rate limit: No hard limit on read requests; send requests in series (not parallel). The free API does not require API keys or OAuth.

---

## Headshot Scraping Strategy

The existing `scrape_city_councils.py` already has `fetch_html_with_fallback()` which tries `requests` first, falls back to Playwright. For headshot extraction, extend the generic parser:

```python
def extract_headshot_from_page(soup, official_name: str) -> str | None:
    """Extract headshot URL for a named official from a parsed council page.

    Strategy:
    1. Find img tags near the official's name text
    2. Filter: skip logos, icons, background images
    3. Return absolute URL or None
    """
    from urllib.parse import urljoin
    # Look for heading/card containing the name, extract nearby img
    # Filter: width > 50px (src attribute or adjacent style), skip .svg, skip generic site logos
    ...
```

Image validation with Pillow before DB insert:

```python
from PIL import Image
import io

def is_valid_headshot(image_bytes: bytes, min_px: int = 80) -> bool:
    """Validate bytes are a real image with minimum dimensions."""
    try:
        img = Image.open(io.BytesIO(image_bytes))
        w, h = img.size
        return w >= min_px and h >= min_px
    except Exception:
        return False
```

Download the image, validate, then insert the URL (not the bytes — store URLs only, per the existing pattern).

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Wikimedia Commons REST API via `requests` | `pyWikiCommons` library | Never — `pyWikiCommons` 0.2.0 is a thin wrapper that adds a dependency for no benefit; raw `requests` is already in use |
| Wikimedia Commons REST API via `requests` | Google Places API for building photos | Never for this project — Places API has billing complexity, non-permanent URLs, and per-request cost; Wikimedia is free, CC-licensed, permanent URLs |
| Wikimedia Commons REST API via `requests` | Wikidata SPARQL (SPARQLWrapper) | Not needed for this scope — SPARQL overkill for building photo lookup; SPARQLWrapper is effectively unmaintained on PyPI (last release March 2022) |
| `Pillow==12.1.1` for image validation | In-memory `imghdr` stdlib | `imghdr` deprecated in Python 3.11+, removed in 3.13; Pillow is the correct replacement |
| Playwright `1.58.0` (upgraded from `1.44.0`) | Stay on `1.44.0` | If Chromium browser binary disk space is a constraint (unlikely); `1.58.0` adds better mobile viewport support useful for government sites optimized for mobile |
| Store photo URLs in `politician_images` | Download to Supabase Storage | Out of scope for v1.7 — `TODO` comment in `scrape_la_officials.py` explicitly defers this. Scraped URLs work now; infrastructure concern for later milestone |
| Static assets in `essentials/public/images/` for building photos | Database-backed building photo URLs | Static is simpler — no API endpoint needed, no DB row, no frontend fetch; existing `buildingImages.js` already uses this pattern |

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `SPARQLWrapper` | Effectively unmaintained on PyPI (last release 2022); adds complexity for SPARQL queries that can be made with raw `requests` to Wikidata endpoint | `requests.get("https://query.wikidata.org/sparql", params={"query": sparql_string, "format": "json"})` — same API, no extra dependency |
| `pyWikiCommons` | Thin wrapper, adds PyPI dependency, no benefits over raw `requests` to `commons.wikimedia.org/w/api.php` | Plain `requests` with User-Agent header |
| `google-maps-services-python` or Google Places API Photos | Billing per request, non-permanent photo URLs, 10K free/month cap applies to existing autocomplete use | Wikimedia Commons API (free, CC-licensed, permanent URLs) |
| `wikipedia` Python library | Heavyweight for this use case; designed for article content, not image fetching | Raw `requests` to MediaWiki API |
| Async scraping (`asyncio`, `aiohttp`) | Government sites need polite serial requests anyway; overhead for ~389 officials is not a bottleneck; adds complexity to simple scripts | Synchronous `requests` + Playwright sync API (already in use) |
| `Scrapy` framework | Heavy framework for one-off ~389-record enrichment; config-driven `politician_sources.json` pattern is sufficient | Extend existing config-driven `scrape_*.py` pattern |
| Image re-hosting to Supabase Storage | Explicitly out of scope in PROJECT.md; scraped URLs work for now | Keep scraped photo URLs, link directly from DB |
| Any new Go packages | No Go changes needed — `PoliticianImage`, `PoliticianContact` models and API endpoints already exist | Python scripts write directly to existing tables |
| Any new npm packages | Building photos go to `public/images/` as static assets; `buildingImages.js` code change only | Extend `CURATED_LOCAL` map in `buildingImages.js` |

---

## Stack Patterns by Task

**If scraping headshot photos from government websites:**
- Use existing `fetch_html_with_fallback()` from `scrape_city_councils.py`
- Extract img src URLs near the official's name element
- Download the image bytes with `requests.get(img_url)`
- Validate with `Pillow.Image.open()` — require minimum 80x80px, JPEG or PNG
- Store the original URL (not bytes) in `essentials.politician_images` via psycopg2
- Skip if image already exists: `SELECT 1 FROM essentials.politician_images WHERE politician_id = %s LIMIT 1`

**If acquiring city hall building photos for 89 LA County cities:**
- Query Wikimedia Commons API: `GET https://commons.wikimedia.org/w/api.php?action=query&list=allimages&aisearch={City+Name+City+Hall}&format=json`
- Filter results: JPEG/PNG only, URL contains "city_hall" or "hall" in path
- Download image, validate with Pillow, store in `essentials/public/images/{city-slug}-city-hall.jpg`
- Add entry to `CURATED_LOCAL` map in `essentials/src/lib/buildingImages.js`
- SVG fallback already handles cities where no photo is found — no code needed for fallback case

**If extracting contact info (email, phone, website) from government sites:**
- Parse with BeautifulSoup; look for `mailto:` links (email), `tel:` links (phone), official website links
- Common regex patterns: `r'[\w\.-]+@[\w\.-]+\.\w+'` for email, `r'\(?\d{3}\)?[\s\-]\d{3}[\s\-]\d{4}'` for phone
- Upsert into `essentials.politician_contacts` with `source = 'officeholder'`, `contact_type = 'district'`

**If extracting term/election dates:**
- Parse from government bio pages: look for "elected", "term", "took office" patterns
- Store as ISO date strings in `politicians.valid_from` (term start) and `politicians.valid_to` (term end)
- For `total_years_in_office`, compute from dates or use scraped "X years" text
- These fields are already in the `Politician` model — no schema changes needed

**If a government site blocks requests or requires JS:**
- Already handled by `fetch_html_with_fallback()` in `scrape_city_councils.py`
- Playwright 1.58.0 handles JS-rendered pages
- School board sites (already established in v1.6) use hardcoded rosters when Cloudflare blocks — apply same pattern for blocked city sites

---

## Version Compatibility

| Package | Current Version | v1.7 Version | Notes |
|---------|----------------|--------------|-------|
| `playwright` | `1.44.0` | `1.58.0` | Run `playwright install chromium` after upgrade; sync API unchanged |
| `Pillow` | not installed | `12.1.1` | Requires Python 3.9+; current env is Python 3.13 — compatible |
| `beautifulsoup4` | `4.12.3` | `4.12.3` | 4.14.3 available; stay pinned for stability |
| `requests` | `2.32.5` | `2.32.5` | Current; no upgrade needed |
| `rapidfuzz` | `3.12.1` | `3.12.1` | 3.14.3 available; stay pinned for stability |
| `pdfplumber` | `0.11.4` | `0.11.4` | 0.11.9 available; no v1.7 PDF extraction needed beyond existing SOS PDF work |

---

## External API Requirements

| API | Auth Required | Rate Limit | Cost | Usage in v1.7 |
|-----|--------------|------------|------|---------------|
| Wikimedia Commons MediaWiki API | None (read-only) | No hard limit; serial requests recommended | Free | Building photo search for 89 cities |
| Government websites (lacounty.gov, lacity.gov, city sites) | None | Varies; use 1-2s delay between requests | Free | Headshot and contact scraping |
| Google Maps Places API | YES (existing key) | 28K requests/month free (autocomplete SKU) | Existing billing | NOT used for v1.7 — no new Places API calls |

---

## Sources

- `EV-Backend/scripts/requirements.txt` — current pinned dependencies, HIGH confidence
- `EV-Backend/scripts/scrape_city_councils.py` — `fetch_html_with_fallback()` Playwright pattern, HIGH confidence
- `EV-Backend/scripts/scrape_la_officials.py` — `photo_origin_url` TODO comment, scraper architecture, HIGH confidence
- `EV-Backend/internal/essentials/models.go` — `PoliticianImage`, `PoliticianContact`, `Degree`, `Experience` schema, HIGH confidence
- `essentials/src/lib/buildingImages.js` — `CURATED_LOCAL` static asset pattern, `getBuildingImages()` function, HIGH confidence
- [Playwright Python PyPI](https://pypi.org/project/playwright/) — v1.58.0 current stable January 2026, HIGH confidence (verified PyPI)
- [Pillow PyPI](https://pypi.org/project/pillow/) — v12.1.1 current stable February 2026, HIGH confidence (verified via WebSearch)
- [Wikimedia Commons API:Etiquette](https://www.mediawiki.org/wiki/API:Etiquette) — no auth needed for reads, serial requests recommended, User-Agent required since late 2025, MEDIUM confidence (verified via WebSearch)
- [Wikimedia Rate Limits](https://api.wikimedia.org/wiki/Rate_limits) — read requests have no hard limit, MEDIUM confidence (verified via WebSearch)
- [pdfplumber PyPI](https://pypi.org/project/pdfplumber/) — v0.11.9 current stable January 2026 (not needed for v1.7), HIGH confidence (verified via WebFetch)
- [SPARQLWrapper PyPI](https://pypi.org/project/SPARQLWrapper/) — v2.0.0, last release March 2022, effectively unmaintained, HIGH confidence (verified via WebSearch)
- [SQLAlchemy releases](https://www.sqlalchemy.org/blog/) — 2.0.46 stable January 2026, HIGH confidence (verified via WebSearch)

---

*Stack research for: v1.7 LA County Data Enrichment — headshot photos, building photos, contact/term data extraction*
*Researched: 2026-02-24*
