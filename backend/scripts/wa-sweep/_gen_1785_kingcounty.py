# Generates 1785_king_county_web_sources.sql.
# Same shape as _gen_1784_seattle.py: data table in, guarded migration out.
import io, os

P = {
    'fain':          ('0d99bf79-7627-4a38-9725-9e569478162e', 'Steffanie Fain'),
    'manion':        ('39544d21-7c0d-46fb-a3d0-a46302afa0f2', 'Leesa Manion'),
    'wise':          ('adf70aaa-33bd-4eeb-9084-264dcd302865', 'Julie Wise'),
    'dunn':          ('5ed0cfd6-c7d1-4597-9855-34d7643edc6f', 'Reagan Dunn'),
    'pvr':           ('5d2c2935-5de1-4abc-b8e6-01ed595b16c0', 'Pete von Reichbauer'),
    'coletindall':   ('2e43aca9-1b7e-4df8-8b9f-b686ecb90f03', 'Patti Cole-Tindall'),
    'assessor':      ('42f94e0e-1a15-45e7-ab46-572a9ea0a013', 'John Wilson'),
}
T = {
    'residential-zoning':              'd4f18138-a2e0-4110-b925-7387d9d0d16d',
    'housing':                         '669cac97-66a6-4087-b036-936fbe62efb3',
    'taxes':                           'f7e5678d-dadd-4556-a2fc-446e24642ceb',
    'public-safety-approach':          'e9ebefcd-c496-45e8-b816-a79f8442ba85',
    'homelessness-response':           '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
    'local-environment':               '1935979c-b290-42e4-baa5-8cb0138b4ffa',
    'judicial-prosecution-priorities': 'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
    'judicial-criminal-justice':       '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
    'local-immigration':               'b9ccee94-ad96-4f10-b655-889d8e5abe92',
    'economic-development':            'eb3d1247-0de1-4b7f-baec-7259861efd53',
    'voting-rights':                   'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
    'transportation-priorities':       'ba59337e-30e2-4aba-a39a-426b3366eb27',
}
FAIN_Q     = 'https://www.theurbanist.org/content/files/www-theurbanist-org/wp-content/uploads/2025/07/steffanie-fain-urbanist-questionnaire-responses-2025-kcc-d5.pdf'
MANION_Q   = 'https://publicola.com/2022/11/03/publicola-questions-king-county-prosecuting-attorney-candidate-leesa-manion/'
MANION_RCP = 'https://www.kuow.org/stories/king-county-prosecutor-pauses-youth-felony-diversion-citing-high-reoffending-rates'
WISE       = 'https://kingcounty.gov/en/dept/elections/about-us/meet-the-director'
DUNN_PAMP  = 'https://info.kingcounty.gov/kcelections/Vote/contests/candidates.aspx?cid=167340&candidateid=1639903&lang=en-US&pamphletson=true'
DUNN_HTH   = 'https://kingcounty.gov/council/news/2020/October/10-13-Reagan-D-housing-tax-release.aspx'
PVR        = 'https://www.federalwaymirror.com/news/meet-king-county-council-district-7-candidate-pete-von-reichbauer/'
SHERIFF    = 'https://kingcounty.gov/en/dept/sheriff/about-king-county/about-sheriff-office/immigrants-refugees'
ASSESSOR   = 'https://kingcounty.gov/en/dept/assessor/buildings-and-property/property-taxes/tax-relief/senior-or-disabled-exemptions'

