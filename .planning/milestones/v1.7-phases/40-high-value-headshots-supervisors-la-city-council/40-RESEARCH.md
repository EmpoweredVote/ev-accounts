# Phase 40: High-Value Headshots — Supervisors and LA City Council - Research

**Researched:** 2026-02-24
**Domain:** Python web scraping, Supabase Storage upload, PostgreSQL upsert (psycopg2)
**Confidence:** HIGH

## Summary

Phase 40 scrapes official headshot photos for 5 LA County supervisors and 15 LA City council members, uploads each image to Supabase Storage, and writes CDN URLs + photo_license values to the `essentials.politician_images` table. All infrastructure from Phase 39 is confirmed in place: `upload_photo_to_storage()` in `utils.py`, `supabase==2.28.0` in `requirements.txt`, `pipeline_config.json` with region definitions, `photo_license` column on `politician_images`, and the `politician-photos` bucket (human-verified).

The primary scraping challenge is that LA City council member photos are **not centralized** — each of the 15 districts maintains its own website with inconsistent structure. Some have press kits with direct JPEG download URLs; others have no dedicated headshot at all. The recommended strategy is a config-driven approach: hardcode verified photo URLs per politician in `pipeline_config.json` (not discovered at runtime), with a fallback scrape attempt for council members missing a hardcoded URL. This is the most reliable path to 100% coverage for all 20 targets without fragile HTML parsers on 15 different site architectures.

The idempotency requirement (PHOTO-01/PHOTO-04/PHOTO-05, Success Criterion 5) is satisfied by three independent mechanisms: (1) `upload_photo_to_storage()` uses `upsert=true` so re-upload overwrites the same CDN path; (2) the DB upsert pattern skips rows where `politician_images` already has a non-null URL; (3) storage paths are deterministic — `la_county/supervisors/{politician_id}.jpg` — so re-running produces the exact same CDN URL.

**Primary recommendation:** Write a single `scrape_headshots.py` script that reads photo source URLs from `pipeline_config.json`, downloads each image, uploads to Supabase Storage, and upserts into `politician_images`. Use hardcoded URLs for supervisors (all 5 available from a single official page) and a per-district config for LA City council members. Set `photo_license = "scraped_no_license"` for government website photos; use `"press_use"` when a press kit explicitly offers the image for download.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PHOTO-01 | User sees headshot photo for each LA County supervisor on their profile page | Covered by: 5 supervisor photos available at `bos.lacounty.gov/official-photos/` with direct kc-usercontent.com download URLs; writing CDN URL to `politician_images` makes them appear in the API response |
| PHOTO-02 | User sees headshot photo for each LA City council member on their profile page | Covered by: each of 15 council districts has at least one photo accessible via individual district website (cdN.lacity.gov); some have press kit JPEG URLs, others require img src extraction; config-driven per-district URLs recommended |
| PHOTO-04 | All scraped headshots stored in Supabase Storage CDN (not hotlinked from source sites) | Covered by: `upload_photo_to_storage()` from Phase 39 uploads bytes to `politician-photos` bucket and returns `*.supabase.co` CDN URL; DB write stores only the CDN URL |
| PHOTO-05 | Photo licensing tracked for each scraped image | Covered by: `photo_license` column exists on `politician_images` (Phase 39); set to `"press_use"` for official press kit downloads, `"scraped_no_license"` for government site images scraped without explicit license statement |
</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| requests | 2.32.5 (pinned) | HTTP download of image bytes from government websites | Already in requirements.txt; used by all existing scrapers |
| beautifulsoup4 | 4.12.3 (pinned) | HTML parsing to extract img src attributes when needed | Already in requirements.txt; used by scrape_la_officials.py |
| psycopg2-binary | 2.9.11 (pinned) | Direct DB writes to essentials.politician_images | Already in requirements.txt; established pattern across all v1.6/v1.7 scripts |
| supabase-py | 2.28.0 (pinned) | Supabase Storage upload via `upload_photo_to_storage()` from utils.py | Phase 39 delivered this; confirmed working (human-verified checkpoint passed) |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| mimetypes (stdlib) | stdlib | Detect content-type from image URL extension | Use when downloading a .png vs .jpg vs .webp to pass correct content_type to upload_photo_to_storage() |
| pathlib (stdlib) | stdlib | Derive storage path from politician ID | Already used in utils.py |
| json (stdlib) | stdlib | Load pipeline_config.json with hardcoded photo URLs | Used by load_pipeline_config() |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hardcoded URLs in pipeline_config.json | Runtime HTML scraping per district | Runtime scraping breaks when government sites restructure (happened to bos.lacounty.gov during v1.6). Hardcoded URLs are verified once and stable for months. Use runtime scraping as fallback only. |
| Single `scrape_headshots.py` script | Two separate scripts (supervisors + council) | Single script is simpler; the two groups use the same upload/upsert logic with only the config source differing |
| `scraped_no_license` for all photos | Distinguish press_use vs scraped | Differentiating licenses satisfies PHOTO-05 better and gives clearer attribution intent |

**Installation:** All packages already installed. No new dependencies needed for Phase 40.

