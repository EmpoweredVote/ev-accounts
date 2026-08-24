# NC Stance Campaign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: use `superpowers:executing-plans` to work this plan
> task by task. Steps use checkbox (`- [ ]`) syntax for tracking. Do **not** use
> `subagent-driven-development` for the research tasks — the research agents are dispatched *by*
> Task 3+ and the skill mandates one at a time.

**Goal:** Give the 170 seated NC General Assembly members and the 32 NC wave 2b local
officeholders evidenced compass coverage — stance values with public reasoning, plus captured
quotes held as drafts — without confabulating a single chair.

**Architecture:** One `politician-stance-researcher` agent per person, dispatched strictly one at a
time, writing an RFC-4180 CSV per batch. Each batch runs research → mechanical QA → value-change
diff → human approval → guarded DB write → ledger entry. Quotes are *captured now* and *promoted
later*: they land in `essentials.quotes` as drafts (`readrank_selected = false`) and stay there
until the season 2 ladder revision settles.

**Tech Stack:** Supabase Postgres (`inform.*`, `essentials.*`), the `research-stances` skill and its
`politician-stance-researcher` agent, `psql` for guarded writes, Node/Python gate scripts in
`backend/scripts/`.

**Spec:** This file is self-contained. Supporting context:
`.planning/todos/2026-08-23-nc-wave-2b-banners-headshots-stances.md` (wave 2b scope and standards),
`CLAUDE.md` (compass chair rules, migration rules), and the compass ladder findings document
(the season 2 driver) at https://claude.ai/code/artifact/6b0a08de-90cf-4a39-bc67-29eca92b5c21.

---

## Global Constraints

Every task inherits these. They are not suggestions.

1. **The bar: every stance needs a CHAIR the evidence names AND a source that supports it,
   independently.** If two adjacent chairs both fit, skip the row. A blank spoke is correct. An
   empty compass is honest; a confabulated one is a false statement about a real person.
2. **Never assume polarity.** Read every ladder from `inform.compass_stances` at run time. The
   corpus convention is chair 1 = maximum government action, but **AI Oversight and Tariffs run the
   other way**, and Residential Zoning, Growth and Development Pace and Government Deference are
   off-axis entirely.
3. **"The least extreme option the reasoning supports" is a TIEBREAKER, not evidence.** Reaching for
   it means the row is not yet evidenced. Leave it blank.
4. **No party inference, ever.** Party lives on `races.primary_party`, never on a person. A stance
   derived from party is a defect, not a shortcut.
5. **`inform.politician_context.reasoning` is VOTER-FACING** — it renders on the Essentials profile
   and the Compass via `Citations.jsx`. It must justify the value actually stored, in plain language.
   Never push a value without reasoning; never leave reasoning describing a different value.
6. **Dispatch ONE research agent at a time.** Parallel dispatch burns the shared WebSearch/Playwright
   quota and returns nothing usable. Wait for each CSV before dispatching the next.
7. **Resolve `politician_id` through `essentials.office_current_holder` joined to
   `essentials.offices` and `essentials.districts` — never by bare `full_name`.** NC has 52 seats
   titled `Senator` (50 state + 2 US) and the corpus has known cross-state homonyms.
   `essentials.offices.politician_id` was **dropped** in ADR 0002; any query selecting it is broken.
8. **Every DB write is dry-run first.** Wrap the body `BEGIN; … ROLLBACK;`, confirm the counts, then
   confirm the rollback actually reverted, then re-run with `COMMIT`.
9. **Quotes are captured but never promoted in this campaign.** Insert with
   `readrank_selected = false`. Do not run the audit → promote loop (`research-stances` STEP 4e/4f).
   Season 2 decides the picks.
10. **If any row deletion from `inform.politician_answers` becomes necessary**, it obliges a
    `-- @context-decision:` line and the guard from
    `backend/migrations/_templates/answer_delete_context_guard.sql` in the same migration.
    `npm run check:answer-delete-guards --prefix backend` enforces it.
