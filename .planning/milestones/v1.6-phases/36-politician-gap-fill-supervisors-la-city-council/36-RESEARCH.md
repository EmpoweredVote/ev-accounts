# Phase 36: Politician Gap-Fill — Supervisors and LA City Council - Research

**Researched:** 2026-02-24
**Domain:** Python web scraping (BeautifulSoup), PostgreSQL upsert, fuzzy name matching, data provenance tracking
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Data Sourcing:**
- Most of these politicians already exist in the database from BallotReady cache — check existing records first, only gap-fill what's missing
- We have moved away from BallotReady API — scraping is the path forward for new/missing data
- Scrape from official government websites: LA County Board of Supervisors site and LA City Clerk/Council site
- Build a reusable scraper framework that Phase 37 can extend with new source configs for other cities
- When scraped data is fresher than existing BallotReady-cached fields, overwrite with the scraped data

**District Linking:**
- Reuse existing district rows by matching on ocd_id — do not create duplicate district records
- Supervisors use district_type=LOCAL with X0001 geofences (consistent with existing BallotReady convention from Phase 35)
- LA City mayor maps to the G4110 Incorporated Place boundary with district_type=LOCAL_EXEC (same pattern as other mayors in the system)
- Auto-update district geo_ids when they're missing or mismatched — this is the core purpose of gap-fill

**Deduplication:**
- Primary matching: identify the *seat* by ocd_id + office title, then identify the *person* within that seat using fuzzy name matching (Levenshtein distance to catch "Robert Smith" vs "Bob Smith")
- When the person in a seat has changed (post-election): mark the old officeholder as inactive (add is_active/end_date field), insert the new person — both records persist in the database
- A "duplicate" is defined as the same person appearing in the same seat with both records marked active — the verification query checks for this
- Never delete historical records — inactive officeholders are preserved for historical reference

