# Generates 1786_kc_executive_candidates.sql — Zahilay + Balducci from their 2025 Executive-race
# questionnaires. Same shape as _gen_1784 / _gen_1785.
# NOTE on percent signs: blocks written WITHOUT a trailing `% (...)` are emitted literally, so use a
# SINGLE % there. '%%' in a plpgsql RAISE is a literal percent consuming no argument and blows up
# with "too many parameters specified for RAISE" -- a guard that only breaks WHEN IT FIRES.
import io, os

P = {
    'zahilay':  ('1f63b667-7da3-4d75-b3ae-24529393741e', 'Girmay Zahilay'),
    'balducci': ('cd772ac3-d63b-4767-9198-ec4f1fb36f4d', 'Claudia Balducci'),
}
T = {
    'housing':                   '669cac97-66a6-4087-b036-936fbe62efb3',
    'residential-zoning':        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
    'taxes':                     'f7e5678d-dadd-4556-a2fc-446e24642ceb',
    'homelessness-response':     '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
    'public-safety-approach':    'e9ebefcd-c496-45e8-b816-a79f8442ba85',
    'transportation-priorities': 'ba59337e-30e2-4aba-a39a-426b3366eb27',
    'local-environment':         '1935979c-b290-42e4-baa5-8cb0138b4ffa',
    'local-immigration':         'b9ccee94-ad96-4f10-b655-889d8e5abe92',
    'growth-and-development':    'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
}
U = 'https://www.theurbanist.org/content/files/old-theurbanist-org/wp-content/uploads/2025/07/'
ZQ  = U + 'girmay-zahilay-urbanist-questionnaire-responses-for-publication.pdf'
BQ  = U + 'claudia-balducci-urbanist-questionnaire-responses-for-publication.pdf'
ICE = 'https://www.kuow.org/stories/zahilay-s-first-executive-order-bars-ice-from-king-county-owned-properties'

