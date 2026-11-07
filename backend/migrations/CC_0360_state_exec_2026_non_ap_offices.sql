-- CC_0360 — 2026-11-03 state executives BEYOND AP'S FOUR OFFICES: create the 31 races
--           Ballotpedia has called on seats we hold but had no race row for, seed the 47
--           candidates we hold no row for, and record the results.
--
-- WHY THIS FILE EXISTS. CC_0359 closed the gap against AP and that gap reached zero — but
--   🔴 AP PUBLISHES ONLY FOUR STATE-EXECUTIVE OFFICES. Measured from its own feed on
--   2026-11-06, every officeName it carries for this election is: U.S. House, Governor,
--   U.S. Senate, Attorney General, Secretary of State, Lieutenant Governor, Mayor,
--   U.S. Delegate, Railroad Commissioner, and ballot measures. NOT ONE treasurer,
--   comptroller, controller, auditor, superintendent, chief financial officer, land or
--   agriculture commissioner. Those seats were on the ballot and no AP race exists for them,
--   so "the AP gap is zero" never meant the tier was recorded.
--
-- 🔴 AND A THIRD KIND OF GAP, WHICH NEITHER SIDE'S LIST CAN SHOW: A RACE THE SOURCE ITSELF
--   DOES NOT CARRY. AP publishes a Lieutenant Governor race in ten states and none in the
--   six where the office runs on the governor's TICKET — CT, HI, MA, NM, PA, WI. Those six
--   are invisible to an AP-side reconciliation because AP has no row to reconcile. Five of
--   them are created here; Wisconsin's race already exists and is CC_0361's.
--
-- WHAT IT WRITES — nothing is updated or deleted; every statement is an INSERT:
--   47 politicians · 31 races · 72 candidacies (31 won, 41 lost) across 23 states
--
--   AL  Treasurer                            3 cand  🏆 Young Boozer (R)
--   AR  Treasurer                            1 cand  🏆 John Thurston (R)
--   CT  Lieutenant Governor                  3 cand  🏆 Susan Bysiewicz (D / Working Families Party)   [TICKET — see below]
--   CT  Treasurer                            2 cand  🏆 Erick Russell (D / Working Families Party)
--   DE  Treasurer                            2 cand  🏆 Ted Lauzen (D)
--   FL  Chief Financial Officer              2 cand  🏆 Blaise Ingoglia (R)
--   HI  Lieutenant Governor                  2 cand  🏆 Derek Kawakami (D)   [TICKET — see below]
--   ID  State Controller                     2 cand  🏆 Brandon Woolf (R)
--   ID  Superintendent of Public Instruction 3 cand  🏆 Debbie Critchfield (R)
--   ID  Treasurer                            2 cand  🏆 Julie Ellsworth (R)
--   IL  Treasurer                            3 cand  🏆 Mike Frerichs (D)
--   IA  Treasurer                            2 cand  🏆 Roby Smith (R)
--   KS  Treasurer                            3 cand  🏆 Steven C. Johnson (R)
--   MD  Comptroller                          2 cand  🏆 Brooke Elizabeth Lierman (D)
--   MA  Lieutenant Governor                  3 cand  🏆 Kim Driscoll (D)   [TICKET — see below]
--   MA  Auditor of the Commonwealth          2 cand  🏆 Diana DiZoglio (D)
--   MA  Treasurer and Receiver-General       2 cand  🏆 Deb Goldberg (D)
--   NE  Treasurer                            2 cand  🏆 Joey Spellerberg (R)
--   NM  Lieutenant Governor                  2 cand  🏆 Stephanie Garcia Richard (D)   [TICKET — see below]
--   NM  Treasurer                            2 cand  🏆 Laura Montoya (D)
--   NY  Comptroller                          2 cand  🏆 Thomas P. DiNapoli (D / Working Families Party)
--   OK  Treasurer                            2 cand  🏆 Cindy Byrd (R)
--   PA  Lieutenant Governor                  3 cand  🏆 Austin Davis (D)   [TICKET — see below]
--   RI  Treasurer                            2 cand  🏆 James Diossa (D)
--   SC  Treasurer                            2 cand  🏆 Curtis Loftis (R)
--   SD  Treasurer                            2 cand  🏆 Melissa Hull (R)
--   TX  Texas Agriculture Commissioner       3 cand  🏆 Clayton Tucker (D)
--   TX  Texas Comptroller                    4 cand  🏆 Sarah Eckhardt (D)
--   TX  Texas Land Commissioner              3 cand  🏆 Benjamin Flores (D)
--   VT  Treasurer                            3 cand  🏆 Michael Pieciak (D)
--   WY  Treasurer                            1 cand  🏆 Curt Meier (R)
--
-- 🔴🔴 THE SOURCING STANDARD CHANGES HERE, AND THE CHANGE IS THE RISK.
--   CC_0358 and CC_0359 used Ballotpedia for IDENTITY ONLY and took every number and the
--   winner from AP. There is no AP race for these offices, so Ballotpedia has to carry the
--   outcome too. That was not assumed — it was tested, and the test says take the flag and
--   refuse the numbers:
--
--   ⚠ ITS COUNTS HAVE NOT SETTLED. Measured 2026-11-06 against AP's authoritative totals on the
--     71 races where both name a winner: only 45 (63%) are within 0.5% of AP. Maine's
--     governor still reads 261,518 against AP's 382,760 — 68% of the real figure — and
--     UNCHANGED from the day before. Only 3 of 70 counts moved in 24 hours, so these tables
--     are not converging; many are simply frozen part-counted.
--   🟢 ITS WINNER FLAG IS A CALL, NOT A LEADER. On those same 71 races the flag agreed with
--     AP's call 71 times out of 71 — while the counts beneath it were up to 32% short. The
--     two are independent. And it WITHHOLDS the flag: Kansas's governor's race shows
--     Cindy Holscher ahead 50.3-49.7 on 1.09m votes on its own page and carries NO winner,
--     exactly where AP has also not called. A leader-takes-the-tick system would have ticked her.
--   ▶ SO: THE WINNER FLAG IS USED AND NO NUMBER IS. No vote count or percentage is written
--     to any column by this file, and none is quoted in this header as fact.
--   ⚠ This is still ONE source where CC_0359 had two. result_certainty is 'called' and
--     result_source names Ballotpedia and the date, so the record says exactly that.
--
-- 🟢 THE PAGE STATES EACH OUTCOME TWICE AND BOTH WERE CHECKED. A CSS class on a table row
--   (tr.results_row.winner) and an editor's sentence ("X defeated Y..."). They are produced
--   separately, so one can be wrong while the other is right. All 44 races in this pass and
--   CC_0361 agree on both. It is not a second source; it is what this source makes available.
--
-- 🔴🔴 IN A TICKET STATE THE LIEUTENANT GOVERNOR'S TABLE ROW NAMES THE GOVERNOR.
--   Ballotpedia renders the LG contest as the gubernatorial ticket: Wisconsin's winning row
--   reads "David Crowley / Sarah Godlewski" with the tick on CROWLEY, who was running for
--   GOVERNOR. Reading the row would have seated six governors in six lieutenant governors'
--   chairs — Ned Lamont, Joshua Green, Maura Healey, Debra Haaland, Josh Shapiro and David
--   Crowley — and every one of them would have looked right.
--   ▶ THE NARRATIVE IS AUTHORITATIVE FOR A TICKET RACE AND THE ROW IS THE TICKET HEAD. The
--     candidate taken is the RUNNING MATE, and this file was built only after the sentence
--     was confirmed to lead with that same running mate in all 5 ticket races:
--       CT Lieutenant Governor: Incumbent Susan Bysiewicz (D / Working Families Party) defeated Matthew Corey (R / Independent Party of Connecticut), 
--       HI Lieutenant Governor: Derek Kawakami (D) defeated Daniel Anthony (R) in the general election for Lieutenant Governor of Hawaii on November 3
--       MA Lieutenant Governor: Incumbent Kim Driscoll (D) defeated Shawn Oliver (R) (Withdrew, still on ballot) and Kayla Kittredge (Unenrolled) in t
--       NM Lieutenant Governor: Stephanie Garcia Richard (D) defeated David M. Gallegos (R) in the general election for Lieutenant Governor of New Mex
--       PA Lieutenant Governor: Incumbent Austin Davis (D) defeated Jason Richey (R) and John Thomas (L) in the general election for Lieutenant Govern
--
-- ⚠ AND A TICKET ROW CARRIES TWO LINKS. The first is the governor's article, the second the
--   running mate's — so the obvious "first href" gives one person's page to another. Worse,
--   for David M. Gallegos (NM) and John Thomas (PA) that second link is an ANCHOR INTO THE
--   GOVERNOR CANDIDATE'S page (#Campaign_themes): they have no article of their own. Citing
--   it would be a fabricated citation in the one field that carries provenance. A slug check
--   caught both, and those two cite the state page, which does name them.
--
-- 🔴 NO AP SURNAME FIELD EXISTS HERE, so nothing outside the name says where the surname
--   starts. 44 of the 47 seeds are two words and have one possible split; three were read off
--   their own articles: "Stephanie Garcia Richard" (the surname is the pair, not "Richard"),
--   "David M. Gallegos", "V. Alonzo Echavarria-Garza". A last-token rule gets the first wrong.
--
-- 🔴 A NAME MATCH IS A HYPOTHESIS. 22 of the 25 matches to existing people are anchored
--   on office_current_holder naming that person for that exact seat — mostly treasurers and
--   auditors re-elected. The other three were read against what that person already holds:
--     · Sarah Eckhardt holds a TEXAS state senate seat and won the Texas comptrollership.
--     · Sonya Dunn is sourced from votesonyadunn.com, whose own title reads
--       "Vote Sonya Dunn - Comptroller for Maryland".
--     · Shawn Oliver holds a Massachusetts city council seat; his Ballotpedia article reads
--       "ran for election for Lieutenant Governor of Massachusetts" and "born in New Bedford,
--       Massachusetts". ⚠ He WITHDREW and stayed on the ballot, so his candidate_status is
--       'withdrawn' while his result is 'lost' — he was on it and votes were cast.
--
-- ⚠ WHAT THIS DOES NOT COVER, named so the tier is not read as finished: Ballotpedia carries
--   265 general-election state-executive voteboxes and 119 of them match no seat we hold —
--   state boards of education, public service and utility commissions, university regents,
--   Massachusetts's Governor's Council, New Hampshire's Executive Council, the Office of
--   Hawaiian Affairs, and single seats such as Alabama's Auditor and Connecticut's
--   Comptroller. Creating those is an office-and-occupancy act, not a results migration.
--   ⚠ Seven states have no Ballotpedia page at all (KY MS NJ NC VA WA WV) and hold no
--     2026-11-03 state-executive race row on our side either — consistent, not proven.
--
-- A CALL IS NOT A CANVASS: result_certainty is 'called' on all 72.
-- Applied to production 2026-11-06 by Chris Cantrell. Slot reserved via steward.

