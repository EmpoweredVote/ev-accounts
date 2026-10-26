# Hand-checked voting locations

One JSON file per county per election. Each file feeds
`backend/scripts/generate-voting-locations-migration.mjs`, which writes a migration that loads
the county's precinct boundaries and voting sites into `essentials.voting_location_sets`,
`essentials.voting_precincts` and `essentials.voting_sites` (tables from `CA_0320`).

The voter-info endpoint uses these rows **only when Google's Voting Information Project
returns nothing** for an address. See `backend/src/lib/localVotingLocations.ts` for the rules,
including the precinct-line guard that withholds an Election Day site rather than risk a wrong one.

## Rules

- **Copy only from the county's or state's own published documents.** Never from a lookup that
  asks for a voter's name or birth date. Record each document's URL, modified date and SHA-256
  under `documents`, so a re-check can tell at a glance whether it changed.
- **Precinct polygons yes, the GIS layer's poll-site fields no** (unless verified against the
  current official list). Monroe's layer pointed 23 of 83 precincts at old sites.
- **Every precinct in the boundary layer must map to exactly one Election Day site.** The
  generator refuses to write a migration otherwise.
- **A set expires on its election day.** Nothing is served after `election_date`, so a stale
  set shows nothing rather than something wrong. A new election is a new file and a new set.

## Re-checking a set

1. Download each document in `documents` and compare its SHA-256.
2. If nothing changed, update `last_checked` with a one-line migration:
   `UPDATE essentials.voting_location_sets SET last_checked = 'YYYY-MM-DD' WHERE county_fips = '…' AND election_date = '…';`
3. If something changed, edit the JSON, regenerate, and replace the set's rows in a new migration.

## Adding a county

Write a new JSON file in the same shape, then run:

```bash
node backend/scripts/generate-voting-locations-migration.mjs backend/data/voting-locations/<file>.json > backend/migrations/<slot>_<name>.sql
```

Before shipping, test real addresses (the IndianaMap / NAD address points work well) against
Google's answers. In Monroe, every precinct where Google answered agreed with the county list.
