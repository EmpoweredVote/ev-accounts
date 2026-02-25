# Pitfalls Research

**Domain:** Politician data enrichment — headshot scraping, building photos, contact info, term data, bios, education, experience; civic tech scraping pipeline for ~389 LA County officials
**Researched:** 2026-02-24
**Confidence:** HIGH (image hosting/hotlinking — verified against mySociety PopIt issue tracker + Pixsy), HIGH (California copyright law — verified against EFF + CA Legislature records), HIGH (anti-bot/JS-rendered pages — verified against Playwright docs + city-scrapers project patterns), MEDIUM (Supabase Storage image pitfalls — verified against Supabase docs + community discussions), MEDIUM (contact info staleness — verified against city-scrapers project learnings + codebase history), LOW (coverage regression detection — pattern reasoning from v1.6 deduplication experience)

---

## Critical Pitfalls

### Pitfall 1: Hotlinking Government Headshots Instead of Re-hosting Them — Photos Disappear Without Warning

**What goes wrong:**
The v1.6 pipeline stores `photo_origin_url` pointing directly at government website image URLs (e.g., `https://bos.lacounty.gov/wp-content/uploads/2021/11/hilda-solis.jpg`). The profile page renders these hotlinked URLs as `<img src>`. Government websites redesign frequently — typically within 2-4 years — and when they do, image paths change or directories are restructured. The image URLs break silently: the `<img>` tag renders a broken image icon with no error logged, no monitoring alert, and no way to know which of the 389 officials is now missing a headshot unless a human clicks every profile.

Beyond redesigns, some government IT departments explicitly block hotlinking by checking the HTTP `Referer` header. A Guatemalan government website case documented in mySociety's PopIt tracker shows the server returns `403 Forbidden` with message "The owner of this website does not allow hotlinking to that resource" — a completely silent failure from the browser's perspective. City of LA currently does not block hotlinking, but this can change with any Cloudflare policy update.

**Why it happens:**
The v1.6 TODO comment in `scrape_la_officials.py` (line 29-33) explicitly deferred photo re-hosting: "Photo re-hosting to Supabase Storage is planned but deferred. Currently storing photo_origin_url pointing to government site URLs." The scraping pipeline was built for names and districts first; image hosting was scoped out of v1.6. v1.7 adds headshot scraping — if it repeats the same deferral pattern, photos will be scraped and stored as hotlinked URLs, creating a fragile dependency on 89 different city websites staying structurally stable forever.

**How to avoid:**
Download every scraped headshot at scrape time and upload it to a Supabase Storage bucket during the Python pipeline run. Do not store government image URLs as the canonical source in `essentials.politician_images`. Store the Supabase CDN URL as `photo_url` (the field `essentials.politician_images.photo_url` is already used by BallotReady photos) and keep `photo_origin_url` as audit metadata only — never render it directly.

```python
import httpx
from supabase import create_client

def download_and_upload_headshot(photo_url, politician_id, supabase_client):
    """Download headshot from government site; upload to Supabase Storage."""
    resp = httpx.get(photo_url, timeout=15, follow_redirects=True)
    resp.raise_for_status()

    content_type = resp.headers.get("content-type", "image/jpeg")
    # Derive extension from content type
    ext = "jpg" if "jpeg" in content_type else content_type.split("/")[-1]
    path = f"headshots/{politician_id}.{ext}"

    supabase_client.storage.from_("politician-photos").upload(
        path=path,
        file=resp.content,
        file_options={"content-type": content_type, "upsert": "true"}
    )
    return supabase_client.storage.from_("politician-photos").get_public_url(path)
```

When Supabase Storage upload fails (network error, invalid MIME type), log the failure and store `photo_origin_url` as the fallback — but flag the record for manual review. Never silently proceed without a CDN URL when image persistence is a stated milestone goal.

**Warning signs:**
- Profile pages show broken image icons for some officials but not others — different government websites failing at different times
- `essentials.politician_images` rows where `photo_url` contains `bos.lacounty.gov`, `cityofburbank.net`, or any city domain rather than a Supabase CDN URL
- `last_synced` on politician records is recent but `photo_url` still points to a government domain
- HTTP 403 response when the backend (Go) tries to fetch `photo_origin_url` for a validity check

**Phase to address:**
Headshot scraping pipeline design phase — before writing a single line of image URL storage. The Supabase Storage bucket must exist and upload logic must be implemented in the first scraper, not treated as a follow-up task. The v1.6 TODO in `scrape_la_officials.py` must be resolved before the v1.7 enrichment scraper is merged.

---

### Pitfall 2: JavaScript-Rendered City Council Pages Return Empty HTML to requests — Scraper Misreports 0 Officials Found

**What goes wrong:**
Approximately 20-30% of California city government websites use JavaScript frameworks (React, Vue, or CMS platforms like Granicus, Municode, CivicPlus) that render content client-side. A `requests.get()` + `BeautifulSoup` scrape of these pages returns the shell HTML with zero council member names — the content div is present but empty. The scraper's count check (`len(officials) == expected_count`) reports a mismatch, falls back to... nothing, because unlike `scrape_la_officials.py` which has hardcoded fallbacks for 21 specific officials, there is no fallback for 89 city websites. The city is marked `status: "failed"` in `city_sources.json` and skipped on re-runs.