BEGIN;

-- ─── 1. The people we hold no row for ───
CREATE TEMP TABLE seed_people (
  seed_key text PRIMARY KEY, full_name text NOT NULL, first_name text NOT NULL, last_name text NOT NULL, source text NOT NULL
) ON COMMIT DROP;
INSERT INTO seed_people (seed_key, full_name, first_name, last_name, source) VALUES
  ('AL|Treasurer|Rosilyn Houston', 'Rosilyn Houston', 'Rosilyn', 'Houston',
   'https://ballotpedia.org/Rosilyn_Houston (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('AL|Treasurer|David Field', 'David Field', 'David', 'Field',
   'https://ballotpedia.org/David_Field (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('CT|Lieutenant Governor|Rick Adgers', 'Rick Adgers', 'Rick', 'Adgers',
   'https://ballotpedia.org/Rick_Adgers (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('CT|Lieutenant Governor|Michael Grant', 'Michael Grant', 'Michael', 'Grant',
   'https://ballotpedia.org/Michael_Grant_(Connecticut_gubernatorial_candidate) (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('CT|Treasurer|Fred Wilms', 'Fred Wilms', 'Fred', 'Wilms',
   'https://ballotpedia.org/Fred_Wilms (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('DE|Treasurer|Ted Lauzen', 'Ted Lauzen', 'Ted', 'Lauzen',
   'https://ballotpedia.org/Ted_Lauzen (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('DE|Treasurer|Michael Ramone', 'Michael Ramone', 'Michael', 'Ramone',
   'https://ballotpedia.org/Michael_Ramone (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('FL|Chief Financial Officer|Annette Taddeo', 'Annette Taddeo', 'Annette', 'Taddeo',
   'https://ballotpedia.org/Annette_Taddeo (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('HI|Lieutenant Governor|Derek Kawakami', 'Derek Kawakami', 'Derek', 'Kawakami',
   'https://ballotpedia.org/Derek_Kawakami (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('HI|Lieutenant Governor|Daniel Anthony', 'Daniel Anthony', 'Daniel', 'Anthony',
   'https://ballotpedia.org/Daniel_Anthony_(Hawaii) (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('ID|State Controller|Rakesh Mohan', 'Rakesh Mohan', 'Rakesh', 'Mohan',
   'https://ballotpedia.org/Rakesh_Mohan (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('ID|Superintendent of Public Instruction|Becky Mitchell', 'Becky Mitchell', 'Becky', 'Mitchell',
   'https://ballotpedia.org/Becky_Mitchell_(Idaho) (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('ID|Superintendent of Public Instruction|Teresa Roundy', 'Teresa Roundy', 'Teresa', 'Roundy',
   'https://ballotpedia.org/Teresa_Roundy (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('ID|Treasurer|Kevin Jones', 'Kevin Jones', 'Kevin', 'Jones',
   'https://ballotpedia.org/Kevin_Jones_(Idaho) (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('IL|Treasurer|Max Solomon', 'Max Solomon', 'Max', 'Solomon',
   'https://ballotpedia.org/Max_Solomon (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('IL|Treasurer|Timothea Papas', 'Timothea Papas', 'Timothea', 'Papas',
   'https://ballotpedia.org/Timothea_Papas (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('IA|Treasurer|John Norwood', 'John Norwood', 'John', 'Norwood',
   'https://ballotpedia.org/John_Norwood (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('KS|Treasurer|Juan Luengo', 'Juan Luengo', 'Juan', 'Luengo',
   'https://ballotpedia.org/Juan_Luengo (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('KS|Treasurer|Eric Lund', 'Eric Lund', 'Eric', 'Lund',
   'https://ballotpedia.org/Eric_Lund_(Kansas) (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('MA|Lieutenant Governor|Kayla Kittredge', 'Kayla Kittredge', 'Kayla', 'Kittredge',
   'https://ballotpedia.org/Kayla_Kittredge (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('MA|Auditor of the Commonwealth|Al Ozonoff', 'Al Ozonoff', 'Al', 'Ozonoff',
   'https://ballotpedia.org/Al_Ozonoff (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('MA|Treasurer and Receiver-General|Deb Goldberg', 'Deb Goldberg', 'Deb', 'Goldberg',
   'https://ballotpedia.org/Deb_Goldberg (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('MA|Treasurer and Receiver-General|Elizabeth Dionne', 'Elizabeth Dionne', 'Elizabeth', 'Dionne',
   'https://ballotpedia.org/Elizabeth_Dionne (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('NE|Treasurer|Daniel Ebers', 'Daniel Ebers', 'Daniel', 'Ebers',
   'https://ballotpedia.org/Daniel_Ebers (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('NM|Lieutenant Governor|Stephanie Garcia Richard', 'Stephanie Garcia Richard', 'Stephanie', 'Garcia Richard',
   'https://ballotpedia.org/Stephanie_Garcia_Richard (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('NM|Lieutenant Governor|David M. Gallegos', 'David M. Gallegos', 'David M.', 'Gallegos',
   'https://ballotpedia.org/New_Mexico_state_executive_official_elections,_2026 (Ballotpedia, read 2026-11-06 — this person has no article of their own; the state page''s Lieutenant Governor table names them); outcome from the same page''s winner flag (CC_0360)'),
  ('NM|Treasurer|James Ellison', 'James Ellison', 'James', 'Ellison',
   'https://ballotpedia.org/James_Ellison_(New_Mexico) (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('NY|Comptroller|Joseph Hernandez', 'Joseph Hernandez', 'Joseph', 'Hernandez',
   'https://ballotpedia.org/Joseph_Hernandez_(New_York) (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('OK|Treasurer|Cindy Byrd', 'Cindy Byrd', 'Cindy', 'Byrd',
   'https://ballotpedia.org/Cindy_Byrd (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('OK|Treasurer|Kiefer Perry', 'Kiefer Perry', 'Kiefer', 'Perry',
   'https://ballotpedia.org/Kiefer_Perry (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('PA|Lieutenant Governor|Jason Richey', 'Jason Richey', 'Jason', 'Richey',
   'https://ballotpedia.org/Jason_Richey_(Pennsylvania) (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('PA|Lieutenant Governor|John Thomas', 'John Thomas', 'John', 'Thomas',
   'https://ballotpedia.org/Pennsylvania_state_executive_official_elections,_2026 (Ballotpedia, read 2026-11-06 — this person has no article of their own; the state page''s Lieutenant Governor table names them); outcome from the same page''s winner flag (CC_0360)'),
  ('RI|Treasurer|Micholas Credle', 'Micholas Credle', 'Micholas', 'Credle',
   'https://ballotpedia.org/Micholas_Credle (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('SC|Treasurer|Vincent Coe', 'Vincent Coe', 'Vincent', 'Coe',
   'https://ballotpedia.org/Vincent_Coe (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('SD|Treasurer|Melissa Hull', 'Melissa Hull', 'Melissa', 'Hull',
   'https://ballotpedia.org/Melissa_Hull (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('SD|Treasurer|Margaret Kuipers', 'Margaret Kuipers', 'Margaret', 'Kuipers',
   'https://ballotpedia.org/Margaret_Kuipers (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('TX|Texas Agriculture Commissioner|Clayton Tucker', 'Clayton Tucker', 'Clayton', 'Tucker',
   'https://ballotpedia.org/Clayton_Tucker (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('TX|Texas Agriculture Commissioner|Nate Sheets', 'Nate Sheets', 'Nate', 'Sheets',
   'https://ballotpedia.org/Nate_Sheets (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('TX|Texas Agriculture Commissioner|Austin Kelly', 'Austin Kelly', 'Austin', 'Kelly',
   'https://ballotpedia.org/Austin_Kelly (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('TX|Texas Comptroller|Donald Huffines', 'Donald Huffines', 'Donald', 'Huffines',
   'https://ballotpedia.org/Donald_Huffines (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('TX|Texas Comptroller|V. Alonzo Echavarria-Garza', 'V. Alonzo Echavarria-Garza', 'V. Alonzo', 'Echavarria-Garza',
   'https://ballotpedia.org/V._Alonzo_Echavarria-Garza (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('TX|Texas Comptroller|Shehla Faizi', 'Shehla Faizi', 'Shehla', 'Faizi',
   'https://ballotpedia.org/Shehla_Faizi (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('TX|Texas Land Commissioner|Benjamin Flores', 'Benjamin Flores', 'Benjamin', 'Flores',
   'https://ballotpedia.org/Benjamin_Flores (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('TX|Texas Land Commissioner|Neil Snider', 'Neil Snider', 'Neil', 'Snider',
   'https://ballotpedia.org/Neil_Snider_(Texas) (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('VT|Treasurer|Michael Pieciak', 'Michael Pieciak', 'Michael', 'Pieciak',
   'https://ballotpedia.org/Michael_Pieciak (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('VT|Treasurer|Lynn LaFleur', 'Lynn LaFleur', 'Lynn', 'LaFleur',
   'https://ballotpedia.org/Lynn_LaFleur (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)'),
  ('VT|Treasurer|Zachary Hampl', 'Zachary Hampl', 'Zachary', 'Hampl',
   'https://ballotpedia.org/Zachary_Hampl (Ballotpedia, read 2026-11-06); outcome from the same page''s winner flag (CC_0360)');

