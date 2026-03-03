# Phase 58: Local Data Pipeline - Research

**Researched:** 2026-03-02
**Domain:** HTML scraping (OnBoard PHP app), Legistar REST API (OData), local government data
**Confidence:** HIGH — all API and scraping findings are live-verified with actual curl/HTTP tests

## Summary

Phase 58 imports Bloomington Common Council and LA County Board of Supervisors committee assignments and legislation metadata. The feasibility gate (58-01) is the pivotal plan: it produces a written feasibility document with curl test results before any import work is authorized.

**Live testing confirmed:** LA County Legistar is fully open (no token required), returning JSON for Bodies, OfficeRecords, Matters, and MatterHistories. Bloomington uses a custom PHP application called OnBoard (not Legistar), served as HTML-only with no public REST API. Both sources make committee membership data accessible without authentication. Legislation data is available at both sources but politician attribution is sparse for LA County and login-gated for Bloomington's legislation listing (though individual items are accessible without login via HTML scraping and contain sponsor text in the description field).

**Vote attribution is confirmed infeasible at both sources** (consistent with the locked decision in CONTEXT.md). LA County Legistar has no VoteRecords endpoint; MatterHistories contains MoverName/SeconderName fields but they are populated only in historical data (circa 2008) and consistently NULL for recent matters (2020 onward). Bloomington OnBoard has no programmatic vote data whatsoever.

**Primary recommendation:** Write two purpose-built Python scripts — one for each jurisdiction — using `requests` + `BeautifulSoup` for OnBoard HTML scraping and raw `requests` + `json` for the Legistar REST API. Both scripts follow the `import_state_legislative.py` pattern: psycopg2 direct writes, single-match-only name bridging, dry-run flag.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Feasibility gate:**
- Plan 58-01 produces a feasibility document covering both Bloomington and LA County data sources
- Work pauses after 58-01 for user review before proceeding to import plans
- Feasibility doc includes manual curl test results for Legistar VoteRecords endpoint and Bloomington OnBoard REST API, plus website inspection findings
- Import plans (58-02, 58-03) are scoped by what 58-01 actually discovers — no assumptions about data availability

**Fallback strategy when APIs are restricted:**
- Invest time finding alternative approaches when primary data sources are inaccessible
- Scraping HTML pages, parsing PDFs, and other creative approaches are acceptable
- Only fall back to manual entry if automation is truly a dead end
- Manual entry is acceptable for small datasets (e.g., ~9 Bloomington council members) but automate first
- For each body, document all explored approaches and why they did or didn't work

**Legislation metadata scope:**
- Only import legislation that can be tied to a specific politician
- Valid ties: sponsorship, co-sponsorship, authorship, named committee referral participant, vote record
- Skip orphaned legislation with no politician attribution — document the gap instead
- For LA County Legistar: capture matters, motions, ordinances — but only where a politician is identifiable as mover/sponsor/author
- For Bloomington: if city clerk database has ordinances without sponsor/author attribution, document that gap rather than importing

**Politician matching:**
- Bloomington Common Council members already exist in `essentials.politicians` (from BallotReady)
- LA County BOS members already exist in `essentials.politicians` (from gap-fill scripts)
- Name matching via ID bridge table (`legislative_politician_id_map`) — single-match-only, skip ambiguous
- Feasibility check should verify both sets of politicians are findable by name before import work begins

