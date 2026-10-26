# Five wrong Texas member codes — migration 1933

**2026-10-22.** Found while re-researching the blanked stance rows (migration 1931). Five of the
`capitol.texas.gov/Members/MemberInfo.aspx?...Code=` URLs in `politician_context.sources` do not
resolve to the politician whose row cites them.

🔴 **One resolves to a different sitting legislator**: `A1390`, cited on Ramon Romero Jr.'s rows,
is **Sen. Taylor Rehmet**. The other four return HTTP 500 and name nobody.

| person | stored | correct | verified as |
|---|---|---|---|
| Rhetta Bowers | A1442 | **A3565** | "Rhetta Bowers", District 113 |
| Philip Cortez | A1432 | **A2365** | "Philip Cortez", District 117 |
| Ray Lopez | A1424 | **A3915** | "Ray Lopez", District 125 |
| Ramon Romero Jr. | A1390 | **A3060** | "Ramon Romero, Jr.", District 90 |
| Rafael Anchía | A1290 | **A2150** | "Rafael Anchía", District 103 |

Each correction was verified by fetching the **new** URL and reading the name *and district* it
returns — not by trusting a member-list scrape. ⚠ There are two Lopezes; `A4295` is Janie Lopez.

## 🔴🔴 Why this was invisible

A wrong member code **does not error** on the reports it feeds. The authored-bills report for a bad
code returns a clean page reading *"No bills have been authored."* During migration 1931 that
silently reported five legislators as having filed nothing at all — a plausible empty result,
indistinguishable from the truth.

**The control that caught it:** resolve each code to a *name* and compare it with the person
expected.

## ⚠ The control had two false positives, both mine, both name-matching

- **`A3455` (Terry Meza) was reported bad and is CORRECT** — the page reads `Rep. Thresa "Terry"
  Meza`, District 105, and the quoted nickname defeated the comparison.
- **`A4290` (Terri Leo-Wilson)** likewise — the site writes "Terri Leo Wilson" without the hyphen.

▶ So the headline **"six bad codes" was wrong; it is five.** A name comparison is a detector like
any other and needed its own control. Printing the resolved name and district, rather than a
boolean, is what exposed both the real errors and the false ones.

## Scope: open season only

The first attempt tried to fix both seasons on the reasoning that a source URL is not an answer.
**The database disagreed**, and it is right: an UPDATE on a closed season's `politician_context`
raises `CLOSED_SEASON_IMMUTABLE` (ADR 0005 §1.6). There is an explicit escape
(`SET LOCAL inform.allow_closed_season_write = 'on'`), deliberately requiring a stated reason.

**21 Season 2 citations fixed. 25 Season 1 citations still point at the wrong page**, six of them at
Taylor Rehmet. Overriding a database-level history guard is an operator's decision, not this pass's.

## ⚠ Two guards in this migration were wrong before they were right

Both read the **whole table** instead of the rows the pass touched:

1. An empty-sources check counted **466 pre-existing source-less rows** corpus-wide and failed.
2. An "answers must not move" check counted **2 answers another session had just written**, and
   failed a migration that touches no answer at all.

Both were true statements about the database that said nothing about this transaction. **A guard
that reads beyond its own blast radius reports the world, not the work.**