The `scrape_city_councils.py` script already has a Playwright fallback (`fetch_html_with_fallback`) that triggers when `len(body_text) < 500`. This works for pages with a minimal HTML shell, but fails for pages that return a full HTML document (5KB+) with meaningful-looking content that is actually JavaScript placeholders — the `body_text > 500` guard never triggers Playwright fallback.

**Why it happens:**
The Playwright fallback threshold is byte-count-based (`len(body_text) > 500`), not content-quality-based. A page template with navigation, footer, and placeholder `<div id="council-members"></div>` will pass the `> 500` threshold but return no member names. The scraper then runs `parse_generic_council_page` on empty content, returns 0 results, and the city fails. This is the difference between "empty page" and "populated page" — the scraper cannot currently distinguish them.

**How to avoid:**
Replace the byte-count threshold with a content-quality check: after BeautifulSoup parsing, look for at least 2 person-like name patterns (two capitalized words adjacent, typical of "First Last" format) in the body text. If fewer than 2 name patterns are found, trigger the Playwright path regardless of body length:

```python
import re

def looks_like_has_names(html):
    """Return True if HTML appears to contain rendered person names."""
    soup = BeautifulSoup(html, "html.parser")
    body_text = soup.get_text()
    # Look for at least 2 adjacent capitalized word pairs (likely names)
    name_matches = re.findall(r'\b[A-Z][a-z]{1,15}\s+[A-Z][a-z]{1,20}\b', body_text)
    return len(name_matches) >= 2

def fetch_html_with_fallback(url, timeout=15):
    html = ""
    try:
        resp = requests.get(url, headers=HEADERS, timeout=timeout)
        resp.raise_for_status()
        html = resp.text
        if looks_like_has_names(html):
            return html, False
    except Exception as e:
        print(f"    requests failed: {e}")
    # Fall back to Playwright
    ...
```

Additionally: identify JS-rendered cities during the source config build phase (before scraping) by manually checking 10 random cities. Mark them `"fetch_method": "playwright"` in `city_sources.json` so the scraper skips `requests` entirely for known JS sites.

**Warning signs:**
- `process_city` returns `False` with reason "No roster data (SOS PDF empty, website failed)" for cities that visibly have council pages
- Playwright is never triggered during a full run (counter stays at 0) despite known CivicPlus cities in the roster
- City council page renders correctly in a browser but `requests.get` + `BeautifulSoup(html).get_text()` contains headings but no names
- `city_sources.json` `failure_reason` field shows "Website parse returned 0 officials" for 15+ cities

**Phase to address:**
Headshot + contact scraping pipeline design phase — before running the batch enrichment scraper for all 89 cities. Validate the fetch quality on a sample of 10 cities (2 known-JS, 8 static) before running the full pipeline. Known JS-heavy platforms: Granicus, CivicPlus, Municode.

---

### Pitfall 3: Cloudflare and Rate Limiting on City Websites Cause Transient Failures Misreported as Permanent Failures

**What goes wrong:**
Several LA County city websites (the v1.6 `scrape_school_boards.py` noted "District websites universally blocked by Cloudflare") run behind Cloudflare Bot Management. A scraping run that hits 89 city websites sequentially without rate limiting will trigger Cloudflare's bot detection on some of them — typically the larger cities with more traffic. The scraper receives HTTP 403 or a Cloudflare challenge page (200 status code with a JS challenge body). The city gets marked `status: "failed"` in `city_sources.json` and is permanently skipped on reruns due to the `if city_config.get("status") == "scraped"` skip guard — except for failures, which are retried but often hit the same Cloudflare block since the IP hasn't changed.

The issue compounds with `photo_origin_url` scraping: downloading 5+ images from the same city domain in rapid succession triggers rate limiting even on sites that allow scraping, because image servers have lower rate limits than HTML pages.

**Why it happens:**
The existing scraper has no rate limiting between city requests (`time.sleep()` is absent from `scrape_city_councils.py`). The `fetch_html_with_fallback` function adds a Playwright fallback, but Playwright headless Chromium is detectable by Cloudflare's browser fingerprinting — `navigator.webdriver` is exposed unless specifically patched. Most importantly: there is no distinction between "permanently blocked" (429 Too Many Requests, 403 from Cloudflare) and "server error" (500, 503) in the retry logic.

**How to avoid:**
Add a minimum delay between city requests: `time.sleep(2)` between cities, `time.sleep(0.5)` between images from the same city. Use randomized delays (`random.uniform(1.5, 3.5)`) to avoid fingerprinting based on request cadence. Add exponential backoff retry logic for HTTP 429 and 503 responses (max 3 retries with 5s, 15s, 45s waits).

For Cloudflare-protected sites specifically: use `playwright-stealth` to patch the headless browser fingerprint before any page navigation. If stealth Playwright is still blocked, fall back to the SOS PDF data already loaded in `city_sources.json` for name data — accept that contact info and headshots won't be available for Cloudflare-protected sites rather than burning time on bypasses.

