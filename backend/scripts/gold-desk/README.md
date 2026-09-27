# Blind Gold Desk

The page a person uses to give blind gold labels (codebook reliability spec §4.3). Published as a
private claude.ai artifact: https://claude.ai/artifact/CWYdrGNwmwBhjBDs9NaPpu

- `gold-desk.html` — the page. Items live in its database at `items/<id>` (only an editor writes them);
  each labeller's answers are at `labels/<uid>/items/<itemId>`, private to that labeller (the owner reads
  all). The page never shows coder output.
- `make_item.py` — builds one item document from a coded batch. It reads `coding-context.json`,
  `topics.json` and `snapshots.json` only — never `labels/` or `coding-report.json` — so an item cannot
  leak what the coders chose. Write the plain meanings (glossary) before looking at coder output.

Answers become gold with `scripts/record-gold-labels.ts` (the gold file stays outside the repo).