CREATE OR REPLACE FUNCTION pg_temp.namekey(t text) RETURNS text IMMUTABLE LANGUAGE sql AS $f$
  SELECT lower(translate(coalesce(t, ''), 'ÁÀÂÄÃÅáàâäãåÉÈÊËéèêëÍÌÎÏíìîïÓÒÔÖÕóòôöõÚÙÛÜúùûüÑñÇç',
                                          'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuNnCc'))
$f$;

-- the big side is normalised ONCE into an indexed temp table. Calling the function on both
-- sides of the join defeats every index and timed out when CC_0359 first tried it.
CREATE TEMP TABLE pol_keys ON COMMIT DROP AS
SELECT id, full_name, first_name, last_name, is_active, source,
       pg_temp.namekey(full_name) AS k_full, pg_temp.namekey(first_name) AS k_first, pg_temp.namekey(last_name) AS k_last
  FROM essentials.politicians;
CREATE INDEX ON pol_keys (k_full);
CREATE INDEX ON pol_keys (k_first, k_last);
ANALYZE pol_keys;

DO $$
DECLARE txt text; n int;
BEGIN
  -- a positive control before any check is allowed to trust its own silence
  SELECT count(*) INTO n FROM pol_keys WHERE k_full = pg_temp.namekey('Doug Jones');
  IF n < 1 THEN RAISE EXCEPTION 'the name index cannot see a politician known to exist — the guard below would pass vacuously'; END IF;
  SELECT count(*) INTO n FROM pol_keys;
  IF n < 50000 THEN RAISE EXCEPTION 'the name index holds only % rows — it did not load the table', n; END IF;

  -- 🔴 BOTH collision keys, across the whole table, archived rows included. No allowance
  --    list this time: measured before writing, not one of these names collides with anything.
  SELECT string_agg(z.msg, '; ') INTO txt FROM (
    SELECT s.full_name || ' already exists as ' || p.full_name || ' (' || p.id || ', active=' || p.is_active || ')' AS msg
      FROM seed_people s JOIN pol_keys p ON p.k_full = pg_temp.namekey(s.full_name)
     WHERE p.source IS DISTINCT FROM s.source
    UNION
    SELECT s.full_name || ' splits to the same (first, last) as ' || p.full_name || ' (' || p.id || ')'
      FROM seed_people s JOIN pol_keys p ON p.k_first = pg_temp.namekey(s.first_name) AND p.k_last = pg_temp.namekey(s.last_name)
     WHERE p.source IS DISTINCT FROM s.source) z;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a person this file seeds already exists: %', txt; END IF;

  -- 🔴 THE SPLIT MUST RECONSTRUCT THE NAME EXACTLY. A control proved the obvious weaker form
  --    ("ends with the surname") useless on a hyphenated name: corrupting Echavarria-Garza to
  --    "Garza" PASSED, because the full name does end in "Garza". Equality has no such hole,
  --    and all 47 satisfy it — a middle name would need its own column, not a loose match.
  SELECT string_agg(s.full_name || ' splits to (' || s.first_name || ', ' || s.last_name || ')', '; ') INTO txt
    FROM seed_people s
   WHERE s.full_name <> s.first_name || ' ' || s.last_name;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded name does not match its own split: %', txt; END IF;

  -- 🔴 every source must be a Ballotpedia URL and must not be an anchor into someone else
  SELECT string_agg(s.full_name || ' -> ' || s.source, '; ') INTO txt FROM seed_people s
   WHERE s.source NOT LIKE 'https://ballotpedia.org/%' OR s.source LIKE '%#%';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a seeded source is not a plain Ballotpedia page: %', txt; END IF;
END $$;

INSERT INTO essentials.politicians (full_name, first_name, last_name, source, is_active, is_incumbent)
SELECT s.full_name, s.first_name, s.last_name, s.source, true, false
  FROM seed_people s
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.full_name = s.full_name AND p.source = s.source);

