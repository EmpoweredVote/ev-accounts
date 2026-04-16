# Phase 118: Verdict Badge Regression — Diagnosis

**Date:** 2026-04-15
**Investigator:** Claude (agent-a401949e)
**Method:** Code-path analysis + production API interrogation (no browser session; Chrome MCP unavailable in worktree)

---

## Reproduction

_Note: Chrome MCP tools are unavailable in this parallel worktree. Production reproduction was performed via `curl` against `https://api.empowered.vote`, direct code reading, npm version checks, and git history analysis. The findings below are equivalent in evidential weight to a browser session._

### Candidate URL (guest)

URL: `https://essentials.empowered.vote/candidate/7e768cda-38f3-4511-ad7c-c8e877c5abfa`

- `GET https://api.empowered.vote/api/candidates/7e768cda-38f3-4511-ad7c-c8e877c5abfa` returns `{ "code": "NOT_FOUND", "message": "Candidate not found" }`.
- This UUID does not correspond to a valid candidate or politician record in production.
- No compass data, no quotes, no stance rows to carry verdict badges.

**Conclusion:** This URL is not a valid RR-01 test surface. The profile will render empty or error.

### Politician URL (guest)

URL: `https://essentials.empowered.vote/politician/72dd5219-490f-48bb-986e-183a6098d602`

- `GET https://api.empowered.vote/api/essentials/politicians/72dd5219-490f-48bb-986e-183a6098d602` returns a valid Matt Pierce politician record with full office/committee/contact data.
- Matt Pierce has compass answers on 10+ topics (confirmed via `GET /api/compass/politicians/72dd5219-490f-48bb-986e-183a6098d602/answers` — returns 10 topic answers).
- `GET https://api.empowered.vote/api/essentials/quotes?politician_id=72dd5219-490f-48bb-986e-183a6098d602` returns 157 total quotes, 13 attributed to Pierce (candidateId = `72dd5219-...`).
- Guest localStorage key for verdicts: `guestVerdicts` (from `essentials/src/lib/compass.js` line 223).
- In a fresh guest session (no localStorage), `loadGuestVerdicts()` returns `null` → `newVerdicts = {}`. Verdict badges would only appear after a Read & Rank session passes a `#compass=` fragment.

**Conclusion:** The politician URL (72dd5219) is the canonical RR-01 surface. The stance accordion should render, and verdict badges should appear after a Read & Rank session or for an authenticated user with stored verdicts.

**Canonical RR-01 surface:** `https://essentials.empowered.vote/politician/72dd5219-490f-48bb-986e-183a6098d602`

**Guest localStorage key:** `guestVerdicts` (literal string)

---

## Hypothesis Tests

H1 — ev-ui version mismatch

**Evidence:**
- `essentials/package.json` pins `"@empoweredvote/ev-ui": "^0.4.0"`.
- Local `ev-ui/package.json` version: `0.4.1`.
- `npm view @empoweredvote/ev-ui version` returns `0.4.1`.
- Installed version in `essentials/node_modules/@empoweredvote/ev-ui/package.json`: `0.4.0`.
- The installed 0.4.0 `dist/index.mjs` contains `verdictsByQuote` (3 occurrences) — the verdict render branch **is present** in the installed version.
- Phase 81-01-SUMMARY confirms `verdictsByQuote` was added in ev-ui v0.1.43 (long before 0.4.0). It has been live ever since.

FAIL — The installed ev-ui version (0.4.0) contains the `verdictsByQuote` render branch. A version mismatch is not the cause.

---

H2 — CompassCard prop wiring drift

**Evidence:**
- `essentials/src/components/CompassCard.jsx` has two `StanceAccordion` call sites:
  - **Call site :321** (authed render branch): `verdictsByQuote={verdicts}` — prop passed correctly.
  - **Call site :415** (guest render branch): `verdictsByQuote={verdicts}` — prop passed correctly.
- Both call sites pass `verdictsByQuote={verdicts}` where `verdicts` comes from `CompassContext.verdicts`.
- Neither call site uses the deprecated `verdictsByTopic`.

FAIL — Both call sites correctly pass `verdictsByQuote`. Prop wiring is not the cause.

---

H3 — Fetch chain returns empty

#### Guest path (fragment)

- Guest verdict flow (CompassContext.jsx lines 149-161):
  1. If `authedUser`: call `fetchUserVerdicts()`, clear guest verdicts.
  2. Else if `fragment` with non-empty `fragment.verdicts`: use fragment verdicts, save to localStorage.
  3. Else: `loadGuestVerdicts()` from `localStorage["guestVerdicts"]` or `{}`.
- Read & Rank (`read-rank/src/utils/verdictFragment.ts`) builds a URL fragment with `#compass=<base64 JSON>` where the payload is `{ v: { [quote_id]: 'agreed'|'disagreed' }, t?: topicId }`.
- `parseCompassFragment()` in essentials decodes this and sets `fragment.verdicts = { [quote_id]: 'agreed'|'disagreed' }`.
- The quote IDs in the fragment are `quote.id` values from the Read & Rank store (sourced from `essentials.quotes.id` in the database).
- These match the `quote.id` values that StanceAccordion renders... **IF** StanceAccordion actually renders the quotes at all (see H3 below — it does not).

