---
name: project_colorado_springs_state_leg_bradfield
description: Colorado Springs state-leg worked example — Mary Bradfield HD21, a 0/28 honest yield despite a large, verified quote haul, because every quote/bill answered an access-supply question, not the ladder's payer/enforcement axis.
type: project
---

Mary Bradfield (HD21, El Paso County) — full 28-topic pass, **0/28 seated**. Not a source-access
failure (found more usable quotes than several higher-yield reps in this cohort) — every single
piece of evidence failed the axis-match test, not the sponsorship-trap test.

## What was found, and why each one was rejected

- **Two prime-sponsored, signed-into-law healthcare bills with strong, verified, forward-looking
  quotes**: HB23-1071 (psychologist prescriptive authority) and SB24-141 (out-of-state telehealth
  licensure). Quotes confirmed word-for-word on a second fetch (e.g. "I want to see Colorado have
  accessible mental and behavioral health... it can be another tool in the toolbox," "there aren't
  enough of them. We need to do something in this state to improve the access to care"). **Still
  skipped `healthcare`** — the ladder's five chairs are about who PAYS (single-payer → public
  option → means-tested → employer/private → stay out); her bills are supply-side scope-of-practice
  and interstate-licensure reform, an orthogonal axis. A quote about "improving access to care" is
  not evidence for a payer-model chair no matter how strong the quote is. **Lesson: confirm the
  quote answers the axis in the question_text before checking whether it's well-sourced — a
  well-sourced off-axis quote is still a skip.**
- **HB26-1104** (Credit Agency Voter Address Verification, prime-sponsored 2026, postponed
  indefinitely) — pure voter-roll-maintenance mechanism, no photo-ID component. `voting-rights`
  chair 4 is compound (ID **and** roll maintenance); only half evidenced → skip. Bill also never
  passed, which independently weakens it as a conviction signal.
- **SB23-106** (veteran military-retirement tax deduction, co-sponsored, killed in committee) —
  narrow demographic tax carve-out, not evidence of general tax philosophy (raise/cut broadly).
  Skip `taxes`.
- **A caucus-site "In the News" tag link** ("Rep. Mary Bradfield" appeared only as a `/news/tag/`
  hyperlink at the bottom of the PUC-heating-mandate-letter article) — this is NOT confirmation she
  signed or endorsed the letter, just that the CMS tagged the article to her page. Treated as
  no-evidence, not weak-evidence. **Lesson: a name appearing as a tag/hyperlink on a page is a
  different (and much weaker) fact than being named in the letter's signature block — verify which
  one it actually is before citing a group letter.**
- **Two whole-caucus group letters she was a signatory on** (Denver crime-crisis letter to Mayor
  Johnston; PUC heating-mandate letter) — no individually attributed statement, unlike the
  Richardson worked example where a group letter's own operative text was still citable because it
  named a specific mechanism. Here the letters are broad advocacy prose ("strengthen law enforcement
  presence," "reverse course") without a mechanism specific enough to name a chair, and she's not
  quoted individually. Skip `jail-capacity`, `judicial-criminal-justice`, `climate-change`,
  `fossil-fuels`.
- **Bio-page school-choice sentence** ("she also understands the importance of a parents' decision
  in the school the child attends") — same magnitude-ambiguity trap as the Caldwell wave: no funding
  mechanism named, so it can't distinguish `school-vouchers` chairs 3/4/5. Skip.
- **HB26-1063** long title mentioned "Treating People with Behavioral Health Disorder" (sounded
  promising for jail-capacity/judicial diversion) — bill TEXT was pure administrative website-
  publication of a transportation-provider list. Title was misleading; text killed it. Reinforces
  "read the bill text, never the title."
- No individual House-floor vote record was retrievable for any pre-2026 bill (e.g. HB22-1279
  Reproductive Health Equity Act) — `leg.colorado.gov/bills/<num>` shows the aggregate tally (e.g.
  "40 AYE 24 NO 1 OTHER") but not a per-member roll call in the WebFetch-rendered view. Don't expect
  to recover individual pre-2026 votes this way.

## Sources confirmed dead or empty for this specific legislator
`completecolorado.com/?s=` (empty), `pikespeakbulletin.org/?s=` (empty), `socoinsider.com/?s=`
(empty), `krdo.com/?s=` (404), `justfacts.votesmart.org/candidate/biography/<id>/<slug>` guessed URL
(403 — id was fabricated/guessed, not confirmed real; don't reuse this ID). `coloradopolitics.com`'s
site search worked (returned the "FOCUS ON THE SPRINGS" column, a Hannah Metzger byline that
covered her 2023 bills in real depth) but is topic-blind — it kept returning generic unrelated
results for topics she has no coverage on (AI, data centers, redistricting, religious freedom,
transgender, immigration, housing) rather than an empty result, so a "no articles found" response
from it is not strong evidence of absence, just of no hit in whatever excerpt the search tool saw.

## Takeaway for future thin-record reps
0/28 is a legitimate outcome distinct from a research-effort shortfall. This pass ran ~30 WebFetch
calls (bill list, bill-text reads, 15+ topic-qualified coloradopolitics queries, all four cohort
tier-2/3 outlets, votesmart, a leg.colorado.gov historical-vote check) and still landed on zero,
because the specific record that exists (health-licensing bills, sunset reviews, caucus letters) is
consistently one axis-step away from every ladder's actual question. Don't force an adjacent-axis
citation just because it's well-sourced — axis mismatch is a skip, same as magnitude ambiguity or
the sponsorship trap.