CREATE TEMP TABLE seeded (seed_key text PRIMARY KEY, politician_id uuid NOT NULL) ON COMMIT DROP;
INSERT INTO seeded (seed_key, politician_id)
SELECT s.seed_key, p.id FROM seed_people s
  JOIN essentials.politicians p ON p.full_name = s.full_name AND p.source = s.source;
DO $$ DECLARE n int; BEGIN
  SELECT count(*) INTO n FROM seeded;
  IF n <> 47 THEN RAISE EXCEPTION 'only % of the 47 seeded people resolved to exactly one row', n; END IF;
END $$;

-- ─── 2. The races ───
CREATE TEMP TABLE new_races (
  rkey text PRIMARY KEY, st text NOT NULL, office_id uuid NOT NULL, election_id uuid NOT NULL, position_name text NOT NULL
) ON COMMIT DROP;
INSERT INTO new_races (rkey, st, office_id, election_id, position_name) VALUES
  ('AL|Treasurer', 'AL', '86ab166c-dfd2-493e-a5d2-d3ba1342fda3'::uuid, '4dc3b465-4921-410c-a3b1-b05bac5004e7'::uuid, 'Treasurer'),
  ('AR|Treasurer', 'AR', 'b03f877e-9729-4cf1-b607-164f75bd08eb'::uuid, 'b333dbd5-2b94-4dc7-8929-9743dc237191'::uuid, 'Treasurer'),
  ('CT|Lieutenant Governor', 'CT', 'fc973a1c-be0b-4d96-b1d6-09c2122b1ff8'::uuid, 'e7630bb9-d60d-4ffe-905d-d171f84e9cb7'::uuid, 'Lieutenant Governor'),
  ('CT|Treasurer', 'CT', '93adf9fb-8676-4b3d-b736-c8328d190794'::uuid, 'e7630bb9-d60d-4ffe-905d-d171f84e9cb7'::uuid, 'Treasurer'),
  ('DE|Treasurer', 'DE', '29461e2c-f020-4272-bf74-b8da68b51a95'::uuid, '00653817-6888-4074-8342-057be2ceced9'::uuid, 'Treasurer'),
  ('FL|Chief Financial Officer', 'FL', '3e261b17-6b04-49a2-af95-55174347e19c'::uuid, '1c868ba1-3169-4f0a-84a2-f41b349ef313'::uuid, 'Chief Financial Officer'),
  ('HI|Lieutenant Governor', 'HI', 'f7daf624-4e61-4e72-81f3-408c97a9ab2a'::uuid, 'e6326a3d-bcf5-45c5-8afb-64999d993fa0'::uuid, 'Lieutenant Governor'),
  ('ID|State Controller', 'ID', 'f0d34cb8-9fe9-4be7-94b0-179ecf52afad'::uuid, '823b82b9-55bd-4d00-8bba-3311e3e78ef2'::uuid, 'State Controller'),
  ('ID|Superintendent of Public Instruction', 'ID', 'c5c22d9f-f47b-42b9-87e8-85183c6b3b5f'::uuid, '823b82b9-55bd-4d00-8bba-3311e3e78ef2'::uuid, 'Superintendent of Public Instruction'),
  ('ID|Treasurer', 'ID', '29b22a69-1c0b-4033-87e9-ead7b17b6059'::uuid, '823b82b9-55bd-4d00-8bba-3311e3e78ef2'::uuid, 'Treasurer'),
  ('IL|Treasurer', 'IL', 'a6350acc-729d-4d62-ba15-4538422631b2'::uuid, '804d07cf-11c9-4e3d-a85d-9ff8cbffb828'::uuid, 'Treasurer'),
  ('IA|Treasurer', 'IA', '2b425609-2b7d-4974-a6d3-38a59df54d38'::uuid, 'ed7eb7da-8e46-4d25-a97a-f3168bd0fbf6'::uuid, 'Treasurer'),
  ('KS|Treasurer', 'KS', '20182ca9-eb4c-4aa0-8494-0f613710c88b'::uuid, '5aec8ba8-8f04-4368-9529-130ea489a4d3'::uuid, 'Treasurer'),
  ('MD|Comptroller', 'MD', '816a9ad0-f2ac-48b3-918a-aa75aa2f9efd'::uuid, 'd3d8376e-0688-42e5-a7fe-fd11e7d225ef'::uuid, 'Comptroller'),
  ('MA|Lieutenant Governor', 'MA', '66c34aa8-db37-4aed-a369-fa5729f62b4a'::uuid, '38121465-a14b-4044-bc21-1a4c968ae4fd'::uuid, 'Lieutenant Governor'),
  ('MA|Auditor of the Commonwealth', 'MA', '58d289a0-a95e-474f-9c6e-b50fc7e93b04'::uuid, '38121465-a14b-4044-bc21-1a4c968ae4fd'::uuid, 'Auditor of the Commonwealth'),
  ('MA|Treasurer and Receiver-General', 'MA', '3367d772-6a6b-4c51-9a74-c294ed1dbfdc'::uuid, '38121465-a14b-4044-bc21-1a4c968ae4fd'::uuid, 'Treasurer and Receiver-General'),
  ('NE|Treasurer', 'NE', '4434a6ba-49dd-4564-9944-d324dc185be8'::uuid, '1224487f-4f73-4048-b553-5629ee19b512'::uuid, 'Treasurer'),
  ('NM|Lieutenant Governor', 'NM', '717136ab-07aa-48d4-b4fe-38ad94370b8d'::uuid, '6a560b73-4059-406c-b96a-6fe27073ecc9'::uuid, 'Lieutenant Governor'),
  ('NM|Treasurer', 'NM', '2bc67444-6fa2-4a8a-b029-c01d18a00692'::uuid, '6a560b73-4059-406c-b96a-6fe27073ecc9'::uuid, 'Treasurer'),
  ('NY|Comptroller', 'NY', '6593095f-6628-451e-97a2-5bf3efcd6a26'::uuid, '80a2b03d-f583-4156-a272-d51abbda0b0a'::uuid, 'Comptroller'),
  ('OK|Treasurer', 'OK', '2145be7d-ebf2-468a-b950-4aae7d6677d1'::uuid, '5afd2125-3d75-4c6e-bcb0-9d3aaa296590'::uuid, 'Treasurer'),
  ('PA|Lieutenant Governor', 'PA', '1d40031c-6521-40b7-bd44-1af0da2951b2'::uuid, 'ed54a0a5-4204-462b-9f3e-c3debed12501'::uuid, 'Lieutenant Governor'),
  ('RI|Treasurer', 'RI', 'b4ffba0d-e20a-4367-8b88-222c0e8496a4'::uuid, '1fb22c90-15f9-45ea-9988-881bae728b1d'::uuid, 'Treasurer'),
  ('SC|Treasurer', 'SC', '8a6811c6-3253-4ae7-993a-13e19b5f1cb9'::uuid, 'e9a9063d-7a17-43de-9ac4-012a50166b64'::uuid, 'Treasurer'),
  ('SD|Treasurer', 'SD', 'f7b99f3b-fbea-43fb-8d63-3f99e80a1638'::uuid, 'ac7ebe0d-b300-43ed-b107-d919822502df'::uuid, 'Treasurer'),
  ('TX|Texas Agriculture Commissioner', 'TX', '5e752883-f21c-4abf-9de8-80b5d1247929'::uuid, '783b7506-dd52-47a1-a85a-9ffc363f8a04'::uuid, 'Texas Agriculture Commissioner'),
  ('TX|Texas Comptroller', 'TX', 'd50da2bc-0e8f-4d70-ba6c-d0dfcd0613b2'::uuid, '783b7506-dd52-47a1-a85a-9ffc363f8a04'::uuid, 'Texas Comptroller'),
  ('TX|Texas Land Commissioner', 'TX', '0bf99572-2eee-4183-97bf-721501889dbc'::uuid, '783b7506-dd52-47a1-a85a-9ffc363f8a04'::uuid, 'Texas Land Commissioner'),
  ('VT|Treasurer', 'VT', '0317b579-578e-4e5a-8ab0-010be70979f2'::uuid, 'a4ed60a8-fdfc-4093-93e3-44799d43f86b'::uuid, 'Treasurer'),
  ('WY|Treasurer', 'WY', '6ec2bf63-5da2-460b-b216-633e3a92c913'::uuid, '28ce873c-af6e-4802-9315-b47a5e0cdd9a'::uuid, 'Treasurer');

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM new_races nr JOIN essentials.offices o ON o.id = nr.office_id;
  IF n <> 31 THEN RAISE EXCEPTION 'only % of the 31 target offices exist', n; END IF;
  SELECT string_agg(nr.position_name || ' is listed under ' || nr.st || ' but its district is ' || upper(d.state) || ' ' || d.district_type, '; ') INTO txt
    FROM new_races nr JOIN essentials.offices o ON o.id = nr.office_id JOIN essentials.districts d ON d.id = o.district_id
   WHERE upper(d.state) <> nr.st OR d.district_type <> 'STATE_EXEC';
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an office is not where this file says: %', txt; END IF;
  SELECT count(*) INTO n FROM new_races nr JOIN essentials.races r ON r.office_id = nr.office_id
    JOIN essentials.elections e ON e.id = r.election_id WHERE e.election_date = DATE '2026-11-03';
  IF n <> 0 THEN RAISE EXCEPTION '% race(s) already exist on these offices for 2026-11-03', n; END IF;
  SELECT string_agg(nr.st || ' -> ' || coalesce(e.name, '(none)') || ' ' || coalesce(e.state, '?'), '; ') INTO txt
    FROM new_races nr LEFT JOIN essentials.elections e ON e.id = nr.election_id
   WHERE e.id IS NULL OR e.election_date <> DATE '2026-11-03' OR e.state IS DISTINCT FROM nr.st;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'an election row is not the 2026-11-03 general of its state: %', txt; END IF;
