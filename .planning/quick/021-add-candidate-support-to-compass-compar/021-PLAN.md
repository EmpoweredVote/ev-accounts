---
phase: quick-021
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - backend/src/lib/compassService.ts
  - backend/src/routes/compass.ts
autonomous: true

must_haves:
  truths:
    - "GET /compass/politicians returns same results as before when no query param is passed"
    - "GET /compass/politicians?include_candidates=true merges active election candidates with incumbents, each record having is_candidate and is_incumbent fields"
    - "GET /compass/candidates/:id/answers returns topic/value array for a valid candidate"
    - "GET /compass/candidates/:id/answers returns 404 when candidateId is not found or has no empowered_profile"
    - "TypeScript compiles with no errors"
  artifacts:
    - path: "backend/src/lib/compassService.ts"
      provides: "getCandidates() export and getCandidateAnswers() export"
      exports: ["getCandidates", "getCandidateAnswers"]
    - path: "backend/src/routes/compass.ts"
      provides: "GET /politicians query param handling and GET /candidates/:id/answers route"
  key_links:
    - from: "backend/src/routes/compass.ts (GET /politicians)"
      to: "compassService.getCandidates()"
      via: "include_candidates=true query param conditional"
    - from: "backend/src/routes/compass.ts (GET /candidates/:id/answers)"
      to: "compassService.getCandidateAnswers(candidateId)"
      via: "direct call, 404 on null return"
---

<objective>
Add candidate support to the compass compare endpoints so that election candidates with compass answers can appear alongside incumbent politicians in the compare UI.

Purpose: Enables the compass compare feature to work with election candidates who have filled out their compass via their empowered_profile.
Output: Two changes — extended GET /politicians and new GET /candidates/:id/answers — both backed by pool.query() since essentials/empower schemas are not in PostgREST.
</objective>

<execution_context>
@C:\Users\Chris\.claude/get-shit-done/workflows/execute-plan.md
@C:\Users\Chris\.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/STATE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add getCandidates() and getCandidateAnswers() to compassService.ts</name>
  <files>backend/src/lib/compassService.ts</files>
  <action>
Add two new exported functions immediately after the existing `getCompassPoliticians` function (around line 319):

**getCandidates()** — queries active election candidates that have at least one compass answer via their empowered_profile. Returns an array with the same shape as `getCompassPoliticians()` rows plus `is_candidate: true` and `is_incumbent: boolean` from `race_candidates.is_incumbent`. Use the exact SQL provided below via `pool.query()`.

SQL:
```sql
SELECT
  rc.id,
  rc.first_name,
  rc.last_name,
  NULL::text AS preferred_name,
  rc.full_name,
  rc.photo_url AS photo_origin_url,
  NULL::text AS photo_custom_url,
  r.position_name AS office_title,
  COALESCE(o.representing_state, e.state::text, '') AS representing_state,
  COALESCE(o.representing_city, '') AS representing_city,
  COALESCE(d.label, '') AS district_label,
  COALESCE(d.district_type, '') AS district_type,
  (
    SELECT COUNT(*)::int FROM inform.compass_responses cr
    JOIN empower.empowered_profiles ep ON ep.user_id = cr.user_id
    WHERE ep.politician_id = rc.politician_id AND cr.deleted_at IS NULL AND cr.value != 0
  ) AS answer_count,
  (
    SELECT array_agg(cr.topic_id) FROM inform.compass_responses cr
    JOIN empower.empowered_profiles ep ON ep.user_id = cr.user_id
    WHERE ep.politician_id = rc.politician_id AND cr.deleted_at IS NULL AND cr.value != 0
  ) AS answered_topic_ids,
  true AS is_candidate,
  rc.is_incumbent
FROM essentials.race_candidates rc
JOIN essentials.races r ON r.id = rc.race_id
JOIN essentials.elections e ON e.id = r.election_id
LEFT JOIN essentials.offices o ON o.id = r.office_id
LEFT JOIN essentials.districts d ON d.id = o.district_id
WHERE rc.candidate_status = 'active'
  AND e.election_date >= CURRENT_DATE
  AND rc.politician_id IS NOT NULL
  AND (
    SELECT COUNT(*) FROM inform.compass_responses cr
    JOIN empower.empowered_profiles ep ON ep.user_id = cr.user_id
    WHERE ep.politician_id = rc.politician_id AND cr.deleted_at IS NULL AND cr.value != 0
  ) > 0
```

