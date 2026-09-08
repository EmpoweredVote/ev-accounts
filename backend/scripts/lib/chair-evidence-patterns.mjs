/**
 * chair-evidence-patterns.mjs — the lexical tests audit-chair-evidence.mjs gates on.
 *
 * Extracted from that script 2026-09-08 so the patterns can be pinned by a test. They had been
 * widened five times with no regression cover, and the sixth widening was prompted by a FALSE FAIL
 * on eleven rows that each named an adopted resolution. A detector nobody can test is a detector
 * nobody can trust — see scripts/lib/chair-evidence-patterns.test.ts.
 *
 * ⚠ Behaviour is unchanged apart from the documented sixth widening. The rationale below is the
 * original, moved intact: it records what each alternative admits and, more usefully, what it
 * refuses. Read it before adding one.
 */

// Does the reasoning name something that can distinguish ONE chair from its neighbour — a bill, an
// act, an ordinance, a recorded vote? A description of direction cannot.
// ⚠ MUNICIPAL VOCABULARY (added 2026-08-13, mig 1738). The original pattern was built for state
// legislatures and could not see a single thing a CITY COUNCIL does — 14 of the 31 California rows
// named a real instrument it scored as "directional only". The additions are deliberately NARROW,
// because the point is never that a word appears:
//   · "Resolution No." / "Ordinance No." require the NUMBER, so a numbered adopted instrument
//     passes and a passing mention of "the sanctuary ordinance" does not.
//   · "referral approved/adopted/considered" requires the referral to have been ACTED ON. Berkeley
//     referrals carry no number, and an unqualified "referral" would have admitted the withdrawn
//     item this very migration had to remove (2025-03-11 Item 15, "removed from the agenda").
// ⚠ WIDENED TWICE, EACH TIME ONLY ALONGSIDE ROWS ALREADY VERIFIED BY READING THE SOURCE.
// The original list was STATE-LEGISLATURE shaped and could not see a city council's vocabulary at
// all; mig 1738 added the municipal terms, requiring a NUMBER so that an unadopted referral could not
// sneak through. Mig 1740 adds the two forms a MAYOR's record takes, for the same reason:
//   · `Measure \d+\.\d+` — a numbered measure inside an adopted municipal plan. San Diego's 2022
//     Climate Action Plan is Gloria's actual instrument (he proposed and signed it; the Council
//     adopted it unanimously), and its commitments live in numbered measures such as Measure 1.1
//     "phase out 45% of natural gas usage from existing buildings by 2030". The decimal is required
//     precisely so that vague prose, or a bare ballot "Measure A", cannot satisfy it.
//   · `O-#####` / `R-######` — San Diego's ordinance and resolution numbering, e.g. Ordinance
//     O-21528 N.S. (Climate Action Plan Consistency Regulations) and Resolution R-316659.
// ⚠ WIDENED A THIRD TIME (2026-08-19, Travis County wave), for the vocabulary of a COUNTY
// COMMISSIONERS COURT. The pattern was state-legislature shaped, then learned city councils (1738)
// and mayors (1740); it still could not see a single thing a county does. Two additions, both
// deliberately narrow and both copying the shape of an existing rule:
//   · `Proposition [A-Z0-9]{1,3}` — a LETTERED/NUMBERED ballot proposition. This is the "Measure A"
//     objection answered rather than repeated: the identifier is required, so vague prose cannot
//     pass, and the rows it admits are county propositions actually put to and carried at an
//     election (Travis County Proposition A, Nov 2024, 59.43%). A county's budget-and-ballot
//     instruments have no bill number; this is the identifier they do have.
//   · `Commissioners Court (approved|adopted|voted)` — requires the BODY TO HAVE ACTED, exactly the
//     test already applied to `referrals? (approved|adopted|considered)`. An unqualified
//     "Commissioners Court" would have admitted every passing mention of the body and is not used.
// ⚠ WHAT THIS WIDENING DELIBERATELY DOES NOT RESCUE. Five rows in the same verified wave still fail,
//    and that is the correct result, not an oversight: a diversion steering committee, a solar
//    installation programme, an early-case-review process and a campaign platform are PROGRAMMES,
//    not instruments. They may well be sound evidence, but they are not the thing this gate tests,
//    and inventing lexical hooks for them would make passing mean nothing.
// 🔑 The point of the gate is that PASSING MEANS SOMETHING. All three widenings were paired with rows whose
//    instruments had been read in the source document, and in each case the recorded proof is that the
//    debt fell by exactly the number of rows touched — never more.
// ⚠ WIDENED A FOURTH TIME (2026-08-24, NC stance campaign), for two FALSE NEGATIVES measured on the
// three-person NC pilot — rows whose evidence was read at the source and confirmed, which this gate
// nevertheless failed. Same discipline as the three widenings above: narrow, identifier-bearing, and
// paired with rows already verified by reading the instrument.
//   · `(House|Senate) Bill \d` — North Carolina numbers its bills `H 509` / `S 467`, not `HB 509`, so
//     an NC citation written in house style was invisible here. The fix requires the CHAMBER WORD and
//     the number rather than admitting a bare `H\d`, which would match far too much ordinary prose.
//     Verified rows: H509 Right to Reproductive Freedom Act and H20 Fair Maps Act (operative text read
//     on ncleg.gov), H1189 Datacenter Transparency Act (moratorium text read), H1229.
//   · `S.L. 20NN-NNN` — a North Carolina SESSION LAW, the identifier an enacted bill carries after
//     ratification. Verified row: Mayfield's Aye on H951/S.L. 2021-165.
//   · CASE. The pattern was case-sensitive, so `Voted Aye` and `Senate Roll Call S-464` both failed
//     while `voted AYE` and `roll call` passed. That is an accident of transcription, not a
//     difference in evidence. Only the vote/roll-call alternatives are made case-tolerant — the whole
//     regex is NOT given an `i` flag, because `\bAct\b` would then match the ordinary verb "act" and
//     passing would stop meaning anything.
// ⚠ WIDENED A FIFTH TIME (2026-09-08, Senate gun-policy pass), for a whole COHORT of false negatives:
// U.S. SENATE bills. The pattern had `\bH\.R\.` from the start but never its Senate sibling, and named
// a federal statute only when the title carried the word `Act`. So every row citing a Senate bill by
// number, and every named federal statute whose title is a `Ban of <year>` rather than an `Act`,
// scored "directional only" — including the LIVE CC_0074 rows (Padilla, Schiff, "the Assault Weapons
// Ban of 2025") and all 42 Assault Weapons Ban rows of CC_0078, each verified at source by
// verify-reresearch-rows (every distinctive term present in the cited bill text). Two additions, both
// narrow and identifier-bearing, both paired with rows already verified by reading the instrument:
//   · `S. <number>` — a U.S. Senate bill, the sibling of `\bH\.R\.`. The negative lookbehind
//     `(?<![A-Za-z]\.)` keeps it from firing on a preceding initialism or middle initial, so
//     `U.S. 2024` and `Angus S. King` do NOT match while `S. 1531` and `S.1531` do. A digit is
//     required, exactly so a bare middle initial cannot pass. Verified rows: CC_0078's S. 1531 / S. 25
//     / S. 3214 cohort.
//   · `Ban of <year>` — a named federal statute whose short title ends in a ban and a year rather
//     than "Act", e.g. "Assault Weapons Ban of 2025" (S. 1531) and "Assault Weapons Ban of 2023"
//     (S. 25). The capitalised `Ban` and the four-digit year are both required, so ordinary prose
//     ("a ban of some kind") cannot satisfy it. Verified rows: the same cohort, whose reasoning names
//     the ban by its exact short title, present in the cited bill text.
// ⚠ WIDENED A SIXTH TIME (2026-09-08, Miami-Dade transportation pass), for a FLORIDA COUNTY BOARD.
// The pattern learned city councils (1738), mayors (1740), a commissioners court (Travis) and the
// U.S. Senate (CC_0078), and still could not see a single thing the Miami-Dade Board of County
// Commissioners does. `\bR-\d{5,6}\b` was San Diego-shaped and requires five or six digits, so
// `R-551-26` — three digits and a two-digit year — never matched. Measured: 8 of the 11 attributed
// Miami-Dade rows in the open season scored "directional only" while every one of them names an
// adopted resolution by number. One addition, identifier-bearing, paired with rows already verified
// by reading the instrument:
//   · `R-<1-4 digits>-<2 digits>` — a Miami-Dade County resolution, e.g. R-551-26 (the RTCBPA
//     density bonus), R-992-25 (first-and-last-mile transit) and R-446-25 (the standardised master
//     development agreement). Both the `R-` prefix and the two-part number are required.
// ⚠ WHAT THIS DELIBERATELY DOES NOT ADMIT: the county ORDINANCE form, a bare `25-59` / `26-51`.
//    Two digits, a hyphen and two more digits is a date range, a score and a code section as often
//    as it is an instrument, and admitting it would make passing mean nothing. It costs nothing
//    here: every Miami-Dade row that names an ordinance also names a resolution, so all 11 pass on
//    the rule above. Cite the resolution number alongside the ordinance and the gate can see it.
export const NAMES_INSTRUMENT =
  /(\bHB\s?\d|\bSB\s?\d|\b(?:House|Senate) Bill \d{1,4}\b|\bS\.L\. 20\d{2}-\d{1,4}\b|\bH\.R\.|\bS\.J\.Res|\bAB-?\s?\d|\bLD\s?\d|\bSJR\s?\d|\bAct\b|\bOrdinance\b|[Vv]oted (YES|Yes|NO|No|Yea|YEA|Nay|NAY|AYE|Aye)|[Rr]oll [Cc]all|Chapter \d|Resolution No\.|Ordinance No\.|referrals? (approved|adopted|considered)|recorded roll call|Measure \d+\.\d+|\bO-\d{4,5}\b|\bR-\d{5,6}\b|\bProposition [A-Z0-9]{1,3}\b|Commissioners Court (approved|adopted|voted)|(?<![A-Za-z]\.)\bS\.\s?\d{1,4}\b|\bBan of (?:19|20)\d{2}\b|\bR-\d{1,4}-\d{2}\b)/;
// A source that could carry such an instrument, as opposed to a bio or an aggregator profile.
export const INSTRUMENT_SRC =
  /(legislature|mgaleg|leginfo|congress\.gov|govtrack|clerk\.house|senate\.gov\/legislative|\/bill|\/legislation|rollcall|roll_call|ordinance|agenda|minutes|\.pdf|capitol|legiscan)/i;
