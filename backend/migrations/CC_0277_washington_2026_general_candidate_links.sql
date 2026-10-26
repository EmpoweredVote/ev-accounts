-- CC_0277_washington_2026_general_candidate_links.sql
--
-- Washington 2026 General, part 1 of 2. Links 12 candidacies. CC_0278 creates the other 197.
--
--   LINK  12   REFUSED (wrong person, each POSITIVELY disconfirmed)  4
--
-- ───────────────────────────────────────────────────────────────────────────────────────────
-- ═══ 🟢 WASHINGTON HAS AN EVIDENCE INSTRUMENT AFTER ALL, AND THIS FOUND IT ═══
--
-- The handoff recorded that WA's certified candidate list is a scanned photocopier image with no
-- text layer, and concluded "outside California there is no instrument". The PDF is indeed a
-- scan. **The instrument is not in the PDF.**
--
-- 🟢 WASHINGTON'S ONLINE VOTERS' PAMPHLET PUBLISHES A STRUCTURED "Elected Experience" FIELD FOR
-- EVERY CANDIDATE, AS JSON, OVER A PUBLIC ENDPOINT WITH NO KEY:
--
--     https://voter.votewa.gov/elections/voterguide.ashx?e=898&la=en&c=
--       -> the whole election: 5 categories, 826 races, every candidate's BallotID
--     https://voter.votewa.gov/elections/candidate.ashx?e=898&r=<RaceID>&b=<BallotID>&la=en&c=
--       -> that candidate's record; `statement.Statement` is HTML whose first section is
--          <b>Elected Experience</b>, followed by Other Professional Experience, Education,
--          Community Service and Statement.
--
-- `e=898` is the 2026 primary, which is the right election to read: it carries EVERY filed
-- candidate, including the ones who did not advance. `backend/scripts/wa-voter-pamphlet.mjs`
-- harvests it. Measured 2026-10-20 over the 209 unlinked WA rows: **205 matched a pamphlet entry
-- by ballot name, 193 carry Elected Experience text.** That is 92% coverage -- far better than
-- California's ballot designation managed in LA County (38%).
--
-- ▶ WHY IT CLEARS THE BAR: it is the candidate's OWN submitted statement, printed by the
-- Secretary of State in the pamphlet mailed to every voter. That is the same artefact class as a
-- California ballot designation -- a sworn, published self-description -- and it is more
-- specific, because it names dates and often the district.
--
-- ⚠ IT IS NOT STORED IN `occupational_designation` AND MUST NOT BE. That column holds
-- California's three-word sworn ballot designation. A pamphlet paragraph is a different artefact
-- with different rules; putting both in one column would make "which rows carry a designation?"
-- count two unlike things. The harvest is reproducible in a minute from the script above.
--
-- ═══ TIER 1 -- THE CANDIDATE'S OWN STATEMENT NAMES THE SEAT WE RECORD THEM HOLDING (9) ═══
-- Each of these filed for the EXACT office our `office_current_holder` says they hold, and their
-- pamphlet statement says so independently. Two unrelated official systems, agreeing:
--   * the candidacy comes from the WA SoS candidate filings (voter.votewa.gov), which print the
--     LEGAL name -- "Jamila E. Taylor", "Drew C MacEwen", "Mia Su-Ling Gregerson";
--   * the seat comes from the WA Legislature's own member web service
--     (wslwebservices.leg.wa.gov), which prints the COMMON name -- "Jamila Taylor", "Drew
--     MacEwen", "Mia Gregerson".
-- 🟢 So the name difference is EXPLAINED by the two sources' conventions rather than being a
-- coincidence that has to be excused.
--
--   Jamila E. Taylor       House 30 Pos 1  "State Representative: Chair of Civil Rights &
--                                           Judiciary Committee..."
--   Mia Su-Ling Gregerson  House 33 Pos 2  "She's represented the 33rd District since 2013"
--   Brianna K. Thomas      House 34 Pos 1  "Proudly serving as your State Representative since 2025"
--   Julia Grant Reed       House 36 Pos 1  "Current State Representative, 36th LD"
--   My-Linh T Thai         House 41 Pos 2  "State Representative: Deputy Majority Leader..."
--   Debra Jean Entenman    House 47 Pos 1  "State Representative, 47th District, 2018-present"
--   Tina L. Orwall         Senate 33       "State Senator; Vice Chair of Health & Long-Term Care"
--   Drew C MacEwen         Senate 35       "State Senate 2023 to present, State Rep 2013 to 2023"
--   Noel C. Frame          Senate 36       "State Senator, 2023-present; State Rep, 2016-2023"
--
-- 🟢 THREE OF THEM NAME THE DISTRICT NUMBER, which is the identifier that cannot drift: Reed
-- (36th), Entenman (47th), Gregerson (33rd). And MacEwen's and Frame's "2023 to present" both
-- agree with our term_start of 2023-01-09, written from the legislature's roster long before this
-- pamphlet was read.
--
-- ═══ TIER 2 -- A DIFFERENT SEAT, NAMED BY THE CANDIDATE, THAT WE ALSO RECORD (3) ═══
--
--   JESSICA FORSYTHE -- seeking House 48 Pos 2 -- "Redmond City Council Member (2020-present),
--     Council President ('22-'23), Council VP ('24-'25)". We record a Jessica Forsythe as
--     **Councilmember, Position 3, Redmond**.
--   VANESSA KRITZER -- seeking House 45 Pos 2 -- "Redmond City Councilmember (2020-present);
--     Council President (2024-2025); Council Vice President (2022-2023)". We record a Vanessa
--     Kritzer as **Councilmember, Position 5, Redmond**.
--   🟢 The two statements INTERLOCK: Forsythe was Council President in '22-'23 and VP in '24-'25;
--   Kritzer was VP in 2022-2023 and President in 2024-2025. Two candidates, two pamphlet entries
--   written independently, describing the same council's officer rotation from opposite sides.
--   A coincidence of names could not produce that.
--   ⚠ Neither statement gives the POSITION NUMBER, so the position in our record is not
--   corroborated -- but the position number is not what identifies the person. Redmond's council
--   has seven seats and exactly one Forsythe and one Kritzer.
--
--   NIKKI TORRES -- seeking **Senate 8** -- "Elected to the Senate, 15th District 2022, Deputy
--     Floor Leader... Elected to Pasco City Council, 2021". We record a Nikki Torres as **State
--     Senator, Legislative (Senate) District 15**.
--   🔴 THIS IS THE ONE THAT LOOKS LIKE A WRONG-PERSON MATCH AND IS NOT. Same chamber, DIFFERENT
--   district -- exactly the shape that should stop a link. It is resolved by the candidate
--   herself: her pamphlet entry for the 8th District race says she was elected to the Senate in
--   the 15th in 2022. She is a sitting senator standing in a neighbouring district, not a
--   second Nikki Torres.
--   ⚠ Our record of her 15th-District seat stays exactly as it is. A candidacy is not occupancy;
--   she holds the 15th today and this migration says nothing else.
--
-- ═══ 🔴🔴 FOUR REFUSED -- AND THE PAMPHLET TURNS "CANNOT SHOW SAMENESS" INTO "CAN SHOW
--     DIFFERENCE" ═══
-- Every previous refusal in this programme rested on a cross-state mismatch: the matched person
-- holds a seat in another state, so the candidate is probably someone else. That is an argument
-- from improbability. Here each refusal is POSITIVELY disconfirmed by the candidate's own words.
--
--   ANGELA TAYLOR      House 2 Pos 2  -- Elected Experience: **"None."**
--     Matched `49ac6935` Angela D. Taylor, a sitting **NEVADA State Senator, District 15**.
--     🔴 A sitting state senator does not write "None" under Elected Experience.
--   ERIC W. PRATT      House 24 Pos 1 -- "Precinct Committee Officer"
--     Matched `fa8d5cfb` Eric Pratt, **MINNESOTA Senator, District 54**.
--   KATHY RICHARDSON   House 28 Pos 1 -- "Board member, ARNP's United"
--     Matched `abddea3f` Katherine Gilmore Richardson, **Councilmember At Large, PHILADELPHIA**.
--   MICHAEL ALVAREZ SHEPARD  Senate 42 -- "Port Commissioner in his third term"
--     Matched `e8df1e64` Mike Shepard, **Council Member Place 1, City of Lavon, TEXAS**.
--
-- 🟢 ALL FOUR ARE CREATED AS SEPARATE PEOPLE IN CC_0278, and **not one of them trips the
-- duplicate-name guard** -- `Eric W. Pratt`, `Kathy Richardson` and `Michael Alvarez Shepard`
-- all split to a first_name the existing row does not carry, and `Angela Taylor` likewise.
-- ⚠ That silence is not agreement. The guard keys on (first_name, last_name) and simply never
-- looked at any of them; the adjudication above is what settles them, and it lives here.
--
-- ⚠ WHY `race_candidates.is_incumbent` WAS NOT USED, THOUGH IT LOOKED LIKE THE ANSWER.
-- All 209 unlinked rows read `is_incumbent = false`, and all 113 rows that read true are already
-- linked -- which invites the conclusion that the source says these nine are not incumbents.
-- 🔴 IT DOES NOT. Grouping by `source` shows the SoS filings feed carries 295 rows of which 93
-- ARE flagged -- so the flag is set for some rows from that very source and absent for others.
-- In all nine races above, NO row is flagged and NO row is linked: the flag is missing for the
-- whole race, not denied for the candidate. **`false` here is an unset default, not an
-- assertion** -- a predicate reading the shape of a value rather than what it says.
--
-- Idempotent: re-running links nothing new.

