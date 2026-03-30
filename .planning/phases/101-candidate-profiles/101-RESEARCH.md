# Phase 101: Candidate Profiles - Research

**Researched:** 2026-03-30
**Domain:** React frontend — profile page branching, backend API endpoint design, conditional data fetching
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Unified CandidateProfile.jsx handles both incumbents and challengers at `/candidate/:id`. All candidate cards on Election Central route here regardless of incumbent status.
- **D-02:** When a candidate has a `politician_id` (incumbent), CandidateProfile fetches the full politician data — compass card, legislative summary, judicial record — achieving full parity with Profile.jsx. A state senator running for US Congress still shows their state legislative record.
- **D-03:** When a candidate has no `politician_id` (challenger), CandidateProfile renders only available data (name, photo, position sought, election banner) and skips legislative/compass API calls entirely — no empty loading states, no placeholder sections.
- **D-04:** CompassCard and Read & Rank verdict badge support are wired into CandidateProfile now. Both self-gate (only render when stance/quote data exists). Profiles look clean today and automatically light up when data is imported later.
- **D-05:** Actual compass stance research and quote collection for candidates is deferred to a future milestone.
- **D-06:** PROF-04 and PROF-05 (compass stances imported, sourced quotes imported) are not achievable in this phase — the profile UI wiring satisfies the architectural requirement, but data population is deferred.
- **D-07:** Ship with current race_candidates fields only (name, photo, position, incumbent flag). No new schema columns (bio_text, campaign_website) in this phase.
- **D-08:** Architecture should accommodate future enrichment — the profile renders whatever's available and hides what's not. But no enrichment pipeline work in this phase.
- **D-09:** All candidate cards on Election Central navigate to `/candidate/:id` using the race_candidates ID. Consistent URL pattern from the elections context.
- **D-10:** Back navigation uses the existing `ev:fromView` sessionStorage pattern (from Phase 99). If user came from Elections tab, back goes to Elections. If from Representatives, back goes to Representatives.

### Claude's Discretion
- How to detect politician_id linkage from race_candidates and conditionally fetch full vs minimal data
- Loading skeleton design for candidate profiles
- How PoliticianProfile (ev-ui) handles the minimal-data case for challengers
- Whether to add a candidate-specific API endpoint or extend the existing fetchPolitician to handle race_candidates IDs

### Deferred Ideas (OUT OF SCOPE)
- AI-assisted compass stance research for candidates
- Read & Rank quote collection for candidates
- bio_text and campaign_website columns on race_candidates
- Campaign website scraping pipeline
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROF-01 | User can view a full profile page for any candidate (same treatment as current officials) | CandidateProfile.jsx already exists at `/candidate/:id`; needs backend candidate-detail endpoint + routing fix for incumbents |
| PROF-02 | Candidate profiles include compass comparison card with user's calibrated data | CompassCard is self-gating on `politicianIdsWithStances`; add to CandidateProfile when politician_id is known |
| PROF-03 | Candidate profiles include Read & Rank verdict badges from sourced quotes | StanceAccordion already renders `verdictsByQuote` from CompassContext; same self-gating mechanism covers this |
| PROF-04 | Compass stances researched and imported for candidates in coverage areas | Deferred by D-06 — UI wiring satisfies architectural requirement |
| PROF-05 | Sourced quotes collected and imported for candidates via existing quote pipeline | Deferred by D-06 — UI wiring satisfies architectural requirement |
</phase_requirements>

---

## Summary

Phase 101 is primarily a frontend wiring task with one new backend endpoint. The core work is: (1) a new backend endpoint `GET /api/essentials/race-candidates/:id` that returns race_candidates detail plus the linked `politician_id`, (2) fixing the routing in `ElectionsView.jsx` so all candidates go to `/candidate/:id` instead of splitting incumbents to `/politician/:id`, and (3) extending `CandidateProfile.jsx` to branch on `politician_id` presence — fetching full politician data for incumbents and rendering minimal data for challengers.

