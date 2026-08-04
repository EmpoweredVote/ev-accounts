# CivicPatch: six-day snapshot diff + partner-meeting brief

**Measured 2026-08-04.** Fresh clone `10f8398b` (2026-08-04) diffed against our vendored snapshot
`928579c0` (2026-07-29), plus live SQL against prod. Companion to
[`2026-07-30-civicpatch-api-decision.md`](2026-07-30-civicpatch-api-decision.md).

Method: shallow blobless sparse clone (`data/` only), both trees parsed with `js-yaml` — **not**
grepped. That distinction matters; see the correction below.

---

## What the first import actually delivered

| | |
|---|---|
| Office contacts live in prod, `source = 'civicpatch:928579c0'` | **293** (252 email, 205 phone, 277 url) |
| Share of every `contact_type='office'` row we hold (1,035) | **28%** |
| Headshots offered / accepted | 10 / **1** (migration 1506) |
| Migrations | 1503 (145 TX+MA), 1504 (136 CA), 1505 (12 adjudicated), 1506 (1 image) — all on `origin/master` |

Contacts were our thinnest field and their richest. That remains the case for the relationship.

## Snapshot integrity

The vendored archive is **intact** — `gzip -t` clean, 3,258 files, sha256 matches `MANIFEST.json`.
(A first `tar -xzf` attempt failed spuriously on this Windows shell; `gzip -dc | tar -xf -` extracts
correctly. Not a data problem.)

## 🔴 Correction: the "1,203-record discrepancy" was ours, not theirs

`MANIFEST.json` records `official_records: 18534` and flags a 1,203-record gap against the 19,737 the
API reported. **There is no gap.** The manifest counted `^- name:`, but 1,203 records list `id`
before `name`, so those list items were missed:

```
^- name:        18,534      ^- (any list item)  19,737      ^  name: (name not first key)  1,203
```

18,534 + 1,203 = 19,737. A YAML parse of the same vendored tree yields **19,737** — exactly what
their API served. Their API and repo agree. **Do not report this to them as a defect.**

Every per-state count was undercounted the same way and is **corrected in this commit** (ca 471 was
right, but co 827→850, mi 5,211→5,233, tx 4,684→5,842). `MANIFEST.json` now records the counting
method, and the snapshot README warns against the grep.

## The six-day diff

| | 928579c0 (07-29) | 10f8398b (08-04) |
|---|---|---|
| Files | 3,258 | 3,318 (+60) |
| Records | 19,737 | 20,111 (+374) |
| Seat-identified | 13.7% | **13.7%** (2,759 / 20,111) |

**They expand; they do not refresh.** All +60 municipalities are MA (59) and NC (1). Of the 44
cities we imported from, **zero records changed** — no departures, no corrected contacts, no fixed
images. Newly covered cities we hold: **Boston (14), Lowell (11), Quincy (10), Somerville (12)** —
our overlap goes 44 → 48 places.

Per-state scrapes move as one batch, so **freshness is a property of the state, not the row** —
which invalidates the decision doc's "gate per row" advice in favour of gating per state:

| state | records | seat% | median scrape | age |
|---|---|---|---|---|
| ma | 381 | 27% | 2026-07-14 | current |
| nc | 44 | 39% | 2026-07-07 | current |
| nh | 816 | 10% | 2026-06-04 | current |
| tn | 698 | 19% | 2026-05-24 | current |
| sc | 583 | 35% | 2026-05-16 | current |
| nj | 3,032 | 10% | 2026-04-25 | 3 mo |
| mi | 5,233 | 4% | 2026-04-19 | 3 mo |
| tx | 5,842 | 15% | 2026-03-28 | 4 mo |
| ca | 471 | 79% | 2025-07-17 | 🔴 12 mo |
| id | 529 | 3% | 2025-07-13 | 🔴 13 mo |
| nd | 230 | 20% | 2025-07-03 | 🔴 13 mo |
| co | 850 | 32% | 2025-06-30 | 🔴 13 mo |
| wa | 1,402 | 9% | 2025-06-23 | 🔴 13 mo |

CA was **not** re-scraped and is now ~12.5 months old. TX — where our overlap is thickest — has a
median of 2026-03-28, so the May 2026 uniform election and Frisco's June runoff are still absent:
their Frisco file names **Jeff Cheney** as mayor (scraped 2026-03-12) though **Mark Hill** was sworn
in 2026-07-07. Our matcher drops these by construction, since candidates come only from
`office_current_holder` — staleness costs MISSes, never bad writes.

## Both image defects are still live

Re-verified in the 2026-08-04 tree:

- **Van Alstyne TX — positional misbinding.** Mayor Jim Atchison has `image: null`, Angelica Peña
  (last) has `null`, and the five between them carry headshots shifted one seat. Opaque blob-token
  URLs carry no name, so no cheap guard catches it.
- **Farmersville TX — background-as-portrait.** Six officials still share one image, a Drupal style
  named `inner_background_image_4k`.

The surviving import (Cristina Todd) cited a *person-specific* page; all nine rejects cited roster
pages. **Rule for any future image batch: import only where `source_urls` resolves to a per-person
page.**

## Meeting position

Take the data, don't take a dependency — unchanged. Bring them the two live image bugs with
diagnoses and the README tier error; carry the manifest correction so we don't report a phantom.
Ask for (1) seat identity in the pipeline — the binding constraint, and CA proves it's achievable at
79% where MI sits at 4%; (2) whether refresh is on the roadmap at all; (3) a `/change_logs` key.
Propose a **recurring roster diff** rather than a data feed: disagreement between their roster and
ours is a defect detector for both sides, with no licence or quality exposure.

Phone-readable brief: https://claude.ai/code/artifact/3805276c-f848-4557-9834-1a469408a225

## Owed work

1. Contacts for the four new MA cities (47 officials, scraped mid-July) — same enrichment-only path.
2. Person-specific-URL filter for images, then re-run the image batch.
3. ~~Correct the counts in `backend/data/civicpatch/MANIFEST.json`~~ — done in this commit.
4. MI (5,233) and NJ (3,032) would be politician *creation* — needs a new approval, out of scope now.
5. Re-vendor a snapshot at `10f8398b` before importing the MA cities, so the importer keeps reading a
   local archive rather than the network. The current archive predates their MA expansion.
