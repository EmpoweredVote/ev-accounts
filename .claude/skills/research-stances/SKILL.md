---
name: research-stances
description: "Research politician stances on compass topics. Use when the user wants to research, look up, or generate stance data for politicians on Empowered Vote compass topics. Produces a reviewable CSV and optionally pushes approved stances to the database. Triggers on: 'research stances', 'look up stances', 'politician positions', 'stance data for', 'compass research'."
argument-hint: "\"Politician Name(s)\" [--topics topic1,topic2] "
---

# /research-stances — Politician Stance Research Orchestrator

You are running the **research-stances** skill. Your job is to research politician stances on existing Empowered Vote compass topics, produce a reviewable CSV, and optionally push approved data to the database.

---

## STEP 0 — Parse Input

Parse `$ARGUMENTS` for:
- **Politician names**: comma-separated list (e.g., `"Brad Sherman, Maxine Waters"`)
- **--topics**: optional comma-separated topic_keys to limit scope (defaults to all topics)

If `$ARGUMENTS` is empty, ask the user:
> "Which politician(s) would you like me to research? You can provide names (e.g., 'Brad Sherman, Maxine Waters') or a body (e.g., 'Bloomington City Council')."

### Jurisdiction Resolution

If the input looks like a legislative body (e.g., "Bloomington City Council", "California State Senate"), resolve it to individual politicians by querying the database:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT p.id, p.full_name, p.last_stances_researched_at, o.title, c.name as chamber_name
  FROM essentials.politicians p
  JOIN essentials.offices o ON o.politician_id = p.id
  JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE c.name ILIKE '%' || \$1 || '%'
  ORDER BY p.full_name
\`, [process.argv[2]]);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
" -- "SEARCH_TERM"
```

Replace `SEARCH_TERM` with the relevant part of the user's input (e.g., "City Council" for "Bloomington City Council").

If no results, tell the user and ask them to provide specific names instead.

### Topic Resolution

Fetch the current live topics — grouped by scope from `compass_topic_roles` — to validate any `--topics` filter. This produces the **canonical topic lists** you will inject into every agent prompt in Step 1. Never use a hardcoded list.

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT
    t.id, t.topic_key, t.title, t.short_title, t.question_text,
    ARRAY_AGG(DISTINCT r.role_scope ORDER BY r.role_scope)
      FILTER (WHERE r.role_scope IS NOT NULL) AS scopes
  FROM inform.compass_topics t
  LEFT JOIN inform.compass_topic_roles r ON r.topic_id = t.id
  WHERE t.is_live = true
  GROUP BY t.id, t.topic_key, t.title, t.short_title, t.question_text, t.created_at
  ORDER BY t.created_at
\`);

const byScope = (scope) => rows.filter(r => r.scopes?.includes(scope)).map(r => r.topic_key);
const unscoped = rows.filter(r => !r.scopes?.length).map(r => r.topic_key);

console.log('NATIONAL TOPICS (federal/state): ' + byScope('federal').join(', '));
console.log('LOCAL TOPICS: ' + byScope('local').filter(k => !byScope('federal').includes(k)).join(', '));
console.log('JUDICIAL TOPICS: ' + byScope('judicial').join(', '));
if (unscoped.length) console.log('WARNING - unscoped topics (add to compass_topic_roles):', unscoped.join(', '));
console.log('\nALL TOPIC KEYS (' + rows.length + ' total): ' + rows.map(r => r.topic_key).join(', '));
console.log(JSON.stringify(rows, null, 2));
await pool.end();
"
```

Save the output lines — you will inject them into Step 1 agent prompts. If any `WARNING - unscoped` topics appear, add them to `inform.compass_topic_roles` before proceeding.

**Confirm before proceeding.** Show the user:
- List of politicians to research, including their `last_stances_researched_at` date (show "Never" if null)
- ⚠️ Flag any politician researched within the last **30 days** — show their date and note they may not need re-research. Still include them unless the user says to skip.
- Topics in scope (all or filtered), noting which topics are relevant to each politician's jurisdiction level
- Estimated scope (e.g., "3 politicians x 26 national topics = up to 78 stance assessments")

---

## STEP 0.5 — Apply Jurisdiction Rules

Some jurisdictions have legal rules that make a topic inapplicable to **every** official there (e.g. Utah Code §57-20-1 bans municipal rent control statewide, so no UT official can act on `rent-regulation`). These live in the coverage tracker at `ev-accounts/backend/data/coverage/<state>.yaml` under `rules.skip_topics`, and you MUST honor them **before** dispatching agents.