END $$;

INSERT INTO essentials.races (election_id, office_id, position_name, primary_party, seats)
SELECT nr.election_id, nr.office_id, nr.position_name, NULL, 1 FROM new_races nr
 WHERE NOT EXISTS (SELECT 1 FROM essentials.races r JOIN essentials.elections e ON e.id = r.election_id
                    WHERE r.office_id = nr.office_id AND e.election_date = DATE '2026-11-03');

-- ─── 3. The candidacies ───
CREATE TEMP TABLE calls (
  seed_key text PRIMARY KEY, rkey text NOT NULL, office_id uuid NOT NULL, seat text NOT NULL,
  who text NOT NULL, result text NOT NULL, status text NOT NULL, is_write_in boolean NOT NULL,
  is_ticket boolean NOT NULL, pinned_id uuid
) ON COMMIT DROP;
INSERT INTO calls (seed_key, rkey, office_id, seat, who, result, status, is_write_in, is_ticket, pinned_id) VALUES
  ('AL|Treasurer|Young Boozer', 'AL|Treasurer', '86ab166c-dfd2-493e-a5d2-d3ba1342fda3'::uuid,
   'AL Treasurer',                            'Young Boozer',                'won',   'active',    false, false, '7a0a5ed5-2a17-4fa8-8197-a589a4f5e2ab'::uuid),
  ('AL|Treasurer|Rosilyn Houston', 'AL|Treasurer', '86ab166c-dfd2-493e-a5d2-d3ba1342fda3'::uuid,
   'AL Treasurer',                            'Rosilyn Houston',             'lost',  'active',    false, false, NULL),
  ('AL|Treasurer|David Field', 'AL|Treasurer', '86ab166c-dfd2-493e-a5d2-d3ba1342fda3'::uuid,
   'AL Treasurer',                            'David Field',                 'lost',  'active',    true , false, NULL),
  ('AR|Treasurer|John Thurston', 'AR|Treasurer', 'b03f877e-9729-4cf1-b607-164f75bd08eb'::uuid,
   'AR Treasurer',                            'John Thurston',               'won',   'active',    false, false, 'e9af5fde-e1cd-4a54-9594-ec9e42353d55'::uuid),
  ('CT|Lieutenant Governor|Susan Bysiewicz', 'CT|Lieutenant Governor', 'fc973a1c-be0b-4d96-b1d6-09c2122b1ff8'::uuid,
   'CT Lieutenant Governor',                  'Susan Bysiewicz',             'won',   'active',    false, true , 'f22b744c-6857-4c75-bce0-3b58d592259c'::uuid),
  ('CT|Lieutenant Governor|Rick Adgers', 'CT|Lieutenant Governor', 'fc973a1c-be0b-4d96-b1d6-09c2122b1ff8'::uuid,
   'CT Lieutenant Governor',                  'Rick Adgers',                 'lost',  'active',    true , true , NULL),
  ('CT|Lieutenant Governor|Michael Grant', 'CT|Lieutenant Governor', 'fc973a1c-be0b-4d96-b1d6-09c2122b1ff8'::uuid,
   'CT Lieutenant Governor',                  'Michael Grant',               'lost',  'active',    true , true , NULL),
  ('CT|Treasurer|Erick Russell', 'CT|Treasurer', '93adf9fb-8676-4b3d-b736-c8328d190794'::uuid,
   'CT Treasurer',                            'Erick Russell',               'won',   'active',    false, false, '674a492b-43f5-45c5-85e8-c302d4a3fd91'::uuid),
  ('CT|Treasurer|Fred Wilms', 'CT|Treasurer', '93adf9fb-8676-4b3d-b736-c8328d190794'::uuid,
   'CT Treasurer',                            'Fred Wilms',                  'lost',  'active',    false, false, NULL),
  ('DE|Treasurer|Ted Lauzen', 'DE|Treasurer', '29461e2c-f020-4272-bf74-b8da68b51a95'::uuid,
   'DE Treasurer',                            'Ted Lauzen',                  'won',   'active',    false, false, NULL),
  ('DE|Treasurer|Michael Ramone', 'DE|Treasurer', '29461e2c-f020-4272-bf74-b8da68b51a95'::uuid,
   'DE Treasurer',                            'Michael Ramone',              'lost',  'active',    false, false, NULL),
  ('FL|Chief Financial Officer|Blaise Ingoglia', 'FL|Chief Financial Officer', '3e261b17-6b04-49a2-af95-55174347e19c'::uuid,
   'FL Chief Financial Officer',              'Blaise Ingoglia',             'won',   'active',    false, false, '8c7b61e3-709d-42f5-acf1-0c6a7e328f0a'::uuid),
  ('FL|Chief Financial Officer|Annette Taddeo', 'FL|Chief Financial Officer', '3e261b17-6b04-49a2-af95-55174347e19c'::uuid,
   'FL Chief Financial Officer',              'Annette Taddeo',              'lost',  'active',    false, false, NULL),
  ('HI|Lieutenant Governor|Derek Kawakami', 'HI|Lieutenant Governor', 'f7daf624-4e61-4e72-81f3-408c97a9ab2a'::uuid,
   'HI Lieutenant Governor',                  'Derek Kawakami',              'won',   'active',    false, true , NULL),
  ('HI|Lieutenant Governor|Daniel Anthony', 'HI|Lieutenant Governor', 'f7daf624-4e61-4e72-81f3-408c97a9ab2a'::uuid,
   'HI Lieutenant Governor',                  'Daniel Anthony',              'lost',  'active',    false, true , NULL),
  ('IA|Treasurer|Roby Smith', 'IA|Treasurer', '2b425609-2b7d-4974-a6d3-38a59df54d38'::uuid,
   'IA Treasurer',                            'Roby Smith',                  'won',   'active',    false, false, 'e13dabd3-ccff-4164-96a7-ecf2444d62c7'::uuid),
  ('IA|Treasurer|John Norwood', 'IA|Treasurer', '2b425609-2b7d-4974-a6d3-38a59df54d38'::uuid,
   'IA Treasurer',                            'John Norwood',                'lost',  'active',    false, false, NULL),
  ('ID|State Controller|Brandon Woolf', 'ID|State Controller', 'f0d34cb8-9fe9-4be7-94b0-179ecf52afad'::uuid,
   'ID State Controller',                     'Brandon Woolf',               'won',   'active',    false, false, '441bad79-c3a9-4cf3-86e1-9384303fe3bf'::uuid),
  ('ID|State Controller|Rakesh Mohan', 'ID|State Controller', 'f0d34cb8-9fe9-4be7-94b0-179ecf52afad'::uuid,
   'ID State Controller',                     'Rakesh Mohan',                'lost',  'active',    false, false, NULL),
  ('ID|Superintendent of Public Instruction|Debbie Critchfield', 'ID|Superintendent of Public Instruction', 'c5c22d9f-f47b-42b9-87e8-85183c6b3b5f'::uuid,
   'ID Superintendent of Public Instruction', 'Debbie Critchfield',          'won',   'active',    false, false, '18e7df42-f9ff-4713-9f5d-4a598d818cef'::uuid),
  ('ID|Superintendent of Public Instruction|Becky Mitchell', 'ID|Superintendent of Public Instruction', 'c5c22d9f-f47b-42b9-87e8-85183c6b3b5f'::uuid,
   'ID Superintendent of Public Instruction', 'Becky Mitchell',              'lost',  'active',    false, false, NULL),
  ('ID|Superintendent of Public Instruction|Teresa Roundy', 'ID|Superintendent of Public Instruction', 'c5c22d9f-f47b-42b9-87e8-85183c6b3b5f'::uuid,
   'ID Superintendent of Public Instruction', 'Teresa Roundy',               'lost',  'active',    false, false, NULL),
  ('ID|Treasurer|Julie Ellsworth', 'ID|Treasurer', '29b22a69-1c0b-4033-87e9-ead7b17b6059'::uuid,
   'ID Treasurer',                            'Julie Ellsworth',             'won',   'active',    false, false, 'ae007cc6-29f6-4b29-8f42-1770ed9f2d8a'::uuid),
  ('ID|Treasurer|Kevin Jones', 'ID|Treasurer', '29b22a69-1c0b-4033-87e9-ead7b17b6059'::uuid,
   'ID Treasurer',                            'Kevin Jones',                 'lost',  'active',    false, false, NULL),
  ('IL|Treasurer|Mike Frerichs', 'IL|Treasurer', 'a6350acc-729d-4d62-ba15-4538422631b2'::uuid,
   'IL Treasurer',                            'Mike Frerichs',               'won',   'active',    false, false, '84f33004-e145-4ea7-8c73-c68e2a1048c2'::uuid),
  ('IL|Treasurer|Max Solomon', 'IL|Treasurer', 'a6350acc-729d-4d62-ba15-4538422631b2'::uuid,
   'IL Treasurer',                            'Max Solomon',                 'lost',  'active',    false, false, NULL),
  ('IL|Treasurer|Timothea Papas', 'IL|Treasurer', 'a6350acc-729d-4d62-ba15-4538422631b2'::uuid,
   'IL Treasurer',                            'Timothea Papas',              'lost',  'active',    true , false, NULL),
  ('KS|Treasurer|Steven C. Johnson', 'KS|Treasurer', '20182ca9-eb4c-4aa0-8494-0f613710c88b'::uuid,
   'KS Treasurer',                            'Steven C. Johnson',           'won',   'active',    false, false, '6dada0fd-8e21-4899-819d-26ba69a75b37'::uuid),
  ('KS|Treasurer|Juan Luengo', 'KS|Treasurer', '20182ca9-eb4c-4aa0-8494-0f613710c88b'::uuid,
   'KS Treasurer',                            'Juan Luengo',                 'lost',  'active',    false, false, NULL),
  ('KS|Treasurer|Eric Lund', 'KS|Treasurer', '20182ca9-eb4c-4aa0-8494-0f613710c88b'::uuid,
   'KS Treasurer',                            'Eric Lund',                   'lost',  'active',    false, false, NULL),
  ('MA|Auditor of the Commonwealth|Diana DiZoglio', 'MA|Auditor of the Commonwealth', '58d289a0-a95e-474f-9c6e-b50fc7e93b04'::uuid,
   'MA Auditor of the Commonwealth',          'Diana DiZoglio',              'won',   'active',    false, false, '30b6b674-509f-46f6-a9aa-aa3dbefc2f42'::uuid),
  ('MA|Auditor of the Commonwealth|Al Ozonoff', 'MA|Auditor of the Commonwealth', '58d289a0-a95e-474f-9c6e-b50fc7e93b04'::uuid,
   'MA Auditor of the Commonwealth',          'Al Ozonoff',                  'lost',  'active',    false, false, NULL),
  ('MA|Lieutenant Governor|Kim Driscoll', 'MA|Lieutenant Governor', '66c34aa8-db37-4aed-a369-fa5729f62b4a'::uuid,
   'MA Lieutenant Governor',                  'Kim Driscoll',                'won',   'active',    false, true , 'e687c089-f00d-464c-aa37-3b021a3aba2c'::uuid),
  ('MA|Lieutenant Governor|Shawn Oliver', 'MA|Lieutenant Governor', '66c34aa8-db37-4aed-a369-fa5729f62b4a'::uuid,
   'MA Lieutenant Governor',                  'Shawn Oliver',                'lost',  'withdrawn', false, true , '206795e1-0a66-4f8c-b526-b9200639ff15'::uuid),
  ('MA|Lieutenant Governor|Kayla Kittredge', 'MA|Lieutenant Governor', '66c34aa8-db37-4aed-a369-fa5729f62b4a'::uuid,
   'MA Lieutenant Governor',                  'Kayla Kittredge',             'lost',  'active',    false, true , NULL),
  ('MA|Treasurer and Receiver-General|Deb Goldberg', 'MA|Treasurer and Receiver-General', '3367d772-6a6b-4c51-9a74-c294ed1dbfdc'::uuid,
   'MA Treasurer and Receiver-General',       'Deb Goldberg',                'won',   'active',    false, false, NULL),
  ('MA|Treasurer and Receiver-General|Elizabeth Dionne', 'MA|Treasurer and Receiver-General', '3367d772-6a6b-4c51-9a74-c294ed1dbfdc'::uuid,
   'MA Treasurer and Receiver-General',       'Elizabeth Dionne',            'lost',  'active',    false, false, NULL),
  ('MD|Comptroller|Brooke Elizabeth Lierman', 'MD|Comptroller', '816a9ad0-f2ac-48b3-918a-aa75aa2f9efd'::uuid,
   'MD Comptroller',                          'Brooke Elizabeth Lierman',    'won',   'active',    false, false, 'b26fb5d2-90eb-4108-8ce5-838df719473d'::uuid),
  ('MD|Comptroller|Sonya Dunn', 'MD|Comptroller', '816a9ad0-f2ac-48b3-918a-aa75aa2f9efd'::uuid,
   'MD Comptroller',                          'Sonya Dunn',                  'lost',  'active',    false, false, '47977cc4-c208-41ff-8944-7afc7c9bf055'::uuid),
  ('NE|Treasurer|Joey Spellerberg', 'NE|Treasurer', '4434a6ba-49dd-4564-9944-d324dc185be8'::uuid,
   'NE Treasurer',                            'Joey Spellerberg',            'won',   'active',    false, false, 'dfdd834a-3ea9-46d0-921a-190d2cac9acb'::uuid),
  ('NE|Treasurer|Daniel Ebers', 'NE|Treasurer', '4434a6ba-49dd-4564-9944-d324dc185be8'::uuid,
   'NE Treasurer',                            'Daniel Ebers',                'lost',  'active',    false, false, NULL),
  ('NM|Lieutenant Governor|Stephanie Garcia Richard', 'NM|Lieutenant Governor', '717136ab-07aa-48d4-b4fe-38ad94370b8d'::uuid,
   'NM Lieutenant Governor',                  'Stephanie Garcia Richard',    'won',   'active',    false, true , NULL),
  ('NM|Lieutenant Governor|David M. Gallegos', 'NM|Lieutenant Governor', '717136ab-07aa-48d4-b4fe-38ad94370b8d'::uuid,
   'NM Lieutenant Governor',                  'David M. Gallegos',           'lost',  'active',    false, true , NULL),
  ('NM|Treasurer|Laura Montoya', 'NM|Treasurer', '2bc67444-6fa2-4a8a-b029-c01d18a00692'::uuid,
   'NM Treasurer',                            'Laura Montoya',               'won',   'active',    false, false, '9d8e3a1a-dd68-433e-8f5c-6056317845d5'::uuid),
  ('NM|Treasurer|James Ellison', 'NM|Treasurer', '2bc67444-6fa2-4a8a-b029-c01d18a00692'::uuid,
   'NM Treasurer',                            'James Ellison',               'lost',  'active',    false, false, NULL),
  ('NY|Comptroller|Thomas P. DiNapoli', 'NY|Comptroller', '6593095f-6628-451e-97a2-5bf3efcd6a26'::uuid,
   'NY Comptroller',                          'Thomas P. DiNapoli',          'won',   'active',    false, false, '8f5b07af-7932-49d4-9164-6277781a541e'::uuid),
  ('NY|Comptroller|Joseph Hernandez', 'NY|Comptroller', '6593095f-6628-451e-97a2-5bf3efcd6a26'::uuid,
   'NY Comptroller',                          'Joseph Hernandez',            'lost',  'active',    false, false, NULL),
  ('OK|Treasurer|Cindy Byrd', 'OK|Treasurer', '2145be7d-ebf2-468a-b950-4aae7d6677d1'::uuid,
   'OK Treasurer',                            'Cindy Byrd',                  'won',   'active',    false, false, NULL),
  ('OK|Treasurer|Kiefer Perry', 'OK|Treasurer', '2145be7d-ebf2-468a-b950-4aae7d6677d1'::uuid,
   'OK Treasurer',                            'Kiefer Perry',                'lost',  'active',    false, false, NULL),
  ('PA|Lieutenant Governor|Austin Davis', 'PA|Lieutenant Governor', '1d40031c-6521-40b7-bd44-1af0da2951b2'::uuid,
   'PA Lieutenant Governor',                  'Austin Davis',                'won',   'active',    false, true , 'fc75d0fc-a205-43e2-ab13-80a1caecdff5'::uuid),
  ('PA|Lieutenant Governor|Jason Richey', 'PA|Lieutenant Governor', '1d40031c-6521-40b7-bd44-1af0da2951b2'::uuid,
   'PA Lieutenant Governor',                  'Jason Richey',                'lost',  'active',    false, true , NULL),
  ('PA|Lieutenant Governor|John Thomas', 'PA|Lieutenant Governor', '1d40031c-6521-40b7-bd44-1af0da2951b2'::uuid,
   'PA Lieutenant Governor',                  'John Thomas',                 'lost',  'active',    false, true , NULL),
  ('RI|Treasurer|James Diossa', 'RI|Treasurer', 'b4ffba0d-e20a-4367-8b88-222c0e8496a4'::uuid,
   'RI Treasurer',                            'James Diossa',                'won',   'active',    false, false, '95ee890b-81c3-4376-972c-ac474e5a95fe'::uuid),
  ('RI|Treasurer|Micholas Credle', 'RI|Treasurer', 'b4ffba0d-e20a-4367-8b88-222c0e8496a4'::uuid,
   'RI Treasurer',                            'Micholas Credle',             'lost',  'active',    false, false, NULL),
  ('SC|Treasurer|Curtis Loftis', 'SC|Treasurer', '8a6811c6-3253-4ae7-993a-13e19b5f1cb9'::uuid,
   'SC Treasurer',                            'Curtis Loftis',               'won',   'active',    false, false, '0a0736c2-3e12-4296-9abe-d2b7a793c8b8'::uuid),
  ('SC|Treasurer|Vincent Coe', 'SC|Treasurer', '8a6811c6-3253-4ae7-993a-13e19b5f1cb9'::uuid,
   'SC Treasurer',                            'Vincent Coe',                 'lost',  'active',    false, false, NULL),
  ('SD|Treasurer|Melissa Hull', 'SD|Treasurer', 'f7b99f3b-fbea-43fb-8d63-3f99e80a1638'::uuid,
   'SD Treasurer',                            'Melissa Hull',                'won',   'active',    false, false, NULL),
  ('SD|Treasurer|Margaret Kuipers', 'SD|Treasurer', 'f7b99f3b-fbea-43fb-8d63-3f99e80a1638'::uuid,
   'SD Treasurer',                            'Margaret Kuipers',            'lost',  'active',    false, false, NULL),
  ('TX|Texas Agriculture Commissioner|Clayton Tucker', 'TX|Texas Agriculture Commissioner', '5e752883-f21c-4abf-9de8-80b5d1247929'::uuid,
   'TX Texas Agriculture Commissioner',       'Clayton Tucker',              'won',   'active',    false, false, NULL),
  ('TX|Texas Agriculture Commissioner|Nate Sheets', 'TX|Texas Agriculture Commissioner', '5e752883-f21c-4abf-9de8-80b5d1247929'::uuid,
   'TX Texas Agriculture Commissioner',       'Nate Sheets',                 'lost',  'active',    false, false, NULL),
  ('TX|Texas Agriculture Commissioner|Austin Kelly', 'TX|Texas Agriculture Commissioner', '5e752883-f21c-4abf-9de8-80b5d1247929'::uuid,
   'TX Texas Agriculture Commissioner',       'Austin Kelly',                'lost',  'active',    false, false, NULL),
  ('TX|Texas Comptroller|Sarah Eckhardt', 'TX|Texas Comptroller', 'd50da2bc-0e8f-4d70-ba6c-d0dfcd0613b2'::uuid,
   'TX Texas Comptroller',                    'Sarah Eckhardt',              'won',   'active',    false, false, '2775a1c4-d7e5-45ce-9633-f1ad137c546a'::uuid),
  ('TX|Texas Comptroller|Donald Huffines', 'TX|Texas Comptroller', 'd50da2bc-0e8f-4d70-ba6c-d0dfcd0613b2'::uuid,
   'TX Texas Comptroller',                    'Donald Huffines',             'lost',  'active',    false, false, NULL),
  ('TX|Texas Comptroller|V. Alonzo Echavarria-Garza', 'TX|Texas Comptroller', 'd50da2bc-0e8f-4d70-ba6c-d0dfcd0613b2'::uuid,
   'TX Texas Comptroller',                    'V. Alonzo Echavarria-Garza',  'lost',  'active',    false, false, NULL),
  ('TX|Texas Comptroller|Shehla Faizi', 'TX|Texas Comptroller', 'd50da2bc-0e8f-4d70-ba6c-d0dfcd0613b2'::uuid,
   'TX Texas Comptroller',                    'Shehla Faizi',                'lost',  'active',    false, false, NULL),
  ('TX|Texas Land Commissioner|Benjamin Flores', 'TX|Texas Land Commissioner', '0bf99572-2eee-4183-97bf-721501889dbc'::uuid,
   'TX Texas Land Commissioner',              'Benjamin Flores',             'won',   'active',    false, false, NULL),
  ('TX|Texas Land Commissioner|Dawn Buckingham', 'TX|Texas Land Commissioner', '0bf99572-2eee-4183-97bf-721501889dbc'::uuid,
   'TX Texas Land Commissioner',              'Dawn Buckingham',             'lost',  'active',    false, false, 'b207a60b-0879-4135-b6d3-164c5d5c5701'::uuid),
  ('TX|Texas Land Commissioner|Neil Snider', 'TX|Texas Land Commissioner', '0bf99572-2eee-4183-97bf-721501889dbc'::uuid,
   'TX Texas Land Commissioner',              'Neil Snider',                 'lost',  'active',    false, false, NULL),
  ('VT|Treasurer|Michael Pieciak', 'VT|Treasurer', '0317b579-578e-4e5a-8ab0-010be70979f2'::uuid,
   'VT Treasurer',                            'Michael Pieciak',             'won',   'active',    false, false, NULL),
  ('VT|Treasurer|Lynn LaFleur', 'VT|Treasurer', '0317b579-578e-4e5a-8ab0-010be70979f2'::uuid,
   'VT Treasurer',                            'Lynn LaFleur',                'lost',  'active',    false, false, NULL),
  ('VT|Treasurer|Zachary Hampl', 'VT|Treasurer', '0317b579-578e-4e5a-8ab0-010be70979f2'::uuid,
   'VT Treasurer',                            'Zachary Hampl',               'lost',  'active',    false, false, NULL),
  ('WY|Treasurer|Curt Meier', 'WY|Treasurer', '6ec2bf63-5da2-460b-b216-633e3a92c913'::uuid,
   'WY Treasurer',                            'Curt Meier',                  'won',   'active',    false, false, '2fd0ec31-7193-451a-90aa-1754aba860cb'::uuid);

