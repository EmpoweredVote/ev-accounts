# Phase 57: State Data Pipeline - Research

**Researched:** 2026-03-02
**Domain:** LegiScan API (state legislation), Indiana IGA REST API, Python + psycopg2 batch import, legislative ID bridging
**Confidence:** HIGH

---

## Summary

Phase 57 imports Indiana and California state legislators' committee assignments, bills, and votes into the existing schema from Phase 54, and matches those legislators to existing `essentials.politicians` records via a `legiscan` bridge in `legislative_politician_id_map`. The phase depends on Phase 56 being complete (which it is), and all five API endpoints for committee/bill/vote data are already wired (from Phase 56).

The primary data source for both states is **LegiScan API** — the same client already in `legiscan_client.go`. The operations `getSessionList` (with `state=IN` or `state=CA`), `getSessionPeople`, `getMasterList`, `getBill`, and `getRollCall` are all reusable from the existing Phase 56 implementation. The only new LegiScan operations needed are `getDatasetList` and `getDataset` for bulk download if the per-bill approach is too slow, but the per-bill `getMasterList + getBill + getRollCall` approach used in Phase 56 is sufficient and should be preferred for budget consistency.

Committee assignment data from LegiScan is limited: `getSessionPeople` returns `committee_id` and `committee_sponsor` fields per legislator, which represent the **committee they chair or primarily sponsor** bills in — not a full membership list. A full committee membership list must be inferred by scraping bill referral history from `getBill` responses (the `committee` and `referrals` fields). Indiana also has its own official REST API (MyIGA at `api.iga.in.gov`) that returns structured committee assignments. However, the MyIGA API requires a token obtained by emailing `apitoken.request@iga.in.gov`, and its coverage of committee assignments may be superior to LegiScan for Indiana. California has no official structured committee assignment API — LegiScan's bill-referral inference is the best available approach.

The import scripts are **Python** (per the phase success criteria spec: "LegiScan Python import scripts"), placed in `EV-Backend/scripts/` alongside the existing `import_shapefiles.py` pattern. These Python scripts write directly to PostgreSQL via `psycopg2` and `DATABASE_URL`, reusing the established pattern from prior shapefile import scripts. The scripts do NOT go through the Go backend.

