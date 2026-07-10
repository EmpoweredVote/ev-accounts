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
