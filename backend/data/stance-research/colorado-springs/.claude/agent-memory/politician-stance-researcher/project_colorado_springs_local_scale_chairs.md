---
name: project_colorado_springs_local_scale_chairs
description: How Nancy Henjum's CPR/KRCC questionnaire mapped (and didn't map) onto the 22-topic Colorado Springs local scale
metadata:
  type: project
---

Ran Nancy Henjum (Council D5) against `scale-local.json`'s 22 topics using only
`sources/cpr-2025-henjum.md` (tier 1) plus unsuccessful WebFetch attempts (see
[[project_colorado_springs_web_sourcing]]). Result: 3 of 22 topics seated, 19 skipped. Output at
`backend/data/stance-research/colorado-springs/out-henjum.csv`.

**Seated:**
- `growth-and-development` = 2 (allow growth only where infrastructure can support it). Her
  annexation answer is the brief's own worked example — opposes distant "flagpole" annexations
  over infrastructure/water/safety limits while accepting logical-extension annexations. Clean fit,
  strong quote.
- `residential-zoning` = 2 (modest density + strong neighborhood input). Her ADU answer explicitly
  balances "property owners should be able to develop... within the limits of... zoning" against
  "neighbors have a right to be concerned about changes." Clean fit, strong quote.
- `public-safety-approach` = 4 (increase police staffing). She states the department needs ~200
  more sworn officers than authorized strength allows and wants to find funding for it. Usable but
  weaker gate pass (starts as "I'd like to begin a conversation" — hedgy) — kept because the
  substantive claim ("we really need an additional 200 sworn officers") is a clear forward
  position, not just a resume item.

**Skipped despite having relevant text — worth remembering the reasoning, not just the verdict:**
- `homelessness-response` — she writes at length about the city's 2025 Homelessness Response
  Action Plan, emphasizing outreach/shelter/prevention/employment/housing strategies and champions
  a fire-department-run outreach program (HOP). But she never mentions encampment enforcement or
  camping ordinances at all, and her one gesture at enforcement is the vague "we must approach the
  challenge in a way that embraces both public safety and compassionate response" — this genuinely
  fits chairs 2 and 3 equally (both are service-heavy with enforcement mentioned differently by
  sequencing). Per brief rule, ambiguity between adjacent chairs = skip, not a tiebreak down to
  the "least extreme" option.
- `homelessness` (the criminalization-focused sibling topic) — same source material, same problem:
  no statement on camping bans / right to sleep in public at all. Skip.
- `housing` (Affordable Housing funding ladder) — her only housing-adjacent lines are "the city of
  Colorado Springs is not a direct provider of housing, we...partner with...non-profits" (in a
  homelessness context, not a general affordability policy) and ADU-related comments that really
  belong to `residential-zoning`. Too tangential to seat a chair about rent caps/subsidies/public
  housing/deregulation.
- `campaign-finance` — "I...am running a grassroots campaign while accepting no campaign donations
  from developers" is a personal fundraising pledge about her own campaign, not a stated position
  on what rules SHOULD govern political money generally. None of the 5 chairs describe a candidate's
  own fundraising practice, so this doesn't seat.
- `transportation-priorities` — the questionnaire's only transportation-adjacent content is about
  class-1 e-bikes on parks/trails (a TOPS-ordinance access question), not roads/transit/parking
  investment priorities. Different axis, doesn't transfer.
- `local-environment` — wildfire mitigation funding (post-Waldo Canyon) is public-safety/disaster
  prep, not a development-vs-green-space tradeoff. Doesn't map to this ladder's language (tree
  canopy, environmental review, fees-in-lieu).
- No local record at all (as the brief predicts for this cohort): abortion, civil-rights,
  climate-change (her CSU utility-board answer is governance-model description, explicitly excluded
  by brief rule 4 — "serving on a board is not a stance"), data-centers, fossil-fuels, jail-capacity,
  local-immigration, religious-freedom, rent-regulation (also likely CO-state-preempted for cities),
  trans-athletes, childcare, city-sanitation, economic-development.

