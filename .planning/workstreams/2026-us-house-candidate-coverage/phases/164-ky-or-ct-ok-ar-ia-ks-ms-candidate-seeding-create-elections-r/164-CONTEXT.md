# Phase 164: KY + OR + CT + OK + AR + IA + KS + MS Candidate Seeding (create elections + races, then candidates) - Context

**Gathered:** 2026-07-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Seed the full 2026 US House ballot field for **KY (6) + OR (6) + CT (5) + OK (5) + AR (4) + IA (4) + KS (4) + MS (4) = 38 districts** — the **4th Wave-3 seeding phase**, continuing the USHC3-02/03/04/05 per-state pipeline established in Phases 161→162→163 (all shipped). Consumes the Phase-160 field table's `seeding_phase=164` slice (`160-field-table-p164.csv`) as the authoritative input.

**This group is structurally SIMPLER than 162/163: ZERO redistricting flags.** None of these 8 states are in the committed Phase-164.1 dual-map set (TN/MO/AL/LA/UT). Therefore the entire D-01 class from 162/163 **drops out** — no old-vs-new correspondence audit, no severe-district withholding, no 164.1 un-gate dependency. Every district surfaces normally on `/elections` for an in-district test coordinate.

**Primary-status split (Phase-160 resolved):**
- **Decided (6 states, 29 districts): KY, OR, OK, AR, IA, MS** — seed the confirmed Nov-3 general-ballot field (nominees + ballot-qualified minor-party/independent).
- **Late-primary (2 states, 9 districts): CT (Aug-11) + KS (Aug-4)** — seed the **full qualified pre-primary field marked `PROVISIONAL:`**, culled later by Phase 167.

Work: author `essentials.elections` + `essentials.races` for KY/CT/OK/AR/IA/KS/MS (**OR reuses its 6 pre-existing scaffolded `race_id`s** via `existing_race_id`), create new candidate records, wire `race_candidates`, headshots per new candidate, and federal-24 sourced stances (0-unsourced).

Pure data — no backend code (v2.22 milestone constraint).

**Out of scope:** the other 140 Wave-3 districts (Phases 161/162/163 shipped, 165 pending); the post-primary cull (Phase 167, date-gated — catches CT Aug-11 / KS Aug-4 primary losers, OR Aug-25 late-filers, KY/OK/AR/IA/MS late independents); the cross-state polygon refresh / dual-map design (Phase 164.1 — does NOT touch any state in this group); challenger `finance_summary`; Senate races.

</domain>

<decisions>
## Implementation Decisions

### CT convention→primary provisional field — cast the full qualified field
- **D-01:** CT qualifies primary candidates **through party conventions** (15%+ delegate threshold) **plus petition**, and all 5 CT districts are **late-primary (Aug-11)**. Seed **every convention-endorsed, 15%-threshold-qualified, AND petitioned primary candidate** as `PROVISIONAL:` — **including incumbents who lost the convention endorsement** (John B. Larson, CT-1, lost the endorsement to Luke Bronin 214-204 and faces a genuine 4-way Dem primary). "renominated" in the field table is PROVISIONAL for CT — do not treat convention endorsees as de-facto nominees. Phase 167 culls after Aug-11. This is the same full-pre-primary-field rule used for MN/MO (Phase 162) and applies to KS here too.
- **D-01a:** CT-1 four-way Dem primary field = Bronin (endorsed), Larson (incumbent, lost endorsement), Gilchrest (15%+ qualified), Fortune (petitioned, 3,743 sigs); Chai (R, unopposed). Seed all four Dem primary candidates.

### Unconfirmed-candidate policy — concrete-signal in, rumor out
- **D-02:** Several CT candidates are flagged in the field table as **"active status unconfirmed by any directly-fetched source"** (Luz Helena Bueno CT-4, Michele Botelho CT-5, Damon Lawrence Cerreta CT-4, and any similar). Rule: **seed provisionally (with an inline note) any candidate backed by a concrete signal** — a filed **FEC Statement of Candidacy**, OR **convention roll-call / 15%-threshold qualification**. **Hold pure secondhand-mention candidates** (no fetched filing/convention evidence) for a Phase-167 re-pull rather than seeding phantom names onto `/elections`. Document the include/hold judgment per candidate in the seed plan's provenance.
- **D-02a:** By this rule, FEC-filed candidates (e.g., Bueno filed 4/8/2026, Cerreta filed FEC candidacy) are IN as provisional-with-note; a candidate whose primary-ballot qualification is "unconfirmed by any directly-fetched source" AND has no FEC/convention signal (e.g., Botelho, described only in a two-way-primary report) is HELD. Re-verify each at plan/seed time against a directly-fetched source before finalizing the include/hold split — the field-table notes are the starting point, not the final word.

