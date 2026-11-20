# Member ids

Every sitting state legislator should carry ids that name them without a name match. They live in
`essentials.legislative_politician_id_map` (one row per person, id type and value; one id names one person).

| id_type | What it is | Filled by |
|---|---|---|
| `openstates` | Open States person id (`ocd-person/…`). Follows a person across sessions and chambers. The common key for every state. | `sync-member-ids.ts` (seat match) |
| `ga-member`, `id-member`, `pa-member`, `sc-member` | The legislature's own member id, where it is one per person. Read from the Open States record's links. | `sync-member-ids.ts` (id crosswalk) |
| `mn-lrl`, `mn-senate-mem` | Minnesota LRL id (what Revisor author links carry) and the Senate's own number. | `mn-member-ids.ts` |
| `legiscan` | LegiScan person id. Mostly matched **by name** (`match_method = 'name'`). | LegiScan importer |
| `bioguide` | Congress. | federal loaders |

`match_method` says how a row was made: `seat`, `id_crosswalk`, `manual` are trusted; `name` is not proof.
`src/lib/memberIds.ts` (`loadMemberIds`) reads trusted rows only.

## Why not each legislature's own id everywhere?

Many are not one per person (checked 2026-11-19 from Open States' links): Arizona, South Dakota and Wisconsin
issue a new id every session; Virginia, Kansas, Massachusetts and Maryland issue a new one when a member moves
between chambers. Georgia, Idaho, Pennsylvania, South Carolina and Minnesota keep one id per person, so those are
stored. A person may hold several ids of a type (an old and a new one); nothing is overwritten.

## Keeping them current

1. After any change to who sits in a legislature (roster refresh, special election, January turnover), run
   `npx tsx scripts/member-ids/sync-member-ids.ts` (dry run), read the problems, then add `--apply`.
   Minnesota: also `mn-member-ids.ts`.
2. `select * from essentials.legislator_member_id_gaps` lists sitting legislators with no trusted Open States id.
   What stays there should be only what the sync reports as a problem: a member Open States has not added yet
   (Indiana and Nevada seat new members the day after the election), a changed name, a family name shared inside
   a multi-member seat, or a duplicate person record (merge it; the ids move with it).
3. Stage 5: `link_check.py --from-db --add` uses these ids before any name rule.

The sync never deletes and never moves an id from one person to another; a conflict is listed for a person to fix.
