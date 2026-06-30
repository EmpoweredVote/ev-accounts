# Phase 154: Field Resolution + Stance-Gap Diagnostic - Research

**Researched:** 2026-06-30
**Domain:** Congressional field resolution, DB diagnostic queries, SQL gate authoring (Wave-2 analog of Phase 148)
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** MI is date-gated (≥ 2026-08-04). Build the 7 decided states now (100 districts: PA/IL/OH/GA/NC/NJ/VA); a separate date-gated MI phase (≥ 2026-08-04) seeds MI's real nominees.
- **D-01a:** Phase 154 still produces the MI incumbent `politician_id` map + stance-gap (MI incumbents already seeded v2.15–v2.17). Only MI nominee/challenger field is deferred. MI districts appear in the field table tagged `pending-primary (Aug-4)`.
- **D-01b:** Roadmap restructuring applied: Phase 157 = NJ-only (12 districts); Phase 158 gate covers 89 decided-state districts; Phase 159 = date-gated MI+VA (24 districts). (VA folded into 159 after the Aug-4-primary finding below.)
- **D-02:** Report-only stance gap for partial incumbents. No top-up. Only new candidates + zero-stance incumbents get stance research downstream.
- **D-03:** Inclusion bar = every candidate officially ballot-qualified for Nov-3 general. Exclude primary-only also-rans and uncertified write-ins.
- **D-04:** Resolve current officeholder AND 2026 nominee from official/results sources — never from 2024 incumbency. VA-11, NJ-11, GA-13 confirmed per this decision (see Special Seat Resolutions below).
- **D-04a:** Any current member seated by a post-v2.17 special election is a new-record need, not a stale incumbent reuse.

### Claude's Discretion

- Field-resolution source per state (SoS vs Ballotpedia vs Wikipedia/raw-wikitext)
- Diagnostic artifact format/location (CSV layout, query structure)
- Exact `154-verify.sql` assertion set — follow inherited Wave-1 conventions

### Deferred Ideas (OUT OF SCOPE)

- MI nominee seeding (Phase 159, ≥ 2026-08-04)
- Partial-incumbent stance top-up
- Challenger FEC finance (out of scope v2.21)
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| USHC2-01 | Verified Nov-3 general-ballot field for all 113 Wave-2 districts — major-party nominees + ballot-qualified independents/third-party — with every district where incumbent is NOT the 2026 nominee explicitly flagged, and per-state challenger/open-seat stance gap diagnosed against existing incumbent records. | Per-state primary dates verified (all 6 decided-state primaries held by June 30 EXCEPT VA — see critical finding); special seat resolutions sourced from official results (VA-11, NJ-11, GA-13); federal-24 denominator confirmed at 24 topics; incumbent-map query pattern established from diag-148-incumbent-stance-gap.ts. |
</phase_requirements>

---

## Summary

Phase 154 is a read-only diagnostic that mirrors Wave-1's Phase 148 exactly — same query patterns, same artifact set, same verify-SQL shape — applied to the 8 Wave-2 states (PA/IL/OH/GA/NC/MI/NJ/VA = 113 districts). It produces a per-district field table, an incumbent-to-`politician_id` map, a stance-gap summary, and a new-record enumeration. It writes zero production rows.

The most important research finding for the plan is a **critical scope update:** Virginia's 2026 congressional primary is **August 4, 2026** — the same date as Michigan's primary. The ROADMAP listed VA in the "7 decided states," but VA nominees for the full term are not decided by the June 30 build window. This affects Phase 154's scoping of VA from "decided" to "pending-primary (Aug-4)" — the same treatment as MI. The plan must resolve whether VA is treated like MI (date-gated) or whether VA's Nov-3 general-ballot field can be resolved another way. The special election result (Walkinshaw, D, seated Sep 2025) is decided; only the Aug-4 primary nominees for the full-term race are unknown.

The three flagged special cases are confirmed from authoritative sources:
- **VA-11:** James Walkinshaw (D) seated via Sep 9, 2025 special election; incumbent; Aug-4 primary for full term.
- **NJ-11:** Analilia Mejia (D) seated via Apr 16, 2026 special election; won the June 2 NJ primary; faces Hathaway (R) in November — DECIDED.
- **GA-13:** David Scott died April 22, 2026; seat VACANT; Jasmine Clark (D) won the May 19 Democratic primary; faces Jonathan Chavez (R) in November — Nov general field DECIDED. GA-13 special election for the remaining term is July 28, 2026 (not yet held as of June 30).

The federal-24 topic set is confirmed at exactly 24 topics in the live DB. The `_FED24_SCALE.txt` file is the authoritative source. All incumbents for the 8 Wave-2 states were stanced in v2.15–v2.17 (PA/IL in v2.16; OH/GA/NC/MI/NJ/VA in v2.17), so the stance-gap diagnostic is expected to show most incumbents near or at the 24-topic bar.

**Primary recommendation:** The plan should mirror Phase 148 exactly — two plans (Wave 1: DB incumbent map via TypeScript script; Wave 2: field table assembly via Python validator + 154-verify.sql). Adapt `diag-148-incumbent-stance-gap.ts` for the 8 Wave-2 FIPS codes; adapt `diag-148-validate-field-table.py` for 113 rows across 8 states. Use the `149-verify.sql` DO $$ ... RAISE EXCEPTION style (not 148-verify.sql which is simpler/pre-seeding) for `154-verify.sql`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Incumbent-to-politician_id map | Database / Storage | — | Pure SELECT on `essentials.districts + offices + politicians`; no application logic needed |
| Stance-gap diagnostic | Database / Storage | — | COUNT query on `inform.politician_answers`; same pattern as v2.18/v2.20 |
| Vacancy / open-seat detection | Database / Storage | External (official results) | Query C in diag-148: districts with holder_ct != 1; cross-check against official sources for intent |
| Field table authoring (Nov-3 ballot) | External (state results) | — | Pure research artifact assembled from official state SoS results, Wikipedia, and FEC; no DB involvement |
| CSV artifact validation | API / Backend (Node/Python script) | — | `diag-148-validate-field-table.py` style: CSV shape gate before any downstream seeding |
| Write-free SQL gate | Database / Storage | — | DO $$ ... RAISE EXCEPTION pattern; psql -v ON_ERROR_STOP=1 run only after field table is locked |

