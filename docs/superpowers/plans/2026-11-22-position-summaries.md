# Position Summaries Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A checked summary, in our own words with numbered citations, of where each Stage 5 person stands on a
topic, written into the draft season's `politician_context` and shown on the profile; plus the tooling for a
100-person local-officials pilot.

**Architecture:** A separate Stage 5 step after coding. Writer subagents (Claude) draft sentences that cite finding
ids; a TypeScript library numbers the citations, builds the reference list from the findings' URLs and lints the
draft mechanically; a Claude checker and two outside models (GPT, Gemini, via `opencode run`) judge each sentence;
a write tool stores passed summaries in `politician_context.reasoning`/`sources` with a `summary_sha256` marker
that lets the read path show a blank's summary.

**Tech Stack:** TypeScript (tsx, vitest, zod, pg) in `backend/`; Python 3 helpers in `backend/scripts/stage5/`;
Postgres migrations; React (`ev-ui`).

**Spec:** `docs/superpowers/specs/2026-11-22-position-summaries-and-local-officials-design.md`

## Global Constraints

- Every write goes to the **draft** season only (`assertDraftSeason`, `stage5Write.ts`); voters see it when Season 3 opens.
- Every sentence ends with one or more citations `[n]` / `[n, m]`, placed before the sentence's closing punctuation.
- 2–5 sentences. No rung, rung number or ladder wording. No party names (`namesParty`, `src/lib/partyLabels.ts`).
- "often", "consistently", "repeatedly" need ≥ 3 distinct cited findings; "more than once" needs ≥ 2.
- A seated person's summary must not point to the other side of the ladder (`topic-profile.json` `sides`).
- One failed sentence from any checker holds the whole summary. Outside-model errors, timeouts or unparseable output count as a fail.
- No database write without the runner's yes for that batch; migrations dry-run first, each step on its own yes.
- Migrations: one per file, slot from `npm run steward --prefix backend -- slot CA --purpose "..."`, old values recorded in the header, post-verify `DO $$` gate.
- Commit with an explicit pathspec: `git commit -F msg -- <paths>`.

## Review Focus

1. Two cited findings with the same URL (two roll calls on one bill page) must share one reference number, not two.
2. `reasoning` edited after the check (sha mismatch) must hide a blank's context again, not show unchecked text.
3. An outside model that returns prose around its JSON, an empty reply, or times out must yield `held`, never `passed`.
4. A person with 40+ findings on the topic: the writer input must stay bounded (most recent and most direct first) and the lint must still accept citations only from that person's findings.
5. A draft-season context row must not reach `getPoliticianContext` before the season opens, even with a valid `summary_sha256`.

Tests for each are named in the owning task (Tasks 3, 4, 7, 5, 4).

---

### Task 1: Migration — local evidence basis for gun-policy

**Files:**
- Create: `backend/migrations/CA_NNNN_gun_policy_local_evidence_basis_own_words.sql` (slot from the allocator)

- [ ] **Step 1:** Reserve the slot: `npm run steward --prefix backend -- slot CA --purpose "gun-policy local compass_topic_roles evidence_basis record -> own-words (local records never seat alone, ruling 2026-10-22)"`.
- [ ] **Step 2:** Write the file: precondition that exactly one row `(gun-policy, local)` exists with `evidence_basis = 'record'` (header records old value `record`); `UPDATE … SET evidence_basis = 'own-words'`; post-verify gate that the row reads `own-words` and the federal and state rows still read `record`.
- [ ] **Step 3:** Dry run: `node backend/scripts/dry-run-migration.mjs backend/migrations/CA_NNNN_….sql`. Expected: `DRY RUN OK`. Tamper control: change the precondition's expected value to `own-words`, watch it FAIL, revert.
- [ ] **Step 4:** 🛑 Ask the runner for the apply; then `node backend/scripts/apply-migration-file.mjs <file>`.
- [ ] **Step 5:** Commit.

### Task 2: Migration — `politician_context.summary_sha256`

**Files:**
- Create: `backend/migrations/CA_NNNN_politician_context_summary_sha256.sql`

