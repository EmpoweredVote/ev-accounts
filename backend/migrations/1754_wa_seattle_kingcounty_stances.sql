-- 1754_wa_seattle_kingcounty_stances.sql
-- Seattle / King County deep-seed, Task 10 stances. NINE rows across FIVE of the 25 officials.
-- Every row is INSERTed (none of the 25 had any prior compass row) and every row cites an enacted
-- instrument that was fetched and read, carried on a DIVIDED roll call that was re-pulled from the
-- Legistar API on 2026-08-14. 20 of the 25 officials get zero rows; that is the finding, not a gap.
--
-- Corpus actually read (both windows widened on 2026-08-14):
--   King County  2018-01-01 -> 2026-08 : 12,631 agenda items, 6,187 with a roll call, 118 divided >=20%
--   Seattle      2020-01-01 -> 2026-08 : 10,639 agenda items, 7,560 with a roll call, 146 divided >=20%
-- Only von Reichbauer (1994), Dunn (2005), Dembowski (2013) and Balducci (2016) have service that
-- predates the window. A blank means "no chair found in the window read", never "no record".
--
-- == METHOD: VOTE-FIRST, because Seattle sponsorship is weak evidence =========================
-- In Seattle a councilmember "sponsor" is routinely the council sponsor of MAYOR-TRANSMITTED
-- executive legislation. Three of three Strauss land-use sponsorships carry a "Mayor's leg
-- transmitted to Council" history line. So the strong signal here is a DIVIDED ROLL CALL plus the
-- ENACTED TEXT, not the sponsorship. This INVERTS the Maryland/Berkeley weighting.
-- The one exception is row 9: JumpStart has NO transmittal line and the mayor RETURNED IT UNSIGNED,
-- so that co-sponsorship is genuine council authorship and is cited as such.
--
-- == TWO PROPOSED GROUPS WERE WITHDRAWN ON THE ENACTED TEXT ==================================
-- Both died the same way: the TITLE described a chair and the OPERATIVE TEXT did not.
--
-- (a) transportation-priorities = 2 for Mosqueda, Perry and Zahilay, on KC 2024-0277 "Complete
--     Streets". The title is chair 2 almost verbatim ("pedestrians, bicyclists, transit riders, and
--     motor vehicle drivers"). But committee Striking Amendment S1 replaced "the County SHALL
--     provide and require the implementation of Complete Streets ... on newly constructed or
--     reconstructed roads" with "the County STRIVES TO provide and require", and the staff report
--     says the change was "meant to clarify that the ordinance is not intended as a development
--     regulation". Enacted Ordinance 19825 sec.1.A endorses the concept and lets "the county road
--     engineer ... in the county road engineer's sole discretion" find exceptions, six of them,
--     including "there is no identified need". Chair 2 requires bike lanes and sidewalks on ALL new
--     road projects and equal investment; this requires nothing and appropriates nothing. ALL SEVEN
--     yes votes stay blank, and Dunn's lone no does not describe chair 4 either.
--     Also note the full-council split was 7-1-1 = 12.5% against, BELOW the 20% screen; it only
--     surfaced because the COMMITTEE vote was 3-1. A committee split is not evidence the body was
--     divided.
--
-- (b) KC 2026-0048 / Ordinance 20041 dropped from the jail-capacity pairing. It reads as chair 2's
--     "rather than building new capacity" almost word for word -- "a one-year moratorium prohibiting
--     ... new or expansion of existing detention facilities". It is NOT a jail-capacity instrument.
--     Word counts in the enacted text: diversion 0, bail 0, pretrial 0, overcrowd 0, incarcerat 0,
--     "King County Correctional" 0. Its findings are about ICE -- the Northwest ICE Processing Center
--     in Tacoma run by GEO Group, and a federal forecast that ICE "intends to expand capacity in the
--     Seattle-Tacoma area" -- plus a zoning gap ("impacts from these large-scale facilities are not
--     contemplated by the county's development regulations"). Section 3 defines "detention facility"
--     by RCW 70.395.020(3), Washington's PRIVATE DETENTION statute, and section 2.B expressly lets
--     government uses expand for "security improvements". It is an ICE-siting land-use study
--     moratorium. It seats nobody, on any ladder -- it is not local-immigration either, since that
--     ladder is about detainers and information sharing, not land use.
-- The three jail-capacity rows SURVIVE because Motion 16361 was always the chair-2-vs-chair-3
-- discriminator; Ordinance 20041 was only ever carrying the contrastive tail.
--
-- == LADDERS THAT COULD NOT BE REACHED, recorded for the chair-quality analysis =================
-- * rent-regulation is UNREACHABLE IN WASHINGTON. KC Ordinance 19311 (2021) is a strong tenant
--   ordinance -- just-cause eviction beyond the state floor, plus 120 days' notice for rent increases
--   over three percent -- and Balducci, Dembowski and Zahilay all voted for it, 6-3. It still reaches
--   no chair: chairs 1 and 2 are both defined by rent control / rent stabilization, which RCW
--   35.21.830 preempts. Searched the enacted text: "rent control" 0, "rent stabiliz" 0, "cap on
--   rent" 0. A whole state's members cannot reach the top of this ladder. This is a DIFFERENT failure
--   mode from the taxes adverb problem: not a ladder that cannot discriminate, but one that cannot
--   be reached. Same disposition for KC 2020-0191 and 2019-0380.
--   Counter-signal kept deliberately: on KC 2020-0165, a motion urging the Governor to impose a rent
--   moratorium, Balducci and Dembowski voted NO. They are not automatic tenant-side votes, which
--   independently confirms no rent-regulation chair should be inferred for them.
-- * Seattle's divided votes cluster on tax mechanics, procedure, appointments, labour agreements and
--   fees. At four times the original sample (146 divided items, not 30) the pattern held: most are
--   "CBA ..." Council Budget Actions and "SLI ..." Statements of Legislative Intent, which are
--   spending allocations, not positions.
--
-- == INSTRUMENTS EXAMINED AND CORRECTLY NOT SEATED =============================================
-- * Seattle CB 120908 capital gains tax + CB 120909 spending plan: Strauss voted FOR the tax and
--   AGAINST the destination, so the purpose test does not attach; Hollingsworth switched sides on
--   both; three opposed consistently. 0 of 5.
-- * Seattle CB 120933 (Stadium Transition Area Overlay District): the naive read -- Rinck, Strauss
--   and Kettle voted against "allowing residential uses", therefore anti-density -- is BACKWARDS. The
--   real axis is industrial and maritime land preservation; the conditions are industrial-protective
--   (recorded covenant accepting "the industrial character of the neighborhood"), and Strauss
--   sponsored the industrial overlay chapter 23.70 himself.
-- * Seattle CB 121215 (Type V land use process, SEPA appeal exemption), 5-4, all nine voters among
--   our 25 -- the highest-leverage roll call available, and still procedure, not a substantive chair.
-- * Seattle CB 120394 (townhouse and rowhouse development standards, 8-1): changes standards INSIDE
--   existing multifamily zones and rezones nothing, while every residential-zoning chair is about
--   WHERE density is allowed. Off-ladder.
-- * Seattle CB 120157 / Ordinance 126445 (5-3, the most divided substantive Seattle housing item in
--   the window): strikes the 60-percent-of-AMI average requirement from the religious-organization
--   density bonus, leaving a flat 80 percent cap, so that faith institutions can build without public
--   subsidy and "limited public resources" can go elsewhere. Off-ladder -- it sets an income
--   threshold inside a bonus programme REQUIRED BY STATE LAW (RCW 36.70A.545), and no chair describes
--   choosing between two AMI thresholds. Also mayor-transmitted.
-- * KC 2018-0241 / Ordinance 19030, on its title "relating to planning and permitting", looked like
--   the second growth-and-development instrument Balducci and Dunn need. It is the 123-page
--   Winery / Brewery / Distillery code. Off-ladder.
-- * KC motions "acknowledging receipt of a report" (2024-0164, 2025-0206, 2024-0037): receiving a
--   report is not a position, however on-topic the subject line reads.
-- * Strauss housing, chair 3 vs chair 4 on CB 120581 / Ordinance 126854: a genuine tie. The signed
--   ordinance is a SCAN WITH NO TEXT LAYER (pages 1-3 extract zero characters) so which amendment
--   carried could not be established. Operator decision 2026-08-14: leave blank, do not OCR.
--
-- == CITATION INTEGRITY ========================================================================
-- Given this project's history with composed citations, every quoted phrase below was checked
-- against the enacted PDF at the page cited: Strauss / Ordinance 126821 7 of 7, Perry /
-- Ordinance 19613 6 of 6. Both apparent misses were LINE-NUMBER ARTIFACTS in the PDF text layer
-- (the extractor reads "balancing other 15 citywide priorities"), not fabrications.
-- Every source URL below was fetched with HTTP 200 on 2026-08-14. The re-fetched Ordinance 19613 and
-- Ordinance 126821 PDFs are BYTE-IDENTICAL to the copies read earlier, confirming provenance.
-- ! Ordinance 18665's PDF is a SCAN with poor OCR ("affrrmed", "uf its ubjeutives"). The operative
--   detainer sentence is legible AND is independently corroborated by the preamble; nothing else is
--   quoted from it.
--
-- == ROWS ======================================================================================
--   jail-capacity          = 2  Balducci, Dembowski, Perry, Zahilay   (Motion 16361)
--   growth-and-development = 1  Perry                                 (Ordinance 19613)
--   local-environment      = 3  Strauss                               (Ordinance 126821)
--   local-immigration      = 2  Balducci, Dembowski                   (Ordinance 18665)
--   taxes                  = 1  Strauss                               (Ordinances 126108 + 126109)
-- ! Zahilay cast his jail-capacity vote as a COUNCILMEMBER; he has been County Executive since
--   2025-11-25. Cross-office evidence, seated on operator decision 2026-08-14.
-- ! Balducci and Dunn remain CANDIDATES, not seats, for growth-and-development = 1 on Ordinance
--   19613: a single localized seven-month moratorium in Perry's own district cannot separate a shared
--   low-growth position from district courtesy. The pre-2023 sweep did not supply a second instrument.

