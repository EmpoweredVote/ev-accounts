# Season topic prep — Stage 5 (code everyone) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Stage 5 to the season-topic-prep skill — research everyone a topic covers once per season, save the
findings by person and subject, code them into seated / doesn't fit / no stance found, stop at an early check if
the rungs look wrong, and (after the check) show voters a seat, checked own words, or a plain "no public stance"
line.

**Architecture:** Two phases. **Phase A (Tasks 1–7)** is everything the run needs up to the early check, and is
offline: pure TypeScript libs with thin CLIs, a new `findings/` area in the source store, and subagent briefs for
the searcher, coder, theme pass and quote check. Codes and reports live in the research folder. **Phase B
(Tasks 8–12)** is what the first database write and voters need: a migration with two tables, a writer, a read
endpoint, and the accordion rows. Phase B is built while Chris reviews the early check; nothing in it runs against
production until the check passes and Chris says yes per batch.

**Tech Stack:** TypeScript + zod + vitest (`backend/scripts/lib`, `backend/src/lib`), Postgres migrations
(`CA_` slots), Express routes, React (ev-ui `StanceAccordion.jsx`), essentials package bump.

**Spec:** `docs/superpowers/specs/2026-10-22-season-topic-prep-stage5-code-everyone-design.md` (PR #1120, with the
2026-10-22 rulings). Rulings: `.claude/skills/season-topic-prep/RULINGS.md` "Stage 5 rulings".

## Global Constraints

- No database write without Chris Andrews' explicit yes, batch by batch; **no writes at all before the early check passes.**
- `--season draft` on every research and write step. Never touch the open season.
- Never print `DATABASE_URL`; read it with `set -a; . backend/.env; set +a`.
- No party names or colours anywhere, including the voter text.
- Never show a quote the AI quote check has not confirmed on its source page (enforced in the schema, Task 8).
- Explicit pathspecs on every commit; never commit in `~/Documents/GitHub` itself; small PRs.
- Migration slots: `npm run steward --prefix backend -- slot CA --purpose "..."`.
- Every CLI path argument is absolute (npm switches into `backend/`).
- Search each person **once per topic per season**; everyone on the roster gets an own-words search.
- Early-check bar: stop when doesn't-fit **>** 1/5 of people with any on-topic evidence, **or** any one theme **>** 1/10 of them.
- A local record never seats alone; it supports a local official's own words only.
- Own-words-only seats keep the `statement-evidence` hold (existing queue) until the blind check (Task 13) passes.
- New blank readers carry `-- @zero-scope: counts-blanks` and keep the filter outside the newest-season collapse; every reader also uses `${SEASON_IS_PUBLISHED}`.
- Voter sentence, exact: `We researched {name} and found no public stance on {topic}.` plus the research date.

## Review Focus

1. **Person holding two offices, or sitting and also a candidate** → one roster row, `scope = both`; never two
   (the `office_current_holder` politician-rooted join fans out). Test in Task 1.
2. **Active candidate with no `politician_id`** → counted and reported as a gap, never silently dropped. Test in Task 1.
3. **Run stopped half-way** → re-running `stage5-next` never lists a person already searched for this topic and
   season; re-importing a finding file merges, never duplicates. Tests in Tasks 2 and 4.
4. **Quote with curly quotes, extra spaces or a line break** compared with the page → the check normalises
   whitespace and quote marks only; any other difference fails. Test in Task 8.
5. **A doesn't-fit code with no open note**, or a local record as the only evidence for a seat → rejected by the
   schema. Tests in Task 5.

---

## Phase A — up to the early check (offline; three PRs)

### Task 1: Roster builder

**Files:**
- Create: `backend/scripts/lib/stage5Roster.ts`, `backend/scripts/lib/stage5Roster.test.ts`
- Create: `backend/scripts/topic-stage5-roster.ts`; Modify: `backend/package.json` (`"topic:stage5-roster": "tsx scripts/topic-stage5-roster.ts"`)

