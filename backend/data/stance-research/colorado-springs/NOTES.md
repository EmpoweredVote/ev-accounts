# Colorado Springs stance wave — working notes

Started 2026-08-21. Branch `feat/colorado-springs-geometry`. Phase 5 of the CS deep seed
(geometry, structure, headshots, elections, banners all landed; this is stances).

## Cohort — 35 people, verified against prod, zero existing answers

Every one of the 35 has **0 rows** in `inform.politician_answers`, so the whole wave is NEW
and the value-change guard has nothing to hold back.

| Group | N | Scale | Notes |
|---|---|---|---|
| Colorado Springs city | 10 | local (22) | Mayor + 6 district + 3 at-large. **Nonpartisan by charter.** |
| El Paso County | 11 | local (22) | 5 commissioners + 6 row offices (Assessor, Clerk, Coroner, DA, Sheriff, Treasurer) |
| CS-overlapping legislators | 14 | state (28) | SD 9/10/11/12/35 + HD 14/15/16/17/18/20/21/22/56 |

## Scale correction — state is 28, not 26

`inform.compass_topic_roles` in prod, 2026-08-21:

    federal 26 | judicial 8 | local 22 | state 28

My carried-forward note said the state-leg scale was 26. It has grown to **28**. Local is 22 as
expected. Both scales exported to `scale-local.json` / `scale-state.json`, all topics carrying a
full 5-value ladder (verified — no malformed ladders).

## 🔴 The geo_id collision bit the cohort query

Colorado SLDU and SLDL geo_ids share the `08NNN` shape — `08014` is BOTH Senate District 14 and
House District 14. Selecting the 14 legislators by `geo_id IN (...)` alone returned **27** people,
silently mixing chambers. Must disambiguate on `mtfcc` (`G5210` senate / `G5220` house). This is
the known 1,159-collision class showing up in a live query, not a theoretical risk.

## Sources

### CS city council — KRCC/CPR candidate questionnaires (tier 1)

Detailed first-person answers, sectioned **Development & Growth / Public Health & Safety /
Governance**, ~6 substantive questions. Quality is high and chair-grade: Henjum, on annexation,
writes "I am opposed to (and recently voted no on 2) so called 'flagpole' annexations" — a
position *and* a named vote.

Topics this source actually reaches: growth-and-development, homelessness,
homelessness-response, public-safety-approach, and partially residential-zoning /
economic-development. It does **not** reach the other ~16 local topics — those need other
sources or stay blank.

- 2025 cycle (district seats D1–D6): 5 of our 6 seated members have a questionnaire.
  **Ken Casey (D2) has none** — needs separate sourcing.
- 2023 cycle (mayor + 3 at-large): Leinweber has one; **Crow-Iverson explicitly "did not respond
  to survey"** — a real absence, not a gap in my search. Risley to confirm.
- 2024 cycle (Southern Colorado): covers the legislative *and* county commissioner races.

### 🔴 cpr.org is behind a WAF that throttles sequential navigation

WebFetch → HTTP 403. curl with a full browser UA → **also 403**, so it is not a UA check.
Playwright gets in, but only paced: the first navigation returns 200 and every rapid one after it
returns **403 with a 258-char body**. `harvest.mjs` handles this with a 9s inter-request delay and
exponential backoff (18s/36s/54s) on a block, and gates success on **body length as well as
status** — a WAF challenge can arrive as HTTP 200 with a few KB of shell.

Harvested pages are frozen to `sources/*.md` so the research agents read local files: no rate
limit, no 403, and a later re-read sees exactly the text a stance was drawn from.

## Standing rules for this wave

- A chair needs evidence naming **that chair**, not just the direction. Two adjacent chairs fit ⇒
  blank. A blank spoke is correct and honest.
- **Never assume polarity** — read each ladder from the exported scale. Chair 1 is usually maximum
  government action but AI Oversight and Tariffs invert, and Residential Zoning, Growth and
  Development Pace and Government Deference are off-axis entirely.
- CS council and mayor are **nonpartisan by charter** — no party inference whatsoever.
- **Land-use votes are quasi-judicial**, not stances (the Austin lesson). A council member voting
  on a specific annexation is adjudicating an application against criteria, not declaring a policy
  position — unless they say so in policy terms, as Henjum does above.
- Validate every payload **on arrival**, not at the end of the wave.

## 🔴 The source finding that matters — city news page, not the questionnaires

The KRCC questionnaires capture only **campaign-era** positions (2023 or 2025 cycle). The
**2024–2026 governing record lives on `coloradosprings.gov/news`** and is invisible to them.

