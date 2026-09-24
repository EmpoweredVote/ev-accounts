-- CA_0237_record_2026_governor_primary_results.sql
--
-- Slot CA_0237 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- Stale-primaries batch 1 (after the Senate pass, CA_0231): record the certified outcome of the past
-- 2026 GOVERNOR primaries in CA HI KS ME MI TN, plus the MA State Senate Second Middlesex Democratic
-- primary — 49 race_candidates rows that still carried no result after their primary date.
-- Same shape as CA_0231 / 1585 / 1842: set result, result_source, result_recorded_at. candidate_status
-- is NOT touched; nothing is deleted or deactivated.
--
--   won 11 · lost 36 · advanced 2 (California's top-two: Becerra, Hilton)
--
-- OUT OF SCOPE here, on purpose:
--   - Maine's U.S. House primary rows (8): U.S. House post-primary reconciliation is Phase 167
--     (Chris Cantrell's workstream, migrations 1853-1859). Left for it.
--   - Indiana (83 rows): another session holds county leases there (Indiana open items).
--   - Utah (165) and Wisconsin (313): mostly legislative and local; later batches.
--
-- SOURCES (fetched 2026-09-24; each row's result_source names its document and figures)
--   CA  Statement of Vote 19-gov.xlsx, totals match 06-sov-summary.pdf; the certified general list
--       (2026-08-27) holds only Becerra and Hilton for Governor.
--   HI  Office of Elections "SUMMARY REPORT FINAL" (Certified Reports); precinct file sums agree.
--   KS  Secretary of State "2026 Primary Election Official Vote Totals" (one document).
--   MA  electionstats 173191; 65 precinct rows sum to the totals.
--   ME  Secretary of State RCV Summary Reports (final-round results); the general candidate list
--       agrees on both nominees (Pingree D, Charles R). Neither file says "certified" in words.
--   MI  Bureau of Elections GEN candidate listing (who went on to November); BSC certified 2026-08-24.
--       Statewide vote totals were NOT reachable from a state source, so MI rows carry no counts.
--   TN  Secretary of State primary-by-county PDFs, STATE TOTALS.
--
-- Maine and California primaries are each ONE race row with no primary_party: Maine holds both party
-- contests (two winners), California is a top-two (two 'advanced'). The gate allows exactly that.
--
-- IDEMPOTENT: every write is guarded on result IS NULL. Dry run: the body wrapped BEGIN; ... ROLLBACK;
-- against prod, applied twice in one transaction, then the rollback confirmed by re-reading the rows.
-- ROLLBACK (once applied): UPDATE essentials.race_candidates SET result = NULL, result_source = NULL,
--   result_recorded_at = NULL WHERE result_source LIKE '%Recorded by CA_0237 (2026-09-24).';

BEGIN;

CREATE TEMP TABLE ca0237_result ON COMMIT DROP AS
SELECT v.rc_id, v.st, v.full_name, v.status_before, v.result, v.result_source
FROM (VALUES
  ('28e308c3-f371-48c9-9580-73c4b8779389'::uuid, 'CA', 'Steve Hilton', 'active', 'advanced',
   'CA Secretary of State Statement of Vote, June 2 2026 Primary, Governor (elections.cdn.sos.ca.gov/sov/2026-primary/sov/19-gov.xlsx; state totals match 06-sov-summary.pdf); top-two primary; the 2026-08-27 certified list of general candidates names Becerra (DEM) and Hilton (REP) only. Steve Hilton: 2,277,318 (24.6%), 2nd; Steyer 3rd with 2,110,707. Recorded by CA_0237 (2026-09-24).'),
  ('e70e25b1-c0e4-456c-ad2f-2ba12b6705d0'::uuid, 'CA', 'Xavier Becerra', 'active', 'advanced',
   'CA Secretary of State Statement of Vote, June 2 2026 Primary, Governor (elections.cdn.sos.ca.gov/sov/2026-primary/sov/19-gov.xlsx; state totals match 06-sov-summary.pdf); top-two primary; the 2026-08-27 certified list of general candidates names Becerra (DEM) and Hilton (REP) only. Xavier Becerra: 2,591,857 (28.0%), 1st. Recorded by CA_0237 (2026-09-24).'),
  ('ab70a60e-fa4f-4305-91f9-8a1d61684fe1'::uuid, 'HI', 'Duke Bourgoin', 'active', 'lost',
   'Hawaii Office of Elections, Primary Election 2026 SUMMARY REPORT FINAL, Certified Reports (elections.hawaii.gov/wp-content/results/2026 Primary/summary.txt and histatewide.pdf; the precinct file media.txt sums to the same totals), Governor, 2026-08-08. Duke Bourgoin: D 4,595; Green 184,289. Recorded by CA_0237 (2026-09-24).'),
  ('eb430262-356f-4680-b0f3-b5f09cf28d41'::uuid, 'HI', 'George "Teva" Lucas-Tadeo', 'active', 'lost',
   'Hawaii Office of Elections, Primary Election 2026 SUMMARY REPORT FINAL, Certified Reports (elections.hawaii.gov/wp-content/results/2026 Primary/summary.txt and histatewide.pdf; the precinct file media.txt sums to the same totals), Governor, 2026-08-08. George "Teva" Lucas-Tadeo: D 8,134; Green 184,289. Recorded by CA_0237 (2026-09-24).'),
  ('c308a824-0f59-49f7-83e4-0532b540334a'::uuid, 'HI', 'Josh Green', 'active', 'won',
   'Hawaii Office of Elections, Primary Election 2026 SUMMARY REPORT FINAL, Certified Reports (elections.hawaii.gov/wp-content/results/2026 Primary/summary.txt and histatewide.pdf; the precinct file media.txt sums to the same totals), Governor, 2026-08-08. Josh Green: D 184,289 (81.7%). Recorded by CA_0237 (2026-09-24).'),
  ('a9d7faa1-b65e-4729-88fd-78bde2e5072e'::uuid, 'HI', 'Lauren Kapoliahi''iaka Shim', 'active', 'lost',
   'Hawaii Office of Elections, Primary Election 2026 SUMMARY REPORT FINAL, Certified Reports (elections.hawaii.gov/wp-content/results/2026 Primary/summary.txt and histatewide.pdf; the precinct file media.txt sums to the same totals), Governor, 2026-08-08. Lauren Kapoliahi''iaka Shim: D 11,199; Green 184,289. Recorded by CA_0237 (2026-09-24).'),
  ('ce07f42f-7dc6-49ef-bd12-0c9a85039585'::uuid, 'HI', 'Gary Cordery', 'active', 'won',
   'Hawaii Office of Elections, Primary Election 2026 SUMMARY REPORT FINAL, Certified Reports (elections.hawaii.gov/wp-content/results/2026 Primary/summary.txt and histatewide.pdf; the precinct file media.txt sums to the same totals), Governor, 2026-08-08. Gary Cordery: R 36,428 (66.6%). Recorded by CA_0237 (2026-09-24).'),
  ('0d0a97a4-1e13-4308-98e7-9958d0255ed4'::uuid, 'HI', 'Ken Fujiyama', 'active', 'lost',
   'Hawaii Office of Elections, Primary Election 2026 SUMMARY REPORT FINAL, Certified Reports (elections.hawaii.gov/wp-content/results/2026 Primary/summary.txt and histatewide.pdf; the precinct file media.txt sums to the same totals), Governor, 2026-08-08. Ken Fujiyama: R 11,599; Cordery 36,428. Recorded by CA_0237 (2026-09-24).'),
  ('3659fda2-ae50-4308-9a7d-c05a099ba463'::uuid, 'KS', 'Cindy Holscher', 'active', 'won',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), Governor / Lt. Governor. Cindy Holscher: D 110,407 (48.76%). Recorded by CA_0237 (2026-09-24).'),
  ('1945b15f-8019-4cb7-8c57-da0545649372'::uuid, 'KS', 'Curt Skoog', 'active', 'lost',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), Governor / Lt. Governor. Curt Skoog: D 28,399; Holscher 110,407. Recorded by CA_0237 (2026-09-24).'),
  ('8c2f6ca7-0a37-4b5d-acb7-29c87e06c944'::uuid, 'KS', 'Ethan Corson', 'active', 'lost',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), Governor / Lt. Governor. Ethan Corson: D 87,601; Holscher 110,407. Recorded by CA_0237 (2026-09-24).'),
  ('099c1bf3-2552-41a0-8fc6-60dc541f153b'::uuid, 'KS', 'Charlotte O''Hara', 'active', 'lost',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), Governor / Lt. Governor. Charlotte O''Hara: R 14,650; Masterson 148,685. Recorded by CA_0237 (2026-09-24).'),
  ('2cc44618-d7ba-4d51-8c48-981d6258f6cc'::uuid, 'KS', 'Nick Reinecker', 'active', 'lost',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), Governor / Lt. Governor. Nick Reinecker: R 7,202; Masterson 148,685. Recorded by CA_0237 (2026-09-24).'),
  ('d74f0084-0ddb-458a-9f0d-7a58134a271c'::uuid, 'KS', 'Philip Sarnecki', 'active', 'lost',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), Governor / Lt. Governor. Philip Sarnecki: R 77,003; Masterson 148,685. Recorded by CA_0237 (2026-09-24).'),
  ('8c427f31-99c9-4148-a8cd-af8837db8d28'::uuid, 'KS', 'Scott Schwab', 'active', 'lost',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), Governor / Lt. Governor. Scott Schwab: R 37,664; Masterson 148,685. Recorded by CA_0237 (2026-09-24).'),
  ('be16349c-a0eb-450c-a398-f3c4d2c73d27'::uuid, 'KS', 'Stacy Rogers', 'active', 'lost',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), Governor / Lt. Governor. Stacy Rogers: R 11,943 (ballot name Stacy L Rogers); Masterson 148,685. Recorded by CA_0237 (2026-09-24).'),
  ('2b863100-726b-4269-a6b0-e09297794815'::uuid, 'KS', 'Ty Masterson', 'active', 'won',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), Governor / Lt. Governor. Ty Masterson: R 148,685 (43.20%). Recorded by CA_0237 (2026-09-24).'),
  ('2165a968-b9fa-499d-8ba2-d9dbe431eedc'::uuid, 'KS', 'Vicki Schmidt', 'active', 'lost',
   'Kansas Secretary of State, 2026 Primary Election Official Vote Totals (sos.ks.gov/elections/26elec/2026-Primary-Election-Official-Vote-Totals.pdf, created 2026-09-01), Governor / Lt. Governor. Vicki Schmidt: R 47,056; Masterson 148,685. Recorded by CA_0237 (2026-09-24).'),
  ('224f0e12-6362-4407-908f-8bf5165527cd'::uuid, 'MA', 'Burhan Azeem', 'active', 'lost',
   'Secretary of the Commonwealth, electionstats.state.ma.us election 173191, "2026 State Senate Democratic Primary 2nd Middlesex District", 2026-09-01 (65 precinct rows sum to the totals); the Republican contest (173192) had no candidates. Burhan Azeem: 6,201; Uyterhoeven 12,546. Recorded by CA_0237 (2026-09-24).'),
  ('caa66aa6-cd0e-47df-a765-558674cab6d7'::uuid, 'MA', 'Christine Barber', 'active', 'lost',
   'Secretary of the Commonwealth, electionstats.state.ma.us election 173191, "2026 State Senate Democratic Primary 2nd Middlesex District", 2026-09-01 (65 precinct rows sum to the totals); the Republican contest (173192) had no candidates. Christine Barber: 10,340; Uyterhoeven 12,546. Recorded by CA_0237 (2026-09-24).'),
  ('ee2a33ac-2e0e-49c8-b65f-ece7aa05a52c'::uuid, 'MA', 'Erika Uyterhoeven', 'active', 'won',
   'Secretary of the Commonwealth, electionstats.state.ma.us election 173191, "2026 State Senate Democratic Primary 2nd Middlesex District", 2026-09-01 (65 precinct rows sum to the totals); the Republican contest (173192) had no candidates. Erika Uyterhoeven: 12,546 (36.9%). Recorded by CA_0237 (2026-09-24).'),
  ('002edc24-bb45-4290-9955-26e96db14a73'::uuid, 'MA', 'Matt McLaughlin', 'active', 'lost',
   'Secretary of the Commonwealth, electionstats.state.ma.us election 173191, "2026 State Senate Democratic Primary 2nd Middlesex District", 2026-09-01 (65 precinct rows sum to the totals); the Republican contest (173192) had no candidates. Matt McLaughlin: 4,218; Uyterhoeven 12,546. Recorded by CA_0237 (2026-09-24).'),
  ('0f08fb06-7562-4779-9738-b293dc0db988'::uuid, 'MA', 'Tom Hopcroft', 'active', 'lost',
   'Secretary of the Commonwealth, electionstats.state.ma.us election 173191, "2026 State Senate Democratic Primary 2nd Middlesex District", 2026-09-01 (65 precinct rows sum to the totals); the Republican contest (173192) had no candidates. Tom Hopcroft: 666; Uyterhoeven 12,546. Recorded by CA_0237 (2026-09-24).'),
  ('4417a0a1-5207-4442-9688-59153e07518d'::uuid, 'ME', 'Angus King III', 'filed', 'lost',
   'Maine Secretary of State, June 9 2026 primary, Governor, ranked-choice (inline-files "GOV Democratic RCV Summary Report.pdf" and "GOV Republican RCV Summary Reportxlsx.pdf"; the SOS "2026 General Candidate List - FINAL" names Pingree (D), Charles (R) and Rick Bennett (I) for Governor). Angus King III: D, eliminated after round 1 (17,860). Recorded by CA_0237 (2026-09-24).'),
  ('ac97cd66-3706-488a-bf2a-d1a9f8304827'::uuid, 'ME', 'Benjamin Midgley', 'filed', 'lost',
   'Maine Secretary of State, June 9 2026 primary, Governor, ranked-choice (inline-files "GOV Democratic RCV Summary Report.pdf" and "GOV Republican RCV Summary Reportxlsx.pdf"; the SOS "2026 General Candidate List - FINAL" names Pingree (D), Charles (R) and Rick Bennett (I) for Governor). Benjamin Midgley: R, final round 39,499 / Charles 59,873. Recorded by CA_0237 (2026-09-24).'),
  ('9555015c-96ce-4bfe-8c22-4e7cb2c25516'::uuid, 'ME', 'David Jones', 'filed', 'lost',
   'Maine Secretary of State, June 9 2026 primary, Governor, ranked-choice (inline-files "GOV Democratic RCV Summary Report.pdf" and "GOV Republican RCV Summary Reportxlsx.pdf"; the SOS "2026 General Candidate List - FINAL" names Pingree (D), Charles (R) and Rick Bennett (I) for Governor). David Jones: R, eliminated after round 3 (4,048). Recorded by CA_0237 (2026-09-24).'),
  ('6c2ee27b-1cf1-4386-aafe-4a288af8be3b'::uuid, 'ME', 'Garrett Mason', 'filed', 'lost',
   'Maine Secretary of State, June 9 2026 primary, Governor, ranked-choice (inline-files "GOV Democratic RCV Summary Report.pdf" and "GOV Republican RCV Summary Reportxlsx.pdf"; the SOS "2026 General Candidate List - FINAL" names Pingree (D), Charles (R) and Rick Bennett (I) for Governor). Garrett Mason: R, eliminated after round 5 (16,438). Recorded by CA_0237 (2026-09-24).'),
  ('f91bb121-e593-4728-9e70-a46dda4bb6f0'::uuid, 'ME', 'Hannah Pingree', 'filed', 'won',
   'Maine Secretary of State, June 9 2026 primary, Governor, ranked-choice (inline-files "GOV Democratic RCV Summary Report.pdf" and "GOV Republican RCV Summary Reportxlsx.pdf"; the SOS "2026 General Candidate List - FINAL" names Pingree (D), Charles (R) and Rick Bennett (I) for Governor). Hannah Pingree: D, won the final RCV round (R4) 111,750 / Shah 86,950. Recorded by CA_0237 (2026-09-24).'),
  ('8215217e-e87b-44e9-8b6f-9291244fcbb8'::uuid, 'ME', 'James Libby', 'filed', 'lost',
   'Maine Secretary of State, June 9 2026 primary, Governor, ranked-choice (inline-files "GOV Democratic RCV Summary Report.pdf" and "GOV Republican RCV Summary Reportxlsx.pdf"; the SOS "2026 General Candidate List - FINAL" names Pingree (D), Charles (R) and Rick Bennett (I) for Governor). James Libby: R, eliminated after round 1 (1,831). Recorded by CA_0237 (2026-09-24).'),
  ('96892309-90f7-40f5-80fd-613d3035b0e5'::uuid, 'ME', 'Jonathan Bush', 'filed', 'lost',
   'Maine Secretary of State, June 9 2026 primary, Governor, ranked-choice (inline-files "GOV Democratic RCV Summary Report.pdf" and "GOV Republican RCV Summary Reportxlsx.pdf"; the SOS "2026 General Candidate List - FINAL" names Pingree (D), Charles (R) and Rick Bennett (I) for Governor). Jonathan Bush: R, eliminated after round 6 (31,104). Recorded by CA_0237 (2026-09-24).'),
  ('27cb7a06-8119-4f74-a965-356df6d247d3'::uuid, 'ME', 'Nirav Shah', 'filed', 'lost',
   'Maine Secretary of State, June 9 2026 primary, Governor, ranked-choice (inline-files "GOV Democratic RCV Summary Report.pdf" and "GOV Republican RCV Summary Reportxlsx.pdf"; the SOS "2026 General Candidate List - FINAL" names Pingree (D), Charles (R) and Rick Bennett (I) for Governor). Nirav Shah: D, led round 1 (58,606) but lost the final round 86,950 / Pingree 111,750. Recorded by CA_0237 (2026-09-24).'),
  ('c1bf9a07-9342-4f83-b84a-5f45daf91308'::uuid, 'ME', 'Owen McCarthy', 'filed', 'lost',
   'Maine Secretary of State, June 9 2026 primary, Governor, ranked-choice (inline-files "GOV Democratic RCV Summary Report.pdf" and "GOV Republican RCV Summary Reportxlsx.pdf"; the SOS "2026 General Candidate List - FINAL" names Pingree (D), Charles (R) and Rick Bennett (I) for Governor). Owen McCarthy: R, eliminated after round 4 (5,769). Recorded by CA_0237 (2026-09-24).'),
  ('f5b22122-3c82-46d8-89ec-5e21115a92ba'::uuid, 'ME', 'Robert Charles', 'filed', 'won',
   'Maine Secretary of State, June 9 2026 primary, Governor, ranked-choice (inline-files "GOV Democratic RCV Summary Report.pdf" and "GOV Republican RCV Summary Reportxlsx.pdf"; the SOS "2026 General Candidate List - FINAL" names Pingree (D), Charles (R) and Rick Bennett (I) for Governor). Robert Charles: R, won the final RCV round (R7) 59,873 / Midgley 39,499. Recorded by CA_0237 (2026-09-24).'),
  ('5ccf856f-583c-4a1b-95e5-3b6608e8545f'::uuid, 'ME', 'Robert Wessels', 'filed', 'lost',
   'Maine Secretary of State, June 9 2026 primary, Governor, ranked-choice (inline-files "GOV Democratic RCV Summary Report.pdf" and "GOV Republican RCV Summary Reportxlsx.pdf"; the SOS "2026 General Candidate List - FINAL" names Pingree (D), Charles (R) and Rick Bennett (I) for Governor). Robert Wessels: R, eliminated after round 2 (3,637). Recorded by CA_0237 (2026-09-24).'),
  ('7b42903a-760f-4093-b618-4557f5aa7e87'::uuid, 'ME', 'Shenna Bellows', 'filed', 'lost',
   'Maine Secretary of State, June 9 2026 primary, Governor, ranked-choice (inline-files "GOV Democratic RCV Summary Report.pdf" and "GOV Republican RCV Summary Reportxlsx.pdf"; the SOS "2026 General Candidate List - FINAL" names Pingree (D), Charles (R) and Rick Bennett (I) for Governor). Shenna Bellows: D, eliminated after round 2 (47,049). Recorded by CA_0237 (2026-09-24).'),
  ('39f9f02f-e400-4ebb-ab3c-fb320362995e'::uuid, 'ME', 'Troy Jackson', 'filed', 'lost',
   'Maine Secretary of State, June 9 2026 primary, Governor, ranked-choice (inline-files "GOV Democratic RCV Summary Report.pdf" and "GOV Republican RCV Summary Reportxlsx.pdf"; the SOS "2026 General Candidate List - FINAL" names Pingree (D), Charles (R) and Rick Bennett (I) for Governor). Troy Jackson: D, eliminated after round 3 (60,010); later the U.S. Senate replacement nominee (CA_0233). Recorded by CA_0237 (2026-09-24).'),
  ('25a23bb4-5b70-449d-bf7a-0e468aa83bfc'::uuid, 'MI', 'Chris Swanson', 'active', 'lost',
   'Michigan Bureau of Elections Official Candidate Listing: the 2026 GEN report (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026) names Benson/Brinks (D) and James/DeBoyer (R) for Governor; Board of State Canvassers certified the 2026-08-04 primary 2026-08-24. Statewide vote totals NOT reachable from a state source (mielections.us refused; mvic 403). Chris Swanson: absent from the GEN listing. Recorded by CA_0237 (2026-09-24).'),
  ('25a98be3-36d1-4a10-b5f1-d3c6b2f962c2'::uuid, 'MI', 'Jocelyn Benson', 'active', 'won',
   'Michigan Bureau of Elections Official Candidate Listing: the 2026 GEN report (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026) names Benson/Brinks (D) and James/DeBoyer (R) for Governor; Board of State Canvassers certified the 2026-08-04 primary 2026-08-24. Statewide vote totals NOT reachable from a state source (mielections.us refused; mvic 403). Jocelyn Benson: Democratic nominee per the GEN listing. Recorded by CA_0237 (2026-09-24).'),
  ('b3f41774-5f72-4000-9e85-d71269c08f8d'::uuid, 'MI', 'John James', 'active', 'won',
   'Michigan Bureau of Elections Official Candidate Listing: the 2026 GEN report (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026) names Benson/Brinks (D) and James/DeBoyer (R) for Governor; Board of State Canvassers certified the 2026-08-04 primary 2026-08-24. Statewide vote totals NOT reachable from a state source (mielections.us refused; mvic 403). John James: Republican nominee per the GEN listing. Recorded by CA_0237 (2026-09-24).'),
  ('2fd3f052-c26a-4eb2-9b03-3abf6053411f'::uuid, 'MI', 'Mike Cox', 'active', 'lost',
   'Michigan Bureau of Elections Official Candidate Listing: the 2026 GEN report (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026) names Benson/Brinks (D) and James/DeBoyer (R) for Governor; Board of State Canvassers certified the 2026-08-04 primary 2026-08-24. Statewide vote totals NOT reachable from a state source (mielections.us refused; mvic 403). Mike Cox: absent from the GEN listing. Recorded by CA_0237 (2026-09-24).'),
  ('37479bdc-1c6d-44d3-ab6a-a9b46a04a9b7'::uuid, 'MI', 'Perry Johnson', 'active', 'lost',
   'Michigan Bureau of Elections Official Candidate Listing: the 2026 GEN report (mi-boe.entellitrak.com ... miboePublicReport&electionType=GEN&electionYear=2026) names Benson/Brinks (D) and James/DeBoyer (R) for Governor; Board of State Canvassers certified the 2026-08-04 primary 2026-08-24. Statewide vote totals NOT reachable from a state source (mielections.us refused; mvic 403). Perry Johnson: absent from the GEN listing. Recorded by CA_0237 (2026-09-24).'),
  ('c009d8ca-9ef1-44a0-a9fc-f27f3e924b7f'::uuid, 'TN', 'Adam "Ditch" Kurtz', 'active', 'lost',
   'Tennessee Secretary of State, August 6 2026 primary by county, Governor (sos-prod.tnsosgovfiles.com/.../20260806DemocraticPrimarybyCounty.pdf and 20260806RepublicanPrimarybyCounty.pdf, STATE TOTALS). Adam "Ditch" Kurtz: D 12,465; Green 244,277. Recorded by CA_0237 (2026-09-24).'),
  ('95ca81d1-b4b4-49ec-b8d4-0bc88bfd8614'::uuid, 'TN', 'Carnita Atwater', 'active', 'lost',
   'Tennessee Secretary of State, August 6 2026 primary by county, Governor (sos-prod.tnsosgovfiles.com/.../20260806DemocraticPrimarybyCounty.pdf and 20260806RepublicanPrimarybyCounty.pdf, STATE TOTALS). Carnita Atwater: D 63,289; Green 244,277. Recorded by CA_0237 (2026-09-24).'),
  ('1ada4690-59a6-4ad2-8e68-00cbcd1b7ccb'::uuid, 'TN', 'Jerri Green', 'active', 'won',
   'Tennessee Secretary of State, August 6 2026 primary by county, Governor (sos-prod.tnsosgovfiles.com/.../20260806DemocraticPrimarybyCounty.pdf and 20260806RepublicanPrimarybyCounty.pdf, STATE TOTALS). Jerri Green: D 244,277. Recorded by CA_0237 (2026-09-24).'),
  ('bb7803e0-ba32-4feb-b33d-4804e829d4b1'::uuid, 'TN', 'Kevin Lee McCants', 'active', 'lost',
   'Tennessee Secretary of State, August 6 2026 primary by county, Governor (sos-prod.tnsosgovfiles.com/.../20260806DemocraticPrimarybyCounty.pdf and 20260806RepublicanPrimarybyCounty.pdf, STATE TOTALS). Kevin Lee McCants: D 18,972; Green 244,277. Recorded by CA_0237 (2026-09-24).'),
  ('f6fb3b82-58a5-4b74-9d52-2a0e281db8e0'::uuid, 'TN', 'Tim Cyr', 'active', 'lost',
   'Tennessee Secretary of State, August 6 2026 primary by county, Governor (sos-prod.tnsosgovfiles.com/.../20260806DemocraticPrimarybyCounty.pdf and 20260806RepublicanPrimarybyCounty.pdf, STATE TOTALS). Tim Cyr: D 14,799; Green 244,277. Recorded by CA_0237 (2026-09-24).'),
  ('d5fc10c4-52c2-401d-8de8-6b017aabdb78'::uuid, 'TN', 'John Rose', 'active', 'lost',
   'Tennessee Secretary of State, August 6 2026 primary by county, Governor (sos-prod.tnsosgovfiles.com/.../20260806DemocraticPrimarybyCounty.pdf and 20260806RepublicanPrimarybyCounty.pdf, STATE TOTALS). John Rose: R 235,561; Blackburn 311,392. Recorded by CA_0237 (2026-09-24).'),
  ('6a907f4b-9cb9-4eca-8649-1a70f3ac2dba'::uuid, 'TN', 'Marsha Blackburn', 'active', 'won',
   'Tennessee Secretary of State, August 6 2026 primary by county, Governor (sos-prod.tnsosgovfiles.com/.../20260806DemocraticPrimarybyCounty.pdf and 20260806RepublicanPrimarybyCounty.pdf, STATE TOTALS). Marsha Blackburn: R 311,392. Recorded by CA_0237 (2026-09-24).'),
  ('40cf71ef-a0ed-45dd-8faf-0000ac2c761f'::uuid, 'TN', 'Monty Fritts', 'active', 'lost',
   'Tennessee Secretary of State, August 6 2026 primary by county, Governor (sos-prod.tnsosgovfiles.com/.../20260806DemocraticPrimarybyCounty.pdf and 20260806RepublicanPrimarybyCounty.pdf, STATE TOTALS). Monty Fritts: R 168,004; Blackburn 311,392. Recorded by CA_0237 (2026-09-24).')
) AS v(rc_id, st, full_name, status_before, result, result_source);

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ca0237_result;
  IF n <> 49 THEN RAISE EXCEPTION 'PRE: % result rows listed, expected 49', n; END IF;

  -- Each row is the row it claims: id, name, status, a past PRIMARY in that state, not a U.S. House race.
  SELECT count(*) INTO n
    FROM ca0237_result c
    JOIN essentials.race_candidates rc ON rc.id = c.rc_id AND rc.full_name = c.full_name
                                      AND rc.candidate_status = c.status_before
    JOIN essentials.races ra ON ra.id = rc.race_id AND ra.position_name NOT LIKE 'U.S. House%'
    JOIN essentials.elections e ON e.id = ra.election_id AND e.election_type = 'primary'
                               AND e.state = c.st AND e.election_date < CURRENT_DATE;
  IF n <> 49 THEN RAISE EXCEPTION 'PRE: only % of 49 rows match id / name / status / race', n; END IF;

  -- Untouched (first run) or written by THIS migration (re-run).
  SELECT count(*) INTO n FROM ca0237_result c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE NOT (rc.result IS NULL OR (rc.result = c.result AND rc.result_source = c.result_source));
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % rows already carry a different result', n; END IF;

  -- Every past non-House primary row in these seven states still lacking a result is in this file.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN essentials.races ra ON ra.id = rc.race_id AND ra.position_name NOT LIKE 'U.S. House%'
                            AND ra.position_name NOT LIKE 'U.S. Senate%'
    JOIN essentials.elections e ON e.id = ra.election_id AND e.election_type = 'primary'
   WHERE e.election_date < CURRENT_DATE AND e.state IN ('CA','HI','KS','ME','MI','TN','MA')
     AND rc.result IS NULL AND rc.candidate_status <> 'withdrawn'
     AND rc.id NOT IN (SELECT rc_id FROM ca0237_result);
  IF n <> 0 THEN RAISE EXCEPTION 'PRE: % stale non-House primary rows in these states were not reviewed', n; END IF;

  RAISE NOTICE 'CA_0237 pre-flight OK';
END $$;

-- ---------------------------------------------------------------------------
-- Record the results. Guarded on result IS NULL.
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
   SET result             = c.result,
       result_source      = c.result_source,
       result_recorded_at = '2026-09-24T00:00:00Z'
  FROM ca0237_result c
 WHERE rc.id = c.rc_id
   AND rc.result IS NULL;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ca0237_result c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
   WHERE rc.result = c.result AND rc.result_source = c.result_source AND rc.result_recorded_at IS NOT NULL
     AND rc.candidate_status = c.status_before;
  IF n <> 49 THEN RAISE EXCEPTION 'POST: % of 49 rows carry their result with candidate_status unchanged', n; END IF;

  SELECT count(*) INTO n FROM ca0237_result WHERE result = 'won';
  IF n <> 11 THEN RAISE EXCEPTION 'POST: % won, expected 11', n; END IF;
  -- At most one winner per party primary race; Maine's party-less race has exactly its two nominees.
  SELECT count(*) INTO n
    FROM (SELECT ra.id FROM ca0237_result c JOIN essentials.race_candidates rc ON rc.id = c.rc_id
            JOIN essentials.races ra ON ra.id = rc.race_id
           WHERE c.result = 'won' AND ra.primary_party IS NOT NULL GROUP BY ra.id HAVING count(*) > 1) x;
  IF n <> 0 THEN RAISE EXCEPTION 'POST: % party primary races have two winners', n; END IF;
  SELECT count(*) INTO n FROM ca0237_result
   WHERE st = 'ME' AND result = 'won' AND full_name IN ('Hannah Pingree', 'Robert Charles');
  IF n <> 2 THEN RAISE EXCEPTION 'POST: Maine should have its two governor nominees as won, found %', n; END IF;
  SELECT count(*) INTO n FROM ca0237_result WHERE st = 'CA' AND result = 'advanced';
  IF n <> 2 THEN RAISE EXCEPTION 'POST: California top-two should have 2 advanced, found %', n; END IF;

  RAISE NOTICE 'CA_0237 applied: 49 primary results recorded (11 won, 36 lost, 2 advanced)';
END $$;

COMMIT;