---

## Critical Finding: Virginia Primary is August 4

**Virginia moved its 2026 primary from June to August.** The Virginia Department of Elections confirmed the primary date is August 4, 2026 — the same date as Michigan. [VERIFIED: Virginia Dept. of Elections official press release + WTKR/NBC4 news reports]

**Implications for the plan:**

| State | Primary Date | Status at June 30 | Nov-3 General Field |
|-------|-------------|-------------------|---------------------|
| PA | May 20, 2026 | DECIDED | Known |
| IL | March 17, 2026 | DECIDED | Known |
| OH | May 12, 2026 | DECIDED | Known |
| GA | May 19, 2026 (primary); July 28 special (remaining term) | DECIDED (Nov general field known) | Known — Clark vs Chavez in GA-13 |
| NC | March 3, 2026 | DECIDED | Known |
| NJ | June 2, 2026 | DECIDED | Known |
| VA | **August 4, 2026** | **NOT DECIDED** | Primary winners unknown |
| MI | August 4, 2026 | NOT DECIDED | Primary winners unknown |

**VA in the 154 field table:** VA districts must be tagged `pending-primary (Aug-4)` — exactly like MI. The VA incumbent `politician_id` map can still be built (incumbents are already in the DB). Phase 157 (NJ+VA seeding) now has a VA date-gate problem. The planner must decide whether to:
- (a) Treat VA like MI: date-gate VA to Phase 159 alongside MI, making Phase 157 NJ-only (12 districts), or
- (b) Keep VA in Phase 157 but author VA races after the Aug-4 primary results, accepting that Phase 157 cannot start until after August 4.

This is a planning decision, not a research decision. The research documents the constraint; the plan must encode the chosen path. Option (a) avoids blocking Phase 157 on Aug 4; option (b) is simpler if Phase 157 can wait.

**The ROADMAP's "7 decided states" claim is incorrect at build time.** CONTEXT.md D-01 originally said "7 decided states (PA/IL/OH/GA/NC/NJ/VA = 100 districts)" but VA is not decided on June 30 (Aug-4 primary). The plan-time field table has **89 decided districts** (PA 17 + IL 17 + OH 15 + GA 14 + NC 14 + NJ 12 = 89) + 13 MI pending + 11 VA pending = 113 total. (Earlier drafts of this file wrote "88" — that is an arithmetic slip; 17+17+15+14+14+12 = 89.)

---

## Special Seat Resolutions (D-04)

### VA-11 (Gerry Connolly → James Walkinshaw)

- Gerry Connolly announced retirement March 2025 due to esophageal cancer; died May 21, 2025. [CITED: Virginia Mercury]
- Special election held September 9, 2025. James Walkinshaw (D, Fairfax County Supervisor) defeated Stewart Whitson (R) by ~50 percentage points (Walkinshaw ~75% vs Whitson ~25%). [CITED: NBC News, Fox 5 DC, WTOP]
- **Walkinshaw is the current seated member.** He is NOT in the DB (v2.17 covered incumbents only through Jan 2025 seating; Walkinshaw was seated post-special election Sep 2025). He is a **new-record need**.
- For the November 3, 2026 full-term race: Walkinshaw is the incumbent running in the Democratic primary August 4; Arthur Purves (R) is the Republican candidate. [CITED: Ballotpedia, Virginia elections 2026 Wikipedia]
- **Nov-3 general field cannot be fully resolved until after Aug 4** (VA primary not yet held). VA-11 is `pending-primary (Aug-4)` in the field table.
- Walkinshaw as the incumbent is enumerated as a **new-record need** (post-v2.17, not in DB). Tag: `special-seated`.

### NJ-11 (Mikie Sherrill → Analilia Mejia)

