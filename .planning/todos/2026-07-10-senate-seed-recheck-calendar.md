# 2026 Senate deep seed — dated re-check calendar (mig 1296, seeded 2026-07-10)

All 35 Senate races seeded/fixed per the verification-pass rules (one ballot-access evidence bar
for all parties; unverified names NOT seeded). Every date below is a follow-up gate. Evidence
trails: scratchpad wsen/verify_group[123].json + group_*.json; master board artifact.

## July 2026
- **Jul 14** — DE filing deadline: re-pull DE primary field (seeded 6 as `filed`; field can grow).
  GA: check mvp.sos.ga.gov whether Allen Buckley (L) completed his petition ("QUALIFIED -
  SIGNATURES REQUIRED", filed 3/2) → add to GA general if certified. GA indies (Bartell/Jackson)
  final confirmation of non-qualification.
- **Jul 15** — SC independent petition deadline (10k sigs, noon): 6 held indies (Ellison, Glaser,
  Louis, Sedletsky, Strunge, Wright-McDonald) → county cert by Aug 17; check VREMS after Aug 17.
- **~Jul 27** — **ME Democratic convention** picks replacement nominee (Platner withdrawn 7/8,
  rc d08e6373 marked withdrawn; statutory deadline 5pm 7/27). Candidates announced: Bellows,
  Jackson, Kleban, Shah, Wood. Seed nominee into ME general when certified.
- **Jul 30** — OH: SOS protest window closes for Gregory Levy (I) petition → add to OH special
  general if certified (county lists 6/16 did NOT show him).

## August 2026
- **Aug 1** — WV: minor-party certificate deadline — confirm S. Marshall Wilson (Constitution,
  seeded active) not stricken.
- **Aug 3** — NE: Burbank (D) withdraw-or-stay decision (pledged to consider backing Osborn;
  must withdraw by 8/3 to be off ballot). Update NE general accordingly.
- **Aug 4** — MI + KS + VA primaries: resolve nominees → populate/adjust generals; MI McMorrow
  suspended-but-on-ballot (votes count); VA R nominee (Farington/Mizusawa/Williams) joins Warner.
  MI minor-party direct-to-general (Marsh G, Christensen L) — verify vs MI BOE and add.
- **Aug 6** — TN primaries: Hagerty (R) + D nominee → general. Resolve McCants discrepancy
  (SOS-listed but BP-withdrawn; seeded `filed` pending).
- **Aug 11** — MN primaries → nominees to general. KY: political-group petition sufficiency —
  confirm Christopher Campbell (Kentucky Party, seeded active) survived.
- **Aug 17** — SC county boards certify petition candidates (noon) → re-check VREMS, add any of
  the 6 held indies who qualified.
- **Aug 18** — AK top-four primary (top 4 → RCV general; seed all 4, RCV thoroughness rule),
  FL special primaries (R: Moody field; D: Nixon/Vindman), WY primaries. FL NPA direct-to-general
  (Churchill, Gillespie) — verify vs FL DOE and add with the nominees.
- **Aug 20** — MT: SOS ballot certification — confirm Bodnar (I, seeded active on 160% county-
  verified signatures) certified.
- **Aug 24** — TX: LP convention-nominee certification to SOS (TEC §181.068) — confirm Ted Brown
  (seeded active). OH write-in deadline (Faris — write-ins not surfaced; informational).
- **Aug 25** — OK Democratic runoff (Thomas vs Priest) → winner joins OK general (Hern/White/
  Meinhardt/Stinnett seeded). MA: non-party SOS filing deadline → check the 4 held (Devincentis,
  Tache, Ayyadurai, Dawicki) ~Sep 1.
- **~late Aug** — OR minor-party convention certificates → re-check OR general (currently 2).
  IL: formal ballot certification — confirm Harrington (American Center) + Muhammad (I).

## September 2026
- **Sep 1** — MA primaries (Markey vs Moulton; Deaton) → general. NJ minors re-check vs NJ
  Division of Elections official general list (Fernandez, Kuniansky, Rivera, Maldonado, Misseri —
  BP-listed, held).
- **Sep 4** — CO: SOS ballot certification — confirm Chew (Forward) + Withrow (Unity), both
  seeded active on assembly-designation evidence.
- **Sep 8/9** — NH primaries (open seat; Pappas field vs Sununu/Brown field); RI primaries
  (RI list was UNOFFICIAL at seed — re-pull official list first; seeded 5 as `filed`).
  NH held indies (Giovonizzi, Harris) + KS Graham (L) — verify vs state lists.
- **Sep 15** — DE primaries → general.
- **~Sep** — NM: SOS posts general qualification list — final confirmation Channon/Chick culls.

## December 2026
- **Dec 1** — GA + MS general RUNOFF date if no candidate wins a November majority.

## Standing notes
- OK general currently has NO Democratic candidate (runoff pending) — correct, not a gap.
- ME general currently = Collins + withdrawn Platner (D slot vacant) — correct until convention.
- Dual-pid merge todo: `.planning/todos/2026-07-10-senate-dual-pid-merge.md` (AFTER this seed).
- politicians.is_incumbent DEFAULTS TRUE — mig 1296 set false explicitly on all 114 new pols.

## FLAG added 2026-07-10 (stance wave): Kevin Lee McCants TN — possible Senate withdrawal
- Stance agent found Ballotpedia listing McCants as WITHDRAWN from the U.S. Senate D primary and declared for TN GOVERNOR (D primary, same Aug-6 date).
- Wikipedia (fetched 2026-07-10) still lists him as DECLARED in BOTH races — conflicting.
- ACTION: verify against TN SOS certified Aug-6 primary ballot (sos.tn.gov); if confirmed, remove McCants (pid 3870e67b-a38c-44e0-8800-ac0dab0e29ea) from the Senate race_candidates row. His stance data attaches to the politician and stays valid either way.

## FLAGS added 2026-07-10 (stance wave): MA Senate primary withdrawals
- **Alexander Rikleen (pid 243a8673-...) WITHDREW** from MA D primary, endorsed Markey; campaign site = "campaign concluded" page. Verify vs MA SoS certified Sep-1 ballot; remove from race_candidates if confirmed.
- **William Gates (pid 590e8d87-...) WITHDREW** — likely missed MA D convention 15% delegate threshold; site shows "Thank You Democratic Delegates"; $0 raised per Ballotpedia. Same verification path.
- Party backfilled on politicians (was NULL): Rikleen D, Gates D, Deaton R. Nathan Bech party still NULL — confirm when his batch runs (gen-mixed).

## FLAG added 2026-07-10 (stance wave): Allen Waters RI — Senate candidacy likely dormant
- FEC Senate committee (S6RI00262) has only a Nov-2024 Statement of Candidacy, no financial activity since; same treasurer runs an ACTIVE watersformayor.com campaign (Providence Mayor, "Independent"/"Providence First", launch video Feb-6-2026) conflicting with his Republican Senate registration.
- Verify vs RI SoS certified Sep-9 primary ballot; if he doesn't appear, remove from Senate race_candidates (pid 0802106b-e080-4466-8cb2-811b9ef3c5c1).

## FLAG added 2026-07-10 (stance wave): Christopher Beardsley DE — switched to STATE Senate run
- Wikipedia + his own site (beardsleyfordelaware.com) now describe a Delaware STATE Senate candidacy, not U.S. Senate; FEC federal committee still shows filings through 05/2026 (lagging).
- Verify vs DE certified Sep-15 primary ballot; if absent, remove from U.S. Senate race_candidates (pid 81ad76c3-18e1-4ba9-acab-81142f01cfbf). His 10 pushed stances are current personal positions — keep on politician record.
- Also noted: Shulli's real site = shulli.org (shulliforsenate.com is an unrelated squatter domain); Katz = party-switcher (2020 D presidential → 2024 I → 2026 R), healthcare stance reversal documented in reasoning.

## FLAG added 2026-07-11 (stance wave): Cindy Burbank NE — self-imposed Aug-3 withdrawal deadline
- Burbank (D, pid cec56151-0501-4f3f-bcb3-3aabbb97b4d0) publicly prefers Dan Osborn as the stronger anti-Ricketts candidate and set Aug-3-2026 as her decide-by date. She was also briefly removed/reinstated from the ballot (NE Supreme Court).
- RE-CHECK ≥ Aug-4: if she withdrew, update NE race_candidates.
- Context also: Mike Marvin (LMN) accused of being an "Osborn plant"; Burbank paid his filing fee — field may shift together.
