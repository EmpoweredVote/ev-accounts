# Phase 64: Headshot Upload & Coverage Validation - Research

**Researched:** 2026-03-06
**Domain:** Python upload pipeline — Supabase Storage CDN, psycopg2 DB upsert, CSV-driven batch processing, coverage validation
**Confidence:** HIGH — all findings verified directly against existing project code

## Summary

Phase 63 produced a complete `headshot_research_manifest.csv` with 246 `found` rows, each containing a `politician_id` (UUID) and a direct `found_url`. Phase 64 is entirely a data-pipeline phase: read the CSV, download each image, upload to Supabase Storage, upsert the CDN URL into `essentials.politician_images`, then run `coverage_report.py` to confirm 80%+ coverage. No new framework, no new dependencies — the full stack already exists in `EV-Backend/scripts/`.

The upload pipeline infrastructure was built in v1.7 (`scrape_city_headshots.py`, `utils.py`). Phase 64 needs a new script — call it `upload_manifest_headshots.py` — that replaces the HTML scraping step with CSV reading, reusing all other pieces: `download_image()`, `upload_photo_to_storage()`, `upsert_politician_image()`, `make_storage_path()`. No fuzzy name matching is needed because `politician_id` UUIDs are already in the manifest.

The manifest contains 246 unique `politician_id` values — zero duplicates confirmed. Of the 246 found URLs: 222 are direct government/city URLs, 24 are Wayback Machine `im_` URLs (direct image bytes, not HTML pages). The upload script must handle both download patterns. The coverage check is already implemented in `coverage_report.py --check 1`.

**Primary recommendation:** Write `upload_manifest_headshots.py` that reads `headshot_research_manifest.csv`, downloads each `found_url`, uploads to `politician-photos` bucket at `la_county/cities/{city_slug}/{name_slug}.{ext}`, upserts into `essentials.politician_images`, then run `coverage_report.py` to confirm 80%+ pass.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PHOTO-03 | All sourced headshots uploaded to Supabase Storage CDN | `upload_photo_to_storage()` in `utils.py` is the exact pattern; `PHOTO_BUCKET = "politician-photos"` already verified to exist (Phase 39) |
| PHOTO-04 | politician_images database records updated for all newly sourced headshots | `upsert_politician_image()` in `scrape_city_headshots.py` handles INSERT/UPDATE by (politician_id, type='default'); reuse verbatim with politician_id from manifest |
| PHOTO-05 | Coverage validation report confirms 80%+ headshot coverage for LA County local officials | `coverage_report.py --check 1` queries Supabase CDN URLs and issues HEAD requests; passes at 80% threshold; already handles `LOCAL`/`LOCAL_EXEC`/`COUNTY` + `state='CA'` filter |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| psycopg2 | 2.x (project standard) | PostgreSQL connection for upsert | All existing scripts use this pattern |
| requests | 2.x (project standard) | Download images from found_url | Used in `download_image()` already |
| supabase-py | 2.x (project standard) | `get_supabase_client()` for Storage upload | `upload_photo_to_storage()` in `utils.py` wraps this |
| csv (stdlib) | 3.13 | Read headshot_research_manifest.csv | DictReader pattern already in project |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| pathlib (stdlib) | 3.13 | File path resolution | All scripts use `Path(__file__).parent` |
| time (stdlib) | 3.13 | Inter-download delay (0.5s) | Matches `DOWNLOAD_DELAY = 0.5` from scraper |
| re (stdlib) | 3.13 | `make_storage_path()` slugification | Copy verbatim from scraper |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| New upload script | Modify `scrape_city_headshots.py` | Too much coupling to city-scraping logic; cleaner to write a focused manifest-reader |
| Direct psycopg2 | SQLAlchemy | psycopg2 is the project standard for batch scripts |

**Installation:** No new dependencies. All required packages are already in the scripts `.venv`.

## Architecture Patterns

