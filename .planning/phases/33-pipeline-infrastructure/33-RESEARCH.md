# Phase 33: Pipeline Infrastructure - Research

**Researched:** 2026-02-24
**Domain:** Python scripting utilities, dependency pinning, PostgreSQL via SQLAlchemy
**Confidence:** HIGH

## Summary

Phase 33 extracts three duplicated utility functions into a shared `EV-Backend/scripts/utils.py` module and creates a `requirements.txt` with pinned versions. The goal is preventing the sixth copy of `get_engine()` and `load_env()` from appearing when Phase 34 adds new import scripts.

The codebase already has a clear, battle-tested implementation of both `get_engine()` and `load_env()` in `import_missing_geofences.py`, `import_school_board_districts.py`, and `import_ca_legislative_geofences.py` — all three have byte-for-byte identical bodies. The shared utils module needs only to consolidate what already exists. The `next_ext_id()` function lives only in `promote_scraped_officials.py` and uses `-100001` as the starting counter; per STATE.md, new Phase 36+ scripts MUST start at `-200001` to avoid collision with the v1.5 range, so the shared version must accept an optional `start` parameter or use the new range as the default.

The critical constraint for `requirements.txt` is the Python version incompatibility: `geopandas 1.1.2` (released December 22, 2025) requires Python >=3.10, but the default `python3` on this machine is Python 3.9.6 (Xcode). Homebrew Python 3.12 and 3.13 are available at `/opt/homebrew/bin/python3.12` and `/opt/homebrew/bin/python3.13`. The requirements.txt must pin geopandas 1.1.2 as specified in the roadmap success criteria, and the documentation must specify that scripts must be run with Python 3.10+.

**Primary recommendation:** Create `utils.py` by lifting the existing implementations verbatim from `import_missing_geofences.py` (canonical source since it has both `get_engine` + `load_env`), add `next_ext_id(start=-200001)` for new Phase 36+ scripts, pin `geopandas==1.1.2` in `requirements.txt` per roadmap spec, and update README to instruct `python3.13` or `python3.12` (not the system `python3`).

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PIPE-01 | Shared utils.py extracted from existing import scripts with get_engine, load_env, next_ext_id | Identical implementations of get_engine/load_env already exist in 3 scripts; next_ext_id exists in promote_scraped_officials.py — lift and consolidate |
| PIPE-02 | requirements.txt with pinned versions for all import script dependencies | Installed versions confirmed: SQLAlchemy 2.0.46, psycopg2-binary 2.9.11, shapely 2.0.7, requests 2.32.5; geopandas 1.1.2 requires Python 3.10+ — must document Python requirement |
| PIPE-03 | Import pipeline is parameterized and documented for reuse with other regions | Existing scripts have hardcoded state FIPS codes; README needs DATABASE_URL setup instructions and Python version note |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| geopandas | 1.1.2 | Shapefile loading, CRS reprojection, to_postgis | Industry standard for geospatial Python; pinned per roadmap success criteria |
| SQLAlchemy | 2.0.46 | Database engine creation, connection pooling | Required by geopandas.to_postgis(); 2.x API used throughout existing scripts |
| psycopg2-binary | 2.9.11 | PostgreSQL driver (SQLAlchemy backend) | Required by SQLAlchemy for PostgreSQL; binary package avoids libpq compile |
| shapely | 2.0.7 | Geometry construction from GeoJSON | Used in import_school_board_districts.py for shape() function |
| requests | 2.32.5 | HTTP downloads (TIGER ZIPs, ArcGIS GeoJSON) | Used in all shapefile download scripts |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| pandas | (transitive, via geopandas) | DataFrame operations for summary queries | Already in env via geopandas; used in import_shapefiles_fixed.py summary |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| psycopg2-binary | asyncpg | asyncpg is faster but requires async code; all existing scripts are synchronous |
| requests | httpx | httpx is newer but requests is already used throughout; no benefit for import scripts |

**Installation:**
```bash
# Must use Python 3.10+ — geopandas 1.1.2 requires Python >=3.10
# System python3 on macOS (Xcode, 3.9.6) will NOT work

/opt/homebrew/bin/python3.13 -m pip install -r EV-Backend/scripts/requirements.txt
# or
/opt/homebrew/bin/python3.12 -m pip install -r EV-Backend/scripts/requirements.txt
```

