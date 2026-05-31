---
name: research-utah-elections
description: "Research and ingest Utah primary-election candidates into Empowered Vote elections. Auto-researches the official Utah candidate filing list + county clerk sources, produces a reviewable CSV, then generates an idempotent seed script for essentials.elections/races/race_candidates. Links incumbents to existing politicians and can chain compass-stance research for challengers. Triggers on: 'utah candidates', 'utah primary', 'salt lake county candidates', 'utah county candidates', 'pull utah elections', 'utah ballot'."
argument-hint: "[--counties \"Salt Lake, Utah\"] [--date 2026-06-23] [--mode partisan|nonpartisan] [--no-stances]"
---

# /research-utah-elections — Utah Primary Candidate Research & Ingestion

You are running the **research-utah-elections** skill. Your job is to research the people **running** in a Utah primary election, produce a reviewable CSV, generate an idempotent seed script that writes them into `essentials.elections` / `essentials.races` / `essentials.race_candidates`, link incumbents to existing politician records, and (optionally) chain compass-stance research for challengers.

This skill is the repeatable process for **any** future Utah candidate pull. It mirrors the conventions of the `research-stances` skill (numbered STEPs, reviewable CSV, human approval gate, idempotent DB writes) and produces seed SQL in the same shape as the two reference scripts already in the repo:

- **Party-separated primary (Monroe County, IN pattern)** — `ev-accounts/backend/scripts/seed-monroe-county-2026-primary.sql`
- **Nonpartisan single-ballot / statewide (LA County, CA pattern)** — `ev-accounts/backend/scripts/seed-la-county-2026-primary-state-federal.sql`

Read those two files before generating SQL — your output must match their structure exactly.

---

## Utah election facts you MUST apply

- **2026 Utah primary date: `2026-06-23`** (4th Tuesday in June).
- Utah's **June primary is partisan** — federal U.S. House, state legislature (State Senate / State House), county offices, and State Board of Education. Republican and Democratic ballots are separate (the R primary is closed; the D primary allows unaffiliated voters). → Use the **partisan / Monroe pattern**: one race per party, `races.primary_party` set to `'Republican'` or `'Democratic'`.
- Utah **municipal / city races are NONPARTISAN and held in ODD years** (August primary / November general). **The cities inside Salt Lake County and Utah County do NOT have a June 2026 primary.** Do not fabricate city primary races for 2026. The nonpartisan single-ballot pattern (`primary_party = NULL`, LA pattern) exists in this skill so the **next city cycle (2027)** reuses the same process — only use `--mode nonpartisan` when actually loading a nonpartisan contest.
- **Antipartisan principle:** party context lives ONLY on the race (`races.primary_party`). Never store party on a candidate, and never surface party color/labels on candidate UI.

---

## STEP 0 — Parse input & set election parameters

Parse `$ARGUMENTS`:

- `--counties` — comma-separated county names (default: `Salt Lake, Utah`).
- `--date` — election date (default: `2026-06-23`).
- `--mode` — `partisan` (default) or `nonpartisan`.
- `--no-stances` — skip STEP 5 (compass research).

Resolve the election header (used everywhere downstream):

| Field | Default |
|-------|---------|
| `name` | `2026 Utah Primary` |
| `election_date` | `2026-06-23` |
| `election_type` | `primary` |
| `state` | `UT` |
| `jurisdiction_level` | `state` (one election row covering federal/state/county races, LA-style) |

**Echo the resolved parameters back to the user**, include the partisan-vs-nonpartisan warning above (especially: "cities have no June 2026 primary"), and **confirm before researching**.

---

## STEP 1 — Auto-research the candidate list

Dispatch research agents **in parallel** (use multiple Agent tool calls in one message; max ~5 concurrent), one per county / scope. Use `subagent_type: "politician-stance-researcher"` (it is the general research agent available here) or the default research agent.

**Source priority (authoritative first):**
1. **Utah Lt. Governor / state elections candidate filing list** — `vote.utah.gov` / `elections.utah.gov` (the official certified filing list).
2. **County Clerk candidate lists** — Salt Lake County Clerk (`slco.org/clerk`) and Utah County Clerk (`utahcounty.gov`) for county/local contests.
3. **Candidate / campaign sites** — for verification and name spelling only.

For each contest, collect:
- `position_name` (e.g. `U.S. House District 3`, `Utah State Senate District 8`, `Salt Lake County Council District 2`)
- `district_type` (see STEP 2 list)
- `primary_party` (partisan mode only)
- `seats` (default 1)
- each candidate's `full_name`, `first_name`, `last_name`, `candidate_status`, and a `source_url`