BEGIN;

CREATE TEMP TABLE _link (
  rc_id   uuid PRIMARY KEY,
  cand    text NOT NULL,
  pol_id  uuid NOT NULL,
  o_title text NOT NULL,   -- the seat the matched person must still hold
  d_label text NOT NULL
) ON COMMIT DROP;

INSERT INTO _link VALUES
 -- tier 1 -- filed for the very seat they hold
 ('47e7053a-fe82-407c-869f-92c8e179cd78','Jamila E. Taylor','da15c353-3744-4dd3-a6ed-c4b6e89752e1',
  'State Representative (Position 1)','Legislative (House) District 30'),
 ('6de113d1-f09d-4d76-a384-f0a96a11548d','Mia Su-Ling Gregerson','edc48d7e-4f91-4e59-af50-79f34df8b011',
  'State Representative (Position 2)','Legislative (House) District 33'),
 ('2b41f82b-1822-46f6-8501-8d8c102ad772','Brianna K. Thomas','c88a915a-6613-4940-a12d-18a28b00935c',
  'State Representative (Position 1)','Legislative (House) District 34'),
 ('1ae8ffd7-26ff-46cf-b047-99eafdeb4ef7','Julia Grant Reed','67b9aaf1-46eb-471f-8f31-dcf501a92933',
  'State Representative (Position 1)','Legislative (House) District 36'),
 ('d4d702fd-1893-438f-8bcb-a5ee658ca0ba','My-Linh T Thai','1963d6e9-069b-4770-9489-59e36faaa2e1',
  'State Representative (Position 2)','Legislative (House) District 41'),
 ('8955c024-7a89-450b-b258-ab48a9e7db58','Debra Jean Entenman','628a26a2-bcb9-4e87-a29f-ac5f6b381a37',
  'State Representative (Position 1)','Legislative (House) District 47'),
 ('21af8460-de87-4cbf-9e42-cb5b300f3261','Tina L. Orwall','7535e225-d3d0-40ca-ba9c-3890563c40a0',
  'State Senator','Legislative (Senate) District 33'),
 ('e4f930cf-e466-43a0-8a0d-de39279e104b','Drew C MacEwen','5ab349b4-f041-4637-af64-c4e6e4f54c3e',
  'State Senator','Legislative (Senate) District 35'),
 ('df1aff5b-dcb9-49f0-b3f7-3b9fdb4ea1ee','Noel C. Frame','4991ee01-0a35-454f-bdf6-bb2f34cf1c30',
  'State Senator','Legislative (Senate) District 36'),
 -- tier 2 -- a different seat, named by the candidate, that we also record
 ('c2d17dcd-4602-49c3-833c-7c5953d5ce01','Jessica Forsythe','6b0a5417-9094-447f-8df7-d868aab762eb',
  'Councilmember, Position 3','Redmond Citywide (At-large)'),
 ('00d3b2e5-6d56-4228-981d-22acf51fef4e','Vanessa Kritzer','21a8e1cc-f52d-439e-a0d0-50c5f6720bed',
  'Councilmember, Position 5','Redmond Citywide (At-large)'),
 ('d8a513c6-8ea7-48fd-8bf4-91b2e3b07576','Nikki Torres','624622d4-ce11-4fa3-9f0b-89c47559d1c6',
  'State Senator','Legislative (Senate) District 15');

