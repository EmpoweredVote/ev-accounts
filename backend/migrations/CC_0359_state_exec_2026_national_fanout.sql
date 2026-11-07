-- CC_0359 — 2026-11-03 state executives, the national fan-out: create the 73 races AP has
--           called on seats we hold but had no race row for, seed the 143 candidates we
--           hold no row for, and record AP's results across 30 states.
--
-- WHY THIS FILE EXISTS. CC_0357 recorded 18 state-executive results and read as if the tier
--   were done. It was scoped to races WE ALREADY HELD — the right scope for a results
--   migration and the wrong scope for "are the state executives recorded", because 🔴 A RACE
--   THAT DOES NOT EXIST PRODUCES NO ROW, NO GAP AND NO ERROR. It is absent from every count
--   the migration takes, so nothing looks wrong. CC_0358 proved the repair on Texas; this
--   file is the rest. The check that finds the gap runs from the SOURCE's list, not ours:
--   backend/data/state-exec-2026-results/ap-state-exec-gap.mjs. Measured 2026-11-05:
--
--     AP state-executive races     104   (Governor, Lt Governor, Attorney General, Secretary
--                                        of State — the only four AP covers at this level)
--     called                        98
--       recorded by us              21   CC_0357 (18) + CC_0358 (3)
--       seat held, NO race row      73   ← THIS FILE, across 30 states
--       we hold no such seat         4   CT Secretary of State · DC Attorney General ·
--                                        MA Secretary of State · TX Railroad Commissioner
--     not yet called                 6   AK Governor (ranked choice) · IA AG · KS Gov/AG/SoS · OH AG
--
-- WHAT IT WRITES — nothing is updated or deleted; every statement is an INSERT:
--   143 politicians · 73 races · 212 candidacies (73 won, 139 lost)
--
--   AL   4 race(s),   8 candidac(ies),   7 seeded   into AL 2026 Statewide General
--   AR   4 race(s),   9 candidac(ies),   6 seeded   into AR 2026 Statewide General
--   CT   2 race(s),   4 candidac(ies),   2 seeded   into CT 2026 Statewide General
--   DE   1 race(s),   2 candidac(ies),   1 seeded   into DE 2026 Statewide General
--   FL   2 race(s),  10 candidac(ies),   8 seeded   into FL 2026 Statewide General
--   GA   4 race(s),   8 candidac(ies),   3 seeded   into GA 2026 Statewide General
--   HI   1 race(s),   2 candidac(ies),   0 seeded   into HI 2026 Statewide General
--   IA   2 race(s),   4 candidac(ies),   3 seeded   into IA 2026 Statewide General
--   ID   4 race(s),  12 candidac(ies),   8 seeded   into ID 2026 Statewide General
--   IL   3 race(s),   7 candidac(ies),   4 seeded   into IL 2026 Statewide General
--   MA   2 race(s),   5 candidac(ies),   3 seeded   into 2026 Massachusetts General Election
--   MD   2 race(s),   6 candidac(ies),   1 seeded   into 2026 Maryland General Election
--   ME   1 race(s),   5 candidac(ies),   2 seeded   into 2026 Maine General Election
--   MI   3 race(s),  16 candidac(ies),  13 seeded   into MI 2026 Statewide General
--   MN   3 race(s),   9 candidac(ies),   5 seeded   into MN 2026 Statewide General
--   ND   2 race(s),   4 candidac(ies),   1 seeded   into ND 2026 Statewide General
--   NE   3 race(s),  10 candidac(ies),   8 seeded   into NE 2026 Statewide General
--   NH   1 race(s),   3 candidac(ies),   2 seeded   into NH 2026 Statewide General
--   NM   3 race(s),   6 candidac(ies),   5 seeded   into NM 2026 Statewide General
--   NY   2 race(s),   4 candidac(ies),   2 seeded   into NY 2026 Statewide General
--   OH   2 race(s),   6 candidac(ies),   5 seeded   into OH 2026 Statewide General
--   OK   3 race(s),   9 candidac(ies),   9 seeded   into OK 2026 Statewide General
--   OR   1 race(s),   3 candidac(ies),   1 seeded   into OR 2026 General
--   PA   1 race(s),   3 candidac(ies),   1 seeded   into PA 2026 Statewide General
--   RI   4 race(s),  10 candidac(ies),   7 seeded   into RI 2026 Statewide General
--   SC   3 race(s),   8 candidac(ies),   5 seeded   into SC 2026 Statewide General
--   SD   3 race(s),   6 candidac(ies),   4 seeded   into SD 2026 Statewide General
--   TN   1 race(s),  15 candidac(ies),  13 seeded   into TN 2026 Statewide General
--   VT   4 race(s),  12 candidac(ies),   8 seeded   into VT 2026 Statewide General
--   WY   2 race(s),   6 candidac(ies),   6 seeded   into WY 2026 Statewide General
--
-- SOURCES — TWO INDEPENDENT ONES, AND THEY WERE RECONCILED RACE BY RACE BEFORE THIS FILE.
--   · AP's results feed, fetched 2026-11-05, is the ONLY source of a vote share, a vote count,
--     a party code, the ballot itself and the winner flag. 🔴 The winner is winner:"X" in
--     progress.json; metadata.json is ballot order and names nobody. ⚠ progress.json's
--     "candidates" is an ARRAY and metadata.json's is an OBJECT MAP — indexing one as the
--     other returns undefined for every candidate and reads as "no results".
--   · Ballotpedia's "<State> state executive official elections, 2026" pages, read 2026-11-05,
--     one per state, give identity: the full name spelling and a per-person article URL,
--     recorded in each seeded politician's source column. 🔴 THOSE PAGES ARE AUTHORITATIVE
--     FOR IDENTITY AND STALE FOR NUMBERS — Maine's governor reads 261,518 votes there
--     against AP's 382,760. NOT ONE NUMBER IN THIS FILE COMES FROM BALLOTPEDIA.
--
--   The two ballots were compared candidate by candidate for all 73 races. Result: 73 of 73
--   races paired, 212 of 212 candidacies paired, and THE TWO SOURCES AGREE ON EVERY WINNER.
--
-- 🔴 AP TRUNCATES NAMES, SO A SEEDED ROW TAKES BALLOTPEDIA'S SPELLING. AP publishes
--   "T. Shannon", "L. Taylor", "C. Reynolds" and "H. Paige"; Ballotpedia has T. W. Shannon,
--   L. Webb Taylor, Christopher Reynolds and H. Brooke Paige. 27 of the 212 names differ
--   between the two sources. ⚠ The SPLIT into first_name/last_name still comes from AP,
--   which publishes "first" and "last" as separate fields — so "Jose Javier Rodriguez"
--   splits to ("Jose Javier","Rodriguez"), not ("Jose","Javier Rodriguez"), and every split
--   was asserted against AP's own surname field before this file was written.
-- 🔴 AND THE ACCENTS COME BACK FROM AP. Ballotpedia drops them: "Jose Javier Rodriguez",
--   "Amanda Lopez Askin" against AP's "José" and "López". Both rows are seeded accented.
--   Prod has NO unaccent extension, so a name stored one way is unfindable by the other.
--
-- 🔴 "Total Write-ins" IS NOT A PERSON. AP candidate id 100013 is Nevada's "None of These
--   Candidates"; the same trap here is id 100008, "Total Write-ins", which appears on 17 of
--   these 73 ballots. It is a ballot aggregate and is excluded — 229 AP rows, 212 people.
--
-- ⚠ DECLARED WRITE-IN CANDIDATES ARE LARGELY ABSENT FROM AP'S BALLOT, SO THEY ARE ABSENT
--   HERE. Ballotpedia lists 43 write-ins that AP does not carry, across AL, CT, DE, FL, IL,
--   MI, MN, NY, OH, TN and VT — Michigan alone has 9. AP carries three (Jacob Burnett in
--   Idaho, Randy Wilcox and John Glowa in Maine) and those three are seeded with
--   is_write_in = true. The rest are absent rather than wrong. Said out loud so nobody
--   reads our ballot as the whole ballot.
--
-- ⚠ THREE RACES CARRY ONE CANDIDATE, and one of those is a call on no votes at all:
--     AR Attorney General  Tim Griffin   100%   620,639 votes  (unopposed)
--     RI Secretary of State Gregg Amore  100%   274,697 votes  (unopposed)
--     SD Attorney General  Lance Russell   0%         0 votes  eevp=0
--   🔴 SOUTH DAKOTA IS A CALL ON THE BALLOT, NOT ON THE COUNT. AP marks Russell the winner
--   with nothing counted because he is the only name on it. The seat is decided and 'won'
--   is the right value; the percentage means nothing and no percentage is stored.
-- ⚠ TENNESSEE'S GOVERNOR WON ON A PLURALITY — Marsha Blackburn 45.49% against 14 others.
--   The gate below asserts the winner is the TOP vote-getter, never that they cleared 50%.
--   None of the 73 is ranked-choice and none elects more than one seat (both read from AP).
--
-- 🔴 THREE SEEDED PEOPLE SHARE A NAME WITH SOMEONE WE ALREADY HOLD, DELIBERATELY. Each was read
--   row by row and each is a DIFFERENT PERSON:
--     · Doug Jones (AL Governor)
--       the existing "Doug Jones" 3216400f-3f92-4d78-a52d-c1a9abe18b5e came from Colorado's certified candidate list (CC_0276) and is a candidate for CO State Representative ON THIS SAME DAY, 2026-11-03 - a different man with the same name, not Alabama's former US Senator
--       NAMED IN THE ALLOWANCE — the guard would otherwise refuse it.
--     · David Graham (DE Attorney General)
--       the existing "David C. Graham" 25ab585b-7769-4264-b8f2-9543cad7f16f came from the Kansas Secretary of State's 2026 candidate list (CA_0233) and is a candidate for KS Senator on this same day - a different man
--       NAMED IN THE ALLOWANCE — the guard would otherwise refuse it.
--     · José Javier Rodriguez (FL Attorney General)
--       the existing "Jose J. Rodriguez" 2ab06b40-d436-43fe-bda7-dfa62afc6820 holds a CALIFORNIA school-board seat (Trustee Area 2, from 2024-12-16) - not Florida's former state senator Jose Javier Rodriguez
--       Needs no allowance: it collides on neither key. Listed so the resemblance is on the record.
--   ⚠ "A different person with a confusable name" and "a name the guard refuses" are NOT the
--     same set, and the first draft of this file conflated them. The guard checks TWO keys —
--     the whole name, and the (first_name, last_name) pair — and they catch different rows:
--     "David C. Graham" clashes only on the second (his columns read "David" and "Graham"),
--     "José Javier Rodriguez" clashes on neither. The allowance carries only what really
--     clashes, and a second gate fails the file if a listed name has stopped clashing.
--
-- 🔴 A MATCH TO AN EXISTING PERSON IS NOT A NAME MATCH. TX-22's winner was the incumbent's
--   TWIN BROTHER. 40 of the 69 matches are anchored on an INDEPENDENT fact — AP flags the
--   candidate incumbent and essentials.office_current_holder names that same person for
--   that same seat. The other 29 were read one at a time against what that politician
--   currently holds, and that read threw three matches out (above) and confirmed four by
--   hand: Tanya F. Miller (GA state rep), James B. Rutledge III (electjim.com reads "JIM
--   RUTLEDGE FOR ATTORNEY GENERAL"), Jermaine L. Johnson Sr. (SC state rep), and Richard
--   Bennett — of whose THREE rows only one holds the Maine senate seat.
--   ⚠ "Rick Bennett" f64c1364-65a7-4958-a9f2-999383f0729d is an ARCHIVED duplicate of that
--     same Maine man. Pre-existing, not touched here, and written up in NOTES.md.
--
-- A CALL IS NOT A CANVASS: result_certainty is 'called' on all 212. AP reports
--   isCertified:false for all 73 races. The 'certified' upgrade is a separate pass.
--
-- 🔴 is_incumbent is set explicitly on every row, from AP's flag, AND cross-checked against
--   essentials.office_current_holder in both directions. A control on CC_0358 proved that
--   gate necessary: moving the flag from the losing incumbent to the winner passed every
--   other check, because the verification read THIS FILE'S OWN TABLE and a tampered file
--   agrees with itself. A count of incumbents cannot catch it either — one true moves to
--   another row and the total does not change.
--
-- Applied to production 2026-11-05 by Chris Cantrell. Slot reserved via steward.

BEGIN;

-- ─── 1. The 143 people we hold no row for ───
CREATE TEMP TABLE seed_people (
  seed_key text PRIMARY KEY, full_name text NOT NULL, first_name text, last_name text NOT NULL, source text NOT NULL
) ON COMMIT DROP;
INSERT INTO seed_people (seed_key, full_name, first_name, last_name, source) VALUES
  ('AL|Attorney General|171298', 'Katherine Robertson', 'Katherine', 'Robertson',
   'https://ballotpedia.org/Katherine_Robertson (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('AL|Attorney General|52832', 'Jeffrey McLaughlin', 'Jeffrey', 'McLaughlin',
   'https://ballotpedia.org/Jeffrey_McLaughlin (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('AL|Governor|3610', 'Doug Jones', 'Doug', 'Jones',
   'https://ballotpedia.org/Doug_Jones_(Alabama) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('AL|Lieutenant Governor|171273', 'John Wahl', 'John', 'Wahl',
   'https://ballotpedia.org/John_Wahl (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('AL|Lieutenant Governor|100911', 'Phillip Ensler', 'Phillip', 'Ensler',
   'https://ballotpedia.org/Phillip_Ensler (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('AL|Secretary of State|160910', 'Caroleene Dobson', 'Caroleene', 'Dobson',
   'https://ballotpedia.org/Caroleene_Dobson (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('AL|Secretary of State|171403', 'Wayne Rogers', 'Wayne', 'Rogers',
   'https://ballotpedia.org/Wayne_Rogers_(Alabama) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('AR|Governor|102193', 'Fredrick Love', 'Fredrick', 'Love',
   'https://ballotpedia.org/Fredrick_Love (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('AR|Governor|174770', 'Colt Shelby', 'Colt', 'Shelby',
   'https://ballotpedia.org/Colt_Shelby (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('AR|Lieutenant Governor|66362', 'Michael Kalagias', 'Michael', 'Kalagias',
   'https://ballotpedia.org/Michael_Kalagias (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('AR|Secretary of State|102119', 'Kim Hammer', 'Kim', 'Hammer',
   'https://ballotpedia.org/Kim_Hammer (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('AR|Secretary of State|169542', 'Kelly Grappe', 'Kelly', 'Grappe',
   'https://ballotpedia.org/Kelly_Grappe (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('AR|Secretary of State|168552', 'Michael Pakko', 'Michael', 'Pakko',
   'https://ballotpedia.org/Michael_Pakko (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('CT|Attorney General|167164', 'John Bolton', 'John', 'Bolton',
   'https://ballotpedia.org/John_Bolton_(Connecticut) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('CT|Governor|109320', 'Ryan Fazio', 'Ryan', 'Fazio',
   'https://ballotpedia.org/Ryan_Fazio (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('DE|Attorney General|179371', 'David Graham', 'David', 'Graham',
   'https://ballotpedia.org/David_Graham_(Delaware) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('FL|Attorney General|107326', 'José Javier Rodriguez', 'José Javier', 'Rodriguez',
   'https://ballotpedia.org/Jose_Javier_Rodriguez_(Florida_state_senator) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('FL|Governor|63159', 'David Jolly', 'David', 'Jolly',
   'https://ballotpedia.org/David_Jolly (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('FL|Governor|178993', 'Scott Jewett', 'Scott', 'Jewett',
   'https://ballotpedia.org/Scott_Jewett (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('FL|Governor|178995', 'Frank Russo', 'Frank', 'Russo',
   'https://ballotpedia.org/Frank_Russo (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('FL|Governor|178990', 'Charles Burkett', 'Charles', 'Burkett',
   'https://ballotpedia.org/Charles_Burkett_(Florida) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('FL|Governor|178989', 'Dean Abrams', 'Dean', 'Abrams',
   'https://ballotpedia.org/Dean_Abrams (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('FL|Governor|178991', 'Jeffrey Datto', 'Jeffrey', 'Datto',
   'https://ballotpedia.org/Jeffrey_Datto (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('FL|Governor|178992', 'Moliere Dimanche', 'Moliere', 'Dimanche',
   'https://ballotpedia.org/Moliere_Dimanche (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('GA|Governor|110638', 'Keisha Bottoms', 'Keisha', 'Bottoms',
   'https://ballotpedia.org/Keisha_Lance_Bottoms (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('GA|Governor|171426', 'Rick Jackson', 'Rick', 'Jackson',
   'https://ballotpedia.org/Rick_Jackson_(Georgia) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('GA|Secretary of State|171430', 'Penny Brown Reynolds', 'Penny Brown', 'Reynolds',
   'https://ballotpedia.org/Penny_Brown_Reynolds (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('IA|Governor|114528', 'Rob Sand', 'Rob', 'Sand',
   'https://ballotpedia.org/Rob_Sand (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('IA|Governor|173748', 'Zach Lahn', 'Zach', 'Lahn',
   'https://ballotpedia.org/Zach_Lahn (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('IA|Secretary of State|173763', 'Ryan Peterman', 'Ryan', 'Peterman',
   'https://ballotpedia.org/Ryan_Peterman (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('ID|Attorney General|172102', 'Lori Hickman', 'Lori', 'Hickman',
   'https://ballotpedia.org/Lori_Hickman (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('ID|Governor|112763', 'Terri Pickens', 'Terri', 'Pickens',
   'https://ballotpedia.org/Terri_Pickens (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('ID|Governor|178019', 'John R. Stegner', 'John R.', 'Stegner',
   'https://ballotpedia.org/John_Stegner (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('ID|Governor|70344', 'Paul Sand', 'Paul', 'Sand',
   'https://ballotpedia.org/Paul_Sand (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('ID|Governor|56769', 'Pro-Life', NULL, 'Pro-Life',
   'https://ballotpedia.org/Pro-Life_(Marvin_Thomas_Richardson) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('ID|Governor|178018', 'Jacob Burnett', 'Jacob', 'Burnett',
   'https://ballotpedia.org/Jacob_Burnett (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('ID|Lieutenant Governor|172099', 'Eric Myricks', 'Eric', 'Myricks',
   'https://ballotpedia.org/Eric_Myricks (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('ID|Secretary of State|112765', 'Shawn Keenan', 'Shawn', 'Keenan',
   'https://ballotpedia.org/Shawn_Keenan (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('IL|Attorney General|116492', 'Bob Fioretti', 'Bob', 'Fioretti',
   'https://ballotpedia.org/Bob_Fioretti (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('IL|Governor|71049', 'Darren Bailey', 'Darren', 'Bailey',
   'https://ballotpedia.org/Darren_Bailey (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('IL|Governor|178028', 'Collin Corbett', 'Collin', 'Corbett',
   'https://ballotpedia.org/Collin_Corbett (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('IL|Secretary of State|63211', 'Diane Harris', 'Diane', 'Harris',
   'https://ballotpedia.org/Diane_Harris (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MA|Attorney General|124347', 'Michael Walsh', 'Michael', 'Walsh',
   'https://ballotpedia.org/Michael_C._Walsh_(Massachusetts_Attorney_General_candidate) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MA|Governor|176606', 'Michael Minogue', 'Michael', 'Minogue',
   'https://ballotpedia.org/Michael_Minogue (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MA|Governor|179350', 'Andrea James', 'Andrea', 'James',
   'https://ballotpedia.org/Andrea_James (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MD|Governor|178525', 'Cathy White', 'Cathy', 'White',
   'https://ballotpedia.org/Cathy_White (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('ME|Governor|179066', 'Randy Wilcox', 'Randy', 'Wilcox',
   'https://ballotpedia.org/Randy_Wilcox_(Maine) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('ME|Governor|120654', 'John Glowa', 'John', 'Glowa',
   'https://ballotpedia.org/John_Glowa (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MI|Attorney General|178885', 'Eli Savit', 'Eli', 'Savit',
   'https://ballotpedia.org/Eli_Savit (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MI|Attorney General|178886', 'Doug Lloyd', 'Doug', 'Lloyd',
   'https://ballotpedia.org/Doug_Lloyd (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MI|Attorney General|178923', 'Jason Dye', 'Jason', 'Dye',
   'https://ballotpedia.org/Jason_Dye (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MI|Attorney General|177001', 'John Ludtke', 'John', 'Ludtke',
   'https://ballotpedia.org/John_Ludtke (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MI|Attorney General|178924', 'Jeff Polonowski', 'Jeff', 'Polonowski',
   'https://ballotpedia.org/Jeff_Polonowski (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MI|Attorney General|771', 'Doug Dern', 'Doug', 'Dern',
   'https://ballotpedia.org/Doug_Dern (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MI|Governor|166567', 'Anthony Hudson', 'Anthony', 'Hudson',
   'https://ballotpedia.org/Anthony_Hudson_(Michigan) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MI|Governor|70820', 'Donna Brandenburg', 'Donna', 'Brandenburg',
   'https://ballotpedia.org/Donna_Brandenburg (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MI|Governor|1321', 'Douglas Campbell', 'Douglas', 'Campbell',
   'https://ballotpedia.org/Douglas_Campbell_(Michigan) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MI|Secretary of State|65347', 'Anthony Forlini', 'Anthony', 'Forlini',
   'https://ballotpedia.org/Anthony_Forlini (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MI|Secretary of State|178921', 'Christine Sloan', 'Christine', 'Sloan',
   'https://ballotpedia.org/Christine_Sloan (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MI|Secretary of State|178922', 'Scott Aughney', 'Scott', 'Aughney',
   'https://ballotpedia.org/Scott_Aughney (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MI|Secretary of State|127616', 'Eric Borregard', 'Eric', 'Borregard',
   'https://ballotpedia.org/Eric_Borregard (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MN|Attorney General|177197', 'Ron Schutz', 'Ron', 'Schutz',
   'https://ballotpedia.org/Ron_Schutz (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MN|Governor|179590', 'Steven Young', 'Steven', 'Young',
   'https://ballotpedia.org/Steven_Young_(Minnesota) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MN|Secretary of State|124249', 'Tad Jude', 'Tad', 'Jude',
   'https://ballotpedia.org/Tad_Jude (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MN|Secretary of State|179592', 'Chip Tangen', 'Chip', 'Tangen',
   'https://ballotpedia.org/Chip_Tangen (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('MN|Secretary of State|179591', 'Seth Kuhl-Stennes', 'Seth', 'Kuhl-Stennes',
   'https://ballotpedia.org/Seth_Kuhl-Stennes (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('ND|Attorney General|135217', 'Timothy Lamb', 'Timothy', 'Lamb',
   'https://ballotpedia.org/Timothy_Lamb_(North_Dakota) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('NE|Attorney General|171170', 'Jocelyn Brasher', 'Jocelyn', 'Brasher',
   'https://ballotpedia.org/Jocelyn_Brasher (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('NE|Governor|129088', 'Lynne Walz', 'Lynne', 'Walz',
   'https://ballotpedia.org/Lynne_Walz (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('NE|Governor|61797', 'Brett Lindstrom', 'Brett', 'Lindstrom',
   'https://ballotpedia.org/Brett_Lindstrom (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('NE|Governor|175131', 'Rick Beard', 'Rick', 'Beard',
   'https://ballotpedia.org/Rick_Beard (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('NE|Secretary of State|171167', 'Scott Petersen', 'Scott', 'Petersen',
   'https://ballotpedia.org/Scott_Petersen_(Nebraska) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('NE|Secretary of State|129548', 'Sarah Slattery', 'Sarah', 'Slattery',
   'https://ballotpedia.org/Sarah_Slattery (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('NE|Secretary of State|179200', 'Paul Rumbaugh', 'Paul', 'Rumbaugh',
   'https://ballotpedia.org/Paul_Rumbaugh (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('NE|Secretary of State|179201', 'Bob Krist', 'Bob', 'Krist',
   'https://ballotpedia.org/Bob_Krist (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('NH|Governor|139961', 'Cinde Warmington', 'Cinde', 'Warmington',
   'https://ballotpedia.org/Cinde_Warmington (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('NH|Governor|168217', 'Stephen Villee', 'Stephen', 'Villee',
   'https://ballotpedia.org/Stephen_Villee (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('NM|Attorney General|173272', 'Samuel Kane', 'Samuel', 'Kane',
   'https://ballotpedia.org/Samuel_Kane (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('NM|Governor|64378', 'Debra Haaland', 'Debra', 'Haaland',
   'https://ballotpedia.org/Debra_Haaland (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('NM|Governor|172994', 'Gregg Hull', 'Gregg', 'Hull',
   'https://ballotpedia.org/Gregg_Hull (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('NM|Secretary of State|173270', 'Amanda López Askin', 'Amanda', 'López Askin',
   'https://ballotpedia.org/Amanda_Lopez_Askin (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('NM|Secretary of State|173271', 'Ramona Goolsby', 'Ramona', 'Goolsby',
   'https://ballotpedia.org/Ramona_Goolsby (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('NY|Attorney General|174055', 'Saritha Komatireddy', 'Saritha', 'Komatireddy',
   'https://ballotpedia.org/Saritha_Komatireddy (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('NY|Governor|61145', 'Bruce Blakeman', 'Bruce', 'Blakeman',
   'https://ballotpedia.org/Bruce_Blakeman (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('OH|Governor|170750', 'Amy Acton', 'Amy', 'Acton',
   'https://ballotpedia.org/Amy_Acton (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('OH|Governor|71843', 'Vivek Ramaswamy', 'Vivek', 'Ramaswamy',
   'https://ballotpedia.org/Vivek_Ramaswamy (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('OH|Governor|60901', 'Don Kissick', 'Don', 'Kissick',
   'https://ballotpedia.org/Don_Kissick (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('OH|Secretary of State|142483', 'Allison Russo', 'Allison', 'Russo',
   'https://ballotpedia.org/Allison_Russo (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('OH|Secretary of State|168202', 'Tom Pruss', 'Tom', 'Pruss',
   'https://ballotpedia.org/Tom_Pruss (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('OK|Attorney General|137775', 'Jon Echols', 'Jon', 'Echols',
   'https://ballotpedia.org/Jon_Echols (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('OK|Attorney General|173600', 'Nick Coffey', 'Nick', 'Coffey',
   'https://ballotpedia.org/Nick_Coffey (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('OK|Governor|137606', 'Mike Mazzei', 'Mike', 'Mazzei',
   'https://ballotpedia.org/Mike_Mazzei (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('OK|Governor|138897', 'Cyndi Munson', 'Cyndi', 'Munson',
   'https://ballotpedia.org/Cyndi_Munson (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('OK|Governor|179040', 'Robert Brooks', 'Robert', 'Brooks',
   'https://ballotpedia.org/Robert_Brooks_(Oklahoma) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('OK|Governor|179039', 'Jerry Griffin', 'Jerry', 'Griffin',
   'https://ballotpedia.org/Jerry_Griffin (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('OK|Governor|179041', 'Orlando Lynn Bush', 'Orlando Lynn', 'Bush',
   'https://ballotpedia.org/Orlando_Lynn_Bush (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('OK|Lieutenant Governor|63815', 'T. W. Shannon', 'T. W.', 'Shannon',
   'https://ballotpedia.org/T._W._Shannon (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('OK|Lieutenant Governor|173592', 'Kelly Forbes', 'Kelly', 'Forbes',
   'https://ballotpedia.org/Kelly_Forbes (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('OR|Governor|167924', 'Brett Smith', 'Brett', 'Smith',
   'https://ballotpedia.org/Brett_Smith_(Oregon) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('PA|Governor|1112', 'Ken Krawchuk', 'Ken', 'Krawchuk',
   'https://ballotpedia.org/Ken_Krawchuk (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('RI|Attorney General|178125', 'Kim Ahern', 'Kim', 'Ahern',
   'https://ballotpedia.org/Kim_Ahern (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('RI|Attorney General|143376', 'Alan Gordon', 'Alan', 'Gordon',
   'https://ballotpedia.org/Alan_Gordon (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('RI|Governor|71486', 'Helena Foulkes', 'Helena', 'Foulkes',
   'https://ballotpedia.org/Helena_Foulkes (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('RI|Governor|61223', 'Ken Block', 'Ken', 'Block',
   'https://ballotpedia.org/Ken_Block (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('RI|Governor|143645', 'Aaron Guckian', 'Aaron', 'Guckian',
   'https://ballotpedia.org/Aaron_Guckian (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('RI|Governor|179317', 'Jasjit Gotra', 'Jasjit', 'Gotra',
   'https://ballotpedia.org/Jasjit_Gotra (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('RI|Lieutenant Governor|178112', 'John Loughlin', 'John', 'Loughlin',
   'https://ballotpedia.org/John_Loughlin (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('SC|Attorney General|172871', 'David Stumbo', 'David', 'Stumbo',
   'https://ballotpedia.org/David_Stumbo (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('SC|Attorney General|145208', 'Richard Hricik', 'Richard', 'Hricik',
   'https://ballotpedia.org/Richard_Hricik (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('SC|Governor|70923', 'Michael Addison', 'Michael', 'Addison',
   'https://ballotpedia.org/Michael_Addison (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('SC|Governor|177976', 'Walid Hakim', 'Walid', 'Hakim',
   'https://ballotpedia.org/Walid_Hakim (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('SC|Secretary of State|172867', 'Jason Belton', 'Jason', 'Belton',
   'https://ballotpedia.org/Jason_Belton (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('SD|Attorney General|143717', 'Lance Russell', 'Lance', 'Russell',
   'https://ballotpedia.org/Lance_Russell (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('SD|Governor|68738', 'Dan Ahlers', 'Dan', 'Ahlers',
   'https://ballotpedia.org/Dan_Ahlers (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('SD|Secretary of State|178209', 'Terrence Davis', 'Terrence', 'Davis',
   'https://ballotpedia.org/Terrence_Davis (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('SD|Secretary of State|71643', 'Tamara Lesnar', 'Tamara', 'Lesnar',
   'https://ballotpedia.org/Tamara_Lesnar (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('TN|Governor|178865', 'David Hatley', 'David', 'Hatley',
   'https://ballotpedia.org/David_Hatley (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('TN|Governor|178868', 'Lauren Pinkston', 'Lauren', 'Pinkston',
   'https://ballotpedia.org/Lauren_Pinkston (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('TN|Governor|178863', 'Dean Brewer', 'Dean', 'Brewer',
   'https://ballotpedia.org/Dean_Brewer (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('TN|Governor|178864', 'Ray Brown', 'Ray', 'Brown',
   'https://ballotpedia.org/Ray_Brown_(Tennessee) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('TN|Governor|178866', 'Wendell Jackson', 'Wendell', 'Jackson',
   'https://ballotpedia.org/Wendell_Jackson (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('TN|Governor|178867', 'Eddie Lee Murphy', 'Eddie Lee', 'Murphy',
   'https://ballotpedia.org/Eddie_Lee_Murphy (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('TN|Governor|178873', 'Robert Vick', 'Robert', 'Vick',
   'https://ballotpedia.org/Robert_Vick_(Tennessee) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('TN|Governor|178862', 'Misam Abidi', 'Misam', 'Abidi',
   'https://ballotpedia.org/Misam_Abidi (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('TN|Governor|70888', 'Charles Morgan', 'Charles', 'Morgan',
   'https://ballotpedia.org/Charles_Morgan_(Tennessee) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('TN|Governor|178872', 'L. Webb Taylor', 'L. Webb', 'Taylor',
   'https://ballotpedia.org/L._Webb_Taylor (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('TN|Governor|178870', 'Dave Seeman', 'Dave', 'Seeman',
   'https://ballotpedia.org/Dave_Seeman (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('TN|Governor|178869', 'Victor Scoggin', 'Victor', 'Scoggin',
   'https://ballotpedia.org/Victor_Scoggin (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('TN|Governor|178871', 'Karl Smithson', 'Karl', 'Smithson',
   'https://ballotpedia.org/Karl_Smithson (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('VT|Attorney General|179188', 'Edwin Kemon', 'Edwin', 'Kemon',
   'https://ballotpedia.org/Edwin_Kemon (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('VT|Governor|175074', 'Amanda Janoo', 'Amanda', 'Janoo',
   'https://ballotpedia.org/Amanda_Janoo (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('VT|Governor|149767', 'Brian Judd', 'Brian', 'Judd',
   'https://ballotpedia.org/Brian_Judd (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('VT|Governor|167782', 'June Goodband', 'June', 'Goodband',
   'https://ballotpedia.org/June_Goodband (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('VT|Governor|178912', 'Dean Roy', 'Dean', 'Roy',
   'https://ballotpedia.org/Dean_Roy (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('VT|Lieutenant Governor|71177', 'Molly Gray', 'Molly', 'Gray',
   'https://ballotpedia.org/Molly_Gray (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('VT|Secretary of State|62482', 'H. Brooke Paige', 'H. Brooke', 'Paige',
   'https://ballotpedia.org/Brooke_Paige (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('VT|Secretary of State|179189', 'Rachel Shaw', 'Rachel', 'Shaw',
   'https://ballotpedia.org/Rachel_Shaw (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('WY|Governor|153633', 'Eric Barlow', 'Eric', 'Barlow',
   'https://ballotpedia.org/Eric_Barlow (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('WY|Governor|179171', 'Rebecca Bextel', 'Rebecca', 'Bextel',
   'https://ballotpedia.org/Rebecca_Bextel (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('WY|Governor|49137', 'Ken Casner', 'Ken', 'Casner',
   'https://ballotpedia.org/Ken_Casner (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('WY|Secretary of State|69218', 'Robert Short', 'Robert', 'Short',
   'https://ballotpedia.org/Robert_Short_(Wyoming) (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('WY|Secretary of State|175356', 'Bryan McCarty', 'Bryan', 'McCarty',
   'https://ballotpedia.org/Bryan_McCarty (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)'),
  ('WY|Secretary of State|155494', 'Tamara Trujillo', 'Tamara', 'Trujillo',
   'https://ballotpedia.org/Tamara_Trujillo (Ballotpedia, read 2026-11-05 — identity and name spelling only; its vote counts were mid-count and are NOT used); ballot, party and result from AP (CC_0359)');

CREATE TEMP TABLE allowed_name_collisions (full_name text PRIMARY KEY) ON COMMIT DROP;
INSERT INTO allowed_name_collisions (full_name) VALUES
  ('Doug Jones'),
  ('David Graham');

-- accent-stripped, case-folded. 🔴 Prod has NO unaccent extension, so this is the comparison
-- a name check has to spell out for itself — a last-name join on Lujan/Luján once returned
-- 32 of 33 rows and said nothing.
CREATE OR REPLACE FUNCTION pg_temp.namekey(t text) RETURNS text IMMUTABLE LANGUAGE sql AS $f$
  SELECT lower(translate(coalesce(t, ''), 'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇç',
                                          'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCc'))
$f$;

-- (first word, last word), accent-stripped and case-folded, suffixes dropped. Two sources
-- that name the same person legitimately differ in the middle — a middle name, an initial, a
-- nickname — but not at both ends.
CREATE OR REPLACE FUNCTION pg_temp.endsname(t text) RETURNS text IMMUTABLE LANGUAGE sql AS $f$
  SELECT CASE WHEN cardinality(w) = 0 THEN $$$$
              WHEN cardinality(w) = 1 THEN w[1]
              ELSE w[1] || ' ' || w[cardinality(w)] END
    FROM (SELECT array_remove(array_remove(array_remove(array_remove(array_remove(
            regexp_split_to_array(btrim(regexp_replace(pg_temp.namekey(t), '[^a-z ]', ' ', 'g')), '\s+'),
            'jr'), 'sr'), 'ii'), 'iii'), 'iv') AS w) q
$f$;

-- ⚠ THE GUARD BELOW TIMED OUT ON ITS FIRST RUN, and a guard that cannot finish is a guard
--   that does not run. Calling namekey() on BOTH sides of a join defeats every index, so it
--   was 143 seeds x 91,353 politicians x 2 keys of function evaluation. Normalising the
--   91,353 rows ONCE into an indexed temp table turns it into 286 index lookups.
CREATE TEMP TABLE pol_keys ON COMMIT DROP AS
SELECT id, full_name, first_name, last_name, is_active, source,
       pg_temp.namekey(full_name) AS k_full,
       pg_temp.namekey(first_name) AS k_first,
       pg_temp.namekey(last_name) AS k_last
  FROM essentials.politicians;
CREATE INDEX ON pol_keys (k_full);
CREATE INDEX ON pol_keys (k_first, k_last);
ANALYZE pol_keys;

DO $$
DECLARE txt text; n int;
BEGIN
  -- 🔴 A POSITIVE CONTROL ON THE DETECTOR ITSELF. Everything below reports "nothing found" on
  --    a healthy run, and a detector that can only ever say that proves nothing. This asserts
  --    the normalised table can actually see a known row before any check trusts its silence.
  SELECT count(*) INTO n FROM pol_keys WHERE k_full = pg_temp.namekey('Doug Jones');
  IF n < 1 THEN RAISE EXCEPTION 'the name index cannot see a politician known to exist — the duplicate guard below would pass vacuously'; END IF;
  SELECT count(*) INTO n FROM pol_keys;
  IF n < 50000 THEN RAISE EXCEPTION 'the name index holds only % rows — it did not load the table', n; END IF;

  -- 🔴 THE REPO DUPLICATE GUARD KEYS ON (first_name, last_name) AND IS CASE-SENSITIVE, so it is
  --    blind to a differently-split, differently-cased or accented row. This checks BOTH keys —
  --    the whole name AND the (first, last) pair — ACROSS THE WHOLE TABLE, ARCHIVED ROWS
  --    INCLUDED, and allows only the collisions named in the header.
  --    ⚠ The two keys catch different rows, and the first draft of this file only had the
  --      first: "David C. Graham" does NOT collide on full name and DOES collide on
  --      (first, last), because his first and last columns read plainly "David" and "Graham".
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT s.full_name || ' already exists as ' || p.full_name || ' (' || p.id || ', active=' || p.is_active || ')' AS msg
      FROM seed_people s JOIN pol_keys p ON p.k_full = pg_temp.namekey(s.full_name)
     WHERE p.source IS DISTINCT FROM s.source
       AND s.full_name NOT IN (SELECT full_name FROM allowed_name_collisions)
    UNION
    SELECT s.full_name || ' splits to the same (first, last) as ' || p.full_name || ' (' || p.id || ', active=' || p.is_active || ')'
      FROM seed_people s JOIN pol_keys p ON p.k_first = pg_temp.namekey(s.first_name)
                                         AND p.k_last  = pg_temp.namekey(s.last_name)
     WHERE p.source IS DISTINCT FROM s.source
       AND s.full_name NOT IN (SELECT full_name FROM allowed_name_collisions)) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a person this file seeds already exists: %', txt; END IF;

  -- and the allowance must still be EARNED: each named collision must really collide on one of
  -- the two keys, or the list is stale and is quietly excusing a row it no longer describes.
  SELECT count(*) INTO n FROM allowed_name_collisions a
    JOIN seed_people s ON s.full_name = a.full_name
   WHERE NOT EXISTS (SELECT 1 FROM pol_keys p
                      WHERE p.source IS DISTINCT FROM s.source
                        AND (p.k_full = pg_temp.namekey(s.full_name)
                          OR (p.k_first = pg_temp.namekey(s.first_name)
                         AND  p.k_last  = pg_temp.namekey(s.last_name))));
  IF n <> 0 THEN RAISE EXCEPTION '% allowed name collision(s) no longer collide with anything — the allowance is stale', n; END IF;
  SELECT count(*) INTO n FROM allowed_name_collisions a WHERE NOT EXISTS (SELECT 1 FROM seed_people s WHERE s.full_name = a.full_name);
  IF n <> 0 THEN RAISE EXCEPTION '% allowed name collision(s) name nobody this file seeds', n; END IF;

  -- 🔴 THE NAME SPLIT MUST AGREE WITH THE NAME. A control found this gate missing: changing a
  --    seeded last_name to "Robertson-Changed" while leaving full_name alone was accepted and
  --    written, silently. It matters because first_name and last_name are the columns the
  --    REPO's duplicate guard keys on, so a wrong split makes that person invisible to it —
  --    the same blindness CLAUDE.md records for differently-cased and accented rows.
  --    ⚠ This is a weaker check than the pinned-uuid gate above: it compares three columns
  --      this file wrote against each other, not against an outside fact. It catches a typo
  --      or a bad split, not a wrong person. The outside check exists only where there is an
  --      existing row to check against, and a seeded person by definition has none.
  SELECT string_agg(s.full_name || ' splits to (' || coalesce(s.first_name,'NULL') || ', ' || s.last_name || ')', '; ') INTO txt
    FROM seed_people s
   WHERE s.full_name NOT LIKE ('%' || s.last_name)
      OR (s.first_name IS NOT NULL AND s.full_name <> s.first_name AND s.full_name NOT LIKE (s.first_name || ' %'));
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded name does not match its own split: %', txt; END IF;
END $$;

