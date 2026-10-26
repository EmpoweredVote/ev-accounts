# The re-research of the 131 — migration 1931

**2026-10-22.** Migration 1928 re-read the 165 blanked chairs and re-seated 34 where the cited roll
call already stated the rung. **131 remained**, needing something the existing evidence could not
give: a *new* instrument. This pass went and looked for one.

**Result: 10 re-seated, 121 still blank.**

Prior: [`MEASUREMENT.md`](MEASUREMENT.md) · [`RE-READ.md`](RE-READ.md)

---

## Method

For each member, their own **authored and coauthored bill list** was fetched from
`capitol.texas.gov` across four sessions (86R–89R) and matched against the topics they are blank on.
**~7,000 captions** were scanned across 20 verified members.

Authorship is a deliberate act of association and is distinctive **whatever the final margin was** —
which is why it can seat a rung where a vote could not.

## ⚖⚖ The yield is low, and that is the finding

**10 of 131.** For most of these members, the topics they are blank on are topics they have **never
legislated on** — they voted and did not file. The remaining 121 cannot be rescued from the Texas
legislative record at all. They need the member's own words, and most of these (topic, level) pairs
are `evidence_basis = 'record'`.

## 🔴🔴 A trap that would have corrupted this pass

**The member codes stored in our own rows are not reliable.** Of 26 taken from the cited
`capitol.texas.gov/Members/MemberInfo` URLs, **six do not resolve to the right person**: five return
HTTP 500, and one — `A1390`, recorded for **Ramon Romero Jr.** — resolves to **Sen. Taylor Rehmet**,
a different human being.

And the authored-bills report for a bad code **does not error**. It returns a clean page reading:

> *No bills have been authored.*

▶ **A wrong identifier produces a plausible empty result, indistinguishable from a member who filed
nothing.** Five members were silently reported as having no record whatsoever.

**The control that caught it:** resolve every code to a *name* and compare it with the person
expected. ⚠ And the control had its own false positive — "Terri Leo-Wilson" against the site's
"Terri Leo Wilson" failed a last-name comparison that was mine, not the data's. **Printing the
resolved name rather than a boolean is what made both visible.**

🔑 **A failed code is not an absence of evidence.** Rhetta Bowers' code is one of the six that did
not resolve — and she turns out to be the **primary author of the enacted CROWN Act**, found by
reading the bill rather than her member page. She is re-seated below.

## The 10 re-seats

**Civil Rights → rung 2 (9 rows).** Rung 2 reads *"strengthen civil rights enforcement and **address
systemic discrimination**."* The instrument is **88(R) HB 567** — *"Relating to discrimination on the
basis of hair texture or protective hairstyle associated with race"*, the **CROWN Act**, primary
author **Rhetta Bowers**, **enacted, effective 1 September 2023** — and its predecessor **87(R)
HB 392**. Adding a protected characteristic to the state's anti-discrimination law extends civil
rights enforcement. Rung 1 requires *mandating racial equity requirements in all institutions*,
which the Act does not do; rung 3 is to **maintain** current law, and the Act changes it.

| member | role |
|---|---|
| Rhetta Bowers | **primary author** |
| Toni Rose | author; also HB 725 (sexual orientation / gender identity), HB 3479 (housing, criminal history) |
| Nicole Collier | coauthor; also HB 1193 (housing, source of income), HB 1751 (sex discrimination in pay) |
| John Bryant | coauthor; also HB 1806, HB 607 |
| Barbara Gervin-Hawkins · Alma Allen | coauthor; also HB 3157 (civil rights of persons in custody) |
| Armando Martinez · Armando Walle · Oscar Longoria | coauthor |

**Climate Change → rung 5 (1 row).** **Terry Wilson**, author of **87(R) HB 4470** — *"imposing a tax
on the amount of federal renewable energy production credits received by wind electric generators"*.
A state tax recapturing a clean-energy subsidy is rung 5's subject exactly: *"End government
subsidies and mandates for clean energy."* Rung 4 is *"stay neutral … let the market choose among
all sources"*, and a tax aimed at one source is the opposite of neutral. ⚠ The bill did not pass.

## What the search refused, so the bar stays visible

- **Walle's and Martinez's abortion rows** — their filings are **postpartum Medicaid** and fertility
  reporting, not abortion. Off axis.
- **Bryant's abortion rows** — he authored HB 3000 repealing abortion prohibitions, which reaches
  rung 1's *legal and accessible at all stages* but says nothing about rung 1's **public funding**
  limb. Blank, consistent with the identical refusal in migration 1923.
- **Healthcare rows (Bryant, Longoria, Flores)** — Medicaid expansion again. **Expansion proves a
  floor, never a ceiling**, the rule migration 1928 set.
- **Collier's redistricting row** — HB 3052 concerns the apportionment *base* (off axis) and HB 3054
  establishes *"principles to govern redistricting plans enacted by the legislature"*, which accepts
  the legislature as drawer but names neither rung 3's supermajority nor rung 4's court oversight.
- **Toth's and Leo-Wilson's civil-rights rows** — their "discrimination" bills concern financial
  institutions, industries and vaccination status, not this ladder's axis.
- **Every taxes row** — property-tax relief delivered *through school finance* cuts taxes without
  scaling back services, matching neither rung 3 nor rung 4.

## Verified

| check | result |
|---|---:|
| re-seated by 1931 | **10** |
| still blank from 1926 | **121** |
| rows naming their new instrument | **10 / 10** |
| **chair-evidence gate** | ✅ **OK: all 10 name an instrument, act or vote** |
| Season 1 answers touched | **0** |

The first group in this programme to pass the gate **cleanly, with no failures**.

## ▶ Still open

- **121 rows** cannot be rescued from the legislative record. They need the member's own words — and
  most are `evidence_basis = 'record'`, so that path needs a ruling before it can be used.
- **Six member codes in our data are wrong**, including one pointing at a different legislator.
  Worth a sweep of `politician_context.sources` for `MemberInfo` URLs.
- The 67 sponsorship rows and 156 no-template rows from `MEASUREMENT.md`.