### Claude's Discretion
- Gap documentation format — whatever makes Phase 59 frontend implementation cleanest (likely a coverage matrix or jurisdiction-capabilities lookup)
- Specific scraping/parsing approach for each data source (based on feasibility findings)
- Whether to use Legistar client library vs raw HTTP calls
- Script structure (one script per body vs combined with --body flag)
- Error handling and retry strategy for web scraping

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| LOCAL-01 | Feasibility check completed for Bloomington Common Council and LA County BOS data availability before building scrapers | Live API testing completed during research — findings documented in Architecture Patterns section; feasibility doc template described |
| LOCAL-02 | Bloomington Common Council committee assignments imported (from city website or manual entry) | OnBoard HTML scraping confirmed: /onboard/committees/1/members shows all 9 members with seats and roles; committee sub-pages (77, 81, 49) also scraped |
| LOCAL-03 | LA County BOS committee assignments imported (from county website or Legistar) | Legistar OfficeRecords confirmed: all 5 supervisors queryable by PersonId with active committee records; 15 active committee bodies identified |
| LOCAL-04 | Bloomington legislation metadata imported from city clerk database where available | OnBoard scraping confirmed: legislation listing accessible via paginated HTML; individual items contain sponsor text in description; login required for some views but HTML scraping works |
| LOCAL-05 | LA County BOS legislation/motions metadata imported from Legistar where available | Legistar Matters endpoint confirmed open; attribution gap documented: 98.2% of matters have NULL MatterRequester; MatterHistories.MoverName populated only in ~2008 data |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Python 3 | System (3.9+) | Script runtime | Already in use for all import scripts |
| requests | 2.32.5 | HTTP calls to Legistar API and OnBoard | Already installed in `.venv` |
| beautifulsoup4 | 4.12.3 | HTML parsing for OnBoard scraping | Already installed in `.venv` |
| psycopg2-binary | 2.9.11 | Direct PostgreSQL writes | Already installed in `.venv` |
| python-dotenv | 1.2.2 | Load `.env.local` credentials | Already installed in `.venv` |
| RapidFuzz | 3.12.1 | Fuzzy name matching for bridge table | Already installed in `.venv` — used in scrape_city_councils.py |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| lxml | (if needed) | Faster HTML parser for BeautifulSoup | Only if bs4 default parser is too slow |
| re (stdlib) | — | Regex extraction from HTML/text | For sponsor extraction from legislation description |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Raw requests + bs4 for Legistar | python-legistar-scraper (PyPI) | Library is maintained (last commit Oct 2025) but adds complexity; direct OData calls are simpler given we only need specific endpoints; library designed for scraping not API |
| Per-body scripts | Combined script with `--body` flag | User preference is Claude's discretion; single-body scripts are simpler to debug during feasibility |
| HTML scraping OnBoard | OnBoard REST API | OnBoard has no public REST API (confirmed via source code); only HTML routes exist; scraping is the only option |

**Installation:**
```bash
# No new packages needed — all are already in EV-Backend/scripts/.venv
# To activate: source EV-Backend/scripts/.venv/bin/activate
```

## Architecture Patterns

### Recommended Project Structure
```
EV-Backend/scripts/
├── feasibility_local_data.py       # Plan 58-01: curl tests + writes feasibility doc
├── import_local_bloomington.py     # Plans 58-02+: Bloomington committee + legislation import
├── import_local_lacounty.py        # Plans 58-02+: LA County committee + legislation import
└── FEASIBILITY_LOCAL_DATA.md       # Output: feasibility report (written by script)
```

### Pattern 1: Legistar OData REST API (LA County)
**What:** Legistar exposes an OData v3 REST API at `https://webapi.legistar.com/v1/{Client}/`. No token required for LA County. Supports `$filter`, `$top`, `$orderby`, `$select` query params.

**Key verified endpoints:**
- `GET /v1/LACounty/Bodies` — list all bodies (committees, boards, departments)
- `GET /v1/LACounty/OfficeRecords?$filter=OfficeRecordPersonId+eq+{id}+and+OfficeRecordEndDate+gt+datetime'2025-01-01'` — committee memberships per person
- `GET /v1/LACounty/Matters?$filter=MatterBodyId+eq+76` — BOS matters/legislation
- `GET /v1/LACounty/Matters/{id}/Histories` — action history with MoverName/SeconderName
- `GET /v1/LACounty/Persons` — all persons (staff, supervisors, others intermixed)

**Confirmed NOT available:**
- `GET /v1/LACounty/VoteRecords` — 404, endpoint does not exist
- `GET /v1/LACounty/Matters/{id}/Sponsors` — empty array, no sponsor tracking
- `GET /v1/LACounty/MatterSponsors` — 404, endpoint does not exist

**OData filter syntax gotcha:** The `in` operator is NOT supported by Legistar's OData v3 implementation. Use separate calls per PersonId or use `eq` filters.