R = [
# ── Girmay Zahilay, County Executive ─────────────────────────────────────────────────────────────
('zahilay','taxes',2,
 'Zahilay says "I strongly support progressive revenue to sustainably fund our priorities without overburdening working people. Our tax code is deeply inequitable", and as Council Budget Chair he "testified in Olympia urging state leaders to lift the 1% cap" and signed a letter calling for exploring new revenue tools. The DESTINATION he states is preservation: he urged the 0.1% public safety sales tax "to preserve critical health and safety services" against federal cuts "jeopardizing nearly $200 million annually", and would otherwise be "reprioritizing budgets, cutting inefficiencies, and using every tool available to protect core services". He also disclaims magnitude directly -- "Lifting the cap does not mean massive tax hikes; it means restoring local control". Raising revenue moderately to hold existing services is chair 2; chair 1 requires significantly raising taxes to fund MORE services, which he expressly does not claim.',
 [ZQ]),
('zahilay','housing',3,
 'Zahilay would "dramatically increase housing supply at all income levels, especially near jobs and transit, by investing public dollars, removing bureaucratic barriers, reforming zoning", and as Budget Chair "secured tens of millions for transit-oriented development and launched the Regional Workforce Housing Initiative to leverage bonding capacity and build $1 billion in rent-restricted housing for essential workers". Public subsidy for affordable projects plus easier permitting is chair 3. Chair 1 is not reached because the flagship programme is aimed at essential workers rather than at anyone who needs a home; chair 2 is refuted because he proposes no rent cap and no requirement that new development include affordable units -- his tenant tools are "rental assistance and tenant protections". ⚠ If a later reader treats a $1 billion county-bonded construction programme as public housing at scale, this is the row to move.',
 [ZQ]),
('zahilay','residential-zoning',4,
 'Zahilay would "overhaul permitting and zoning to accelerate the creation of affordable housing", cites "my missing middle housing legislation to expand density in urban areas", would "push for zoning reforms that allow deeply affordable housing near transit, schools, and jobs", and would "hold every city accountable for helping meet our regional housing needs". Missing middle legislation allows multifamily where single-family zoning stood, which with streamlined permitting is chair 4. Chair 3 is refuted by the scope: he does not protect most residential zones but legislates density into them, and applies the obligation to every city rather than to corridors.',
 [ZQ]),
('zahilay','homelessness-response',2,
 'Zahilay would "deliver 17,000 units of shelter and emergency housing, with a focus on non-congregate models like tiny house villages", accelerate permanent supportive housing "in tandem", "redirect resources from duplicative administrative functions to frontline outreach", and expand "proven prevention tools like rental assistance, tenant protections, and youth supports". Expanding shelter capacity and services as the primary strategy is chair 2. Chair 1 is not reached because the headline commitment is emergency beds rather than permanent supportive housing without preconditions, and chairs 4 and 5 are refuted because he proposes no enforcement tool at all.',
 [ZQ]),
('zahilay','public-safety-approach',2,
 'Zahilay states the division of labour explicitly: "Police will be trained, overseen, and supported to focus on serious crimes, while non-police responders handle behavioral health and substance use crises." He would "expand crisis response teams that de-escalate and connect people to care" and scale JustCARE and REACH. Holding sworn staffing while moving behavioral health and substance use calls to unarmed responders is chair 2 almost verbatim. Chair 1 is refuted because the redirection he proposes is of homelessness-authority administrative overhead, not of the police budget; chair 4 is refuted because he proposes no staffing increase.',
 [ZQ]),
('zahilay','transportation-priorities',1,
 'Zahilay would "invest in reliable mass public transit", and would "lead a coordinated plan with cities to redesign dangerous roads, prioritizing the safety of pedestrians, cyclists, and transit riders" -- chair 1 list stated in full. On electrification he insists service must not be cut because "we risk pushing more people into cars", and his stated goal is "ensuring more people choose fast, reliable public transit". Chair 2 is refuted: he does not propose investing equally in road capacity, and where roads appear it is to redesign them for non-drivers.',
 [ZQ]),
('zahilay','local-environment',2,
 'On rural and natural lands Zahilay would "increase enforcement capacity by fully staffing the departments responsible for oversight", "clarify codes to remove loopholes", and "push for tighter timelines and meaningful penalties so that damaging protected lands is not treated as a cost of doing business". Protecting existing natural areas strictly, with penalties set so that impact cannot simply be paid for, is chair 2. Chair 3 is refuted by what is absent as much as what is present: there is no flexibility clause anywhere in the answer and the stated direction is to close loopholes rather than to accommodate implementation. ⚠ Contrast Fain and Balducci, who answered the same question and were seated at chair 3 on explicit balance language.',
 [ZQ]),
('zahilay','local-immigration',2,
 'Zahilay first executive order as County Executive bars ICE from conducting enforcement in non-public areas of county-owned buildings, adds $2 million for rental, food and legal aid, directs the Sheriff Office to write protocols for 911 calls reporting immigration enforcement, and creates a Welcoming County subcabinet. His stated rationale is that residents are "afraid to leave their homes and go to school, work, medical appointments, and even report crimes to local law enforcement", and that "Every resident who calls King County home, regardless of their citizenship status, deserves safety, dignity, and to live without fear". Protecting people who would otherwise not report crimes is chair 2 second clause. Chair 1 is not reached: the order does not change the detainer standard, and King County continues to honour judicial-warrant-backed detainers under K.C.C. 2.15 -- the same reason Balducci and Dembowski sit at chair 2 rather than chair 1. This is his OWN order, which is what distinguishes it from the Sheriff executing county code (migration 1785).',
 [ICE]),
# ── Claudia Balducci, Council District 6 ─────────────────────────────────────────────────────────
('balducci','taxes',2,
 'Balducci frames tax reform around protecting services: "one of the greatest threats to providing essential services long-term is our limited funding options, which are primarily regressive sources like sales tax, property tax and fees/fares. I have long supported more progressive options." She "supported the capital gains tax and opposed I-2109 to protect an essential progressive revenue source", and lobbied in Olympia to lift the 1% cap because a hard revenue limit "causes systemic and worsening budget challenges" for "critical, basic services long-term". Taxing wealth to sustain existing services, without a claim of significant expansion, is chair 2. Chair 3 is refuted because she seeks new progressive authority rather than small adjustments to the current system.',
 [BQ]),
('balducci','housing',3,
 'Balducci would "continue to advocate for additional funding options to increase subsidized housing, and county-wide planning and zoning efforts to expand the availability of market-based housing of a variety of types and affordability levels (as opposed to the mostly luxury apartments we see going up in our county)", building on the Regional Affordable Housing Committee she founded and chairs and on HB 1220 housing targets in every jurisdiction comprehensive plan. Subsidy for affordable projects plus planning to ease market supply is chair 3. Chair 2 is refuted: she proposes no rent cap and no inclusionary requirement, and chair 1 is not reached because she funds and convenes rather than builds and operates.',
 [BQ]),
('balducci','growth-and-development',3,
 'Balducci states the position twice: "I have stood strong for protecting the urban growth boundary and holding the line on expanding uses outside the urban growth area", and "As Executive, I will uphold a firm commitment to focusing growth within the Urban Growth boundary, resisting pressure to sprawl". Critically she pairs containment with accommodation -- "The best way to protect these areas is to have a strong commitment to urban infill development, expansion of housing opportunities in cities, and building a vision of liveable communities that are able to accommodate growth". Planning proactively so growth is absorbed responsibly rather than limited is chair 3. Chair 1 is refuted because she imposes no cap on growth itself and requires no public vote; chair 2 because she gates nothing on capacity; chairs 4 and 5 because she reduces no fees and removes no barriers.',
 [BQ]),
('balducci','local-environment',3,
 'Balducci "fought for funding for appropriate code enforcement to make sure our rules protecting these areas are observed" and "ensured County departments have the staff, tools, and direction to investigate and act on violations -- whether it is unpermitted construction, environmental degradation, or illegal land use". She pairs that with an explicit balance clause: the current funding system "does not support rural roads as we should, nor allow in some cases appropriate and modest economic activity". Consistent enforcement of existing standards with acknowledged room for modest activity is chair 3. Chairs 1 and 2 are refuted by that balance clause, which is exactly the flexibility chair 3 names and chair 2 excludes.',
 [BQ]),
('balducci','transportation-priorities',1,
 'Balducci would "make road and transit safety top priorities", established "Bellevue Vision Zero policy and using a Safe System Approach at the Puget Sound Regional Council and King County", and states the transit principle plainly: "frequency is freedom -- frequent, reliable transit service is among the most effective climate strategies we have". Her stated Executive focus is "expanding service, improving rider experience, and designing a system that works best for those using it", alongside completing light rail and expanding the regional trail network. Prioritising transit and pedestrian safety is chair 1. Chair 2 is refuted because she nowhere proposes matching road capacity investment; her one road reference is a funding gap for rural roads, not a modal commitment.',
 [BQ]),
('balducci','public-safety-approach',3,
 'Balducci is "committed to both improving law enforcement response and innovative early intervention strategies for addiction and mental/behavioral health crises, which are crucial to preventing crime and eliminating counterproductive responses that we know lead to recidivism", and would invest "throughout the spectrum of responses" with new state resources. Adding crisis intervention capacity alongside, rather than instead of, existing law enforcement funding is chair 3. Chair 2 is not reached because she does not propose shifting call types away from officers -- she improves both limbs at once -- and chair 4 is refuted because she proposes no staffing increase. ⚠ Contrast Zahilay, seated at chair 2 on the same ladder, who does state the shift explicitly.',
 [BQ]),
('balducci','homelessness-response',2,
 'Balducci brings "unmatched experience providing emergency shelter", says "There are tools at hand we are not using (e.g., stranded tiny homes)", and sets the goal that King County becomes "a place where no one sleeps outside due to a lack of housing", while restructuring KCRHA around clear goals and public accountability. Expanding shelter and emergency housing capacity as the primary strategy is chair 2. Chairs 4 and 5 are refuted because she proposes no enforcement tool; chair 1 is not reached because her lead mechanism is emergency shelter rather than permanent supportive housing without preconditions.',
 [BQ]),
]