BEGIN;

CREATE TEMP TABLE wa_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

CREATE TEMP TABLE wa_intent (pid uuid, tid uuid, chair numeric, reasoning text, sources text[]) ON COMMIT DROP;
INSERT INTO wa_intent (pid, tid, chair, reasoning, sources) VALUES

-- ─────────── jail-capacity = 2 · Claudia Balducci ───────────
('cd772ac3-d63b-4767-9198-ec4f1fb36f4d','c267e137-0ff9-4e7d-9d13-e3cea1756cd0', 2,
 'On May 16, 2023 the Metropolitan King County Council passed Motion 16361 by a divided vote of seven to two, and Balducci voted yes. The motion requests the county executive to evaluate programs to appropriately reduce the average daily population in King County adult secure detention facilities and to provide funding recommendations. Its enacted text names the mechanisms of this chair rather than leaving them to inference: it records that the council has expressed a priority interest in further reducing the average daily population at the county''s adult detention facilities, if appropriate for maintaining public safety, through exploring potential options such as increased support services for people in the criminal justice system, electronic home monitoring program expansion, diversion program expansion, bail assistance programs and partnerships with community organizations. It directs the evaluation to draw on the county''s Pretrial Reform Proviso Workgroup Report and its Community Bail Fund Pilot Project Report, and its preamble recites two decades in which the county developed alternatives to secure detention including offering diversion programs and providing treatment resources. Reducing the incarcerated population by diversion, bail assistance and treatment or support alternatives is what separates this chair from the adjacent one, which is about upgrading jail facilities to meet constitutional standards and says nothing about population reduction. The chair above it is refuted rather than merely unsupported: the motion recites that county policy is that secure detention facilities shall only be used for public safety purposes, conditions the evaluation twice on what is appropriate for ensuring public safety, and asks only for recommendations about priorities for county investment, so it works within a retained jail system rather than redirecting incarceration funding in order to shrink it. This chair''s contrasting phrase about not building new capacity is not separately evidenced by this instrument, and the motion requests an evaluation rather than enacting a diversion scheme, so what the vote establishes is endorsement of the council''s stated priority and its named mechanisms.',
 ARRAY['https://kingcounty.legistar1.com/kingcounty/attachments/b6618526-0bab-40c1-9e0c-afbb2f5e235d.pdf']::text[]),

