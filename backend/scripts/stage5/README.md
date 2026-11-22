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
| 3a | `link_check.py --state XX --roster <scoped tsv> --ds <dir> --idmap <tsv> [--add] [--from-db] [--no-record <tsv>] [--offices <regex>]` | 🔴 run after sponsor cover, before any vote is built. **Use `--from-db --add` first**: it reads the member ids we hold (`scripts/member-ids/`), pairs each Open States person by the id `sync-member-ids.ts` matched to the seat (no name involved), and adds LegiScan ids from the database marked with how they were matched; an idmap line that disagrees is a CONFLICT (exit 1, nothing changed). Every roster legislator (office matches `--offices`, scope not `candidate`) must have an `idmap.tsv` line that points at a LegiScan person of the state's datasets; one without it has **no votes on file and nothing errors**. `--add` appends unique name matches (the shared rule, or a letter-for-letter whole name) for you to check; a name match alone is not a link. Exit 1 lists each unlinked member with the unlinked LegiScan people who share a name word, a LegiScan person already linked to another id (a duplicate person row), and the newest session's unlinked people. `--no-record` excuses a member with no LegiScan record, with a reason. Exit 2 = no verdict (no legislators matched, or no people read). Kentucky 2026-11-14: 6 of 138 unlinked ("Deanna Frazier" for Deanna Gordon, "Casey" for Cassie Chambers Armstrong); 2 were written as blanks that a vote and a sponsorship on file would have seated, 1 was held |
| 1, B1 | `roster_sync.py --shared <stage5>/roster.tsv --batch <stage5>/batches/xx-roster.tsv --ids <xx-ids.txt> [--write] [--distinct <tsv>]` | The record script, the coder inputs, the import and the write read the SHARED roster; the set-up leg settles the state's own. The batch roster wins for the listed ids: without `--write` it lists each difference (exit 1), with it it adds missing rows and sets differing fields after a backup (`roster.tsv.bak-sync-xx`). `run_state.py` runs it first, with `--write`. Exit 2 = no verdict (an id not in the batch roster, a blank office there). Utah 2026-11-15: a missing new winner, 118 blank offices and one stale level stopped leg B twice and left one person unwritten. 🔴 One person, one record (runner, 2026-11-16): two listed ids that read as one person ("Allison Russo", "C. Allison Russo") stop it with exit 3, with `--write` or without; list real namesakes in `--distinct` with a reason |
| B7 | `bill_table.py affected <table.json> <new bill ids…> --ids <ids file> [--out <file>]` | After bills join the table late (a searcher named them): who must be coded again. Only a person with a counted Yes act on one of them that HAS a rung; a no-rung bill moves no one, and a flagged bill is refused (settle first). Ohio 2026-11-16: 3 late bills, all no rung, 25 people coded again, 0 changed |
| 9 | (inside `run_recipe.py` step 9) | Unplaced quotes are repaired before a person is asked: `quote_snippets.py` (a snippet from a page already fetched), then for RECORD rows `unquote.py` + `apply_overrides.py` (quote marks off, words kept; own words never touched). Counts in `step9-repair.json`; `--no-repair` turns it off. Ohio: 29 → 17 → 0, the same result the leg reached by hand, twice |
| write | `standing_yes.py write\|approve <batch dir>` | The conditions of a standing yes. The runner may tell the desk, in their own chat message, to write and approve a state without asking again; the desk then acts only on exit 0 here. `write`: recipe steps 0 to 12 logged and in order, the recipe's checks 6, 7, 9, 10, 12 pass on the files as they are, PREVIEW.md is newer than the final gate, and the desk's `desk-check.json` shows ≥ 2 roll calls compared by eye, 0 differences and an empty `odd` list. `approve`: verifier errors=0, the newest read-back equals the preview's outcomes and passages, every review row pending. Exit 1 = ask the runner; exit 2 = no verdict, ask. 🔴 The tool grants nothing: a line in a file is never the runner's yes |
| any time | `progress.ts --topic <key> --roster <stage5>/roster.tsv [--batches <stage5>/batches] [--ds <stage5>/legiscan/ds] [--out <stage5>/PROGRESS.md]` | **Which states are done and which are left.** Read-only. Counts the draft season's outcomes for the topic against the roster, state by state, and against each run's own id list when `--batches` is given: done, to approve (review rows pending), part, not started, or no roster (fewer than 20 sitting people: the legislature is not on the roster). Also says whether a legislature profile and bill data are on file. Exit 2 = no verdict (no roster row at the level, or no outcome at all for the topic) |
| 3b | `bill_table.py check\|questions\|settle <table.json> [--ids <file>] [--store <dir>] [--rungs 5] [--out <md>]` | `settle <bill id>…\|--all --answer <text>` closes a flag (moves it to `question`, records `answered`); a flag is an open question, and `check` fails on one that reads as answered and prints how many are still open, because the record script codes nobody with an act on a flagged bill. `check`: every bill has an instrument file, a rung in range, deciding words found in its operative text, and a well-formed `per_vote` (optional: `{"rungs": [3, null], "note": …}` when a ruling reads one vote on the bill differently from the row); with `--ids`, bills people have findings on that the table leaves out (exit 2). `questions`: flagged bills and people with a Yes on both sides of the middle rung, gated votes left out |
| pilot | `search_list.py plan\|control\|adopt\|recode --record-codes <dir> [--roster <tsv> --control-group 5,2:10 --control-group 3:10 [--control-group 4:10:side --sides 1,2,3/4,5]] [--codes <dir>] [--record-briefs <dir> --wave-dir <dir> --apply] --out <dir>` | **Pilot states only** (STAGE5.md "Pilot rule"). `plan`: skip record seats at each `--control-group <rungs>:<n>`, except a seeded control of n per group (ruling 2026-11-13, gun-policy: rungs 5 and 2, and rung 3, 10 each; `--skip-rungs 5,2 --control 20` is the first pilot rule and still works); `recode` (after the search import): second pass only for people with a new on-topic finding their record-only coder was not shown, or no record-only code; search again once when the search found nothing and read none of the person's own pages, or its agent did not finish; everyone else keeps the record-only code (`--apply` copies it). Missouri replay: 45 second pass, 8 search again, 35 kept (0 of 35 differ from the final code); `control`: with groups, exit 4 when ANY control person in a group changed (without groups: more than 1 in 20); `adopt`: runs `control`, copies the record-only codes of skipped people in the groups that held, and lists a failed group's skipped people in `reopened.tsv` to search |
| code | `record-script.ts plan --config <json> --rulings <md> --roster <tsv> --ids <file> --unit state:xx --bill-table <json> --sides 1,2,3/4,5 --name <prefix> --out <dir> [--check 10] [--skip-rungs 5,2]` · `record-script.ts adopt --out <dir> --name <prefix> --codes <record-codes>` | **Record-only pass by rule, with an Opus lane and a standing check** (round three; see "Record pass by script" below). `plan` writes a script-made code for each plain case into a holding folder, and lists everyone else for Opus with the reason; `adopt` compares a seeded sample of the script's people with their blind Opus codes and releases the script codes only when all agree (exit 4 on any difference: nothing released) |
| code | `coder-inputs.ts --config <json> --rulings <md> --roster <tsv>… --ids <file> --unit state:xx\|federal --name <prefix> --out <dir> --coded-dir <dir> [--size 20] [--store <dir>] [--record-only] [--bill-table <json>]` | per coder batch (`--record-only`: record findings only, no-stance forbidden, people with no record listed apart): the brief, one compact findings file (refuses one that does not rebuild to the store) and an ids list; prints the rulings the unit's coders will not see, and characters before and after. Each brief line names the office (roster `office` column); `--record-only` refuses a person with none, because a kept record-only code is final. `--bill-table` (round three) collapses each person's plain record to one line per bill and act (finding id, date, chamber, tally, gate, the table's rung) and states each bill's rung, deciding words and reason once; a record whose note says more than the pre-fill's fixed sentence is never collapsed and stays word for word; the file is refused unless every finding, note included, rebuilds exactly. California batch 1 (20 people, 1,321 findings): 680,549 → 363,153 characters, 0 ids lost, all 12 other notes kept; all six record batches: 3.21M → 1.75M |
| code | `split-codes.ts <coded batch file> --config <json> --codes <dir> [--ids <file>] [--store <dir>] [--replace]` | checks one coder file (`checkCode` plus the bill, label and quote checks in `lib/stage5Ingest.ts`), sets `coded_at` and `evidence_basis`, writes passing codes; the rest go to `<batch>.sendback.md` (exit 3) |
| 0-12 | `run_recipe.py <batch> [--from N] [--to 12] [--print] [--check-only N]` · `run_recipe.py <batch> --replay [--to 9] [--no-reapply] [--print]` | 🔴 reads LegiScan from the datasets on disk (`<stage5>/legiscan/ds/<ST>-*`, `_onfile.py`) whenever the state has them, as `write-batch.sh` does; the live API only with `"legiscan_live": true` in recipe.json (`LEGISCAN_LIVE=1` for the write script), on the runner's yes. Step 7 prints which was read and the newest roll call on disk, and stops on an act with no LegiScan line. Ends by printing the desk's write, verifier, read-back and approval commands whole. runs recipe steps 0-12 from `<batch>/recipe.json`; stops at the first failed check (exit 2) or at an agent or hand step (exit 10, with the `--from` to resume); step 9 refuses while step 7 ran after step 8; step 5 writes an empty `fallback/urls.txt` when no blank sits over a shown answer; prints the PREVIEW numbers. `--replay` (round three), after a tool fix: keeps the current files as `*-before-replay-<k>.csv`, puts the pre-step-7 copies back, then runs step 7, `drop_held.py` (when anyone is held), step 8, the saved trims (`uncite.json`, `overrides.json` with `--skip-changed`; `--no-reapply` leaves them out) and step 9. It refuses when the pre-step-7 copies are missing or an earlier step ran after them. A step-7 re-run no longer overwrites those copies while they are current |
| waves | `wave.py <jobs.tsv> --out <dir> [--max 8] [--full] [--add-dir <dir>]…` | one wave of headless agents (`claude -p`), at most 8 at a time, slim by default; one result file per agent; skips agents already done |
| run | `run_state.py --profile <topic-profile.json> --state xx [--from N] [--to N] [--print]` · `run_state.py … --round <name> [--ids <file>] [--why <file>]` | One command for a state's record pass, search list, search and import, re-code list (with one second search), second coding pass, adopt and early check: session B's steps B1 to B8, about 60 single commands in each pilot state. It stops only where a person is needed and prints the `--from` to resume with: exit 4 = the standing check, a changed control, or the early check's bar (runner stop 2); exit 10 = codes sent back or search files refused; exit 2 = a command failed. Logs in `<stage5>/<xx>/run/`. Refuses a topic whose profile names no control groups. **`--round`** (2026-11-14) codes some people again in one command: everyone in an unanswered `.sendback.md` (with the code check's reasons), or `--ids` after a ruling. The brief holds only those people (Tennessee: one sent-back person's brief and findings are 78,000 characters, against 326,000 for the whole batch a hand-written send-back prompt pointed at); second-pass people go to `codes/`, the rest to `record-codes/` (and `codes/` when already adopted); replaced codes are kept in `<xx>/codes-before-<name>/`; files in `<xx>/rounds/<name>/` |
| prompts | `stage5_prompts.py search-briefs\|bill-table\|quote-check\|coder-jobs --profile <topic-profile.json> …` | The builders every state copied and edited (7 copies of the search-brief script alone). Search briefs from the profile's `search` block, written per state so an import reads one state only; bill-table prompts with the `{all}` rulings and this state's; quote-check prompts and `qc/to-check.json` from the dry run; a jobs file for any coder wave. Exit 1, writing nothing, on an unfilled slot |
| prompts | `quote-check-validate.ts <batch dir> <stage5 dir>` | Checks every finding on `qc/to-check.json` has an answer that parses, then appends the answers to `quote-checks.jsonl` once |
| slim | `leg.py A\|B --profile <topic-profile.json> --state xx --state-name <Name> [--answer <file>] [--cap N]` · `leg.py sessions …` · `leg.py log "<line>"` | Runs a session leg as a SLIM Opus session: its card plus `templates/stage5-slim-rules.md`, started with `claude -p --safe-mode`. A desktop session starts at 110,000 to 126,000 tokens and re-reads them on every step; a slim one starts at about 7,000 (13,000 with its card). The leg ends with one last line, which is the exit code: `DONE` 0, `STOP question <file>` 10, `STOP write <preview>` 11, `STOP blocked` 12, anything else 2. `--answer` resumes the same session with the runner's words. The small desktop session that starts the legs follows `session_card.py desk`. 🔴 A slim session is unattended, so every leg runs with `STAGE5_NO_DB_WRITE=1`: `topic:stage5-write --apply`, `verify-stance-research --apply`, `approve-batch` and `write-batch.sh apply` refuse (exit 5, `scripts/lib/noWriteGuard.ts`). The desk runs the write and the approval on the runner's yes. The guard covers those tools, not a hand-written SQL statement **Size cap (2026-11-14):** a leg is a chain of sessions. The session adds each log line with `leg.py log`, which answers with its size read from its own transcript; past the cap (default 100,000 tokens; the profile's `slim_cap`; `--cap 0` = off) it writes `<desk>/CONTINUE-<leg>-<n>.md`, ends with `STOP handover <file>`, and this tool starts a fresh session with the card, the rules and that note, without waking the desk. An `--answer` goes to a fresh session when the stopped one is past the cap and left a note. A hand-over inside 8 steps stops the leg as blocked. Replayed over Tennessee's legs (159 and 152 steps, ending at 322,000 and 233,000 tokens), a cap of 100,000 costs 43% to 45% less |
| local pilot | `local_pilot_sample.py --roster <roster.tsv> --out <dir> [--n 100]` | The 100-person local-official pilot draw (spec 2026-11-22 §8). Reads the seed from `<out>/seed.txt` (exit 2 if the runner has not recorded it), keeps the first row per politician_id among `level = local`, strata by office title (council-and-mayor / county / sheriff / other; each at least 10 when the pool allows), California capped at its pool share, no state over its share + 1. Writes `sample.tsv` and `strata.md`. `stage5_prompts.py search-briefs` uses the profile's `search.local_subjects` for local people |
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
| 7 | `state_legiscan.py plan\|pairs <batch> <findings> --state XX --host <h>[,<h>] [--topic <key>] [--bill-pad N] [--year-shift N] [--session-start odd]` | the same for a state whose findings print no roll-call number: `plan` → `vote-pages.json` for `legiscan-rollcalls.ts`; `pairs` matches bill, chamber, date and tally (ties: motion text) → `pairs.csv`, `needs.json`, `rollcall-map.json`, `unmapped.json`. `pairs` prints the unmapped votes grouped by cause. A roll call converted from Open States data is paired with the legislature's own roll-call page, not a legiscan.com address. With `LEGISCAN_DATASETS` set, a bill's LegiScan number and its session's first year come from the datasets on disk (SC: `S0109`, `/H3594/2023`); the two flags apply only to a bill the datasets do not hold exactly once. A conference-report vote is a floor vote however the motion words it |
| 7 | `../legiscan-evidence-lines.ts --in pairs.csv --out legiscan-evidence.csv [--page-cache <dir>]` | the LegiScan lines (counted API calls, or the datasets on disk). A pair whose address is a legislature's own roll-call page (a state run from Open States data) gets its line from that page, read with the verifier's own fetch at the site's crawl delay; `--page-cache` keeps each page's render so a second run fetches nothing |
| 3a, 7 | `openstates/extract.py <dump> <st> <work dir>` · `openstates/convert.py <work dir>/extracts/<YYYY-MM>/<st>` | **A state with no LegiScan dataset on disk** (`openstates/README.md`): Open States data, free and with no cap, converted to the LegiScan dataset layout, so `scan_bills.py`, `sponsor_cover.py`, `link_check.py` and step 7 read it unchanged. Its ids are ours and no legiscan.com page exists for them: step 7 cites each vote on the legislature's own roll-call page and reads the line from it (`src/lib/stateRollCallEvidence.ts`: Utah, Ohio and South Dakota so far; a new state needs a reader for its page). A sponsorship makes no pair and keeps its official page (`legiscan/sponsor-own-page.json`). Utah pilot, 2026-11-15: 215 floor roll calls on the topic's bills, 6,772 votes placed, 0 unmapped. 🔴 Check each session for roll calls before trusting the data: Utah's 2025 General Session has none in the dump. `openstates/fetch-legislature-rollcalls.ts <st> <session> <work dir> --bills …` reads them from the legislature's own site for the bills the scan found, and `convert.py` merges them (re-run it for the whole state) |
| 2 | `openstates/coverage.py <extract dir> [<more>] [--since 2017] [--min-bills 50] [--json <out>]` | 🔴 before the bill scan of an Open States state. Exit 1 names each session with 50 bills or more and no roll call, or roll calls that list no voter: that record is **not on disk**, which is not "no vote". Also prints each state's roll-call addresses (the page a state reader must read). Exit 2 = no verdict for a state (empty extract). 2026-11 dump: gaps in UT 2025, MD 2023, MN 2020s1 to 2021-2022, ND 66 and 67, NV 80, 81 and 84; PR is empty |
| 7 (IN) | `iga-votes.ts <batch> <findings> --topic <key>` | Indiana: each vote's official roll-call PDF → its line; cites the PDF, uncites covered bill pages, cross-checks (exit 1 on any disagreement) |
| 4, 7 (IN) | `iga-pages.ts <pages dir> <url>…` · `iga-evidence-lines.ts --in pairs.csv --out <csv>` | iga.in.gov text through the MyIGA API (what the verifier reads); lines for hand-made pairs |
| 7 (MA) | `ma-rollcall-votes.ts <batch> <findings> --topic <key> [--instruments <dir>] [--pdf-dir <dir>]` | Massachusetts House: each vote's official roll-call PDF (from the store instrument's `urls`) → its line; cites the PDF, uncites covered bill pages, cross-checks (exit 1 on any disagreement) |
| 7 (US) | `federal-votes.ts <batch> <findings> --topic <key>` | federal: each seated vote's roll call from `essentials.legislative_votes` (read only); House → Clerk XML line, cited, covered page uncited; Senate, and a House roll call the table gives no roll number → `legiscan/pairs.csv` + `needs.json` for the next two tools; cross-checks (exit 1 on any disagreement) |
| 7 | `legiscan_merge.py <batch> --host <official host>` | cites the lines, uncites covered official pages, cross-checks every vote (exit 1 on any disagreement); 🔴 lists every vote or sponsorship that got NO line in `legiscan/no-line.json`, and step 7 prints the count: find the cause (a bill page named wrong, a name LegiScan prints differently) before holding anyone |
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

A ruling about a bill ends with "People: …", everyone who holds an act on it. That list does not count as naming a
person once every one of the state's bills the ruling names has an answered row in the bill table
(`rulingsNameText`). Tennessee's eleven lists named all 129 people with a record and the script coded nobody; without
them it codes 94, each the same as the Opus code (Washington: 9 more people, 9 the same). A name in the ruling's own
words, a list with no bill before it, and a list beside a bill the table lacks or flags still send the person to Opus.

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

**Two more plain cases (runner, 2026-11-16).** (1) A name in a ruling line no longer holds a person when the line only says who holds an act on a bill the table has answered: a bracket with no bill in it (`(sponsor Ann Able)`), a `Sponsors: …` list, or the `People:` list. A name that is the ruling's subject still does, and so does any name beside a flagged or missing bill. (2) A person with no usable Yes act and a sponsorship that supports no rung (a no-rung bill, or a gated sponsorship) gets a script blank: No-votes-only when the counted No votes are on one side, a sponsorships-only blank (class `wording`) when there are none. No votes on both sides still go to Opus. Replay against blind Opus record codes, 7 states: 92 more people coded by script (564 to 656 of 913), outcome and rung the same for all 92; the blank class differs for 16 (Opus wrote `wording` or `off-question` where the script writes `nay-only` or `wording`). The standing check draws from these people first.

**After Ohio (2026-11-16).** `run_state.py` step 1 runs `bill_table.py check` before the plan and stops on a problem; `record-script.ts plan` exits 6 when its own text fails the coding checks for 5 or more people and a tenth of the record pass, all for one reason: that is one bill-table row, not the people (Ohio: one row quoted a text the store no longer held, and 80 people went to Opus; with the row fixed the script codes 122 of 130, and 105 of 105 that have a blind Opus code agree). A ruling that names a namesake ("Cecil Thomas") no longer holds another person of that surname on the list (Jim Thomas); a bare surname still holds everyone who carries it.

**After Maryland and Kansas (2026-11-18).** `bill_table.py votes` (run by `questions` too) lists, at set-up, each bill with a rung that in-scope people voted on and the datasets on disk hold no roll call for: Maryland held 20 people at the write for a 2013 bill older than its data. It cannot tell whether the vote's own page is readable (Kansas cited a 2015 bill page and held no one), so it prints the check to do. A legislature's roll call is read under the names in `essentials.politicians.alternate_names` when the person's own name fits no label (`stateRollCallLinesFor`, `verifyStateRollCallLine`): a roll call prints the name held on the day. A searcher's `status` key is accepted inside `searched` as well as at the root. `standing_yes.py write` names the people and the file that failed step 7, not the first list the recipe meets. The cards give the commit as `--pathspec-from-file` with a `git log -1 --stat` check.

**Shared set-up scripts, a rung per vote, a control of 5 (runner, 2026-11-19).**
- `bill_skeletons.py`, `bill_fill_wave.py` and `bill_merge.py` replace the three scripts each Open States state copied from the state before (`legiscan/scripts/build_skeletons_<xx>.py`, `merge_fill_<xx>.py`, `<xx>/scripts/build_fill_wave_<xx>.py`). The copies kept what nobody edited: 235 Maryland records say their text was read "from the official Mississippi text", and two states checked the store of a deleted worktree. Proven on Kansas, Maryland, Mississippi and South Dakota: 478 skeletons, 0 differ from each state's own script; the merge is identical for Mississippi and Kansas, identical for Maryland apart from that state name, and for South Dakota apart from 2 bills merged by hand into records already in the store (the shared script stops for those). The text fetch stays one script per state: which version to read, and how a legislature marks new and struck words, are facts of that legislature.
- `per_vote.votes` in a bill-table row gives the rung of each floor vote (date, chamber, tally). `record-script.ts` reads a vote that fits exactly one entry at that rung; anything else on the bill is read as before. A vote read at a rung other than the row's still goes to Opus (the script words a seat with the row's deciding words). Replay on Kansas, the one recent state with such bills: the per-vote lane went from 20 people to 0, but only 5 left the Opus lane, because the other 15 are also there for another reason. All 5 agree with the code Opus gave them, and no other script code changed.
- The control of the skip rule is the topic profile's `control_groups`. Gun-policy's went from 10 to 5 per group on 2026-11-19 (1 of 266 controls changed a code across 13 states). A new topic starts at 10.

