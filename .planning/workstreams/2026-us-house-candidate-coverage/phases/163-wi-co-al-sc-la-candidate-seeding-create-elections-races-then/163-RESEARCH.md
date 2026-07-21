# Phase 163: WI + CO + AL + SC + LA US House Candidate Seeding - Research

**Researched:** 2026-07-05
**Domain:** Pure-data election seeding (Postgres/Supabase) — third Wave-3 seeding phase, cloning the proven Phase-161/162 pipeline; TWO of five states carry live mid-cycle redistricting (AL, LA) discovered fresh this session via WebSearch (real-time news through 2026-07)
**Confidence:** HIGH (mechanics are proven twice already); MEDIUM on AL/LA severity classification until the phase's own correspondence audits run (same posture 161 had for TN and 162 had for MO)

## Summary

Phase 163 is a **parameterization exercise, not new engineering** — every mechanic needed (per-state elections+races migration, external_id assignment, headshot pipeline, stance push pipeline, redistricted-state severity-routed withholding) was already built and proven twice (Phase 161: WA/AZ/TN/MA; Phase 162: IN/MD/MN/MO). This research's job is narrow: pin the state-specific facts that differ, hand the planner direct clone-templates, and flag the one thing that makes 163 harder than 162 — **two states (AL and LA), not one, are undergoing live mid-cycle redistricting**, and 163 is the first Wave-3 phase to need TWO correspondence audits plus a brand-new ballot-modeling pattern (LA's all-party "jungle" primary).

Live 2026 news research (WebSearch, verified through July 2026 sources) confirms Alabama's 2023 GOP-drawn map (1 majority-Black district, the one struck down in 2023 but reinstated by a SCOTUS stay in June 2026) governs a **special primary for AL-1/2/6/7 on 2026-08-11** — this is the same district set already flagged `late-primary` in Phase 160's field table, and it directly implies the DB's live AL polygons (drawn to match the 2024 court-ordered 2-majority-Black-district map, under which Shomari Figures was elected to the current CD-2) are **stale relative to the operative 2026 map** for those four districts — the exact MO/TN pattern. Louisiana's SB 121 (Act 2 of the 2026 Regular Session, signed 2026-05-29) dissolves the majority-Black CD-6 that elected Cleo Fields in 2024, reverting the state to (approximately) its pre-2024 map; a federal three-judge panel's scheduled June 17 challenge hearing was **cancelled** after the state successfully argued Purcell-principle timing, so **SB121 stands as the operative map** for the Nov-3 jungle primary and any Dec-12 runoff. LA is *also* a stale-DB-polygon case. **Phase 163 needs its own D-01-style correspondence audits for BOTH AL and LA before seeding either state** — a first for Wave 3 (161/162 each only needed one).

**Primary recommendation:** Clone `161-tn-generate.mts`/`162-mo-*` patterns for AL and LA (severity-routed withholding), clone `161-az-generate.mts`/`162-mn-generate.mts` for WI/SC/CO (vanilla new-election, no withholding), and introduce ONE new pattern never used in 161/162: LA's jungle-primary race modeling (clone the CA top-2 jungle-primary convention already in the codebase — `primary_party = NULL` on the single Nov-3 race per district; do NOT model a separate primary race). Run AL + LA correspondence audits FIRST (mirrors 161-01/162-01), before any AL/LA seeding.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Election/race authoring (elections, races rows) | Database / Storage | — | Pure data via migration SQL; no service-layer writes |
| Race surfacing on `/elections` | API / Backend (read path) | Database | `electionService.ts` reads races+race_candidates+districts+geofence_boundaries; zero code changes this phase |
| Candidate record creation (politicians, race_candidates) | Database / Storage | — | Pure data via migration SQL |
| AL + LA old-vs-new district correspondence audits | Research/analysis (no tier) | — | Pure research artifacts; no runtime component; gate downstream seeding |
| LA jungle-primary race modeling | Database / Storage | API / Backend (read path) | Single non-partisan race (`primary_party=NULL`), same `electionService.ts` read path as every other race — no code change, just a data-shape choice already proven by the CA pattern |
| Headshot ingestion | Backend script (offline) | Database / Storage | `backend/scripts/seed-*-house-headshots.py` pattern, outside request path |
| Stance research + push | Backend script (offline) | Database | `_merge.ts`/`_push.ts`/`_push_uuid.ts`; writes via `pool.query()`, never PostgREST |
| Consolidated read-only mini-gate (36-district) | Database (read-only) | — | `psql -v ON_ERROR_STOP=1 -f 163-verify.sql` against prod, clone of `162-verify.sql` |

No frontend/browser tier work exists in this phase (identical to 161/162).

<user_constraints>
## User Constraints (from CONTEXT.md)

**No `163-CONTEXT.md` exists at research time** — `/gsd:discuss-phase 163` has not yet been run. This RESEARCH.md is written to inform that discussion (or direct planning if the operator skips discuss-phase, as the pipeline is now well-established). The **carried-forward standing decisions from Phase 161/162** (D-01 redistricting-handling pattern, D-01a audit-first, D-01b severe-gate mechanism, D-01c un-gate-in-164.1, external_id scheme, stance/headshot pipeline discipline) apply here by project convention (`.planning/STATE.md` "v2.22 Execution Methodology") and should be treated as pre-locked unless discuss-phase overrides them. If discuss-phase runs before planning, the two open decisions it should confirm are: (1) whether AL's and LA's severe-district withholding gets ONE combined audit plan or two separate ones (this research recommends one combined plan, two tasks — see Plan Structure below), and (2) whether LA's contingent Dec-12 runoff is explicitly deferred to Phase 167 (this research recommends yes — it cannot be known who needs a runoff until after Nov-3 results).

