# Stage 5 batch tools

The tools behind the Stage 5 write recipe: `.claude/skills/season-topic-prep/STAGE5.md`, step 7. Each one takes
the topic, state and season as arguments; none hard-codes a topic id, a season id or a worktree path. They were
moved here from the voting-rights batches (2026-10-29/30) and replayed on the Indiana batch `in-01`, matching its
outputs file for file. The tools the gun-policy batches added (2026-11-03/04) were moved the same way and replayed on
copies of those batches (`federal-01`, `tx-01`, `va-01`, `pa-01`, `in-01`, `ma-01` and the held follow-ups), matching
the research-folder versions file for file.

Run them from `backend/`: TypeScript as `ADMIN_INGEST_TOKEN=placeholder npx tsx --env-file=.env scripts/stage5/<tool>.ts`,
Python as `python3 -I scripts/stage5/<tool>.py`. `<batch>` is the batch folder, `stage5/write/<unit>-NN/`.

| Step | Tool | What it does |
|---|---|---|
| 3a | `scan_bills.py <ds_root> <XX,YY> <out.json> --topic gun-policy` | the topic's bills in a state's LegiScan datasets, with sponsors and votes (moved from the gun-policy folder's `scan_gun.py`; same output on GA and MO) |
| 3a | `sponsor_cover.py <bills.json> --state XX --roster <tsv>… --core <json> --ds <dir> [--idmap <tsv>] [--since 2017] [--candidates <json>] [--triage <json> --write <json>]` | every non-resolution topic bill a roster member sponsored that is not core yet; writes candidates for an Opus title triage, then core + the "fill" bills (refuses while any is untriaged); prints LegiScan people matched by name for `idmap.tsv` |
| 3b | `bill_table.py check\|questions <table.json> [--ids <file>] [--store <dir>] [--rungs 5] [--out <md>]` | `check`: every bill has an instrument file, a rung in range, and deciding words found in its operative text; with `--ids`, bills people have findings on that the table leaves out (exit 2). `questions`: flagged bills and people with a Yes on both sides of the middle rung, gated votes left out |
| pilot | `search_list.py plan\|control\|adopt --record-codes <dir> [--roster <tsv> --skip-rungs 5,2 --control 20] [--codes <dir>] --out <dir>` | **Missouri pilot only.** `plan`: skip record seats at the skip rungs, except a seeded control; `control`: exit 4 when more than 1 in 20 control people changed; `adopt`: runs `control`, then copies skipped people's record-only codes |
| code | `coder-inputs.ts --config <json> --rulings <md> --roster <tsv>… --ids <file> --unit state:xx\|federal --name <prefix> --out <dir> --coded-dir <dir> [--size 20] [--store <dir>] [--record-only]` | per coder batch (`--record-only`: record findings only, no-stance forbidden, people with no record listed apart): the brief, one compact findings file (refuses one that does not rebuild to the store) and an ids list; prints the rulings the unit's coders will not see, and characters before and after |
| code | `split-codes.ts <coded batch file> --config <json> --codes <dir> [--ids <file>] [--store <dir>] [--replace]` | checks one coder file (`checkCode` plus the bill, label and quote checks in `lib/stage5Ingest.ts`), sets `coded_at` and `evidence_basis`, writes passing codes; the rest go to `<batch>.sendback.md` (exit 3) |
| 0-12 | `run_recipe.py <batch> [--from N] [--to 12] [--print] [--check-only N]` | runs recipe steps 0-12 from `<batch>/recipe.json`; stops at the first failed check (exit 2) or at an agent or hand step (exit 10, with the `--from` to resume); step 9 refuses while step 7 ran after step 8; prints the PREVIEW numbers |
| waves | `wave.py <jobs.tsv> --out <dir> [--max 8] [--full] [--add-dir <dir>]…` | one wave of headless agents (`claude -p`), at most 8 at a time, slim by default; one result file per agent; skips agents already done |
| measure | `stage5_usage.py --session <main .jsonl> [--wave-dir <dir>]… [--people N] [--since ISO] [--until ISO] [--json <out>]` | the pilot's token numbers: weighted units, per person, main-session share and steps, agents by kind with their starting size (Georgia replay: 40.0M, 196k per person, 39%) |
| 0, 14 | `write-batch.sh <stage5> <batch> <topic> <units> [N\|apply]` | `topic:stage5-write` with `held.txt` / `moved.txt` codes set aside, then put back (even on failure); writes `pids-write.txt` for `readback.ts` |
| held | `setup_batch.py <stage5> <new batch> --level federal\|state [--state XX] <pid>…` | a held follow-up batch: `pids.txt` = these ids, `moved.txt` = every other coded id in the unit (refuses an id not coded there) |
| held | `drop_held.py <batch>` | drops `held.txt` / `moved.txt` people from `research.csv` and `evidence.csv`; the full set kept once as `*-with-held.csv` |
| 2 | `add_hand_rows.py <batch> <stage5> <findings> --topic <key>` | appends the rows in `hand-rows.json` (`{id: "no-evidence" \| "direction-only"}`) |
| 4 | `build_evidence.py <batch> <roster.tsv> <findings> [--fetch] [--level state --state XX] [--max-urls N] [--from-research\|--from-pre]` | builds `evidence.csv`; lists unread pages in `evidence-missing.json`. A `research.csv` replaced since its last run stops it: `--from-research` rebuilds from the new file, `--from-pre` from the saved copy. `--max-urls`: most sources a row keeps (default 8 federal, 20 state; federal-01 needed 20) |
| 4 | `congress-pages.ts <pages dir> <url>…` | congress.gov text through the verifier's api.congress.gov reader (`build_evidence.py` calls it through `_congress.py`; a plain fetch gets a bot check) |
| 4 | `archive-pages.ts <pages dir> <url>…` | archive.org text through the verifier's own `fetchViaWayback` (`build_evidence.py` calls it through `_archive.py` when the live page is refused, thin or a challenge page, the verifier's `looksLikeRealPage` test) |
| 4 | `pdf_pages.py <batch>` | reads PDF sources with `pdftotext` |
| 5 | `s1-sources.ts --topic <key> <batch>` | old-season sources behind each blank over a shown answer → `fallback/fallback-required.json` |
| 5 | `fallback-fetch.ts <batch>/fallback` | loads `fallback/urls.txt` through the verifier's own fetch steps |
| 5 | `add_fallback.py <batch> --topic <key> --gloss "…" [--hold Name]… [--seen Name]…` | lists loaded old sources as examined on each blank, each with a passage the verifier accepts when the page has one (`cited_unverifiable` in its log when not) |
| 6, 10 | `party-sweep.ts <evidence.csv>` · `party-sweep.ts --research <research.csv>` | lists snippets / research text that name a party (must end at 0) |
| 6 | `party_fix.py <batch>` | drops swept snippets (or cuts, `party-cuts.json`); uncites a page left with none |
| 7 | `legiscan-rollcalls.ts <ST> <vote-pages.json> <out.json>` | finds the LegiScan roll call for each official one (bill, chamber, counts) |
| 7 | `legiscan_pairs.py <batch> <findings> --topic --state --host --rollcalls <json> [--bill-pad N]` | official votes/authorships → `legiscan/pairs.csv` |
| 7 | `state_legiscan.py plan\|pairs <batch> <findings> --state XX --host <h>[,<h>] [--topic <key>] [--bill-pad N] [--year-shift N] [--session-start odd]` | the same for a state whose findings print no roll-call number: `plan` → `vote-pages.json` for `legiscan-rollcalls.ts`; `pairs` matches bill, chamber, date and tally (ties: motion text) → `pairs.csv`, `needs.json`, `rollcall-map.json`, `unmapped.json` |
| 7 | `../legiscan-evidence-lines.ts --in pairs.csv --out legiscan-evidence.csv` | the LegiScan lines (counted API calls) |
| 7 (IN) | `iga-votes.ts <batch> <findings> --topic <key>` | Indiana: each vote's official roll-call PDF → its line; cites the PDF, uncites covered bill pages, cross-checks (exit 1 on any disagreement) |
| 4, 7 (IN) | `iga-pages.ts <pages dir> <url>…` · `iga-evidence-lines.ts --in pairs.csv --out <csv>` | iga.in.gov text through the MyIGA API (what the verifier reads); lines for hand-made pairs |
| 7 (MA) | `ma-rollcall-votes.ts <batch> <findings> --topic <key> [--instruments <dir>] [--pdf-dir <dir>]` | Massachusetts House: each vote's official roll-call PDF (from the store instrument's `urls`) → its line; cites the PDF, uncites covered bill pages, cross-checks (exit 1 on any disagreement) |
| 7 (US) | `federal-votes.ts <batch> <findings> --topic <key>` | federal: each seated vote's roll call from `essentials.legislative_votes` (read only); House → Clerk XML line, cited, covered page uncited; Senate, and a House roll call the table gives no roll number → `legiscan/pairs.csv` + `needs.json` for the next two tools; cross-checks (exit 1 on any disagreement) |
| 7 | `legiscan_merge.py <batch> --host <official host>` | cites the lines, uncites covered official pages, cross-checks every vote (exit 1 on any disagreement) |
| 8 | `bill_text_auto.py <batch> <findings> --topic <key> [--instruments <dir>] [--saved-root <dir>] [--gate <file>]` | finds each quote the gate cannot place in the person's bills (store operative text: quote blocks, then the whole text; then the saved copy) and cites that bill with a 25+-word passage. `--gate`: the gate output to read (default `gate-output.txt`) |
| 8 | `add_bill_text.py <batch> --topic --url --sentences <json> [--text <file>]` | the same by hand, for a bill the store does not hold |
| 9 | `cite_named.py <batch> <gate output> <findings> --state XX` | for each `instrument-not-cited` bill, cites the person's own record finding on it; the rest → `cite-named-none.json` (a trim, never a guessed source) |
| 9 | `quote_snippets.py <batch> <gate output> --topic <key>` | a quote the gate cannot place, found in a cited page already fetched (`pages/`) → a snippet round it |
| 9 | `uncite.py <batch> [--file <json>]` | takes the pages in `uncite.json` (`[{name, url, why}]`) off their rows and drops their snippets |
| 9 | `respell_ids.py <batch> --state XX` | trims: store ids in the research text (`VA-HB-2767-2025`) → bill numbers (`HB 2767 (2025)`) |
| 9 | `unquote.py <batch> <gate output> [--skip Name]…` | trims: quote marks off act words no readable page prints; own words (statement rows, first person) listed, never touched |
| 9 | `quote_fix.py <batch> <gate output> <findings> --saved-root <dir>` | trims: a coder-edited bill quote (`...`, `[x]`) split into the act's exact pieces |
| 9 | `apply_overrides.py <batch> [--file <json>] [--skip-changed]` | research-text trims from `overrides.json` (`{"trims": [...]}`), never a stance or value. `--skip-changed`: a trim whose words an earlier trim already changed is skipped and listed, not fatal (several trim tools feed one file) |
| 14 | `readback.ts --topic <key> <ids file> [--batch-id <id>]` | outcomes, passages and review rows the draft season now holds |
| 15 | `approve-batch.ts <editor uuid> <batch,...> [--skip "Name"]… [--unverifiable-blank "Name"]…` | 🛑 approves pending review rows, on the runner's separate "approve"; `--unverifiable-blank` approves a queued blank whose old sources cannot be verified with no source, its reason on the review row (ruling 2026-10-31) — never write such a blank by hand |

