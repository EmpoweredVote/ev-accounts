# Characterisation rows (`NO_QUOTE`) — hand review, in progress

Cohort regenerated after 1521: **78 characterisation rows across 52 sites** (not the "85" quoted
earlier — that predated the `<main>` extractor fix and the 1520/1521 retirements). All 52 sites are
readable. Evidence: [`2026-08-01-topic-evidence.md`](2026-08-01-topic-evidence.md), produced by
`probe-topic-evidence.mjs`, which searches each page with a lexicon built from the **compass topic**
rather than from the row's own wording.

**Read so far: 13 of 78. Retirement candidates: 1.**

## How these rows are being triaged

Two cheap signals pick out the rows worth reading first, and neither is a verdict:

1. **No topic passage on the site at all** — 5 rows.
2. **The row asserts a NAMED thing (committee, court case, bill, place) that is absent from the page**
   — 11 rows. A named instrument is a rare token, so its absence is real evidence about *that
   sentence*, exactly as the bill-number test was for Oregon.

Everything else is a bulk editorial read, and the sampling so far says it is majority-correct.

## ✅ Group 1 — the 5 rows with no topic passage found

| row | finding | verdict |
|---|---|---|
| **Tim Greimel / Medicare-aid** (mi) | Page: *"worked across party lines to establish Healthy Michigan, providing access to affordable health insurance for over 650,000 Michiganders."* Healthy Michigan **is** Michigan's Medicaid expansion; the row supplies that link from outside knowledge, and it is correct. | **KEEP** — chair 2 also bundles "lower Medicare age to 55", which is unevidenced; that is a chair-granularity issue, not a citation failure |
| **Chris Chaffee / Taxes** (md) | Page: *"suspending the fuel tax for 30 days"* and *"No legislators should be paid if the budget isn't balanced"*. Row describes both accurately. | **KEEP** — though chair 4 ("cut taxes for everyone and scale back public services") is strong for a 30-day fuel-tax holiday |
| **Amy Donahue / Abortion** (—) | Page: *"codifying healthcare for all (which must include reproductive health)"* — quoted accurately. Chair 1 (legal, accessible, **publicly funded at all stages**) is inferred; the row's own text concedes it states no gestational limits. ⚠ The site describes itself as *"a placeholder collection page"*. | **KEEP, value questionable** |
| **John Nagel / Taxes** (mn) | Page: *"President Trump's Big Beautiful Bill brought real relief to hardworking Americans, and in Congress, I will fight to end Washington's reckless spending"*. The row renders this as *"tax relief"* — **the word "tax" does not appear on the site**. The BBB is genuinely a tax law, so the position is real. | **REASONING FIX** — say "real relief", not "tax relief" |
| **Kyle Kirkland / Fossil Fuels** (—) | Page's only related line: *"Kyle will end over-regulation, restart domestic production, and attack the cost-of-living crisis head-on"*, under a cost-of-living heading. **No occurrence of energy, drilling, oil, permits or fossil fuel anywhere.** Chair 4 is "expand fossil fuel drilling permits". | 🔴 **RETIREMENT CANDIDATE** — a generic deregulation line is not a drilling-permits position |

## ✅ Group 2 — the 8 rows asserting a named thing absent from the page

**Four were fine; four assert one unsourced specific on top of a well-supported claim.** None is a
retirement — in every case the *topic* is genuinely on the page and only the ornament is invented.

| row | the named thing | verdict |
|---|---|---|
| **Ericka Kopp / Campaign Finance** | `#WeThePeopleAmendment` **is on the page** (under Pledges); "Citizens United" is absent, but the row attributes that to the amendment, not the site — and accurately. Page also has *"not with lobbyists or corporate donors"*. | **KEEP** |
| **Gene Rechtzigel / Religious Freedom** | *"Engel v. Vitale (1962) and Abington School District v. Schempp (1963)"* — **verbatim on the page**, in a passage calling to "destroy the decisions". | **KEEP** |
| **Charles H. Schmidt / Healthcare** | "ACA" absent but *"Ensure healthcare subsidies for Medicaid and marketplace"* is present — the marketplace **is** the ACA. | **KEEP** |
| **Mark Henderson / Homelessness** | Both present: *"a continuous and supportive advocate for combating homelessness and Veterans' concerns in Los Angeles County"*, on a Gardena council site. | **KEEP** |
| **Caroline Fairly / Religious Freedom** | "Select Committee on Civil Discourse and Freedom of Speech in Higher Education" — **absent**. Religious-freedom content is strong: *"Freedom is non-negotiable, specifically when it comes to our right to practice our religion"*. | **REASONING FIX** — drop the committee claim |
| **Andy Hopper / Religious Freedom** | "Ten Commandments" — **absent**. Content is strong: *"Preserve Faith and Freedom. God—not government—is sovereign. Texans must always be free to pray, speak, and live according to their faith without government interference."* | **REASONING FIX** |
| **Phil M. Hernandez / Childcare** | "Child Tax Credit" — **absent**. Present instead: *"improve access to the Child Care Subsidy Program"* and lowering costs "in the areas of housing… and childcare". | **REASONING FIX** |
| **Lana Negrete / Public Safety** | "Santa Monica Pier" — **absent**. Present: *"the safe and clean task force (Santa Monica Police, Public Works, Fire, and Code Departments)"*. ⚠ Her page is only 2,911 chars on one page — check for a JS shell before acting. | **REASONING FIX** |

## Running tally

| verdict | rows |
|---|---|
| keep — correctly sourced | 8 |
| reasoning fix — drop one unsourced specific, keep the row | 5 |
| retirement candidate | **1** (Kirkland / Fossil Fuels) |
| **read so far** | **13 / 78** |

🔴 **Same shape as every other batch on this workstream.** The rows selected *because they looked
worst* came back 8 keep / 5 trim / 1 retire. Do not extrapolate a failure rate from the risk-ranked
head of a queue — the 65 unread rows were not flagged by either signal and should be expected to be
cleaner still, not dirtier.

## What is left, and how to work it

- **65 rows unread.** No named-instrument claim and at least one topic passage on the page.
- Work them **site by site** from `2026-08-01-topic-evidence.md` — 15 sites carry 2+ rows (Kopp alone
  has 7, and 5 of her 7 verify directly against her policy list: Social Security income cap, ending
  Dobbs, Obergefell, universal healthcare, LGBTQ+ protections).
- The likely output is a **reasoning-correction migration** in the 1518 shape, not retirements.
- ⚠ Check `lananegrete.com` and any other single-page site under ~3k chars for a client-rendered shell
  before drawing conclusions — a thin body is not an absent claim.
