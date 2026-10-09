"""Per-(topic, S1 rung) CARRY rulings for the absence tier-A queue.

⚖ THE QUESTION. Every row here is a Season 1 row with no Season 2 answer, so repairing it means
writing FORWARD into Season 2. That is only a renumbering when the S2 rung ASKS THE SAME THING.
mig 1903 blanked 13 rows wrongly by not asking; the candidates cohort found the inverse — ladders
that silently changed the question (voting-rights became an IDENTIFICATION ladder, climate-change
rung 3 became permitting-and-grid).

Ruled by reading the S1 and S2 rung text side by side. One ruling per (topic, rung) covers every
row at that position — the ladder is a property of the topic, not of the person.

CARRIES      the S2 rung asks the same thing, or asks LESS (a dropped limb cannot un-earn a seat).
NEEDS_READ   the S2 rung ADDS a requirement, or drops a safeguard that changes who belongs there.
             Not decidable from the ladder; the evidence has to be read.
NO_CARRY     the S2 rung asks a DIFFERENT QUESTION. The S1 seat says nothing about it, and no
             amount of renumbering helps. These blank, citing the ladder — they are not evidence
             failures and must not be recorded as if the research was wrong.
"""
RULINGS = {
    # ── CARRIES: identical substance, or S2 dropped a limb so it asks LESS ────────────────────
    ('school-vouchers', 1.0): ('CARRIES', "S2 drops 'fully funding public schools' and keeps only "
                               "'eliminating voucher programs' — one limb instead of two, so anyone who met S1 meets S2"),
    ('school-vouchers', 4.0): ('CARRIES', "S2 drops 'while maintaining baseline public school funding'; asks less"),
    ('ai-regulation', 3.0): ('CARRIES', "S2 drops the disclosure limb and keeps legal responsibility for harm; asks less"),
    ('deportation', 2.0): ('CARRIES', 'pure rewording: "people without legal status" -> "undocumented immigrants"'),
    ('deportation', 3.0): ('CARRIES', 'pure rewording'),
    ('deportation', 4.0): ('CARRIES', 'pure rewording'),
    ('deportation', 5.0): ('CARRIES', 'pure rewording'),
    ('medicare/aid', 2.0): ('CARRIES', 'S2 generalises "lower Medicare age to 55" to "significantly expand '
                            'eligibility, stopping short of universal"; same position, broader wording'),
    ('medicare/aid', 4.0): ('CARRIES', '"partially privatize and reduce" -> "scale back both, shifting to private"'),
    ('same-sex-marriage', 2.0): ('CARRIES', 'S1-2 -> S2-3 per rung_map; "some organizations" narrowed to '
                                 '"religious organizations", same substance'),
    ('city-sanitation', 3.0): ('CARRIES', 'same two limbs, reworded'),
    ('judicial-interpretation', 5.0): ('CARRIES', 'same substance, shorter'),
    ('economic-development', 2.0): ('CARRIES', 'same substance'),
    ('homelessness', 2.0): ('CARRIES', 'S2 keeps decriminalisation and drops the investment limb; asks less'),
    ('data-centers', 2.0): ('CARRIES', 'S2 keeps the cost-shifting bar and drops the dedicated-generation limb; asks less'),
    ('homelessness-response', 2.0): ('CARRIES', 'both are "expand services"; S1 adds an enforcement-sequencing '
                                     'clause that does not change who belongs at the rung'),
    # housing: rung_map {1:1,2:3,3:4,4:5,5:5} -- an INSERTED rung at 2, so S1-4 and S1-5 both land on
    # S2-5. ⚠ That is a MERGE: S2-5 can no longer tell "deregulate so builders build" from "stay out
    # entirely". The seat carries; it is simply less precise than it was.
    ('housing', 4.0): ('CARRIES', 'rung_map 4->5; S2-5 merges S1-4 and S1-5 (market reliance, deregulation at most)'),
    ('housing', 5.0): ('CARRIES', 'rung_map 5->5; merged with S1-4 as above'),

    # ── NEEDS_READ: S2 added a requirement or dropped a safeguard ────────────────────────────
    ('economic-development', 3.0): ('NEEDS_READ', 'S2 ADDS a clawback — "pay the money back if they '
                                    "don't deliver\". A row seated on incentives-with-conditions may not meet it."),
    ('homelessness', 4.0): ('NEEDS_READ', 'S2 drops "while requiring jurisdictions to maintain basic shelter '
                            'options", so S2-4 is purely punitive where S1-4 was enforcement WITH a safeguard'),
    ('voting-rights', 3.0): ('NEEDS_READ', 'both concern ID, but S1 guarantees free IDs and S2 substitutes an '
                             'affidavit route — a different accommodation'),
    ('voting-rights', 4.0): ('NEEDS_READ', 'S2 is the IDENTIFICATION ladder; check the evidence is about ID '
                             'and not about roll maintenance'),
    ('climate-change', 4.0): ('NEEDS_READ', '"let market forces drive the transition" -> "stay neutral and let '
                              'the market choose"; closest of the climate rungs, but the ladder changed axis'),

    # ── NO_CARRY: the S2 rung asks a DIFFERENT QUESTION ──────────────────────────────────────
    # 🔴 climate-change was re-asked wholesale: S1 graded SPEED AND COMPULSION, S2 grades MECHANISM.
    # Already recorded in [[ma_profile_only_cohort]] and [[ladder_scope_findings]] for rungs 1/2/3;
    # rung 5 is the same story and is added here.
    ('climate-change', 2.0): ('NO_CARRY', 'S1 "rapidly transition and phase out fossil fuels by 2030" (a SPEED '
                              'commitment) -> S2 "fund clean energy with subsidies, tax credits and public investment" (a MECHANISM)'),
    ('climate-change', 3.0): ('NO_CARRY', 'S1 "invest in clean energy while gradually reducing fossil fuels" -> '
                              'S2 "speed up clean energy by cutting permitting red tape and upgrading the grid"'),
    ('climate-change', 5.0): ('NO_CARRY', 'S1 "reject climate change policies and focus on economic growth" (a '
                              'POSITION ON CLIMATE POLICY) -> S2 "end government subsidies and mandates for clean energy" (a SPECIFIC MECHANISM)'),
    ('homelessness-response', 3.0): ('NO_CARRY', 'S1 "invest in outreach, shelter and mental health services" -> '
                                     'S2 "maintain current programs at today\'s funding level, with no major new spending". Active investment vs status quo.'),
    ('homelessness-response', 4.0): ('NO_CARRY', 'S1 "enforce anti-camping ordinances as the primary tool" -> '
                                     'S2 "provide limited public funding to nonprofits and charities to lead". Enforcement vs delegation.'),
    ('homelessness-response', 5.0): ('NO_CARRY', 'S1 "strict enforcement, minimise spending" -> S2 "withdraw '
                                     'funding, treat as a matter for private charity and the market"'),
    ('campaign-finance', 3.0): ('NO_CARRY', 'S1 "require full disclosure of all political donations" -> S2 "keep '
                                'contribution limits at current levels". Disclosure and limits are different questions.'),
    ('misinformation', 2.0): ('NO_CARRY', 'S1 "mandate fact-checking and algorithmic transparency" -> S2 "require '
                              'platforms to LABEL false content rather than remove it"'),
    ('school-vouchers', 2.0): ('NO_CARRY', 'S1 "restricting vouchers to low-income families who lack adequate '
                               'local options" ALLOWS targeted vouchers; S2 "opposing voucher programs and blocking their expansion" does not'),
    ('voting-rights', 2.0): ('NO_CARRY', 'S1 "expand early voting and no-excuse mail-in voting" (ACCESS) -> S2 '
                             '"accept non-photo identification" (IDENTIFICATION). The documented axis change.'),
    ('childcare', 4.0): ('NO_CARRY', 'S1 "reducing regulations on providers to increase supply" (DEREGULATION) -> '
                         'S2 "limiting government support to subsidies for the lowest-income" (MEANS-TESTING). Already recorded in [[ma_profile_only_cohort]].'),
    ('campaign-finance', 2.0): ('CARRIES', 'same substance, reworded'),
}
