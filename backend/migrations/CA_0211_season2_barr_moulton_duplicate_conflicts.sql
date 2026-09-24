-- CA_0211_season2_barr_moulton_duplicate_conflicts.sql
-- Season 2 re-research of the compass conflicts CA_0204 left on the deactivated Barr and Moulton duplicate rows
-- (Andy Barr, U.S. House KY-6; Seth Moulton, U.S. House MA-6). Writes the Season 2 answer the evidence supports on
-- the SEATED rows. 11 chairs seated (5 Barr, 6 Moulton); 2 conflicts left unwritten (below).
-- Slot CA_0211 reserved via `steward slot CA` before this file existed. Author: Chris Andrews.
--
-- WHY. CA_0204 (merged #682) re-pointed FEC links, office_terms and finance_summary from each politician's deactivated
-- "Candidate for U.S. Senate" duplicate onto their seated U.S. House row, but left inform.politician_answers /
-- politician_context untouched on both rows: Season 1 is closed and its rows are trigger-guarded immutable
-- (inform.closed_season_is_immutable). Where the seated and duplicate Season 1 rows answered the same topic with
-- DIFFERENT values, both readings survive as an unresolved conflict — the seated value is what voters see; the
-- duplicate's is invisible once deactivated. Operator ruling (Chris Andrews, this task): do not touch Season 1 -- it
-- is closed and it is the record of what was believed at the time. Research each disputed topic again against the
-- Season 2 ladder (open) and write the seated row's answer there. Same model as CA_0190's resolution of the
-- Barragán/Strickland duplicate conflicts from CA_0184.
--
-- 🔴 SEASON 1 IS NOT TOUCHED, AND NEITHER IS EITHER DUPLICATE. Both are asserted by fingerprint at the bottom: every
-- Season 1 answer, context and evidence row in the corpus, every row of either duplicate in any season, and every
-- other Season 2 row of the two seated people must hash the same after this file as before it.
--
-- 🔴 TWO OF THE THIRTEEN ORIGINAL DISAGREEMENTS ARE NOT WRITTEN HERE, ON PURPOSE:
--   Moulton Immigration (S1: seated 3 / duplicate 2) -- "immigration" was retired from Season 2 entirely (CA_0066,
--     72% overlap with Deportation); there is no season_questions row for it, so politician_answers_pin_fkey forbids
--     a Season 2 row. Nothing is written; the Season 1 conflict stays for the Season 3 decision on the topic, the same
--     position CA_0190 recorded for Strickland's Immigration conflict and migration 1888 records for its siblings.
--   Moulton Jail Capacity (S1: seated 3 / duplicate 2) -- inform.compass_topic_roles currently scopes jail-capacity to
--     {local, state} only; it does NOT admit 'federal'. A U.S. House seat has no lever over county or state jail
--     capacity, and CLAUDE.md's scope-is-per-rung rule ("does an officeholder at this level hold a lever on this?")
--     answers no. Writing a Season 2 answer for a federal seat on a topic that does not offer the federal tier would
--     repeat the fact pattern CA_0190's tier check exists to catch, so this row is left as a Season 1 conflict too,
--     for whoever next revisits jail-capacity's role scope (it evidently admitted federal when the Season 1 rows were
--     written, since both duplicate and seated answered it then).
-- The pre-flight below guards both exclusions and refuses to run if either condition has changed since this file was
-- written (a Season 2 immigration question appearing, or jail-capacity gaining the federal role scope) -- in either
-- case the exclusion needs to be re-examined, not silently bypassed.
--
-- ⚠ THE LADDER SERVED IS NOT ALWAYS THE LADDER PINNED (ADR 0006: a season pins a version, serves the latest published
-- revision of that version). Season 2 pins r1 but SERVES a later clarifying revision for abortion (serves r5),
-- fossil-fuels (r3), tariffs (r3) and taxes (r3); civil-rights, deportation, religious-freedom, school-vouchers and
-- social-security serve their pinned revision unchanged. Every value below was matched against the SERVED text, which
-- the pre-flight re-reads and refuses on if a later edit has moved it. Two corrections this made against the first
-- pass of this research, for the record: abortion chair 5 no longer mentions "criminal penalties for ... patients",
-- which was the reason to keep Barr at chair 4 rather than chair 5 anyway (his Life at Conception Act cosponsorships
-- explicitly bar prosecuting the pregnant woman); and fossil-fuels chair 5 is specifically about opening MORE public
-- land and waters, which nothing in Barr's record reaches -- his instruments expand permitting on land already
-- eligible, which is chair 4's text, not chair 5's.
--
-- THE EVIDENCE (S1 values: seated / duplicate -> Season 2):
--   Barr  Abortion            4 / 5 -> 4  Pain-Capable Unborn Child Protection Act (H.R. 1080, 117th Congress,
--                                         cosponsored 2021-02-15): bans abortion after 20 weeks with exceptions for
--                                         rape (reported to authorities), incest of a minor, and serious risk to the
--                                         mother's life -- the same three exceptions as chair 4's served text. Current
--                                         cosponsorships are narrower: Born-Alive Abortion Survivors Protection Act
--                                         (H.R. 21, 119th, 2025-01-13) and Title X Abortion Provider Prohibition Act
--                                         (H.R. 330, 118th, 2023-01-12), neither of which states a gestational or
--                                         exception framework. His post-Dobbs statement (barr.house.gov, 2022-06-24)
--                                         frames abortion as a state democratic-process question and names only Hyde
--                                         and Born-Alive as his federal positions.
--                                         ⚖ JUDGMENT CALL: he also cosponsored the Life at Conception Act five times
--                                         through the 117th Congress (H.R. 1091 2013, H.R. 816 2016, H.R. 681 2017,
--                                         H.R. 616 2019, H.R. 1011 2022), a fertilization-personhood bill with no
--                                         stated exceptions -- closer to chair 5's "no exceptions." But that bill's own
--                                         text bars prosecuting the pregnant woman, and he has not cosponsored either
--                                         bill since the 117th Congress; between two tied, stale instruments, Pain-
--                                         Capable's explicit exception list is the closer textual match to a served
--                                         chair, so chair 4 stands.
--   Barr  Civil Rights        4 / 5 -> 5  Dismantle DEI Act of 2025 (H.R. 925, 119th, cosponsored 2025-10-31): closes
--                                         every federal agency's DEI office within 90 days by mandatory reduction in
--                                         force and bars funding DEI training or positions. Eliminate DEI in Colleges
--                                         Act (H.R. 1282, 119th, cosponsored 2025-10-28): cuts federal funds and
--                                         federal student aid to any college that carries out or houses DEI
--                                         programming. Both target race-conscious government programs as a category,
--                                         matching chair 5 ("eliminate ... all race-based government programs") over
--                                         chair 4's narrower "limit federal civil rights enforcement to clear cases of
--                                         discrimination." Season 1's reasoning (a 2016 vote against a federal-
--                                         contractor non-discrimination amendment) is about the reach of anti-
--                                         discrimination law, not about eliminating a program, and is better evidence
--                                         for Religious Freedom than for this topic.
--   Barr  Fossil Fuels        4 / 5 -> 4  Protecting American Energy Production Act (H.R. 26, 119th, cosponsored
--                                         2025-01-09; passed House 2025-02-07): bars a presidential fracking
--                                         moratorium without congressional authorization. Energy Choice Act (H.R.
--                                         3699, 119th, cosponsored 2025-07-15): bars state/local bans on new natural-
--                                         gas hookups. His energy platform (barr.house.gov/energy) calls to "fast-
--                                         track the approval process for American energy production on federal lands
--                                         and waters" for "energy dominance ... by rolling back onerous regulations."
--                                         A decade of CRA disapprovals removes restrictions ON drilling (WOTUS,
--                                         H.J.Res. 27, 118th, 2023; the Stream Protection Rule, H.J.Res. 38, 115th,
--                                         2017; EPA power-plant GHG rules, H.J.Res. 163 and H.J.Res. 152, 118th,
--                                         2024), plus current coal support (COAL POWER Act, H.R. 3870, 119th, 2025;
--                                         Coal Ash for American Infrastructure Act, H.R. 4875, 119th, sponsored
--                                         2025-08-05). This is chair 4's "expand ... with new drilling and permits."
--                                         Not chair 5: no instrument opens a NEW public-land or water area (e.g. ANWR,
--                                         an OCS lease sale) -- H.R. 26 and the energy page describe the approval
--                                         PROCESS on land already eligible for production.
--   Barr  Religious Freedom   4 / 5 -> 4  First Amendment Defense Act (H.R. 2802, 114th, cosponsored 2015-07-09):
--                                         bars adverse federal action (grants, contracts, tax-exempt status) against a
--                                         person or organization for acting on the belief that marriage is one man/one
--                                         woman. A specific exemption from a specific category of federal action --
--                                         chair 4's "allow faith-based exemptions from laws that conflict with sincere
--                                         religious beliefs" -- not chair 5's "complete autonomy in ... operations and
--                                         hiring practices," which FADA does not reach (it does not address hiring
--                                         generally). No current-Congress domestic religious-exemption bill was found;
--                                         his 119th religious-freedom activity (H.Res. 861, H.Res. 930, H.Res. 860)
--                                         addresses persecution abroad (China, Hong Kong, Nigeria) and does not bear
--                                         on domestic law.
--   Barr  Taxes                5 / 4 -> 5  Death Tax Repeal Act -- full estate-tax repeal, no phase-in -- cosponsored
--                                         in every Congress from the 113th (H.R. 147, 2013) through the current 119th
--                                         (H.R. 1301, cosponsored 2025-02-13), seven Congresses running. Signed
--                                         Americans for Tax Reform's Taxpayer Protection Pledge (opposing any net tax
--                                         increase), confirmed by his own release "Rep. Barr Keeps Promise, Votes for
--                                         Tax Reform" referring to the 2017 Tax Cuts and Jobs Act (Pub. L. 115-97).
--                                         Repeated pursuit of full repeal of an entire federal tax plus a standing
--                                         never-raise-taxes pledge matches chair 5's "cut taxes as far as possible and
--                                         shrink what government does" over chair 4's narrower "cut ... including the
--                                         main rates most people pay," which describes a rate cut, not an elimination.
--   Moulton  Abortion         2 / 1 -> 1  No bill or vote states a trimester or gestational cutoff. Current
--                                         cosponsorships run the other way: Ensuring Women's Right to Reproductive
--                                         Freedom Act (H.R. 4099, 119th, cosponsored 2025-06-24) and Reproductive
--                                         Rights are Human Rights Act of 2025 (H.R. 4888, cosponsored 2025-08-05),
--                                         both stating a right to abortion care with no gestational qualifier.
--                                         H.J.Res. 144 (119th, cosponsored 2026-02-24) disapproves a VA rule that
--                                         would have limited the reproductive health services (including abortion
--                                         counseling) the VA provides -- opposing a limit, not proposing one. H.R.
--                                         8734 and H.Res. 1285 (119th, 2026) both call for federal preemption of state
--                                         restrictions on dispensing medication abortion. He also cosponsored
--                                         resolutions condemning the Dobbs decision (H.Res. 28, 118th, 2023; H.Res.
--                                         1218, 117th, 2022). Matches chair 1's "legal at every stage of pregnancy,
--                                         with no time limit," not chair 2's second-trimester line, for which no
--                                         instrument was found.
--   Moulton  Deportation      3 / 2 -> 2  Current cosponsorships target the SCOPE and conduct of enforcement, not the
--                                         age of a case: the Drain ICE Act of 2026 (H.R. 7346, 119th, cosponsored
--                                         2026-02-04), the Studying Disastrous Impacts of Mass Deportation Act (H.R.
--                                         7345, cosponsored 2026-02-04), and the Southeast Asian Deportation Relief
--                                         Act of 2026 (H.R. 7608, cosponsored 2026-06-02), which protects a population
--                                         removed mainly on old convictions from decades ago. Earlier, the Veteran
--                                         Deportation Prevention and Reform Act (H.R. 1182, 117th, cosponsored
--                                         2021-06-01) shields noncitizen veterans, including some with old
--                                         convictions, from removal. None draws a line at how recently someone
--                                         arrived (chair 3's test); the through-line is opposing broad deportation
--                                         regardless of tenure, which is chair 2's "only ... convicted of serious
--                                         violent crimes," not chair 3.
--   Moulton  Fossil Fuels     4 / 2 -> 2  Decade-long record against new drilling: COAST Anti-Drilling Act (H.R. 341,
--                                         116th, cosponsored 2019-05-08), Stop Arctic Ocean Drilling Act of 2017 (H.R.
--                                         1784, 115th, cosponsored 2017-04-03), Arctic Cultural and Coastal Plain
--                                         Protection Act (H.R. 1146, 116th, cosponsored 2019-02-11). On House passage
--                                         of the Coastal and Marine Economies Protection Act and the Protecting and
--                                         Securing Florida's Coastline Act (permanent OCS leasing moratoria), he said:
--                                         "Offshore drilling is not worth the risk. Period. We don't need it, and the
--                                         potential downsides are far worse than any potential upside," and that
--                                         drilling was "a direct threat to the North Atlantic right whale and the more
--                                         than 90,000 jobs in our state's maritime industry" (moulton.house.gov press
--                                         release). LCV's 2025 scorecard credits votes against rolling back BLM
--                                         drilling safeguards in Alaska's Western Arctic (Roll Call 296) and against a
--                                         bill undermining federal authority over LNG facility siting (Roll Call 304).
--                                         Matches chair 2's "no new drilling ... production declines"; not chair 1
--                                         (no instrument ends existing production) and not chair 4 (the Season 1
--                                         seated row's value), for which no supporting instrument was found.
--   Moulton  School Vouchers  5 / 1 -> 1  Keep Public Funds in Public Schools Act of 2026 (H.R. 9289, 119th,
--                                         cosponsored 2026-06-11): repeals IRC Section 25F, the federal tax credit for
--                                         donations to K-12 private-school scholarship organizations created by the
--                                         2025 One Big Beautiful Bill Act -- eliminating an existing federal voucher
--                                         program, not merely opposing its growth. Matches chair 1's "eliminating
--                                         voucher programs," not chair 2's narrower "opposing ... without moving to
--                                         eliminate existing ones." He has also cosponsored "Public Schools Week"
--                                         resolutions in multiple Congresses (H.Res. 173, 118th, 2023; H.Res. 939,
--                                         117th, 2022). No instrument supports any voucher program; the Season 1
--                                         seated row's chair 5 ("universal vouchers") has no supporting record.
--   Moulton  Social Security  1 / 2 -> 1  Original cosponsor of the Social Security 2100 Act across five Congresses:
--                                         H.R. 1391 (114th, 2016), H.R. 1902 (115th, 2017), H.R. 860 (116th, 2019),
--                                         H.R. 5723 (117th, 2021), H.R. 4583 (118th, cosponsored 2023-07-12), which
--                                         raises the benefit formula and applies the payroll tax above $400,000 in its
--                                         later versions. Also cosponsored the more expansive Social Security
--                                         Expansion Act (H.R. 1170, 116th, cosponsored 2019-02-27, tax above $250,000)
--                                         and the Social Security Fairness Act eliminating the WEP/GPO offsets (H.R.
--                                         82, 118th, cosponsored 2023-01-24). Sustained, repeated support for a
--                                         significant benefit increase paired with new payroll tax on high earners
--                                         matches chair 1's "expand ... significantly and remove the income cap," not
--                                         chair 2's "modestly."
--   Moulton  Tariffs          2 / 3 -> 2  Prevent Tariff Abuse Act (H.R. 407, 119th, cosponsored 2025-04-07): strips
--                                         the President's IEEPA authority to impose tariffs or import quotas absent
--                                         congressional authorization -- a structural check on broad emergency
--                                         tariffs, not on tariffs as such. On the administration's 2025 tariffs, he
--                                         said the approach was "closer to throwing mud against the wall than well-
--                                         targeted shots," would send "inflation to skyrocket" for "American
--                                         businesses, and ... American consumers," and that "strong trading
--                                         relationships with our allies give Americans access to a wider variety of
--                                         goods at lower prices" (Patch, 2025-04-03; moulton.house.gov). Matches chair
--                                         2's "reduce most tariffs, keeping only limited exceptions" -- not chair 1
--                                         (he does not call for eliminating tariffs) and not chair 3 (no current
--                                         instrument seeks a tariff to protect a specific American industry).
--
-- No migration runner exists; this file records SQL applied by hand. Pure DML.
-- STATUS: NOT YET APPLIED. Dry-run (BEGIN ... ROLLBACK) to be run against prod before any apply; operator approval
--   required first (Chris Andrews).
--
-- ROLLBACK: on apply, snapshot the pre-image (empty, since no Season 2 row exists yet for any of these 11 pairs) to
--   backend/data/stance-retirement/<date>-ca0211-barr-moulton-rollback.json, then to roll back, DELETE the 11 Season 2
--   answer + context rows this file inserts (listed in _ca0211_rows below).
-- IDEMPOTENT: each write is guarded on its pre-image; a re-run writes nothing and every gate still passes.

BEGIN;

-- ─── The rows ──────────────────────────────────────────────────────────────────────────────────────
-- served_text is the Season 2 rung the chair was researched against. The pre-flight compares it with what the
-- season serves at apply time and refuses on a mismatch.
CREATE TEMP TABLE _ca0211_rows (
  politician_id uuid NOT NULL,
  who           text NOT NULL,
  topic_key     text NOT NULL,
  s1_seated     int  NOT NULL,     -- the conflict this row resolves, as CA_0204 left it
  s1_dup        int  NOT NULL,
  value         int  NOT NULL,
  served_text   text NOT NULL,
  reasoning     text NOT NULL,
  sources       text[] NOT NULL,
  PRIMARY KEY (politician_id, topic_key)
) ON COMMIT DROP;

INSERT INTO _ca0211_rows VALUES
-- Andy Barr (seated 164fb70e-b8c1-48cd-a6ef-12d80165c67d; duplicate d6d297f5-5319-4be1-b938-6bcce63368e7)
('164fb70e-b8c1-48cd-a6ef-12d80165c67d', 'Andy Barr', 'abortion', 4, 5, 4,
 'ban abortion except in cases of rape, incest, or a serious risk to the mother''s life.',
 $r$Barr's most on-point current instrument is the Pain-Capable Unborn Child Protection Act (H.R. 1080, 117th Congress, cosponsored 2021-02-15), which bans abortion after 20 weeks with exceptions for rape (reported to authorities), incest of a minor, and a serious risk to the mother's life -- the same three exceptions this ladder's chair 4 describes. His two active current-Congress cosponsorships are narrower and do not state a gestational or exception framework: the Born-Alive Abortion Survivors Protection Act (H.R. 21, 119th Congress, cosponsored 2025-01-13) requires care for infants who survive an abortion, and the Title X Abortion Provider Prohibition Act (H.R. 330, 118th Congress, cosponsored 2023-01-12) bars Title X family-planning funds from abortion providers. After the Supreme Court overturned Roe, his own statement said abortion policy "belongs with the American people through the democratic process" at the state level, and named only the Hyde Amendment and the Born-Alive Act as his federal positions (barr.house.gov, 2022-06-24). He was also a cosponsor of the Life at Conception Act five times through the 117th Congress (H.R. 1091 in 2013, H.R. 816 in 2016, H.R. 681 in 2017, H.R. 616 in 2019, and H.R. 1011 in 2022), which declares 14th Amendment personhood from fertilization with no stated exceptions -- closer to a chair with no exceptions. But that bill's own text bars prosecuting the pregnant woman, and he has not cosponsored either bill since the 117th Congress. Between two stale, tied instruments, the Pain-Capable Act's explicit three-exception list is the closer textual match to a specific served chair.$r$,
 ARRAY[$r$https://www.congress.gov/bill/117th-congress/house-bill/1080/cosponsors$r$,
       $r$https://www.congress.gov/bill/119th-congress/house-bill/21/cosponsors$r$,
       $r$https://www.congress.gov/bill/118th-congress/house-bill/330/cosponsors$r$,
       $r$https://barr.house.gov/2022/6/barr-historic-victory-for-life-as-scotus-overturns-roe-v-wade$r$,
       $r$https://www.congress.gov/bill/117th-congress/house-bill/1011/cosponsors$r$]),
('164fb70e-b8c1-48cd-a6ef-12d80165c67d', 'Andy Barr', 'civil-rights', 4, 5, 5,
 'eliminate affirmative action and all race-based government programs',
 $r$Barr is a current cosponsor of the Dismantle DEI Act of 2025 (H.R. 925, 119th Congress, cosponsored 2025-10-31), which closes every federal agency's DEI office within 90 days through a mandatory reduction in force, bars reassigning the affected employees elsewhere in the agency, and prohibits funding DEI training or positions across the federal government. He is also a cosponsor of the Eliminate DEI in Colleges Act (H.R. 1282, 119th Congress, cosponsored 2025-10-28), which cuts off federal funds and federal student aid to any college that carries out, or maintains an office that carries out, diversity-equity-and-inclusion programming. Both bills target race-conscious government programs and offices as a category to be eliminated, not merely the scope of anti-discrimination enforcement -- matching this ladder's chair 5 ("eliminate affirmative action and all race-based government programs") over chair 4's narrower "limit federal civil rights enforcement to clear cases of discrimination." This supersedes the Season 1 seated-row reasoning, which rested on a 2016 vote against a federal-contractor non-discrimination amendment -- an instrument about the reach of anti-discrimination law, which is better evidence for the Religious Freedom topic than for this one.$r$,
 ARRAY[$r$https://www.congress.gov/bill/119th-congress/house-bill/925/cosponsors$r$,
       $r$https://www.congress.gov/bill/119th-congress/house-bill/1282/cosponsors$r$,
       $r$https://www.congress.gov/bill/119th-congress/house-bill/1282/text$r$]),
('164fb70e-b8c1-48cd-a6ef-12d80165c67d', 'Andy Barr', 'fossil-fuels', 4, 5, 4,
 'Expand fossil fuel production with new drilling and permits.',
 $r$Barr is a current cosponsor of the Protecting American Energy Production Act (H.R. 26, 119th Congress, cosponsored 2025-01-09; passed the House 2025-02-07), which bars the President from declaring a moratorium on hydraulic fracturing without congressional authorization, and of the Energy Choice Act (H.R. 3699, 119th Congress, cosponsored 2025-07-15), which bars state and local governments from prohibiting or limiting a utility connection based on the type of energy delivered (i.e. bans on new natural-gas hookups). His official energy platform calls for legislation to "fast-track the approval process for American energy production on federal lands and waters" and to achieve "energy dominance ... by rolling back onerous regulations" (barr.house.gov/energy). This continues a decade of removing restrictions on drilling and production: Congressional Review Act disapprovals of the revised "waters of the United States" rule (H.J.Res. 27, 118th Congress, cosponsored 2023-02-02), the Stream Protection Rule (H.J.Res. 38, 115th Congress, cosponsored 2017-01-03), and EPA greenhouse-gas emission rules for power plants (H.J.Res. 163 and H.J.Res. 152, 118th Congress, cosponsored 2024-06-25), plus current coal support (the COAL POWER Act, H.R. 3870, 119th Congress, cosponsored 2025-11-18, and the Coal Ash for American Infrastructure Act, H.R. 4875, 119th Congress, sponsored 2025-08-05). This is chair 4's "expand fossil fuel production with new drilling and permits." Not chair 5: no instrument found opens a NEW public-land or water area to leasing (e.g. the Arctic National Wildlife Refuge, a new Outer Continental Shelf lease sale) -- H.R. 26 and the energy-page language describe the approval PROCESS on land and water already eligible for production, which is chair 4's text, not chair 5's "open more public land and waters."$r$,
 ARRAY[$r$https://www.congress.gov/bill/119th-congress/house-bill/26/cosponsors$r$,
       $r$https://www.congress.gov/bill/119th-congress/house-bill/3699/cosponsors$r$,
       $r$https://barr.house.gov/energy$r$,
       $r$https://www.congress.gov/bill/118th-congress/house-joint-resolution/27/cosponsors$r$,
       $r$https://www.congress.gov/bill/119th-congress/house-bill/3870/cosponsors$r$,
       $r$https://www.congress.gov/bill/119th-congress/house-bill/4875/all-info$r$]),
('164fb70e-b8c1-48cd-a6ef-12d80165c67d', 'Andy Barr', 'religious-freedom', 4, 5, 4,
 'protect religious freedom and allow faith-based exemptions from laws that conflict with sincere religious beliefs.',
 $r$Barr's most on-point instrument is the First Amendment Defense Act (H.R. 2802, 114th Congress, cosponsored 2015-07-09), which bars the federal government from taking adverse action -- denying a grant, contract, or tax-exempt status -- against a person or organization for acting in accordance with the belief that marriage is the union of one man and one woman. That is a specific religious exemption from a specific category of federal action, matching this ladder's chair 4 ("allow faith-based exemptions from laws that conflict with sincere religious beliefs"), not chair 5's broader "complete autonomy in ... operations and hiring practices" -- FADA does not address hiring generally, and no domestic instrument found extends the exemption beyond the marriage-belief context. No current-Congress domestic religious-exemption bill was found in his record; his 119th Congress religious-freedom activity (H.Res. 861, H.Res. 930, H.Res. 860) addresses persecution of religious minorities abroad (China, Hong Kong, Nigeria) and does not bear on how U.S. law balances domestic religious exemptions against anti-discrimination protection.$r$,
 ARRAY[$r$https://www.congress.gov/bill/114th-congress/house-bill/2802/cosponsors$r$,
       $r$https://www.congress.gov/bill/114th-congress/house-bill/2802/text$r$]),
('164fb70e-b8c1-48cd-a6ef-12d80165c67d', 'Andy Barr', 'taxes', 5, 4, 5,
 'Cut taxes as far as possible and shrink what government does',
 $r$Barr has cosponsored the Death Tax Repeal Act -- a full, no-phase-in repeal of the federal estate tax -- in every Congress from the 113th (H.R. 147, cosponsored 2013-02-13) through the current 119th (H.R. 1301, cosponsored 2025-02-13), seven Congresses running. He has signed Americans for Tax Reform's Taxpayer Protection Pledge, under which signers commit to oppose any net increase in taxes; his own release "Rep. Barr Keeps Promise, Votes for Tax Reform" refers to his vote for the 2017 Tax Cuts and Jobs Act (Pub. L. 115-97) as keeping that pledge. Repeatedly seeking full elimination of an entire federal tax, combined with a standing pledge never to raise any tax and support for the broadest tax-cut law of the last decade, matches chair 5's "cut taxes as far as possible and shrink what government does" better than chair 4's narrower "cut taxes broadly, including the main rates most people pay," which describes a rate cut rather than eliminating a tax category.$r$,
 ARRAY[$r$https://www.congress.gov/bill/119th-congress/house-bill/1301/cosponsors$r$,
       $r$https://www.congress.gov/bill/113th-congress/house-bill/147/cosponsors$r$,
       $r$https://barr.house.gov/press-releases?ID=011D4017-55BB-4BD1-B191-E13B7CF71F36$r$,
       $r$https://atr.org/take-the-pledge/$r$]),
-- Seth Moulton (seated 77f162cd-6ca0-4073-84e1-1c8ab87eb1e0; duplicate 5ccb1f15-f285-470c-b86a-97f9e6b22dff)
('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0', 'Seth Moulton', 'abortion', 2, 1, 1,
 'keep abortion legal at every stage of pregnancy, with no time limit.',
 $r$No bill or vote in Moulton's record states a trimester or gestational cutoff. His current cosponsorships run the other way: the Ensuring Women's Right to Reproductive Freedom Act (H.R. 4099, 119th Congress, cosponsored 2025-06-24) and the Reproductive Rights are Human Rights Act of 2025 (H.R. 4888, cosponsored 2025-08-05) both state a right to abortion care with no gestational qualifier. On 2026-02-24 he cosponsored H.J.Res. 144 disapproving a Department of Veterans Affairs rule that would have limited the reproductive health services, including abortion counseling, the VA provides -- opposing a limit, not proposing one. In 2026 he cosponsored H.R. 8734 and H.Res. 1285, both calling for federal preemption of state restrictions on dispensing medication abortion -- opposing state-level limits generally rather than accepting a second-trimester line. He also cosponsored resolutions condemning the Supreme Court's Dobbs decision (H.Res. 28, 118th Congress, cosponsored 2023-01-11; H.Res. 1218, 117th Congress, cosponsored 2022-07-05). This matches chair 1's "keep abortion legal at every stage of pregnancy, with no time limit," not chair 2's "legal through the second trimester ... only to protect the mother's health" afterward, for which no supporting instrument was found.$r$,
 ARRAY[$r$https://www.congress.gov/bill/119th-congress/house-bill/4099/cosponsors$r$,
       $r$https://www.congress.gov/bill/119th-congress/house-bill/4888/cosponsors$r$,
       $r$https://www.congress.gov/bill/119th-congress/house-joint-resolution/144/cosponsors$r$,
       $r$https://www.congress.gov/bill/119th-congress/house-bill/8734/cosponsors$r$,
       $r$https://www.congress.gov/bill/118th-congress/house-resolution/28/cosponsors$r$]),
('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0', 'Seth Moulton', 'deportation', 3, 2, 2,
 'Only deport undocumented immigrants convicted of serious violent crimes',
 $r$Moulton's current cosponsorships target the scope and conduct of enforcement, not how recently someone arrived: the Drain ICE Act of 2026 (H.R. 7346, 119th Congress, cosponsored 2026-02-04), the Studying Disastrous Impacts of Mass Deportation Act (H.R. 7345, cosponsored 2026-02-04), and the Southeast Asian Deportation Relief Act of 2026 (H.R. 7608, cosponsored 2026-06-02), which protects a population removed mainly on old convictions from decades ago. Earlier, the Veteran Deportation Prevention and Reform Act (H.R. 1182, 117th Congress, cosponsored 2021-06-01) shields noncitizen veterans, including some with old convictions, from removal. None of these draws a line at how long someone has been in the country (this ladder's chair 3 test); the through-line is opposing broad or mass deportation regardless of tenure, which matches chair 2's "only deport ... convicted of serious violent crimes," not chair 3's "recent arrivals" framing. Not chair 1: none of these bills stops deportation entirely.$r$,
 ARRAY[$r$https://www.congress.gov/bill/119th-congress/house-bill/7346/cosponsors$r$,
       $r$https://www.congress.gov/bill/119th-congress/house-bill/7345/cosponsors$r$,
       $r$https://www.congress.gov/bill/119th-congress/house-bill/7608/cosponsors$r$,
       $r$https://www.congress.gov/bill/117th-congress/house-bill/1182/cosponsors$r$]),
('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0', 'Seth Moulton', 'fossil-fuels', 4, 2, 2,
 'Allow no new drilling and let production decline over time.',
 $r$Moulton has a decade-long record opposing new drilling: the COAST Anti-Drilling Act (H.R. 341, 116th Congress, cosponsored 2019-05-08), the Stop Arctic Ocean Drilling Act of 2017 (H.R. 1784, 115th Congress, cosponsored 2017-04-03), and the Arctic Cultural and Coastal Plain Protection Act (H.R. 1146, 116th Congress, cosponsored 2019-02-11). On House passage of the Coastal and Marine Economies Protection Act and the Protecting and Securing Florida's Coastline Act -- both permanent moratoria on new Outer Continental Shelf oil and gas leasing -- he said: "Offshore drilling is not worth the risk. Period. We don't need it, and the potential downsides are far worse than any potential upside," and that a drilling expansion was "a direct threat to the North Atlantic right whale and the more than 90,000 jobs in our state's maritime industry that depend on clean water" (moulton.house.gov press release). The League of Conservation Voters' 2025 congressional scorecard credits him with votes against reversing Bureau of Land Management safeguards on drilling in Alaska's Western Arctic (Roll Call 296) and against a bill undermining federal authority over LNG facility siting (Roll Call 304). This matches chair 2's "allow no new drilling and let production decline over time" -- not chair 1's "phase out ... entirely" (no instrument calls for ending existing production), and not chair 4 (the Season 1 seated row's value), for which no supporting instrument was found.$r$,
 ARRAY[$r$https://www.congress.gov/bill/116th-congress/house-bill/341/cosponsors$r$,
       $r$https://www.congress.gov/bill/115th-congress/house-bill/1784/cosponsors$r$,
       $r$https://www.congress.gov/bill/116th-congress/house-bill/1146/cosponsors$r$,
       $r$https://moulton.house.gov/news/press-releases/house-passes-bills-prevent-offshore-drilling-moulton-announces-save-right$r$,
       $r$https://www.lcv.org/moc/seth-moulton/$r$]),
('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0', 'Seth Moulton', 'school-vouchers', 5, 1, 1,
 'Eliminating voucher programs that divert taxpayer money from public schools to private institutions',
 $r$Moulton is a current cosponsor of the Keep Public Funds in Public Schools Act of 2026 (H.R. 9289, 119th Congress, cosponsored 2026-06-11), which repeals Internal Revenue Code Section 25F -- the federal tax credit for donations to K-12 private-school scholarship organizations created by the 2025 One Big Beautiful Bill Act -- eliminating an existing federal voucher-style program, not merely opposing its expansion. This matches chair 1's "eliminating voucher programs that divert taxpayer money from public schools to private institutions," not chair 2's narrower "opposing ... without moving to eliminate existing ones." He has also cosponsored "Public Schools Week" resolutions supporting public education funding in multiple Congresses (H.Res. 173, 118th Congress, cosponsored 2023-02-27; H.Res. 939, 117th Congress, cosponsored 2022-02-22). No bill or statement found supports a voucher program of any kind; the Season 1 seated row's chair 5 ("universal vouchers ... to any school ... chosen by the family") has no supporting instrument in his record.$r$,
 ARRAY[$r$https://www.congress.gov/bill/119th-congress/house-bill/9289/cosponsors$r$,
       $r$https://www.kelly.senate.gov/newsroom/press-releases/kelly-hirono-lead-bill-to-repeal-federal-private-school-voucher-program-keep-public-dollars-in-public-schools/$r$,
       $r$https://www.congress.gov/bill/118th-congress/house-resolution/173/cosponsors$r$]),
('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0', 'Seth Moulton', 'social-security', 1, 2, 1,
 'expand Social Security benefits significantly and remove the income cap on payroll taxes to fund it.',
 $r$Moulton has been an original cosponsor of the Social Security 2100 Act across five Congresses -- H.R. 1391 (114th, 2016), H.R. 1902 (115th, 2017), H.R. 860 (116th, 2019), H.R. 5723 (117th, 2021), and H.R. 4583 (118th, cosponsored 2023-07-12) -- which raises the benefit formula for all beneficiaries and, in its later versions, applies the Social Security payroll tax to earnings above $400,000. He also cosponsored the more expansive Social Security Expansion Act (H.R. 1170, 116th Congress, cosponsored 2019-02-27), which applies the payroll tax above $250,000 and raises benefits across the board, and the Social Security Fairness Act eliminating the WEP/GPO benefit offsets for public-sector retirees (H.R. 82, 118th Congress, cosponsored 2023-01-24). This sustained, repeated support for a significant benefit increase paired with new payroll taxation on high earners well above the current cap matches chair 1's "expand Social Security benefits significantly and remove the income cap on payroll taxes," better than chair 2's "modestly" -- both bills move the benefit formula and the taxable-earnings base well beyond a token adjustment.$r$,
 ARRAY[$r$https://www.congress.gov/bill/118th-congress/house-bill/4583/cosponsors$r$,
       $r$https://www.congress.gov/bill/116th-congress/house-bill/1170/cosponsors$r$,
       $r$https://www.congress.gov/bill/118th-congress/house-bill/82/cosponsors$r$]),
('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0', 'Seth Moulton', 'tariffs', 2, 3, 2,
 'reduce most tariffs, keeping only limited exceptions.',
 $r$Moulton is a current cosponsor of the Prevent Tariff Abuse Act (H.R. 407, 119th Congress, cosponsored 2025-04-07), which would strip the President's authority under the International Emergency Economic Powers Act to impose tariffs or import quotas without congressional authorization -- a structural check on broad, emergency-declared tariffs, not on tariffs as such. Responding to the administration's 2025 tariff actions he said the across-the-board approach was "closer to throwing mud against the wall than well-targeted shots," would send "inflation to skyrocket" for "American businesses, and ... American consumers," and that "strong trading relationships with our allies give Americans access to a wider variety of goods at lower prices, from our cars to laptops to dishwashers" (Patch, 2025-04-03; moulton.house.gov). This matches chair 2's "reduce most tariffs, keeping only limited exceptions" -- he does not call for eliminating tariffs altogether (chair 1), and no current instrument shows him seeking a tariff specifically to protect an American industry (chair 3), only opposing their broad, untargeted use.$r$,
 ARRAY[$r$https://www.congress.gov/bill/119th-congress/house-bill/407/cosponsors$r$,
       $r$https://patch.com/massachusetts/salem/throwing-mud-against-wall-rep-moulton-blasts-trumps-tariffs$r$,
       $r$https://moulton.house.gov/in-the-news/local-firms-face-uncertainty-due-to-trumps-tariffs$r$]);

-- The pin each row writes against: read from the open season, never hand-typed, so the pin FK holds by construction.
CREATE TEMP TABLE _ca0211_target ON COMMIT DROP AS
SELECT r.*, pr.id AS topic_id, pr.season_id, pr.season_revision_id AS topic_revision_id
  FROM _ca0211_rows r
  JOIN inform.compass_topics_promoted pr ON pr.topic_key = r.topic_key;

-- Fingerprints of everything this file must NOT change. Hard-coded ids (no temp-table references) so the view can be
-- dropped cleanly before COMMIT.
CREATE OR REPLACE TEMP VIEW _ca0211_fp_now AS
WITH a AS (SELECT * FROM inform.politician_answers), c AS (SELECT * FROM inform.politician_context),
     e AS (SELECT * FROM inform.politician_context_evidence),
     mine(pid, tid) AS (VALUES
       ('164fb70e-b8c1-48cd-a6ef-12d80165c67d'::uuid, 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid),  -- Barr abortion
       ('164fb70e-b8c1-48cd-a6ef-12d80165c67d', '0bc588c6-39e1-4084-b5de-cac909b8b762'),              -- Barr civil-rights
       ('164fb70e-b8c1-48cd-a6ef-12d80165c67d', 'a22215c3-6693-4bc2-b248-01aebba14570'),              -- Barr fossil-fuels
       ('164fb70e-b8c1-48cd-a6ef-12d80165c67d', '6b9ba6d9-1001-43f5-b073-4d37130696fd'),              -- Barr religious-freedom
       ('164fb70e-b8c1-48cd-a6ef-12d80165c67d', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),              -- Barr taxes
       ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'),              -- Moulton abortion
       ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0', '44905f3b-e105-4f6c-afc7-5d223813dbac'),              -- Moulton deportation
       ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0', 'a22215c3-6693-4bc2-b248-01aebba14570'),              -- Moulton fossil-fuels
       ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0', '00b95a6a-75db-4521-b523-3326bba938de'),              -- Moulton school-vouchers
       ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0', '87d20824-a6e9-407b-983c-65440084a0ab'),              -- Moulton social-security
       ('77f162cd-6ca0-4073-84e1-1c8ab87eb1e0', '683c8084-2281-4920-a07c-18439b2dd413'))              -- Moulton tariffs
SELECT 'season1 answers' AS k, count(*) AS n, md5(coalesce(string_agg(concat_ws('|', politician_id, topic_id, value, write_in_text, topic_revision_id, editor_id, updated_at), E'\n' ORDER BY politician_id, topic_id), '')) AS h
  FROM a WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
UNION ALL
SELECT 'season1 context', count(*), md5(coalesce(string_agg(concat_ws('|', politician_id, topic_id, reasoning, sources::text, topic_revision_id, editor_id, updated_at), E'\n' ORDER BY politician_id, topic_id), ''))
  FROM c WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
UNION ALL
SELECT 'season1 evidence', count(*), md5(coalesce(string_agg(concat_ws('|', id, politician_id, topic_id, source_url, snippet, snippet_index, verified_at, batch_id), E'\n' ORDER BY id), ''))
  FROM e WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'
UNION ALL
SELECT 'duplicates answers', count(*), md5(coalesce(string_agg(concat_ws('|', politician_id, topic_id, season_id, value, write_in_text, topic_revision_id, updated_at), E'\n' ORDER BY politician_id, topic_id, season_id), ''))
  FROM a WHERE politician_id IN ('d6d297f5-5319-4be1-b938-6bcce63368e7', '5ccb1f15-f285-470c-b86a-97f9e6b22dff')
UNION ALL
SELECT 'duplicates context', count(*), md5(coalesce(string_agg(concat_ws('|', politician_id, topic_id, season_id, reasoning, sources::text, topic_revision_id, updated_at), E'\n' ORDER BY politician_id, topic_id, season_id), ''))
  FROM c WHERE politician_id IN ('d6d297f5-5319-4be1-b938-6bcce63368e7', '5ccb1f15-f285-470c-b86a-97f9e6b22dff')
UNION ALL
SELECT 'duplicates evidence', count(*), md5(coalesce(string_agg(concat_ws('|', id, source_url, snippet), E'\n' ORDER BY id), ''))
  FROM e WHERE politician_id IN ('d6d297f5-5319-4be1-b938-6bcce63368e7', '5ccb1f15-f285-470c-b86a-97f9e6b22dff')
UNION ALL
SELECT 'seated rows, other pairs', count(*), md5(coalesce(string_agg(concat_ws('|', a.politician_id, a.topic_id, a.season_id, a.value, a.topic_revision_id, a.updated_at, c.reasoning, c.sources::text, c.updated_at), E'\n' ORDER BY a.politician_id, a.topic_id, a.season_id), ''))
  FROM a LEFT JOIN c USING (politician_id, topic_id, season_id)
 WHERE a.politician_id IN ('164fb70e-b8c1-48cd-a6ef-12d80165c67d', '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0')
   AND NOT (a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND (a.politician_id, a.topic_id) IN (SELECT pid, tid FROM mine));

CREATE TEMP TABLE _ca0211_fp_before ON COMMIT DROP AS SELECT * FROM _ca0211_fp_now;
CREATE TEMP TABLE _ca0211_state (run text NOT NULL, s2_answers int NOT NULL, s2_context int NOT NULL) ON COMMIT DROP;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n int; v_fresh int; v_done int; rec record; v_served text;
BEGIN
  IF (SELECT status FROM inform.seasons WHERE id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3') IS DISTINCT FROM 'closed'
  OR (SELECT status FROM inform.seasons WHERE id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194') IS DISTINCT FROM 'open' THEN
    RAISE EXCEPTION 'CA_0211: expected Season 1 closed and Season 2 open';
  END IF;

  IF (SELECT count(*) FROM _ca0211_rows) <> 11 OR (SELECT count(*) FROM _ca0211_target) <> 11 THEN
    RAISE EXCEPTION 'CA_0211: expected 11 rows each resolving to one open-season question, got % / %',
      (SELECT count(*) FROM _ca0211_rows), (SELECT count(*) FROM _ca0211_target);
  END IF;
  IF (SELECT count(*) FROM _ca0211_target WHERE season_id <> '86d893a1-c1a2-4bbf-b4e5-69ec43221194') > 0 THEN
    RAISE EXCEPTION 'CA_0211: a row resolved to a season other than Season 2';
  END IF;

  -- The two excluded conflicts: guard that the exclusion reason still holds.
  IF EXISTS (SELECT 1 FROM inform.season_questions
              WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390') THEN
    RAISE EXCEPTION 'CA_0211: Immigration is now a Season 2 question -- Moulton''s conflict needs a row; re-research it first';
  END IF;
  IF EXISTS (SELECT 1 FROM inform.compass_topic_roles WHERE topic_id = 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0' AND role_scope::text = 'federal') THEN
    RAISE EXCEPTION 'CA_0211: jail-capacity now admits the federal tier -- Moulton''s conflict needs a row; re-research it first';
  END IF;

  -- The people: the seated rows hold a seat and are active; the duplicates are inactive and hold none.
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.id IN ('164fb70e-b8c1-48cd-a6ef-12d80165c67d', '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0')
     AND p.is_active AND EXISTS (SELECT 1 FROM essentials.office_current_holder h WHERE h.politician_id = p.id);
  IF v_n <> 2 THEN RAISE EXCEPTION 'CA_0211: expected both seated rows active and holding a seat, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.id IN ('d6d297f5-5319-4be1-b938-6bcce63368e7', '5ccb1f15-f285-470c-b86a-97f9e6b22dff')
     AND NOT p.is_active AND NOT EXISTS (SELECT 1 FROM essentials.office_current_holder h WHERE h.politician_id = p.id);
  IF v_n <> 2 THEN RAISE EXCEPTION 'CA_0211: expected both duplicates inactive and seatless, found %', v_n; END IF;
  SELECT count(*) INTO v_n FROM _ca0211_rows r JOIN essentials.politicians p ON p.id = r.politician_id WHERE p.full_name <> r.who;
  IF v_n > 0 THEN RAISE EXCEPTION 'CA_0211: % row(s) name a different person than their politician_id', v_n; END IF;

  -- The tier: every topic must admit the federal tier (both seats are U.S. House).
  SELECT count(*) INTO v_n FROM _ca0211_target t
   WHERE NOT EXISTS (SELECT 1 FROM inform.compass_topic_roles cr WHERE cr.topic_id = t.topic_id AND cr.role_scope::text = 'federal');
  IF v_n > 0 THEN RAISE EXCEPTION 'CA_0211: % topic(s) do not admit the federal tier', v_n; END IF;

  -- The conflict each row resolves is still the one CA_0204 left (Season 1, seated vs duplicate, all 11 pairs).
  SELECT count(*) INTO v_n FROM (
    SELECT politician_id, topic_id, s1_seated, s1_dup FROM _ca0211_rows r JOIN _ca0211_target t USING (politician_id, topic_key)
  ) x
   JOIN inform.politician_answers k ON k.politician_id = x.politician_id AND k.topic_id = x.topic_id AND k.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND k.value = x.s1_seated
   JOIN inform.politician_answers d ON d.topic_id = x.topic_id AND d.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3' AND d.value = x.s1_dup
                                    AND d.politician_id = CASE x.politician_id WHEN '164fb70e-b8c1-48cd-a6ef-12d80165c67d' THEN 'd6d297f5-5319-4be1-b938-6bcce63368e7'::uuid
                                                                                ELSE '5ccb1f15-f285-470c-b86a-97f9e6b22dff'::uuid END;
  IF v_n <> 11 THEN RAISE EXCEPTION 'CA_0211: expected the 11 CA_0204 Season 1 conflicts unchanged, found %', v_n; END IF;

  -- The ladder: each chair's served text (latest published revision of the pinned version) is the text the evidence
  -- was read against. A ladder edit after this file was written must stop it.
  FOR rec IN SELECT * FROM _ca0211_target LOOP
    SELECT sr.text INTO v_served
      FROM inform.compass_topic_revisions pin
      JOIN LATERAL (SELECT e.id FROM inform.compass_topic_revisions e
                     WHERE e.topic_id = pin.topic_id AND e.version = pin.version AND e.status IN ('published', 'superseded')
                     ORDER BY e.revision DESC LIMIT 1) eff ON true
      JOIN inform.compass_stance_revisions sr ON sr.topic_revision_id = eff.id AND sr.value = rec.value
     WHERE pin.id = rec.topic_revision_id;
    IF v_served IS DISTINCT FROM rec.served_text THEN
      RAISE EXCEPTION 'CA_0211: % / % chair % now serves "%", researched against "%"', rec.who, rec.topic_key, rec.value, v_served, rec.served_text;
    END IF;
  END LOOP;

  -- No evidence rows hang off the Season 2 context this file writes.
  SELECT count(*) INTO v_n FROM _ca0211_target t JOIN inform.politician_context_evidence e
      ON e.politician_id = t.politician_id AND e.topic_id = t.topic_id AND e.season_id = t.season_id;
  IF v_n > 0 THEN RAISE EXCEPTION 'CA_0211: % evidence row(s) on the target Season 2 context -- not expected', v_n; END IF;

  -- State of each target: 'fresh' (this file has not run) or 'done' (it has). Anything else is a state this file did
  -- not create and must not overwrite.
  SELECT count(*) FILTER (WHERE st = 'fresh'), count(*) FILTER (WHERE st = 'done') INTO v_fresh, v_done
    FROM (
      SELECT CASE
        WHEN a.politician_id IS NULL AND c.politician_id IS NULL THEN 'fresh'
        WHEN a.value = t.value AND a.topic_revision_id = t.topic_revision_id
             AND c.reasoning = t.reasoning AND c.sources = t.sources THEN 'done'
        ELSE 'other' END AS st
        FROM _ca0211_target t
        LEFT JOIN inform.politician_answers a ON a.politician_id = t.politician_id AND a.topic_id = t.topic_id AND a.season_id = t.season_id
        LEFT JOIN inform.politician_context c ON c.politician_id = t.politician_id AND c.topic_id = t.topic_id AND c.season_id = t.season_id
    ) s;
  IF NOT (v_fresh = 11 OR v_done = 11) THEN
    RAISE EXCEPTION 'CA_0211: targets are neither all fresh nor all done (fresh %, done %) -- someone else has written here', v_fresh, v_done;
  END IF;

  INSERT INTO _ca0211_state
  SELECT CASE WHEN v_fresh = 11 THEN 'fresh' ELSE 'rerun' END,
         (SELECT count(*) FROM inform.politician_answers WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'),
         (SELECT count(*) FROM inform.politician_context WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194');

  RAISE NOTICE 'CA_0211 pre-flight OK (%): seasons, people, tiers, 11 conflicts, served ladders, 2 exclusions still hold. Season 2 holds % answers / % context.',
    (SELECT run FROM _ca0211_state), (SELECT s2_answers FROM _ca0211_state), (SELECT s2_context FROM _ca0211_state);
END $$;

-- ─── Writes ─────────────────────────────────────────────────────────────────────────────────────
INSERT INTO inform.politician_answers (politician_id, topic_id, value, season_id, topic_revision_id, editor_id)
SELECT t.politician_id, t.topic_id, t.value, t.season_id, t.topic_revision_id, NULL
  FROM _ca0211_target t
 WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers a
                    WHERE a.politician_id = t.politician_id AND a.topic_id = t.topic_id AND a.season_id = t.season_id);

INSERT INTO inform.politician_context (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources, editor_id, updated_at)
SELECT t.politician_id, t.topic_id, t.season_id, t.topic_revision_id, t.reasoning, t.sources, NULL, now()
  FROM _ca0211_target t
 WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id = t.politician_id AND c.topic_id = t.topic_id AND c.season_id = t.season_id);

-- ─── Post-verify ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_n int; v_run text; v_a0 int; v_c0 int; v_a int; v_c int; v_exp int;
BEGIN
  SELECT run, s2_answers, s2_context INTO v_run, v_a0, v_c0 FROM _ca0211_state;

  -- Every target holds exactly what this file says, against the Season 2 pin.
  SELECT count(*) INTO v_n
    FROM _ca0211_target t
    JOIN inform.politician_answers a ON a.politician_id = t.politician_id AND a.topic_id = t.topic_id AND a.season_id = t.season_id
    JOIN inform.politician_context c ON c.politician_id = t.politician_id AND c.topic_id = t.topic_id AND c.season_id = t.season_id
   WHERE a.value = t.value AND a.write_in_text IS NULL
     AND a.topic_revision_id = t.topic_revision_id AND c.topic_revision_id = t.topic_revision_id
     AND c.reasoning = t.reasoning AND c.sources = t.sources AND cardinality(c.sources) > 0;
  IF v_n <> 11 THEN RAISE EXCEPTION 'CA_0211: expected 11 target pairs exactly as written, found %', v_n; END IF;

  -- Deltas: 11 inserts on a fresh run, nothing on a re-run.
  v_exp := CASE v_run WHEN 'fresh' THEN 11 ELSE 0 END;
  SELECT count(*) INTO v_a FROM inform.politician_answers WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  SELECT count(*) INTO v_c FROM inform.politician_context WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
  IF v_a - v_a0 <> v_exp OR v_c - v_c0 <> v_exp THEN
    RAISE EXCEPTION 'CA_0211: Season 2 delta answers % / context %, expected % each (%)', v_a - v_a0, v_c - v_c0, v_exp, v_run;
  END IF;

  -- Season 1, the duplicates, and every other row of the two seated people: unchanged, by fingerprint.
  SELECT count(*) INTO v_n
    FROM _ca0211_fp_before b JOIN _ca0211_fp_now n USING (k)
   WHERE b.n <> n.n OR b.h <> n.h;
  IF v_n > 0 OR (SELECT count(*) FROM _ca0211_fp_now) <> 7 THEN
    RAISE EXCEPTION 'CA_0211: % protected fingerprint(s) changed (Season 1 / duplicates / other seated rows)', v_n;
  END IF;

  -- Every non-blank Season 2 answer on these two people has its context row.
  SELECT count(*) INTO v_n FROM inform.politician_answers a
   WHERE a.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194' AND a.value <> 0
     AND a.politician_id IN ('164fb70e-b8c1-48cd-a6ef-12d80165c67d', '77f162cd-6ca0-4073-84e1-1c8ab87eb1e0')
     AND NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id AND c.season_id = a.season_id);
  IF v_n > 0 THEN RAISE EXCEPTION 'CA_0211: % non-blank Season 2 answer(s) on these two people have no context row', v_n; END IF;

  -- The seated compasses now read the Season 2 value: the newest-season collapse the read path uses.
  SELECT count(*) INTO v_n
    FROM _ca0211_target t
    JOIN LATERAL (SELECT a.value FROM inform.politician_answers a JOIN inform.seasons s ON s.id = a.season_id AND s.status <> 'draft'
                   WHERE a.politician_id = t.politician_id AND a.topic_id = t.topic_id
                   ORDER BY s.number DESC LIMIT 1) latest ON true
   WHERE latest.value = t.value;
  IF v_n <> 11 THEN RAISE EXCEPTION 'CA_0211: the newest published season does not serve all 11 values (got %)', v_n; END IF;

  RAISE NOTICE 'CA_0211 OK (%): 11 chairs seated (Barr: Abortion 4, Civil Rights 5, Fossil Fuels 4, Religious Freedom 4, Taxes 5; Moulton: Abortion 1, Deportation 2, Fossil Fuels 2, School Vouchers 1, Social Security 1, Tariffs 2). Season 2 now % answers / % context. Season 1, duplicates and other seated rows unchanged. Immigration and Jail Capacity left as Season 1 conflicts (see header).',
    v_run, v_a, v_c;
END $$;

DROP VIEW _ca0211_fp_now;

COMMIT;
