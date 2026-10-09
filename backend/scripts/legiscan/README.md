# LegiScan state legislative refresh

The refresh is now a TypeScript job, not a script. Code: `backend/src/lib/legiscan/`.
Job name: `legiscan` (`backend/src/jobs/registry.ts`). It loads bills, votes and committee
data from LegiScan's weekly datasets into the `essentials.legislative_*` tables for every
state that has a sitting state legislator in our database (29 states).
The old Python loader (built March 2026 in the archived `EV-Backend` repo) was removed
after the TypeScript job matched it row for row on CA and IN. ev-cto decision 0031.

## Run it
    node dist/jobs/run.js legiscan                       # what the Render cron runs
    # manual, from backend/ (needs LEGISCAN_API_KEY and DATABASE_URL in .env):
    LEGISCAN_DRY_RUN=1 LEGISCAN_STATES=CA,IN npx tsx src/jobs/run.ts legiscan

Optional environment overrides: `LEGISCAN_STATES=CA,IN`, `LEGISCAN_DRY_RUN=1` (write
nothing), `LEGISCAN_FORCE=1` (ignore the unchanged-hash skip; use after the legislator
roster grows), `LEGISCAN_SESSIONS=current`.

## Rules
- One LegiScan key only: `LEGISCAN_API_KEY`. Never register a second key or account.
- Free tier: 10,000 queries a month, about 2 requests a second. The job spaces calls
  0.6 s apart and counts every call in `essentials.legiscan_query_counter`. It stops 100
  short of the cap. A quiet week costs about 1 query per state.
- A session whose `dataset_hash` matches `essentials.legiscan_dataset_state` is skipped.
  Datasets update Sundays about 5am Eastern; the cron runs Sundays 14:00 UTC.
- Data is CC BY 4.0. Pages showing it must credit LegiScan (`essentials`
  `LegiScanAttribution.jsx`). Never read or store a legislator's party.
- Legislators are matched by name inside their own state only. A name with 2 or more
  candidates is skipped and logged, never guessed.
- LegiScan has no Puerto Rico dataset.

## Known limits
- New legislators get old votes only after a `LEGISCAN_FORCE=1` run.
- Sponsors and committees are written for new bills only; existing bills get status and
  roll-call refreshes.
