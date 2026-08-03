# Pre-tenure re-research — tranche 2: both defects fixed, roll calls re-triaged, Hyde-Smith built

Continues `ADJUDICATION-TRANCHE-1.md` and `AFFIRMATIVE-SOURCE.md`. **Nothing is written to production. No
migration. Every chair in the artifacts is still blank** — the verdicts below are recorded here and in the
JSON, ready to be applied as a separate, reviewed step.

Artifacts: `affirmative-candidates.json` · `bill-adjudication.json` (now carries `crs_verdict`) ·
`senate-rollcall-index.json` · `senate-hyde-smith-candidates.json` · `ADJUDICATION-WORKSHEET.md`.
Scripts: `_tmp-pretenure-topic-crs.mjs` (shared mapping) · `_tmp-pretenure-cosponsor.mjs` ·
`_tmp-pretenure-retriage-rollcalls.mjs` · `_tmp-senate-rollcall-index.mjs` ·
`_tmp-senate-triage-and-fetch.mjs` · `_tmp-pretenure-worksheet.mjs`.

## Defect 2 — bill id: 952 nulls → 0

`legislationUrl` was never a parse bug. **It does not exist in 116th or 117th BILLSTATUS at all** (0 of
~30,000 files), is partial in the 118th, and near-complete in the 119th — the null rate was a data-vintage
artefact, which is why it looked like 952 arbitrary rows.

The bill's own `<number>` and `<type>` are **direct children of `<bill>`, indented exactly 4 spaces**;
committee `<type>Standing</type>` sits deeper, so the indent anchor disambiguates them. A small set of
older files use a legacy schema where `<billNumber>`/`<billType>` **do** exist — correcting the earlier
note that those tags never exist. With the fallback:

| | |
|---|---|
| files resolving to a bill id | **45,894 / 45,894 (100%)** — later 85,352 / 85,352 with the Senate and 115th added |
| agreement with `legislationUrl` where present | **13,396 / 13,396, zero disagreements** |
| ids now formatted | `H.R. 8404`, `H.J.Res. 35`, `S.J.Res. 13` (was `house bill 8404`, unusable as a citation) |

⚠ **My first verification of this was invalid and I nearly shipped it.** The check script was written with
a bash heredoc that silently ate backslashes, so `[\\s\\S]` reached disk as `[sS]` and `\d` as `d`. The
regexes still "ran" and still reported 100% agreement. It surfaced only because the same corruption made
an unrelated extraction return 0 policy areas on 45,894 files, which was impossible. **Scripts are now
written with the file-writing tool, never a heredoc**, and the verification was redone from scratch.

## Defect 1 — CRS mappings tightened: 1,595 → 434 candidates

The error class had fired **three times**, and the third time was mine, during this fix:

1. **Keywords** — "marriage" made H.Res.994, a *rule* for the SALT **Marriage** Penalty Elimination Act,
   the only Same-Sex Marriage evidence for four members.
2. **CRS subject terms** — the claim that CRS terms "mean what they say" was an overclaim. The terms are
   professionally assigned; the ones *chosen* were wider than the topics. `Sex, gender, sexual orientation
   discrimination` pulled in an ERA ratification-deadline resolution, `Marriage and family status` pulled
   in the Caring for Survivors Act, `Government lending and loan guarantees` pulled 174 student-loan and
   SBA bills into Taxation.
3. **Bill titles** — matching titles by regex re-ran the bug immediately: `/equality act/` matched **DAIRY
   PRIDE Act** and *Supplemental Security Income Equality Act*; `/for the people act/` matched
   *Prescription Pricing for the People Act* and *Emergency Money for the People Act*.

So all three layers are now **exact, closed-vocabulary** matches, in one shared module
(`_tmp-pretenure-topic-crs.mjs`) imported by both the co-sponsorship pass and the roll-call re-triage so
they cannot drift:

- **`policyArea` is a GATE (AND), never an alternative.** It was previously OR'd with subjects, and
  area-alone produced **623 of the old 1,595 rows** — literally every bill filed under Taxation. Exactly
  one policyArea is assigned per bill, which makes it a strong discriminator but never a position.
- **Subject terms match exactly.** Substring matching is what let `discrimination` swallow every kind of
  discrimination and `criminal justice` swallow *Criminal justice information and records* (676 bills
  about records systems).
- **Identity bills match by exact title.**
- Every term was verified present in the corpus vocabulary (**1,070 distinct CRS terms**, extracted from
  the data) before use — no term was chosen from memory.

