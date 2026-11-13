-- CC_0411 — the last reachable Massachusetts rows of the zero-vote correction (2 rows)
--
-- WHERE THIS SITS
-- ----------------------------------------------------------------------------
-- CC_0409 corrected 43 rows from each state's own return; CC_0410 corrected Wisconsin's 8 from the
-- county clerks. Three Massachusetts rows were left. This file takes the two whose municipalities
-- have actually published, leaving ONE — and the post-verify asserts exactly one.
--
-- 🔴 MASSACHUSETTS PUBLISHES NO UNOFFICIAL RESULTS AT ALL. The Secretary of the Commonwealth:
--   "We do not publish unofficial election results ... local officials don't report unofficial
--    results to the state. We receive election results from cities and towns only after local
--    clerks finalize and certify them."  Cities and towns have 15 days after a state election.
--   (sec.state.ma.us/divisions/elections/voting-information/announcing-certifying.htm, 2026-11-12)
-- The state's results database holds no 2026 general at all today. So these totals come from the
-- city clerks and are ARITHMETIC, with the same two things load bearing as in Wisconsin:
--
-- 🔴 1. THE MUNICIPAL SET MUST BE COMPLETE — a missed city undercounts and nothing errors. The
--      set is taken from the Secretary's own CERTIFIED 2024 general results for these same
--      districts under the same 2021 plan: the 25th Middlesex lies entirely within Cambridge;
--      the 26th Middlesex is Cambridge plus Somerville.
-- 🔴 2. EACH FIGURE READ AT FULL WIDTH. Somerville publishes a wide ward-by-precinct grid whose
--      text extraction collapses; its grand-total column was re-read from the rendered page.
--      ⚠ Cambridge's "Total Votes" INCLUDES its write-in line (11,082 + 273 = 11,355) — the
--      OPPOSITE of Racine County's in CC_0410, which excludes it. Neither convention can be
--      assumed; each was checked by making the contest's arithmetic close.
--
-- 🔴 THE LAST ROW IS BLOCKED ON A CITY THAT HAS PUBLISHED NOTHING, AND IT IS NOT GUESSED.
-- Sal DiDomenico's Middlesex & Suffolk Senate district is Boston + Cambridge + Chelsea + Everett.
-- Three of the four are in hand (Cambridge 18,151; Boston 5,541 from its Statement of Votes Cast;
-- Chelsea 5,201 from its citywide summary). EVERETT HAS POSTED NO NOVEMBER 3 2026 RESULTS — its
-- elections department's newest file is the September primary. Everett was 9,724 of 47,113 in
-- 2024, about a fifth of the district, so summing the other three would understate the winner's
-- total by roughly that much while looking perfectly consistent. That row waits for Everett or
-- for the state's official results.
-- ⚠ Chelsea's own figure is also marked "(Election Day)" and it posted a post-election tabulation
-- notice dated 2026-11-06, so even the three in hand are not final.
--
-- WHAT THIS FILE DOES
-- ----------------------------------------------------------------------------
-- One row, one column, 2 rows. result, result_certainty and result_recorded_at are gated
-- UNCHANGED: both municipal returns are expressly labelled unofficial, no municipality publishes
-- a winner flag, and Massachusetts has certified nothing — so the CALL stays AP's. The prior
-- value of each row travels in the payload beside its md5, gate 0 refusing the file unless the
-- recorded text hashes to the recorded hash and gate 1 unless the LIVE column does too.

BEGIN;

CREATE TEMP TABLE cc0411_rows (
  rc_id        uuid PRIMARY KEY,
  prior_md5    text    NOT NULL,
  prior_source text    NOT NULL,
  muni_total   integer NOT NULL,
  new_source   text    NOT NULL
) ON COMMIT DROP;