The existing `CandidateProfile.jsx` currently treats its `:id` param as a `politician.id` and calls `fetchPolitician(id)` directly. For Phase 101, the route URL will carry a `race_candidates.id` (UUID), so the page must first fetch the race candidate record (which returns `politician_id` if linked), then conditionally fetch politician detail. This is the single most important architectural change.

`PoliticianProfile` (ev-ui) defaults `politician = {}` and uses safe coalescing throughout — it renders gracefully with minimal data (name, photo_url). `CompassCard` is already self-gating via `politicianIdsWithStances.has(politicianId)`. No ev-ui changes are needed.

**Primary recommendation:** Add `GET /api/essentials/race-candidates/:id` in the backend, fix the ElectionsView routing, and branch CandidateProfile.jsx on the returned `politician_id`.

---

## Standard Stack

### Core (this phase)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React 19 | 19.x | UI component framework | Project standard for `essentials` |
| React Router v6 | 6.x | Client-side routing, `useParams`, `useNavigate` | Already in use — `App.jsx` routes defined here |
| Express 4 | 4.x | New backend route handler | Project backend standard |
| @chrisandrewsedu/ev-ui | latest | `PoliticianProfile`, `CompassCard`, `StanceAccordion` | Already consumed by CandidateProfile.jsx |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Zod | 3.x | Request validation for new backend route | Consistent with all other ev-accounts routes |
| Vitest + Supertest | latest | Integration test for new route | All new backend routes require CI-safe route wiring tests |

---

## Architecture Patterns

### Recommended Project Structure

No new directories required. Files modified/created:

```
ev-accounts/backend/src/
├── lib/electionService.ts            # ADD getCandidateById() query
├── routes/essentials.ts              # WIRE new /race-candidates sub-route
└── routes/essentialsPoliticians.ts   # (reference only, no changes)

essentials/src/
├── pages/CandidateProfile.jsx        # EXTEND — main work
├── components/ElectionsView.jsx      # FIX — route all candidates to /candidate/:id
└── lib/api.jsx                       # ADD fetchRaceCandidate(id)

ev-accounts/tests/integration/
└── essentials-elections.test.ts      # ADD route wiring test for new endpoint
```

### Pattern 1: Backend — Candidate Detail Endpoint

**What:** `GET /api/essentials/race-candidates/:id` returns the `race_candidates` row with its linked `politician_id` (nullable) and the race context (position_name, election_date).

**When to use:** CandidateProfile.jsx calls this on mount, then decides what additional data to fetch based on whether `politician_id` is non-null.

**Response shape:**
```typescript
// Returned by GET /api/essentials/race-candidates/:id
{
  candidate_id: string;         // race_candidates.id
  full_name: string;
  first_name: string | null;
  last_name: string | null;
  photo_url: string | null;
  is_incumbent: boolean;
  position_name: string;        // from races.position_name
  election_date: string | null; // from elections.election_date
  election_type: string | null;
  politician_id: string | null; // null = challenger, non-null = incumbent
}
```

**Implementation note:** This query joins `race_candidates → races → elections` and a `LEFT JOIN LATERAL` on `politician_images` for photo fallback. Follow the same pattern as `getElectionsByCoordinate` in `electionService.ts`.

**Route placement:** Add to `electionService.ts` as `getCandidateById`, wire via `essentials.ts` as `/race-candidates/:id`. Use `UUID_REGEX` validation identical to `essentialsPoliticians.ts`.

### Pattern 2: Frontend — Branched Data Fetching in CandidateProfile.jsx

**What:** CandidateProfile fetches race candidate detail first, then uses `politician_id` to branch fetches.

**When to use:** Always — the page now receives a `race_candidates.id` in the URL, not a `politician.id`.

