# CivicPatch open-data — vendored snapshot

Point-in-time copy of [`CivicPatch/open-data`](https://github.com/CivicPatch/open-data) at commit
**`928579c0`** (2026-07-29). CC0-1.0 — public domain, no attribution obligation.

**Why this is vendored rather than fetched.** Civic Data Tech said both repos are free "for as long
as we could keep them up" — an explicit statement that continuity is *not* guaranteed. CC0 means
anything already imported is ours permanently, so the snapshot is the durable half. Any pipeline
that resolves `github.com/CivicPatch/open-data` or `cdn.civicpatch.org` at run time inherits their
uptime. **The importer reads this archive, not the network.** See
[`.planning/decisions/2026-07-30-civicpatch-api-decision.md`](../../../.planning/decisions/2026-07-30-civicpatch-api-decision.md).

## What's here

| | |
|---|---|
| `civicpatch-open-data-928579c0.tar.gz` | 1.67 MB — the `data/` YAML tree plus root metadata |
| `MANIFEST.json` | source SHA, checksum, per-state counts, known discrepancies |

3,258 YAML files, **19,737 official records**, 13 states (ca co id ma mi nc nd nh nj sc tn tx wa).
**Municipal tier only** — their README claims county and state tiers; those do not exist in the tree.

**Count records by parsing the YAML, not with `grep -c '^- name:'`.** That grep misses the 1,203
records whose first key is `id` rather than `name`, which is what produced the phantom
"18,534 vs 19,737" discrepancy this manifest used to carry. Their API and their repo agree exactly.

## Restore

```bash
mkdir -p /tmp/civicpatch && tar -xzf civicpatch-open-data-928579c0.tar.gz -C /tmp/civicpatch
# verify you got what this manifest describes
sha256sum civicpatch-open-data-928579c0.tar.gz   # a48fa685...45c2
```

Records live at `data/<state>/local/place_<name>.yml`, one list entry per official:

```yaml
- name: John B. Muns
  phones: ["(972) 941-7000"]
  emails: ["mayor@plano.gov"]
  office:
    name: Mayor
    division_ocdid: ocd-division/country:us/state:tx/place:plano
  image: null          # original municipal URL
  cdn_image: null      # their CDN copy
  source_urls: [...]
  updated_at: '2026-03-27T21:19:29+00:00'
  id: bea7c6b2-...
```

Both `image` and `cdn_image` are preserved, so headshots can still be re-fetched from the source
municipality even if `cdn.civicpatch.org` disappears.

## What was deliberately left out

`data_source/` — 2,781 `workflow_context.json` files, **188 MB, 89% of the clone by size**. These are
the scraper's LLM pipeline internals (page content, per-LLM merge and review steps), not provenance.
The provenance the importer relies on (`source_urls`, `updated_at`) is in the YAML. Excluding it is
what turns a 211 MB clone into a 1.67 MB committed artifact.

Images are also not here: ~9,094 records carry one, on the order of 200–250 MB. Those belong in a
Supabase Storage bucket and are pulled per import batch, never hotlinked.

## Reading it honestly

- **Freshness is bimodal — gate per row on `updated_at`, never trust the dataset as a whole.**
  TX and MI are current; CO (0/120) and WA (1/196) are not. Every CA row is ~12 months old.
- **Only ~13.6% of records identify a seat.** The rest are place-level "Council Member" with no seat
  identity and **cannot be seated** into `office_id → districts.geo_id` address search.
- **~470 of the records have been human-reviewed.** The rest is unreviewed scraper output. It is a
  backfill for gaps, not a source of truth that displaces ours.
