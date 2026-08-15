# Task 10's 20 blanks, re-checked against the 10% corpus

**Closed 2026-08-15. 2 rows seated (mig 1759). 18 of the 20 officials stay blank.**

Task 10 seated 9 rows across 5 of 25 officials. This pass re-examined the other 20 after discovering
that the divided-vote corpus had been built at the wrong threshold.

## Two blind spots, neither of them a research failure

**1. The divided-vote threshold.** `votefirst.py divided` defaults to `--min-oppose 0.20`, and the
cached corpus was built at that default. **A 20% floor cannot see an 8-1 or 9-2 full-council vote** —
11% and 18% against. On a nine-member council that band is exactly where the lone dissent and the
narrowly-carried authored bill live. Re-running at `0.10`:

| corpus | @20% | @10% | newly visible |
|---|---|---|---|
| King County (2018+, 12,631 items) | 118 | **260** | 142 |
| Seattle (2020+, 10,639 items) | 146 | **284** | 138 |

Filtering the 280 newly-visible items to those that are on-topic **and** touch one of the 20 blank
officials gives **89 candidates**.

**2. Cross-office service.** Teresa Mosqueda is bucketed as a King County councilmember, so only King
County Legistar was searched for her. She served on the **Seattle City Council 2018–2023**, and the
Task 10 write-up states in as many words that her record starts in 2024. Her Seattle service was never
examined at all — this is independent of the threshold.
🔑 **A member's corpus is defined by WHERE THEY SERVED, not by which government currently lists them.**
The cross-office precedent already existed: Zahilay's jail row is evidence from his council service,
written after he became County Executive.

## Method: sponsor/mover is the strong filter, not vote membership

A Yes inside an 8-1 is the consensus side and rarely describes a chair; a No against a proposal is
direction rather than a chair — both already adjudicated in this corpus. What actually seated Task 10
rows was **authorship** (Perry "sponsor + mover" on Ord 19613; Dembowski sponsor on Motion 16361). So
the 89 candidates were re-filtered to items a blank official **sponsored or moved**: **27 items**.

## ✅ Seated

**Jorge Barón / `local-immigration` = 2** — Ordinance 19963 (2025-0216), passed **8-1** on 2025-08-19.
Barón is its **sole sponsor**, **moved it to passage**, and voted yes. It extends K.C.C. chapter 2.15 —
the chapter created by **Ordinance 18665, the very instrument that seated Balducci and Dembowski at
this chair** — to county contractors. Contractors may not spend resources facilitating civil
immigration enforcement, and may not admit ICE/CBP/USCIS to nonpublic areas or databases "absent a
judicial criminal warrant specifying the information or persons sought". That judicial-warrant
condition is chair 2's mechanism.
**Chair 1 fails on both clauses, by refutation not absence:** its detainer clause is refuted by the
chapter being amended (18665 *honours* detainers accompanied by a judicial warrant), and its
information-sharing clause is contradicted twice in this ordinance's own text — a contractor "is not
prohibited from sending to, or receiving from, federal immigration authorities, the citizenship or
immigration status of a person."
⚠ The Seattle sponsorship discount does not apply: this is King County and there is no
executive-transmittal line in the history.

**Teresa Mosqueda / `taxes` = 1** — CB 119810 (Ord 126108) and CB 119811 (Ord 126109), Seattle,
2020-07-06. **Co-sponsor of both and voted for both** — the exact standard applied to Strauss on this
same instrument pair, which the operator approved. Seating her differently on identical evidence would
make the corpus inconsistent with itself. The §2.A counter-argument is carried forward verbatim in the
row's own reasoning rather than quietly dropped.

## ⬜ Not seated, and why

- **Reagan Dunn** is the lone No on a large share of the newly visible 11% items (39 of the 89
  appearances). **Opposing a proposal is direction, not a chair** — the same disposition Task 10 gave
  him on jail-capacity and local-immigration. His habitual dissent also makes a lone No a weak
  discriminator for him specifically.
- ⚠ **Dunn's committee dissents reverse.** On 2023-0438 and 2024-0315 he voted No in committee and Yes
  at a unanimous full council. For this member a committee No is not evidence without checking final
  passage.
- **Kettle, Rivera, Saka, Rinck, Hollingsworth** sponsor or dissent only on surveillance-technology
  authorisations, solid-waste rates, levy *implementation plans*, a jail interlocal agreement, and
  graffiti enforcement. None of these describes a ladder; several are "acknowledging receipt of a
  report", which Task 10 already established is not a position.
- **Pete von Reichbauer** sponsors ballot-submission ordinances and the Regional Homelessness Authority
  interlocal agreement — governance instruments that create a body rather than state a strategy.
- **Juarez** was already assessed and blank by Task 10 (voted against the JumpStart tax and for the
  spending plan — consistent with chairs 3, 4 and 5 alike).
- **Evans, Katie Wilson, Cole-Tindall, Manion, John Wilson, Wise, Foster, Lin, Fain, Rhonda Lewis** have
  little or no roll-call record: several are non-legislative offices (City Attorney, Mayor, Sheriff,
  Prosecuting Attorney, Assessor, Director of Elections) and six took office in January 2026. The
  vote-first method cannot reach them at all.

## 🔑 Carry forward

**Check the threshold before trusting an absence.** A default that hides the 10–20% band hides exactly
the votes a small legislative body produces. Both rows seated here came from that band.

**"Thin record" can mean "wrong corpus".** Mosqueda looked like a 2024-onward member with nothing to
show; she authored Seattle's largest progressive tax two years before that.

**Sponsor/mover beat votes 27:89 as a filter, and 2:0 as a producer of rows.** Neither seated row came
from a vote tally — both came from authorship.