-- ─────────── jail-capacity = 2 · Rod Dembowski (prime sponsor) ───────────
('1c6c1a17-f235-4ccb-9201-5cbc35bfbf8a','c267e137-0ff9-4e7d-9d13-e3cea1756cd0', 2,
 'Dembowski is the prime sponsor of Motion 16361, with Councilmember Kohl-Welles, and voted yes when the Metropolitan King County Council passed it by a divided vote of seven to two on May 16, 2023. The motion requests the county executive to evaluate programs to appropriately reduce the average daily population in King County adult secure detention facilities and to provide funding recommendations. Its enacted text names the mechanisms of this chair rather than leaving them to inference: it records that the council has expressed a priority interest in further reducing the average daily population at the county''s adult detention facilities, if appropriate for maintaining public safety, through exploring potential options such as increased support services for people in the criminal justice system, electronic home monitoring program expansion, diversion program expansion, bail assistance programs and partnerships with community organizations. It directs the evaluation to draw on the county''s Pretrial Reform Proviso Workgroup Report and its Community Bail Fund Pilot Project Report, and its preamble recites two decades in which the county developed alternatives to secure detention including offering diversion programs and providing treatment resources. Reducing the incarcerated population by diversion, bail assistance and treatment or support alternatives is what separates this chair from the adjacent one, which is about upgrading jail facilities to meet constitutional standards and says nothing about population reduction. The chair above it is refuted rather than merely unsupported: the motion recites that county policy is that secure detention facilities shall only be used for public safety purposes, conditions the evaluation twice on what is appropriate for ensuring public safety, and asks only for recommendations about priorities for county investment, so it works within a retained jail system rather than redirecting incarceration funding in order to shrink it. This chair''s contrasting phrase about not building new capacity is not separately evidenced by this instrument, and the motion requests an evaluation rather than enacting a diversion scheme.',
 ARRAY['https://kingcounty.legistar1.com/kingcounty/attachments/b6618526-0bab-40c1-9e0c-afbb2f5e235d.pdf']::text[]),

