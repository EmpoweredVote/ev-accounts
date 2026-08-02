# The 22 held rows — resolution

1527 repaired 257 damaged `sources` arrays automatically and **held 22** its guards could not prove.
Worked by hand: **13 repaired (1528) + 1 more found (1529) · 9 need an operator decision.**
`NON_URL_SOURCE` 22 → **9**.

## 🔴 Every held row needed a different fix from the one a rule would have chosen

The guards were not being cautious for its own sake — in each case the automatic repair was **wrong**:

| held row | what the rule would have done | what was actually true |
|---|---|---|
| **Igor Tregub ×2** | nothing — both halves return 200, so the URL "isn't broken" | `/wiki/Berkeley` and `/wiki/Berkeley,_California` are **different articles**. Only the second is the city he represents. Rejoined. |
| **Mónica García ×2** | rejoin on the comma | 🔴 **the rejoined URL 404s too** — Ballotpedia renamed the page. The automatic fix would have produced a *second* broken link. Re-sourced instead. |
| **Linda Sanchez** | nothing — congress.gov 403s from a script | The truncated form is **unclosed JSON** (`{` with no `}`) in the query string. Decisive on structure where the network was silent. Rejoined. |
| **6 drop-cases** | rejoin the fragment onto the reasoning | Their reasoning is **complete** and already states the claim; the stray entry is a bare name (`"Susan Collins"`, `"John Lee"`) or a quotation the reasoning reproduces. Rejoining would have corrupted finished prose. Dropped. |
| **Kris Fair** | nothing — first fragment `"disinformation"` has no whitespace, so the prose test never fired | A textbook reasoning-split. Rejoined; the mgaleg citation survives. |
| **Benjamin Brooks** | — | See below. The worst single row found. |

## 🔴 Brooks: two entire stance rows were swallowed, not just corrupted

His one "source" is a raw CSV fragment containing **three records**: the tail of his own reasoning, its
real URL, and then **two complete stance rows that never reached the database**:

- `local-environment, 2` — *"Brooks sponsored the Maryland Native Plants Program (signed into law 2023) and chairs the Joint Electric Universal Workgroup Service Program focused on expanding community solar access for low-income residents."* → `en.wikipedia.org/wiki/Benjamin_Brooks_(politician)`
- `economic-development, 2` — *"Brooks sponsored community solar expansion legislation (SB613, 2023) and property tax incentives for grocery stores in food deserts, prioritizing economic equity and access in underserved communities."* → `benbrooksforsenate.com/about`

Brooks holds **neither topic today**. His Public Safety row is repaired in 1528; the two lost rows are
**not** re-created, because that is inserting stances, not repairing one — an operator decision.

✅ **Checked corpus-wide: exactly one `sources` entry contains a newline.** The row-swallowing was a
single incident, not systemic.

## 🔴 A new class found by accident: URLs that parse but 404

Confirming the García fix surfaced **a third row of hers — School Vouchers — citing the same dead URL**,
unsplit and perfectly well-formed. It was in no cohort and tripped no detector, because nothing about it
is malformed. It simply does not resolve.

That is a class no gate check can see: **every branch classifies by the SHAPE of the URL**, and the
2026-08-01 reachability sweep probed only the bare *hosts* of the `PRIMARY_SITE_NO_PATH` bucket — never
deep paths. Fixed for this row in 1529; the class is unswept.

⚠ It was found only because the same target was reached by two different routes. There is no reason to
think García is special.

---

## ✅ The last 9 — re-sourced, not retired (1530). `NON_URL_SOURCE` is now **0** and zero-tolerance.

Operator decision 2026-08-02: re-source. These were sound research whose citation our pipeline
destroyed; retiring them would have deleted good work to pay for an ingestion bug.

🔴 **The obvious move was wrong, and checking is what caught it.** "Give each Maryland senator their
mgaleg member page" fails, because **mgaleg shows ONE SESSION**: Zucker's 2011/2013/2018/2021 bills and
Feldman's 2018-2021 record are simply absent from their 2025 pages. Assigning them would have produced
nine authoritative-looking citations that support nothing — the precise failure this workstream exists
to stop. Each row went to the page that actually holds its claims:

| row | source | verified to contain |
|---|---|---|
| Lam / Medicare-aid, Criminal Justice | mgaleg `lam02?ys=2025RS` | SB0111, SB0438, SB0448, SB0974, SB0741 — all present, titles matching, Primary sponsorship |
| Lam / Healthcare | `clarencelam.com/meet-clarence` | *"capping the cost of insulin at no more than $1 per day"*, *"the only physician in the Maryland State Senate"*, *"healthcare is a human right"* — mgaleg does **not** carry the insulin claim (2022 session) |
| Feldman / Healthcare | Wikipedia | Protect Maryland Health Care Act, individual mandate, medical debt, Prescription Drug Affordability Board |
| Zucker / Civil Rights | Wikipedia | Civil Marriage, death penalty, harassment, Raskin |
| Valentine / Voting Rights | mgaleg `valentine01` | HB0454 *(SAVE Our Elections Act of 2026)*, HB0964 *Secure the Vote Act of 2026*, both Co-Sponsor |
| Fleming / Healthcare | OnTheIssues Health Care | single-payer, socialized medicine, repeal, takeover, health savings |
| Fleming / Immigration | OnTheIssues Immigration | Birthright Citizenship, ALIPAC, welfare, *"All illegal immigrants should be deported"* |
| Fleming / Religious Freedom | OnTheIssues Civil Rights + Principles&Values | *"Fleming co-sponsored Marriage and Religious Freedom Act"*; verbatim *"a Government interest of the highest order"*; Ten Commandments, prayer, Christian principles |

**Unmatched quotation marks were repaired too** — the split ate opening quotes, leaving `received an A"
rating`. A dangling *closing* quote proves its opening was lost in the same split, so it was restored,
never invented.

⚠ **One claim was deliberately not chased:** Fleming's *"complete autonomy for religious organizations
in how they operate"* appears on no source page **because it is our own chair-5 text**. It is the
researcher's alignment statement, not a quotation — the documented "quoted compass chair label" trap.

### And the migration's own assertion found one more

Scoped to the politician rather than the row (the same over-broad mistake 1524 made), it swept in
**John Fleming / Taxes**: `Abolish the Income Tax.""` — a CSV double-quote *escape* that leaked
through with its opening quote lost. Repaired in 1530. Corpus-wide there is exactly one such row.
Both times an over-broad assertion has fired here it found something real, so the rule is: **narrow the
check *and* fix what it found** — never narrow it and walk away. (12 rows still carry a single
unmatched quote; several were fixed above, the rest are a small follow-up, deliberately not swept blind.)

## ~~The 9 rows still held — an operator decision~~ (resolved above; kept for the reasoning)

All nine are the same shape: **reasoning truncated mid-sentence, and no URL survives anywhere in the
array.** Repairing the reasoning is unambiguously right, but it would leave `sources` empty — and
`EMPTY_SOURCES` is a **zero-tolerance** gate class, so the repair cannot be applied on its own.

| politician | topics | what the reasoning cites |
|---|---|---|
| Clarence Lam (MD Sen) | Healthcare · Medicare/aid · Criminal Justice | named bills: SB0438, SB0448, SB0974, SB0741 |
| John Fleming (LA) | Healthcare · Immigration · Religious Freedom | Birthright Citizenship Act; ACA repeal |
| Brian Feldman (MD Sen) | Healthcare | Protect Maryland Health Care Act (2018), Prescription Drug Affordability Board |
| Craig Zucker (MD Sen) | Civil Rights | capital-punishment repeal (2013), NDA ban (2018) |
| William Valentine | Voting Rights | SAVE Our Elections Act |

**These are not bad research.** The claims are specific, dated and checkable — the citation was
destroyed by our ingestion, not missing from the work. Three options:

1. **Re-source, then repair** — for the Maryland senators the obvious target is their `mgaleg.maryland.gov`
   member page, *but only after verifying it actually lists the cited bills*. Assigning it unverified is
   the exact inference this workstream keeps punishing. Most work, best outcome.
2. **Retire** — consistent with `EMPTY_SOURCES` being zero-tolerance and with 1520/1521/1522/1525. But it
   deletes sound research to pay for a pipeline bug.
3. **Repair the reasoning and leave them flagged** — restores the mutilated voter-facing text now, keeps
   the rows visible in `NON_URL_SOURCE` until sourced. The prose would briefly appear both in the
   reasoning and in `sources`.

Recommended: **(1)**, and it is small — 9 rows across 5 people, most of them Maryland bills on one site.
