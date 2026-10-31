-- Migration 1942 — the contradiction check's eight largest groups, read in full; seven adjudicated.
--
-- WHAT THIS IS. The first working pass over the queue built by
-- `backend/scripts/check-instrument-rung-contradictions.mjs` (PR #1085). That check groups rows
-- that cite ONE instrument, take the SAME side of it, and sit on DIFFERENT rungs of ONE ladder
-- revision; at most one member of such a group can be right. Run in `--sole` mode against
-- production on 2026-10-25 it reports 149 groups covering 1,127 rows. This migration takes the
-- EIGHT LARGEST — 227 rows — and reads EVERY ONE of them rather than sampling. That mattered: one
-- of the eight was adjudicated from a sample of four rows and then WITHDRAWN when all 31 were
-- read. See section A.
--
--   45  Inflation Reduction Act          / climate-change  / FOR      chairs 1, 2, 3   ▶ WITHDRAWN
--   36  For the People Act               / redistricting   / FOR      chairs 1, 2
--   29  For the People Act               / redistricting   / SPONSOR  chairs 1, 2
--   25  For the People Act               / redistricting   / AGAINST  chairs 1, 4, 5
--   25  Safe Communities Act             / deportation     / SPONSOR  chairs 1, 2
--   23  Protection of Women and Girls…   / trans-athletes  / FOR      chairs 4, 5
--   22  Texas HB 229 (89R)               / trans-athletes  / SPONSOR  chairs 4, 5
--   22  Fair Districts for Maryland Act  / redistricting   / SPONSOR  chairs 1, 4
--
-- OUTCOME: 41 re-seated, 73 withdrawn, 113 left exactly as they are.
--
-- ⚖ THE METHOD, STATED ONCE. For each group the ENACTED OR INTRODUCED TEXT of the instrument was
-- retrieved and read — never the title, never a summary, never a news report. Where the text names
-- the chair, the group re-seats onto it. Where the text does not legislate on the ladder's
-- question at all, every member of the group is withdrawn, because an off-axis instrument cannot
-- seat a chair at ANY rung and picking between the rungs it was split across would be inventing an
-- answer. Texts read: BILLS-117hr1eh (For the People Act), BILLS-118hr734eh and BILLS-119hr28eh
-- (Protection of Women and Girls in Sports Act), capitol.texas.gov HB00229F (Texas HB 229
-- enrolled), mgaleg.maryland.gov hb0482F (Fair Districts for Maryland Act), PLAW-117publ169
-- (Inflation Reduction Act), and the Season 1 and Season 2 ladders for all four topics.
--
-- 🔴🔴 EVERY ONE OF THESE 227 ROWS SERVES FROM SEASON 1, AND THAT CHANGES THE WRITE SHAPE.
-- Unlike migrations 1926, 1927, 1930 and 1941, which updated Season 2 rows in place, not one row
-- in this population has a Season 2 shadow: the check's own `serving` CTE prefers Season 2 and
-- fell back to Season 1 for all 227. Season 1 is CLOSED AND IMMUTABLE (ADR 0005 §1.6), so the only
-- way to change what a voter reads is to INSERT a Season 2 row. Verified before writing: 114
-- target pairs, 114 Season 1 answers, 114 Season 1 contexts, ZERO rows in any other season.
-- ✅ A Season 2 row does shadow a Season 1 one — `getPoliticianAnswers` and the citations query
-- both collapse with `DISTINCT ON (topic_id) … ORDER BY s.number DESC` and then drop `value = 0`,
-- so an inserted Season 2 blank removes the spoke and an inserted re-seat replaces the chair.
--
-- 🔴🔴 AND IT CHANGES WHICH LADDER THE NEW ROW IS READ AGAINST. ADR 0006 (Option Y): an answer is
-- locked to the ladder it was given against, resolved from `pa.topic_revision_id` through the
-- latest published revision OF THAT VERSION. So a Season 1 answer is read against the Season 1
-- ladder, and the Season 2 row written to correct it is read against the SEASON 2 ladder. For
-- redistricting those are the same ladder — ONE revision, pinned by Season 1, Season 2 and
-- Season 3 alike — and for trans-athletes the two differ only at chair 3, which no row here
-- occupies. So every chair written below means the same thing in both seasons. The one topic where
-- that is NOT true is climate-change, and it is half the reason section A was withdrawn.
--
-- ── THE EIGHT GROUPS ──────────────────────────────────────────────────────────────────────────
--
-- A · INFLATION REDUCTION ACT → climate-change (45 rows) ▶▶ WITHDRAWN, AND THE REASON IS THE
--   MOST USEFUL THING IN THIS FILE. The adjudication was written, guarded and dry-run before being
--   taken out. What killed it was reading all 31 target rows instead of the four the group listing
--   shows.
--   🔴🔴 `--sole` GUARANTEES ONE **KEYED** INSTRUMENT, NOT ONE INSTRUMENT. The check compares only
--   rows whose reasoning yields exactly one instrument key, precisely so that a rung reflecting the
--   SUM of a row's evidence is not compared against a rung reflecting less. But the keyer is
--   lexical: it never keys "the Green New Deal" (H.Res. 109), and 13 of these 31 rows rest on Green
--   New Deal co-sponsorship as well as the Inflation Reduction Act, with 9 citing a dated
--   decarbonisation target in the member's own words. Those rows are NOT comparable with the rows
--   that cite the Act alone, so the group is not one unit of defect and the contradiction it
--   reports is partly an artefact.
--   ⚠ THE UNDERLYING READING STILL LOOKS RIGHT AND IS RECORDED FOR WHOEVER PICKS IT UP. Season 1
--   chair 2 reads "rapidly transition to renewable energy and phase out fossil fuels by 2030", and
--   the Act's own section 50265(b) forbids the Secretary, for TEN YEARS, to issue a wind or solar
--   right-of-way on Federal land unless an onshore oil-and-gas lease sale was held in the previous
--   120 days covering at least 2,000,000 acres in the previous year, and to issue an offshore wind
--   lease unless at least 60,000,000 acres were offered for offshore oil and gas in the previous
--   year; section 50264 reinstates Gulf Lease Sale 257 and mandates Sales 258 and 259. An Act that
--   makes renewable development conditional on continued fossil leasing for a decade does not
--   evidence a 2030 phase-out. But that only reaches the 15 rows resting on the Act plus a League
--   of Conservation Voters score — a scorecard is a direction, not a rung — and those 15 need
--   reading against H.Res. 109 one at a time, not as a group.
--   🔴 A SECOND FINDING, LOGGED AND NOT ACTED ON: the Season 1 and Season 2 climate ladders ask
--   DIFFERENT QUESTIONS, and `rung_map` says they do not.
--       Season 1 (v1r1)  1 ban all activities that increase carbon emissions
--                        2 rapidly transition … phase out fossil fuels by 2030
--                        3 invest in clean energy while gradually reducing reliance on fossil fuels
--       Season 2 (v2r3)  1 Require a shift to clean energy through mandates and firm deadlines.
--                        2 Fund clean energy with major subsidies, tax credits, and public investment.
--                        3 Speed up clean energy by cutting permitting red tape and upgrading the grid.
--   The first ranks AMBITION, the second ranks INSTRUMENT; they are not a rewording of one another.
--   Yet v2r3's `rung_map` is the IDENTITY MAP {1:1,2:2,3:3,4:4,5:5}, which is the project's licence
--   to treat a Season 1 value as meaning the same position in Season 2 (compassService.ts,
--   getTopicAnswerStats). ▶ Logged in the ledger as an open item: every Season 1 climate answer
--   ported forward on that map lands on a chair that asks a different question.
--
-- B · FOR THE PEOPLE ACT → redistricting, FOR and SPONSOR (65 rows: 19 at chair 1, 46 at 2).
--   All 19 target rows were read in full; each rests on the Act alone.
--   Chair 1's discriminating limb is "no elected officials involved at ANY level". Section 2414(b)
--   of H.R. 1 (117th) requires each State to appoint a Select Committee on Redistricting of FOUR
--   SITTING STATE LEGISLATORS — one per chamber from each of the two largest parties — and that
--   committee approves or disapproves the selection pool from which every commissioner is drawn
--   (§2412(b)(1)). Elected officials hold the gate. Section 2411(a)(1) composes the commission of
--   15: five majority-party, five minority-party, five unaffiliated — which is chair 2's limb,
--   "equal representation from both major parties", exactly.
--   ⚖ §2412(a)(2) does disqualify officeholders, candidates, party officers, lobbyists and their
--   immediate families from SERVING. That is a bar on membership, and it is what the 19 rows were
--   reaching for; it is not the absence of elected officials from the process.
--   🔑 Two of the 19 carry their own refutation. One row spells out the commission as "five
--   Democrats, five Republicans, and five independents" and then concludes chair 1. Another adds
--   support for Virginia's 2020 constitutional amendment, whose commission is eight legislators and
--   eight citizens — further from chair 1 still.
--   ▶ RE-SEAT the 19 to chair 2. The 46 already at chair 2 are NOT touched.
--
-- C · FOR THE PEOPLE ACT → redistricting, AGAINST (25 rows: 1 at chair 1, 11 at 4, 13 at 5).
--   A vote proves the SIDE, never the RUNG. Opposing a federal bill that would impose commissions
--   on every State establishes rejection of that mandate; it does not choose between chair 4
--   ("state legislatures with court oversight") and chair 5 ("the party that controls the state
--   legislature without outside interference"), neither of which the Act proposed. All 25 were read
--   and every one performs the inference in its own text — "his opposition IMPLIES preference for
--   state legislative control", "by opposing this reform he EFFECTIVELY supports…" — and one even
--   concedes the member "has not explicitly advocated for unchecked partisan map-drawing" while
--   seating him anyway.
--   🔴 AND ONE ROW IS INVERTED OUTRIGHT — the clearest single defect this queue has produced.
--   Mike Lee is seated at CHAIR 1, the most pro-commission rung, on reasoning that opens "Lee
--   strongly opposes independent redistricting commissions" and quotes him calling an independent
--   commission "a strategy to give Democrats an edge they can't win through fair elections." His
--   own words do put him on the anti-commission side, but between chairs 4 and 5 they do not
--   choose: he attacks a Utah judge for DRAWING a map rather than for reviewing one, and separately
--   calls a Virginia Democratic gerrymander "a naked power grab", which is not the posture of chair
--   5's "without outside interference".
--   ⚠ ONE ROW HAS A GENUINE ARGUMENT THE OTHER WAY and is withdrawn anyway: a former Wisconsin
--   Senate Majority Leader who personally defended the 2011 maps a federal panel called an
--   unconstitutional gerrymander. That is conduct, not a stated position on who should draw maps,
--   and he defended them IN court — which is chair 4's oversight, not chair 5's absence of it.
--   ▶ WITHDRAW all 25.
--
-- D · SAFE COMMUNITIES ACT → deportation, SPONSOR (25 rows: 2 at chair 1, 23 at 2).
--   Already ruled, twice. Migration 1927 blanked three rows seated at deportation chair 1 on this
--   Act; migration 1930 extended the ruling to sanctuary ordinances under the title "a sanctuary
--   ordinance cannot seat a deportation chair". The Act limits what MASSACHUSETTS police may do;
--   the ladder asks WHO SHOULD BE DEPORTED, which is a federal question. Chair 2 reads "only
--   deport people convicted of serious violent crimes" and the Act states no removal threshold at
--   all. These 25 are the remainder of that cluster — invisible to the earlier passes because they
--   serve from Season 1 and those migrations worked Season 2 rows.
--   🔑 The rows name their own leap: "ends state and local involvement in civil immigration
--   enforcement — EFFECTIVELY limiting deportation cooperation to serious criminal cases."
--   ⚠ The two chair-1 rows do not survive either. One adds a mayor's directive and a city
--   sanctuary ordinance — the same axis. The other adds five ICE bills the member filed ("get ICE
--   out of families", "de-ICE Massachusetts law enforcement", "support the pursuit of justice
--   against ICE", "melt ICE defenses", "uncover ICE"); their texts were NOT retrievable from
--   malegislature.gov and their titles all name the agency's conduct in Massachusetts, which cannot
--   carry "stop deportations entirely". ▶ If any of those texts is obtained and states a removal
--   position, that row re-seats on it.
--   ▶ WITHDRAW all 25.
--
-- E · PROTECTION OF WOMEN AND GIRLS IN SPORTS ACT → trans-athletes, FOR (23 rows: 22 at 4, 1 at 5).
--   The Act adds one operative subsection, 20 U.S.C. 1681(d): a Title IX violation to "permit a
--   person whose sex is male to participate in an athletic program or activity that is designated
--   for women or girls", with sex "recognized based solely on a person's reproductive biology and
--   genetics at birth", and (d)(4) expressly preserving a recipient's ability to let males train
--   or practise with a women's programme where no female loses a place or benefit. It reaches
--   women's and girls' programmes only and bars nobody from men's or mixed competition, so chair 5
--   — "completely ban all transgender athletes from competing in any organized sports" — overstates
--   it. Chair 4 is the Act almost in the ladder's own words. The 2023 (H.R. 734) and 2025 (H.R. 28)
--   Acts carry the SAME operative amendment; both were read, because the single outlier cites 2023
--   and the other 22 cite 2025.
--   ▶ RE-SEAT the 1 to chair 4. The 22 are NOT touched.
--
-- F · TEXAS HB 229 (89R) → trans-athletes, SPONSOR (22 rows: 20 at chair 4, 2 at 5).
--   🔑 THE FINDING OF THIS PASS: A FINDINGS CLAUSE IS NOT AN OPERATIVE PROVISION. The enrolled Act
--   has three operative sections. SECTION 2 adds definitions of "boy", "father", "female", "girl",
--   "male", "mother" and "sex" to Government Code 311.005. SECTION 3 adds Government Code
--   2051.252: a governmental entity collecting vital statistics information that identifies sex
--   "shall identify each individual as either male or female". SECTION 4 is the effective date.
--   NOTHING IN THE ACT REGULATES ATHLETIC PARTICIPATION. "Athletics" occurs only in SECTION 1, the
--   legislative findings, in a list of contexts — with prisons, shelters, locker rooms and
--   restrooms — where the legislature finds sex distinctions may be legitimate.
--   The rows show the leap in two grades: the careful ones call HB 229 "the ENFORCEMENT MECHANISM
--   for sex-based sports eligibility", conceding the eligibility rule is elsewhere; the careless
--   ones assert that it "bans transgender athletes from competing on teams matching their gender
--   identity", which the enrolled text does not say.
--   ⚠ Texas DOES restrict athletic participation by birth sex — HB 25 (87R) and SB 15 (88R) — and
--   a member who authored one of those can be seated on it. This says only that HB 229 is not it.
--   ▶ WITHDRAW all 22. An off-axis instrument is wrong at every rung, so the 4/5 split that
--   flagged the group is not resolved by choosing one of them.
--
-- G · FAIR DISTRICTS FOR MARYLAND ACT → redistricting, SPONSOR (22 rows: 11 at chair 1, 11 at 4).
--   The cleanest shape in the queue: twenty-two sponsors of ONE bill, with near-identical
--   reasoning, split exactly in half between two chairs. Both halves are wrong.
--   §8-7A-05(A) of HB 482 (2026RS) gives the Commission TEN members, FOUR OF THEM SITTING BY
--   VIRTUE OF ELECTED OFFICE — the President of the Senate, the Speaker of the House and the two
--   Minority Leaders — plus one appointee of each of those four, plus two gubernatorial appointees
--   subject to unanimous approval of the Senate Executive Nominations and House Rules committees.
--   Elected officials are a plurality of the commission, so chair 1's "no elected officials
--   involved at any level" fails outright. Chair 4, "state legislatures with court oversight", is
--   further off still: proposed Article XXI §2(B) makes the Commission "the EXCLUSIVE MEANS to
--   adopt any plan", displacing the General Assembly rather than preserving it. The eleven rows at
--   chair 4 did not describe a chair at all — they recorded a motive, "a Republican-led
--   redistricting reform effort opposing Democratic-drawn maps", and a motive is not a position.
--   WHY CHAIR 2: Article XXI §2(C)(2) constitutes the Commission "an INDEPENDENT UNIT of State
--   government", and its membership is balanced four-and-four between the two major parties by
--   construction — chair 2's "independent redistricting commissions with equal representation from
--   both major parties".
--   ⚖ CHAIR 3 WAS WEIGHED AND DECLINED. Its supermajority limb fits — §8-7A-06(A)(2) requires
--   seven of ten votes for any plan — but its noun, "bipartisan legislative COMMITTEES", does not:
--   §2(B) displaces the legislature instead of working through it.
--   ▶ RE-SEAT 21 to chair 2. ▶ WITHDRAW 1: Jefferson L. Ghrist's row cites only his own member
--   page, and he is not among the 28 sponsors HB 482 lists on its face, nor on the Senate
--   companion SB 2102. A row whose stated evidence cannot be located is withdrawn rather than
--   moved, because moving it would carry an unverified claim to a new chair.
--
-- ── WHAT A BLANK AND A RE-SEAT EACH ASSERT ────────────────────────────────────────────────────
-- A BLANK asserts that THIS ROW does not show which rung the person occupies. It does not assert
-- they hold no view, and it does not doubt the vote, the co-sponsorship or the co-authorship: the
-- citations are kept and the original reasoning is preserved verbatim beneath the notice. Each is
-- a candidate for re-seating on better evidence, not a write-off.
-- A RE-SEAT asserts that the evidence is sound and the MAPPING failed — the remedy migration 1921
-- established for a repaired row, and the one migration 1941 used for the Fair Share Amendment.
--
-- ⚠ WHAT THIS PASS DOES NOT CLAIM. The check finds DISAGREEMENT, not ERROR: a uniformly wrong
-- mapping produces no disagreement and is invisible to it. Groups F and A show the converse twice
-- over — a real split can point at something other than the split. In F the defect was that the
-- instrument has nothing to do with the ladder; in A the defect was in the GROUPING. 141 groups
-- covering roughly 900 rows remain unread.
--
-- Applied by hand via psql; no migration runner exists in this repo, so "applied" means its data
-- effects are live. Guards fail the whole transaction rather than write a partial result.

-- ── THE FROZEN TARGET SET ──────────────────────────────────────────────────────────────────────
-- 🔴 Frozen ONCE, with the Season 1 answer and context captured alongside, so the guards, the
-- write and the verification all speak about the same 114 rows. A predicate re-evaluated after an
-- INSERT would match the new rows as well and pass vacuously.
-- 🔴 THE SEASON 2 LADDER REVISION IS RESOLVED FROM season_questions, NEVER HARD-CODED. Reading the
-- wrong revision is what put a wrong chair in production in migration 1935.
CREATE TEMP TABLE mig1942_targets AS
SELECT x.politician_id,
       x.topic_id,
       x.op,
       x.value_after,
       sq.topic_revision_id        AS s2_revision,
       pa1.value                   AS value_before,
       pa1.topic_revision_id       AS s1_revision,
       pc1.reasoning               AS reasoning_before,
       pc1.sources                 AS sources_before
  FROM (VALUES
  ('0af35a49-9908-474a-a3b6-f0f0ad1e85a0'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-reseat', 2),  -- Mark Takano: chair 1 -> 2
  ('2c12afd3-178d-46c3-a4ea-a09f2f796ce9'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-reseat', 2),  -- Alma S. Adams: chair 1 -> 2
  ('46c6ebb0-137a-46aa-b6fa-17af31aa4ef1'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-reseat', 2),  -- Abigail Spanberger: chair 1 -> 2
  ('59662930-3fe8-4e3e-8f02-2a341d58619f'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-reseat', 2),  -- Mark Pocan: chair 1 -> 2
  ('7bf73fb2-1b31-412e-913d-835bfd3e326d'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-reseat', 2),  -- Katherine Clark: chair 1 -> 2
  ('a49af796-7961-4b82-8327-989691880a39'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-reseat', 2),  -- Grace Meng: chair 1 -> 2
  ('e4d5cd69-0a54-48d6-9d8c-11da8f091cb6'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-reseat', 2),  -- Norma Torres: chair 1 -> 2
  ('fa64bf50-3abd-455f-ba78-5845ab983299'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-reseat', 2),  -- Suzan K. DelBene: chair 1 -> 2
  ('05cf439f-3932-4398-b97b-4fd9a7506934'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-reseat', 2),  -- Sean Casten: chair 1 -> 2
  ('05e88b53-b6f4-4c5d-bcd2-f6b7b20f98d6'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-reseat', 2),  -- Mike Quigley: chair 1 -> 2
  ('135f4a8f-6e03-453f-a5b2-9a3b338f26c3'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-reseat', 2),  -- Henry C. "Hank" Johnson, Jr.: chair 1 -> 2
  ('28eeeb86-5ec1-48dd-86a7-9cf6d7771949'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-reseat', 2),  -- John Garamendi: chair 1 -> 2
  ('291f71df-c5c2-4f0a-b6be-d762d7aec9dd'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-reseat', 2),  -- Deborah K. Ross: chair 1 -> 2
  ('2c71d91b-7ad8-4984-b9a6-81587c41ea0d'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-reseat', 2),  -- Joe Neguse: chair 1 -> 2
  ('5be0c642-33b3-4ea4-8bb1-2eb25df2b4ef'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-reseat', 2),  -- Doris Matsui: chair 1 -> 2
  ('610bb358-bae9-4ce8-beaf-a33a27d5ba49'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-reseat', 2),  -- Diana DeGette: chair 1 -> 2
  ('956281d7-e27e-43cc-84e9-244879ed5ecf'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-reseat', 2),  -- Zoe Lofgren: chair 1 -> 2
  ('be2943b7-f634-42f4-8ab8-15db8138169f'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-reseat', 2),  -- Gil Cisneros: chair 1 -> 2
  ('efba0750-f472-47b3-acf7-054bd57817fc'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-reseat', 2),  -- Jahana Hayes: chair 1 -> 2
  ('4f62ca82-fda1-4386-9a4a-62dd84318f83'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Mike Lee: chair 1 -> withdrawn
  ('102b239c-0a3d-44b9-ae32-88d8179197e2'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Todd Young: chair 4 -> withdrawn
  ('164fb70e-b8c1-48cd-a6ef-12d80165c67d'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Andy Barr: chair 4 -> withdrawn
  ('2d0245b5-08f7-4c07-a1ba-0b01e066ee7d'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Michael Guest: chair 4 -> withdrawn
  ('4112b70d-e961-4313-987e-8673e9f39f22'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Russ Fulcher: chair 4 -> withdrawn
  ('55432c1f-2d1c-4848-8515-066bd1d3521a'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- John R. Moolenaar: chair 4 -> withdrawn
  ('56dfd8dd-ac7a-482a-848a-7c1d0e979606'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Nicole Malliotakis: chair 4 -> withdrawn
  ('66eef569-f283-4d35-a535-30eed922199a'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Bennie G. Thompson: chair 4 -> withdrawn
  ('6d0241d8-0408-4a0d-a159-62e1fe5d8fab'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Ann Wagner: chair 4 -> withdrawn
  ('9325e98f-db12-4214-bae0-9898e9438fac'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- W. Gregory Steube: chair 4 -> withdrawn
  ('9c7e62aa-c793-4630-b58b-4eb219b91d30'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Gary J. Palmer: chair 4 -> withdrawn
  ('f0d27c86-02f3-4014-9162-e4e940f2afdd'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Darin LaHood: chair 4 -> withdrawn
  ('1b776971-4c34-4453-ba38-6772f6783b1c'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Brian J. Mast: chair 5 -> withdrawn
  ('1fd041d0-473c-45f5-bbfb-54b42aaabc8d'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- David Rouzer: chair 5 -> withdrawn
  ('58c25b43-0ed1-4636-8213-b89a90f7f6a2'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Lauren Boebert: chair 5 -> withdrawn
  ('6840c7e6-2169-43a4-8490-1e73c8704cbd'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Guy Reschenthaler: chair 5 -> withdrawn
  ('7e2ff82b-e665-422f-a6b9-ee65682b1f6d'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Scott Fitzgerald: chair 5 -> withdrawn
  ('8561df96-52fd-42de-b6ad-e15dfc748c52'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- John H. Rutherford: chair 5 -> withdrawn
  ('96e589b9-d04a-4749-bf9f-9b66eaea5083'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Kevin Hern: chair 5 -> withdrawn
  ('cf705451-177f-4ab1-8870-cc9ff54b35d4'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Diana Harshbarger: chair 5 -> withdrawn
  ('d367c814-6226-44d3-b0bb-fdf6c2540f51'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Charles J. "Chuck" Fleischmann: chair 5 -> withdrawn
  ('d7f3b400-2d9f-4d23-bd02-9edea5274e92'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Warren Davidson: chair 5 -> withdrawn
  ('dc96bdae-2812-4ca4-af18-75d5d737ec89'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Trent Kelly: chair 5 -> withdrawn
  ('efd863c6-df64-4b40-9b49-73ddd003dc5d'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Paul A. Gosar: chair 5 -> withdrawn
  ('f7704cd1-eec4-40d8-b44f-429b4f9c8611'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'ftpa-blank', 0),  -- Tom McClintock: chair 5 -> withdrawn
  ('41ced04d-7403-4170-a267-c339191e6fcd'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Jake Wilson: chair 1 -> withdrawn
  ('b7369e32-1916-413e-b0eb-2871a5348470'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Rebecca L. Rausch: chair 1 -> withdrawn
  ('04a9edee-5d51-49f3-a2c9-585e2231bd08'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Jack P. Lewis: chair 2 -> withdrawn
  ('19b7c45b-57a7-468c-9762-82b926080646'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Andres X. Vargas: chair 2 -> withdrawn
  ('1d78debb-efd5-45e8-9204-06aab3076b2a'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Steven C. Owens: chair 2 -> withdrawn
  ('49963775-d2d5-4ae2-95cf-b2b8d0ed2a92'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Mike Connolly: chair 2 -> withdrawn
  ('5729a0a4-40a9-41bd-82a4-9a0bea757567'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Frank A. Moran: chair 2 -> withdrawn
  ('5c497509-7a9d-492b-ac35-ff37f8fcfb82'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Brandy Fluker-Reid: chair 2 -> withdrawn
  ('60e4da77-0c2b-4ca4-8d02-a4210bd91d90'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Michael J. Barrett: chair 2 -> withdrawn
  ('64e0eeb2-c83a-4da4-b6a2-2047b1e25cab'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Carlos González: chair 2 -> withdrawn
  ('7072bd94-b465-414e-bcf5-6e3feb7ec8dd'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Sean Garballey: chair 2 -> withdrawn
  ('78ae3786-e71e-4dc4-8b84-0ab28b555632'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Adam Gómez: chair 2 -> withdrawn
  ('853f0b26-a2b5-48b6-8dd6-f40ca48c87fd'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Lindsay Sabadosa: chair 2 -> withdrawn
  ('918296a2-5def-4ddf-8986-860d542900e7'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Simon Cataldo: chair 2 -> withdrawn
  ('95d5e111-b7dd-4440-8b51-070b72e33126'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- James K. Hawkins: chair 2 -> withdrawn
  ('961506eb-3f00-4358-a9a3-1730e7004474'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Joanne M. Comerford: chair 2 -> withdrawn
  ('98291d86-d42d-49d0-a5b2-d689a8154b15'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Erika Uyterhoeven: chair 2 -> withdrawn
  ('9ed1b75f-a314-4241-87ff-231de4aba963'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- James B. Eldridge: chair 2 -> withdrawn
  ('a40f234e-1790-4b52-8670-090b6379eb03'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Jason M. Lewis: chair 2 -> withdrawn
  ('a9ea7006-d595-45aa-a301-9c71d5a3af4d'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Carmine L. Gentile: chair 2 -> withdrawn
  ('bd451748-111f-461d-9752-95e7c243769e'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Julian A. Cyr: chair 2 -> withdrawn
  ('c947719a-cd1a-497a-8fc9-d9c4d434b18f'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Vanna Howard: chair 2 -> withdrawn
  ('e96b35eb-dad1-4a29-b416-d9b10838840f'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Russell E. Holmes: chair 2 -> withdrawn
  ('ecafa801-15b3-4777-9c38-95f5ded5cbe6'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- Mindy Domb: chair 2 -> withdrawn
  ('ffb8e526-7ad7-4911-92c5-d69528a0f280'::uuid, '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid, 'sca-blank', 0),  -- David M. Rogers: chair 2 -> withdrawn
  ('ff596d3f-3056-43e2-a80a-8c4b8fd9abde'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'pwgsa-reseat', 4),  -- Andy Harris: chair 5 -> 4
  ('2c5de636-b661-4b8f-8863-f10aa25e54ce'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- David Spiller: chair 4 -> withdrawn
  ('2f3450e1-7b1c-4ca0-ae62-581bbc2cf606'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- Cody Vasut: chair 4 -> withdrawn
  ('382d9814-389e-4205-b48c-67f3b9f7b332'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- David Lowe: chair 4 -> withdrawn
  ('3b3da471-8c67-4ea5-bb5f-fa1b2c0ce095'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- James Frank: chair 4 -> withdrawn
  ('481d7dae-0a6f-4e54-917c-72a2c6be6731'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- Don McLaughlin: chair 4 -> withdrawn
  ('4f6da77d-f516-4873-b705-3adeb23c1ffb'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- Jared Patterson: chair 4 -> withdrawn
  ('5249613b-40df-4458-830d-cdbb121961dc'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- David Cook: chair 4 -> withdrawn
  ('687ba2dd-c179-4ac6-abb2-3a5ac7ed43bb'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- Daniel Alders: chair 4 -> withdrawn
  ('82968d14-f39b-401d-821c-89825a9811ac'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- Hillary Hickland: chair 4 -> withdrawn
  ('afdc1bdd-8975-4d9f-9071-ab5065450ea9'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- Greg Bonnen: chair 4 -> withdrawn
  ('b10ab09a-0945-4ee7-a78c-a25288a6f136'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- Jay Dean: chair 4 -> withdrawn
  ('b36348f0-135f-4ea4-983d-70775f71e03e'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- Janis Holt: chair 4 -> withdrawn
  ('b5f2f8c9-13ab-4e15-82dd-dbecb6466084'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- Keith Bell: chair 4 -> withdrawn
  ('b652c0bb-1dc5-4043-8a2e-9e12ea034dc8'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- Giovanni Capriglione: chair 4 -> withdrawn
  ('c6dcdb47-9bbd-4c9b-9169-77e6082f17b1'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- Cody Harris: chair 4 -> withdrawn
  ('cb331eaa-fe08-4692-b92c-c3d303a426aa'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- Cole Hefner: chair 4 -> withdrawn
  ('d9dbb8f1-c49a-4a95-8a53-8aaf34809ffe'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- Helen Kerwin: chair 4 -> withdrawn
  ('df2b0dba-63d7-4f18-b713-7cc0594ec61d'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- Janie Lopez: chair 4 -> withdrawn
  ('e1b7592e-6f9a-411a-96c3-19f1ccc23435'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- Joanne Shofner: chair 4 -> withdrawn
  ('f920022b-4aa0-47ae-a5ae-c2edf3e17044'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- John McQueeney: chair 4 -> withdrawn
  ('002f4446-75be-4860-935e-3cb65ce296fb'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- Stan Gerdes: chair 5 -> withdrawn
  ('9a8cf4be-0543-4cc1-99ea-be5f19cb3402'::uuid, 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'::uuid, 'hb229-blank', 0),  -- Shelley Luther: chair 5 -> withdrawn
  ('3817ad52-3f43-4bd3-8525-e7dcd0816153'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- Jim Hinebaugh, Jr.: chair 1 -> 2
  ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- Jason C. Buckel: chair 1 -> 2
  ('5967c703-2583-466f-a438-c3ac182111d5'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- April Rose: chair 1 -> 2
  ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- Chris Tomlinson: chair 1 -> 2
  ('b389687f-817b-4fda-8770-a888029f4629'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- April Miller: chair 1 -> 2
  ('ba85b633-32cf-4617-923c-3a325f39894e'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- Ric Metzgar: chair 1 -> 2
  ('cdf746c1-8311-416b-9ad3-2684a83b6992'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- William Valentine: chair 1 -> 2
  ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- Jesse T. Pippy: chair 1 -> 2
  ('d049cf3e-6577-4f8d-ba7e-768ac2b78d66'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- Terry L. Baker: chair 1 -> 2
  ('df6fe96f-7795-4934-9acc-2b9f8f0aa8f7'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- William J. Wivell: chair 1 -> 2
  ('eadb65c9-74b6-40c3-b9e7-159c5734c59f'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- Robert B. Long: chair 1 -> 2
  ('0c789b27-d50c-4822-95ff-409ecb7db08a'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- Mike Griffith: chair 4 -> 2
  ('1eada938-f28c-46b9-bd21-df241656cd2b'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- Christopher T. Adams: chair 4 -> 2
  ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- Wayne A. Hartman: chair 4 -> 2
  ('547841f2-3476-4e83-9344-0cac984d44e8'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- Teresa E. Reilly: chair 4 -> 2
  ('58d0ff82-631f-475f-889a-9a4ebb39fc07'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- Susan K. McComas: chair 4 -> 2
  ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- Jay A. Jacobs: chair 4 -> 2
  ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- Barry Beauchamp: chair 4 -> 2
  ('d17104a7-8a35-4bcd-8879-76ceb997df6a'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- H. Kevin Anderson: chair 4 -> 2
  ('eca530ff-628d-417d-a3dc-b858dc7c2376'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-blank', 0),  -- Jefferson L. Ghrist: chair 4 -> withdrawn
  ('fb1fe811-b340-42d3-88ee-97b5364117cd'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2),  -- Thomas S. Hutchinson: chair 4 -> 2
  ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2'::uuid, '48cc9585-ec22-4f53-8d42-6839828dd36f'::uuid, 'md482-reseat', 2)  -- Steven J. Arentz: chair 4 -> 2
  ) AS x(politician_id, topic_id, op, value_after)
  JOIN inform.politician_answers pa1
    ON pa1.politician_id = x.politician_id AND pa1.topic_id = x.topic_id
   AND pa1.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
  JOIN inform.politician_context pc1
    ON pc1.politician_id = x.politician_id AND pc1.topic_id = x.topic_id
   AND pc1.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
  JOIN inform.season_questions sq
    ON sq.topic_id = x.topic_id AND sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- The before-picture, for a delta that does not depend on the predicate.
CREATE TEMP TABLE mig1942_before AS
SELECT (SELECT count(*) FROM inform.politician_answers
         WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND value > 0)                    AS seated_season2,
       (SELECT count(*) FROM inform.politician_answers
         WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND value > 0)                    AS seated_season1;

-- Snapshot Season 1 for these pairs so the closing guard can prove the closed season did not move.
CREATE TEMP TABLE mig1942_season1_before AS
SELECT pa.politician_id, pa.topic_id, pa.value, pa.updated_at
  FROM inform.politician_answers pa
  JOIN mig1942_targets t ON t.politician_id = pa.politician_id AND t.topic_id = pa.topic_id
 WHERE pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid;

-- ── GUARDS ─────────────────────────────────────────────────────────────────────────────────────

-- GUARD 1 — the population is exactly the set that was read, every row still at the value it was
-- read at, and every row still has reasoning to preserve.
-- 🔴 STALENESS GATE: if another session has worked any of these rows, a value moves and this refuses.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1942_targets;
  IF n <> 114 THEN RAISE EXCEPTION 'migration 1942: expected 114 target rows, found %', n; END IF;

  SELECT count(*) INTO n FROM mig1942_targets WHERE op = 'ftpa-reseat';
  IF n <> 19 THEN RAISE EXCEPTION 'migration 1942: expected 19 ftpa-reseat rows, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1942_targets WHERE op = 'ftpa-blank';
  IF n <> 25 THEN RAISE EXCEPTION 'migration 1942: expected 25 ftpa-blank rows, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1942_targets WHERE op = 'sca-blank';
  IF n <> 25 THEN RAISE EXCEPTION 'migration 1942: expected 25 sca-blank rows, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1942_targets WHERE op = 'pwgsa-reseat';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1942: expected 1 pwgsa-reseat rows, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1942_targets WHERE op = 'hb229-blank';
  IF n <> 22 THEN RAISE EXCEPTION 'migration 1942: expected 22 hb229-blank rows, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1942_targets WHERE op = 'md482-reseat';
  IF n <> 21 THEN RAISE EXCEPTION 'migration 1942: expected 21 md482-reseat rows, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1942_targets WHERE op = 'md482-blank';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1942: expected 1 md482-blank rows, found %', n; END IF;

  SELECT count(*) INTO n FROM mig1942_targets
   WHERE reasoning_before IS NULL OR length(reasoning_before) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % target(s) have no reasoning to preserve', n; END IF;

  SELECT count(*) INTO n FROM mig1942_targets WHERE coalesce(cardinality(sources_before), 0) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % target(s) have no citations to carry forward', n; END IF;

  SELECT count(*) INTO n FROM mig1942_targets WHERE reasoning_before LIKE 'INTERNAL RECORD%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % target(s) are already withdrawn rows', n; END IF;
END $$;

-- GUARD 2 — the value each row was READ at. Written out per group rather than asserted in prose,
-- so a row somebody else has moved since the read cannot be written over silently.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1942_targets WHERE op = 'ftpa-reseat'  AND value_before <> 1;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % For the People Act row(s) are no longer at chair 1', n; END IF;
  SELECT count(*) INTO n FROM mig1942_targets WHERE op = 'ftpa-blank'   AND value_before NOT IN (1, 4, 5);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % opposing For the People Act row(s) moved since the read', n; END IF;
  SELECT count(*) INTO n FROM mig1942_targets WHERE op = 'sca-blank'    AND value_before NOT IN (1, 2);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % Safe Communities Act row(s) moved since the read', n; END IF;
  SELECT count(*) INTO n FROM mig1942_targets WHERE op = 'pwgsa-reseat' AND value_before <> 5;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: the Protection of Women and Girls in Sports Act row is no longer at chair 5'; END IF;
  SELECT count(*) INTO n FROM mig1942_targets WHERE op = 'hb229-blank'  AND value_before NOT IN (4, 5);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % Texas HB 229 row(s) moved since the read', n; END IF;
  SELECT count(*) INTO n FROM mig1942_targets WHERE op IN ('md482-reseat', 'md482-blank') AND value_before NOT IN (1, 4);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % Fair Districts for Maryland row(s) moved since the read', n; END IF;
END $$;

-- GUARD 3 — every row really does cite the instrument this migration says it cites. Reading the
-- shape of the stored text rather than trusting the uuid list that selected it.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1942_targets
   WHERE op IN ('ftpa-reseat', 'ftpa-blank') AND reasoning_before !~* 'for the people act';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % target(s) do not name the For the People Act', n; END IF;
  SELECT count(*) INTO n FROM mig1942_targets
   WHERE op = 'sca-blank'    AND reasoning_before !~* 'safe communities act';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % target(s) do not name the Safe Communities Act', n; END IF;
  SELECT count(*) INTO n FROM mig1942_targets
   WHERE op = 'pwgsa-reseat' AND reasoning_before !~* 'protection of women and girls in sports act';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: the target does not name the Protection of Women and Girls in Sports Act'; END IF;
  SELECT count(*) INTO n FROM mig1942_targets
   WHERE op = 'hb229-blank'  AND reasoning_before !~* 'hb ?229';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % target(s) do not name Texas HB 229', n; END IF;
  SELECT count(*) INTO n FROM mig1942_targets
   WHERE op IN ('md482-reseat', 'md482-blank') AND reasoning_before !~* 'fair districts for maryland act';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % target(s) do not name the Fair Districts for Maryland Act', n; END IF;
END $$;

-- GUARD 4 — 🔴🔴 THE LADDER THIS MIGRATION WAS WRITTEN AGAINST, ON THE REVISION EACH SIDE USES.
-- Two ladders are in play for every re-seat: the Season 1 one the row is read against today, and
-- the Season 2 one the new row will be read against (ADR 0006 — an answer is locked to the ladder
-- it was given against). Both are checked by their TEXT, because a rung NUMBER means nothing
-- outside one revision. This is the trap that put a wrong chair in production in migration 1935.
DO $$
DECLARE n int;
BEGIN
  -- Season 2 must still be the open season; nothing may be written to a closed one.
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                  WHERE id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND status = 'open') THEN
    RAISE EXCEPTION 'migration 1942: Season 2 is not open — do not write to a closed season';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM inform.seasons
                  WHERE id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND status = 'closed') THEN
    RAISE EXCEPTION 'migration 1942: Season 1 is not closed — re-check the assumption this pass rests on';
  END IF;

  -- Every target's Season 1 row must sit on the revision Season 1 pins for its topic.
  SELECT count(*) INTO n
    FROM mig1942_targets t
   WHERE NOT EXISTS (SELECT 1 FROM inform.season_questions sq
                      WHERE sq.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
                        AND sq.topic_id = t.topic_id AND sq.topic_revision_id = t.s1_revision);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % row(s) sit on a revision Season 1 does not pin', n; END IF;

  -- The chair being written must exist on the Season 2 revision.
  SELECT count(*) INTO n
    FROM mig1942_targets t
   WHERE t.value_after > 0
     AND NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions csr
                      WHERE csr.topic_revision_id = t.s2_revision AND csr.value = t.value_after);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % row(s) name a rung that does not exist on the Season 2 revision', n; END IF;

  -- REDISTRICTING. Both re-seat groups turn on chair 1 naming elected officials and chair 2 naming
  -- equal major-party representation.
  SELECT count(*) INTO n FROM mig1942_targets t
    JOIN inform.compass_stance_revisions r ON r.topic_revision_id = t.s2_revision AND r.value = 1
   WHERE t.op IN ('ftpa-reseat', 'md482-reseat') AND r.text !~* 'no elected officials';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: redistricting chair 1 does not read as the no-elected-officials rung — re-read the ladder'; END IF;
  SELECT count(*) INTO n FROM mig1942_targets t
    JOIN inform.compass_stance_revisions r ON r.topic_revision_id = t.s2_revision AND r.value = 2
   WHERE t.op IN ('ftpa-reseat', 'md482-reseat') AND r.text !~* 'equal representation from both major parties';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: redistricting chair 2 does not read as the equal-major-party rung — re-read the ladder'; END IF;

  -- TRANS-ATHLETES. Chair 4 must still be the birth-sex rung and chair 5 the total ban.
  SELECT count(*) INTO n FROM mig1942_targets t
    JOIN inform.compass_stance_revisions r ON r.topic_revision_id = t.s2_revision AND r.value = 4
   WHERE t.op = 'pwgsa-reseat' AND r.text !~* 'biological sex assigned at birth';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: trans-athletes chair 4 is not the birth-sex rung — re-read the ladder'; END IF;
  SELECT count(*) INTO n FROM mig1942_targets t
    JOIN inform.compass_stance_revisions r ON r.topic_revision_id = t.s1_revision AND r.value = 5
   WHERE t.op = 'pwgsa-reseat' AND r.text !~* 'completely ban all transgender athletes';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: trans-athletes chair 5 is not the total-ban rung — re-read the ladder'; END IF;

  -- DEPORTATION. The blank argues chair 2 states a removal threshold the Act never states.
  SELECT count(*) INTO n FROM mig1942_targets t
    JOIN inform.compass_stance_revisions r ON r.topic_revision_id = t.s1_revision AND r.value = 2
   WHERE t.op = 'sca-blank' AND r.text !~* 'serious violent crime';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: deportation chair 2 is not the serious-violent-crime rung — re-read the ladder'; END IF;
END $$;

-- GUARD 5 — 🔴 THIS MIGRATION ONLY INSERTS. If any target pair already holds a row outside
-- Season 1, the population was measured wrongly and the whole pass must be re-measured.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM mig1942_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
   WHERE pa.season_id <> '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % answer row(s) already exist outside Season 1 — re-measure before writing', n; END IF;

  SELECT count(*) INTO n
    FROM mig1942_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
   WHERE pc.season_id <> '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % context row(s) already exist outside Season 1 — re-measure before writing', n; END IF;

  -- Everyone written here must be a live, listable person; a blank on an inactive row is a no-op
  -- that would make the ledger describe something the site never showed.
  SELECT count(*) INTO n
    FROM mig1942_targets t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE NOT p.is_active;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % target(s) sit on inactive people', n; END IF;
END $$;

-- GUARD 6 — the rows this pass deliberately DOES NOT touch, pinned so the ledger cannot describe
-- something untrue. 113 rows are left exactly as they are: the 46 For the People Act rows already
-- at redistricting chair 2, the 22 Protection of Women and Girls in Sports Act rows already at
-- trans-athletes chair 4, and all 45 Inflation Reduction Act rows — the group this pass WITHDREW
-- after reading it (see the header, section A).
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n
    FROM inform.politician_answers pa
    JOIN inform.compass_topics ct ON ct.id = pa.topic_id AND ct.topic_key = 'redistricting'
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
    JOIN essentials.politicians p ON p.id = pa.politician_id AND p.is_active
   WHERE pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND pa.value = 2
     AND pc.reasoning ~* 'for the people act'
     AND NOT EXISTS (SELECT 1 FROM mig1942_targets t
                      WHERE t.politician_id = pa.politician_id AND t.topic_id = pa.topic_id);
  IF n < 46 THEN RAISE EXCEPTION 'migration 1942: expected at least 46 untouched For the People Act rows at chair 2, found %', n; END IF;

  SELECT count(*) INTO n
    FROM inform.politician_answers pa
    JOIN inform.compass_topics ct ON ct.id = pa.topic_id AND ct.topic_key = 'trans-athletes'
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
    JOIN essentials.politicians p ON p.id = pa.politician_id AND p.is_active
   WHERE pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND pa.value = 4
     AND pc.reasoning ~* 'protection of women and girls in sports act'
     AND NOT EXISTS (SELECT 1 FROM mig1942_targets t
                      WHERE t.politician_id = pa.politician_id AND t.topic_id = pa.topic_id);
  IF n < 22 THEN RAISE EXCEPTION 'migration 1942: expected at least 22 untouched sports-act rows at chair 4, found %', n; END IF;

  -- 🔴 THE WITHDRAWN GROUP MUST NOT BE WRITTEN. Section A was adjudicated and then un-adjudicated
  -- on a full read; if a climate row ever reaches this target set, the file has been edited
  -- without its header and the whole transaction should fail rather than write it.
  SELECT count(*) INTO n
    FROM mig1942_targets t
    JOIN inform.compass_topics ct ON ct.id = t.topic_id AND ct.topic_key = 'climate-change';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % climate row(s) in the target set — group A was WITHDRAWN', n; END IF;
END $$;

-- ── THE WRITE ──────────────────────────────────────────────────────────────────────────────────
-- 🔴 Season 1 is CLOSED and IMMUTABLE (ADR 0005 §1.6). Every one of these 114 rows serves from
-- Season 1 with nothing shadowing it, so the only way to correct what a voter reads is to INSERT a
-- Season 2 row, which wins the per-topic collapse (ORDER BY s.number DESC) in every voter-facing
-- consumer. Nothing below touches Season 1, and the closing guard proves it.

INSERT INTO inform.politician_answers
  (politician_id, topic_id, value, season_id, topic_revision_id)
SELECT t.politician_id, t.topic_id, t.value_after, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, t.s2_revision
  FROM mig1942_targets t;

-- The record of WHY — 🔑 with the Season 1 reasoning PRESERVED VERBATIM beneath it, and its
-- citations carried forward unchanged. The votes, co-sponsorships and co-authorships are real and
-- remain good evidence; throwing them away would make a re-read start from nothing.
INSERT INTO inform.politician_context
  (politician_id, topic_id, reasoning, sources, season_id, topic_revision_id)
SELECT t.politician_id, t.topic_id,
       CASE t.op
         WHEN 'ftpa-reseat' THEN $txt$RE-SEATED by migration 1942 — the chair this row was filed under is contradicted by the Act's own text. Shape: A DISCRIMINATING LIMB THAT THE INSTRUMENT FAILS. Chair 1 reads "independent citizens' commissions with no elected officials involved at ANY level"; chair 2 reads "independent redistricting commissions with equal representation from both major parties." The For the People Act fails the first and satisfies the second, by its own sections. Section 2414(b) requires each State to appoint a Select Committee on Redistricting made up of FOUR SITTING STATE LEGISLATORS — one member of each chamber appointed by the leader of the largest party and one by the leader of the second largest — and that committee approves or disapproves the selection pool from which every commissioner must be drawn. Elected officials therefore hold the gate the whole commission passes through, which is "involved" on any reading of the phrase. Section 2411(a)(1) then composes the commission of 15 members: 5 from the majority category, 5 from the minority category and 5 unaffiliated with either — equal representation from both major parties, which is chair 2's own limb. ⚖ The Act does bar officeholders, candidates, party officers, lobbyists and their immediate families from SERVING as commissioners (section 2412(a)(2)), and that is what the original reasoning was reaching for; it is a bar on membership, not the absence of elected officials from the process. 🔑 THE ROW IS NOT UNEVIDENCED — THE MAPPING FAILED. Engrossed text read at https://www.govinfo.gov/content/pkg/BILLS-117hr1eh/html/BILLS-117hr1eh.htm. Written in Season 2 because Season 1 is closed and immutable (ADR 0005 §1.6); redistricting has ONE ladder revision, pinned by both seasons, so no renumbering is involved. THE ORIGINAL EVIDENCE IS KEPT AND IS NOT DOUBTED: the Season 1 reasoning follows verbatim and its citations are carried forward unchanged. ---- ORIGINAL REASONING, PRESERVED ---- $txt$
         WHEN 'ftpa-blank' THEN $txt$INTERNAL RECORD — blanked by migration 1942: the chair does not stand on the evidence this row cites. Shape: A VOTE PROVES THE SIDE, NEVER THE RUNG. The evidence is opposition to the For the People Act — a federal bill that would have REQUIRED every State to hand congressional map-drawing to an independent commission. Voting it down establishes rejection of that federal mandate. It does not choose between chair 4, "state legislatures with court oversight to prevent extreme partisan bias", and chair 5, "the party that controls the state legislature without outside interference", because the Act proposed neither and a Nay says nothing about which of the two the member would prefer. Every row in this group reached its chair by stating that inference out loud — "by opposing this reform, he effectively supports state legislatures retaining redistricting authority, with court oversight as the existing check" — and an inference announced in the reasoning is the thing this audit removes. ⚖ Chair 5 is the stronger overreach of the two: declining to impose commissions on the states is not the same proposition as endorsing unchecked single-party map-drawing, and nothing cited has the member saying so. 🔴 ONE ROW IN THIS GROUP WAS INVERTED OUTRIGHT and is recorded here because it is the clearest defect the contradiction check has surfaced: a member whose reasoning states that he "strongly opposes independent redistricting commissions" was seated at CHAIR 1, the most pro-commission rung on the ladder. THE EVIDENCE IS NOT DOUBTED AND IS KEPT: the original reasoning follows verbatim and the citations are unchanged. A blank asserts only that THIS ROW does not show which rung the person occupies; it does not assert they hold no view. THIS IS A CANDIDATE FOR RE-SEATING ON OWN WORDS, NOT A WRITE-OFF. ---- ORIGINAL REASONING, PRESERVED ---- $txt$
         WHEN 'sca-blank' THEN $txt$INTERNAL RECORD — blanked by migration 1942: the chair does not stand on the evidence this row cites. Shape: THE INSTRUMENT DOES NOT LEGISLATE ON THE LADDER'S QUESTION. The evidence is co-sponsorship of the Massachusetts Safe Communities Act, which limits what STATE AND LOCAL law enforcement may do — honouring ICE detainers, assisting civil immigration enforcement, asking about status. This ladder asks WHO SHOULD BE DEPORTED, and Massachusetts does not decide that; removal is federal. Chair 2 reads "only deport people convicted of serious violent crimes", and the Act states no removal threshold at all, so that chair is an unevidenced claim; chair 1, "stop deportations entirely", is further still. 🔑 THE ROWS STATE THE LEAP THEMSELVES: "ends state and local involvement in civil immigration enforcement — EFFECTIVELY limiting deportation cooperation to serious criminal cases." The word doing the work there is "effectively", and limiting COOPERATION is a different proposition from limiting REMOVAL. ⚖ THIS IS THE PROJECT'S OWN SETTLED RULING, NOT A NEW ONE: migration 1927 blanked three rows seated at deportation chair 1 on this very Act, and migration 1930 extended it to three sanctuary-ordinance rows under the title "a sanctuary ordinance cannot seat a deportation chair". This group is the rest of that cluster — 25 rows the earlier passes could not see because they serve from Season 1. ⚠ There is a separate LOCAL IMMIGRATION ENFORCEMENT ladder on which this Act is squarely on-axis, and that is where this evidence belongs; where no such row exists, the blank leaves a gap to seed by research, which is not a reason to keep an unevidenced chair. THE EVIDENCE IS NOT DOUBTED AND IS KEPT: the original reasoning follows verbatim and the citations are unchanged. ---- ORIGINAL REASONING, PRESERVED ---- $txt$
         WHEN 'pwgsa-reseat' THEN $txt$RE-SEATED by migration 1942 — the chair this row was filed under is wider than the Act it rests on. Shape: THE INSTRUMENT RESTRICTS ONE CATEGORY OF PROGRAMME, NOT ALL SPORT. Chair 5 reads "completely ban all transgender athletes from competing in any organized sports competitions." The Protection of Women and Girls in Sports Act does not do that. Its single operative section adds 20 U.S.C. 1681(d)(1), making it a Title IX violation for a recipient "to permit a person whose sex is male to participate in an athletic program or activity that is designated for women or girls", with sex recognised "based solely on a person's reproductive biology and genetics at birth". It reaches women's and girls' programmes only; it bars nobody from men's or mixed competition, and subsection (d)(4) expressly preserves a recipient's ability to let males train or practise with a women's programme where no female loses a place or benefit. That is chair 4 — "require transgender athletes to compete only on teams matching their biological sex assigned at birth" — stated almost in the ladder's own words. The 2023 Act (H.R. 734, 118th) this row cites and the 2025 Act (H.R. 28, 119th) carry the SAME operative amendment; both were read. 🔑 THE ROW IS NOT UNEVIDENCED — THE MAPPING FAILED; the vote is real and 22 colleagues citing the same Act sit correctly at chair 4. Engrossed text read at https://www.govinfo.gov/content/pkg/BILLS-118hr734eh/html/BILLS-118hr734eh.htm. Written in Season 2 because Season 1 is closed and immutable (ADR 0005 §1.6); chairs 4 and 5 are textually identical on both ladder revisions, so no renumbering is involved. THE ORIGINAL EVIDENCE IS KEPT AND IS NOT DOUBTED: the Season 1 reasoning follows verbatim and its citations are carried forward unchanged. ---- ORIGINAL REASONING, PRESERVED ---- $txt$
         WHEN 'hb229-blank' THEN $txt$INTERNAL RECORD — blanked by migration 1942: the chair does not stand on the evidence this row cites. Shape: THE INSTRUMENT DOES NOT LEGISLATE ON THE LADDER'S QUESTION — AND A FINDINGS CLAUSE IS NOT AN OPERATIVE PROVISION. The evidence is co-authorship of Texas HB 229 (89R), "relating to general definitions for and collection of governmental information regarding biological sex". The enrolled Act has exactly three operative sections: SECTION 2 adds definitions of "boy", "father", "female", "girl", "male", "mother" and "sex" to Government Code 311.005; SECTION 3 adds Government Code 2051.252, requiring a governmental entity that collects vital statistics information identifying sex to record each individual as male or female; SECTION 4 is the effective date. NOTHING IN THE ACT REGULATES ATHLETIC PARTICIPATION. The word "athletics" appears only inside SECTION 1, the legislative FINDINGS, as one item in a list of contexts — alongside prisons, domestic violence shelters, locker rooms and restrooms — in which the legislature finds sex distinctions may be legitimate. A finding is not a rule, and a bill that mentions a subject in a recital has not legislated on it. 🔑 THE ROWS STATE THE LEAP THEMSELVES, in two forms: the careful one calls the Act "the ENFORCEMENT MECHANISM for sex-based sports eligibility", which concedes that the eligibility rule is somewhere else; the careless one asserts flatly that the Act "bans transgender athletes from competing on teams matching their gender identity", which the enrolled text does not say. ⚖ This is the same ruling as migrations 1927 and 1930 on a different ladder: an off-axis instrument cannot seat a chair at any rung, so the split between chairs 4 and 5 that flagged this group is not resolved by picking one — both go. ⚠ Texas does restrict school and collegiate athletic participation by birth sex, in the Save Women's Sports Act (HB 25, 87R) and SB 15 (88R); a member who authored one of THOSE can be seated on it. This blank says only that HB 229 is not that statute. Enrolled text read at https://capitol.texas.gov/tlodocs/89R/billtext/html/HB00229F.htm. THE EVIDENCE IS NOT DOUBTED AND IS KEPT: the original reasoning follows verbatim and the citations are unchanged. ---- ORIGINAL REASONING, PRESERVED ---- $txt$
         WHEN 'md482-reseat' THEN $txt$RE-SEATED by migration 1942 — this bill's own membership section names its chair, and it is neither of the two this group was split across. Shape: ONE INSTRUMENT, IDENTICAL EVIDENCE, TWO CHAIRS — SO AT MOST ONE COULD BE RIGHT, AND NEITHER WAS. Twenty-two sponsors of the same bill were seated eleven at chair 1 and eleven at chair 4. Chair 1 reads "independent citizens' commissions with no elected officials involved at ANY level". Section 8-7A-05(A) of the Fair Districts for Maryland Act (HB 482, 2026RS) gives the Redistricting Commission TEN members, FOUR OF WHOM SIT ON IT BY VIRTUE OF ELECTED OFFICE — the President of the Senate, the Speaker of the House, the Minority Leader of the Senate and the Minority Leader of the House of Delegates — plus one member appointed by each of those four, plus two appointed by the Governor subject to unanimous approval of the Senate Executive Nominations Committee and the House Rules and Executive Nominations Committee. Elected officials are not merely involved; they are a plurality of the commission. Chair 4, "state legislatures with court oversight to prevent extreme partisan bias", is further off: proposed Article XXI, section 2(B) makes the Commission "the EXCLUSIVE MEANS to adopt any plan to alter legislative districts or congressional districts", which removes the General Assembly from map-drawing rather than preserving it. ⚠ The eleven rows at chair 4 did not describe a chair at all — they recorded a motive ("a Republican-led redistricting reform effort opposing Democratic-drawn maps"), and a motive is not a position on a ladder. WHY CHAIR 2: the commission is constituted as "an INDEPENDENT UNIT of State government" (Article XXI, section 2(C)(2)) and its membership is balanced four-and-four between the two major parties by construction, which is chair 2's limb, "independent redistricting commissions with equal representation from both major parties". ⚖ Chair 3 was weighed and declined: its supermajority limb fits (section 8-7A-06(A)(2) requires seven of ten votes for any plan), but its noun — "bipartisan legislative COMMITTEES" — does not, because section 2(B) displaces the legislature instead of working through it. Bill text read at https://mgaleg.maryland.gov/2026RS/bills/hb/hb0482F.pdf. Written in Season 2 because Season 1 is closed and immutable (ADR 0005 §1.6); redistricting has ONE ladder revision, pinned by both seasons. THE ORIGINAL EVIDENCE IS KEPT AND IS NOT DOUBTED: the Season 1 reasoning follows verbatim and its citations are carried forward unchanged. ---- ORIGINAL REASONING, PRESERVED ---- $txt$
         WHEN 'md482-blank' THEN $txt$INTERNAL RECORD — blanked by migration 1942: the cited record does not show what the row says it shows. Shape: THE SPONSORSHIP IS NOT IN THE BILL'S SPONSOR LIST. The row rests on co-sponsorship of the Fair Districts for Maryland Act and cites only this member's own legislature profile page, not the bill. The Act's House version for the 2026 Regular Session, HB 482, lists twenty-eight sponsors on its face — Buckel, Pippy, Adams, Anderson, Arentz, Baker, Beauchamp, Chisholm, Griffith, Hartman, Hinebaugh, Hornberger, Hutchinson, Jacobs, Kipke, R. Long, Mangione, McComas, Metzgar, Miller, T. Morgan, Nkongolo, Reilly, Rose, Schmidt, Tomlinson, Valentine and Wivell — and this member is not among them; nor does the Senate companion, SB 2102, carry the name. The other twenty-one members in this group were confirmed against that list and are re-seated on the bill's text; this row alone could not be. ⚖ The chair would have been wrong in any event: chair 4, "state legislatures with court oversight", is not what the Act proposes, since its Article XXI section 2(B) makes the commission the exclusive means of adopting a plan. But a row whose stated evidence cannot be located is blanked rather than moved, because moving it would carry the unverified claim to a new chair. THIS IS A CANDIDATE FOR RE-SEATING, NOT A WRITE-OFF: if a sponsorship of this Act in an earlier session is found, the row re-seats at chair 2 with the rest. Sponsor list read at https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0482?ys=2026RS. The original reasoning follows verbatim and the citations are unchanged. ---- ORIGINAL REASONING, PRESERVED ---- $txt$
       END || t.reasoning_before,
       t.sources_before, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, t.s2_revision
  FROM mig1942_targets t;

-- ── VERIFY THE RESULT, NOT THE ABSENCE OF AN ERROR ─────────────────────────────────────────────
DO $$
DECLARE n int; before_s2 int; after_s2 int; before_s1 int; after_s1 int;
BEGIN
  -- Every target now holds a Season 2 answer at exactly the adjudicated value, on the revision
  -- Season 2 pins.
  SELECT count(*) INTO n
    FROM mig1942_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = t.value_after AND pa.topic_revision_id = t.s2_revision;
  IF n <> 114 THEN RAISE EXCEPTION 'migration 1942: expected 114 rows at their adjudicated value, found %', n; END IF;

  SELECT count(*) INTO n
    FROM mig1942_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = 0;
  IF n <> 73 THEN RAISE EXCEPTION 'migration 1942: expected 73 blanks, found %', n; END IF;

  SELECT count(*) INTO n
    FROM mig1942_targets t
    JOIN inform.politician_answers pa
      ON pa.politician_id = t.politician_id AND pa.topic_id = t.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value > 0;
  IF n <> 41 THEN RAISE EXCEPTION 'migration 1942: expected 41 re-seats, found %', n; END IF;

  -- Nothing lost its citations, and every new row says which kind of row it is and keeps what it
  -- replaced.
  SELECT count(*) INTO n
    FROM mig1942_targets t
    JOIN inform.politician_context pc
      ON pc.politician_id = t.politician_id AND pc.topic_id = t.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE coalesce(cardinality(pc.sources), 0) = 0
      OR pc.sources IS DISTINCT FROM t.sources_before
      OR pc.reasoning NOT LIKE '%---- ORIGINAL REASONING, PRESERVED ---- %'
      OR strpos(pc.reasoning, t.reasoning_before) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % new row(s) lost citations or lost the original reasoning', n; END IF;

  -- 🔴 THE CLOSED SEASON DID NOT MOVE. Not one Season 1 value or timestamp may have changed.
  SELECT count(*) INTO n
    FROM mig1942_season1_before b
    JOIN inform.politician_answers pa
      ON pa.politician_id = b.politician_id AND pa.topic_id = b.topic_id
     AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
   WHERE pa.value IS DISTINCT FROM b.value OR pa.updated_at IS DISTINCT FROM b.updated_at;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1942: % Season 1 row(s) moved — the closed season must be untouched', n; END IF;

  SELECT seated_season1, seated_season2 INTO before_s1, before_s2 FROM mig1942_before;
  SELECT count(*) INTO after_s1 FROM inform.politician_answers
   WHERE season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND value > 0;
  IF after_s1 <> before_s1 THEN RAISE EXCEPTION 'migration 1942: the Season 1 seated count moved from % to %', before_s1, after_s1; END IF;

  -- Season 2 gains exactly the re-seats; the blanks add rows but no seats.
  SELECT count(*) INTO after_s2 FROM inform.politician_answers
   WHERE season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND value > 0;
  IF after_s2 - before_s2 <> 41 THEN
    RAISE EXCEPTION 'migration 1942: Season 2 seated count moved by %, expected 41', after_s2 - before_s2;
  END IF;

  RAISE NOTICE 'migration 1942: % rows written — % re-seated, % withdrawn; Season 1 unmoved',
    114,
    41,
    73;
END $$;
