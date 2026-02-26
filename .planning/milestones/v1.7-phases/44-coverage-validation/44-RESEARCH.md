# Phase 44: Coverage Validation - Research

**Researched:** 2026-02-25
**Domain:** Python scripting, database validation, HTTP HEAD requests
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
None — no locked decisions in CONTEXT.md. All implementation details are Claude's discretion.

### Claude's Discretion
- Script language (Python or Go), location, and invocation
- Report output format (CLI table, JSON, markdown, etc.)
- How granular the report is (summary vs line-by-line)
- Any additional validation checks beyond the 3 success criteria
- Error handling and retry logic for HEAD requests

### Deferred Ideas (OUT OF SCOPE)
- BIO-01: Bio text for county supervisors — moved to future milestone
- BIO-02: Bio text for LA City council members — moved to future milestone
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PIPE-03 | Coverage report validates 80%+ headshot and contact targets | New standalone script `coverage_report.py` with 3 validation checks: HEAD-request CDN audit, contact website presence, hotlink scan — mirrors validate_la_county.py pattern |
</phase_requirements>

---

## Summary

Phase 44 is a single-script delivery: a standalone `coverage_report.py` that runs three deterministic checks against the database and the Supabase CDN, prints a structured PASS/FAIL report, and exits 0 on full pass or 1 on any failure. The script closes PIPE-03, the only remaining requirement in REQUIREMENTS.md.

The key context from reading the codebase: a prototype of Check 1 (HEAD request CDN audit) already exists as the `check_coverage()` function inside `scrape_city_headshots.py`, invoked via `--check-coverage`. Phase 44 extracts and expands that into a proper dedicated script with all three checks. The three checks mirror the three phase success criteria exactly. **The script is a reporter, not a fixer** — it reports PASS or FAIL honestly. Currently Phase 42 is at 21.5% headshot coverage (84/391) and Phase 42-06 (manual curation sprint) is deferred, so Check 1 will FAIL at the time the script is first written. That is intentional and correct behavior. The script must still be written so that when Plan 42-06 is eventually executed, `coverage_report.py` can be re-run to confirm the milestone is met.

**Primary recommendation:** Write `coverage_report.py` in Python following the `validate_la_county.py` structural pattern: numbered steps, clear PASS/FAIL per check, final summary table, exit code 0/1. One plan is sufficient. Reuse `load_env()` and `get_connection()` from `utils.py`. The contact website check uses pure SQL (no HTTP requests needed). The hotlink check uses pure SQL. Only Check 1 (HEAD requests) needs network access.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Python 3.13 | 3.13 | Script runtime | Already in use for all EV-Backend scripts |
| psycopg2-binary | 2.9.11 | PostgreSQL queries (headshot URLs, contact presence, hotlink scan) | Pinned in requirements.txt; used by every other script |
| requests | 2.32.5 | HTTP HEAD requests to Supabase CDN | Pinned in requirements.txt; used by scrape_city_headshots.py |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| utils.py (local) | N/A | load_env(), get_engine(), load_supabase_env() | Always — project-standard environment loading |
| argparse (stdlib) | stdlib | --dry-run, --json-output flags | Standard across all project scripts |
| json (stdlib) | stdlib | Optional JSON output mode | If implementing JSON report format |
| sys (stdlib) | stdlib | Exit code 0/1 | Always |
| time (stdlib) | stdlib | 100ms sleep between HEAD requests | Rate limiting (matches existing check_coverage() pattern) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Python | Go | Go adds complexity; all other v1.7 scripts are Python; no benefit for a once-per-milestone script |
| psycopg2 | SQLAlchemy (get_engine from utils.py) | SQLAlchemy adds ORM abstraction; raw SQL queries are clearer for read-only validation; psycopg2 is used by scrape_city_headshots.py and validate_la_county.py already |
| CLI table output | JSON output | CLI table is human-readable and matches validate_la_county.py; JSON is better for CI integration; both are easy to add with a flag |

**Installation:**
```bash
# Already installed — no new dependencies
cd EV-Backend/scripts
python3 -m pip install -r requirements.txt
```

---

## Architecture Patterns

