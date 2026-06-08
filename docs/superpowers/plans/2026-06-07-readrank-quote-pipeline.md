# Read & Rank Quote Pipeline (Plan 1 of 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the `research-stances` skill capture a verbatim + de-identified quote per stance and push it into `essentials.quotes` (keep-all, one `readrank_selected` per stance), and make the Read & Rank route serve only the selected quote.

**Architecture:** Add a `readrank_selected` boolean to `essentials.quotes` with a partial-unique index and a backfill (one per existing stance). The Read & Rank service filters on it. The research agent gains two CSV columns (`quote_text`, `quote_deidentified`); the skill's push step inserts quotes keep-all and sets the selection at the human approval gate. The admin selection UI is Plan 2.

**Tech Stack:** PostgreSQL (Supabase, project `kxsdzaojfaibhuzmclfq`), Node 20 + TypeScript + Express, Vitest, the `research-stances` Claude skill + `politician-stance-researcher` agent (Markdown).

**Spec:** `docs/superpowers/specs/2026-06-07-research-stances-quote-path-design.md`

**Sequencing note (cross-branch):** Task 1 (migration) must be applied to the production DB **before** Task 2 (the Read & Rank filter) is deployed. The Read & Rank route lives on `master` (`backend/src/routes/readrank.ts` + `backend/src/lib/readrankService.ts`), not on `feat/admin-review-queue`. Task 2 is authored on `master`; Tasks 1, 3, 4 are on the working branch. The migration is additive (`DEFAULT false` + backfill) and harmless before Task 2 ships.

---

### Task 1: Schema migration — `readrank_selected` flag + backfill

**Files:**
- Create: `backend/migrations/276_readrank_selected_quotes.sql`
- Apply via: Supabase MCP `apply_migration` (project `kxsdzaojfaibhuzmclfq`)

- [ ] **Step 1: Capture the pre-migration baseline**

Run (Supabase MCP `execute_sql`, project `kxsdzaojfaibhuzmclfq`):

```sql
SELECT r.position_name,
  COUNT(DISTINCT rc.politician_id) FILTER (WHERE q.deidentified_text IS NOT NULL) AS playable_candidates
FROM essentials.races r
JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id IS NOT NULL
  AND COALESCE(rc.candidate_status,'active') <> 'withdrawn'
JOIN essentials.quotes q ON q.politician_id = rc.politician_id
JOIN inform.compass_topics ct ON ct.topic_key = lower(q.topic_key) AND ct.is_live = true
GROUP BY r.position_name
HAVING COUNT(DISTINCT rc.politician_id) FILTER (WHERE q.deidentified_text IS NOT NULL) >= 2;
```

Expected: 3 rows — `United States Representative, Ninth District` (4), `State Representative, District 061` (2), `Monroe County Commissioner District 1` (2). Record these numbers; Step 4 must reproduce them.

- [ ] **Step 2: Write the migration file**

Create `backend/migrations/276_readrank_selected_quotes.sql`:

```sql
-- 276_readrank_selected_quotes.sql
-- Adds a per-stance "this is the Read & Rank quote" flag to essentials.quotes.
-- Keep-all model: multiple quotes per (politician, topic) are allowed; exactly one
-- per (politician_id, lower(topic_key)) may be readrank_selected.

BEGIN;

ALTER TABLE essentials.quotes
  ADD COLUMN IF NOT EXISTS readrank_selected boolean NOT NULL DEFAULT false;

-- Backfill: pick exactly one row per existing stance.
-- Prefer a de-identified quote; tie-break by earliest created_at (nullable) then id.
WITH ranked AS (
  SELECT id,
         row_number() OVER (
           PARTITION BY politician_id, lower(topic_key)
           ORDER BY (deidentified_text IS NOT NULL) DESC,
                    created_at ASC NULLS LAST,
                    id ASC
         ) AS rn
  FROM essentials.quotes
)
UPDATE essentials.quotes q
SET readrank_selected = true
FROM ranked
WHERE q.id = ranked.id AND ranked.rn = 1;

-- Enforce at most one selected per stance.
CREATE UNIQUE INDEX IF NOT EXISTS quotes_one_selected_per_stance
  ON essentials.quotes (politician_id, lower(topic_key))
  WHERE readrank_selected;

COMMIT;
```

- [ ] **Step 3: Apply the migration**