- [ ] **Step 1:** Reserve a slot (purpose: "politician_context.summary_sha256: marks reasoning as a checked position summary").
- [ ] **Step 2:** `ALTER TABLE inform.politician_context ADD COLUMN IF NOT EXISTS summary_sha256 text CHECK (summary_sha256 IS NULL OR summary_sha256 ~ '^[0-9a-f]{64}$')`; `COMMENT ON COLUMN` saying what it marks and that the read compares it with `sha256(reasoning)`. Post-verify: column exists, every existing row NULL. No grant change (existing table grants cover it; state that in the header).
- [ ] **Step 3:** Dry run, as Task 1. Control: insert a row with `summary_sha256 = 'x'` inside the dry run and watch the CHECK fail.
- [ ] **Step 4:** 🛑 Runner's yes, then apply. Commit.

### Task 3: Summary library

**Files:**
- Create: `backend/scripts/lib/stage5Summary.ts`
- Test: `backend/scripts/lib/stage5Summary.test.ts`

**Interfaces:**
- Consumes: `Finding` type from `scripts/lib/sourceStore.ts`; `namesParty`, `shownSha256` from `stage5QuoteCheck.ts`; `Stage5Code` from `stage5Code.ts`.
- Produces:
  - `SummaryDraftSchema` (zod) → `SummaryDraft = { politician_id: string; topic_key: string; sentences: { text: string; cites: string[] /* finding ids */ }[] }`
  - `buildSummary(draft: SummaryDraft, findings: Finding[]): { text: string; sources: string[]; sha256: string }`
  - `lintSummary(draft: SummaryDraft, ctx: { findings: Finding[]; code: Stage5Code; sides: string }): string[]` (problems; empty = clean)
  - `SummaryCheckSchema` (zod) → `SummaryCheck = { politician_id; topic_key; text_sha256; checker: string; family: 'claude' | 'gpt' | 'gemini'; sentences: { index: number; verdict: 'pass' | 'fail'; reason: string }[]; verdict: 'pass' | 'fail'; at: string /* ISO with zone */ }`
  - `summaryVerdict(checks: SummaryCheck[], sha256: string, required: SummaryCheck['family'][]): 'passed' | 'held' | 'failed'`
  - `agreementRate(verdicts: { all_agree: boolean }[]): number`

- [ ] **Step 1: Write failing tests** in `stage5Summary.test.ts`:
  - `buildSummary numbers by first use and places markers before closing punctuation`: sentences cite `[f2]`, `[f1, f2]` → text `"A [1]. B [2, 1]."`, `sources = [url(f2), url(f1)]`.
  - `buildSummary gives two findings on one URL one number` (Review Focus 1): f1, f3 share a URL → one source, both cites render `[1]`, no `[1, 1]`.
  - `lintSummary refuses a cite not in the person's findings`, `… a sentence with no cites`, `… 0 or 6 sentences`, `… the word rung`, `… a party name`, `… "often" with 2 distinct cites` (passes with 3), `… "more than once" with 1 cite`.
  - `lintSummary accepts only this person's findings when 40+ are supplied` (Review Focus 4).
  - `summaryVerdict`: all required pass on matching sha → `passed`; any fail → `held`; a check on another sha ignored, so a missing required family → `held`; claude fail → `failed`.
- [ ] **Step 2:** Run `npx vitest run scripts/lib/stage5Summary.test.ts` from `backend/`. Expected: FAIL (module missing).
- [ ] **Step 3:** Implement. `lintSummary`'s side check is left to the checkers (it needs judgement); the lint covers the mechanical rules only. Two findings are "the same URL" after trimming a trailing slash and `#fragment`.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit.

### Task 4: Read path shows a blank's checked summary

**Files:**
- Modify: `backend/src/lib/compassService.ts` (`getPoliticianContext`, ~line 947)
- Test: the existing compassService context tests (find with `grep -ln getPoliticianContext backend/src/**/*.test.ts`); add cases there.