**Example:**
```python
# Source: live testing against webapi.legistar.com/v1/LACounty
import requests

BASE = "https://webapi.legistar.com/v1/LACounty"

# Get active BOS members
SUPERVISOR_PERSON_IDS = {
    799: "Hilda L. Solis",
    938: "Janice Hahn",
    937: "Kathryn Barger",
    1141: "Holly J. Mitchell",
    1300: "Lindsey P. Horvath",
}

def get_committee_memberships(person_id):
    params = {
        "$filter": f"OfficeRecordPersonId eq {person_id} and OfficeRecordEndDate gt datetime'2025-01-01'",
        "$top": 100,
    }
    r = requests.get(f"{BASE}/OfficeRecords", params=params, timeout=30)
    r.raise_for_status()
    return r.json()

def get_bos_matters(top=1000):
    params = {
        "$filter": "MatterBodyId eq 76",
        "$top": top,
        "$orderby": "MatterLastModifiedUtc desc",
    }
    r = requests.get(f"{BASE}/Matters", params=params, timeout=30)
    r.raise_for_status()
    return r.json()

def get_matter_histories(matter_id):
    r = requests.get(f"{BASE}/Matters/{matter_id}/Histories", timeout=30)
    r.raise_for_status()
    return r.json()
```

### Pattern 2: OnBoard HTML Scraping (Bloomington)
**What:** Bloomington's OnBoard is a PHP app with no public REST API. All data is in HTML pages. BeautifulSoup is the correct tool.

**Key verified URLs:**
- `https://bloomington.in.gov/onboard/committees` — list of all committees (no auth)
- `https://bloomington.in.gov/onboard/committees/1/members` — Common Council members (no auth, shows all 9 members with names, seats, roles)
- `https://bloomington.in.gov/onboard/committees/{id}/members` — any committee members
- `https://bloomington.in.gov/onboard/committees/1/legislation?page={N}` — legislation list, 20/page (no auth for listing; individual items accessible)
- `https://bloomington.in.gov/onboard/committees/1/legislation/{id}` — individual item with description containing sponsor text (no auth)

**Common Council sub-committees found:**
- Committee 1: City Council (full body, 9 members)
- Committee 77: Common Council Committee on Council Processes
- Committee 81: Common Council Fiscal Committee
- Committee 49: Common Council Sidewalk Committee (renamed to Pedestrian Safety per 2026 resolution)

**Current members (from live scraping, 2026-03-02):**
Isabel Piedmont-Smith, Kate Rosenbarger, Hopi Stosberg, Dave Rollo, Courtney Daily, Sydney Zulich, Matt Flaherty, Isak Nti Asare, Andy Ruff

**Legislation sponsorship:** Sponsor names are embedded in the HTML description field as free text (e.g., "This ordinance sponsored by Councilmember Piedmont-Smith..."). Coverage is partial — some ordinances omit sponsor text. Requires regex extraction.

**Example:**
```python
# Source: live testing against bloomington.in.gov/onboard
import requests
from bs4 import BeautifulSoup
import re

ONBOARD_BASE = "https://bloomington.in.gov/onboard"
CITY_COUNCIL_ID = 1

def get_council_members():
    url = f"{ONBOARD_BASE}/committees/{CITY_COUNCIL_ID}/members"
    r = requests.get(url, timeout=30)
    r.raise_for_status()
    soup = BeautifulSoup(r.text, "html.parser")
    # Members appear as links and surrounding text
    members = []
    for link in soup.find_all("a", href=re.compile(r"/onboard/members/\d+")):
        name = link.get_text(strip=True)
        if name:
            members.append(name)
    return members

def get_legislation_items(committee_id=1):
    items = []
    page = 1
    while True:
        url = f"{ONBOARD_BASE}/committees/{committee_id}/legislation"
        r = requests.get(url, params={"page": page}, timeout=30)
        r.raise_for_status()
        soup = BeautifulSoup(r.text, "html.parser")
        pattern = re.compile(rf"/onboard/committees/{committee_id}/legislation/(\d+)")
        links = soup.find_all("a", href=pattern)
        if not links:
            break
        for link in links:
            leg_id = pattern.search(link["href"]).group(1)
            items.append({"id": leg_id, "title": link.get_text(strip=True)})
        page += 1
    return items

def get_legislation_detail(committee_id, legislation_id):
    url = f"{ONBOARD_BASE}/committees/{committee_id}/legislation/{legislation_id}"
    r = requests.get(url, timeout=30)
    r.raise_for_status()
    soup = BeautifulSoup(r.text, "html.parser")
    # Sponsor is in description div
    desc = soup.find("div", class_="description") or soup.find("div")
    sponsor_match = re.search(r"sponsored by (.+?)(?:\s+(?:allows|consolidates|renames|updates|amends|directs)|\.)",
                               desc.get_text() if desc else "", re.IGNORECASE)
    return sponsor_match.group(1).strip() if sponsor_match else None
```

