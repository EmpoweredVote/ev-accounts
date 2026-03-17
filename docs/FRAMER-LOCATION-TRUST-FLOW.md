# Framer Location Trust Flow — API Contract

Location input is a trust expenditure. The user is giving you their home address. The flow must treat that moment with gravity — not with a casual "Input Location" text field.

This document covers the full sequence from Connected celebration through first location set, pseudonym refinement, and the separate "I moved" update path. It is the canonical contract between the Accounts backend and the Framer frontend.

---

## 1. Philosophy

When a user reaches the Connected flow, they have already made two significant trust investments:

1. They vouched with a real name (legal identity on record)
2. They used a real invite code (a human being trusted them enough to invite them)

Location is the third trust moment. They are telling the platform where they live so it can connect them to their actual representatives and civic community. This is not a form field. This is a civic commitment.

**Framing that honors the moment:**
- "Help us find your representatives" — practical, grounded
- "Connect you to your community" — social, identity-affirming
- NOT: "Enter your address" — transactional, cold

**What the platform does with the address:**
- Geocodes to lat/lng coordinates
- Resolves to voting districts (congressional, state senate, state house, county, school district)
- Encrypts the raw address — it is never stored in plaintext and never shared
- Used only to identify civic spaces and representatives

---

## 2. The Connected Celebration Flow

This is the primary flow — first-time users progressing from Inform tier through Connected tier and setting their location.

### Step A: Connect flow completion

The user finishes the connect enrollment (invite code validated, profile filled out).

**Request:**
```
POST /api/connect/complete
Authorization: Bearer {access_token}
```

**Response (201):**
```json
{
  "connected": true,
  "verification_status": "verified",
  "tier": "connected"
}
```

**After this call, `GET /api/account/me` returns:**
```json
{
  "tier": "connected",
  "location_consent": false,
  "completed_onboarding": false,
  ...
}
```

`location_consent: false` is the definitive signal that this user has not yet set their location.

### Step B: Connected celebration

Show the Connected celebration screen. This acknowledges what the user has done — they trusted the platform with their identity and a human trusted them enough to invite them.

**Suggested copy tone:** "You're Connected. You've taken the first step toward civic participation that actually matters."

This is a moment to land before asking for anything more.

### Step C: Trust-first location prompt

After celebration, present the location step as a natural next beat — not an afterthought.

**Do not show a raw address input field immediately.** Lead with context:

> "To connect you to your representatives and your civic community, we need to know where you live."

Then reveal the input. This ordering signals that location serves the user — not the platform.

### Step D: User enters address

**Request:**
```
POST /api/connect/set-location
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "address": "123 Main St, Indianapolis, IN 46201"
}
```

**Response (200) — first time:**
```json
{
  "location_consent": true,
  "first_location": true,
  "jurisdiction": {
    "congressional_district": "IN-07",
    "congressional_district_name": "Indiana's 7th Congressional District",
    "state_senate_district": "IN-SD-30",
    "state_senate_district_name": "Indiana Senate District 30",
    "state_house_district": "IN-HD-97",
    "state_house_district_name": "Indiana House District 97",
    "county": "Marion County",
    "county_name": "Marion County",
    "school_district": "IPS",
    "school_district_name": "Indianapolis Public Schools"
  }
}
```

**`first_location: true` is the celebration trigger.** When Framer sees this flag:
- Trigger the location celebration animation (confetti, moment, affirmation)
- Display their jurisdiction summary: "You're in [Congressional District Name], represented by..."
- This is distinct from the Connected celebration — it's the civic grounding moment

After celebration, proceed to Step E.

### Step E: Pseudonym creation prompt

After location is set, prompt the user to finalize their public identity.

The `display_name` was set as a draft during the connect flow, but this is the intentional moment to let them own it as their civic pseudonym — the name their community will know them by.

**Context to present:**
> "Choose how you'll be known in your community. This is the name other members will see — not your legal name."

**Request:**
```
PATCH /api/account/me
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "display_name": "Maria V."
}
```

**Response (200):** Updated user object (same shape as GET /api/account/me).

After pseudonym confirmation, mark onboarding complete:

**Request:**
```
POST /api/auth/complete-onboarding
Authorization: Bearer {access_token}
```

This sets `completed_onboarding: true` on the connected profile. Future calls to `GET /api/account/me` will return `completed_onboarding: true`, signaling that the full flow is done.

---

## 3. The "I Moved" Update Flow

This is the update path for users who have already set their location and need to change it.

This flow is accessed from profile/settings — NOT from the onboarding sequence.

### Detection

When Framer loads the profile/settings screen:

```
GET /api/account/me
```

If `location_consent: true` → user already has a location set. Show "Update Location" option (not "Set Location").

### Update request

Same endpoint as the initial set — the backend handles upsert:

**Request:**
```
POST /api/connect/set-location
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "address": "456 Oak Ave, Indianapolis, IN 46202"
}
```

**Response (200) — update:**
```json
{
  "location_consent": true,
  "first_location": false,
  "jurisdiction": { ... }
}
```

