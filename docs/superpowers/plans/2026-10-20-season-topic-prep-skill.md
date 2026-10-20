# Season Topic Prep Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A team-usable skill, `season-topic-prep`, that takes a compass topic from audit to an applied Season revision, with the helper scripts it needs (source store, seat-rate report, gate pre-screen, blindness check, Monday update text) and a one-time import of pilot sources.

**Architecture:** The skill is Markdown (`.claude/skills/season-topic-prep/`) that drives an orchestrating session through the stages in the spec. Deterministic work lives in small pure TypeScript modules under `backend/scripts/lib/` (tested with vitest, database access injected as a `Query` function like `seasonTarget.ts`), with thin CLI wrappers under `backend/scripts/`. The source store is JSON committed at `backend/data/source-store/`. Monday writes go through the Monday MCP tools; code only formats the update text.

**Tech Stack:** TypeScript run with `tsx`, `zod` for schemas, `vitest`, `pg` (read-only queries), Markdown skill files.

**Spec:** `docs/superpowers/specs/2026-10-20-season-topic-prep-skill-design.md`

## Global Constraints

- Every script in this plan is **read-only against the database**. No migration is part of this project (spec §9 item 1).
- Pure modules take an injected `Query = (sql: string, params?: unknown[]) => Promise<{ rows: any[] }>` and never import `db.js` (pattern: `backend/scripts/lib/seasonTarget.ts`).
- Season targeting uses `seasonSpecFromArgv` / the existing `seasonTarget.ts` helpers: `--season open|draft|<uuid>`, default `open`; a closed season is refused.
- Levels are `'federal' | 'state' | 'local' | 'judicial' | 'school'` (`src/lib/topicApplicability.ts` `Level`), resolved with `levelForDistrict`.
- A blank is `politician_answers.value = 0`; half values (e.g. 2.5) are seated write-ins between two rungs.
- Blank classes are exactly: `source-gap`, `gate`, `wording`, `no-lever` (spec §5.0).
- Jurisdiction scopes use the steward form: `federal`, `state:<usps lower>`, `county:<5-digit fips>`, `place:<7-digit geoid>`.
- Instrument ids look like `WA-ESSB-5044-2021`: jurisdiction prefix, instrument, year.
- The skill never writes the database, a revision, a migration or a `--season draft` batch without the runner's explicit yes (spec §3).
- Antipartisan: no party names or partisan colours in any output.
- Skill copy (Markdown) states the purpose in its first lines (spec §1) and uses plain English.
- Commit with an explicit pathspec: `git commit -F msg -- <paths>` (repo CLAUDE.md). End commit messages with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

- A topic with **zero rows** in the chosen season → the seat-rate report prints "no rows" per level, never NaN or a divide-by-zero. (Test in Task 2.)
- **Half-value answers** (2.5) → counted as seated, not blank, and attributed to no single rung in the per-rung table but to a `between` bucket. (Test in Task 2.)
- **The same instrument saved by two runs** (different votes or fields) → merged: votes unioned by (date, body, motion), fields from the newer `fetched_at` kept, never a silent overwrite. (Test in Task 1.)
- **Forbidden paths written differently in a transcript** (`~/…`, absolute, `Application%20Support`, escaped spaces) → still detected by the blindness check. (Test in Task 4.)
- **A malformed `rows.tsv`** (missing column, unknown blank class) → the report stops with the file, line and column named. (Test in Task 2.)

---

### Task 1: Source store schemas and helpers

**Files:**
- Create: `backend/scripts/lib/sourceStore.ts`
- Create: `backend/scripts/lib/sourceStore.test.ts`
- Create: `backend/scripts/source-store.ts` (CLI: `validate`)
- Create: `backend/data/source-store/README.md` (layout + field meanings, from spec §5.7)
- Modify: `backend/package.json` (add script `"source-store": "tsx scripts/source-store.ts"`)