R = [
# ── Steffanie Fain, Council District 5 ───────────────────────────────────────────────────────────
('fain','residential-zoning',3,
 'Fain names "targeted zoning changes, streamlined permitting, and transit-oriented development" among her top three priorities, and would "increase production of housing at all levels--especially middle housing and ADUs--through incentives like density bonuses, reduced parking minimums, and streamlined permitting", with "Upzoning near frequent transit" and allowing "diverse housing types within a quarter-mile of high-capacity transit". Density concentrated at transit and job centres rather than applied broadly is chair 3. Chair 4 is not reached: her own word for the zoning changes is "targeted", and her upzoning is bounded by a quarter-mile transit radius rather than by-right citywide.',
 [FAIN_Q]),
('fain','housing',3,
 'Fain would support "public investment in community land trusts and nonprofit housing providers that deliver long-term affordability", pair incentives with "public investment, technical support, or fee deferrals", and reduce delays by templatizing and digitizing infill permitting. Subsidies for affordable projects plus easier permitting is chair 3. Chair 2 requires rent caps as well as affordability requirements and public funding: she holds the second and third but proposes no rent cap, offering instead "rental assistance, legal support in eviction proceedings, longer notice periods for rent increases", which regulate the process of a rent increase rather than its size.',
 [FAIN_Q]),
('fain','taxes',3,
 'Fain conditions new revenue on proving stewardship first: "Before asking the public for more, we must prove we are good stewards of public dollars. King County budget has grown significantly over the last few years", starting with "a clear-eyed review of current spending: evaluating outcomes, cutting duplication, and phasing out programs that no longer meet today needs". The revenue tools she names are "closing tax loopholes, leveraging public-private partnerships", and any new funding "should avoid placing unnecessary burdens on working families or small businesses". Closing loopholes while otherwise keeping the system as-is is chair 3. Chairs 1 and 2 are refuted: she nowhere proposes raising taxes on wealthy people or large companies.',
 [FAIN_Q]),
('fain','public-safety-approach',2,
 'Fain would "ensure cities have fully staffed first responders, while also investing in robust co- and alternative-responder programs", because those programs "improve outcomes and allow first responders to focus on incidents that require their specialized training and authority". Holding staffing at full strength while moving the calls that do not need a sworn responder to co-responders is chair 2. Chair 4 is not reached because she proposes no increase beyond full staffing, and chair 3 is the weaker fit because her stated mechanism is reallocating call types rather than adding teams on top of current funding.',
 [FAIN_Q]),
('fain','homelessness-response',2,
 'Fain frames homelessness as "a visible symptom of deeper failures in our housing and behavioral health systems" and would "expand access to housing options across the board and improve service coordination so people do not fall through the cracks", strengthening "coordination across the behavioral health system so individuals do not fall through the cracks during transitions--like from detox to inpatient treatment to housing and long-term support". Expanding housing and services as the primary strategy is chair 2. Chairs 4 and 5 are refuted because she proposes no enforcement tool; chair 1 is not reached because she does not commit to housing-first without preconditions.',
 [FAIN_Q]),
('fain','local-environment',3,
 'On rural land protection Fain would "strategically focus resources on high-risk and ecologically sensitive areas", pair enforcement with "technical assistance and clear guidance" to "reduce violations and foster a more cooperative approach to land protection", and apply "consistent, meaningful penalties" when violations occur, "while recognizing the fiscal and operational realities we face". Consistent standards applied with reasonable flexibility is chair 3. Chairs 1 and 2 are not reached: she adds no preservation or full-offset duty to development, and her emphasis is enforcing the rules that exist rather than raising them.',
 [FAIN_Q]),
# ── Leesa Manion, Prosecuting Attorney ───────────────────────────────────────────────────────────
('manion','judicial-prosecution-priorities',3,
 'Manion describes her charging practice as "we file conservatively, that we want people to take accountability early on, and we are not overcharging", and she co-founded the Choose 180 pre-filing diversion programme. As the sitting prosecutor she then paused felony referrals to Restorative Community Pathways after a recidivism analysis showed 53 percent reoffending within 24 months for felony referrals against 37 percent for misdemeanours, saying "because of that, and because we have discretion, I made the decision to temporarily pause felony referrals", and redirecting those cases "to more court-supervised diversion programs" rather than dismissing them. Using diversion where the benefit is demonstrated and treating it as a judgment call on the evidence is chair 3. Chair 2 is not reached because she does not reserve prosecution for when community safety requires it; chairs 4 and 5 are refuted because she keeps diversion and expanded it for adults.',
 [MANION_Q, MANION_RCP]),
('manion','judicial-criminal-justice',3,
 'Manion pairs early accountability with support and sorts cases by what happened. She says the goal is that "people take accountability early on", is a co-founding partner of Choose 180, and cites Restorative Community Pathways recidivism of "8 percent compared to either 21 percent or 58 percent"; she also supports the "aspirational goal of zero youth detention" while noting "we do not have the upstream support. We do not have enough services to meet the needs." Her felony-versus-misdemeanour split in the 2024 diversion pause is the ladder chair 3 clause "depending on what happened" applied literally. Chair 2 is not reached because restitution and treatment are not offered as the general answer, and chairs 4 and 5 are refuted by her diversion record.',
 [MANION_Q, MANION_RCP]),
# ── Julie Wise, Director of Elections ────────────────────────────────────────────────────────────
('wise','voting-rights',2,
 'Wise is described by her own office as "A champion for increasing both accessibility and security... dedicated to removing barriers to voting, while maintaining accuracy, security, and transparency", and the record is of advocacy rather than administration: her "push for prepaid postage in King County led to statewide action resulting in prepaid postage for all Washington voters in 2018", she took ballot drop boxes "from just 10 when she took office to over 80 today", she created the Voter Education Fund for non-partisan registration work in historically marginalized communities, and the office provides materials in seven languages. Removing the cost and distance barriers to returning a mail ballot, and opening vote centres for same-day registration, is chair 2. Chair 1 is not reached because she has never advocated online voting, and chairs 3 to 5 are refuted because every change she has pursued widens access rather than conditioning it on identification.',
 [WISE]),
# ── Reagan Dunn, Council District 9 ──────────────────────────────────────────────────────────────
('dunn','taxes',4,
 'In his own candidate statement Dunn writes that he is "running for re-election to fight against new and unnecessary taxes, higher fees, and government spending at all levels that are making it harder for working families to be able to afford to live here in King County", that "I will fight to keep your taxes low", and that "I will continue to prioritize government spending so that critical emergency services and road maintenance are properly funded". Chair 4 requires both limbs: cutting taxes for everyone AND scaling back public services to match. He states both, opposing the revenue and the spending together and naming only emergency services and road maintenance as what should be funded. Chair 5 is refused on the adverb rule that has governed this ladder since migration 1759: nothing in the statement supports "drastically", and he commits to funding critical services rather than shrinking government as such.',
 [DUNN_PAMP]),
# ── Pete von Reichbauer, Council District 7 ──────────────────────────────────────────────────────
('pvr','economic-development',2,
 'Asked about his priorities, von Reichbauer said "I want to make sure we work as a group, bringing together local cities and the private sector to create more job producing businesses here", argued that "70% of new jobs are produced by small businesses, not large corporations", and would modify county regulations and direct county contracts toward small enterprises, alongside apprenticeship programmes in local school districts. Small business support and local entrepreneur programmes, expressly contrasted with large corporations, is chair 2. Chairs 3 to 5 are not reached: he proposes no industry incentives, no tax abatements and no competition for major employers. His avoidance of large corporate subsidies is implied by that contrast rather than stated, which is incompleteness rather than contradiction.',
 [PVR]),
# ── DOCUMENTED BLANKS ────────────────────────────────────────────────────────────────────────────
('coletindall','local-immigration',None,
 'Unable to place on this ladder. The King County Sheriff Office does not honor ICE detainers, but its own page presents that as mandatory compliance rather than a choice, citing three binding authorities: RCW 10.93.160, K.C.C. 2.15 (Citizen and Immigration Status) and General Orders Manual 5.05.000. 🔑 K.C.C. 2.15 is the chapter created by Ordinance 18665 -- the very instrument that seated Balducci and Dembowski at chair 2 in migration 1754. The councilmembers who WROTE the policy hold the chair; the appointed sheriff who EXECUTES it does not. Nothing in the record shows Cole-Tindall advocating for, against, or beyond the policy she administers, and she is appointed rather than elected, so there is no candidate statement either. Executing a policy is not holding a position.',
 [SHERIFF]),
('assessor','taxes',None,
 'Unable to place on this ladder. The Assessor office administers property tax relief but does not set it: the county page states plainly that "State law provides 2 tax benefit programs for senior citizens and persons with disabilities", and the office role is processing applications and notifying applicants, not setting eligibility criteria or income thresholds, which come from state legislation. An assessor values property and applies rates set elsewhere, so the office itself answers none of this ladder question about the balance between what government collects and what it spends. Wilson did state budget and tax positions as a 2025 candidate for County Executive, but that campaign was suspended and no primary source for those positions could be fetched, so they are not relied on here. Same distinction as the Sheriff above: administering a rule is not holding a position on it.',
 [ASSESSOR]),
('pvr','transportation-priorities',None,
 'Unable to place on this ladder. Transportation is one of von Reichbauer two named priorities and he still states no modal preference. His formulation is "We need to recognize how our transportation modes fit not the last decade, but the next decade", framed around adapting service to remote work patterns, and his candidate statement offers only "working to improve transportation modes for South King County commuters". Every chair on this ladder turns on where investment should go as between roads, transit and pedestrian or cycling infrastructure, and he ranks none of them against the others. Naming the subject is not answering the question.',
 [PVR, FAIN_Q]),
('dunn','homelessness-response',None,
 'Unable to place on this ladder. Dunn cast the lone No vote against the 2020 Health Through Housing sales tax, which funds permanent housing for chronically homeless people, and has since co-sponsored beginning the dissolution of the King County Regional Homelessness Authority. His stated rationale is process and efficacy rather than a position on strategy: "The lack of adequate public process for this tax increase has created uncertainties for our suburban cities", "This lightning speed process and lack of a collaborative approach is a sore spot for cities", and "These are policies that are not working. Throwing more money at the problem, without a serious rethinking of our strategies and performance measures, may not make the problem of homelessness in King County much better." Arguing that a programme does not work, and that it was adopted too fast, refutes chair 1 but evidences none of chairs 2 to 5, because he proposes no enforcement tool and no alternative strategy. Same shape as SB 6022 in migration 1783: an efficacy argument is not a position on the ladder question. His candidate statement adds only that he is "committed to finding real solutions to our regional homelessness crisis and will continue to help those who suffer from drug and alcohol addiction", which refutes chair 5 as well.',
 [DUNN_HTH, DUNN_PAMP]),
]

