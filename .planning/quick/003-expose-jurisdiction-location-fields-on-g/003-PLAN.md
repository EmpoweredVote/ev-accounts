---
phase: quick
plan: 003
type: execute
wave: 1
depends_on: []
files_modified:
  - backend/src/routes/account.ts
  - tests/integration/account.test.ts
  - docs/ONBOARDING-VQ.md
autonomous: true

must_haves:
  truths:
    - "GET /api/account/me returns jurisdiction object with district names when location_consent is true"
    - "GET /api/account/me returns jurisdiction: null when location_consent is false or user is Inform tier"
    - "PATCH /api/account/me response also includes jurisdiction (same shape as GET)"
    - "ONBOARDING-VQ.md documents the new jurisdiction field on /me"
  artifacts:
    - path: "backend/src/routes/account.ts"
      provides: "jurisdiction field on /me response"
      contains: "resolve_user_jurisdiction"
    - path: "tests/integration/account.test.ts"
      provides: "jurisdiction in ALLOWED_ME_KEYS whitelist"
      contains: "jurisdiction"
    - path: "docs/ONBOARDING-VQ.md"
      provides: "Updated /me response shape documenting jurisdiction"
      contains: "jurisdiction"
  key_links:
    - from: "backend/src/routes/account.ts (GET /me)"
      to: "connect.resolve_user_jurisdiction RPC"
      via: "adminRpc call when location_consent is true"
      pattern: "adminRpc.*resolve_user_jurisdiction"
---

<objective>
Expose jurisdiction/location district fields directly on GET /api/account/me so Validation Quests (and other consumers) can read a Connected user's district data without making a separate call to /me/jurisdiction.

Purpose: VQ needs district data (school_district, county, state_senate, state_house, congressional) to scope quests by jurisdiction. Currently this requires a separate authenticated call to /me/jurisdiction. Embedding it in /me eliminates the extra round-trip and simplifies VQ's client code.

Output: Updated account.ts with jurisdiction on /me, updated test whitelist, updated ONBOARDING-VQ.md.
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@backend/src/routes/account.ts
@tests/integration/account.test.ts
@docs/ONBOARDING-VQ.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add jurisdiction to GET /me and PATCH /me responses</name>
  <files>backend/src/routes/account.ts</files>
  <action>
In both GET /me and PATCH /me handlers, after determining the connected profile exists and location_consent is true, call `resolve_user_jurisdiction` via `adminRpc` (same pattern already used in the GET /me/jurisdiction endpoint at line 208) and include the result as a `jurisdiction` object on the response.

Specifically:

1. In GET /me handler (after line 102, before building meResponse):
   - If `connected?.location_consent` is truthy, call `adminRpc('resolve_user_jurisdiction', { p_user_id: authReq.userId }, 'connect')`
   - Parse the result into a jurisdiction object with keys: `congressional_district`, `congressional_district_name`, `state_senate_district`, `state_senate_district_name`, `state_house_district`, `state_house_district_name`, `county`, `county_name`, `school_district`, `school_district_name` (same shape as /me/jurisdiction endpoint, lines 220-232)
   - If location_consent is false or user is Inform tier, set jurisdiction to null
   - Add `jurisdiction` to the meResponse object (at root level, NOT inside connected_profile)

2. In PATCH /me handler (same pattern — after re-fetching connected profile):
   - Same logic: if `updatedConnected?.location_consent` is truthy, call the RPC
   - Add jurisdiction to the PATCH meResponse

Important: Do NOT remove the existing /me/jurisdiction endpoint — it remains available. This is additive.

The jurisdiction field should be `null` (not omitted) when location_consent is false or user is Inform tier — this gives VQ a clear signal vs. undefined.

Handle RPC errors gracefully: if resolve_user_jurisdiction fails, log the error and set jurisdiction to null (do not fail the entire /me request over a jurisdiction lookup failure).
  </action>
  <verify>
    - `npx tsc --noEmit` passes
    - Review the diff to confirm jurisdiction is added to both GET and PATCH response builders
    - Confirm /me/jurisdiction endpoint is untouched
  </verify>
  <done>
    - GET /me returns `jurisdiction: { congressional_district, congressional_district_name, state_senate_district, state_senate_district_name, state_house_district, state_house_district_name, county, county_name, school_district, school_district_name }` when location_consent is true
    - GET /me returns `jurisdiction: null` when location_consent is false or user is Inform tier
    - PATCH /me mirrors the same behavior
    - RPC failure does not crash /me — returns jurisdiction: null with console.error
  </done>
</task>

<task type="auto">
  <name>Task 2: Update test whitelist and docs</name>
  <files>tests/integration/account.test.ts, docs/ONBOARDING-VQ.md</files>
  <action>
1. In tests/integration/account.test.ts:
   - Add `'jurisdiction'` to the `ALLOWED_ME_KEYS` Set (line 26-45). This is the privacy contract whitelist — without this addition, the whitelist test would flag jurisdiction as a data leak.

2. In docs/ONBOARDING-VQ.md:
   - In the "Reading User State" section (around line 349), update the response shape TypeScript block to include the new `jurisdiction` field:
     ```
     // -- Jurisdiction (null if location_consent is false) --
     jurisdiction: {
       congressional_district: string | null;
       congressional_district_name: string | null;
       state_senate_district: string | null;
       state_senate_district_name: string | null;
       state_house_district: string | null;
       state_house_district_name: string | null;
       county: string | null;
       county_name: string | null;
       school_district: string | null;
       school_district_name: string | null;
     } | null;
     ```
   - In the "Jurisdiction (District Eligibility)" section (around line 432), add a note that jurisdiction is now also available directly on GET /me (no separate call needed), and that the /me/jurisdiction endpoint remains available for backward compatibility.
   - Update the VQ participation gating example to show how to use jurisdiction from /me:
     ```typescript
     // District-scoped quests
     if (meData.jurisdiction) {
       const userDistrict = meData.jurisdiction.congressional_district_name;
       // Filter quests by district...
     } else {
       // location_consent is false — prompt user to set location
     }
     ```
  </action>
  <verify>
    - `npx vitest run tests/integration/account.test.ts` passes
    - Review ONBOARDING-VQ.md diff confirms jurisdiction is documented in both the response shape and the jurisdiction section
  </verify>
  <done>
    - ALLOWED_ME_KEYS includes 'jurisdiction'
    - All existing tests pass
    - ONBOARDING-VQ.md documents jurisdiction on /me with TypeScript type, usage example, and note about /me/jurisdiction backward compat
  </done>
</task>

</tasks>

<verification>
- `npx tsc --noEmit` — no type errors
- `npx vitest run tests/integration/account.test.ts` — all tests pass including whitelist check
- Manual review: jurisdiction field present in both GET and PATCH /me response builders
- /me/jurisdiction endpoint unchanged (still works independently)
</verification>

<success_criteria>
- GET /api/account/me includes jurisdiction object (or null) at root level
- PATCH /api/account/me mirrors the same jurisdiction field
- Test whitelist updated — no false positive privacy violations
- ONBOARDING-VQ.md updated so VQ developers know to use /me directly for district data
- Zero breaking changes to existing response shape
</success_criteria>

<output>
After completion, create `.planning/quick/003-expose-jurisdiction-location-fields-on-g/003-SUMMARY.md`
</output>