**Interfaces:**
- Produces:
  - `InstrumentSchema`, `PersonSourcesSchema`, `JurisdictionSchema`, `DeadEndSchema` (zod) and their inferred types `Instrument`, `PersonSources`, `Jurisdiction`, `DeadEnd`.
  - `Provenance = { fetched_by: string; fetched_at: string /* ISO */; method: 'webfetch'|'curl'|'browser'|'ocr'|'api'|'hand-saved'; saved_copy?: { path: string; sha256: string } }` — required on every instrument, person source and jurisdiction portal entry.
  - `Instrument` fields: `id`, `scope`, `title`, `urls: string[]`, `version: 'as-filed'|'enrolled'|'adopted'|'other'`, `operative_text?: string`, `single_subject: { season: number; codebook: string; topic_list_hash: string; verdict: 'single'|'multi'; other_topics: string[] }[]`, `higher_law_duty?: string`, `votes: Vote[]`, `provenance`.
  - `Vote = { date: string; body: string; motion: string; kind: 'action-item'|'consent'|'en-bloc'|'roll-call'; yes: number; no: number; absent?: number; body_size?: number; members: { name: string; politician_id?: string; vote: 'yea'|'nay'|'absent'|'abstain' }[] }`.
  - `PersonSources = { politician_id: string; sources: { url: string; kind: 'record'|'own-words'; topic_keys: string[]; useful: boolean; note?: string; provenance: Provenance }[]; terms: { office: string; start?: string; end?: string; precision: 'day'|'month'|'year'|'unknown'; source: string }[] }`.
  - `Jurisdiction = { scope: string; portals: { name: string; url: string; status: 'works'|'blocked'|'needs-browser'; how?: string; checked_at: string }[]; rosters: { url: string; note?: string }[]; higher_law_duties: { topic_key: string; duty: string; citation: string }[] }`.
  - `DeadEnd = { at: string; scope?: string; politician_id?: string; topic_key?: string; query_or_url: string; result: 'nothing'|'blocked'|'paywalled'|'robots'; by: string }`.
  - `storePaths(root: string)` → `{ instrument(scope, id), person(politicianId), jurisdiction(scope), deadEnds }` (file paths; scope `state:wa` → directory `state-wa`).
  - `upsertInstrument(root: string, inst: Instrument): 'created'|'merged'`, `upsertPerson(root, p: PersonSources)`, `upsertJurisdiction(root, j: Jurisdiction)`, `appendDeadEnd(root, d: DeadEnd)`, `validateStore(root): { file: string; error: string }[]`.

- [ ] **Step 1: Write failing tests** in `sourceStore.test.ts` (use a temp dir per test):
  - `rejects an instrument without provenance` → `InstrumentSchema.safeParse(...)` `.success === false`.
  - `rejects a bad scope` → `'WA'` and `'state:WA'` fail; `'state:wa'`, `'county:53033'`, `'place:5363000'`, `'federal'` pass.
  - `instrument id format` → `'WA-ESSB-5044-2021'` passes; `'5044'` fails.
  - `upsertInstrument creates then merges`: first call returns `'created'`; second call with one new vote and one repeated vote (same date, body, motion) returns `'merged'`, file holds 2 votes; a field present in both keeps the value with the newer `provenance.fetched_at`.
  - `appendDeadEnd appends one JSON line per call` → file has 2 lines after 2 calls, each parses with `DeadEndSchema`.
  - `validateStore reports file and reason` → a hand-written broken file yields one entry naming that file.
- [ ] **Step 2: Run** `npm test --prefix backend -- sourceStore` → FAIL (module missing).
- [ ] **Step 3: Implement** `sourceStore.ts` with the interfaces above. Files are pretty-printed JSON with a trailing newline, keys in schema order, so diffs stay small.
- [ ] **Step 4: Implement** `scripts/source-store.ts validate [--root <dir>]` (default root `backend/data/source-store`); exits 1 and prints each problem when `validateStore` returns any.
- [ ] **Step 5: Run** `npm test --prefix backend -- sourceStore` → PASS; `npm run typecheck --prefix backend` → no errors; `npm run source-store --prefix backend -- validate` on the empty store → exit 0.
- [ ] **Step 6: Commit** `feat(topic-prep): source store schemas, merge rules and validate CLI` with pathspec.

### Task 2: Seat-rate report

**Files:**
- Create: `backend/scripts/lib/seatRate.ts`, `backend/scripts/lib/seatRate.test.ts`
- Create: `backend/scripts/topic-seat-rate.ts`
- Modify: `backend/package.json` (add `"topic:seat-rate": "tsx scripts/topic-seat-rate.ts"`)