**Rules for agents:**
- **Never invent a candidate without a source URL.**
- **Exclude withdrawn candidates**, or include them with `candidate_status = withdrawn`.
- Only research contests in the requested counties + the statewide/federal races those counties vote in.

---

## STEP 2 — Write the reviewable CSV

Write to `ev-accounts/backend/data/election-research/<DATE>-utah-primary.csv` (e.g. `2026-06-23-utah-primary.csv`) with this header:

```
jurisdiction_level,position_name,district_type,primary_party,seats,full_name,first_name,last_name,is_incumbent,candidate_status,politician_id,source_url
```

- `primary_party`: `Republican` / `Democratic` in partisan mode; **blank** in nonpartisan mode.
- `district_type`: one of `NATIONAL_LOWER`, `NATIONAL_UPPER`, `NATIONAL_EXEC`, `STATE_UPPER`, `STATE_LOWER`, `STATE_EXEC`, `STATE_BOARD`, `COUNTY`, `LOCAL`, `LOCAL_EXEC`, `SCHOOL`, `JUDICIAL`. Drives `office_id` resolution in STEP 4.
  - ⚠️ **Utah State Board of Education = `STATE_BOARD`, NOT `SCHOOL`.** USBE is a *state-level* body elected by 15 geographic districts (`geo_id ocd-division/.../sboe:N`, mtfcc `X0003`). Tagging it `SCHOOL` files it under the **Local** tier and (via the `'education'` keyword in `inferDistrictType`) breaks tier classification. Local school-district boards (e.g. LAUSD, Alpine) stay `SCHOOL`.
- `is_incumbent` / `politician_id`: filled by STEP 2b (leave blank for now).

### STEP 2b — Incumbent matching (fills `politician_id`)

For each candidate, check whether they match one of the ~374 already-loaded Utah politicians. Use the research-stances DB invocation style:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const names = process.argv.slice(2);
const { rows } = await pool.query(\`
  SELECT p.id AS politician_id, p.full_name, o.title AS office_title,
         d.district_type, d.label AS district_name
  FROM essentials.politicians p
  LEFT JOIN essentials.offices o   ON o.politician_id = p.id
  LEFT JOIN essentials.districts d ON d.id = o.district_id
  WHERE d.district_type IN ('NATIONAL_LOWER','STATE_UPPER','STATE_LOWER','COUNTY','LOCAL','SCHOOL','STATE_EXEC','STATE_BOARD')
    AND (\` + names.map((_,i)=>'p.full_name ILIKE \$'+(i+1)).join(' OR ') + \`)
  ORDER BY p.full_name
\`, names.map(n => '%'+n+'%'));
console.log(JSON.stringify(rows, null, 2));
await pool.end();
" -- "Last Name 1" "Last Name 2"
```

- On a confident match, set `politician_id` and `is_incumbent = true` in the CSV. Linking lets the candidate's existing photo, bio, and compass stances flow onto the candidate card automatically.
- **Surface fuzzy / ambiguous matches to the user in STEP 3** — do not auto-link a name that matches more than one politician or matches loosely.

---

## STEP 3 — Approval gate

Show the user a summary table before any DB write:

```
## Utah Primary Candidates — <DATE>

| Contest | Party | Seats | Candidates | Incumbents matched |
|---------|-------|-------|-----------|--------------------|
| U.S. House District 3 | Republican | 1 | 4 | Mike Kennedy (✔ linked) |
| ... | ... | ... | ... | ... |

CSV: ev-accounts/backend/data/election-research/<DATE>-utah-primary.csv
Ambiguous matches needing confirmation: <list, or "none">
```

Then ask:
> Review above. You can: **1) Approve all** → generate the seed script. **2) Reject rows** → name contests/candidates to drop. **3) Edit** → corrections (party, district, incumbent link). **4) CSV only** → stop here, no seed.

Do not proceed to STEP 4 until the user approves.

---

## STEP 4 — Generate idempotent seed SQL

Write `ev-accounts/backend/scripts/seed-ut-<DATE>-primary.sql`, mirroring the **three-step structure** of `seed-monroe-county-2026-primary.sql`. The file MUST be idempotent and wrapped in `BEGIN; … COMMIT;`.

**Step 1 — Upsert the election:**

```sql
INSERT INTO essentials.elections (name, election_date, election_type, jurisdiction_level, state, description)
VALUES ('2026 Utah Primary', '2026-06-23', 'primary', 'state', 'UT',
        'Utah 2026 Primary — Salt Lake & Utah County federal, state, and county races')
ON CONFLICT (name, election_date, state)
DO UPDATE SET description = EXCLUDED.description, updated_at = now();
```

