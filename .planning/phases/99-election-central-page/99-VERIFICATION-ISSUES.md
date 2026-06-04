# 99 Verification Issues

**Date:** 2026-06-04
**Verified by:** Playwright (automated)
**Test address:** 123 Main St, Salt Lake City, UT 84101
**Redirect confirmed:** yes — final URL: https://essentials.empowered.vote/results?prefilled=true&view=elections&q=123+Main+St%2C+Salt+Lake+City%2C+UT+84101

## Data Issues
None found.

Address geocoded/normalized to "123 S Main St, Salt Lake City, UT, 84111" — expected geocoder behavior, not a bug.

## UI Issues
None found.

Elections tab active with "Primary · Jun 23, 2026 · 19 days away" label. Races grouped by tier (Local → Executive + Legislative, State → Legislative + Other, Federal). Many races visible — Salt Lake County (Assessor D/R, Auditor D/R, Clerk D, Recorder D, Sheriff D/R, Surveyor R, Council At-Large A D/R, Council District 1 D, District Attorney D/R), Utah State Senate District 9 (D/R), Utah State House District 22 (D/R), Utah State Board of Education District 5 (D/R), U.S. House District 1 (D primary with 4 candidates). Total well exceeds 3-race minimum.

Candidate spot-checks: Jiro Johnson ✓, Jen Dailey-Provost ✓, Sim Gill ✓, Ben McAdams ✓, Joel Frost ✓, Ali Cloward ✓.

## Mobile Issues
None found. At 375px: no horizontal scroll, cards stack vertically, UNOPPOSED badge renders correctly, Elections tab with "19 days away" pill visible.

## Console Errors
1 error: `401 Failed to load resource @ /api/auth/session` — expected for unauthenticated Playwright session. Not a bug.

## Withdrawn Candidate Behavior
N/A — no withdrawn candidates in UT 2026 Primary data set.

## Summary
**PASS.** All acceptance criteria met. No data issues, no UI issues, no mobile issues. The single 401 console error is an expected auth-check for unauthenticated users and does not affect functionality.
