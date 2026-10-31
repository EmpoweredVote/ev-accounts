# Stage 5 — code everyone

Stage 5 runs after Stage 4 has pinned a revision into the draft season. It researches everyone the topic applies
to, once per season, saves what it finds by person and by subject, codes each person from those saved findings,
and reports how the rungs held. An early check stops the run if the rungs look wrong, while they can still be
fixed. The design and its reasons: `docs/superpowers/specs/2026-10-22-season-topic-prep-stage5-code-everyone-design.md`.
The rulings it rests on: [RULINGS.md](RULINGS.md) "Stage 5 rulings".

Output folder: `<research folder>/stage5/`. Every command takes absolute paths (SKILL.md "Running the CLIs").

## Hard rules

- 🔴 **No database write before the early check passes.** Findings and codes stay in the research folder and the
  source store until then, so a rung fix or a split leaves no draft-season rows to undo. After it passes, every
  batch is written on the runner's yes, one batch at a time.
- `--season draft` on every step. Stage 5 never researches or writes the open season.
- **Search each person once per topic per season.** Everyone on the roster gets an own-words search, including
  people a vote on file already places: a vote saves the record search, not the own-words search.
- **Searching and coding are separate passes.** The searcher saves what it finds and decides nothing; the coder
  reads only the saved findings.
- **Subagents.** Stage 5 runs searchers and coders as subagents, unlike research-stances STEP 1, because no one can
  research thousands of people inline. What keeps that safe: the searcher never codes, its files are validated
  on import, the coder reads only saved findings, every code passes `checkCode`, and every quote shown to voters is
  fetched again and checked by a separate agent (the quote check) before it can be stored.
- A local record (ordinance or resolution) may support a local official's own words; it never seats alone.
- No party names or colours anywhere. Never infer a stance from silence.

## Who is in scope, and the 2026 election

Sitting officials at every level the topic is asked at, and active candidates in upcoming races at those levels.
No one else. The general election is 2026-11-03:

- **Before the results:** research sitting officials who stay (seat not up, or running again) and every active
  candidate, so every winner is done when the results come in. Officials who are leaving (`leaving = yes`) get
  the pre-fill only, no open search.
- **After the results:** drop the losers (their candidacy is no longer live). Finish only the close races as they
  are called. Georgia and Louisiana runoffs stay active until December.
- `leaving = yes` only when the official's own seat has an upcoming race (before 2027) with live candidates on file
  and they are not one of them. `leaving = unknown` means the race data cannot say (no race on file for the seat,
  or no candidates loaded for it; 2026-10-22: Massachusetts has 200 state races on file and 4 candidates). Report
  the count; `unknown` gets the full search.

## Steps

### 1. Roster

```bash
npm run topic:stage5-roster --prefix backend -- --topic <key> --out <abs>/stage5/roster.tsv
```

It prints the counts per level, scope, leaving and state, and writes `roster.gaps.tsv` (active candidates with no
politician record, offices with no known level, levels the topic is not asked at). **Show the runner the counts
and the gaps before anything runs.**

### 2. Pre-fill from roll calls on file

Write `stage5/subjects.json`: each census instrument's subjects in plain words (`{ "IN-SB-483-2011": ["voter ID at
the polls"] }`), read from its title and operative text. Then:

```bash
npm run topic:stage5-prefill --prefix backend -- --topic <key> --research <abs topic folder> --subjects <abs>/stage5/subjects.json --dry-run
npm run topic:stage5-prefill --prefix backend -- --topic <key> --research <abs topic folder> --subjects <abs>/stage5/subjects.json
```

Members with no politician id land in `stage5/prefill/unmatched.json`. Match them with `npm run census:identity`
(official member lists, never surname alone), set the ids on the instruments, and run the pre-fill again; it adds
only what is new.

### 3. Search, one unit at a time

Order: **federal** as one batch; then **states one at a time**, the first two or three chosen to differ on the topic
(they are the early check); then the rest; then **local**; then candidates' remaining gaps.

```bash
npm run topic:stage5-find --prefix backend -- next --topic <key> --season draft --unit federal --size 20 --roster <abs>/stage5/roster.tsv --out <abs>/stage5/batches/federal-01.tsv
```

Brief one `source-collector` subagent per person with [templates/BRIEF-stage5-find.md](templates/BRIEF-stage5-find.md),
each writing `stage5/raw/find/<politician_id>.json`. Run them in parallel. Then import:

```bash
npm run topic:stage5-find --prefix backend -- import --topic <key> --season draft --dir <abs>/stage5/raw/find --roster <abs>/stage5/roster.tsv
```

A refused file names the person and the problem: fix the file or re-brief that person. **To resume after a stop,
import first, then run `next` again**: it lists only people with no search for this topic and season, so files
written but not imported would be listed again. Commit the store's
`findings/` with the stage PR (`npm run source-store --prefix backend -- validate` first).

### 4. Code

Run [templates/stage5-coder-prompt.md](templates/stage5-coder-prompt.md) on the most capable model, one subagent
per batch of about 20 people, writing `stage5/codes/<politician_id>.json`. The ladder text comes from
`npm run topic:ladder-lint --prefix backend -- --topic <key> --season draft`.

### 5. Early check (after federal and the first two or three states)

```bash
npm run topic:stage5-report --prefix backend -- --topic <key> --research <abs topic folder> --units federal,state:xx,state:yy --notes-out <abs>/stage5/notes.jsonl --out <abs>/stage5/early-check.md --early
```

Exit 3 means some codes failed their check: fix those first. Then run the theme pass,
[templates/stage5-theme-prompt.md](templates/stage5-theme-prompt.md), as a fresh subagent on `notes.jsonl`,
writing `stage5/themes.json`, and run the report again with `--themes <abs>/stage5/themes.json`.

**The bar (ruled 2026-10-22):** stop when "doesn't fit" is **more than 1 in 5** of the people with any on-topic
evidence, or when **any one theme holds more than 1 in 10** of them (exit 4). Doesn't-fit cases whose only record
is a No vote (`nay-only`) or a gated vote (`gate`) are reported apart and left out of both sides of both bars: no
rung change can seat them. A large unit may be checked on a **seeded sample** (record the seed and the draw before
drawing); the rest of the unit follows once the check passes. 🛑 Either way, show the runner the
split and the themes. On a stop, ask one question: fix the rungs first (back to Stage 2, or a split), or carry on.
Recommend one, with the cases that show why.

### 6. Full report

When every unit is coded, run the report without `--units` and without `--early`, to `stage5/report.md`, with a
fresh theme pass over all the notes. Add the plain recommendation: ship the rungs as they are, fix them (with the
cases), or split the topic. 📋 Monday step (SKILL.md), stage `5`.

### 7. Write and show (after the early check passes)

Once the early check passes, the coded people are written one **batch** at a time: one unit (federal, or one state)
per batch. Each batch is prepared as a dry run, shown to the runner, and written after the runner's yes for that
batch. Voters see the result only when the draft season opens.

**First, once per topic, migration CA_0322.** It adds `inform.topic_research_outcomes` (the "we researched"
marker, kept apart from `value = 0`) and `inform.own_words_passages` (which can hold only a passage with a passed
quote check). 🛑 It needs two yeses from the runner: one for a `BEGIN … ROLLBACK` dry run, and one for the real apply.

#### The recipe, in order

The `voting-rights` state batches (2026-10-29/30: TX, WI, NC, CA, VA, AZ, MI, IN) worked out the order below. The
newest worked example is `.planning/research/s3-prep-voting-rights/stage5/write/in-01/PREVIEW.md`. Each step names
the file it leaves in the batch folder, `stage5/write/<unit>-NN/` (for example `in-01`).

| # | Step | Leaves |
|---|---|---|
| 0 | Dry run 0 | `dry-run-0.txt`, `research-stage5-0.csv` |
| 1 | Quote check | lines appended to `stage5/quote-checks.jsonl` |
| 2 | Dry run again; hand rows | `research.csv`, `hand-rows.md` |
| 3 | Bundle | `politicians.json`, `topics.json`, `season.json`, `bundle-output.txt` |
| 4 | Evidence | `evidence.csv`, `evidence-missing.json` |
| 5 | Old Season 1 sources | `fallback/` |
| 6 | Party sweep and fix | `party-sweep.jsonl`, `party-dropped.json` |
| 7 | Roll calls: official or LegiScan, cross-checked | `legiscan/` |
| 8 | Bill text | `bill-text.json` |
| 9 | Gate to 0 high | `gate-output-final.txt`, `overrides.json`, `held.txt` |
| 10 | Party check on the research text | `party-sweep-research.jsonl` |
| 11 | Audit | `audit-output.txt` |
| 12 | Verifier dry run | `verify-dry-run.txt`, `publish-report.json` |
| 13 | `PREVIEW.md` → 🛑 the runner's yes | `PREVIEW.md` |
| 14 | Write, queue for review, read back | `stage5-write-apply.txt`, `verify-apply.txt`, `readback.txt` |
| 15 | 🛑 Approve the review rows (a separate yes) | `review-apply.txt` |