11. **Chris's migration namespace is `CA_NNNN_*.sql`.** As of 2026-08-24 the claimed slots across
    all 21 remote refs are `CA_0001`–`CA_0012`, `CA_0015`, `CA_0016`. **Take `CA_0017`.** The gap at
    0013/0014 is not a free lunch — two authors taking a number before either pushes is invisible
    from any repo state, so do not fill gaps. Run `npm run check:migrations --prefix backend` after
    `git fetch origin`, and count within the namespace only; never read the shared max; never
    retro-rename. (This campaign writes through guarded upserts, not migrations, so a slot is needed
    only if a correction pass requires one.)
12. **`git fetch origin` before reading anything git-related.** Master moves under you.

### Measured facts (verified against prod 2026-08-24 — re-verify, do not re-derive)

| Fact | Value |
|---|---|
| NC House, `district_type = 'STATE_LOWER'` | 120 seated, all with `geo_id` |
| NC Senate, `district_type = 'STATE_UPPER'` | 50 seated, all with `geo_id` |
| US Senators (excluded — already stanced) | 2, `district_type = 'NATIONAL_UPPER'` |
| Wave 2b locals | 32 (Durham 15, Asheville 7, Buncombe 10) |
| State scale, `role_scope = 'state'` | **28 topics** (an older note said 26 — it was stale) |
| Local scale, `role_scope = 'local'` | **22 topics** |
| Existing NC stance rows | 326, across 23 people, **all federal or statewide** |
| Existing rows for the 202 people in scope | **0** |

Ceiling is 5,464 assessments. **Expect roughly 600–750 real rows.** Comparable waves: WI 144 people
→ 504 rows (3.5 each), AZ 140 → 548 (3.9), Austin 11 → 58 (5.3), Colorado Springs 10 → 41 (4.1).
A batch that returns far more than ~5 rows per person is a red flag, not a win — check it for
party-inferred or direction-only chairs before pushing.

---

## File Structure

```
.planning/workstreams/nc-stance-campaign/
  PLAN.md                    <- this file
  LEDGER.md                  <- append-only batch record; created in Task 1
backend/data/stance-research/
  2026-08-24-nc-pilot.csv            <- Task 3 output
  2026-08-24-nc-pilot.csv.bundle.json
  2026-MM-DD-nc-<cohort>-<nn>.csv    <- one per batch, Task 5+
  nc-campaign/
    written-<batch>.json     <- exact (politician_id, topic_id, value) written per batch
```

**Why the ledger exists.** `inform.politician_answers` and `inform.politician_context` have **no
timestamp columns**. Once a row is written there is no way to ask the database "what did batch 7
write?" The season 2 revision will need exactly that question answered. `written-<batch>.json` is
the only record, so it is written in the same task as the DB push, never later.

---

## Task 1: Stand up the ledger and confirm the roster

**Files:**
- Create: `.planning/workstreams/nc-stance-campaign/LEDGER.md`
- Create: `backend/data/stance-research/nc-campaign/` (directory)

**Interfaces:**
- Produces: `LEDGER.md` with a table every later task appends one row to.

- [ ] **Step 1: Re-verify the roster counts against prod**

Run this read (Supabase MCP, project `kxsdzaojfaibhuzmclfq`):

```sql
SELECT d.district_type, count(*) AS seated,
       count(*) FILTER (WHERE EXISTS (
         SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = och.politician_id
       )) AS already_stanced
FROM essentials.office_current_holder och
JOIN essentials.offices o ON o.id = och.office_id
JOIN essentials.districts d ON d.id = o.district_id
WHERE och.politician_id IS NOT NULL AND lower(d.state) = 'nc'
  AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
GROUP BY d.district_type;
```

Expected: `STATE_LOWER` 120 seated / 0 stanced, `STATE_UPPER` 50 seated / 0 stanced.
If `already_stanced` is non-zero, someone has worked this cohort since 2026-08-24 — stop and
reconcile before researching, or you will overwrite curated values.

