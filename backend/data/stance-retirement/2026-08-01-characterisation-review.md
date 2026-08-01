# Characterisation rows (`NO_QUOTE`) — hand review, COMPLETE

Cohort regenerated after 1521: **78 characterisation rows across 52 sites.** All 52 sites readable.
Evidence: [`2026-08-01-topic-evidence.md`](2026-08-01-topic-evidence.md), produced by
`probe-topic-evidence.mjs`, which searches each page with a lexicon built from the **compass topic**
rather than from the row's own wording.

**Read: 78 of 78.** ✅ **APPLIED 2026-08-01 as migrations 1522 / 1523 / 1524** on operator decision.
Gate **653 → 640**; `PRIMARY_SITE_NO_PATH` baseline ratcheted **548 → 535** (exactly −13, the
retirements). Rollback: `2026-08-01-characterisation-remedies-rollback.json` — generated from the
database by `emit-characterisation-rollback.mjs`, which refuses to write a short record.

⚠ **One row was reclassified during application: Marc LaHood / Immigration moved from reasoning-fix to
retirement.** "immigra" is absent from his whole site, which is the identical test Craddick and Lancia
failed, and the same test must give the same answer. Final: **13 retire · 3 chair · 9 reasoning.**
**Brooks Benson / Housing** likewise moved from chair-correction to retirement — see 1522 for why his
position is not representable on the Housing axis at all.

---

## 🔴 The single most important result: the topic probe could not see the evidence

`probe-topic-evidence.mjs` prints the **top-3 passages scored on topic-lexicon hits**. That design is
right — it keeps the evidence independent of the claim — but it means the sentence a row actually
rests on is routinely **not in its output**, because that sentence scores 0–1 topic terms.

Reading "the passages didn't mention it" as "the site doesn't say it" would have destroyed correct
rows. Concretely, every one of these is **verbatim on the cited page and absent from the probe's
output for that row**:

| row | the sentence the probe never showed |
|---|---|
| Barnitz / Abortion | *"Missourians spoke clearly by passing **Amendment 3** in 2024. This historic vote restored reproductive freedom"* |
| Barnitz / Voting Rights | *"In Missouri, we already have to show ID… **That's good enough for me.**"* |
| Hooslyn / Deportation | *"**Abolish ICE** and reallocate funds toward Core 4 policies"* |
| Kopp / Deportation | *"**Abolishing ICE**"* — first item of her A–Z priorities |
| Beebe / Abortion | *"I am unequivocally pro-life — I believe **life begins at conception**… I support the **Dobbs** decision"* |
| Mills / Voting Rights | *"Require **proof of U.S. citizenship** for voting… Support **paper ballots** and fully auditable election systems"* |
| Jacob / Abortion | *"Being **pro-choice** encompasses more than just a single policy debate"* |
| Arndt / Healthcare | *"**Medicare for All**"* — a red line, and a section heading |
| Schwab / Campaign Finance | *"Scott has opposed legislation in Congress that would… **use tax dollars to fund political campaigns**"* |
| D'Arrigo / Taxes | *"eliminate federal income tax for every household earning **under $75,000** per year"* |

**So the tooling was corrected a ninth time**, and again in the direction of fewer findings. A new
script does the reading the probe cannot: **`scripts/read-site.mjs`** — it imports `lib/site-crawl.mjs`
(no duplicated crawler), greps **raw HTML** rather than extracted body, and **prints `raw=` / `body=` /
`chrome=` char counts for every page** so extractor loss can never masquerade as an absent claim. It
proposes nothing and writes nothing.

    node scripts/read-site.mjs --site https://frankbarnitz.com --find "amendment 3|voter id|good enough"
    node scripts/read-site.mjs --site https://kirkland2026.com --full

Every verdict below was taken against raw HTML with those counts printed.

---

## Tally — all 78 rows

| verdict | rows |
|---|---|
| **keep** — correctly sourced | **53** |
| **reasoning fix** — drop an unsourced specific, keep row and chair | **10** |
| **chair wrong** — topic is on the page, but the page supports a different chair | **4** |
| **retirement candidate** — the topic itself is absent from the cited site | **11** |

*(Corrects an off-by-one in the interim tally: the first 13 rows were 7 keep / 5 fix / 1 retire, not 8/5/1.)*