### Carried Forward (locked — do not re-litigate; from Phase 161/162 / milestone standing standards)
- Full provisional field seeded NOW marked `PROVISIONAL:` for late-primary states (WI/AL/LA); only the post-primary cull (Phase 167) is date-gated.
- Full federal-24 sourced stances per candidate; 0-unsourced gate floor; chairs-not-polarity; never party-inferred; honest-skip (per-topic or whole-record) only with a written search trail, whole-record skips gate-pinned; mandatory primary-source verification pass before push.
- `race_candidates`: non-null `politician_id`, `candidate_status='active'`, incumbents `is_incumbent=true`; NEVER party on the candidate card (`races.primary_party` only); NEVER `office_id IS NULL` on a House race.
- external_id band `-(state_fips*10000 + cd*100 + seq)` for NEW challengers; FIPS: WI=55, CO=08, AL=01, SC=45, LA=22. Existing incumbents use the OLDER legacy scheme `-(state_fips*1000 + seq)` (verified live against prod this session — see Must-Answer #3) — never recompute or touch an incumbent's external_id.
- Incumbents reuse existing records (identity by `(district_type='NATIONAL_LOWER', geo_id)` join, never computed external_id); zero duplicate `full_name` per state.
- Stance agents at 3-concurrency max, first-wave output validation, exact 1–5 scale texts embedded per topic (`_TOPIC_SCALE_FULL.txt`); headshots via find-headshots conventions — trust the auto-guard's first-name-mismatch rejection.
- Migrations idempotent (NOT EXISTS guards); pure-data changes need no deploy. Push each stance batch to PROD as it completes (stance CSVs are gitignored → PROD is the durable store).
- D-01/D-01a/D-01b/D-01c redistricting-handling pattern from 161/162 (audit first → severity-score every district from named sources → seed-but-withhold severe districts via election_id substitution to a non-surfacing "Polygon Pending"-style election → un-gate in already-committed Phase 164.1).

### Deferred Ideas (OUT OF SCOPE for 163)
- Cross-state district polygon refresh / dual-map design (TN, MO, AL, LA, UT) — Phase 164.1 (already committed in `.planning/STATE.md`, confirms AL+LA are EXPECTED redistricting-affected states, corroborating this research's independent WebSearch findings).
- LA's contingent Dec-12, 2026 runoff races — cannot be authored until Nov-3 results are known; belongs in Phase 167 (or a dedicated LA runoff follow-up) not 163.
- AL-1/2/6/7 Aug-11 special-primary RESULT reconciliation (pruning the non-winning primary candidates) — Phase 167, same class as MO's Aug-4/MN's Aug-11 primary culls from 162.
- SC independent-candidate late filings (window closes 2026-07-15) — re-check at 163 execution time; if execution is after Jul-15, either re-pull SC or note it for Phase 167.
- Challenger `finance_summary` — out of scope; record no-FEC-ID rather than retry.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| USHC3-02 | Every candidate has exactly one `essentials.politicians` record; incumbents reuse; party normalized; collision-free external_ids | Per-State Audit Table below (incumbent pid/external_id map); Must-Answer #3 (0 collisions verified live) |
| USHC3-03 | Every race surfaces on `/elections` via `races`+`race_candidates`; elections/races authored first; never `office_id IS NULL` | AL + LA correspondence-audit requirement (Critical Question 1); LA jungle-primary modeling (Critical Question 2) |
| USHC3-04 | Every newly-seeded candidate has a headshot (or documented honest-skip) | Pipeline templates section — clone `seed-{az,wa,tn,ma,in,md,mn,mo}-house-headshots.py` verbatim with new `BANDS` entries |
| USHC3-05 | Every newly-seeded candidate has sourced federal-24 stances, 0-unsourced, honest-skip with search trail | Stance Scope section below (101 new-candidate targets, 0 zero-tier incumbents) |
</phase_requirements>

## Per-State Audit Table

All 36 districts confirmed live on prod: `essentials.districts` + `essentials.offices` + incumbent `essentials.politicians` rows already exist for WI/CO/AL/SC/LA (queried directly, 2026-07-05); **0 pre-existing 2026-11-03 `essentials.races` rows** for any of the 5 states (confirmed live — all 5 need the full create-races-first pattern, none are MD-style reuse states).

| State | Districts | Primary Date | Decided/PROVISIONAL | Redistricting / Severe geo_ids | Notes |
|-------|-----------|--------------|----------------------|----------------------------------|-------|
| **WI** | 8 (5501-5508) | 2026-08-11 (statewide) | **late-primary** (all 8) — full field PROVISIONAL | None — map stable, no redistricting flag found | WI-2 (5502) has NO Republican filed (2-candidate all-D ballot) — verified, not an error. WEC (elections.wi.gov) Cloudflare-walled even via r.jina.ai; source via Wikipedia raw wikitext + WEC-quoting news. |
| **CO** | 8 (0801-0808) | 2026-06-30 (already held) | **decided** (all 8) — unofficial-but-decisive results, clear margins | None — map stable | **CO-1 UPSET: Diana DeGette (D, 19 existing stances) LOST her primary to Melat Kiros 53.2–39.8.** DeGette's existing incumbent record is untouched (still sitting Rep until Jan 2027) but she is NOT a CO-1 general-election candidate — do not add her to the new `race_candidates` row. Kiros is a wholly new record. This is a THIRD distinct incumbent-transition pattern (distinct from "retired" and from Phase-162's Craig MN-2 "running for a different office" REUSE-NO-ROW) — call it **"incumbent-lost-primary, stays incumbent-only, does not appear on the new race."** |
| **AL** | 7 (0101-0107) | AL-3/4/5 already decided (May-19 / Jun-16); **AL-1/2/6/7 special primary 2026-08-11** (SCOTUS-ordered redraw) | **SPLIT within one state**: AL-3/4/5 (0103/0104/0105) = **decided**; AL-1/2/6/7 (0101/0102/0106/0107) = **late-primary** (full qualified field already known — 21 candidates qualified May-22 — only the WINNER is undetermined; no runoff, top vote-getter advances) | **LIKELY SEVERE: AL-1/2/6/7 (0101/0102/0106/0107).** NOT-SEVERE: AL-3/4/5 (0103/0104/0105). Confidence: MEDIUM-HIGH (real-time WebSearch-verified, not yet run through the formal correspondence-audit rubric) — see Critical Question 1 below. | Live WebSearch (2026-07 sources) confirms: 2023 Alabama-drawn map (1 majority-Black district; the very map struck down by a 3-judge panel in May 2026 as intentionally discriminatory) was reinstated by a **SCOTUS stay in June 2026** for the 2026 cycle only. Gov. Ivey called the Aug-11 special primary specifically for the four districts whose lines moved (1, 2, 6, 7) — this 4-district split is IDENTICAL to Phase 160's `late-primary` classification, corroborating the redistricting hypothesis. Figures (AL-2, currently the CD-2 incumbent elected 2024 under the now-superseded 2-majority-Black-district map) faces 6 Republicans with no Democratic primary opponent. |
| **SC** | 7 (4501-4507) | Already held (primaries complete) | **decided** (all 7) | None — map stable | `filing_open_deadline=2026-07-15` — independent/petition window is OPEN as of this research date (2026-07-05); **re-check at plan/execution time** — if execution slips past Jul-15, either re-pull SC or flag for Phase 167. |
| **LA** | 6 (2201-2206) | **No party primary** — all-party "jungle" ballot Nov-3; qualifying window **2026-08-05 to 08-07**; contingent runoff **Dec-12-2026** if no candidate clears 50% | **late-primary / declared-so-far** (all 6) — field is "structurally unknowable until qualifying closes" (LA-5 alone already has 13 declared candidates); re-pull mandatory after Aug-7 | **LIKELY SEVERE: a subset of LA-1/4/5/6 (2201/2204/2205/2206).** LIKELY NOT-SEVERE: LA-2 (2202, Carter, New Orleans anchor historically stable) and LA-3 (2203, Higgins, southwest Acadiana, geographically distant from the dissolved corridor). Confidence: MEDIUM (real-time WebSearch confirms the CD-6 dissolution and a "return to ~2022 map" description, but exact per-parish reassignment to CD-1/4/5 was not found at source-URL granularity this session) — see Critical Question 1 below. | Gov. Landry signed SB 121 (Act 2 of the 2026 Regular Session) 2026-05-29, dissolving the majority-Black CD-6 (Cleo Fields, elected 2024 under the prior SB8 map) and reverting toward the pre-2024 (~2022) map: 5 safe-R districts + 1 D district (CD-2, New Orleans). A federal 3-judge panel's June 17 hearing to challenge SB121 was **cancelled** after the state successfully invoked Purcell-principle "no last-minute changes" reasoning (citing the SCOTUS *Allen v. Milligan* stay language) — **SB121 stands as the operative 2026 map**, no live injunction as of this research date. |

## Critical Question 1 — Redistricting / Severe-District Withholding (ANSWERED, MEDIUM-HIGH confidence, audit still required)

**WI, CO, SC: NOT redistricted.** No named source found describing any 2026 boundary change for these three states; DB polygons are presumed current. No correspondence audit needed — proceed with the vanilla 161-az/162-mn "new-election" seeding pattern.

**AL: REDISTRICTED, mid-cycle, confirmed via live WebSearch this session.** Sequence of events (all sourced, dated 2026): AL's 2023 GOP-drawn map (1 majority-Black district) was struck down as unconstitutional by SCOTUS-affirmed lower-court rulings years ago; a federal court imposed a 2-majority-Black-district remedial map used for the 2024 election (under which Shomari Figures was elected AL-2). In May 2026 a 3-judge panel again struck down the 2023 map as intentionally discriminatory when Alabama's legislature tried to reuse it — but in June 2026 SCOTUS granted Alabama a stay, **reinstating the 2023 map for the 2026 cycle only**. Gov. Ivey called an Aug-11 special primary for the four affected districts (AL-1, AL-2, AL-6, AL-7). Because the DB's current AL district polygons were seeded to match the 2024 remedial map (the one under which Figures currently holds AL-2), **those same four districts' boundaries are changing again for 2026** — this is architecturally identical to the MO/TN stale-polygon situation from 161/162. **Recommendation: AL-1/2/6/7 are the predicted severe set; AL-3/4/5 predicted not-severe** (this maps 1:1 onto Phase 160's decided/late-primary split, which is a strong corroborating signal but not itself the correspondence-audit rubric). Sources: [Alabama Reflector — "Supreme Court allows Alabama to use 2023 congressional map"](https://alabamareflector.com/2026/06/02/supreme-court-allows-alabama-to-use-2023-congressional-map-in-august-special-primary/), [WSFA — "Supreme Court rules Alabama can use 2023 congressional map for 2026 election cycle"](https://www.wsfa.com/2026/06/03/supreme-court-rules-alabama-can-use-2023-congressional-map-2026-election-cycle/), [Alabama Reflector — "As litigation continues, 21 candidates qualify"](https://alabamareflector.com/2026/05/22/as-litigation-continues-21-candidates-qualify-for-august-alabama-congressional-primaries/), [Governor Ivey's newsroom announcement](https://governor.alabama.gov/newsroom/2026/05/governor-ivey-celebrates-major-court-victory-in-states-redistricting-battle-calls-special-election-for-alabama-drawn-congressional-map/).

**LA: REDISTRICTED, mid-cycle, confirmed via live WebSearch this session.** SCOTUS's April 29, 2026 *Louisiana v. Callais* ruling (6-3) struck down LA's 2-majority-Black-district map (the SB8 map that elected Cleo Fields to CD-6 in 2024) as an unconstitutional racial gerrymander. The Legislature passed, and Gov. Landry signed (2026-05-29), SB 121 (Act 2), dissolving CD-6 and reverting the state to approximately its pre-2024 (2022) composition: 5 safe-R districts + 1 D district (CD-2, New Orleans, Troy Carter). A federal 3-judge panel's scheduled challenge hearing was cancelled; SB121 is the operative map with no live injunction. **Recommendation: run the formal correspondence audit on all 6 LA districts** (unlike AL, the late-primary/decided split does not cleanly predict severity here, because ALL 6 LA districts are `late-primary` due to the jungle-primary qualifying window, not due to redistricting specifically) — predicted severe = LA-1/4/5/6 (touched by the CD-6 corridor's dissolution and reabsorption into neighboring districts), predicted not-severe = LA-2 (Carter, historically stable New Orleans anchor) and LA-3 (Higgins, geographically distant Acadiana anchor), but this is a WEAKER hypothesis than AL's (no exact per-parish reassignment source was found this session — the audit task must do the county/parish-level gather-and-score work, same as 161-01/162-01). Sources: [NOLA.com — "Gov. Jeff Landry signs Louisiana's new congressional map"](https://www.nola.com/news/politics/legislature/jeff-landry-signs-louisiana-redistricting-bill-congress/article_770ef156-f8b0-442d-9c22-d555b2ff1466.html), [Louisiana Illuminator — "Louisiana Senate committee drops one of two majority-Black districts"](https://lailluminator.com/2026/05/13/louisiana-senate-committee-drops-one-of-two-majority-black-districts-in-advancing-map/), [KSLA — "Federal court sets June hearing on Louisiana's new congressional map"](https://www.ksla.com/2026/06/02/federal-court-sets-june-hearing-louisianas-new-congressional-map/), [The Advocate — "Louisiana likely to use new congressional map for 2026 midterms despite looming court challenge"](https://www.theadvocate.com/baton_rouge/news/politics/louisiana-callais-congressional-map-2026-midterm-elections/article_5000e785-29f5-57c7-9f2b-67495938d488.html), [Wikipedia — Louisiana v. Callais](https://en.wikipedia.org/wiki/Louisiana_v._Callais).

**Withholding mechanism (recommendation, mirrors 161/162 D-01b exactly):** For each severe geo_id, wire its race's `election_id` to a NEW non-surfacing election row (e.g., `'AL 2026 Congressional Redistricting - Polygon Pending'` / `'LA 2026 Congressional Redistricting - Polygon Pending'`, dated to the relevant court/legislative action so `electionService.ts`'s `ELECTION_VISIBILITY_WINDOW` evaluates false) — races/candidates/stances still get fully seeded, just don't surface on `/elections`. Non-severe districts wire to the normal `'AL 2026 Statewide General'` / `'LA 2026 Statewide General'` election. **164.1 (already committed, confirmed in `.planning/STATE.md` to cover TN/MO/AL/LA/UT) un-gates these on polygon refresh** — no new roadmap insertion needed, exactly like MO's carry-forward from 162.

