-- Migration 1181: Michael "Mike" Marshall (City Councilor, Forest Grove OR) compass stances — AUDIT-ONLY (not registered in the ledger)
-- Evidence-only; 100% cited; chairs model (value 1-5); 3 cited stances; blank spokes omitted.
-- topic_id resolved LIVE via JOIN on compass_topics.topic_key AND is_live=true (no hardcoded topic UUIDs).

BEGIN;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('homelessness', 3, 'Marshall, elected in November 2022 and seated on the seven-member council in January 2023, joined the unanimous 7-0 first-reading vote (June 12, 2023) adopting Forest Grove''s "time, place and manner" camping ordinance (Ordinance 2023-04), which prohibits camping in parks and restricts overnight camping to the designated City Hall South Lot between 7 p.m. and 7 a.m., drafted to satisfy Oregon''s HB 3115 requirement that cities set "objectively reasonable" rules for where camping is allowed when shelter is unavailable — the statewide codification that people cannot be punished for sleeping outside with no alternative. His official city bio says he "works towards solutions for those suffering from homelessness," with the goal "to help them be contributing members of their community" — moving people from public spaces toward stability rather than either blanket criminalization or unrestricted camping. Enforcement conditioned on the shelter-availability standard with a designated permitted location matches the allow-enforcement-only-with-adequate-alternatives chair, not a blanket criminal ban and not a protected right to camp anywhere.', ARRAY['https://hillsboronewstimes.com/2023/06/21/forest-grove-residents-blast-city-council-for-overnight-camping-regulations/', 'https://www.forestgrove-or.gov/611/Meet-the-Council']::text[]),
    ('homelessness-response', 3, 'On January 22, 2024 Marshall joined the unanimous council vote denying the appeal against the Forest Grove Foundation''s transitional homeless pod village (12-16 sleeping pods with lighting, electrical outlets, and radiant heating, plus a common building with kitchen, restrooms, showers, and laundry at 2500 22nd Ave), advancing a services-centered transitional-shelter project with three to four full-time-equivalent managers. His official city bio states he "works towards solutions for those suffering from homelessness, to help them be contributing members of their community." Pairing that shelter-and-services investment with the June 2023 camping regulations he voted for matches the invest-in-outreach-shelter-and-mental-health-services-while-enforcing-reasonable-public-space-rules chair, not housing-first-without-enforcement and not enforcement-as-the-primary-tool.', ARRAY['https://forestgrovenewstimes.com/2024/01/26/plans-for-new-forest-grove-homeless-pod-village-moves-forward-council-denies-appeal/', 'https://www.forestgrove-or.gov/611/Meet-the-Council']::text[]),
    ('local-immigration', 2, 'Marshall joined the unanimous November 10, 2025 council vote declaring a state of emergency over federal immigration raids, authorizing the city manager to allocate up to $50,000 for community-based organizations serving impacted residents, and on January 12, 2026 he voted with the 6-1 majority (Councilor Martinez the lone dissent on the seven-member council) to codify Oregon''s Sanctuary Promise Act into Forest Grove''s municipal code — barring city resources from assisting federal immigration enforcement, directing new staff policies and training, establishing reporting requirements, and defining "nonpublic" areas of city facilities that federal agents cannot enter without a warrant. Voting to codify protections that limit cooperation to what a warrant or court order compels, while funding aid to affected residents, matches the comply-only-with-court-ordered-cooperation-and-protect-residents chair — stronger than passive non-use of city resources, but short of a documented refusal of all detainers.', ARRAY['https://hillsboronewstimes.com/2026/01/14/forest-grove-affirms-its-a-sanctuary-city-in-6-1-vote-will-develop-new-internal-ice-policies/', 'https://forestgrovenewstimes.com/2025/11/11/forest-grove-declares-state-of-emergency-over-ice-raids/']::text[])
)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT 'acef8291-5eeb-43b9-905d-ac5ede610223'::uuid, ct.id, s.val
FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