Save a copy of `research.csv` and `evidence.csv` before each step that changes them (`research-pre-<step>.csv`), so
any step can be undone and the diff can be read.

**Tools.** The `topic:` scripts, `build-stance-topic-bundle.ts`, `stance-gate.ts`, `audit-chair-evidence.mjs`,
`verify-stance-research.ts` and `legiscan-evidence-lines.ts` are in `backend/scripts/`. The batch tools named below
(`build_evidence.py`, `party_sweep.mts`, `legiscan_rollcalls.mts`, `approve_batch.mts`, `pdf_pages.py`,
`s1-sources.mts`, `fallback/fetch.mts`, `readback.mts`, and the per-state `add_*.py` / `merge.py` patterns) are
being moved into `backend/scripts/stage5/`. Until that lands, they are in
`.planning/research/s3-prep-voting-rights/stage5/write/` (`tools/`, `in-01/tools-in/`, `in-01/fallback/`,
`va-01/tools-va/`, `ca-01/tools-ca/`) on Chris Andrews' machine. 🔴 Those copies hard-code the `voting-rights` topic
id, the draft season id and the `.wt-vr-ca` worktree path: change all three before you run one for another topic.

**Running them.** Run every `tsx` helper from a backend folder whose `.env` is linked to
`ev-accounts/backend/.env`, as `ADMIN_INGEST_TOKEN=placeholder npx tsx --env-file=.env <script>`. Run the Python
tools as `python3 -I <tool> <batch dir>`. Three zsh traps:

- Write `"${p}:state"`, never `"$p:state"`: zsh reads `$p:s` as a modifier.
- Do not `echo =====`: zsh expands a word that starts with `=` as a command path, and the command fails.
- Run each `git rev-parse` as its own call. Do not chain it with other commands.

**Held people.** A person whose row cannot pass yet (a tool gap, or a new item that needs a re-code check) is
**held**: their id goes in `held.txt`, and their rows come out of `research.csv` and `evidence.csv` (keep the full
set as `research-with-held.csv` / `evidence-with-held.csv`). A coded person who is leaving and is left out of the
batch on the runner's choice goes in `moved.txt`. Set both lists' code files aside before each `topic:stage5-write`
run and put them back after (`in-01/dryrun.sh` does both). Nothing is written for a held person. They follow in a
small batch of their own (`<unit>-NN-<name>`) once the gap is fixed.

**0. Dry run 0.**

```bash
npm run topic:stage5-write --prefix backend -- --topic <key> --research <abs topic folder> --season draft --units state:xx --csv-out <abs>/stage5/write/<batch>/research-stage5-0.csv
```

It reads the database only to find the draft season. It fetches each own-words passage's page again and keeps the
passage only when it is there word for word, whatever the quote check said. A page that is not HTML (a PDF) or will
not load keeps the quote check's word and is listed under **not re-checked on the page**. It prints:

- the outcome rows by type, and the passages it would store;
- **not in research.csv**: blanks whose detail fits no single codebook V6 reason. Step 2 adds those rows by hand.
- **refused**: codes that fail `checkCode` (`code`), and passages kept off the page (`passage`): no passed check,
  text changed since its check, a party label left in what voters would see (or a `shown_text` that is not a
  clean bracket edit), or a local record with none of their own words beside it. The
  person's outcome row is still written for a refused passage.

It also writes `research.csv` for the seats and blanks. Fix every refused code before going on.

**1. Quote check.** Run [templates/stage5-quote-check-prompt.md](templates/stage5-quote-check-prompt.md) as a
**separate** agent: never the searcher or the coder. Use one subagent per batch of about 20 findings. Check every
finding that a `doesnt-fit` code cites and that is own words or a local record. The agent fetches each page fresh
and writes one line per finding to a batch file (`qc/qc-1.jsonl`). Validate it with `readQuoteChecks`
(`backend/scripts/lib/stage5QuoteCheck.ts`) before you append it to `stage5/quote-checks.jsonl`. A passage
**passes** only when:

