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
| same-sex-marriage | ✅ | ✅ |  |  | Federal constitutional question (Obergefell), state recognition and licensing. Cities issue licenses as state-law implementation, not a local lever. Non-discrimination ordinances belong under civil-rights. |
| religious-freedom | ✅ | ✅ | ✅ |  | Federal RFRA, state RFRAs, local ordinances. |
| trans-athletes | ✅ | ✅ | ✅ |  | Federal Title IX, state laws, local school district policies. |
| ukraine-support | ✅ |  |  |  | Federal foreign policy. |
| medicare/aid | ✅ | ✅ |  | 🔄 | Topic conflates Medicare (federal-only) with Medicaid (federal-state joint program with real state levers: expansion decisions, optional benefits, reimbursement rates). Current framing is ambiguous and should be rewritten as "government-funded healthcare" in Plan D. |
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
| misinformation | ✅ | ✅ |  |  | Federal platform regulation (Section 230, FCC), state laws (deepfake statutes, social media restrictions). Local government has no meaningful policy lever — media literacy curriculum is education policy, not misinformation policy. |
| redistricting | ✅ | ✅ |  |  | Federal and state — local redistricting (council districts) is genuine but rarely a compass-level issue. |
| school-vouchers | ✅ | ✅ |  |  | Federal funding streams, state voucher programs. Local school boards advocate against/for voucher bills but do not create or administer them — advocacy is not jurisdiction. Stances from local officials still flow through the compass regardless. |
| data-centers | ✅ | ✅ | ✅ |  | Federal energy/grid, state utility regulation, local zoning and tax abatements. |
| homelessness | ✅ | ✅ | ✅ |  | Federal HUD, state funding, local shelter and enforcement decisions. |
| childcare | ✅ | ✅ | ✅ |  | Federal CTC and subsidies, state licensing, local zoning and facility support. |
| jail-capacity |  | ✅ | ✅ |  | State corrections and local jails. No federal role. |

## Summary

- 26 topics
- 15 apply at all three tiers
- 7 apply at federal + state (abortion, ai-regulation, redistricting, medicare/aid, school-vouchers, same-sex-marriage, misinformation)
- 1 applies at state + local only (jail-capacity)
- 3 federal-only (tariffs, ukraine-support, social-security)
- 5 flagged as rewrite candidates (healthcare, taxes, ai-regulation, immigration, medicare/aid)

## Principle (for reference)

Tier flags represent **actual jurisdiction** — which levels of government have real policy levers on the topic. They do NOT represent "who might comment on it" or "where voters want to see stances." Advocacy and commentary flow through the data layer regardless of tier flags: a local school board member's on-record position on state voucher legislation still appears on voters' compasses, even though school-vouchers is tagged federal+state only. Tier flags drive three things: the informational badge in the compass builder, the coverage-nudge callout on essentials results pages, and research prioritization. They do not gate compass rendering.