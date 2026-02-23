# Phase 27: Cache-Only Candidates & Warmer Cleanup - Context

**Gathered:** 2026-02-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace all remaining BallotReady live API calls with database reads. Candidates come from cached election_records data, warmers are fully removed (not stubbed), the BallotReady provider is deregistered and deleted, and the lazy-fetch goroutine is removed. ZIP search is already gone (Phase 26). The transition is invisible to users.

</domain>

<decisions>
## Implementation Decisions

### Candidate toggle behavior
- Keep the toggle on the Essentials dashboard — users opt in to see candidates alongside elected officials
- When toggle is on, candidates appear mixed into their respective tier (Federal/State/Local), not in a separate section
- Candidates are visually distinguished with a small "Candidate" badge/tag on the card — same card style otherwise
- Show candidates even if some data is missing — name, party, office sought are sufficient; missing fields just don't appear
- Only currently running candidates should appear — past candidates are excluded entirely
- Add an `is_active` manual flag column to determine which candidates are currently running (set during data import, manually toggleable)

### Missing data handling
- Hide empty sections on politician profile pages — if no endorsements/stances/elections are cached, those sections simply don't render
- No lazy-fetch on profile view — profiles read from DB only, no background goroutine
- No fetch attempt of any kind — if data isn't cached, it's not shown

### Warmer and provider removal
- Remove warmFederal, warmState, warmLocal functions entirely — clean break, no stubs, no dead code
- Remove the BallotReady provider/client completely — delete initialization, config, and all related code
- Remove the lazy-fetch candidacy goroutine and its BallotReady dependency
- Drop cache tracking tables (zip_caches, federal_cache, state_caches) — nothing writes to them anymore
- Phase 29 will verify zero BallotReady references remain via grep audit

### Transition visibility
- Transition is invisible to users — no freshness indicators, no "last updated" dates
- No coverage gap handling needed for ZIP searches (already removed in Phase 26)
- Address search empty state already handled in Phase 26 ("representative data is not yet available for this area")
- Instant loading expected — all data from DB means no progressive loading needed

### Claude's Discretion
- Exact order of removal operations (warmers vs provider vs lazy-fetch)
- Database migration approach for dropping cache tables and adding is_active column
- How to handle any code that currently reads from cache tracking tables

</decisions>

<specifics>
## Specific Ideas

- The `is_active` flag on candidates should be a simple boolean column that can be set during data import and toggled manually — not date-based logic
- This is a removal-heavy phase: the goal is less code, not different code
- Everything should work from the database that was populated by prior BallotReady imports

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 27-cache-only-candidates-warmer-cleanup*
*Context gathered: 2026-02-22*