**A third plain case (runner, 2026-11-18).** A person whose record holds Yes or No votes and none of them counts (each is on a bill the table gives no rung, or is gated), with no sponsorship and no counted No, gets a script blank: class `gate` when every vote is gated, `wording` otherwise. No votes on both sides, and a record with no Yes or No vote at all, still go to Opus. Replay against blind Opus record codes, 10 states: 67 people released, outcome the same for all 67; Opus's blank class is `off-question`, `gate`, `wording` or `nay-only` and matches the script's for 14. The standing check draws from these people first. Also: the import files a searcher's root `status` key as the `status: …` place the brief asks for (six hand fixes in two states), and `standing_yes.py` no longer fails on a held person's unreadable vote, reads the read-back against what the write wrote, and counts a row sent back for more research as one that stays pending.

**After Colorado (2026-11-19).** Colorado cost 102,494 units per person, against Kansas's 44,441. Four gaps, each
from its log. (1) `bill_table.py affected` also lists a person whose first finding on the topic is on a late bill
(two "no stance" codes stopped the early check), and gives no verdict (exit 2) when nobody holds a finding on the
bills: the pre-fill has not run since they joined the store. (2) `run_recipe.py` keeps an earlier pass of step 0 or 2
aside (`research-stage5-<n>.before-run-<k>.csv`) where the writer refused to overwrite it. (3) `bill_table.py check`
wants a bill stored from a summary (NO BILL TEXT READ) flagged for the runner, or settled; card A settles a bill with
no readable text in session A (seven such bills joined after coding, and 66 people were coded again). (4) Card B runs
the pre-fill before `affected`. And `openstates/pilot_batch.py` replaces the `make_pilot_batch.py` copied into seven
pilot folders: its dry batch names each voted bill, and `--verdict` reads the merge and the gate on it, so a reader
session meets a state's formats before a real run does. On Colorado's dry batch the merge and the gate as they were
before the run fail it (6,256 votes disagree; 3,834 named bills not found); as fixed, they pass.

