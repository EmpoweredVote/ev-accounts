---
name: project_colorado_springs_state_leg_liston
description: State-leg worked example — Larry Liston SD-10 (13-year incumbent, thin current-session bill list); coloradopolitics.com search was the highest-yield source for a legislator whose leg.colorado.gov record is almost entirely 2026 technical bills.
metadata:
  type: project
---

# Larry Liston (R, Senate District 10, El Paso County) — 3/28 seated

## What worked

`https://www.coloradopolitics.com/?s=%22First+Last%22+<keyword>` (their native search, not a
generic homepage fetch) was by far the richest source for this legislator — better than
`completecolorado.com` (which surfaced only one op-ed and one 2018 mention) and much better than
`leg.colorado.gov`, whose 9 current-session bills were almost all technical/bipartisan (key boxes
at schools, noise abatement, massage-facility regulation, age attestation) with zero ideological
content. Keyword-qualifying the coloradopolitics search (`+abortion`, `+nuclear`, `+voucher`,
`+crime`) is cheap and worth doing per-topic — plain `?s=<name>` alone missed the richest hit (a
2019 "Q&A with Larry Liston" interview) that only surfaced once we searched `+Second+Amendment`
as an unrelated side effect. Consider running 6-8 topic-qualified searches per legislator on this
source rather than one bare-name search.

A 2019 Colorado Politics **Q&A/interview format** article was worth more per-fetch than any bill:
it gave a direct, on-the-record answer covering taxes, government overreach (Referendum CC),
school choice, oil-and-gas support, and 2A — all in the legislator's own words, no paraphrase risk.
This confirms the standing lesson (from KOAA "one-on-one" pieces) that interview-format sources
beat news coverage of votes.

## What was seated (3 rows) and why the compound-clause test killed the rest

- **misinformation = 4** — a `completecolorado.com` op-ed opposing SB21-132 (govt regulation of
  business speech on social media) is a clean, on-question, forward quote for the free-speech-not-
  censorship chair.
- **taxes = 4** — combined a 2019 Q&A quote (opposes "higher taxes, income and wealth
  re-distribution") with a documented pattern of action (3 sponsored Homestead Exemption bills for
  seniors/disabled veterans + a KOAA quote pushing a special session after Prop HH's defeat). Chose
  4 over 5 specifically because nothing in the record calls for a flat tax or "shrink government" —
  only opposition to raising taxes and support for returning TABOR-capped revenue. This is a
  judgment call under real ambiguity, documented in reasoning rather than hidden.
- **climate-change = 3** — SB24-039 / SB23-079 (both died in committee, party-line) tried to define
  nuclear as a "clean energy resource." A direct quote ("lay the groundwork for... reliable and
  renewable energy... for future generations") is forward and on-question. Landed on 3 (gradual
  clean-energy investment) rather than 2 (rapid phase-out) because his framing is additive
  (add nuclear to the mix) not a fossil-fuel-elimination timeline.

**Killed despite real evidence, and why:**
- `fossil-fuels` — Q&A says he wants Republicans to "distinguish" themselves via "oil and gas
  industry support," but that phrase alone doesn't pick between maintain-current-levels (3),
  expand-permits (4), or remove-restrictions (5). Direction only — skipped, same shape as the
  sponsorship trap but for a spoken quote instead of a bill.
- `redistricting` / `voting-rights` — HB26-1203 (co-sponsor, 4th-listed, "Lost") would have forced
  large counties into district-based county-commissioner elections. Read the full bill text before
  ruling it out: it's about the *method of electing county commissioners*, not who draws
  state-legislative maps (redistricting chair) and not voter ID/registration/mail-voting rules
  (voting-rights chair) — off-axis for both ladders on this scale, not just under-evidenced.
- `judicial-criminal-justice` — Wikipedia claims he "opposed death penalty repeal" and "attempted
  to stall" a 2020 repeal vote, but no primary source (news article, vote record) corroborated it —
  `leg.colorado.gov/bills/sb20-100` (the actual 2020 repeal bill, not the HB20-1091 red herring
  Wikipedia's bill-number omission led to) shows final vote tallies with **no per-member roll call
  in the fetched content**, and no news search surfaced a quote. Skipped rather than seat a chair on
  an uncorroborated secondary-source claim.
- `school-vouchers` — "school choice" named repeatedly as a talking point/distinguishing issue but
  never with a funding mechanism (means-tested vs. universal) attached. Skipped for the same
  magnitude-ambiguity reason as fossil-fuels above.

## Dead ends specific to this legislator
- `completecolorado.com` tag page and multiple keyword searches: only 2 total hits across the whole
  research pass (1 op-ed, 1 unrelated 2018 mention).
- `socoinsider.com` and `pikespeakbulletin.org` (usually productive for this cohort per
  [[project_colorado_springs_deep_seed]]): **zero** hits for this legislator specifically — a
  reminder these sources are inconsistent per-person, not universally reliable.
- `csindy.com` search silently 302-redirects to `socoinsider.com` (itself a dead end here) —
  don't waste a second fetch chasing the redirect once socoinsider is already confirmed empty.
- `coloradosenaterepublicans.com` has no working per-member bio URL pattern (`/larry-liston/` and
  `/senators/larry-liston/` both 404; homepage doesn't link individual profiles).
- League of Women Voters Pikes Peak Region forum (flagged by the dispatcher as worth hunting):
  found the real domain via redirect-chasing (`lwvcs.org` → `lwvcs.clubexpress.com`), but
  ClubExpress-hosted LWV chapter sites 403 WebFetch outright. DNS guesses (`lwvpikespeak.org`,
  `lwv-pikespeak.org`, `lwvcopikespeak.org`, `lwvpprcolorado.org`) all NXDOMAIN. Google/Bing/
  DuckDuckGo fetched as plain URLs return no usable results for this query (DDG CAPTCHAs; Bing and
  Google silently ignore quoted multi-word queries and return unrelated general hits) — these are
  not viable substitutes for WebSearch under the WebFetch-only rule. The forum was never located.
- `friendsoflarrylliston.com` (guessed campaign domain) — NXDOMAIN.
- `denverpost.com` — Claude Code's WebFetch refuses this host outright ("unable to fetch"), distinct
  from a 403/404; don't retry it for any legislator.
- `leg.colorado.gov/bills/<wrong-number>` — Wikipedia's prose ("2020 repeal vote") didn't include
  the bill number; guessing HB20-1091 wasted a fetch (it's an insurance-division bill). The actual
  2020 CO death-penalty repeal is **SB20-100**. Worth remembering this number if another SD/HD
  legislator's death-penalty record comes up in this cohort.
