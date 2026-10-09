# Local-tier ladder defects found in the Knight cities stance waves — for Season 3

**For:** Chris Andrews · **From:** the Knight cities stance programme, slices 1–2
**Measured:** 2026-10-02/03 · **Cohort:** 29 city officials — Charlotte NC (12); Bradenton, Miami,
Tallahassee FL (17) · **Result:** 1,015 rows, **7 chairs seated**

Bears on spec [`2026-09-23-stance-program-design.md`](../../docs/superpowers/specs/2026-09-23-stance-program-design.md)
**§4.9** (a ladder can be legally unavailable at a level), **§8.3** (scope is a per-rung question),
**§5.3 / §5.3.1** (local bodies). Programme tracker:
[`knight-foundation/stances.md`](../knight-foundation/stances.md).

> These are **ladder** findings only. Sourcing problems found in the same waves are written up in
> spec §5.3.1 and are not repeated here. Where a ladder worked, that is recorded at the end — the
> ask is not "fix the local tier", it is seven specific decisions.

---

## 1. 🔴🔴 `public-safety-approach` — chairs 1 and 3 do not separate, and this is the costliest defect

**Seven of Charlotte's twelve members spoke substantively on public safety. None could be seated.**
That single ladder suppressed more rows than every sourcing gap in the wave combined.

- chair 1 — *Shift public safety away from policing and toward mental health, housing, and social services.*
- chair 3 — *Keep police as the main responders and add crisis teams to work alongside them.*

A member who **funds both police and prevention** satisfies the spirit of both and the text of
neither. That describes most of this council, and probably most urban councils.

Worked example — Ajmera, on a proposed teen curfew:

> "This conversation is not about criminalizing our youth, it is about keeping our community safe …
> It's about preventing violence, supporting our youth, connecting them with the right resources and
> the right tools before CMPD needs to intervene."

"Resources before police intervene" is chair-1 language; supporting a police-enforced curfew with
supports alongside is chair-3 behaviour. Anderson's *"our youth are really crying out for safe third
spaces"* and Watlington's *"look beyond political theatre to community solutions"* land in the same
gap. All three are real positions and the ladder cannot hold any of them.

**Ask:** can the discriminator be made behavioural rather than directional — e.g. *who responds to a
mental-health call*, which is what chair 2 already does well? If chairs 1 and 3 separated cleanly at
municipal level, Charlotte alone would plausibly go from 5 chairs to 10–12.

---

## 2. 🔴🔴 A rung that describes STATE LAW rather than a position will seat a whole cohort wrongly

The failure mode is not a blank spoke. It is a **confident wrong row**, and it arrives by working
backwards from the observed outcome.

Already recorded for Florida rent control (Miami-Dade, `125.0103(2)`). **Two new instances:**

| Ladder | Rung | Why it is not a position |
|---|---|---|
| `rent-regulation` ch.5 — *oppose rent control entirely* | **Fla. Stat. 166.043(1)(a)** bars municipal price controls | No Florida city has rent control **because it may not**. Seating 5 records a preemption as 17 personal beliefs. |
| `ranked-choice-voting` ch.5 — *ban ranked-choice voting by law* | **Fla. Stat. 101.019** prohibits RCV statewide and voids conflicting local ordinances | Same shape, and newly found this wave. |

A member said it herself. Bradenton's Marianne Barnebey, on short-term rentals:

> "We cannot eliminate Airbnbs, we cannot say where they can operate, we cannot say how many times
> they can be rented during a year, **we have no authority to do that**."

**Ask:** should a ladder carry a machine-readable marker where an extreme rung coincides with a
common preemption, so a wave cannot seat it by accident? `compass_topic_roles` has no per-state
dimension, so today a refusals file is the only place this can live.

---

## 3. 🔴 Compound rungs bundle a position with its legal context

`housing` ch.4 — *Set **no binding rules**, but offer subsidies and tax breaks so more affordable
housing gets built.*

In North Carolina and Florida, "no binding rules" is **the legal default, not a choice** — NC
`42-14.1` bars rent regulation, and inclusionary mandates are unavailable. So any member who
supports housing subsidies drifts into chair 4 by default, and the row silently records a preemption
as a preference. This is defect 2 hiding inside a compound rung, which is harder to catch.

Ajmera is the live case: her record shows $100m in affordable-housing bonds — the subsidy clause —
and nothing at all on the "no binding rules" clause, because it was never hers to decide. **Blanked.**

**Ask:** can compound rungs be split, or the legal-context clause dropped from the rung text?

---

## 4. 🔴 One municipal statement reads on three ladders, and nothing says which owns it

Miami Mayor Higgins, on permitting:

> "I secret-shopped both systems … The county's project was permitted in 107 days. The same project
> submitted the same week to the city took over a year and a half. We're literally keeping people
> out of housing."

That is simultaneously:

- `growth-and-development` ch.3 vs ch.4 — welcome steady growth, or actively push faster by cutting red tape
- `housing` ch.5 — *cut the regulations and zoning limits that block private building*
- arguably `economic-development`

A permitting-speed statement is the single most common substantive thing a city official says, and
three ladders claim it. **Blanked**, because nothing in the standard resolves the overlap.

**Ask:** is there an ownership rule, or should the local tier have one permitting/process ladder?

---

## 5. 🔴 `local-immigration` spans two different offices

- chairs 1, 2, 4 turn on **ICE detainers** — served on the county sheriff's jail
- chairs 3 and 5 turn on **local police policy** — the city's lever

For a city council member, three of five rungs belong to a different elected official. Combined with
the statutory floor (FL `908.103`, NC `160A-205.2` both bar sanctuary policies, removing chairs 1–2),
a Florida or NC city official has **chair 3 or chair 5, and nothing else**.

It is still answerable — this is the one place the ladder worked, see below — but a ladder whose
rungs sit at two offices cannot be answered cleanly by either.

**Ask:** should the detainer rungs be scoped to `county` and the police-policy rungs to `local`?

---

## 6. ⚠ `climate-change` is a national energy ladder asked of city officials

Its rungs are mandates, subsidies, permitting reform, neutrality, ending subsidies. **Cities act on
heat, tree canopy, stormwater and resilience.**

WFAE ran a 2025 candidate survey explicitly on *"climate change and environmental health"* and got
substantive written answers from two Charlotte members — cool roofs, canopy restoration in Steele
Creek and Nations Ford, shaded transit stops, energy-efficiency retrofits. **None of it touches any
rung.** Substantive evidence answering a different question seats nothing.

Note the near-miss this creates: those answers fit `local-environment` well, but the survey is
branded "climate", so a researcher looking for climate evidence finds plenty and can seat none.

Ajmera is the exception that shows the shape — she seats chair 1 only because she chaired the
environment committee and set a **dated, binding** 100%-carbon-free-by-2030 target for city
operations. That is a mandate with a deadline, which is a rare thing for a city to have.

**Ask:** does the local tier need its own climate ladder, phrased in municipal levers?

---

## 7. ⚠ Eight `education-*` ladders are offered at `local` and no city council can answer any

`education-curriculum`, `-library-books`, `-gender-identity`, `-equity-programs`, `-school-police`,
`-charter-authorization`, `-school-budget`, `-ai` all carry a `local` role. Schools in all four
cities are run by separately elected **county** school boards.

That is **8 of the 35 local topics — 23% of the local set — an automatic scope blank for every city
council member in the programme.** Spec §5.3 already says school boards are skipped as a cohort
until the badge ships, so these rungs currently have no one to answer them at this tier.

**Ask:** should `education-*` carry a `school` role only, and drop `local`?

---

## 8. 🔴🔴 There is no ladder for TENANT PROTECTION — `rent-regulation` is a price ladder, and a whole city's divided record falls through the gap

**Added 2026-10-05 from slice 3 (Duluth MN). This is defect 1's shape in a different place: a real,
contested, well-documented municipal position with no chair to sit in.**

Duluth City Council's housing record in 2025–26 is almost entirely about **habitability and eviction**,
not about rent:

| Instrument | Date | Tally |
|---|---|---|
| 25-015-O — *Tenant Right to Repair*, a citizens' petition ordinance (repair, deduct up to $500 or half a month's rent) | 2025-07-01 | **failed 2-6**, then went to the Nov 2025 ballot |
| 25-016-O — the council's own Ch. 29A alternative (landlord training, tenant notification, repairs in 14 days) | 2025-07-01 | **passed 6-2** |
| 26-0105R — call on the Governor for a temporary eviction moratorium + $50M rental assistance | 2026-02-23 | **failed 7-2** |

Three divided votes, all single-subject, all within term, all reported by the daily paper with the
members named — **the best record evidence the Knight programme has found in a city so far.** The
`rent-regulation` ladder cannot hold any of it, because every rung is about **price**:

- 1 *Expand rent control to cover all rental units communitywide*
- 2 *Strengthen existing rent stabilization and extend coverage to more units*
- 3 *Maintain current tenant protections while allowing market rents for new construction*
- 4 *Limit rent regulations to subsidized units; allow market rents broadly*
- 5 *Oppose rent control entirely; rents should be set by the market without government intervention*

Only chair 3 names tenant protection at all, and it names it as a **subordinate clause** of a position
about new-construction rents. Duluth has no rent control of any kind, so chairs 1, 2 and 4 describe
nothing that exists there, and chair 5 is contradicted by the council unanimously *adding* tenant
protections.

**The campaign itself said the two subjects are different.** Asked directly, at a public forum, whether
right-to-repair was a precursor to rent control, the organiser answered:

