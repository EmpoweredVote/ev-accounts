# Phase 117: Candidate Stub Resolution + Data Import - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-14
**Phase:** 117-candidate-stub-resolution-data-import
**Areas discussed:** Feasibility gate process, Data sourcing strategy, Candidate-vs-politician model, Photo + bio minimum bar

---

## Feasibility gate process

### Q1: What form should the feasibility evaluation take?

| Option | Description | Selected |
|--------|-------------|----------|
| Spreadsheet per stub | Row-per-candidate CSV with columns for sources/data found/confidence | |
| Tiered markdown doc | FEASIBILITY.md grouping candidates into Confirmed/Partial/Unsourceable with scope-down list | ✓ |
| Both — CSV + summary MD | CSV as raw data plus short summary MD | |

**User's choice:** Tiered markdown doc
**Notes:** Planner-readable tiers preferred over row-per-row machine format.

### Q2: Who runs the feasibility evaluation?

| Option | Description | Selected |
|--------|-------------|----------|
| Claude does real sourcing | Actually hits clerk filings, candidate sites, press for each stub | ✓ |
| Research agent availability check only | Confirms plausible sources exist without extracting | |
| Hybrid: agent inventory, Claude extracts contested-only | Split by race tier | |

**User's choice:** Claude does real sourcing
**Notes:** Wants actual data inventory, not just "might be possible" checks.

### Q3: April 25 go/no-go criteria?

| Option | Description | Selected |
|--------|-------------|----------|
| % sourced threshold | Hard numeric cutoff | |
| Contested-race coverage only | 100% of contested races must be sourceable | |
| Planner's call during discussion | Review feasibility artifact together, decide then | ✓ |

**User's choice:** Planner's call during discussion
**Notes:** Wants flexibility to judge data quality, not just counts.

---

## Data sourcing strategy

### Q1: Source priority order?

| Option | Description | Selected |
|--------|-------------|----------|
| Clerk filing first | Monroe County Clerk CAN-2 filings as authoritative for name/office | ✓ |
| Candidate site first | Candidate website/FB most likely to have photo + bio together | |
| Whatever's richest per-candidate | No fixed priority, document source per field | |

**User's choice:** Clerk filing first
**Notes:** Authoritative source for name/office spelling; photo/bio fall to candidate sites and press.

### Q2: Fallback for candidates with no sourceable photo or bio?

| Option | Description | Selected |
|--------|-------------|----------|
| Placeholder + office-title-only bio | Ship minimum row so profile loads | ✓ |
| Exclude from import entirely | Don't import stubs that lack sources | |
| Import name + office, no placeholder asset | Let UI handle empty state | |

**User's choice:** Placeholder + office-title-only bio
**Notes:** Preserves contested-race coverage; minimum bar still meets CAND-03.

### Q3: AI drafting vs extraction?

| Option | Description | Selected |
|--------|-------------|----------|
| Pure extraction only | Verbatim snippets from named source | |
| Extraction + light compression | Compress source text, keep only facts present in source | ✓ |
| LLM-drafted from multiple sources | Synthesize across clerk/site/press | |

**User's choice:** Extraction + light compression
**Notes:** No new claims, source URL recorded. Hallucination risk before a primary is unacceptable.

---

## Candidate-vs-politician model

### Q1: How to handle address-leakage in Phase 117?

| Option | Description | Selected |
|--------|-------------|----------|
| Accept the leak until post-primary | Import as regular politicians, fix later | |
| Add is_candidate flag now, filter in address lookup | Migration + resolver filter, surgical | ✓ |
| Use race_candidates-only path (no politician rows) | Read directly from race_candidates when politician_id null | |

**User's choice:** Add is_candidate flag now, filter in address lookup
**Notes:** Fix the bug in the same wave that would otherwise make it worse.

### Q2: Backfill scope?

| Option | Description | Selected |
|--------|-------------|----------|
| New imports only, no backfill | Only Phase 117's 30 imports get the flag | |
| Backfill from race_candidates linkage | Any politician linked to race_candidates with is_incumbent=false gets is_candidate=true | ✓ |
| Defer backfill to follow-up phase | Column + filter + new imports only | |

**User's choice:** Backfill from race_candidates linkage
**Notes:** Closes broader pre-existing leakage in one pass; signal (is_incumbent=false) is already reliable.

---

## Photo + bio minimum bar

### Q1: Photo placeholder style?

| Option | Description | Selected |
|--------|-------------|----------|
| Neutral silhouette | Grayscale bust icon | |
| Initials on ev-coral background | First+last initial on brand color | |
| Reuse whatever ev-ui has today | Let planner check and reuse existing fallback | ✓ |

**User's choice:** Reuse whatever ev-ui has today
**Notes:** Don't introduce a new asset; rely on existing PoliticianProfile fallback.

### Q2: Photo asset hosting?

| Option | Description | Selected |
|--------|-------------|----------|
| Supabase Storage CDN (existing pattern) | Download → upload → store URL in politician_images | ✓ |
| Direct hotlink to source URL | Fastest but risks breakage | |
| CDN for sourced, client-rendered placeholder | Mixed approach | |

**User's choice:** Supabase Storage CDN (existing pattern)
**Notes:** Canonical pattern per CLAUDE.md; protects against source-site changes before May 5.

### Q3: 1-line bio content bar?

| Option | Description | Selected |
|--------|-------------|----------|
| One sentence, ~120-180 chars | Names profession or reason-for-running | ✓ |
| Fact-only: office + affiliation + one identifier | Bare facts, hardest to get wrong | |
| Variable length, human-authored feel | 2-3 sentences when source supports | |

**User's choice:** One sentence, ~120-180 chars
**Notes:** Fits profile card cleanly, consistent for QA.

---

## Claude's Discretion

- Exact column name / placement of source-citation field
- Staging workflow vs one-shot import script (planner decides after reviewing feasibility)
- Migration filename numbering
- SQL vs application-code location of the `is_candidate` filter

## Deferred Ideas

- Full candidate/politician table split (post-primary phase)
- Candidate Q&A / response tracking (v2026.5.x+)
- Withdrawn candidate status tracking (v2026.5.x+)
- Candidate discovery pipeline expansion (Phase 123+)