**Interfaces:**
- Produces: `type RosterRow = { politician_id: string; full_name: string; office_id: string | null; level: Level; state: string | null; scope: 'sitting' | 'candidate' | 'both'; leaving: 'yes' | 'no' | 'unknown'; race_ids: string[] }`
- `loadRoster(q: QueryFn, topicKey: string, onGap: (g: RosterGap) => void): Promise<RosterRow[]>` where `RosterGap = { kind: 'candidate-no-politician' | 'no-level' | 'level-out-of-scope'; id: string; note: string }`
- `formatRosterTsv(rows: RosterRow[]): string`, `parseRosterTsv(text: string): RosterRow[]`, `rosterCounts(rows): { byLevel: Record<Level, number>; byState: Record<string, number>; byScope: ...; leaving: ... }`
- Columns, in order: `politician_id full_name office_id level state scope leaving race_ids` (race_ids comma-joined).

Sitting officials: `essentials.office_current_holder` with `DISTINCT ON (p.id)` choosing the highest level office
(federal > state > judicial > local > school). Level from `levelForDistrict`; keep only levels in
`compass_topic_roles` for the topic. Candidates: `race_candidates.candidate_status = 'active'` in races whose
district maps to an in-scope level. `leaving = 'yes'` when the person's office has a race in the 2026-11-03
election and they are not an active candidate in it; `'no'` when the seat has no such race or they are on the
ballot; `'unknown'` when the race cannot be tied to the office. Use the fake-query pattern in `seatRate.test.ts:58`.

- [ ] **Step 1: Write failing tests** — `loadRoster` with a fake query: (a) one person with two offices → one row, the higher level; (b) a sitting official who is an active candidate → `scope: 'both'`, `leaving: 'no'`; (c) seat up, not on ballot → `leaving: 'yes'`; (d) a candidate row with `politician_id: null` → no row, one `candidate-no-politician` gap; (e) a level not in the topic's roles → no row, one `level-out-of-scope` gap. `parseRosterTsv(formatRosterTsv(rows))` round-trips.
- [ ] **Step 2: Run** `npm test --prefix backend -- scripts/lib/stage5Roster.test.ts` → FAIL (module not found).
- [ ] **Step 3: Implement** the lib, then the CLI: `--topic <key> --out <abs roster.tsv>`; refuses an existing `--out`; writes `<out>.gaps.tsv`; prints `rosterCounts` as a table.
- [ ] **Step 4: Run tests** → PASS. Run `npm run lint --prefix backend` and `npm run check:occupancy --prefix backend` → clean.
- [ ] **Step 5: Commit** (pathspec: the four files).

### Task 2: Findings in the source store

**Files:**
- Modify: `backend/scripts/lib/sourceStore.ts` (new section `// ---------- findings ----------`), `backend/scripts/lib/sourceStore.test.ts`, `backend/scripts/source-store.ts` (validate and merge cover `findings/`), `backend/data/source-store/README.md`, `.claude/skills/season-topic-prep/SOURCE-STORE.md` (new row in "When to write each file")

**Interfaces:**
- `FindingSchema = { id: string /* sha256 hex of kind|url|passage-or-instrument+act */; kind: 'record' | 'own-words'; url: string; date: string; date_precision: 'day'|'month'|'year'|'unknown'; passage?: string /* exact, required for own-words */; instrument_id?: string; act?: 'yea'|'nay'|'abstain'|'sponsor'|'author'|'signed'|'vetoed'|'other'; local_record?: boolean; note: string; subjects: string[] /* plain words, min 1 */; topic_keys: string[]; provenance: Provenance }`
- `SearchSchema = { topic_key: string; season: number; subjects: string[]; places: string[]; found: number; at: string; by: string }`
- `PersonFindingsSchema = { politician_id: uuid; findings: Finding[]; searches: Search[] }` at `findings/<politician-id>.json`
- `findingId(f: Omit<Finding,'id'>): string`, `mergeFindings(prev, next)`, `upsertFindings(root, pf): 'created'|'merged'`, `searchedFor(pf, topicKey, season): boolean`
- `storePaths(root).findings(politicianId)`

Merge: findings unioned by `id` (newer `provenance.fetched_at` wins); searches unioned by `topic_key|season|at`.
`people/` stays as it is (the importer from the pilots relies on it).

- [ ] **Step 1: Failing tests** — own-words finding without `passage` fails; record finding without `instrument_id` or `url` fails; `subjects: []` fails; upserting the same finding twice leaves one; `searchedFor` true after a search entry for (`voting-rights`, 3) and false for season 4; `validateStore` reports a broken `findings/` file; `mergeStore` carries `findings/`.
- [ ] **Step 2: Run** `npm test --prefix backend -- scripts/lib/sourceStore.test.ts` → the new tests FAIL.
- [ ] **Step 3: Implement**; document the file in both READMEs.
- [ ] **Step 4: Run tests** → PASS; `npm run source-store --prefix backend -- validate` → exit 0.
- [ ] **Step 5: Commit.**

