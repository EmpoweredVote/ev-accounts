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
- `dead-ends.jsonl` is append-only and marked `merge=union` in `.gitattributes`, so two branches that each add
  lines merge without a conflict.
- **A run that cannot commit** (dry mode, or a test run of the skill) writes a staging copy with `--root
  <research folder>/<stage>/store-staging` (the helpers take any root, and `validate --root <dir>` checks it). Merge
  it into the repo store later, in a PR: `npm run source-store --prefix backend -- merge --from <abs staging dir>`.
  It uses the same merge rules and skips dead ends already present.

## When to write each file

| File | Write it when | What it must carry |
|---|---|---|
| `jurisdictions/<scope>.json` | You fetch, or fail to fetch, a portal, a roster or a session list for a place, or you find a standing higher-law duty on the topic | Each portal with `works`, `blocked` or `needs-browser` and how to fetch it; roster and session-list URLs; duties per topic key with the citation |
| `instruments/<scope>/<id>.json` | You read a bill, ordinance, policy or resolution (census, Stage 1, Source path) | Official URLs; version (as filed, enrolled, adopted); operative text or a saved-copy reference; `sponsors` (prime, co, author or patron, as printed, with the version and a politician id once identity-checked); the single-subject verdict with season, codebook version and topic-list hash; higher-law duty note; **every vote** (date, body, motion, kind, tally, body size, each member's vote with politician id where matched) |
| `people/<politician-id>.json` | You find a source for a person's own words, a sponsorship or a term date, whether useful or not | URL, kind (`record` or `own-words`), topic keys, `useful` true or false, a note; term dates with their precision and source. **A roll-call vote lives on the instrument only**: do not write a person file for every voter. |
| `findings/<politician-id>.json` | Stage 5: a search for one person ends, whether it found anything or not | Each finding: `kind` (`record` or `own-words`), URL, date and precision, the **exact passage** for own words, the instrument and `act` for a record, `local_record` for a local ordinance or resolution, a plain note, `subjects` in plain words (not rung numbers), topic keys, provenance. One `searches` entry per search: topic, season, subjects, places, count found. Write with `upsertFindings`. |
| `dead-ends.jsonl` | A search finds nothing, or a portal blocks you, is paywalled, or robots forbid it | Date, scope or person, topic key, the query or URL, the result (`nothing`, `blocked`, `paywalled`, `robots`), who searched |

Read the store **first** at Stage 0 and on the Source path: `jurisdictions/` for portals and rosters,
`instruments/` for what is already found, `people/` for sources and term dates, `dead-ends.jsonl` so nobody repeats
a blocked search.

## The topic-list hash

Every single-subject verdict records `topic_list_hash`: SHA-256 of the season's served topic keys, de-duplicated,
sorted, one per line with a trailing newline. Print it with
`npm run source-store --prefix backend -- topic-list-hash --season <open|draft|uuid>` (Season 3 draft, 60 topics,
on 2026-10-22: `a7b0076a…`). Two verdicts with the same hash were judged against the same list. Never write
`pilot-unrecorded` for a new verdict.

## Ids

- People: the politician UUID. Only matched people get a `people/` file; unmatched members keep their printed name
  inside the vote.
- Jurisdictions: the steward scope form `federal`, `state:wa`, `county:53033`, `place:5363000`, and
  `school:<7-digit geoid>` for a school district (the geoid `essentials.districts` holds for the school district
  row, e.g. `school:5103840`). A school district never uses `place:`.
- Instruments: jurisdiction prefix, instrument, year, e.g. `WA-ESSB-5044-2021`. Companion bills are two instruments.

## From the census brief to the store

Collectors write what [templates/BRIEF-census-local.md](templates/BRIEF-census-local.md) and
[templates/BRIEF-census-state.md](templates/BRIEF-census-state.md) ask for. Save it in the store's
terms:

| Census brief | Store |
|---|---|
| member vote `yes` | `yea` |
| member vote `no` | `nay` |
| member vote `abstain` | `abstain` |
| member vote `absent` | `absent` |
| member vote `recused` | `recused` |
| state roll call `yea_names` / `nay_names` | one member each, `yea` / `nay` |
| state roll call `absent_names` | one member each, `absent` |
| state roll call `not_voting_names` | one member each, `abstain` |
| state roll call `other_names` (older briefs, not split) | `absent` when marked excused or absent; `abstain` when marked not voting or present; a `note` on the vote when the page did not say which |
| `sponsors` / `prime_sponsors` | `sponsors` (role `prime`, `co`, `author` or `patron`; never appended to `operative_text`) |
| `names_from` | a vote `note` when it is `reader summary` or `news` (the identity step re-reads those) |
| record type `ACTION_ITEM_NAMED` | a vote with `kind` `action-item` and every named member |
| record type `ACTION_ITEM_TALLY` | a vote with `kind` `action-item`, the tally and `members: []` |
| record type `CONSENT` | a vote with `kind` `consent`, or `en-bloc` when the minutes say en bloc |
| record type `OTHER` | no vote (save the instrument only if its text is useful) |
| state or federal `rollcalls` entry | a vote with `kind` `roll-call` |
| `body_size` | `body_size` |
| `tally` / `yeas`, `nays` | `yes`, `no` (and `absent` when the count is printed); an inferred count gets a `note` |
| `motion_quote` / `motion` | `motion` |
| `url_minutes`, `url_item`, `url_other` | `urls` (official pages only) |
| `content_terms` / `operative_parts` | `operative_text` |
| `state_duty_note` / `higher_law_note` | `higher_law_duty` (omit when "none cited") |
| `other_subjects` | input to the single-subject verdict, recorded in `single_subject` once ruled |
| `own_motion` | not stored on the instrument; it goes in `stage0/gates.tsv` |

## Provenance

Every instrument, person source and portal records who fetched it (`fetched_by`), when (`fetched_at`, ISO), how
(`method`: `webfetch`, `curl`, `browser`, `ocr`, `api`, `hand-saved`, or `unrecorded` for an imported source that
never recorded one) and, for a saved copy, its path and SHA-256.
A hand-saved source keeps the existing rule: the source and method on its first line, with the runner's OK.

## Large copies stay out of the repo

PDFs, page captures and OCR output are **not** committed. Text extraction drops strike-through: when a saved PDF
shows markup, also keep the rendered page images (`pdftoppm -png`) as saved copies, and say in the instrument's
`operative_text` which words are struck. Keep them in the research folder (for example
`stage1/raw/`) and reference them from the store by path and SHA-256 (`shasum -a 256 <file>`), in
`provenance.saved_copy`. A later reader finds the copy by its hash.

## One-time import of the pilots

What the Season 3 pilots already hold in structured form (instruments, tallies and member votes, rosters, session
lists, term starts, blocked portals) is imported once by
`npm run import:pilot-sources --prefix backend -- --research <absolute research root>`. Free-text notes are not
converted. After the import, a run reads the store like any other.
