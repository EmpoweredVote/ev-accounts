# Phase 37: Politician Gap-Fill — City Councils and School Boards - Research

**Researched:** 2026-02-24
**Domain:** Python web scraping (requests + BeautifulSoup + Playwright), PDF extraction, ArcGIS REST API, PostgreSQL upsert, config-driven scraper framework extension
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Source Strategy for 87 Cities**
- Claude's discretion on whether to use aggregator sources (League of CA Cities, SCAG, LA County data portals) vs per-city scraping — evaluate during research and pick the best approach per city
- Use Playwright headless browser scraping for JavaScript-heavy or hard-to-scrape city sites before marking as failed — try harder before giving up
- Python for all scrapers, consistent with Phase 34/35/36 scripts (requests + BeautifulSoup for static, Playwright for JS-heavy)
- Single consolidated config file mapping all 87 cities to their scraper configs (similar to arcgis_sources.json pattern from Phase 34)

**School Board Sourcing**
- Scope: ALL LA County school districts — unified, elementary, high school, and community college districts (not just USDs)
- Claude's discretion on bulk source approach — research CDE directory, LACOE, and individual district sites to find the best strategy
- Import missing school district boundaries as part of this phase if they weren't covered in Phase 34 — every board member needs a geofence
- Where trustee areas exist, create separate sub-district records so an address returns the specific trustee representative; fall back to shared district for at-large elections

**Coverage and Prioritization**
- Target: 90%+ coverage acceptable — cover as many cities and districts as automated scraping handles, log gaps for follow-up
- Phase is complete if 90%+ of cities and 90%+ of school districts have records
- Claude's discretion on batching strategy (all at once vs waves) and coverage tracking approach
- Cities/districts that fail scraping are logged with failure reason for manual follow-up

**Data Quality Thresholds**
- Minimum viable record: name + seat only
- Grab everything available from sources — photos, bios, contacts, committee assignments, term dates
- School board members stored with party = 'Nonpartisan' explicitly (not null)
- Incomplete records treated the same in the frontend — show what we have, hide what we don't. Missing photos use placeholder avatar.

### Claude's Discretion
- Aggregator vs per-city scraping decisions per entity
- Batching/wave strategy for processing 87+ entities
- Coverage tracking mechanism (report script vs config status field)
- School board bulk source selection (CDE vs LACOE vs per-district)
- Playwright integration approach for JS-heavy sites
- Trustee area boundary sourcing for school districts with sub-district elections

### Deferred Ideas (OUT OF SCOPE)
- Automated scraper scheduling/refresh cycles — future phase
- Community college board coverage if not included in "all school districts" boundary data — evaluate during research
- Handling mid-term vacancies and special elections for covered cities — future phase
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| POL-03 | City council members for all 87 other incorporated LA County cities populated | California Secretary of State 2025/2026 Roster PDF (`admin.cdn.sos.ca.gov/ca-roster/2026/cities-towns.pdf`) is a bulk PDF source covering all incorporated cities. Phase 36 scraper framework (`scrape_la_officials.py` + `politician_sources.json`) is directly extensible: add 87 new entries. G4110 geofences imported in Phase 34 cover at-large cities; X0001 ward geofences cover district-based cities (some already in Phase 35). The 90% target is achievable with aggregator-first approach. |
| POL-04 | School board members for 80+ LA County school districts populated | LA County has 80 public school districts (52 unified, 24 elementary, 3-5 high school districts). CDE ArcGIS API (`services3.arcgis.com/fdvHcZVgB2QSRNkL/arcgis/rest/services/SchoolDistrictAreas2425/FeatureServer/0`) provides boundary GeoJSON with CDCode identifier. Individual district websites are the primary source for board member names. LACOE's school directory provides a structured district list. School boards use `district_type = SCHOOL` per existing MTFCC G5420 mapping. |
</phase_requirements>

---

## Summary

Phase 37 is a high-volume extension of the Phase 36 config-driven scraper framework. The primary challenge is scale: 87 cities plus 80+ school districts require a two-track strategy. For cities, the California Secretary of State publishes an annual "Incorporated Cities and Town Officials" PDF that lists mayor and council member names for all California incorporated cities — this is the best bulk aggregator source, covering ~90%+ of LA County cities in one document with minimal per-city site scraping. For school boards, no comparable aggregator exists; individual district websites must be scraped, but the LACOE school directory provides a structured entry point and the CDE ArcGIS API provides boundaries. The Phase 36 `scrape_la_officials.py` and `politician_sources.json` require no architectural changes — new city and district entries extend the existing config.

The data complexity is higher than Phase 36 in three areas: (1) at-large vs by-district classification affects geo_id assignment — at-large cities map to the G4110 place boundary, district cities need X0001 ward geofences; (2) LA County school board trustee areas (where districts elect by trustee area) require sub-district boundary records similar to the Monroe County MCCSC pattern already implemented in `import_school_board_districts.py`; (3) the California CVRA has driven ~50% of cities to switch from at-large to by-district elections since 2016, so many cities that BallotReady treated as at-large may now have ward geofences, requiring the same geo_id update pattern from `gap_fill_geo_ids.py`.