seats  = [r for r in R if r[2] is not None]
blanks = [r for r in R if r[2] is None]

def arr(urls):
    return 'ARRAY[' + ','.join("'" + u + "'" for u in urls) + ']'

out = io.StringIO(); w = out.write
w("""-- 1785_king_county_web_sources.sql
-- King County's 8 uncovered officials, re-researched from WEB sources. %d seated rows + %d blanks,
-- reaching 5 of the 8. This is the companion to migration 1784 (Seattle) and closes the caveat that
-- migration left open: King County's blanks were still vote-first-only artefacts.
--
-- ⚠ THE YIELD IS MUCH LOWER THAN SEATTLE (42 rows / 11 of 11) AND THAT IS STRUCTURAL, NOT EFFORT.
-- Seattle's eleven are all elected policy-makers who ran contested campaigns, so nine of them had a
-- long-form candidate questionnaire. King County's eight are a different population: THREE hold
-- administrative offices (Assessor, Elections, Sheriff), ONE was appointed three months ago, and TWO
-- are long-serving members who decline questionnaires. Only Fain had an Urbanist questionnaire.
--
-- ── 🔑 EXECUTING A POLICY IS NOT HOLDING A POSITION ───────────────────────────────────────────────
-- The most transferable finding here, and it will recur in every county and every sheriff's office.
-- The King County Sheriff's Office does not honor ICE detainers -- and its own page presents that as
-- compliance with three BINDING authorities: RCW 10.93.160, K.C.C. 2.15 and GOM 5.05.000.
-- **K.C.C. 2.15 is the chapter created by Ordinance 18665, the very instrument that seated Balducci
-- and Dembowski at local-immigration chair 2 in migration 1754.** The councilmembers who WROTE the
-- policy hold the chair; the appointed sheriff who EXECUTES it does not. Identical shape at the
-- Assessor, where the page says "State law provides 2 tax benefit programs" and the office processes
-- applications. Seating either would have looked like coverage and been a category error.
--
-- ── 🔑 THE LINE IS ADVOCACY vs ADMINISTRATION, AND JULIE WISE IS ON THE OTHER SIDE OF IT ──────────
-- An administrator is not automatically unplaceable. Wise REQUESTED prepaid postage for all voters
-- and her push "led to statewide action resulting in prepaid postage for all Washington voters in
-- 2018"; she took drop boxes from 10 to over 80 and created the Voter Education Fund. Advocating a
-- change in the law is a position; applying a law someone else wrote is not. That is the test, and
-- it is what separates her from Cole-Tindall and the Assessor.
--
-- ── 🔑 taxes CHAIR 4 IS REACHABLE FROM A CANDIDATE STATEMENT THOUGH UNREACHABLE FROM LEGISLATION ──
-- The WA sweep blanked FOUR legislators across both parties on taxes chair 4 (Orcutt, Krishnadasan,
-- Steele, Schoesler) because the chair carries a consequence clause -- "and scale back public
-- services to match" -- that tax-cut BILLS never legislate about themselves. Dunn's own candidate
-- statement states it: he opposes "new and unnecessary taxes, higher fees, AND government spending
-- at all levels" and names only emergency services and road maintenance as what should be funded.
-- **The chair is not broken everywhere; it is broken for one SOURCE CLASS.** Same lesson as housing
-- chair 2 in migration 1784: reachability is a property of a chair meeting a corpus.
--
-- ── 🔑 TWO SOURCE CLASSES EARNED THEIR PLACE ─────────────────────────────────────────────────────
-- · **The King County voters' pamphlet** (info.kingcounty.gov/kcelections/...&pamphletson=true) is
--   candidate-AUTHORED and official. It is what reached Dunn.
-- · **Hyperlocal news.** The Federal Way Mirror interview produced von Reichbauer's ONLY chair. His
--   pamphlet statement is pure valence ("listening to, and fighting for, us") and reaches nothing.
--   For a long-serving member who skips questionnaires, the community paper is the source of record.
--
-- ⚠ RHONDA LEWIS (D2) GETS NO ROWS AND NO TOPIC BLANKS, DELIBERATELY. Appointed 2025-12-09 from
-- Zahilay's staff; her only public document is a biography with no policy positions. A per-ladder
-- blank would assert an absence nobody tested, so the record is this comment plus the write-up --
-- the same disposition as Jinkins and Stokesbary in the legislative sweep.
--
-- ▶ OWED: Zahilay (now County Executive, carrying ONE row) and Balducci both have full 2025 Urbanist
-- questionnaires already located but outside this pass's scope. They are the two most consequential
-- County officials and the highest-value remaining work.
BEGIN;

CREATE TEMP TABLE kc_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

CREATE TEMP TABLE kc_rows (pid uuid, tid uuid, val int, nm text, tk text) ON COMMIT DROP;
INSERT INTO kc_rows (pid, tid, val, nm, tk) VALUES
""" % (len(seats), len(blanks)))