```python
import time, random

for city_config in cities:
    # ... process city
    time.sleep(random.uniform(1.5, 3.5))  # Between cities

# When downloading images from the same city:
for i, photo_url in enumerate(photo_urls):
    if i > 0:
        time.sleep(0.5)  # Between images from same domain
    download_image(photo_url)
```

**Warning signs:**
- Multiple cities from the same geographic area fail simultaneously (same Cloudflare edge node blocking the scraper IP)
- HTTP 403 response body contains "Cloudflare" in the HTML title or meta description
- `city_sources.json` failure_reason for 5+ cities reads "403 Client Error" or "Challenge page returned"
- Playwright successfully loads the page but the rendered content shows a "checking your browser" message
- Image download failures cluster by city domain (all images from `cityofburbank.net` fail, but not `cityofpasadena.net`)

**Phase to address:**
Scraping pipeline implementation phase — rate limiting and retry logic must be in the initial implementation, not added after Cloudflare blocks start appearing. Add a 72-hour "blocked" cooldown: if a city returns 429/403, mark it `status: "blocked"` rather than `status: "failed"`, and add a `retry_after` timestamp. Only reattempt after the cooldown.

---

### Pitfall 4: Contact Info Scraping Returns Stale Data — Phone Numbers and Emails Silently Outdated

**What goes wrong:**
City council member contact info (phone numbers, email addresses, office addresses) changes frequently: after elections (new members, new district assignments), after office reorganizations, and when members leave. A scraper run captures contact info that is current at scrape time. If the database is not refreshed, users see outdated phone numbers and dead email addresses that bounce — damaging trust in the platform without any visible error.

The existing pipeline has `last_synced` timestamps on politician records but no corresponding TTL enforcement for the enrichment fields (contact info, headshots, bio). Once scraped, these fields persist indefinitely in `essentials.politicians` and related tables. A city council election in November could render 30% of contact info stale by January, with no mechanism to detect or surface this.

**Why it happens:**
The scraping pipeline is designed as a one-time gap-fill operation, not a recurring refresh system. The `status: "scraped"` field in `city_sources.json` permanently marks cities as done, causing them to be skipped on re-runs. This is appropriate for name/seat data (seat changes are tracked by `is_active` flag) but incorrect for contact info (which can change without a seat change — same person, new phone number).

**How to avoid:**
Separate the enrichment data TTL from the seat occupancy TTL. Treat contact info (phone, email, website) and headshots as having a 90-day freshness window — the same TTL used for BallotReady cache warmers in the existing system. Add a `contact_synced_at` timestamp to the relevant tables. The pipeline should re-scrape contact info for any record where `contact_synced_at` is older than 90 days, regardless of `status: "scraped"`.

For the v1.7 milestone specifically: after elections (November 2026, March 2026 primary), run the enrichment scraper as a refresh pass with `--force-refresh-contact` flag to bypass the `status: "scraped"` skip guard for contact fields while keeping name/seat data stable.

Add a data freshness indicator to profile pages: "Contact info last updated: [date]" — this sets user expectations and makes staleness visible rather than hidden.

**Warning signs:**
- User reports that a phone number goes to voicemail for a different council member
- `last_synced` on `essentials.politicians` is > 90 days old but contact fields are actively displayed
- Post-election: `essentials.politicians` records show is_active=true for officials who lost their seat (name scraper ran, but contact info for the new member was never scraped)
- `city_sources.json` shows all 89 cities as `status: "scraped"` — no city will ever be re-scraped for contact refreshes

**Phase to address:**
Contact info storage design phase — before writing a single contact field to the database. Decide the refresh cadence and implement `contact_synced_at` tracking upfront. Do not build a system where data freshness is invisible.

---

### Pitfall 5: Image Licensing Ambiguity for State and Local Government Photos — Contractor-Taken Photos Are Not Public Domain

**What goes wrong:**
Federal government works are unambiguously public domain under 17 U.S.C. § 105. State and local government works in California are NOT automatically public domain — this is a common misconception in civic tech. Under California law (Government Code § 6254.9), state agencies can claim copyright in their works. Cities and counties can also copyright materials they produce, unlike the federal government.

The practical implication: a professional headshot taken by a photographer hired by the City of Burbank and published on burbank.ca.gov may be copyrighted by the photographer (work for hire → city owns copyright, city can restrict use). Scraping and hosting that photo in a Supabase bucket and serving it via a commercial civic tech platform constitutes reproduction and distribution of a potentially copyrighted work.

The 2016 California AB 2880 debate clarified that CA governments were already asserting copyright on some works — the bill would have expanded this; it was amended but not to protect against copyright. California city websites routinely include Terms of Use language like "All content on this site is the property of the City of [X] and may not be reproduced without permission."

**Why it happens:**
Developers familiar with federal government data (Congress, FEC, PACER) assume the same public domain rules apply to city websites. They do not. The lavote.gov scraper already in the codebase uses "EmpoweredVote-Scraper/1.0" as the User-Agent — this identifies the scraper but provides no license notice. Scraping + re-hosting photos without a license assessment is done quickly during prototyping and never revisited.

