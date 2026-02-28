# Phase 8: Public Candidate Pages - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Expose Empowered user-candidates publicly via two unauthenticated endpoints:
1. `GET /api/candidates/:slug` — individual candidate profile page (permanent public record)
2. `GET /api/essentials/candidates/:zip` — ZIP-based candidate lookup for the Essentials frontend

Both endpoints enforce strict field projection: `tolerance_rating` is absent from every response at both the RLS and serialization layers. Creating posts, interactions, or any write path is out of scope.

</domain>

<decisions>
## Implementation Decisions

### Endpoints

- Two endpoints: `GET /api/candidates/:slug` (profile) AND `GET /api/essentials/candidates/:zip` (Essentials lookup)
- Both are fully unauthenticated — no JWT required for any read
- ZIP lookup will eventually shift to full address lookup, but Phase 8 uses ZIP only

### Response shape — candidate profile

- `legal_name` is split into `first_name` and `last_name` at the API serialization layer (parsing the stored single field)
- Photo returned as `images: [{type: 'default', url: photo_origin_url}]` — matches Essentials frontend format
- Jurisdiction fields added to `empowered_profiles` via schema migration: `representing_city`, `representing_state`, `district_type`, `district_id`, `government_name`, `chamber_name`, `chamber_name_formal`
- Active flag included in all responses: `{active: true/false, demoted_at: date | null}`
- `tolerance_rating` NEVER included — enforced at RLS layer AND serializer (test must assert absence, not null)

### Stances endpoints

- `GET /api/candidates/:slug` returns profile + candidate's own selected topics (3-8 pinned topics) as their curated featured positions
- Separate endpoint `GET /api/candidates/:slug/answers` returns answers for caller-specified topic IDs (for personalized viewer comparison)
- Answer shape: `{topic_id, value, write_in_text}` — write-in text included when present
- Inversion: client passes viewer's inverted topic IDs as query param (e.g., `?inverted=topicId1,topicId2`); API flips stance values before returning

### Inactive state

- `GET /api/candidates/:slug` always returns full profile regardless of `is_active` — inactive candidates return full data + `{active: false, demoted_at: date}`. This is the permanent public record.
- `GET /api/essentials/candidates/:zip` excludes inactive (demoted) candidates — only active candidates are surfaced in Essentials
- Add explicit DB UNIQUE constraint on `empowered_profiles.candidate_page_slug` — enforces slug non-reassignment at schema level (in addition to Phase 5 generation logic)

### Caching

- Both endpoints cached via Upstash Redis (existing layer)
- TTL: 15 minutes (900s) for both profile and ZIP lookup
- Cache invalidation: accept up to 15-minute stale window on demotion — no active invalidation required

### Claude's Discretion

- Cache key naming convention for slug and ZIP endpoints
- Exact parsing logic for splitting legal_name into first/last (handle multi-word last names, suffixes)
- Error shape for invalid slug (404) vs. no candidates in ZIP (200 with empty array)
- How to structure the inversion query param (comma-separated IDs vs. repeated param)

</decisions>

<specifics>
## Specific Ideas

- Essentials frontend (`EmpoweredVote/essentials`) consumes `/essentials/candidates/{zip}` and renders candidates via `PoliticianCard` / `PoliticianGrid` components — response must match the politician object shape those components expect
- CompassV2 (`EmpoweredVote/CompassV2`) uses `GET /compass/politicians/{id}/answers` for comparison — Phase 8's answers endpoint should be compatible with how CompassV2 consumes politician answers (array of `{topic_id, value}`)
- Inversion behavior is a design intent in CompassV2 that is not yet implemented for politicians — Phase 8's API query-param approach enables this to be implemented client-side without requiring a second API redesign
- "Permanent public repository" framing: even demoted candidates remain accessible by slug. The platform maintains a public record of all who were ever Empowered.

</specifics>

<deferred>
## Deferred Ideas

- Address-based candidate lookup (replace ZIP with full address for precise geographic matching) — future phase
- Candidate reasoning/context per topic (analogous to `GET /compass/politicians/:id/:topicId/context`) — future enrichment phase
- Election date and election name fields on the candidate response — not in current schema, future enrichment
- User-to-user compass compare (COMP-05) — previously deferred from Phase 4, still deferred

</deferred>

---

*Phase: 08-public-candidate-pages*
*Context gathered: 2026-02-28*
