# Phase 119: Read & Rank Location Filter Repair - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-15
**Phase:** 119-read-rank-location-filter-repair
**Areas discussed:** Diagnosis scope, Test verification, Filter behavior, Backend wiring

---

## Diagnosis Scope

### Which filter mode is broken?

| Option | Description | Selected |
|--------|-------------|----------|
| Both are broken | Neither address search nor browse-by-location returns results for Monroe County | |
| Address mode only | Browse mode works but address search (geocoding path) fails | |
| Not sure | Haven't tested recently — research step should diagnose which paths fail | ✓ |

**User's choice:** Not sure — investigate both paths
**Notes:** Root cause unknown; research must diagnose end-to-end

### Filter threshold

| Option | Description | Selected |
|--------|-------------|----------|
| Keep at 2 (Recommended) | Read & Rank needs at least 2 candidates for meaningful matchups | ✓ |
| Lower to 1 | Show any issue where at least 1 local rep has a quote | |
| You decide | Claude picks the threshold | |

**User's choice:** Keep at 2

### Root cause suspicion

| Option | Description | Selected |
|--------|-------------|----------|
| Unknown — investigate | Research step should diagnose: DB quotes exist? API returns them? Frontend wires them? | ✓ |
| Likely data gap | Monroe County candidates may not have quotes in the DB | |
| Likely API/wiring | Quotes exist but search/filter path doesn't connect correctly | |

**User's choice:** Unknown — investigate

---

## Test Verification

### Test address

| Option | Description | Selected |
|--------|-------------|----------|
| 401 N Morton St, Bloomington | City Hall — matches mayor, council, county, state, federal | |
| Same as Kirkwood from Phase 121 | Use the Kirkwood Ave test address from MATRIX.md | ✓ |
| You pick a Bloomington address | Claude selects a good test address | |

**User's choice:** Same as Kirkwood from Phase 121

### Verification environment

| Option | Description | Selected |
|--------|-------------|----------|
| Production only (Recommended) | readrank.empowered.vote is the source of truth | ✓ |
| Local dev is fine | Fix verified locally; Render auto-deploys on merge | |
| Both | Verify locally during dev, confirm on production | |

**User's choice:** Production only

---

## Filter Behavior

### Hidden vs shown issues

| Option | Description | Selected |
|--------|-------------|----------|
| Hide them (current behavior) | Only show issues with enough local content for matchups | ✓ |
| Show with a message | Grey out with "Not enough local quotes" | |
| You decide | Claude picks the best UX | |

**User's choice:** Hide them (current behavior)

### Zero-state UX

| Option | Description | Selected |
|--------|-------------|----------|
| Message + clear filter button | "No issues with local quotes for this area. Clear filter to see all issues." | ✓ |
| Auto-clear the filter | Silently remove filter and show all issues | |
| You decide | Claude picks the zero-state UX | |

**User's choice:** Message + clear filter button

---

## Backend Wiring

### CORS/routing

| Option | Description | Selected |
|--------|-------------|----------|
| Not sure — investigate | Research should test endpoints from readrank origin | ✓ |
| Known CORS issue | CORS errors seen in browser console | |
| No CORS issues | Other API calls from Read & Rank work fine | |

**User's choice:** Not sure — investigate

### Google Maps API key

| Option | Description | Selected |
|--------|-------------|----------|
| Not sure — investigate | Check VITE_GOOGLE_MAPS_KEY in Render env vars | |
| Yes, it's configured | Google Places works; read-rank shares the same key | ✓ |
| Probably not | Might be root cause — address mode fails silently | |

**User's choice:** Yes, it's configured

---

## Claude's Discretion

- Exact diagnostic commands and SQL queries during investigation
- Fix order if multiple breaks found (data → wiring → frontend suggested)
- Zero-state UX implementation approach (new component vs inline message)

## Deferred Ideas

None — discussion stayed within phase scope.
