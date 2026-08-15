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
