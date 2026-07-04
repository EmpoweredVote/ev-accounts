# Phase 159: MI + VA Primary-Field Coverage (seed now) + Post-Primary Cull — Research

**Researched:** 2026-07-01
**Domain:** Election-data seeding (pure-data; no backend code) — MI + VA 2026 US House candidate field, provisional-then-cull pattern (FL Phase 151→153)
**Confidence:** HIGH on pipeline/scheme/gate; MEDIUM on the qualified candidate field (party-primary rosters confirmed from the official MI Bureau of Elections report + politics1/VPAP/Wikipedia cross-check; the independent/third-party general-ballot slice is NOT yet final — see the timing caveat below)

## Summary

This phase applies the fully-proven FL provisional-field pattern (Phase 151 seed → Phase 153 cull) to Michigan (13 districts, election + races must be authored) and Virginia (11 districts, election + races already scaffolded — DB-confirmed). The pipeline, external_id scheme, stance methodology, headshot pipeline, and verification-gate shape are all directly inherited from Phases 151/155/156/157/158 — this is a mechanical repeat, not new architecture. The single novel research deliverable is **the ballot-qualified Aug-4 primary candidate field**, captured below per district with per-candidate source provenance.

The defining timing constraint that separates 159 from the six decided Wave-2 states: **both MI and VA hold their congressional primaries on Aug 4, 2026** (VA moved from June to Aug this cycle — verified). The operator's reframe (locked in CONTEXT) is to seed the **full pre-primary qualified field NOW** (before Aug 4) so primary voters see their options, then run a **date-gated cull ≥ 2026-08-05** to prune losers and confirm nominees. Seeding is un-gated; only the cull (159-C) is date-gated.

**Two timing caveats the planner MUST internalize (these are new, not in FL-151):**
1. **VA independent/third-party general-ballot filing deadline = Aug 4, 2026** (same day as the primary). So the *party-primary* fields below are final and seedable now, but the *independent/third-party general* slice is still open — some independents listed below (from politics1/VPAP) are declared-but-not-yet-certified and more may file up to Aug 4. `[VERIFIED: elections.virginia.gov via WebSearch]`
2. **MI minor-party (Green/Libertarian/US Taxpayers) nominees are chosen by party convention with a July 16, 2026 filing deadline** — also after the seed window. `[CITED: thegreenpapers.com / MI BOE via WebSearch]`

**Consequence:** the "full qualified field" that is truly *final* right now = the **major-party (D/R) primary rosters** (authoritative: MI BOE public report + VA Dept. of Elections primary candidate spreadsheets). The independent/minor-party slice should be seeded as-declared with a documented "field-open-until-{date}" note, then reconciled in 159-C alongside the primary-loser cull. This mirrors FL-151's "provisional" marking but with an added open-filing dimension.

