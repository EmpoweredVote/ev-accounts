# Pre-tenure re-research — tranche 3: all 36 pairs adjudicated

Completes `ADJUDICATION-TRANCHE-1.md` and `ADJUDICATION-TRANCHE-2.md`. The 24 pairs open after tranche 2
are adjudicated here, heaviest first.

**Nothing is written to production. No migration. Every chair in the database is still blank.** The
verdicts live in `affirmative-candidates.json` under `adjudication.verdicts` and in this document.
Applying them is a separate, reviewed step. Next free migration number is **1541**.

| | pairs |
|---|---|
| **chairs supported** | **9** — 4 confirm the retired value, **5 are corrections** |
| blank — two adjacent chairs both fit (SKIP) | 16 |
| blank — no usable evidence at all | 2 |
| blank — **structural scope mismatch** | 4 |
| settled in tranche 1 (climate/fossil, oppositional only) | 5 |
| **total** | **36 · none open** |

## The standard used for assigning a chair

Stated explicitly so it can be argued with, because 5 of the 9 change a stored value:

1. a **sponsorship or repeated original co-sponsorship** — never a late co-sponsorship on its own, which
   the artifact's own rule already flags as driven by courtesy and constituency; **and**
2. a **multi-clause textual match to exactly one chair**, with the adjacent chair's distinguishing clause
   absent or contradicted.

Everything failing that is blank, per the standing rule *"if two adjacent chairs both fit, SKIP"*.

## ✅ Chairs supported

### Guy Reschenthaler / Taxation → **chair 4** (retired 4.0 — confirmed)