**`first_location: false` signals this is an update.** Framer shows:
- A confirmation: "Location updated. Your community connections have been refreshed."
- The new jurisdiction summary
- NO celebration animation — that moment has already happened

---

## 4. API Reference

All routes require `Authorization: Bearer {access_token}` header.

| Method | Path | Auth Required | Purpose |
|--------|------|---------------|---------|
| `GET` | `/api/account/me` | Auth | Current user profile, tier, location_consent, onboarding status |
| `PATCH` | `/api/account/me` | Auth + Connected | Update display_name, avatar_url |
| `GET` | `/api/account/me/jurisdiction` | Auth + Connected | Retrieve resolved districts (requires location_consent: true) |
| `POST` | `/api/connect/start` | Auth | Begin connect flow (provide invite code) |
| `PATCH` | `/api/connect/step` | Auth | Update profile drafts (display_name, legal_name, home_address) |
| `POST` | `/api/connect/complete` | Auth | Finalize Connected tier |
| `POST` | `/api/connect/set-location` | Auth + Connected | Set or update precise location |
| `POST` | `/api/auth/complete-onboarding` | Auth + Connected | Mark onboarding complete |

### GET /api/account/me — response shape

```json
{
  "id": "uuid",
  "email": "user@example.com",
  "display_name": "Maria V.",
  "avatar_url": null,
  "tier": "connected",
  "is_admin": false,
  "completed_onboarding": false,
  "location_consent": false,
  "verification_rating": 60,
  "vq_hold_active": false,
  "red_gem_quests_unlocked": false,
  "account_standing": "active",
  "created_at": "...",
  "updated_at": "...",
  "connected_profile": {
    "display_name": "Maria V.",
    "verification_status": "verified",
    "tolerance_rating": 50,
    "xp": { "total": 0, "level": 0, "xp_in_level": 0, "xp_to_next_level": 100 },
    "gems": { "yellow": 0, "blue": 0, "red": 0 },
    "completed_onboarding": false,
    "verification_rating": 60,
    "vq_hold_active": false,
    "vq_hold_until": null,
    "created_at": "..."
  }
}
```

`connected_profile` is only present when `tier` is `"connected"` or `"empowered"`.

### POST /api/connect/set-location — response shape

```json
{
  "location_consent": true,
  "first_location": true,
  "jurisdiction": {
    "congressional_district": "IN-07",
    "congressional_district_name": "Indiana's 7th Congressional District",
    "state_senate_district": "IN-SD-30",
    "state_senate_district_name": "Indiana Senate District 30",
    "state_house_district": "IN-HD-97",
    "state_house_district_name": "Indiana House District 97",
    "county": "Marion County",
    "county_name": "Marion County",
    "school_district": "IPS",
    "school_district_name": "Indianapolis Public Schools"
  }
}
```

Any jurisdiction field may be `null` if the address falls outside a mapped district boundary.

---

## 5. Key Signals for Framer

Enumerated decision points — check these in order:

| Signal | Meaning | Action |
|--------|---------|--------|
| `tier === 'inform'` | Not yet Connected | Show connect flow entry point |
| `tier === 'connected' && location_consent === false` | Connected, no location set | Show trust-first location prompt (section 2) |
| `tier === 'connected' && location_consent === true && completed_onboarding === false` | Connected, has location, onboarding not finished | Resume or skip to pseudonym step |
| `tier === 'connected' && completed_onboarding === true` | Fully onboarded Connected user | Normal profile / home screen |
| `first_location === true` in set-location response | User just set location for the first time | Trigger location celebration + jurisdiction display |
| `first_location === false` in set-location response | User updated an existing location | Show confirmation only, no celebration |

---

## 6. Error UX Guidance

All errors from `POST /api/connect/set-location` are 422 with a `code` field.

| Error Code | User-Facing Message |
|------------|---------------------|
| `ADDRESS_NOT_FOUND` | "We couldn't find that address. Try including your city and state, or use a more specific street address." |
| `PO_BOX_REJECTED` | "We need a residential street address to find your representatives. PO Boxes can't be mapped to districts." |
| `OUT_OF_COVERAGE` | "We're not in your area yet, but we're expanding. We'll let you know when we arrive." |
| `VALIDATION_ERROR` | "Please enter a complete address." |
| `INTERNAL_ERROR` | "Something went wrong on our end. Please try again in a moment." |

**UX pattern for errors:** Keep the user on the location input screen. Show the error inline below the input field. Do not navigate away or reset the flow state.

---

## 7. Privacy Reassurance Copy Suggestions

These are suggestions — not prescriptive. The Framer team should adapt tone to match the overall voice.

**Before the input:**
> "Your address is encrypted and never shared. We use it only to identify your voting districts and civic community."

**After successful set (update flow):**
> "You can update your location anytime if you move."

**On the pseudonym step:**
> "This is how your community will know you — not your legal name. You can update it later from your profile."

**On why districts matter:**
> "Your congressional representative votes on federal legislation that affects your life. Your state legislators shape local law. Knowing who they are is step one."