DO $$
DECLARE r record; v text; v_pid uuid; v_act bool; n int;
BEGIN
  FOR r IN SELECT * FROM _link LOOP
    SELECT p.full_name, p.is_active INTO v, v_act
      FROM essentials.politicians p WHERE p.id = r.pol_id;
    IF v IS NULL THEN RAISE EXCEPTION 'CC_0277: politician % missing', r.pol_id; END IF;
    IF NOT v_act THEN
      RAISE EXCEPTION 'CC_0277: % is ARCHIVED - linking would resurrect a retired row', v;
    END IF;

    -- 🔴 THE EVIDENCE IS THE SEAT, SO ASSERT THE SEAT. Every one of these links says "the person
    -- who holds X is the person filing for Y". If they no longer hold X the argument is gone and
    -- the link must be re-derived from the pamphlet, not re-applied from this file.
    SELECT count(*) INTO n
      FROM essentials.office_terms t
      JOIN essentials.offices o   ON o.id = t.office_id
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE t.politician_id = r.pol_id
       AND o.title = r.o_title AND d.label = r.d_label AND lower(d.state) = 'wa';
    IF n <> 1 THEN
      RAISE EXCEPTION 'CC_0277: % does not hold exactly one "% @ %" term (found %) - the '
                      'office evidence no longer stands', v, r.o_title, r.d_label, n;
    END IF;

    SELECT rc.full_name, rc.politician_id INTO v, v_pid
      FROM essentials.race_candidates rc WHERE rc.id = r.rc_id;
    IF v IS DISTINCT FROM r.cand THEN
      RAISE EXCEPTION 'CC_0277: row % is "%", expected "%"', r.rc_id, v, r.cand;
    END IF;
    IF v_pid IS NOT NULL AND v_pid <> r.pol_id THEN
      RAISE EXCEPTION 'CC_0277: row % already linked to %', r.rc_id, v_pid;
    END IF;
  END LOOP;
