# Requirements: v2.16 National House Rep Stances (Tier 2)

**Milestone:** v2.16  
**Status:** Active  
**Last updated:** 2026-06-16

The 299 US House reps seeded in v2.15 (Tier 1) currently have ZERO compass stance data. This milestone gives a bounded first chunk — the 4 largest delegations (FL, NY, PA, IL = 87 reps) — sourced compass stances so they appear with alignment data in the representatives feed. Remaining ~212 reps continue in v2.17+.

**Hard constraints (project memory):**
- Run stance research at most **3 reps concurrently** (premium tier; was 1-2 on Pro). Never mass-parallel (8-13) — that causes rate-limit hits with empty output. Validate 3-concurrency on the FL wave (Phase 127); drop back if the old failure signature reappears.
- Every stance needs ≥1 REAL fetched source URL in `inform.politician_context`. NEVER infer stances from party affiliation. Honest-skip a topic if no documentable evidence is found.
- Embed the 1–5 stance scale texts per topic in each researcher prompt (direction varies by topic).
- ~21 compass topics, Chair methodology. Use the `research-stances` skill / `politician-stance-researcher` agent.

The 87 reps are `essentials.politicians` with `external_id BETWEEN -56999 AND -1000` and `representing_state IN ('FL','NY','PA','IL')`. Production DB = Supabase project `kxsdzaojfaibhuzmclfq`.

---

## House Rep Stances (USHS)

- [ ] **USHS-01**: Sourced stances + paired `inform.politician_context` rows (real fetched URLs) for all 27 FL House reps; honest-skip topics with no evidence; zero unsourced rows.
- [ ] **USHS-02**: Sourced stances + context for all 26 NY House reps; honest-skip where no evidence; zero unsourced rows.
- [ ] **USHS-03**: Sourced stances + context for all 17 PA House reps; honest-skip where no evidence; zero unsourced rows.
- [ ] **USHS-04**: Sourced stances + context for all 17 IL House reps; honest-skip where no evidence; zero unsourced rows.
- [ ] **USHS-05**: Phase-gate verify SQL — every in-scope rep (FL/NY/PA/IL, external_id -56999..-1000) has ≥1 sourced stance or a documented honest-skip; zero `politician_answers` rows lack a paired `politician_context` row with a real (non-placeholder) source URL.

---

## Future Requirements (deferred → v2.17+)

- Stance research for the remaining ~212 House reps (all other states): AL, AK, AZ, AR, CO, CT, DE, GA, HI, IA, ID, IN, KS, KY, LA, MI, MN, MS, MO, MT, NE, NV, NH, NJ, NM, NC, ND, OH, OK, RI, SC, SD, TN, VT, WA, WV, WI, WY.
- FEC finance summary for the newly-seeded House reps (FINA stream).

## Out of Scope

- The other ~212 House reps (→ v2.17+)
- FEC / campaign finance data (→ FINA stream)
- The 3 genuine House vacancies (FL-20, GA-13, TX-23) — no rep to research; auto-fill on a seed re-run after special elections
- Re-researching the 137 pre-existing reps (already have stances)

---

## Traceability

| Requirement | Phase |
|-------------|-------|
| USHS-01 | 127 |
| USHS-02 | 128 |
| USHS-03 | 129 |
| USHS-04 | 130 |
| USHS-05 | 131 |