---

## Architecture Patterns

### Recommended Project Structure
```
EV-Backend/scripts/
├── scrape_headshots.py         # NEW: Phase 40 — supervisors + LA City council
├── pipeline_config.json        # MODIFY: add photo_sources per politician
├── utils.py                    # EXISTING: upload_photo_to_storage(), load_pipeline_config()
└── requirements.txt            # EXISTING: no changes needed
```

```
EV-Backend/internal/essentials/
├── models.go    # EXISTING: PoliticianImage.PhotoLicense column (Phase 39 confirmed)
└── (no changes needed in Go backend for Phase 40)
```

### Pattern 1: Config-Driven Photo URL Registry
**What:** Store verified photo URLs per politician in `pipeline_config.json` so scraping is deterministic and re-runnable without live HTML parsing risk.
**When to use:** For high-value targets where URLs are known in advance (all 20 supervisors/council members).
**Example:**
```json
// pipeline_config.json — add to la_county section
{
  "default_region": "la_county",
  "regions": {
    "la_county": {
      "headshots": {
        "supervisors": [
          {
            "name": "Hilda L. Solis",
            "district": 1,
            "photo_url": "https://assets-us-01.kc-usercontent.com:443/0234f496-d2b7-00b6-17a4-b43e949b70a2/be5432b1-336e-43d4-8678-9392c9d72bae/Supervisor%20Hilda%20Solis%202026.jpg",
            "photo_license": "scraped_no_license",
            "storage_filename": "hilda-solis.jpg"
          }
        ],
        "la_city_council": [
          {
            "name": "Eunisses Hernandez",
            "district": 1,
            "photo_url": "https://cd1.lacity.gov/sites/g/files/wph2061/files/styles/portrait_medium_350x467_/public/2023-03/Eunisses_Hernandez_960x665.jpg",
            "photo_license": "scraped_no_license",
            "storage_filename": "eunisses-hernandez.jpg"
          },
          {
            "name": "Nithya Raman",
            "district": 4,
            "photo_url": "https://cd4.lacity.gov/wp-content/uploads/2023/10/A6013-189.jpg",
            "photo_license": "press_use",
            "storage_filename": "nithya-raman.jpg"
          }
        ]
      }
    }
  }
}
```

### Pattern 2: Scraper Main Loop (idempotent)
**What:** For each configured politician, find their DB record by name+district, download photo, upload to Storage, upsert into `politician_images`.
**When to use:** The core execution loop in `scrape_headshots.py`.
**Example:**
```python
# Source: established pattern from scrape_la_officials.py + Phase 39 upload utility

import sys
import requests
import psycopg2
import psycopg2.extras
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from utils import load_env, load_supabase_env, load_pipeline_config, upload_photo_to_storage, next_ext_id

SUPERVISOR_STORAGE_PREFIX = "la_county/supervisors"
COUNCIL_STORAGE_PREFIX = "la_county/la_city_council"

def download_image(url, timeout=15):
    """Download image bytes with browser User-Agent."""
    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/121.0.0.0 Safari/537.36"
        )
    }
    resp = requests.get(url, headers=headers, timeout=timeout)
    resp.raise_for_status()
    return resp.content

def find_politician_id(cur, name, group_type):
    """Find politician UUID by full_name and group type (supervisor vs council member)."""
    if group_type == "supervisor":
        title_pattern = "%Supervisor%"
    else:
        title_pattern = "%Council%"

    cur.execute("""
        SELECT p.id
        FROM essentials.politicians p
        JOIN essentials.offices o ON o.politician_id = p.id
        WHERE p.full_name ILIKE %s
          AND LOWER(o.title) LIKE LOWER(%s)
          AND p.is_active = true
        ORDER BY p.last_synced DESC
        LIMIT 1
    """, (name, title_pattern))
    row = cur.fetchone()
    return str(row["id"]) if row else None

def upsert_politician_image(cur, politician_id, cdn_url, photo_license, storage_path):
    """Upsert a single image record for a politician.

    IDEMPOTENCY: Skip if a non-empty URL already exists for this politician+type.
    This prevents overwriting existing CDN URLs on re-run (per Success Criterion 5).

    Note: uses INSERT ... ON CONFLICT DO NOTHING if same URL already stored,
    or INSERT and replace if URL changed (re-run with new photo).
    """
    # Check if already have a "default" image for this politician
    cur.execute("""
        SELECT id, url FROM essentials.politician_images
        WHERE politician_id = %s AND type = 'default'
        LIMIT 1
    """, (politician_id,))
    existing = cur.fetchone()

    if existing:
        # Already has a default image — update URL and license (idempotent re-run)
        cur.execute("""
            UPDATE essentials.politician_images
            SET url = %s, photo_license = %s
            WHERE id = %s
        """, (cdn_url, photo_license, existing["id"]))
        return "updated"
    else:
        # Insert new image record
        cur.execute("""
            INSERT INTO essentials.politician_images
                (id, politician_id, url, type, photo_license)
            VALUES (gen_random_uuid(), %s, %s, 'default', %s)
        """, (politician_id, cdn_url, photo_license))
        return "inserted"
```