Takeaway for the next candidate in this cohort: a rich single-source questionnaire (~20k chars)
still only cleanly seats about 3/22 topics once the "which specific chair" bar is applied honestly.
Don't feel obligated to pad output — a lot of real, substantive text is still off-axis or
ambiguous-between-adjacent-chairs for this specific ladder.

## David Leinweber (At-Large 2, 2023 CPR questionnaire) — second data point, confirms the pattern

Ran against `sources/cpr-2023-leinweber.md` (tier 1) + `sources/cpr-2023-atlarge-overview.md`
(leads only) + a few WebFetch attempts (all thin — see [[project_colorado_springs_web_sourcing]]).
Again landed at 3/22 seated. Output at `out-leinweber.csv`.

**Seated:**
- `growth-and-development` = 3 (plan proactively / invest in infrastructure ahead of growth). He
  explicitly frames the 128%-of-demand water/annexation ordinance debate as needing more
  data-gathering, community engagement, and *regional* coordination before proceeding — not a
  blanket capacity gate (2) and not voter-approval growth limits (1); he separately says growth is
  "inevitable" and wants to "keep the momentum going," ruling out 1.
- `homelessness-response` = 2 (services/shelter primary, enforcement only after/incidental). His
  answer is 100% services-framed ("hand up not hand out," pathways to mental-health care) with
  **zero** mention of camping/encampment enforcement either direction. His explicit rejection of
  unconditional "hand outs" rules out chair 1 (no-preconditions housing-first); silence on
  enforcement made 2 the more defensible read over 3 (which requires an enforcement component he
  never states) — don't invent the enforcement clause just because 3 sounds more "balanced."
- `transportation-priorities` = 3 (selectively add transit/pedestrian where it fits). His own
  language is "neighborhood by neighborhood," explicitly declines to call bike/ped a "primary
  focus" even when the survey question asked directly, plus concrete evidence of selectivity: he
  supports regional Front Range Rail (yes) but opposed extending Constitution Ave (no).

**Skipped — new reasoning not yet logged for Henjum, useful going forward:**
- `climate-change` — candidate has a "Yes" quick-response to "is the city adequately addressing
  climate change" PLUS a CSU-utility-board comment about the green-energy-portfolio transition.
  Tempting to read that combo as chair 3, but the quick-yes is direction-only with no magnitude,
  and the utility comment is board-governance description explicitly excluded by brief rule 4. Two
  weak signals do not average into one strong one — skip.
- `housing` (Affordable Housing funding ladder) — candidate has real, elaborated infill-development
  language ("intentionally plan for more attainable housing" via infill) but infill is a *land-use*
  tool, not one of the ladder's fiscal/regulatory levers (public housing / rent caps+inclusionary /
  subsidies+permits / deregulation / hands-off). Reads as roughly 3-or-4 with no way to pick — skip
  rather than guess from the reporter's overview paraphrase ("policy driven approach" is a lead, not
  a citable stance).
- `residential-zoning` — same infill language, "where it makes the most sense" is too generic to
  name a specific zoning mechanism (ADUs, upzoning-by-right, parking minimums, community-vote
  triggers). Distinguish from Henjum, whose ADU answer *did* name a mechanism and seated cleanly.
- `local-environment` — the "Palmer's vision" answer commits to protecting parks/greenways/open
  space as "necessary" while accepting growth, which plausibly reads as chair 2 (protect strictly)
  or chair 3 (consistent standards + developer flexibility) with no textual way to choose — skip.
- `public-safety-approach` — extensive material on trust/training/accountability/LETAC but **never
  a funding-level statement** (no redirect, no staffing increase, no budget-priority claim) — this
  ladder is specifically about budget allocation, so process/culture answers don't seat regardless
  of length. Contrast with Henjum, who gave an explicit staffing-number ask and seated at 4.
  Reasoning-quantity is not a proxy for chair-specificity — check what axis the ladder is actually on.
- `economic-development` — his answer is entirely about K-12/employer workforce-alignment, not
  about tax incentives/abatements at all. Off-axis, not ambiguous — genuinely no signal on the
  incentive-structure axis this ladder asks about.

## Brian Risley (At-Large 3, 2023 CPR questionnaire) — third data point

