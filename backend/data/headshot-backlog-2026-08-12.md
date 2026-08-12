# headshot-backlog-2026-08-12.csv

**1,545 currently-seated officials with no portrait we can render.** Generated 2026-08-12 against
production, read-only. Companion to `photo-origin-breadcrumbs-2026-08-11.json`, which this file
joins against — see *Already searched* below.

A CSV cannot carry its own provenance the way that JSON file does, so it lives here instead.

## What changed since the 2026-08-11 file

That file listed 2,502 rows and **41% of them were candidates, not officeholders** — it excluded the
discovery pool by *source string*, which caught CalAccess and missed Indiana entirely. Migration
1702 replaced that with a structural test and this file uses it (see *Scope*). Combined with the
292 portraits imported off the first list, the by-state picture moved a lot:

| state | 2026-08-11 | 2026-08-12 | why |
|---|---|---|---|
| CA | 1,060 | **1,013** | 47 portraits imported (mig 1709); 277 candidates removed |
| IN | 810 | **140** | 674 were discovered candidates; 6 portraits (mig 1703) |
| TX | 215 | **56** | 158 portraits imported (mig 1699) |
| UT | 166 | **90** | 76 portraits imported (mig 1706) |
| MA | 118 | **113** | 5 portraits imported (mig 1708) |
| WI · ME · OR · NV | 132 | **132** | untouched |

Indiana is the one to notice: it looked like the second-largest backlog in the country and was
really the fourth-smallest of the states listed.

## What "missing" means

`HAS_RENDERABLE_PHOTO_SQL` from `backend/src/lib/photoCoverage.ts`, copied verbatim rather than
re-invented so this list cannot disagree with the platform's own coverage numbers:

```sql
(    img.politician_id IS NOT NULL
  OR btrim(coalesce(p.photo_custom_url, '')) <> ''
  OR (btrim(coalesce(p.photo_origin_url, '')) <> '' AND p.photo_origin_url LIKE 'http%') )
```

Rows in this file are the ones where that predicate is **false**. Do not substitute
`photo_origin_url IS NOT NULL` — that column doubles as a research scratchpad, which is the defect
migration 1688 fixed. It measures "could render", not "is definitely a face": 2,604 rows platform-wide
hold a real URL pointing at a roster page rather than a portrait, and those are counted as present
here because they cannot be told apart from working portraits without a per-row content-type fetch.

## Scope

Included: holds a seat by **either** occupancy link, not vacant, portrait not renderable.

Excluded: **placeholder occupancy**, via migration 1702's view — the test the previous file got
wrong:

```sql
AND NOT EXISTS (SELECT 1 FROM essentials.politician_occupancy_evidence e
                WHERE e.politician_id = p.id AND e.is_placeholder_occupancy)
```

Of the 83,291 rows in the current-holder view only ~5,476 rest on more than a placeholder; the rest
are open-ended, precision-unknown terms written by the ADR 0002 phase-2 backfill (migration 1459)
onto offices with no district, chamber or city. They are real people seeded from candidate-committee
filings (`backend/scripts/discover-indiana-candidates.ts` and the CalAccess equivalent) — legitimate
records with real provenance, and **never to be deleted**. They are simply not officeholders, so
they are not a portrait worklist.

🔴 **Do not test on `has_candidate_committee`.** Every incumbent seeking re-election has one —
Lindsey Graham, Bill Keating, Nanette Díaz Barragán, David Brock Smith and James Talarico all do,
and all hold real seats. The discriminator is **structural**: a real seat carries geography
(district, chamber or city); a discovery placeholder carries none. That column exists on the view as
information only, and 1702's post-verify gate names those five people specifically because an
earlier draft flagged them.

## Jurisdiction is resolved three ways, in this order

1. current `office_terms` → office → chamber → government  (ADR 0002, the modern link)
2. legacy `politicians.office_id` → office → chamber → government
3. `offices.representing_state` / `representing_city`

All three are load-bearing, and the `jurisdiction_from` column records which one answered:

- Step 1 alone misses everyone seeded before ADR 0002.
- Step 2 alone misses everyone seeded after it — that is the bug that had the volunteer briefing's
  map showing Wisconsin at 5 researched officials when it has 208.
- Step 3: **93% of offices (77,680 of 83,291) have `chamber_id` NULL** and keep their jurisdiction
  on the office row. A first cut of the previous file used steps 1–2 only and silently dropped
  **1,164 officials**.