**Example:**
```jsx
// Source: derived from Profile.jsx pattern + electionService data shape
useEffect(() => {
  if (!id) return;
  setLoadingProfile(true);

  (async () => {
    try {
      // Step 1: fetch race candidate detail (always)
      const candidate = await fetchRaceCandidate(id);
      setCandidateData(candidate);

      if (candidate.politician_id) {
        // Step 2a: INCUMBENT — fetch full politician + legislative + judicial + elections
        const [polResult, legSummary, jRecord] = await Promise.all([
          fetchPolitician(candidate.politician_id),
          fetchLegislativeSummary(candidate.politician_id),
          fetchJudicialRecord(candidate.politician_id),
        ]);
        setPol(polResult);
        setLegislativeSummary(legSummary);
        setJudicialRecord(polResult.is_judicial ? jRecord : null);
        setPolId(candidate.politician_id);
      } else {
        // Step 2b: CHALLENGER — build minimal pol object from candidate data only
        setPol({
          full_name: candidate.full_name,
          first_name: candidate.first_name,
          last_name: candidate.last_name,
          photo_origin_url: candidate.photo_url,
        });
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoadingProfile(false);
    }
  })();
}, [id]);
```

### Pattern 3: Routing Fix in ElectionsView.jsx

**What:** Remove the `isPolitician ? /politician/:id : /candidate/:id` split. All candidates route to `/candidate/:id` using `candidate.candidate_id`.

**Current code (line 189, 197-199):**
```jsx
// CURRENT — routes incumbents to /politician/:id
id={candidate.politician_id || candidate.candidate_id}
onClick={() => onCandidateClick(
  candidate.politician_id || candidate.candidate_id,
  !!candidate.politician_id
)}
```

**New code:**
```jsx
// NEW — always use race_candidates.id, always /candidate/:id
id={candidate.candidate_id}
onClick={() => onCandidateClick(candidate.candidate_id)}
```

**Results.jsx `onCandidateClick` handler** (line 1199-1206): remove `isPolitician` param, always navigate to `/candidate/${id}`.

### Pattern 4: CompassCard Integration for Incumbents

**What:** After Step 2a fetches data, render CompassCard using the `politician_id` (not the `candidate_id`). CompassCard's self-gate (`politicianIdsWithStances.has(politicianId)`) ensures it renders only when stances exist.

**Example (CandidateProfile render, within `incumbent` branch):**
```jsx
// Only rendered when politician_id is non-null
{polId && (
  <CompassCard
    politicianId={polId}
    politicianName={pol.full_name || `${pol.first_name} ${pol.last_name}`}
    politicianTitle={pol.office_title || candidateData?.position_name || ''}
  />
)}
```

### Pattern 5: Challenger Minimal Banner

**What:** For challengers, the "Candidate for [position]" banner uses `candidateData.position_name` and `candidateData.election_date` directly — no election API call needed (data comes from the race candidate detail endpoint).

### Anti-Patterns to Avoid

- **Passing politician_id as `:id` in the route URL:** The URL must carry `race_candidates.id`. The component resolves `politician_id` at runtime. Mixing these creates routing ambiguity.
- **Calling fetchPolitician(id) directly:** CandidateProfile.jsx currently does this. It must first call `fetchRaceCandidate(id)` to get `politician_id` before calling `fetchPolitician`.
- **Adding loading skeleton per section:** Profile.jsx and CandidateProfile.jsx use a single top-level spinner (`loadingProfile`). Maintain this pattern — one spinner for the whole profile, not per-section skeletons.
- **Showing empty sections for challengers:** The challenger branch must not render `CompassCard`, legislative summary, or judicial record. No null state messages needed — just omit the sections entirely.
- **Routing ElectionsView to `/politician/:id` for incumbents:** After this phase, `/politician/:id` is the explicit official profile. `/candidate/:id` is the elections-context profile. The split routing must be removed.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Compass stance gating | Custom "has stances" check | `politicianIdsWithStances.has(politicianId)` inside CompassCard | Already handles async loading, returns null automatically |
| Verdict badge rendering | Custom verdict UI | `verdictsByQuote` from CompassContext + StanceAccordion | Already wired — Read & Rank verdicts appear automatically in StanceAccordion |
| Minimal politician object | Custom challenger display component | Pass minimal data object to PoliticianProfile | PoliticianProfile defaults `politician = {}` and coalesces all fields safely |
| Election date formatting | Custom formatter | Reuse `formatElectionDateFull()` already in CandidateProfile.jsx | Consistent display, already handles timezone issues |