- it is on the page word for word (only whitespace, quote marks and long dashes may differ);
- it is the person's own words (codebook V1; a small named group's joint statement counts, RULINGS.md "A small
  group's joint statement is each signer's own words");
- it is on the topic (a "would have voted" line that names nothing on the question is not, RULINGS.md "A 'would
  have voted' statement is off topic");
- a party is not its point (it does not call on voters to back or oppose a party);
- for a local record, the plain-words note voters see is a fair summary of the act.

A passage that only mentions a party passes with each party label bracketed out: the check writes `shown_text`, the
passage with each label replaced by a word from the fixed list ("[…]", "[some lawmakers]", "[some officials]",
"[some voters]", "[some states]", "[others]"). The exact words stay stored; voters see `shown_text`, with the source
link under it. The writer refuses a `shown_text` that changes anything but party labels (`bracketEditProblem`,
`backend/src/lib/partyLabels.ts`) or still has a label (RULINGS.md "Party labels never reach a reader").
Each check also records the sha256 of the exact text voters will see (`shown_text` when there is one), so text
edited later has no check.
Run the check again every time you write a batch. The newest check for a finding wins, and a check made before
the code was made never counts. Each line's `at` is an ISO timestamp with a time zone.

**2. Dry run again; hand rows.** Run the dry run again (`research-stage5-1.csv`) so the passed checks count, and
copy it to `research.csv`. Then add a row for each blank listed under **not in research.csv**, by the ruling in
RULINGS.md "Mapping a blank to a V6 reason": off-question, no-side and gated blanks → `no-evidence`; blanks that
show a side → `direction-only`. Write each one, with its reason, in `hand-rows.md`, and append the rows from the
person's code file (pattern: `in-01/tools-in/add_hand_rows.py`).

**3. Bundle.** Build the research-stances bundle for the coded people of this batch only:

```bash
cd backend && args=(); while read p; do args+=(--politician "${p}:state"); done < <batch>/pids.txt
ADMIN_INGEST_TOKEN=placeholder npx tsx --env-file=.env scripts/build-stance-topic-bundle.ts --dir <batch> --season draft "${args[@]}"
```

`pids.txt` holds the roster ids at this level and state that have a code file. Use `"${p}:federal"` for a federal
batch.

**4. Evidence.** `stance-gate` needs an `evidence.csv`, and Stage 5 has no other step that builds one.

```bash
python3 -I build_evidence.py <batch> <abs>/stage5/roster.tsv <abs>/backend/data/source-store/findings --fetch --level state --state XX
```

It rewrites `research.csv` (sources from the cited findings) and writes `evidence.csv` (snippets cut from each
fetched page, party labels skipped). Every page it could not read goes in `evidence-missing.json`. Read that list
by host. A state legislature site that answers with a "please enable JavaScript" page or a bot check will fail the
verifier too: its votes and sponsorships need step 7, and its bill text needs step 8. PDF sources: run
`pdf_pages.py <batch>` (it uses `pdftotext`; a raw PDF must never become a snippet).

**5. Old Season 1 sources.** Do this now, not at the end. A blank that would replace an answer voters see in an
earlier season must show that the old answer's sources were examined (`checkBlankExaminedFallback`). Reading them
early finds a new on-topic item while the person can still be re-coded, before the gate work is spent on them.

1. Run `stance-gate.ts --dir <batch>` and a verifier dry run (step 12) once, to get `publish-report.json`. Gate
   findings are expected at this point.
2. `s1-sources.mts <batch>` lists, for every blank over a shown answer, the sources of that answer
   (`fallback/fallback-required.json`).
3. Drop OnTheIssues and Wikipedia (RULINGS.md "OnTheIssues and Wikipedia are never sources"). Load the rest
   through the verifier's own fetch steps (`fallback/fetch.mts`), so a page the verifier cannot load is known now.
4. One agent reads the loaded pages for the question (`fallback-read.json/.md`). Check its "nothing on topic"
   answers yourself.
5. A page with a **new** on-topic item: hold the person (`held.txt`) for a re-code check. Otherwise list each loaded
   page on the blank as examined, with a party-free snippet (pattern: `in-01/tools-in/add_fallback.py`).
6. A blank whose old answer rests only on OnTheIssues or Wikipedia is written as an outcome row with no source and
   no review row (as `nc-01-stein`).

**6. Party sweep and fix.**

```bash
npx tsx party_sweep.mts <batch>/evidence.csv > <batch>/party-sweep.jsonl
```

It lists every snippet that names a party (`namesParty`, plus roll-call party letters: "CLANCY D N", "(R)",
"R-Dist", "(D-Bloomington)"). A snippet is never edited inside: cut it before the label when the person and the act
are still in what is left, or drop it. A page left with no snippet comes off the row's sources
(`party-dropped.json`; pattern: `in-01/tools-in/party_fix.py`). The sweep must end at 0. A party word inside a
source's **web address** is fine (RULINGS.md "A party word in a source address is fine").

**7. Roll calls: official or LegiScan, cross-checked.** For every vote and sponsorship a seat rests on, check the
official page the verifier will read. Use it when it loads, names the person in a way the verifier can match, and
prints no party by the names. Otherwise cite a LegiScan line instead. The legislature sites met so far:

| State | Official page | What was done |
|---|---|---|
| WI | Assembly roll calls print a party letter by each name | LegiScan lines |
| NC | roll calls print party headings and surnames only | LegiScan lines, matched by bill, date and motion |
| AZ | the vote API prints `"Party":"R"` by each name (the sweep misses it) | LegiScan lines |
| MI | journal snippets mis-decoded, or cut from the attendance list | LegiScan lines |
| IN | iga.in.gov is a JavaScript app to a plain fetch | LegiScan lines; bill text as a PDF (step 8) |
| TX | robots-blocked bill pages | LegiScan lane (PR #1218) |

Steps:

1. Map each official roll call to the LegiScan roll call of the same bill, chamber and counts
   (`legiscan_rollcalls.mts <ST> <vote-pages.json> <out.json>`, or a per-state table as
   `in-01/tools-in/legiscan_pairs.py`). Write `legiscan/pairs.csv` (`full_name, last_name, topic_key, source_url`).
2. `npx tsx --env-file=.env scripts/legiscan-evidence-lines.ts --in <batch>/legiscan/pairs.csv --out <batch>/legiscan/legiscan-evidence.csv`.
   A pair with no line is reported: usually a name LegiScan prints another way. Hold that person; do not guess.
3. Merge (pattern: `in-01/tools-in/merge.py`): cite the LegiScan URL; take an unreadable official page off the row
   only when every act of the person on it now has a line; and cross-check each vote line against the act in the
   finding (`legiscan/crosscheck.json`). 🔴 It must show **0 disagree**. LegiScan's totals can differ from the
   official tally by one (IN SB 10 House vote: official 66-26, LegiScan 66-25); what must agree is each person's
   own vote.

Every LegiScan call counts against the monthly cap (`LEGISCAN_API_KEY`). The lines print no party.

**8. Bill text.** When the reasoning quotes a bill's words and the cited page cannot be read, the gate cannot find
the quote. Cite the bill text itself: the enrolled act from the official site, or the source store's saved copy
(`backend/data/source-store/instruments/<juris>/<id>.json`, `provenance.saved_copy` and `urls`). Check its sha256
against the store's copy, and add the sentences that hold each quote as passages: 25 words or more each
(pattern: `in-01/tools-in/add_bill_text.py`; in IN this cleared 290 of 310 high findings). A bill names no voter,
so the verifier does not count it as a source for the person; it only meets the gate's quote check.

**9. Gate to 0 high.**

```bash
npx tsx scripts/stance-gate.ts --dir <batch>
```

Work every high finding down to 0. Two tools, and they are not the same:

- **Trim** (`overrides.json`, applied by `in-01/tools-in/apply_overrides.py`): an edit to the **research text
  only**, never to a stance or a value. Use it for a side-list bill the seat does not rest on and with no readable
  page (drop its number), quote marks the coder put round its own words, or a quote that the page splits at a
  comma. Each entry records the old words, the new words and why. 🔴 The code file still says the old words; say
  so in the preview.
- **Hold** (`held.txt`): a finding that only new evidence or a code change could clear.

Medium `statement-needs-review` findings are expected for own-words seats: they go to review. A seat placed on own
words alone is `statement` evidence, so it keeps the `statement-evidence` hold until the topic's blind check passes
(section 8 below).

**10. Party check on the research text.** Run `party_sweep.mts` on the research text too: make a temporary
evidence-shaped CSV with one row per `research.csv` row and the reasoning as its snippet. Also
`grep -ciE 'republican|democrat|\bGOP\b' research.csv`. Both must be 0, except party words inside web addresses.

**11. Audit.**

```bash
node scripts/audit-chair-evidence.mjs --csv <batch>/research.csv
```

It lists blank rows too (it does not read blanks), so count the flags on seated rows. A seat on a record must not
fail. An own-words seat that names no bill is flagged; that is expected, and it goes to review.

**12. Verifier dry run.**

```bash
ADMIN_INGEST_TOKEN=placeholder npx tsx --env-file=.env scripts/verify-stance-research.ts --dir <batch> --season draft --threshold 1 --batch-id <batch>
```

Read the counts (review, unchanged, re-research) and `publish-report.json`. Every seat needs at least one verified
source. A blank whose old answer has no verified source is queued but cannot be approved: name those in the
preview. A host whose certificate chain is incomplete needs `NODE_EXTRA_CA_CERTS` (Ohio,
`write/federal-merrin/`).

**13. `PREVIEW.md`, then the runner's yes.** One page: scope (roster count, coded, out of scope, leaving, held and
why); what it would write (outcomes by type, passages, seats by rung and what they rest on, hand rows); the quote
check; evidence (missing pages by host, party sweep, roll calls and the cross-check, bill text, trims); gate, audit
and verifier counts; old Season 1 sources; and the exact commands it will run on yes. 🛑 Show it to the runner.
Write nothing until the runner says yes **for this batch**.

**14. Write, queue for review, read back.** On yes:

1. Run `topic:stage5-write` with `--apply` and without `--csv-out`, with held and moved codes set aside
   (`dryrun.sh apply`). It writes the outcomes and passages in one transaction. Exit 3 with "WROTE" is fine. It
   refuses to run while any code is refused: fix those codes and dry-run again first, or an earlier write for
   those people would stay live. Running it again for the same people replaces their outcome and their passages.
   It refuses any season but the draft one.
2. `verify-stance-research.ts` with the step 12 flags plus `--apply --editor-id <editor uuid>`. It queues every row
   for review (review-all).
3. Read back (`readback.mts <batch>/pids-write.txt`): outcomes by type, passages, and review rows by status must
   match the preview.
4. Add the counts to `PREVIEW.md` under "WRITTEN", and a line to the topic's hand-over log.

**15. Approve the review rows.** 🛑 A separate yes ("approve"). `approve_batch.mts <editor uuid> <batch>
[--skip "Name"]…` resolves the pending rows. Skip every own-words seat while the topic's blind check (section 8) has not
passed, unless the runner rules otherwise. Rows with no verified source cannot be approved. Read back again.

**What voters see when the season opens.** The profile reads
`GET /api/compass/politicians/:id/research-states` (and the candidate route). It shows:

- **No stance found:** "We researched {name} and found no public stance on {topic}." and the research date.
- **Own words:** the checked passages under "In their own words — not a position on the scale", each with its
  source and date. A local record appears in plain words.
- **Seated:** the topic shows as today. A seat in the same or a newer season hides the research state.

### 8. Blind check for own-words seats (after coding, per topic)

A seat placed on own words alone keeps the `statement-evidence` hold until a blind check on that topic agrees with
the coder at the Stage 3 bar (RULINGS.md "Own-words seats: the hold ends after a blind check").

1. **Draw the sample.** List the topic's own-words-only seats: codes with outcome `seated` and
   `evidence_basis: own-words`. Hash a seed and record it in `stage5/blind-check/seed.txt` before you draw, as in
   Stage 1. Then draw at least 30, or every one if there are fewer. Record the drawn ids in the same file.
2. **Code blind.** Run separate blind validators: fresh subagents on the most capable model that never saw the
   codes. Each gets only:
   - the codebook;
   - the pinned ladder (`topic:ladder-lint --season draft`);
   - the topic's annex and RULINGS.md;
   - each sampled person's findings file.

   Use the coder prompt, with the person's code removed. Write `stage5/blind-check/<politician_id>.json`.
3. **Compare.** A case agrees when both give the same rung, or both leave it blank. Agreement is agreeing cases
   divided by sampled cases. Write `stage5/blind-check/result.md` with the count and every miss, each with both
   readings and the findings cited.
4. **Decide.** At **95% or more**, open one PR that releases the hold for this topic and updates CLAUDE.md's
   "separate reliability stratum" rule (ruling 2b). Below 95%, the hold stays. Report the misses to the runner and
   recommend what to fix: the coder prompt, the annex, or the rungs.