**Interfaces:**
- Consumes: `seasonSpecFromArgv(argv)` and `resolveSeasonTarget(spec, query)` from `scripts/lib/seasonTarget.ts`; `levelForDistrict` from `src/lib/topicApplicability.ts`.
- Produces:
  - `type BlankClass = 'source-gap'|'gate'|'wording'|'no-lever'`.
  - `blankClassForReason(reason: string): BlankClass | null` — `no-evidence`→source-gap; `near-unanimous`, `multi-subject`, `study-directive`, `pre-seating`→gate; `direction-only`, `adjacent-chairs`, `compound-partial`, `record-vs-statement-conflict`→wording; `scope-unavailable`→no-lever; anything else → `null` (caller reports it as unclassified).
  - `type ResearchRow = { politician_id: string; office_id: string; level: Level; value: number | null; blank_reason?: string; blank_class?: BlankClass; record_kind: 'vote-yes'|'vote-no'|'sponsor'|'author'|'own-words'|'none'; gate?: string }` — the `rows.tsv` row (tab-separated, header row with exactly these column names).
  - `parseRowsTsv(text: string, file: string): ResearchRow[]` — throws `Error` naming file, line and column on any bad cell.
  - `summarise(rows: { level: Level; value: number | null; blank_class?: BlankClass; record_kind?: ResearchRow['record_kind']; gate?: string }[]): SeatRateReport` where `SeatRateReport = { byLevel: Record<Level, { rows: number; seated: number; blank: number; byClass: Record<BlankClass|'unclassified', number>; perRung: Record<'1'|'2'|'3'|'4'|'5'|'between', number>; affirmative?: { rows: number; seated: number; rate: number | null } }>; total: same-shape-without-byLevel }`. `affirmative` is present only when rows carry `record_kind`: it counts `vote-yes`, `sponsor`, `author` rows with no `gate`.
  - `loadDbRows(q: Query, topicKey: string, seasonId: string)` → rows from `inform.politician_answers` joined to the office's district for `level`, blank reason from the matching `stance_research_review.proposed_blank_reason` when present.
  - CLI: `topic-seat-rate --topic <key> [--season open|draft|<uuid>] [--research <stage0a dir>] [--json]`. With `--research`, rows come from `<dir>/rows.tsv` instead of the database and the report includes `affirmative`.
- [ ] **Step 1: Write failing tests**:
  - `zero rows` → `summarise([])` gives `total.rows === 0` and `affirmative?.rate ?? null` is `null`; the CLI formatter prints `no rows`.
  - `half value is seated in between` → `[{level:'state', value:2.5}]` → `seated 1`, `perRung.between 1`.
  - `blank classes` → value 0 with `blank_class:'gate'` counts under `byClass.gate`; a 0 with no class counts under `unclassified`.
  - `affirmative excludes gated and No` → rows: vote-yes seated, vote-yes gated (`gate:'consent'`) blank, vote-no seated, sponsor blank → `affirmative = { rows: 2, seated: 1, rate: 0.5 }`.
  - `blankClassForReason` maps each listed reason as above and returns `null` for `'banana'`.
  - `parseRowsTsv` throws a message containing the file name, `line 3` and `blank_class` for an unknown class on line 3.
- [ ] **Step 2: Run** `npm test --prefix backend -- seatRate` → FAIL.
- [ ] **Step 3: Implement** `seatRate.ts` (pure parts) and `loadDbRows` (one parameterised SELECT; no writes).
- [ ] **Step 4: Implement** `topic-seat-rate.ts`: table output per level (rows, seated, rate, blanks by class) plus `--json`.
- [ ] **Step 5: Run** tests → PASS; typecheck clean; then a live read-only run: `npm run topic:seat-rate --prefix backend -- --topic education-equity-programs --season open` → prints a table (expect 0 rows for politicians: the topic has 0 seats).
- [ ] **Step 6: Commit** `feat(topic-prep): seat-rate report by level and blank class`.

### Task 3: Gate pre-screen and ladder lint

**Files:**
- Create: `backend/scripts/lib/gatePrescreen.ts`, `backend/scripts/lib/gatePrescreen.test.ts`
- Create: `backend/scripts/lib/ladderLint.ts`, `backend/scripts/lib/ladderLint.test.ts`, `backend/scripts/topic-ladder-lint.ts`
- Modify: `backend/package.json` (add `"topic:ladder-lint": "tsx scripts/topic-ladder-lint.ts"`)

