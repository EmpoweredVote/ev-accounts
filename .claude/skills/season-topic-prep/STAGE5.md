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
  are called. Georgia and Louisiana runoffs stay active until December. "Drop" means **do not search or code** them
  from here on. 🔴 Anything already written for a person who then loses **stays**: never remove their outcome, passage
  or review rows (RULINGS.md "A loser's written research stays"). A close race may be written before it is called on
  the runner's say-so.
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
npm run topic:stage5-prefill --prefix backend -- --topic <key> --research <abs topic folder> --subjects <abs>/stage5/subjects.json --from-table --dry-run
npm run topic:stage5-prefill --prefix backend -- --topic <key> --research <abs topic folder> --subjects <abs>/stage5/subjects.json --from-table
```

Members with no politician id land in `stage5/prefill/unmatched.json`. Match them with `npm run census:identity`
(official member lists, never surname alone), set the ids on the instruments, and run the pre-fill again; it adds
only what is new.

**`--from-table` (federal votes; leave it out when the census has no `US-` instrument).** It also reads the
roster's federal roll calls on the census bills from `essentials.legislative_votes` (read only; roster ids with a
bioguide id), takes findings from the table, and checks each hand-listed vote against it, by politician id, never by
name: `yea` → yea, `nay` → nay, `present` → abstain, `not_voting` → no finding. It writes
`stage5/prefill/table-crosscheck.json`. 🔴 On any disagreement it prints each one, writes **no** findings and exits
1: fix the hand list or the store vote, then run it again. A hand-listed absent or recused against a table yea or nay
is a disagreement. A census vote the table cannot match (a 2013 Senate amendment, two roll calls that fit) keeps its
hand list and is listed as "not matched". The table read takes about 5 minutes for the federal roster.

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

#### 3a. Bill round one: sponsor cover

Before the search, put every topic bill a roster member sponsored into the state's core set, so the search does not
have to find it and no second bill round is needed (Wisconsin, Arizona and Georgia each needed one: 5, 8 and 13 bills).

```bash
python3 -I scripts/stage5/sponsor_cover.py <bills.json> --state XX --roster <roster.tsv> --core <core.json> --ds <legiscan ds root> --idmap <idmap.tsv> --candidates <stage5>/sponsor-candidates-xx.json
```

The keyword scan is wide (Georgia: 164 such bills). One Opus agent triages the titles with
[templates/stage5-sponsor-triage-prompt.md](templates/stage5-sponsor-triage-prompt.md); then the same command with
`--triage <triage.json> --write <new core.json>` keeps only the "fill" bills. It refuses while any candidate is
untriaged. Add the name matches it prints to `idmap.tsv` once checked.

#### 3b. Bill table

After the last bill round and the bill-text fill, one Opus agent reads each core bill once and writes the rung a Yes
supports, with the deciding words copied from the bill
([templates/stage5-bill-table-prompt.md](templates/stage5-bill-table-prompt.md)). Then:

```bash
python3 -I scripts/stage5/bill_table.py check <stage5>/bill-table-xx.json --ids <ids>          # exit 2 on any problem
python3 -I scripts/stage5/bill_table.py questions <stage5>/bill-table-xx.json --ids <ids> --out <stage5>/bill-questions-xx.md
```

`questions` lists the flagged bills and every person with a Yes on both sides of the middle rung. **The runner
answers that file before coding starts** (a runner stop). The answers go into the coder rulings digest.

#### Pilot rule: record first, search only where the record leaves the seat open — MISSOURI PILOT ONLY

> **Missouri pilot only (gun-policy, Season 3, 2026-11).** Do not use it for another state or topic until the pilot
> report says it held. It rests on one measurement: in Georgia, a record seat at rung 5 (244 people) or rung 2 (12)
> was never changed by the search; rung 3 changed 2.3% of the time and rung 4 10%.

1. Code everyone from the record alone: `coder-inputs.ts ... --record-only --coded-dir <stage5>/record-coded`, then
   `split-codes.ts ... --codes <stage5>/record-codes`. A record-only coder never codes no-stance (nothing was searched
   yet); a person with no record is listed in `<name>-no-record.txt` and searched.
2. `python3 -I scripts/stage5/search_list.py plan --record-codes <stage5>/record-codes --roster <roster.tsv> --skip-rungs 5,2 --out <stage5>/search-plan-xx`
   skips record seats at rungs 5 and 2, except a seeded random 20 of them (the control), which are searched.
3. Search and code everyone in `search.tsv` as usual.
4. `search_list.py adopt ...` first checks the control (exit 4 when more than 1 in 20 changed outcome or rung: then
   search the skipped people too, and report it), then copies the skipped people's record-only codes into `codes/`.

### 4. Code

One Opus `stage5-coder` subagent per batch of about 20 people. Build the batches with `coder-inputs.ts`; never fill
[templates/stage5-coder-prompt.md](templates/stage5-coder-prompt.md) by hand.

1. Once per topic, write `stage5/coder-config.json` (topic, season, season and revision ids, codebook version, date,
   the ladder text from `npm run topic:ladder-lint --prefix backend -- --topic <key> --season draft`, and the
   evidence basis by level) and `stage5/coder-rulings.md`: the runner rulings and store notes the coders apply, as
   `## Heading {scope}` sections of `- ` bullets. A scope is `{all}` (the default), `{federal}` or `{state:xx[,yy]}`;
   a bullet may carry its own scope first. Tag a ruling to one state only when it is about that state's bills and
   nothing else; a ruling that names another state's bill as an example of a general rule is `{all}`.