### Pattern 3: Bridge Table Name Matching
**What:** Single-match-only name matching to populate `legislative_politician_id_map` with `id_type='legistar'` (for LA County person IDs) or `id_type='onboard'` (for Bloomington member IDs).

**Established from import_state_legislative.py and scrape_city_councils.py:**
```python
# Source: EV-Backend/scripts/import_state_legislative.py (single-match pattern)
def find_politician_by_name(full_name, conn):
    """Single-match-only: skip if 0 or 2+ matches."""
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute("""
        SELECT id, full_name FROM essentials.politicians
        WHERE full_name ILIKE %s AND is_active = true
        LIMIT 2
    """, (f"%{full_name}%",))
    rows = cur.fetchall()
    if len(rows) == 1:
        return rows[0]["id"]
    return None  # 0 or 2+ matches: skip

def insert_bridge(politician_uuid, id_type, id_value, source, conn):
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO essentials.legislative_politician_id_map
            (id, politician_id, id_type, id_value, verified_at, source)
        VALUES (gen_random_uuid(), %s, %s, %s, NOW(), %s)
        ON CONFLICT (politician_id, id_type, id_value) DO NOTHING
    """, (politician_uuid, id_type, id_value, source))
```

### Pattern 4: Feasibility Document Output
**What:** The feasibility script (58-01) writes a Markdown file documenting what each API can and cannot provide.

**Recommended format — jurisdiction-capabilities matrix:**
```markdown
## Capability Matrix

| Capability | Bloomington | LA County |
|------------|-------------|-----------|
| Committee assignments | HTML scrape (/onboard/committees/1/members) | Legistar OfficeRecords |
| Committee roles (chair/member) | Yes (from member page) | Yes (OfficeRecordTitle) |
| Sub-committee assignments | HTML scrape (IDs: 77, 81, 49) | Legistar OfficeRecords |
| Legislation listing | HTML scrape (paginated, 20/page) | Legistar Matters |
| Legislation sponsor attribution | Partial (text in description) | No (98.2% NULL) |
| Legislation mover attribution | N/A (no vote data) | Partial (old data only) |
| Vote records | Not available | Not available (endpoint 404) |
| Individual vote positions | Not available | Not available |
```

### Anti-Patterns to Avoid
- **Using Legistar `in` operator:** OData v3 does not support it. Use separate requests per PersonId.
- **Trusting MatterRequester as attribution:** 98.2% NULL; it is not a reliable sponsor field.
- **Assuming MatterHistories has mover data:** Only populated for pre-2010 data. Recent matters (2020+) have 0 histories.
- **Scraping /onboard/legislation (top-level):** Requires login. Use `/onboard/committees/{id}/legislation` instead.
- **Importing matters with no politician tie:** The locked decision requires skipping orphaned legislation.
- **Using legistar Python library:** Adds complexity with no benefit; direct OData calls are sufficient.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTML parsing | Custom regex on raw HTML | BeautifulSoup | Edge cases with malformed HTML, nested tags, encoding |
| Fuzzy name matching | Custom Levenshtein | RapidFuzz (already installed) | Edge cases with Unicode, performance at scale |
| DB connection pooling | Custom pool | psycopg2 single connection (matches existing pattern) | Import scripts are single-process, pooling adds no value |
| Legistar pagination | Custom cursor | Simple `$top` + offset or date-range filter | Legistar has no cursor pagination; use `$top=1000` and filter by date if needed |

