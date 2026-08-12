# Chair/reasoning inversion — diagnosis (2026-08-12)

Found while re-sourcing class C of [the 197](2026-08-12-the-197-disposition.md). **Not a sourcing
fault: a wrong chair is a wrong voter-facing position.** The compass dot and the "Why this position?"
text say opposite things about the same person.

## The defect
| person | topic | stored chair | what the chair text says | what the row's own reasoning says |
|---|---|---|---|---|
| Alonzo T. Washington | Civil Rights | **5** | *eliminate affirmative action and all race-based government programs* | "As an African American senator in PG County, he prioritizes racial justice" |
| Todd Gloria | Same-Sex Marriage | **5** | *make same-sex marriage illegal* | "the first openly gay mayor of San Diego … chairman of the San Diego LGBT Community Center" |
| Mark Warner | Ukraine | **5** | *end all aid to Ukraine immediately* | "among the most vocal Ukraine aid supporters in the Senate" |
| Tim Kaine | Ukraine | **5** | *end all aid to Ukraine immediately* | "one of the Senate's strongest Ukraine supporters … voted for the $95 billion supplemental" |
| Kevin M. Harris | Childcare | **5** | *no government subsidies or mandates* | sponsored SB0664 (2026) prioritising providers in the Child Care Scholarship Program |

## How the detector was built, and how it first failed
🔑 **Polarity must not be hand-asserted.** Chairs are 1-5 **discrete options**, not a strength scale
and not left-right, and direction is topic-specific — on **Fossil Fuel Policy the RESTRICTIVE chair
is the pro-climate one**, so any "expansive = chair 1" lexicon inverts. So the scan lets **the corpus
define each topic's polarity**: measure how pro/anti-worded reasoning distributes across the five
chairs, and take the majority pattern as the direction. Topics with a weak or non-monotonic pattern
are **UNCALIBRATED** and contribute no flags — Fossil Fuel Policy scores 0.00 and is correctly excluded.

🔴 **The first cut fired on 1,442 rows (4.4% of the corpus) and was mostly noise, because a verb has
an OBJECT the regex cannot see:**
- *"co-sponsored a resolution **opposing** Senate Bill 590"* — a PRO civil-rights act, scored ANTI.
- *"voted **against** the GOP budget that would cut Medicaid"* — PRO healthcare, scored ANTI.
- *"cosponsored legislation to **block** DEI programs"* — ANTI civil-rights, scored PRO.
- *"**supports limited** government-funded healthcare"* — ANTI, scored PRO.

🔑 **Fix: match on what distinguishes the real defect.** True inversions read as *wholly and
unambiguously* supportive with **no oppositional or restrictive word anywhere**. Any restrictive
marker disqualifies the row, because then direction depends on an object the test cannot read.
**1,442 → 194.**