Ran against `sources/cpr-2023-risley.md` (tier 1) + overview (leads only) + two confirmatory
WebFetch dead-ends (see [[project_colorado_springs_web_sourcing]]). Landed at 5/22 seated — best
yield of the three so far, because he happens to answer growth/housing/transportation/public-safety
questions in unusually concrete, mechanism-naming terms. Output at `out-risley.csv`.

**Seated:**
- `economic-development` = 1 (no incentives; organic growth via public services). He explicitly
  says government should stick to core services and "limit government overreach into the realm of
  private business" rather than compete on incentives — the clearest of the three candidates on
  this axis (Leinweber and Henjum both had nothing usable here).
- `housing` = 4 (deregulation/supply-side). Names the actual levers: faster permit review, lower
  land-development-code financial burden, density/infill — no rent caps, no subsidy program, no
  public housing. First candidate in this cohort where `housing` (as opposed to `residential-zoning`)
  seated cleanly on its own fiscal/regulatory axis rather than collapsing into the zoning topic.
- `public-safety-approach` = 4 (increase staffing/funding). Weaker than Henjum's explicit
  "200 more sworn officers" ask, but still a real funding-level claim — "policies that support
  funding of police, fire and emergency management efforts will be key" — plus an officer-retention
  problem he attributes to public disrespect. Passes the bar Leinweber's answer failed (culture/trust
  talk with *no* funding-level statement at all).
- `residential-zoning` = 2 (modest density, ADU-scale). He names the actual mechanism — "tiny homes,
  additional dwelling units... where appropriate" — matching chair 2's own example items
  (duplexes/accessory units) rather than the broader "multifamily near corridors" of chair 3.
- `transportation-priorities` = 3 (roads stay primary; add transit/ped selectively where density
  supports it). Near-verbatim match: he says active-transportation expansion "should be encouraged
  where it makes sense" in "densely populated areas" — almost the ladder's own wording ("where
  density supports it").