**How to avoid:**
Use a licensed source for headshots wherever available. Priority order:
1. **Wikimedia Commons** — Politician photos available under CC BY-SA or public domain. Search `commons.wikimedia.org` for each official by name. Coverage is ~60-70% for prominent LA County officials (supervisors, LA City Council), lower for smaller cities.
2. **Official government press releases / media kits** — Many city websites have a "Newsroom" or "Media" section with explicitly downloadable photos labeled "for press use." This is implicit license for reproduction.
3. **Scraped without explicit license** — Store `photo_origin_url` only; flag for legal review before moving to CDN. Do not serve at scale.

Add a `photo_license` field to `essentials.politician_images`: `"public_domain"`, `"cc_by"`, `"cc_by_sa"`, `"press_use"`, `"scraped_no_license"`. Only serve photos where `photo_license != "scraped_no_license"` in production until legal review is complete.

**Warning signs:**
- City website Terms of Use page contains "All rights reserved" or "may not be reproduced without written permission"
- Photo URL path contains `/wp-content/uploads/` suggesting the city hired a photographer (WordPress CMS)
- No `alt` text or caption on city website photo indicating it's from an external photographer's portfolio
- `photo_origin_url` points to a city domain but Wikimedia Commons search finds no image for the same official

**Phase to address:**
Headshot sourcing design phase — before scraping begins. Build the `photo_license` field into the schema. Check Wikimedia Commons first for every official batch before attempting city website scraping. For officials not on Wikimedia Commons: check city media kits and press rooms. Only scrape city websites as a last resort, with explicit `photo_license: "scraped_no_license"` flagging.

---

### Pitfall 6: Term and Election Date Data Is Inconsistent Across Sources — Year vs. Full Date, Different Epoch Conventions

**What goes wrong:**
Term data from different sources uses incompatible formats. The lavote.gov scraper captures `year_elected` as a bare year string ("2024"). The CA Secretary of State PDF provides term start dates in some columns and election years in others. City websites may show "Elected November 2022, Term expires December 2026" or "2022-2026" or just "Term: 4 years" with no actual date. Some cities show the date of the election; others show the date the member was sworn in; others show the date the term ends.

When these fields are stored in `essentials.politicians` (current schema has `term_start`, `term_end` as nullable date columns), inconsistent inputs produce a mix of NULL, year-only strings stored as "2024-01-01" (with arbitrary month/day), and correctly formatted dates. The frontend's `formatTermDate()` helper in ev-ui formats all dates, so "2024-01-01" displays as "Jan 2024" — which looks correct but is wrong (the actual swearing-in was December 2022).

**Why it happens:**
The existing `lavote_scraper.py` captures `year_elected` as a string from table cells that contain year-only data. The `scrape_la_officials.py` main upsert doesn't touch `term_start` or `term_end` at all — these fields are left NULL for gap-filled politicians. v1.7 will add this data, and the temptation is to store whatever format each source provides, coercing year strings to dates at write time with `f"{year}-01-01"` as a placeholder.

**How to avoid:**
Add a `term_date_precision` field alongside `term_start` and `term_end`: `"year"`, `"month"`, `"day"`, `"unknown"`. Store dates at the precision available:
- "2024" → store `term_start = "2024-01-01"`, `term_date_precision = "year"` — frontend renders as "2024"
- "December 2022" → `term_start = "2022-12-01"`, `term_date_precision = "month"` — frontend renders as "Dec 2022"
- "December 5, 2022" → `term_start = "2022-12-05"`, `term_date_precision = "day"` — frontend renders as "Dec 5, 2022"

The `formatTermDate()` in ev-ui must be updated to accept precision metadata. If precision is `"year"`, suppress month/day display entirely. Never render `"Jan 2022"` when the source only provided `"2022"`.

Additionally: normalize the epoch convention. LA County has 4-year terms for most positions. If `year_elected = "2022"`, `term_end` should be `"2026-01-01"` (precision: year), not NULL. Calculate term end from year elected + standard term length when the end date is not explicitly provided.

**Warning signs:**
- `term_start` values cluster around "YYYY-01-01" in the database — a strong signal of year-coercion rather than real January 1st start dates
- Profile pages show "Jan 2022" for officials elected in November 2022 (wrong month)
- `term_start` is non-null but `term_end` is NULL for all gap-filled officials — term end was never calculated
- A council member with a 4-year term elected in 2020 shows no "Term ends:" line on their profile despite the data being inferrable

**Phase to address:**
Term data schema design phase — before writing any term dates. Implement `term_date_precision` before the first INSERT. The frontend `formatTermDate()` helper must be updated in ev-ui before the enrichment data goes live.

---

### Pitfall 7: Bio and Education Scraping Returns Navigation Text, Boilerplate, and Footer Content Mixed Into Bio Fields

**What goes wrong:**
Biography text scraped from city council "About" pages frequently captures the wrong content. The generic `parse_generic_council_page()` function looks for text near headings — but individual council member pages often have:
- Navigation breadcrumbs: "Home > City Council > District 3 > Councilmember Name"
- Boilerplate committee language: "The City Council meets the first and third Tuesday of each month..."
- Footer copyright: "© 2025 City of Burbank. All rights reserved."
- Other council members' bios if the page lists all members on one page