-- ─────────── jail-capacity = 2 · Sarah Perry (committee mover) ───────────
('165df2f6-84e7-4f40-9f4b-ff00c766cbfb','c267e137-0ff9-4e7d-9d13-e3cea1756cd0', 2,
 'Perry moved Motion 16361 in the Law, Justice, Health and Human Services Committee on May 2, 2023, where it was recommended do pass by five votes to one, and voted yes when the full Metropolitan King County Council passed it by a divided vote of seven to two on May 16, 2023. The motion requests the county executive to evaluate programs to appropriately reduce the average daily population in King County adult secure detention facilities and to provide funding recommendations. Its enacted text names the mechanisms of this chair rather than leaving them to inference: it records that the council has expressed a priority interest in further reducing the average daily population at the county''s adult detention facilities, if appropriate for maintaining public safety, through exploring potential options such as increased support services for people in the criminal justice system, electronic home monitoring program expansion, diversion program expansion, bail assistance programs and partnerships with community organizations. It directs the evaluation to draw on the county''s Pretrial Reform Proviso Workgroup Report and its Community Bail Fund Pilot Project Report, and its preamble recites two decades in which the county developed alternatives to secure detention including offering diversion programs and providing treatment resources. Reducing the incarcerated population by diversion, bail assistance and treatment or support alternatives is what separates this chair from the adjacent one, which is about upgrading jail facilities to meet constitutional standards and says nothing about population reduction. The chair above it is refuted rather than merely unsupported: the motion recites that county policy is that secure detention facilities shall only be used for public safety purposes, conditions the evaluation twice on what is appropriate for ensuring public safety, and asks only for recommendations about priorities for county investment, so it works within a retained jail system rather than redirecting incarceration funding in order to shrink it. This chair''s contrasting phrase about not building new capacity is not separately evidenced by this instrument, and the motion requests an evaluation rather than enacting a diversion scheme.',
 ARRAY['https://kingcounty.legistar1.com/kingcounty/attachments/b6618526-0bab-40c1-9e0c-afbb2f5e235d.pdf']::text[]),