Notes:

- ⚠ **`build_evidence.py` and `pdf_pages.py` fetch with a browser user-agent.** This is a deliberate exception to
  decision 0003 (ev-cto `knowledge/decisions/0003-scraping-toolchain.md`), ruled 2026-10-31 (Chris Andrews), for local research runs only. Never copy it into a live or
  scheduled fetch path. A page these tools read is not proof the verifier can read it: the verifier sends the honest
  `EmpoweredVoteBot` identity (`src/lib/verificationFetch.ts`).
- **iga.in.gov goes through the official MyIGA API, never the browser user-agent.** Both tools hand any iga.in.gov
  URL to `iga-pages.ts` (through `_iga.py`), which reads it with `src/lib/adapters/igaAdapter.ts`, the verifier's own
  Indiana tier. The API asks for the token in `x-api-key` and as `User-Agent: iga-api-client-<token>`
  (docs.api.iga.in.gov/usage.html): the state's rule, not a disguise. Set `IGA_API_KEY` in `backend/.env`; without
  it Indiana pages stay unread and Indiana votes go through LegiScan as before. The token sits inside a header, so
  never log a request.

- `build_evidence.py` also reads an `overrides.json` of the older shape `{name: {column: value}}`; a `{"trims": …}`
  file is ignored by it (no row is named "trims").