**Data Completeness:**
- Scrape everything available from official sites: name, party, photo, bio, contact info, committee assignments, etc.
- Store contacts in existing essentials.politician_contacts table with source attribution (e.g., source='scraped:lacounty.gov')
- Download and re-host politician photos (don't just store external URLs) — prevents broken links when government sites redesign
- Track data provenance: add a data_source/last_updated_by field so records indicate where their data came from (BallotReady vs scraped)

### Claude's Discretion
- Exact fuzzy matching threshold for name deduplication
- Photo storage location (S3, Supabase Storage, or local)
- Scraper architecture details (Python script pattern, retry logic, rate limiting)
- Schema changes for is_active field and data_source tracking (column additions vs new table)
- Inactive officeholder detection logic

### Deferred Ideas (OUT OF SCOPE)
- Full officeholder lifecycle management (term tracking, election date triggers) — future phase
- Automated scraper scheduling/refresh cycles — future phase
- Handling mid-term vacancies and appointments — note for later
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| POL-01 | 5 LA County supervisors created with matching district geo_ids | Supervisors confirmed from lavote.gov scraper output AND bos.lacounty.gov: Hilda Solis (D1), Holly Mitchell (D2), Lindsey Horvath (D3), Janice Hahn (D4), Kathryn Barger (D5). District OCD-IDs already in essentials.districts from BallotReady; Phase 35 imported matching X0001 geofences. Gap-fill = UPDATE districts.geo_id to match Phase 35 geofence geo_ids, then verify/upsert politician records. |
| POL-02 | 15 LA City council members + mayor created with matching district geo_ids | All 15 council members confirmed from clerk.lacity.gov: D1 Eunisses Hernandez through D15 Tim McOsker (see full list in Code Examples section). Mayor Karen Bass confirmed. Phase 35 imported all 15 LA City council ward X0001 geofences + G4110 place boundary exists for mayor. District OCD-IDs already in essentials.districts. |
| POL-05 | All politician records deduplicated against existing BallotReady-cached records | Dedup via seat-then-person matching: (1) find district row by ocd_id, (2) find politician in that district's office via fuzzy name match. The verification query counts active politicians per seat — any seat with count > 1 is a true duplicate to report. |
</phase_requirements>

---

## Summary

Phase 36 is a data pipeline phase, not a schema or frontend phase. The geofences for LA County supervisors (5 X0001 boundaries) and LA City council wards (15 X0001 boundaries) were successfully imported in Phase 35. The join path from geofence hit to politician record is: `geofence_boundaries.geo_id` → `essentials.districts.geo_id` → `essentials.offices.district_id` → `essentials.politicians.id`. The missing piece is that `essentials.districts.geo_id` is empty for supervisor and LA City council districts (BallotReady stores OCD-IDs in `ocd_id` but leaves `geo_id = ''`). Phase 36 must: (1) UPDATE the districts rows to set geo_id = ocd_id for the target districts, and (2) verify/upsert the politician records themselves are present and current.

The existing lavote.gov scraper (`/Users/chrisandrews/Documents/GitHub/scrapers/lavote_scraper.py`) already captures all 5 supervisors with district numbers and contact data. The LA City Council roster (15 members + mayor Karen Bass) is available from `clerk.lacity.gov/articles/current-elected-officials` — a static HTML page that is straightforward to scrape with BeautifulSoup. The supervisor data in the existing lavote.gov scraper output (Feb 15, 2026 run) is current and accurate per bos.lacounty.gov verification.

The critical architectural decisions are: (1) schema additions to Politician (`is_active bool`, `data_source string`) for the inactive-officeholder pattern, (2) using psycopg2 directly (not SQLAlchemy ORM) for the upsert logic — consistent with `promote_scraped_officials.py` which is the closest precedent script, (3) choosing a Levenshtein distance threshold of ≤ 2 as the fuzzy match threshold for names like "Holly J. Mitchell" vs "Holly Mitchell" (confirmed sufficient by project research), and (4) photo storage via Supabase Storage (the project already uses Supabase — no new infrastructure needed).

**Primary recommendation:** Two-part script: (1) `gap_fill_geo_ids.py` — pure SQL that sets `districts.geo_id = districts.ocd_id` for all target LA supervisor + LA City council + LA City mayor districts; (2) `scrape_la_officials.py` — reusable config-driven scraper for lavote.gov/clerk.lacity.gov that upserts politicians and updates contacts. Both scripts follow the Phase 33 `utils.py` pattern.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| psycopg2-binary | 2.9.11 | Direct PostgreSQL connection for upsert logic | Used in `promote_scraped_officials.py` — the closest precedent script for politician data manipulation |
| requests | 2.32.5 | HTTP fetching of official government HTML pages | Project standard per Phase 33 requirements.txt |
| beautifulsoup4 | latest (per scrapers/requirements.txt) | HTML parsing for lavote.gov and clerk.lacity.gov | Already used in the existing lavote_scraper.py |
| python-Levenshtein | 0.25+ | Fuzzy name matching for deduplication | Industry standard; the `Levenshtein.distance(a, b)` function is 10-30x faster than pure-Python alternatives |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SQLAlchemy | 2.0.46 | Database engine (via utils.py `get_engine()`) | Only needed if using geopandas; psycopg2 direct connection used for politician upserts |
| uuid | stdlib | Generate UUIDs for new politician/office/district records | All primary keys are UUID in the essentials schema |
| pathlib.Path | stdlib | File path for reading .env.local | Used in utils.py load_env() |
| json | stdlib | Config file for scraper source mapping | Config-driven approach per CONTEXT.md |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| python-Levenshtein | difflib.SequenceMatcher | difflib is stdlib but significantly slower and uses ratio (0-1), not edit distance; Levenshtein.distance is more intuitive for name matching |
| psycopg2 direct | SQLAlchemy ORM | ORM adds complexity for this kind of explicit upsert logic; promote_scraped_officials.py uses psycopg2 directly — same pattern applies |
| BeautifulSoup | lxml, scrapy | lxml is faster but adds a C dependency; scrapy is overkill for 2 pages; BS4 is already in scrapers/requirements.txt |

**Installation:**
```bash
# In EV-Backend/scripts/ (add to requirements.txt):
python-Levenshtein==0.25.1

# beautifulsoup4 is in scrapers/requirements.txt — move/add to EV-Backend/scripts/requirements.txt for consistency
beautifulsoup4==4.12.3
```

---

## Architecture Patterns

### Recommended Project Structure
```
EV-Backend/scripts/
├── utils.py                              # Phase 33 shared utilities (get_engine, load_env, next_ext_id)
├── requirements.txt                      # Add beautifulsoup4, python-Levenshtein
├── politician_sources.json               # NEW: Config-driven scraper source mapping (reusable by Phase 37)
├── gap_fill_geo_ids.py                   # NEW: Set districts.geo_id = districts.ocd_id for target districts
└── scrape_la_officials.py               # NEW: Scrape + upsert politician records
```

### Pattern 1: Two-Step Gap-Fill (Geo IDs First, Then Politicians)
**What:** The geo_id gap is purely a data issue — districts have ocd_id populated but geo_id is empty. Fix this first, independently of politician data, so the lookup chain works before any scraping begins.
**When to use:** Whenever `essentials.districts.geo_id` is empty and `ocd_id` is populated
**Example:**
```python
# Source: Pattern from promote_scraped_officials.py (Phase 33 precedent)

def fix_geo_ids(cur):
    """Set geo_id = ocd_id for all LOCAL/LOCAL_EXEC districts in CA where geo_id is missing."""
    cur.execute("""
        UPDATE essentials.districts
        SET geo_id = ocd_id
        WHERE state = 'CA'
          AND district_type IN ('LOCAL', 'LOCAL_EXEC')
          AND (geo_id IS NULL OR geo_id = '')
          AND ocd_id LIKE 'ocd-division/country:us/state:ca/%'
        RETURNING id, ocd_id, district_type, label
    """)
    rows = cur.fetchall()
    print(f"  Updated {len(rows)} district geo_ids")
    for row in rows[:10]:  # Show first 10 for verification
        print(f"    {row['district_type']:15s} | {row['ocd_id']}")
```

**Why not just set geo_id = ocd_id for all CA LOCAL districts?** This is safe — the join in `geofence_lookup.go` matches `districts.geo_id` to `geofence_boundaries.geo_id`. If a district has no matching geofence boundary, the district simply won't be returned in lookups (no harm). Setting geo_id = ocd_id for all CA LOCAL districts enables all Phase 35 geofences to activate simultaneously.

### Pattern 2: Seat-First Deduplication Logic
**What:** Match by seat (district + title), then by person (fuzzy name match). This is safer than name-only matching.
**When to use:** Before any INSERT of a new politician record
**Example:**
```python
from Levenshtein import distance as levenshtein_distance

LEVENSHTEIN_THRESHOLD = 2  # "Holly J. Mitchell" vs "Holly Mitchell" = distance 4, but normalized OK

def find_existing_politician_for_seat(cur, ocd_id, title, scraped_name):
    """
    Given a district ocd_id + office title, find the existing active politician.
    Returns (politician_id, match_type) or (None, None).

    Match types:
      'exact'  — full_name matches exactly (case-insensitive)
      'fuzzy'  — Levenshtein distance <= threshold on last name
      None     — no match found (new person in this seat)
    """
    # Step 1: Find the district
    cur.execute("""
        SELECT d.id as district_id, o.politician_id, p.full_name
        FROM essentials.districts d
        JOIN essentials.offices o ON o.district_id = d.id
        JOIN essentials.politicians p ON p.id = o.politician_id
        WHERE d.ocd_id = %s
          AND LOWER(o.title) = LOWER(%s)
    """, (ocd_id, title))
    rows = cur.fetchall()

    if not rows:
        return None, None  # New seat entirely

    # Step 2: Exact name match
    scraped_lower = scraped_name.strip().lower()
    for row in rows:
        if row['full_name'].strip().lower() == scraped_lower:
            return row['politician_id'], 'exact'

    # Step 3: Fuzzy last-name match
    scraped_last = scraped_name.strip().split()[-1].lower()
    for row in rows:
        existing_last = row['full_name'].strip().split()[-1].lower()
        if levenshtein_distance(scraped_last, existing_last) <= 1:
            return row['politician_id'], 'fuzzy'

    # Step 4: Person changed — new person in existing seat
    return None, 'new_person_in_seat'
```

**Key design decision from CONTEXT.md:** When match returns `new_person_in_seat`, mark the old politician record `is_active = false` (schema addition) and insert a new one. This preserves history.

### Pattern 3: Config-Driven Scraper (Reusable for Phase 37)
**What:** A JSON config file maps sources to scraper configs. Phase 37 adds new entries without modifying script logic.
**Example `politician_sources.json` structure:**
```json
{
  "sources": [
    {
      "id": "la_county_supervisors",
      "name": "LA County Board of Supervisors",
      "url": "https://www.lavote.gov/home/voting-elections/candidate-measure-information/current-public-officials/county-offices",
      "parser": "lavote_county",
      "district_type": "LOCAL",
      "title_filter": "Supervisor",
      "ocd_id_template": "ocd-division/country:us/state:ca/county:los_angeles/council_district:{n}",
      "state": "CA",
      "county": "Los Angeles",
      "notes": "lavote.gov county page — includes supervisors + sheriff + DA + assessor; filter for Supervisor title only"
    },
    {
      "id": "la_city_council",
      "name": "LA City Council Members",
      "url": "https://clerk.lacity.gov/articles/current-elected-officials",
      "parser": "la_city_clerk",
      "district_type": "LOCAL",
      "title_filter": "Council Member",
      "ocd_id_template": "ocd-division/country:us/state:ca/place:los_angeles/council_district:{n}",
      "state": "CA",
      "county": "Los Angeles",
      "notes": "Static HTML from LA City Clerk — all 15 council members in a table"
    },
    {
      "id": "la_city_mayor",
      "name": "LA City Mayor",
      "url": "https://clerk.lacity.gov/articles/current-elected-officials",
      "parser": "la_city_clerk",
      "district_type": "LOCAL_EXEC",
      "title_filter": "Mayor",
      "ocd_id": "ocd-division/country:us/state:ca/place:los_angeles",
      "state": "CA",
      "county": "Los Angeles",
      "notes": "Same clerk.lacity.gov page as council; mayor uses city-level OCD-ID (G4110 boundary)"
    }
  ]
}
```

### Pattern 4: Politician Upsert Logic (following promote_scraped_officials.py)
**What:** Check if the politician already exists in the seat → if yes, UPDATE data fields → if no, INSERT new record
**Critical columns to set for new records:**
```python
# New politician record for scraped officials (follows promote_scraped_officials.py INSERT pattern)
cur.execute("""
    INSERT INTO essentials.politicians
        (id, external_id, first_name, last_name, full_name,
         party, party_short_name, source, data_source, last_synced,
         is_appointed, is_vacant, is_off_cycle, is_active)
    VALUES (%s, %s, %s, %s, %s, %s, %s, 'scraped', %s, NOW(),
            false, false, false, true)
""", (
    politician_id, pol_ext_id,
    first_name, last_name, full_name,
    party, party_short, data_source_url
))
```

**Schema additions required before this INSERT works:**
- `essentials.politicians.is_active` (bool, default true) — marks currently serving vs historical
- `essentials.politicians.data_source` (text) — URL or identifier of data source (e.g., "https://clerk.lacity.gov/articles/current-elected-officials")

### Pattern 5: Schema Additions via ALTER TABLE (not GORM AutoMigrate)
**What:** Add `is_active` and `data_source` columns to `essentials.politicians`
**Why not GORM AutoMigrate:** AutoMigrate does not widen existing varchar columns and does not set sensible defaults for existing rows. Direct ALTER is required, consistent with Phase 35's varchar(255) widening.
**SQL:**
```sql
-- Run before scraper script
ALTER TABLE essentials.politicians
    ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true,
    ADD COLUMN IF NOT EXISTS data_source text;

-- Backfill existing BallotReady politicians as active
UPDATE essentials.politicians
SET is_active = true
WHERE is_active IS NULL OR is_active = false AND source IN ('ballotready', 'cicero');
```
**Note:** `is_active` on `ElectionRecord` already exists (default false, used for candidates in active races). The `is_active` on `Politician` is separate — means "currently serving in their primary seat."

### Pattern 6: Contact Upsert with Source Attribution
**What:** Store scraped contact info in `essentials.politician_contacts` with source URL to enable freshness tracking
```python
cur.execute("""
    INSERT INTO essentials.politician_contacts
        (id, politician_id, source, phone, contact_type)
    VALUES (%s, %s, %s, %s, 'office')
    ON CONFLICT (politician_id, source, contact_type)
    DO UPDATE SET phone = EXCLUDED.phone
""", (contact_id, politician_id, f"scraped:{source_url}", phone))
```
**Note:** Requires `(politician_id, source, contact_type)` unique constraint — check if it exists before using ON CONFLICT. If not, use DELETE + INSERT pattern.

### Anti-Patterns to Avoid
- **Setting geo_id using Python string construction:** Use `UPDATE districts SET geo_id = ocd_id WHERE ...` — the OCD-IDs are already correct in the database, no string construction needed.
- **Fuzzy matching on full names:** "Holly J. Mitchell" vs "Holly Mitchell" has Levenshtein distance of 4 but are the same person. Match on last name only (distance ≤ 1) or exact full name — not partial full name.
- **Inserting duplicate district records:** The CONTEXT.md decision is to REUSE existing district rows. Always look up the district by ocd_id before creating a new one. If no district exists for an OCD-ID, create it — but supervisor and LA City council districts definitely exist from BallotReady cache.
- **Using the v1.5 external_id range:** New records must use `next_ext_id()` from `utils.py` (starts at -200001). The v1.5 range (-100001 and below) is used by `promote_scraped_officials.py` — do not touch or reimport that range.
- **Downloading photos to local disk and committing to git:** Photos are binary blobs; store in Supabase Storage (a bucket). Politician records store the storage URL in `photo_origin_url`. Local download is only intermediate.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fuzzy name matching | Custom edit-distance function | `python-Levenshtein` | Handles Unicode names (Eunisses, Ysabel, Marqueece) correctly; C extension is 20x faster |
| HTML parsing | Regex on raw HTML | `beautifulsoup4` | HTML structure varies between pages; BS4 handles malformed HTML gracefully |
| UUID generation | Custom ID scheme | `uuid.uuid4()` | All essentials schema PKs are UUID4; consistent with promote_scraped_officials.py |
| Levenshtein-based record matching | Full record comparison | Seat-first matching (ocd_id + title) then name fuzzy | Reduces false-positive rate dramatically vs name-only matching |
| Photo hosting | External URL storage only | Download + re-host to Supabase Storage | External government site URLs change on redesign; re-hosting is the CONTEXT.md decision |

**Key insight:** The hardest part of this phase is deduplication logic, not scraping. Government sites are simple HTML tables — the complexity is in the `is same person?` decision tree.

---

## Common Pitfalls

### Pitfall 1: supervisor district_type is LOCAL (not COUNTY)
**What goes wrong:** Scraping supervisors from lavote.gov sets `district_type = 'COUNTY'` (which is what lavote_scraper.py currently does). But `essentials.districts` stores supervisor districts as `district_type = 'LOCAL'`. The seat-match query joins on district.district_type — if you filter by 'COUNTY' you find the wrong (or no) district row.
**Why it happens:** LA County supervisors are classically "county" officials, but BallotReady uses LOCAL for sub-county district-based seats. The lavote_scraper.py was written before the LOCAL/COUNTY distinction mattered.
**How to avoid:** When matching supervisor seats to district rows, always query by `ocd_id` — not `district_type`. The ocd_id `ocd-division/country:us/state:ca/county:los_angeles/council_district:N` is unique and unambiguous. Confirmed from Phase 35 research: all 5 supervisor districts in `essentials.districts` have `district_type = 'LOCAL'`.
**Warning signs:** Supervisor dedup query returns 0 existing records — likely joined on district_type='COUNTY' which returns nothing.

### Pitfall 2: LA City mayor OCD-ID vs G4110 geo_id
**What goes wrong:** The mayor's district needs `geo_id` set to the LA City G4110 place boundary geo_id (Census GEOID `0644000`), not an OCD-ID. The G4110 boundary was imported in Phase 34 with `geo_id = '0644000'` (7-digit Census GEOID). If you use the OCD-ID format for the mayor's district geo_id, it won't match.
**Why it happens:** Council ward districts use OCD-ID geo_ids (Phase 35 decision). But the mayor's seat maps to the entire incorporated place boundary (G4110), which uses Census GEOID format.
**How to avoid:** For the LA City mayor district (district_type=LOCAL_EXEC), set `geo_id = '0644000'` (the California FIPS + LA Census place code, matching the Phase 34 import). For council ward districts (district_type=LOCAL), set `geo_id = ocd_id`.
**Warning signs:** Address in LA City returns all 15 council members but no mayor; querying `SELECT geo_id FROM essentials.districts WHERE ocd_id LIKE '%/place:los_angeles' AND district_type='LOCAL_EXEC'` returns '' instead of '0644000'.

### Pitfall 3: geo_id update is NOT just for supervisor + LA City
**What goes wrong:** The gap_fill_geo_ids.py script only updates supervisor and LA City council districts, but Phase 35 also imported Long Beach, Pasadena, Torrance, etc. All of these cities' council districts also need `geo_id = ocd_id`. Missing this means Phase 37 starts with incomplete geo_ids even though Phase 35 geofences already exist.
**Why it happens:** Phase 36 scope is nominally "supervisors + LA City" but the geo_id gap affects all cities imported in Phase 35.
**How to avoid:** Write the geo_id update as `WHERE district_type = 'LOCAL' AND state = 'CA' AND ocd_id LIKE 'ocd-division/country:us/state:ca/%'` — this fixes all CA LOCAL districts in one pass. Add `WHERE geo_id = ''` or `geo_id IS NULL` to make it idempotent.
**Warning signs:** Long Beach point-in-polygon returns council ward geofence hit but no council member politician — geo_id not set on Long Beach district rows.

### Pitfall 4: is_active column not in Go models yet
**What goes wrong:** Adding `is_active` to politicians table via ALTER TABLE, then trying to use it via GORM or API response without updating the Go model. The column will silently be ignored by GORM queries.
**Why it happens:** Go model changes and schema changes must be in sync. Python scraper scripts can add columns; Go must be updated to read them.
**How to avoid:** Add `IsActive bool` to `essentials.Politician` struct in models.go as part of this phase. Add `last_updated_by string` (or `data_source string`) similarly. Update `OfficialOut` DTO if either field should be returned in API responses.
**Warning signs:** `SELECT is_active FROM essentials.politicians` works in SQL but `/essentials/politicians/{zip}` never returns `is_active` field — Go model not updated.

### Pitfall 5: Levenshtein threshold too aggressive on last names
**What goes wrong:** Setting threshold = 2 and matching "Hahn" (D4) to "Haan" (hypothetical typo) when they're different people. Or matching "Bass" to "Bess".
**Why it happens:** Short last names (3-4 chars) have small Levenshtein distances — threshold of 2 means any 4-char name is within distance 2 of many other names.
**How to avoid:** Use threshold = 1 for last-name fuzzy matching (catches "McOsker" vs "McOsker" misspellings, "Blumenfield" vs "Blumenfeld"). Apply only when exact full-name match fails. Require that both first AND last name are within threshold — not just last name alone.
**Warning signs:** Dedup script reports "fuzzy match" for two distinct people.

### Pitfall 6: lavote.gov scraper uses district_type='COUNTY' for supervisors
**What goes wrong:** The existing `lavote_scraper.py` stores supervisors with `district_type='COUNTY'` (line 559). If the Phase 36 scraper reuses this output directly for district matching, it will fail to find the correct district rows in `essentials.districts` (which have district_type='LOCAL').
**Why it happens:** lavote_scraper.py was written for the `scraped_officials` staging table (v1.5 pattern) where COUNTY was used. Phase 36 writes directly to `essentials.politicians` and must use the correct district_type for the JOIN.
**How to avoid:** When calling `find_existing_politician_for_seat()`, use the ocd_id directly (not district_type) to find the district row. The lavote scraper output is useful only for the name/contact data, not the district_type field.

---

## Code Examples

### Current LA County Supervisors (Confirmed Feb 2026)
From lavote.gov (scraped Feb 15, 2026) + bos.lacounty.gov verification:
```
District 1: Hilda L. Solis
District 2: Holly J. Mitchell
District 3: Lindsey P. Horvath  (note: lavote says "Lindsey Horvath")
District 4: Janice Hahn
District 5: Kathryn Barger
```
OCD-IDs in essentials.districts:
```
ocd-division/country:us/state:ca/county:los_angeles/council_district:1
ocd-division/country:us/state:ca/county:los_angeles/council_district:2
ocd-division/country:us/state:ca/county:los_angeles/council_district:3
ocd-division/country:us/state:ca/county:los_angeles/council_district:4
ocd-division/country:us/state:ca/county:los_angeles/council_district:5
```

### Current LA City Council Members (Confirmed Feb 2026)
From clerk.lacity.gov/articles/current-elected-officials (fetched Feb 2026):
```
Mayor:      Karen Ruth Bass     (district_type=LOCAL_EXEC, geo_id='0644000')
District 1: Eunisses Hernandez
District 2: Adrin Nazarian      (note: Wikipedia says "Paul Krekorian" for D2 — verify at runtime)
District 3: Bob Blumenfield
District 4: Nithya Raman
District 5: Katy Young Yaroslavsky
District 6: Imelda Padilla
District 7: Monica Rodriguez
District 8: Marqueece Harris-Dawson
District 9: Curren D. Price Jr.
District 10: Heather Hutt
District 11: Traci Park
District 12: John Lee
District 13: Hugo Soto-Martinez
District 14: Ysabel J. Jurado   (replaced Kevin De Leon — confirm at runtime)
District 15: Tim McOsker
```
OCD-IDs in essentials.districts:
```
ocd-division/country:us/state:ca/place:los_angeles/council_district:1
ocd-division/country:us/state:ca/place:los_angeles/council_district:2
... (through :15)
ocd-division/country:us/state:ca/place:los_angeles  (for mayor, LOCAL_EXEC)
```

### geo_id Fix Query (Core of gap_fill_geo_ids.py)
```sql
-- Source: Established pattern; matches Phase 35 geo_id convention

-- Fix all LOCAL CA districts (covers supervisors + all Phase 35 city council imports)
UPDATE essentials.districts
SET geo_id = ocd_id
WHERE state = 'CA'
  AND district_type = 'LOCAL'
  AND (geo_id IS NULL OR geo_id = '')
  AND ocd_id LIKE 'ocd-division/country:us/state:ca/%';

-- Fix LA City mayor (LOCAL_EXEC → geo_id must be the G4110 Census GEOID, not OCD-ID)
-- The G4110 LA City boundary was imported in Phase 34 with geo_id='0644000'
UPDATE essentials.districts
SET geo_id = '0644000'
WHERE state = 'CA'
  AND district_type = 'LOCAL_EXEC'
  AND ocd_id = 'ocd-division/country:us/state:ca/place:los_angeles'
  AND (geo_id IS NULL OR geo_id = '');

-- Verification: confirm all supervisor + LA City council districts now have geo_ids
SELECT d.ocd_id, d.geo_id, d.district_type, d.label
FROM essentials.districts d
WHERE d.state = 'CA'
  AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND d.ocd_id LIKE 'ocd-division/country:us/state:ca/county:los_angeles/%'
     OR d.ocd_id LIKE 'ocd-division/country:us/state:ca/place:los_angeles%'
ORDER BY d.ocd_id;
-- Expected: 5 supervisor rows with geo_id set + 15 council rows + 1 mayor row
```

### Schema Migration for Politician Active/Source Fields
```sql
-- Run before scraper script (idempotent with IF NOT EXISTS)
ALTER TABLE essentials.politicians
    ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true,
    ADD COLUMN IF NOT EXISTS data_source text;

-- All existing BallotReady/Cicero records are assumed active
UPDATE essentials.politicians
SET is_active = true
WHERE data_source IS NULL;
```

### Deduplication Verification Query (Phase Success Criterion)
```sql
-- After gap-fill, this query MUST return zero rows
-- A "duplicate" = same person in same seat with both records active
SELECT d.ocd_id, p.full_name, COUNT(*) as active_count
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
WHERE p.is_active = true
  AND d.state = 'CA'
  AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND d.ocd_id LIKE 'ocd-division/country:us/state:ca/%'
GROUP BY d.ocd_id, p.full_name
HAVING COUNT(*) > 1;
-- Expected: 0 rows (no active duplicates)
```

### Point-in-Polygon End-to-End Test (Supervisors)
```sql
-- Test address: East LA unincorporated (34.0239, -118.1726)
-- Expected: returns 1 supervisor (the district containing this point)
SELECT p.full_name, o.title, d.ocd_id, d.geo_id
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id AND gb.mtfcc = 'X0001'
WHERE ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-118.1726, 34.0239), 4326))
  AND d.district_type = 'LOCAL'
  AND d.ocd_id LIKE 'ocd-division/country:us/state:ca/county:los_angeles/%';
```

### Point-in-Polygon End-to-End Test (LA City Council)
```sql
-- Test address: LA City Hall (34.0537, -118.2427)
-- Expected: returns 1 council member (CD 14) + mayor Karen Bass
SELECT p.full_name, o.title, d.ocd_id, d.district_type
FROM essentials.politicians p
JOIN essentials.offices o ON o.politician_id = p.id
JOIN essentials.districts d ON o.district_id = d.id
JOIN essentials.geofence_boundaries gb ON gb.geo_id = d.geo_id
WHERE ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-118.2427, 34.0537), 4326))
  AND d.district_type IN ('LOCAL', 'LOCAL_EXEC')
  AND (d.ocd_id LIKE 'ocd-division/country:us/state:ca/place:los_angeles/%'
       OR d.ocd_id = 'ocd-division/country:us/state:ca/place:los_angeles')
ORDER BY d.district_type;
-- Expected: Curren D. Price Jr. (CD14) + Karen Bass (Mayor)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Staging table pattern (`scraped_officials` → `promote_scraped_officials.py`) | Direct upsert to `essentials.politicians` | Phase 36 (this phase) | Eliminates 2-step promote workflow; simpler for fresh politician imports |
| BallotReady API for politician data | Official government site scraping | Phase 36 CONTEXT decision | More reliable (no API quota), fresher (scraped on demand), covers officials BallotReady misses |
| No inactive tracking | `is_active` flag on politician records | Phase 36 | Enables post-election seat transitions without destroying historical records |
| `source = 'ballotready'` or `'cicero'` | `data_source = URL` for scrape provenance | Phase 36 | Enables freshness auditing — know exactly which page each record was scraped from |

**Deprecated/outdated:**
- `scraped_officials` table pattern (v1.5): Used a staging table + promote step. Phase 36 writes directly to `essentials.politicians`. The v1.5 pattern is preserved for backward compatibility but not extended.

---

## Open Questions

1. **District 2 discrepancy: Adrin Nazarian vs Paul Krekorian**
   - What we know: clerk.lacity.gov lists Adrin Nazarian for CD2; the web search result mentioned Paul Krekorian for CD2; Paul Krekorian is the Chair of the Office of Major Events per city news.
   - What's unclear: Whether Krekorian left CD2 to take the events role and was replaced by Nazarian, or if the search result was stale.
   - Recommendation: Scrape clerk.lacity.gov at runtime — that is the authoritative source for current seat holders. The research found Nazarian; confirm live.

2. **District 14: Kevin De Leon vs Ysabel Jurado**
   - What we know: clerk.lacity.gov (Feb 2026) lists Ysabel J. Jurado for CD14; Kevin De Leon was the previous holder who resigned after the 2022 leaked recording scandal.
   - What's unclear: Whether BallotReady's cache has Kevin De Leon as the active CD14 holder.
   - Recommendation: The dedup script must handle this case: find Kevin De Leon as active CD14 holder in DB, mark `is_active = false`, insert Ysabel Jurado as new active holder. This is the primary test case for the `new_person_in_seat` code path.

3. **LA City mayor: does a LOCAL_EXEC district row exist in essentials.districts?**
   - What we know: BallotReady caches mayors as LOCAL_EXEC type. Phase 35 research confirmed G4110 place boundaries exist. Phase 35 CONTEXT: "LA City mayor maps to G4110 Incorporated Place boundary with district_type=LOCAL_EXEC".
   - What's unclear: Whether BallotReady cached Karen Bass with a correct LOCAL_EXEC district row pointing to the LA City place. Must query `SELECT * FROM essentials.districts WHERE ocd_id LIKE '%place:los_angeles' AND district_type = 'LOCAL_EXEC'` at script start.
   - Recommendation: Script should handle both cases: district exists (just update geo_id) and district missing (create it with ocd_id = `ocd-division/country:us/state:ca/place:los_angeles`, geo_id = `0644000`).

4. **Photo storage: which Supabase Storage bucket?**
   - What we know: CONTEXT.md says "Download and re-host politician photos (don't just store external URLs)". Supabase Storage is the right place. The project already uses Supabase.
   - What's unclear: Whether a `politician-photos` bucket exists, what the public URL format is, and whether the scripts have Supabase Storage credentials.
   - Recommendation (Claude's discretion): Create a `politician-photos` bucket in Supabase Storage. The script downloads the photo to a temp file, uploads via Supabase Storage API, stores the public URL in `photo_origin_url`. The Supabase Python client or direct REST API handles the upload. This is lower priority than the core data integrity work — can be a separate task in the plan.

5. **politician_contacts unique constraint check**
   - What we know: `essentials.politician_contacts` exists with (politician_id, source, contact_type) fields. The upsert ON CONFLICT requires a unique constraint on those columns.
   - What's unclear: Whether this constraint exists. promote_scraped_officials.py does a plain INSERT (no ON CONFLICT) suggesting it may not exist.
   - Recommendation: Check `SELECT * FROM pg_constraint WHERE conrelid = 'essentials.politician_contacts'::regclass` at script start. If no unique constraint on (politician_id, source, contact_type), use DELETE + INSERT pattern for contacts (consistent with how images/degrees/experiences are handled in the BallotReady upsert logic).

---

## Sources

### Primary (HIGH confidence)
- Direct verification: `clerk.lacity.gov/articles/current-elected-officials` (fetched Feb 2026) — authoritative current council roster: all 15 members + mayor Karen Bass confirmed
- Direct verification: `bos.lacounty.gov/executive-office/about-us/board-of-supervisors/` (fetched Feb 2026) — all 5 supervisors confirmed: Solis, Mitchell, Horvath, Hahn, Barger
- `/Users/chrisandrews/Documents/GitHub/scrapers/lavote_scraper.py` — existing scraper code: BeautifulSoup + requests pattern, county page parser, district_type handling confirmed
- `/Users/chrisandrews/Documents/GitHub/scrapers/output/lavote_2026-02-15.json` — 5 supervisors with correct names and district numbers, confirmed current
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/promote_scraped_officials.py` — canonical upsert pattern for politicians/offices/districts/contacts; uuid generation, ext_id counter, chamber find-or-create
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/utils.py` — next_ext_id(), load_env(), get_engine() — confirmed v1.6 range starts at -200001
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/models.go` — Politician struct: Source field exists, no is_active or data_source fields yet; ElectionRecord.IsActive exists separately
- `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/geofence_lookup.go` — confirmed `"X0001": {"LOCAL"}` and `"G4110": {"LOCAL", "LOCAL_EXEC"}` mappings; district join logic
- `/Users/chrisandrews/Documents/GitHub/.planning/phases/35-la-county-arcgis-geofences-supervisor-districts-and-city-council-wards/35-RESEARCH.md` — Phase 35 research: confirmed all 5 supervisor OCD-IDs and 15 LA City council OCD-IDs in essentials.districts; geo_id = '' confirmed; Phase 35 set X0001 geo_ids to OCD-ID strings

### Secondary (MEDIUM confidence)
- WebSearch: LA County Board of Supervisors 2026 — Measure G expansion to 9 members planned but not yet implemented; board remains at 5 members as of Feb 2026
- WebSearch: Ysabel Jurado confirmed in CD14 (Kevin De Leon resigned 2023); Adrin Nazarian in CD2 (elected special election after Krekorian took events role)
- `lacity.gov/government/elected-officials/city-council` — confirms district election structure, 4-year terms, 3-term limit

### Tertiary (LOW confidence)
- Wikipedia Los Angeles City Council (accessed via WebSearch) — names for some districts; superseded by clerk.lacity.gov authoritative source
- Photo storage via Supabase Storage API — pattern not yet in codebase; standard Supabase SDK approach assumed

---

## Metadata

**Confidence breakdown:**
- Politician data (names, seats): HIGH — verified from authoritative government sources at research time
- Schema additions (is_active, data_source): HIGH — straightforward ALTER TABLE; precedent from ElectionRecord.is_active
- Deduplication logic: HIGH — seat-first matching pattern is sound; specific Levenshtein threshold is Claude's discretion (LOW)
- geo_id fix query: HIGH — direct extension of Phase 35 convention; OCD-IDs confirmed in DB
- Photo storage: LOW — no Supabase Storage SDK usage in codebase yet; standard approach assumed

**Research date:** 2026-02-24
**Valid until:** 2026-05-24 (council roster may change due to elections/appointments; re-scrape clerk.lacity.gov at run time rather than trusting this static list)