When `bio_text` is stored in `essentials.politicians`, these artifacts create garbled bio text that undermines user trust more than having no bio at all. The `essentials` frontend renders `bio_text` directly; there is no sanitization layer.

**Why it happens:**
Scraping bio text from generic city pages requires the scraper to understand page structure — which element is the bio vs. which is navigation. The existing generic parser (Strategy 3 in `scrape_city_councils.py`) uses sibling elements after a "council" heading, which is a reasonable heuristic but will fail for pages where the bio is in a different structural relationship to the heading.

**How to avoid:**
Use a character budget and content quality heuristic for bio text:
- Minimum 100 characters (shorter text is likely a title or label, not a bio)
- Maximum 2000 characters (longer text likely spans multiple sections)
- Must not contain any of: "©", "Cookie", "Privacy Policy", "All rights reserved", "Click here", "Home >"
- Must contain at least one sentence-ending punctuation mark (period or exclamation mark)

```python
def is_valid_bio(text):
    """Return True if text looks like a genuine bio, not boilerplate."""
    if not text or len(text) < 100 or len(text) > 2000:
        return False
    BLOCKLIST = ["©", "cookie", "privacy policy", "all rights reserved",
                 "click here", "home >", "sitemap", "skip to content"]
    lower = text.lower()
    if any(b in lower for b in BLOCKLIST):
        return False
    if "." not in text and "!" not in text:
        return False
    return True
```

Store `bio_source_url` alongside `bio_text` so the scrape can be re-verified manually. When no valid bio is found, store NULL rather than storing low-quality text.

**Warning signs:**
- `bio_text` in the database contains "©" or "Cookie Policy" substrings
- `bio_text` is less than 80 characters (likely a job title, not a biography)
- Multiple council members for the same city have identical `bio_text` (boilerplate about council meeting schedules was captured instead of individual bios)
- `bio_text` begins with "Home >" or "You are here:" (navigation breadcrumb captured)

**Phase to address:**
Bio scraping implementation phase — implement the quality filter before storing any bio text. During QA, run `SELECT full_name, LEFT(bio_text, 100) FROM essentials.politicians WHERE bio_text IS NOT NULL AND LENGTH(bio_text) < 100 LIMIT 20` to spot low-quality text before it reaches the frontend.

---

### Pitfall 8: Photo Coverage "80%" Metric Counts Records, Not Display Success — Broken Images Count as "Covered"

**What goes wrong:**
The v1.7 milestone states "80%+ coverage target for headshots and contact info." Coverage is tempting to measure as: "percentage of officials where `photo_url IS NOT NULL`." But this metric is misleading if `photo_url` contains a hotlinked government URL that is broken, or a Supabase Storage URL where the upload failed or was deleted. The database says 85% coverage, users see 40% coverage (broken images silently rendering as placeholder avatars).

**Why it happens:**
Coverage metrics are written into the milestone spec before the pipeline architecture is finalized. The Python script that checks coverage after a run counts non-null DB rows — it cannot distinguish a working image from a broken one without making an HTTP request to each URL.

**How to avoid:**
Define coverage as verifiable display success, not database row presence. After the scraping pipeline completes, run a coverage validation script that makes HEAD requests to every `photo_url` and counts HTTP 200 responses:

```python
def verify_photo_coverage(conn):
    cur = conn.cursor()
    cur.execute("""
        SELECT p.id, pi.photo_url
        FROM essentials.politicians p
        JOIN essentials.politician_images pi ON pi.politician_id = p.id
        WHERE p.is_active = true
          AND p.source = 'scraped'
          AND pi.photo_url IS NOT NULL
    """)
    rows = cur.fetchall()

    working = 0
    for politician_id, url in rows:
        try:
            resp = requests.head(url, timeout=5)
            if resp.status_code == 200:
                working += 1
        except Exception:
            pass

    total = len(rows)
    all_active = get_total_active_scraped_politicians(conn)
    print(f"Photo coverage: {working}/{all_active} = {working/all_active*100:.1f}%")
    print(f"Photos in DB: {total} ({total/all_active*100:.1f}%)")
    print(f"Photos working: {working} ({working/total*100:.1f}% of stored URLs)")
```

Run this validation script as the final step of every pipeline run and include its output in the pipeline run log.

**Warning signs:**
- Pipeline summary shows "headshot coverage: 87%" but `essentials` frontend shows placeholder avatars for most city council members
- HEAD request audit shows >10% of stored `photo_url` values return non-200 responses
- Supabase Storage dashboard shows fewer files than the database has non-null `photo_url` rows
- Coverage metric increased after a run but no new images were uploaded to Supabase Storage (URL pattern unchanged)