**Primary recommendation:** Two-wave execution — Wave A: CA SOS Roster PDF extraction covers all 87 cities as an initial data dump; Wave B: per-district school board scraping using LACOE directory + CDE boundaries. Both waves use the existing Phase 36 dedup logic and upsert pattern. No new schema changes are needed (Phase 36 added `is_active` and `data_source` columns). `pdfplumber` is the correct library for SOS roster PDF extraction.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| psycopg2-binary | 2.9.11 | Direct PostgreSQL connection for upsert logic | Used in `scrape_la_officials.py`, `gap_fill_geo_ids.py`, `promote_scraped_officials.py` — project standard |
| requests | 2.32.5 | HTTP fetching of HTML pages and ArcGIS GeoJSON | Project standard per Phase 33 `requirements.txt` |
| beautifulsoup4 | 4.12.3 | HTML parsing for individual city and district websites | Project standard; already in `requirements.txt` |
| rapidfuzz | 3.x | Fuzzy last-name matching for deduplication | Phase 36 decision — replaces `python-Levenshtein`, builds cleanly on macOS |
| pdfplumber | 0.11.x | Extract text from CA SOS Roster PDF | Best-in-class for structured PDF extraction with coordinate awareness; returns character positions for layout-sensitive parsing |
| playwright | 1.44+ | Headless browser for JS-heavy government sites | Project decision (Phase 37 CONTEXT); install via `pip install playwright && playwright install chromium` |
| geopandas | 0.14.x | GeoDataFrame for ArcGIS GeoJSON school district boundaries | Already in `requirements.txt` (used by `import_arcgis_geofences.py`, `import_school_board_districts.py`) |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| uuid | stdlib | UUID generation for new politician/office/district records | All PK generation |
| json | stdlib | Config file for scraper source mapping | Already used by `politician_sources.json` pattern |
| shapely | 2.x | GeoJSON geometry for school district boundary import | Already in `requirements.txt` |
| lxml | stdlib (html.parser fallback) | Fast HTML parser | Optional upgrade from html.parser for better performance |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| pdfplumber | PyMuPDF | PyMuPDF is faster but more complex API; pdfplumber has simpler table-extraction and coordinate-based access — better fit for roster PDF layout parsing |
| pdfplumber | pypdf | pypdf has weaker layout-preserving extraction; loses column structure in multi-column PDFs |
| Playwright | Selenium | Playwright is faster, has better async support, and cleaner Python API; project CONTEXT decision chose Playwright |
| per-district scraping | LACSTA bulk data request | LACSTA does not publish a machine-readable member roster — no bulk API exists |

**Installation:**
```bash
# Add to EV-Backend/scripts/requirements.txt:
pdfplumber==0.11.4
playwright==1.44.0

# After pip install, install browser binary:
playwright install chromium
```

---

## Architecture Patterns

### Recommended Project Structure

```
EV-Backend/scripts/
├── utils.py                          # Phase 33 shared utilities (unchanged)
├── requirements.txt                  # Add pdfplumber, playwright
├── politician_sources.json           # EXTEND: add 87 city entries + school district entries
├── gap_fill_geo_ids.py               # REUSE (idempotent — already handles all CA LOCAL districts)
├── scrape_la_officials.py            # EXTEND: add parsers for new source types
├── scrape_city_councils.py           # NEW: wave-based batch scraper for all 87 cities
├── scrape_school_boards.py           # NEW: LACOE directory + per-district scraper
├── city_sources.json                 # NEW: 87-city config (separate from politician_sources.json)
└── school_sources.json               # NEW: 80+ school district config with boundaries
```

**Alternative:** Extend `politician_sources.json` directly with all 87 cities and school districts (the CONTEXT.md preference — "single consolidated config file"). Either approach works; the tradeoff is one large config vs. separate configs for clarity.

### Pattern 1: CA SOS Roster PDF Extraction (Bulk City Data)
**What:** The California Secretary of State publishes an annual "Incorporated Cities and Town Officials" PDF listing mayor and council members for all ~482 CA incorporated cities. For LA County, this covers all 87 remaining cities in one document.
**When to use:** First pass — extract all LA County cities from PDF, store as city_sources entries with fallback rosters
**Source URL:** `https://admin.cdn.sos.ca.gov/ca-roster/2026/cities-towns.pdf` (2026 edition published late 2025) or `https://admin.cdn.sos.ca.gov/ca-roster/2025/complete-roster.pdf`

**Example:**
```python
# Source: pdfplumber docs + pattern derived from SOS PDF structure
import pdfplumber
import re

def extract_la_county_cities_from_sos_roster(pdf_path):
    """Extract city council member names from CA SOS Incorporated Cities PDF.

    The PDF is organized city-by-city alphabetically. For each city it lists:
    - City name header
    - Mayor (or Mayor Pro-Tem)
    - Council Members (or City Council, depending on format)
    - City Clerk, City Administrator, etc.

    Returns: dict mapping city_name -> {mayor: str, council_members: [str]}
    """
    results = {}

    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            text = page.extract_text()
            if text:
                # City sections are identified by a city name in all caps or title case
                # followed by address, then "Mayor:" or "Council Members:"
                # Parsing logic depends on actual PDF layout — check at implementation time
                lines = text.split('\n')
                current_city = None
                for line in lines:
                    # Look for LA County city headers
                    # Pattern: city name followed by "CA" or zip code
                    # TODO: Implement after inspecting actual PDF layout
                    pass

    return results

# Alternative: Use page.extract_tables() if council members are in tabular form
with pdfplumber.open(pdf_path) as pdf:
    for page in pdf.pages:
        tables = page.extract_tables()
        for table in tables:
            # Process table rows
            pass
```

