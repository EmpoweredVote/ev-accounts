# Compass API Contract

External-facing API contract for CompassV2 integration with the Empowered Vote accounts API.
This document covers all endpoints CompassV2 needs to integrate: authentication, account profile shape,
compass read/write, guest state migration on signup, and all error codes. It is authoritative —
implement against this document without needing to read server source code.

---

## 1. Base URL

```
Production: https://accounts.empowered.vote/api
```

All paths in this document are relative to that base URL. Example: `POST /auth/login` means
`POST https://accounts.empowered.vote/api/auth/login`.

---

## 2. Authentication

**Method:** Bearer token (JWT issued by Supabase Auth)

```
Authorization: Bearer <access_token>
```

**How to get a token:** `POST /auth/login` returns `access_token`. Send it as a Bearer token header
on all subsequent requests.

**Token lifetime:** Supabase JWTs expire in approximately 1 hour. When a token expires, repeat the
login call to get a new one. (Token refresh via refresh_token is not yet exposed through this API —
use email/password re-auth for now.)

**Anonymous access:** Most compass endpoints work without a token. Unauthenticated calls receive
empty data (empty arrays, empty objects, or null), not 401 errors. See each endpoint below.

**Endpoints that require a token (return 401 without one):**

- `DELETE /compass/answers/me`
- `GET /compass/progress`
- `POST /auth/complete-onboarding`
- All `/account/*` endpoints
- All `/admin/*` endpoints

---

## 3. Account Endpoints

### GET /account/me

Returns the authenticated user's full profile.

**Auth required:** Yes

**Response (200):**

```json
{
  "id": "uuid",
  "email": "user@example.com",
  "display_name": "string | null",
  "avatar_url": "string | null",
  "tier": "inform | connected | empowered",
  "completed_onboarding": false,
  "account_standing": "active | suspended",
  "created_at": "2026-01-15T10:00:00Z",
  "updated_at": "2026-01-15T10:00:00Z",
  "connected_profile": {
    "display_name": "string | null",
    "verification_status": "string",
    "tolerance_rating": 5.0,
    "xp": {
      "total": 250,
      "level": 3,
      "xp_in_level": 50,
      "xp_to_next_level": 150
    },
    "gem_balance": 10,
    "completed_onboarding": false,
    "created_at": "2026-01-15T10:00:00Z"
  },
  "empowered_profile": null
}
```

**Field notes:**

- `completed_onboarding` appears at ROOT for all tiers. Inform-tier users (no connected_profile) always
  receive `false` here.
- `connected_profile` is omitted (not null, not present) for inform-tier users.
- `empowered_profile` is omitted for non-empowered users. When present, contains `is_active`,
  `candidate_page_slug`, `empowered_at`, `demoted_at`.
- `xp` is a structured object — NOT a raw integer. Read `xp.total` for total XP, `xp.level` for
  the computed level. The `xp` object is only present inside `connected_profile`, never at root.
- `account_standing` at root reflects the connected_profile value. Inform-tier users always receive
  `"active"`.
- `empowerment_status` (string: `"empowered"` or `"demoted"`) is included at root only when an
  `empowered_profile` record exists — indicating whether the user holds active Empowered status or
  was previously demoted. Absent for inform and connected users.

**Error (401):** `{ "code": "AUTH_ERROR" }` — invalid or expired token.

---

### PATCH /account/me

Updates the authenticated user's profile. Connected-tier and above only.

**Auth required:** Yes (Connected tier or above)

**Request:**

```json
{
  "display_name": "Jane Smith",
  "avatar_url": "https://example.com/avatar.jpg"
}
```

Both fields are optional. At least one must be present.

**Response (200):** Same shape as GET /account/me.

**Error (403):** `{ "code": "NOT_CONNECTED" }` — user is inform-tier (Connect enrollment not complete).

---

### GET /admin/me

Returns the authenticated admin user's identity. Used to verify admin JWT validity.

**Auth required:** Yes (admin JWT)

**Response (200):**

```json
{
  "isAdmin": true,
  "id": "uuid",
  "email": "admin@example.com"
}
```

**Error (403):** Not an admin account.

---

## 4. Auth Endpoints

### POST /auth/login

Authenticates with email and password. Returns tokens and a minimal profile stub.

**Note:** The `user` object in the response is always `tier: "inform"` and `account_standing: "active"` —
this is a stub, not a full profile. After login, call `GET /account/me` to get the user's real tier
and standing.

**Auth required:** No