### OR existing-race reuse + open filing windows
- **D-03:** OR **reuses its 6 `existing_race_id` general races** (`160-field-table-p164.csv` carries all 6 UUIDs) — do NOT author new OR `races`. Confirm at plan time whether any OR `race_candidates` rows already exist (like MA-5/MA-7 in 161 and MD in 162) and do not duplicate them. Seed the confirmed OR general field now.
- **D-03a:** OR carries `filing_open_deadline=2026-08-25` (unaffiliated/minor-party window still open statewide). **Defer OR late-filers to Phase 167 reconciliation** — do NOT add a within-phase OR re-pull date-gate. Same pattern as MD's Aug-3 window (162 D-04a) and MA's Aug-25 window (161).

### External-ID collision handling — use audited safe sub-bands
- **D-04:** `160-negative-id-audit.csv` flags negative-ID band collisions for this group. New candidate external_ids MUST use the audited `safe_start_seq` per colliding district: **KY-1 → seq 200** (band 1-98 occupied), **OK-1 → seq 200** (band 1-43 occupied), **OR-1 → seq 14** (10-13 used), **KS-1 → seq 3**, **KS-2 → seq 10**. All other districts use the standard band start. **Re-verify 0 collisions per state against live DB before authoring** — the audit is the starting point; a fresh collision check is still mandatory (162 carried-forward standard).

