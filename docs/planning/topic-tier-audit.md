# Topic Tier Audit

**Date:** 2026-04-11
**Spec:** docs/superpowers/specs/2026-04-10-local-officials-topic-scoping-design.md
**Purpose:** Drives the tier flag backfill in Plan A. Each row assigns one or more applicable tiers (`federal`, `state`, `local`) per topic. The backfill script (`backfill-topic-tier-flags.ts`) inserts one row per (topic, tier) pair into `inform.compass_topic_roles`.

## Review gate

Chris reviews this document and approves before the backfill script runs. Do not run the backfill until this has been explicitly approved.

## How to read the table

- **Tier flags** — which levels of government the topic is meaningfully answerable at. A topic can have 1, 2, or all 3 tiers.
- **Reason** — why this assignment. Principle-level topics work at all levels. Federal-program topics only work at federal (or federal + state when states routinely comment on federal policy).
- **Rewrite?** — flagged for future rewrite consideration via the workflow in Plan D. Does NOT get acted on in this plan. Flagged topics still get tier flags backfilled under their current framing.

## Audit table

| topic_key | Federal | State | Local | Rewrite? | Reason |
|---|:---:|:---:|:---:|:---:|---|
| healthcare | ✅ | ✅ | ✅ | 🔄 | Currently federally framed (single-payer vs ACA). Rewrite could make it cleanly multi-tier. Mark all three tiers now; rewrite later under the current framing produces some mis-scoring we accept as interim. |
| abortion | ✅ | ✅ |  |  | Federal and state both have meaningful policy roles. Local officials have no levers. |
| tariffs | ✅ |  |  |  | Irreducibly federal (Congress sets tariffs). |
| taxes | ✅ | ✅ | ✅ | 🔄 | Tax policy exists at all three levels but current framing is federally focused. |
| same-sex-marriage | ✅ | ✅ | ✅ |  | Federal constitutional question, state recognition, local non-discrimination ordinances. |
| religious-freedom | ✅ | ✅ | ✅ |  | Federal RFRA, state RFRAs, local ordinances. |
| trans-athletes | ✅ | ✅ | ✅ |  | Federal Title IX, state laws, local school district policies. |
| ukraine-support | ✅ |  |  |  | Federal foreign policy. |
| medicare/aid | ✅ |  |  |  | Federal programs. (States do administer Medicaid but stance questions are on the federal structure.) |
| fossil-fuels | ✅ | ✅ | ✅ |  | Federal energy policy, state regulation, local zoning and environmental review. |
| voting-rights | ✅ | ✅ | ✅ |  | Federal VRA, state election laws, local administration. |
| deportation | ✅ | ✅ | ✅ |  | Federal enforcement, state cooperation, local sanctuary policies. |
| social-security | ✅ |  |  |  | Federal program only. |
| ai-regulation | ✅ | ✅ |  | 🔄 | Primarily federal, state action on deepfakes/privacy emerging. Local angle is speculative — leave out for now. |
| climate-change | ✅ | ✅ | ✅ |  | All three levels have meaningful levers. |
| civil-rights | ✅ | ✅ | ✅ |  | Federal constitutional questions, state laws, local ordinances. |
| housing | ✅ | ✅ | ✅ |  | Federal HUD/LIHTC, state landlord-tenant and preemption, local zoning and inclusionary zoning. |
| campaign-finance | ✅ | ✅ | ✅ |  | Federal FEC, state disclosure, local lobbying rules. |
| immigration | ✅ | ✅ | ✅ | 🔄 | Federal core, state policy, local sanctuary. Rewrite candidate because current framing conflates several dimensions. |
| misinformation | ✅ | ✅ | ✅ |  | Federal platform regulation, state laws, local education policy. |
| redistricting | ✅ | ✅ |  |  | Federal and state — local redistricting (council districts) is genuine but rarely a compass-level issue. |
| school-vouchers | ✅ | ✅ | ✅ |  | Federal funding, state voucher programs, local school board implementation. |
| data-centers | ✅ | ✅ | ✅ |  | Federal energy/grid, state utility regulation, local zoning and tax abatements. |
| homelessness | ✅ | ✅ | ✅ |  | Federal HUD, state funding, local shelter and enforcement decisions. |
| childcare | ✅ | ✅ | ✅ |  | Federal CTC and subsidies, state licensing, local zoning and facility support. |
| jail-capacity |  | ✅ | ✅ |  | State corrections and local jails. No federal role. |

## Summary

- 26 topics
- 18 apply at all three tiers
- 3 apply at federal + state (abortion, ai-regulation, redistricting)
- 1 applies at state + local only (jail-capacity)
- 4 federal-only (tariffs, ukraine-support, medicare/aid, social-security)
- 4 flagged as rewrite candidates (healthcare, taxes, ai-regulation, immigration)