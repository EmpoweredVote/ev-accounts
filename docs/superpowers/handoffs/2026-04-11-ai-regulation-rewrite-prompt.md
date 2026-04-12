# AI Regulation Rewrite — Fresh Session Handoff Prompt

**Use this prompt to start a fresh Claude Code session dedicated to
running the first real Plan D topic rewrite (ai-regulation).**

Copy everything below the separator into the new conversation.

---

Execute the ai-regulation topic rewrite using the Plan D auto-approved
workflow. This is the first real run of the machinery built in Plan D
(see `docs/superpowers/plans/2026-04-11-plan-d-topic-rewrite-workflow.md`).
The drafts and audit have already been written and approved.

## What you're executing

The rewrite has 6 sequential steps. Steps 1, 2, 3, 5, and 6 are instant
psql calls. Step 4 is ~2 hours of agent research.

**Before step 1:** read `docs/superpowers/drafts/2026-04-11-compass-rewrite-drafts.md`
section "## 1. ai-regulation" to get the exact new title, short_title,
question_text, and 5 stance texts. Paste those into the SQL in step 1.

### Context you need

- Chris's user UUID (for the `p_actor_id` argument):
  `854fbc06-40fc-458d-b523-20ef8e5ad1b2`
- Working directory for psql:
  `/Users/chrisandrews/Documents/GitHub/ev-accounts/backend`
  (must `set -a && source .env && set +a` to get `DATABASE_URL`)
- Production Supabase project ID: `kxsdzaojfaibhuzmclfq` (E.V Backend).
  Verify BEFORE running anything with:
  `echo "$DATABASE_URL" | sed -E 's|.*postgres\.([a-z0-9]+):.*|\1|'`
- Never echo `DATABASE_URL` directly — it contains the prod password.

### Step 1 — Create the rewrite

```sql
SELECT inform.admin_create_topic_rewrite(
  'ai-regulation',                                  -- p_topic_key
  '854fbc06-40fc-458d-b523-20ef8e5ad1b2'::uuid,     -- p_actor_id
  'Artificial Intelligence Oversight',              -- p_new_title
  'AI Oversight',                                   -- p_new_short_title
  'How much should government oversee artificial intelligence development and deployment?',  -- p_new_question_text
  '[
    {"value": 1, "text": "Allow AI companies to develop and deploy technology freely without government interference"},
    {"value": 2, "text": "Suggest AI safety guidelines but let companies choose whether to follow them"},
    {"value": 3, "text": "Require AI developers to disclose risks and be held responsible when their systems cause harm"},
    {"value": 4, "text": "Require safety testing and ban high-risk AI uses in areas like hiring, healthcare, and policing"},
    {"value": 5, "text": "Impose strict approval requirements and ban AI systems that could cause serious harm"}
  ]'::jsonb,                                         -- p_new_stances
  'First real Plan D rewrite; drafts committed in docs/superpowers/drafts/2026-04-11-compass-rewrite-drafts.md'  -- p_notes
);
```

Save the returned UUID — that's the `rewrite_id` you'll use for every
remaining step. Call it `$REWRITE_ID` in the next steps.

### Step 2 — Submit for framing review

```sql
SELECT inform.admin_submit_rewrite_for_framing_review('$REWRITE_ID'::uuid);
```

### Step 3 — Approve framing (auto-approve, seeds proposals)

```sql
SELECT inform.admin_approve_rewrite_framing(
  '$REWRITE_ID'::uuid,
  '854fbc06-40fc-458d-b523-20ef8e5ad1b2'::uuid
);
```

Expected return: integer count of seeded proposals. For ai-regulation
this should be **29** (the current count of politicians with existing
stances on the topic).

Verify with:
```sql
SELECT count(*) FROM inform.topic_rewrite_stance_proposals
WHERE rewrite_id = '$REWRITE_ID'::uuid;
```

### Step 4 — Run research-stances in rewrite mode

Invoke the skill:

```
/research-stances --rewrite-id $REWRITE_ID
```

The skill will:
1. Fetch rewrite detail (old + new framing + 29 pending proposals)
2. Dispatch politician-stance-researcher agents in batches of 3–5 to
   re-evaluate each politician under the new scale (using the agent's
   REWRITE RE-EVALUATION MODE section)
3. Write the CSV to
   `ev-accounts/backend/data/stance-research/YYYY-MM-DD-rewrite-ai-regulation.csv`