-- 🟢 THE DATABASE HAS ITS OWN DUPLICATE-NAME TRIGGER AND IT AGREED WITH THE GUARD ABOVE,
--    independently, on the dry run:
--      DUPLICATE_POLITICIAN_NAME: 1 active politician row(s) already carry the name Doug Jones.
--    Its advice is the right default — "a sitting officeholder running for a different seat
--    is the normal case, not a different person" — and it is not this case. Colorado's Doug
--    Jones is on a ballot for CO State Representative ON THIS SAME DAY. So the escape hatch
--    is opened DELIBERATELY, and closed again on the next line so it covers this one
--    statement and nothing else in the transaction.
SET LOCAL essentials.allow_duplicate_name = 'on';
INSERT INTO essentials.politicians (full_name, first_name, last_name, source, is_active, is_incumbent)
SELECT s.full_name, s.first_name, s.last_name, s.source, true, false
  FROM seed_people s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p
                    WHERE p.full_name = s.full_name AND p.source = s.source);
SET LOCAL essentials.allow_duplicate_name = 'off';

-- resolve every seeded person back to the row this file owns. The source string is unique
-- to this migration, so it separates our Doug Jones from Colorado's without ambiguity, and
-- it makes the file re-runnable: a second run inserts nothing and resolves the same 143.
CREATE TEMP TABLE seeded (seed_key text PRIMARY KEY, politician_id uuid NOT NULL) ON COMMIT DROP;
INSERT INTO seeded (seed_key, politician_id)
SELECT s.seed_key, p.id FROM seed_people s
  JOIN essentials.politicians p ON p.full_name = s.full_name AND p.source = s.source;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM seeded;
  IF n <> 143 THEN RAISE EXCEPTION 'only % of the 143 seeded people resolved to exactly one row', n; END IF;
