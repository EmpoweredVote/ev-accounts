---
status: complete
phase: 99-election-central-page
source: 99-01-SUMMARY.md, 99-02-SUMMARY.md, 99-03-SUMMARY.md, 99-04-SUMMARY.md, 99-05-SUMMARY.md
started: 2026-06-04T00:00:00Z
updated: 2026-06-05T02:15:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Cold Start Smoke Test
expected: Kill any running server/service. Clear ephemeral state (temp DBs, caches, lock files). Start the application from scratch. Server boots without errors, any seed/migration completes, and a primary query (health check, homepage load, or basic API call) returns live data.
result: skipped
reason: testing on live site instead

### 2. Elections API — valid address returns elections
expected: GET /api/essentials/elections-by-address?address=123+Main+St%2C+Salt+Lake+City%2C+UT+84101 returns HTTP 200 with { elections: [...] } containing geofence-matched races for that SLC address. At least one election with races and candidates is present in the response.
result: pass

### 3. Elections API — missing address returns 422
expected: GET /api/essentials/elections-by-address (no address param, or empty string) returns HTTP 422 with error code VALIDATION_ERROR. The endpoint does not crash and does not return 500.
result: pass

### 4. Elections page loads at /elections
expected: Navigate to https://essentials.empowered.vote/elections — the page renders (or redirects to /results?view=elections), an address input form is visible, and there are no JS errors in the console (the single 401 on /api/auth/session is expected for unauthenticated users and is not an error).
result: pass

### 5. Address form submits and shows elections grouped by tier
expected: Enter "123 Main St, Salt Lake City, UT 84101" into the address form and submit. Elections appear grouped by Federal, State, and Local tiers. At least one election is visible with races and candidate names.
result: pass

### 6. Antipartisan display — no party labels
expected: In the UT 2026 Primary results, the word "Democrat", "Republican", or any explicit party name does NOT appear in race titles or candidate cards. Election type is shown generically as "Primary Election" or similar — never "Democratic Primary" / "Republican Primary".
result: issue
reported: "Race headers throughout the results show explicit party labels: 'ASSESSOR — DEMOCRATIC PRIMARY', 'ASSESSOR — REPUBLICAN PRIMARY', 'AUDITOR — DEMOCRATIC PRIMARY', etc. Every race in the Local, State, and Federal tiers includes 'DEMOCRATIC PRIMARY' or 'REPUBLICAN PRIMARY' in its title. This directly contradicts the antipartisan requirement that primary_party never be rendered."
severity: major

### 7. UT 2026 Primary data — races and candidates visible
expected: For the SLC address, the UT 2026 Primary election (Jun 23, 2026) is shown with many races across tiers. Spot-check candidates: Ben McAdams, Sim Gill, Jiro Johnson, or Jen Dailey-Provost should appear in the results. Total visible races should be well above 3.
result: pass

### 8. Mobile: responsive at 375px
expected: At 375px viewport width (mobile), the elections page shows no horizontal scroll. Election cards stack vertically. The election date pill/label ("19 days away" or similar) is visible. No content is cut off.
result: pass

### 9. Empty state — unrecognized address
expected: Enter a garbage address like "zzzz 99999" into the elections address form. An empty state message appears (e.g., "No elections found" or similar) — not an error message, not a crash, not a spinner stuck indefinitely.
result: pass

## Summary

total: 9
passed: 7
issues: 1
pending: 0
skipped: 1
blocked: 0

## Gaps

- truth: "Race headers display election type without party labels — 'Primary Election' or position name only"
  status: failed
  reason: "User reported: Race headers throughout Local/State/Federal tiers show explicit party names: 'ASSESSOR — DEMOCRATIC PRIMARY', 'ASSESSOR — REPUBLICAN PRIMARY', etc. Every race concatenates position_name + primary_party + 'PRIMARY'. The antipartisan requirement states primary_party must never be rendered."
  severity: major
  test: 6
  root_cause: "ElectionsView (in Transparent Motivations/essentials/src/components/ElectionsView.jsx or equivalent) builds race header as '{position_name} — {primary_party} PRIMARY'. The primary_party field from the API is being used in the race title display, directly violating the antipartisan design requirement documented in Phase 99 plan 02."
  artifacts:
    - path: "Transparent Motivations/essentials/src/components/ElectionsView.jsx"
      issue: "Race header renders primary_party field explicitly"
  missing:
    - "Strip primary_party from race headers — show position_name only (e.g. 'ASSESSOR') or group races by position and show party as a secondary/filter-only attribute"
  debug_session: ""

- truth: "Landing at /elections with stored address auto-fetches elections without requiring re-submission"
  status: failed
  reason: "Observed: navigating to /elections redirects to /results?prefilled=true&view=elections with no q= param. activeQuery derives only from URL q=, so the elections fetch is skipped (gated on if (!activeQuery) return). Address bar pre-populates from localStorage visually but does not trigger a fetch. User must re-type and re-submit their address to see elections."
  severity: minor
  test: 5
  root_cause: "Results.jsx:434 sets activeQuery = searchParams.get('q') || ''. The /elections redirect in App.jsx does not include q=. The elections useEffect (line 746) short-circuits on empty activeQuery. Pre-populated addressInput state is not wired to trigger the elections fetch on view=elections landing."
  artifacts:
    - path: "Transparent Motivations/essentials/src/pages/Results.jsx"
      issue: "Elections fetch gated on URL q= param only; addressInput not used"
    - path: "Transparent Motivations/essentials/src/App.jsx"
      issue: "/elections redirect missing q= param for pre-populated address"
  missing:
    - "On view=elections landing with prefilled=true, auto-submit stored address as q= param (or trigger elections fetch directly from stored addressInput)"
  debug_session: ""
