# Focused Communities — Empowered Accounts Integration Onboarding

**Audience:** Claude instance or developer building the Focused Communities feature.
**Accounts API:** `https://accounts.empowered.vote/api`
**Auth Hub:** `https://accounts.empowered.vote`
**Last updated:** 2026-04-15

---

## What You're Building

**Focused Communities** are subreddit-style communities organized around a single compass topic. They live as spokes off the Civic Spaces hub — each community is anchored to one of the 21 live compass topics (Immigration, Healthcare, Housing, etc.).

A user who navigates to the "Housing" community sees:
- The community's discourse, organized around housing policy
- Their own stance on housing (from the compass) surfaced contextually
- Politician stances on housing pulled alongside their own
- Alignment signals — who shares their position, who doesn't

Focused Communities are a **Connect feature**. The accounts system owns identity, stances, and politician data. You query it; you don't replicate it.

---

## Account Protocols

### The Three-Tier Model

**Tier = child record presence. Never a status flag.**

```
auth.users
    └── public.users               ← slug, account_standing
        ├── connect.connected_profiles   ← EXISTS = Connected tier
        └── empower.empowered_profiles   ← EXISTS = Empowered tier
```

| Tier | Access in Focused Communities |
|------|-------------------------------|
| **Inform** | Browse community read-only. Cannot post, react, or follow a topic. |
| **Connected** | Full access — post, react, follow, see stance context. |
| **Empowered** | Same as Connected. Their legal name is public in Empower contexts, but Focused Communities is a Connect context — still show `display_name` only. |

**Focused Communities is a Connected-tier feature.** Gate all write actions behind a tier check. Never gate by checking a status field — gate by checking whether `connected_profiles` exists (the `tier` field on `/api/account/me` reflects this).

### Fetching the User

```typescript
const res = await fetch('https://accounts.empowered.vote/api/account/me', {
  headers: { 'Authorization': `Bearer ${token}` }
});
const user = await res.json();
```

Full response shape (relevant fields for Focused Communities):

```typescript
{
  id: string,                    // UUID — the stable accounts identifier
  display_name: string,          // Pseudonym — the ONLY name shown in Connect contexts
  tier: 'inform' | 'connected' | 'empowered',
  account_standing: 'active' | 'suspended',
  completed_onboarding: boolean, // false = user hasn't finished compass calibration

  // Jurisdiction (only present if location_consent = true)
  jurisdiction: {
    congressional_geo_id: string,
    congressional_district_name: string,
    state_senate_geo_id: string,
    state_senate_district_name: string,
    state_house_geo_id: string,
    state_house_district_name: string,
    county_geo_id: string,
    county_name: string,
    school_district_geo_id: string,
    school_district_district_name: string,
    city_council_geo_id: string | null,
    city_council_district_name: string | null,
    jurisdiction_state: string,
    jurisdiction_city: string | null,
  } | null,

  xp: {
    total: number,
    level: number,
    xp_in_level: number,
    xp_to_next_level: number,
  },
  gems: { yellow: number, blue: number, red: number },
  vq_hold_active: boolean,
  red_gem_quests_unlocked: boolean,  // verification_rating >= 90

  connected_profile: {
    display_name: string,
    verification_status: string,
    completed_onboarding: boolean,
    verification_rating: number,
    created_at: string,
    // NOTE: tolerance_rating is nested here — never surface it in UI
  },

  // Only present if tier === 'empowered'
  empowered_profile: {
    legal_name: string,    // NEVER display in Connect contexts
    is_active: boolean,
    candidate_page_slug: string | null,
    empowered_at: string,
  } | null,
}
```

### Privacy Rules — Non-Negotiable

These are enforced at the API layer, but you must also enforce them in your UI:

| Field | Rule |
|-------|------|
| `display_name` | The only name shown anywhere in a Connect context. |
| `legal_name` | Internal to Empower contexts only. Never read, never display, in Focused Communities. |
| `tolerance_rating` | Internal admin field. Never read, never display. |
| Raw coordinates | Never returned by the API. You get `jurisdiction` GEOIDs only. |
| `email` | Not for display anywhere in Connect. |

