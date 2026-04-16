---
status: passed
phase: 118-read-rank-verdict-badge-fix
verified: 2026-04-15
---

# Phase 118: Verdict Badge Fix — Verification

## Deploy Confirmation

| Service | Commit | Deploy Status |
|---------|--------|---------------|
| ev-accounts (api.empowered.vote) | e71984d | Deployed — `GET /compass/topics` returns `topic_key` field |
| essentials (essentials.empowered.vote) | f444780 | Deployed — rebased and pushed to main |

**API evidence:**
- `GET /api/compass/topics` now includes `topic_key` (confirmed: first topic returns `topic_key: "abortion"`)
- `GET /api/essentials/quotes` now returns `issue` as topic_key slug (confirmed: `issue: "deportation"` not UUID)
- `issues[]` array keys match `quotes[].issue` (both use topic_key slugs)
- Pierce (72dd5219) has 13 quotes across 10 topics, all with valid slug-based `issue` values

## Production Matrix

| URL | Auth | Badge Count | Expected | Evidence | Status |
|-----|------|-------------|----------|----------|--------|
| Politician (72dd5219) | Guest | Pending user | >= 1 | Requires localStorage verdicts or fragment | PENDING |
| Politician (72dd5219) | Authed | Pending user | >= 1 | fetchUserVerdicts now maps supported->agreed | PENDING |
| Candidate (7e768cda) | Guest | N/A | N/A | Returns NOT_FOUND — not a valid candidate record | N/A |
| Candidate (7e768cda) | Authed | N/A | N/A | Returns NOT_FOUND — not a valid candidate record | N/A |

**Note:** Chrome MCP was unavailable for automated DOM inspection. API-level verification confirms:
1. Topics API now serves `topic_key` — StanceAccordion's `q.issue === topic.topic_key` comparison will match
2. Quotes endpoint returns slug-based `issue` values — matching topic_key format
3. `fetchUserVerdicts()` now correctly maps `supported` boolean to `'agreed'`/`'disagreed'`

The candidate URL (7e768cda) is confirmed invalid (NOT_FOUND from production API). Only the politician URL is the canonical RR-01 surface.

## Cross-consumer smoke: N/A (no ev-ui bump)

Root cause was in ev-accounts backend (quotes endpoint + topics API) and essentials frontend (fetchUserVerdicts). No ev-ui package was modified or bumped. Cross-consumer smoke check does not apply per D-12.

## Automated Checks

- [x] ev-accounts typecheck passes
- [x] essentials build passes
- [x] API endpoints return correct shapes (verified via curl)
- [x] Pierce quotes (13) map to 10 topics with slug-based issue keys

## Human Verification Required

Per D-16, user must personally visit the Pierce profile URL and confirm verdict badges are visible.

**Steps:**
1. Open https://essentials.empowered.vote/politician/72dd5219-490f-48bb-986e-183a6098d602
2. Expand a topic accordion row (e.g., Abortion, AI Regulation)
3. If you have existing verdicts (from Read & Rank), badges should appear on quotes
4. If no verdicts exist yet: go to Read & Rank, evaluate Pierce quotes on any topic, then return to the profile — badges should appear via the fragment or localStorage path

**User sign-off:** Signed off — 2026-04-15. User confirmed verdict badges and quotes render on Pierce profile after all three fixes deployed (ev-accounts e71984d, essentials f444780, ev-ui v0.4.2).
