# Phase 151: FL Candidate Seeding (provisional qualified field) — Research

**Researched:** 2026-06-29
**Domain:** Single-state US House candidate seeding (FL, FIPS 12) onto `/elections`, applying the validated 149/150 pipeline. FL-specific deltas only — the general approach is locked, NOT re-researched.
**Confidence:** HIGH (all four open questions resolved against the live prod DB + live FL DoE endpoint; only assumptions explicitly flagged below).

## Summary

This research resolves the four FL-specific open questions the planner needs; it does **not** re-derive the 149/150 pipeline (locked in 151-CONTEXT.md and the 150 plan/gate/smoke, all read). The phase mirrors 150's create-races-first pattern for a single state, **plus** one new structural step (create the FL-20 office) and one accounting nuance (provisional, crowded field).

**Four resolutions (verified):**
1. **FL DoE `downloadcanlist.asp` is fully fetchable via plain `curl` POST (no JS/Cloudflare wall) — but returns ZERO 2026 federal/general candidate rows today.** The mechanism works (HTTP 200, `Content-Type: application/tab-separated-values`, correct 26-column header); the data is simply not present — the `2026 Election` (`elecID=20261103-GEN`) and `Federal Offices` (`elecID=FED`) extracts both return header-only (243 bytes). FL US House candidates currently file for the partisan primary / with the FEC and do not populate this extract pre-Aug-18. **Recommendation: `148-field-table.csv` (Wikipedia-sourced) IS the documented source-of-truth for this phase; the DoE endpoint cannot reconcile against an empty set.** Re-attempt the DoE pull in Phase 153 (post-Aug-18) when the general field resolves.
2. **FL-20 office must be created** (geo `1220`, district row exists `da308220-…`, mtfcc `G5200`, 0 offices). Exact column spec provided below — mirror any sibling FL House office (all 27 share chamber `c2facc31-…` US House).
3. **`essentials.races` has NO status/notes column** (only nullable `description`). CA/TX races leave `description` NULL. "decided" is NOT marked anywhere today. **Recommendation: mark FL races provisional by writing an explicit sentinel into `races.description`** (e.g. `'PROVISIONAL: pre-Aug-18-primary qualified field; pruned to nominees in Phase 153'`) — the only available column — AND assert it in `151-verify.sql`. Phase 153 NULLs/rewrites it on prune.
4. **Stance scope = the 17 independents is CONFIRMED CORRECT** — exactly 17 `(Independent)` candidates in the FL field, matching CONTEXT D-01's list verbatim. **155 `new_records_needed` confirmed.** Dedup: only **3 reuse targets** (Frankel, Moskowitz, Wasserman Schultz — all already in the DB); Sheila Cherfilus-McCormick is **genuinely new** (0 DB records — CONTEXT D-03's "confirm existing record, reuse" is WRONG for her; flagged below).

**Primary recommendation:** Treat `148-field-table.csv` as authoritative (DoE empty). Wave 1 authors `FL 2026 Statewide General` election + 28 races + the FL-20 office, marking each race provisional via `description`. Reuse the 150 migration/gate/smoke templates scoped to FIPS `12`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Election + race scaffold authoring | Database (migration) | — | Pure `essentials.elections`/`races` INSERTs; no app code (150 precedent) |
| FL-20 office creation | Database (migration) | — | One `essentials.offices` row, mirror sibling; Wave 1 |
| Provisional marking | Database (`races.description`) | Gate convention (`151-verify.sql`) | No status column exists → sentinel string + gate assertion |
| Candidate field wiring (`race_candidates`) | Database (push script) | — | UUID-keyed insert (`_push_uuid.ts`), reuse 150 path |
| Dedup (cross-district incumbents) | Pre-insert read (`pg` pool) | Gate assertion | Live-DB name+identity check before insert (D-03) |
| Stances (17 independents) | Research agents + push | inform schema | Federal-24 chairs-not-polarity; ≤3 concurrent researchers |
| Surfacing verification | Read-only smoke (`pg`/PostGIS) | — | `ST_Covers` coordinate smoke, FIPS 12 |

## User Constraints (from 151-CONTEXT.md)