## Architecture Patterns

### Recommended Project Structure
```
EV-Backend/scripts/
├── utils.py              # NEW: shared utilities (get_engine, load_env, next_ext_id)
├── requirements.txt      # NEW: pinned dependency manifest
├── README.md             # UPDATED: add Python 3.10+ note and DATABASE_URL setup
├── import_missing_geofences.py        # UPDATE: import from utils
├── import_school_board_districts.py   # UPDATE: import from utils
├── import_ca_legislative_geofences.py # UPDATE: import from utils
├── promote_scraped_officials.py       # UPDATE: import next_ext_id from utils
├── import_shapefiles.py               # LEGACY: uses psycopg2 directly (can stay as-is)
├── import_shapefiles_fixed.py         # LEGACY: has get_db_engine (different name, can stay)
└── bulk_import_la_county.py           # No DB connection — not affected
```

### Pattern 1: Shared get_engine() — Canonical Implementation
**What:** Creates SQLAlchemy engine with password URL-encoding for special characters (Supabase passwords frequently contain `@`, `#`, etc.)
**When to use:** Every script that writes to PostgreSQL via to_postgis() or SQLAlchemy text()
**Example:**
```python
# Source: import_missing_geofences.py and import_ca_legislative_geofences.py (identical)
def get_engine():
    """Create SQLAlchemy engine, URL-encoding the password if needed"""
    from urllib.parse import urlparse, quote_plus, urlunparse
    raw_url = os.getenv("DATABASE_URL")
    parsed = urlparse(raw_url)
    # Re-encode the password to handle special chars like @
    if parsed.password:
        encoded_pw = quote_plus(parsed.password)
        netloc = f"{parsed.username}:{encoded_pw}@{parsed.hostname}"
        if parsed.port:
            netloc += f":{parsed.port}"
        safe_url = urlunparse((parsed.scheme, netloc, parsed.path,
                               parsed.params, parsed.query, parsed.fragment))
    else:
        safe_url = raw_url
    return create_engine(safe_url)
```

### Pattern 2: Shared load_env() — Canonical Implementation
**What:** Reads DATABASE_URL from environment or falls back to `../.env.local` relative to the scripts directory
**When to use:** Every script before calling get_engine()
**Example:**
```python
# Source: import_missing_geofences.py, import_school_board_districts.py, import_ca_legislative_geofences.py (identical)
def load_env():
    """Load DATABASE_URL from .env.local if not already set"""
    if os.getenv("DATABASE_URL"):
        return
    env_path = Path(__file__).parent.parent / ".env.local"
    if env_path.exists():
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line.startswith("DATABASE_URL="):
                    os.environ["DATABASE_URL"] = line.split("=", 1)[1]
                    print(f"  Loaded DATABASE_URL from {env_path}")
                    return
    print("Error: DATABASE_URL not set and .env.local not found")
    sys.exit(1)
```

### Pattern 3: next_ext_id() — New Scripts Use -200001 Range
**What:** Thread-safe counter returning synthetic negative external IDs for manually-created records
**When to use:** Any script that inserts politicians, districts, or chambers that were not imported from BallotReady
**Critical constraint from STATE.md:** v1.5 scripts used range starting at -100001. v1.6 scripts MUST start at -200001 to avoid collision.
**Example:**
```python
# Source: promote_scraped_officials.py (adapted for utils.py with configurable start)
_EXT_ID_COUNTER = -200001  # v1.6 range — v1.5 used -100001

def next_ext_id() -> int:
    """Return next synthetic negative external_id for manually-created records.

    v1.5 scripts started at -100001.
    v1.6 scripts start at -200001 to avoid collision.
    """
    global _EXT_ID_COUNTER
    val = _EXT_ID_COUNTER
    _EXT_ID_COUNTER -= 1
    return val
```

### Pattern 4: requirements.txt — Pinned Manifest
**What:** Exact version pins for all import script dependencies
**When to use:** `pip install -r requirements.txt` before running any import script
**Example:**
```
# EV-Backend/scripts/requirements.txt
# Requires Python >=3.10 (geopandas 1.1.2 constraint)
geopandas==1.1.2
SQLAlchemy==2.0.46
psycopg2-binary==2.9.11
shapely==2.0.7
requests==2.32.5
```