**Key caveat (MEDIUM confidence):** The actual PDF layout must be inspected at implementation time. The SOS PDF has historically been a multi-column text PDF, not a true table. `pdfplumber.page.extract_text()` with newline parsing is usually sufficient; `extract_tables()` helps if sections are formatted as tables.

### Pattern 2: At-Large vs By-District City Classification (geo_id assignment)
**What:** Cities that elect council at-large use the G4110 incorporated place boundary as geo_id. Cities that elect by district (ward) use the X0001 sub-district geofence. About 50% of LA County cities now elect by district (CVRA-driven trend since 2016).
**When to use:** For every city in `city_sources.json`, must set `election_type` field
**Example:**
```python
# Config structure distinguishing at-large vs district cities
{
  "id": "burbank_city_council",
  "name": "Burbank City Council",
  "election_type": "at-large",        # Uses G4110 place geofence
  "place_geoid": "0608954",           # Census GEOID from Phase 34 G4110 import
  "url": "https://www.burbankca.gov/government/city-council",
  "parser": "generic_council_page",
  "district_type": "LOCAL",
  "title": "Council Member",
  "state": "CA",
  "expected_count": 5
}

# vs. district city
{
  "id": "redondo_beach_city_council",
  "name": "Redondo Beach City Council",
  "election_type": "district",         # Uses X0001 ward geofences
  "place_geoid": "0660788",
  "districts": 5,
  "ocd_id_template": "ocd-division/country:us/state:ca/place:redondo_beach/council_district:{n}",
  "url": "https://www.redondo.org/government/city-council",
  "parser": "generic_council_page",
  "district_type": "LOCAL",
  "title": "Council Member",
  "state": "CA"
}
```

**For at-large cities:** `geo_id` = place_geoid (e.g., `0608954`) — matches G4110 boundary from Phase 34. All council members share the same geo_id.

**For district cities where X0001 already imported:** `geo_id` = ocd_id (same as Phase 36 pattern, already handled by `gap_fill_geo_ids.py`).

**For district cities where X0001 NOT yet imported:** Need to find ArcGIS boundary source and import (extend `arcgis_sources.json`). The Phase 35 pattern handles this.

### Pattern 3: Playwright Integration for JS-Heavy Sites
**What:** Playwright renders JavaScript before BeautifulSoup parses. Fall through from requests → Playwright transparently.
**When to use:** When `requests.get()` returns empty/minimal HTML (JavaScript-rendered content)
**Example:**
```python
# Source: playwright.dev/python/docs pattern + scraping community best practices
import requests
from bs4 import BeautifulSoup

def fetch_html_with_fallback(url, timeout=15):
    """Try requests first; fall back to Playwright for JS-heavy sites.

    Returns (html: str, used_playwright: bool)
    """
    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/121.0.0.0 Safari/537.36"
        )
    }

    try:
        resp = requests.get(url, headers=headers, timeout=timeout)
        resp.raise_for_status()
        html = resp.text

        # Heuristic: if page has minimal text content, likely JS-rendered
        soup = BeautifulSoup(html, "html.parser")
        body_text = soup.get_text(strip=True)
        if len(body_text) > 500:  # Threshold — adjust per site
            return html, False
    except Exception as e:
        print(f"    requests failed: {e}")

    # Fall back to Playwright
    print(f"    Falling back to Playwright for: {url}")
    from playwright.sync_api import sync_playwright
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto(url, timeout=30000)
        page.wait_for_load_state("networkidle")
        html = page.content()
        browser.close()
    return html, True
```

**Installation note:** After `pip install playwright`, must run `playwright install chromium` to download the Chromium binary. This is a one-time step, not included in `requirements.txt` pip install.

### Pattern 4: Generic Council Page Parser (Covers ~70% of Sites)
**What:** Most small city websites use one of a few common CMS patterns for "City Council" pages. A generic parser handles these; custom parsers handle the exceptions.
**Example:**
```python
def parse_generic_council_page(html, source_config):
    """Generic parser for common city council page patterns.

    Handles:
    - Tables with council member names and district/position
    - Lists with heading "Council Member" or "Mayor"
    - "Card" layouts with person name + title

    Returns: list of {name: str, district: int/str, title: str, party: str}
    """
    soup = BeautifulSoup(html, "html.parser")
    import re
    results = []

    # Strategy 1: Search for common council member class names
    for tag in soup.find_all(class_=re.compile(
        r"council|member|official|elected|representative", re.I
    )):
        name_el = tag.find(re.compile(r"h[1-6]|strong|b|span"))
        if name_el:
            name = name_el.get_text(strip=True)
            if len(name.split()) >= 2:
                # Extract district if present
                tag_text = tag.get_text(" ", strip=True)
                dist_match = re.search(r"District\s*(\d+)", tag_text, re.I)
                district = int(dist_match.group(1)) if dist_match else 0
                results.append({"name": name, "district": district, "title": "Council Member"})

    # Strategy 2: Look for table with member names
    if not results:
        for table in soup.find_all("table"):
            for row in table.find_all("tr"):
                cells = [c.get_text(strip=True) for c in row.find_all(["td", "th"])]
                if len(cells) >= 2:
                    # Look for rows that have a person name
                    for i, cell in enumerate(cells):
                        if re.match(r"[A-Z][a-z]+ [A-Z][a-z]+", cell):
                            district_text = " ".join(cells)
                            dist_match = re.search(r"District\s*(\d+)", district_text, re.I)
                            district = int(dist_match.group(1)) if dist_match else 0
                            results.append({"name": cell, "district": district, "title": "Council Member"})
                            break

    return results
```