### Locked Decisions
- **D-01** Coverage depth = RECORDS-NOW / STANCES-AT-153. All 28 districts get election + races + `race_candidates` for **every** qualified candidate (field completeness, non-negotiable). All **155** new candidates get `politician_id`-linked records now (no headshot/stance for the partisan-primary subset). 27 partial-stance incumbents LEFT AS-IS (zero-only top-up rule; none are zero-stance). **17 independent/NPA new candidates** get full-24 chairs-not-polarity stances + headshots NOW (they bypass the Aug-18 primary, are already on the Nov ballot, are NOT pruned in 153).
- **D-02** Seed EVERY qualified candidate (incl. multi-same-party + minor lines). No pre-pruning, no guessing the primary winner, no collapsing same-party fields. Mark race provisional.
- **D-03** Dedup = MANDATORY pre-insert live-DB check. Reuse existing `politician_id` for cross-district redistricted incumbents (Frankel FL-22→cand FL-23; Moskowitz FL-23→cand FL-25; Wasserman Schultz FL-25→cand FL-20). Enforce zero duplicate `full_name` (FL-scoped) in `151-verify.sql`. Confirm each reuse target against live DB (148 used naive name-matching).
- **D-04** Provisional marking — mechanism follows established conventions; planner resolves exact column against live `races` schema (RESOLVED below). Multi-same-party per district present by design; must NOT trip a one-D-one-R dedup assertion.
- **D-05** race_candidates + stance integrity conventions [INHERITED]: non-null `politician_id`, `candidate_status='active'`, incumbent `is_incumbent=true`, NEVER `office_id IS NULL`, NEVER party on the card. Retired/redistricted/vacant incumbents keep their record but get NO active row in the seat they left. Chairs-not-polarity, 0 unsourced, mandatory primary-source verification pass, honest-skip (pinned by UUID) where thin.
- **D-06** ONE phase, planner waves. Suggested seam: (W1) election + 28 races + FL-20 office + gate; (W2) reconcile + 155 records + wire all `race_candidates`; (W3) headshots + full-24 stances for 17 independents only; (W4) consolidated gate + FL coordinate smoke.

### Claude's Discretion
- Exact wave/batch split; whether 17-independent stance work is one plan or two (≤3 concurrent researchers).
- FL DoE access mechanics + reconciliation; whether to treat 148-field-table.csv as authoritative if DoE is fetch-walled (RESOLVED: it is fetchable but EMPTY → 148 CSV is authoritative).
- Provisional-marking column choice (RESOLVED: `races.description` sentinel).
- FL-20 office creation SQL (RESOLVED: spec below).
- Election/race authoring as migration vs script (follow conventions; mirror CA shape).
- Reuse 149/150 assets (`_push_uuid.ts`, stance-CSV repair pipeline, 150-verify.sql + 150-coordinate-smoke.ts as templates).

### Deferred Ideas (OUT OF SCOPE)
- Full-24 stances + headshots for the ~138 partisan (R/D) primary candidates → Phase 153 (post-Aug-18 prune, nominee coverage).
- CA (149 done), TX/NY (150 done), 144-completion gate (152), FL provisional prune (153).

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| USHC-02 | New candidate records, deduped | 155 new records; 3 reuse targets verified live (Frankel/Moskowitz/Wasserman Schultz); Cherfilus-McCormick genuinely new; FEC-noise collision guard |
| USHC-03 | Races + race_candidates seeded, field surfaces | 28 races on existing offices (+ FL-20 office created); coordinate smoke FIPS 12; 28 geofences present |
| USHC-04 | Headshots for newly-seeded in-scope candidates | 17 independents only this phase (D-01); honest-skip pinned by external_id |
| USHC-05 | Sourced stances for in-scope candidates | 17 independents, federal-24, 0 unsourced, whole-record honest-skip pinned by UUID |

## Open Question Resolutions

### Q1 — FL DoE `downloadcanlist.asp` access + reconciliation [VERIFIED via live curl]

**Access: FETCHABLE via plain `curl` — NOT JS/Cloudflare-walled.** The page is a classic ASP form (`<form name="CanDownload" action="extractCanList.asp" method="post">`). The actual data download is a **POST to `extractCanList.asp`** with the election ID:

```bash
# Mechanism (VERIFIED working — HTTP 200, Content-Type: application/tab-separated-values,
# Content-Disposition: attachment; filename=CandidateList.txt):
curl -sS -A "Mozilla/5.0" \
  -X POST --data "elecID=20261103-GEN" \
  "https://dos.elections.myflorida.com/candidates/extractCanList.asp"
```

**Tab-delimited column shape (26 columns, VERIFIED from the live header row):**
```
AcctNum · VoterID · ElectionID · OfficeCode · OfficeDesc · Juris1num · Juris2num ·
StatusCode · StatusDesc · PartyCode · PartyDesc · NameLast · NameFirst · NameMiddle ·
SuppressAddress · Addr1 · Addr2 · City · State · Zip · County · Phone ·
TrsNameLast · TrsNameFirst · TrsNameMiddle · Email
```
Relevant for reconciliation: `OfficeDesc` (office name), `Juris1num`/`Juris2num` (district number), `PartyDesc`, `NameLast`/`NameFirst`/`NameMiddle`, `StatusDesc` (e.g., active/withdrawn). `elecID` options include `20261103-GEN` ("2026 Election") and a dedicated `FED` ("Federal Offices") value.

