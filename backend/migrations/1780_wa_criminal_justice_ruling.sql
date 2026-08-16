-- 1780_wa_criminal_justice_ruling.sql
-- ⚖ OPERATOR RULING, 2026-08-15: "chair 3 for both — structure over inferred purpose."
--
-- The question, open since migration 1772 and restated in 1779: `judicial-criminal-justice` chair 1
-- is "helping the person change their life and stay out of trouble in the future" (a PURPOSE) and
-- chair 3 is "a mix: some accountability, some support, depending on what happened" (a STRUCTURE).
-- Washington's second-look statutes contain no findings and no intent section, so a reader must
-- either infer the purpose or read the structure. The operator ruled: read the structure.
--
-- Applied as a ladder ruling rather than a two-member fix, because the cohort rule says one
-- instrument seats all of its sponsors alike:
--   · 7 senators from SB 6074 (reinstituting parole, Dhingra prime) — the row left unseated in the
--     first pass of this sweep;
--   · 5 representatives from HB 1317 and HB 1229 (Hackney prime), the instruments that made this a
--     ladder problem rather than a one-member puzzle.
--
-- ── 🔑 THE RULING HAS A BOUNDARY, AND IT IS IN THE OPERATOR'S OWN WORDING ─────────────────────────
-- "Structure over INFERRED purpose" governs instruments that state no purpose. Where an act STATES
-- its purpose, that is evidence, not inference, and the stated purpose governs. HB 1239, the reentry
-- readiness act, is exactly that case: it finds that "reentry readiness reduces recidivism" and that
-- earned time is "the most effective means of incentivizing participation in rehabilitative
-- programming", and it extends graduated reentry so that people leaving long sentences get "an
-- extended transition period between total confinement and full independence". That is chair 1's text
-- — helping the person change their life and stay out of trouble in the future — asserted by the act
-- about itself. Its 7 sponsors are seated at chair 1, including three who also signed a second-look
-- statute: instrument A sets the floor, instrument B raises it, the pattern of migrations 1766, 1768
-- and 1769.
-- ⚠ Two instruments were read and deliberately did NOT move anyone: Nobles' SB 5182 (midwifery and
-- doula services for incarcerated pregnant people) and Simmons' HB 1233 (the ending forced labor
-- act). Both are conditions-of-confinement instruments. They say nothing about what matters when
-- someone breaks the law, which is what this ladder asks, so they are off it entirely — on-topic by
-- subject, not by rationale.
-- ⚠ Lovick's record contains the parole act AND two penalty-increase instruments (school-safety
-- penalties, enacted; eluding and resisting arrest, with vehicle forfeiture). He stays at chair 3,
-- and for him it is not a compromise: "a mix: some accountability, some support" is a literal
-- description of that record.
--
-- ── Hackney: a documented blank BECOMES an answer ─────────────────────────────────────────────────
-- Migration 1779 blanked him on this ladder pending exactly this ruling. His context row is REWRITTEN
-- from "Unable to place on this ladder" to the chair 3 reasoning and an answer is inserted. No answer
-- is deleted anywhere in this migration, so the answer-delete gate does not apply; the guards below
-- assert the row no longer reads as a blank, which is the mirror image of that check.
BEGIN;