vals = []
for who, tk, val, _r, _s in R:
    pid, nm = P[who]
    vals.append("('%s','%s',%s,'%s','%s')" % (pid, T[tk], 'NULL' if val is None else val,
                                              nm.replace("'", "''"), tk))
w(',\n'.join(vals) + ';\n\n')

# NOTE: this block is NOT %-formatted, so percent signs are written LITERALLY here.
# Writing '%%' in a plpgsql RAISE means a literal percent and consumes no argument, so
# `RAISE '... %% ...', n` fails at runtime with "too many parameters specified for RAISE" --
# a guard that only breaks WHEN IT FIRES. Keep single % in this block.
w("""DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM kc_rows r
    JOIN inform.politician_answers a ON a.politician_id=r.pid AND a.topic_id=r.tid;
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % of these pairs already have an answer', n; END IF;
  SELECT count(*) INTO n FROM kc_rows r
    JOIN inform.politician_context c ON c.politician_id=r.pid AND c.topic_id=r.tid;
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % of these pairs already have a context row', n; END IF;

  -- The Cole-Tindall blank argues that Ordinance 18665's authors hold the chair she does not. If
  -- those rows have moved, the reasoning in that blank no longer stands.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE topic_id='b9ccee94-ad96-4f10-b655-889d8e5abe92' AND value=2
     AND politician_id IN ('cd772ac3-d63b-4767-9198-ec4f1fb36f4d','1c6c1a17-f235-4ccb-9201-5cbc35bfbf8a');
  IF n <> 2 THEN RAISE EXCEPTION 'pre-check: Balducci/Dembowski local-immigration=2 not both present (found %)', n; END IF;

  -- Chair-text tripwires for the two ladders carrying the argument-heavy rows.
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='f7e5678d-dadd-4556-a2fc-446e24642ceb' AND value=4 AND text ILIKE '%scale back public services%';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: taxes chair 4 no longer carries the scale-back clause -- re-argue Dunn'; END IF;
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='eb3d1247-0de1-4b7f-baec-7259861efd53' AND value=2 AND text ILIKE '%small business%';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: economic-development chair 2 has been reworded'; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
""")

