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
    python import_state_legislative.py --states CA,IN,TX
    python import_state_legislative.py --all --dry-run     # every state with a sitting legislator
    python import_state_legislative.py --all

`--all` reads the list of states from our database. For each state it picks the two
newest regular sessions from LegiScan's dataset list. A state listed in
`state_legislative_config.json` uses the years in that file instead. Legislators are
matched by name inside their own state only. A session whose `dataset_hash` has not
changed since the last good import is skipped at no query cost. After the legislator
roster grows, run with `--force` so new legislators get their votes.

Known limits: bills already in the database are not updated, so a bill's status
(passed, signed) can lag. Writes are row by row over the network, so a big state takes
tens of minutes.

Needs `LEGISCAN_API_KEY` and `DATABASE_URL` in `backend/.env` or the shell.

## Session changes
Edit `state_legislative_config.json` when a new session starts: IN 2027 (January 2027),
CA 2027-28 (December 2026). Set `current_year_start` and `previous_year_start`.