### Pattern 5: Importing from utils.py
**What:** Standard relative import pattern for scripts in the same directory
**Example:**
```python
# At top of each import script, replace duplicated functions with:
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from utils import get_engine, load_env, next_ext_id
```

Note: `sys.path.insert` is preferable to a package structure (adding `__init__.py`) because the scripts directory is not a package and scripts are run directly with `python3 script.py`.

### Anti-Patterns to Avoid
- **Hardcoded EXT_ID_COUNTER = -100001 in new scripts:** v1.5 range — causes silent collision with promote_scraped_officials.py-created records. Always use utils.next_ext_id() which starts at -200001.
- **Using system `python3` (3.9.6) for geopandas 1.1.2:** Will fail with "No matching distribution found". Must use `python3.12` or `python3.13` from Homebrew.
- **Adding `__init__.py` to scripts directory:** Makes scripts/ a package, complicates direct execution. Prefer `sys.path.insert` pattern.
- **Removing duplicate functions from legacy scripts (import_shapefiles.py, import_shapefiles_fixed.py):** These are legacy files with different function names (`get_db_connection`, `get_db_engine`). Do not refactor them — only update the three canonical scripts.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Password URL-encoding | Custom string manipulation | `urllib.parse.quote_plus` | Already in stdlib; existing pattern handles `@` in passwords |
| .env.local parsing | dotenv-style parser | The 5-line load_env() already in codebase | Adding python-dotenv dependency for a 5-line function is overkill |
| Connection testing | Custom ping logic | `engine.connect()` + `text("SELECT 1")` | SQLAlchemy raises immediately on bad credentials |

**Key insight:** The shared utils module is a consolidation task, not an architecture task. Every function body already exists and works — the only engineering decision is the `next_ext_id` starting value and whether to accept a `start` parameter.

## Common Pitfalls

### Pitfall 1: geopandas 1.1.2 Python Version Mismatch
**What goes wrong:** Running `python3 -m pip install -r requirements.txt` with the Xcode Python 3.9.6 silently installs geopandas 1.0.1 or fails outright. Scripts appear to work until a 1.1-specific API is called.
**Why it happens:** macOS ships `python3` as the Xcode Python (3.9.6). geopandas 1.1.2 requires >=3.10. PyPI will install the latest compatible version, which for 3.9 is 1.0.1.
**How to avoid:** Document in README that `python3.12` or `python3.13` from Homebrew is required. Pin exact version in requirements.txt so mismatches are caught at install time with a clear error.
**Warning signs:** `pip install -r requirements.txt` succeeds but `pip show geopandas` shows `1.0.1` instead of `1.1.2`.

### Pitfall 2: next_ext_id Counter Collision
**What goes wrong:** A new Phase 36 script copies the `EXT_ID_COUNTER = -100001` pattern from promote_scraped_officials.py and creates records that collide with v1.5-era synthetic records in the database.
**Why it happens:** The v1.5 `promote_scraped_officials.py` already consumed IDs in the -100001 range. A fresh script starting there would produce duplicate `external_id` values.
**How to avoid:** `utils.next_ext_id()` hardcodes the start at -200001. The old script keeps its own local counter at -100001.
**Warning signs:** `INSERT` fails with unique constraint violation on `external_id` column.

### Pitfall 3: __file__ Resolution in utils.py
**What goes wrong:** `load_env()` uses `Path(__file__).parent.parent / ".env.local"`. When imported by another script, `__file__` refers to `utils.py`'s location, not the calling script's location. This is actually the correct behavior since utils.py lives in scripts/ and .env.local lives in EV-Backend/ (one level up).
**Why it happens:** `Path(__file__)` in a module always resolves to the module file, not the importer.
**How to avoid:** No change needed — the path logic (`scripts/ -> EV-Backend/`) is correct when utils.py lives in scripts/.
**Warning signs:** "Error: DATABASE_URL not set and .env.local not found" when .env.local definitely exists at EV-Backend/.