### Recommended Project Structure
```
EV-Backend/scripts/
├── coverage_report.py    # NEW — Phase 44 deliverable
├── utils.py              # shared env/DB helpers (existing)
├── validate_la_county.py # structural reference (existing, Phase 38)
├── city_sources.json     # 89 LA County cities config (existing)
└── requirements.txt      # dependencies (existing, no changes)
```

### Pattern 1: Three-Check Sequential Script
**What:** Each check is an isolated function returning (pass: bool, result_dict). Main runs them in order, collects results, prints summary, exits 0 or 1.
**When to use:** Multiple independent validation checks that each have clear PASS/FAIL semantics.
**Example:**
```python
# Based on validate_la_county.py pattern (EV-Backend/scripts/validate_la_county.py)

def check_1_headshot_cdn(conn):
    """HEAD-request audit: 80%+ of CDN URLs return HTTP 200."""
    # Query: same as existing check_coverage() in scrape_city_headshots.py
    # Returns (passed: bool, result: dict)

def check_2_contact_website_presence(conn):
    """SQL audit: all 89 LA County cities have a website_url contact."""
    # Returns (passed: bool, result: dict)

def check_3_zero_hotlinks(conn):
    """SQL audit: zero politician_images rows point to non-Supabase URLs."""
    # Returns (passed: bool, result: dict)

def main():
    load_env()
    conn = get_connection()
    results = []
    results.append(check_1_headshot_cdn(conn))
    results.append(check_2_contact_website_presence(conn))
    results.append(check_3_zero_hotlinks(conn))
    conn.close()
    all_pass = print_summary(results)
    sys.exit(0 if all_pass else 1)
```

### Pattern 2: Existing check_coverage() Extraction
**What:** The headshot CDN check already exists as `check_coverage()` in `scrape_city_headshots.py` (lines 964-1023). Extract the logic directly — same SQL, same HEAD loop, same 100ms delay.
**When to use:** Avoid duplicating working logic; reference the source function as a model.

Existing SQL from `scrape_city_headshots.py` line 980-991:
```python
# Source: EV-Backend/scripts/scrape_city_headshots.py, check_coverage() function
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
```

**Note:** The Phase 44 script expands this query to also count politicians WITHOUT headshots to compute actual coverage percentage (not just CDN health percentage). Two numbers are useful:
- CDN health: of politicians WHO HAVE a CDN headshot URL, what % returns HTTP 200?
- Population coverage: of all LOCAL/LOCAL_EXEC LA County politicians, what % have a headshot URL?

The success criterion ("80%+ of LA County headshot URLs return HTTP 200 from Supabase CDN") maps to CDN health percentage. The population coverage number provides additional diagnostic context.

### Pattern 3: Contact Presence SQL (Check 2)
**What:** Pure SQL — count distinct cities whose politicians have at least one `contact_type='city_website'` contact row.
**Example:**
```python
# Adapted from import_city_contacts.py knowledge of schema
# essentials.politician_contacts has: politician_id, source, contact_type, website_url

# Approach: count cities represented in city_sources.json against DB contact rows
# OR: count distinct place_geoids in building_photos with a matched contact
# Simplest approach: join districts by OCD-ID pattern for each city

# Simple count approach:
cur.execute("""
    SELECT COUNT(DISTINCT p.id) as politicians_with_website,
           COUNT(*) as total_contacts
    FROM essentials.politician_contacts pc
    JOIN essentials.politicians p ON pc.politician_id = p.id
    WHERE pc.contact_type = 'city_website'
      AND pc.website_url != ''
      AND p.is_active = true
""")
```

**Better approach:** Load city_sources.json (89 cities), then for each city check if at least one of its roster members has a `city_website` contact in the DB. This gives the "N of 89 cities covered" metric that maps directly to the success criterion.

