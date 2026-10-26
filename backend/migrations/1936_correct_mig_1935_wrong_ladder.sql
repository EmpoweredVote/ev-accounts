-- Migration 1936 — CORRECTION. Migration 1935 read the SEASON 1 ladder and judged SEASON 2 rows
-- against it. This restores the one chair it moved wrongly and repairs all six reasonings.
--
-- 🔴🔴 THE MISTAKE, STATED PLAINLY. `inform.compass_stances` IS NOT THE SEASON'S LADDER. It holds
-- one row per (topic_id, value) and, for the topics involved here, its text is the SEASON 1 wording.
-- The ladder a Season 2 answer is defined against lives in `inform.compass_stance_revisions`, keyed
-- by the `topic_revision_id` carried on the answer row itself. Migration 1935 quoted
-- `compass_stances` throughout and therefore argued against the wrong rung texts.
--
-- 🔴 AND IT MADE EXACTLY THE ERROR IT CLAIMED TO HAVE RULED OUT. 1935's header says it "PROBED FOR
-- AN INSERTED RUNG ... IT IS NOT ONE HERE", because housing rung 3 "today" read "Offer targeted
-- help like subsidies ... first-time buyer assistance". That IS the Season 1 rung 3. The Season 2
-- housing ladder is a different ladder:
--   S2 1  Make government the main provider - build and operate public housing so everyone is
--         guaranteed a home.
--   S2 2  Build a large public housing sector that competes with the private market to hold prices
--         down, while private housing stays the norm.
--   S2 3  Build no public housing, but set binding rules on the private market like rent caps or
--         required affordable units.
--   S2 4  Set no binding rules, but offer subsidies and tax breaks so more affordable housing gets
--         built.
--   S2 5  Rely on the market to set prices and supply - at most, cut the regulations and zoning
--         limits that block private building.
-- The "+1 shift" those six rows showed WAS the Season 1 -> Season 2 remap: the reasoning was
-- written against the Season 1 numbering and the chair carried the correct Season 2 image of it.
-- ⚖ The standing rule — "a +1 shift across a topic = an INSERTED RUNG, probe for it before
-- writing" — was right, and the probe was run against the wrong table.
--
-- WHAT WAS ACTUALLY WRONG, AND WHAT WAS NOT.
--
-- 🔴 ONE SUBSTANTIVE ERROR, REVERSED HERE. JOEY SPELLERBERG / housing was re-seated 4 -> 3. Under
--    the Season 2 ladder chair 4 is "Set no binding rules, but offer subsidies and tax breaks",
--    which is precisely what Nebraska LB 803 does - tax-deductible savings accounts for first-time
--    buyers, no binding rule on anyone - and chair 3 is "Build no public housing, but set BINDING
--    RULES on the private market like rent caps", which he does not support. HIS ORIGINAL CHAIR 4
--    WAS CORRECT. Restored.
--
-- ✅ THE FIVE BLANKS STAND, because none of them turned on which rung the text named. Each was
--    blanked on a ladder-independent ground, and each ground survives the correction:
--      · Erick Russell / housing — administers a programme created before his tenure, and CT Baby
--        Bonds is a general asset-building vehicle (home purchase, business, education OR
--        retirement), not a housing policy. OFFICE DUTY + off-axis instrument.
--      · Erick Russell / same-sex-marriage — the chair rested on personal identity ("is the first
--        openly gay Black person elected to Connecticut statewide office and is married to a man")
--        plus gender-affirming care, a different question. Identity is not a policy record, and
--        this topic is evidence_basis 'record' at state scope. ⚠ Note the Season 2 ssm ladder is
--        ALSO renumbered - S2 chair 2 reads "Guarantee same-sex marriage the same benefits and
--        protections as any other marriage" - so the original chair 2 was in fact the correct image
--        of the Season 1 rung 1 the prose named. That changes nothing: no rung on either ladder is
--        evidenced by who a person is married to.
--      · Fiona Ma / housing — chairing CDLAC and CTCAC is an ex officio statutory duty; the rest is
--        a salience claim. OFFICE DUTY.
--      · Malia M. Cohen / housing — names no bill, vote, date or quotation; aggregator sourcing.
--      · Steven Johnson / housing — "the Kansas Treasurer's OFFICE under Johnson administers"; a
--        bare-domain citation. OFFICE DUTY.
--
-- ✅ MIGRATIONS 1927, 1930, 1932 AND 1934 ARE UNAFFECTED. Checked rung by rung: `compass_stances`
--    and the Season 2 revision agree exactly on abortion, jail-capacity, public-safety-approach and
--    local-immigration. Deportation differs only in wording, not in meaning or order ("Only deport
--    people convicted of serious violent crimes" vs "Only deport undocumented immigrants convicted
--    of serious violent crimes"), so the deportation arguments in 1927 and 1930 stand as written.
--    Only housing, same-sex-marriage, climate-change and deportation diverge at all, and only the
--    first two are renumberings.
--
-- 🔑 THE REUSABLE LESSON, and it is the point of writing this file rather than quietly amending:
--    **READ THE LADDER THROUGH THE ANSWER'S OWN `topic_revision_id`.**
--      SELECT csr.value, csr.text FROM inform.politician_answers pa
--        JOIN inform.compass_stance_revisions csr USING (topic_revision_id) WHERE pa.politician_id=...
--    `compass_stances` is a convenience table and is NOT season-scoped. Migration 1921 got this
--    right — its R12 quotes the Season 2 text verbatim — so the knowledge existed and was not used.
--
-- Applied by hand via psql. Guards fail the whole transaction rather than write a partial result.

CREATE TEMP TABLE mig1936_targets (
  politician_id uuid NOT NULL,
  topic_id      uuid NOT NULL,
  who           text NOT NULL,
  what          text NOT NULL,
  value_now     numeric NOT NULL,   -- what migration 1935 left
  value_after   numeric NOT NULL,   -- what it should be
  note          text NOT NULL,
  reasoning_now text
);

INSERT INTO mig1936_targets (politician_id, topic_id, who, what, value_now, value_after, note) VALUES
('dfdd834a-3ea9-46d0-921a-190d2cac9acb'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,'Joey Spellerberg','housing',3,4,
 'CHAIR RESTORED TO 4. Migration 1935 moved this row from chair 4 to chair 3 after reading the SEASON 1 housing ladder by mistake. Against the SEASON 2 ladder this row is defined by, chair 4 reads "Set no binding rules, but offer subsidies and tax breaks so more affordable housing gets built" - which is exactly Nebraska LB 803, the First-Time Homebuyer Savings Account Act: tax-deductible savings accounts for down payments and closing costs, imposing no binding rule on any developer or landlord. Chair 3 reads "Build no public housing, but set binding rules on the private market like rent caps or required affordable units", which he has not supported. The original chair was right. THE EVIDENCE IS UNCHANGED AND IS GOOD: Senator Hallstrom introduced LB 803 at the Treasurer''s request, it passed 48-1 and was signed 2026-04-16, so the initiative is attributable to his office rather than merely administered by it. ⚖ The reasoning''s own reference to "stance 3" is the SEASON 1 numbering, under which rung 3 was the targeted-assistance rung; the Season 2 image of that content is chair 4, which is where this row sits.'),
('674a492b-43f5-45c5-85e8-c302d4a3fd91'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,'Erick Russell','housing',0,0,
 'BLANK CONFIRMED on a ground that does not depend on the ladder. The Connecticut Baby Bonds programme was created before this officeholder''s tenure and he administers it, and its permitted uses are home purchase, business investment, education or retirement - a general asset-building vehicle, not a housing policy. An office administering a programme is not the officeholder''s position on it. ⚠ Migration 1935 additionally argued from the Season 1 ladder; that argument is withdrawn, and the Season 2 chair 4 it displaced ("Set no binding rules, but offer subsidies and tax breaks") would have been the defensible chair had the programme been his and been about housing.'),
('674a492b-43f5-45c5-85e8-c302d4a3fd91'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'Erick Russell','same-sex-marriage',0,0,
 'BLANK CONFIRMED on a ground that does not depend on the ladder. The chair rested on personal identity - that he is the first openly gay Black person elected to Connecticut statewide office and is married to a man - together with action on gender-affirming care, which is a different question. Who a person is, and whom they are married to, is not a record of the policy they hold, and this topic is evidence_basis ''record'' at state scope. ⚠ CORRECTION TO MIGRATION 1935''s REASONING: the Season 2 same-sex-marriage ladder is also renumbered, and its chair 2 reads "Guarantee same-sex marriage the same benefits and protections as any other marriage" - so the chair the row served was in fact the correct Season 2 image of the Season 1 rung 1 its prose named. That corrects the mismatch, not the defect: no rung on either ladder is evidenced by identity.'),
('41ef8aaa-b604-4725-b46d-dab1656cc198'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,'Fiona Ma','housing',0,0,
 'BLANK CONFIRMED on a ground that does not depend on the ladder. Chairing CDLAC and CTCAC, the bodies that allocate California housing bonds and Low Income Housing Tax Credits, is an ex officio statutory duty of the Treasurer - held by virtue of the office whatever she believes - and overseeing the Dream for All fund is administration of a programme created elsewhere. What remains is a campaign listing affordable housing among top priorities, which states salience rather than which approach she favours. ⚠ Migration 1935''s quotation of the ladder was from Season 1 and is withdrawn; under the Season 2 ladder her office''s subsidy-and-tax-credit toolkit would point at chair 4 ("Set no binding rules, but offer subsidies and tax breaks"), not the chair 3 she held nor the "stance 2" her prose named - but it is the office''s toolkit, not her stated position.'),
('ea85dfe3-1092-468e-a799-cb8054c135db'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,'Malia M. Cohen','housing',0,0,
 'BLANK CONFIRMED on a ground that does not depend on the ladder. "Supported large-scale affordable housing investment and rental assistance programs during her time as SF supervisor" names no bill, no vote, no date and no quotation, and auditing housing spending as Controller is a duty of that office. The citations are an aggregator profile and a voter guide rather than a record. ⚠ Migration 1935''s quotation of the ladder was from Season 1 and is withdrawn; the defect is the absent instrument, which no ladder repairs.'),
('6dada0fd-8e21-4899-819d-26ba69a75b37'::uuid,'669cac97-66a6-4087-b036-936fbe62efb3'::uuid,'Steven Johnson','housing',0,0,
 'BLANK CONFIRMED on a ground that does not depend on the ladder. The whole of the evidence is that "the Kansas Treasurer''s OFFICE under Johnson administers the Home In The Heartland grant program" - an office duty discharged regardless of the officeholder''s view, with the programme not attributed to him - and the single citation is a bare domain with no path. ⚠ Migration 1935''s quotation of the ladder was from Season 1 and is withdrawn; under the Season 2 ladder a grant programme would point at chair 4 ("subsidies and tax breaks"), which is the chair the row already held, but administering it still shows no position.');

UPDATE mig1936_targets t
   SET reasoning_now = pc.reasoning
  FROM inform.politician_context pc
 WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
   AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

CREATE TEMP TABLE mig1936_before AS
SELECT count(*) AS seated_season2
  FROM inform.politician_answers
 WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND value > 0;

CREATE TEMP TABLE mig1936_season1_before AS
SELECT pa.politician_id, pa.topic_id, pa.value, pa.updated_at
  FROM inform.politician_answers pa
  JOIN inform.seasons se ON se.id = pa.season_id AND se.name = 'Season 1'
  JOIN mig1936_targets t ON t.politician_id = pa.politician_id AND t.topic_id = pa.topic_id;

-- GUARD 1 — the six rows are exactly as migration 1935 left them, and each carries its notice.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1936_targets;
  IF n <> 6 THEN RAISE EXCEPTION 'migration 1936: expected 6 targets, found %', n; END IF;

  SELECT count(*) INTO n
    FROM mig1936_targets t
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value IS NULL OR pa.value <> t.value_now;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1936: % target(s) are not in the state migration 1935 left them in', n; END IF;

  SELECT count(*) INTO n FROM mig1936_targets WHERE reasoning_now IS NULL OR reasoning_now NOT LIKE '%migration 1935%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1936: % target(s) do not carry a migration 1935 notice', n; END IF;
END $$;

-- GUARD 2 — 🔴 THE PREMISE OF THIS CORRECTION. The Season 2 housing ladder must really be the one
-- quoted above, read THROUGH THE ANSWER'S OWN topic_revision_id rather than through compass_stances
-- — which is the mistake being corrected, so it is proved here rather than assumed.
DO $$
DECLARE s2rev uuid; txt4 text; txt3 text;
BEGIN
  SELECT DISTINCT pa.topic_revision_id INTO s2rev
    FROM inform.politician_answers pa
   WHERE pa.topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;
  IF s2rev IS NULL THEN RAISE EXCEPTION 'migration 1936: no Season 2 revision for housing'; END IF;

  SELECT text INTO txt4 FROM inform.compass_stance_revisions WHERE topic_revision_id = s2rev AND value = 4;
  SELECT text INTO txt3 FROM inform.compass_stance_revisions WHERE topic_revision_id = s2rev AND value = 3;

  IF txt4 IS NULL OR txt4 NOT ILIKE '%subsidies and tax breaks%' THEN
    RAISE EXCEPTION 'migration 1936: Season 2 housing chair 4 is not the subsidies-and-tax-breaks rung this correction rests on (got: %)', coalesce(txt4, 'null');
  END IF;
  IF txt3 IS NULL OR txt3 NOT ILIKE '%binding rules%' THEN
    RAISE EXCEPTION 'migration 1936: Season 2 housing chair 3 is not the binding-rules rung (got: %)', coalesce(txt3, 'null');
  END IF;

  -- And the thing that caused the error: compass_stances must still DISAGREE, so this guard is
  -- meaningful. If they ever converge, this note should be revisited rather than silently passing.
  IF (SELECT text FROM inform.compass_stances
       WHERE topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid AND value = 4) = txt4 THEN
    RAISE EXCEPTION 'migration 1936: compass_stances now agrees with the Season 2 housing ladder — re-read this correction before applying it';
  END IF;
END $$;

-- GUARD 3 — exactly one chair moves, and it moves back to 4.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1936_targets WHERE value_now <> value_after;
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1936: expected exactly 1 chair change, found %', n; END IF;

  SELECT count(*) INTO n FROM mig1936_targets
   WHERE value_now <> value_after AND (politician_id <> 'dfdd834a-3ea9-46d0-921a-190d2cac9acb'::uuid OR value_after <> 4);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1936: the chair change is not Spellerberg -> 4'; END IF;
END $$;

-- ── THE WRITE ──────────────────────────────────────────────────────────────────────────────────

UPDATE inform.politician_answers pa
   SET value = t.value_after, updated_at = now()
  FROM mig1936_targets t
 WHERE pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
   AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   AND pa.value <> t.value_after;

-- Prepend the correction. 🔑 Migration 1935's text is kept beneath it, and the original reasoning
-- beneath that, so the whole chain stays readable rather than being tidied away.
UPDATE inform.politician_context pc
   SET reasoning = 'CORRECTED by migration 1936. ⚠ MIGRATION 1935 JUDGED THIS SEASON 2 ROW AGAINST THE SEASON 1 LADDER. It quoted inform.compass_stances, which is not season-scoped; the ladder a Season 2 answer is defined against lives in inform.compass_stance_revisions, keyed by the topic_revision_id on the answer itself. The Season 2 housing ladder runs: 1 government as main provider; 2 a large public housing sector; 3 no public housing but binding rules such as rent caps; 4 no binding rules but subsidies and tax breaks; 5 rely on the market. So the "+1 shift" migration 1935 treated as a defect was in fact the Season 1 to Season 2 REMAP, and the rung its prose named was the Season 1 numbering. '
                  || t.note
                  || ' ---- MIGRATION 1935 RECORD, SUPERSEDED IN PART, PRESERVED ---- '
                  || t.reasoning_now,
       updated_at = now()
  FROM mig1936_targets t
 WHERE pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
   AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- ── VERIFY ────────────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE n int; before_seated int; after_seated int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1936_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value <> t.value_after;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1936: % row(s) do not hold the corrected value', n; END IF;

  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id = 'dfdd834a-3ea9-46d0-921a-190d2cac9acb'::uuid
     AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'::uuid
     AND season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
     AND value = 4;
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1936: Spellerberg is not restored to chair 4'; END IF;

  -- The chain must remain readable: correction, then the 1935 record, then the original.
  SELECT count(*) INTO n
    FROM mig1936_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.reasoning NOT LIKE 'CORRECTED by migration 1936.%'
      OR pc.reasoning NOT LIKE '%MIGRATION 1935 RECORD, SUPERSEDED IN PART, PRESERVED%'
      OR pc.reasoning NOT LIKE '%---- ORIGINAL REASONING, PRESERVED ----%'
      OR position(t.reasoning_now in pc.reasoning) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1936: % row(s) lost part of the record chain', n; END IF;

  SELECT count(*) INTO n
    FROM mig1936_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE coalesce(cardinality(pc.sources), 0) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1936: % row(s) lost their citations', n; END IF;

  -- 🔴 BLAST RADIUS: the seated COUNT must not move at all. The only chair change is 3 -> 4, and
  -- both are seated values, so a non-zero delta would mean this pass touched something else.
  -- (The first draft of this guard expected +1 and failed its own dry run — a re-seat between two
  -- seated chairs is not a change in how many rows are seated.)
  SELECT seated_season2 INTO before_seated FROM mig1936_before;
  SELECT count(*) INTO after_seated FROM inform.politician_answers
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND value > 0;
  IF after_seated <> before_seated THEN
    RAISE EXCEPTION 'migration 1936: seated Season 2 rows changed by %, expected 0', after_seated - before_seated;
  END IF;

  -- The five blanks must still be blank: this correction restores one chair, not five.
  SELECT count(*) INTO n
    FROM mig1936_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE t.value_after = 0 AND pa.value <> 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1936: % row(s) that should remain blank are seated', n; END IF;

  -- 🔴 Season 1 is closed and must not have moved.
  SELECT count(*) INTO n
    FROM mig1936_season1_before b
    JOIN inform.politician_answers pa
      ON pa.politician_id = b.politician_id AND pa.topic_id = b.topic_id
    JOIN inform.seasons se ON se.id = pa.season_id AND se.name = 'Season 1'
   WHERE pa.value IS DISTINCT FROM b.value OR pa.updated_at IS DISTINCT FROM b.updated_at;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1936: % Season 1 row(s) moved', n; END IF;
END $$;

SELECT t.who, t.what, t.value_now AS mig1935_left, t.value_after AS corrected_to
  FROM mig1936_targets t ORDER BY t.who, t.what;