### Task 3: Pre-fill from roll calls

**Files:**
- Create: `backend/scripts/lib/stage5Prefill.ts` (+ `.test.ts`), `backend/scripts/topic-stage5-prefill.ts`; Modify: `backend/package.json` (`topic:stage5-prefill`)

**Interfaces:**
- Consumes: `RosterRow` (Task 1), `Instrument`, `upsertFindings` (Task 2), `identifyRollCalls` (`identityMatch.ts`).
- `prefillFindings(instruments: Instrument[], accepted: Set<string>, roster: RosterRow[], topicKey: string, at: string): { findings: PersonFindings[]; unmatched: UnmatchedVote[] }`
- `UnmatchedVote = { instrument_id: string; date: string; body: string; name: string; vote: string }`

`accepted` = instrument ids listed in the topic's `stage0/gates.tsv` (gated ones too; the gate goes in the
finding's `note` so the coder sees it). Each matched member vote and each matched sponsor → one record finding,
`subjects` from the instrument's title words chosen by the runner in a `--subjects <abs json>` map
(`{ "<instrument_id>": ["voter ID at the polls", ...] }`), `provenance.method: 'unrecorded'` carried from the
instrument. Unmatched names go to `unmatched.json` for `census:identity` (never surname alone). No search entry
is written: pre-fill does not count as the own-words search.

- [ ] **Step 1: Failing tests** — a yea by a roster person → one finding with `act: 'yea'`, the instrument id and the gate note; a member with no `politician_id` → in `unmatched`; a member not on the roster (left office) → no finding; an instrument not in `accepted` → ignored; running twice → no duplicate (same `id`).
- [ ] **Step 2–4:** run → FAIL; implement lib + CLI (`--topic --research <abs dir> --store <abs root> [--dry-run]`, prints counts per level); run → PASS.
- [ ] **Step 5: Commit.** **Open PR A1** (Tasks 1–3).

### Task 4: The search pass (brief, importer, next batch)

**Files:**
- Create: `.claude/skills/season-topic-prep/templates/BRIEF-stage5-find.md`
- Create: `backend/scripts/lib/stage5Find.ts` (+ `.test.ts`), `backend/scripts/topic-stage5-find.ts`; Modify: `backend/package.json` (`topic:stage5-find`)

**Interfaces:**
- `nextBatch(roster: RosterRow[], store: string, topicKey: string, season: number, order: 'federal' | { state: string }, size: number): RosterRow[]` — people in that unit not yet `searchedFor`, people with pre-filled findings first, `leaving: 'yes'` excluded.
- `importFindFile(json: unknown, topicKey: string, season: number): PersonFindings` — validates the collector's file (shape below), computes `id`s, appends the search entry even when `findings` is empty.
- CLI: `topic:stage5-find next --topic --unit federal|state:xx --size N --roster <abs> --store <abs>` prints a batch file; `topic:stage5-find import --topic --dir <abs stage5/raw/find> --store <abs>`.

The brief is for `source-collector` agents, one person per agent, broad on the topic's subject (records and own
words, the classes in design §5 step 3), following research-stances STEP 0.5 (OTR transcripts first) and STEP 1's
source order. It asks for **no rung or value**. Output JSON:
`{ politician_id, searched: { subjects[], places[] }, findings: [{ kind, url, date, date_precision, passage?, instrument_id?, act?, local_record?, note, subjects[] }] }`, written to `<research>/stage5/raw/find/<politician_id>.json`. Passages are copied verbatim.

- [ ] **Step 1: Failing tests** — `nextBatch` skips a person with a search entry for this topic and season, keeps one searched for another topic, puts pre-filled people first, excludes `leaving: 'yes'`; `importFindFile` with `findings: []` still writes a search entry with `found: 0`; a finding missing `subjects` throws naming the person.
- [ ] **Step 2–4:** FAIL → implement → PASS.
- [ ] **Step 5: Commit.**

### Task 5: Coding from saved findings

**Files:**
- Create: `.claude/skills/season-topic-prep/templates/stage5-coder-prompt.md`
- Create: `backend/scripts/lib/stage5Code.ts` (+ `.test.ts`)