**Do NOT under-scope.** Both 161's TN audit (5/9 severe, more than the pre-audit guess of ~2) and 162's MO audit (5/8 severe, more than the pre-audit guess of ~1-3) expanded well beyond their initial hypotheses once county-level evidence was gathered. Budget for AL's and LA's severe sets to potentially be LARGER than this research's 4-of-7 and 4-of-6 predictions — run the full rubric (>25% population moved OR anchor city/county changed) against every district in both states, not just the predicted ones.

## Critical Question 2 — LA Ballot Modeling (jungle/open primary)

Louisiana's system: **all candidates, regardless of party, appear on ONE ballot on 2026-11-03.** A candidate needs >50% to win outright; otherwise the top two proceed to a **runoff on 2026-12-12**. This is structurally the same non-partisan-blanket pattern the codebase already implements for California (`backend/scripts/seed-la-citywide-races-2026.sql`, `backend/scripts/ingest-ca-sos-2026-challengers.ts`) — confirmed live: `essentials.races.primary_party` is nullable, with a unique index `idx_races_election_position_no_party ON (election_id, position_name) WHERE primary_party IS NULL` specifically supporting this exact shape.

**Recommendation:** Model each LA district as **ONE race per district on the `'LA 2026 Statewide General'` (or withheld-equivalent) election, `primary_party = NULL`**, with every qualified candidate (regardless of party) wired into `race_candidates` for that single race — clone the CA jungle-primary convention verbatim, do NOT create separate party-primary races. **Do NOT attempt to model the contingent Dec-12 runoff in Phase 163** — which districts need a runoff cannot be known until Nov-3 results are in; this is a Phase 167 (or dedicated LA-runoff follow-up) concern, matching the "only the post-primary cull is date-gated" principle already established for MO/MN/WI. `ballot_system=open-primary-nov3` is already recorded per-row in `160-field-table-p163.csv` for exactly this purpose.