84 candidates, and the heaviest pair in the workstream. **Original** co-sponsor of the **Death Tax Repeal
Act** (repeals estate and generation-skipping taxes) and **Main Street Tax Certainty Act** (CRS: *"makes
permanent the tax deduction for qualified business income"*), plus a Yea on H.Res. 1156 endorsing the 2025
tax relief — chairs 1/2/3 contradicted. Chair 4's *"scale back public services"* half comes from the IRS
rescission (H.R. 23, orig-co) and H.R. 564, which rescinds unobligated ARPA funds for deficit reduction.

**Chair 5 is affirmatively absent, and that absence is the finding.** Across 84 candidates there is no
balanced budget amendment, FairTax, flat tax or spending cap, and he expands LIHTC three times,
Neighborhood Homes three times, and supplemental appropriations. Contrast Hyde-Smith, whose BBA
sponsorships made chair 5 fit and forced a SKIP — the same test, opposite result.

⚠ **Stop Inflationary Spending Act is not a spending cut.** CRS: it only requires CBO to project the
inflation impact of reconciliation bills. I had it counted as a services-cut commitment until I read it.

### Val Hoyle / Reproductive Rights → **chair 1** (retired 1.0 — confirmed)

Chair 1 needs legal **+** accessible **+** *publicly funded*. WHPA (orig-co) supplies the first two. The
**EACH Act** (orig-co) is the deciding piece: CRS confirms it requires Medicaid, Medicare and CHIP to
cover abortion, repeals the ACA state opt-outs, and lets premium tax credits pay for abortion. Public
funding is exactly the clause chair 2 lacks.

### Val Hoyle / Affordable Housing → **chair 3** ⚠ (retired 1.0)

She **sponsored** the **DASH Act**, and CRS describes it matching chair 3 clause-for-clause: LIHTC
expansion (*subsidies for affordable projects*), a **$15,000 first-time homebuyer credit** (*first-time
buyer assistance*), and encouraging zoning that promotes multi-family housing (*easier building permits*)
— reinforced by her YIMBY Act co-sponsorship. Chair 1's *"directly build and operate public housing"* is
absent: DASH works through vouchers, credits and grants, not public construction. Chair 2 fails on rent
caps and inclusionary mandates, neither of which appears anywhere.

### Val Hoyle / Campaign Finance → **chair 3** ⚠ (retired 1.0)

Original co-sponsor of the **DISCLOSE Act in two consecutive Congresses** — a donor-disclosure bill, which
is chair 3 (*"require full disclosure of all political donations"*) verbatim. Chair 2 (*"strictly **limit**
corporate donations and dark money groups"*) is not supported: DISCLOSE discloses, it does not limit.
Chair 1's *"ban all private money"* is unsupported; only the Freedom to Vote omnibus touches public
financing. ⚠ Tranche 1 closed this pair as zero-candidate; the affirmative pass re-opened it.

### Val Hoyle / Civil Rights → **chair 2** ⚠ (retired 1.0)

Original co-sponsor of the **Equality Act** and the **ERA deadline removal** — both clauses of chair 2
(*strengthen civil rights enforcement, address systemic discrimination*). Chair 1 requires *"mandate
racial equity requirements in all institutions **and** provide reparations"*: no racial-equity-mandate
bill appears, and her only reparations item is a **late** co-sponsorship of H.R. 40, a commission to
**study** reparations. Studying is not providing.

### Andrea Salinas / Voting Rights → **chair 2** ⚠ (retired 1.0)

She **sponsored** the **Universal Right To Vote by Mail Act**, which CRS describes as prohibiting states
from imposing additional conditions on mail voting in federal elections — chair 2's *"make mail-in voting
available to all voters without requiring an excuse"*, verbatim. Chair 1 requires automatic registration
**and online voting**; her AVR evidence is a late co-sponsorship of an omnibus, and **no bill in the
45,894-file corpus authorises online voting**. A sponsored standalone vehicle outweighs a late omnibus
co-sponsorship — which is precisely why Hoyle's voting-rights pair skips and Salinas's does not.

### Mike Collins / Civil Rights → **chair 5** ⚠ (retired 3.0 — understated by two chairs)

Original co-sponsor of the **Dismantle DEI Act** in two consecutive Congresses.

⚠ **BILLSTATUS carries no CRS summary for either version**, so the title alone would have been the only
basis — and inferring content from a title is the error class this whole audit exists to eliminate. The
text was fetched from govinfo (`BILLS-119hr925ih`). It amends the Civil Rights Act of 1964 to define a
prohibited practice as *"discriminating **for or against** any person on the basis of race, color,
ethnicity, religion, biological sex, or national origin"* — i.e. barring race-conscious measures — and
applies it across federal personnel, training, contracting over $10,000, grants and cooperative
agreements, advisory committees, education accreditation, Fannie/Freddie/FHFA, capital markets and
corporate boards, HHS, DoD, DHS and ODNI, **with a private cause of action**.

That is chair 5, *"eliminate affirmative action and all race-based government programs"*. Chair 4
(*"limit federal civil rights enforcement to clear cases of discrimination"*) understates it: the bill
does not narrow enforcement, it prohibits the practices and creates a new right of action.

**This is the workstream's only correction that makes a member's stored position more extreme, not less.**
The audit's standing worry is over-claiming; here the original research under-claimed.

## Blanks worth reading

### 🔴 Four pairs are unanswerable by construction, not for want of evidence

> **⚠ SUPERSEDED IN PART — see `SCOPE-DECISION.md`.** This section was written before I checked
> `inform.compass_topic_roles`, the platform's live tier model. It settles three of these four with no new
> policy: Transportation Priorities and Economic Development Incentives carry no `federal` role row, so
> `applies_federal=false` and both are *already* filtered off a member of Congress's compass — those three
> pairs are closed permanently. But **Hoyle / State Redistricting has a `federal` role row and is NOT a
> scope problem**; it is an ordinary evidence blank, and calling it a scope failure below was wrong. The
> same check also found two chairs migration 1541 applied are inert for the same reason.

Two topics are **city-scoped questions attached to members of Congress**:

- *Transportation Priorities* — *"Where should **your city** focus its transportation investment?"*, with
  chairs about parking requirements, bike lanes and road capacity. Hoyle's and Salinas's entire federal
  record here is FAA reauthorization, an Airport and Airway extension, a rail worker safety bill, and a
  bill **designating US Route 20 as the National Medal of Honor Highway**.
- *Economic Development Incentives* — *"How should **your city** attract businesses?"*, with chairs about
  municipal tax abatements and community benefit agreements. Kamlager-Dove has **zero** candidates from
  any source, and structurally so.

**Hoyle / State Redistricting** is a third scope failure of a different kind: the topic asks about **state**
redistricting, and her candidates are the Freedom to Vote Act (federal **congressional** criteria) and DC
statehood twice, which is not redistricting at all.

These four should be settled as **policy** — either the topics are out of scope for federal officials, or
the questions need federal-level wording. No amount of further research changes them.

### Matt Van Epps: five retired chairs on an eight-month record

He was seated **2025-12-04**. Every one of his five retired rows asserted chair **4.0**. His entire
affirmative record across all five topics is **five late co-sponsorships, no sponsorships, no original
co-sponsorships**, and the shortlisted roll calls almost all predate him — the service-window guard marks
them "not seated", visibly. His Medicare/Medicaid pair has **zero** co-sponsorships and one Yea on the
**Do No Harm in Medicaid Act**, which CRS confirms prohibits Medicaid payment for gender transition
procedures for minors: a coverage-exclusion bill, entirely off the axis the topic asks about
(*funded and structured*, from expand-to-everyone to phase-out).

All five correctly retired; none restorable. The pattern is the cleanest illustration in the workstream of
what migration 1537 was for.

### Bentz's two pairs both fail, for opposite reasons

- **Healthcare (retired 4.0)** — zero sponsorships; his single original co-sponsorship is an
  abortion-funding disapproval, not an access-axis bill; the other 20 rows are late co-sponsorships. And
  the record points both ways on the same axis: a pre-existing-conditions backstop plus step-therapy,
  copay, prior-auth and Medicare coverage expansions (which cut against chair 4's *"**only** help the
  poorest"*) alongside **H.R. 379**, which nullifies the rule limiting short-term plans that are exempt
  from ACA requirements *including pre-existing conditions*.
- **Taxation (retired 5.0)** — **chair 5 is affirmatively ruled out**: no structural shrink-government
  vehicle, consistent Yea votes on appropriations, and a LIHTC expansion co-sponsorship. But his own
  affirmative evidence is four late co-sponsorships, so chair 4 cannot be positively pinned either.

### Neguse and Salinas on Taxation: the "significantly / moderately" seam

Both retired at 1.0 and both skip, for the reason predicted in tranche 2.

**Neguse** has a genuine large-company increase — original co-sponsor of the **No Tax Breaks for
Outsourcing Act** (country-by-country foreign tax credit limits, interest-deduction limits, inversion
rules). But chair 1 also requires raising taxes on wealthy *people*, and his eight sponsorships are credit
**expansions** (LIHTC, solar, R&D). His only wealthy-individual evidence is a roll-call Aye on H.R. 5377 —
a bill whose main effect was **SALT cap relief, a tax cut concentrated on affluent households**, offset by
restoring the top rate to 39.6%. Chair 1 is partly unevidenced and partly contradicted; chair 2 fails on
*"existing services"* given the American Family Act.

**Salinas** has one original co-sponsorship, the **Assuring Medicare's Promise Act**, which raises the net
investment income tax above $400k and directs it to the Medicare Part A trust fund — funding an
**existing** service, chair 2's clause rather than chair 1's *"more public services"*. One original
co-sponsorship is too thin to change a stored value.

## Two residual gate observations

The tightened mapping is much better but not perfect, and both leaks are visible in this tranche:

1. **Commemorative resolutions carry CRS subjects but no policy content.** Three of Kamlager-Dove's six
   childcare candidates are *"Recognizing January as National Mentoring Month"*-type resolutions, and her
   only *sponsored* childcare item is one of them (National Kinship Care Month). Worth excluding
   `H.Res.`/`S.Res.` bills whose only action is a designation.
2. **A topic term can be the vehicle rather than the subject of contention.** The Do No Harm in Medicaid
   Act matched *Medicaid* exactly and correctly, yet it is a transgender-care coverage exclusion, not a
   Medicaid funding-or-structure bill. Exact subject matching fixed the breadth problem; it does not fix
   aboutness.

Neither invalidates a verdict here — both were caught by reading — but they are the next refinements.

## What is owed

1. **A migration applying the 9 supported chairs**, with the citations recorded in
   `affirmative-candidates.json`. Note that **5 of the 9 change a stored value**, and one (Collins) makes a
   position more extreme; these deserve review before they are written. Next number is **1541**.
2. **A policy decision on the four scope-mismatched pairs** — the two city-scoped topics plus Hoyle's
   state-vs-federal redistricting. They cannot be researched into an answer.
3. The 22 blanks should be recorded as **settled blank with a reason**, not left looking unresearched. The
   `reresearch_worklist` caveat applies: coverage is computed as "has ≥1 answer", so a correctly-blank
   spoke is invisible and will otherwise be re-queued forever.