### Script Structure
```
EV-Backend/scripts/
├── upload_manifest_headshots.py  # NEW: Phase 64 upload pipeline
├── headshot_research_manifest.csv   # Phase 63 output — input to Phase 64
├── coverage_report.py               # Existing — run --check 1 at end
├── utils.py                         # Existing — load_env, load_supabase_env, upload_photo_to_storage, get_supabase_client
└── scrape_city_headshots.py         # Existing — reference for download_image, upsert_politician_image, make_storage_path
```

### Pattern 1: CSV-driven batch upload with --dry-run and idempotent upsert
**What:** Read `headshot_research_manifest.csv`, filter `research_status == 'found'`, download image from `found_url`, upload to Supabase CDN, upsert into `essentials.politician_images`.
**When to use:** This is the sole pattern for this phase.
**Example:**
```python
# Source: scrape_city_headshots.py (download_image, upsert_politician_image, make_storage_path)

import csv
import time
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from utils import load_env, load_supabase_env, upload_photo_to_storage

DOWNLOAD_DELAY = 0.5  # seconds between downloads — matches scraper constant

def run_upload(manifest_path, dry_run=False):
    load_env()
    load_supabase_env()
    conn = get_connection()  # psycopg2, port 5432 (not 6543 pooler)
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)

    rows = [r for r in csv.DictReader(open(manifest_path)) if r['research_status'] == 'found']
    print(f"Found {len(rows)} rows to upload")

    ok, skip, fail = 0, 0, 0
    for i, row in enumerate(rows):
        politician_id = row['politician_id']
        found_url = row['found_url']
        city_id = row['city_id']
        member_name = row['member_name']

        # Download
        try:
            image_bytes, content_type = download_image(found_url)
        except Exception as e:
            print(f"  FAIL download: {member_name} — {e}")
            fail += 1
            continue

        ext = content_type_to_ext(content_type)
        storage_path = make_storage_path(city_id, member_name, ext)

        if dry_run:
            print(f"  DRY-RUN: {member_name} -> {storage_path}")
            ok += 1
            continue

        # Upload
        cdn_url = upload_photo_to_storage(image_bytes, storage_path, content_type)

        # Upsert
        action = upsert_politician_image(cur, politician_id, cdn_url, "scraped_no_license")
        conn.commit()
        print(f"  {action}: {member_name} -> {cdn_url}")
        ok += 1

        if i < len(rows) - 1:
            time.sleep(DOWNLOAD_DELAY)

    cur.close()
    conn.close()
    print(f"\nDone: {ok} uploaded, {fail} failed")
```

### Pattern 2: Wayback Machine URLs — same `download_image()` works
**What:** Wayback Machine `im_` URLs (24 of 246) serve raw image bytes directly (not HTML). The existing `download_image()` function handles these identically to direct URLs — HTTP GET with browser User-Agent, content-type from response header.
**Evidence:** All 24 Wayback URLs in the manifest use the `im_` notation (e.g., `https://web.archive.org/web/20241102103128im_/https://...`). The `im_` modifier tells Wayback to return the raw resource, not the archived HTML page. No special handling needed.

### Pattern 3: photo_license classification
**What:** Determine license string per URL type.
**Rule:**
```python
if "wikimedia.org" in found_url or "wikipedia.org" in found_url:
    photo_license = "cc_by_sa_4.0"
else:
    photo_license = "scraped_no_license"
```
Source: `scrape_city_headshots.py` lines 926-929 — verbatim copy.

### Pattern 4: Coverage validation
**What:** After all uploads complete, run `coverage_report.py --check 1` for the official CDN health check.
**Command:**
```bash
cd EV-Backend/scripts
python3 coverage_report.py --check 1
```
This issues HEAD requests to all Supabase CDN URLs for `LOCAL`/`LOCAL_EXEC`/`COUNTY` + `state='CA'` politicians, reports percentage, exits 0 if >= 80%.

