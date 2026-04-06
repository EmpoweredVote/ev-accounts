---
status: testing
phase: 58-contributor-portal
source: 58-01-SUMMARY.md, 58-02-SUMMARY.md, 58-03-SUMMARY.md, 58-04-SUMMARY.md
started: 2026-04-05T00:00:00Z
updated: 2026-04-05T00:00:00Z
---

## Current Test

number: 6
name: Compass Editor: Politician List with Scope Badge
expected: |
  The Compass Editor page loads a list of politicians scoped to the user's jurisdiction. A scope
  badge is visible in the header (e.g. "Showing: [geoid]"). If loading, a spinner shows.
awaiting: user response

## Tests

### 1. Contributor Tab Always Visible
expected: On the Profile Hub (DashboardPage), a "Contributor" tab is visible in the tab bar alongside the "Profile" tab — for ALL logged-in users, regardless of whether they have any active role grants.
result: pass

### 2. Locked State for Users Without Grants
expected: Clicking the Contributor tab when you have no active grants shows an aspirational locked state — NOT a cold "you have no roles" message. It should describe what each contributor role does (Compass Editors, Essentials Editors, Candidate Coordinators) and include a contact link to request access.
result: pass

### 3. Active Grant Cards
expected: A user with active role grants sees one card per grant on the Contributor dashboard. Each card shows: the role display name ("Compass Editor", "Candidate Coordinator", or "Essentials Editor"), the scope (e.g. jurisdiction geoid, "Single Politician", or "Unrestricted"), the grant date, who granted it, and a CTA button to open the editor.
result: pass

### 4. Editor Navigation from Grant Card
expected: Clicking a grant card's CTA navigates to the correct editor page — /contributor/compass-editor for Compass Editor, /contributor/campaign-manager for Candidate Coordinator, /contributor/essentials-editor for Essentials Editor.
result: pass

### 5. Back Navigation from Editors
expected: All three editor pages have a back button/link in the header. Clicking it returns to the Contributor dashboard (not the browser history stack — a specific "Back to Profile" nav link in ContributorLayout).
result: pass

### 6. Compass Editor: Politician List with Scope Badge
expected: The Compass Editor page loads a list of politicians scoped to the user's jurisdiction. A scope badge is visible in the header (e.g. "Showing: [geoid]"). If loading, a spinner shows.
result: issue
reported: "Scoped grant (jurisdiction_geoid=06037) returned zero politicians"
severity: blocker

### 7. Compass Editor: Stance Editing and Save
expected: Clicking a politician in the Compass Editor loads all live compass topics with the politician's current stances shown as selected buttons (values 1–5). Clicking a different value marks it selected. The Save button is disabled until at least one stance is changed. Clicking Save submits only the changed stances and shows a success toast.
result: [pending]

### 8. Candidate Coordinator: Single Politician and Stance Editor
expected: The Candidate Coordinator (campaign_manager) page shows a single politician as a list card. The scope badge in the header shows the politician's name and office title. Clicking the politician opens the identical stance editor. Header always reads "Candidate Coordinator" — never "Campaign Manager".
result: [pending]

### 9. Essentials Editor: Politician Grid
expected: The Essentials Editor loads a grid of politicians scoped to the editor's jurisdiction, showing photo (or placeholder), full name, and office title. A jurisdiction scope badge is visible in the header.
result: [pending]

### 10. Essentials Editor: Field Editor and Partial Save
expected: Clicking a politician in the Essentials Editor opens an inline field editor with three fields: Bio (textarea), Preferred Name (input), and Photo URL (input). Leaving a field empty and saving does NOT blank the existing value — only non-empty fields are sent. A success toast appears on save.
result: [pending]

## Summary

total: 10
passed: 5
issues: 1
pending: 4
skipped: 0

## Gaps

- truth: "Scoped compass_stance_editor grant (with jurisdiction_geoid) returns politicians in that jurisdiction"
  status: failed
  reason: "User reported: zero politicians shown with jurisdiction_geoid=06037 scoped grant"
  severity: blocker
  test: 6
  root_cause: "essentials.politicians.home_jurisdiction_geoid is NULL on all 2577 rows — never populated. Additionally, district geo_ids (7-digit city codes e.g. 0643000) don't match user county_geo_id format (5-digit FIPS e.g. 06037). Scoped query WHERE p.home_jurisdiction_geoid = $1 always returns 0 rows."
  artifacts:
    - path: "backend/src/lib/stanceService.ts"
      issue: "getContributorPoliticians scoped branch filters on home_jurisdiction_geoid which is always NULL"
  missing:
    - "Populate home_jurisdiction_geoid on essentials.politicians from offices→districts join"
    - "Resolve geo_id format mismatch between district codes and user county_geo_id"

- truth: "Compass Editor allows contributors to add a source URL alongside each stance they record"
  status: failed
  reason: "User reported: expected a source URL field per stance so contributors can link evidence for a politician's position"
  severity: major
  test: 4-note
  root_cause: ""
  artifacts: []
  missing:
    - "Source URL input per stance in CompassEditorPage and CampaignManagerPage"
    - "inform.politician_context table already has sources text[] — need write endpoint and UI"