**Request:**

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (200):**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 3600,
  "expires_at": 1773151865,
  "token_type": "bearer",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "display_name": null,
    "tier": "inform",
    "account_standing": "active"
  }
}
```

**Error (401):** `{ "code": "INVALID_CREDENTIALS" }` — wrong email or password. The server does not
distinguish between them (OWASP enumeration protection).

**Error (403):** `{ "code": "EMAIL_NOT_VERIFIED" }` — account exists but email confirmation is
pending.

**Rate limit:** 10 requests per 15-minute window per IP. Exceeding returns 429 RATE_LIMIT_EXCEEDED.

---

### POST /auth/signup

Creates a new account. The optional `guest_state` field migrates anonymous compass answers and
selected topics into the new account at the moment of signup — the user does not need to redo their
compass after creating an account.

**Auth required:** No

**Request:**

```json
{
  "email": "user@example.com",
  "password": "minimum8chars",
  "guest_state": {
    "answers": [
      {
        "topic_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "value": 3.5,
        "write_in_text": "Optional write-in explanation"
      }
    ],
    "selected_topics": [
      "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "4eb96a75-6828-5673-c4fd-3d074g77bfb7"
    ]
  }
}
```

`guest_state` is optional. When omitted, signup behaves exactly as before — no migration occurs.

**guest_state.answers[].value:** Must be a 0.5-increment number in the range 0.5–5.5.
Predefined stance values are integers 1–5. Write-in placements use half-integers (0.5, 1.5, 2.5,
3.5, 4.5, 5.5) to express positions between or beyond the predefined stances.

**guest_state.selected_topics:** Array of topic UUIDs. The server validates all IDs exist and are
live before persisting.

**Response (201):**

```json
{
  "id": "uuid",
  "message": "Check your email to confirm your account"
}
```

The response does not include tokens — the account must be email-confirmed before login is
permitted.

**Guest state migration behavior:**

- Migration runs atomically after account creation. Either all answers and selected topics are
  migrated, or none are (partial migration does not occur).
- Migration is best-effort — if it fails for any reason, signup still returns 201 and the account
  is created. The user will need to re-enter their compass answers after confirming their email.
- `selected_topics` migration requires a Connected profile to exist. Selected topics are silently
  skipped if the user is inform-tier at migration time (which is always the case at signup —
  the user has not yet enrolled in Connect). Store `selected_topics` in localStorage and
  submit via `PUT /compass/selected-topics` after the user completes Connect enrollment.

**Error (409):** `{ "code": "EMAIL_EXISTS" }` — account already registered with this email.

**Error (422):** `{ "code": "VALIDATION_ERROR" }` — password too short (minimum 8 characters) or
invalid email format.

**Error (503):** `{ "code": "EMAIL_DELIVERY_FAILED" }` — transient SMTP failure. Retry later.

**Rate limit:** 10 requests per 15-minute window per IP.

---

### POST /auth/complete-onboarding

Marks the user's compass onboarding as complete. Sets `completed_onboarding = true` on the
connected_profiles row. Idempotent — safe to call multiple times.

**Auth required:** Yes (Connected tier)

**Request:** No body required.

**Response (200):**

```json
{ "completed_onboarding": true }
```

**Error (403):** `{ "code": "NOT_CONNECTED" }` — user has not completed Connect enrollment yet.

---

### POST /auth/logout

Invalidates the current session globally across all devices.

**Auth required:** Yes

**Request:** No body required.

**Response (200):**

```json
{ "message": "Logged out successfully" }
```

Always returns 200 — even if the server-side revocation fails, the response is 200. The access
token has a short TTL and will expire naturally.

---

## 5. Compass Endpoints

### GET /compass/topics

Returns all live topics with nested stances. Use this to build the compass question list.

**Auth:** Optional — works unauthenticated.

**Response (200):**

```json
[
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "title": "Minimum Wage",
    "short_title": "Min. Wage",
    "question_text": "Should the federal minimum wage be increased?",
    "stances": [
      { "value": 1, "text": "Strongly Oppose" },
      { "value": 2, "text": "Oppose" },
      { "value": 3, "text": "Neutral" },
      { "value": 4, "text": "Support" },
      { "value": 5, "text": "Strongly Support" }
    ]
  }
]
```

Stances have integer values 1–5. These are the labeled positions. Write-in answers use half-integer
values placed between stances.

---

### GET /compass/categories

Returns all categories with nested live topics (same topic shape as above, without stances).
Use this for the category-filtered compass view.

**Auth:** Optional — works unauthenticated.

**Response (200):**

```json
[
  {
    "id": "uuid",
    "title": "Economy",
    "topics": [
      {
        "id": "uuid",
        "title": "Minimum Wage",
        "short_title": "Min. Wage",
        "question_text": "Should the federal minimum wage be increased?"
      }
    ]
  }
]
```

---

### GET /compass/answers

Returns the authenticated user's compass responses. Returns an empty array for unauthenticated
requests — no 401.

**Auth:** Optional (unauthenticated returns `[]`)

**Response (200):**

```json
[
  {
    "topic_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "value": 3.5,
    "write_in_text": "string | null",
    "visibility": "private | public",
    "inverted": false,
    "created_at": "2026-01-15T10:00:00Z",
    "updated_at": "2026-01-15T10:00:00Z"
  }
]
```

`value` is NUMERIC — it may be an integer (`3`) or a half-integer (`3.5`). Always parse it as a
float, not an integer.

---

### POST /compass/answers

Upserts a single compass response. For unauthenticated users, returns `null` immediately — the
answer is NOT persisted. Store anonymous answers in browser localStorage instead.

**Auth:** Optional (unauthenticated returns `null` — answer not saved)

**Request:**

```json
{
  "topic_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "value": 3.5,
  "write_in_text": "Optional write-in text",
  "inverted": false
}
```

Field constraints:
- `topic_id`: UUID of a live topic (required)
- `value`: 0.5-increment float, range 0.5–5.5 (required). Use integers 1–5 for predefined stances;
  use half-integers for write-in placement between or beyond stances.
- `write_in_text`: string, max 500 characters (optional)
- `inverted`: boolean, default `false` (optional). When `true`, indicates the user's score should be
  treated as inverted relative to the stance direction.

**Response (200):** The upserted response object (same shape as a single item from GET /compass/answers).

**Error (404):** `{ "code": "TOPIC_NOT_FOUND" }` — topic UUID does not exist or topic is not live.

**Error (422):** `{ "code": "VALIDATION_ERROR" }` — value out of range, not a 0.5 increment, or
write_in_text too long.

---

### POST /compass/answers/batch

Returns the user's answers for a specific list of topic IDs. Useful for loading answers for a
subset of topics without fetching all answers.

**Auth:** Optional (unauthenticated returns `[]`)

**Request:**

```json
{
  "ids": [
    "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "4eb96a75-6828-5673-c4fd-3d074g77bfb7"
  ]
}
```

`ids` must be an array of 1–100 UUIDs.

**Response (200):**

```json
[
  {
    "topic_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "value": 3.5,
    "write_in_text": "string | null"
  }
]
```

Only topics the user has answered are included in the response. Missing topic IDs are silently
omitted (not an error).

---

### GET /compass/selected-topics

Returns the user's saved topic selection. Returns `{ topic_ids: [] }` for unauthenticated requests.

**Auth:** Optional (unauthenticated returns `{ "topic_ids": [] }`)

**Response (200):**

```json
{ "topic_ids": ["uuid", "uuid"] }
```

**Error (403):** `{ "code": "NOT_CONNECTED" }` — authenticated user has not completed the Connect
enrollment flow. (Unauthenticated users receive `{ "topic_ids": [] }`, not this error.)

---

### PUT /compass/selected-topics

Saves the user's topic selection. The server validates that all submitted IDs are live topics before
persisting. For unauthenticated users, returns `{ topic_ids: [] }` immediately — selection is NOT
persisted.

**Auth:** Optional (unauthenticated returns `{ "topic_ids": [] }` — selection not saved)

**Request:**

```json
{
  "topic_ids": [
    "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "4eb96a75-6828-5673-c4fd-3d074g77bfb7"
  ]
}
```

`topic_ids` may be an empty array (clears the selection).

**Response (200):**

```json
{ "topic_ids": ["uuid", "uuid"] }
```

**Error (403):** `{ "code": "NOT_CONNECTED" }` — authenticated user has not completed Connect
enrollment. (This is a real error — unlike the GET, authenticated users without a connected_profile
get 403, not an empty list.)

**Error (422):** `{ "code": "INVALID_TOPIC_IDS", "invalid_ids": ["uuid"] }` — one or more topic IDs
do not exist or are not live. The `invalid_ids` array lists the specific IDs that failed validation.

---

### DELETE /compass/answers/me

Soft-deletes all of the user's compass responses and clears their selected topic IDs. Idempotent —
returns 200 even when the user has no responses.

**Auth required:** Yes

**Response (200):**

```json
{ "reset": true }
```

---

### GET /compass/progress

Returns the user's compass calibration completeness as a score. Optionally filtered by a political
role scope.

**Auth required:** Yes

**Query params:**

- `?role=city_council` — count only topics relevant to this role
- `?role=state_legislature`
- `?role=us_congress`
- `?role=president`
- (omit `role` to count all live topics)

**Response (200):**

```json
{
  "answered": 12,
  "total": 30,
  "percent": 40
}
```

(Exact response shape from compassService — consult source if the exact fields differ.)

---

### GET /compass/politicians

Returns all active politicians ordered by name.

**Auth:** Optional

**Response (200):**

```json
[
  {
    "id": "uuid",
    "first_name": "Jane",
    "last_name": "Smith",
    "preferred_name": "Jane",
    "full_name": "Jane Smith",
    "office_title": "U.S. Representative"
  }
]
```

---

### GET /compass/politicians/:id/answers

Returns a politician's stances on all topics they have answered.

**Auth:** Optional

**Path param:** `:id` — politician UUID

**Response (200):**

```json
[
  {
    "topic_id": "uuid",
    "value": 4
  }
]
```

Returns an empty array if the politician has no recorded answers. Returns 422 VALIDATION_ERROR if
`:id` is not a valid UUID format.

---

### GET /compass/politicians/:id/:topicId/context

Returns the reasoning and sources for a politician's stance on a specific topic.

**Auth:** Optional

**Path params:** `:id` — politician UUID, `:topicId` — topic UUID

**Response (200):**

```json
{
  "reasoning": "string",
  "sources": ["https://example.com/source1", "https://example.com/source2"]
}
```

**Error (404):** `{ "code": "NOT_FOUND" }` — no context record exists for this politician/topic
combination. Context is optional — a politician may have answers without context entries.

---

## 6. Error Codes

All error responses use this shape:

```json
{ "code": "ERROR_CODE", "message": "Human-readable description" }
```

The `code` field is machine-readable and stable. The `message` field is for debugging only —
do not parse or display it to users.

| Code | HTTP Status | Meaning |
|------|-------------|---------|
| `VALIDATION_ERROR` | 422 | Request body failed schema validation (missing field, wrong type, value out of range) |
| `INVALID_TOPIC_IDS` | 422 | One or more topic IDs in PUT /compass/selected-topics are invalid or not live; `invalid_ids` array identifies which |
| `TOPIC_NOT_FOUND` | 404 | Topic UUID in POST /compass/answers does not exist or is not live |
| `NOT_FOUND` | 404 | Requested resource does not exist (used by politician context) |
| `NOT_CONNECTED` | 403 | User has not completed the Connect enrollment flow |
| `AUTH_ERROR` | 401 | JWT invalid, expired, or revoked |
| `INVALID_CREDENTIALS` | 401 | Wrong email or password (server does not distinguish between them) |
| `EMAIL_NOT_VERIFIED` | 403 | Account exists but email confirmation has not been completed |
| `EMAIL_EXISTS` | 409 | An account is already registered with this email address |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests — back off and retry after the window resets |
| `EMAIL_DELIVERY_FAILED` | 503 | Transient SMTP failure during signup — retry later |
| `USER_NOT_FOUND` | 404 | Authenticated user's profile record not found (rare — indicates DB inconsistency) |
| `INTERNAL_ERROR` | 500 | Unexpected server error — log and surface a generic error to the user |

---

## 7. Anonymous Mode Implementation Guide

CompassV2 supports anonymous compass usage. Users can complete the entire compass without creating
an account. When they create an account, their anonymous answers migrate automatically.

**How to implement:**

1. **Show the compass to unauthenticated users.** `GET /compass/topics` and `GET /compass/categories`
   work without auth.

2. **Store anonymous answers in browser localStorage only.** Do NOT call `POST /compass/answers` for
   unauthenticated users — the server returns `null` and does not persist anything. Store locally
   with a key like `compassAnswers` as a JSON array of `{ topic_id, value, write_in_text? }` objects.
   Similarly store `selectedTopics` as a JSON array of UUIDs.

3. **On signup, pass the stored state in `guest_state`.** Send all localStorage answers and selected
   topics in the `POST /auth/signup` request body. The accounts API migrates them atomically.

4. **Handle migration failure gracefully.** If migration fails, signup still returns 201. The user's
   account is created. They will need to re-enter their compass answers after confirming their email.
   Do not block signup on migration failure.

5. **Clear localStorage after successful signup.** Once the user confirms their email and logs in,
   their answers are on the server. Clear the local copies.

6. **Selected topics are a Connected-only feature.** The guest_state migration may not persist
   `selected_topics` if the user is still inform-tier (they always are at signup). Store the
   selected topics in localStorage and call `PUT /compass/selected-topics` after the user completes
   Connect enrollment.

**Summary of route behavior for unauthenticated callers:**

| Route | Unauthenticated response |
|-------|--------------------------|
| `GET /compass/topics` | Full data |
| `GET /compass/categories` | Full data |
| `GET /compass/answers` | `[]` |
| `POST /compass/answers` | `null` (not persisted) |
| `POST /compass/answers/batch` | `[]` |
| `GET /compass/selected-topics` | `{ "topic_ids": [] }` |
| `PUT /compass/selected-topics` | `{ "topic_ids": [] }` (not persisted) |
| `GET /compass/politicians` | Full data |
| `GET /compass/politicians/:id/answers` | Full data |
| `GET /compass/politicians/:id/:topicId/context` | Full data |
| `DELETE /compass/answers/me` | 401 (auth required) |
| `GET /compass/progress` | 401 (auth required) |

---

*Document version: Phase 18 (2026-03-10)*
*Covers: accounts API as shipped with Phase 18 — CompassV2 API Contract*