**The desk in two commands (2026-11-19).** The desk is the one session left in the desktop app: it starts at about
135,000 tokens and re-reads them on every step (Kansas: 63 steps, 0.97M units; 8 to 13% of a state). `desk.py start`
does the start-up in one step (fetch, `.env` link, install, tracker, the state from the queue, reader or desk, the
lease, the desk card) and `desk.py close` the close-out (`close_state.py`, then `DESK-REPORT.md` with the facts the
final report needs). It never takes a held lease, never picks a 🛑 row, and writes nothing to the database.


**Maine's record, older Legislatures (2026-11-21).** The Maine reader read 57 floor roll calls of its 130-bill dry
batch and now reads 95: the 128th to 130th House (21) and the 131st Senate (17, up from 0). Senators are named from
member lists of the 128th to 132nd saved in the repo (`backend/src/lib/maineLegislatureMembers.ts`, rebuilt with
`openstates/me-member-lists.ts`), so the live senators page is no longer fetched and the 132nd keeps reading after the
133rd is seated; add the 133rd's list when it is. The older House PDFs print surnames only, and each is named from our
Open States roster of that Legislature: 42 of 3,169 member votes stay as printed with no line (21 a surname two seated
members share), and the fetch prints the count. Against the dump, 6 of 9,603 member votes differ, all six paired
senators. Each new refusal was watched failing on a planted fault (46 in the reader, 7 in the fetch). Maine leaves 🛑
in `STATE-QUEUE-gun-policy.md`. Details and gaps: `backend/data/legislatures/me.json`.

