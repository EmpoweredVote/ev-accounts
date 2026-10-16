# education-library-books — Season 3 draft, Opus-alone coder run (2026-10-15)

Operator: Chris Andrews (`CA_`). 33 seated people from the Stage 3 test set; Draft A = revision 7bb64029, pinned in
draft Season 3 (7b3a066c) by CA_0310. Every chair goes to review; nothing is auto-pushed. Voters cannot see draft rows.

Steps (run from `backend/`): `make_spec.py` → `stage_human_saved.py` → `scripts/gold-desk/build_batch.py <spec>
--season draft [--coders-only --slots 1 --parallel 3]` → `finish.sh <batch names>` (store-snapshots,
code-stance-batch `--models "opus" --apply`, queue-coded-batch `--apply`, all `--season draft`) → `report.py`.

- `spec-dry.json` (Ward, Jackson), `spec-wave1.json` (17), `spec-utah.json` + `spec-boards.json` (= `spec-wave2.json`, 14),
  `spec-r2.json` (7 re-coded with the sources the coder asked for on its first pass; batch names end `-r2`).
- `human-saved/` — sources the honest fetcher could not read, saved by hand with the operator's OK for this run
  (2026-10-15): Chino Valley BP 6163.1, AR 1312.2 (host robots.txt disallows bots) and 2023-11-16 minutes (Wayback);
  Escambia Rule 2522 (2024, 2025) and three BoardDocs agenda vote pages (BoardDocs refuses scripted fetches without a
  cookie); Utah HB 29 enrolled copy (image-only PDF, read by tesseract OCR); Clay 2023-04-06 minutes (fetcher said
  binary-content; pdftotext). Each file's first line says where it came from and how.
- `results.json` / `report.py` — the outcome per person.
