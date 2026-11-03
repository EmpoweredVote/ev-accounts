# Federal roll calls from the votes table — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stage 5 takes federal roll-call positions from `essentials.legislative_votes` by `politician_id` at step 2 (pre-fill), cross-checks the census hand lists, and builds the step-7 citations (House Clerk XML, Senate LegiScan page) from the matched roll calls.

**Architecture:** A pure matcher library (`scripts/lib/federalTableVotes.ts`) pairs each census roll call with exactly one table roll call. The pre-fill script reads the table per roster member (indexed by `politician_id`) and hands the result to the still-pure `prefillFindings`. A new step-7 tool (`scripts/stage5/federal-votes.ts`, shaped like `iga-votes.ts`) builds House lines from the Clerk XML by bioguide (`name-id`) and Senate pairs for the existing `legiscan-evidence-lines.ts`.

**Tech Stack:** TypeScript (tsx), vitest, `pg` via `src/lib/db.ts`, existing `rollCallEvidence.ts` / `legiscanEvidence.ts`.

**Spec:** `docs/superpowers/specs/2026-11-03-federal-table-roll-calls-design.md`

## Global Constraints

- 🔴 Every commit, PR, merge or DB write needs Chris Andrews' explicit yes, one each. Commit with an explicit pathspec: `git commit -F msg -- <paths>`.
- Read only against the database. No migration, no new index, no new table.
- Never query `essentials.legislative_votes` by `bill_id` or `external_vote_id` alone (no index; times out). Query by `politician_id`, restricted to the instruments' bill ids.
- Federal sessions only: `essentials.legislative_sessions.jurisdiction = 'federal'`, `external_id` = Congress number as text (`'118'`). Bill numbers look like `HJRES 44`, `HR 1615`.
- Party is never read, stored or printed. The Clerk XML carries `party="R"`: never copy it.
- Clerk XML is fetched with the verifier's identity (`src/lib/verificationFetch.ts`), once per roll call.
- Positions: table `yea` → `yea`, `nay` → `nay`, `present` → `abstain`, `not_voting` → no finding.
- Totals may differ by one between instrument and table; each person's own vote must agree.
- `stage5Prefill.ts` stays pure: no database, no network.
- Run tests from `backend/`: `npx vitest run <file>`.

## Review Focus

1. **One person, two chambers.** A roster senator who was a House member when a House roll call happened: the match is by roll call, not by the person's current chamber, so the House vote must still be found and cited as House. Test in Task 1.
2. **Same bill, same day, both chambers** (e.g. a concurrence vote): totals tell them apart; a tie of candidates is a two-match and is refused, never picked. Test in Task 1.
3. **A roster member missing from the table** (Padilla, Fuller): their hand-list vote is kept as today and listed, never dropped and never re-matched by surname. Test in Task 2.
4. **Two House members sharing a surname** (`Jackson (IL)` / `Jackson (TX)`): the House line is chosen by bioguide `name-id`, so the line carries the right state. Test in Task 3.
5. **A census vote the table has but with `not_voting` for a hand-listed `yea`:** that is a disagreement, not a silent skip. Test in Task 2.

---

### Task 1: Pure roll-call matcher

**Files:**
- Create: `backend/scripts/lib/federalTableVotes.ts`
- Test: `backend/scripts/lib/federalTableVotes.test.ts`

**Interfaces:**
- Produces:
  - `type TableVoteRow = { politician_id: string; external_vote_id: string; bill_number: string; congress: string; vote_date: string /* YYYY-MM-DD */; vote_question: string; position: 'yea'|'nay'|'present'|'not_voting'|string; yea_count: number; nay_count: number }`
  - `type TableRollCall = { external_vote_id: string; bill_number: string; congress: string; date: string; question: string; rc: number | null; yes: number; no: number; positions: Map<string, string> /* politician_id → table position */ }`
  - `function instrumentBill(instrumentId: string): { congress: string; bill_number: string } | null` — `US-HJRES-44-2023` → `{ congress: '118', bill_number: 'HJRES 44' }`; a non-`US-` id → `null`. Congress from year: `Math.floor((year - 1789) / 2) + 1`.
  - `function groupRollCalls(rows: TableVoteRow[]): TableRollCall[]` — one per `external_vote_id`; `rc` parsed from a trailing `RC# <n>`.
  - `type MatchResult = { kind: 'one'; roll: TableRollCall } | { kind: 'none' } | { kind: 'many'; candidates: string[] }`
  - `function matchRollCall(vote: Pick<Vote,'date'|'yes'|'no'>, bill: { congress: string; bill_number: string }, rolls: TableRollCall[]): MatchResult` — same congress, bill, date; `|yes-yea_count| <= 1 && |no-nay_count| <= 1`.
  - `function tableAct(position: string): 'yea'|'nay'|'abstain'|null`

