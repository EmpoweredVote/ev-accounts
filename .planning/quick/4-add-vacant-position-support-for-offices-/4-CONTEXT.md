# Quick Task 4: Vacant Position Support & Kristi Noem DHS Removal - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Task Boundary

Add robust vacant position support to the essentials module so that when officials leave office, the seat can be displayed as "Vacant" in search results. Immediate use case: Kristi Noem fired as Secretary of Homeland Security.

</domain>

<decisions>
## Implementation Decisions

### Vacancy Modeling
- Model vacancy at the **Office level** — add `is_vacant` (bool) and `vacant_since` (date) fields to the `essentials.offices` table
- No dummy/placeholder politician records — the office itself carries vacancy state
- Backend returns vacant offices alongside filled ones in search results

### Vacant Card UI
- Vacant positions appear **inline** in their normal classification position (e.g., Federal > Cabinet)
- Dimmed/muted styling with a "Vacant" badge
- No photo area (or empty-seat placeholder)
- Position title remains visible so users know the seat exists

### Noem's Record Handling
- Set `is_active = false` on Kristi Noem's politician record (preserves her data for future reassignment)
- Her office row (DHS Secretary) stays but gets `is_vacant = true` with `vacant_since` date
- Detach politician from office (set `politician_id = NULL` on the office, or use the vacancy flag to skip rendering her)
- If she gets a new position later, create a new office linking to her reactivated record

### Claude's Discretion
- Exact SQL migration approach
- API response structure for vacant offices (can extend existing OfficialOut or add a parallel VacantOfficeOut)

</decisions>

<specifics>
## Specific Ideas

- The `classify.js` already has a `VACANT` district type filter (`first_name !== 'VACANT'`) — this can be replaced with proper `is_vacant` office-level logic
- The `is_vacant` field already exists on the Politician model but should move conceptually to Office
- Backend query in `fetchOfficialsFromDB` currently filters `is_active = true` — need to also return vacant offices that have no active politician

</specifics>
