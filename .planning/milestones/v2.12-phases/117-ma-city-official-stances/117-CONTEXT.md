# Phase 117: MA City Official Stances — Context

**Gathered:** 2026-06-12
**Status:** Ready for planning
**Source:** User conversation

<domain>
## Phase Boundary

Research and ingest compass stance data for ~82 MA city officials across 7 cities that already have politician records and geofences in the DB. The politician records, government stubs, chambers, districts, and TIGER geofences are ALL already applied — this phase is stances only.

Cities in scope:
- **Boston**: 14 officials (Mayor Wu + 4 at-large + 9 district councillors)
- **Cambridge**: ~15 officials (9 City Council at-large + school committee)
- **Worcester**: 11 officials (Mayor Petty + 5 at-large + 5 district councillors)
- **Springfield**: 14 officials (Mayor Sarno + 8 ward + 5 at-large councillors)
- **Lowell**: 12 officials (council-manager model; City Manager + Mayor + 10 councillors)
- **Brockton**: 12 officials (Mayor Rodrigues + 7 ward + 4 at-large councillors)
- **Quincy**: 10 officials (Mayor Koch + 6 ward + 3 at-large councillors)

Total: ~88 politicians. Current stance count: 0 for all city officials.

</domain>

<decisions>
## Implementation Decisions

### Topic Scope
- D-01 [LOCKED]: Attempt ALL 44 compass topics for every official — do not pre-filter to "local" topics. Fetch live topic list and stance texts from DB using research-stances SKILL.md pattern.
- D-02 [LOCKED]: Expected yield is 10–14 stances per official on average. Many topics will honest-skip. That is correct behavior, not a gap.
- D-03 [LOCKED]: Use the Chairs methodology — every stance value must be calibrated against the specific stance text for that Chair position, not just directional lean.
- D-04 [LOCKED]: Every stance requires a real fetched source URL in inform.politician_context.sources[]. No placeholder URLs, no Wikipedia disambiguation pages, no non-specific landing pages.
- D-05 [LOCKED]: NEVER infer stances from party affiliation. If no documentable evidence exists for a topic, honest-skip it entirely (no row written).

### Research Methodology
- D-06 [LOCKED]: Use the /research-stances SKILL.md agent pattern (politician-stance-researcher subagent type). Run ONE agent at a time — never more than 2 in parallel (rate-limit protection per feedback memory).
- D-07 [LOCKED]: For each official, search: official city website bio, city council meeting votes, local newspaper archives (Boston Globe, Worcester Telegram, Springfield Republican, etc.), official social media statements, campaign sites.
- D-08 [LOCKED]: City officials are local-government scope but may have documented positions on federal/state topics (housing, climate, immigration). Research all 44 and let evidence determine coverage.

### Migration Pattern
- D-09 [LOCKED]: Each city gets its own migration file (or multiple per city if needed). Follow existing city stance migration pattern — ON CONFLICT DO UPDATE for both politician_answers and politician_context.
- D-10 [LOCKED]: Embed politician UUIDs via DB query before writing migration (same pattern as all prior stance migrations).
- D-11 [LOCKED]: Migration numbering starts at next available after 515. Check MAX(version) from supabase_migrations.schema_migrations before each wave.

### Wave Structure
- D-12: Batch by city. Suggested waves: W1 = Boston + Cambridge (highest-profile, most documented), W2 = Worcester + Springfield, W3 = Lowell + Brockton + Quincy.
- D-13: Each wave = research → review → migration → apply → verify. Do not apply a migration until stances are human-reviewed for accuracy.

### Verification
- D-14: Post-migration gate: SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id IN (city official ids) must be > 0 for each city after its wave.
- D-15: Every applied stance row must have a paired inform.politician_context row with sources array non-null and non-empty.

### Claude's Discretion
- Which officials within a city to research first (start with Mayor + most prominent council members)
- How to handle school committee members vs city councillors (same process, same 44 topics)
- Whether to split a wave if a single city has too many officials for one agent run

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing stance migration patterns (most recent city stances)
- `backend/migrations/256_berkeley_stances.sql` — Berkeley city stances pattern
- `backend/migrations/347_boston_government.sql` — Boston official roster (IDs, external_ids)
- `backend/migrations/351_worcester_government.sql` — Worcester official roster
- `backend/migrations/352_springfield_government.sql` — Springfield official roster
- `backend/migrations/353_lowell_government.sql` — Lowell official roster
- `backend/migrations/354_brockton_government.sql` — Brockton official roster
- `backend/migrations/355_quincy_government.sql` — Quincy official roster
- `backend/migrations/157_cambridge_government_chambers.sql` — Cambridge government
- `backend/migrations/159_cambridge_incumbents.sql` — Cambridge officials

### Skill
- `.claude/skills/research-stances/SKILL.md` — research-stances orchestrator (MUST READ — topic fetch, Chairs methodology, agent pattern, rate limiting)

### Project patterns
- `backend/migrations/515_richard_wells_stances.sql` — most recent stance migration (pattern reference)
- `.planning/STATE.md` — decisions log, migration numbering notes

</canonical_refs>

<specifics>
## Specific Details

**External IDs for DB lookup:**
- Boston range: -2507000001 to -2507000014 (Mayor Wu = -2507000001)
- Worcester range: -258200001 to -258200011 (Mayor Petty = -258200001)
- Springfield range: -256700001 to -256700014 (Mayor Sarno = -256700001)
- Lowell range: -253700001 to -253700012 (City Manager Golden = -253700001)
- Brockton range: -250900001 to -250900012 (Mayor Rodrigues = -250900001)
- Quincy range: -255574501 to -255574510 (Mayor Koch = -255574501)
- Cambridge: use separate query (migration 159)

**Scope note from user:** State legislature stances are being handled by the Essentials team separately. This phase is city officials only.

**Topic coverage expectation (from user):** "try for all 44 questions, even if we only land at 10-14 answered." This is the target, not a floor. Some officials may yield more (Boston Mayor Wu, Cambridge councillors who've been vocal); some may yield fewer.

</specifics>

<deferred>
## Deferred

- FEC/campaign finance data for MA city officials — separate phase (state campaign finance, not FEC)
- MA state executive stances (VAST-01 analog) — not in scope for this phase
- Additional MA cities beyond the 7 in scope — deferred to future milestone
- School committee stances — in scope for 44-topic attempt but if yield is very low, document and defer
</deferred>

---

*Phase: 117-ma-city-official-stances*
*Context gathered: 2026-06-12 via user conversation*
