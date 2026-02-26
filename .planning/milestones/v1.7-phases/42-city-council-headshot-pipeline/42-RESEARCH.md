# Phase 42: City Council Headshot Pipeline (89 Cities) - Research

**Researched:** 2026-02-25
**Domain:** Python web scraping, Supabase Storage batch upload, config-driven pipeline, Cloudflare detection
**Confidence:** HIGH

## Summary

Phase 42 extends the headshot pipeline established in Phase 40 to cover city council members across all 89 LA County cities (approximately 382 roster members: 89 mayors + 293 council members across 88 non-LA-City cities, plus 15 LA City council members already handled in Phase 40). The success criteria references "369 city council member headshot URLs" — this is the approximate DB count of active local council-tier politicians. The 80% threshold means roughly 295+ photos must return HTTP 200 from the Supabase CDN.

The primary technical challenge is scale: Phase 40 handled 20 known officials with pre-verified URLs. Phase 42 must process ~369 officials whose photo sources vary significantly city-to-city. Each city council has its own website with inconsistent HTML structure, anti-bot protections ranging from none to Cloudflare. The established approach from Phase 40 — config-driven photo URLs with Supabase Storage upload and idempotent psycopg2 upsert — scales directly to this problem. The key architectural decision is WHERE the photo URLs come from: the city council official sites stored in `city_sources.json` already provide one entry point per city.

The most realistic strategy to hit 80% coverage: add a `headshot_url` field to each roster entry in `city_sources.json` (or a separate `city_headshots_config.json`), populated by semi-automated scraping of each city's council member page. Wikipedia/Wikimedia Commons serves as a secondary source for officials who have articles. Cloudflare-protected sites (estimated 15-25% of 89 cities) are marked `"blocked"` rather than `"failed"` and skipped on re-run.

**Primary recommendation:** Write `scrape_city_headshots.py` that iterates through the 89-city roster from `city_sources.json`, visits each city's council URL to extract per-member headshot img src attributes, downloads images with a 1.5s inter-city rate limit, uploads to Supabase Storage under `la_county/cities/{city_id}/{name_slug}.jpg`, and upserts CDN URLs into `essentials.politician_images`. Cloudflare detection is based on HTTP 403/429 response with `cf-ray` response header. Use `requests` + `BeautifulSoup` as primary; `Playwright` headless as fallback for JS-heavy sites.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PHOTO-03 | User sees headshot photo for 80%+ of city council members across 89 LA County cities | Covered by: scrape_city_headshots.py iterates city_sources.json roster, extracts img src per member from city council pages, uploads to Supabase CDN, upserts into politician_images. Coverage validation via HEAD requests (success criterion 1) confirms 80%+ target. |
| PIPE-02 | Scraping respects rate limits with delays between requests | Covered by: 1.5s inter-city delay enforced in main loop (time.sleep), plus per-image delay. Cloudflare-blocked cities marked "blocked" and skipped on re-run so pipeline never retries known-blocked sites unnecessarily. |
</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| requests | 2.32.5 (pinned) | HTTP download of council pages and image bytes | Already in requirements.txt; used by all existing v1.7 scrapers |
| beautifulsoup4 | 4.12.3 (pinned) | HTML parsing to extract img src attributes from council member pages | Already in requirements.txt; used by scrape_city_councils.py |
| psycopg2-binary | 2.9.11 (pinned) | Direct DB lookup (politician_id by name) and upsert into politician_images | Already in requirements.txt; established pattern |
| supabase-py | 2.28.0 (pinned) | Supabase Storage upload via `upload_photo_to_storage()` from utils.py | Phase 39 delivered this; confirmed working |
| playwright | 1.50.0 (pinned) | Headless Chromium fallback for JS-rendered council pages | Already in requirements.txt; already used as fallback in scrape_city_councils.py |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| time (stdlib) | stdlib | Inter-city delay enforcement (1.5s minimum) | Used in main loop between cities |
| re (stdlib) | stdlib | Name slug generation, HTML attribute extraction | Storage filename and candidate filtering |
| urllib.parse (stdlib) | stdlib | Resolve relative image URLs to absolute | `urljoin(city_base_url, img_src)` |
| argparse (stdlib) | stdlib | CLI flags: --dry-run, --city, --resume, --limit | Standard for all v1.7 pipeline scripts |
| json (stdlib) | stdlib | Read/write city_sources.json with headshot status | In-place status tracking |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| BeautifulSoup + requests with Playwright fallback | Playwright-only for all cities | Playwright is slower (~3-5s/page vs ~0.5s for requests). Use requests first; only fall back to Playwright if content is < 500 chars (JS-heavy). Already the established pattern from scrape_city_councils.py |
| Adding headshot_url to city_sources.json entries | Separate city_headshots_config.json | city_sources.json is already the master city config; adding headshot_url fields inline keeps all city data in one file. Acceptable for 89 cities. However this file is 382 roster entries — adding per-member URLs could make it unwieldy. Alternative: add headshot_url directly to each roster member object in city_sources.json. |
| Per-member headshot_url in city_sources.json roster | Separate pipeline_config.json section similar to Phase 40 headshots | Phase 40 used pipeline_config.json for 20 officials. At 382 members, it still fits. Recommended: add a `city_council_headshots` section to pipeline_config.json keyed by city_id, mirroring the Phase 40 pattern. |
| Wikipedia Wikimedia Commons as primary source | City official websites as primary | Wikipedia has CC-licensed photos for roughly 10-20% of city council members (mostly higher-profile members of larger cities like Long Beach, Pasadena). City official sites cover the remaining 80%. Use city sites as primary, Wikipedia as supplementary fallback. |
| HEAD request coverage validation in-script | SQL COUNT of non-null photo_url | Success criterion 1 explicitly requires HEAD request check (not null-count SQL). Write a separate `check_coverage.py` script or include a `--check-coverage` flag in the main script. |