**Interfaces:**
- `Stage5CodeSchema = { politician_id; topic_key; season_id; revision_id; outcome: 'seated'|'no-stance'|'doesnt-fit'; value?: number /* 1–5, halves */; reasoning: string; blank_class?: BlankClass /* seatRate.ts */; open_note?: string; tags: StarterTag[]; finding_ids: string[]; evidence_basis: 'record'|'own-words'|'joint'; codebook: string; coded_by: string; coded_at: string }`
- `StarterTag = 'between-rungs' | 'related-question' | 'unnamed-position' | 'direction-only' | 'other-level-lever'`
- `checkCode(code, findings: Finding[]): string[]` — returns problems; empty = OK.

Rules `checkCode` enforces: `seated` needs `value` and ≥ 1 finding id that exists; `doesnt-fit` needs a non-empty
`open_note` and ≥ 1 finding; `no-stance` needs a search entry and zero on-topic findings cited; a seat whose cited
findings are all `local_record` fails ("a local record never seats alone"); `evidence_basis` must match the cited
kinds. The coder prompt (Opus subagent, one person per call, batches of ~20) gets the codebook, the served ladder
for the draft pin, the annex, RULINGS.md and that person's findings file **only**; it writes
`<research>/stage5/codes/<politician_id>.json`. Blank classes map: `source-gap` → no-stance; `gate`, `wording`,
`no-lever`, `off-question`, `nay-only` → doesn't-fit (kept as `blank_class`).

- [ ] **Step 1: Failing tests** — one per rule above, plus a valid code of each outcome passes.
- [ ] **Step 2–4:** FAIL → implement → PASS.
- [ ] **Step 5: Commit.**

### Task 6: Theme pass and report with the early check

**Files:**
- Create: `.claude/skills/season-topic-prep/templates/stage5-theme-prompt.md`
- Create: `backend/scripts/lib/stage5Report.ts` (+ `.test.ts`), `backend/scripts/topic-stage5-report.ts`; Modify: `backend/package.json` (`topic:stage5-report`)

