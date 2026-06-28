# Phase 148: Field Resolution + Stance-Gap Diagnostic - Research

**Researched:** 2026-06-28
**Domain:** Civic-data diagnostics — read-only field enumeration + incumbent/stance mapping for 144 Wave-1 US House districts (CA 52 / TX 38 / FL 28 / NY 26)
**Confidence:** HIGH (every claim below verified against the live production DB `kxsdzaojfaibhuzmclfq` and live source endpoints this session)

## Summary

Phase 148 is a **pure diagnostic / reference-data phase** — no seeding, no code, no migrations. It produces three artifacts the seeding phases (149 CA / 150 TX+NY / 151 FL) consume: (1) a **per-district verified Nov-3 general-ballot field table** for all 144 Wave-1 districts, (2) an **incumbent → `politician_id` + current-stance-count map** so incumbent-nominees reuse their existing record (no duplicates) and thin incumbents are flagged for top-up, and (3) a **lost-incumbent / open-seat flag list** so no district seeds a non-candidate or assumes incumbent=nominee.

Live DB inspection this session **overturned two milestone-research assumptions** and the planner must build on the corrected facts:

1. **"Sitting incumbents are already stanced (v2.15–v2.17)" is FALSE for Wave-1 House.** Live counts: CA has **36 of 52** incumbents at **0 stances** (only 9 at ≥24); TX has **all 37** seated incumbents at **0 stances**; FL averages 14.6 (0 at ≥24, 1 at 23); NY averages 15.8 (1 at 24). Across all 144 districts, the federal-24-topic bar is met by **only ~11 incumbents.** Stance work for incumbents is therefore large, not incidental — Phase 148 must quantify it precisely so 149–151 scope it correctly.
2. **FL's qualified field is NOT downloadable from the FL DoE `extractCanList.asp` endpoint yet.** The Nov-3 general extract returns header-only (243 bytes, 0 candidate rows) and there is **no Aug-18 primary elecid in the download dropdown** — only `20261103-GEN` (empty) + special elections. FL federal qualifying *closed June 12, 2026* (so the field is legally final), but the FL DoE bulk download is not yet the source. Use **Wikipedia (raw-wikitext API) + Ballotpedia (Playwright)** for the FL qualified field instead.

A third correction: the `ingest-ca-sos-2026-challengers.ts` template referenced upstream seeds into the **"2026 LA County Primary"** election (1 House race, CD-34 only) — it is NOT the general-election seed path. The 52 CA House general races live in a **different election: "CA 2026 Statewide General"** (`728d0074-…`), each with **0 race_candidates**. The script is a useful *pattern* (find-race-by-position_name, idempotent upsert) but is not a turnkey general-election seeder.

