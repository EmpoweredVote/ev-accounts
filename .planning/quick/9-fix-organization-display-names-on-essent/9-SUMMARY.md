---
phase: quick-9
plan: 01
subsystem: EV-Backend/essentials
tags: [data-seed, government-bodies, display-names, ellettsville, indiana]
dependency_graph:
  requires: []
  provides: [government_body_name values for Ellettsville, Richland Township, Richland-Bean Blossom]
  affects: [essentials results page section headers]
tech_stack:
  added: []
  patterns: [name_formal chamber grouping, government_bodies seed rows]
key_files:
  created: []
  modified:
    - EV-Backend/internal/essentials/setup.go
decisions:
  - Set name_formal on all Ellettsville council ward chambers to group them under 'Ellettsville Town Council' body_key
  - Created separate 'Ellettsville Town Officials' body_key for the Clerk/Treasurer chamber
  - Also grouped Bean Blossom Township while fixing Richland Township (same locality pattern)
metrics:
  duration: "~10 min"
  completed: "2026-03-12"
  tasks_completed: 1
  files_changed: 1
---

# Quick-9: Fix Organization Display Names on Essentials Summary

**One-liner:** Seeded `government_bodies` rows and set `name_formal` on Ellettsville, Richland Township, and Richland-Bean Blossom chambers so section headers show actual body names instead of generic fallbacks.

## What Was Done

### Root Cause

The JOIN in `fetchOfficialsFromDB` maps `COALESCE(NULLIF(c.name_formal, ''), c.name, '')` to a `government_bodies` row. For Ellettsville and other non-Bloomington localities, both `name_formal` was empty AND no `government_bodies` rows existed, so `government_body_name` returned `''` and the frontend fell back to generic labels.

### Changes Made

**`EV-Backend/internal/essentials/setup.go`**

Added `UPDATE essentials.chambers SET name_formal = ...` blocks for:
- Ellettsville Town Council wards (Ward 1/2/3) → `'Ellettsville Town Council'`
- Ellettsville Town Clerk/Treasurer → `'Ellettsville Town Officials'`
- Monroe County: Richland Township Board + Trustee → `'Richland Township'`
- Richland-Bean Blossom School Board (At Large, Bean Blossom Twp, Richland Twp seats) → `'Richland-Bean Blossom Community School Corporation'`
- Monroe County: Bean Blossom Township Board + Trustee → `'Bean Blossom Township'`

Added 5 new `government_bodies` seed rows (ON CONFLICT DO NOTHING):
| geo_id | body_key | display_name |
|--------|----------|--------------|
| 1820800 | Ellettsville Town Council | Ellettsville Town Council |
| 1820800 | Ellettsville Town Officials | Ellettsville Town Officials |
| 1810564152 | Richland Township | Richland Township |
| 1809480 | Richland-Bean Blossom Community School Corporation | Richland-Bean Blossom Community School Corporation |
| 1810503808 | Bean Blossom Township | Bean Blossom Township |

## Verification

Tested `GET /essentials/politicians/47429` (Ellettsville ZIP):
- `Ellettsville Town Council` present
- `Ellettsville Town Officials` present
- `Richland Township` present
- `Richland-Bean Blossom Community School Corporation` present
- Monroe County / Bloomington names unchanged (regression verified via ZIP 47401)

## Deviations from Plan

### Auto-added: Bean Blossom Township

**Found during:** Task 1 discovery queries

**Issue:** Bean Blossom Township Board and Trustee also lacked `name_formal` and `government_bodies` rows, identical problem to Richland Township.

**Fix:** Added Bean Blossom Township to both the `name_formal` UPDATE and the `government_bodies` seed INSERT.

**Files modified:** EV-Backend/internal/essentials/setup.go

**Commit:** 580b995

## Commits

| Hash | Message |
|------|---------|
| 580b995 | feat(quick-9): seed government_bodies for Ellettsville, Richland Township, Richland-Bean Blossom |

## Self-Check

- [x] EV-Backend/internal/essentials/setup.go modified
- [x] go build passes (no output = success)
- [x] API returns correct display names for ZIP 47429
- [x] Bloomington regression check passed (ZIP 47401)
- [x] Commit 580b995 exists in EV-Backend repo