### Anti-Patterns to Avoid
- **Using port 6543 (pooler):** Causes "prepared statement already exists" on bulk inserts. Always use port 5432 (direct connection).
- **Fuzzy name matching:** The manifest has `politician_id` UUIDs — use them directly. No ILIKE/Levenshtein needed.
- **Base64-encoding image bytes:** `upload_photo_to_storage()` requires raw bytes, not base64. Passing base64-encoded data corrupts the stored file.
- **Missing content-type:** The Supabase SDK defaults to `text/plain` if content-type is omitted. Always pass the explicit MIME type from the response header.
- **Committing per-batch instead of per-row:** Use `conn.commit()` after each successful upsert to isolate failures. Do not wrap all uploads in one transaction.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Supabase Storage upload | Custom HTTP PUT to storage API | `upload_photo_to_storage()` in `utils.py` | Handles upsert=true, content-type, public URL extraction |
| DB upsert for politician_images | Custom INSERT ... ON CONFLICT | `upsert_politician_image()` in `scrape_city_headshots.py` | Handles UPDATE vs INSERT correctly, proven idempotent |
| Storage path generation | Custom path scheme | `make_storage_path()` in `scrape_city_headshots.py` | Consistent with existing v1.7 uploads; same slug format |
| Coverage validation | Custom HEAD request loop | `coverage_report.py --check 1` | Already implemented, exits 0/1, handles 80% threshold |
| Image download | Custom requests wrapper | `download_image()` in `scrape_city_headshots.py` | Handles User-Agent, 403 retry with Referer, content-type extraction |

**Key insight:** `scrape_city_headshots.py` already contains every function needed. Phase 64 replaces only the HTML-scraping step with CSV reading — everything else is copied verbatim.

## Common Pitfalls

### Pitfall 1: Wayback Machine URL edge cases
**What goes wrong:** Some Wayback URLs may return 404 (archive removed) or redirect to an HTML page instead of raw image if the `im_` modifier is stripped.
**Why it happens:** Wayback archive availability changes; 24 Wayback URLs were recorded months ago.
**How to avoid:** Run `--dry-run` first to test all downloads without writing to DB. Any that fail HTTP are logged; manually verify the few failures before writing a not-found note.
**Warning signs:** `download_image()` raises `requests.HTTPError` with 404 or `content_type` is `text/html` (not `image/*`). The `download_image()` function already handles this: it falls back if `content_type` doesn't start with `image/`.

### Pitfall 2: Government URLs that 403-block direct download
**What goes wrong:** Some city URLs that returned images during browser research return 403 when downloaded by a script (no session cookie, no JavaScript execution).
**Why it happens:** Some government CDNs check Referer headers or require browser sessions.
**How to avoid:** `download_image()` already retries with `Referer: {domain}/` on 403. For persistent failures, manually download and re-upload — there are at most a handful.
**Warning signs:** `requests.HTTPError: 403` on the retry attempt.

### Pitfall 3: Duplicate uploads overwriting existing CDN records
**What goes wrong:** Some politicians already have `politician_images` rows from v1.7 batch scraping. Overwriting them with Phase 64 URLs is intentional (better quality research URLs), but the `upsert_politician_image()` function updates the URL for existing rows.
**Why it happens:** By design — `upsert=true` in Supabase Storage and UPDATE in the DB upsert.
**How to avoid:** No action needed; overwriting is correct. The manifest only contains politicians who were missing headshots at manifest generation time, but a few may have gotten headshots from other imports since then. This is safe.

### Pitfall 4: coverage_report.py Check 2 fails for unrelated reasons
**What goes wrong:** `coverage_report.py` runs three checks. Check 2 (contact websites, 89 cities) and Check 3 (zero hotlinks) may fail due to pre-existing issues unrelated to Phase 64.
**Why it happens:** Check 2 and 3 were part of v1.7 milestones and may have known non-zero state.
**How to avoid:** Run only `coverage_report.py --check 1` for the Phase 64 gate. Check 1 is the CDN health percentage check that maps directly to PHOTO-05. Checks 2 and 3 are out of scope.

### Pitfall 5: politician_id as UUID string vs object
**What goes wrong:** `politician_id` in the CSV is a UUID string (e.g., `5604c5ae-d10d-4ca3-920d-dd3592278777`). psycopg2 accepts UUID strings as `%s` parameters but the existing `upsert_politician_image()` function was written for the case where `find_politician_id()` returns a string. Pass `row['politician_id']` directly — no cast needed.
**Warning signs:** `DataError: invalid input syntax for type uuid` if accidentally passing a truncated or malformed UUID.

