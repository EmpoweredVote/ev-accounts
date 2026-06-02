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

Fetch the current live topics — grouped by scope from `compass_topic_roles`, **with their full 1–5 stance scales** — to validate any `--topics` filter and to give each agent the authoritative scale to score against. This produces (a) the **canonical topic-key lists** you inject into every Step 1 prompt and (b) **per-scope scale reference files** in `/tmp/` that agents Read at dispatch time. Never use a hardcoded topic list or hardcoded scales — the database is the only source of truth, and it has drifted far from any list baked into an agent.

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
import fs from 'node:fs';
const { rows } = await pool.query(\`
  SELECT
    t.id, t.topic_key, t.title, t.question_text,
    ARRAY_AGG(DISTINCT r.role_scope ORDER BY r.role_scope)
      FILTER (WHERE r.role_scope IS NOT NULL) AS scopes,
    (SELECT json_agg(json_build_object('value', s.value, 'text', s.text) ORDER BY s.value)
       FROM inform.compass_stances s WHERE s.topic_id = t.id) AS stances
  FROM inform.compass_topics t
  LEFT JOIN inform.compass_topic_roles r ON r.topic_id = t.id
  WHERE t.is_live = true
  GROUP BY t.id, t.topic_key, t.title, t.question_text, t.created_at
  ORDER BY t.created_at
\`);

const has = (r, scope) => r.scopes?.includes(scope);
const national = rows.filter(r => has(r, 'federal'));
const local = rows.filter(r => has(r, 'local') && !has(r, 'federal'));
const judicial = rows.filter(r => has(r, 'judicial'));
const unscoped = rows.filter(r => !r.scopes?.length);

const block = (r) => {
  const out = ['### ' + r.topic_key + ' — ' + r.title];
  if (r.question_text) out.push('Q: ' + r.question_text);
  for (const s of (r.stances || [])) out.push(s.value + ' = ' + s.text);
  return out.join('\n');
};
const writeScope = (name, list) =>
  fs.writeFileSync('/tmp/ev-stance-scales-' + name + '.txt', list.map(block).join('\n\n') + '\n');
writeScope('national', national);
writeScope('local', local);
writeScope('judicial', judicial);

const keys = (list) => list.map(r => r.topic_key).join(', ');
console.log('NATIONAL TOPICS (federal/state): ' + keys(national));
console.log('LOCAL TOPICS: ' + keys(local));
console.log('JUDICIAL TOPICS: ' + keys(judicial));
if (unscoped.length) console.log('WARNING - unscoped topics (add to compass_topic_roles): ' + keys(unscoped));
console.log('\nALL TOPIC KEYS (' + rows.length + ' total): ' + rows.map(r => r.topic_key).join(', '));
console.log('\nScale reference files written to /tmp/:');
console.log('  ev-stance-scales-national.txt  (' + national.length + ' topics)');
console.log('  ev-stance-scales-local.txt     (' + local.length + ' topics)');
console.log('  ev-stance-scales-judicial.txt  (' + judicial.length + ' topics)');
await pool.end();
"
```

Save the printed topic-key lines — you inject them into Step 1 prompts (after STEP 0.5 removes any skipped keys). The `/tmp/ev-stance-scales-*.txt` files hold the full scale each agent scores against; you pass the matching path(s) into each dispatch. If any `WARNING - unscoped` topics appear, add them to `inform.compass_topic_roles` before proceeding.

### Resolve politician IDs and pre-load prior research

Before confirming, resolve every politician to their `essentials.politicians.id` and pull any stances already in the DB. This (a) gives each agent a stable `politician_id` to thread through the CSV — so STEP 4 never has to re-match fragile names — and (b) lets agents **update** prior research instead of re-researching from scratch (much faster, like rewrite mode). Prior stances are written to per-politician files agents Read at dispatch.

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
import fs from 'node:fs';
const names = process.argv.slice(2);
const { rows: pols } = await pool.query(\`
  SELECT id, full_name, last_stances_researched_at
  FROM essentials.politicians
  WHERE full_name = ANY(\$1)
     OR lower(full_name) = ANY(SELECT lower(n) FROM unnest(\$1::text[]) AS n)
\`, [names]);
const byName = new Map(pols.map(p => [p.full_name.toLowerCase(), p]));

const ids = pols.map(p => p.id);
const { rows: prior } = ids.length ? await pool.query(\`
  SELECT pa.politician_id, t.topic_key, pa.value, pc.reasoning, pc.sources
  FROM inform.politician_answers pa
  JOIN inform.compass_topics t ON t.id = pa.topic_id
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE pa.politician_id = ANY(\$1)
  ORDER BY pa.politician_id, t.created_at
\`, [ids]) : { rows: [] };

const priorByPol = new Map();
for (const r of prior) {
  if (!priorByPol.has(r.politician_id)) priorByPol.set(r.politician_id, []);
  priorByPol.get(r.politician_id).push(r);
}
for (const [pid, list] of priorByPol) {
  const body = list.map(r =>
    '### ' + r.topic_key + '  (prior value: ' + r.value + ')\n' +
    'Prior reasoning: ' + (r.reasoning || '(none)') + '\n' +
    'Prior sources: ' + ((r.sources || []).join(' | ') || '(none)')
  ).join('\n\n');
  fs.writeFileSync('/tmp/ev-prior-' + pid + '.txt', body + '\n');
}

console.log('RESOLVED (politician_id | name | last researched | prior stances):');
for (const n of names) {
  const p = byName.get(n.toLowerCase());
  if (!p) { console.log('  UNMATCHED | ' + n + ' | — | not in essentials.politicians (research only, cannot push)'); continue; }
  const cnt = (priorByPol.get(p.id) || []).length;
  const last = p.last_stances_researched_at ? new Date(p.last_stances_researched_at).toISOString().slice(0,10) : 'Never';
  console.log('  ' + p.id + ' | ' + p.full_name + ' | ' + last + ' | ' + cnt + (cnt ? '  -> /tmp/ev-prior-' + p.id + '.txt' : ''));
}
await pool.end();
" -- "Name1" "Name2"
```

Pass each politician's name as a trailing arg. Save the printed `politician_id` per name — you inject it into Step 1 and it flows through the CSV to Step 4. For any `UNMATCHED` politician, research can still run but the rows cannot be pushed (flag it in the confirmation). For politicians with a prior file, pass that path into their dispatch.

**Confirm before proceeding.** Show the user:
- List of politicians to research, with `politician_id` (or ⚠️ `UNMATCHED` — can't push) and their `last_stances_researched_at` date (show "Never" if null)
- ⚠️ Flag any politician researched within the last **30 days** — show their date and note they may not need re-research. Still include them unless the user says to skip.
- Note which politicians have **prior stances** to update (incremental) vs. need full fresh research
- Topics in scope (all or filtered), noting which topics are relevant to each politician's jurisdiction level
- Estimated scope (e.g., "3 politicians × 24 national topics = up to 72 stance assessments")

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

[Per politician in this dispatch — repeat this identity block for each one in a batch:]
politician_id: [UUID from STEP 0, or UNMATCHED if not in the DB]
Put this politician_id verbatim in the politician_id column of every CSV row for this politician (leave blank if UNMATCHED).

[If a prior-research file exists for this politician (STEP 0 printed a /tmp/ev-prior-<id>.txt path):]
Prior research file: /tmp/ev-prior-[UUID].txt — Read it FIRST. It lists this politician's existing stances (prior value, reasoning, sources) from an earlier run. Confirm or update each one efficiently against the CURRENT scale, and concentrate fresh research on topics that aren't listed or where prior evidence is thin. If you change a prior value, say so and why in the reasoning. (If no prior file is named, do full fresh research.)

IMPORTANT — Score ONLY these topics (fetched live from the database in STEP 0, after STEP 0.5 jurisdiction skips — NOT a hardcoded list). Inject only the line(s) matching THIS politician's level:

[INSERT the relevant topic-key line(s) for this politician's jurisdiction — "NATIONAL TOPICS" for federal/state officials, "LOCAL TOPICS" for city/county/municipal, "JUDICIAL TOPICS" for judges/prosecutors — copied from STEP 0, MINUS any keys STEP 0.5 removed.]

The exact 1–5 stance scale for every topic above is in this reference file (written live from the DB in STEP 0):

[INSERT the matching path(s): /tmp/ev-stance-scales-national.txt and/or /tmp/ev-stance-scales-local.txt and/or /tmp/ev-stance-scales-judicial.txt]

Read that file IN FULL before scoring anything. Score each topic against the EXACT numbered stance text in it — do NOT rely on any scale you remember; topics and scales change. Your `value` must correspond to one of that topic's numbered stances.

The topic_key in your CSV output MUST exactly match one of the keys listed above. Do NOT invent slugs, and do NOT score any topic not in the list above (the scale file may contain more topics than you were asked to score — the list above governs).

Skip topics outside this politician's jurisdiction unless they have taken a clear public position on them.

--output-dir [ABSOLUTE_PATH]/ev-accounts/backend/data/stance-research/[BATCH_ID]

(Choose a stable BATCH_ID slug for this run, e.g. `2026-06-02-bloomington-council`. EVERY agent in the batch — including re-research dispatches — writes its two CSVs into this same directory: `stances.csv` and `evidence.csv`, appending without repeating headers.)

Important:
- For every source you cite, capture a **verbatim 25–300 word snippet** in evidence.csv — **no snippet = no source.** A deterministic verifier fetches each URL and drops any snippet it can't find on the page (or whose subject isn't near it).
- If you cannot ground a stance in real snippets from real sources, leave `value` **blank** rather than guess.
- Use the full 1-5 range based on evidence, not party affiliation.
```

Use `subagent_type: "politician-stance-researcher"` in the Agent tool call.

---

## STEP 2 — Collect agent output

After all agents complete, the batch directory `data/stance-research/[BATCH_ID]/` should contain:
- `stances.csv` — `full_name,politician_id,topic_key,value,reasoning`
- `evidence.csv` — `full_name,topic_key,source_url,snippet,snippet_index`

1. Confirm both files exist with a single clean header each (agents append; check for duplicate header rows and remove any).
2. If an agent returned CSVs in its response text instead of writing files, save them into the batch dir with the Write tool.
3. Sanity-check: stance rows ≈ politicians × in-scope topics; every `source_url` in evidence.csv has at least one snippet row.

---

## STEP 2.5 — Verify evidence (the gate)

No data reaches the database until a **deterministic verifier** confirms each cited snippet actually appears on its page with the politician's name nearby. No LLM in this loop — it is pure string-matching, so it is cheap and auditable. Run it dry first:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && \
  npx tsx scripts/verify-stance-research.ts --dir data/stance-research/[BATCH_ID] --threshold 2
```

It fetches each URL with headless Chromium, string-matches every snippet (after normalizing whitespace/quotes/dashes/case), checks the politician's name is within ~500 chars of the match, and prints three buckets:
- **PUSH** — rows with ≥ threshold (default 2) verified sources. Ready for the DB.
- **RE-RESEARCH** — rows below threshold whose politician resolved. Each line includes an `exclude-urls=` list (the sources that failed verification).
- **UNRESOLVED→REVIEW** / **SKIP** — politician not in `essentials.politicians` (→ review queue), or `value=null` (dropped, not pushed).

### Bounded re-research — one pass only

For each **RE-RESEARCH** row, dispatch ONE `politician-stance-researcher` agent in **RE-RESEARCH MODE** for that single (politician, topic). In the dispatch prompt include:
- the same `--output-dir data/stance-research/[BATCH_ID]` (it appends to the same CSVs),
- `--exclude-urls <the failed URLs from that row>`,
- the failure summary from the verifier line, the politician's `politician_id`, and that topic's scale block (from the matching `/tmp/ev-stance-scales-*.txt`).

Run **at most one** re-research pass per row per batch. After those agents finish, **re-run the verifier dry** (same command) to see the updated partition. Rows still below threshold after this pass go to the review queue in STEP 4 — do not loop again.

---

## STEP 3 — Present Approval Summary

From the latest verifier run, show the user the verification outcome and the stance table:

```
## Research Results: [BATCH_ID]

Verification (threshold = 2 verified sources):
- ✅ auto-verified (push-ready):        N
- ♻️  verified after re-research:        N
- 🚩 review queue (insufficient / unresolved): N
- ⏭️  skipped (value blank):             N

### Stance Overview

| Politician | Topic | Value | Assigned stance (value → text) | Verified sources | Reasoning (preview) |
|-----------|-------|-------|-------------------------------|------------------|-------------------|
| Name 1 | healthcare | 2 | "public option alongside private insurance" | 2 | "Cosponsored the Public Option... — best matches stance 2" |
| Name 1 | abortion | 1 | "legal, accessible, publicly funded at all stages" | 3 | "Voted against every restrict... — best matches stance 1" |
| ...    | ...        | ... | ... | ... | ... |

Batch dir: `ev-accounts/backend/data/stance-research/[BATCH_ID]/`
```

- The **Assigned stance** column is the text of the stance the agent's `value` selected — look it up from `/tmp/ev-stance-scales-*.txt`. Value next to its real stance text makes scale inversions (a `1` that should be a `5`) obvious at a glance.
- **Verified sources** is the count from the verifier (rows below threshold are the 🚩 ones).
- List the 🚩 review-queue rows separately with the failure reason per source (`snippet_not_found` / `name_not_present` / `url_broken`) so the user sees *why* each was held back.

Then ask:
> "Review above. You can:
> 1. **Approve & push** — write the verified rows to the DB; the rest go to the review queue
> 2. **Reject specific rows** — name politician/topic pairs to drop before pushing
> 3. **Edit values** — e.g. 'change Sherman/healthcare to 3' (edit `stances.csv` in the batch dir; a value change doesn't need re-verification, but the reasoning should still match the new stance)
> 4. **Skip DB push** — keep the CSVs only
>
> What would you like to do?"

For rejects/edits, modify `stances.csv` in the batch dir before STEP 4.

---

## STEP 4 — Push to database (gated by verification)

The push is the **same verifier script** with `--apply`. It re-verifies, then in one atomic-per-row pass writes the verified rows to production and everything else to the review queue — you do not hand-write any SQL:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && \
  npx tsx scripts/verify-stance-research.ts --dir data/stance-research/[BATCH_ID] --threshold 2 --apply --re-researched
```

(`--re-researched` stamps review rows as having had their one re-research attempt — include it only after STEP 2.5's re-research pass ran.) Per PUSH row it upserts `inform.politician_answers` + `inform.politician_context` (storing the **verified** source URLs) and replaces `inform.politician_context_evidence` with the verified snippets, then stamps `last_stances_researched_at`. Per below-threshold / unresolved row it upserts `inform.stance_research_review`.

If the user chose to **reject** or **edit** rows in STEP 3, apply those to `stances.csv` first (delete rejected rows; change values). The runner only pushes what's in the CSVs and still verifies.

Report what the script printed:
> "Pushed [N] verified stances for [politicians]. [E] snippets persisted as evidence. [R] rows sent to the review queue. [M] politicians stamped. CSVs at `data/stance-research/[BATCH_ID]/`."

---

## STEP 5 — Surface the review queue

Show the rows that didn't clear the gate so a human can act on them:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT full_name_raw, topic_key, proposed_value, verified_source_count, threshold, status
  FROM inform.stance_research_review
  WHERE batch_id = \$1 AND status = 'pending'
  ORDER BY full_name_raw, topic_key
\`, [process.argv[2]]);
for (const r of rows) console.log('  ' + r.status + '\t' + r.full_name_raw + '\t' + r.topic_key + '\tvalue=' + (r.proposed_value ?? 'null') + '\tverified=' + r.verified_source_count + '/' + r.threshold);
console.log('\n' + rows.length + ' rows pending review for this batch.');
await pool.end();
" -- "[BATCH_ID]"
```

These rows are **not** in production. Each carries the full per-snippet verdict audit trail in its `evidence` jsonb column, so the failure mode is visible without re-running anything. Resolving them — manual research, creating a missing politician record, or rejecting — is a separate human/admin step (a future admin UI will surface them; for now they're queryable here).

---

## ERROR HANDLING

- If an agent fails or times out, report which politician failed and offer to retry just that one
- If the CSVs can't be written, fall back to showing both (stances + evidence) in conversation and offer to retry the file write
- If the verifier can't fetch a URL (paywall, timeout, 4xx/5xx) it counts as unverified — that's expected, not an error; the row falls back to re-research or the review queue
- If `--apply` fails for a specific row, the script logs it and continues; re-running `--apply` is safe (idempotent upserts)
- Never lose data — the batch-dir CSVs are the source of truth; verified rows push to production, the rest go to the review queue (nothing is silently dropped except `value=null` rows)

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
3. Runs the same deterministic verifier as normal mode, then pushes
   proposed values to `admin_upsert_stance_proposal` instead of direct
   inserts on `politician_context`.
4. Auto-approves each **verified** proposal via
   `admin_approve_stance_proposal` and auto-**rejects** any proposal
   that is null-value or falls below the verification threshold (the
   workflow's human gate is bypassed by this automated verify-gate —
   the audit trail in `topic_rewrites` provides rollback safety).
5. Skips the STEP 3 approval summary prompt (the verifier decides
   approve vs reject — nothing to hand-approve).

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

Produce the SAME two CSVs as normal mode, joined on (full_name, topic_key):

stances.csv:  full_name,politician_id,topic_key,value,reasoning
evidence.csv: full_name,topic_key,source_url,snippet,snippet_index

Write both to --output-dir [ABSOLUTE_PATH]/ev-accounts/backend/data/stance-research/[BATCH_ID]
(e.g. BATCH_ID = YYYY-MM-DD-rewrite-[TOPIC_KEY]).

Important:
- Include the politician_id UUID from the batch input on every stances.csv row — the apply step keys on it.
- The snippet rule applies here too: every source_url in evidence.csv needs a verbatim 25–300 word snippet. The verifier runs on rewrite output, and proposals whose new-scale value isn't backed by ≥2 verified sources are auto-rejected.
```

## STEP 2 (rewrite mode) — Collect results (same as normal mode)

Same as STEP 2 in normal mode: the batch dir holds `stances.csv` + `evidence.csv` (stances.csv carries the politician_id from the proposals batch).

## STEP 3 (rewrite mode) — SKIPPED

No human approval prompt. In rewrite mode the verifier decides:
verified proposals are auto-approved, unverified/null ones auto-rejected
(STEP 4). The audit trail lives in the `topic_rewrites` table and every
change is reversible (old topic row stays with is_live=false for easy
rollback).

## STEP 4 (rewrite mode) — Push proposals, auto-approve, and auto-reject

Every pending proposal must resolve before `admin_mark_rewrite_publish_ready`
will succeed — any proposal left `pending` blocks publish with a
`PROPOSALS_PENDING` error. So every proposal is either **approved** (verified)
or **rejected** (unverified / null) here.

The same deterministic verifier from normal-mode STEP 2.5 runs first. Each
re-evaluated row resolves to one of three outcomes:
1. **Value present AND ≥ threshold (2) verified sources** → upsert proposal (with the verified source URLs) → auto-approve.
2. **Value present but below threshold** → auto-reject as unverified (the new-scale score isn't grounded).
3. **Null value** → auto-reject with an insufficient-evidence note.

### 4a. Verify, then apply, in one script

The apply script imports the verifier directly so verification and the
proposal RPCs happen in one pass. Write it to
`ev-accounts/backend/scripts/apply-rewrite-[TOPIC_KEY].ts` for a permanent
audit trail. (Note: evidence snippets are NOT persisted to
`politician_context_evidence` in rewrite mode — that table FKs to live
`politician_context`, which the new topic doesn't have until publish. The
verified source URLs ride along on the proposal.)

```typescript
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { pool } from '../src/lib/db.js';
import { parseStancesCsv, parseEvidenceCsv } from '../src/lib/stanceResearchCsv.js';
import { verifyEvidence, createPageFetcher, type PoliticianNames } from '../src/lib/researchVerifier.js';
import { fetchPageContent } from '../src/lib/fetchPageContent.js';

const REWRITE_ID = '[REWRITE_UUID]';        // orchestrator substitutes
const ACTOR_ID = '[ACTOR_UUID]';             // same id that created the rewrite
const THRESHOLD = 2;
const DIR = join(process.cwd(), 'data/stance-research/[BATCH_ID]');

const stances = parseStancesCsv(readFileSync(join(DIR, 'stances.csv'), 'utf8'));
const evidence = existsSync(join(DIR, 'evidence.csv'))
  ? parseEvidenceCsv(readFileSync(join(DIR, 'evidence.csv'), 'utf8'))
  : [];

const lastToken = (n: string) => n.trim().split(/\s+/).filter(Boolean).slice(-1)[0] ?? n;
const politicianNames: PoliticianNames = {};
for (const s of stances) politicianNames[s.full_name] = { fullName: s.full_name, lastName: lastToken(s.full_name) };
const idByName = new Map(stances.map(s => [s.full_name, s.politician_id]));

const scored = stances.filter(s => s.value !== null);
const nullRows = stances.filter(s => s.value === null);

const fetcher = createPageFetcher(fetchPageContent);
const { pushable, needsReResearch } = await verifyEvidence({
  stanceRows: scored, evidenceRows: evidence, fetcher, threshold: THRESHOLD, politicianNames,
});

let upserted = 0, approved = 0, rejected = 0;
const errors: string[] = [];

async function reject(pid: string, fullName: string, note: string) {
  try {
    await pool.query(`SELECT inform.admin_reject_stance_proposal($1::uuid,$2::uuid,$3::uuid,$4::text)`,
      [REWRITE_ID, pid, ACTOR_ID, note]);
    rejected++; console.log('REJECT ' + fullName);
  } catch (e: any) { errors.push('REJECT ' + fullName + ': ' + e.message); }
}

// 1. Verified → upsert (verified source URLs) + approve
for (const row of pushable) {
  const pid = idByName.get(row.stance.full_name)!;
  const sources = row.verifiedSources.map(s => s.url);
  try {
    await pool.query(`SELECT inform.admin_upsert_stance_proposal($1::uuid,$2::uuid,$3::numeric,$4::text,$5::text[])`,
      [REWRITE_ID, pid, Number(row.stance.value), row.stance.reasoning, sources]);
    upserted++; console.log('UPSERT ' + row.stance.full_name + ' value=' + row.stance.value);
  } catch (e: any) { errors.push('UPSERT ' + row.stance.full_name + ': ' + e.message); continue; }
  try {
    await pool.query(`SELECT inform.admin_approve_stance_proposal($1::uuid,$2::uuid,$3::uuid,$4::text)`,
      [REWRITE_ID, pid, ACTOR_ID, 'auto-approved (verified ' + sources.length + ' sources) by research-stances rewrite mode']);
    approved++; console.log('APPROVE ' + row.stance.full_name);
  } catch (e: any) { errors.push('APPROVE ' + row.stance.full_name + ': ' + e.message); }
}

// 2. Below threshold → reject as unverified
for (const row of needsReResearch) {
  const pid = idByName.get(row.stance.full_name);
  if (!pid) { errors.push('NO_ID ' + row.stance.full_name); continue; }
  await reject(pid, row.stance.full_name,
    'Unverified under new scale: only ' + row.verifiedSources.length + '/' + THRESHOLD + ' sources verified. ' + (row.stance.reasoning || ''));
}

// 3. Null value → reject as insufficient evidence
for (const s of nullRows) {
  const pid = idByName.get(s.full_name);
  if (!pid) { errors.push('NO_ID ' + s.full_name); continue; }
  await reject(pid, s.full_name, 'Insufficient evidence under new scale: ' + (s.reasoning || 'agent returned null'));
}

console.log('\nSUMMARY: upserted=' + upserted + ' approved=' + approved + ' rejected=' + rejected + ' errors=' + errors.length);
if (errors.length) { errors.forEach(e => console.log('  ' + e)); process.exitCode = 1; }
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