WITH s(topic_key, val, reasoning, sources) AS (
  VALUES
    ('homelessness', 3, 'Marshall, elected in November 2022 and seated on the seven-member council in January 2023, joined the unanimous 7-0 first-reading vote (June 12, 2023) adopting Forest Grove''s "time, place and manner" camping ordinance (Ordinance 2023-04), which prohibits camping in parks and restricts overnight camping to the designated City Hall South Lot between 7 p.m. and 7 a.m., drafted to satisfy Oregon''s HB 3115 requirement that cities set "objectively reasonable" rules for where camping is allowed when shelter is unavailable — the statewide codification that people cannot be punished for sleeping outside with no alternative. His official city bio says he "works towards solutions for those suffering from homelessness," with the goal "to help them be contributing members of their community" — moving people from public spaces toward stability rather than either blanket criminalization or unrestricted camping. Enforcement conditioned on the shelter-availability standard with a designated permitted location matches the allow-enforcement-only-with-adequate-alternatives chair, not a blanket criminal ban and not a protected right to camp anywhere.', ARRAY['https://hillsboronewstimes.com/2023/06/21/forest-grove-residents-blast-city-council-for-overnight-camping-regulations/', 'https://www.forestgrove-or.gov/611/Meet-the-Council']::text[]),
    ('homelessness-response', 3, 'On January 22, 2024 Marshall joined the unanimous council vote denying the appeal against the Forest Grove Foundation''s transitional homeless pod village (12-16 sleeping pods with lighting, electrical outlets, and radiant heating, plus a common building with kitchen, restrooms, showers, and laundry at 2500 22nd Ave), advancing a services-centered transitional-shelter project with three to four full-time-equivalent managers. His official city bio states he "works towards solutions for those suffering from homelessness, to help them be contributing members of their community." Pairing that shelter-and-services investment with the June 2023 camping regulations he voted for matches the invest-in-outreach-shelter-and-mental-health-services-while-enforcing-reasonable-public-space-rules chair, not housing-first-without-enforcement and not enforcement-as-the-primary-tool.', ARRAY['https://forestgrovenewstimes.com/2024/01/26/plans-for-new-forest-grove-homeless-pod-village-moves-forward-council-denies-appeal/', 'https://www.forestgrove-or.gov/611/Meet-the-Council']::text[]),
    ('local-immigration', 2, 'Marshall joined the unanimous November 10, 2025 council vote declaring a state of emergency over federal immigration raids, authorizing the city manager to allocate up to $50,000 for community-based organizations serving impacted residents, and on January 12, 2026 he voted with the 6-1 majority (Councilor Martinez the lone dissent on the seven-member council) to codify Oregon''s Sanctuary Promise Act into Forest Grove''s municipal code — barring city resources from assisting federal immigration enforcement, directing new staff policies and training, establishing reporting requirements, and defining "nonpublic" areas of city facilities that federal agents cannot enter without a warrant. Voting to codify protections that limit cooperation to what a warrant or court order compels, while funding aid to affected residents, matches the comply-only-with-court-ordered-cooperation-and-protect-residents chair — stronger than passive non-use of city resources, but short of a documented refusal of all detainers.', ARRAY['https://hillsboronewstimes.com/2026/01/14/forest-grove-affirms-its-a-sanctuary-city-in-6-1-vote-will-develop-new-internal-ice-policies/', 'https://forestgrovenewstimes.com/2025/11/11/forest-grove-declares-state-of-emergency-over-ice-raids/']::text[])
)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT 'acef8291-5eeb-43b9-905d-ac5ede610223'::uuid, ct.id, s.reasoning, s.sources
FROM s JOIN inform.compass_topics ct ON ct.topic_key = s.topic_key AND ct.is_live = true
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

DO $$
DECLARE n INTEGER;
        v_ext BIGINT;
BEGIN
  -- Identity gate (WR-01): the hardcoded politician UUID must belong to the
  -- intended official's external_id — a wrong-but-existing UUID would satisfy
  -- the FK and the count gate below while silently misattributing stances.
  SELECT external_id INTO v_ext FROM essentials.politicians WHERE id = 'acef8291-5eeb-43b9-905d-ac5ede610223';
  IF v_ext IS DISTINCT FROM -4126202 THEN
    RAISE EXCEPTION 'UUID acef8291-5eeb-43b9-905d-ac5ede610223 does not belong to external_id -4126202 (Michael Marshall) — found %', v_ext;
  END IF;
  SELECT COUNT(*) INTO n FROM inform.politician_answers WHERE politician_id = 'acef8291-5eeb-43b9-905d-ac5ede610223';
  IF n <> 3 THEN
    RAISE EXCEPTION 'Expected % answers, found % — topic_key mismatch dropped rows', 3, n;
  END IF;
  -- Context-parity gate (WR-03): the context VALUES list is a verbatim
  -- duplicate of the answers list; count it too so a single-sided edit
  -- cannot silently drop or skew reasoning/sources rows.
  SELECT COUNT(*) INTO n FROM inform.politician_context WHERE politician_id = 'acef8291-5eeb-43b9-905d-ac5ede610223';
  IF n <> 3 THEN
    RAISE EXCEPTION 'Expected % context rows, found % — answers/context VALUES lists diverged', 3, n;
  END IF;
END $$;

COMMIT;