### Pattern 5: School Board Scraper — LACOE Directory Entry Point
**What:** LACOE's school directory (`schooldirectory.lacoe.edu`) provides a structured list of all 80 LA County districts. The CDE district data file (`cde.ca.gov/SchoolDirectory/report?rid=dl2&tp=txt`) provides district name, CDCode, and superintendent contact. Individual district websites are the source for board member names.
**When to use:** Phase 37 Plan B (school boards)
**Example:**
```python
# CDE district data file gives us the definitive list + district identifiers
# The tab-delimited file has columns: CD Code, County, District, Phone, AdmFName, AdmLName, ...
# Does NOT include board member names — those come from individual district sites

import csv
import io
import requests

def get_la_county_districts_from_cde():
    """Download CDE district list filtered to LA County.

    Returns list of dicts with district name, CDCode, phone, superintendent name.
    Use CDCode to link to geofence_boundaries via geo_id matching.
    """
    url = "https://www.cde.ca.gov/SchoolDirectory/report?rid=dl2&tp=txt"
    resp = requests.get(url, headers={"User-Agent": "..."})
    content = resp.content.decode("utf-8", errors="replace")
    reader = csv.DictReader(io.StringIO(content), delimiter="\t")

    la_districts = []
    for row in reader:
        if row.get("County", "").strip() == "Los Angeles":
            la_districts.append({
                "cd_code": row.get("CD Code", "").strip().replace(" ", ""),
                "name": row.get("District", "").strip(),
                "phone": row.get("Phone", "").strip(),
                "website": None,  # Not in CDE file — must look up separately
            })

    return la_districts
```

### Pattern 6: School District Boundaries via CDE ArcGIS API
**What:** The CDE publishes 2024-25 school district boundaries as an ArcGIS FeatureServer. Query by `CountyName = 'Los Angeles'` to get all LA County school district polygons with CDCode.
**Source:** `https://services3.arcgis.com/fdvHcZVgB2QSRNkL/arcgis/rest/services/SchoolDistrictAreas2425/FeatureServer/0`
**Fields:** CDCode (7 chars), CDSCode (14 chars), DistrictName, DistrictType, FedID
**Example query:**
```
https://services3.arcgis.com/fdvHcZVgB2QSRNkL/arcgis/rest/services/SchoolDistrictAreas2425/FeatureServer/0/query?where=CountyName+%3D+%27Los+Angeles%27&outFields=CDCode,CDSCode,DistrictName,DistrictType,FedID&f=geojson&outSR=4326
```

**geo_id convention for school districts:** Phase 34 imported G5420 boundaries using `FedID` as the geo_id (7-digit Federal ID). Verify this against existing `geofence_boundaries` rows before writing the school board importer. If Phase 34 used GEOID format instead, adjust accordingly.

**Confirmed from sample query:**
- ABC Unified: CDCode=1964212, FedID=0601620
- Arcadia Unified: CDCode=1964261, FedID=0602970
- Azusa Unified: CDCode=1964279, FedID=0603600

### Pattern 7: Coverage Tracking with Config Status Field
**What:** Add a `"status"` field to each entry in `city_sources.json` and `school_sources.json` to track progress.
**When to use:** Throughout scraping waves — update status as each source is completed
**Example:**
```json
{
  "id": "burbank_city_council",
  "status": "pending",       // pending → scraped → failed → manual_review
  "failure_reason": null,    // Populated on failure
  "last_scraped": null       // ISO timestamp on success
}
```
**Alternatively:** Use a separate `coverage_report.json` generated by a reporting script — avoids modifying the config on each run. Claude's discretion on which approach.

### Anti-Patterns to Avoid
- **Treating all cities as at-large:** ~50% of LA County cities have switched to by-district elections (CVRA). Always check `election_type` in config before geo_id assignment.
- **Using school district CDCode as geo_id without verifying:** Phase 34 imported G5420 boundaries with a specific geo_id format. Must query existing `geofence_boundaries WHERE mtfcc = 'G5420'` to confirm the geo_id used, then set `essentials.districts.geo_id` accordingly.
- **Blocking on Playwright install in CI:** `playwright install chromium` downloads ~150MB binary. For production/CI environments, consider using the Playwright Docker image or pre-installing. For local one-time use, run interactively.
- **Treating community college districts as school boards:** The CONTEXT decision says "evaluate during research." Community college boards (13 in LA County) are separate governing bodies with different district types. CONTEXT.md REQUIREMENTS.md excludes them from POL-04 scope ("School board members for 80+ LA County unified school districts") — the "+" implies all school district types, but community college districts are deferred per CONTEXT.md Deferred Ideas.
- **Skipping dedup for school boards:** School board members from at-large districts will conflict with any existing BallotReady-cached records. Same seat-first dedup logic applies.
- **Creating new district rows without checking Phase 34/36 geo_ids:** `gap_fill_geo_ids.py` already sets `geo_id = ocd_id` for all CA LOCAL districts. Adding new city council districts should use this same logic. School districts need their own geo_id logic matching whatever geo_id G5420 boundaries use.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| PDF text extraction | Regex on raw bytes | `pdfplumber` | SOS roster PDF has multi-column layout; coordinate-based extraction handles this correctly |
| JS-rendered page scraping | iframe parsing / curl + headers tricks | `playwright` sync API | Government sites increasingly use React/Vue for council pages; no workaround for client-rendered DOM |
| Fuzzy name matching | Custom edit distance | `rapidfuzz` | Already in requirements.txt from Phase 36; same API, handles accented chars |
| School district boundary import | Custom GeoJSON parser | `geopandas.to_postgis()` | Pattern already works in `import_school_board_districts.py`; 6 lines vs. 60 lines |
| Deduplication logic | Rewrite | Reuse `scrape_la_officials.py::find_existing_politician_for_seat()` | Seat-first matching is proven from Phase 36; same function works for any city/district |
| Coverage tracking | Runtime DB queries | In-config `status` field or report script | Simpler to implement; no DB schema change needed |