> "This is not rent control. And I'm here today to talk about the 'Right to Repair' policy, which is a
> common-sense tool to support renters getting the repairs they need in their homes."

🔴 **The failure mode is specific and dangerous.** Working backwards from "voted against a tenant
measure" seats the six who voted no at chair 5 — *oppose rent control entirely, no government
intervention* — when **five of those six voted the same night to ADD tenant protections**, and one of
the two who voted FOR the tenants' ordinance voted AGAINST the council's. A price ladder reads a
habitability vote exactly backwards.

**Ask — one of two, and they are not equivalent:**
1. **A `tenant-protections` ladder at `local`**, whose rungs are enforcement mechanisms — who acts
   when a repair is not made, and at whose risk: tenant self-help with rent deduction · a city
   inspection-and-order regime · landlord licensing conditions · state-law remedies only (escrow and
   the courts) · no local role. Those five are five real municipal positions, each with an instrument
   behind it in some city, and Duluth's three votes separate cleanly across them.
2. **Or widen `rent-regulation` chair 3** so tenant protection is the position rather than the
   subordinate clause — cheaper, but it collapses two genuinely different questions into one chair and
   leaves the other four rungs still unreachable in any city without rent control.

⚠ **This is not a Minnesota problem.** Charlotte reached the same wall from the other side: NC
§42-14.1 bars rent regulation outright, so `rent-regulation` was a scope blank there — and Charlotte's
tenant-habitability record, if it has one, was never looked for, because no ladder asks for it.

---

## What worked — the ask is not "fix the local tier"

Five ladders seated cleanly, and they share a shape: **a concrete municipal lever, and rungs that
differ by what the officeholder would actually do.**

| Ladder | Seated | Why it worked |
|---|---|---|
| `transportation-priorities` | 2 (Owens, Mazuera Arias) | Rungs differ by what gets funded. *"We cannot pave our way to prosperity"* lands unambiguously on ch.1. |
| `data-centers` | 1 (Ajmera) | Only one rung describes a moratorium, and she called for one. |
| `residential-zoning` | 1 (Johnson) | Rungs differ by **where** density is allowed, which is exactly how councils argue it. |
| `local-environment` | 1 (Gonzalez Moore) | Rungs differ by how much flexibility development gets — *"It's not a blank check. It is a high standard."* |
| `local-immigration` | 1 (Higgins) | Despite defect 5: *"We are going to comply with the law, but we are not going to help beyond that"* is ch.3 verbatim. |

**The pattern worth generalising:** a local ladder works when its rungs are distinguished by a
*decision the officeholder makes*, and fails when they are distinguished by a *degree of
philosophical commitment*. `public-safety-approach` fails on exactly that test; `residential-zoning`
passes it.

---

## Summary of the nine asks

1. Make `public-safety-approach` chairs 1 and 3 separable behaviourally — **highest value by far**.
2. Mark rungs that coincide with common state preemptions, so they cannot be seated by accident.
3. Split compound rungs, or drop the legal-context clause.
4. Give an ownership rule for permitting/process statements across `growth-and-development`, `housing`, `economic-development`.
5. Re-scope `local-immigration`: detainer rungs to county, police-policy rungs to local.
6. Consider a municipal climate ladder phrased in city levers.
7. Re-scope `education-*` to `school` only.
8. Add a `tenant-protections` ladder at `local`, or widen `rent-regulation` chair 3 — **second highest
   value**: three divided, single-subject, well-reported Duluth votes seat nobody, and reading them on
   the price ladder gets six members exactly backwards.

## 9. ⚠ `childcare` at `local` is a FUNDING ladder, and a city's lever is ZONING

**Added 2026-10-05 from slice 3 (Duluth MN).** All five rungs are about public money: universal
public funding · expanded subsidies and provider grants · targeted tax credits below an income
threshold · support limited to the lowest incomes · none at all. Those are state and federal levers.

What a city actually does, and what Duluth did, is **zoning**. Council Vice President Lynn Marie
Nephew, speaking for an ordinance opening childcare facilities to more neighborhoods:

> "There are **limited things we can do** to support our childcare providers and one thing we can do
> is **actually zoning**. … What this is going to do is open up zoning to a variety of different
> neighborhoods and hopefully create some more community daycare or childcare facilities in the
> neighborhoods for parents to bring their kiddos to."

She names the problem herself: the city's levers here are limited, and the one it has is not on the
ladder. A member who acts on childcare supply therefore reads as having no position on childcare.

**Ask:** either add a supply rung at `local` — zoning and licensing that let childcare open in more
places — or re-scope `childcare` to `state` and `federal`, where its five rungs are real choices.
⚠ This is **not** the same as defect 7 (`education-*` at `local`), where no city lever exists at all.
Here a lever exists, is used, and the ladder cannot see it.
9. Give `childcare` a supply rung at `local`, or re-scope it off `local` — its five rungs are all
   public money, and the lever a city actually has is zoning.