**Phase to address:**
Coverage verification phase — implement the HEAD request audit as part of the pipeline run from day one. The milestone success criteria must reference verified display coverage, not database coverage.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Store `photo_origin_url` as the displayed image URL (hotlinking) | No CDN setup required, pipeline runs faster | Photos break silently when city websites redesign (expected every 2-4 years); hotlink blocking can break all photos overnight | Never for production display — acceptable only as audit metadata |
| Store `year_elected` as "YYYY-01-01" date without precision tracking | Simple schema, no new columns | Frontend shows "Jan 2022" when official was elected in November; misleads users about term timing | Never — add `term_date_precision` before storing any term dates |
| Use `bio_text IS NOT NULL` as coverage metric | Easy to compute in SQL | Counts broken, boilerplate, and empty-looking text as "covered"; masks true quality issues | Never — use the quality filter + HEAD request audit as the canonical coverage measure |
| Skip Wikimedia Commons check and go straight to city website scraping | Faster initial scraping | Scrapes potentially copyrighted contractor photos at scale; creates legal exposure for a nonprofit; Wikimedia photos are CDN-hosted and license-verified | Never — Wikimedia check must come first in the sourcing priority chain |
| Single transaction for all 89 cities in `scrape_city_councils.py` | Simpler code | One city failure rolls back all others; pipeline must restart from scratch | Never — v1.6 already uses per-city COMMIT; enrichment pipeline must maintain this pattern |
| No rate limiting between city website requests | Faster scraping run | Triggers Cloudflare bot detection; IP blocked; entire batch fails; cities marked "failed" permanently | Never — minimum 2s delay between cities, 0.5s between images from same domain |

---

## Integration Gotchas

Common mistakes when connecting to external services for this enrichment pipeline.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Supabase Storage (Python) | Not setting `content-type` in `file_options` — defaults to `text/plain`, breaks image rendering | Always pass `file_options={"content-type": "image/jpeg"}` (or correct MIME type from HTTP response `Content-Type` header) |
| Supabase Storage (Python) | Base64-encoding image bytes before upload — corrupts the file | Pass `resp.content` (raw bytes) directly to `supabase.storage.from_().upload()`, no encoding |
| Supabase Storage (Python) | Uploading to a non-existent bucket — raises `StorageApiError` with cryptic message | Create the `politician-photos` bucket manually in Supabase dashboard before running the pipeline; verify with `supabase.storage.list_buckets()` at pipeline startup |
| Wikimedia Commons API | Searching by politician full name returns zero results for officials who go by a different display name | Search by last name only first, then filter by state/role context; also try the politician's Wikipedia page URL (search Commons for files linked from that Wikipedia article) |
| City website rate limiting | Requesting images and HTML from same domain in rapid succession | Use separate delays: 2s between HTML page requests, 0.5s between image downloads, 5s after any 429 response |
| `city_sources.json` status field | Re-running the enrichment scraper overwrites `status: "scraped"` with `status: "failed"` if the enrichment pass fails, preventing future name/seat re-scrapes | Use separate status fields: `roster_status` (names from SOS PDF — stable) and `enrichment_status` (photos/contacts — refreshable) |

---

## Performance Traps

Patterns that work at small scale but fail at 389 officials.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Sequential HEAD requests to verify photo coverage (one per official) | Coverage validation script takes 10+ minutes for 389 officials | Use `concurrent.futures.ThreadPoolExecutor(max_workers=10)` for parallel HEAD requests with a semaphore to cap concurrency | Immediately at 100+ officials if running sequentially |
| Downloading all headshots in a single Python session without progress checkpointing | If the script crashes 3/4 through (network error, OOM), all work is lost and must restart from the beginning | Checkpoint progress to a JSON file after each city's images are uploaded; check this file on startup to skip already-completed cities | Always — 89 cities × ~5 officials × image download = thousands of HTTP requests, crash probability is high |
| Using `requests` synchronously for photo downloads from 89 different domains | Full pipeline run takes 2+ hours at ~2s per image | Use `asyncio` + `httpx.AsyncClient` for image downloads with domain-level rate limiting (semaphore per domain) | At 200+ images — acceptable for MVP if pipeline is run overnight |
| Storing large bio text (2000+ chars) in `essentials.politicians.bio_text` for all 791 politicians | SELECT queries on the full politicians table pull 2000+ bytes of text per row even when bio is not needed | Add `bio_text` to a separate `essentials.politician_bios` table or use PostgreSQL `TOAST` compression (automatic for text > 2KB) — at 791 politicians this is minor, but sets the right pattern for expansion | At 5,000+ politicians — not a current concern, but worth designing for |

---

## Security Mistakes

Domain-specific security issues for the enrichment pipeline.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Storing Supabase service role key in `city_sources.json` or any config file committed to git | Service role key bypasses Row Level Security; anyone with repo access can read/write all tables | Use environment variable `SUPABASE_SERVICE_KEY` only; never commit to `city_sources.json` or any JSON config file; add `SUPABASE_SERVICE_KEY` to `.gitignore` patterns |
| Making Supabase Storage bucket public without restricting file types | Anyone can upload files to the bucket via the public URL, including non-image payloads | Set bucket to public (for CDN access) but restrict uploads via Storage Policy to authenticated service role only; never use `anon` key for uploads |
| Logging `photo_origin_url` values that may contain politician home addresses if scraped from unofficial sources | CCPA compliance risk if logged to any persistent log file | Sanitize log output — log politician IDs and scrape status, not scraped URLs or personal contact information |
| Not verifying image MIME type before uploading to Storage — a government site could serve JavaScript or HTML at an image URL | Malformed "image" served to users; potential XSS if a browser interprets a `text/html` response from the CDN URL | Verify `content-type` header starts with `image/` before uploading; reject and log any non-image content type |

