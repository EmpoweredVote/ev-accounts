---
status: proposed
---

# Canonical office/district labeling for politicians

`office_title`, `district_label`, and `district_id` are currently inconsistent across office
types: `office_title` sometimes embeds the district (`"State Representative District 24"`,
`"U.S. Senate - Utah"`) and sometimes is a clean role (`"Representative"`, `"Assessor"`);
`district_label` sometimes carries the seat (`"State House District 24"`), sometimes the
jurisdiction (`"Salt Lake County"`, `"Utah"`, `"United States"`), and sometimes the role
(`"Utah Attorney General"`); and `district_id` is sometimes a number (`"24"`), sometimes empty,
and sometimes a string (`"Utah"`, `"UNITED STATES"`). We decided to standardize at the source so
that `office_title` holds **only the role/position name** and a single, consistently-populated
field holds the **seat/district designation** (`"District 24"`, `"At-Large"`, `"Ward 3"`, or empty
for single-seat offices), kept separate from the chamber/body and the jurisdiction. The frontend
then renders group = chamber, card title = role, subtitle = seat designation — with no per-office
parsing.

## Considered options

- **Standardize in the backend (chosen).** One source of truth; every consumer (essentials,
  read-rank, candidate cards, election race labels) renders consistently and the frontend stops
  accreting per-office-type special cases.
- **Keep normalizing in the frontend.** Faster per-fix but perpetuates divergence — each new office
  shape adds another frontend branch. Rejected as the long-term model; a contained frontend
  fallback was shipped as an interim (see Consequences).

## Consequences

- Hard to reverse and high blast-radius: requires a migration, changes to whatever populates these
  fields (the scraper / ingest pipeline), a full backfill, and an audit of every consumer that
  currently reads the district out of `office_title`.
- Must verify the new seat-designation field is populated wherever `office_title` currently embeds
  a district **before** stripping it, or that information is lost. Today the affected types are
  `STATE_LOWER`, `STATE_UPPER`, `STATE_BOARD`, `LOCAL` (council), and `NATIONAL_UPPER`
  (state appended). `district_label` is populated on 100% of records sampled but is not a clean
  district field, so it cannot be trusted as-is.
- Interim: essentials renders the district for `STATE_LOWER`/`STATE_UPPER`/`NATIONAL_LOWER` by
  parsing `district_label` (`/district\s+(\w+)/`). That fallback should be removed once this
  standardization lands.
- Evidence (live `POST /essentials/candidates/search`, Salt Lake City, 2026-06-19):

  | district_type | office_title | district_label |
  |---|---|---|
  | STATE_LOWER | `State Representative District 24` | `State House District 24` |
  | STATE_UPPER | `State Senator District 9` | `State Senate District 9` |
  | NATIONAL_LOWER | `Representative` | `Congressional District 1` |
  | NATIONAL_UPPER | `U.S. Senate - Utah` | `Utah` |
  | COUNTY | `Assessor` | `Salt Lake County` |
  | LOCAL_EXEC | `Mayor` | `Salt Lake City Mayor` |