**Key insight:** Phase 37 is almost entirely data logistics, not new code. The hard algorithmic work (dedup, upsert, geo_id linking) is done in Phase 36. The planning challenge is managing 87+ sources with consistent conventions.

---

## Common Pitfalls

### Pitfall 1: at-large city geo_id vs district city geo_id (The Critical Classification)
**What goes wrong:** An at-large city's council members all share the place boundary (G4110, geo_id = Census GEOID). If you assign them the OCD-ID format (like district cities), the `geofence_lookup.go` JOIN fails because G4110 boundaries use Census GEOID, not OCD-ID format.
**Why it happens:** Phase 36 set `geo_id = ocd_id` for all LOCAL districts, but for at-large city council members there IS no per-member district — they represent the whole city. The geo_id must be the G4110 place GEOID (e.g., `0608954` for Burbank).
**How to avoid:** For at-large cities: `district.geo_id = place_geoid` (the 7-char Census GEOID from G4110 Phase 34 import). For district cities: `district.geo_id = ocd_id`. Mark `election_type` in config.
**Warning signs:** At-large city address returns 0 council members despite politician records existing — geo_id mismatch with G4110 geofence.

### Pitfall 2: SOS Roster PDF layout may vary between cities
**What goes wrong:** The CA SOS roster PDF is a multi-column text document. Small cities may list just "Mayor/Council Members" without district numbers (at-large). Large district-based cities may show "District 1: Name, District 2: Name" etc. The parser must handle both formats.
**Why it happens:** Each city submits its own data to SOS in varying formats. The PDF is compiled from those submissions.
**How to avoid:** `pdfplumber.page.extract_text()` returns text with whitespace-preserved layout. Parse line by line, look for patterns: (a) "Mayor:" followed by a name, (b) "Council Member" + name, (c) "District N:" + name. Build a parser that tolerates missing district numbers.
**Warning signs:** PDF parsing returns truncated name lists (5 members when there should be 7) or missing mayoral entries.

### Pitfall 3: El Monte malformed OCD-ID in database
**What goes wrong:** STATE.md documents that El Monte BallotReady records have malformed OCD-IDs (`state:nv` instead of `state:ca`). The `find_existing_politician_for_seat()` query matches on `ocd_id`, so El Monte records will never match if the DB has the wrong OCD-ID.
**Why it happens:** BallotReady data quality issue — Nevada abbreviation used instead of California.
**How to avoid:** At Phase 37 start, run a correction query:
```sql
UPDATE essentials.districts
SET ocd_id = REPLACE(ocd_id, 'state:nv', 'state:ca')
WHERE ocd_id LIKE '%state:nv%place:elmonte%' OR ocd_id LIKE '%state:nv%el_monte%';
```
Verify the update returns the expected rows before proceeding.
**Warning signs:** El Monte scraping shows "no seat found" for all council members despite them appearing in BallotReady cache.

### Pitfall 4: School district geo_id format must match Phase 34 G5420 import
**What goes wrong:** The CDE ArcGIS API provides `FedID` (e.g., `0601620`) and `CDCode` (e.g., `1964212`). Phase 34 may have used GEOID from TIGER G5420 shapefiles (which uses a different format). If the Phase 37 school district importer creates districts with `geo_id = FedID` but Phase 34 stored boundaries with `geo_id = GEOID`, the JOIN fails.
**Why it happens:** TIGER G5420 shapefiles use 7-character GEOID (`GEOID` field). CDE ArcGIS uses `FedID` (also 7 chars) and `CDCode` (7 chars). They may or may not be the same value.
**How to avoid:** Before writing school district imports, query:
```sql
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE mtfcc = 'G5420'
LIMIT 20;
```
Compare the geo_id values to CDE `FedID` and `CDCode` values. If they match, use FedID as the geo_id. If not, identify the matching field.
**Warning signs:** School board PIP tests return 0 results for any address — geo_id mismatch means no boundary-to-district JOIN.