Apply via Supabase MCP `apply_migration` with `name: "276_readrank_selected_quotes"`, `project_id: "kxsdzaojfaibhuzmclfq"`, and `query` = the full file contents above.
Expected: success, no error.

- [ ] **Step 4: Verify backfill correctness**

Run (Supabase MCP `execute_sql`):

```sql
-- (a) Exactly one selected per stance (expect zero offending groups):
SELECT count(*) AS bad_groups FROM (
  SELECT politician_id, lower(topic_key) AS tk,
         count(*) FILTER (WHERE readrank_selected) AS sel
  FROM essentials.quotes
  GROUP BY politician_id, lower(topic_key)
  HAVING count(*) FILTER (WHERE readrank_selected) <> 1
) x;

-- (b) Live-race playability under the NEW flag must match Step 1 (expect same 3 rows/counts):
SELECT r.position_name,
  COUNT(DISTINCT rc.politician_id) FILTER (WHERE q.deidentified_text IS NOT NULL AND q.readrank_selected) AS playable_candidates
FROM essentials.races r
JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id IS NOT NULL
  AND COALESCE(rc.candidate_status,'active') <> 'withdrawn'
JOIN essentials.quotes q ON q.politician_id = rc.politician_id
JOIN inform.compass_topics ct ON ct.topic_key = lower(q.topic_key) AND ct.is_live = true
GROUP BY r.position_name
HAVING COUNT(DISTINCT rc.politician_id) FILTER (WHERE q.deidentified_text IS NOT NULL AND q.readrank_selected) >= 2;
```

Expected: (a) `bad_groups = 0`; (b) the same 3 races with the same candidate counts recorded in Step 1.

- [ ] **Step 5: Commit the migration file**

```bash
git add backend/migrations/276_readrank_selected_quotes.sql
git commit -m "feat(db): add readrank_selected flag to essentials.quotes with backfill"
```

---

### Task 2: Filter the Read & Rank route on `readrank_selected` (on `master`)

**Files:**
- Modify: `backend/src/lib/readrankService.ts` (three queries) — **on the `master` branch**

> Do this on a branch off `master` (e.g. `git switch master && git switch -c feat/readrank-selected-filter`). Only after Task 1 is applied to production.

- [ ] **Step 1: Add the filter to `getPlayableRaces`**

In `backend/src/lib/readrankService.ts`, the `getPlayableRaces` query joins quotes:

```
    JOIN essentials.quotes q
      ON q.politician_id = rc.politician_id
     AND q.deidentified_text IS NOT NULL
```

Change to:

```
    JOIN essentials.quotes q
      ON q.politician_id = rc.politician_id
     AND q.deidentified_text IS NOT NULL
     AND q.readrank_selected = true
```

- [ ] **Step 2: Add the filter to `getRaceBlindQuotes`**

Same three-line join inside `getRaceBlindQuotes` — add the identical `AND q.readrank_selected = true` line.

- [ ] **Step 3: Add the filter to `computeRaceMatch`**

Inside `computeRaceMatch`, the join is on one line:

```
    JOIN essentials.quotes q ON q.politician_id = rc.politician_id AND q.deidentified_text IS NOT NULL
```

Change to:

```
    JOIN essentials.quotes q ON q.politician_id = rc.politician_id AND q.deidentified_text IS NOT NULL AND q.readrank_selected = true
```

- [ ] **Step 4: Typecheck**

Run: `cd backend && npm run typecheck`
Expected: no errors.

- [ ] **Step 5: Verify the live endpoint still serves the 3 races**

With `backend/.env` present, run `cd backend && npm run dev`, then:

```bash
curl -s http://localhost:3000/api/readrank/races | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d['races']), 'races:', sorted(r['positionName'] for r in d['races']))"
```

Expected: `3 races: ['Monroe County Commissioner District 1', 'State Representative, District 061', 'United States Representative, Ninth District']`.

- [ ] **Step 6: Commit**

```bash
git add backend/src/lib/readrankService.ts
git commit -m "feat(readrank): serve only the readrank_selected quote per stance"
```

---

### Task 3: Add quote columns + de-id rules to the researcher agent

**Files:**
- Modify: `.claude/agents/politician-stance-researcher.md` (OUTPUT FORMAT section, ~line 449-462; QUOTES section ~373-377; self-audit ~494)

- [ ] **Step 1: Extend the OUTPUT FORMAT column list**

Find (around line 454):

```
full_name,external_id,topic_key,value,reasoning,source_url_1,source_url_2,source_url_3
```