- [ ] **Step 1: Write the failing tests**

```ts
it('derives Congress and bill from an instrument id', () => {
  expect(instrumentBill('US-HJRES-44-2023')).toEqual({ congress: '118', bill_number: 'HJRES 44' });
  expect(instrumentBill('US-HR-1-2025')).toEqual({ congress: '119', bill_number: 'HR 1' });
  expect(instrumentBill('IN-SB-10-2025')).toBeNull();
});
it('matches the one roll call with the same bill, date and totals within one', () => {
  // rolls: RC# 252 On Passage 219-210 and RC# 253 veto override 233-197, same bill-day
  expect(matchRollCall({ date: '2023-06-13', yes: 219, no: 210 }, hj44, rolls)).toMatchObject({ kind: 'one', roll: { rc: 252 } });
  expect(matchRollCall({ date: '2023-06-13', yes: 220, no: 210 }, hj44, rolls)).toMatchObject({ kind: 'one' });
});
it('refuses a census vote with no table roll call', () => {
  expect(matchRollCall({ date: '2023-06-14', yes: 219, no: 210 }, hj44, rolls).kind).toBe('none');
});
it('refuses, never picks, when two roll calls fit', () => {
  expect(matchRollCall({ date: '2023-06-13', yes: 219, no: 210 }, hj44, [...rolls, twinOf252]).kind).toBe('many');
});
it('tells a House roll call from a Senate one on the same bill and day by totals', () => {
  // House 219-210 and Senate 49-48 on HJRES 44, 2023-06-13
  expect(matchRollCall({ date: '2023-06-13', yes: 49, no: 48 }, hj44, withSenate)).toMatchObject({ kind: 'one', roll: { yes: 49 } });
});
it('groups rows by roll call whoever voted, so a senator\'s earlier House vote is found', () => {
  const g = groupRollCalls([houseRowFor('sen-now-1'), houseRowFor('rep-1')]);
  expect(g).toHaveLength(1);
  expect(g[0].positions.get('sen-now-1')).toBe('yea');
});
it('maps table positions to acts; not_voting is no act', () => {
  expect([tableAct('yea'), tableAct('nay'), tableAct('present'), tableAct('not_voting')]).toEqual(['yea', 'nay', 'abstain', null]);
});
```

