# Phase 39: Compass Additions - Context

**Gathered:** 2026-03-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Fill in missing compass API endpoints (compare, verdicts, admin CRUD, batch politician answers) and migrate the value range from integer `1–5` to decimal `0.5–5.5`. No frontend work — this phase completes the backend compass contract so CompassV2 has zero Go server dependency for compass routes.

</domain>

<decisions>
## Implementation Decisions

### Value range migration

- Migrate `inform.compass_responses.value` and `inform.politician_answers.value` from integer to `numeric(3,1)` (one decimal place)
- `inform.compass_stances.value` stays as integer 1–5 — stances define the canonical options; no change needed
- Valid values: **0.5 increments only** — 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5
- CHECK constraint enforces half-step precision: `value * 2 = ROUND(value * 2) AND value >= 0.5 AND value <= 5.5`
- Existing integer rows (1–5) are all valid in the new range — no data transformation needed
- **Semantic model:** integer values (1, 2, 3, 4, 5) = user selected a canonical stance; half-step values (0.5, 1.5, 2.5, 3.5, 4.5, 5.5) = user wrote in their own stance and placed it between two canonical options
- **0.5 = more extreme than stance 1; 5.5 = more extreme than stance 5** — write-in positions that go beyond the current spectrum in either direction
- Write-in detection: `write_in_text IS NOT NULL` pairs with half-step values

### Compare endpoint

- Accept **multiple politician IDs in one call** — `POST /api/compass/compare` with `{ politician_ids: uuid[] }` body
- Response: per-politician object with `alignment_score` (0–100%) + `topics` array
  - Shape: `{ politicians: [{ id, name, alignment_score, topics: [{ topic_id, user_value, politician_value }] }] }`
- **Proximity-based scoring:** `1 - (|user_value - politician_value| / 5)` per topic, averaged across shared topics, × 100
  - Exact match = 100%; max divergence (0.5 vs 5.5 = delta 5) = 0%
- **Topic scope:** Only topics where both user AND politician have a recorded stance — no null-padded gaps
- **All mutually answered topics** included — not limited to user's selected calibration topics
- Requires authentication (needs the calling user's compass_responses)

### Verdicts (Read & Rank)

- **What a verdict is:** A user's judgment from a Read & Rank session — the blind taste test assigns binary support (yes/no per quote), and the ranking step produces an ordinal position among liked quotes
- **Schema:** New table `inform.compass_verdicts` with: `user_id`, `quote_id` (FK → `essentials.quotes`), `supported` (boolean), `rank` (nullable integer — position among supported quotes in session; NULL if not supported), `session_size` (integer — how many quotes were in this ranking session, for normalization), timestamps
- **Persistence:** Updateable — `UPSERT ON CONFLICT (user_id, quote_id)`; latest verdict wins. A user re-doing Read & Rank updates their existing verdicts.
- **POST shape:** Batch — accepts `{ verdicts: [{ quote_id, supported, rank, session_size }] }` — all verdicts from a Read & Rank session in one atomic transaction
- **GET shape:** Returns all of the calling user's verdicts; supports `?politician_id=` filter for the profile page use case
- **Profile page output:** `supported` + `rank` + `session_size` together enable "liked mildly vs liked a lot" display (rank/session_size normalization)
- Requires authentication; RLS owner-read (users see only their own verdicts)

### Admin CRUD — Topics

- `POST /api/compass/topics/create` — create topic with stances included in same request (atomic)
  - Body: `{ title, short_title, question_text, level[], is_live, stances: [{value:1,text}, ...{value:5,text}], category_ids?: uuid[] }`
  - Optional `category_ids[]` in create payload for immediate assignment
- `PATCH /api/compass/topics/update` — update topic metadata (title, question_text, is_live, etc.)
- `DELETE /api/compass/topics/delete/:id` — **blocked if any compass_responses exist** for that topic; returns 422 with message. Admin must use PATCH to set `is_live=false` to archive instead.
- `PATCH /api/compass/topics/categories/update` — reassign topic-category mappings after creation
- `PATCH /api/compass/stances/update` — update stance text on existing stances

### Admin CRUD — Politician Data

- `PUT /api/compass/politicians/:id/answers` — **full replacement**: send all answers for the politician; anything not in the payload is deleted. Body: `{ answers: [{topic_id, value}] }`
- `POST /api/compass/politicians/context` — add or update politician reasoning + sources per topic. Body: `{ politician_id, topic_id, reasoning, sources: string[] }`

### Batch politician answers (non-admin)

- `POST /api/compass/politicians/:id/answers/batch` — non-admin public read: accepts `{ topic_ids: uuid[] }` and returns the politician's answers for only those specific topics
- Used by CompassV2 to efficiently fetch politician stances for a user's selected topics (3–8) without fetching all answers

### Claude's Discretion

- Exact `numeric(3,1)` vs `decimal` column type declaration — both work; use what's consistent with existing schema
- `session_size` storage approach on verdicts (could also normalize at write time)
- Admin endpoint URL style (`/topics/create` vs REST `/topics` POST) — match existing ev-accounts compass admin patterns
- Batch compare performance optimization (parallel queries vs single JOIN)

</decisions>

<specifics>
## Specific Ideas

- The "liked mildly vs liked a lot" signal on politician profile pages comes from `rank / session_size` normalization — rank 1 of 3 supported = strong preference; rank 3 of 3 = mild preference
- Write-ins at 0.5/5.5 represent stances more extreme than the existing spectrum — the spectrum can grow in either direction without changing the constraint bounds
- The analytics insight: if many users write in 3.5 rather than selecting 3 or 4, that signals the canonical options may not be well-represented — worth monitoring over time but not an implementation task

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope

</deferred>

---

*Phase: 39-compass-additions*
*Context gathered: 2026-03-20*