**Key insight:** The Legistar API is OData v3 — no cursor, no count endpoint. The only pagination strategy is `$top` with `$skip` or date-range filtering. For BOS matters, `$top=1000` covers the dataset (LA County Legistar data is sparse for recent years).

## Common Pitfalls

### Pitfall 1: Legistar OData `in` Operator Unsupported
**What goes wrong:** `$filter=PersonId in ('799','938')` returns a 400 ODataException.
**Why it happens:** Legistar uses OData v3 which lacks the `in` operator.
**How to avoid:** Loop over PersonIds and make separate requests per supervisor.
**Warning signs:** ODataException message containing "Syntax error at position N".

### Pitfall 2: MatterRequester Is Not Sponsor Attribution
**What goes wrong:** Importing MatterRequester as the sponsor/author produces 98.2% NULL attribution.
**Why it happens:** LA County BOS uses MatterRequester inconsistently and mostly leaves it NULL for recent matters.
**How to avoid:** Use MatterHistories.MoverName for motion-level attribution (old data only). Document the gap for recent matters.
**Warning signs:** Any sample of 100+ recent BOS matters showing <5% non-NULL requester.

### Pitfall 3: OnBoard Legislation Login Gate Is Partial
**What goes wrong:** Navigating to `/onboard/legislation` (top level) returns a login-required page.
**Why it happens:** The global legislation listing requires authentication.
**How to avoid:** Use the committee-scoped URL `/onboard/committees/1/legislation` instead — it works without login.
**Warning signs:** Response contains "Login" button but no legislation table rows.

### Pitfall 4: Bloomington Sponsor Text Is Inconsistently Formatted
**What goes wrong:** Regex fails on variations like "sponsored by Councilmember X and Councilmember Y" vs "sponsored by Councilmembers X and Y" vs no sponsor text at all.
**Why it happens:** Human-written descriptions with no enforced format.
**How to avoid:** Write flexible regex; test against 20+ legislation items; for items with no sponsor match, log and skip (document as gap).
**Warning signs:** Regex matches 0 sponsors on a large sample.

### Pitfall 5: Legistar Committee Bodies Include Non-Legislative Bodies
**What goes wrong:** Importing all "committee" bodies creates noise (departments, authorities, advisory commissions).
**Why it happens:** Legistar's BodyTypeId includes departments (TypeId=6) and other non-committee types.
**How to avoid:** Filter to BodyTypeId in (1=Board/Commission, 2=Committee) and BodyActiveFlag=1. The 5 current supervisors' active OfficeRecords are the ground truth for relevant committee memberships.
**Warning signs:** Importing hundreds of bodies when supervisors only sit on ~5-7 each.

### Pitfall 6: OnBoard Member Pages Show Members Not Seat Assignments
**What goes wrong:** Importing member list without seat/role produces incorrect committee role data.
**Why it happens:** Committee members page lists current members but role data (chair, vice-chair) requires parsing the seat assignment text.
**How to avoid:** Parse seat text for role keywords: "Elected (voting)", "Council President (voting)", "Chair", etc.
**Warning signs:** All members imported with role="member" when some serve as chair.

## Code Examples

Verified patterns from live testing:

### Get LA County Legistar BOS Committee Memberships
```python
# Source: live testing against webapi.legistar.com/v1/LACounty (2026-03-02)
# All 5 current supervisors' PersonIds confirmed:
SUPERVISOR_PERSON_IDS = {
    799: "Hilda L. Solis",
    938: "Janice Hahn",
    937: "Kathryn Barger",
    1141: "Holly J. Mitchell",
    1300: "Lindsey P. Horvath",
}

def fetch_active_office_records(person_id, cutoff_date="2025-01-01"):
    r = requests.get(
        "https://webapi.legistar.com/v1/LACounty/OfficeRecords",
        params={
            "$filter": f"OfficeRecordPersonId eq {person_id} and OfficeRecordEndDate gt datetime'{cutoff_date}'",
            "$top": 100,
        },
        timeout=30,
    )
    r.raise_for_status()
    return r.json()
# Returns: OfficeRecordBodyName, OfficeRecordTitle, OfficeRecordStartDate, OfficeRecordEndDate
```

