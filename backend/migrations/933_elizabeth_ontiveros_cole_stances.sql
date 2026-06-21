-- 933_elizabeth_ontiveros_cole_stances.sql — Phase 147 Wave 4 — AUDIT-ONLY (NOT registered in schema_migrations)
-- Elizabeth Ontiveros-Cole (D4, external_id -700658). Evidence-only chairs; 100% citation; no judicial topics.
DO $do$
DECLARE pid uuid;
BEGIN
  SELECT id INTO pid FROM essentials.politicians WHERE external_id = -700658;

  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
    (pid,'b9ccee94-ad96-4f10-b655-889d8e5abe92',1),
    (pid,'669cac97-66a6-4087-b036-936fbe62efb3',3),
    (pid,'eb3d1247-0de1-4b7f-baec-7259861efd53',3),
    (pid,'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',5)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
    (pid,'b9ccee94-ad96-4f10-b655-889d8e5abe92',$$On April 6 2026 the council UNANIMOUSLY adopted a resolution barring DHS/ICE from using any city-owned property to organize or stage civil immigration enforcement — meaning she voted yes, affirmatively withholding city resources from ICE.$$,ARRAY['https://thepolypost.com/news/2026/04/14/pomona-adopts-ice-resolution/','https://claremont-courier.com/latest-news/public-hearing-documents-alleged-ice-abuses-in-pomona-88339/']),
    (pid,'669cac97-66a6-4087-b036-936fbe62efb3',$$Her official record states she 'prioritized the development of 96 affordable housing units' in District 4 — supporting targeted affordable-housing projects/permits rather than public housing or rent caps/inclusionary mandates.$$,ARRAY['https://www.pomonaca.gov/government/mayor-city-council/councilmember-elizabeth-ontiveros-cole','https://ballotpedia.org/Elizabeth_Ontiveros-Cole_(Pomona_City_Council_District_4,_California,_candidate_2024)']),
    (pid,'eb3d1247-0de1-4b7f-baec-7259861efd53',$$Emphasizes recruiting specific community-benefit projects to District 4 — accelerating an Aldi grocery store and establishing the East Valley Medical Clinic — and 'protecting local businesses and local jobs,' a targeted community-benefit approach rather than blanket abatements.$$,ARRAY['https://www.pomonaca.gov/government/mayor-city-council/councilmember-elizabeth-ontiveros-cole','https://ballotpedia.org/Elizabeth_Ontiveros-Cole_(Pomona_City_Council_District_4,_California,_candidate_2024)']),
    (pid,'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',$$On Oct 21 2025 she voted NO (4-3) on the permanent rent stabilization ordinance and rental registry, and The Pomonan reports she 'often frames herself as an advocate for small landlords, repeating the same government overreach lines' — a documented anti-rent-regulation position. (She later abstained on the Nov 17 final passage, which complicates but does not negate the Oct 21 no vote and small-landlord framing.)$$,ARRAY['https://members.aagla.org/news/victory-alert-pomona-rejects-rental-registry-and-reconsiders-rent-stabilization','https://www.thepomonan.com/theopera/2025/10/28/pomona-city-council-quietly-reverses-course-on-rent-cap-ordinance'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
END $do$;