- **One party test for every step that cuts reader-facing text.** `build_evidence.py` and `add_fallback.py` ask
  `party-check.ts` (through `_party.py`), which answers with the same `sweepHit` that `party-sweep.ts` uses:
  `namesParty()` from `src/lib/partyLabels.ts` plus roll-call letters and a vote API's `"Party":"R"` field. So a
  snippet a builder keeps is never one the sweep then flags. Add a new marker to `lib.ts`, never to a tool.
- **Ballotpedia: survey answers only** (ruling 2026-11-02). `build_evidence.py` uncites any Ballotpedia page but a
  Candidate Connection `#Campaign_themes` link (logged in `evidence-missing.json`) and `add_fallback.py` skips it,
  through `_ballotpedia.py`. The stance gate refuses the same pages (`ballotpedia-non-survey`).
- **One passage test for a blank's examined pages.** `build_evidence.py` and `add_fallback.py` first ask
  `window-check.ts` (through `_window.py`) for a passage the verifier will accept: `verifiableWindow` in `lib.ts`,
  built from the verifier's own `matchSnippet`, `matchedSpan` and `checkNameProximity` plus `sweepHit`. It need not
  contain the name, only sit near it: on a congress.gov cosponsor list, where every name carries a party label, it is
  the action line beside the list (Warner, S. 2747). Only when there is none do they fall back to the old window.