A suspended user (`account_standing: 'suspended'`) should be able to browse but not post or interact. Check this field before allowing writes.

### Access State Detection

```typescript
async function detectUserState() {
  const token = localStorage.getItem('ev_token');

  if (!token) return { state: 'inform' };

  const res = await fetch('https://accounts.empowered.vote/api/account/me', {
    headers: { 'Authorization': `Bearer ${token}` }
  });

  if (res.status === 401) {
    localStorage.removeItem('ev_token');
    return { state: 'inform' };
  }

  const user = await res.json();

  if (user.tier === 'inform') return { state: 'inform', user };

  if (!user.completed_onboarding) {
    return { state: 'connected_no_compass', user };
    // User is Connected but hasn't calibrated their compass yet.
    // You can still show the community, but their stance context will be empty.
    // Show a gentle prompt to complete calibration.
  }

  return { state: 'connected', user };
}
```

The three branches matter:
- **`inform`** — read-only view; all write actions redirect to the Auth Hub
- **`connected_no_compass`** — Connected but `completed_onboarding: false`; show community content but surface an empty-state prompt for their stance card
- **`connected`** — full experience; user has a stance you can load

### Auth Hub Redirects

Never build a login page. Redirect to the shared Auth Hub:

```
https://accounts.empowered.vote/login?redirect=https%3A%2F%2Fyour-focused-communities-url%2F
```

After login, extract the token:

```typescript
const hash = new URLSearchParams(window.location.hash.slice(1));
const token = hash.get('access_token');
if (token) {
  localStorage.setItem('ev_token', token);
  window.history.replaceState({}, '', window.location.pathname);
}
```

---

## JWT Verification

Tokens are ES256 asymmetric JWTs (migrated from HS256 on 2026-03-27). **There is no shared secret.** Verify via JWKS:

```typescript
import { jwtVerify, createRemoteJWKSet } from 'jose';

const JWKS = createRemoteJWKSet(
  new URL('https://kxsdzaojfaibhuzmclfq.supabase.co/auth/v1/.well-known/jwks.json')
);

const { payload } = await jwtVerify(token, JWKS, {
  issuer: 'https://kxsdzaojfaibhuzmclfq.supabase.co/auth/v1',
  audience: 'authenticated',
});
const userId = payload.sub; // accounts UUID
```

If your feature uses its own Supabase project, configure Third-Party Auth with:
- **JWKS URL:** `https://kxsdzaojfaibhuzmclfq.supabase.co/auth/v1/.well-known/jwks.json`
- **Issuer:** `https://kxsdzaojfaibhuzmclfq.supabase.co/auth/v1`
- **Audience:** `authenticated`

The accounts API also enforces server-side revocation via Redis. Cryptographic validity alone isn't sufficient for sensitive operations — validate active sessions with `GET /api/account/me`.

---

## How the Compass Works

The compass is the Inform pillar's core tool — users calibrate their positions on 21 policy topics (Immigration, Healthcare, Climate, etc.) on a 1–5 scale. Each answer is stored server-side on the accounts system. Focused Communities uses these stances as context for community membership and discourse framing.

### The Data Model

**`inform.compass_topics`** — the 21 live policy topics:
```
id              UUID        Primary key
title           TEXT        Full topic title (e.g. "Healthcare Access")
short_title     TEXT?       Short label for compact UI (e.g. "Healthcare")
question_text   TEXT        The question posed to users
is_live         BOOLEAN     Only live topics are active (filter on this)
version         INT         Increments when a topic changes substantially
office_scope    TEXT[]?     Scopes this topic applies to (e.g. ['federal','state'])
```

**`inform.compass_stances`** — the 5 pre-written stance options per topic:
```
id          UUID    Primary key
topic_id    UUID    FK to compass_topics
value       INT     1 (far left) to 5 (far right)
text        TEXT    The pre-written stance text shown to users
```

