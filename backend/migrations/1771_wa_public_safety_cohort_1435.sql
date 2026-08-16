-- 1771_wa_public_safety_cohort_1435.sql
-- 23 rows on `public-safety-approach`, all at chair 4. Cohort: every sponsor of HB 1435 (law
-- enforcement hiring grant program, Abell R-7 prime). Deliberately a REPUBLICAN HOUSE instrument:
-- after migration 1770 the 37 legislators still uncovered were 24 R / 23 House, and every cohort but
-- two had run on a majority-party bill. This one is also genuinely bipartisan — 16 R and 7 D — which
-- is the first cohort in the sweep that is not near-uniform by party.
--
-- ── why chair 4 ──────────────────────────────────────────────────────────────────────────────────
-- Chair 4 is "increase police staffing, equipment, and pay to improve response times and deter
-- crime". HB 1435 is the staffing-and-pay half in operative terms: it appropriates state money to
-- pay 75% of a new officer's entry-level salary and benefits, and §1(1) states the purpose as
-- "increase community policing and public safety". The anti-transfer clause — no grant for anyone
-- employed by a Washington law enforcement agency in the previous 12 months — is what makes it an
-- increase in officers rather than a reshuffle.
-- The prime sponsor's two companion bills carry the deterrence rationale chair 4 names explicitly:
-- HB 1436 and HB 1896 both find violent crime at "25-year highs", Washington "last in the nation for
-- law enforcement officers per capita", and set out to fund more officers "with the goal of reducing
-- violent and property crime".
-- The other four chairs are refuted from the text, not merely unproven:
--   · chair 1 ("redirect a significant portion of the police budget to social services") — opposite
--     direction;
--   · chair 2 ("MAINTAIN current police staffing but shift non-violent calls to unarmed mental health
--     co-responders") — the act increases staffing, and creates no alternative responder;
--   · chair 3 ("KEEP CURRENT public safety funding while adding crisis response teams") — the act
--     adds public safety funding;
--   · chair 5 ("make expanding the police budget the TOP SPENDING PRIORITY over other services") —
--     nothing here ranks police against other spending. The grant is capped, subject to
--     appropriation, and requires a local match; Abell's companion funding bills are permissive local
--     options adopted expressly "to avoid placing more burden on local governments".
--
-- ── scope: this ladder IS used for state legislators ──────────────────────────────────────────────
-- The chair text asks how "your community" funds and operates public safety, and the generated
-- reference warns the community-scoped ladders are usually wrong for a statewide official. Overridden
-- here on the same ground as `local-immigration` in migration 1766: the instrument legislates on
-- precisely what the ladder asks — a state appropriation that pays local and tribal agencies to put
-- more officers on the street. ⚠ The inconsistency flagged in 1766 is still open:
-- `transportation-priorities` was NOT used for state legislators on this same reasoning.
--
-- ── per-member screen: 10 flagged, all read, NOBODY MOVED ─────────────────────────────────────────
--   · Abell (prime) HB 1436 and HB 1896 — more officers via a local sales tax credited against the
--     state portion: chair 4 three times over, never chair 5, because both are permissive local
--     options that rank police against nothing.
--   · 🔑 Davis HB 1498 (ENACTED, domestic violence co-responder grant program) and Nance HB 1809
--     (training and reimbursement for behavioral health co-response) are the two instruments that
--     look like chairs 2-3 and are not. Chair 2 wants non-violent calls shifted to UNARMED mental
--     health responders; HB 1498's advocates are "summoned BY law enforcement to the scene" and
--     handle victim support, so the officer still takes the call. Chair 3 requires KEEPING public
--     safety funding current, which each of them refuted by sponsoring HB 1435 itself.
--   · Paul HB 1791 (ENACTED) only widens what existing local REET may be spent on; Low's HB 1139 and
--     HB 1331 raise criminal penalties, which is the `judicial-criminal-justice` question, not this
--     one; the rest are memorials, notification duties and training access.
--
-- 🔑 PRECEDENT WORTH KEEPING: a chair is refuted when the record CONTRADICTS its text, not when the
-- record is BROADER than it. Davis and Nance support more officers AND more co-response; chair 4
-- claims only the first and claims no exclusivity, so it is true of them. That is different from the
-- abortion blanks in 1767, where chairs 2-5 each asserted a gestational limit the members rejected.
-- Contradiction blanks a chair; incompleteness does not.
-- 🔴 FOR THE LADDER OWNER: this ladder makes "more police" and "more crisis response" mutually
-- exclusive rungs — chairs 2 and 3 both open with maintain/keep-current. A bipartisan bloc here holds
-- both at once and has no chair that says so. Logged in COMPASS-LADDER-TROUBLE-SPOTS.md.
--
-- ⚠ RECORDED WEAKNESS: chair 4 is a compound — "staffing, equipment, and pay". HB 1435 funds
-- staffing and pay and explicitly forbids spending the grant on anything else, so the equipment limb
-- is unmatched. Chair 4 survives on its main clause plus refutation of all four neighbours, the same
-- way residential-zoning chair 2 survived without "strong design review" in migration 1769.
--
-- ⚠ The picker's top-ranked Republican House instrument was a dud again: HB 1108 (Klicker, enacted,
-- +8 uncovered) creates a "task force on housing cost driver analysis" — it appoints members and
-- reports; it takes no position and reaches no chair. Third dud of the sweep. Rank to choose where to
-- look, then read.
BEGIN;