**Primary recommendation:** Author MI election + 13 races (VA's 11 already exist — reuse), seed every declared major-party primary candidate + every declared independent/third-party candidate as active `race_candidates`, reuse all 24 incumbent `politician_id`s (never duplicate), give new challengers new records + headshots + federal-24 chairs-not-polarity stances (0-unsourced floor, honest-skip thin), then in date-gated 159-C prune non-advancing candidates via the two-path convention and confirm nominees + reconcile any independents that filed/failed to file by Aug 4.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Strategy:** Seed full pre-primary qualified field (all parties) NOW + cull losers ≥ Aug-5. Applies FL Phase 151→153 pattern to MI+VA.
- **Coverage depth = FULL:** every ballot-qualified candidate gets record + headshot + **full federal-24 sourced stances** (NOT stances-light). Operator explicitly accepts stance work on primary losers is discarded at the Aug-5 cull.
- **Data modeling (follow FL precedent, do NOT invent):** qualified field attaches to the **Nov-3 general race rows** as a provisional field (`election_date='2026-11-03'`), NOT separate primary-election rows. MI needs `essentials.elections` ("MI 2026 Statewide General") + 13 `essentials.races` authored first. **VA's election + 11 races already exist** (DB-confirmed) — wire candidates onto existing scaffolding, do NOT duplicate.
- **race_candidates shape:** non-null `politician_id`, `candidate_status='active'`, incumbent `is_incumbent=true`; NEVER party on the candidate card (party lives on `races.primary_party`).
- **Records & reuse:** All 13 MI + 11 VA incumbents already exist with `politician_id` + partial stances — REUSE, never duplicate. **VA-11 James Walkinshaw already exists** (external_id -5102011, 7 stances) — the stale "Walkinshaw needs a new record" roadmap note is OUTDATED; reuse. New records only for genuinely-new challengers.
- **external_id scheme for new challengers:** `-(state_fips*10000 + cd*100 + seq)`; MI fips=26, VA fips=51. Verify 0 collisions per state before authoring.
- **Stances:** Federal 24-topic set (`_TOPIC_SCALE_FULL.txt`), `politician-stance-researcher` at **3-concurrency max**, chairs-not-polarity, embed 1–5 stance texts per topic in every agent prompt. **0-unsourced is the non-negotiable gate floor.** Honest-skip thin topics; whole-record skip allowed + gate-pinned. Mandatory primary-source verification pass before every push. Incumbents partially stanced — top-up only gaps (several VA incumbents thin: Vindman 1, Subramanyam 1, McGuire 2).
- **Cull sub-phase (159-C):** date-gated ≥ 2026-08-05. This is the ONLY date-gated part; seeding is un-gated (do now). Prune non-advancing candidates to inactive `candidate_status`; confirm advancing nominee(s) from official MI SoS / VA Dept. of Elections results; verify two-path prune (mirror FL Phase 153).

### Claude's Discretion
- Exact wave/batch split; whether stance work is one plan or several (≤3 concurrent researchers).
- Reconciliation mechanics of the declared field against MI BOE / VA Dept. of Elections official lists at execution time.
- Provisional-marking column choice against live `races` schema (D-04 in FL-151).
- Election/race authoring as migration vs script — follow established conventions.
- Reuse 155/156/157 assets: `_push_uuid.ts`, `_push_relaxed.ts`, `_merge.ts`, headshot python pipeline, `15N-verify.sql` + `15N-coordinate-smoke.ts` templates.

### Deferred Ideas (OUT OF SCOPE)
- **PA independents** (Aug-3 filing) — separate post-Aug-10 date-gated re-check (Phase 155 carry-forward).
- **FL post-primary cull** — Phase 153, gated ≥ Aug-18.
- **Challenger finance** (`finance_summary`) — v2.22+.
- **Remaining ~178 districts** — future waves.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| USHC2-02 | Every candidate exactly one `essentials.politicians` record; incumbents reuse; collision-free negative external_id verified per state | Candidate field + reuse map below; external_id scheme collision-verified against live DB (0 collisions in both new bands) |
| USHC2-03 | Every race surfaces on `/elections` via `races`+`race_candidates`; MI election+races authored first (VA already exists); non-null pid, `candidate_status='active'`, never `office_id IS NULL` | MI needs 1 election + 13 races; VA reuses 11 existing races (race_ids in field table); race-wiring shape inherited from 157-03 |
| USHC2-04 | Every newly-seeded candidate has a headshot (600×750 + `politician_images` + `photo_origin_url`; free-license, wrong-person-guarded, documented honest-skips) | Headshot pipeline = `seed-nj-house-headshots.py` clone with MI/VA band; expect heavy honest-skip rate (155: 8/37, 156: 5/62, 157: 1/15) |
| USHC2-05 | Every candidate lacking them gets federal-24 chairs-not-polarity stances; 0 unsourced; honest-skip thin; primary-source-verified before push; already-stanced incumbents skipped via diagnostic | Stance pipeline + topic-embed rule; thin VA incumbents (Vindman/Subramanyam/McGuire) are top-up candidates per CONTEXT |
| USHC2-06 | Consolidated read-only gate: MI + VA address → House race with full field; 0 unsourced; 0 duplicate-incumbent; all 24 districts ≥1 active row | Gate modeled on 158-verify.sql (dual-state) + 157-verify.sql (per-state pins); mirror 158-coordinate-smoke.ts for MI+VA |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Candidate field surfacing on /elections | Database (essentials.races + race_candidates) | — | Path B feed; PURE DATA, no backend code (STATE.md-confirmed) |
| Geography → district resolution | Database (PostGIS ST_Covers via office_id→districts.geo_id) | — | Geofences already present for MI + VA (v2.15/v2.10) |
| Stance data | Database (inform.politician_answers + politician_context) | — | Existing schema; research agents produce CSV → push scripts |
| Headshots | Supabase Storage + politician_images | — | Existing find-headshots pipeline (python script per phase) |
| Post-primary cull | Database (candidate_status + is_active two-path) | — | Two-path prune convention (FL-153) — no schema change |

**No frontend or API code in this repo is touched.** The "race not covered" empty-state lives in the separate Essentials frontend repo; backend returns `{elections:[]}`.

---

## THE QUALIFIED PRIMARY CANDIDATE FIELD (the core deliverable)

**Inclusion bar:** every ballot-qualified Aug-4-2026 primary candidate (Democratic primary + Republican primary) plus every declared independent/third-party candidate for the Nov-3 general. Incumbents flagged for REUSE (existing `politician_id`); everyone else is a NEW record.

**Authoritative sources used:**
- **MI:** Official Michigan Bureau of Elections public candidate-listing report (`mi-boe.entellitrak.com` PRI 2026) `[VERIFIED: mi-boe.entellitrak.com]` — this is the equivalent of FL's `downloadcanlist.asp` and is the authoritative D/R primary roster. Cross-checked with Wikipedia raw-wikitext + Michigan Advance.
- **VA:** politics1.com VA page (full field incl. declared independents/third-party) `[CITED: politics1.com/va.htm]` + Wikipedia raw-wikitext + VPAP + vademocrats.org nominees, cross-checked. **Authoritative reconciliation source at execution = VA Dept. of Elections downloadable candidate spreadsheets** (`elections.virginia.gov/candidatepac-info/candidate-bulletins/`, "2026 August Democratic Primary: Federal Offices Candidates List" + "2026 August Republican Primary: All Offices Candidates List", revised 6/3/26) `[CITED: elections.virginia.gov]`.

> **Provenance rule:** every candidate name below is `[VERIFIED]` against the official MI BOE report (MI) or `[CITED]` from politics1/VPAP/Wikipedia (VA). The planner MUST re-reconcile the VA independent/third-party slice against the VA Dept. of Elections spreadsheet at plan/execution time (D-01 discretion) — that slice is still filing until Aug 4.

### Michigan (13 districts) — geo_id 2601..2613, FIPS 26

**Source:** Official MI Bureau of Elections PRI-2026 report `[VERIFIED: mi-boe.entellitrak.com]`. Incumbent reuse from CONTEXT map.

| Dist | geo_id | Incumbent (REUSE pid) | Dem primary candidates | Rep primary candidates | Other/declared | New records |
|------|--------|----------------------|------------------------|------------------------|----------------|-------------|
| MI-1 | 2601 | Jack Bergman (R) -26001 | Callie Barr; Kyle Blomquist; Wayne Stiles | **Bergman** (inc); Matthew DenOtter; Justin Michal | Independents: Zebulon Featherly, Thomas Latza (declared; MI indep deadline 7/16) | 5+ (3 D + 2 R + indeps) |
| MI-2 | 2602 | John R. Moolenaar (R) -26002 | Ben Ambrose; Jamie Hill; Clyde Welford | **Moolenaar** (inc) | — | 3 |
| MI-3 | 2603 | Hillary J. Scholten (D) -26003 | **Scholten** (inc) | Ryan Cushman; Terri DeBoer | — | 2 |
| MI-4 | 2604 | Bill Huizenga (R) -26004 | Diop Harris II; Sean McCann | **Huizenga** (inc); Philip Tanis | — | 3 |
| MI-5 | 2605 | Tim Walberg (R) -26005 | Christian Vukasovich | **Walberg** (inc) | Green: James Bronke (convention) | 1 (+1 Green) |
| MI-6 | 2606 | Debbie Dingell (D) -26006 | **Dingell** (inc) | Heather Smiley | Green: Clyde Shabazz (convention) | 1 (+1 Green) |
| MI-7 | 2607 | Tom Barrett (R) -26007 | Bridget Brink; William Lawrence; Matt Maasdam; Muhammad Salman Rais | **Barrett** (inc) | Independent: Alexandra Prieditis (declared) | 4 (+indep) |
| MI-8 | 2608 | Kristen McDonald Rivet (D) -26008 | **McDonald Rivet** (inc) | Amir Hassan; Al Lemmo; Thomas J. Smith | — | 3 |
| MI-9 | 2609 | Lisa C. McClain (R) -26009 | Ray Pooley | **McClain** (inc) | Independents: Jasen Cartwright, Fernando Valdez (declared) | 1 (+indeps) |
| MI-10 | 2610 | John James (R) -26010 — **NOT running (Gov run) → OPEN SEAT** | Eric Chung; Tim Greimel; Christina Bertrand Hines | Michael Bouchard; Steffan Demetropoulos; Justin Kirk; Robert Lulgjuraj | — | 7 (James gets NO active row) |
| MI-11 | 2611 | Haley M. Stevens (D) -26011 — **NOT running (US Senate) → OPEN SEAT** | Stu Baker; Aisha Farooqi; Jeremy Moss; Michelle Mary Murphy; John Paul Torres; Don Ufford | Ethan Baker; Tony J. Prieto | — | 8 (Stevens gets NO active row) |
| MI-12 | 2612 | Rashida Tlaib (D) -26012 | **Tlaib** (inc); Allen Downer; Shanelle Jackson; Byron H. Nolen | James D. Hooper | — | 4 (Downer per news; verify on BOE list) |
| MI-13 | 2613 | Shri Thanedar (D) -26013 | **Thanedar** (inc); John Goci; Donavan McKinney; Mary Waters | Martell D. Bivings; Raphiel King; T.P. Nykoriak | Independent: Maurice Morton (declared) | 6 (+indep) |

**MI notes:**
- **MI-10 (John James) and MI-11 (Haley Stevens) are OPEN SEATS** — both incumbents vacate (James → Governor, Stevens → US Senate). Their existing records (`-26010`, `-26011`) get **NO active `race_candidates` row** in their old seat (the FL retired-incumbent convention). This is the MI analog of NJ-12/PA-3.
- **MI-12** has **no Republican general candidate** — Hooper is the only R, uncontested R primary; the R primary winner faces Tlaib. Seed Hooper as active.
- **MI-2/3/5/6/8/9** several incumbents run "presumptive" uncontested in their own primary — still seed the incumbent as active + any opposing-primary challengers.
- **MI-12 Allen Downer:** appears in a news source but NOT in the MI BOE report snapshot fetched (which listed Jackson/Nolen/Tlaib). Planner must reconcile against the live BOE list — the BOE report is authoritative over news.
- **Green candidates (MI-5 Bronke, MI-6 Shabazz)** are nominated by convention, not primary — declared but not final until the 7/16 convention/filing. Seed as declared; reconcile in 159-C.

**MI new-record count (excl. incumbents, excl. James/Stevens who vacate):** ~48 major-party challengers + ~8 declared independents/Green = **~56 new records** (upper bound; the independent/Green slice will firm up by 7/16). This is the authoritative sizing input; treat as provisional pending the BOE-list reconciliation.

### Virginia (11 districts) — geo_id 5101..5111, FIPS 51 (races already exist)

**Source:** politics1.com/va.htm `[CITED]` + Wikipedia + VPAP + vademocrats, cross-checked. Existing race_ids from `154-field-table.csv`. Incumbent reuse from CONTEXT map (all 11 exist incl. Walkinshaw -5102011).

| Dist | geo_id | existing race_id | Incumbent (REUSE pid) | Dem primary | Rep primary | Indep / 3rd-party (declared) | New records |
|------|--------|-----------------|----------------------|-------------|-------------|------------------------------|-------------|
| VA-1 | 5101 | 65dd3477-… | Rob Wittman (R) -5102001 | Elizabeth Beggs; Salaam Bhatti; Tim Cywinski; Jason Knapp; Ericka Kopp; Shannon Taylor; Mel Tull *(vademocrats also lists Lucchetti/Shea/Sublette — RECONCILE)* | **Wittman** (inc) | — | 7–10 (Dem field unsettled) |
| VA-2 | 5102 | 73a46730-… | Jen Kiggans (R) -5102002 | Nila Devanath; Bill Fleming; Elaine Luria; Patrick Mosolf *(vademocrats adds Strickler/Stringfellow — RECONCILE)* | **Kiggans** (inc) | Indep: DeVinche Albritton, Makiba Gaines, Geral "Bishop" Staten; Write-in: Ashley Maria Euceda-Mendoza | 4–8 (+indeps) |
| VA-3 | 5103 | ae5bfa0e-… | Bobby Scott (D) -5102003 | **Scott** (inc) | Edwin Rivera | Libertarian: Hailey Dollar; Indep: James "Zeb" Taylor, Dawn Vasquez, Steve Woll | 1 R + 4 others |
| VA-4 | 5104 | a48dfb93-… | Jennifer McClellan (D) -5102004 | **McClellan** (inc) | *(none filed by deadline)* | Indep: Jason Brown II, Andre Kersey | 2 indeps |
| VA-5 | 5105 | 6a1bf3a1-… | John McGuire (R) -5102005 | Suzanne Krzyzanowski; Tom Perriello; Rob Tracinski | **McGuire** (inc); Melanie Lucero | Indep: Cooke Costa Harvey, Chris Register | 3 D + 1 R + 2 indeps |
| VA-6 | 5106 | 807d0f7c-… | Ben Cline (R) -5102006 | Beth Macy *(vademocrats lists Barlow/Gooditis/Mitchell/Murray too — RECONCILE)* | **Cline** (inc) | — | 1–5 (Dem field unsettled) |
| VA-7 | 5107 | b9e08170-… | Eugene Vindman (D) -5102007 **(THIN — top-up)** | **Vindman** (inc) | Philip Harding; Doug Ollivant; Rick Smithers | Libertarian: Taner Lopez; Indep: Craig Ennis | 3 R + 2 others |
| VA-8 | 5108 | df4895e9-… | Don Beyer (D) -5102008 | **Beyer** (inc); Lorena Bruner; Michael Duffin; Adam Dunigan; Mo Seifeldein | Tony Sabio | Libertarian: Shelly Arnoldi | 4 D + 1 R + 1 Lib |
| VA-9 | 5109 | da51cdee-… | Morgan Griffith (R) -5102009 **(THIN — top-up)** | Douglas Crockett; Adam Murphy; Joy Powers | **Griffith** (inc) | Indep: Michael Jackson | 3 D + 1 indep |
| VA-10 | 5110 | 3fccc125-… | Suhas Subramanyam (D) -5102010 **(THIN — top-up)** | **Subramanyam** (inc) | Dave Beckwith; Julie Perry; Anthony Suttles; Sam Wong | Write-in: Steven Goforth, Omar Morsy | 4 R (+WI) |
| VA-11 | 5111 | bb9b6411-… | James Walkinshaw (D) -5102011 | **Walkinshaw** (inc); Bree Fram; Stella Pekarsky; Amy Roma | Arthur Purves *(Wikipedia adds Nathan Headrick/Michael Van Meter — RECONCILE)* | — | 3 D + 1–3 R |

**VA notes:**
- **VA-11 Walkinshaw REUSE** — CONTEXT is explicit: he already exists (`-5102011`, 7 stances). The stale roadmap note "Walkinshaw needs a new record" is OUTDATED. Do NOT create a duplicate. Success-criterion 2's "Walkinshaw gets a new record" phrasing in the ROADMAP is likewise superseded by the CONTEXT DB-confirmed fact — reuse the existing record. **Flag this contradiction to the planner explicitly.**
- **Thin incumbents to top-up (CONTEXT):** Vindman (VA-7, 1 stance), Subramanyam (VA-10, 1), McGuire (VA-5, 2). These are top-up stance targets — the ONLY incumbents that get stance work (all others are partial-and-left-as-is per the zero-only/top-up rule, EXCEPT that CONTEXT explicitly names these three as top-up candidates because they are near-zero).
- **VA independent/3rd-party filing deadline = Aug 4, 2026.** The independents/Libertarians listed above are *declared* per politics1/VPAP but the field is still open. Seed as-declared, mark provisional, reconcile in 159-C.
- **Dem primary fields disagree between sources** (VA-1, VA-2, VA-6 especially — Wikipedia/politics1/vademocrats each list different rosters, a symptom of the May-8 redistricting churn). **The VA Dept. of Elections spreadsheet is the tiebreaker** and MUST be pulled at execution time.
- **May 8, 2026 Supreme Court of Virginia decision** overturned the redistricting referendum → the 2021 Special Masters map remains in effect for the Nov general. Several candidates shifted districts after the ruling. Districts/geo_ids in the DB (5101..5111) are unchanged (2021 map), so the existing races are correct — but candidate-to-district assignment must be taken from the post-ruling official list, not pre-ruling coverage.

### Reuse map (all 24 incumbents — NEVER duplicate)

MI: -26001..-26013 (Bergman/Moolenaar/Scholten/Huizenga/Walberg/Dingell/Barrett/McDonald Rivet/McClain/**James†**/**Stevens†**/Tlaib/Thanedar). VA: -5102001..-5102011 (Wittman/Kiggans/Scott/McClellan/McGuire/Cline/Vindman/Beyer/Griffith/Subramanyam/Walkinshaw).

† **James (MI-10) and Stevens (MI-11) vacate — their records exist but get NO active row in their old seat.** All other 22 incumbents get an active `is_incumbent=true` row.

---

## Standard Stack

Pure-data phase — no libraries installed. The "stack" is the existing repo tooling (all present, all proven across 151/155/156/157):

| Tool | Purpose | Provenance |
|------|---------|------------|
| `pg` (raw driver, `src/lib/db.js` pool) | read-only diagnostics, verify gates | `[VERIFIED: repo]` project invariant (raw pg for transactions) |
| `psql` + `-v ON_ERROR_STOP=1 -f` | run migrations + write-free gates | `[VERIFIED: 157/158 SUMMARY]` |
| `node --import tsx` | ad-hoc DB scripts | `[VERIFIED: research-stances SKILL.md]` |
| `_merge.ts` / `_push_uuid.ts` / `_push_relaxed.ts` / `_push.ts` | stance CSV merge + push (UUID-keyed for new NULL-external_id records; relaxed parse for URL-boundary CSV repair) | `[VERIFIED: 157-05 SUMMARY, STATE.md]` |
| `seed-{state}-house-headshots.py` | headshot pipeline (600×750, Storage mirror, wrong-person guards) | `[VERIFIED: 157-04 SUMMARY — clone of 156 pipeline]` |
| `politician-stance-researcher` agent (≤3 concurrent) | federal-24 chairs-not-polarity stance research | `[VERIFIED: research-stances SKILL.md + MEMORY 3-concurrency rule]` |

**No packages to install → no Package Legitimacy Audit required for this phase.**

## Architecture Patterns

### Data flow (Path B elections feed)

```
User address (lat/lon)
      │
      ▼
getElectionsByCoordinate (electionService.ts)  ── PostGIS ST_Covers ──▶ districts.geo_id (2601..2613 / 5101..5111)
      │                                                                        │
      ▼                                                                        ▼
essentials.races (office_id → district office)  ◀──────────────── essentials.offices (US Rep office per district)
      │
      ▼
essentials.race_candidates (politician_id, candidate_status='active', is_incumbent)
      │
      ├──▶ essentials.politicians (record; external_id)
      ├──▶ essentials.politician_images (headshot)
      └──▶ inform.politician_answers + politician_context (stances) — via politician_id
```

Party is NEVER on the `race_candidates` card. It reads from `races.primary_party` only (antipartisan structural invariant — gate asserts no `party`/`party_affiliation` column exists).

### Pattern 1: Author election + races first (MI only; VA already done)

**What:** Create one `essentials.elections` row ("MI 2026 Statewide General", `election_date='2026-11-03'`), then one `essentials.races` per district linked to the existing US Rep office (`office_id` NEVER NULL).
**When:** MI (0 elections, 0 races currently). VA already has 1 election + 11 races — skip for VA, resolve election id by exact name.
**Example (from 157-01):**
```sql
-- Source: backend/migrations/1140_seed_nj_2026_house_elections_races.sql (157-01 SUMMARY)
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'MI 2026 Statewide General', '2026-11-03', 'general', 'state', 'MI'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'MI 2026 Statewide General');
-- then one races row per district on the existing NATIONAL_LOWER US House office (geo_id 2601..2613)
```

### Pattern 2: Reconcile + insert new records + wire race_candidates

**What:** Live-DB dedup by name + external_id, reuse incumbents, insert new challengers in the `-(fips*10000+cd*100+seq)` band, wire all as active `race_candidates`.
**Example shape (from 157-03):** migration inserts N new politicians + M race_candidates (incumbents reused active + new active); vacating incumbent gets NO active row. Idempotent via `WHERE NOT EXISTS`.

### Pattern 3: Two-path post-primary cull (159-C, date-gated ≥ Aug-5)

**What:** For each primary loser: set `essentials.politicians.is_active=false` (reps feed) AND `essentials.race_candidates.candidate_status='withdrawn'` (elections feed). **NEVER hard-DELETE** (preserves record/stances/headshot). Confirm advancing nominee(s) from official results. Re-research advancing thin-stance winners against primary sources.
**Source:** STATE.md USHC-07 / FL Phase 153 convention `[VERIFIED: STATE.md line 88]`.

### Anti-Patterns to Avoid
- **Duplicate incumbent record** (the v2.4 two-Andy-Barrs failure) — always reuse existing `politician_id`. Dedup by exact external_id or accent-normalized last name within the district.
- **`office_id IS NULL` on a House race** — statewide convention, matches every resident of the state. Always link the district office.
- **Party on the candidate card** — party lives on `races.primary_party`.
- **Creating a new record for Walkinshaw (VA-11)** — he already exists; the roadmap note is stale.
- **Giving James (MI-10) or Stevens (MI-11) an active row** — they vacate; no active row in the old seat.
- **Inferring stance from party** — chairs-not-polarity; honest-skip if no evidence.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Headshot fetch/resize/mirror | custom image pipeline | `seed-nj-house-headshots.py` clone (change band to MI/VA) | wrong-person guards, historical-year reject, idempotent WHERE NOT EXISTS all already solved |
| Stance CSV → DB push | ad-hoc INSERT loop | `_push_uuid.ts` / `_push_relaxed.ts` | 0-unsourced enforcement, source_url_1 misalignment guard, surname-leak check baked in |
| Verify gate | fresh SQL each time | clone `158-verify.sql` (dual-state) + `157-verify.sql` (per-state pins) | asymmetry-safe unsourced existence check, temp-table scope, RAISE EXCEPTION labels all proven |
| Coordinate surfacing test | manual queries | `158-coordinate-smoke.ts` clone | Pitfall-5 challenger-present guard already implemented |

**Key insight:** every sub-problem in this phase was solved in 151/155/156/157/158. The ONLY genuinely new work is (a) the candidate field research (done above), (b) the MI election/races authoring (VA already done), and (c) the cull sub-phase's date-gate + independent-field reconciliation.

## Runtime State Inventory

> This is a data-seeding phase (writes to prod DB), not a rename/refactor. A full Runtime State Inventory is not applicable. The relevant runtime-state consideration is the DEPLOY question:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | New `essentials.elections`/`races`/`race_candidates`/`politicians`/`politician_answers`/`politician_context`/`politician_images` rows | Migrations + push scripts (this phase's work) |
| Live service config | None — no external service holds MI/VA candidate state | None |
| Deploy trigger | **Data-only changes need NO deploy** (MEMORY: reference_render_deploy — only code changes deploy; STATE_EXEC/elections feed already wired). MI/VA feed surfacing uses existing `electionService.ts`. | No Render deploy needed |
| Build artifacts | None | None |
| Secrets/env vars | `DATABASE_URL` in `backend/.env` (gitignored) — read-only use | None |

**Verified:** MI + VA NATIONAL_LOWER district geofences + US Rep offices are present (v2.10 VA, v2.15 MI). VA election + 11 races present. MI has 0 elections/races (must author).

## Common Pitfalls

### Pitfall 1: The independent/third-party slice is NOT final at seed time
**What goes wrong:** Seeding "the full qualified field" now, then treating it as complete — but VA indep deadline is Aug 4 and MI minor-party conventions/filing run to July 16. New independents may appear; declared ones may fail to certify.
**How to avoid:** Seed declared indeps/minor-party as active + mark provisional; the 159-C cull MUST reconcile the independent slice (add certified late-filers, prune non-filers) in addition to pruning primary losers. Document the field-open dates in the seed migration comment.
**Warning sign:** A district's Nov field differs from the seed field for a reason OTHER than a primary result.

### Pitfall 2: Source disagreement on VA Dem primary rosters (redistricting churn)
**What goes wrong:** Wikipedia, politics1, and vademocrats list different Dem candidates for VA-1/2/6 (post-May-8-ruling shuffle). Seeding from the wrong source creates phantom or missing candidates.
**How to avoid:** The **VA Dept. of Elections official primary spreadsheet** (revised 6/3/26) is the tiebreaker — pull it at execution. Treat the field table above as the reconciliation *starting point*, not the final roster.
**Warning sign:** A candidate appears in one source only.

### Pitfall 3: Vacating incumbents (MI-10 James, MI-11 Stevens) get a phantom active row
**What goes wrong:** Auto-wiring all incumbents active would put James/Stevens in races they've left → wrong field + a `is_incumbent=true` row for a non-candidate.
**How to avoid:** Explicitly exclude -26010 and -26011 from active wiring (they keep their record, no active row). Gate must assert their absence from the active MI-10/MI-11 field (mirror NJ-12 Watson Coleman pin in 157/158 gate).

### Pitfall 4: Duplicate incumbent (v2.4 two-Andy-Barrs)
**What goes wrong:** A new-record INSERT for a sitting rep who already has a record.
**How to avoid:** Mandatory live-DB dedup before insert (reuse existing pid); gate asserts 0 duplicate full_name per state + 0 politician_id active in 2+ races.

### Pitfall 5: Two-path prune incomplete at cull
**What goes wrong:** Setting only `candidate_status='withdrawn'` (elections feed) but leaving `is_active=true` (reps feed) — loser still surfaces in one feed.
**How to avoid:** Both paths, every loser. Never hard-DELETE.

### Pitfall 6: Fetch-walls waste research budget
**What goes wrong:** Ballotpedia (Cloudflare 403/blank via WebFetch), VPAP (403), Wikipedia (TOC-only via WebFetch), long candidate pages.
**How to avoid (proven paths):** MI official BOE report renders via WebFetch (used for the table above). VA politics1 renders. For stance research, `politician-stance-researcher` uses WebFetch-only on campaign sites/Ballotpedia patterns; Playwright "Key votes" bypass is the orchestrator's tool if WebFetch 403s (project-150 method). Wikipedia raw wikitext via `?action=raw` partially works but truncates long pages — prefer the official candidate lists.

## Code Examples

### Verify external_id band is collision-free (run before authoring)
```bash
# Source: adapted from STATE.md diagnostic query 2; run 2026-07-01, both bands EMPTY (0 rows)
psql "$DATABASE_URL" -tA -c "SELECT count(*) FROM essentials.politicians
  WHERE external_id BETWEEN -269999 AND -260101   -- MI challenger band (cd*100+seq, cd>=1)
     OR external_id BETWEEN -519999 AND -510101;"  -- VA challenger band
# → 0. MI incumbents -26001..-26013 are LESS negative than -260101 (outside band).
#   VA statewide -510001/2/3 (Spanberger/Hashmi/Jones) are cd=00 → less negative than -510101 (outside band).
#   VA incumbents -5102001..-5102011 are FAR more negative (~5.1M) → outside band.
```

### Run a per-phase gate (mid-wave, read-only)
```bash
# Source: 157-02 SUMMARY invocation
cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/159-verify.sql
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| "Wait until Aug-4, seed decided nominees" (original Phase 159 plan) | Seed full pre-primary qualified field NOW + cull ≥ Aug-5 (FL-151→153 pattern) | 2026-07-01 operator reframe | This phase seeds provisionally, un-gated; only 159-C is date-gated |
| VA June primary | VA Aug-4 primary | 2026 cycle | VA folded into 159 with MI (both Aug-4) |
| VA pre-ruling redistricting map | 2021 Special Masters map (post May-8 ruling) | 2026-05-08 SCoVA | Candidate-to-district assignments must come from post-ruling official list |

**Superseded roadmap notes (flag to planner):**
- ROADMAP success-criterion 2 says "VA-11's special-seated member Walkinshaw gets a new record" — **WRONG per CONTEXT** (he already exists, reuse -5102011).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | MI-12 Allen Downer is a qualified Dem primary candidate (news-sourced; not in the BOE report snapshot) | MI field table | Low — planner reconciles against live BOE list; extra/missing 1 record |
| A2 | The declared VA independents/Libertarians (politics1) are/will be ballot-qualified | VA field table | Medium — Aug-4 filing deadline open; some may not certify. Reconciled in 159-C |
| A3 | MI Green candidates (Bronke, Shabazz) will be convention-nominated by 7/16 | MI field table | Low-Medium — declared; reconcile in 159-C |
| A4 | VA Dem primary rosters for VA-1/2/6 (source disagreement) | VA field table | Medium — VA DoE spreadsheet is the execution-time tiebreaker |
| A5 | New-record counts (~56 MI, ~40 VA) are upper-bound estimates | field tables | Low — sizing input only; exact count set by execution-time reconciliation |
| A6 | No collision in MI/VA challenger external_id bands | external_id | Low — DB-verified 0 rows 2026-07-01; planner re-verifies pre-insert |

## Open Questions

1. **Independent/third-party field finality**
   - Known: VA indep deadline Aug 4; MI minor-party filing July 16.
   - Unclear: exactly which declared indeps certify.
   - Recommendation: seed declared-now as provisional; 159-C reconciles the indep slice against official lists alongside the primary-loser cull. Consider whether 159-C should run in TWO date-gated passes (≥ July 17 for MI minor-party firm-up; ≥ Aug 5 for the primary cull) — planner's call.

2. **Provisional-marking mechanism**
   - Known: FL-151 marked races provisional (D-04); exact column resolved against live `races` schema.
   - Recommendation: reuse the FL-151 provisional-marking convention (same column/sentinel).

3. **Cull scope for discarded losers' stance rows**
   - Known: FL-153 convention allows retain-or-prune.
   - Recommendation: retain (historical) per two-path (`is_active=false` + `candidate_status='withdrawn'`), never hard-DELETE.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Prod Postgres (`DATABASE_URL`) | all seeding/gates | ✓ | Supabase prod ref kxsdzaojfaibhuzmclfq | — |
| `psql` | migrations + gates | assumed ✓ (used 157/158) | — | node pg script |
| `node --import tsx` | push scripts | assumed ✓ | — | — |
| Python 3 + Pillow | headshot pipeline | assumed ✓ (used 155/156/157) | — | honest-skip |
| MI BOE report / VA DoE spreadsheet | field reconciliation | ✓ (fetched this session) | — | Wikipedia/politics1 |

**No blocking missing dependencies.** All tooling proven in prior phases this milestone.

## Validation Architecture

> nyquist_validation not explicitly false → included. This is data seeding; "tests" are the write-free SQL gate + coordinate smoke.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | write-free psql assertion gate (`DO $$ … RAISE EXCEPTION`) + tsx coordinate smoke |
| Config file | none — script-based (`backend/scripts/159-verify.sql`, `159-coordinate-smoke.ts`) |
| Quick run command | `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/159-verify.sql` |
| Full suite command | above + `node --import tsx scripts/159-coordinate-smoke.ts` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| USHC2-03 | MI 13 + VA 11 races, all ≥1 active, 0 null pid | gate | `159-verify.sql` USHC2-03a/b | ❌ Wave 0 (author) |
| USHC2-02 | 0 dup full_name per state; incumbents reused; James/Stevens absent from active | gate | `159-verify.sql` USHC2-02a/c + MI-10/11 vacate pins | ❌ Wave 0 |
| USHC2-04 | new candidates have headshot or pinned skip | gate | `159-verify.sql` USHC2-04 | ❌ Wave 0 |
| USHC2-05 | 0 unsourced; ≥1 sourced OR pinned skip; thin VA incumbents topped-up | gate | `159-verify.sql` USHC2-05a/b | ❌ Wave 0 |
| USHC2-06 | MI+VA address → full field; 0 unsourced; 0 dup-incumbent; 24 districts ≥1 active | gate + smoke | `159-verify.sql` + `159-coordinate-smoke.ts` | ❌ Wave 0 |
| (cull) | losers withdrawn two-path; nominees confirmed | gate (159-C, date-gated) | `159-cull-verify.sql` | ❌ 159-C |

### Sampling Rate
- **Per plan:** run `159-verify.sql` after each seeding step (goes green incrementally, like 157).
- **Phase gate:** full `159-verify.sql` + `159-coordinate-smoke.ts` green (both MI + VA samples, Pitfall-5 challenger guard).
- **159-C (date-gated):** re-run gate after cull; assert nominees active + losers withdrawn.

### Wave 0 Gaps
- [ ] `backend/scripts/159-verify.sql` — dual-state MI+VA gate (clone 158-verify.sql structure + 157-verify.sql per-state pins; MI-10/MI-11 vacate pins mirroring NJ-12; James -26010 / Stevens -26011 absent-from-active assertions; VA-11 Walkinshaw REUSE assertion)
- [ ] `backend/scripts/159-coordinate-smoke.ts` — MI + VA in-district surfacing smoke (clone 158-coordinate-smoke.ts; ≥3 MI + ≥3 VA)
- [ ] `backend/migrations/{next}_seed_mi_2026_house_elections_races.sql` — MI election + 13 races
- [ ] `backend/migrations/{next}_seed_mi_2026_house_candidates.sql` + `{next}_seed_va_2026_house_candidates.sql`
- [ ] `backend/scripts/seed-mi-house-headshots.py` + `seed-va-house-headshots.py` (band-swapped 157 clones)
- [ ] `backend/scripts/159-cull-verify.sql` (159-C, date-gated) — two-path prune assertions

## Security Domain

> `security_enforcement` not set false in config for this repo's data phases; but this phase writes only public civic data (candidate names, public stances with public sources) via existing, RLS-governed schema and read-only gates. No new attack surface.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | candidate data hand-curated + gate-asserted (0 null pid, 0 dup, valid stance values 1–5); CSV parsed with RFC-4180 parser (never split-on-comma) per research-stances SKILL |
| V6 Cryptography | no | no secrets handled beyond read-only `DATABASE_URL` |
| others | no | no auth/session/access-control surface in a data-seed |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Wrong-person headshot | Spoofing (identity) | find-headshots wrong-person guards + historical-year reject (157 pipeline) |
| Party-inference stance (mis-repr.) | Tampering (integrity) | chairs-not-polarity, mandatory primary-source verification pass, 0-unsourced gate |
| Duplicate/phantom candidate | Tampering | live-DB dedup + gate (0 dup full_name, 0 dup-incumbent, vacate pins) |
| Surname leak in de-identified quote | Information disclosure | surname leak-check in push script (research-stances SKILL) |

## Sources

### Primary (HIGH confidence)
- **Michigan Bureau of Elections** official PRI-2026 public candidate report (`mi-boe.entellitrak.com`) — authoritative MI D/R primary roster, all 13 districts `[VERIFIED]`
- Live prod DB (ref kxsdzaojfaibhuzmclfq) — external_id collision check (both bands empty), incumbent pid/format confirmation, VA race scaffolding present
- `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-field-table.csv` — incumbent pids, VA race_ids, stance baselines
- `.planning/phases/151-*` (FL) + `157-*` (NJ) SUMMARY/CONTEXT — the seed→headshot→stance→gate pipeline + provisional-field + cull convention
- `backend/scripts/158-verify.sql` — dual-state gate template
- `.claude/skills/research-stances/SKILL.md` — stance pipeline + chairs-not-polarity + push conventions

### Secondary (MEDIUM confidence)
- politics1.com/va.htm — full VA field incl. declared independents/third-party `[CITED]`
- michiganadvance.com voter guide + Bridge Michigan / Arab American News — MI-10/11/12/13 detail cross-check
- vademocrats.org/2026-nominees + VPAP (403-walled via WebFetch, name-level via WebSearch) — VA Dem field cross-check
- elections.virginia.gov candidate-bulletins — VA DoE official spreadsheet (execution-time tiebreaker) `[CITED]`
- Wikipedia "2026 US House elections in Michigan/Virginia" (raw wikitext, partial — truncates long pages)

### Tertiary (LOW confidence — flagged for execution-time reconciliation)
- VA-1/2/6 Dem rosters (source disagreement — resolve via VA DoE spreadsheet)
- Declared VA independents / MI minor-party (filing deadlines still open)

## Metadata

**Confidence breakdown:**
- Pipeline / external_id scheme / gate shape: HIGH — DB-verified + directly inherited from 151/157/158
- MI major-party candidate field: HIGH — official MI BOE report
- VA major-party candidate field: MEDIUM — cross-source; VA DoE spreadsheet is execution tiebreaker
- Independent/third-party slice (both states): LOW-MEDIUM — filing deadlines open (VA Aug-4, MI Jul-16); reconcile in 159-C

**Research date:** 2026-07-01
**Valid until:** 2026-08-05 (candidate field firms up as primaries approach; MI minor-party firm ~Jul 16; VA indep firm ~Aug 4; re-pull official lists at execution)
