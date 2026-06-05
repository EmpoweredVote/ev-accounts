---
phase: quick
plan: 002
type: execute
wave: 1
depends_on: []
files_modified:
  - backend/src/routes/connect.ts
  - docs/FRAMER-LOCATION-TRUST-FLOW.md
autonomous: true

must_haves:
  truths:
    - "POST /connect/set-location response distinguishes first-time location from update"
    - "Framer team has a clear contract doc for the trust-first location flow and Connected celebration"
    - "GET /api/account/me already exposes location_consent (true/false) so Framer can distinguish 'has set location' from 'has not'"
  artifacts:
    - path: "backend/src/routes/connect.ts"
      provides: "first_location flag in set-location response"
      contains: "first_location"
    - path: "docs/FRAMER-LOCATION-TRUST-FLOW.md"
      provides: "Complete UX flow contract for Framer frontend"
      contains: "Connected Celebration"
  key_links:
    - from: "POST /connect/set-location"
      to: "connect.connected_profiles.location_consent"
      via: "location_consent checked before upsert to determine first_location"
      pattern: "first_location"
---

<objective>
Add backend signals and Framer contract documentation to support a trust-first location input flow with Connected celebration UX.

Purpose: The current location input feels transactional. The Framer frontend needs clear backend signals to know when a user is setting their location for the first time (celebration moment) vs. updating it (they moved). The backend also needs a documented contract so the Framer team can build the thoughtful UX flow the user envisions: Connected celebration after first location, pseudonym creation prompt, and a separate update path for movers.

Output: Enhanced set-location response with first_location flag + comprehensive Framer integration doc.
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@backend/src/routes/connect.ts
@backend/src/routes/account.ts
@supabase/migrations/20260310000032_location_rpcs.sql
@supabase/migrations/20260310000031_location_schema.sql
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add first_location flag to POST /connect/set-location response</name>
  <files>backend/src/routes/connect.ts</files>
  <action>
In the POST /connect/set-location handler (line ~511), BEFORE calling the upsert_user_location RPC, check the user's current location_consent value to determine if this is their first time setting location.

Add this check after the coverage validation and before the upsert RPC call:

