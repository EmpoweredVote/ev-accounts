# First-load test fixtures

Slices of the hand-built inventory, copied from
`.planning/research/local-inventory/bloomington-in/` on 2026-11-26. Only the fields first-load reads were kept.

- `inventory-full.json`: all 18 items dated 2026-10-07 from `full.json`.
- `inventory-deep.json`: 12 items from `deep.json` that cover each id suffix form (veto override, Vetoed, amendment 01,
  amendment to amendment, reasonable condition, motion to read by title).
- `inventory-roster.json`: `roster.json`, whole file.

The reader-side tests reuse the OnBoard fixtures in `src/lib/localRecord/onboard/__fixtures__/`. Politician ids in
the tests are placeholders (`p-...`), never real ids.