- Mikie Sherrill won the NJ governorship (Nov 2025); resigned her House seat November 20, 2025. [CITED: Ballotpedia News, New Jersey Monitor]
- Special election held April 16, 2026. Analilia Mejia (D, Center for Popular Democracy) defeated Joe Hathaway (R) in the general special election. Primary was February 5, 2026. [CITED: New Jersey Monitor, CNN]
- **Mejia is the current seated member.** She is NOT in the DB (special election result post-v2.17). She is a **new-record need**. Tag: `special-seated`.
- For the November 3, 2026 full-term race: Mejia (D) won the June 2, 2026 NJ primary; faces Hathaway (R) again in November. [CITED: New Jersey Globe, New Jersey Monitor]
- **NJ-11 Nov-3 general field is DECIDED** (Mejia vs Hathaway). Both are new records (Sherrill's v2.17 record is the old incumbent; neither Mejia nor Hathaway is in the DB).
- NJ-11 is tagged `decided` in the field table. Nominee status for the old incumbent (Sherrill): `vacancy` (resigned). Current incumbent Mejia: `special-seated`.

### GA-13 (David Scott deceased → Jasmine Clark for Nov-3)

- David Scott died April 22, 2026, at age 80. He had served 12 terms. [CITED: AJC, Georgia Recorder]
- **GA-13 is currently VACANT** (no one has been seated yet for the remaining term — the special election for the remaining term is July 28, 2026, not yet held as of June 30). [CITED: Georgia SoS call for special election]
- Jasmine Clark (D, GA State Rep.) won the **May 19 Democratic primary** for the November 2026 full-term seat. She faces Jonathan Chavez (R, Air Force veteran) in the November general. [CITED: CBS Atlanta, 19th News, Ballotpedia]
- **GA-13 Nov-3 general field is DECIDED:** Clark vs Chavez. Both are new records. Nominee status for Scott: `deceased`. GA-13 in the field table: `open-seat-vacancy` (same as FL-20/TX-23 in Phase 148).
- The July 28 special election winner for the remaining term will NOT necessarily be in the Nov-3 general ballot field — the special fills only the remaining days of Scott's term; Clark and Chavez are the Nov-3 nominees regardless. However, if Clark wins the special election she will also be the sitting member when the Nov-3 election occurs. Since the special is July 28 (after the build window), the plan should record GA-13 current holder as VACANT (geo_id holder_ct = 0).
- **No phantom incumbent record.** GA-13 has no living holder to map. It is the Wave-2 equivalent of FL-20/TX-23 in Phase 148.

---

## Standard Stack

### Core (Phase 154 — diagnostic only)

| Asset | Version / Location | Purpose | Why Standard |
|-------|--------------------|---------|--------------|
| `diag-148-incumbent-stance-gap.ts` | `backend/scripts/` | Template TypeScript script for DB queries | Direct template; adapt FIPS codes + district counts |
| `diag-148-validate-field-table.py` | `backend/scripts/` | Template Python CSV shape validator | Direct template; adapt row counts + state list |
| `backend/src/lib/db.js` `pool` | `backend/src/lib/` | DB connection for diagnostic scripts | Canonical diagnostic-query path; resolves node_modules inside `backend/` |
| `149-verify.sql` | `backend/scripts/` | Template for `DO $$ ... RAISE EXCEPTION` gate style | More complete than 148-verify.sql; includes TEMP TABLE diffing pattern |
| `dotenv/config` | Node module | Env loading (DATABASE_URL) | Required for pool.query to reach prod DB |
| `tsx` | Node module | TypeScript execution for .ts scripts | Established pattern: `node --import tsx scripts/diag-148-*.ts` |

### Supporting (field-resolution research tools)

| Tool | Purpose | Fetch-wall Status |
|------|---------|-------------------|
| Wikipedia US House elections pages per state | Primary field-resolution source (raw-wikitext for long pages) | WebFetch returns TOC-only on long pages → use raw-wikitext via `?action=raw` |
| Ballotpedia per-district election pages | Secondary field-resolution source | Cloudflare-blocked to WebFetch → Playwright required |
| State SoS / Board of Elections results | Authoritative primary-results source | Varies by state; most reachable |
| FEC API (`api.data.gov`) | Candidate registration cross-check | Requires free API key; 1000/hr rate limit |

---

## Package Legitimacy Audit

> Phase 154 installs NO new packages. All tooling (`tsx`, `dotenv`, `pg`) is already installed in `backend/node_modules`. No new npm installs are required.

**Packages removed due to slopcheck:** none (no new packages)
**Packages flagged as suspicious:** none

---

## Architecture Patterns

### System Architecture Diagram

```
Phase 154 data flow (READ-ONLY):

Live Postgres DB (kxsdzaojfaibhuzmclfq)
  |
  ├── Query A: districts JOIN offices JOIN politicians (8 FIPS codes)
  |     → per-district incumbent name + politician_id + external_id + stance_count
  |
  ├── Query B: per-state stance-gap summary (zero / partial / done counts)
  |
  └── Query C: districts with holder_ct != 1 (vacancies / anomalies)
              → GA-13 expected 0-holder (VACANT); others expected 1-holder
              |
              v
        154-incumbent-map.csv  ← write to .planning/phases/154-.../
        (113 rows: 89 decided + 24 pending-primary [MI 13 + VA 11])

External sources (web research, plan-time artifact assembly):
  State SoS results + Wikipedia + Ballotpedia (via Playwright)
  → per-district nominee resolution
  → incumbent-not-nominee flags
  → new-record enumeration
              |
              v
        154-field-table.csv  ←  assembled in Wave 2
        (113 rows; columns match 148-field-table.csv schema)
              |
              v
        diag-154-validate-field-table.py  ← validates CSV shape
              |
              v
        154-verify.sql  ← write-free gate (DO $$ ... RAISE EXCEPTION)
        run: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/154-verify.sql
```

### Recommended Project Structure

```
backend/scripts/
├── diag-154-incumbent-stance-gap.ts    # Wave 1 (adapt from diag-148-incumbent-stance-gap.ts)
├── diag-154-validate-field-table.py    # Wave 2 (adapt from diag-148-validate-field-table.py)
└── 154-verify.sql                      # Wave 2 (adapt from 149-verify.sql style)

.planning/phases/154-field-resolution-stance-gap-diagnostic/
├── 154-incumbent-map.csv               # output of diag-154-incumbent-stance-gap.ts (Wave 1)
├── 154-field-table.csv                 # assembled in Wave 2
└── 154-FIELD-TABLE.md                  # human-readable summary (optional)
```

### Pattern 1: Incumbent Map Query (from diag-148-incumbent-stance-gap.ts)

```typescript
// Source: backend/scripts/diag-148-incumbent-stance-gap.ts (Query A)
// Adapt: WAVE2_FIPS replaces WAVE1_FIPS; EXPECTED_PER_STATE updates per state
const WAVE2_FIPS = ['42', '17', '39', '13', '37', '26', '34', '51'] as const;
// PA=42, IL=17, OH=39, GA=13, NC=37, MI=26, NJ=34, VA=51

const queryA = await pool.query(
  `SELECT substr(d.geo_id, 1, 2)                       AS state_fips,
          d.geo_id                                     AS geo_id,
          p.id                                         AS politician_id,
          p.external_id                                AS external_id,
          p.full_name                                  AS full_name,
          p.is_active                                  AS is_active,
          (SELECT COUNT(*) FROM inform.politician_answers pa
            WHERE pa.politician_id = p.id)::int        AS stance_count
   FROM essentials.districts   d
   JOIN essentials.offices     o ON o.district_id = d.id
   JOIN essentials.politicians p ON p.id = o.politician_id
   WHERE d.district_type = 'NATIONAL_LOWER'
     AND substr(d.geo_id, 1, 2) = ANY($1::text[])
   ORDER BY state_fips, d.geo_id`,
  [WAVE2_FIPS],
);
// Key constraint: map by (district_type, geo_id) ONLY — never computed external_id
// inform.politician_answers has NO id column -> COUNT(*), never COUNT(pa.id)
```

### Pattern 2: Vacancy Detection Query (from diag-148-incumbent-stance-gap.ts)

```typescript
// Source: backend/scripts/diag-148-incumbent-stance-gap.ts (Query C)
// Wave-2 known vacancies: GA-13 geo_id '1313' (David Scott deceased, special not yet held)
// NJ-11 geo_id '3411' (Sherrill resigned → Mejia special-seated; but Mejia IS in the DB?
//   → No: Mejia was seated post-v2.17, not in DB → holder_ct = 0 expected)
// VA-11 geo_id '5111' (Walkinshaw seated post-v2.17, not in DB → holder_ct = 0 expected)
const queryC = await pool.query(
  `SELECT substr(d.geo_id, 1, 2)      AS fips,
          d.geo_id                    AS geo_id,
          COUNT(o.id)                 AS office_ct,
          COUNT(o.politician_id)      AS holder_ct
   FROM essentials.districts d
   LEFT JOIN essentials.offices o ON o.district_id = d.id
   WHERE d.district_type = 'NATIONAL_LOWER'
     AND substr(d.geo_id, 1, 2) = ANY($1::text[])
   GROUP BY substr(d.geo_id, 1, 2), d.geo_id
   HAVING COUNT(o.politician_id) <> 1
   ORDER BY d.geo_id`,
  [WAVE2_FIPS],
);
// Expected: GA-13, NJ-11, VA-11 appear as 0-holder (all three incumbents post-v2.17)
// Also check: GA-14 (Clay Fuller, R, won special for MTG's seat Apr 7, 2026 → also post-v2.17)
```

### Pattern 3: 154-verify.sql Gate Shape (from 149-verify.sql)

```sql
-- Source: backend/scripts/149-verify.sql (DO $$ style with TEMP TABLE diffing)
-- 154-verify.sql is a PRE-SEEDING gate — asserts the DB baseline before any Wave-2
-- seeding, not post-seeding. It mirrors 148-verify.sql, not 149-verify.sql's
-- post-seeding assertions. Key assertions for Phase 154:
--   1. All 8 Wave-2 states have the expected NATIONAL_LOWER district count
--      (PA 17 + IL 17 + OH 15 + GA 14 + NC 14 + MI 13 + NJ 12 + VA 11 = 113).
--   2. Each district with a living seated incumbent has exactly 1 holder
--      (i.e., all districts EXCEPT the 0-holder vacancies: GA-13, NJ-11, VA-11,
--       and possibly GA-14 if Fuller is post-v2.17).
--   3. 0 pre-existing 2026-11-03 elections for the 8 states (baseline: no races seeded yet)
--   4. The stance-gap tier distribution is reasonable (not a hard assertion, but a NOTICE)

\set ON_ERROR_STOP on
DO $$
DECLARE
  v_total  int;
  v_pa     int; v_il int; v_oh int; v_ga int; v_nc int;
  v_mi     int; v_nj int; v_va int;
  v_vacancies int;
  v_races_2026 int;
BEGIN
  -- District count assertions (prod-verified at plan time from live DB)
  SELECT COUNT(DISTINCT d.geo_id) FILTER (WHERE substr(d.geo_id,1,2)='42') INTO v_pa FROM ...;
  -- ... repeat per state ...
  IF v_pa <> 17 THEN RAISE EXCEPTION 'FAIL: PA expected 17 districts, got %', v_pa; END IF;
  RAISE NOTICE 'PASS: all 8 Wave-2 states have correct NATIONAL_LOWER district counts';

  -- Pre-seeding baseline: 0 active 2026-11-03 races for any Wave-2 state
  SELECT COUNT(*) INTO v_races_2026 FROM essentials.races r
    JOIN essentials.elections el ON el.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
  WHERE el.election_date = '2026-11-03'
    AND d.district_type = 'NATIONAL_LOWER'
    AND substr(d.geo_id,1,2) IN ('42','17','39','13','37','26','34','51');
  IF v_races_2026 <> 0 THEN
    RAISE EXCEPTION 'FAIL: expected 0 pre-seeded 2026 races for Wave-2 states, got %', v_races_2026;
  END IF;
  RAISE NOTICE 'PASS: no pre-seeded 2026-11-03 races for Wave-2 states (baseline confirmed)';

  RAISE NOTICE 'ALL ASSERTIONS PASSED';
END $$;
```

### Pattern 4: field-table.csv Schema (from 148-field-table.csv)

The 154-field-table.csv uses the same 15-column schema as 148-field-table.csv:

```
state, cd, geo_id, target_election, existing_race_id, incumbent_name,
incumbent_pid, incumbent_external_id, incumbent_stance_count,
incumbent_top_up_tier, nominee_status, general_candidates,
new_records_needed, field_status, source_url
```

Key adaptations from Phase 148:
- `target_election`: e.g., "PA 2026 Statewide General" (none pre-exist; all will be created in Phase 155/156/157)
- `existing_race_id`: BLANK for all 113 rows (no pre-seeded 2026 races — unlike CA in Phase 148)
- `field_status`: `decided` for 88 rows (PA/IL/OH/GA/NC/NJ); `pending-primary (Aug-4)` for MI (13) and VA (11)
- `nominee_status` taxonomy: `renominated` / `retired` / `lost-primary` / `vacancy` / `deceased` / `special-seated` / `open-seat-vacancy` — same 7-value set from Phase 148

**Rows requiring special nominee_status values:**
- GA-13: `open-seat-vacancy` (Scott deceased; Jasmine Clark is the D nominee but for a VACANT seat)
- NJ-11: incumbent row uses `vacancy` (Sherrill resigned); Mejia is `special-seated` (current holder, new-record need)
- VA-11: `special-seated` (Walkinshaw, new-record need, seated Sep 2025) — but field_status = `pending-primary (Aug-4)`
- GA-14 (Clay Fuller, R): MUST CHECK whether Fuller was seeded in v2.15–v2.17. Fuller won the Apr 7, 2026 special for MTG's seat (GA-14). MTG's record exists from v2.17 but Fuller likely does not. If holder_ct = 0 for GA-14, it is another 0-holder vacancy (special won but likely not yet seeded). **Plan must run Query C and check live.**

### Anti-Patterns to Avoid

- **Using computed external_id for incumbent lookup.** The `-(fips*1000+cd)` formula mis-keys incumbents in CA and TX (and potentially others). Always join by `(district_type='NATIONAL_LOWER', geo_id)`. [Source: CONTEXT.md code_context, Phase 148 verified]
- **Assuming 2024 incumbency = 2026 nominee.** PA/IL/OH/GA/NC all held primaries; some incumbents lost. Never derive nominees from incumbency.
- **Treating VA as a "decided state."** VA's primary is August 4, same as MI. VA must be tagged `pending-primary (Aug-4)` in the field table.
- **Assuming GA-13's special election result (July 28) determines the Nov-3 ballot.** The special election fills only the remaining days of Scott's term. The Nov-3 ballot is Jasmine Clark vs Jonathan Chavez regardless of who wins the special.
- **Counting `inform.politician_answers.id` column.** This column does not exist; use `COUNT(*)` not `COUNT(pa.id)`. [Source: diag-148-incumbent-stance-gap.ts comment]
- **Running scripts outside `backend/`.** Must `cd /c/EV-Accounts/backend` first to resolve node_modules. CWD resets between Bash calls — always use `cd && node --import tsx` in a single compound command.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CSV shape validation | Custom validator | Adapt `diag-148-validate-field-table.py` | Already handles row count, field presence, UUID-shape checks, per-state counts |
| Incumbent-map DB query | New query | Adapt `diag-148-incumbent-stance-gap.ts` Queries A/B/C | Proven patterns including the holder_ct vacancy detection and `COUNT(*)` (not `COUNT(pa.id)`) |
| SQL gate assertion style | Custom psql | Adapt `149-verify.sql` DO $$ ... RAISE EXCEPTION | The canonical gate style with TEMP TABLEs, RAISE NOTICE per assertion, `\set ON_ERROR_STOP on` |

---

## Per-State Primary Status and Field-Resolution Source Recommendations

| State | Primary Date | Status (June 30) | Recommended Field Source | Known Fetch-Wall |
|-------|-------------|-------------------|--------------------------|------------------|
| PA | May 20, 2026 | DECIDED [CITED: NCSL, FEC] | Wikipedia PA 2026 House elections page (raw-wikitext) | Long pages → raw-wikitext via `?action=raw` |
| IL | March 17, 2026 | DECIDED [CITED: NBC News primary results] | Wikipedia IL 2026 House elections page (raw-wikitext) | Same |
| OH | May 12, 2026 | DECIDED [CITED: NCSL] | Wikipedia OH 2026 House elections page (raw-wikitext) | Same |
| GA | May 19, 2026 (primary) | DECIDED (Nov-3 field known) [CITED: CBS Atlanta] | Wikipedia GA 2026 House elections page + GA SoS for GA-13 special | GA SoS reachable |
| NC | March 3, 2026 | DECIDED [CITED: NBC News primary results] | Wikipedia NC 2026 House elections page (raw-wikitext) | Same |
| NJ | June 2, 2026 | DECIDED [CITED: WHYY, NPR results] | Wikipedia NJ 2026 House elections page + NJ SoS | NJ SoS generally reachable |
| VA | **August 4, 2026** | **NOT DECIDED** [CITED: VA Dept. of Elections] | VA Dept. of Elections candidate list (for declared candidates only) | Partially reachable |
| MI | August 4, 2026 | NOT DECIDED [CITED: CONTEXT.md D-01] | Michigan SoS / declared field only | Partially reachable |

**Fetch-wall notes:**
- Ballotpedia: Cloudflare-blocked to WebFetch. Playwright required for per-district pages. [ASSUMED from v2.20 methodology]
- Wikipedia long pages: WebFetch returns TOC-only. Use raw-wikitext API: `https://en.wikipedia.org/wiki/PAGENAME?action=raw` [VERIFIED: v2.20 established pattern]
- State SoS results pages: variable; most return usable content. GA SoS, NJ SoS, PA SoS reachable without Playwright. [ASSUMED from general experience]
- FEC API (`api.data.gov`): requires free key registration; 1000/hr rate limit. One paginated per-state call suffices. [CITED: v2.20 ROADMAP methodology]

---

## Federal-24 Denominator Confirmation

**Confirmed 24 topics in live DB (`kxsdzaojfaibhuzmclfq`):**

```
abortion, ai-regulation, campaign-finance, childcare, civil-rights,
climate-change, deportation, fossil-fuels, healthcare, homelessness,
housing, immigration, medicare/aid, misinformation, redistricting,
religious-freedom, same-sex-marriage, school-vouchers, social-security,
tariffs, taxes, trans-athletes, ukraine-support, voting-rights
```

**Source file:** `backend/data/stance-research/_FED24_SCALE.txt` (24 topics with full 1–5 scale texts) — authoritative for downstream seeding phases. `_TOPIC_SCALE_FULL.txt` does not exist; `_FED24_SCALE.txt` is the correct filename. [VERIFIED: file confirmed present at correct path]

The `FEDERAL_TOPIC_BAR = 24` constant from `diag-148-incumbent-stance-gap.ts` carries forward unchanged.

---

## Incumbent Coverage Baseline (Expected)

All 8 Wave-2 states had their incumbent US House reps stanced in v2.15–v2.17:
- PA, IL incumbents: v2.16 (Phases 127–130)
- OH, GA, NC, MI, NJ, VA incumbents: v2.17 (Phases 132–134, etc.)

The `topUpTier` function from the diag-148 script will classify most incumbents as `done` (stance_count ≥ 24). The stance-gap diagnostic report is expected to show very few `zero` or `partial` tier incumbents — mostly `done`. The Phase 154 diagnostic only **reports** this (per D-02); no top-up occurs.

**Expected vacancy / 0-holder districts (Query C will confirm):**
- GA-13 (geo_id `1313`): David Scott deceased; special election July 28 (not yet held) → 0-holder
- NJ-11 (geo_id `3411`): Sherrill resigned; Mejia special-seated but not in DB → 0-holder
- VA-11 (geo_id `5111`): Walkinshaw special-seated but not in DB → 0-holder
- GA-14 (geo_id `1314`): Clay Fuller won special Apr 7, 2026 (post-v2.17) → likely 0-holder (plan must verify)

All four of the above are **new-record needs** for the seeding phases (D-04a).

---

## Common Pitfalls

### Pitfall 1: VA Treated as a Decided State
**What goes wrong:** Plan assumes VA's Nov-3 general-ballot field is known and tags VA rows as `decided`; the field table is then wrong because VA nominees aren't determined until Aug 4.
**Why it happens:** The ROADMAP listed "7 decided states (PA/IL/OH/GA/NC/NJ/VA)" but Virginia moved its primary to Aug 4 after the roadmap was written.
**How to avoid:** Tag VA (11 districts) as `pending-primary (Aug-4)` in the field table, same as MI (13 districts). The 154-verify.sql gate does NOT assert VA has a decided field.
**Warning signs:** Any plan task that says "resolve the VA nominee" before August 4 is wrong.

### Pitfall 2: GA-13 Special Election Winner ≠ Nov-3 Nominee
**What goes wrong:** Planner waits for the July 28 GA-13 special to identify who to wire as the GA-13 nominee in the seeding phase.
**Why it happens:** Special elections and regular elections are distinct. The special fills only the remaining days of Scott's 118th Congress term; the Nov-3 election is a new full term.
**How to avoid:** Treat the Nov-3 GA-13 field as DECIDED: Jasmine Clark (D) vs Jonathan Chavez (R). The special election winner is immaterial to the Phase 156 seeding — Clark and Chavez are the candidates regardless. GA-13 is tagged `open-seat-vacancy` in the field table (no living seated incumbent; the special winner, even if Clark, was seated post-Phase-154-build).
**Warning signs:** Any plan that blocks Phase 156 (GA seeding) on the July 28 special election result is wrong.

### Pitfall 3: Counting `politician_answers.id`
**What goes wrong:** `SELECT COUNT(pa.id)` in the stance-gap query → PostgreSQL error because `inform.politician_answers` has no `id` column.
**Why it happens:** Assumption that all tables have an id column.
**How to avoid:** Always `SELECT COUNT(*) FROM inform.politician_answers pa WHERE pa.politician_id = p.id`. This is explicit in `diag-148-incumbent-stance-gap.ts` with a comment.
**Warning signs:** `column pa.id does not exist` error at runtime.

### Pitfall 4: Running Scripts Outside `backend/`
**What goes wrong:** `node --import tsx scripts/diag-154-*.ts` fails with `Cannot find module 'dotenv/config'` or `Cannot find module '../src/lib/db.js'`.
**Why it happens:** node_modules lives inside `backend/`; relative import paths assume cwd is `backend/`.
**How to avoid:** Always `cd /c/EV-Accounts/backend && node --import tsx scripts/diag-154-incumbent-stance-gap.ts`. Since Bash tool resets cwd between calls, use a compound command: `cd /c/EV-Accounts/backend && set -a && source .env && set +a && node --import tsx scripts/diag-154-incumbent-stance-gap.ts`.
**Warning signs:** Module resolution errors.

### Pitfall 5: NJ-11 Ghost Incumbent (Sherrill's Record)
**What goes wrong:** Seeding phase looks up NJ-11 incumbent by `(NATIONAL_LOWER, geo_id '3411')` and finds Mikie Sherrill's existing record; wires Sherrill as the incumbent-nominee for the 2026 race, even though she resigned and is now NJ governor.
**Why it happens:** Sherrill is likely still in the DB with an office row on NJ-11 (seeded in v2.17). Query A will return her as the "incumbent" because her office row exists.
**How to avoid:** The field table must flag NJ-11 with `nominee_status = vacancy` for the Sherrill record, and enumerate Mejia (D, `special-seated`) and Hathaway (R) as the Nov-3 candidates. The seeding phase must NOT wire Sherrill as an active candidate. The 154 diagnostic must explicitly call out that Sherrill's office row will appear in Query A but she is not the 2026 nominee.
**Warning signs:** Any seeding task that uses the Query-A result to directly assign incumbent-nominee status without cross-checking the field table.

### Pitfall 6: GA-14 Fuller Omission
**What goes wrong:** Clay Fuller (R) won the GA-14 special election April 7, 2026, replacing MTG. If the plan doesn't check for Fuller, GA-14 appears to have MTG as the incumbent (from v2.17 seeding), but MTG is no longer the seated member. Fuller is likely not in the DB → 0-holder for GA-14.
**Why it happens:** Phase 154 research scope focuses on the primary three vacancies (GA-13/NJ-11/VA-11) and misses the fourth.
**How to avoid:** Run Query C and inspect ALL districts with holder_ct ≠ 1 — not just the pre-identified three. GA-14 may appear as a 0-holder or as a "MTG is incumbent" anomaly. Fuller must be enumerated as a new-record need if he's not in the DB.
**Warning signs:** Query C returns more than the 3 expected 0-holder districts.

---

## Validation Architecture

> `workflow.nyquist_validation` is absent from `.planning/config.json` → treated as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | psql (-v ON_ERROR_STOP=1) for SQL gate; python3 for CSV validator; node --import tsx for DB scripts |
| Config file | none — scripts are standalone |
| Quick run command | `cd /c/EV-Accounts/backend && set -a && source .env && set +a && node --import tsx scripts/diag-154-incumbent-stance-gap.ts` |
| Full suite command | `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/154-verify.sql` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| USHC2-01 (Part A) | 113-district incumbent map produced | integration | `node --import tsx scripts/diag-154-incumbent-stance-gap.ts` (exits 0 if all 113 rows written) | ❌ Wave 0 |
| USHC2-01 (Part B) | field-table.csv shape-valid | integration | `python3 scripts/diag-154-validate-field-table.py` (exits 0 = PASS) | ❌ Wave 0 |
| USHC2-01 (Part C) | DB baseline pre-seeding assertions pass | integration | `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/154-verify.sql` | ❌ Wave 0 |

### Sampling Rate

- **Per-task commit:** Run the relevant diagnostic script to verify output is well-formed (exits 0)
- **Per-wave merge:** Run all three test commands above
- **Phase gate:** All three must pass before `/gsd:verify-work` on Phase 154

### Wave 0 Gaps

- [ ] `backend/scripts/diag-154-incumbent-stance-gap.ts` — USHC2-01 Part A (adapt from diag-148)
- [ ] `backend/scripts/diag-154-validate-field-table.py` — USHC2-01 Part B (adapt from diag-148)
- [ ] `backend/scripts/154-verify.sql` — USHC2-01 Part C (new, DO $$ style)
- [ ] `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-incumbent-map.csv` — output artifact
- [ ] `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-field-table.csv` — output artifact

---

## Security Domain

> This phase is purely read-only diagnostic against a production database using existing credentials. No new API surface, no user input, no network endpoints. ASVS categories are not applicable.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | no | No user-controlled input in diagnostic scripts |
| V6 Cryptography | no | No cryptographic operations |
| V2-V4 Auth/Session/Access | no | DB connection uses existing `DATABASE_URL` (service role); no new auth surface |

---

## Open Questions (RESOLVED)

1. **Clay Fuller (GA-14) — in DB or not?**
   - What we know: Fuller won the GA-14 special election April 7, 2026, replacing MTG. MTG exists in the DB (v2.17). Fuller was seated post-v2.17.
   - What's unclear: Whether Fuller was added to the DB in any quick-task or subsequent phase between v2.17 and now.
   - Recommendation: Run Query C (`holder_ct <> 1` check for GA-14) at plan time. If holder_ct = 0, Fuller is a new-record need enumerated in Phase 154. If holder_ct = 1 and the holder is Fuller, he maps correctly. If holder_ct = 1 and the holder is MTG, Phase 154 must flag this as a stale-incumbent anomaly.

2. **VA nominees — partial field or fully deferred?**
   - What we know: VA primary is Aug 4. Several districts have only Republican primaries (uncontested Democrats) or only Democratic primaries. Some VA Nov-3 general candidates may already be determinable even before Aug 4 (where one party has no primary).
   - What's unclear: Whether the plan should attempt to partially resolve VA districts where nominees are already locked (e.g., uncontested primary districts) vs. treating all 11 VA districts as uniformly `pending-primary (Aug-4)`.
   - Recommendation: Tag all 11 VA districts `pending-primary (Aug-4)` uniformly. This is cleaner and safer than attempting partial resolution — partial resolution risks introducing incorrect nominees for contested districts, and Phase 159 will do the full resolution anyway. The plan should note this as the simpler conservative path.

3. **NJ-11 Sherrill office row — does it cause a false positive in Query A?**
   - What we know: Sherrill was seeded in v2.17 with an office row for NJ-11. She resigned Nov 2025. The office row likely still exists with `politician_id = Sherrill's pid`.
   - What's unclear: Whether the office row was cleaned up (unlikely — no such cleanup has been documented), so Query A likely returns Sherrill as the NJ-11 "incumbent."
   - Recommendation: The diagnostic must explicitly flag NJ-11 as "Query A returns Sherrill (old incumbent); actual current holder is Mejia (not in DB)." The field table overrides Query A with the D-04 verified resolution. The seeding phase must not use the Query A result for NJ-11 without checking the field table.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | GA-14 Clay Fuller is NOT in the DB (post-v2.17 special) | Pitfall 6 + Expected vacancies | If Fuller IS in the DB, GA-14 shows as 1-holder and is handled correctly; no harm, no new-record need |
| A2 | Ballotpedia returns blank to WebFetch due to Cloudflare | Per-state source recommendations | If reachable, Playwright not needed for per-district Ballotpedia pages; simpler research |
| A3 | NJ-11 Sherrill office row is still in DB (not cleaned up) | Open Question 3 | If cleaned up, Query A returns 0-holder for NJ-11 correctly without special handling |
| A4 | All OH/GA/NC/MI/NJ/VA reps were fully stanced in v2.17 at 24+ topics | Incumbent Coverage Baseline | If some incumbents were partially stanced, the diagnostic may surface more `partial` tier entries; D-02 says report-only so no seeding impact |
| A5 | `_TOPIC_SCALE_FULL.txt` does not exist (only `_FED24_SCALE.txt`) | Federal-24 denominator | CONTEXT.md references `_TOPIC_SCALE_FULL.txt`; verified at the actual file path — `_FED24_SCALE.txt` is the correct filename |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| node + tsx | diag-154-*.ts scripts | ✓ | (existing in backend/) | — |
| python3 | diag-154-validate-field-table.py | ✓ | (existing on machine) | — |
| psql | 154-verify.sql gate | ✓ | (existing; used in v2.20) | — |
| DATABASE_URL (.env) | All DB scripts | ✓ | (kxsdzaojfaibhuzmclfq) | — |
| Playwright | Ballotpedia field resolution | ✓ | (established in v2.20) | Wikipedia raw-wikitext |
| FEC API key | Candidate cross-check | ✓ | (established in v2.20) | Skip FEC cross-check if key expired |

**Missing dependencies with no fallback:** None.

---

## Sources

### Primary (HIGH confidence)
- `backend/scripts/diag-148-incumbent-stance-gap.ts` — Query A/B/C patterns, FIPS constants, CSV output format, `topUpTier` classification, holder_ct vacancy detection [VERIFIED: read directly]
- `backend/scripts/diag-148-validate-field-table.py` — field-table CSV schema (15 columns), per-state row count validation, UUID-shape assertion [VERIFIED: read directly]
- `backend/scripts/149-verify.sql` — DO $$ ... RAISE EXCEPTION style, TEMP TABLE diffing, USHC assertion naming, `\set ON_ERROR_STOP on` [VERIFIED: read directly]
- `.planning/phases/148-field-resolution-stance-gap-diagnostic/148-field-table.csv` — field-table column layout and values; nominee_status taxonomy examples [VERIFIED: read directly]
- `backend/data/stance-research/_FED24_SCALE.txt` — 24 federal topics confirmed (abortion through voting-rights) [VERIFIED: read directly]
- Live DB query: `inform.compass_topics WHERE topic_key IN (24 keys)` → COUNT = 24 [VERIFIED: executed via `node --import tsx`]

### Secondary (MEDIUM confidence)
- [Virginia Dept. of Elections press release](https://www.elections.virginia.gov/news-releases/primary-election-moved-to-august-4-1.html) — VA primary moved to August 4 [CITED]
- [Virginia Mercury, Sep 9 2025](https://virginiamercury.com/2025/09/09/democrats-retake-connollys-seat-in-virginias-11th-congressional-district-special-election/) — Walkinshaw won VA-11 special election [CITED]
- [New Jersey Monitor, Apr 16 2026](https://newjerseymonitor.com/2026/04/16/analilia-mejia-special-house-election/) — Mejia won NJ-11 special election [CITED]
- [New Jersey Globe](https://newjerseyglobe.com/congress/mejia-convincingly-wins-democratic-primary-for-first-full-term/) — Mejia won June 2 NJ primary [CITED]
- [CBS Atlanta](https://www.cbsnews.com/atlanta/news/georgia-13th-congressional-district-primary/) — Jasmine Clark won GA-13 Democratic primary May 19 [CITED]
- [Georgia SoS call for special election](https://sos.ga.gov/news/call-special-election-congressional-district-13) — GA-13 special election July 28, 2026 [CITED]
- [19th News](https://19thnews.org/2026/05/georgia-primary-election-jasmine-clark-congress/) — Clark faces Chavez in November general [CITED]
- [Ballotpedia VA-11 2026](https://ballotpedia.org/Virginia's_11th_Congressional_District_election,_2026) — Walkinshaw incumbent, Aug 4 primary [CITED]

### Tertiary (LOW confidence)
- WebSearch results for NJ/PA/IL/OH/NC/GA primary dates — cross-referenced against NCSL and FEC; consistent across multiple sources [MEDIUM confidence after cross-check]
- Arthur Purves as VA-11 Republican opponent — from single WebSearch result; confirm at plan time [ASSUMED: LOW confidence, needs verification]

---

## Metadata

**Confidence breakdown:**
- Per-state primary dates: HIGH (PA/IL/OH/NC/NJ all multiple confirming sources; VA confirmed by official DOE; GA primary May 19 confirmed by multiple sources)
- Special seat resolutions (VA-11/NJ-11/GA-13): HIGH (each confirmed by 2+ named news sources with URLs)
- Federal-24 denominator: HIGH (verified against live DB via tsx)
- Template script patterns (Queries A/B/C, verify SQL): HIGH (read directly from source files)
- GA-14 Fuller status in DB: LOW (assumed not present; plan must verify via Query C)
- Ballotpedia fetch-wall: MEDIUM (inherited from v2.20; assumed unchanged)

**Research date:** 2026-06-30
**Valid until:** 2026-08-03 (VA + MI primaries Aug 4 change the field table scope; re-research VA nominees after that date for Phase 157/159)