**LA qualifying nuance:** qualifying doesn't close until 2026-08-07 — the 6 rows in `160-field-table-p163.csv` are "declared-so-far" captures (LA-5 alone already has 13 declared candidates for an open seat). Per the standing PROVISIONAL-field principle, seed the full declared-so-far field NOW; Phase 163 (or 167) must re-pull after Aug-7 to catch late qualifiers and confirmed withdrawals.

## Critical Question 3 — Incumbent Dedup Map

Full incumbent map (pid, external_id, current stance count, top-up tier) is captured verbatim in `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-field-table-p163.csv` and cross-verified live against prod this session (query below). **All 36 incumbents show `incumbent_top_up_tier=partial`** — unlike Phase 162 (which had 11 zero-tier incumbents: MD's all 8 + IN's Baird/Carson/Messmer requiring full stance research), **Phase 163 has ZERO zero-tier incumbents**. Per the standing USHC3-05 principle ("already-stanced incumbents skipped via the stance-gap diagnostic") and the 162 precedent ("partial-tier incumbents NOT topped up"), **no incumbent stance work is in scope for 163** — stance research scope is 100% new-candidate records.

**Live-verified incumbent identity (2026-07-05, read-only query against prod):**
```sql
SELECT d.state, d.geo_id, o.politician_id, p.full_name, p.external_id
FROM essentials.districts d
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p ON p.id = o.politician_id
WHERE d.district_type='NATIONAL_LOWER' AND d.state IN ('WI','CO','AL','SC','LA')
ORDER BY d.state, d.geo_id;
```
Result: 36/36 rows returned, every `politician_id`/`external_id` pair matches `160-field-table-p163.csv` exactly (e.g. AL-2 = `e54e3ded-838d-4980-82c8-ef23c19118a7` / `-1002` Shomari Figures) — **0 drift between the Phase-160 snapshot and live prod**. All 36 incumbent legacy external_ids follow the OLDER `-(state_fips*1000 + seq)` scheme (e.g. WI = -55001..-55008, CO = -8001..-8008, AL = -1001..-1007, SC = -45001..-45007, LA = -22001..-22006) — this is DIFFERENT from the new-challenger band and must never be recomputed or touched.

