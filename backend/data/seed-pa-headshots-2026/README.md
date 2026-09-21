# PA-5 headshot provenance

What the Pennsylvania portraits were built from, kept for the same reason
`seed-mn-headshots-2026/` keeps its candidate files: **the images are live, and this is the only
record of where each one came from and what was approved.**

Applied to production 2026-09-19 (legislature) and 2026-09-20 (Sheriff). Nothing here is an input
to a future run — these are receipts.

| File | What it is |
| --- | --- |
| `candidates-legislature.json` | 253 rows, one per seat, as `build-pa-legislature-candidates.py` produced them. 252 carry a `url`; Brandon Dukes (HD-12) does not. |
| `contact-sheet-manifest.json` | **What Cantrell actually approved on 2026-09-19** — `rendered` (252) with the `upscale` and source dimensions each frame was drawn at, and `missing` (1). |
| `candidates-sheriff.json` | The Philadelphia Sheriff, added 2026-09-20. One row. |
| `PHILADELPHIA-PERMISSION-REQUEST.md` | The seven seats we have **no** right to crop, and the request that would change that. Drafted, not sent. |

## The fields worth understanding

- **`identity_mad`** — mean absolute difference between the **unlinked full-size original** and the
  member's own linked thumbnail, both downscaled to a common size. It is how we proved an unlinked
  bucket holds the same photograph rather than a mis-keyed one. Median **1.96**, worst **13.17**
  (Doug Mastriano), reject threshold 18.
  🔴 **It proves "same shot, another size" and NOTHING MORE.** Two different photographs of the same
  person score like two different people — the Sheriff's 2022 and 2026 headshots scored **87.52**.
  Identity across different photographs needs a page that names the person.
- **`upscale`** — the factor needed to reach 600x750. Anything above 1.0 was **stored at native
  cropped size instead**, never enlarged. 217 of 252 landed at the full 600x750; 35 did not, and
  those 35 are exactly the amber-ringed frames on the approval sheet.
- **`license`** — the licence position for that publisher, written at the time it was read. The
  `phillysheriff.com` line was **corrected on 2026-09-20**: the site does publish terms, they
  reserve rights without prohibiting reproduction or modification, and the earlier note saying "no
  site terms" was never true. See the permission request for the full reading.

## What is NOT here, and why

- **`.tmp-headshot-cache/`** (542 MB) — the downloaded source bytes. Its job was to make what
  shipped identical to what was approved; the shipped objects are on our CDN and were verified by
  decode, so the cache's job is done. Re-downloadable from the same URLs, which are in these files.
- **`.tmp-tiger-2024-42/`** (15 MB) — the Census TIGER 2024 Pennsylvania legislative shapefiles used
  by PA-1. Public downloads, re-fetchable from the Census.

## Verifying any of this again

```bash
py scripts/verify-imported-headshots.py \
    --json data/seed-pa-headshots-2026/candidates-legislature.json --expect 252
```

It refetches every row from the CDN and **fully decodes** it, runs a bogus-key control that must
fail, and **asserts the count**. The count is the part that matters: MN-6 shipped a verifier that
reported "0 broken" while testing none of the 133 rows just written.