Dropped as wider than their topic: `Government lending and loan guarantees` · `Child health` (958 bills;
child health is not childcare affordability) · `Health programs administration and funding` (1,504) ·
`Census and government statistics` (the census is not a redistricting position) · `Small business` and
`Manufacturing` · `Alternative and renewable resources` and `Energy efficiency` for Fossil Fuel (the
renewables axis — backing renewables is not a fossil-fuel *position*) · the enforcement-mechanics half of
Criminal Justice · the umbrella `Elections, voting, political campaign regulation`.

🔴 **Two topics have no usable CRS term at all, and this is structural, not tuning.** Same-Sex Marriage's
only candidate terms are two umbrellas (`Sex, gender, sexual orientation discrimination`, 526 bills;
`Marriage and family status`, 136). Campaign Finance has only `Elections, voting, political campaign
regulation` (667), one term spanning elections *and* voting *and* campaign regulation, so it cannot
separate campaign finance from voting rights. For those two topics subject matching is **disabled** and
identity bills are the only route — which is what `AFFIRMATIVE-SOURCE.md` predicted.

| | before | after |
|---|---|---|
| affirmative candidates | 1,595 | **434** |
| bill id null | 952 | **0** |
| (member, topic) pairs covered | 35 of 36 *(incl. the ERA / veterans' false positives)* | **33 of 36** |
| match basis | area-alone 623 | area+subject 418 · identity 5 · adjacent-identity 11 |

A self-check now prints every curated identity title that produced no signature, and distinguishes *real
bill, nobody signed it* from *not a title in the corpus*. It currently reports **0 invented titles**.
⚠ The first version of that check collected titles only from cohort-signed bills, so "exists in corpus"
silently meant something narrower and I dropped five real bills on its advice; they are restored.

## Roll calls re-triaged: 277 → 76 worth reading

The 277 roll-call bills were shortlisted by the **original keyword triage** — the same defect. Joining each
to BILLSTATUS and applying the tightened gate:

| | |
|---|---|
| at least one ON_TOPIC topic | **76** ← the real roll-call reading queue |
| every shortlisted topic OFF_TOPIC | 181 |
| not legislation at all | 20 |
| unjoinable (missing data) | **0** |

The rulings are plainly right: **VA clinic renamings** and *"To designate the clinic of the Department of
Veterans Affairs in Indian River, Michigan…"* had been shortlisted as **Taxation and Public Spending**
evidence. And **19 of the original 21 non-joins were `Election of the Speaker` ballots**, shortlisted for
Voting Rights because the question text contains the word "Election" — not legislation, no bill, no
position. They are classified `NOT_LEGISLATION`, which is a confident ruling, separately from
`NO_BILLSTATUS`, which is missing data. Conflating those two would repeat the empty-HTTP-200 mistake of
treating absence as an answer. The one genuine gap (`H.Con.Res. 86`, a carbon-tax resolution) was closed
by downloading `hconres`; `sres`/`sconres` and the whole 115th were added too, so nothing is unjoinable.

**This is a reading queue, not a delete list.** All 277 rows are retained with their CRS classification so
every OFF_TOPIC call can be checked by hand.

## 🔴 Cindy Hyde-Smith — both unbuilt sources are now built

1. **Senate BILLSTATUS** (`s`, `sjres`, plus `sres`/`sconres` and the 115th) — she was invisible to the
   co-sponsorship pass because only House types had been downloaded. She now has **52 candidates**.
2. **Senate roll calls** — `senate.gov/legislative/LIS/roll_call_lists/vote_menu_<congress>_<session>.xml`,
   9 sessions covering 2018-04-09 onward: **3,446 roll calls in tenure** at ~9 requests instead of ~3,400.
   CRS-gated (not keyword-gated) to her one topic: 2,128 not bills (nominations), 792 off-topic,
   **526 ON_TOPIC**, 0 unjoinable.

⚠ **The Senate keys votes on `lis_member_id`, not bioguide** — she is **S395** — and "Hyde-Smith" is
exactly the compound-surname shape that made `Hoyle (OR)` report Val Hoyle absent from votes she plainly
cast. The id was derived from the vote XML, never recalled. Sanity counts: **she appears in 526 of 526**
fetched votes, chamber totals 99–100.

## Adjudications

### ✅ Ayanna Pressley / Taxation and Public Spending → **chair 1** (retired chair was 1.0)

She is the **SPONSOR** — not a co-sponsor — of the **American Opportunity Accounts Act** in three
consecutive Congresses (H.R. 3922 116th, H.R. 835 117th, H.R. 1041 118th): federally funded "baby bond"
savings accounts for every American child.

**Cite the 116th version, H.R. 3922.** Its CRS summary states the bill *"also increases and modifies
(1) estate and gift taxes, and (2) capital gains taxes"*, and its subject list carries `Capital gains tax`,
`Transfer and inheritance taxes` and `Income tax rates` — so the revenue side is documented in the source,
not inferred. ⚠ The 118th reintroduction (H.R. 1041) **drops those subjects and its summary does not
mention the tax increases**, so it is the weaker citation despite being the most recent; it would support
"new public spending" but not "raise taxes on the wealthy".

Chair 1 is *"significantly raise taxes on wealthy people and large companies to fund more public
services."* H.R. 3922 does exactly both halves, and sponsoring it three times is about as affirmative as
legislative evidence gets. Chair 2 (*"moderately raise taxes … to fund existing services"*) does **not**
fit equally: this creates a **new** universal program, and estate/gift plus capital-gains increases are
significant rather than moderate. Chairs 3–5 are contradicted outright.

### ✅ Ayanna Pressley / Criminal Justice Approach → **chair 1** (retired chair was 1.0)

Nine sponsorships and 40 co-sponsorships, consistently at the decarceral end: **SPONSOR** of the Federal
Death Penalty Prohibition Act (H.R. 262, 117th; H.R. 4052, 116th), Justice for Incarcerated Moms Act,
Andrew Kearse Accountability for Denial of Medical Care Act; **original co-sponsor** of the MORE Act
(decriminalisation + expungement + community reinvestment); co-sponsor of the Second Look Act, REDEEM Act,
No Money Bail Act, Emergency Community Supervision Act, Eliminating Debtor's Prison for Kids Act, and a
constitutional amendment to repeal the Thirteenth Amendment's punishment exception.

Chair 1 is *"helping the person change their life and stay out of trouble in the future."* Chairs 3–5 are
contradicted decisively. The 1-vs-2 test was applied explicitly: chair 2 centres accountability delivered
another way (*"treatment, community service, or restitution"*), and her record does **not** emphasise
alternative sanctions — it is second-chance and anti-punishment (expungement, sentence review, release,
abolition). Chair 1 is the single supported chair.

### ✅ Same-Sex Marriage ×4 (Hoyle, Salinas, Landsman, Collins) → **BLANK confirmed**, now against affirmative evidence

Tranche 1 reached blank on roll calls. The affirmative pass does not change it, which is a stronger result
than the first one:

- **Mike Collins** — zero candidates from any source. His retired row claimed he *"voted FOR the Respect
  for Marriage Act, breaking with most conservative Republicans"* — the highest-harm row in the workstream.
  RFMA is in the corpus and **no cohort member co-sponsored it**; it passed 2022-12-08, before he was
  seated. Blank is correct.
- **Hoyle, Salinas, Landsman** — their only candidates are the **Equality Act** (original co-sponsors),
  Do No Harm Act, and LGBTQI+ Data Inclusion Act. None is marriage-recognition legislation: the Equality
  Act amends the Civil Rights Act on employment, housing, credit and public accommodations. Decisively:
  **chairs 1 and 2 both entail nationwide same-sex marriage**, so co-sponsoring an LGBTQ anti-discrimination
  bill cannot separate them — *two adjacent chairs fit → SKIP*.

### ✅ Cindy Hyde-Smith / Taxation and Public Spending → **BLANK** (retired chair was 4.0)

This one reversed on the evidence, and the reversal is the point.

Her roll-call record alone reads like chair 4 (*"cut taxes for everyone and scale back public services to
match"*): **Yea on H.R. 1 (2025)**, the reconciliation act extending and expanding the individual rate
cuts alongside Medicaid and SNAP reductions; **Nay on the Inflation Reduction Act** (corporate minimum
tax) and **Nay on the American Rescue Plan**, which rule out chairs 1–2; and her Yea on the largest tax
cut of the period contradicts chair 3. I had provisionally concluded chair 4, reasoning that chair 5
(*"drastically cut taxes and shrink government"*) was contradicted by her voting Yea on **27 of 34**
appropriations passages, including CARES.

**The sponsorship data overturned that.** She is the **SPONSOR of a constitutional Balanced Budget
Amendment in three consecutive Congresses** (S.J.Res. 3 116th, S.J.Res. 6 117th, S.J.Res. 13 118th). Read
from the source rather than the title, it is considerably stronger than "balance the budget": the CRS
summary confirms it would cap total federal outlays at **18% of GDP**, require a **two-thirds vote of both
chambers to impose any new tax or raise any tax rate**, and require three-fifths to raise the debt limit.
That is a repeated, constitutional-level affirmative commitment to shrinking government and locking in low
taxes — precisely the chair-5 commitment I had just called absent. Her appropriations Yeas are also weaker
evidence than they looked: she sponsored the THUD appropriations bill (S. 2465) as an appropriator, so those
votes carry an institutional explanation, not only an ideological one.

So chair 4 has affirmative support (Yea on H.R. 1: broad rate cuts plus Medicaid/SNAP reductions) and chair
5 has affirmative support (the BBA, sponsored three times), and **neither is contradicted** — her routine
appropriations Yeas sit awkwardly with an 18%-of-GDP cap, but voting to fund the government under current
law is not a repudiation of wanting to change it. **Two adjacent chairs fit → SKIP.** Blank.

⚠ Worth recording as a method lesson: **roll calls alone pointed at a chair that sponsorships then took
away.** Tranche 1 concluded affirmative evidence was needed to *reach* chairs; here affirmative evidence
was needed to *avoid over-claiming* one. Read both sources before pinning anything.

## Where the remaining work stands

**Adjudicated here: 7 of 36 pairs** — 2 chairs supported, 5 blank. The honest running total:

| | pairs |
|---|---|
| settled in tranche 2 | **7** (Pressley ×2 chair-supported; 4 × Same-Sex Marriage + Hyde-Smith blank) |
| still settled from tranche 1 | **5** (Climate ×3, Fossil Fuel ×2 — oppositional evidence only) |
| **open** | **24** |
| total | 36 |

⚠ Three pairs tranche 1 closed as "zero candidates" are **re-opened** and counted in the 24, because the
affirmative pass gave them evidence that did not exist when they were closed: **Hoyle / Campaign Finance
Reform**, **Hoyle / State Redistricting**, **Van Epps / Immigration**. Closing a pair for absence of
evidence is only valid against the sources that were built at the time.

The remaining queue, with the chair text on the page, is `ADJUDICATION-WORKSHEET.md` (1,508 lines):

| queue | size |
|---|---|
| roll-call bills worth reading | 76 (from 277) |
| affirmative (bill, topic) units | ~310 (from 1,595 rows) |
| Hyde-Smith Senate on-topic votes | 526 |

Heaviest first: **Taxation** (Reschenthaler 82, Neguse 74, Pressley 45 ✅ done, Hyde-Smith 52, Salinas 8,
Hoyle 5, Bentz 3, Van Epps 1), then **Criminal Justice** (Pressley 49 ✅ done), **Healthcare** (Bentz 21),
**Reproductive Rights** (Hoyle 11).

Two first-look observations for whoever picks it up:

- **Reschenthaler and Neguse both look like SKIPs, for the same reason from opposite directions.**
  Reschenthaler's 82 are almost entirely *narrow, targeted* tax credits, and he sponsored exactly one
  (a rare-earth magnet production credit). A pile of niche credits does not pin chair 4's *"cut taxes for
  everyone."* Neguse's 8 sponsorships are credit **expansions** (LIHTC, solar, R&D) — expanding a business
  credit is not chair 1's *"significantly raise taxes on wealthy people and large companies."* Both need
  reading, but neither looks chair-shaped.
- 🔴 **Two topics may be structurally unanswerable for federal members.** *Economic Development Incentives*
  asks *"How should **your city** attract businesses…"* and *Transportation Priorities* asks *"Where should
  **your city** focus its transportation investment?"* Both are **city-scoped questions** applied to members
  of Congress. Kamlager-Dove / Economic Development already has zero candidates. This is a scale-scope
  mismatch, not an evidence gap, and it should be decided as policy rather than researched further.

## Still owed

1. Adjudicate the 24 open pairs from `ADJUDICATION-WORKSHEET.md`.
2. Decide the city-scoped-topic question above before spending research effort on those pairs.
3. Re-open the three tranche-1 "zero candidate" pairs that now have affirmative evidence
   (Hoyle / Campaign Finance, Hoyle / State Redistricting, Van Epps / Immigration).
4. Only then write a migration. **Nothing has been applied; next free number is 1541.**