CREATE TEMP TABLE ps_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f68a7024-846d-4383-a34e-a21df06b2314' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Adam Bernbaum already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f68a7024-846d-4383-a34e-a21df06b2314' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Adam Bernbaum already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='5204682b-10ec-452a-bd90-4be46a634258' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Adison Richards already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='5204682b-10ec-452a-bd90-4be46a634258' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Adison Richards already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='1ea4763b-1a8a-4920-b4ef-55a5c35aa3d0' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Andrew Barkis already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='1ea4763b-1a8a-4920-b4ef-55a5c35aa3d0' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Andrew Barkis already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='20691f72-9abe-40ad-b361-eb804b212e29' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Andrew Engell already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='20691f72-9abe-40ad-b361-eb804b212e29' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Andrew Engell already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='a327c238-cf63-4a27-83f7-cc85468f8742' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: April Connors already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='a327c238-cf63-4a27-83f7-cc85468f8742' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: April Connors already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='4546a3b3-4544-43bf-bf0f-eb56871fa1a2' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chris Corry already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='4546a3b3-4544-43bf-bf0f-eb56871fa1a2' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Chris Corry already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='43bb35d8-ef11-49cb-9bc7-f16e65cc6534' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Cyndy Jacobsen already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='43bb35d8-ef11-49cb-9bc7-f16e65cc6534' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Cyndy Jacobsen already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='78726dd6-5ce2-40d4-9cf6-10fc6a840756' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Dave Paul already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='78726dd6-5ce2-40d4-9cf6-10fc6a840756' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Dave Paul already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f5c96c19-a962-4881-9520-a741cb0123e5' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Deb Manjarrez already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f5c96c19-a962-4881-9520-a741cb0123e5' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Deb Manjarrez already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='fab8170e-a747-41de-ad39-769d8e0dd901' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Gerry Pollet already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='fab8170e-a747-41de-ad39-769d8e0dd901' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Gerry Pollet already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='81aeef04-3b51-40a1-8a89-013acf2f5ec4' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Gloria Mendoza already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='81aeef04-3b51-40a1-8a89-013acf2f5ec4' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Gloria Mendoza already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='463c9085-ff29-45f4-88b0-fe3be9693a36' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Greg Nance already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='463c9085-ff29-45f4-88b0-fe3be9693a36' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Greg Nance already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='ba7f7d85-62ba-440d-abff-70ce9af458e5' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Hunter Abell already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='ba7f7d85-62ba-440d-abff-70ce9af458e5' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Hunter Abell already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='72f1981b-ff10-48dd-8c92-e6ea2c169902' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jeremie Dufault already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='72f1981b-ff10-48dd-8c92-e6ea2c169902' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Jeremie Dufault already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='62bd22ba-058e-4cf8-bd24-905ced2f727a' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Joe Schmick already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='62bd22ba-058e-4cf8-bd24-905ced2f727a' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Joe Schmick already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='61b7b19c-1af2-4e6c-a33d-80c4d80d2cd4' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: John Ley already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='61b7b19c-1af2-4e6c-a33d-80c4d80d2cd4' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: John Ley already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='ae61e4af-16a8-44d6-933a-c4826882e103' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Larry Springer already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='ae61e4af-16a8-44d6-933a-c4826882e103' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Larry Springer already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='0e5af9ca-165c-458c-8c65-a89aaf1a8d3e' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lauren Davis already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='0e5af9ca-165c-458c-8c65-a89aaf1a8d3e' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Lauren Davis already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='f6a25fa8-ef58-4179-8660-bdb642336f68' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mark Klicker already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='f6a25fa8-ef58-4179-8660-bdb642336f68' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Mark Klicker already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='7b5839a9-87c9-4789-bd4e-a85e24a90d6d' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Michelle Valdez already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='7b5839a9-87c9-4789-bd4e-a85e24a90d6d' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Michelle Valdez already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='bcfed468-6b26-4e3c-a96d-fb39ce46fd13' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sam Low already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='bcfed468-6b26-4e3c-a96d-fb39ce46fd13' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Sam Low already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='a2960d00-9348-4a98-82b9-2cf2320669b6' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Skyler Rude already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='a2960d00-9348-4a98-82b9-2cf2320669b6' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Skyler Rude already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='0401d7b9-9f0d-4b92-beed-02bcf2afc456' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Suzanne Schmidt already has a public-safety-approach answer'; END IF;
  SELECT count(*) INTO n FROM inform.politician_context
   WHERE politician_id='0401d7b9-9f0d-4b92-beed-02bcf2afc456' AND topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: Suzanne Schmidt already has a public-safety-approach context row'; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances WHERE topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85' AND value=4;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: public-safety-approach chair 4 not defined exactly once (%)', n; END IF;
  SELECT count(*) INTO n FROM inform.compass_topics
   WHERE id='e9ebefcd-c496-45e8-b816-a79f8442ba85' AND topic_key='public-safety-approach' AND is_live AND is_active;
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: public-safety-approach topic is not live/active'; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
('f68a7024-846d-4383-a34e-a21df06b2314','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('5204682b-10ec-452a-bd90-4be46a634258','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('1ea4763b-1a8a-4920-b4ef-55a5c35aa3d0','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('20691f72-9abe-40ad-b361-eb804b212e29','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('a327c238-cf63-4a27-83f7-cc85468f8742','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('4546a3b3-4544-43bf-bf0f-eb56871fa1a2','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('43bb35d8-ef11-49cb-9bc7-f16e65cc6534','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('78726dd6-5ce2-40d4-9cf6-10fc6a840756','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('f5c96c19-a962-4881-9520-a741cb0123e5','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('fab8170e-a747-41de-ad39-769d8e0dd901','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('81aeef04-3b51-40a1-8a89-013acf2f5ec4','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('463c9085-ff29-45f4-88b0-fe3be9693a36','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('ba7f7d85-62ba-440d-abff-70ce9af458e5','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Prime sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('72f1981b-ff10-48dd-8c92-e6ea2c169902','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('62bd22ba-058e-4cf8-bd24-905ced2f727a','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('61b7b19c-1af2-4e6c-a33d-80c4d80d2cd4','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('ae61e4af-16a8-44d6-933a-c4826882e103','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('0e5af9ca-165c-458c-8c65-a89aaf1a8d3e','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('f6a25fa8-ef58-4179-8660-bdb642336f68','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('7b5839a9-87c9-4789-bd4e-a85e24a90d6d','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('bcfed468-6b26-4e3c-a96d-fb39ce46fd13','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('a2960d00-9348-4a98-82b9-2cf2320669b6','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']),
('0401d7b9-9f0d-4b92-beed-02bcf2afc456','e9ebefcd-c496-45e8-b816-a79f8442ba85',
 $r$Co-sponsor of HB 1435, which directs the criminal justice training commission to run a law enforcement hiring grant program paying up to 75 percent of the entry-level salary and benefits of new local and tribal police officers — a maximum state share of $125,000 per position for 36 months, against a 25 percent local cash match — "for the purpose of increasing the number of filled local and tribal law enforcement officer positions in Washington state" and to "increase community policing and public safety". The grants may be spent on nothing but salaries and benefits, and are barred for any officer employed by a Washington agency in the previous 12 months, so the money buys additional officers rather than transfers.$r$,
 ARRAY['https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf']);

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
('f68a7024-846d-4383-a34e-a21df06b2314','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('5204682b-10ec-452a-bd90-4be46a634258','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('1ea4763b-1a8a-4920-b4ef-55a5c35aa3d0','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('20691f72-9abe-40ad-b361-eb804b212e29','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('a327c238-cf63-4a27-83f7-cc85468f8742','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('4546a3b3-4544-43bf-bf0f-eb56871fa1a2','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('43bb35d8-ef11-49cb-9bc7-f16e65cc6534','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('78726dd6-5ce2-40d4-9cf6-10fc6a840756','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('f5c96c19-a962-4881-9520-a741cb0123e5','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('fab8170e-a747-41de-ad39-769d8e0dd901','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('81aeef04-3b51-40a1-8a89-013acf2f5ec4','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('463c9085-ff29-45f4-88b0-fe3be9693a36','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('ba7f7d85-62ba-440d-abff-70ce9af458e5','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('72f1981b-ff10-48dd-8c92-e6ea2c169902','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('62bd22ba-058e-4cf8-bd24-905ced2f727a','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('61b7b19c-1af2-4e6c-a33d-80c4d80d2cd4','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('ae61e4af-16a8-44d6-933a-c4826882e103','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('0e5af9ca-165c-458c-8c65-a89aaf1a8d3e','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('f6a25fa8-ef58-4179-8660-bdb642336f68','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('7b5839a9-87c9-4789-bd4e-a85e24a90d6d','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('bcfed468-6b26-4e3c-a96d-fb39ce46fd13','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('a2960d00-9348-4a98-82b9-2cf2320669b6','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4),
('0401d7b9-9f0d-4b92-beed-02bcf2afc456','e9ebefcd-c496-45e8-b816-a79f8442ba85', 4);

DO $$
DECLARE ans_after int; ctx_after int; s record;
BEGIN
  SELECT * INTO s FROM ps_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 23 THEN
    RAISE EXCEPTION 'guard 1: answers % -> %, expected +23', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 23 THEN
    RAISE EXCEPTION 'guard 1: context % -> %, expected +23', s.ctx_before, ctx_after; END IF;
END $$;

DO $$
DECLARE bad int; c4 int; primes int;
BEGIN
  -- content, not merely that an INSERT ran: the chair value, the clause the chair was read from,
  -- and the source actually fetched.
  SELECT count(*) INTO bad
    FROM inform.politician_answers a
    JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
   WHERE a.topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85' AND a.politician_id IN ('f68a7024-846d-4383-a34e-a21df06b2314','5204682b-10ec-452a-bd90-4be46a634258','1ea4763b-1a8a-4920-b4ef-55a5c35aa3d0','20691f72-9abe-40ad-b361-eb804b212e29','a327c238-cf63-4a27-83f7-cc85468f8742','4546a3b3-4544-43bf-bf0f-eb56871fa1a2','43bb35d8-ef11-49cb-9bc7-f16e65cc6534','78726dd6-5ce2-40d4-9cf6-10fc6a840756','f5c96c19-a962-4881-9520-a741cb0123e5','fab8170e-a747-41de-ad39-769d8e0dd901','81aeef04-3b51-40a1-8a89-013acf2f5ec4','463c9085-ff29-45f4-88b0-fe3be9693a36','ba7f7d85-62ba-440d-abff-70ce9af458e5','72f1981b-ff10-48dd-8c92-e6ea2c169902','62bd22ba-058e-4cf8-bd24-905ced2f727a','61b7b19c-1af2-4e6c-a33d-80c4d80d2cd4','ae61e4af-16a8-44d6-933a-c4826882e103','0e5af9ca-165c-458c-8c65-a89aaf1a8d3e','f6a25fa8-ef58-4179-8660-bdb642336f68','7b5839a9-87c9-4789-bd4e-a85e24a90d6d','bcfed468-6b26-4e3c-a96d-fb39ce46fd13','a2960d00-9348-4a98-82b9-2cf2320669b6','0401d7b9-9f0d-4b92-beed-02bcf2afc456')
     AND (a.value <> 4
          OR c.reasoning !~ 'increasing the number of filled local and tribal law enforcement officer positions'
          OR c.reasoning !~ 'increase community policing and public safety'
          OR NOT ('https://lawfilesext.leg.wa.gov/biennium/2025-26/Pdf/Bills/House%20Bills/1435.pdf' = ANY(c.sources)));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: % row(s) wrong chair, missing the staffing clause, or missing HB 1435', bad; END IF;

  SELECT count(*) INTO c4 FROM inform.politician_answers
   WHERE topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85' AND value=4 AND politician_id IN ('f68a7024-846d-4383-a34e-a21df06b2314','5204682b-10ec-452a-bd90-4be46a634258','1ea4763b-1a8a-4920-b4ef-55a5c35aa3d0','20691f72-9abe-40ad-b361-eb804b212e29','a327c238-cf63-4a27-83f7-cc85468f8742','4546a3b3-4544-43bf-bf0f-eb56871fa1a2','43bb35d8-ef11-49cb-9bc7-f16e65cc6534','78726dd6-5ce2-40d4-9cf6-10fc6a840756','f5c96c19-a962-4881-9520-a741cb0123e5','fab8170e-a747-41de-ad39-769d8e0dd901','81aeef04-3b51-40a1-8a89-013acf2f5ec4','463c9085-ff29-45f4-88b0-fe3be9693a36','ba7f7d85-62ba-440d-abff-70ce9af458e5','72f1981b-ff10-48dd-8c92-e6ea2c169902','62bd22ba-058e-4cf8-bd24-905ced2f727a','61b7b19c-1af2-4e6c-a33d-80c4d80d2cd4','ae61e4af-16a8-44d6-933a-c4826882e103','0e5af9ca-165c-458c-8c65-a89aaf1a8d3e','f6a25fa8-ef58-4179-8660-bdb642336f68','7b5839a9-87c9-4789-bd4e-a85e24a90d6d','bcfed468-6b26-4e3c-a96d-fb39ce46fd13','a2960d00-9348-4a98-82b9-2cf2320669b6','0401d7b9-9f0d-4b92-beed-02bcf2afc456');
  IF c4 <> 23 THEN RAISE EXCEPTION 'guard 2: chair-4 count is %, expected 23', c4; END IF;

  SELECT count(*) INTO primes FROM inform.politician_context
   WHERE topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85' AND politician_id IN ('f68a7024-846d-4383-a34e-a21df06b2314','5204682b-10ec-452a-bd90-4be46a634258','1ea4763b-1a8a-4920-b4ef-55a5c35aa3d0','20691f72-9abe-40ad-b361-eb804b212e29','a327c238-cf63-4a27-83f7-cc85468f8742','4546a3b3-4544-43bf-bf0f-eb56871fa1a2','43bb35d8-ef11-49cb-9bc7-f16e65cc6534','78726dd6-5ce2-40d4-9cf6-10fc6a840756','f5c96c19-a962-4881-9520-a741cb0123e5','fab8170e-a747-41de-ad39-769d8e0dd901','81aeef04-3b51-40a1-8a89-013acf2f5ec4','463c9085-ff29-45f4-88b0-fe3be9693a36','ba7f7d85-62ba-440d-abff-70ce9af458e5','72f1981b-ff10-48dd-8c92-e6ea2c169902','62bd22ba-058e-4cf8-bd24-905ced2f727a','61b7b19c-1af2-4e6c-a33d-80c4d80d2cd4','ae61e4af-16a8-44d6-933a-c4826882e103','0e5af9ca-165c-458c-8c65-a89aaf1a8d3e','f6a25fa8-ef58-4179-8660-bdb642336f68','7b5839a9-87c9-4789-bd4e-a85e24a90d6d','bcfed468-6b26-4e3c-a96d-fb39ce46fd13','a2960d00-9348-4a98-82b9-2cf2320669b6','0401d7b9-9f0d-4b92-beed-02bcf2afc456') AND reasoning LIKE 'Prime sponsor of %';
  IF primes <> 1 THEN RAISE EXCEPTION 'guard 2: % prime-sponsor row(s), expected 1', primes; END IF;
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

  RAISE NOTICE 'public-safety-approach: 23 at chair 4 from HB 1435; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