2. Build the batches:

   ```bash
   npx tsx scripts/stage5/coder-inputs.ts --config <abs>/stage5/coder-config.json --rulings <abs>/stage5/coder-rulings.md \
     --roster <abs>/stage5/roster.tsv --ids <ids file> --unit state:xx --name xx --out <abs>/stage5/code-briefs --coded-dir <abs>/stage5/coded
   ```

   Each batch gets a brief, one compact findings file (this topic only, word for word, without source-tracking
   fields; it refuses to write a file that does not rebuild to exactly what the store holds) and an ids list. It
   prints each ruling the unit's coders will not see: read that list.
3. Each coder writes ONE file, `stage5/coded/<batch>.json`. Check it and write the codes:

   ```bash
   npx tsx scripts/stage5/split-codes.ts <abs>/stage5/coded/<batch>.json --config <abs>/stage5/coder-config.json \
     --codes <abs>/stage5/codes --ids <abs>/stage5/code-briefs/<batch>.ids.txt
   ```

   It sets `coded_at` and computes `evidence_basis` from the cited findings (the coder never writes either), runs
   `checkCode`, and also refuses a bill named in the reasoning that is not in the person's findings, an annex or
   ruling label (S3, Q2, R5-AZ…) in the reasoning, and quote marks round words in no cited finding or bill text.
   Passing codes go to `codes/<politician_id>.json`; the rest go, with their reasons, to `coded/<batch>.sendback.md`
   (exit 3). Hand that file back to a coder for those people only. `--replace` for a re-code after a ruling.

### Pitfalls the first topic found (voting-rights, Season 3, 2026-10/11)

Each cost at least one re-code round or a store fix. Check them before coding a new topic.

- **Read bill text before coding.** Fetch the full text of broad or much-voted bills and draft each bill's verdict
  (an Opus draft, then a review) before the coders run. Three voting-rights re-code rounds came from text found late.
  Never overwrite a stored instrument's text with an earlier version (enrolled text beats as-introduced).
