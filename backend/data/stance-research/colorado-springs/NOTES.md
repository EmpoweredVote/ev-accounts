# ✅ COMPLETE — Colorado Springs stance wave (2026-08-21)

**PUSHED TO PROD.** 77 answers + 77 matching contexts across 28 people. All 35 cohort members
researched; 7 produced a documented, honest zero.

Post-push verification:
- `inform.politician_answers` = 77, `inform.politician_context` = 77, paired 1:1, 28 people.
- `npm run check:stance-sources` is **byte-identical to the pre-push baseline** — 745 offending rows
  across 4 checks, every counter unchanged (BALLOTPEDIA_ONLY 158/159, BARE_AGGREGATOR_DOMAIN 1/1,
  ORPHAN_CONTEXT 50/50, PRIMARY_SITE_NO_PATH 536/536; the four must-be-zero checks all 0).
  **The wave added no source debt.**
- `verify-quotes.mjs`: **61 quotes, all verified against raw source bytes, 0 not-found.**
- `validate-wave.mjs`: clean (high=0, medium=0).

Banners also shipped: essentials `main` pushed (`916aacaa..b549f727`), both assets serving 200 at
the exact uploaded byte counts.

## Coverage

| Cohort | People | Rows |
|---|---|---|
| Colorado Springs council | 10 / 10 | 42 |
| El Paso County | 11 / 11 | 13 |
| CS-area legislators | 14 / 14 | 22 |

🔴 **The legislator count understates the record.** Colorado's legislature is mid-migration and
exposes essentially only the current session — a search for a 13-year member returned 26 bills, 25
from 2026. **That half is worth re-running once the migration completes.** Not a finding about the
people.

---

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

## 🔑 THE LEGISTAR WEB API — the biggest source find of this wave, and it generalises

Colorado Springs runs its legislative record on Legistar. The **WebForms UI at
`coloradosprings.legistar.com` is not fetchable** — it needs interactive postback, which is exactly
where one agent correctly gave up. But Legistar exposes a **public, unauthenticated JSON Web API**
that needs no browser at all:

    https://webapi.legistar.com/v1/coloradosprings/...

    events?$filter=EventDate ge datetime'2026-04-01' and EventDate le datetime'2026-04-15'
    events/{id}/eventitems?Attachments=1     → agenda items + attachment URLs
    events/{id}                              → EventAgendaFile / EventMinutesFile PDF links
    matters?$filter=substringof('camping',MatterTitle)
    matters/{id}/histories                   → every action, with mover/seconder and vote tallies
    matters/{id}/attachments                 → ordinance text, staff presentations
    eventitems/{MatterHistoryId}/votes       → 🔑 THE PER-MEMBER ROLL CALL, by name

Attachment PDFs at `legistar2.granicus.com/...` are then plain-fetchable.

**What it unlocked here, concretely:**
1. **Ken Casey's vacancy-application packet.** He is an appointee with no campaign and no
   questionnaire, and his first pass was an honest zero across all 22 topics. The packet
   ("District 2 Candidates - Finalists", attached to event 2840) contains his written answers to
   nine questions including growth, public safety, transportation and parks — a first-person policy
   record equal to a campaign questionnaire. He went 0 → 2 seated topics, and would have stayed at
   zero without it.
2. **Ordinance No. 26-08, the camping ordinance** — matter 25-590, presented by Donelson, finally
   passed 2026-03-10 **7-2** (No: Gold, Henjum). A numbered, adopted, non-quasi-judicial instrument
   squarely on the `homelessness` axis, with the per-member roll call *and* the minutes in which
   members explain themselves.

**The minutes are narrative.** They summarise what each member said — "Councilmember Leinweber
stated he cannot support a person living in their car because living that way supports isolation
and loneliness when what they really need is the resources to help them… this Ordinance does not
criminalize homelessness; it regulates camping on public land." 🔴 That is the **clerk's
third-person summary, not a verbatim quote** — it can carry `reasoning` and it proves the member
articulated a position rather than merely voting, but it must never become `quote_text`.

Consolidated into `sources/camping-ordinance-26-08.md` (both roll calls + both discussions) for a
single adjudication pass over the whole council, rather than nine separate re-reads.