END $$;

-- ─── 2. The 73 races ───
CREATE TEMP TABLE new_races (
  ap_race text PRIMARY KEY, st text NOT NULL, office_id uuid NOT NULL, election_id uuid NOT NULL, position_name text NOT NULL
) ON COMMIT DROP;
INSERT INTO new_races (ap_race, st, office_id, election_id, position_name) VALUES
  ('20261103AL1025', 'AL', 'dbb60021-06d6-4359-aa7e-60f82ed4e90b'::uuid, '4dc3b465-4921-410c-a3b1-b05bac5004e7'::uuid, 'Attorney General'),
  ('20261103AL1019', 'AL', '8f62b37c-e344-4a24-be98-8c9617ad8f2c'::uuid, '4dc3b465-4921-410c-a3b1-b05bac5004e7'::uuid, 'Governor'),
  ('20261103AL1021', 'AL', 'a9d2cc9d-7d26-437f-9584-8feb9639e1ab'::uuid, '4dc3b465-4921-410c-a3b1-b05bac5004e7'::uuid, 'Lieutenant Governor'),
  ('20261103AL1023', 'AL', '6acd1d55-4faa-496c-bd97-5f12b4f548d7'::uuid, '4dc3b465-4921-410c-a3b1-b05bac5004e7'::uuid, 'Secretary of State'),
  ('20261103AR5729', 'AR', 'a0c10af2-2694-4860-ac40-d5c863c9fd65'::uuid, 'b333dbd5-2b94-4dc7-8929-9743dc237191'::uuid, 'Attorney General'),
  ('20261103AR5626', 'AR', '38e72906-3f76-4071-9973-7b64558f7a6e'::uuid, 'b333dbd5-2b94-4dc7-8929-9743dc237191'::uuid, 'Governor'),
  ('20261103AR5315', 'AR', '73bf9b8d-275d-4e15-bb1f-dd245ef8e68d'::uuid, 'b333dbd5-2b94-4dc7-8929-9743dc237191'::uuid, 'Lieutenant Governor'),
  ('20261103AR5728', 'AR', '9af74283-be8f-4964-ad8e-836ddc8dc3ec'::uuid, 'b333dbd5-2b94-4dc7-8929-9743dc237191'::uuid, 'Secretary of State'),
  ('20261103CT7029', 'CT', 'b0413048-a7ba-44fb-953d-d7f2510ba031'::uuid, 'e7630bb9-d60d-4ffe-905d-d171f84e9cb7'::uuid, 'Attorney General'),
  ('20261103CT7019', 'CT', '58562e19-0ea9-4cef-a0d2-9a7586ef0892'::uuid, 'e7630bb9-d60d-4ffe-905d-d171f84e9cb7'::uuid, 'Governor'),
  ('20261103DE8283', 'DE', '58120cc2-36cb-4874-b61b-7736968cbda1'::uuid, '00653817-6888-4074-8342-057be2ceced9'::uuid, 'Attorney General'),
  ('20261103FL10049', 'FL', '9e399ee2-5270-4877-9941-f0cd30235ace'::uuid, '1c868ba1-3169-4f0a-84a2-f41b349ef313'::uuid, 'Attorney General'),
  ('20261103FL10045', 'FL', 'e2dd77a5-604e-4537-8fe7-5b74f0cbc1d6'::uuid, '1c868ba1-3169-4f0a-84a2-f41b349ef313'::uuid, 'Governor'),
  ('20261103GA11033', 'GA', '525e4d1f-2648-4101-8ed7-ae4357ca9082'::uuid, 'e4d22b2e-2c87-4fec-9b5a-c0680e99d2c7'::uuid, 'Attorney General'),
  ('20261103GA12029', 'GA', '2411d0c8-5959-4013-8a32-0cc5ffb9868a'::uuid, 'e4d22b2e-2c87-4fec-9b5a-c0680e99d2c7'::uuid, 'Governor'),
  ('20261103GA11029', 'GA', '56f2ebbe-b7e1-4790-b50a-ee33707e2a15'::uuid, 'e4d22b2e-2c87-4fec-9b5a-c0680e99d2c7'::uuid, 'Lieutenant Governor'),
  ('20261103GA11031', 'GA', '069e295f-4266-407b-be0c-b31238d0e80b'::uuid, 'e4d22b2e-2c87-4fec-9b5a-c0680e99d2c7'::uuid, 'Secretary of State'),
  ('20261103HI12480', 'HI', '69eaf89c-9d6f-4314-be40-e589fc71f144'::uuid, 'e6326a3d-bcf5-45c5-8afb-64999d993fa0'::uuid, 'Governor'),
  ('20261103IA17076', 'IA', '26e6c494-f075-478c-8576-3c217e1b2202'::uuid, 'ed7eb7da-8e46-4d25-a97a-f3168bd0fbf6'::uuid, 'Governor'),
  ('20261103IA16950', 'IA', '0bec374b-a5c4-404f-b9a1-eac2b9aaed39'::uuid, 'ed7eb7da-8e46-4d25-a97a-f3168bd0fbf6'::uuid, 'Secretary of State'),
  ('20261103ID13681', 'ID', '3c42cbb6-afba-493e-a48e-5330fe73451b'::uuid, '823b82b9-55bd-4d00-8bba-3311e3e78ef2'::uuid, 'Attorney General'),
  ('20261103ID13676', 'ID', '66dbc16e-56ea-47f9-86ac-b82078ada305'::uuid, '823b82b9-55bd-4d00-8bba-3311e3e78ef2'::uuid, 'Governor'),
  ('20261103ID13677', 'ID', '24c1a220-3ad3-47fc-adf3-1f6375453705'::uuid, '823b82b9-55bd-4d00-8bba-3311e3e78ef2'::uuid, 'Lieutenant Governor'),
  ('20261103ID13678', 'ID', '5ed58238-3f48-4771-b1bd-b4b5f312ea40'::uuid, '823b82b9-55bd-4d00-8bba-3311e3e78ef2'::uuid, 'Secretary of State'),
  ('20261103IL15258', 'IL', '33e4c5d9-da0d-4d4d-a429-a52620887bc6'::uuid, '804d07cf-11c9-4e3d-a85d-9ff8cbffb828'::uuid, 'Attorney General'),
  ('20261103IL15989', 'IL', 'b8fa5cdf-e0e4-47b3-abe7-b46e03e55c43'::uuid, '804d07cf-11c9-4e3d-a85d-9ff8cbffb828'::uuid, 'Governor'),
  ('20261103IL15257', 'IL', 'be10035e-21ec-4288-8130-14a8b5cba72b'::uuid, '804d07cf-11c9-4e3d-a85d-9ff8cbffb828'::uuid, 'Secretary of State'),
  ('20261103MA22960', 'MA', 'acff6f85-1bc2-4f50-94e6-58294f5f096a'::uuid, '38121465-a14b-4044-bc21-1a4c968ae4fd'::uuid, 'Attorney General'),
  ('20261103MA22957', 'MA', '21f9e818-904d-4a19-879b-438f447bcd68'::uuid, '38121465-a14b-4044-bc21-1a4c968ae4fd'::uuid, 'Governor'),
  ('20261103MD22092', 'MD', '6f9fd58a-442c-4c58-bd6d-f36a1bcbf114'::uuid, 'd3d8376e-0688-42e5-a7fe-fd11e7d225ef'::uuid, 'Attorney General'),
  ('20261103MD22091', 'MD', '1a7ac65d-983a-4c62-85bc-d506ea2755a3'::uuid, 'd3d8376e-0688-42e5-a7fe-fd11e7d225ef'::uuid, 'Governor'),
  ('20261103ME20646', 'ME', '95700fc5-2800-4766-9005-38dc7237c455'::uuid, '43874bd1-d891-4ae0-b839-58fef5b98218'::uuid, 'Governor'),
  ('20261103MI24116', 'MI', 'a5281741-c2b2-4aac-8293-66b96cc6dce0'::uuid, '03079314-238b-417b-a9e5-5e6d203e1594'::uuid, 'Attorney General'),
  ('20261103MI24074', 'MI', '68da5056-e5aa-4653-9a61-feb3e3f3b257'::uuid, '03079314-238b-417b-a9e5-5e6d203e1594'::uuid, 'Governor'),
  ('20261103MI24115', 'MI', '971841d3-b324-4870-b9b5-e2db53391d1d'::uuid, '03079314-238b-417b-a9e5-5e6d203e1594'::uuid, 'Secretary of State'),
  ('20261103MN24793', 'MN', 'a2cb5ff8-4a75-4563-b346-cdde981b710d'::uuid, '964480b9-d8ae-4d80-a1f0-ddfca3b01883'::uuid, 'Attorney General'),
  ('20261103MN24704', 'MN', '73fc9ecc-3b0b-445e-898a-1d51b9846d32'::uuid, '964480b9-d8ae-4d80-a1f0-ddfca3b01883'::uuid, 'Governor'),
  ('20261103MN24710', 'MN', '186e84b2-0798-43cf-88a3-0fde73138dff'::uuid, '964480b9-d8ae-4d80-a1f0-ddfca3b01883'::uuid, 'Secretary of State'),
  ('20261103ND35345', 'ND', 'a9c867cf-371e-4ab6-af26-0a4c508d3a85'::uuid, 'fce62fc6-28b4-4d99-821a-3c5e94bb2915'::uuid, 'Attorney General'),
  ('20261103ND35344', 'ND', '5fd38de4-2c16-4e6e-881d-db543699a01a'::uuid, 'fce62fc6-28b4-4d99-821a-3c5e94bb2915'::uuid, 'Secretary of State'),
  ('20261103NE28011', 'NE', 'd2e27132-0182-41d6-8fdc-7ff1977fe1c9'::uuid, '1224487f-4f73-4048-b553-5629ee19b512'::uuid, 'Attorney General'),
  ('20261103NE28006', 'NE', 'c45af066-9b43-4aee-bcbd-65e5e2369548'::uuid, '1224487f-4f73-4048-b553-5629ee19b512'::uuid, 'Governor'),
  ('20261103NE28009', 'NE', '4496d005-bb8d-4b8b-8350-ba187f9be331'::uuid, '1224487f-4f73-4048-b553-5629ee19b512'::uuid, 'Secretary of State'),
  ('20261103NH30005', 'NH', 'ae8e7bfa-651a-4b8a-9d14-235b51c13e3f'::uuid, 'c6fcba79-6b3d-4617-b227-5a745c27f849'::uuid, 'Governor'),
  ('20261103NM32350', 'NM', '9e0f9033-a22b-424a-bfaf-df903fbebf15'::uuid, '6a560b73-4059-406c-b96a-6fe27073ecc9'::uuid, 'Attorney General'),
  ('20261103NM32238', 'NM', 'bae1e006-1759-49cd-a802-05cc098ed99c'::uuid, '6a560b73-4059-406c-b96a-6fe27073ecc9'::uuid, 'Governor'),
  ('20261103NM32342', 'NM', '3bae9063-56a0-4d1c-94f6-6e90aa2f403b'::uuid, '6a560b73-4059-406c-b96a-6fe27073ecc9'::uuid, 'Secretary of State'),
  ('20261103NY36820', 'NY', 'ac3d6525-46d9-43a7-8005-112330f11c9f'::uuid, '80a2b03d-f583-4156-a272-d51abbda0b0a'::uuid, 'Attorney General'),
  ('20261103NY39760', 'NY', '2aafa674-b590-4bfb-b573-d620027467ab'::uuid, '80a2b03d-f583-4156-a272-d51abbda0b0a'::uuid, 'Governor'),
  ('20261103OH36005', 'OH', '9c2a4c5e-1262-4138-9446-a0c4736e3780'::uuid, '32657ce8-8606-420b-8782-ca2c7f01c5ae'::uuid, 'Governor'),
  ('20261103OH36011', 'OH', 'fe1848f7-956f-4a98-9f48-b19c913dc84a'::uuid, '32657ce8-8606-420b-8782-ca2c7f01c5ae'::uuid, 'Secretary of State'),
  ('20261103OK37895', 'OK', '49173ad9-112e-47ef-8c96-8574fef6d151'::uuid, '5afd2125-3d75-4c6e-bcb0-9d3aaa296590'::uuid, 'Attorney General'),
  ('20261103OK37857', 'OK', '78dacf12-acf1-41ba-9ccf-637b88d97bcb'::uuid, '5afd2125-3d75-4c6e-bcb0-9d3aaa296590'::uuid, 'Governor'),
  ('20261103OK37858', 'OK', 'd188cd52-a64c-4378-bc6c-abb89ef38806'::uuid, '5afd2125-3d75-4c6e-bcb0-9d3aaa296590'::uuid, 'Lieutenant Governor'),
  ('20261103OR38019', 'OR', '780f76cd-2ec0-42fc-bb67-74a8911ca1c8'::uuid, 'de10e3a7-f5c2-47e6-acd7-ee87be9413db'::uuid, 'Governor'),
  ('20261103PA39292', 'PA', '99415af3-4691-49e5-a00e-33adcbe636d0'::uuid, 'ed54a0a5-4204-462b-9f3e-c3debed12501'::uuid, 'Governor'),
  ('20261103RI40011', 'RI', 'ec794af6-bbb1-4d54-82ae-67cdcdc457ae'::uuid, '1fb22c90-15f9-45ea-9988-881bae728b1d'::uuid, 'Attorney General'),
  ('20261103RI40005', 'RI', '75bfe876-3cc1-4ba7-bbfd-f18d3b06ab76'::uuid, '1fb22c90-15f9-45ea-9988-881bae728b1d'::uuid, 'Governor'),
  ('20261103RI40008', 'RI', '8799c407-3d10-4e69-9322-be04c976f293'::uuid, '1fb22c90-15f9-45ea-9988-881bae728b1d'::uuid, 'Lieutenant Governor'),
  ('20261103RI40010', 'RI', '6d0f16b7-88f0-4bf6-b23f-2b3b65582da9'::uuid, '1fb22c90-15f9-45ea-9988-881bae728b1d'::uuid, 'Secretary of State'),
  ('20261103SC41199', 'SC', 'ba71d6b9-f182-43ad-8188-d8566266f2d4'::uuid, 'e9a9063d-7a17-43de-9ac4-012a50166b64'::uuid, 'Attorney General'),
  ('20261103SC41191', 'SC', '8b0de7c5-8fa0-46e9-814d-c720f0429975'::uuid, 'e9a9063d-7a17-43de-9ac4-012a50166b64'::uuid, 'Governor'),
  ('20261103SC41195', 'SC', '1ce91b70-b22f-4df1-8877-b665d59ce330'::uuid, 'e9a9063d-7a17-43de-9ac4-012a50166b64'::uuid, 'Secretary of State'),
  ('20261103SD42010', 'SD', '410286b4-0bfa-4694-8270-1ac9046d77d3'::uuid, 'ac7ebe0d-b300-43ed-b107-d919822502df'::uuid, 'Attorney General'),
  ('20261103SD42222', 'SD', '519f011a-a114-4ee5-aac6-41a88a83c140'::uuid, 'ac7ebe0d-b300-43ed-b107-d919822502df'::uuid, 'Governor'),
  ('20261103SD42009', 'SD', '6de8c31e-52db-4b93-81cb-e676f5362dad'::uuid, 'ac7ebe0d-b300-43ed-b107-d919822502df'::uuid, 'Secretary of State'),
  ('20261103TN43440', 'TN', 'b4667b62-fd9f-4ff5-9e5c-068f85ba6ce2'::uuid, 'fee6619a-62dc-4cc7-b2fd-d8d289bc54cb'::uuid, 'Governor'),
  ('20261103VT46011', 'VT', '087c3021-ff29-44bf-9f61-b505e2b78297'::uuid, 'a4ed60a8-fdfc-4093-93e3-44799d43f86b'::uuid, 'Attorney General'),
  ('20261103VT46375', 'VT', '2abe04f0-ba94-42b9-aa71-1e2dcc4cfce8'::uuid, 'a4ed60a8-fdfc-4093-93e3-44799d43f86b'::uuid, 'Governor'),
  ('20261103VT46376', 'VT', 'bd0adeb4-6746-418d-abb0-062c99f260c9'::uuid, 'a4ed60a8-fdfc-4093-93e3-44799d43f86b'::uuid, 'Lieutenant Governor'),
  ('20261103VT46377', 'VT', 'da8e0d09-2e16-4415-a362-76f22b72e3f1'::uuid, 'a4ed60a8-fdfc-4093-93e3-44799d43f86b'::uuid, 'Secretary of State'),
  ('20261103WY51403', 'WY', '409b15ad-4c4f-44ad-b656-5345b9ed6d8a'::uuid, '28ce873c-af6e-4802-9315-b47a5e0cdd9a'::uuid, 'Governor'),
  ('20261103WY51404', 'WY', '130a2bc0-1c93-4424-96e5-949b509d3320'::uuid, '28ce873c-af6e-4802-9315-b47a5e0cdd9a'::uuid, 'Secretary of State');

DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM new_races nr JOIN essentials.offices o ON o.id = nr.office_id;
  IF n <> 73 THEN RAISE EXCEPTION 'only % of the 73 target offices exist', n; END IF;

  -- the office must belong to the state this file says it does, and be a state-executive seat
  SELECT string_agg(nr.position_name || ' is listed under ' || nr.st || ' but its district is ' || upper(d.state) || ' ' || d.district_type, '; ') INTO txt
    FROM new_races nr JOIN essentials.offices o ON o.id = nr.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE upper(d.state) <> nr.st OR d.district_type <> 'STATE_EXEC';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an office is not where this file says: %', txt; END IF;

  -- every target office must hold NO race on this date, or this file is duplicating one
  SELECT count(*) INTO n FROM new_races nr
    JOIN essentials.races r ON r.office_id = nr.office_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.election_date = DATE '2026-11-03';
  IF n <> 0 THEN RAISE EXCEPTION '% race(s) already exist on these offices for 2026-11-03', n; END IF;

  -- and every election row must be the general of 2026-11-03 in that same state
  SELECT string_agg(nr.st || ' -> ' || coalesce(e.name, '(no such election row)') || ' ' || coalesce(e.state, '?') || ' ' || coalesce(e.election_date::text, '?'), '; ') INTO txt
    FROM new_races nr LEFT JOIN essentials.elections e ON e.id = nr.election_id
   WHERE e.id IS NULL OR e.election_date <> DATE '2026-11-03' OR e.state IS DISTINCT FROM nr.st;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an election row is not the 2026-11-03 general of its state: %', txt; END IF;
END $$;

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT nr.election_id, nr.office_id, nr.position_name, NULL, 1
  FROM new_races nr
 WHERE NOT EXISTS (SELECT 1 FROM essentials.races r
                     JOIN essentials.elections e ON e.id = r.election_id
                    WHERE r.office_id = nr.office_id AND e.election_date = DATE '2026-11-03');

