# Source store

What the season-topic-prep skill finds while it works, saved so the next stage (or the next runner) does not search again. Plain JSON, committed with each stage's PR. Schemas live in `backend/scripts/lib/sourceStore.ts`; check the files with `npm run source-store --prefix backend -- validate`.

Large saved copies (PDFs, page captures) are not committed. They stay in the runner's research folder (`~/Documents/GitHub/.planning/research/` by default) and are referenced here by path and SHA-256.

## Layout

- `instruments/<scope-dir>/<instrument-id>.json` — one bill, ordinance, policy or resolution. Official URL(s), version (as-filed, enrolled, adopted, other), operative text, single-subject verdict per served topic list (with season and codebook version), higher-law duty note, and every vote: date, body, motion, kind (action-item, consent, en-bloc, roll-call), tally, and per-member yea/nay/absent/abstain with politician ids where matched. A vote may carry a `note` for a caveat such as an inferred count.
- `people/<politician-id>.json` — sources found for one person (own words and records), the topic keys each covers, whether each was useful, and term dates found with their precision.
- `jurisdictions/<scope-dir>.json` — portals and how to fetch them (works, blocked, needs-browser), roster and session-list sources, and standing higher-law duties per topic.
- `dead-ends.jsonl` — one JSON object per line: what was searched and found nothing, or was blocked, with date and who searched.

## Ids

- Politician ids are the politician UUIDs.
- Jurisdiction scopes use the steward form: `federal`, `state:wa`, `county:53033`, `place:5363000`. The directory name replaces `:` with `-` (`state-wa`).
- School districts use `place:<7-digit district geoid>` (the geoid `essentials.districts` holds for the district, e.g. `place:5103840` Virginia Beach City Public Schools). Consolidated city-counties use the geoid essentials stores (Nashville is `county:47037`).
- Instrument ids are jurisdiction prefix, instrument, year: `WA-ESSB-5044-2021`.

## Provenance

Every instrument, person source, jurisdiction portal and saved copy records who fetched it (`fetched_by`), when (`fetched_at`, ISO), how (`method`: webfetch, curl, browser, ocr, api, hand-saved, unrecorded when an imported source never recorded one), and the SHA-256 of any saved copy. A saved copy's `path` is relative to the runner's research root (for example `s3-pilot-equity-programs/stage1/raw/vb/040825M.pdf`), so the store reads the same on every machine. Hand-saved sources keep the existing rule: source and method on the first line, with Chris's OK.

## Merge rules (re-running a stage)

- Instruments: votes are unioned by (date, body, motion). Every other field comes from whichever copy has the newer `provenance.fetched_at`. `single_subject` entries are unioned by (season, codebook, topic_list_hash).
- People: sources are unioned by URL (newer `fetched_at` wins); terms by (office, start).
- Jurisdictions: portals by URL (newer `checked_at` wins), rosters by URL, duties by (topic key, duty).
- Dead ends are append-only.
