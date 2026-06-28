# Feature Research

**Domain:** Civic election-race display — "show me my 2026 US House race" by address, inside an existing Elections experience
**Researched:** 2026-06-27
**Confidence:** HIGH (grounded in this repo's live election schema + feed service; external civic-tool norms from Ballotpedia/Vote411/BallotReady are MEDIUM)

> Supersedes the prior v2.18 State-Leaders FEATURES.md (archived context only).

## Context: What Already Exists (do not re-build)

The hard infrastructure is shipped and load-bearing for this milestone. Every feature below is scored against it.

| Existing capability | Where | Implication for v2.20 |
|---------------------|-------|------------------------|
| Election → race → candidate schema | `migrations/042_election_schema.sql` | `race_candidates` already supports incumbent-linked (`politician_id`) **and** challenger (`politician_id = NULL`, denormalized `full_name`/`photo_url`) rows. No schema change needed to add House candidates. |
| Address/coordinate → races feed | `electionService.getElectionsByCoordinate()` | A House race surfaces automatically once a `race` row exists for the user's `NATIONAL_LOWER` district. US House is **already geofence-matched** (district path), not statewide. |
| Grouping into elections→races→candidates | `electionGrouping.groupElectionRows()` | LEFT JOIN keeps **candidate-less races**; dedupes candidates; infers `district_type` from `position_name` ("u.s. house" → `NATIONAL_LOWER`). Empty/partial races already render. |
| Incumbent marker | `race_candidates.is_incumbent` | Table-stakes incumbent flag is **already in the payload**. |
| Headshot fallback | `COALESCE(rc.photo_url, pi.url)` in `RACE_SELECT` | Linked incumbents get their `politician_images` photo for free; challengers need `rc.photo_url` populated (find-headshots flow). |
| Stance link | `race_candidates.politician_id` | A candidate with a politician record carries compass stances + finance + bio. **The stance comparison depends entirely on this FK being set** for new challengers. |
| Visibility window | `ELECTION_VISIBILITY_WINDOW` | Generals show through Dec 31 of election year; primaries 30 days post-date. Undecided→decided transition is **time-driven, not a manual flip**. |
| Antipartisan invariant | schema comment + `electionService` header | Party lives on `races.primary_party` (primaries only), **never** on the candidate. House general candidate cards must not show party. |
| Withdrawn handling | `candidate_status IN ('active','withdrawn','filed')` | Withdrawn excluded from `getCandidateById`; feed shows active. |

**Net:** v2.20 is overwhelmingly a **data** milestone (seed candidate rows + headshots + stances + politician_id links). The only candidate for a code change is the surfacing question (elections-page vs representatives-feed) and the presentation states below — and most already have data-layer support.

## Feature Landscape

### Table Stakes (Users Expect These)

A resident enters an address and sees "my US House race." Missing these = the race feels broken or untrustworthy.

| Feature | Why Expected | Complexity | Notes / Dependency |
|---------|--------------|------------|--------------------|
| Race surfaces for the resident's address/district | The entire premise — "see MY race" | LOW | Works via `getElectionsByCoordinate` district path once a `race` row exists for the `NATIONAL_LOWER` geo. Pure data: seed the race + candidates. |
| Candidate card per candidate (name) | A race with no people is empty | LOW | `race_candidates.full_name` (denormalized for challengers). Existing. |
| Headshot per candidate | Faces make a ballot legible; absence reads as incomplete | MEDIUM | Incumbents free via COALESCE; challengers need `find-headshots` → `rc.photo_url` (or a politician record). Explicit milestone scope. |
| Incumbent marker | Voters anchor on "who has the seat now" | LOW | `is_incumbent` already in payload. Frontend must render the badge. |
| Race title / district label ("U.S. House — CA-12") | Voters must know *which* seat | LOW | `position_name`; `inferDistrictType` maps it to `NATIONAL_LOWER`. |
| Chairs-not-polarity stance per candidate, sourced | Core value vs a generic ballot lookup | HIGH (research, not code) | Depends on `politician_id` link → existing compass stance pipeline (do NOT rebuild). Federal 24-topic set. Honest-skip where no source. |
| Stance / compass comparison across the race's candidates | "How do they compare on what I care about" — the reason to use EV over Ballotpedia | MEDIUM | Multi-candidate compass overlay is a rendering concern (PROJECT.md: out-of-scope-no-schema). Data exists once each candidate is a politician record with answers. |
| Link to each candidate's full civic profile | Card is a teaser; users want depth | LOW | `getCandidateById` + existing politician profile route; needs `politician_id`. |
| Election date / "what's on the ballot when" | Voters need the when | LOW | `elections.election_date`; Nov 3 2026 general. |
| Graceful "no candidates yet / race not yet covered" state | Address resolves but data is thin — must not look like an error | LOW–MEDIUM | LEFT JOIN already keeps candidate-less races. Needs a deliberate empty-state string, not a blank card. (See state table.) |

### Differentiators (Competitive Advantage)

Align to PROJECT.md Core Value (sourced, antipartisan, compass-aligned).

| Feature | Value Proposition | Complexity | Notes / Dependency |
|---------|-------------------|------------|--------------------|
| Compass alignment to *the viewer* ("matches your answers on 7 of 9 topics") | Biggest reason to use EV over a static ballot — personal, not generic | MEDIUM–HIGH | Needs viewer's own compass responses (Connected tier) + candidate answers. Inform tier sees neutral chairs. Candidate-vs-self compare is a lighter path than the deferred COMP-05 user-to-user compare. |
| Sourced-stance transparency (every chair backed by a fetched URL) | Trust differentiator; "we show our work" | LOW (display) / HIGH (research) | `inform.politician_context.sources` already populated for incumbents; same pattern for challengers. Display the source link per stance. |
| Antipartisan candidate cards (no party color/label) | Reduces tribal snap-judgment; unique stance | LOW | Already enforced at schema/query. Frontend must resist adding party chips. |
| Finance summary on the card (FEC) | "Who's funding this race" at a glance | LOW–MEDIUM | `finance_summary` JSONB exists for federal politicians; populated only where the candidate has a politician record + FEC ID. Null-safe. Free for incumbents; challengers need FEC ingestion (existing flow) — likely a stretch/defer. |
| Seamless undecided→decided transition as primaries resolve | Same URL, no separate "results page" — the race just updates | LOW (data) | Time-driven via visibility window + re-seed post-primary. Milestone already plans "seed-now + re-check primaries." |
| "Open seat" / no-incumbent framing | Open seats are higher-information races; calling it out helps voters | LOW | Derive from a race having zero `is_incumbent=true` candidates. Display-only. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Party label / party color on candidate cards | "Voters want R vs D fast" | **Violates the antipartisan invariant** (enforced at schema + query). Re-introduces the tribal shortcut EV exists to dissolve. | Sourced stances + compass alignment. Party only appears structurally on `primary_party` for *primary* races, never general candidates. |
| Inferring stances from party to fill gaps | "Empty stances look incomplete" | Violates the project's hardest rule (chairs-not-polarity, no party inference). Produces fabricated data. | Honest-skip the topic. Show "no sourced position found" rather than a guessed chair. |
| Seeding primary-only / withdrawn / speculative candidates into the general field | "Be comprehensive" | Clutters the Nov-3 view with people who won't be on the ballot; out of scope per PROJECT.md. Visibility window + `candidate_status` exist to prevent this. | Seed only confirmed Nov-3 general-ballot candidates; re-check after FL Aug 18 primary. |
| Predicting / displaying a likely winner, polling, or odds | "Voters want to know who'll win" | Editorializing; not sourced civic fact; invites bias claims; no data source in the model. | Show the field neutrally. Link to official sources via existing `voter-info` (Google Civic) proxy. |
| Live results / vote counts on election night | "Real-time everything" | Out of domain (pre-election information tool); no ingestion path; high op-cost for an unfunded nonprofit. | Visibility window already carries the general through Dec 31; results are a separate future track. |
| Showing every ballot-qualified write-in / micro-party candidate | "Completeness" | Long-tail candidates often have no fetchable record → empty cards or inference. Dilutes the comparison. | Scope to major-party nominees + ballot-qualified independents/third-party (PROJECT.md Wave-1 definition). Document the cutoff. |
| Hard-failing (error/blank) when a district's candidates aren't covered yet | Seems like correct "no data" behavior | Address resolved successfully — a blank/error reads as a bug and erodes trust at the worst moment. | Deliberate partial-coverage empty state (state table). The feed already returns the race shell. |

## State-by-State Presentation (the explicit asks)

Four presentation states the requirements author must specify. All four have **existing data-layer support**; the work is frontend rendering rules + seed discipline.

| State | Trigger (data condition) | Expected user-facing behavior | Code/data dependency |
|-------|--------------------------|-------------------------------|----------------------|
| **Decided general field** | `election_type='general'`, ≥2 active candidates, primaries concluded | Full side-by-side: each card with headshot, incumbent badge, stances, compare. Target experience. | Pure data: seed confirmed Nov-3 candidates + headshots + politician_id + stances. |
| **Undecided / primary not yet held** | General race exists but field not final (e.g. FL pre–Aug 18), OR a `primary` race is currently in-window | Either (a) **don't surface a half-empty general** — show "candidates set after the [date] primary"; or (b) show the `primary` race with `primary_party` framing. **Recommendation:** seed the known field now, label "field finalizes after [primary date]," avoid implying completeness. Time-driven re-seed flips to "decided" with no code change. | `ELECTION_VISIBILITY_WINDOW` + `primary_party`. Milestone "seed-now + re-check primaries" already assumes this. |
| **One covered candidate** (others uncovered) | Race has candidates but only some have headshot/stances/politician_id | Show the covered candidate fully; show the uncovered opponent's **name + headshot if available** with an honest "stances not yet researched" note — never hide the opponent (hiding reads as endorsement). Do NOT inference-fill. | `race_candidates` rows can exist without `politician_id`/stances. Needs a per-candidate "coverage pending" indicator. |
| **Uncontested race** | Exactly one active candidate, `seats=1` | Display the single candidate, labeled "running unopposed" / "uncontested." Still show their stances. | Derive from candidate count vs `seats`. Display-only. |
| **District resolves, race not covered at all** | Address → valid `NATIONAL_LOWER` district, but no `race`/candidates seeded (non-Wave-1 state, or a Wave-1 district not yet done) | **Not an error.** Show "Your U.S. House district is CA-NN. Candidate coverage is coming." Keep the resident's *incumbent* visible (already in the representatives feed) so the address still feels productive. Offer the `voter-info` official-links fallback. | Feed returns the race shell or nothing; frontend must distinguish "no race row" from "race row, no candidates." Most likely **small code/UX change** in the milestone. |

## Feature Dependencies

```
[House race surfaces by address]
    └──requires──> [race + race_candidates rows seeded]   (DATA — new work)
                       └──requires──> [NATIONAL_LOWER geofence]  (EXISTS — all 435 districts)

[Chairs-not-polarity stance per candidate]
    └──requires──> [candidate has politician_id]   (DATA — link/create record)
                       └──requires──> [compass stance pipeline]  (EXISTS — do not rebuild)

[Headshot on challenger card]
    └──requires──> [rc.photo_url populated]   (DATA — find-headshots flow, EXISTS)

[Compass alignment to the viewer]
    └──requires──> [candidate answers]  AND  [viewer's own compass responses]  (Connected tier)

[Finance summary on card]
    └──requires──> [candidate politician record + FEC ingestion]  (EXISTS for federal; stretch for new challengers)

[Undecided→decided transition]
    └──driven-by──> [ELECTION_VISIBILITY_WINDOW + post-primary re-seed]  (EXISTS + scheduled data work)

[Antipartisan card] ──conflicts──> [Party label/color]   (schema-enforced: party only on races.primary_party)
[Inferred-from-party stance] ──conflicts──> [chairs-not-polarity invariant]   (project hard rule)
```

### Dependency Notes

- **Stance comparison requires `politician_id`:** A challenger card with only a denormalized name renders, but carries no stances/finance/profile. Stance work and record-linking are the same gate — PROJECT.md already anticipates a plan-time stance-gap diagnostic.
- **Headshot and stance are independent:** A candidate can have a headshot but no stances (and vice-versa). The "one covered candidate" state is per-attribute coverage, not all-or-nothing.
- **Surfacing path is the one open code question:** Elections-page vs representatives-feed. The election feed already district-matches US House, so the elections page likely needs **no** code change; surfacing inside the representatives feed (if desired) would. STACK/ARCHITECTURE research should resolve this — FEATURES assumes the elections-page path is pure data.

## MVP Definition

### Launch With (v2.20 Wave 1 — CA/TX/FL/NY, 144 districts)

- [ ] `race` + `race_candidates` rows for every Wave-1 district's Nov-3 general field — nothing surfaces without it
- [ ] Headshot per new challenger/open-seat candidate — faceless cards read as incomplete
- [ ] `politician_id` link (or new politician record) per candidate — gates stances/finance/profile
- [ ] Sourced federal-24-topic chairs-not-polarity stances per candidate, honest-skip where no source — core differentiator
- [ ] Incumbent badge + open-seat framing (display) — data already present
- [ ] Partial-coverage empty state for resolved-but-uncovered districts — prevents the "looks broken" failure
- [ ] Seed-now + post-primary re-check (FL Aug 18) — keeps the field honest as primaries resolve

### Add After Validation (v2.21+)

- [ ] States beyond top-4 delegations (deferred in PROJECT.md)
- [ ] Finance summary on challenger cards (FEC ingestion for new records) — stretch; null-safe already
- [ ] Viewer-personalized compass alignment ("matches you on N topics") — depends on Connected-tier responses

### Future Consideration (v2.x+)

- [ ] Multi-candidate compass overlay rendering (PROJECT.md out-of-scope, no schema change) — defer until base cards validate
- [ ] Pre-primary `filed`-candidate view — defer; risks clutter, not needed for a Nov-3 general view

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Race surfaces by address (seed candidates) | HIGH | LOW (data) | P1 |
| Sourced chairs-not-polarity stances | HIGH | HIGH (research) | P1 |
| Headshots for new candidates | MEDIUM | MEDIUM (data) | P1 |
| Incumbent / open-seat / uncontested framing | MEDIUM | LOW | P1 |
| Partial-coverage / not-covered empty state | HIGH | LOW–MEDIUM (UX) | P1 |
| Post-primary re-seed discipline | HIGH | LOW (process) | P1 |
| Viewer-personalized compass alignment | HIGH | MEDIUM–HIGH | P2 |
| Finance on candidate cards | MEDIUM | MEDIUM | P2 |
| Multi-candidate compass overlay | MEDIUM | MEDIUM | P3 |

## Competitor Feature Analysis

| Feature | Ballotpedia / Vote411 | BallotReady | Our Approach |
|---------|----------------------|-------------|--------------|
| Address → ballot | Yes (sample ballot lookup) | Yes | Yes — already shipped via coordinate/address feed |
| Party label | Yes, prominent | Yes | **No** — antipartisan; stances replace party |
| Candidate stances | Vote411 candidate Q&A; Ballotpedia survey | Issue positions | Sourced chairs-not-polarity, every answer a fetched URL |
| Incumbent marker | Yes | Yes | Yes (`is_incumbent`) |
| Uncontested handling | Labeled "uncontested" | Shown | Derive from candidate count vs `seats`; label unopposed |
| Personalized match | No (neutral) | Limited | Differentiator: compass alignment to the viewer (Connected) |
| Finance | External link | Some | Inline `finance_summary` (FEC) where available |

## Sources

- Repo: `backend/migrations/042_election_schema.sql` (election/race/candidate model, antipartisan rationale, `candidate_status`) — HIGH
- Repo: `backend/src/lib/electionService.ts` + `electionGrouping.ts` (feed surfacing, visibility window, district vs statewide, empty-race handling, photo COALESCE) — HIGH
- Repo: `backend/migrations/1072_seed_2026_statewide_general_candidates.sql` (live seeding convention: confirmed-only, incumbent link, held-back-until-certified) — HIGH
- `.planning/PROJECT.md` (v2.20 goal, Wave-1 scope, federal-24-topic, out-of-scope list, finance/compass-overlay deferrals) — HIGH
- MEMORY.md (chairs-not-polarity, no-inference-from-party hard rules) — HIGH
- [Ballotpedia Sample Ballot Lookup](https://ballotpedia.org/Sample_Ballot_Lookup) / [Uncontested races definition](https://ballotpedia.org/Election_results,_2025:_Uncontested_races_by_state) — MEDIUM (general civic-tool norms)

---
*Feature research for: 2026 US House candidate coverage in the Elections experience*
*Researched: 2026-06-27*
