# Phase 157: NJ Candidate Seeding (create elections + races, then candidates) - Context

**Gathered:** 2026-07-01
**Status:** Ready for planning
**Source:** Auto-generated from Phase 155 anchor decisions (D-01..D-06) + Phase 156 (OH/GA/NC) inheritance + Phase 154 NJ field findings — inherited pipeline; new decisions only where NJ differs from the prior waves (NJ is the SIMPLEST state so far: no true vacancy, no zero-stance incumbent, one uncontested seat).

<domain>
## Phase Boundary

Phase 157 seeds the full Nov-3, 2026 general candidate field for all **12 NJ US House districts** (geo_id 3401..3412) onto `/elections`, applying the Phase 155/156-validated create-races-first pipeline. Independent of Phases 155/156 (disjoint states) but sequenced after them to inherit the proven pipeline (`_push_relaxed.ts`, `_fed24-scale-block.txt`, the `156-verify.sql` gate shape, `seed-oh-ga-nc-house-headshots.py` conventions).

Structural shape = Phase 150/155/156 (TX/NY/PA/IL/OH/GA/NC), NOT CA turnkey: NJ has **no `essentials.elections`/`races` rows yet** — author them first, then wire `race_candidates`. All 12 rows in `154-field-table.csv` carry a BLANK `existing_race_id`.

In scope (USHC2-02/03/04/05 — NJ portion):
- `essentials.elections` "NJ 2026 Statewide General" (`election_date='2026-11-03'`).
- `essentials.races` per district (geo_id 34NN) on the district's existing U.S. Representative office (`office_id` NEVER NULL).
- `race_candidates` on every race (`politician_id`-linked, `candidate_status='active'`, incumbent `is_incumbent=true`).
- New `essentials.politicians` for the ~15 genuinely-new candidates (D-03 dedup confirms).
- Headshots for every new candidate (find-headshots conventions; expect mostly honest-skips per 155/156 precedent).
- Federal-24 chairs-not-polarity stances for every new candidate. **No incumbent stance work** — see D-01.

Out of scope: PA/IL (Phase 155, done), OH/GA/NC (Phase 156, done), MI+VA (Phase 159, date-gated Aug-4 primary), the 89-district gate (Phase 158), all already-stanced (partial) NJ incumbents.

Source-of-truth field: `154-field-table.csv` + `154-FIELD-TABLE.md` (NJ rows, `field_status=decided`) + `154-incumbent-map.csv`. Consumed, not re-derived.
</domain>

<decisions>
## Implementation Decisions

### D-01: Incumbent stance scope — NJ has ZERO in-scope incumbents (all 12 are partial, untouched) [LOCKED — 155/156 D-01 + 154 finding]
Per Phase 154's diagnostic, every one of NJ's 12 incumbents is PARTIAL (stance counts 6–23) and left as-is (NOT topped up). **Unlike Phase 156, NJ has NO zero-stance incumbent** (NC-6 McDowell was the only zero-stance incumbent in all of Wave 2). Therefore the NJ stance in-scope set = **the ~15 new candidates ONLY**; every existing NJ incumbent record is untouched (no `_push.ts` existing-record top-up in this phase).

Per-district incumbent stance counts (all partial, all untouched): NJ-1 Norcross 17, NJ-2 Van Drew 16, NJ-3 Conaway 9, NJ-4 Smith 15, NJ-5 Gottheimer 17, NJ-6 Pallone 23, NJ-7 Kean 10, NJ-8 Menendez 11, NJ-9 Pou 9, NJ-10 McIver 6, NJ-11 Mejia 7, NJ-12 Watson Coleman 18.

### D-02: Third-party / minor-line candidates = SEED ALL + honest-skip thin ones [LOCKED — 155/156 D-02]
NJ carries a modest minor-line field: NJ-3 **Steven Welzer (Green)** + **Ryan Michael Kelly (Affordability Accountability People)**; NJ-5 **Adam Rueda (Humane Sustainable Future)**. Seed EVERY ballot-qualified Nov-3 general candidate as an active `race_candidate` (party-agnostic card). Research stances normally; thin/no-source minor candidates → whole-record honest-skip, pinned by UUID in `157-verify.sql`. Do NOT drop minor candidates.