**`inform.compass_responses`** — a user's calibrated positions:
```
user_id         UUID        FK to public.users
topic_id        UUID        FK to compass_topics
value           NUMERIC     1.0–5.5 in 0.5 increments (5.5 = write-in)
write_in_text   TEXT?       Custom position text (when value = 5.5)
inverted        BOOLEAN     User flipped their spoke direction (apply consistently)
visibility      ENUM        'private' | 'friends' | 'public'
deleted_at      TIMESTAMPTZ Soft-delete marker (NULL = active)
updated_at      TIMESTAMPTZ Last calibration timestamp
```

**`inform.politician_answers`** — a politician's positions:
```
politician_id   UUID    FK to inform.politicians
topic_id        UUID    FK to compass_topics
value           INT     1–5 (whole numbers only; 0 = not answered, filtered out)
```

### Important: The Inversion Mechanic

A user can flip the spoke direction of their compass for a given response. When `inverted: true`:
- The user's value reads left-to-right opposite to the default
- **Always apply it when displaying the user's stance** — never ignore it
- Fetch the response exactly as returned; do not recompute

---

## Pulling Compass Data

All compass endpoints are available publicly (no auth required for reads). Authenticated requests additionally return the calling user's own answers on the relevant endpoints.

### 1. Fetch All Live Topics (for Community Index / Topic Header)

```
GET /api/compass/topics
```

No auth required. Returns all 21 live topics with nested stances and categories.

**Response:**
```typescript
[
  {
    id: string,              // UUID — use as the community's anchor key
    title: string,           // "Healthcare Access"
    short_title: string | null,  // "Healthcare"
    question_text: string,   // "What is your position on..."
    is_live: boolean,        // Always true (endpoint filters for is_live = true)
    version: number,
    office_scope: string[] | null,  // ['federal','state'] | null
    applies_federal: boolean,
    applies_state: boolean,
    applies_local: boolean,
    stances: [
      { id: string, value: number, text: string }   // value 1–5
    ],
    categories: [
      { category_id: string, title: string }
    ],
    roles: [
      { role_scope: 'federal' | 'state' | 'local', is_required: boolean }
    ]
  }
]
```

**Pattern:** Fetch once on app load, cache in memory. Topics change rarely — a topic change bumps `version`, but the ID stays the same. Your community anchor is the topic `id`.

### 2. Fetch Topic Categories (for Browse / Filter UI)

```
GET /api/compass/categories
```

No auth required. Returns categories with their nested live topics.

```typescript
[
  {
    id: string,
    title: string,           // "Economy", "Social Issues", etc.
    topics: [
      { id: string, title: string, short_title: string | null }
    ]
  }
]
```

### 3. Fetch a User's Own Stances

This is how you surface "your position on this topic" inside a community. The endpoint returns the calling user's full set of calibrated responses.

```
GET /api/compass/answers
Authorization: Bearer <token>
```

**Response:**
```typescript
[
  {
    topic_id: string,         // Match this against your community's topic ID
    value: number,            // 1.0–5.5 in 0.5 increments
    write_in_text: string | null,  // Custom text if value = 5.5
    visibility: 'private' | 'friends' | 'public',
    inverted: boolean,        // ALWAYS apply this when rendering
    created_at: string,
    updated_at: string,
  }
]
```

Returns `[]` for unauthenticated requests — always check for the empty case.

**Pattern for a single community page:** Filter the returned array for `topic_id === community.topicId`. If no matching response exists, the user hasn't calibrated this topic yet.

```typescript
const answers = await fetchCompassAnswers(token);
const myStance = answers.find(a => a.topic_id === community.topicId) ?? null;
```

### 4. Fetch Specific Answers by Topic IDs (Batch)

When you need a user's stances for a specific set of topics (e.g., only the topics relevant to a community cluster):

```
POST /api/compass/answers/batch
Authorization: Bearer <token>
Content-Type: application/json

{ "ids": ["topic-uuid-1", "topic-uuid-2"] }
```

**Response:** Same shape as `GET /api/compass/answers` but filtered to the requested IDs.

### 5. Fetch Politician Stances for a Community

```
GET /api/compass/politicians/:politicianId/answers
```

No auth required. Returns all topics this politician has answered.

