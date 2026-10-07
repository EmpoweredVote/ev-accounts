# LegiScan state legislative refresh (CA, IN)

Loads bills, votes and committee data from LegiScan weekly datasets into the
`essentials.legislative_*` tables. Ported from the archived `EV-Backend` repo
(`scripts/import_state_legislative.py`, built in March 2026). Decision: ev-cto
`knowledge/decisions/0030-legiscan-refresh-bulk-datasets.md`.

## Rules
- One LegiScan key only: `LEGISCAN_API_KEY`. Do not register a second key or account.
- Free tier is 10,000 queries a month (about 2 requests a second). A run costs about
  5 queries per state: `getDatasetList`, `getDataset`, `getSessionPeople`.
  The counter lives in `~/.ev-backend/legiscan_counter.json`.
- Data is CC BY 4.0. Pages that show it must credit LegiScan (see `essentials`
  `LegiScanAttribution.jsx`). Never store or show a legislator's party.
- Datasets update Sundays about 5am Eastern. Run weekly, after that. Unchanged
  sessions are skipped by `dataset_hash` (use `--force` to override).

## Run
    pip install -r requirements.txt
    python import_state_legislative.py --state CA --sessions current --dry-run --verbose
    python import_state_legislative.py --state CA --sessions current
    python import_state_legislative.py --state IN --sessions current,previous

Needs `LEGISCAN_API_KEY` and `DATABASE_URL` in `backend/.env` or the shell.

## Session changes
Edit `state_legislative_config.json` when a new session starts: IN 2027 (January 2027),
CA 2027-28 (December 2026). Set `current_year_start` and `previous_year_start`.