### Pattern 3: Storage Path Convention
**What:** Deterministic storage path using politician name slug (not UUID) for human readability and re-run stability.
**Why not UUID:** The path `la_county/supervisors/{uuid}.jpg` is opaque. A slug like `hilda-solis.jpg` is readable in the bucket browser and stable across re-runs.
**Example:**
```python
import re

def make_storage_path(name, prefix, extension="jpg"):
    """Convert 'Hilda L. Solis' -> 'la_county/supervisors/hilda-solis.jpg'"""
    slug = re.sub(r'[^a-z0-9]+', '-', name.lower()).strip('-')
    return f"{prefix}/{slug}.{extension}"

# Examples:
# "Hilda L. Solis" -> "la_county/supervisors/hilda-l-solis.jpg"
# "Eunisses Hernandez" -> "la_county/la_city_council/eunisses-hernandez.jpg"
# "Hugo Soto-Martinez" -> "la_county/la_city_council/hugo-soto-martinez.jpg"
```

Alternatively, config can specify `storage_filename` explicitly to override slug generation.

### Pattern 4: Content-Type Detection from URL
**What:** Detect MIME type from photo URL extension to pass correct `content_type` to `upload_photo_to_storage()`.
**When to use:** Source URLs may be .jpg, .png, or .webp.
**Example:**
```python
import mimetypes

def get_content_type(url):
    """Derive MIME type from URL extension. Default to image/jpeg."""
    # Strip query strings before extension detection
    clean_url = url.split("?")[0].split("#")[0]
    mime, _ = mimetypes.guess_type(clean_url)
    if mime and mime.startswith("image/"):
        return mime
    return "image/jpeg"  # Safe default for government photos

# kc-usercontent.com URLs: typically .jpg -> "image/jpeg"
# lacity.gov webp variants: "image/webp"
# Always upload as image/jpeg for consistency (or use actual MIME from response Content-Type header)
```

### Anti-Patterns to Avoid
- **Discovering photo URLs at runtime by scraping HTML of 15 different council sites:** Each site has different structure, CSS classes, and JavaScript rendering. Runtime discovery is fragile and breaks silently. Use hardcoded URLs in pipeline_config.json verified once.
- **Using UUID as the storage filename:** `{uuid}.jpg` is opaque — hard to debug in the Supabase bucket browser. Use name slug so `hilda-solis.jpg` is obvious.
- **Hotlinking the government URL in `politician_images.url`:** Defeats PHOTO-04. The DB must store the Supabase CDN URL, not the source URL.
- **Running without calling `init_ext_id_counter()`:** For this script, no new politicians are inserted (photos only) — so `next_ext_id()` is NOT needed. Don't call it.
- **Storing base64-encoded image in DB:** Never — images go to Supabase Storage, only CDN URL goes in DB.
- **Overwriting existing photos on re-run without checking:** Success Criterion 5 says don't overwrite non-empty existing photos. The upsert pattern should check for existing records. (Note: "overwrite" here means don't LOSE a previously scraped photo by inserting null — but updating a stale URL to a fresher CDN URL is acceptable.)

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Image upload to CDN | Custom multipart form or boto3 | `upload_photo_to_storage()` from utils.py | Phase 39 built and verified this; handles content-type, upsert, returns stable CDN URL |
| Config loading | json.load() inline in script | `load_pipeline_config()` from utils.py | Already exists; returns region-scoped config dict |
| Supabase auth | Manual header construction | `get_supabase_client()` from utils.py | Phase 39 built this; lazy import avoids requiring supabase package for DB-only scripts |
| Politician lookup | Complex JOIN query | Simple psycopg2 SELECT by full_name + title LIKE | Supervisors and council members already in DB from Phase 36; straightforward name lookup is sufficient |

**Key insight:** Phase 39 delivered all upload infrastructure. Phase 40's only new code is the scrape loop + psycopg2 upsert to `politician_images`. The script should be ~150 lines.

---

## Photo Sources — Verified

### LA County Supervisors (5 of 5 — direct download URLs verified)

All 5 supervisors have official high-resolution JPEG headshots available at:
`https://bos.lacounty.gov/official-photos/`

The page hosts files on the `assets-us-01.kc-usercontent.com` CDN with separate display (WebP) and download (JPG) versions. The download JPG URLs are stable permalinks.