**Interfaces:**
- Consumes: `Vote` from Task 1.
- Produces: `gateForVote(v: Vote, opts: { ownMotion: boolean; higherLawDuty: boolean; multiSubject: boolean }): string | null` — returns the first gate that applies, in this order: `'multi-subject'`, then for `body_size <= 10`: `'consent'` (kind consent or en-bloc, or `ownMotion` false), `'higher-law-duty'`; for larger bodies: `'near-unanimous'` when `no / (yes + no) < 0.10`; else `null`. Unknown `body_size` uses `yes + no + (absent ?? 0)`.
  `gateForSponsor(filedVersionMatchesTopic: boolean): 'off-version-sponsor' | null`.
  `lintRungs(rungs: string[]): { rung: number; check: string; match: string }[]` with the pilot T6 checks, copied from `.planning/research/s3-pilot-equity-programs/stage3/t6_lint.py` (workspace root): degree words `more|less|some|significant|strong|modest|reasonable|appropriate|limited|broad(ly)?|small|large|minimal|substantial`; `and`; `at most`; `without`; `only`; `while`; `every|any|all` — whole words, case-insensitive. Raw hits are reported; the skill tells the runner that an `and` inside one object list or an `every` that is an object can be accepted, with a reason written next to it (as the pilots did). CLI `topic:ladder-lint --topic <key> [--season open|draft]` reads the served rungs read-only and prints the hits.
- [ ] **Step 1: Write failing tests** with the pilot values:
  - `MD HB 1386 House 120-16 is not near-unanimous` (11.8% No, body 141) → `null`.
  - `a 140-5 chamber is near-unanimous` → `'near-unanimous'`.
  - `7-member board, 7-0, own action item, own choice` → `null`.
  - `7-member board on consent` → `'consent'`.
  - `7-member board carrying out a state duty` → `'higher-law-duty'`.
  - `11-member board 6-5` (Virginia Beach shape) → `null`; `11-member board 11-0` → `'near-unanimous'`.
  - `multi-subject wins over every other gate` → `'multi-subject'`.
  - `sponsor of an off-topic filed version` → `'off-version-sponsor'`.
  - `lintRungs on equity control rev 1` (the five rung texts in `.planning/research/s3-pilot-equity-programs/stage4/revision.md`) → 6 hits: `and` on rungs 1, 2, 3, 5; `without` and `every` on rung 4.
  - `lintRungs on library Draft A` (rungs in `backend/migrations/CA_0310_library_books_s3_draft_a_revision.sql`) → 0 hits.
- [ ] **Step 2: Run** `npm test --prefix backend -- gatePrescreen ladderLint` → FAIL.
- [ ] **Step 3: Implement** the three functions and the lint CLI.
- [ ] **Step 4: Run** → PASS; typecheck clean.
- [ ] **Step 5: Commit** `feat(topic-prep): gate pre-screen and ladder lint`.

### Task 4: Blindness check

**Files:**
- Create: `backend/scripts/lib/blindnessCheck.ts`, `backend/scripts/lib/blindnessCheck.test.ts`
- Create: `backend/scripts/topic-blindness-check.ts`
- Modify: `backend/package.json` (add `"topic:blindness-check": "tsx scripts/topic-blindness-check.ts"`)

**Interfaces:**
- Produces:
  - `findForbiddenReads(transcriptJsonl: string, forbidden: string[], home: string): { line: number; path: string; tool: string }[]` — scans every tool call's input (Read `file_path`, Bash `command`, Grep/Glob `path`/`pattern`) for any forbidden path. Normalises both sides: expands `~` to `home`, decodes `%20`, unescapes `\ `, strips trailing `/`. A forbidden entry matches as a path prefix.
  - CLI: `topic-blindness-check --transcript <jsonl> --forbid <path> [--forbid <path> …] --out <file>`; writes `PASS` or one line per hit to `--out`; exit 1 on any hit.