1. **Determine the state code** for this batch — the 2-letter code (e.g. `ut`) from the resolved politicians' `representing_state` / the body name.

2. **Read the skip rules** (no-op if the file doesn't exist — behave exactly as before):

Replace `STATE_CODE` with the batch's 2-letter code (e.g. `ut`):

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import fs from 'node:fs';
import yaml from 'js-yaml';
const state = 'STATE_CODE'.toLowerCase();
const f = 'data/coverage/' + state + '.yaml';
if (!fs.existsSync(f)) { console.log('NO_COVERAGE_RULES'); process.exit(0); }
const doc = yaml.load(fs.readFileSync(f, 'utf8'));
for (const r of (doc.rules?.skip_topics ?? [])) {
  console.log('SKIP\t' + r.topic_key + '\t' + (r.applies_to || []).join(',') + '\t' + r.reason);
}
"
```

3. **Map each politician's office to a coverage level**: `NATIONAL_*`/`STATE_*` → `state`, `COUNTY` → `county`, `LOCAL*` → `local`, `SCHOOL` → `school`, `JUDICIAL` → `judicial`.

4. **For each `SKIP` line whose `applies_to` includes a level present in this batch**, REMOVE that `topic_key` from the NATIONAL / LOCAL / JUDICIAL topic lists you saved in STEP 0 (so it is never injected into a Step 1 agent), and print a warning, e.g.:
   > ⚠️ Skipping `rent-regulation` for UT — Utah Code §57-20-1 prohibits municipal rent control. (rule: data/coverage/ut.yaml)

   If a batch mixes levels and a rule applies to only some of them, split the batch by level so non-matching politicians still get the topic. Include the skipped topics in the confirmation summary shown to the user.

---

## STEP 1 — Dispatch Research Agents

For each politician, dispatch a `politician-stance-researcher` agent using the Agent tool.

**Dispatch rules:**
- One agent per politician for well-known politicians (federal, state-level)
- Batches of 2-3 per agent for lesser-known politicians (local officials)
- Run agents **in parallel** — use multiple Agent tool calls in a single message
- Maximum 5 concurrent agents to stay within reasonable limits

**Agent prompt template:**

```
Research the political stances of [POLITICIAN_NAME] ([OFFICE/TITLE if known]).

[If --topics was specified:]
Only research these topics: [TOPIC_LIST]

[If --topics was NOT specified:]
Research all current policy topics.

IMPORTANT — Use ONLY these exact topic_key values (fetched live from the database in STEP 0 — NOT a hardcoded list):

National topics (federal/state politicians):
[INSERT THE "NATIONAL TOPICS" LINE FROM THE STEP 0 OUTPUT HERE]

Local topics (city council, county, municipal officials):
[INSERT THE "LOCAL TOPICS" LINE FROM THE STEP 0 OUTPUT HERE]

Judicial topics (judges, prosecutors, district attorneys):
[INSERT THE "JUDICIAL TOPICS" LINE FROM THE STEP 0 OUTPUT HERE]

The topic_key in your CSV output MUST exactly match one of these values.
Do NOT invent your own topic_key slugs.

Only research topics relevant to this politician's jurisdiction — use the scope groupings above.
Skip topics outside their jurisdiction unless they have taken a clear public position on them.

--output-file [ABSOLUTE_PATH]/ev-accounts/backend/data/stance-research/YYYY-MM-DD-[BATCH_NAME].csv

Important:
- Skip any topic where you cannot find sufficient evidence
- Every source URL must be real and verifiable
- Use the full 1-5 range based on evidence, not party affiliation
```

Use `subagent_type: "politician-stance-researcher"` in the Agent tool call.

---

## STEP 2 — Collect and Merge Results

After all agents complete:

1. Read the CSV file(s) generated by the agents
2. If multiple agents wrote to the same file, verify no duplicate headers
3. If agents returned results in their response text instead of writing to file, manually compile into the CSV file using the Write tool
4. Count total stances collected vs. expected (politicians x topics)

---

## STEP 3 — Present Approval Summary

Show the user a formatted summary table:

```
## Research Results: [BATCH_NAME]

| Politician | Topics Found | Topics Skipped |
|-----------|-------------|---------------|
| Name 1    | 19/21       | ai-regulation, redistricting |
| Name 2    | 21/21       | none |

### Stance Overview

| Politician | Topic | Value | Reasoning (preview) |
|-----------|-------|-------|-------------------|
| Name 1 | healthcare | 2 | "Cosponsored the Public Option..." |
| Name 1 | abortion | 1 | "Voted against every restrict..." |
| ...    | ...        | ... | ... |

CSV saved to: `ev-accounts/backend/data/stance-research/YYYY-MM-DD-[BATCH_NAME].csv`
```

Then ask:
> "Review the stances above. You can:
> 1. **Approve all** — push everything to the database
> 2. **Reject specific rows** — tell me which politician/topic pairs to remove
> 3. **Edit values** — tell me which rows to change (e.g., 'change Sherman/healthcare to 3')
> 4. **Skip DB push** — keep the CSV only, don't write to database
>
> What would you like to do?"

---

## STEP 4 — Push to Database

For each approved row, push to the database in two steps:

### 4a. Resolve IDs

Look up `politician_id` and `topic_id`:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT p.id as politician_id, p.full_name,
         t.id as topic_id, t.title as topic_title
  FROM essentials.politicians p
  CROSS JOIN inform.compass_topics t
  WHERE p.full_name = ANY(\$1)
    AND t.is_live = true
  ORDER BY p.full_name, t.created_at
\`, [process.argv.slice(2)]);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
" -- "Name1" "Name2"
```

If a politician name doesn't match any row in `essentials.politicians`, report it:
> "Could not find '[NAME]' in the politicians table. Their CSV data is preserved but won't be pushed to DB. You may need to create this politician first via the admin panel."

### 4b. Upsert answers and context

For each matched row, call the admin service functions via a script:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';

const stances = JSON.parse(process.argv[2]);

for (const s of stances) {
  // Upsert politician answer
  await pool.query(\`
    INSERT INTO inform.politician_answers (politician_id, topic_id, value)
    VALUES (\$1, \$2, \$3)
    ON CONFLICT (politician_id, topic_id)
    DO UPDATE SET value = EXCLUDED.value
  \`, [s.politician_id, s.topic_id, s.value]);

  // Upsert politician context (reasoning + sources)
  const sources = [s.source_url_1, s.source_url_2, s.source_url_3].filter(Boolean);
  await pool.query(\`
    INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
    VALUES (\$1, \$2, \$3, \$4)
    ON CONFLICT (politician_id, topic_id)
    DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources
  \`, [s.politician_id, s.topic_id, s.reasoning, sources]);
}

console.log('Done: ' + stances.length + ' stances upserted');
await pool.end();
" '[JSON_ARRAY_OF_RESOLVED_STANCES]'
```

### 4c. Stamp last_stances_researched_at

After a successful push, update the timestamp for every politician who had at least one stance upserted:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const ids = process.argv.slice(2);
await pool.query(
  'UPDATE essentials.politicians SET last_stances_researched_at = NOW() WHERE id = ANY(\$1::uuid[])',
  [ids]
);
console.log('Stamped ' + ids.length + ' politicians');
await pool.end();
" -- [SPACE-SEPARATED LIST OF POLITICIAN UUIDs]
```

### 4d. Report results

After DB push:
> "Pushed [N] stances to the database for [politician names].
> - [N] politician_answers upserted
> - [N] politician_context entries with reasoning and sources
> - last_stances_researched_at stamped for [M] politicians
> - CSV preserved at: [file path]
>
> Skipped: [list any unmatched politicians or rejected rows]"

---

## ERROR HANDLING

- If an agent fails or times out, report which politician failed and offer to retry just that one
- If the CSV file can't be written, fall back to showing results in conversation and offer to retry the file write
- If DB push fails for a specific row, report the error, skip that row, and continue with the rest
- Never lose data — the CSV is the source of truth; DB push is additive

---

# REWRITE RE-EVALUATION MODE (`--rewrite-id`)

When `$ARGUMENTS` includes `--rewrite-id <uuid>`, the skill runs in a
different mode that feeds the Plan D topic rewrite workflow
(`inform.topic_rewrites` / `inform.topic_rewrite_stance_proposals`)
instead of pushing directly to live data.

In this mode, the skill:

1. Skips the normal politician-name input — the politician list
   comes from `topic_rewrite_stance_proposals` rows already seeded
   for the rewrite.
2. Fetches BOTH the old and new topic framing and passes them to
   the agent so each politician gets re-scored under the new scale.
3. Pushes proposed values to `admin_upsert_stance_proposal` instead
   of direct inserts on `politician_context`.
4. Auto-approves each proposal via `admin_approve_stance_proposal`
   (the workflow's human gate is intentionally bypassed by
   auto-approval — the audit trail in `topic_rewrites` provides
   rollback safety).
5. Skips the STEP 3 approval summary prompt (nothing to approve —
   everything auto-approves).

## STEP 0 (rewrite mode) — Parse and fetch rewrite detail

Parse `$ARGUMENTS` for `--rewrite-id <uuid>`. If present, switch to
rewrite mode and IGNORE the politician-name and `--topics` args.

Fetch the rewrite detail including old and new framing, plus the
pending proposals queue:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const rewriteId = process.argv[2];
const { rows: detail } = await pool.query(\`
  SELECT r.*,
         ot.title AS old_title, ot.question_text AS old_question_text, ot.version AS old_version,
         nt.title AS new_title, nt.question_text AS new_question_text, nt.version AS new_version
  FROM inform.topic_rewrites r
  JOIN inform.compass_topics ot ON ot.id = r.old_topic_id
  JOIN inform.compass_topics nt ON nt.id = r.new_topic_id
  WHERE r.id = \$1
\`, [rewriteId]);
const { rows: oldStances } = await pool.query(
  'SELECT value, text FROM inform.compass_stances WHERE topic_id=\$1 ORDER BY value',
  [detail[0].old_topic_id]
);
const { rows: newStances } = await pool.query(
  'SELECT value, text FROM inform.compass_stances WHERE topic_id=\$1 ORDER BY value',
  [detail[0].new_topic_id]
);
const { rows: proposals } = await pool.query(\`
  SELECT p.politician_id, p.old_value, p.old_reasoning, p.old_sources, p.status,
         pol.full_name, o.title AS office_title, c.name AS chamber_name
  FROM inform.topic_rewrite_stance_proposals p
  JOIN essentials.politicians pol ON pol.id = p.politician_id
  LEFT JOIN essentials.offices o ON o.politician_id = pol.id
  LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE p.rewrite_id = \$1 AND p.status = 'pending'
  ORDER BY pol.full_name
\`, [rewriteId]);
console.log(JSON.stringify({ rewrite: detail[0], oldStances, newStances, proposals }, null, 2));
await pool.end();
" -- "REWRITE_ID_HERE"
```

Confirm with the user before dispatching agents:
- Topic being rewritten (`topic_key` and old→new version)
- New framing (title, question_text, 5 stance texts)
- Old framing for context
- Count of politicians to re-evaluate (= count of pending proposals)
- Estimated scope ("~30 politicians × 1 topic = 30 re-evaluations")

## STEP 1 (rewrite mode) — Dispatch re-evaluation agents

For each politician with a pending proposal (batch size 3–5 per
agent to keep context manageable), dispatch a
`politician-stance-researcher` agent.

**Dispatch prompt template for re-evaluation:**

**CRITICAL — template substitution happens in the skill, not the agent.** Before calling the Agent tool, you (the skill orchestrator) MUST replace every `[bracketed_placeholder]` below with the concrete value from the STEP 0 fetch (`[TOPIC_KEY]`, `[old_question_text]`, `[old_stance_1..5]`, `[new_question_text]`, `[new_stance_1..5]`, and the per-politician `[full_name]`/`[office_title]`/`[chamber_name]`/`[old_value]`/`[old_reasoning]`/`[old_sources]`). Passing the literal bracketed text to the agent will fail silently — the agent has no access to the rewrite detail you already fetched. Build one fully-substituted prompt string per batch and pass that to the Agent tool.

**PREFERRED INVOCATION PATTERN — write prompts to disk, have agents Read them.** Instead of passing the full substituted prompt inline in the Agent tool call (large, error-prone, hard to audit), use a short Node script to build one fully-substituted prompt per batch and write each to `/tmp/<topic_key>_prompt_batch<N>.txt`. Then the Agent tool call only needs a short wrapper prompt like:

> Read the file `/tmp/<topic_key>_prompt_batch<N>.txt` in its entirety and follow it exactly. It contains a REWRITE RE-EVALUATION MODE task for 5 politicians on the "<topic_key>" topic. [...schema reminders + CSV format + output path confirmation...]

Benefits:
- The orchestrator's message tokens stay small even with 9+ batches dispatched in parallel.
- Substitution happens once, in a single Node script with full access to the STEP 0 JSON — no escape-hell embedding multi-paragraph reasoning into inline JS strings.
- The prompt files remain on disk as an audit trail of exactly what each agent saw.
- Easy to inspect/regenerate a single batch if one agent fails.

This pattern was validated on the housing rewrite (45 politicians, 9 batches, two waves of 5+4). Total wall-clock time was ~3 minutes, not the 3 hours estimated in the runbook — because agents mostly map existing reasoning rather than doing fresh research when prior evidence already exists.

```
You are running in REWRITE RE-EVALUATION MODE.

A compass topic has been rewritten with new framing. You need to
re-score each listed politician's stance under the new scale. Their
old stance under the old scale is provided as context — use it to
understand their position, then map that position onto the new scale.

## Topic key
[TOPIC_KEY, e.g. ai-regulation]

## OLD framing (what the politician was originally scored against)
Question: [old_question_text]
Stance scale:
  1 = [old_stance_1]
  2 = [old_stance_2]
  3 = [old_stance_3]
  4 = [old_stance_4]
  5 = [old_stance_5]

## NEW framing (what you're scoring against now)
Question: [new_question_text]
Stance scale:
  1 = [new_stance_1]
  2 = [new_stance_2]
  3 = [new_stance_3]
  4 = [new_stance_4]
  5 = [new_stance_5]

## Politicians to re-evaluate

For each politician below, you have their prior stance, prior
reasoning, and prior sources. Your task is to produce a NEW value,
NEW reasoning, and NEW sources under the new scale.

[For each politician in the batch, include:]
### [full_name] ([office_title], [chamber_name])
- Prior value under old scale: [old_value]
- Prior reasoning: [old_reasoning]
- Prior sources: [old_sources joined]

## Instructions

- Prefer mapping the prior evidence onto the new scale — that's the
  fastest path when the new framing is a generalization or
  reframing of the old one.
- Only do fresh research if the new framing asks about something the
  old research didn't cover (e.g., new framing includes a dimension
  the old scale ignored). Note in reasoning when you added evidence.
- Your new reasoning MUST explicitly reference the new scale. Write
  as if explaining to someone looking at the new question/stances
  for the first time. Do not reference the old scale.
- If a politician's position genuinely spans two new stances, pick
  the better match and note the ambiguity in reasoning.
- If you cannot score a politician under the new framing with
  available evidence, output value=null and note in reasoning why.
  Do NOT guess.

## Output format

For each politician, produce one CSV row:

full_name,politician_id,topic_key,value,reasoning,source_url_1,source_url_2,source_url_3

Write to --output-file [ABSOLUTE_PATH]/ev-accounts/backend/data/stance-research/YYYY-MM-DD-rewrite-[TOPIC_KEY].csv

Important: The politician_id column is new in this mode — include
the UUID from the batch input for each row.
```

## STEP 2 (rewrite mode) — Collect results (same as normal mode)

Same as STEP 2 in normal mode, just with politician_id column.

## STEP 3 (rewrite mode) — SKIPPED

No approval prompt. In rewrite mode, the workflow auto-approves
every proposal. The audit trail lives in the `topic_rewrites` table
and every change is reversible (old topic row stays with
is_live=false for easy rollback).

## STEP 4 (rewrite mode) — Push proposals, auto-approve, and auto-reject

Every pending proposal must resolve before `admin_mark_rewrite_publish_ready`
will succeed — any proposal left `pending` blocks publish with a
`PROPOSALS_PENDING` error. That means null-value rows (insufficient
evidence) MUST be rejected here, not just skipped.

For each re-evaluated row, the script handles three outcomes:
1. **Has a value** → upsert proposal, then auto-approve.
2. **Null value** → auto-reject with an insufficient-evidence note.
3. **Upsert/approve fails** → log error, continue, report at end.

### 4a. Parse CSV batches and apply in one script

Read every `YYYY-MM-DD-rewrite-[TOPIC_KEY]-batch*.csv` file the agents
produced. Parse them with `csv-parse/sync` (already installed in the
backend). Do NOT try to inline a JSON payload on the command line —
the reasoning fields contain commas, quotes, and special characters
that break shell escaping.

Write the script to `ev-accounts/backend/scripts/apply-rewrite-[TOPIC_KEY].ts`
so there's a permanent audit trail of what was applied:

```typescript
import { readFileSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'csv-parse/sync';
import { pool } from '../src/lib/db.js';

const REWRITE_ID = '[REWRITE_UUID]';        // orchestrator substitutes
const ACTOR_ID = '[ACTOR_UUID]';             // same id that created the rewrite
const CSV_DIR = join(process.cwd(), 'data/stance-research');
const CSV_PREFIX = '[YYYY-MM-DD]-rewrite-[TOPIC_KEY]-batch';

type Row = {
  full_name: string;
  politician_id: string;
  topic_key: string;
  value: string;
  reasoning: string;
  source_url_1: string;
  source_url_2: string;
  source_url_3: string;
};

const files = readdirSync(CSV_DIR)
  .filter(f => f.startsWith(CSV_PREFIX) && f.endsWith('.csv'))
  .sort();

const allRows: Row[] = [];
for (const f of files) {
  const content = readFileSync(join(CSV_DIR, f), 'utf8');
  const rows = parse(content, {
    columns: true,
    skip_empty_lines: true,
    relax_column_count: true,
  }) as Row[];
  allRows.push(...rows);
}

let upserted = 0;
let approved = 0;
let rejected = 0;
const errors: string[] = [];

for (const r of allRows) {
  const isNull = !r.value || r.value.trim() === '' || r.value === 'null';

  if (isNull) {
    // Null value → auto-reject. Reasoning field from the agent
    // explains WHY evidence was insufficient; surface that as the
    // rejection note so the audit trail preserves the explanation.
    try {
      await pool.query(
        `SELECT inform.admin_reject_stance_proposal($1::uuid, $2::uuid, $3::uuid, $4::text)`,
        [REWRITE_ID, r.politician_id, ACTOR_ID,
         `Insufficient evidence under new scale: ${r.reasoning || 'agent returned null'}`]
      );
      rejected++;
      console.log(`REJECT ${r.full_name}`);
    } catch (e: any) {
      errors.push(`REJECT ${r.full_name}: ${e.message}`);
    }
    continue;
  }

  // Has a value → upsert + approve
  const value = Number(r.value);
  const sources = [r.source_url_1, r.source_url_2, r.source_url_3]
    .map(s => s?.trim()).filter(Boolean);
  try {
    await pool.query(
      `SELECT inform.admin_upsert_stance_proposal($1::uuid, $2::uuid, $3::numeric, $4::text, $5::text[])`,
      [REWRITE_ID, r.politician_id, value, r.reasoning, sources]
    );
    upserted++;
    console.log(`UPSERT ${r.full_name} value=${value}`);
  } catch (e: any) {
    errors.push(`UPSERT ${r.full_name}: ${e.message}`);
    continue;
  }
  try {
    await pool.query(
      `SELECT inform.admin_approve_stance_proposal($1::uuid, $2::uuid, $3::uuid, $4::text)`,
      [REWRITE_ID, r.politician_id, ACTOR_ID,
       'auto-approved by research-stances rewrite mode']
    );
    approved++;
    console.log(`APPROVE ${r.full_name}`);
  } catch (e: any) {
    errors.push(`APPROVE ${r.full_name}: ${e.message}`);
  }
}

console.log(`\nSUMMARY: upserted=${upserted} approved=${approved} rejected=${rejected} errors=${errors.length}`);
if (errors.length) {
  errors.forEach(e => console.log('  ' + e));
  process.exitCode = 1;
}
await pool.end();
```

Run with: `cd ev-accounts/backend && set -a && source .env && set +a && npx tsx scripts/apply-rewrite-[TOPIC_KEY].ts`

### 4b. Handle proposals the agents didn't touch

If the count of CSV rows doesn't match `proposalCount` from STEP 0,
some pending proposals were missed entirely (e.g. an agent crashed
mid-batch). List them with:

```sql
SELECT p.politician_id, pol.full_name
FROM inform.topic_rewrite_stance_proposals p
JOIN essentials.politicians pol ON pol.id = p.politician_id
WHERE p.rewrite_id = '[REWRITE_ID]'::uuid AND p.status = 'pending';
```

Either re-run the missing batches or manually reject them — otherwise
`admin_mark_rewrite_publish_ready` will fail.

### 4c. Report results

```
## Rewrite re-evaluation complete: [topic_key]

- Rewrite ID: [uuid]
- Proposals upserted: [N]
- Proposals approved: [N]
- Proposals rejected (insufficient evidence): [N]
- Errors: [N]

Ready for publish_ready + publish.
```

Note on `ACTOR_ID`: this is a Supabase user id needed by the RPC
for audit logging. The orchestrator (not the skill) supplies it —
use the same id that created the rewrite.

The skill stops here in rewrite mode. The orchestrating
conversation (not the skill itself) is responsible for calling
`admin_mark_rewrite_publish_ready` + `admin_publish_topic_rewrite`
afterward — that way the human/AI running the rewrite can inspect
the proposals table between auto-approval and publish if desired,
even though the normal path is to publish immediately.