---

## UX Pitfalls

Common user experience mistakes when displaying enrichment data.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Showing "No photo available" text instead of initials avatar when headshot scraping failed | Empty-looking profile that erodes trust; initials avatars already exist in ev-ui | Keep the initials avatar as the unconditional fallback — never show text like "Photo coming soon" |
| Displaying contact info (phone, email) scraped more than 6 months ago without a freshness indicator | User calls a dead number or emails a bouncing address; immediate trust failure | Show "Contact info as of [month year]" below each contact field; link to official city website for the most current info |
| Rendering term dates as "Jan 2022" when only the year was available | Users think the official started in January when they actually started in December | Implement `term_date_precision` (see Pitfall 6) and render "2022" when precision is year-only |
| Showing "Education: None listed" vs hiding the education section entirely | "None listed" implies the data was looked for and not found, which may not be true | Hide the education section entirely when no degrees are scraped — do not distinguish "has no education" from "education not found"; show section only when at least one degree exists |
| Rendering all 89 cities' contact info without grouping by recency | Users cannot tell which contact info is freshly verified vs. year-old | Group by `contact_synced_at` recency — officials enriched in the current pipeline run are marked "verified [month year]"; older records show "last verified [older date]" |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Photo re-hosting:** Verify `essentials.politician_images` rows where `photo_url` contains a Supabase CDN domain, NOT a government domain — run `SELECT COUNT(*) FROM essentials.politician_images WHERE photo_url NOT LIKE '%supabase%'` and expect 0 rows after pipeline run
- [ ] **Photo license field populated:** Verify `photo_license` column exists and is non-null for all inserted images — `SELECT COUNT(*) FROM essentials.politician_images WHERE photo_license IS NULL AND politician_id IN (SELECT id FROM essentials.politicians WHERE source='scraped')` expects 0
- [ ] **Coverage metric is verified, not counted:** Run HEAD request audit on all stored photo URLs; confirm >= 80% return HTTP 200 (not just 80% of rows have non-null `photo_url`)
- [ ] **Term date precision tracked:** Verify `term_date_precision` column exists in schema and is set for every row where `term_start IS NOT NULL` — `SELECT COUNT(*) FROM essentials.politicians WHERE term_start IS NOT NULL AND term_date_precision IS NULL` expects 0
- [ ] **Bio quality validated:** Run `SELECT full_name, LEFT(bio_text, 100) FROM essentials.politicians WHERE bio_text IS NOT NULL ORDER BY LENGTH(bio_text) ASC LIMIT 20` — manually review shortest bios to confirm they are not boilerplate or navigation text
- [ ] **Contact info has synced timestamp:** Verify `contact_synced_at IS NOT NULL` for all officials where at least one contact field (phone, email, website) is non-null
- [ ] **Rate limiting verified:** After full pipeline run, confirm no cities are marked `status: "blocked"` due to Cloudflare; if any are blocked, add a `retry_after` timestamp and re-run after 72 hours
- [ ] **Supabase Storage bucket exists and is public:** `supabase.storage.list_buckets()` shows `politician-photos` with `public: true`; verify a test image URL resolves from a browser without authentication
- [ ] **Playwright fallback tested:** Manually identify 3 JS-rendered city pages, run `fetch_html_with_fallback` on them, confirm Playwright path is triggered and names are found
- [ ] **Deduplication still passes:** After enrichment upserts, re-run the duplicate check query from v1.6: `SELECT d.ocd_id, p.full_name, COUNT(*) FROM essentials.politicians p JOIN essentials.offices o ON o.politician_id = p.id JOIN essentials.districts d ON o.district_id = d.id WHERE p.is_active = true GROUP BY d.ocd_id, p.full_name HAVING COUNT(*) > 1` — expects 0 rows

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Hotlinked photos breaking (city website redesign) | MEDIUM | (1) Run coverage validation script — identify all non-200 photo URLs. (2) Re-run headshot scraper for affected cities with `--force` flag. (3) New URLs found → download + re-upload to Supabase Storage. (4) If city page restructured and image not findable, search Wikimedia Commons as fallback. Recovery time: 2-4 hours per batch |
| JS-rendered cities marked as permanent failures | LOW | (1) Identify failed cities in `city_sources.json`. (2) Test each with Playwright manually. (3) Mark `"fetch_method": "playwright"` in config. (4) Remove `status: "failed"` for those cities. (5) Re-run pipeline. Recovery time: 30 min setup + pipeline re-run time |
| Cloudflare blocking scraper IP | LOW | (1) Wait 24-48 hours for IP unblock. (2) Add `time.sleep(random.uniform(3, 6))` between all requests. (3) For persistently blocked sites, accept SOS PDF names-only coverage — no contact/photos. Recovery time: 1 day wait + 1 hour code change |
| Bio text contains boilerplate in production | LOW | (1) Run quality filter query to identify affected records. (2) UPDATE `bio_text = NULL` for records failing quality check. (3) Add quality filter to scraper for future runs. Recovery time: under 1 hour |
| Coverage metric inflated (counts null URLs as missing but counts broken URLs as covered) | LOW | (1) Run HEAD request audit. (2) Update `photo_url = NULL` for records returning non-200. (3) Implement verified coverage metric going forward. Recovery time: 2 hours |
| Term dates stored as year-coerced "YYYY-01-01" displayed as "Jan YYYY" | MEDIUM | (1) Add `term_date_precision` column if missing. (2) UPDATE `term_date_precision = 'year'` for all rows where `EXTRACT(MONTH FROM term_start) = 1 AND EXTRACT(DAY FROM term_start) = 1`. (3) Update `formatTermDate()` in ev-ui to suppress month/day when precision is "year". (4) Publish new ev-ui version. Recovery time: 3-5 hours including ev-ui publish cycle |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Hotlinking (Pitfall 1) | Headshot scraping pipeline design — Supabase Storage setup must precede any headshot scraping | `SELECT COUNT(*) FROM essentials.politician_images WHERE photo_url NOT LIKE '%supabase%'` = 0 |
| JS-rendered page failures (Pitfall 2) | Pre-scraping audit — classify 10 sample cities before writing pipeline | Playwright fallback triggered for known-JS cities; coverage for JS cities >= static cities |
| Cloudflare rate limiting (Pitfall 3) | Scraping pipeline implementation — rate limiting in initial commit | No cities marked `status: "blocked"` after a full run |
| Contact info staleness (Pitfall 4) | Contact storage schema design — `contact_synced_at` column before first INSERT | `SELECT COUNT(*) FROM essentials.politicians WHERE (phone IS NOT NULL OR email IS NOT NULL) AND contact_synced_at IS NULL` = 0 |
| Image licensing (Pitfall 5) | Headshot sourcing design — Wikimedia Commons check before city scraping | `photo_license` is non-null for all stored images; "scraped_no_license" images not served in production |
| Term date inconsistency (Pitfall 6) | Term data schema design — `term_date_precision` column before first INSERT | `SELECT COUNT(*) FROM essentials.politicians WHERE term_start IS NOT NULL AND term_date_precision IS NULL` = 0 |
| Bio boilerplate (Pitfall 7) | Bio scraping implementation — quality filter in first implementation | Manual QA of 20 shortest bio_text values shows all are genuine biographies |
| Coverage metric inflation (Pitfall 8) | Coverage verification design — HEAD request audit as pipeline final step | Coverage report shows verified working URLs, not just non-null DB rows |