| District | Name | Download URL | License |
|----------|------|-------------|---------|
| 1 | Hilda L. Solis | `https://assets-us-01.kc-usercontent.com:443/0234f496-d2b7-00b6-17a4-b43e949b70a2/be5432b1-336e-43d4-8678-9392c9d72bae/Supervisor%20Hilda%20Solis%202026.jpg` | scraped_no_license |
| 2 | Holly J. Mitchell | `https://assets-us-01.kc-usercontent.com:443/0234f496-d2b7-00b6-17a4-b43e949b70a2/cd9042fe-bb94-4e37-a92a-152fb844226e/Supervisor%20Holly%20J%20Mitchell%202024%201.jpg` | scraped_no_license |
| 3 | Lindsey P. Horvath | `https://assets-us-01.kc-usercontent.com:443/0234f496-d2b7-00b6-17a4-b43e949b70a2/9c9efa42-aec7-49aa-9659-0eb97db84081/Supervisor%20Lindsey%20Horvath.jpg` | scraped_no_license |
| 4 | Janice Hahn | `https://assets-us-01.kc-usercontent.com:443/0234f496-d2b7-00b6-17a4-b43e949b70a2/36c202cd-4e18-4e63-bd47-b3aca4f1c25a/Supervisor%20Janice%20Hahn.jpg` | scraped_no_license |
| 5 | Kathryn Barger | `https://assets-us-01.kc-usercontent.com:443/0234f496-d2b7-00b6-17a4-b43e949b70a2/b69f282e-2371-4783-937e-aca87240ef44/Supervisor%20Kathryn%20Barger%20official%20portrait%202020.jpg` | scraped_no_license |

**License note:** The page has no license statement. These are official government press photos published for public information use — assign `"scraped_no_license"` to track them honestly.

### LA City Council Members (15 — mixed availability)

Each council district maintains its own website (`cdN.lacity.gov`). Photo availability is **inconsistent** across districts. Research findings:

| District | Name | Photo Source | Status | Recommended License |
|----------|------|-------------|--------|---------------------|
| 1 | Eunisses Hernandez | cd1.lacity.gov — portrait img + Google Drive download | Available (img src; GDrive link) | scraped_no_license |
| 2 | Adrin Nazarian | cd2.lacity.gov — no dedicated headshot; action photos only | Needs alternate source | scraped_no_license |
| 3 | Bob Blumenfield | cd3.lacity.gov — no dedicated headshot, hero banner only | Needs alternate source | scraped_no_license |
| 4 | Nithya Raman | cd4.lacity.gov/press-kit/ — direct JPEG: `https://cd4.lacity.gov/wp-content/uploads/2023/10/A6013-189.jpg` | Available (press kit) | press_use |
| 5 | Katy Yaroslavsky | councildistrict5.lacity.gov — outdoor full-body; media request page exists | Partial (non-headshot) | scraped_no_license |
| 6 | Imelda Padilla | cd6.lacity.gov — portrait JPEG: `https://cd6.lacity.gov/wp-content/uploads/2024/03/photo-imelda-portrait-02.jpg` | Available (portrait) | scraped_no_license |
| 7 | Monica Rodriguez | cd7.lacity.gov — not fully checked | Unknown | scraped_no_license |
| 8 | Marqueece Harris-Dawson | cd8.lacity.gov — no photo found; Flickr album referenced | Needs alternate source | scraped_no_license |
| 9 | Curren D. Price Jr. | cd9.lacity.gov — not fully checked | Unknown | scraped_no_license |
| 10 | Heather Hutt | cd10.lacity.gov — not fully checked | Unknown | scraped_no_license |
| 11 | Traci Park | cd11.lacity.gov — webp image found (screenshot-based, non-ideal) | Partial | scraped_no_license |
| 12 | John Lee | cd12.lacity.gov — not fully checked | Unknown | scraped_no_license |
| 13 | Hugo Soto-Martinez | cd13.lacity.gov — not fully checked | Unknown | scraped_no_license |
| 14 | Ysabel J. Jurado | cd14.lacity.gov — webp hero image found (outdoor mural, not headshot) | Partial (non-headshot) | scraped_no_license |
| 15 | Tim McOsker | cd15.lacity.gov — not fully checked | Unknown | scraped_no_license |

**Important planning decision needed:** For districts 2, 3, 8 and others where cdN.lacity.gov does not have a clear headshot, alternative sources include:
1. Wikipedia Commons photos (CC-licensed, ideal if available — check `en.wikipedia.org/wiki/[Name]`)
2. Ballotpedia profile photos (ToS prohibits scraping — OUT OF SCOPE per REQUIREMENTS.md)
3. Official press releases on lacity.gov (may have embedded photos)
4. The planner/executor must verify each remaining council district and populate `pipeline_config.json` accordingly

**Recommendation for the plan:** The plan should include a Task 0 or verification step where the executor checks each of the 15 district sites and populates `pipeline_config.json` with verified URLs before the scraping loop runs. This is preferable to writing scraping code that might fail on missing photos.

---

## Common Pitfalls

### Pitfall 1: WebP Images Served as Lossless — Content-Type Must Match Reality
**What goes wrong:** Some council district sites serve images as `.webp` (e.g., Traci Park, Ysabel Jurado). The SDK default `content_type="image/jpeg"` would serve a WebP file with the wrong MIME type, breaking `<img>` tags in Safari.
**Why it happens:** `upload_photo_to_storage()` defaults to `image/jpeg`. WebP files must be uploaded with `image/webp`.
**How to avoid:** Check the `Content-Type` response header from `requests.get()` before calling `upload_photo_to_storage()`. Use that header value as `content_type`. Or: if the URL ends in `.webp`, pass `content_type="image/webp"`. Alternatively, convert all images to JPEG using Pillow before upload — but this adds a dependency.
**Warning signs:** Images display broken in Safari but work in Chrome (WebP support edge case).

