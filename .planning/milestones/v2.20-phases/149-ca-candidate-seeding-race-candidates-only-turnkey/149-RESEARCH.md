# Phase 149: CA Candidate Seeding (race_candidates only — turnkey) - Research

**Researched:** 2026-06-28
**Domain:** Civic data seeding — `essentials.race_candidates` wiring, new `essentials.politicians` creation + dedup, headshots, federal-24 evidence-only stances, elections-feed surfacing (pure data, no backend code)
**Confidence:** HIGH (schema, pipelines, and field table all verified against the live production DB `kxsdzaojfaibhuzmclfq` and the in-repo scripts this phase reuses)

## Summary

Phase 149 is the **anchor** of the CA/TX/NY/FL US House seeding pipeline. CA is "turnkey" because its `elections` row (`728d0074-8a8d-49e3-a68c-78ccdd15434f`, "CA 2026 Statewide General") and its **52 US House `races`** already exist with **0 `race_candidates`** on the House races. The work is pure data in four established workstreams: (1) insert `race_candidates` rows onto the 52 House races; (2) create new `essentials.politicians` rows for the 38 genuinely-new CA candidates, reusing incumbents and previously-seeded figures by `politician_id`; (3) headshots for new candidates via the find-headshots Python pipeline; (4) federal-24 chairs-not-polarity evidence-only stances for the 36 zero-stance incumbents + all 38 new candidates (D-01 zero-only top-up — the 7 partials are NOT topped up here). The exact mechanics locked here are inherited by Phases 150/151.

The two costliest traps — duplicate incumbent records (the v2.4 two-Andy-Barrs / mig-1074 failure) and surfacing a non-nominee — are both pre-solved by Phase 148's locked field table (`148-field-table.csv` + `148-incumbent-map.csv`), which carries an `existing_race_id` UUID and `incumbent_pid` UUID per CA district. Phase 149 **consumes** that table; it does not re-derive the field.