-- ─────────── jail-capacity = 2 · Girmay Zahilay (voted as councilmember; now County Executive) ───────────
('1f63b667-7da3-4d75-b3ae-24529393741e','c267e137-0ff9-4e7d-9d13-e3cea1756cd0', 2,
 'Zahilay voted yes on Motion 16361 when the Metropolitan King County Council passed it by a divided vote of seven to two on May 16, 2023, sitting then as the councilmember for District 2; he has served as King County Executive since November 25, 2025, so this is his record in a previous office, on a subject squarely within the executive''s remit. The motion requests the county executive to evaluate programs to appropriately reduce the average daily population in King County adult secure detention facilities and to provide funding recommendations. Its enacted text names the mechanisms of this chair rather than leaving them to inference: it records that the council has expressed a priority interest in further reducing the average daily population at the county''s adult detention facilities, if appropriate for maintaining public safety, through exploring potential options such as increased support services for people in the criminal justice system, electronic home monitoring program expansion, diversion program expansion, bail assistance programs and partnerships with community organizations. It directs the evaluation to draw on the county''s Pretrial Reform Proviso Workgroup Report and its Community Bail Fund Pilot Project Report. Reducing the incarcerated population by diversion, bail assistance and treatment or support alternatives is what separates this chair from the adjacent one, which is about upgrading jail facilities to meet constitutional standards and says nothing about population reduction. The chair above it is refuted rather than merely unsupported: the motion recites that county policy is that secure detention facilities shall only be used for public safety purposes, conditions the evaluation twice on what is appropriate for ensuring public safety, and asks only for recommendations about priorities for county investment, so it works within a retained jail system rather than redirecting incarceration funding in order to shrink it. This chair''s contrasting phrase about not building new capacity is not separately evidenced by this instrument, and the motion requests an evaluation rather than enacting a diversion scheme.',
 ARRAY['https://kingcounty.legistar1.com/kingcounty/attachments/b6618526-0bab-40c1-9e0c-afbb2f5e235d.pdf']::text[]),

-- ─────────── growth-and-development = 1 · Sarah Perry ───────────
('165df2f6-84e7-4f40-9f4b-ff00c766cbfb','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 1,
 'Perry sponsored Ordinance 19613 and moved it to passage on May 16, 2023, when the Metropolitan King County Council adopted it by a divided vote of six to three. The ordinance declares an emergency and imposes a seven-month moratorium prohibiting the acceptance of applications for the subdivision of residentially zoned land in the Rural Town of Fall City, which lies in her district. Its enacted findings state a growth-limiting rationale directly. Finding D recites King County Comprehensive Plan Policy R-301, that a low growth rate is desirable for the Rural Area including Rural Towns to comply with the Growth Management Act, continue preventing sprawl and the overburdening of rural services, reduce need for capital expenditures, maintain rural character, protect the environment, and reduce transportation-related emissions. Finding L states that the moratorium exists in order to investigate whether additional regulation is necessary, and finding I contemplates a following interim zoning ordinance carrying provisions for minimum lot size and setbacks intended to ensure consistency with rural character. The adjacent chair, which would allow growth only where existing infrastructure can support it and slow approvals until capacity catches up, is refuted rather than merely unsupported: finding J records that the pending subdivisions rely on large on-site sewage systems and shared stormwater tracts, so service capacity is not the constraint the ordinance identifies, and the stated objection is the pressure such development places on the intended rural character of the area. This chair''s further example of requiring voter approval for major annexations or large-scale developments is not evidenced here and is read as illustrative rather than as a required element.',
 ARRAY['https://kingcounty.legistar1.com/kingcounty/attachments/7ed14fe7-04c4-4010-b445-47b874ce3489.pdf']::text[]),