CREATE TEMP TABLE cj_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='0097aee3-e409-44bc-ba20-121108c11ec7' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Manka Dhingra already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4991ee01-0a35-454f-bdf6-bb2f34cf1c30' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Noel Frame already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='47ac1908-3715-4599-82f6-606aaf2d9fe6' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: John Lovick already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='436194e1-479e-4066-8d99-f325fd6bb880' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: T''wina Nobles already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4218b4c2-d642-431e-a279-5aff5100379f' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Rebecca Saldaña already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='c09a622c-ec49-40e9-87db-ead331f5ab9e' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Yasmin Trudeau already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='1ff1e922-601b-45f3-a43d-2ef69220f54b' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lisa Wellman already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='447b684b-e885-42c9-9f32-7e6480cb5b98' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: David Hackney already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='de6d7929-66dd-4166-998a-479cfa264ce5' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Roger Goodman already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='370f9462-ed1d-4a83-b244-8bb593038444' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Tarra Simmons already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='ae61e4af-16a8-44d6-933a-c4826882e103' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Larry Springer already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='fab8170e-a747-41de-ad39-769d8e0dd901' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Gerry Pollet already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='45737b89-a83b-421f-9d6c-abc829c7eae0' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Beth Doglio already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='ab474e84-9ab1-46b1-954b-f49f237498bb' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Darya Farivar already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='73ad3771-798c-4855-a467-7c6269bca5fc' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Edwin Obras already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='6341053d-0580-4fbf-85ea-71ddb6b6f838' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Strom Peterson already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='5617115e-78d5-4480-9534-aa337612a285' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharon Wylie already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='945d0b44-3329-46b2-a39e-47f5fdddc6ed' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Timm Ormsby already has a judicial-criminal-justice answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='165640fd-99e3-4e1e-bd73-8df36e4ac1d6' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Natasha Hill already has a judicial-criminal-justice answer'; END IF;
  -- Hackney holds the 1779 blank and must still read as one before it is rewritten
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='447b684b-e885-42c9-9f32-7e6480cb5b98' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336'
     AND reasoning ~ '^Unable to place on this ladder';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: Hackney does not hold exactly one documented blank on this ladder (%)', n; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances WHERE topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND value IN (1,3);
  IF n <> 2 THEN RAISE EXCEPTION 'pre-check: chairs 1 and 3 are not both defined exactly once (%)', n; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND value=3 AND text ILIKE '%some accountability, some support%';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: chair 3 is no longer the mixed chair — re-read before seating'; END IF;
END $$;

UPDATE inform.politician_context
   SET reasoning = $r$Prime sponsor of HB 1317, which would let a person convicted of crimes committed before their 21st birthday petition the indeterminate sentence review board for release after 25 years — barred by a later conviction or a disqualifying serious infraction, with the board weighing the youth's "chances of becoming rehabilitated" — and of HB 1229, which requires resentencing where a robbery in the second degree conviction was used to impose a persistent offender sentence. Neither act contains findings or an intent section, so they are placed on their structure — time served is the accountability, the petition is the support, and the disqualifiers are the "depending on what happened".$r$,
       sources   = ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1317.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1229.pdf']
 WHERE politician_id='447b684b-e885-42c9-9f32-7e6480cb5b98' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('0097aee3-e409-44bc-ba20-121108c11ec7','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Prime sponsor of SB 6074, which would reinstitute parole: a person who committed their offence before turning 18 may petition for release after serving 60 percent of the term, with life without parole, aggravated murder and sex offences excluded. The act contains no findings and no intent section, so it is placed on its structure — time served is the accountability, the petition is the support, and the exclusions are the "depending on what happened".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6074.pdf']),