Replace with:

```
full_name,external_id,topic_key,value,reasoning,source_url_1,source_url_2,source_url_3,quote_text,quote_deidentified
```

Then, in the column descriptions immediately below it, append these two bullet lines after the `source_url_*` bullet:

```
- `quote_text`: ONE exact, verbatim quote (the politician's own words) that best documents this stance. Wrap in double quotes; escape embedded double quotes by doubling them (RFC 4180). Leave BLANK if the position is documented only by voting record/paraphrase with no quotable sentence.
- `quote_deidentified`: the SAME quote rewritten so the speaker is not identifiable (see DE-IDENTIFICATION below). Leave BLANK if `quote_text` is blank, or if it cannot be de-identified without destroying the stance.
```

- [ ] **Step 2: Add a DE-IDENTIFICATION subsection**

Immediately after the existing `### Quotes` subsection (ends ~line 377), insert:

```
### De-identification (quote_deidentified)

Read & Rank shows quotes blind — readers must not be able to tell who said it.
Produce `quote_deidentified` from `quote_text` with MINIMUM change — edit only the
identity-revealing phrases.

SCRUB:
- the speaker's own name
- explicit office claims ("as Senator", "since I came to Congress", "I'm a commissioner")
- acts only one office can do ("I signed an executive order", "I met with President X")
- party self-ID ("our Democratic Party", "Indiana Republicans")
- naming the incumbent or opponent
- narrowing a district/jurisdiction that identifies the seat

KEEP (not identifying):
- bare state/demographic names ("Indiana", "Hoosier", "California")
- generic "we"
- bill names without an authorship claim (SAVE Act, USMCA, Prop 1, a state RFRA)
- broad policy advocacy

If a quote cannot be de-identified without destroying the stance, leave
`quote_deidentified` BLANK (the quote is still recorded; it just won't be served by
Read & Rank).
```

- [ ] **Step 3: Add a self-audit line**

In the self-audit list (~line 494, the "Self-audit — Review for:" step), append:

```
   - `quote_deidentified` contains NO speaker name, office claim, party self-ID, or named opponent
```

- [ ] **Step 4: Verify the edits**

Run:

```bash
grep -n "quote_text,quote_deidentified" .claude/agents/politician-stance-researcher.md
grep -n "De-identification (quote_deidentified)" .claude/agents/politician-stance-researcher.md
```

Expected: both grep lines return a match.

- [ ] **Step 5: Commit**

```bash
git add .claude/agents/politician-stance-researcher.md
git commit -m "feat(agent): capture quote_text + quote_deidentified in stance research CSV"
```

---

### Task 4: Push quotes in the research-stances skill (STEP 2/3/4)

**Files:**
- Modify: `.claude/skills/research-stances/SKILL.md` (STEP 2 collect ~169; STEP 3 approval ~180-210; STEP 4 push ~214-297)

- [ ] **Step 1: Note the new columns in STEP 2**

In STEP 2 ("Collect and Merge Results"), append a bullet:

```
5. The CSV now includes `quote_text` and `quote_deidentified` columns. Parse the CSV with a real RFC-4180 parser (`csv-parse/sync`), never by splitting on commas — quote columns contain commas and embedded quotes.
```

- [ ] **Step 2: Show quotes + conflicts in STEP 3**

In STEP 3, after the "Stance Overview" table description, insert:

```
### Quote Overview (Read & Rank)

For every row with a non-blank `quote_text`, show:

| Politician | Topic | Quote (de-identified) | De-id OK? |
|-----------|-------|----------------------|-----------|
| Name 1 | healthcare | "..." | yes / NEEDS MANUAL DE-ID (blank) |

For each (politician, topic) that ALREADY has quote(s) in `essentials.quotes`, show the
existing de-identified quote vs the new one and ask which should be the Read & Rank pick
(`readrank_selected`). Default: keep the current selection.

Rows where `quote_text` is present but `quote_deidentified` is blank are recorded as
library quotes but are NOT eligible to be the Read & Rank pick.
```

Also update the approval prompt's option 1 wording to: `**Approve all** — push stances AND quotes to the database`.

- [ ] **Step 3: Add STEP 4d — push quotes**

After section "4b. Upsert answers and context" (and before "4c. Report results"), insert a new subsection:

````
### 4d. Push quotes to essentials.quotes (Read & Rank)

For each approved, name-resolved row, build a quote object:

```
{
  politician_id, topic_key,            // topic_key lowercased
  quote_text, quote_deidentified,      // from the CSV; may be blank
  source_url,                          // first non-blank source_url_1..3, else null
  make_selected                        // boolean decided at STEP 3 (true for the chosen RR pick)
}
```

Only include objects whose `quote_text` is non-blank. Then run:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const quotes = JSON.parse(process.argv[2]);
let inserted = 0, dupes = 0, selected = 0, leaks = [];
await pool.query('BEGIN');
try {
  for (const x of quotes) {
    const tk = x.topic_key.toLowerCase();
    // idempotency: skip exact dupe
    const { rows: dup } = await pool.query(
      'SELECT id FROM essentials.quotes WHERE politician_id=\$1 AND lower(topic_key)=\$2 AND quote_text=\$3',
      [x.politician_id, tk, x.quote_text]
    );
    let quoteId;
    if (dup.length) { quoteId = dup[0].id; dupes++; }
    else {
      const sourceName = x.source_url ? (()=>{ try { return new URL(x.source_url).hostname; } catch { return null; } })() : null;
      const { rows: ins } = await pool.query(
        'INSERT INTO essentials.quotes (politician_id, topic_key, quote_text, deidentified_text, source_url, source_name) VALUES (\$1,\$2,\$3,\$4,\$5,\$6) RETURNING id',
        [x.politician_id, tk, x.quote_text, x.quote_deidentified || null, x.source_url || null, sourceName]
      );
      quoteId = ins[0].id; inserted++;
    }
    if (x.make_selected) {
      if (!x.quote_deidentified) { leaks.push(x.politician_id + '/' + tk + ': no de-id text, cannot select'); continue; }
      // leak-check: surname must not appear in de-id text
      const surname = (x.full_name || '').trim().split(/\s+/).pop();
      if (surname && new RegExp('\\\\b' + surname.replace(/[.*+?^\${}()|[\\]\\\\]/g,'\\\\\$&') + '\\\\b','i').test(x.quote_deidentified)) {
        leaks.push(x.politician_id + '/' + tk + ': surname leak, not selected'); continue;
      }
      await pool.query('UPDATE essentials.quotes SET readrank_selected=false WHERE politician_id=\$1 AND lower(topic_key)=\$2', [x.politician_id, tk]);
      await pool.query('UPDATE essentials.quotes SET readrank_selected=true WHERE id=\$1', [quoteId]);
      selected++;
    }
  }
  await pool.query('COMMIT');
  console.log(JSON.stringify({ inserted, dupes, selected, leaks }, null, 2));
} catch (e) { await pool.query('ROLLBACK'); console.error('Rolled back:', e.message); process.exit(1); }
await pool.end();
" '[JSON_ARRAY_OF_QUOTE_OBJECTS]'
```

`full_name` must be included on each object for the leak-check (carry it through from the
resolved row).
````

- [ ] **Step 4: Extend the STEP 4c report**

In "4c. Report results", append to the report block:

```
> Quotes: [inserted] inserted, [dupes] already present, [selected] set as the Read & Rank pick.
> Held back (no de-id / surname leak): [leaks list]
> Reminder: a race becomes playable in Read & Rank only when ≥2 candidates in it each have
> a readrank_selected de-identified quote on a live topic.
```

- [ ] **Step 5: Verify the edits**

Run:

```bash
grep -n "4d. Push quotes to essentials.quotes" .claude/skills/research-stances/SKILL.md
grep -n "csv-parse/sync" .claude/skills/research-stances/SKILL.md
grep -n "Quote Overview (Read & Rank)" .claude/skills/research-stances/SKILL.md
```

Expected: all three return a match.

- [ ] **Step 6: Commit**

```bash
git add .claude/skills/research-stances/SKILL.md
git commit -m "feat(skill): push research quotes into essentials.quotes with selection at approval gate"
```

---

## Self-Review notes

- Spec §1 (schema+backfill) → Task 1. §2 (RR filter) → Task 2. §3 (CSV) + §4 (agent) → Task 3. §5 (skill) → Task 4. §6 (admin) → Plan 2.
- Idempotency, leak-check, selection conflict, blank-deid handling all covered in Task 4.
- The leak-check regex and SQL `$n` placeholders are double-escaped for the `node -e` shell-heredoc context (`\\$&`, `\$1`) — matching the existing inline-node pattern in the skill.