**Skipped — new reasoning, notably a reversal from the growth-and-development pattern:**
- `growth-and-development` — despite a long, substantive answer (defines "sustainable growth" as
  aligning development with resource capacity, praises the newly adopted city/county master plans
  as the framework for "smart growth"), it genuinely straddles chair 2 ("we cannot outgrow our
  resources," capacity-gated) and chair 3 (master plans = proactive infrastructure planning) with
  no textual tiebreaker — he never says "invest ahead of growth" (3's literal mechanism) nor "slow
  approvals" (2's literal mechanism). **Contrast with Henjum (seated at 2, clean annexation example)
  and Leinweber (seated at 3, explicit "keep the momentum going" + regional-coordination framing)**
  — this is the first of three where the same topic that seated for both predecessors had to be
  skipped for the third candidate on the same general subject matter. Lesson: don't assume a topic
  that seated for two prior candidates in a cohort will seat for the next one just because they
  discuss the same subject at length — check the specific mechanism words each time.
- `climate-change` — only a bare "Yes" to "is the city adequately addressing climate change," no
  elaboration. Same dead end as Leinweber's identical quick-response question.
- `homelessness` / `homelessness-response` — his answer is root-cause/nonprofit-framed (drug
  addiction, mental illness, "the City should encourage their efforts") with **zero** mention of
  camping, encampments, or public-space enforcement either direction — even more silent on the
  enforcement axis than Henjum's or Leinweber's answers were, so no defensible chair on either
  sibling topic.
- `rent-regulation` — never mentioned; his supply-side housing framing doesn't imply an explicit
  rent-control position (resist the temptation to back-infer chair 5 "oppose rent control entirely"
  from general market-oriented rhetoric — that's exactly the "least extreme option" trap the brief
  warns against).
- `local-environment` — the "Palmer's vision" answer ("we have balanced preservation... with the
  need to grow") is pure sentiment with no mechanism (no tree-canopy mandate, no fees-in-lieu, no
  review requirement) — same class of skip as Leinweber's version of this answer.
- No local record at all: abortion, campaign-finance (donor-disclosure Q ≠ a campaign-finance
  policy stance), childcare, city-sanitation, civil-rights, data-centers, fossil-fuels (no CSU
  rate-case/generation-plan vote found), jail-capacity, local-immigration, religious-freedom,
  trans-athletes.

## Dave Donelson (Council D1, 2025 CPR questionnaire) — third data point, lowest yield yet (3/22)

Ran against `sources/cpr-2025-donelson.md` only (tier 1); `coloradosprings.gov` D1 bio page and
Ballotpedia both confirmed dead/empty again (bio-only page, empty Ballotpedia fetch — see
[[project_colorado_springs_web_sourcing]]). Output at `out-donelson.csv`. No new source found —
this cohort's tier-1 questionnaire remains the only productive source type.

**Seated:**
- `homelessness` = 5 (ban public camping/sleeping with criminal penalties, rely on EXISTING social
  services). He explicitly backs expanding the "No Sit/Lie" ordinance and says the city should be
  "the least convenient city in Colorado ... to live in the parks and on the streets," directing
  people who want help to an existing nonprofit (Springs Rescue Mission) rather than proposing new
  city-funded shelter. The "existing services, not new capacity" detail is what separates this from
  chair 4 (which requires the jurisdiction to *maintain* shelter options as part of the deal).
- `homelessness-response` = 4 (enforcement-primary + basic outreach) — same evidence, different
  ladder: this one's chair 4 just needs "basic outreach programs" maintained alongside enforcement,
  which the Rescue Mission referral satisfies, without needing the "existing vs. new capacity"
  distinction chair 5 requires on the sibling topic. Two different values from one quote is correct
  here — the ladders ask genuinely different things, not a restatement of the same axis.
- `residential-zoning` = 1 (protect character strictly, votes before rezoning). He personally
  drafted and gathered 6,000+ signatures for a ballot initiative to let citizens vote on a downtown
  building-height limit, and states the general principle: "For significant changes to the
  character of our downtown, our city, I think allowing citizens to vote on those changes is the
  right thing to do." Scope caveat logged honestly in the row's reasoning: his stated proposal was
  downtown-height-specific, not literally "any rezoning" — chair 1 is still the best available
  textual match and no more-permissive chair fits what he actually proposed.

**Skipped — new reasoning:**
- `growth-and-development` — genuinely conflicting signals across THREE chairs from one answer: he
  wants BLR annexation built out (pro-growth), ties it to wastewater infrastructure catching up
  first ("the limiting factor... being addressed" → chair 2 or 3), AND separately wants voter
  approval on major downtown character changes (→ chair 1). Unlike Henjum/Leinweber's 2-chair
  ambiguity, this spread across 1/2/3 is a stronger skip signal — no single chair captures the full
  position without dropping a piece of it.
- `public-safety-approach` — he calls "soft on crime" *state legislation* the top public-safety
  issue (auto theft, reduced penalties) and separately frames the No-Sit/Lie expansion as "giving
  CSPD another tool." Neither is a statement about local police BUDGET/staffing allocation, which is
  what this ladder asks — state-law criticism and one ordinance-enforcement mention don't transfer
  to a budget-priority chair. Contrast Henjum (explicit staffing-number ask, seated at 4).
- `campaign-finance` — "I do not take developer money - my opponent does" is the same self-pledge
  pattern as Henjum's row: a personal fundraising claim, not a stated rule for what campaign-finance
  law should require of everyone. Fails the FORWARD gate too (résumé/contrast framing, not a "should").
- `transportation-priorities` — his only transportation-adjacent material is opposing an e-bike
  ordinance's definition trick on TOPS trails (should have gone to a citizen vote). That's a
  TOPS-access/process question, same off-axis pattern Henjum hit with the identical e-bike topic —
  not a roads/transit/parking investment-priority statement.
- `local-environment` — his wildfire-evacuation-modeling concern (density near Waldo-Canyon-type
  choke points) is public-safety/disaster-prep reasoning, not a development-vs-green-space tradeoff;
  same distinction as Henjum's wildfire-funding skip on this same topic.
- `city-sanitation` — only line is the vision-statement "make our city cleaner and safer" — direction
  only (more sanitation good), zero magnitude/mechanism (staffing levels? enforcement? privatization?
  underserved-neighborhood priority?). Classic "tiebreaker not evidence" trap — skip.
- No local record at all: abortion, civil-rights, climate-change (CSU-board governance comments
  again explicitly excluded by brief rule 4 — he argues the board *structure* is good, never a rate
  case or generation-mix vote), data-centers, fossil-fuels, housing (affordable-housing ladder — his
  apartment-density comments belong to residential-zoning, not fiscal/subsidy tools), jail-capacity,
  local-immigration, religious-freedom, rent-regulation, trans-athletes, childcare,
  economic-development.

Running total for this cohort: every candidate so far lands at 3/22 seated. Don't read that as a
target to hit or a floor to defend — it's just what one KRCC/CPR questionnaire honestly supports
once "which specific chair" is applied. A 4th or 5th topic seating on a future candidate should come
from genuinely stronger evidence in THEIR questionnaire, not from stretching to match this pattern.

## Second-pass addendum (2026-08-21) — added via coloradosprings.gov/news + koaa.com

Coordinator flagged that `coloradosprings.gov/news` carries the 2024-2026 governing record invisible
to the KRCC questionnaires, and asked me to re-check homelessness, city-sanitation, data-centers,
local-immigration, and climate-change/fossil-fuels (CSU board votes). Result: **1 new topic seated**
(`local-immigration` = 2, taking Henjum from 3 rows to 4), the rest confirmed still unseatable —
now with much higher confidence since it's a documented absence, not just an unchecked topic:

- **`local-immigration` = 2 — NEW.** A council resolution declaring "Colorado Springs is not a
  sanctuary city for migrants" passed 6-3; Henjum was one of the 3 no votes, quoted directly:
  "We don't put blockades on I-25 and say who can and can't come into our city. When people come,
  they will be served." (KOAA, James Gavato). This is vote + her own on-the-record reasoning —
  exactly the evidentiary bar the brief wants. Landed on chair 2 (comply only with court-ordered
  detainers / protect victims-witnesses) rather than chair 1 (refuse all detainers, prohibit all
  info-sharing) because her quote is a values statement about not turning people away, not a
  specific pledge on detainer mechanics — chair 1 would have been reading more into it than it
  says.
- **`homelessness` / `homelessness-response` — STILL SKIPPED, now for a sharper reason.** Found
  the actual missing piece the coordinator hoped would resolve the chair-2-vs-3 ambiguity: Henjum
  voted NO on a sit-lie-ordinance expansion (an enforcement-increasing measure) in a 2-vote series
  covered by KOAA. But every article covering that vote gives her name and the tally only — zero
  attributed reasoning, unlike Avila, Talarico, and Donelson who all got quoted on the same vote.
  A bare vote without her own policy language still doesn't seat a chair (same rule as the
  land-use carve-out). Don't keep re-searching this specific vote — three separate KOAA articles on
  it were checked and none quote her.
- **`city-sanitation` (KICAS) and `data-centers`** — confirmed absent by name on both the city's
  own Aug-2026 news items (which quote Mayor Mobolade and, for KICAS, Councilmember Brandy Williams
  — but not Henjum) and by koaa.com search combos ("Henjum KICAS", "Henjum data centers") returning
  no relevant hits. Genuinely no record for this person on these two topics as of this pass.
- **`climate-change` / `fossil-fuels` (CSU rate case angle)** — re-checked per the coordinator's
  suggestion that a specific rate-case/generation-plan vote with reasoning would be admissible
  (unlike the excluded governance-model description). Found only one more CSU-adjacent quote (a
  KOAA one-on-one interview): "people come to us as city council and ask us to keep the rates low,
  and I really get that" — still just affordability framing, no mention of a specific rate case,
  generation mix, or fossil-fuel/renewable decision. Still not seatable.
- **A single-question-and-answer news interview can also fail the land-use/quasi-judicial-style
  test even outside zoning**: the same KOAA one-on-one has Henjum touting, as her proudest
  accomplishment, permanently killing a 20-year-old proposal to extend Constitution Avenue to I-25
  — a real transportation decision — but her own framing of it is entirely about the *process*
  ("gather neighbors, listen to their concerns... make that decision as a full council") not about
  a general roads-vs-transit-vs-pedestrian investment philosophy. Treated as a single infrastructure
  project outcome, not a `transportation-priorities` policy statement — same logic as the brief's
  land-use carve-out even though this isn't literally a zoning vote.

Running total for Henjum: 4/22 topics seated (growth-and-development, residential-zoning,
public-safety-approach, local-immigration). File: `out-henjum.csv`.

## Lynette Crow-Iverson (At-Large 1, NO questionnaire response) — 2/22 seated, entirely from web
## sourcing, see [[project_colorado_springs_web_sourcing]] for the source-discovery detail

`sources/cpr-2023-crow-iverson.md` is "Candidate did not respond to survey" on every question —
first true zero-tier-1 candidate in the cohort. Found via `pikespeakbulletin.org/?s=` +
`koaa.com/search?q=` instead. Output at `out-crow-iverson.csv`.

**Seated:**
- `homelessness` = 5 (criminal penalties, reliance on existing social services). A koaa.com
  one-on-one interview quotes her own normative framing of the city's sit-lie ordinance —
  "Getting people the help they need is more compassionate than letting them sit there in freezing
  temperatures" — cross-referenced against the ordinance's actual mechanics from
  `pikespeakbulletin.org` ($500 fine 1st offense, up to 90 days JAIL 2nd offense, no shelter-bed
  contingency, no warning step). The "criminal penalty + existing services, not a new shelter
  mandate" combination is what separates this from chair 4.
- `homelessness-response` = 4 (enforcement-primary + basic outreach). Same interview, "You can't
  just trash a part of our city. You have to do something" — enforcement (sit-lie) is what she
  leads with as her policy; no call for new outreach/shelter investment anywhere found, which is
  what keeps this from reading as chair 3 (services-primary, enforcement secondary).

**Skipped — close but under-determined:**
- `public-safety-approach` — "I'm a limited government. Essential functions of government, police,
  fire and infrastructure... will continue to be my focus" is priority/continuity language with no
  funding-DIRECTION verb (no "increase," no staffing number). Contrast Henjum ("200 more sworn
  officers") and Williams ("active role to recruit and retain officers") — both had an explicit
  ask; Crow-Iverson's version reads as "keep emphasizing" rather than "grow," which under-
  determines between the ladder's "keep current + add crisis teams" (3) and "increase staffing" (4)
  chairs. Neither sub-clause (crisis teams; a specific increase) is evidenced — skip rather than
  guess from tone.
- `economic-development` — "the redevelopment of the North Nevada corridor... it's kind of a gem
  in the rough right now" names a real, specific project but never states the funding mechanism
  (tax abatement vs. public infrastructure spend vs. pure zoning/permitting change) that would
  distinguish this ladder's chairs. Searched twice for corroboration (pikespeakbulletin.org,
  socoinsider.com) and found nothing — a genuinely dangling lead, not yet resolvable.
- `local-immigration` — she was directly involved in an immigration-adjacent controversy (faith
  leaders' MLK-day comments criticizing ICE; she reprimanded a colleague over it) but read three
  full articles and confirmed she deliberately kept her own remarks to meeting-decorum grounds,
  never engaging the ICE-detainer substance. This is a confirmed, deliberate non-position, not an
  unchecked gap.
- No local record found at all: abortion, campaign-finance, childcare, city-sanitation,
  civil-rights, climate-change, data-centers, fossil-fuels, growth-and-development, housing,
  jail-capacity, local-environment, religious-freedom, rent-regulation, residential-zoning,
  trans-athletes, transportation-priorities (the CPR bio's TOPS/PPRTA-advocacy claims are
  reporter's-voice only and produced zero independent corroboration on a direct search for either
  ballot campaign).

Running total for Crow-Iverson: 2/22 — lowest yield in the cohort so far, but a genuine, honest
result given zero tier-1 material. Confirms the brief's framing: web sourcing alone, done well
(alt-press search + a profile interview), can partially substitute for a missing questionnaire but
does not come close to matching one.