def arr(u):
    return 'ARRAY[' + ','.join("'" + x + "'" for x in u) + ']'

out = io.StringIO(); w = out.write
w("""-- 1786_kc_executive_candidates.sql
-- Girmay Zahilay (now County Executive) and Claudia Balducci (Council D6), from the long-form
-- questionnaires both filed in the 2025 County Executive race. %d seated rows, no blanks.
-- Completes the King County web-source pass begun in migration 1785.
--
-- Before: Zahilay carried ONE row (jail-capacity=2) and Balducci TWO (jail-capacity=2,
-- local-immigration=2), all from the vote-first pass. The two most consequential officials in the
-- county were the thinnest-covered. After: 9 and 9.
--
-- ── ✅ VALUE-CHANGE GUARD: 15 NEW, 0 CHANGE ──────────────────────────────────────────────────────
-- All three pre-existing rows were re-checked against the questionnaires and CONFIRMED, so nothing
-- here overwrites a curated value. The pre-check below asserts they are still present and unmoved;
-- if any has changed, the confirmation recorded here is stale and must be redone.
--
-- ── 🔑 THE SAME LADDER SPLIT THE TWO CANDIDATES THREE TIMES, WHICH IS THE METHOD WORKING ─────────
-- These two ran against each other, share a party, and would read as interchangeable to a
-- party-inference approach. Reading what they actually wrote separates them:
--   · public-safety-approach -- Zahilay 2, Balducci 3. He states the shift outright ("Police will be
--     trained, overseen, and supported to focus on serious crimes, WHILE non-police responders
--     handle behavioral health and substance use crises"); she improves both limbs at once and
--     invests "throughout the spectrum of responses", which is adding capacity, not reallocating it.
--   · local-environment -- Zahilay 2, Balducci 3. He would set penalties so damage "is not treated
--     as a cost of doing business" with no flexibility clause anywhere; she names one explicitly,
--     that the rules do not "allow in some cases appropriate and modest economic activity".
--   · residential-zoning -- Zahilay 4 on his own missing-middle legislation; Balducci is not seated
--     on that ladder at all, because convening and funding is not a zoning position.
-- 🔑 They CONVERGE on taxes=2 for the same documented reason, and that is worth as much as the
-- splits: both frame progressive revenue as PRESERVING services against federal cuts, and Zahilay
-- disclaims magnitude outright ("Lifting the cap does not mean massive tax hikes"). The destination
-- rule from migration 1759 keeps producing chair 2 for officials whose vocabulary reads chair 1.
--
-- ── 🔑 AN EXECUTIVE ORDER IS THE OFFICIAL'S OWN CHOICE; EXECUTING COUNTY CODE IS NOT ─────────────
-- Migration 1785 blanked the Sheriff on local-immigration because KCSO's no-detainer policy is
-- compliance with binding state law and K.C.C. 2.15. Zahilay is seated on the SAME ladder from the
-- same county, because his first executive order was his own act: it bars ICE from non-public areas
-- of county buildings, funds legal aid, and directs the Sheriff to write 911 protocols. Chair 2 not
-- chair 1, because the order does not touch the detainer standard -- which is why Balducci and
-- Dembowski sit at chair 2 as well. Three King County officials, three separate instruments, one
-- chair, and the reason each is there is different.
BEGIN;

CREATE TEMP TABLE ex_snap ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_answers) AS ans_before,
       (SELECT count(*) FROM inform.politician_context) AS ctx_before;

CREATE TEMP TABLE ex_rows (pid uuid, tid uuid, val int, nm text, tk text) ON COMMIT DROP;
INSERT INTO ex_rows (pid, tid, val, nm, tk) VALUES
""" % len(R))

