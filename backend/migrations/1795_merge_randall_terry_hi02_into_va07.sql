-- Migration 1795: Randall Terry is ONE person — merge the HI-02 row into the VA-07 row.
--
-- ============================================================================
-- WHY THIS EXISTS, AND THE BROKEN PREMISE IT EXPOSES
-- ============================================================================
-- `backend/scripts/dedup-essentials-politicians.ts` blocked the "Randall Terry" group on
-- its RACE CONFLICT detector: two rows are candidates in different races, and the
-- detector's stated premise is that "one person contests one office per cycle."
--
-- 🔴 THAT PREMISE IS FALSE FOR PERENNIAL / PROTEST FILERS, and Randall Terry is the
-- proof. In the 2026 cycle alone he filed with the FEC in TWO districts and appeared on
-- a ballot in a third state. Detector 2 cannot distinguish a name collision from a
-- serial filer; it needs a same-cycle-multi-filing carve-out, or it will keep producing
-- false positives on exactly this class of candidate. Logged for the guard's follow-up.
--
--   89c3cb64-d0e8-48b9-8f59-adc752a7e567  SURVIVOR  external_id -510704
--       race_candidates row for U.S. House VA-07 (2026 Virginia General Election),
--       10 compass stances + reasoning, 1 headshot (recent, ~2024).
--   76f8ca69-3f05-4e96-a127-1981fffb31fe  DUPLICATE  external_id -150206
--       race_candidates row for U.S. Representative District 2 (HI 2026 Statewide
--       General), 1 headshot (~20 years older). Zero stances, zero finance sources.
--
-- Survivor is the stance-holder: inform.politician_answers is PRIMARY KEY
-- (politician_id, topic_id), so keeping the row that already holds all 10 avoids
-- repointing them at all. Only the HI-02 candidacy edge moves.
--
-- ============================================================================
-- THE IDENTITY EVIDENCE
-- ============================================================================
-- * FEC candidate records, 2026 cycle and adjacent:
--       H6NJ07300  TERRY, RANDALL  House NJ-07  IND  PO BOX 420, ELLENDALE TN 38029
--       H6VA07312  TERRY, RANDALL  House VA-07  IND  7310 CENTRALIA RD, ELLENDALE TN 38029
--       H6FL06290  TERRY, RANDALL  House FL-06  IND  PO BOX 420, ELLENDALE TN 38029
--   All three at the same Tennessee town and ZIP. The FL-06 2025 special is confirmed
--   on the record as the Operation Rescue founder ($17,862 raised, lost 2025-04-01),
--   which anchors the whole address chain to that one man.
-- * Reproaction, "Randall Terry's Illegal Dual Campaigns" — the Tennessee-based
--   anti-abortion advocate launched campaigns in BOTH New Jersey AND Hawaii; told that
--   running two simultaneous congressional campaigns is illegal, he said he "did not
--   read the law correctly" and ended the New Jersey campaign.
-- * New Jersey Globe — "Anti-abortion leader Randall Terry ends independent House bid
--   in NJ-7." Independent, non-aggregator confirmation of the Hawaii run.
-- * Ballotpedia carries ONE Randall Terry page spanning HI-02 2026, NJ-07 2026, the
--   FL-06 2025 special, the 2024 Constitution Party presidential run and 2012.
-- * The two stored headshots are the same man roughly two decades apart — the same
--   distinctive high-volume curly hair, face and glasses, brown in the older campaign
--   photo and gray in the recent stage portrait.
--
-- ⚠ SOFT EDGE, stated rather than papered over: the VA-07 link rests on the town/ZIP
-- match across FEC filings, not on a source that says outright "Randall Terry ran in
-- VA-07." Ballotpedia does not list VA-07 on his page, and this corpus's own
-- race_candidates note already records that he was absent from the Ballotpedia VA-07
-- general-election field after the 2026-08-04 filing deadline. The match is strong —
-- same rare-ish name, same tiny Tennessee ZIP, same office type, same cycle, same
-- INDEPENDENT status — but it is an inference, not a statement.
--
-- ============================================================================
-- WHAT IS DELIBERATELY NOT DONE HERE
-- ============================================================================
-- ⚠ The HI-02 candidacy result is LEFT ALONE. Terry LOST that nonpartisan primary on
-- 2026-08-08 (37.5% / 736 votes to Edward Codelia's 62.5% / 1,226), its
-- `provisional_until` of 2026-08-08 has expired, and it is still candidate_status
-- 'active' with result NULL. Recording that loss is a real and separate debt belonging
-- to the election-resolve queue, and it is not folded into an identity migration.
--
-- 🔴 CONSEQUENCE WORTH KNOWING BEFORE THE NEXT CULL: all 10 stances live on the VA-07
-- candidacy's row. Before this merge, a cull that retired the VA-07 row would have taken
-- every stance with it and left the row with real ballot access blank. After this merge
-- both candidacies hang off one person, so retiring either race edge no longer threatens
-- the stances.
--
-- ⚠ SEPARATE QUALITY DEFECT, NOT REPAIRED HERE: 9 of the 10 stances reason from
-- `constitutionparty.com/platform` — a PARTY PLATFORM attributed to a PERSON. Evidence
-- must describe the thing it is cited for; a platform is not the candidate's own record.
-- That belongs to the stance evidence-integrity audit, not to this identity fix.
--
-- The duplicate row is RETIRED, NOT DELETED. Its headshot stays attached to it; the
-- survivor keeps the recent portrait.
--
-- Verified to hold ZERO rows for BOTH ids: politician_context_evidence,
-- stance_research_review, topic_rewrite_stance_proposals, office_terms, identifiers,
-- addresses, degrees, experiences, politician_committees, politician_contacts,
-- politician_name_aliases, quest_verified_facts, empowered_profiles, la_council_votes,
-- public.politician_id_bridge, and transparent_motivations.politician_sources. The
-- duplicate holds nothing but the one race_candidates edge and its image.
--
-- essentials.race_candidates has no unique constraint beyond its PK, so the survivor
-- holding two candidacy edges in one cycle is representable — and it is the truth.
--
-- No answers are deleted or rewritten by this migration, so no @context-decision
-- declaration is required.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Move the HI-02 candidacy edge onto the surviving person row.
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates
SET politician_id = '89c3cb64-d0e8-48b9-8f59-adc752a7e567',
    source = COALESCE(source, '')
           || ' | merge 1795: moved from duplicate person row '
           || '76f8ca69-3f05-4e96-a127-1981fffb31fe. Same Randall Terry as the VA-07 '
           || 'filing — FEC H6NJ07300 / H6VA07312 / H6FL06290 all list Ellendale TN 38029, '
           || 'and Reproaction + New Jersey Globe report he campaigned in NJ and HI at once '
           || 'before ending the NJ bid. He contested at least three House seats in the 2026 '
           || 'cycle, so two candidacy edges on one person here is correct, not a collision.'
WHERE id = '133ed4af-20f3-4045-b67e-e5bf12c43cea';

-- ---------------------------------------------------------------------------
-- 2. Retire the duplicate person row (kept, not deleted).
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians
SET is_active    = false,
    is_incumbent = false,
    notes = ARRAY['DUPLICATE of politician 89c3cb64-d0e8-48b9-8f59-adc752a7e567 '
      || '(Randall Terry, founder of Operation Rescue and 2024 Constitution Party '
      || 'presidential nominee, of Ellendale TN). This row held the HI-02 candidacy, the '
      || 'survivor holds the VA-07 candidacy and all 10 compass stances. Same man: FEC '
      || 'H6NJ07300 (NJ-07 2026), H6VA07312 (VA-07 2026) and H6FL06290 (FL-06 2025 special) '
      || 'all carry the same Ellendale TN 38029 address; Reproaction and the New Jersey '
      || 'Globe both report he ran in New Jersey and Hawaii simultaneously and ended the NJ '
      || 'bid once told dual campaigns are illegal; the two stored headshots are the same '
      || 'man about twenty years apart. This row existed only because '
      || 'dedup-essentials-politicians.ts blocked the group on its race-conflict detector, '
      || 'whose premise that one person contests one office per cycle does not hold for '
      || 'perennial filers. Migration 1795 moved the HI-02 candidacy to the surviving row '
      || 'and retired this one. NOTE: that HI-02 candidacy is unresolved — Terry LOST the '
      || '2026-08-08 nonpartisan primary 37.5%/736 to Edward Codelia 62.5%/1,226 and its '
      || 'provisional window has expired; recording the loss is owed to the election-resolve '
      || 'queue.']
WHERE id = '76f8ca69-3f05-4e96-a127-1981fffb31fe';

COMMIT;
