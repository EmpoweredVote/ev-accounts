-- CC_0410 — the AP zero-vote prose, corrected for Wisconsin from the COUNTY CLERKS (8 rows)
--
-- WHY THIS FILE IS SEPARATE FROM CC_0409
-- ----------------------------------------------------------------------------
-- CC_0409 corrected 43 of the 54 remaining rows from each state's own return. Wisconsin was left
-- out because 🔴 WISCONSIN HAS NO STATE RETURN TO READ. The Wisconsin Elections Commission:
--
--   "Wisconsin does not have a statewide system for reporting unofficial results on Election
--    Night, and there is no central official website or feed where results are reported. State
--    law requires that counties post the unofficial election night numbers for each polling
--    place. The unofficial statewide and county results numbers that the public sees on Election
--    Night and the days thereafter come from the news media, including the Associated Press,
--    which collects them from the 72 county clerks' websites."
--    (elections.wi.gov/election-results, read 2026-11-12)
--
-- So the authority is the county clerks, and each district total here is ARITHMETIC — summed
-- across every county the district touches. That makes two things load bearing:
--
-- 🔴 1. THE COUNTY SET MUST BE COMPLETE. A missed county silently undercounts and nothing errors.
--      The set comes from WEC's OWN County by County Report for the 2026 Partisan Primary, and
--      ALL FIVE party sheets (Republican, Democratic, Constitution, Libertarian, Wisconsin Green)
--      agree on the set for all 8 districts. That agreement is the control, not an assumption.
--        AD 12  Milwaukee                                   AD 84  Racine, Walworth, Waukesha
--        AD 27  Calumet, Fond du Lac, Manitowoc, Sheboygan  AD 97  Jefferson, Waukesha
--        AD 83  Waukesha                                    AD 99  Dodge, Jefferson, Waukesha
--        SD 3   Milwaukee                                   SD 27  Dane
--
-- 🔴 2. EACH COUNTY FIGURE MUST BE READ AT FULL WIDTH. Several counties publish only PDFs whose
--      text extraction interleaves columns: Dodge's extracted text put AD 99's candidate total,
--      write-ins and ballots on lines belonging to the contest above it, and Racine's made the
--      arithmetic fail to close. Both were re-read from the rendered page before being used.
--      ⚠ Racine's "Total Votes" EXCLUDES its write-in line — confirmed across three contests on
--      the same page — so that column is not ballots cast and must not be used as a denominator.
--      ⚠ Jefferson's percentages are of ballots cast, not of votes, and do not sum to 100; only
--      its raw counts are used here.
--      ⚠ Manitowoc's official PDF is a SCAN with no text layer, and its per-ward tally sheet shows
--      only one ward column for AD 27 (Schleswig, 851). The county TOTAL is 2,140, taken from the
--      signed tabular statement — summing the one visible column would have undercounted by 1,289.
--
-- ⚠ CERTAINTY IS NOT UNIFORM ACROSS A SUMMED DISTRICT. Calumet and Manitowoc have completed county
-- canvasses (Manitowoc's is signed by its Board of Canvassers, dated 2026-11-09) while Fond du Lac
-- and Sheboygan still label their returns unofficial, so AD 27's total mixes the two. Each row's
-- citation says which counties are which. No row's result_certainty moves: there is no Wisconsin
-- state canvass yet, and no county publishes a winner flag, so the CALL stays AP's throughout.
--
-- WHAT THIS FILE DOES
-- ----------------------------------------------------------------------------
-- One row, one column, 8 rows. result, result_certainty and result_recorded_at are gated
-- UNCHANGED. The prior value of every row travels in the payload beside its md5: gate 0 refuses
-- the file unless the recorded text hashes to the recorded hash, gate 1 refuses unless the LIVE
-- column hashes to the same thing, so the record of what was overwritten is checked against
-- production rather than asserted in a comment.
--
-- 🔴 THE REMAINING 3 ARE DELIBERATELY UNTOUCHED, AND THE POST-VERIFY ASSERTS EXACTLY 3.
-- Massachusetts publishes no unofficial results at all: "We do not publish unofficial election
-- results ... local officials don't report unofficial results to the state", and cities and towns
-- have 15 days after a state election to certify
-- (sec.state.ma.us/divisions/elections/voting-information/announcing-certifying.htm, read
-- 2026-11-12). Its 2026 general is not yet in the state's results database. Those 3 rows need the
-- municipal clerks of Cambridge, Somerville and the Middlesex & Suffolk cities, or the state's
-- official results once they are published.

BEGIN;

CREATE TEMP TABLE cc0410_rows (
  rc_id         uuid PRIMARY KEY,
  prior_md5     text    NOT NULL,
  prior_source  text    NOT NULL,   -- verbatim, the value this file overwrites
  county_total  integer NOT NULL,   -- the sum of the county clerks' figures
  new_source    text    NOT NULL
) ON COMMIT DROP;

INSERT INTO cc0410_rows (rc_id, prior_md5, prior_source, county_total, new_source) VALUES
  ('1184fd68-6e1f-4701-8a4b-ee8b6096c341'::uuid, 'f97b8c53c8d60429483675f56f2eb668', 'Associated Press race call for the 2026-11-03 general election, read 2026-11-08 from AP''s own per-state results feed (interactives.apelections.org/election-results/data-live/2026-11-03/results/races/WI/, race 20261103WI50207, candidate 155973): Russell Goodwin (Dem) 0 votes, 0%, recorded as won. This is AP''s call and NOT the state canvass; AP reports this race as not yet certified. Matched to our row on basis ''exact-first-last''.', 15575, 'Wisconsin publishes NO statewide unofficial return — the Wisconsin Elections Commission states that "Wisconsin does not have a statewide system for reporting unofficial results on Election Night, and there is no central official website or feed where results are reported", and that the statewide numbers the public sees come from the news media, "including the Associated Press, which collects them from the 72 county clerks'' websites" (elections.wi.gov/election-results, read 2026-11-12). So this figure is summed from the county clerks themselves. Russell Antonio Goodwin, Sr. (DEM) took 15,575 votes for Assembly District 12, with 292 write-in or scattering votes across the same counties. Per county: Milwaukee County 15,575 (write-in 292, 28 of 28 wards; unofficial election-night website, Last Updated Nov. 4, 2026 0:50 a.m.; county.milwaukee.gov/EN/County-Clerk/Off-Nav/Election-Results/11-3-26-General-Election--Unofficial-Results-Election-Night-Website). The district''s county set is Milwaukee, taken from the Wisconsin Elections Commission''s own County by County Report for the 2026 Partisan Primary, where all five party sheets agree on that set. There is no Wisconsin state canvass yet and no county publishes a winner flag, so the WIN remains the Associated Press''s call — AP race 20261103WI50207, candidate 155973. AP''s feed marks this race metadata.uncontested = true and publishes no tabulation for it; the figure in the citation this row carried before was AP declining to count an uncontested race, not a tally of the ballots. Read 2026-11-12. Corrected by CC_0410, which records the previous citation verbatim and gates on its hash.'),
  ('8edd230d-3533-45fb-b122-da18de547cc8'::uuid, '80bc33772c88f7a3b18703ba6172233e', 'Associated Press race call for the 2026-11-03 general election, read 2026-11-08 from AP''s own per-state results feed (interactives.apelections.org/election-results/data-live/2026-11-03/results/races/WI/, race 20261103WI50252, candidate 164873): Lindee Brill (GOP) 0 votes, 0%, recorded as won. This is AP''s call and NOT the state canvass; AP reports this race as not yet certified. Matched to our row on basis ''exact-full-name''.', 22971, 'Wisconsin publishes NO statewide unofficial return — the Wisconsin Elections Commission states that "Wisconsin does not have a statewide system for reporting unofficial results on Election Night, and there is no central official website or feed where results are reported", and that the statewide numbers the public sees come from the news media, "including the Associated Press, which collects them from the 72 county clerks'' websites" (elections.wi.gov/election-results, read 2026-11-12). So this figure is summed from the county clerks themselves. Lindee Brill (REP) took 22,971 votes for Assembly District 27 — Calumet 111 + Fond du Lac 3,712 + Manitowoc 2,140 + Sheboygan 17,008, with 791 write-in or scattering votes across the same counties. Per county: Calumet County 111 (write-in 6, county canvass; county canvass, published as NOV 2026 Official Election Results - State and Federal; calumetcounty.org/DocumentCenter/View/12335/20261110-Canvass---State-and-Federal); Fond du Lac County 3,712 (write-in 65, 5 of 5 precincts; unofficial Election Summary Report; fdlco.wi.gov, November 3, 2026, Unofficial Election Summary Report); Manitowoc County 2,140 (write-in 56, county canvass; certified by the Manitowoc County Board of Canvassers, signed and dated Monday, November 9, 2026; manitowoccountywi.gov/wp-content/uploads/2026/11/11-3-2026-Official-Election-Results.pdf); Sheboygan County 17,008 (write-in 664, all municipalities listed; unofficial election night results, report generated 11/3/2026 11:44:52 PM; sheboygancounty.com, Unofficial Election Night Results). The district''s county set is Calumet, Fond du Lac, Manitowoc, Sheboygan, taken from the Wisconsin Elections Commission''s own County by County Report for the 2026 Partisan Primary, where all five party sheets agree on that set. ⚠ This total MIXES county canvasses (Calumet, Manitowoc) with returns the other counties still label unofficial, so it is not uniformly official. There is no Wisconsin state canvass yet and no county publishes a winner flag, so the WIN remains the Associated Press''s call — AP race 20261103WI50252, candidate 164873. AP''s feed marks this race metadata.uncontested = true and publishes no tabulation for it; the figure in the citation this row carried before was AP declining to count an uncontested race, not a tally of the ballots. Read 2026-11-12. Corrected by CC_0410, which records the previous citation verbatim and gates on its hash.'),
  ('e1d1a4d7-e138-4742-b099-a0c022500f02'::uuid, '0f14aa4f99012fd9cec0301c02f4493f', 'Associated Press race call for the 2026-11-03 general election, read 2026-11-08 from AP''s own per-state results feed (interactives.apelections.org/election-results/data-live/2026-11-03/results/races/WI/, race 20261103WI50420, candidate 164985): Dave Maxey (GOP) 0 votes, 0%, recorded as won. This is AP''s call and NOT the state canvass; AP reports this race as not yet certified. Matched to our row on basis ''exact-full-name''.', 22155, 'Wisconsin publishes NO statewide unofficial return — the Wisconsin Elections Commission states that "Wisconsin does not have a statewide system for reporting unofficial results on Election Night, and there is no central official website or feed where results are reported", and that the statewide numbers the public sees come from the news media, "including the Associated Press, which collects them from the 72 county clerks'' websites" (elections.wi.gov/election-results, read 2026-11-12). So this figure is summed from the county clerks themselves. Dave Maxey (REP) took 22,155 votes for Assembly District 83, with 954 write-in or scattering votes across the same counties. Per county: Waukesha County 22,155 (write-in 954, 34 of 34 units; unofficial results, final at 12:17 AM; electionresults.waukeshacounty.gov/contests.aspx?contest=-1). The district''s county set is Waukesha, taken from the Wisconsin Elections Commission''s own County by County Report for the 2026 Partisan Primary, where all five party sheets agree on that set. There is no Wisconsin state canvass yet and no county publishes a winner flag, so the WIN remains the Associated Press''s call — AP race 20261103WI50420, candidate 164985. AP''s feed marks this race metadata.uncontested = true and publishes no tabulation for it; the figure in the citation this row carried before was AP declining to count an uncontested race, not a tally of the ballots. Read 2026-11-12. Corrected by CC_0410, which records the previous citation verbatim and gates on its hash.'),
  ('0cde983c-e56c-46e9-99ea-b6d2247dcbc9'::uuid, 'e59078a5d790d78d536487f1101c7e3e', 'Associated Press race call for the 2026-11-03 general election, read 2026-11-08 from AP''s own per-state results feed (interactives.apelections.org/election-results/data-live/2026-11-03/results/races/WI/, race 20261103WI50423, candidate 156622): Chuck Wichgers (GOP) 0 votes, 0%, recorded as won. This is AP''s call and NOT the state canvass; AP reports this race as not yet certified. Matched to our row on basis ''exact-full-name''.', 24977, 'Wisconsin publishes NO statewide unofficial return — the Wisconsin Elections Commission states that "Wisconsin does not have a statewide system for reporting unofficial results on Election Night, and there is no central official website or feed where results are reported", and that the statewide numbers the public sees come from the news media, "including the Associated Press, which collects them from the 72 county clerks'' websites" (elections.wi.gov/election-results, read 2026-11-12). So this figure is summed from the county clerks themselves. Chuck Wichgers (REP) took 24,977 votes for Assembly District 84 — Waukesha 16,533 + Racine 8,378 + Walworth 66, with 656 write-in or scattering votes across the same counties. Per county: Waukesha County 16,533 (write-in 426, 12 of 12 units; unofficial results, final at 12:17 AM; electionresults.waukeshacounty.gov/contests.aspx?contest=-1); Racine County 8,378 (write-in 228, 3 of 3 precincts; Election Summary Report 11-03-2026 FINAL UNOFFICIAL, generated 11/4/2026 12:45:20 AM; racinecounty.gov, ElectionSummaryReportRPT_11-03-2026 FINAL UNOFFICIAL); Walworth County 66 (write-in 2, 1 of 1 precinct; COMPLETE FINAL UNOFFICIAL ELECTION NIGHT RESULTS, 11/3/2026 9:36:49 PM; co.walworth.wi.us, 11-03-2026 Summary Report). The district''s county set is Waukesha, Racine, Walworth, taken from the Wisconsin Elections Commission''s own County by County Report for the 2026 Partisan Primary, where all five party sheets agree on that set. There is no Wisconsin state canvass yet and no county publishes a winner flag, so the WIN remains the Associated Press''s call — AP race 20261103WI50423, candidate 156622. AP''s feed marks this race metadata.uncontested = true and publishes no tabulation for it; the figure in the citation this row carried before was AP declining to count an uncontested race, not a tally of the ballots. Read 2026-11-12. Corrected by CC_0410, which records the previous citation verbatim and gates on its hash.'),
  ('d67868c8-316b-423c-b499-fb4e21f4e4d4'::uuid, '06a204f3752a8a90edd440d814898e26', 'Associated Press race call for the 2026-11-03 general election, read 2026-11-08 from AP''s own per-state results feed (interactives.apelections.org/election-results/data-live/2026-11-03/results/races/WI/, race 20261103WI50462, candidate 156662): Cindi Duchow (GOP) 0 votes, 0%, recorded as won. This is AP''s call and NOT the state canvass; AP reports this race as not yet certified. Matched to our row on basis ''exact-full-name''.', 24860, 'Wisconsin publishes NO statewide unofficial return — the Wisconsin Elections Commission states that "Wisconsin does not have a statewide system for reporting unofficial results on Election Night, and there is no central official website or feed where results are reported", and that the statewide numbers the public sees come from the news media, "including the Associated Press, which collects them from the 72 county clerks'' websites" (elections.wi.gov/election-results, read 2026-11-12). So this figure is summed from the county clerks themselves. Cindi Duchow (REP) took 24,860 votes for Assembly District 97 — Waukesha 21,361 + Jefferson 3,499, with 664 write-in or scattering votes across the same counties. Per county: Waukesha County 21,361 (write-in 583, 16 of 16 units; unofficial results, final at 12:17 AM; electionresults.waukeshacounty.gov/contests.aspx?contest=-1); Jefferson County 3,499 (write-in 81, 6 of 6 precincts; county results page headed Official Results, carrying its own disclaimer that totals are subject to change; apps.jeffersoncountywi.gov/jc/election/results/11032026). The district''s county set is Waukesha, Jefferson, taken from the Wisconsin Elections Commission''s own County by County Report for the 2026 Partisan Primary, where all five party sheets agree on that set. There is no Wisconsin state canvass yet and no county publishes a winner flag, so the WIN remains the Associated Press''s call — AP race 20261103WI50462, candidate 156662. AP''s feed marks this race metadata.uncontested = true and publishes no tabulation for it; the figure in the citation this row carried before was AP declining to count an uncontested race, not a tally of the ballots. Read 2026-11-12. Corrected by CC_0410, which records the previous citation verbatim and gates on its hash.'),
  ('b3426b02-daf7-46ab-a352-56897c25f179'::uuid, '0963986565b838af5083ebd6335748fd', 'Associated Press race call for the 2026-11-03 general election, read 2026-11-08 from AP''s own per-state results feed (interactives.apelections.org/election-results/data-live/2026-11-03/results/races/WI/, race 20261103WI50468, candidate 165012): Barbara Dittrich (GOP) 0 votes, 0%, recorded as won. This is AP''s call and NOT the state canvass; AP reports this race as not yet certified. Matched to our row on basis ''exact-full-name''.', 23898, 'Wisconsin publishes NO statewide unofficial return — the Wisconsin Elections Commission states that "Wisconsin does not have a statewide system for reporting unofficial results on Election Night, and there is no central official website or feed where results are reported", and that the statewide numbers the public sees come from the news media, "including the Associated Press, which collects them from the 72 county clerks'' websites" (elections.wi.gov/election-results, read 2026-11-12). So this figure is summed from the county clerks themselves. Barbara Dittrich (REP) took 23,898 votes for Assembly District 99 — Waukesha 18,823 + Jefferson 1,925 + Dodge 3,150, with 802 write-in or scattering votes across the same counties. Per county: Waukesha County 18,823 (write-in 681, 11 of 11 units; unofficial results, final at 12:17 AM; electionresults.waukeshacounty.gov/contests.aspx?contest=-1); Jefferson County 1,925 (write-in 71, 2 of 2 precincts; county results page headed Official Results, carrying its own disclaimer that totals are subject to change; apps.jeffersoncountywi.gov/jc/election/results/11032026); Dodge County 3,150 (write-in 50, 5 of 5 precincts; Summary Results Report, UNOFFICIAL RESULTS, 11/03/2026 10:19 PM; co.dodge.wi.gov, Summary Report - Unofficial Results). The district''s county set is Waukesha, Jefferson, Dodge, taken from the Wisconsin Elections Commission''s own County by County Report for the 2026 Partisan Primary, where all five party sheets agree on that set. There is no Wisconsin state canvass yet and no county publishes a winner flag, so the WIN remains the Associated Press''s call — AP race 20261103WI50468, candidate 165012. AP''s feed marks this race metadata.uncontested = true and publishes no tabulation for it; the figure in the citation this row carried before was AP declining to count an uncontested race, not a tally of the ballots. Read 2026-11-12. Corrected by CC_0410, which records the previous citation verbatim and gates on its hash.'),
  ('fa679dd6-e4e8-4b15-9d94-cbdba5bc3e06'::uuid, '0426258a01d51be698ba79f230b81711', 'Associated Press race call for the 2026-11-03 general election, read 2026-11-08 from AP''s own per-state results feed (interactives.apelections.org/election-results/data-live/2026-11-03/results/races/WI/, race 20261103WI50081, candidate 48378): Tim Carpenter (Dem) 0 votes, 0%, recorded as won. This is AP''s call and NOT the state canvass; AP reports this race as not yet certified. Matched to our row on basis ''exact-full-name''.', 36046, 'Wisconsin publishes NO statewide unofficial return — the Wisconsin Elections Commission states that "Wisconsin does not have a statewide system for reporting unofficial results on Election Night, and there is no central official website or feed where results are reported", and that the statewide numbers the public sees come from the news media, "including the Associated Press, which collects them from the 72 county clerks'' websites" (elections.wi.gov/election-results, read 2026-11-12). So this figure is summed from the county clerks themselves. Tim Carpenter (DEM) took 36,046 votes for State Senate District 3, with 770 write-in or scattering votes across the same counties. Per county: Milwaukee County 36,046 (write-in 770, 105 of 105 wards; unofficial election-night website, Last Updated Nov. 4, 2026 0:50 a.m.; county.milwaukee.gov/EN/County-Clerk/Off-Nav/Election-Results/11-3-26-General-Election--Unofficial-Results-Election-Night-Website). The district''s county set is Milwaukee, taken from the Wisconsin Elections Commission''s own County by County Report for the 2026 Partisan Primary, where all five party sheets agree on that set. There is no Wisconsin state canvass yet and no county publishes a winner flag, so the WIN remains the Associated Press''s call — AP race 20261103WI50081, candidate 48378. AP''s feed marks this race metadata.uncontested = true and publishes no tabulation for it; the figure in the citation this row carried before was AP declining to count an uncontested race, not a tally of the ballots. Read 2026-11-12. Corrected by CC_0410, which records the previous citation verbatim and gates on its hash.'),
  ('83a95c0a-2dd0-4b9f-b995-c9a235fa9300'::uuid, '59dfb79b0c63a0f15ed2ed13262f565e', 'Associated Press race call for the 2026-11-03 general election, read 2026-11-08 from AP''s own per-state results feed (interactives.apelections.org/election-results/data-live/2026-11-03/results/races/WI/, race 20261103WI50153, candidate 154763): Dianne Hesselbein (Dem) 0 votes, 0%, recorded as won. This is AP''s call and NOT the state canvass; AP reports this race as not yet certified. Matched to our row on basis ''exact-full-name''.', 87902, 'Wisconsin publishes NO statewide unofficial return — the Wisconsin Elections Commission states that "Wisconsin does not have a statewide system for reporting unofficial results on Election Night, and there is no central official website or feed where results are reported", and that the statewide numbers the public sees come from the news media, "including the Associated Press, which collects them from the 72 county clerks'' websites" (elections.wi.gov/election-results, read 2026-11-12). So this figure is summed from the county clerks themselves. Dianne Hesselbein (DEM) took 87,902 votes for State Senate District 27, with 1,861 write-in or scattering votes across the same counties. Per county: Dane County 87,902 (write-in 1,861, 81 of 81 precincts; county clerk''s 2026 General Election page, headed Unofficial Results; elections.countyofdane.com/Election-Result/197). The district''s county set is Dane, taken from the Wisconsin Elections Commission''s own County by County Report for the 2026 Partisan Primary, where all five party sheets agree on that set. There is no Wisconsin state canvass yet and no county publishes a winner flag, so the WIN remains the Associated Press''s call — AP race 20261103WI50153, candidate 154763. AP''s feed marks this race metadata.uncontested = true and publishes no tabulation for it; the figure in the citation this row carried before was AP declining to count an uncontested race, not a tally of the ballots. Read 2026-11-12. Corrected by CC_0410, which records the previous citation verbatim and gates on its hash.');

-- ─── 1. Pre-gates ───────────────────────────────────────────────────────────────
DO $$
DECLARE v_n integer; v_bad text;
BEGIN
  SELECT string_agg(rc_id::text, ', ') INTO v_bad
    FROM cc0410_rows WHERE md5(prior_source) <> prior_md5;
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0410 gate: the prior value recorded in this file does not hash to its recorded md5 for %', v_bad;
  END IF;

  SELECT count(*) INTO v_n FROM cc0410_rows;
  IF v_n <> 8 THEN RAISE EXCEPTION 'CC_0410 gate: % rows in the payload, expected 8', v_n; END IF;

  SELECT string_agg(t.rc_id::text, ', ') INTO v_bad
    FROM cc0410_rows t JOIN essentials.race_candidates rc ON rc.id = t.rc_id
   WHERE md5(rc.result_source) <> t.prior_md5;
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0410 gate: result_source has changed since this file was written, for %', v_bad;
  END IF;

  SELECT count(*) INTO v_n
    FROM cc0410_rows t JOIN essentials.race_candidates rc ON rc.id = t.rc_id
   WHERE rc.result_source ~ '[^0-9,]0 votes, 0(\.0+)?%';
  IF v_n <> 8 THEN RAISE EXCEPTION 'CC_0410 gate: only % of 8 targets carry the zero-vote sentence', v_n; END IF;

  -- 🔴 Every target must be a WISCONSIN row. This file's reasoning is Wisconsin-specific and its
  -- sources are Wisconsin counties; applying it anywhere else would attach the wrong provenance.
  SELECT count(*) INTO v_n
    FROM cc0410_rows t
    JOIN essentials.race_candidates rc ON rc.id = t.rc_id
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'wi';
  IF v_n <> 8 THEN RAISE EXCEPTION 'CC_0410 gate: only % of 8 targets are Wisconsin rows', v_n; END IF;

  SELECT count(*) INTO v_n
    FROM cc0410_rows t JOIN essentials.race_candidates rc ON rc.id = t.rc_id
   WHERE rc.result = 'won' AND rc.result_certainty = 'called';
  IF v_n <> 8 THEN RAISE EXCEPTION 'CC_0410 gate: % of 8 targets are won/called; this file corrects a citation, not a result', v_n; END IF;

  -- "Not false" is not "true": the summed county total must be IN each new citation.
  SELECT string_agg(rc_id::text, ', ') INTO v_bad
    FROM cc0410_rows
   WHERE position(to_char(county_total, 'FM999,999,999') IN new_source) = 0;
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0410 gate: the summed county total is not in the new citation for %', v_bad;
  END IF;

  -- The replacement must not re-state the sentence it corrects.
  SELECT string_agg(rc_id::text, ', ') INTO v_bad
    FROM cc0410_rows WHERE new_source ~ '[^0-9,]0 votes, 0(\.0+)?%';
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0410 gate: the zero-vote sentence is still on the replacement for %', v_bad;
  END IF;

  -- A summed figure is worthless without its parts: every citation must name its county set.
  SELECT string_agg(rc_id::text, ', ') INTO v_bad
    FROM cc0410_rows WHERE new_source NOT LIKE '%County by County Report%';
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0410 gate: the new citation does not say where the county set came from, for %', v_bad;
  END IF;

  SELECT string_agg(rc_id::text, ', ') INTO v_bad
    FROM cc0410_rows WHERE new_source NOT LIKE '%AP race 20261103%';
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0410 gate: the new citation dropped the AP race id for %', v_bad;
  END IF;
END $$;

CREATE TEMP TABLE cc0410_before AS
  SELECT rc.id, rc.result, rc.result_certainty, rc.result_recorded_at
    FROM essentials.race_candidates rc JOIN cc0410_rows t ON t.rc_id = rc.id;
CREATE TEMP TABLE cc0410_counts AS
  SELECT (SELECT count(*) FROM essentials.office_terms) AS terms,
         -- Repo-wide and dated, NOT scoped to one election id. CC_0409 carried this gate scoped to
         -- Indiana's election while touching no Indiana row, so it compared 0 with 0 and could
         -- never have failed. Measured now: 6, all in the SC 2026 Statewide General.
         (SELECT count(*) FROM essentials.race_candidates rc
            JOIN essentials.races r ON r.id = rc.race_id
            JOIN essentials.elections e ON e.id = r.election_id
           WHERE e.election_date = '2026-11-03' AND rc.result_certainty = 'certified') AS certified_general,
         (SELECT count(*) FROM essentials.race_candidates
           WHERE result_source ~ '[^0-9,]0 votes, 0(\.0+)?%') AS zero_vote_rows;

-- ─── 2. The write ───────────────────────────────────────────────────────────────
UPDATE essentials.race_candidates rc
   SET result_source = t.new_source
  FROM cc0410_rows t
 WHERE rc.id = t.rc_id
   AND md5(rc.result_source) = t.prior_md5;

-- ─── 3. Post-verify ─────────────────────────────────────────────────────────────
DO $$
DECLARE v_n integer; v_was integer; v_bad text;
BEGIN
  SELECT count(*) INTO v_n
    FROM cc0410_rows t JOIN essentials.race_candidates rc ON rc.id = t.rc_id
   WHERE rc.result_source = t.new_source;
  IF v_n <> 8 THEN RAISE EXCEPTION 'CC_0410 post: % of 8 rows carry their new citation', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE result_source ~ '[^0-9,]0 votes, 0(\.0+)?%';
  SELECT zero_vote_rows INTO v_was FROM cc0410_counts;
  IF v_was <> 11 THEN RAISE EXCEPTION 'CC_0410 post: the class held % rows before this file, expected 11', v_was; END IF;
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CC_0410 post: % rows still carry the zero-vote sentence, expected 3 (MA, which publishes no unofficial results)', v_n;
  END IF;

  SELECT string_agg(b.id::text, ', ') INTO v_bad
    FROM cc0410_before b JOIN essentials.race_candidates rc ON rc.id = b.id
   WHERE rc.result IS DISTINCT FROM b.result
      OR rc.result_certainty IS DISTINCT FROM b.result_certainty;
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'CC_0410 post: the result moved on %', v_bad; END IF;

  SELECT string_agg(b.id::text, ', ') INTO v_bad
    FROM cc0410_before b JOIN essentials.race_candidates rc ON rc.id = b.id
   WHERE rc.result_recorded_at IS DISTINCT FROM b.result_recorded_at;
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'CC_0410 post: result_recorded_at moved on % — this file records no new result', v_bad;
  END IF;

  SELECT count(*) INTO v_n FROM essentials.office_terms;
  IF v_n <> (SELECT terms FROM cc0410_counts) THEN
    RAISE EXCEPTION 'CC_0410 post: office_terms moved from % to %', (SELECT terms FROM cc0410_counts), v_n;
  END IF;

  SELECT count(*) INTO v_n FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.election_date = '2026-11-03' AND rc.result_certainty = 'certified';
  IF v_n <> (SELECT certified_general FROM cc0410_counts) THEN
    RAISE EXCEPTION 'CC_0410 post: certified rows dated 2026-11-03 moved from % to %',
      (SELECT certified_general FROM cc0410_counts), v_n;
  END IF;
  -- 🟢 And the gate is not vacuous: it must be watching a non-zero population.
  IF (SELECT certified_general FROM cc0410_counts) = 0 THEN
    RAISE EXCEPTION 'CC_0410 post: the certified-row gate is watching an empty set and proves nothing';
  END IF;
END $$;

DROP TABLE IF EXISTS cc0410_before;
DROP TABLE IF EXISTS cc0410_counts;

COMMIT;