ctx = []
for who, tk, _v, reason, src in R:
    pid, _nm = P[who]
    ctx.append("('%s','%s',\n $r$%s$r$,\n %s)" % (pid, T[tk], reason, arr(src)))
w(',\n'.join(ctx) + ';\n\n')

w("INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES\n")
ans = []
for who, tk, val, _r, _s in seats:
    pid, _nm = P[who]
    ans.append("('%s','%s', %d)" % (pid, T[tk], val))
w(',\n'.join(ans) + ';\n\n')

w("""DO $$
DECLARE ans_after int; ctx_after int; s record; bad int; n int;
BEGIN
  SELECT * INTO s FROM kc_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + %d THEN
    RAISE EXCEPTION 'guard 1: answers %% -> %%, expected +%d', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + %d THEN
    RAISE EXCEPTION 'guard 1: context %% -> %%, expected +%d', s.ctx_before, ctx_after; END IF;

  SELECT count(*) INTO bad
    FROM kc_rows r
    JOIN inform.politician_answers a ON a.politician_id=r.pid AND a.topic_id=r.tid
    JOIN inform.politician_context c ON c.politician_id=r.pid AND c.topic_id=r.tid
   WHERE r.val IS NOT NULL
     AND (a.value <> r.val
          OR coalesce(cardinality(c.sources),0) = 0
          OR length(c.reasoning) < 200);
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: %% seated row(s) wrong chair, thin reasoning or unsourced', bad; END IF;

  -- Chair SPREAD: a bug collapsing every row onto one value still satisfies the check above.
  SELECT count(DISTINCT a.value) INTO n FROM kc_rows r
    JOIN inform.politician_answers a ON a.politician_id=r.pid AND a.topic_id=r.tid;
  IF n <> 3 THEN RAISE EXCEPTION 'guard 2: expected chairs 2,3,4 across this pass, found %% distinct', n; END IF;
  SELECT count(*) INTO n FROM kc_rows r
    JOIN inform.politician_answers a ON a.politician_id=r.pid AND a.topic_id=r.tid
   WHERE r.tk='taxes' AND a.value=4;
  IF n <> 1 THEN RAISE EXCEPTION 'guard 2: Dunn taxes=4 missing -- the source-class finding rests on it'; END IF;

  -- Blanks: context, sources, carve-out phrase, and NO answer.
  SELECT count(*) INTO bad
    FROM kc_rows r
    JOIN inform.politician_context c ON c.politician_id=r.pid AND c.topic_id=r.tid
   WHERE r.val IS NULL
     AND (c.reasoning !~ '^Unable to place on this ladder'
          OR coalesce(cardinality(c.sources),0) = 0
          OR EXISTS (SELECT 1 FROM inform.politician_answers a
                      WHERE a.politician_id=r.pid AND a.topic_id=r.tid));
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: %% documented blank(s) malformed or carrying an answer', bad; END IF;

  -- 5 of the 8 must now hold at least one answer.
  SELECT count(*) INTO n FROM (
    SELECT DISTINCT r.pid FROM kc_rows r
      JOIN inform.politician_answers a ON a.politician_id=r.pid) x;
  IF n <> 5 THEN RAISE EXCEPTION 'guard 2: %% of the 8 hold an answer, expected 5', n; END IF;
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
     AND pc.reasoning !~* '^researched\\s+[0-9]{4}-[0-9]{2}-[0-9]{2}'
     AND pc.reasoning !~* 'no (scorable |substantive |specific |detailed )?public record|no public statements? found|no record found|no scorable|unable to place|insufficient public record|no substantive [a-z ]{0,40}(available|found)';
  IF orphans <> 50 THEN RAISE EXCEPTION 'guard 3: ORPHAN_CONTEXT is %%, expected 50', orphans; END IF;

  SELECT count(*) INTO ans_wo_ctx FROM inform.politician_answers a
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                      WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ans_wo_ctx > 0 THEN RAISE EXCEPTION 'guard 3: %% answer(s) have no context', ans_wo_ctx; END IF;

  RAISE NOTICE 'King County: %d seated rows + %d documented blanks, reaching 5 of the 8; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
""" % (len(seats), len(seats), len(R), len(R), len(seats), len(blanks)))

dest = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..',
                    'migrations', '1785_king_county_web_sources.sql')
with open(dest, 'w', encoding='utf-8', newline='\n') as f:
    f.write(out.getvalue())
print('wrote %s' % os.path.normpath(dest))
print('seated=%d blanks=%d total_context=%d' % (len(seats), len(blanks), len(R)))
