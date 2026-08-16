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

**Scope caveat, important.** "Unreachable" below means *unreachable from legislative sponsorship in
this corpus*. A chair could still be reachable from candidate statements, questionnaires, or floor
speeches. Two of the classes below (UNREACHABLE ELEMENT, INDISTINGUISHABLE PAIR) are properties of
the chair text and probably generalise; the others may be Washington-specific. Flagged per entry.

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
adding crisis response **instead of** adding officers. HB 1435's 23 sponsors include Lauren Davis
(prime sponsor of the enacted domestic violence co-responder grant program) and Greg Nance (behavioral
health co-response training and reimbursement) — legislators who fund **both**, and Washington already
runs "over 60 co-response teams" alongside a statewide officer shortage. They were seated at chair 4
because it is true of them and claims no exclusivity, but nothing on this ladder says what they
actually did. **The fix is to drop "maintain"/"keep current" from chairs 2 and 3**, which would let
the co-response position stand on its own merits instead of requiring a police-funding freeze.
**Generalises?** Yes — co-response has broad bipartisan support in many states precisely because it is
*not* framed as a trade against police staffing.

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

## Useful discriminators discovered (worth writing into the reference)

- **`local-immigration` chair 4 vs 5 = permissive vs directive.** SB 6264/SB 5818 use "may" → chair 4.
  SB 5002 bans sanctuary policies, says agencies "**shall** use best efforts", and requires county
  jails to contract with ICE → chair 5. Clean, textual, repeatable.
- **`rent-regulation` chairs 2-5 turn on rent-control SCOPE only.** Eviction and just-cause bills
  cannot discriminate among them; they bear only on chair 1's third clause.
- **`climate-change` chair 2 vs 3 = a phase-out DATE.** Chair 2 requires "by 2030". Cap-and-invest
  and clean-energy deployment, however aggressive, are chair 3 without a date.