- [ ] **Step 2: Re-verify both scales and capture the topic UUIDs**

```sql
SELECT tr.role_scope, t.id, t.topic_key, t.question_text
FROM inform.compass_topic_roles tr
JOIN inform.compass_topics t ON t.id = tr.topic_id AND t.is_live = true
WHERE tr.role_scope IN ('state','local')
ORDER BY tr.role_scope, t.topic_key;
```

Expected: 28 rows for `state`, 22 for `local`. **If the counts differ from that, season 2 has
already landed — stop and re-read this plan's assumptions before continuing.**

- [ ] **Step 3: Create the ledger**

Write `.planning/workstreams/nc-stance-campaign/LEDGER.md`:

```markdown
# NC Stance Campaign — Batch Ledger

`inform.politician_answers` has no timestamps. This file is the only record of what each batch
wrote. Append one row per batch, in the same task that pushes it. Never backfill from memory.

| Batch | Date | Cohort | People | Rows pushed | Quotes drafted | CSV | written-*.json |
|---|---|---|---|---|---|---|---|
```

- [ ] **Step 4: Create the write-record directory**

```bash
mkdir -p backend/data/stance-research/nc-campaign
```

- [ ] **Step 5: Commit**

```bash
git add .planning/workstreams/nc-stance-campaign/
git commit -F- -- .planning/workstreams/nc-stance-campaign/ <<'MSG'
docs(nc): open the stance campaign ledger

politician_answers and politician_context carry no timestamp columns, so
there is no way to ask the database what a given batch wrote. The ledger
and the per-batch written-*.json files are the only record, which the
season 2 ladder revision will need.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
```

---

## Task 2: Build the two topic payloads

**Files:**
- Create: `backend/data/stance-research/nc-campaign/scale-state.txt`
- Create: `backend/data/stance-research/nc-campaign/scale-local.txt`

**Interfaces:**
- Produces: two plain-text blocks pasted verbatim into every research agent prompt. Task 3+ consume
  them.

- [ ] **Step 1: Fetch every live stance for both scales**

```sql
SELECT tr.role_scope, t.topic_key, t.id AS topic_id, t.question_text, s.value, s.text
FROM inform.compass_topic_roles tr
JOIN inform.compass_topics t ON t.id = tr.topic_id AND t.is_live = true
JOIN inform.compass_stances s ON s.topic_id = t.id
WHERE tr.role_scope IN ('state','local')
ORDER BY tr.role_scope, t.topic_key, s.value;
```

- [ ] **Step 2: Format each scope into this exact shape**

One block per topic, blank line between topics:

```
<topic_key> (id: <uuid>)
Question: "<question_text>"
  1 = "<stance text for value 1>"
  2 = "<stance text for value 2>"
  3 = "<stance text for value 3>"
  4 = "<stance text for value 4>"
  5 = "<stance text for value 5>"
```

Write the `state` blocks to `scale-state.txt` (28 topics) and `local` to `scale-local.txt` (22).

- [ ] **Step 3: Verify the files**

```bash
grep -c "^  1 = " backend/data/stance-research/nc-campaign/scale-state.txt   # expect 28
grep -c "^  1 = " backend/data/stance-research/nc-campaign/scale-local.txt   # expect 22
```

If either count is wrong, a topic lost a rung in transcription. Rebuild it — do not hand-patch.

- [ ] **Step 4: Commit**

```bash
git add backend/data/stance-research/nc-campaign/scale-*.txt
git commit -F- -- backend/data/stance-research/nc-campaign/ <<'MSG'
chore(nc): freeze the season 1 state and local ladders for the campaign

28 state topics and 22 local, captured verbatim so every research agent in
the campaign scores against identical text. Re-fetch rather than reuse if
the season 2 revision lands mid-campaign.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
```

---

## Task 3: Pilot — three people, one from each cohort

The pilot exists to measure yield, runtime and defect rate before committing 199 more agents.
Do not skip it and do not widen it.

**Files:**
- Create: `backend/data/stance-research/2026-08-24-nc-pilot.csv`

