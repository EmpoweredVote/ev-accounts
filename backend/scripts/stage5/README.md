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
| 3a | `sponsor_cover.py <bills.json> --state XX --roster <tsv>… --core <json> --ds <dir> [--idmap <tsv>] [--since 2017] [--candidates <json>] [--triage <json> --write <json>] [--refile-tolerance 0.02 \| --keep-refiled] [--refiled-out <json>]` | every non-resolution topic bill a roster member sponsored that is not core yet; writes candidates for an Opus title triage, then core + the "fill" bills (refuses while any is untriaged); prints LegiScan people matched by name for `idmap.tsv`. **Re-file trim** (default on): among "fill" bills of one title and prime sponsor, keeps the newest, and an older copy only when it adds a roster sponsor or its introduced text's size differs by more than the tolerance; dropped copies → `<write>.refiled.json`. Missouri: 277 → 213 (2%), 165 with text ignored (`--refile-tolerance 1000`); the hand script kept 163. **Text fill only where it can matter** (round three): the triage may answer `stub` (on the topic, but the title shows no rung is possible); a stub is not filled and is listed for the runner in `<write>.stubs.json` (`--stubs-out`). 🔴 A bill a roster member voted on in a floor roll call is always filled: the tool turns that `stub` into `fill` and prints it (each candidate carries `floor_voters` and the summary line `desc`). California replay, 117 candidates, blind triage: 12 stubs, **11 fills saved of 109**, **0 bills that ended with a rung left unfilled**; the vote guard caught one (SB 368 (2023), a dealer-rules title with a rung 3 part) |
| 3b | `bill_table.py check\|questions <table.json> [--ids <file>] [--store <dir>] [--rungs 5] [--out <md>]` | `check`: every bill has an instrument file, a rung in range, deciding words found in its operative text, and a well-formed `per_vote` (optional: `{"rungs": [3, null], "note": …}` when a ruling reads one vote on the bill differently from the row); with `--ids`, bills people have findings on that the table leaves out (exit 2). `questions`: flagged bills and people with a Yes on both sides of the middle rung, gated votes left out |
| pilot | `search_list.py plan\|control\|adopt\|recode --record-codes <dir> [--roster <tsv> --control-group 5,2:10 --control-group 3:10] [--codes <dir>] [--record-briefs <dir> --wave-dir <dir> --apply] --out <dir>` | **Pilot states only** (STAGE5.md "Pilot rule"). `plan`: skip record seats at each `--control-group <rungs>:<n>`, except a seeded control of n per group (ruling 2026-11-13, gun-policy: rungs 5 and 2, and rung 3, 10 each; `--skip-rungs 5,2 --control 20` is the first pilot rule and still works); `recode` (after the search import): second pass only for people with a new on-topic finding their record-only coder was not shown, or no record-only code; search again once when the search found nothing and read none of the person's own pages, or its agent did not finish; everyone else keeps the record-only code (`--apply` copies it). Missouri replay: 45 second pass, 8 search again, 35 kept (0 of 35 differ from the final code); `control`: with groups, exit 4 when ANY control person in a group changed (without groups: more than 1 in 20); `adopt`: runs `control`, copies the record-only codes of skipped people in the groups that held, and lists a failed group's skipped people in `reopened.tsv` to search |
| code | `record-script.ts plan --config <json> --rulings <md> --roster <tsv> --ids <file> --unit state:xx --bill-table <json> --sides 1,2,3/4,5 --name <prefix> --out <dir> [--check 10] [--skip-rungs 5,2]` · `record-script.ts adopt --out <dir> --name <prefix> --codes <record-codes>` | **Record-only pass by rule, with an Opus lane and a standing check** (round three; see "Record pass by script" below). `plan` writes a script-made code for each plain case into a holding folder, and lists everyone else for Opus with the reason; `adopt` compares a seeded sample of the script's people with their blind Opus codes and releases the script codes only when all agree (exit 4 on any difference: nothing released) |
| code | `coder-inputs.ts --config <json> --rulings <md> --roster <tsv>… --ids <file> --unit state:xx\|federal --name <prefix> --out <dir> --coded-dir <dir> [--size 20] [--store <dir>] [--record-only] [--bill-table <json>]` | per coder batch (`--record-only`: record findings only, no-stance forbidden, people with no record listed apart): the brief, one compact findings file (refuses one that does not rebuild to the store) and an ids list; prints the rulings the unit's coders will not see, and characters before and after. Each brief line names the office (roster `office` column); `--record-only` refuses a person with none, because a kept record-only code is final. `--bill-table` (round three) collapses each person's plain record to one line per bill and act (finding id, date, chamber, tally, gate, the table's rung) and states each bill's rung, deciding words and reason once; a record whose note says more than the pre-fill's fixed sentence is never collapsed and stays word for word; the file is refused unless every finding, note included, rebuilds exactly. California batch 1 (20 people, 1,321 findings): 680,549 → 363,153 characters, 0 ids lost, all 12 other notes kept; all six record batches: 3.21M → 1.75M |
| code | `split-codes.ts <coded batch file> --config <json> --codes <dir> [--ids <file>] [--store <dir>] [--replace]` | checks one coder file (`checkCode` plus the bill, label and quote checks in `lib/stage5Ingest.ts`), sets `coded_at` and `evidence_basis`, writes passing codes; the rest go to `<batch>.sendback.md` (exit 3) |
| 0-12 | `run_recipe.py <batch> [--from N] [--to 12] [--print] [--check-only N]` · `run_recipe.py <batch> --replay [--to 9] [--no-reapply] [--print]` | runs recipe steps 0-12 from `<batch>/recipe.json`; stops at the first failed check (exit 2) or at an agent or hand step (exit 10, with the `--from` to resume); step 9 refuses while step 7 ran after step 8; step 5 writes an empty `fallback/urls.txt` when no blank sits over a shown answer; prints the PREVIEW numbers. `--replay` (round three), after a tool fix: keeps the current files as `*-before-replay-<k>.csv`, puts the pre-step-7 copies back, then runs step 7, `drop_held.py` (when anyone is held), step 8, the saved trims (`uncite.json`, `overrides.json` with `--skip-changed`; `--no-reapply` leaves them out) and step 9. It refuses when the pre-step-7 copies are missing or an earlier step ran after them. A step-7 re-run no longer overwrites those copies while they are current |
| waves | `wave.py <jobs.tsv> --out <dir> [--max 8] [--full] [--add-dir <dir>]…` | one wave of headless agents (`claude -p`), at most 8 at a time, slim by default; one result file per agent; skips agents already done |
| run | `run_state.py --profile <topic-profile.json> --state xx [--from N] [--to N] [--print]` | One command for a state's record pass, search list, search and import, re-code list (with one second search), second coding pass, adopt and early check: session B's steps B1 to B8, about 60 single commands in each pilot state. It stops only where a person is needed and prints the `--from` to resume with: exit 4 = the standing check, a changed control, or the early check's bar (runner stop 2); exit 10 = codes sent back or search files refused; exit 2 = a command failed. Logs in `<stage5>/<xx>/run/`. Refuses a topic whose profile names no control groups |
| prompts | `stage5_prompts.py search-briefs\|bill-table\|quote-check\|coder-jobs --profile <topic-profile.json> …` | The builders every state copied and edited (7 copies of the search-brief script alone). Search briefs from the profile's `search` block, written per state so an import reads one state only; bill-table prompts with the `{all}` rulings and this state's; quote-check prompts and `qc/to-check.json` from the dry run; a jobs file for any coder wave. Exit 1, writing nothing, on an unfilled slot |
| prompts | `quote-check-validate.ts <batch dir> <stage5 dir>` | Checks every finding on `qc/to-check.json` has an answer that parses, then appends the answers to `quote-checks.jsonl` once |
| legislature | `legislature.py show xx \| check [xx] \| new xx --name <Name>` | Legislature profiles, `backend/data/legislatures/<xx>.json`: what a state's legislature is like (hosts, votes mode and floor rule, how texts mark changes, what our reader can open, the search and bill-table notes), written once and read by every topic. `check` fails a profile that is missing a part, leaves a votes or texts host out of `reader_access`, or names a topic or a rung. The cards, `stage5_prompts.py` and `check_fill_quotes.py` read it; session A writes or refreshes it at hand-over. On file: mo, ca, wa |
| bills | `check_fill_quotes.py --fills <dir> --texts <dir> --state xx [--flag <key>] [--skip <id>]...` | Each quote in a bill-text fill must be in the saved text, as printed or as it reads after struck words are removed (9 per-state copies replaced). The legislature's own section labels come from its profile. Exit 1 on a miss or a fill with no saved text. Washington: 795 parts, 2 misses, the same as its own script; California: 774, 0 |
| session | `session_card.py A\|B --profile <topic-profile.json> --state xx --state-name <Name> [--worktree <dir>] [--out <file>]` | Writes the one short page a Stage 5 session reads in place of the skill file, STAGE5.md, the runbook and this README (about 3,000 tokens for about 31,000, which were carried on every step). Every topic value comes from the profile (`templates/stage5-topic-profile.example.json`): topic key, folders, the ladder's sides, whether the record pass by script is approved, the skip rule's control groups, the settled rulings. With no control groups the card says to search everyone. Exit 1, writing nothing, on an unfilled `{{…}}` slot or a half-filled profile |
| measure | `close_state.py --profile <topic-profile.json> --state xx --session <main .jsonl>... [--leg A\|B] [--batch xx-01] [--out <dir>] [--projects <dir>]... [--force]` | The close-out in one command, run as the session's LAST act: `usage-xx.json` (stage5_usage.py's output plus each session and wave folder apart), `search-effect-xx.json` (over the state's id list), `MEASURES.md` and a hand-over skeleton. Lists every question the sessions asked and every wait of 5 minutes or more that a runner message ended. Leaves `__` for what a person must fill (gate runs; which questions were listed stops). Never replaces a `MEASURES.md` it did not write |
| measure | `search_effect.py --roster <tsv> --unit state:xx --record-codes <dir> --codes <dir> --plan <dir> [--ids <file>] [--json <out>]` | pass `--ids` (the state's id list) so people dropped from scope are not counted; each control group is reported apart; per state: searched people whose outcome or rung changed between the record-only code and the final code, split by the record-only result; codings per person (Missouri: 4 of 82 changed, 1.62 codings per person) |
| measure | `stage5_usage.py --session <main .jsonl> [--wave-dir <dir>]… [--people N] [--since ISO] [--until ISO] [--json <out>]` | the pilot's token numbers: weighted units, per person, main-session share and steps, agents by kind with their starting size (Georgia replay: 40.0M, 196k per person, 39%) |
| 0, 14 | `write-batch.sh <stage5> <batch> <topic> <units> [N\|apply]` | `topic:stage5-write --skip-ids <batch>/skip-ids.txt` (the `held.txt` and `moved.txt` ids); moves no code file (until 2026-11-12 it moved them aside, which a session's permission check refused); writes `pids-write.txt` for `readback.ts` |
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

## Record pass by script (round three, 2026-11-13)

The state's bill table already says which rung a Yes on each bill supports. `record-script.ts` applies it to each
person's record and decides **only the plain cases**; an Opus coder decides the rest.

**The script may decide** (and nothing else):
- a **seat at the furthest rung**, when every counted Yes act (an ungated Yes vote, or a sponsorship that is not gated)
  on a bill with a rung sits on one side of the ladder (`--sides`, e.g. `1,2,3/4,5`);
- a **No-votes-only blank** (`nay-only`, shows a side), when no Yes act counts, the person has no sponsorship, and
  every counted No is on bills of one side.

**The script hands to Opus**, with the reason in `<name>-lanes.tsv`:

| Lane | Why a script cannot decide it |
|---|---|
| Yes acts on both sides of the ladder | the licence rule (a carry easing beside a limit) or a two-sided record: a judgment |
| A later No on a bill at the seat's rung | a later vote on the same provision may replace the Yes (Missouri, transit carry) |
| No usable rung act, but sponsorships | what the sponsored bills show is a reading |
| A person the state's rulings name | a ruling about a person is applied by a coder |
| A `per_vote` bill, when one of its rungs would change the result | a vote taken on an earlier text |
| An office that is not a legislative seat; a bill of another legislature | the record may come from another office |
| A bill missing from the table or the store; a bill with an open flag | nothing to apply |
| A record whose note says more than the plain facts; an act the rule does not read | doubts are flagged in notes |
| Any other blank | only gated votes, No votes on both sides, or only no-rung bills |
| The script's own text failed a coding check | never fixed by hand: the person goes to Opus |

**Guards.** A script code is marked `coded_by: stage5-record-script`. It passes the same `checkAtIngest` as a coder's
code, plus the party sweep. It sits in `<out>/script-codes/` until `adopt` passes, and `checkCode` refuses it without
its `script_check` stamp at ingest, in the report and at write time, so it cannot reach the database unchecked.
**Standing check, every state:** a seeded random 10 of the script's people (half of them seats at `--skip-rungs`,
which the pilot rule never searches: pass `5,2,3` since the ruling of 2026-11-13) are coded blind by Opus in the same wave as the Opus lane. Any difference in
outcome or rung stops the run (exit 4), releases nothing, and goes to the runner.

**Replay against the Opus record-only codes** (2026-11-13; `record-coded/`):

| | California | Missouri |
|---|---|---|
| People with a record | 101 | 127 |
| Decided by the script | 83 (82%) | 106 (83%) |
| Of those, same outcome and rung as Opus | **83 of 83** | **106 of 106** |
| Handed to Opus | 18 | 21 |

The bare rule with no lanes agreed for 99 of 101 and 122 of 127. Its 7 misses all fall in a lane: five licence-rule
records (Opus right), one superseded Yes (Opus right), and one person the rulings name, where the script matched the
bill table and the Opus second pass, and the Opus record-only coder did not. Missouri's roster had no office column,
so that lane was replayed with a stand-in. Georgia has no bill table and no record-only codes: not replayed.

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
- **The roster names the office.** `topic:stage5-roster` writes an `office` column (the office title, else its chamber)
  since 2026-11-12; older rosters still read. A record-only coder that does not know the seat cannot tell a record from
  another office (Missouri, Scott Fitzpatrick: House votes, now State Auditor).
- **Pre-fill one unit.** `topic:stage5-prefill ... --units state:xx` writes findings only for that unit's people.
  Without it the pre-fill merges every roster person with a vote on file (Georgia: 3,173 people for a 193-person
  state), which rewrote other states' files in WI, AZ and GA.
- **Triage prompt slots.** `templates/stage5-sponsor-triage-prompt.md` takes `{{RUNG_ACTS}}` and `{{NO_RUNG_KINDS}}` per topic (the gun-policy text is in its comment), with `{{LADDER_TEXT}}`.
- **Checks.** `python3 -I scripts/stage5/check_tools.py` runs the Python tools on small made-up batches, one check per
  rule (no database, network or node_modules); `--tools <dir>` points it at a tampered copy. The TypeScript helpers are
  tested with vitest (`lib.test.ts`, `federalVotesPlan.test.ts`, and `../lib/stage5Ingest.test.ts`, `../lib/stage5CoderInputs.test.ts`, `../lib/stage5RecordRule.test.ts` for the coding tools).
- `lib.ts` holds the pure helpers (`readCsv`, `sweepHit`, `verifiableWindow`, `unverifiableNote`) and their tests;
  `batch-db.ts` resolves the topic id and the draft season; `_args.py` is the Python tools' argument reader.
- One-off fixes for a single batch (a person's own sentence added by hand, a page uncited because the research text
  says it is unused) stay in that batch folder, with a line in its `PREVIEW.md`.