**Installation:** All packages already installed. No new dependencies needed for Phase 42.

---

## Architecture Patterns

### Recommended Project Structure
```
EV-Backend/scripts/
├── scrape_city_headshots.py     # NEW: Phase 42 — batch headshot scraper for 89 cities
├── city_sources.json            # MODIFY: add headshot_url per roster member
├── pipeline_config.json         # NO CHANGE (headshots section already has la_county structure)
├── utils.py                     # EXISTING: upload_photo_to_storage(), load_pipeline_config()
└── requirements.txt             # EXISTING: no changes needed
```

### Pattern 1: Per-City Scrape Loop with Cloudflare Detection
**What:** For each city, fetch the council page, detect Cloudflare blocking, extract headshot URLs per member, download and upload each image.
**When to use:** Core scrape loop in `scrape_city_headshots.py`.
**Example:**
```python
# Source: established pattern from scrape_city_councils.py + Phase 40 scrape_headshots.py

import time
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin

INTER_CITY_DELAY = 1.5  # seconds between cities (PIPE-02)
DOWNLOAD_DELAY = 0.5    # seconds between image downloads within a city
TIMEOUT = 15

BROWSER_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/121.0.0.0 Safari/537.36"
    )
}

def is_cloudflare_blocked(response):
    """Detect Cloudflare protection: HTTP 403/429 with cf-ray header."""
    if response.status_code in (403, 429, 503):
        if "cf-ray" in response.headers or "cloudflare" in response.headers.get("server", "").lower():
            return True
    return False

def fetch_council_page(url):
    """Fetch HTML of council page. Returns (html, used_playwright, blocked_reason).

    Returns (None, False, 'cloudflare') if Cloudflare detected.
    Returns (html, True, None) if Playwright was needed.
    Returns (html, False, None) on clean requests success.
    """
    try:
        resp = requests.get(url, headers=BROWSER_HEADERS, timeout=TIMEOUT)
        if is_cloudflare_blocked(resp):
            return None, False, "cloudflare"
        resp.raise_for_status()
        soup = BeautifulSoup(resp.text, "html.parser")
        if len(soup.get_text(strip=True)) > 500:
            return resp.text, False, None
    except requests.RequestException:
        pass

    # Playwright fallback for JS-heavy sites
    try:
        from playwright.sync_api import sync_playwright
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            page = browser.new_page()
            page.goto(url, timeout=30000)
            page.wait_for_load_state("networkidle", timeout=30000)
            html = page.content()
            browser.close()
        # Check for Cloudflare in Playwright response
        if "cf-ray" in html or "Checking your browser" in html:
            return None, True, "cloudflare"
        return html, True, None
    except Exception:
        return None, False, "fetch_failed"
```