- **Read a vote on the version voted on.** An amendment can add or strike the topic's text between printer's
  numbers. PA SB 224 PN 1171 and PA SB 1 PN 385 passed the House after their voter-ID text was struck, and the store
  said they carried it (#1289). Check the journal for the version and for separate votes on the topic part
  (W3-R25). A House-added part was never in the Senate-passed or as-introduced version, so its sponsors did not
  sponsor it.
- **Linking votes.** A concurrence motion is not an amendment vote. On a same-day failed-then-passed roll call, take
  the later one. A cross-chamber sponsor fallback needs the printed first name to agree. Skip a vote taken before
  the topic's text existed.
- **Search notes.** A note whose first place starts with `status` is read as an exit by the coding scripts: keep
  `status:` for exits only.
- **Web-search budget.** About 200 searches per turn of the orchestrating session, shared by every subagent it runs.
- **Blank classes.** Coders drift between `gate` and `wording` for people whose only records widen an accepted
  list. Name that case in the coder prompt's blank-class rule.
- **Rulings live in the coder digest.** A runner ruling that exists only in a batch script is invisible to the next
  coder and the next topic. Add it to the digest the coders read, then to the scripts.
- **Store corrections keep finding ids.** A finding's id hashes its kind, URL, instrument, act, date and motion.
  Correct a wrong fact in the note and subjects, not the motion. A changed act changes the id: find the codes that
  cite the old one first.
- **Floor debate as evidence.** Pennsylvania's journals print floor remarks as text; Georgia keeps video only.
  Read `robots.txt` before fetching from any video host (palegis' Sliq player says `Disallow: /`).
- **Reasoning text is voter-facing.** When a store fix changes a fact that seated reasoning repeats, search the
  codes for the phrase and fix each row with a guarded text-only migration (CA_0355, CA_0357), not a batch
  re-write, which would send the rows back to review.

### 5. Early check (after federal and the first two or three states)

```bash
npm run topic:stage5-report --prefix backend -- --topic <key> --research <abs topic folder> --units federal,state:xx,state:yy --notes-out <abs>/stage5/notes.jsonl --out <abs>/stage5/early-check.md --early
```

Exit 3 means some codes failed their check: fix those first. Then run the theme pass,
[templates/stage5-theme-prompt.md](templates/stage5-theme-prompt.md), as a fresh subagent on `notes.jsonl`,
writing `stage5/themes.json`, and run the report again with `--themes <abs>/stage5/themes.json`. Do not fill the
template by hand: write it with

```bash
npm run topic:stage5-theme-prompt --prefix backend -- --topic <key> --season draft --notes <abs>/stage5/notes.jsonl --out <abs>/stage5/theme-prompt.md
```

It fills the ladder (the question and five rungs the season serves) and exits 1, writing nothing, if any `{{…}}`
slot stays unfilled. The Mississippi theme pass (2026-11-05) ran on a hand-filled copy with `{{LADDER_TEXT}}` left
in, and grouped the notes without the ladder.

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
are in `backend/scripts/stage5/`; its [README](../../../backend/scripts/stage5/README.md) lists each one with its
arguments. They take the topic, state and season as arguments, so they work for any topic. A one-off fix for a
single batch (a sentence added by hand, a page uncited because the research text says it is unused) stays in that
batch folder, with a line in its `PREVIEW.md`.

**Running them.** Run every tool from a worktree's `backend/` folder whose `.env` is linked to
`ev-accounts/backend/.env`: `ADMIN_INGEST_TOKEN=placeholder npx tsx --env-file=.env scripts/stage5/<tool>.ts`, and
`python3 -I scripts/stage5/<tool>.py`. Three zsh traps:

- Write `"${p}:state"`, never `"$p:state"`: zsh reads `$p:s` as a modifier.
- Do not `echo =====`: zsh expands a word that starts with `=` as a command path, and the command fails.
- Run each `git rev-parse` as its own call. Do not chain it with other commands.

**Held people.** A person whose row cannot pass yet (a tool gap, or a new item that needs a re-code check) is
**held**: their id goes in `held.txt`, and their rows come out of `research.csv` and `evidence.csv` (keep the full
set as `research-with-held.csv` / `evidence-with-held.csv`; `drop_held.py <batch>` does both). A coded person who is
leaving and is left out of the batch on the runner's choice goes in `moved.txt`. Set both lists' code files aside
before each `topic:stage5-write` run and put them back after: `write-batch.sh` does both. Nothing is written for a
held person. They follow in a small batch of their own (`<unit>-NN-<name>`) once the gap is fixed:
`setup_batch.py <abs>/stage5 <abs>/stage5/write/<unit>-NN-<name> --level state --state XX <pid>…` (`--level federal`
for a federal one) writes its `pids.txt` and puts every other coded id in the unit in its `moved.txt`, so only those
people are written.

**0. Dry run 0.**

```bash
zsh scripts/stage5/write-batch.sh <abs>/stage5 <abs batch> <key> state:xx 0
```

It runs `topic:stage5-write --season draft --units state:xx --csv-out <batch>/research-stage5-0.csv` with the held
and moved codes set aside, and saves its output in `dry-run-0.txt`. Later dry runs take the next number.

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

`build_evidence.py` (step 4) rebuilds from the `research-pre-evidence.csv` it saved on its first run. A later dry run
copied over `research.csv` makes it stop and ask: `--from-research` (rebuild from the new file) or `--from-pre`.

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
copy it to `research.csv`. The writer maps each blank to a V6 reason by the ruling in RULINGS.md "Mapping a blank to a
V6 reason": gated and off-question blanks, and blanks whose code says `shows_side: false`, → `no-evidence`; blanks
whose code says `shows_side: true` (or carries the `direction-only` tag) → `direction-only`. A blank it still lists
under **not in research.csv** is a code written before `shows_side` existed: decide it by the same ruling, write it,
with its reason, in `hand-rows.md`, put the ids and reasons in `hand-rows.json`, and run `add_hand_rows.py <batch>
<abs>/stage5 <findings dir> --topic <key>`.

**3. Bundle.** Build the research-stances bundle for the coded people of this batch only:

```bash
cd backend && args=(); while read p; do args+=(--politician "${p}:state"); done < <batch>/pids.txt
ADMIN_INGEST_TOKEN=placeholder npx tsx --env-file=.env scripts/build-stance-topic-bundle.ts --dir <batch> --season draft "${args[@]}"
```

`pids.txt` holds the roster ids at this level and state that have a code file. Use `"${p}:federal"` for a federal
batch.

**4. Evidence.** `stance-gate` needs an `evidence.csv`, and Stage 5 has no other step that builds one.

```bash
python3 -I scripts/stage5/build_evidence.py <batch> <abs>/stage5/roster.tsv <abs>/backend/data/source-store/findings --fetch --level state --state XX
```

A page the live site refuses (a 403, a challenge page) is read from its archive.org snapshot through the verifier's
own reader (`archive-pages.ts`), as the verifier does, so it is not listed as unread when the verifier can read it
(wi-01 held David Crowley over two wispolitics.com pages that verified this way, 2026-11-10). A row keeps at most 20 sources (8 at federal level). When a federal seat rests on more cited acts than that, pass
`--max-urls 20` (gun-policy `federal-01` lost cited acts at 8). congress.gov pages are read through the verifier's own
api.congress.gov reader (`congress-pages.ts`, `CONGRESS_GOV_API_KEY` in `backend/.env`); a plain fetch gets a bot
check. Delete a congress.gov page an older run cached before running again.

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
2. `s1-sources.ts --topic <key> <batch>` lists, for every blank over a shown answer, the sources of that answer
   (`fallback/fallback-required.json`).
3. Drop OnTheIssues and Wikipedia (RULINGS.md "OnTheIssues and Wikipedia are never sources"). Load the rest
   through the verifier's own fetch steps (`fallback-fetch.ts <batch>/fallback`, reading `fallback/urls.txt`), so a page the verifier cannot load is known now.
4. One agent reads the loaded pages for the question (`fallback-read.json/.md`). Check its "nothing on topic"
   answers yourself.
5. A page with a **new** on-topic item: hold the person (`held.txt`) for a re-code check. Otherwise list each loaded
   page on the blank as examined, with a party-free snippet: `add_fallback.py <batch> --topic <key> --gloss "<what the
   question asks>" --hold "<Name>"…`.
6. A blank whose old answer rests only on OnTheIssues or Wikipedia is written as an outcome row with no source and
   no review row (as `nc-01-stein`).

**6. Party sweep and fix.**

```bash
npx tsx scripts/stage5/party-sweep.ts <batch>/evidence.csv > <batch>/party-sweep.jsonl
```

It lists every snippet that names a party (`namesParty`, plus roll-call party letters: "CLANCY D N", "(R)",
"R-Dist", "(D-Bloomington)"). A snippet is never edited inside: cut it before the label when the person and the act
are still in what is left, or drop it. A page left with no snippet comes off the row's sources
(`party_fix.py <batch>`; list cuts in `party-cuts.json`; log in `party-dropped.json`). The sweep must end at 0. A party word inside a
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
| IN | iga.in.gov is a JavaScript app to a plain fetch; the official MyIGA API reads it (2026-11-02) | official roll-call lines (`iga-votes.ts`, below); LegiScan as before when `IGA_API_KEY` is unset |
| MA | House roll-call PDFs print a vote mark and a surname only (an initial where two share it); LegiScan has no record of some House roll calls | official roll-call lines (`ma-rollcall-votes.ts`, below) |
| TX | robots-blocked bill pages | LegiScan lane (PR #1218) |
| OH | the vote pages print a party letter by each name; the legislature's API lists member ids only | LegiScan lines (`state_legiscan.py … --session-start odd` for sponsor pages); HB 458's 2022-12-14 House vote is not in LegiScan |
| US | House: the Clerk XML prints a party by each name; Senate: senate.gov blocks a fresh fetch | House: Clerk XML lines; Senate: LegiScan lines (`federal-votes.ts`, below) |

Steps:

1. Map each official roll call to the LegiScan roll call of the same bill, chamber and counts
   (`legiscan-rollcalls.ts <ST> <vote-pages.json> <out.json>`), and record each match in `legiscan/rollcall-map.json`.
   Then `legiscan_pairs.py <batch> <findings dir> --topic <key> --state XX --host <official host> --rollcalls
   <batch>/legiscan/rollcall-map.json` writes `legiscan/pairs.csv` (IN also needs `--bill-pad 4`: LegiScan prints
   SB0010).
   **When the findings print no roll-call number** (TX, VA, PA in gun-policy), use `state_legiscan.py` instead: it
   matches each vote by bill, chamber, date and tally. `state_legiscan.py plan <batch> <findings dir> --state XX
   --host <host>[,<host>]` writes `legiscan/vote-pages.json`; `legiscan-rollcalls.ts XX <batch>/legiscan/vote-pages.json
   <batch>/legiscan/rollcall-hits.json` looks them up; `state_legiscan.py pairs … --topic <key>` keeps only a single
   roll call on the finding's date with its tally (a same-day tie broken on the motion text) and writes
   `legiscan/pairs.csv`, `needs.json` and `rollcall-map.json`. Everything else goes to `legiscan/unmapped.json`: hold
   that person; do not guess.
2. `npx tsx --env-file=.env scripts/legiscan-evidence-lines.ts --in <batch>/legiscan/pairs.csv --out <batch>/legiscan/legiscan-evidence.csv`.
   A pair with no line is reported: usually a name LegiScan prints another way. Hold that person; do not guess.
3. Merge (`legiscan_merge.py <batch> --host <official host>`): cite the LegiScan URL; take an unreadable official page off the row
   only when every act of the person on it now has a line; and cross-check each vote line against the act in the
   finding (`legiscan/crosscheck.json`). 🔴 It must show **0 disagree**. A row that needs more source columns than
   the file has gets them (no padding step needed). LegiScan's totals can differ from the
   official tally by one (IN SB 10 House vote: official 66-26, LegiScan 66-25); what must agree is each person's
   own vote.

Every LegiScan call counts against the monthly cap (`LEGISCAN_API_KEY`). The lines print no party.

**Indiana: the official roll calls instead** (with `IGA_API_KEY` in `backend/.env`). One command replaces steps 1-3:
`npx tsx --env-file=.env scripts/stage5/iga-votes.ts <batch> <findings dir> --topic <key>`. It finds each vote's
official roll-call PDF through the MyIGA API, cuts the person's line from it
("Indiana House roll call 340 (2025), SB 10 - Culp - 3rd Reading: Culp voted Yea."), cites the PDF, uncites a
covered bill page, and cross-checks every line against the finding (`iga/crosscheck.json`, 🔴 **0 disagree**).
A vote with no line is listed in `iga/unmapped.json`: hold that person; do not guess. A finding that prints no
roll-call number is matched by chamber and tally to the bill's one roll call (exact first, else within one vote on
each count, as LegiScan's tallies can be; never two candidates), and a floor vote on a conference committee report
is a floor vote, not a committee vote (`igaVotesPlan.ts`, 2026-11-04). Replayed on `in-01`: the
same 101 votes as the LegiScan lines, plus Alting and Prescott, whom LegiScan could not match. Bill pages,
legislator pages and every other iga.in.gov PDF read through the same API in step 4 (`build_evidence.py`,
`pdf_pages.py`), and the verifier reads them the same way (`src/lib/adapters/igaAdapter.ts`).

**Massachusetts House: the official roll-call PDFs instead.** One command replaces steps 1-3:
`npx tsx --env-file=.env scripts/stage5/ma-rollcall-votes.ts <batch> <findings dir> --topic <key>`. Each House
vote finding is matched to its store instrument's House vote; the instrument's `urls` give the PDF
(malegislature.gov/RollCall/<GC>/HouseRollCall<n>.pdf). The tool cuts the person's line from the PDF
("Massachusetts House roll call 135 (193rd General Court), H.4885 - On acceptance of the report: Kilcoyne voted
Yea."), cites the PDF, uncites a covered bill page, and cross-checks every line against the finding
(`ma-rollcall/crosscheck.json`, 🔴 **0 disagree**). The label must fit the surname, and the first initial when
printed; a bare surname two members share gives no line. "Mr. Speaker" never matches anyone, so the Speaker's
vote needs another source. Votes with no line go to `ma-rollcall/unmapped.json`: hold that person, do not
guess. The verifier reads the PDF the same way (`src/lib/adapters/maLegislatureAdapter.ts`). Replayed on the
44 `ma-01` members held for this (2026-11-04): 56 lines, 0 disagree, all 44 verified.

**Federal: the roll-call table instead.** One command for the House, two more for the Senate:

```bash
npx tsx --env-file=.env scripts/stage5/federal-votes.ts <batch> <findings dir> --topic <key>
npx tsx --env-file=.env scripts/legiscan-evidence-lines.ts --in <batch>/legiscan/pairs.csv --out <batch>/legiscan/legiscan-evidence.csv
python3 -I scripts/stage5/legiscan_merge.py <batch> --host <official host>
```

`federal-votes.ts` pairs each seated vote with its roll call in `essentials.legislative_votes` (read only), finds
the person on it by politician id, and cross-checks the table position against the finding. House: it fetches the
Clerk XML once per roll call, cuts the person's line by bioguide id, with no party
("House roll call 102 (2025), H R 22, On Passage: Fedorchak (ND) voted Yea."), cites the XML, and uncites a covered
page. Senate (115th Congress on): it writes `legiscan/pairs.csv` and `legiscan/needs.json` for the two commands
after it; skip them when it prints no Senate pairs. 🔴 `federal/crosscheck.json` and `legiscan/crosscheck.json` must
both show **0 disagree**. A vote with no line is listed in `federal/unmapped.json` (Senate: `legiscan/unmapped.json`):
hold that person; do not guess. A House roll call the table gives no roll number has no Clerk XML: when its table
id is a LegiScan id it takes the Senate's LegiScan lane (pair, lines, merge); otherwise it is held. A Senate seat whose act is abstain ("present") shows up as a `DISAGREE` line
(LegiScan NV is stored as `not_voting`) and stops the run; hold that person by hand. A page it prints as `WARN` stays cited on purpose (a House vote or other snippet
on it has no line). Replayed on `federal-01` (2026-11-03): 97 of the 98 House lines again, 0 disagree; the 98th is
held, because that person's politician record has no bioguide id (held, never matched by surname).

**8. Bill text.** When the reasoning quotes a bill's words and the cited page cannot be read, the gate cannot find
the quote. Run the gate once (step 9) to list those quotes, then:

```bash
python3 -I scripts/stage5/bill_text_auto.py <batch> <abs>/backend/data/source-store/findings --topic <key> --saved-root <abs>/.planning/research [--gate <gate output>]
```

For each high `quote-not-in-snippet` finding in the gate output (`gate-output.txt`, or the file `--gate` names) it
looks for the quoted words in the bills the person's own findings name: first the store's operative text (verbatim
from the act; its quote blocks, then the whole text), then the act's saved copy (`provenance.saved_copy`, sha256
checked). It cites that bill's text URL with a passage of whole sentences, 25 words or more, that holds the
quote. `bill-text.json` lists every quote it placed and every quote it could not. A quote it could not place is
usually the coder's own words in quote marks (trim them, step 9) or a bill the store does not hold (add it with
`add_bill_text.py`, by hand). On in-01 it placed the same 290 of 310 quotes the hand step did, leaving the same 20
high findings. A bill names no voter, so the verifier does not count it as a source for the person; it only meets
the gate's quote check.

**9. Gate to 0 high.**

```bash
npx tsx scripts/stance-gate.ts --dir <batch>
```

Work every high finding down to 0. Two tools, and they are not the same:

- **Trim** (`overrides.json`, applied by `apply_overrides.py <batch>`): an edit to the **research text
  only**, never to a stance or a value. Use it for a side-list bill the seat does not rest on and with no readable
  page (drop its number), quote marks the coder put round its own words, or a quote that the page splits at a
  comma. Each entry records the old words, the new words and why. 🔴 The code file still says the old words; say
  so in the preview.
- **Hold** (`held.txt`): a finding that only new evidence or a code change could clear.

Tools for the common cases, each writing trims to `overrides.json` (or, for the first three, sources and snippets),
never a stance: `cite_named.py` (a bill the text names: cite the person's own record on it, or list it for a trim),
`quote_snippets.py` (a quote a cached cited page prints: add that snippet), `uncite.py` (`uncite.json`: take a page
off a row), `respell_ids.py` (store ids in the text → bill numbers), `unquote.py` (quote marks off act words no
readable page prints; own words are listed, never touched), `quote_fix.py` (a coder-edited bill quote → the act's
exact pieces). When several of them feed one `overrides.json`, apply it with `apply_overrides.py <batch>
--skip-changed`: a trim whose words an earlier trim already changed is skipped and listed instead of stopping the
run. Read that list.

Medium `statement-needs-review` findings are expected for own-words seats: they go to review. A seat placed on own
words alone is `statement` evidence, so it keeps the `statement-evidence` hold until the topic's blind check passes
(section 8 below).

**10. Party check on the research text.** `party-sweep.ts --research <batch>/research.csv` sweeps the reasoning of
every row. Also `grep -ciE 'republican|democrat|\bGOP\b' research.csv`. Both must be 0, except party words inside
web addresses.

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
   (`write-batch.sh <abs>/stage5 <abs batch> <key> state:xx apply`). It writes the outcomes and passages in one transaction. Exit 3 with "WROTE" is fine. It
   refuses to run while any code is refused: fix those codes and dry-run again first, or an earlier write for
   those people would stay live. Running it again for the same people replaces their outcome and their passages.
   It refuses any season but the draft one.
2. `verify-stance-research.ts` with the step 12 flags plus `--apply --editor-id <editor uuid>`. It queues every row
   for review (review-all).
3. Read back (`readback.ts --topic <key> <batch>/pids-write.txt --batch-id <batch>`): outcomes by type, passages, and review rows by status must
   match the preview.
4. Add the counts to `PREVIEW.md` under "WRITTEN", and a line to the topic's hand-over log.

**15. Approve the review rows.** 🛑 A separate yes ("approve"). `approve-batch.ts <editor uuid> <batch>
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