```typescript
[
  {
    topic_id: string,
    value: number   // 1–5, whole numbers only
  }
]
```

**Pattern:** Filter for your community's `topicId`:

```typescript
const politicianAnswers = await fetchPoliticianAnswers(politicianId);
const stance = politicianAnswers.find(a => a.topic_id === community.topicId) ?? null;
// stance === null means this politician hasn't answered this topic
```

### 6. Fetch a Politician's Reasoning (Context)

If a politician has provided reasoning for their stance on a topic:

```
GET /api/compass/politicians/:politicianId/:topicId/context
```

No auth required. Returns 404 if no context exists.

```typescript
{
  reasoning: string,      // Narrative explanation of their stance
  sources: string[]       // Array of source URLs or citations
}
```

### 7. Fetch All Politicians (for Community Sidebar)

```
GET /api/compass/politicians
```

No auth required. Returns all active politicians.

```typescript
[
  {
    id: string,
    first_name: string,
    last_name: string,
    preferred_name: string | null,
    full_name: string,
    office_title: string | null,
    photo_url: string | null,
  }
]
```

### 8. Compute Alignment Scores Against Politicians

When showing "how aligned is this user with politicians in this community":

```
POST /api/compass/compare
Authorization: Bearer <token>
Content-Type: application/json

{ "politician_ids": ["uuid1", "uuid2"] }
```

**Response:**
```typescript
{
  politicians: [
    {
      id: string,
      name: string | null,
      alignment_score: number,    // 0–100 rounded integer
      topics: [
        {
          topic_id: string,
          user_value: number,         // 1.0–5.5
          politician_value: number    // 1–5
        }
      ]
    }
  ]
}
```

The `alignment_score` is proximity-based across all shared answered topics. 100 = perfectly aligned.

**Pattern:** For a single Focused Community, you can still use this endpoint — pass all relevant politicians and then filter `topics` to your community's `topicId` for the per-topic delta.

### 9. Compass Progress / Calibration Completeness

To know whether a user has calibrated enough topics to participate meaningfully:

```
GET /api/compass/progress
Authorization: Bearer <token>
```

```typescript
{
  required: number,   // Count of required (Top Priority) topics
  answered: number,   // How many the user has answered
  percent: number,    // 0–100
  complete: boolean   // true = fully calibrated
}
```

**"Fully Calibrated"** = all 20 live Top Priority topics answered. New topics have a 30-day grace period. Empowered users face demotion if they lapse.

This maps to `completed_onboarding` on `/api/account/me`. If `completed_onboarding: false`, show a soft prompt in the community UI.

---

## Building the Stance Context Card

The core UI element in a Focused Community is the stance card — the user's position surfaced alongside politicians'. Here's the assembly pattern:

```typescript
async function buildStanceContext(topicId: string, politicianIds: string[], token?: string) {
  const [topicsRes, politiciansRes, answersRes] = await Promise.all([
    fetch('/api/compass/topics'),
    fetch('/api/compass/politicians'),
    token
      ? fetch('/api/compass/answers', { headers: { Authorization: `Bearer ${token}` } })
      : Promise.resolve({ json: () => [] }),
  ]);

  const [topics, politicians, answers] = await Promise.all([
    topicsRes.json(),
    politiciansRes.json(),
    answersRes.json ? answersRes.json() : Promise.resolve([]),
  ]);

  const topic = topics.find((t: any) => t.id === topicId);
  const myStance = answers.find((a: any) => a.topic_id === topicId) ?? null;

  // Fetch politician answers for this topic
  const politicianStances = await Promise.all(
    politicianIds.map(async (pid) => {
      const res = await fetch(`/api/compass/politicians/${pid}/answers`);
      const ans = await res.json();
      const stance = ans.find((a: any) => a.topic_id === topicId) ?? null;
      const politician = politicians.find((p: any) => p.id === pid);
      return { politician, stance };
    })
  );

  return { topic, myStance, politicianStances };
}
```