INSERT INTO cc0411_rows (rc_id, prior_md5, prior_source, muni_total, new_source) VALUES
  ('14fd8f44-8807-440a-be8d-cf94708502df'::uuid, '46ab71e919c9163027845b124888484b', 'Associated Press race call for the 2026-11-03 general election, read 2026-11-08 from AP''s own per-state results feed (interactives.apelections.org/election-results/data-live/2026-11-03/results/races/MA/, race 20261103MA23056, candidate 122817): Marjorie Decker (Dem) 0 votes, 0%, recorded as won. This is AP''s call and NOT the state canvass; AP reports this race as not yet certified. Matched to our row on basis ''exact-full-name''.', 11082, 'Massachusetts publishes NO unofficial election results — the Secretary of the Commonwealth states "We do not publish unofficial election results" and that "local officials don’t report unofficial results to the state", cities and towns having 15 days after a state election to certify (sec.state.ma.us/divisions/elections/voting-information/announcing-certifying.htm, read 2026-11-12). So this figure is summed from the municipal clerks. MARJORIE C. DECKER took 11,082 votes for the Twenty-Fifth Middlesex District, with 273 write-in votes across the same municipalities. Per municipality: Cambridge 11,082 (write-in 273) — Cambridge reports 11,355 total votes in the contest (the candidate plus 273 unresolved write-ins), 2,017 undervotes and 3 overvotes against 13,375 ballots cast; City of Cambridge Election Commission, "November 3 2026 State Election Unofficial Results", the November 10 updated Election Summary Report (cambridgema.gov/-/media/Files/electioncommission/2026stateelection/november10updatedunofficialresultscambridge.pdf, report footer 11/10/2026 5:08:36 PM). The Twenty-Fifth Middlesex District lies ENTIRELY within Cambridge, so this one city is the whole district; that composition is taken from the Secretary of the Commonwealth''s CERTIFIED 2024 general election results for this same district under the same 2021 districting plan (electionstats.state.ma.us). Both municipal returns are expressly labelled UNOFFICIAL by the cities that published them, and no municipality publishes a winner flag, so the WIN remains the Associated Press''s call — AP race 20261103MA23056, candidate 122817. AP''s feed marks this race metadata.uncontested = true and publishes no tabulation for it; the figure in the citation this row carried before was AP declining to count an uncontested race, not a tally of the ballots. Read 2026-11-12. Corrected by CC_0411, which records the previous citation verbatim and gates on its hash.'),
  ('92517dc6-ab06-4ad1-8e69-b500f4c4de3a'::uuid, '02d558a804a850140f1c44c6d528ca17', 'Associated Press race call for the 2026-11-03 general election, read 2026-11-08 from AP''s own per-state results feed (interactives.apelections.org/election-results/data-live/2026-11-03/results/races/MA/, race 20261103MA23057, candidate 123059): Mike Connolly (Dem) 0 votes, 0%, recorded as won. This is AP''s call and NOT the state canvass; AP reports this race as not yet certified. Matched to our row on basis ''exact-full-name''.', 13554, 'Massachusetts publishes NO unofficial election results — the Secretary of the Commonwealth states "We do not publish unofficial election results" and that "local officials don’t report unofficial results to the state", cities and towns having 15 days after a state election to certify (sec.state.ma.us/divisions/elections/voting-information/announcing-certifying.htm, read 2026-11-12). So this figure is summed from the municipal clerks. MIKE CONNOLLY took 13,554 votes for the Twenty-Sixth Middlesex District — Cambridge 10,367 + Somerville 3,187, with 185 write-in votes across the same municipalities. Per municipality: Cambridge 10,367 (write-in 131) — Cambridge reports 10,498 total votes in the contest (the candidate plus 131 unresolved write-ins), 1,706 undervotes and 2 overvotes against 12,206 ballots cast; City of Cambridge Election Commission, "November 3 2026 State Election Unofficial Results", the November 10 updated Election Summary Report (cambridgema.gov/-/media/Files/electioncommission/2026stateelection/november10updatedunofficialresultscambridge.pdf, report footer 11/10/2026 5:08:36 PM); Somerville 3,187 (write-in 54) — Somerville’s grand total across Wards 1 and 2 (the only wards of that city in this district), with 54 write-in and 496 blank; City of Somerville, "Somerville UnOfficial Election Totals - Tuesday November 3, 2026" (s3.amazonaws.com/somervillema-live/s3fs-public/election-results-preliminary-20261103.pdf). The Twenty-Sixth Middlesex District is made up of parts of Cambridge and Somerville; that composition is taken from the Secretary of the Commonwealth''s CERTIFIED 2024 general election results for this same district under the same 2021 districting plan (electionstats.state.ma.us). Both municipal returns are expressly labelled UNOFFICIAL by the cities that published them, and no municipality publishes a winner flag, so the WIN remains the Associated Press''s call — AP race 20261103MA23057, candidate 123059. AP''s feed marks this race metadata.uncontested = true and publishes no tabulation for it; the figure in the citation this row carried before was AP declining to count an uncontested race, not a tally of the ballots. Read 2026-11-12. Corrected by CC_0411, which records the previous citation verbatim and gates on its hash.');