('4991ee01-0a35-454f-bdf6-bb2f34cf1c30','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of SB 6074, which would reinstitute parole: a person who committed their offence before turning 18 may petition for release after serving 60 percent of the term, with life without parole, aggravated murder and sex offences excluded. The act contains no findings and no intent section, so it is placed on its structure — time served is the accountability, the petition is the support, and the exclusions are the "depending on what happened".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6074.pdf']),
('47ac1908-3715-4599-82f6-606aaf2d9fe6','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of SB 6074, which would reinstitute parole: a person who committed their offence before turning 18 may petition for release after serving 60 percent of the term, with life without parole, aggravated murder and sex offences excluded. The act contains no findings and no intent section, so it is placed on its structure — time served is the accountability, the petition is the support, and the exclusions are the "depending on what happened".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6074.pdf']),
('436194e1-479e-4066-8d99-f325fd6bb880','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of SB 6074, which would reinstitute parole: a person who committed their offence before turning 18 may petition for release after serving 60 percent of the term, with life without parole, aggravated murder and sex offences excluded. The act contains no findings and no intent section, so it is placed on its structure — time served is the accountability, the petition is the support, and the exclusions are the "depending on what happened".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6074.pdf']),
('4218b4c2-d642-431e-a279-5aff5100379f','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of SB 6074, which would reinstitute parole: a person who committed their offence before turning 18 may petition for release after serving 60 percent of the term, with life without parole, aggravated murder and sex offences excluded. The act contains no findings and no intent section, so it is placed on its structure — time served is the accountability, the petition is the support, and the exclusions are the "depending on what happened".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6074.pdf']),
('c09a622c-ec49-40e9-87db-ead331f5ab9e','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of SB 6074, which would reinstitute parole: a person who committed their offence before turning 18 may petition for release after serving 60 percent of the term, with life without parole, aggravated murder and sex offences excluded. The act contains no findings and no intent section, so it is placed on its structure — time served is the accountability, the petition is the support, and the exclusions are the "depending on what happened".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6074.pdf']),
('1ff1e922-601b-45f3-a43d-2ef69220f54b','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of SB 6074, which would reinstitute parole: a person who committed their offence before turning 18 may petition for release after serving 60 percent of the term, with life without parole, aggravated murder and sex offences excluded. The act contains no findings and no intent section, so it is placed on its structure — time served is the accountability, the petition is the support, and the exclusions are the "depending on what happened".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Senate%20Bills/6074.pdf']),
('de6d7929-66dd-4166-998a-479cfa264ce5','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of HB 1317, which would let a person convicted of crimes committed before their 21st birthday petition the indeterminate sentence review board for release after 25 years — barred by a later conviction or a disqualifying serious infraction, with the board weighing the youth's "chances of becoming rehabilitated" — and of HB 1229, which requires resentencing where a robbery in the second degree conviction was used to impose a persistent offender sentence. Neither act contains findings or an intent section, so they are placed on their structure — time served is the accountability, the petition is the support, and the disqualifiers are the "depending on what happened".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1317.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1229.pdf']),
('370f9462-ed1d-4a83-b244-8bb593038444','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of HB 1317, which would let a person convicted of crimes committed before their 21st birthday petition the indeterminate sentence review board for release after 25 years — barred by a later conviction or a disqualifying serious infraction, with the board weighing the youth's "chances of becoming rehabilitated" — and of HB 1229, which requires resentencing where a robbery in the second degree conviction was used to impose a persistent offender sentence. Neither act contains findings or an intent section, so they are placed on their structure — time served is the accountability, the petition is the support, and the disqualifiers are the "depending on what happened".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1317.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1229.pdf']),
('ae61e4af-16a8-44d6-933a-c4826882e103','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of HB 1317, which would let a person convicted of crimes committed before their 21st birthday petition the indeterminate sentence review board for release after 25 years — barred by a later conviction or a disqualifying serious infraction, with the board weighing the youth's "chances of becoming rehabilitated" — and of HB 1229, which requires resentencing where a robbery in the second degree conviction was used to impose a persistent offender sentence. Neither act contains findings or an intent section, so they are placed on their structure — time served is the accountability, the petition is the support, and the disqualifiers are the "depending on what happened".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1317.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1229.pdf']),
('fab8170e-a747-41de-ad39-769d8e0dd901','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of HB 1317, which would let a person convicted of crimes committed before their 21st birthday petition the indeterminate sentence review board for release after 25 years — barred by a later conviction or a disqualifying serious infraction, with the board weighing the youth's "chances of becoming rehabilitated" — and of HB 1229, which requires resentencing where a robbery in the second degree conviction was used to impose a persistent offender sentence. Neither act contains findings or an intent section, so they are placed on their structure — time served is the accountability, the petition is the support, and the disqualifiers are the "depending on what happened".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1317.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1229.pdf']),
('45737b89-a83b-421f-9d6c-abc829c7eae0','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Prime sponsor of HB 1239, the reentry readiness act, which expands earned release time and extends graduated reentry for the longest sentences. Unlike the second-look statutes, it STATES its purpose: "reentry readiness reduces recidivism", and "the availability of earned time is the most effective means of incentivizing participation in rehabilitative programming, which is critical for the purposes of increasing public safety and improving reentry outcomes". The act intends to give those who have served the longest sentences "an extended transition period between total confinement and full independence".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1239.pdf']),
('ab474e84-9ab1-46b1-954b-f49f237498bb','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of HB 1239, the reentry readiness act, which expands earned release time and extends graduated reentry for the longest sentences. Unlike the second-look statutes, it STATES its purpose: "reentry readiness reduces recidivism", and "the availability of earned time is the most effective means of incentivizing participation in rehabilitative programming, which is critical for the purposes of increasing public safety and improving reentry outcomes". The act intends to give those who have served the longest sentences "an extended transition period between total confinement and full independence".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1239.pdf']),
('73ad3771-798c-4855-a467-7c6269bca5fc','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of HB 1239, the reentry readiness act, which expands earned release time and extends graduated reentry for the longest sentences. Unlike the second-look statutes, it STATES its purpose: "reentry readiness reduces recidivism", and "the availability of earned time is the most effective means of incentivizing participation in rehabilitative programming, which is critical for the purposes of increasing public safety and improving reentry outcomes". The act intends to give those who have served the longest sentences "an extended transition period between total confinement and full independence".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1239.pdf']),
('6341053d-0580-4fbf-85ea-71ddb6b6f838','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of HB 1239, the reentry readiness act, which expands earned release time and extends graduated reentry for the longest sentences. Unlike the second-look statutes, it STATES its purpose: "reentry readiness reduces recidivism", and "the availability of earned time is the most effective means of incentivizing participation in rehabilitative programming, which is critical for the purposes of increasing public safety and improving reentry outcomes". The act intends to give those who have served the longest sentences "an extended transition period between total confinement and full independence".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1239.pdf']),
('5617115e-78d5-4480-9534-aa337612a285','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of HB 1239, the reentry readiness act, which expands earned release time and extends graduated reentry for the longest sentences. Unlike the second-look statutes, it STATES its purpose: "reentry readiness reduces recidivism", and "the availability of earned time is the most effective means of incentivizing participation in rehabilitative programming, which is critical for the purposes of increasing public safety and improving reentry outcomes". The act intends to give those who have served the longest sentences "an extended transition period between total confinement and full independence".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1239.pdf']),
('945d0b44-3329-46b2-a39e-47f5fdddc6ed','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of HB 1239, the reentry readiness act, which expands earned release time and extends graduated reentry for the longest sentences. Unlike the second-look statutes, it STATES its purpose: "reentry readiness reduces recidivism", and "the availability of earned time is the most effective means of incentivizing participation in rehabilitative programming, which is critical for the purposes of increasing public safety and improving reentry outcomes". The act intends to give those who have served the longest sentences "an extended transition period between total confinement and full independence".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1239.pdf']),
('165640fd-99e3-4e1e-bd73-8df36e4ac1d6','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Co-sponsor of HB 1239, the reentry readiness act, which expands earned release time and extends graduated reentry for the longest sentences. Unlike the second-look statutes, it STATES its purpose: "reentry readiness reduces recidivism", and "the availability of earned time is the most effective means of incentivizing participation in rehabilitative programming, which is critical for the purposes of increasing public safety and improving reentry outcomes". The act intends to give those who have served the longest sentences "an extended transition period between total confinement and full independence".$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1239.pdf']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('0097aee3-e409-44bc-ba20-121108c11ec7','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 3),
('4991ee01-0a35-454f-bdf6-bb2f34cf1c30','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 3),
('47ac1908-3715-4599-82f6-606aaf2d9fe6','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 3),
('436194e1-479e-4066-8d99-f325fd6bb880','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 3),
('4218b4c2-d642-431e-a279-5aff5100379f','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 3),
('c09a622c-ec49-40e9-87db-ead331f5ab9e','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 3),
('1ff1e922-601b-45f3-a43d-2ef69220f54b','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 3),
('447b684b-e885-42c9-9f32-7e6480cb5b98','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 3),
('de6d7929-66dd-4166-998a-479cfa264ce5','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 3),
('370f9462-ed1d-4a83-b244-8bb593038444','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 3),
('ae61e4af-16a8-44d6-933a-c4826882e103','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 3),
('fab8170e-a747-41de-ad39-769d8e0dd901','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 3),
('45737b89-a83b-421f-9d6c-abc829c7eae0','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 1),
('ab474e84-9ab1-46b1-954b-f49f237498bb','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 1),
('73ad3771-798c-4855-a467-7c6269bca5fc','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 1),
('6341053d-0580-4fbf-85ea-71ddb6b6f838','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 1),
('5617115e-78d5-4480-9534-aa337612a285','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 1),
('945d0b44-3329-46b2-a39e-47f5fdddc6ed','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 1),
('165640fd-99e3-4e1e-bd73-8df36e4ac1d6','9db07b16-1076-4b7d-ad89-ebe7b51f4336', 1);

DO $$
DECLARE ans_after int; ctx_after int; s record; bad int; c3 int; c1 int;
BEGIN
  SELECT * INTO s FROM cj_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 19 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +19', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 18 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +18 (Hackney is UPDATED, not inserted)', s.ctx_before, ctx_after; END IF;

  -- chair 3 side: the structural reading must be visible in the prose, both sides asserted separately
  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND a.politician_id IN ('0097aee3-e409-44bc-ba20-121108c11ec7','4991ee01-0a35-454f-bdf6-bb2f34cf1c30','47ac1908-3715-4599-82f6-606aaf2d9fe6','436194e1-479e-4066-8d99-f325fd6bb880','4218b4c2-d642-431e-a279-5aff5100379f','c09a622c-ec49-40e9-87db-ead331f5ab9e','1ff1e922-601b-45f3-a43d-2ef69220f54b','447b684b-e885-42c9-9f32-7e6480cb5b98','de6d7929-66dd-4166-998a-479cfa264ce5','370f9462-ed1d-4a83-b244-8bb593038444','ae61e4af-16a8-44d6-933a-c4826882e103','fab8170e-a747-41de-ad39-769d8e0dd901')
     AND (a.value <> 3
          OR c.reasoning !~ 'intent section'
          OR c.reasoning !~ 'depending on what happened'
          OR c.reasoning ~ '^Unable to place');
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % chair-3 row(s) wrong chair, missing the structural reasoning, or still reading as a blank', bad; END IF;

  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND a.politician_id IN ('45737b89-a83b-421f-9d6c-abc829c7eae0','ab474e84-9ab1-46b1-954b-f49f237498bb','73ad3771-798c-4855-a467-7c6269bca5fc','6341053d-0580-4fbf-85ea-71ddb6b6f838','5617115e-78d5-4480-9534-aa337612a285','945d0b44-3329-46b2-a39e-47f5fdddc6ed','165640fd-99e3-4e1e-bd73-8df36e4ac1d6')
     AND (a.value <> 1
          OR c.reasoning !~ 'reentry readiness reduces recidivism'
          OR NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1239.pdf' = ANY(c.sources)));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % chair-1 row(s) wrong chair, missing the stated purpose, or missing HB 1239', bad; END IF;

  SELECT count(*) INTO c3 FROM inform.politician_answers WHERE topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND value=3 AND politician_id IN ('0097aee3-e409-44bc-ba20-121108c11ec7','4991ee01-0a35-454f-bdf6-bb2f34cf1c30','47ac1908-3715-4599-82f6-606aaf2d9fe6','436194e1-479e-4066-8d99-f325fd6bb880','4218b4c2-d642-431e-a279-5aff5100379f','c09a622c-ec49-40e9-87db-ead331f5ab9e','1ff1e922-601b-45f3-a43d-2ef69220f54b','447b684b-e885-42c9-9f32-7e6480cb5b98','de6d7929-66dd-4166-998a-479cfa264ce5','370f9462-ed1d-4a83-b244-8bb593038444','ae61e4af-16a8-44d6-933a-c4826882e103','fab8170e-a747-41de-ad39-769d8e0dd901');
  SELECT count(*) INTO c1 FROM inform.politician_answers WHERE topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND value=1 AND politician_id IN ('45737b89-a83b-421f-9d6c-abc829c7eae0','ab474e84-9ab1-46b1-954b-f49f237498bb','73ad3771-798c-4855-a467-7c6269bca5fc','6341053d-0580-4fbf-85ea-71ddb6b6f838','5617115e-78d5-4480-9534-aa337612a285','945d0b44-3329-46b2-a39e-47f5fdddc6ed','165640fd-99e3-4e1e-bd73-8df36e4ac1d6');
  IF c3 <> 12 THEN RAISE EXCEPTION 'guard 2: chair-3 count is %, expected 12', c3; END IF;
  IF c1 <> 7 THEN RAISE EXCEPTION 'guard 2: chair-1 count is %, expected 7', c1; END IF;

  -- Hackney specifically: no longer a blank, now an answer
  SELECT count(*) INTO bad FROM inform.politician_context
   WHERE politician_id='447b684b-e885-42c9-9f32-7e6480cb5b98' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND reasoning ~ '^Unable to place';
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: Hackney still reads as a documented blank'; END IF;
END $$;

DO $$
DECLARE orphans int; ans_wo_ctx int;
BEGIN
  SELECT count(*) INTO orphans
    FROM inform.politician_context pc
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pa.politician_id IS NULL
     AND coalesce(cardinality(pc.sources), 0) > 0
     AND pc.reasoning !~* '^researched\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF orphans <> 50 THEN RAISE EXCEPTION 'guard 3: ORPHAN_CONTEXT is %, expected 50', orphans; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: % answer(s) have no context', ans_wo_ctx; END IF;

  RAISE NOTICE 'judicial-criminal-justice: 12 at chair 3, 7 at chair 1; Hackney blank converted; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
