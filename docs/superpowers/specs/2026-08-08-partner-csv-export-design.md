# Partner CSV Export — CA + OR officeholder data

**Date:** 2026-08-08
**Requester:** Chris (operator)
**Recipient:** Civic Data Tech (external, reciprocal data exchange — they have already shared theirs)
**Status:** Approved, building

---

## Purpose

Give an external partner our California and Oregon officeholder data in a form they can ingest
*and* judge the quality of. The second half is the harder requirement: a CSV that looks uniformly
confident misrepresents us, because our coverage is genuinely uneven and some columns hold
placeholders rather than facts.

The bundle therefore ships its own gaps alongside its data.

## Scope

- **States:** CA and OR, matched on `lower(essentials.districts.state)`.
- **Occupancy:** current only. There is no history to share — 1 closed term row in CA, 0 in OR.
- **Excluded by decision:** compass stances, campaign finance, email addresses.

Stances were excluded because the `reasoning` field is voter-facing prose that reads as a quote
when lifted out of its citation context; sharing it to a partner who may republish is a
fabricated-quote risk we're not taking in a first exchange. Finance was excluded as low marginal
value — it is FEC-derived and already public at the source.

## Grain

Three files at three grains. The seat/person split is deliberate and mirrors ADR 0002:

- `essentials.offices` is a **seat**. It holds no occupant.
- Occupancy is a dated row in `essentials.office_terms`.
- CA has 1,129 seated offices but 1,127 distinct people — two officials hold two seats each.

A single flat file would teach the partner that "a person has a title," which is wrong, cannot
represent an unoccupied seat, and would corrupt their ingest. Three files preserve the model.

## Files

| File | Rows | Grain |
|---|---|---|
| `ev_offices_ca_or.csv` | 1,936 | One row per seat, including unoccupied |
| `ev_politicians_ca_or.csv` | ~1,426 | One row per person |
| `ev_office_holders_ca_or.csv` | 1,428 | Occupancy link + term facts |
| `README.md` | — | Data dictionary, provenance, join instructions, license terms |
| `COVERAGE.md` | — | Per-state / per-district-type completeness, gaps named |

## Columns

**offices** — `office_id`, `title`, `role_canonical`, `normalized_position_name`, `seats`,
`partisan_type`, `is_appointed_position`, `district_id`, `district_label`, `district_type`,
`district_subtype`, `state`, `city`, `ocd_id`, `geo_id`, `occupancy_status`

**politicians** — `politician_id`, `external_id`, `external_id_is_synthetic`, `bioguide_id`,
`full_name`, `first_name`, `last_name`, `middle_initial`, `name_suffix`, `preferred_name`,
`party`, `official_url`, `photo_url`, `photo_url_kind`, `photo_url_is_third_party`,
`data_source`

**office_holders** — `office_id`, `politician_id`, `term_start`, `start_precision`, `term_end`,
`source`

## Honesty rules

Enforced in the script and asserted before any file is written.

1. **No placeholder dates.** `term_start` is emitted only where `start_precision ∈ ('day','year')`
   — 60 rows across both states. Elsewhere blank with `start_precision='unknown'`. 95% of CA and
   97% of OR term rows are open-ended backfill placeholders, not researched dates. Shipping them
   as dates would hand the partner 1,369 false facts.
2. **Empty string is not a value.** `party = ''` → blank. 76 CA rows hold an empty string; a naive
   `IS NOT NULL` check counts them as populated and overstates party coverage by 76.
3. **`unknown` ≠ `vacant`.** `occupancy_status` distinguishes `seated` (1,129 CA / 299 OR),
   `vacant` (1 / 3, confirmed via `offices.is_vacant`), and `unknown` (504 / 0 — seats with no
   `office_terms` row ever written, all CA judicial). Collapsing these misrepresents quality in
   both directions.
4. **Photos are links, not assets, and the column is polluted.** `photo_origin_url` has been
   doubling as a research scratchpad: 83 rows hold a process note rather than a URL (`explored`,
   `searched:no_results`) and are blanked on export; a further 224 hold a real URL pointing at a
   roster page or a Wikipedia article about the *city* rather than a portrait, and are labelled
   `photo_url_kind='page'`. Only 175 rows are genuine images. Counting this column with
   `IS NOT NULL` overstates portrait coverage roughly 3x. 398 of 399 surviving URLs are on hosts
   we do not control, so the README grants no image rights and warns of link rot.
5. **`external_id` is mostly not an identifier.** 1,341 of 1,426 values are negative numbers we
   minted for self-seeded records; only 85 correspond to a real upstream key. Exported with an
   `external_id_is_synthetic` flag, and the README directs matching to `politician_id` /
   `bioguide_id` / reviewed name+district instead.
6. **Empty string is not a value — checked file-wide.** Verification scans every column of every
   file for whitespace-only cells, rather than guarding named columns. This trap has now been hit
   independently by `party` (76 rows), `bioguide_id` (87 rows) and `data_source`.
7. **Generated counts only.** Every number in `COVERAGE.md` is produced by the same run that
   writes the CSVs. No hand-typed figure can drift from the data.

## Known gaps to disclose

Measured at build time on 2026-08-08.

| Gap | CA | OR |
|---|---|---|
| Seats with unknown occupancy | 504 (31%, all judicial) | 0 |
| Officeholders with real party value | 873 / 1,127 (77%) | 103 / 299 (34%) |
| Officeholders with a usable **portrait** | 158 (14%) | 17 (6%) |
| Photo URLs that are pages, not portraits | 199 | 25 |
| Per-row `data_source` populated | 691 (61%) | 0 |
| `external_id` synthetic | 1,042 (92%) | 299 (100%) |
| Federal officeholders with `bioguide_id` | 17 / 53 | 0 / 8 |
| Term starts with real precision | 52 (5%) | 8 (3%) |

## Build

`backend/scripts/export-partner-csv.mts` — read-only, parameterized by state list so it is
reusable for the next partner. Writes to an output directory, then re-reads its own CSVs and
asserts:

- row counts match the source queries
- no `term_start` present where `start_precision = 'unknown'`
- no whitespace-only cell in any column of any file
- no non-URL value in `photo_url`; `photo_url` and `photo_url_kind` never out of step
- `occupancy_status` is a closed set and totals reconcile to the office count
- referential integrity across all three files, both directions

Fails loudly rather than writing a bad file. This caught a real defect during development: a NULL
photo fell through a `CASE` to `ELSE 'page'`, mislabelling all 944 photo-less rows, because
`NULL !~* '...'` evaluates to NULL rather than true.

## Out of scope

Delivery mechanism (how the bundle reaches Civic Data Tech), any data-sharing agreement or
license text beyond a short attribution/no-image-rights note in the README, and reciprocal ingest
of their data.
