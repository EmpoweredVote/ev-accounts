# Phase 120: Contested-Race Bio + Photo Authoring - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-16
**Phase:** 120-contested-race-bio-photo-authoring
**Areas discussed:** Candidate scope, Authoring workflow, Photo sourcing, Bio tone + voice

---

## Candidate Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Use Phase 117 feasibility output | Phase 117 should have produced a feasibility doc with a prioritized contested-race list. Start from that. | ✓ |
| Query DB for contested races | Run audit-112-candidates.ts or similar to get current state of stub candidates. | |
| I have a specific list | User already knows which candidates need bios/photos. | |

**User's choice:** Use Phase 117 feasibility output
**Notes:** None

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, supplement with DB audit | Cross-reference feasibility doc against current DB state. | ✓ |
| Feasibility doc is authoritative | Only work on candidates listed in feasibility output. | |
| You decide | Claude uses judgment. | |

**User's choice:** Yes, supplement with DB audit
**Notes:** None

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, Todd Young first | Sitting US Senator, highest visibility. | |
| No special priority | All contested-race candidates are equal priority. | ✓ |
| Prioritize by race visibility | Federal > State > County order. | |

**User's choice:** No special priority
**Notes:** None

---

## Authoring Workflow

| Option | Description | Selected |
|--------|-------------|----------|
| One-shot import script | TypeScript script reads prepared data file, inserts/updates DB directly. | ✓ |
| Staging review workflow | Use existing stagingService data-entry tool. | |
| Claude authors directly | Claude researches, drafts, writes DB records via script. | |

**User's choice:** One-shot import script
**Notes:** None

| Option | Description | Selected |
|--------|-------------|----------|
| Claude does the research + drafting | Claude researches, writes bio, finds photo, prepares import file. User reviews. | ✓ |
| I'll prepare the data file | User manually researches and creates JSON/CSV. | |
| Split: Claude researches, I review | Claude drafts, user edits/approves, script imports. | |

**User's choice:** Claude does the research + drafting
**Notes:** None

| Option | Description | Selected |
|--------|-------------|----------|
| Markdown table in a review doc | .md file with name, bio, photo URL, source per candidate. | ✓ |
| JSON file with comments | Import data file with source URLs as metadata. | |
| You decide | Claude picks format. | |

**User's choice:** Markdown table in a review doc
**Notes:** None

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, capture methodology during this phase | Document sourcing approach, tone, constraints — reusable for Phase 124. | ✓ |
| No, just get bios done | Phase 124 can define its own methodology. | |

**User's choice:** Yes, capture methodology during this phase
**Notes:** Phase 124 success criteria explicitly requires a methodology doc.

---

## Photo Sourcing

| Option | Description | Selected |
|--------|-------------|----------|
| Official > Campaign > Social > News | Most authoritative to least authoritative source hierarchy. | ✓ |
| Whatever's highest quality | Best photo regardless of source. | |
| You decide | Claude uses judgment. | |

**User's choice:** Official > Campaign > Social > News
**Notes:** None

| Option | Description | Selected |
|--------|-------------|----------|
| Use ev-ui missing-photo fallback | Existing placeholder renders. Move on without a photo. | ✓ |
| Block on photo | Don't import until photo found. | |
| Generate a placeholder initial | Styled initial/avatar as step up from generic fallback. | |

**User's choice:** Use ev-ui missing-photo fallback
**Notes:** Consistent with Phase 117 D-12.

| Option | Description | Selected |
|--------|-------------|----------|
| Claude downloads + uploads to Supabase | Full pipeline matching existing Phase 117 D-13 pattern. | ✓ |
| Record URLs, upload manually | Claude finds URLs, user uploads. | |
| Script handles upload | Import script downloads and uploads programmatically. | |

**User's choice:** Claude downloads + uploads to Supabase
**Notes:** None

---

## Bio Tone + Voice

| Option | Description | Selected |
|--------|-------------|----------|
| Neutral factual | Dry, objective facts. Example: "Monroe County educator and longtime community volunteer seeking County Council District 3 seat." | ✓ |
| Warm but neutral | Slightly more human but still nonpartisan. | |
| Template-based | Fixed sentence structure filled per candidate. | |

**User's choice:** Neutral factual
**Notes:** None

| Option | Description | Selected |
|--------|-------------|----------|
| No party mention | Consistent with antipartisan principle. | |
| Include party if factual | Party is public record from clerk filings. | |
| You decide | Claude applies antipartisan principle. | |

**User's choice:** (Free text) No party mention in general, but OK to mention if it's part of someone's actual job or service history (e.g., "president of Monroe County Democrats"). Minimize party mentions as much as possible.
**Notes:** Nuanced antipartisan stance — party is acceptable only as professional/service background, not as political identifier.

| Option | Description | Selected |
|--------|-------------|----------|
| Office-title-only bio | "Candidate for [office title]." fallback from Phase 117 D-06. | ✓ |
| Leave bio null | Profile renders without one. | |
| Flag for manual research | Mark candidate for user to fill in. | |

**User's choice:** Office-title-only bio
**Notes:** Consistent with Phase 117 D-06.

---

## Claude's Discretion

- Import data file format (JSON vs CSV)
- Import script location and naming
- Batch vs individual import processing
- Methodology doc format and location
- Source citation column choice

## Deferred Ideas

None — discussion stayed within phase scope