**THE CRITICAL FINDING — the extract is EMPTY for 2026 federal/general today.** Both relevant queries return **header-only (243 bytes / 1 line, 0 candidate rows)**:
- `elecID=20261103-GEN` → 0 rows
- `elecID=FED` → 0 rows
- Even `elecID=20241105-GEN` (the 2024 General, which had candidates) → header-only. The extract returns the *currently-active filing universe*, not historical fields.

**Why:** FL US House candidates currently file for the **Aug-18-2026 partisan primary** and federally with the FEC; the DoE downloadable general-ballot extract does not populate the federal general field pre-primary (and historically clears past elections). This is consistent with the phase's defining premise (pre-primary, qualified field).

**Reconciliation plan (concrete):**
1. **Source-of-truth for Phase 151 = `148-field-table.csv` (Wikipedia-sourced).** The DoE extract cannot reconcile against an empty set; document this explicitly in the seed migration header and SUMMARY.
2. **Do NOT block the phase on the DoE pull.** Record the verified mechanism (above) and the empty result; treat 148 as authoritative per CONTEXT D-04/Discretion.
3. **Defer the authoritative DoE reconciliation to Phase 153** (post-Aug-18), when `20261103-GEN` populates with the resolved nominees — that is precisely when the field narrows and the prune happens. At that point, re-run the curl POST, parse `OfficeDesc`/`Juris1num`, filter to US House, and reconcile added/dropped candidates against the seeded provisional field.
4. **If a planner still wants a pre-primary cross-check:** the FEC `/candidates` API (filtered to FL House, cycle 2026) is the only authoritative federal source that is populated now — but that is OUT of the 151 scope (148 is the locked field) and adds no decision value for a provisional seed. Flag, don't pursue.

**Net:** Endpoint is reachable and its shape is known; data is absent → 148 CSV is the documented source. `[VERIFIED: live curl POST to dos.elections.myflorida.com 2026-06-29]`

### Q2 — FL-20 office creation [VERIFIED via live DB]

FL-20 (geo `1220`) **district row EXISTS** but has **0 offices** (vacant seat). Verified live:
- District: `id='da308220-76a5-4bb4-a446-8fbe6524ec33'`, `geo_id='1220'`, `district_type='NATIONAL_LOWER'`, `mtfcc='G5200'`, `label='Congressional District 20'`, `state='FL'`.
- All 27 existing FL House offices share **chamber_id `c2facc31-7b13-428c-b7b9-32d0d3b95f76`** (US House of Representatives — a single national chamber, NOT per-state).

**Sibling office shape (FL-19, geo 1219 — VERIFIED full row):**
```
id (gen_random_uuid)          politician_id = <the FL-19 incumbent uuid>  ← FL-20 has NO incumbent → NULL
chamber_id = c2facc31-…        district_id  = <FL-19 district uuid>        ← use FL-20's da308220-…
title = 'U.S. Representative'   representing_state = 'FL'
representing_city = NULL        description = NULL        seats = NULL
normalized_position_name = NULL partisan_type = NULL      salary = NULL
is_appointed_position = false   is_vacant = false         vacant_since = NULL
faces_retention_vote = false    role_canonical = NULL
```

**Ready spec for the new FL-20 office row (`essentials.offices`):**

| Column | Value | Note |
|--------|-------|------|
| `id` | `gen_random_uuid()` | default |
| `politician_id` | **NULL** | vacant seat — no incumbent (sibling has one; FL-20 must NOT) |
| `chamber_id` | `'c2facc31-7b13-428c-b7b9-32d0d3b95f76'` | US House (resolve by chamber name to be safe) |
| `district_id` | `(SELECT id FROM essentials.districts WHERE geo_id='1220' AND district_type='NATIONAL_LOWER')` → `da308220-…` | the join key for the race |
| `title` | `'U.S. Representative'` | matches all FL House offices |
| `representing_state` | `'FL'` | |
| `seats` | NULL | siblings are NULL |
| `is_appointed_position` | `false` | |
| `is_vacant` | **`true`** (with `vacant_since` optionally set) | this seat IS vacant; sibling shows `false` because it's filled. Reasonable to mark `true`; OR mirror sibling `false` if the planner prefers strict shape-mirroring. **Recommend `true`** (semantically correct, and `is_vacant` has a default of `false` so it must be set explicitly to `true`). |
| `faces_retention_vote` | `false` | NOT NULL, default false |
| all other text/uuid cols | NULL | mirror sibling |

