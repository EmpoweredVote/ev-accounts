# Phase 160: Field Resolution + Stance-Gap Diagnostic - Research

**Researched:** 2026-07-03
**Domain:** Congressional field resolution across 38 states, DB diagnostic queries, external_id collision auditing, SQL gate authoring (Wave-3 analog of Phases 148/154, scaled 3-4x)
**Confidence:** HIGH (DB findings — all live-queried against prod `kxsdzaojfaibhuzmclfq`); MEDIUM (primary-date table — single-source NCSL fetch, spot-verified for 7 of 38 states)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Field-resolution research dispatched to per-state agents, max 3 concurrent, ordered by seeding-phase grouping (161's states first: WA/AZ/TN/MA, then 162's, ... 165's last).
- **D-01a:** Validate the first wave's output shape before continuing (same discipline as the stance pipeline).
- **D-01b:** DB-side diagnostics (incumbent map, stance-gap counts, external_id collision check, race pre-existence check) run **inline by the orchestrator first** — done in this research session; results below.
- **D-02 (walled sources):** Agents use unwalled routes only (official SoS/board-of-elections, r.jina.ai, raw wikitext, FEC API); flag unresolvable districts rather than guessing. Orchestrator runs a Playwright sweep over flagged residue at the end of each wave. No field row without a fetched source URL.
- **D-03 (filing-not-closed states):** States with an open filing period get `filing-open (deadline: YYYY-MM-DD)` tagged declared-so-far capture. Owning seeding phase re-pulls at execution time if the deadline has passed; otherwise seeds `PROVISIONAL:` and Phase 167 reconciles.
- **D-04 (nonstandard primary systems):** `decided`/`late-primary` classification augmented with a `ballot_system` tag: `standard` / `top-two` (WA) / `top-four-rcv` (AK) / `rcv-general` (ME) / LA's 2026 system (resolved below — RESEARCH finding: closed-primary plan cancelled, reverted to traditional fall open primary).
- **D-04a (RCV over-indulgence):** RCV races (AK, ME, + any discovered RCV jurisdiction) get deliberately maximal thoroughness — exhaustive field capture, flagged `rcv` in the field table, prioritized for Phase 165 (AK+ME).
- **D-05 (artifact packaging):** Mirror Phase 154's artifact shape — `160-field-table.csv` + `160-incumbent-map.csv` + `160-FIELD-TABLE.md`, with an added `seeding_phase` column (161-165), plus `ballot_system`, `rcv`, `filing-open (deadline)`, and nominee-status taxonomy columns.

### Carried Forward from Phase 154 / Roadmap (locked, do not re-litigate)

- Report-only, no top-up for **partial**-stance incumbents; **zero-stance incumbents ARE in scope** for downstream stance research (treated like new candidates) — new-candidate/zero-stance-incumbent scope only.
- Inclusion bar: every officially ballot-qualified candidate; exclude primary-only also-rans and uncertified write-ins.
- Vacancy/special-seated: resolve current officeholder AND 2026 nominee from official/results sources, never 2024 incumbency; post-v2.17 special-seated members = new-record needs; 7-value nominee-status taxonomy.
- Incumbent identity by `(district_type='NATIONAL_LOWER', geo_id)` join — never computed external_id.
- Read-only: no migrations, no INSERTs; output = artifacts + `160-verify.sql` asserting read-only facts.

### Claude's Discretion

- Field-resolution source choice per state, exact research-agent prompt template, per-wave artifact merge mechanics, the exact `160-verify.sql` assertion set, the Phase-167 primary-date-cluster output format.

### Deferred Ideas (OUT OF SCOPE)

- Partial-incumbent stance top-up; challenger FEC finance summaries; RCV-aware product surfaces (UI); v2.21 tail (159-05/06, PA independents, FL-153) — calendar-gated, separate from this phase.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| USHC3-01 | Verified 2026 ballot field resolved for 178 districts/38 states; primary-date classification; incumbent map + stance-gap baseline; collision-free negative external_id bands verified per state before insert. | Full 38-state district-count tally VERIFIED (178/178, 0 mismatches). Incumbent map + stance-gap baseline run live (below) — reveals the "already stanced" assumption is WRONG at scale (only 11/178 incumbents ≥24 stances). External_id collision check run live — 16/178 districts across 10 states DO collide with existing DB records under the naive formula (critical finding, see below). Primary-date table sourced from NCSL + spot-verified for 7 states via independent WebSearch; AL split-state and LA system-change discovered and documented. Pre-existing races/candidates discovered in 5-7 states (ME/MD/MA/NV/OR races; IN/UT/ME stale candidate rows) — directly contradicts the ROADMAP's "none of the 38 states have pre-seeded races" assumption and must be reconciled, not recreated. |
</phase_requirements>

---

## Summary

Phase 160 is the Wave-3 diagnostic, structurally identical to Phases 148/154 (read-only, no writes, produces the incumbent map + field table + verify.sql that every seeding phase depends on) but 1.6-4.7x larger in state count (38 vs 8) and district count (178 vs 113). Running the full D-01b diagnostic query set live against production this session surfaced **four findings that materially change the shape of the plan** relative to a naive scale-up of the Phase 154 template:

1. **The decided/late-primary split is nearly 50/50, not decided-majority.** As of today (2026-07-03), roughly **88 of 178 districts (20 full states + 3 of Alabama's 7) are already `decided`** (primary held) and **90 are `late-primary`** (17 full states + 4 of Alabama's 7 + Louisiana's sui generis system). This is the opposite of what the ROADMAP's framing implies ("primary-decided states seed the final field; late-primary states... seed the full qualified pre-primary field") — the reader could assume decided is the norm. It is not. Seeding Phase 161 (the anchor, WA+AZ+TN+MA) is **100% late-primary** — the anchor phase must establish the `PROVISIONAL:` pattern from day one, not the decided pattern.

2. **Alabama is not a single decided/late-primary state — it is split at the district level.** AL-3/4/5 held their primary May 19 (runoff June 16) and are DECIDED. AL-1/2/6/7 are re-running a **court-ordered special primary August 11, 2026** (mid-cycle redistricting, no runoff possible) and are LATE-PRIMARY. Any plan or field-table row that tags "Alabama" as one state is wrong.

3. **Louisiana's closed-primary plan for 2026 House races was cancelled.** [CITED: 270toWin, LA SoS] A U.S. Supreme Court ruling on Louisiana's congressional districts forced LA to abandon the May 2026 closed-party-primary format for Congress; House races revert to LA's traditional fall **open ("jungle") primary** — all candidates on the Nov-3 ballot regardless of party, majority wins outright, no separate spring primary. Qualifying period is **August 5-7, 2026**. LA's field cannot be resolved until qualifying closes.

4. **The ROADMAP's "none of the 38 states have pre-seeded 2026 House races" claim is false for at least 5 states.** ME (2 races), MD (8 races), MA (9 races), NV (4 races), and OR (6 races) already have `essentials.races` rows scaffolded on `2026-11-03` elections — the VA-in-Wave-2 pattern repeats here at 5x the scale. **NV additionally has 9 real `race_candidates` already wired** (including all 4 incumbents), and **ME, IN, and UT have stale primary-era `race_candidates` rows with a confirmed data-quality bug** (IN-9's four Democratic primary losers are incorrectly flagged `is_incumbent=true`, while the actual incumbent Erin Houchin is flagged `false`). The field table's `existing_race_id` column must NOT default to blank across the board — it must be populated per-district from a live query, exactly like VA in Phase 154.

Additionally, the **stance-gap baseline is far worse than the "already stanced" assumption**: of 178 mapped incumbents, only 11 have ≥24 federal stances (`done`), 154 are `partial` (1-23), and 13 are `zero` (MD's entire 8-member delegation, both ME reps, and 3 of IN's members). Per the carried-forward D-02 scope, the 13 `zero`-tier incumbents are IN SCOPE for full stance research downstream (treated like new candidates) — this is a real, non-trivial addition to Phases 162 (IN+MD) and 165 (ME) workload that the ROADMAP's "new work = challengers + open-seat candidates" framing does not mention.

Finally, the **external_id collision check reveals the negative-band formula `-(state_fips*10000 + cd*100 + seq)` is NOT inherently collision-free at Wave-3 scale**: 16 of 178 districts across 10 states (KY, OR, OK, KS, NV, NM, NE, ME, NH, MT) have pre-existing negative external_ids occupying the same computed integer space (from unrelated historical seeding efforts — MA state legislature, MA congressional delegation, Utah city council wards, Oregon county commissioner races, and ME's own Senate/House incumbents). KY-CD1 is nearly saturated: 98 of the 99 available `seq` slots (1-99) already collide.

**Primary recommendation:** Structure the plan as more than the 2-plan (DB wave + field-table wave) template Phase 154 used. Given the 5x scale and the discovered cross-cutting issues (collision audit, pre-existing-race reconciliation, AL split, LA nonstandard system), recommend: **Wave 1** — DB diagnostics at full 38-state scope (incumbent map + stance-gap + external_id collision audit + pre-existing race/candidate audit), all runnable now with the query patterns proven in this research; **Waves 2-6** — per-seeding-phase-group field-table assembly (161's 4 states, 162's 4, 163's 5, 164's 8, 165's 17) dispatched as research agents at 3-concurrency per D-01, in the exact 161→165 order; **Wave 7** — merge into the master `160-field-table.csv` + author `160-verify.sql` + `160-FIELD-TABLE.md`. This keeps each wave's agent dispatch small enough to validate before continuing (D-01a) while giving the planner clean per-group checkpoints matching the downstream seeding phases.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Incumbent-to-politician_id map (178 districts) | Database / Storage | — | Pure SELECT on `essentials.districts + offices + politicians`; verified live this session |
| Stance-gap diagnostic | Database / Storage | — | COUNT query on `inform.politician_answers`; verified live — 13 zero / 154 partial / 11 done |
| External_id collision audit | Database / Storage | — | New for Wave-3: must check the FULL computed range per district against existing negative IDs, not just assume the formula is clean (proven false for 16 districts) |
| Pre-existing race/race_candidates audit | Database / Storage | — | New for Wave-3: must check for existing races/candidates on ANY election_date (not just 2026-11-03) — ME/IN/UT have stale primary-era rows |
| Vacancy / retirement detection | Database / Storage | External (official results) | Query C pattern from Phase 148/154; cross-check against Ballotpedia's 2026 House retirement list (Hoyer/MD-5 confirmed retiring) |
| Field table authoring (primary-date classification + ballot field) | External (state SoS results, NCSL, Ballotpedia) | Database (carry incumbent_pid) | Research artifact; per-state primary dates + AL split + LA system change resolved this session |
| CSV artifact validation | API / Backend (Node/Python script) | — | Clone `diag-154-validate-field-table.py` pattern, scaled to 38-state EXPECTED map |
| Write-free SQL gate | Database / Storage | — | `DO $$ ... RAISE EXCEPTION` pattern; must assert the pre-existing-race baseline is the DISCOVERED one (5 states with races), not a blanket "0 races" claim |

---

## CRITICAL FINDING 1: The Decided/Late-Primary Split Is Nearly 50/50

As of **2026-07-03** (today), primary dates sourced from NCSL's 2026 State Primary Election Dates page [CITED: ncsl.org], spot-verified against 2+ independent sources for MD, MA, AZ, WA, AK, AL, LA:

| State | Primary Date | Status (Jul 3) | Ballot System | Confidence |
|-------|-------------|-----------------|----------------|------------|
| WA | Aug 4, 2026 | **late-primary** | top-two | HIGH [CITED: Ballotpedia, WA SoS via WebSearch] |
| AZ | Jul 21, 2026 | **late-primary** | standard | HIGH [CITED: Maricopa County, AZ SoS — moved from Aug to 2nd-to-last Tue in July by new law] |
| TN | Aug 6, 2026 | **late-primary** | standard | MEDIUM [NCSL] |
| MA | Sep 1, 2026 | **late-primary** | standard | HIGH [CITED: MA Legislature press release — moved to Sep 1 by statute] |
| IN | May 5, 2026 | **decided** | standard | HIGH [VERIFIED: DB has IN-9 primary races/candidates dated 2026-05-05] |
| MD | Jun 23, 2026 | **decided** | standard | HIGH [CITED: Ballotpedia, MD SoS, BallotReady — 3 independent sources] |
| MN | Aug 11, 2026 | **late-primary** | standard | MEDIUM [NCSL] |
| MO | Aug 4, 2026 | **late-primary** | standard | MEDIUM [NCSL] |
| WI | Aug 11, 2026 | **late-primary** | standard | MEDIUM [NCSL] |
| CO | Jun 30, 2026 | **decided** (3 days before build) | standard | MEDIUM [NCSL only — re-verify at execution, razor-close date] |
| AL | **SPLIT** — see Critical Finding 2 | **mixed** | standard | HIGH [CITED: multiple AL news sources] |
| SC | Jun 9, 2026 | **decided** | standard | MEDIUM [NCSL] |
| LA | No standard primary — see Critical Finding 3 | **late-primary-equivalent** | open/jungle (nonstandard) | HIGH [CITED: 270toWin, LA SoS] |
| KY | May 19, 2026 | **decided** | standard | MEDIUM [NCSL] |
| OR | May 19, 2026 | **decided** | standard | HIGH [VERIFIED: DB has OR races scaffolded on 2026-11-03, consistent with a resolved primary awaiting Nov general wiring] |
| CT | Aug 11, 2026 | **late-primary** | standard | MEDIUM [NCSL] |
| OK | Jun 16, 2026 | **decided** | standard | MEDIUM [NCSL] |
| AR | Mar 3, 2026 | **decided** | standard | MEDIUM [NCSL] |
| IA | Jun 2, 2026 | **decided** | standard | MEDIUM [NCSL] |
| KS | Aug 4, 2026 | **late-primary** | standard | MEDIUM [NCSL] |
| MS | Mar 10, 2026 | **decided** | standard | MEDIUM [NCSL] |
| NV | Jun 9, 2026 | **decided** | standard | HIGH [VERIFIED: DB has 4 races with 9 real candidates incl. all 4 incumbents wired on Nov-3 general] |
| UT | Jun 23, 2026 | **decided** | standard | HIGH [VERIFIED: DB has UT primary races (D+R split) dated 2026-06-23 with 12 candidates] |
| NM | Jun 2, 2026 | **decided** | standard | MEDIUM [NCSL] |
| NE | May 12, 2026 | **decided** | standard | MEDIUM [NCSL] |
| WV | May 12, 2026 | **decided** | standard | MEDIUM [NCSL] |
| ID | May 19, 2026 | **decided** | standard | MEDIUM [NCSL] |
| HI | Aug 8, 2026 | **late-primary** | standard | MEDIUM [NCSL] |
| ME | Jun 9, 2026 | **decided** | **rcv-general** | HIGH [VERIFIED: DB + CITED NBC News — RCV primary tabulated; Dunlap beat Golden's open seat primary field, LePage secured R nomination; Pingree ME-1 status needs execution-time re-check] |
| NH | Sep 8, 2026 | **late-primary** | standard | MEDIUM [NCSL] |
| RI | Sep 9, 2026 | **late-primary** | standard | MEDIUM [NCSL] |
| MT | Jun 2, 2026 | **decided** | standard | MEDIUM [NCSL] |
| AK | Aug 18, 2026 | **late-primary** | **top-four-rcv** | HIGH [CITED: Ballotpedia — top-four primary Aug 18, RCV general Nov 3] |
| DE | Sep 15, 2026 | **late-primary** | standard | MEDIUM [NCSL] |
| ND | Jun 9, 2026 | **decided** | standard | MEDIUM [NCSL] |
| SD | Jun 2, 2026 | **decided** | standard | MEDIUM [NCSL] |
| VT | Aug 11, 2026 | **late-primary** | standard | MEDIUM [NCSL] |
| WY | Aug 18, 2026 | **late-primary** | standard | MEDIUM [NCSL] |

**District-count math:** Decided (full states, 20) = IN9+MD8+CO8+SC7+KY6+OR6+OK5+AR4+IA4+MS4+NV4+UT4+NM3+NE3+WV2+ID2+ME2+MT2+ND1+SD1 = **85**, + AL-3/4/5 (3) = **88 decided districts**. Late-primary (full states, 17) = WA10+AZ9+TN9+MA9+MN8+MO8+WI8+LA6+CT5+KS4+HI2+NH2+RI2+AK1+DE1+VT1+WY1 = **86**, + AL-1/2/6/7 (4) = **90 late-primary districts**. Total 88+90 = **178**. ✓

**Per-seeding-phase decided/late split** (from the state groupings in ROADMAP.md):

| Seeding Phase | States | Decided districts | Late-primary districts |
|---------------|--------|--------------------|--------------------------|
| 161 | WA+AZ+TN+MA | **0** | **37 (100%)** |
| 162 | IN+MD+MN+MO | 17 (IN9+MD8) | 16 (MN8+MO8) |
| 163 | WI+CO+AL+SC+LA | 18 (CO8+SC7+AL-3) | 18 (WI8+AL-4+LA6) |
| 164 | KY+OR+CT+OK+AR+IA+KS+MS | 29 (KY6+OR6+OK5+AR4+IA4+MS4) | 9 (CT5+KS4) |
| 165 | NV+UT+NM+NE+WV+ID+HI+ME+NH+RI+MT+AK+DE+ND+SD+VT+WY | 24 | 10 (HI2+NH2+RI2+AK1+DE1+VT1+WY1) |

**Implication for the plan:** Phase 161 (the anchor seeding phase, USHC3-02..05 anchor) is **entirely** late-primary/`PROVISIONAL:`. Any plan-authoring for Phase 161 that assumes the "decided-state pattern first, then adapt for late-primary" order (as Phase 149/155/161's naming might suggest) is backwards for Wave 3 — the pipeline must be built PROVISIONAL-first.

---

## CRITICAL FINDING 2: Alabama Is District-Split, Not State-Split

Alabama's congressional map was redrawn mid-cycle (VRA redistricting litigation, second Black-majority district). [CITED: multiple AL news sources via WebSearch, cross-referenced]

- **AL-3, AL-4, AL-5:** Primary held **May 19, 2026**; runoff **June 16, 2026** (no candidate won >50% in the primary). **DECIDED.**
- **AL-1, AL-2, AL-6, AL-7:** Governor's proclamation moved these four districts to a **special primary August 11, 2026**, with **no runoff possible**. **LATE-PRIMARY.**

The field table must carry AL at the district level, not the state level. `160-field-table.csv` rows for AL-3/4/5 get `field_status=decided`; AL-1/2/6/7 get `field_status=late-primary`. This is analogous to — but more granular than — Phase 154's VA/MI carve-out (which was whole-state).

---

## CRITICAL FINDING 3: Louisiana's Congressional Election System Changed for 2026

[CITED: 270toWin "Changes to Louisiana Primaries Effective in 2026"; LA SoS ElectionsCalendar2026.pdf; LA SoS "05.14.26 Fall House Races Finalized"]

Louisiana was set to hold its first **closed party primary** for Congress in 2026 (a new system passed by the legislature), originally scheduled for spring 2026. A U.S. Supreme Court ruling on Louisiana's congressional district lines forced this closed-primary plan for **U.S. House races specifically** to be **cancelled**. Congressional races revert to Louisiana's traditional **fall open ("jungle") primary**: all candidates regardless of party appear on the **November 3, 2026** ballot; a candidate winning >50% is elected outright; otherwise the top two advance to a December runoff.

- **Qualifying period: August 5-7, 2026.** LA's House field cannot be authoritatively resolved before qualifying closes.
- LA's U.S. Senate race and local races still use the May 16, 2026 closed-primary date — only House is affected.
- Tag LA `ballot_system=open-primary-nov3` (or equivalent Claude's-discretion label) and `field_status=late-primary` (functionally equivalent to a pending-primary state — the field is unknowable until Aug 7).
- Redistricting litigation risk: LA's district lines (especially the CD-6 Black-majority district, Cleo Fields) were the subject of the same Supreme Court case. Verify at execution time whether district boundaries are final for the Nov-3 ballot.

---

## CRITICAL FINDING 4: Pre-Existing Races/Candidates Contradict the "Zero Pre-Seeded" Assumption

The ROADMAP states "None of the 38 Wave-3 states have pre-seeded 2026 House races." **This is false for at least 5 states**, verified live against production:

| State | Pre-existing `races` rows (2026-11-03) | Pre-existing `race_candidates` | Detail |
|-------|------------------------------------------|-------------------------------|--------|
| ME | 2 (both districts) | 2 on the general (Pingree ME-1, LePage ME-2) + 8 stale primary rows | ME's primary is DECIDED (RCV-tabulated); the general rows are incomplete — ME-2 needs Matt Dunlap added (beat the D primary field per NBC News), ME-1 Pingree's renomination needs confirmation |
| MD | 8 (all districts) | 0 | Races scaffolded, empty; MD's Jun-23 primary is DECIDED but no nominees wired yet — genuinely new work despite the race rows existing |
| MA | 9 (all districts) | 2 (MA-5 Katherine Clark, MA-7 Ayanna Pressley — both incumbents, `is_incumbent=true`, `active`) | Only 2 of 9 races have any candidate; MA's primary is Sep 1 (late-primary) — these 2 pre-wired incumbent rows are get-ahead placeholders from an unrelated earlier effort |
| NV | 4 (all districts) | **9 real candidates**, including all 4 sitting incumbents (Titus, Lee, Horsford — `is_incumbent=true`) + 5 challengers | NV's Jun-9 primary is DECIDED and this field looks essentially COMPLETE already. **NV-2's Lynn Chapman row has `politician_id IS NULL`** — a data-quality gap (violates the "non-null politician_id" invariant) that must be fixed, not re-created |
| OR | 6 (all districts) | 0 | Races scaffolded, empty; OR's May-19 primary is DECIDED — genuinely new work |

**Additionally, two states have stale PRIMARY-dated `race_candidates` rows (not on the Nov-3 election) that reveal a real data-quality bug:**

- **IN-9** (`2026 Indiana Primary`, May 5, already resolved): has a Democratic primary race (4 candidates: Graham, Meyer, Peck, Roark — all incorrectly flagged `is_incumbent=true`) and a Republican primary race (1 candidate: Erin Houchin — incorrectly flagged `is_incumbent=false`, even though Houchin IS the actual sitting IN-9 incumbent, confirmed via the incumbent map with 25 stances on file). **This is a real bug in existing prod data** the Phase-162 (IN) seeding plan must fix, not propagate.
- **UT** (`2026 Utah Primary`, Jun 23, already resolved): all 4 districts have D+R primary-split races fully wired (12 candidates total, correctly flagging Blake Moore/UT-2, Celeste Maloy/UT-3, Mike Kennedy/UT-4 as incumbents). This looks correct and complete — it is prior work from an earlier quick-task (`seed-ut-2026-06-23-primary*.sql`, referenced in project memory) that Phase-165 (UT) should build FROM, resolving the Nov-3 general nominees from these already-known primary winners rather than re-researching from scratch.

**Implication for the field table:** `existing_race_id` in `160-field-table.csv` must be populated per-district from a live query (not defaulted blank) for ME (2), MD (8), MA (9), NV (4), and OR (6) districts — 29 of 178 rows. The Phase-160 diagnostic script MUST run the "any election_date" sweep (not just `2026-11-03`) to catch IN and UT's stale primary infrastructure too, and flag the NV-2 NULL-politician_id anomaly and the IN-9 incumbent-flag bug explicitly for the owning seeding phase to fix.

---

## CRITICAL FINDING 5: Stance-Gap Baseline — the "Already Stanced" Assumption Is Materially Wrong

Live query against all 178 mapped incumbents (`inform.politician_answers` COUNT per politician, federal-24 bar = 24, confirmed live):

```
zero (sc=0):        13  incumbents
partial (1-23):     154 incumbents
done (>=24):         11 incumbents
```

Per-state detail (selected): **MD's entire 8-member delegation is at 0 stances** (Harris, Olszewski, Elfreth, Ivey, Hoyer, McClain Delaney, Mfume, Raskin — all real, correctly-mapped incumbents, just never run through v2.16/v2.17's stance pipeline). **ME's both reps (Pingree, Golden) are at 0.** **3 of IN's 9 reps (Baird, Carson, Messmer) are at 0.** Every other state's incumbents sit in the 3-25 partial range (average ~13) — **not** near the 24-topic bar as the ROADMAP's "sitting incumbents already stanced (v2.16/v2.17) and reuse their existing records" framing implies. Only Massachusetts (8 of 9 done, avg 37.4 — likely stanced against a larger, non-federal-scoped topic set at some point) approaches full coverage.

**Per D-02 (carried forward, locked):** partial-tier incumbents are reported only (no top-up — matches the roadmap's "new work = challengers + open-seat candidates" framing for them). **Zero-tier incumbents ARE in scope** for downstream stance research, same treatment as a new candidate. This means:
- Phase 162 (IN+MD+MN+MO) inherits **11 zero-tier incumbents needing full federal-24 research** (3 IN + 8 MD) — this is real, non-trivial scope the ROADMAP doesn't call out.
- Phase 165 (17 small states) inherits **2 zero-tier incumbents** (ME's Pingree, Golden) — though Golden is not seeking re-election (see Assumptions Log), so effectively this may reduce to Pingree + the new ME-2 nominees.

The `160-incumbent-map.csv`'s `incumbent_top_up_tier` column is the mechanism that carries this signal to the seeding phases — same schema as Phase 154, but the tier distribution itself is a materially different (worse) starting point than Wave 2's.

---

## CRITICAL FINDING 6: External_id Collision Audit — the Naive Formula Is NOT Collision-Free

Ran the exact D-01b Query 2 pattern (existing negative `external_id`s) against the proposed Wave-3 formula `-(state_fips*10000 + cd*100 + seq)` for `seq` in the valid 1-99 range, across all 178 districts:

**16 of 178 districts across 10 states have at least one real collision:**

| District | Colliding seq values | Max seq | Collision source (identified) |
|----------|----------------------|---------|-------------------------------|
| KY-CD1 | 1-98 (98 of 99 slots!) | 98 | MA state legislature (seeded 2026-05-22, geo `251xx`) — coincidental prefix overlap: MA state-leg used `-(21xxxx)` where "21" is NOT Kentucky's FIPS in that scheme |
| OK-CD1 | 10 scattered (max 43) | 43 | Mixed — WY/other state-exec `-(fips*10000+seq)` scheme (v2.18) overlapping OK's proposed band |
| KS-CD1 | 1,2 | 2 | MA congressional delegation (Pressley/Lynch/Moulton/Clark/Keating) — different old scheme using "20" as a non-FIPS prefix |
| KS-CD2 | 1-9 | 9 | Same MA-congress-delegation scheme |
| OR-CD1 | 10-13 | 13 | Washington County OR commissioner-district candidates (non-federal local race) |
| NV-CD1 | 73 | 73 | Utah city-council-ward candidate (unrelated) |
| NV-CD2 | 50 | 50 | Utah city-council-ward candidate |
| NV-CD4 | 46, 78 | 78 | Utah city-council-ward candidates |
| NM-CD1 | 25 | 25 | Utah city-council-ward candidate |
| NM-CD2 | 50 | 50 | Utah city-council-ward candidate |
| NM-CD3 | 81 | 81 | Utah city-council-ward candidate |
| NE-CD3 | 59 | 59 | Utah city-council-ward candidate |
| ME-CD1 | 1, 2 | 2 | **ME's own real Senate/House incumbents** — Susan Collins, Angus King, Chellie Pingree, Jared Golden already occupy `-(23xxxx)` low-seq slots under an earlier, similar-but-not-identical formula |
| ME-CD2 | 1, 2 | 2 | Same — ME's own incumbents |
| NH-CD1 | 28-32 | 32 | Some other municipal/ward dataset (geo `4971290`) |
| MT-CD2 | 84 | 84 | Salt Lake City mayor race (Erin Mendenhall) — unrelated dataset entirely |

**Root cause:** the negative external_id space has been used with several different, mutually-inconsistent ad-hoc numbering schemes across the project's history (state legislatures, state executives, county/city local races, an early MA congressional-delegation numbering). None of them consistently used "leading two digits = US state FIPS" — several used the leading digits as an unrelated dataset code that happens to numerically coincide with a different state's real FIPS code. There is no way to know this without running the live check per exact computed value — the collision cannot be predicted from the formula alone.

**Recommendation for the plan:** Do NOT trust the formula as collision-free by construction. Phase 160 must ship a `160-negative-id-audit.csv` (per-district: computed range, collision count, colliding values, safe starting seq) as a first-class artifact, and each seeding phase's insert script must **verify the specific computed external_id against a live `SELECT 1 FROM essentials.politicians WHERE external_id = $N` immediately before each INSERT**, incrementing `seq` on collision, rather than assuming a pre-reserved range is free. For KY-CD1 specifically (98/99 slots taken), flag it as requiring special handling — recommend an alternate sub-band (e.g., `seq` starting at 200, or a documented one-off exception) since fewer than 2 genuinely free slots remain in the standard range.

---

## Standard Stack

### Core (Phase 160 — diagnostic only, no new dependencies)

| Asset | Version / Location | Purpose | Why Standard |
|-------|--------------------|---------|--------------|
| `diag-154-incumbent-stance-gap.ts` | `backend/scripts/` | Template for the 38-state incumbent map + stance-gap script | Direct template; scale `WAVE3_FIPS` to 38 codes, `EXPECTED_PER_STATE` to the 38-state district counts (VERIFIED live this session — matches exactly) |
| `diag-154-validate-field-table.py` | `backend/scripts/` | Template CSV shape validator | Adapt `EXPECTED` map to 38 states; ADD the AL split-state row handling (AL needs per-district field_status, not per-state) |
| `154-verify.sql` | `backend/scripts/` | Template for the write-free pre-seeding gate | Adapt assertions to 38-state totals; MUST assert the DISCOVERED pre-existing-race baseline (ME 2 / MD 8 / MA 9 / NV 4 / OR 6 = 29 races), not a blanket "0 races" claim (this is the single most important deviation from the 154 template) |
| `backend/src/lib/db.js` `pool` | `backend/src/lib/` | DB connection | Unchanged |
| NEW: `diag-160-external-id-collision.ts` | `backend/scripts/` (to be authored) | Per-district collision audit against the proposed `-(fips*10000+cd*100+seq)` band | No template exists for this — Phase 154 (8 states) apparently had 0 collisions and didn't need one; Wave-3's 38-state scope surfaces 16 real collisions (proven live this session) that a naive port of the 154 approach would miss entirely |

### Supporting (field-resolution research tools)

| Tool | Purpose | Fetch-wall Status |
|------|---------|-------------------|
| NCSL 2026 State Primary Election Dates page | Baseline primary-date source (all 38 states in one fetch) | Reachable via WebFetch — used this session, MEDIUM confidence for non-spot-checked states |
| Ballotpedia per-state/per-district pages | Cross-verification + special-case detail (AL split, LA system change, AK/ME RCV mechanics) | Cloudflare-walled to WebFetch/WebSearch snippets sufficed for this session's targeted questions; Playwright required for full per-district candidate lists |
| State SoS sites (LA, MD, WA, AZ) | Authoritative primary-date + qualifying-period confirmation | Reachable; LA SoS PDF calendars especially useful |
| Wikipedia per-state 2026 House elections pages | Per-district candidate field detail | Long pages TOC-only via WebFetch → use raw-wikitext `?action=raw` |
| FEC API (`api.data.gov`) | Candidate registration cross-check | Free key, 1000/hr, established pattern |

---

## Package Legitimacy Audit

> Phase 160 installs NO new npm/pip/cargo packages. All tooling (`tsx`, `dotenv`, `pg`, `psql`, `python3`) is already installed in `backend/node_modules` / the machine environment, proven working this session (all diagnostic queries executed successfully against prod).

**Packages removed due to slopcheck:** none (no new packages)
**Packages flagged as suspicious:** none

---

## Architecture Patterns

### System Architecture Diagram

```
Phase 160 data flow (READ-ONLY, 38 states / 178 districts):

Live Postgres DB (kxsdzaojfaibhuzmclfq)
  |
  ├── Query A: districts JOIN offices JOIN politicians (38 FIPS codes)
  |     → 178 mapped incumbents (VERIFIED: 0 vacancies found — Query C returned 0 rows,
  |       unlike Wave 2's 3 special seats; still must sweep for retirements not yet
  |       reflected as office-holder changes, e.g. Hoyer/MD-5 retiring but still the
  |       current DB "incumbent" until his successor is elected)
  |
  ├── Query B: per-state stance-gap summary
  |     → 13 zero / 154 partial / 11 done (CRITICAL FINDING 5 — worse than assumed)
  |
  ├── Query C: vacancy detection (holder_ct != 1)
  |     → 0 rows found for Wave-3 (unlike Wave-2's GA-13/NJ-11/VA-11/GA-14);
  |       does NOT mean no open seats — retirements (Hoyer/MD-5, Golden/ME-2, etc.)
  |       still show a "1-holder" district because the CURRENT member hasn't left yet
  |
  ├── NEW Query D: external_id collision audit (per district, seq 1-99)
  |     → 16/178 districts collide (CRITICAL FINDING 6) — MUST run before any
  |       seeding phase authors a new challenger external_id
  |
  └── NEW Query E: pre-existing race/race_candidates audit (ANY election_date)
        → ME/MD/MA/NV/OR have scaffolded races (29 total); NV has 9 real candidates;
          IN/UT/ME have stale primary-era candidate rows, one with a confirmed
          incumbent-flag bug (IN-9) — CRITICAL FINDING 4
              |
              v
        160-incumbent-map.csv    (178 rows)
        160-negative-id-audit.csv (per-district collision report, NEW artifact)
        160-race-preexistence-audit.csv (per-district existing_race_id source, NEW or folded into field-table)

External sources (web research, plan-time / wave-time artifact assembly):
  NCSL primary-date table + state SoS + Ballotpedia (AL split, LA system change,
  AK/ME RCV mechanics) + Wikipedia raw-wikitext
  → per-district decided/late-primary/ballot_system classification
  → incumbent-not-nominee flags (Hoyer/MD-5 retiring, Golden/ME-2 not seeking
    re-election — both confirmed this session)
  → new-record enumeration
              |
              v
        160-field-table.csv  ←  assembled per-seeding-group wave (161→165 order)
        (178 rows; 15+ columns incl. seeding_phase, ballot_system, rcv,
         filing-open deadline; existing_race_id populated for the 29 ME/MD/MA/NV/OR rows)
              |
              v
        diag-160-validate-field-table.py  ← validates CSV shape (38-state EXPECTED map,
                                              AL district-level split handling)
              |
              v
        160-verify.sql  ← write-free gate; asserts the DISCOVERED 29-race baseline,
                           NOT a blanket "0 pre-seeded races" claim
```

### Recommended Project Structure

```
backend/scripts/
├── diag-160-incumbent-stance-gap.ts        # Wave 1 (adapt diag-154, 38 FIPS)
├── diag-160-external-id-collision.ts       # Wave 1 (NEW — no Phase-154 precedent needed one)
├── diag-160-race-preexistence-audit.ts     # Wave 1 (NEW — ANY election_date sweep)
├── diag-160-validate-field-table.py        # Final wave (adapt diag-154, 38-state EXPECTED + AL split)
└── 160-verify.sql                          # Final wave (adapt 154-verify.sql; assert discovered 29-race baseline)

.planning/phases/160-field-resolution-stance-gap-diagnostic/
├── 160-incumbent-map.csv                   # Wave 1 output (178 rows)
├── 160-negative-id-audit.csv               # Wave 1 output (per-district collision report)
├── 160-field-table.csv                     # Assembled across Waves 2-6 (per seeding-group)
└── 160-FIELD-TABLE.md                      # Human-readable summary
```

### Pattern 1: Incumbent Map Query (proven this session — reuse verbatim)

```typescript
// VERIFIED this session against prod (178 rows returned, matches expected exactly).
const WAVE3_FIPS = ['53','04','47','25','18','24','27','29','55','08','01','45','22','21',
  '41','09','40','05','19','20','28','32','49','35','31','54','16','15','23','33','44','30',
  '02','10','38','46','50','56']; // WA AZ TN MA IN MD MN MO WI CO AL SC LA KY OR CT OK AR IA
  // KS MS NV UT NM NE WV ID HI ME NH RI MT AK DE ND SD VT WY
const queryA = await pool.query(
  `SELECT substr(d.geo_id, 1, 2) AS state_fips, d.geo_id, p.id AS politician_id,
          p.external_id, p.full_name, p.is_active,
          (SELECT COUNT(*) FROM inform.politician_answers pa
            WHERE pa.politician_id = p.id)::int AS stance_count
   FROM essentials.districts d
   JOIN essentials.offices o ON o.district_id = d.id
   JOIN essentials.politicians p ON p.id = o.politician_id
   WHERE d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id, 1, 2) = ANY($1::text[])
   ORDER BY state_fips, d.geo_id`,
  [WAVE3_FIPS],
);
// Result this session: 178 rows (0 vacancies) — Query C (holder_ct != 1) returned 0 rows.
```

### Pattern 2: External_id Collision Audit (NEW — proven this session)

```typescript
// NEW pattern — no Phase-154 precedent needed this because Wave-2's 8 states had 0
// collisions. Wave-3's 38 states have 16. Run this BEFORE any seeding phase authors IDs.
const FIPS: Record<string, number> = { WA:53, AZ:4, TN:47, /* ...all 38... */ };
const DELEG: Record<string, number> = { WA:10, AZ:9, TN:9, /* ...district counts... */ };
const { rows } = await pool.query('SELECT external_id FROM essentials.politicians WHERE external_id < 0');
const negIds = new Set(rows.map(r => Number(r.external_id)));
for (const [st, fips] of Object.entries(FIPS)) {
  for (let cd = 1; cd <= DELEG[st]; cd++) {
    const collisions: number[] = [];
    for (let seq = 1; seq <= 99; seq++) {
      const candidate = -(fips * 10000 + cd * 100 + seq);
      if (negIds.has(candidate)) collisions.push(seq);
    }
    if (collisions.length) {
      // KY-CD1: 98 collisions (seq 1-98) — nearly the entire band is taken.
      console.log(`${st}-CD${cd}: ${collisions.length} collisions, max seq ${Math.max(...collisions)}`);
    }
  }
}
// Result this session: 16 districts across KY/OR/OK/KS/NV/NM/NE/ME/NH/MT collide.
```

### Pattern 3: Pre-Existing Race/Candidate Sweep (NEW — proven this session)

```typescript
// Sweep ANY election_date, not just 2026-11-03 — catches ME/IN/UT's primary-era rows
// that a Nov-3-only filter would miss entirely.
const q = await pool.query(
  `SELECT substr(d.geo_id,1,2) AS fips, el.election_date, el.name,
          COUNT(DISTINCT r.id) AS race_ct, COUNT(rc.id) AS cand_ct
   FROM essentials.races r
   JOIN essentials.elections el ON el.id = r.election_id
   JOIN essentials.offices o ON o.id = r.office_id
   JOIN essentials.districts d ON d.id = o.district_id
   LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
   WHERE d.district_type='NATIONAL_LOWER' AND substr(d.geo_id,1,2) = ANY($1::text[])
   GROUP BY fips, el.election_date, el.name ORDER BY fips, el.election_date`,
  [WAVE3_FIPS],
);
// Result this session: IN (May-5 primary, 5 cands), ME (Jun-9 primary 8 cands + Nov-3
// general 2 cands), MD (Nov-3, 0 cands, 8 races), MA (Nov-3, 2 cands, 9 races),
// NV (Nov-3, 9 cands, 4 races), OR (Nov-3, 0 cands, 6 races), UT (Jun-23 primary, 12 cands).
```

### Anti-Patterns to Avoid

- **Assuming the negative external_id formula is collision-free by construction.** Proven false for 16/178 districts this session. Always run the live per-computed-value check.
- **Treating Alabama as one state in the field table.** It is district-split: AL-3/4/5 decided, AL-1/2/6/7 late-primary.
- **Defaulting `existing_race_id` to blank for all 178 rows.** ME/MD/MA/NV/OR (29 districts) have real pre-scaffolded races that must be reused, not duplicated.
- **Filtering the pre-existing-race sweep to `election_date='2026-11-03'` only.** This misses IN's and UT's stale-but-relevant primary-era `race_candidates` rows (5 and 12 rows respectively) that inform the Nov-3 nominee resolution.
- **Treating LA as a normal "late-primary" state with a knowable future primary date.** LA has no separate House primary in 2026; the field is unknowable until the Aug 5-7 qualifying period closes, and the Nov-3 ballot IS the first round.
- **Assuming "sitting incumbents already stanced" means near-24-topic coverage.** Only 11/178 are actually done; 154 are mid-teens partial; 13 (MD's whole delegation + both ME reps + 3 IN reps) are at zero and are IN SCOPE for downstream research per D-02's zero-tier carve-out.
- **Propagating the IN-9 incumbent-flag bug.** The pre-existing DB rows mislabel Houchin (actual incumbent) as non-incumbent and her primary opponents as incumbents. Phase 162 must correct this, not copy it forward.
- **Using computed external_id for incumbent lookup.** Always join by `(district_type='NATIONAL_LOWER', geo_id)` — unchanged from Phase 148/154.
- **Counting `inform.politician_answers.id`.** No such column; use `COUNT(*)`.
- **Running scripts outside `backend/`.** `cd /c/EV-Accounts/backend && node --import tsx ...` in one compound command (cwd resets between Bash calls).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Incumbent-map DB query | New query | Adapt `diag-154-incumbent-stance-gap.ts` Query A/B/C | Proven; ran successfully this session at 38-state scale with zero changes to the SQL shape |
| CSV shape validation | Custom validator | Adapt `diag-154-validate-field-table.py` | Handles row count, field presence, per-state counts; needs the AL-split and 38-state EXPECTED map additions |
| SQL gate assertion style | Custom psql | Adapt `154-verify.sql` `DO $$ ... RAISE EXCEPTION` | Canonical gate style; needs the discovered-29-race baseline substituted for the "0 races" assumption |
| External_id collision detection | Trusting the formula | The live per-computed-value SELECT pattern proven in this research (Pattern 2 above) | The formula is provably NOT collision-free at this scale; only a live DB check catches it |

**Key insight:** At 38-state / 178-district scale, "adapt the Wave-2 template" is necessary but not sufficient. Three genuinely new problems appear that Wave-2's 8-state scope never surfaced: real external_id collisions, a nearly-even decided/late-primary split (vs. Wave-2's 7-decided/1-pending), and multiple states with real pre-existing race/candidate data (vs. Wave-2's single VA case). The plan must budget explicit tasks for all three, not just scale the row counts in the Wave-2 templates.

---

## Common Pitfalls

### Pitfall 1: Treating Alabama as a Single Decided or Late-Primary State
**What goes wrong:** The field table tags all 7 AL districts uniformly.
**Why it happens:** Every other Wave-3 state has one primary date; AL is the only district-split exception (mid-cycle court-ordered redistricting).
**How to avoid:** AL-3/4/5 = `decided` (May 19 primary + June 16 runoff, already resolved); AL-1/2/6/7 = `late-primary` (Aug 11 special primary, no runoff).
**Warning signs:** Any field-table row for AL that doesn't cite a district-specific source URL.

### Pitfall 2: Assuming Louisiana Has a Knowable Primary Date
**What goes wrong:** Plan waits for or tries to resolve an "LA primary date" that doesn't exist for House races in 2026.
**Why it happens:** Every other state has a primary; LA's closed-primary plan (which would have had one) was cancelled by a SCOTUS ruling specific to LA's district lines.
**How to avoid:** Tag LA `late-primary` with the Aug 5-7 qualifying period as the operative date; the Nov-3 ballot is the first (and possibly only) round.
**Warning signs:** A field-table row for LA citing a "primary date" other than the qualifying window.

### Pitfall 3: Defaulting `existing_race_id` Blank for All 178 Rows
**What goes wrong:** Phase 161-165 seeding scripts create duplicate `essentials.races` rows for ME/MD/MA/NV/OR districts that already have one.
**Why it happens:** The ROADMAP's blanket "none of the 38 states have pre-seeded races" claim, taken at face value.
**How to avoid:** Run the pre-existence sweep (Pattern 3) across ALL election_dates for all 38 states; populate `existing_race_id` for the 29 discovered rows (ME 2, MD 8, MA 9, NV 4, OR 6).
**Warning signs:** A seeding phase's `INSERT INTO essentials.races` for a district that Query E already found a race for.

### Pitfall 4: Re-Creating NV's Already-Wired Candidates
**What goes wrong:** Phase 165 (NV is in this group) re-researches and re-inserts NV's 4 House races from scratch, creating duplicate `race_candidates` rows for Titus, Buck, Chapman, Flippo, Benitez-Thompson, Lee, O'Donnell, Horsford, Whipple.
**Why it happens:** Not checking for pre-existing `race_candidates` before starting fresh research.
**How to avoid:** The field table's `general_candidates` column for NV's 4 districts should note "ALREADY WIRED — verify completeness/correctness, do not duplicate" and flag NV-2's NULL-`politician_id` row (Lynn Chapman) as a fix-not-recreate item.
**Warning signs:** Any NV seeding task that doesn't first query `race_candidates` for the district.

### Pitfall 5: Propagating the IN-9 Incumbent-Flag Bug
**What goes wrong:** Phase 162 (IN) reads IN-9's existing `race_candidates` rows at face value and treats Jim Graham/Brad Meyer/Tim Peck/Keil Roark as incumbents (they're not) while treating Erin Houchin as a non-incumbent (she is the actual sitting member).
**Why it happens:** Trusting stale primary-era data without cross-checking against the incumbent map.
**How to avoid:** Cross-reference every pre-existing `race_candidates.is_incumbent` flag against the Query A incumbent map (which correctly shows Houchin at geo_id 1809 with 25 stances) before wiring the Nov-3 general race.
**Warning signs:** Any IN-9 general-election candidate list where the flagged incumbent isn't the same politician_id as the Query-A incumbent map.

### Pitfall 6: Trusting the External_id Formula Without a Live Collision Check
**What goes wrong:** A seeding phase computes `-(fips*10000+cd*100+seq)` for a new challenger and INSERTs it, silently overwriting or colliding with an unrelated existing politician (e.g., a KY-CD1 challenger's ID colliding with a Massachusetts state legislator's ID).
**Why it happens:** The formula "looks" collision-free by design (each state/district/seq combination is unique in the abstract) but the negative-ID space has been reused with inconsistent, non-FIPS-based schemes across the project's multi-year history.
**How to avoid:** Every INSERT of a new negative external_id MUST be preceded by a live `SELECT 1 FROM essentials.politicians WHERE external_id = $computed` check; increment `seq` on any hit. For KY-CD1 (98/99 slots occupied) and OK-CD1 (43/99 occupied), flag for manual seq-range extension before Phase 164 (KY, OK) begins seeding.
**Warning signs:** A unique-constraint violation on `essentials.politicians.external_id` during seeding — or worse, a silent overwrite if there's no unique constraint (verify at plan time whether `external_id` has a UNIQUE constraint).

### Pitfall 7: Assuming "Already Stanced" Means Near-24-Topic Coverage
**What goes wrong:** A seeding phase skips ALL Wave-3 incumbents for stance work, assuming v2.16/v2.17 coverage is complete.
**Why it happens:** The ROADMAP's "sitting incumbents already stanced (v2.16/v2.17) and reuse their existing records" framing doesn't distinguish `done` from `partial` from `zero`.
**How to avoid:** Consult `incumbent_top_up_tier` per district. `zero`-tier incumbents (13: MD's 8, ME's 2, IN's 3) need FULL federal-24 research, same as a new candidate. `partial`-tier (154) are report-only, no top-up (per D-02). `done`-tier (11) are fully skipped.
**Warning signs:** A seeding-phase plan for MD or ME that has zero stance-research tasks.

### Pitfall 8: Counting `politician_answers.id`
**What goes wrong:** `SELECT COUNT(pa.id)` errors — no such column.
**How to avoid:** `SELECT COUNT(*) FROM inform.politician_answers pa WHERE pa.politician_id = p.id`.
**Warning signs:** `column pa.id does not exist`.

### Pitfall 9: Running Scripts Outside `backend/`
**What goes wrong:** Module resolution errors (`dotenv/config`, `../src/lib/db.js`).
**How to avoid:** `cd /c/EV-Accounts/backend && set -a && source .env && set +a && node --import tsx scripts/diag-160-*.ts` — one compound command (cwd resets between Bash calls).

---

## Ballot System Reference (D-04)

| State | System | Mechanics | Source |
|-------|--------|-----------|--------|
| WA | `top-two` | All candidates on one primary ballot regardless of party; top 2 advance to Nov-3 general, party-blind | HIGH [CITED: Ballotpedia, WA SoS] |
| AK | `top-four-rcv` | Top-four primary Aug 18 (party-blind); Nov-3 general uses RCV among the 4 advancers; majority (50%+1) wins after elimination rounds | HIGH [CITED: Ballotpedia] |
| ME | `rcv-general` | Both primary AND general use RCV; ME-2's Jun-9 D primary was RCV-tabulated (Dunlap beat a multi-candidate field); apply D-04a maximal thoroughness | HIGH [CITED: NBC News, FairVote] |
| LA | `open-primary-nov3` (nonstandard) | No separate House primary in 2026; qualifying Aug 5-7; all candidates on Nov-3 ballot; majority wins outright, Dec runoff if none | HIGH [CITED: 270toWin, LA SoS] |
| AL (1/2/6/7 only) | `standard` but mid-cycle-redistricted | Special primary Aug 11, no runoff possible (unlike AL's normal runoff system) | HIGH |
| All other 33 states | `standard` | Traditional party primaries; runoff rules vary by state (not researched in depth — not flagged as RCV or top-two/four by any source found) | MEDIUM |

---

## Runtime State Inventory

> Not applicable — Phase 160 is a diagnostic phase producing NEW artifacts (field table, incumbent map, collision audit), not a rename/refactor/migration of existing runtime state. Skipping per the "greenfield phases" exemption. (The pre-existing race/candidate DATA discovered in Critical Finding 4 is a genuine finding but belongs in the field-table reconciliation task, not a rename/migration inventory — no renaming or key-migration is occurring.)

---

## Code Examples

Verified patterns from this session's live DB queries (all executed successfully against `kxsdzaojfaibhuzmclfq` — see Architecture Patterns section above for full code):

- **178-district tally** — confirms 0 mismatches against the ROADMAP's stated per-state delegation sizes.
- **Incumbent map + stance-gap** — confirms 178 mapped incumbents, 0 vacancies (Query C empty), and the 13/154/11 zero/partial/done tier split.
- **External_id collision audit** — confirms 16/178 districts collide; full per-district seq list captured above.
- **Pre-existing race/candidate sweep (any election_date)** — confirms ME/MD/MA/NV/OR races and IN/UT/ME stale candidate rows.

---

## State of the Art

| Old Approach (Wave 1/2 assumption) | Current Reality (Wave 3, verified) | When Changed | Impact |
|--------------------------------------|--------------------------------------|---------------|--------|
| "None of the N states have pre-seeded races" | 5 of 38 states (ME/MD/MA/NV/OR) DO have pre-seeded races; NV has real candidates | Discovered this session | Field table must populate `existing_race_id` for 29 rows, not default blank |
| "Sitting incumbents already stanced" | Only 11/178 at ≥24 topics; 13 at zero | Discovered this session | Zero-tier incumbents (MD's 8, ME's 2, IN's 3) need full stance research downstream |
| "External_id formula is collision-free by construction" | 16/178 districts collide with historical ad-hoc ID schemes | Discovered this session | Must run live per-value checks, not trust the range |
| "Decided states are the norm, late-primary is the Aug-Sep exception" (implied by ROADMAP prose) | Nearly 50/50 split (88/90); Phase 161 is 100% late-primary | Discovered this session | Anchor seeding phase must build the PROVISIONAL pattern first, not last |
| Louisiana closed-primary system (as passed by the LA legislature) | Cancelled for 2026 House races by SCOTUS ruling; reverted to open/jungle primary | Ruling occurred before 2026-07-03; discovered this session | LA field unresolvable until Aug 5-7 qualifying closes |

**Deprecated/outdated:** The Phase-154-template assumption "field-resolution research produces the entire field from scratch" — for 5-7 Wave-3 states, the correct task is "reconcile/complete existing prod data," a different (and in some cases easier — NV looks nearly done) task shape.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | NCSL's primary-date table is current and accurate for the 31 states not independently spot-verified this session (TN, MN, MO, WI, CO, SC, KY, CT, OK, AR, IA, KS, MS, NM, NE, WV, ID, HI, NH, RI, MT, DE, ND, SD, VT, WY) | Critical Finding 1 table | If any of these dates are stale/wrong (as VA's was in Phase 154), the decided/late-primary classification for that state is wrong; recommend the per-state research agents (D-01) re-verify their assigned state's date against an official SoS source before finalizing the field table row |
| A2 | Chellie Pingree (ME-1) was renominated in the June 9 primary | Critical Finding 1 (ME row) | The WebSearch results confirmed ME-2's contested primary outcome (Dunlap) but did not explicitly confirm ME-1's primary result; if Pingree lost or didn't run, ME-1 needs the same open-seat treatment as ME-2 |
| A3 | Jared Golden (ME-2) is not seeking re-election in 2026 | Critical Finding 5 / Stance-gap zero-tier note | Sourced from a single WebSearch synthesis (NBC News); if incorrect, ME-2's zero-stance "incumbent" scope treatment changes (Golden would need stance research as an incumbent, not be replaced by a new nominee) |
| A4 | Steny Hoyer (MD-5) is retiring, not running for re-election in 2026 | Critical Finding 5 | Sourced from Ballotpedia's retirement-list WebSearch synthesis; if Hoyer IS running and won the June 23 primary, MD-5's "new record" framing is wrong — he'd remain the incumbent nominee needing stance top-up (zero-tier), not a new-record replacement |
| A5 | The 16 identified external_id collisions (Critical Finding 6) fully enumerate the collision risk; no additional collisions exist beyond seq 99 that matter | Critical Finding 6 | The check was bounded to seq 1-99 (the formula's intended range); if a district needs more than the remaining free slots (e.g., KY-CD1 has only 1 free slot in 1-99), the seeding phase will need an explicitly extended range — this is flagged, not silently risked |
| A6 | The AL-1/2/6/7 special primary (Aug 11, no runoff) and AL-3/4/5 (May 19 + Jun 16 runoff) dates are both still current as of 2026-07-03 (no further court intervention) | Critical Finding 2 | AL's redistricting litigation has already changed once (mid-cycle map redraw); a further ruling could change dates again before the Phase 163 (AL is in this group) seeding work begins — recommend re-verification at execution time |
| A7 | Massachusetts's high stance counts (8/9 incumbents ≥24, avg 37.4) reflect legitimate prior federal-24 research, not a data artifact from an unrelated topic set or duplicate rows | Critical Finding 5 | If MA's answers were seeded against a different (larger, non-federal-scoped) topic set at some point, the `stance_count` numbers may overstate actual federal-24 coverage; worth a spot-check of a MA incumbent's `politician_answers` topic_ids against the current 24 federal-24 topic_key list before trusting the `done` tier for MA |

**If this table is empty:** N/A — populated above.

---

## Open Questions (all RESOLVED)

1. **Does `essentials.politicians.external_id` have a UNIQUE (or similar) DB constraint?** **(RESOLVED — resolved-by-plan: 160-01's collision-audit task (Part B) documents the constraint's presence/absence as part of its output; no separate action needed.)**
   - What we know: 16 districts have collision risk under the naive formula; a UNIQUE constraint would turn a silent-overwrite risk into a hard INSERT failure (safer, fails loud).
   - What's unclear: Whether such a constraint exists — not checked this session.
   - Recommendation: Verify via `\d essentials.politicians` or an information_schema query at plan time; if no UNIQUE constraint exists, the live pre-INSERT collision check (Pattern 2) becomes even more critical since a silent overwrite is possible, not just a loud failure.

2. **Are NV-2's stale primary-era data and the IN-9 incumbent-flag bug isolated, or do similar bugs exist in ME's or UT's pre-existing rows?** **(RESOLVED — 160-01's race-preexistence-audit task now emits a full-column dump of every pre-existing ME/MD/MA/NV/OR/IN/UT race/candidate row with a per-row anomaly flag, so the owning seeding phases (162/163/165) inherit a complete column-level audit before building on them.)**
   - What we know: IN-9's bug (wrong incumbent flags) and NV-2's NULL-politician_id are confirmed; ME's and UT's rows were spot-checked and looked structurally sound (correct incumbent flags on Blake Moore/Celeste Maloy/Mike Kennedy in UT; ME's rows are simply incomplete, not obviously wrong).
   - What's unclear: A full field-by-field data-quality audit of all 29+ pre-existing rows wasn't performed (this session verified existence and gross correctness, not every column).
   - Recommendation: The Phase-160 plan should include an explicit "reconcile, don't recreate" task per affected state (ME, MD, MA, NV, OR, IN, UT) that audits every column of the pre-existing rows before the owning seeding phase (162/163/165) builds on them.

3. **What is Phase 167's exact per-cluster date-gated structure, given the 90 late-primary districts span primary dates from Jul 21 (AZ) through Sep 15 (DE)?** **(RESOLVED — Claude's Discretion per CONTEXT.md D-05; delivered by 160-07's Phase-167 primary-date cluster table grouping every state's exact 2026 primary date by calendar week.)**
   - What we know: The late-primary districts don't share one date — they span nearly 2 months across 5+ distinct clusters (Jul: AZ; Aug 4: WA/MO/KS/AL-1267-no-wait-Aug11; Aug 6: TN; Aug 8: HI; Aug 11: MN/WI/CT/VT/AL-1/2/6/7; Aug 18: AK/WY; Sep 1: MA; Sep 8: NH; Sep 9: RI; Sep 15: DE; LA's Aug 5-7 qualifying is its own case).
   - What's unclear: Whether Phase 167 should have one plan per date-cluster (7-8 plans) or a smaller number of coarser clusters (e.g., "August primaries" vs "September primaries").
   - Recommendation: This is explicitly Claude's Discretion per CONTEXT.md D-05 ("the Phase-167 primary-date-cluster output format"); Phase 160 should at minimum produce the per-state exact primary date so the eventual Phase-167 planner can group as needed. Recommend clustering by calendar week for practicality (5-7 clusters).

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| node + tsx | diag-160-*.ts scripts | ✓ VERIFIED (multiple successful runs this session) | existing in `backend/` | — |
| python3 | diag-160-validate-field-table.py | ✓ (established v2.20/v2.21 pattern) | existing | — |
| psql | 160-verify.sql gate | ✓ (established pattern) | existing | — |
| DATABASE_URL (.env) | All DB scripts | ✓ VERIFIED (all queries this session hit prod successfully) | `kxsdzaojfaibhuzmclfq` | — |
| Playwright | Ballotpedia field resolution | ✓ (established v2.20/v2.21) | — | Wikipedia raw-wikitext |
| FEC API key | Candidate cross-check | ✓ (established v2.20/v2.21) | — | Skip FEC cross-check if key expired |
| WebFetch (NCSL, LA SoS PDF) | Primary-date research | ✓ VERIFIED (used this session successfully) | — | WebSearch snippet synthesis (used as backup for spot-checks) |

**Missing dependencies with no fallback:** None.

---

## Validation Architecture

> `workflow.nyquist_validation` is absent from `.planning/config.json` → treated as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | psql (`-v ON_ERROR_STOP=1`) for the SQL gate; python3 for the CSV validator; `node --import tsx` for DB diagnostic scripts |
| Config file | none — standalone scripts, same pattern as Phase 154 |
| Quick run command | `cd /c/EV-Accounts/backend && set -a && source .env && set +a && node --import tsx scripts/diag-160-incumbent-stance-gap.ts` |
| Full suite command | `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/160-verify.sql` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| USHC3-01 (Part A) | 178-district incumbent map + stance-gap produced | integration | `node --import tsx scripts/diag-160-incumbent-stance-gap.ts` (exits 0, prints 178-total) | ❌ Wave 0 |
| USHC3-01 (Part B) | External_id collision audit produced, 0 UNRESOLVED collisions (all 16 found ones have a documented safe-seq recommendation) | integration | `node --import tsx scripts/diag-160-external-id-collision.ts` (exits 0, writes `160-negative-id-audit.csv`) | ❌ Wave 0 (NEW script — no Phase-154 precedent) |
| USHC3-01 (Part C) | Pre-existing race/candidate audit produced (ANY election_date, all 38 states) | integration | `node --import tsx scripts/diag-160-race-preexistence-audit.ts` | ❌ Wave 0 (NEW script) |
| USHC3-01 (Part D) | field-table.csv shape-valid (178 rows, per-state + AL-district-split counts, 88/90 decided/late partition) | integration | `python3 scripts/diag-160-validate-field-table.py` (exits 0 = PASS) | ❌ Wave 0 |
| USHC3-01 (Part E) | DB baseline pre-seeding assertions pass, including the DISCOVERED 29-race baseline (not "0 races") | integration | `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/160-verify.sql` | ❌ Wave 0 |

### Sampling Rate

- **Per-task commit:** Run the relevant diagnostic script to verify output is well-formed (exits 0).
- **Per-wave merge:** Run all diagnostic + validator commands above for that wave's state subset.
- **Phase gate:** All commands must pass (178-row incumbent map, negative-id-audit with all 16 collisions documented+resolved, field-table 178-row/88-90-split PASS, verify.sql PASS) before `/gsd:verify-work` on Phase 160.

### Wave 0 Gaps

- [ ] `backend/scripts/diag-160-incumbent-stance-gap.ts` — USHC3-01 Part A (adapt from diag-154; SQL shape already proven this session)
- [ ] `backend/scripts/diag-160-external-id-collision.ts` — USHC3-01 Part B (NEW; logic proven this session, needs packaging into a script + CSV emit)
- [ ] `backend/scripts/diag-160-race-preexistence-audit.ts` — USHC3-01 Part C (NEW; logic proven this session, needs packaging into a script + CSV emit)
- [ ] `backend/scripts/diag-160-validate-field-table.py` — USHC3-01 Part D (adapt from diag-154; needs the AL district-level split handling)
- [ ] `backend/scripts/160-verify.sql` — USHC3-01 Part E (NEW logic: assert the 29-race discovered baseline, not "0 races"; assert 0 UNEXPECTED vacancies since Query C returned empty this session)
- [ ] `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-incumbent-map.csv` — output artifact
- [ ] `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-negative-id-audit.csv` — output artifact (NEW, no Phase-154 equivalent)
- [ ] `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-field-table.csv` — output artifact

---

## Security Domain

> This phase is purely read-only diagnostic against a production database using existing credentials, plus public-source web research. No new API surface, no user input, no network endpoints serving the app. ASVS categories are not applicable — confirmed by executing every diagnostic query this session as SELECT-only with zero writes.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | no | No user-controlled input in diagnostic scripts |
| V6 Cryptography | no | No cryptographic operations |
| V2-V4 Auth/Session/Access | no | DB connection uses existing `DATABASE_URL` (service role); no new auth surface |

---

## Sources

### Primary (HIGH confidence — verified this session via direct tool execution)

- Live DB queries against `kxsdzaojfaibhuzmclfq` (this session): 178-district tally (0 mismatches), incumbent map + stance-gap (13 zero/154 partial/11 done), vacancy detection (0 rows), external_id collision audit (16 districts collide), pre-existing race/candidate sweep (ME/MD/MA/NV/OR races; IN/ME/UT stale candidate rows; NV-2 NULL-politician_id; IN-9 incumbent-flag bug) — [VERIFIED: executed via `node --import tsx` this session]
- `backend/scripts/diag-154-incumbent-stance-gap.ts`, `diag-154-validate-field-table.py`, `154-verify.sql`, `154-01-PLAN.md`, `154-02-PLAN.md` — Wave-2 template patterns [VERIFIED: read directly]
- `backend/data/stance-research/_FED24_SCALE.txt` + live `inform.compass_topics` query (44 total, 24 federal after excluding 20 city/judicial/data-center topics) — federal-24 denominator CONFIRMED CURRENT [VERIFIED: cross-checked file against live DB this session]

### Secondary (MEDIUM-HIGH confidence — cross-verified 2+ independent sources)

- [NCSL 2026 State Primary Election Dates](https://www.ncsl.org/elections-and-campaigns/2026-state-primary-election-dates) — baseline 38-state primary-date table [CITED]
- Maryland primary date June 23, 2026 — [Ballotpedia](https://ballotpedia.org/Maryland_elections,_2026), [MD SoE](https://elections.maryland.gov/elections/2026/vote2026/), [BallotReady](https://www.ballotready.org/elections/maryland-primary-election-146338e5-e266-491f-88a6-70b28bf4e3ae) [CITED — 3 sources]
- Massachusetts primary date September 1, 2026 — [MA Legislature press release](https://malegislature.gov/PressRoom/Detail?pressReleaseId=255), [Ballotpedia](https://ballotpedia.org/Massachusetts_elections,_2026) [CITED]
- Arizona primary date July 21, 2026 (moved by law from Aug to 2nd-to-last Tue in July) — [Maricopa County Elections](https://elections.maricopa.gov/news-and-information/elections-news/primary-election-dates-262026.html) [CITED]
- Washington top-two primary, Aug 4, 2026 — [Ballotpedia](https://ballotpedia.org/United_States_House_elections_in_Washington,_2026_(August_4_top-two_primaries)) [CITED]
- Alaska top-four-RCV, Aug 18 primary / Nov 3 RCV general — [Ballotpedia](https://ballotpedia.org/United_States_Senate_election_in_Alaska,_2026_(August_18_top-four_primary)), [FairVote](https://fairvote.org/alaska-election-results-show-ranked-choice-voting-continues-to-work-well-for-voters/) [CITED]
- Alabama district-split (AL-3/4/5 decided May19+runoff Jun16; AL-1/2/6/7 special primary Aug 11 no runoff, court-ordered redistricting) — cross-referenced AL news sources via WebSearch [CITED]
- Louisiana closed-primary cancellation, reversion to open/jungle primary, qualifying Aug 5-7 — [270toWin](https://www.270towin.com/content/changes-to-louisiana-primaries-effective-in-2026), [LA SoS Elections Calendar](https://www.sos.la.gov/ElectionsAndVoting/PublishedDocuments/ElectionsCalendar2026.pdf), [LA SoS Fall House Races Finalized](https://www.sos.la.gov/OurOffice/PublishedDocuments/05.14.26FallHouseRaces.pdf) [CITED]
- Maine RCV primary results (Dunlap over Golden's open-seat field; LePage secured R nomination) — [NBC News](https://www.nbcnews.com/politics/2026-election/maine-resolves-ranked-choice-primaries-setting-governors-race-key-hous-rcna350415) [CITED]
- Steny Hoyer (MD-5) retiring; 2026 House retirement tracker — [Ballotpedia](https://ballotpedia.org/List_of_U.S._House_incumbents_who_are_not_running_for_re-election_in_2026), [NPR retirement tracker](https://www.npr.org/2025/09/15/nx-s1-5534254/house-senate-retirement-tracker-2026) [CITED]

### Tertiary (LOW confidence — single-source, not independently cross-checked)

- Primary dates for TN, MN, MO, WI, CO, SC, KY, CT, OK, AR, IA, KS, MS, NM, NE, WV, ID, HI, NH, RI, MT, DE, ND, SD, VT, WY — sourced from the single NCSL WebFetch table this session; NOT independently cross-verified against a second source. Given the Phase-154 lesson (VA's primary-date change from training data was caught only by explicit verification), recommend each per-state research agent (D-01) re-confirm its assigned state's exact date against an official SoS source before finalizing that state's field-table row. [ASSUMED, pending per-state re-verification]
- Jared Golden (ME-2) not seeking re-election — synthesized from a single WebSearch result; not independently corroborated with a second named source in this session. [ASSUMED]

---

## Metadata

**Confidence breakdown:**
- DB-diagnostic findings (incumbent map, stance-gap, collision audit, pre-existing race sweep): **HIGH** — all executed live against prod this session, fully reproducible
- Primary-date classification (decided/late-primary split): **MEDIUM overall** — HIGH for the 7 spot-verified states (MD, MA, AZ, WA, AK, AL, LA) and the 3 DB-corroborated states (IN, NV, UT, ME); MEDIUM (single NCSL source) for the remaining ~27 states, flagged for per-state re-verification in D-01's dispatched research
- Ballot-system taxonomy (WA/AK/ME/LA nonstandard systems): HIGH — each independently cited from 2+ sources
- Template script patterns (Queries A/B/C, verify.sql style): HIGH — read directly from Phase 154 source files and re-proven against the 38-state scope this session

**Research date:** 2026-07-03
**Valid until:** 2026-07-21 (Arizona's primary — the earliest still-future Wave-3 primary date — after which AZ's field_status flips from late-primary to decided and must be re-classified; broader re-verification recommended before each seeding-phase wave begins per D-01a's first-wave-validation discipline)