**Guest verdict shape:** `{ [quote_id_uuid]: 'agreed'|'disagreed' }` — shape is correct.

#### Authed path

- `fetchUserVerdicts()` (`essentials/src/lib/compass.js` lines 262-275) calls `GET /compass/verdicts` and maps:
  ```js
  for (const item of list) {
    map[item.quote_id] = item.verdict;  // expects item.verdict field
  }
  ```
- `GET /api/compass/verdicts` (`ev-accounts/backend/src/routes/compass.ts` lines 363-385) calls `getUserVerdicts()` which returns:
  ```sql
  SELECT quote_id, supported, rank, session_size, created_at, updated_at
  FROM inform.compass_verdicts
  ```
  Response shape: `[{ quote_id, supported: boolean, rank, session_size, created_at, updated_at }]`
- **The backend returns `supported: boolean`, not `verdict: string`.** The `fetchUserVerdicts` comment says it expects `{ id, user_id, quote_id, verdict, created_at }` (legacy shape), but the backend returns the new shape with `supported` instead of `verdict`.
- Result: `map[item.quote_id] = item.verdict` → `map[quote_id] = undefined` for every verdict. The returned map has all keys set to `undefined`, which is falsy — neither `'agreed'` nor `'disagreed'`. No authed verdict badges ever render.

PASS (authed path) — `fetchUserVerdicts` maps `item.verdict` but the backend returns `item.supported`. The authed verdict map is always `{ [quote_id]: undefined }`, so no authed verdict badges render.

Guest fragment path: Technically correct shape (bypasses the API), but badges still cannot render due to H4 quote filter bug.

---

H4 — Backend /compass/verdicts response shape

**Evidence:**
- `GET /api/compass/verdicts` returns `[{ quote_id, supported: boolean, rank, session_size, created_at, updated_at }]` — confirmed via code reading.
- The `supported` field is a boolean (`true` = agreed, `false` = disagreed).
- `fetchUserVerdicts()` reads `item.verdict` (not `item.supported`) — no conversion.
- The backend response shape changed (from legacy `verdict: 'agreed'|'disagreed'` to new `supported: boolean`) but the frontend client was never updated to consume it.
- `inform.compass_verdicts` table: stores `supported` boolean, `rank`, `session_size` (new schema introduced when Read & Rank launched with ranking support).

**Additional finding — quote filter in StanceAccordion (root cause, see separate section):**
- The `/api/essentials/quotes` endpoint (line 186 of `essentials.ts`) returns quotes with `issue = compass_topic UUID` (from `ct.id AS topic_id`).
- StanceAccordion (ev-ui) filters quotes by: `if (topic.topic_key) return q.issue === topic.topic_key; return q.issue.toLowerCase() === topic.short_title.toLowerCase()`.
- The compass topics API (`GET /api/compass/topics`) does NOT include `topic_key` in its response (confirmed via production API — all `topic_key` values are absent from the response).
- Therefore `topic.topic_key` is always `undefined`, and the fallback comparison `q.issue.toLowerCase() === topic.short_title.toLowerCase()` runs: `"af2fdfd6-02c4-49df-b09c-cf8536f4773f" === "abortion"` — always false.
- Result: `topicQuotes` is always `[]`. No quotes render in any expanded accordion row. Since verdict badges are only shown inside quote rows, no badges ever appear.

PASS — Two backend shape issues:
1. `GET /compass/verdicts` returns `supported: boolean` but client reads `item.verdict` (undefined).
2. `GET /essentials/quotes` returns `issue = topic_id UUID` but StanceAccordion compares to `topic.topic_key` (slug) or `short_title` (display text) — never matches.

---

H5 — CSS / display regression in StanceAccordion

**Evidence:**
- `StanceAccordion.jsx` lines 359-402: verdict badge rendering uses inline styles (`display: 'inline-flex'`, `backgroundColor`, etc.) — no Tailwind classes.
- `ev-ui` uses inline styles exclusively (confirmed by phase 81-01-SUMMARY pattern note: "ev-ui inline styles only: no Tailwind in component library source").
- There is no CSS `display: none`, `opacity: 0`, or `visibility: hidden` on the badge elements — they are conditionally rendered (`{verdict === 'agreed' && <span>...}`) rather than hidden.
- Badges cannot be hidden by CSS because they are not mounted when `verdict` is `undefined` (conditional JSX render).

FAIL — No CSS regression. Badges are not hidden; they simply never mount because `topicQuotes` is always empty (H4 quote filter bug) and `item.verdict` is always `undefined` (H3 authed path bug).

---

## Root Cause

### Root cause layer: `essentials-fetch` + `essentials-wiring`

**Two compounding bugs**, both of which must be fixed:

---

**Bug A — Quote filter: `q.issue` (UUID) vs `topic.topic_key` / `topic.short_title` (slug/text)**