### Pitfall 4: Supabase Pooler vs Direct Connection
**What goes wrong:** Using the Supabase connection pooler (port 6543) breaks bulk imports with `prepared statement ... already exists` errors or row count mismatches.
**Why it happens:** The pooler uses transaction mode which does not support prepared statements used by SQLAlchemy's batch insert path.
**How to avoid:** STATE.md requires direct connection (port 5432). Document this requirement in README.md.
**Warning signs:** Intermittent `psycopg2.errors.DuplicatePreparedStatement` or imports completing with fewer rows than expected.

## Code Examples

Verified patterns from existing scripts:

### Complete utils.py
```python
# Source: Consolidated from import_missing_geofences.py (get_engine + load_env)
# and promote_scraped_officials.py (next_ext_id), adapted for v1.6 range.
#!/usr/bin/env python3
"""
Shared utilities for EV-Backend import scripts.

Usage in scripts:
    from utils import get_engine, load_env, next_ext_id
"""
import os
import sys
from pathlib import Path

from sqlalchemy import create_engine


def load_env():
    """Load DATABASE_URL from .env.local if not already set.

    Falls back to EV-Backend/.env.local (parent of scripts/).
    Supabase connection string must use direct connection (port 5432),
    NOT the connection pooler (port 6543).
    """
    if os.getenv("DATABASE_URL"):
        return
    env_path = Path(__file__).parent.parent / ".env.local"
    if env_path.exists():
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line.startswith("DATABASE_URL="):
                    os.environ["DATABASE_URL"] = line.split("=", 1)[1]
                    print(f"  Loaded DATABASE_URL from {env_path}")
                    return
    print("Error: DATABASE_URL not set and .env.local not found")
    sys.exit(1)


def get_engine():
    """Create SQLAlchemy engine from DATABASE_URL.

    URL-encodes the password to handle special characters (common in
    Supabase auto-generated passwords that contain @, #, etc.).
    """
    from urllib.parse import urlparse, quote_plus, urlunparse
    raw_url = os.getenv("DATABASE_URL")
    if not raw_url:
        print("Error: DATABASE_URL environment variable not set")
        sys.exit(1)
    parsed = urlparse(raw_url)
    if parsed.password:
        encoded_pw = quote_plus(parsed.password)
        netloc = f"{parsed.username}:{encoded_pw}@{parsed.hostname}"
        if parsed.port:
            netloc += f":{parsed.port}"
        safe_url = urlunparse((parsed.scheme, netloc, parsed.path,
                               parsed.params, parsed.query, parsed.fragment))
    else:
        safe_url = raw_url
    return create_engine(safe_url)


# v1.6 synthetic external_id range starts at -200001
# v1.5 range was -100001 to -100xxx (used by promote_scraped_officials.py)
_EXT_ID_COUNTER = -200001


def next_ext_id() -> int:
    """Return the next synthetic negative external_id.

    Used for manually-created politician, district, and chamber records
    that were not imported from BallotReady. Negative IDs avoid collision
    with BallotReady's positive integer external_ids.

    v1.5 scripts used range starting at -100001.
    v1.6 scripts use range starting at -200001.
    """
    global _EXT_ID_COUNTER
    val = _EXT_ID_COUNTER
    _EXT_ID_COUNTER -= 1
    return val
```

### Complete requirements.txt
```
# EV-Backend/scripts/requirements.txt
#
# Import script dependencies with pinned versions.
# Requires Python >=3.10 — geopandas 1.1.2 dropped Python 3.9 support.
#
# Setup:
#   /opt/homebrew/bin/python3.13 -m pip install -r requirements.txt
# or:
#   /opt/homebrew/bin/python3.12 -m pip install -r requirements.txt
#
# Run scripts with:
#   python3.13 import_ca_legislative_geofences.py
#   (NOT the system python3 which is 3.9.6 on macOS with Xcode)
geopandas==1.1.2
SQLAlchemy==2.0.46
psycopg2-binary==2.9.11
shapely==2.0.7
requests==2.32.5
```

