---
name: s0g-CONTEXT
description: User decisions for elections page multi-seat unopposed label quick task
type: context
---

# Quick Task s0g: Elections Page Multi-Seat Unopposed Label — Context

**Gathered:** 2026-04-26
**Status:** Ready for planning

<domain>
## Task Boundary

The elections page in `essentials` already shows "Running Unopposed" for single-candidate races. However, some races have multiple seats (e.g., township board, city council at-large), where voters elect more than one person. When the number of active candidates is ≤ the seat count, all candidates are effectively guaranteed to win — but the current UI only flags this for single-candidate races (`activeCandidates.length === 1`). Fix this so multi-seat unopposed races are correctly labeled with seat context.

</domain>

<decisions>
## Implementation Decisions

### Label phrasing for multi-seat unopposed
- Single-seat: "Running Unopposed" (no change — existing behavior)
- Multi-seat: "Running Unopposed (N seats)" where N = the race's seat count
- The seat count goes in parentheses to keep the primary message dominant

### What triggers "unopposed" status
- Condition: `activeCandidates.length > 0 && activeCandidates.length <= race.seats`
- Covers both exact-fill (3 candidates, 3 seats) and under-fill (2 candidates, 3 seats)
- Single-seat stays as-is (semantically: `count <= 1`)

### Single-seat label consistency
- Single-seat races: keep "Running Unopposed" with NO seat count appended
- Only multi-seat races get the "(N seats)" suffix

### Claude's Discretion
- ev-ui backwards compatibility strategy: make `running_unopposed` accept string | boolean — if string, render it as the banner text; if boolean true, fall back to "Running Unopposed" (unchanged behavior for all existing callers)
- The change to ev-ui is a patch bump (0.6.4); essentials currently pins `^0.6.3` so it's compatible
- ElectionsView.jsx changes can ship independently; degraded behavior (shows "Running Unopposed" without seat count) until ev-ui 0.6.4 reaches production

</decisions>

<specifics>
## Specific Implementation Notes

**Where `seats` lives:** `seats: number` is already on the `ElectionRace` interface in `ev-accounts/backend/src/lib/electionService.ts` and is returned by the API. It is NOT currently forwarded into the `processedElections` useMemo in `essentials/src/components/ElectionsView.jsx`.

**Files to change:**

1. `ev-ui/src/CompassCardVertical.jsx` (line ~371): Change hardcoded "Running Unopposed" to:
   `{typeof politician.running_unopposed === 'string' ? politician.running_unopposed : 'Running Unopposed'}`

2. `ev-ui/src/CompassCardHorizontal.jsx` (line ~325): Same change.

3. `ev-ui/package.json`: Bump version to 0.6.4, push tag to trigger npm publish + auto-bump pipeline.

4. `essentials/src/components/ElectionsView.jsx`:
   - In `processedElections` useMemo (line ~331): forward `seats: race.seats || 1` onto the processed race object
   - Update `isUnopposed` (line ~563): `const seats = race.seats || 1; const isUnopposed = activeCandidates.length > 0 && activeCandidates.length <= seats;`
   - In `polForCard` (line ~634): set `running_unopposed` to `true` for single-seat or `\`Running Unopposed (${seats} seats)\`` for multi-seat

</specifics>

<canonical_refs>
## Canonical References

- `essentials/src/components/ElectionsView.jsx` — current isUnopposed logic and card rendering
- `ev-ui/src/CompassCardVertical.jsx` lines 362–373 — existing banner rendering
- `ev-ui/src/CompassCardHorizontal.jsx` lines 323–330 — existing banner rendering
- `ev-accounts/backend/src/lib/electionService.ts` — ElectionRace interface with `seats` field

</canonical_refs>