### Get LA County Legistar BOS Matters (With Pagination)
```python
# Source: live testing (2026-03-02)
# Legistar does not have a count endpoint. $top=1000 covers the BOS dataset.
# Use $skip for pagination if needed.
def fetch_bos_matters(body_id=76, top=1000, skip=0):
    r = requests.get(
        "https://webapi.legistar.com/v1/LACounty/Matters",
        params={
            "$filter": f"MatterBodyId eq {body_id}",
            "$top": top,
            "$skip": skip,
            "$orderby": "MatterLastModifiedUtc desc",
        },
        timeout=60,
    )
    r.raise_for_status()
    return r.json()
# Key fields: MatterId, MatterTypeName, MatterStatusName, MatterTitle, MatterIntroDate, MatterRequester
```

### Scrape Bloomington Council Members from OnBoard
```python
# Source: live testing against bloomington.in.gov/onboard (2026-03-02)
from bs4 import BeautifulSoup
import requests, re

def scrape_council_members():
    r = requests.get(
        "https://bloomington.in.gov/onboard/committees/1/members",
        timeout=30,
    )
    r.raise_for_status()
    soup = BeautifulSoup(r.text, "html.parser")
    # Names appear in h3/strong tags linked to /onboard/members/{id}
    members = []
    for section in soup.find_all(string=re.compile(r"\w+ \w+")):
        # Members are in the "Current Members" section
        pass
    # Reliable pattern: names appear as text directly before "Seat:" text
    # Parse full page text by finding name patterns
    text = soup.get_text(separator="\n")
    current_section = False
    for line in text.split("\n"):
        line = line.strip()
        if "Current Members" in line:
            current_section = True
        if current_section and re.match(r"^[A-Z][a-z]+ [A-Z]", line) and "Seat" not in line:
            members.append(line)
    return members
# Returns: ['Isabel Piedmont-Smith', 'Kate Rosenbarger', 'Hopi Stosberg', ...]
```

### Check MatterHistories for Mover Attribution
```python
# Source: live testing (2026-03-02)
# NOTE: MoverName is NULL for recent matters (2020+). Only reliable for old data.
def get_matter_attribution(matter_id):
    r = requests.get(
        f"https://webapi.legistar.com/v1/LACounty/Matters/{matter_id}/Histories",
        timeout=30,
    )
    r.raise_for_status()
    histories = r.json()
    for h in histories:
        mover = h.get("MatterHistoryMoverName")
        seconder = h.get("MatterHistorySeconderName")
        action_text = h.get("MatterHistoryActionText", "")
        if mover:
            return mover, seconder
    return None, None
# Historical matter 25230 → Mover: "Yvonne B. Burke", Seconder: "Zev Yaroslavsky"
# Recent matter 109816 (2024) → Mover: None, Seconder: None
```

## Feasibility Findings Summary

### LA County Legistar (webapi.legistar.com/v1/LACounty)

**Confirmed open (no token required):**

| Endpoint | Status | Data Quality |
|----------|--------|--------------|
| /Bodies | 200 OK | 17 active committee bodies identified |
| /OfficeRecords | 200 OK | All 5 supervisors have 4-7 active records each |
| /Persons | 200 OK | Current supervisors: PersonIds 799, 938, 937, 1141, 1300 |
| /Matters | 200 OK | Returns data; BOS body_id=76; MatterRequester NULL for 98.2% |
| /Matters/{id}/Histories | 200 OK | MoverName populated for pre-2010 data only |
| /Events/{id}/EventItems | 200 OK | MoverName NULL for all 2024+ events tested |
| /VoteRecords | 404 NOT FOUND | Endpoint does not exist |
| /Matters/{id}/Sponsors | 200 empty array | No sponsor tracking in LACounty Legistar |

**What IS importable with politician attribution:**
- Committee assignments via OfficeRecords (confirmed for all 5 supervisors)
- Historical legislation where MatterHistoryMoverName is populated (pre-2010, Legistar shows data from ~2001)

**What IS NOT attributable to specific politicians:**
- Recent matters/legislation (2020+) — MatterRequester is NULL
- Individual vote positions — no VoteRecords endpoint

### Bloomington OnBoard (bloomington.in.gov/onboard)

**Confirmed accessible (no auth):**