### Pitfall 5: Trustee area boundaries for school districts not in Phase 34
**What goes wrong:** Phase 34 imported G5420 (unified school district) boundaries at the whole-district level. School districts that elect by trustee area need sub-district boundaries (like the Monroe County MCCSC pattern in `import_school_board_districts.py`). If a district elects 5 trustees by area and we only have the whole-district boundary, all 5 trustees show for any address in the district.
**Why it happens:** TIGER G5420 only has whole-district boundaries. Trustee area sub-polygons come from individual district GIS services.
**How to avoid:** For large unified districts (LAUSD, Long Beach USD, Pasadena USD), search for an ArcGIS FeatureServer with trustee area boundaries (same pattern as Phase 35 city council ward search). If found, import sub-boundaries with a trustee-area-specific geo_id. If not found, fall back to whole-district boundary and log as a gap.
**Warning signs:** An LAUSD address returns all 7 board members instead of 1 (the representative for that trustee area).

### Pitfall 6: High volume of sources overwhelming a single script run
**What goes wrong:** 87 cities + 80 districts = 167 sources. A single sequential script taking 10-30 seconds per site would run for 30-80 minutes. A transient network error mid-run forces a full restart.
**Why it happens:** No idempotency within a run — if the script fails at source 60, all 59 prior updates are rolled back (single transaction).
**How to avoid:** Implement per-source savepoints or per-source COMMIT (like the `autocommit = False` + source-level `conn.commit()` pattern). Alternatively, use the coverage `status` field in config — sources with `status = "scraped"` are skipped on re-run.
**Warning signs:** Script consistently fails at the same source; progress lost on restart.

### Pitfall 7: PDF extraction returning garbled text for small cities
**What goes wrong:** The SOS roster PDF may use embedded fonts or ligatures that cause `pdfplumber` to extract garbled names like "Shaufi" instead of "Shaufi". City names with special characters (accents, etc.) may also be misread.
**Why it happens:** PDF font encoding issues; common in government-produced PDFs. pdfplumber handles most cases but not all.
**How to avoid:** Post-process extracted names: strip non-ASCII characters, validate against known name patterns (at least 2 words, each starting with capital). Flag suspicious names (single-word, all lowercase, contains numbers) for manual review.
**Warning signs:** Names appear truncated or contain character substitutions (e.g., "fi" ligature read as "?" or missing).

---

## Code Examples

### CDE District List Download
```python
# Source: CDE data file structure verified via API (2026-02-24)
import csv, io, requests

def get_la_county_districts_cde():
    url = "https://www.cde.ca.gov/SchoolDirectory/report?rid=dl2&tp=txt"
    resp = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=30)
    text = resp.content.decode("utf-8", errors="replace")
    reader = csv.DictReader(io.StringIO(text), delimiter="\t")
    return [
        {
            "cd_code": row["CD Code"].replace(" ", ""),
            "name": row["District"].strip(),
            "phone": row.get("Phone", "").strip(),
        }
        for row in reader
        if row.get("County", "").strip() == "Los Angeles"
    ]
# Returns ~80-90 rows — all LA County public school districts
```

### CDE ArcGIS Boundary Query for LA County School Districts
```python
# Source: Verified API endpoint 2026-02-24
import requests, json

def get_la_county_school_district_boundaries():
    url = (
        "https://services3.arcgis.com/fdvHcZVgB2QSRNkL/arcgis/rest/services/"
        "SchoolDistrictAreas2425/FeatureServer/0/query"
        "?where=CountyName+%3D+%27Los+Angeles%27"
        "&outFields=CDCode,CDSCode,DistrictName,DistrictType,FedID"
        "&f=geojson&outSR=4326&resultRecordCount=200"
    )
    resp = requests.get(url, timeout=60)
    resp.raise_for_status()
    return resp.json()  # GeoJSON FeatureCollection

# Verified sample (2026-02-24):
# ABC Unified: CDCode=1964212, FedID=0601620
# Arcadia Unified: CDCode=1964261, FedID=0602970
```

### geo_id for School District (requires verification vs Phase 34)
```sql
-- Step 1: Inspect what geo_id format Phase 34 used for G5420 boundaries
SELECT geo_id, name, mtfcc
FROM essentials.geofence_boundaries
WHERE mtfcc = 'G5420'
ORDER BY imported_at DESC
LIMIT 20;

-- Step 2: Compare to CDE FedID (e.g., '0601620' for ABC Unified)
-- If they match → use FedID as geo_id in district upsert
-- If TIGER GEOID format (e.g., '1900080') → need to cross-reference CDE-to-TIGER mapping

-- Step 3: Set geo_id for SCHOOL districts (after confirming format):
UPDATE essentials.districts
SET geo_id = <verified_format_value>
WHERE district_type = 'SCHOOL'
  AND state = 'CA'
  AND (geo_id IS NULL OR geo_id = '');
```

### El Monte OCD-ID Correction
```sql
-- Fix malformed state:nv -> state:ca for El Monte records
-- From STATE.md: "El Monte BallotReady records have malformed OCD-IDs (state:nv instead of state:ca)"
UPDATE essentials.districts
SET ocd_id = REPLACE(ocd_id, '/state:nv/', '/state:ca/')
WHERE state = 'CA'
  AND ocd_id LIKE '%state:nv%'
  AND (ocd_id LIKE '%el_monte%' OR ocd_id LIKE '%elmonte%')
RETURNING id, ocd_id;
-- Expected: 3-5 rows for El Monte council districts
```

