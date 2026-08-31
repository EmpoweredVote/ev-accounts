# FL state legislators are HOTLINKED, not mirrored — 155 of 159

**Found:** 2026-08-30, immediately after FL-7 closed Florida's stage 5.
**Status:** open. Two tasks below, in order.

## The finding

Florida's 159 seated **state** officials all read as photo-covered. They are not covered the same way
the 72 local and county officials are:

| How they are covered | Count |
| --- | --- |
| Real `essentials.politician_images` row, mirrored into our Supabase bucket | **4** |
| `photo_origin_url` only — a raw hotlink to a third-party host | **155** |

🔴 **`HAS_RENDERABLE_PHOTO_SQL` counts anything `LIKE 'http%'`, so a DEAD LINK STILL READS AS
COVERAGE.** The predicate lives once, in `backend/src/lib/photoCoverage.ts` — do not re-inline it.

⚠ **`photo_origin_url` is meant to be the SOURCE PAGE (provenance).** `politician_images.url` is the
thing that renders. Putting a raw image URL in the origin field works by accident, and that accident
is what makes the coverage number lie. `scripts/import-headshot-candidates.py` documents this in its
own module docstring, and cites the precedent: **seven Colorado portraits silently became 404s.**

So Florida's two halves are in different states:

- **72 local/county (FL-7)** — fetched, cropped to 600×750, stored in OUR bucket. Source can vanish.
- **155 state legislators (FL-2)** — hotlinked. A chamber redesign 404s them and nothing notices.

## Task 1 — measure how bad it already is

```bash
cd /c/EV-Accounts/backend && set -a && . ./.env && set +a && node scripts/verify-photo-origin-urls.mjs
```

Scope the report to Florida state rows. Report **how many of the 155 are already dead**, not a
percentage of attempted. Do not treat HTTP 200 as proof — a WAF page arrives as 200; check the magic
number, or better, that the bytes decode.

## Task 2 — re-import them properly

Bring the 155 up to the standard the local half now meets: fetch, crop, mirror into storage, and give
each a real `politician_images` row.

**The tooling is already there and was hardened during FL-7:**

- `backend/scripts/headshot_crop.py` — the 4:5 crop, in ONE place, imported by both the proof-sheet
  renderer and the importer so they cannot drift. Supports a per-row `"crop"` override
  (`anchor_x`, `anchor_y`, `zoom`, `bbox`) for subjects the centre crop gets wrong.
- `backend/scripts/render-headshot-contact-sheet.py --title … --json … --out …` — cohorts now come
  from the data, not a hardcoded list.
- `backend/scripts/import-headshot-candidates.py` — `--dry-run`, `--only`, `--exclude`.
- Both share the on-disk cache `.tmp-headshot-cache/`, so **the bytes the operator approves are the
  bytes that ship**. Delete the directory to force a refetch.

🔴 **STANDING RULES, not to be re-asked:** press/official/public-domain only; **never any social
network**; a photographer's copyright is a refusal; skip monochrome; approval is ALWAYS one batch
contact sheet published as an Artifact, never a dialog per person; report **measured yield in usable
headshots**, never files touched.

⚠ **A legislature is the easy tier.** Per spec §7, a chamber's own roster usually carries official
portraits for the whole body at one URL — one script per chamber, cloned from
`scripts/seed-wi-legislature-headshots.py`. That is a different shape from FL-7's per-person hunt.
The Florida House and Senate roster pages are the place to start, NOT a per-member search.

## Traps this cohort will hit

- 🔴 **`miami.gov` 403s every non-browser client**, and the Wayback mirror 503s under repeated
  fetches. The durable fix found in FL-7 was **an institution re-hosting the same official portrait**
  — Christine King's is on her FIU fellowship profile under the identical filename. Expect similar
  blocks on other government hosts.
- 🔴 **The import guard joins `external_id` AND `full_name`**, so a wrong id drops the row rather than
  seating a stranger. Keep it.
- 🔴 **The upscale gate measures the FACE crop, not the frame.**
- **5 of the 164 state offices are VACANT** (4 House, 1 Senate) and correctly have no holder — HD-113
  among them. Do not "fix" them.

## Related

- FL-7 wave: `docs/superpowers/plans/2026-08-30-knight-fl-wave-7-florida-assets.md`
- Slice notes: `.planning/knight-foundation/fl.md` (FL-7 section)
- Open PR with the three pipeline fixes: **ev-accounts #261**
