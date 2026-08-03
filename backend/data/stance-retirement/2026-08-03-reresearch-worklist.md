# Re-research worklist — and why clearing `last_stances_researched_at` is NOT the prerequisite

Asked before starting re-research: do we need to clear anything first? **No — and there is nothing to
clear.** But the question surfaces a real gap that clearing would not have fixed.

Worklist: `2026-08-03-reresearch-worklist.json` — **303 rows across 109 politicians**, each with its
retired chair, its retired sources, the defect class, and whether it is currently visible to any
selection surface.

| defect class | rows | migration |
|---|---|---|
| composed-citation | 209 | 1538 |
| invented-outlet | 58 | 1540 |
| pretenure | 36 | 1537 |

## Why no clearing is needed

1. **The rule was already applied.** Migrations 1507/1508 set the precedent and 1494/1525 confirm it:
   null `last_stances_researched_at` **only for politicians emptied to zero answers**, because "a
   timestamp with zero answers asserts research that no longer exists". 1538 and 1540 did exactly that
   — **39 politicians emptied, timestamps nulled, verified none still carries one.**

2. **Clearing the survivors would assert something false.** The other 70 politicians kept at least one
   row — rows that survived scrutiny. Hoyle keeps 3, Gimenez 12, Salinas 7. Nulling their timestamp
   would claim they were never researched.

3. **It is already null for all 70 of them, and it is not a queue anyway.** Corpus-wide the column is
   set on **281 of 85,139 politicians (0.33%)**. Both coverage services deliberately ignore it, and the
   code says why: *"unstamped for bulk-loaded states (CA/OR have 0 stamped despite 228/108 with
   answers), so it badly under-reported stance coverage."* They define **researched = has ≥1 compass
   answer**.

## 🔴 The actual gap: 174 topics are invisible

Because "researched" means "has ≥1 answer", a politician who lost some rows but kept others reads as
**done**:

| | politicians | topics owed | visible to selection? |
|---|---|---|---|
| **EMPTIED_VISIBLE** | 39 | 129 | ✅ 0 answers, so they read as unresearched |
| **PARTIAL_INVISIBLE** | **70** | **174** | 🔴 **no — they kept ≥1 answer** |

Val Hoyle reads as researched on 3 surviving rows while owing 17. Nothing in the codebase computes
per-(politician, topic) coverage, so no timestamp change surfaces these — **the worklist has to be the
input to re-research, not a coverage query.**

⚠ Do not fix this by clearing the 70. Fix it by driving from the worklist, or by adding a per-topic gap
surface if this recurs.

## 🔴 Re-research must NOT return to the original sources

Migration 1508 states the rule: *"Re-research must NOT use Ballotpedia bios — these rows failed
precisely because those pages carry no position content."* Applied per class here:

- **invented-outlet (58)** — the cited outlets do not exist (`medfordmirror.com`,
  `newtonvillearea.com`, `alhambraource.com`, `walthamtribunenews.com`, `walthamatch.com`). There is
  nothing to return to. ⚠ And the *other* citations on those rows were fetched and are mostly dead too:
  46 HTTP 404, 4 unreachable, 7 readable but never naming the politician. Replacement must be genuinely
  new — council minutes, `malegislature.gov`, working local-government pages.
- **composed-citation (209)** — same shape: the URLs never existed. ⚠ The four thin hosts
  (`lynnma.gov`, `alhambraca.gov`, `carsonca.gov`, `medfordma.org`) are a real Wayback coverage gap
  rather than composed, so a citation there may be recoverable; everything else needs a new source.
- **pretenure (36)** — different failure, different fix. The source was often **correct** (two rows
  cited the genuine TCJA roll call); the defect was attributing a chamber's vote to someone not in the
  chamber. Re-research needs a **membership check against the roll call itself**, and for Hoyle,
  Salinas, Kamlager-Dove and Van Epps their real votes exist for their actual terms — the votes are
  findable, just not the ones that were claimed.

## Also owed, tracked elsewhere

- **183 rows** the fetch pass confirmed unreachable (`2026-08-02-undecidable-fetch.md`) — measured, not
  yet dispositioned.
- **5 citations** on the three weak-evidence campaign hosts; `octavioforwhittier.com`'s 2 rows are
  sole-sourced and should go first.
- **511 stripped rows** are NOT in this worklist: they kept a working citation and their chair stands.
  They are a lower-priority sourcing-quality queue, not a coverage gap.