### Pitfall 2: Politician Lookup by Name Fails for Scraped Officials
**What goes wrong:** `find_politician_id()` queries by `full_name ILIKE` but the scraped officials from Phase 36 may have slightly different name formats in the DB (e.g., "Katy Young Yaroslavsky" vs "Katy Yaroslavsky").
**Why it happens:** `scrape_la_officials.py` uses the name as-scraped from bos.lacounty.gov / clerk.lacity.gov. The fallback rosters in that file show the exact names stored in the DB.
**How to avoid:** Use the exact fallback roster names from `scrape_la_officials.py` as the lookup keys in `pipeline_config.json`. Cross-reference:
- FALLBACK_LA_COUNTY_SUPERVISORS: ["Hilda L. Solis", "Holly J. Mitchell", "Lindsey P. Horvath", "Janice Hahn", "Kathryn Barger"]
- FALLBACK_LA_CITY_COUNCIL: ["Eunisses Hernandez", "Adrin Nazarian", "Bob Blumenfield", "Nithya Raman", "Katy Young Yaroslavsky", "Imelda Padilla", "Monica Rodriguez", "Marqueece Harris-Dawson", "Curren D. Price Jr.", "Heather Hutt", "Traci Park", "John Lee", "Hugo Soto-Martinez", "Ysabel J. Jurado", "Tim McOsker"]
**Warning signs:** `find_politician_id()` returns None for a politician that definitely exists in the DB.

### Pitfall 3: kc-usercontent.com URLs Are CDN-Gated
**What goes wrong:** Supervisor photo URLs at `assets-us-01.kc-usercontent.com` are the county's Kentico CMS CDN. They may require specific `Referer` or `User-Agent` headers or serve 403 to non-browser clients.
**Why it happens:** Government CDNs sometimes check `Referer` header before serving files.
**How to avoid:** Pass `Referer: https://bos.lacounty.gov/` in the request headers alongside the browser User-Agent. If still blocked: use Playwright headless browser (already in requirements.txt as playwright==1.50.0) to download from within a browser context.
**Warning signs:** `requests.get()` returns 403 or 302 redirect to an error page.

### Pitfall 4: lacity.gov webp Variant URLs Need Full Domain Prefix
**What goes wrong:** Some council site images have relative paths: `/sites/g/files/wph2061/files/...`. The full URL must be constructed by prepending the site domain.
**Why it happens:** Web scraping extracts `src` attributes which may be relative or absolute. BeautifulSoup returns the `src` as-is.
**How to avoid:** Always pass the council member's domain (e.g., `https://cd1.lacity.gov`) to `urljoin(base_url, img_src)` when constructing the download URL.
**Warning signs:** `requests.get()` gets a path-only URL and returns 404 because no scheme/host is present.

### Pitfall 5: Duplicate politician_images Rows on Re-Run
**What goes wrong:** Re-running the script inserts a second `politician_images` row instead of updating the existing one.
**Why it happens:** The `politician_images` table has no UNIQUE constraint on `(politician_id, type)`. A naive INSERT would create duplicates.
**How to avoid:** Before INSERT, do a SELECT for existing `(politician_id, type='default')`. If found, do UPDATE; otherwise INSERT. Or add a UNIQUE constraint via GORM:
```go
// In models.go — add composite unique index
type PoliticianImage struct {
    ...
    PoliticianID uuid.UUID `gorm:"type:uuid;uniqueIndex:idx_pol_image_type,composite"`
    Type         string    `gorm:"uniqueIndex:idx_pol_image_type,composite"`
}
```
If the constraint is added, the Python script can use `INSERT ... ON CONFLICT (politician_id, type) DO UPDATE SET url = ..., photo_license = ...`.
**Warning signs:** Running the script twice results in doubled rows in `politician_images` for the same politician.

### Pitfall 6: Google Drive Download Links Require Special Handling
**What goes wrong:** Council District 1 (Hernandez) provides a Google Drive link for headshot download. `requests.get()` on a Google Drive URL redirects to a confirmation page rather than the file.
**Why it happens:** Google Drive forces a "download confirmation" for large files when accessed without a session cookie.
**How to avoid:** Use the direct img src URL instead of the Google Drive link. For CD1, the direct webp image at `https://cd1.lacity.gov/sites/g/files/wph2061/files/styles/portrait_medium_350x467_/public/2023-03/Eunisses_Hernandez_960x665.jpg` is the preferred target. Convert the URL from `.jpg.webp` endpoint to the underlying JPEG if needed.
**Warning signs:** requests.get() returns HTML content (a Google Drive page) instead of image bytes.

---

## Code Examples

Verified patterns from official sources:

### Full Scrape Loop (Core Logic)
```python
# Source: Pattern established in scrape_la_officials.py + Phase 39 utils.py

import sys
import requests
import psycopg2
import psycopg2.extras
from pathlib import Path
from urllib.parse import urlparse, urljoin
import re
import mimetypes

sys.path.insert(0, str(Path(__file__).parent))
from utils import load_env, load_supabase_env, upload_photo_to_storage

SUPERVISOR_STORAGE_PREFIX = "la_county/supervisors"
COUNCIL_STORAGE_PREFIX = "la_county/la_city_council"

def get_content_type_from_response(response):
    """Get MIME type from response Content-Type header."""
    ct = response.headers.get("Content-Type", "image/jpeg")
    # Strip parameters like "; charset=utf-8"
    return ct.split(";")[0].strip()

def make_slug(name):
    """'Holly J. Mitchell' -> 'holly-j-mitchell'"""
    return re.sub(r'[^a-z0-9]+', '-', name.lower()).strip('-')

def process_headshot(cur, config, storage_prefix):
    """Download and upload one headshot; upsert into politician_images.

    config: {
      "name": "Hilda L. Solis",
      "photo_url": "https://...",
      "photo_license": "scraped_no_license"
    }
    """
    name = config["name"]
    photo_url = config["photo_url"]
    photo_license = config.get("photo_license", "scraped_no_license")

    # 1. Find politician UUID
    politician_id = find_politician_id(cur, name)
    if not politician_id:
        print(f"  SKIP: {name} — not found in DB")
        return "skipped"

    # 2. Download image
    headers = {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
        "Referer": "https://bos.lacounty.gov/"  # Required for kc-usercontent.com CDN
    }
    response = requests.get(photo_url, headers=headers, timeout=15)
    response.raise_for_status()
    image_bytes = response.content
    content_type = get_content_type_from_response(response)

    # 3. Determine storage path
    storage_filename = config.get("storage_filename") or f"{make_slug(name)}.jpg"
    storage_path = f"{storage_prefix}/{storage_filename}"

    # 4. Upload to Supabase Storage (upsert=true handles re-runs)
    cdn_url = upload_photo_to_storage(image_bytes, storage_path, content_type)
    print(f"  Uploaded: {name} -> {cdn_url}")

    # 5. Upsert into politician_images
    action = upsert_politician_image(cur, politician_id, cdn_url, photo_license)
    print(f"  DB {action}: {name} (license={photo_license})")
    return action
```

### Idempotent DB Upsert
```python
def upsert_politician_image(cur, politician_id, cdn_url, photo_license):
    """Upsert politician image — update if exists, insert if not.

    Success Criterion 5: re-running does not create duplicate rows.
    """
    cur.execute("""
        SELECT id FROM essentials.politician_images
        WHERE politician_id = %s AND type = 'default'
        LIMIT 1
    """, (politician_id,))
    existing = cur.fetchone()

    if existing:
        cur.execute("""
            UPDATE essentials.politician_images
            SET url = %s, photo_license = %s
            WHERE id = %s
        """, (cdn_url, photo_license, existing["id"]))
        return "updated"
    else:
        cur.execute("""
            INSERT INTO essentials.politician_images
                (id, politician_id, url, type, photo_license)
            VALUES (gen_random_uuid(), %s, %s, 'default', %s)
        """, (politician_id, cdn_url, photo_license))
        return "inserted"
```

### Politician Lookup by Name + Title
```python
def find_politician_id(cur, full_name):
    """Lookup politician UUID by full_name (case-insensitive)."""
    cur.execute("""
        SELECT p.id
        FROM essentials.politicians p
        WHERE p.full_name ILIKE %s
          AND p.is_active = true
        ORDER BY p.last_synced DESC
        LIMIT 1
    """, (full_name,))
    row = cur.fetchone()
    return str(row["id"]) if row else None
```