-- ─── 1. Pre-gates ───────────────────────────────────────────────────────────────
DO $$
DECLARE v_n integer; v_bad text;
BEGIN
  SELECT string_agg(rc_id::text, ', ') INTO v_bad FROM cc0411_rows WHERE md5(prior_source) <> prior_md5;
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0411 gate: the prior value recorded in this file does not hash to its recorded md5 for %', v_bad;
  END IF;

  SELECT count(*) INTO v_n FROM cc0411_rows;
  IF v_n <> 2 THEN RAISE EXCEPTION 'CC_0411 gate: % rows in the payload, expected 2', v_n; END IF;

  SELECT string_agg(t.rc_id::text, ', ') INTO v_bad
    FROM cc0411_rows t JOIN essentials.race_candidates rc ON rc.id = t.rc_id
   WHERE md5(rc.result_source) <> t.prior_md5;
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0411 gate: result_source has changed since this file was written, for %', v_bad;
  END IF;

  SELECT count(*) INTO v_n
    FROM cc0411_rows t JOIN essentials.race_candidates rc ON rc.id = t.rc_id
   WHERE rc.result_source ~ '[^0-9,]0 votes, 0(\.0+)?%';
  IF v_n <> 2 THEN RAISE EXCEPTION 'CC_0411 gate: only % of 2 targets carry the zero-vote sentence', v_n; END IF;

  -- Massachusetts only: this file's sources are two Massachusetts city clerks.
  SELECT count(*) INTO v_n
    FROM cc0411_rows t
    JOIN essentials.race_candidates rc ON rc.id = t.rc_id
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'ma';
  IF v_n <> 2 THEN RAISE EXCEPTION 'CC_0411 gate: only % of 2 targets are Massachusetts rows', v_n; END IF;

  SELECT count(*) INTO v_n
    FROM cc0411_rows t JOIN essentials.race_candidates rc ON rc.id = t.rc_id
   WHERE rc.result = 'won' AND rc.result_certainty = 'called';
  IF v_n <> 2 THEN RAISE EXCEPTION 'CC_0411 gate: % of 2 targets are won/called', v_n; END IF;

  SELECT string_agg(rc_id::text, ', ') INTO v_bad
    FROM cc0411_rows WHERE position(to_char(muni_total, 'FM999,999,999') IN new_source) = 0;
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0411 gate: the summed municipal total is not in the new citation for %', v_bad;
  END IF;

  SELECT string_agg(rc_id::text, ', ') INTO v_bad
    FROM cc0411_rows WHERE new_source ~ '[^0-9,]0 votes, 0(\.0+)?%';
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0411 gate: the zero-vote sentence is still on the replacement for %', v_bad;
  END IF;

  -- A summed figure must say where its municipal set came from.
  SELECT string_agg(rc_id::text, ', ') INTO v_bad
    FROM cc0411_rows WHERE new_source NOT LIKE '%CERTIFIED 2024 general election results%';
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0411 gate: the new citation does not say where the municipal set came from, for %', v_bad;
  END IF;

  SELECT string_agg(rc_id::text, ', ') INTO v_bad
    FROM cc0411_rows WHERE new_source NOT LIKE '%AP race 20261103%';
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0411 gate: the new citation dropped the AP race id for %', v_bad;
  END IF;