-- ─── 3. The 212 candidacies, with AP's result ───
CREATE TEMP TABLE calls (
  seed_key text PRIMARY KEY, ap_race text NOT NULL, office_id uuid NOT NULL, seat text NOT NULL,
  who text NOT NULL, who_ap text NOT NULL, ap_cand_id text NOT NULL, result text NOT NULL,
  vote_pct numeric NOT NULL, is_inc boolean NOT NULL, is_write_in boolean NOT NULL, pinned_id uuid
) ON COMMIT DROP;
INSERT INTO calls (seed_key, ap_race, office_id, seat, who, who_ap, ap_cand_id, result, vote_pct, is_inc, is_write_in, pinned_id) VALUES
  ('AL|Attorney General|171298', '20261103AL1025', 'dbb60021-06d6-4359-aa7e-60f82ed4e90b'::uuid,
   'AL Attorney General',         'Katherine Robertson',         'Katherine Robertson',     '171298',  'won',    55.04, false, false, NULL),
  ('AL|Attorney General|52832', '20261103AL1025', 'dbb60021-06d6-4359-aa7e-60f82ed4e90b'::uuid,
   'AL Attorney General',         'Jeffrey McLaughlin',          'Jeff McLaughlin',         '52832',   'lost',   44.96, false, false, NULL),
  ('AL|Governor|68308', '20261103AL1019', '8f62b37c-e344-4a24-be98-8c9617ad8f2c'::uuid,
   'AL Governor',                 'Tommy Tuberville',            'Thomas Tuberville',       '68308',   'won',    52.06, false, false, '7affca4e-db2b-4f7e-b009-9acc6b493139'::uuid),
  ('AL|Governor|3610', '20261103AL1019', '8f62b37c-e344-4a24-be98-8c9617ad8f2c'::uuid,
   'AL Governor',                 'Doug Jones',                  'Doug Jones',              '3610',    'lost',   47.94, false, false, NULL),
  ('AL|Lieutenant Governor|171273', '20261103AL1021', 'a9d2cc9d-7d26-437f-9584-8feb9639e1ab'::uuid,
   'AL Lieutenant Governor',      'John Wahl',                   'John Wahl',               '171273',  'won',    54.36, false, false, NULL),
  ('AL|Lieutenant Governor|100911', '20261103AL1021', 'a9d2cc9d-7d26-437f-9584-8feb9639e1ab'::uuid,
   'AL Lieutenant Governor',      'Phillip Ensler',              'Phillip Ensler',          '100911',  'lost',   45.64, false, false, NULL),
  ('AL|Secretary of State|160910', '20261103AL1023', '6acd1d55-4faa-496c-bd97-5f12b4f548d7'::uuid,
   'AL Secretary of State',       'Caroleene Dobson',            'Caroleene Dobson',        '160910',  'won',    54.59, false, false, NULL),
  ('AL|Secretary of State|171403', '20261103AL1023', '6acd1d55-4faa-496c-bd97-5f12b4f548d7'::uuid,
   'AL Secretary of State',       'Wayne Rogers',                'Wayne Rogers',            '171403',  'lost',   45.41, false, false, NULL),
  ('AR|Attorney General|60231', '20261103AR5729', 'a0c10af2-2694-4860-ac40-d5c863c9fd65'::uuid,
   'AR Attorney General',         'Tim Griffin',                 'Tim Griffin',             '60231',   'won',      100, true , false, '9298415e-b8e5-4ccf-9f2a-b9366dd8ca1a'::uuid),
  ('AR|Governor|70516', '20261103AR5626', '38e72906-3f76-4071-9973-7b64558f7a6e'::uuid,
   'AR Governor',                 'Sarah Huckabee Sanders',      'Sarah Huckabee Sanders',  '70516',   'won',    53.87, true , false, 'b4f849ef-ce62-45ad-b5af-be0a54e3fa95'::uuid),
  ('AR|Governor|102193', '20261103AR5626', '38e72906-3f76-4071-9973-7b64558f7a6e'::uuid,
   'AR Governor',                 'Fredrick Love',               'Fred Love',               '102193',  'lost',   38.58, false, false, NULL),
  ('AR|Governor|174770', '20261103AR5626', '38e72906-3f76-4071-9973-7b64558f7a6e'::uuid,
   'AR Governor',                 'Colt Shelby',                 'Colt Shelby',             '174770',  'lost',    7.55, false, false, NULL),
  ('AR|Lieutenant Governor|102485', '20261103AR5315', '73bf9b8d-275d-4e15-bb1f-dd245ef8e68d'::uuid,
   'AR Lieutenant Governor',      'Leslie Rutledge',             'Leslie Rutledge',         '102485',  'won',    63.89, true , false, 'e8d0cb0c-a145-4483-860e-4e6af68f0a8b'::uuid),
  ('AR|Lieutenant Governor|66362', '20261103AR5315', '73bf9b8d-275d-4e15-bb1f-dd245ef8e68d'::uuid,
   'AR Lieutenant Governor',      'Michael Kalagias',            'Michael Kalagias',        '66362',   'lost',   36.11, false, false, NULL),
  ('AR|Secretary of State|102119', '20261103AR5728', '9af74283-be8f-4964-ad8e-836ddc8dc3ec'::uuid,
   'AR Secretary of State',       'Kim Hammer',                  'Kim Hammer',              '102119',  'won',    55.85, false, false, NULL),
  ('AR|Secretary of State|169542', '20261103AR5728', '9af74283-be8f-4964-ad8e-836ddc8dc3ec'::uuid,
   'AR Secretary of State',       'Kelly Grappe',                'Kelly Grappe',            '169542',  'lost',   39.57, false, false, NULL),
  ('AR|Secretary of State|168552', '20261103AR5728', '9af74283-be8f-4964-ad8e-836ddc8dc3ec'::uuid,
   'AR Secretary of State',       'Michael Pakko',               'Michael Pakko',           '168552',  'lost',    4.57, false, false, NULL),
  ('CT|Attorney General|106050', '20261103CT7029', 'b0413048-a7ba-44fb-953d-d7f2510ba031'::uuid,
   'CT Attorney General',         'William Tong',                'William Tong',            '106050',  'won',    63.06, true , false, '134c2bfa-eb1f-4e67-beb6-505624707a2f'::uuid),
  ('CT|Attorney General|167164', '20261103CT7029', 'b0413048-a7ba-44fb-953d-d7f2510ba031'::uuid,
   'CT Attorney General',         'John Bolton',                 'John Bolton',             '167164',  'lost',   36.94, false, false, NULL),
  ('CT|Governor|51911', '20261103CT7019', '58562e19-0ea9-4cef-a0d2-9a7586ef0892'::uuid,
   'CT Governor',                 'Ned Lamont',                  'Ned Lamont',              '51911',   'won',    59.12, true , false, 'eca2c4af-c882-42f6-bcb9-e656e1264758'::uuid),
  ('CT|Governor|109320', '20261103CT7019', '58562e19-0ea9-4cef-a0d2-9a7586ef0892'::uuid,
   'CT Governor',                 'Ryan Fazio',                  'Ryan Fazio',              '109320',  'lost',   40.88, false, false, NULL),
  ('DE|Attorney General|176060', '20261103DE8283', '58120cc2-36cb-4874-b61b-7736968cbda1'::uuid,
   'DE Attorney General',         'Kathy Jennings',              'Kathy Jennings',          '176060',  'won',    63.62, true , false, '811bd5cb-8c0f-41a5-b78b-18d76151b994'::uuid),
  ('DE|Attorney General|179371', '20261103DE8283', '58120cc2-36cb-4874-b61b-7736968cbda1'::uuid,
   'DE Attorney General',         'David Graham',                'David Graham',            '179371',  'lost',   36.38, false, false, NULL),
  ('FL|Attorney General|175594', '20261103FL10049', '9e399ee2-5270-4877-9941-f0cd30235ace'::uuid,
   'FL Attorney General',         'James Uthmeier',              'James Uthmeier',          '175594',  'won',    50.93, true , false, '2e0915c5-45d7-48de-ae59-04bcd6bda1f7'::uuid),
  ('FL|Attorney General|107326', '20261103FL10049', '9e399ee2-5270-4877-9941-f0cd30235ace'::uuid,
   'FL Attorney General',         'José Javier Rodriguez',       'José Rodriguez',          '107326',  'lost',   49.07, false, false, NULL),
  ('FL|Governor|62408', '20261103FL10045', 'e2dd77a5-604e-4537-8fe7-5b74f0cbc1d6'::uuid,
   'FL Governor',                 'Byron Donalds',               'Byron Donalds',           '62408',   'won',    50.02, false, false, '13972902-fa8a-4ebc-91f6-b451db77c7d1'::uuid),
  ('FL|Governor|63159', '20261103FL10045', 'e2dd77a5-604e-4537-8fe7-5b74f0cbc1d6'::uuid,
   'FL Governor',                 'David Jolly',                 'David Jolly',             '63159',   'lost',   48.71, false, false, NULL),
  ('FL|Governor|178993', '20261103FL10045', 'e2dd77a5-604e-4537-8fe7-5b74f0cbc1d6'::uuid,
   'FL Governor',                 'Scott Jewett',                'Scott Jewett',            '178993',  'lost',    0.46, false, false, NULL),
  ('FL|Governor|178995', '20261103FL10045', 'e2dd77a5-604e-4537-8fe7-5b74f0cbc1d6'::uuid,
   'FL Governor',                 'Frank Russo',                 'Frank Russo',             '178995',  'lost',    0.28, false, false, NULL),
  ('FL|Governor|178990', '20261103FL10045', 'e2dd77a5-604e-4537-8fe7-5b74f0cbc1d6'::uuid,
   'FL Governor',                 'Charles Burkett',             'Charles Burkett',         '178990',  'lost',    0.18, false, false, NULL),
  ('FL|Governor|178989', '20261103FL10045', 'e2dd77a5-604e-4537-8fe7-5b74f0cbc1d6'::uuid,
   'FL Governor',                 'Dean Abrams',                 'Dean Abrams',             '178989',  'lost',    0.15, false, false, NULL),
  ('FL|Governor|178991', '20261103FL10045', 'e2dd77a5-604e-4537-8fe7-5b74f0cbc1d6'::uuid,
   'FL Governor',                 'Jeffrey Datto',               'Jeffrey Datto',           '178991',  'lost',     0.1, false, false, NULL),
  ('FL|Governor|178992', '20261103FL10045', 'e2dd77a5-604e-4537-8fe7-5b74f0cbc1d6'::uuid,
   'FL Governor',                 'Moliere Dimanche',            'Moliere Dimanche',        '178992',  'lost',    0.09, false, false, NULL),
  ('GA|Attorney General|112352', '20261103GA11033', '525e4d1f-2648-4101-8ed7-ae4357ca9082'::uuid,
   'GA Attorney General',         'Tanya Miller',                'Tanya Miller',            '112352',  'won',    55.55, false, false, '1d40e77c-40f0-4475-bf2f-ff0a544a8eaf'::uuid),
  ('GA|Attorney General|109167', '20261103GA11033', '525e4d1f-2648-4101-8ed7-ae4357ca9082'::uuid,
   'GA Attorney General',         'Brian Strickland',            'Brian Strickland',        '109167',  'lost',   44.45, false, false, 'fc440298-213d-4985-b16d-191f5d1c67cf'::uuid),
  ('GA|Governor|110638', '20261103GA12029', '2411d0c8-5959-4013-8a32-0cc5ffb9868a'::uuid,
   'GA Governor',                 'Keisha Bottoms',              'Keisha Bottoms',          '110638',  'won',    54.33, false, false, NULL),
  ('GA|Governor|171426', '20261103GA12029', '2411d0c8-5959-4013-8a32-0cc5ffb9868a'::uuid,
   'GA Governor',                 'Rick Jackson',                'Rick Jackson',            '171426',  'lost',   45.67, false, false, NULL),
  ('GA|Lieutenant Governor|111031', '20261103GA11029', '56f2ebbe-b7e1-4790-b50a-ee33707e2a15'::uuid,
   'GA Lieutenant Governor',      'Josh McLaurin',               'Josh McLaurin',           '111031',  'won',    55.96, false, false, 'ce3bc454-d297-44f7-b145-601cb592d9c2'::uuid),
  ('GA|Lieutenant Governor|110781', '20261103GA11029', '56f2ebbe-b7e1-4790-b50a-ee33707e2a15'::uuid,
   'GA Lieutenant Governor',      'Greg Dolezal',                'Greg Dolezal',            '110781',  'lost',   44.04, false, false, 'a9c06c0b-b8a0-4a2c-9762-ab1f4bea97fb'::uuid),
  ('GA|Secretary of State|171430', '20261103GA11031', '069e295f-4266-407b-be0c-b31238d0e80b'::uuid,
   'GA Secretary of State',       'Penny Brown Reynolds',        'Penny Reynolds',          '171430',  'won',    55.69, false, false, NULL),
  ('GA|Secretary of State|112465', '20261103GA11031', '069e295f-4266-407b-be0c-b31238d0e80b'::uuid,
   'GA Secretary of State',       'Tim Fleming',                 'Tim Fleming',             '112465',  'lost',   44.31, false, false, '7d2f345d-c98c-42f0-9bf3-655a8a572599'::uuid),
  ('HI|Governor|71471', '20261103HI12480', '69eaf89c-9d6f-4314-be40-e589fc71f144'::uuid,
   'HI Governor',                 'Joshua Green',                'Josh Green',              '71471',   'won',    72.65, true , false, '76307cf7-47dd-4b0a-ac4b-ed218095bf47'::uuid),
  ('HI|Governor|71276', '20261103HI12480', '69eaf89c-9d6f-4314-be40-e589fc71f144'::uuid,
   'HI Governor',                 'Gary Cordery',                'Gary Cordery',            '71276',   'lost',   27.35, false, false, '1bb21d89-c9c1-4b69-bbd3-04b6a0fc745f'::uuid),
  ('IA|Governor|114528', '20261103IA17076', '26e6c494-f075-478c-8576-3c217e1b2202'::uuid,
   'IA Governor',                 'Rob Sand',                    'Rob Sand',                '114528',  'won',    55.49, false, false, NULL),
  ('IA|Governor|173748', '20261103IA17076', '26e6c494-f075-478c-8576-3c217e1b2202'::uuid,
   'IA Governor',                 'Zach Lahn',                   'Zach Lahn',               '173748',  'lost',   44.51, false, false, NULL),
  ('IA|Secretary of State|114183', '20261103IA16950', '0bec374b-a5c4-404f-b9a1-eac2b9aaed39'::uuid,
   'IA Secretary of State',       'Paul Pate',                   'Paul Pate',               '114183',  'won',    53.21, true , false, 'e9d4ee27-3f0d-487e-b68f-3c5510999834'::uuid),
  ('IA|Secretary of State|173763', '20261103IA16950', '0bec374b-a5c4-404f-b9a1-eac2b9aaed39'::uuid,
   'IA Secretary of State',       'Ryan Peterman',               'Ryan Peterman',           '173763',  'lost',   46.79, false, false, NULL),
  ('ID|Attorney General|60527', '20261103ID13681', '3c42cbb6-afba-493e-a48e-5330fe73451b'::uuid,
   'ID Attorney General',         'Raúl Labrador',               'Raul Labrador',           '60527',   'won',    59.84, true , false, 'e0bab0e6-dc32-4d68-a479-0f59a79c0cf4'::uuid),
  ('ID|Attorney General|172102', '20261103ID13681', '3c42cbb6-afba-493e-a48e-5330fe73451b'::uuid,
   'ID Attorney General',         'Lori Hickman',                'Lori Hickman',            '172102',  'lost',   40.16, false, false, NULL),
  ('ID|Governor|53635', '20261103ID13676', '66dbc16e-56ea-47f9-86ac-b82078ada305'::uuid,
   'ID Governor',                 'Brad Little',                 'Brad Little',             '53635',   'won',    57.07, true , false, 'd36ab4ef-dbf4-4b60-9f8b-db497dfb5de4'::uuid),
  ('ID|Governor|112763', '20261103ID13676', '66dbc16e-56ea-47f9-86ac-b82078ada305'::uuid,
   'ID Governor',                 'Terri Pickens',               'Terri Pickens',           '112763',  'lost',   32.34, false, false, NULL),
  ('ID|Governor|178019', '20261103ID13676', '66dbc16e-56ea-47f9-86ac-b82078ada305'::uuid,
   'ID Governor',                 'John R. Stegner',             'John Stegner',            '178019',  'lost',     7.6, false, false, NULL),
  ('ID|Governor|70344', '20261103ID13676', '66dbc16e-56ea-47f9-86ac-b82078ada305'::uuid,
   'ID Governor',                 'Paul Sand',                   'Paul Sand',               '70344',   'lost',    1.62, false, false, NULL),
  ('ID|Governor|56769', '20261103ID13676', '66dbc16e-56ea-47f9-86ac-b82078ada305'::uuid,
   'ID Governor',                 'Pro-Life',                    'Pro-Life',                '56769',   'lost',    1.33, false, false, NULL),
  ('ID|Governor|178018', '20261103ID13676', '66dbc16e-56ea-47f9-86ac-b82078ada305'::uuid,
   'ID Governor',                 'Jacob Burnett',               'Jacob Burnett',           '178018',  'lost',    0.05, false, true , NULL),
  ('ID|Lieutenant Governor|53608', '20261103ID13677', '24c1a220-3ad3-47fc-adf3-1f6375453705'::uuid,
   'ID Lieutenant Governor',      'Scott Bedke',                 'Scott Bedke',             '53608',   'won',    63.52, true , false, '8cb018dc-a962-47b1-813c-6d1322b36037'::uuid),
  ('ID|Lieutenant Governor|172099', '20261103ID13677', '24c1a220-3ad3-47fc-adf3-1f6375453705'::uuid,
   'ID Lieutenant Governor',      'Eric Myricks',                'Eric Myricks',            '172099',  'lost',   36.48, false, false, NULL),
  ('ID|Secretary of State|112084', '20261103ID13678', '5ed58238-3f48-4771-b1bd-b4b5f312ea40'::uuid,
   'ID Secretary of State',       'Phil McGrane',                'Phil McGrane',            '112084',  'won',    67.39, true , false, 'ade5ce47-25a7-4332-848f-877404875f0e'::uuid),
  ('ID|Secretary of State|112765', '20261103ID13678', '5ed58238-3f48-4771-b1bd-b4b5f312ea40'::uuid,
   'ID Secretary of State',       'Shawn Keenan',                'Shawn Keenan',            '112765',  'lost',   32.61, false, false, NULL),
  ('IL|Attorney General|17760', '20261103IL15258', '33e4c5d9-da0d-4d4d-a429-a52620887bc6'::uuid,
   'IL Attorney General',         'Kwame Raoul',                 'Kwame Raoul',             '17760',   'won',    61.27, true , false, 'dcf335bf-ca4f-4878-8ef6-616380ff19db'::uuid),
  ('IL|Attorney General|116492', '20261103IL15258', '33e4c5d9-da0d-4d4d-a429-a52620887bc6'::uuid,
   'IL Attorney General',         'Bob Fioretti',                'Robert Fioretti',         '116492',  'lost',   38.73, false, false, NULL),
  ('IL|Governor|17710', '20261103IL15989', 'b8fa5cdf-e0e4-47b3-abe7-b46e03e55c43'::uuid,
   'IL Governor',                 'JB Pritzker',                 'JB Pritzker',             '17710',   'won',    59.73, true , false, '557dc739-3701-443c-ab97-7d9c5c3d40db'::uuid),
  ('IL|Governor|71049', '20261103IL15989', 'b8fa5cdf-e0e4-47b3-abe7-b46e03e55c43'::uuid,
   'IL Governor',                 'Darren Bailey',               'Darren Bailey',           '71049',   'lost',   36.93, false, false, NULL),
  ('IL|Governor|178028', '20261103IL15989', 'b8fa5cdf-e0e4-47b3-abe7-b46e03e55c43'::uuid,
   'IL Governor',                 'Collin Corbett',              'Collin Corbett',          '178028',  'lost',    3.34, false, false, NULL),
  ('IL|Secretary of State|60136', '20261103IL15257', 'be10035e-21ec-4288-8130-14a8b5cba72b'::uuid,
   'IL Secretary of State',       'Alexi Giannoulias',           'Alexi Giannoulias',       '60136',   'won',    64.45, true , false, '65df6ce5-a824-4b24-a0a9-d031e3631272'::uuid),
  ('IL|Secretary of State|63211', '20261103IL15257', 'be10035e-21ec-4288-8130-14a8b5cba72b'::uuid,
   'IL Secretary of State',       'Diane Harris',                'Diane Harris',            '63211',   'lost',   35.55, false, false, NULL),
  ('MA|Attorney General|124893', '20261103MA22960', 'acff6f85-1bc2-4f50-94e6-58294f5f096a'::uuid,
   'MA Attorney General',         'Andrea Campbell',             'Andrea Campbell',         '124893',  'won',    65.62, true , false, '602f147a-90bc-4083-aeab-1d0becf088e9'::uuid),
  ('MA|Attorney General|124347', '20261103MA22960', 'acff6f85-1bc2-4f50-94e6-58294f5f096a'::uuid,
   'MA Attorney General',         'Michael Walsh',               'Michael Walsh',           '124347',  'lost',   34.38, false, false, NULL),
  ('MA|Governor|71279', '20261103MA22957', '21f9e818-904d-4a19-879b-438f447bcd68'::uuid,
   'MA Governor',                 'Maura Healey',                'Maura Healey',            '71279',   'won',    62.16, true , false, '7cf1080e-6e7e-4f5b-be00-6fb170896a7c'::uuid),
  ('MA|Governor|176606', '20261103MA22957', '21f9e818-904d-4a19-879b-438f447bcd68'::uuid,
   'MA Governor',                 'Michael Minogue',             'Michael Minogue',         '176606',  'lost',   34.49, false, false, NULL),
  ('MA|Governor|179350', '20261103MA22957', '21f9e818-904d-4a19-879b-438f447bcd68'::uuid,
   'MA Governor',                 'Andrea James',                'Andrea James',            '179350',  'lost',    3.35, false, false, NULL),
  ('MD|Attorney General|54705', '20261103MD22092', '6f9fd58a-442c-4c58-bd6d-f36a1bcbf114'::uuid,
   'MD Attorney General',         'Anthony G. Brown',            'Anthony Brown',           '54705',   'won',    67.07, true , false, '60329719-1d5b-4bb4-8295-38ea18f6f378'::uuid),
  ('MD|Attorney General|173033', '20261103MD22092', '6f9fd58a-442c-4c58-bd6d-f36a1bcbf114'::uuid,
   'MD Attorney General',         'James Rutledge',              'James Rutledge',          '173033',  'lost',   32.93, false, false, '579020c7-482d-440e-b2f7-f7191da9b0e5'::uuid),
  ('MD|Governor|71129', '20261103MD22091', '1a7ac65d-983a-4c62-85bc-d506ea2755a3'::uuid,
   'MD Governor',                 'Wes Moore',                   'Wes Moore',               '71129',   'won',    62.78, true , false, '21e534c8-c0c0-42f5-b52b-5eb2f246d632'::uuid),
  ('MD|Governor|64816', '20261103MD22091', '1a7ac65d-983a-4c62-85bc-d506ea2755a3'::uuid,
   'MD Governor',                 'Dan Cox',                     'Dan Cox',                 '64816',   'lost',   33.19, false, false, '4a876d03-4e8f-4d0a-a236-4f594b59f29c'::uuid),
  ('MD|Governor|178524', '20261103MD22091', '1a7ac65d-983a-4c62-85bc-d506ea2755a3'::uuid,
   'MD Governor',                 'Andy Ellis',                  'Andy Ellis',              '178524',  'lost',    2.06, false, false, '48593795-6e01-4da0-99b3-ef522b906652'::uuid),
  ('MD|Governor|178525', '20261103MD22091', '1a7ac65d-983a-4c62-85bc-d506ea2755a3'::uuid,
   'MD Governor',                 'Cathy White',                 'Cathy White',             '178525',  'lost',    1.97, false, false, NULL),
  ('ME|Governor|174083', '20261103ME20646', '95700fc5-2800-4766-9005-38dc7237c455'::uuid,
   'ME Governor',                 'Hannah Pingree',              'Hannah Pingree',          '174083',  'won',    54.62, false, false, 'ac09c6dc-d7db-4bdb-9829-0e746c8ca665'::uuid),
  ('ME|Governor|174086', '20261103ME20646', '95700fc5-2800-4766-9005-38dc7237c455'::uuid,
   'ME Governor',                 'Bobby Charles',               'Robert Charles',          '174086',  'lost',   37.26, false, false, '8aad9681-4dc3-4803-9ff1-7c004303b4ab'::uuid),
  ('ME|Governor|177853', '20261103ME20646', '95700fc5-2800-4766-9005-38dc7237c455'::uuid,
   'ME Governor',                 'Richard Bennett',             'Rick Bennett',            '177853',  'lost',    8.08, false, false, 'e73bd689-240f-492a-bf01-f7be307367f8'::uuid),
  ('ME|Governor|179066', '20261103ME20646', '95700fc5-2800-4766-9005-38dc7237c455'::uuid,
   'ME Governor',                 'Randy Wilcox',                'Randy Wilcox',            '179066',  'lost',    0.03, false, true , NULL),
  ('ME|Governor|120654', '20261103ME20646', '95700fc5-2800-4766-9005-38dc7237c455'::uuid,
   'ME Governor',                 'John Glowa',                  'John Glowa',              '120654',  'lost',    0.01, false, true , NULL),
  ('MI|Attorney General|178885', '20261103MI24116', 'a5281741-c2b2-4aac-8293-66b96cc6dce0'::uuid,
   'MI Attorney General',         'Eli Savit',                   'Eli Savit',               '178885',  'won',    52.48, false, false, NULL),
  ('MI|Attorney General|178886', '20261103MI24116', 'a5281741-c2b2-4aac-8293-66b96cc6dce0'::uuid,
   'MI Attorney General',         'Doug Lloyd',                  'Doug Lloyd',              '178886',  'lost',   44.75, false, false, NULL),
  ('MI|Attorney General|178923', '20261103MI24116', 'a5281741-c2b2-4aac-8293-66b96cc6dce0'::uuid,
   'MI Attorney General',         'Jason Dye',                   'Jason Dye',               '178923',  'lost',    1.25, false, false, NULL),
  ('MI|Attorney General|177001', '20261103MI24116', 'a5281741-c2b2-4aac-8293-66b96cc6dce0'::uuid,
   'MI Attorney General',         'John Ludtke',                 'John Ludtke',             '177001',  'lost',    0.68, false, false, NULL),
  ('MI|Attorney General|178924', '20261103MI24116', 'a5281741-c2b2-4aac-8293-66b96cc6dce0'::uuid,
   'MI Attorney General',         'Jeff Polonowski',             'Jeff Polonowski',         '178924',  'lost',    0.53, false, false, NULL),
  ('MI|Attorney General|771', '20261103MI24116', 'a5281741-c2b2-4aac-8293-66b96cc6dce0'::uuid,
   'MI Attorney General',         'Doug Dern',                   'Doug Dern',               '771',     'lost',     0.3, false, false, NULL),
  ('MI|Governor|128670', '20261103MI24074', '68da5056-e5aa-4653-9a61-feb3e3f3b257'::uuid,
   'MI Governor',                 'Jocelyn Benson',              'Jocelyn Benson',          '128670',  'won',    54.52, false, false, '5d59648a-be0a-4a19-bb3d-344754a559ef'::uuid),
  ('MI|Governor|166570', '20261103MI24074', '68da5056-e5aa-4653-9a61-feb3e3f3b257'::uuid,
   'MI Governor',                 'John James',                  'John James',              '166570',  'lost',   43.76, false, false, '1c1f6614-fb03-4aa8-879b-2470a1dcd59f'::uuid),
  ('MI|Governor|166567', '20261103MI24074', '68da5056-e5aa-4653-9a61-feb3e3f3b257'::uuid,
   'MI Governor',                 'Anthony Hudson',              'Anthony Hudson',          '166567',  'lost',    0.93, false, false, NULL),
  ('MI|Governor|70820', '20261103MI24074', '68da5056-e5aa-4653-9a61-feb3e3f3b257'::uuid,
   'MI Governor',                 'Donna Brandenburg',           'Donna Brandenburg',       '70820',   'lost',    0.42, false, false, NULL),
  ('MI|Governor|1321', '20261103MI24074', '68da5056-e5aa-4653-9a61-feb3e3f3b257'::uuid,
   'MI Governor',                 'Douglas Campbell',            'Douglas Campbell',        '1321',    'lost',    0.37, false, false, NULL),
  ('MI|Secretary of State|178884', '20261103MI24115', '971841d3-b324-4870-b9b5-e2db53391d1d'::uuid,
   'MI Secretary of State',       'Garlin Gilchrist II',         'Garlin Gilchrist',        '178884',  'won',    53.74, false, false, '312e77d1-8fc7-4a75-8731-2f252d72e2a4'::uuid),
  ('MI|Secretary of State|65347', '20261103MI24115', '971841d3-b324-4870-b9b5-e2db53391d1d'::uuid,
   'MI Secretary of State',       'Anthony Forlini',             'Anthony Forlini',         '65347',   'lost',   43.58, false, false, NULL),
  ('MI|Secretary of State|178921', '20261103MI24115', '971841d3-b324-4870-b9b5-e2db53391d1d'::uuid,
   'MI Secretary of State',       'Christine Sloan',             'Christine Sloan',         '178921',  'lost',    1.63, false, false, NULL),
  ('MI|Secretary of State|178922', '20261103MI24115', '971841d3-b324-4870-b9b5-e2db53391d1d'::uuid,
   'MI Secretary of State',       'Scott Aughney',               'Scott Aughney',           '178922',  'lost',     0.6, false, false, NULL),
  ('MI|Secretary of State|127616', '20261103MI24115', '971841d3-b324-4870-b9b5-e2db53391d1d'::uuid,
   'MI Secretary of State',       'Eric Borregard',              'Eric Borregard',          '127616',  'lost',    0.45, false, false, NULL),
  ('MN|Attorney General|55265', '20261103MN24793', 'a2cb5ff8-4a75-4563-b346-cdde981b710d'::uuid,
   'MN Attorney General',         'Keith Ellison',               'Keith Ellison',           '55265',   'won',    54.29, true , false, '9b7310b5-d12f-419d-af87-6ad834a1055a'::uuid),
  ('MN|Attorney General|177197', '20261103MN24793', 'a2cb5ff8-4a75-4563-b346-cdde981b710d'::uuid,
   'MN Attorney General',         'Ron Schutz',                  'Ronald Schutz',           '177197',  'lost',   45.56, false, false, NULL),
  ('MN|Governor|159027', '20261103MN24704', '73fc9ecc-3b0b-445e-898a-1d51b9846d32'::uuid,
   'MN Governor',                 'Amy Klobuchar',               'Amy Klobuchar',           '159027',  'won',    55.46, false, false, '3d51cca6-7206-413b-ab8d-3199a58a6767'::uuid),
  ('MN|Governor|126628', '20261103MN24704', '73fc9ecc-3b0b-445e-898a-1d51b9846d32'::uuid,
   'MN Governor',                 'Lisa Demuth',                 'Lisa Demuth',             '126628',  'lost',   42.63, false, false, 'e49ed577-d00e-402f-bf80-5546baae414f'::uuid),
  ('MN|Governor|179590', '20261103MN24704', '73fc9ecc-3b0b-445e-898a-1d51b9846d32'::uuid,
   'MN Governor',                 'Steven Young',                'Steven Young',            '179590',  'lost',    1.82, false, false, NULL),
  ('MN|Secretary of State|122463', '20261103MN24710', '186e84b2-0798-43cf-88a3-0fde73138dff'::uuid,
   'MN Secretary of State',       'Steve Simon',                 'Steve Simon',             '122463',  'won',    54.71, true , false, 'd95b4426-cd5e-4970-a46e-ae9b7ee16012'::uuid),
  ('MN|Secretary of State|124249', '20261103MN24710', '186e84b2-0798-43cf-88a3-0fde73138dff'::uuid,
   'MN Secretary of State',       'Tad Jude',                    'Tad Jude',                '124249',  'lost',   41.81, false, false, NULL),
  ('MN|Secretary of State|179592', '20261103MN24710', '186e84b2-0798-43cf-88a3-0fde73138dff'::uuid,
   'MN Secretary of State',       'Chip Tangen',                 'George Tangen',           '179592',  'lost',    1.96, false, false, NULL),
  ('MN|Secretary of State|179591', '20261103MN24710', '186e84b2-0798-43cf-88a3-0fde73138dff'::uuid,
   'MN Secretary of State',       'Seth Kuhl-Stennes',           'Seth Kuhl-Stennes',       '179591',  'lost',    1.48, false, false, NULL),
  ('ND|Attorney General|135218', '20261103ND35345', 'a9c867cf-371e-4ab6-af26-0a4c508d3a85'::uuid,
   'ND Attorney General',         'Drew Wrigley',                'Drew Wrigley',            '135218',  'won',    63.93, true , false, '86a3a804-41ea-49c9-badd-0b48582df08e'::uuid),
  ('ND|Attorney General|135217', '20261103ND35345', 'a9c867cf-371e-4ab6-af26-0a4c508d3a85'::uuid,
   'ND Attorney General',         'Timothy Lamb',                'Tim Lamb',                '135217',  'lost',   36.07, false, false, NULL),
  ('ND|Secretary of State|134977', '20261103ND35344', '5fd38de4-2c16-4e6e-881d-db543699a01a'::uuid,
   'ND Secretary of State',       'Michael Howe',                'Michael Howe',            '134977',  'won',    62.08, true , false, 'd7cc7826-afd2-43fb-85b4-76c9aeccd1db'::uuid),
  ('ND|Secretary of State|135245', '20261103ND35344', '5fd38de4-2c16-4e6e-881d-db543699a01a'::uuid,
   'ND Secretary of State',       'Ryan Braunberger',            'Ryan Braunberger',        '135245',  'lost',   37.92, false, false, '86c6b5b8-27a1-4ad5-9969-d914748af34d'::uuid),
  ('NE|Attorney General|128715', '20261103NE28011', 'd2e27132-0182-41d6-8fdc-7ff1977fe1c9'::uuid,
   'NE Attorney General',         'Mike Hilgers',                'Mike Hilgers',            '128715',  'won',    56.35, true , false, 'e32910d5-50f2-4ab9-afc0-a5dd605c429b'::uuid),
  ('NE|Attorney General|171170', '20261103NE28011', 'd2e27132-0182-41d6-8fdc-7ff1977fe1c9'::uuid,
   'NE Attorney General',         'Jocelyn Brasher',             'Jocelyn Brasher',         '171170',  'lost',   43.65, false, false, NULL),
  ('NE|Governor|69957', '20261103NE28006', 'c45af066-9b43-4aee-bcbd-65e5e2369548'::uuid,
   'NE Governor',                 'Jim Pillen',                  'Jim Pillen',              '69957',   'won',    50.76, true , false, '5751ccd5-8b7a-4ce4-9247-e308c703a809'::uuid),
  ('NE|Governor|129088', '20261103NE28006', 'c45af066-9b43-4aee-bcbd-65e5e2369548'::uuid,
   'NE Governor',                 'Lynne Walz',                  'Lynne Walz',              '129088',  'lost',   42.18, false, false, NULL),
  ('NE|Governor|61797', '20261103NE28006', 'c45af066-9b43-4aee-bcbd-65e5e2369548'::uuid,
   'NE Governor',                 'Brett Lindstrom',             'Brett Lindstrom',         '61797',   'lost',     4.4, false, false, NULL),
  ('NE|Governor|175131', '20261103NE28006', 'c45af066-9b43-4aee-bcbd-65e5e2369548'::uuid,
   'NE Governor',                 'Rick Beard',                  'Rick Beard',              '175131',  'lost',    2.66, false, false, NULL),
  ('NE|Secretary of State|171167', '20261103NE28009', '4496d005-bb8d-4b8b-8350-ba187f9be331'::uuid,
   'NE Secretary of State',       'Scott Petersen',              'Scott Petersen',          '171167',  'won',    54.03, false, false, NULL),
  ('NE|Secretary of State|129548', '20261103NE28009', '4496d005-bb8d-4b8b-8350-ba187f9be331'::uuid,
   'NE Secretary of State',       'Sarah Slattery',              'Sarah Slattery',          '129548',  'lost',    40.3, false, false, NULL),
  ('NE|Secretary of State|179200', '20261103NE28009', '4496d005-bb8d-4b8b-8350-ba187f9be331'::uuid,
   'NE Secretary of State',       'Paul Rumbaugh',               'Paul Rumbaugh',           '179200',  'lost',    3.09, false, false, NULL),
  ('NE|Secretary of State|179201', '20261103NE28009', '4496d005-bb8d-4b8b-8350-ba187f9be331'::uuid,
   'NE Secretary of State',       'Bob Krist',                   'Bob Krist',               '179201',  'lost',    2.57, false, false, NULL),
  ('NH|Governor|61040', '20261103NH30005', 'ae8e7bfa-651a-4b8a-9d14-235b51c13e3f'::uuid,
   'NH Governor',                 'Kelly Ayotte',                'Kelly Ayotte',            '61040',   'won',    51.16, true , false, '13d45047-8183-46bd-a04a-5f5420b710cc'::uuid),
  ('NH|Governor|139961', '20261103NH30005', 'ae8e7bfa-651a-4b8a-9d14-235b51c13e3f'::uuid,
   'NH Governor',                 'Cinde Warmington',            'Cinde Warmington',        '139961',  'lost',   47.33, false, false, NULL),
  ('NH|Governor|168217', '20261103NH30005', 'ae8e7bfa-651a-4b8a-9d14-235b51c13e3f'::uuid,
   'NH Governor',                 'Stephen Villee',              'Stephen Villee',          '168217',  'lost',    1.51, false, false, NULL),
  ('NM|Attorney General|134003', '20261103NM32350', '9e0f9033-a22b-424a-bfaf-df903fbebf15'::uuid,
   'NM Attorney General',         'Raul Torrez',                 'Raul Torrez',             '134003',  'won',    62.95, true , false, 'e61e062d-cde2-424b-b384-ae4eb4bfc6bf'::uuid),
  ('NM|Attorney General|173272', '20261103NM32350', '9e0f9033-a22b-424a-bfaf-df903fbebf15'::uuid,
   'NM Attorney General',         'Samuel Kane',                 'Samuel Kane',             '173272',  'lost',   37.05, false, false, NULL),
  ('NM|Governor|64378', '20261103NM32238', 'bae1e006-1759-49cd-a802-05cc098ed99c'::uuid,
   'NM Governor',                 'Debra Haaland',               'Deb Haaland',             '64378',   'won',    57.28, false, false, NULL),
  ('NM|Governor|172994', '20261103NM32238', 'bae1e006-1759-49cd-a802-05cc098ed99c'::uuid,
   'NM Governor',                 'Gregg Hull',                  'Greggory Hull',           '172994',  'lost',   42.72, false, false, NULL),
  ('NM|Secretary of State|173270', '20261103NM32342', '3bae9063-56a0-4d1c-94f6-6e90aa2f403b'::uuid,
   'NM Secretary of State',       'Amanda López Askin',          'Amanda López Askin',      '173270',  'won',    60.86, false, false, NULL),
  ('NM|Secretary of State|173271', '20261103NM32342', '3bae9063-56a0-4d1c-94f6-6e90aa2f403b'::uuid,
   'NM Secretary of State',       'Ramona Goolsby',              'Ramona Goolsby',          '173271',  'lost',   39.14, false, false, NULL),
  ('NY|Attorney General|33000', '20261103NY36820', 'ac3d6525-46d9-43a7-8005-112330f11c9f'::uuid,
   'NY Attorney General',         'Letitia James',               'Letitia James',           '33000',   'won',    60.04, true , false, '406dd9be-a751-4685-a946-44806bd01548'::uuid),
  ('NY|Attorney General|174055', '20261103NY36820', 'ac3d6525-46d9-43a7-8005-112330f11c9f'::uuid,
   'NY Attorney General',         'Saritha Komatireddy',         'Saritha Komatireddy',     '174055',  'lost',   39.89, false, false, NULL),
  ('NY|Governor|61285', '20261103NY39760', '2aafa674-b590-4bfb-b573-d620027467ab'::uuid,
   'NY Governor',                 'Kathy Hochul',                'Kathy Hochul',            '61285',   'won',     59.6, true , false, '90369b67-99c3-4e29-9f6c-8529350cf1eb'::uuid),
  ('NY|Governor|61145', '20261103NY39760', '2aafa674-b590-4bfb-b573-d620027467ab'::uuid,
   'NY Governor',                 'Bruce Blakeman',              'Bruce Blakeman',          '61145',   'lost',   40.19, false, false, NULL),
  ('OH|Governor|170750', '20261103OH36005', '9c2a4c5e-1262-4138-9446-a0c4736e3780'::uuid,
   'OH Governor',                 'Amy Acton',                   'Amy Acton',               '170750',  'won',    52.31, false, false, NULL),
  ('OH|Governor|71843', '20261103OH36005', '9c2a4c5e-1262-4138-9446-a0c4736e3780'::uuid,
   'OH Governor',                 'Vivek Ramaswamy',             'Vivek Ramaswamy',         '71843',   'lost',   44.38, false, false, NULL),
  ('OH|Governor|60901', '20261103OH36005', '9c2a4c5e-1262-4138-9446-a0c4736e3780'::uuid,
   'OH Governor',                 'Don Kissick',                 'Don Kissick',             '60901',   'lost',     3.3, false, false, NULL),
  ('OH|Secretary of State|142483', '20261103OH36011', 'fe1848f7-956f-4a98-9f48-b19c913dc84a'::uuid,
   'OH Secretary of State',       'Allison Russo',               'Allison Russo',           '142483',  'won',    50.25, false, false, NULL),
  ('OH|Secretary of State|141808', '20261103OH36011', 'fe1848f7-956f-4a98-9f48-b19c913dc84a'::uuid,
   'OH Secretary of State',       'Robert Sprague',              'Robert Sprague',          '141808',  'lost',    46.8, false, false, '171effdf-cf2b-49aa-ab26-29f26c2be755'::uuid),
  ('OH|Secretary of State|168202', '20261103OH36011', 'fe1848f7-956f-4a98-9f48-b19c913dc84a'::uuid,
   'OH Secretary of State',       'Tom Pruss',                   'Tom Pruss',               '168202',  'lost',    2.95, false, false, NULL),
  ('OK|Attorney General|137775', '20261103OK37895', '49173ad9-112e-47ef-8c96-8574fef6d151'::uuid,
   'OK Attorney General',         'Jon Echols',                  'Jon Echols',              '137775',  'won',    55.34, false, false, NULL),
  ('OK|Attorney General|173600', '20261103OK37895', '49173ad9-112e-47ef-8c96-8574fef6d151'::uuid,
   'OK Attorney General',         'Nick Coffey',                 'Nick Coffey',             '173600',  'lost',   44.66, false, false, NULL),
  ('OK|Governor|137606', '20261103OK37857', '78dacf12-acf1-41ba-9ccf-637b88d97bcb'::uuid,
   'OK Governor',                 'Mike Mazzei',                 'Mike Mazzei',             '137606',  'won',    51.93, false, false, NULL),
  ('OK|Governor|138897', '20261103OK37857', '78dacf12-acf1-41ba-9ccf-637b88d97bcb'::uuid,
   'OK Governor',                 'Cyndi Munson',                'Cyndi Munson',            '138897',  'lost',   45.92, false, false, NULL),
  ('OK|Governor|179040', '20261103OK37857', '78dacf12-acf1-41ba-9ccf-637b88d97bcb'::uuid,
   'OK Governor',                 'Robert Brooks',               'Robert Brooks',           '179040',  'lost',    1.04, false, false, NULL),
  ('OK|Governor|179039', '20261103OK37857', '78dacf12-acf1-41ba-9ccf-637b88d97bcb'::uuid,
   'OK Governor',                 'Jerry Griffin',               'Jerry Griffin',           '179039',  'lost',    0.66, false, false, NULL),
  ('OK|Governor|179041', '20261103OK37857', '78dacf12-acf1-41ba-9ccf-637b88d97bcb'::uuid,
   'OK Governor',                 'Orlando Lynn Bush',           'Orlando Bush',            '179041',  'lost',    0.45, false, false, NULL),
  ('OK|Lieutenant Governor|63815', '20261103OK37858', 'd188cd52-a64c-4378-bc6c-abb89ef38806'::uuid,
   'OK Lieutenant Governor',      'T. W. Shannon',               'T. Shannon',              '63815',   'won',    57.79, false, false, NULL),
  ('OK|Lieutenant Governor|173592', '20261103OK37858', 'd188cd52-a64c-4378-bc6c-abb89ef38806'::uuid,
   'OK Lieutenant Governor',      'Kelly Forbes',                'Kelly Forbes',            '173592',  'lost',   42.21, false, false, NULL),
  ('OR|Governor|70205', '20261103OR38019', '780f76cd-2ec0-42fc-bb67-74a8911ca1c8'::uuid,
   'OR Governor',                 'Tina Kotek',                  'Tina Kotek',              '70205',   'won',    51.91, true , false, '66c3bd97-94d1-4287-b1b8-86605a38cb97'::uuid),
  ('OR|Governor|70218', '20261103OR38019', '780f76cd-2ec0-42fc-bb67-74a8911ca1c8'::uuid,
   'OR Governor',                 'Christine Drazan',            'Christine Drazan',        '70218',   'lost',   45.28, false, false, '402a00be-71c3-4584-b29f-bf493365bffb'::uuid),
  ('OR|Governor|167924', '20261103OR38019', '780f76cd-2ec0-42fc-bb67-74a8911ca1c8'::uuid,
   'OR Governor',                 'Brett Smith',                 'Brett Smith',             '167924',  'lost',    2.69, false, false, NULL),
  ('PA|Governor|70066', '20261103PA39292', '99415af3-4691-49e5-a00e-33adcbe636d0'::uuid,
   'PA Governor',                 'Josh Shapiro',                'Josh Shapiro',            '70066',   'won',    60.39, true , false, 'c3956e15-01f6-46cf-95bd-edd43f0ae8f3'::uuid),
  ('PA|Governor|146618', '20261103PA39292', '99415af3-4691-49e5-a00e-33adcbe636d0'::uuid,
   'PA Governor',                 'Stacy Garrity',               'Stacy Garrity',           '146618',  'lost',   38.31, false, false, '066f7bc5-6e3d-4d17-9878-73d896a2369e'::uuid),
  ('PA|Governor|1112', '20261103PA39292', '99415af3-4691-49e5-a00e-33adcbe636d0'::uuid,
   'PA Governor',                 'Ken Krawchuk',                'Ken Krawchuk',            '1112',    'lost',    1.29, false, false, NULL),
  ('RI|Attorney General|178125', '20261103RI40011', 'ec794af6-bbb1-4d54-82ae-67cdcdc457ae'::uuid,
   'RI Attorney General',         'Kim Ahern',                   'Kimberly Ahern',          '178125',  'won',    66.34, false, false, NULL),
  ('RI|Attorney General|143376', '20261103RI40011', 'ec794af6-bbb1-4d54-82ae-67cdcdc457ae'::uuid,
   'RI Attorney General',         'Alan Gordon',                 'Alan Gordon',             '143376',  'lost',    33.4, false, false, NULL),
  ('RI|Governor|71486', '20261103RI40005', '75bfe876-3cc1-4ba7-bbfd-f18d3b06ab76'::uuid,
   'RI Governor',                 'Helena Foulkes',              'Helena Foulkes',          '71486',   'won',    57.69, false, false, NULL),
  ('RI|Governor|61223', '20261103RI40005', '75bfe876-3cc1-4ba7-bbfd-f18d3b06ab76'::uuid,
   'RI Governor',                 'Ken Block',                   'Kenneth Block',           '61223',   'lost',   27.78, false, false, NULL),
  ('RI|Governor|143645', '20261103RI40005', '75bfe876-3cc1-4ba7-bbfd-f18d3b06ab76'::uuid,
   'RI Governor',                 'Aaron Guckian',               'Aaron Guckian',           '143645',  'lost',   13.18, false, false, NULL),
  ('RI|Governor|168232', '20261103RI40005', '75bfe876-3cc1-4ba7-bbfd-f18d3b06ab76'::uuid,
   'RI Governor',                 'Christopher Reynolds',        'C. Reynolds',             '168232',  'lost',    0.57, false, false, 'ec5cb4d8-b857-4442-b1c0-96bd69537de6'::uuid),
  ('RI|Governor|179317', '20261103RI40005', '75bfe876-3cc1-4ba7-bbfd-f18d3b06ab76'::uuid,
   'RI Governor',                 'Jasjit Gotra',                'Jasjit Gotra',            '179317',  'lost',    0.46, false, false, NULL),
  ('RI|Lieutenant Governor|71854', '20261103RI40008', '8799c407-3d10-4e69-9322-be04c976f293'::uuid,
   'RI Lieutenant Governor',      'Sabina Matos',                'Sabina Matos',            '71854',   'won',    59.32, true , false, '8dfb13d5-f590-4afb-a00d-58c477f39b94'::uuid),
  ('RI|Lieutenant Governor|178112', '20261103RI40008', '8799c407-3d10-4e69-9322-be04c976f293'::uuid,
   'RI Lieutenant Governor',      'John Loughlin',               'John Loughlin',           '178112',  'lost',   40.38, false, false, NULL),
  ('RI|Secretary of State|143080', '20261103RI40010', '6d0f16b7-88f0-4bf6-b23f-2b3b65582da9'::uuid,
   'RI Secretary of State',       'Gregg Amore',                 'Gregg Amore',             '143080',  'won',      100, true , false, '8df7ff47-c5f1-4ba1-82dc-1e8f6abdc753'::uuid),
  ('SC|Attorney General|172871', '20261103SC41199', 'ba71d6b9-f182-43ad-8188-d8566266f2d4'::uuid,
   'SC Attorney General',         'David Stumbo',                'David Stumbo',            '172871',  'won',    52.32, false, false, NULL),
  ('SC|Attorney General|145208', '20261103SC41199', 'ba71d6b9-f182-43ad-8188-d8566266f2d4'::uuid,
   'SC Attorney General',         'Richard Hricik',              'Richard Hricik',          '145208',  'lost',   47.63, false, false, NULL),
  ('SC|Governor|143843', '20261103SC41191', '8b0de7c5-8fa0-46e9-814d-c720f0429975'::uuid,
   'SC Governor',                 'Alan Wilson',                 'Alan Wilson',             '143843',  'won',    51.59, false, false, '36120b17-6913-4ac0-bbc2-deaba73e8cf7'::uuid),
  ('SC|Governor|145291', '20261103SC41191', '8b0de7c5-8fa0-46e9-814d-c720f0429975'::uuid,
   'SC Governor',                 'Jermaine Johnson',            'Jermaine Johnson',        '145291',  'lost',   47.11, false, false, '5a642c1c-8754-49c5-ac1c-eff925a6cc43'::uuid),
  ('SC|Governor|70923', '20261103SC41191', '8b0de7c5-8fa0-46e9-814d-c720f0429975'::uuid,
   'SC Governor',                 'Michael Addison',             'Michael Addison',         '70923',   'lost',    0.79, false, false, NULL),
  ('SC|Governor|177976', '20261103SC41191', '8b0de7c5-8fa0-46e9-814d-c720f0429975'::uuid,
   'SC Governor',                 'Walid Hakim',                 'Walid Hakim',             '177976',  'lost',    0.45, false, false, NULL),
  ('SC|Secretary of State|40271', '20261103SC41195', '1ce91b70-b22f-4df1-8877-b665d59ce330'::uuid,
   'SC Secretary of State',       'Mark Hammond',                'Mark Hammond',            '40271',   'won',    52.86, true , false, '559e7f33-2285-4cc8-bf8b-4cb88839157e'::uuid),
  ('SC|Secretary of State|172867', '20261103SC41195', '1ce91b70-b22f-4df1-8877-b665d59ce330'::uuid,
   'SC Secretary of State',       'Jason Belton',                'Jason Belton',            '172867',  'lost',    47.1, false, false, NULL),
  ('SD|Attorney General|143717', '20261103SD42010', '410286b4-0bfa-4694-8270-1ac9046d77d3'::uuid,
   'SD Attorney General',         'Lance Russell',               'Lance Russell',           '143717',  'won',        0, false, false, NULL),
  ('SD|Governor|58102', '20261103SD42222', '519f011a-a114-4ee5-aac6-41a88a83c140'::uuid,
   'SD Governor',                 'Larry Rhoden',                'Larry Rhoden',            '58102',   'won',    63.49, true , false, '0a283b10-918c-4251-899b-5385c9174b6d'::uuid),
  ('SD|Governor|68738', '20261103SD42222', '519f011a-a114-4ee5-aac6-41a88a83c140'::uuid,
   'SD Governor',                 'Dan Ahlers',                  'Dan Ahlers',              '68738',   'lost',   36.51, false, false, NULL),
  ('SD|Secretary of State|163072', '20261103SD42009', '6de8c31e-52db-4b93-81cb-e676f5362dad'::uuid,
   'SD Secretary of State',       'Heather Baxter',              'Heather Baxter',          '163072',  'won',    58.39, false, false, '76c1003d-23ee-45f3-bf1c-a3436f6e852f'::uuid),
  ('SD|Secretary of State|178209', '20261103SD42009', '6de8c31e-52db-4b93-81cb-e676f5362dad'::uuid,
   'SD Secretary of State',       'Terrence Davis',              'Terrence Davis',          '178209',  'lost',    36.1, false, false, NULL),
  ('SD|Secretary of State|71643', '20261103SD42009', '6de8c31e-52db-4b93-81cb-e676f5362dad'::uuid,
   'SD Secretary of State',       'Tamara Lesnar',               'Tamara Lesnar',           '71643',   'lost',    5.51, false, false, NULL),
  ('TN|Governor|682', '20261103TN43440', 'b4667b62-fd9f-4ff5-9e5c-068f85ba6ce2'::uuid,
   'TN Governor',                 'Marsha Blackburn',            'Marsha Blackburn',        '682',     'won',    45.49, false, false, '808ab926-365f-4b8a-a42e-628f11ecc48e'::uuid),
  ('TN|Governor|147782', '20261103TN43440', 'b4667b62-fd9f-4ff5-9e5c-068f85ba6ce2'::uuid,
   'TN Governor',                 'Jerri Green',                 'Jerri Green',             '147782',  'lost',   42.98, false, false, 'f4b0bd70-e7e3-432c-bb34-8dc20cd382d1'::uuid),
  ('TN|Governor|178865', '20261103TN43440', 'b4667b62-fd9f-4ff5-9e5c-068f85ba6ce2'::uuid,
   'TN Governor',                 'David Hatley',                'David Hatley',            '178865',  'lost',     9.3, false, false, NULL),
  ('TN|Governor|178868', '20261103TN43440', 'b4667b62-fd9f-4ff5-9e5c-068f85ba6ce2'::uuid,
   'TN Governor',                 'Lauren Pinkston',             'Lauren Pinkston',         '178868',  'lost',    1.25, false, false, NULL),
  ('TN|Governor|178863', '20261103TN43440', 'b4667b62-fd9f-4ff5-9e5c-068f85ba6ce2'::uuid,
   'TN Governor',                 'Dean Brewer',                 'Dean Brewer',             '178863',  'lost',     0.2, false, false, NULL),
  ('TN|Governor|178864', '20261103TN43440', 'b4667b62-fd9f-4ff5-9e5c-068f85ba6ce2'::uuid,
   'TN Governor',                 'Ray Brown',                   'Ray Brown',               '178864',  'lost',    0.14, false, false, NULL),
  ('TN|Governor|178866', '20261103TN43440', 'b4667b62-fd9f-4ff5-9e5c-068f85ba6ce2'::uuid,
   'TN Governor',                 'Wendell Jackson',             'Wendell Jackson',         '178866',  'lost',    0.11, false, false, NULL),
  ('TN|Governor|178867', '20261103TN43440', 'b4667b62-fd9f-4ff5-9e5c-068f85ba6ce2'::uuid,
   'TN Governor',                 'Eddie Lee Murphy',            'Eddie Murphy',            '178867',  'lost',    0.11, false, false, NULL),
  ('TN|Governor|178873', '20261103TN43440', 'b4667b62-fd9f-4ff5-9e5c-068f85ba6ce2'::uuid,
   'TN Governor',                 'Robert Vick',                 'Robert Vick',             '178873',  'lost',    0.11, false, false, NULL),
  ('TN|Governor|178862', '20261103TN43440', 'b4667b62-fd9f-4ff5-9e5c-068f85ba6ce2'::uuid,
   'TN Governor',                 'Misam Abidi',                 'Misam Abidi',             '178862',  'lost',     0.1, false, false, NULL),
  ('TN|Governor|70888', '20261103TN43440', 'b4667b62-fd9f-4ff5-9e5c-068f85ba6ce2'::uuid,
   'TN Governor',                 'Charles Morgan',              'Charles Van Morgan',      '70888',   'lost',    0.06, false, false, NULL),
  ('TN|Governor|178872', '20261103TN43440', 'b4667b62-fd9f-4ff5-9e5c-068f85ba6ce2'::uuid,
   'TN Governor',                 'L. Webb Taylor',              'L. Taylor',               '178872',  'lost',    0.05, false, false, NULL),
  ('TN|Governor|178870', '20261103TN43440', 'b4667b62-fd9f-4ff5-9e5c-068f85ba6ce2'::uuid,
   'TN Governor',                 'Dave Seeman',                 'Dave Seeman',             '178870',  'lost',    0.04, false, false, NULL),
  ('TN|Governor|178869', '20261103TN43440', 'b4667b62-fd9f-4ff5-9e5c-068f85ba6ce2'::uuid,
   'TN Governor',                 'Victor Scoggin',              'Victor Scoggin',          '178869',  'lost',    0.04, false, false, NULL),
  ('TN|Governor|178871', '20261103TN43440', 'b4667b62-fd9f-4ff5-9e5c-068f85ba6ce2'::uuid,
   'TN Governor',                 'Karl Smithson',               'Karl Smithson',           '178871',  'lost',    0.02, false, false, NULL),
  ('VT|Attorney General|149600', '20261103VT46011', '087c3021-ff29-44bf-9f61-b505e2b78297'::uuid,
   'VT Attorney General',         'Charity Clark',               'Charity Clark',           '149600',  'won',    67.72, true , false, '7b2dfaca-3f6e-4d71-893f-28a278049eda'::uuid),
  ('VT|Attorney General|179188', '20261103VT46011', '087c3021-ff29-44bf-9f61-b505e2b78297'::uuid,
   'VT Attorney General',         'Edwin Kemon',                 'Edwin Kemon',             '179188',  'lost',   32.07, false, false, NULL),
  ('VT|Governor|45443', '20261103VT46375', '2abe04f0-ba94-42b9-aa71-1e2dcc4cfce8'::uuid,
   'VT Governor',                 'Phil Scott',                  'Phil Scott',              '45443',   'won',     52.6, true , false, '963f2c91-9563-444e-9487-91822cd3e6cf'::uuid),
  ('VT|Governor|175074', '20261103VT46375', '2abe04f0-ba94-42b9-aa71-1e2dcc4cfce8'::uuid,
   'VT Governor',                 'Amanda Janoo',                'Amanda Janoo',            '175074',  'lost',   45.65, false, false, NULL),
  ('VT|Governor|149767', '20261103VT46375', '2abe04f0-ba94-42b9-aa71-1e2dcc4cfce8'::uuid,
   'VT Governor',                 'Brian Judd',                  'Brian Judd',              '149767',  'lost',    0.84, false, false, NULL),
  ('VT|Governor|167782', '20261103VT46375', '2abe04f0-ba94-42b9-aa71-1e2dcc4cfce8'::uuid,
   'VT Governor',                 'June Goodband',               'June Goodband',           '167782',  'lost',     0.4, false, false, NULL),
  ('VT|Governor|178912', '20261103VT46375', '2abe04f0-ba94-42b9-aa71-1e2dcc4cfce8'::uuid,
   'VT Governor',                 'Dean Roy',                    'Dean Roy',                '178912',  'lost',    0.37, false, false, NULL),
  ('VT|Lieutenant Governor|71177', '20261103VT46376', 'bd0adeb4-6746-418d-abb0-062c99f260c9'::uuid,
   'VT Lieutenant Governor',      'Molly Gray',                  'Molly Gray',              '71177',   'won',    62.72, false, false, NULL),
  ('VT|Lieutenant Governor|147924', '20261103VT46376', 'bd0adeb4-6746-418d-abb0-062c99f260c9'::uuid,
   'VT Lieutenant Governor',      'John Rodgers',                'John Rodgers',            '147924',  'lost',   37.05, true , false, 'aa4040bf-4468-460e-8cb4-5a1e2a53c34f'::uuid),
  ('VT|Secretary of State|148040', '20261103VT46377', 'da8e0d09-2e16-4415-a362-76f22b72e3f1'::uuid,
   'VT Secretary of State',       'Sarah Copeland Hanzas',       'Sarah Copeland Hanzas',   '148040',  'won',    59.18, true , false, 'fc2b0e86-3e94-4e0b-9812-a154065b5bad'::uuid),
  ('VT|Secretary of State|62482', '20261103VT46377', 'da8e0d09-2e16-4415-a362-76f22b72e3f1'::uuid,
   'VT Secretary of State',       'H. Brooke Paige',             'H. Paige',                '62482',   'lost',   32.58, false, false, NULL),
  ('VT|Secretary of State|179189', '20261103VT46377', 'da8e0d09-2e16-4415-a362-76f22b72e3f1'::uuid,
   'VT Secretary of State',       'Rachel Shaw',                 'Rachel Shaw',             '179189',  'lost',    8.13, false, false, NULL),
  ('WY|Governor|153633', '20261103WY51403', '409b15ad-4c4f-44ad-b656-5345b9ed6d8a'::uuid,
   'WY Governor',                 'Eric Barlow',                 'Eric Barlow',             '153633',  'won',    68.57, false, false, NULL),
  ('WY|Governor|179171', '20261103WY51403', '409b15ad-4c4f-44ad-b656-5345b9ed6d8a'::uuid,
   'WY Governor',                 'Rebecca Bextel',              'Rebecca Bextel',          '179171',  'lost',   16.77, false, false, NULL),
  ('WY|Governor|49137', '20261103WY51403', '409b15ad-4c4f-44ad-b656-5345b9ed6d8a'::uuid,
   'WY Governor',                 'Ken Casner',                  'Kenneth Casner',          '49137',   'lost',   14.66, false, false, NULL),
  ('WY|Secretary of State|69218', '20261103WY51404', '130a2bc0-1c93-4424-96e5-949b509d3320'::uuid,
   'WY Secretary of State',       'Robert Short',                'Robert Short',            '69218',   'won',    67.78, false, false, NULL),
  ('WY|Secretary of State|175356', '20261103WY51404', '130a2bc0-1c93-4424-96e5-949b509d3320'::uuid,
   'WY Secretary of State',       'Bryan McCarty',               'Bryan McCarty',           '175356',  'lost',    23.8, false, false, NULL),
  ('WY|Secretary of State|155494', '20261103WY51404', '130a2bc0-1c93-4424-96e5-949b509d3320'::uuid,
   'WY Secretary of State',       'Tamara Trujillo',             'Tamara Trujillo',         '155494',  'lost',    8.41, false, false, NULL);