Measured, not assumed: the mayor's pass reached 7 topics from the questionnaire alone and **11**
once the city news page was searched. The four extra topics — `city-sanitation` (Aug-2026 KICAS
initiative), `data-centers` (Aug-2026 Community-First Data Center Standards), `homelessness-response`
(Aug-2026 Homelessness Response Team), `local-immigration` (Jan-2024 migrants/sanctuary statement) —
were reachable from **no other source tried**. Three of its quotes were re-verified verbatim against
raw HTML (not WebFetch's rendering) and all three matched.

`BRIEF-local.md` was updated with this mid-wave, and the two agents that ran before the finding
(Henjum, Leinweber) are being sent back for a second pass rather than left at their first-pass yield.

**Confirmed dead for this cohort** (stop re-testing): `ballotpedia.org/<Name>` returns empty for
these officials; `gazette.com` is WAF-protected exactly like cpr.org; `csindy.com` redirects
off-domain to socoinsider.com; outlet `?s=` search endpoints 403 or serve JS shells; guessed
`<name>.com` campaign domains are placeholders. `koaa.com` and `krdo.com` **do** work.

## Log

- 2026-08-21 — cohort resolved (35), scales exported, baseline confirmed 0, harvester built.
- 2026-08-21 — 17 CS/EPC sources + 14 legislator sources harvested to `sources/`.
- 2026-08-21 — wave 1 (Mobolade 11 rows, Henjum 3, Leinweber 3). City-news finding folded into the
  brief; Henjum resumed for a second pass.

## Review findings — two rows dropped, and why they matter

Both survived the mechanical validator and failed on judgment. Neither would have been caught by
a structural check; this is why payloads get hand-read on arrival.

**1. `economic-development` = 1 for an at-large member — dropped.** The ladder is entirely about
*incentive posture* (none → maximum). He never mentions incentives, subsidies or abatements
anywhere in his own answers. The "no corporate tax incentives" clause was resting on the phrase
"limiting government overreach into the realm of private business" — which sits in KRCC's
**reporter-written bio paragraph**, introduced by "The short biography below is gleaned from the
candidate's response, their website and other sources." 🔴 **Every questionnaire page opens with
one of these**, and it reads exactly like a position statement. The candidate's own words start at
the first question heading.

**2. `local-immigration` = 2 for a district member — dropped.** She voted against the non-sanctuary
resolution and said "When people come, they will be served." But the ladder's every chair is about
**law enforcement and ICE** — detainers, information sharing, proactive assistance — while the
resolution is about **municipal spending and symbolic posture** and contains no detainer policy at
all. Her statement is about service provision: a different axis. The reasoning as written even
conceded she "stopped short of pledging to refuse court-ordered ICE detainers" — i.e. it admitted
the chair's own content was unevidenced. Voting no places her on the more-welcoming side, but
chairs 1 and 2 both fit and nothing separates them ⇒ blank.

The mayor's `local-immigration` = 3 was **kept** on the narrow ground that "we are not a sanctuary
city," in ordinary usage, *is* a claim about cooperating with federal enforcement, and no
proactive-assistance directive exists to push it to chair 4. Rule 4 in `BRIEF-local.md` now states
this distinction so later agents don't re-seat the resolution.

## What actually lifts yield

Ranked by measured effect on this cohort:
1. `coloradosprings.gov/news` — the governing record. Took the mayor 7 → 11.
2. Searching by **institution + topic** rather than name + topic. "Colorado Springs council
   immigration resolution" surfaced a vote that "<name> immigration" missed completely.
3. `koaa.com/search?q=` — highest-yield outlet search.
4. `coloradosprings.gov/search?query=` — server-rendered, so its "no results" is trustworthy
   negative evidence rather than a JS shell.

## ⚠ OPEN: `growth-and-development` is being seated inconsistently — needs an adjudication pass

Across six agents the same topic got: Henjum 2, Leinweber 3, Gold 3, Williams skip, Risley skip
(explicitly "straddles 2 and 3, no textual tiebreaker"), Donelson skip ("conflicting signals
across three chairs").

The two chairs in contention:
- 2 = "Allow growth only where existing infrastructure can support it; slow approvals until
  capacity catches up"
- 3 = "Plan proactively — invest in infrastructure ahead of growth to support responsible expansion"

**Chair 3's distinguishing content is INVESTING AHEAD. Chair 2's is CONDITIONING GROWTH ON EXISTING
CAPACITY.** Reading the sources directly, both rows seated at 3 look like chair 2:
- Leinweber: "advocate for more thorough considerations of infill before annexations", "taking
  advantage of **existing** infrastructure and resources within our city" — infill-first, slow the
  approval, use what's there. No investment-ahead proposal anywhere.
- Gold: "District 4 has seen firsthand what happens when development **outpaces** infrastructure",
  annexation decided "by considering key factors like water availability, infrastructure
  capacity" — growth conditioned on capacity. No investment-ahead proposal.

Only Henjum's 2 rests on distinguishing evidence (opposing flagpole annexations *specifically* on
public-safety/infrastructure/water-capacity grounds, with votes).

Every Colorado Springs politician says "plan carefully and consider infrastructure" — that phrase
alone cannot separate 2 from 3, and an agent reading it in isolation drifts to 3 because it sounds
proactive. **Do not resolve this per-agent.** Held for a single adjudication pass over the whole
cohort with all sources in view, so the answer is consistent across the nine council members rather
than an artifact of which agent read which file.
