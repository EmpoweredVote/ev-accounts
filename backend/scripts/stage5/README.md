# Stage 5 batch tools

The tools behind the Stage 5 write recipe: `.claude/skills/season-topic-prep/STAGE5.md`, step 7. Each one takes
the topic, state and season as arguments; none hard-codes a topic id, a season id or a worktree path. They were
moved here from the voting-rights batches (2026-10-29/30) and replayed on the Indiana batch `in-01`, matching its
outputs file for file.

Run them from `backend/`: TypeScript as `ADMIN_INGEST_TOKEN=placeholder npx tsx --env-file=.env scripts/stage5/<tool>.ts`,
Python as `python3 -I scripts/stage5/<tool>.py`. `<batch>` is the batch folder, `stage5/write/<unit>-NN/`.

| Step | Tool | What it does |
|---|---|---|
| 0, 14 | `write-batch.sh <stage5> <batch> <topic> <units> [N\|apply]` | `topic:stage5-write` with `held.txt` / `moved.txt` codes set aside, then put back (even on failure) |
| 2 | `add_hand_rows.py <batch> <stage5> <findings> --topic <key>` | appends the rows in `hand-rows.json` (`{id: "no-evidence" \| "direction-only"}`) |
| 4 | `build_evidence.py <batch> <roster.tsv> <findings> [--fetch] [--level state --state XX]` | builds `evidence.csv`; lists unread pages in `evidence-missing.json` |
| 4 | `pdf_pages.py <batch>` | reads PDF sources with `pdftotext` |
| 5 | `s1-sources.ts --topic <key> <batch>` | old-season sources behind each blank over a shown answer → `fallback/fallback-required.json` |
| 5 | `fallback-fetch.ts <batch>/fallback` | loads `fallback/urls.txt` through the verifier's own fetch steps |
| 5 | `add_fallback.py <batch> --topic <key> --gloss "…" [--hold Name]… [--seen Name]…` | lists loaded old sources as examined on each blank |
| 6, 10 | `party-sweep.ts <evidence.csv>` · `party-sweep.ts --research <research.csv>` | lists snippets / research text that name a party (must end at 0) |
| 6 | `party_fix.py <batch>` | drops swept snippets (or cuts, `party-cuts.json`); uncites a page left with none |
| 7 | `legiscan-rollcalls.ts <ST> <vote-pages.json> <out.json>` | finds the LegiScan roll call for each official one (bill, chamber, counts) |
| 7 | `legiscan_pairs.py <batch> <findings> --topic --state --host --rollcalls <json> [--bill-pad N]` | official votes/authorships → `legiscan/pairs.csv` |
| 7 | `../legiscan-evidence-lines.ts --in pairs.csv --out legiscan-evidence.csv` | the LegiScan lines (counted API calls) |
| 7 | `legiscan_merge.py <batch> --host <official host>` | cites the lines, uncites covered official pages, cross-checks every vote (exit 1 on any disagreement) |
| 8 | `add_bill_text.py <batch> --topic --url --sentences <json> [--text <file>]` | bill text as cited passages for quotes the gate cannot find |
| 9 | `apply_overrides.py <batch>` | research-text trims from `overrides.json` (`{"trims": [...]}`), never a stance or value |
| 14 | `readback.ts --topic <key> <ids file> [--batch-id <id>]` | outcomes, passages and review rows the draft season now holds |
| 15 | `approve-batch.ts <editor uuid> <batch,...> [--skip "Name"]…` | 🛑 approves pending review rows, on the runner's separate "approve" |

Notes:

- ⚠ **`build_evidence.py` and `pdf_pages.py` fetch with a browser user-agent.** This is a deliberate exception to
  decision 0003 (ev-cto `knowledge/decisions/0003-scraping-toolchain.md`), ruled 2026-10-31 (Chris Andrews), for local research runs only. Never copy it into a live or
  scheduled fetch path. A page these tools read is not proof the verifier can read it: the verifier sends the honest
  `EmpoweredVoteBot` identity (`src/lib/verificationFetch.ts`). iga.in.gov, for example, serves its PDFs and JSON to
  a browser identity only, so Indiana's records come from LegiScan or the official keyed API (`api.iga.in.gov`).

- `build_evidence.py` also reads an `overrides.json` of the older shape `{name: {column: value}}`; a `{"trims": …}`
  file is ignored by it (no row is named "trims").
- `lib.ts` holds the pure helpers (`readCsv`, `sweepHit`) and their tests; `batch-db.ts` resolves the topic id and
  the draft season; `_args.py` is the Python tools' argument reader.
- One-off fixes for a single batch (a person's own sentence added by hand, a page uncited because the research text
  says it is unused) stay in that batch folder, with a line in its `PREVIEW.md`.