- [ ] **Step 1: Failing tests:**
  - `serves a value-0 context whose summary_sha256 matches sha256(reasoning)`.
  - `hides a value-0 context whose reasoning changed after the check` (Review Focus 2).
  - `hides a value-0 context with NULL summary_sha256` (today's behaviour).
  - `never serves a draft-season row, even with a valid summary_sha256` (Review Focus 5).
  - Seated (value > 0) rows: unchanged.
- [ ] **Step 2:** Run; expected FAIL on the first.
- [ ] **Step 3:** Change the outer `NOT EXISTS (… a.value = 0)` so a 0-answer is allowed when `x.summary_sha256 = encode(sha256(convert_to(x.reasoning, 'UTF8')), 'hex')`. Select `summary_sha256` in the inner query. Add `-- @zero-scope: shows a blank's checked position summary, never a position` above the clause. Confirm `shownSha256` in `stage5QuoteCheck.ts` hashes the same bytes (UTF-8, no normalisation); if not, the write tool (Task 8) must use the SQL definition.
- [ ] **Step 4:** Run; PASS. Run `npx vitest run src/lib/draftSeasonWrites.test.ts`; PASS.
- [ ] **Step 5:** Commit.

### Task 5: Writer and checker inputs

**Files:**
- Create: `backend/scripts/stage5/summary-inputs.ts`
- Create: `.claude/skills/season-topic-prep/templates/stage5-summary-writer.md`, `stage5-summary-checker.md`
- Test: `backend/scripts/stage5/summaryInputs.test.ts`

**Interfaces:**
- Consumes: Task 3 types; codes in `<stage5>/codes/<unit>/*.json`; findings via `sourceStore.ts`; `stage5Template.ts` slot filling (exit 1 on an unfilled `{{…}}`).
- Produces: `summary-inputs.ts --profile <topic-profile.json> --unit <xx> --batch <xx-NN> [--max-findings 25] [--people <ids>]` writes `<stage5>/summaries/<batch>/writer/<n>.md` (≈ 10 people each) and `people.json` (ids, outcome, value, finding ids offered).

- [ ] **Step 1: Failing tests:** `includes only seated and doesnt-fit people with ≥1 topic finding`; `caps findings at --max-findings, newest and records first, and lists the count left out` (Review Focus 4); `writer prompt contains the seven writing rules and the person's outcome, never the rung text`; `checker prompt contains the summary, every cited finding's full note and URL, the outcome and the sides`.
- [ ] **Step 2:** Run; FAIL.
- [ ] **Step 3:** Implement, with the templates holding spec §5's seven rules verbatim and the JSON output shape (`SummaryDraft[]` for the writer; `SummaryCheck` without `checker`/`at`, which the tool stamps, for checkers).
- [ ] **Step 4:** Run; PASS. Commit.

### Task 6: Assemble drafts

**Files:**
- Create: `backend/scripts/stage5/summary-assemble.ts`
- Test: `backend/scripts/stage5/summaryAssemble.test.ts`

**Interfaces:** reads `writer/*.out.json` (writer subagents' files); writes `summaries.jsonl` (`{ politician_id, topic_key, text, sources, sha256, cites }`), `lint-refused.jsonl`, and `checker/<n>.md`. Exit 0 always; prints counts (drafted, linted out, to check).

- [ ] **Step 1:** Failing test: a draft that fails lint lands in `lint-refused.jsonl` with its problems and gets no checker input; a clean draft gets one.
- [ ] **Step 2–4:** Run FAIL, implement on `buildSummary` + `lintSummary`, run PASS.
- [ ] **Step 5:** Commit.

### Task 7: Second opinion through OpenCode

**Files:**
- Create: `backend/scripts/stage5/summary-second-opinion.ts`
- Test: `backend/scripts/stage5/summarySecondOpinion.test.ts`

**Interfaces:** `summary-second-opinion.ts --batch-dir <dir> --models opencode/gpt-…,opencode/gemini-… [--timeout 180]`. For each `checker/<n>.md`: copies it alone into a fresh empty temp dir, runs `opencode run -m <model> --format json --archived -f <copy> "<instruction>"` with that dir as `cwd` and no `.env` in the environment, extracts the JSON reply, validates with `SummaryCheckSchema`, stamps `checker` = model and `family`, appends to `checks.jsonl`. Exports `parseModelReply(raw: string): SummaryCheck[] | null`.

- [ ] **Step 1: Failing tests** for `parseModelReply` (Review Focus 3): JSON in a fenced block → parsed; prose around it → parsed; empty, truncated or schema-invalid → `null`; and `a null reply is recorded as a fail check with reason "no usable reply"`.
- [ ] **Step 2–4:** Run FAIL, implement, run PASS. The model list comes from the runner's profile key `second_opinion_models`; pick one GPT and one Gemini from `opencode models` and write them there (builder's call).
- [ ] **Step 5:** One live smoke run on 3 summaries; read `checks.jsonl` by hand. Commit.

### Task 8: Write tool

**Files:**
- Create: `backend/scripts/stage5/summary-write.ts`
- Test: `backend/scripts/stage5/summaryWrite.test.ts`

**Interfaces:** `summary-write.ts --profile <p> --batch-dir <dir> [--apply --yes "<runner's words>"]`. Reads `summaries.jsonl` + `checks.jsonl` (Claude checks written there by the desk from the Claude checker subagents' files); `summaryVerdict(..., required = ['claude','gpt','gemini'])`; dry run prints a table (person, outcome, verdict, agreement) and writes `PREVIEW.md` and `held.md` (each held sentence with every checker's reason). Apply: `assertDraftSeason`, then for each `passed` row `UPSERT_CONTEXT_IN_SEASON_SQL` with the new `reasoning`/`sources` and `summary_sha256 = sha256`, after saving the row's previous `reasoning`/`sources` to `old-context.jsonl`. Refuses a person with no existing context row for that season (the summary never creates a seat or a blank). Prints the batch agreement rate.

- [ ] **Step 1: Failing tests:** `dry run writes nothing`; `apply refuses without --yes`; `apply refuses a non-draft season`; `held and failed rows are not written`; `old reasoning is saved before the overwrite`; `a person with no context row in the season is refused`.
- [ ] **Step 2–4:** Run FAIL, implement (a `Query` seam as `stage5Write.ts` `applyBatch` uses), run PASS.
- [ ] **Step 5:** Commit.

### Task 9: The recipe, rulings and the 20-sample stop

**Files:**
- Modify: `.claude/skills/season-topic-prep/STAGE5.md` (new section "7b. Position summaries", after section 7)
- Modify: `.claude/skills/season-topic-prep/RULINGS.md` (three rulings, 2026-11-22, Chris Andrews: summaries in our own words with numbered citations for everyone with evidence; no direction marker and no compass effect; second opinion from a GPT and a Gemini model until the runner retires it)
- Modify: `backend/scripts/stage5/README.md` (tool list)

- [ ] **Step 1:** Write the section: order of steps (inputs → writer subagents → assemble → Claude checker subagents → second opinion → write dry run → 🛑 runner's yes per batch → apply), and the first-run stop: before any gun-policy write, show the runner 20 summaries with references (seeded draw, seed in `summaries/sample-seed.txt`). 🛑
- [ ] **Step 2:** Commit.

### Task 10: Profile display (`ev-ui`, separate PR)

**Files:**
- Modify: `ev-ui/src/StanceAccordion.jsx` (research-state branch ~line 585; references ~line 668)
- Test: `ev-ui/src/StanceAccordion.researchStates.test.jsx`

- [ ] **Step 1: Failing tests:** `a doesnt-fit topic with context shows the reasoning and References above the own-words passages`; `[n] markers render as links to that topic's reference n`; `a doesnt-fit topic whose context fetch 404s renders as today`.
- [ ] **Step 2–4:** Fetch context for a doesnt-fit topic on expand (the same `contextCache` path seated topics use); render; `[n]` → `<a href="#ref-<topicId>-<n>">`, reference `<li id=…>`. Run PASS.
- [ ] **Step 5:** PR in `ev-ui`; then bump `ev-ui` in `essentials` per that repo's usual way. Ships before Season 3 opens; shows nothing until then.

### Task 11: Local pilot tooling

**Files:**
- Create: `backend/scripts/stage5/local_pilot_sample.py`
- Modify: `backend/scripts/stage5/stage5_prompts.py` (use `search.local_subjects` for level `local`)
- Modify: `<stage5>/topic-profile.json` (research folder, not committed): add `search.local_subjects` (spec §8 list) and `second_opinion_models`
- Test: `backend/scripts/stage5/test_local_pilot_sample.py`

- [ ] **Step 1: Failing tests:** `same seed → same 100`; `strata = council-and-mayor / county / sheriff / other, each ≥ 10`; `California ≤ its roster share rounded up`; `the seed file must exist before drawing (exit 2 otherwise)`.
- [ ] **Step 2–4:** Run FAIL (`python3 -I -m pytest`), implement from `roster.tsv` + office titles (query as in this plan's research, `DISTINCT ON (politician_id)` over `office_current_holder`), run PASS.
- [ ] **Step 5:** Commit. The pilot run itself (search, code, summarise, `REPORT.md`, 🛑 runner) happens after Task 1 is applied, by the Stage 5 recipe.