**Primary recommendation:** Author one idempotent TS seed script per the `ingest-ca-sos-2026-challengers.ts` template that (a) reuses `incumbent_pid` for every renominated/previously-seeded candidate, (b) creates new `essentials.politicians` rows for exactly the 38 `new_records_needed` names using the negative-external_id scheme `-(60000 00 + cd*100 + seq)` (collision-checked), (c) inserts `race_candidates` with non-null `politician_id`, `candidate_status='active'`, `is_incumbent=true` for incumbents, sourced + idempotent by `(race_id, full_name)`. Then run the find-headshots Python pipeline for new candidates, then the stance pipeline (`politician-stance-researcher` @3-concurrency → CSV → primary-source verification → `_push_uuid.ts`/`_push.ts`). Gate read-only: 52 races each ≥2 active candidates, 0 NULL `politician_id`, 0 duplicate `full_name` within CA, headshot presence, 0-unsourced stances, and a coordinate-surfacing smoke test.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01 — Incumbent stance top-up threshold = ZERO-ONLY.** Seed federal-24 stances ONLY for the **36 CA incumbents currently at 0 stances**. The **7 partial CA incumbents (1–23 topics) are left as-is** — NOT topped up here. The 9 already-done CA incumbents (≥24) are skipped via the stance-gap diagnostic. All **38 genuinely-new CA candidates** get the full federal-24 evidence-only set regardless. (CA gap: 36 zero / 7 partial / 9 done.)
- **D-02 — Record reuse + dedup (USHC-02).** Incumbent-nominees and previously-seeded figures REUSE their existing `incumbent_pid` (from `148-incumbent-map.csv`) — NEVER INSERT a new politician row for a sitting rep (the v2.4 two-Andy-Barrs / mig-1074 failure vector). Only the 38 names in `new_records_needed` get new `essentials.politicians` rows. Zero duplicate `full_name` within CA after seeding. **Known dedup target: duplicate "Raul Ruiz" records in CA-25 — resolve before/at seeding.** Party normalized to canonical form (Democratic, not Democrat).
- **D-03 — race_candidates conventions (project invariant).** Every `race_candidates` row: non-null `politician_id`, `candidate_status='active'`, incumbent flagged `is_incumbent=true`. NEVER `office_id IS NULL` on a House race (statewide-general convention — the race carries the district's existing U.S. Representative office). NEVER put party on the candidate card (party reads from `races.primary_party`). `existing_race_id` per CA district is the live UUID in `148-field-table.csv` (re-query/confirm against the live DB at execution).
- **D-04 — Same-party (top-two) generals recorded party-agnostically.** CA has 8 D-vs-D + 1 R-vs-R same-party general districts. Seed BOTH advancers as active candidates; do NOT assume one-D-one-R; do NOT drop the second same-party candidate.
- **D-05 — Stance integrity (USHC-05, project rule).** Chairs-not-polarity (stance value = exact scale position the evidence supports, never inferred from party); every answer paired to an `inform.politician_context` row with a real fetched source URL; **0 unsourced**; honest-skip (incl. documented whole-record skip) where evidence is thin; mandatory primary-source verification pass before push. Federal-24 topic set.

### Claude's Discretion

- Wave/batch structure across the 52 districts (largest-population-first, by new-record count, or same-party-generals grouped) — planner decides.
- Whether headshots + stances are separate waves from records + race-wiring, or interleaved.
- Whether to split the phase if it exceeds the context budget (operator open to a split recommendation).
- Exact push-script mechanics (UUID-keyed `_push_uuid.ts` for NULL-external_id new records vs external_id `_push.ts`) — follow established STATE.md conventions.

### Deferred Ideas (OUT OF SCOPE)

- Top-up of the 7 CA partial incumbents (1–23 topics) to full 24 — deferred to a later sweep.
- TX/NY (Phase 150), FL (Phase 151), 144-completion gate (Phase 152), FL prune (Phase 153).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| USHC-02 | Every Wave-1 (CA) candidate has exactly one `essentials.politicians` record — incumbents/previously-seeded reuse existing record, only genuinely-new get new records; party normalized | `148-incumbent-map.csv` gives reuse `incumbent_pid` per district; `new_records_needed` = 38 names; negative-external_id scheme + name-collision dedup verified live (§Standard Stack, §Common Pitfalls); Raul Ruiz dedup resolved (§Runtime State Inventory) |
| USHC-03 | Every CA US House race surfaces on `/elections` for an in-district address via `races`+`race_candidates`, `politician_id` non-null | 52 House races live at 0 candidates; feed query traced (`getElectionsByCoordinate`) — surfaces via `office_id→district→geofence ST_Covers`; geofence boundaries present for CA House geo_ids (§Validation Architecture) |
| USHC-04 | Every newly-seeded CA candidate has a headshot (Storage 600×750 + `politician_images` row + photo_origin_url) | `seed-state-exec-headshots.py` pipeline verified — Wikipedia pageimages → 4:5 crop → 600×750 → `politician_photos` bucket → `politician_images` row (§Standard Stack, §Code Examples) |
| USHC-05 | Every CA candidate lacking them has sourced federal-24 stances, chairs-not-polarity, 0 unsourced, honest-skip, mandatory verification pass; already-stanced skipped via gap diagnostic | `research-stances` skill + `politician-stance-researcher` @3 + `_TOPIC_SCALE_FULL.txt` + `_push_uuid.ts`/`_push.ts`; stance-gap from 148 (36 zero / 7 partial / 9 done) drives D-01 zero-only scope (§Standard Stack, §Stance Pipeline) |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Candidate field → ballot truth | Data (Phase 148 artifacts) | — | Locked in `148-field-table.csv`; Phase 149 consumes, never re-derives |
| New politician record creation | Database (`essentials.politicians`) | — | INSERT with negative external_id; office row may be needed only if feed requires it (House feed resolves via `race_candidates.politician_id`, NOT via the candidate's own office) |
| Race↔candidate wiring | Database (`essentials.race_candidates`) | — | Pure INSERT onto pre-existing race UUIDs; no office_id change |
| Surfacing on /elections | API (`electionService.ts`, unchanged) | Database (geofence + races) | PURE DATA — backend code already reads `races`+`race_candidates`; no code change |
| Headshots | Storage (`politician_photos` bucket) + DB (`politician_images`) | — | Python pipeline; feed reads `COALESCE(rc.photo_url, pi.url)` via lateral join |
| Stances | Database (`inform.politician_answers` + `politician_context` + `essentials.quotes`) | — | Research → CSV → verified push; chairs-not-polarity |

## Standard Stack

### Core (established pipelines — reuse, do not rebuild)

| Tool | Location | Purpose | Why Standard |
|------|----------|---------|--------------|
| `ingest-ca-sos-2026-challengers.ts` | `backend/scripts/` | **Template** for the `race_candidates` seed script — dry-run/`--commit`, election lookup, race-by-position-name resolution, idempotent upsert by `external_id` then `(race_id, full_name)`, incumbent-status corrections | The exact precedent for CA race_candidates seeding [VERIFIED: codebase] |
| migration `1072_seed_2026_statewide_general_candidates.sql` | `backend/migrations/` | **Alternative pattern** — pure-SQL `INSERT … SELECT FROM (VALUES …) WHERE NOT EXISTS` idempotent seed with `politician_id` linked for incumbents, NULL for new | Most-recent precedent (2026) for general-election candidate seeding [VERIFIED: codebase] |
| `seed-state-exec-headshots.py` | `backend/scripts/` | Headshot pipeline: Wikipedia pageimages → license-check (free only) → 4:5 crop → 600×750 LANCZOS q90 → `politician_photos/{uuid}-headshot.jpg` (x-upsert) → INSERT `politician_images` WHERE NOT EXISTS | Established 600×750 conventions + wrong-person + non-free-license guards [VERIFIED: codebase] |
| `research-stances` skill + `politician-stance-researcher` agent | `.claude/skills/research-stances/SKILL.md` | Stance research orchestration: fetch live topics+stance-texts, dispatch agents ONE AT A TIME (premium tier: ≤3 — see MEMORY), CSV → approval → push | The canonical stance pipeline; embeds 1–5 stance texts per topic per the stance-scale-embed rule [VERIFIED: skill file] |
| `_push_uuid.ts` | `backend/data/stance-research/quick-candidates-2026/` | Push stances for **NULL-external_id / new** records — CSV keyed on `politician_id` (UUID) | For the 38 new candidates (created with negative external_id, but UUID push also works) [VERIFIED: codebase] |
| `_push.ts` | same dir | Push stances for **existing** records — CSV keyed on `external_id` (int) | For the 36 zero-stance incumbents (all have negative external_ids) [VERIFIED: codebase] |
| `_TOPIC_SCALE_FULL.txt` | same dir | The full per-topic 1–5 scale text embedded in agent prompts | Existing scale reference; federal-24 is a subset (§Stance Pipeline) [VERIFIED: codebase] |
| `pg` Pool via `backend/src/lib/db.js` | — | All read-only diagnostics + verify gates + node-tsx scripts | Project standard; raw driver for transactions [VERIFIED: codebase + CLAUDE/MEMORY] |

**No new packages installed.** This phase reuses existing scripts and the `pg` / `csv-parse/sync` / `pillow` / `requests` / `psycopg2` deps already in the repo. → **Package Legitimacy Audit not applicable** (0 external packages added).

**Run conventions (verified live):**
- TS/node scripts: `cd /c/EV-Accounts/backend && set -a && source .env && set +a && node --import tsx <script> [args]` (cwd resets between Bash calls — always one compound command).
- `_push.ts` / `_push_uuid.ts` import `pool` from `../../../src/lib/db.js` which itself does NOT auto-load dotenv → the `set -a && source .env` wrapper is mandatory.
- Python headshot script reads `.env` itself (manual parse) — run `python backend/scripts/<script>.py`.
- Production project ref: `kxsdzaojfaibhuzmclfq`. DB writes are DATA only → **no Render deploy needed** (STATE_EXEC/House already wired in `electionService.ts`; pure data).

### `essentials.race_candidates` — VERIFIED LIVE SCHEMA

```
id                       uuid     NOT NULL  default gen_random_uuid()
race_id                  uuid     NOT NULL  → FK essentials.races(id) ON DELETE CASCADE
politician_id            uuid     NULL      → FK essentials.politicians(id)   [D-03: must be non-null for House]
full_name                text     NOT NULL
first_name               text     NULL
last_name                text     NULL
photo_url                text     NULL      [feed uses COALESCE(rc.photo_url, pi.url); leave NULL → resolves via politician_images]
is_incumbent             boolean  NOT NULL  default false   [D-03: true for the seated incumbent-nominee]
candidate_status         text     NOT NULL  default 'active'  CHECK IN ('active','withdrawn','filed')
last_verified_at         timestamptz NULL
source                   text     NULL      [cite the field source_url]
external_id              text     NULL      [optional idempotency key, e.g. 'ushouse-ca-2026-<slug>']
created_at / updated_at  timestamptz NOT NULL default now()
occupational_designation text     NULL
website_url              text     NULL
```

**Constraints (VERIFIED):** PK on `id`; FK `race_id`→races (cascade); FK `politician_id`→politicians. **There is NO unique constraint on `(race_id, politician_id)` or on `external_id`.** Idempotency is enforced **in application code** (the template checks by `external_id`, then by `(race_id, full_name)`) — the seed script MUST do likewise or re-runs duplicate rows.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| TS seed script (`ingest-ca-…` template) | Pure SQL migration (`1072` pattern) | SQL migration is simpler/atomic and is the most-recent precedent, BUT the 38 new-politician INSERTs + dedup logic + negative-external_id assignment are more ergonomic in TS. **Recommendation:** the field is small/static (104 candidate rows) — either works; a SQL migration that creates the 38 politicians + 104 race_candidates in one `BEGIN/COMMIT` is the cleanest auditable artifact and matches `1072`. Planner's discretion. |
| `_push_uuid.ts` for all stances | `_push.ts` for incumbents | Both exist. Incumbents have negative external_ids (use `_push.ts`); new candidates created with negative external_ids can use either (`_push.ts` by ext_id, or `_push_uuid.ts` by UUID). Pick per-batch; UUID push is robust to external_id drift. |

## Package Legitimacy Audit

**Not applicable** — Phase 149 installs zero external packages. All tooling (`pg`, `csv-parse/sync`, `tsx`, `pillow`, `requests`, `psycopg2`) is already present in the repo and used by prior shipped phases.

## Architecture Patterns

### System Architecture Diagram (data flow, CA seeding)

```
148-field-table.csv ─┐  (existing_race_id, incumbent_pid, general_candidates, new_records_needed)
148-incumbent-map.csv┘
        │
        ▼
[Step 1: Record reconciliation]  ──► for each candidate:
        │   renominated / previously-seeded? ──► REUSE incumbent_pid (148 map)  [D-02]
        │   in new_records_needed (38)?       ──► confirm-genuinely-new (live name check) ──► INSERT essentials.politicians (neg external_id)
        │   Raul Ruiz CA-25 dup?              ──► retire the NULL-ext duplicate (is_active=false) BEFORE seeding
        ▼
[Step 2: race_candidates wiring]  ──► INSERT essentials.race_candidates
        │   (race_id = existing_race_id, politician_id NON-NULL, candidate_status='active',
        │    is_incumbent = (renominated incumbent), source = field source_url)   [D-03]
        │   idempotent by (race_id, full_name); both same-party advancers kept    [D-04]
        ▼
[Step 3: Headshots (new candidates)] ──► seed-headshots.py ──► politician_photos/{uuid}-headshot.jpg
        │                                              └──► INSERT politician_images(url,type='default')  [USHC-04]
        ▼
[Step 4: Stances]  scope = 36 zero-stance incumbents + 38 new candidates  [D-01]
        │   politician-stance-researcher @≤3 ──► per-candidate CSV (federal-24)
        │   ──► MANDATORY primary-source verification pass (re-fetch quotes; delete inference rows)  [D-05]
        │   ──► _push.ts (incumbents, ext_id) / _push_uuid.ts (new, UUID)
        │        └──► inform.politician_answers + politician_context + essentials.quotes
        ▼
[Surfacing — NO CODE]  electionService.getElectionsByCoordinate(lat,lng)
        geofence ST_Covers(point) → district geo_id 06NN → office → race → race_candidates → photo lateral
        ▼
   /elections shows the CA House race + field for an in-district address   [USHC-03]
```

### Recommended seed-script structure (mirrors `ingest-ca-sos-2026-challengers.ts`)

```
backend/scripts/seed-ca-2026-house-candidates.ts   (or a SQL migration NNNN_seed_ca_2026_house.sql)
  - dry-run default; --commit writes inside BEGIN/COMMIT
  - resolve election '728d0074-…' (assert by name 'CA 2026 Statewide General')
  - per district: resolve race by position_name 'U.S. Representative District N' (or by existing_race_id from CSV)
  - reuse map: { full_name → incumbent_pid }  (from 148-incumbent-map.csv)
  - new set:   38 names → assign negative external_id, INSERT politicians, then race_candidates
  - idempotent: skip (race_id, full_name) that already exists
```

### Pattern: New `essentials.politicians` row for a new candidate

```sql
-- Source: derived from migration 1072 + verified -6000xxx CA House external_id scheme
INSERT INTO essentials.politicians (id, external_id, full_name, first_name, last_name, is_active)
VALUES (gen_random_uuid(), $1::int, $2, $3, $4, true);
-- $1 = negative external_id (collision-checked); see Pitfall 3 for scheme
```

> **Open question (resolve at plan time):** do new House *challenger* records also need an `essentials.offices` row? The **elections feed does NOT require it** — the House race surfaces via the race's own `office_id` (the incumbent's U.S. Representative office) and resolves the candidate purely through `race_candidates.politician_id`. Prior precedent (`1072`, `ingest-ca-sos`) created challengers with **NO office row** (politician_id linked only via race_candidates). **Recommendation:** do NOT create offices for challengers — it risks polluting the reps feed / geofence search. Confirm against the headshot pipeline, which joins `offices` for its self-targeting query (the headshot script will need the candidate UUIDs passed explicitly via a manual list rather than the office-join query — see §Code Examples).

### Anti-Patterns to Avoid

- **Creating a second politician row for a renominated incumbent** (the v2.4 two-Andy-Barrs failure; mig-1074 had to dedupe). ALWAYS reuse `incumbent_pid`.
- **`office_id IS NULL` on a House race** — never; the 52 races already carry the correct `office_id` → district. Do not touch `races`.
- **Storing party on `race_candidates`** — party lives on `races.primary_party` (NULL for CA top-two). Antipartisan design.
- **Splitting on commas to parse stance CSVs** — quote columns contain commas; use `csv-parse/sync` (RFC-4180). The push scripts already do.
- **Re-running a non-idempotent insert** — no DB unique constraint exists; rely on the `(race_id, full_name)` guard.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| race_candidates upsert | New insert logic | `ingest-ca-sos-2026-challengers.ts` template (or `1072` SQL pattern) | Idempotency + dry-run + race resolution already solved |
| Headshot fetch/crop/upload | New image script | `seed-state-exec-headshots.py` (Wikipedia + manual modes) | 600×750 4:5 crop, free-license guard, wrong-person guard, Storage upsert all done |
| Stance research + scoring | Manual lookups | `politician-stance-researcher` agent via `research-stances` skill | Chairs-not-polarity framing + topic-text embedding baked in |
| Stance DB push | New upsert | `_push_uuid.ts` / `_push.ts` | answers + context + quotes + Read&Rank surname-leak guard done |
| Confirming a name is genuinely new | Trust 148 naive match | Live `essentials.politicians` name+office query | 148 used naive name-match; verifier flagged it (§Common Pitfalls) |

**Key insight:** Every primitive this phase needs already shipped in v2.4–v2.19. The phase is an orchestration of proven scripts over a locked 104-row field, not new engineering.

## Runtime State Inventory

> This phase WRITES new runtime state (politicians, race_candidates, images, stances). The relevant "inventory" is the existing live state the seed must reconcile against.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data — CA general election | `essentials.elections` "CA 2026 Statewide General" = `728d0074-8a8d-49e3-a68c-78ccdd15434f`; **53 races** (52 House + 1 Governor). House races at **0 race_candidates** (clean baseline). | Insert race_candidates onto the 52 House races only. |
| Stored data — Governor race drift | The 53rd race (CA Governor) already has **76 race_candidates** (primary leftovers from quick-016/023), including visible duplicates (e.g. "Gretha Solorzano" vs "Gretha Solórzano", "Don J. Grundmann" ×2, "Frederic C. Schultz" ×2). | **OUT OF SCOPE** for Phase 149 (House only) — but note: the `148` "52 CA races at 0 candidates" baseline is correct *for House*; the Governor race is the 53rd and is not this phase's concern. Do NOT let a `COUNT(race_candidates WHERE election='CA general')=0` assertion run — it will false-fail. Scope every gate to the 52 House races. |
| Stored data — Raul Ruiz CA-25 (D-02 dedup) | **3 records:** (a) `5238b298-…` ext `-6000325` = canonical incumbent (has headshot, in 148 map, 0 stances) — KEEP; (b) `05349fa0-…` ext NULL, has 1 office, 0 stances/img/rc — the **active duplicate to retire**; (c) `eb9448bd-…` "RUIZ FOR PERRIS CITY COUNCIL 2018; RAUL M" ext NULL, **already `is_active=false`** (FEC committee junk) — already retired. | Set `05349fa0` `is_active=false` (two-path style, NEVER hard-DELETE) BEFORE wiring CA-25; wire CA-25 incumbent to `5238b298` per the 148 map. Confirm no race_candidates/stances orphan to `05349fa0`. |
| Live service config | None — surfacing is pure DB read by already-deployed `electionService.ts`. No n8n/Datadog/external config. | None. |
| Secrets / env vars | `DATABASE_URL`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` in `backend/.env` (used by push + headshot scripts). | None — read-only use. |
| Build artifacts | None — no compiled package. | None. |

**Verified-via-live-DB findings (do not re-assume):**
- New-record name-collision risk is REAL: e.g. "Connie Chan" (ext -630001), "Mai Vang" (ext -660017), "Scott Wiener" (ext -6001011) all **already exist** as politicians (SF/Sacramento local + state records) — these are the 148 *reuse* (empty `new_records_needed`) rows and must be matched to the existing record, NOT inserted. Conversely "Joe Males" exists with NULL external_id. → The seed must do a **live name+context check** for every candidate, not trust the CSV's `new_records_needed` blindly (148 verifier finding #1).

## Common Pitfalls

### Pitfall 1: 52-vs-53 races / Governor-race candidate drift
**What goes wrong:** A gate asserting "CA general election has N race_candidates" or "0 baseline" will false-fail because the 53rd race (Governor) already carries 76 candidates from prior quick-tasks.
**Why:** The 148 baseline "52 races at 0 candidates" is true only for the **House** subset.
**How to avoid:** Scope EVERY query to the 52 House races (`position_name ILIKE 'U.S. Representative District%'` or `office.district_type='NATIONAL_LOWER'` within this election). Verified live: 52 House races, 0 candidates; 1 Gov race, 76 candidates.
**Warning signs:** A count that includes 76 unexpected rows.

### Pitfall 2: Duplicate incumbent records (the v2.4 / mig-1074 trap)
**What goes wrong:** Inserting a new politician for a renominated incumbent (e.g. two "Raul Ruiz", two "Andy Barr").
**Why:** Naive name seeding without reuse-by-id.
**How to avoid:** Drive reuse from `148-incumbent-map.csv` `incumbent_pid`. Only the 38 `new_records_needed` names get new rows. Post-seed gate: `0 duplicate full_name within CA` (scoped to active records).
**Warning signs:** A `GROUP BY full_name HAVING count>1` returning a sitting rep.

### Pitfall 3: external_id collision for new records
**What goes wrong:** A chosen negative external_id collides with an existing one → idempotency/lookup breaks.
**Why:** CA House incumbents use `-6000301..-6000352` (geo_id-derived) AND `-100013..-100045` (legacy). 179 rows already exist in the -6000xxx range.
**How to avoid:** New CA House *candidates* need a non-colliding scheme. Recommend `-(6000000 + cd*100 + seq)` (e.g. CA-2 Littau → -6000201) OR simply create them with **NULL external_id and push stances by UUID** (`_push_uuid.ts`) — the simplest collision-free path (the 7-challenger work and quick-023 both used NULL-ext + UUID push). **Verify 0 collisions** with `SELECT external_id FROM essentials.politicians WHERE external_id < 0` before authoring. (Min live neg id = -5127200010; -200 is max.)
**Warning signs:** A unique-key error or a stance pushed to the wrong person.

### Pitfall 4: Naive new-vs-reuse name match (148 verifier finding)
**What goes wrong:** Treating a `new_records_needed` name as new when an existing record (homonym or prior seed) exists, or vice-versa.
**Why:** 148 used exact/surname matching; the DB contains FEC-committee junk rows ("RUIZ FOR PERRIS…", "GALLAGHER FOR…") and legitimate homonyms (Connie Chan, Mai Vang, Scott Wiener all exist).
**How to avoid:** For each candidate, run a live query (`full_name` + office/jurisdiction context) and human/AI-confirm the match before insert. Document the reuse target UUID per district.
**Warning signs:** A new record whose name already returns a row.

### Pitfall 5: Stance over-read / fabrication (D-05)
**What goes wrong:** Agents cite a real URL but mis-state the value, fabricate a quote/figure, or infer from party.
**Why:** Documented repeatedly (quick-023 deleted 4; 7-challenger work deleted 16 inference rows).
**How to avoid:** Mandatory primary-source verification pass (re-fetch raw quotes, ideally via Playwright) BEFORE push; chairs-not-polarity; honest-skip thin topics; 0-unsourced gate. On any quote correction, wipe `essentials.quotes` for the pid+topic and re-push (stale quote otherwise lingers).
**Warning signs:** A value that matches party expectation with a generic source; a quote that doesn't appear verbatim at the cited URL.

### Pitfall 6: Concurrency rate-limit (MEMORY)
**What goes wrong:** Launching >3 stance agents at once → rate-limit hits, empty output.
**How to avoid:** Cap at **3 concurrent** on premium tier (per MEMORY; the skill itself says one-at-a-time — 3 is the validated ceiling). Validate on first wave.

## Code Examples

### race_candidates insert (incumbent reuse + new record), SQL idempotent
```sql
-- Source: migration 1072 pattern (VERIFIED), adapted for CA House
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT v.race_id::uuid, v.politician_id::uuid, v.full_name, v.first_name, v.last_name, v.is_incumbent, 'active', v.source
FROM (VALUES
  -- CA-2 (race 00a7bf9a…): Huffman incumbent (reuse 960e5acd…) + Littau new
  ('00a7bf9a-96b5-4818-9ff3-3de3a4048068','960e5acd-c847-4c8b-9a00-980483647849','Jared Huffman','Jared','Huffman',true ,'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_2'),
  ('00a7bf9a-96b5-4818-9ff3-3de3a4048068',:littau_uuid                          ,'Robin Littau','Robin','Littau',false,'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_California#District_2')
) AS v(race_id, politician_id, full_name, first_name, last_name, is_incumbent, source)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.race_candidates rc
  WHERE rc.race_id = v.race_id::uuid AND rc.full_name = v.full_name);
