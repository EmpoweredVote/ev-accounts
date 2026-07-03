# Phase 161: WA + AZ + TN + MA Candidate Seeding - Research

**Researched:** 2026-07-03
**Domain:** Pure-data election seeding (Postgres/Supabase) — elections/races/candidates authoring, headshot pipeline, stance-research pipeline
**Confidence:** HIGH (all core mechanics verified directly against this repo's schema, prior-phase migrations, and prior-phase SUMMARYs; TN redistricting facts verified via multiple news sources — MEDIUM on exact severity classification, which is explicitly a phase-internal audit deliverable, not pre-resolved here)

## Summary

Phase 161 is the anchor seeding phase for v2.22 Wave 3: WA (10) + AZ (9) + TN (9) + MA (9) = 37 districts, 100% late-primary, ~183 new candidate-record ceiling. The mechanics are a direct continuation of the proven v2.20/v2.21 pipeline (Phase 149/150/155/156/157/159): one `essentials.elections` row per state + one `essentials.races` row per district (MA reuses its 9 pre-existing races via `existing_race_id` — do NOT re-create), then new `essentials.politicians` rows for non-incumbents, `essentials.race_candidates` wiring, headshots via the Wikipedia-pageimages pipeline, and federal-24 sourced stances pushed via the `_merge.ts`/`_push.ts`/`_push_uuid.ts` scripts. Every mechanic needed already exists as a script or migration pattern in this repo — no new tooling, no new npm packages, no backend code.

The one genuinely novel piece of work is TN: a mid-cycle congressional redistricting (HB 7003/SB 7001, signed May 7, 2026) redrew the map while `essentials.districts` and `essentials.geofence_boundaries` still carry the OLD (2024-TIGER) polygons — because those same polygon rows also drive the reps feed for sitting members who represent the old districts until Jan 2027. Per the locked D-01 decision, TN races wire to the EXISTING old-numbered district rows regardless of severity; the phase opens with a correspondence audit (D-01a) to identify which districts shifted so severely (expected: the Memphis-area exchange between old TN-8/9 and the new map's TN-5/8/9) that showing the new-map-correct candidate slate against the old-map polygon would actively mislead a voter. This research proposes a concrete, code-free withholding mechanism (Common Pitfalls #1 below) that satisfies the "never `office_id IS NULL`" invariant while making the race genuinely invisible to `/elections` until a future polygon-refresh phase flips one column.

**Primary recommendation:** Clone the Phase 159 MI/VA generator-script pattern (`backend/scripts/159-{mi,va}-generate.mts` → migration SQL) once per state (4 generators: WA/AZ/TN/MA), reuse `156-verify.sql`/`158-verify.sql` structurally for the phase-161 mini-gate, and reuse the `seed-mi-house-headshots.py` script verbatim with a new `BANDS` entry per state. For the TN severe-district withholding, point the severe races' `election_id` at a dedicated, deliberately-non-general TN election row (see Pitfall #1) rather than touching `office_id`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Election/race authoring (elections, races rows) | Database / Storage | — | Pure data; no service layer writes these outside migrations |
| Race surfacing on `/elections` | API / Backend (read path) | Database | `electionService.ts` reads races+race_candidates+districts+geofence_boundaries; zero code changes this phase, but the read path's exact JOIN chain determines what data shape is safe to write |
| Candidate record creation (politicians, race_candidates) | Database / Storage | — | Pure data via migration SQL |
| Headshot ingestion (Wikipedia fetch → Storage → politician_images) | Backend script (offline, not a service route) | Database / Storage | `backend/scripts/seed-*-house-headshots.py` runs outside the request path; writes Storage + `politician_images` |
| Stance research + push (politician_answers/politician_context/quotes) | Backend script (offline) | Database | `_merge.ts`/`_push.ts`/`_push_uuid.ts` under `backend/data/stance-research/*`; writes via `pool.query()`, never PostgREST |
| TN old/new district correspondence audit | Research/analysis (no tier) | — | Pure research task producing a severity table; no runtime component |
| Consolidated read-only gate (37-district mini-gate) | Database (read-only) | — | `psql -v ON_ERROR_STOP=1 -f <phase>-verify.sql` against prod |

No frontend/browser tier work exists in this phase — `/elections` already reads the correct shape; this phase only ever writes data, never code.

## Standard Stack

This phase installs **zero new packages**. It reuses tooling already present and used by every prior v2.20/v2.21/v2.22 seeding phase.

### Core (already installed, reused verbatim)
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|---------------|
| `pg` / `backend/src/lib/db.js` `pool` | existing | All non-public-schema reads/writes | Project-mandated; PostgREST cannot see `essentials`/`inform` schemas |
| `psql` (via `psql -v ON_ERROR_STOP=1 -f`) | existing (system) | Running migrations + the read-only verify gate | Matches 149/150/155/156/157/158/159/160 precedent exactly |
| `psycopg2` + `requests` + `Pillow` (Python) | existing (`backend/scripts/seed-mi-house-headshots.py` deps) | Headshot pipeline: Wikipedia fetch, image crop/resize, Storage upload | Proven pipeline, zero changes needed except a new `BANDS` entry per state |
| `node --import tsx` + `csv-parse/sync` | existing | `_merge.ts`/`_push.ts`/`_push_uuid.ts` stance pipeline | Same pipeline used by every prior stance-research batch |
| `.mts` one-off generator scripts (e.g. `159-mi-generate.mts`) | existing pattern, new files per state | Deterministic field→SQL migration generation with dedup + external_id assignment | Avoids hand-writing 37 districts' worth of INSERT statements; keeps a reproducible source of truth |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Per-state `.mts` generator → migration SQL | Hand-written SQL INSERTs | Generator is safer for ~183 records (dedup, external_id sequencing, idempotency) — same reasoning as 159/157/156 |
| `_push.ts`/`_push_uuid.ts` per-candidate CSV push | A single mega-CSV push | Per-state vertical slices (D-03) require per-state pushable checkpoints; per-candidate files match the proven MI/VA/OH/GA/NC pattern |

**Installation:** None. `npm install` / `pip install` not required — all dependencies already present in `backend/node_modules` and the machine's Python environment (confirmed working as of Phase 159, 2026-07-01/02).

## Package Legitimacy Audit

**Not applicable.** This phase installs no new external packages (no `npm install`, no `pip install`). All scripts reuse dependencies already vetted and installed in prior phases (`pg`, `psycopg2`, `requests`, `Pillow`, `csv-parse`). No slopcheck / registry verification needed.

## Architecture Patterns

### System Architecture Diagram

```
[Phase-160 outputs]                                     [Production Supabase — kxsdzaojfaibhuzmclfq]
160-field-table-p161.csv (37 rows)                                essentials.elections
160-incumbent-map.csv  ───────┐                                          │
160-race-preexistence-audit.csv (MA existing_race_id)                    ▼
160-negative-id-audit.csv (0 collisions WA/AZ/TN/MA) │            essentials.races  ◄────┐
        │                                             │                  │              │ office_id (NEVER NULL)
        ▼                                             │                  ▼              │
[Per-state .mts generator: WA/AZ/TN/MA]  ─────────────┘         essentials.race_candidates
   - dedup vs essentials.politicians (name match)                        │  politician_id (NEVER NULL when active)
   - external_id assignment (-(fips*10000+cd*100+seq), seq starts at 1)  │
   - emits migration SQL (elections+races for WA/AZ/TN; races-only for MA reuse)
        │                                                                ▼
        ▼                                                    [/elections read path]
[psql -f migration.sql]  (idempotent, NOT EXISTS guards)      electionService.ts
        │                                                       geofence-matched query:
        ▼                                                       races → offices → districts
[Per-candidate stance research: research-stances skill]                → geofence_boundaries
   politician-stance-researcher agent (3-concurrency max)               → ST_Covers(point)
   → CSV (federal-24 topics only) → _merge.ts → _push.ts/_push_uuid.ts        │
        │                                                                     ▼
        ▼                                                          candidate field surfaces
[Headshot pipeline: seed-<state>-house-headshots.py]                (or is withheld — TN severe
   Wikipedia pageimages → license check → crop/resize →              districts, see Pitfall #1)
   Storage upload → politician_images row
        │
        ▼
[<phase>-verify.sql — read-only gate, psql -v ON_ERROR_STOP=1]
   asserts: race count, 0 NULL politician_id, 0 dup full_name,
   0 unsourced stances, headshot coverage, TN severe-race non-surfacing
```

### Recommended Project Structure
```
backend/
├── scripts/
│   ├── 161-az-generate.mts         # AZ elections+races+candidates migration generator
│   ├── 161-wa-generate.mts         # WA (same pattern)
│   ├── 161-tn-generate.mts         # TN — wires to OLD CD district rows (D-01)
│   ├── 161-ma-generate.mts         # MA — races-only insert onto existing_race_id (no election/race create)
│   ├── 161-tn-correspondence-audit.ts   # NEW: old-vs-new TN district comparison + severity scoring (read-only, no DB writes — pure geo/text analysis)
│   ├── seed-az-house-headshots.py  # clone of seed-mi-house-headshots.py, new BANDS entry
│   ├── seed-wa-house-headshots.py
│   ├── seed-tn-house-headshots.py
│   ├── seed-ma-house-headshots.py
│   └── 161-verify.sql              # consolidated read-only gate, cloned from 156/158-verify.sql
backend/migrations/
├── 11XX_seed_az_2026_house_elections_races.sql
├── 11XX_seed_az_2026_house_candidates.sql
├── 11XX_seed_wa_2026_house_elections_races.sql
├── 11XX_seed_wa_2026_house_candidates.sql
├── 11XX_seed_tn_2026_house_elections_races.sql   # TN-specific: severe-district election_id trick (Pitfall #1)
├── 11XX_seed_tn_2026_house_candidates.sql
└── 11XX_seed_ma_2026_house_candidates.sql        # MA: candidates-only, races already exist
backend/data/
├── seed-az-2026-house/161-0X-az-reconciliation.csv
├── seed-wa-2026-house/161-0X-wa-reconciliation.csv
├── seed-tn-2026-house/161-0X-tn-reconciliation.csv
├── seed-ma-2026-house/161-0X-ma-reconciliation.csv
└── stance-research/{az,wa,tn,ma}-2026-house/*.csv + _merge.ts + _push.ts/_push_uuid.ts + _TOPIC_SCALE_FULL.txt (federal-24 subset)
```

### Pattern 1: Per-state elections+races migration (new-election states: AZ, WA, TN)
**What:** One idempotent migration creates 1 `elections` row + N `races` rows wired to existing `NATIONAL_LOWER` offices.
**When to use:** Any Wave-3 state without pre-existing 2026 House races (AZ, WA, TN — NOT MA).
**Example:**
```sql
-- Source: backend/migrations/1146_seed_mi_2026_house_elections_races.sql (Phase 159-01, proven pattern)
BEGIN;
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state)
SELECT 'AZ 2026 Statewide General', '2026-11-03'::date, 'general', 'state', 'AZ'
WHERE NOT EXISTS (SELECT 1 FROM essentials.elections WHERE name = 'AZ 2026 Statewide General');

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats, description)
SELECT el.id, o.id,
       'U.S. Representative District ' || (substr(d.geo_id, 3)::int)::text,
       NULL, 1,
       'PROVISIONAL: pre-primary qualified field, cull >= 2026-07-22'  -- AZ primary Jul-21
FROM essentials.elections el
JOIN essentials.districts d ON d.district_type = 'NATIONAL_LOWER' AND substr(d.geo_id,1,2) = '04'
JOIN essentials.offices o ON o.district_id = d.id
WHERE el.name = 'AZ 2026 Statewide General'
  AND NOT EXISTS (SELECT 1 FROM essentials.races r WHERE r.election_id = el.id AND r.office_id = o.id);
COMMIT;
```

### Pattern 2: MA races-only candidate insert (reuse-existing-race states)
**What:** No `elections`/`races` INSERT at all — write only `race_candidates` onto the 9 `existing_race_id` values from `160-race-preexistence-audit.csv`.
**When to use:** MA only, this phase (analogous to Phase 159's VA slice onto its 11 pre-existing races).
**Example:**
```sql
-- Source: backend/migrations/1148_seed_va_2026_house_candidates.sql (Phase 159-03, proven pattern)
BEGIN;
-- Optional: mark the existing race description PROVISIONAL if not already
UPDATE essentials.races SET description = 'PROVISIONAL: pre-primary field, cull >= 2026-09-02'
WHERE id IN ('3bfd0d89-cbb0-4bd4-952b-798214c29f84', /* ...8 more MA existing_race_id values... */)
  AND description NOT LIKE 'PROVISIONAL:%';

INSERT INTO essentials.politicians (full_name, first_name, last_name, external_id, ...)
VALUES (...) ; -- new MA challengers only (18 ceiling)

INSERT INTO essentials.race_candidates (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status, source)
SELECT '3bfd0d89-...'::uuid, p.id, p.full_name, p.first_name, p.last_name, false, 'active', 'ma_sec_state'
FROM essentials.politicians p WHERE p.external_id = -250101
  AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = '3bfd0d89-...' AND rc.politician_id = p.id);
COMMIT;
```
**Critical:** Clark (MA-5, pid `7bf73fb2-1b31-412e-913d-835bfd3e326d`) and Pressley (MA-7, pid `c61baf45-dc2a-4d78-b4b7-21b1e9d79464`) already have `race_candidates` rows on their `existing_race_id` — see `160-race-preexistence-audit.csv` rows 29/31. **Do not re-insert them**; a `NOT EXISTS` guard on `(race_id, politician_id)` is mandatory in every MA insert.

### Pattern 3: External_id assignment (new challengers only)
**What:** `-(state_fips * 10000 + cd * 100 + seq)` — FIPS: WA=53, AZ=04, TN=47, MA=25. Per `160-negative-id-audit.csv`, **none of WA/AZ/TN/MA appear in the 16-district collision list** — every district in this phase is collision-free with `safe_start_seq = 1` (unlike KY-CD1/OK-CD1/NV/NM/etc., which needed alternate sub-bands). Still, re-verify with a live `SELECT` before authoring per the "never trust a computed band" lesson from 160-01.
**Existing incumbents keep their OWN historical external_id** (a different, older numbering convention per state — e.g. AZ incumbents are `-4001`..`-4009`, i.e. `-(fips*1000+cd)`, NOT the new-challenger formula). Never recompute or touch an incumbent's external_id; only assign the new formula to genuinely new records.
**Example (from `159-mi-generate.mts`, directly reusable pattern):**
```typescript
// Source: backend/scripts/159-mi-generate.mts (adapt FIPS constant + FIELD array per state)
const seqByCd: Record<number, number> = {};
for (const c of FIELD) {
  const geo = '04' + String(c.cd).padStart(2, '0');  // AZ example
  if (c.inc) {
    rows.push({ ...c, geo, ext: INC_EXT[c.cd], decision: c.vacate ? 'REUSE-NO-ROW' : 'REUSE', is_incumbent: true });
  } else {
    seqByCd[c.cd] = (seqByCd[c.cd] || 0) + 1;
    const ext = -(4 * 10000 + c.cd * 100 + seqByCd[c.cd]);  // AZ fips=4
    rows.push({ ...c, geo, ext, decision: 'NEW', is_incumbent: false });
  }
}
```

### Anti-Patterns to Avoid
- **Re-deriving MA's field from scratch:** MA's 9 races already exist with 2 candidates wired. Only insert the 18-record ceiling of NEW challengers; never touch or duplicate Clark/Pressley.
- **Setting `office_id IS NULL` for TN's severe districts:** violates the locked, milestone-wide invariant. Use the election-visibility mechanism (Pitfall #1) instead.
- **Recomputing an incumbent's external_id under the new formula:** incumbents keep their historical id; only new challengers get `-(fips*10000+cd*100+seq)`.
- **Skipping the live collision re-check because 160 already audited 0 collisions:** re-run the `SELECT` anyway — the 160-01 SUMMARY explicitly states "never trust a computed negative external_id band as collision-free."

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|--------------|-----|
| Headshot licensing/wrong-person detection | A new image-fetch script from scratch | Clone `seed-mi-house-headshots.py`, add a `BANDS` entry per state | The wrong-person guard (title must contain first+surname, reject non-political disambiguators, reject pre-1940 historical homonyms) took multiple phases of hardening (Bouchard incident) — do not re-derive it |
| Stance topic scale texts | Hand-typing the 1-5 stance text per topic into agent prompts | Fetch live from `inform.compass_topics`/`inform.compass_stances` per the `research-stances` skill's Topic Resolution query, then filter to the federal-24 subset | Topic set grows over time (44 live topics as of 2026-06-02, will be different by execution time); a hardcoded `_TOPIC_SCALE_FULL.txt` copy risks staleness |
| CSV→DB stance push with quote/dedup/leak-checking | A new push script | `_merge.ts` + `_push.ts` (existing pid) / `_push_uuid.ts` (new NULL-external_id pid) per `backend/data/stance-research/*` | Handles RFC-4180 parsing, surname-leak guard on Read & Rank quotes, transactional per-file push — reinventing this risks the surname-leak bug class |
| Gate assertions for a multi-state seeding batch | A bespoke ad hoc verify script | Clone `156-verify.sql` (3-state) or `158-verify.sql` (multi-state coordinate gate) structurally | These encode hard-won per-state-scoping discipline (the "cross-state contamination trap") and the honest-skip-pin-ordering lesson (Phase 143) |
| TN district polygon comparison | A custom GIS diff pipeline | Public comparison sources: TN Comptroller's official map (via `sos.tn.gov/announcements/2026-congressional-redistricting`), Wikipedia's "2026 Tennessee redistricting" article, Dave's Redistricting App (dra2020.org) side-by-side view, Census TIGER for the old shapes already in `essentials.geofence_boundaries` | No need to fetch/parse shapefiles directly — the qualitative county-level breakdown (which counties moved between which CDs) is sufficient for a severity classification, and it's already reported by multiple outlets |

**Key insight:** Every mechanical piece of Phase 161 (elections/races authoring, headshots, stance push, gate) is a *parameterization* of an already-proven script, not new engineering. The only genuinely new artifact is the TN correspondence-audit script/analysis and the severe-district withholding mechanism — everything else is "change the FIPS code and the FIELD array."

## Common Pitfalls

### Pitfall 1: How to withhold a TN "severe" race from `/elections` without `office_id IS NULL`
**What goes wrong:** D-01b requires severe TN districts to have races+candidates+stances seeded but NOT surfaced on `/elections`. A naive approach (`office_id = NULL`) violates the locked, milestone-wide "NEVER `office_id IS NULL` on a House race" invariant that Phase 166's gate will assert across all 178 districts.
**Why it happens:** The obvious "make it invisible" lever (nulling the FK the geofence query requires) is also the lever every other gate treats as a hard-fail signal.
**How to avoid:** Point the severe race's `election_id` at a **dedicated, non-general TN "withheld" election row** instead of the shared `TN 2026 Statewide General` row. `electionService.ts`'s `ELECTION_VISIBILITY_WINDOW` is:
  ```sql
  (e.election_type != 'general' AND e.election_date >= CURRENT_DATE - INTERVAL '30 days')
  OR (e.election_type = 'general' AND e.election_date >= DATE_TRUNC('year', CURRENT_DATE::date))
  ```
  A general-type election dated anywhere in 2026 is ALWAYS visible (year-level check, not day-level) — so you cannot suppress one race under the shared general election by date alone. Instead:
  1. Create a second election row, e.g. `('TN 2026 Congressional Redistricting — Polygon Pending', election_date='2026-05-07', election_type='special', jurisdiction_level='state', state='TN')` — `election_type != 'general'` and the date is >30 days in the past, so `ELECTION_VISIBILITY_WINDOW` evaluates false and the race never surfaces via any of `electionService.ts`'s three query paths (`fetchDistrictRaceRows`, the geofence-matched `getElectionsByCoordinate` Part A, `fetchStatewideRaceRows` doesn't apply to NATIONAL_LOWER).
  2. Wire the severe race's `office_id` normally (satisfies the invariant — this is the SAME old-CD-numbered office every other TN race uses, per D-01).
  3. Race, candidates, and stances all insert exactly like a normal district — the ONLY difference is `election_id`.
  4. When the future polygon-refresh phase runs (before Phase 165, per D-01c), it flips these races' `election_id` back to the real `TN 2026 Statewide General` row with a one-line `UPDATE` — "zero rework," matching the operator's original requirement.
**Verify:** `SELECT r.id FROM essentials.races r JOIN essentials.elections e ON e.id = r.election_id WHERE e.name = 'TN 2026 Congressional Redistricting — Polygon Pending'` should return exactly the severe-district race IDs, and a coordinate smoke test against a point inside a severe district should return **zero** House races (while returning the correct old-district incumbent on the reps feed, since reps reads `offices`, not `races`).
**Warning signs:** If a smoke test against a severe TN district's coordinate DOES return a House race, the election_id substitution was skipped or the visibility window math was miscalculated (double-check `election_type` is NOT `'general'`).

### Pitfall 2: TN incumbent-office linkage staying correct while the race is withheld
**What goes wrong:** TN's reps feed (`essentials.offices`) must keep showing the TRUE current (old-map) incumbent for a severe district, even though the /elections race for that district is withheld. Phase 159's VA-5/6/9 incident (office↔politician_id rotation bug) shows this class of bug is easy to introduce silently.
**Why it happens:** Confusing "the CANDIDATE FIELD is withheld from /elections" with "the OFFICE→POLITICIAN link should also change" — they are unrelated. D-01 explicitly says only the address→race polygon join is stale; the reps feed must NOT be touched by this phase.
**How to avoid:** This phase writes ONLY to `essentials.elections`/`races`/`politicians`/`race_candidates`. Never touch `essentials.offices.politician_id` for TN. Verify with a query mirroring 159-03's fix: confirm every TN `offices` row's `politician_id` is unchanged pre/post migration.
**Warning signs:** A migration diff touching `essentials.offices` for TN geo_ids is a signal this phase has scope-crept into Phase 161-out-of-scope territory (D-01c's future dual-map phase).

### Pitfall 3: MA declared-independent gate timing (Aug-25 filing window)
**What goes wrong:** Seeding MA's independents NOW (2026-07-03) risks missing late filers, or over-including unqualified FEC-only filers.
**Why it happens:** MA's independent filing deadline (Aug-25) is AFTER this phase's execution window but BEFORE MA's Sep-1 primary/general resolution.
**How to avoid:** Per the locked "declared-so-far" pattern (established in 160-02), seed ONLY news-evidenced declared independents (e.g., Milleron MA-1) — exclude bare FEC-committee registrations with no news coverage of an actual declared candidacy. Phase 167's MA cluster (week of Aug 31–Sep 6) reconciles the rest.
**Warning signs:** A "candidate" whose only source is an FEC filing with no campaign site, news mention, or social presence is very likely a placeholder registration, not a real declared candidate — apply the same standard used for FEC-committee-junk dedup elsewhere in this project.

### Pitfall 4: WA top-two ballot system's post-primary cull is NOT the standard "prune losers, confirm nominee" shape
**What goes wrong:** WA's Aug-4 top-two primary sends the TOP TWO vote-getters regardless of party to November — unlike every other state in this phase, where the standard multi-party general model applies. If Phase 167's WA cluster naively applies the standard "each party's nominee advances" logic, it will incorrectly retain one candidate per party instead of the actual top-two.
**Why it happens:** `ballot_system=top-two` is a WA-specific field on the field table; the seeding phase (161) is unaffected (full field is seeded regardless), but this is a landmine for the future Phase 167 WA cluster.
**How to avoid:** Not this phase's concern to fix, but Phase 161 should NOT invent WA-specific races/candidates logic — seed the full qualified field exactly like every other late-primary state (one race, N active candidates from all parties). Flag this note for Phase 167's WA cluster plan (a repo-level breadcrumb, e.g. in the phase's SUMMARY or the field table's ballot_system column, both of which already carry this flag).
**Warning signs:** None for Phase 161 itself — this is a forward-looking flag only.

### Pitfall 5: Federal-24 topic filtering — do not paste the full 44-topic file into agent prompts
**What goes wrong:** `backend/data/stance-research/*/_TOPIC_SCALE_FULL.txt` files observed in this repo (e.g. `quick-candidates-2026/_TOPIC_SCALE_FULL.txt`) contain ALL 44 live topics (city + judicial + data-centers included), not just the federal-24 subset. Federal House candidates should only be scored on the 24 federal-appropriate topics.
**Why it happens:** The master topic-scale dump is a convenience artifact for ALL research (city, state, federal); nothing prevents copy-pasting the wrong subset into a House-candidate agent prompt.
**How to avoid:** Federal-24 = all-live-topics MINUS 11 city-only topics (`transportation-priorities`, `economic-development`, `homelessness-response`, `residential-zoning`, `city-sanitation`, `local-immigration`, `rent-regulation`, `growth-and-development`, `local-environment`, `public-safety-approach`, `jail-capacity`) MINUS 8 judicial-only topics (`judicial-*`) MINUS `data-centers` = 24 (verified: 44 − 11 − 8 − 1 = 24, matching the `research-stances` SKILL.md's own exclusion list). Build the per-state `_TOPIC_SCALE_FULL.txt` by filtering the live-DB query, not by copying an old file — the topic set changes over time (44 as of 2026-06-02; re-verify count at execution time).
**Warning signs:** An agent scoring a House candidate on `residential-zoning` or any `judicial-*` topic is a filtering miss.

## Code Examples

### Live topic-set query, then filter to federal-24 (verify count before dispatching agents)
```bash
# Source: .claude/skills/research-stances/SKILL.md STEP 0 (adapted)
cd /c/EV-Accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const EXCLUDE = new Set(['transportation-priorities','economic-development','homelessness-response',
  'residential-zoning','city-sanitation','local-immigration','rent-regulation','growth-and-development',
  'local-environment','public-safety-approach','jail-capacity','data-centers']);
const { rows } = await pool.query(\`
  SELECT t.id, t.topic_key, t.title, t.question_text,
         json_agg(json_build_object('value', s.value, 'text', s.text) ORDER BY s.value) AS stances
  FROM inform.compass_topics t JOIN inform.compass_stances s ON s.topic_id = t.id
  WHERE t.is_live = true GROUP BY t.id, t.topic_key, t.title, t.question_text ORDER BY t.topic_key
\`);
const fed24 = rows.filter(r => !EXCLUDE.has(r.topic_key) && !r.topic_key.startsWith('judicial-'));
console.log('federal-24 count:', fed24.length);  // MUST equal 24 before dispatching any agent
console.log(JSON.stringify(fed24, null, 2));
await pool.end();
"
```

### Live external_id collision re-check (never trust the pre-audit alone)
```bash
# Source: 160-01-SUMMARY.md lesson — "never trust a computed negative external_id band as collision-free"
cd /c/EV-Accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const candidates = [-40101, -40102, -40103];  // example AZ-1 seq 1-3
const { rows } = await pool.query('SELECT external_id FROM essentials.politicians WHERE external_id = ANY(\$1::bigint[])', [candidates]);
console.log(rows.length === 0 ? 'CLEAR' : 'COLLISION: ' + JSON.stringify(rows));
await pool.end();
"
```

### TN correspondence audit skeleton (no DB writes — pure research artifact)
```
For each TN geo_id (4701..4709):
  1. Pull old-map county composition (from essentials.geofence_boundaries via a read-only
     ST_Intersects-against-county-boundaries query, OR from the pre-2026 TIGER/Census description).
  2. Pull new-map county composition (from the TN Comptroller's official redistricting map / the
     TN General Assembly's HB 7003 district descriptions / Wikipedia's "2026 Tennessee redistricting").
  3. Score severity: % of the district's population in counties that moved to a DIFFERENT CD.
     Facts already known from research: Shelby County (Memphis) split three ways among new CD-5/8/9;
     Davidson County (Nashville) split three ways among new CD-4/6/7. TN-1/2/3 (East TN) are reported
     as largely unaffected by every source found. Old TN-9 (Cohen's seat) is explicitly dismantled.
  4. Districts scoring "severe" (recommend threshold: >25% of population moved to a different CD, OR
     the district's core anchor city/county changed) get the Pitfall-#1 withholding treatment.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|-------------------|---------------|--------|
| Deferring late-primary states to a separate date-gated seeding phase (early v2.21 Phase 159 framing) | Seed the FULL provisional field in the SAME seeding phase, cull later (Phase 167) | Phase 159 reframe, 2026-07-01 | Every Wave-3 late-primary state (incl. all of 161) follows this from the start — no separate "wait for primary" phase exists |
| Assuming all Wave-3 states need `elections`/`races` created from scratch | 5 states (MA, MD, OR, NV, ME) already have pre-existing races for 2026-11-03 | Discovered live in Phase 160, 2026-07-02/03 | MA (this phase) is races-reuse, NOT create-from-scratch — contradicts the original ROADMAP assumption; already corrected in this phase's CONTEXT.md |
| Treating "office_id must always point to the district's currently-correct polygon" as implicit | TN explicitly keeps races wired to OLD polygons on purpose (D-01) — polygon correctness and race correctness are decoupled | This phase's discuss-phase session, 2026-07-03 | Establishes a reusable pattern for any future mid-cycle redistricting state (MO/AL/LA/UT flagged) |

**Deprecated/outdated:** The original ROADMAP.md assumption "none of the 38 states have pre-seeded 2026 House races" is FALSE for 5 states (see 160-FIELD-TABLE.md §8) — always re-verify with the Phase-160-style pre-existence audit query before assuming create-from-scratch for any state.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|----------------|
| A1 | The TN severity threshold ">25% of district population moved to a different CD" is a reasonable, defensible cutoff | Common Pitfalls #1 / Code Examples (TN audit skeleton) | If too strict, districts that should be withheld surface wrong data to voters; if too loose, districts that are actually fine get needlessly hidden. This is explicitly flagged as Claude's/planner's discretion in CONTEXT.md (D-01a/D-01b) — the phase's own audit task should set the final rubric, not this research |
| A2 | The election-visibility-window substitution (Pitfall #1) is the best withholding mechanism, vs. e.g. `candidate_status='filed'` on all of a severe race's candidates | Common Pitfalls #1 | `candidate_status='filed'` was considered but rejected: it's unclear whether every `/elections` code path filters non-active candidates at the SQL level (some LEFT JOINs shown don't filter `candidate_status`), so a race with all-filed candidates might still surface with an empty candidate list rather than being fully invisible — the election-visibility mechanism is provably complete against all three `electionService.ts` query paths reviewed in this research |
| A3 | TN-1/2/3 (Harshbarger/Burchett/Fleischmann, East TN) will score "not severe" and TN-9 (Cohen, dismantled) will score "severe" | Summary / Common Pitfalls #1 | Based on convergent reporting (Shelby/Davidson county splits) but not a district-by-district GIS diff — the phase's own audit task must confirm precisely, including TN-4/5/6/7/8 which are also reported as touched by the Nashville/Memphis county exchanges and may also warrant severe classification |
| A4 | No new npm/pip packages are needed for this phase | Package Legitimacy Audit | If the TN correspondence audit needs a shapefile/GIS diff library not already installed, a package legitimacy check would be newly required — low risk since the qualitative county-level approach (Don't Hand-Roll table) avoids this dependency entirely |

## Open Questions (RESOLVED)

> All three questions are disposed of by the final plan set (plan-checker pass 2026-07-03):
> Q1 → RESOLVED: the classification IS 161-01's deliverable (audit plan runs first, emits the machine-readable severe list TN seeding consumes). Q2 → RESOLVED: deferred to Phase 164.1 (polygon-refresh/dual-map, now inserted in ROADMAP) — this phase writes no geofence data. Q3 → RESOLVED: every migration-authoring task re-checks `ls backend/migrations` at author time; plans sequence 1187–1193 with one migration author per wave.

1. **Exact TN severity classification (which of TN-4 through TN-9 are "severe")**
   - What we know: Shelby County (Memphis) splits three ways among new CD-5/8/9; Davidson County (Nashville) splits three ways among new CD-4/6/7; TN-9 (Cohen) is explicitly dismantled; TN-1/2/3 (East TN) are reported unaffected by every source found.
   - What's unclear: Whether TN-4/5/6/7/8 (all touched by the Nashville/Memphis exchange, per NPR/Tennessee Lookout reporting) individually cross a "severe" threshold, or whether only TN-9 (and possibly TN-8, its most Memphis-adjacent old neighbor) do.
   - Recommendation: The phase's first plan (D-01a, the correspondence audit) should pull the TN Comptroller's official before/after district descriptions (via `sos.tn.gov/announcements/2026-congressional-redistricting`) and Wikipedia's "2026 Tennessee redistricting" article's per-district composition tables, then apply the >25%-population-moved rubric (or a county-anchor-changed rubric) per district and document the result as a phase artifact before any TN race authoring begins.

2. **Whether TN's `essentials.geofence_boundaries` old polygons are also used by any OTHER live feature besides the reps feed and (now) the withheld /elections races**
   - What we know: D-01's rationale explicitly says "both feeds share one polygon" (reps + elections).
   - What's unclear: Whether any other geofenced feature (e.g., city/county overlay lookups, jurisdiction resolution for `connected_profiles`) also reads TN's `NATIONAL_LOWER` geofence_boundaries and could be affected by this phase's writes. This phase writes no geofence data, so risk is low, but worth a quick grep of `geofence_boundaries` consumers before execution if time allows.
   - Recommendation: Low priority — this phase does not touch `geofence_boundaries` at all, so the risk is theoretical; flag for the future dual-map/polygon-refresh phase (D-01c) instead.

3. **Exact next migration number to use**
   - What we know: Last migration in the repo as of this research is `1149_fix_va_5_6_9_incumbent_office_rotation.sql`.
   - What's unclear: Whether any other in-flight work (e.g., the parallel Phase 177/178 session) has claimed `1150+` already.
   - Recommendation: Planner should re-check `ls backend/migrations/ | sort | tail -5` immediately before authoring the first Phase-161 migration, not rely on this research's snapshot.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|--------------|-----------|---------|----------|
| `psql` CLI | Migration execution + verify gate | ✓ (used throughout 148-160) | system | — |
| `node --import tsx` | `.mts` generators, `_merge.ts`/`_push.ts` stance scripts | ✓ | project-pinned | — |
| Python 3 (`py`, NOT `python3`) | Headshot pipeline (`seed-*-house-headshots.py`) | ✓ (confirmed 2026-07-02: `python3` is a dead MS-Store alias; use `py`) | Python 3.14.3 | Use `py` explicitly in every command, not `python3` |
| Supabase prod DB (`kxsdzaojfaibhuzmclfq`) via `backend/.env` `DATABASE_URL` (Session pooler) | All writes/reads | ✓ | — | — |
| WebFetch/Playwright for stance research | Sourcing citations for stances | ✓ (rate-limited; 3-concurrency cap per project standard) | — | Playwright orchestrator-run for Ballotpedia-walled sources (per 150 Playwright method) |

**Missing dependencies with no fallback:** None identified.

**Missing dependencies with fallback:** None beyond the `python3`→`py` substitution already known and trivially applied.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None (no unit-test framework) — this project verifies data-seeding phases via read-only SQL assertion scripts (`psql -v ON_ERROR_STOP=1 -f <phase>-verify.sql`) and standalone TS/Python coordinate-smoke scripts, per the 149→160 precedent. No Jest/pytest/vitest applicable — pure-data phase. |
| Config file | none — see Wave 0 below |
| Quick run command | `cd /c/EV-Accounts/backend && set -a && source .env && set +a && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/161-verify.sql` |
| Full suite command | Same command — the gate script IS the full suite for this phase (single consolidated DO block, per 156/158 precedent) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|---------------------|-------------|
| USHC3-02 | 0 duplicate politician rows per state; new/reuse split correct | SQL assertion | `psql -f scripts/161-verify.sql` (dup-full_name + reuse-pid checks, cloned from 156-verify.sql §USHC2-02a/02c) | ❌ Wave 0 — write `161-verify.sql` |
| USHC3-03 | 37 races exist, 0 NULL office_id, 0 NULL politician_id (active), race count exact | SQL assertion | same file, scope-count + NULLPID checks (156-verify.sql pattern) | ❌ Wave 0 |
| USHC3-03 (TN severe) | Severe TN races exist but do NOT surface via `/elections` | SQL assertion + coordinate smoke | `161-verify.sql` (election_id substitution check) + `161-coordinate-smoke.ts` (0 races returned for a severe-district test point) | ❌ Wave 0 — both new |
| USHC3-04 | Every new candidate has a `politician_images` row or a pinned honest-skip | SQL assertion | `161-verify.sql` (`_img_skip` pattern, 156-verify.sql §USHC2-04) | ❌ Wave 0 |
| USHC3-05 | 0 unsourced stance rows; every in-scope candidate has ≥1 sourced federal stance or a pinned whole-record skip | SQL assertion | `161-verify.sql` (`_stance_skip`/`_in_scope`/`_fed24` pattern, 156-verify.sql §USHC2-05a/05b) | ❌ Wave 0 |
| MA reuse invariant | Clark (MA-5) / Pressley (MA-7) `race_candidates` rows not duplicated | SQL assertion | `161-verify.sql` (exactly-1-row-per-pid-per-race check) | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** targeted `psql` SELECT for the specific state/district just written (idempotency + row-count spot check, per every prior phase's task-level verify pattern)
- **Per state-slice merge:** run the state-scoped subset of `161-verify.sql` assertions (or the whole file, since it's cheap)
- **Phase gate:** Full `161-verify.sql` green + a `161-coordinate-smoke.ts` (clone of `158-coordinate-smoke.ts`, extended to WA/AZ/TN/MA, MIN_DISTRICTS=4, including one severe-TN-district negative-result sample) before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `backend/scripts/161-verify.sql` — consolidated read-only gate, clone structurally from `156-verify.sql` (3-state pattern) + `158-verify.sql` (coordinate-gate pattern); needs a NEW assertion block for the TN severe-race non-surfacing invariant (no prior-phase precedent for this specific check — must be authored fresh)
- [ ] `backend/scripts/161-coordinate-smoke.ts` — clone of `158-coordinate-smoke.ts`, extended to 4 states, with an explicit negative-result sample for at least one severe TN district
- [ ] `backend/scripts/161-tn-correspondence-audit.ts` (or a plain markdown research task, no code needed) — D-01a deliverable, produces the severity table
- [ ] Per-state `.mts` generators (`161-{az,wa,tn,ma}-generate.mts`) — clone `159-mi-generate.mts` / `159-va-generate.mts`
- [ ] Per-state headshot scripts (or a single parameterized script with a `BANDS` dict entry per state) — clone `seed-mi-house-headshots.py`

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|--------------------|
| V2 Authentication | No | No auth surface changed — pure data phase, no new endpoints/routes |
| V3 Session Management | No | Not applicable |
| V4 Access Control | No | Not applicable — writes happen via `pool.query()` with the service-role `DATABASE_URL` (Session pooler), never via a public-facing route; RLS unaffected |
| V5 Input Validation | Partial | Migration SQL generators (`.mts` files) parameterize INSERTs from typed arrays, not raw string concatenation — `sqlStr()` helper in `159-mi-generate.mts` escapes single quotes; carry this pattern forward for all 4 new generators |
| V6 Cryptography | No | Not applicable |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|-----------------------|
| SQL injection via unescaped candidate names in generated migration SQL | Tampering | Use the `sqlStr()` quote-escaping helper (or parameterized queries in the TS push scripts) for every free-text field (candidate names, source URLs, reasoning text) — never raw string interpolation |
| Data-integrity drift (a "seeded but withheld" race accidentally surfacing due to a future unrelated migration touching `election_type`) | Tampering / Repudiation | The `161-verify.sql` gate's TN-non-surfacing assertion should be re-run as part of EVERY subsequent phase's gate that touches TN data (166's consolidated gate, and any future dual-map phase) — document this dependency explicitly in the phase's SUMMARY for downstream phases to inherit |

This phase has an unusually small security surface (no new code, no new auth/access paths, production DB access already gated by the existing service-role credential model) — the primary "security-adjacent" concern is data-integrity (the TN withholding mechanism must not silently break), which is covered under Validation Architecture above rather than classic ASVS categories.

## Sources

### Primary (HIGH confidence)
- This repo's own schema: `backend/migrations/042_election_schema.sql` (essentials.elections/races/race_candidates DDL, read directly)
- This repo's own prior-phase migrations: `1146_seed_mi_2026_house_elections_races.sql`, `1147_seed_mi_2026_house_candidates.sql`, `1148_seed_va_2026_house_candidates.sql`, `1149_fix_va_5_6_9_incumbent_office_rotation.sql` (read directly)
- This repo's own service code: `backend/src/lib/electionService.ts` (RACE_SELECT, ELECTION_VISIBILITY_WINDOW, all 4 query paths, read directly)
- This repo's own generator/headshot scripts: `backend/scripts/159-mi-generate.mts`, `backend/scripts/seed-mi-house-headshots.py` (read directly)
- This repo's own gate templates: `backend/scripts/156-verify.sql`, `.planning/phases/158-coordinate-verification-gate/158-01-SUMMARY.md` (read directly)
- This repo's own prior-phase SUMMARYs: `159-01-SUMMARY.md`, `159-02-SUMMARY.md`, `159-03-SUMMARY.md` (read directly)
- Phase-160 authoritative artifacts: `160-field-table-p161.csv`, `160-FIELD-TABLE.md`, `160-incumbent-map.csv`, `160-race-preexistence-audit.csv`, `160-negative-id-audit.csv`, `160-02-SUMMARY.md`, `160-01-SUMMARY.md` (read directly)
- `.claude/skills/research-stances/SKILL.md` (read directly — topic resolution query, push mechanics, exclusion list)

### Secondary (MEDIUM confidence)
- [Tennessee Secretary of State — 2026 Congressional Redistricting](https://sos.tn.gov/announcements/2026-congressional-redistricting) — official map/announcement page
- [2026 Tennessee redistricting — Wikipedia](https://en.wikipedia.org/wiki/2026_Tennessee_redistricting)
- [Tennessee Lookout — Tennessee Republicans pass US House map carving up Memphis](https://tennesseelookout.com/2026/05/07/tenn-passes-new-potential-9-0-gop-u-s-house-map-eight-days-after-scotus-guts-voting-rights-act/)
- [NPR — Tennessee Republicans pass a map to break up the state's lone Democratic House seat](https://www.npr.org/2026/05/07/nx-s1-5815023/tennessee-redistricting-map-passage)
- [NPR — What Tennessee's new redistricting map looks like from the ground](https://www.npr.org/2026/05/13/nx-s1-5818509/what-tennessees-new-redistricting-map-looks-like-from-the-ground)
- [localmemphis.com — Tennessee adopts new congressional map carving up Memphis](https://www.localmemphis.com/article/news/politics/tennessee-lawmakers-expected-to-vote-on-newly-proposed-congressional-map/522-fede6f0a-aacb-433e-a105-92da1bdd6c7e)
- [localmemphis.com — Judges dismiss NAACP lawsuit against new Tennessee congressional map](https://www.localmemphis.com/article/news/local/state-court-dismisses-lawsuit-against-new-tennessee-congressional-map/522-ad11c2ac-68c8-4244-be91-0ec4c7b64474)

### Tertiary (LOW confidence)
- None used as load-bearing claims in this document — all TN redistricting facts were cross-confirmed across 3+ independent news outlets plus the official state announcement page.

## Metadata

**Confidence breakdown:**
- Standard stack / pipeline mechanics: HIGH — every script/migration pattern read directly from this repo's own prior-phase artifacts, not inferred
- Architecture (elections/races/race_candidates authoring, MA reuse, external_id scheme): HIGH — schema and prior migrations read directly; 0-collision claim for WA/AZ/TN/MA verified against the 160-negative-id-audit.csv absence (not just presence)
- TN withholding mechanism (Pitfall #1): MEDIUM-HIGH — the mechanism is derived from direct reading of `electionService.ts`'s actual SQL and is provably correct against the 3 query paths reviewed, but has not been executed/tested in this repo yet (no prior phase needed this exact trick)
- TN severity classification (which districts are "severe"): MEDIUM — qualitative, cross-confirmed news facts about county-level splits; exact per-district severity score is explicitly deferred to the phase's own D-01a audit task, not resolved here
- Pitfalls / Don't-Hand-Roll: HIGH — directly sourced from documented incidents in prior-phase SUMMARYs (Bouchard wrong-person, VA-5/6/9 rotation, 21/25 false-skip epidemic, surname-leak guard)

**Research date:** 2026-07-03
**Valid until:** 30 days for the pipeline/mechanics content (stable, proven across 6+ prior phases); 7 days for the TN redistricting legal-status facts (NAACP lawsuit outcome, exact district composition) given active litigation and the Jul-21 AZ / Aug-4 WA+TN primary calendar pressure — re-verify TN's litigation status immediately before executing the TN slice if more than a few days have passed.