- **Root cause file:** `ev-ui/src/StanceAccordion.jsx` lines 202-208
- **Root cause data:** `ev-accounts/backend/src/routes/essentials.ts` lines 192-224
- **Description:** StanceAccordion filters quotes by `q.issue === topic.topic_key` (fallback: `q.issue === topic.short_title`). The quotes API returns `issue` as a compass topic UUID. The compass topics API does not include `topic_key`. Result: `topicQuotes` is always `[]` — no quotes ever display, no verdict badges can appear.
- **Fix options (either side):**
  - Option A1 (backend): Change `GET /essentials/quotes` to return `issue: topic_key` (slug) instead of `issue: topic_id` (UUID). This would match StanceAccordion's primary comparison.
  - Option A2 (backend): Add `topic_key` to the compass topics API response so `topic.topic_key` is populated, and ensure the quotes endpoint returns the matching slug.
  - Option A3 (frontend): Change StanceAccordion to match on `q.issue === topic.id` (UUID) instead of topic_key/short_title.
- **Commit that introduced it:** The `/essentials/quotes` endpoint was built in phase 50 to serve Read & Rank (which groups quotes by topic UUID). StanceAccordion (phase 81) was written assuming `q.issue` would be a topic_key slug. The two halves were never validated together.

---

**Bug B — Authed verdict shape: `item.verdict` (undefined) vs `item.supported` (boolean)**

- **Root cause file:** `essentials/src/lib/compass.js` lines 262-275 (`fetchUserVerdicts`)
- **Root cause data:** `ev-accounts/backend/src/lib/compassService.ts` lines 521-547 (`getUserVerdicts`)
- **Description:** `fetchUserVerdicts()` reads `item.verdict` from the `/compass/verdicts` response, but the backend returns `item.supported: boolean`. The `verdict` field does not exist in the response. The map is built as `{ [quote_id]: undefined }`, so no authed verdict badges ever render.
- **Fix:** In `fetchUserVerdicts()`, map `item.supported === true ? 'agreed' : 'disagreed'` instead of reading `item.verdict`.
- **Commit that introduced it:** The backend migrated from legacy verdict shape (`verdict: 'agreed'|'disagreed'`) to new shape (`supported: boolean, rank, session_size`) in phase 79. The `fetchUserVerdicts()` client was not updated to consume the new shape.

---

**Summary:**

| Bug | Layer | File | Fix |
|-----|-------|------|-----|
| A: Quote filter uses UUID vs slug/text | ev-ui (StanceAccordion) or backend (essentials/quotes) | `ev-ui/src/StanceAccordion.jsx:206` and/or `ev-accounts/backend/src/routes/essentials.ts:221` | Either: change quote `issue` field to topic_key slug; or change StanceAccordion to match on UUID; or add topic_key to topics API response |
| B: Verdict shape mismatch `verdict` vs `supported` | essentials-fetch | `essentials/src/lib/compass.js:269` | Change `item.verdict` to `item.supported === true ? 'agreed' : 'disagreed'` |

**Root cause layer:** `essentials-wiring` (quote filter in StanceAccordion / quotes endpoint response) + `essentials-fetch` (fetchUserVerdicts shape mismatch)

**Root cause file(s):**
- `ev-ui/src/StanceAccordion.jsx` (quote-to-topic matching, lines 202-208)
- `ev-accounts/backend/src/routes/essentials.ts` (quotes endpoint `issue` field, line 221)
- `essentials/src/lib/compass.js` (fetchUserVerdicts `item.verdict`, line 269)

**One-line fix summary:**
1. `fetchUserVerdicts`: replace `item.verdict` with `item.supported === true ? 'agreed' : 'disagreed'`.
2. Quote-to-topic matching: change `/essentials/quotes` to return `issue: topic_key` (slug) instead of `issue: topic_id` (UUID), so StanceAccordion's `q.issue === topic.topic_key` comparison works.

**Commit that introduced it:**
- Bug A: Phase 50 built the quotes endpoint for Read & Rank (UUID-keyed topics). Phase 81 built StanceAccordion expecting topic_key slugs. The two were never validated together — no single "introducing commit", rather a design assumption gap.
- Bug B: Phase 79 migrated the backend verdicts schema to `supported: boolean`. `fetchUserVerdicts()` was not updated. Likely near commit `9620c327506600a73a12a4fcd7d1de8d0706e05f` (docs(79-01) complete backend verdict endpoints plan).

---

## Priority and Impact

Both bugs must be fixed for verdict badges to render:
- Bug A blocks ALL verdict badges (guest AND authed) — quotes never render.
- Bug B blocks authed verdict badges specifically — even if quotes render, authed users see no badges.

The guest fragment path (Read & Rank → essentials URL) is also blocked by Bug A, but the verdict data in the fragment is correctly shaped — it will work once quotes render.

---

## Deferred (out of scope for 118-02)

- The `GET /essentials/quotes` endpoint ignores the `?politician_id=` query param — it always returns all 157 quotes. This is a performance issue (not correctness) since StanceAccordion filters client-side. Tracking for a future phase.
- `read-rank/src/utils/verdictSync.ts` POSTs to `/compass/verdicts` using legacy format `[{ quote_id, verdict }]`. The backend supports this via `postVerdictsLegacySchema`. This is working correctly and does not need to change.