**Key insight:** The self-gating architecture (CompassCard, StanceAccordion) means PROF-02 and PROF-03 are satisfied by wiring alone — no data existence checks needed in the parent component.

---

## Common Pitfalls

### Pitfall 1: URL ID Mismatch
**What goes wrong:** CandidateProfile.jsx currently calls `fetchPolitician(id)` directly. After the routing change, `id` is a `race_candidates.id` (UUID), not a `politician.id`. `fetchPolitician` will return 404.
**Why it happens:** The current code was written when `/candidate/:id` was only reached via politician UUIDs.
**How to avoid:** The first fetch in the new CandidateProfile MUST call `fetchRaceCandidate(id)`. Only then use the returned `politician_id` for `fetchPolitician`.
**Warning signs:** 404 errors on `/api/essentials/politicians/:id` when navigating to a candidate profile.

### Pitfall 2: ElectionsView Still Splits Routing
**What goes wrong:** If ElectionsView.jsx still sends incumbents to `/politician/:id`, those profiles won't show the "Candidate for" election banner or the election context. The profile pages appear as regular official profiles, not candidate profiles.
**Why it happens:** ElectionsView currently passes `isPolitician ? /politician/:id : /candidate/:id` to the click handler. Easy to miss this as a required change.
**How to avoid:** Fix ElectionsView routing at the same time as CandidateProfile changes.
**Warning signs:** Clicking an incumbent on Election Central takes you to `/politician/:id` instead of `/candidate/:id`.