In this file: 1,059 rows resolved by government, 486 by `representing_state`, and exactly 1 not at
all. Note that step 3 and the placeholder exclusion pull in opposite directions — step 3 recovers
real officials whose office carries no chamber, while the exclusion removes placeholders that step 3
would otherwise sweep in. The briefing map needed both, in that order, on consecutive days.

## Columns

| column | notes |
|---|---|
| `state` | resolved as above; blank for federal offices |
| `jurisdiction` | government name, or `representing_city` when there is no government row |
| `chamber`, `office` | blank chamber means the office carries no `chamber_id` |
| `stances` | researched stance count — **> 0 means a live profile page with a placeholder where a face should be** |
| `already_searched` | the breadcrumb migration 1688 cleared for this politician |
| `seat_link` | `current term` or `legacy office_id` |
| `jurisdiction_from` | `government`, `representing_state`, or `UNRESOLVED` |
| `official_urls` | the politician's own URLs, useful as a first place to look |
| `politician_id` | UUID, for feeding an import |

Sorted so the **57** with researched stances come first; those are the highest-value fixes because
they already have live pages. That number was 216 in the previous file — the difference is almost
entirely candidates who carried researched stances and are no longer counted as officeholders.

## Already searched — 137 rows

These carry a breadcrumb (`searched:no_results`, `explored`) from an earlier portrait sweep, cleared
from `photo_origin_url` by migration 1688 and preserved in the JSON beside this file. Somebody has
already looked and come up empty. Per that migration's own note the breadcrumbs are undated and
their method is unknown, so treat them as **a reading queue, not proof no portrait exists** — but
don't spend the first pass on them.

## By state

| state | missing | of those, researched |
|---|---|---|
| CA | 1,013 | 0 |
| IN | 140 | 0 |
| MA | 113 | 37 |
| UT | 90 | 0 |
| WI | 58 | 17 |
| TX | 56 | 2 |
| ME | 54 | 0 |
| OR | 16 | 0 |
| NV | 4 | 0 |
| federal / unresolved | 1 | 1 |

## Regenerating

No script was added for this. The query is small enough to keep here, and pinning it to the
`photoCoverage.ts` predicate above matters more than automating it — if that predicate changes,
this file is stale regardless.

```sql
WITH cur_term AS (
  SELECT DISTINCT ON (ot.politician_id) ot.politician_id AS pid, ot.office_id
  FROM essentials.office_terms ot
  WHERE ot.term_end IS NULL OR ot.term_end >= current_date
  ORDER BY ot.politician_id, ot.term_start DESC NULLS LAST
)
SELECT p.id, p.full_name, p.party_short_name,
       upper(btrim(coalesce(g.state, o.representing_state, ''))) AS state,
       coalesce(g.name, nullif(btrim(coalesce(o.representing_city,'')),''), '') AS jurisdiction,
       ch.name AS chamber, o.title AS office,
       CASE WHEN t.pid IS NOT NULL THEN 'current term' ELSE 'legacy office_id' END AS seat_link,
       coalesce(pa.n, 0) AS stances, p.urls
FROM essentials.politicians p
LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
LEFT JOIN cur_term t ON t.pid = p.id
LEFT JOIN essentials.offices o   ON o.id  = coalesce(t.office_id, p.office_id)
LEFT JOIN essentials.chambers ch ON ch.id = o.chamber_id
LEFT JOIN essentials.governments g ON g.id = ch.government_id
LEFT JOIN (SELECT politician_id, count(*) n FROM inform.politician_answers GROUP BY 1) pa
       ON pa.politician_id = p.id
WHERE NOT ( img.politician_id IS NOT NULL
            OR btrim(coalesce(p.photo_custom_url,'')) <> ''
            OR (btrim(coalesce(p.photo_origin_url,'')) <> '' AND p.photo_origin_url LIKE 'http%') )
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_occupancy_evidence e
                  WHERE e.politician_id = p.id AND e.is_placeholder_occupancy)
  AND coalesce(p.is_vacant,false) = false
  AND coalesce(o.is_vacant,false) = false
  AND (t.pid IS NOT NULL OR p.office_id IS NOT NULL)
ORDER BY (coalesce(pa.n,0) > 0) DESC, 4, 5, 2;
```

**Two sanity checks before trusting a regenerated file.** Count seated officials *with* a renderable
portrait separately and confirm the two add to the seated total — that is how the 1,164 dropped rows
were caught. Then spot-check that the largest state's count is plausible against its roster: the
reconciling total could not see the 957 candidates, because they were seated-looking rows on both
sides of the sum. **A total that adds up catches missing rows, not wrong ones.**
