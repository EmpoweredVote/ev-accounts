---
title: Eight Utah coverage chips claim compass stances that do not exist
type: bug
priority: medium
created: 2026-08-02
source: incidental discovery while re-checking coverage chips after migration 1538
domain: data + frontend (essentials src/lib/coverage.js vs inform.politician_answers)
---

# Eight Utah cities render a "has compass stances" chip with zero stanced officials

Found while doing the coverage-chip re-check that the stance backlog says is owed after any retirement
pass. **Not caused by migrations 1537/1538 — proven pre-existing** (none of the 215 politicians those
two migrations touched is linked to any of these cities).

`src/lib/coverage.js` marks these `hasContext: true`, which renders the purple "compass stances seeded"
chip on the landing page:

| city | geo_id | officeholders linked | stanced |
|---|---|---|---|
| Layton | 4943660 | 6 | **0** |
| Lehi | 4944320 | — | **0** |
| Ogden | 4955980 | 8 | **0** |
| Provo | 4962470 | 8 | **0** |
| Sandy | 4967440 | — | **0** |
| St. George | 4965330 | — | **0** |
| West Jordan | 4982950 | — | **0** |
| West Valley City | 4983470 | — | **0** |

The officeholders exist and are linked to the government; they simply have no rows in
`inform.politician_answers`.

⚠ **This contradicts the recorded project state**, which says ten Utah cities were deep-seeded with only
a Salt Lake City D4 gap remaining. Either the stance half of that seed never landed, or it landed
against duplicate politician records that are not the ones linked to these governments. **Check for
duplicate politician rows before re-researching** — re-seeding stances onto the wrong record would
reproduce the same invisible gap.

## How to reproduce

Occupancy must be resolved through `essentials.office_terms`, **not** `politicians.office_id`. ADR 0002
phase 5 dropped `offices.politician_id`, and `politicians.office_id` is unpopulated for several later
seeds (Dane County, Racine County and Madison all read as zero politicians through that column despite
being fully seeded). A chip audit joining the wrong way reports 27 false zeros instead of 9.

```sql
SELECT g.geo_id, g.name, count(DISTINCT pa.politician_id) AS stanced
  FROM essentials.governments g
  JOIN essentials.chambers c      ON c.government_id = g.id
  JOIN essentials.offices o       ON o.chamber_id = c.id
  JOIN essentials.office_terms ot ON ot.office_id = o.id
  LEFT JOIN inform.politician_answers pa ON pa.politician_id = ot.politician_id
 WHERE g.geo_id = ANY(ARRAY['4943660','4944320','4955980','4962470','4967440','4965330','4982950','4983470'])
 GROUP BY g.geo_id, g.name;
```

## Action

1. Decide per city: seed the stances, or flip `hasContext` to `false` so the chip stops promising
   coverage that is not there. (Beverly Hills was flipped to `false` on 2026-08-02 for exactly this
   reason, after 1538 retired all five of its stanced officials.)
2. Add the query above as a standing check so a chip can never again claim stances the database does not
   hold — the same shape of guard as `check:stance-sources`.