### Open seats / non-returning incumbents — seed nominees, never reuse a departing incumbent as a candidate
- **D-05:** Verified departures in this slice (seed the new field, do NOT create a candidate row for the departing incumbent): **KY-4 Massie LOST his primary** (`nominee_status=lost-primary`; Ed Gallrein is the R nominee — Massie's `politician_id` is NOT a KY-4 candidate); **KY-6 Barr retired**; **OK-1 Hern retired**; **IA-2 Hinson retired**; **IA-4 Feenstra retired**. Incumbents who ARE renominated reuse their existing records by `(district_type='NATIONAL_LOWER', geo_id)` join (never recompute external_id) — zero duplicate `full_name` per state.

### State ordering & urgency — Claude's Discretion (planner decides)
- **D-06:** Operator delegated end-to-end state sequencing to the planner, within the locked conventions (per-state vertical slice: races → records → headshots → stances → push; **push each state to PROD as it completes**, never one mega-push). **Recommended sequence (non-binding guidance):** front-load the late-primary states by civic deadline — **KS (Aug-4) → CT (Aug-11)** — then OR-reuse as a cheap early win, then remaining decided states (KY/OK/AR/IA/MS). Mirrors MO→MN→decided in 162. Within each state, research incumbents + evidenced majors first, fringe filers last (161/162 D-03a).

### Carried forward (locked — do not re-litigate; from Phases 161/162/163 + milestone standing standards)
- Full provisional field seeded NOW marked `PROVISIONAL:` for late-primary states (CT/KS); only the cull (Phase 167) is date-gated.
- Full federal-24 sourced stances per candidate; **0-unsourced gate floor**; chairs-not-polarity; never party-inferred; honest-skip (per-topic or whole-record) only with a **written search trail**, whole-record skips gate-pinned; mandatory primary-source verification pass before every push.
- All incumbents in this group are `incumbent_top_up_tier=partial` per the field table (existing stances present). **Partial-tier incumbents are NOT topped up** (out of v2.22 scope — 154 D-02). Unlike 162's zero-tier incumbents, this group has **no zero-tier incumbents flagged** — so incumbent stance work is limited to any incumbent that is ALSO a genuinely-contested primary candidate needing current-cycle coverage; new challengers are the stance-research target set.
- `race_candidates`: non-null `politician_id`, `candidate_status='active'`, incumbents `is_incumbent=true`; NEVER party on the candidate card (`races.primary_party` only); NEVER `office_id IS NULL` on a House race.
- external_id band `-(state_fips*10000 + cd*100 + seq)` for new candidates; FIPS: **KY=21, OR=41, CT=09, OK=40, AR=05, IA=19, KS=20, MS=28** (see D-04 for collision sub-bands). Reuse (never recompute) incumbent ids — note existing incumbents use mixed legacy schemes (KY `-21001`, OR `-4102001`, CT `-9001`, OK `-40001`, AR `-5001`, IA `-19001`, KS `-20001`, MS `-28001`).
- Stance agents at **3-concurrency max**, first-wave output validation, exact 1–5 scale texts embedded per topic (`_TOPIC_SCALE_FULL.txt`); execute seeding plans **INLINE** (not via executor sub-agents); reserve agents for parallel stance research only. Headshots via find-headshots conventions — trust the auto-guard's first-name-mismatch rejection.
- Migrations idempotent (NOT EXISTS guards); pure-data changes need no deploy. Push each stance batch to PROD as it completes (stance CSVs are gitignored → PROD is the durable store; 161 resilience lesson). `cd /c/EV-Accounts/backend &&` in the same compound Bash call (cwd resets).

### Claude's Discretion
- Exact plan count/splitting (e.g., whether CT's or KS's provisional stance slice splits for checkpoint safety), gate assertion set (clone prior seeding-phase verify SQL style + coordinate smoke), per-state elections/races migration authoring details, end-to-end state sequencing (D-06 — recommendation given), the concrete-vs-rumor final include/hold split per unconfirmed CT candidate (D-02, re-verify at seed time) — researcher/planner decide within the conventions above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase-160 outputs (the authoritative input — this phase's slice)
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-field-table-p164.csv` — the 38-row field table (19 columns): full qualified field per district, `new_records_needed`, incumbent pid/external_id/stance-count/top-up-tier, `existing_race_id` (OR's 6), `nominee_status` (KY-4 lost-primary; KY-6/OK-1/IA-2/IA-4 retired), `field_status` (decided vs late-primary), `ballot_system`, `filing_open_deadline`, and the CT convention/contested + unconfirmed-candidate NOTEs and KY-1/OK-1 external-ID-collision NOTEs.
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-negative-id-audit.csv` — per-district collision counts + `safe_start_seq` (KY-1=200, OK-1=200, OR-1=14, KS-1=3, KS-2=10; D-04 source).
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-incumbent-map.csv` — incumbent → `politician_id` map + top-up tiers, all 38 districts.
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-FIELD-TABLE.md` — human view: per-state new-record counts, Phase-167 cluster table, open-window notes.
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/staging/p164-{KY,OR,CT,OK,AR,IA,KS,MS}.csv` — per-state agent provenance (source URLs, per-candidate notes).

### Prior seeding-phase precedent (the pattern this phase mirrors — most decisions inherit)
- `.planning/phases/162-in-md-mn-mo-candidate-seeding-create-elections-races-then-ca/162-CONTEXT.md` — MD existing-race reuse (the OR template here), late-primary provisional field (MN/MO → CT/KS), per-state vertical slices + push-per-state (D-03), open-window→167 deferral (D-04a → D-03a here), collision re-check standard.
- `.planning/phases/161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca/161-CONTEXT.md` — MA existing-race reuse + pre-existing race_candidates dedup (the OR dupe-check precedent); per-state vertical slices; uniform search depth.
- `.planning/phases/163-*/` seed + stance + gate SUMMARYs — most recent create-races → provisional-field → headshot → stance → mini-gate pipeline to clone; the 163-11 consolidated verify gate style.
- `.planning/phases/162-*/162-11 verify.sql` (`backend/scripts/162-verify.sql`) — mini-gate template (0-unsourced assertions, pinned skip sets, coordinate smoke) for the 38-district close.

### Milestone scope & methodology (locked)
- `.planning/ROADMAP.md` §Phase 164 — goal + 3 success criteria; §Phase 161 anchor note (USHC3-02/03/04/05 continuation); §Phase 164.1 (does NOT touch this group's states); §Phase 166 (consolidated 178-district gate, inherits this phase's 38).
- `.planning/REQUIREMENTS.md` — USHC3-02/03/04/05.
- `.planning/STATE.md` §v2.22 Execution Methodology — prod ref `kxsdzaojfaibhuzmclfq`, Path-B surfacing, race_candidates shape, full FIPS table, stance pipeline, external_id scheme.

### Pipeline templates & scripts
- `backend/data/stance-research/*/_TOPIC_SCALE_FULL.txt` — federal-24 topic set + exact 1–5 scale texts (embed per agent prompt).
- Prior seeding scripts (backend/data/stance-research): `_merge.ts`, `_push_uuid.ts` (new NULL-external_id path), `_push.ts` (existing) — only `_merge.ts` IN_SCOPE/OUT changes per state.
- `backend/src/lib/db.js` `pool` — canonical query path when MCP Supabase tokens expire.

### Skills
- `.claude/skills/` research-stances + find-headshots — pipeline rules, wrong-person guard.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- OR's 6 pre-existing scaffolded `race_id`s (`existing_race_id` column) — reuse like MD-162 / MA-161; no new OR races.
- `_merge.ts` / `_push_uuid.ts` / `_push.ts` (backend/data/stance-research pipeline) — per-candidate CSV → validate → merge → push; `_push_uuid.ts` for new candidates (NULL external_id path).
- Prior seeding migrations (161 WA/AZ/TN, 162 IN/MN/MO, 163 WI/CO/AL/SC/LA) — elections+races+politicians+race_candidates authoring shape to clone per state.
- Prior verify SQL (156/158/161/162/163 gates) — mini-gate + coordinate-smoke template for the 38-district close.

### Established Patterns
- Path-B surfacing: `/elections` reads `races` + `race_candidates`; geography via `office_id → districts.geo_id` + `ST_Covers` — pure data, no code.
- Provisional-field convention: `PROVISIONAL:` marker for CT + KS (MN/MO Phase-162 precedent).
- Existing-race reuse pattern (MD-162 / MA-161): wire candidates to `existing_race_id`, dedup pre-existing race_candidates, author no new races — reused for OR.
- Diagnostic-before-write: re-run collision + duplicate checks per state at plan time even though 160 pre-audited.

### Integration Points
- Phase 166 consolidated gate asserts across all 178 districts — this phase's 38 must satisfy the same assertions.
- Phase 167 clusters: CT (Aug-11) + KS (Aug-4) prune primary losers; OR (Aug-25) + KY/OK/AR/IA/MS late independents reconcile.
- **A parallel session works Phases 177/178 (Hillsboro/Tigard OR LOCAL offices) in this repo.** This phase touches OR **US House** (federal), not OR local offices — low collision risk, but coordinate before touching shared Oregon `politicians`/`politician_images` rows and avoid editing that session's dirs.

</code_context>

<specifics>
## Specific Ideas

- **CT convention specifics:** CT-1 Larson lost the Dem convention endorsement to Luke Bronin 214-204 (May-11-2026 convention) → genuine 4-way Aug-11 primary (Bronin/Larson/Gilchrest/Fortune). Ruth Fortune petitioned on with 3,743 signatures. Amy Chai (R) unopposed by acclamation. CT filing deadline 2026-08-05, primary Aug-11.
- **KY specifics:** KY-4 Massie LOST his primary (Ed Gallrein R nominee) — a Phase-160-flagged upset. KY-6 Barr retired (Ralph Alvarado R nominee). KY-1 and OK-1 external-ID band collisions → seq 200 sub-band (D-04).
- **KS specifics:** KS primary Aug-4 (filing deadline 2026-08-03); heavy multi-filer fields esp. KS-4 (11 candidates across R/D/L/I). All 4 districts late-primary provisional.
- **Open seats:** KY-4 (Massie lost), KY-6 (Barr retired), OK-1 (Hern retired), IA-2 (Hinson retired), IA-4 (Feenstra retired).
- **Unconfirmed CT candidates to re-verify at seed time:** Luz Helena Bueno CT-4 (FEC filed 4/8 → likely IN), Damon Lawrence Cerreta CT-4 (FEC filed → likely IN), Michele Botelho CT-5 (qualification unconfirmed, only in a two-way-primary report → likely HOLD), Daniel Miressi CT-4 (convention-qualified R → IN). Final split per D-02 after a directly-fetched check.
- **Source URLs:** KY = KY SoS CandidateFilings ASPX (may fetch-wall — cross-check Wikipedia); OR/OK/AR/IA/KS = Wikipedia 2026-House-elections pages; MS = Clarion-Ledger; CT = ctmirror.org / ctpublic.org / ctinsider.com (rich convention coverage).

</specifics>

<deferred>
## Deferred Ideas

- **Phase 167 re-pull queue for this group:** CT Aug-11 primary cull; KS Aug-4 primary cull; OR Aug-25 unaffiliated/minor-party window; KY/OK/AR/IA/MS late independents; the HELD unconfirmed-CT candidates (D-02) re-verified against a directly-fetched source.
- **Cross-state polygon refresh / dual-map (Phase 164.1, TN/MO/AL/LA/UT)** — committed, runs after this phase. Does NOT touch any state in this group; noted only because it is the next phase in sequence.
- **Partial-incumbent stance top-up** — all incumbents in this group are `partial` tier; top-up is out of v2.22 scope (154 D-02).
- **Challenger `finance_summary`** — out of scope per REQUIREMENTS.md; record no-FEC-ID rather than retry.

### Reviewed Todos (not folded)
None — no pending todos matched Phase 164.

</deferred>

---

*Phase: 164-ky-or-ct-ok-ar-ia-ks-ms-candidate-seeding-create-elections-r*
*Context gathered: 2026-07-06*
