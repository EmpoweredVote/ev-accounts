# Phase 164: KY + OR + CT + OK + AR + IA + KS + MS Candidate Seeding - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-06
**Phase:** 164-ky-or-ct-ok-ar-ia-ks-ms-candidate-seeding-create-elections-r
**Areas discussed:** CT convention field scope, Unconfirmed-candidate policy, State ordering / urgency, OR reuse + open windows

---

## CT convention field scope

| Option | Description | Selected |
|--------|-------------|----------|
| All convention+petition qualified | Seed every convention-endorsed, 15%-threshold-qualified, and petitioned primary candidate as PROVISIONAL, incl. incumbents who lost endorsement (Larson CT-1). 167 culls after Aug-11. | ✓ |
| Endorsed + serious challengers only | Endorsees + 15%-threshold challengers, skip petition-only entrants. | |
| General-ballot best-guess only | Treat endorsees as de-facto nominees, non-provisional. | |

**User's choice:** All convention+petition qualified (recommended)
**Notes:** Matches the MN/MO full-pre-primary-field rule from Phase 162; applies to KS as well. → D-01/D-01a.

---

## Unconfirmed-candidate policy

| Option | Description | Selected |
|--------|-------------|----------|
| Concrete-signal in, rumor out | Seed provisionally (with note) any candidate with a concrete signal (FEC Statement filed or convention roll-call/threshold); hold pure secondhand mentions for a 167 re-pull. | ✓ |
| Seed all provisionally | Include every flagged candidate as PROVISIONAL, let 167 prune. | |
| Hold all until verified | Exclude all four unconfirmed until a directly-fetched source confirms. | |

**User's choice:** Concrete-signal in, rumor out (recommended)
**Notes:** Applies to CT Bueno/Botelho/Cerreta/Miressi flags; re-verify each at seed time against a directly-fetched source before finalizing include/hold. → D-02/D-02a.

---

## State ordering / urgency

| Option | Description | Selected |
|--------|-------------|----------|
| Urgency-first: KS→CT→decided | Late-primary states first by deadline, then OR-reuse quick win, then decided states. | |
| Cheapest-first: OR→decided→late | OR reuse + decided first, late-primary last. | |
| You decide at plan time | Planner sequences within per-state-vertical-slice + push-per-state conventions. | ✓ |

**User's choice:** You decide at plan time
**Notes:** Delegated to planner. Recommendation recorded as non-binding guidance (KS→CT→OR→remaining decided; mirrors MO→MN→decided in 162). → D-06.

---

## OR reuse + open windows

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse races, defer late-filers to 167 | Reuse OR's 6 existing race_ids, dedup pre-existing race_candidates, defer Aug-25 window to 167. | ✓ |
| Reuse races, re-pull OR before phase close | Same reuse + within-phase Aug-25 re-pull date-gate. | |

**User's choice:** Reuse races, defer late-filers to 167 (recommended)
**Notes:** Same as MD-162 / MA-161 existing-race reuse + open-window→167 deferral. → D-03/D-03a.

---

## Claude's Discretion

- End-to-end state sequencing (D-06 — recommendation given, planner decides).
- Final concrete-vs-rumor include/hold split per unconfirmed CT candidate (D-02, re-verify at seed time).
- Plan count/splitting, gate assertion set + coordinate smoke, per-state migration authoring details.

## Deferred Ideas

- Phase 167 re-pull queue: CT Aug-11 cull, KS Aug-4 cull, OR Aug-25 window, KY/OK/AR/IA/MS late independents, HELD unconfirmed-CT candidates.
- Phase 164.1 polygon refresh (does NOT touch this group's states).
- Partial-incumbent stance top-up (out of v2.22 scope).
- Challenger finance_summary (out of scope).