**Idempotency:** guard with `WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o JOIN essentials.districts d ON d.id=o.district_id WHERE d.geo_id='1220' AND d.district_type='NATIONAL_LOWER')`. Create the office in the **same Wave-1 migration** that authors the election + races, **before** the FL-20 race INSERT, so the FL-20 race's `office_id` lookup resolves non-null (D-05: NEVER `office_id IS NULL`).

`[VERIFIED: live DB query 2026-06-29]`

### Q3 — Provisional marking [VERIFIED via live DB schema]

**`essentials.races` has NO status/notes column.** Full live column list (VERIFIED):
```
id · election_id · office_id · position_name · primary_party · seats · description · created_at · updated_at
```
- CA House races: `description=NULL`, `primary_party=NULL` (one CA non-House race has a descriptive `description` like "Governor of California — open seat", proving `description` is free-text and safe to write).
- TX House races (150-01): `description=NULL`, `primary_party=NULL`.
- **There is NO "decided" marking anywhere** — CA/TX/NY "decided" is purely conceptual / gate-convention, NOT a stored value. So "provisional vs decided" cannot be a column comparison.

**Recommendation (exact):** mark each FL race provisional by writing a **sentinel string into `races.description`**, the only available free-text column:
```sql
description = 'PROVISIONAL: pre-Aug-18-2026-primary qualified field; pruned to nominees in Phase 153'
```
Then assert in `151-verify.sql`: every FL House race has `description LIKE 'PROVISIONAL:%'` (28/28). Phase 153 rewrites/NULLs `description` when it prunes to nominees (its gate flips the assertion to "0 races still marked PROVISIONAL"). Keep `primary_party=NULL` (multi-candidate general has no single primary party — matches 150 D-05 antipartisan invariant).

**Alternative considered:** a pure gate-level convention (no DB marker, gate just asserts FL races exist + are uncontested-allowed). **Rejected** — D-04 explicitly wants the field *recorded* as provisional, and 152/153 both need a queryable signal to distinguish the FL provisional field from CA/TX/NY decided fields. The `description` sentinel is the cleanest queryable marker with zero schema change.

`[VERIFIED: live DB schema + CA/TX race rows 2026-06-29]`

### Q4 — Stance scope confirmation [VERIFIED via CSV + live DB]

**CONFIRMED CORRECT.** The FL field contains **exactly 17 `(Independent)` candidates**, matching CONTEXT D-01's list verbatim (parsed from `148-field-table.csv` `general_candidates` column):

| District | Independent candidate |
|----------|----------------------|
| FL-1 | Tyler Davis |
| FL-3 | Mike Klein |
| FL-4 | Todd Schaefer |
| FL-6 | Andrew Parrott · Alec Pavlik |
| FL-12 | Branden Scrivener |
| FL-13 | Tony D'Arrigo |
| FL-16 | Mark Davis |
| FL-17 | Michael Quirk |
| FL-18 | Deva Simmons |
| FL-19 | Seth Haskins |
| FL-20 | Kedner MaximeDe |
| FL-21 | Alexander Cooke |
| FL-24 | Andy Daro · Patricia Gonzalez |
| FL-26 | Deborah Ann Meidinger Hosey |
| FL-28 | Eddy Rojas |