## Code Examples

Verified patterns from existing project code:

### Supabase Storage upload (from utils.py)
```python
# Source: EV-Backend/scripts/utils.py — upload_photo_to_storage()
PHOTO_BUCKET = "politician-photos"

def upload_photo_to_storage(image_bytes, storage_path, content_type="image/jpeg"):
    client = get_supabase_client()
    # upsert=true: overwrite on re-upload (same CDN URL — stable)
    client.storage.from_(PHOTO_BUCKET).upload(
        storage_path,
        image_bytes,
        {"content-type": content_type, "upsert": "true"},
    )
    return client.storage.from_(PHOTO_BUCKET).get_public_url(storage_path)
```

### DB upsert for politician_images (from scrape_city_headshots.py)
```python
# Source: EV-Backend/scripts/scrape_city_headshots.py — upsert_politician_image()
def upsert_politician_image(cur, politician_id, cdn_url, photo_license):
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

### Storage path generation (from scrape_city_headshots.py)
```python
# Source: EV-Backend/scripts/scrape_city_headshots.py — make_storage_path()
import re

def make_storage_path(city_id, member_name, extension="jpg"):
    # "burbank_city_council" -> "burbank"
    city_slug = re.sub(r"_city_council$", "", city_id)
    name_slug = re.sub(r"[^a-z0-9]+", "-", member_name.lower()).strip("-")
    return f"la_county/cities/{city_slug}/{name_slug}.{extension}"
```

### Image download (from scrape_city_headshots.py)
```python
# Source: EV-Backend/scripts/scrape_city_headshots.py — download_image()
def download_image(url, timeout=15, referer=None):
    headers = dict(BROWSER_HEADERS)
    if referer:
        headers["Referer"] = referer

    resp = requests.get(url, headers=headers, timeout=timeout)

    # Retry with Referer on 403
    if resp.status_code == 403 and not referer:
        from urllib.parse import urlparse
        parsed = urlparse(url)
        domain_referer = f"{parsed.scheme}://{parsed.netloc}/"
        retry_headers = dict(BROWSER_HEADERS)
        retry_headers["Referer"] = domain_referer
        resp = requests.get(url, headers=retry_headers, timeout=timeout)

    resp.raise_for_status()

    raw_ct = resp.headers.get("Content-Type", "image/jpeg")
    content_type = raw_ct.split(";")[0].strip()
    if not content_type.startswith("image/"):
        content_type = "image/jpeg"

    return resp.content, content_type
```

### Coverage validation (from coverage_report.py)
```bash
# Source: EV-Backend/scripts/coverage_report.py
cd EV-Backend/scripts
python3 coverage_report.py --check 1
# Exit 0 = PASS (>=80% CDN URLs return HTTP 200)
# Exit 1 = FAIL
```

### Environment setup
```bash
# Source: EV-Backend/scripts/utils.py — load_env() + load_supabase_env()
# .env.local must contain:
DATABASE_URL=postgresql://...    # port 5432 (direct, not 6543 pooler)
SUPABASE_URL=https://....supabase.co
SUPABASE_SERVICE_KEY=eyJ...      # service role key (bypasses RLS)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| BallotReady API for headshots | Supabase Storage CDN + manual research | v1.5/v1.7 | Self-hosted images, no third-party dependency |
| Fuzzy name matching for DB lookup | Direct UUID from manifest `politician_id` | Phase 63 | No ambiguity, no fallback logic needed |
| city_sources.json roster-driven scraping | CSV manifest-driven upload | Phase 64 | Simpler pipeline; research phase already validated URLs |

**Deprecated/outdated:**
- `find_politician_id()` with Levenshtein fallback: Not needed in Phase 64. Manifest has `politician_id` UUIDs directly.
- `extract_headshot_url()` / `fetch_council_page()`: Not needed. Research already done; URLs are in the CSV.

## Open Questions