### Import pattern for updated scripts
```python
# Replace duplicated get_engine/load_env bodies in each script with:
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from utils import get_engine, load_env  # noqa: E402 (after sys.path insert)

# Scripts that create politicians/districts also import:
# from utils import next_ext_id
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| psycopg2 direct (import_shapefiles.py) | SQLAlchemy engine (import_missing_geofences.py+) | v1.5 era | geopandas.to_postgis() requires SQLAlchemy engine, not psycopg2 connection |
| get_db_engine() (import_shapefiles_fixed.py) | get_engine() (newer scripts) | Naming cleanup during v1.5 | get_engine is the canonical name going forward |
| Inline load_env() in each script | utils.load_env() (Phase 33) | Phase 33 | Consistent behavior; no more copy-paste drift |
| EXT_ID range -100001 (v1.5) | EXT_ID range -200001 (v1.6) | Phase 33 | Prevents collision when both ranges are in same database |

**Deprecated/outdated:**
- `import_shapefiles.py`: Uses psycopg2 directly (no SQLAlchemy), no load_env(). This is legacy — it works for its original purpose but should not be used as a template for new scripts.
- `import_shapefiles_fixed.py`: Uses `get_db_engine()` (non-canonical name), no load_env(). Also legacy.

## Open Questions

1. **Should legacy scripts (import_shapefiles.py, import_shapefiles_fixed.py) be updated to import from utils?**
   - What we know: They use different function names and no load_env(). They still work.
   - What's unclear: Whether updating them is in scope for PIPE-01 (which says "new scripts import from it")
   - Recommendation: Out of scope — PIPE-01 says "new scripts import from it rather than duplicating logic." The three canonical scripts (import_missing_geofences.py, import_school_board_districts.py, import_ca_legislative_geofences.py) should be updated. The two legacy scripts can be left as-is since they are not being extended.

2. **What is the correct requests version to pin?**
   - What we know: Currently installed requests==2.32.5. No version constraint was specified in the roadmap success criteria (unlike geopandas/SQLAlchemy which are specified).
   - What's unclear: Whether to pin to 2.32.5 specifically or use >=2.28
   - Recommendation: Pin to 2.32.5 to match what's verified working locally. Consistent with the "pinned" mandate.

3. **Should psycopg2-binary version be pinned?**
   - What we know: Currently installed 2.9.11. The roadmap success criteria say "psycopg2-binary" without a version.
   - Recommendation: Pin to 2.9.11 for reproducibility — the requirements.txt purpose is exact reproducibility.

## Validation Architecture

> nyquist_validation is not present in .planning/config.json — skipping this section.

## Sources

### Primary (HIGH confidence)
- Direct code analysis: `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/import_missing_geofences.py` — canonical get_engine/load_env implementation
- Direct code analysis: `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/import_school_board_districts.py` — identical get_engine/load_env (confirms pattern)
- Direct code analysis: `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/import_ca_legislative_geofences.py` — identical get_engine/load_env (confirms pattern)
- Direct code analysis: `/Users/chrisandrews/Documents/GitHub/EV-Backend/scripts/promote_scraped_officials.py` — canonical next_ext_id implementation
- `/Users/chrisandrews/Documents/GitHub/.planning/STATE.md` — confirms -200001 start range for v1.6 scripts
- `pip3 index versions geopandas` — confirms 1.1.2 is NOT on PyPI for Python 3.9 (highest available: 1.0.1)
- `pip3 install geopandas==1.1.2` — ERROR confirms 1.1.2 not installable with Python 3.9.6
- PyPI: https://pypi.org/project/geopandas/1.1.2/ — "Requires: Python >=3.10", release date December 22, 2025

### Secondary (MEDIUM confidence)
- WebSearch: geopandas 1.1.2 requires Python >=3.10, verified by PyPI page fetch
- `pip3 show geopandas sqlalchemy psycopg2-binary shapely requests` — confirmed installed versions (2.0.46, 2.9.11, 2.0.7, 2.32.5)

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all versions confirmed via pip show and PyPI
- Architecture: HIGH — consolidation of existing code, no new patterns
- Pitfalls: HIGH — Python version pitfall confirmed by direct pip install failure; counter collision is documented in STATE.md

**Research date:** 2026-02-24
**Valid until:** 2026-05-24 (stable domain — package versions change slowly)