1. Import `getLocationConsent` from `../lib/connectService.js` (already imported at top of file — confirm it's there).
2. Before calling `adminRpc('upsert_user_location', ...)`, call `getLocationConsent(userId)` to get the current value. Store as `const hadPriorLocation = await getLocationConsent(userId);`
3. After the successful upsert and jurisdiction resolution, add `first_location: !hadPriorLocation` to the response JSON alongside the existing `location_consent: true` and `jurisdiction: {...}` fields.

The response shape changes from:
```json
{ "location_consent": true, "jurisdiction": {...} }
```
to:
```json
{ "location_consent": true, "first_location": true, "jurisdiction": {...} }
```

Where `first_location` is `true` on the very first set-location call (location_consent was false before) and `false` on subsequent calls (user is updating/moving).

Do NOT change the upsert_user_location RPC or any SQL. This is purely a route-level read-before-write pattern using the existing getLocationConsent helper.
  </action>
  <verify>
Run `npx tsc --noEmit` from the backend directory to confirm no type errors. Manually trace the logic: getLocationConsent reads location_consent from connected_profiles, returns boolean. If false before upsert, first_location=true. If true before upsert, first_location=false. Correct.
  </verify>
  <done>POST /connect/set-location returns first_location boolean in response. First-time callers get true, subsequent callers get false.</done>
</task>

<task type="auto">
  <name>Task 2: Write Framer location trust flow contract doc</name>
  <files>docs/FRAMER-LOCATION-TRUST-FLOW.md</files>
  <action>
Create a comprehensive contract document for the Framer frontend team that covers the entire trust-first location flow. This is a UX-informed API contract — not just endpoint docs, but the intended emotional arc and flow states.

Structure the document as follows:

**1. Philosophy section** — Why location is a trust expenditure. The user is giving you their home address. Treat it with gravity. No casual "Input Location" fields. Frame it as: "Help us find your representatives" or "So we can connect you to your community."

**2. The Connected Celebration Flow** — Document the full sequence:
  a. User completes connect flow (POST /connect/complete) — they now have Real Name + Referral Code verified.
     Response: `{ connected: true, verification_status: 'verified', tier: 'connected' }`
     At this point, `GET /api/account/me` returns `tier: 'connected'`, `location_consent: false`.
  b. Framer shows celebration: "You're Connected!" — acknowledging the trust they've invested (real name, invite code).
  c. Next prompt: "Help us connect you to your community" — explain WHY location matters (finding their representatives, their civic spaces). This is NOT a form field. This is a moment.
  d. User enters address → POST /connect/set-location with `{ address: "..." }`.
     Response includes `first_location: true` — Framer triggers celebration animation/confetti/moment.
     Response also includes `jurisdiction` object with all their districts.
  e. After location celebration, prompt pseudonym creation: "Choose how you'll be known in your community."
     Pseudonym = display_name. Update via PATCH /api/account/me with `{ display_name: "..." }`.
     Note: display_name was already set during connect flow as a draft, but this is the moment to let them refine it as their public identity.

**3. The "I Moved" Update Flow** — Separate from initial flow:
  a. User goes to profile/settings section.
  b. `GET /api/account/me` shows `location_consent: true` (already has location).
  c. User clicks "Update Location" (NOT "Input Location" — they already have one).
  d. POST /connect/set-location with new address.
     Response includes `first_location: false` — Framer shows confirmation, NOT celebration.
     New jurisdiction data returned.

**4. API Reference Table** — Quick reference of all endpoints involved:
  - GET /api/account/me — tier, location_consent, completed_onboarding, display_name
  - POST /connect/start — begin connect flow (invite code)
  - PATCH /connect/step — update profile drafts (display_name, legal_name, location text, home_address)
  - POST /connect/complete — finalize Connected tier
  - POST /connect/set-location — set/update precise location (geocoded, encrypted)
  - PATCH /api/account/me — update display_name (pseudonym), avatar_url
  - GET /api/account/me/jurisdiction — retrieve resolved districts

**5. Key Signals for Framer** — Enumerated decision points:
  - `tier === 'inform'` → not yet Connected, show connect flow
  - `tier === 'connected' && location_consent === false` → Connected but no location, show trust-first location prompt
  - `tier === 'connected' && location_consent === true` → full Connected, show normal profile
  - `first_location === true` in set-location response → celebrate!
  - `first_location === false` in set-location response → confirm update, no celebration

**6. Error UX Guidance** — How to handle error codes gracefully:
  - ADDRESS_NOT_FOUND: "We couldn't find that address. Try including your city and state."
  - PO_BOX_REJECTED: "We need a residential address to find your representatives. PO Boxes can't be mapped to districts."
  - OUT_OF_COVERAGE: "We're not in your area yet, but we're expanding soon. We'll let you know when we arrive."

**7. Privacy Reassurance Copy Suggestions** — Not prescriptive, but suggested language:
  - "Your address is encrypted and never shared. We only use it to identify your voting districts."
  - "You can update your location anytime if you move."
  </action>
  <verify>
Read the completed document and confirm: (1) all endpoints referenced are real and match the codebase, (2) response shapes match actual backend responses, (3) the first_location flag from Task 1 is documented, (4) both first-time and update flows are covered, (5) error codes match GeocodingError codes in geocodingService.ts.
  </verify>
  <done>docs/FRAMER-LOCATION-TRUST-FLOW.md exists with complete flow contract covering celebration triggers, pseudonym creation, update flow, API reference, signal enumeration, and error UX guidance.</done>
</task>

</tasks>

<verification>
1. `cd backend && npx tsc --noEmit` — no type errors
2. POST /connect/set-location response shape now includes `first_location: boolean`
3. docs/FRAMER-LOCATION-TRUST-FLOW.md exists and references correct endpoints
4. No existing tests broken (run `npm test` from backend dir)
</verification>

<success_criteria>
- POST /connect/set-location returns first_location=true on first call, false on subsequent
- Framer team has a single document covering the entire trust-first location flow
- No breaking changes to existing response contracts (first_location is additive)
- All referenced endpoints in the doc match real backend routes
</success_criteria>

<output>
After completion, create `.planning/quick/002-location-trust-flow-connected-celebrate/002-SUMMARY.md`
</output>
