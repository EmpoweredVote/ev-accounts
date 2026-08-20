-- 1838_travis_county_stances.sql
-- Travis County officeholders: first 8 compass stances (local 22-topic scale).
--
-- All 12 Travis County officeholders carried ZERO stances. This records the eight rows the
-- 2026-08-19 research wave could evidence to a SPECIFIC CHAIR, and no more. The other four
-- officials, and every other topic, are deliberately left blank: a blank spoke is the honest
-- answer and an unevidenced chair is a false statement about a real person.
--
-- ALREADY APPLIED to prod on 2026-08-19 by the research-stances push. This migration exists so the
-- repo carries the audit trail for a voter-facing change (the research CSV itself is gitignored),
-- and is written idempotent so re-applying is a no-op.
--
-- WHY THESE EIGHT, AND WHAT WAS REFUSED
--   Sources: Travis County Judge press releases (primary PDFs), the Austin Monitor per-person tag
--   archives, and the District Attorney's own office pages. Every source URL was fetched and
--   returned 200 before the row was written; two URLs reconstructed from headlines turned out to be
--   wrong and were corrected against the harvested article, not guessed.
--   REFUSED as direction-without-magnitude, per CLAUDE.md: Andy Brown on abortion (opposes the Texas
--   ban but names no gestational framework, so chairs 1/2/3 are all consistent with the evidence);
--   Brigid Shea and Celia Israel on transportation (transit advocacy is clear, but chair 1 is
--   compound and its parking-requirements clause is unevidenced); Delia Garza on residential zoning
--   (mixed direction, city-council-era, six years stale). Sally Hernandez is HELD: she co-chairs the
--   diversion programme, but chair 2 contrasts against "building new capacity" and she runs the jail,
--   so her position on capacity itself is unsourced.
--
-- SAME-SOURCE RULE. The Mental Health Diversion press release evidences jail-capacity ONLY. Reusing
-- it for public-safety-approach as well would pin neither, so that spoke stays blank.
--
-- CHAIR-EVIDENCE GATE. Three of these rows name an instrument the gate can see; five name county
-- PROGRAMMES (a diversion steering committee, a solar installation programme, an early-case-review
-- process, a campaign platform). That is a real limitation of programmatic county-executive evidence,
-- recorded here rather than papered over -- the reasoning was NOT padded with instrument words to
-- pass a lexical proxy.
--
-- Idempotency: ON CONFLICT DO NOTHING on both tables, so this never overwrites a later human edit.

BEGIN;