### D-03: Mandatory pre-insert live-DB dedup + certified-general re-confirm [LOCKED — 155/156 D-03]
Query live DB by name before any insert; reuse existing `politician_id` if found; enforce 0 duplicate `full_name`. NJ's June 2026 primary is held → the renominated field is reliable. Source-of-truth for the certified field: `154-field-table.csv` NJ rows (Wikipedia `2026_United_States_House_of_Representatives_elections_in_New_Jersey` + newjerseyglobe "final list of who's running" for NJ-8/10/11). Some NJ nominees may be sitting state legislators/officials with existing records — live-confirm each before inserting a new record.

### D-04: Uncontested / retired / special-seated handling — NO true vacancy in NJ [LOCKED — 155/156 D-04, NJ specifics]
The sitting incumbent who is NOT wired as an active nominee keeps its `politician_id` but gets no active `race_candidates` row where applicable. NJ flags (154-FIELD-TABLE.md):
- **NJ-8 (Menendez) — UNCONTESTED**: Robert Menendez (D) is the only Nov-3 general candidate. Wire ONLY the incumbent (`is_incumbent=true`, active). **0 new records** for NJ-8. Not an error — a single-candidate general.
- **NJ-11 (Mejia) — SPECIAL-SEATED, ALREADY IN DB**: Analilia Mejia (`93874414-6d14-4c12-87b2-d254b3855570`, external_id `-34011`, sc=7) is **already seeded as the incumbent** (Phase 154 finding #2). **REUSE her existing record** as the active `is_incumbent=true` candidate — do NOT create a new Mejia record. ⚠ The ROADMAP goal's parenthetical "special-seated member Mejia, not yet in DB" is **STALE** — 154's diagnostic verified she IS in the DB. Joe Hathaway (R) is the only new NJ-11 record.
- **NJ-12 (Watson Coleman) — RETIRED (open seat)**: Bonnie Watson Coleman (`a75a3e6e-…`, `-34012`) keeps her pid but gets **NO active `race_candidates` row**. Both nominees Adam Hamawy (D) + Gregg Mele (R) are new records. **This is a RETIREMENT, not a vacancy** — the district's office AND the incumbent politician record already exist, so (unlike GA-13 in Phase 156) there is **NO office to create and NO ghost-incumbent concern**. Pin the incumbent-absent (Watson Coleman has 0 active race_candidates row) in the gate.
- All other 10 NJ districts are `renominated`: reuse the incumbent_pid from `154-incumbent-map.csv` as the active `is_incumbent=true` candidate.

### D-05: Phase structure = ONE phase, planner waves [LOCKED — 155/156 D-05]
Single phase; 6 plans across 4 waves (leaner than 156's 10 because NJ is one state, 12 districts, no vacancy-office, no incumbent top-up):
- **W1**: 157-01 election/race authoring (1 election + 12 races) + 157-02 write-free `157-verify.sql` gate (test infra, nyquist).
- **W2**: 157-03 records + `race_candidates` wiring (all 12 NJ districts, ~15 new + reused incumbents).
- **W3**: 157-04 headshots (the ~15 new candidates) + 157-05 federal-24 stances (the ~15 new candidates; NO incumbent target).
- **W4**: 157-06 consolidated gate green + coordinate smoke.

### D-06: race_candidates + stance integrity conventions [INHERITED — project invariants]
- **race_candidates**: non-null `politician_id`, `candidate_status='active'`, incumbent `is_incumbent=true`. NEVER `office_id IS NULL`; NEVER party on the card (party via `races.primary_party`, kept NULL for multi-candidate generals).
- **Stance integrity**: chairs-not-polarity; every answer paired to `inform.politician_context` with a real fetched source URL; **0 unsourced**; honest-skip (per-topic or whole-record) where thin; **primary-source verification pass before push** (agent self-audit + 0-unsourced push filter + chairs-not-polarity framing, per 155/156). Wipe `essentials.quotes` per pid before re-push on quote correction.
- **external_id for new candidates**: `-(state_fips*10000 + cd*100 + seq)` — **NJ fips=34**, so band `-3401NN … -3412NN` (e.g. NJ-1 Galdo `-340101`; NJ-3 McGuire/Welzer/Kelly `-340301/-340302/-340303`; NJ-12 Hamawy/Mele `-341201/-341202`). No collision with the incumbent band `-34001..-34012`. Verify 0 collisions before insert. New records → UUID stance path (`_push_relaxed.ts` — resolve each new pid's UUID at push time, per 156).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 154 source-of-truth (the locked NJ field)
- `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-field-table.csv` — per-district NJ field (rows `NJ,1..12`); all have empty `existing_race_id`; `general_candidates` + `new_records_needed` + `nominee_status` columns are the seed spec.
- `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-FIELD-TABLE.md` — non-incumbent-nominee flags (NJ-11 special-seated, NJ-12 retired) + new-record count (NJ 15).
- `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-incumbent-map.csv` — NJ geo_id 34NN → incumbent_pid + external_id (reuse source; Mejia -34011 + Watson Coleman -34012 both already in DB).

### Phase 155/156 pattern (the just-validated pipeline this phase repeats)
- `.planning/phases/156-oh-ga-nc-candidate-seeding-create-elections-races-then-candi/156-CONTEXT.md` — the OH/GA/NC decisions this mirrors.
- `.planning/phases/156-…/156-01-PLAN.md` (elections+races authoring), `156-03/04/05-PLAN.md` (per-state records+wiring), `156-06` (headshots), `156-07/08/09` (stances), `156-10-PLAN.md` (gate+smoke) — adapt for single-state NJ.
- `backend/migrations/1127_*` (OH/GA/NC elections+races scaffold precedent), `1128`/`1129`/`1130` (candidate seed precedent). NO vacancy-office precedent needed (NJ has no true vacancy).
- `backend/scripts/156-verify.sql` (gate template — adapt: 1 state, geo prefix 34; NO zero-stance-incumbent target; NJ-8 uncontested = 1 active row; NJ-11 Mejia reused-incumbent; NJ-12 Watson Coleman incumbent-absent pin), `156-coordinate-smoke.ts` (smoke template).
- `backend/scripts/seed-oh-ga-nc-house-headshots.py` (parameterize `--state NJ` with band; model `seed-nj-house-headshots.py`), `backend/data/stance-research/_push_relaxed.ts` (robust stance push), `backend/data/stance-research/_fed24-scale-block.txt` (24 topic scales).

### Conventions
- `.planning/STATE.md` "v2.21 Execution Methodology" (prod ref `kxsdzaojfaibhuzmclfq`, create-races-first, external_id scheme, stance pipeline, fetch-walls). Scripts run from `backend/` with `set -a && source .env && set +a`.
- Memory: [[project-149-stance-gate-standard]] (0-unsourced + ≥1-sourced-or-pinned-skip), [[project_phase156_complete]] (the executed 156 run + traps: session-limit re-dispatch, cwd resets, malformed-CSV repair, homonym headshot guard, band pollution → scope via race_candidates joins).
</canonical_refs>

<specifics>
## Specific Ideas
- Election name: "NJ 2026 Statewide General", date 2026-11-03. State FIPS: NJ=34. geo_ids 3401..3412.
- New-record count (154): NJ 15. D-03 dedup may adjust.
- The 15 new candidates (per 154 `new_records_needed`): NJ-1 Damon Galdo (R); NJ-2 Zack Mullock (D); NJ-3 Michael McGuire (R) + Steven Welzer (Green) + Ryan Michael Kelly (Affordability Accountability People); NJ-4 Rachel Peace (D); NJ-5 Sean Kirrane (R) + Adam Rueda (Humane Sustainable Future); NJ-6 Hillary Herzig (R); NJ-7 Rebecca Bennett (D); NJ-9 Rosie Pino (R); NJ-10 Carmen Bucco (R); NJ-11 Joe Hathaway (R); NJ-12 Adam Hamawy (D) + Gregg Mele (R). (NJ-8 = 0 new, uncontested.)
- **NJ-8 uncontested**: only Menendez active (single-candidate general — not an error).
- **NJ-11 Mejia**: already in DB (`-34011`) — reuse as active incumbent; Hathaway new. ROADMAP "not yet in DB" is stale.
- **NJ-12 Watson Coleman**: retired → incumbent pid kept, NO active row; Hamawy + Mele new. Retirement ≠ vacancy → no office creation.
- Minor-line seed-all: NJ-3 (Green + Affordability Accountability People), NJ-5 (Humane Sustainable Future).
- external_id band NJ new = `-3401NN..-3412NN` (fips*10000 + cd*100 + seq); no overlap with incumbent `-34001..-34012`.
</specifics>

<deferred>
## Deferred Ideas
- Top-up of partial NJ incumbents to full-24 — deferred (D-01).
- Challenger FEC finance — out of scope (v2.22+).
- MI+VA (Phase 159, date-gated Aug-4), 89-district consolidation gate (Phase 158).

### Reviewed Todos (not folded)
None — scope inherited cleanly from 155/156.
</deferred>

---

*Phase: 157-nj-candidate-seeding-create-elections-races-then-candidates*
*Context gathered: 2026-07-01 via plan-phase auto-generate (155/156 anchor decisions + 154 NJ field)*
