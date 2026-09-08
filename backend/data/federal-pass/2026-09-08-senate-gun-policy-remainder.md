# The four senators gun-policy does not seat

Season 2, measured 2026-09-08 after `CC_0079`. gun-policy holds **96 answers for 100
sitting senators**. These are the four it does not, why sponsorship cannot settle any of
them, and what would.

Written so nobody repeats the read. Each of these was opened; the refusal is the finding.

| senator | gun-policy leads | on-axis | disposition |
|---|---|---|---|
| Rand Paul | 2 | 1 | refused — direction clear, rung not |
| Lisa Murkowski | 2 | 1 | refused — wrong question |
| Susan M. Collins | 0 | 0 | no instrument |
| Alan Armstrong | 0 | 0 | no record yet |

## 🔴 A correction this file exists partly to make

`CC_0078` and `CC_0079` both say Alan Armstrong's zero leads are "the signature of a
bioguide that did not resolve, not of a senator with no record". **That is wrong, and both
migrations are already applied.** Checked against the Congress API on 2026-09-08:
`A000383` resolves to Alan Armstrong, Republican, Oklahoma, `currentMember: true`, a
Senate term in the 119th Congress beginning 2026.

He is a real sitting senator with a real bioguide. His zero leads are the ordinary
consequence of having been in office roughly six months — the same shape as Jon Husted
(2 leads) and Bernie Moreno (4), further along. The claim was repeated three times before
anyone checked it, which is the actual lesson: "this looks like a data defect" is a
hypothesis, and a one-request lookup was available the whole time.

The migration headers carry a pointer to this file rather than being rewritten, since what
they record is what was applied.

## Rand Paul — refused

    on-axis   SJRES. 20  2023-03-15  CRA disapproval of the ATF rule "Factoring Criteria
                                     for Firearms With Attached 'Stabilizing Braces'"
    off-axis  S. 119     2026-04-15  No Retaining Every Gun In a System That Restricts
                                     Your Rights Act — records retention, not which
                                     firearms are legal or who may carry

The direction is not in doubt: disapproving the brace rule is opposing a restriction on a
class of firearm. The RUNG is. Rung 4 — "add no new restrictions, and at most loosen rules
on carrying" — fits the evidence in hand exactly, and almost certainly **understates him**:
Paul's public position sits nearer rung 5, and he is absent from the carry-reciprocity bill
that 47 of his colleagues signed, so the ladder's own strongest signal for him is missing
rather than negative.

Seating him at 4 off one 2023 CRA vote would publish a claim that the record neither
compels nor contradicts. `CC_0074`'s standard: an absent row is honest, a thin one is not.

**What settles it:** his own issues page, or a carry bill he does sponsor. Absence from
S. 65 is worth understanding before anything is written — it is unusual enough to be
informative either way.

## Lisa Murkowski — refused

    on-axis   SJRES. 83  2024-06-17  CRA disapproval of the ATF rule "Definition of
                                     'Engaged in the Business' as a Dealer in Firearms"
    off-axis  S. 1907    2023-06-08  Federal Firearms Licensee Protection Act of 2023 —
                                     penalties for theft from dealers, a crime bill

⚠ THE INSTRUMENT IS AMBIGUOUS IN A WAY THE LADDER CANNOT ABSORB. A Congressional Review Act
disapproval says the AGENCY should not have made this rule. It does not say the underlying
policy is wrong, and for a senator with a documented record of supporting expanded
background checks those two readings point at different rungs.

This is `CC_0074`'s military-intervention refusal exactly: a war powers cosponsorship is
about WHO AUTHORIZES force where the ladder asks WHEN force is warranted. Real evidence,
wrong question. One CRA vote plus a theft-penalty bill cannot separate "opposes background
check expansion" from "opposes rulemaking by ATF".

**What settles it:** a floor vote on a background-check bill, or her own issues page.

## Susan M. Collins — no instrument

Zero gun-policy leads. The sweep worked for her — she carries 23 leads across other topics
— so this is genuine silence in the sponsorship record, not a gap in the data. She does not
sponsor gun bills.

**What settles it:** a roll-call vote or her issues page. And note the first of those is
not currently available (below).

## Alan Armstrong — no record yet

Zero leads on any of the nine topics, because the record is roughly six months long.
Sponsorship will not settle any topic for him for some time, and re-sweeping will not help.

**What settles it:** his campaign or office issues pages. He is the clearest case in the
cohort for reading statements rather than instruments.

## ⚠ Roll-call votes are NOT available for this cohort, despite the table

`essentials.legislative_votes` holds 121,178 rows and looks like the obvious instrument for
Collins and for confirming Paul. It is not: measured 2026-09-08, all 121,178 rows come from
LegiScan and cover **58 politicians, none of them sitting U.S. senators**. It is
state-legislature data.

    SELECT count(*) FROM essentials.legislative_votes
     WHERE politician_id IN (<sitting U.S. senators>);   -- 0

So "check the roll call" is not a next step here, it is a data-acquisition project. Anyone
reaching for it should know that before planning around it.

## What this says about the triage

All four were reachable from `federal-pass-triage.mjs`, and it classified them correctly.
Paul and Murkowski came out `settleable` — which the tool defines as "there is a lead worth
OPENING", never "this settles". Two of the two settleable ones ended in no row, which is the
documented outcome, not a miss.

Collins and Armstrong came out `no-lead`, and the tool's note for that verdict — "silence is
not a position; it needs another instrument" — is exactly right for both, for two completely
different reasons that no automated verdict could have separated.