### Pitfall 3: Election Banner Broken for Incumbents
**What goes wrong:** Current CandidateProfile fetches elections via `/essentials/politicians/:id/elections`. For incumbents, we now have `politician_id` available, so this call still works — but the banner data (position sought, election date) comes from the race candidate detail endpoint, not the politicians elections endpoint.
**Why it happens:** Two sources of election truth: `race_candidates` (what race they're in now) vs `politician.elections` (full electoral history).
**How to avoid:** Use `candidateData.position_name` and `candidateData.election_date` for the primary banner. The `/elections` endpoint is optional enrichment for the incumbent's reelection context check.
**Warning signs:** Banner shows "Candidate for undefined" or missing election date.

### Pitfall 4: CompassCard Receives candidate_id Instead of politician_id
**What goes wrong:** `politicianIdsWithStances` is keyed by `politician.id`. If you pass `candidate_id` to `CompassCard.politicianId`, the gate check always fails and the card never renders — even when stances exist.
**Why it happens:** The component tracks two IDs: `candidateId` (URL param) and `polId` (derived from race candidate detail). It's easy to pass the wrong one.
**How to avoid:** Store `polId` as separate state. Only pass it to CompassCard. Never pass the URL `id` param to CompassCard.
**Warning signs:** CompassCard never appears even after stances are imported.

### Pitfall 5: Challenger Profile Shows Spinner Forever
**What goes wrong:** If the loading state starts as `true` but the challenger branch never triggers `setLoadingProfile(false)`, the profile spins forever.
**Why it happens:** Forgetting `finally { setLoadingProfile(false); }` in the challenger branch.
**How to avoid:** The `finally` block must always fire regardless of which branch executes.

---

## Code Examples

Verified patterns from existing codebase:

### New Backend Service Function (electionService.ts)
```typescript
// Pattern: follow getCandidatesByZip in candidateService.ts + electionService.ts joins
export async function getCandidateById(candidateId: string): Promise<CandidateDetail | null> {
  const queryText = `
    SELECT
      rc.id           AS candidate_id,
      rc.full_name,
      rc.first_name,
      rc.last_name,
      COALESCE(rc.photo_url, pi.url) AS photo_url,
      rc.is_incumbent,
      rc.politician_id,
      r.position_name,
      e.election_date,
      e.election_type
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    LEFT JOIN LATERAL (
      SELECT url FROM essentials.politician_images
      WHERE politician_id = rc.politician_id AND type = 'default'
      LIMIT 1
    ) pi ON rc.politician_id IS NOT NULL
    WHERE rc.id = $1
      AND rc.candidate_status != 'withdrawn'
  `;
  const { rows } = await pool.query(queryText, [candidateId]);
  return rows[0] ?? null;
}
```

### New Frontend API Function (api.jsx)
```javascript
export async function fetchRaceCandidate(id) {
  try {
    const res = await publicFetch(`/essentials/race-candidates/${id}`);
    if (!res || !res.ok) return null;
    return res.json();
  } catch (error) {
    console.error('Error fetching race candidate:', error);
    return null;
  }
}
```

### Existing Back Navigation Pattern (from CandidateProfile.jsx)
```javascript
onBack={() => {
  const fromView = sessionStorage.getItem('ev:fromView') || 'representatives';
  const viewParam = fromView === 'elections' ? '&view=elections' : '';
  try {
    const cached = sessionStorage.getItem('ev:results');
    if (cached) {
      const { query } = JSON.parse(cached);
      if (query) {
        navigate(`/results?q=${encodeURIComponent(query)}${viewParam}`);
        return;
      }
    }
  } catch { /* fall through */ }
  navigate('/');
}}
```

### Integration Test Pattern (essentials-elections.test.ts style)
```typescript
describe('GET /api/essentials/race-candidates/:id', () => {
  it('returns 422 for invalid UUID', async () => {
    const res = await request(app).get('/api/essentials/race-candidates/not-a-uuid');
    expect(res.status).toBe(422);
    expect(res.body).toMatchObject({ code: 'VALIDATION_ERROR' });
  });

  it('returns 404 for valid UUID that does not exist', async () => {
    const res = await request(app).get(
      '/api/essentials/race-candidates/00000000-0000-0000-0000-000000000000'
    );
    // With no DB: may 500 on connection; CI-safe pattern allows 404 or 500 gracefully
    expect([404, 500]).toContain(res.status);
  });
});
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Separate routing: incumbents → `/politician/:id`, challengers → `/candidate/:id` | Unified routing: all candidates → `/candidate/:id` | Phase 101 (this phase) | CandidateProfile must resolve politician_id at runtime |
| CandidateProfile uses politician UUID as URL param | CandidateProfile uses race_candidates UUID as URL param | Phase 101 (this phase) | New backend endpoint required |

---

## Open Questions

1. **Should `fetchRaceCandidate` use `publicFetch` or `apiFetch`?**
   - What we know: Current `fetchElectionsByAddress` uses `publicFetch` (no auth required). Candidate profiles are public-facing.
   - What's unclear: Whether any future enrichment fields would require auth.
   - Recommendation: Use `publicFetch` — consistent with election data access pattern. Auth can be added later.

2. **Does the `/api/essentials/race-candidates` route go in `essentials.ts` or a new route file?**
   - What we know: `essentials.ts` currently mounts `essentialsCandidates` (ZIP-based lookup) and `essentialsPoliticians`. It already has election routes.
   - Recommendation: Wire directly in `essentials.ts` as a new sub-router, or inline the route in `essentialsPoliticians.ts` (since it bridges elections and politicians). A separate `essentialsRaceCandidates.ts` route file avoids file bloat in essentialsPoliticians.

3. **What happens when `getCandidateById` returns null (e.g., invalid/withdrawn candidate)?**
   - What we know: The route should return 404. The frontend should show a "candidate not found" state.
   - Recommendation: Add a `notFound` state to CandidateProfile that renders a brief message and back button, matching the graceful pattern in Profile.jsx.

---

## Environment Availability

Step 2.6: SKIPPED — this phase is frontend/backend code changes only. No new external services, CLIs, or runtimes required beyond Node.js 20 and the existing Supabase PostgreSQL setup.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Vitest (v2.x) |
| Config file | `ev-accounts/backend/vitest.config.ts` |
| Quick run command | `cd ev-accounts && npm test -- --run tests/integration/essentials-elections.test.ts` |
| Full suite command | `cd ev-accounts && npm test -- --run` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROF-01 | `GET /api/essentials/race-candidates/:id` returns 422 for invalid UUID | unit | `cd ev-accounts && npm test -- --run tests/integration/essentials-elections.test.ts` | ❌ Wave 0 |
| PROF-01 | `GET /api/essentials/race-candidates/:id` returns 404 for unknown UUID | unit | same | ❌ Wave 0 |
| PROF-01 | CandidateProfile renders without errors for challenger (no politician_id) | manual | Navigate to `/candidate/:challenger-id` in browser | N/A |
| PROF-02 | CompassCard present in CandidateProfile DOM when politician_id exists | manual | Navigate to incumbent candidate profile, verify section renders | N/A |
| PROF-03 | StanceAccordion with verdictsByQuote renders for incumbent candidate | manual | Same as PROF-02 (StanceAccordion is inside CompassCard) | N/A |
| PROF-04 | (Deferred — UI wiring only) | — | — | N/A |
| PROF-05 | (Deferred — UI wiring only) | — | — | N/A |

### Sampling Rate
- **Per task commit:** `cd ev-accounts && npm test -- --run tests/integration/essentials-elections.test.ts`
- **Per wave merge:** `cd ev-accounts && npm test -- --run`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] Add `race-candidates` route wiring tests to `tests/integration/essentials-elections.test.ts` — covers PROF-01 route validation

*(Existing test infrastructure covers all other requirements — no new test files needed)*

---

## Sources

### Primary (HIGH confidence)
- Direct code inspection: `essentials/src/pages/CandidateProfile.jsx` — current state, existing patterns
- Direct code inspection: `essentials/src/pages/Profile.jsx` — parity target for incumbents
- Direct code inspection: `essentials/src/components/ElectionsView.jsx` — routing logic requiring fix (lines 189, 197-199)
- Direct code inspection: `essentials/src/components/CompassCard.jsx` — self-gating mechanism confirmed
- Direct code inspection: `ev-accounts/backend/src/lib/electionService.ts` — race_candidates query patterns, data shape
- Direct code inspection: `ev-ui/src/PoliticianProfile.jsx` — confirms safe defaults for minimal data
- Direct code inspection: `essentials/src/lib/api.jsx` — existing `fetchPolitician`, `fetchLegislativeSummary`, `fetchJudicialRecord` patterns
- Direct code inspection: `essentials/src/App.jsx` — confirms `/candidate/:id` route exists, CompassProvider wraps all routes

### Secondary (MEDIUM confidence)
- Direct code inspection: `ev-accounts/backend/src/routes/essentialsCandidates.ts` — confirms no existing `GET /race-candidates/:id` endpoint; UUID_REGEX pattern to reuse
- Direct code inspection: `ev-accounts/tests/integration/essentials-elections.test.ts` — test pattern for CI-safe route wiring tests

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already in use, no new dependencies
- Architecture: HIGH — all patterns derived from existing code, no external research needed
- Pitfalls: HIGH — identified from direct code inspection of routing/ID handling

**Research date:** 2026-03-30
**Valid until:** 2026-06-30 (stable codebase, no fast-moving external dependencies)
