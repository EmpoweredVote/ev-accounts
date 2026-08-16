# Compass ladder trouble spots — findings from the Washington sweep

**What this is.** A running record of places where a compass ladder could not be used as written,
discovered by trying to seat real legislators against a real corpus. Each entry names the exact
clause that caused the problem and what was actually in the record, so the ladder can be judged on
evidence rather than on impression.

**Why it exists.** The 44 ladders were written before anyone knew what evidence would exist.
Reachability is not a property of a chair's wording alone — it is a property of that wording meeting
a corpus. The Washington sweep is the first time the ladders have been tested at scale against a
complete legislative record (3,411 bills, 147 legislators, 2025-26 biennium), so it is the first time
these can be measured instead of guessed.

📤 **Handoff version for the compass owner** — the five highest-cost chairs ranked by measured blanks,
each with the exact clause, what was in the record, and a concrete proposed rewording:
https://claude.ai/code/artifact/22f2169e-d7f1-4023-9045-b8cd68af8b54
That page is the *prioritised* read. This file remains the *complete* evidence, and is what the
handoff cites.

**Scope caveat, important.** "Unreachable" below means *unreachable from legislative sponsorship in
this corpus*. A chair could still be reachable from candidate statements, questionnaires, or floor
speeches. Two of the classes below (UNREACHABLE ELEMENT, INDISTINGUISHABLE PAIR) are properties of
the chair text and probably generalise; the others may be Washington-specific. Flagged per entry.

---

## The pattern that runs through half of these entries: THE LADDERS DESCRIBE CHANGE, AND MOST LEGISLATING DEFENDS WHAT EXISTS

Written after the sweep had produced 34 documented blanks (**58 as of 2026-08-16**, across 14
ladders), because the same shape kept recurring on unrelated ladders and it is probably the single
most useful thing here:

- `climate-change` — nine senators who want to KEEP the statutory emission targets while opposing new
  state-specific mandates have no chair; every chair moves the policy somewhere.
- `taxes` chairs 4 and 5 — a tax cut must come "and scale back public services to match". Three
  legislators across both parties (Orcutt R, Krishnadasan D, Steele R) proposed cuts and stated no
  service consequence, because bills do not legislate their own consequences.
- `healthcare` — Penner's HB 2331 forbids the health care authority from cutting off life-sustaining
  medicaid services. Chair 3 pairs helping people who cannot afford care with EXPANDING programmes;
  chair 4 says help ONLY the poorest. Defending the current scope is neither.
- `public-safety-approach` chairs 2 and 3 open with "maintain"/"keep current" and then require a
  co-responder trade-off, so wanting both more officers and more crisis response has no chair either.

**A legislature spends most of its effort protecting, funding and adjusting programmes that already
exist.** Ladders built as five points along a direction of travel cannot describe that, and the
result is not neutrality — it is a blank, which reads to a coverage-hungry session as "not yet
researched". If one change were made to the compass off the back of this sweep, it should be to give
the middle chairs a defend-the-status-quo reading rather than a stalled-change one.

---

## Class A — a chair requires an element that has NO instrument anywhere in the corpus

The chair cannot be evidenced for *anyone*, no matter how strong their record. This is the most
actionable class: it is a property of the chair text, not of any politician.

### `civil-rights` chair 1 — requires reparations
> "mandate racial equity requirements in all institutions **and provide reparations**"

Anchored search of all 3,411 bills: **zero** reparations instruments. The nearest thing in the corpus
is SB 5414 (enacted), requiring social equity impact analysis in performance audits and legislative
hearings — which fails *both* of chair 1's clauses (state audits are not "all institutions", and it
provides no reparations). Chair 1 is unreachable for every WA legislator.
**Generalises?** Likely. Reparations legislation is rare in any state corpus.

### `housing` chair 2 — requires inclusionary zoning
> "Use rent caps, **require new developments to include affordable units**, and publicly fund new housing"

