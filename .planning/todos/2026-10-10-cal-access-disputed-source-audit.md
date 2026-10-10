# CAL-ACCESS — the 1,336 DISPUTED sources: audit and worklist

Opened 2026-10-10, after `CC_0221`/`CC_0222` closed the **confirmed** population.
Brief that deprioritised this population: `2026-10-10-cal-access-published-source-audit.md` (closed).
Result of the confirmed audit: `2026-10-10-cal-access-confirmed-518-audit-log.md`.

## 🔴 THE REFRAMING — THE HANDOFF MEASURED THE WRONG AXIS

It shelved this population on **money**: only 2 of the 1,336 carry a contribution, so adjudicating
them "changes nothing a voter sees". Both halves are true and the conclusion does not follow.

▶ **827 of the 1,336 sit on LIVE politician rows.** That is the `CC_0220` hazard — a `disputed`
source on a live officeholder is a loaded gun, because the thing that created it (a name match) is
also the thing a later pass would use to confirm it. Nothing publishes today; the exposure is the
next pass, and the next merge.

| population | sources | politicians | on LIVE rows | carry money |
|---|---|---|---|---|
| mig 1792 UNVERIFIED | 1,205 | 234 | **707** | 0 |
| `CA_0192` primarily-formed | 105 | 52 | **105** | 2 |
| `confirm-cal-access.ts`, no later note | 18 | 5 | 15 | 0 |
| `CC_0216`/`CC_0217` downgrades | 5 | 1 | 0 | 0 |
| `CC_0221` support/oppose | 3 | 3 | 0 | 0 |

## 🔴🔴 THREE PREDICATES RAN BEFORE THE TRUE ONE

Each was discarded only because rows were **read**. This is the whole method; the counts are
worthless without it.

1. **Forename test** — said 705 of 707 live-row sources "do not name the politician". **False.**
   They are surname-only local committees (`MOSS FOR SCHOOL BOARD 2014`), which `CC_0221` already
   established is normal and evidence of nothing.
2. **Surname-anywhere test** — found 100 with no surname match. **Real but incomplete.**
3. 🔴 **A surname test PASSES WHEN THE POLITICIAN'S SURNAME IS SOMEBODY ELSE'S FORENAME.** Caught
   by `CC_0223`'s own pre-verify gate, which refused to run: three on Karen **Douglas** —
   `STREHL … FOR THE ELECTION OF DOUGLAS`, `PHIMISTER FOR JUDGE, CITIZENS FOR DOUGLAS C.` Same
   shape as Paulette Francis / Francis Carbajal in `CC_0221`.

▶ **The test that holds: does the committee name START with the politician's surname?** California
committees are named `SURNAME FOR OFFICE …` or `SURNAME, COMMITTEE TO ELECT FORENAME`.

## ✅ DONE — `CC_0223`: 103 foreign committees on SEVEN LIVE rows

Not one of the 103 begins with the politician's surname; all were read; none carries money.

| live politician | n | actually belongs to | in corpus? |
|---|---|---|---|
| Francis De Leon Sanchez `e086df00` | **80** | Van de Kamp · De Vore · De Maio · De Saulnier · De Young · … | mostly no |
| Gregg Hart `21940b7c` | 8 | **Henry Stern** | ✅ live incumbent |
| Dr. Corey A. Jackson `bbd7825a` | 5 | **Thomas Umberg** | ✅ live incumbent |
| Karen Douglas `5d6cae71` | 4 | Hardcastle · Douglas Strehl ×2 · Douglas Phimister | no |
| Jasmeet Kaur Bains `539874fc` | 3 | **Maria Elena Durazo** | ✅ live incumbent |
| Steve Bennett `8c61cd23` | 2 | Valladares — **three candidates, ambiguous** | ✅ but unclear which |
| Phillip Chen `ed32efa5` | 1 | **Debra Archuleta** (LA District Attorney 2024) | ✅ live |

🔴🔴 **Sanchez's 80 came from matching the particle "DE"** — a two-letter token. Larger than Dan
O'Brien's 44 in `CC_0221`, and unlike those eight rows **this one is LIVE**.

⚠ **These rows were already partly cleaned; this was the residue.** Sanchez also carries 109
`not_applicable`, Douglas 38, Chen 10, Bains 8. **A row that has been worked is not finished.**

## ▶ STEP 2 — re-attach the 16 whose owner we hold. NOT YET DONE.

Henry Stern 8 · Thomas Umberg 5 · Maria Elena Durazo 3 (+ Debra Archuleta 1, Valladares 2 once the
right Valladares is established — Oscar, Suzette Martinez, or the bare `Valladares` netfile row).