**Interfaces:**
- Consumes: `scale-state.txt`, `scale-local.txt` from Task 2.
- Produces: one CSV with columns
  `full_name,topic_key,value,reasoning,source_url_1,source_url_2,source_url_3,quote_text,quote_deidentified,editor_note`

- [ ] **Step 1: Pick the three, and record why**

Select by seat, not by fame — a pilot stacked with leadership overstates yield:
one `STATE_LOWER` member, one `STATE_UPPER` member, one wave 2b local. Prefer people whose
districts cover Durham or Buncombe so the pilot shares geography with wave 2b. Record the three
names, `politician_id`s, seats and districts in the batch notes before dispatching.

```sql
SELECT p.id AS politician_id, p.full_name, d.district_type, d.label, d.district_id
FROM essentials.office_current_holder och
JOIN essentials.offices o ON o.id = och.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.id = och.politician_id
WHERE lower(d.state) = 'nc' AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
ORDER BY d.district_type, d.label
LIMIT 40;
```

- [ ] **Step 2: Dispatch the first agent — and only the first**

Use the Agent tool with `subagent_type: "politician-stance-researcher"`. Build the prompt from the
`research-stances` STEP 1 template, with these campaign-specific changes:

- Paste `scale-state.txt` (state members) or `scale-local.txt` (the local) into the
  `TOPIC SCALE REFERENCE` slot. Never paste both — an agent given the wrong scale will invent
  `topic_key`s that do not exist for that person's role scope.
- Add verbatim: *"Capture quotes where the three gates pass, but understand these quotes will be
  stored as drafts and will not go live in this campaign. Do not optimise quote choice for Read &
  Rank selection."*
- Add verbatim: *"A blank spoke is the correct answer whenever two adjacent chairs both fit, or
  when the evidence establishes only a direction (pro/anti) rather than a magnitude. Direction
  alone under-determines which chair applies. Do not fill a spoke to raise your count."*
- Output path: `backend/data/stance-research/2026-08-24-nc-pilot.csv`.

Wait for it to finish. Confirm the CSV exists and has rows before dispatching the second.

- [ ] **Step 3: Dispatch the second agent, then the third**

Same template, correct scale per person, same output file (append). One at a time.

- [ ] **Step 4: Validate each payload the moment it returns**

```bash
cd backend && py scripts/validate-stance-quotes.py data/stance-research/2026-08-24-nc-pilot.csv
```

**A structural pass is NOT sufficient.** Hand-check, for at least five rows: does the quote actually
belong to this person, does the `reasoning` name a real instrument/act/vote, and does the chosen
chair's text match what the reasoning claims?

- [ ] **Step 5: Run the mechanical QA and bundle**

```bash
cd backend && node ../.claude/skills/research-stances/scripts/build-and-check.mjs \
  --csv data/stance-research/2026-08-24-nc-pilot.csv
```

Fix every **high** finding in the CSV and re-run until clean. Do not proceed with high findings.

- [ ] **Step 6: Run the chair-evidence gate**

```bash
cd backend && node scripts/audit-chair-evidence.mjs --check <rollback.json>
```

It fails any row whose reasoning names no instrument, act or vote. Every failure is either a rewrite
of the reasoning to cite the real instrument, or a blank — never a softened sentence that keeps the
chair.

---

## Task 4: Calibrate from the pilot, then decide batch size

- [ ] **Step 1: Compute and report the measured numbers**

Report all five, measured, not estimated:
rows per person · topics attempted vs pinned · wall-clock minutes per agent ·
high-severity mechanical findings per person · chair-gate failures per person.

- [ ] **Step 2: Compare against the expected band**

Expected is 3.5–5.3 rows per person. **Above ~7 is a red flag** — sample five rows and check for
direction-only chairs and party inference before trusting the batch.

- [ ] **Step 3: Present the pilot to the user for sign-off**