- [ ] **Step 1: Write failing tests**:
  - `clean transcript passes` → `[]`.
  - `detects Read of a forbidden file` → one hit with tool `Read`.
  - `detects the path inside a Bash command` (`cat ~/Documents/GitHub/.planning/research/x/stage1/FROZEN.md` with forbid `/Users/u/Documents/GitHub/.planning/research/x/stage1`, home `/Users/u`) → one hit.
  - `detects encoded and escaped spaces` (`Application%20Support` and `Application\ Support`) → hits.
  - `does not flag a sibling with a shared prefix` (`stage1b` when forbidding `stage1`) → `[]`.
- [ ] **Step 2: Run** `npm test --prefix backend -- blindnessCheck` → FAIL.
- [ ] **Step 3: Implement** module and CLI.
- [ ] **Step 4: Run** → PASS; typecheck clean.
- [ ] **Step 5: Commit** `feat(topic-prep): blindness check for drafter transcripts`.

### Task 5: Monday update formatter

**Files:**
- Create: `backend/scripts/lib/topicPrepUpdate.ts`, `backend/scripts/lib/topicPrepUpdate.test.ts`

**Interfaces:**
- Produces:
  - `type TopicPrepState = { topicKey: string; stage: '0a'|'0'|'1'|'2'|'3'|'4'|'done'|'parked'; path?: 'source'|'wording'; seatRateBefore?: number|null; seatRateAfter?: number|null; blockedOn: 'ruling'|'sources'|'dispute'|'nothing'; nextStep: string; owed: string[]; disputesOpen: number; expertQueue: number; revisionId?: string; researchFolder: string }`.
  - `storyName(topicKey: string): string` → `` `S3 topic prep — ${topicKey}` ``.
  - `statusLabel(s: TopicPrepState): 'Working on it'|'Stuck'|'Done'` — `done` → Done; `blockedOn !== 'nothing'` or `parked` → Stuck; else Working on it. (Before use, the skill checks these against the board's actual Status labels and records the mapping in `config.json`.)
  - `formatUpdate(s: TopicPrepState): string` — plain text, fixed line order: `Stage`, `Path`, `Seat rate` (`before → after`, percentages with no decimals, `—` when null), `Blocked on`, `Next`, `Owed` (bulleted, `none` when empty), `Disputes open`, `Expert queue`, `Revision`, `Folder`.
- [ ] **Step 1: Write failing tests**: `storyName`; the three `statusLabel` cases; `formatUpdate` snapshot for a full state; seat rates `0.75`/`null` render `75% → —`; empty `owed` renders `Owed: none`; output contains no `undefined`.
- [ ] **Step 2: Run** `npm test --prefix backend -- topicPrepUpdate` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(topic-prep): Monday update text`.

### Task 6: The skill

**Files:**
- Create: `.claude/skills/season-topic-prep/SKILL.md`
- Create: `.claude/skills/season-topic-prep/config.json`
- Create: `.claude/skills/season-topic-prep/RULINGS.md`
- Create: `.claude/skills/season-topic-prep/STAGE4-RECIPE.md`
- Create: `.claude/skills/season-topic-prep/templates/stage4-revision.sql`
- Create: `.claude/skills/season-topic-prep/ADVERSARIAL-CHECK.md`
- Create: `.claude/skills/season-topic-prep/SOURCE-STORE.md`
- Create: `.claude/skills/season-topic-prep/templates/BRIEF-census.md`, `templates/BRIEF-stage1.md`, `templates/drafter-prompt.md`, `templates/adversary-prompt.md`
- Create: `backend/scripts/lib/topicPrepSkill.test.ts`

**Interfaces:**
- Consumes: every CLI from Tasks 1–5 by its `npm run` name; `formatUpdate` / `storyName` from Task 5.
- Produces: `config.json` shape `{ monday: { boardId: "18417210762", groupId: "group_mm46qn8m", columns: { status: "color_mm468pe2", pillar: "color_mm46skd9", owner: "multiple_person_mm46ymaf", epic: "text_mm46npw7" }, epic: "Season 3 topic prep", statusLabels: { working: string, stuck: string, done: string } }, researchRoot: "~/Documents/GitHub/.planning/research", sourceStore: "backend/data/source-store", env: { mondayUserId: "EV_MONDAY_USER_ID", researchRoot: "EV_RESEARCH_ROOT" } }`. `statusLabels` is filled by reading the board's Status column once (Monday MCP) during this task.

Content each file must carry (copy and decisions from the spec; do not re-derive):
- `SKILL.md`: frontmatter `name: season-topic-prep`, a description that triggers on "prep a topic", "season prep", "topic audit", "seat rate", "Stage 0–4"; **first section = purpose (spec §1) in five sentences or fewer**; then: settings and env overrides (spec §9 item 6); the path decision (spec §5.0); one checklist per stage (spec §5.0–5.5) naming the files each stage writes (`stage0a/diagnosis.md`, `stage0a/rows.tsv`, `stage0/gates.tsv`, `stage1/FROZEN.md`, `stage1/EXCLUDE.txt`, `stage2/drafts.md`, `stage2/blindness-check.txt`, `stage3/results.md`, `stage3/disputes.md`, `stage3/expert-queue.json`, `stage4/README.md`); the Stage 0a lint step (`npm run topic:ladder-lint`); the stop points where the runner must say yes (path ruling when unclear; each ruling; starting a coding batch; applying a migration; merging); "save every source to the store" at each collecting step and "read the store first" at Stage 0 (spec §5.1); the Monday step at each stage end (Task 5 text, post as an update on the Story; create the Story if missing; never touch subitems or the private sprints board; print the update when Monday is unavailable); how rulings are asked (one plain question each with a recommendation).
- `RULINGS.md`: every bullet of spec §6 with date, source and scope; a "topic-scoped readings" section that lists equity R1 as topic-scoped; an "how to add a ruling" footer.
- `STAGE4-RECIPE.md` + `templates/stage4-revision.sql`: spec §5.5 steps in order; the SQL template is CA_0314's structure (`backend/migrations/CA_0314_equity_programs_s3_draft_b_prime_revision.sql`) with placeholders `{{SLOT}}`, `{{TOPIC_KEY}}`, `{{TOPIC_ID}}`, `{{REV_PREV_ID}}`, `{{TITLE}}`, `{{SHORT_TITLE}}`, `{{QUESTION}}`, `{{GUIDANCE}}`, `{{RUNG_1}}`…`{{RUNG_5}}`, `{{RUNG_MAP}}`, `{{RATIONALE}}`, `{{PUBLIC_NOTE}}`, `{{REVIEW_REF}}`, `{{S2_COUNT}}`, `{{S3_COUNT}}`; keeps the guidance UPDATE before approve, the rung_map keyed by old rung, the dry-run method (body twice inside BEGIN, forced RAISE), and "re-read season counts".
- `ADVERSARIAL-CHECK.md` + `templates/adversary-prompt.md`: spec §5.6 points 1–4; dispute format (deciding sentence quoted, plain explanation, two readings, recommendation); `expert-queue.json` shape `[{ politician_id, instrument_id, chair, deciding_quote }]`; the note that T4 items on the Blind Gold Desk are retired from the gate.
- `templates/drafter-prompt.md`: the Stage 2 blindness list and the instruction that the orchestrator runs `npm run topic:blindness-check` on the drafter's transcript afterwards.
- `SOURCE-STORE.md`: when to write each file type, `npm run source-store -- validate` before every commit, large copies stay in the research folder referenced by SHA-256.
- `BRIEF-census.md` / `BRIEF-stage1.md`: generalised from `.planning/research/s3-census-education-equity-programs-supplement/BRIEF.md` and `.planning/research/s3-pilot-equity-programs/stage1/BRIEF-stage1.md` (workspace root) with topic-specific text replaced by `{{…}}` placeholders; keep the fetching rules (item by item, no bulk portal requests, a blocked portal is a gap) and the gate pre-screen fields.

- [ ] **Step 1: Write failing test** `topicPrepSkill.test.ts`:
  - `SKILL.md has name season-topic-prep and a description`.
  - `SKILL.md opens with the purpose` → the first `##` section heading is `Purpose` and it contains `seat`.
  - `every file SKILL.md links to exists` (relative links under the skill folder).
  - `every npm script SKILL.md names exists in backend/package.json` (regex `npm run ([a-z:-]+)`).
  - `config.json parses and has boardId 18417210762 and groupId group_mm46qn8m`, and three non-empty `statusLabels`.
  - `stage4-revision.sql has every placeholder` from the list above and contains `UPDATE inform.compass_topic_revisions SET guidance`.
  - `RULINGS.md lists equity R1 under topic-scoped readings`.
- [ ] **Step 2: Run** `npm test --prefix backend -- topicPrepSkill` → FAIL.
- [ ] **Step 3: Read the board's Status labels** with the Monday MCP (`get_board_info` on `18417210762`) and fill `statusLabels`; if Task 5's labels differ, update `statusLabel` and its test to the real labels.
- [ ] **Step 4: Write the skill files** listed above.
- [ ] **Step 5: Run** `npm test --prefix backend -- topicPrepSkill` → PASS; full `npm test --prefix backend` → no new failures.
- [ ] **Step 6: Commit** `feat(topic-prep): season-topic-prep skill, rulebook, recipe and templates`.

### Task 7: Import pilot sources

**Files:**
- Create: `backend/scripts/import-pilot-sources.ts`
- Create: `backend/scripts/lib/pilotImport.ts`, `backend/scripts/lib/pilotImport.test.ts`
- Create: `backend/data/source-store/**` (generated JSON)
- Modify: `backend/package.json` (add `"import:pilot-sources": "tsx scripts/import-pilot-sources.ts"`)

**Interfaces:**
- Consumes: `upsertInstrument`, `upsertPerson`, `upsertJurisdiction`, `appendDeadEnd` (Task 1).
- Produces: `type PilotAdapter = { name: string; matches(dir: string): boolean; read(dir: string): { instruments: Instrument[]; people: PersonSources[]; jurisdictions: Jurisdiction[]; deadEnds: DeadEnd[] } }`; `ADAPTERS: PilotAdapter[]`; CLI `import-pilot-sources --research <root> [--dry-run]` printing counts per adapter and per output kind.
- Adapters in this task, one per known file shape: equity Stage 1 (`s3-pilot-equity-programs/stage1/texts-state.json`, `texts-boards.json`, `test-set-v1.json`, `school-voters.tsv`); equity census supplement (`s3-census-education-equity-programs-supplement/identity-check.json` → person term rows; its blocked-portal notes → dead ends); homelessness Stage 1 (`s3-pilot-homelessness-stage1/` frozen texts). Free-text notes are not converted (spec §9 item 4). Other pilots get adapters later.
- [ ] **Step 1: Write failing tests** using small fixtures copied from the real files' shapes into `scripts/lib/__fixtures__/pilot/`: each adapter's `matches` is true only for its folder; `read` of the equity fixture yields an instrument `WA-ESSB-5044-2021` with `kind`, tallies and members; every produced object passes the Task 1 schemas.
- [ ] **Step 2: Run** `npm test --prefix backend -- pilotImport` → FAIL.
- [ ] **Step 3: Implement** adapters and CLI.
- [ ] **Step 4: Run** tests → PASS; then `npm run import:pilot-sources --prefix backend -- --research ~/Documents/GitHub/.planning/research --dry-run` → counts printed; then without `--dry-run`; then `npm run source-store --prefix backend -- validate` → exit 0.
- [ ] **Step 5: Commit** `data(source-store): import equity and homelessness pilot sources` (store files + importer).

### Task 8: Seed the Monday Stories and hand over

**Files:**
- Modify: `docs/superpowers/specs/2026-10-20-season-topic-prep-skill-design.md` (status line → "approved 2026-10-20; built by <PR>")

- [ ] **Step 1:** Ask the runner (Chris) for a yes before any Monday write. Then, with the Monday MCP, for each of `education-library-books` (done, revision `7bb64029-0103-4df8-a4d8-3dcb2938f27f`), `education-equity-programs` (done, revision `516800d5-b3ce-4eff-ad34-6f1c25a272ef`), `education-school-police` (Stage 4 next), `homelessness` (Stage 3, first adversarial-check run), `education-school-budget`, `education-curriculum`, `education-gender-identity` (parked): find the Story by `storyName`, create it in `group_mm46qn8m` if missing with Epic, Pillar and Status set, and post `formatUpdate` as an update. Check each Story afterwards by reading it back.
- [ ] **Step 2:** Run the full suite `npm test --prefix backend`, `npm run typecheck --prefix backend`, `npm run lint --prefix backend` → all clean.
- [ ] **Step 3:** Update the spec status line; commit; push; mark PR EmpoweredVote/ev-accounts#1070 ready for review.