**Incumbent departures / transitions (verified):**
- **AL-1 Barry Moore** — retired (running for Senate); AL-1 is an open seat.
- **LA-5 Julia Letlow** — retired (running for Senate); LA-5 is an open seat with 13 declared candidates.
- **SC-1 Nancy Mace + SC-5 Ralph Norman** — both retired (running for Governor); open seats.
- **WI-7 Thomas Tiffany** — retired (running for Governor); open seat.
- **CO-1 Diana DeGette** — **LOST her June 30 primary** to Melat Kiros 53.2–39.8. This is a NEW transition pattern for Wave 3 (distinct from "retired" and from 162's Craig MN-2 "different office" REUSE-NO-ROW): DeGette's existing incumbent record and office assignment are untouched (she remains the sitting Rep until Jan 2027 and her stance history stays intact), but she must NOT be added to CO-1's new `race_candidates` row — Melat Kiros (D, new record) and Christy Peterson (R, new record) are the CO-1 general-election field.
- All other 31 incumbents: renominated, seeking reelection, appear in their district's new `race_candidates` row alongside new challenger records.

**external_id collision check (live-verified, 2026-07-05):** queried the new-challenger band ranges (`-(state_fips*10000 + cd*100 + seq)`: WI -550101..-550899, CO -80101..-80899, AL -10101..-10799, SC -450101..-450799, LA -220101..-220699) against `essentials.politicians` — **0 collisions found** in any of the 5 bands. (One adjacent record, `-10000` Sarah McBride/DE, sits just outside AL's true sub-range and is not a collision.)

## Standard Stack

Zero new packages — identical to 161/162. All tooling reused verbatim: `pg`/`pool.query()` for all essentials/inform reads+writes, `psql -v ON_ERROR_STOP=1 -f` for migrations and the read-only verify gate, `psycopg2`+`requests`+`Pillow` (invoke via `py`) for the headshot pipeline, `node --import tsx`+`csv-parse/sync` for the `_merge.ts`/`_push.ts`/`_push_uuid.ts` stance pipeline, `.mts` one-off generator scripts for deterministic field→SQL migration generation.

## Package Legitimacy Audit

**N/A — this phase installs zero external packages.** All tooling is already installed and vetted in prior phases (148–162).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|--------------|-----|
| Old-vs-new district boundary comparison | A shapefile/GIS diff pipeline | Qualitative county/parish-level correspondence audit from named reporting (161-tn/162-mo pattern) | No GIS dependency needed; a written rubric + named sources is sufficient evidence and matches the project's proven methodology |
| Non-partisan "everyone on one ballot" race modeling | A new schema column or a custom multi-round race concept | `essentials.races.primary_party = NULL` (already-proven CA jungle-primary convention) | The schema already supports this exact shape (unique index specifically for `primary_party IS NULL`); no migration needed |
| Severe-district non-surfacing | A new "hidden" flag or a code change to `electionService.ts` | Election_id substitution to a non-surfacing "Polygon Pending"-style election row (161/162 D-01b) | Pure-data mechanism; zero backend code changes; proven twice already |

## Migration Numbering

**Next free migration number: `1220`** (verified live: highest existing migration file is `1219_portland_admin_chambers_no_compass.sql`; 1213 has a duplicate-numbered pair — `1213_seed_in_2026_house_elections_races.sql` and `1213_seed_washco_2026_local_races.sql` — a pre-existing quirk from a parallel session's work, not a 163 concern, but confirms migration numbers are NOT always strictly sequential/unique in this repo; verify the actual max via `ls backend/migrations | sort -n` at plan-authoring time, don't assume 1220 is still free if other work has landed since this research date).

## Recommended Plan Structure

Mirrors 162's 11-plan structure, expanded for two audits and one extra state (5 states vs 162's 4):

1. **163-01: AL + LA correspondence audits** (combined plan, 2 tasks — clone 161-01/162-01's "gather then score" structure per state) — produces `163-al-correspondence-audit.md` and `163-la-correspondence-audit.md`, each ending in a machine-readable `Severe geo_id list:` line. Runs FIRST, front-loaded, parallel with WI/CO/SC seeding work.
2. **163-02: WI seed** (vanilla new-election pattern, 8 districts, clone `162-mn-generate.mts`)
3. **163-03: CO seed** (vanilla, 8 districts; handle DeGette's lost-primary transition explicitly — do NOT create a CO-1 race_candidates row for her)
4. **163-04: AL seed** (severity-routed withholding per 163-01's audit; wires AL-1/2/6/7's races to the withheld election if scored severe)
5. **163-05: SC seed** (vanilla, 7 districts; re-verify the Jul-15 independent window hasn't produced new filings)
6. **163-06: LA seed** (jungle-primary modeling per Critical Question 2 + severity-routed withholding per 163-01's LA audit)
7. **163-07: WI stances** (28 new-candidate targets, 8 districts, 1-agent-per-district pattern, 3-concurrency)
8. **163-08: CO stances** (9 new-candidate targets, 8 districts — small, could combine with 163-03 seed plan at planner's discretion)
9. **163-09: AL stances** (21 new-candidate targets, 7 districts)
10. **163-10: SC stances** (16 new-candidate targets, 7 districts)
11. **163-11: LA stances** (27 new-candidate targets, 6 districts — LA-5 alone has 13)
12. **163-12: Consolidated verify + coordinate-smoke** (clone `162-verify.sql`/`162-coordinate-smoke.ts`; new assertion blocks: AL-SEVERE and LA-SEVERE non-surfacing, analogous to 162's MO-SEVERE block; positive coordinate-smoke samples for all 5 states + negative samples for AL/LA severe districts)

**Total new candidate records: 101** (WI 28 + CO 9 + AL 21 + SC 16 + LA 27) — comparable in scale to Phase 162's 129 targets (118 new + 11 zero-tier incumbents), but with ZERO incumbent top-up needed this phase (see Critical Question 3), so the stance workload is purely new-candidate research. Plan count/splitting (e.g., whether to combine small CO's 9-target stance work with its seed plan) is Claude's Discretion at plan-authoring time — the planner should feel free to consolidate small plans (CO, SC) and keep large ones (WI, LA, AL) as their own plans, matching 162's precedent of splitting MO's 58-record stance load into two plans while keeping IN/MD as single plans.

## Common Pitfalls

### Pitfall 1: Assuming AL's decided/late-primary split IS the correspondence-audit rubric
**What goes wrong:** Treating "AL-1/2/6/7 = late-primary" as sufficient proof they're SEVERE and skipping the formal audit.
**Why it happens:** The correlation is strong (both stem from the same redistricting event) but they are not logically identical — a district's primary-timing status answers "is the WINNER decided," not "did >25% of the population move or did the anchor county change." A district could theoretically be re-drawn just enough to trigger a new qualifying window without crossing the severity threshold.
**How to avoid:** Run the full rubric against all 7 AL districts (not just the predicted 4) with named-source county-level evidence, exactly as 161/162 did for TN/MO even when the "obvious" districts turned out to be correct.
**Warning signs:** An audit that finishes in under 15 minutes with zero new sources fetched is a sign the audit was skipped, not performed.

### Pitfall 2: Modeling LA's runoff prematurely
**What goes wrong:** Trying to pre-seed a `'LA 2026 Runoff'` election/race set in Phase 163 "to be thorough."
**Why it happens:** LA's ballot system has two rounds baked into state law, tempting a "model both now" instinct.
**How to avoid:** Only the general (Nov-3, all-party) round is knowable pre-election. Which districts need a runoff, and who the top-two are, cannot be determined until results are in. Defer entirely to Phase 167 or a dedicated follow-up.
**Warning signs:** A migration that creates a second LA election row dated December 2026 during Phase 163.

### Pitfall 3: Losing DeGette's stance history on the CO-1 transition
**What goes wrong:** Treating DeGette's primary loss like a "retirement" and archiving/deleting her existing 19 stances, or accidentally wiring her into the new CO-1 race_candidates row because she's still the district's `office.politician_id`.
**Why it happens:** CO-1's `office_id → politician_id` FK still points at DeGette (she's the sitting Rep until Jan 2027) — a naive "incumbent = office.politician_id" join would incorrectly pull her into the general-election candidate set.
**How to avoid:** Use Phase 160's field table (`nominee_status=lost-primary`) as the authoritative signal, not the raw office join. Seed only Kiros (D) and Peterson (R) as CO-1's `race_candidates`; leave DeGette's politicians/offices rows completely untouched.
**Warning signs:** A CO-1 race with 3 candidates instead of 2, or DeGette appearing on the `/elections` general-ballot card.

### Pitfall 4: SC independent window drift
**What goes wrong:** Seeding SC as fully "decided" and closed without re-checking `filing_open_deadline=2026-07-15`.
**Why it happens:** SC's field looks fully resolved (all 7 nominees known) so it's tempting to treat it identically to AL-3/4/5.
**How to avoid:** If Phase 163 executes on or after 2026-07-15, do a quick re-check for newly-qualified SC independents before finalizing the seed (mirrors 162's MD unaffiliated-window handling, D-04a).
**Warning signs:** A new SC independent candidate appearing in Phase 167's post-primary reconciliation that could have been caught at initial seed time.

## Stance Pipeline

Federal-24 topic set confirmed identical (`_TOPIC_SCALE_FULL.txt` exists per-state-cluster directory, e.g. `backend/data/stance-research/{az,fl,in}-2026-house/_TOPIC_SCALE_FULL.txt`; the phase should create `backend/data/stance-research/{wi,co,al,sc,la}-2026-house/` directories cloning that convention). 3-concurrency max on `politician-stance-researcher`, 1 agent per district, wave-based dispatch with first-wave validation (161/162 pattern). 0-unsourced gate floor; chairs-not-polarity; honest-skip (per-topic or whole-record) with a written search trail; mandatory primary-source verification pass before every push; wipe `essentials.quotes` per pid before re-push on any quote correction.

## Sources

### Primary (HIGH confidence — live prod queries, this session, 2026-07-05)
- `essentials.districts`/`essentials.offices`/`essentials.politicians` — confirmed all 36 WI/CO/AL/SC/LA districts exist with correct incumbent wiring, 0 drift from `160-field-table-p163.csv`
- `essentials.races` — confirmed 0 pre-existing 2026-11-03 races for any of the 5 states
- `essentials.races` schema (`\d essentials.races`) — confirmed `primary_party` nullable with a dedicated unique index for `WHERE primary_party IS NULL`, supporting the LA jungle-primary recommendation
- External_id collision query — 0 collisions in any of the 5 states' new-challenger bands

### Primary (HIGH confidence — prior-phase artifacts, directly reused)
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-field-table-p163.csv` — the 36-row field table (this phase's ground truth for candidates, nominee status, ballot_system, filing deadlines)
- `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-04-SUMMARY.md` — the field-resolution research narrative for WI/CO/AL/SC/LA, incl. the original AL-split and LA-jungle-primary discovery
- `.planning/phases/161-wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca/161-tn-correspondence-audit.md` — the exact audit structure/rubric to clone
- `.planning/phases/162-in-md-mn-mo-candidate-seeding-create-elections-races-then-ca/162-01-PLAN.md`, `162-mo-correspondence-audit.md` (via 162-01-SUMMARY.md), `162-verify.sql` — the plan/artifact/gate templates to clone

### Secondary (MEDIUM-HIGH confidence — live WebSearch, 2026-07 dated sources)
- [Alabama Reflector — Supreme Court allows Alabama to use 2023 congressional map (2026-06-02)](https://alabamareflector.com/2026/06/02/supreme-court-allows-alabama-to-use-2023-congressional-map-in-august-special-primary/)
- [WSFA — Supreme Court rules Alabama can use 2023 congressional map for 2026 election cycle (2026-06-03)](https://www.wsfa.com/2026/06/03/supreme-court-rules-alabama-can-use-2023-congressional-map-2026-election-cycle/)
- [Alabama Reflector — 21 candidates qualify for August Alabama congressional primaries (2026-05-22)](https://alabamareflector.com/2026/05/22/as-litigation-continues-21-candidates-qualify-for-august-alabama-congressional-primaries/)
- [Governor Ivey newsroom — special election announcement](https://governor.alabama.gov/newsroom/2026/05/governor-ivey-celebrates-major-court-victory-in-states-redistricting-battle-calls-special-election-for-alabama-drawn-congressional-map/)
- [Wikipedia — Louisiana v. Callais](https://en.wikipedia.org/wiki/Louisiana_v._Callais)
- [Louisiana Illuminator — Supreme Court strikes down Louisiana congressional maps (2026-04-29)](https://lailluminator.com/2026/04/29/supreme-court-callais/)
- [NOLA.com — Gov. Jeff Landry signs Louisiana's new congressional map (2026-05-29)](https://www.nola.com/news/politics/legislature/jeff-landry-signs-louisiana-redistricting-bill-congress/article_770ef156-f8b0-442d-9c22-d555b2ff1466.html)
- [Louisiana Illuminator — Louisiana Senate committee drops one of two majority-Black districts (2026-05-13)](https://lailluminator.com/2026/05/13/louisiana-senate-committee-drops-one-of-two-majority-black-districts-in-advancing-map/)
- [KSLA — Federal court sets June hearing on Louisiana's new congressional map (2026-06-02)](https://www.ksla.com/2026/06/02/federal-court-sets-june-hearing-louisianas-new-congressional-map/)
- [The Advocate — Louisiana likely to use new congressional map for 2026 midterms despite looming court challenge](https://www.theadvocate.com/baton_rouge/news/politics/louisiana-callais-congressional-map-2026-midterm-elections/article_5000e785-29f5-57c7-9f2b-67495938d488.html)

### Tertiary (LOW confidence — flagged for the phase's own audit to firm up)
- Exact per-parish/county reassignment for LA-1/4/5/6 (which specific parishes move where) — not found at source-URL granularity this session; the 163-01 LA audit task must gather this directly, same as 161-01/162-01 did for TN/MO.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|----------------|
| A1 | AL-1/2/6/7 will score SEVERE and AL-3/4/5 NOT-SEVERE under the formal correspondence-audit rubric | Critical Question 1 | If wrong, the wrong AL districts get withheld from `/elections`, either hiding a stable district unnecessarily or surfacing a wrong-map district to voters |
| A2 | LA-1/4/5/6 will score SEVERE and LA-2/3 NOT-SEVERE | Critical Question 1 | Same risk as A1, for LA; this is the WEAKER of the two hypotheses (no per-parish source found) |
| A3 | LA's jungle-primary should be modeled as a single `primary_party=NULL` race per district (cloning the CA convention) rather than any other schema shape | Critical Question 2 | If wrong, `/elections` could show LA candidates with an incorrect party-primary framing, or the unique-index/query patterns built for CA might not generalize cleanly to LA's higher candidate-per-race counts (LA-5 has 13) |
| A4 | 0 incumbent stance top-up is needed this phase (all 36 incumbents are `partial` tier, none `zero`) | Critical Question 3 | If wrong (e.g., if the diagnostic's tier classification is stale), some incumbents could be under-covered on `/elections` compass comparisons |
| A5 | Migration number 1220 is free | Migration Numbering | Low risk — explicitly flagged to re-verify at plan-authoring time since another session may have landed work since 2026-07-05 |

## Open Questions

1. **Exact LA per-parish reassignment for the correspondence audit**
   - What we know: CD-6 dissolves; the state broadly "returns to ~2022 map" (5R+1D); CD-2 (New Orleans) and likely CD-3 (Acadiana) are stable anchors.
   - What's unclear: Which specific parishes move from the dissolved CD-6 into CD-1 vs CD-4 vs CD-5, and by how much (the >25%-moved threshold needs a number, not just a qualitative "some territory moved").
   - Recommendation: The 163-01 audit task should fetch Louisiana's official 2026 redistricting site (`redist.legis.la.gov/2026_Files/2026CONGRESSACT2`) and/or Dave's Redistricting App-sourced Wikipedia tables (per the 161-TN precedent) for exact parish-level data before scoring.

2. **Will the AL/LA litigation status change before Phase 163 executes?**
   - What we know: Both maps currently stand with no live injunction as of 2026-07-05 (AL: SCOTUS stay in place; LA: challenge hearing cancelled).
   - What's unclear: Both are genuinely live, contested cases (AL's underlying discrimination finding was never overturned, only stayed for this cycle; LA's plaintiffs explicitly reserved the right to seek a remedy). A stay or emergency order could theoretically issue before Nov-3.
   - Recommendation: Re-verify both maps' status at 163-01 audit execution time (same 7-day freshness discipline as 161's TN audit), and again immediately before AL/LA seeding (163-04/163-06) if more than a few days elapse.

## Environment Availability

Skipped — this phase has no external tool/service dependencies beyond what 161/162 already proved available (`psql`, `psycopg2`, `node --import tsx`, Supabase prod access). No new environment probes needed.

## Validation Architecture

Skipped per project convention — `.planning/config.json` `workflow.nyquist_validation` is not applicable to this pure-data seeding milestone (161/162 did not include this section either; the phase's own `163-verify.sql` + `163-coordinate-smoke.ts` read-only gate IS the validation architecture, per the established pattern).

## Security Domain

Skipped — pure-data seeding phase, no auth/session/access-control/input-validation/cryptography surface changes (identical posture to 161/162, which also omitted this section).

## Project Constraints (from CLAUDE.md / empowered-vote-primer.md)

Not re-derived here — fully inherited from 161/162's research and `.planning/STATE.md`'s "v2.22 Execution Methodology": `pool.query()` for all essentials/inform reads+writes (never PostgREST); atomic multi-table writes via SECURITY DEFINER RPCs (N/A this phase — pure migration SQL, no RPC needed); PostGIS calls (if any, in the verify gate's coordinate-smoke) use `public.ST_*` never `extensions.ST_*`; Render-only infra, no code changes this phase; migrations idempotent with NOT EXISTS guards.

## Metadata

**Confidence breakdown:**
- Standard stack / pipeline mechanics: HIGH — proven twice (161, 162), zero new tooling
- WI/CO/SC field resolution: HIGH — decided/stable, no redistricting flag, live-verified against prod
- AL redistricting classification (which districts are severe): MEDIUM-HIGH — strong live-WebSearch corroboration + a clean 1:1 correlation with Phase 160's late-primary split, but not yet run through the formal audit rubric
- LA redistricting classification: MEDIUM — map status and CD-6 dissolution are HIGH confidence; which specific neighboring districts absorb the territory is LOW-MEDIUM (audit task must gather parish-level detail)
- LA jungle-primary modeling: HIGH — direct schema/pattern reuse of an already-proven CA convention

**Research date:** 2026-07-05
**Valid until:** 7 days for the AL/LA litigation-status claims (both are live contested cases; re-verify immediately before seeding those two states — same freshness window 161/162 used for TN/MO); 30 days for everything else (WI/CO/SC field resolution, pipeline mechanics, schema facts).
