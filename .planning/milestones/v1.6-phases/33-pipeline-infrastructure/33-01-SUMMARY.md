---
phase: 33-pipeline-infrastructure
plan: 01
subsystem: infra
tags: [python, geopandas, sqlalchemy, psycopg2, shapefile, geofence, import-scripts]

# Dependency graph
requires:
  - phase: 32-schema-fixes-and-lookup-bug-correction
    provides: correct unique constraint on geofence_boundaries and MTFCC map

provides:
  - EV-Backend/scripts/utils.py with shared get_engine, load_env, next_ext_id functions
  - EV-Backend/scripts/requirements.txt with pinned Python dependencies
  - Three canonical scripts refactored to import from shared utils
  - README.md updated with Python 3.10+, port 5432, and pip install -r requirements.txt setup

affects:
  - phase-34-tiger-geofences
  - phase-35-arcgis-geofences
  - all future import scripts

# Tech tracking
tech-stack:
  added:
    - geopandas==1.1.2
    - SQLAlchemy==2.0.46
    - psycopg2-binary==2.9.11
    - shapely==2.0.7
    - requests==2.32.5
  patterns:
    - Shared utility module pattern for import scripts (utils.py)
    - Synthetic external ID ranges by version (v1.5=-100001, v1.6=-200001)

key-files:
  created:
    - EV-Backend/scripts/utils.py
    - EV-Backend/scripts/requirements.txt
  modified:
    - EV-Backend/scripts/import_missing_geofences.py
    - EV-Backend/scripts/import_school_board_districts.py
    - EV-Backend/scripts/import_ca_legislative_geofences.py
    - EV-Backend/scripts/README.md

key-decisions:
  - "v1.6 synthetic external IDs start at -200001 (not -100001) to avoid collision with v1.5 promote_scraped_officials.py range"
  - "urllib.parse imports stay inside get_engine() body in utils.py — matches the existing pattern from canonical scripts"
  - "promote_scraped_officials.py keeps its own local EXT_ID_COUNTER = -100001 — not refactored, v1.5 script kept isolated"
  - "No __init__.py added to scripts/ — scripts are run directly, not as a Python package"

patterns-established:
  - "Import scripts must use: sys.path.insert(0, str(Path(__file__).parent)); from utils import get_engine, load_env"
  - "Python 3.10+ required for all import scripts (geopandas 1.1.2 constraint)"
  - "Always use direct connection port 5432, never pooler port 6543"

requirements-completed: [PIPE-01, PIPE-02, PIPE-03]

# Metrics
duration: 5min
completed: 2026-02-24
---

# Phase 33 Plan 01: Pipeline Infrastructure Summary

**Shared Python utility module (utils.py) and pinned requirements.txt created; three canonical import scripts refactored to import from shared module, eliminating duplicate get_engine/load_env function bodies**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-02-24T06:35:40Z
- **Completed:** 2026-02-24T06:40:09Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Created `utils.py` with three shared functions: `load_env()`, `get_engine()`, `next_ext_id()` starting at -200001
- Created `requirements.txt` pinning all 5 import dependencies to exact versions
- Removed duplicate `load_env()` and `get_engine()` bodies from all three canonical scripts
- Updated README.md with Python 3.10+ requirement, direct connection (port 5432), `python3.13 -m pip install -r requirements.txt`, and shared utils import pattern

## Task Commits

Each task was committed atomically in the EV-Backend nested git repository:

1. **Task 1: Create shared utils.py and requirements.txt** - `2196e30` (chore)
2. **Task 2: Update canonical scripts and README documentation** - `422dfc1` (refactor)

**Plan metadata:** committed with docs commit in workspace repo

## Files Created/Modified

- `EV-Backend/scripts/utils.py` — Shared get_engine, load_env, next_ext_id functions; _EXT_ID_COUNTER starts at -200001
- `EV-Backend/scripts/requirements.txt` — Pinned: geopandas==1.1.2, SQLAlchemy==2.0.46, psycopg2-binary==2.9.11, shapely==2.0.7, requests==2.32.5
- `EV-Backend/scripts/import_missing_geofences.py` — Replaced inline load_env/get_engine with `from utils import get_engine, load_env`; removed `create_engine` from sqlalchemy import
- `EV-Backend/scripts/import_school_board_districts.py` — Same refactor; removed `create_engine` from sqlalchemy import
- `EV-Backend/scripts/import_ca_legislative_geofences.py` — Same refactor; removed `create_engine` from sqlalchemy import
- `EV-Backend/scripts/README.md` — Full rewrite of Prerequisites section; added Python 3.10+ requirement, python3.13 usage, requirements.txt one-command setup, port 5432 direct connection note, shared utils pattern documentation, Python version mismatch troubleshooting

## Decisions Made

- v1.6 synthetic external IDs start at -200001 (not -100001) to avoid collision with v1.5 promote_scraped_officials.py range
- `urllib.parse` imports stay inside `get_engine()` body in utils.py — matches the existing pattern from canonical scripts rather than hoisting to module top
- `promote_scraped_officials.py` was deliberately NOT refactored — it's a v1.5 one-time script with its own local counter, not part of the ongoing import pipeline
- No `__init__.py` added to scripts/ — scripts are run directly with python3.13, not imported as a package

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

- The workspace root is a git repository but EV-Backend/ is a nested git repository. Task commits were made to the EV-Backend nested repo (not the workspace root), which is the correct behavior for code changes in that project.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Phase 34 (TIGER geofences) is unblocked: new import scripts can `from utils import get_engine, load_env, next_ext_id` without duplicating function bodies
- Python 3.13 with pinned dependencies is ready to run: `python3.13 -m pip install -r requirements.txt`
- All three canonical scripts verified to still run correctly after refactor (no inline function bodies, utils imports verified)

## Self-Check: PASSED

- utils.py exists and is importable: FOUND
- requirements.txt exists: FOUND
- 33-01-SUMMARY.md exists: FOUND
- Task commit 2196e30 exists in EV-Backend repo: FOUND
- Task commit 422dfc1 exists in EV-Backend repo: FOUND

---
*Phase: 33-pipeline-infrastructure*
*Completed: 2026-02-24*