### Pipeline Config Structure for Phase 40
```json
// Addition to pipeline_config.json la_county section
{
  "headshots": {
    "supervisors": [
      {"name": "Hilda L. Solis",    "district": 1, "photo_url": "https://assets-us-01.kc-usercontent.com:443/0234f496-d2b7-00b6-17a4-b43e949b70a2/be5432b1-336e-43d4-8678-9392c9d72bae/Supervisor%20Hilda%20Solis%202026.jpg", "photo_license": "scraped_no_license"},
      {"name": "Holly J. Mitchell", "district": 2, "photo_url": "https://assets-us-01.kc-usercontent.com:443/0234f496-d2b7-00b6-17a4-b43e949b70a2/cd9042fe-bb94-4e37-a92a-152fb844226e/Supervisor%20Holly%20J%20Mitchell%202024%201.jpg", "photo_license": "scraped_no_license"},
      {"name": "Lindsey P. Horvath","district": 3, "photo_url": "https://assets-us-01.kc-usercontent.com:443/0234f496-d2b7-00b6-17a4-b43e949b70a2/9c9efa42-aec7-49aa-9659-0eb97db84081/Supervisor%20Lindsey%20Horvath.jpg", "photo_license": "scraped_no_license"},
      {"name": "Janice Hahn",       "district": 4, "photo_url": "https://assets-us-01.kc-usercontent.com:443/0234f496-d2b7-00b6-17a4-b43e949b70a2/36c202cd-4e18-4e63-bd47-b3aca4f1c25a/Supervisor%20Janice%20Hahn.jpg", "photo_license": "scraped_no_license"},
      {"name": "Kathryn Barger",    "district": 5, "photo_url": "https://assets-us-01.kc-usercontent.com:443/0234f496-d2b7-00b6-17a4-b43e949b70a2/b69f282e-2371-4783-937e-aca87240ef44/Supervisor%20Kathryn%20Barger%20official%20portrait%202020.jpg", "photo_license": "scraped_no_license"}
    ],
    "la_city_council": [
      {"name": "Eunisses Hernandez",        "district": 1,  "photo_url": "TBD_VERIFY_cd1.lacity.gov",  "photo_license": "scraped_no_license"},
      {"name": "Adrin Nazarian",            "district": 2,  "photo_url": "TBD_no_headshot_found",       "photo_license": "scraped_no_license"},
      {"name": "Bob Blumenfield",           "district": 3,  "photo_url": "TBD_no_headshot_found",       "photo_license": "scraped_no_license"},
      {"name": "Nithya Raman",              "district": 4,  "photo_url": "https://cd4.lacity.gov/wp-content/uploads/2023/10/A6013-189.jpg", "photo_license": "press_use"},
      {"name": "Katy Young Yaroslavsky",    "district": 5,  "photo_url": "TBD_VERIFY_councildistrict5.lacity.gov", "photo_license": "scraped_no_license"},
      {"name": "Imelda Padilla",            "district": 6,  "photo_url": "https://cd6.lacity.gov/wp-content/uploads/2024/03/photo-imelda-portrait-02.jpg", "photo_license": "scraped_no_license"},
      {"name": "Monica Rodriguez",          "district": 7,  "photo_url": "TBD_VERIFY_cd7.lacity.gov",  "photo_license": "scraped_no_license"},
      {"name": "Marqueece Harris-Dawson",   "district": 8,  "photo_url": "TBD_check_wikipedia_flickr",  "photo_license": "scraped_no_license"},
      {"name": "Curren D. Price Jr.",       "district": 9,  "photo_url": "TBD_VERIFY_cd9.lacity.gov",  "photo_license": "scraped_no_license"},
      {"name": "Heather Hutt",              "district": 10, "photo_url": "TBD_VERIFY_cd10.lacity.gov", "photo_license": "scraped_no_license"},
      {"name": "Traci Park",               "district": 11, "photo_url": "TBD_VERIFY_cd11.lacity.gov", "photo_license": "scraped_no_license"},
      {"name": "John Lee",                  "district": 12, "photo_url": "TBD_VERIFY_cd12.lacity.gov", "photo_license": "scraped_no_license"},
      {"name": "Hugo Soto-Martinez",        "district": 13, "photo_url": "TBD_VERIFY_cd13.lacity.gov", "photo_license": "scraped_no_license"},
      {"name": "Ysabel J. Jurado",          "district": 14, "photo_url": "TBD_VERIFY_cd14.lacity.gov", "photo_license": "scraped_no_license"},
      {"name": "Tim McOsker",               "district": 15, "photo_url": "TBD_VERIFY_cd15.lacity.gov", "photo_license": "scraped_no_license"}
    ]
  }
}
```

---

## How the Frontend Consumes Photos (Confirmed)

The frontend uses `politician_images` rows through two code paths:

**Profile page** (`GET /essentials/politician/{id}`): The Go handler at `GetPoliticianByID` (handlers.go:1901) fetches `politician_images WHERE politician_id = ?` and returns them as `images: [{url, type}]`. The `PoliticianProfile` component in ev-ui renders the first `type=default` image as the headshot.

**Results/search page** (`GET /essentials/politicians/{zip}`): The handler at `fetchOfficialsFromDB` (handlers.go:1058) runs a batch query `FROM essentials.politician_images WHERE politician_id = ANY(?)` and returns them in `images[]` per politician. The `PoliticianCard` component checks `pol.images && pol.images.length > 0` and shows the first image, falling back to initials avatar if none.

**Conclusion:** Phase 40 only needs to write to `essentials.politician_images` with `type='default'` and a valid CDN URL. No Go backend changes needed. No frontend changes needed.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hotlinking from BallotReady/government URLs | Re-hosting to Supabase Storage CDN | Phase 40 (v1.7) | Eliminates link rot; government URLs break within 2-4 years |
| `photo_origin_url` field on politicians table | `politician_images.url` with `photo_license` | Phase 39 built the column | Normalized image table supports multiple photos per person + license tracking |
| No photo license tracking | `photo_license` column required on all new images | Phase 39 (v1.7 decision) | Legal compliance tracking before scraping at scale |

**Notes from scrape_la_officials.py:** The existing scraper has a `TODO` comment: "Photo re-hosting to Supabase Storage is planned but deferred. Currently storing photo_origin_url pointing to government site URLs." Phase 40 is the implementation of that deferred plan — but targets only the 20 high-value officials (not the full BallotReady sync).

---

## Open Questions

