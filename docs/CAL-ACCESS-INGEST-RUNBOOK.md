# CAL-ACCESS Ingest Runbook

> ## 🔴 THE LINKING PIPELINE BELOW IS RETIRED — do not revive it as written (2026-09-23)
>
> - **Step 1 is deleted.** `discover-cal-access-candidates.ts` and `discover-by-jurisdiction.ts` were
>   removed on 2026-09-23 (git history keeps them). Both linked committees to people **by name only**.
>   The first classified Cal-Access SUB_CATEGORY `40102` (PRIMARILY FORMED CANDIDATE) as the
>   candidate's own committee; those are **independent committees that support or oppose** the
>   candidate. The second seeded `confirmed` links with no control check at all. `CA_0192` found 63
>   such committees linked as people's own ("… SPONSORED BY BIZFED PAC", "CALIFORNIANS TO RECALL
>   GAVIN") and disputed them.
> - **Steps 2 and 3 are deleted too.** `confirm-cal-access.ts` was removed on 2026-09-23. It could
>   not run (it wrote the dropped `essentials.offices.politician_id`, ADR 0002, migration 1463), and
>   it matched on the last token of the name (migrations 1789 and 1792 demoted its results). CI step
>   "cal-access predicate tripwire" still fails a restore that keeps that rule.
> - The counts below are from April. On 2026-09-23 only 306 `cal_access` links on active rows are
>   `confirmed`.
> - **How to link a committee today:** decide it from the SOS bulk export — `FILER_TO_FILER_TYPE_CD`
>   CATEGORY `40002` (CONTROLLED), a `FILER_LINKS_CD` `12011` link naming the controlling candidate,
>   and state e-filed covers in `CVR_CAMPAIGN_DISCLOSURE_CD`. `CA_0192`'s header describes the method.
>   Do **not** confirm a local committee that has no SOS covers: its filings are with the city or
>   county, so it loads nothing and shows a false "data pending".
> - Ingestion is separate and still live: `calAccessAdapter.ts`, run by the `cal-access` job in
>   `backend/src/jobs/registry.ts` (#659). It loads only `confirmed` links.

**Last updated:** 2026-04-01 (banner above: 2026-09-23)  
**Status:** Phase 1 (discovery + auto-confirm + ambiguous pass) complete. ~64k `needs_research` rows remain.  
**Purpose:** Document what happened, what we learned, and the exact steps to continue.

---

## What This Is

Cal-Access is California's campaign finance disclosure database. It contains every registered candidate committee filer (76k+ rows). The goal of this ingest pipeline is to link those filer IDs to real `essentials.politicians` rows in our database so that `transparent_motivations` contribution data can be attributed to named politicians.

**All writes go to:**
- `transparent_motivations.politician_sources` — the linking table (`filer_id` → `politician_id`)
- `essentials.politicians` + `essentials.offices` — new placeholder politicians created during discovery
- `transparent_motivations.ingestion_runs` — audit log of every adapter run

---

## The Three-Script Pipeline

```
Step 1: discover-cal-access-candidates.ts   ← creates politician_sources rows (needs_research)
Step 2: confirm-cal-access.ts               ← promotes needs_research → confirmed (auto-match)
Step 3: confirm-cal-access.ts --ambiguous   ← operator-reviewed decisions applied
```

Each step is idempotent. Steps can be re-run safely; duplicates are caught by `ON CONFLICT DO NOTHING`.

---

## Current State (as of 2026-04-01 reset)

### DB counts
| Status | Unique filer_ids | Total rows |
|--------|-----------------|------------|
| `confirmed` | 7,901 | 7,901 |
| `needs_research` | 64,244 | 76,332 |

The discrepancy between unique filer_ids (64,244) and total rows (76,332) in `needs_research` is because some filer_ids have multiple `politician_sources` rows — one PAC placeholder row per original CAL-Access discovery entry.

### Confirmed breakdown
| Confirmed by | Count |
|---|---|
| Initial load (`confirm-cal-access.ts`) | 7,082 |
| Operator ambiguous review (`--ambiguous`) | 811 |
| Pre-script manual load (timestamped Mar 5) | 8 |
| **Total confirmed** | **7,901** |

### FEC status
| Status | Count |
|---|---|
| `confirmed` | 126 |
(FEC auto-match has been run; all confirmable federal politicians are already linked.)

---

## What the "Day-Long Run" Actually Was

On 2026-03-31 through 2026-04-01, a previous session ran the full Step 2 pipeline:

1. `confirm-cal-access.ts` (main pass) — processed all 76,332 `needs_research` rows. For each one, ran regex classification against every active CA politician. This is inherently O(n × m) — 76k rows × ~400 politicians = ~30M comparisons. **This is what took most of the time.**

2. Wrote audit CSVs and ambiguous CSVs (timestamped 2026-03-31).

3. Then ran `confirm-cal-access.ts --report` to produce the operator-friendly single-row-per-committee report CSV: `cal-access-report-2026-03-31T18-42-59.csv`.

4. Ran `confirm-cal-access.ts --ambiguous scripts/cal-access-report-2026-03-31T18-42-59.csv` to apply operator decisions. This CSV had 17,512 rows, 897 with `decision=confirm` filled in, 16,615 blank. Of the 897, 811 were new inserts (remainder were already-confirmed duplicates).

5. After each confirm/ambiguous run, the script calls `runAdapterForAll('cal_access')` to trigger ingest. This left **3 orphaned `status=running` ingestion_runs** in the DB (the machine was killed mid-run). These are harmless but should be manually cleaned up.

**Nothing in the git working tree changed** — all the CSVs, JSON reports, and TIGER shapefiles are untracked local files. No tracked code was modified or committed.

---

## Orphaned Ingestion Runs — Fix on Next Session

Three `ingestion_runs` rows are stuck as `status='running'` from the interrupted sessions. Clean them up:

```sql
UPDATE transparent_motivations.ingestion_runs
SET status = 'failed', completed_at = now(), notes = 'Interrupted — machine reset 2026-04-01'
WHERE adapter_name = 'cal_access'
  AND status = 'running';
```

---

## The `created_at` NULL Issue

The `politician_sources` table has a `created_at` column, but the confirm scripts **do not set it** — they omit it from the INSERT column list. The column has no `DEFAULT now()` clause, so all rows inserted by the confirm scripts land with `created_at = NULL`.

This means you **cannot** use `created_at` to track when confirm-script rows were inserted. Use `notes::jsonb->>'confirmed_by'` instead (JSON was added by the script).

**Fix to consider:** Add `DEFAULT now()` to `politician_sources.created_at` so future inserts are automatically timestamped.

```sql
ALTER TABLE transparent_motivations.politician_sources
  ALTER COLUMN created_at SET DEFAULT now();
```

---

## Local Files to Keep (Don't Lose These)

These are in the working tree but untracked/uncommitted. After the machine reset, verify they survived:

| File | What it is |
|------|-----------|
| `backend/scripts/cal-access-report-2026-03-31T18-42-59.csv` | **The key operator file** — 17,512 ambiguous committees, 897 already decided. 16,615 still blank = next work queue. |
| `backend/scripts/cal-access-confirm-2026-03-31T18-42-59.csv` | Auto-confirmed audit trail |
| `backend/scripts/cal-access-ambiguous-2026-03-31*.csv` | Prior ambiguous runs (earlier timestamps) |
| `backend/scripts/cal-access-confirm-2026-03-31*.csv` | Prior confirm audit CSVs |
| `backend/discover-cal-access-report-2026-03-*.json` | Raw discovery JSON reports from 2026-03-28/29 |

---

## Remaining Work

### The 16,615 Blank Decisions

`cal-access-report-2026-03-31T18-42-59.csv` has 16,615 rows with no `decision` set. These are the ambiguous cases the operator hasn't reviewed yet. Columns:

| Column | Meaning |
|--------|---------|
| `filer_id` | Cal-Access filer ID |
| `committee_name` | Name from Cal-Access |
| `case_type` | `single_no_signal` = one politician matched but no signal word; `multi_match` = multiple politicians matched |
| `match_count` | Number of politicians whose last name appeared in committee name |
| `matches` | `"Name (Office) [uuid]"` — the candidates |
| `politician_id` | Pre-filled for `single_no_signal`; blank for `multi_match` |
| `decision` | **Fill this in** — `confirm` or `reject` |

**Workflow:**
1. Open CSV in Excel/Sheets
2. For each row, review committee name + matches
3. Set `decision` column to `confirm` (correct match) or `reject` (wrong/no match)
4. For `multi_match` rows with blank `politician_id`, also fill in the correct UUID
5. Save as CSV, then run:

```bash
cd backend
npx tsx scripts/confirm-cal-access.ts --ambiguous scripts/cal-access-report-2026-03-31T18-42-59.csv
```

This is fully idempotent — rows already confirmed are silently skipped. Safe to run multiple times as you work through batches.

### The 64,244 `needs_research` Filer IDs

These are committees where no active CA politician's last name was found in the committee name. Options:

1. **Leave them** — they're PAC/party/ballot measure committees, not individual candidate committees. They're not matchable via the name-matching approach.
2. **Re-run discovery** — if you've added new politicians to `essentials.politicians` since the last confirm run, run Step 2 again with `--dry-run` first to see if new matches appear.
3. **Manual review** — for high-value committees, look them up on cal-access.sos.ca.gov and manually set `research_status = 'confirmed'` with the correct `essentials_politician_id`.

### FEC
FEC auto-match is complete (126 confirmed). If new federal politicians are added, re-run:

```bash
cd backend
npx tsx scripts/run-fec-auto-match.ts
```

Check current FEC status anytime:
```bash
npx tsx scripts/check-fec-sources.ts
```

---

## Script Reference

### Step 1 — Discovery (only needed if re-downloading Cal-Access bulk data)

```bash
# Download fresh bulk export from: https://cal-access.sos.ca.gov/Campaign/Candidates/
# Then:
npx tsx scripts/discover-cal-access-candidates.ts --zip /path/to/dbwebexport.zip
# Review the JSON report, then:
npx tsx scripts/discover-cal-access-candidates.ts --zip /path/to/dbwebexport.zip --execute
```

Requires: `DATABASE_URL` in `.env`

### Step 2 — Auto-confirm (main classify pass)

```bash
# Dry run (classify only, no DB writes, writes CSVs):
npx tsx scripts/confirm-cal-access.ts --dry-run

# Live run (inserts confirmed rows, triggers ingest):
npx tsx scripts/confirm-cal-access.ts

# Generate operator-friendly single-row-per-committee report:
npx tsx scripts/confirm-cal-access.ts --report
```

**Runtime warning:** The main classify pass is slow (~hours) on 76k rows because it runs regex matching against every active CA politician for every row. It's single-threaded and row-by-row. This is what took most of the day. The `--report` flag is fast — it just reformats the already-generated ambiguous CSV.

### Step 3 — Ambiguous review pass

```bash
npx tsx scripts/confirm-cal-access.ts --ambiguous scripts/cal-access-report-2026-03-31T18-42-59.csv
```

Processes only the rows with `decision=confirm` in the CSV. Blank-decision rows are skipped. Fully idempotent.

### Trigger ingest manually (after confirm)

```bash
npx tsx scripts/_run-fec-ingest.ts    # FEC
# Cal-Access ingest is triggered automatically at end of confirm-cal-access.ts runs
# Or run directly via runAdapterForAll('cal_access') in campaignFinanceScheduler.ts
```

---

## Key Schema Facts

```sql
-- The linking table
transparent_motivations.politician_sources (
  id                     uuid PRIMARY KEY,
  essentials_politician_id uuid REFERENCES essentials.politicians(id),
  source_system          varchar,   -- 'cal_access', 'fec', 'fec_pac', 'la_socrata', etc.
  external_id            varchar,   -- Cal-Access filer_id (string, not int)
  research_status        varchar,   -- 'needs_research' | 'confirmed' | 'not_applicable'
  notes                  text,      -- JSON string (no jsonb type — cast manually with ::jsonb)
  created_at             timestamptz  -- NULL for confirm-script rows (no DEFAULT set yet)
  -- UNIQUE (essentials_politician_id, source_system, external_id)
)
```

**Gotcha:** `notes` is `text`, not `jsonb`. The confirm scripts write JSON strings into it. To query: `notes::jsonb->>'confirmed_by'`. But only works on rows where notes is valid JSON — use `WHERE notes LIKE '{%'` to filter.

---

## TIGER/Line Shapefiles

The following were downloaded to the repo root during the long run. They are **not needed for Cal-Access ingest** — they were for a different phase (location/boundary work). They're large and should not be committed.

```
tl_2024_06_cd119.zip + dir   (CA congressional)
tl_2024_06_sldl.zip + dir    (CA state assembly)
tl_2024_06_sldu.zip + dir    (CA state senate)
tl_2024_06_unsd.zip + dir    (CA school districts)
tl_2024_18_cd119.zip + dir   (IN congressional)
tl_2024_18_sldl.zip + dir    (IN state house)
tl_2024_18_sldu.zip + dir    (IN state senate)
tl_2024_18_unsd.zip + dir    (IN school districts)
tl_2024_us_county.zip + dir  (national counties)
tl_2024_us_state.zip + dir   (national states)
```

Add to `.gitignore` if not already:
```
tl_2024_*/
*.zip
```

---

## Transparent Motivations Ingest — Big Picture

The end goal of all this source-linking work is that `transparent_motivations.contributions` rows can be attributed to a real politician via the chain:

```
contributions.committee_id
  → committees.filer_id
    → politician_sources.external_id (where source_system = 'cal_access')
      → politician_sources.essentials_politician_id
        → essentials.politicians.id
```

Only `confirmed` politician_sources rows are used in this chain. The `needs_research` rows mean contributions exist for that committee but we don't know which politician to attribute them to — they show up as `records_unresolved` in `ingestion_runs`.

The `completed_with_warning` status on recent ingestion runs (fetched 0–4 records) means the ingest ran but found no new contribution data to pull — likely because the Cal-Access API returned no new records since the last run, not an error.