Show the stance overview table and the value-change diff (all rows should be **NEW**; anything
already carrying a value means the roster check in Task 1 missed something). Get explicit approval
before any write. Then push the pilot using the Task 5 procedure.

- [ ] **Step 4: Set the batch size and write it into the ledger header**

Choose so one batch is a reviewable sitting — 10–20 people for state members, the 32 locals split
by body (Durham 15, Asheville 7, Buncombe 10).

---

## Task 5: The repeating batch cycle

Repeat until all 202 are done. **Each batch is one pass of every step below.** Never let research
run ahead of pushing — an unpushed CSV backlog is how a campaign loses track of what is real.

**Files (per batch):**
- Create: `backend/data/stance-research/2026-MM-DD-nc-<cohort>-<nn>.csv`
- Create: `backend/data/stance-research/nc-campaign/written-<batch>.json`
- Modify: `.planning/workstreams/nc-stance-campaign/LEDGER.md`

- [ ] **Step 1: Research** — dispatch agents one at a time, correct scale per person, into one CSV.

- [ ] **Step 2: Validate + mechanical QA + chair gate** — exactly Task 3 steps 4–6.

- [ ] **Step 3: Resolve IDs through the seat, never the name**

```sql
SELECT p.id AS politician_id, p.full_name, o.title, d.district_type, d.label
FROM essentials.office_current_holder och
JOIN essentials.offices o ON o.id = och.office_id
JOIN essentials.districts d ON d.id = o.district_id
JOIN essentials.politicians p ON p.id = och.politician_id
WHERE lower(d.state) = 'nc' AND p.full_name = ANY($1::text[]);
```

Any name that returns 0 rows or >1 row is **held**, not guessed. Report it and move on.

- [ ] **Step 4: Value-change guard**

```sql
SELECT p.full_name, t.topic_key, a.value AS existing_value
FROM inform.politician_answers a
JOIN essentials.politicians p ON p.id = a.politician_id
JOIN inform.compass_topics t ON t.id = a.topic_id
WHERE a.politician_id = ANY($1::uuid[]);
```

Split into **NEW** (push with approval), **unchanged** (no-op), **CHANGE** (hold for explicit
per-row sign-off — never auto-push a value that overwrites a curated one).

- [ ] **Step 5: Dry run the write**

Build the upsert as a single statement whose `VALUES` list carries the expected `full_name`
alongside each `politician_id`, and join on both, so a wrong id drops the row instead of seating the
wrong person:

```sql
BEGIN;
WITH v(pid, expected_name, tid, val, reasoning, sources) AS (VALUES
  ('<uuid>'::uuid, 'Full Name', '<topic uuid>'::uuid, 3::numeric, 'reasoning text', ARRAY['https://…'])
  -- one row per stance
), ok AS (
  SELECT v.* FROM v JOIN essentials.politicians p ON p.id = v.pid AND p.full_name = v.expected_name
), ins_a AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT pid, tid, val FROM ok
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
), ins_c AS (
  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT pid, tid, reasoning, sources FROM ok
  ON CONFLICT (politician_id, topic_id)
  DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources
  RETURNING 1
)
SELECT (SELECT count(*) FROM ins_a) AS answers,
       (SELECT count(*) FROM ins_c) AS contexts,
       (SELECT count(*) FROM v)     AS expected;
ROLLBACK;
```

`answers`, `contexts` and `expected` must all be equal. If `answers < expected`, a name did not
match its id — fix it, do not force it.

- [ ] **Step 6: Confirm the rollback reverted, then commit the write**

Re-run the value-change guard query. It must show the pre-write state. Only then re-run the
statement with `COMMIT` in place of `ROLLBACK`.

- [ ] **Step 7: Insert the captured quotes as DRAFTS**

Use the `research-stances` STEP 4d script unchanged **except** that `readrank_selected` stays
`false` for every row. Do not run STEP 4e (audit) or 4f (promote) — season 2 owns those.

- [ ] **Step 8: Write the ledger record**

