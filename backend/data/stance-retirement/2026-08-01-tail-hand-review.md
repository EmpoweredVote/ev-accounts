# Tail cohort hand-review — 19 retire candidates, 2026-08-01

> **OUTCOME (migrations 1516 + 1517 applied).** Reading each row individually shrank the actionable set
> again — from the 17 this document first proposed to **9**. Group A was over-counted: 6 of its 10 needed
> no change at all, because **the detector cannot tell a chair name in quotation marks from a source
> quotation**. Cottam's three rows each say *"matching the `'partially privatize Medicare'` chair"* —
> correctly attributed by the researcher, unparseable by the tool. Cliff Johnson, Zabel and Milleron
> were simply accurate (Milleron's page does say *"I will fight to make health care accessible to all"*).
>
> | applied | rows | |
> |---|---|---|
> | **1516** corrections | 4 | Miller-Watkins + Baucom (quote fixes), Bryan/Housing (unsourced quote removed, AB 1685 added), Werner (SB1729 added) |
> | **1517** retirements | 5 | 3 self-declared inference rows + Mitchell/Redistricting + Harding/Taxes |
> | no change needed | 8 | Cottam ×3, Cliff Johnson, Zabel, Milleron, Lavigne, Keohokalole (deferred) |
>
> Two findings that reversed this document's own conclusions:
>
> - **Lavigne is supported, not a re-point.** His survey reads *"Lower taxes, lower energy costs, No boys
>   in Girls sports or locker rooms or restrooms."* Identical position to the row's; the audit missed it
>   because the row's terms were *transgender* / *athletes* / *LD 1134* and the page uses none of them.
> - **Harding is a retirement, not a keep.** His page contains no tax-cut pledge — *cut taxes*, *lower
>   taxes*, *tax relief*, *reduce taxes*, *tax cut* are ALL absent. "Cut taxes" was inserted into a
>   pledge about eliminating wasteful spending, and stance 4 rested entirely on the inserted words.
>
> 🔴 **Keohokalole deferred, deliberately.** HI HB489 (2015) is real and its mechanism matches exactly,
> but his name appears **nowhere** in the measure's 53,000-character status page and the bill's
> INTRODUCED BY line is a blank signature placeholder. Citing it would lend the row false authority.
>
> The removed Bryan quotation turned out to be **real and correctly sourced elsewhere** — his
> *Homelessness* row cites a LinkedIn post whose URL slug is `the-solution-to-homelessness-is-housing`.
> It was unsourced only on the Housing row, which is why it came off that row and not out of the DB.

Every row below was read against its live cited page, not against the tool's verdict. **None of the 19
is a plain retirement.** They are four different problems wearing one label, and three of them are not
citation failures at all.

Source run: `data/stance-retirement/2026-08-01-audit-tail-refixed.json` (after the negation,
quote-parity and stemming fixes). Prior run had 22; the detector fixes removed 3 before a human looked.

## A. Substance IS on the page — keep the row, fix the quote (10)

The cited page supports the claim; the row's *quotation* is compressed, paraphrased or invented. Per
the post-mortem's own rule, inexact quotation is not fabrication, and deleting these destroys true,
sourced work.

| row | what the page actually says |
|---|---|
| Daniel Cottam / Social Security | "we need to raise the retirement age by at least 3 years across the board with a **gradual phase in**" — row compressed it to "gradually raise the retirement age" |
| Daniel Cottam / Medicare | "one of the ways I would reform Medicare is by decreasing regulations … surgical centers … allow Medicare to negotiate" — matches the row exactly. The quote "partially privatize Medicare" is the researcher's own characterisation and should simply be removed |
| Daniel Cottam / Housing | regulations / apartment / complex / allowing all present — the blocked-apartment-complex story is on the page |
| Civil Miller-Watkins / Voting Rights | "I will work to **protect voting rights** … strengthen faith in our elections" + "strong supporter of the **John Lewis Voting Rights Act**" |
| Cliff Johnson / Medicare | mississippians / thousands / stabilize / medicaid / coverage **all present**. Failed only because "Medicaid and ACA" was tested as one conjoined string |
| Brinker Harding / Taxes | eliminate / wasteful / spending present — the "cut taxes, eliminate wasteful spending" pledge is there |
| Nadia Milleron / Healthcare | healthcare / accessible present — "accessible to all" is on the page |
| Sarah Zabel / AI Oversight | transparency / accountability / violations present |
| Holly J. Mitchell / Redistricting | redistricting / independent / commission / california present |
| Johnny Baucom / Taxes | constitutional / deregulation present ⚠️ but cited page is the **election page**, not his own — re-point as well as re-quote |

## B. Unevidenced inference — retire, but as NO STANCE, not as a citation failure (3)

These rows say outright in their own reasoning that no evidence was found, then assign a chair from the
person's general record. The backlog's standing rule is that where no source supports a chair, the
answer is **no stance**. Retiring them for a *failed citation* would mislabel why they are going.

- **Isaac Bryan / Religious Freedom** — "No direct legislation or on-record statements … were found."
- **Holly J. Mitchell / Religious Freedom** — "No specific legislation authored by Mitchell … was identified."
- **Holly J. Mitchell / Campaign Finance** — inference from caucus membership and general record.

## C. Genuine citation failure, but RE-POINTABLE — do not retire (4)

The claim names a real, checkable instrument that is simply absent from the Ballotpedia page. The fix
is a better source, not deletion.

| row | claim | where it should point |
|---|---|---|
| Isaac Bryan / Housing | authored **AB 1685** | leginfo.legislature.ca.gov |
| Jarrett Keohokalole / Voting Rights | sponsored **HI HB489** (2015) | capitol.hawaii.gov |
| Thomas Lavigne / Trans Athletes | roll calls on **LD 1134 / LD 233** | legislature.maine.gov — note "transgender" is absent from the whole 21k page |
| Carine Werner / Housing | sponsored **SB1729** | azleg.gov |

## D. Needs a person to decide (2)

- **Guy Guzzone / Criminal Justice** — "expungement" and "criminal" both absent; only generic terms present.
- **Shirley Weber / Taxes** — committee/assembly/spending present, but **reparations** absent. The
  reasoning leans on the reparations record specifically, so the row may need narrowing rather than
  re-sourcing.

## The 11 UNKNOWN rows are all explained — none is a rate-limit artifact

- 8 × HTTP 404 — Andrej Selivra (7, cites the *Los Angeles City Council elections, 2026* race page) and
  Mónica García (1). A race page never supported a claim about one candidate.
- 2 × HTTP 403 — Bo Biteman and Matthew D. Klein cite `r.jina.ai/…`. These are **PROXY_URL_AS_SOURCE**
  rows; the 403 is the scraping wrapper refusing, exactly as the backlog records.
- 1 × HTTP 200, 0 chars — Ankur Patel cites bare `https://ballotpedia.org`. That is the single
  **BARE_AGGREGATOR_DOMAIN** row; there is no article div because it is the site homepage.

⚠️ **The audit's cohort query predates the gate split**, so it is auditing 3 rows that belong to other
gate buckets. Worth aligning it the way `deep-link-candidate-connection.mjs` was aligned.

## Standing conclusion

**Seven consecutive times now, this detector's findings have shrunk when either the detector or the
reviewer was corrected** — 32→11→3→0 on Texas, 18→8→5 on TN/WA, 22→19 here, and then 19→0 plain
retirements on reading the pages. The tool is good at finding rows *worth reading* and has never once
been right that a row should be deleted. Treat its output as a reading queue, never as a delete list.