-- one person per candidacy: either a uuid this file pins, or a row it just seeded. Never both.
CREATE TEMP TABLE pins ON COMMIT DROP AS
SELECT c.*, coalesce(c.pinned_id, s.politician_id) AS pid
  FROM calls c LEFT JOIN seeded s ON s.seed_key = c.seed_key;

DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM pins WHERE pid IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% candidacy(ies) resolve to no person at all', n; END IF;
  SELECT count(*) INTO n FROM calls c JOIN seeded s ON s.seed_key = c.seed_key WHERE c.pinned_id IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% candidacy(ies) are both pinned and seeded', n; END IF;

  -- every pinned uuid must be a real, ACTIVE politician
  SELECT string_agg(p.full_name || ' (' || p.id || ') is archived', '; ') INTO txt
    FROM pins c JOIN essentials.politicians p ON p.id = c.pid WHERE NOT p.is_active;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a candidacy points at an archived person: %', txt; END IF;
  SELECT count(*) INTO n FROM pins c LEFT JOIN essentials.politicians p ON p.id = c.pid WHERE p.id IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% candidacy(ies) point at a politician id that does not exist', n; END IF;

  -- 🔴 A PINNED uuid MUST BE THE PERSON THE FILE NAMES. 69 of the 212 candidacies carry a
  --    hand-chosen politician id, and the INSERT below takes the name FROM THAT ROW — so a
  --    uuid swapped for another real, active person would be written without a murmur, under
  --    the wrong person's name, and every other gate here would still pass. That is exactly
  --    the shape a control on CC_0358 exposed: a file that checks only itself agrees with
  --    itself. The independent fact is that the NAME comes from AP and Ballotpedia and the
  --    ROW comes from the database. They are compared on (first word, last word) because the
  --    two sources legitimately differ on middle names and nicknames — "Andrea Campbell" for
  --    "Andrea Joy Campbell" — but never on both ends at once. Measured: all 69 agree with no
  --    exceptions needed, so this gate carries no allowance list to go stale.
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT c.seat || ': this file names ' || c.who || ' (AP: ' || c.who_ap || ') but the pinned row is ' || p.full_name || ' (' || p.id || ')' AS msg
      FROM calls c JOIN essentials.politicians p ON p.id = c.pinned_id
     WHERE c.pinned_id IS NOT NULL
       AND pg_temp.endsname(p.full_name) NOT IN (pg_temp.endsname(c.who), pg_temp.endsname(c.who_ap))) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a pinned politician is not the person this file names: %', txt; END IF;

  -- 🔴 the winner must be AP's TOP VOTE-GETTER in that race. winner and votePct are
  --    independent fields in the feed, so a transposition breaks their agreement. This is
  --    NOT a 50% test: Tennessee elected a governor on 45.49%. It is valid because AP flags
  --    none of these 73 as ranked-choice and none elects more than one seat.
  SELECT string_agg(a.seat || ': ' || a.who || ' won on ' || a.vote_pct || '% but ' || b.who || ' polled ' || b.vote_pct || '%', '; ') INTO txt
    FROM calls a JOIN calls b ON b.ap_race = a.ap_race AND b.vote_pct > a.vote_pct
   WHERE a.result = 'won';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'the winner is not the top vote-getter: %', txt; END IF;

  -- exactly one winner per race, and 73 in all
  SELECT count(*) INTO n FROM (
    SELECT ap_race FROM calls GROUP BY ap_race HAVING count(*) FILTER (WHERE result = 'won') <> 1) z;
  IF n <> 0 THEN RAISE EXCEPTION '% race(s) in this file do not hold exactly one winner', n; END IF;
  SELECT count(*) INTO n FROM calls WHERE result = 'won';
  IF n <> 73 THEN RAISE EXCEPTION 'expected 73 winners, found %', n; END IF;
  SELECT count(*) INTO n FROM calls WHERE result NOT IN ('won','lost');
  IF n <> 0 THEN RAISE EXCEPTION '% candidacy(ies) carry a result other than won or lost', n; END IF;

  -- 🔴 INCUMBENCY IS CROSS-CHECKED AGAINST WHO ACTUALLY HOLDS THE SEAT, BY ID, IN BOTH
  --    DIRECTIONS. essentials.office_current_holder is a fact this file does not supply, so
  --    it can disagree with it; the file's own table cannot.
  SELECT string_agg(msg, '; ') INTO txt FROM (
    SELECT c.seat || ': this file marks ' || c.who || ' incumbent, but the seat is held by ' || coalesce(h.full_name, '(nobody)') AS msg
      FROM pins c
      LEFT JOIN essentials.office_current_holder och ON och.office_id = c.office_id
      LEFT JOIN essentials.politicians h ON h.id = och.politician_id
     WHERE c.is_inc AND och.politician_id IS DISTINCT FROM c.pid
    UNION ALL
    SELECT c.seat || ': ' || c.who || ' holds this seat and is not marked incumbent'
      FROM pins c
      JOIN essentials.office_current_holder och ON och.office_id = c.office_id AND och.politician_id = c.pid
     WHERE NOT c.is_inc) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'incumbency disagrees with the current officeholder: %', txt; END IF;