**Generalises to:** any jurisdiction on Legistar/Granicus — which is most mid-size and large US
cities and many counties. Worth trying `webapi.legistar.com/v1/<client>/` before concluding a
council has no reachable record.

## ⚠ OPEN: the homelessness cluster needs the camping-ordinance adjudication

Hand-review of the seated rows found three that are thinner than they look. None is clearly wrong;
all three rest on evidence that gestures at the chair rather than naming it. Flagged rather than
dropped, because Ordinance 26-08 (now harvested with both roll calls and both discussions) is
exactly the evidence that can settle them.

- **Williams, `homelessness` = 4** and **`homelessness-response` = 3** — both rest partly on a KOAA
  *paraphrase* that she and Donelson "questioned whether penalties for low-level offenses are enough
  to deter crime". Asking whether penalties suffice is not a position on prohibiting encampments.
  She did vote **Aye** on Ordinance 26-08, which the agent did not know.
- **Crow-Iverson, `homelessness-response` = 4** — rests on "You can't just trash a part of our city.
  You have to do something." That is an expression of concern, not a strategy. Her
  `homelessness` = 5 is better founded (her own words on the sit-lie ordinance, cross-checked
  against its actual mechanics) but leans on the ordinance's content more than on her quote.

Rows that reviewed clean and need no further work: Rainey (`housing` = 5 is the single best-matched
row in the wave — "allow the free market to operate… with the least amount of government
interference" against a chair reading "stay out of housing entirely and let the market decide"),
Rainey `growth-and-development` = 2 (the 128% water rule, specific and his own), Casey's two rows,
Donelson's three, Henjum's three.

## 🔴 MATERIAL LIMITATION — Colorado's legislative record is mid-migration, and it caps this cohort

leg.colorado.gov is currently displaying a banner that it is "migrating legacy session data to a
new location" and that links to it "may not be functional at this time." The practical effect is
that **only the current (2026) session is reachable**:

- Member pages carry current-session prime sponsorships only, with no session selector.
- `leg.colorado.gov/bill-search?search_api_views_fulltext=<name>` does work and is multi-session in
  principle, but a search for a legislator who has served since 2013 returned **26 distinct bills,
  25 of them from the 2026 session and exactly one from 2017**. The historical index is effectively
  empty.
- `data.openstates.org` serves the people roster CSV fine but **403s on directory listings**, so the
  bulk bill archive can't be enumerated without a key. No LegiScan key is configured either.

**Consequence, stated plainly:** for long-serving members the seated-topic count understates the
record rather than reflecting a thin one. One 13-year legislator produced a single row. That is a
source-availability artifact, not a finding about the person, and it should not be read as "this
legislator has no positions." Re-run the legislator half once Colorado finishes the migration.

This does NOT affect the city/county half, whose evidence is questionnaires, city news, Legistar and
local press — all fully reachable.

## ✅ QUOTE VERIFICATION — all 44 quotes matched to raw source, zero fabrications

🔴 **Why this pass was necessary.** Two agents independently discovered the same defect:
**WebFetch runs a summarising model over every page, and that model will sometimes return
paraphrased talking points formatted as though they were quotations.** One agent re-fetched a
profile piece with an explicit "only text inside quotation marks" instruction and the answer
reversed to "no direct quotes exist" — the "quotes" from the first fetch had never been said.
Another found that two "reproduce verbatim" calls on the same page returned two *different*
"exact quotes" for the same passage, even through a raw-text proxy, and adopted a rule of citing
only what reproduced byte-identical across independent fetches.

A quote that was never said is a fabricated statement attributed to a real person. So
`verify-quotes.mjs` re-checks every `quote_text` against the **raw bytes** of its source — plain
fetch, no model in the loop — plus the frozen local harvest files.

**Result: 43 verified against source, 1 resolved by hand. Nothing fabricated.**

Three bugs in my own checker had to be fixed before the result could be trusted — worth recording,
because each produced a false accusation against a real quote:
1. It couldn't read PDFs, so quotes from the Legistar vacancy packet looked invented. Fixed by
   converting every harvested PDF to `.txt`.
2. It treated a leading `…` as literal text to find, so honestly-excerpted quotes failed. Fixed by
   splitting on ellipses and requiring each substantial fragment.
3. 🔴 It stripped punctuation *before* decoding numeric HTML entities, so `you&#8217;re` became
   `you 8217 re` — the digits survive a punctuation strip. Two genuine quotes were flagged by this
   alone. Decode entities first.

**A false positive here is not harmless**: it invites dropping a real quote. Every flag was run to
ground rather than resolved by deletion.

One real edit surfaced and is now disclosed rather than silent: a councilmember's recording contains
the spoken stutter "you have to you have to do something", which had been cleaned to "You have to do
something" with no note. The `editor_note` now states the repetition was removed and nothing else
changed.

## ✅ RESOLVED: `growth-and-development` adjudicated across the whole council

Decided once, comparatively, from `sources/growth-and-development-comparison.md` (all nine members'
own answers side by side) rather than leaving it to whichever agent happened to read which file.

**The discriminator:** chair 3's distinguishing content is *investing in infrastructure AHEAD of
growth*. Chair 2's is *conditioning growth on the capacity already in place*. "Plan carefully and
consider infrastructure" is what every Colorado Springs politician says and separates neither.

**Two rows changed, 3 → 2**, with their public reasoning rewritten to justify the new chair:
- **Gold** — "District 4 has seen firsthand what happens when development **outpaces**
  infrastructure"; annexation judged on "water availability, infrastructure capacity". Conditioning,
  not investing ahead.
- **Leinweber** — infill before annexation, "taking advantage of **existing** infrastructure", and
  he would have slowed the process to gather facts. Conditioning, not investing ahead.

**Kept as-is:** Henjum 2 (opposes flagpole annexations on water/infrastructure/public-safety
grounds, with votes), Rainey 2 (backs a specific numeric water-supply threshold, the 128% rule,
before annexation), Casey 2 ("vital to ensure development does not outpace the ability of City
services to support"), **Mobolade 3** — he is the one member with an affirmative forward programme
(RetoolCOS zoning flexibility, an annexation policy weighing future utility needs), which is what
chair 3 actually describes.

**Kept skipped:** Donelson (describes wastewater capacity being fixed to unlock Banning Lewis Ranch —
a fact, not a stated preference, and it reads across two chairs), Williams (only "we need to grow
intentionally"), Risley (says "the market will largely drive the balance", which points at the
deregulatory end, but he also criticises the water ordinance as rushed — no clean chair).

Final distribution: **Casey 2, Gold 2, Henjum 2, Leinweber 2, Rainey 2, Mobolade 3**, three blank.

## ✅ The WebFetch-paraphrase warning proved load-bearing

After the warning went into both briefs, an agent researching a county commissioner reported that an
earlier WebFetch pass had **hallucinated two quotes** attributed to her — one about preserving
"2½-acre plots", one about a 300-year water rule. A strict "only text inside quotation marks"
re-fetch of the *same article* confirmed **neither sentence exists in the source**. She dropped both.

That is two fabricated statements about a real person, caught before they were written down, by a
warning that only existed because two other agents had hit the same defect earlier in the night and
reported it. Propagating findings back into the brief mid-wave is what made the difference.

Standing rule for any future wave: **treat WebFetch output as a summary, never as a transcript.**
Confirm a quote with a strict re-fetch, and verify the whole set against raw bytes afterwards.

## Third row dropped — `deportation` for a legislator, same error class as the sanctuary row

The agent flagged this one itself as "the closest this pass came to the sponsorship/magnitude trap",
and on review it does not survive.

The row seated chair 4 ("deport everyone without legal status, starting with those who have criminal
records") on prime sponsorship of SB25-047, which reinstates a mandate that peace officers report
anyone they have probable cause to believe is unlawfully present to federal immigration authorities.

🔴 **That is an enforcement-COOPERATION instrument, and the ladder asks who should be DEPORTED.**
Reporting to ICE does not establish deportation scope. Worse, the two available pieces of evidence
point at different chairs: the bill has no criminal carve-out (which reads toward 4), while his own
op-ed's stated motivating concern is a serious criminal offender (which reads toward 2, "only deport
people convicted of serious violent crimes"). Two chairs fit and nothing separates them.

The quote attached to it — "Continue defending laws that make cooperation harder, or fix a system
that is failing the people it is supposed to protect" — is about cooperation, and fails the
on-question gate for this ladder.

This is the same defect as the city `local-immigration` row dropped earlier: **an instrument about
cooperating with federal enforcement mapped onto a ladder asking a different question.** Worth
generalising — that mapping is the most seductive wrong answer in this whole topic area.

## Harmonised: `local-immigration` across the county, 5 → 4 for the Board Chair

Three county officials were seated on this ladder by three different agents, and the result was
internally inconsistent:

| | seated | evidence |
|---|---|---|
| Sheriff Roybal | 4 | reinstated ICE communication, authorised deputies to assist **"when requested"**, publishes transfer lists, **pursued a formal 287(g) agreement**, "my office collaborates with ICE when criminal activity is involved" |
| Commissioner H. Williams | 4 | joined the county lawsuit; "fully collaborating with ICE Officials, **as state statute allows**" |
| Commissioner Geitner (Chair) | **5** | announced the same lawsuit, framed as restoring the Sheriff's ability to contract with the federal government |

🔴 **The Board Chair was seated a chair ABOVE the Sheriff, on weaker evidence, for the same county
action.** That is the tell. Two things settle it:

1. Chair 5's operative verb is "**Direct** local police to actively assist… and support federal
   detention operations." A county commissioner cannot direct the Sheriff — the office is
   independently elected. Litigating to remove a statutory barrier is *enabling* cooperation, not
   directing enforcement.
2. Her own quote carries the same criminal-conduct limit that kept the Sheriff at chair 4 ("if we
   have criminals in our community who are doing harm… we want to make sure that we are able to get
   them out"). The same framing cannot support two different chairs.

Changed to 4 with the reasoning rewritten. All three county officials now sit at chair 4 on the same
underlying posture, which is what the evidence actually shows.

**The general lesson:** per-person agents cannot see each other's work, so a ladder touched by
several members of the same body needs a cohort-level pass. This is the second time on this wave
(after `growth-and-development`) that comparing rows side by side changed an answer.

## County row officers — a documented zero, and a scale-coverage gap worth acting on

All four administrative row officers (Assessor, Clerk & Recorder, Coroner, Treasurer) produced
**zero rows**, checked individually rather than waved off. Two distinct reasons, and they mean
different things:

- **No record at all**: Assessor Mark Flutcher and Coroner Emily Russell-Kinsley. The only Flutcher
  hit has him observing that reappraisal notices "scared a lot of people" — a comment on public
  reaction, not a proposal. Russell-Kinsley's coverage is appointment notices and a profile about
  management style; targeted searches for any overdose/harm-reduction policy statement found only
  factual death reports, which is precisely the "reporting data is not a position" trap.
- 🔴 **Real, quotable policy positions with NOWHERE ON THE SCALE TO PUT THEM**: Clerk & Recorder
  **Steve Schleiker** wrote an April 2026 op-ed, "How we know our El Paso County elections are safe
  and secure" (SAVE Act, mail-in voting), and pulled the county out of the Colorado County Clerks
  Association. Treasurer **Chuck Broerman** co-authored an April 2026 Colorado Politics op-ed,
  "Update, safeguard Colorado's mail ballot with voter ID."

Both are genuine first-person policy advocacy. Both concern **election administration and voter ID**
— and **the 22-topic LOCAL scale has no `voting-rights` or elections topic at all** (the *state*
scale does). So the honest outcome is a blank, but the cause is a gap in the ladder set rather than
a gap in the record.

**Recommendation:** if a local elections/voting-rights topic is ever added, these two officers are
ready-made, well-sourced subjects for it. Worth noting when the local scale is next reviewed —
county clerks are the officials most likely to hold a public position on exactly that axis, and the
scale currently cannot represent them at all.

⚠ One misattribution caught in passing: Colorado Politics' own search UI labels Broerman as "Clerk
and Recorder". He is the **Treasurer**; Schleiker is the Clerk. The agent verified true authorship
before citing.

## 🔴 Caucus-site CMS tags are NOT authorship — hit twice, avoided both times

`coloradohouserepublicans.com` (and likely its Senate/Dem equivalents) attaches member name-tags to
`/news/` articles as a CMS taxonomy, **independently of who actually signed or is quoted**. Two
agents hit this:
- One nearly seated `climate-change` on a "House Republicans Deliver Letter Opposing Costly PUC
  Heating Mandate" article that tagged their subject — a targeted re-fetch showed the letter's
  **signature block names only Dan Woog**. Not a signer. Used as background context only.
- Another found the same pattern and refused a row because the member's name appeared solely via a
  `/news/tag/` hyperlink with no evidence she had signed.

**Rule: a name in a tag, byline strip, or `/tag/` URL is not evidence.** Find the signature block,
the quote attribution, or the bill's sponsor list. Group letters in particular list many members in
metadata and quote two or three — only the ones actually named in the text can carry a chair, and
even then the letter's *own stated reasoning* has to name the chair.

## County vacancies go through the PARTY, not the Board — so there is no county vacancy packet

The city appointee's vacancy-application packet was the best single find of this wave, so I asked
whether the county had an equivalent for its June-2025 appointee. **It does not, and the reason is
structural:** a Colorado county commissioner vacancy is filled by a **party vacancy committee**, not
by an act of the Board. (Hers took four rounds, a 20–20 deadlock, then 21 votes.) So AgendaSuite —
which only carries Board business — has no application materials for that office type, and there is
nothing to hunt for. Don't repeat the search on a future county wave.

What worked instead for both remaining commissioners was **their own campaign sites**. ⚠ Both are
built on a template where **the nav labels are decorative and the real content sits at `/blank` and
`/blank-2`** — the "Issues" link on one is a dead placeholder while the actual platform text is on
the homepage. An agent that trusts the nav concludes the site is empty. Check the odd paths.

## 📋 Scale-coverage gaps found — real positions with nowhere to sit

Three times this wave an official had genuine, well-sourced, first-person policy advocacy that
seated **nothing**, because no ladder asks that question. These are gaps in the topic set, not gaps
in the record, and they are worth raising when the scales are next reviewed:

| Missing topic | Scale | Who it would have seated |
|---|---|---|
| **elections / voting-rights** | LOCAL (22) | County **Clerk & Recorder** (op-ed "How we know our El Paso County elections are safe and secure"; withdrew the county from the Colorado County Clerks Association) and county **Treasurer** (co-authored "Update, safeguard Colorado's mail ballot with voter ID"). The state scale has `voting-rights`; the local one does not — yet **county clerks are the officials most likely to hold a public position on exactly this axis**, and the scale cannot represent them at all. |
| **privacy / surveillance** | STATE (28) | A senator whose only quotable, forward-looking statements are on surveillance-technology bills (SB26-070, SB26-071). Zero rows seated as a result. |
| **firearms** | STATE (28) | A representative who owns a firearms business and wrote a veto-urging op-ed — her richest personal vein, entirely off-scale. |

Not an argument for adding topics casually — but the clerk case in particular looks like a genuine
blind spot for any county cohort, since it is the one office whose whole remit is elections.

## Decision: the harvested sources stay in the repo (operator, 2026-08-21)

The PR is +28,821 lines and most of it is `sources/` and the `out-*.csv` payloads rather than code.
**Operator decision: keep them.** Not up for re-litigation on a future wave.

The reason it matters: a stance is a public claim about a real person, and `reasoning` renders to
voters under "Why this position?". Six months from now the only way to check whether a chair was
fairly seated is to re-read *the text it was drawn from* — and several of this wave's best sources
are behind a WAF (cpr.org allows one page per browser launch), are Legistar attachments reachable
only via an undocumented JSON API, or are news pages that rot. Freezing them to `sources/` is what
makes the wave auditable rather than merely asserted. The CSVs are the same argument: they carry the
per-row source URLs, quotes and editor notes that the DB flattens.

Practical consequence for future waves: **harvest to `sources/` and commit it.** Don't treat the
harvest as scratch.