WITH src(politician_id, topic_key, value, reasoning, sources) AS (VALUES
  ('d0e80e1b-32d3-4b10-9fd1-e90afc412a12', 'childcare', 2,
   'Brown championed Travis County Proposition A, the November 2024 ballot measure that raised the county tax rate to fund child care and passed with 59.43 percent of the vote. The program expands early childhood and afterschool care by increasing quality and capacity for children aged 0 to 3, funding afterschool and summer care during nontraditional hours, and creating a business-government partnership that incentivizes employers to offer child care stipends. That is a significant expansion of public subsidy and provider capacity aimed at working families, rather than a universal entitlement or a narrow tax credit.',
   ARRAY['https://www.traviscountytx.gov/images/commissioners_court/judge/20241106_Child_Care_Prop_A_Press_Release.pdf']),
  ('d0e80e1b-32d3-4b10-9fd1-e90afc412a12', 'jail-capacity', 2,
   'Brown co-chairs the Travis County Mental Health Diversion Steering Committee, which he launched with Sheriff Sally Hernandez in August 2024 to build a diversion center for Travis County. The committee''s stated priorities are optimizing crisis response, tracking eligible individuals through the process, and integrating community-based re-entry supports — reducing who ends up incarcerated through diversion and treatment alternatives rather than adding jail beds.',
   ARRAY['https://www.traviscountytx.gov/images/commissioners_court/judge/doc/08282024_MH_Diversion_Steering_Committee_Press_Release.pdf']),
  ('e0d9989c-af22-42a5-a6b0-f77073d20386', 'childcare', 2,
   'Shea backed Travis County Proposition A, the affordable child care initiative funded by the 2024 tax rate increase and approved by voters that November, describing it as a transformative investment in early childhood care for thousands of local families. Her stated basis is the evidence that investing in high-quality early childhood care improves graduation rates, health and earnings — support for significantly expanding publicly funded child care capacity and affordability rather than leaving it to targeted credits or the market.',
   ARRAY['https://austinmonitor.com/stories/2025/01/travis-county-commissioner-brigid-shea-urges-local-climate-resilience-initiatives-to-combat-coming-federal-turn/', 'https://www.traviscountytx.gov/images/commissioners_court/judge/20241106_Child_Care_Prop_A_Press_Release.pdf']),
  ('e0d9989c-af22-42a5-a6b0-f77073d20386', 'climate-change', 3,
   'As Travis County''s Precinct 2 commissioner Shea has driven the county''s clean energy and water resilience programs: installing solar panels with battery backup on as many county facilities as possible using Austin Energy funds, and the county''s purple pipe reclaimed-water program, which she says will permanently eliminate demand for 45 million gallons a year once county buildings and the Capitol complex are connected. Her documented county record is sustained public investment in clean energy and conservation; she has not called for banning emissions-increasing activity or for a dated fossil fuel phase-out.',
   ARRAY['https://austinmonitor.com/stories/2025/01/travis-county-commissioner-brigid-shea-urges-local-climate-resilience-initiatives-to-combat-coming-federal-turn/']),
  ('ccaf36cf-65a7-43d4-9f6e-6d8071b5f8bd', 'homelessness-response', 1,
   'Howard came to the Precinct 3 seat from the Ending Community Homelessness Coalition and has made permanent supportive housing the county''s strategy. She led the county resolution investing $110 million of American Rescue Plan Act funds into 11 housing projects, and in September 2024 the county signed $27 million in contracts with LifeWorks and Foundation Communities to add more than 200 affordable supportive housing units for people experiencing homelessness. Her approach builds permanent housing with services attached rather than expanding shelter capacity or relying on enforcement of public space rules.',
   ARRAY['https://austinmonitor.com/stories/2025/01/in-2025-travis-county-commissioner-ann-howard-eyes-building-more-supportive-housing-and-strengthening-climate-resilience/']),
  ('193123e1-8c6b-48b4-9581-2305ba4128b2', 'jail-capacity', 1,
   'As Travis County Attorney, Garza argues that money spent on services inside jails should instead be spent on those services outside jails, and has acted on it: she implemented an early case review process under which her office reviews an arrest within 48 hours to decide whether to dismiss or prosecute, which cut average jail stays from 35 days to 17 days in her first six months, and she expanded eligibility for the county''s DWI diversion program. She frames much of the jail population as people who need help rather than detention, while maintaining that those who pose a genuine threat belong in custody.',
   ARRAY['https://austinmonitor.com/stories/2022/01/county-attorney-garzas-first-priority-is-public-safety/']),
  ('f7583cbb-70e8-42ee-a0c9-f6e07ca41ec1', 'economic-development', 3,
   'Travillion describes property tax rebates as Travis County''s chief tool for attracting employers, but says the Commissioners Court attaches conditions: companies receiving rebates are expected to hire significant numbers of local residents, including people who are unemployed or underemployed, and to offer certain benefits. He pairs this with workforce development work through the local workforce board and says he holds rebate recipients accountable. That is targeted incentives carrying community benefit and job quality requirements, not open-ended competition for any large employer.',
   ARRAY['https://austinmonitor.com/stories/2023/01/travillion-charting-the-path-to-job-opportunity-for-county-residents/', 'https://austinmonitor.com/stories/2021/10/panelists-look-at-impacts-opportunities-brought-by-tesla-and-other-major-projects/']),
  ('8feee56c-d748-4ad8-9c4c-01a363bf1fc1', 'jail-capacity', 2,
   'Garza was elected Travis County District Attorney in 2020 and re-nominated in the 2024 Democratic primary on a platform of diverting more people accused of crimes away from jail, prosecuting police misconduct and investigating more sexual assault cases than his predecessor, and the Austin Monitor reports he has done so. His office runs decarceration-oriented programmes including a Conviction Integrity Unit that reviews claims of wrongful conviction and annual expunction expos that clear eligible Travis County arrest records, which his office frames as removing barriers to employment, housing and financial aid. His documented approach reduces who is held through diversion and case screening rather than through added jail capacity.',
   ARRAY['https://austinmonitor.com/stories/2024/03/travis-county-da-jose-garza-maintains-a-commanding-30-plus-point-lead-over-jeremy-sylestine/', 'https://districtattorney.traviscountytx.gov/about-us/special-initiatives/'])
),
resolved AS (
  SELECT s.politician_id::uuid AS pid, t.id AS tid, s.value::numeric AS val, s.reasoning, s.sources
  FROM src s JOIN inform.compass_topics t ON t.topic_key = s.topic_key AND t.is_live = true
),
ins_a AS (
  INSERT INTO inform.politician_answers (politician_id, topic_id, value)
  SELECT pid, tid, val FROM resolved
  ON CONFLICT (politician_id, topic_id) DO NOTHING
  RETURNING 1
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT pid, tid, reasoning, sources FROM resolved
ON CONFLICT (politician_id, topic_id) DO NOTHING;

DO $$
DECLARE v_answers int; v_context int; v_orphan int;
BEGIN
  SELECT count(*) INTO v_answers
    FROM inform.politician_answers a
   WHERE a.politician_id IN (
     'd0e80e1b-32d3-4b10-9fd1-e90afc412a12','e0d9989c-af22-42a5-a6b0-f77073d20386',
     'ccaf36cf-65a7-43d4-9f6e-6d8071b5f8bd','193123e1-8c6b-48b4-9581-2305ba4128b2',
     'f7583cbb-70e8-42ee-a0c9-f6e07ca41ec1','8feee56c-d748-4ad8-9c4c-01a363bf1fc1');
  IF v_answers <> 8 THEN
    RAISE EXCEPTION 'Expected 8 Travis County stances, found %', v_answers;
  END IF;

  -- Every answer must carry its public-facing reasoning. A value with no reasoning ships a chair
  -- the voter cannot interrogate.
  SELECT count(*) INTO v_context
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id
   WHERE a.politician_id IN (
     'd0e80e1b-32d3-4b10-9fd1-e90afc412a12','e0d9989c-af22-42a5-a6b0-f77073d20386',
     'ccaf36cf-65a7-43d4-9f6e-6d8071b5f8bd','193123e1-8c6b-48b4-9581-2305ba4128b2',
     'f7583cbb-70e8-42ee-a0c9-f6e07ca41ec1','8feee56c-d748-4ad8-9c4c-01a363bf1fc1')
     AND btrim(coalesce(c.reasoning,'')) <> '' AND coalesce(array_length(c.sources,1),0) > 0;
  IF v_context <> 8 THEN
    RAISE EXCEPTION 'Expected 8 Travis County contexts with reasoning AND sources, found %', v_context;
  END IF;

  -- No context row may exist for these people without a matching answer (the ORPHAN_CONTEXT class).
  SELECT count(*) INTO v_orphan
    FROM inform.politician_context c
   WHERE c.politician_id IN (
     'd0e80e1b-32d3-4b10-9fd1-e90afc412a12','e0d9989c-af22-42a5-a6b0-f77073d20386',
     'ccaf36cf-65a7-43d4-9f6e-6d8071b5f8bd','193123e1-8c6b-48b4-9581-2305ba4128b2',
     'f7583cbb-70e8-42ee-a0c9-f6e07ca41ec1','8feee56c-d748-4ad8-9c4c-01a363bf1fc1')
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                      WHERE a.politician_id = c.politician_id AND a.topic_id = c.topic_id);
  IF v_orphan <> 0 THEN
    RAISE EXCEPTION '% orphaned Travis County context row(s) with no answer', v_orphan;
  END IF;

  RAISE NOTICE 'OK: 8 Travis County stances, all with reasoning and sources, no orphan context.';
END $$;

COMMIT;