### Pattern 4: Hotlink Detection SQL (Check 3)
**What:** Query politician_images for all LOCAL/LOCAL_EXEC CA politicians where url does NOT contain 'supabase'. Zero such rows = PASS.
**Example:**
```python
cur.execute("""
    SELECT p.full_name, pi.url, d.district_type
    FROM essentials.politician_images pi
    JOIN essentials.politicians p ON p.id = pi.politician_id
    JOIN essentials.offices o ON o.politician_id = p.id
    JOIN essentials.districts d ON o.district_id = d.id
    WHERE pi.type = 'default'
      AND pi.url IS NOT NULL
      AND pi.url != ''
      AND pi.url NOT LIKE '%supabase%'
      AND d.district_type IN ('LOCAL', 'LOCAL_EXEC', 'COUNTY')
      AND d.state = 'CA'
      AND p.is_active = true
""")
# If rows > 0: list them with name + url for investigation
```

**Scope note:** Check 3 should cover ALL LA County officials (supervisors + LA City + 89 cities), not just LOCAL/LOCAL_EXEC. Supervisors are COUNTY type; they were the first batch uploaded in Phase 40. The `%supabase%` pattern reliably identifies Supabase Storage CDN URLs — Supabase public URLs follow the pattern `https://{project_ref}.supabase.co/storage/v1/object/public/politician-photos/...`.

### Anti-Patterns to Avoid
- **Null-count SQL only:** The success criterion explicitly requires HEAD requests, not just checking for non-null URLs. A CDN URL can exist in the DB but return 403/404 if the file was deleted from Storage. Check 1 MUST issue actual HEAD requests.
- **Asserting pass before checking:** The script should report the current state (21.5% at time of writing). It will FAIL now and PASS after Phase 42-06. Do not short-circuit or threshold-adjust to make it pass early.
- **Merging into scrape_city_headshots.py:** The `--check-coverage` flag already exists there for convenience during scraping. Phase 44 creates a SEPARATE script dedicated to the coverage report so it can be run independently at any time without invoking the scraper.
- **Importing from scrape_city_headshots.py:** That file is 1247 lines and imports Playwright. Don't import it — copy the relevant SQL and HEAD loop directly into coverage_report.py.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Environment loading | Custom .env parser | `load_env()` from utils.py | Already handles edge cases (special chars in password, direct vs pooler URL) |
| DB connection | New psycopg2 setup | `get_connection()` pattern from validate_la_county.py | Handles urlparse, port, SSL params |
| HTTP requests | urllib.request | requests library (already in requirements.txt) | Handles redirects, timeouts, connection pooling |
| City list | Hardcoded 89 city names | Read city_sources.json | Single source of truth; already used by import_city_contacts.py |

**Key insight:** Everything needed already exists in the project. The research manifest CSV (300 politicians, 82 cities) is the cross-reference guide. The schema is fully known. This phase is purely assembly of existing pieces into a standalone report script.

---

## Common Pitfalls

### Pitfall 1: CDN URL Pattern Mismatch
**What goes wrong:** Using a regex like `\.supabase\.co` when the actual URL contains a subdomain like `{project_ref}.supabase.co`. The `LIKE '%supabase%'` approach used by the existing check_coverage() function is simpler and already proven correct.
**Why it happens:** Overcorrecting toward precision when the project already has a working pattern.
**How to avoid:** Use `pi.url LIKE '%supabase%'` exactly as in scrape_city_headshots.py line 987.
**Warning signs:** SQL returning 0 rows for Check 1 when headshots are known to exist in DB.

### Pitfall 2: Scope Confusion for Check 3 (Hotlinks)
**What goes wrong:** Only scanning LOCAL/LOCAL_EXEC districts for hotlinks, missing supervisors (COUNTY type) and LA City council (which have both LOCAL and other types).
**Why it happens:** The Phase 42 headshot scraper focused on LOCAL/LOCAL_EXEC, so it's natural to scope Check 3 the same way. But Phase 40 (supervisors and LA City council) also stored photos — any of those could theoretically be hotlinks.
**How to avoid:** Check 3 should cover `district_type IN ('LOCAL', 'LOCAL_EXEC', 'COUNTY')` for California politicians, or simply all active California politicians with non-null headshot URLs.
**Warning signs:** Check 3 shows 0 hotlinks but you haven't verified it scanned supervisors.