Write `backend/data/stance-research/nc-campaign/written-<batch>.json` as an array of
`{politician_id, full_name, topic_id, topic_key, value}` — exactly what was committed, not what was
proposed. Then append one row to `LEDGER.md`.

- [ ] **Step 9: Commit the batch**

```bash
git add backend/data/stance-research/ .planning/workstreams/nc-stance-campaign/LEDGER.md
git commit -F- -- backend/data/stance-research/ .planning/workstreams/nc-stance-campaign/ <<'MSG'
feat(nc-stances): batch <nn> — <cohort>, <N> people, <R> rows

<one line on what the evidence was: roll calls, local press, official
statements — and what the blank rate was>

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>
MSG
```

Use an explicit pathspec on `git commit`. Parallel sessions sweep each other's staged files in both
directions, and staging alone is not enough protection.

---

## Task 6: Close the campaign

- [ ] **Step 1: Verify the end state, not the delta**

```sql
SELECT d.district_type, count(DISTINCT och.politician_id) AS seated,
       count(DISTINCT och.politician_id) FILTER (WHERE EXISTS (
         SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = och.politician_id)) AS stanced,
       (SELECT count(*) FROM inform.politician_answers pa2
        JOIN essentials.office_current_holder o2 ON o2.politician_id = pa2.politician_id
        WHERE o2.office_id = och.office_id) AS rows_total
FROM essentials.office_current_holder och
JOIN essentials.offices o ON o.id = och.office_id
JOIN essentials.districts d ON d.id = o.district_id
WHERE lower(d.state) = 'nc' AND och.politician_id IS NOT NULL
GROUP BY d.district_type;
```

- [ ] **Step 2: Confirm no orphaned context**

Every `politician_context` row must have a matching `politician_answers` row. A context without an
answer is an unpublished claim that will render the moment someone writes an answer for that pair.

```sql
SELECT count(*) FROM inform.politician_context c
WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                  WHERE a.politician_id = c.politician_id AND a.topic_id = c.topic_id);
```

Compare against the baseline recorded before the campaign started. It must not have grown.

- [ ] **Step 3: Record the outcome**

Update `.planning/todos/2026-08-23-nc-wave-2b-banners-headshots-stances.md` — sub-project 3 status,
measured rows, blank rate, and anything the campaign learned that changes the method.

- [ ] **Step 4: Hand the ledger to season 2**

The quote drafts and the `written-*.json` files are the season 2 work queue. State plainly in the
todo how many quote drafts are parked and where the list lives.

---

## Self-review notes

- **Spec coverage:** roster verification (T1), ladder capture (T2), pilot (T3), calibration (T4),
  the repeating cycle for all 202 (T5), close-out and orphan check (T6). Quote capture is in T5 s7;
  quote promotion is explicitly out of scope by Global Constraint 9.
- **Known gap, deliberate:** this plan does not fix the three defects in the `research-stances`
  skill file (dead `offices.politician_id` column in its roster and rewrite queries, bare-`full_name`
  matching at its STEP 4b). It routes around them. Fixing the skill is a separate task.
- **Season 2 collision:** if the ladder revision lands mid-campaign, Task 1 Step 2 catches it
  (topic counts move off 28/22). Stop rather than mixing scales within a cohort.
- **Season 2 machinery is already live (2026-08-24).** ADR 0004 (compass content versioning) shipped
  as `CA_0011`, `CA_0012`, `CA_0015`, `CA_0016`, adding a revision lifecycle and an admin review
  queue. This is the mechanism that will carry the ladder rewrites, and the `research-stances` skill
  has a matching `--rewrite-id` mode that re-scores existing rows against new framing via
  `inform.topic_rewrites` / `topic_rewrite_stance_proposals` instead of writing live data. **That is
  the intended path for re-scoring this campaign's rows when season 2 lands** — the ledger
  (`written-*.json`) supplies the politician/topic list to seed the proposals. Read ADR 0004 before
  starting any re-score, and note the skill's rewrite mode auto-approves proposals, so the audit
  trail rather than a human gate is what makes it reversible.