CREATE TEMP TABLE pins ON COMMIT DROP AS
SELECT c.*, coalesce(c.pinned_id, s.politician_id) AS pid FROM calls c LEFT JOIN seeded s ON s.seed_key = c.seed_key;

CREATE OR REPLACE FUNCTION pg_temp.endsname(t text) RETURNS text IMMUTABLE LANGUAGE sql AS $f$
  SELECT CASE WHEN cardinality(w) = 0 THEN $$$$ WHEN cardinality(w) = 1 THEN w[1]
              ELSE w[1] || ' ' || w[cardinality(w)] END
    FROM (SELECT array_remove(array_remove(array_remove(array_remove(
            regexp_split_to_array(btrim(regexp_replace(pg_temp.namekey(t), '[^a-z ]', ' ', 'g')), '\s+'),
            'jr'), 'sr'), 'ii'), 'iii') AS w) q
$f$;

DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM pins WHERE pid IS NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% candidacy(ies) resolve to no person', n; END IF;
  SELECT count(*) INTO n FROM calls c JOIN seeded s ON s.seed_key = c.seed_key WHERE c.pinned_id IS NOT NULL;
  IF n <> 0 THEN RAISE EXCEPTION '% candidacy(ies) are both pinned and seeded', n; END IF;
  SELECT string_agg(p.full_name || ' (' || p.id || ') is archived', '; ') INTO txt
    FROM pins c JOIN essentials.politicians p ON p.id = c.pid WHERE NOT p.is_active;
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a candidacy points at an archived person: %', txt; END IF;

  -- 🔴 a pinned uuid must be the person the file names (CC_0359 added this after a control
  --    showed a swapped id is invisible: the INSERT takes the name from the pinned row).
  SELECT string_agg(c.seat || ': this file names ' || c.who || ' but the pinned row is ' || p.full_name || ' (' || p.id || ')', '; ') INTO txt
    FROM calls c JOIN essentials.politicians p ON p.id = c.pinned_id
   WHERE c.pinned_id IS NOT NULL AND pg_temp.endsname(p.full_name) <> pg_temp.endsname(c.who);
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a pinned politician is not the person this file names: %', txt; END IF;

  SELECT count(*) INTO n FROM (
    SELECT rkey FROM calls GROUP BY rkey HAVING count(*) FILTER (WHERE result = 'won') <> 1) z;
  IF n <> 0 THEN RAISE EXCEPTION '% race(s) in this file do not hold exactly one winner', n; END IF;
  SELECT count(*) INTO n FROM calls WHERE result = 'won';
  IF n <> 31 THEN RAISE EXCEPTION 'expected 31 winners, found %', n; END IF;
  SELECT count(*) INTO n FROM calls WHERE result NOT IN ('won','lost');
  IF n <> 0 THEN RAISE EXCEPTION '% candidacy(ies) carry a result other than won or lost', n; END IF;

  -- 🔴 NOBODY IN A TICKET LIEUTENANT GOVERNOR RACE MAY BE A SITTING GOVERNOR OR A CANDIDATE
  --    FOR GOVERNOR. This is the specific error the ticket rows invite, and it is caught by
  --    an outside fact: office_current_holder, and this election's own Governor races.
  SELECT string_agg(c.seat || ': ' || c.who || ' is also on the Governor ballot in ' || c.seat, '; ') INTO txt
    FROM pins c
   WHERE c.is_ticket AND EXISTS (
     SELECT 1 FROM essentials.race_candidates rc
       JOIN essentials.races r2 ON r2.id = rc.race_id
       JOIN essentials.elections e2 ON e2.id = r2.election_id AND e2.election_date = DATE '2026-11-03'
       JOIN essentials.offices o2 ON o2.id = r2.office_id
       JOIN essentials.districts d2 ON d2.id = o2.district_id
      WHERE rc.politician_id = c.pid AND d2.district_type = 'STATE_EXEC'
        AND o2.title ILIKE '%Governor%' AND o2.title NOT ILIKE '%Lieutenant%');
  IF txt IS NOT NULL THEN RAISE EXCEPTION 'a ticket lieutenant-governor candidate is on the Governor ballot — the ticket HEAD was taken instead of the running mate: %', txt; END IF;