END $$;

-- 🔴 A CONTROL ON THE REFUSALS. These four names must NOT be linked by this migration, and must
-- still be sitting unlinked when it ends. If a later edit ever adds one to _link, this fails.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM _link
   WHERE cand IN ('Angela Taylor','Eric W. Pratt','Kathy Richardson','Michael Alvarez Shepard');
  IF n <> 0 THEN
    RAISE EXCEPTION 'CC_0277: % refused candidate(s) appear in the link set - each was '
                    'POSITIVELY disconfirmed by their own pamphlet statement', n;
  END IF;
END $$;

UPDATE essentials.race_candidates rc SET politician_id = l.pol_id
FROM _link l WHERE rc.id = l.rc_id AND rc.politician_id IS DISTINCT FROM l.pol_id;

DO $$
DECLARE n_link int; n_left int; n_ref int;
BEGIN
  SELECT count(*) INTO n_link FROM essentials.race_candidates rc
    JOIN _link l ON l.rc_id = rc.id WHERE rc.politician_id = l.pol_id;
  IF n_link <> 12 THEN RAISE EXCEPTION 'CC_0277: expected 12 linked, found %', n_link; END IF;

  -- the four refusals are still unlinked, which is the finding
  SELECT count(*) INTO n_ref FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.state = 'WA' AND e.election_date >= current_date AND rc.politician_id IS NULL
     AND rc.full_name IN ('Angela Taylor','Eric W. Pratt','Kathy Richardson','Michael Alvarez Shepard');
  IF n_ref <> 4 THEN
    RAISE EXCEPTION 'CC_0277: expected the 4 refused rows to remain unlinked, found %', n_ref;
  END IF;

  SELECT count(*) INTO n_left FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.state = 'WA' AND e.election_date >= current_date AND rc.politician_id IS NULL;
  IF n_left <> 197 THEN
    RAISE EXCEPTION 'CC_0277: expected 197 WA rows left for CC_0278, found %', n_left;
  END IF;

  RAISE NOTICE 'CC_0277 OK - 12 linked, 4 refusals left unlinked, 197 remain for CC_0278';
END $$;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- 🔴 THE RULE: "THERE IS NO DOCUMENT" IS A CLAIM ABOUT WHERE YOU LOOKED.
-- The handoff recorded Washington's certified list as a scan with no text layer and concluded the
-- state had no instrument. The scan was real; the conclusion was not. The same Secretary of State
-- publishes every candidate's sworn Elected Experience as JSON, and it covers 92% of this cohort.
-- ▶ Before writing "no instrument exists", ask what the instrument was DOING -- a published,
-- sworn self-description -- and then look for anything that does that job, in any format.
-- 🟢 AND IT PAYS TWICE: a self-description disconfirms as well as it confirms. Angela Taylor's
-- "None." under Elected Experience refutes the match to a sitting Nevada senator outright. Every
-- earlier refusal in this programme was an argument from improbability; these four are evidence.
-- ───────────────────────────────────────────────────────────────────────────────────────────