```

### Headshot — explicit candidate list (manual mode), reusing the verified pipeline
```bash
# Source: seed-state-exec-headshots.py --manual mode (VERIFIED).
# Manual file lines: external_id|image_url_or_path|license  (resolves UUID by external_id)
# If new candidates have NULL external_id, adapt run_manual to accept UUID directly,
# OR pre-assign negative external_ids so the existing --manual path works unchanged.
python backend/scripts/seed-ca-house-headshots.py   # (clone of seed-state-exec-headshots.py,
                                                     #  swap the target-selection query to the
                                                     #  explicit CA-2026-House candidate UUID set)
# Pipeline per candidate: Wikipedia pageimages (free license only) → 4:5 crop → 600x750 LANCZOS q90
#   → PUT politician_photos/{uuid}-headshot.jpg (x-upsert)
#   → INSERT essentials.politician_images (politician_id, url, type='default', photo_license) WHERE NOT EXISTS
```

### Stance push (new candidate, UUID-keyed)
```bash
# Source: _push_uuid.ts (VERIFIED). CSV columns: full_name,politician_id,topic_key,value,reasoning,
#   source_url_1..3,quote_text,quote_deidentified
cd /c/EV-Accounts/backend && set -a && source .env && set +a && \
  node --import tsx data/stance-research/<batch>/_push_uuid.ts <candidate>.csv