**Primary recommendation:** Use LegiScan's `getMasterList + getBill + getRollCall` workflow for bills and votes (mirrors Phase 56's Senate import), and `getSessionPeople` for the initial person bridge. For committee assignments, infer from `getBill` referral data (bill's `committee` field) and augment with LegiScan's `committee_id` / `committee_sponsor` per-person field. Indiana's IGA API is a secondary option if the token is obtainable, but plan around LegiScan as primary.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| STATE-01 | Indiana state committee assignments, bills, and votes imported via LegiScan or IGA API (current + previous session) | LegiScan `getSessionList(state=IN)`, `getMasterList`, `getBill` (committee referrals), `getRollCall` are all available and reusable from Phase 56's LegiScan client |
| STATE-02 | California state committee assignments, bills, and votes imported via LegiScan (current + previous session) | Same pattern as STATE-01 with `state=CA`. California has no official state API — LegiScan is the only structured source |
| STATE-03 | State legislators matched to existing politician records via external IDs or name matching with dedup | `getSessionPeople` returns first_name + last_name + district per legislator; match against `essentials.politicians` by name + state; insert `id_type='legiscan'` bridge rows into `legislative_politician_id_map` — exact same pattern as `buildLegiScanSenatorBridge` from Phase 56 |
</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `psycopg2-binary` | 2.9.x | Python-to-PostgreSQL writes | Established project standard (import_shapefiles.py) — no ORM overhead needed for batch inserts |
| `requests` | 2.31+ | LegiScan HTTP calls | Established project standard (import_shapefiles.py) |
| `python-dotenv` | 1.x | Load `DATABASE_URL` from `.env.local` | Keeps secrets out of scripts |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `legiscan_client.go` (existing) | — | Go client already has all needed LegiScan operations | Use from Go if wiring CLI subcommands; but phase spec calls for Python scripts |
| `psycopg2` (binary variant) | 2.9.x | Avoids compiling C extension | Always prefer binary variant on macOS dev machines |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Python psycopg2 | Go CLI subcommand (like Phase 56) | Phase spec explicitly requires Python import scripts; Python is also what `import_shapefiles.py` uses |
| LegiScan getDataset bulk download | Per-bill getMasterList+getBill | Bulk download uses access_key from getDatasetList, returns base64-encoded ZIP; adds complexity; per-bill approach mirrors Phase 56 and uses existing monthly budget counter awareness |
| LegiScan for IN committees | Indiana IGA API (api.iga.in.gov) | IGA API has token requirement (email request); plan around LegiScan as primary, treat IGA as enhancement if token available |

**Installation:**
```bash
cd EV-Backend/scripts
python3 -m venv .venv  # already exists per Glob output
source .venv/bin/activate
pip install psycopg2-binary requests python-dotenv
```

---

## Architecture Patterns

### Recommended Project Structure
```
EV-Backend/scripts/
├── import_state_legislative.py    # Main script for IN + CA import
├── .venv/                         # Already exists
└── (existing shapefile scripts)
```

Single script covering both states with `--state IN|CA` argument is cleanest. Each state runs the same three phases: person bridge, bills import, votes import.

### Pattern 1: LegiScan State Session Discovery
**What:** Find session IDs for IN and CA using `getSessionList`
**When to use:** Before any import — need session_id to call getMasterList and getSessionPeople

```python
# Source: verified from existing legiscan_client.go + Microsoft Learn docs
# State codes: "IN" for Indiana, "CA" for California
def find_state_session_id(api_key, state, year_start):
    """Returns LegiScan session_id for the given state and year."""
    resp = requests.get("https://api.legiscan.com/", params={
        "key": api_key,
        "op": "getSessionList",
        "state": state
    })
    data = resp.json()
    for session in data.get("sessions", []):
        if session["year_start"] == year_start and session["special"] == 0:
            return session["session_id"]
    return None

# Indiana 2026 Regular Session: year_start=2026
# Indiana 2025 Regular Session: year_start=2025
# California 2025-2026 Regular Session: year_start=2025
# California 2023-2024 Regular Session: year_start=2023
```

### Pattern 2: State Legislator Bridge Building
**What:** Match LegiScan people records to `essentials.politicians` by name + district state
**When to use:** First step before bills/votes import — need politician_id to create LegislativeVote rows

```python
# Source: mirrors buildLegiScanSenatorBridge in import_federal_votes.go
def build_state_legislator_bridge(api_key, legiscan_session_id, state_abbr, conn):
    """Matches state legislators from LegiScan to politician records."""
    resp = requests.get("https://api.legiscan.com/", params={
        "key": api_key,
        "op": "getSessionPeople",
        "id": legiscan_session_id
    })
    data = resp.json()
    people = data.get("sessionpeople", {}).get("people", [])

    cur = conn.cursor()
    bridge_map = {}  # people_id -> politician_uuid

    for person in people:
        people_id = person["people_id"]
        first_name = person.get("first_name", "")
        last_name = person.get("last_name", "")
        role = person.get("role", "")   # "Rep" or "Sen"

        # Check if bridge row already exists
        cur.execute("""
            SELECT politician_id FROM essentials.legislative_politician_id_map
            WHERE id_type = 'legiscan' AND id_value = %s
        """, (str(people_id),))
        existing = cur.fetchone()
        if existing:
            bridge_map[people_id] = existing[0]
            continue

        # Match by name + state (single match only — ambiguous = skip)
        cur.execute("""
            SELECT p.id FROM essentials.politicians p
            JOIN essentials.offices o ON o.politician_id = p.id
            JOIN essentials.districts d ON o.district_id = d.id
            WHERE LOWER(p.last_name) = LOWER(%s)
              AND LOWER(p.first_name) = LOWER(%s)
              AND d.state = %s
        """, (last_name, first_name, state_abbr))
        matches = cur.fetchall()

        if len(matches) == 1:
            politician_id = matches[0][0]
            bridge_map[people_id] = politician_id
            cur.execute("""
                INSERT INTO essentials.legislative_politician_id_map
                    (id, politician_id, id_type, id_value, verified_at, source)
                VALUES (gen_random_uuid(), %s, 'legiscan', %s, NOW(), 'legiscan-state-people')
                ON CONFLICT DO NOTHING
            """, (politician_id, str(people_id)))
        # 0 matches: log and skip; 2+ matches: log ambiguous and skip

    conn.commit()
    return bridge_map
```

### Pattern 3: getMasterList is a MAP (critical from Phase 56)
**What:** Parse getMasterList as a dict, not a list; skip key "0" (session metadata)
**When to use:** When fetching all bills for a state session

```python
# Source: from STATE.md key decisions + import_federal_votes.go
# CRITICAL: getMasterList returns {"masterlist": {"0": {metadata}, "1": {bill}, ...}}
resp = requests.get("https://api.legiscan.com/", params={
    "key": api_key,
    "op": "getMasterList",
    "id": legiscan_session_id
})
data = resp.json()
masterlist = data.get("masterlist", {})
bills = [v for k, v in masterlist.items() if k != "0"]
# Now bills is a list of {bill_id, number, title, ...} dicts
```

### Pattern 4: Session Row Upsert (Python equivalent of getOrCreateSession)
**What:** Create or retrieve `legislative_sessions` row for state session
**When to use:** Before any bill/vote inserts — session_id is a foreign key

```python
def get_or_create_state_session(conn, state_name, year_start, year_end, legiscan_session_id):
    cur = conn.cursor()
    external_id = str(legiscan_session_id)
    # Map state to jurisdiction string used by existing API handlers
    # "indiana" maps to GET /politician/{id}/committees?jurisdiction=indiana
    jurisdiction = state_name.lower()  # "indiana" or "california"

    cur.execute("""
        SELECT id FROM essentials.legislative_sessions
        WHERE jurisdiction = %s AND external_id = %s
    """, (jurisdiction, external_id))
    existing = cur.fetchone()
    if existing:
        return existing[0]

    cur.execute("""
        INSERT INTO essentials.legislative_sessions
            (id, jurisdiction, name, external_id, is_current, source)
        VALUES (gen_random_uuid(), %s, %s, %s, %s, 'legiscan')
        RETURNING id
    """, (jurisdiction, f"{year_start} {state_name} Regular Session",
          external_id, True))  # Only current session is_current=True
    session_id = cur.fetchone()[0]
    conn.commit()
    return session_id
```

### Pattern 5: Committee Data from getBill Referrals
**What:** Extract committee assignment data from bill responses
**When to use:** To populate `legislative_committees` and `legislative_committee_memberships`

```python
# Source: agbales/legiscan library docs + Microsoft Learn LegiScan connector docs
# getBill returns: bill["committee"] (current committee) and bill["referrals"] (history)
# Committee object structure: {"committee_id": int, "chamber": str, "chamber_id": int, "name": str}
resp = requests.get("https://api.legiscan.com/", params={
    "key": api_key, "op": "getBill", "id": bill_id
})
bill_data = resp.json().get("bill", {})
committee = bill_data.get("committee", {})  # current committee
referrals = bill_data.get("referrals", [])  # committee history

if committee.get("committee_id"):
    # Upsert committee to legislative_committees
    # Then upsert committee membership from getSessionPeople's committee_id field
```

### Pattern 6: LegiScan Budget Awareness
**What:** Check monthly budget before bulk state import; 30K queries/month total across all uses
**When to use:** State imports will consume significant budget (IN has ~500-1000 bills/session, CA has 2000+)

```python
# Each bill requires 1 getMasterList + N getBill + M getRollCall calls
# CA 2025-2026 estimated: 2000 bills x 2 calls each = 4000 queries per session
# IN 2026: ~500 bills x 2 = 1000 queries per session
# Both sessions (current + previous) for both states: ~10,000-12,000 queries
# Budget check: verify > 15,000 remaining before starting full import

# The monthly counter file is at: ~/.ev-backend/legiscan_counter.json
# Python should read/increment it to stay in sync with Go counter
import json, os
from pathlib import Path

def check_legiscan_budget(threshold=15000):
    counter_path = Path.home() / ".ev-backend" / "legiscan_counter.json"
    if counter_path.exists():
        with open(counter_path) as f:
            data = json.load(f)
        month = data.get("month", "")
        current_month = datetime.now().strftime("%Y-%m")
        if month == current_month:
            used = data.get("queries", 0)
            remaining = 30000 - used
            print(f"LegiScan budget: {used}/30000 used, {remaining} remaining")
            if remaining < threshold:
                print(f"WARNING: budget low — consider running with --state IN only")
            return remaining
    return 30000  # fresh counter or different month
```

### Anti-Patterns to Avoid
- **Parsing getMasterList as a list:** It is a JSON object with string keys ("0", "1", etc.). Key "0" is session metadata — skip it. This is a documented project pitfall from Phase 56.
- **Using `state=` parameter in getMasterList instead of `id=`:** The `state=` shortcut gives the CURRENT session only; use `id=legiscan_session_id` to target specific sessions including previous ones.
- **Assuming LegiScan getBill returns full committee membership lists:** It returns the current/pending committee and referral history only. `committee_id` in `getSessionPeople` person records represents the committee the person primarily sponsors in (chairs). Full membership requires inferring from all bill referrals or using Indiana's IGA API.
- **Writing to `essentials.politicians` from Python scripts:** State data should only populate legislative tables (`legislative_sessions`, `legislative_committees`, `legislative_committee_memberships`, `legislative_bills`, `legislative_bill_cosponsors`, `legislative_votes`, `legislative_politician_id_map`). Never modify politicians records from import scripts.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| LegiScan HTTP client | Custom request wrapper | `requests` library with explicit `params={}` dict | Simple GET params; existing pattern in project |
| Monthly budget counter | Custom file tracking | Reuse `~/.ev-backend/legiscan_counter.json` format; Python script reads the same file Go writes | Stay in sync; don't maintain two counters |
| Name normalization | Custom fuzzy matching | Exact first+last name match, single-match-only guard | Established project decision: no medium-confidence bridges |
| UUID generation | Python `uuid.uuid4()` | PostgreSQL `gen_random_uuid()` in INSERT | Let DB generate consistent UUIDs; simpler Python |
| Bill status normalization | Custom state-specific logic | Direct copy of `normalizeBillStatus` from Go (`import_federal_bills.go`) | Status strings vary by state; LegiScan bills already have a `status` field (1-8 int) + `last_action` text |

**Key insight:** The LegiScan status codes (1=Introduced, 2=Engrossed, 3=Enrolled, 4=Passed, 5=Vetoed, 6=Failed, 7=Override, 8=Chaptered) can be normalized to the same labels used for federal bills.

---

## Common Pitfalls

### Pitfall 1: Committee Data Is Bill-Centric, Not Person-Centric in LegiScan
**What goes wrong:** You expect `getSessionPeople` to return full committee memberships (like congress-legislators YAML). It returns `committee_id` and `committee_sponsor` which are the committee the person primarily chairs/sponsors in — not all their committee assignments.
**Why it happens:** LegiScan's data model centers bills and referrals, not committee rosters.
**How to avoid:** For committee memberships, either (a) infer from `getBill` referral data (all bills sent to a committee with sponsor), (b) use Indiana IGA API if token available, or (c) accept partial committee coverage using only `committee_id` from `getSessionPeople` for the "primary committee" role.
**Warning signs:** Import shows only 1 committee per legislator, never multiple.

### Pitfall 2: getMasterList Parsed as Array
**What goes wrong:** `json.loads(body)["masterlist"]` is a dict with string keys, not a list. If you try to iterate it as a list of bill objects, you get key errors or wrong types.
**Why it happens:** Inherited from Phase 56 — documented in STATE.md.
**How to avoid:** Always `[v for k, v in masterlist.items() if k != "0"]`. Verified in existing Go code.
**Warning signs:** Import immediately crashes with TypeError or StopIteration.

### Pitfall 3: California Session Spans Two Calendar Years
**What goes wrong:** CA regular session is "2025-2026" — year_start=2025, year_end=2026. If you filter by `year_start=2026`, you miss the current active session.
**Why it happens:** California has 2-year legislative sessions; Indiana has annual sessions.
**How to avoid:** Use `year_start` for matching, not `year_end`. Current CA session: year_start=2025. Previous: year_start=2023.
**Warning signs:** getSessionList returns no sessions for CA when filtering by 2026.

### Pitfall 4: LegiScan Budget Exhaustion on California Import
**What goes wrong:** CA has ~2,000+ bills per session. Full import (bills + votes) for current+previous = 8,000+ queries. Combined with ongoing federal data, may exhaust 30K monthly limit.
**Why it happens:** California is one of the largest state legislatures by bill volume.
**How to avoid:** Check budget before starting. Log projected cost. Support `--state IN` only flag. Run CA and IN import in separate runs to track budget impact. Consider `getDataset` bulk download (one call = full session ZIP) as budget optimization for CA.
**Warning signs:** Import exits with "LegiScan monthly budget exhausted" error mid-way through CA.

### Pitfall 5: District State Matching for Legislators
**What goes wrong:** Matching state legislators by `last_name + first_name + state` doesn't work if the `districts.state` column in the database uses different values than LegiScan's state codes (IN, CA).
**Why it happens:** Districts from BallotReady may store state as "Indiana" or "IN" — check actual DB values.
**How to avoid:** Before writing matching SQL, query the DB to confirm state column format: `SELECT DISTINCT state FROM essentials.districts WHERE district_type IN ('STATE_UPPER', 'STATE_LOWER') LIMIT 20`.
**Warning signs:** Zero matches for all legislators despite correct names.

### Pitfall 6: Jurisdiction String Must Match Existing API Handlers
**What goes wrong:** If you store sessions with `jurisdiction='IN'` instead of `'indiana'`, the existing `GET /politician/{id}/committees` handler won't find the data.
**Why it happens:** The Phase 56 API handlers filter by jurisdiction string. The federal data uses `'federal'`.
**How to avoid:** Check handlers.go to confirm what jurisdiction strings are used in WHERE clauses. Use `'indiana'` and `'california'` (lowercase full state name).
**Warning signs:** API returns empty arrays for state legislators even after import succeeds.

### Pitfall 7: Cosponsor Bill Upsert Overwrites Primary Sponsor
**What goes wrong:** In state legislatures, a bill may have multiple sponsors listed. If you upsert with SponsorID set for each sponsor, the last insert wins.
**Why it happens:** LegiScan bills have a `sponsors` array with a `sponsor_order` field — sponsor_order=1 is primary.
**How to avoid:** Set SponsorID only for sponsor_order=1 (primary sponsor). For all others, use the cosponsors table. Mirror `upsertCosponsoredBill` pattern from Phase 56.
**Warning signs:** Bills have random politicians as sponsor_id rather than the primary sponsor.

---

## Code Examples

Verified patterns from official sources and existing codebase:

### LegiScan getSessionList for State
```python
# Source: Microsoft Learn LegiScan connector docs (verified)
import requests

def get_state_sessions(api_key: str, state: str) -> list:
    """Returns list of sessions for given state code (e.g., 'IN', 'CA')."""
    resp = requests.get("https://api.legiscan.com/", params={
        "key": api_key,
        "op": "getSessionList",
        "state": state
    }, timeout=30)
    resp.raise_for_status()
    data = resp.json()
    if data.get("status") != "OK":
        raise RuntimeError(f"LegiScan error: {data}")
    return data.get("sessions", [])

# Find current IN session:
# Next regular Indiana session year_starts: 2026 (current), 2025 (previous)
# Indiana meets annually (odd and even years)

# Find current CA session:
# CA 2025-2026 Regular Session: year_start=2025
# CA 2023-2024 Regular Session: year_start=2023
```

### LegiScan getSessionPeople and Bridge Insert
```python
# Source: import_federal_votes.go (buildLegiScanSenatorBridge) + verified MS docs
def get_session_people(api_key: str, session_id: int) -> list:
    """Returns list of legislators active in the given session."""
    resp = requests.get("https://api.legiscan.com/", params={
        "key": api_key,
        "op": "getSessionPeople",
        "id": session_id
    }, timeout=30)
    resp.raise_for_status()
    data = resp.json()
    # Response: {"status": "OK", "sessionpeople": {"session": {...}, "people": [...]}}
    return data.get("sessionpeople", {}).get("people", [])

# Each person record includes:
# people_id, first_name, last_name, party, role, district,
# committee_id, committee_sponsor, state_id, votesmart_id, ballotpedia
```

### getMasterList Parsing (Critical)
```python
# Source: import_federal_votes.go importSenateVotes (verified working pattern)
def get_master_list(api_key: str, session_id: int) -> list:
    """Returns list of bill stubs for the given session."""
    resp = requests.get("https://api.legiscan.com/", params={
        "key": api_key,
        "op": "getMasterList",
        "id": session_id
    }, timeout=30)
    resp.raise_for_status()
    data = resp.json()
    # CRITICAL: masterlist is a dict with string keys, NOT a list
    # Key "0" is session metadata — skip it
    masterlist = data.get("masterlist", {})
    return [v for k, v in masterlist.items() if k != "0"]
    # Each item: {bill_id, number, title, description, status, last_action, ...}
```

### getRollCall Response Structure
```python
# Source: Microsoft Learn (verified schema) + import_federal_votes.go
# Roll call response: {"status": "OK", "roll_call": {...}}
# roll_call fields: roll_call_id, bill_id, date, desc, yea, nay, nv, absent, total,
#                   passed (0 or 1), chamber ("H" or "S"), chamber_id, votes: [...]
# votes item: {people_id, vote_id, vote_text}
# vote_text values: "Yea", "Nay", "NV", "Absent"

def normalize_vote_cast(vote_text: str) -> str:
    """Normalize LegiScan vote_text to our position values."""
    mapping = {
        "yea": "yea", "aye": "yea",
        "nay": "nay", "no": "nay",
        "nv": "not_voting",
        "absent": "absent",
        "present": "present",
    }
    return mapping.get(vote_text.lower(), "not_voting")
```

### DB Write Pattern (psycopg2 upsert)
```python
# Source: import_shapefiles.py pattern in project (verified)
import psycopg2
import os

conn = psycopg2.connect(os.environ["DATABASE_URL"])
cur = conn.cursor()

# Upsert a bill
cur.execute("""
    INSERT INTO essentials.legislative_bills
        (id, session_id, external_id, jurisdiction, number, title, raw_status,
         status_label, sponsor_id, introduced_at, url, source)
    VALUES (gen_random_uuid(), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 'legiscan')
    ON CONFLICT (external_id, jurisdiction) DO UPDATE SET
        title = EXCLUDED.title,
        raw_status = EXCLUDED.raw_status,
        status_label = EXCLUDED.status_label,
        url = EXCLUDED.url
    RETURNING id
""", (session_id, external_id, jurisdiction, number, title, raw_status,
      status_label, sponsor_id, introduced_at, url))
bill_db_id = cur.fetchone()[0]
conn.commit()
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| One-off import per state | Shared LegiScan workflow (getMasterList + getBill + getRollCall) | Phase 56 established | State import reuses all Phase 56 patterns directly |
| Separate Go CLI per import | Python scripts in EV-Backend/scripts/ | Phase 57 spec | Python for batch scripts aligns with shapefile import precedent |
| Aspirational committee schema | Bill-referral inference for committees | Phase 57 reality | LegiScan doesn't provide full committee membership lists |

**Deprecated/outdated:**
- `getDataset` bulk download: Technically valid but adds base64-ZIP complexity; per-bill approach is cleaner and monitors budget incrementally.

---

## Open Questions

1. **Indiana IGA API token availability**
   - What we know: IGA API exists at `api.iga.in.gov`, requires `x-api-key` header, token obtained by emailing `apitoken.request@iga.in.gov`
   - What's unclear: Whether a token is available for this project, and whether IGA API returns fuller committee membership data than LegiScan
   - Recommendation: Plan primary implementation around LegiScan. If IGA token is available, add it as an enhancement in a separate plan step for richer committee data. Do NOT block the phase on token availability.

2. **districts.state format in the database**
   - What we know: BallotReady-sourced districts use the `state` column, but we haven't verified whether it stores "IN"/"CA" (2-letter) or "Indiana"/"California" (full name)
   - What's unclear: Exact column value to use in name-matching SQL
   - Recommendation: Run verification query at start of matching step: `SELECT DISTINCT state FROM essentials.districts WHERE district_type IN ('STATE_UPPER', 'STATE_LOWER') LIMIT 10`. Adjust matching SQL accordingly.

3. **California session year coverage**
   - What we know: CA uses 2-year sessions; current = 2025-2026 (year_start=2025), previous = 2023-2024 (year_start=2023)
   - What's unclear: Whether "previous session" means 2023-2024 (last completed) or 2024 only
   - Recommendation: Import 2025 (current) and 2023 (previous full session). This matches "current and previous session" as stated in STATE-01/STATE-02.

4. **LegiScan budget allocation for CA**
   - What we know: 30K queries/month total; federal Senate import (Phase 56) may have consumed some; CA has ~2000 bills
   - What's unclear: How many queries remain for March 2026
   - Recommendation: Add a budget check at start of script that reads `~/.ev-backend/legiscan_counter.json` and warns if < 15,000 remaining. Support `--state IN` flag to run Indiana-only first.

5. **Jurisdiction strings for state sessions**
   - What we know: Federal uses `'federal'`; STATE.md says "indiana", "california", "bloomington-in", "la-county-ca" are the five jurisdictions
   - What's unclear: Confirmed only from STATE.md, not inspected in handlers.go WHERE clauses
   - Recommendation: Before writing Python, verify in handlers.go that `GetPoliticianCommittees`, `GetPoliticianBills`, `GetPoliticianVotes` filter by jurisdiction string and what values they expect.

---

## Validation Architecture

> workflow.nyquist_validation is not set in .planning/config.json (no `nyquist_validation` key). Skipping this section.

---

## Sources

### Primary (HIGH confidence)
- Microsoft Learn LegiScan connector docs (https://learn.microsoft.com/en-us/connectors/legiscan/) - Full operation list, all parameter schemas, all response schemas including `SessionPerson` with `committee_id`/`committee_sponsor` fields
- `EV-Backend/internal/essentials/import_federal_votes.go` - getMasterList parsing pattern, senator bridge pattern, vote upsert pattern — all verified working code
- `EV-Backend/internal/essentials/legiscan_client.go` - LegiScanClient, LegiScanRollCall, LegiScanVote, LegiScanPerson types — verified
- `EV-Backend/scripts/import_shapefiles.py` - psycopg2 + requests pattern for Python scripts in project
- `EV-Backend/internal/essentials/models.go` - All target table schemas (LegislativeSession, LegislativeCommittee, LegislativeCommitteeMembership, LegislativeBill, LegislativeBillCosponsor, LegislativeVote, LegislativePoliticianIDMap)
- `.planning/STATE.md` - Key decisions including getMasterList MAP structure, single-match-only bridge, jurisdiction string plan
- LegiScan API User Manual (https://api.legiscan.com/dl/LegiScan_API_User_Manual.pdf) - Confirmed `getSessionList` state parameter; session structure

### Secondary (MEDIUM confidence)
- agbales/legiscan JavaScript library README - bill object structure including `committee`, `pending_committee_id`, `referrals` fields
- Indiana IGA API (api.iga.in.gov) - Confirmed `x-api-key` required; confirmed endpoint format `GET /2026/standing-committees/`; endpoint returns 403 without token; token obtained by emailing apitoken.request@iga.in.gov
- WebSearch results confirming Indiana has 45 standing committees (22 Senate, 23 House) for 2026 session

### Tertiary (LOW confidence)
- California legislature has no official structured committee assignment API (inferred from absence in search results; all sources point to LegiScan as the only option)

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Python + psycopg2 is established project pattern; LegiScan operations confirmed from verified working Go code
- Architecture: HIGH - getMasterList MAP pattern, bridge building pattern, session creation pattern all verified from existing Phase 56 code
- Pitfalls: HIGH - getMasterList parsing is documented project pitfall; committee data limitation confirmed from API schema inspection; CA session year confirmed from LegiScan

**Research date:** 2026-03-02
**Valid until:** 2026-04-02 (LegiScan API is stable; IGA API token availability unknown)

---

## Phase Planning Notes

### Suggested Plan Split

**Plan 57-01: State legislator bridge (STATE-03)**
- `getSessionPeople` for IN and CA sessions (current + previous)
- Build `legislative_politician_id_map` rows with `id_type='legiscan'`
- Validate: `SELECT COUNT(*) FROM essentials.legislative_politician_id_map WHERE legiscan_id IS NOT NULL` (but note: column is `id_value`, filter `id_type='legiscan'`)
- File: `EV-Backend/scripts/import_state_legislative.py` (base structure + bridge)

**Plan 57-02: State bills import (STATE-01, STATE-02 partial)**
- `getMasterList + getBill` for IN and CA (current + previous session)
- Upsert `legislative_sessions`, `legislative_bills`, `legislative_bill_cosponsors`
- Upsert `legislative_committees` and `legislative_committee_memberships` from bill referral data
- File: extends 57-01 script

**Plan 57-03: State votes import (STATE-01, STATE-02 complete)**
- `getRollCall` for IN and CA bills that have votes
- Upsert `legislative_votes` via bridge map
- Validate: `GET /essentials/politician/{id}/votes` returns data for a known IN state legislator
- File: extends 57-01/57-02 script

### Environment Variables Needed
```
LEGISCAN_API_KEY=<existing from Phase 56>
DATABASE_URL=<existing from .env.local>
IGA_API_KEY=<optional, obtain from apitoken.request@iga.in.gov>
```

### File Location
Per project pattern: `EV-Backend/scripts/import_state_legislative.py`

Script invocation:
```bash
cd EV-Backend/scripts && source .venv/bin/activate
python import_state_legislative.py --state IN --sessions current,previous --dry-run
python import_state_legislative.py --state CA --sessions current,previous --dry-run
```