🔴 **Attaching is a POSITIVE claim and needs POSITIVE evidence.** The committee name proves only
whose a committee is *not*. Use the candidate page, then the **Form 460 cover page Part 5** when it
is silent — all four are state politicians, so the candidate page should answer cheaply.
⚠ `politician_sources` has a UNIQUE index on (politician, source_system, external_id): check the
target does not already hold the id before repointing.

## ▶ NEXT SLICE — the 212 that carry the surname but not at the front

⚠ **Re-measured after `CC_0223` (2026-10-10): 212 on LIVE rows, not the 215 first reported** — three
Karen Douglas sources were swept into `CC_0223`. The no-surname bucket on live rows is now **0**.
⚠ **And there are 64 MORE of the same shape on INACTIVE rows**, which the first count missed:
**276 in total.** The live 212 are the priority; the inactive 64 carry the same merge hazard as
`CC_0221`'s eight duplicate rows.

For scale, the whole mig-1792 population now splits:

| | starts with surname | surname not leading | no surname |
|---|---|---|---|
| **live rows** (698) | 486 | **212** | 0 ✅ cleared by `CC_0223` |
| inactive rows (498) | 434 | **64** | 0 |

A read of 18 shows this bucket is **mostly foreign too**, and the matcher's reach is wider than
surnames — it hit **place names and common nouns**:

```
PRINCE FOR SAN GABRIEL VALLEY MUNICIPAL WATER DISTRICT  -> Jesse GABRIEL
NELSON FOR VILLA PARK CITY COUNCIL                      -> Traci PARK
RYU … GRIFFITH PARK FRIENDS SUPPORTING DAVID            -> Traci PARK
HENDRICKSON KING CITY COUNCIL 2012                      -> John KING  (King City, Monterey)
RESNICK FOR PERALTA COMMUNITY COLLEGE BOARD             -> Scarlet PERALTA
VOTE FOR PARKS  /  CALIFORNIANS FOR SAFE PARKS (Prop 12) -> Grant PARKS
CONWELL, DEVINCENZI, KERR & MAHER FOR SCHOOL BOARD      -> Megan KERR  (a slate, a different Kerr)
EDUCATION LEADERS SUPPORT ANTHONY PORTANTINO            -> Konstantine ANTHONY (his forename)
```

🔴 **But roughly one in five IS a genuine support/oppose committee naming the right person** —
`PRICE FOR MAYOR 2022 AND OPPOSING REX RICHARDSON`, `HALL, RASKIN, SNELL, ZERNITSKAYA, AND AGAINST
BROCK FOR CITY COUNCIL 2024`, `PETERS, COMMITTEE TO RECALL SCOTT`. **Those must NOT be detached.**
They are correctly withheld and blocked on the same question as `CC_0221`'s three and the Newsom
recall committee: **how outside spending renders support vs oppose.**

▶ **This bucket needs reading row by row. A predicate cannot separate "foreign" from "about them,
but against them".**

## Left alone, deliberately

- **486 live-row sources whose committee DOES start with the surname** — plausible, unverified, $0.
  Verifying them means ~486 Form 460 fetches for no voter-visible change.
- **498 mig-1792 sources on inactive rows** — same shape, lower stakes, no live twin exposure.
- **The `CA_0192` 105 primarily-formed committees.** All on live rows, but only 2 carry money and
  those two are the blocked ones. Retyping the other 103 `ie_committee` would publish nothing,
  because their money was never ingested.
- 🔴 **The two disputed sources that DO carry money, both on LIVE rows, both blocked on the
  support/oppose question:** `1448127` Gipson ($194,000) and `1418587` the Newsom recall committee
  ($33,172.80).

## The single blocker worth naming — now an ADR

**`OutsideSpendingCommittee` has no support/oppose field.** Five committees across `CC_0221`, this
audit and the closed brief are all waiting on that one schema-plus-read-path decision. Until it
exists, `disputed` is the honest state: publishing a recall committee under a heading that does not
say "opposing" is its own false statement about a real person.

▶ **Written up as [`docs/adr/0008-outside-spending-support-or-oppose.md`](../../docs/adr/0008-outside-spending-support-or-oppose.md)
(status: proposed, 2026-10-10).** It records that **all three currently-published outside-spending
committees are support by the luck of their names, not by evidence** — so the first oppose committee
anyone types publishes silently as the politician's own backing. The decision is a nullable
`support_oppose` that the read path **requires**, because there is no safe default.