# Upserts inform.politician_answers + politician_context + essentials.quotes (Read&Rank w/ surname-leak guard)
```

### Surfacing smoke test (USHC-03) — read-only
```bash
# Source: electionService.getElectionsByCoordinate trace (VERIFIED).
# Pick an in-district lat/lng (centroid of the CA House geofence) and assert the race + field returns.
cd /c/EV-Accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
// Verify a CA House race surfaces for a point inside its geofence:
const r = await pool.query(\`
  SELECT r.position_name, count(rc.id) AS cands, count(rc.politician_id) AS linked
  FROM essentials.geofence_boundaries gb
  JOIN essentials.districts d ON d.geo_id=gb.geo_id AND (d.mtfcc IS NULL OR d.mtfcc='' OR gb.mtfcc=d.mtfcc)
  JOIN essentials.offices o ON o.district_id=d.id
  JOIN essentials.races r ON r.office_id=o.id
  JOIN essentials.elections e ON e.id=r.election_id AND e.name='CA 2026 Statewide General'
  LEFT JOIN essentials.race_candidates rc ON rc.race_id=r.id
  WHERE d.district_type='NATIONAL_LOWER'
    AND public.ST_Covers(gb.geometry, public.ST_SetSRID(public.ST_MakePoint(\$1,\$2),4326))
  GROUP BY r.position_name\`, [LNG, LAT]);
console.log(JSON.stringify(r.rows,null,1)); await pool.end();"
```

## Federal-24 Topic Set (the D-01 / D-05 stance scope)

The federal-24 is **not stored in a DB column** (`office_scope` is NULL for all 44 live topics) — it is an operational set defined by prior milestone methodology. Verified empirically: the 6 fully-done (≥24) CA federal incumbents carry exactly these **24** topics. The remaining 20 live topics are state/local/judicial-only and are OUT of scope (§REQUIREMENTS "20 non-federal topics").

**Federal-24 (use this exact set in agent prompts and the 0-unsourced gate):**
```
abortion, ai-regulation, campaign-finance, childcare, civil-rights, climate-change,
deportation, fossil-fuels, healthcare, homelessness, housing, immigration, medicare/aid,
misinformation, redistricting, religious-freedom, same-sex-marriage, school-vouchers,
social-security, tariffs, taxes, trans-athletes, voting-rights, ukraine-support
```
[VERIFIED: live DB — these 24 are the only topics carried by all 6 done-tier federal incumbents; `ukraine-support` is the 24th (carried by 5 of 6, the 6th honest-skipped it).]

> **Caveat:** a few done-tier incumbents also carry stray city-tier topics (data-centers, economic-development, homelessness-response, public-safety-approach, transportation-priorities) — these are over-research artifacts, NOT part of the federal-24. Do not seed them for House candidates. Embed only the 24 above + their 1–5 stance texts (fetched live per the `research-stances` Topic Resolution query, filtered to these 24).

## Stance scope arithmetic (D-01 zero-only)

| Group | Count | Topics each | Action |
|-------|------:|-------------|--------|
| CA incumbents @ 0 stances | 36 | federal-24 | RESEARCH (zero-only top-up) |
| CA incumbents @ 1–23 (partial) | 7 | — | **SKIP** (D-01 deferred) |
| CA incumbents @ ≥24 (done) | 9 | — | SKIP (stance-gap diagnostic) |
| New CA candidates (`new_records_needed`) | 38 | federal-24 | RESEARCH (full set) |

**Stance research universe = 36 + 38 = 74 candidates × up-to-24 topics.** Honest-skip thin topics; 0-unsourced. The 7 partials and 9 done incumbents are NOT researched.

The 9 zero-stance incumbents whose existing records have positive/legacy external_ids: most CA incumbents use `-6000301..-6000352`; a subset (CA-23/26-30/32-37/42-45) use `-100013..-100045` and CA-33 uses `-6000204`. Resolve incumbent push by external_id via `_push.ts` (all 36 zero-stance incumbents have external_ids in the 148 map).

## State of the Art

| Old Approach | Current Approach | When | Impact |
|--------------|------------------|------|--------|
| Path A (candidacy offices) for candidate surfacing | Path B — `races` + `race_candidates` (elections feed) | v2.20 research | Path A is invisible to /elections; reps feed filters `is_incumbent=true`. CA House MUST use race_candidates. |
| Stance push by name | Push by external_id (`_push.ts`) / UUID (`_push_uuid.ts`) | v2.16+ | Robust to homonyms |
| Trust 148 `new_records_needed` | Live confirm each reuse/new | 148 verifier | Prevents homonym dup |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Federal-24 = the 24 listed topics (derived empirically from done-tier incumbents, not a DB column) | Federal-24 Topic Set | If the canonical federal set differs (e.g. excludes ukraine or includes another), stance scope is off by 1–2 topics — confirm against the v2.16/v2.17 federal topic definition or operator at plan time. [ASSUMED] |
| A2 | New House challengers do NOT need an `essentials.offices` row (feed resolves via race_candidates.politician_id) | Architecture Patterns | If a downstream surface (candidate profile page, headshot self-query) requires an office, new candidates won't fully resolve — verify the candidate-detail endpoint and headshot script's target query at plan time. [ASSUMED — based on `1072`/`ingest-ca-sos` precedent which created no offices] |
| A3 | The 38 `new_records_needed` count is current vs live DB | Stance scope | If a "new" name already exists (homonym), the count drops — Pitfall 4 mitigation (live confirm) covers this. [ASSUMED — 148-verified at 2026-06-28] |
| A4 | The 52 House `existing_race_id` UUIDs in 148-field-table.csv still match live | D-03 | Re-query at execution (D-03 requires it); a race UUID drift would mis-wire. [ASSUMED — 148-verify.sql passed 2026-06-28; CA-1 spot-confirmed live this session] |

## Open Questions

1. **Seed artifact form: TS script vs SQL migration.**
   - Known: both precedents exist (`ingest-ca-sos` TS, `1072` SQL).
   - Unclear: which the operator prefers for auditability.
   - Recommendation: a single idempotent SQL migration (create 38 politicians + 104 race_candidates + retire Ruiz dup, in one transaction) is the cleanest auditable artifact and matches the most-recent precedent (`1072`). Planner's discretion (D-decision allows it).

2. **Do new challengers need an `essentials.offices` row?** (A2)
   - Recommendation: NO (precedent), but verify the headshot script's target-selection (it self-targets via an `offices` join) — clone it to take an explicit UUID list instead, OR pre-create offices. Resolve before the headshot task.

3. **Phase split?**
   - 74 candidates × stance research is the bulk. Records+race-wiring+headshots (Steps 1–3) are fast/mechanical; stances (Step 4) are the heavy workstream.
   - Recommendation: keep one phase but structure as waves — Wave A: records + race_candidates + Ruiz dedup (gate: 52 races wired, 0 dup); Wave B: headshots; Wave C: stances (batched, ≤3 concurrent). Operator is open to a split if context-budget demands.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Postgres (prod `kxsdzaojfaibhuzmclfq`) via `DATABASE_URL` | all steps | ✓ | live | — |
| `tsx` / node | seed + push scripts | ✓ | node 24.13 | — |
| `csv-parse/sync` | push scripts | ✓ | in repo | — |
| Python + Pillow + requests + psycopg2 | headshots | ✓ (used by prior phases) | — | — |
| Supabase Storage `politician_photos` bucket + `SUPABASE_SERVICE_ROLE_KEY` | headshots | ✓ | — | — |
| WebFetch / Playwright (stance research + verification) | stances | ✓ | — | one-fetch-per-URL rule (MEMORY) |
| FEC API key (cross-check only) | optional identity x-check | register free at api.data.gov/signup (1000/hr) | — | DEMO_KEY 10/hr stalls — register first |

**No blocking missing dependencies.**

## Validation Architecture

> nyquist_validation: not disabled in config → section included. This is a pure-data phase; "tests" are read-only SQL/node assertions a `149-verify.sql` (+ small node smoke) gate executes. No unit-test framework applies.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Read-only SQL gate (`psql -f`) + node-tsx smoke (pattern: `148-verify.sql`, `verify-phase-141-144.sql`) |
| Config file | none — gate is a standalone `.sql` in `backend/scripts/` |
| Quick run | `psql "$DATABASE_URL" -f backend/scripts/149-verify.sql` (expect all assertions PASS, exit 0) |
| Full suite | same gate + the coordinate surfacing node smoke (§Code Examples) |

### Phase Requirements → Test Map
| Req | Behavior | Type | Automated assertion | Exists? |
|-----|----------|------|---------------------|---------|
| USHC-03 | All 52 CA House races have ≥2 active candidates, all `politician_id` non-null | SQL | `0 = (SELECT count(*) FROM <52 House races> WHERE active_candidate_count < 2)` AND `0 = count(race_candidates WHERE politician_id IS NULL AND race in 52 House)` | ❌ Wave 0 (author 149-verify.sql) |
| USHC-03 | Race surfaces for an in-district coordinate | node smoke | `getElectionsByCoordinate`-equivalent query returns the race+field for ≥3 sample CA House centroids | ❌ Wave 0 |
| USHC-02 | No duplicate `full_name` within CA active politicians involved in this election | SQL | `GROUP BY full_name HAVING count(*)>1` over CA House candidates = 0 rows | ❌ Wave 0 |
| USHC-02 | Raul Ruiz CA-25 dedup applied | SQL | exactly 1 active "Raul Ruiz" wired to CA-25 (`5238b298…`); `05349fa0…` is_active=false | ❌ Wave 0 |
| USHC-02 | Every renominated incumbent reuses its 148 `incumbent_pid` (no new row) | SQL | each CA-renominated incumbent's race_candidate `politician_id` = the 148 map UUID | ❌ Wave 0 |
| USHC-04 | Every newly-seeded CA candidate has a headshot | SQL | `0 = count(new candidates WITHOUT a politician_images row)` (honest-skips documented + pinned) | ❌ Wave 0 |
| USHC-05 | 0 unsourced stance rows for the 36+38 in-scope candidates | SQL | `0 = count(politician_answers a WHERE a.politician_id IN scope AND NOT EXISTS politician_context c with non-empty sources)` | ❌ Wave 0 |
| USHC-05 | Each in-scope candidate has federal-24 coverage OR documented honest-skip | SQL/node | per-candidate stance count vs 24; whole-record skips pinned by UUID (USHS-14a pattern) | ❌ Wave 0 |
| D-04 | Both same-party advancers present in each of the 9 same-party districts | SQL | each listed district has both named candidates as active race_candidates | ❌ Wave 0 |

### Gate scoping rules (CRITICAL — from live findings)
- **Scope all assertions to the 52 House races** (`d.district_type='NATIONAL_LOWER'` within the CA general election) — the 53rd (Governor) race carries 76 pre-existing candidates and will false-fail any election-wide count (Pitfall 1).
- Honest-skip set (incl. any whole-record skip) MUST be pinned by exact UUID/external_id with the query's exact `ORDER BY` (the 143 gate lesson — ordering mismatch false-fails).
- Gate must be **write-free** (TEMP-table-for-diff is OK; the `148-verify.sql` pattern using `CREATE TEMP TABLE … ON COMMIT DROP` is the accepted precedent).

### Sampling Rate
- Per task commit: targeted SQL count for that task's slice.
- Per wave merge: full `149-verify.sql`.
- Phase gate: full gate green + coordinate smoke before `/gsd:verify-work`.

### Wave 0 Gaps
- [ ] `backend/scripts/149-verify.sql` — all USHC-02/03/04/05 + D-04 assertions, House-scoped, honest-skip-pinned.
- [ ] Coordinate surfacing node smoke (≥3 CA House centroids) — or fold into the gate as `ST_Covers` assertions.
- [ ] Sample in-district lat/lng per smoke district (centroid query from `geofence_boundaries`).
- [ ] (no test framework install needed)

## Sources

### Primary (HIGH confidence)
- Live production DB `kxsdzaojfaibhuzmclfq` — `race_candidates` schema + constraints, CA general election composition (53 races / 52 House @ 0 / Gov @ 76), Raul Ruiz 3-record dedup, negative external_id ranges, geofence boundary presence for CA House geo_ids, federal-24 topic derivation, name-collision spot checks. [queried this session]
- `backend/scripts/ingest-ca-sos-2026-challengers.ts` — race_candidates seed template.
- `backend/migrations/1072_seed_2026_statewide_general_candidates.sql` — most-recent general-election candidate seed precedent.
- `backend/scripts/seed-state-exec-headshots.py` — headshot pipeline (600×750, free-license, wrong-person guards).
- `backend/data/stance-research/quick-candidates-2026/_push_uuid.ts` + `_push.ts` + `_TOPIC_SCALE_FULL.txt` — stance push + scale.
- `backend/src/lib/electionService.ts` — feed query (`getElectionsByCoordinate`, RACE_SELECT, PHOTO_LATERAL, ELECTION_VISIBILITY_WINDOW).
- `.claude/skills/research-stances/SKILL.md` — stance orchestration.
- `148-field-table.csv`, `148-incumbent-map.csv`, `148-FIELD-TABLE.md`, `148-VERIFICATION.md` — locked field + reuse map + flagged follow-ups.

### Secondary (MEDIUM confidence)
- `.planning/STATE.md` v2.20 execution methodology (Path B, seed conventions, two costliest traps, stance pipeline, fetch-walls).
- MEMORY.md — 3-concurrency stance cap, no-assumption stance rule, render-deploy (data needs no deploy).

### Tertiary (LOW confidence)
- Federal-24 exact membership (A1) — derived empirically, not from a canonical DB column; flag for confirmation.

## Metadata

**Confidence breakdown:**
- Standard stack / schema / pipelines: HIGH — verified against live DB + in-repo scripts.
- race_candidates conventions + surfacing: HIGH — feed query traced; geofence + 0-baseline confirmed live.
- Dedup (Raul Ruiz) + external_id scheme: HIGH — 3 records enumerated live; ranges confirmed.
- Federal-24 membership: MEDIUM — empirically derived (A1); confirm 24th (ukraine) at plan time.
- New-candidate office requirement: MEDIUM — precedent says no office (A2); verify headshot self-query.

**Research date:** 2026-06-28
**Valid until:** 2026-07-28 (stable; re-query CA general race UUIDs + Raul Ruiz state at execution per D-03)
