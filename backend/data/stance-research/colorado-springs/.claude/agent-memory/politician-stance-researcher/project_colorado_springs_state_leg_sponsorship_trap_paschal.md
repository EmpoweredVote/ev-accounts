---
name: project_colorado_springs_state_leg_sponsorship_trap_paschal
description: Worked example (Rep. Amy Paschal, HD18) of applying the sponsorship trap to a 17-bill leg.colorado.gov list on the 28-topic STATE scale — most bills fail, only 2/28 seated
metadata:
  type: project
---

Amy Paschal (D, HD18, El Paso/Teller) — Energy & Environment, Joint Technology, Transportation/
Housing/Local Government committees. Her leg.colorado.gov member page listed 17 current-session
(2026) prime-sponsored bills/memorials and NO personal or caucus site. Result: only 2/28 state
topics seated (`climate-change`=3, `judicial-criminal-justice`=3), both resting on read bill TEXT,
not the title. See [[project_colorado_springs_local_scale_chairs]] for the sibling worked example
on the LOCAL scale.

## The filter on leg.colorado.gov member pages is real, but doesn't save you from reading the bill

The page's "Sponsor Type" filter defaults to **Prime Sponsor only** ("(1)" badge, 3 filters
applied). Confirmed by fetching two bill pages directly and asking for prime vs. co-sponsor: both
SB26-182 and HB26-1242 listed Paschal under "Prime Sponsor" on the bill page itself. So the member
page's list can be trusted as prime-sponsorship-only for this legislator — **but that only proves
DIRECTION, not which of the 5 chairs applies.** You still have to fetch `leg.colorado.gov/bills/
<num>` for every bill you intend to cite.

## What happened when I read all 17 bills' actual text (not titles)

Titles alone would have tempted rows on `fossil-fuels`, `transportation-priorities`, `redistricting`,
`housing`/`rent-regulation`, `voting-rights`, `civil-rights`, `healthcare`. Reading the operative
text killed every one of them:

- **HB26-1112** "Underground Injection Control Wells" sounds like fossil-fuel policy. Text: a
  regulatory-permitting framework (EPA primacy request, misdemeanor penalties for violations) —
  and it died in committee. Doesn't ban/expand drilling; not a `fossil-fuels` chair.
- **SB26-172** "Front Range Passenger Rail District" sounds like transit investment. Text: pure
  GOVERNANCE restructuring (board residency rules, subdistrict creation, a NEW voter-approval
  requirement before local tax increases). No investment-priority claim; skip `transportation-
  priorities`.
- **HB26-1038** "County Commissioner Redistricting" sounds like a clean `redistricting` chair-1 hit
  ("independent commissions"). Text: independent commissions draw the plan, but the elected county
  board retains modification-and-final-approval power over that plan. That's neither "no elected
  officials at any level" (chair 1) nor "equal party representation" (chair 2) — a genuine two-
  chairs-fit case. **Skipped per the compound-chair rule**, and it's a COUNTY-level redistricting
  bill in any case, one level down from the topic's state/congressional framing.
- **HB26-1284** "Requirements for Tenant Utility Billing" sounds like `rent-regulation` or
  `housing`. Text: submetering + RUBS billing-method rules with a tenant right to sue for
  overcharges — real tenant protection, but about utility billing mechanics, not rent caps,
  eviction rules, or housing supply. Neither ladder's chairs describe this. Also died in committee.
- **HB26-1080** "County Mail Ballot Signature Verification" sounds like `voting-rights`. Text:
  requires a bipartisan TEAM (not one judge) to verify signatures — a process-integrity tweak that
  doesn't move the needle on the ladder's actual axis (registration/mail-voting access vs. photo-ID
  strictness). Also died in committee.
- **HB26-1043** "Transportation Network Company Discriminatory Practices" sounds like `civil-
  rights`. Text: raises TNC civil penalties for driver discrimination, mandates service-animal
  driver training, more frequent PUC reporting. Real but narrow to one industry — the `civil-
  rights` ladder is about racial/social inequality broadly; this doesn't seat any of its 5 chairs.
- **HB26-1107** "Health Care in Regulated Facilities" sounds like `healthcare`. Text: a dementia-
  care-facility DISCLOSURE FORM mandate (transparency), not a coverage/access/payer mechanism. Not
  a `healthcare` chair.

## What DID seat, and why

- **`climate-change` = 3**, from **SB26-182** (signed 05/21/2026, confirmed House prime sponsor):
  hard hard-deadline hard coal phase-out (Dec 31 2032) for municipal utilities PAIRED with an
  extension of their original 80%-reduction deadline and new reporting/planning mandates. That
  combination — firm mandate + gradual timeline + continued regulatory oversight, not an outright
  ban and not a market-only approach — is what let it seat chair 3, not just prove direction.
  Secondary source **SB26-022** (same subject, further deadline extension to 2040 + a 1.5% annual
  rate-increase cap) corroborates the "gradual, not rapid" read without contradicting it.
- **`judicial-criminal-justice` = 3**, from **HB26-1242** (signed 05/28/2026, confirmed lead House
  prime sponsor): a MANDATORY 9-month post-reinstatement interlock restriction for first-time DUI
  (accountability) bundled with eliminating the prior 2-month reinstatement wait AND a new income-
  based subsidy for interlock costs (support). The bill's own text mixes both halves of chair 3's
  "some accountability, some support" — a single clean bill doing both is what makes this citable,
  not a title read.

## Tier-2/3 web sourcing yield for this legislator: near-zero

- `coloradopolitics.com/?s=` worked and returned 3 real hits, but all from her FIRST session
  (2025) and all describing her as a CO-sponsor (weaker per the sponsorship-strength rule), with
  **zero direct quotes** — geothermal energy (HB25-1165) and lab-animal-adoption (SB25-085) bills.
  Useful for color/corroboration only, not primary citations.
- `completecolorado.com/?s=` — zero hits (not every legislator has coverage there; don't assume
  the tier-2 productive-source claim in BRIEF-state.md holds for every individual).
- `pikespeakbulletin.org/?s=` — 2 hits, both about campaign/political-drama (a complaint to state
  party leaders about a congressional candidate's tactics; a Jane Fonda campaign rally appearance)
  — zero policy quotes. One fetch attempt hit a transient Cloudflare 522; retry succeeded.
- `socoinsider.com/?s=` — zero hits for this name.
- `koaa.com/search?q=` — the search results page is JS-rendered; WebFetch only sees the shell
  (claimed "1,333 results" but no actual article content reachable). Don't trust the raw hit count.
- `cohousedems.com/members/` — 404, no caucus bio page exists at that path for this legislator.
- `en.wikipedia.org` — a stub, one sentence (took office Jan 2025, succeeded Marc Snyder), no
  policy content.
- Ballotpedia was not attempted (per BRIEF-state.md, confirmed empty-body for this cohort).

**Takeaway for the next low-profile freshman-adjacent state legislator with no personal site:** if
her committees are all technical/infrastructure (Energy, Transportation, JTC — no Judiciary, no
Health, no Appropriations, no Education) and press coverage is thin, expect a LOW seat count (2/28
here) even with 17 sponsored bills. That is the correct, honest outcome per BRIEF-state.md's "a
blank spoke is a correct answer" — do not stretch a technical bill's title to cover an adjacent
ladder.