-- ─────────── local-environment = 3 · Dan Strauss ───────────
('2e4714c6-feb4-443f-9cc0-08d866a0a99f','1935979c-b290-42e4-baa5-8cb0138b4ffa', 3,
 'Strauss was the council sponsor of Council Bill 120534 and voted in favour both in the Land Use Committee, where it passed four to one, and at full council, where the Seattle City Council passed it six to one. The resulting Ordinance 126821 relates to tree protection and is titled as balancing the need for housing production and increasing tree protections. The enacted text places him at consistent standards with reasonable implementation flexibility rather than at strict protection or at a pay-to-remove regime. Section 25.11.010, the purpose and intent section, provides that the chapter implements the goals and policies of Seattle''s Comprehensive Plan, especially those in the Environment Element dealing with protection of the urban forest while balancing other citywide priorities such as housing production, which is what defeats a strict-protection reading; the ordinance also exempts permanent supportive housing providers and moves tree review to non-appealable administrative Type I decisions. The standards themselves are uniform and were tightened rather than relaxed: a single tiered framework applies citywide, the exceptional-tree threshold falls from thirty inches to twenty-four inches, tree groves are added, and trees between twelve and twenty-four inches become regulated for the first time. Flexibility appears as an option rather than an entitlement, in section 25.11.110 on off-site planting and voluntary payment in lieu, under which the applicant may elect to make a voluntary payment instead of replacing trees on site. The chair describing developers paying fees in lieu of on-site preservation while prioritising economic activity over green space is refuted by that same section, which requires results equivalent to or greater than the minimum requirements for on-site tree plantings, prices smaller Tier 1 and Tier 2 trees at the twenty-four-inch rate, restricts the resulting revenue to census tracts with twenty-five percent or less canopy cover, and triples penalties where a violation was committed to improve views, increase market value, or expand development potential. The matter history shows the legislation was transmitted to the council by the mayor, so authorship is the executive''s and the position recorded here rests on his sponsorship together with his affirmative votes on a divided final passage, not on drafting.',
 ARRAY['https://legistar2.granicus.com/seattle/attachments/384e214e-e1be-4531-bf30-5dfede187616.pdf']::text[]),

-- ─────────── local-immigration = 2 · Claudia Balducci ───────────
('cd772ac3-d63b-4767-9198-ec4f1fb36f4d','b9ccee94-ad96-4f10-b655-889d8e5abe92', 2,
 'On February 26, 2018 the Metropolitan King County Council passed Ordinance 18665 as amended by a divided vote of six to three, and Balducci voted yes. The ordinance is titled as enhancing the trust and fairness for King County immigrant communities and establishes requirements for the department of adult and juvenile detention regarding the honoring of federal administrative detainers, access to inmates and the sharing of information. Its operative provision sets exactly the court-order condition this chair describes: county agents and agencies shall not honor immigration detainer requests or administrative warrants issued by ICE, CBP or USCIS, or hold any person on the basis of such a request or warrant, unless the request or warrant is accompanied by a warrant issued by a United States Court judge or magistrate. The preamble records the same standard independently, noting that following federal court decisions holding that detention based solely on a detainer is unconstitutional, the county had limited the honoring of immigration detainers to only those accompanied by a judicial warrant. That is why the chair above it does not apply: it would refuse all ICE detainers, whereas this ordinance expressly continues to honor them when a judicial warrant accompanies them, even though the ordinance does also bar employees from maintaining or sharing personal information including citizenship or immigration status. The ordinance additionally prohibits spending county money or other resources on facilitating the civil enforcement of federal immigration law and prohibits threatening to report family members to ICE; those provisions overlap the chair below, but that chair speaks only of following federal law as required and declines to address detainers at all, whereas refusing federal administrative warrants absent a judicial one is the affirmative limit this chair names. This chair''s further protection for undocumented crime victims and witnesses from referral is not separately evidenced; the ordinance''s non-disclosure protections run to all residents rather than to victims and witnesses specifically.',
 ARRAY['https://kingcounty.legistar1.com/kingcounty/attachments/6dd98974-903d-4aef-b78f-d2a464da051a.pdf']::text[]),