vals = []
for who, tk, val, _r, _s in R:
    pid, nm = P[who]
    vals.append("('%s','%s',%d,'%s','%s')" % (pid, T[tk], val, nm.replace("'", "''"), tk))
w(',\n'.join(vals) + ';\n\n')

w("""DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ex_rows r
    JOIN inform.politician_answers a ON a.politician_id=r.pid AND a.topic_id=r.tid;
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % of these pairs already have an answer', n; END IF;
  SELECT count(*) INTO n FROM ex_rows r
    JOIN inform.politician_context c ON c.politician_id=r.pid AND c.topic_id=r.tid;
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % of these pairs already have a context row', n; END IF;

  -- The three pre-existing rows this pass CONFIRMED rather than changed. If any has moved, the
  -- value-change guard recorded in this header no longer describes reality. Resolved by topic_key
  -- rather than a hard-coded uuid, since these ids are not otherwise needed by this migration.
  SELECT count(*) INTO n FROM inform.politician_answers a
    JOIN inform.compass_topics t ON t.id=a.topic_id
   WHERE (a.politician_id='1f63b667-7da3-4d75-b3ae-24529393741e' AND t.topic_key='jail-capacity' AND a.value=2)
      OR (a.politician_id='cd772ac3-d63b-4767-9198-ec4f1fb36f4d' AND t.topic_key='jail-capacity' AND a.value=2)
      OR (a.politician_id='cd772ac3-d63b-4767-9198-ec4f1fb36f4d' AND t.topic_key='local-immigration' AND a.value=2);
  IF n <> 3 THEN RAISE EXCEPTION 'pre-check: expected the 3 confirmed pre-existing rows, found %', n; END IF;

  -- Chair-text tripwire for the ladder that splits the two candidates most sharply.
  SELECT count(*) INTO n FROM inform.compass_stances
   WHERE topic_id='e9ebefcd-c496-45e8-b816-a79f8442ba85' AND value=2 AND text ILIKE '%co-responders%';
  IF n <> 1 THEN RAISE EXCEPTION 'pre-check: public-safety-approach chair 2 has been reworded'; END IF;
END $$;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
""")