END $$;

CREATE TEMP TABLE cc0411_before AS
  SELECT rc.id, rc.result, rc.result_certainty, rc.result_recorded_at
    FROM essentials.race_candidates rc JOIN cc0411_rows t ON t.rc_id = rc.id;
CREATE TEMP TABLE cc0411_counts AS
  SELECT (SELECT count(*) FROM essentials.office_terms) AS terms,
         (SELECT count(*) FROM essentials.race_candidates rc
            JOIN essentials.races r ON r.id = rc.race_id
            JOIN essentials.elections e ON e.id = r.election_id
           WHERE e.election_date = '2026-11-03' AND rc.result_certainty = 'certified') AS certified_general,
         (SELECT count(*) FROM essentials.race_candidates
           WHERE result_source ~ '[^0-9,]0 votes, 0(\.0+)?%') AS zero_vote_rows;

-- ─── 2. The write ───────────────────────────────────────────────────────────────
UPDATE essentials.race_candidates rc
   SET result_source = t.new_source
  FROM cc0411_rows t
 WHERE rc.id = t.rc_id
   AND md5(rc.result_source) = t.prior_md5;

-- ─── 3. Post-verify ─────────────────────────────────────────────────────────────
DO $$
DECLARE v_n integer; v_was integer; v_bad text;
BEGIN
  SELECT count(*) INTO v_n
    FROM cc0411_rows t JOIN essentials.race_candidates rc ON rc.id = t.rc_id
   WHERE rc.result_source = t.new_source;
  IF v_n <> 2 THEN RAISE EXCEPTION 'CC_0411 post: % of 2 rows carry their new citation', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE result_source ~ '[^0-9,]0 votes, 0(\.0+)?%';
  SELECT zero_vote_rows INTO v_was FROM cc0411_counts;
  IF v_was <> 3 THEN RAISE EXCEPTION 'CC_0411 post: the class held % rows before this file, expected 3', v_was; END IF;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0411 post: % rows still carry the zero-vote sentence, expected 1 (DiDomenico, blocked on Everett)', v_n;
  END IF;

  SELECT string_agg(b.id::text, ', ') INTO v_bad
    FROM cc0411_before b JOIN essentials.race_candidates rc ON rc.id = b.id
   WHERE rc.result IS DISTINCT FROM b.result OR rc.result_certainty IS DISTINCT FROM b.result_certainty;
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0411 post: the result moved on %', v_bad; END IF;

  SELECT string_agg(b.id::text, ', ') INTO v_bad
    FROM cc0411_before b JOIN essentials.race_candidates rc ON rc.id = b.id
   WHERE rc.result_recorded_at IS DISTINCT FROM b.result_recorded_at;
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0411 post: result_recorded_at moved on % — this file records no new result', v_bad;
  END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms;
  IF v_n <> (SELECT terms FROM cc0411_counts) THEN
    RAISE EXCEPTION 'CC_0411 post: office_terms moved from % to %', (SELECT terms FROM cc0411_counts), v_n;
  END IF;

  SELECT count(*) INTO v_n FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.election_date = '2026-11-03' AND rc.result_certainty = 'certified';
  IF v_n <> (SELECT certified_general FROM cc0411_counts) THEN
    RAISE EXCEPTION 'CC_0411 post: certified rows dated 2026-11-03 moved from % to %',
      (SELECT certified_general FROM cc0411_counts), v_n;
  END IF;
  IF (SELECT certified_general FROM cc0411_counts) = 0 THEN
    RAISE EXCEPTION 'CC_0411 post: the certified-row gate is watching an empty set and proves nothing';
  END IF;
END $$;

DROP TABLE IF EXISTS cc0411_before;
DROP TABLE IF EXISTS cc0411_counts;

COMMIT;