**Interfaces:**
- `ThemesSchema = { themes: [{ name: string; points_at: 'rung-change'|'new-topic'|'nothing'; politician_ids: string[]; summary: string }]; read_notes: number; at: string }`
- `DOESNT_FIT_BAR = 0.2`, `THEME_BAR = 0.1`
- `summarise(roster: RosterRow[], codes: Stage5Code[], themes?: Themes): Stage5Summary` — counts per level, per state, overall for the three outcomes plus "not yet researched"; per-rung seats; `seatRateAll = seated / researched`; `seatRateEvidence = seated / (seated + doesntFit)`.
- `earlyCheck(s: Stage5Summary): { stop: boolean; reasons: string[] }` — strict `>` on both bars; the denominator is people with any on-topic evidence (seated + doesn't fit).
- `formatReport(s, check): string` (Markdown for `stage5/report.md` or `stage5/early-check.md`).
- CLI: `--topic --research <abs> --roster <abs> [--themes <abs>] --out <abs> [--early]`; exit 0 = continue, exit 4 = stop.

The theme prompt (separate subagent) reads every doesn't-fit open note and its tags, names themes in plain words
from the notes, and may leave a note unthemed.

- [ ] **Step 1: Failing tests** — exactly 20% doesn't-fit → no stop; 21% → stop; one theme at 11% with total 15% → stop, reason names the theme; no-stance people do not enter the denominator; `seatRateAll` and `seatRateEvidence` computed on a fixture of 10.
- [ ] **Step 2–4:** FAIL → implement → PASS.
- [ ] **Step 5: Commit.**

### Task 7: Skill text

**Files:**
- Create: `.claude/skills/season-topic-prep/STAGE5.md`
- Modify: `.claude/skills/season-topic-prep/SKILL.md` (description triggers add "Stage 5", "code everyone"; one "Stage 5" section pointing at STAGE5.md; the folder list adds `stage5/`), `backend/scripts/lib/topicPrepUpdate.ts` (+ test: stage `5` allowed), `backend/scripts/lib/topicPrepSkill.test.ts` (STAGE5.md exists and every CLI it names is in package.json)

STAGE5.md is the runbook: steps 1–7 of design §5 with the commands from Tasks 1–6; the order (federal, then
the early-check states, then the rest, then local and candidate gaps); resume = run `next` again; the
stop/ask at the early check; the election rules (leaving officials get pre-fill only; drop losers after results;
GA/LA runoffs stay active); the Monday step. Write it in the house style of STAGE4-RECIPE.md.

- [ ] **Step 1: Failing test** in `topicPrepSkill.test.ts` (file and commands present) → FAIL.
- [ ] **Step 2: Write the text and the stage-5 update change** → PASS.
- [ ] **Step 3: Commit.** **Open PR A2** (Tasks 4–7).

**Then run** (no build needed): roster → pre-fill → federal search and code → the early-check states → theme pass
→ `topic:stage5-report --early` → stop and show Chris the split and the themes.

---

## Phase B — before the first write (built during the early-check review)

### Task 8: Quote check

**Files:**
- Create: `.claude/skills/season-topic-prep/templates/stage5-quote-check-prompt.md`
- Create: `backend/scripts/lib/stage5QuoteCheck.ts` (+ `.test.ts`)

**Interfaces:**
- `normaliseForMatch(s: string): string` — collapse whitespace, curly → straight quotes and apostrophes, en/em dash → hyphen; nothing else.
- `passageOnPage(passage: string, pageText: string): boolean`
- `QuoteCheckSchema = { finding_id; politician_id; verdict: 'passed'|'failed'; on_page: boolean; own_words: boolean; on_topic: boolean; reason: string; checker: string; at: string }`; `verdict = 'passed'` only if all three are true.

The prompt runs a **second** agent (not the searcher or coder) per finding: fetch the page fresh, run
`passageOnPage`, judge own words (codebook V1) and on-topic; write `<research>/stage5/quote-checks.jsonl`.

- [ ] **Step 1: Failing tests** — curly quotes and a line break still match; one changed word fails; `verdict` cannot be `passed` with `own_words: false` (schema refine).
- [ ] **Step 2–4:** FAIL → implement → PASS. **Step 5: Commit.**

### Task 9: Migration — research outcomes and shown passages

**Files:**
- Create: `backend/migrations/CA_NNNN_stage5_research_outcomes.sql` (slot from steward)

Tables, both keyed per person, per topic, per season, both with FKs to `inform.seasons`, `inform.compass_topics`,
`essentials.politicians`, and the `inform.closed_season_is_immutable()` trigger attached like the answer tables:
- `inform.topic_research_outcomes (politician_id, topic_id, season_id, outcome text CHECK IN ('seated','doesnt-fit','no-stance'), researched_on date NOT NULL, checked_by text[] NOT NULL DEFAULT '{}', created_at, PRIMARY KEY (politician_id, topic_id, season_id))` — the "we researched" marker, separate from `value = 0`.
- `inform.own_words_passages (id uuid PK, politician_id, topic_id, season_id, finding_id text NOT NULL, kind text CHECK IN ('own-words','local-record'), passage text NOT NULL, source_url text NOT NULL, source_date date, source_date_precision text, quote_check text NOT NULL CHECK (quote_check = 'passed'), quote_checked_at timestamptz NOT NULL, quote_checker text NOT NULL, UNIQUE (politician_id, topic_id, season_id, finding_id))` — an unchecked quote cannot be stored.

- [ ] **Step 1:** Reserve the slot; write the migration with a header comment and an `-- @zero-scope:` note on the outcome table.
- [ ] **Step 2:** `npm run check:reservations --prefix backend` → clean. Nothing runs against production here: a
  `BEGIN … ROLLBACK` dry run needs Chris' yes, and the real apply needs a second yes, both after the early check.
- [ ] **Step 3: Commit.**

### Task 10: Writer

**Files:**
- Create: `backend/scripts/lib/stage5Write.ts` (+ `.test.ts`), `backend/scripts/topic-stage5-write.ts`; Modify: `backend/package.json` (`topic:stage5-write`)

**Interfaces:**
- Consumes: `Stage5Code` (Task 5), `QuoteCheck` (Task 8), `PersonFindings` (Task 2).
- `planBatch(codes, findingsByPerson, checks): { outcomes: OutcomeRow[]; passages: PassageRow[]; researchCsv: string; refused: { politician_id: string; reason: string }[] }`

Seats and blanks still go through the existing pipeline (`research.csv` + `evidence.csv` →
`verify-stance-research.ts --season draft`), so `stanceGate`, `decidePublish` (own-words seats → `statement-evidence`)
and `audit-chair-evidence.mjs --csv` all still run. The writer adds the outcome rows and the passages in one
transaction, `--season draft` only (refuses `open` or a uuid that is not a draft), default dry run, `--apply` after
Chris' yes. A passage with no `passed` check is refused and listed.

- [ ] **Step 1: Failing tests** — a doesn't-fit code with an own-words finding and a passed check → one outcome + one passage; same with a failed check → outcome only, passage in `refused`; `--season open` → throws; a no-stance code → outcome only.
- [ ] **Step 2–4:** FAIL → implement → PASS. **Step 5: Commit.** **Open PR B1** (Tasks 8–10).

### Task 11: API — research states

**Files:**
- Modify: `backend/src/lib/compassService.ts`, `backend/src/lib/compassService.test.ts`, `backend/src/routes/compass.ts`, `backend/src/routes/compass.answers.scope.test.ts`

**Interfaces:**
- `getResearchStates(politicianId: string): Promise<ResearchState[]>` where `ResearchState = { topic_id: string; outcome: 'doesnt-fit'|'no-stance'; researched_on: string; passages: { kind: 'own-words'|'local-record'; passage: string; source_url: string; source_date: string | null }[] }`
- Routes: `GET /api/compass/politicians/:id/research-states`; `GET /api/compass/candidates/:id/research-states` (via `race_candidates.politician_id`; `[]` when none). Same auth, UUID and error handling as the `/answers` routes.

`getPoliticianAnswers` is **unchanged** (its consumers treat any returned value as a position). The new read:
newest **published** season per topic (`${SEASON_IS_PUBLISHED}`, `DISTINCT ON (topic_id) … ORDER BY s.number DESC`),
then keeps only outcomes `doesnt-fit`/`no-stance` **outside** the collapse, marked `-- @zero-scope: counts-blanks`.
A topic whose newest season seats the person returns nothing.

- [ ] **Step 1: Failing tests** — SQL contains `SEASON_IS_PUBLISHED`'s text, the collapse, and the outcome filter after `) latest`; contains `@zero-scope: counts-blanks`; passages attached per topic; route 422 on a bad uuid. `npm run check:answer-seasons` and `draftSeasonWrites.test.ts` pass.
- [ ] **Step 2–4:** FAIL → implement → PASS. **Step 5: Commit.** **Open PR B2.**

### Task 12: Accordion rows (ev-ui, then essentials)

**Files:**
- Modify: `ev-ui/src/StanceAccordion.jsx` (+ its test/story if present), `ev-ui/package.json` (minor bump)
- Modify: `essentials/package.json` (bump `@empoweredvote/ev-ui`); CompassV2 is a follow-up (below)

StanceAccordion fetches `${apiUrl}/api/compass/politicians/${politicianId}/research-states` once, like the quotes
fetch. For a topic with no value:
- `no-stance` → `We researched {name} and found no public stance on {topic}.` + `Researched {Month D, YYYY}.` (new optional prop `politicianName`; without it, "this official").
- `doesnt-fit` → heading `In their own words — not a position on the scale`, each passage in quotes with source link and date; a local record under `Local record` with its plain-words summary.
No colours tied to any side; no adjectives about the person. A topic with neither keeps today's text.

- [ ] **Step 1: Failing tests** (ev-ui test runner) — each state renders its exact copy; a seated topic ignores research states; a failed fetch renders as today.
- [ ] **Step 2–4:** FAIL → implement → PASS; publish ev-ui; bump essentials; check in the browser preview against a draft-free local fixture.
- [ ] **Step 5: Commit** in each repo; **PRs B3 (ev-ui) and B4 (essentials).**

### Task 13: Blind check for own-words seats (after coding, per topic)

Not code: a STAGE5.md section. Draw a seeded sample of own-words-only seats (hash the seed first, as Stage 1),
have separate blind validators code them from the codebook, ladder, annex and the findings only, and compare.
≥ 95% agreement → propose the CLAUDE.md change and the per-topic hold release in one PR (ruling 2b). Below → the
hold stays; report the misses.

---

## Follow-ups (not in this plan)

- CompassV2 `CombinedPage.jsx` rows for the two states (it drops `v <= 0` today).
- One search per person across all topics (budget rule, later).
- Validation Quests reading `checked_by`.