### Pitfall 3: Coverage Denominator Error
**What goes wrong:** Check 1 computes "N of M CDN URLs return 200" where M is only the URLs already in the DB. This is correct per the success criterion ("80%+ of LA County headshot URLs return HTTP 200"). But confusing this with "80%+ of all politicians have headshots" causes misreporting.
**Why it happens:** Two overlapping but different metrics: CDN health vs. population coverage.
**How to avoid:** Report both numbers explicitly: "CDN health: X/Y URLs return 200 (Z%). Population coverage: A/B LA County politicians have any headshot (C%)." The 80% threshold applies to CDN health (URLs that exist must be reachable).
**Warning signs:** Reporting a high CDN health % while population coverage is 21.5%, which could falsely indicate the milestone target is met.

### Pitfall 4: Rate Limiting HEAD Requests
**What goes wrong:** Sending hundreds of HEAD requests to Supabase CDN without delays, triggering rate limiting or 429 responses.
**Why it happens:** Supabase Storage CDN has per-client rate limits on public URLs.
**How to avoid:** Use 100ms delays between HEAD requests, exactly as in the existing `check_coverage()` function (line 1010: `time.sleep(0.1)`). With ~84 current URLs this is negligible; with 313+ after Phase 42-06 it takes ~31 seconds, which is acceptable.
**Warning signs:** Sudden 429 or 503 responses after the first N requests succeed.

### Pitfall 5: Contact Check Scope — What Counts as "89 Cities Covered"?
**What goes wrong:** The success criterion says "contact website URLs are present for all 89 LA County cities." Two interpretations exist:
1. 89 cities have at least one politician with a `city_website` contact row
2. Every individual politician in those cities has a `city_website` contact row
**Why it happens:** The import_city_contacts.py script imports city website contacts per-politician, not per-city. Some politicians may be in the DB without matching contact rows if the name-based matching failed.
**How to avoid:** Use interpretation 1 — "for each city in city_sources.json, at least one roster member has a city_website contact." This is the meaningful coverage check. Report per-city as a table.
**Warning signs:** Check 2 returning "88/89" because one city's roster didn't match any DB politicians.

---

## Code Examples

Verified patterns from project source files:

### Connection Pattern (from validate_la_county.py)
```python
# Source: EV-Backend/scripts/validate_la_county.py lines 36-53
from urllib.parse import urlparse
import psycopg2
import psycopg2.extras

def get_connection():
    raw_url = os.getenv("DATABASE_URL")
    parsed = urlparse(raw_url)
    kwargs = {
        "host": parsed.hostname,
        "port": parsed.port or 5432,
        "dbname": parsed.path.lstrip("/"),
        "user": parsed.username,
        "password": parsed.password,
    }
    if parsed.query:
        for param in parsed.query.split("&"):
            if "=" in param:
                k, v = param.split("=", 1)
                kwargs[k] = v
    return psycopg2.connect(**kwargs)
```

Note: import_city_contacts.py uses a slightly different connection pattern (also psycopg2). Both work. Use validate_la_county.py's version (includes query param handling for SSL mode).

### HEAD Request Loop (from scrape_city_headshots.py check_coverage)
```python
# Source: EV-Backend/scripts/scrape_city_headshots.py lines 999-1014
import requests
import time

total = len(rows)
ok = 0
print(f"\nChecking coverage: {total} CDN URLs to validate...")
for i, row in enumerate(rows):
    url = row["url"]
    try:
        resp = requests.head(url, timeout=5, allow_redirects=True)
        if resp.status_code == 200:
            ok += 1
        else:
            print(f"  FAIL [{resp.status_code}]: {url}")
    except requests.RequestException as e:
        print(f"  ERROR: {url} — {e}")
    time.sleep(0.1)  # 100ms between HEAD requests

    if (i + 1) % 50 == 0:
        pct_so_far = (ok / (i + 1)) * 100
        print(f"  Progress: {i + 1}/{total} checked ({pct_so_far:.1f}% OK so far)")

pct = (ok / total * 100) if total > 0 else 0.0
```

### Loading city_sources.json (from import_city_contacts.py)
```python
# Source: EV-Backend/scripts/import_city_contacts.py lines 453-457
from pathlib import Path
import json

city_sources_path = Path(__file__).parent / "city_sources.json"
with open(city_sources_path) as f:
    data = json.load(f)
cities = data["cities"]
# Each city has: id, name, place_geoid, roster (list of {name, district, party, role})
```