**No politician is emptied by any retirement below.** Worst case Kirkland 5 → 1; Lancia 5 → 4;
Hernandez 6 → 5; Benson and Welford lose nothing (chair corrections). The 1494 rule is not in play —
but re-run this check against live counts before applying anything.

---

## 🔴 Retirement candidates — 11

The test is the one 1517/1520/1521 established: **the topic vocabulary is absent from the raw HTML of
the whole site.** Not "the row is thin", not "I am unsure" — *verified absent*. Each line gives the
haystack size actually searched.

| row | what is absent from raw HTML | what the row leaned on instead |
|---|---|---|
| **Kirkland / Fossil Fuels** (ca) | *energy, oil, drilling, permit* — 13,883c, one page | "restart domestic production" (4 words) |
| **Kirkland / Housing** | *zoning, affordab* | same clause; chair 4 needs zoning + private developers |
| **Kirkland / Healthcare** | no coverage / insurer / employer / poor content at all | same clause |
| **Kirkland / Taxes** | no tax-cut language; only "waste and fraud", "demand audits" | row itself concedes "no explicit flat-tax or drastic-cut language" |
| **Fairly / Deportation** (tx) | *deport, traffick* — 36,530c over 2 pages | **worked for Ronny Jackson**, and "Panhandle district is strongly pro-enforcement" |
| **Fairly / Trans Athletes** | *sports, athlet, biological* | "radical gender ideology" — verbatim, but about **classroom materials and libraries** |
| **Hopper / Trans Athletes** (tx) | *sports, athlet, biological* — 8 pages, 38k+c | row says it outright: "No specific trans-athlete bill… **strongly implies**" |
| **Craddick / Deportation** (tx) | *deport, immigra* — 26,886c | $3bn border security + "no authored mass deportation bill found" |
| **Lancia / Immigration** (ct) | *immigra, visa, public services* — 6,452c | one border-security sentence about drugs and crime |
| **LaHood / Religious Freedom** (tx) | *religio, exemption* — 17,699c | biography only: "brought him back to the Church", "his family, and his faith" |
| **Hernandez / Housing** (va) | *affordable housing, zoning, rent* | the word "housing" once, inside a cost-of-living list |

Three of these repeat precedents already settled on this workstream:

- **LaHood / Religious Freedom is the Schwab case from 1521 exactly.** Personal faith is biography;
  the topic asks about **exemptions from generally applicable laws**. 🔴 Presence is not support.