### Pattern 2: Headshot Image Extraction from Council Page HTML
**What:** Given a council page HTML and a member name, find the most likely portrait image for that member.
**When to use:** Per-member image extraction loop.
**Example:**
```python
# Source: adapted from scrape_city_councils.py + scrape_la_officials.py patterns

import re
from bs4 import BeautifulSoup
from urllib.parse import urljoin

PORTRAIT_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
EXCLUDE_PATTERNS = re.compile(
    r"(logo|icon|banner|header|footer|background|bg-|pattern|seal|flag|map|arrow|chevron|search|menu)",
    re.I
)

def extract_headshot_url(html, member_name, city_url):
    """Extract best-candidate headshot URL for a council member.

    Strategy:
    1. Find elements containing member's last name
    2. Look for nearby img tags (within same parent/grandparent)
    3. Filter images: must have portrait-like dimensions (src contains portrait keywords),
       valid extension, and not match exclusion patterns
    4. Return absolute URL of best candidate, or None

    Returns: str (absolute URL) or None
    """
    soup = BeautifulSoup(html, "html.parser")
    last_name = member_name.strip().split()[-1].lower()

    # Strategy 1: Find name in text, look for nearby img
    name_els = soup.find_all(
        string=re.compile(re.escape(last_name), re.I)
    )
    for name_el in name_els:
        # Walk up to find containing block (card/row)
        container = name_el.parent
        for _ in range(4):  # look up to 4 levels
            if container is None:
                break
            imgs = container.find_all("img")
            for img in imgs:
                src = img.get("src", "")
                alt = img.get("alt", "")
                if not src:
                    continue
                ext = "." + src.rsplit(".", 1)[-1].lower().split("?")[0] if "." in src else ""
                if ext not in PORTRAIT_EXTENSIONS:
                    continue
                if EXCLUDE_PATTERNS.search(src) or EXCLUDE_PATTERNS.search(alt):
                    continue
                return urljoin(city_url, src)
            container = container.parent

    # Strategy 2: All portrait-like images on page, match by alt text
    for img in soup.find_all("img"):
        src = img.get("src", "")
        alt = img.get("alt", "").lower()
        if last_name in alt:
            ext = "." + src.rsplit(".", 1)[-1].lower().split("?")[0] if "." in src else ""
            if ext in PORTRAIT_EXTENSIONS and not EXCLUDE_PATTERNS.search(src):
                return urljoin(city_url, src)

    return None
```

### Pattern 3: Supabase Storage Path Convention for City Council Photos
**What:** Deterministic storage path following established Phase 40 naming convention.
**When to use:** All uploads in scrape_city_headshots.py.
**Example:**
```python
import re

def make_storage_path(city_id, member_name, extension="jpg"):
    """'burbank_city_council' + 'Jess Talamantes' -> 'la_county/cities/burbank/jess-talamantes.jpg'"""
    # Strip trailing '_city_council' from city_id
    city_slug = re.sub(r'_city_council$', '', city_id)
    name_slug = re.sub(r'[^a-z0-9]+', '-', member_name.lower()).strip('-')
    return f"la_county/cities/{city_slug}/{name_slug}.{extension}"

# Examples:
# city_id="burbank_city_council", name="Jess Talamantes" -> "la_county/cities/burbank/jess-talamantes.jpg"
# city_id="long_beach_city_council", name="Mary Zendejas" -> "la_county/cities/long_beach/mary-zendejas.jpg"
```

### Pattern 4: Politician Lookup by Name (Established from scrape_headshots.py)
**What:** Find politician UUID in essentials.politicians by full_name ILIKE.
**When to use:** Before uploading — must link photo to correct politician_id.
**Example:**
```python
def find_politician_id(cur, full_name):
    """Lookup politician UUID by full_name (case-insensitive).
    Returns UUID string or None.
    """
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

### Pattern 5: Per-City Status Tracking (Idempotent Re-runs)
**What:** Save scrape status per city so re-running skips completed cities and retries failed ones (but NOT Cloudflare-blocked cities).
**When to use:** Status written back to `city_sources.json` at end of each city's processing.
**Status values:**
- `"scraped"` — completed successfully; skip on re-run
- `"failed"` — error (network, parse, etc.); retry on re-run
- `"blocked"` — Cloudflare or other anti-bot blocking detected; SKIP on re-run (not retried)
- `null` / missing — not yet processed; process on run

**Example:**
```python
# After processing each city:
if blocked:
    city_config["headshot_status"] = "blocked"
    city_config["headshot_blocked_reason"] = "cloudflare"
