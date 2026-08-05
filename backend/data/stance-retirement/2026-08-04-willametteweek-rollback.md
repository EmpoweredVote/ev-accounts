# Retirement record — willametteweek.com fabricated articles (migration 1558)

**57 rows across 12 politicians retired 2026-08-04, operator-approved.**
Every row was sole-sourced to one of five `willametteweek.com/news/2024/10/30/...-candidates-answer-our-questions/`
URLs that never existed. Full verbatim rows — value, reasoning, sources — are in the companion `.json`.

## Why this is a retirement and not a re-point

`willametteweek.com` is WW's **genuine former domain** (archived from 1998, 301-redirecting to
wweek.com through 2020), so the earlier "composed hostname" framing was wrong. But the cited
**articles** never existed — zero captures of `answer-our-questions` anywhere on wweek.com, all five
paths 404 at the live domain — and, decisively, **the claimed topics are absent from WW's real
coverage**: the genuine Oct-16-2024 endorsements for D1-D4 and mayor contain zero mentions of
immigration, sanctuary, ICE, rent control, zoning, vouchers, or the phrase "affordable housing".
Those are exactly what these rows assert. No re-point can support them.

## Blast radius

| politician | answers before | retired | after |
|---|---|---|---|
| Angelita Morillo | 5 | 5 | 0 **(zero)** |
| Candace Avalos | 7 | 7 | 0 **(zero)** |
| Dan Ryan | 9 | 3 | 6 |
| Elana Pirtle-Guiney | 5 | 5 | 0 **(zero)** |
| Eric Zimmerman | 4 | 4 | 0 **(zero)** |
| Jamie Dunphy | 4 | 4 | 0 **(zero)** |
| Keith Wilson | 10 | 5 | 5 |
| Loretta Smith | 5 | 3 | 2 |
| Mitch Green | 4 | 4 | 0 **(zero)** |
| Sameer Kanal | 5 | 5 | 0 **(zero)** |
| Steve Novick | 9 | 7 | 2 |
| Tiffany Koyama Lane | 5 | 5 | 0 **(zero)** |

**8 of 12 politicians drop to zero answers**, so `last_stances_researched_at` is nulled
for exactly those (the 1494/1507/1508 rule: a timestamp with zero answers asserts research that no
longer exists). The other politicians keep surviving rows and their timestamps are untouched.

## Owed

Portland is queued as a re-research cluster — see `data/stance-research/reresearch-portland/QUEUE.md`.