**Rendering `myStance`:**
- If `myStance === null` → user hasn't answered; show an empty state with a call to calibrate
- If `myStance.value === 5.5` → user wrote in their own position; display `write_in_text`
- Otherwise → look up the stance text from `topic.stances.find(s => s.value === Math.round(myStance.value))`
- **Always apply `myStance.inverted`** — if `inverted: true`, the spoke renders right-to-left

---

## Selected Topics

A user can "follow" up to 3–8 topics as their focus areas (used in the compass spoke selector). You can read and write this list:

```
GET /api/compass/selected-topics
Authorization: Bearer <token>
```
Returns: `number[]` — array of selected topic IDs (integers).

```
PUT /api/compass/selected-topics
Authorization: Bearer <token>
Content-Type: application/json

{ "topic_ids": [1, 4, 7, 12] }
```

You can use this to pre-select a community's topic when a user joins — or to show which of a user's followed topics this community matches.

---

## Service-to-Service: XP and Gem Awards

If community actions should reward XP or gems, call the accounts API with your service key. Never generate random transaction keys — use deterministic IDs tied to the specific event.

```typescript
// Award XP for a community action
await fetch('https://accounts.empowered.vote/api/xp/award', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Service-Key': process.env.EV_SERVICE_KEY!,
  },
  body: JSON.stringify({
    user_id: userId,                            // accounts UUID
    source: 'focused_communities_post',         // register this key with accounts team first
    amount: 25,
    transaction_key: `fc-post-${postId}`,      // stable, deterministic
  }),
});

// Award gems
await fetch('https://accounts.empowered.vote/api/gems/award', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-Service-Key': process.env.EV_SERVICE_KEY!,
  },
  body: JSON.stringify({
    user_id: userId,
    gem_type: 'yellow',         // 'yellow' | 'blue' | 'red' — confirm authorization
    amount: 1,
    source: 'focused_communities_milestone',
  }),
});
```

`transaction_key` is mandatory and idempotent — submitting the same key twice silently ignores the second call.

---

## Public Profile Data

To display another user's profile card in a community thread:

```
GET /api/account/profile/:userId
```

No auth required. Returns only safe public fields:

```typescript
{
  id: string,
  display_name: string,
  tier: 'inform' | 'connected' | 'empowered',
  level: number,
  xp: { total: number },
}
```

Never `tolerance_rating`, never `legal_name`, never coordinates.

---

## Database Ownership

Focused Communities **will have its own schema** in the consolidated Supabase project (`kxsdzaojfaibhuzmclfq`). Likely `focused_communities.*` or `civic_spaces.*` (confirm with accounts team).

Rules:
- **User identity is always the accounts UUID.** Never create a local user table.
- **Never replicate user profile data.** Don't copy `display_name`, XP, or gems — fetch fresh from accounts each session.
- **Never store stances or politician answers locally.** These are owned by the accounts system and can change. Query them at render time or cache briefly (e.g., 5-minute TTL).
- **RLS on every table.** All migrations must have RLS policies defined before shipping.
- **Compass topic `id` as FK.** If your community records reference a topic, store the topic UUID as a foreign key. Don't store title strings.

---

## API Quick Reference