⚠ **Two topics still produce only false positives and must be excluded by hand** — "support" attaches
to opposite objects in them: **School Vouchers** (*"supporter of public education and opponent of
voucher programs"* IS chair 1) and **AI Oversight** (*"promoting voluntary NIST standards"* IS chair 2).
That is 70 of the 194.

## 🔴🔴 IT IS ONE BAD BATCH, NOT SCATTERED NOISE
**15 politicians hold 79 inverted rows, and for 14 of them 100% of their pro-worded rows sit at the
anti pole** (7/7, 6/6 ×5, 5/5 ×6, 5/6, 4/4). **14 of the 15 are Maryland** — 302 of their source
citations are `mgaleg.maryland.gov`. The 15th is Terry Taplin (Berkeley, CA), a separate case.

Sara Love has **19 rows, every one with pro-progressive reasoning**, sitting at chair **5** on Civil
Rights, Healthcare, Childcare, Same-Sex Marriage, Climate, Environment, Reproductive Rights and
Voting Rights, and chair **4** on nine more.

🔑 **Best reading: one research run wrote the chair as an INTENSITY rating — 5 meaning "strongly holds
this view" — instead of picking one of five discrete policy options.** That is exactly the failure the
standing rule warns about.

⚠ **BUT A MECHANICAL 5→1 FLIP IS NOT SAFE.** The same batch got other topics *right*: Sara Love and
Ron Watson both sit at chair **2** on Fossil Fuel Policy (*"supports transitioning away from fossil
fuels"*) and School Vouchers (*"opposes school vouchers"*) — correct, because there the reasoning is
phrased as opposition and the writer picked a low number. The batch is **inconsistent**, so the
correction has to be judged per row.

## Confirmed by reading, per topic
| topic | flags | real inversions | notes |
|---|---|---|---|
| Civil Rights | 20 | **19** | only Harold Rogers is correct at chair 5 ("voted YES on ending racial preferences", 28% NAACP) |
| Same-Sex Marriage | 15 | **8** | the other 7 are genuine opponents (Steube, Kelly, Miller, Fischbach, Graves, Griffin, Reeves) |
| Childcare | 13 | **13** | all Blueprint-support rows at chairs 4-5 |
| Ukraine | 3 | **2** | Andy Harris is correct at chair 4 (voted Nay on H.R.8035) |
| Rent Regulation | 2 | **2** | |
| Misinformation | 4 | **1** | |
| School Vouchers | 45 | **0** | object-ambiguous, excluded |
| AI Oversight | 25 | **0** | object-ambiguous, excluded |
| Climate Change | 23 | **15** | Grove, Ainsworth, Hunsaker, Braun, Foster, Craddick correct; Whitburn and Jacob too vague |
| Healthcare Access | 22 | **13** | Rutledge, Kohlhaas, Pan, Cowan, Conforti, Wittrock, Vaz correct; Szeliga and Johnson vague |
| Affordable Housing | 22 | **16** | Jones, Czaplewski, Long, Ishii correct; Cloutier and O'Keefe too vague |

## ✅ FIXED — migration 1714. 89 chairs corrected, 18 also re-sourced

Operator chose: correct the chair and re-source where possible, across all calibrated topics.

| topic | rows | new chair |
|---|---|---|
| Civil Rights | 19 | 2 |
| Affordable Housing | 16 | 2 or 3 |
| Climate Change | 15 | 3, or 2 where wording is stronger |
| Healthcare Access | 13 | 2 |
| Childcare | 13 | 2 |
| Same-Sex Marriage | 8 | 1 |
| Ukraine | 2 | 2 |
| Rent Regulation | 2 | 2 |
| Misinformation | 1 | 2 |

**Target = the least extreme pro-side option the reasoning actually supports.** Generic "supports
civil rights legislation … racial equity … anti-discrimination" becomes chair 2 (*strengthen civil
rights enforcement and address systemic discrimination*), NOT chair 1, which demands reparations the
row never claims. Ten rows with clearly stronger wording were overridden individually — the Sierra
Club chapter chair, "aggressive climate action", "universal healthcare access", "housing as a human
right".

✅ **Verified after applying:** production matches the file; **0 of the 89 still sit at their topic's
anti pole**; a full re-scan drops 194 → 105 and **the batch signature is gone — 0 politicians meet it,
was 15**. The 105 remaining are exactly the 70 in the two excluded topics plus the 35 read and judged
correct. Corpus 33,083 / 32,542 unchanged, orphans 0.

⚠ **Sourcing is still owed on 71 of the 89.** Only Civil Rights and Same-Sex Marriage could be
re-sourced from the Maryland index; climate, healthcare, housing and childcare bills were never
crawled. The chair is right now, the citation is still a Ballotpedia bio.

### The original open question (answered)
The stored chair is **unambiguously wrong**; the right replacement is **not** mechanical.
For *"supports civil rights legislation including racial equity measures and LGBTQ protections"*,
chair **2** (*strengthen civil rights enforcement and address systemic discrimination*) fits, but
chair **1** (*mandate racial equity requirements in all institutions and provide reparations*) is a
stronger claim the reasoning does not make. Choosing between them is a research judgement, per row.

Tools: `scripts/chair-inversion-scan.mjs`, `scripts/chair-inversion-batch.mjs`,
`scripts/gen-chair-inversion-fix.mjs`, `scripts/verify-1714-applied.mjs`.
Records: `2026-08-12-chair-inversion-{scan,batch,rescan,rollback}.json`.

## ▶ What is left

### 1. Sourcing on 71 of the 89 corrected rows — and it is TWO jobs, not one
Explicit list: `backend/data/stance-retirement/2026-08-12-chair-fix-sourcing-owed.json` (71 rows).

🔑 **Only 24 of the 71 name an instrument, and they name just TWO acts between them.** The other 47
name nothing at all — so "extend the crawl" is the right plan for one half and useless for the other.

### ✅ (a) THE LANDMARK ROWS — DONE, migration 1717 applied and verified
23 rows (the 24th is Kevin Harris's SB0664/SB0402 row, which names bills rather than an act and was
already sourced). **9 SPONSOR · 12 VOTE · 2 re-sourced from pre-tenure.** Verified in production:
23/23 rewritten, 0 unsourced "backed" verbs left in scope, chairs untouched, corpus 33,083/32,542.
Tools: `md-landmark-acts.mjs` → `md-landmark-disposition.mjs` → `gen-1717-landmark-sourcing.mjs`.
Rollback: `data/stance-retirement/2026-08-12-landmark-1717-rollback.json`.

🔴 **FIVE DEFECTS THE READING CAUGHT — four of them in the tooling, not the data:**
1. **Two rows were PRE-TENURE.** Kevin M. Harris (House 2023-2025, Senate from Dec 2025) and
   C. Anthony Muse (Senate 2007-2019, then from 2023) were both credited with backing an Act passed
   in 2021/2022 while out of office. Retirement is what is left AFTER looking — both were re-sourced
   to real in-tenure solar sponsorships (Harris SB0669/SB0923 2026; Muse SB0120 2025, Ch. 516).
2. 🔴 **THE SPONSOR PARSER WAS DROPPING THE LEAD SPONSOR.** On a leadership-carried bill —
   "The Speaker (By Request - …) **and Delegates McIntosh**, Kaiser, …" — the whole prefix plus the
   first name landed in one over-long cell that the 40-char filter then discarded. Recovered sponsors:
   SB1030 17→19, HB1300 5→7, SB0414 20→21, HB1413 2→4. ⚠ **The committed 882-bill CR sponsor index
   was built with this bug**, so its POSITIVES stand but every "no on-topic bill" NEGATIVE from it is
   unreliable — that includes reasoning used in earlier passes.
3. 🔴 **A SENATE BILL'S SPONSOR CANNOT BE A DELEGATE.** Without a chamber gate the pass credited
   Alonzo T. Washington with sponsoring SB0414/SB0528, whose "Washington" is Senator **Mary**
   Washington. 🔑 The bill page **hyperlinks each sponsor to a member slug** — `washington01` vs
   `washington02` — which is identity where a surname is a guess. ⚠ But slugs rot: HB1300's
   `washington` now 404s, and treating a dead slug as a rival identity manufactured a false negative.
   A mismatch only counts when the rival slug still resolves.
4. 🔴 **A JANUARY-SWEARING-IN ASSUMPTION PUT RON WATSON IN THE WRONG CHAMBER.** He joined the Senate
   on 31 Aug 2021, after the session adjourned, so his 2021 votes are HOUSE votes. Fixed with a new
   month-aware `chamberForSession()`; `chamberFor()` is untouched. ⚠ **Pass 5 plausibly carries this
   same defect on any appointed mid-year switch and is owed a re-check.**
5. 🔴 **A MEMBER'S OWN mgaleg PAGE CAN HIDE PRIOR-CHAMBER SERVICE.** Sara Love's tenure field reads
   only "Senate since June 13, 2024" though the corpus has "Delegate Love" sponsoring from 2019RS —
   so her entire Blueprint-era service fell outside her tenure and the test silently never ran. There
   is now a detector: any session where the corpus shows the surname sponsoring but tenure says
   absent is flagged for reading.

🔑 **Two judgement rules worth keeping.** A near-unanimous vote is not a position — SB1030/2019 passed
the Senate 43-1 then 45-0, so those sheets are recorded and deliberately NOT cited; every vote cited
had ≥10% against. And the bill is chosen by what the CLAIM says, not by what scores best: ranking by
margin picked HB1372 "Revisions" for every childcare row, when the childcare claim lives in HB1300 —
159 × "prekindergarten", 3 × "Child Care Scholarship" in the enacted text, and **none of it in the
synopsis**, which is why the topic clause had to be quoted from the chapter text.

### ✅ (b) THE INSTRUMENT-FREE ROWS — Maryland DONE, migration 1721 applied and verified
The 48 rows left after 1717 are **three different jobs**, only one of which mgaleg can reach:
**MD 35 · CA 11 · VA 2**. The CA and VA rows are NOT unsourced — they already carry council agendas,
leginfo bill pages, congress.gov and news citations, so they need VERIFICATION, not a crawl. ▶ owed.

**MD 35 → 25 re-sourced · 9 left owed · 1 verified unchanged.** Chairs untouched; corpus 33,083/32,542.
Pipeline: `md-member-legislation.mjs` → `md-member-dossier.mjs` → `gen-1721-md-classc-sourcing.mjs`
(+ `md-member-legislation-queue.mjs` for reading, `lib/md-topic-nets.mjs` for the nets).

🔑 **THE CRAWL WAS THE WRONG PLAN.** Fetching every healthcare/housing/rent bill to read its sponsor
list is **4,713 pages, ~86 minutes, and identifies people by SURNAME**. mgaleg will instead list a
member's own sponsored legislation per session — `/Members/Details/<slug>?ys=<session>` — which is
~150 fetches and is mgaleg's OWN attribution, so it cannot mis-credit a surname twin.
🔴🔴 **BUT A MEMBER RECORD IS CHAMBER-SCOPED.** Ask a current senator's record for a session when they
sat in the House and mgaleg returns a page of exactly **56,073 bytes with ZERO bills** — not an error.
Alonzo T. Washington's ten House sessions read as "sponsored nothing". Treating that as absence would
manufacture a false negative for every chamber-switcher, so it is recorded as UNAVAILABLE_SESSION and
those rows are reported **owed**, never absent.
🔴🔴 **THE NETS HAD SUBSTRING COLLISIONS AND THEY REACHED THE TOP OF THE QUEUE.** Before `\b` bounding,
the best-ranked evidence included *"App-**rent**-iceships in Licensed Occupations Act"* for Rosapepe on
housing, *"2nd Lieu-**tenant** Richard Collins Hate Crimes Act"* for Benson on housing, *"**Premium**
Cigar Lounge Alcoholic Beverages License"* for Harris on healthcare, and **rental-car spare-tire bills**
as Kagan's top three housing bills. Same defect as the Socrata "Tran"→"Transportation" pass.
⚠ Word boundaries are not enough — `TOPIC_EXCLUDE` also drops *"Correctional Services – **Restrictive
Housing**"* (solitary confinement), which is a real word match and a nonsense citation.

🔑 **RANK BY LEAD SPONSORSHIP.** Being one of 30 co-sponsors on a consensus bill is weak; leading the
bill is a position. Benson's healthcare net matched 308 bills — unreadable — and lead-sponsorship plus
a tighter core pattern cut it to something that could actually be read.

🔴 **The 9 left OWED, deliberately, rather than sourced to something weak:** 4 × Same-Sex Marriage
(Ellis, Harris, Kramer, Watson — MD settled it in 2012; **Ellis's entire tenure is readable and holds
no such bill**, an absence that evidences nothing because there was nothing left to vote on; Harris's
only hit is a financial-disclosure ethics bill mentioning domestic partners); Harris/Love/Watson on
Healthcare and Watson on Housing (**Watson's health leads are paternity testing and sickle cell —
public health, not coverage**); Muse on Childcare.
✓ Harris/Childcare was **verified already correct** (SB0664 he leads, SB0402 enacted Ch. 641) — no change.

### 🔴🔴 NEW, MUCH LARGER FINDING: "backed Medicaid expansion" IS A NATIONAL TEMPLATE
Every one of the 12 MD healthcare rows said the member "backed Medicaid expansion". Maryland expanded
Medicaid in **2013**, before most of them were seated — so the claim was not merely unsourced, it was
impossible. Querying the corpus for the phrase:
**368 rows · 288 politicians · 44 states · 360 of them with NO bill citation of any kind.**
The 1714 cohort was a slice of this, exactly as pass 6 found the cohort itself was the defect.
▶▶ **This is its own queue and is NOT started.**

**(b-remaining) The CA 11 + VA 2, and the 47 elsewhere — needs the full class-C treatment**: crawl that topic's bill
titles, build the co-sponsor reverse index, match, pick squarely on-topic bills.
Healthcare Access 13 · Affordable Housing 16 · Same-Sex Marriage 5 · Civil Rights 4 · Climate 3 ·
Childcare 2 · Ukraine 1 · Rent Regulation 1 · Misinformation 1.
⚠ **Same-Sex Marriage will not resolve** — Maryland settled it in 2012 and 2012RS has zero usable
bills in the corpus. Expect those 5 to stay unsourced by this route.
⚠ Reuse `md-cr-sponsor-index.mjs`; **add the topic's vocabulary to its `CR` regex first** — the net
IS the extractor, and omitting "religio"/"immigra" already manufactured three false absences once.
2. **The 4 uncalibrated-topic blind spots.** Fossil Fuel Policy, Reproductive Rights, Immigration and
   Voting Rights all scored UNCALIBRATED, so **they were never tested at all** — the true national
   total is unknown and may be larger than 194. Measuring them needs a test that can see the object
   of a verb, which a regex cannot.
3. **Terry Taplin (Berkeley)** was the one non-Maryland member of the batch — worth checking whether
   a second, smaller batch exists in California local rows.