### At-Large City Council geo_id Assignment
```sql
-- At-large city council districts should use G4110 place GEOID as geo_id
-- Example: Burbank all-at-large council (5 members share place boundary)
-- G4110 boundary for Burbank was imported in Phase 34 with geo_id='0608954'

-- Create district row for at-large city with geo_id = place GEOID
INSERT INTO essentials.districts
    (id, external_id, ocd_id, label, district_type, state, geo_id,
     num_officials, is_judicial, has_unknown_boundaries, retention)
VALUES (
    gen_random_uuid(), -200101,
    'ocd-division/country:us/state:ca/place:burbank',
    'City of Burbank',
    'LOCAL',  -- All council members share same seat type
    'CA',
    '0608954',  -- G4110 Census GEOID for Burbank
    5,          -- Number of council seats
    false, false, false
)
ON CONFLICT (ocd_id) DO UPDATE SET geo_id = EXCLUDED.geo_id;
```

### Playwright Fallback Integration
```python
# Source: playwright.dev/python/docs/library (sync API)
from playwright.sync_api import sync_playwright

def fetch_with_playwright(url, wait_for_selector=None, timeout=30000):
    """Fetch page HTML after JS execution.

    Args:
        url: Target URL
        wait_for_selector: CSS selector to wait for before extracting HTML
        timeout: Navigation timeout in milliseconds

    Returns: HTML string after JS execution
    """
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()
        page.goto(url, timeout=timeout)
        if wait_for_selector:
            page.wait_for_selector(wait_for_selector, timeout=10000)
        else:
            page.wait_for_load_state("networkidle", timeout=timeout)
        html = page.content()
        browser.close()
    return html

# Usage: pass HTML to BeautifulSoup exactly like requests HTML
html = fetch_with_playwright("https://example-js-city.gov/city-council")
soup = BeautifulSoup(html, "html.parser")
```

---

## Source Strategy Recommendation (Claude's Discretion Areas)

### Cities: Aggregator-First with Per-City Fallback
**Recommendation: Use CA SOS Roster PDF as primary source for all 87 cities**

**Rationale:**
- The CA SOS Incorporated Cities and Town Officials PDF (`admin.cdn.sos.ca.gov/ca-roster/2026/cities-towns.pdf`) is published annually and covers all ~482 CA incorporated cities — all 87 LA County cities in scope are included
- This is the single best bulk source: one download, structured layout, official data, no rate limiting
- The 2026 edition (published late 2025) contains current officials as of the submission date
- PDF extraction with `pdfplumber` is simpler than per-city website scraping for the initial data load
- For verification and updates, per-city official websites can be scraped as a secondary pass

**Confidence:** MEDIUM — PDF structure must be verified at implementation time. If parsing proves too unreliable, fall back to per-city scraping using city website URLs from config.

**Fallback roster pattern:** Same as Phase 36 — hardcode a fallback roster for each city (or leave roster as `[]` and log as `needs_manual`) so the config-driven system degrades gracefully.

### School Boards: Per-District Website Scraping with CDE as Entry Point
**Recommendation: CDE district list → LACOE school directory → per-district website scraping**

**Rationale:**
- No bulk aggregator for board member names exists (confirmed via research — NCES, LACOE, LACSTA do not publish machine-readable member rosters)
- CDE district data file provides the definitive list of LA County districts with contact info
- Each district website typically has a "Board of Education" or "Board Members" page
- Pattern: load CDE list → for each district, fetch website → parse board members
- LAUSD (7 members), Long Beach USD (7 members), and other large districts have structured board pages; small districts have simpler pages

**The 90% target is realistic:** 80 districts, averaging ~5 board members each = ~400 records. Most district websites are static HTML with a basic "Meet Our Board" page. The hardest 10-15% (JS-heavy CMSes, poorly maintained sites) can be handled with Playwright or logged as manual gaps.

### Batching Strategy: Two-Plan Waves
**Recommendation: Split into two plans — Plan A (Cities) and Plan B (School Boards)**

- **Plan A:** SOS PDF extraction for 87 cities + geo_id handling (at-large vs district) + upsert
- **Plan B:** School board scraping using CDE list + boundary import for missing G5420 boundaries + upsert

Splitting into two plans reduces risk: city council data (simpler geo_id logic) is validated before school board data (more complex trustee area handling) begins.

---

## Open Questions

1. **SOS Roster PDF layout structure**
   - What we know: PDF exists at `admin.cdn.sos.ca.gov/ca-roster/2026/cities-towns.pdf`; confirmed to include council member names for incorporated cities; data is provided by local jurisdictions
   - What's unclear: Exact column structure, whether district numbers are included for district cities, whether layout is consistent across cities
   - Recommendation: Open PDF with `pdfplumber` as first task in Plan A. If layout is unsuitable for parsing, fall back to per-city website scraping for initial population.

2. **Phase 34 geo_id format for G5420 school district boundaries**
   - What we know: Phase 34 imported G5420 TIGER shapefiles. CDE ArcGIS uses `FedID` (7 chars, e.g., `0601620`). TIGER G5420 uses `GEOID` field.
   - What's unclear: Whether TIGER GEOID = CDE FedID for LA County unified districts
   - Recommendation: Query `SELECT geo_id FROM essentials.geofence_boundaries WHERE mtfcc = 'G5420' LIMIT 10` and compare to CDE FedID values at Plan B start.

3. **Which LA County cities are truly at-large vs by-district in 2026**
   - What we know: ~50% of CA cities now use district elections (CVRA trend); Phase 35 imported wards for 8 specific cities (LA, Long Beach, Pasadena, Torrance, Inglewood, West Covina, Glendale, and 5 gaps)
   - What's unclear: Status for the other ~80 cities — many may have recently switched from at-large
   - Recommendation: For each city in config, mark `election_type` based on available information. When scraping the SOS roster, district-numbered entries vs. plain member entries indicate election type.