- **Kirkland is a whole-person pattern, not four rows.** All four come from one sentence —
  *"Kyle will end over-regulation, restart domestic production, and attack the cost-of-living crisis"* —
  plus a four-item list naming housing, food, gas and healthcare as expensive. His **fifth** row is the
  only one not in this cohort, and it quotes something real (*"stop fentanyl, human trafficking, and
  cartel violence while respecting legal immigration"*) and **holds**. One thin single-page site
  produced four specific policy chairs.
- **Both Trans Athletes rows fail the same way** (Fairly, Hopper — both TX): real, verbatim
  gender-ideology content about schools and medical care, stretched to a total sports ban. Worth a
  topic-level look at Trans Athletes rows beyond this cohort.

---

## 🔴 Chair wrong — 4 (the topic IS on the page; the page supports a different chair)

These are heavier than a reasoning trim and lighter than a retirement. Retiring them would erase a
real, sourced position; leaving them shows a voter the wrong one.

**Welford / Healthcare (mi) — chair 1, fabricated quotation.**
Row: *"explicitly advocates for **'free healthcare'** for all Americans, **citing Israel's universal
free healthcare system as a model**."* Raw HTML, whole site (5,357c + 1,618c): *free healthcare*,
*free health care*, *universal*, *single payer*, *Medicare for All* — **all MISS**. "Israel" appears
once, in a **foreign-policy plank** about Israel's right to exist and a two-state peace. The actual
healthcare text is *"Affordable Health Care… I will fight to protect Medicare and Social Security,
lower prescription drug costs, and expand access to quality health care"* — chair 2, not chair 1.
⚠ The quotation marks are the problem: `politician_context.reasoning` is **voter-facing** (Citations.jsx,
"Why this position?"), so this is a live fabricated quote. **Suggested: chair 1 → 2 + reasoning rewrite.**
His other two rows are fine — they cite `/melt-ice.html`, a real 3,543c page my crawl missed because
the URL doesn't match `ISSUEISH`, and it fully supports both.

**Landgraf / Fossil Fuels (tx) — chair 5, refuted by his own cited page.**
The decisive sentence is *"**No evidence of any environmental restrictions he has supported**; he
would strongly favor removing restrictions."* His own site's front page carries **HB 3866**, which
bans chemical-container storage within **2,000 feet of homes** with TCEQ registration and periodic
inspections, and his bio says he **chairs the House Environmental Regulation Committee**, "a leading
voice for… standards that protect public health". The pro-extraction half is solid and verbatim
(*"co-authored a bill that repealed burdensome anti-fracking regulations"*, *"keep energy markets open
and unimpeded for oil and gas producers"*). **Suggested: chair 5 → 4 + reasoning rewrite.**

**Tandon / Childcare (ca) — chair 4, page points the other way.**
Row: childcare affordability *"through **reducing regulatory burdens on providers**… **no proposal for
universal subsidies or broad public investment**"*. Raw: *regulatory burden* MISS, *daycare* MISS. The
page says *"**Expand affordable childcare access**, strengthen elder-care support systems, and provide
**flexible federal support** that helps families stay in the workforce."* That is subsidy expansion
filed under the deregulation chair. **Suggested: chair 4 → 3 + reasoning rewrite.**

**Benson / Housing (ut) — chair 4, and the row refutes itself.**
You do not need the page: the row's own text says *"opposes housing approvals without adequate roads,
schools, and utilities in place — a **growth-management** approach that prioritises **limiting
development pace** over affordability"*, and then files it under *"Cut regulations and zoning rules so
**private developers** can build more housing."* The page confirms the row and not the chair —
*zoning*, *regulation*, *permit*, *affordab* all **MISS** in 4,530c; what is there is
*"Infrastructure-first development that serves families, **not developers**"* and unmanaged growth
listed as the problem. **Suggested: chair 4 → 2 or 3, operator's call.**

---

## Reasoning fixes — 10

Five carried over from the first pass (Nagel/Taxes "tax relief"→"real relief"; Fairly/Religious
Freedom drop the Select Committee; Hopper/Religious Freedom drop Ten Commandments;
Hernandez/Childcare drop Child Tax Credit; Negrete/Public Safety drop Santa Monica Pier). Five new:

- **Landgraf / Climate Change** — chair 5 is **defensible and unmentioned by the row**: *"blocked
  radical **Green New Deal**–style proposals that would threaten Permian Basin jobs and raise costs"*
  is climate-policy rejection framed on economic growth, verbatim on the site. The row instead reasons
  from **district geography** ("represents Odessa… economy built on fossil fuel extraction") and claims
  "his campaign website opposes regulation" — from the chairman of the Environmental Regulation
  Committee. Keep the chair, replace the reasoning with the sentence that actually earns it.
  *(`climate` and `emissions` are MISS site-wide — the chair survives on substance, not vocabulary.)*
- **Park / Immigration (ca)** — 🔴 **party prior in voter-facing text.** All three factual claims verify
  verbatim (*"expanding Know Your Rights education"*, *"making legal resources available"*, *"partnered
  with… **SALEF**… rental relief and direct financial support"*). But the chair rests on *"As a **former
  Republican and the most conservative council member**"* plus an argument from a missing sanctuary vote
  (*sanctuary* is MISS on a page that would not record votes anyway). Strike both clauses. Feeds
  [`2026-07-24-party-prior-stance-contamination-audit.md`](2026-07-24-party-prior-stance-contamination-audit.md).
- **Santos / School Vouchers (ma)** — two invented specifics. *"thriving well-resourced community hub"*
  is presented as her platform statement: **MISS**. *"Endorsed by the Cambridge Education Association"*:
  CEA appears once on the page, as **another endorsee's résumé line** (Betsy Preval) — wrong-person
  attribution. Verified verbatim: *"Luisa will fight for **fully funded schools** and reallocate
  resources to **student-facing supports**"* and the MTA-member claim. All five *voucher* hits on the
  page are **housing** vouchers, and the page's education commitments include *"improving the **school
  choice** system"* — so the "eliminating voucher programs" half is unevidenced. ⚠ Also a **citation**
  problem: the row cites a third-party endorser site which itself names her own,
  `luisaforschoolcommittee.org` — a re-source candidate in the 1512/1519 shape.
- **Kopp / School Vouchers (va)** — *voucher*, *private school* both MISS in 14,647c. The public-education
  half is verbatim (*"Establishing universal public education from pre-K through post-secondary"*); the
  "eliminating voucher programs" half is absence-read-as-opposition. Same bundled-chair shape as
  Greimel/Medicare-aid: keep the row, stop claiming the second half.
- **LaHood / Immigration (tx)** — *"state-led operations"* is verbatim (*"SECURING OUR BORDER THROUGH
  STATE-LED OPERATIONS"*), but *immigra* is **MISS** in 17,699c, and chair 4 is about making **legal**
  immigration harder. Border enforcement ≠ restricting legal immigration. Trim the inference; the chair
  is arguable and worth a second look.

---

## What this cohort actually shows

🔴 **Within a person, the rows that hold up are the ones citing a named instrument; the rows that drift
are the ones citing only a campaign homepage.** This is visible in the non-cohort rows of the same people:

- **Landgraf**'s other three rows cite **capitol.texas.gov bill lookups** (SB8, HB3, HB30) — sound.
  His two homepage-only rows are the two that fell back on district geography.
- **Santos**'s other row cites a **Cambridge Day election guide** — sound. Her CRA-endorsement row drifted.
- **Welford**'s other two rows cite **`/melt-ice.html`**, a real issue page — sound. His homepage row is
  the fabrication.
- **Kirkland**'s one non-cohort row quotes a real sentence — sound. His four homepage rows are the four
  retirement candidates.

That is a better predictor of a bad row than any detector built so far, and it is worth testing as a
cheap corpus-wide signal: **a characterisation row whose only source is a bare campaign homepage.**

**And the headline number is unchanged in direction.** 78 rows selected *because they looked worst*
came back **53 keep**. Of the 25 non-keeps, 11 are retirements and 14 are corrections that leave the row
standing. The risk-ranked head of a queue is not a failure rate.

---

## 🔴 Found while applying: a SECOND party-prior row, outside this cohort

`1524`'s own assertion failed on first run and caught **Traci Park / Taxes** — a row this review never
looked at, because it is not in the `NO_QUOTE` cohort:

> *"Park is the most conservative member of the LA City Council, endorsed by the Chamber of Commerce
> and multiple business federations whose platforms strongly favor lower taxes… **As a former
> Republican operating in a pro-business coalition**, her economic orientation aligns with cutting
> taxes… **No direct city-level income tax vote exists**, but her coalition and record consistently
> reflect new stance 4."*

Party prior, plus inference from **endorsers' platforms**, plus an explicit admission that no vote
supports it. Deliberately **not** fixed by 1524 — it is outside what was reviewed and approved. Logged
for [`2026-07-24-party-prior-stance-contamination-audit.md`](../../../.planning/todos/2026-07-24-party-prior-stance-contamination-audit.md).

The lesson generalises: a same-person check is a cheap way to find contaminated rows, because whoever
wrote one party-prior row for a politician tended to write more. Worth running as a query —
`reasoning ILIKE '%former Republican%'`, `'%former Democrat%'`, `'%his/her party%'`, `'%no direct%vote%'`.

## Next actions

1. ~~Operator decision on the retirements~~ ✅ **APPLIED — 1522.** All 13 re-verified with
   `read-site.mjs --no-cache` *after* the review was written, because crawl status is not stable.
   Every apparent survivor was opened and read; all four were substrings (Kirkland "rent" =
   Current/parents, Fairly "removal" = privacy boilerplate, Hopper "team" = a Cyber Team, LaHood
   "exemption" = **property tax** exemptions).
2. ~~The chair corrections need a ruling~~ ✅ **APPLIED — 1523**, a new remedy class for this
   workstream. Welford's fabricated quotation is off the live card.
3. ~~Reasoning-correction migration~~ ✅ **APPLIED — 1524.**
4. **Three leads worth their own pass**, in rough order of value:
   - **The bare-homepage signal** — a characterisation row whose only source is a bare campaign
     homepage. Best predictor found so far, and there are now **78 labelled rows** to calibrate it
     against before trusting it. If it holds it risk-ranks all 535 `PRIMARY_SITE_NO_PATH` rows.
   - **Party-prior rows corpus-wide** — see the Traci Park / Taxes find above.
   - **Trans Athletes corpus-wide** — 2 of 2 in this cohort failed identically.
5. `neighbors4faye`-style note: **`/melt-ice.html` was missed by the crawler** because the URL doesn't
   match `ISSUEISH`. Issue pages with campaign-slogan URLs are invisible to every tool here.