**After Oregon and Hawaii (2026-11-21).** Measured over eight states: a state costs 8M to 13M units whatever its
size (Nevada, 55 people: 143,115 a person; Minnesota, 203: 65,389), because about 3.6M of it is fixed: the desk
(1.4M to 1.9M over its whole session), session A's own steps (132 to 151 steps, 1.36M to 1.77M, in seven of eight
states) and session B's (0.67M when nothing goes wrong). What changed, each with the number behind it:

- **Sponsorships in the reader test.** Nevada, Oregon and Hawaii each stopped a live run at recipe step 9 on the page
  that proves a sponsorship (three runner stops, three tool edits mid-run, 13 of their 18 gate runs). Their dry
  batches had listed those pages (81, 428 and 1,266) and nothing read one. `sponsor-page-check.ts` reads a sample as
  the verifier will, and `pilot_batch.py --verdict` gives no verdict without it. On Nevada's old list it fails 6 of
  6 pages; on Colorado's it passes 6 of 6.
- **Session A is `run_setup.py`**: eight steps for A1 to A5, stopping only where a person is needed. The scripts each
  state copied from the state before are shared tools now: `results_scope.py` with `results-scope-data.ts` (the same
  scope, ids and roster as Oregon's, Hawaii's and Nevada's own copies, byte for byte), `stage5_prompts.py triage`,
  `setup_store.py` (Oregon's store step replayed: the same files, apart from two rows a ruling changed later) and
  `bill_table.py join`. The link check runs before the sponsor cover. The quote check's control is built in.
- **`check_fill_quotes.py` reads numbers and single words.** Over 3,848 real quote parts of eight states, the old
  rule caught 0 of 996 planted number changes and 424 of 1,422 planted word changes; the new one about 9 in 10 of
  each, and fails 32 honest parts (a label the fill added in front).
- **`link_check.py` wants every record of a linked member.** Nevada: 39 of the 40 lines leg B added by hand are
  named. It also names 3 unlinked records in Hawaii and 257 in North Dakota, on batches already written: check
  whether the votes on them reached those people another way.
- **The gate's `snippet-page-code`**: 122 of 27,939 written snippets hold markup or an unreadable character (100 of
  them in one Virginia batch).
- **The desk.** `desk.py write` is the write stop in one step, on one of the runner's two kinds of yes, and it never
  approves when the read-back does not match the write. `leg.py --say` files the runner's words and resumes, and a
  stop prints its question. `desk.py slim` prints the commands for a desk in a terminal: 6,470 tokens at the start,
  against about 135,000 in the desktop app.
- **A log line is never a step of its own** (3 to 17 such steps a leg, about 0.15M a state), and a searcher runs
  `topic-stage5-find.ts check` on its own file (10 files in three states were refused for a party word and reworded
  by the main session).
- Not built: mapping a blank to its reason without a hand step. All 31 such rows of four states were blanks the
  record script wrote with no `shows_side`; whether a vote on a no-position bill shows a side is in the bill table's
  free text. It needs a `side` key on a no-position row, which is a ruling.
- **`summary-second-opinion.ts`** (position summaries, step 3). `--profile <topic-profile.json> --batch <name> [--models a,b] [--timeout 180]`
  sends each `checker/<n>.md` to one GPT and one Gemini model through `opencode run`, in an empty temp dir with secrets
  stripped from the environment, and appends one check per (summary, model) to `checks.jsonl`. A timeout, error or
  unusable reply is recorded as a fail ("no usable reply: …"), never a pass. Models come from `--models` or the profile's
  `second_opinion_models`; use `opencode-go/gpt-6-luna` and `opencode-go/gemini-4-argon`. 🔴 The `opencode/…` models are
  pay-as-you-go and answered "Insufficient balance" (HTTP 402, as an error event with exit 0) on 2026-11-22; only
  `opencode-go/…` models run on the plan.
- **The rest of the position-summary tools** (recipe: STAGE5.md section 7b; all take `--profile <topic-profile.json> --batch <name>`):
  - `summary-inputs.ts [--state xx|federal] [--people id,id] [--max-findings 25]` builds `summaries/<batch>/writer/<n>.md`
    (about 10 people each), `people.json` and an empty `drafts/` for people coded `seated` or `doesnt-fit` with a saved finding.
  - `summary-assemble.ts` turns the writers' `drafts/*.json` into `summaries.jsonl`, `lint-refused.jsonl` and `checker/<n>.md`.
    A bad draft goes to the refused file; it never stops the run.
  - `summary-write.ts [--apply --yes "<the runner's words>"]` is a dry run by default (`PREVIEW.md`, `held.md`, the
    batch agreement rate). With `--apply --yes` it writes the draft season only and records the old text in
    `old-context.jsonl` and the run in `write-log.jsonl`. It refuses off-topic and duplicated rows, and it needs the
    `summary_sha256` column (its migration is applied separately).