**Base:** `https://accounts.empowered.vote/api`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/account/me` | Bearer | Full user state (tier, jurisdiction, XP, gems, onboarding status) |
| `GET` | `/api/account/profile/:userId` | None | Public profile (display_name, tier, level) |
| `POST` | `/api/xp/award` | X-Service-Key | Award XP (idempotent) |
| `POST` | `/api/gems/award` | X-Service-Key | Award gems (idempotent) |
| `GET` | `/api/compass/topics` | None | All 21 live topics with stances + categories |
| `GET` | `/api/compass/categories` | None | Topic categories with nested topics |
| `GET` | `/api/compass/answers` | Bearer | Calling user's calibrated stances (empty array if unauthed) |
| `POST` | `/api/compass/answers/batch` | Bearer | User stances for a specific set of topic IDs |
| `GET` | `/api/compass/selected-topics` | Bearer | User's followed topic IDs |
| `PUT` | `/api/compass/selected-topics` | Bearer | Update user's followed topics |
| `GET` | `/api/compass/progress` | Bearer | Calibration completeness (required/answered/percent) |
| `POST` | `/api/compass/compare` | Bearer | Alignment scores vs politicians (body: `{politician_ids:[]}`) |
| `GET` | `/api/compass/politicians` | None | All politicians |
| `GET` | `/api/compass/politicians/:id/answers` | None | Politician's stances on all topics |
| `POST` | `/api/compass/politicians/:id/answers/batch` | None | Politician stances filtered to topic IDs |
| `GET` | `/api/compass/politicians/:id/:topicId/context` | None | Politician reasoning + sources for one topic (404 if absent) |

Auth Hub:
```
Login:  https://accounts.empowered.vote/login?redirect={encodeURIComponent(url)}
Signup: https://accounts.empowered.vote/signup?redirect={encodeURIComponent(url)}
```

---

## Key Patterns Summary

1. **Gate by tier, not status flags.** Check `tier === 'connected'` or `tier === 'empowered'` from `/api/account/me`. Gate writes behind this check.

2. **Display name only.** Show `display_name` in all Connect contexts. Never `legal_name`, never email.

3. **Suspended users get read-only.** Check `account_standing: 'suspended'` before allowing writes.

4. **Empty compass = soft prompt.** If `completed_onboarding: false` or no stance exists for the community's topic, show an empty state — not an error. The user may not have calibrated yet.

5. **Always apply `inverted`.** When rendering a user's stance, respect the `inverted` boolean. Never ignore it.

6. **5.5 = write-in.** Values of 5.5 indicate a custom write-in position. Display `write_in_text` instead of a preset stance label.

7. **Stances are read-only for you.** Focused Communities reads stances but never writes them. Stance updates happen through the compass UI. Don't build your own stance-editing flow.

8. **Never store stances locally.** Compass data is owned by accounts and can change. Query at render time; cache briefly if needed.

9. **Idempotent awards.** Always pass a stable `transaction_key` when awarding XP or gems. Never generate random keys.

10. **Topic ID is the community anchor.** Each Focused Community maps to one `compass_topics.id`. Store that UUID in your schema as the community's defining key.

---

## Coordination With the Accounts Team

Before starting implementation:

1. **Service key issuance** — request an `EV_SERVICE_KEY` scoped to Focused Communities.
2. **XP source keys** — register your source key strings (e.g. `focused_communities_post`, `focused_communities_reaction`) so the XP ledger has proper attribution.
3. **Gem type authorization** — confirm which gem types your key is authorized to award.
4. **Schema name** — confirm your schema name in the shared Supabase project.
5. **Topic-community mapping** — clarify whether communities are created 1:1 per topic automatically, or whether a subset of topics gets communities. This is a product decision that affects your schema design.

---

## Reading the Accounts Codebase (If Needed)

```
backend/
├── migrations/         Ground truth schema — read these before writing migrations
└── src/
    ├── routes/
    │   ├── compass.ts  All compass endpoints (topics, answers, politicians, compare)
    │   ├── account.ts  /api/account/me — full user shape
    │   └── social.ts   Social graph patterns (peer requests, follows)
    ├── lib/
    │   ├── compassService.ts   Compass data access + alignment scoring
    │   └── connectService.ts   Connect enrollment + calibration import
    └── middleware/
        ├── auth.ts         requireAuth, optionalAuth
        ├── tierGuards.ts   requireConnected, requireEmpowered
        └── requireRole.ts  Role-based access control factory
```

Key reference docs:
- `docs/ACCOUNTS-ONBOARDING.md` — full system architecture
- `docs/CIVIC-SPACES-ONBOARDING.md` — spatial layer docs; same Connect-tier integration pattern
- `docs/COMPASSV2-INTEGRATION.md` — canonical compass integration guide (745 lines)
- `docs/ESSENTIALS-INTEGRATION.md` — jurisdiction + data flow patterns

---

*Empowered Accounts — Empowered Vote | Bloomington, Indiana*
*Focused Communities is a Connect Pillar feature. Questions → coordinate with the accounts team before building.*