- [ ] **Step 2: Run, expect FAIL** — `npx vitest run scripts/lib/federalTableVotes.test.ts` → module not found.
- [ ] **Step 3: Implement the interfaces above in `federalTableVotes.ts`.** Pure; imports only the `Vote` type from `./sourceStore.js`.
- [ ] **Step 4: Run, expect PASS.**
- [ ] **Step 5: Commit (after Chris's yes)** — `git commit -F msg -- backend/scripts/lib/federalTableVotes.ts backend/scripts/lib/federalTableVotes.test.ts`

### Task 2: Pre-fill takes positions from the table

**Files:**
- Modify: `backend/scripts/lib/stage5Prefill.ts` (`prefillFindings`, vote loop)
- Test: `backend/scripts/lib/stage5Prefill.test.ts`

**Interfaces:**
- Consumes: `TableRollCall`, `matchRollCall`, `instrumentBill`, `tableAct` (Task 1).
- Produces:
  - `prefillFindings(instruments, gates, roster, topicKey, subjects, table?: TableRollCall[])` — returns the existing fields plus `crosscheck: CrossCheck`.
  - `type CrossCheck = { disagree: Array<{ instrument_id: string; date: string; motion: string; politician_id: string; hand: string; table: string | null }>; handOnly: Array<{ instrument_id: string; date: string; motion: string; politician_id: string; hand: string }>; tableOnly: number; matched: number; unmatchedRollCalls: SkippedVote[] }`
- Behaviour when `table` is given, for each gates row whose instrument is `US-` and whose store vote is `kind: 'roll-call'`:
  - `matchRollCall` → `'one'`: for every roster member with a position in `roll.positions`, `tableAct(position)`; non-null → a finding, same shape as today, with `note` ending `positions from essentials.legislative_votes (<external_vote_id>).` For each hand member with a `politician_id` on the roster: table act differs (including table `null` where hand is `yea`/`nay`) → `disagree`; person absent from `roll.positions` → keep the hand finding, add to `handOnly`. Table findings for people with no hand `politician_id` count into `tableOnly`. Hand members with no `politician_id` are **not** added to `unmatched` (the table settled identity).
  - `'none'` / `'many'` → today's path for that vote; push to `crosscheck.unmatchedRollCalls` with reason `table: no roll call` / `table: N roll calls fit`.
- Without `table`, behaviour and output are unchanged (existing tests still pass).

- [ ] **Step 1: Write the failing tests**

```ts
it('takes positions from the matched table roll call, by politician id, with no name match', () => {
  const r = prefillFindings([inst], gates, roster, 'gun-policy', subjects, [roll252]);
  expect(r.findings.find((p) => p.politician_id === 'pid-unmatched-by-name')?.findings[0].act).toBe('nay');
  expect(r.unmatched).toHaveLength(0);
  expect(r.crosscheck.tableOnly).toBe(1);
});
it('reports a hand-list vote the table contradicts', () => {
  const r = prefillFindings([instWithWrongHandVote], gates, roster, 'gun-policy', subjects, [roll252]);
  expect(r.crosscheck.disagree).toEqual([expect.objectContaining({ politician_id: 'pid-a', hand: 'yea', table: 'nay' })]);
});
it('treats a table not_voting against a hand yea as a disagreement', () => {
  expect(prefillFindings([inst], gates, roster, 'gun-policy', subjects, [rollWithANotVoting]).crosscheck.disagree).toHaveLength(1);
});
it('keeps the hand finding of a roster member the table does not hold, and lists it', () => {
  const r = prefillFindings([inst], gates, roster, 'gun-policy', subjects, [rollWithoutPidB]);
  expect(r.findings.some((p) => p.politician_id === 'pid-b')).toBe(true);
  expect(r.crosscheck.handOnly).toEqual([expect.objectContaining({ politician_id: 'pid-b' })]);
});
it('falls back to the hand list, and says why, when no table roll call matches', () => {
  const r = prefillFindings([inst], gates, roster, 'gun-policy', subjects, []);
  expect(r.crosscheck.unmatchedRollCalls[0].reason).toBe('table: no roll call');
  expect(r.findings.length).toBeGreaterThan(0);
});
```

- [ ] **Step 2: Run, expect FAIL** — `npx vitest run scripts/lib/stage5Prefill.test.ts`.
- [ ] **Step 3: Implement** the behaviour above; update the file's header comment to say federal roll calls can come from the table.
- [ ] **Step 4: Run the whole file, expect PASS** (old tests included).
- [ ] **Step 5: Commit (after Chris's yes)** — pathspec: the two files.

### Task 3: Table read and `--from-table` in the pre-fill script

**Files:**
- Create: `backend/scripts/lib/federalTableRead.ts`
- Modify: `backend/scripts/topic-stage5-prefill.ts`

**Interfaces:**
- Consumes: `instrumentBill`, `groupRollCalls`, `TableVoteRow` (Task 1); `prefillFindings(..., table)` and `CrossCheck` (Task 2).
- Produces: `async function readTableRollCalls(pool: Pool, pids: string[], bills: Array<{ congress: string; bill_number: string }>): Promise<TableRollCall[]>` — one query per politician id: `JOIN essentials.legislative_bills b ON b.id = v.bill_id JOIN essentials.legislative_sessions s ON s.id = v.session_id WHERE v.politician_id = $1 AND s.jurisdiction = 'federal' AND (s.external_id, b.number) IN (...)`, `statement_timeout = '20s'`, inside `BEGIN READ ONLY … ROLLBACK`. Prints progress every 50 people.
- Script: `--from-table` reads the roster's ids and the `US-` instruments in `gates.tsv`, calls `readTableRollCalls`, passes the result. Writes `stage5/prefill/table-crosscheck.json` (the `CrossCheck`). 🔴 If `crosscheck.disagree.length > 0`: print each line (instrument, date, motion, politician id, hand, table — no name, no party), write **no findings**, exit 1. Prints `table: matched N roll calls, M not matched; findings from table X, hand only Y, disagree Z`.

- [ ] **Step 1: Typecheck** — `npx tsc --noEmit -p .` → clean for the touched files.
- [ ] **Step 2: Positive control (read only)** — `npm run topic:stage5-prefill -- --topic voting-rights --research <abs s3-prep-voting-rights> --subjects <abs subjects.json> --from-table --dry-run`. Expected: `matched` > 0; Jeffries (`J000294`'s politician id) has a finding on every House instrument roll call in that topic where the Clerk record shows him voting; `disagree` printed in full (any non-zero count is a finding to show Chris, not to fix by hand).
- [ ] **Step 3: Record the numbers** (matched, not matched, table-only, hand-only, disagree) for the PR body.
- [ ] **Step 4: Commit (after Chris's yes)** — pathspec: the two files.

### Task 4: House line from the Clerk XML by bioguide

**Files:**
- Modify: `backend/src/lib/rollCallEvidence.ts`
- Test: `backend/src/lib/rollCallEvidence.test.ts`

**Interfaces:**
- Produces: `function houseRollCallLineFor(xml: string, url: string, bioguideId: string): string | null` — finds the `<recorded-vote>` whose `name-id` equals `bioguideId`; returns `formatRollCallLine({ rollNum, year (from url), legisNum, question, surname: <legislator text without " (ST)">, state, vote })`; `null` if absent.

- [ ] **Step 1: Write the failing tests** (reuse the file's `XML` fixture)

```ts
it('builds the line for a member by bioguide, and the verifier accepts it', () => {
  const line = houseRollCallLineFor(XML, URL, 'J000304')!;
  expect(line).toContain('Jackson (TX) voted Aye.');
  expect(verifyRollCallLine(line, URL, XML, 'Jackson').verdict).toBe('verified');
});
it('never prints a party', () => {
  expect(houseRollCallLineFor(XML, URL, 'G000558')).not.toMatch(/\bparty\b|\(R\)|\(D\)/);
});
it('returns null for a member not on the roll call', () => {
  expect(houseRollCallLineFor(XML, URL, 'X000000')).toBeNull();
});
```

(Use the verdict string `verifyRollCallLine` returns for a pass in the existing tests.)

- [ ] **Step 2: Run, expect FAIL.** - [ ] **Step 3: Implement.** - [ ] **Step 4: Run, expect PASS.**
- [ ] **Step 5: Commit (after Chris's yes)** — pathspec: the two files.

### Task 5: Step-7 tool `federal-votes.ts`

**Files:**
- Create: `backend/scripts/stage5/federal-votes.ts`
- Create: `backend/scripts/stage5/federalVotesPlan.ts` (pure)
- Test: `backend/scripts/stage5/federalVotesPlan.test.ts`

**Interfaces:**
- Consumes: Task 1 (`TableRollCall`, `matchRollCall`, `instrumentBill`, `tableAct`), Task 3 (`readTableRollCalls`), Task 4 (`houseRollCallLineFor`), `readCsv` from `./lib.js`.
- Produces (pure): `function planCitations(seated: SeatedVote[], rolls: TableRollCall[]): { house: HouseCite[]; senate: SenatePair[]; unmapped: Unmapped[]; crosscheck: { agree: number; disagree: Unmapped[] } }` where
  - `SeatedVote = { politician_id: string; full_name: string; last_name: string; bioguide: string | null; topic_key: string; instrument_id: string; date: string; motion: string; act: string; yes: number; no: number; cited_url: string }`
  - House roll (`rc` set, total `yes+no > 150`): `HouseCite = { …SeatedVote, url: 'https://clerk.house.gov/evs/<year>/roll<rc padded to 3>.xml' }`.
  - Senate roll (≥ 115th Congress): `SenatePair = { full_name, last_name, topic_key, source_url: 'https://legiscan.com/US/rollcall/<bill_number without space>/id/<external_vote_id minus "legiscan-">' }` — the `pairs.csv` columns of `legiscan-evidence-lines.ts`.
  - Table act ≠ seated act → `crosscheck.disagree`; no match / no position / pre-115th Senate → `unmapped` with a reason.
- Script: `federal-votes.ts <batch dir> <store findings dir> --topic <key>`. Reads seated vote findings for `US-` instruments the way `iga-votes.ts` does; fetches each House XML once (verifier fetch) and builds lines with `houseRollCallLineFor`; writes `federal/lines.csv` (House), `federal/pairs.csv` (Senate, for `legiscan-evidence-lines.ts`), `federal/unmapped.json`, `federal/crosscheck.json`; cites the XML, uncites a covered page, rewrites `research.csv`/`evidence.csv` keeping `*-pre-federal.csv`, exactly as `iga-votes.ts` does. Exit 1 on any disagree.

- [ ] **Step 1: Write the failing tests**

```ts
it('cites a House vote at its Clerk XML, from the table roll number', () => {
  expect(planCitations([seatedHouse], [roll252]).house[0].url).toBe('https://clerk.house.gov/evs/2023/roll252.xml');
});
it('makes a LegiScan pair for a Senate vote from the table id, with no senate.gov lookup', () => {
  expect(planCitations([seatedSenate], [senateRoll]).senate[0].source_url).toBe('https://legiscan.com/US/rollcall/HJRES44/id/1343990');
});
it('stops on a seat whose act the table contradicts', () => {
  expect(planCitations([{ ...seatedHouse, act: 'yea' }], [roll252WithNay]).crosscheck.disagree).toHaveLength(1);
});
it('holds, never guesses, a vote with no single table roll call', () => {
  expect(planCitations([seatedHouse], []).unmapped[0].reason).toMatch(/no roll call/);
});
```

- [ ] **Step 2: Run, expect FAIL.** - [ ] **Step 3: Implement `federalVotesPlan.ts`, then the script.** - [ ] **Step 4: Run, expect PASS; typecheck clean.**
- [ ] **Step 5: Commit (after Chris's yes)** — pathspec: the three files.

### Task 6: Replay, Senate hand check, docs

**Files:**
- Modify: `.claude/skills/season-topic-prep/STAGE5.md` (step 2: `--from-table`, the stop on disagree; step 7: the federal row and command)
- Modify: `backend/scripts/stage5/README.md` (table row for `federal-votes.ts`)

- [ ] **Step 1: House replay** on a **copy** of `.planning/research/s3-prep-voting-rights/stage5/write/federal-01/` in the scratchpad. Compare `federal/lines.csv` with that batch's standard roll-call lines in `evidence.csv` (pattern `^House roll call \d+ \(\d{4}\), .*: .* \([A-Z]{2}\) voted (Yea|Nay|Aye|No|Present|Not Voting)\.$`). Expected: every old line reproduced, or each difference explained in writing; `crosscheck.json` 0 disagree.
- [ ] **Step 2: Verifier dry run on the copy** — `ADMIN_INGEST_TOKEN=placeholder npx tsx --env-file=.env scripts/verify-stance-research.ts --dir <copy> --season draft --threshold 1 --batch-id replay-federal`. Expected: no House roll-call line fails that passed before. Writes nothing to the database? — confirm from the script's header before running; if it writes, stop and ask Chris.
- [ ] **Step 3: Senate hand check** — pick three Senate roll calls on 115th+ instruments, build pairs with `planCitations`, run `legiscan-evidence-lines.ts` on them, and open each LegiScan page to confirm the person's vote. Record the three in the PR body.
- [ ] **Step 4: Update STAGE5.md and the README.**
- [ ] **Step 5: `npm run test:unit` and the CI static guards** (`check:occupancy`). Expected: green.
- [ ] **Step 6: Commit (after Chris's yes)**, then PR (after a second yes).