1. **Will all 246 direct-URL downloads succeed?**
   - What we know: 222 direct URLs from government sites, 24 Wayback `im_` URLs. Recorded days to weeks ago.
   - What's unclear: Some government CDNs may block script downloads even though the browser found them. This is unknowable until attempted.
   - Recommendation: Run `--dry-run` first to test all downloads. Track failures. For persistent failures, fall back to manual download + script upload with a `--file` flag, OR accept a small number of failures (the 80% target has ~49-politician headroom above 246 found).

2. **Does the 80% threshold apply to the 304-politician manifest universe or the full 391-politician DB population?**
   - What we know: `coverage_report.py --check 1` queries the full `LOCAL`/`LOCAL_EXEC`/`COUNTY` CA active politician population in DB (not the manifest). Per STATE.md: "Current coverage: target 80%+ of 391 politicians." The pre-existing v1.7 batch already uploaded ~84 headshots (21.5% base coverage). Adding 246 new uploads brings the total to ~330, which is ~84% of 391.
   - What's unclear: The exact current DB count of pre-existing Supabase headshots — it was ~84 at manifest generation but could have changed.
   - Recommendation: The math strongly favors passing: 246 new + ~84 existing = ~330/391 = ~84%. Run the check and it should pass.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual script execution + coverage_report.py |
| Config file | none — script-based validation |
| Quick run command | `python3 coverage_report.py --check 1` |
| Full suite command | `python3 coverage_report.py` (all 3 checks) |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PHOTO-03 | All sourced headshots accessible via Supabase CDN URL | smoke | `python3 coverage_report.py --check 1` | Yes |
| PHOTO-04 | politician_images rows exist for all uploaded headshots | integration | SQL: `SELECT COUNT(*) FROM essentials.politician_images WHERE type='default' AND url LIKE '%supabase%'` (compare before/after) | Yes (via psql/DB query) |
| PHOTO-05 | Coverage report confirms 80%+ headshot coverage | smoke | `python3 coverage_report.py --check 1` exits 0 | Yes |

### Sampling Rate
- **Per upload batch:** Review stdout for any `FAIL download` or `ERROR` lines
- **Phase gate:** `python3 coverage_report.py --check 1` exits 0 before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `EV-Backend/scripts/upload_manifest_headshots.py` — the new upload pipeline script; covers PHOTO-03, PHOTO-04

*(coverage_report.py already exists and covers PHOTO-05)*

## Sources

### Primary (HIGH confidence)
- `EV-Backend/scripts/scrape_city_headshots.py` — `download_image()`, `upsert_politician_image()`, `make_storage_path()`, `upload_photo_to_storage()` call patterns verified by direct code read
- `EV-Backend/scripts/utils.py` — `upload_photo_to_storage()`, `load_supabase_env()`, `PHOTO_BUCKET` verified by direct code read
- `EV-Backend/scripts/coverage_report.py` — all 3 checks, SQL queries, 80% threshold verified by direct code read
- `EV-Backend/scripts/generate_headshot_manifest.py` — `politician_id` UUID column confirmed, manifest schema verified
- `EV-Backend/scripts/headshot_research_manifest.csv` — 304 rows, 246 found, 58 not_found, 0 duplicates confirmed by direct count
- `EV-Backend/internal/essentials/models.go` — `PoliticianImage` struct confirmed: `(id, politician_id, url, type, photo_license)`
- `.planning/STATE.md` — Phase 63 final status: 246 found (80%), manifest ready for upload pipeline

### Secondary (MEDIUM confidence)
- `.planning/phases/63-headshot-research-sprint/63-VERIFICATION.md` — confirms 246 found URLs are valid HTTPS, all have politician_id

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries and patterns verified directly in project code
- Architecture: HIGH — `upload_manifest_headshots.py` design directly derived from `scrape_city_headshots.py` patterns
- Pitfalls: HIGH — derived from observed behaviors in Phase 63 context and code review; Wayback URL behavior verified by manifest URL inspection
- Coverage math: MEDIUM — 246 new + ~84 existing = ~84% estimate; exact pre-existing count depends on live DB state

**Research date:** 2026-03-06
**Valid until:** 2026-04-06 (stable — infrastructure already in place, no external API changes possible)