---

## Sources

- mySociety PopIt issue #461: [Detect when image hotlinking is prevented](https://github.com/mysociety/popit/issues/461) — documented hotlink blocking behavior from Guatemalan government website returning 403 with explicit hotlink message; PopIt project (civic data platform) archived 2018 after not solving this
- Pixsy: [Hotlinking: What Is It & How To Prevent It](https://www.pixsy.com/image-protection/hotlinking) — hotlink protection mechanics; broken link risk when host moves image
- EFF: [California Legislature Drops Proposal to Copyright All Government Works](https://www.eff.org/deeplinks/2016/06/california-legislature-drops-proposal-copyright-all-government-works) — AB 2880 history; CA governments can assert copyright, unlike federal
- Wikipedia: [Copyright status of works by subnational governments of the United States](https://en.wikipedia.org/wiki/Copyright_status_of_works_by_subnational_governments_of_the_United_States) — state/local government copyright rules differ from federal; California does not have automatic public domain for government works
- Wikimedia Commons: [Commons:Licensing](https://commons.wikimedia.org/wiki/Commons:Licensing) — CC BY-SA and public domain terms for Commons-hosted images; Fair use not accepted
- USA.gov: [Learn about copyright and federal government materials](https://www.usa.gov/government-copyright) — federal works are public domain; state/local NOT covered by same rule
- Supabase docs: [Python API Reference — Storage Upload](https://supabase.com/docs/reference/python/storage-from-upload) — MIME type requirement, file_options format
- Supabase community: [PNG Image becomes corrupted after uploading to storage bucket](https://github.com/orgs/supabase/discussions/26257) — base64 encoding pitfall with Python upload
- Scrapfly: [How to Bypass Cloudflare When Web Scraping](https://scrapfly.io/blog/posts/how-to-bypass-cloudflare-anti-scraping) — Cloudflare bot detection mechanisms; headless browser fingerprinting
- City Bureau: [City Scrapers project](https://github.com/City-Bureau/city-scrapers) — community patterns for scraping government websites; JS-rendered page handling patterns
- Codebase: `EV-Backend/scripts/scrape_la_officials.py` (lines 29-33) — existing TODO for photo re-hosting deferral; `EV-Backend/scripts/scrape_city_councils.py` (fetch_html_with_fallback) — byte-count threshold limitation; `scrapers/lavote_scraper.py` — year_elected as bare string pattern; v1.6 school board comment "universally blocked by Cloudflare"

---
*Pitfalls research for: v1.7 LA County Data Enrichment — headshot scraping, building photos, contact/term data, bio/education/experience pipeline*
*Researched: 2026-02-24*
