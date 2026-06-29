-- Migration 1098: City of North Las Vegas stances - Scott Black (Council Member, Ward 3) (AUDIT-ONLY)
--
-- Phase 164 (CLARK-04). AUDIT-ONLY: NOT registered in the migration ledger;
-- the structural ledger stays at 1093. Evidence-only compass stances (CHAIRS
-- model - value is the discrete position the evidence matches, not a polarity).
-- 100% cited; every stance has reasoning + source URL(s). Topics with no
-- city-level evidence are honest blanks (absent). No defaulted values.
-- topic_id resolved LIVE by topic_key (is_live=true) - no hardcoded topic UUIDs.
-- politician_id = 80a3329f-c338-4991-afb3-b1670996ef7b (external_id -3207004, minted by mig 1093).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('economic-development'::text, 4, 'Black is the leading council champion of the 7,000-acre Apex Industrial Park, pursuing major employers via large public infrastructure subsidies. He voted with the SNWA board to approve $37 million for the Garnet Valley water/wastewater systems to enable Apex development, and publicly lobbied for the federal Apex Area Technical Corrections Act, saying it "really streamlines processes in the Apex Industrial Area in terms of utilities, easements, to allow development to really accelerate." The Vegas Chamber endorsed him citing his support of the Apex Industrial Park and Hylo Park - aggressively competing for large employers with major public infrastructure investment.', ARRAY['https://www.reviewjournal.com/local/north-las-vegas/north-las-vegas-industrial-park-bill-awaits-trumps-signature-3387507/','https://vegaschamber.com/vegas-chamber-endorses-scott-black-as-next-north-las-vegas-mayor/']::text[]),
    ('growth-and-development'::text, 4, 'Black frames North Las Vegas''s success around completing major development infrastructure and streamlining permitting to recruit development. He cites the Garnet Valley water line/sewer system and Apex road network as the "bookends to our success story," and supported the Apex Area Technical Corrections Act specifically because it "streamlines processes... in terms of utilities, easements, to allow development to really accelerate" - streamlined permitting and active recruitment of development.', ARRAY['https://www.reviewjournal.com/local/north-las-vegas/north-las-vegas-industrial-park-bill-awaits-trumps-signature-3387507/','https://www.ktnv.com/neighborhoods/north-las-vegas/north-las-vegas-mayoral-candidates-face-off-in-chamber-debate-residents-discuss-priorities']::text[]),
    ('rent-regulation'::text, 5, 'Black voted to block the Culinary Union''s 2022 North Las Vegas rent-control ballot initiative (which would have capped rent increases), siding with the city manager''s interpretation that kept it off the ballot. He called the measure "a one size fits all" solution that was inappropriate for the community, though he noted it might make more sense at a statewide or regional level. At the city level he opposed rent control.', ARRAY['https://nevadacurrent.com/2026/05/21/north-las-vegas-mayor-race-features-city-councilman-and-state-legislator/','https://www.nevadacurrent.com/2022/08/09/nlv-went-way-out-of-its-way-to-slam-the-door-on-rent-stabilization-critics-say/']::text[])
),
t AS (
  SELECT s.*, ct.id AS topic_id
  FROM s JOIN inform.compass_topics ct
    ON ct.topic_key = s.topic_key AND ct.is_live = true
),
ins_ans AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT '80a3329f-c338-4991-afb3-b1670996ef7b'::uuid, topic_id, val FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
  SELECT '80a3329f-c338-4991-afb3-b1670996ef7b'::uuid, topic_id, reasoning, sources FROM t
  ON CONFLICT (politician_id, topic_id) DO UPDATE
    SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
