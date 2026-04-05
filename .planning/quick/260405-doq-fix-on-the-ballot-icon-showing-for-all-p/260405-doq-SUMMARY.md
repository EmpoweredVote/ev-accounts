# Quick Task 260405-doq: Fix ballot icon showing for all politicians

## What Changed

Replaced the `UPCOMING_ELECTIONS_LATERAL` SQL lateral join in `essentialsService.ts` to filter by actual ballot participation instead of matching broadly by state.

### Root Cause
The original lateral join matched elections only by `e.state = d.state`, meaning every Indiana politician received the next election date for the entire state — causing the "on the ballot" icon to appear for all politicians.

### Fix
The new lateral join correlates through `essentials.races` (by `office_id`) and `essentials.race_candidates` (by `politician_id`) so only politicians with an actual race for their office or who are explicitly listed as active candidates receive election dates.

## Files Modified
- `ev-accounts/backend/src/lib/essentialsService.ts` — replaced `UPCOMING_ELECTIONS_LATERAL` constant
- `ev-accounts/backend/src/lib/essentialsBrowseService.ts` — added field mappings for type compatibility

## Verification
- TypeScript compiles without errors
- Tested against live DB: ballot icon now shows for 15 of 108 politicians (those with actual races) instead of all 108

## Commit
- `6db60d7` — fix(quick-260405-doq): filter ballot icon to politicians with actual races