1. **LA City Council Districts 2, 3, 7, 8, 9, 10, 11, 12, 13, 15 — Photo Sources**
   - What we know: Individual district sites (cdN.lacity.gov) have inconsistent headshot availability; research checked 6 of 15
   - What's unclear: Districts 2, 3, 7, 8, 9, 10, 12, 13, 15 may have photos at `cdN.lacity.gov/press-kit/`, Wikipedia Commons, or accessible via img src scraping
   - Recommendation: Plan Wave 0 should be a manual verification task where executor fetches each remaining district site and adds confirmed photo URLs to `pipeline_config.json`. This is 15-30 minutes of manual lookup, not coding. The task should document the strategy: (a) check cdN.lacity.gov/press-kit/ first, (b) then cdN.lacity.gov homepage img src, (c) then Wikipedia article for that member's name.

2. **photo_license for Google Drive / Press Kit Downloads**
   - What we know: Some council members explicitly provide download links labeled "Download Headshot" (CD1) or "Press Kit" (CD4)
   - What's unclear: Whether Google Drive download links should be treated as `"press_use"` or `"scraped_no_license"`. A dedicated press kit implies intentional media availability.
   - Recommendation: Use `"press_use"` for URLs from explicitly labeled press kit pages (CD4 confirmed). Use `"scraped_no_license"` for all other government site images. This distinction satisfies PHOTO-05's licensing tracking intent.

3. **Unique constraint on politician_images (politician_id, type)**
   - What we know: No UNIQUE constraint exists; plain SELECT+INSERT/UPDATE is required for idempotency (Pitfall 5)
   - What's unclear: Whether adding the UNIQUE constraint via GORM AutoMigrate is worth doing in Phase 40 vs leaving for later
   - Recommendation: Add the constraint in Phase 40's Go model change (minimal effort, prevents future bugs). This enables ON CONFLICT DO UPDATE in Python for simpler idempotent upserts. However, it requires a server restart to apply via AutoMigrate — a minor coordination requirement.

4. **WebP images: convert to JPEG or upload as-is**
   - What we know: Some lacity.gov images are served as WebP (Traci Park, Ysabel Jurado). Pillow (not in requirements.txt) could convert to JPEG before upload.
   - What's unclear: Whether the frontend img tag handles WebP correctly in all target browsers (Safari <14 had no WebP support, but that is rare in 2026).
   - Recommendation: Upload images as-is with correct content_type. Do NOT add Pillow dependency. Modern browsers all support WebP. Content-Type must be set correctly (image/webp) to avoid MIME corruption.

5. **STATE.md blocker: photo_license review workflow**
   - What we know: STATE.md flags: "photo_license review workflow decision needed — serve 'scraped_no_license' images immediately or gate on manual review per city batch"
   - Resolution (locked in Phase 39 CONTEXT.md): "Track but don't block — record license type for every photo, but don't prevent storing photos without a clear license." This means `scraped_no_license` images should be served immediately (no gating). This blocker is already resolved.
   - Recommendation: No action needed. Use `scraped_no_license` freely; serve images immediately.

---

## Sources

### Primary (HIGH confidence)
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/utils.py` — confirmed upload_photo_to_storage(), load_pipeline_config(), load_supabase_env() all present and verified
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/requirements.txt` — supabase==2.28.0 confirmed
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/pipeline_config.json` — la_county region with 90 cities confirmed
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/models.go` — PoliticianImage.PhotoLicense field confirmed present
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/handlers.go` — GetPoliticianByID and fetchOfficialsFromDB photo query logic confirmed
- `/Users/chrisandrews/Documents/GitHub/essentials/src/components/PoliticianCard.jsx` — images[] fallback to initials avatar confirmed
- `/Users/chrisandrews/Documents/GitHub/.planning/phases/39-schema-and-infrastructure-preparation/39-02-SUMMARY.md` — Phase 39 complete, bucket verified, human checkpoint passed
- `https://bos.lacounty.gov/official-photos/` — all 5 supervisor photo URLs verified with direct kc-usercontent.com JPG download links (WebFetch confirmed)

### Secondary (MEDIUM confidence)
- `https://lacity.gov/directory#elected-officials` — all 15 council member names confirmed (WebFetch)
- `https://cd4.lacity.gov/press-kit/` — Nithya Raman JPEG press kit URL confirmed (WebFetch)
- `https://cd6.lacity.gov` — Imelda Padilla portrait JPEG URL confirmed (WebFetch)
- `https://cd1.lacity.gov/councilmember-hernandez` — Eunisses Hernandez img src confirmed (WebFetch); Google Drive download link available
- `https://cd11.lacity.gov` — Traci Park WebP image found (WebFetch); Flickr album referenced for better photos

### Tertiary (LOW confidence)
- Districts 2, 3, 7, 8, 9, 10, 12, 13, 15 photo availability — not verified; flagged for executor lookup in Wave 0

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all dependencies already in requirements.txt; no new installs needed
- Architecture: HIGH — upload pattern established in Phase 39, DB schema confirmed, API response flow confirmed
- Supervisor photo sources: HIGH — all 5 URLs directly verified via WebFetch
- Council photo sources: MEDIUM — 6 of 15 districts checked; remaining 9 need executor verification
- Pitfalls: HIGH — WebP MIME type, name matching, duplicate rows, and CDN gating are all real risks documented with evidence

**Research date:** 2026-02-24
**Valid until:** 2026-05-24 (government photo URLs stable; Supabase Storage API stable)
