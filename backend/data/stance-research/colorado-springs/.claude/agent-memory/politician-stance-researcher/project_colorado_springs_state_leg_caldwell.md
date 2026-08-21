---
name: project_colorado_springs_state_leg_caldwell
description: Worked example for CO state-leg (28-topic) research on Rep. Jarvis Caldwell (HD 20) — which sources actually yielded chair-worthy evidence and where rhetoric-level magnitude ambiguity forced a skip.
metadata:
  type: project
---

Cohort: Colorado Springs-area STATE legislators, 28-topic `scale-state.json` ladder (not the
44-topic full set, not the local 22). Brief: `backend/data/stance-research/colorado-springs/BRIEF-state.md`.

## Source yield, ranked

- **leg.colorado.gov member page (tier-1 harvested file) bill list was almost entirely unusable.**
  Of 13 current-session prime/co-sponsorships, nearly all were bipartisan, technical, appropriation,
  or narrowly-scoped bills (interim-committee tweaks, channel-authority board appointments,
  auctioneer exemptions, a one-year overtime tax carve-out, a natural-medicine bill, a
  child-care-tax-credit *continuation*). None of these are categorical-enough to seat a chair per
  the sponsorship trap. **Do not expect the current-session bill list to carry the research** for a
  minority-party or bipartisan-leaning member — it mostly won't.
- **The caucus site's `/news` article pages (not just the profile page) were the highest-yield
  source** — `coloradohouserepublicans.com/news/<slug>`. The profile page lists headlines with NO
  hrefs; fetch `coloradohouserepublicans.com/news` itself (or search-engine the headline) to recover
  the actual article slug/URL, then fetch that article directly. An opening-day floor speech and a
  caucus press statement produced clean, on-the-record, forward-looking quotes on taxes/budget,
  school choice, energy/climate, parental rights, and immigration-enforcement rhetoric — far richer
  per fetch than the bill list.
- **completecolorado.com committee-testimony coverage** (Sherrie Peif's bill-hearing writeups) gave
  the single best judicial-criminal-justice quote found: Caldwell opposing a bill that would
  downgrade attempted-murder-with-no-injury to a low felony class, in his own words, forward-looking
  about the outcome he considers wrong (probation for a near-miss shooting). This is a **floor/
  committee statement opposing someone else's bill** — exactly the evidence type the brief ranks
  above sponsorship.
- **coloradopolitics.com's `?s=` search works and is worth 2-3 query variants** (name alone, name+topic)
  — different queries surfaced different articles; a single query undercounted.
- pikespeakbulletin.org and socoinsider.com returned **zero** results for this legislator (both
  0-hit searches, not fetch failures — the pages loaded and explicitly said no posts found). Don't
  assume these under-used sources pay off for every legislator; they're worth trying but can be a
  fast, clean dead end.
- koaa.com/search worked but the "one-on-one interview" pattern from the brief didn't surface a
  Caldwell-specific interview — 223 results, mostly noise, page-1 excerpt had no direct hits.

## Magnitude ambiguity is not just a bill-sponsorship problem — it applies to rhetoric too

Caldwell has a strong, quotable "parents should have the choice to send their children to the
school that best fits their needs whether it's a district run public school, charter school,
private school, or homeschool" line. It's tempting to seat this at school-vouchers chair 4 or 5
(both "no income restriction" chairs — the phrasing rules out chairs 1-3, which all name an
eligibility/means-test limit). But the quote **never mentions a funding mechanism** (vouchers,
"funding follows the student," eligibility scope) — it's pure choice-philosophy rhetoric. That still
left two adjacent chairs (4 "expanding voucher eligibility to most families... maintaining baseline
public school funding" vs. 5 "universal vouchers... funding follows the student") both plausible.
Skipped per the two-chairs-fit rule. **Lesson: the sponsorship-trap logic (direction ≠ magnitude)
generalizes to any rhetorical "choice"/"freedom" statement that doesn't specify the actual policy
instrument or its scope** — don't let a strong quote's fluency substitute for the missing magnitude
detail.

Same reasoning killed a `taxes` row: strong TABOR-defense and anti-"government growth" rhetoric from
the same opening-day speech, but no explicit rate-cut or flat-tax commitment, leaving chairs 4 and 5
both plausible.

## jail-capacity: a categorical bill that still didn't seat a chair

HB25-1072 (Caldwell prime sponsor, failed — postponed indefinitely 3/12/2025) categorically
prohibits unsecured personal-recognizance bonds for repeat violent offenders and sets a $7,500
minimum bond — exactly the kind of numeric/categorical mandate the brief says CAN seat a chair. But
`jail-capacity` chair 5 is a **compound clause**: "expanding jail capacity and enforcement as the
primary response to crime, PRIORITIZING DETENTION OVER ALTERNATIVES." The bill evidences the second
clause only (opposing bail-reform-style release for a narrow offender class) — it says nothing about
capacity expansion or establishing detention as the primary response to crime generally. Chair 4
("building additional jail capacity") isn't about bond policy at all. Skipped both. **Lesson: a
bill can be categorical in its own right and still fail to evidence a compound chair if it only
speaks to one clause of that chair's text — read the FULL chair sentence, not just its most salient
half, before matching a bill to it.**

## Net yield

2 of 28 topics seated (climate-change=4, judicial-criminal-justice=5) with strong quotes; ~26 skipped,
most for magnitude ambiguity or simple absence of evidence rather than contradiction. See
`backend/data/stance-research/colorado-springs/out-caldwell.csv`.