**Step 2 — Upsert races** `ON CONFLICT (election_id, position_name, primary_party) DO UPDATE`:
- **Partisan mode** → emit **one race row per party** for each partisan office (Monroe pattern), `primary_party = 'Republican'` / `'Democratic'`.
- **Nonpartisan mode** → **one race row**, `primary_party = NULL` (LA pattern).

**`office_id` resolution (critical — address matching depends on it):**
- **District-scoped races** (`NATIONAL_LOWER`, `STATE_UPPER`, `STATE_LOWER`, `STATE_BOARD`, `COUNTY` council districts, `SCHOOL`) must set `race.office_id` to an existing office in that district so `electionService` **Part A** (PostGIS geofence → district → `race.office_id`) surfaces the race by address. Resolve it from the existing office in that district:

  ```sql
  -- office_id for a district race: the existing office in that district
  (SELECT o.id FROM essentials.offices o
     JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.district_type = 'STATE_LOWER'
      AND d.label ILIKE '%District 24%'   -- match the contest's district
    LIMIT 1)
  ```
  - **Utah State Board of Education** is district-scoped — resolve `office_id` from the matching `STATE_BOARD` office (one per district 1–15), e.g. `WHERE d.district_type = 'STATE_BOARD' AND d.district_id = '11'`. Do **not** leave it NULL: without the office link it falls to Part B and shows for *every* Utah address under the wrong tier. (See `scripts/fix-ut-state-board-race-office-ids.sql` for the backfill pattern.)
- **Statewide / at-large races** (Governor, U.S. Senate, statewide ballot questions) set `office_id = NULL` — they are served by `electionService` **Part B** (`r.office_id IS NULL AND e.state = 'UT'`). Note: the State Board of Education is **not** at-large — see above.

**Step 3 — Insert candidates** `… WHERE NOT EXISTS (rc.race_id = rid AND rc.full_name = v.full_name)` (Monroe idempotency pattern). Resolve `race_id` inline via the election+position+party subquery shown in the Monroe script.
- **Matched incumbent** → `politician_id = '<uuid>'`, `is_incumbent = true`.
- **Challenger** → `politician_id = NULL`, `is_incumbent = false`, name carried in the candidate row.
- Set `source` to the data origin (`sos_filing` / `county_clerk` / `manual`).

End the file with Monroe-style **verification queries as comments** (race count, candidate count per race).

**Apply it:**
```bash
cd ev-accounts/backend && set -a && source .env && set +a && psql "$DATABASE_URL" -f scripts/seed-ut-<DATE>-primary.sql
```

> ⚠️ For a first run, apply against the **dev** database (`EV-Backend-Dev`, project `mzuppdqbibqjedmesbmp`) before production (`E.V Backend`, `kxsdzaojfaibhuzmclfq`). Confirm with the user which DB to target.

---

## STEP 5 — Chain compass-stance research (unless `--no-stances`)

Hand the candidate list to the existing **`research-stances`** skill (`.claude/skills/research-stances/SKILL.md`) — do not duplicate its logic:
- **Linked incumbents** already have stances; report current coverage and only fill gaps.
- **Challengers** (`politician_id = NULL`) have no record — research them so their candidate card shows a compass radar. Note: a challenger needs a politician record for stances to attach; coordinate with the user on whether to create one, or keep the challenger display-only for this cycle.

---

## ERROR HANDLING

- If a research agent fails or times out, report **which contest** failed and offer to retry just that one.
- The **CSV is the source of truth**; the seed script is additive and idempotent. Never lose researched data to a failed DB write.
- If a name can't be matched to `essentials.politicians`, seed the candidate as a challenger (`politician_id = NULL`) and report it — don't block.
- If a contest's district can't be resolved to an `office_id`, seed the race with `office_id = NULL` (it will only surface via statewide Part B) and flag it so the user can backfill the district/geofence.

---

## Light verification (run after seeding)

1. Race + candidate counts:
   ```sql
   SELECT r.position_name, r.primary_party, COUNT(rc.*)
   FROM essentials.races r
   JOIN essentials.elections e ON r.election_id = e.id
   LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
   WHERE e.name = '2026 Utah Primary'
   GROUP BY r.position_name, r.primary_party ORDER BY r.position_name;
   ```
2. Address check: `GET /api/essentials/elections-by-address?address=<a Salt Lake County address>` returns the new races.
3. Re-run the seed — confirm no duplicate elections/races/candidates.