4. **Community college district scope**
   - What we know: LA County has 13 community college districts. CONTEXT.md Deferred Ideas says "Community college board coverage if not included in 'all school districts' boundary data — evaluate during research."
   - What's unclear: Whether community college boards fall under "ALL LA County school districts" (as stated in locked decisions) or are deferred
   - Recommendation: Defer community college boards — they use a different `district_type` (would need a new MTFCC mapping), their boundaries are not in the G5420 import, and CONTEXT.md explicitly defers them. POL-04 says "80+ LA County unified school districts" — community colleges are not school districts in the K-12 sense.

5. **LAUSD trustee area boundaries — ArcGIS source availability**
   - What we know: LAUSD has 7 board members elected by trustee area. Phase 34 imported G5420 whole-district boundary only.
   - What's unclear: Whether LAUSD publishes trustee area boundaries via ArcGIS or GeoJSON
   - Recommendation: Search `arcgis.com` for "LAUSD trustee areas" or check `geohub.lacity.org` for LAUSD boundary layers at Plan B start. If found, import sub-district boundaries. If not found, use whole-district boundary (all 7 members return for any LAUSD address) and log as gap.

---

## Validation Architecture

> `workflow.nyquist_validation` is not set in `.planning/config.json` — Validation Architecture section omitted per instructions.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Scrape each city website independently | CA SOS Roster PDF as bulk aggregator | Phase 37 recommendation | Single download covers 87+ cities |
| Treat all cities as at-large | Check CVRA election type per city | Post-2016 CVRA wave | ~50% of cities now district-based |
| Skip school districts (covered by BallotReady for federal/state) | Per-district website scraping | Phase 37 | School boards rarely in BallotReady cache |
| Global transaction, rollback on any error | Per-source commit with status tracking | Phase 37 recommendation | 167 sources can't all be in one transaction |

---

## Sources

### Primary (HIGH confidence)
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/scrape_la_officials.py` — Phase 36 scraper framework (fully verified); `find_existing_politician_for_seat()`, `upsert_politician()`, `process_source()` all reusable for Phase 37
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/politician_sources.json` — Phase 36 config format verified; Phase 37 extends this structure
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/import_school_board_districts.py` — school district boundary import pattern verified; uses geopandas `to_postgis()` with G5420 MTFCC
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/arcgis_sources.json` — Phase 35 ArcGIS config pattern with `place_geoid`, `election_type`, `geo_id_template` fields — extensible for Phase 37
- `/Users/chrisandrews/Documents/GitHub/.planning/STATE.md` — documents El Monte malformed OCD-ID (`state:nv`) bug
- CDE ArcGIS API `services3.arcgis.com/fdvHcZVgB2QSRNkL/arcgis/rest/services/SchoolDistrictAreas2425/FeatureServer/0` — verified 2026-02-24; returns LA County districts with CDCode, FedID, geometry in GeoJSON
- CDE district data file `cde.ca.gov/SchoolDirectory/report?rid=dl2&tp=txt` — verified 2026-02-24; tab-delimited with CDCode, District name, County, phone; does NOT include board member names

### Secondary (MEDIUM confidence)
- CA SOS 2026 Roster URL `admin.cdn.sos.ca.gov/ca-roster/2026/cities-towns.pdf` — confirmed URL returns a PDF; content structure unverified (WebFetch returned compressed binary); must inspect at implementation time
- Rose Institute April 2025 report "Mapping the Revolution in California City Council Election Systems" — confirms ~50% of CA cities now use district elections as of 2024
- LA Almanac school district list `laalmanac.com/education/ed01.php` — lists 52 unified, 24 elementary, 3-5 high school districts in LA County (80 total); counts verified against LACOE's stated "80 public school districts"
- WebSearch confirmed: NCES, LACSTA, LACOE do not publish machine-readable board member rosters — per-district scraping is required
- playwright.dev/python — official docs confirm sync API pattern `sync_playwright()` + `page.content()` + BeautifulSoup is the standard integration pattern

### Tertiary (LOW confidence)
- LACOE HARS MapServer `egis2.lacounty.gov/arcgis/rest/services/LACOE/HARS/MapServer` — confirmed in search results as school district layer source but URL returned 503; alternative to CDE ArcGIS API
- data.lacounty.gov school district boundaries dataset — mentioned in search results; details unverified due to 503 error on direct access

---

## Metadata

**Confidence breakdown:**
- Phase 36 scraper framework extensibility: HIGH — read source code directly; all key functions are self-contained and parameterized
- CA SOS Roster as bulk source: MEDIUM — URL confirmed, PDF exists, content structure must be verified at implementation
- School district geo_id format: MEDIUM — CDE FedID identified as likely geo_id candidate; must verify against Phase 34 `geofence_boundaries` at implementation
- at-large vs by-district city classification: MEDIUM — CVRA trend confirmed (~50%), specific LA County city list requires config-time research
- Playwright integration pattern: HIGH — official docs verified, sync API pattern confirmed

**Research date:** 2026-02-24
**Valid until:** 2026-05-24 (city council rosters change on election cycles; SOS roster is annual; school board terms are 4 years)