elif success:
    city_config["headshot_status"] = "scraped"
    city_config["headshot_scraped_at"] = datetime.now().isoformat()
    city_config["headshot_count"] = uploaded_count
else:
    city_config["headshot_status"] = "failed"
    city_config["headshot_failure_reason"] = failure_reason

# In main loop:
if city_config.get("headshot_status") in ("scraped", "blocked"):
    print(f"  Skipping {city_name} (status={city_config['headshot_status']})")
    skipped_count += 1
    continue
```

### Anti-Patterns to Avoid
- **Marking Cloudflare-blocked cities as "failed" and retrying them:** Cloudflare 403 on re-run wastes time and burns delay budget. The success criteria explicitly require blocked cities to be marked "blocked" and skipped on re-run.
- **Inter-city delay less than 1.5 seconds:** PIPE-02 requires 1 city per 1.5 seconds ON AVERAGE. Individual city scrapes may take longer; the delay is a floor, not a cap.
- **Storing source URL (city website) in politician_images.url instead of CDN URL:** Always upload to Supabase Storage first, then store the CDN URL. Government photo URLs break silently.
- **Re-using the existing `scrape_headshots.py`:** Phase 40's script is designed for 20 known officials with hardcoded URLs. Phase 42 needs a different script that auto-discovers URLs from council pages. Write `scrape_city_headshots.py` as a new file.
- **Calling `next_ext_id()` in the headshot script:** This script does NOT create new politicians — it only adds photos to existing records. Do not import or call `next_ext_id()`.
- **Global transaction across all cities:** Each city must commit independently (per-city COMMIT). A failure in one city should not roll back previous successes. Established pattern from `scrape_city_councils.py`.
- **Applying Phase 40's `find_politician_id()` directly:** Phase 40 searched by full_name only. Phase 42 should additionally accept fuzzy matching (Levenshtein distance ≤ 1 on last name) because city council member names from the roster may have slight formatting differences from what the scraper extracts from HTML.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Image upload to Supabase CDN | Custom multipart or boto3 | `upload_photo_to_storage()` from utils.py | Phase 39 built and verified this; handles content-type, upsert, returns stable CDN URL |
| Config loading | `json.load()` inline | `load_pipeline_config()` from utils.py | Already exists; returns region-scoped config |
| Supabase authentication | Manual header construction | `get_supabase_client()` from utils.py | Lazy import avoids requiring supabase package for DB-only invocations |
| Playwright headless fallback | Custom subprocess call to chromium | `playwright.sync_api.sync_playwright()` | Already in requirements.txt; pattern already in scrape_city_councils.py |
| Fuzzy name matching | Custom edit-distance function | `rapidfuzz.distance.Levenshtein.distance()` | Already in requirements.txt; used in scrape_city_councils.py |
| Relative URL resolution | String concatenation | `urllib.parse.urljoin(base, src)` | Handles edge cases (leading /, relative paths, absolute URLs) |
| Coverage validation HEAD requests | SQL COUNT(photo_url IS NOT NULL) | `requests.head(cdn_url)` in a validation loop | Success criterion 1 explicitly requires HTTP 200 response check, not null count |

**Key insight:** The full upload + DB upsert infrastructure already exists. The only new code needed is: (1) per-city HTML fetching with Cloudflare detection, (2) per-member image extraction heuristic, (3) coverage validation script. The actual upload/upsert pattern is copied from scrape_headshots.py.

---

## Common Pitfalls

### Pitfall 1: Cloudflare Misclassification
**What goes wrong:** City returns HTTP 403 for a different reason (IP block, missing auth, expired session) and gets marked "blocked" — but it's actually a transient failure that would succeed on retry.
**Why it happens:** Distinguishing Cloudflare from other 403s requires checking the `cf-ray` response header or `server: cloudflare` header. A simple status-code check will false-positive on non-Cloudflare 403s.
**How to avoid:** Check BOTH the status code (403/429/503) AND the presence of `cf-ray` header or `"cloudflare"` in the `server` header. If 403 without cf-ray, mark as "failed" (not "blocked") so it retries.
**Warning signs:** Cities with permanent `failed` status that work fine when visited in a browser.

### Pitfall 2: Image Extraction Selects Logo/Icon Instead of Portrait
**What goes wrong:** `extract_headshot_url()` returns the city logo, a navigation icon, or a banner image instead of a council member portrait.
**Why it happens:** Council pages often have many images; the name-proximity heuristic may find the wrong image if the DOM structure places the member name far from the portrait.
**How to avoid:** Apply filtering on image characteristics: (a) minimum size hints from HTML `width`/`height` attributes (> 80px); (b) filename patterns that suggest portraits (`portrait`, `headshot`, `photo`, `member`, `council`, `photo-*`, UUID patterns); (c) explicit exclusion of logo/icon/banner patterns in src and alt attributes. Accept false-negatives (returning None) over false-positives (returning wrong image).
**Warning signs:** Profile pages show a city logo instead of a person's photo.

### Pitfall 3: Same Image Returned for All Members of a City
**What goes wrong:** The extraction heuristic finds one image for the first member and returns the same URL for all members of that city.
**Why it happens:** Many council pages use a grid layout where the same image container is found regardless of which name we're searching for. The "nearby image" heuristic picks the first image in the grid every time.
**How to avoid:** After extracting URLs for all members of a city, check for duplicates: if all extracted URLs are identical, they are likely wrong (most cities don't use the same photo for all members). In that case, mark the entire city as needing manual review or fall back to an alternative source.
**Warning signs:** Multiple council members have identical CDN URLs in politician_images.

### Pitfall 4: Content-Type Mismatch on Upload
**What goes wrong:** Image bytes are uploaded to Supabase Storage with wrong MIME type (`image/jpeg` for a WebP file), causing browser rendering failures especially in Safari.
**Why it happens:** `upload_photo_to_storage()` default is `image/jpeg`. WebP images from city sites need `image/webp`.
**How to avoid:** Always derive content_type from the download response `Content-Type` header (established in scrape_headshots.py Phase 40 decision): `content_type = resp.headers.get("Content-Type", "image/jpeg").split(";")[0].strip()`. Default to `"image/jpeg"` if missing or not `image/*`.
**Warning signs:** Images broken in Safari but visible in Chrome.

### Pitfall 5: Politician Name Mismatch Between Roster and DB
**What goes wrong:** `find_politician_id()` returns None for a council member who exists in the DB because the scraper extracted a slightly different name format (e.g., "Jess Talamantes Jr" vs "Jess Talamantes Jr.").
**Why it happens:** city_sources.json roster uses names from the CA Secretary of State PDF; the DB stores names from that same source, but special characters like periods, middle initials, and suffixes may differ slightly.
**How to avoid:** Use Levenshtein fuzzy matching on last name (threshold ≤ 1) as a fallback after exact ILIKE match fails. `rapidfuzz` is already in requirements.txt and used in `scrape_city_councils.py`.
**Warning signs:** `find_politician_id()` returns None for known officials.

### Pitfall 6: Rate Limit Burns on Cloudflare Cities
**What goes wrong:** Script retries a Cloudflare-blocked city multiple times (or on every re-run), wasting the 1.5s delay budget and adding noise to logs.
**Why it happens:** Without persistent "blocked" status in the config, every run re-attempts all cities including confirmed blocked ones.
**How to avoid:** Write `headshot_status: "blocked"` to `city_sources.json` after first detection. Main loop skips cities with `headshot_status in ("scraped", "blocked")`. This is the exact same idempotency pattern from `scrape_city_councils.py` where completed cities get `"status": "scraped"`.
**Warning signs:** Log shows the same cities being attempted repeatedly across re-runs.

### Pitfall 7: DB Connection Lost Mid-Run (89+ Cities)
**What goes wrong:** psycopg2 connection times out or goes idle mid-run (some Supabase poolers close idle connections after ~5 minutes), causing silent failures for later cities.
**Why it happens:** 89 cities at 1.5s average = ~2.2 minutes minimum, but image downloads and Playwright fallbacks can push total run time to 15-30 minutes. Supabase direct connection (port 5432) has better stability than the pooler.
**How to avoid:** Use the direct connection (port 5432), not the pooler (port 6543). Apply `connection.autocommit = False` and commit after each city (not global). If connection error occurs, attempt reconnect once before marking city as failed. Same pattern as `scrape_city_councils.py`.
**Warning signs:** Later cities in the run fail with `psycopg2.OperationalError: connection closed`.

---

## Code Examples

Verified patterns from official sources:

### Full Main Loop with Rate Limiting and Status Tracking
```python
# Source: adapted from scrape_city_councils.py pattern (Phase 37)

import json, time, sys
from datetime import datetime
from pathlib import Path

def main():
    load_env()
    load_supabase_env()

    config_path = Path(__file__).parent / "city_sources.json"
    with open(config_path) as f:
        config = json.load(f)
    cities = config["cities"]

    conn = get_connection()
    conn.autocommit = False

    processed = 0
    skipped = 0
    blocked = 0
    failed = 0
    total_uploaded = 0

    prev_city_time = None

    for i, city_config in enumerate(cities):
        city_name = city_config["name"]
        status = city_config.get("headshot_status")

        # Skip completed or blocked cities (idempotent re-run)
        if status in ("scraped", "blocked"):
            skipped += 1
            continue

        # Enforce inter-city rate limit (PIPE-02: 1 city per 1.5s average)
        if prev_city_time is not None:
            elapsed = time.time() - prev_city_time
            if elapsed < 1.5:
                time.sleep(1.5 - elapsed)
        prev_city_time = time.time()

        success, upload_count, failure_reason = process_city(conn, city_config)

        if failure_reason == "cloudflare":
            city_config["headshot_status"] = "blocked"
            city_config["headshot_blocked_reason"] = "cloudflare"
            blocked += 1
        elif success:
            city_config["headshot_status"] = "scraped"
            city_config["headshot_scraped_at"] = datetime.now().isoformat()
            city_config["headshot_count"] = upload_count
            total_uploaded += upload_count
            processed += 1
        else:
            city_config["headshot_status"] = "failed"
            city_config["headshot_failure_reason"] = failure_reason
            failed += 1

    # Save updated status back to city_sources.json
    config["cities"] = cities
    with open(config_path, "w") as f:
        json.dump(config, f, indent=2)

    conn.close()
    print(f"\nProcessed: {processed} | Skipped: {skipped} | Blocked: {blocked} | Failed: {failed}")
    print(f"Total headshots uploaded: {total_uploaded}")
```

### Idempotent DB Upsert (Reused from scrape_headshots.py)
```python
# Source: established pattern from Phase 40 scrape_headshots.py

def upsert_politician_image(cur, politician_id, cdn_url, photo_license):
    """Upsert politician headshot into essentials.politician_images.

    Checks for existing (politician_id, type='default') row.
    If exists: UPDATE url and photo_license.
    If not: INSERT new row.

    Returns: "updated" or "inserted"
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

### Coverage Validation (HEAD Request Check)
```python
# Source: Required by PHOTO-03 Success Criterion 1 (HEAD request, not null-count SQL)

import requests

def check_coverage(cur):
    """Validate headshot coverage via HEAD requests to Supabase CDN.

    Fetches all politician_images.url values for LOCAL/LOCAL_EXEC politicians
    in LA County, issues HEAD requests, counts HTTP 200 responses.

    Returns (covered_count, total_count, coverage_pct)
    """
    cur.execute("""
        SELECT DISTINCT pi.url
        FROM essentials.politician_images pi
        JOIN essentials.politicians p ON p.id = pi.politician_id
        JOIN essentials.offices o ON o.politician_id = p.id
        JOIN essentials.districts d ON o.district_id = d.id
        WHERE pi.type = 'default'
          AND pi.url LIKE '%supabase%'
          AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
          AND d.state = 'CA'
          AND p.is_active = true
        LIMIT 600
    """)
    rows = cur.fetchall()
    total = len(rows)
    ok = 0
    for row in rows:
        url = row["url"]
        try:
            resp = requests.head(url, timeout=5, allow_redirects=True)
            if resp.status_code == 200:
                ok += 1
        except requests.RequestException:
            pass
        time.sleep(0.1)  # 100ms between HEAD requests

    pct = (ok / total * 100) if total > 0 else 0
    return ok, total, pct
```

### Cloudflare Detection
```python
# Source: Based on documented Cloudflare response characteristics

def classify_http_failure(response):
    """Return 'cloudflare', 'http_error', or 'ok' based on response."""
    if response.status_code in (403, 429, 503):
        server = response.headers.get("server", "").lower()
        has_cf_ray = "cf-ray" in response.headers
        has_cf_server = "cloudflare" in server
        if has_cf_ray or has_cf_server:
            return "cloudflare"
        return "http_error"
    return "ok"
```

---

## Scope and Data Model

### What cities are in scope for Phase 42?
The `city_sources.json` contains **89 cities** (all LA County incorporated cities except City of Los Angeles). Each city has a `roster` array with member objects (role: Mayor or Council Member). Total roster entries: ~382 (89 mayors + 293 council members).

City of Los Angeles (15 council members) was handled in **Phase 40** and is NOT re-processed here.

### Target headshot count
The success criteria references "369 city council member headshot URLs" — this is the approximate DB count of active LOCAL/LOCAL_EXEC politicians across the 89 cities in scope. The 80% threshold = ~295 successful HEAD-request validations needed.

### Storage path structure
```
politician-photos/          # Supabase Storage bucket (created Phase 39)
├── la_county/
│   ├── supervisors/        # Phase 40: 5 supervisors
│   ├── la_city_council/    # Phase 40: 15 LA City council members
│   └── cities/             # Phase 42: NEW
│       ├── burbank/
│       │   ├── jess-talamantes.jpg
│       │   └── ...
│       ├── long_beach/
│       └── ...
```

### Database writes
Only `essentials.politician_images` is written to. The matching key is `(politician_id, type='default')`. Politician records themselves are NOT modified (no new politicians inserted — they already exist from Phase 37 scrape_city_councils.py).

### No Go backend changes needed
The existing `fetchOfficialsFromDB` and `GetPoliticianByID` handlers already query `politician_images` and return `images[]` in the API response. Writing a CDN URL to `politician_images` automatically makes it appear in the frontend profile and search results. Phase 42 is purely a data pipeline phase — zero Go or React changes needed.

---

## Phase Plan Structure

Based on the scope and established Phase 40 two-plan pattern (plan 1 = build config + script, plan 2 = execute + verify), Phase 42 warrants **two plans**:

**42-01-PLAN.md** (autonomous): Build `scrape_city_headshots.py` script and add headshot status fields to `city_sources.json`.
- Build the scraper with Cloudflare detection, BeautifulSoup extraction, Playwright fallback
- Add `headshot_url` fields to `city_sources.json` for cities where URLs can be statically pre-populated (this may be feasible for the 10-15 largest cities with well-structured council pages)
- Verify script syntax and dry-run behavior

**42-02-PLAN.md** (human checkpoint required): Execute the scraper, verify DB results, validate coverage.
- Run `python3 scrape_city_headshots.py` (or in batches)
- Run coverage check: HEAD requests confirm 80%+ CDN URLs return HTTP 200
- Human verifies a sample of profile pages show headshots
- Document which cities were blocked vs scraped vs failed

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| BallotReady headshots (Phase B) — hotlinked from BallotReady CDN | Re-hosted to Supabase Storage CDN | Phase 40 (v1.7) | Eliminates link rot; government photo URLs break within 2-4 years |
| 20 officials with hardcoded URLs (Phase 40) | 369 officials via automated page scraping (Phase 42) | Phase 42 (v1.7) | Scales headshot coverage from ~5% to 80%+ of LA County local officials |
| photo_origin_url on politicians table | politician_images.url with photo_license | Phase 39-40 | Normalized image table; license tracking |

---

## Open Questions

1. **Coverage achievability: can 80% be hit via automated scraping alone?**
   - What we know: 89 cities, each with a council URL in city_sources.json. Photo availability varies widely. Small cities (Bradbury, Rolling Hills, Hidden Hills — populations < 5,000) may not publish individual council member photos on their websites.
   - What's unclear: What percentage of the 89 cities have parseable member portraits on their council pages? Based on scrape_city_councils.py experience, ~75-80% of cities provided usable roster data from their websites. Photo extraction will have a lower yield (not all pages with names also have portraits).
   - Recommendation: Plan for ~65-75% automated coverage from city sites. For the remaining ~5-15% needed to hit 80%, use Wikipedia/Wikimedia Commons as fallback for members of larger, higher-profile cities (Long Beach, Pasadena, Glendale, etc.) where Wikipedia articles exist.

2. **Should phase 42 also add Wikipedia fallback lookups?**
   - What we know: Phase 40 successfully used Wikipedia Commons for 13/15 LA City council members (CC-licensed, stable URLs). The same approach works for any council member with a Wikipedia article.
   - What's unclear: What percentage of 369 city council members have Wikipedia articles with portrait photos? Rough estimate: 10-20% of council members in the largest 20 cities (Long Beach has 9 districts, Pasadena has 7, etc.).
   - Recommendation: Include Wikipedia as a fallback source in `scrape_city_headshots.py`. After the primary city-site scrape returns None for a member, attempt a Wikipedia lookup using the member's full name. If a portrait exists, use it with `photo_license = "cc_by_sa_4.0"`. This is a modest code addition (the Wikipedia URL pattern is already established in scrape_headshots.py) that could contribute 20-40 additional headshots and meaningfully improve coverage.

3. **Status field naming: add to city_sources.json or a separate file?**
   - What we know: `city_sources.json` already tracks `status` (roster scrape) and `last_scraped` per city. Adding `headshot_status`, `headshot_scraped_at`, `headshot_count`, `headshot_blocked_reason` is consistent with the existing pattern.
   - What's unclear: Whether adding these new status fields to the 89-city objects would make the file too noisy.
   - Recommendation: Add headshot status fields directly to each city object in `city_sources.json`. This keeps all per-city state in one file and matches the established `scrape_city_councils.py` pattern exactly.

4. **Should per-member headshot URLs be stored in city_sources.json roster?**
   - What we know: Phase 40 stored photo_url per politician in pipeline_config.json. City_sources.json roster objects have name, district, party, role, data_source.
   - What's unclear: Whether storing `headshot_url` per-member in city_sources.json is the right approach vs purely dynamically scraping at runtime.
   - Recommendation: Store `headshot_url` per-member in city_sources.json roster entries. This allows: (a) pre-populating for well-known cities; (b) manual overrides when scraping fails; (c) idempotent re-runs that skip members with existing headshot_url; (d) auditing which URLs came from which source. The file is already used as the single source of truth for city council data.

---

## Sources

### Primary (HIGH confidence)
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/city_sources.json` — 89 cities, 382 roster members, all with council URLs
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/scrape_headshots.py` — Phase 40 upload/upsert pattern confirmed working
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/scrape_city_councils.py` — Playwright fallback, per-city commit, status tracking, Levenshtein matching already implemented
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/utils.py` — upload_photo_to_storage(), load_pipeline_config(), upsert patterns confirmed
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/requirements.txt` — requests, beautifulsoup4, playwright, psycopg2-binary, supabase, rapidfuzz all pinned and installed
- `/Users/chrisandrews/Documents/GitHub/.planning/phases/40-high-value-headshots-supervisors-la-city-council/40-RESEARCH.md` — Phase 40 headshot patterns (content-type detection, idempotent upsert, Cloudflare handling)
- `.planning/STATE.md` — Phase 41 complete; all infrastructure confirmed working

### Secondary (MEDIUM confidence)
- Cloudflare detection via `cf-ray` header: documented behavior, consistent across Cloudflare CDN deployments (widely verified in scraping community)
- Wikipedia coverage estimate (10-20% of council members in large cities): based on Phase 40 LA City experience where 13/15 council members had Wikipedia articles

### Tertiary (LOW confidence)
- Estimated 65-75% automated photo coverage from city websites: extrapolated from scrape_city_councils.py coverage (~75-80% of cities had parseable roster data); photo extraction will have lower yield. Actual coverage unknown until script runs.
- Cloudflare prevalence in LA county city websites: estimated 15-25% based on general municipal website patterns; not verified per-city.

---

## Validation Architecture

The config.json does not have `nyquist_validation` set to true (key absent). Skipping formal test framework section per instructions.

Coverage validation for this phase is manual + script-based:
- `python3 scrape_city_headshots.py --check-coverage` (or separate `check_headshot_coverage.py`)
- Runs HEAD requests against all Supabase CDN URLs in `politician_images` for LOCAL/LOCAL_EXEC politicians
- Reports percentage returning HTTP 200
- Phase gate: 80%+ required before marking Phase 42 complete

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all dependencies confirmed installed; no new packages needed
- Architecture: HIGH — upload/upsert/status tracking patterns established and verified in Phases 39-40-41
- Image extraction heuristic: MEDIUM — name-proximity strategy is sound but yield is unknown until tested; real coverage TBD
- Cloudflare prevalence: LOW — estimated 15-25% from general knowledge; actual count unknown until script runs
- 80% coverage achievability: MEDIUM — likely achievable with city sites + Wikipedia fallback, but depends on city website structure quality

**Research date:** 2026-02-25
**Valid until:** 2026-05-25 (Supabase Storage API stable; city council URLs from city_sources.json stable; Cloudflare detection mechanism stable)