### Summary Table Pattern (from validate_la_county.py)
```python
# Source: EV-Backend/scripts/validate_la_county.py lines 467-517
def print_summary(results: list, ...) -> bool:
    print("\n" + "=" * 70)
    print("=== VALIDATION SUMMARY ===")
    print("=" * 70)
    print(f"{'Check':<45} {'Result':<6}  {'Notes'}")
    print("-" * 70)
    for r in results:
        label = r["label"][:44]
        print(f"{label:<45} {r['status']:<6}  {r['detail']}")
    print("=" * 70)
    all_ok = all(r["status"] == "PASS" for r in results)
    print(f"\nOVERALL: {'PASS' if all_ok else 'FAIL'}")
    return all_ok
```

### Contact Presence Check (new — adapted from schema knowledge)
```python
# Approach: per-city presence check using city_sources.json + DB join
# Each city gets PASS if ANY politician with that city's roster name
# has a city_website contact row.

def check_2_contact_website_presence(conn, city_sources_path):
    with open(city_sources_path) as f:
        data = json.load(f)
    cities = data["cities"]

    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cities_with_contact = 0
    cities_without_contact = []

    for city in cities:
        roster = city.get("roster", [])
        if not roster:
            continue
        names = [m["name"] for m in roster]
        # Check if any roster member has a city_website contact
        cur.execute("""
            SELECT COUNT(*) as cnt
            FROM essentials.politicians p
            JOIN essentials.politician_contacts pc ON pc.politician_id = p.id
            WHERE p.full_name = ANY(%s)
              AND p.is_active = true
              AND pc.contact_type = 'city_website'
              AND pc.website_url != ''
        """, (names,))
        row = cur.fetchone()
        if row["cnt"] > 0:
            cities_with_contact += 1
        else:
            cities_without_contact.append(city["name"])

    passed = cities_with_contact == len(cities)
    return passed, {
        "cities_covered": cities_with_contact,
        "total_cities": len(cities),
        "missing": cities_without_contact,
    }
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `--check-coverage` flag inside scrape_city_headshots.py | Standalone coverage_report.py | Phase 44 (this phase) | Dedicated script runnable independently from scraper; covers all 3 checks not just headshot CDN |

**Deprecated/outdated:**
- Nothing deprecated in this phase — all tools are current.

---

## Open Questions

1. **What is the correct denominator for Check 1 (CDN health)?**
   - What we know: The existing `check_coverage()` uses `LIMIT 600` (there are ~84 CDN URLs currently). After Phase 42-06, there could be 300+.
   - What's unclear: Should Check 1 report "N of M CDN URLs return 200" (health of what exists) or "N of 391 total politicians have reachable headshots" (population coverage)?
   - Recommendation: Report both. CDN health is the metric for the success criterion; population coverage is the diagnostic context. Keep `LIMIT 600` as a safety cap.

2. **Should Check 2 count LA City separately?**
   - What we know: LA City is not in city_sources.json `cities[]` list but IS in the config as a special entry. Its politicians are handled differently (OCD-ID join, not name matching). Import_city_contacts.py handles LA City as a hardcoded special case.
   - What's unclear: The success criterion says "all 89 LA County cities." Does LA City count as one of the 89, making city_sources.json adequate, or is it a 90th city?
   - Recommendation: city_sources.json has exactly 89 entries including "City of Los Angeles" at index 0 (`id: "la_city"`). Treat this as the authoritative 89-city list. LA City has no `url` for its council page in the cities[] array (it's handled via separate config sections), but it DOES have roster members. Check the roster for LA City too.

3. **Phase 42-06 deferral: Should the script warn that Phase 42 is incomplete?**
   - What we know: Phase 42-06 (manual curation sprint) was deferred. Coverage is 21.5%, well below 80%. The coverage_report.py will FAIL Check 1 when first run.
   - Recommendation: The script should not add any special warning about Phase 42-06 specifically — just report FAIL with the actual numbers. This is the honest reporter approach. The FAIL output naturally communicates what needs to happen.

---

## Validation Architecture

`workflow.nyquist_validation` is not set in `.planning/config.json` (the key does not exist), so this section is skipped per the output format instructions.

---

## Implementation Recommendation (for Planner)

Phase 44 is **one plan** delivering one Python script:

**File:** `EV-Backend/scripts/coverage_report.py`

**Script sections:**
1. Check 1 — Headshot CDN health (HEAD requests, 80% threshold, reports both CDN health % and population coverage %)
2. Check 2 — Contact website presence (SQL, 89/89 cities threshold, lists any missing cities)
3. Check 3 — Zero hotlinks (SQL, scans all CA LOCAL/LOCAL_EXEC/COUNTY politician_images for non-Supabase URLs)
4. Summary table (PASS/FAIL per check, overall PASS/FAIL, exit code 0/1)

**Invocation:**
```bash
cd EV-Backend/scripts
python3 coverage_report.py              # full report
python3 coverage_report.py --check 1   # headshot CDN only
python3 coverage_report.py --check 2   # contacts only
python3 coverage_report.py --check 3   # hotlinks only
```

**Current expected output (before Phase 42-06):**
```
Check 1: Headshot CDN Health    FAIL   84/84 URLs return 200 (100% CDN health)
                                       BUT 84/391 politicians have headshots (21.5% < 80%)