-- ─────────── local-immigration = 2 · Rod Dembowski (sponsor) ───────────
('1c6c1a17-f235-4ccb-9201-5cbc35bfbf8a','b9ccee94-ad96-4f10-b655-889d8e5abe92', 2,
 'Dembowski is one of the sponsors of Ordinance 18665, with Councilmembers Gossett, McDermott, Kohl-Welles and Upthegrove, and voted yes when the Metropolitan King County Council passed it as amended by a divided vote of six to three on February 26, 2018. The ordinance is titled as enhancing the trust and fairness for King County immigrant communities and establishes requirements for the department of adult and juvenile detention regarding the honoring of federal administrative detainers, access to inmates and the sharing of information. Its operative provision sets exactly the court-order condition this chair describes: county agents and agencies shall not honor immigration detainer requests or administrative warrants issued by ICE, CBP or USCIS, or hold any person on the basis of such a request or warrant, unless the request or warrant is accompanied by a warrant issued by a United States Court judge or magistrate. The preamble records the same standard independently, noting that following federal court decisions holding that detention based solely on a detainer is unconstitutional, the county had limited the honoring of immigration detainers to only those accompanied by a judicial warrant. That is why the chair above it does not apply: it would refuse all ICE detainers, whereas this ordinance expressly continues to honor them when a judicial warrant accompanies them, even though the ordinance does also bar employees from maintaining or sharing personal information including citizenship or immigration status. The ordinance additionally prohibits spending county money or other resources on facilitating the civil enforcement of federal immigration law and prohibits threatening to report family members to ICE; those provisions overlap the chair below, but that chair speaks only of following federal law as required and declines to address detainers at all, whereas refusing federal administrative warrants absent a judicial one is the affirmative limit this chair names. This chair''s further protection for undocumented crime victims and witnesses from referral is not separately evidenced; the ordinance''s non-disclosure protections run to all residents rather than to victims and witnesses specifically.',
 ARRAY['https://kingcounty.legistar1.com/kingcounty/attachments/6dd98974-903d-4aef-b78f-d2a464da051a.pdf']::text[]),

-- ─────────── taxes = 1 · Dan Strauss (JumpStart: the tax AND its spending plan) ───────────
('2e4714c6-feb4-443f-9cc0-08d866a0a99f','f7e5678d-dadd-4556-a2fc-446e24642ceb', 1,
 'Strauss co-sponsored both halves of Seattle''s JumpStart payroll expense tax and voted for both. Council Bill 119810, which became Ordinance 126108, passed the City Council seven votes to two on July 6, 2020 and levies a payroll expense tax graduated on both employer size and salary: businesses with payroll under one hundred million dollars pay seven-tenths of one percent on compensation between one hundred fifty thousand and four hundred thousand dollars and one and seven-tenths percent above that, rising through a middle tier to one and four-tenths percent and two and four-tenths percent for businesses with payroll of one billion dollars or more. The companion spending plan, Council Bill 119811, which became Ordinance 126109, passed eight to one the same day with Strauss again in favour and again as a co-sponsor. The mayor returned both unsigned, so this was council-authored legislation rather than executive legislation carried by a council sponsor, which is why the sponsorship counts here. The spending plan is what places him at funding more public services rather than existing ones: section 2.B, governing all years after the first, directs the proceeds to capital costs for the construction or acquisition of housing for low-income households, to operating and services costs for rental housing serving households at or below thirty percent of area median income, to rental assistance, to the Equitable Development Initiative, to support for local businesses and tourism, and to investments that advance Seattle''s Green New Deal. Recorded against that reading: section 2.A, which applies to 2021 only, replenishes the city''s Emergency Fund and Revenue Stabilization Fund and funds continuity of services and programs the city supported before the COVID-19 crisis that would otherwise see a reduction in funding, which is language belonging to the adjacent chair; that provision is expressly transitional while section 2.B is the permanent structure. Neither instrument characterises the increase as significant or moderate in its own terms, so the chair rests on the destination of the revenue rather than on stated magnitude.',
 ARRAY['https://legistar2.granicus.com/seattle/attachments/7404af72-ad86-44c5-87d3-adadb4d17aa0.pdf','https://legistar2.granicus.com/seattle/attachments/960f43a8-369f-4d82-8736-530e50712742.pdf']::text[]);

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
SELECT pid, tid, chair FROM wa_intent;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
SELECT pid, tid, reasoning, sources FROM wa_intent;

-- Guard 1: all 9 rows landed at the intended chair with the intended text and sources.
DO $$
DECLARE bad int; n int;
BEGIN
  SELECT count(*) INTO n FROM wa_intent;
  IF n <> 9 THEN RAISE EXCEPTION 'guard 1 failed: intent holds % rows, expected 9', n; END IF;
  SELECT count(*) INTO bad FROM wa_intent i
  LEFT JOIN inform.politician_answers a ON a.politician_id=i.pid AND a.topic_id=i.tid
  LEFT JOIN inform.politician_context c ON c.politician_id=i.pid AND c.topic_id=i.tid
  WHERE a.value IS DISTINCT FROM i.chair
     OR c.reasoning IS DISTINCT FROM i.reasoning
     OR c.sources IS DISTINCT FROM i.sources;
  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) not as intended', bad; END IF;