- **Slim agents.** A headless agent started in this repo reads CLAUDE.md, the skills, plugins and MCP servers before
  its prompt: measured 2026-11-12, its first turn was **175k tokens**; with `--strict-mcp-config
  --disable-slash-commands` 56k; with `--safe-mode` (no CLAUDE.md, skills, plugins, hooks, MCP or custom agents)
  **4.9k**. `wave.py` uses `--safe-mode` unless `--full`. That is safe only for a self-contained prompt, one that
  names every file the agent reads and states every rule it applies: the coder brief, the bill-table, triage and
  quote-check prompts are. A separate `CLAUDE_CONFIG_DIR` (for example `~/.claude-ev`) also works but needs its own
  `/login` once. Re-measure with `stage5_usage.py` after a change to CLAUDE.md or the installed plugins.
- **Pre-fill one unit.** `topic:stage5-prefill ... --units state:xx` writes findings only for that unit's people.
  Without it the pre-fill merges every roster person with a vote on file (Georgia: 3,173 people for a 193-person
  state), which rewrote other states' files in WI, AZ and GA.
- **Checks.** `python3 -I scripts/stage5/check_tools.py` runs the Python tools on small made-up batches, one check per
  rule (no database, network or node_modules); `--tools <dir>` points it at a tampered copy. The TypeScript helpers are
  tested with vitest (`lib.test.ts`, `federalVotesPlan.test.ts`, and `../lib/stage5Ingest.test.ts`, `../lib/stage5CoderInputs.test.ts` for the coding tools).
- `lib.ts` holds the pure helpers (`readCsv`, `sweepHit`, `verifiableWindow`, `unverifiableNote`) and their tests;
  `batch-db.ts` resolves the topic id and the draft season; `_args.py` is the Python tools' argument reader.
- One-off fixes for a single batch (a person's own sentence added by hand, a page uncited because the research text
  says it is unused) stay in that batch folder, with a line in its `PREVIEW.md`.