- **No miscount.** 17 `(Independent)` mentions = 17 candidates. No `(No Party)`, `(NPA)`, or `(Write-In)` labels appear in the FL field — all non-D/R are labeled `(Independent)`. (FL's official designation is NPA; Wikipedia labels them "Independent" — same set.)
- **155 `new_records_needed` confirmed** (summed across all 28 FL rows).
- All 17 independents appear in `new_records_needed` → all are genuinely new records (none are existing incumbents). Stance scope is exactly these 17.

`[VERIFIED: 148-field-table.csv parse + live DB 2026-06-29]`

## Standard Stack / Reusable Assets

No new packages. Reuse the established pipeline (all verified present in the repo):

| Asset | Location | Use |
|-------|----------|-----|
| Election/race seed migration template | `backend/migrations/1109_seed_tx_ny_2026_house_elections_races.sql` | Mirror for FL (single state); next free migration number = `ls backend/migrations \| sort -t_ -k1 -n \| tail -1` + 1 |
| CA election shape | `essentials.elections` "CA 2026 Statewide General" (`728d0074-…`) | `election_type='general'`, `jurisdiction_level='state'`, `state='FL'`, `election_date='2026-11-03T08:00:00.000Z'` |
| UUID-keyed record insert | `_push_uuid.ts` (149/150) | 155 new FL records have NULL external_id → use UUID-keyed path |
| Stance-CSV repair pipeline | 149 relax-parse + canonical-restringify + `source_url_1` misalignment guard | For the 17 independents' stance CSVs |
| Verify gate template | `backend/scripts/150-verify.sql` | Adapt single-state FIPS `12` → `151-verify.sql` |
| Coordinate smoke template | `backend/scripts/150-coordinate-smoke.ts` | Single-state FL, geoPrefix `'12'`, sample districts |
| DB pool (read-only diag) | `backend/src/lib/db.ts` (`pool`) | Session pooler, port 5432; `set -a && source .env && set +a && node --import tsx …` |

**Run-from-backend reminder:** `.env` (with `DATABASE_URL`) lives in `backend/`. Inline Bash cwd resets between calls and may land in `C:\EV-Accounts` (root). Always run DB scripts from `backend/` or prefix with the absolute path; the agent's shell `set -a && source .env` only works in `backend/`.

## External_id Band Convention [VERIFIED]

- FL incumbents occupy `-12028..-12001` (27 records; FL-20 vacant has none) — `-120NN` pattern.
- TX new-record encoding (verified): `-48NNXX` (NN=2-digit district, XX=2-digit seq; e.g., TX-1 first new = `-4810101`).
- **FL new records should mirror: `-12NNXX`** (e.g., FL-1 first new = `-1210101`, FL-20 = `-1220XX`). The FL new-record band `-1229999..-1210000` is currently **empty (0 rows)** — no collision risk.
- The `151-verify.sql` in-scope / honest-skip pins should reference these new external_ids (mirroring the 150 gate's `_new_cands` band filter `external_id BETWEEN -1229999 AND -1210000`).

## Architecture Patterns (FL deltas only)

### Wave 1 migration order (single migration, BEGIN/COMMIT)
1. INSERT 1 election: `'FL 2026 Statewide General'`, mirror CA shape, `state='FL'`. Idempotent `WHERE NOT EXISTS (… name=…)`.
2. **CREATE the FL-20 office** (spec in Q2) — BEFORE the races, so FL-20's race office lookup resolves. Idempotent.
3. INSERT 28 races, one per FL geo `1201..1228`, `office_id` resolved by `districts.geo_id` join (now including the new FL-20 office), `position_name='U.S. Representative District '||cd`, `primary_party=NULL`, `seats=1`, **`description='PROVISIONAL: …'`**. Idempotent `WHERE NOT EXISTS (… election_id, office_id)`.
4. NEVER create districts (all 28 exist); NEVER `office_id IS NULL`; NEVER reuse other FL elections.
5. Post-COMMIT assert: 1 election; 28 races on FL NATIONAL_LOWER offices; 0 NULL office_id; every geo `1201..1228` has exactly 1 race; all 28 `description LIKE 'PROVISIONAL:%'`.

### Wave 2 dedup-then-wire
- For each of the 155 new candidates: query live DB by name+identity; if found (Frankel/Moskowitz/Wasserman Schultz), **reuse pid** for the cross-district active row; else create with UUID-keyed insert + `-12NNXX` external_id.
- Wire `race_candidates`: non-null `politician_id`, `candidate_status='active'`, sitting incumbent `is_incumbent=true`, NO party on card.
- Retired/redistricted/vacant incumbents get NO active row in the seat they left (FL-2 Dunn, FL-16 Buchanan, FL-19 Donalds, FL-24 Wilson retired; FL-22 Frankel / FL-23 Moskowitz / FL-25 Wasserman Schultz redistricted-away; FL-20 was vacant).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| FL DoE data parse | A bespoke ASP scraper / headless browser | Documented-empty → use 148 CSV | Endpoint is plain-curl-fetchable but holds 0 rows; scraping yields nothing |
| New-record insert | Ad-hoc INSERTs | `_push_uuid.ts` (149/150) | NULL external_id records need the UUID-keyed path; proven idempotent |
| Stance CSV ingest | Manual CSV editing | 149 relax-parse + restringify pipeline | Stance-researcher agents emit malformed CSVs (trailing-comma, quad-quote, comma-in-reasoning) |
| Provisional status column | A schema migration adding `races.status` | `races.description` sentinel | No status column exists; description is free-text, queryable, zero schema risk |
| Surfacing test | New PostGIS query | `150-coordinate-smoke.ts` (FIPS 12) | Mirrors `getElectionsByCoordinate` exactly |

## Common Pitfalls

### Pitfall 1: One-D-one-R dedup assertion false-fails on crowded same-party fields
**What goes wrong:** FL is pre-primary → FL-19 has 11 Republicans, FL-2 has 8 R + 4 D, FL-24 has ~8 D. A 150-style "≤2 active per race" or party-balance assertion would false-fail.
**How to avoid:** `151-verify.sql` must assert `full_name` uniqueness (FL-scoped) and `>=1` active per race — NOT a per-party cap. The 150 gate's USHC-03a uses `>=1` hard floor with a `<2` NOTICE (not a failure) — keep that, but the FL field is the inverse (many same-party), so do NOT add any upper-bound or one-D-one-R check. Document multi-same-party as expected (D-02/D-04).

### Pitfall 2: FEC-committee-noise false dedup match (the v2.4 two-Andy-Barrs trap)
**What goes wrong:** A naive `full_name ILIKE '%Frankel%'` matches FEC committee rows like `"FRANKEL 4 PV SCHOOLS …"`, `"FRANKEL, COMMITTEE TO ELECT LARRY"`, `"MOSKOWITZ FOR CITY COUNCIL, RON"` (all verified present in DB with NULL external_id). Reusing one of these as the candidate pid would corrupt the card.
**How to avoid:** Dedup must match on **exact identity** (the real politician record has `external_id IN (-12022, -12023, -12025)` for Frankel/Moskowitz/Wasserman Schultz), not a substring. The 3 verified reuse targets are:
- Lois Frankel → `b4040115-b3ea-4500-89cf-1ddaecafc94e` (external_id `-12022`) — active row in FL-23.
- Jared Moskowitz → `1cb8827c-6ae0-4fcf-884c-94ad2246f15d` (external_id `-12023`) — active row in FL-25.
- Debbie Wasserman Schultz → `097623b0-3063-4943-a13c-89d213ca5829` (external_id `-12025`) — active row in FL-20.
**Warning sign:** more than one DB row matches a reuse name → inspect external_id, reject committee noise.

### Pitfall 3: Sheila Cherfilus-McCormick treated as a reuse (CONTEXT D-03 error)
**What goes wrong:** CONTEXT D-03 says "Sheila Cherfilus-McCormick … confirm existing record, reuse." **She has 0 DB records** (verified — `%cherfilus%` and `%mccormick%` searches return only unrelated McCormicks: Dave/Richard/Jennifer/Jessica). She is **genuinely new** and appears in FL-20 `new_records_needed`. Treating her as a reuse would orphan her card.
**How to avoid:** Create a NEW record for Cherfilus-McCormick (FL-20, `-1220XX`). The McCormick variants in the DB are different people — do NOT match them. (Notable ex-Reps Alan Grayson, Madison Cawthorn, Kendrick Meek, Shevrin Jones, Scott Singer, Oliver Gilbert, Carla Spalding also all have **0 DB records** → all genuinely new.)

### Pitfall 4: FL-20 race authored before its office exists
**What goes wrong:** If the FL-20 race INSERT runs before the FL-20 office is created, the office lookup join returns nothing → either a skipped race (only 27 races) or `office_id IS NULL` (D-05 violation).
**How to avoid:** Create the FL-20 office FIRST in the Wave-1 migration, then INSERT all 28 races. Post-COMMIT assert exactly 28 races, 0 NULL office_id.

### Pitfall 5: Two-path / incumbent-only surfacing
**What goes wrong (inherited from 150):** Coordinate smoke surfaces only the incumbent, not the challenger field.
**How to avoid:** `151-coordinate-smoke.ts` asserts `>=1` challenger (`is_incumbent=false`) AND 0 NULL pid per sampled district. For FL the floor should stay `>=2` active with `>=1` challenger; FL-8 (Haridopolos vs Jenkins, 2 candidates) and FL-10 (Frost — currently field shows ONLY the incumbent, no challengers in 148) are edge cases — **FL-10 is uncontested in the 148 field** (`general_candidates` = "Maxwell Frost (Democratic)" only, `new_records_needed` empty). Set FL-10's `minActive` override to 1 in the smoke (uncontested-seat allowance), like the 150 gate's `<2` NOTICE. Verify FL-10 actually has no challengers before seeding (it may gain primary challengers the 148 snapshot missed — but per D-04 the 148 CSV is authoritative).

## Runtime State Inventory

> Greenfield-style data seed (no rename/refactor). Included for completeness.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `essentials.elections`/`races`/`race_candidates`, `essentials.offices` (FL-20 new), `essentials.politicians` (155 new), `inform.politician_answers`/`politician_context` (17 independents) | All net-new INSERTs; no migration of existing data |
| Live service config | None — surfacing is via DB join (`getElectionsByCoordinate`); no external service config | None |
| OS-registered state | None | None |
| Secrets/env vars | `DATABASE_URL` in `backend/.env` (read-only diag + write migration via psql) — unchanged | None |
| Build artifacts | None — pure data + one migration file | None |

**Verified:** no rename/refactor surface; all changes are additive INSERTs to the prod DB.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Prod Postgres (Supabase `kxsdzaojfaibhuzmclfq`) | All waves | ✓ | session pooler :5432 | — |
| PostGIS (`ST_Covers`/`ST_PointOnSurface`) | Coordinate smoke | ✓ | in-DB (150 smoke ran) | — |
| `pg` + `tsx` + Node | Diag/push/smoke | ✓ | Node v24.13 | — |
| FL DoE `extractCanList.asp` | Q1 reconciliation (optional) | ✓ fetchable but **EMPTY** for 2026 | n/a | **148-field-table.csv (authoritative)** |
| 28 FL geofence boundaries | Surfacing | ✓ | 28/28 with geometry | — |
| 28 FL NATIONAL_LOWER districts | Race linkage | ✓ | geo 1201..1228 | — |
| 27 FL House offices (+1 to create) | Race linkage | ✓ (FL-20 missing → create) | chamber c2facc31 | — |

**Missing with no fallback:** none. **Missing with fallback:** FL DoE 2026 data (empty) → 148 CSV.

## Validation Architecture

> `workflow.nyquist_validation` not checked as a blocker; the project uses SQL-gate + coordinate-smoke validation (149/150 precedent), which this section maps.

### Test "framework"
| Property | Value |
|----------|-------|
| Gate | `backend/scripts/151-verify.sql` (read-only psql, `\set ON_ERROR_STOP on`, `CREATE TEMP … ON COMMIT DROP`) |
| Smoke | `backend/scripts/151-coordinate-smoke.ts` (read-only `pg`/PostGIS) |
| Quick run | `cd /c/EV-Accounts/backend && set -a && source .env && set +a && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/151-verify.sql` |
| Smoke run | `cd /c/EV-Accounts/backend && set -a && source .env && set +a && node --import tsx scripts/151-coordinate-smoke.ts` |

### Phase Requirements → Test Map
| Req | Behavior | Test | File |
|-----|----------|------|------|
| USHC-03 | 28 FL races, each `>=1` active candidate, 0 NULL office_id, all `description LIKE 'PROVISIONAL:%'` | SQL assert (FIPS 12) | `151-verify.sql` (W1 race-count; W2 candidate) |
| USHC-02 | 0 duplicate `full_name` (FL); 3 reuse pids active; Cherfilus new | SQL assert + reuse pins | `151-verify.sql` (W2) |
| USHC-04 | 17 independents have a `politician_images` row (honest-skip pinned by external_id) | SQL assert | `151-verify.sql` (W3) |
| USHC-05 | 0 unsourced stance rows for 17 independents; each `>=1` sourced federal stance OR pinned whole-record skip | SQL assert | `151-verify.sql` (W3) |
| Surfacing | In-district FL coordinates surface the full field (`>=1` challenger; FL-10 uncontested allowance) | PostGIS smoke | `151-coordinate-smoke.ts` (W4) |

### Wave 0 Gaps
- [ ] `backend/scripts/151-verify.sql` — adapt `150-verify.sql` to single-state FIPS `12`, remove TX/NY cross-state scoping, add provisional-description assertion, set stance in-scope = the 17 independents only (NOT all active — incumbents are partial and left as-is, like NY).
- [ ] `backend/scripts/151-coordinate-smoke.ts` — single-state config (`st:'FL'`, `geoPrefix:'12'`, sample districts e.g. `['1201','1210','1219','1220']` covering uncontested FL-10, crowded FL-19, new-office FL-20), FL-10 `minActive` override = 1.
- [ ] Wave-1 seed migration `NNNN_seed_fl_2026_house_elections_races.sql` (election + FL-20 office + 28 provisional races).

**Stance in-scope set for the gate (critical — mirror NY's partial-incumbent exclusion):** in-scope = the 17 independents (NEW external_id band `-12NNXX`) ONLY. The 27 FL incumbents are partial-stance and LEFT AS-IS (D-01) → EXCLUDE them from USHC-05 coverage/0-unsourced checks or their pre-existing partial coverage false-fails (the exact NY false-fail trap documented in `150-verify.sql` D-01 ASYMMETRY note).

## Security Domain

> Data-seed phase; `security_enforcement` not the focus. Relevant controls:

| ASVS | Applies | Control |
|------|---------|---------|
| V5 Input Validation | yes | Seed data is human-reviewed (148 field); migration is parameterless SQL; stance CSVs pass relax-parse validation |
| V6 Cryptography | no | — |

**Threat patterns:** (1) Tampering — duplicate election/race/candidate on re-run → mitigated by `NOT EXISTS` idempotency guards (150 precedent). (2) Tampering — wrong/NULL office_id → mitigated by office-by-geo_id join + post-COMMIT assert. (3) Information disclosure — none (public candidate data). (4) The FL DoE endpoint is read-only, unauthenticated, public; no credentials involved.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | FL DoE `extractCanList.asp` will populate the 2026 general/FED federal field after Aug-18 (basis for deferring reconciliation to 153) | Q1 | LOW — even if it never populates federal candidates, 148 CSV remains authoritative; 153 can fall back to FEC API. The *current* emptiness is VERIFIED, not assumed. |
| A2 | FL labels all non-D/R candidates "(Independent)" in the 148 field = NPA in official terms (no separate NPA/Write-In set) | Q4 | LOW — verified 17 `(Independent)` and 0 other minor labels in the CSV; if a write-in exists in reality it's not in the locked 148 field (out of scope by D-04) |
| A3 | `is_vacant=true` is the correct value for the new FL-20 office (sibling shows `false` because filled) | Q2 | LOW — cosmetic/semantic; `false` (strict sibling-mirror) also works. Surfacing does not depend on `is_vacant`. |
| A4 | FL-10 (Frost) is genuinely uncontested in the seeded field (148 shows incumbent-only) | Pitfall 5 | LOW — drives the smoke `minActive` override; if a challenger is later added the smoke floor of 2 would simply pass. Verify against 148 at seed time. |

**Everything else (DoE mechanism + emptiness, FL-20 office absence + shape, races schema, dedup targets/Cherfilus-new, 17-independent count, 155 new records, external_id band) is VERIFIED against live sources this session.**

## Open Questions

1. **Does FL DoE ever surface federal (US House) candidates through this extract, or only state offices?**
   - What we know: `elecID=FED` ("Federal Offices") exists as an option but returns 0 rows today; `20261103-GEN` also 0.
   - What's unclear: whether FED populates pre-general or whether FL routes federal filings entirely to the FEC.
   - Recommendation: Re-test in Phase 153 (post-Aug-18). For 151, 148 CSV is authoritative — no blocker.

2. **Phase-153 prune mechanics for the `description` sentinel.**
   - What we know: 151 writes `description='PROVISIONAL: …'`.
   - What's unclear: whether 153 NULLs it or rewrites to a "DECIDED" marker.
   - Recommendation: 153's planner decides; 151 just needs the queryable sentinel. Note in SUMMARY for 153 carry-forward.

## Sources

### Primary (HIGH confidence)
- Live prod DB (`kxsdzaojfaibhuzmclfq`, session pooler) via `backend/src/lib/db.ts` — offices/districts/races/race_candidates/politicians schema + rows, dedup targets, external_id bands, FL-20 absence, geofence counts. Verified 2026-06-29.
- Live FL DoE endpoint `https://dos.elections.myflorida.com/candidates/downloadcanlist.asp` + `extractCanList.asp` — fetchability, POST mechanism, 26-column shape, empty 2026 result. Verified via curl 2026-06-29.
- `.planning/phases/148-field-resolution-stance-gap-diagnostic/148-field-table.csv` (28 FL rows) — field, 17 independents, 155 new records.
- `.planning/phases/151-fl-candidate-seeding-provisional-qualified-field/151-CONTEXT.md` — locked D-01..D-06.
- `backend/scripts/150-verify.sql`, `backend/scripts/150-coordinate-smoke.ts`, `backend/migrations/1109_…sql`, `150-01-PLAN.md`/`-SUMMARY.md` — pipeline templates.

### Secondary (MEDIUM confidence)
- 148 field is Wikipedia-sourced (per CSV `source_url`) — human-reviewed in Phase 148; authoritative for this phase by CONTEXT D-04.

### Tertiary (LOW confidence)
- None relied upon.

## Metadata

**Confidence breakdown:**
- Q1 DoE access/reconciliation: HIGH — mechanism + emptiness directly observed via curl.
- Q2 FL-20 office: HIGH — sibling row + district row pulled live; spec is exact.
- Q3 provisional marking: HIGH — full races schema verified; no status column confirmed.
- Q4 stance scope: HIGH — 17 independents + 155 new records counted from CSV + dedup confirmed live.
- Pitfalls: HIGH — FEC-noise rows, Cherfilus-absence, crowded-field counts all observed live.

**Research date:** 2026-06-29
**Valid until:** ~2026-08-18 (FL primary) for the DoE-empty finding; the schema/office/dedup findings are stable until the prod DB changes.