Map rows to the same shape as `getCompassPoliticians()` return type, with these additions:
- `is_candidate: true` (always true for this function)
- `is_incumbent: r.is_incumbent as boolean`
- `is_active: true` (candidates from active elections are considered active)
- `photo_origin_url: r.photo_origin_url ?? ''` (no lateral join needed — candidates have a direct photo_url column)

**getCandidateAnswers(candidateId: string)** — three-step lookup:
1. `SELECT politician_id FROM essentials.race_candidates WHERE id = $1` via pool.query(). If no row, return null.
2. `SELECT user_id FROM empower.empowered_profiles WHERE politician_id = $1` via pool.query(). If no row, return null.
3. `SELECT topic_id, value FROM inform.compass_responses WHERE user_id = $1 AND deleted_at IS NULL AND value != 0 ORDER BY topic_id ASC` via pool.query().
Return the rows array typed as `Array<{ topic_id: string; value: number }>`, or null if step 1 or 2 finds nothing.

All three steps must use `pool.query()` — NOT supabaseAnon.schema() — because essentials and empower are not in the PostgREST exposed schema list.
  </action>
  <verify>cd C:/EV-Accounts/backend && npx tsc --noEmit 2>&1 | head -30</verify>
  <done>getCandidates and getCandidateAnswers are exported from compassService.ts with no TypeScript errors. Each uses pool.query() exclusively.</done>
</task>

<task type="auto">
  <name>Task 2: Wire routes in compass.ts — extend GET /politicians and add GET /candidates/:id/answers</name>
  <files>backend/src/routes/compass.ts</files>
  <action>
**Change 1 — Import new service functions:**
Add `getCandidates` and `getCandidateAnswers` to the existing import from `'../lib/compassService.js'`.

**Change 2 — Extend GET /politicians handler:**
The current handler (around line 456) calls `getCompassPoliticians()` and returns the result directly. Change it to:
1. Check `req.query.include_candidates === 'true'`
2. If false/absent: return existing behavior unchanged (`await getCompassPoliticians()`)
3. If true: run both `getCompassPoliticians()` and `getCandidates()` in parallel via `Promise.all`. Add `is_candidate: false, is_incumbent: true` to each incumbent record. Merge the two arrays and return the combined result.

No auth change — remains `optionalAuth`.

**Change 3 — Add GET /candidates/:id/answers route:**
Register this route BEFORE the existing `/politicians/:id/answers` routes to avoid Express routing conflicts. A good insertion point is just before the `GET /politicians` route (around line 450). The route must be:

```
GET /candidates/:id/answers
Auth: optionalAuth (public, no PII)
```

Handler logic:
1. Extract `req.params.id` as `candidateId`
2. Call `await getCandidateAnswers(candidateId)`
3. If result is null → `res.status(404).json({ code: 'NOT_FOUND', message: 'Candidate not found or has no compass answers' })`
4. Otherwise → `res.status(200).json(result)`

Error logging prefix: `[GET /compass/candidates/:id/answers]`
  </action>
  <verify>cd C:/EV-Accounts/backend && npx tsc --noEmit 2>&1 | head -30</verify>
  <done>TypeScript compiles clean. GET /politicians route accepts include_candidates param. GET /candidates/:id/answers route is registered and handles 404 for missing candidates.</done>
</task>

</tasks>

<verification>
Run from C:/EV-Accounts/backend:

1. `npx tsc --noEmit` — must exit 0 with no errors

Manual smoke tests (if dev server running):
- `curl http://localhost:3001/api/compass/politicians` — returns array without is_candidate field (backward compat)
- `curl "http://localhost:3001/api/compass/politicians?include_candidates=true"` — returns merged array, all records have is_candidate field
- `curl http://localhost:3001/api/compass/candidates/nonexistent/answers` — returns 404 JSON
</verification>

<success_criteria>
- TypeScript compiles with no errors
- GET /compass/politicians without param: unchanged behavior
- GET /compass/politicians?include_candidates=true: merged array, incumbents have is_candidate: false, is_incumbent: true; candidates have is_candidate: true, is_incumbent from DB
- GET /compass/candidates/:id/answers: returns Array<{ topic_id, value }> for valid candidate
- GET /compass/candidates/:id/answers: returns 404 for nonexistent candidateId
- All DB access via pool.query() (no supabaseAnon.schema() for essentials/empower schemas)
</success_criteria>

<output>
After completion, create `.planning/quick/021-add-candidate-support-to-compass-compar/021-SUMMARY.md`
</output>