ctx = []
for who, tk, _v, reason, src in R:
    pid, _nm = P[who]
    ctx.append("('%s','%s',\n $r$%s$r$,\n %s)" % (pid, T[tk], reason, arr(src)))
w(',\n'.join(ctx) + ';\n\n')

w("INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES\n")
w(',\n'.join("('%s','%s', %d)" % (P[who][0], T[tk], val) for who, tk, val, _r, _s in R) + ';\n\n')

w("""DO $$
DECLARE ans_after int; ctx_after int; s record; bad int; n int;
BEGIN
  SELECT * INTO s FROM ex_snap;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  IF ans_after <> s.ans_before + %d THEN
    RAISE EXCEPTION 'guard 1: answers %% -> %%, expected +%d', s.ans_before, ans_after; END IF;
  IF ctx_after <> s.ctx_before + %d THEN
    RAISE EXCEPTION 'guard 1: context %% -> %%, expected +%d', s.ctx_before, ctx_after; END IF;

  SELECT count(*) INTO bad
    FROM ex_rows r
    JOIN inform.politician_answers a ON a.politician_id=r.pid AND a.topic_id=r.tid
    JOIN inform.politician_context c ON c.politician_id=r.pid AND c.topic_id=r.tid
   WHERE a.value <> r.val
      OR coalesce(cardinality(c.sources),0) = 0
      OR length(c.reasoning) < 200;
  IF bad <> 0 THEN RAISE EXCEPTION 'guard 2: %% row(s) wrong chair, thin reasoning or unsourced', bad; END IF;

  -- The three SPLITS are the substance of this migration. Assert each side separately: a bug that
  -- collapsed both candidates onto one chair would satisfy every count guard above.
  SELECT count(*) INTO n FROM ex_rows r
    JOIN inform.politician_answers a ON a.politician_id=r.pid AND a.topic_id=r.tid
   WHERE r.tk='public-safety-approach' AND r.nm='Girmay Zahilay' AND a.value=2;
  IF n <> 1 THEN RAISE EXCEPTION 'guard 2: Zahilay public-safety-approach=2 missing'; END IF;
  SELECT count(*) INTO n FROM ex_rows r
    JOIN inform.politician_answers a ON a.politician_id=r.pid AND a.topic_id=r.tid
   WHERE r.tk='public-safety-approach' AND r.nm='Claudia Balducci' AND a.value=3;
  IF n <> 1 THEN RAISE EXCEPTION 'guard 2: Balducci public-safety-approach=3 missing'; END IF;
  SELECT count(*) INTO n FROM ex_rows r
    JOIN inform.politician_answers a ON a.politician_id=r.pid AND a.topic_id=r.tid
   WHERE r.tk='local-environment' AND r.nm='Girmay Zahilay' AND a.value=2;
  IF n <> 1 THEN RAISE EXCEPTION 'guard 2: Zahilay local-environment=2 missing'; END IF;
  SELECT count(*) INTO n FROM ex_rows r
    JOIN inform.politician_answers a ON a.politician_id=r.pid AND a.topic_id=r.tid
   WHERE r.tk='local-environment' AND r.nm='Claudia Balducci' AND a.value=3;
  IF n <> 1 THEN RAISE EXCEPTION 'guard 2: Balducci local-environment=3 missing'; END IF;

  -- Both must now be among the best-covered county officials rather than the thinnest.
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='1f63b667-7da3-4d75-b3ae-24529393741e';
  IF n <> 9 THEN RAISE EXCEPTION 'guard 2: Zahilay holds %% answers, expected 9', n; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers
   WHERE politician_id='cd772ac3-d63b-4767-9198-ec4f1fb36f4d';
  IF n <> 9 THEN RAISE EXCEPTION 'guard 2: Balducci holds %% answers, expected 9', n; END IF;
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

  RAISE NOTICE 'KC Executive race: %d rows; Zahilay and Balducci now 9 each; ORPHAN_CONTEXT still 50';
END $$;

COMMIT;
""" % (len(R), len(R), len(R), len(R), len(R)))

dest = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..',
                    'migrations', '1786_kc_executive_candidates.sql')
with open(dest, 'w', encoding='utf-8', newline='\n') as f:
    f.write(out.getvalue())
print('wrote %s' % os.path.normpath(dest))
print('rows=%d' % len(R))