**Primary recommendation:** Build the field table by joining the live incumbent map (the SQL below) against a per-state field pulled from Wikipedia via the `action=parse` API (never WebFetch — TOC-only) cross-checked with the registered-key FEC `/v1/candidates` per-state call; flag NY-10 (Goldman) and NY-13 (Espaillat) lost-primary plus FL-20 / TX-23 vacancies (both confirmed live as 0-holder offices). Map incumbents to `politician_id` by **`(district_type='NATIONAL_LOWER', geo_id)`** — NEVER by computing an external_id (the scheme is inconsistent across the four states, verified below).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Field enumeration (who's on the Nov-3 ballot) | External sources (Wikipedia/FEC/Ballotpedia) | — | No authoritative copy in our DB; must be fetched + verified per district |
| Incumbent → politician_id mapping | Database / Storage (read-only) | — | `essentials.districts→offices→politicians` already holds all 435 seated reps |
| Stance-gap counting | Database / Storage (read-only) | — | `inform.politician_answers` is the source of truth for current coverage |
| Lost-primary / vacancy detection | External (primary results) + DB (vacancy = 0-holder office) | — | Results live externally; vacancies are visible in the office→politician join |
| Output artifact production | Filesystem (phase dir / backend/data) | — | Reference data consumed by 149–151; not a DB write |

This phase touches **no application tier** — it is read-only DB queries + external fetches + a written reference artifact.

## Standard Stack

This is a diagnostic phase; the "stack" is read-only query tooling + verified external sources. No packages are installed.

### Core Tools

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `pg` (raw driver) via `node --import tsx` | already in repo | Read-only diagnostic queries against prod | Project convention; MCP Supabase tokens expire ~1h (STATE.md) `[VERIFIED: backend/src/lib/db.ts]` |
| Wikipedia `action=parse` API | n/a (HTTP) | Per-district general-ballot field | Bypasses the WebFetch TOC-only wall — returns full wikitext/sections `[VERIFIED: live this session]` |
| FEC OpenFEC `/v1/candidates` | v1 | Authoritative FEC candidate IDs + incumbent/challenger/open flag | Registered key present in `.env` (40 chars, 1000/hr) `[VERIFIED: live, 190 NY filers returned]` |
| Playwright | `playwright` (install if absent) | Render Ballotpedia (blank to WebFetch) + FL SoS SPA | Project's universal fetch-wall workaround `[CITED: .planning/research/STACK.md]` |

### Supporting Sources

| Source | URL pattern | Purpose | When to Use |
|--------|-------------|---------|-------------|
| Wikipedia per-state House page | `en.wikipedia.org/w/api.php?action=parse&page=2026_United_States_House_of_Representatives_elections_in_{State}&prop=wikitext&format=json` | Primary field discovery | All four states; FL too (449 sections incl. "Failed to qualify"/"Presumptive nominee") `[VERIFIED: live]` |
| FEC OpenFEC | `api.open.fec.gov/v1/candidates/?office=H&state={ST}&election_year=2026&api_key={KEY}` | Candidate IDs + `incumbent_challenge_full` | One paginated call per state (NY = 64 pages of 3, or use `per_page=100`); never per-district `[VERIFIED: live]` |
| Ballotpedia per-district | `ballotpedia.org/{State}'s_{N}th_Congressional_District_election,_2026` | Richest single-district detail | When Wikipedia thin; **Playwright only** (WebFetch blank) `[CITED: STACK.md]` |
| NBC/AP NY results | `nbcnews.com/politics/2026-primary-elections/new-york-house-results` | Confirm NY 6/23 nominees + uncalled races | NY only `[CITED: STACK.md]` |
| firstcoastnews / Politics1 | per-state roll-ups | Cross-check FL qualified field + independents | FL/independents `[VERIFIED: firstcoastnews 2026 qualifying article]` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Wikipedia `action=parse` API | WebFetch on the Wikipedia page | WebFetch returns TOC-only on these long pages — yields false "no data" `[VERIFIED: STACK.md + this session]` |
| FEC registered key | `DEMO_KEY` | 10/hr cap stalls a 144-district pull `[CITED: STACK.md]`; key already present so moot |
| Wikipedia for FL | FL DoE `extractCanList.asp` download | **Endpoint is empty / no Aug-18 elecid yet** (verified this session) — not yet usable; revisit for Phase 153 |

**Installation:** None for Phase 148 (read-only). Playwright is only needed if a district's field must be confirmed from Ballotpedia.

## Package Legitimacy Audit

> Not applicable — Phase 148 installs **no external packages**. It runs read-only queries with the in-repo `pg` driver and fetches public HTTP endpoints. `[VERIFIED: phase scope is diagnostic-only per objective + REQUIREMENTS USHC-01]`

## Architecture Patterns

### Data Flow Diagram

```
                  ┌─────────────────────────────────────────────┐
                  │  PER-STATE FIELD (external, must verify)      │
  Wikipedia ──────┤  action=parse API → per-district sections    │
  (raw wikitext)  │  "Nominee" / "Presumptive nominee" /          │
                  │  "Independents" / "Eliminated in primary"     │
  FEC API ────────┤  /v1/candidates → candidate_id +              │──┐
  (registered key)│  incumbent_challenge_full (I/C/Open seat)     │  │
                  │  cross-check: does field match incumbency?    │  │
  NBC/AP/BP ──────┤  confirm NY upsets + CA top-two same-party    │  │
                  └─────────────────────────────────────────────┘  │
                                                                    ▼
  ┌──────────────────────────────────────────┐         ┌────────────────────────────┐
  │  LIVE DB (read-only)                       │         │  JOIN per district:         │
  │  districts(NATIONAL_LOWER, geo_id=SSCC)    │────────▶│  geo_id ↔ field             │
  │   → offices → politicians (incumbent)      │         │  incumbent pid + stance_ct  │
  │   ← inform.politician_answers COUNT        │         │  nominee flag (inc? lost?)  │
  │  (0-holder office = VACANCY)               │         │  new-candidate enumeration  │
  └──────────────────────────────────────────┘         └──────────────┬─────────────┘
                                                                       ▼
                                              ┌──────────────────────────────────────┐
                                              │  OUTPUT ARTIFACT (phase dir)            │
                                              │  148-FIELD-TABLE.md/.csv per district:  │
                                              │   state, cd, geo_id, incumbent,         │
                                              │   incumbent_pid, stance_ct,             │
                                              │   nominee_status, candidates[],         │
                                              │   new_records_needed[], fec_id          │
                                              └──────────────────────────────────────┘
```

### Pattern 1: Map incumbent by (district_type, geo_id), NOT by external_id

**What:** Resolve each district's seated incumbent `politician_id` + stance count by joining `districts→offices→politicians` on `geo_id`, scoped to `NATIONAL_LOWER`.
**When to use:** The core incumbent-mapping query for the diagnostic.
**Why NOT external_id:** The external_id scheme is **inconsistent across the four Wave-1 states** (verified live):

| State | CD-01 external_id | Apparent scheme |
|-------|-------------------|------------------|
| CA (06) | `-6000301` | `-(6000300 + cd)` |
| TX (48) | `-100301` | `-(100300 + cd)` |
| FL (12) | `-12001` | `-(12000 + cd)` |
| NY (36) | `-36010` (CD-10) | `-(36000 + cd)` |

A planner who computes `-(state_fips*1000+cd)` (the scheme noted in the objective) would mis-key CA and TX entirely. Always join on `geo_id`. `[VERIFIED: live DB this session]`

```sql
-- Incumbent → politician_id + current stance count, per Wave-1 district.
-- This is the v2.18 stance-gap diagnostic pattern (STATE.md L226) adapted to NATIONAL_LOWER.
SELECT substr(d.geo_id,1,2)                        AS state_fips,
       d.geo_id,                                   -- SSCC, e.g. '0612' = CA-12
       p.id                                        AS politician_id,
       p.external_id,
       p.full_name,
       p.is_active,
       (SELECT COUNT(*) FROM inform.politician_answers pa
         WHERE pa.politician_id = p.id)            AS stance_count
FROM essentials.districts d
JOIN essentials.offices     o ON o.district_id = d.id
JOIN essentials.politicians p ON p.id = o.politician_id
WHERE d.district_type = 'NATIONAL_LOWER'
  AND substr(d.geo_id,1,2) IN ('06','48','12','36')
ORDER BY state_fips, d.geo_id;
```

Note: `inform.politician_answers` has **no `id` column** — it is keyed `(politician_id, topic_id)`. Use `COUNT(*)`, not `COUNT(pa.id)` (which errors). `[VERIFIED: information_schema this session]`

### Pattern 2: Vacancy = office with NULL `politician_id` (or no office)

**What:** A district with no seated member shows as either 0 offices or an office with `politician_id IS NULL`.
**Verified live:** FL-20 (`geo_id 1220`) has **0 offices / 0 holders**; TX-23 (`geo_id 4823`) has **1 office / 0 holders**. Both match the STATE.md deferred "3 House vacancies (FL-20/GA-13/TX-23)". `[VERIFIED: live DB]`
**When to use:** The diagnostic must enumerate these explicitly as "OPEN — no incumbent record to reuse; all general candidates are new records."

```sql
-- Vacancy detection within Wave-1
SELECT substr(d.geo_id,1,2) fips, d.geo_id,
       COUNT(o.id) office_ct, COUNT(o.politician_id) holder_ct
FROM essentials.districts d
LEFT JOIN essentials.offices o ON o.district_id = d.id
WHERE d.district_type='NATIONAL_LOWER' AND substr(d.geo_id,1,2) IN ('06','48','12','36')
GROUP BY substr(d.geo_id,1,2), d.geo_id
HAVING COUNT(o.politician_id) <> 1;
```

### Pattern 3: Field discovery via Wikipedia `action=parse` (the TOC-wall workaround)

**What:** Fetch the per-district candidate field from the section structure + wikitext, not the rendered HTML.
```bash
# List per-district sections (gives "District N", "Nominee", "Presumptive nominee",
#   "Independents", "Eliminated in primary", "Failed to qualify" anchors):
curl -s "https://en.wikipedia.org/w/api.php?action=parse&page=2026_United_States_House_of_Representatives_elections_in_New_York&prop=sections&format=json"
# Pull a specific district's wikitext by section index (from the sections list):
curl -s "https://en.wikipedia.org/w/api.php?action=parse&page=...&prop=wikitext&section=NN&format=json"
```
NY page returned sections `['District 1','Republican','Nominee','Democratic primary','Nominee',...,'Independents','General election',...]`; FL page returned **449 sections** including `'Failed to qualify'` and `'Presumptive nominee'`. `[VERIFIED: live this session]`

### Pattern 4: FEC per-state candidate pull (one call, paginated)

```bash
KEY=$(awk -F= '/^FEC_API_KEY/{print $2}' backend/.env | tr -d '\r')
curl -s "https://api.open.fec.gov/v1/candidates/?office=H&state=NY&election_year=2026&per_page=100&api_key=${KEY}"
# Each result: name ("LAST, FIRST"), candidate_id (e.g. H6NY13238), district,
#   incumbent_challenge_full ('Incumbent'|'Challenger'|'Open seat'), candidate_status
```
NY returned `count: 190` (64 pages at per_page=3 — use per_page=100 → 2 pages). The `incumbent_challenge_full` field is the FEC's own incumbent/challenger/open classification — useful cross-check but **not authoritative for who won the primary** (a defeated incumbent is still "Incumbent" to FEC). `[VERIFIED: live]`

### Anti-Patterns to Avoid

- **Computing external_id from FIPS×1000+cd** — wrong for CA and TX; join on `geo_id` instead.
- **`COUNT(pa.id)` on `inform.politician_answers`** — no `id` column; query errors.
- **Treating `ingest-ca-sos-2026-challengers.ts` as the general-election seeder** — it targets the LA County *Primary* (CD-34 only). The general races are in "CA 2026 Statewide General".
- **Concluding "FL field unavailable" because the FL DoE download is empty** — the field IS final (qualifying closed 6/12); it's the *download endpoint* that's not populated. Use Wikipedia/Ballotpedia.
- **Deriving the nominee from incumbency** — NY-10/NY-13 incumbents lost (see Pitfalls).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Incumbent identity per district | A name-match against FEC/Wikipedia names | The live `districts→offices→politicians` join on `geo_id` | The DB already holds all 435 seated reps with stable pids; name-match is the v2.4 Andy-Barr dup vector |
| Stance coverage count | Re-deriving from CSVs/scratch | `COUNT(*) FROM inform.politician_answers` per pid | Single source of truth; v2.18 stance-gap pattern |
| Field discovery on long Wikipedia pages | An HTML scraper of the rendered page | `action=parse&prop=sections/wikitext` API | Avoids the TOC-only WebFetch wall; structured by district |
| FEC candidate IDs | Guessing/constructing IDs | `/v1/candidates` per state | FEC IDs are opaque (`H6NY13238`); only the API is authoritative |

**Key insight:** Phase 148's entire value is *not building anything* — it is reconciling the live DB (what we have) against verified external sources (what the ballot is) into one table, so the seeding phases never guess.

## Runtime State Inventory

> Phase 148 is **read-only / diagnostic — it writes no DB state and changes no runtime config.** This section is included because the *output artifact* feeds seeding phases that DO mutate state; the inventory documents what those phases will touch (so 148's table captures it).

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `essentials.race_candidates`: **0 rows** on all 52 CA general House races + **none** for TX/FL/NY (TX/NY/FL have no general House races at all). `inform.politician_answers`: ~11 of 144 incumbents at ≥24 topics. | None in 148 (diagnostic). 148 *records* these gaps for 149–151. |
| Live service config | None — no external service holds Wave-1 House state. The `/elections` feed reads `essentials.races`+`race_candidates` directly. | None. |
| OS-registered state | None. | None — `[VERIFIED: phase is read-only]`. |
| Secrets/env vars | `FEC_API_KEY` present in `backend/.env` (40 chars, registered 1000/hr key). `DATABASE_URL` present. No new secrets needed. | None — reuse existing. |
| Build artifacts | None — no install, no compile. Temp diagnostic scripts must be deleted after use (done this session). | None. |

**Verified explicitly:** no migration, no commit-of-data, no service patch is in Phase 148's scope. Its only filesystem write is the reference artifact under the phase dir.

## Common Pitfalls

### Pitfall 1: Assuming incumbents are already stanced (the milestone's own stale assumption)
**What goes wrong:** REQUIREMENTS.md/STATE.md say "sitting incumbents already stanced (v2.15–v2.17)". **Live data contradicts this.** Per-state stance-gap (verified this session):

| State (FIPS) | Incumbent records | 0 stances | 1–23 stances | ≥24 stances | min / max / avg |
|--------------|-------------------|-----------|--------------|-------------|------------------|
| CA (06) | 52 | **36** | 7 | 9 | 0 / 29 / 7.5 |
| FL (12) | 27 (+1 vacancy) | 0 | **27** | 0 | 6 / 23 / 14.6 |
| NY (36) | 26 | 0 | 25 | 1 | 4 / 24 / 15.8 |
| TX (48) | 37 (+1 vacancy) | **37** | 0 | 0 | 0 / 0 / 0.0 |

So **~133 of 144 incumbents are below the federal-24 bar**, and 73 are at 0. If 149–151 assume incumbents are done, the milestone ships with mostly empty incumbent stance sets.
**How to avoid:** Phase 148's diagnostic MUST emit the exact stance count per incumbent so the seeding phases scope incumbent top-up explicitly. Flag the threshold the milestone wants (full 24 vs "good enough" partial — this is an **open question for the planner/operator**, see Open Questions).
**Warning signs:** A 149–151 plan that only researches challengers.

### Pitfall 2: Lost-incumbent-primary (NY-10 Goldman, NY-13 Espaillat)
**What goes wrong:** Both incumbents are **`is_active=true` in the DB** (Goldman `-36010` 14 stances; Espaillat `-36013` 18 stances — verified live) and would naively map as the 2026 nominee, but both **lost their 6/23 primary** (per milestone research). Surfacing them as the general candidate omits the real nominee.
**How to avoid:** For each NY district, confirm the nominee from Wikipedia "Nominee" section + NBC/AP results — never from the DB incumbent. Phase 148 produces a **`nominee_status` column** with values like `incumbent-renominated` / `incumbent-lost-primary` / `incumbent-retired` / `open-seat-vacancy`. NY-10 and NY-13 must be explicitly flagged `incumbent-lost-primary` with a results citation.
**Also confirm:** NY-7 (Velázquez `-36007`, retired → open), NY-12 (Nadler `-36012`, retired → open) per STACK.md. Both are `is_active=true` holders today; flag as `incumbent-retired`.
**Warning signs:** Any NY district whose field still lists the sitting member after a confirmed loss/retirement.

### Pitfall 3: CA top-two same-party generals (don't assume D-vs-R)
**What goes wrong:** CA is a jungle primary — a district's two June-2 advancers can be D-vs-D or R-vs-R. Assuming one-D-one-R produces a wrong field.
**How to avoid:** For each CA district, read both "advanced to general" entries from Wikipedia/SoS results; the field table lists exactly the two advancers, party-agnostic.
**Warning signs:** A CA district field auto-populated with the incumbent + a single opposite-party challenger.

### Pitfall 4: Vacant districts have no incumbent record to reuse
**What goes wrong:** FL-20 (1220) and TX-23 (4823) have **no seated member** (verified: 0 holders). A diagnostic that assumes every district has an incumbent pid will null-error or mis-map.
**How to avoid:** The vacancy query (Pattern 2) explicitly enumerates these; mark `nominee_status='open-seat-vacancy'`, `incumbent_pid=NULL`. All general candidates there are new records (or a special-election winner if one seats before seeding — re-check).
**Warning signs:** A NULL `incumbent_pid` row treated as an error rather than an open seat.

### Pitfall 5: Wrong election scope for CA races
**What goes wrong:** The 52 CA general House races are in **"CA 2026 Statewide General"** (`728d0074-…`). There is also a "2026 LA County Primary" with **1** House race (CD-34, 6 candidates already seeded) and a "2026 LA County General". A field table that keys CA races to the wrong election will mis-route the seeding.
**How to avoid:** Phase 148 records, per CA district, the target election = "CA 2026 Statewide General" and the existing `races.position_name` (`U.S. Representative District N`, geo_id `06NN`). All 52 have `cand_ct=0`. `[VERIFIED: live]`
**Warning signs:** Referencing "2026 LA County Primary" as the CA general seed target.

## Code Examples

### The complete stance-gap diagnostic (run-ready)
```sql
-- Per-state summary (run first for scoping)
WITH inc AS (
  SELECT substr(d.geo_id,1,2) AS fips, p.id AS pid,
         (SELECT COUNT(*) FROM inform.politician_answers pa WHERE pa.politician_id=p.id) AS sc
  FROM essentials.districts d
  JOIN essentials.offices o ON o.district_id=d.id
  JOIN essentials.politicians p ON p.id=o.politician_id
  WHERE d.district_type='NATIONAL_LOWER' AND substr(d.geo_id,1,2) IN ('06','48','12','36')
  GROUP BY substr(d.geo_id,1,2), p.id
)
SELECT fips, COUNT(*) incumbent_records,
       COUNT(*) FILTER (WHERE sc=0)            AS zero_stance,
       COUNT(*) FILTER (WHERE sc>0 AND sc<24)  AS under24,
       COUNT(*) FILTER (WHERE sc>=24)          AS at_or_above_24,
       MIN(sc) min_sc, MAX(sc) max_sc, ROUND(AVG(sc),1) avg_sc
FROM inc GROUP BY fips ORDER BY fips;
```

### FEC per-state pull (bash, registered key)
```bash
cd /c/EV-Accounts/backend
KEY=$(awk -F= '/^FEC_API_KEY/{print $2}' .env | tr -d '\r')
for ST in CA TX FL NY; do
  curl -s "https://api.open.fec.gov/v1/candidates/?office=H&state=${ST}&election_year=2026&per_page=100&page=1&api_key=${KEY}" \
    > /c/.../scratch/fec_house_${ST}_p1.json
done
# Each result row: name, candidate_id, district, incumbent_challenge_full, candidate_status
```

## State of the Art

| Old Approach (milestone research assumption) | Current Reality (verified live 2026-06-28) | Impact |
|----------------------------------------------|--------------------------------------------|--------|
| "Incumbents already stanced (v2.15–v2.17)" | ~133/144 below 24 topics; 73 at 0 (TX all 0, CA 36 at 0) | Incumbent stance top-up is a major 149–151 workstream, not incidental |
| "FL qualified field downloadable now from FL DoE" | `extractCanList.asp` returns header-only; no Aug-18 elecid in dropdown | FL field must come from Wikipedia/Ballotpedia, not the bulk download |
| "CA 53 House races pre-seeded, turnkey" | 52 general races (in "CA 2026 Statewide General"), all 0 candidates; the `ingest-ca-...` script targets the LA County *Primary* | CA is insert-`race_candidates`-only into the **general** election; the named script is a pattern, not the seeder |
| external_id = `-(fips*1000+cd)` | Scheme differs per state (CA -6000301, TX -100301, FL -12001, NY -36010) | Map by `geo_id`, never compute external_id |

**Deprecated/outdated for this phase:**
- WebFetch on Wikipedia long election pages — TOC-only; use `action=parse` API.
- WebFetch on Ballotpedia — blank; use Playwright.
- FL DoE `downloadcanlist.asp` as the FL field source — empty as of 2026-06-28.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | NY-10 (Goldman) and NY-13 (Espaillat) lost their 6/23 primaries | Pitfall 2 | If wrong, wrong nominee flagged — but this is from milestone research; Phase 148 MUST re-verify from results before locking the table. `[ASSUMED — re-confirm from NBC/AP/Wikipedia in this phase]` |
| A2 | NY-7 (Velázquez) and NY-12 (Nadler) are retiring → open seats | Pitfall 2 | Same — re-confirm from Wikipedia "Nominee"/"open seat" sections. `[ASSUMED]` |
| A3 | FL federal qualifying closed June 12, 2026 (field legally final) | Summary / Stack | If a late ballot-access action changed the field, FL table is stale; the Aug-18 primary still narrows each party. Provisional by design. `[VERIFIED: firstcoastnews + FL DoE qualifying page]` but candidate set itself `[ASSUMED until pulled from Wikipedia]` |
| A4 | TX field is fully decided (March 3 + May 26 runoff past) | Stack (inherited) | If any TX House race is uncalled/contested, that district's field is provisional. `[CITED: STACK.md]` |
| A5 | "Federal 24-topic" is the incumbent stance bar | Pitfall 1 | The operator may accept partial coverage for incumbents rather than full 24; the *threshold* for "needs top-up" is a decision, not a fact. `[ASSUMED — see Open Questions]` |

## Open Questions

1. **What stance threshold flags an incumbent for top-up?**
   - What we know: ~133/144 incumbents are below 24 topics; CA/TX have 73 at zero.
   - What's unclear: Does the milestone require all incumbents brought to the full federal-24 set, or is the existing partial coverage acceptable (top-up only the 0-stance ones)? This dramatically changes 149–151 effort (full-24 for 144 incumbents is a very large stance program).
   - Recommendation: Phase 148 emits the exact count per incumbent and presents three tiers — `zero` (must research), `partial <24` (top-up candidate), `>=24` (done). Let the operator set the bar at plan time. Do NOT silently assume full-24.

2. **Are any NY 6/23 races still uncalled?**
   - What we know: NY primary was 6/23; milestone flags Goldman/Espaillat losses.
   - What's unclear: Close races may remain uncalled as of 6/28.
   - Recommendation: Cross-check NBC + AP per NY district; mark genuinely-uncalled races `nominee_status='uncalled'` rather than guessing.

3. **CA same-party generals — which districts?**
   - What we know: top-two can yield D-vs-D / R-vs-R.
   - What's unclear: exact list of same-party CA generals.
   - Recommendation: enumerate both advancers per CA district from results; the table captures party-on-race for the seeding phases (party never on candidate).

4. **Output artifact format/location.**
   - Recommendation below (Output Artifact section).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Production DB (`DATABASE_URL`) | All diagnostic queries | ✓ | Supabase session pooler | — |
| `FEC_API_KEY` (registered) | FEC candidate-ID pull | ✓ | 40-char key, 1000/hr | DEMO_KEY (10/hr, too slow) |
| Wikipedia `action=parse` API | Field discovery | ✓ | live | Playwright on rendered page |
| `tsx` / `pg` | Running diagnostic scripts | ✓ | in repo | — |
| Playwright | Ballotpedia/SPA render | ✗ (not confirmed installed) | — | Wikipedia API covers most needs; install `playwright` only if a district needs Ballotpedia |
| FL DoE `extractCanList.asp` | FL field (intended) | ✓ endpoint, **✗ data** (header-only) | — | **Wikipedia/Ballotpedia for FL field** (download not yet populated) |

**Missing dependencies with no fallback:** none — Phase 148 can complete fully read-only.
**Missing dependencies with fallback:** Playwright (fallback: Wikipedia API); FL DoE download (fallback: Wikipedia FL page, 449 sections, verified populated).

## Output Artifact (recommendation for the planner)

**Location:** `.planning/phases/148-field-resolution-stance-gap-diagnostic/148-FIELD-TABLE.md` (human-readable, git-tracked since `commit_docs: true`) **plus** a machine-readable companion `148-field-table.csv` in the same dir (the seeding phases parse the CSV; the .md is the reviewable narrative). Do NOT put it under `backend/data/stance-research/...` (that dir is gitignored scratch).

**Recommended columns (CSV):**

| Column | Source | Notes |
|--------|--------|-------|
| `state` | constant | CA/TX/FL/NY |
| `cd` | district number | 1–N |
| `geo_id` | DB | `SSCC` (e.g. `0612`) — the join key |
| `target_election` | DB | CA → "CA 2026 Statewide General"; TX/NY/FL → election to be created in 149–151 |
| `existing_race_id` | DB | non-null for CA (52 races exist); null for TX/FL/NY |
| `incumbent_name` | DB | from offices→politicians (or "VACANT") |
| `incumbent_pid` | DB | the politician UUID to reuse (NULL if vacant) |
| `incumbent_external_id` | DB | for reference/audit |
| `incumbent_stance_count` | `inform.politician_answers` | the gap number |
| `incumbent_top_up_tier` | derived | `zero` / `partial` / `done` |
| `nominee_status` | external + DB | `incumbent-renominated` / `incumbent-lost-primary` / `incumbent-retired` / `open-seat-vacancy` / `uncalled` |
| `general_candidates` | Wikipedia/FEC | list: name + party + (fec_id if found) |
| `new_records_needed` | derived | candidates with no existing `politicians` row (challengers/open-seat) |
| `field_status` | derived | `decided` (CA/TX/NY) / `provisional` (FL pre-Aug-18) |
| `source_url` | citation | the verified field source per district |

This shape lets 149 (CA) read `existing_race_id` + the candidate list and insert `race_candidates`; 150/151 read `target_election` to create races first; all three read `incumbent_pid` to reuse records and `incumbent_top_up_tier` to scope stance work.

## Security Domain

> `security_enforcement` is not set in `.planning/config.json` (treated as enabled). However, Phase 148 is **read-only diagnostic** — it accepts no user input, writes no DB state, and exposes no endpoint. The only data-handling concern is below.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth surface touched |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | minimal | External fetch responses (Wikipedia/FEC) are parsed; treat as untrusted text — do not eval, sanitize before writing into the artifact |
| V6 Cryptography | no | — |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Stale/wrong nominee surfaced (misinformation) | Tampering/Repudiation (data-integrity) | Verify every district's field from a cited source; record `source_url`; flag uncalled/provisional rather than guessing |
| Secret leakage (`FEC_API_KEY`) | Information disclosure | Never echo the key into the artifact or logs; read from `.env` at runtime only |
| Read query mutating prod | Tampering | Phase 148 issues SELECT-only; never `--commit`, never INSERT/UPDATE |

## Project Constraints (from CLAUDE.md)

No `CLAUDE.md` exists at the repo root or in `backend/` (verified — neither file present). Project conventions are instead carried in MEMORY.md / STATE.md and apply:

- **Chairs-not-polarity / no inference / honest-skip** — relevant to how the field table records nominee status (verify, never infer). `[CITED: MEMORY.md]`
- **`pg` raw driver for verification; MCP Supabase tokens expire ~1h** — use `node --import tsx` + `pg`. `[CITED: STATE.md L157]`
- **Bash cwd resets between calls** — `cd /c/EV-Accounts/backend &&` in the same compound command. `[CITED: STATE.md L158]`
- **`_push.ts` does NOT load dotenv** — N/A to 148 (no push), but diagnostic scripts must `import 'dotenv/config'` or use `set -a && source .env`.
- **Production project ref:** `kxsdzaojfaibhuzmclfq`.

## Validation Architecture

> `workflow.nyquist_validation` is not present in `.planning/config.json` (treated as enabled). Phase 148 is diagnostic/data — its "tests" are SQL assertions on the produced table, not a unit-test suite.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | SQL assertions (psql `DO $$ ... RAISE EXCEPTION`) — project's phase-gate convention `[CITED: STATE.md L218]` |
| Config file | none — gate is a standalone `.sql` run via psql/pg |
| Quick run command | `node --import tsx <diagnostic>.ts` (re-runs the counts) |
| Full suite command | the gate `.sql` (if the planner adds a verification sub-step) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| USHC-01 | Field table covers all 144 districts | assertion | row-count check: 52+38+28+26=144 in the CSV | ❌ Wave 0 (artifact is this phase's deliverable) |
| USHC-01 | Every non-vacant district maps to a real `incumbent_pid` | SQL | the incumbent-mapping query returns 142 rows (144 − 2 vacancies) | ✅ (query above) |
| USHC-01 | Lost-primary/retired/vacancy flagged | manual+source | NY-10/NY-13/NY-7/NY-12/FL-20/TX-23 carry non-`renominated` status with citation | ❌ Wave 0 |
| USHC-01 | Stance gap quantified per incumbent | SQL | stance-gap summary returns 4 state rows | ✅ (query above) |

### Sampling Rate
- **Per artifact build:** re-run the incumbent-mapping + stance-gap queries; assert row counts.
- **Phase gate:** the field table has 144 rows, 0 NULL `nominee_status`, every non-vacant row has a non-NULL `incumbent_pid`, every row has a `source_url`.

### Wave 0 Gaps
- [ ] `148-FIELD-TABLE.md` + `148-field-table.csv` — the deliverable artifact (does not exist yet; IS the phase output)
- [ ] Optional `148-verify.sql` — asserts the 144-row / no-NULL-status / pid-present invariants (planner's call; this is a diagnostic phase so a lightweight assertion script suffices)
- [ ] Framework install: none needed

## Sources

### Primary (HIGH confidence)
- Live production DB `kxsdzaojfaibhuzmclfq` (inspected 2026-06-28): incumbent map, stance counts per Wave-1 state, external_id schemes, vacancies (FL-20/TX-23), CA general races (52, 0 candidates) in "CA 2026 Statewide General", `inform.politician_answers` schema (no `id` col), `compass_topic_roles` federal=24
- `backend/scripts/ingest-ca-sos-2026-challengers.ts` — confirmed targets "2026 LA County Primary" (not the general)
- Wikipedia `action=parse` API for NY + FL 2026 House pages (live: sections + wikitext returned, TOC-wall bypassed)
- FEC OpenFEC `/v1/candidates?office=H&state=NY&election_year=2026` (live with registered key: 190 NY filers, `incumbent_challenge_full` field)
- FL DoE `extractCanList.asp` (live: returns `application/tab-separated-values`, header-only for `20261103-GEN`; no Aug-18 elecid in dropdown)
- `.planning/research/{SUMMARY,STACK,ARCHITECTURE,PITFALLS}.md` (milestone research)
- `.planning/REQUIREMENTS.md` (USHC-01), `.planning/STATE.md` (v2.20 methodology, stance-gap pattern)

### Secondary (MEDIUM confidence)
- firstcoastnews 2026 FL qualifying article + FL DoE qualifying page — FL federal qualifying closed June 12, 2026; primary Aug 18, 2026
- MEMORY `project_2026_senate_coverage.md` — Path-A vs race_candidates surfacing, federal-24 insight, re-check pattern

### Tertiary (LOW confidence)
- Milestone-research claims about specific NY upsets (Goldman/Espaillat) and CA top-two same-party generals — flagged in Assumptions Log for in-phase re-verification

## Metadata

**Confidence breakdown:**
- Incumbent mapping + stance gap: HIGH — queried live DB directly
- Field-discovery method (Wikipedia/FEC/FL): HIGH — every endpoint exercised live this session
- Specific nominee outcomes (NY upsets, CA same-party): MEDIUM — inherited from milestone research, must be re-confirmed per district in-phase (Assumptions A1–A2)
- Output artifact shape: HIGH — derived from how 149–151 consume it + existing seed conventions

**Research date:** 2026-06-28
**Valid until:** field data is time-sensitive — NY uncalled races, FL pre-Aug-18 status, and any special-election seating (FL-20/TX-23) can change. Treat field facts as valid ~7 days; re-verify per district at table-build time. DB schema facts valid ~30 days.