Three required elements. Rent caps plainly exist (EHB 1217, enacted, 35 sponsors). Anchored search
finds **zero** inclusionary-zoning instruments in the biennium. So chair 2 is unreachable even for
legislators who enacted statewide rent caps — the strongest possible evidence for its first clause.
**Generalises?** Partly. Inclusionary zoning is usually municipal, not state, so a state-level corpus
may never reach this chair anywhere.

> ✅ **RESOLVED AT CITY LEVEL, 2026-08-15 — and this is the most transferable lesson in the file.**
> Seattle's **MHA is inclusionary zoning**, so the element with zero state instruments is routine
> municipal policy. Dionne Foster holds all three limbs at once: statewide rent stabilization, MHA
> applied to middle housing ("Allowing duplexes, triplexes, and other middle housing types without
> any affordability requirements risks missing an opportunity"), and protecting dedicated affordable
> housing funds. Seated at chair 2 in migration 1784.
> 🔑 **UNREACHABILITY IS A PROPERTY OF A CHAIR MEETING A CORPUS, NOT OF THE CHAIR TEXT ALONE.** The
> "Generalises? Partly" hedge above was right for the wrong reason — the chair is fine, the state
> corpus was the wrong place to look. **Re-test every Class A finding when the corpus changes**, and
> do not carry "unreachable" across a level of government. The scope caveat at the top of this file
> says this in the abstract; this is the first measured instance.

---

## Class B — the ladder cannot describe a real, widely-held position

Not a coverage gap; a mapping gap. The position exists, many legislators hold it, and no chair says it.

### `abortion` — a constitutional right with no funding provision
SJR 8204 (27 seated senators, over half the chamber) would make abortion a **fundamental right with
no limit by stage of pregnancy**. That refutes chairs 2-5 outright — every one sets a gestational
limit or restriction these members demonstrably reject. Chair 2 ("through the second trimester with
rare exceptions") is not a softer version of their position; it is a different one.

Chair 1 is then the only survivor, but it bundles **three** things: legal + accessible + **publicly
funded** at all stages. SJR 8204 is a *negative* right — the state shall not deny or interfere — and
is silent on funding. Result: 9 seated (they also sponsored SB 6182, state grants for direct patient
abortion care), **18 blanked** despite unambiguous, well-documented positions.

**The fix is probably to unbundle funding from legality.** As written, a legislator can support
abortion rights at all stages and land in no chair at all.
**Generalises?** Yes. Any state with constitutional-right politics and no funding statute hits this.

### `childcare` — a subsidy channelled through EMPLOYERS has no chair
> 2 = "Significantly expanding subsidies and provider grants to make childcare affordable for **low- and middle-income families**"
> 3 = "Offering targeted tax credits and subsidies for **families below a set income threshold** while supporting providers through training and facility grants"
> 5 = "Leaving childcare to the private market and families, with **no government subsidies**"

Penner's HB 2187 gives employers a B&O and public utility tax credit worth 50 percent of what they
pay a registered provider for an employee's dependents — a capped five-year pilot, small employers
first, with small businesses encouraged to pool into "child care consortiums". Chair 5 is refuted
because a tax credit **is** a public subsidy. Chairs 2 and 3 aim their subsidies at families, by
income; this one is paid to employers with no income test and no provider grants. Chair 4 is
deregulation, which the act does not do.

Employer-side child care support is a mainstream policy in both parties and it sits in the gap
between "subsidise families" and "leave it to the market". **The fix is a chair for supply-side or
employer-mediated support**, or wording in chairs 2-3 that does not name the recipient.
**Generalises?** Yes — employer child care credits exist in many state codes and in the federal one.

Also worth noting on this ladder: HB 1128 (enacted, 43 sponsors) establishes a child care WORKFORCE
STANDARDS BOARD to set minimum compensation for child care workers, on the finding that low pay has
"resulted in lack of access, unaffordable prices". Labour standards are a third mechanism for the
same goal — cost and availability — and no chair mentions the workforce at all, so a 43-sponsor
enacted instrument reaches nothing.

### `ai-regulation` — no scope axis, so a chatbot rule and an economy-wide framework share a chair
> 3 = "Require AI developers to disclose risks and be held responsible when their systems cause harm"
> 4 = "Require safety testing and **ban** high-risk AI uses in areas like hiring, healthcare, and policing"

Chair 4 is reached only by BANNING. Washington's actual AI legislation does not ban: HB 2225 (enacted,
31 sponsors) regulates one product class with disclosure duties and consumer protection act liability,
and HB 2157 and HB 2667 build economy-wide duties against algorithmic discrimination in consequential
decisions — hiring, healthcare, lending, housing — while expressly intending to "continue to promote
innovation". All three land at chair 3, so a narrow chatbot rule is indistinguishable from a
comprehensive risk framework.

**The fix is a scope dimension, or a chair 4 that reads "require testing and impact assessments for
high-risk uses" without the ban.** As written, the entire middle of AI policy — every risk-based
accountability regime anyone has actually passed — collapses onto one chair, and chairs 4 and 5 are
reachable only by legislation no state has enacted.
**Generalises?** Yes, and it will get worse: risk-based frameworks are the dominant model in the US
and the EU, and none of them bans a use outright.

### `voting-rights` — chair 5 bundles two conditions, so abolishing vote by mail lands at chair 4
> 4 = "require photo ID for voting and regularly update voter rolls to remove inactive registrations"
> 5 = "mandate in-person voting with **strict** photo ID and eliminate mail-in voting **except for military overseas**"

HB 1584 (15 sponsors) would end vote by mail statewide and restore polling places. That is chair 5's
headline, and chair 5 still fails: the act keeps "limited absentee voting" for "those who most need
it" — health care facility residents among them, so wider than military and overseas — and the photo
ID list it accepts includes **student and employer** cards, which is not "strict". The eleven members
who also sponsored the citizenship-verification bill were seated at **chair 4**, whose two mechanisms
they do both hold, but chair 4 says nothing about mail voting at all.

**The tightening half of this ladder therefore cannot distinguish "photo ID and roll maintenance"
from "abolish vote by mail".** The fix is to unbundle chair 5 — the strictness of the ID, the fate of
mail voting, and the exemption list are three separate questions, and no real bill sets all three the
way the chair does.
**Generalises?** Yes. Every state's mail-voting rollback bill keeps some absentee category, so this
chair is unreachable almost by construction.

### `climate-change` — no chair for "keep the targets, without state-specific mandates or new spending"
> 3 = "**invest in clean energy** while gradually reducing reliance on fossil fuels"
> 4 = "let **market forces** drive any transition to cleaner energy sources"
> 5 = "**reject** climate change policies and focus on economic growth instead"

SB 5091 (16 senators) bars Washington from adopting California's motor vehicle emission standards and
requires rules consistent with the **federal** clean air act instead — while finding that
"decarbonizing the transportation sector is achievable and an important objective". That refutes
chair 5 outright, and chairs 1-2 for want of a phase-out. But it invests in nothing (chair 3 fails)
and it swaps one regulator for another rather than deregulating (chair 4 fails). **Six senators were
blanked** whose entire climate record is that bill plus carve-outs from cap-and-invest.

Three others — Boehnke, MacEwen and Dozier — DID hold both limbs of chair 3 from their own records
(clean energy loans, carbon capture, public renewable generation, plus enacted annual accountability
for the RCW 70A.45.020 targets) and were seated there by migration 1772. **The operator blanked them
too, in migration 1773**, because chair 3 put them on the same rung as the 11 Democrats who wrote the
cap-and-invest programme: 27 legislators at one chair, reading as cross-caucus agreement that does
not exist. Chair 3 is doing the work of the entire middle of the spectrum.

**So this ladder currently cannot place ANY of the nine Senate Republicans who were researched on it**
— not the six with only a repeal in their record, and not the three who fund clean energy as well.
**The fix is a chair for "keep existing emission targets but oppose new state-specific mandates"**,
which is the modal minority-party position here and currently maps nowhere. Until it exists, the
honest corpus is nine blanks, which is what is in the database.
**Generalises?** Yes. Any state with a Democratic climate programme and a Republican
repeal-the-mandate caucus produces exactly this pair of unplaceable positions.

### `public-safety-approach` — "more police" and "more crisis response" are mutually exclusive rungs
> 2 = "**Maintain** current police staffing but shift non-violent calls to unarmed mental health co-responders"
> 3 = "**Keep current** public safety funding while adding crisis response teams for mental health and addiction calls"
> 4 = "Increase police staffing, equipment, and pay to improve response times and deter crime"

Both middle chairs open with a freeze on police funding or staffing, so the ladder can only describe
adding crisis response **instead of** adding officers.

**The decisive example is a single enacted act.** ESHB 2015 (2025) funds a grant program for "hiring,
retaining, and training law enforcement officers, **peer counselors, and behavioral health personnel
working in co-response**", paid for by a new criminal justice account and a local option tax. One
instrument, more police AND more co-response, and chairs 2 and 3 rule it out by their opening clause
while chair 4 never mentions co-response. Fourteen legislators sit at chair 4 on an act whose text
they would only half recognise there. No cross-referencing of separate bills is needed to see the
problem — the ladder cannot describe the contents of one statute. HB 1435's 23 sponsors include Lauren Davis
(prime sponsor of the enacted domestic violence co-responder grant program) and Greg Nance (behavioral
health co-response training and reimbursement) — legislators who fund **both**, and Washington already
runs "over 60 co-response teams" alongside a statewide officer shortage. They were seated at chair 4
because it is true of them and claims no exclusivity, but nothing on this ladder says what they
actually did. **The fix is to drop "maintain"/"keep current" from chairs 2 and 3**, which would let
the co-response position stand on its own merits instead of requiring a police-funding freeze.
**Generalises?** Yes — co-response has broad bipartisan support in many states precisely because it is
*not* framed as a trade against police staffing.

### `local-environment` — "trees AND housing" has no chair
> 1 = "Require significant green space, **tree preservation**, and environmental review before approving any development"
> 2 = "Protect existing parks and tree canopy strictly; require developers to **fully offset** any environmental impact"
> 3 = "Apply consistent environmental standards while giving developers **reasonable flexibility** on implementation"
> 5 = "**Remove** local environmental restrictions beyond what state and federal law requires"

Every chair treats canopy as a **duty on development**, varying only in how heavy. Seattle's actual
argument is about **where the duty sits**. Eddie Lin: "We can increase tree canopy by putting more
trees in public spaces, including rights-of-way, **instead of** trying to impose tree retention
burdens on housing", and "I push back against the idea that trees have to be maintained on private
property, and I'm concerned that wealthier neighborhoods are using trees as a way to continue
segregation and stop housing production."

That is *more* canopy and *less* private-lot regulation simultaneously. Chairs 1 and 2 fail because he
rejects the development duty; chairs 4 and 5 fail because he would expand public canopy, not reduce
protection; chair 3 describes flexibility *within* the existing duty rather than relocating it. He was
**blanked** in migration 1784.

**The fix is a chair that separates the LOCATION of environmental obligation from its STRENGTH** — or
wording that does not assume the only lever is a condition on private development. Note this is the
same shape as the `taxes` chair 4/5 problem: the chair bundles a mechanism with a level, and real
politics varies them independently.
**Generalises?** Yes. Tree-canopy-versus-housing is a live fight in every upzoning city, and the
pro-housing side of it is systematically unplaceable here.

> 🔴 **AND THE SAME LADDER FAILS THE OPPOSITE WAY: CHAIR 3 ABSORBS BOTH SIDES OF A DIVIDED VOTE
> (migration 1787, 2026-08-16).** This is the first ladder defect in the file measured from a
> contested municipal **roll call** rather than from sponsorship, and it is the cleanest instrument
> in the corpus for the purpose — a 4-3 vote, one question, nine members, all positions recorded.
>
> Amendment 102 to Seattle CB 120993 (Rivera; adopted 4-3 on 2025-09-18; enacted in Ordinance
> 127376) strikes "cannot" from SMC 25.11.070.A.4.b so that a tree protection area "may be altered
> by the Director", and lets the Director approve modifications that "do not interfere with the
> overall health and stability of the retained tree". Rivera, Saka, Juarez and Hollingsworth voted
> aye. **Strauss voted no — and already sat at chair 3** from Ordinance 126821, the ordinance
> Amendment 102 amends. Seating the four ayes correctly puts all five at chair 3.
>
> Chair 3 is "apply consistent environmental standards while giving developers **reasonable
> flexibility** on implementation". Both sides of this vote hold consistent standards, and both hold
> some flexibility; they disagree about **how much discretion an administrator gets over a
> protection area**, and that variable does not appear anywhere on the ladder. Chairs 1 and 2
> escalate the *duty*; chairs 4 and 5 remove it. Nothing varies *who decides* or *how much slack the
> decider has*, which is the actual axis of municipal environmental politics once a protection
> regime exists.
> 🔑 The failure is not a bundled clause and not a missing chair at an end — it is a **missing
> dimension in the middle**, and it only becomes visible when you have both sides of one vote. A
> corpus built from sponsorship alone would have shown four aye-voters at chair 3 and called it
> agreement.
> **Generalises?** Yes, and it is the general case of the `climate-change` chair 3 problem below:
> wherever a policy regime already exists, argument moves from *whether* to *how much discretion*,
> and a five-point direction-of-travel ladder has no room for that.

---

## Class C — chairs distinguished only by an adverb the record never uses

### `taxes` chair 1 vs 2 — "significantly" vs "moderately"
> 1 = "**Significantly** raise taxes on wealthy people and large companies to fund **more** public services"
> 2 = "**Moderately** raise taxes on wealthy people and large companies to fund **existing** services"

Bills do not characterise their own magnitude. The corpus resolved this (migration 1759) by ruling
that **the chair rests on the DESTINATION of the revenue, not the adverb** — new investment → 1,
preserving existing services → 2. That works and should probably be written into the chair text,
because the adverb currently invites the wrong reading and the destination clause is doing all the
work.

**Refinement forced by ESSB 6346 (migration 1770): a real tax act funds BOTH destinations at once.**
The enacted millionaires' tax states in §1(6) that its intent is to "maintain and preserve essential
governmental services" (chair 2) while its §1 also aspires to free school meals for every child, a
new city and county fiscal health account, and increased K-12 funding (chair 1). It was seated at
chair 2 because none of the chair-1 items has an operative section — the act's Parts IX–XI are titled
TAX RELIEF — but that test only works when the two destinations are unequal in force. **An act that
genuinely funded both existing services and a new programme would not be placeable on this ladder at
all**, and neither would a member whose own record contains one of each (two came up in this cohort:
C. Wilson and Saldaña). The ladder assumes tax policy has a single destination; budgets do not work
that way.

### `taxes` chair 4 vs 5 — the same problem, still unresolved
> 4 = "Cut taxes for everyone **and scale back public services to match**"
> 5 = "**Drastically** cut taxes and **shrink government**"

Both chairs carry a *consequence* clause about public services. Tax-cut bills do not state one.
Ed Orcutt — House Finance ranking member, **eight** primary tax bills including cutting the state
sales tax rate 6.5%→6.0% — was **blanked**, because nothing in his 69 substantive sponsorships pairs
a cut with a service reduction, there is no expenditure-limit bill in his record, and one of his tax
bills *restores* a low-income utility credit.
**Consequence:** the cut side of the taxes ladder may be systematically unreachable for legislators,
which would bias the corpus by party. The destination rule that fixed 1-vs-2 has no analogue here,
because a tax cut's effect on services is a forecast, not a clause.

> ✅ **PARTLY RESOLVED, 2026-08-16 — THE CHAIR IS NOT BROKEN EVERYWHERE, IT IS BROKEN FOR ONE SOURCE
> CLASS (migration 1785).** Reagan Dunn's King County **voters' pamphlet statement** supplies the
> consequence clause four legislators' bills could not. He is "running for re-election to fight
> against new and unnecessary taxes, higher fees, **and government spending at all levels**", will
> "fight to keep your taxes low", and will "prioritize government spending so that **critical
> emergency services and road maintenance** are properly funded" — naming what survives, which is the
> scale-back the chair asks for. Seated at chair 4.
> 🔑 A **bill** cannot legislate its own downstream effect on services, so the clause is unreachable
> from legislation. A **candidate statement** is exactly the genre in which people do state it. Before
> concluding a chair is broken, ask *which source class* was searched — the same correction that
> `housing` chair 2 needed above.

**RESOLVED — it is not a party bias, it is a broken chair (migration 1777).** Deborah Krishnadasan
(D-26) proposed the *same* cut Orcutt did — the state sales tax from 6.5% to 6.0%, SB 5795 — for the
opposite reason: Washington's tax code "remains the second most regressive in the nation" and lowering
the sales tax reduces "one of the key drivers of regressivity". She is unplaceable for exactly the
missing clause that blanked Orcutt. So the ladder cannot describe a tax cut offered as **fairness**
policy any more than one offered as **small-government** policy, and the two blanks sit on opposite
sides of the aisle. **The fix is to drop the consequence clause from chair 4** — "cut taxes for
everyone" is a position people actually hold and legislate; "and scale back public services to match"
is a prediction no bill makes about itself.
**Generalises?** Yes. Every state has sales-tax-cut bills and none of them legislates the service
reduction the chair requires.

> ⚠ **THE CONSEQUENCE CLAUSE IS THE SECOND FAULT, NOT THE ONLY ONE — measured across all four
> blanks, 2026-08-16.** Two of the four (Steele's HJR 4207 homestead exemption, Schoesler's SB 5289
> farm-machinery exemption) fail chair 4 **twice**: no service consequence, *and* a targeted
> exemption is not a cut "for **everyone**". For those two, chair 3 fails as well, and for a reason
> worth stating plainly: chair 3 is "keep the current tax system mostly as-is with small adjustments
> to **close unfair loopholes**", and an exemption **opens** a preference rather than closing one.
> 🔑 So a single farm-equipment exemption bill refutes **four of the five chairs** — 1 and 2 (it
> raises nothing), 3 (wrong direction), 4 and 5 (no consequence, not universal). Targeted exemptions
> and credits are the *ordinary form* of minority-party tax legislating, so the ladder is not merely
> missing a clause at chair 4; it has **no chair for narrowing a specific tax**, which is most of
> what tax politics consists of outside a budget year.
> ⚠ Attribution note for anyone costing this fix: `taxes` carries **6** documented blanks, of which
> **4** are this defect. The other two are unrelated — Juarez (a single recorded No vote on
> JumpStart, no rationale on the rate question) and King County Assessor John Wilson (Class G).

### `judicial-criminal-justice` chair 4 vs 5 — distinguished only by a purpose no penal statute states
> 4 = "Making sure others think twice before doing the same thing."
> 5 = "Punishing the behavior. Society needs to know that breaking the law has real consequences."

Same shape as the taxes pair above, one level worse: both chairs are *purposes of punishment*
(deterrence and retribution), and **penal statutes describe mechanisms, not purposes**. Chair 5's
first clause, "punishing the behavior", is satisfied by every penalty provision in the criminal code
— John Lovick sits at chair 3 holding two penalty-increase instruments — so all the discriminating
work falls on its second clause, which is a claim about the message sent to the public, exactly as
inferential as chair 4's.

**The decisive example is an instrument that names BOTH chairs and ranks neither.** Wagoner's SB 5267
would allow a death penalty charge for aggravated murder committed while already incarcerated. It
directs the review panel to weigh "whether imposition of the death penalty measurably contributes to
the core purposes of **retribution and deterrence** of capital crimes by prospective offenders" —
chair 5's value and chair 4's value, side by side as co-equal criteria — alongside "sufficient
mitigating circumstances to merit leniency" and "fairness and consistency". The most explicitly
purposive criminal instrument in 3,411 bills states both purposes and prefers neither.

Migration 1781 tried to break the tie structurally and seated 12 senators at chair 5; **the operator
reversed it in 1783** and eleven became documented blanks. The twelfth, Boehnke, was seated at chair
**4** — on SB 6083, whose §1 states a prospective "protect the property and persons" rationale. So
the pair *is* discriminable, but only from a stated purpose, and only one instrument among twelve
members' full criminal-justice records had one.

**The fix is to drop chair 5's second sentence and give chair 4 a mechanism.** As written, "punishing
the behavior" is not a position — it is what every criminal statute does — and the sentence that
makes it a position is a forecast about public opinion that no bill makes about itself.
**Generalises?** Yes. Sentencing bills state purposes in almost no state; this pair will blank the
punitive end of every legislative corpus.

---

## Class D — the topic detector files the row against the wrong ladder

Not a ladder-text problem, but it corrupts research if unnoticed.

- **HB 1699 "Defending equity in interscholastic sports"** is a transgender-athlete bill. The word
  "equity" filed it under `civil-rights`. Its operative text belongs to `trans-athletes`.
- **SB 6254 "Leveraging artificial intelligence to improve Washington's regulatory climate"** matched
  BOTH `ai-regulation` and `climate-change`. It is about using AI inside government and belongs to
  neither.
- **Vocabulary vs rationale**: Dhingra's pregnancy-loss dignity, advance-directive, and
  rape-causing-pregnancy sentencing bills all mention pregnancy; none answers the abortion-access
  question. Correctly left off the ladder.

---

## Class E — bill titles and statutory boilerplate that point at the wrong chair

- **"Millionaires tax" (HB 2724)** reads as `taxes` chair 1. Its own §1(6) says the intent is to
  "maintain and preserve" existing services and §202 spends the revenue offsetting sales and B&O tax
  cuts → chair 2.
- **ESSB 6346's own INTENT section points at the wrong chair — one level deeper than a title.**
  Read against the House companion it enacts, the Senate act adds three chair-1-sounding promises to
  §1: breakfast and lunch "for all children served without charge", a city and county fiscal health
  account the legislature "intends to create", and "increase state funding for K-12 education".
  **None has an operative section in the act's 110 pages.** The trap is not the title here; it is
  enacted text that a careful reader would reasonably trust. Read the operative parts and the
  distribution section (§202), then come back to the intent.
- **HB 2367 ends "declaring an emergency"** — Washington boilerplate for immediate effect. `climate-change`
  chair 1 is "declare a climate **emergency**". Title-reading seats it at chair 1 and is flatly wrong.
- **HB 2335 §403** ("necessary for the immediate preservation of the public peace... or support of the
  state government and its existing public institutions") is the standard emergency clause, not a
  pro-government fiscal position.
- **SB 6022 is captioned "improving juvenile rehabilitation" and REPEALS the JR-25 policies outright**
  — the fifth confirmed trap, and the one where the title states the opposite of the operative effect.
  Read against `judicial-criminal-justice` it looks like a chair-1 or chair-3 support limb for its two
  sponsors. Its §1 argues **cost** (approximately $257,000 per incarcerated individual at DCYF against
  $76,000 at corrections) and violence and contraband at Green Hill School. That is an efficacy and
  fiscal argument, not a position on what matters when someone breaks the law, so it reaches no chair
  and supplies no support limb. Also note the inverse: **SB 6083's title agrees with its §1**, and
  that is what made it safe to seat from — a title is not evidence, but a title contradicted by the
  text is a warning and a title corroborated by the text is neither.
- 🔴 **THE SIXTH TRAP IS NOT A TITLE AT ALL — IT IS A NEWS SUMMARY, AND IT IS THE MOST DANGEROUS ONE
  (migration 1787).** Seattle's Amendment 102 reached this workstream through a reputable outlet's
  write-up as an amendment *tightening* tree preservation, and the research question was framed as
  `local-environment` chair 1 versus chair 2 on the full-offset clause. The redline says the
  opposite: its operative move strikes the word **"cannot"** so that a tree protection area **"may be
  altered by the Director"**, converting a prohibition into administrative discretion. The correct
  chair is **3**, which was not among the two under consideration. The amendment does tighten in
  places — Tier 3 trees added to the purpose section, the removal threshold cut from 15 feet to 10 —
  which is exactly why a summary can be accurate sentence by sentence and still point at the wrong
  chair: **a summary reports the changes; a chair is decided by which change is operative.**
  ⚠ A title you can distrust on sight. A summary from a good outlet reads as reading, and the only
  defence is the rule already in this file: open the enacted text before naming a chair.
  ⚠ Second-order trap in the same instrument: the amendment was to **CB 120993**, the zoning
  compliance bill, not to CB 120985, the comprehensive plan everyone was discussing. Amendments 1-53
  belong to one bill and 54-114 to the other. Searching the wrong matter's 43 attachments for
  "Amendment 102" returns nothing, which reads as "not in Legistar" rather than "wrong bill".

---

## Class F — scope questions the reference answers with "usually"

- **`local-immigration` for state legislators.** The generated reference says it is "usually the WRONG
  choice for a federal or statewide official". Used deliberately for WA senators, because SB 6264,
  SB 5818 and SB 5002 legislate on precisely what the ladder asks — whether local law enforcement
  cooperates with federal immigration enforcement. A state legislator writing the statewide rule for
  local agencies is answering that question, not an adjacent one.
- **`transportation-priorities`** carries local framing ("communitywide", "local transportation
  policy") and was NOT used for state legislators, even where road-vs-transit instruments existed.
  The inconsistency between these two decisions is worth a ruling.

---

## Class G — the office EXECUTES the policy rather than choosing it

Not a ladder-text problem and not a research gap: a real class of official who can never hold a chair
on the ladder their job is about. Found across King County's countywide offices (migration 1785).

### The test: **advocacy vs administration**

- **King County Sheriff / `local-immigration`.** KCSO does not honor ICE detainers — and its own page
  presents that as compliance with three **binding** authorities: RCW 10.93.160, **K.C.C. 2.15** and
  General Orders Manual 5.05.000. 🔑 K.C.C. 2.15 is the chapter created by **Ordinance 18665, the very
  instrument that seated Balducci and Dembowski at chair 2** in migration 1754. The councilmembers who
  *wrote* the policy hold the chair; the appointed sheriff who *executes* it does not. Blanked.
- **King County Assessor / `taxes`.** "State law provides 2 tax benefit programs for senior citizens
  and persons with disabilities"; the office processes applications and does not set eligibility or
  thresholds. An assessor values property and applies rates set elsewhere. Blanked.
- **Contrast — King County Elections Director / `voting-rights`, SEATED at chair 2.** Julie Wise
  *requested* prepaid postage for all voters and her push "led to statewide action resulting in
  prepaid postage for all Washington voters in 2018"; she took drop boxes from 10 to over 80 and
  created the Voter Education Fund. **Advocating a change in the law is a position; applying a law
  someone else wrote is not.**

⚠ The trap is that the execute-only official's record *reads* like a strong stance — a sheriff with a
sanctuary policy looks like a chair-1 or chair-2 official. Seating them would double-count the
legislators who actually chose it, and would put words in the mouth of someone who never spoke.
**Generalises?** Strongly. Sheriffs, assessors, clerks, registrars and appointed department heads
exist in every county in the country, and most compass ladders describe legislative choices.

---

## Useful discriminators discovered (worth writing into the reference)

- **`local-immigration` chair 4 vs 5 = permissive vs directive.** SB 6264/SB 5818 use "may" → chair 4.
  SB 5002 bans sanctuary policies, says agencies "**shall** use best efforts", and requires county
  jails to contract with ICE → chair 5. Clean, textual, repeatable.
- **`rent-regulation` chairs 2-5 turn on rent-control SCOPE only.** Eviction and just-cause bills
  cannot discriminate among them; they bear only on chair 1's third clause.
- **`climate-change` chair 2 vs 3 = a phase-out DATE.** Chair 2 requires "by 2030". Cap-and-invest
  and clean-energy deployment, however aggressive, are chair 3 without a date.
