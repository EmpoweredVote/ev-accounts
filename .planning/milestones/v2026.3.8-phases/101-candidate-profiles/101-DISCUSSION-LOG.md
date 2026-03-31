# Phase 101: Candidate Profiles - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-30
**Phase:** 101-candidate-profiles
**Areas discussed:** Profile page architecture, Compass & verdict data sourcing, Challenger profile content, Navigation & linking

---

## Profile Page Architecture

| Option | Description | Selected |
|--------|-------------|----------|
| Unified CandidateProfile | One page at /candidate/:id handles both incumbents and challengers. Detects politician_id and fetches full data accordingly. | |
| Merge into Profile.jsx | Eliminate CandidateProfile.jsx. Profile.jsx handles both /politician/:id and /candidate/:id. | |
| Keep fully separate pages | Profile.jsx for incumbents, CandidateProfile.jsx for challengers. Different pages based on status. | |

**User's choice:** Unified CandidateProfile with full parity goal — incumbents should get compass and legislative data. A state senator running for US Congress still shows their state legislative record.

| Option | Description | Selected |
|--------|-------------|----------|
| Full parity | CandidateProfile fetches everything Profile.jsx does when politician_id exists | ✓ |
| Compass + legislative only | Skip judicial record and campaign finance | |

**User's choice:** Full parity
**Notes:** The goal is feature parity with Profile.jsx for any candidate that has a linked politician record.

---

## Compass & Verdict Data Sourcing

| Option | Description | Selected |
|--------|-------------|----------|
| AI-assisted research | Use politician-stance-researcher agent, produce CSV for import-stances CLI | |
| Manual staging workflow | Volunteers enter via data-entry tool | |
| Hybrid approach | AI researches drafts, human reviews via staging | |

**User's choice:** AI-assisted research is the planned approach, but **deferred to a future milestone**. Not ready to get that data yet.

| Option | Description | Selected |
|--------|-------------|----------|
| Wire it up now | Add CompassCard and verdict badge support now, self-gating. Lights up when data arrives. | ✓ |
| Defer all compass/verdict UI | Don't add until data is ready | |

**User's choice:** Wire it up now
**Notes:** Self-gating components mean clean profiles today, automatic enrichment later.

---

## Challenger Profile Content

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal profile with election context | Name, photo, position, election banner. Compass/legislative self-gate away. | ✓ |
| Profile with bio placeholder | Same + "Help us fill in their profile" CTA | |
| Redirect to external source | Link to VoteSmart/Ballotpedia instead | |

**User's choice:** Minimal profile — clean and honest
**Notes:** Long-term plan is to pull in campaign website data, interview data, etc. Architecture should accommodate future enrichment. Legislative records obviously won't be available for first-time candidates.

| Option | Description | Selected |
|--------|-------------|----------|
| Ship with current fields | Use existing race_candidates data only | ✓ |
| Add bio_text + website columns now | Small schema change for manual entry | |

**User's choice:** Ship with current fields

---

## Navigation & Linking

| Option | Description | Selected |
|--------|-------------|----------|
| Always /candidate/:id | All candidate cards go to /candidate/:id. CandidateProfile detects politician_id. | ✓ |
| /politician/:id for incumbents | Different pages based on incumbent status | |
| Unified /profile/:type/:id | New URL pattern with type-based fetching | |

**User's choice:** Always /candidate/:id

| Option | Description | Selected |
|--------|-------------|----------|
| Context-aware back | Use existing ev:fromView sessionStorage pattern | ✓ |
| Always back to Elections | Since /candidate/:id is an elections concept | |

**User's choice:** Context-aware back (already implemented)

---

## Claude's Discretion

- Politician_id detection and conditional data fetching strategy
- Loading skeleton design
- PoliticianProfile (ev-ui) minimal-data handling for challengers
- Whether to add candidate-specific API endpoint or extend existing ones

## Deferred Ideas

- AI-assisted compass stance research for candidates (future milestone)
- Read & Rank quote collection for candidates (future milestone)
- bio_text and campaign_website schema columns (future milestone)
- Campaign website scraping pipeline (future milestone)