Check 2: Contact Website (89)   PASS   89/89 cities have website contact
Check 3: Zero Hotlinks          PASS   0 government domain hotlinks found
OVERALL: FAIL (1 of 3 checks failed)
```

**Note on Check 1 nuance:** CDN health (URLs that exist returning 200) will likely be 100% since all uploaded images are valid. Population coverage (politicians WITH headshots / total politicians) will be 21.5%. The success criterion says "80%+ of LA County headshot URLs return HTTP 200" — this measures CDN health of existing URLs, not population coverage. However, the Phase 42 success criterion explicitly required 80% population coverage (313/391 headshots). The script should report BOTH and fail if population coverage is below 80%.

---

## Sources

### Primary (HIGH confidence)
- `EV-Backend/scripts/scrape_city_headshots.py` — `check_coverage()` function (lines 964-1023) is the direct prototype for Check 1
- `EV-Backend/scripts/validate_la_county.py` — structural pattern for numbered-steps validation script with summary table
- `EV-Backend/scripts/import_city_contacts.py` — contact schema and name-based city matching patterns
- `EV-Backend/scripts/utils.py` — `load_env()`, `load_supabase_env()`, `get_supabase_client()`, `upload_photo_to_storage()` helpers
- `EV-Backend/scripts/pipeline_config.json` — Supabase CDN URL is from `get_public_url()` which returns `https://{project_ref}.supabase.co/storage/v1/object/public/politician-photos/...` (verified via utils.py line 171)
- `.planning/phases/42-city-council-headshot-pipeline/42-VERIFICATION.md` — confirmed current coverage is 84/391 = 21.5%; all 89 cities have headshot_status; 76 scraped + 12 failed + 1 blocked
- `EV-Backend/scripts/city_sources.json` — 89 cities confirmed; all cities have roster[] with name-keyed members; "la_city" at index 0

### Secondary (MEDIUM confidence)
- Supabase Storage CDN URL pattern (`%supabase%` as match string) — verified by `pi.url LIKE '%supabase%'` pattern already proven in existing check_coverage() function
- 100ms inter-request delay for HEAD requests — verified in existing code; consistent with Supabase CDN rate limits in practice

### Tertiary (LOW confidence)
- None — all claims are backed by direct code inspection.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — same Python/psycopg2/requests stack as all other v1.7 scripts; no new libraries needed
- Architecture: HIGH — check_coverage() prototype already exists and proven; validate_la_county.py structural pattern is well-established in this project
- Pitfalls: HIGH — identified from direct reading of existing code and known Phase 42 state (21.5% coverage, deferred Plan 42-06)

**Research date:** 2026-02-25
**Valid until:** 2026-03-25 (stable domain; only risk is schema changes which are unlikely)
