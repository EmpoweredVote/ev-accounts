-- 1779_wa_house_democrats.sql
-- 14 rows on `public-safety-approach` at chair 4 from ESHB 2015, and 3 DOCUMENTED BLANKS closing
-- the House Democrats. Speaker Jinkins gets nothing, for the reason migration 1778 gave for
-- Stokesbary.
--
-- ── ESHB 2015, and why it is chair 4 even though it funds co-response ─────────────────────────────
-- The enacted act creates a local law enforcement grant program for "hiring, retaining, and training
-- law enforcement officers, PEER COUNSELORS, AND BEHAVIORAL HEALTH PERSONNEL WORKING IN CO-RESPONSE",
-- funds it from a new supplemental criminal justice account, and conditions a locality's share on
-- imposing a local option public safety sales tax.
-- 🔑 Note the enacted text differs from the introduced bill, which funded officers only. The
-- co-response personnel were added in the legislative process, so a cohort seated from the introduced
-- version would have been reasoning about a different act. Read the session law.
--   · chair 4 ("increase police staffing, equipment, and pay") — the act increases staffing and pay
--     and raises the money to do it;
--   · chair 3 ("KEEP CURRENT public safety funding while adding crisis response teams") — refuted, it
--     adds funding rather than holding it;
--   · chair 2 ("MAINTAIN current police staffing but shift non-violent calls to unarmed mental health
--     co-responders") — refuted twice over: staffing rises, and co-response here means clinicians
--     working WITH officers, not instead of them;
--   · chair 5 ("make expanding the police budget the TOP SPENDING PRIORITY over other services") —
--     nothing ranks police against other spending; the local tax is optional and voter-facing.
-- ⚠ This is the migration 1771 problem inside a SINGLE instrument, and it is the clearest example yet
-- for the ladder owner: one enacted act funds more officers AND more co-response, and chairs 2 and 3
-- both forbid that combination by opening with maintain/keep-current. Chair 4 survives because it
-- claims no exclusivity — contradiction blanks a chair, incompleteness does not.
--
-- Gerry Pollet is a sponsor and is deliberately NOT written here: he already holds this exact chair
-- from HB 1435 in migration 1771. Same chair, different instrument, so there is nothing to add and a
-- second row would double-count him.
--
-- ── the three blanks ─────────────────────────────────────────────────────────────────────────────
-- 🔴 HACKNEY REPRODUCES THE OPEN DHINGRA QUESTION, WHICH MAKES IT A LADDER PROBLEM RATHER THAN A
-- ONE-MEMBER PUZZLE. His HB 1317 (early release petitions for offences committed before 21) and
-- HB 1229 (resentencing where robbery 2 drove a persistent offender sentence) contain NO findings and
-- NO intent section. `judicial-criminal-justice` chair 1 is "helping the person change their life"
-- and chair 3 is "a mix: some accountability, some support, depending on what happened" — and a
-- second-look statute is structurally both: time served is the accountability, the petition is the
-- support, the disqualifiers are the "depending on what happened". Manka Dhingra's SB 6074 was left
-- unseated for exactly this reason and is still open. Two members now turn on one ruling; it is worth
-- making once, deliberately, rather than per member.
-- Bronoske and Hall are the "defending what exists" and "authorising without funding" shapes the
-- trouble-spot log now opens with.
BEGIN;

CREATE TEMP TABLE hd_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='be3c2a24-1576-4636-9374-18fc77a8513f' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Amy Walen already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='ec9da15f-7d79-42bc-a368-da3ab0855ddf' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: April Berg already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='45737b89-a83b-421f-9d6c-abc829c7eae0' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Beth Doglio already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='40ae39e3-8e86-46a5-b660-96b46a3e6c02' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Brandy Donaghy already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='d8adabde-90dd-49e7-870c-1f2ae7c5e6d3' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chris Stearns already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='628a26a2-bcb9-4e87-a29f-ac5f6b381a37' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Debra Entenman already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='73ad3771-798c-4855-a467-7c6269bca5fc' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Edwin Obras already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='cf992e89-7b96-46f3-9999-58432c690fe4' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Kristine Reeves already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='30fdeba0-e9d3-414d-859f-2941140d8e80' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lisa Parshley already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='1a53e3c7-3c47-450b-a04d-a2128288b868' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Melanie Morgan already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='1963d6e9-069b-4770-9489-59e36faaa2e1' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: My-Linh Thai already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4b5055b4-2ed1-4894-acae-0e1465159564' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Osman Salahuddin already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='3efc8925-9612-4601-aed5-c05234a5e64d' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Rob Chase already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='d5c6e6e4-c474-41fa-ab96-bd237c8ff4de' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sharon Tomiko Santos already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='447b684b-e885-42c9-9f32-7e6480cb5b98' AND topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: David Hackney already has a judicial-criminal-justice context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_topics
   WHERE id='9db07b16-1076-4b7d-ad89-ebe7b51f4336' AND topic_key='judicial-criminal-justice' AND is_live AND is_active;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: judicial-criminal-justice topic id does not resolve to a live topic'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='55631a34-52aa-4806-9af6-1220fcf65ca5' AND topic_id='e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Dan Bronoske already has a healthcare context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_topics
   WHERE id='e8dad4a8-eb93-4931-91f5-d8fb5d7dd529' AND topic_key='healthcare' AND is_live AND is_active;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: healthcare topic id does not resolve to a live topic'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='2026df33-5726-4d18-8f17-1882e49893fa' AND topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Zach Hall already has a climate-change context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_topics
   WHERE id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c' AND topic_key='climate-change' AND is_live AND is_active;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: climate-change topic id does not resolve to a live topic'; END IF;
  -- Pollet must already hold chair 4 from migration 1771, and must not be written again
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='fab8170e-a747-41de-ad39-769d8e0dd901' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85' AND value=4;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: Pollet does not hold exactly one public-safety chair-4 row (%)', n; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('be3c2a24-1576-4636-9374-18fc77a8513f','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of ESHB 2015 (Chapter law, 2025), which creates a local law enforcement grant program "for the purpose of providing direct support to local and tribal law enforcement agencies in hiring, retaining, and training law enforcement officers, peer counselors, and behavioral health personnel working in co-response to increase community policing and public safety", funds it through a new supplemental criminal justice account distributed per capita, and authorizes a local option public safety sales tax that a city or county must impose to qualify.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2015-S.SL.pdf']),
('ec9da15f-7d79-42bc-a368-da3ab0855ddf','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of ESHB 2015 (Chapter law, 2025), which creates a local law enforcement grant program "for the purpose of providing direct support to local and tribal law enforcement agencies in hiring, retaining, and training law enforcement officers, peer counselors, and behavioral health personnel working in co-response to increase community policing and public safety", funds it through a new supplemental criminal justice account distributed per capita, and authorizes a local option public safety sales tax that a city or county must impose to qualify.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2015-S.SL.pdf']),
('45737b89-a83b-421f-9d6c-abc829c7eae0','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of ESHB 2015 (Chapter law, 2025), which creates a local law enforcement grant program "for the purpose of providing direct support to local and tribal law enforcement agencies in hiring, retaining, and training law enforcement officers, peer counselors, and behavioral health personnel working in co-response to increase community policing and public safety", funds it through a new supplemental criminal justice account distributed per capita, and authorizes a local option public safety sales tax that a city or county must impose to qualify.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2015-S.SL.pdf']),
('40ae39e3-8e86-46a5-b660-96b46a3e6c02','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of ESHB 2015 (Chapter law, 2025), which creates a local law enforcement grant program "for the purpose of providing direct support to local and tribal law enforcement agencies in hiring, retaining, and training law enforcement officers, peer counselors, and behavioral health personnel working in co-response to increase community policing and public safety", funds it through a new supplemental criminal justice account distributed per capita, and authorizes a local option public safety sales tax that a city or county must impose to qualify.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2015-S.SL.pdf']),
('d8adabde-90dd-49e7-870c-1f2ae7c5e6d3','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of ESHB 2015 (Chapter law, 2025), which creates a local law enforcement grant program "for the purpose of providing direct support to local and tribal law enforcement agencies in hiring, retaining, and training law enforcement officers, peer counselors, and behavioral health personnel working in co-response to increase community policing and public safety", funds it through a new supplemental criminal justice account distributed per capita, and authorizes a local option public safety sales tax that a city or county must impose to qualify.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2015-S.SL.pdf']),
('628a26a2-bcb9-4e87-a29f-ac5f6b381a37','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Prime sponsor of ESHB 2015 (Chapter law, 2025), which creates a local law enforcement grant program "for the purpose of providing direct support to local and tribal law enforcement agencies in hiring, retaining, and training law enforcement officers, peer counselors, and behavioral health personnel working in co-response to increase community policing and public safety", funds it through a new supplemental criminal justice account distributed per capita, and authorizes a local option public safety sales tax that a city or county must impose to qualify.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2015-S.SL.pdf']),
('73ad3771-798c-4855-a467-7c6269bca5fc','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of ESHB 2015 (Chapter law, 2025), which creates a local law enforcement grant program "for the purpose of providing direct support to local and tribal law enforcement agencies in hiring, retaining, and training law enforcement officers, peer counselors, and behavioral health personnel working in co-response to increase community policing and public safety", funds it through a new supplemental criminal justice account distributed per capita, and authorizes a local option public safety sales tax that a city or county must impose to qualify.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2015-S.SL.pdf']),
('cf992e89-7b96-46f3-9999-58432c690fe4','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of ESHB 2015 (Chapter law, 2025), which creates a local law enforcement grant program "for the purpose of providing direct support to local and tribal law enforcement agencies in hiring, retaining, and training law enforcement officers, peer counselors, and behavioral health personnel working in co-response to increase community policing and public safety", funds it through a new supplemental criminal justice account distributed per capita, and authorizes a local option public safety sales tax that a city or county must impose to qualify.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2015-S.SL.pdf']),
('30fdeba0-e9d3-414d-859f-2941140d8e80','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of ESHB 2015 (Chapter law, 2025), which creates a local law enforcement grant program "for the purpose of providing direct support to local and tribal law enforcement agencies in hiring, retaining, and training law enforcement officers, peer counselors, and behavioral health personnel working in co-response to increase community policing and public safety", funds it through a new supplemental criminal justice account distributed per capita, and authorizes a local option public safety sales tax that a city or county must impose to qualify.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2015-S.SL.pdf']),
('1a53e3c7-3c47-450b-a04d-a2128288b868','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of ESHB 2015 (Chapter law, 2025), which creates a local law enforcement grant program "for the purpose of providing direct support to local and tribal law enforcement agencies in hiring, retaining, and training law enforcement officers, peer counselors, and behavioral health personnel working in co-response to increase community policing and public safety", funds it through a new supplemental criminal justice account distributed per capita, and authorizes a local option public safety sales tax that a city or county must impose to qualify.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2015-S.SL.pdf']),
('1963d6e9-069b-4770-9489-59e36faaa2e1','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of ESHB 2015 (Chapter law, 2025), which creates a local law enforcement grant program "for the purpose of providing direct support to local and tribal law enforcement agencies in hiring, retaining, and training law enforcement officers, peer counselors, and behavioral health personnel working in co-response to increase community policing and public safety", funds it through a new supplemental criminal justice account distributed per capita, and authorizes a local option public safety sales tax that a city or county must impose to qualify.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2015-S.SL.pdf']),
('4b5055b4-2ed1-4894-acae-0e1465159564','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of ESHB 2015 (Chapter law, 2025), which creates a local law enforcement grant program "for the purpose of providing direct support to local and tribal law enforcement agencies in hiring, retaining, and training law enforcement officers, peer counselors, and behavioral health personnel working in co-response to increase community policing and public safety", funds it through a new supplemental criminal justice account distributed per capita, and authorizes a local option public safety sales tax that a city or county must impose to qualify.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2015-S.SL.pdf']),
('3efc8925-9612-4601-aed5-c05234a5e64d','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of ESHB 2015 (Chapter law, 2025), which creates a local law enforcement grant program "for the purpose of providing direct support to local and tribal law enforcement agencies in hiring, retaining, and training law enforcement officers, peer counselors, and behavioral health personnel working in co-response to increase community policing and public safety", funds it through a new supplemental criminal justice account distributed per capita, and authorizes a local option public safety sales tax that a city or county must impose to qualify.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2015-S.SL.pdf']),
('d5c6e6e4-c474-41fa-ab96-bd237c8ff4de','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of ESHB 2015 (Chapter law, 2025), which creates a local law enforcement grant program "for the purpose of providing direct support to local and tribal law enforcement agencies in hiring, retaining, and training law enforcement officers, peer counselors, and behavioral health personnel working in co-response to increase community policing and public safety", funds it through a new supplemental criminal justice account distributed per capita, and authorizes a local option public safety sales tax that a city or county must impose to qualify.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2015-S.SL.pdf']),
('447b684b-e885-42c9-9f32-7e6480cb5b98','9db07b16-1076-4b7d-ad89-ebe7b51f4336',
 $r$Unable to place on this ladder. Prime sponsor of HB 1317, which would let a person convicted of crimes committed before their 21st birthday petition the indeterminate sentence review board for early release after 25 years, barred if they have a later conviction or a disqualifying serious infraction, with the board weighing "the age of the individual, the youth's childhood and life experience, the degree of responsibility the youth was capable of exercising, and the youth's chances of becoming rehabilitated"; and of HB 1229, which requires resentencing where a robbery in the second degree conviction was used to impose a persistent offender sentence. Neither act contains findings or an intent section, so the ladder cannot be told which chair they answer: chair 1 ("helping the person change their life") fits the purpose a reader would infer, and chair 3 ("a mix: some accountability, some support, depending on what happened") fits the structure almost verbatim — 25 years served is the accountability, the petition is the support, and the disqualifiers are the "depending on what happened". This is the same unresolved 1-vs-3 split as Manka Dhingra's SB 6074, and it is a property of the chairs rather than of either member's record.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1317.pdf','https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1229.pdf']),
('55631a34-52aa-4806-9af6-1220fcf65ca5','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
 $r$Unable to place on this ladder. Prime sponsor of HB 2242 (2026), which preserves access to evidence-based preventive health services by clarifying the department of health's authority to issue immunization recommendations and the insurance coverage that follows from them. Its own §1 says the legislature "does not intend to establish new requirements that any individual receive any immunization or other preventive health service", nor to modify existing informed consent law. The act defends the current scope of coverage and changes no one's access to insurance. Chair 3 pairs helping people who cannot afford care with EXPANDING programmes; chair 4 asserts the state should help ONLY the poorest and leave everyone else to employers and private insurance; chairs 1 and 2 are universal or near-universal public coverage; chair 5 is staying out of healthcare entirely, which sponsoring this refutes. Preventing a reduction is not a chair on this ladder.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2242.pdf']),
('2026df33-5726-4d18-8f17-1882e49893fa','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
 $r$Unable to place on this ladder. Prime sponsor of HB 2296 (Chapter law, 2026), which expands the use of distributed energy resources — it legalises "balcony solar" and widens net metering and meter aggregation definitions so small consumer-owned generation can interconnect. It authorises clean generation rather than funding it, and it states no emission target or reduction schedule. Chair 3 requires investment in clean energy while gradually reducing reliance on fossil fuels, and this act appropriates nothing; chair 2 requires a phase-out by 2030 and chair 1 an emergency declaration, neither of which appears; chairs 4 and 5 describe leaving the transition to markets or rejecting climate policy, which an act deliberately widening access to consumer solar refutes. His other energy instruments — siting distributed generation on agricultural lands, and reducing certain environmental and energy reporting obligations — do not add either missing element.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/2296.pdf']);

-- answers for the ESHB 2015 cohort only; the three blanks get NO answer row
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('be3c2a24-1576-4636-9374-18fc77a8513f','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('ec9da15f-7d79-42bc-a368-da3ab0855ddf','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('45737b89-a83b-421f-9d6c-abc829c7eae0','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('40ae39e3-8e86-46a5-b660-96b46a3e6c02','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('d8adabde-90dd-49e7-870c-1f2ae7c5e6d3','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('628a26a2-bcb9-4e87-a29f-ac5f6b381a37','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('73ad3771-798c-4855-a467-7c6269bca5fc','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('cf992e89-7b96-46f3-9999-58432c690fe4','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('30fdeba0-e9d3-414d-859f-2941140d8e80','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('1a53e3c7-3c47-450b-a04d-a2128288b868','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('1963d6e9-069b-4770-9489-59e36faaa2e1','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('4b5055b4-2ed1-4894-acae-0e1465159564','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('3efc8925-9612-4601-aed5-c05234a5e64d','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('d5c6e6e4-c474-41fa-ab96-bd237c8ff4de','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4);

DO $$
DECLARE ans_after int; ctx_after int; s record; bad int; c4 int; nblank int;
BEGIN
  SELECT * INTO s FROM hd_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 14 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +14', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 17 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +17', s.ctx_before, ctx_after; END IF;

  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85' AND a.politician_id IN ('be3c2a24-1576-4636-9374-18fc77a8513f','ec9da15f-7d79-42bc-a368-da3ab0855ddf','45737b89-a83b-421f-9d6c-abc829c7eae0','40ae39e3-8e86-46a5-b660-96b46a3e6c02','d8adabde-90dd-49e7-870c-1f2ae7c5e6d3','628a26a2-bcb9-4e87-a29f-ac5f6b381a37','73ad3771-798c-4855-a467-7c6269bca5fc','cf992e89-7b96-46f3-9999-58432c690fe4','30fdeba0-e9d3-414d-859f-2941140d8e80','1a53e3c7-3c47-450b-a04d-a2128288b868','1963d6e9-069b-4770-9489-59e36faaa2e1','4b5055b4-2ed1-4894-acae-0e1465159564','3efc8925-9612-4601-aed5-c05234a5e64d','d5c6e6e4-c474-41fa-ab96-bd237c8ff4de')
     AND (a.value <> 4
          OR c.reasoning !~ 'hiring, retaining, and training law enforcement officers'
          OR NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/Session%20Laws/House/2015-S.SL.pdf' = ANY(c.sources)));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % seated row(s) wrong chair, missing the grant clause, or missing the session law', bad; END IF;

  SELECT count(*) INTO c4 FROM inform.politician_answers
   WHERE topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85' AND value=4 AND politician_id IN ('be3c2a24-1576-4636-9374-18fc77a8513f','ec9da15f-7d79-42bc-a368-da3ab0855ddf','45737b89-a83b-421f-9d6c-abc829c7eae0','40ae39e3-8e86-46a5-b660-96b46a3e6c02','d8adabde-90dd-49e7-870c-1f2ae7c5e6d3','628a26a2-bcb9-4e87-a29f-ac5f6b381a37','73ad3771-798c-4855-a467-7c6269bca5fc','cf992e89-7b96-46f3-9999-58432c690fe4','30fdeba0-e9d3-414d-859f-2941140d8e80','1a53e3c7-3c47-450b-a04d-a2128288b868','1963d6e9-069b-4770-9489-59e36faaa2e1','4b5055b4-2ed1-4894-acae-0e1465159564','3efc8925-9612-4601-aed5-c05234a5e64d','d5c6e6e4-c474-41fa-ab96-bd237c8ff4de');
  IF c4 <> 14 THEN RAISE EXCEPTION 'guard 2: chair-4 count is %, expected 14', c4; END IF;

  -- blanks asserted separately: a bug seating them would still satisfy the counts above
  SELECT count(*) INTO nblank
    FROM inform.politician_context c
   WHERE ((c.politician_id='447b684b-e885-42c9-9f32-7e6480cb5b98' AND c.topic_id='9db07b16-1076-4b7d-ad89-ebe7b51f4336') OR (c.politician_id='55631a34-52aa-4806-9af6-1220fcf65ca5' AND c.topic_id='e8dad4a8-eb93-4931-91f5-d8fb5d7dd529') OR (c.politician_id='2026df33-5726-4d18-8f17-1882e49893fa' AND c.topic_id='f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'))
     AND c.reasoning ~ '^Unable to place on this ladder'
     AND coalesce(cardinality(c.sources),0) >= 1
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                      WHERE a.politician_id=c.politician_id AND a.topic_id=c.topic_id);
  IF nblank <> 3 THEN RAISE EXCEPTION 'guard 2: % documented blank(s), expected 3', nblank; END IF;

  -- Pollet still holds exactly one row on this ladder, not two
  SELECT count(*) INTO bad FROM inform.politician_answers
   WHERE politician_id='fab8170e-a747-41de-ad39-769d8e0dd901' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF bad <> 1 THEN RAISE EXCEPTION 'guard 2: Pollet now holds % public-safety rows, expected 1', bad; END IF;
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

  RAISE NOTICE 'public-safety-approach: 14 at chair 4 from ESHB 2015; 3 documented blanks; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