END $$;

INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, candidate_status,
   is_write_in, source, result, result_certainty, result_source, result_recorded_at)
SELECT r.id, p.id, p.full_name, p.first_name, p.last_name,
       (och.politician_id IS NOT NULL), c.status,
       c.is_write_in, 'Ballotpedia, "<State> state executive official elections, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0360', c.result, 'called', 'Ballotpedia, "<State> state executive official elections, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0360', now()
  FROM pins c
  JOIN essentials.races r ON r.office_id = c.office_id
  JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
  JOIN essentials.politicians p ON p.id = c.pid
  LEFT JOIN essentials.office_current_holder och ON och.office_id = c.office_id AND och.politician_id = c.pid
 WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.politician_id = p.id);

-- ─── Post-verify ───
DO $$ DECLARE n int; txt text; BEGIN
  SELECT count(*) INTO n FROM new_races nr JOIN essentials.races r ON r.office_id = nr.office_id
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03';
  IF n <> 31 THEN RAISE EXCEPTION 'expected 31 new races, found %', n; END IF;
  SELECT count(*) INTO n FROM pins c
    JOIN essentials.races r ON r.office_id = c.office_id
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = c.pid
   WHERE rc.result = c.result AND rc.result_certainty = 'called'
     AND rc.result_source = 'Ballotpedia, "<State> state executive official elections, 2026", read 2026-11-06 (winner flag only; its vote counts are incomplete and are NOT used) — CC_0360' AND rc.result_recorded_at >= TIMESTAMPTZ '2026-11-05'
     AND rc.is_write_in = c.is_write_in AND rc.candidate_status = c.status;
  IF n <> 72 THEN RAISE EXCEPTION 'only % of the 72 candidacies hold their stated result', n; END IF;
  SELECT count(*) INTO n FROM (
    SELECT r.id FROM new_races nr JOIN essentials.races r ON r.office_id = nr.office_id
      JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
      JOIN essentials.race_candidates rc ON rc.race_id = r.id GROUP BY r.id
    HAVING count(*) FILTER (WHERE rc.result = 'won') <> 1 OR count(*) FILTER (WHERE rc.result IS NULL) <> 0) z;
  IF n <> 0 THEN RAISE EXCEPTION '% new race(s) lack exactly one winner or hold an undecided row', n; END IF;
  SELECT count(*) INTO n FROM seeded sd JOIN essentials.politicians p ON p.id = sd.politician_id WHERE p.is_active AND NOT p.is_incumbent;
  IF n <> 47 THEN RAISE EXCEPTION 'only % of the 47 seeded people read active and non-incumbent', n; END IF;
  SELECT count(*) INTO n FROM pins c
    JOIN essentials.races r ON r.office_id = c.office_id
    JOIN essentials.elections e ON e.id = r.election_id AND e.election_date = DATE '2026-11-03'
    JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = c.pid
   WHERE rc.result_certainty <> 'called';
  IF n <> 0 THEN RAISE EXCEPTION '% row(s) do not read called', n; END IF;
  RAISE NOTICE 'CC_0360 OK — 31 races, 72 candidacies (31 won), 47 people seeded.';
END $$;

COMMIT;