END $$;

-- Guard 2: row-count arithmetic. Exactly 9 new rows in each table, no updates, no deletions.
DO $$
DECLARE ans_after int; ctx_after int; s record;
BEGIN
  SELECT * INTO s FROM wa_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + 9 THEN
    RAISE EXCEPTION 'guard 2 failed: answers % -> %, expected +9', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + 9 THEN
    RAISE EXCEPTION 'guard 2 failed: context % -> %, expected +9', s.ctx_before, ctx_after; END IF;
END $$;

-- Guard 3: every cited source is one of the six documents actually fetched (HTTP 200, 2026-08-14).
-- A source that is not on this list is a composed citation by definition.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM wa_intent i
  WHERE EXISTS (
    SELECT 1 FROM unnest(i.sources) s
    WHERE s NOT IN (
      'https://kingcounty.legistar1.com/kingcounty/attachments/b6618526-0bab-40c1-9e0c-afbb2f5e235d.pdf',
      'https://kingcounty.legistar1.com/kingcounty/attachments/7ed14fe7-04c4-4010-b445-47b874ce3489.pdf',
      'https://kingcounty.legistar1.com/kingcounty/attachments/6dd98974-903d-4aef-b78f-d2a464da051a.pdf',
      'https://legistar2.granicus.com/seattle/attachments/384e214e-e1be-4531-bf30-5dfede187616.pdf',
      'https://legistar2.granicus.com/seattle/attachments/7404af72-ad86-44c5-87d3-adadb4d17aa0.pdf',
      'https://legistar2.granicus.com/seattle/attachments/960f43a8-369f-4d82-8736-530e50712742.pdf'));
  IF bad > 0 THEN RAISE EXCEPTION 'guard 3 failed: % row(s) cite an unfetched source', bad; END IF;
END $$;

-- Guard 4: the five seated officials hold exactly the rows intended, and NO OTHER official of the
-- Seattle-11 / King-County-14 cohort gained a row. The 20 blanks must stay blank -- a blank is a
-- researched finding here, so a stray row would silently destroy it.
DO $$
DECLARE seated int; strays int;
BEGIN
  SELECT count(*) INTO seated FROM inform.politician_answers a
   WHERE (a.politician_id, a.topic_id) IN (SELECT pid, tid FROM wa_intent);
  IF seated <> 9 THEN RAISE EXCEPTION 'guard 4 failed: % of 9 intended rows present', seated; END IF;

  SELECT count(*) INTO strays
    FROM inform.politician_answers a
    JOIN essentials.office_terms ot ON ot.politician_id = a.politician_id
    JOIN essentials.offices o       ON o.id  = ot.office_id
    JOIN essentials.chambers ch     ON ch.id = o.chamber_id
    JOIN essentials.governments g   ON g.id  = ch.government_id
   WHERE g.geo_id IN ('5363000','53033')
     AND ot.term_end IS NULL
     AND (a.politician_id, a.topic_id) NOT IN (SELECT pid, tid FROM wa_intent);
  IF strays > 0 THEN
    RAISE EXCEPTION 'guard 4 failed: % unexpected Seattle/King County row(s) exist', strays; END IF;
END $$;

-- Guard 5: the topics are the five intended live ladders, and every chair is in range 1-5.
DO $$
DECLARE t int; oob int;
BEGIN
  SELECT count(DISTINCT tid) INTO t FROM wa_intent;
  IF t <> 5 THEN RAISE EXCEPTION 'guard 5 failed: % distinct topics, expected 5', t; END IF;
  SELECT count(*) INTO oob FROM wa_intent i
   WHERE NOT EXISTS (SELECT 1 FROM inform.compass_stances s
                      WHERE s.topic_id = i.tid AND s.value = i.chair);
  IF oob > 0 THEN
    RAISE EXCEPTION 'guard 5 failed: % row(s) sit at a chair that does not exist on their ladder', oob; END IF;
END $$;

COMMIT;
