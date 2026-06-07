# Phase 103 — Deletion Log (QUAL-02)

**Phase:** 103 — State Remediation — CA + MD
**Plan:** 02
**Migration:** 282 (supabase/migrations/20260606000005_282_ca_state_source_remediation.sql)
**Produced:** 2026-06-06

## Notes

Methodology applied (CONTEXT.md D-06): Delete if no real specific URL was found by the research-stances
agent, regardless of the current value. No "directional keep" — if research found no verifiable source
for a topic, the stance is deleted. No party-affiliation inference was used at any point (QUAL-01 rule).

All 6 deletions below represent topics where the research agent exhausted available public sources and
found no specific (non-homepage) URL. CA state senators/executives have no direct votes on federal-level
topics (social-security, ukraine-support); weak state-homepage-only sourcing for religious-freedom
topics was not upgradeable to a specific position page in a single research pass per D-06.

Research agents dispatched one at a time (11 sequential dispatches, alphabetical). Each agent received
the live stance scale embedded in the prompt (SKILL.md Step 0 requirement).

## Deletions

| politician full_name | topic_key | former value | reason |
|----------------------|-----------|--------------|--------|
| Eloise Gómez Reyes | religious-freedom | 3 | no evidence found |
| Eloise Gómez Reyes | ukraine-support | 2 | no evidence found |
| Henry Stern | religious-freedom | 3 | no evidence found |
| Henry Stern | social-security | 2 | no evidence found |
| Henry Stern | ukraine-support | 2 | no evidence found |
| Rob Bonta | ukraine-support | 2 | no evidence found |

**Total deletions: 6**

Cross-check: 12 CSV rows (upserts) + 6 deletions = 18 = Plan 01 flagged-stance count ✓