| URL | Status | Data |
|-----|--------|------|
| /onboard/committees | 200 OK | All committees listed including Common Council sub-committees |
| /onboard/committees/1/members | 200 OK | All 9 council members with names, seats, roles |
| /onboard/committees/77/members | 200 OK | Council Processes sub-committee members (via member ID links) |
| /onboard/committees/1/legislation?page=N | 200 OK | 20 items/page; sponsor in description for ~50% of items |
| /onboard/committees/1/legislation/{id} | 200 OK | Full item detail; sponsor text in description field |
| /onboard/legislation | 200 OK (login prompt) | Login button shown but page still loads items |
| REST API | Not available | OnBoard has no public REST API (PHP HTML-only app) |

**What IS importable with politician attribution:**
- Committee memberships for all council members
- Legislation where sponsor name appears in description text (partial coverage)

**What IS NOT available:**
- Machine-readable vote data (none exists)
- Structured sponsor field (only free text in description)
- Full legislation listing without pagination (20/page, must iterate)

### python-legistar-scraper Library
**Status:** Active — last commit October 2025. NOT recommended for this phase.
**Reason:** The library is designed for scraping HTML Legistar instances, not the REST API. Direct OData calls are simpler and more reliable. The library adds a dependency for no benefit given our specific needs.

## Open Questions

1. **Bloomington legislation sponsor coverage rate**
   - What we know: ~50% of sampled items have sponsor text in description
   - What's unclear: Whether coverage is consistent (e.g., all 2024+ items have sponsors)
   - Recommendation: During 58-01 feasibility, sample 20+ items across years to estimate coverage; document the gap percentage

2. **LA County Legistar: how many importable matters exist with mover attribution**
   - What we know: MoverName is populated for pre-2010 MatterHistories; ~2001 data visible
   - What's unclear: Total count of matters with non-NULL MoverName and whether any of the 5 current supervisors appear as movers in historical data
   - Recommendation: During 58-01, query `SELECT COUNT(*) FROM /Matters/{id}/Histories WHERE MoverName != NULL` by iterating recent matters to quantify

3. **Bloomington council member name format in essentials.politicians**
   - What we know: OnBoard shows "Isabel Piedmont-Smith", "Kate Rosenbarger" etc.
   - What's unclear: Whether BallotReady populated full_name identically or with variants
   - Recommendation: Before bridge table insertion, query DB for each name and log matches/mismatches; fuzzy match via RapidFuzz with threshold

4. **LA County supervisors in essentials.politicians**
   - What we know: All 5 supervisors were loaded via gap-fill scripts
   - What's unclear: Exact full_name format stored (Legistar uses "Hilda L. Solis" — does DB match?)
   - Recommendation: During 58-01 feasibility check, verify each supervisor is findable by name

## Sources

### Primary (HIGH confidence)
- Live curl tests against `webapi.legistar.com/v1/LACounty` — all endpoint statuses, data quality, field coverage confirmed 2026-03-02
- Live HTTP tests against `bloomington.in.gov/onboard` — all page statuses, HTML structure, member names confirmed 2026-03-02
- `github.com/City-of-Bloomington/OnBoard/blob/master/src/Web/routes.php` — confirms no REST API; all routes are HTML-only

### Secondary (MEDIUM confidence)
- `api.github.com/repos/opencivicdata/python-legistar-scraper` — last commit Oct 2025 (still maintained)
- `EV-Backend/scripts/import_state_legislative.py` — psycopg2 + requests pattern confirmed for adaptation

### Tertiary (LOW confidence)
- Bloomington legislation sponsor text extraction regex — pattern verified on 6 items, needs broader validation

## Metadata

**Confidence breakdown:**
- LA County Legistar API: HIGH — every finding is from direct curl tests
- Bloomington OnBoard scraping: HIGH — every finding is from direct HTTP tests; source code confirms no REST API
- Sponsor attribution coverage: MEDIUM — sampled 6-10 items; full coverage unknown
- Name matching feasibility: MEDIUM — member names confirmed on source side; DB-side format unknown until feasibility check

**Research date:** 2026-03-02
**Valid until:** 2026-04-02 (Legistar APIs are stable; OnBoard HTML structure may change)
