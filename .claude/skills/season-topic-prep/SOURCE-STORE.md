# Source store — what to save, when

Every stage saves what it finds, so later stages, later topics, later seasons and the national research reuse it
instead of searching again. The store is plain JSON in the repo at `backend/data/source-store/`, committed with
each stage's PR. A later project (the database source-and-bill library) will import it, so the format is fixed.

- **Schemas:** `backend/scripts/lib/sourceStore.ts` (zod). The layout, ids and merge rules are in
  `backend/data/source-store/README.md`.
- **Write with the helpers**, not by hand: `upsertInstrument`, `upsertPerson`, `upsertJurisdiction` and
  `appendDeadEnd` from `sourceStore.ts`. They merge with what is already there (re-running a stage never
  overwrites), keep keys in schema order and validate. A small `npx tsx` script in your research folder that
  imports them and reads the collectors' JSON is the usual way.
- 🔴 **Before every commit:** `npm run source-store --prefix backend -- validate`. It exits 1 and names each broken
  file.

## When to write each file

| File | Write it when | What it must carry |
|---|---|---|
| `jurisdictions/<scope>.json` | You fetch, or fail to fetch, a portal, a roster or a session list for a place, or you find a standing higher-law duty on the topic | Each portal with `works`, `blocked` or `needs-browser` and how to fetch it; roster and session-list URLs; duties per topic key with the citation |
| `instruments/<scope>/<id>.json` | You read a bill, ordinance, policy or resolution (census, Stage 1, Source path) | Official URLs; version (as filed, enrolled, adopted); operative text or a saved-copy reference; the single-subject verdict with season, codebook version and topic-list hash; higher-law duty note; **every vote** (date, body, motion, kind, tally, body size, each member's vote with politician id where matched) |
| `people/<politician-id>.json` | You find a source for a person (a record or their own words), whether useful or not, or a term date | URL, kind (`record` or `own-words`), topic keys, `useful` true or false, a note; term dates with their precision and source |
| `dead-ends.jsonl` | A search finds nothing, or a portal blocks you, is paywalled, or robots forbid it | Date, scope or person, topic key, the query or URL, the result (`nothing`, `blocked`, `paywalled`, `robots`), who searched |

Read the store **first** at Stage 0 and on the Source path: `jurisdictions/` for portals and rosters,
`instruments/` for what is already found, `people/` for sources and term dates, `dead-ends.jsonl` so nobody repeats
a blocked search.

## Ids

- People: the politician UUID. Only matched people get a `people/` file; unmatched members keep their printed name
  inside the vote.
- Jurisdictions: the steward scope form `federal`, `state:wa`, `county:53033`, `place:5363000`.
- Instruments: jurisdiction prefix, instrument, year, e.g. `WA-ESSB-5044-2021`. Companion bills are two instruments.

## Provenance

Every instrument, person source and portal records who fetched it (`fetched_by`), when (`fetched_at`, ISO), how
(`method`: `webfetch`, `curl`, `browser`, `ocr`, `api`, `hand-saved`) and, for a saved copy, its path and SHA-256.
A hand-saved source keeps the existing rule: the source and method on its first line, with the runner's OK.

## Large copies stay out of the repo

PDFs, page captures and OCR output are **not** committed. Keep them in the research folder (for example
`stage1/raw/`) and reference them from the store by path and SHA-256 (`shasum -a 256 <file>`), in
`provenance.saved_copy`. A later reader finds the copy by its hash.

## One-time import of the pilots

What the Season 3 pilots already hold in structured form (instruments, tallies and member votes, rosters, session
lists, term starts, blocked portals) is imported once by `npm run import:pilot-sources --prefix backend` (added in
the import task of the build plan). Free-text notes are not converted. After the import, a run reads the store
like any other.