END $$;

-- full_name is NOT NULL on race_candidates and the table carries its own name split, so both
-- are taken FROM THE POLITICIAN ROW rather than retyped — they cannot drift apart. external_id
-- stays NULL, matching every other state-executive candidacy in this election; AP's candidate
-- id lives in this file and in the saved feed, not in a column where a collision could later
-- seat the wrong person.
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status,
   is_write_in, source, result, result_certainty, result_source, result_recorded_at)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name, c.is_inc, 'active',
       c.is_write_in, 'https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/progress.json (AP call, fetched 2026-11-05; CC_0359)', c.result, 'called', 'https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/progress.json (AP call, fetched 2026-11-05; CC_0359)', now()
  FROM pins c
  JOIN essentials.races r ON r.office_id = c.office_id
  JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
  JOIN essentials.politicians p ON p.id = c.pid
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
                    WHERE rc.race_id = r.id AND rc.politician_id = p.id);

-- ─── Post-verify ───
DO $$
DECLARE n int; txt text;
BEGIN
  SELECT count(*) INTO n FROM new_races nr
    JOIN essentials.races r ON r.office_id = nr.office_id
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03';
  IF n <> 73 THEN RAISE EXCEPTION 'expected 73 new races, found %', n; END IF;

  -- every pinned call landed on the right person, with its result, citation and a measured stamp
  SELECT count(*) INTO n
    FROM pins c
    JOIN essentials.races r ON r.office_id = c.office_id
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = c.pid
   WHERE rc.result = c.result AND rc.result_certainty = 'called'
     AND rc.result_source = 'https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/progress.json (AP call, fetched 2026-11-05; CC_0359)'
     AND rc.result_recorded_at >= TIMESTAMPTZ '2026-11-04'
     AND rc.is_incumbent = c.is_inc AND rc.is_write_in = c.is_write_in;
  IF n <> 212 THEN RAISE EXCEPTION 'only % of the 212 candidacies hold their stated result', n; END IF;

  -- each new race: exactly one winner, nobody undecided
  SELECT count(*) INTO n FROM (
    SELECT r.id FROM new_races nr
      JOIN essentials.races r ON r.office_id = nr.office_id
      JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
      JOIN essentials.race_candidates rc ON rc.race_id = r.id
     GROUP BY r.id
    HAVING count(*) FILTER (WHERE rc.result = 'won') <> 1 OR count(*) FILTER (WHERE rc.result IS NULL) <> 0) z;
  IF n <> 0 THEN RAISE EXCEPTION '% new race(s) lack exactly one winner or hold an undecided row', n; END IF;

  -- the 143 seeded people exist exactly once under this file's source, active, non-incumbent
  SELECT string_agg(s.full_name || ' x' || (SELECT count(*) FROM essentials.politicians p WHERE p.full_name = s.full_name AND p.source = s.source), '; ') INTO txt
    FROM seed_people s
   WHERE (SELECT count(*) FROM essentials.politicians p WHERE p.full_name = s.full_name AND p.source = s.source) <> 1;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded person is not present exactly once: %', txt; END IF;
  SELECT count(*) INTO n FROM seeded sd JOIN essentials.politicians p ON p.id = sd.politician_id
   WHERE p.is_active AND NOT p.is_incumbent;
  IF n <> 143 THEN RAISE EXCEPTION 'only % of the 143 seeded people read active and non-incumbent', n; END IF;

  -- nothing claims to be certified
  SELECT count(*) INTO n FROM pins c
    JOIN essentials.races r ON r.office_id = c.office_id
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = c.pid
   WHERE rc.result_certainty <> 'called';
  IF n <> 0 THEN RAISE EXCEPTION '% row(s) do not read called', n; END IF;

  -- 🔴 AND THE TIER TOTAL, MEASURED THE WAY THE GAP SCRIPT MEASURES IT. 21 before this file
  --    (18 from CC_0357, 3 from CC_0358) plus 73 here.
  SELECT count(*) INTO n FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = DATE '2026-11-03' AND d.district_type = 'STATE_EXEC' AND rc.result = 'won';
  IF n <> 94 THEN RAISE EXCEPTION 'expected 94 state-executive winners nationally (21 + 73 here), found %', n; END IF;

  RAISE NOTICE 'CC_0359 OK — 73 races, 212 candidacies (73 won, 139 lost), 143 people seeded, across 30 states.';
END $$;

COMMIT;