4. Upsert each proposed value via `admin_upsert_stance_proposal`
5. Auto-approve each proposal via `admin_approve_stance_proposal` using
   `854fbc06-40fc-458d-b523-20ef8e5ad1b2` as the actor id
6. Report per-politician outcomes

This step is the only long-running one (~2 hours for 29 politicians).
Monitor for: agents that fail, insufficient-evidence skips, politicians
whose position genuinely doesn't map onto the new scale.

**Gotcha to watch for:** the agent prompt template in SKILL.md STEP 1
(rewrite mode) needs real values substituted for the bracketed
placeholders — `[TOPIC_KEY]`, `[old_stance_1]`, etc. If the skill
fails on first run because the prompt template is passed to the agent
with literal `[placeholder]` text, that's the skill bug — fix it
inline before retrying.

### Step 5 — Mark publish-ready

After step 4 completes with all 29 proposals approved:

```sql
SELECT inform.admin_mark_rewrite_publish_ready('$REWRITE_ID'::uuid);
```

This RPC will fail with `PROPOSALS_PENDING: N proposals still need
review` if any proposals didn't get approved. Investigate those and
either approve them via the admin UI or reject them before re-running.

### Step 6 — Publish atomically

```sql
SELECT inform.admin_publish_topic_rewrite(
  '$REWRITE_ID'::uuid,
  '854fbc06-40fc-458d-b523-20ef8e5ad1b2'::uuid
);
```

Expected return: JSON like `{"approved_copied": 29, "rejected_skipped": 0}`.

At this point:
- New topic row has `is_live=true`, `went_live_at=now()`, version 2
- Old topic row has `is_live=false`, version 1 (kept for audit/rollback)
- 29 rows copied to `politician_answers` + `politician_context` under
  the new `topic_id`
- `topic_rewrites.state = 'published'`

### Step 7 — Verify the publish

```sql
-- Both versions should be present; new is live
SELECT id, version, is_live, went_live_at, title
FROM inform.compass_topics
WHERE topic_key = 'ai-regulation'
ORDER BY version;

-- New version has all 29 answers
SELECT COUNT(*) AS new_answers
FROM inform.politician_answers pa
JOIN inform.compass_topics t ON t.id = pa.topic_id
WHERE t.topic_key = 'ai-regulation' AND t.is_live = true;

-- Old version still has the original 29 (append-only, kept for audit)
SELECT COUNT(*) AS old_answers
FROM inform.politician_answers pa
JOIN inform.compass_topics t ON t.id = pa.topic_id
WHERE t.topic_key = 'ai-regulation' AND t.is_live = false;
```

Also hit the voter-facing API and confirm the new framing is showing:

```bash
curl -s "https://api.empowered.vote/api/compass/topics" | python3 -c "
import sys, json
data = json.load(sys.stdin)
hits = [t for t in data if t.get('topic_key') == 'ai-regulation']
print(f'live rows returned: {len(hits)}')
print(json.dumps(hits[0] if hits else 'MISSING', indent=2))
"
```

Should return exactly one live row with the new `title` ("Artificial
Intelligence Oversight") and new `question_text`.

## Rollback procedure if something looks wrong

If the publish lands but the results are bad:

```sql
BEGIN;
-- Flip new back to inactive, old back to live
UPDATE inform.compass_topics SET is_live = true
  WHERE topic_key = 'ai-regulation' AND version = 1;
UPDATE inform.compass_topics SET is_live = false
  WHERE topic_key = 'ai-regulation' AND version = 2;
-- Mark the rewrite as cancelled so the next run doesn't blocked by "open rewrite"
UPDATE inform.topic_rewrites SET state = 'cancelled'
  WHERE id = '$REWRITE_ID'::uuid;
COMMIT;
```

This restores v1 to live immediately. The v2 row stays in the DB but
hidden. `politician_answers` for v2 are still there too — they're just
not queried because v1 is the live version. No data lost.

## When you're done

Report back in conversation:
1. Whether publish succeeded
2. Count of proposals approved vs. skipped
3. Any politicians whose reasoning looked weak on manual spot-check
4. Anything the skill + agent handled poorly that needs fixing before
   the next rewrite (housing)

If this rewrite ships cleanly, the next rewrites in the queue are:
housing → taxes → (immigration + deportation together) → healthcare.
Each follows the same 6-step pattern with different drafts pasted into
step 1.
